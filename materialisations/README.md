# Choosing a materialisation

How dbt saves a model: view, table, incremental, ephemeral or materialized view.

## Problem

The wrong choice means either rebuilding a large table every run when you don't need to, or adding incremental logic to a table with 10,000 rows. Pick the simplest one that works, and only change it when you have a reason to.

## Quick guide

| Type | What it does | Good for | Watch out for |
|---|---|---|---|
| `view` | Runs the query every time it's read | Staging, light transforms, things rarely queried | Slow when views are stacked or queried by dashboards |
| `table` | Rebuilds the whole table each run | Marts, anything queried often | Rebuild time as it grows |
| `incremental` | Only processes new or changed rows | Big tables where rebuilds are slow | Extra logic, and results that can get out of sync |
| `ephemeral` | Inlined as a CTE, never created | Small steps used by one or two models | Can't query or test it directly |
| `materialized_view` | Stored results the database refreshes | Postgres: stored results without incremental logic | Refreshed in full each `dbt run` |

## Guidelines

1. Start with views for staging and tables for marts.
2. Use incremental only when a full rebuild is already too slow or expensive, not because it might be in the future.
3. Don't point dashboards at a chain of views. Make the last step a table.
4. If you're unsure, use a view or table instead of ephemeral. It's easier to debug.

## Decisions

- **Set defaults per folder** in `dbt_project.yml` (see the snippet here), so most models need no config.
- **Set `on_schema_change` for incremental models.** The default, `ignore`, silently leaves out any column you add to the model. `append_new_columns` (in the snippet) adds it, with nulls in rows already loaded until a full refresh. `fail` stops the run so you can decide.
- **`full_refresh: false`** on big incremental tables stops an accidental `--full-refresh` from rebuilding them. It also blocks the deliberate ones some patterns rely on, so remove it for that run.

## Gotchas

- Switching a model between view and table drops and recreates it. Anything outside dbt that depends on it may break.
- Incremental models keep old logic for rows already loaded until you run `--full-refresh`.

## Files

- `dbt_project.yml`: folder-level defaults
