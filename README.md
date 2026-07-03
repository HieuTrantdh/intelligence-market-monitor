\# 🚀 Intelligence Market Monitor



\## Tổng quan



Dự án \*\*end-to-end data pipeline\*\* để phân tích tương quan giữa biến động giá crypto và tin tức thị trường.



\*\*Stack\*\*: Python + PostgreSQL + SQL + GitHub Actions + Power BI



\---



\## 🎯 Mục tiêu



1\. ✅ \*\*Tự động thu thập dữ liệu\*\* từ 3 nguồn (CoinGecko, Binance, News APIs)

2\. ✅ \*\*Kiểm tra chất lượng dữ liệu\*\* (duplicate detection, null checks, freshness)

3\. ✅ \*\*Phát hiện sự bất thường\*\* (anomaly detection, statistical outliers)

4\. ✅ \*\*Cảnh báo tự động\*\* (Slack notifications khi có anomaly)

5\. ✅ \*\*Trực quan hóa\*\* (Dashboard tracking giá, news impact, alerts)



\---



\## 📊 Architecture

┌─────────────────────────────────────────────────────────────┐

│                    INGESTION LAYER                          │

│  CoinGecko API  │  Binance API  │  CryptoPanic Web Scraper  │

└──────────────┬──────────────────────────────────────────────┘

│

┌──────────────▼──────────────────────────────────────────────┐

│                  VALIDATION LAYER                           │

│  Duplicate Check  │  Null Validation  │  Data Freshness    │

└──────────────┬──────────────────────────────────────────────┘

│

┌──────────────▼──────────────────────────────────────────────┐

│              STORAGE (PostgreSQL)                           │

│  Star Schema: Dim\_Coins | Fact\_Prices | Dim\_News           │

└──────────────┬──────────────────────────────────────────────┘

│

┌──────────────▼──────────────────────────────────────────────┐

│           TRANSFORMATION LAYER (SQL)                        │

│  Window Functions | Anomaly Detection | Feature Engineering│

└──────────────┬──────────────────────────────────────────────┘

│

┌──────────────▼──────────────────────────────────────────────┐

│          VISUALIZATION \& ALERTING                           │

│     Power BI Dashboard  │  Slack Alerts  │  Metrics         │

└─────────────────────────────────────────────────────────────┘



\*Detailed architecture: See \[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)\*



\---



\## ⚡ Quick Start



\### Prerequisites

\- Python 3.10+

\- PostgreSQL 13+

\- Git

\- GitHub account



\### 1. Clone Repository

```bash

git clone https://github.com/your-username/intelligence-market-monitor.git

cd intelligence-market-monitor

```



\### 2. Setup Environment

```bash

\# Create virtual environment

python -m venv venv

source venv/bin/activate  # On Windows: venv\\Scripts\\activate



\# Install dependencies

pip install -r requirements.txt

```



\### 3. Configure Database

```bash

\# Copy template

cp .env.example .env



\# Edit .env with your PostgreSQL credentials

nano .env



\# Create database \& tables

psql -U data\_engineer -d intelligence\_market -f sql/schema/initial\_schema.sql

psql -U data\_engineer -d intelligence\_market -f sql/seeds/seed\_coins.sql

```



\### 4. Run Ingestion

```bash

python src/ingestion/run\_ingestion.py

```



\### 5. Check Data

```bash

psql -U data\_engineer -d intelligence\_market



\# Inside psql

SELECT COUNT(\*) FROM fact\_prices;

SELECT COUNT(\*) FROM dim\_news;

```



\---



\## 📁 Project Structure

intelligence-market-monitor/

├── README.md                 ← This file

├── requirements.txt          ← Python dependencies

├── .env.example             ← Config template

├── .gitignore               ← Git exclusions

│

├── src/                     ← Source code

│   ├── ingestion/           ← Fetch data from APIs

│   ├── validation/          ← Data quality checks

│   ├── transformation/      ← SQL transformations

│   └── config.py            ← Config loader

│

├── sql/                     ← Database scripts

│   ├── schema/              ← Create tables

│   ├── queries/             ← Analytical queries

│   └── migrations/          ← Schema updates

│

├── tests/                   ← Unit tests (pytest)

│

├── .github/                 ← GitHub automation

│   └── workflows/           ← CI/CD pipelines

│

└── docs/                    ← Documentation

├── ARCHITECTURE.md      ← System design

├── DATABASE.md          ← Schema \& ER diagram

└── API\_GUIDE.md         ← API usage



\---



\## 🔄 Data Pipeline



\### Ingestion (Phase 1)

\- Fetch prices every 6 hours (CoinGecko, Binance)

\- Scrape news every 2 hours (CryptoPanic, CoinDesk)

\- Validate + deduplicate

\- Load into PostgreSQL



\### Transformation (Phase 2)

\- Calculate moving averages (SQL window functions)

\- Compute price momentum

\- Detect anomalies (z-score)



\### Alerting (Phase 3)

\- Send Slack notification if anomaly detected

\- Log alert in database



\### Visualization (Phase 4)

\- Power BI dashboard

\- Real-time price tracking

\- News impact analysis

\- Alert history



\---



\## 📊 Database Schema



\*\*Fact Tables\*\*:

\- `fact\_prices` — Daily OHLCV data (price\_id, coin\_id, timestamp, open, high, low, close, volume)

\- `fact\_validations` — Data quality logs



\*\*Dimension Tables\*\*:

\- `dim\_coins` — Cryptocurrency master data (coin\_id, name, symbol, market\_cap\_rank)

\- `dim\_news` — News articles (news\_id, title, source, published\_at, sentiment\_score)



\*Full schema: See \[docs/DATABASE.md](docs/DATABASE.md) \& \[sql/schema/initial\_schema.sql](sql/schema/initial\_schema.sql)\*



\---



\## 🛠 Tech Stack



| Component | Technology |

|-----------|------------|

| \*\*Language\*\* | Python 3.10+ |

| \*\*APIs\*\* | CoinGecko, Binance, CryptoPanic |

| \*\*Database\*\* | PostgreSQL 13+ (Star Schema) |

| \*\*SQL\*\* | Window Functions, CTEs, Aggregations |

| \*\*Orchestration\*\* | GitHub Actions (scheduled jobs) |

| \*\*Testing\*\* | pytest |

| \*\*Visualization\*\* | Power BI (optional: Tableau) |

| \*\*Version Control\*\* | Git/GitHub |



\---



\## 📈 Key Features (by Phase)



| Phase | Timeframe | Features |

|-------|-----------|----------|

| \*\*MVP\*\* | Month 1–2 | ✅ Ingestion, Data Quality, Validation |

| \*\*Anomaly Detection\*\* | Month 2–3 | ✅ Statistical Outliers, Alerting, Window Functions |

| \*\*Predictive\*\* | Month 3–4 | ✅ Sentiment Scoring, Coin Momentum (24h forecast) |

| \*\*Production\*\* | Month 5–6 | ✅ Dashboard, Deployment, Full Documentation |



\---



\## 🧪 Testing



```bash

\# Run all tests

pytest



\# Run with coverage

pytest --cov=src tests/



\# Run specific test file

pytest tests/test\_coingecko.py -v

```



\---



\## 📚 Documentation



\- \*\*\[ARCHITECTURE.md](docs/ARCHITECTURE.md)\*\* — System design \& data flow

\- \*\*\[DATABASE.md](docs/DATABASE.md)\*\* — Schema design (ER diagram, normalization)

\- \*\*\[API\_GUIDE.md](docs/API\_GUIDE.md)\*\* — How to use CoinGecko, Binance, CryptoPanic

\- \*\*\[SETUP.md](docs/SETUP.md)\*\* — Detailed environment setup (OS-specific)

\- \*\*\[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)\*\* — Common issues \& solutions



\---



\## 🚀 Deployment (Planned for Phase 4)



\- AWS RDS (PostgreSQL)

\- Docker containerization

\- GitHub Actions CI/CD

\- Monitoring \& alerting

\- Data backup strategy



\---



\## 📊 Success Metrics (6-month goal)



| Metric | Target |

|--------|--------|

| \*\*Commits\*\* | 75+ meaningful commits |

| \*\*Lines of Code\*\* | 6000+ |

| \*\*Test Coverage\*\* | 75%+ |

| \*\*Data Freshness\*\* | 98%+ (no gaps > 1h) |

| \*\*Pipeline Success Rate\*\* | 99%+ |

| \*\*Documentation\*\* | 100% complete |



\---



\## 🤝 Contributing



This is a personal learning project. However, feedback \& issues are welcome!



\---



\## 📄 License



MIT License — See \[LICENSE](LICENSE) file



\---



\## 👨‍💻 Author



\*\*\[Hieu Tran]\*\*  

Year 2 student, Information Systems, Hanoi University  

Building this project for internship opportunities in Data Engineering / Data Science



\---



\## 📞 Contact



\- \*\*GitHub\*\*: \[HieuTran](https://github.com/HieuTrantdh)

\- \*\*Email\*\*: tranhieu71tdh@gmail.com

\- \*\*LinkedIn\*\*: \[Duy Hieu Tran](https://www.linkedin.com/in/hieutrantdh-data/)



\---



\## 📝 Changelog



\### v0.1.0 (Week 1)

\- ✅ Project structure created

\- ✅ Database schema designed

\- ✅ README skeleton + documentation

\- 🚧 Ingestion layer (coming Week 2)



\---



\*\*Last Updated\*\*: \[Today's Date]  

\*\*Status\*\*: 🟡 In Progress (Phase 1: MVP Ingestion)

