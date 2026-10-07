# SQL refresher for this course

SQL specifies relationships and results. Physical execution need not follow the written order of clauses. As a useful logical model, form the input relation, filter rows, form groups, filter groups, compute/select output, order, and limit. Window processing has its own place after grouping; aliases are not universally visible in every clause.

## Filtering, grouping, and missing values

```sql
SELECT project_id, count(*) AS failures, avg(duration_ms) AS mean_duration
FROM course.runs
WHERE status = 'failed'
GROUP BY project_id
HAVING count(*) >= 10
ORDER BY failures DESC, project_id
LIMIT 10;
```

`WHERE` removes rows before grouping. `HAVING` removes groups. `count(*)` counts rows; `count(error_code)` excludes null values. `NULL` is not an ordinary value: `error_code = NULL` is not the predicate for missing data. Use `IS NULL`. A nullable `NOT IN` subquery can produce unknown rather than true, which is why lesson 9 compares anti-join formulations.

## Join multiplicity

```sql
SELECT p.id, p.name, count(r.id) AS runs
FROM course.projects p
LEFT JOIN course.runs r ON r.project_id = p.id
GROUP BY p.id, p.name
ORDER BY p.id;
```

The left join retains projects with no matches. Counting `r.id` then gives zero for an unmatched project; counting `*` would count its null-extended output row. A filter on `r.status` in the outer `WHERE` can remove those unmatched projects. Moving a condition between `ON` and `WHERE` can change semantics.

A one-to-many join repeats the parent row. A later join to another many-side relation can multiply results again. Never repair an unexplained multiplication with `DISTINCT` before understanding the relationship.

## Subqueries, CTEs, and windows

```sql
WITH ranked AS (
  SELECT id, workflow_id, created_at,
         row_number() OVER (
           PARTITION BY workflow_id ORDER BY created_at DESC, id DESC
         ) AS position
  FROM course.runs
)
SELECT id, workflow_id, created_at
FROM ranked
WHERE position <= 3
ORDER BY workflow_id, created_at DESC, id DESC;
```

A CTE names an intermediate query. It is not automatically a temporary table or a guaranteed optimization barrier; materialization depends on its properties and explicit options. `GROUP BY` collapses groups; a window function preserves individual rows while computing over related rows. `row_number`, `rank`, and `dense_rank` differ when ties exist. The explicit ID tie-breaker makes the ordering unique here.

## Time and pagination

Prefer an explicit half-open time interval when the result contract calls for a date range:

```sql
SELECT id, created_at
FROM course.runs
WHERE created_at >= TIMESTAMPTZ '2026-01-02 00:00:00+00'
  AND created_at <  TIMESTAMPTZ '2026-01-03 00:00:00+00'
ORDER BY created_at, id;
```

The upper boundary is excluded. This avoids inventing a “last microsecond” of a day. A local day in Asia/Ho_Chi_Minh has different UTC bounds. `timestamptz` stores an instant; display and some casts depend on timezone settings.

## Transactions and parameters

```sql
BEGIN;
SELECT id FROM course.projects WHERE id = 42 FOR UPDATE;
-- Perform a small related change here, not a long external job.
ROLLBACK;
```

A transaction groups database effects and defines visibility/locking behavior. It is not a mechanism to hold a database connection throughout GPU inference. Parameterized application queries separate data values from query syntax. Table names and sort directions are not interchangeable with ordinary bound values; use an explicit allowlist when an application must select them dynamically.

Sources: [SQL queries](https://www.postgresql.org/docs/17/queries.html), [CTEs](https://www.postgresql.org/docs/17/queries-with.html), [window functions](https://www.postgresql.org/docs/17/functions-window.html), [date/time types](https://www.postgresql.org/docs/17/datatype-datetime.html).
