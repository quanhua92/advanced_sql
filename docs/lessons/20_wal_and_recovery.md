# 20. WAL And Recovery

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 18, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/20_wal_and_recovery.sql) · [Worked answers](../solutions/20_wal_and_recovery.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: COMMIT is not “write every changed data page now”

Write-ahead logging records information needed to recover database changes. The ordering rule ensures required log information reaches durable storage before affected data pages are relied upon as durable. Data pages can be written separately from the transaction's commit acknowledgement.

This distinction explains how PostgreSQL can commit without synchronously rewriting every changed heap and index page at that moment. It also explains why a checkpoint is not the same operation as committing one application's transaction.

## WAL records, flushing, and checkpoints

A transaction generates WAL through its logged changes. With the normal durable configuration, commit waits for the required local WAL flush; synchronous replication settings can introduce additional remote requirements. The precise guarantee depends on configuration and the storage stack honoring durability requests.

A checkpoint establishes a recovery starting point and coordinates writing dirty buffers. It is not a backup, and it does not establish that every external side effect triggered by application code happened exactly once. Full-page images help protect recovery from partial page-write problems under the relevant conditions, adding variability to WAL volume.

The lab prints `fsync`, `full_page_writes`, and `synchronous_commit` instead of silently disabling them to make writes appear fast. Do not turn durability protections off as a generic performance tutorial step.

## Logged versus unlogged tables

The lab inserts identical data into logged and unlogged tables and records statement WAL behavior. Unlogged tables avoid normal WAL logging for their data but do not offer the same crash-recovery or replication properties. Their contents can be truncated after an unclean shutdown. They are unsuitable as a substitute for durable run history merely because an insert benchmark improves.

A cluster-wide LSN difference can include other sessions and background work. Treat it as an observation with scope, not a perfectly isolated byte count for one statement. `EXPLAIN WAL` provides a more directly associated statement view, but neither field is identical to physical device write volume.

## A controlled optional recovery drill

The lab creates and commits a marker row. The operating guide then offers an explicitly manual unclean restart of **only the disposable Compose service**. After restarting, inspect server recovery logs and confirm the committed marker remains. The ordinary smoke suite never kills a server.

This demonstrates one recovery scenario on your environment. It is not a proof against power loss, lying storage caches, filesystem corruption, simultaneous disk failure, or all replication configurations. A careful test report states the failure injected and the checks performed.

## Backups solve a different problem

Crash recovery uses the database's recovery machinery to restore a consistent state after interruption. A backup and restore process protects against other failures, including accidental deletion and loss of the original data volume. Point-in-time recovery requires a suitable base backup and retained WAL with an operationally tested restore procedure.

The package includes a logical pg_dump/pg_restore helper for the teaching database. It restores into a separate named database and checks its seed count. This is a restore exercise, not a production backup policy or a point-in-time-recovery implementation.

## Platform application

A committed run claim can survive a database restart while the corresponding external job never starts, or an external job can finish before its result acknowledgement is committed. WAL protects database state, not the distributed workflow by itself. Leases, durable intents, idempotency, and reconciliation address that separate boundary.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 20
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/20_wal_and_recovery.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab20`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why can a transaction commit without all changed data pages being written at that exact moment?
2. What important guarantees are lost by replacing a durable history table with an unlogged table?
3. Why does a successful crash-recovery demonstration not replace backup-and-restore testing?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/20_wal_and_recovery.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/20_wal_and_recovery.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [wal intro](https://www.postgresql.org/docs/18/wal-intro.html)
- [wal internals](https://www.postgresql.org/docs/18/wal-internals.html)
- [runtime config wal](https://www.postgresql.org/docs/18/runtime-config-wal.html)
- [sql createtable](https://www.postgresql.org/docs/18/sql-createtable.html)
- [backup](https://www.postgresql.org/docs/18/backup.html)
