\ir session.sql
SET application_name='course_snapshot_B';
UPDATE course_concurrency.document SET body='version two' WHERE id=1;
VACUUM(VERBOSE,ANALYZE) course_concurrency.document;
SELECT pid,application_name,backend_xmin,xact_start,state
FROM pg_stat_activity WHERE application_name LIKE 'course_snapshot_%';
