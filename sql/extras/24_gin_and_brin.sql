\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab24');
CREATE INDEX runs_metadata_gin ON lab24.runs USING gin(metadata jsonb_path_ops);
CREATE INDEX runs_time_brin ON lab24.runs USING brin(created_at)
WITH(pages_per_range=32,autosummarize=on);
ANALYZE lab24.runs;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT id FROM lab24.runs WHERE metadata @> '{"model":"tiny","region":"vn"}'::jsonb;
EXPLAIN (ANALYZE,BUFFERS,TIMING OFF)
SELECT sum(duration_ms) FROM lab24.runs
WHERE created_at>='2026-01-02 00:00:00+00'::timestamptz
AND created_at<'2026-01-03 00:00:00+00'::timestamptz;
SELECT indexrelid::regclass,pg_size_pretty(pg_relation_size(indexrelid))
FROM pg_index WHERE indrelid='lab24.runs'::regclass ORDER BY 1;
SELECT brin_summarize_new_values('lab24.runs_time_brin'::regclass);
SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab24.runs WHERE metadata @> '{"model":"tiny","region":"vn"}')=
 (SELECT count(*) FROM lab24.runs WHERE metadata->>'model'='tiny' AND metadata->>'region'='vn'),
 'Containment agrees with field comparisons for this non-null string-valued seed');

SELECT 'BONUS_24_PASSED' AS result;
