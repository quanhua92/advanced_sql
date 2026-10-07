-- Lesson 02: index economics.
-- READ docs/lessons/02_index_economics.md before running.
-- Re-running resets ONLY lab02; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab02',false);
CREATE TABLE lab02.no_secondary AS SELECT * FROM course.runs WHERE false;
CREATE TABLE lab02.three_indexes (LIKE lab02.no_secondary);
CREATE INDEX writes_project ON lab02.three_indexes(project_id);
CREATE INDEX writes_status ON lab02.three_indexes(status);
CREATE INDEX writes_time ON lab02.three_indexes(created_at);
-- Identical input, different index-maintenance obligations. This is not a
-- controlled storage-device benchmark: cache state and run order differ.
EXPLAIN (ANALYZE,BUFFERS,WAL,TIMING OFF)
INSERT INTO lab02.no_secondary SELECT * FROM course.runs WHERE id<=10000;
EXPLAIN (ANALYZE,BUFFERS,WAL,TIMING OFF)
INSERT INTO lab02.three_indexes SELECT * FROM course.runs WHERE id<=10000;
VACUUM (ANALYZE) lab02.no_secondary;
VACUUM (ANALYZE) lab02.three_indexes;
SELECT c.oid::regclass AS relation,
       pg_size_pretty(pg_relation_size(c.oid)) AS main_fork,
       pg_size_pretty(pg_indexes_size(c.oid)) AS indexes
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='lab02' AND c.relkind='r' ORDER BY c.relname;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT sum(duration_ms) FROM lab02.three_indexes WHERE status='failed';

SELECT 'LAB_02_COMPLETED' AS result;
