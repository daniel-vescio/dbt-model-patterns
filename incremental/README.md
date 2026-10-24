# Incremental models

Patterns for tables that are too slow to rebuild every run. Each run processes only new or changed rows and merges them into the existing table.

## Which one

| Your data | Pattern |
|---|---|
| Rows never change after they're loaded | [Append-only](append-only/) |
| Rows get updated in place | [Merge on key](merge-on-key/) |
| Daily totals that late rows can change | [Late-arriving data](late-arriving-data/) |
| Big time-series tables, backfills by date | [Microbatch](microbatch/) |

Check whether a plain `table` is fast enough first. It often is, even for large tables, and it can't get out of sync.

## Things that apply to all of them

- **Choose the watermark deliberately.** Row-level patterns filter on `_loaded_at`, which picks up every row loaded since the last run, whatever its event date. Late-arriving data recomputes a window of business dates, and microbatch batches on `event_time` with a `lookback`. Both miss anything later than their window.
- **`coalesce` the watermark.** `max()` on an empty table is null, and `_loaded_at > null` is never true. If the first build runs against an empty or filtered source, every later run silently loads nothing. The templates use `coalesce(max(...), '1900-01-01')`.
- **One row per key per batch.** `merge` and `delete+insert` replace rows already in the table, but they don't dedupe within the batch, and the first build doesn't dedupe at all.
- **Set `on_schema_change`.** The default, `ignore`, silently leaves out columns you add to the model. See [materialisations](../materialisations/).
- **Rows already loaded keep the old logic** until a `--full-refresh`. Schedule one regularly. If you've set `full_refresh: false`, it blocks that too, so remove it for the run.
