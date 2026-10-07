# 25. Make schema changes without confusing “concurrent” with “free”

A useful index in a classroom can still be dangerous to add carelessly to a busy table. Index creation consumes resources, interacts with locks and old transactions, and can leave operational work when interrupted. The appropriate migration plan includes validation and rollback, not just a CREATE INDEX statement.

Ordinary index creation and concurrent creation have different locking and scan behavior. `CREATE INDEX CONCURRENTLY` allows ordinary writes to continue through much of the process but takes longer work paths and can wait for transactions. It must run outside an explicit transaction block. That includes migration frameworks that automatically wrap a file in one transaction.

The lab builds a concurrent index on an isolated copy, inspects `indisvalid` and `indisready`, then removes only that demonstration index concurrently. A failed concurrent build can leave an invalid index requiring diagnosis and cleanup. `IF NOT EXISTS` alone does not prove that an existing object has the intended definition or valid state.

Before production execution, record the exact target, expected lock behavior, disk headroom, index definition, competing long transactions, observation query, timeout policy, and recovery action. Do not blindly retry a name-based migration while ignoring a partially created object. Constraint-backed indexes have additional dependencies that make arbitrary dropping unsafe.

The constraint example separates adding a CHECK constraint with NOT VALID from validating existing rows. Such staging can help manage the work and locking profile, but NOT VALID does not mean future writes are allowed to violate the new rule. Constraint type and statement-specific lock behavior still matter.

A safe migration also preserves application compatibility while old and new code versions coexist. An index addition is often simpler than a column rewrite or changed null policy, but even it can consume enough CPU and I/O to affect service latency. Measure workload impact while observing build progress.

The lab's short lock timeout is a teaching guard. It can cause an intentional migration attempt to fail rather than wait indefinitely. In production, choose a policy based on the operation and service objectives; do not copy the classroom value without understanding retries and partial state.

**Exercise:** write the recovery steps for an interrupted concurrent index build. Identify why an automatic “already exists, skip” response is insufficient.

**Worked answer:** inspect definition and validity, determine whether the intended build is still active, then deliberately clean up or resume through an approved migration path. Avoid dropping unrelated or constraint-enforcing structures. Validate the final plan and workload impact after successful creation.

**DoneContract:** provide a migration runbook with lock, resource, validation, and rollback considerations, not just the target DDL.

References: [CREATE INDEX](https://www.postgresql.org/docs/18/sql-createindex.html), [ALTER TABLE](https://www.postgresql.org/docs/18/sql-altertable.html), [progress reporting](https://www.postgresql.org/docs/18/progress-reporting.html), [DROP INDEX](https://www.postgresql.org/docs/18/sql-dropindex.html).

## Run

```sh
python scripts/course.py bonus 25
```

[Executable lab](../../sql/extras/25_safe_schema_changes.sql). This bonus includes its own assertions or diagnostic queries. Re-running resets its own teaching schema where one is needed; the monitoring bonus is read-only apart from ordinary statistics collection.
