# Source index and provenance

Prepared 7 October 2026. Explanations are original and linked to primary engine documentation. The public syllabus supplied topic alignment; inaccessible premium material was neither reviewed nor reproduced. Exact query plans, timings, and cache behavior must be measured in your environment.

Most references pin PostgreSQL 18 documentation for the course baseline. PostgreSQL 17 multicolumn-index documentation is linked from the version note only to compare older behavior. MySQL documentation is used to distinguish InnoDB storage from PostgreSQL rather than merging the engines into one model. Docker references describe the runtime packaging.

External references require internet access. The lessons and SQL themselves are local. Links are source attribution, not a promise that third-party sites will remain unchanged or available.

## PostgreSQL

- https://www.postgresql.org/docs/18/app-pgdump.html
- https://www.postgresql.org/docs/18/app-pgrestore.html
- https://www.postgresql.org/docs/18/app-psql.html
- https://www.postgresql.org/docs/18/backup.html
- https://www.postgresql.org/docs/18/brin.html
- https://www.postgresql.org/docs/18/btree.html
- https://www.postgresql.org/docs/18/datatype-datetime.html
- https://www.postgresql.org/docs/18/datatype-json.html
- https://www.postgresql.org/docs/18/ddl-constraints.html
- https://www.postgresql.org/docs/18/ddl-partitioning.html
- https://www.postgresql.org/docs/18/ddl-rowsecurity.html
- https://www.postgresql.org/docs/18/ddl-system-columns.html
- https://www.postgresql.org/docs/18/errcodes-appendix.html
- https://www.postgresql.org/docs/18/explicit-locking.html
- https://www.postgresql.org/docs/18/functions-aggregate.html
- https://www.postgresql.org/docs/18/functions-comparison.html
- https://www.postgresql.org/docs/18/functions-comparisons.html
- https://www.postgresql.org/docs/18/functions-datetime.html
- https://www.postgresql.org/docs/18/functions-window.html
- https://www.postgresql.org/docs/18/gin.html
- https://www.postgresql.org/docs/18/indexes-bitmap-scans.html
- https://www.postgresql.org/docs/18/indexes-expressional.html
- https://www.postgresql.org/docs/18/indexes-index-only-scans.html
- https://www.postgresql.org/docs/18/indexes-multicolumn.html
- https://www.postgresql.org/docs/18/indexes-opclass.html
- https://www.postgresql.org/docs/18/indexes-ordering.html
- https://www.postgresql.org/docs/18/indexes-partial.html
- https://www.postgresql.org/docs/18/indexes-types.html
- https://www.postgresql.org/docs/18/indexes.html
- https://www.postgresql.org/docs/18/monitoring-stats.html
- https://www.postgresql.org/docs/18/mvcc-intro.html
- https://www.postgresql.org/docs/18/mvcc-serialization-failure-handling.html
- https://www.postgresql.org/docs/18/pageinspect.html
- https://www.postgresql.org/docs/18/pgstatstatements.html
- https://www.postgresql.org/docs/18/pgtrgm.html
- https://www.postgresql.org/docs/18/pgvisibility.html
- https://www.postgresql.org/docs/18/planner-stats.html
- https://www.postgresql.org/docs/18/progress-reporting.html
- https://www.postgresql.org/docs/18/protocol-flow.html
- https://www.postgresql.org/docs/18/queries-limit.html
- https://www.postgresql.org/docs/18/queries-table-expressions.html
- https://www.postgresql.org/docs/18/queries-with.html
- https://www.postgresql.org/docs/18/queries.html
- https://www.postgresql.org/docs/18/role-attributes.html
- https://www.postgresql.org/docs/18/routine-vacuuming.html
- https://www.postgresql.org/docs/18/runtime-config-query.html
- https://www.postgresql.org/docs/18/runtime-config-resource.html
- https://www.postgresql.org/docs/18/runtime-config-wal.html
- https://www.postgresql.org/docs/18/sql-altertable.html
- https://www.postgresql.org/docs/18/sql-analyze.html
- https://www.postgresql.org/docs/18/sql-cluster.html
- https://www.postgresql.org/docs/18/sql-createindex.html
- https://www.postgresql.org/docs/18/sql-createpolicy.html
- https://www.postgresql.org/docs/18/sql-createstatistics.html
- https://www.postgresql.org/docs/18/sql-createtable.html
- https://www.postgresql.org/docs/18/sql-dropindex.html
- https://www.postgresql.org/docs/18/sql-explain.html
- https://www.postgresql.org/docs/18/sql-prepare.html
- https://www.postgresql.org/docs/18/sql-select.html
- https://www.postgresql.org/docs/18/sql-set.html
- https://www.postgresql.org/docs/18/storage-hot.html
- https://www.postgresql.org/docs/18/storage-page-layout.html
- https://www.postgresql.org/docs/18/storage-vm.html
- https://www.postgresql.org/docs/18/transaction-iso.html
- https://www.postgresql.org/docs/18/tutorial-transactions.html
- https://www.postgresql.org/docs/18/tutorial-window.html
- https://www.postgresql.org/docs/18/upgrading.html
- https://www.postgresql.org/docs/18/using-explain.html
- https://www.postgresql.org/docs/18/wal-internals.html
- https://www.postgresql.org/docs/18/wal-intro.html
- https://www.postgresql.org/docs/18/wal-reliability.html
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
