-- Lesson 19: mvcc and snapshots.
-- READ docs/lessons/19_mvcc_and_snapshots.md before running.
-- Re-running resets ONLY lab19; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab19',false);
CREATE TABLE lab19.documents(id integer PRIMARY KEY,body text NOT NULL) WITH(fillfactor=70);
INSERT INTO lab19.documents VALUES(1,'version one');
SELECT ctid,xmin::text,xmax::text,* FROM lab19.documents;
UPDATE lab19.documents SET body='version two' WHERE id=1;
SELECT ctid,xmin::text,xmax::text,* FROM lab19.documents;
SELECT pg_current_snapshot();
VACUUM (VERBOSE,ANALYZE) lab19.documents;
SELECT * FROM pg_visibility_map_summary('lab19.documents'::regclass);
-- The retained-snapshot experiment must use independent sessions.
-- Follow docs/lessons/19_mvcc_and_snapshots.md.

SELECT 'LAB_19_COMPLETED' AS result;
