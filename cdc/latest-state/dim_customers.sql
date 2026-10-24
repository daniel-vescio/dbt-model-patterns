{{ config(materialized='table') }}

-- Latest event per customer, rebuilt from the full change log.
-- Customers whose latest event is a delete are left out.
-- replace: model, key and column names

with changes as (
    select * from {{ ref('stg_cdc__customer_changes') }}
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
        _source_ts as last_changed_at
    from ranked
    -- Rank first, then drop deletes. The other way round brings deleted customers back.
    where
        change_rank = 1
        and _op <> 'd'
)

select * from latest
