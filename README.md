# dbt model patterns

Patterns for building dbt models, with notes on when to use each one and common mistakes to avoid.

They're a guide, not a framework. Copy what's useful and adapt it to your project. Templates use Postgres SQL and current dbt Core (1.10+), but the approach applies to any warehouse.

## Pick a pattern

| Situation | Pattern |
|---|---|
| Bringing a new source table into dbt | [Staging](staging/) |
| Choosing between view, table and incremental | [Choosing a materialisation](materialisations/) |
| Rows never change after they're loaded (events, logs) | [Append-only](incremental/append-only/) |
| Rows get updated in place | [Merge on key](incremental/merge-on-key/) |
| Daily totals that late rows can change | [Late-arriving data](incremental/late-arriving-data/) |
| Big time-series tables, backfills by date | [Microbatch](incremental/microbatch/) |
| History, and the source has a reliable `updated_at` | [Snapshot: timestamp](scd/snapshot-timestamp/) |
| History, without a reliable `updated_at` | [Snapshot: check](scd/snapshot-check/) |
| Current state from a CDC stream | [CDC: latest state](cdc/latest-state/) |
| Deletes coming through CDC | [CDC: deletes](cdc/deletes/) |
| Incremental CDC with late or out-of-order events | [CDC: out-of-order events](cdc/out-of-order-events/) |
| Full history from a CDC stream | [CDC: SCD2](cdc/scd2-from-cdc/) |
| More than one row per key | [Deduplication](deduplication/) |

Before using any incremental pattern, check whether a plain `table` is fast enough. It often is, even for large tables.

## How each pattern is laid out

Each folder has a short README covering the problem, when to use it (and when not to), the decisions you'll need to make, and the gotchas. The `.sql` and `.yml` files next to it are the templates.

[`incremental/`](incremental/), [`scd/`](scd/) and [`cdc/`](cdc/) also have an overview README with the rules that apply to every pattern in them.

## Conventions

- The examples use an online shop: orders, payments, customers and app events. Lines to change are marked `replace`.
- Naming: `stg_` for staging, `int_` for intermediate steps, `fct_` for facts, `dim_` for dimensions.
- Sources have a `_loaded_at` column (when the row was loaded into the warehouse). A few patterns rely on it.
- This isn't a runnable project. Templates reference models like `stg_shop__orders` that you'd have in your own project.

## Not covered yet

Fact table types, dimensions and surrogate keys, combining data from multiple source systems, a date spine, project structure and config, and a testing strategy.

## License

MIT. See [LICENSE](LICENSE).
