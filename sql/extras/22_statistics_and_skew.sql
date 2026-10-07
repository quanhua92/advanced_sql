\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab22',false);
CREATE TABLE lab22.correlated AS
SELECT i AS id,i%100 AS tenant_bucket,i%100 AS region_bucket,repeat('x',40) AS payload
FROM generate_series(1,100000) g(i);
ANALYZE lab22.correlated;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT * FROM lab22.correlated WHERE tenant_bucket=42 AND region_bucket=42;
CREATE STATISTICS lab22.tenant_region_stats(dependencies,mcv,ndistinct)
ON tenant_bucket,region_bucket FROM lab22.correlated;
ANALYZE lab22.correlated;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT * FROM lab22.correlated WHERE tenant_bucket=42 AND region_bucket=42;
SELECT statistics_name,attnames,kinds FROM pg_stats_ext WHERE schemaname='lab22';
SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab22.correlated WHERE tenant_bucket=42 AND region_bucket=42)=1000,
 'Correlated predicates match 1000 rows, not the independence estimate');

SELECT 'BONUS_22_PASSED' AS result;
