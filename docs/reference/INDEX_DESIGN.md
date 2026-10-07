# Index design decision guide

Start with the exact predicate and ordering, not a list of columns that “need indexes.” Separate equality constraints, range constraints, ordering, required payload, and any stable partial predicate. Then explain how the candidate index organizes the relevant entries.

For a failed-run feed, `(project_id, status, created_at DESC, id DESC)` aligns two equalities with a requested time order. Removing the status equality changes the order requirement; a project/time index supports that different feed. A partial failed-only index can reduce scope but cannot stand in for all-status access. An unknown generic-plan parameter may prevent the planner from proving a partial predicate.

`INCLUDE` values cover payload but do not participate in key navigation. Coverage does not guarantee heap-free execution. Adding payload can enlarge the index, increase maintenance, and affect HOT eligibility when those values change. Always compare read savings to update frequency and visibility behavior.

For text, distinguish a prefix range from arbitrary substring matching and verify collation/operator-class behavior. For JSON, choose operators and an index class that match the query. For append-correlated time data, BRIN can be compact but works through page-range summaries and rechecks rather than exact tuple locations. Different methods remove different kinds of work.

Before retaining an index, measure its size, inspect overlapping indexes, test representative parameter skew, and evaluate mutation costs. Building an index concurrently reduces some blocking but does not remove all operational risk; verify validity and transaction restrictions. A failed build can leave cleanup work.

The decision should name the workload served, mechanism, evidence, costs, alternatives, and a condition for revisiting it. Use [the decision template](../templates/index_decision.md).

Sources: [Indexes](https://www.postgresql.org/docs/18/indexes.html), [multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html), [CREATE INDEX](https://www.postgresql.org/docs/18/sql-createindex.html), [HOT](https://www.postgresql.org/docs/18/storage-hot.html).
