# 08. Ranges Text And Bitmaps

**Prerequisite:** the preceding lessons, especially their DoneContracts. **Environment:** PostgreSQL 17, disposable course database. **Evidence:** actual plans and result checks, not prescribed timings.

[Course map](../01_course_map.md) · [SQL lab](../../sql/labs/08_ranges_text_and_bitmaps.sql) · [Worked answers](../solutions/08_ranges_text_and_bitmaps.md)

The explanations and experiments are original teaching material. Engine semantics are grounded in the primary references at the end; workload examples and proposed decisions are not measurements from your production system.

## The problem: not every search describes one contiguous key range

A numeric or timestamp interval maps naturally to an ordered region in a suitable B-tree. A text prefix can also describe a bounded region under compatible comparison rules. A substring in the middle of a value generally does not. Before choosing an index, describe the set of keys the predicate must locate.

The first half of the lab revisits project and status with separate indexes. The second half uses messages such as `Run-000123 finished` and `Run-010000 timeout`. These are synthetic application messages, not production logs or a linguistic search benchmark.

## Range boundaries and operator classes

A B-tree operator class defines the comparisons its entries support. For prefix `LIKE` searches under some locale settings, a `text_pattern_ops` index provides a useful character-by-character ordering. The course database deliberately uses the C locale, but the explicit pattern operator class makes the intended access family visible. Do not generalize the observed behavior to every collation or case-insensitive operator.

A prefix such as `Run-0001%` identifies values sharing their initial characters. A search for `%timeout%` can match at many positions, so an ordinary leading-key lookup cannot simply jump to one alphabetical prefix. An index may still be scanned in some circumstances, but that is different from efficiently narrowing the search.

## Trigrams change the indexed representation

The lab's GIN trigram index stores information about character fragments rather than merely the entire string's ordinary order. It can support suitable substring and similarity searches. The query still has to verify candidates, and short or unselective patterns may not provide useful index keys. A trigram index is not a universal replacement for full-text search, linguistic tokenization, or a B-tree used for ordering.

Compare before and after plans for `%timeout%`. Record the index's storage and the number of candidate rows. A rare synthetic word can make a compelling demonstration; it does not establish performance for common production terms or arbitrary languages.

## Bitmap combination: AND is not always two indexes

For `project_id=42 AND status='running'`, PostgreSQL may combine two index results with a bitmap intersection. It may instead choose one index and apply the other condition as a filter. Consulting a second index has a cost, and one condition may already narrow the candidate set enough.

For an `OR`, a bitmap union can collect matches from separate indexes. SQL `OR` returns each qualifying row once, even when both branches match. Rewriting it as `UNION ALL` can introduce duplicates. If proposing that rewrite, explicitly remove overlap or choose duplicate-eliminating semantics where appropriate. Query rewrites are correctness changes until proven equivalent.

## Ordering and LIMIT remain separate concerns

A bitmap heap scan visits heap pages in physical order. Even when its inputs come from ordered indexes, their order is not retained as the query's output order. A feed requiring recent results may benefit more from one composite ordered index than from several filter indexes, especially when it can stop early.

Conversely, a broad report with no required order may gain from bitmap combination. Evaluate the complete query, not just the `WHERE` clause.

## Experiment and platform transfer

Run the natural `AND` and `OR` plans without demanding a `BitmapAnd` screenshot. Then inspect the prefix and substring cases. For platform search, separate exact identifiers, prefixes, free-text document search, and arbitrary diagnostic substrings into explicit requirements. Each can deserve a different data representation and index family.

The solution checks substring matches against an equivalent literal search and demonstrates overlap-safe OR reasoning. It deliberately does not assert that a GIN plan must be faster at every data size.

## Run the experiment

From the package root:

```sh
python scripts/course.py lab 8
```

Without host Python:

```sh
docker compose exec -T postgres psql -X -U course -d advanced_sql -v ON_ERROR_STOP=1 -f /course/sql/labs/08_ranges_text_and_bitmaps.sql
```

Read each SQL section and predict its result before executing it. Re-running the lab resets only `lab08`. Do not reset it while another session is using it. The noninteractive lab is only the foundation for lessons 17-19; use [the concurrency guide](../concurrency.md) for actual overlapping transactions.

## Exercises before opening the answer key

1. Why can a text prefix describe a B-tree search region when an arbitrary substring does not?
2. Why might the planner use only one of two applicable indexes for an AND predicate?
3. What semantic bug can appear when OR is rewritten as UNION ALL?

Record your hypothesis, result, and explanation with [the experiment template](../templates/experiment.md). The [answer key](../solutions/08_ranges_text_and_bitmaps.md) includes this lesson's DoneContract; [solution SQL](../../sql/solutions/08_ranges_text_and_bitmaps.sql) adds executable checks or a worked alternative after the lab.

## Primary references

- [indexes types](https://www.postgresql.org/docs/17/indexes-types.html)
- [indexes opclass](https://www.postgresql.org/docs/17/indexes-opclass.html)
- [indexes bitmap scans](https://www.postgresql.org/docs/17/indexes-bitmap-scans.html)
- [pgtrgm](https://www.postgresql.org/docs/17/pgtrgm.html)
