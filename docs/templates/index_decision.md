# Index decision record

**Workload:** exact query patterns and representative parameter distributions.

**Correctness contract:** tenant boundaries, NULL semantics, ordering, pagination, and transaction needs.

**Candidate:** key columns in order, predicates, INCLUDE payload, index method, and relevant operator classes.

**Mechanism:** search range, ordering, early termination, coverage, or organized heap access.

**Evidence:** plans and semantic checks before/after, representative timings, buffers, index size, mutation measurements.

**Costs:** write amplification, HOT eligibility, memory/storage, build/maintenance time, overlapping indexes, and deployment locks.

**Alternatives:** rewrite, statistics, another index arrangement, materialized summary, partitioning, or leaving the query unchanged.

**Decision:** retain, revise, or reject; explain the workload assumptions and a review trigger.
