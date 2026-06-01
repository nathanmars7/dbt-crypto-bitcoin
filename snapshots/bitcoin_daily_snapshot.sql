{% snapshot bitcoin_daily_snapshot %}

{{
    config(
        target_schema='dbt_crypto_bitcoin_snapshots',
        unique_key='transaction_date',
        strategy='check',
        check_cols=['total_transactions', 'total_volume_btc', 'total_fees_btc']
    )
}}

select * from {{ ref('mart_bitcoin_daily') }}

{% endsnapshot %}