-- Companion answer: run lab 14 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab14') IS NOT NULL,'Run lesson 14 first');

WITH grouped AS (SELECT project_id,count(*) AS n FROM lab14.runs GROUP BY project_id)
SELECT course_meta.assert_true(
 (SELECT sum(n) FROM grouped)=(SELECT count(*) FROM lab14.runs),
 'Grouping consumes every input row exactly once for this key');
WITH x(v) AS (VALUES(NULL::integer),(2))
SELECT count(*) AS row_count,count(v) AS nonnull_count,sum(v) AS total FROM x;
SELECT project_id,count(*) FILTER(WHERE status='failed') AS failures
FROM lab14.runs GROUP BY project_id ORDER BY project_id LIMIT 10;

SELECT 'SOLUTION_14_PASSED' AS result;
