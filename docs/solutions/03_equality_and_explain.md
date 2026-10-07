# 03. Equality And Explain: worked answers

[Return to lesson](../lessons/03_equality_and_explain.md)


## Worked answers

Approximately 2,000 rows were emitted across the node's executions, subject to rounding. Do not add inclusive ancestor/descendant times or buffer counts as though they described independent work. For parallel plans, inspect worker information before applying this arithmetic blindly.

Find the earliest cardinality divergence. Inspect the predicate's distribution, statistics freshness, and relevant column dependence before blaming the join algorithm. Bonus lesson 22 gives a deliberately correlated dataset for this purpose.

`ANALYZE` in the EXPLAIN option means execute and measure. An UPDATE really updates rows. Even when rolled back, not every side effect is undone or free. The course isolates these experiments rather than applying them to a live application.

## Expected observations

The primary-key equality has an appropriate lookup index. The project query returns many rows and can choose an ordinary or bitmap path after indexing. Neither shape is mandatory. The solution verifies that indexed filtering preserves the selected IDs and collects the plan again.

**DoneContract:** annotate an unfamiliar plan with required result size, estimate errors, repeated work, buffer interpretation, and the evidence supporting a proposed change.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 3
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [using explain](https://www.postgresql.org/docs/18/using-explain.html)
- [sql explain](https://www.postgresql.org/docs/18/sql-explain.html)
- [planner stats](https://www.postgresql.org/docs/18/planner-stats.html)
- [monitoring stats](https://www.postgresql.org/docs/18/monitoring-stats.html)
