-- Companion answer: run lab 05 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab05') IS NOT NULL,'Run lesson 05 first');

SELECT course_meta.assert_true(
 (SELECT sum(duration_ms) FROM lab05.runs WHERE status='failed')=
 (SELECT sum(duration_ms) FROM course.runs WHERE status='failed'),
 'Scan-strategy experiments preserve aggregate semantics');
SELECT status,count(*) AS rows,sum(duration_ms) AS total_duration
FROM lab05.runs GROUP BY status ORDER BY status;
SHOW enable_seqscan;
SHOW enable_indexscan;
SHOW enable_bitmapscan;
-- The preceding lab used SET LOCAL; these should not be leaked forced settings.

SELECT 'SOLUTION_05_PASSED' AS result;
