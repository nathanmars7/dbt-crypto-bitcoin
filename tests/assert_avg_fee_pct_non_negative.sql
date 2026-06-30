-- avg_fee_pct must be >= 0 when present.
select
    transaction_date,
    avg_fee_pct
from {{ ref('mart_bitcoin_daily') }}
where avg_fee_pct is not null
  and avg_fee_pct < 0