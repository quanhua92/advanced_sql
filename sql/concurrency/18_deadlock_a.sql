\ir session.sql
\set ON_ERROR_STOP off
\set VERBOSITY verbose
SET application_name='course_deadlock_a';
BEGIN;
UPDATE course_concurrency.resources SET value=value+1 WHERE id=1;
\prompt 'B must first lock row 2. Press Enter to request row 2 and wait: ' continue
UPDATE course_concurrency.resources SET value=value+1 WHERE id=2;
ROLLBACK;
\set ON_ERROR_STOP on
-- Expected outcome: one participant reports SQLSTATE 40P01; victim unspecified.
