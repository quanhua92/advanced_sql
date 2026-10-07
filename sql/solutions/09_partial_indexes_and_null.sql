-- Companion answer: run lab 09 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab09') IS NOT NULL,'Run lesson 09 first');

SELECT course_meta.assert_true((2 NOT IN(1,NULL::integer)) IS NULL,'NOT IN yields unknown');
SELECT course_meta.assert_true((SELECT count(*) FROM lab09.labels)=2,'NULLS NOT DISTINCT conflict policy');
WITH banned(id) AS (VALUES(1),(NULL::integer)),candidate(id) AS (VALUES(1),(2),(NULL::integer))
SELECT candidate.id FROM candidate
WHERE NOT EXISTS(SELECT 1 FROM banned b WHERE b.id IS NOT DISTINCT FROM candidate.id);
-- The null-safe matching policy above excludes a NULL candidate when NULL is banned.
PREPARE fixed_failure(integer) AS
SELECT id FROM lab09.runs WHERE project_id=$1 AND status='failed'
ORDER BY created_at DESC,id DESC LIMIT 20;
BEGIN;
SET LOCAL plan_cache_mode=force_generic_plan;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF) EXECUTE fixed_failure(42);
ROLLBACK;
DEALLOCATE fixed_failure;

SELECT 'SOLUTION_09_PASSED' AS result;
