# Validation status

Prepared 7 October 2026. The validation boundary matters: **Docker and PostgreSQL were not available in the preparation environment. No database lab, SQL solution, container initialization, crash test, or concurrency schedule was executed there.** No measured query plans or speedups are claimed.

## Local checks

The included `scripts/validate_package.py` checks the 21-lesson/five-supplement manifest, file existence, relative Markdown links, SQL include targets, Python parsing, required completion markers, baseline Compose fields, and byte-for-byte preservation of the earlier extracted files against their original archive. It is not a PostgreSQL SQL parser.

Additional preparation checks parse the Compose YAML, run the shell syntax checker, run the offline Python CLI unit tests, and inspect SQL lexical delimiters. These cannot establish database correctness. The recorded results are in [the preparation report](validation/preparation_report.json). Packaged checksums establish an unchanged file baseline, not correctness of its content.

## Run these locally

```sh
python scripts/validate_package.py --checksums
python -m unittest discover -s tests -v
docker compose up -d --wait
python scripts/course.py test
python scripts/course.py concurrency-test
```

`test` runs the bootstrap check, 21 labs and 21 matching solution scripts, five bonus scripts, and the capstone walkthrough/assertions. It drops each lesson's scratch tables after checking it and rebuilds the capstone. Do not run it while working in those schemas. It deliberately excludes interactive prompts and the optional crash experiment.

`concurrency-test` uses real distinct PostgreSQL backend connections. It tests the specified overlapping schedules and includes concurrent capstone claims when that schema is present. The capstone's deterministic SQL assertions alone are sequential, not a concurrency test. Neither test suite is a formal proof over all schedules or a production security audit.

## Expected result versus measured result

A lesson may predict that an index makes an ordered lookup possible. It does not require PostgreSQL to choose that path on every machine. Runtime assertions focus on result semantics and state invariants, not fixed plan nodes, zero heap fetches, or timing thresholds. Storage, statistics, PostgreSQL patch version, cache state, and machine resources can affect observations.

The default 500,000-row fixture is the complete-suite baseline. Scale changes are supported for exploration, but some answer keys depend on default row IDs, distributions, and populated time windows. Run the baseline before treating a scaled-suite failure as an engine issue.

## What the ZIP does not contain

The Docker image, a database dump, external service integrations, premium course material, and third-party documentation snapshots are not bundled. The first image pull needs internet or a cached image. External worker execution, authentication, and outbox delivery are explicitly outside the implemented teaching capstone. These boundaries are documented rather than represented as completed features.
