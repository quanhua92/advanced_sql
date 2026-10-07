# 11. Hash And Merge Joins: worked answers

[Return to lesson](../lessons/11_hash_and_merge_joins.md)


## Worked answers

Underestimated cardinality or row width can make the actual hash structure exceed the planned memory expectation. A deliberately small work_mem can also cause batching. Inspect actual batch and temporary-I/O evidence rather than guessing from the join name.

Input sorts can dominate a merge plan. Existing useful order may remove that setup cost, but an index scan can introduce other costs such as heap access. Compare the full plan.

Duplicate join keys can produce a large number of row combinations. An unintended many-to-many join changes the answer, not merely its speed. Check key constraints and the desired multiplicity before buying more memory for it.

## Expected evidence

All equivalent join formulations must preserve counts or aggregates. Node families and timings can vary. The solution uses relational equality checks to guard the answer and leaves performance conclusions to the collected plans.

**DoneContract:** account for build/probe or sort/merge work, identify memory pressure, and explain the role of row estimates and output multiplicity.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 11
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [using explain](https://www.postgresql.org/docs/18/using-explain.html)
- [runtime config resource](https://www.postgresql.org/docs/18/runtime-config-resource.html)
- [planner stats](https://www.postgresql.org/docs/18/planner-stats.html)
- [queries table expressions](https://www.postgresql.org/docs/18/queries-table-expressions.html)
