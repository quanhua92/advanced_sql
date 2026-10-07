# Start here

This course is mostly about database performance and correctness, not increasingly ornate SQL syntax. Its recurring application is a workflow platform: projects submit work, runners execute it, and dashboards read growing run histories. The dataset is synthetic and the schema is intentionally small enough to inspect.

## What you need first

Be comfortable reading a `SELECT`, a filter, a join, and an aggregate. [The SQL refresher](04_sql_refresher.md) supplies the minimum vocabulary. You do not need to know database internals. Docker with Compose v2 is the runtime dependency; host Python is optional unless you use the helper or automated multi-connection harness.

Start the database from [the root README](../README.md). Run the bootstrap check before changing anything:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/tests/bootstrap_check.sql
```

Record `SELECT version()` and the seed count. The image tag tracks PostgreSQL 18 patch releases, so record its digest too when comparing runs over time. The package guards against silently running a different major version.

## The lesson loop

First read the practical question and inspect the SQL without executing it. Write one prediction: an expected result, access-path opportunity, or concurrency outcome. Then run one section, inspect evidence, and explain the difference between your prediction and observation. Only then open the worked answers. Each answer key ends with a **DoneContract**, a concrete demonstration of understanding rather than a video-watching checkbox.

Use [the experiment template](templates/experiment.md). Save plans and actual outputs in `outputs/`; do not replace evidence with a remembered timing. A lab's `LAB_NN_COMPLETED` marker means execution reached the end. A solution's `SOLUTION_NN_PASSED` marker means its programmed checks passed. Neither substitutes for explaining why the behavior occurred.

## Two reading routes

The foundation route is lessons 1–16 in order, then the coordinated transactions in 17–19, followed by recovery and partitioning in 20–21. Finish with the bonuses and capstone.

For immediate workflow-platform relevance, study 1, 3, 4, 9, 12, and 15 for dashboard/index design, then 17–20 for runner correctness and durability. Return to the skipped foundations before making broad performance decisions. The capstone expects those mechanisms; it is not a shortcut around them.

## What completion looks like

For an unfamiliar query, you can state the required result, propose two plausible access paths, identify a semantic trap, inspect estimates and actual work, and defend an index decision including its write cost. For overlapping workers, you can specify the transaction boundary, reproduce a failure schedule, and explain how retries and lease ownership affect correctness.

[Course map](01_course_map.md) · [Lab method](03_lab_method.md) · [Dataset](02_database_and_dataset.md) · [Troubleshooting](05_troubleshooting.md)
