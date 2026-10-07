# The evidence-driven lab method

## Start with a result contract

Write the exact intended result before tuning: tenant scope, handling of missing values, ordering tie-breaker, and whether pages must reflect one stable snapshot. “Latest 20 runs” is underspecified without a time field and tie-breaker. A faster query with different timezone boundaries or join multiplicity is not an optimization.

Then write the access-path hypothesis. For example: equality on project and status locates one region of an ordered index, allowing a bounded traversal in descending time order. This predicts work removed, not an exact execution time.

## Read plans in layers

Use `EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)`. Inspect result rows first, then estimates versus actual rows, loops, predicates, scan organization, sort/hash work, and buffer activity. Costs are planner units, not milliseconds. Actual per-node row counts and time may be averaged over loops; a cheap repeated inner probe can accumulate substantial work. Parent instrumentation includes work underneath it, so summing parent and child values can double-count.

Index eligibility is not plan selection. Diagnostic `enable_*` switches let you inspect alternatives; they do not prove that forcing the plan is a sensible production fix. Many switches discourage a path rather than making every occurrence impossible.

## Preserve semantics and isolate variables

Compare result sets using symmetric `EXCEPT` or counts plus a stable key contract. Remember that plain `EXCEPT` removes duplicates; use `EXCEPT ALL` when multiplicity matters. Equality of counts alone does not establish equality of rows. For pagination, compare IDs under the same snapshot and ordering, not two pages observed around concurrent writes.

Change one index, predicate, or planner setting at a time. Keep versions, seed size, and relevant session settings in the experiment record. Do not compare a fresh heap to a heavily updated one without noting the visibility and layout differences.

## Treat timing as a distribution

Repeat representative reads. Record cache state honestly as “not controlled” unless you actually control it. The first execution after loading or indexing is not automatically cold. A shared-buffer read can be satisfied by the operating-system cache; it is not synonymous with a device read. Avoid clearing machine caches on a workstation simply to manufacture a benchmark.

Record total execution time, buffer hits/reads, returned rows, discarded rows, sort spills, hash batches, and lock waits where relevant. A fast warm-cache plan can still scale poorly under concurrency. A query with more buffer hits may do more work despite zero reported reads.

## Mutation experiments are real operations

`EXPLAIN ANALYZE` executes writes. A surrounding transaction and rollback can prevent committed row changes, but rollback does not erase all physical work, WAL generation, sequence advances, or cache effects. `VACUUM`, `CREATE INDEX CONCURRENTLY`, and certain maintenance operations cannot be bundled into one transaction. Only use this disposable database.

## Distinguish kinds of tests

A semantic assertion can require that two pages contain the same IDs. A runtime observation can report that a sort spilled on one machine. A structural expectation can say an index makes an ordered lookup possible. A concurrency test requires overlapping transactions with a specified schedule. A recovery test requires an actual failure event and independently known durable state. Do not promote one kind of evidence into a stronger claim.

Sources: [EXPLAIN](https://www.postgresql.org/docs/17/using-explain.html), [EXPLAIN command](https://www.postgresql.org/docs/17/sql-explain.html), [monitoring statistics](https://www.postgresql.org/docs/17/monitoring-stats.html).
