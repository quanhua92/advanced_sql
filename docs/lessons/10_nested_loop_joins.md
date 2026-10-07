# 10. Nested Loop Joins

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 18, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/10_nested_loop_joins.sql) · [Worked answers](../solutions/10_nested_loop_joins.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: repeated lookups can be efficient or disastrous

A nested-loop join processes an outer input and executes an inner access for each outer row. Its cost depends on how many outer rows reach it and what each inner execution must do. The join name alone does not reveal whether that is a good strategy.

Your platform might display five workflows and the latest three runs for each. A parameterized inner index probe that stops after three rows is a very different workload from scanning all run history once per workflow. The lab makes that distinction visible with `LATERAL` and a workflow/time index.

## A bounded per-workflow lookup

```sql
SELECT w.id, recent.id, recent.created_at
FROM course.workflows AS w
CROSS JOIN LATERAL (
  SELECT id, created_at
  FROM lab10.runs AS r
  WHERE r.workflow_id = w.id
  ORDER BY created_at DESC, id DESC
  LIMIT 3
) AS recent
WHERE w.project_id = 42;
```

The inner query can depend on the current workflow. An index on `(workflow_id, created_at DESC, id DESC)` offers a bounded ordered path. Inspect the inner node's loops and rows per loop. Five inexpensive probes can be a good design; 500,000 expensive probes can be a different story.

The final query order is a separate contract. Add an outer `ORDER BY` when the UI depends on result order. Do not infer a guaranteed presentation order from how the nested loop happens to emit rows today.

## INNER versus LEFT is a correctness choice

`CROSS JOIN LATERAL` excludes a workflow when its inner query returns no rows. A `LEFT JOIN LATERAL (...) ON true` preserves the workflow and supplies nulls for the missing run. If the dashboard must show never-run workflows, the left form is appropriate.

Likewise, adding a `WHERE` condition on a nullable right-side column can accidentally eliminate the unmatched rows from a left join. Decide whether a predicate constrains matched rows or filters final output. A faster query that silently removes empty workflows has not met the product requirement.

## Database nested loops are not application N+1

An application N+1 pattern sends one request to list workflows and then separate requests to fetch each workflow's runs. That adds network and driver overhead and can change snapshot behavior between requests. A database nested loop occurs inside one server-side execution plan. It may perform many probes without those extra application round trips.

Replacing N+1 with one SQL statement does not guarantee low server work. A poorly indexed correlated subquery can still scan repeatedly. Conversely, refusing all nested loops can discard an efficient server-side strategy. Measure both round trips and database execution work.

## Cardinality estimates affect the decision

When the outer input is underestimated, the planner may expect a small number of probes and choose a plan that becomes expensive with the actual row count. Investigate the outer filter and its statistics before simply forcing a hash join. For bounded top-N-per-parent problems, a different join family may not express the same early-stop opportunity.

## Lab and transfer

Compare the latest-three lateral query with a join that counts all runs for the selected workflows. The second query cannot stop after three. The solution uses a left lateral form and a window-function alternative to explore the same business requirement with different processing strategies.

For each platform screen, state whether empty parents must be visible, how many children are needed, and whether ordering is deterministic. Those requirements guide the index and join design together.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 10
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/10_nested_loop_joins.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab10`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why can a nested loop be excellent for a latest-three-per-workflow query?
2. How do CROSS JOIN LATERAL and LEFT JOIN LATERAL differ for a workflow with no runs?
3. Why is a database nested loop not the same thing as application N+1?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/10_nested_loop_joins.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/10_nested_loop_joins.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [queries table expressions](https://www.postgresql.org/docs/18/queries-table-expressions.html)
- [using explain](https://www.postgresql.org/docs/18/using-explain.html)
- [indexes multicolumn](https://www.postgresql.org/docs/18/indexes-multicolumn.html)
- [sql select](https://www.postgresql.org/docs/18/sql-select.html)
