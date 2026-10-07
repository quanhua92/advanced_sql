# 05. Scan Strategies

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 18, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/05_scan_strategies.sql) · [Worked answers](../solutions/05_scan_strategies.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: three ways to obtain matching rows

A sequential scan walks the relation's heap pages and evaluates rows. An ordinary index scan traverses matching index entries and accesses the corresponding heap tuples. A bitmap plan first represents matching locations, then visits heap pages in physical order. Each approach can be sensible for the same predicate under different data and workload conditions.

The mistake is ranking them by name. A sequential scan can be efficient when most rows or pages are needed. An index scan can be excellent for an ordered top-N query. A bitmap path can reduce scattered heap access but loses the source index's ordering.

## Distinguish rows, pages, and order

The failure predicate matches 1% of the seeded rows; succeeded matches 85%. Both have the same status index available in the lab. Their required aggregate reads `duration_ms`, which is not covered by that index. The statuses repeat through the heap rather than forming one compact contiguous region.

This layout intentionally makes page distribution relevant. Do not assume that 1% of rows means 1% of heap pages, and do not assume a threshold such as 5% determines the answer. A narrow covering index, clustered heap, warm cache, different `random_page_cost`, and a useful `LIMIT` all change the comparison.

A bitmap heap scan can visit a page once and inspect its matching tuple positions. Under memory pressure, a bitmap can become lossy at page granularity and require rechecking tuples. Inspect `Heap Blocks`, recheck conditions, and rows removed by recheck when present. A `Recheck Cond` label alone does not establish that every match is a false positive.

## Natural plans first, counterfactuals second

The first two experiments leave the planner's choices alone. Later transactions use `SET LOCAL` to discourage selected scan families. These are controlled questions: what would another path cost here? The settings automatically revert at transaction end.

They are not instructions to disable sequential scanning in production. Planner switches generally discourage paths rather than rewriting SQL into a guaranteed strategy. If no legal alternative exists, a discouraged node can still appear. Always inspect what actually executed.

For each plan, write down the aggregate result, rows processed, estimated rows, buffers, and repeated elapsed times. Equal aggregate results verify semantics; different plan costs and runtime observations support a performance argument. Do not compare only the final one-row aggregate output, which hides the number of rows consumed.

## Why bitmap combination is not free

Two single-column indexes can sometimes combine for `AND` or `OR`. Building two bitmaps costs work. If one index is already highly selective, fetching those candidates and applying a remaining filter can be cheaper than consulting the second index. A composite index might directly identify the needed combination and preserve useful order, at the cost of another maintained structure.

Lesson 8 makes this concrete. For now, explain the difference between avoiding repeated heap-page visits and providing a chronological result. They are different benefits.

## Platform application

A dashboard feed, a failure-count report, and a full export can legitimately choose different access paths on the same runs table. An optimization review should describe which workload changed. A blanket “we eliminated all sequential scans” target is an invitation to optimize the wrong quantity.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 5
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/05_scan_strategies.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab05`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why might an index scan lose when most matching rows are scattered across many heap pages?
2. What benefit can a bitmap heap scan supply, and what ordering benefit does it generally lose?
3. Why must planner-disable experiments remain local diagnostics rather than permanent tuning?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/05_scan_strategies.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/05_scan_strategies.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [using explain](https://www.postgresql.org/docs/18/using-explain.html)
- [indexes bitmap scans](https://www.postgresql.org/docs/18/indexes-bitmap-scans.html)
- [runtime config query](https://www.postgresql.org/docs/18/runtime-config-query.html)
- [indexes ordering](https://www.postgresql.org/docs/18/indexes-ordering.html)
