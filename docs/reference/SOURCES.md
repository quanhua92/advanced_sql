# Source index and provenance

Prepared 7 October 2026. Explanations are original and linked to primary engine documentation. The public syllabus supplied topic alignment; inaccessible premium material was neither reviewed nor reproduced. Exact query plans, timings, and cache behavior must be measured in your environment.

Most references intentionally pin PostgreSQL 17 documentation. The PostgreSQL 18 multicolumn-index reference is included only for version comparison. MySQL documentation is used to distinguish InnoDB storage from PostgreSQL rather than merging the engines into one model. Docker references describe the runtime packaging.

External references require internet access. The lessons and SQL themselves are local. Links are source attribution, not a promise that third-party sites will remain unchanged or available.

## PostgreSQL

- https://www.postgresql.org/docs/17/app-pgdump.html
- https://www.postgresql.org/docs/17/app-pgrestore.html
- https://www.postgresql.org/docs/17/app-psql.html
- https://www.postgresql.org/docs/17/backup.html
- https://www.postgresql.org/docs/17/brin.html
- https://www.postgresql.org/docs/17/btree.html
- https://www.postgresql.org/docs/17/datatype-datetime.html
- https://www.postgresql.org/docs/17/datatype-json.html
- https://www.postgresql.org/docs/17/ddl-constraints.html
- https://www.postgresql.org/docs/17/ddl-partitioning.html
- https://www.postgresql.org/docs/17/ddl-rowsecurity.html
- https://www.postgresql.org/docs/17/ddl-system-columns.html
- https://www.postgresql.org/docs/17/errcodes-appendix.html
- https://www.postgresql.org/docs/17/explicit-locking.html
- https://www.postgresql.org/docs/17/functions-aggregate.html
- https://www.postgresql.org/docs/17/functions-comparison.html
- https://www.postgresql.org/docs/17/functions-comparisons.html
- https://www.postgresql.org/docs/17/functions-datetime.html
- https://www.postgresql.org/docs/17/functions-window.html
- https://www.postgresql.org/docs/17/gin.html
- https://www.postgresql.org/docs/17/indexes-bitmap-scans.html
- https://www.postgresql.org/docs/17/indexes-expressional.html
- https://www.postgresql.org/docs/17/indexes-index-only-scans.html
- https://www.postgresql.org/docs/17/indexes-multicolumn.html
- https://www.postgresql.org/docs/17/indexes-opclass.html
- https://www.postgresql.org/docs/17/indexes-ordering.html
- https://www.postgresql.org/docs/17/indexes-partial.html
- https://www.postgresql.org/docs/17/indexes-types.html
- https://www.postgresql.org/docs/17/indexes.html
- https://www.postgresql.org/docs/17/monitoring-stats.html
- https://www.postgresql.org/docs/17/mvcc-intro.html
- https://www.postgresql.org/docs/17/mvcc-serialization-failure-handling.html
- https://www.postgresql.org/docs/17/pageinspect.html
- https://www.postgresql.org/docs/17/pgstatstatements.html
- https://www.postgresql.org/docs/17/pgtrgm.html
- https://www.postgresql.org/docs/17/pgvisibility.html
- https://www.postgresql.org/docs/17/planner-stats.html
- https://www.postgresql.org/docs/17/progress-reporting.html
- https://www.postgresql.org/docs/17/protocol-flow.html
- https://www.postgresql.org/docs/17/queries-limit.html
- https://www.postgresql.org/docs/17/queries-table-expressions.html
- https://www.postgresql.org/docs/17/queries-with.html
- https://www.postgresql.org/docs/17/queries.html
- https://www.postgresql.org/docs/17/role-attributes.html
- https://www.postgresql.org/docs/17/routine-vacuuming.html
- https://www.postgresql.org/docs/17/runtime-config-query.html
- https://www.postgresql.org/docs/17/runtime-config-resource.html
- https://www.postgresql.org/docs/17/runtime-config-wal.html
- https://www.postgresql.org/docs/17/sql-altertable.html
- https://www.postgresql.org/docs/17/sql-analyze.html
- https://www.postgresql.org/docs/17/sql-cluster.html
- https://www.postgresql.org/docs/17/sql-createindex.html
- https://www.postgresql.org/docs/17/sql-createpolicy.html
- https://www.postgresql.org/docs/17/sql-createstatistics.html
- https://www.postgresql.org/docs/17/sql-createtable.html
- https://www.postgresql.org/docs/17/sql-dropindex.html
- https://www.postgresql.org/docs/17/sql-explain.html
- https://www.postgresql.org/docs/17/sql-prepare.html
- https://www.postgresql.org/docs/17/sql-select.html
- https://www.postgresql.org/docs/17/sql-set.html
- https://www.postgresql.org/docs/17/storage-hot.html
- https://www.postgresql.org/docs/17/storage-page-layout.html
- https://www.postgresql.org/docs/17/storage-vm.html
- https://www.postgresql.org/docs/17/transaction-iso.html
- https://www.postgresql.org/docs/17/tutorial-transactions.html
- https://www.postgresql.org/docs/17/tutorial-window.html
- https://www.postgresql.org/docs/17/upgrading.html
- https://www.postgresql.org/docs/17/using-explain.html
- https://www.postgresql.org/docs/17/wal-internals.html
- https://www.postgresql.org/docs/17/wal-intro.html
- https://www.postgresql.org/docs/17/wal-reliability.html
- https://www.postgresql.org/docs/18/indexes-multicolumn.html

## Docker

- https://docs.docker.com/compose/how-tos/startup-order/
- https://docs.docker.com/reference/cli/docker/compose/up/
- https://hub.docker.com/_/postgres

## MySQL / InnoDB

- https://dev.mysql.com/doc/refman/8.4/en/innodb-index-types.html

## Public syllabus

- https://sydexa.com/courses/advanced-sql
- https://sydexa.com/courses/advanced-sql/lessons/index-and-btree
- https://sydexa.com/courses/advanced-sql/lessons/index-in-practice
