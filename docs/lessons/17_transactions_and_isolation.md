# 17. Transactions And Isolation

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 18, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/17_transactions_and_isolation.sql) · [Worked answers](../solutions/17_transactions_and_isolation.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: two correct-looking decisions can conflict when combined

A transaction groups database operations into a commit or rollback unit. Isolation determines what concurrent effects the transaction can observe and which anomalies are prevented. A transaction is not automatically a lock around every business invariant mentioned by its SELECT statements.

The first lab transfers a value between two teaching accounts and rolls back. The total is preserved within the transaction, and the original rows return after rollback. The account example is arithmetic, not a financial-system design. The important lesson is atomicity of related database changes.

## Read Committed and Repeatable Read

At PostgreSQL's default Read Committed isolation, separate statements can observe different committed states. A transaction can read a value, another session can commit an update, and a later SELECT can observe the new value. An ordinary statement snapshot is not a promise that the whole transaction sees one unchanging database.

Repeatable Read uses a transaction snapshot established when the relevant first statement executes. Subsequent ordinary reads see that snapshot, plus the transaction's own changes. It prevents several read anomalies, but it does not guarantee that every business invariant remains serializable.

PostgreSQL treats Read Uncommitted as Read Committed. The names alone do not justify importing an isolation table from another engine without checking its actual semantics.

## Write skew: the on-call example

Two rows represent two workers who can remain responsible for a service. The invariant is that at least one stays active. Both transactions read that two workers are active. Each deactivates a different row. Under snapshot isolation, both can commit because they wrote different rows, leaving no active worker.

Each transaction respected the invariant relative to its snapshot; their combination violated it. Row-level non-overlap is not sufficient to prove a cross-row business invariant.

The package includes coordinated two-session scripts and an automated concurrency test for this schedule. Do not try to demonstrate it with two sequential transactions in one psql connection: the essential overlap disappears.

## Serializable and retries

Serializable isolation aims to make committed concurrent transactions equivalent to a serial execution. PostgreSQL can reject a transaction with a serialization failure when the dependency pattern cannot safely commit. The application must retry the **whole transaction**, using fresh reads, rather than replaying only the failed last statement inside an aborted transaction.

A retry policy needs a bounded attempt budget, backoff, and idempotent external behavior. A serialization failure is an expected concurrency outcome, not necessarily a database defect. Deadlock failures also require transaction-level recovery, though their cause differs.

An alternative is explicitly locking a shared guard row representing the invariant before reading and updating participating rows. That can serialize the critical section at the cost of contention. A declarative constraint is preferable when it can accurately express the invariant; arbitrary cross-row assertions generally cannot be implemented by a simple row CHECK.

## External effects are outside a database rollback

A database transaction cannot automatically undo a remote API call or an already-started GPU job. Commit a claim or durable intent, then use a separate protocol for external work, retries, and acknowledgements. The capstone applies this separation with leases and ownership tokens.

## Lab and transfer

Run the single-session foundation, then follow the multi-session schedules for changing reads and write skew. Explain the invariant, the overlapping reads, the writes, and the commit outcomes. The correct solution is a concurrency protocol with retry behavior, not merely adding BEGIN and COMMIT around existing code.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 17
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/17_transactions_and_isolation.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab17`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why can two SELECTs in one Read Committed transaction return different committed values?
2. How can two transactions updating different rows violate a shared invariant under Repeatable Read?
3. What must be retried after a serialization failure, and why is retrying only the last statement insufficient?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/17_transactions_and_isolation.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/17_transactions_and_isolation.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [transaction iso](https://www.postgresql.org/docs/18/transaction-iso.html)
- [mvcc intro](https://www.postgresql.org/docs/18/mvcc-intro.html)
- [explicit locking](https://www.postgresql.org/docs/18/explicit-locking.html)
- [tutorial transactions](https://www.postgresql.org/docs/18/tutorial-transactions.html)
