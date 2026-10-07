# 11. Hash And Merge Joins

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/11_hash_and_merge_joins.sql) · [Worked answers](../solutions/11_hash_and_merge_joins.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: broad joins need a different work model

When a report consumes a substantial fraction of both inputs, repeated point lookups may not be the cheapest approach. A hash join builds a lookup structure from one input and probes it with the other. A merge join consumes inputs ordered by their join keys. Neither strategy is universally superior, and both have setup costs.

The lab joins run history to workflows for a project-level aggregate. Unlike the latest-three feed, this report needs all relevant runs. The planner can consider processing each input in bulk rather than repeatedly stopping after a few rows.

## Hash join: build, probe, and memory

A hash join groups build-side keys into an in-memory hash structure when possible. Probe rows find candidate matches through those keys, and the join condition still determines the result. PostgreSQL can choose a build side that differs from the left/right order in the SQL text.

A larger build relation may require multiple batches and temporary I/O when memory is insufficient. Inspect hash buckets, batches, memory usage, and temporary reads/writes in the actual plan. Estimate errors about row count or width can make memory behavior very different from the planner's expectation.

`work_mem` is not one global per-query budget. Multiple memory-consuming nodes, workers, and simultaneous queries can allocate independently; hash operations also have their documented memory multiplier. Increasing it broadly to fix one report can create concurrency problems elsewhere.

## Merge join: order has a price

A merge join can advance through ordered join keys rather than repeatedly hashing or probing each row. The ordered inputs may come from suitable indexes or explicit sorts. If sorting dominates the workload, the merge itself can be cheap while the overall query is expensive.

Duplicate keys matter. An equality join between many rows sharing the same key can produce many combinations. A faster algorithm does not make that output cardinality disappear. Before tuning, confirm that the join key and intended multiplicity are correct. An accidental many-to-many join often masquerades as a performance issue.

## Controlled alternatives

The lab first observes the natural plan. Separate transactions then discourage nested loops and one of the bulk join families to expose alternatives. A final self-join uses a larger build input with a small local memory setting to make batching behavior more observable.

These experiments preserve query semantics and restore planner settings at transaction end. They do not establish a server-wide preference. If the selected plan differs from the expected family, read the full plan and available legal paths rather than treating the setting as a guarantee.

## A diagnosis sequence

Check result multiplicity first. Then find the earliest estimate divergence. Determine whether the dominant work is scanning, building, probing, sorting, spilling, or producing a huge result. Only then propose a targeted change: a corrected join condition, better statistics, a useful index, a smaller projection, or a carefully scoped memory setting.

Avoid ranking only the join node's timing. Its input sorts and scans are part of the cost of obtaining the required rows. Inclusive timing fields must not be summed into a double-counted total.

## Platform application

A campaign summary across all runs can favor bulk processing; a live workflow card can favor bounded probes. The same tables support both. The answer key asks you to compare their data consumption rather than insist that a platform should standardize on one join family.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 11
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/11_hash_and_merge_joins.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab11`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. What can make a hash join spill even when the estimated build input looked small?
2. When can a merge join have a cheap join step but an expensive overall plan?
3. Why should an unexpectedly large join result be checked for a correctness problem before tuning?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/11_hash_and_merge_joins.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/11_hash_and_merge_joins.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [using explain](https://www.postgresql.org/docs/17/using-explain.html)
- [runtime config resource](https://www.postgresql.org/docs/17/runtime-config-resource.html)
- [planner stats](https://www.postgresql.org/docs/17/planner-stats.html)
- [queries table expressions](https://www.postgresql.org/docs/17/queries-table-expressions.html)
