-- Staging for a Debezium change stream, flattened with ExtractNewRecordState using
-- delete.handling.mode=rewrite and add.fields=op,lsn,source.ts_ms.
-- One row per change. The CDC patterns handle ordering and duplicates.
-- replace: source, key and column names (and the metadata fields if you're not on Debezium)

with source as (
    select * from {{ source('cdc', 'customers') }}
),

renamed as (
    select
        -- key
        id as customer_id,

        -- values after the change (last known values for deletes)
        email,
        full_name,
        lower(tier) as customer_tier,

        -- change metadata
        __op as _op,
        __lsn as _source_lsn,
        to_timestamp(__source_ts_ms / 1000.0) as _source_ts,
        _loaded_at
    from source
)

select * from renamed
