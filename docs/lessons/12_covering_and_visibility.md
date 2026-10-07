# 12. Covering And Visibility

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/12_covering_and_visibility.sql) · [Worked answers](../solutions/12_covering_and_visibility.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: the index contains the values, but can it prove visibility?

A covering index stores every value required by a particular query. An index-only scan is an execution strategy that can obtain those values from the index. These ideas are related but not identical to a guarantee of zero heap access.

PostgreSQL must obey MVCC visibility. Ordinary index entries do not carry all the information needed to decide which row version is visible to an arbitrary snapshot. A visibility-map bit can provide page-level assurance that permits heap access to be skipped. Without that assurance, an index-only scan can still fetch heap tuples.

## Navigation keys versus included payload

The lab creates:

```sql
CREATE INDEX runs_covering
ON lab12.runs(project_id, status, created_at DESC, id DESC)
INCLUDE(duration_ms);
```

The four key columns define the searchable ordering. `duration_ms` is stored as payload and can satisfy projection needs. It does not become another search-order key simply because it is in the index. Adding many large payload columns can make the index expensive and may encounter index tuple-size limits.

Whether a query is covered depends on all required values, including predicates and ordering expressions, not just an informal count of selected columns. Index access-method capabilities also matter. This lesson uses B-tree behavior rather than assuming every index family stores reconstructible original values.

## The visibility lifecycle

After loading and vacuuming a quiet table, many pages can be marked all-visible. Updating rows clears relevant visibility-map state. An index-only query may then perform heap fetches until cleanup and visibility conditions allow the assurance to be restored.

The lab prints `pg_visibility_map_summary`, executes the covered feed, updates project 42, executes it again, and vacuums before a third execution. Compare the plan's `Heap Fetches` field when an index-only path is selected. An ordinary index scan does not report that same field in the same way, so absence of the label is not proof of zero heap access.

Background autovacuum, snapshots, and plan choices can affect the observation. Treat the expected increase/decrease as a mechanism to investigate, not a mandatory numeric sequence. The solution does not assert `Heap Fetches = 0` as a portable test.

## The write-side consequence

Because duration is stored in the index, changing it requires index maintenance and can prevent HOT updates for that change. A frequently refreshed duration or heartbeat field can therefore be a poor covering payload even when it makes a dashboard query attractive in isolation.

Separate immutable historical facts from highly mutable operational state when the data model permits it. That can improve both the index-only opportunity for history and update behavior for live state. It is an architectural tradeoff, not an excuse to split every table without considering transactional requirements.

## Platform application

Completed run history may become mostly stable, while running rows change repeatedly. Covering indexes can be more valuable on stable history than on constantly modified queue rows. A smaller partial index or narrower projection can be preferable to covering every dashboard field.

The lesson's decision is to justify the values stored in the index and explain when heap access can be skipped. “It says Index Only Scan” is the start of that explanation, not its conclusion.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 12
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/12_covering_and_visibility.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab12`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. How can an Index Only Scan still have nonzero Heap Fetches?
2. What is the difference between an INCLUDE column and a navigation key?
3. Why might including a frequently updated heartbeat field be a poor tradeoff?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/12_covering_and_visibility.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/12_covering_and_visibility.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [indexes index only scans](https://www.postgresql.org/docs/17/indexes-index-only-scans.html)
- [pgvisibility](https://www.postgresql.org/docs/17/pgvisibility.html)
- [storage vm](https://www.postgresql.org/docs/17/storage-vm.html)
- [storage hot](https://www.postgresql.org/docs/17/storage-hot.html)
