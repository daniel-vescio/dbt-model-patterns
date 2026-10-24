-- One row per payment. Latest version wins, with tie-breakers so it's the same row every run.
-- replace: model, key and ordering columns

with payments as (
    select * from {{ ref('stg_shop__payments') }}
),

ranked as (
    select
        *,
        row_number() over (
            partition by payment_id
            order by
                updated_at desc nulls last,  -- the rule: latest version
                _loaded_at desc,              -- tie-breaker: most recently loaded copy
                md5(payments::text)           -- last resort: a hash of the whole row
        ) as row_num
    from payments
),

deduplicated as (
    select
        payment_id,
        order_id,
        payment_method,
        payment_status,
        currency_code,
        amount,
        is_successful,
        created_at,
        updated_at,
        _loaded_at
    from ranked
    where row_num = 1
)

select * from deduplicated
