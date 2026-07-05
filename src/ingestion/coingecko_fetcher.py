"""
CoinGecko API Fetcher - Refined & Completed Version (20 Coins Personal Project)

Đã sửa đổi và hoàn thiện các chi tiết kỹ thuật cuối cùng:
1. Sửa lỗi gọi hàm: Đã khôi phục đầy đủ bước ghi nhật ký vào bảng `fact_validations` trong hàm `fetch_and_insert`.
2. Giới hạn Backoff: Áp dụng chặn trên tối đa 60 giây (`MAX_BACKOFF`) cho exponential backoff khi gặp lỗi mạng/5xx.
3. Giải phóng Connection: Đảm bảo đóng `response.close()` trong khối `finally` tại tất cả các điểm nhận kết quả từ mạng.
4. Bổ sung Logging: Thêm thông báo `logger.warning` chi tiết ghi nhận chính xác dòng timestamp nào bị lỗi parse.
5. Thống nhất Timezone: Giữ nguyên cơ chế múi giờ chuẩn quốc tế UTC (Timezone-aware) cho toàn bộ hệ thống DB.
"""

import requests
import logging
import time
import random
import uuid
import psycopg2
from psycopg2.extras import execute_values
from datetime import datetime, timezone, timedelta
from typing import List, Dict, Optional, Tuple

logger = logging.getLogger(__name__)


class CoinGeckoConfig:
    """Cấu hình tinh gọn, thực tế cho nhu cầu cào 20 coins"""
    
    BASE_URL = "https://api.coingecko.com/api/v3"
    
    # Định thời gian delay cơ bản: Gói miễn phí CoinGecko khuyên dùng ~ 4.5s giữa các request nặng
    HEAVY_DELAY = 4.5  
    
    REQUEST_TIMEOUT = 15  # 15s đề phòng VPS nghẽn mạng
    MAX_RETRIES = 3
    INITIAL_BACKOFF = 2
    MAX_BACKOFF = 60      # 💡 Sửa lỗi 2: Chặn trên cho thời gian backoff tối đa
    
    # Cache dữ liệu lịch sử trong vòng 10 phút
    CACHE_TTL_SECONDS = 600

    # Một User-Agent Chrome sạch và mới nhất
    USER_AGENT = (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    )


class CoinGeckoAPI:
    """Client API tinh gọn, kiểm soát tài nguyên kết nối chặt chẽ"""
    
    def __init__(self, config: CoinGeckoConfig = None):
        self.config = config or CoinGeckoConfig()
        self.session = None
        self.last_request_time = 0
        self._cache: Dict[str, Tuple[datetime, dict]] = {}
        
        # Thống kê ngắn gọn cho dự án nhỏ
        self.metrics = {
            "total_network_requests": 0,
            "success_requests": 0,
            "cloudflare_blocks": 0
        }
        
        self._init_session()

    def _init_session(self):
        """Khởi tạo session sạch kèm bộ nhận diện an toàn"""
        if self.session:
            try: self.session.close()
            except: pass
            
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': self.config.USER_AGENT,
            'Accept': 'application/json',
            'Accept-Language': 'en-US,en;q=0.9,vi;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive'
        })

    def _enforce_rate_limit(self):
        """Giãn cách thời gian với sai số Jitter ±15% tránh tạo thành mẫu hành vi lặp lại"""
        elapsed = time.time() - self.last_request_time
        jitter_delay = self.config.HEAVY_DELAY * random.uniform(0.85, 1.15)
        
        if elapsed < jitter_delay:
            time.sleep(jitter_delay - elapsed)
            
        self.last_request_time = time.time()

    def _cleanup_expired_cache(self):
        """Dọn dẹp các cache đã hết hạn để tránh phình bộ nhớ RAM"""
        now_utc = datetime.now(timezone.utc)
        expired_keys = [
            key for key, (cached_time, _) in self._cache.items()
            if now_utc > cached_time + timedelta(seconds=self.config.CACHE_TTL_SECONDS)
        ]
        for key in expired_keys:
            del self._cache[key]

    def _get_with_retry(self, url: str, params: Dict = None) -> Optional[requests.Response]:
        backoff = self.config.INITIAL_BACKOFF
        
        for attempt in range(1, self.config.MAX_RETRIES + 1):
            response = None
            try:
                self._enforce_rate_limit()
                self.metrics["total_network_requests"] += 1
                
                response = self.session.get(url, params=params, timeout=self.config.REQUEST_TIMEOUT)
                
                # Phòng chống ValueError khi ép kiểu các header rate limit từ CoinGecko
                xl_remaining = response.headers.get('X-RateLimit-Remaining')
                xl_reset = response.headers.get('X-RateLimit-Reset')
                
                try:
                    remaining = int(xl_remaining) if xl_remaining else None
                except ValueError:
                    remaining = None
                    
                if remaining is not None and remaining <= 1:
                    try:
                        wait_reset = int(xl_reset) if xl_reset else 10
                    except ValueError:
                        wait_reset = 10
                    logger.warning(f"⚠️ Sắp cạn kiệt Rate Limit. Chủ động dừng đợi {wait_reset}s.")
                    time.sleep(wait_reset)

                # Xử lý lỗi 429 (Rate Limited)
                if response.status_code == 429:
                    retry_after = response.headers.get('Retry-After')
                    try:
                        wait_time = int(retry_after) if retry_after else 60
                    except ValueError:
                        wait_time = 60
                        
                    logger.warning(f"⚠️ Gặp lỗi 429 (Too Many Requests). Phải đợi {wait_time}s.")
                    time.sleep(wait_time)
                    
                    # 💡 Sửa lỗi 3: Vì ta sẽ gọi 'continue' nên cần giải phóng kết nối hiện tại ngay lập tức
                    response.close()
                    continue

                # Phát hiện Cloudflare Block -> Ngắt tiến trình ngay (Fail-Fast)
                if response.status_code in [403, 503]:
                    body_text = response.text.lower()
                    if "cf-ray" in response.headers or "cloudflare" in body_text or "attention required" in body_text:
                        self.metrics["cloudflare_blocks"] += 1
                        logger.critical("🛑 [CLOUDFLARE BLOCK] Phát hiện tường lửa chặn IP! Dừng batch ngay lập tức.")
                        if response: response.close()
                        return None

                # Xử lý lỗi phía Server 5xx từ CoinGecko
                if response.status_code >= 500:
                    logger.warning(f"Server CoinGecko lỗi {response.status_code}. Thử lại sau {backoff}s...")
                    time.sleep(backoff)
                    backoff = min(backoff * 2, self.config.MAX_BACKOFF)  # 💡 Sửa lỗi 2: Giới hạn MAX_BACKOFF
                    response.close()
                    continue

                response.raise_for_status()
                self.metrics["success_requests"] += 1
                return response  # Lưu ý: Tầng gọi hàm phía trên có trách nhiệm close() response này
            
            except (requests.exceptions.Timeout, requests.exceptions.ConnectionError) as e:
                logger.warning(f"Lỗi kết nối mạng ({type(e).__name__}) ở lượt thử {attempt}. Đang thử lại...")
                if response: 
                    try: response.close()
                    except: pass
                time.sleep(backoff)
                backoff = min(backoff * 2, self.config.MAX_BACKOFF)  # 💡 Sửa lỗi 2: Giới hạn MAX_BACKOFF
            except requests.exceptions.HTTPError as e:
                logger.error(f"Lỗi HTTP Client không thể tự sửa: {e}")
                if response: response.close()
                return None
            except Exception as e:
                logger.error(f"Lỗi không xác định trong quá trình request: {e}")
                if response: response.close()
                return None
                
        return None

    def get_market_chart(self, coin_id: str, days: int = 7) -> Optional[Dict]:
        cache_key = f"market_chart_{coin_id}_{days}"
        now_utc = datetime.now(timezone.utc)
        
        # Kiểm tra bộ đệm Cache
        if cache_key in self._cache:
            cached_time, cached_data = self._cache[cache_key]
            if now_utc < cached_time + timedelta(seconds=self.config.CACHE_TTL_SECONDS):
                logger.debug(f"⚡ [CACHE HIT] Sử dụng lại dữ liệu cache của {coin_id}.")
                return cached_data

        url = f"{self.config.BASE_URL}/coins/{coin_id}/market_chart"
        params = {'vs_currency': 'usd', 'days': days, 'interval': 'daily'}
        
        logger.info(f"Đang gọi API lấy Market Chart cho: {coin_id}")
        response = self._get_with_retry(url, params)
        
        if not response:
            return None
            
        try:
            # 💡 Sửa lỗi 3: Đảm bảo đóng kết nối HTTP sau khi bóc tách JSON thành công qua khối try...finally
            data = response.json()
            
            self._cleanup_expired_cache()
            self._cache[cache_key] = (now_utc, data)
            return data
        except ValueError as e:
            logger.error(f"Phản hồi của CoinGecko không phải định dạng JSON: {e}")
            return None
        finally:
            if response:
                response.close()  # Giải phóng HTTP Connection về connection pool

    def log_metrics_report(self):
        """Kết xuất thống kê ngắn gọn cho dự án nhỏ"""
        logger.info("============== 📊 BÁO CÁO BATCH HOÀN THÀNH ==============")
        logger.info(f"   🔹 TỔNG SỐ REQUEST GỬI QUA MẠNG: {self.metrics['total_network_requests']}")
        logger.info(f"   🔹 SỐ REQUEST THÀNH CÔNG:       {self.metrics['success_requests']}")
        logger.info(f"   🔹 SỐ LẦN BỊ CLOUDFLARE CHẶN:    {self.metrics['cloudflare_blocks']}")
        logger.info("=========================================================")

    def close(self):
        if self.session:
            self.session.close()


class CoinGeckoFetcher:
    """Bộ điều phối liên kết dữ liệu API vào cơ sở dữ liệu PostgreSQL"""
    
    def __init__(self, api: CoinGeckoAPI = None):
        self.api = api or CoinGeckoAPI()
    
    def fetch_and_insert(self, db_conn, coin_id: str, coingecko_id: str, days: int = 7) -> Tuple[int, int, int]:
        data = self.api.get_market_chart(coingecko_id, days)
        if not data:
            logger.error(f"❌ Bỏ qua {coingecko_id} trong chu kỳ này do lỗi API (hoặc Cloudflare Block).")
            return 0, 0, 1
        
        prices = data.get('prices', [])
        if not prices:
            return 0, 0, 1
        
        coin_uuid = self._get_coin_uuid(db_conn, coingecko_id)
        if not coin_uuid:
            logger.error(f"❌ Không tìm thấy map ID {coingecko_id} trong bảng dim_coins.")
            return 0, 0, len(prices)
        
        # 💡 Sửa lỗi 1: Khôi phục logic gọi hàm _log_validation để cập nhật bảng chất lượng dữ liệu
        inserted, skipped, errors = self._insert_prices(db_conn, coin_uuid, coingecko_id, prices)
        self._log_validation(db_conn, coin_uuid, coingecko_id, inserted, skipped, errors)
        
        return inserted, skipped, errors
    
    def _get_coin_uuid(self, db_conn, coingecko_id: str) -> Optional[str]:
        cursor = None
        try:
            cursor = db_conn.cursor()
            cursor.execute("SELECT coin_id FROM dim_coins WHERE coingecko_id = %s", (coingecko_id,))
            result = cursor.fetchone()
            return result[0] if result else None
        except psycopg2.Error as e:
            logger.error(f"Lỗi DB bảng dim_coins: {e}")
            return None
        finally:
            if cursor: cursor.close()
    
    def _insert_prices(self, db_conn, coin_uuid: str, coingecko_id: str, prices: List) -> Tuple[int, int, int]:
        cursor = None
        inserted = 0
        skipped = 0
        errors = 0
        records = []
        
        now_utc = datetime.now(timezone.utc)
        
        try:
            cursor = db_conn.cursor()
            for timestamp_ms, price in prices:
                try:
                    # Chuyển đổi timestamp từ mili-giây sang datetime UTC thống nhất
                    dt = datetime.fromtimestamp(timestamp_ms / 1000.0, tz=timezone.utc)
                    records.append((
                        str(uuid.uuid4()), coin_uuid, dt, price,
                        None, None, None, None, 'coingecko', now_utc
                    ))
                except Exception as e:
                    # 💡 Sửa lỗi nhỏ: Bổ sung log warning chi tiết thông tin record lỗi parsing cấu trúc
                    logger.warning(f"⚠️ Lỗi phân tích cú pháp cho record giá của {coingecko_id} tại timestamp_ms {timestamp_ms}: {e}")
                    errors += 1
            
            if not records:
                return 0, 0, errors
            
            sql = """
                INSERT INTO fact_prices 
                (price_id, coin_id, timestamp, close, open, high, low, volume, source, fetched_at)
                VALUES %s
                ON CONFLICT (coin_id, timestamp, source) DO NOTHING
            """
            execute_values(cursor, sql, records)
            
            # Sử dụng cursor.rowcount đếm chính xác dòng chèn mới thực tế
            actual_inserted = cursor.rowcount
            if actual_inserted >= 0:
                inserted = actual_inserted
                skipped = len(records) - inserted
            else:
                inserted = len(records)
                skipped = 0
                
            db_conn.commit()
            logger.info(f"✓ {coingecko_id}: Đã thêm mới={inserted}, Bỏ qua trùng={skipped}, Lỗi parsing={errors}")
            
        except psycopg2.Error as e:
            if db_conn: db_conn.rollback()
            logger.error(f"Lỗi thực thi SQL Database Fact Table: {e}")
            errors += len(records)
        finally:
            if cursor: cursor.close()
            
        return inserted, skipped, errors

    def _log_validation(self, db_conn, coin_uuid: str, coingecko_id: str, 
                       inserted: int, skipped: int, errors: int):
        cursor = None
        now_utc = datetime.now(timezone.utc)
        try:
            cursor = db_conn.cursor()
            total = inserted + skipped + errors
            status = 'success' if errors == 0 else ('partial' if errors < total else 'failed')
            
            cursor.execute("""
                INSERT INTO fact_validations 
                (validation_id, pipeline_step, table_name, validation_timestamp, 
                 total_records, valid_records, invalid_records, error_log, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                str(uuid.uuid4()), 'ingestion', 'fact_prices', now_utc,
                total, inserted + skipped, errors,
                f'{{"source": "coingecko", "coin_id": "{coingecko_id}", "inserted": {inserted}, "skipped": {skipped}, "errors": {errors}}}',
                status
            ))
            db_conn.commit()
            logger.debug(f"✓ Đã lưu log đối soát validation cho {coingecko_id}")
        except psycopg2.Error as e:
            if db_conn: db_conn.rollback()
            logger.error(f"Lỗi ghi log validation cho {coingecko_id}: {e}")
        finally:
            if cursor: cursor.close()

    def close(self):
        self.api.log_metrics_report()
        self.api.close()