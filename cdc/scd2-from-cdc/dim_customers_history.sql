{{
    config(
        materialized='incremental',
        unique_key='customer_id',
        incremental_strategy='delete+insert'
    )
}}

-- One row per version of each customer, built from change events.
-- Each run rebuilds the full history of customers with new events, and delete+insert on
-- customer_id swaps it in, so late and out-of-order events land in the right place.
-- unique_key here is the key delete+insert replaces on, not a unique column: each customer
-- has many rows. (It wouldn't work with merge.)
-- replace: model, key and column names

with changes as (
    select * from {{ ref('stg_cdc__customer_changes') }}
),

-- Customers with events since the last run (everyone on a full refresh)
changed_customers as (
    select distinct changes.customer_id
    from changes
    {% if is_incremental() %}
        -- coalesce: on an empty table max() is null, and nothing would ever load
        where changes._loaded_at > (
            select coalesce(max(hist._loaded_at), '1900-01-01') from {{ this }} as hist
        )
    {% endif %}
),

-- All events for those customers, old and new, so their whole history gets rebuilt
in_scope as (
    select changes.*
    from changes
    inner join changed_customers
        on changes.customer_id = changed_customers.customer_id
),

-- Drop duplicate deliveries. Keeping the latest copy moves the _loaded_at watermark on.
deduplicated as (
    select
        *,
        row_number() over (
            partition by customer_id, _source_lsn
            order by _loaded_at desc
        ) as copy_number
    from in_scope
),

versions as (
    select
        customer_id,
        email,
        full_name,
        customer_tier,
        _op = 'd' as is_deleted,
        _source_ts as valid_from,
        lead(_source_ts) over (
            partition by customer_id
            order by _source_lsn
        ) as next_valid_from,
        _source_lsn,
        _loaded_at
    from deduplicated
    where copy_number = 1
),

final as (
    select
        md5(customer_id::text || '-' || _source_lsn::text) as customer_version_id,
        customer_id,
        email,
        full_name,
        customer_tier,
        is_deleted,
        valid_from,
        coalesce(next_valid_from, '9999-12-31'::timestamptz) as valid_to,
        next_valid_from is null as is_current,
        _source_lsn,
        _loaded_at
    from versions
)

select * from final
