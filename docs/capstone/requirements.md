# Capstone requirements

## Workload

Projects submit jobs to CPU or GPU pools. Available workers poll for a bounded claim rather than downloading every queued job. A job has a project-scoped idempotency key, priority, availability time, attempt budget, and durable lifecycle history. External execution may take much longer than a database transaction and may fail without a clean shutdown.

## Result and correctness contract

A claim must select eligible queued work for the requested project and pool, acquire ownership atomically, increment the attempt count, create a fresh lease token, and record a claim event. A concurrent claimant must not receive the same live claim. It may skip a locked candidate rather than wait.

Renewal and completion require the current running state, correct worker identifier, correct token, and an unexpired lease. Expiry must be checked while holding the row lock so a blocked operation cannot authorize itself using a stale pre-wait time check. Completion must update state and record its event/outbox message in the same database transaction. A duplicate completion must not apply its effects again.

A bounded reaper must find expired running jobs without blocking behind another owner. It clears expired ownership, applies a bounded retry delay, and either requeues the job or marks it failed when attempts are exhausted. Its event must retain the expired token and prior worker for diagnosis. Failed and completed jobs must not retain active lease fields.

## Index contract

Propose an index matching project/pool equality, queued eligibility, and priority/creation/ID ordering. Explain why `available_at` remains a filter in the supplied index arrangement and why many delayed high-priority jobs could create extra scan work. Propose a measurement rather than claiming the index is optimal for every queue distribution.

A second partial index must organize expiry discovery for running jobs. History should support ordered lookup per job. An outbox uniqueness rule should prevent duplicate records for the same completion event in this simple lifecycle.

## Failure cases to demonstrate

Wrong token, wrong worker, expired lease, duplicate completion, replacement attempt with a new token, completion from the old attempt, retry-budget exhaustion, and overlapping claim transactions. The supplied deterministic assertions inject expired timestamps rather than sleeping. The automated concurrency harness covers actual overlap separately.

## Boundaries

Worker and project arguments are not authentication. The reference implementation assumes a trusted caller; production needs authorization, restricted privileges, or carefully designed RLS/API enforcement. It does not implement external artifact uploads, outbox delivery, cancellation, agent scheduling, heartbeat processes, permanent-error classification, or production monitoring alerts. Those are explicit extension tasks, not hidden claims of implemented functionality.

The delivery contract is not exactly-once external execution. A worker can perform an external effect and then lose connectivity before acknowledging it. Design external idempotency and, where supported, fencing using a monotonic attempt generation. A random lease token rejects stale database operations but is not automatically an ordered fencing token for another system.
