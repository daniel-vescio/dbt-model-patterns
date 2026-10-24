# CDC: SCD2

Build full history straight from the change stream. Every change becomes a version with a valid-from and valid-to.

## Problem

Snapshots only see the state when they run, so two changes between runs collapse into one. A CDC stream already has every change and exactly when it happened. Turn those events into versions and you get complete history that you can rebuild from the log whenever you need to.

## Use when

You have a CDC stream and need history ("what tier was this customer on 3 March?").

## Don't use when

- There's no CDC. Use a [snapshot](../../scd/snapshot-timestamp/).
- You only need current state. Use [latest state](../latest-state/).

## Decisions

- **Rebuild the customers that changed, not individual rows.** Each run finds customers with new events, rebuilds their whole history from the log, and swaps it in with `delete+insert` on `customer_id`. Late and out-of-order events end up in the right place without patching existing versions.
- **Dates from the commit time, order from the log position.** `valid_from` is `_source_ts`, versions are ordered by `_source_lsn`, and `valid_to` is the next version's `valid_from`.
- **Deletes become a version** with `is_deleted = true`. Current state is `where is_current and not is_deleted`.
- **Join facts with `>= valid_from and < valid_to`** so each timestamp matches exactly one version.

## Gotchas

- **Keep the raw change log.** Rebuilding a customer reads all their events, so pruning the log truncates their history.
- Updates to columns you don't model still create a version with the same values. Collapse them with `lag()` if that bothers you.
- Two changes in the same millisecond give a zero-length version. It's correct, just a bit surprising.

## Files

- `dim_customers_history.sql`: the model
- `_dim_customers_history.yml`: tests
