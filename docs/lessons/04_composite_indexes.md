# 04. Composite Indexes

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 18, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/04_composite_indexes.sql) · [Worked answers](../solutions/04_composite_indexes.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: an index is one ordering, not several independent indexes

A B-tree on `(project_id, status, created_at, id)` orders tuples lexicographically. It first compares project. Only within equal projects does status decide order, followed by time and ID. Visualize a project directory whose status sections each contain a time-ordered run list.

For a query with equality on project and status, the remaining time order is immediately useful. Remove the status equality and you expose several independently ordered lists. Reading one after another is not the same as merging them by time.

## Leading equalities and the first range

For PostgreSQL 18 B-trees, equality constraints on leading columns and a range on the first non-equality column bound the ordinary contiguous scan region. Constraints farther right can be checked in the index and save heap visits without necessarily shrinking that region. PostgreSQL 18 can sometimes narrow work further with skip scans: when skipped leading keys have few distinct values, it may perform repeated searches using a later-column condition. Check the actual `Index Searches` count; the planner can still prefer another path.

Consider `(project_id, created_at, status)`. With a project equality and a time range, the index walks the time interval. A rare status farther right may eliminate most entries before heap access, but the index entries across that interval still matter. Swapping status before time can be better for status-specific feeds, but different for all-status chronological feeds.

Do not turn the leftmost-column rule into “the index can never be used otherwise.” PostgreSQL may scan an index for another reason, including covering or cost, and PG18 may use skip scans. Neither changes the index's lexicographic order or guarantees a plan choice. The executable baseline targets PG18; [the version note](../07_postgresql17_vs18.md) compares this behavior with PG17.

## Why “most selective first” is not enough

Suppose both project and status are constrained by equality. Either ordering can identify their combination. The better leading column depends on the other queries that must share the index, ordering requirements, and the data. Counting distinct values in isolation ignores these requirements.

An application often needs both of these feeds:

```sql
-- Failure-focused feed:
WHERE project_id = 42 AND status = 'failed'
ORDER BY created_at DESC, id DESC LIMIT 20

-- All-status feed:
WHERE project_id = 42
ORDER BY created_at DESC, id DESC LIMIT 20
```

The lab compares a status-aware composite index with `(project_id, created_at DESC, id DESC)`. The second index fits the second feed without an intervening status group. It can also inspect runs in time order and filter status, but may examine many entries when failures are rare. That is a workload tradeoff, not a contradiction.

## Direction and deterministic ordering

A B-tree can be scanned backward, which reverses the ordering across its keys. A uniform descending request can often use a reversed ascending index. Mixed directions require more care: reversing `(a ASC, b ASC)` does not produce `(a ASC, b DESC)`. Null placement and collation are part of the ordering contract too.

Use a unique tie-breaker for limited feeds. A timestamp alone does not determine which row comes first when timestamps tie. A stable sort order is necessary for correct cursor pagination, even when the current seed happens to use distinct timestamps.

## Experiment and decision

Predict the sort behavior for both feeds before running either. Then compare observed buffer work and rows examined, not only the final 20 returned rows. Retain the indexes that serve important workload families; avoid accumulating one index per SQL spelling. The solution adds a partial failure-feed alternative and asks you to identify which existing structure it actually replaces.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 4
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/04_composite_indexes.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab04`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why does changing status from failed to running differ from removing the status condition?
2. What does a predicate to the right of the first range sometimes save, even when it does not bound the scanned region?
3. When could a skip scan help a suffix-only predicate, and what evidence would you inspect?
4. Would one all-ascending index automatically satisfy every combination of ascending and descending ordering?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/04_composite_indexes.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/04_composite_indexes.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [indexes multicolumn](https://www.postgresql.org/docs/18/indexes-multicolumn.html)
- [indexes ordering](https://www.postgresql.org/docs/18/indexes-ordering.html)
- [indexes partial](https://www.postgresql.org/docs/18/indexes-partial.html)
- [sql createindex](https://www.postgresql.org/docs/18/sql-createindex.html)
