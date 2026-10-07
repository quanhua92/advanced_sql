# 08. Ranges Text And Bitmaps: worked answers

[Return to lesson](../lessons/08_ranges_text_and_bitmaps.md)


## Worked answers

A prefix constrains the beginning of the ordered key, enabling bounds under compatible collation and operator-class rules. A substring can appear anywhere. Trigram indexing uses a different representation to identify candidates, which are still checked against the original predicate.

Building and combining two bitmaps costs work. One selective index plus a filter can be cheaper than consulting both. An available path is not an instruction to use it.

Rows matching both branches appear once under OR but twice under a naive UNION ALL. Eliminate overlap explicitly or use a duplicate-eliminating result when that matches the desired semantics. Plain UNION can also incur sorting or hashing and must be measured.

## Expected evidence

The prefix index can supply a bounded search. The trigram index can supply a substring candidate path. A bitmap node may lose useful ordering and need a sort. The key lesson is the representation and required work, not a universal ranking of index families.

**DoneContract:** classify a search as equality, range, prefix, substring, or full-text; choose a candidate representation; and verify both semantics and actual plans.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 8
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [indexes types](https://www.postgresql.org/docs/18/indexes-types.html)
- [indexes opclass](https://www.postgresql.org/docs/18/indexes-opclass.html)
- [indexes bitmap scans](https://www.postgresql.org/docs/18/indexes-bitmap-scans.html)
- [pgtrgm](https://www.postgresql.org/docs/18/pgtrgm.html)
