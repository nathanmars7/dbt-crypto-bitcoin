with daily as (

    select * from {{ ref('mart_bitcoin_daily') }}

),

final as (

    select
        DATE_TRUNC(transaction_date, MONTH)             as transaction_month,
        count(transaction_date)                         as total_days,
        sum(total_transactions)                         as total_transactions,
        round(sum(total_volume_btc), 4)                 as total_volume_btc,
        round(avg(avg_transaction_btc), 4)              as avg_transaction_btc,
        round(sum(total_fees_btc), 4)                   as total_fees_btc,
        round(avg(avg_fee_btc), 8)                      as avg_fee_btc,
        round(avg(avg_fee_pct), 4)                      as avg_fee_pct,
        round(max(total_transactions), 0)               as peak_daily_transactions,
        round(min(total_transactions), 0)               as min_daily_transactions
    from daily
    group by DATE_TRUNC(transaction_date, MONTH)
    order by transaction_month

)

select * from final