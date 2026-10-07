# 01. Pages And B-Trees

**Prerequisite:** the setup guide and basic SELECT/JOIN syntax. **Environment:** PostgreSQL 18, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/01_pages_and_btrees.sql) · [Worked answers](../solutions/01_pages_and_btrees.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: a small answer can require a large search

Your dashboard needs the latest 20 failed runs for project 42. SQL describes that result; it does not prescribe a search algorithm. Before creating an index, separate the work into finding candidates, obtaining their values, checking visibility, producing the order, and stopping after enough rows. An index can improve several of these steps, but not necessarily all of them.

The lab begins with only an `id` primary-key index. That index is useful for an ID lookup, but it does not organize this dashboard's project, status, and time conditions. The baseline plan is evidence of the chosen access path, not a verdict that PostgreSQL forgot how indexes work.

## Pages, fanout, and the path to a tuple

PostgreSQL normally uses 8 KB pages. The heap and each ordinary index have separate storage. A B-tree's internal entries direct navigation toward lower pages; leaf entries identify matching table tuples. The implementation has sibling links and details beyond a textbook tree, but the essential benefit is high fanout: many routing choices fit into each page.

Use explicit assumptions for a numerical model. Two million rows at 80 rows per heap page occupy about 25,000 heap pages. An index with 400 entries per leaf page needs about 5,000 leaf pages. With internal fanout 250, about 20 internal pages and one root suffice. A lookup traverses three index levels, then may fetch heap pages. These capacities are hypothetical, not observed PostgreSQL occupancies.

Three levels do **not** imply three physical storage reads. PostgreSQL may have a page in shared buffers, and the operating system can satisfy a PostgreSQL read from its own cache. Navigation also has CPU and synchronization costs. Conversely, finding the first matching entry does not make the remaining matching entries free.

## Why row selectivity is not page selectivity

Suppose each row independently matches with probability 0.01 and a page contains 80 rows. The probability that a page has at least one match is:

```text
1 - (1 - 0.01)^80 = approximately 0.5525
```

A query that needs all matching heap rows can therefore touch roughly 55% of pages even though only 1% of rows match under this model. This does not establish which plan wins. It exposes the missing variable: distribution across pages. Clustered placement, covering, bitmap access, caches, and early termination change the work.

## A worked access-path design

```sql
CREATE INDEX runs_dashboard
ON lab01.runs(project_id, status, created_at DESC, id DESC);
```

The leading equalities identify one project/status region. Inside it, entries have the requested timestamp and ID order. PostgreSQL can consider walking that region until 20 visible qualifying rows are obtained. The index supplies both filtering and ordering, rather than merely mentioning the filtered columns.

The query also selects `duration_ms`, which is not stored in this index, so an ordinary index scan must obtain that value from the heap. Adding it later as an included column changes the available path, but visibility still matters. Lesson 12 demonstrates why a covering index is not a promise of zero heap visits.

## Inspect the mechanism

Run the lab section by section. Compare the baseline and indexed plan, then inspect `bt_metap` and a heap page. `level` in the B-tree metadata is zero-based; a root level of zero means the root itself is a leaf. The displayed `ctid` identifies a physical tuple location, not a durable application ID. Never build application references around it.

The output you need is the selected scan, presence of sorting, actual rows, buffer activity, and observed tree level. Do not invent a speedup from tree height. Repeat the query and record that loading and indexing already interacted with the cache.

## Transfer to the platform

A run feed benefits from a bounded ordered access path. A report aggregating all failures has different needs. An index designed for the feed can be excellent even when its first column is not the globally most selective one. The access path must fit the whole query and the surrounding workload.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 1
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/01_pages_and_btrees.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab01`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Explain why a three-level tree can produce fewer than three physical reads, or much more than three page accesses for a query.
2. Why can 1% of matching rows be spread over roughly half the pages in the hypothetical model?
3. Remove the status equality from the dashboard query. Does the existing index still provide global time order within project 42?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/01_pages_and_btrees.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/01_pages_and_btrees.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [storage page layout](https://www.postgresql.org/docs/18/storage-page-layout.html)
- [btree](https://www.postgresql.org/docs/18/btree.html)
- [pageinspect](https://www.postgresql.org/docs/18/pageinspect.html)
- [indexes ordering](https://www.postgresql.org/docs/18/indexes-ordering.html)
