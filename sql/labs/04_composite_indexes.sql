-- Lesson 04: composite indexes.
-- READ docs/lessons/04_composite_indexes.md before running.
-- Re-running resets ONLY lab04; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab04');
CREATE INDEX runs_project_status_time ON lab04.runs
(project_id,status,created_at DESC,id DESC);
-- PG18 may skip across the low-cardinality project_id prefix for status-only predicates.
-- Compare Index Searches, buffers, and the planner's chosen path.
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT count(*) FROM lab04.runs WHERE status='failed';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab04.runs
WHERE project_id=42 AND status='failed'
ORDER BY created_at DESC,id DESC LIMIT 20;
-- Removing the equality exposes several independently time-ordered status groups.
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab04.runs
WHERE project_id=42 ORDER BY created_at DESC,id DESC LIMIT 20;
CREATE INDEX runs_project_time ON lab04.runs(project_id,created_at DESC,id DESC);
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab04.runs
WHERE project_id=42 ORDER BY created_at DESC,id DESC LIMIT 20;
-- Right-of-range predicates can filter entries without narrowing the full range.
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id FROM lab04.runs
WHERE project_id>=90 AND status='failed';

SELECT 'LAB_04_COMPLETED' AS result;
