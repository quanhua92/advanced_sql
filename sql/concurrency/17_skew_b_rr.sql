\ir session.sql
SET application_name='course_skew_b_rr';
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) AS active_before_decision FROM course_concurrency.on_call WHERE active;
\prompt 'Both A and B must have read 2. Once both are paused, press Enter: ' continue
UPDATE course_concurrency.on_call SET active=false WHERE id=2;
COMMIT;
-- Under SERIALIZABLE a serialization error is an expected outcome for a
-- participant. In an interactive session issue ROLLBACK after an error.
