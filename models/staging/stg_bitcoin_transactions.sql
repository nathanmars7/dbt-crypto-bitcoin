with source as (

    select * from {{ source('crypto_bitcoin', 'transactions') }}

),

renamed as (

    select
        `hash`                                                      as transaction_hash,                                                        
        block_timestamp,
        DATE(block_timestamp)                                       as transaction_date,
        input_count,
        output_count,
        round(input_value / 1e8, 8)                                as input_value_btc,
        round(output_value / 1e8, 8)                               as output_value_btc,
        round(fee / 1e8, 8)                                        as fee_btc,
        round((fee / nullif(output_value, 0)) * 100, 4)            as fee_pct
    from source
    -- Partition pruning: block_timestamp_month is the table's partition column.
    -- Filtering it limits the scan to 2023 partitions; the block_timestamp
    -- predicates below keep the exact day-level boundaries.
    where block_timestamp_month >= '2023-01-01'
        and block_timestamp_month < '2024-01-01'
        and block_timestamp is not null
        and block_timestamp >= '2023-01-01'
        and block_timestamp < '2024-01-01'

)

select * from renamed