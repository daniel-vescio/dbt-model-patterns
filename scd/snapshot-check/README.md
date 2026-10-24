# Snapshot: check strategy

Keep the full history of a table (SCD type 2) by comparing chosen columns each run and saving a new version when any of them change.

## Problem

Plenty of sources have no `updated_at`, or one that some updates skip (bulk fixes, back-office scripts). The [timestamp strategy](../snapshot-timestamp/) misses those. The check strategy compares the actual values instead.

## Use when

You need history, and there's no reliable `updated_at`.

## Don't use when

- There is a reliable `updated_at`. The timestamp strategy is cheaper and records when the change actually happened.
- You have a CDC feed. Use [CDC: SCD2](../../cdc/scd2-from-cdc/).

## Decisions

- **List the columns you care about** in `check_cols`. `all` creates a new version for every little change, including noisy columns like `last_login_at`.
- **Validity times are run times.** `dbt_valid_from` is when the snapshot noticed the change, not when it happened.
- **`hard_deletes`:** same options as the [timestamp strategy](../snapshot-timestamp/).

## Gotchas

- Changes between runs collapse. A price that goes 10 → 12 → 10 between runs records nothing.
- A column the snapshot only started capturing later is null in older versions. Adding it to `check_cols` then creates a new version for nearly every row on the next run.
- You can't get history back, so back up before renaming or moving the table.
- `unique_key` must really be unique in the source. Duplicates corrupt the history for good, so put a `unique` test on the source column.

## Files

- `_snap_erp__products.yml`: the snapshot
