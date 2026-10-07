# Advanced SQL: PostgreSQL Performance, Internals, and Reliable Workflows

**An original, runnable self-study course aligned with the 21 publicly advertised topic areas of Sydexa's Advanced SQL course.** Includes all earlier work, expanded explanations, experiments, worked answers, and a local PostgreSQL environment. This is not a copy of paid lessons or videos, and it does not claim access to inaccessible premium material.

**Start reading:** [Start here](docs/00_start_here.md) → [Course map](docs/01_course_map.md) → [Lesson 1](docs/lessons/01_pages_and_btrees.md).

**Validation:** Read [VALIDATION.md](VALIDATION.md). The full PostgreSQL smoke suite and real concurrency harness passed on PostgreSQL 18.6, alongside the offline package and CLI checks. No benchmark results are invented.

## 1. Start PostgreSQL

Extract the ZIP, open a terminal in the `advanced_sql` folder, and start Docker with Compose v2 available:

```sh
docker compose up -d --build --wait
```

The first start builds a local image from the official PostgreSQL 18 image, creates a new `postgres18_data` volume, installs the included extensions, and seeds 500,000 synthetic runs. The image itself is **not inside the ZIP**; first startup needs internet access or an already-cached base image. Course files are copied into the image, so startup does not depend on host directory mounts. Initialization scripts run only when the data directory is empty. Existing PostgreSQL 17 data volumes are left untouched; a major-version upgrade requires a deliberate dump/restore or `pg_upgrade` procedure.

Open a database terminal:

```sh
docker compose exec postgres psql -X -U course -d advanced_sql
```

Inside `psql`, run lesson 1:

```sql
\i /course/sql/labs/01_pages_and_btrees.sql
```

Exit `psql` with `\q`. Never run all course SQL inside one transaction: some experiments use `VACUUM` and concurrent index operations.

## 2. Optional Python helper

Python 3.10 or newer, standard library only. No `pip install` is needed. On systems whose command is `python3`, substitute it for `python`.

```sh
python scripts/course.py lab 1
python scripts/course.py solution 1
python scripts/course.py bonus 22
python scripts/course.py capstone
```

The helper copies the current `sql/`, `scripts/`, and `legacy/` folders into the container before running a command, then saves run logs to `outputs/`. Run a solution after its matching lab. Each lab rebuilds only its own `labNN` schema; rerunning a lab discards your changes in that schema. The shared `course` dataset remains unchanged. Do not run/reset the same lesson concurrently.

## 3. Check the installation and exercise the package

```sh
python scripts/validate_package.py
python scripts/course.py test
python scripts/course.py concurrency-test
```

The first command runs **offline structural checks**, not PostgreSQL. The second runs 21 labs, their 21 solution scripts, five bonuses, and the capstone's deterministic assertions. It cleans lesson schemas as it goes to limit retained disk usage. The third opens actual concurrent database connections to test snapshots, write skew, serialization failure, skipped locks, deadlocks, and old-version visibility. Run the capstone first to include its concurrent-claim test; the smoke test already does this.

Without host Python, run the SQL smoke test directly:

```sh
docker compose exec -T postgres sh /course/scripts/smoke.sh
```

Manual concurrency schedules are in [the concurrency guide](docs/concurrency.md). Crash recovery is a separate, explicitly optional exercise, not part of automatic tests.

## 4. Connection settings

| Setting | Local teaching value |
|---|---|
| Access | `docker compose exec postgres psql -X -U course -d advanced_sql` |
| Database | `advanced_sql` |
| User | `course` |
| Password | `course_local_only` |
| Baseline | PostgreSQL 18, official `postgres:18-bookworm` image family |

These credentials belong to a disposable **teaching superuser**, not a production account. The database is not published on a host port; use `docker compose exec` so it does not conflict with a local PostgreSQL service. Do not load sensitive data. Optional image and password overrides are documented in `.env.example`; defaults work without creating `.env`. Changing the environment password does not change an already-initialized database role.

## 5. What is included

```text
advanced_sql/
├── README.md, VALIDATION.md, CONTENTS.md
├── .dockerignore, Dockerfile, docker-compose.yml, .env.example, Makefile
├── docker/init/                 First-start database bootstrap
├── docs/
│   ├── lessons/                 21 complete teaching chapters
│   ├── solutions/               21 worked answer keys and DoneContracts
│   ├── extras/                  Statistics, monitoring, GIN/BRIN, migrations, RLS
│   ├── capstone/                Requirements and reference queue design
│   ├── reference/               EXPLAIN, indexes, patterns, glossary, sources
│   └── templates/               Experiment log, progress, index decision record
├── sql/
│   ├── setup/ and lib/          Dataset, extensions, guards, assertion helper
│   ├── labs/ and solutions/     Executable lesson experiments and checks
│   ├── concurrency/             Coordinated two-session exercises
│   ├── extras/                  Five supplementary experiments
│   ├── capstone/                Lease-based worker queue and invariant checks
│   └── tests/                   Bootstrap checks
├── scripts/                     Cross-platform CLI and test harnesses
├── legacy/                      Earlier map, SQL lab, and original ZIP unchanged
├── outputs/                     Your evidence logs
└── backups/                     Your optional logical backups
```

## 6. Stop, clean, or reset

```sh
python scripts/course.py down
python scripts/course.py clean 1
```

`down` stops/removes the service container but preserves the named data volume. `clean 1` removes only lesson 1's scratch tables. To **delete the course volume and everything stored in it**, including any restore database, and initialize afresh:

```sh
python scripts/course.py reset --yes
```

Back up anything you need first. Read [operating the lab](docs/06_operating_the_lab.md) before resets, reseeding, restore rehearsals, or crash experiments.

## Learning goal

Do not memorize “an index is faster.” Learn to explain which work an access path removes, which work remains, which writes become more expensive, and which concurrency guarantees your application actually needs. The final capstone applies that reasoning to a durable workflow queue with project scope, CPU/GPU pools, leases, attempt limits, ownership checks, events, and a transactional outbox.
