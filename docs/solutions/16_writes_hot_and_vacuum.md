# 16. Writes HOT And Vacuum: worked answers

[Return to lesson](../lessons/16_writes_hot_and_vacuum.md)


## Worked answers

The update must avoid changing values relevant to ordinary index maintenance, and the replacement tuple must fit on the same heap page. Check expression, included-column, and predicate dependencies, plus version-specific summarizing-index behavior.

The included value is stored index payload, so changing it requires maintaining that representation and can prevent HOT. Search-key status and maintenance obligations are different dimensions.

Vacuum makes space reusable and handles visibility and transaction-age maintenance. The allocated file need not shrink proportionally. Full compaction is a different operation with different locking and resource costs.

## Expected evidence

Both tables end with the intended logical updates. HOT counters and WAL measurements explain differing physical work, subject to statistics timing and page layout. The deleted-table count is the reliable semantic assertion; file size is an observation to interpret.

**DoneContract:** explain a mutation through row-version creation, index effects, page capacity, WAL, and later cleanup, without reducing it to a universal N-index write formula.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 16
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [storage hot](https://www.postgresql.org/docs/17/storage-hot.html)
- [routine vacuuming](https://www.postgresql.org/docs/17/routine-vacuuming.html)
- [storage page layout](https://www.postgresql.org/docs/17/storage-page-layout.html)
- [monitoring stats](https://www.postgresql.org/docs/17/monitoring-stats.html)
