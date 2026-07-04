# Intelligence Market Monitor

End-to-end data pipeline for cryptocurrency market analysis. The system automatically collects price data from multiple sources, validates data quality, detects anomalies, and triggers alerts based on statistical outliers.

## Overview

This project builds an ingestion and transformation layer for cryptocurrency data. It fetches historical prices from CoinGecko and Binance APIs, scrapes news from CryptoPanic and CoinDesk, and stores everything in PostgreSQL using a star schema design. The pipeline includes data quality validation, duplicate detection, and freshness monitoring. Future phases will add anomaly detection and a Power BI dashboard.

## Technology Stack

Language: Python 3.10+
Database: PostgreSQL 15+
Data Model: Star Schema (fact and dimension tables)
APIs: CoinGecko, Binance, CryptoPanic, CoinDesk
Orchestration: GitHub Actions (scheduled jobs)
Version Control: Git/GitHub

## Project Structure

```
intelligence-market-monitor/
├── README.md
├── requirements.txt
├── .env.example
├── .gitignore
├── backup_database.sh
├── LICENSE
│
├── src/
│   ├── __init__.py
│   ├── config.py
│   ├── ingestion/
│   │   ├── __init__.py
│   │   ├── coingecko_fetcher.py
│   │   └── binance_fetcher.py
│   ├── validation/
│   │   ├── __init__.py
│   │   └── data_quality.py
│   └── transformation/
│       ├── __init__.py
│       └── sql_queries.py
│
├── sql/
│   ├── schema/
│   │   └── initial_schema.sql
│   ├── seeds/
│   │   └── coins.sql
│   └── queries/
│       └── day2_validation.sql
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_coingecko.py
│   └── test_validation.py
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DATABASE.md
│   ├── API_GUIDE.md
│   └── SETUP.md
│
├── .github/
│   └── workflows/
│       └── daily_ingestion.yml
│
└── backups/
    └── (automated database backups)
```

## Setup

### Prerequisites

Install required software:
- Python 3.10 or higher
- PostgreSQL 15 or higher
- Git

### Installation

Clone the repository:
```bash
git clone https://github.com/HieuTrantdh/intelligence-market-monitor.git
cd intelligence-market-monitor
```

Create and activate Python virtual environment:
```bash
python -m venv venv
source venv/bin/activate
```

On Windows, use:
```bash
venv\Scripts\activate
```

Install Python dependencies:
```bash
pip install -r requirements.txt
```

Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your PostgreSQL credentials
```

The .env file should contain:
```
DB_HOST=localhost
DB_PORT=5432
DB_USER=data_engineer
DB_PASS=your_password
DB_NAME=intelligence_market
LOG_LEVEL=INFO
```

### Database Setup

Create the database and user in PostgreSQL:
```bash
psql -U postgres -d postgres << EOF
CREATE DATABASE intelligence_market;
CREATE USER data_engineer WITH PASSWORD 'your_password_here';
GRANT CONNECT ON DATABASE intelligence_market TO data_engineer;
GRANT CREATE ON DATABASE intelligence_market TO data_engineer;
EOF
```

Initialize the schema:
```bash
psql -U data_engineer -d intelligence_market -f sql/schema/initial_schema.sql
```

Seed the cryptocurrency data:
```bash
psql -U data_engineer -d intelligence_market -f sql/seeds/coins.sql
```

Verify the setup:
```bash
psql -U data_engineer -d intelligence_market -f sql/queries/day2_validation.sql
```

## Database Schema

The schema follows a star design with fact and dimension tables.

Dimension Tables:
- dim_coins: Master data for 20 cryptocurrencies (Bitcoin, Ethereum, etc.)
- dim_news: News articles and events from CoinDesk and CryptoPanic

Fact Tables:
- fact_prices: OHLCV price data collected from CoinGecko and Binance
- fact_validations: Data quality metrics for each ingestion run

Key constraints:
- Each price record is unique by coin, timestamp, and source
- Each news item is unique by title, source, and publication date
- Price values must be non-null and non-negative

Indexes are created on frequently queried columns (coin_id, timestamp, source) to optimize query performance.

See sql/schema/initial_schema.sql for complete table definitions.

## Running the Pipeline

Single run:
```bash
python src/ingestion/run_ingestion.py
```

This will:
1. Fetch price data from CoinGecko and Binance APIs
2. Scrape recent news from CryptoPanic and CoinDesk
3. Validate data for duplicates and null values
4. Insert records into PostgreSQL
5. Log validation results to fact_validations table

Scheduled runs are configured in .github/workflows/daily_ingestion.yml and run automatically via GitHub Actions.

## Testing

Run the test suite:
```bash
pytest
```

Run tests with coverage:
```bash
pytest --cov=src tests/
```

Run a specific test file:
```bash
pytest tests/test_coingecko.py -v
```

Current test coverage includes:
- API response handling and error cases
- Data validation logic (null checks, duplicates, type checking)
- Database insertion and transaction rollback

## Database Backup

Create a backup manually:
```bash
./backup_database.sh
```

This creates a SQL dump in the backups/ directory with timestamp format: intelligence_market_YYYY-MM-DD_HH-MM-SS.sql

The script automatically keeps only the 10 most recent backups to save space.

## Development

Code style follows PEP 8. Format code before committing:
```bash
black src/
flake8 src/
```

Git workflow:
1. Create a branch for your feature
2. Make changes and commit with descriptive messages
3. Submit a pull request against the develop branch
4. After review and tests pass, merge to main

Commit message convention:
- feat: new feature or enhancement
- fix: bug fix
- docs: documentation changes
- test: test additions or updates
- refactor: code restructuring without behavior change

Example:
```bash
git commit -m "feat: add Binance API fetcher with error retry logic"
```

## Known Limitations

Currently in MVP phase (Week 1-2):
- News scraping is basic HTML parsing, not using Scrapy yet
- Anomaly detection not yet implemented
- No Power BI dashboard yet (planned for Phase 2)
- Alerts only logged to database, not sent to Slack yet
- Single-machine deployment only

## Future Work

Phase 2 (Month 2-3): Add anomaly detection using z-score analysis, implement Slack alerting, create Power BI dashboard

Phase 3 (Month 3-4): Add sentiment scoring, build predictive model for 24-hour price momentum

Phase 4 (Month 5-6): Prepare for production deployment (Docker, AWS RDS, CI/CD improvements), complete documentation

## Troubleshooting

PostgreSQL connection fails:
- Check that PostgreSQL is running: psql --version
- Verify credentials in .env match your PostgreSQL user
- Test connection: psql -U data_engineer -d intelligence_market -c "SELECT 1;"

Database already exists:
```bash
psql -U postgres -d postgres << EOF
DROP DATABASE IF EXISTS intelligence_market;
CREATE DATABASE intelligence_market;
EOF
```

Permission denied errors:
```sql
psql -U postgres -d intelligence_market
ALTER USER data_engineer WITH CREATEDB;
GRANT ALL PRIVILEGES ON DATABASE intelligence_market TO data_engineer;
```

Virtual environment not activating:
- Make sure you're in the project directory
- Try creating a fresh venv: rm -rf venv && python -m venv venv
- Then activate again: source venv/bin/activate

API rate limits:
- CoinGecko free tier: 10-50 calls/minute (adjust request intervals in config)
- Binance public API: no authentication needed for price data

## License

MIT License. See LICENSE file for details.

## Author

Tran Duy Hieu
Year 2 student, Information Systems, Hanoi University
Email: tranhieu71tdh@gmail.com
GitHub: https://github.com/HieuTrantdh
LinkedIn: https://www.linkedin.com/in/hieutrantdh-data/

## Status

Phase: MVP Ingestion Pipeline (Week 1-2)
Latest update: 2024-07-04
Last commit: Initial schema and database setup