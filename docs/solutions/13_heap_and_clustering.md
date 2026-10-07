# 13. Heap And Clustering: worked answers

[Return to lesson](../lessons/13_heap_and_clustering.md)


## Worked answers

No. PostgreSQL ordinarily stores heap tuples separately from the primary-key index. InnoDB's clustered row organization and secondary-key lookup path are different.

CLUSTER rewrites the current table and records a preferred clustering index. Later writes need not preserve global physical key order. Queries still require ORDER BY for a contractual result order, and the metadata flag is not proof of ongoing physical sortedness.

Secondary-index representations differ across engines. InnoDB includes the primary-key value in secondary entries, whereas PostgreSQL ordinary indexes use heap tuple identifiers. Wide explicit keys still have costs in PostgreSQL, but the propagation mechanism is not identical.

## Platform decision

Retain the application's identifier semantics while measuring storage and access costs on its actual engine. Do not change a distributed ID strategy because a rule from another engine was presented without qualification.

**DoneContract:** draw each engine's lookup path, explain the scope and locking cost of CLUSTER, and separate physical locality from SQL ordering guarantees.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 13
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [sql cluster](https://www.postgresql.org/docs/18/sql-cluster.html)
- [storage page layout](https://www.postgresql.org/docs/18/storage-page-layout.html)
- [planner stats](https://www.postgresql.org/docs/18/planner-stats.html)
- [innodb index types](https://dev.mysql.com/doc/refman/8.4/en/innodb-index-types.html)
