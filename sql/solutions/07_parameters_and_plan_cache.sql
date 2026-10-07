-- Companion answer: run lab 07 first.
\ir ../lib/session.sql
SELECT course_meta.assert_true(to_regnamespace('lab07') IS NOT NULL,'Run lesson 07 first');

SELECT course_meta.assert_true((SELECT count(*) FROM lab07.items WHERE category='rare')=100,'rare skew');
SELECT course_meta.assert_true((SELECT count(*) FROM lab07.items WHERE category='common')=99900,'common skew');
PREPARE answer_total(text) AS SELECT sum(length(payload)) FROM lab07.items WHERE category=$1;
EXECUTE answer_total('rare');
EXECUTE answer_total('common');
DEALLOCATE answer_total;
-- A value containing a quote remains a value, not SQL structure.
PREPARE echo_value(text) AS SELECT $1 AS value, length($1) AS characters;
EXECUTE echo_value('O''Reilly');
DEALLOCATE echo_value;

SELECT 'SOLUTION_07_PASSED' AS result;
