\ir ../lib/session.sql
-- Each call is a short transaction when psql autocommit is enabled.
SELECT id AS job_id,lease_token AS token,attempt
FROM capstone.claim_one(1,'cpu','worker-demo',120) \gset
SELECT capstone.renew(:job_id,:'token'::uuid,'worker-demo',120) AS renewed;
SELECT capstone.complete(:job_id,:'token'::uuid,'worker-demo','{"summary":"synthetic result"}'::jsonb)
AS completed;
-- Duplicate acknowledgement is rejected, not applied twice.
SELECT NOT capstone.complete(:job_id,:'token'::uuid,'worker-demo','{}'::jsonb) AS duplicate_rejected;
SELECT * FROM capstone.job_events WHERE job_id=:job_id ORDER BY id;
SELECT * FROM capstone.outbox WHERE job_id=:job_id;
