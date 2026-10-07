-- Companion answer: run lab 18 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab18') IS NOT NULL,'Run lesson 18 first');

SELECT course_meta.assert_true((SELECT count(*) FROM lab18.jobs WHERE status='running')=1,'first atomic claim');
BEGIN;
WITH candidate AS(
 SELECT id FROM lab18.jobs WHERE status='queued' ORDER BY priority DESC,id
 FOR UPDATE SKIP LOCKED LIMIT 1)
UPDATE lab18.jobs j SET status='running' FROM candidate c WHERE j.id=c.id RETURNING j.*;
SELECT course_meta.assert_true((SELECT count(*) FROM lab18.jobs WHERE status='running')=2,'second claim is distinct');
ROLLBACK;
SELECT course_meta.assert_true((SELECT count(*) FROM lab18.jobs WHERE status='running')=1,'solution leaves initial lab state');
SELECT pid,application_name,state,wait_event_type,wait_event,pg_blocking_pids(pid) AS blockers
FROM pg_stat_activity WHERE datname=current_database() ORDER BY pid;

SELECT 'SOLUTION_18_PASSED' AS result;
