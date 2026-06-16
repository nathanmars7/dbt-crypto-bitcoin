-- Reconcile additive metrics between the daily and monthly Bitcoin marts.
-- Monthly is a rollup of daily, so per-month sums of the additive daily metrics
-- must equal the monthly totals:
--   total_transactions  -> exact (integer count)
--   total_volume_btc     -> within 1e-8 (float)
--   total_fees_btc       -> within 1e-8 (float)
-- Reads only the two mart tables (no staging/source scan). Passes when 0 rows.

with daily_rollup as (

    select
        date_trunc(transaction_date, month)   as transaction_month,
        sum(total_transactions)               as total_transactions,
        sum(total_volume_btc)                 as total_volume_btc,
        sum(total_fees_btc)                   as total_fees_btc
    from {{ ref('mart_bitcoin_daily') }}
    group by 1

),

monthly as (

    select
        transaction_month,
        total_transactions,
        total_volume_btc,
        total_fees_btc
    from {{ ref('mart_bitcoin_monthly') }}

),

reconciled as (

    select
        coalesce(m.transaction_month, d.transaction_month) as transaction_month,
        d.total_transactions as daily_transactions,
        m.total_transactions as monthly_transactions,
        d.total_volume_btc   as daily_volume_btc,
        m.total_volume_btc   as monthly_volume_btc,
        d.total_fees_btc     as daily_fees_btc,
        m.total_fees_btc     as monthly_fees_btc
    from monthly m
    full outer join daily_rollup d using (transaction_month)

)

select *
from reconciled
where
    daily_transactions is null
    or monthly_transactions is null
    or daily_transactions != monthly_transactions
    or abs(daily_volume_btc - monthly_volume_btc) > 1e-8
    or abs(daily_fees_btc - monthly_fees_btc) > 1e-8
