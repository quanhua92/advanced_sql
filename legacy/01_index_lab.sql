/*
Original PostgreSQL index lab: workflow-run history
Target: PostgreSQL 17; also suitable for comparison on PostgreSQL 18.

Use a DISPOSABLE database. Run sections individually with autocommit enabled.
VACUUM cannot run inside a transaction block. In psql, do not use --single-transaction.
The script deliberately fails if sql_course_lab already exists, rather than
silently overwriting existing work. It does not touch application schemas.

These queries were prepared against the documented PostgreSQL interfaces, but
were NOT executed against a PostgreSQL server while preparing this learning pack.
Expected observations below are hypotheses, not measured benchmark results.

For each experiment, record the plan, estimated and actual rows, loops, buffer
activity, sorting, and repeated execution times. Do not interpret planner cost as
milliseconds, sum inclusive parent/child buffer counts, or equate shared reads
with physical storage-device reads.
*/

-- SECTION A: A fresh, isolated dataset. The only initial index is the primary key.
CREATE SCHEMA sql_course_lab;

CREATE TABLE sql_course_lab.runs (
    id          bigint PRIMARY KEY,
    project_id  integer NOT NULL,
    status      text NOT NULL CHECK (status IN ('failed', 'running', 'succeeded')),
    created_at  timestamptz NOT NULL,
    duration_ms integer NOT NULL CHECK (duration_ms >= 0),
    payload     text NOT NULL
);

-- Project allocation is independent of the status formula. Using the same
-- modulo expression for both would accidentally correlate tenants and status.
SELECT setseed(0.42);

INSERT INTO sql_course_lab.runs
    (id, project_id, status, created_at, duration_ms, payload)
SELECT
    i,
    1 + floor(random() * 100)::integer,
    CASE
        WHEN i % 100 = 0 THEN 'failed'
        WHEN i % 10 = 0 THEN 'running'
        ELSE 'succeeded'
    END,
    TIMESTAMPTZ '2026-01-01 00:00:00+00' + i * INTERVAL '1 second',
    1 + (i % 10000),
    repeat(md5(i::text), 4)
FROM generate_series(1, 500000) AS g(i);

-- Run this as its own statement, outside an explicit transaction.
VACUUM (ANALYZE) sql_course_lab.runs;

SELECT version();
SHOW block_size;
SHOW work_mem;
SHOW random_page_cost;
SHOW effective_cache_size;

SELECT status, count(*) AS rows
FROM sql_course_lab.runs
GROUP BY status
ORDER BY status;

SELECT project_id, count(*) AS failed_runs
FROM sql_course_lab.runs
WHERE status = 'failed' AND project_id = 42
GROUP BY project_id;

-- SECTION B: Baseline. Predict the scan and sorting work before running.
-- Repeat this EXPLAIN at least twice; do not treat its first execution as a
-- controlled cold-cache benchmark. Dataset loading and VACUUM already used cache.
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT id, created_at, duration_ms
FROM sql_course_lab.runs
WHERE project_id = 42 AND status = 'failed'
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- SECTION C: Supply an access path aligned with equality filters and ordering.
-- duration_ms is deliberately NOT covered: an ordinary Index Scan still needs
-- heap access to retrieve that column.
CREATE INDEX runs_dashboard_idx
ON sql_course_lab.runs
    (project_id, status, created_at DESC, id DESC);

EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT id, created_at, duration_ms
FROM sql_course_lab.runs
WHERE project_id = 42 AND status = 'failed'
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- Prediction: the new index makes an ordered, bounded lookup possible. Inspect
-- whether the planner actually chooses it, whether Sort disappears, and how
-- much row/buffer work remains. Exact timing and plan details are not fixed.

SELECT
    pg_size_pretty(pg_relation_size('sql_course_lab.runs')) AS heap_main_fork,
    pg_size_pretty(pg_indexes_size('sql_course_lab.runs')) AS all_indexes,
    pg_size_pretty(pg_total_relation_size('sql_course_lab.runs')) AS total_relation;

-- SECTION D: A workload-specific alternative. Failed rows are 1% of this data.
-- Retaining both indexes is for comparison, not a production recommendation.
CREATE INDEX runs_failed_feed_idx
ON sql_course_lab.runs (project_id, created_at DESC, id DESC)
WHERE status = 'failed';

SELECT indexrelid::regclass AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_index
WHERE indrelid = 'sql_course_lab.runs'::regclass
ORDER BY pg_relation_size(indexrelid) DESC;

EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT id, created_at, duration_ms
FROM sql_course_lab.runs
WHERE project_id = 42 AND status = 'failed'
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- Explain why the partial index is eligible for the preceding query, but not
-- a general replacement for the full index when querying succeeded runs.

-- SECTION E: An existing index is not an instruction to use it.
CREATE INDEX runs_status_idx ON sql_course_lab.runs (status);

EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT sum(duration_ms)
FROM sql_course_lab.runs
WHERE status = 'failed';

EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT sum(duration_ms)
FROM sql_course_lab.runs
WHERE status = 'succeeded';

-- Both queries have a matching status index available. Explain any difference
-- in chosen access paths. The generated statuses repeat through the heap, so
-- matching rows are dispersed rather than clustered into one compact region.
-- There is no universal percentage at which the optimizer must switch scans.

-- SECTION F: Prediction exercise for the next lesson. Do not add another index
-- until you have described how the existing indexes are ordered.
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT id, created_at, duration_ms
FROM sql_course_lab.runs
WHERE project_id = 42
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- Questions to answer in your notes:
-- 1. Why is removing the status equality different from changing its value?
-- 2. Can (project_id, status, created_at, id) provide the requested global
--    time order within a project when several status values are present?
-- 3. Which workload would justify a separate (project_id, created_at, id) index?
-- 4. Which of this lab's comparison indexes would you retain in a real system?
