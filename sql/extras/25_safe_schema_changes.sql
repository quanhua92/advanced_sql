\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab25');
-- CONCURRENTLY must not run inside BEGIN or psql --single-transaction.
CREATE INDEX CONCURRENTLY runs_project_time ON lab25.runs(project_id,created_at DESC,id DESC);
SELECT indexrelid::regclass,indisvalid,indisready FROM pg_index
WHERE indrelid='lab25.runs'::regclass;
SELECT course_meta.assert_true(
 (SELECT indisvalid AND indisready FROM pg_index
 WHERE indexrelid='lab25.runs_project_time'::regclass),'Concurrent index is valid and ready');
ALTER TABLE lab25.runs ADD CONSTRAINT duration_nonnegative CHECK(duration_ms>=0) NOT VALID;
ALTER TABLE lab25.runs VALIDATE CONSTRAINT duration_nonnegative;
SELECT conname,convalidated FROM pg_constraint WHERE conrelid='lab25.runs'::regclass;
DROP INDEX CONCURRENTLY lab25.runs_project_time;
SELECT course_meta.assert_true(to_regclass('lab25.runs_project_time') IS NULL,'Demo index removed');

SELECT 'BONUS_25_PASSED' AS result;
