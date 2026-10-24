# CDC: latest state

Rebuild the current state of each row from the full change log, every run.

## Problem

A change stream tells you what happened, not what exists now. To get "what does this customer look like today", you need the latest event per key, minus anything whose latest event was a delete.

## Use when

- You need current state from a CDC stream.
- Scanning the whole change log each run is quick enough.

It's the simplest version that's always right: every run starts fresh, so late or out-of-order events can't build up into problems.

## Don't use when

- Scanning the whole log takes too long. Use [out-of-order events](../out-of-order-events/), the incremental version.
- You need history. Use [SCD2](../scd2-from-cdc/).

## Decisions

- **Order by `_source_lsn`.**
- **Rank first, then drop deletes.** Doing it the other way round brings deleted customers back.
- **Deleted rows just disappear.** If downstream needs to know about deletes, see [deletes](../deletes/).
- **Table, not view.** A view would rescan the log on every query.

## Gotchas

- A key that's deleted and later re-created comes back, because only the latest event counts. That's usually what you want.
- If your tool re-snapshots a table, check the snapshot (`r`) rows get log positions that sort correctly against live changes.

## Files

- `dim_customers.sql`: the model
- `_dim_customers.yml`: tests
