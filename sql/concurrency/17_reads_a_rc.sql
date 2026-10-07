\ir session.sql
SET application_name='course_reads_A_rc';
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT value AS first_read FROM course_concurrency.counter WHERE id=1;
\prompt 'A has read. Run 17_reads_b.sql in B; then press Enter here: ' continue
SELECT value AS second_read FROM course_concurrency.counter WHERE id=1;
COMMIT;
