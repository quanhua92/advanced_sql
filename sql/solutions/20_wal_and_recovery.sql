-- Companion answer: run lab 20 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab20') IS NOT NULL,'Run lesson 20 first');

SELECT course_meta.assert_true((SELECT count(*) FROM lab20.logged_rows)=10000,'logged insertion');
SELECT course_meta.assert_true((SELECT count(*) FROM lab20.unlogged_rows)=10000,'unlogged insertion before optional crash');
SELECT course_meta.assert_true((SELECT count(*) FROM lab20.durability_marker)=1,'committed marker');
SELECT relname,relpersistence FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='lab20' AND c.relkind='r' ORDER BY relname;
-- After the optional crash, unlogged rows may be gone. Rerun lab20 to restore
-- its initial comparison before running this pre-crash solution again.

SELECT 'SOLUTION_20_PASSED' AS result;
