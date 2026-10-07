-- Lesson 08: ranges text and bitmaps.
-- READ docs/lessons/08_ranges_text_and_bitmaps.md before running.
-- Re-running resets ONLY lab08; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab08');
CREATE INDEX runs_project ON lab08.runs(project_id);
CREATE INDEX runs_status ON lab08.runs(status);
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id FROM lab08.runs WHERE project_id=42 AND status='running';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id FROM lab08.runs WHERE project_id=42 OR status='failed';
-- A BitmapAnd is possible, not guaranteed. One selective index plus a filter
-- can be cheaper than building two bitmaps for this dataset.
CREATE TABLE lab08.messages AS
SELECT i AS id,'Run-'||lpad(i::text,6,'0')||
       CASE WHEN i%100=0 THEN ' timeout' ELSE ' finished' END AS message
FROM generate_series(1,50000) g(i);
CREATE INDEX messages_prefix ON lab08.messages(message text_pattern_ops);
ANALYZE lab08.messages;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id FROM lab08.messages WHERE message LIKE 'Run-0001%';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id FROM lab08.messages WHERE message LIKE '%timeout%';
CREATE INDEX messages_substring ON lab08.messages USING gin(message gin_trgm_ops);
ANALYZE lab08.messages;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id FROM lab08.messages WHERE message LIKE '%timeout%';

SELECT 'LAB_08_COMPLETED' AS result;
