# Patterns and their contracts

## Keyset pagination

```sql
-- Values shown are a teaching cursor, not a dynamically assembled application query.
SELECT id, created_at FROM course.runs
WHERE project_id=42
  AND (created_at,id) < (TIMESTAMPTZ '2026-02-01 00:00:00+00',200000::bigint)
ORDER BY created_at DESC,id DESC LIMIT 20;
```

The comparison direction follows the descending order. The cursor must include the full unique ordering and remain tied to the same filter scope. Mixed directions and nullable ordering keys require more careful predicates. Keyset pagination does not automatically freeze the dataset between requests.

## Top N per parent

```sql
SELECT w.id AS workflow_id,r.id AS run_id,r.created_at
FROM course.workflows w
LEFT JOIN LATERAL (
  SELECT id,created_at FROM course.runs
  WHERE workflow_id=w.id ORDER BY created_at DESC,id DESC LIMIT 3
) r ON true
WHERE w.project_id=42;
```

The left join retains empty parents. An appropriate workflow/time index can make bounded probes useful. A window-function formulation is another strategy, especially for broad batch results. Inspect total work rather than assuming one is always superior.

## Null-safe anti-existence

```sql
SELECT p.id FROM course.projects p
WHERE NOT EXISTS (SELECT 1 FROM course.runs r WHERE r.project_id=p.id);
```

For nullable keys, decide whether two nulls should count as a match. Ordinary equality and `IS NOT DISTINCT FROM` express different contracts. Do not treat `NOT IN`, `NOT EXISTS`, and every anti-join rewrite as universally identical.

## Short queue claims

The executable capstone provides `capstone.claim_one`. Use a short transaction, commit the claim, execute externally, then renew or complete with the returned ownership token. A claim is not authorization to access any tenant; the application must separately establish the caller's allowed scope.

## Safe retry outline

Begin the complete logical transaction, read the required state, apply changes, and commit. On a retryable serialization/deadlock failure, roll back and restart the logical transaction with a bounded policy. Do not retry only the last statement while retaining stale assumptions. Keep external side effects outside retryable database work unless they have their own idempotency contract.

Sources: [SELECT](https://www.postgresql.org/docs/17/sql-select.html), [LATERAL](https://www.postgresql.org/docs/17/queries-table-expressions.html), [comparisons](https://www.postgresql.org/docs/17/functions-comparison.html), [serialization failures](https://www.postgresql.org/docs/17/mvcc-serialization-failure-handling.html).
