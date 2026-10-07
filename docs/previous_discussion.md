# Earlier research and first-lesson discussion, incorporated

## What the original investigation established

The earlier response inspected the publicly visible Advanced SQL syllabus and reported 21 lessons covering indexes, access paths, joins, storage, transactions, MVCC, recovery, and partitioning. It found substantial public text for the first two lessons and titles/descriptions behind premium gates for the others. It did not access the paid sandbox or establish actual video runtime. The archived map records the advertised price and inconsistent 12-hour versus 24-hour duration claims as findings of that investigation, not as independently verified video lengths.

The conclusion was not that short videos must be poor. The useful standard is whether a learner can predict behavior, inspect evidence, explain exceptions, and make a correct design decision. This package teaches those skills in original material rather than reproducing premium content.

The original files are preserved unchanged in [legacy](../legacy/README.md), including the original ZIP. Their historical “not executed” language describes the earlier pack. This package's own validation status is separately documented in [VALIDATION.md](../VALIDATION.md).

## Four qualifications retained

Tree height measures navigation levels, not a guaranteed count of physical storage reads. A covering index supplies requested values but does not guarantee zero heap visits under MVCC. There is no universal matched-row percentage at which sequential scanning must become preferable. Mutation costs differ: some updates can be HOT, and deletion leaves cleanup work for later.

The expanded lessons retain all four distinctions, supported by PostgreSQL's primary documentation. They treat plans as choices based on estimated work, not automatic consequences of column names.

## The first example

The original dashboard query requested the latest 20 failed runs of project 42, ordered by `(created_at DESC, id DESC)`. The candidate `(project_id, status, created_at DESC, id DESC)` index aligns both equality conditions with an ordered suffix, making bounded ordered access possible. A failed-only partial index is a narrower workload-specific alternative. Both introduce storage and maintenance costs.

The numerical thought experiment used two million rows, 80 heap rows per page, 400 index entries per leaf page, and fanout 250. These were explicit hypothetical capacities, not measured engine occupancies. It also showed that independent 1% row matches can touch roughly 55% of pages at 80 rows per page, using `1 - 0.99^80`. The new [lesson 1](lessons/01_pages_and_btrees.md) explains these models and connects them to runnable evidence.

## Answer to the earlier checkpoint

Removing the status equality changes the ordering problem. Within project 42, the index groups entries by status first, then by time within each status. Those time-ordered groups are not one globally time-ordered stream. A backward scan reverses the complete ordering; it does not discard the status grouping. PostgreSQL may still use the index in some plan, but it generally needs additional work to produce the all-status time order. An index beginning `(project_id, created_at DESC, id DESC)` serves that different feed directly. Whether retaining both is worthwhile depends on the broader read/write workload.

The new dataset has additional platform entities and statuses, so it does not silently replace the original 500,000-row lab's exact fixture. Both remain runnable in separate schemas.

Sources: [Public course](https://sydexa.com/courses/advanced-sql), [public first lesson](https://sydexa.com/courses/advanced-sql/lessons/index-and-btree), [public second lesson](https://sydexa.com/courses/advanced-sql/lessons/index-in-practice), [multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html), [index-only visibility](https://www.postgresql.org/docs/18/indexes-index-only-scans.html), [HOT](https://www.postgresql.org/docs/18/storage-hot.html).
