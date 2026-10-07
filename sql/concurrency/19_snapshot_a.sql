\ir session.sql
SET application_name='course_snapshot_A';
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT body FROM course_concurrency.document WHERE id=1;
\prompt 'Run 19_snapshot_b.sql in B, including VACUUM; then press Enter: ' continue
SELECT body AS still_old FROM course_concurrency.document WHERE id=1;
COMMIT;
SELECT body AS new_snapshot FROM course_concurrency.document WHERE id=1;
