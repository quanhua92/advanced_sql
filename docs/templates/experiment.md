# Experiment record

Copy this template for each experiment. Blank fields are for your observations, not missing course content.

## Question and result contract

State the intended rows, duplicate handling, tenant scope, ordering, time boundaries, and required consistency.

## Environment

Record PostgreSQL version, image digest, seed size, relevant indexes, session settings, and recent mutations/vacuum. State whether cache conditions are controlled.

## Prediction

Name the work you expect to disappear or remain. Separate semantic guarantees from possible plan choices and performance hypotheses.

## Procedure and evidence

Record exact SQL, parameter values, evidence-log path, estimates/actuals/loops, buffers, sorting/hashing, lock observations, and repeated timings. Capture errors with SQLSTATE where relevant.

## Result checks

Explain how you checked both content and multiplicity. For concurrency, record the actual overlapping schedule and commits/rollbacks.

## Explanation and decision

Explain any mismatch. State the alternative you rejected, the tradeoff, and what evidence could change your decision.

## DoneContract

Write the unfamiliar case you can now explain without looking at the answer key.
