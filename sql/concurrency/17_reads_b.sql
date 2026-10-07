\ir session.sql
SET application_name='course_reads_B';
UPDATE course_concurrency.counter SET value=value+1 WHERE id=1 RETURNING value;
