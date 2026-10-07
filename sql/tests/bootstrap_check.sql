\ir ../lib/session.sql
DO $body$
DECLARE actual bigint; expected bigint;
BEGIN
 SELECT count(*) INTO actual FROM course.runs;
 SELECT seeded_runs INTO expected FROM course_meta.installation WHERE id=1;
 IF actual<>expected THEN RAISE EXCEPTION 'Seed mismatch: % vs %',actual,expected; END IF;
 IF EXISTS(SELECT 1 FROM course.runs r JOIN course.workflows w ON w.id=r.workflow_id
           WHERE r.project_id<>w.project_id) THEN RAISE EXCEPTION 'Invalid tenant/workflow relationship'; END IF;
 IF (SELECT count(*) FROM pg_extension WHERE extname IN
   ('pg_stat_statements','pageinspect','pg_visibility','pg_trgm'))<>4 THEN
   RAISE EXCEPTION 'An expected extension is missing'; END IF;
END;
$body$;
SELECT status,count(*) FROM course.runs GROUP BY status ORDER BY status;
SELECT 'BOOTSTRAP_CHECK_PASSED' AS result;
