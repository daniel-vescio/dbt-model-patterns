-- One row per customer version, with friendlier names than the raw snapshot.
-- Join facts on: occurred_at >= valid_from and occurred_at < valid_to
-- Current rows can have a null dbt_valid_to or the dbt_valid_to_current date (setting that
-- config on an existing snapshot doesn't backfill rows that are already current). This handles both.
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
        coalesce(dbt_valid_to, '9999-12-31'::timestamp) as valid_to,
        dbt_valid_to is null or dbt_valid_to = '9999-12-31'::timestamp as is_current
    from versions
)

select * from final
