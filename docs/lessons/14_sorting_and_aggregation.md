# 14. Sorting And Aggregation

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/14_sorting_and_aggregation.sql) · [Worked answers](../solutions/14_sorting_and_aggregation.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: a small final result can hide a large sort or aggregation

A query returning one aggregate row can read every qualifying input row. A LIMIT can bound returned rows without bounding the work needed to identify them. Ask which operators can emit early and which must accumulate or inspect their input first.

The lab contrasts a top-20 chronological feed before and after an ordering index, then examines grouped counts and an intentionally memory-constrained sort. Each experiment separates result cardinality from consumed input cardinality.

## Obtaining order

Without a useful ordered access path, PostgreSQL may scan candidates and sort them. A top-N sort can retain only the best N candidates in memory, but it generally still examines the candidate input to know which N are best. An aligned index can sometimes provide those rows directly and stop early.

A sort node's method and memory or disk usage explain more than its name. An external merge sort indicates temporary storage work. Temporary I/O is not the same as table heap I/O, and increasing shared_buffers does not simply remove every sort spill.

For multi-column order, check key direction, collation, and null placement. Mixed ordering requirements may not match an index merely because its column names look right. Incremental sorting can also exploit a prefix order without the whole requested order being available; inspect the actual plan rather than dividing all queries into only “sort” and “no sort.”

## Hash versus ordered aggregation

A hash aggregate groups rows by building state keyed by grouping values. An ordered group aggregate can process rows with equal group keys together when suitable order is available. Sorting to obtain that order is part of the plan's cost.

A grouping index does not make an arbitrary SUM or COUNT constant-time. The aggregate usually still needs its input rows, even when the index supplies a convenient order or a narrower covering representation. Do not mistake an Index Only Scan over hundreds of thousands of entries for a single metadata lookup.

The lab uses `COUNT(*) FILTER (WHERE status='failed')` alongside total counts. This computes related measures over one grouped input while keeping their conditions explicit. Note that COUNT(*) counts rows while COUNT(column) excludes null values in that expression.

## Memory is multiplied by concurrency

The local work_mem change demonstrates pressure on a single query. It is not a recommendation to give every application connection a large allocation. A query can contain several sorts or hashes, parallel workers can participate, and many queries can run simultaneously. Hash memory also depends on its documented multiplier.

Before increasing memory, reduce unnecessary projected width, correct accidental row multiplication, apply valid early filters, and check whether a useful ordered path exists. A memory setting cannot repair incorrect query semantics.

## Lab and platform transfer

Run the baseline top-N, the indexed top-N, both aggregate strategies, and the small-memory sort. Record rows consumed, sort method, temporary I/O, and whether the grouping path still scans a large input.

For a dashboard repeatedly computing expensive historical aggregates, consider whether cached or incrementally maintained summaries fit the freshness and correctness requirements. That is a separate design decision requiring a refresh or update protocol; it is not something an ordinary B-tree automatically provides.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 14
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/14_sorting_and_aggregation.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab14`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why can a top-N sort still inspect nearly the entire candidate set?
2. Does a grouping index turn COUNT(*) into a constant-time metadata lookup?
3. Why is work_mem not safely interpreted as the maximum memory of a whole application connection?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/14_sorting_and_aggregation.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/14_sorting_and_aggregation.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [indexes ordering](https://www.postgresql.org/docs/17/indexes-ordering.html)
- [using explain](https://www.postgresql.org/docs/17/using-explain.html)
- [runtime config resource](https://www.postgresql.org/docs/17/runtime-config-resource.html)
- [functions aggregate](https://www.postgresql.org/docs/17/functions-aggregate.html)
