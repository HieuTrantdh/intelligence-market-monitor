#!/usr/bin/env python3
"""
Main Ingestion Script - Day 3
Fetch prices từ CoinGecko → Insert vào PostgreSQL fact_prices

Usage:
    python run_ingestion.py

Returns:
    - Exit code 0: Success
    - Exit code 1: Database connection failed
    - Exit code 2: API fetch failed (partial)
"""

import logging
import sys
import os
from datetime import datetime, timezone
from dotenv import load_dotenv
import psycopg2

# Thêm thư mục src vào Python path để import modules khi chạy trực tiếp file này
PROJECT_ROOT = os.path.dirname(os.path.dirname(__file__))
sys.path.insert(0, PROJECT_ROOT)

from ingestion.coingecko_fetcher import CoinGeckoAPI, CoinGeckoFetcher

# ============================================================================
# CONFIGURATION
# ============================================================================

load_dotenv()
os.makedirs("logs", exist_ok=True)

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.FileHandler('logs/ingestion.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Database config từ .env
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 5432)),
    'database': os.getenv('DB_NAME', 'intelligence_market'),
    'user': os.getenv('DB_USER', 'data_engineer'),
    'password': os.getenv('DB_PASS', ''),
}

# Danh sách 20 coins theo market cap rank
COINS_TO_FETCH = [
    ('bitcoin', 'BTC'),
    ('ethereum', 'ETH'),
    ('tether', 'USDT'),
    ('binancecoin', 'BNB'),
    ('ripple', 'XRP'),
    ('cardano', 'ADA'),
    ('solana', 'SOL'),
    ('polkadot', 'DOT'),
    ('dogecoin', 'DOGE'),
    ('matic-network', 'MATIC'),
    ('litecoin', 'LTC'),
    ('bitcoin-cash', 'BCH'),
    ('chainlink', 'LINK'),
    ('stellar', 'XLM'),
    ('uniswap', 'UNI'),
    ('monero', 'XMR'),
    ('cosmos', 'ATOM'),
    ('avalanche-2', 'AVAX'),
    ('crypto-com-chain', 'CRO'),
    ('aave', 'AAVE'),
]

FETCH_DAYS = 7  # Lấy 7 ngày dữ liệu lịch sử


# ============================================================================
# MAIN FUNCTION
# ============================================================================

def main():
    """Main ingestion pipeline"""
    
    logger.info("=" * 70)
    logger.info("🚀 INGESTION PIPELINE STARTED")
    logger.info(f"   Timestamp: {datetime.now(timezone.utc).isoformat()}")
    logger.info(f"   Source: CoinGecko API")
    logger.info(f"   Coins to fetch: {len(COINS_TO_FETCH)}")
    logger.info(f"   Days of history: {FETCH_DAYS}")
    logger.info("=" * 70)
    
    # Step 1: Connect to database
    logger.info("Step 1: Connecting to PostgreSQL...")
    try:
        db_conn = psycopg2.connect(**DB_CONFIG)
        logger.info("✓ Database connection successful")
    except psycopg2.Error as e:
        logger.error(f"✗ Database connection failed: {e}")
        return 1
    
    # Step 2: Initialize CoinGecko API client
    logger.info("Step 2: Initializing CoinGecko API client...")
    try:
        api = CoinGeckoAPI()
        fetcher = CoinGeckoFetcher(api)
        logger.info("✓ CoinGecko API client initialized")
    except Exception as e:
        logger.error(f"✗ Failed to initialize API client: {e}")
        db_conn.close()
        return 1
    
    # Step 3: Fetch and insert prices for each coin
    logger.info(f"Step 3: Fetching prices for {len(COINS_TO_FETCH)} coins...")
    logger.info("-" * 70)
    
    total_inserted = 0
    total_skipped = 0
    total_errors = 0
    coins_success = 0
    coins_failed = 0
    
    try:
        for coingecko_id, symbol in COINS_TO_FETCH:
            try:
                inserted, skipped, errors = fetcher.fetch_and_insert(
                    db_conn,
                    coin_id=coingecko_id,
                    coingecko_id=coingecko_id,
                    days=FETCH_DAYS
                )

                total_inserted += inserted
                total_skipped += skipped
                total_errors += errors

                if errors == 0:
                    coins_success += 1
                else:
                    coins_failed += 1

            except Exception as e:
                logger.exception(f"Failed processing {coingecko_id}: {e}")
                try:
                    db_conn.rollback()
                except Exception:
                    pass
                coins_failed += 1
                total_errors += 1
    finally:
        # Step 4: Close connections and report
        try:
            if fetcher:
                fetcher.close()
        except Exception:
            pass

        try:
            if db_conn and not db_conn.closed:
                db_conn.close()
        except Exception:
            pass
    
    # Summary report
    logger.info("=" * 70)
    logger.info("📊 INGESTION REPORT")
    logger.info(f"   Coins processed:     {coins_success} success, {coins_failed} failed")
    logger.info(f"   Total records:       Inserted={total_inserted}, Skipped={total_skipped}, Errors={total_errors}")
    logger.info(f"   Timestamp:           {datetime.now(timezone.utc).isoformat()}")
    logger.info("=" * 70)
    
    # Determine exit code
    if coins_failed == 0:
        logger.info("✓ INGESTION COMPLETED SUCCESSFULLY")
        return 0
    elif coins_success > 0:
        logger.warning("⚠️ INGESTION COMPLETED WITH PARTIAL SUCCESS")
        return 2
    else:
        logger.error("✗ INGESTION FAILED - ALL COINS FAILED")
        return 1


if __name__ == '__main__':
    exit_code = main()
    sys.exit(exit_code)