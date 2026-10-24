# Deduplication

Get a source down to one row per key, picking the same row every time.

## Problem

Sources send duplicates: loaders retry, files get resent, and some tables keep several versions of a record. Duplicates inflate counts and break joins further down.

## Two kinds

- **Exact copies** (the same file loaded twice): any copy will do.
- **Several versions of one key** (a payment stored as `pending`, then `success`): you need a rule for which one wins, e.g. latest `updated_at`.

The template handles both.

## Use when

A source has more than one row per key, and a test has confirmed it (not just a hunch).

## Don't use when

- The "duplicates" are actually separate real events, like two payments for the same amount. Fix the key instead of dropping data.
- It's a CDC stream. The [CDC patterns](../cdc/) dedupe by log position.

## Decisions

- **Dedupe once, early.** One model right after staging that everything else uses. Deduping in some places and not others gives you different numbers in different reports.
- **Make it deterministic.** Order by your rule, then add tie-breakers (`_loaded_at`, then a unique column if you have one) until one row always wins. Otherwise the result can change between runs.
- **Keep an eye on how many you're dropping.** A `unique` test on the staging model with `severity: warn` shows you duplicates arriving without failing the run.
- On Postgres, `distinct on (payment_id) ... order by payment_id, updated_at desc` does the same thing in one go. `row_number()` works everywhere.

## Gotchas

- On Postgres, nulls sort **first** in `desc`. A row with no `updated_at` would win. The template uses `nulls last`.
- Deduping on the wrong key quietly deletes real data. Check the grain with whoever owns the source.

## Files

- `int_payments__deduplicated.sql`: the model
- `_int_payments__deduplicated.yml`: tests
