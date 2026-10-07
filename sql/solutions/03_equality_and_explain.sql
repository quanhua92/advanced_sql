-- Companion answer: run lab 03 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab03') IS NOT NULL,'Run lesson 03 first');

SELECT course_meta.assert_true((SELECT count(*) FROM lab03.runs WHERE id=4242)=1,'primary-key equality');
SELECT course_meta.assert_true(
 NOT EXISTS((SELECT id FROM lab03.runs WHERE project_id=42
             EXCEPT SELECT id FROM course.runs WHERE project_id=42)
 UNION ALL (SELECT id FROM course.runs WHERE project_id=42
             EXCEPT SELECT id FROM lab03.runs WHERE project_id=42)),
 'Project filter preserves IDs');
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id FROM lab03.runs WHERE project_id=42 LIMIT 20;

SELECT 'SOLUTION_03_PASSED' AS result;
