\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab26',false);
DO $body$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='course_rls_learner') THEN
  CREATE ROLE course_rls_learner NOLOGIN NOSUPERUSER NOBYPASSRLS;
 END IF;
 IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname='course_rls_learner' AND (rolsuper OR rolbypassrls)) THEN
  RAISE EXCEPTION 'Refusing an existing privileged teaching role';
 END IF;
END;
$body$;
CREATE TABLE lab26.notes(id integer PRIMARY KEY,project_id integer NOT NULL,body text NOT NULL);
INSERT INTO lab26.notes VALUES(1,1,'project one'),(2,2,'project two');
ALTER TABLE lab26.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab26.notes FORCE ROW LEVEL SECURITY;
GRANT USAGE ON SCHEMA lab26 TO course_rls_learner;
GRANT SELECT,INSERT,UPDATE,DELETE ON lab26.notes TO course_rls_learner;
CREATE POLICY project_scope ON lab26.notes TO course_rls_learner
USING(project_id=NULLIF(current_setting('app.project_id',true),'')::integer)
WITH CHECK(project_id=NULLIF(current_setting('app.project_id',true),'')::integer);
BEGIN;
SET LOCAL ROLE course_rls_learner;
SET LOCAL app.project_id='1';
SELECT current_user,rolsuper,rolbypassrls FROM pg_roles WHERE rolname=current_user;
SELECT * FROM lab26.notes ORDER BY id;
DO $body$
BEGIN
 IF (SELECT count(*) FROM lab26.notes)<>1
    OR EXISTS(SELECT 1 FROM lab26.notes WHERE project_id<>1) THEN
  RAISE EXCEPTION 'RLS must expose only project one to the teaching role';
 END IF;
END;
$body$;
INSERT INTO lab26.notes VALUES(3,1,'allowed insert');
UPDATE lab26.notes SET body='allowed update' WHERE id=3;
DO $body$
BEGIN
 BEGIN
  INSERT INTO lab26.notes VALUES(4,2,'must be rejected');
  RAISE EXCEPTION 'Expected cross-project insert to be rejected';
 EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'Expected RLS rejection observed';
 END;
END;
$body$;
DELETE FROM lab26.notes WHERE id=3;
COMMIT;
SELECT course_meta.assert_true((SELECT count(*) FROM lab26.notes)=2,'RLS exercise preserves fixture');
-- This setting-based context is a teaching mechanism, NOT authentication.
-- A client allowed to set arbitrary app.project_id can choose another tenant.

SELECT 'BONUS_26_PASSED' AS result;
