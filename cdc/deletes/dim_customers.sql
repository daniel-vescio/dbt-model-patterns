{{
    config(
        materialized='incremental',
        unique_key='customer_id',
        incremental_strategy='merge'
    )
}}

-- Current state of each customer, keeping deleted customers as soft deletes.
-- Consumers filter with: where not is_deleted
-- To hard delete instead, add to the config: post_hook="delete from {{ this }} where is_deleted"
-- replace: model, key and column names

with changes as (
    select * from {{ ref('stg_cdc__customer_changes') }}
    {% if is_incremental() %}
        where _loaded_at > (select max(dim._loaded_at) from {{ this }} as dim)
    {% endif %}
),

ranked as (
    select
        *,
        row_number() over (
            partition by customer_id
            order by _source_lsn desc
        ) as change_rank
    from changes
),

latest as (
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
)

select * from latest
