-- Companion answer: run lab 21 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab21') IS NOT NULL,'Run lesson 21 first');

SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab21.events)+(SELECT count(*) FROM lab21.events_2026_01)=
 (SELECT count(*) FROM course.run_events),'Detach preserves data in separate relations');
SELECT course_meta.assert_true(
 NOT EXISTS(SELECT 1 FROM lab21.events WHERE created_at<'2026-02-01 00:00:00+00'::timestamptz),
 'Detached January is no longer visible through the parent');
BEGIN;
INSERT INTO lab21.events VALUES(-1,-1,1,'2026-02-01 00:00:00+00','boundary.test','{}');
SELECT tableoid::regclass,id,created_at FROM lab21.events WHERE id=-1;
SELECT course_meta.assert_true(
 EXISTS(SELECT 1 FROM lab21.events_2026_02 WHERE id=-1),'February boundary routes to February');
ROLLBACK;

SELECT 'SOLUTION_21_PASSED' AS result;
