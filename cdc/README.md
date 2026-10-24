# CDC (change data capture)

Patterns for building tables from a change stream: one row per insert, update or delete, captured from a database's log by tools like Debezium, Fivetran or AWS DMS.

## Which one

| You need | Pattern |
|---|---|
| Current state, simplest version | [Latest state](latest-state/) |
| To decide how deleted rows should look | [Deletes](deletes/) |
| Current state incrementally, with late or out-of-order events | [Out-of-order events](out-of-order-events/) |
| Full history | [SCD2](scd2-from-cdc/) |

Start with latest state. Move to out-of-order events when rebuilding from the full log gets too slow.

## What the events look like

The patterns read from a staging model (`stg_cdc__customer_changes.sql`) with one row per change:

| Column | What it is |
|---|---|
| `customer_id` | Key of the changed row, on every event (including deletes) |
| `email`, `full_name`, `customer_tier` | Values after the change. On deletes, the last known values |
| `_op` | `c` create, `u` update, `d` delete, `r` initial snapshot |
| `_source_lsn` | Position in the source database's log. Use it to order events |
| `_source_ts` | When the change was committed at the source |
| `_loaded_at` | When the event landed in the warehouse. Use it for incremental filters |

The staging template maps Debezium's fields to these names. Other tools call them something different, but the ideas are the same.

`_stg_cdc__models.yml` tests it. `_op` only accepts `c`, `u`, `d` and `r`: the patterns treat anything that isn't `d` as a live row, so an unexpected value should fail there first.

## Things that apply to all of them

- **Order by log position, not timestamp.** Two changes can share a timestamp. The log position (LSN, binlog position, SCN) gives the real order.
- **Filter incrementally on `_loaded_at`.** It catches every event that arrived since the last run, however old.
- **Pick the latest event first, then check for deletes.** Filtering out deletes first brings deleted rows back with their previous values.
- **Expect duplicates.** Most pipelines deliver at least once.
