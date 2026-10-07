-- Lesson 01: pages and btrees.
-- READ docs/lessons/01_pages_and_btrees.md before running.
-- Re-running resets ONLY lab01; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab01');
SHOW block_size;
SELECT pg_size_pretty(pg_relation_size('lab01.runs')) AS heap,
       pg_size_pretty(pg_indexes_size('lab01.runs')) AS indexes;
-- Predict the scan and sort before executing each plan.
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab01.runs
WHERE project_id=42 AND status='failed'
ORDER BY created_at DESC,id DESC LIMIT 20;
CREATE INDEX runs_dashboard ON lab01.runs(project_id,status,created_at DESC,id DESC);
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id,created_at,duration_ms FROM lab01.runs
WHERE project_id=42 AND status='failed'
ORDER BY created_at DESC,id DESC LIMIT 20;
-- Root level zero means the root is a leaf; number of levels = level + 1.
SELECT root,level,fastroot,fastlevel FROM bt_metap('lab01.runs_dashboard');
SELECT ctid,id,project_id FROM lab01.runs WHERE id=42;
SELECT lp,lp_len,t_xmin,t_xmax,t_ctid
FROM heap_page_items(get_raw_page('lab01.runs',0)) LIMIT 8;
-- Mathematical model with explicitly hypothetical independent row placement.
SELECT 1-power(1-0.01,80) AS probability_page_contains_a_match;

SELECT 'LAB_01_COMPLETED' AS result;
