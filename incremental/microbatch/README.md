# Microbatch

Let dbt split an incremental model into time batches (hour, day, month or year) that are processed and retried on their own. Needs dbt 1.9+.

## Problem

Hand-written incremental filters get fiddly on big time-series tables: lookback windows, backfilling a date range, retrying one failed day. Microbatch moves all of that into config.

## Use when

- Big tables where every row has a reliable event timestamp.
- You want easy backfills ("rerun 1 to 7 March") and late-data handling without writing the filter yourself.

## Don't use when

- The table is small. A `table` or [append-only](../append-only/) model is simpler.
- There's no trustworthy event timestamp. Use [merge on key](../merge-on-key/) with `_loaded_at`.
- A row depends on data outside its own batch (e.g. running totals). Each batch runs on its own.

## Decisions

- **`event_time`:** the column that decides which batch a row is in. Set it on this model **and** on the upstream models, so dbt can filter them too.
- **`batch_size`:** daily suits most cases.
- **`lookback`:** how many previous batches to redo each run, for late data. Defaults to 1.
- **`begin`:** where the first build starts from.
- **Postgres needs a `unique_key`.** dbt-postgres uses `merge` under the hood, so you also need Postgres 15+.

## Running it

```bash
dbt run -s fct_page_views                          # latest batches plus lookback
dbt run -s fct_page_views --event-time-start "2025-03-01" --event-time-end "2025-03-08"
dbt retry                                          # rerun only the failed batches
```

## Gotchas

- If an upstream model has no `event_time`, every batch reads the whole thing. Still correct, just slow.
- Don't add your own `is_incremental()` filter. dbt already filters each batch.
- Batches are in UTC, so a batch "day" won't line up with a Melbourne day.

## Files

- `fct_page_views.sql`: the model
- `_fct_page_views.yml`: tests, plus `event_time` on the upstream model
