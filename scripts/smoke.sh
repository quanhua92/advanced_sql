#!/bin/sh
# Run inside the postgres service. Resets teaching schemas, not the base dataset.
set -eu
export PGAPPNAME=advanced_sql_smoke
run() {
  printf '\n===== %s =====\n' "$1"
  psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f "$1"
}
run /course/sql/tests/bootstrap_check.sql
for lab in /course/sql/labs/[0-9][0-9]_*.sql; do
  name=$(basename "$lab")
  number=${name%%_*}
  run "$lab"
  run "/course/sql/solutions/$name"
  psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -c \
    "SELECT course_meta.reset_lab('lab$number', false);"
done
for lab in /course/sql/extras/[0-9][0-9]_*.sql; do
  name=$(basename "$lab")
  number=${name%%_*}
  run "$lab"
  psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -c \
    "SELECT course_meta.reset_lab('lab$number', false);"
done
run /course/sql/capstone/run_all.sql
printf '\nSMOKE_PASSED: 21 labs, 21 solution scripts, 5 bonuses, capstone assertions.\n'
printf 'Manual concurrency, actual concurrent schedules, and crash recovery are separate tests.\n'
