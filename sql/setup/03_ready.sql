\set ON_ERROR_STOP on
DO $body$
BEGIN
  IF (SELECT count(*) FROM course.runs) < 10000 THEN
    RAISE EXCEPTION 'Seed is incomplete';
  END IF;
END;
$body$;
UPDATE course_meta.installation SET ready=true WHERE id=1;
SELECT 'COURSE_READY' AS status,seeded_runs,package_version FROM course_meta.installation;
