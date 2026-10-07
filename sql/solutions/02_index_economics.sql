-- Companion answer: run lab 02 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab02') IS NOT NULL,'Run lesson 02 first');

SELECT course_meta.assert_true((SELECT count(*) FROM lab02.no_secondary)=10000,'unindexed input count');
SELECT course_meta.assert_true((SELECT count(*) FROM lab02.three_indexes)=10000,'indexed input count');
SELECT course_meta.assert_true(
 NOT EXISTS((SELECT * FROM lab02.no_secondary EXCEPT SELECT * FROM lab02.three_indexes)
 UNION ALL (SELECT * FROM lab02.three_indexes EXCEPT SELECT * FROM lab02.no_secondary)),
 'Both write paths preserve identical rows');
SELECT pg_indexes_size('lab02.no_secondary') AS no_secondary_bytes,
       pg_indexes_size('lab02.three_indexes') AS three_index_bytes;

SELECT 'SOLUTION_02_PASSED' AS result;
