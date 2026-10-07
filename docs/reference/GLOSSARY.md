# Glossary

**Heap:** PostgreSQL's ordinary table storage, separate from its indexes. **Tuple:** a row representation or row version. **TID/ctid:** physical tuple location, not a stable application identifier. **Page/block:** the fixed-size unit of relation storage.

**B-tree:** ordered index structure supporting equality and ordered/range access. **Fanout:** routing choices in an internal page. **Selectivity:** fraction of rows expected to satisfy a predicate. **Correlation:** relationship between value order and physical layout, or between columns, depending on context.

**Sequential scan:** examine table pages without navigating a matching index path. **Index scan:** use index entries to locate candidate table rows. **Bitmap scan:** collect candidate locations and organize heap visits, possibly combining indexes. **Index-only scan:** use index-provided values with visibility-map assistance, possibly still fetching the heap.

**Covering index:** an index containing the values needed by a query. **INCLUDE:** stored payload outside the navigation key. **Partial index:** an index restricted by a predicate. **Expression index:** an index over an expression rather than only raw columns. **Sargable predicate:** informal term for a condition usable to constrain an access path; check the actual operator and expression semantics rather than relying on the label.

**Cardinality estimate:** predicted row count. **Cost:** optimizer comparison units. **Generic plan:** reusable plan not specialized to current bound values. **Custom plan:** plan made with the execution's parameter values. **Spill:** work that exceeds its memory allocation and uses temporary storage.

**MVCC:** multiversion concurrency control. **Snapshot:** rules identifying which committed/uncommitted versions a statement can see. **Visibility map:** per-heap-page visibility/freeze information. **Vacuum:** maintenance reclaiming reusable space from obsolete versions and updating related metadata. **HOT:** an update optimization that can avoid ordinary index updates when eligible.

**Isolation:** transaction visibility and conflict behavior. **Row lock:** authority preventing incompatible concurrent changes to a row. **Deadlock:** a cycle of waiting transactions. **Serialization failure:** rejection needed to preserve serializable behavior. **Write skew:** separate writes based on a shared predicate that collectively break an invariant.

**WAL:** write-ahead log used for durability/recovery. **Checkpoint:** recovery-related synchronization of dirty state, not a replacement for commit. **Unlogged table:** table without ordinary crash-durable data logging. **Partition pruning:** eliminating irrelevant partitions from execution. **BRIN:** page-range summary index. **GIN:** inverted index used for supported component/containment searches.

**Lease:** time-bounded ownership under a protocol. **Attempt:** one execution generation of a durable job. **Fencing:** rejecting stale generations at a resource that enforces the ordering. **Idempotency:** repeated requests produce one intended logical effect. **Transactional outbox:** durable publication intent committed with the database change. **DoneContract:** this course's explicit demonstration required to consider a lesson understood.

For engine-specific details, follow the primary references in the matching lesson and [source index](SOURCES.md). The queue vocabulary describes the supplied design, not built-in PostgreSQL job semantics.
