-- Companion answer: run lab 15 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab15') IS NOT NULL,'Run lesson 15 first');

SELECT course_meta.assert_true((SELECT count(*) FROM lab15.offset_page)=20,'OFFSET page length');
SELECT course_meta.assert_true((SELECT count(*) FROM lab15.keyset_page)=20,'keyset page length');
SELECT course_meta.assert_true(
 NOT EXISTS((SELECT * FROM lab15.offset_page EXCEPT SELECT * FROM lab15.keyset_page)
 UNION ALL (SELECT * FROM lab15.keyset_page EXCEPT SELECT * FROM lab15.offset_page)),
 'Static keyset and OFFSET pages match');
WITH x(id,v) AS (VALUES(1,10),(2,10),(3,20)),calc AS (
 SELECT id,sum(v) OVER(ORDER BY v) AS range_total,
 sum(v) OVER(ORDER BY v,id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rows_total FROM x)
SELECT course_meta.assert_true(
 (SELECT array_agg(range_total ORDER BY id) FROM calc)=ARRAY[20,20,40]::bigint[]
 AND (SELECT array_agg(rows_total ORDER BY id) FROM calc)=ARRAY[10,20,40]::bigint[],
 'Peer-aware versus row-wise frames');
WITH x(id,v) AS(VALUES(1,10),(2,10),(3,20))
SELECT id,last_value(v) OVER(ORDER BY v,id
 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS final_partition_value
FROM x ORDER BY id;

SELECT 'SOLUTION_15_PASSED' AS result;
