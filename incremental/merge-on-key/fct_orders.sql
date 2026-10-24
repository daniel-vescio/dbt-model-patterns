{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge'
    )
}}

-- New orders get inserted, changed orders get updated in place.
-- merge needs Postgres 15+. Use 'delete+insert' on older versions.
-- replace: model, key and column names

with orders as (
    select
        order_id,
        customer_id,
        order_status,
        order_total,
        created_at,
        updated_at,
        _loaded_at
    from {{ ref('stg_shop__orders') }}
    {% if is_incremental() %}
        -- Everything that landed since the last run, whatever its updated_at.
        -- coalesce: on an empty table max() is null, and nothing would ever load
        where _loaded_at > (
            select coalesce(max(fct._loaded_at), '1900-01-01') from {{ this }} as fct
        )
    {% endif %}
),

-- One row per order in the batch. Two versions of the same order would make merge
-- error or insert both.
ranked as (
    select
        *,
        row_number() over (
            partition by order_id
            order by
                updated_at desc nulls last,  -- latest version wins
                _loaded_at desc               -- tie-breaker: most recently loaded copy
        ) as row_num
    from orders
),

latest as (
    select
        order_id,
        customer_id,
        order_status,
        order_total,
        created_at,
        updated_at,
        _loaded_at
    from ranked
    where row_num = 1
)

select * from latest
