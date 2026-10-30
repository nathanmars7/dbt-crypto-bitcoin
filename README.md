# dbt Crypto Bitcoin Analytics

A dbt Core project on Google BigQuery that turns the public Bitcoin blockchain transaction table into tested daily and monthly transaction-metric marts, with a dbt snapshot that records how the daily metrics change over time. It is a portfolio project built to practise a small staged DAG, window functions, snapshots and cost-aware querying on BigQuery.

## At a glance

| | |
|---|---|
| Stack | dbt Core 1.11, dbt-bigquery, dbt_utils (see `packages.yml`) |
| Warehouse | Google BigQuery |
| Data | `bigquery-public-data.crypto_bitcoin.transactions`, filtered to calendar year 2023 |
| What it shows | Staging view to daily mart to monthly mart, 7-day moving averages, a `check` strategy snapshot (SCD Type 2), schema and singular tests, partition pruning on the source table |
| Status | Portfolio project, complete. Last verified 2026-06 from the repo contents. |

## Project structure

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
    tests/
    ├── assert_avg_fee_pct_non_negative.sql
    ├── assert_daily_monthly_reconcile.sql
    ├── assert_fee_pct_non_negative.sql
    └── assert_peak_geq_min_daily_transactions.sql

Data flow: `source -> stg_bitcoin_transactions (view) -> mart_bitcoin_daily (table) -> mart_bitcoin_monthly (table)`, with `bitcoin_daily_snapshot` reading the daily mart. Materializations are set in `dbt_project.yml`: staging as views, marts as tables.

## Run it

You need Python 3, a Google Cloud project with BigQuery enabled, and the `gcloud` CLI for authentication.

    git clone https://github.com/nathanmars7/dbt-crypto-bitcoin.git
    cd dbt-crypto-bitcoin
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt

Authenticate to Google Cloud and create a dbt profile named `dbt_crypto_bitcoin` (the name set in `dbt_project.yml`) in `~/.dbt/profiles.yml`:

    gcloud auth application-default login

    dbt_crypto_bitcoin:
      target: dev
      outputs:
        dev:
          type: bigquery
          method: oauth
          project: <your-gcp-project-id>
          dataset: dbt_crypto_bitcoin
          location: US
          threads: 4

The source dataset is public, so any project with BigQuery enabled can query it. The snapshot writes to a separate dataset, `dbt_crypto_bitcoin_snapshots`, set in `snapshots/bitcoin_daily_snapshot.sql`.

Then build:

    dbt debug
    dbt deps
    dbt build
    dbt docs generate
    dbt docs serve

`dbt build` runs the models, tests and snapshot in dependency order. To run them separately use `dbt run`, `dbt test` and `dbt snapshot`. There are no seeds.

The staging model filters on `block_timestamp_month`, the source table's partition column, so BigQuery prunes partitions and reads only the 2023 slices of the source rather than the full history. Keep that predicate when editing the staging `where` clause.

## Models

| Name | Type | Description |
|---|---|---|
| `stg_bitcoin_transactions` | View | Cleaned 2023 transactions. Renames `hash` to `transaction_hash`, converts Satoshis to BTC (`value / 1e8`), derives `transaction_date` and `fee_pct` |
| `mart_bitcoin_daily` | Table | One row per day: transaction count, volume, fees, averages and 7-day moving averages of count and volume |
| `mart_bitcoin_monthly` | Table | One row per month, rolled up from the daily mart: totals, averages, peak and minimum daily transaction counts |
| `bitcoin_daily_snapshot` | Snapshot | SCD Type 2 history of the daily mart, `check` strategy on `total_transactions`, `total_volume_btc`, `total_fees_btc` |
| `assert_fee_pct_non_negative` | Singular test | No staging row has a negative `fee_pct` |
| `assert_avg_fee_pct_non_negative` | Singular test | No daily row has a negative `avg_fee_pct` |
| `assert_daily_monthly_reconcile` | Singular test | Per-month sums of the daily mart's additive metrics match the monthly mart |
| `assert_peak_geq_min_daily_transactions` | Singular test | `peak_daily_transactions` is at least `min_daily_transactions` in every month |

Column-level tests (`not_null`, `unique`, `dbt_utils.accepted_range`) are declared in the `schema.yml` files next to the models.

## Portfolio

Part of a set of data engineering portfolio projects:

- https://github.com/nathanmars7/dbt-analytics-engineering : dbt on DuckDB and Snowflake from one codebase
- https://github.com/nathanmars7/jaffle-shop-snowflake : minimal dbt starter on Snowflake
- https://github.com/nathanmars7/dbt-nyc-citibike : dbt on BigQuery, Citibike ridership vs weather
- https://github.com/nathanmars7/dbt-crypto-bitcoin : dbt on BigQuery with snapshots, Bitcoin transactions (this repo)
- https://github.com/nathanmars7/dbt-learning : dbt on BigQuery, Chicago taxi trips, incremental models
- https://github.com/nathanmars7/pyspark-fraud-pipeline : PySpark and Delta Lake medallion pipeline on Databricks
