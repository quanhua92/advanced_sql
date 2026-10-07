# 10. Nested Loop Joins: worked answers

[Return to lesson](../lessons/10_nested_loop_joins.md)


## Worked answers

A small outer set and an inner ordered index probe with LIMIT can bound the work for each workflow. The important terms are outer cardinality and per-probe work, not the join label.

The cross form drops a workflow when the inner query has no rows. The left form preserves it with null run columns. Test this with a deliberately empty workflow rather than relying on the seed, which is likely to populate all workflows.

Application N+1 introduces multiple client/server requests. A nested loop is internal execution of one statement. Either can still cause excessive server work if the lookup path is poor, but the network and snapshot implications differ.

## Plan explanation

Report the number of selected workflows, the inner loop count, rows obtained per probe, and whether the requested order allowed early termination. Compare a window-function formulation without assuming it is automatically better. Large outer sets can change the tradeoff.

**DoneContract:** choose join semantics that preserve the product requirement, then explain repeated inner work using the actual plan and a suitable index.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 10
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [queries table expressions](https://www.postgresql.org/docs/17/queries-table-expressions.html)
- [using explain](https://www.postgresql.org/docs/17/using-explain.html)
- [indexes multicolumn](https://www.postgresql.org/docs/17/indexes-multicolumn.html)
- [sql select](https://www.postgresql.org/docs/17/sql-select.html)
