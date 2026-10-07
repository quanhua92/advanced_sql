# Database and synthetic dataset

## Shared schema

```text
course.projects (100)
  └─ course.workflows (500, five per project)
       └─ course.runs (500,000 by default)
            ├─ course.runners (20, nullable run assignment)
            └─ course.run_events (one event per fifth run)
```

`runs` contains `id`, `project_id`, `workflow_id`, `runner_id`, `status`, `created_at`, `duration_ms`, `priority`, `error_code`, `metadata`, and `payload`. A composite foreign key ensures a run's workflow belongs to the stated project. `metadata` holds a model, region, and synthetic trace. `payload` is a repeated MD5-derived text string, not a real log. Integer identifiers make experiments easier to inspect; they are not a recommendation to replace your application's UUID strategy.

For the default seed, statuses are exactly 1% failed, 5% queued, 9% running, and 85% succeeded. Those ratios follow deterministic ID residues. Project and workflow selection use seeded pseudorandom draws independently of the status residue, avoiding accidental tenant/status correlation. Other relationships remain intentionally synthetic: time follows ID, priority follows an ID residue, and all events represent just one sampled status observation. This is not a realistic production lifecycle dataset.

Creation time starts at 2026-01-01 00:00:00 UTC plus ten seconds per run ID. A larger seed extends the time range; it does not merely pack more rows into the original range. All sessions default to UTC. Local calendar-day questions require explicit timezone semantics, illustrated in lesson 6. Do not compare different seed sizes as though the workload and selectivity were unchanged.

## Isolation between experiments

The shared `course` schema is the source dataset. Most lessons call `course_meta.reset_lab('labNN')`, which validates a tightly bounded schema name, recreates that scratch schema, copies runs, adds an ID primary key, and analyzes the copy. The copy deliberately does not inherit all base indexes and constraints. Some lessons instead create smaller, purpose-built fixtures.

Consequently, an index made in lesson 4 cannot contaminate lesson 5's plans. A solution assumes its lab has already run. Running a lab again resets its prior work. The smoke runner removes each lesson's scratch tables after checking it, reducing retained disk usage. Manually retaining many full copies costs storage; measure it rather than estimating solely from row count.

## Extensions and settings

The image initializes `pg_stat_statements`, `pageinspect`, `pg_visibility`, and `pg_trgm`. These support monitoring, physical-page inspection, visibility-map inspection, and trigram experiments. The teaching user is privileged because some inspection and maintenance operations require it. The RLS bonus deliberately switches to an unprivileged role to demonstrate why testing as a superuser is misleading.

Server defaults include 128 MB shared buffers, 8 MB `work_mem`, 128 MB maintenance memory, 50 connections, timing instrumentation, UTC, and loaded statement statistics. Lab sessions disable parallel query and JIT to reduce one source of variation. These are lab choices, not tuning recommendations. `work_mem` is not a fixed per-server cap: individual operations and workers can each consume memory.

## Changing scale

The helper accepts 10,000 through 5,000,000 rows and removes known scratch schemas before reseeding:

```sh
python scripts/course.py reseed --rows 100000 --yes
```

This destroys all lesson, capstone, and manual-concurrency progress but preserves the separate legacy schema. Use the default 500,000 rows for the published exercises: some predicates, IDs, and partition windows become empty on smaller seeds. A smaller seed is useful for exploration, not a guarantee that every answer-key assertion remains applicable. Running all tests at a nondefault scale is not claimed to work.

Sources: [Physical page layout](https://www.postgresql.org/docs/18/storage-page-layout.html), [resource consumption](https://www.postgresql.org/docs/18/runtime-config-resource.html), [Docker image initialization](https://hub.docker.com/_/postgres).
