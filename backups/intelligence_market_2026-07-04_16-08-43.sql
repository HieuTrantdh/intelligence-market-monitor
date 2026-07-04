--
-- PostgreSQL database dump
--

\restrict aOvEXa4bgK1EIvExPqGXyAZNtwXpoeZSjEnuIaX4htV813b4Agbl5PPyu109iic

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-07-04 16:08:43

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 16553)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5112 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 3 (class 3079 OID 16734)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 5113 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 16745)
-- Name: dim_coins; Type: TABLE; Schema: public; Owner: data_engineer
--

CREATE TABLE public.dim_coins (
    coin_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    symbol character varying(10) NOT NULL,
    market_cap_rank integer,
    coingecko_id character varying(50),
    binance_symbol character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.dim_coins OWNER TO data_engineer;

--
-- TOC entry 223 (class 1259 OID 16785)
-- Name: dim_news; Type: TABLE; Schema: public; Owner: data_engineer
--

CREATE TABLE public.dim_news (
    news_id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying(500) NOT NULL,
    summary text,
    source character varying(100) NOT NULL,
    url character varying(1000),
    published_at timestamp without time zone NOT NULL,
    sentiment_label character varying(20),
    sentiment_score numeric(5,3),
    relevant_coins character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.dim_news OWNER TO data_engineer;

--
-- TOC entry 222 (class 1259 OID 16762)
-- Name: fact_prices; Type: TABLE; Schema: public; Owner: data_engineer
--

CREATE TABLE public.fact_prices (
    price_id uuid DEFAULT gen_random_uuid() NOT NULL,
    coin_id uuid NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    open numeric(20,8),
    high numeric(20,8),
    low numeric(20,8),
    close numeric(20,8),
    volume numeric(20,2),
    source character varying(50) NOT NULL,
    ingestion_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fact_prices_close_check CHECK ((close IS NOT NULL)),
    CONSTRAINT fact_prices_close_check1 CHECK ((close >= (0)::numeric))
);


ALTER TABLE public.fact_prices OWNER TO data_engineer;

--
-- TOC entry 224 (class 1259 OID 16803)
-- Name: fact_validations; Type: TABLE; Schema: public; Owner: data_engineer
--

CREATE TABLE public.fact_validations (
    validation_id uuid DEFAULT gen_random_uuid() NOT NULL,
    pipeline_step character varying(50) NOT NULL,
    table_name character varying(50) NOT NULL,
    validation_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total_records integer,
    valid_records integer,
    invalid_records integer,
    error_log jsonb,
    status character varying(20),
    duration_seconds integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.fact_validations OWNER TO data_engineer;

--
-- TOC entry 5103 (class 0 OID 16745)
-- Dependencies: 221
-- Data for Name: dim_coins; Type: TABLE DATA; Schema: public; Owner: data_engineer
--

COPY public.dim_coins (coin_id, name, symbol, market_cap_rank, coingecko_id, binance_symbol, created_at, updated_at) FROM stdin;
89053d68-bcd2-470e-b743-a58a860f25ce	Bitcoin	BTC	1	bitcoin	BTCUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
ce486bac-599c-4233-8df9-8cc413a0754e	Ethereum	ETH	2	ethereum	ETHUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
2aca3478-3a79-4892-9af9-db14b4d410f0	Tether	USDT	3	tether	USDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
6db64b1d-603d-4bb1-8b83-ab78e58b3ae6	Binance Coin	BNB	4	binancecoin	BNBUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
2c00c445-3e66-427b-83c3-7458fc147fdb	XRP	XRP	5	ripple	XRPUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
7228c1ba-769d-48ae-a02e-4c9cd266b779	Cardano	ADA	6	cardano	ADAUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
929f4e5c-c1ed-43f9-9e8f-77327a78bdb1	Solana	SOL	7	solana	SOLUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
5326e947-5e00-4654-b936-8516a0038b91	Polkadot	DOT	8	polkadot	DOTUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
e1d4b53f-7d05-459a-82aa-eb400553a2af	Dogecoin	DOGE	9	dogecoin	DOGEUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
ce387a30-4aa7-49a9-8962-75b06a4f3070	Polygon	MATIC	10	matic-network	MATICUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
8bf3017a-1c24-410c-ae37-9705e068350b	Litecoin	LTC	11	litecoin	LTCUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
11822d78-0573-4960-9961-2c61d167e1dd	Bitcoin Cash	BCH	12	bitcoin-cash	BCHUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
1e91311f-58a6-4181-a373-005c060aabc4	Chainlink	LINK	13	chainlink	LINKUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
fd8e627d-75cd-47fd-81a9-b87d1ee7b8e2	Stellar	XLM	14	stellar	XLMUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
3fd9989e-0a48-47bf-a2ad-571bb293007e	Uniswap	UNI	15	uniswap	UNIUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
33dad532-199b-42d0-af51-5f797519776b	Monero	XMR	16	monero	XMRUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
0e5890c2-b072-4840-af03-aab400c9f46a	Cosmos	ATOM	17	cosmos	ATOMUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
fb6934c6-9d0b-4658-8672-977d4d461cd2	Avalanche	AVAX	18	avalanche-2	AVAXUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
09a29edf-a376-44c2-85ea-fa70001858d2	Cro	CRO	19	crypto-com-chain	CROUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
0cb677ae-0501-47cc-bac9-f6c96d17e70f	Aave	AAVE	20	aave	AAVEUSDT	2026-07-03 10:58:41.98329	2026-07-03 10:58:41.98329
\.


--
-- TOC entry 5105 (class 0 OID 16785)
-- Dependencies: 223
-- Data for Name: dim_news; Type: TABLE DATA; Schema: public; Owner: data_engineer
--

COPY public.dim_news (news_id, title, summary, source, url, published_at, sentiment_label, sentiment_score, relevant_coins, created_at) FROM stdin;
\.


--
-- TOC entry 5104 (class 0 OID 16762)
-- Dependencies: 222
-- Data for Name: fact_prices; Type: TABLE DATA; Schema: public; Owner: data_engineer
--

COPY public.fact_prices (price_id, coin_id, "timestamp", open, high, low, close, volume, source, ingestion_timestamp) FROM stdin;
\.


--
-- TOC entry 5106 (class 0 OID 16803)
-- Dependencies: 224
-- Data for Name: fact_validations; Type: TABLE DATA; Schema: public; Owner: data_engineer
--

COPY public.fact_validations (validation_id, pipeline_step, table_name, validation_timestamp, total_records, valid_records, invalid_records, error_log, status, duration_seconds, created_at) FROM stdin;
\.


--
-- TOC entry 4929 (class 2606 OID 16759)
-- Name: dim_coins dim_coins_coingecko_id_key; Type: CONSTRAINT; Schema: public; Owner: data_engineer
--

ALTER TABLE ONLY public.dim_coins
    ADD CONSTRAINT dim_coins_coingecko_id_key UNIQUE (coingecko_id);


--
-- TOC entry 4931 (class 2606 OID 16755)
-- Name: dim_coins dim_coins_pkey; Type: CONSTRAINT; Schema: public; Owner: data_engineer
--

ALTER TABLE ONLY public.dim_coins
    ADD CONSTRAINT dim_coins_pkey PRIMARY KEY (coin_id);


--
-- TOC entry 4933 (class 2606 OID 16757)
-- Name: dim_coins dim_coins_symbol_key; Type: CONSTRAINT; Schema: public; Owner: data_engineer
--

ALTER TABLE ONLY public.dim_coins
    ADD CONSTRAINT dim_coins_symbol_key UNIQUE (symbol);


--
-- TOC entry 4944 (class 2606 OID 16797)
-- Name: dim_news dim_news_pkey; Type: CONSTRAINT; Schema: public; Owner: data_engineer
--

ALTER TABLE ONLY public.dim_news
    ADD CONSTRAINT dim_news_pkey PRIMARY KEY (news_id);


--
-- TOC entry 4937 (class 2606 OID 16774)
-- Name: fact_prices fact_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: data_engineer
--

ALTER TABLE ONLY public.fact_prices
    ADD CONSTRAINT fact_prices_pkey PRIMARY KEY (price_id);


--
-- TOC entry 4951 (class 2606 OID 16816)
-- Name: fact_validations fact_validations_pkey; Type: CONSTRAINT; Schema: public; Owner: data_engineer
--

ALTER TABLE ONLY public.fact_validations
    ADD CONSTRAINT fact_validations_pkey PRIMARY KEY (validation_id);


--
-- TOC entry 4949 (class 2606 OID 16799)
-- Name: dim_news unique_news; Type: CONSTRAINT; Schema: public; Owner: data_engineer
--

ALTER TABLE ONLY public.dim_news
    ADD CONSTRAINT unique_news UNIQUE (title, source, published_at);


--
-- TOC entry 4942 (class 2606 OID 16776)
-- Name: fact_prices unique_price; Type: CONSTRAINT; Schema: public; Owner: data_engineer
--

ALTER TABLE ONLY public.fact_prices
    ADD CONSTRAINT unique_price UNIQUE (coin_id, "timestamp", source);


--
-- TOC entry 4934 (class 1259 OID 16760)
-- Name: idx_dim_coins_coingecko_id; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_dim_coins_coingecko_id ON public.dim_coins USING btree (coingecko_id);


--
-- TOC entry 4935 (class 1259 OID 16761)
-- Name: idx_dim_coins_symbol; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_dim_coins_symbol ON public.dim_coins USING btree (symbol);


--
-- TOC entry 4945 (class 1259 OID 16800)
-- Name: idx_dim_news_published_at; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_dim_news_published_at ON public.dim_news USING btree (published_at);


--
-- TOC entry 4946 (class 1259 OID 16802)
-- Name: idx_dim_news_sentiment; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_dim_news_sentiment ON public.dim_news USING btree (sentiment_label);


--
-- TOC entry 4947 (class 1259 OID 16801)
-- Name: idx_dim_news_source; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_dim_news_source ON public.dim_news USING btree (source);


--
-- TOC entry 4938 (class 1259 OID 16782)
-- Name: idx_fact_prices_coin_timestamp; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_fact_prices_coin_timestamp ON public.fact_prices USING btree (coin_id, "timestamp");


--
-- TOC entry 4939 (class 1259 OID 16784)
-- Name: idx_fact_prices_source; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_fact_prices_source ON public.fact_prices USING btree (source);


--
-- TOC entry 4940 (class 1259 OID 16783)
-- Name: idx_fact_prices_timestamp; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_fact_prices_timestamp ON public.fact_prices USING btree ("timestamp");


--
-- TOC entry 4952 (class 1259 OID 16819)
-- Name: idx_fact_validations_status; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_fact_validations_status ON public.fact_validations USING btree (status);


--
-- TOC entry 4953 (class 1259 OID 16817)
-- Name: idx_fact_validations_table; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_fact_validations_table ON public.fact_validations USING btree (table_name);


--
-- TOC entry 4954 (class 1259 OID 16818)
-- Name: idx_fact_validations_timestamp; Type: INDEX; Schema: public; Owner: data_engineer
--

CREATE INDEX idx_fact_validations_timestamp ON public.fact_validations USING btree (validation_timestamp);


--
-- TOC entry 4955 (class 2606 OID 16777)
-- Name: fact_prices fact_prices_coin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: data_engineer
--

ALTER TABLE ONLY public.fact_prices
    ADD CONSTRAINT fact_prices_coin_id_fkey FOREIGN KEY (coin_id) REFERENCES public.dim_coins(coin_id) ON DELETE CASCADE;


-- Completed on 2026-07-04 16:08:43

--
-- PostgreSQL database dump complete
--

\unrestrict aOvEXa4bgK1EIvExPqGXyAZNtwXpoeZSjEnuIaX4htV813b4Agbl5PPyu109iic

