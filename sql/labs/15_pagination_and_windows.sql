-- Lesson 15: pagination and windows.
-- READ docs/lessons/15_pagination_and_windows.md before running.
-- Re-running resets ONLY lab15; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab15');
CREATE INDEX runs_time ON lab15.runs(created_at DESC,id DESC);
-- Capture the row immediately before the requested page, not its first row.
SELECT created_at AS cursor_time,id AS cursor_id FROM lab15.runs
ORDER BY created_at DESC,id DESC OFFSET 4999 LIMIT 1 \gset
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at FROM lab15.runs
ORDER BY created_at DESC,id DESC OFFSET 5000 LIMIT 20;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at FROM lab15.runs
WHERE (created_at,id)<(:'cursor_time'::timestamptz,:cursor_id::bigint)
ORDER BY created_at DESC,id DESC LIMIT 20;
CREATE TABLE lab15.offset_page AS
SELECT id FROM lab15.runs ORDER BY created_at DESC,id DESC OFFSET 5000 LIMIT 20;
CREATE TABLE lab15.keyset_page AS
SELECT id FROM lab15.runs
WHERE (created_at,id)<(:'cursor_time'::timestamptz,:cursor_id::bigint)
ORDER BY created_at DESC,id DESC LIMIT 20;
-- A window is not a GROUP BY: it keeps the input rows.
WITH ranked AS (
 SELECT workflow_id,id,created_at,row_number() OVER
 (PARTITION BY workflow_id ORDER BY created_at DESC,id DESC) AS rn
 FROM lab15.runs WHERE project_id=42
)
SELECT * FROM ranked WHERE rn<=3 ORDER BY workflow_id,rn;
-- Default RANGE includes peers with equal ORDER BY values.
WITH x(id,v) AS (VALUES(1,10),(2,10),(3,20))
SELECT id,v,sum(v) OVER(ORDER BY v) AS range_total,
 sum(v) OVER(ORDER BY v,id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rows_total
FROM x ORDER BY id;

SELECT 'LAB_15_COMPLETED' AS result;
