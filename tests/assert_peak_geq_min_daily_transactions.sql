-- peak_daily_transactions must be >= min_daily_transactions within each month.
select
    transaction_month,
    peak_daily_transactions,
    min_daily_transactions
from {{ ref('mart_bitcoin_monthly') }}
where peak_daily_transactions < min_daily_transactions