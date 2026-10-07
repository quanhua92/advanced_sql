\set ON_ERROR_STOP on
\if :{?n_runs}
\else
  \set n_runs 500000
\endif
SELECT :'n_runs'::bigint >= 10000 AND :'n_runs'::bigint <= 5000000 AS valid_size \gset
\if :valid_size
\else
  \echo 'n_runs must be between 10000 and 5000000'
  SELECT 1 / 0 AS invalid_seed_size;
\endif
-- Explicit course-only reseed. No application schemas are addressed.
BEGIN;
UPDATE course_meta.installation SET ready=false WHERE id=1;
TRUNCATE course.run_events,course.runs,course.workflows,course.runners,course.projects;
INSERT INTO course.projects
SELECT i, 'Project '||i, 'Owner'||i||'@Example.test' FROM generate_series(1,100) g(i);
INSERT INTO course.workflows
SELECT (p.id-1)*5+w, p.id, 'Workflow '||w
FROM course.projects p CROSS JOIN generate_series(1,5) g(w);
INSERT INTO course.runners
SELECT i,'Runner '||i,CASE WHEN i<=15 THEN 'cpu' ELSE 'gpu' END
FROM generate_series(1,20) g(i);

-- Random project/workflow selection is independent of the status modulo.
-- Reusing i%100 for both would accidentally tie tenants to particular statuses.
SELECT setseed(0.42);
WITH generated AS MATERIALIZED (
  SELECT i,
         1+floor(random()*100)::integer AS project_id,
         1+floor(random()*5)::integer AS workflow_slot,
         CASE WHEN i%100=0 THEN 'failed'
              WHEN i%100 BETWEEN 1 AND 5 THEN 'queued'
              WHEN i%100 BETWEEN 6 AND 14 THEN 'running'
              ELSE 'succeeded' END AS status
  FROM generate_series(1, :n_runs) g(i)
)
INSERT INTO course.runs
SELECT i,project_id,(project_id-1)*5+workflow_slot,
       CASE WHEN status='queued' THEN NULL ELSE (i%20+1)::integer END,
       status,
       TIMESTAMPTZ '2026-01-01 00:00:00+00'+i*INTERVAL '10 seconds',
       (i%10000)::integer,(i%4)::integer,
       CASE WHEN status='failed' THEN CASE WHEN i%200=0 THEN 'OOM' ELSE 'TIMEOUT' END END,
       jsonb_build_object('model',CASE WHEN i%3=0 THEN 'tiny' ELSE 'base' END,
                          'region',CASE WHEN i%7=0 THEN 'vn' ELSE 'us' END,
                          'trace',md5(i::text)),
       repeat(md5(i::text),4)
FROM generated ORDER BY i;
INSERT INTO course.run_events
SELECT r.id,r.id,r.project_id,r.created_at+INTERVAL '1 second',
       'run.'||r.status,jsonb_build_object('status',r.status)
FROM course.runs r WHERE r.id%5=0;
UPDATE course_meta.installation SET seeded_runs=:n_runs, installed_at=clock_timestamp() WHERE id=1;
COMMIT;
-- VACUUM must be outside a transaction and outside --single-transaction.
VACUUM (ANALYZE) course.projects;
VACUUM (ANALYZE) course.workflows;
VACUUM (ANALYZE) course.runners;
VACUUM (ANALYZE) course.runs;
VACUUM (ANALYZE) course.run_events;
