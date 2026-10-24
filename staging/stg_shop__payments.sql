-- Rename, cast and tidy. No joins, filters or business logic.
-- replace: source, table and column names

with source as (
    select * from {{ source('shop', 'payments') }}
),

renamed as (
    select
        -- keys
        id as payment_id,
        order_id,

        -- attributes
        lower(payment_method) as payment_method,
        lower(status) as payment_status,
        upper(currency) as currency_code,
        coalesce(lower(status) = 'success', false) as is_successful,

        -- amounts (source stores cents, and every currency here has two decimals)
        amount_cents / 100.0 as amount,

        -- timestamps (source stores UTC without a time zone. A plain ::timestamptz
        -- would read them in the session's time zone)
        created at time zone 'UTC' as created_at,
        updated at time zone 'UTC' as updated_at,
        _loaded_at
    from source
)

select * from renamed
