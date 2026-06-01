with transactions as (

    select * from {{ ref('stg_bitcoin_transactions') }}

),

daily as (

    select
        transaction_date,
        count(transaction_hash)                         as total_transactions,
        round(sum(output_value_btc), 4)                 as total_volume_btc,
        round(avg(output_value_btc), 4)                 as avg_transaction_btc,
        round(sum(fee_btc), 4)                          as total_fees_btc,
        round(avg(fee_btc), 8)                          as avg_fee_btc,
        round(avg(fee_pct), 4)                          as avg_fee_pct,
        round(avg(input_count), 2)                      as avg_input_count,
        round(avg(output_count), 2)                     as avg_output_count
    from transactions
    group by transaction_date

),

final as (

    select
        transaction_date,
        total_transactions,
        total_volume_btc,
        avg_transaction_btc,
        total_fees_btc,
        avg_fee_btc,
        avg_fee_pct,
        avg_input_count,
        avg_output_count,
        round(avg(total_transactions) over (
            order by transaction_date
            rows between 6 preceding and current row
        ), 0)                                           as transactions_7d_avg,
        round(avg(total_volume_btc) over (
            order by transaction_date
            rows between 6 preceding and current row
        ), 4)                                           as volume_7d_avg_btc
    from daily
    order by transaction_date

)

select * from final