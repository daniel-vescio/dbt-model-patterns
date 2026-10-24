{{ config(materialized='incremental') }}

-- Events never change, so each run just adds what landed since the last one.
-- replace: model and column names

with events as (
    select
        event_id,
        user_id,
        event_name,
        occurred_at,
        _loaded_at
    from {{ ref('stg_app__events') }}
    {% if is_incremental() %}
        -- Load time, not event time: yesterday's event that landed today is still new.
        -- coalesce: on an empty table max() is null, and nothing would ever load
        where _loaded_at > (
            select coalesce(max(fct._loaded_at), '1900-01-01') from {{ this }} as fct
        )
    {% endif %}
)

select * from events
