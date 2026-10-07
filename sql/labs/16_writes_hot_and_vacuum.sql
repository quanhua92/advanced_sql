-- Lesson 16: writes hot and vacuum.
-- READ docs/lessons/16_writes_hot_and_vacuum.md before running.
-- Re-running resets ONLY lab16; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab16',false);
CREATE TABLE lab16.hot_candidate(id integer PRIMARY KEY,status integer,note text)
WITH(fillfactor=70);
CREATE TABLE lab16.indexed_note(LIKE lab16.hot_candidate INCLUDING ALL)
WITH(fillfactor=70);
CREATE INDEX hot_status ON lab16.hot_candidate(status);
CREATE INDEX cold_note ON lab16.indexed_note(status) INCLUDE(note);
INSERT INTO lab16.hot_candidate
SELECT i,i%4,'initial' FROM generate_series(1,20000) g(i);
INSERT INTO lab16.indexed_note SELECT * FROM lab16.hot_candidate;
VACUUM (ANALYZE) lab16.hot_candidate;
VACUUM (ANALYZE) lab16.indexed_note;
EXPLAIN (ANALYZE,BUFFERS,WAL,TIMING OFF)
UPDATE lab16.hot_candidate SET note='changed' WHERE id<=10000;
EXPLAIN (ANALYZE,BUFFERS,WAL,TIMING OFF)
UPDATE lab16.indexed_note SET note='changed' WHERE id<=10000;
SELECT pg_stat_force_next_flush();
SELECT pg_stat_clear_snapshot();
SELECT relname,n_tup_upd,n_tup_hot_upd,n_dead_tup
FROM pg_stat_user_tables WHERE schemaname='lab16' ORDER BY relname;
DELETE FROM lab16.hot_candidate WHERE id%10=0;
SELECT pg_size_pretty(pg_relation_size('lab16.hot_candidate')) AS before_vacuum;
VACUUM (ANALYZE) lab16.hot_candidate;
SELECT pg_size_pretty(pg_relation_size('lab16.hot_candidate')) AS after_vacuum;
-- Ordinary VACUUM makes space reusable; do not expect a full file compaction.

SELECT 'LAB_16_COMPLETED' AS result;
