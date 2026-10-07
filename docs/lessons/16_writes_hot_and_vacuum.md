# 16. Writes HOT And Vacuum

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/16_writes_hot_and_vacuum.sql) · [Worked answers](../solutions/16_writes_hot_and_vacuum.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: changing one logical row can create several physical obligations

In PostgreSQL, an UPDATE generally creates a new row version rather than simply overwriting the old application values in place. Old versions can remain necessary for other snapshots. Index maintenance, free space, visibility, and later cleanup determine the physical cost of a mutation.

The lab contrasts two tables with identical row data and spare page space. One indexes a stable status field; the other also includes the note field being updated. The goal is to separate an eligible HOT path from a change that must maintain indexed data.

## HOT is conditional, not a synonym for a small update

A heap-only tuple update can avoid adding fresh entries to ordinary indexes when no relevant indexed values change and the replacement tuple fits on the same heap page. PostgreSQL 17 has qualifications involving summarizing indexes such as BRIN; the useful rule is to inspect the actual index definitions and engine version, not say every index always blocks HOT.

Changing an included column can matter even though it is not a search key. Expression-index inputs and partial-index predicate dependencies can matter too. A change to a column not visible in the projected dashboard may still affect an indexed expression or eligibility condition.

The lab's fillfactor leaves room for updates, but spare capacity is not a promise that every update is HOT. Tuple width and actual page occupancy matter. Inspect `n_tup_hot_upd` relative to update counts, while remembering that cumulative statistics can lag and be cached in the observing transaction.

## Dead versions and vacuum

DELETE marks rows as no longer visible to future snapshots when committed, but it does not instantly remove every physical trace or shrink all relation files. Ordinary VACUUM reclaims reusable space and performs other maintenance, including visibility-map and transaction-age work. It can sometimes truncate empty pages at the end, but it is not a general full compaction of the heap file.

VACUUM FULL rewrites the relation and has strong locking and disk-space implications. It is not a routine substitute for correctly functioning autovacuum. Long-lived snapshots can prevent cleanup of versions that are still needed, which lesson 19 demonstrates.

## Page splits and WAL add variability

Inserting an index entry into a full page can require splitting and structural changes. Wider entries reduce how much fits. WAL records and full-page images depend on the operation and checkpoint history. Two updates affecting the same number of rows can therefore produce different measured WAL volumes.

`EXPLAIN (ANALYZE, BUFFERS, WAL)` exposes statement-level evidence for the lab mutations. It is not a clean prediction of physical device writes, and cluster-wide WAL deltas can include other activity. Do not infer a fixed multiplicative write factor from the number of indexes.

## A useful schema-design question

A runner heartbeat is highly mutable; a completed run's creation timestamp is stable. Storing both in a heavily covered history index can create avoidable churn. Consider a narrow live-state representation and stable historical facts when their transactional relationship remains manageable.

This is not an instruction to denormalize blindly. Splitting data changes join patterns and atomicity requirements. The right design minimizes unnecessary maintenance without losing correctness or making the common read path worse.

## Experiment and transfer

Compare the two updates, flush and refresh statistics as the lab does, then delete rows and vacuum one table. Explain why file size may remain similar even though reusable space increased. The answer key verifies logical row counts and update results rather than asserting a particular HOT ratio on every machine.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 16
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/16_writes_hot_and_vacuum.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab16`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. What two broad conditions make an ordinary HOT update possible?
2. Why can INCLUDE(note) change the update path when note is never filtered?
3. Why can ordinary VACUUM be successful without dramatically shrinking a table file?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/16_writes_hot_and_vacuum.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/16_writes_hot_and_vacuum.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [storage hot](https://www.postgresql.org/docs/17/storage-hot.html)
- [routine vacuuming](https://www.postgresql.org/docs/17/routine-vacuuming.html)
- [storage page layout](https://www.postgresql.org/docs/17/storage-page-layout.html)
- [monitoring stats](https://www.postgresql.org/docs/17/monitoring-stats.html)
