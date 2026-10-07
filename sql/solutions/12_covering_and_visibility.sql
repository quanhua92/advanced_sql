-- Companion answer: run lab 12 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab12') IS NOT NULL,'Run lesson 12 first');

SELECT course_meta.assert_true(
 NOT EXISTS(SELECT 1 FROM lab12.runs l JOIN course.runs r USING(id)
 WHERE l.duration_ms<>r.duration_ms+CASE WHEN r.project_id=42 THEN 1 ELSE 0 END),
 'Covering-index experiment preserves intended updates');
SELECT * FROM pg_visibility_map_summary('lab12.runs'::regclass);
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab12.runs
WHERE project_id=42 AND status='failed' ORDER BY created_at DESC,id DESC LIMIT 20;
-- Do not assert Heap Fetches=0: visibility and actual plan choice are observations.

SELECT 'SOLUTION_12_PASSED' AS result;
