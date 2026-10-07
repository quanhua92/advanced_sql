-- Companion answer: run lab 11 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab11') IS NOT NULL,'Run lesson 11 first');

SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab11.runs r JOIN course.workflows w ON w.id=r.workflow_id)=
 (SELECT count(*) FROM lab11.runs),'One workflow match per run');
SELECT course_meta.assert_true(
 (SELECT sum(r.duration_ms) FROM lab11.runs r JOIN course.workflows w ON w.id=r.workflow_id)=
 (SELECT sum(duration_ms) FROM lab11.runs),'Equivalent join aggregate');
SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab11.runs a JOIN lab11.runs b ON a.id=b.id)=
 (SELECT count(*) FROM lab11.runs),'Self-join does not multiply unique IDs');

SELECT 'SOLUTION_11_PASSED' AS result;
