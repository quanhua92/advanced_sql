# 09. Partial Indexes And NULL

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 18, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/09_partial_indexes_and_null.sql) · [Worked answers](../solutions/09_partial_indexes_and_null.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: index only the rows that matter, without changing truth

Most completed run history is not waiting for a runner. A queue-specific index can therefore be much smaller than one covering every historical row. A partial index defines its indexed subset through a predicate. It is useful only when the query's conditions establish that the needed rows are inside that subset.

The lab uses a failure-feed index with project and time as keys and `status='failed'` as the predicate. Status need not also be a key merely to express which rows belong to the index. That index is not a complete answer for a running-only or all-status feed.

## Eligibility is a proof obligation

PostgreSQL must recognize at planning time that a query implies the partial-index predicate. Obvious matching conditions work; arbitrarily reformulated logical equivalents are not guaranteed to be recognized. A generic plan with `status=$2` cannot assume every possible value belongs to the failure subset. A custom plan with a known failure value may establish eligibility.

Parameterization is not inherently incompatible with partial indexes. For example, a query can parameterize project ID while keeping the trusted fixed failure condition in its SQL. The relevant question is whether the unknown part prevents proof of the index predicate. Do not discard safe binding to chase a particular index plan.

A partial unique index can also enforce uniqueness within a subset, such as one currently active assignment per resource. That requires a carefully defined active predicate. It does not automatically implement a lease protocol or protect external side effects.

## SQL has an unknown truth value

`NULL` is not an ordinary equality value. A comparison with null generally produces unknown. A `WHERE` clause retains only true rows, not false or unknown rows. Use `IS NULL`, `IS NOT NULL`, or a deliberately chosen null-safe comparison when those semantics are required.

Consider:

```sql
SELECT 2 NOT IN (1, NULL::integer);
```

This is unknown, not true. The expression cannot prove that 2 differs from an unknown value. In an anti-membership query, one unexpected null in the exclusion set can therefore remove results you expected to retain.

The lab contrasts this with `NOT EXISTS` using an explicit equality relation. That form asks whether a matching row exists. It is often the intended anti-join, but it still requires a decision about how null candidate IDs should be treated. There is no null-safe policy that should be assumed without stating it.

## Uniqueness and null policy

Ordinary unique constraints and `NULLS NOT DISTINCT` express different policies for null values. The lab uses a single-column constraint with `NULLS NOT DISTINCT` and `ON CONFLICT DO NOTHING` to demonstrate that a second null conflicts under that declaration. This is a business-rule choice, not a performance trick.

For platform data, distinguish “unknown runner,” “unassigned runner,” and “not applicable.” Using the same null for several meanings can make queue predicates and reporting harder to reason about.

## Lab and decision

Compare the literal failed-feed query with a forced generic prepared version. Then run the three-valued-logic and uniqueness examples. Record the predicate under which a partial index is eligible and write the null policy in words before using it in SQL.

A partial queue index reduces the search space; an atomic claim protocol establishes ownership. The capstone keeps those responsibilities separate.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 9
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/09_partial_indexes_and_null.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab09`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Can a query parameterize project_id and still use a partial index fixed to failed status?
2. Why does NOT IN behave unexpectedly when the excluded set contains NULL?
3. What does NULLS NOT DISTINCT change, and what does it not do?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/09_partial_indexes_and_null.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/09_partial_indexes_and_null.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [indexes partial](https://www.postgresql.org/docs/18/indexes-partial.html)
- [functions comparisons](https://www.postgresql.org/docs/18/functions-comparisons.html)
- [functions comparison](https://www.postgresql.org/docs/18/functions-comparison.html)
- [ddl constraints](https://www.postgresql.org/docs/18/ddl-constraints.html)
