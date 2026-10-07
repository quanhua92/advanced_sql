# Real concurrency: two sessions and an observer

Lessons 17–19 provide sequential foundations. The schedules below produce genuinely overlapping transactions. Use two independent terminals, A and B. An optional third terminal observes locks. In each terminal open:

```sh
docker compose exec postgres psql -X -U course -d advanced_sql
```

All following `\i` commands run **inside psql**, not in a shell. Before every fresh experiment, close/roll back previous transactions and run this once in an idle terminal:

```sql
\i /course/sql/concurrency/setup.sql
```

Setup resets only `course_concurrency`. Never run it while A or B still holds locks from the prior exercise. Teaching sessions allow longer idle transactions than ordinary labs, but the timeouts remain bounded. Press Enter at prompts only after the indicated step in the other session has occurred.

## 17A. Read Committed gets a new statement snapshot

In A:

```sql
\i /course/sql/concurrency/17_reads_a_rc.sql
```

A reads 100 and pauses. In B:

```sql
\i /course/sql/concurrency/17_reads_b.sql
```

B commits an increment. Resume A. Its second read should show 101, even though A remained in the same transaction. The guarantee concerns the statement's snapshot, not a repeatable view for the entire transaction.

## 17B. Repeatable Read keeps the earlier snapshot

Reset setup. Start A with `17_reads_a_rr.sql`, then run the same B script and resume A. A should continue to see 100 within its transaction. A new transaction can see 101. The first relevant statement establishes the Repeatable Read snapshot; saying only “BEGIN fixes every snapshot immediately” would be imprecise.

## 17C. Write skew under Repeatable Read

Reset setup. The invariant is that at least one of two on-call people must remain active. Start these files, leaving both at their prompts:

```sql
-- A
\i /course/sql/concurrency/17_skew_a_rr.sql
-- B, in its own terminal
\i /course/sql/concurrency/17_skew_b_rr.sql
```

Both have read a count of two active rows. Resume A so it deactivates person 1 and commits. Then resume B so it deactivates person 2 and commits. Query `SELECT count(*) FROM course_concurrency.on_call WHERE active;`. The count can become zero because the transactions wrote different rows after reasoning about a shared predicate. Row-level write conflict protection alone does not preserve this business invariant.

## 17D. Serializable detects this conflict

Reset setup. Use `17_skew_a_serial.sql` and `17_skew_b_serial.sql` with the same schedule: both read before either writes, then A commits before B continues. Expect SQLSTATE `40001` in the conflicting participant, possibly during the statement rather than only at `COMMIT`. Run `ROLLBACK;` after an aborted transaction. A real application must retry the whole logical transaction and re-evaluate the predicate, not replay only its final update.

Victim selection and exact error timing are not universal guarantees. The important properties are an observed serialization failure and preservation of the invariant among committed transactions under this schedule.

## 18A. Skip a locked candidate

Reset setup. A runs `18_skip_a.sql`, locking job 1 and pausing. B runs `18_skip_b.sql`, which atomically selects and marks another available job. Under this fixture B should claim job 2 rather than wait for job 1. Resume A to release its lock with a rollback.

This demonstrates queue-like behavior, not a fair global snapshot. A job can be skipped repeatedly while locked. Long transactions undermine throughput and fairness even when `SKIP LOCKED` avoids blocking other candidates.

## 18B. Produce and inspect a deadlock

Reset setup. Start A with `18_deadlock_a.sql`; it locks resource 1 and pauses. Start B with `18_deadlock_b.sql`; it locks resource 2 and pauses. Resume A first: it requests resource 2 and blocks. While A is waiting, inspect from the observer:

```sql
\i /course/sql/concurrency/monitor.sql
```

Now resume B, requesting resource 1. The cycle cannot be resolved merely by waiting. PostgreSQL should abort one participant with SQLSTATE `40P01`; do not require a particular victim. The scripts roll back, and temporarily allow the expected error rather than treating it as an ordinary success. Unexpected timeouts are not equivalent to a successful deadlock demonstration.

## 19. A snapshot preserves an older row version

Reset setup. A runs `19_snapshot_a.sql`, reading “version one” in Repeatable Read and pausing. B runs `19_snapshot_b.sql`, updating to “version two” and vacuuming. Resume A: the old transaction still sees its old version. After A commits, a fresh statement sees the new version.

Vacuum must respect versions still needed by active snapshots. Inspect snapshot age and transaction activity, but do not require an exact dead-tuple counter or heap size from this tiny fixture. Those are observations affected by implementation and timing.

## Automated schedules

From a normal shell:

```sh
python scripts/course.py capstone
python scripts/course.py concurrency-test
```

The standard-library harness creates separate backend connections, coordinates statements, observes a real blocked PID before closing the deadlock cycle, and verifies SQLSTATEs and result invariants. It also verifies distinct capstone claims while the first transaction is still open. Missing capstone setup is explicitly reported as a skip, not as a passed capstone test. Logs go to `outputs/`.

The harness was included but not executed in the preparation environment. Run it on the supplied PostgreSQL baseline before treating its checks as observed evidence. A successful schedule test covers that schedule, not every possible interleaving.

Sources: [Transaction isolation](https://www.postgresql.org/docs/17/transaction-iso.html), [explicit locks](https://www.postgresql.org/docs/17/explicit-locking.html), [SELECT locking clauses](https://www.postgresql.org/docs/17/sql-select.html), [vacuum](https://www.postgresql.org/docs/17/routine-vacuuming.html).
