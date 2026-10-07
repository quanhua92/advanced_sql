# 18. Locks And Worker Claims

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/18_locks_and_worker_claims.sql) · [Worked answers](../solutions/18_locks_and_worker_claims.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: many runners can ask for the same next job

A naive worker first SELECTs a queued job, performs work, and later updates it. Another worker can select the same row during that gap. A correct database claim must establish ownership atomically. It must also distinguish database ownership from the external execution that follows.

The lab uses a small queue and a short transaction. A candidate is selected with a row lock and updated through the same statement. Other claimers can skip locked candidates instead of waiting for the first one.

## A short atomic claim

```sql
WITH candidate AS (
  SELECT id FROM lab18.jobs
  WHERE status = 'queued'
  ORDER BY priority DESC, id
  FOR UPDATE SKIP LOCKED
  LIMIT 1
)
UPDATE lab18.jobs AS j
SET status = 'running'
FROM candidate AS c
WHERE j.id = c.id
RETURNING j.*;
```

The candidate's row lock is held until transaction end. Commit the claim before running a long GPU task. Holding the transaction open throughout external work can retain locks and snapshots, occupy a connection, and magnify failure recovery problems.

SKIP LOCKED deliberately gives an incomplete view of rows that are currently locked. That is useful for queue-like selection, not a general consistent-reporting strategy. It does not guarantee strict global priority, fairness, or exactly-once job execution. A locked higher-priority job can be bypassed.

## Locks at different levels

PostgreSQL has table-level lock modes, row locks, and internal synchronization mechanisms. Ordinary row-version reads often coexist with writes, but schema changes and explicit locks can block work. A wait is not necessarily slow query computation.

`pg_stat_activity`, `pg_blocking_pids`, and `pg_locks` help identify who is waiting for whom. A row-lock conflict can appear through a transaction-ID wait, so do not expect every blocked row to show up as an obvious tuple entry in pg_locks. Observe blocking relationships, transaction age, and the statements involved.

Use lock and statement timeouts deliberately. A timeout bounds waiting; it does not make the interrupted business operation complete. After an error inside a transaction, rollback before issuing unrelated statements.

## Deadlocks: circular waiting

If session A holds row 1 and asks for row 2 while session B holds row 2 and asks for row 1, neither can proceed. PostgreSQL detects the cycle and aborts one participant. Which transaction becomes the victim is not a business-level guarantee.

A consistent lock acquisition order reduces this class of deadlock. Keep transactions short and acquire locks only for the required critical section. Still implement retries because ordering alone does not eliminate every possible dependency pattern in a larger application.

The coordinated scripts intentionally create a deadlock in disposable resources. Expected SQLSTATE `40P01` is a successful demonstration, not a failing learning objective. The automated test checks that a deadlock is detected rather than requiring a particular victim.

## From claim to recoverable ownership

A state flag alone strands a job when its worker disappears. Add a lease expiry, attempt identity, renewal checks, and a completion operation conditioned on the current ownership token. A reclaimer can make expired work available again; stale workers must not be allowed to acknowledge a newer owner's attempt.

Even that protocol permits duplicate external execution during failures. Idempotency keys or externally enforced fencing are necessary where repeated side effects are unacceptable. The capstone teaches this boundary explicitly rather than calling a row lock an exactly-once engine.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 18
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/18_locks_and_worker_claims.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab18`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why must selection and claim happen atomically, and why should the claim transaction end before long external work?
2. What correctness and fairness guarantees does SKIP LOCKED not provide?
3. How do you diagnose a deadlock, and what is the application recovery unit?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/18_locks_and_worker_claims.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/18_locks_and_worker_claims.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [explicit locking](https://www.postgresql.org/docs/17/explicit-locking.html)
- [sql select](https://www.postgresql.org/docs/17/sql-select.html)
- [monitoring stats](https://www.postgresql.org/docs/17/monitoring-stats.html)
- [errcodes appendix](https://www.postgresql.org/docs/17/errcodes-appendix.html)
