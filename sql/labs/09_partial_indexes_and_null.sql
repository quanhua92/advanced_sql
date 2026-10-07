-- Lesson 09: partial indexes and null.
-- READ docs/lessons/09_partial_indexes_and_null.md before running.
-- Re-running resets ONLY lab09; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab09');
CREATE INDEX runs_failed_feed ON lab09.runs(project_id,created_at DESC,id DESC)
WHERE status='failed';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at FROM lab09.runs WHERE project_id=42 AND status='failed'
ORDER BY created_at DESC,id DESC LIMIT 20;
PREPARE feed(integer,text) AS
SELECT id,created_at FROM lab09.runs WHERE project_id=$1 AND status=$2
ORDER BY created_at DESC,id DESC LIMIT 20;
BEGIN;
SET LOCAL plan_cache_mode=force_generic_plan;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF) EXECUTE feed(42,'failed');
ROLLBACK;
DEALLOCATE feed;
-- NOT IN is not a general null-safe anti-join.
SELECT 2 NOT IN (1,NULL::integer) AS unknown_not_true;
WITH banned(id) AS (VALUES (1),(NULL::integer))
SELECT candidate.id FROM (VALUES(1),(2),(3)) candidate(id)
WHERE NOT EXISTS(SELECT 1 FROM banned b WHERE b.id=candidate.id)
ORDER BY candidate.id;
CREATE TABLE lab09.labels(name text UNIQUE NULLS NOT DISTINCT);
INSERT INTO lab09.labels VALUES(NULL),(NULL),('cpu') ON CONFLICT DO NOTHING;
SELECT * FROM lab09.labels ORDER BY name NULLS FIRST;

SELECT 'LAB_09_COMPLETED' AS result;
