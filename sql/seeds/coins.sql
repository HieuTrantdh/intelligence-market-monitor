-- Intelligence Market Monitor - Seed Data
-- Insert 20 top cryptocurrencies

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
