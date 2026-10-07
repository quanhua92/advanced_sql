# 21. Partitioning

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 18, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/21_partitioning.sql) · [Worked answers](../solutions/21_partitioning.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: a growing event history needs both access and retention design

Partitioning divides one logical table into physical pieces using a declared key and bounds. It can make retention operations and some queries more manageable, but it is not an automatic speed multiplier. A query benefits from pruning only when PostgreSQL can determine that particular partitions cannot contain relevant rows.

The lab partitions run events by month on `created_at`. It creates three explicit monthly partitions plus a default partition, then adds a project/time index through the partitioned parent. The seed's actual time range determines which pieces contain rows.

## Choose the key from operations and queries

Time partitioning fits a retention rule that removes old time ranges together. Tenant partitioning fits different isolation or maintenance requirements but can create too many objects if there are many tenants. Hash partitioning has other distribution goals. Start with the dominant operations, expected partition count, and query predicates rather than selecting a key because its column is convenient.

A query with a direct half-open timestamp range can often eliminate unrelated monthly partitions. A query using only `id` lacks that time bound and may need to consider multiple partitions. Wrapping the key in a date expression can also prevent the same direct pruning proof. Inspect the plan rather than assuming every time-related expression is equally prunable.

## Pruning and indexes solve different problems

Pruning avoids visiting irrelevant partitions. Within the remaining partitions, PostgreSQL still needs an access path for their rows. A project/time index can help those local searches; partitioning does not replace it. Conversely, a small selective unpartitioned table with a good index may already be efficient without the planning and management overhead of partitions.

Pruning can occur at planning or execution stages depending on the query. Prepared parameters do not automatically eliminate all pruning opportunities. Look for removed subplans, executed children, and parameter-sensitive behavior in the actual plan.

## Uniqueness and foreign-key design

A unique or primary-key constraint on a partitioned table must include the partition key under PostgreSQL's applicable rules. The lab uses `(created_at, id)`, not a global uniqueness promise on `id` alone. That has consequences for referencing tables and API identifiers.

An application-generated globally unique event ID can be a useful convention, but convention and database-enforced uniqueness are not the same guarantee. Document what enforces each invariant. Do not silently weaken a key constraint to obtain a partitioned schema.

## Default partitions and operational work

A default partition catches rows outside explicitly declared ranges. That can prevent insert failures, but it also requires monitoring and management. Adding a new partition can need validation that overlapping rows are not already in the default partition, with locking and scan implications. A default partition is not a substitute for creating future ranges deliberately.

The lab detaches January. Detached rows remain in an ordinary table but are no longer returned through the parent. Detach is not the same as deleting the physical table, and neither operation by itself creates an archive backup. Retention workflows must define validation, archival, detach, and final deletion separately.

## Platform application

Time-based `run_events` retention is a plausible fit. Mutable run state and worker leases have different requirements and should not be partitioned merely to match the history table. Evaluate migrations, parent-level statistics, partition counts, and lock behavior before production adoption.

The capstone combines an indexed live queue with an event history while keeping their correctness responsibilities separate. Your final design should explain why partitioning helps a concrete operation and which queries still require cross-partition work.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 21
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/21_partitioning.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab21`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why can a time range prune monthly partitions while an id-only lookup cannot prove the same exclusions?
2. Why does partitioning not eliminate the need for indexes inside the relevant partitions?
3. What changes when January is detached, and what data still exists?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/21_partitioning.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/21_partitioning.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [ddl partitioning](https://www.postgresql.org/docs/18/ddl-partitioning.html)
- [sql altertable](https://www.postgresql.org/docs/18/sql-altertable.html)
- [sql createtable](https://www.postgresql.org/docs/18/sql-createtable.html)
- [planner stats](https://www.postgresql.org/docs/18/planner-stats.html)
