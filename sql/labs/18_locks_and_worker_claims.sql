-- Lesson 18: locks and worker claims.
-- READ docs/lessons/18_locks_and_worker_claims.md before running.
-- Re-running resets ONLY lab18; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab18',false);
CREATE TABLE lab18.jobs(id integer PRIMARY KEY,status text NOT NULL,priority integer NOT NULL);
INSERT INTO lab18.jobs SELECT i,'queued',i%3 FROM generate_series(1,12) g(i);
CREATE INDEX jobs_queued ON lab18.jobs(priority DESC,id) WHERE status='queued';
BEGIN;
WITH candidate AS (
 SELECT id FROM lab18.jobs WHERE status='queued'
 ORDER BY priority DESC,id FOR UPDATE SKIP LOCKED LIMIT 1
)
UPDATE lab18.jobs j SET status='running' FROM candidate c WHERE j.id=c.id
RETURNING j.*;
COMMIT;
SELECT locktype,mode,granted,relation::regclass
FROM pg_locks WHERE pid=pg_backend_pid() ORDER BY locktype,mode;
CREATE TABLE lab18.resources(id integer PRIMARY KEY,value integer NOT NULL);
INSERT INTO lab18.resources VALUES(1,0),(2,0);
-- sql/concurrency/18_* provides real blocking, deadlock, and skip-locked schedules.

SELECT 'LAB_18_COMPLETED' AS result;
