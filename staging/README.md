# Staging

One model per source table. Rename, cast and tidy up. Nothing else.

## Problem

Raw tables come with messy names, odd types and different units. If every downstream model cleans them up itself, you end up with the same logic written five different ways. Staging does it once.

## Use when

Any source table dbt reads gets exactly one staging model.

## Don't use when

- You need joins, aggregations or business rules. Those go further downstream.
- Nothing uses the table yet. Stage it when something does.

## Decisions

- **Naming:** `stg_<source>__<table>`, e.g. `stg_shop__payments`.
- **What belongs here:** renames, casts, unit conversions (cents to dollars), fixing case, simple flags. Nothing that changes the row count.
- **Column names:** `_id` for keys, `_at` for timestamps, `_on` for dates, `is_`/`has_` for booleans.
- **Views.** Cheap and always up to date.
- **Only staging uses `source()`.** Everything else uses `ref()`.

## Gotchas

- List columns explicitly in the final select, so new upstream columns don't sneak through.
- Don't quietly filter rows here. If you must, comment why.
- Set freshness on the source so a stale load fails loudly instead of showing old numbers.

## Files

- `_shop__sources.yml`: source with a freshness check
- `stg_shop__payments.sql`: the staging model
- `_stg_shop__models.yml`: tests
