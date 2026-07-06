-- DAY 3 VALIDATION QUERIES
-- Chạy sau khi chạy run_ingestion.py để verify data integrity
-- 
-- Usage:
--   psql -U data_engineer -d intelligence_market -f sql/queries/day3_validation.sql


-- ============================================================================
-- 1. COUNT TOTAL PRICES INSERTED
-- ============================================================================

SELECT 
    'fact_prices table' as check_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT coin_id) as unique_coins,
    MIN(timestamp) as oldest_price,
    MAX(timestamp) as newest_price
FROM fact_prices
WHERE source = 'coingecko';

-- Expected: > 0 records, 20 unique coins (if all 20 fetched successfully)


-- ============================================================================
-- 2. VERIFY NO DUPLICATE TIMESTAMPS PER COIN
-- ============================================================================

SELECT 
    'Duplicate check' as check_name,
    COUNT(*) as duplicate_count
FROM (
    SELECT coin_id, timestamp, source, COUNT(*) as cnt
    FROM fact_prices
    WHERE source = 'coingecko'
    GROUP BY coin_id, timestamp, source
    HAVING COUNT(*) > 1
) duplicates;

-- Expected: 0 duplicates (ON CONFLICT DO NOTHING should prevent this)


-- ============================================================================
-- 3. PRICE DATA QUALITY BY COIN
-- ============================================================================

SELECT 
    dc.symbol,
    COUNT(fp.price_id) as price_records,
    MIN(fp.timestamp) as oldest_fetch,
    MAX(fp.timestamp) as latest_fetch,
    ROUND(AVG(fp.close), 2) as avg_price_usd,
    MIN(fp.close) as min_price,
    MAX(fp.close) as max_price,
    COUNT(DISTINCT DATE(fp.timestamp)) as days_covered
FROM dim_coins dc
LEFT JOIN fact_prices fp ON dc.coin_id = fp.coin_id AND fp.source = 'coingecko'
WHERE dc.market_cap_rank <= 20
GROUP BY dc.symbol, dc.coin_id
ORDER BY dc.market_cap_rank;

-- Expected: All 20 coins with >0 price_records, at least 7 days covered


-- ============================================================================
-- 4. VALIDATION LOG SUMMARY
-- ============================================================================

SELECT 
    'Ingestion validation' as check_type,
    COUNT(*) as total_batches,
    SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as successful_batches,
    SUM(CASE WHEN status = 'partial' THEN 1 ELSE 0 END) as partial_batches,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_batches,
    SUM(total_records) as total_records_processed,
    SUM(valid_records) as total_valid,
    SUM(invalid_records) as total_invalid
FROM fact_validations
WHERE pipeline_step = 'ingestion' 
  AND table_name = 'fact_prices'
  AND validation_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 day';

-- Expected: High success rate (>95%), low error rate


-- ============================================================================
-- 5. PRICES WITH NULL VALUES (Data Quality Check)
-- ============================================================================

SELECT 
    'NULL check' as check_type,
    COUNT(*) as records_with_nulls
FROM fact_prices
WHERE source = 'coingecko'
  AND (close IS NULL OR coin_id IS NULL OR timestamp IS NULL);

-- Expected: 0 (close, coin_id, timestamp should never be NULL)


-- ============================================================================
-- 6. PRICE RANGE SANITY CHECK
-- ============================================================================

SELECT 
    'Price sanity check' as check_type,
    dc.symbol,
    COUNT(*) as records,
    ROUND(MIN(fp.close)::numeric, 2) as min_price,
    ROUND(MAX(fp.close)::numeric, 2) as max_price,
    ROUND((MAX(fp.close) - MIN(fp.close)) / MIN(fp.close) * 100, 2) as price_variance_pct
FROM fact_prices fp
JOIN dim_coins dc ON fp.coin_id = dc.coin_id
WHERE fp.source = 'coingecko'
  AND fp.timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY dc.symbol
HAVING COUNT(*) > 0
ORDER BY price_variance_pct DESC;

-- Expected: 
-- - BTC: Small variance (stable)
-- - DOGE: Larger variance (volatile)
-- - All prices > 0


-- ============================================================================
-- 7. FRESHNESS CHECK
-- ============================================================================

SELECT 
    'Data freshness' as check_type,
    MAX(timestamp) as latest_price_timestamp,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(timestamp)))::int as seconds_old,
    ROUND((EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(timestamp))) / 3600)::numeric, 1) as hours_old
FROM fact_prices
WHERE source = 'coingecko';

-- Expected: < 1 day old (Tran should run this daily/weekly)


-- ============================================================================
-- 8. VERIFICATION LOG (Last 10 ingestion batches)
-- ============================================================================

SELECT 
    validation_id,
    validation_timestamp,
    status,
    total_records,
    valid_records,
    invalid_records,
    ROUND(valid_records::numeric/ NULLIF(total_records,0)*100,1) AS success_rate_pct,
    error_log
FROM fact_validations
WHERE pipeline_step = 'ingestion' 
  AND table_name = 'fact_prices'
ORDER BY validation_timestamp DESC
LIMIT 10;

-- Expected: Mostly 'success' status, high success_rate_pct


-- ============================================================================
-- 9. QUICK STATS - SUMMARY FOR README
-- ============================================================================

WITH stats AS (
    SELECT 
        COUNT(*) as total_prices,
        COUNT(DISTINCT coin_id) as unique_coins,
        COUNT(DISTINCT DATE(timestamp)) as days_with_data,
        MAX(timestamp) as last_updated
    FROM fact_prices
    WHERE source = 'coingecko'
)
SELECT 
    'Summary' as metric,
    total_prices::text || ' price records' as value
FROM stats
UNION ALL
SELECT 'Coins with data', unique_coins::text FROM stats
UNION ALL
SELECT 'Days covered', days_with_data::text FROM stats
UNION ALL
SELECT 'Last updated', TO_CHAR(last_updated, 'YYYY-MM-DD HH24:MI:SS UTC') FROM stats;

-- Expected output:
-- Summary | 140 price records
-- Coins with data | 20
-- Days covered | 7
-- Last updated | 2024-07-04 10:30:45 UTC


-- ============================================================================
-- END OF DAY 3 VALIDATION QUERIES
-- ============================================================================