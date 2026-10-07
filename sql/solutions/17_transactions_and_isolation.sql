-- Companion answer: run lab 17 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab17') IS NOT NULL,'Run lesson 17 first');

SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab17.accounts WHERE balance=100)=2,
 'Rollback restores both teaching balances');
SELECT course_meta.assert_true((SELECT sum(balance) FROM lab17.accounts)=200,'total invariant');
SELECT course_meta.assert_true((SELECT count(*) FROM lab17.on_call WHERE active)=2,'on-call starting state');
-- A shared guard row can serialize cross-row decisions when all participants lock it.
CREATE TABLE IF NOT EXISTS lab17.invariant_guard(id integer PRIMARY KEY);
INSERT INTO lab17.invariant_guard VALUES(1) ON CONFLICT DO NOTHING;
BEGIN;
SELECT id FROM lab17.invariant_guard WHERE id=1 FOR UPDATE;
SELECT count(*) AS active_workers FROM lab17.on_call WHERE active;
ROLLBACK;
-- This is a pattern demonstration; concurrency correctness requires all writers
-- to follow the same protocol. Run the independent-session exercises next.

SELECT 'SOLUTION_17_PASSED' AS result;
