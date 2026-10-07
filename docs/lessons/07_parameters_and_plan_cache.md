# 07. Parameters And Plan Cache

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/07_parameters_and_plan_cache.sql) · [Worked answers](../solutions/07_parameters_and_plan_cache.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: safe parameters and good plans are different concerns

Parameter binding keeps data values separate from SQL syntax. Prepared execution can also avoid repeating some parsing and planning work. These are related mechanisms, but safety does not guarantee an optimal plan for every parameter distribution.

The lab creates a deliberately skewed table: 100 rows belong to a rare category and 99,900 to a common category. A status-like category index is available. A rare-value lookup can favor an index path while a common-value aggregation can favor scanning. Reusing one plan for both values can therefore involve a compromise.

## Custom and generic planning

A custom prepared plan is made with current parameter values available. A generic plan is reusable without specializing to those values. In automatic mode, PostgreSQL uses a documented cost-based heuristic to choose whether generic reuse appears worthwhile after initial custom executions. It is not simply “the sixth call always becomes generic.”

`force_custom_plan` and `force_generic_plan` make the two alternatives observable in this experiment. They are diagnostic controls, not automatic recommendations for every application connection. The query reads payload length so the category index does not trivially cover all needed values.

Inspect both the estimated cardinality and selected path for rare and common inputs. In generic plans, a parameter symbol may remain visible in the index condition or filter. `pg_prepared_statements` exposes counters for prepared statements in the current session; it is not a catalog of every application's cached queries across the server.

## Keep preparation, pooling, and query text distinct

A prepared statement's lifecycle belongs to a database session. Connection pooling can change which session receives a request and whether named prepared statements persist. Client libraries also have their own thresholds and behaviors. Check the actual driver and pool configuration before attributing production behavior to the SQL-level `PREPARE` demonstration.

The course uses `psql` and explicit server-side statements so the mechanism is visible without importing a specific driver's defaults. Parameterized execution is not an invitation to manually interpolate strings.

## Defensive query construction

A value such as a project ID or status belongs in a bound parameter. A table name or sort direction is not a value placeholder in the same sense. Use a small allowlist and the driver's identifier-composition tools for dynamic SQL structure. Keep the application role least-privileged, and do not expose arbitrary database error details to users.

Conceptually, application code should pass a fixed query and a separate tuple of values. It should not build the SQL by concatenating a user-provided status. The exact placeholder spelling depends on the driver; SQL-level `$1` and a Python driver's placeholder syntax are not interchangeable examples.

## The partial-index connection

A generic plan that must handle any status cannot assume that `$2` always equals the failure predicate of a partial index. A custom plan with a known value may establish eligibility. Lesson 9 demonstrates this without weakening parameter safety. A performance issue involving a generic plan is not a reason to replace safe binding with string concatenation.

## Experiment and decision

Run all four plan/value combinations and record estimate differences. Then propose a response based on workload: improve statistics, separate genuinely different query families, assess a different index, or evaluate targeted planning settings. Every proposal should preserve safe value binding and account for planning overhead.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 7
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/07_parameters_and_plan_cache.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab07`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. What does parameter binding guarantee, and what performance property does it not guarantee?
2. Why is “after five executions the plan is always generic” inaccurate?
3. Can a user-selected table name be treated as an ordinary bound value?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/07_parameters_and_plan_cache.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/07_parameters_and_plan_cache.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [sql prepare](https://www.postgresql.org/docs/17/sql-prepare.html)
- [runtime config query](https://www.postgresql.org/docs/17/runtime-config-query.html)
- [protocol flow](https://www.postgresql.org/docs/17/protocol-flow.html)
- [indexes partial](https://www.postgresql.org/docs/17/indexes-partial.html)
