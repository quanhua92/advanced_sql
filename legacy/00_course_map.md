# PostgreSQL Performance and Internals: Learning Map

Prepared 7 October 2026. Original teaching plan and exercises, aligned with the publicly visible topic coverage of Sydexa's advanced-SQL course. This is not a transcription or reproduction of its premium lessons.

## What was verified

The course page advertises 21 intermediate-level lessons and a price of 399,000 VND. Its landing page reports approximately 12 hours, while the course catalog reports 24 hours. These are inconsistent advertised study durations, not verified video runtimes.

All 21 lesson pages were opened. The first two exposed substantial instructional text; the other 19 exposed titles and short descriptions with a premium-content gate. The public samples also contain interactive components, quizzes, and an advertised paid PostgreSQL 17 sandbox. The sandbox was not tested, and video runtimes were not independently established.

Sources:
- Course: https://sydexa.com/courses/advanced-sql
- Catalog: https://sydexa.com/courses
- Public first lesson and navigation: https://sydexa.com/courses/advanced-sql/lessons/index-and-btree
- Public second lesson: https://sydexa.com/courses/advanced-sql/lessons/index-in-practice

## Teaching approach

Use PostgreSQL 17 as a reproducible baseline matching the advertised sandbox. Explicitly distinguish PostgreSQL 18 behavior where relevant, especially B-tree skip scans. Distinguish PostgreSQL heap storage from MySQL InnoDB clustering rather than combining them into one fictional database engine.

The running example is an agent/workflow platform with projects, workflows, runners, runs, and an append-oriented event history. These are teaching entities, not an assertion about the user's exact production schema.

Each lesson follows: practical question, prediction, mechanism, experiment, counterexample, application decision.

A lesson's DoneContract is not remembering a rule. It is explaining an unfamiliar case, predicting the relevant database work, testing that prediction, and stating the cost or correctness tradeoff.

## All 21 topic areas and proposed learning outcomes

The topics below paraphrase the visible syllabus. The outcomes and exercises are original proposals, not claims about the contents of inaccessible lessons.

| Lesson | Topic area | Evidence of understanding |
|---|---|---|
| 1 | Pages and tree-based access | Trace a key lookup through index pages to a heap tuple; distinguish logical visits from device reads. |
| 2 | Index read/write economics | Compare index sizes and write costs against the queries that benefit. |
| 3 | Equality and plan inspection | Read estimates, actual rows, loops, costs, and execution measurements without confusing them. |
| 4 | Multi-column index design | Explain lexicographic ordering, leading equalities, ranges, and why another workload can require another order. |
| 5 | Choosing an access strategy | Compare sequential, ordinary index, and bitmap access on the same data. |
| 6 | Searchable expressions | Rewrite a time predicate without changing timezone semantics; compare an expression index. |
| 7 | Parameters and plan reuse | Separate safe parameter binding from generic/custom planning decisions under skew. |
| 8 | Ranges, text prefixes, and index combination | Explain prefix versus substring access and when bitmap combination helps or loses ordering. |
| 9 | Partial indexes and three-valued logic | Design a queue-specific index and reason correctly about NULL, NOT IN, and NOT EXISTS. |
| 10 | Indexed nested-loop execution | Explain inner-probe repetition and distinguish a database join from application N+1 queries. |
| 11 | Hash and merge execution | Identify build/probe work, sorting requirements, memory pressure, and row-estimate errors. |
| 12 | Covering and index-only access | Separate navigation keys from INCLUDE payload and verify Heap Fetches under MVCC. |
| 13 | Heap versus clustered organization | Compare PostgreSQL and InnoDB retrieval paths and primary-key tradeoffs. |
| 14 | Ordering and aggregation | Explain when ordering avoids a sort and when hashing or streaming fits an aggregate. |
| 15 | Bounded results and pagination | Build stable keyset pagination and top-N-per-group queries; distinguish ROWS and RANGE frames. |
| 16 | Mutations and index maintenance | Explain HOT eligibility, dead versions, page splits, and maintenance costs. |
| 17 | Transaction isolation | Reproduce a concurrency anomaly and select a correctness mechanism, including retries where required. |
| 18 | Locks and deadlocks | Diagnose a wait chain, order locks consistently, and design short worker-claim transactions. |
| 19 | Snapshots and version retention | Explain why an old snapshot can obstruct cleanup and why ordinary reads need not block writes. |
| 20 | Durable commits and recovery | Distinguish WAL flushing, data-page writes, checkpoints, crash recovery, and backups. |
| 21 | Partitioning and pruning | Design time-based event retention; demonstrate which partitions a query can actually exclude. |

## Additions for production PostgreSQL

These are supplements to the advertised topic map, not claims that the paid course excludes them.

**Statistics and skew:** inspect estimated versus actual cardinalities, statistics freshness, and correlated columns. A logically applicable index does not make a bad estimate disappear.

**Operational evidence:** use query-level and activity statistics to distinguish query execution from lock waits, pooling delays, and application latency.

**Safe changes:** review concurrent index creation, invalid-index cleanup, lock behavior, and migration transaction boundaries before changing a live database.

**Workload-specific index families:** introduce GIN for appropriate JSONB/search workloads and BRIN for physically correlated large histories. Not every PostgreSQL index is a B-tree.

**Runner-queue correctness:** use atomic claims and short transactions, then add leases, ownership checks, and idempotent effects. SKIP LOCKED is an access/locking primitive, not an exactly-once execution protocol.

## Qualifications that matter

Tree height counts navigation levels, not necessarily physical disk reads. PostgreSQL and the operating system both cache data.

An Index Only Scan can still perform heap fetches for visibility checks. Covering every selected value is necessary in the ordinary case but not sufficient to guarantee zero heap access.

There is no fixed row-match percentage at which PostgreSQL must switch to a sequential scan. Estimated pages, correlation, caching assumptions, CPU work, ordering, and LIMIT all matter.

HOT updates can avoid new entries in ordinary indexes when eligibility conditions hold. PostgreSQL deletion also leaves cleanup work for later. Thus one universal N+1-writes formula is not an accurate model of every mutation.

PostgreSQL's primary-key index does not make the heap an InnoDB-style clustered table. PostgreSQL CLUSTER is a reorganization operation whose order is not continuously maintained by later writes.

## Original numerical thought experiment

Assume a hypothetical table has 2,000,000 rows and 80 rows per heap page: 25,000 heap pages.

Assume an index has 400 leaf entries per leaf page and internal fanout 250. It needs approximately 5,000 leaf pages, 20 internal pages, and one root. A point lookup follows three index levels, then may visit a heap page. These capacities are chosen assumptions, not measured PostgreSQL page occupancies.

Now assume each row independently matches a predicate with probability 1%. A page with 80 rows contains at least one match with probability:

`1 - (1 - 0.01)^80 = approximately 55.25%`.

This is why a small fraction of rows need not correspond to a small fraction of heap pages. It does not prove that an index loses: cache state, bitmap access, ordering, covering, and execution overhead still matter.

## Starter lab

Open `01_index_lab.sql`. Use a disposable database and execute sections individually with autocommit. The dataset is synthetic, contains 500,000 rows, and is not the provider's dataset. The script was not executed against a PostgreSQL server during preparation.

The lab compares the same dashboard query before indexing, after a composite index, and after a partial index. It also compares rare/common status predicates and finishes with a changed-workload prediction exercise. Record actual plans instead of assuming a promised speedup.

## Primary technical references

- Page layout: https://www.postgresql.org/docs/17/storage-page-layout.html
- B-tree implementation: https://www.postgresql.org/docs/17/btree.html
- Index families: https://www.postgresql.org/docs/17/indexes-types.html
- Reading plans: https://www.postgresql.org/docs/17/using-explain.html
- EXPLAIN semantics: https://www.postgresql.org/docs/17/sql-explain.html
- Planner cost settings: https://www.postgresql.org/docs/17/runtime-config-query.html
- Planner statistics: https://www.postgresql.org/docs/17/planner-stats.html
- Composite indexes, version 17: https://www.postgresql.org/docs/17/indexes-multicolumn.html
- Composite indexes and skip scans, version 18: https://www.postgresql.org/docs/18/indexes-multicolumn.html
- Index ordering: https://www.postgresql.org/docs/17/indexes-ordering.html
- Bitmap combinations: https://www.postgresql.org/docs/17/indexes-bitmap-scans.html
- Expression indexes: https://www.postgresql.org/docs/17/indexes-expressional.html
- Partial indexes: https://www.postgresql.org/docs/17/indexes-partial.html
- Covering/index-only access: https://www.postgresql.org/docs/17/indexes-index-only-scans.html
- HOT updates: https://www.postgresql.org/docs/17/storage-hot.html
- Vacuum: https://www.postgresql.org/docs/17/routine-vacuuming.html
- PostgreSQL CLUSTER: https://www.postgresql.org/docs/17/sql-cluster.html
- InnoDB clustered storage: https://dev.mysql.com/doc/refman/8.4/en/innodb-index-types.html
- Prepared plans: https://www.postgresql.org/docs/17/sql-prepare.html
- Isolation: https://www.postgresql.org/docs/17/transaction-iso.html
- Locks: https://www.postgresql.org/docs/17/explicit-locking.html
- MVCC introduction: https://www.postgresql.org/docs/17/mvcc-intro.html
- SELECT locking clauses: https://www.postgresql.org/docs/17/sql-select.html
- WAL: https://www.postgresql.org/docs/17/wal-intro.html
- WAL internals: https://www.postgresql.org/docs/17/wal-internals.html
- Partitioning: https://www.postgresql.org/docs/17/ddl-partitioning.html
- Monitoring and operating-system cache qualification: https://www.postgresql.org/docs/17/monitoring-stats.html
