\ir ../lib/session.sql

SELECT sum(duration_ms) FROM course.runs WHERE project_id=42;
SELECT sum(duration_ms) FROM course.runs WHERE project_id=42;
SELECT sum(duration_ms) FROM course.runs WHERE project_id=42;
SELECT queryid,calls,round(total_exec_time::numeric,2) AS total_ms,
 round(mean_exec_time::numeric,2) AS mean_ms,rows,shared_blks_hit,shared_blks_read,
 temp_blks_read,temp_blks_written,left(query,140) AS query
FROM pg_stat_statements WHERE dbid=(SELECT oid FROM pg_database WHERE datname=current_database())
ORDER BY total_exec_time DESC LIMIT 20;
SELECT pid,application_name,state,wait_event_type,wait_event,
 clock_timestamp()-xact_start AS transaction_age,pg_blocking_pids(pid) AS blockers
FROM pg_stat_activity WHERE datname=current_database() ORDER BY xact_start NULLS LAST;
SELECT schemaname,relname,n_live_tup,n_dead_tup,last_autovacuum,last_autoanalyze
FROM pg_stat_user_tables WHERE schemaname IN('course','lab16','lab19') ORDER BY 1,2;
SELECT current_setting('shared_preload_libraries') AS preloaded;
SELECT course_meta.assert_true(
 EXISTS(SELECT 1 FROM pg_extension WHERE extname='pg_stat_statements'),'Query statistics extension installed');

SELECT 'BONUS_23_PASSED' AS result;
