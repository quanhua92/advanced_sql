# 06. Expressions And Predicates: worked answers

[Return to lesson](../lessons/06_expressions_and_predicates.md)


## Worked answers

A half-open interval includes the starting instant and excludes the next day's midnight. Adjacent days neither overlap nor leave gaps. An inclusive upper midnight includes one instant belonging to the next interval.

`timestamptz` represents an instant, while a calendar date depends on the timezone used to interpret it. The same instant can belong to different dates in different zones. A session-dependent cast is not an immutable indexed expression.

An expression index is useful when a stable, repeated application query genuinely searches by a derived value and the write/storage cost is acceptable. A timestamp range often gives more general reuse for arbitrary time windows. The decision follows query semantics and workload, not a preference for one SQL spelling.

## Boundary tests

Construct rows just before the start, exactly at the start, just before the end, and exactly at the end. Run both query formulations and compare IDs in both directions. Also test a local-time date whose UTC boundaries differ from midnight UTC.

**DoneContract:** produce a semantically equivalent searchable predicate and explain its timezone, endpoint, null, and type assumptions before presenting the performance plan.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 6
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [indexes expressional](https://www.postgresql.org/docs/18/indexes-expressional.html)
- [datatype datetime](https://www.postgresql.org/docs/18/datatype-datetime.html)
- [functions datetime](https://www.postgresql.org/docs/18/functions-datetime.html)
- [sql createindex](https://www.postgresql.org/docs/18/sql-createindex.html)
