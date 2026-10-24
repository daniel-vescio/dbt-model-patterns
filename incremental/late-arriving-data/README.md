# Late-arriving data

Recompute the last few days on every run, so rows that turn up late still land in the right day.

## Problem

Totals by date go wrong when rows arrive after their day has already been processed. An order placed Monday that lands Wednesday never makes Monday's total if you only ever process new days.

## Use when

You're aggregating by a business date and rows can land or change a few days after that date.

## Don't use when

- The model is row level, not aggregated. [Merge on key](../merge-on-key/) filtering on `_loaded_at` already catches late rows.
- The table is big and time-partitioned. [Microbatch](../microbatch/) does this with built-in batching and backfills.

## Decisions

- **Window size:** cover how late your data normally is, with some margin. It's a variable, so you can widen it for one run: `dbt run -s fct_daily_revenue --vars '{revenue_lookback_days: 30}'`.
- **Count back from the table, not from today.** `max(order_date) - N` also covers you if dbt hasn't run for a few days. `current_date - N` would leave a gap.
- **`delete+insert` on the date.** Each run swaps out the recomputed days, so reruns give the same answer.
- **Filter inside the measures, not in `where`.** That way a day where every order was cancelled still shows up (as zero) instead of keeping its old total.

## Gotchas

- Anything later than the window gets missed. Run a `--full-refresh` every so often (weekly is usually fine) to tidy up.
- If every row for a day is deleted upstream, that day keeps its old total until the next full refresh.
- `created_at::date` on a `timestamptz` uses the session's time zone, so days can shift depending on who runs it. Convert explicitly, e.g. `(created_at at time zone 'Australia/Melbourne')::date`.

## Files

- `fct_daily_revenue.sql`: the model
- `_fct_daily_revenue.yml`: tests
