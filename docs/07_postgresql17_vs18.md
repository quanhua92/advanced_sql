# PostgreSQL 18 baseline and version boundaries

The executable course targets PostgreSQL 18 and rejects another major version. The `postgres:18-bookworm` tag follows PostgreSQL 18 patch releases rather than pinning one immutable build. Record `SELECT version()` and the local image digest with evidence. To pin an exact image, set `POSTGRES_IMAGE` in `.env` to a verified PostgreSQL 18 image reference; keep the major version at 18 because the data-volume layout and SQL guard are configured for it.

## B-tree skip scans

PostgreSQL 18 can use B-tree skip scans when useful conditions constrain later index columns while earlier columns lack equality conditions. It performs repeated searches across values of the unconstrained key columns when the planner estimates that skipping groups costs less than scanning them. Low distinct counts in skipped columns make this more promising; the optimizer may choose a sequential scan or another index when that costs less.

The feature does not change the index's logical ordering. An index ordered by `(project_id, status, created_at)` does not provide one global creation-time order across several project or status groups. Inspect `EXPLAIN (ANALYZE, BUFFERS)` and its `Index Searches` count to see how PostgreSQL traversed an index. The count can also reflect `IN` values, repeated join probes, or other searches, so explain it in query context.

PostgreSQL 17 and earlier can still scan a multicolumn index when only a later column is constrained, but cannot use the PostgreSQL 18 skip-scan optimization to avoid irrelevant key groups. Use the PG17 references only when comparing older behavior; the course examples and expected semantics target PG18.

## Separate major-version data

The official PostgreSQL 18 image stores `PGDATA` under `/var/lib/postgresql/18/docker` and uses `/var/lib/postgresql` as its volume mount. This course names its volume `postgres18_data`, keeping it separate from an existing PG17 volume. A major-version data directory must not be opened by substituting a different server image. Migrate deliberately with a tested dump/restore or `pg_upgrade` process, and keep the old volume until the new cluster is verified.

The original learning-pack files under `legacy/` remain preserved as supplied. Their map describes the earlier PG17 plan; the legacy SQL lab is also runnable against PG18, while all maintained course chapters and executable checks target PG18.

Sources: [PG17 multicolumn indexes](https://www.postgresql.org/docs/17/indexes-multicolumn.html), [PG18 multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html), [PG18 EXPLAIN](https://www.postgresql.org/docs/18/using-explain.html), [official image and data paths](https://hub.docker.com/_/postgres), [PG18 major-version upgrades](https://www.postgresql.org/docs/18/upgrading.html).
