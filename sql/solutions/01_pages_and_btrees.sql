-- Companion answer: run lab 01 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab01') IS NOT NULL,'Run lesson 01 first');

CREATE INDEX IF NOT EXISTS runs_all_status_time ON lab01.runs(project_id,created_at DESC,id DESC);
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab01.runs WHERE project_id=42
ORDER BY created_at DESC,id DESC LIMIT 20;
SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab01.runs)=(SELECT seeded_runs FROM course_meta.installation WHERE id=1),
 'An index must not change the number of table rows');
SELECT indexrelid::regclass,pg_size_pretty(pg_relation_size(indexrelid))
FROM pg_index WHERE indrelid='lab01.runs'::regclass ORDER BY 1;

SELECT 'SOLUTION_01_PASSED' AS result;
