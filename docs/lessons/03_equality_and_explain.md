# 03. Equality And Explain

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/03_equality_and_explain.sql) · [Worked answers](../solutions/03_equality_and_explain.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: EXPLAIN looks precise, but its fields answer different questions

A plan is a tree of execution steps. Read it from the result-producing root down to its inputs, then reason about work flowing upward. A `Limit` may stop an input early; a sort may need to examine its whole input before returning the first row. Startup cost and total cost describe different parts of that possibility.

Plain `EXPLAIN` shows the planner's estimates. `EXPLAIN ANALYZE` runs the query and attaches measurements. Planner costs are not milliseconds, estimated widths are not measured result sizes, and the presence of an index node does not establish good performance.

## Estimates, actuals, and repetition

Suppose an inner node displays 4 actual rows with 500 loops. That means roughly 2,000 rows were produced across executions, not four rows of total work. Actual row and timing fields are reported per-loop averages where the node executes repeatedly. Rounding and early termination can complicate simple arithmetic. Parallel-worker reporting introduces another layer, which the baseline labs temporarily avoid by disabling parallel query in their sessions.

Time at an ancestor generally includes time spent in its descendants. Similarly, buffer counts are inclusive where reported. Do not sum all nodes into a fictional query total. Instead locate where rows multiply, where large candidate sets are rejected, and where the first major estimate error appears.

An underestimated outer relation can turn a seemingly cheap repeated inner lookup into substantial work. The visible symptom may be a slow nested loop, while the upstream cause is an estimate that expected a handful of outer rows.

## Three equality experiments

The lab first retrieves a known primary-key ID. It then retrieves a project before and after a project index is available. The equality operator is the same broad kind of condition, but result cardinality and index availability differ. Inspect `Index Cond`, `Filter`, and `Rows Removed by Filter`: an index condition and a later filter are not interchangeable descriptions of work.

`ANALYZE` updates the statistics used for planning; it does not create an index or execute the user's query. The lab prints `n_distinct`, null fraction, and physical correlation so you can connect estimates to the information the planner receives. Correlation here describes relationship to physical order, not general statistical dependency between two arbitrary columns.

## A useful plan-reading procedure

First state the query's required result and cardinality. Then identify the selected scan and any sort, join, or aggregate. Compare estimated and observed cardinalities at the earliest substantial divergence. Next inspect repetition, buffers, temporary I/O, and timing. Finally connect the candidate optimization to one observed source of work.

For automated collection, JSON plans are easier to traverse than a screenshot. Preserve the full plan with server settings, schema/index definitions, row distribution, and the exact parameter values. A stripped screenshot often omits the parameter that caused the problem.

## Safety and interpretation

`EXPLAIN ANALYZE` executes writes as well as reads. A rolled-back write experiment can still generate WAL, consume sequence values, or invoke nontransactional effects. Do not assume that adding `ROLLBACK` makes arbitrary production experiments harmless. In this package, writes run only against disposable lesson tables.

The lesson's performance assertion is qualitative: the new access path is available and its observed use can be explained. There is no required millisecond target or plan shape that every machine must reproduce.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 3
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/03_equality_and_explain.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab03`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. A node reports actual rows=4 and loops=500. What quantity can you estimate, and what should you not sum?
2. Where would you investigate a nested loop that processed far more outer rows than estimated?
3. Why is EXPLAIN ANALYZE on an UPDATE different from an estimated plan preview?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/03_equality_and_explain.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/03_equality_and_explain.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [using explain](https://www.postgresql.org/docs/17/using-explain.html)
- [sql explain](https://www.postgresql.org/docs/17/sql-explain.html)
- [planner stats](https://www.postgresql.org/docs/17/planner-stats.html)
- [monitoring stats](https://www.postgresql.org/docs/17/monitoring-stats.html)
