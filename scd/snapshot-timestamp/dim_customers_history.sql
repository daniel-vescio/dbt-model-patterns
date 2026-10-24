-- One row per customer version, with friendlier names than the raw snapshot.
-- Join facts on: occurred_at >= valid_from and occurred_at < valid_to
-- Assumes dbt_valid_to_current is set. Without it, use `dbt_valid_to is null` for is_current.
-- replace: snapshot and column names

with versions as (
    select * from {{ ref('snap_shop__customers') }}
),

final as (
    select
        dbt_scd_id as customer_version_id,
        customer_id,
        email,
        customer_tier,
        dbt_valid_from as valid_from,
        dbt_valid_to as valid_to,
        dbt_valid_to = '9999-12-31'::timestamp as is_current
    from versions
)

select * from final
