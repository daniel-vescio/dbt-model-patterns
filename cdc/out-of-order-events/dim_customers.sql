{{
    config(
        materialized='incremental',
        unique_key='customer_id',
        incremental_strategy='merge'
    )
}}

-- Incremental current state that ignores late and duplicate events.
-- replace: model, key and column names

with changes as (
    select * from {{ ref('stg_cdc__customer_changes') }}
    {% if is_incremental() %}
        where _loaded_at > (select max(dim._loaded_at) from {{ this }} as dim)
    {% endif %}
),

-- Guard 1: newest event per customer within the batch
ranked as (
    select
        *,
        row_number() over (
            partition by customer_id
            order by _source_lsn desc
        ) as change_rank
    from changes
),

newest_in_batch as (
    select
        customer_id,
        email,
        full_name,
        customer_tier,
        _op = 'd' as is_deleted,
        case when _op = 'd' then _source_ts end as deleted_at,
        _source_ts as last_changed_at,
        _source_lsn,
        _loaded_at
    from ranked
    where change_rank = 1
),

-- Guard 2: only apply it if it's newer than what's already in the table
applicable as (
    select newest_in_batch.*
    from newest_in_batch
    {% if is_incremental() %}
        left join {{ this }} as loaded
            on newest_in_batch.customer_id = loaded.customer_id
        where
            loaded.customer_id is null
            or newest_in_batch._source_lsn > loaded._source_lsn
    {% endif %}
)

select * from applicable
