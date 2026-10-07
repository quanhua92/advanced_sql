-- Lesson 20: wal and recovery.
-- READ docs/lessons/20_wal_and_recovery.md before running.
-- Re-running resets ONLY lab20; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab20',false);
CREATE TABLE lab20.logged_rows(id integer PRIMARY KEY,payload text);
CREATE UNLOGGED TABLE lab20.unlogged_rows(id integer PRIMARY KEY,payload text);
SHOW fsync;
SHOW full_page_writes;
SHOW synchronous_commit;
SELECT pg_current_wal_lsn() AS before_lsn \gset
EXPLAIN (ANALYZE,BUFFERS,WAL,TIMING OFF)
INSERT INTO lab20.logged_rows SELECT i,repeat(md5(i::text),4) FROM generate_series(1,10000) g(i);
SELECT pg_wal_lsn_diff(pg_current_wal_lsn(),:'before_lsn'::pg_lsn) AS cluster_wal_delta;
EXPLAIN (ANALYZE,BUFFERS,WAL,TIMING OFF)
INSERT INTO lab20.unlogged_rows SELECT i,repeat(md5(i::text),4) FROM generate_series(1,10000) g(i);
-- A checkpoint is not a COMMIT. This one affects only the disposable course cluster.
CHECKPOINT;
CREATE TABLE lab20.durability_marker(id integer PRIMARY KEY,note text NOT NULL);
INSERT INTO lab20.durability_marker VALUES(1,'committed before optional container crash');
SELECT pg_current_wal_lsn(),pg_current_wal_flush_lsn();
SELECT count(*) AS marker_count FROM lab20.durability_marker;
-- Never auto-kill a server. The optional controlled restart is documented.

SELECT 'LAB_20_COMPLETED' AS result;
