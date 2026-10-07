\ir ../lib/session.sql
DROP SCHEMA IF EXISTS course_concurrency CASCADE;
CREATE SCHEMA course_concurrency;
CREATE TABLE course_concurrency.counter(id integer PRIMARY KEY,value integer NOT NULL);
INSERT INTO course_concurrency.counter VALUES(1,100);
CREATE TABLE course_concurrency.on_call(id integer PRIMARY KEY,active boolean NOT NULL);
INSERT INTO course_concurrency.on_call VALUES(1,true),(2,true);
CREATE TABLE course_concurrency.resources(id integer PRIMARY KEY,value integer NOT NULL);
INSERT INTO course_concurrency.resources VALUES(1,0),(2,0);
CREATE TABLE course_concurrency.jobs(id integer PRIMARY KEY,status text NOT NULL);
INSERT INTO course_concurrency.jobs SELECT i,'queued' FROM generate_series(1,4) g(i);
CREATE TABLE course_concurrency.document(id integer PRIMARY KEY,body text NOT NULL) WITH(fillfactor=70);
INSERT INTO course_concurrency.document VALUES(1,'version one');
