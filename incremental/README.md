# Incremental models

Patterns for tables that are too slow to rebuild every run. Each run processes only what's new or changed and merges it into the table that's already there.

## Which one

| Your data | Pattern |
|---|---|
| Rows never change after they land | [Append-only](append-only/) |
| Rows get updated in place | [Merge on key](merge-on-key/) |
| Daily totals that late rows need to fix | [Late-arriving data](late-arriving-data/) |
| Big time-series tables, backfills by date | [Microbatch](microbatch/) |

Check a plain `table` first. It's fast enough for longer than you'd think, and it can't drift.

## Things that apply to all of them

- **Pick the watermark on purpose.** Row-level patterns filter on `_loaded_at`, which catches every row that landed since the last run, however old. Late-arriving data recomputes a window of business dates, and microbatch batches on `event_time` with a `lookback`. Both miss anything later than their window.
- **`coalesce` the watermark.** `max()` on an empty table is null, and `_loaded_at > null` is never true. If the first build runs against an empty or filtered source, every later run silently loads nothing. The templates use `coalesce(max(...), '1900-01-01')`.
- **One row per key per batch.** `merge` and `delete+insert` replace rows already in the table, but they don't dedupe within the batch, and the first build doesn't dedupe at all.
- **Set `on_schema_change`.** The default, `ignore`, quietly leaves out columns you add to the model. See [materialisations](../materialisations/).
- **Rows already loaded keep the old logic** until a `--full-refresh`. Plan for one every so often. If you've set `full_refresh: false`, that blocks it too, so take it off for the run.
