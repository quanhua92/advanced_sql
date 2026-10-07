# 09. Partial Indexes And NULL: worked answers

[Return to lesson](../lessons/09_partial_indexes_and_null.md)


## Worked answers

Yes. The project parameter does not prevent proof of the fixed failure predicate. An unknown status in a generic plan is the problematic part of the example, not the mere presence of any parameter.

NOT IN must establish inequality against every member. Comparing against null yields unknown, so the overall predicate may not become true. NOT EXISTS with an explicit equality relation is often a clearer anti-join, but null treatment for the candidate side remains an application decision.

NULLS NOT DISTINCT makes null values conflict as equal for the declared uniqueness rule. It does not change all SQL comparisons with null, eliminate nulls from the table, or define what an unknown value means to the application.

## Design answer

For a queue, make the eligibility predicate explicit and stable. Use an index such as an ordered partial index restricted to queued rows, then claim atomically. Do not create one partial index per tenant simply to imitate a partitioning strategy without workload evidence.

**DoneContract:** prove partial-index eligibility for three query forms and explain their null behavior without relying on JavaScript/Python-style boolean intuition.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 9
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [indexes partial](https://www.postgresql.org/docs/18/indexes-partial.html)
- [functions comparisons](https://www.postgresql.org/docs/18/functions-comparisons.html)
- [functions comparison](https://www.postgresql.org/docs/18/functions-comparison.html)
- [ddl constraints](https://www.postgresql.org/docs/18/ddl-constraints.html)
