# Capstone: a reliable workflow-runner queue

Turn the course mechanisms into a small database protocol for a CPU/GPU workflow platform. This is a complete **teaching SQL implementation** with executable assertions, not a finished web service, agent runtime, or production deployment.

Read [requirements](requirements.md), propose your own schema and transaction boundaries, then compare [the reference design](reference_design.md). Run:

```sh
python scripts/course.py capstone
python scripts/course.py concurrency-test
```

The first command rebuilds only `capstone`, demonstrates a claim/renew/complete sequence, and runs deterministic invariant checks. The second adds actual overlapping claim transactions alongside the broader concurrency tests. Neither command launches external agents or GPU workloads.

## Files

[Schema](../../sql/capstone/00_schema.sql) defines jobs, history, indexes, and an outbox. [Protocol](../../sql/capstone/01_protocol.sql) implements atomic claim, renewal, completion, and bounded expiry recovery. [Walkthrough](../../sql/capstone/02_walkthrough.sql) shows client calls. [Assertions](../../sql/capstone/03_assertions.sql) verify ownership, expired leases, attempts, duplicates, history, and outbox behavior. [Entry point](../../sql/capstone/run_all.sql) executes them in order.

## DoneContract

Explain why a worker must not hold a transaction during external execution; show two concurrent workers claiming different jobs; reject completion by a stale token; recover an expired attempt without exceeding its budget; and explain why database lease ownership still does not guarantee exactly-once external side effects. Identify the authentication and authorization layer that this demo deliberately does not implement.
