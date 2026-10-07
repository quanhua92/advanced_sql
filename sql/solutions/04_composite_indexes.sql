-- Companion answer: run lab 04 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab04') IS NOT NULL,'Run lesson 04 first');

CREATE INDEX IF NOT EXISTS runs_failed_only ON lab04.runs(project_id,created_at DESC,id DESC)
WHERE status='failed';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab04.runs
WHERE project_id=42 AND status='failed' ORDER BY created_at DESC,id DESC LIMIT 20;
SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab04.runs WHERE status='failed')=
 (SELECT seeded_runs/100 FROM course_meta.installation WHERE id=1),
 'Failure predicate matches the documented seed');
SELECT indexname,indexdef FROM pg_indexes WHERE schemaname='lab04' ORDER BY indexname;

SELECT 'SOLUTION_04_PASSED' AS result;
