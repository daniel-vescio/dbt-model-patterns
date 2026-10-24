# Append-only

Add new rows each run. Old rows are never changed.

## Problem

Event and log tables grow every day. Rebuilding them in full gets slower every run, even though old rows never change.

## Use when

Rows never change once written: events, logs, readings, ledger entries.

## Don't use when

- Rows get updated after they're loaded. Use [merge on key](../merge-on-key/).
- You're aggregating by date and late rows change past totals. Use [late-arriving data](../late-arriving-data/).

## Decisions

- **Filter on `_loaded_at`, not the event time.** An event from yesterday that was loaded today is still new. Filtering on event time skips it without any error.
- **No `unique_key`.** Without one, dbt appends.

## Gotchas

- **Duplicate delivery.** Some loaders send the same event twice. The `unique` test on `event_id` will catch it. Adding `unique_key='event_id'` only partly fixes it: copies of rows already in the table get replaced, but two copies in the same batch both get inserted, and the first build doesn't dedupe at all. If duplicates are common, dedupe in the model and use [merge on key](../merge-on-key/).
- **`>` vs `>=`.** `>` can miss rows sharing the latest `_loaded_at` if a load was still in progress when dbt ran. The simplest fix is to run dbt after loads finish.
- Rows already loaded keep the old logic until you `--full-refresh`.

## Files

- `fct_app_events.sql`: the model
- `_fct_app_events.yml`: tests
