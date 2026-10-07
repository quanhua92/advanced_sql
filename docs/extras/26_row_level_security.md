# 26. Optional tenant isolation with row-level security

Projects are not only filters for performance. They can define access boundaries. PostgreSQL row-level security adds policies restricting which rows an otherwise permitted statement may read or change. Ordinary object privileges and RLS work together: granting table CRUD does not inherently bypass RLS.

The lab uses a dedicated NOLOGIN role without superuser or BYPASSRLS privileges. It grants SELECT, INSERT, UPDATE, and DELETE, then switches into that role inside a transaction. Testing as the course superuser would be misleading because superusers bypass row security. Table owners also normally have special behavior; FORCE ROW LEVEL SECURITY changes the owner case but does not remove superuser bypass.

`USING` controls which existing rows are visible or eligible under the policy. `WITH CHECK` constrains the new row values produced by insertion or update. A design that filters SELECT but forgets new-row checks can fail its intended write-isolation contract. The lab performs allowed same-project CRUD and deliberately attempts a cross-project insert, which must be rejected.

The project context is represented by a custom session setting for clarity. This is **not authentication**. A client that may set that value arbitrarily can choose a different project. In a real service, a trusted boundary must establish authorized context, and database privileges must prevent untrusted users from choosing identities or invoking unsafe helper functions. RLS is not a substitute for authenticating the request.

Connection pools make context lifecycle important. A session-level setting can leak across reused connections. The demonstration uses transaction-local context and role changes, which revert at transaction end. Verify actual pool behavior and transaction boundaries before transferring the pattern.

Policy expressions affect query planning as well as correctness. Tenant-leading indexes can help common scoped queries, but performance changes must not weaken the access rule. Security-definer functions, role inheritance, owner privileges, and alternate write paths deserve explicit review.

The queue capstone intentionally does not implement an application authorization layer. Passing `project_id` into its function is not proof that the caller is authorized for that project. This bonus exists to make that omission visible and show a separate security mechanism, not to claim a production-ready multi-tenant security architecture.

**Exercise:** explain why the course superuser is the wrong actor for testing RLS, and why both read visibility and inserted/updated row checks are needed.

**Worked answer:** use an unprivileged role that does not bypass policy, confirm the role flags, and test allowed and disallowed CRUD separately. A trusted application must establish context; a freely chosen setting is not an identity proof.

**DoneContract:** verify a tenant policy with a non-bypassing role and state the authentication, context, and connection-pooling assumptions.

References: [row security](https://www.postgresql.org/docs/18/ddl-rowsecurity.html), [CREATE POLICY](https://www.postgresql.org/docs/18/sql-createpolicy.html), [role attributes](https://www.postgresql.org/docs/18/role-attributes.html), [SET](https://www.postgresql.org/docs/18/sql-set.html).

## Run

```sh
python scripts/course.py bonus 26
```

[Executable lab](../../sql/extras/26_row_level_security.sql). This bonus includes its own assertions or diagnostic queries. Re-running resets its own teaching schema where one is needed; the monitoring bonus is read-only apart from ordinary statistics collection.
