# 21. Partitioning: worked answers

[Return to lesson](../lessons/21_partitioning.md)


## Worked answers

The timestamp bounds match the partitioning rule and identify impossible partitions. An ID alone does not tell PostgreSQL which timestamp range contains it, even when the application knows the values are correlated.

Pruning removes whole pieces; indexing selects rows within the remaining pieces. They operate at different granularity. A query spanning all partitions can still require substantial work.

The parent no longer includes the detached January table in its logical data. The detached relation and its rows still exist separately. Archival and deletion remain explicit follow-up operations with their own safety checks.

## Design answer

Use time partitioning when retention and time-filtered access justify it. Preserve a clearly enforced uniqueness model, plan future partition creation, and monitor the default partition. Do not promise global ID uniqueness from a composite partition-key constraint alone.

**DoneContract:** justify a partition key from operations, demonstrate actual pruning, account for uniqueness and references, and design retention without confusing detach, archive, and deletion.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 21
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [ddl partitioning](https://www.postgresql.org/docs/18/ddl-partitioning.html)
- [sql altertable](https://www.postgresql.org/docs/18/sql-altertable.html)
- [sql createtable](https://www.postgresql.org/docs/18/sql-createtable.html)
- [planner stats](https://www.postgresql.org/docs/18/planner-stats.html)
