-- Lesson 05: scan strategies.
-- READ docs/lessons/05_scan_strategies.md before running.
-- Re-running resets ONLY lab05; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab05');
CREATE INDEX runs_status ON lab05.runs(status);
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT sum(duration_ms) FROM lab05.runs WHERE status='failed';
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT sum(duration_ms) FROM lab05.runs WHERE status='succeeded';
-- Controlled counterfactuals, scoped to transactions. These flags discourage
-- paths; they are diagnostic instruments, not global production fixes.
BEGIN;
SET LOCAL enable_seqscan=off;
SET LOCAL enable_bitmapscan=off;
SET LOCAL enable_indexonlyscan=off;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT sum(duration_ms) FROM lab05.runs WHERE status='failed';
ROLLBACK;
BEGIN;
SET LOCAL enable_seqscan=off;
SET LOCAL enable_indexscan=off;
SET LOCAL enable_indexonlyscan=off;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT sum(duration_ms) FROM lab05.runs WHERE status='failed';
ROLLBACK;
BEGIN;
SET LOCAL enable_indexscan=off;
SET LOCAL enable_indexonlyscan=off;
SET LOCAL enable_bitmapscan=off;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT sum(duration_ms) FROM lab05.runs WHERE status='failed';
ROLLBACK;

SELECT 'LAB_05_COMPLETED' AS result;
