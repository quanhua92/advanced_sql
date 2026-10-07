# 17. Transactions And Isolation: worked answers

[Return to lesson](../lessons/17_transactions_and_isolation.md)


## Worked answers

Read Committed normally obtains a new snapshot for each statement. Another transaction's committed update can become visible between those statements. Repeatable Read preserves the transaction snapshot for its ordinary reads instead.

Both transactions can make decisions from a snapshot in which the invariant holds, then write disjoint rows whose combined state violates it. This is write skew. Non-overlapping row writes do not prove cross-row correctness.

Retry the whole transaction from fresh reads. A serialization failure aborts the transaction, and the decisions leading to the last statement may be stale. External effects need idempotency or a separate durable protocol so replay is safe.

## Expected schedules

Read Committed changes the second observed value; Repeatable Read preserves it. The Repeatable Read on-call schedule can leave zero active rows. Serializable should reject at least one conflicting transaction in the designed schedule, preserving the invariant among committed transactions.

**DoneContract:** reproduce a real concurrent anomaly and present a correct isolation/locking/constraint solution with explicit retry and external-effect handling.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 17
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [transaction iso](https://www.postgresql.org/docs/17/transaction-iso.html)
- [mvcc intro](https://www.postgresql.org/docs/17/mvcc-intro.html)
- [explicit locking](https://www.postgresql.org/docs/17/explicit-locking.html)
- [tutorial transactions](https://www.postgresql.org/docs/17/tutorial-transactions.html)
