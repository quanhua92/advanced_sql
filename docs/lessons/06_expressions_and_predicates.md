# 06. Expressions And Predicates

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 18, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/06_expressions_and_predicates.sql) · [Worked answers](../solutions/06_expressions_and_predicates.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: the index stores a value, not every function of that value

An ordinary index on `created_at` orders timestamps. A predicate comparing `created_at::date` to a day compares a derived value instead. PostgreSQL does not generally transform every function expression into a bound on the original timestamp index. Saying “functions destroy indexes” is too broad: the real question is whether the expression and operators match an available access path.

There are two main repairs. Rewrite the predicate into an equivalent searchable range, or index the expression actually being queried. Each repair must preserve semantics before it is judged on performance.

## A day is a pair of boundaries in a timezone

With the lab's timezone explicitly set to UTC, selecting January 2 can be written as:

```sql
WHERE created_at >= TIMESTAMPTZ '2026-01-02 00:00:00+00'
  AND created_at <  TIMESTAMPTZ '2026-01-03 00:00:00+00'
```

The half-open interval avoids guessing the final representable instant of the day. It also composes cleanly with adjacent intervals. `BETWEEN` includes both endpoints, so using midnight of the next day with `BETWEEN` would include an unwanted boundary row.

For a business day in Ho Chi Minh City, derive both midnight boundaries in `Asia/Ho_Chi_Minh`, then compare the stored `timestamptz` column to those instants. Do not silently replace a local-calendar query with a UTC-calendar query. For regions with daylight-saving transitions, a local day need not span exactly 24 elapsed hours.

## When an expression index fits

The lab also creates an index on `(created_at AT TIME ZONE 'UTC')::date`. Specifying the zone makes the chosen calendar interpretation explicit. A bare `timestamptz::date` depends on the session timezone and is not an immutable expression suitable for that index definition.

For a contact lookup, a `lower(email)` expression index can serve queries using that same expression. It does not establish a universal email-normalization policy. Case handling, collations, and the application's identity rules still require decisions. The example uses synthetic ASCII addresses to keep the indexing issue isolated.

Expression indexes precompute their indexed representation on relevant writes. They trade maintenance and storage for a useful search path. Avoid adding one for every formatting function used in a report.

## Types and conversions matter too

Bind parameters with the intended type. A conversion on the parameter side can leave the stored column directly searchable; wrapping the column in a conversion can change the expression being matched. The exact behavior depends on the available operator and index operator class, so verify the plan instead of relying on a slogan about all casts.

A query returning correct results is still wrong as an optimization when it changes how nulls, timezones, case, or boundaries are treated. Test adversarial values around midnight and both interval endpoints.

## Lab and transfer

Compare the cast predicate, the UTC half-open range, and the explicit UTC-date expression. Then inspect the case-insensitive lookup. The solution checks day-predicate equivalence under the declared UTC contract and provides a local-day variant for your platform.

For run-history APIs, document whether users filter by absolute instants or project-local calendar dates. That API choice should come before the index definition.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 6
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/06_expressions_and_predicates.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab06`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why is a half-open day range preferable to an inclusive next-midnight boundary?
2. Why does casting timestamptz directly to date involve session state?
3. When would you prefer an expression index over rewriting each predicate?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/06_expressions_and_predicates.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/06_expressions_and_predicates.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [indexes expressional](https://www.postgresql.org/docs/18/indexes-expressional.html)
- [datatype datetime](https://www.postgresql.org/docs/18/datatype-datetime.html)
- [functions datetime](https://www.postgresql.org/docs/18/functions-datetime.html)
- [sql createindex](https://www.postgresql.org/docs/18/sql-createindex.html)
