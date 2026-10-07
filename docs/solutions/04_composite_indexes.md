# 04. Composite Indexes: worked answers

[Return to lesson](../lessons/04_composite_indexes.md)


## Worked answers

Changing the equality value selects a different single status region with the same time ordering. Removing it exposes multiple status regions, so their physical index order is no longer the requested all-status time order.

The status-only count leaves the leading `project_id` key unconstrained. Because the fixture has only 100 project values, PostgreSQL 18 can use a B-tree skip scan and search the matching status range once per project value. The tested PG18.6 plan used a bitmap index scan with 101 index searches; inspect your own `Index Searches` count and buffers because the planner can choose another path on different data or hardware.

A later predicate can reject index entries before fetching heap tuples. That can be valuable even if many entries still need examination. Distinguish index work from heap work rather than treating any indexed condition as free.

Backward scanning reverses the key order together. It does not independently reverse whichever columns the query chooses. Check mixed directions, collation, and null ordering against the actual index definition.

## Index portfolio answer

A project/time index supports the all-status feed. A partial project/time index restricted to failures can support the failure feed more compactly than a full status-aware index, but cannot answer a succeeded-only feed by itself. Retaining two structures is justified only by the measured workload and write budget.

**DoneContract:** draw the lexicographic order for a small set of tuples, identify the contiguous scan region and usable result order for changed queries, and explain when the PG18 status-only plan uses repeated searches.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 4
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [indexes multicolumn](https://www.postgresql.org/docs/18/indexes-multicolumn.html)
- [indexes ordering](https://www.postgresql.org/docs/18/indexes-ordering.html)
- [indexes partial](https://www.postgresql.org/docs/18/indexes-partial.html)
- [sql createindex](https://www.postgresql.org/docs/18/sql-createindex.html)
