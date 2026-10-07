-- Companion answer: run lab 19 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab19') IS NOT NULL,'Run lesson 19 first');

SELECT course_meta.assert_true(
 (SELECT body FROM lab19.documents WHERE id=1)='version two','latest committed version');
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT pg_current_snapshot(),body FROM lab19.documents WHERE id=1;
COMMIT;
SELECT pid,application_name,xact_start,backend_xmin,state FROM pg_stat_activity
WHERE datname=current_database() ORDER BY xact_start NULLS LAST;
-- A single session cannot prove retained-version behavior. Use concurrency tests.

SELECT 'SOLUTION_19_PASSED' AS result;
