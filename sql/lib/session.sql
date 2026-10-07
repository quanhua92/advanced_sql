\set ON_ERROR_STOP on
\pset pager off
\timing on
SET application_name='advanced_sql_course';
SET timezone='UTC';
SET statement_timeout='120s';
SET lock_timeout='5s';
SET idle_in_transaction_session_timeout='60s';
-- Deterministic baseline for teaching, not a production tuning prescription.
SET max_parallel_workers_per_gather=0;
SET jit=off;
DO $body$
BEGIN
  IF current_database()<>'advanced_sql' THEN
    RAISE EXCEPTION 'Teaching labs require database advanced_sql, not %',current_database();
  END IF;
  IF current_setting('server_version_num')::integer/10000<>18 THEN
    RAISE EXCEPTION 'This executable baseline requires PostgreSQL 18. Use a separate environment for other majors.';
  END IF;
  IF NOT COALESCE((SELECT ready FROM course_meta.installation WHERE id=1),false) THEN
    RAISE EXCEPTION 'Course installation is not ready';
  END IF;
END;
$body$;
