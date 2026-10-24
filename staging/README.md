# Staging

One model per source table. Rename, cast and clean up. Nothing else.

## Problem

Raw tables come with inconsistent names, wrong types and mixed units. If every downstream model cleans them up itself, the same logic gets written several different ways. Staging does it once.

## Use when

Any source table dbt reads gets exactly one staging model.

## Don't use when

- You need joins, aggregations or business rules. Those go further downstream.
- Nothing uses the table yet. Add a staging model when something does.

## Decisions

- **Naming:** `stg_<source>__<table>`, e.g. `stg_shop__payments`.
- **What belongs here:** renames, casts, unit conversions (cents to dollars), fixing case, simple flags. Nothing that changes the row count.
- **Column names:** `_id` for keys, `_at` for timestamps, `_on` for dates, `is_`/`has_` for booleans.
- **Nested data:** keep the raw field and extract the values you need. If it holds repeated records (like line items), unnest them into their own staging model, e.g. `stg_shop__order_items`. It's the one place staging changes the row count, so give it its own key and tests.
- **Views.** Cheap and always up to date.
- **Only staging uses `source()`.** Everything else uses `ref()`.

## Gotchas

- List columns explicitly in the final select, so new upstream columns aren't passed through automatically.
- Don't filter rows here without a comment explaining why.
- Set freshness on the source, so a stale load raises an error instead of reports showing old numbers.
- Be explicit about time zones. Casting a timestamp without a time zone to `timestamptz` reads it in the session's time zone, so the same row can come out differently depending on who runs it.
- Dividing by 100 assumes every currency has two decimal places. JPY has none and KWD has three, so with mixed currencies divide by each currency's minor unit.

## Files

- `_shop__sources.yml`: source with a freshness check
- `stg_shop__payments.sql`: the staging model
- `_stg_shop__models.yml`: tests
