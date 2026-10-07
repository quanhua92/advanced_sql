\ir session.sql
SET application_name='course_skip_A';
BEGIN;
SELECT id FROM course_concurrency.jobs WHERE id=1 FOR UPDATE;
\prompt 'A holds job 1. Run 18_skip_b.sql in B; then Enter to release: ' continue
ROLLBACK;
