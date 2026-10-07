-- Lesson 06: expressions and predicates.
-- READ docs/lessons/06_expressions_and_predicates.md before running.
-- Re-running resets ONLY lab06; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab06');
CREATE INDEX runs_created ON lab06.runs(created_at);
-- Session timezone is explicitly UTC, so these two day predicates agree.
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT count(*) FROM lab06.runs WHERE created_at::date=DATE '2026-01-02';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT count(*) FROM lab06.runs
WHERE created_at>=TIMESTAMPTZ '2026-01-02 00:00:00+00'
  AND created_at<TIMESTAMPTZ '2026-01-03 00:00:00+00';
-- timestamptz::date depends on the session timezone. Fix the zone in the expression.
CREATE INDEX runs_utc_date ON lab06.runs(((created_at AT TIME ZONE 'UTC')::date));
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT count(*) FROM lab06.runs
WHERE (created_at AT TIME ZONE 'UTC')::date=DATE '2026-01-02';
CREATE TABLE lab06.contacts AS
SELECT i AS id,'Person'||i||'@Example.test' AS email FROM generate_series(1,50000) g(i);
CREATE INDEX contacts_lower_email ON lab06.contacts(lower(email));
ANALYZE lab06.contacts;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id FROM lab06.contacts WHERE lower(email)='person4242@example.test';

SELECT 'LAB_06_COMPLETED' AS result;
