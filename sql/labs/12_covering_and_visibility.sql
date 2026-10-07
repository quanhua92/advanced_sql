-- Lesson 12: covering and visibility.
-- READ docs/lessons/12_covering_and_visibility.md before running.
-- Re-running resets ONLY lab12; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab12');
CREATE INDEX runs_covering ON lab12.runs(project_id,status,created_at DESC,id DESC)
INCLUDE(duration_ms);
VACUUM (ANALYZE) lab12.runs;
SELECT * FROM pg_visibility_map_summary('lab12.runs'::regclass);
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab12.runs
WHERE project_id=42 AND status='failed'
ORDER BY created_at DESC,id DESC LIMIT 20;
UPDATE lab12.runs SET duration_ms=duration_ms+1 WHERE project_id=42;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab12.runs
WHERE project_id=42 AND status='failed'
ORDER BY created_at DESC,id DESC LIMIT 20;
SELECT * FROM pg_visibility_map_summary('lab12.runs'::regclass);
VACUUM (ANALYZE) lab12.runs;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab12.runs
WHERE project_id=42 AND status='failed'
ORDER BY created_at DESC,id DESC LIMIT 20;

SELECT 'LAB_12_COMPLETED' AS result;
