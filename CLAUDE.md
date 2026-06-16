# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A dbt Core project that transforms raw Bitcoin blockchain data from BigQuery's public dataset (`bigquery-public-data.crypto_bitcoin.transactions`, scoped to 2023) into tested daily and monthly transaction-metric marts, with a snapshot tracking historical change. Adapter: **dbt-bigquery**; profile name `dbt_crypto_bitcoin` (auth via gcloud OAuth/ADC).

## Commands

```bash
dbt debug                                    # validate connection + profiles.yml
dbt build                                    # run + test + snapshot, full DAG (~19 GiB scan)
dbt build --select mart_bitcoin_daily        # one model + its tests
dbt build --select stg_bitcoin_transactions+ # a model and everything downstream
```

There is no separate lint step; `dbt build` is the verification gate. Always run `dbt build` (not just `dbt compile`) to confirm a change — compile does not catch database errors. Standard `dbt run`/`test`/`show`/`snapshot` work as usual.

## Architecture

Three-layer DAG, all under `models/`:

- **`stg_bitcoin_transactions`** (staging, **view**) — reads the source, renames columns, converts Satoshis to BTC (`value / 1e8`), and filters to 2023. The only model that touches the raw source.
- **`mart_bitcoin_daily`** (mart, table) — daily aggregates (transactions, volume, fees) plus 7-day moving averages via window functions. The only consumer of staging.
- **`mart_bitcoin_monthly`** (mart, table) — monthly rollup built **from the daily mart** (`ref('mart_bitcoin_daily')`), not from staging or source.
- **`bitcoin_daily_snapshot`** (snapshot) — `check` strategy on `total_transactions`, `total_volume_btc`, `total_fees_btc`; SCD Type 2 over the daily mart. Lives in schema `dbt_crypto_bitcoin_snapshots`.

Data flow: `source → stg (view) → mart_daily (table) → mart_monthly (table) / snapshot`.

## Project-specific gotchas

- **Partition-pruning rule (critical for cost):** the source table is partitioned on **`block_timestamp_month`** (a `DATE` column), *not* on `block_timestamp`. Any filter must include a `block_timestamp_month` predicate or BigQuery scans every partition of the 2.5 TB table. The current staging filter pairs `block_timestamp_month` (for pruning) with `block_timestamp` (for exact day boundaries). Filtering `block_timestamp` alone costs ~177 GiB; with the partition predicate it's ~19 GiB (~88% less) for identical results. Never drop the `block_timestamp_month` bound when editing the staging WHERE clause.
- **Staging stays a view by design.** Materializing `stg_bitcoin_transactions` as a table was measured and is *more* expensive here: because pruning already makes the source scan cheap (~19 GiB) and only one model reads staging, a table costs more on both full builds (~40 GiB) and marts-only rebuilds (~20 GiB) and adds standing storage. Do not change it to a table without re-measuring — the tradeoff only flips if multiple models fan out from staging.
- **BigQuery reserved word `hash`** must be backtick-quoted (`` `hash` ``) when referencing the source column.
- **`fee_pct`** uses `nullif(output_value, 0)` to avoid divide-by-zero; keep that guard.

## Verifying cost cheaply

Before large changes, estimate bytes with a free BigQuery dry run instead of a build.
Use the python from dbt's env (it has google-cloud-bigquery):

    python -c "from google.cloud import bigquery; c=bigquery.Client(); \
    j=c.query('<sql>', job_config=bigquery.QueryJobConfig(dry_run=True)); \
    print(j.total_bytes_processed/1024**3,'GiB')"
