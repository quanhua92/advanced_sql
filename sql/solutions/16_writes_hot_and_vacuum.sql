-- Companion answer: run lab 16 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab16') IS NOT NULL,'Run lesson 16 first');

SELECT course_meta.assert_true((SELECT count(*) FROM lab16.hot_candidate)=18000,'delete count');
SELECT course_meta.assert_true((SELECT count(*) FROM lab16.indexed_note)=20000,'comparison table count');
SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab16.hot_candidate WHERE note='changed')=9000,
 'Updated rows remaining after deletion');
SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab16.indexed_note WHERE note='changed')=10000,
 'Included-payload update result');
SELECT pg_stat_clear_snapshot();
SELECT relname,n_tup_upd,n_tup_hot_upd,n_dead_tup FROM pg_stat_user_tables
WHERE schemaname='lab16' ORDER BY relname;

SELECT 'SOLUTION_16_PASSED' AS result;
