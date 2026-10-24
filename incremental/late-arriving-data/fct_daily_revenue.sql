{{
    config(
        materialized='incremental',
        unique_key='order_date',
        incremental_strategy='delete+insert'
    )
}}

-- Recomputes the last few days every run, so late or changed orders still update their day.
-- Widen the window for one run: dbt run -s fct_daily_revenue --vars '{revenue_lookback_days: 30}'
-- replace: model, grain and measures

{% set lookback_days = var('revenue_lookback_days', 3) %}

with orders as (
    select
        order_status,
        order_total,
        created_at::date as order_date
    from {{ ref('stg_shop__orders') }}
    {% if is_incremental() %}
        -- Counted back from the table's latest day, so a missed run doesn't leave a gap
        where created_at::date >= (
            select max(fct.order_date) - {{ lookback_days }} from {{ this }} as fct
        )
    {% endif %}
),

daily as (
    select
        order_date,
        count(*) as orders_placed,
        sum(case when order_status <> 'cancelled' then 1 else 0 end) as orders_kept,
        coalesce(sum(case when order_status <> 'cancelled' then order_total end), 0) as revenue
    from orders
    group by order_date
)

select * from daily
