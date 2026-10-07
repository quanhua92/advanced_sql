# 12. Covering And Visibility: worked answers

[Return to lesson](../lessons/12_covering_and_visibility.md)


## Worked answers

The scan can read projected values from the index but still need heap visibility checks when the visibility map cannot prove that the relevant page is all-visible. The node name describes an available value-access strategy, not a count of heap visits.

Included payload can satisfy a query's value requirements but does not extend the B-tree's search ordering. It consumes storage and participates in maintenance.

A heartbeat changes frequently, causing index updates and potentially preventing HOT for those updates. The read benefit must be compared with write amplification and visibility churn. A narrow query or separate stable history representation may be more appropriate.

## Expected evidence

Inspect actual Heap Fetches only when the chosen plan includes an Index Only Scan. Explain the observed visibility-map changes and account for concurrent activity. A timing improvement without that evidence does not establish the claimed mechanism.

**DoneContract:** distinguish covering, access-method capability, MVCC visibility, and measured heap avoidance; then defend each included column against its update cost.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 12
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [indexes index only scans](https://www.postgresql.org/docs/18/indexes-index-only-scans.html)
- [pgvisibility](https://www.postgresql.org/docs/18/pgvisibility.html)
- [storage vm](https://www.postgresql.org/docs/18/storage-vm.html)
- [storage hot](https://www.postgresql.org/docs/18/storage-hot.html)
