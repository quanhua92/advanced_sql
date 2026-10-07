# Reference design and operational reasoning

## State and authority

```text
queued --claim--> running --valid completion--> succeeded
                    |
                    +--expired lease, attempts remain--> queued after backoff
                    |
                    +--expired lease, exhausted budget--> failed
```

`attempt` increases at claim time. Each claim receives a random UUID token and a worker identifier. The token is the identity of this attempt's database authority; it is not the identity of the durable job. A check constraint ties the running state to the presence of all three lease fields and disallows partial ownership fields in other states.

The unique `(project_id, idempotency_key)` constraint allows a submission API to implement deduplicated requests. The demo schema supplies the uniqueness rule, not a complete API policy for returning prior results or rejecting a reused key with a different prompt.

## Claim transaction

`claim_one(project, pool, worker, lease_seconds)` finds one eligible row with `FOR UPDATE SKIP LOCKED`, updates it to running, increments the attempt, sets ownership, and inserts an event. Call it in a short autocommit transaction, or explicitly commit immediately after receiving the claim. Keep external execution outside the transaction.

The partial claim index is keyed by `(project_id, pool, priority DESC, created_at, id)` for queued jobs. It aligns tenant/pool equality and stable priority ordering. `available_at <= clock_timestamp()` and remaining attempts are eligibility checks, not a promise of a one-entry lookup. Workloads dominated by delayed high-priority jobs may need another queue organization. `SKIP LOCKED` favors progress, not strict fairness or a globally consistent queue view.

## Renew and complete under a lock

The functions first acquire the target row lock, then inspect the current state, worker, token, and wall-clock expiry. This ordering matters: checking time before waiting for a lock could accept authority that expired during the wait. The ownership check is performed within a short transaction; it is not a promise about a caller deliberately holding that transaction open indefinitely afterward.

`renew` changes the expiry and records an event. `complete` transitions the row, clears lease fields, stores the result, records completion history, and inserts an outbox message. These effects commit or roll back together. A false return means the caller no longer has acceptable authority; it should not silently retry completion with a fabricated new token.

At Read Committed, row locks serialize changes to a job. Other isolation levels can introduce serialization errors that a production caller must handle. Every retry policy must preserve the job/attempt authority checks rather than assuming the original claim remains valid forever.

## Expiry recovery

The reaper locks a bounded set of expired jobs using `SKIP LOCKED`. Each becomes queued with bounded linear backoff or failed if the attempt budget has been consumed. History records the expired claim before its active ownership fields are cleared. The reference backoff is intentionally simple; production may add jitter, permanent-error handling, cancellation, or task-specific budgets.

A requeued job receives a fresh token only when a worker claims it again. An older worker can still physically be running. Its stale token prevents it from completing the database job, but it does not stop code execution or revoke an external API call already made.

## Transactional outbox and external effects

The outbox makes “state changed but completion event was never recorded” avoidable inside this transaction. It does not deliver the event. A separate relay would read pending records, publish, and mark delivery. A crash between publish and acknowledgement can duplicate delivery, so consumers still need idempotency. Delivery code is not included and is not claimed as tested.

External artifacts should be named or validated using job and attempt identity. An external system supporting monotonic fencing can reject effects from an older attempt generation after accepting a newer one. Merely generating a UUID does not impose that ordering. For expensive inference, exact-once execution may be infeasible; explicit duplicate-cost budgets and idempotent finalization are more meaningful targets.

## Evidence in the package

The assertion script verifies wrong-token/worker rejection, renewal, successful completion, duplicate rejection, expired authority, replacement tokens, stale completion, exhausted attempts, and expected outbox counts. Those assertions are sequential tests with controlled timestamp fixtures. The separate multi-connection harness holds the first claim transaction open while a second worker claims another job, establishing actual overlap for that case.

Neither suite is a proof over every interleaving. Additional tests could delay a renewal behind a row lock until its lease expires, crash a client between execution and acknowledgement, or model sustained backpressure. Before deploying, add authorization tests, adversarial schedules, external idempotency tests, rate limits, operational monitoring, and restore drills.

Sources: [Row locking and deadlocks](https://www.postgresql.org/docs/18/explicit-locking.html), [SELECT SKIP LOCKED](https://www.postgresql.org/docs/18/sql-select.html), [isolation](https://www.postgresql.org/docs/18/transaction-iso.html), [partial indexes](https://www.postgresql.org/docs/18/indexes-partial.html). The state machine and lease protocol are original design choices for this exercise.
