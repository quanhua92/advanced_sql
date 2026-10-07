# 07. Parameters And Plan Cache: worked answers

[Return to lesson](../lessons/07_parameters_and_plan_cache.md)


## Worked answers

Binding separates values from SQL grammar and prevents those values from being interpreted as SQL structure through that channel. It does not guarantee the best access path for every value, remove authorization checks, or make dynamic identifiers safe.

Automatic planning compares estimated costs using PostgreSQL's prepared-plan heuristic. The initial executions inform the decision; the result is not an unconditional switch after a fixed call count. Planning settings and invalidation events can also affect behavior.

Identifiers are SQL structure. Choose them from a strict allowlist and quote them with the database driver's composition facilities. Do not interpolate raw user strings or pretend an identifier can always be supplied as a normal value parameter.

## Expected evidence

The custom rare and common plans can reflect skew. The generic plan must use one reusable shape. Record actual performance before recommending a forced mode, since specialization has its own planning cost.

**DoneContract:** explain a slow parameterized query without conflating SQL injection prevention, driver behavior, server preparation, and cardinality-sensitive plan selection.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 7
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [sql prepare](https://www.postgresql.org/docs/18/sql-prepare.html)
- [runtime config query](https://www.postgresql.org/docs/18/runtime-config-query.html)
- [protocol flow](https://www.postgresql.org/docs/18/protocol-flow.html)
- [indexes partial](https://www.postgresql.org/docs/18/indexes-partial.html)
