# 14. Sorting And Aggregation: worked answers

[Return to lesson](../lessons/14_sorting_and_aggregation.md)


## Worked answers

The algorithm must determine which candidates are in the best N. Keeping a small winning set can reduce memory without avoiding examination of the input. An ordered index can change that by making the desired rows available first.

No. A covering or ordered index can reduce other work while still scanning all relevant entries for the aggregate. The plan's actual rows reveal that consumption.

Multiple nodes, workers, and simultaneous statements can consume separate allocations. Hash operations also have a memory multiplier. Assess concurrency and the whole plan before changing a global setting.

## Expected evidence

The ordered feed can avoid a separate sort. Grouping can choose hashing or ordered processing depending on costs. The constrained full sort may spill, but no exact disk amount is mandated. Compare semantics independently of performance.

**DoneContract:** distinguish bounded output from bounded input, explain sorting and grouping setup costs, and propose a memory change only with a concurrency-aware justification.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 14
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [indexes ordering](https://www.postgresql.org/docs/17/indexes-ordering.html)
- [using explain](https://www.postgresql.org/docs/17/using-explain.html)
- [runtime config resource](https://www.postgresql.org/docs/17/runtime-config-resource.html)
- [functions aggregate](https://www.postgresql.org/docs/17/functions-aggregate.html)
