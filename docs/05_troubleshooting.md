# Troubleshooting

## Docker does not start or Compose rejects an option

Check that Docker is installed and its engine is running. This package uses Compose v2 through `docker compose`, not the historical `docker-compose` binary. Inspect `docker compose version` and `docker compose config`. If an older installation lacks `--wait`, start with `docker compose up -d`, inspect `docker compose ps`, and wait for the service to become healthy before running SQL.

## Connect to the database

The database has no published host port. Connect from inside the container with `docker compose exec postgres psql -X -U course -d advanced_sql`; the Python helper uses the same route. This avoids conflicts with another PostgreSQL server using port 5432.

## Health remains unhealthy

Run `docker compose logs --tail=150 postgres`. The healthcheck requires TCP readiness and `course_meta.installation.ready = true`. A seed failure can leave a nonempty volume without a completed dataset; initialization does not automatically restart from the first script on the next boot. For a disposable new installation, correct the error and use the explicit reset command. Do not delete a volume containing work you need.

Check available disk and memory before increasing seed size. Read the first database error, not only the final health timeout. Increasing the wait timeout does not fix SQL errors or a full disk.

## Password changes appear ignored

Initialization environment variables apply to an empty data directory. Editing `.env` does not rewrite the password of the existing `course` role. Restore the original local setting, explicitly change the role password from an authorized connection, or reset this disposable volume. A password containing Compose interpolation characters should be handled according to Compose's environment-file rules; the included local-only example avoids that complication.

## SQL files fail in a GUI

The files intentionally contain `psql` commands such as `\ir`, `\gset`, `\if`, and `\prompt`. A GUI's SQL editor usually does not implement them. Execute the files through the included `psql` commands, or copy individual SQL statements while understanding the omitted setup. Do not enable a GUI option that wraps the entire file in a transaction.

## “Current transaction is aborted”

Run `ROLLBACK;` in that session. The deadlock and serializable exercises deliberately trigger errors. Their schedules explain which errors are expected. Unexpected errors in ordinary labs should stop execution; do not disable `ON_ERROR_STOP` to conceal them.

## A different plan appears

That alone is not a failure. Compare the version, seed size, indexes, visibility state, statistics, settings, row counts, and workload. PostgreSQL chooses among available paths. This package tests semantic invariants rather than requiring a particular number of milliseconds or universal plan node. Diagnostic switches can illustrate an alternative without making it a production recommendation.

## Relation missing, or solution assertion fails

Run the matching lab before its solution. Check whether a smoke run or `clean` command removed the scratch table. Do not run two copies of the same lesson at once. Return to the default 500,000-row seed when testing the complete suite. Some worked checks intentionally depend on that fixture.

## RLS shows every row

Verify `current_user`, `rolsuper`, and `rolbypassrls`. The default course connection is a superuser and bypasses RLS. Bonus 26 switches to `course_rls_learner` inside a transaction; that role is the relevant test subject. A caller-supplied tenant setting is not authentication.

## Concurrency tests hang or time out

Do not leave unrelated manual transactions open. Inspect `pg_stat_activity`, `pg_blocking_pids`, and the monitor script. The automated harness uses bounded statement and lock timeouts and reports unexpected errors as failures. A timeout is not a substitute for observing the intended deadlock or serialization error. Close abandoned clients and retry the setup when no experiment sessions are active.

Sources: [Docker initialization](https://hub.docker.com/_/postgres), [Compose up](https://docs.docker.com/reference/cli/docker/compose/up/), [psql](https://www.postgresql.org/docs/18/app-psql.html), [RLS](https://www.postgresql.org/docs/18/ddl-rowsecurity.html).
