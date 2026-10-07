\set ON_ERROR_STOP on
CREATE SCHEMA IF NOT EXISTS course_meta;
CREATE TABLE IF NOT EXISTS course_meta.installation (
  id integer PRIMARY KEY CHECK (id=1),
  package_version text NOT NULL,
  ready boolean NOT NULL DEFAULT false,
  seeded_runs bigint NOT NULL DEFAULT 0,
  installed_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
INSERT INTO course_meta.installation(id,package_version,ready)
VALUES (1,'1.0.0',false)
ON CONFLICT(id) DO UPDATE SET ready=false,package_version=EXCLUDED.package_version;

CREATE SCHEMA IF NOT EXISTS course;
CREATE TABLE IF NOT EXISTS course.projects (
  id integer PRIMARY KEY,
  name text NOT NULL,
  owner_email text NOT NULL
);
CREATE TABLE IF NOT EXISTS course.workflows (
  id integer PRIMARY KEY,
  project_id integer NOT NULL REFERENCES course.projects(id),
  name text NOT NULL,
  UNIQUE(id,project_id)
);
CREATE TABLE IF NOT EXISTS course.runners (
  id integer PRIMARY KEY,
  name text NOT NULL,
  pool text NOT NULL CHECK(pool IN ('cpu','gpu'))
);
CREATE TABLE IF NOT EXISTS course.runs (
  id bigint PRIMARY KEY,
  project_id integer NOT NULL REFERENCES course.projects(id),
  workflow_id integer NOT NULL,
  runner_id integer REFERENCES course.runners(id),
  status text NOT NULL CHECK(status IN ('queued','running','succeeded','failed')),
  created_at timestamptz NOT NULL,
  duration_ms integer NOT NULL CHECK(duration_ms>=0),
  priority integer NOT NULL DEFAULT 0,
  error_code text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  payload text NOT NULL,
  FOREIGN KEY(workflow_id,project_id) REFERENCES course.workflows(id,project_id)
);
CREATE TABLE IF NOT EXISTS course.run_events (
  id bigint PRIMARY KEY,
  run_id bigint NOT NULL REFERENCES course.runs(id),
  project_id integer NOT NULL REFERENCES course.projects(id),
  created_at timestamptz NOT NULL,
  kind text NOT NULL,
  details jsonb NOT NULL
);

-- Explicitly restrict lesson resets to a small teaching-schema namespace.
CREATE OR REPLACE FUNCTION course_meta.reset_lab(p_schema text, p_copy_runs boolean DEFAULT true)
RETURNS void LANGUAGE plpgsql AS $body$
BEGIN
  IF p_schema !~ '^lab(0[1-9]|1[0-9]|2[0-6])$' THEN
    RAISE EXCEPTION 'Not an allowed lesson schema: %',p_schema;
  END IF;
  IF NOT COALESCE((SELECT ready FROM course_meta.installation WHERE id=1),false) THEN
    RAISE EXCEPTION 'Course installation not ready; finish bootstrap first';
  END IF;
  EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE',p_schema);
  EXECUTE format('CREATE SCHEMA %I',p_schema);
  IF p_copy_runs THEN
    -- LIKE deliberately omits indexes, constraints, and defaults. Each lesson
    -- starts with exactly one primary-key index, independent of earlier lessons.
    EXECUTE format('CREATE TABLE %I.runs (LIKE course.runs)',p_schema);
    EXECUTE format('INSERT INTO %I.runs SELECT * FROM course.runs ORDER BY id',p_schema);
    EXECUTE format('ALTER TABLE %I.runs ADD PRIMARY KEY(id)',p_schema);
    EXECUTE format('ANALYZE %I.runs',p_schema);
  END IF;
END;
$body$;


CREATE OR REPLACE FUNCTION course_meta.assert_true(condition boolean, message text)
RETURNS void LANGUAGE plpgsql AS $body$
BEGIN
  IF condition IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Assertion failed: %',message;
  END IF;
END;
$body$;
