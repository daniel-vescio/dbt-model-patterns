# Snapshot: timestamp strategy

Keep the full history of a table (SCD type 2) by saving a new version whenever its `updated_at` changes.

## Problem

Source systems overwrite rows. Once a customer moves from `standard` to `premium`, the old tier is gone, and you can't answer "what tier were they in March?". A snapshot keeps every version with the period it was valid for.

## Use when

You need history, and the source has an `updated_at` that changes on **every** update.

## Don't use when

- There's no reliable `updated_at`. Use the [check strategy](../snapshot-check/).
- You have a CDC feed. [CDC: SCD2](../../cdc/scd2-from-cdc/) catches every change, not just what's there when the snapshot runs.
- You only need current state.

## Decisions

- **Snapshot the source, not a staging model.** You can't rebuild history later, so capture the raw data and transform it downstream.
- **`hard_deletes`:** what happens when a row disappears from the source. `ignore` (default) keeps it current forever. `invalidate` closes the current version. `new_record` adds a version flagged as deleted. `invalidate` is a good default.
- **`dbt_valid_to_current`:** puts a far-future date on current rows instead of null, which makes date-range joins simpler. Optional. Adding it to an existing snapshot doesn't backfill: rows that are already current keep null. `dim_customers_history.sql` handles both.
- **Read it through a model** like `dim_customers_history.sql` with friendlier names, rather than pointing people at the snapshot table.

## Gotchas

- Snapshots only see what's there when they run. Two updates between runs show up as one.
- Lost history can't be recovered. Back up the table before renaming it or moving it to another schema.
- If the source ever backdates `updated_at`, changes get missed.
- `unique_key` must be unique in the source. Duplicates corrupt the history permanently, so put a `unique` test on the source column.

## Files

- `_snap_shop__customers.yml`: the snapshot (dbt 1.9+ YAML format)
- `dim_customers_history.sql`: friendlier history model on top
