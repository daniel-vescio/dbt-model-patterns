# CDC: out-of-order events

Keep current state up to date incrementally, without late or duplicate events overwriting newer data.

## Problem

An incremental CDC model only processes events that landed since the last run. Two things trip up a naive version:

1. **Several changes to one key in the same batch.** Without picking one, `merge` errors or inserts duplicates.
2. **An older change lands after a newer one was applied.** Retries and parallel loaders make this more common than you'd think. A naive merge applies whatever arrives last, so the row quietly goes back to an older version.

## Use when

You need current state from a CDC stream, rebuilding from the full log ([latest state](../latest-state/)) is too slow, and events can arrive late or twice. Assume they can unless you know otherwise.

## Don't use when

- The full rebuild is fast enough. [Latest state](../latest-state/) is simpler and can't drift.
- You need history. Use [SCD2](../scd2-from-cdc/).

## Decisions

- **Two guards, in this order:**
  1. Keep only the newest event per key within the batch.
  2. Only apply it if it's newer than what's already in the table (`_source_lsn > loaded._source_lsn`).
- **Store `_source_lsn` on every row**, since guard 2 compares against it.
- **Deletes go through the same guards**, so a late update can't bring a deleted customer back.
- **The unit tests in `_dim_customers.yml` cover both guards.** With `is_incremental` overridden, the expected rows are what the model returns for the batch, not the final table.

## Gotchas

- If `_source_lsn` ever resets (database restore, failover, connector rebuilt), new events look older and get skipped. Run a `--full-refresh` after anything like that.
- Incremental models can drift over time. Compare against [latest state](../latest-state/) now and then, or schedule a periodic full refresh.

## Files

- `dim_customers.sql`: the model
- `_dim_customers.yml`: tests and unit tests
