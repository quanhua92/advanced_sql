\set ON_ERROR_STOP on
-- Local teaching superuser is intentional: page inspection and WAL diagnostics.
-- No external extension build or package download is required by these labs.
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pageinspect;
CREATE EXTENSION IF NOT EXISTS pg_visibility;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
