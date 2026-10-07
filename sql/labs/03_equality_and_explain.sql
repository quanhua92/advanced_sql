-- Lesson 03: equality and explain.
-- READ docs/lessons/03_equality_and_explain.md before running.
-- Re-running resets ONLY lab03; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab03');
-- Primary-key point lookup versus a non-indexed equality.
EXPLAIN (ANALYZE,BUFFERS,VERBOSE,TIMING OFF)
SELECT id,payload FROM lab03.runs WHERE id=4242;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,payload FROM lab03.runs WHERE project_id=42;
CREATE INDEX runs_project ON lab03.runs(project_id);
ANALYZE lab03.runs;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,payload FROM lab03.runs WHERE project_id=42;
-- Machine-readable plan; EXPLAIN still executes the enclosed SELECT.
EXPLAIN (ANALYZE,BUFFERS,FORMAT JSON,TIMING OFF)
SELECT id FROM lab03.runs WHERE project_id=42 LIMIT 20;
SELECT attname,n_distinct,null_frac,correlation
FROM pg_stats WHERE schemaname='lab03' AND tablename='runs'
AND attname IN ('project_id','status','created_at');

SELECT 'LAB_03_COMPLETED' AS result;
