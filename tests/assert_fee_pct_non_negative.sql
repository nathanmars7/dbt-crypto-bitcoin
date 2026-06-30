select
    transaction_hash,
    fee_pct
from {{ ref('stg_bitcoin_transactions') }}
where fee_pct is not null
  and fee_pct < 0
