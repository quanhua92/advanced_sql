# EXPLAIN field guide

```sql
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, SETTINGS)
SELECT id FROM course.runs WHERE project_id=42 ORDER BY created_at DESC, id DESC LIMIT 20;
```

`EXPLAIN` without `ANALYZE` plans but does not execute the query. `ANALYZE` executes it, including writes. `TIMING OFF` avoids per-node timing overhead while retaining total execution timing. `FORMAT JSON` is useful for programmatic inspection; JSON structure does not turn planner costs into milliseconds.

| Evidence | Question |
|---|---|
| Estimated versus actual rows | Is the planner making a cardinality mistake? |
| Loops | Is small inner work repeated many times? |
| Index Cond versus Filter | What narrows index access, and what is rejected later? |
| Rows Removed by Filter | How much visited data is discarded? |
| Sort Method / Disk | Was ordering in memory, top-N, or spilled? |
| Hash Batches / memory | Did the hash operation partition or spill? |
| Heap Fetches | Did an index-only scan still need heap visibility checks? |
| Buffers hit/read/dirtied/written | What buffer activity occurred, without equating reads to device I/O? |
| WAL records/bytes | What write logging was measured for an executed statement? |
| Lock/wait monitoring | Was elapsed time dominated by waiting elsewhere? |

A Bitmap Heap Scan visits heap pages using a bitmap and does not preserve B-tree ordering. Lossy bitmap pages require rechecking candidates. An Index Scan can avoid sorting yet still do substantial heap work. An Index Only Scan's name does not guarantee zero heap fetches. A Sequential Scan is not automatically a mistake.

Node measurements can include child work and be averaged over loops. Avoid summing inclusive totals. The planner's estimated width is not an exact memory or disk allocation report. Be careful when comparing executions around data changes, vacuum, caching, or different parameters.

For a surprising plan, verify the query's result contract, inspect predicates and statistics, check parameter planning, then compare plausible alternatives. Do not start by globally disabling the chosen scan type.

Sources: [Using EXPLAIN](https://www.postgresql.org/docs/18/using-explain.html), [EXPLAIN syntax](https://www.postgresql.org/docs/18/sql-explain.html).
