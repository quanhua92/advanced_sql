\ir ../lib/session.sql
CREATE OR REPLACE FUNCTION capstone.claim_one(
 p_project integer,p_pool text,p_worker text,p_lease_seconds integer DEFAULT 60)
RETURNS SETOF capstone.jobs LANGUAGE plpgsql AS $body$
DECLARE claimed capstone.jobs%ROWTYPE;
BEGIN
 IF p_project IS NULL OR p_pool NOT IN('cpu','gpu') OR p_pool IS NULL
 OR p_worker IS NULL OR length(trim(p_worker))=0
 OR p_lease_seconds IS NULL OR p_lease_seconds NOT BETWEEN 1 AND 3600 THEN
   RAISE EXCEPTION 'Invalid claim arguments';
 END IF;
 WITH candidate AS(
  SELECT id FROM capstone.jobs
  WHERE project_id=p_project AND pool=p_pool AND status='queued'
    AND available_at<=clock_timestamp() AND attempt<max_attempts
  ORDER BY priority DESC,created_at,id
  FOR UPDATE SKIP LOCKED LIMIT 1
 )
 UPDATE capstone.jobs j
 SET status='running',attempt=j.attempt+1,lease_token=gen_random_uuid(),
 claimed_by=p_worker,lease_expires_at=clock_timestamp()+make_interval(secs=>p_lease_seconds)
 FROM candidate c WHERE j.id=c.id RETURNING j.* INTO claimed;
 IF FOUND THEN
  INSERT INTO capstone.job_events(job_id,kind,attempt,lease_token,details)
  VALUES(claimed.id,'claimed',claimed.attempt,claimed.lease_token,jsonb_build_object('worker',p_worker));
  RETURN NEXT claimed;
 END IF;
 RETURN;
END;
$body$;

CREATE OR REPLACE FUNCTION capstone.renew(
 p_job bigint,p_token uuid,p_worker text,p_lease_seconds integer DEFAULT 60)
RETURNS boolean LANGUAGE plpgsql AS $body$
DECLARE renewed capstone.jobs%ROWTYPE;
BEGIN
 IF p_lease_seconds IS NULL OR p_lease_seconds NOT BETWEEN 1 AND 3600 THEN
   RAISE EXCEPTION 'Lease length must be between 1 and 3600 seconds';
 END IF;
 -- Acquire the row lock BEFORE checking wall-clock expiry. A prior waiter must
 -- not authorize itself using an expiry predicate evaluated before it blocked.
 SELECT * INTO renewed FROM capstone.jobs WHERE id=p_job FOR UPDATE;
 IF NOT FOUND OR renewed.status<>'running'
    OR renewed.lease_token IS DISTINCT FROM p_token
    OR renewed.claimed_by IS DISTINCT FROM p_worker
    OR renewed.lease_expires_at IS NULL
    OR renewed.lease_expires_at<=clock_timestamp() THEN RETURN false; END IF;
 UPDATE capstone.jobs SET lease_expires_at=clock_timestamp()+make_interval(secs=>p_lease_seconds)
 WHERE id=p_job RETURNING * INTO renewed;
 INSERT INTO capstone.job_events(job_id,kind,attempt,lease_token,details)
 VALUES(p_job,'renewed',renewed.attempt,p_token,jsonb_build_object('worker',p_worker));
 RETURN true;
END;
$body$;

CREATE OR REPLACE FUNCTION capstone.complete(
 p_job bigint,p_token uuid,p_worker text,p_result jsonb)
RETURNS boolean LANGUAGE plpgsql AS $body$
DECLARE completed capstone.jobs%ROWTYPE;
BEGIN
 -- Ownership and expiry are checked under the acquired row lock.
 SELECT * INTO completed FROM capstone.jobs WHERE id=p_job FOR UPDATE;
 IF NOT FOUND OR completed.status<>'running'
    OR completed.lease_token IS DISTINCT FROM p_token
    OR completed.claimed_by IS DISTINCT FROM p_worker
    OR completed.lease_expires_at IS NULL
    OR completed.lease_expires_at<=clock_timestamp() THEN RETURN false; END IF;
 UPDATE capstone.jobs SET status='succeeded',result=p_result,
 lease_token=NULL,claimed_by=NULL,lease_expires_at=NULL
 WHERE id=p_job RETURNING * INTO completed;
 INSERT INTO capstone.job_events(job_id,kind,attempt,lease_token,details)
 VALUES(p_job,'completed',completed.attempt,p_token,jsonb_build_object('worker',p_worker));
 INSERT INTO capstone.outbox(job_id,kind,payload)
 VALUES(p_job,'run.completed',jsonb_build_object('job_id',p_job,'result',p_result));
 RETURN true;
END;
$body$;

CREATE OR REPLACE FUNCTION capstone.requeue_expired(p_limit integer DEFAULT 100)
RETURNS integer LANGUAGE plpgsql AS $body$
DECLARE expired capstone.jobs%ROWTYPE; processed integer:=0; next_status text;
BEGIN
 IF p_limit IS NULL OR p_limit NOT BETWEEN 1 AND 1000 THEN
  RAISE EXCEPTION 'Reaper limit must be between 1 and 1000';
 END IF;
 FOR expired IN
  SELECT * FROM capstone.jobs WHERE status='running' AND lease_expires_at<=clock_timestamp()
  ORDER BY lease_expires_at,id FOR UPDATE SKIP LOCKED LIMIT p_limit
 LOOP
  next_status:=CASE WHEN expired.attempt>=expired.max_attempts THEN 'failed' ELSE 'queued' END;
  UPDATE capstone.jobs SET status=next_status,lease_token=NULL,claimed_by=NULL,lease_expires_at=NULL,
   available_at=clock_timestamp()+make_interval(secs=>least(60,expired.attempt*2))
  WHERE id=expired.id;
  INSERT INTO capstone.job_events(job_id,kind,attempt,lease_token,details)
  VALUES(expired.id,CASE WHEN next_status='failed' THEN 'attempts_exhausted' ELSE 'lease_expired' END,
   expired.attempt,expired.lease_token,jsonb_build_object('previous_worker',expired.claimed_by));
  processed:=processed+1;
 END LOOP;
 RETURN processed;
END;
$body$;
-- Functions run with caller privileges. This demo does not implement application
-- authentication or tenant RLS. Worker/project arguments are not authorization.
