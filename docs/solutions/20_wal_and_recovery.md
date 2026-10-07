# 20. WAL And Recovery: worked answers

[Return to lesson](../lessons/20_wal_and_recovery.md)


## Worked answers

The required WAL can be made durable before data pages are written. Recovery can use the log to reconstruct appropriate changes. Commit semantics depend on configuration and storage behavior; they are not equivalent to a full immediate data-file rewrite.

Unlogged data does not have ordinary logged-table crash durability or replication behavior. It can be truncated after an unclean shutdown. Use it only where the application can safely rebuild or lose that data.

Recovery from interruption and recovery from losing or corrupting the original data are different scenarios. A backup is useful only with a tested restore procedure, and a simple logical dump is not a complete point-in-time-recovery system.

## Expected evidence

The marker is committed before the optional manual crash. Verify its persistence afterward and inspect the server logs. Report the exact injected failure; do not claim universal power-loss resilience from one container test.

**DoneContract:** explain WAL, flush, commit, checkpoint, crash recovery, and backup as distinct mechanisms, then connect database durability to the remaining distributed-workflow failure cases.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 20
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [wal intro](https://www.postgresql.org/docs/17/wal-intro.html)
- [wal internals](https://www.postgresql.org/docs/17/wal-internals.html)
- [runtime config wal](https://www.postgresql.org/docs/17/runtime-config-wal.html)
- [sql createtable](https://www.postgresql.org/docs/17/sql-createtable.html)
- [backup](https://www.postgresql.org/docs/17/backup.html)
