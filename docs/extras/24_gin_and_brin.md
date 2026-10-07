# 24. GIN and BRIN: choose a representation, not a fashionable acronym

B-tree indexes order keys. GIN indexes support inverted representations appropriate to selected multi-component values and operators. BRIN indexes summarize ranges of physically adjacent pages. They solve different search problems and have different false-positive and maintenance behavior.

The JSONB experiment uses containment, asking whether metadata contains a particular model and region combination. A GIN index with `jsonb_path_ops` supports a specific operator family; it is not interchangeable with the default JSONB operator class for every query. Match the operator class to the queries, including whether key-existence operators are required. A targeted expression B-tree can be a simpler alternative for a frequently queried scalar field.

Do not index all metadata merely because it is JSONB. Large values and frequent updates can make that choice expensive. If a field becomes a central filtering or integrity attribute, a typed column may provide clearer constraints and statistics. JSON flexibility does not remove schema design.

The BRIN experiment exploits the seed's physical correlation: IDs are inserted in order and timestamps increase with ID. A small timestamp range can rule out many page ranges using their summaries. BRIN then rechecks candidate rows; it is intentionally lossy rather than a tuple-by-tuple exact lookup map.

`pages_per_range` trades summary precision against index size. Smaller ranges usually create more summaries and can exclude data more precisely. New ranges require summarization, which the lab inspects explicitly. Autosummarize is an operational aid, not a promise of synchronous summary creation for every new page.

Disordered backfills can widen timestamp summaries and reduce pruning effectiveness. A tiny BRIN index is not proof that its queries are cheap. Compare candidate heap pages, rechecks, and the amount of ordering still required. BRIN does not supply a chronological top-N order the way a suitable B-tree can.

For the platform, JSONB metadata search and append-oriented event-history filtering are plausible distinct uses. A high-frequency queue claim still needs its own access and ownership design. Do not replace every B-tree with GIN or BRIN because one synthetic case looks attractive.

**Exercise:** explain why the BRIN index is small and why it may return extra candidates. Then change the JSON query from containment to key existence and identify whether the chosen operator class supports it.

**Worked answer:** BRIN stores summaries per page range rather than an exact entry for every row. The selected JSONB operator class has a narrower operator set than the default; a different query may need a different index or no index.

**DoneContract:** justify the indexed representation, supported operators, and maintenance assumptions for each workload.

References: [BRIN](https://www.postgresql.org/docs/18/brin.html), [JSONB indexing](https://www.postgresql.org/docs/18/datatype-json.html), [GIN](https://www.postgresql.org/docs/18/gin.html).

## Run

```sh
python scripts/course.py bonus 24
```

[Executable lab](../../sql/extras/24_gin_and_brin.sql). This bonus includes its own assertions or diagnostic queries. Re-running resets its own teaching schema where one is needed; the monitoring bonus is read-only apart from ordinary statistics collection.
