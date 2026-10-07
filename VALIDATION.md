# Validation status

Verified 8 October 2026 with PostgreSQL 18.6 and Docker Compose 2.38.2. The package validator, nine CLI unit tests, Compose configuration, full SQL smoke suite, preserved legacy lab, and real multi-connection harness passed. The optional crash recovery exercise was not run. No benchmark speedups are claimed.

## Checks performed

`scripts/validate_package.py --checksums` checks the manifest, file inventory, local Markdown links, SQL include paths, Python syntax, lesson completion markers, bundled image files, Compose settings, the checksums, and preservation of the earlier extracted files. It is an offline package check, not a SQL parser.

`python scripts/course.py test` ran the bootstrap check, all 21 labs and matching solutions, all five supplements, and the capstone walkthrough and assertions. It cleaned lesson schemas as it went. The concurrency harness used distinct PostgreSQL connections and passed Read Committed, Repeatable Read, write skew, Serializable rejection, `SKIP LOCKED`, deadlock detection, old-version visibility across vacuum, and concurrent capstone claims.

The local image copies course files during build, so Compose needs no host port or source bind mounts. The helper copies the current host `sql/`, `scripts/`, and `legacy/` folders into the running container before executing lessons and suites.

## Repeat the checks

```sh
python scripts/validate_package.py --checksums
python -m unittest discover -s tests -v
docker compose config --quiet
docker compose up -d --build --wait
python scripts/course.py test
python scripts/course.py concurrency-test
```

The smoke suite excludes interactive prompts and the optional crash exercise. The concurrent schedules test specific examples and invariants; they are not a proof over every possible schedule or a production security audit.

## Reading runtime observations

A lesson may predict that an index makes an ordered lookup possible. It does not require PostgreSQL to choose that path on every machine. Runtime assertions focus on result semantics and state invariants, not fixed plan nodes, zero heap fetches, or timing thresholds. Storage, statistics, PostgreSQL patch version, cache state, and machine resources can affect observations.

The default 500,000-row fixture is the complete-suite baseline. Scale changes are supported for exploration, but some answer keys depend on default row IDs, distributions, and populated time windows. Run the baseline before treating a scaled-suite failure as an engine issue.

## Package boundaries

The PostgreSQL base image, database dump, external service integrations, premium course material, and third-party documentation snapshots are not bundled. The first image build needs internet access or a cached base image. External worker execution, authentication, and outbox delivery are outside the implemented teaching capstone.
