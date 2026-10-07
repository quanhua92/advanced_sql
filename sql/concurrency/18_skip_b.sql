\ir session.sql
SET application_name='course_skip_B';
WITH candidate AS(SELECT id FROM course_concurrency.jobs WHERE status='queued'
 ORDER BY id FOR UPDATE SKIP LOCKED LIMIT 1)
UPDATE course_concurrency.jobs j SET status='running' FROM candidate c
WHERE j.id=c.id RETURNING j.*;
