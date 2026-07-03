-- ============================================
-- Intelligence Market Monitor - Initial Schema
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. DIM_COINS 
-- ============================================
CREATE TABLE IF NOT EXISTS dim_coins (
    coin_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,              
    symbol VARCHAR(10) NOT NULL UNIQUE,     
    market_cap_rank INT,                     
    coingecko_id VARCHAR(50) UNIQUE,        
    binance_symbol VARCHAR(20),              
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE INDEX IF NOT EXISTS idx_dim_coins_coingecko_id ON dim_coins(coingecko_id);
CREATE INDEX IF NOT EXISTS idx_dim_coins_symbol ON dim_coins(symbol);

-- ============================================
-- 2. FACT_PRICES 
-- ============================================
CREATE TABLE IF NOT EXISTS fact_prices (
    price_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coin_id UUID NOT NULL REFERENCES dim_coins(coin_id) ON DELETE CASCADE,
    timestamp TIMESTAMP NOT NULL,            
    open DECIMAL(20, 8),                    
    high DECIMAL(20, 8),                    
    low DECIMAL(20, 8),                     
    close DECIMAL(20, 8),                  
    volume DECIMAL(20, 2),                   
    source VARCHAR(50) NOT NULL,             
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
   
    CHECK (close IS NOT NULL),
    
    CHECK (close >= 0),
    
    CONSTRAINT unique_price UNIQUE(coin_id, timestamp, source)
);

CREATE INDEX IF NOT EXISTS idx_fact_prices_coin_timestamp ON fact_prices(coin_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_fact_prices_timestamp ON fact_prices(timestamp);
CREATE INDEX IF NOT EXISTS idx_fact_prices_source ON fact_prices(source);

-- ============================================
-- 3. DIM_NEWS (Tin tức từ internet)
-- ============================================
CREATE TABLE IF NOT EXISTS dim_news (
    news_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,             
    summary TEXT,                            
    source VARCHAR(100) NOT NULL,            
    url VARCHAR(1000),                       
    published_at TIMESTAMP NOT NULL,         
    sentiment_label VARCHAR(20),             
    sentiment_score DECIMAL(5, 3),           
    relevant_coins VARCHAR(500),             
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    
    CONSTRAINT unique_news UNIQUE(title, source, published_at)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_dim_news_published_at ON dim_news(published_at);
CREATE INDEX IF NOT EXISTS idx_dim_news_source ON dim_news(source);
CREATE INDEX IF NOT EXISTS idx_dim_news_sentiment ON dim_news(sentiment_label);

-- ============================================
-- 4. FACT_VALIDATIONS (Data Quality Tracking)
-- ============================================
CREATE TABLE IF NOT EXISTS fact_validations (
    validation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pipeline_step VARCHAR(50) NOT NULL,      
    table_name VARCHAR(50) NOT NULL,         
    validation_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Metrics
    total_records INT,                      
    valid_records INT,                       
    invalid_records INT,                     
    
    -- Details
    error_log JSONB,                         
    status VARCHAR(20),                      
    duration_seconds INT,                    
    
    -- Created time
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_fact_validations_table ON fact_validations(table_name);
CREATE INDEX IF NOT EXISTS idx_fact_validations_timestamp ON fact_validations(validation_timestamp);
CREATE INDEX IF NOT EXISTS idx_fact_validations_status ON fact_validations(status);

-- ============================================
-- 5. SEED DATA - Insert 30 top cryptocurrencies
-- ============================================
INSERT INTO dim_coins (name, symbol, market_cap_rank, coingecko_id, binance_symbol)
VALUES
    ('Bitcoin', 'BTC', 1, 'bitcoin', 'BTCUSDT'),
    ('Ethereum', 'ETH', 2, 'ethereum', 'ETHUSDT'),
    ('Tether', 'USDT', 3, 'tether', 'USDT'),
    ('Binance Coin', 'BNB', 4, 'binancecoin', 'BNBUSDT'),
    ('XRP', 'XRP', 5, 'ripple', 'XRPUSDT'),
    ('Cardano', 'ADA', 6, 'cardano', 'ADAUSDT'),
    ('Solana', 'SOL', 7, 'solana', 'SOLUSDT'),
    ('Polkadot', 'DOT', 8, 'polkadot', 'DOTUSDT'),
    ('Dogecoin', 'DOGE', 9, 'dogecoin', 'DOGEUSDT'),
    ('Polygon', 'MATIC', 10, 'matic-network', 'MATICUSDT'),
    ('Litecoin', 'LTC', 11, 'litecoin', 'LTCUSDT'),
    ('Bitcoin Cash', 'BCH', 12, 'bitcoin-cash', 'BCHUSDT'),
    ('Chainlink', 'LINK', 13, 'chainlink', 'LINKUSDT'),
    ('Stellar', 'XLM', 14, 'stellar', 'XLMUSDT'),
    ('Uniswap', 'UNI', 15, 'uniswap', 'UNIUSDT'),
    ('Monero', 'XMR', 16, 'monero', 'XMRUSDT'),
    ('Cosmos', 'ATOM', 17, 'cosmos', 'ATOMUSDT'),
    ('Avalanche', 'AVAX', 18, 'avalanche-2', 'AVAXUSDT'),
    ('Cro', 'CRO', 19, 'crypto-com-chain', 'CROUSDT'),
    ('Aave', 'AAVE', 20, 'aave', 'AAVEUSDT')
ON CONFLICT (symbol) DO NOTHING;
