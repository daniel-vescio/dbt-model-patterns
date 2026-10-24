# SCD (slowly changing dimensions)

Patterns for keeping history (SCD type 2): every version of a record, with the period it was valid for, so you can answer "what tier was this customer on 3 March?".

## Which one

| You have | Pattern |
|---|---|
| An `updated_at` that changes on every update | [Snapshot: timestamp](snapshot-timestamp/) |
| No reliable `updated_at` | [Snapshot: check](snapshot-check/) |
| A CDC stream | [CDC: SCD2](../cdc/scd2-from-cdc/) |

If you have CDC, use it. Snapshots only see what's there when they run, so changes between runs collapse into one.

## Things that apply to all of them

- **Snapshots can't be rebuilt.** History that wasn't captured is gone, and dropping or moving the table loses what was. Back it up before changing anything structural.
- **`unique_key` must really be unique in the source.** Duplicate keys corrupt the history for good. Put a `unique` test on the source column.
- **Read history through a model** with friendly names and a `valid_to` that's never null, rather than pointing people at the snapshot table.
- **Join facts with `>= valid_from and < valid_to`** so each timestamp matches exactly one version.
- **History starts when capture started.** The first version's `valid_from` is the first snapshot run (or the first CDC event), so facts older than that match no version. If the first version should cover everything before it, set its `valid_from` to `'1900-01-01'` in the history model.
