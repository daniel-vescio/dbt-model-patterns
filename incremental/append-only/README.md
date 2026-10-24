# Append-only

Add new rows each run. Never touch the old ones.

## Problem

Event and log tables grow every day. Rebuilding them in full gets slower every run, even though old rows never change.

## Use when

Rows never change once written: events, logs, readings, ledger entries.

## Don't use when

- Rows get updated after they land. Use [merge on key](../merge-on-key/).
- You're aggregating by date and late rows change past totals. Use [late-arriving data](../late-arriving-data/).

## Decisions

- **Filter on `_loaded_at`, not the event time.** An event from yesterday that only landed today is still new. Filtering on event time quietly drops it.
- **No `unique_key`.** Without one, dbt just appends.

## Gotchas

- **Duplicate delivery.** Some loaders send the same event twice. The `unique` test on `event_id` will catch it, and adding `unique_key='event_id'` fixes it.
- **`>` vs `>=`.** `>` can miss rows sharing the latest `_loaded_at` if a load was half finished when dbt ran. Easiest fix: run dbt after loads finish.
- Rows already loaded keep the old logic until you `--full-refresh`.

## Files

- `fct_app_events.sql`: the model
- `_fct_app_events.yml`: tests
