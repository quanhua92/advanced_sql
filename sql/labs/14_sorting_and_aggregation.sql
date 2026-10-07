-- Lesson 14: sorting and aggregation.
-- READ docs/lessons/14_sorting_and_aggregation.md before running.
-- Re-running resets ONLY lab14; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab14');
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at FROM lab14.runs ORDER BY created_at DESC,id DESC LIMIT 20;
CREATE INDEX runs_time ON lab14.runs(created_at DESC,id DESC);
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at FROM lab14.runs ORDER BY created_at DESC,id DESC LIMIT 20;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT project_id,count(*) AS total,
       count(*) FILTER(WHERE status='failed') AS failed
FROM lab14.runs GROUP BY project_id ORDER BY project_id;
CREATE INDEX runs_group ON lab14.runs(project_id) INCLUDE(status);
VACUUM (ANALYZE) lab14.runs;
BEGIN;
SET LOCAL enable_hashagg=off;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT project_id,count(*) FROM lab14.runs GROUP BY project_id ORDER BY project_id;
ROLLBACK;
BEGIN;
SET LOCAL work_mem='64kB';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,payload FROM lab14.runs ORDER BY payload,id;
ROLLBACK;

SELECT 'LAB_14_COMPLETED' AS result;
