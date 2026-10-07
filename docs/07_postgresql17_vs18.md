# PostgreSQL 17 baseline and version boundaries

The experiments target PostgreSQL 17 and explicitly reject another major version. The `postgres:17-bookworm` tag selects a major-version image family, not an immutable image. Record the patch version and local image digest with evidence. For stricter reproducibility, set `POSTGRES_IMAGE` in your local `.env` to an official PostgreSQL 17 image pinned by its verified digest; do not copy a fabricated digest from an example.

## B-tree skip scans

PostgreSQL 18 documents B-tree skip scans, which can exploit later-column conditions by performing repeated searches under selected conditions. Therefore, “a multi-column index cannot ever help without its first column” is too absolute. Even on PostgreSQL 17, later-column conditions can be checked in an index and a planner may choose a broader index scan. Distinguish a narrow contiguous navigation range from any possible use of the index.

Skip scans do not change the index's logical ordering. An index ordered by `(project_id, status, created_at)` does not become globally ordered by creation time across several statuses merely because the engine can perform additional searches. Read the selected plan instead of transplanting a slogan between versions.

## Do not upgrade by reusing the same volume

The official image's data-directory/volume conventions differ for PostgreSQL 18 and later versus the PostgreSQL 17 path used in this Compose file. More importantly, a major-version data directory cannot simply be opened by substituting a new server image. Use a planned major upgrade or a dump/restore into a new, separately initialized environment. Preserve the old volume until recovery is verified.

This package does not include an automatic PostgreSQL 18 variant, and changing the image tag alone is not supported. You may create a separate comparison project after adapting its guards, volume layout, and expected behavior. Keep result sets and workload definitions comparable while documenting differences in optimizer capabilities.

Sources: [PG17 multicolumn indexes](https://www.postgresql.org/docs/17/indexes-multicolumn.html), [PG18 multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html), [official image and data paths](https://hub.docker.com/_/postgres), [major-version upgrades](https://www.postgresql.org/docs/17/upgrading.html).
