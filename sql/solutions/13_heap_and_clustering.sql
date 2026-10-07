-- Companion answer: run lab 13 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab13') IS NOT NULL,'Run lesson 13 first');

SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab13.runs)=(SELECT seeded_runs+10000 FROM course_meta.installation WHERE id=1),
 'CLUSTER and later inserts preserve expected cardinality');
SELECT course_meta.assert_true(
 NOT EXISTS(SELECT 1 FROM lab13.runs l JOIN course.runs r USING(id)
 WHERE l.payload<>r.payload),'Rewrite preserves original row values');
SELECT attname,correlation FROM pg_stats WHERE schemaname='lab13'
AND tablename='runs' AND attname IN('project_id','created_at');
-- The recorded clustering flag is not a continuously maintained physical invariant.

SELECT 'SOLUTION_13_PASSED' AS result;
