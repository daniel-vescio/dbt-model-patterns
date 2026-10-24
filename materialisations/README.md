# Choosing a materialisation

How dbt saves a model: view, table, incremental, ephemeral or materialized view.

## Problem

Get it wrong and you either rebuild a huge table every run for no reason, or add incremental logic to a table with 10,000 rows. Pick the simplest one that works and only change it when you have a reason to.

## Quick guide

| Type | What it does | Good for | Watch out for |
|---|---|---|---|
| `view` | Runs the query every time it's read | Staging, light transforms, things rarely queried | Slow when stacked or hit by dashboards |
| `table` | Rebuilds the whole table each run | Marts, anything queried often | Rebuild time as it grows |
| `incremental` | Only processes new or changed rows | Big tables where rebuilds are slow | Extra logic that can drift |
| `ephemeral` | Inlined as a CTE, never created | Small steps used by one or two models | Can't query or test it directly |
| `materialized_view` | Stored results the database refreshes | Postgres: stored results without incremental logic | Refreshed in full each `dbt run` |

## Rules of thumb

1. Start with views for staging and tables for marts.
2. Go incremental only when a full rebuild is actually too slow or expensive, not because it might be one day.
3. Don't point dashboards at a chain of views. Make the last step a table.
4. When in doubt, use a real model over ephemeral. It's easier to debug.

## Decisions

- **Set defaults per folder** in `dbt_project.yml` (see the snippet here), so most models need no config.
- **`full_refresh: false`** on big incremental tables stops an accidental `--full-refresh` from rebuilding them.

## Gotchas

- Switching a model between view and table drops and recreates it. Anything outside dbt that depends on it may break.
- Incremental models keep old logic for rows already loaded until you run `--full-refresh`.

## Files

- `dbt_project.yml`: folder-level defaults
