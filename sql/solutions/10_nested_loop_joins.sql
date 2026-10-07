-- Companion answer: run lab 10 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab10') IS NOT NULL,'Run lesson 10 first');

CREATE TEMP TABLE chosen_workflows AS
SELECT id FROM course.workflows WHERE project_id=42 UNION ALL SELECT 9999;
CREATE TEMP TABLE latest AS
SELECT w.id AS workflow_id,r.id AS run_id
FROM chosen_workflows w
LEFT JOIN LATERAL(SELECT id FROM lab10.runs r WHERE r.workflow_id=w.id
 ORDER BY created_at DESC,id DESC LIMIT 3) r ON true;
SELECT course_meta.assert_true(
 (SELECT count(*) FROM latest WHERE workflow_id=9999 AND run_id IS NULL)=1,
 'LEFT LATERAL preserves an empty parent');
SELECT course_meta.assert_true(
 NOT EXISTS(SELECT workflow_id FROM latest GROUP BY workflow_id HAVING count(run_id)>3),
 'No parent has more than three actual child rows');
SELECT * FROM latest ORDER BY workflow_id,run_id;

SELECT 'SOLUTION_10_PASSED' AS result;
