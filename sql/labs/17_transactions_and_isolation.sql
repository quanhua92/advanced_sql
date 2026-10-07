-- Lesson 17: transactions and isolation.
-- READ docs/lessons/17_transactions_and_isolation.md before running.
-- Re-running resets ONLY lab17; do not run while a concurrency exercise uses it.
\ir ../lib/session.sql

SELECT course_meta.reset_lab('lab17',false);
CREATE TABLE lab17.accounts(id integer PRIMARY KEY,balance integer NOT NULL CHECK(balance>=0));
INSERT INTO lab17.accounts VALUES(1,100),(2,100);
BEGIN;
UPDATE lab17.accounts SET balance=balance-25 WHERE id=1;
UPDATE lab17.accounts SET balance=balance+25 WHERE id=2;
SELECT sum(balance) AS total_during_transaction FROM lab17.accounts;
ROLLBACK;
SELECT * FROM lab17.accounts ORDER BY id;
SHOW transaction_isolation;
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT pg_current_snapshot();
SELECT sum(balance) FROM lab17.accounts;
COMMIT;
CREATE TABLE lab17.on_call(id integer PRIMARY KEY,active boolean NOT NULL);
INSERT INTO lab17.on_call VALUES(1,true),(2,true);
-- The multi-session exercises are in sql/concurrency/17_*.
-- A single connection cannot demonstrate a concurrent anomaly.

SELECT 'LAB_17_COMPLETED' AS result;
