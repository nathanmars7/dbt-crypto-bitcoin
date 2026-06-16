# dbt Crypto Bitcoin Analytics

A hands-on dbt project analysing Bitcoin blockchain transaction patterns using **dbt Core** and **Google BigQuery**, featuring dbt Snapshots for tracking historical changes.

## Project Overview

This project transforms raw Bitcoin blockchain data from BigQuery's public datasets into clean, tested, and documented analytical models — including daily and monthly transaction metrics with 7-day moving averages.

## Tech Stack

- **dbt Core** 1.11
- **Google BigQuery**
- **Python** 3.13

## Data Source

| Source | Dataset | Description |
|--------|---------|-------------|
| Bitcoin transactions | `bigquery-public-data.crypto_bitcoin.transactions` | Every Bitcoin transaction recorded on the blockchain in 2023 |

## Project Structure

    models/
    ├── staging/
    │   ├── sources.yml
    │   ├── schema.yml
    │   └── stg_bitcoin_transactions.sql
    └── marts/
        ├── schema.yml
        ├── mart_bitcoin_daily.sql
        └── mart_bitcoin_monthly.sql
    snapshots/
    └── bitcoin_daily_snapshot.sql

## Models

| Model | Materialization | Description |
|-------|----------------|-------------|
| `stg_bitcoin_transactions` | View | Cleans raw blockchain data, converts Satoshis to BTC |
| `mart_bitcoin_daily` | Table | Daily metrics — transactions, volume, fees, 7-day moving averages |
| `mart_bitcoin_monthly` | Table | Monthly rollup referencing the daily mart |
| `bitcoin_daily_snapshot` | Snapshot | Tracks historical changes to daily metrics over time |

## Key Concepts Demonstrated

- **Three-layer DAG** — staging → daily mart → monthly mart
- **Satoshi to BTC conversion** — `value / 1e8` for correct Bitcoin denomination
- **Window functions** — 7-day moving average using `rows between 6 preceding and current row`
- **Mart-to-mart references** — `mart_bitcoin_monthly` references `mart_bitcoin_daily` via `ref()`
- **Snapshots** — `check` strategy tracking changes to `total_transactions`, `total_volume_btc`, `total_fees_btc`
- **SCD Type 2** — `dbt_valid_from` and `dbt_valid_to` columns for full history tracking
- **Reserved keyword handling** — backtick quoting for BigQuery reserved words like `hash`

## Performance

`stg_bitcoin_transactions` filters on `block_timestamp_month`, the source table's partition column, so BigQuery applies **partition pruning** and reads only the relevant 2023 partitions instead of the full 2.5 TB history. This cuts the daily mart's build scan from **156.5 GiB to 18.6 GiB (~88%)** with identical results — still 365 daily rows and 12 monthly rows. The lesson: always filter on the partition column, not just a related timestamp, or the optimizer can't prune.

## Key Insight

Bitcoin transaction activity in 2023 showed a massive volume spike in late April/May driven by the Ordinals/BRC-20 token craze, followed by a steady climb in transaction counts through Q4 as the market entered a new bull cycle.

## Getting Started

### Prerequisites

- Python 3.13+
- Google Cloud account with BigQuery enabled
- dbt Core with BigQuery adapter

### Setup

    git clone https://github.com/nathanmars7/dbt-crypto-bitcoin.git
    cd dbt-crypto-bitcoin
    python3 -m venv venv
    source venv/bin/activate
    pip install dbt-bigquery
    gcloud auth application-default login
    dbt debug

### Running the Project

    dbt run
    dbt test
    dbt snapshot
    dbt docs generate
    dbt docs serve