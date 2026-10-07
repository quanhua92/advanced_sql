-- Lesson 11: hash and merge joins.
-- READ docs/lessons/11_hash_and_merge_joins.md before running.
-- Re-running resets ONLY lab11; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab11');
CREATE INDEX runs_workflow ON lab11.runs(workflow_id);
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT w.project_id,sum(r.duration_ms)
FROM course.workflows w JOIN lab11.runs r ON r.workflow_id=w.id
GROUP BY w.project_id;
BEGIN;
SET LOCAL enable_nestloop=off;
SET LOCAL enable_mergejoin=off;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT count(*) FROM lab11.runs r JOIN course.workflows w ON w.id=r.workflow_id;
ROLLBACK;
BEGIN;
SET LOCAL enable_nestloop=off;
SET LOCAL enable_hashjoin=off;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT count(*) FROM lab11.runs r JOIN course.workflows w ON w.id=r.workflow_id;
ROLLBACK;
-- A larger build input makes memory/batch behavior observable.
BEGIN;
SET LOCAL work_mem='64kB';
SET LOCAL enable_nestloop=off;
SET LOCAL enable_mergejoin=off;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT count(*) FROM lab11.runs a JOIN lab11.runs b ON a.id=b.id;
ROLLBACK;

SELECT 'LAB_11_COMPLETED' AS result;
