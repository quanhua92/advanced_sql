# 02. Index Economics

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/02_index_economics.sql) · [Worked answers](../solutions/02_index_economics.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: who pays for an index?

An index is stored derived information. It can save future reads, enforce a constraint, or provide order. Keeping it current consumes storage, CPU, writes, WAL, cache capacity, and maintenance work. The relevant decision is not whether one SELECT improves; it is whether the workload benefits enough to justify those obligations.

Imagine a runner emits one state transition and many log events, while the dashboard is refreshed occasionally. A wide index on every payload field would optimize hypothetical reads while taxing every write. Conversely, a small index needed for an important uniqueness constraint can be valuable even when query statistics show few scans.

## Separate three kinds of value

An access index changes how rows can be found. An ordering index can avoid processing and sorting a large candidate set for a small feed. A unique index enforces a database invariant. One physical index can serve several roles, but removing it based on one role alone is unsafe. A primary-key index is not just a performance decoration.

A rough decision worksheet is:

```text
Read value:     query frequency × work avoided × latency importance
Write cost:     mutation frequency × maintenance added
Other costs:    retained bytes, cache displacement, vacuum/reindex effort
Correctness:    constraints the index enforces
```

This is not a reliable scalar formula without measurements. It is a reminder to include terms that a single before/after SELECT hides.

## The controlled comparison

The lab creates two empty tables with identical columns, then gives one table three secondary indexes. Both receive the same 10,000 input rows. `EXPLAIN (ANALYZE, BUFFERS, WAL)` executes each insert and exposes its measured behavior. The tables intentionally lack a primary key so the difference under study is the three secondary indexes, not an accidentally different constraint design.

Compare index storage and WAL output, then ask whether the status index helps the rare-failure aggregation. The experiment is not a fair storage-device benchmark: the first and second execution have different cache histories, and background work can intervene. Repeat with fresh tables and swap order before treating timing as a causal estimate.

## Why one universal write multiplier fails

An insert must establish the new heap tuple and required index entries. An update creates a new row version, but eligible HOT updates can avoid fresh entries in ordinary indexes. A delete does not immediately compact every index into its final future form; cleanup is part of the lifecycle. Page splits and full-page WAL images introduce additional variation. Therefore, “three indexes means exactly four writes” is not an engine model.

Index width matters. A large `INCLUDE` payload is copied into the index even though it is not a navigation key. It can help a read path while increasing storage and preventing HOT when that included value changes. You will isolate that effect in lessons 12 and 16.

## Make an index inventory

For each index in a platform table, record its definition, size, supported queries, enforced constraints, affected updates, and replacement candidates. Do not remove an apparently unused index after observing only a short quiet window. An incident query or periodic report can be important despite low frequency. Statistics also have collection and reset boundaries.

The useful output of this lesson is a retained-index decision with evidence and a known observation window, not a promise to index every `WHERE` column.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 2
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/02_index_economics.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab02`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why is “not scanned recently” insufficient evidence for dropping a unique index?
2. Which parts of the two insert measurements are controlled, and which are not?
3. Why can adding duration_ms with INCLUDE change update costs even when it never appears in WHERE?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/02_index_economics.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/02_index_economics.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [sql createindex](https://www.postgresql.org/docs/17/sql-createindex.html)
- [storage hot](https://www.postgresql.org/docs/17/storage-hot.html)
- [routine vacuuming](https://www.postgresql.org/docs/17/routine-vacuuming.html)
- [monitoring stats](https://www.postgresql.org/docs/17/monitoring-stats.html)
