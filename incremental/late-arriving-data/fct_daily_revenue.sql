{{
    config(
        materialized='incremental',
        unique_key='order_date',
        incremental_strategy='delete+insert'
    )
}}

-- Recomputes the last few days every run, so late or changed orders still update their day.
-- Widen the window for one run: dbt run -s fct_daily_revenue --vars '{revenue_lookback_days: 30}'
-- replace: model, grain, measures and reporting time zone

{% set lookback_days = var('revenue_lookback_days', 3) %}
{% set reporting_time_zone = 'UTC' %}

with orders as (
    select
        order_status,
        order_total,
        -- Explicit time zone, so the day doesn't depend on the session running the model
        (created_at at time zone '{{ reporting_time_zone }}')::date as order_date
    from {{ ref('stg_shop__orders') }}
    {% if is_incremental() %}
        -- Counted back from the table's latest day, so a missed run doesn't leave a gap.
        -- coalesce: on an empty table max() is null, and nothing would ever load
        where (created_at at time zone '{{ reporting_time_zone }}')::date >= (
            select coalesce(max(fct.order_date), '1900-01-01') - {{ lookback_days }}
            from {{ this }} as fct
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
