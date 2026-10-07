# Preserved earlier work

`00_course_map.md`, `01_index_lab.sql`, and `original_learning_pack.zip` are byte-for-byte copies of the earlier learning pack. Historical statements about validation describe that earlier delivery. The expanded package's current status is in `../VALIDATION.md`.

The earlier SQL lab creates a separate `sql_course_lab` schema and deliberately refuses to overwrite it. Run it with:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/legacy/01_index_lab.sql
```

It is optional and independent of the new shared dataset. To repeat it, explicitly remove **only** its teaching schema in this disposable database: `DROP SCHEMA sql_course_lab CASCADE;`. Never run this against an application database. The earlier first-lesson explanation has been incorporated and expanded in `docs/lessons/01_pages_and_btrees.md` and `docs/previous_discussion.md`.
