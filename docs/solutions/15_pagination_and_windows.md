# 15. Pagination And Windows: worked answers

[Return to lesson](../lessons/15_pagination_and_windows.md)


## Worked answers

The ID breaks timestamp ties, making the boundary unambiguous. A strict comparison excludes the already-seen row. Omitting the tie-breaker can skip or duplicate tied rows. Mixed directions and null values need different explicit handling.

No. Separate statements can see different committed data. Define live-feed or snapshot semantics explicitly. Updates to a sort key are particularly important because a row can cross a cursor boundary.

The default ordered frame includes peers according to the ORDER BY values. In the example, both rows with value 10 include their peer group, so both can show 20. A ROWS frame with a unique order advances one physical ordered row at a time and produces 10, 20, 40.

## Top-N answer

Use row_number for exactly N positions with a deterministic tie-breaker. Use rank-based rules when ties should expand the result. Compare a lateral indexed strategy for a small selected parent set against a window strategy for broader reporting.

**DoneContract:** design a complete cursor and consistency contract, prove page equivalence on static data, and predict ROWS/RANGE and ranking behavior on tied values.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 15
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [queries limit](https://www.postgresql.org/docs/17/queries-limit.html)
- [functions window](https://www.postgresql.org/docs/17/functions-window.html)
- [tutorial window](https://www.postgresql.org/docs/17/tutorial-window.html)
- [sql select](https://www.postgresql.org/docs/17/sql-select.html)
