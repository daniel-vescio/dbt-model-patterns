# CDC: deletes

Decide how rows deleted at the source should look downstream.

## Problem

A delete arrives as a `d` event, and you have to choose what to do with it. Remove the row and old reports break (facts pointing at customers that no longer exist). Ignore it and deleted records look live.

## Options

| Approach | What happens to the row | When |
|---|---|---|
| **Soft delete** (template) | Kept, with `is_deleted` and `deleted_at` | The default. Facts still join, and you can report on deletions |
| **Hard delete** | Removed | Privacy or legal reasons, e.g. a right-to-erasure request |
| **Ignore** | Kept, looks live | Rarely. Only if the source deletes rows for housekeeping |

## Use when

Your CDC source sends deletes and you're building current state incrementally.

## Don't use when

You're rebuilding from the full log each run and just want deleted rows gone. [Latest state](../latest-state/) already does that.

## Decisions

- **Keep soft deletes, filter for consumers.** Store `is_deleted` here and filter with `where not is_deleted` in the marts. One table answers both "current customers" and "who was deleted when".
- **Hard deletes need a post-hook.** dbt's `merge` only inserts and updates, so add `post_hook="delete from {{ this }} where is_deleted"` (see the comment in the template).
- **Last known values.** Debezium's `rewrite` mode keeps the row's last values on delete events. If your tool only sends the key, the other columns will be null on deleted rows.

## Gotchas

- A re-created key (`c` after `d`) sets `is_deleted` back to false. The newest event wins.
- A hard delete here doesn't remove the data from the raw change log. For erasure requests, purge that too.
- This template only picks the newest event within each batch. If older events can arrive after newer ones, use [out-of-order events](../out-of-order-events/).

## Files

- `dim_customers.sql`: the model
