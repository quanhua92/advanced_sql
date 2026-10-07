-- Companion answer: run lab 08 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab08') IS NOT NULL,'Run lesson 08 first');

SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab08.messages WHERE message LIKE '%timeout%')=500,
 'Substring match count');
SELECT course_meta.assert_true(
 NOT EXISTS((SELECT id FROM lab08.messages WHERE message LIKE '%timeout%'
 EXCEPT SELECT id FROM lab08.messages WHERE position('timeout' in message)>0)
 UNION ALL (SELECT id FROM lab08.messages WHERE position('timeout' in message)>0
 EXCEPT SELECT id FROM lab08.messages WHERE message LIKE '%timeout%')),
 'Trigram-supported predicate preserves substring semantics');
WITH original AS (SELECT id FROM lab08.runs WHERE project_id=42 OR status='failed'),
rewritten AS (SELECT id FROM lab08.runs WHERE project_id=42
 UNION SELECT id FROM lab08.runs WHERE status='failed')
SELECT course_meta.assert_true(
 NOT EXISTS((SELECT * FROM original EXCEPT SELECT * FROM rewritten)
 UNION ALL(SELECT * FROM rewritten EXCEPT SELECT * FROM original)),
 'UNION, not naive UNION ALL, preserves OR set semantics here');

SELECT 'SOLUTION_08_PASSED' AS result;
