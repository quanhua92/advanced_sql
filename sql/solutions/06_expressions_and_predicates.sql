-- Companion answer: run lab 06 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab06') IS NOT NULL,'Run lesson 06 first');

SELECT course_meta.assert_true(
 (SELECT count(*) FROM lab06.runs WHERE created_at::date=DATE '2026-01-02')=
 (SELECT count(*) FROM lab06.runs
  WHERE created_at>=TIMESTAMPTZ '2026-01-02 00:00:00+00'
    AND created_at<TIMESTAMPTZ '2026-01-03 00:00:00+00'),
 'UTC cast and half-open range agree under the declared timezone');
-- Local business-day boundaries, converted into instants for the column comparison.
SELECT count(*) FROM lab06.runs
WHERE created_at >= (TIMESTAMP '2026-01-02 00:00:00' AT TIME ZONE 'Asia/Ho_Chi_Minh')
AND created_at < (TIMESTAMP '2026-01-03 00:00:00' AT TIME ZONE 'Asia/Ho_Chi_Minh');
SELECT course_meta.assert_true(
 (SELECT id FROM lab06.contacts WHERE lower(email)='person4242@example.test')=4242,
 'Expression lookup');
WITH boundary(t) AS (VALUES
 (TIMESTAMPTZ '2026-01-01 23:59:59.999999+00'),
 (TIMESTAMPTZ '2026-01-02 00:00:00+00'),
 (TIMESTAMPTZ '2026-01-02 23:59:59.999999+00'),
 (TIMESTAMPTZ '2026-01-03 00:00:00+00'))
SELECT course_meta.assert_true(
 (SELECT count(*) FROM boundary WHERE t>='2026-01-02 00:00:00+00'::timestamptz
 AND t<'2026-01-03 00:00:00+00'::timestamptz)=2,'Boundary inclusion');

SELECT 'SOLUTION_06_PASSED' AS result;
