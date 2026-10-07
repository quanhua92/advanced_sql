-- Lesson 21: partitioning.
-- READ docs/lessons/21_partitioning.md before running.
-- Re-running resets ONLY lab21; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab21',false);
CREATE TABLE lab21.events(
 id bigint NOT NULL,run_id bigint NOT NULL,project_id integer NOT NULL,
 created_at timestamptz NOT NULL,kind text NOT NULL,details jsonb NOT NULL,
 PRIMARY KEY(created_at,id)
) PARTITION BY RANGE(created_at);
CREATE TABLE lab21.events_2026_01 PARTITION OF lab21.events
FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-02-01 00:00:00+00');
CREATE TABLE lab21.events_2026_02 PARTITION OF lab21.events
FOR VALUES FROM ('2026-02-01 00:00:00+00') TO ('2026-03-01 00:00:00+00');
CREATE TABLE lab21.events_2026_03 PARTITION OF lab21.events
FOR VALUES FROM ('2026-03-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');
CREATE TABLE lab21.events_default PARTITION OF lab21.events DEFAULT;
INSERT INTO lab21.events SELECT * FROM course.run_events;
CREATE INDEX events_project_time ON lab21.events(project_id,created_at DESC,id DESC);
ANALYZE lab21.events;
SELECT tableoid::regclass AS partition,count(*) FROM lab21.events GROUP BY tableoid ORDER BY 1;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT count(*) FROM lab21.events
WHERE created_at>=TIMESTAMPTZ '2026-02-01 00:00:00+00'
AND created_at<TIMESTAMPTZ '2026-03-01 00:00:00+00';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT count(*) FROM lab21.events WHERE created_at::date=DATE '2026-02-02';
-- The row ID alone is not the range key. Compare the partitions visited.
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT * FROM lab21.events WHERE id=5000;
-- Retention demonstration: detached data remains in its own ordinary table.
ALTER TABLE lab21.events DETACH PARTITION lab21.events_2026_01;
SELECT count(*) AS detached_january_rows FROM lab21.events_2026_01;

SELECT 'LAB_21_COMPLETED' AS result;
