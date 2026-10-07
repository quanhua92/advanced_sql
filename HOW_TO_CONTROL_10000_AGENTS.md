# HOW TO CONTROL 10,000 AGENTS

## A durable orchestration guide for a FastAPI platform using the OpenAI Codex SDK

**Version:** 1.0  
**Prepared:** 2026-10-08  
**Audience:** Engineers building a multi-user, multi-machine agent platform.  
**Status:** Researched architecture and implementation specification, with a locally tested reference state model. This is not a delivered orchestration service or a 10,000-Codex-instance benchmark.

> **Put fleet control outside Codex. Use Codex to execute bounded reasoning turns inside that fleet.**
>
> A reusable Agent is a definition. A Chat is a durable conversation. An activation is scheduled work. A running Codex harness is a temporary resource. These must not all have the same lifetime.

This guide preserves your existing FastAPI, PostgreSQL, projects, user/project agents, Chats, Workflows, Workflow Runners, knowledge base, comments, and files. It does not require a new mandatory campaign entity, a TypeScript rewrite, or a GPU for every agent. The course-building workflow from `HOW_TO_MAKE_COURSE.md` is a worked example, not the only supported application.

Vendor capabilities are cited as **[S01]** and similar references. Everything described as a platform contract, policy, schema, proposed default, or implementation phase is an original design recommendation, not a claim that Codex implements it automatically. Current SDK behavior must be probed against the version you actually deploy.

---

## Contents

1. [The architectural decision](#decision)
2. [What exactly reaches 10,000?](#counts)
3. [Keep your product model](#product-model)
4. [Verified Codex capabilities and their boundaries](#codex-facts)
5. [The system architecture](#architecture)
6. [The contracts that make the system correct](#invariants)
7. [Tasks, activations, attempts, and state machines](#state)
8. [The PostgreSQL execution protocol](#postgres-protocol)
9. [Durable messaging without lost wakeups](#messaging)
10. [The Codex adapter and bounded turns](#adapter)
11. [Scheduling, quotas, budgets, and backpressure](#admission)
12. [How the agents actually collaborate](#collaboration)
13. [A course factory with real pre-authoring adversaries](#course-factory)
14. [Artifacts, shared knowledge, and integration](#artifacts)
15. [External effects, retries, and exactly-once claims](#effects)
16. [Persistence, affinity, and moving work between machines](#migration)
17. [One machine, many machines, and 10,000 active executions](#deployment)
18. [CPU reasoning and GPU jobs are separate resources](#gpu)
19. [Failures, cancellation, pause, and recovery](#recovery)
20. [Keeping PostgreSQL and the control plane healthy](#database-scale)
21. [When to adopt Temporal, and what it should own](#temporal)
22. [Where Celery, NATS, Ray, and Kubernetes fit](#alternatives)
23. [Application APIs and authorization](#apis)
24. [Isolation and security boundaries](#security)
25. [Observability and operator controls](#observability)
26. [Validation and scale tests](#testing)
27. [An implementation roadmap](#roadmap)
28. [Operational runbooks](#runbooks)
29. [A prompt for your implementation agents](#implementation-prompt)
30. [Release criteria and validation status](#acceptance)
31. [Appendix A: starter database shape](#schema)
32. [Appendix B: executable reference state model](#reference-model)
33. [Sources and evidence notes](#sources)

---

<a id="decision"></a>
## 1. The architectural decision

Do not try to build the fleet by telling one Codex parent to recursively create an enormous family of native subagents. Native subagents can be useful within a small, bounded assignment. Their runtime lifecycle is not your cluster's authority for tenant permissions, durable tasks, machine placement, fair scheduling, money, artifact acceptance, or disaster recovery.

Instead, your platform should launch **many independent root Codex threads**, each assigned a bounded piece of work. A scheduler controls which of them is allowed to run. Agents collaborate through platform tools that create durable tasks, messages, dependencies, artifacts, and review decisions.

The distinction is concrete:

```text
Do not make this the fleet architecture:

one giant Codex parent
  -> recursively spawned children
     -> more children
        -> shared mutable workspace and unbounded waiting

Build this instead:

FastAPI + durable orchestration
  -> a bounded CPU runner pool
     -> independent Codex root thread / bounded turn
     -> independent Codex root thread / bounded turn
     -> independent Codex root thread / bounded turn
  -> a separate compute-job pool
     -> GPU jobs, CPU jobs, validators

Coordination: durable messages, task dependencies, revisions, and gates.
```

**The root of a workflow is a durable record, not necessarily a permanently running model.** A coordinator agent wakes when judgment is needed, produces a bounded plan or decision, and finishes its turn. Deterministic code handles dispatch, dependency bookkeeping, retries, deadlines, authorization, and status reconciliation.

My recommended starting stack for your existing platform is **FastAPI + PostgreSQL + S3-compatible artifact storage + independently deployed Python runner services + your Codex adapter**. Start with a deliberately small explicit orchestration state machine. Use an established workflow engine such as Temporal when workflow complexity and recovery requirements justify it, as described in Section 21. Do not introduce five infrastructure systems just because the target number contains four zeros.

This document addresses two different ambitions: keeping 10,000 durable agents available and running 10,000 executions simultaneously. The second requires much more hardware and provider capacity. Neither automatically gives useful collaboration among 10,000 agents on one problem.

<a id="counts"></a>
## 2. What exactly reaches 10,000?

Give the dashboard separate counters. Otherwise, “10,000 agents” can conceal completely different systems.

| Quantity | Meaning | What it consumes while idle |
|---|---|---|
| Agent definitions | Reusable instructions, policy, identity, and visibility | Database records |
| Chats / logical participants | Durable conversations or run-scoped participants | History and structured state |
| Open tasks | Goals that are not yet accepted or terminated | Task and dependency records |
| Runnable activations | Work eligible for admission now | Queue entries |
| Active harnesses | Live Codex execution environments | Memory, processes, connections, filesystem resources |
| Active model requests | Requests currently using provider inference | Provider capacity and usage budget |
| Native child threads | Children created inside a Codex session | Additional context, usage, and potentially runtime resources |
| Compute jobs | Training, tests, data processing, evaluation | Independently scheduled CPU/GPU resources |

A perfectly useful fleet can have 10,000 logical participants, 600 ready activations, 80 running harnesses, and 6 GPU jobs. These numbers are illustrative, not expected measurements.

Conversely, 10,000 simultaneous harnesses may each issue several model requests during a turn. Some may launch subprocesses or native children. Counting Python coroutines is not capacity planning.

The design should support sleeping participants without a live interpreter, OS process, open HTTP request, model call, or reserved GPU for each sleeper. For genuinely simultaneous execution, scale the admitted runner resources and contracted inference capacity instead of changing the identity model.

<a id="product-model"></a>
## 3. Keep your product model

Use your existing Agent and Chat distinction rather than adding a separate permanent employee process.

| Existing concept | Proposed meaning at fleet scale |
|---|---|
| Project | Authorization, quotas, resources, and collaboration boundary |
| Agent | Versioned system instructions and permitted capabilities |
| `owner_id != NULL` | User-owned agent, subject to project membership and sharing rules |
| `owner_id == NULL` | Project-level agent; not automatically a public agent |
| Chat | Durable actor-like conversation; normally one current Codex thread binding |
| Workflow | Versioned workflow definition or policy |
| WorkflowRun | One execution of a goal, static or dynamically planned |
| Runner | Machine-local service advertising bounded available resources |
| File / note / report | First-class resource with immutable revisions and access control |
| Comment | Human or agent collaboration record, not automatically executable instructions |

A single Agent may have many Chats running concurrently. **Serialize conflicting turns of one Chat, not every Chat belonging to the same Agent.** A project-level shared agent can answer many independent requests in separate chats. A run-scoped specialist does not need a permanent entry in the user's left-hand agent list.

Keep `Chat -> current Codex Thread` as a product-level relationship, but record binding history. Recovery may require a new provider thread. Preserve the Chat identity and add a new binding rather than pretending the old thread ID became portable.

Your “Agent Inbox as RPC” idea remains useful at the product level:

```text
ask_agent(agent_id, message, context) -> eventually a response
```

Implement that internally as **durable request, queued activation, durable result, and caller continuation**. It should not mean “keep the caller's MCP request and Codex harness alive until the other agent finishes.”

The platform can offer a synchronous-looking UI while execution underneath is asynchronous and recoverable. A chat page can show “waiting for reviewer” without a model burning turns to ask whether the reviewer has finished.

<a id="codex-facts"></a>
## 4. Verified Codex capabilities and their boundaries

These observations were checked on 2026-10-08. They are not assumptions about your installed version.

| Verified observation | Consequence for this design |
|---|---|
| OpenAI documents a Python Codex SDK for Python 3.10+, including async use. It controls a local app-server; the published package includes a pinned runtime dependency. [S01] | A Python-native runner is viable. You do not need to switch your FastAPI stack to TypeScript. |
| The documented native child limit is `agents.max_concurrent_threads_per_session`, excluding the primary thread. `agents.max_threads` is a legacy alias. The docs do not establish one universal fixed child count for every deployment. [S02] | Treat the native cap as a local guard, not a fleet-wide scheduler. |
| App-server exposes thread/turn operations, including resume and interrupt. Persistent thread history and live thread loading are distinct. [S03] | Persist platform work state separately, and explicitly manage runtime lifecycle. |
| The raw app-server WebSocket transport is documented as experimental and unsupported. [S03] | Use authenticated platform runner traffic across machines, not public raw Codex endpoints. |
| The CLI supports explicit session resume. [S04] | A CLI adapter is possible, but must select an explicit session, never an ambiguous “last session” in a multi-user worker. |
| Codex configuration has user/project scope and trust rules. [S05] | Pin and inspect effective configuration. A project file must not silently become the fleet's security policy. |

The Python SDK and the raw transport have different documented maturity boundaries. Do not flatten them into “everything under app-server is stable” or “there is no Python SDK.” Test the specific surface you use.

Before shipping an adapter, record SDK and CLI versions, supported authentication mode, thread-start/resume behavior, interruption behavior, child-agent controls, usage events, sandbox enforcement, working-directory isolation, and filesystem persistence. A successful import is not this compatibility test.

Start fleet operation with native spawning disabled, or with a small explicit, budgeted allowance. A larger allowed native tree should require evidence that all its children are included in resource accounting. Section 11 explains why.

<a id="architecture"></a>
## 5. The system architecture

```text
Browser / CLI / researcher / existing coding agent
                        |
                   HTTPS or MCP
                        v
+---------------------------------------------------------------+
| FastAPI control plane                                         |
| auth, projects, agents, chats, runs, task API, operator controls |
| NO long-running Codex turns inside request handlers             |
+---------------------------+-----------------------------------+
                            |
              short authoritative transactions
                            v
+---------------------------------------------------------------+
| PostgreSQL                                                    |
| tasks, activations, attempts, inboxes, waits, budgets, gates,    |
| effect intents, artifact metadata, event history, outbox        |
+-------------------+----------------------------+--------------+
                    |                            |
          scheduler / reconciler          outbox / notifications
                    |                            |
           admitted leased work           UI / wakeup hints
                    v
+---------------------------------------------------------------+
| CPU runner services on one or many machines                    |
| local slot manager, process supervision, scoped credentials    |
|  + isolated Codex harness  + isolated Codex harness  + ...       |
|  + pinned workspace       + pinned workspace                   |
+----------------------------+----------------------------------+
                             |
                  authorized platform tools
                             v
+----------------------+  +----------------------+  +-----------+
| Task / inbox service |  | Effect / publication |  | Job API   |
| request, reply, wait |  | service               |  | CPU / GPU|
+----------------------+  +----------------------+  +-----------+
                                  |                       |
                         immutable artifacts       Slurm / job
                         in object storage          executors
```

These are responsibility boundaries, not a demand for a microservice per box. Initially they can share one Python repository, deployment image, and database, with separate API, scheduler, runner, and reconciler processes.

The runner should usually pull admitted work over authenticated outbound HTTPS. Your API remains reachable; the worker does not need an inbound public Codex port. The runner reports actual available resources and accepts only what it can supervise.

Separate four concerns:

**Control** decides who may do what and records durable transitions. **Execution** runs model/tool loops and subprocesses. **Effects** perform authorized external mutations. **Evidence** records what happened and whether the output meets its contract.

An LLM is not required to decide whether an expired lease should be reaped, whether a dependency is complete, or whether a tenant has budget left. It is useful for proposing a plan, investigating evidence, authoring a change, or challenging a claim.

---
<a id="invariants"></a>
## 6. The contracts that make the system correct

Make these executable invariants before making an elaborate agent hierarchy.

| Invariant | What must enforce it |
|---|---|
| At most one attempt is currently authorized to mutate a Chat's execution state | Transactional claim, Chat execution epoch, attempt identity, and lease checks |
| Old processes cannot publish as the current attempt | Fenced completion and publication APIs |
| An idle or waiting Chat does not reserve an execution slot | Explicit yield and runner cleanup |
| A committed inbox message is not lost because a receiver went to sleep | Transactional message sequencing, wait registration, and wake reconciliation |
| A retry does not redefine the logical operation | Stable task, activation, and effect identities |
| A child cannot exceed its parent's authority or spending allowance | Server-side lineage policy and admission checks |
| A review approval applies only to the revision actually reviewed | Artifact digests, input manifests, and gate version checks |
| Success of a process is not acceptance of its output | Separate execution and verification states |
| A notification is not the only record that work exists | Durable database state and periodic reconciliation |
| A claimed cancellation is not falsely reported as confirmed termination | Distinct cancellation and resource-release states |
| Every task has a finite route to termination or escalation | Deadlines, attempt limits, wait timeouts, and budget limits |

“At most one authorized attempt” is intentionally not “at most one process exists.” A network-partitioned machine may continue running after its lease expires. The platform must reject its stale writes even before that machine can be stopped.

Likewise, a fencing token only protects resources that validate it. An agent holding unrestricted GitHub, object-storage, or deployment credentials can bypass your fenced publication path. Authority and credential isolation must agree.

Use database time for leases. Use a monotonic local clock for process timeout measurement. Avoid deciding lease ownership from two machines' wall clocks.

<a id="state"></a>
## 7. Tasks, activations, attempts, and state machines

### 7.1 Separate work identity from execution identity

A **Task** is an intended outcome: “Produce the indexing chapter for design revision 7.” It has a Goal, DoneContract, immutable input references, dependencies, owner scope, and budget.

An **Activation** is one bounded opportunity to advance a Chat or Task. It might plan, write, review, or consume new results. A normal wakeup creates a new activation.

An **Attempt** is an execution attempt of that activation on a worker. A crash and retry create another attempt, not a new logical task. This distinction preserves error history without treating ordinary conversations as repeated failures.

A **ThreadBinding** maps a Chat to a particular Codex runtime history. It records runtime location or storage identity, provider thread ID, SDK/runtime versions, and continuity mode. A rehydrated fresh thread gets a new binding.

An **ExecutionGrant** records what the attempt may consume: local runner capacity, provider-admission allowance, spending reservation, expiry, and child allowance. These reservations have different release conditions; a dead local process does not prove an outstanding provider request was unbilled.

### 7.2 Suggested state machines

```text
Task:
  BLOCKED -> READY -> WORKING -> PRODUCED -> VERIFYING -> ACCEPTED
                               |              |
                               +<-- REVISION_REQUIRED
  terminal alternatives: FAILED, CANCELLED, BUDGET_EXHAUSTED

Activation:
  READY -> RUNNING -> COMPLETED
                    -> YIELDED
                    -> RETRY_PENDING -> READY
                    -> FAILED / CANCELLED

Attempt:
  CLAIMED -> STARTING -> RUNNING -> FINISHED
              |           |
              +-----------+-> FAILED / EXPIRED / CANCEL_REQUESTED
                                              -> STOP_CONFIRMED

Chat scheduling state:
  IDLE / READY / RUNNING / WAITING / CLOSED
```

These states are a proposed model, not vendor enums. Store cancellation intent separately when an attempt may still be executing. An expired attempt can be unauthorized while its termination status remains unknown.

A task in `PRODUCED` has candidate output. A task in `ACCEPTED` has passed the required checks for that exact output. Finishing a Codex turn with confident prose does not perform that transition.

### 7.3 What a task assignment contains

```json
{
  "schema_version": 1,
  "kind": "write_lesson",
  "goal": "Explain composite index ordering with a runnable counterexample",
  "input_manifest": "artifact://course/design/revision-7",
  "done_contract": {
    "required_outputs": ["lesson.md", "lab.sql", "solutions.md"],
    "checks": ["technical_review", "learner_review", "lab_execution"],
    "acceptance_policy_revision": "course-policy-v1"
  },
  "output_scope": "modules/composite-indexes/",
  "allowed_tools": ["read_project_file", "write_attempt_artifact", "request_task"],
  "limits": {
    "max_child_tasks": 2,
    "max_plan_depth": 2,
    "max_activations": 8,
    "max_attempts_per_activation": 3
  }
}
```

This is an application payload example. Production IDs, budgets, deadlines, policy versions, and authorized source references are assigned and validated by the platform. Do not accept identity or permission claims solely because the model included them in JSON.

### 7.4 Static and dynamic workflows can share one engine

A static workflow has a mostly predetermined dependency graph. A Dynamic Workflow lets an agent propose additions or revisions to that graph.

In both cases, the host validates the graph before enabling work. Require acyclic dependencies, authorized task kinds, bounded task count and depth, valid resource requests, and remaining lineage budget. Store `plan_revision`, and accept a replan only against the revision the planner read. Reject conflicting stale plans rather than silently mixing them.

Use deterministic dependency handling for routine readiness. Wake a planning agent for genuine decisions, such as conflicting evidence or a failed hypothesis, not for every child completion.

<a id="postgres-protocol"></a>
## 8. The PostgreSQL execution protocol

PostgreSQL documents `SKIP LOCKED` as useful for queue-like consumers, while warning that it gives an inconsistent view for general-purpose reads. It is a way to select work without waiting on another consumer's row lock, not an implementation of leases, retries, or durable workflows. [S06]

The following is a proposed protocol. Appendix A supplies a starter shape, not all migrations or production endpoints.

### 8.1 Claim a bounded activation

Reserve or provisionally acquire admission capacity first. Then use a short transaction to claim a runnable Chat and its activation. Do not claim thousands of jobs into a worker's memory merely to wait for a provider slot.

A Chat selection building block is:

```sql
SELECT id
FROM agent_chats
WHERE schedule_state = 'READY'
  AND ready_at <= clock_timestamp()
  AND current_attempt_id IS NULL
ORDER BY priority DESC, ready_at, id
FOR UPDATE SKIP LOCKED
LIMIT 1;
```

This fragment assumes the transaction has already narrowed the authorized project/run/resource partition. It is not a complete fair scheduler or an authorization check.

While holding the selected Chat lock, revalidate that the run permits dispatch and that an eligible activation exists. Increment the Chat's monotonically increasing `execution_epoch`; create a fresh attempt ID and unguessable attempt token; set the lease deadline; connect the Chat and activation to that attempt; persist the execution grant, event, and outbox entry; then commit.

Only after the commit may the runner launch Codex. A lost claim response is recovered by the claim request's idempotency key, not by creating a second claim blindly.

The epoch belongs to the **Chat execution authority**, not to a counter that resets whenever a new Task is created. Resource-specific authorities, such as a publication branch, can also need their own version checks.

### 8.2 Keep lock order consistent

Define one lock order for every handler. A workable convention is quota/grant records, run control records, Chats sorted by ID, activations, then attempts. Use compatible shared locks on run control where appropriate, rather than serializing every claim with an exclusive update of one run row. Revalidate after taking the relevant locks.

Do not lock a child Chat and then synchronously lock its parent in one handler while another handler does the reverse. Prefer durable completion events followed by an idempotent parent-wakeup transaction. The source completion is committed even when the parent wakeup must be retried.

Never hold a database transaction open across a model call, subprocess, GPU job, HTTP upload, or reviewer decision.

### 8.3 Heartbeat without resurrecting a dead lease

A heartbeat must require all of the following to match: current attempt ID, execution epoch, runner identity, attempt token, allowed attempt state, and **a lease that has not already expired**. Extend the lease with database time only after these checks pass.

An expired worker cannot revive itself by sending a late heartbeat before the reaper happens to run. A failed heartbeat makes the runner stop initiating tools and begin interruption/cleanup. The server remains the authority even when local cleanup fails.

The lease duration must be longer than the chosen heartbeat interval plus realistic scheduling and network delays. For example, 15-second heartbeats and a 90-second lease are initial test inputs, not recommended universal production constants. Tune them using observed stalls and recovery goals.

### 8.4 Complete with a fenced transaction

Completion is not “write status = success.” The handler must lock the execution records, reject stale or expired authority, validate the result manifest and disposition, and atomically commit the accepted execution transition, artifact references, events, and outbox work.

Store a completion request key and body digest. Repeating the same accepted completion returns the same receipt. Reusing its key with different content is a conflict. A delayed completion from an old attempt is not accepted merely because its output looks useful.

If the result merits preservation, it can enter a quarantined evidence area, clearly labeled stale and unauthorized. That is different from promoting it as the task's current output.

### 8.5 Reap expired attempts safely

The reconciler conditionally expires the exact attempt and epoch it observed, invalidates that authority, records whether retry is allowed, and makes a retry activation claimable only under policy. It must not overwrite a later successful heartbeat or a newly claimed attempt.

Physical cleanup is separate. Mark the old runtime and any uncertain remote jobs for termination/reconciliation. Do not release its machine slot until the local supervisor confirms it is gone. Do not refund uncertain provider usage simply because the lease expired.

A replacement attempt may run on another machine after the old authority is invalidated. Its external operations must still obey effect-idempotency and conflict rules.

<a id="messaging"></a>
## 9. Durable messaging without lost wakeups

This is one of the most important parts of the design. A queue alone does not solve it.

### 9.1 The failure you must prevent

```text
Receiver: checks inbox and sees no reply
Sender:   commits the reply
Receiver: marks itself WAITING and stops

No further reply arrives. The receiver sleeps forever.
```

The fix is not faster polling. The check and transition to waiting must be coordinated with message insertion.

### 9.2 Use a Chat-local committed sequence

Maintain an `inbox_next_seq` on the destination Chat. A sender locks that Chat, allocates its next sequence number, inserts the message, records any required wakeup, and commits. Sequence allocation and message insertion share the transaction.

Do not advance a consumer cursor to the maximum global `BIGSERIAL` value it happened to see. Transactions can allocate IDs and commit out of order. That pattern can skip a lower-ID message committed later. Chat-local sequencing under the destination lock avoids that specific hole.

Every message has a stable deduplication key, destination Chat, authorized sender, request/correlation ID where applicable, type, body or artifact reference, and content digest. Duplicate delivery must not allocate a second sequence number. The same key with different content is rejected.

### 9.3 Acknowledge only the input actually delivered

When an activation starts, capture an input snapshot with a last-delivered inbox sequence. Later messages may arrive while the agent works. Completing the activation must not automatically acknowledge all messages now in the inbox.

Acknowledge only the consumed prefix from that snapshot, or use explicit message acknowledgments for more complex routing. Preserve newer messages. A failed activation leaves uncommitted consumption eligible for retry.

Not every message should wake every wait. For example, a progress update can be recorded without satisfying a wait for an accepted artifact. Define typed wake predicates and separate bookkeeping for non-actionable messages so they do not cause an infinite loop of empty activations.

### 9.4 Atomically yield or remain runnable

At the end of the bounded turn, lock the Chat, validate attempt authority, commit the appropriate acknowledgments, and evaluate its wait predicate against durable state.

If a relevant message or result is already available, finish the current activation and create or preserve a ready continuation. Otherwise, record the wait condition and set the Chat to `WAITING`. Clear its current attempt and release execution capacity after the runtime is safely drained.

A sender that commits before this transaction is visible to its readiness check. A sender that commits after it sees the waiting Chat and makes the continuation ready. Both paths preserve the message.

For dependency results recorded elsewhere, combine durable wait registration with an idempotent completion-to-wakeup reconciler. The reconciler must scan unresolved waits as well as consume notifications. This repairs the interval between a child committing and the parent wake event being processed.

### 9.5 A wait is a first-class record

```json
{
  "kind": "task_results",
  "request_ids": ["runtime-assigned-request-a", "runtime-assigned-request-b"],
  "policy": "all_terminal",
  "on_failure": "wake_with_failure_details",
  "timeout_seconds": 900,
  "resume_context": "artifact://run/continuation/current-revision"
}
```

Supported policies might include any result, all terminal results, a successful quorum, a specific reply, human approval, or an external job transition. Every policy needs explicit handling of failure, cancellation, timeout, and duplicate results.

A parent should not wait forever for “all successful” when one child has permanently failed. It needs a decision or terminal condition, not a silent deadlock.

### 9.6 Do not keep MCP calls open as distributed futures

Propose two application tools:

```text
request_agent_task(spec, idempotency_key)
  -> {request_id, task_id, status: "queued"}

register_wait(condition, continuation_ref)
  -> {wait_id, next_action: "finish_turn"}
```

These are your tools, not built-in Codex SDK methods. Their names can match your current API conventions.

The model records a compact continuation and ends its turn. Your adapter must verify that the turn really ended, or interrupt it after a bounded grace period. A tool returning `next_action: finish_turn` is only a protocol instruction until the host enforces the lifecycle.

When the result arrives, the platform creates a new activation and resumes or reconstructs the Chat. A waiting parent releases its runner slot before its children need that slot.

### 9.7 Notifications are acceleration, not correctness

PostgreSQL `NOTIFY` is useful for waking listeners after a transaction commits. Keep the durable inbox and task state as the source of truth; listeners and notifications are not a replayable message store. [S07]

The outbox publisher may send a notification or broker message. A periodic sweeper must still find committed runnable work after a listener, broker, or publisher fails.

---
<a id="adapter"></a>
## 10. The Codex adapter and bounded turns

### 10.1 Preserve the SDK, change its owner

Your current FastAPI code may look conceptually like this:

```text
HTTP request -> start Codex -> wait -> return answer
```

Move to:

```text
HTTP request -> commit run/task -> return 202 + IDs
Runner claim -> start/resume Codex -> stream evidence -> commit disposition
UI -> subscribe to durable progress and inspect results
```

FastAPI's `BackgroundTasks` mechanism is not a durable distributed executor. Its documentation directs substantial cross-process/server background work toward separate task infrastructure. [S08]

The runtime should live under a runner supervisor, not an HTTP worker whose restart can silently lose the assignment.

### 10.2 Minimal real Python SDK shape

The following uses the documented Python SDK shape, without pretending it is a fleet implementation. It requires the separately installed, pinned SDK and a configured authorized runtime. It has not been executed against Codex for this guide. [S01]

```python
# SDK usage sketch, not the orchestrator or a security configuration.
import asyncio
from openai_codex import AsyncCodex

async def main() -> None:
    async with AsyncCodex() as codex:
        thread = await codex.thread_start()
        result = await thread.run(
            "Explain the supplied task and identify missing prerequisites. "
            "Do not modify files or launch child work."
        )
        print(result.final_response)

if __name__ == "__main__":
    asyncio.run(main())
```

That prompt is not a security boundary. Configure enforced tool, sandbox, network, and credential policy before using any adapter with real work.

Do not replace the sample with `asyncio.gather` over 10,000 calls and call that orchestration. Async concurrency helps multiplex waiting I/O. It does not provide durable ownership, cost control, or recovery.

### 10.3 Define your own narrow adapter interface

The following names are an application interface to implement against your pinned SDK. They are not claimed SDK methods:

```text
AgentRuntimeAdapter
  probe_capabilities() -> CapabilityReport
  prepare_attempt(grant, input_manifest, thread_binding) -> RuntimeHandle
  execute_turn(handle, input_snapshot, deadline) -> TurnDisposition
  interrupt(handle, reason) -> InterruptReceipt
  inspect(handle) -> ObservedRuntimeState
  drain_and_checkpoint(handle) -> CheckpointManifest
  stop_and_confirm(handle) -> TerminationReceipt
```

`TurnDisposition` should be one of produced output, yielded for durable dependencies, needs human input, failed, or cancelled. It contains artifact references and typed evidence, not an unrestricted instruction to mutate arbitrary database rows.

The runner owns heartbeats, process groups or container handles, output limits, local disk limits, and cancellation propagation. An async task being cancelled does not prove its subprocess tree stopped. Its supervisor must inspect and confirm termination.

The adapter should track platform IDs separately from provider IDs. A platform Chat ID, runtime thread ID, provider request ID, and SDK session ID are not interchangeable. Log each only when actually exposed by the runtime.

### 10.4 Bounded turns need actual stopping rules

A turn can be bounded by wall-clock deadline, observed tool count, allowed child fan-out, usage budget where observable, and the maximum size of accepted output. Enforce the limits outside the prompt.

Not every boundary can be perfectly enforced through every SDK version. For example, an event may report usage only after a request finishes. The capability report must distinguish exact request admission, after-the-fact observation, and unsupported telemetry.

For long planning sessions, checkpoint a compact decision record periodically. Do not assume you can interrupt an arbitrary moment and restore the model's unexposed internal state elsewhere.

<a id="admission"></a>
## 11. Scheduling, quotas, budgets, and backpressure

### 11.1 Admission is an intersection of constraints

An activation can run only when all relevant constraints allow it:

```text
eligible task and satisfied dependencies
AND active run and valid authorization
AND Chat has no authorized current attempt
AND project/user fairness allowance
AND remaining lineage budget
AND provider/model admission allowance
AND local CPU/memory/process/disk capacity
AND compatible workspace and trust domain
```

A worker-local semaphore controls only that worker. Twenty workers each permitting 100 calls do not collectively implement a global limit of 100.

Start with a central durable grant allocator. As it becomes a measured bottleneck, allocate bounded sub-grants to schedulers or runner groups. Their combined grants must remain within the global budget. Do not treat an in-memory cache on each machine as an independent source of unlimited tokens.

### 11.2 Fairness must apply across tenants and task kinds

Use weighted project queues with bounded bursts, aging for old work, and deadline-aware handling where justified. Within a project, separate lanes for planning, authoring, review, recovery, and interactive responses.

Do not let bulk authors occupy every slot while the reviewers needed to finish their work remain queued. Reserve a small configurable fraction of capacity for critical-path coordination and review, or implement equivalent priority guarantees. Unused reserved capacity can be borrowed with a clear reclaim policy.

This is a proposed scheduling policy. Measure accepted work and waiting time before choosing exact weights. Avoid a single global `priority DESC` queue that lets one aggressive tenant starve everyone else.

### 11.3 Provider capacity is not the same as harness capacity

OpenAI documents request and token limits with organization/project and model-related scopes. Actual capacity is account-specific. Abrupt traffic growth can trigger throttling even when a simple average looks acceptable. [S09]

One Codex turn may make multiple model calls. Native children and some runtime features may add more. Therefore, a limit of 100 simultaneous `thread.run` calls is not a precise limit on 100 requests per minute or any fixed tokens-per-minute value.

Choose one of two honest enforcement levels:

| Level | What you can claim |
|---|---|
| Every request passes a compatible, verified admission path | Request-level rate/cost admission, subject to provider semantics and in-flight usage |
| Only turn-level hooks and eventual usage are available | Conservative per-turn reservations and adaptive throttling; not exact request-level policing |

Do not assume a generic HTTP proxy can safely intercept every Codex authentication and transport mode. Validate compatibility and security before making it a dependency. With coarse controls, use more headroom, monitor throttling, and reduce concurrency when pressure rises.

Distinguish API project limits from capacity under a ChatGPT-authenticated Codex session. Do not assume one account mode provides another mode's billing, telemetry, or scaling guarantees. Use the supported authentication and deployment arrangement for your actual organization. More machines and more keys do not create permission to evade provider limits.

### 11.4 Bound recursive expansion

Let a granted parent runtime have an allowance of `k` concurrent native children. If there are `P` parents, an upper bound from that allowance alone is `P * (1 + k)` thread slots, before considering deeper nesting or other calls. Deeper nesting needs its own explicit accounting.

Initially, use independent platform tasks for delegated work and disable native children in the controlled fleet profile:

```toml
# Codex configuration example; verify effective config in the pinned runtime.
[agents]
enabled = false
```

The `agents.enabled` switch is documented. [S02] This policy does not mean native subagents are bad. It makes the first version's resource boundary inspectable.

Later, enable small native teams only when the runner reserves their worst-case local capacity, enforces depth/fan-out, captures actual child receipts, and accounts for usage. Never let a platform child also become an untracked native child accidentally.

### 11.5 Budget by lineage, not just by worker

A task should inherit constraints from its run, project, and authorized user. Child grants carve out the parent's remaining allowance; they do not invent new budget.

Maintain committed cost, outstanding reservations, unknown-outcome reservations, and available budget separately. When reported usage differs from the reservation, settle the difference. Include tool services, storage-heavy execution, and GPU jobs where relevant, not just language-model tokens.

OpenAI now documents both spend alerts and enforceable organization/project hard spend limits; enforcement can still lag and slightly exceed the configured value. Alerts alone are not caps. [S10]

Your platform should stop new admissions before its internal limit and treat provider controls as an additional boundary. A local stop cannot erase already accepted remote work. A claimed mathematical overspend bound is valid only when all chargeable paths and their maximum in-flight costs are actually bounded.

### 11.6 Retry policy must identify the failure

Retry transient transport failures with bounded exponential backoff and jitter. Do not retry authentication errors, permanent policy denials, exhausted budgets, or failed acceptance criteria indefinitely. A rejected solution often requires a new revision task, not repeating the same execution attempt unchanged.

Assign one owner for each retry layer. Hidden SDK retries plus runner retries plus queue retries can multiply work. Record which retries the SDK can perform, which are visible, and which activation retries the platform owns.

Preserve a stable logical request key across uncertain transport retries. Renewing an idempotency key on every timeout defeats its purpose.

<a id="collaboration"></a>
## 12. How the agents actually collaborate

Infrastructure reliability and reasoning quality are separate scaling problems. A perfectly durable system can coordinate 10,000 agents into producing a large, consistent mistake.

### 12.1 Use sparse collaboration, not an all-to-all group chat

For 10,000 participants, there are `10,000 * 9,999 = 99,990,000` possible directed peer relationships. This calculation does not predict actual traffic; it shows why unrestricted connectivity is an unhelpful default.

Organize work into bounded groups around a deliverable or resource boundary. A group can have a planner, several producers, independent reviewers, and a deterministic acceptance controller. These are roles assigned to activations, not permanently running processes.

A fleet can contain hundreds of such groups across projects. Group size should be chosen from coordination needs, not a desire to display a large swarm number. Start with a small team and expand only when measured accepted throughput improves.

### 12.2 Route information by purpose

Use direct messages for a specific request, task-result events for dependencies, project notes for shared evidence, and controlled summaries for cross-group coordination. Do not broadcast every thought, tool output, or full transcript.

An agent generally needs the current Goal, DoneContract, input manifest, relevant findings, open questions, and its output scope. It rarely needs the entire fleet's conversation history.

Use a digest plus references for large evidence. The digest must distinguish observations, assumptions, unresolved disagreements, and decisions. A summary that hides a failed test or uncertainty is not a faithful coordination artifact.

### 12.3 Plan hierarchically, execute against contracts

A planner proposes a bounded work graph. Domain planners can expand authorized subgraphs within their budgets. Producers work against immutable input revisions. Reviewers challenge the output. Deterministic code checks that the required evidence exists and that approvals refer to the candidate revision.

Aggregate results in bounded stages. A root planner should consume validated group-level summaries and exceptions, not 10,000 unfiltered reports. Preserve the ability to follow a summary back to its source artifact.

Do not make one LLM integrator the mandatory gate for every patch in the fleet. Shard integration by component or deliverable boundary, with explicit cross-component checks. Serialize only genuine conflicts, such as publication to the same branch or competing changes to the same schema contract.

### 12.4 Independent work is easier than tightly coupled work

Parallel source investigation, isolated test cases, independent module drafts, and alternative hypotheses can be good candidates. Ten agents editing the same central file against moving requirements create conflict rather than useful parallelism.

The planner should estimate coupling as part of decomposition: shared files, shared semantic assumptions, critical-path dependencies, and required context. A task too small can spend more effort on handoffs than on work. A task too large becomes difficult to verify and retry.

Use the metric **accepted useful output per total cost and elapsed time**. Compare against one strong agent and a small team. Record review defects and integration failures, not only completed attempts.

### 12.5 What the public engineering reports actually support

Cursor's January 2026 report describes experiments with hundreds of concurrent coding agents, difficulties with shared coordination, and a planner/worker approach. It also reports that an integrator role became a bottleneck. This is valuable first-party experience, not evidence that your workload will scale productively to 10,000. [S11]

Anthropic's multi-agent research account emphasizes scoped delegation and context separation, while describing substantial coordination and usage tradeoffs. It supports testing where parallel exploration helps, not assuming that additional agents always improve results. [S12]

The design in this guide borrows the lesson that boundaries matter. It does not reproduce either company's system or claim their outcomes as a benchmark for yours.

### 12.6 Disagreement has an explicit route

A reviewer returns a finding with a claim, evidence reference, severity, impact, proposed repair or experiment, and a recheck condition. The author can repair, dispute with evidence, or request adjudication. Set a bounded number of revision cycles before escalation.

Majority agreement is not factual verification. Several agents can share the same missing assumption. Prefer independent execution, source inspection, counterexamples, and changed-condition tests for important claims.

<a id="course-factory"></a>
## 13. A course factory with real pre-authoring adversaries

Your earlier `HOW_TO_MAKE_COURSE.md` requires real early invocations and explicit review gates before bulk authoring. Implement those gates as workflow constraints, not instructions that a lead agent may ignore.

### 13.1 A concrete graph

```text
Create course run, brief revision 1, and budget
                      |
         +------------+------------+----------------+
         |            |            |                |
     Researcher    Truth critic  Learner critic  Runtime verifier
         |            |            |                |
         +------------+------------+----------------+
                      |
           G0: actual invocations returned
                      |
      Curriculum/design proposal on pinned sources
                      |
           G1: independent design reviews pass
                      |
          One complete pilot lesson + practice
                      |
             G2: pilot review and tests
                      |
           Bounded parallel module production
             + per-module independent review
                      |
        Whole-course integration and acceptance
                      |
       Package -> extract -> verify extracted copy
```

Before G1, reviewers can check the brief, prerequisites, scope, source coverage, assessment design, feasibility, and test strategy. They cannot certify chapters that do not exist. After writing, they inspect the real artifacts.

Every early role must have a real attempt record and actual returned result. A list of persona names is not evidence of a team.

### 13.2 Gate approvals bind to revisions

A gate decision must include run ID, gate kind, exact subject manifest/digest, review policy revision, reviewer invocation references, findings, deterministic test receipts, decision, and timestamp.

Use an unexecuted template like this:

```json
{
  "gate": "G1_DESIGN",
  "status": "NOT_RUN",
  "subject_manifest_digest": null,
  "review_policy_revision": "course-policy-v1",
  "reviewer_attempt_ids": [],
  "blocking_findings": [],
  "test_receipts": [],
  "authorized_next_task_kinds": []
}
```

The gate controller fills actual values after execution. Do not initialize example files to `PASS`.

The task-creation API must reject authoring tasks when the required design gate does not pass for the current design. A later design revision invalidates affected approvals and downstream work according to the dependency graph.

### 13.3 Independence is more than a different display name

The reviewer must be a separately invoked execution with its own assigned context. For blind learner testing, do not include the answer key in that context. For technical verification, permit access to original evidence and the candidate being reviewed.

Track author/reviewer role conflicts. A worker machine may execute different roles at different times, but a single author transcript relabeled as a reviewer is not an independent review. Different models or approaches can add diversity, but do not guarantee independence or correctness.

A reviewer returns findings. A trusted validator records test execution. The controller applies policy. No one of these should fabricate the evidence of the others.

### 13.4 Course-scale example

Suppose a course has 40 modules. The platform can queue 40 producer tasks without starting all of them. Admit a bounded number, then send each produced revision to independent review. Ready review tasks compete in a lane that cannot be starved by new writing.

An author waiting for a review yields. A reviewer waiting for a lab result yields. The lab executor consumes CPU or database resources independently. A coordinator wakes only for blockers or integration decisions.

This is a real team even with modest simultaneous concurrency. “10,000 agents available” should not force a 40-module course to employ 10,000 agents.

<a id="artifacts"></a>
## 14. Artifacts, shared knowledge, and integration

### 14.1 Give every attempt an isolated writable area

Use a path or object namespace derived from run, task, activation, and attempt IDs. Restore an immutable input manifest, record source commits and patches, and keep candidate output separate from accepted project state.

Git worktrees can help organize concurrent edits, but they share repository metadata and are not a security boundary. For untrusted or differently authorized work, use stronger filesystem/process isolation and separate credentials. Repository isolation and security isolation solve different problems.

Do not let 100 authors write directly into one shared final directory. Publish immutable candidates, then assemble an accepted manifest from verified revisions.

### 14.2 Use publication as a controlled operation

An agent can create a candidate file. It cannot silently replace the accepted revision. A publication service validates current run authority, input revision compatibility, allowed output scope, required gates, content digest, and destination version before promoting it.

Use optimistic concurrency on the destination: “publish against revision 12.” A conflicting revision 13 means the candidate needs integration or revalidation. It is not a reason to overwrite someone else's accepted work.

For code, use component-specific integration queues and automated checks. For a course, use module manifests plus whole-course consistency checks. The mechanism should reflect the artifact's conflict boundaries.

### 14.3 Separate conversation history from curated knowledge

Persist raw transcripts for audit under retention policy. Persist curated notes, decisions, facts, and reports as separate versioned resources. Retrieval should supply relevant context with provenance, not dump all old messages into every new prompt.

A knowledge-base statement should carry its source, revision, status, and confidence/uncertainty where meaningful. Conflicting reports can coexist until resolved. Do not let the latest agent message overwrite the project's accepted facts by default.

### 14.4 Upload through scoped capabilities

Preserve your application-mediated upload pattern: an authorized MCP tool returns a short-lived upload capability for the permitted project and scope; the runner uploads bytes; the platform verifies size, digest, type policy, and ownership before creating an artifact revision.

For attempt outputs, restrict the capability further to that attempt's output area. Project-level analysis uploads can remain first-class Files without pretending they belong to a run. Do not expose master object-storage keys or reuse the MCP bearer token as a universal upload password.

---
<a id="effects"></a>
## 15. External effects, retries, and exactly-once claims

### 15.1 Be precise about the guarantee

Aim for **at-least-once execution with deduplicated committed transitions and controlled external effects**. Do not promise that a model call, shell command, or remote job physically executes exactly once under arbitrary failures.

The transactional outbox pattern commits application state and an outgoing-event record together. Delivery can still repeat, so consumers need idempotency. [S13]

The proposed completion transaction can therefore record an artifact candidate and a publication intent atomically. An effect worker later performs the authorized publication. If the delivery repeats, it must resolve to the same logical intent.

### 15.2 Identify intent independently of attempts

Use an effect key derived from a stable logical operation, such as:

```text
(run_id, task_id, operation_kind, intended_revision, destination)
```

The key must remain stable across retries of the same intent. **Do not include a changing attempt ID merely to make the key unique.** Include the content or parameter digest as a conflict check: the same key with different intended content must fail rather than silently reuse an unrelated result.

AWS's idempotent-API discussion makes the important distinction between identical-looking requests and the same caller intent. Caller-supplied request identity helps distinguish retries from deliberately repeated operations. [S14]

Your effect ledger should retain deduplication records for at least the supported retry and reconciliation horizon. An expired provider idempotency window does not magically remain protective because your task is still open.

### 15.3 The unavoidable ambiguous window

```text
Effect worker sends "create job"
Provider creates the job
Network response is lost
Effect worker does not know whether creation happened
```

Retrying immediately may duplicate the job. First use the stable request key, provider-side idempotency, or a queryable external identifier to reconcile the outcome.

Use states such as `PLANNED`, `DISPATCHING`, `CONFIRMED`, `FAILED`, and `UNKNOWN_OUTCOME`. Unknown is a real state, not a failure label that authorizes blind retries.

For providers without reliable idempotency or lookup, define a conservative policy: read-only retry, manual investigation, or a compensating operation when safe and meaningful. A refund or rollback is not always equivalent to an operation never having happened.

### 15.4 Fence the gateway, not merely the chat table

Every side-effect request must carry a task-scoped capability and current execution authority. The gateway checks the run, epoch, allowed operation, destination, and idempotency key before accepting the intent.

Once an authorized remote operation is in flight, later cancellation cannot guarantee it vanishes. Record its accepted intent and reconcile its result. Distinguish preventing a new effect from undoing a previously accepted effect.

Read-only research tasks can often avoid this complexity by never receiving mutation credentials. Allow producers to write only attempt-local candidates, and reserve shared publication for the trusted gateway.

<a id="migration"></a>
## 16. Persistence, affinity, and moving work between machines

### 16.1 Persist three different things

| Layer | What belongs there |
|---|---|
| Platform state | Goals, tasks, waits, messages, decisions, revisions, budgets, evidence, and audit history |
| Runtime conversation state | Codex thread/session history and version-specific runtime metadata |
| Workspace state | Checked-out source, generated files, patches, environment description, and execution artifacts |

A provider thread ID is not a backup of all three layers. Platform recovery must work even when resuming the old conversation is impossible.

Codex's documented thread operations distinguish stored history from loaded runtime state. Unsubscribing is not an immediate memory-freeing primitive; unloading includes a grace period. [S03] Plan resource release around observed lifecycle and safe process shutdown, not an assumption that each idle thread disappears instantly.

### 16.2 Support three continuity modes

**Sticky resume:** Route the next activation to the worker or persistent storage location holding the compatible runtime history. This is the simplest first implementation.

**Verified restoration:** Move a quiesced, integrity-checked runtime/workspace checkpoint to a compatible worker, using a persistence method tested for the pinned runtime. Do not copy a live shared runtime database and assume it is consistent. Do not accidentally distribute authentication files with the checkpoint.

**Rehydrated continuation:** Start a new Codex thread with the Goal, accepted decisions, current plan, compact conversation summary, pending requests, relevant messages, and immutable artifacts. Record a new ThreadBinding and label continuity `rehydrated`, not `exact_resume`.

Rehydration does not reproduce hidden model state or guarantee identical future output. It is a practical application-level recovery route with explicit provenance.

### 16.3 Affinity is a preference, not a permanent hostage situation

A scheduler can prefer a machine that has cached files and thread history. If that machine fails, the platform should eventually recover using a verified checkpoint or rehydration rather than blocking forever.

Keep durable storage references and workspace manifests independent of host-local path strings. A manifest records logical files and hashes; a runner resolves them into its local filesystem.

Do not point hundreds of unrelated tenants at one mutable `CODEX_HOME` for convenience. Test supported concurrent access, isolate trust domains, and treat runtime authentication state as sensitive. Codex's non-interactive documentation specifically warns that saved authentication material contains credentials. [S04]

### 16.4 Recovery from uncertain turn completion

A worker might finish a model turn but crash before committing its platform disposition. Inspect the persisted attempt evidence and runtime state, when available, before rerunning it.

Even with that inspection, external side effects require their own reconciliation. “The transcript says it created the job” is not a trusted remote job receipt.

The safe recovery order is: establish current authority, reconcile durable effect intents, restore or rehydrate context, then admit another bounded turn. Do not recreate the whole workflow just because one runtime thread vanished.

<a id="deployment"></a>
## 17. One machine, many machines, and 10,000 active executions

### 17.1 Start with one machine without baking it into the model

For development or a modest deployment, run separate services on one host:

```text
api
scheduler
reconciler + outbox publisher
cpu-runner with a small measured slot limit
postgres
artifact storage or an existing object-store endpoint
```

The runner can supervise multiple isolated harnesses. Sleeping Chats remain database records. Use the same claim protocol that remote runners will later use.

Docker Compose can package these services after you implement them. This guide does not provide fictional images or claim that a Compose file alone supplies the missing orchestration code.

Keep the API and runner process lifecycle separate even on one host. An API deployment should not terminate ongoing turns unnecessarily. A runner drain should stop new claims, finish or yield current work, checkpoint, and report termination before upgrade.

### 17.2 Add machines by adding runner capacity

Each runner registers a stable identity, software image/version, resource pools, supported capabilities, trust domain, available slots, and health. It polls or long-polls for eligible work with bounded batches.

Place CPU reasoning, memory-heavy analysis, untrusted code execution, and GPU jobs in appropriate pools. The scheduler should not assume every free slot is interchangeable.

An example application policy, not Codex or Kubernetes configuration:

```yaml
schema_version: 1
fleet:
  max_active_harnesses: 80
  scheduler_partition_count: 8
  max_native_children_per_attempt: 0
  require_fenced_publication: true
runner_defaults:
  max_active_harnesses: 4
  heartbeat_seconds: 15
  lease_seconds: 90
  unknown_runtime_action: quarantine_slot
workflow_defaults:
  max_tasks: 200
  max_plan_depth: 4
  max_attempts_per_activation: 3
  wait_timeout_seconds: 900
  review_capacity_share: 0.20
```

These numbers are starting hypotheses for testing. They do not certify that a four-slot runner fits a particular machine or that 80 harnesses fit your provider allowance.

### 17.3 Use measured resource envelopes

Measure the complete execution unit: SDK/runtime, child processes, test tools, workspace cache, logging buffers, and peak memory. Do not estimate from the size of the Python object representing a thread.

For a measured memory envelope `m`, the memory-only upper bound on local slots is:

```text
floor((usable_host_memory - reserved_memory) / m)
```

Then reduce it for CPU, process/file-descriptor limits, storage I/O, network, sandbox overhead, and provider admission. A memory-only bound is not an operational recommendation.

Illustrative total memory for 10,000 active execution units:

| Assumed measured memory per unit | Total before fleet overhead |
|---|---:|
| 0.25 GiB | 2,500 GiB |
| 1 GiB | 10,000 GiB |
| 2 GiB | 20,000 GiB |

These are arithmetic scenarios, **not measured Codex memory requirements**. A single very large machine and a multi-machine fleet differ in failure isolation and resource limits even when aggregate RAM is similar.

### 17.4 Calculate the provider demand explicitly

Let:

```text
C = admitted simultaneous activations
W = average active seconds per activation
r = average provider requests per activation
q = average provider-counted tokens per activation
R = allowed requests per minute
T = allowed tokens per minute
```

For a stable workload under these simplifying assumptions:

```text
activation throughput per second
  <= min(C / W, R / (60 * r), T / (60 * q))
```

This is a capacity model, not a promise. Separate constraints are needed for distinct input/output token limits, shared model families, request bursts, tool quotas, latency distributions, and other provider rules.

For a deliberately hypothetical workload with `C=10,000`, `W=60`, `r=4`, and `q=56,000`, sustaining that concurrency implies roughly:

```text
166.7 activations/second
40,000 provider requests/minute
560,000,000 provider-counted tokens/minute
```

Use your actual traces to replace these inputs. A larger host cannot solve insufficient provider capacity. Before enabling 10,000 active executions, obtain the appropriate authorized capacity and prove that your admission controller respects it.

### 17.5 Account for burst and shutdown behavior

Steady-state averages miss simultaneous cold starts, dependency installation, large checkouts, log flushes, retries, and mass cancellation. Ramp capacity gradually and measure the entire lifecycle.

If one large job finishes and releases thousands of dependent tasks, admit them through the same fairness and quota system. A dependency graph must not bypass admission simply because its parents completed together.

At 10,000 genuinely active executions, expect operational needs beyond one simple server: resilient control-plane services, managed credentials, bounded resource pools, tested failover, database capacity planning, and operator controls. Introduce components because the measurements demand them, not to decorate the diagram.

<a id="gpu"></a>
## 18. CPU reasoning and GPU jobs are separate resources

A Codex harness calling a hosted model does not require a local GPU merely to conduct its control loop. Your research workload may still need GPUs for training, evaluation, local inference, or other tools. Schedule those as separate jobs.

```text
CPU agent activation
  -> proposes experiment specification and resource request
  -> platform validates budget and authorization
  -> durable GPU job request
  -> agent registers wait and ends turn

GPU executor
  -> claims job under its own resource lease
  -> submits or launches using stable external job identity
  -> reports progress and artifacts
  -> reconciles observed completion

Job result
  -> wakes a new CPU agent activation
  -> agent analyzes evidence and decides what happens next
```

Do not hold a CPU reasoning slot or an open model call for hours while a training job runs. Conversely, a CPU agent lease expiring must not automatically resubmit an already running GPU job.

Record the scheduler's actual job identity and submission intent. On uncertain submission, reconcile first. Cancellation must propagate to the external scheduler and be confirmed there. A task status changing to cancelled in PostgreSQL is not proof that a GPU stopped consuming resources.

Keep job output collection independent of the agent's survival. A job's logs and artifacts should remain accessible when the agent that requested it has been replaced.

<a id="recovery"></a>
## 19. Failures, cancellation, pause, and recovery

### 19.1 Classify failures before acting

| Failure | Proposed response |
|---|---|
| Model/provider transient error | Bounded retry under rate and budget policy |
| Invalid credentials or denied authority | Stop dispatch; surface configuration/policy failure |
| Runner process crash | Expire authority, reconcile effects, retry within limits |
| Worker network partition | Reject expired authority; quarantine uncertain runtime resources |
| Child permanently fails | Wake parent with terminal result; do not wait for impossible success |
| Output fails review | New revision work with findings, not an invisible success retry |
| Database unavailable | Fail closed for new authoritative claims and effects; buffer bounded local diagnostics |
| Artifact upload uncertain | Retry by digest and upload intent; do not publish a missing artifact |
| Provider job outcome uncertain | Reconcile stable external identity before resubmission |
| Budget exhausted | Stop new admissions and route outstanding work to controlled completion or cancellation |

### 19.2 Cancellation is a protocol

Use distinct states for cancellation requested, interruption requested, runtime termination confirmed, and external jobs reconciled. The UI can immediately say “cancellation requested,” but must not report “all stopped” prematurely.

A run-level cancellation record prevents new work from being authorized. Propagate it to descendant tasks in bounded batches, interrupt active runtimes, cancel external jobs where permitted, and collect late results without promoting them as accepted output.

Every claim and effect-acceptance path checks the current run control generation. Define the exact race semantics: operations authorized before the cancellation boundary may still complete; operations after it must be rejected. Do not promise a global instantaneous stop across remote providers.

Keep reservations for unknown in-flight cost until usage reconciliation or conservative settlement resolves them. Expiry alone is not proof of zero usage; hold or conservatively charge the bounded exposure rather than automatically refunding it. Keep local slots quarantined until the supervisor confirms the processes are gone.

### 19.3 Pause is different from cancellation

A pause normally stops new admissions and lets bounded activations reach safe boundaries. A hard pause may interrupt active work. Record which behavior the user requested.

Resume re-evaluates authorization, budgets, provider availability, artifact revisions, and expired waits. Do not blindly reactivate a month-old task against changed project state.

### 19.4 Database failover deserves its own threat model

A durable design still depends on the database's actual persistence and failover guarantees. If acknowledged state can be lost during recovery, a remote effect may outlive its corresponding local record.

Define recovery point and recovery time objectives, backup testing, and the behavior after uncertain failover. Stable external idempotency keys and reconciliation remain necessary. Do not claim exactly-once external behavior from a fencing counter whose authoritative history may have been rolled back.

Start with one authoritative region. Multi-region active-active control introduces conflict and consistency questions that should not be smuggled into a first implementation.

<a id="database-scale"></a>
## 20. Keeping PostgreSQL and the control plane healthy

### 20.1 Do not give every agent a database connection

Agents call scoped platform tools. API and worker services use bounded connection pools for short transactions. Ten thousand sleeping Chats should not produce ten thousand idle database connections.

If using PgBouncer transaction pooling, note that its feature matrix does not support session-level `LISTEN` or session advisory locks in that mode. Use a dedicated session/direct connection for listeners rather than assuming a pooled transaction can preserve that state. [S15]

### 20.2 Separate hot state from bulky evidence

Keep frequently updated execution rows small. Put large transcripts, stdout, tool output, and artifact bytes in chunked object storage, with database references and integrity metadata.

Do not update one enormous JSON history field on every token. Batch progress and log writes. Define bounded log buffers and backpressure so a noisy subprocess cannot exhaust runner memory or database I/O.

Preserve append-only semantic events such as claim, yield, effect acceptance, gate result, and cancellation. Token-level streaming can use a different retention and storage path. “Durable history” does not require replaying every token through the core transaction tables.

### 20.3 Partition work without changing its identity

Use stable scheduler partitions and resource pools. Initially multiple scheduler instances can consume eligible rows with the claim protocol. Later, assign partition ownership with leases and a placement generation.

Changing the partition count needs an explicit migration strategy. Naively changing `hash(id) % partition_count` while old owners are active can create duplicate ownership. Store the placement generation or use a stable mapping directory.

Keep duplicate-safe reconciliation even with partition ownership. A scheduler lease is an optimization for ownership, not an excuse to remove per-attempt fencing.

### 20.4 Watch hot counters and fan-in

One global “spent tokens” row updated for every event can become a lock bottleneck. A giant root run record updated for every child heartbeat can do the same.

Use per-attempt usage records, bounded budget sub-grants, batched aggregation, and separate read projections. Maintain hard constraints at admission and settlement without forcing every log event through one global mutex.

Use dependency indexes and targeted wakeups. Avoid scanning every task in the fleet whenever one child finishes. For large fan-in, maintain idempotently updated completion records or staged aggregation, and periodically reconcile the aggregate against authoritative child state.

### 20.5 Notifications can be lost without losing work

A dashboard projection, outbox consumer, or broker subscriber may fall behind. Persist a cursor or durable consumer state, make handlers idempotent, and provide a repair path from authoritative records.

Use desired-versus-observed reconciliation as an architectural pattern. Kubernetes documents this controller model, but the pattern does not require Kubernetes to be useful in your FastAPI application. [S16]

<a id="temporal"></a>
## 21. When to adopt Temporal, and what it should own

### 21.1 The decision is about lifecycle complexity

Ten thousand mostly idle records do not by themselves require Temporal. Many long-lived workflows with nested waits, timers, cancellation, versioned continuation, and difficult recovery can make an established durable engine worth adopting earlier.

My decision rule is: retain the small PostgreSQL engine when its lifecycle is explicit, understood, and well tested. Consider Temporal before custom timer, signal, recovery, and workflow-versioning code becomes a major product of its own. Do not wait for an arbitrary agent-count threshold.

### 21.2 Map responsibilities explicitly

| Concern | PostgreSQL-native path | Temporal-owned lifecycle path |
|---|---|---|
| Workflow state transitions | Your typed state machine | Workflow execution |
| Durable waits and timers | Wait table plus reconciler | Workflow waits/timers |
| Incoming durable result notification | Inbox and wake protocol | Signal/Update handling plus application identity |
| Codex turn execution | Leased runner activation | Bounded Activity on a worker |
| Retry of a bounded turn | Your activation retry policy | Activity retry policy, with application reconciliation |
| Product entities and files | PostgreSQL/object store | PostgreSQL/object store |
| External effect intent and publication policy | Application services | Application services, not magically replaced |
| UI/history projections | Platform events/read models | Platform projections fed by lifecycle events |

Temporal requires deterministic Workflow behavior; put model calls, external I/O, and other nondeterministic work in Activities rather than directly in replayed Workflow logic. [S17]

Activities can retry, so operations still need appropriate idempotency and external-effect reconciliation. [S18] Durable execution does not make a deployment API, payment-like mutation, or GPU submission physically exactly once.

### 21.3 Suspend the workflow, not a worker Activity

A workflow waiting for children can use durable message/timer mechanisms. Do not implement the entire lifetime of a sleeping agent as one long-running Activity that blocks waiting for inbox messages.

Temporal's Python documentation distinguishes Queries, Signals, and Updates; a signal's acceptance is not proof its handler finished processing. [S19] Keep your request/result correlation and acknowledgment semantics explicit.

Use bounded workflow scopes and history management. Continue-As-New starts a fresh history under the same workflow identity with a new run identity; pass the compact state needed for continuation. [S20] Do not put every token event or every fleet participant into one eternal root history.

### 21.4 Avoid two competing orchestration authorities

For a given run, choose one lifecycle owner. Do not have both a PostgreSQL reaper and Temporal independently retry the same activation.

During migration, mark each run with its engine kind and generation. Drain or explicitly transfer runs at supported boundaries. PostgreSQL can remain the product store and a projection of workflow state without being an independent retry engine for Temporal-owned work.

Temporal workers may still run your Codex adapter, resource admission, sandbox, publication gateway, and GPU-job adapter. Adopting the engine replaces specific lifecycle responsibilities, not every part of the platform.

---
<a id="alternatives"></a>
## 22. Where Celery, NATS, Ray, and Kubernetes fit

These products solve different problems. Adopting all of them is not a scaling strategy.

| Technology | Useful role | What it does not remove |
|---|---|---|
| Celery | Distribution of bounded background tasks when you already operate it | Your durable Chat identity, accepted artifacts, gates, and effect reconciliation |
| NATS JetStream | Durable delivery/wakeup infrastructure and consumer flow control | Authoritative workflow state and acceptance policy |
| Ray | Distributed Python computation and actor-based execution where that fits the workload | Application-specific durable state, effect policy, and recovery design |
| Kubernetes | Placement, isolation, resource limits, and lifecycle of worker services/jobs | The meaning of agent tasks, messages, reviews, and budgets |
| Temporal | Durable workflow lifecycle and waits | Trust boundaries, model quality, sandboxing, and external-effect semantics |

Celery explicitly warns that synchronously waiting for subtasks can deadlock when the worker pool is exhausted. That is the same resource dependency this guide avoids by yielding parents. [S21]

JetStream pull consumers offer bounded fetch and acknowledgment-related flow control. Use these controls if delivery volume warrants a broker, but do not confuse a broker acknowledgment with acceptance of the agent's work. [S22]

Ray's actor fault-tolerance documentation explains that restoring application state requires explicit work; actor restart alone does not reconstruct arbitrary user state. [S23]

Kubernetes resource requests and limits help place and constrain execution units. Autoscale runners from runnable work and available admission capacity, not from the number of registered Agent records. [S24]

Choose an addition because it replaces a clearly identified responsibility or solves a measured bottleneck. A reasonable first system needs none of Celery, NATS, Ray, or Kubernetes if your PostgreSQL state machine and supervised runners meet the workload.

<a id="apis"></a>
## 23. Application APIs and authorization

### 23.1 Suggested API surface

These are proposed platform endpoints, not OpenAI endpoints.

| Endpoint | Contract |
|---|---|
| `POST /workflow-runs` | Validate goal and authorization; atomically create run; return `202` and durable IDs |
| `POST /tasks` | Create a bounded authorized task against current plan/gates |
| `POST /chats/{id}/messages` | Deduplicated durable message insertion and wake evaluation |
| `GET /requests/{id}` | Read result or explicit pending/terminal status |
| `POST /runner/claims` | Claim work idempotently under resource admission |
| `POST /attempts/{id}/heartbeat` | Extend only valid current authority |
| `POST /attempts/{id}/complete` | Fenced, idempotent execution disposition |
| `POST /attempts/{id}/wait` | Register a durable wait, not a blocking response stream |
| `POST /effects` | Accept an authorized stable effect intent |
| `POST /workflow-runs/{id}/cancel` | Persist cancellation request and generation |
| `GET /workflow-runs/{id}/events` | Authorized, cursor-based semantic event feed |

Use an explicit request idempotency key plus a canonical body digest for mutation endpoints. Reuse returns the original result; a mismatched body returns a conflict. Authenticate first, and scope the key to the authorized caller/project so unrelated users cannot collide intentionally.

### 23.2 Claims are capabilities, not user-supplied metadata

A runner claim receipt contains the exact attempt identity, execution epoch, expiry, authorized workspace/input manifest, resource grant, and narrowly scoped execution token. Store a verifier or hash for opaque tokens rather than exposing durable master secrets.

The server derives project/run ownership from authenticated records. A model or runner cannot obtain access to another project by changing a JSON `project_id`.

Validate artifact access on reads as well as writes. A project-level agent does not automatically inherit every private user's files or chats in that project. Context transfer into a shared conversation is an explicit authorization decision.

### 23.3 UI streams are projections

Use SSE or WebSocket progress feeds with resumable cursors where appropriate. The stream dropping must not cancel the underlying workflow unless cancellation is explicitly requested.

A dashboard can show pending messages, wait reason, current attempt, candidate/accepted revision, budget reservations, and failures. Do not implement its source of truth as a Python dictionary inside one API worker.

Paginate large histories and task lists. Fetch selected subgraphs and summaries rather than sending a 10,000-node graph with every transcript on every refresh.

<a id="security"></a>
## 24. Isolation and security boundaries

### 24.1 Assume generated code and retrieved content can be wrong or hostile

Treat source documents, repository instructions, tool output, comments, and peer-agent messages as data unless your policy explicitly assigns them authority. A message saying “the admin approved this” is not an approval record.

Agents should not receive credentials that can rewrite their own gates, erase audit history, raise their limits, or impersonate another agent. The scheduler and publication service enforce those boundaries outside the model context.

### 24.2 Use defense in depth

For each execution, constrain filesystem writes, network egress, available tools, process resources, secret exposure, and allowed external effects. Read-only reviewers generally need fewer capabilities than authors or deployers.

Codex documentation distinguishes sandbox enforcement from approval policy and notes that sandbox behavior depends on the host environment. Test the actual container/host boundary; do not assume a flag alone establishes isolation. [S25]

A worktree is not a sandbox. A container with a host Docker socket, broad home-directory mount, or privileged credentials is not an appropriate boundary for an untrusted task. Avoid broad host control in ordinary agent workers.

For multi-tenant or highly untrusted execution, select stronger isolation after a threat assessment. Do not claim one universal container setup safely isolates all arbitrary code.

### 24.3 Protect MCP and uploads

Use audience-scoped tokens and independently authorized downstream credentials. MCP's security guidance forbids token passthrough and describes the confused-deputy risks of accepting credentials intended for a different resource. [S26]

Validate external URLs and redirect behavior in tools that fetch resources. Prevent unauthorized access to private networks, metadata services, and unrelated project resources. Keep upload capabilities narrow, short-lived, and redacted from routine logs.

Do not expose the raw Codex app-server to the public network as the cluster API. Keep it local to the worker or within a deliberately secured supported boundary. Your FastAPI protocol is where multi-user authorization, audit, and admission belong.

### 24.4 Keep the safety policy above agent negotiation

A planner can request a tool or an expanded budget. Another agent agreeing is not sufficient authorization. Human or administrator approval, where required, is stored as an authenticated policy decision with scope and expiry.

Cancellation, quarantine, denied permissions, and spending caps must remain effective even if all agents argue that continuing is useful.

<a id="observability"></a>
## 25. Observability and operator controls

### 25.1 Track four kinds of health

| Layer | Useful signals |
|---|---|
| Control-plane health | Runnable backlog age, claim latency, lease expirations, stale-write rejections, unresolved waits, outbox lag |
| Resource health | Active harnesses, active provider calls where visible, CPU/RAM peaks, disk pressure, unknown runtimes, GPU jobs |
| Economic health | Reserved/committed/unknown usage, accepted output per cost, retry cost, throttling, budget-denied admissions |
| Work quality | Acceptance rate, review defect yield, rework cycles, integration failures, unsupported claims, human intervention |

A growing number of completed attempts with a flat number of accepted artifacts is a warning, not success.

Record correlation IDs in logs/traces. Avoid putting every run, task, or Chat ID into metric labels, which creates a high-cardinality metrics problem. Use bounded dimensions such as project tier, pool, role, outcome, and model class where appropriate.

### 25.2 Explain why work is not running

Every pending task should have a readable reason: blocked dependency, awaiting review, budget unavailable, provider admission unavailable, no compatible worker, paused run, unresolved effect, human approval, or retry backoff.

A generic spinner labeled “agent thinking” is misleading when no model call is active.

Expose separate counts for logical agents, ready activations, live harnesses, native children, provider requests, and external jobs. Also show that some quantities are unavailable if the current adapter does not expose them.

### 25.3 Proposed initial service objectives

Set targets from your product needs and verify them under load. Examples for a first test campaign might be: no committed-message loss, zero accepted stale completions, recovery of expired work within two lease periods plus backoff, and bounded p95 dispatch delay when provider capacity is available.

These are proposed objectives, not measured results or universal production thresholds. Track correctness separately from latency. A fast system that duplicates irreversible effects is not healthy.

### 25.4 Operator controls must be cheap and reliable

Provide run/project/fleet pause, cancellation, maximum concurrency changes, provider circuit breakers, worker drain, quarantine, blocked-task inspection, and reconciliation actions. Audit each control operation.

The operator must be able to stop admission without invoking another language model. Keep an emergency control path independent of the overloaded worker pool.

<a id="testing"></a>
## 26. Validation and scale tests

### 26.1 Test correctness before buying concurrency

Build a deterministic fake adapter with controllable latency, messages, failures, usage, child requests, and effect outcomes. It should expose every transition the real adapter would report, without making model calls.

Run the orchestration with one logical agent, then 10, 100, 1,000, and 10,000 logical agents. Separately vary active slots. A test of 10,000 dormant records with 20 fake workers must be reported as exactly that, not “10,000 live Codex agents.”

Then execute a small real-Codex compatibility suite, followed by bounded real workload trials within authorized quotas. Only call a test a 10,000-active-execution test when instrumentation proves that level of actual concurrency, duration, resource consumption, and provider traffic.

### 26.2 Required failure-injection cases

| Injected event | Required observation |
|---|---|
| Reply commits just before receiver yields | Receiver becomes ready or consumes the reply; no permanent sleep |
| Reply commits just after receiver yields | Sender/reconciler makes continuation runnable |
| Duplicate message with same key/body | One durable message and sequence allocation |
| Same message key with different body | Conflict, not silent replacement |
| Late heartbeat after lease expiry | Rejected, even before reaper execution |
| Old worker completes after replacement starts | Current state and accepted artifacts remain unchanged |
| Completion response is lost | Retrying returns the same receipt without a new transition |
| Parent fills the last slot then delegates | Parent yields; child can obtain a slot |
| Process exits but remote effect outcome is unknown | Effect remains unresolved; no blind duplicate submission |
| Cancellation races with new child requests | Defined generation boundary; no unauthorized later expansion |
| Gate approved revision 7, candidate becomes revision 8 | Revision 8 cannot inherit revision 7's approval |
| Publisher emits event then crashes before acknowledging | Duplicate consumer delivery is harmless |
| Database/listener/broker restarts | Committed runnable work is rediscovered |
| One tenant creates a large fan-out | Other authorized tenants retain bounded service |
| Host disappears with runtime history | Verified restore or explicit rehydration, never invented continuity |

Also test unauthorized project access, credential leakage in logs/artifacts, output-size limits, disk exhaustion, worker software mismatch, and provider throttling.

### 26.3 Use an explicit load matrix

For each run, record logical population, ready population, admitted harnesses, maximum actual model requests, native children, average/peak memory, request/token usage, duration, failure injection, and acceptance outcomes.

Compare fake-adapter throughput, real-Codex turn throughput, and end-to-end accepted artifact throughput. These measure different things.

Use bursty and long-tail durations, not only identical fast fake tasks. Include a dependency fan-in storm and a mass-cancel operation. Test startup and cleanup resource peaks as well as steady state.

### 26.4 Evaluate whether more agents help

Choose representative tasks and fixed total budgets. Compare a single agent, a small team, and a larger team. Blindly evaluate the resulting artifacts against the same DoneContract.

Record wrong answers that pass self-review, source errors, integration defects, latency, cost, and how often a person must intervene. A platform that can schedule 10,000 independent executions still needs evidence that a particular team structure improves the work.

### 26.5 What the embedded reference model proves

Appendix B is a standard-library state model for selected invariants. Its tests exercise serialized transition logic, not actual PostgreSQL locking, distributed network behavior, SDK execution, security isolation, or throughput.

Use it to clarify the contract and as a starting point for property/concurrency tests against the real database implementation. Passing it cannot certify a production fleet.

<a id="roadmap"></a>
## 27. An implementation roadmap

### Phase 0: Independent design review and capability probe

Invoke real reviewers for SDK compatibility, distributed-state correctness, security, and capacity/cost before bulk implementation. Each receives this design and your current architecture, not a claim that the proposal is already approved.

Return actual findings and invocation receipts. Resolve blockers with evidence. If your execution environment cannot run separate reviewers, record the limitation and do not manufacture their sign-offs.

**DoneContract:** Current adapter capabilities are known; threat and failure models exist; the first vertical slice and its tests are approved against an exact revision.

### Phase 1: One durable Chat across worker restarts

Implement run/task creation, activation/attempt identity, transactional claim, heartbeat, fenced completion, attempt-local output, and a fake adapter. Move execution out of API request handlers.

**DoneContract:** Killing the worker never permits a stale completion to become current. Duplicate completion requests do not duplicate state transitions. Every attempt is inspectable.

### Phase 2: Durable inbox and yield/resume

Implement request/reply identity, per-Chat message sequencing, wait records, consumed-input snapshots, wake reconciliation, and bounded end-of-turn behavior.

**DoneContract:** Both reply/yield race orders pass real database concurrency tests. A parent waiting for a child releases its execution slot. Child failure wakes a parent according to policy.

### Phase 3: Controlled effects and artifact acceptance

Implement stable effect intents, uncertain-outcome reconciliation, immutable artifact revisions, publication authorization, independent reviews, and gate invalidation.

**DoneContract:** A repeated submission cannot silently create duplicate controlled effects. A changed revision cannot reuse stale approval. Producers cannot self-publish around required checks.

### Phase 4: Multi-machine runners and global admission

Implement runner identity, resource pools, bounded claims, project fairness, global quotas, native-child policy, drain, cancellation, and cleanup confirmation.

**DoneContract:** Two or more machines share work without duplicate authority. Provider and cost admission apply globally. Dead machines and noisy tenants do not corrupt other runs.

### Phase 5: 10,000 logical agents with a fake adapter

Exercise the load matrix, reconciliation, UI pagination, log storage, failure storms, and database recovery. Keep actual active slots explicit.

**DoneContract:** Publish measured counts and resources, zero-loss/stale-write correctness results, tail latency, and known bottlenecks. Do not relabel fake executions as Codex executions.

### Phase 6: Production workload qualification

Run real bounded tasks, measure per-activation resource/usage distributions, and compare team structures. Decide whether Temporal, a broker, or infrastructure orchestration replaces a measured problem.

**DoneContract:** A supported deployment configuration meets product latency, correctness, isolation, and budget requirements under representative failures.

### Phase 7: Qualify higher simultaneous concurrency

Increase real execution capacity only after obtaining provider capacity and proving each stage's behavior. Repeat correctness tests at the larger concurrency, not only throughput tests.

**DoneContract:** The claimed active-concurrency number is backed by traces, resource measurements, duration, quota configuration, and accepted-work results. A planned target is not reported as an achieved benchmark.

### Suggested repository boundaries

```text
app/
  api/                 # FastAPI routes and auth
  domain/              # typed states, contracts, policy
  orchestration/       # chosen lifecycle engine adapter
  scheduling/          # fairness, resource grants, admission
  messaging/           # inbox, waits, wake reconciliation
  effects/             # stable intents and external reconciliation
  artifacts/           # immutable revisions and publication
  reviews/             # findings, gates, conflict checks
  persistence/         # transactions and migrations
runner/
  supervisor/          # process/container lifecycle and cleanup
  adapters/codex/      # version-pinned SDK adapter
  adapters/fake/       # deterministic failure injection
  workspaces/          # manifests, restore, checkpoint
  telemetry/
tests/
  unit/
  database_concurrency/
  adapter_contract/
  failure_injection/
  security/
  load/
ops/
  deployment/
  dashboards/
  runbooks/
```

These are proposed module boundaries, not files bundled with this guide. Keep business policy out of SDK-specific adapter code so the runtime can evolve without rewriting the durable model.

<a id="runbooks"></a>
## 28. Operational runbooks

### Provider throttling rises

Reduce new admissions at the affected provider/model scope, preserve fairness, respect retry guidance, and inspect actual request/token demand. Separate rate exhaustion from spend or credential errors. Do not add workers or rotate keys to evade the limit.

### Workers expire while still running

Stop admitting replacements into occupied local slots; quarantine uncertain runtimes; inspect host scheduling, networking, and heartbeat delay. Verify stale effects are rejected. Tune leases only after understanding the failure, not to hide a supervision bug.

### A project creates a task explosion

Freeze new descendants at the run's expansion budget, preserve existing evidence, and wake a coordinator or operator with the rejected expansion request. Do not allow task creation to bypass the same quota lineage as execution.

### A workflow appears stuck

Inspect its wait predicate, deadline, child terminal states, inbox acknowledgments, required gate revision, provider admission, and worker compatibility. Run the durable wake reconciler. Do not restart the entire fleet as the first response.

### A remote job may have been duplicated

Pause automatic submissions for the affected intent, query external identities, preserve both receipts, and reconcile ownership/cost. Cancel a confirmed unintended duplicate only under authorized policy. Repair the effect key or uncertain-outcome handling before resuming retries.

### The database is recovering

Stop new claims and controlled effects. Keep bounded local diagnostics and interrupt work whose authority cannot be maintained. After recovery, establish the authoritative generation, reconcile attempts/effects, restore projections, and resume gradually.

### A runtime upgrade is needed

Pin the candidate version, run the adapter and sandbox compatibility suite, test old-thread continuity or explicit rehydration, canary a bounded pool, and drain old workers. Preserve the ability to identify which runtime produced each artifact.

<a id="implementation-prompt"></a>
## 29. A prompt for your implementation agents

Use this after attaching the guide and making the current repository available to the implementation environment:

```text
Read HOW_TO_CONTROL_10000_AGENTS.md and inspect the existing repository.

Build the smallest correct vertical slice for our FastAPI/PostgreSQL platform,
not a replacement product. Preserve Projects, user/project Agents, Chats,
Workflows, WorkflowRuns, Workflow Runners, knowledge resources, and Files.
Do not require a campaign entity or a TypeScript rewrite.

Before implementation, invoke real separate reviewers for:
1. Codex SDK/runtime compatibility.
2. Distributed-state correctness and lost-wakeup/fencing failures.
3. Security, authorization, and external effects.
4. Resource capacity, global admission, and cost controls.

Record their actual invocation receipts and findings. They review the proposal
and verification plan first; they cannot certify code that does not exist.
If real subagents are unavailable, disclose that and do not fabricate reviews.

Use the existing lifecycle engine when it is suitable. Otherwise begin with
the PostgreSQL path described in this guide. Do not run PostgreSQL and Temporal
as competing authorities for the same activation.

Implement in dependency order:
- Durable run/task/activation/attempt identities.
- Short transactional claims, leases, and Chat execution fencing.
- A fake runtime adapter with deterministic failure injection.
- Durable inbox, acknowledged input snapshots, wait/yield, and wake reconciliation.
- Controlled effect intents and immutable artifact publication.
- Independent review gates tied to exact input/output revisions.
- Multiple supervised CPU runners, global admission, and separate GPU jobs.

Use the installed Codex SDK's verified API. Pin versions and report actual
capabilities. Do not invent SDK functions. Keep native subagents disabled until
their resource and usage accounting is implemented and tested.

Run independent reviews and applicable tests at each phase boundary. Include
real PostgreSQL concurrency tests for the two lost-wakeup orders, late
heartbeats, stale completions, duplicate requests, and cancellation races.

Report separately: static checks, reference-model tests, database tests,
fake-adapter load tests, real-Codex tests, and measured active concurrency.
Never describe 10,000 database records or fake tasks as 10,000 active Codex agents.

Do not provision paid infrastructure, expand account limits, or grant broader
permissions without authorization. Deliver runnable code, migrations, tests,
operator instructions, and a truthful validation report for the scope completed.
```

<a id="acceptance"></a>
## 30. Release criteria and validation status

A qualified deployment has evidence for durable task ownership, lost-wakeup-safe waits, stale-worker rejection, bounded recursion, global admission, immutable artifacts, independent review gates, scoped effects, cancellation reconciliation, and the measured resource envelope of its declared concurrency.

It also has a tested explanation of what happens when exact thread resume is unavailable, a provider response is lost, a worker survives its lease, and an approval refers to an obsolete revision.

**Validation of this document:** The final Markdown was parsed; all 65 internal links resolve to the 59 explicit anchors; all 26 source labels resolve; both Python blocks pass syntax parsing; and the three JSON blocks, one YAML block, and one TOML block parse successfully. The reference model was extracted from this document and executed with Python 3.13.5: **26 tests passed**.

| Validation category | Result |
|---|---|
| Markdown navigation and source-label integrity | PASS |
| Embedded Python syntax and JSON/YAML/TOML parsing | PASS |
| Extracted reference-model tests | PASS: 26/26 |
| PostgreSQL DDL execution and concurrency tests | NOT RUN |
| Docker deployment | NOT RUN |
| Codex SDK/runtime compatibility and real agent execution | NOT RUN |
| Single-machine or multi-machine scale benchmark | NOT RUN |

This guide was researched and authored in this chat. No independent subagent team was launched here. The pre-implementation review workflow above is a requirement for your agent-capable platform, not a claim about how this document was produced.

The embedded model is deliberately small. It cannot demonstrate real database isolation, native SDK behavior, process termination, provider capacity, or 10,000-agent throughput. Those remain acceptance work for the implementation.

**The goal is not to keep 10,000 models talking. It is to let as many agents as the work justifies make bounded, authorized, recoverable progress, with evidence that their outputs are useful.**

---
<a id="schema"></a>
## Appendix A. Starter database shape

This PostgreSQL-oriented DDL illustrates key identities and constraints. It is not a complete application migration and was not executed against PostgreSQL here. Adapt names to your existing tables; do not paste it over a production schema.

Project membership, Agent definitions, WorkflowRuns, artifact revisions, resource grants, budgets, usage settlement, dependency edges, and detailed audit policy remain part of the surrounding application. Add their foreign keys and authorization constraints. IDs are supplied by the application, so this fragment does not depend on a particular database UUID-generation extension.

```sql
CREATE TABLE agent_chats (
    id uuid PRIMARY KEY,
    project_id uuid NOT NULL,
    agent_id uuid NOT NULL,
    workflow_run_id uuid,
    schedule_state text NOT NULL DEFAULT 'IDLE'
        CHECK (schedule_state IN ('IDLE', 'READY', 'RUNNING', 'WAITING', 'CLOSED')),
    execution_epoch bigint NOT NULL DEFAULT 0 CHECK (execution_epoch >= 0),
    current_attempt_id uuid,
    ready_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    priority integer NOT NULL DEFAULT 0,
    inbox_next_seq bigint NOT NULL DEFAULT 1 CHECK (inbox_next_seq > 0),
    inbox_acked_seq bigint NOT NULL DEFAULT 0 CHECK (inbox_acked_seq >= 0),
    state_revision bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (project_id, id),
    CHECK (inbox_acked_seq < inbox_next_seq)
);

CREATE INDEX agent_chats_ready_idx
    ON agent_chats (project_id, priority DESC, ready_at, id)
    WHERE schedule_state = 'READY' AND current_attempt_id IS NULL;

CREATE TABLE agent_tasks (
    id uuid PRIMARY KEY,
    project_id uuid NOT NULL,
    workflow_run_id uuid NOT NULL,
    parent_task_id uuid,
    plan_revision bigint NOT NULL,
    goal text NOT NULL,
    done_contract jsonb NOT NULL,
    input_manifest_digest text NOT NULL,
    status text NOT NULL DEFAULT 'BLOCKED',
    deadline timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (project_id, id),
    FOREIGN KEY (project_id, parent_task_id)
        REFERENCES agent_tasks (project_id, id)
);

CREATE TABLE agent_activations (
    id uuid PRIMARY KEY,
    project_id uuid NOT NULL,
    chat_id uuid NOT NULL,
    task_id uuid,
    cause_key text NOT NULL,
    status text NOT NULL DEFAULT 'READY'
        CHECK (status IN ('READY', 'RUNNING', 'COMPLETED', 'YIELDED',
                          'RETRY_PENDING', 'FAILED', 'CANCELLED')),
    not_before timestamptz NOT NULL DEFAULT clock_timestamp(),
    max_attempts integer NOT NULL CHECK (max_attempts > 0),
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (project_id, chat_id, id),
    UNIQUE (project_id, chat_id, cause_key),
    FOREIGN KEY (project_id, chat_id) REFERENCES agent_chats (project_id, id),
    FOREIGN KEY (project_id, task_id) REFERENCES agent_tasks (project_id, id)
);

CREATE TABLE agent_attempts (
    id uuid PRIMARY KEY,
    project_id uuid NOT NULL,
    chat_id uuid NOT NULL,
    activation_id uuid NOT NULL,
    runner_id uuid NOT NULL,
    execution_epoch bigint NOT NULL CHECK (execution_epoch > 0),
    attempt_number integer NOT NULL CHECK (attempt_number > 0),
    attempt_token_digest bytea NOT NULL,
    lease_until timestamptz NOT NULL,
    input_inbox_through_seq bigint NOT NULL CHECK (input_inbox_through_seq >= 0),
    status text NOT NULL,
    termination_status text NOT NULL DEFAULT 'NOT_CONFIRMED',
    completion_key text,
    completion_body_digest text,
    completion_receipt jsonb,
    started_at timestamptz,
    finished_at timestamptz,
    UNIQUE (project_id, chat_id, id),
    UNIQUE (chat_id, execution_epoch),
    UNIQUE (activation_id, attempt_number),
    FOREIGN KEY (project_id, chat_id, activation_id)
        REFERENCES agent_activations (project_id, chat_id, id)
);

ALTER TABLE agent_chats
    ADD CONSTRAINT agent_chats_current_attempt_fk
    FOREIGN KEY (project_id, id, current_attempt_id)
    REFERENCES agent_attempts (project_id, chat_id, id)
    DEFERRABLE INITIALLY DEFERRED;

CREATE INDEX agent_attempts_lease_idx ON agent_attempts (lease_until)
    WHERE status IN ('CLAIMED', 'STARTING', 'RUNNING');

CREATE TABLE agent_inbox (
    id uuid PRIMARY KEY,
    project_id uuid NOT NULL,
    chat_id uuid NOT NULL,
    seq bigint NOT NULL CHECK (seq > 0),
    dedupe_key text NOT NULL,
    message_type text NOT NULL,
    correlation_id uuid,
    body jsonb NOT NULL,
    body_digest text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (chat_id, seq),
    UNIQUE (chat_id, dedupe_key),
    FOREIGN KEY (project_id, chat_id) REFERENCES agent_chats (project_id, id)
);

CREATE TABLE agent_waits (
    id uuid PRIMARY KEY,
    project_id uuid NOT NULL,
    chat_id uuid NOT NULL,
    activation_id uuid NOT NULL,
    condition jsonb NOT NULL,
    continuation_manifest_digest text NOT NULL,
    status text NOT NULL DEFAULT 'PROPOSED'
        CHECK (status IN ('PROPOSED', 'ARMED', 'SATISFIED', 'TIMED_OUT', 'CANCELLED')),
    deadline timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    FOREIGN KEY (project_id, chat_id, activation_id)
        REFERENCES agent_activations (project_id, chat_id, id)
);

CREATE INDEX agent_waits_deadline_idx ON agent_waits (deadline)
    WHERE status = 'ARMED';

CREATE TABLE agent_effect_intents (
    id uuid PRIMARY KEY,
    project_id uuid NOT NULL,
    workflow_run_id uuid NOT NULL,
    logical_effect_key text NOT NULL,
    parameter_digest text NOT NULL,
    operation jsonb NOT NULL,
    status text NOT NULL DEFAULT 'PLANNED'
        CHECK (status IN ('PLANNED', 'DISPATCHING', 'CONFIRMED',
                          'FAILED', 'UNKNOWN_OUTCOME')),
    external_reference text,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (project_id, logical_effect_key)
);

CREATE TABLE agent_gate_decisions (
    id uuid PRIMARY KEY,
    project_id uuid NOT NULL,
    workflow_run_id uuid NOT NULL,
    gate_kind text NOT NULL,
    subject_manifest_digest text NOT NULL,
    review_policy_revision text NOT NULL,
    decision text NOT NULL
        CHECK (decision IN ('NOT_RUN', 'IN_PROGRESS', 'PASS', 'FAIL', 'BLOCKED')),
    reviewer_receipts jsonb NOT NULL DEFAULT '[]'::jsonb,
    findings jsonb NOT NULL DEFAULT '[]'::jsonb,
    test_receipts jsonb NOT NULL DEFAULT '[]'::jsonb,
    recorded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE agent_outbox (
    id uuid PRIMARY KEY,
    project_id uuid NOT NULL,
    aggregate_kind text NOT NULL,
    aggregate_id uuid NOT NULL,
    event_kind text NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    published_at timestamptz
);

CREATE INDEX agent_outbox_unpublished_idx ON agent_outbox (created_at, id)
    WHERE published_at IS NULL;
```

Important implementation obligations remain: validate same-run relationships, legal transitions, actor/tenant permissions, consumed-input bounds, attempt and recursion limits, monotonic epochs, and atomic events. `updated_at` is not automatically maintained by the default; update it explicitly or add an appropriate trigger.

The schema does not enforce the full workflow merely by existing. In particular, a JSON array of reviewer receipts must be populated from authenticated execution records, not trusted because a caller submitted it. A message's sequence is allocated under the destination Chat lock, not by independently guessing `MAX(seq) + 1`.

For multi-row transactions, preserve the lock order from Section 8. For queues, test starvation and index behavior under representative load. A correct small example is not a capacity certificate.

---
<a id="reference-model"></a>
## Appendix B. Executable reference state model

Copy the Python block below into `reference_state_model.py` and run:

```sh
python reference_state_model.py
```

It uses only the standard library and Python 3.10+ syntax. It was executed here with Python 3.13.5. All **26 tests passed**. These are deterministic model tests, not database, network, Codex, GPU, or scale tests.

Each method represents an already serialized authoritative transaction. The inbox model treats every new message as actionable; a production typed-wait implementation needs the additional predicate and acknowledgment handling described in Section 9. The model omits authentication, process cleanup, database isolation, resource placement, and remote execution deliberately.

The fake IDs and receipts inside tests are local fixtures. They are not evidence that real agents or reviewers were invoked.

```python
"""Reference transition model, not a database or Codex implementation.

Methods represent serialized authoritative transactions. Tests explore selected
interleavings only. There is no network, subprocess, security boundary, clock
synchronization, provider call, or throughput benchmark here.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import unittest
from itertools import count

_CHAT_IDS = count(1)  # Deterministic local fixture identities.


class Conflict(RuntimeError):
    pass


class StaleAuthority(RuntimeError):
    pass


@dataclass(frozen=True)
class Grant:
    chat_id: int
    attempt: int
    epoch: int
    input_through: int


@dataclass
class Chat:
    chat_id: int = field(default_factory=lambda: next(_CHAT_IDS))
    state: str = "READY"
    epoch: int = 0
    attempt_counter: int = 0
    next_seq: int = 1
    acked: int = 0
    lease_until: float = 0.0
    active: Grant | None = None
    messages: dict[str, tuple[int, str]] = field(default_factory=dict)
    completions: dict[Grant, tuple[int, bool, str]] = field(default_factory=dict)

    def send(self, key: str, body: str) -> int:
        if key in self.messages:
            seq, old_body = self.messages[key]
            if old_body != body:
                raise Conflict("Message key reused with different content")
            return seq
        if self.state == "CLOSED":
            raise Conflict("Chat is closed")
        seq = self.next_seq
        self.next_seq += 1
        self.messages[key] = (seq, body)
        if self.state in {"WAITING", "IDLE"}:
            self.state = "READY"
        return seq

    def claim(self, now: float, lease_seconds: float = 10.0) -> Grant:
        if lease_seconds <= 0:
            raise ValueError("Lease must be positive")
        if self.state != "READY" or self.active is not None:
            raise Conflict("Chat is not claimable")
        self.epoch += 1
        self.attempt_counter += 1
        grant = Grant(self.chat_id, self.attempt_counter, self.epoch, self.next_seq - 1)
        self.active = grant
        self.lease_until = now + lease_seconds
        self.state = "RUNNING"
        return grant

    def _authorize(self, grant: Grant, now: float) -> None:
        if (self.state != "RUNNING" or self.active != grant
                or grant.chat_id != self.chat_id or grant.epoch != self.epoch
                or now >= self.lease_until):
            raise StaleAuthority("Wrong attempt, epoch, or expired lease")

    def heartbeat(self, grant: Grant, now: float, extension: float) -> None:
        if extension <= 0:
            raise ValueError("Extension must be positive")
        self._authorize(grant, now)
        self.lease_until = max(self.lease_until, now + extension)

    def finish(self, grant: Grant, now: float, through: int,
               wait: bool = True) -> str:
        if grant in self.completions:
            old_through, old_wait, receipt = self.completions[grant]
            if (old_through, old_wait) != (through, wait):
                raise Conflict("Completion retried with different content")
            return receipt  # Return the old receipt; never mutate current work.
        self._authorize(grant, now)
        if not self.acked <= through <= grant.input_through:
            raise Conflict("Acknowledgment exceeds delivered input or regresses")
        self.acked = through
        unread = any(seq > self.acked for seq, _ in self.messages.values())
        self.state = "READY" if unread else ("WAITING" if wait else "IDLE")
        self.active = None
        self.lease_until = 0.0
        receipt = f"model-receipt:{grant.attempt}:{grant.epoch}"
        self.completions[grant] = (through, wait, receipt)
        return receipt

    def expire(self, now: float) -> bool:
        if self.active is None or now < self.lease_until:
            return False
        self.epoch += 1  # Invalidate old authority before replacement.
        self.active = None
        self.lease_until = 0.0
        self.state = "READY"
        return True  # This does NOT mean an old physical process was killed.


@dataclass
class Effect:
    payload: str
    state: str = "PLANNED"
    external_ref: str | None = None


@dataclass
class EffectLedger:
    effects: dict[str, Effect] = field(default_factory=dict)

    def accept(self, key: str, payload: str) -> Effect:
        old = self.effects.get(key)
        if old is not None:
            if old.payload != payload:
                raise Conflict("Effect key reused for a different intent")
            return old
        effect = Effect(payload)
        self.effects[key] = effect
        return effect

    def begin_dispatch(self, key: str) -> bool:
        effect = self.effects[key]
        if effect.state != "PLANNED":
            return False
        effect.state = "DISPATCHING"
        return True

    def mark_unknown(self, key: str) -> None:
        effect = self.effects[key]
        if effect.state != "DISPATCHING":
            raise Conflict("Only an in-flight dispatch can become unknown")
        effect.state = "UNKNOWN_OUTCOME"

    def confirm(self, key: str, external_ref: str) -> None:
        effect = self.effects[key]
        if effect.state == "CONFIRMED":
            if effect.external_ref != external_ref:
                raise Conflict("Contradictory external receipt")
            return
        if effect.state not in {"DISPATCHING", "UNKNOWN_OUTCOME"}:
            raise Conflict("No dispatched effect to reconcile")
        effect.state = "CONFIRMED"
        effect.external_ref = external_ref


@dataclass
class Reservation:
    amount: int
    actual: int | None = None
    unknown: bool = False


@dataclass
class Budget:
    limit: int
    reservations: dict[str, Reservation] = field(default_factory=dict)

    @property
    def available(self) -> int:
        used = sum(r.amount if r.actual is None else r.actual
                   for r in self.reservations.values())
        return self.limit - used

    def reserve(self, key: str, amount: int) -> None:
        if amount <= 0:
            raise ValueError("Reservation must be positive")
        if key in self.reservations:
            if self.reservations[key].amount != amount:
                raise Conflict("Reservation key reused with different amount")
            return
        if amount > self.available:
            raise Conflict("Insufficient remaining admission budget")
        self.reservations[key] = Reservation(amount)

    def mark_unknown(self, key: str) -> None:
        reservation = self.reservations[key]
        if reservation.actual is not None:
            raise Conflict("Already settled")
        reservation.unknown = True  # Retain the reservation.

    def settle(self, key: str, actual: int) -> None:
        if actual < 0:
            raise ValueError("Actual usage cannot be negative")
        reservation = self.reservations[key]
        if reservation.actual is not None and reservation.actual != actual:
            raise Conflict("Contradictory settlement")
        reservation.actual = actual
        reservation.unknown = False
        # An overrun is recorded, not erased to pretend the cap held.


def gate_allows(subject: str, approved_subject: str | None,
                author: str, reviewers: tuple[str, ...],
                blocking_findings: int = 0) -> bool:
    # The real implementation must resolve authenticated invocation receipts.
    return (bool(subject) and subject == approved_subject
            and len(set(reviewers)) >= 2 and author not in reviewers
            and blocking_findings == 0)


class TransitionTests(unittest.TestCase):
    def test_one_authorized_claim_per_chat(self) -> None:
        chat = Chat()
        chat.claim(0)
        with self.assertRaises(Conflict):
            chat.claim(1)

    def test_expired_heartbeat_cannot_resurrect(self) -> None:
        chat = Chat()
        grant = chat.claim(0)
        with self.assertRaises(StaleAuthority):
            chat.heartbeat(grant, 10, 10)

    def test_valid_heartbeat_extends_authority(self) -> None:
        chat = Chat()
        grant = chat.claim(0)
        chat.heartbeat(grant, 9, 10)
        chat.finish(grant, 15, 0)
        self.assertEqual(chat.state, "WAITING")

    def test_old_attempt_cannot_finish_after_replacement(self) -> None:
        chat = Chat()
        old = chat.claim(0)
        self.assertTrue(chat.expire(10))
        replacement = chat.claim(11)
        with self.assertRaises(StaleAuthority):
            chat.finish(old, 12, 0)
        self.assertEqual(chat.active, replacement)

    def test_duplicate_completion_does_not_mutate_new_attempt(self) -> None:
        chat = Chat()
        first = chat.claim(0)
        receipt = chat.finish(first, 1, 0)
        chat.send("reply", "ready")
        second = chat.claim(2)
        self.assertEqual(chat.finish(first, 3, 0), receipt)
        self.assertEqual(chat.active, second)

    def test_changed_completion_is_conflict(self) -> None:
        chat = Chat()
        grant = chat.claim(0)
        chat.finish(grant, 1, 0, True)
        with self.assertRaises(Conflict):
            chat.finish(grant, 2, 0, False)

    def test_reply_before_yield_is_not_lost(self) -> None:
        chat = Chat()
        grant = chat.claim(0)
        chat.send("reply", "result")
        chat.finish(grant, 1, 0)
        self.assertEqual(chat.state, "READY")

    def test_reply_after_yield_wakes_receiver(self) -> None:
        chat = Chat()
        grant = chat.claim(0)
        chat.finish(grant, 1, 0)
        self.assertEqual(chat.state, "WAITING")
        chat.send("reply", "result")
        self.assertEqual(chat.state, "READY")

    def test_cannot_ack_message_not_in_input_snapshot(self) -> None:
        chat = Chat()
        chat.send("first", "one")
        grant = chat.claim(0)
        late_seq = chat.send("late", "two")
        with self.assertRaises(Conflict):
            chat.finish(grant, 1, late_seq)
        chat.finish(grant, 2, grant.input_through)
        self.assertEqual(chat.state, "READY")

    def test_duplicate_message_allocates_one_sequence(self) -> None:
        chat = Chat()
        seq = chat.send("key", "same")
        self.assertEqual(chat.send("key", "same"), seq)
        self.assertEqual(chat.next_seq, 2)

    def test_changed_duplicate_message_is_conflict(self) -> None:
        chat = Chat()
        chat.send("key", "old")
        with self.assertRaises(Conflict):
            chat.send("key", "new")

    def test_unknown_effect_requires_reconciliation(self) -> None:
        ledger = EffectLedger()
        ledger.accept("intent", "create-job")
        self.assertTrue(ledger.begin_dispatch("intent"))
        ledger.mark_unknown("intent")
        ledger.accept("intent", "create-job")
        self.assertFalse(ledger.begin_dispatch("intent"))
        ledger.confirm("intent", "external-job-123")
        self.assertFalse(ledger.begin_dispatch("intent"))

    def test_changed_effect_intent_is_conflict(self) -> None:
        ledger = EffectLedger()
        ledger.accept("intent", "revision-1")
        with self.assertRaises(Conflict):
            ledger.accept("intent", "revision-2")

    def test_unknown_usage_keeps_reservation(self) -> None:
        budget = Budget(100)
        budget.reserve("first", 80)
        budget.mark_unknown("first")
        self.assertEqual(budget.available, 20)
        with self.assertRaises(Conflict):
            budget.reserve("second", 30)

    def test_actual_overrun_is_visible_and_blocks_admission(self) -> None:
        budget = Budget(100)
        budget.reserve("first", 80)
        budget.settle("first", 110)
        self.assertEqual(budget.available, -10)
        with self.assertRaises(Conflict):
            budget.reserve("second", 1)

    def test_stale_gate_does_not_approve_new_revision(self) -> None:
        self.assertFalse(gate_allows("revision-8", "revision-7", "author",
                                     ("reviewer-a", "reviewer-b")))

    def test_missing_reviewers_do_not_approve(self) -> None:
        self.assertFalse(gate_allows("revision-7", "revision-7", "author", ()))

    def test_author_is_not_own_independent_reviewer(self) -> None:
        self.assertFalse(gate_allows("revision-7", "revision-7", "author",
                                     ("author", "reviewer-b")))

    def test_matching_gate_with_independent_reviewers_approves(self) -> None:
        self.assertTrue(gate_allows("revision-7", "revision-7", "author",
                                    ("reviewer-a", "reviewer-b")))

    def test_blocking_finding_prevents_approval(self) -> None:
        self.assertFalse(gate_allows("revision-7", "revision-7", "author",
                                     ("reviewer-a", "reviewer-b"), 1))

    def test_expired_completion_rejected_before_reaper_runs(self) -> None:
        chat = Chat()
        grant = chat.claim(0)
        with self.assertRaises(StaleAuthority):
            chat.finish(grant, 10, 0)

    def test_consumed_input_can_enter_waiting(self) -> None:
        chat = Chat()
        chat.send("message", "work")
        grant = chat.claim(0)
        chat.finish(grant, 1, grant.input_through)
        self.assertEqual(chat.state, "WAITING")
        self.assertEqual(chat.acked, 1)

    def test_early_reaper_does_not_expire_live_attempt(self) -> None:
        chat = Chat()
        grant = chat.claim(0)
        self.assertFalse(chat.expire(9))
        self.assertEqual(chat.active, grant)

    def test_settlement_retry_does_not_reserve_again(self) -> None:
        budget = Budget(100)
        budget.reserve("first", 80)
        budget.mark_unknown("first")
        budget.settle("first", 50)
        budget.settle("first", 50)
        budget.reserve("first", 80)
        self.assertEqual(budget.available, 50)

    def test_grant_for_another_chat_is_rejected(self) -> None:
        first, second = Chat(), Chat()
        wrong_grant = first.claim(0)
        correct_grant = second.claim(0)
        with self.assertRaises(StaleAuthority):
            second.finish(wrong_grant, 1, 0)
        self.assertEqual(second.active, correct_grant)

    def test_distinct_chats_can_run_independently(self) -> None:
        first, second = Chat(), Chat()
        self.assertIsNotNone(first.claim(0))
        self.assertIsNotNone(second.claim(0))


if __name__ == "__main__":
    unittest.main(verbosity=2)
```

---
<a id="sources"></a>
## Sources and evidence notes

All web references below were consulted on **2026-10-08**. Documentation can change; pin software and recheck the installed capability rather than treating this date as a compatibility guarantee. URLs are shown explicitly for offline use. Source labels in the text link to the entries below.

These are primary documentation or first-party engineering reports. The reports are not independent reproductions, and none is presented as a benchmark of this proposed platform.

<a id="s01"></a>
### S01. OpenAI: Codex SDK

Python/TypeScript SDK surfaces, Python requirements, async usage, and runtime dependency packaging.

`https://developers.openai.com/codex/sdk/`  
Observed destination: `https://learn.chatgpt.com/docs/codex-sdk`

<a id="s02"></a>
### S02. OpenAI: Subagents

Native child configuration, including the per-session concurrency setting and legacy alias.

`https://developers.openai.com/codex/multi-agent/`  
Observed destination: `https://learn.chatgpt.com/docs/agent-configuration/subagents`

<a id="s03"></a>
### S03. OpenAI: App-server

Thread/turn lifecycle, persistence versus loaded state, and transport maturity boundaries. The raw transport documentation must not be mistaken for a production cluster orchestration contract.

`https://developers.openai.com/codex/app-server/`  
Observed destination: `https://learn.chatgpt.com/docs/app-server`

<a id="s04"></a>
### S04. OpenAI: Non-interactive mode

Explicit CLI session resumption and credential-handling cautions.

`https://developers.openai.com/codex/noninteractive/`  
Observed destination: `https://learn.chatgpt.com/docs/non-interactive-mode`

<a id="s05"></a>
### S05. OpenAI: Configuration reference

Configuration scope, trust, and version-dependent settings.

`https://developers.openai.com/codex/config-reference/`  
Observed destination: `https://learn.chatgpt.com/docs/config-file/config-reference`

<a id="s06"></a>
### S06. PostgreSQL: SELECT

Row locking and `SKIP LOCKED` queue-consumer behavior.

`https://www.postgresql.org/docs/current/sql-select.html`

<a id="s07"></a>
### S07. PostgreSQL: NOTIFY

Transactional notification behavior and listener semantics.

`https://www.postgresql.org/docs/current/sql-notify.html`

<a id="s08"></a>
### S08. FastAPI: Background Tasks

The scope of in-process background tasks and the distinction from distributed execution infrastructure.

`https://fastapi.tiangolo.com/tutorial/background-tasks/`

<a id="s09"></a>
### S09. OpenAI API: Rate limits

Request/token admission scopes and rate-limit handling. No published example tier is assumed to be the user's actual allowance.

`https://developers.openai.com/api/docs/guides/rate-limits`

<a id="s10"></a>
### S10. OpenAI API: Spend limits

Spend alerts versus hard limits, and delayed enforcement of tracked spending.

`https://developers.openai.com/api/docs/guides/spend-limits`

<a id="s11"></a>
### S11. Cursor: Scaling long-running autonomous coding

First-party engineering report published 2026-01-14. Used for lessons about coordination boundaries and bottlenecks, not a 10,000-agent guarantee.

`https://cursor.com/blog/scaling-agents`

<a id="s12"></a>
### S12. Anthropic: How we built our multi-agent research system

First-party engineering report published 2025-06-13. Used for scoped delegation, context separation, and coordination tradeoffs.

`https://www.anthropic.com/engineering/multi-agent-research-system`

<a id="s13"></a>
### S13. AWS Prescriptive Guidance: Transactional outbox pattern

Atomic state/outbox recording and the need to handle duplicate delivery.

`https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html`

<a id="s14"></a>
### S14. AWS Builders' Library: Making retries safe with idempotent APIs

Stable caller intent and request identity for retry-safe operations.

`https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/`

<a id="s15"></a>
### S15. PgBouncer: Features

Compatibility boundaries of transaction pooling, including session-based behavior.

`https://www.pgbouncer.org/features.html`

<a id="s16"></a>
### S16. Kubernetes: Controllers

Desired-versus-observed reconciliation as an architectural pattern.

`https://kubernetes.io/docs/concepts/architecture/controller/`

<a id="s17"></a>
### S17. Temporal: Workflow Definition

Deterministic workflow execution and replay constraints.

`https://docs.temporal.io/workflow-definition`

<a id="s18"></a>
### S18. Temporal: Activities

External work, retry behavior, and activity idempotency considerations.

`https://docs.temporal.io/activities`

<a id="s19"></a>
### S19. Temporal Python: Message passing

Queries, Signals, Updates, and their processing semantics.

`https://docs.temporal.io/develop/python/message-passing`  
Observed destination: `https://docs.temporal.io/develop/python/workflows/message-passing`

<a id="s20"></a>
### S20. Temporal Python: Continue-As-New

Bounded workflow history and continued execution with a new run identity.

`https://docs.temporal.io/develop/python/continue-as-new`  
Observed destination: `https://docs.temporal.io/develop/python/workflows/continue-as-new`

<a id="s21"></a>
### S21. Celery: Tasks

Task semantics and the warning about synchronous subtasks exhausting a worker pool.

`https://docs.celeryq.dev/en/stable/userguide/tasks.html`

<a id="s22"></a>
### S22. NATS: JetStream pull consumers

Pull-based consumption and bounded flow-control settings.

`https://docs.nats.io/nats-concepts/jetstream/consumers`  
Observed destination: `https://docs.nats.io/learn/jetstream/pull-consumers`

<a id="s23"></a>
### S23. Ray: Actor fault tolerance

Actor restart and the need to restore application state explicitly.

`https://docs.ray.io/en/latest/ray-core/fault_tolerance/actors.html`

<a id="s24"></a>
### S24. Kubernetes: Resource Management for Pods and Containers

Resource requests and limits for scheduled execution units.

`https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/`

<a id="s25"></a>
### S25. OpenAI: Agent approvals and security

Sandbox versus approval policy, host-dependent enforcement, and operational security boundaries.

`https://learn.chatgpt.com/docs/agent-approvals-security`

<a id="s26"></a>
### S26. Model Context Protocol: Security Best Practices

Audience validation, token passthrough, and confused-deputy risks.

`https://modelcontextprotocol.io/specification/latest/basic/security_best_practices`  
Observed destination: `https://modelcontextprotocol.io/docs/2026-07-28/tutorials/security/security_best_practices`

### Internal context used

**C1. `HOW_TO_MAKE_COURSE.md`.** Current-conversation artifact. Relevant sections establish real early role invocations, G0/G1 before authoring, revision-bound reviews, and truthful validation. This guide operationalizes those requirements through durable tasks and gates.

**C2. `agentic_discovery_qwen3_demo_updated.md`.** Relevant sections retrieved from the user's Library, not a complete reread of the file. They support preserving FastAPI/PostgreSQL, independent CPU/GPU work, durable host state, and ending agent turns while jobs run. Vendor API claims were checked against current official sources rather than trusted from that document.

**C3. Prior project context.** Used to preserve the user's Agent/Chat distinction, project versus user ownership, Agent Inbox as request/response, workflow runners, and preference for durable platform history without a mandatory campaign entity. These are user design constraints, not public facts or vendor requirements.

### Evidence boundaries

The reference-model test results are local observations from this document's preparation. Runtime migration, provider usage limits, memory envelopes, sandbox behavior, and productive 10,000-agent coordination remain deployment-specific and must be verified. The architecture, schema, policies, and implementation phases are proposals, not a report of a deployed system.

[S01]: #s01
[S02]: #s02
[S03]: #s03
[S04]: #s04
[S05]: #s05
[S06]: #s06
[S07]: #s07
[S08]: #s08
[S09]: #s09
[S10]: #s10
[S11]: #s11
[S12]: #s12
[S13]: #s13
[S14]: #s14
[S15]: #s15
[S16]: #s16
[S17]: #s17
[S18]: #s18
[S19]: #s19
[S20]: #s20
[S21]: #s21
[S22]: #s22
[S23]: #s23
[S24]: #s24
[S25]: #s25
[S26]: #s26
