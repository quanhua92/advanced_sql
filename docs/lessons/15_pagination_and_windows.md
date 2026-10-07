# 15. Pagination And Windows

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 18, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/15_pagination_and_windows.sql) · [Worked answers](../solutions/15_pagination_and_windows.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: page 500 is not the same request as the first 20 rows

OFFSET pagination asks PostgreSQL to skip a number of ordered results before returning the next set. Even with an ordered index, skipped entries still represent work. Keyset pagination instead asks for rows after a known ordered boundary. It can avoid repeatedly walking an ever-growing prefix.

The lab uses a global run feed with a two-column deterministic order. It captures the row immediately before an offset page and compares the offset result with an equivalent keyset query on an unchanged dataset.

## A correct descending cursor

```sql
WHERE (created_at, id) < (:cursor_time, :cursor_id)
ORDER BY created_at DESC, id DESC
LIMIT 20
```

The boundary stores every ordering component needed to disambiguate rows. The strict inequality excludes the previously returned boundary row. For a project-specific feed, include the same project filter on every page and use a project-leading index when justified. A cursor from another filter or tenant is not interchangeable.

The lab columns are non-null and both directions are descending. Nullable sort columns and mixed directions require an explicit comparison policy, not a copied tuple inequality. A cursor contract should also specify serialization precision, ordering version, and filters. For an exposed API, treat a cursor as opaque validated state rather than trusting client-supplied authorization data.

## Stable order is not a stable historical snapshot

A unique tie-breaker makes ordering deterministic for a fixed set of rows. It does not freeze a changing table between requests. Newly inserted rows before the cursor, rows deleted during traversal, or updates to sort keys can affect what later pages see.

Decide whether the API offers a live feed, an as-of boundary, or a snapshot-consistent export. A long database transaction can preserve a snapshot but retain old versions and occupy resources. A bounded export strategy or an immutable event sequence can better match some application requirements. Correct keyset syntax alone does not resolve that product decision.

## Top-N per group

`row_number() OVER (PARTITION BY workflow_id ORDER BY created_at DESC, id DESC)` assigns a deterministic position within each workflow. Filtering rank at most three yields the latest three per group. It can process many input rows before discarding the rest; a lateral indexed lookup may be preferable when the selected workflow set is small.

Distinguish `row_number`, `rank`, and `dense_rank`. Row number gives unique positions. Rank and dense rank preserve ties differently, so a rank cutoff can return more than N rows. Choose whether the product wants exactly N records or all records tied at a boundary.

PostgreSQL's `DISTINCT ON` is also useful for one row per group when paired with the correct leading ORDER BY expressions. It is PostgreSQL-specific and has its own deterministic-order requirements.

## Window frames are not group collapse

A window function keeps input rows while calculating over a partition and frame. With ORDER BY and the default frame, peers with equal order keys can be included together. The lab's values 10, 10, 20 produce peer-aware running sums distinct from a ROWS frame with a unique tie-breaker.

`last_value` can surprise users because the default frame often ends at the current peer group rather than the end of the partition. Specify `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` when the intended value is from the entire partition. The solution includes this explicit variant.

## Lab and decision

Verify that offset and keyset pages contain identical IDs on the static seed. Then compare work, inspect the ranked result, and calculate the small frame example by hand. The learning target is both efficient pagination and a precise result contract under ties and concurrent change.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 15
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/15_pagination_and_windows.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab15`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why must the cursor include id when timestamps can tie, and why is the inequality strict?
2. Does deterministic keyset ordering guarantee a frozen dataset across separate requests?
3. Why can the two equal values in a default RANGE running sum share the same cumulative result?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/15_pagination_and_windows.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/15_pagination_and_windows.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [queries limit](https://www.postgresql.org/docs/18/queries-limit.html)
- [functions window](https://www.postgresql.org/docs/18/functions-window.html)
- [tutorial window](https://www.postgresql.org/docs/18/tutorial-window.html)
- [sql select](https://www.postgresql.org/docs/18/sql-select.html)
