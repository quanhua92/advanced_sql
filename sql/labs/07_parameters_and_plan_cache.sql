-- Lesson 07: parameters and plan cache.
-- READ docs/lessons/07_parameters_and_plan_cache.md before running.
-- Re-running resets ONLY lab07; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab07',false);
CREATE TABLE lab07.items AS
SELECT i AS id,CASE WHEN i<=100 THEN 'rare' ELSE 'common' END AS category,
       repeat(md5(i::text),4) AS payload
FROM generate_series(1,100000) g(i);
CREATE INDEX items_category ON lab07.items(category);
ANALYZE lab07.items;
PREPARE category_total(text) AS
SELECT sum(length(payload)) FROM lab07.items WHERE category=$1;
BEGIN;
SET LOCAL plan_cache_mode=force_custom_plan;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF) EXECUTE category_total('rare');
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF) EXECUTE category_total('common');
ROLLBACK;
BEGIN;
SET LOCAL plan_cache_mode=force_generic_plan;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF) EXECUTE category_total('rare');
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF) EXECUTE category_total('common');
ROLLBACK;
SELECT name,parameter_types,generic_plans,custom_plans FROM pg_prepared_statements;
DEALLOCATE category_total;

SELECT 'LAB_07_COMPLETED' AS result;
