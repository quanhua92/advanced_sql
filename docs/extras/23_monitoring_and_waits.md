# 23. Workload evidence and lock waits

A single slow query screenshot is not a workload profile. `pg_stat_statements` aggregates execution information by normalized query identity. `pg_stat_activity` describes current sessions and their state. They answer different questions: which query families consumed resources over an observation period, and what is happening now?

The Compose configuration preloads pg_stat_statements, and initialization creates its extension. The lab executes a repeated aggregate and prints a top-total-time view. Compare total time with call count and mean time. A moderately slow query called constantly can consume more resources than a rare expensive report. A mean is not a p95 or p99 latency percentile, and server execution statistics do not include every application or connection-pool delay.

Record reset boundaries and the observation window. Do not reset all query statistics merely to make a tutorial output look tidy when other users depend on them. This lab does not reset shared counters. Its database is disposable, but the operational habit should transfer to shared environments.

A session waiting on a lock may be slow because another transaction remains open, not because its scan needs a new index. Follow `pg_blocking_pids`, inspect transaction age and wait events, and determine the owning application action. Row waits can appear through transaction locks rather than a simple tuple row in pg_locks.

Do not terminate sessions indiscriminately. Identify whether the owner is a migration, maintenance operation, or live application transaction, and understand the rollback impact. The package's automatic tests own and clean up only their own teaching sessions.

Buffer reads are PostgreSQL-level events. They are not automatically physical storage-device reads because the operating system also caches. Cumulative statistics can lag and observing transactions can retain cached snapshots. Use fresh observations and appropriate clearing of the statistics snapshot when investigating, not arbitrary assumptions about instantaneous counters.

For the agent platform, separate queue delay, worker availability, connection acquisition, lock wait, SQL execution, and external model/tool latency in telemetry. Adding an index cannot fix all of those stages. Correlate run IDs, attempts, application_name, and timestamps without logging credentials or private prompts unnecessarily.

**Exercise:** find the most expensive query by total time and by mean time. Explain why the answers can differ. Open one manual blocking exercise and identify the blocker from an observer session.

**Worked answer:** call frequency changes cumulative cost. A lock-wait diagnosis requires the wait relationship and transaction owner, not only a query plan. Mean duration cannot establish tail latency.

**DoneContract:** build a workload observation with an explicit window and distinguish computation from waiting.

References: [pg_stat_statements](https://www.postgresql.org/docs/17/pgstatstatements.html), [statistics views](https://www.postgresql.org/docs/17/monitoring-stats.html), [locks](https://www.postgresql.org/docs/17/explicit-locking.html).

## Run

```sh
python scripts/course.py bonus 23
```

[Executable lab](../../sql/extras/23_monitoring_and_waits.sql). This bonus includes its own assertions or diagnostic queries. Re-running resets its own teaching schema where one is needed; the monitoring bonus is read-only apart from ordinary statistics collection.
