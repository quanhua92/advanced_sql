-- Lesson 10: nested loop joins.
-- READ docs/lessons/10_nested_loop_joins.md before running.
-- Re-running resets ONLY lab10; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab10');
CREATE INDEX runs_workflow_time ON lab10.runs(workflow_id,created_at DESC,id DESC);
-- Five selected workflows, each requesting only its latest three runs.
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT w.id AS workflow_id,r.id,r.created_at
FROM course.workflows w
CROSS JOIN LATERAL (
  SELECT id,created_at FROM lab10.runs r
  WHERE r.workflow_id=w.id ORDER BY created_at DESC,id DESC LIMIT 3
) r
WHERE w.project_id=42
ORDER BY w.id,r.created_at DESC,r.id DESC;
-- Observe inner loops and rows per loop, not just the time of one probe.
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT w.id,count(r.id) FROM course.workflows w
JOIN lab10.runs r ON r.workflow_id=w.id
WHERE w.project_id=42 GROUP BY w.id;

SELECT 'LAB_10_COMPLETED' AS result;
