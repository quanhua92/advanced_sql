# 22. Statistics, skew, and correlated predicates

An applicable index does not guarantee a useful estimate. PostgreSQL plans using statistics about value distributions, distinct counts, nulls, and other characteristics. A common approximation treats separate conditions as independent when no better information is available. That can be badly wrong when columns encode related facts.

The lab deliberately makes `tenant_bucket` and `region_bucket` identical. Each of 100 values appears 1,000 times in a 100,000-row table. An independence model would multiply 1/100 by 1/100 and expect about 10 matching rows for the conjunction. The actual result is 1,000 because the second condition adds no restriction. These are properties of the synthetic construction, not statistics inferred about your tenants.

Run the estimate before and after creating extended statistics and running ANALYZE. The experiment adds no access index. Its purpose is to change the planner's information, not the data or query answer. Functional dependencies, multicolumn most-common-value information, and multicolumn distinct counts answer different estimation questions. Creating a statistics object is not enough; it needs collected statistics.

Do not interpret `pg_stats.correlation` as this general relationship between two columns. That field describes a column's relationship with physical row ordering. The similar vocabulary conceals different mechanisms.

A badly underestimated filter can later cause an unfortunate join choice, sort-size estimate, or memory expectation. Diagnose the earliest divergence instead of treating the final slow node as the whole problem. Statistics targets and ANALYZE frequency also have collection costs, and not every expression or join-estimation problem is solved by one multicolumn object.

For your platform, a project might heavily favor a model family, pool, or status pattern. A synthetic globally uniform dataset will miss that skew. Capture real distributions in a privacy-preserving form before extrapolating lab timings to production. Test both common and rare parameter values.

**Exercise:** calculate the independent estimate, then explain why it differs from the actual count. Compare estimates after collection without demanding one exact numerical result from every statistics sample.

**Worked answer:** the independent estimate is 10, while the generated data contains 1,000 matches. Extended statistics can describe the dependency or frequent combinations. The output count must remain unchanged; only planning information changes.

**DoneContract:** identify a cardinality error caused by dependence or skew and justify a statistics change separately from an index change.

References: [planner statistics](https://www.postgresql.org/docs/18/planner-stats.html), [CREATE STATISTICS](https://www.postgresql.org/docs/18/sql-createstatistics.html), [ANALYZE](https://www.postgresql.org/docs/18/sql-analyze.html).

## Run

```sh
python scripts/course.py bonus 22
```

[Executable lab](../../sql/extras/22_statistics_and_skew.sql). This bonus includes its own assertions or diagnostic queries. Re-running resets its own teaching schema where one is needed; the monitoring bonus is read-only apart from ordinary statistics collection.
