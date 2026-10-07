# 13. Heap And Clustering

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/13_heap_and_clustering.sql) · [Worked answers](../solutions/13_heap_and_clustering.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: “clustered index” means different things in different engines

PostgreSQL's ordinary table data resides in a heap, with separate indexes pointing to physical tuples. A primary key creates a uniqueness-enforcing index, but it does not turn the table into an InnoDB-style clustered structure. Confusing these storage models leads to incorrect assumptions about secondary-index lookups and primary-key width.

In InnoDB, the clustered index organizes row data, and secondary index entries carry the primary-key value used to reach that organization. PostgreSQL's ordinary index entries instead identify heap tuples. The course compares these concepts, but the runnable environment is PostgreSQL only. There is no hidden MySQL service or untested claim that PostgreSQL CLUSTER reproduces InnoDB's storage model.

## Logical index order versus physical heap placement

An index maintains its key order independently of heap location. Two neighboring keys can refer to heap pages far apart. The heap is not guaranteed to remain in insertion order either: updates, available free space, vacuum, and rewrites affect placement. The only reliable query-order contract comes from `ORDER BY`.

Physical correlation can nevertheless affect access cost. If a project's rows occupy a compact range of heap pages, a project-range query may need less scattered heap work than when those rows are dispersed. The lab prints planner statistics for correlation and measures the same range query around a controlled reorganization.

## What PostgreSQL CLUSTER does

`CLUSTER table USING index` rewrites a table according to the chosen index order and requires a strong lock. It is a one-time organization operation. Subsequent inserts and updates are not continuously repositioned to preserve a globally sorted heap.

After clustering, refresh statistics before interpreting estimates. The lab also inserts another set of rows in ID order and shows that the clustered-index designation can remain recorded without becoming an invariant about future physical order.

Do not infer that a query can omit ORDER BY after clustering. Even a favorable current layout is not a stable SQL result-order guarantee, and a later plan may use a different path entirely.

## Primary-key width and identifier design

Wider keys consume more index space and can reduce page occupancy. In an engine where secondary indexes contain the primary key, primary-key width can affect many structures. In PostgreSQL, a UUID primary key does not automatically get copied as the lookup pointer into every unrelated secondary index, although explicit multi-column keys and included payload can of course store it.

Choosing UUIDs, ordered identifiers, or integers involves distributed generation, privacy, write distribution, and application semantics as well as storage. This teaching schema uses integers for readable SQL. It is not a recommendation to replace the UUIDv7 IDs in your platform design.

## Experiment and transfer

Compare the project-range plan, correlation, and buffer work before and after CLUSTER. Distinguish the effect of refreshed statistics from the physical rewrite, and remember both operations warm caches. This is not a cold-storage benchmark.

For a growing run-history table, ask whether physical organization remains stable long enough to justify reorganization cost and lock requirements. Partitioning stable historical data may change that operational tradeoff, but partitioning alone does not guarantee clustering or correct indexes.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 13
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/13_heap_and_clustering.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab13`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Does a PostgreSQL primary key make the heap an InnoDB-style clustered table?
2. What remains true after CLUSTER, and what is not continuously maintained?
3. Why should primary-key-width claims be qualified by storage engine?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/13_heap_and_clustering.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/13_heap_and_clustering.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [sql cluster](https://www.postgresql.org/docs/17/sql-cluster.html)
- [storage page layout](https://www.postgresql.org/docs/17/storage-page-layout.html)
- [planner stats](https://www.postgresql.org/docs/17/planner-stats.html)
- [innodb index types](https://dev.mysql.com/doc/refman/8.4/en/innodb-index-types.html)
