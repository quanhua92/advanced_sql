# 19. MVCC And Snapshots

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/19_mvcc_and_snapshots.sql) · [Worked answers](../solutions/19_mvcc_and_snapshots.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: an old reader can keep old data alive

MVCC lets different transactions observe different visible row versions without making every ordinary read block every write. An UPDATE creates a new version, and snapshots determine which version a query can see. This is a visibility protocol, not merely a timestamp column maintained by the application.

The lab prints system columns before and after updating a teaching document. `ctid` is a physical location, and transaction-related fields expose parts of the version metadata. They are diagnostic information, not stable application identifiers or a complete user-facing audit history.

## What a snapshot represents

A transaction snapshot describes visibility relative to transaction activity. It is not simply “everything before wall-clock time T.” Transaction IDs can be assigned and commit in different orders, and visibility considers transaction state. PostgreSQL provides snapshot-related functions for inspection; manually comparing IDs is not a substitute for the engine's rules.

Read Committed generally takes a fresh statement snapshot. Repeatable Read retains a transaction snapshot for ordinary reads. A transaction also sees its own changes. The exact behavior of concurrent updates and locking reads requires the isolation rules, which is why this lesson follows transactions rather than treating MVCC as a separate magic feature.

## The retained-version experiment

Open session A in Repeatable Read and read document version one. Session B changes it to version two and commits. Session A reads again and still sees version one. Session B can run VACUUM, but the old version remains necessary to A's snapshot and cannot simply be discarded as useless.

Once A ends, a later cleanup can reclaim now-unneeded versions. The experiment coordinates reads and commits with explicit prompts, not arbitrary sleep durations that may race on different machines. Observe VACUUM output and the two session results; do not require one exact dead-tuple counter value.

A long transaction that never established or retained a relevant snapshot is not identical to this case. Diagnose actual snapshot horizons and transaction state rather than blaming every old connection age alone.

## Visibility map and index-only access

The visibility map summarizes page-level conditions useful to vacuum and index-only scans. It is different from the free-space map and different from a transaction's snapshot. A page can be all-visible for index-only purposes without implying that the application has an immutable copy of its contents forever.

Updates can clear all-visible state, and old snapshots can delay cleanup. Thus query performance and transaction hygiene can interact: a read-mostly covering index may lose some heap-avoidance benefit when pages are frequently modified or cleanup cannot advance.

## MVCC is not an audit log

Old row versions are internal, temporary, and subject to cleanup. They do not provide a durable business event history or a reconstructible record of every edit. Your platform's immutable note revisions and run events remain separate application responsibilities. Do not replace those features with access to xmin or assumptions about vacuum retention.

Transaction-ID wraparound prevention also motivates vacuum and freezing. This is not just optional file housekeeping. Avoid disabling autovacuum globally to preserve a classroom observation; the package confines any controlled maintenance experiment to disposable data.

## Platform application

Keep API transactions short, avoid idle transactions around agent reasoning or remote tool calls, and monitor backend transaction age and snapshot retention. Store durable history explicitly. The teaching goal is to connect version visibility, cleanup, index-only behavior, and application transaction boundaries into one coherent model.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 19
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/19_mvcc_and_snapshots.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab19`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why can session A keep seeing the old document after session B commits an update?
2. Why can VACUUM be unable to remove the old version while A remains active?
3. Why are xmin and retained heap versions not a replacement for a durable application event history?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/19_mvcc_and_snapshots.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/19_mvcc_and_snapshots.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [mvcc intro](https://www.postgresql.org/docs/17/mvcc-intro.html)
- [transaction iso](https://www.postgresql.org/docs/17/transaction-iso.html)
- [routine vacuuming](https://www.postgresql.org/docs/17/routine-vacuuming.html)
- [ddl system columns](https://www.postgresql.org/docs/17/ddl-system-columns.html)
- [storage vm](https://www.postgresql.org/docs/17/storage-vm.html)
