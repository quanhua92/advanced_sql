# 18. Locks And Worker Claims: worked answers

[Return to lesson](../lessons/18_locks_and_worker_claims.md)


## Worked answers

Separate selection and update leave a race in which two workers choose the same job. Locking and updating inside one short transaction establish a claim. External work should happen after commit so its duration does not hold database locks and snapshots.

SKIP LOCKED can bypass currently locked rows, so the result is not a complete consistent view and strict priority or fairness is not guaranteed. It also does not implement lease recovery or exactly-once external execution.

Inspect the wait cycle and SQLSTATE 40P01, then rollback and retry the whole transaction under an appropriate bounded policy. Consistent lock order helps prevent the demonstrated cycle, but applications still need failure handling.

## Capstone connection

The current lease token and attempt number guard acknowledgement. Expiry permits recovery. External effects require their own idempotency or fencing contract. Keep these responsibilities separate in both schema and documentation.

**DoneContract:** show two independent claimers choosing distinct available rows, diagnose a real wait cycle, and explain how worker failure and stale completion are handled.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 18
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [explicit locking](https://www.postgresql.org/docs/17/explicit-locking.html)
- [sql select](https://www.postgresql.org/docs/17/sql-select.html)
- [monitoring stats](https://www.postgresql.org/docs/17/monitoring-stats.html)
- [errcodes appendix](https://www.postgresql.org/docs/17/errcodes-appendix.html)
