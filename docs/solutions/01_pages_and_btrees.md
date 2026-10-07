# 01. Pages And B-Trees: worked answers

[Return to lesson](../lessons/01_pages_and_btrees.md)


## Worked answers

The tree height describes initial navigation. Cached pages need no storage-device read, while a range can traverse many leaf pages and fetch many heap pages. Neither the number of results nor tree height is a complete cost model.

The page calculation asks whether any of 80 independent rows matches. Its complement is the event that all 80 fail to match. Real data can violate both the independence and occupancy assumptions, so use this as a counterexample to a simplistic rule, not a measured model of your server.

Removing the status equality leaves multiple status groups, each ordered by time. Their concatenation is not globally time-ordered. A separate `(project_id, created_at DESC, id DESC)` index can supply that order. A plan may sort or use another strategy; the original index is not categorically unusable for filtering.

## What a convincing lab report contains

Save the two actual plans and the metadata output. Identify the first stage where work is reduced. If PostgreSQL chooses a different path from your prediction, investigate statistics and the data size rather than forcing the desired screenshot. The solution SQL verifies that the two query formulations select the same set and measures both indexes; it does not assert a timing threshold.

**DoneContract:** explain the dashboard query as a sequence of navigation, entry inspection, heap access, visibility, ordering, and termination. Explain what changes when `LIMIT`, selected columns, or the status filter changes.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 1
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [storage page layout](https://www.postgresql.org/docs/18/storage-page-layout.html)
- [btree](https://www.postgresql.org/docs/18/btree.html)
- [pageinspect](https://www.postgresql.org/docs/18/pageinspect.html)
- [indexes ordering](https://www.postgresql.org/docs/18/indexes-ordering.html)
