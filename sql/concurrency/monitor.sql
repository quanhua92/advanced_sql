\ir session.sql
SELECT pid,application_name,state,xact_start,backend_xmin,
 wait_event_type,wait_event,pg_blocking_pids(pid) AS blockers,left(query,100) AS query
FROM pg_stat_activity WHERE datname=current_database() ORDER BY pid;
SELECT pid,locktype,mode,granted,relation::regclass,transactionid
FROM pg_locks WHERE pid IN(SELECT pid FROM pg_stat_activity WHERE datname=current_database())
ORDER BY pid,granted,locktype;
