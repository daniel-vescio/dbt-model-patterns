# Merge on key

Insert new rows and update existing ones, matched on a key.

## Problem

Records change after they're created. An order goes from `placed` to `shipped` to `refunded`. Appending would give you duplicates, and rebuilding everything every run gets slow as the table grows.

## Use when

Rows are updated in place, you only need the latest version, and the table is big enough that a full rebuild hurts.

## Don't use when

- Rows never change. [Append-only](../append-only/) is simpler.
- You need the history of changes. Use a [snapshot](../../scd/snapshot-timestamp/), or [CDC: SCD2](../../cdc/scd2-from-cdc/) if you have a change stream.
- The table is small. A plain `table` is simpler and always right.

## Decisions

- **Key:** the column (or list of columns) that identifies a row, e.g. `unique_key='order_id'`.
- **Strategy:** `merge` updates matching rows and inserts the rest. It needs Postgres 15+. On older versions use `delete+insert`, which deletes matching keys and inserts the batch. If you set a `unique_key` without a strategy, Postgres gives you `delete+insert`.
- **Filter on `_loaded_at`.** It picks up everything that landed since the last run. Filtering on the source's `updated_at` assumes changes always arrive in order, and they often don't.

## Gotchas

- **One row per key per batch.** If a batch has two versions of the same order, `merge` either errors ("cannot affect row a second time") or inserts both. Deduplicate first (see [deduplication](../../deduplication/)).
- **Null keys never match**, so those rows get inserted as new. Test the key with `not_null`.
- **Rows deleted at the source stay here.** Merge only sees rows that arrive. If deletes matter, use a CDC feed or rebuild periodically.

## Files

- `fct_orders.sql`: the model
- `_fct_orders.yml`: tests
