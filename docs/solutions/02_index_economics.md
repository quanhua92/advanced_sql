# 02. Index Economics: worked answers

[Return to lesson](../lessons/02_index_economics.md)


## Worked answers

A unique index may enforce a required invariant. Query scan counts do not measure that value. A short observation window can also miss periodic reads, and reset counters need interpretation.

The row input and table columns are controlled. The indexed table has three additional structures. Run order, cache residency, filesystem behavior, and background database activity are not fully controlled. Compare repeated fresh runs and record WAL and storage alongside latency.

An included value is still stored index data. Changing it requires maintaining the index representation and can disqualify a HOT update. `INCLUDE` separates search-key semantics from payload semantics, not read costs from all write costs.

## Design answer

For a failed-run feed, begin with a narrow candidate index aligned with project and ordering, possibly partial on the failure status. Compare it with a full status-aware index if other status feeds matter. Do not keep both merely because the lesson created both. Explain the supported workload for every retained structure.

**DoneContract:** present a read/write/storage/constraint inventory and a specific keep-or-remove decision. Distinguish a measured difference from a guaranteed write amplification factor.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 2
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [sql createindex](https://www.postgresql.org/docs/17/sql-createindex.html)
- [storage hot](https://www.postgresql.org/docs/17/storage-hot.html)
- [routine vacuuming](https://www.postgresql.org/docs/17/routine-vacuuming.html)
- [monitoring stats](https://www.postgresql.org/docs/17/monitoring-stats.html)
