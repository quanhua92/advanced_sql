# Operating the disposable lab

## Storage and lifecycle

The named volume holds database data; bind-mounted `sql`, `scripts`, and `legacy` folders are read-only inside the container. `outputs` and `backups` are host folders written by the optional Python helper. `docker compose down` preserves the named volume. `docker compose down -v` deletes it. This project deliberately fixes a Compose project name, so a second extracted copy is not automatically a separate installation.

Keep one active copy of the project unless you deliberately understand Compose project names, ports, and volumes. Do not connect these scripts to an application database. The session guard checks the database name, major version, and installation marker, but a guard is not a substitute for maintaining a separate environment.

Measure current size:

```sql
SELECT pg_size_pretty(pg_database_size(current_database()));
SELECT n.nspname, pg_size_pretty(sum(pg_total_relation_size(c.oid))::bigint)
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE c.relkind IN ('r','m') AND n.nspname NOT IN ('pg_catalog','information_schema')
GROUP BY n.nspname ORDER BY sum(pg_total_relation_size(c.oid)) DESC;
```

Full lesson copies and indexes accumulate. `python scripts/course.py clean 4` recreates an empty `lab04` schema. The smoke test cleans each lesson after checking it. Do not clean while another session uses that schema.

## Reseed versus full reset

`python scripts/course.py reseed --rows 500000 --yes` removes known scratch schemas and replaces the shared dataset. It does not remove the legacy schema. It temporarily makes the readiness marker false. Do not reseed while experiments are running.

`python scripts/course.py reset --yes` removes the entire named volume and starts a fresh installation. Every database in that volume is deleted, including `advanced_sql_restore`. Host evidence and backup files remain, but that is not a promise that your SQL state is recoverable without a valid backup.

## Logical backup and restore rehearsal

```sh
python scripts/course.py backup
```

The helper writes a custom-format `pg_dump` archive to `backups/` using a binary file handle. This avoids binary redirection pitfalls in some shells. Stop active experiments first for a simple teaching rehearsal, then use the printed filename:

```sh
python scripts/course.py restore backups/REPLACE_WITH_THE_PRINTED_FILENAME.dump --yes
```

The filename above is a template, not an included dump. Restore creates `advanced_sql_restore` and refuses to overwrite an existing database of that name. It loads the dump there with owner/privilege restoration disabled and reports restored rows. It does **not** overwrite `advanced_sql`. A failed restore may leave the rehearsal database present; inspect it before deliberately removing and retrying.

This same-cluster rehearsal is not a complete disaster-recovery design. A single-database dump does not include cluster-global roles. Policies referring to roles require those roles to exist when restoring elsewhere. Physical backups, continuous WAL archiving, point-in-time recovery, credentials, and off-machine retention need additional operational design. Restore success should include application-specific validation, not just a file existing on disk.

## Optional controlled process-crash exercise

Only perform this against the isolated course service. Close all other course sessions first. Run lesson 20 and its solution, and independently note the committed recovery marker and row counts:

```sh
python scripts/course.py lab 20
python scripts/course.py solution 20
```

The following intentionally terminates the database server process without graceful shutdown. It is not part of the automatic smoke test:

```sh
docker compose kill -s SIGKILL postgres
docker compose up -d --wait
docker compose logs --tail=100 postgres
```

Reconnect and inspect `lab20.durability_marker` and the logged/unlogged tables by the actual names in [the lab](../sql/labs/20_wal_and_recovery.sql). The committed logged marker should survive recovery. Unlogged table contents are not protected across crash recovery and are expected to be reset after an unclean shutdown. The pre-crash solution expects the original unlogged count, so do not run it after the crash without first rebuilding the lab.

This tests process-crash recovery on your current storage stack. It does not simulate every power-loss, torn-write, hardware-cache, filesystem, or backup-loss failure. Do not disable `fsync` or `full_page_writes` to obtain an attractive benchmark. A WAL mechanism is not a backup strategy.

Sources: [Backup](https://www.postgresql.org/docs/17/backup.html), [pg_dump](https://www.postgresql.org/docs/17/app-pgdump.html), [pg_restore](https://www.postgresql.org/docs/17/app-pgrestore.html), [unlogged tables](https://www.postgresql.org/docs/17/sql-createtable.html), [WAL reliability](https://www.postgresql.org/docs/17/wal-reliability.html).
