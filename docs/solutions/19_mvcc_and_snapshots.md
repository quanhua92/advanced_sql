# 19. MVCC And Snapshots: worked answers

[Return to lesson](../lessons/19_mvcc_and_snapshots.md)


## Worked answers

A's Repeatable Read snapshot still identifies the older visible version. B's commit makes the new version available to appropriate later snapshots, not retroactively to every already-established snapshot.

The older version remains required by A. Cleanup must preserve versions that can still be visible to active snapshots. Ending the relevant transaction allows the cleanup horizon to advance, though statistics and background work may not update instantly.

Internal versions are not a durable public change-log contract. They are reclaimed, and transaction metadata does not carry the full application meaning or evidence. Persist business events or immutable revisions explicitly.

## Expected evidence

The two sessions can see different bodies for the same logical document. A sees the new body after its transaction ends and a new read occurs. VACUUM output and snapshot activity support the retention explanation; exact counters are not hard-coded tests.

**DoneContract:** explain which version each statement sees and when cleanup may reclaim it, then identify application transaction boundaries that unnecessarily retain history.

## Execute the companion solution

Run the lesson first, then:

```sh
python scripts/course.py solution 19
```

The SQL checks logical outcomes or demonstrates an alternative. It deliberately does not assert that every server chooses an identical plan or meets a fixed latency. Compare your captured plan with the reasoning above.

## Primary references

- [mvcc intro](https://www.postgresql.org/docs/17/mvcc-intro.html)
- [transaction iso](https://www.postgresql.org/docs/17/transaction-iso.html)
- [routine vacuuming](https://www.postgresql.org/docs/17/routine-vacuuming.html)
- [ddl system columns](https://www.postgresql.org/docs/17/ddl-system-columns.html)
- [storage vm](https://www.postgresql.org/docs/17/storage-vm.html)
