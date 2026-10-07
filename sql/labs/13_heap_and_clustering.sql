-- Lesson 13: heap and clustering.
-- READ docs/lessons/13_heap_and_clustering.md before running.
-- Re-running resets ONLY lab13; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab13');
CREATE INDEX runs_cluster_order ON lab13.runs(project_id,created_at,id);
ANALYZE lab13.runs;
SELECT attname,correlation FROM pg_stats WHERE schemaname='lab13'
AND tablename='runs' AND attname='project_id';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT sum(duration_ms) FROM lab13.runs WHERE project_id BETWEEN 40 AND 45;
-- ACCESS EXCLUSIVE lock and a rewrite: only this disposable lesson table.
CLUSTER lab13.runs USING runs_cluster_order;
ANALYZE lab13.runs;
SELECT attname,correlation FROM pg_stats WHERE schemaname='lab13'
AND tablename='runs' AND attname='project_id';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT sum(duration_ms) FROM lab13.runs WHERE project_id BETWEEN 40 AND 45;
-- New rows are not continuously reinserted into a globally sorted heap.
INSERT INTO lab13.runs
SELECT id+10000000,project_id,workflow_id,runner_id,status,created_at,
       duration_ms,priority,error_code,metadata,payload
FROM course.runs WHERE id<=10000 ORDER BY id;
ANALYZE lab13.runs;
SELECT indexrelid::regclass,indisclustered FROM pg_index
WHERE indrelid='lab13.runs'::regclass;

SELECT 'LAB_13_COMPLETED' AS result;
