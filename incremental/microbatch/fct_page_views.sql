{{
    config(
        materialized='incremental',
        incremental_strategy='microbatch',
        event_time='occurred_at',
        batch_size='day',
        lookback=3,
        begin='2025-01-01',
        unique_key='event_id'
    )
}}

-- dbt builds one day at a time and filters upstream models to that day using their
-- event_time, so there's no is_incremental() block.
-- Postgres needs unique_key and Postgres 15+ for this.
-- replace: model, columns and begin date

select
    event_id,
    user_id,
    page_path,
    occurred_at,
    occurred_at::date as event_date
from {{ ref('stg_app__events') }}
where event_name = 'page_view'
