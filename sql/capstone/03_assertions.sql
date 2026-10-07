\ir ../lib/session.sql
-- Deterministic failure injection: alter the TEST job's expiry instead of relying
-- on arbitrary sleeps. Does not simulate external effects or actual worker loss.
DO $body$
DECLARE first_job capstone.jobs%ROWTYPE; second_job capstone.jobs%ROWTYPE;
 replacement capstone.jobs%ROWTYPE; exhausted capstone.jobs%ROWTYPE; ok boolean;
BEGIN
 DELETE FROM capstone.jobs WHERE project_id=99 AND idempotency_key LIKE 'smoke:%';
 INSERT INTO capstone.jobs(project_id,idempotency_key,pool,prompt,priority,max_attempts)
 VALUES(99,'smoke:a','cpu','test A',100,2),(99,'smoke:b','cpu','test B',100,2);
 SELECT * INTO first_job FROM capstone.claim_one(99,'cpu','worker-A',300);
 SELECT * INTO second_job FROM capstone.claim_one(99,'cpu','worker-B',300);
 PERFORM course_meta.assert_true(first_job.id IS NOT NULL AND second_job.id IS NOT NULL
  AND first_job.id<>second_job.id,'Distinct sequential claims');
 PERFORM course_meta.assert_true(NOT capstone.complete(first_job.id,gen_random_uuid(),'worker-A','{}'),
  'Wrong token rejected');
 PERFORM course_meta.assert_true(NOT capstone.complete(first_job.id,first_job.lease_token,'wrong-worker','{}'),
  'Wrong owner rejected');
 PERFORM course_meta.assert_true(capstone.renew(first_job.id,first_job.lease_token,'worker-A',300),
  'Current owner renews');
 PERFORM course_meta.assert_true(capstone.complete(second_job.id,second_job.lease_token,'worker-B','{}'),
  'Current owner completes');
 PERFORM course_meta.assert_true(NOT capstone.complete(second_job.id,second_job.lease_token,'worker-B','{}'),
  'Duplicate acknowledgement rejected');
 UPDATE capstone.jobs SET lease_expires_at=clock_timestamp()-INTERVAL '1 second' WHERE id=first_job.id;
 PERFORM course_meta.assert_true(NOT capstone.complete(first_job.id,first_job.lease_token,'worker-A','{}'),
  'Expired owner cannot complete');
 PERFORM course_meta.assert_true(NOT capstone.renew(first_job.id,first_job.lease_token,'worker-A',300),
  'Expired owner cannot renew');
 PERFORM capstone.requeue_expired(100);
 UPDATE capstone.jobs SET available_at=clock_timestamp()-INTERVAL '1 second' WHERE id=first_job.id;
 SELECT * INTO replacement FROM capstone.claim_one(99,'cpu','worker-C',300);
 PERFORM course_meta.assert_true(replacement.id=first_job.id AND replacement.attempt=2
 AND replacement.lease_token<>first_job.lease_token,'Reclaimed attempt has a new identity');
 PERFORM course_meta.assert_true(NOT capstone.complete(first_job.id,first_job.lease_token,'worker-A','{}'),
  'Stale attempt cannot acknowledge its replacement');
 PERFORM course_meta.assert_true(capstone.complete(replacement.id,replacement.lease_token,'worker-C','{}'),
  'Replacement can complete');
 INSERT INTO capstone.jobs(project_id,idempotency_key,pool,prompt,max_attempts)
 VALUES(99,'smoke:exhaust','cpu','test exhausted',1);
 SELECT * INTO exhausted FROM capstone.claim_one(99,'cpu','worker-D',300);
 UPDATE capstone.jobs SET lease_expires_at=clock_timestamp()-INTERVAL '1 second' WHERE id=exhausted.id;
 PERFORM capstone.requeue_expired(100);
 PERFORM course_meta.assert_true((SELECT status FROM capstone.jobs WHERE id=exhausted.id)='failed',
  'Attempt budget stops retries');
 PERFORM course_meta.assert_true((SELECT count(*) FROM capstone.outbox WHERE job_id IN(first_job.id,second_job.id))=2,
  'One transactional outbox record per completed test job');
 PERFORM course_meta.assert_true(
  (SELECT count(*) FROM capstone.job_events WHERE job_id=first_job.id AND kind='claimed')=2
  AND (SELECT count(*) FROM capstone.job_events WHERE job_id=first_job.id AND kind='renewed')=1
  AND (SELECT count(*) FROM capstone.job_events WHERE job_id=first_job.id AND kind='lease_expired')=1
  AND (SELECT count(*) FROM capstone.job_events WHERE job_id=first_job.id AND kind='completed')=1,
  'History preserves both attempts, renewal, expiry, and one completion');
 PERFORM course_meta.assert_true(
  (SELECT count(*) FROM capstone.job_events WHERE job_id=exhausted.id AND kind='attempts_exhausted')=1,
  'Exhausted attempt is recorded in durable history');
END;
$body$;
SELECT 'CAPSTONE_ASSERTIONS_PASSED' AS result;
