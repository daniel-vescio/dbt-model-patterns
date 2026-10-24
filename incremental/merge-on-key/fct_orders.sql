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
        -- Everything that landed since the last run, whatever its updated_at
        where _loaded_at > (select max(fct._loaded_at) from {{ this }} as fct)
    {% endif %}
)

select * from orders
