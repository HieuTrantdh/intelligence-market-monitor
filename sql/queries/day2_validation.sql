-- Day 2 Validation Queries
-- Kiểm tra database setup hoàn tất

-- Q1: Đếm total coins
SELECT COUNT(*) as total_coins FROM dim_coins;

-- Q2: Hiển thị top 5 coins
SELECT coin_id, name, symbol, market_cap_rank 
FROM dim_coins 
ORDER BY market_cap_rank ASC 
LIMIT 5;

-- Q3: Kiểm tra fact_prices (nên empty)
SELECT COUNT(*) as total_prices FROM fact_prices;

-- Q4: Kiểm tra indexes
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- Q5: Đếm tables
SELECT COUNT(*) as table_count 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- Q6: Hiển thị tất cả tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;
