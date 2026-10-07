# 05. Scan Strategies: worked answers

[Return to lesson](../lessons/05_scan_strategies.md)


## Worked answers

The index scan pays for index traversal and heap access while potentially touching a large share of the relation. A sequential scan may obtain the necessary pages more efficiently. Cache state and covering can reverse the comparison, so there is no universal row-percentage cutoff.

Bitmap processing organizes heap access by page and can combine multiple index results. It does not preserve the index's original key order, so an `ORDER BY` may require separate work. Lossy page entries require tuple rechecks.

Diagnostic switches ask a counterfactual question. Permanently disabling a path deprives other workloads of useful choices and can conceal statistics or schema problems. The lab uses transactions to prevent those flags leaking into later work.

## Expected observations

The default plans may differ between rare and common status predicates. The forced alternatives can be slower or faster on your machine; that is data to interpret, not an exam answer to manipulate. Verify aggregate equality independently of the plan shape.

**DoneContract:** defend an access strategy using rows, pages, ordering, and stopping conditions. Explain why an apparently more sophisticated node can perform more work.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 5
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [using explain](https://www.postgresql.org/docs/18/using-explain.html)
- [indexes bitmap scans](https://www.postgresql.org/docs/18/indexes-bitmap-scans.html)
- [runtime config query](https://www.postgresql.org/docs/18/runtime-config-query.html)
- [indexes ordering](https://www.postgresql.org/docs/18/indexes-ordering.html)
