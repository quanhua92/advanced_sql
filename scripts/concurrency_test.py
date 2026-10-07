#!/usr/bin/env python3
"""Real multi-connection schedules through Docker's psql; Python standard library."""
from __future__ import annotations
from datetime import datetime, timezone
from pathlib import Path
import queue
import subprocess
import sys
import threading
import time
import uuid

from course import ROOT, COMPOSE, PSQL, need_docker


class Session:
    def __init__(self, name: str):
        self.name = name
        self.output: queue.Queue[str | None] = queue.Queue()
        self.pending: str | None = None
        self.process = subprocess.Popen(COMPOSE + [
            'exec', '-T', 'postgres', 'psql', '-X', '-qAt', '-U', 'course', '-d', 'advanced_sql',
            '-v', 'ON_ERROR_STOP=off', '-v', 'VERBOSITY=verbose'],
            cwd=ROOT, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, text=True, encoding='utf-8', errors='replace', bufsize=1)
        threading.Thread(target=self._read, daemon=True).start()
        self.query("SET statement_timeout='20s'; SET lock_timeout='15s'; "
                   "SET idle_in_transaction_session_timeout='60s'; SET deadlock_timeout='100ms'; "
                   f"SET application_name='course_concurrency_{name}'; SET client_min_messages=warning;")
        self.pid = int(self.query('SELECT pg_backend_pid();')[-1])

    def _read(self) -> None:
        assert self.process.stdout is not None
        for line in self.process.stdout:
            self.output.put(line.rstrip('\r\n'))
        self.output.put(None)

    def send(self, sql: str) -> None:
        if self.pending is not None:
            raise RuntimeError(f'{self.name}: a query is already pending')
        marker = '__COURSE_DONE_' + uuid.uuid4().hex
        self.pending = marker
        assert self.process.stdin is not None
        self.process.stdin.write(sql + '\n\\echo ' + marker + '\n')
        self.process.stdin.flush()

    def receive(self, allowed_errors: tuple[str, ...] = ()) -> list[str]:
        if self.pending is None:
            raise RuntimeError('No pending query')
        deadline = time.monotonic() + 30
        lines: list[str] = []
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError(f'{self.name}: no completion marker; output={lines}')
            line = self.output.get(timeout=remaining)
            if line is None:
                raise RuntimeError(f'{self.name}: psql exited; output={lines}')
            if line == self.pending:
                break
            if line:
                lines.append(line)
        self.pending = None
        errors = [line for line in lines if 'ERROR:' in line or 'FATAL:' in line]
        for error in errors:
            if not any(code in error for code in allowed_errors):
                raise RuntimeError(f'{self.name}: unexpected database error: {lines}')
        return lines

    def query(self, sql: str, allowed_errors: tuple[str, ...] = ()) -> list[str]:
        self.send(sql)
        return self.receive(allowed_errors)

    def close(self) -> None:
        # Closing the client rolls back any unfinished transaction on disconnect.
        try:
            if self.process.poll() is None and self.process.stdin is not None:
                self.process.stdin.write('ROLLBACK;\n\\q\n')
                self.process.stdin.flush()
                self.process.wait(timeout=3)
        except (OSError, subprocess.TimeoutExpired):
            self.process.kill()
            self.process.wait(timeout=3)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    sessions: list[Session] = []
    directory = ROOT / 'outputs'
    directory.mkdir(exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    logfile = directory / f'{stamp}_concurrency.log'
    with logfile.open('w', encoding='utf-8') as log:
        def report(text: str) -> None:
            print(text, flush=True)
            log.write(text + '\n')
            log.flush()
        try:
            need_docker()
            subprocess.run(COMPOSE + PSQL + ['-f', '/course/sql/concurrency/setup.sql'], cwd=ROOT, check=True)
            for name in ('A', 'B', 'observer'):
                sessions.append(Session(name))
            a, b, observer = sessions
            report('Connected backend PIDs: ' + ', '.join(str(s.pid) for s in sessions))

            a.query('BEGIN ISOLATION LEVEL READ COMMITTED;')
            require(a.query('SELECT value FROM course_concurrency.counter WHERE id=1;') == ['100'], 'Initial RC value')
            b.query('UPDATE course_concurrency.counter SET value=value+1 WHERE id=1;')
            require(a.query('SELECT value FROM course_concurrency.counter WHERE id=1;') == ['101'], 'RC sees new committed value')
            a.query('COMMIT;')
            report('PASS: Read Committed uses a new statement snapshot.')

            a.query('BEGIN ISOLATION LEVEL REPEATABLE READ;')
            require(a.query('SELECT value FROM course_concurrency.counter WHERE id=1;') == ['101'], 'Initial RR value')
            b.query('UPDATE course_concurrency.counter SET value=value+1 WHERE id=1;')
            require(a.query('SELECT value FROM course_concurrency.counter WHERE id=1;') == ['101'], 'RR retains snapshot')
            a.query('COMMIT;')
            require(a.query('SELECT value FROM course_concurrency.counter WHERE id=1;') == ['102'], 'New transaction sees commit')
            report('PASS: Repeatable Read preserves its earlier snapshot.')

            for session in (a, b):
                session.query('BEGIN ISOLATION LEVEL REPEATABLE READ;')
                require(session.query('SELECT count(*) FROM course_concurrency.on_call WHERE active;') == ['2'], 'Both doctors initially active')
            a.query('UPDATE course_concurrency.on_call SET active=false WHERE id=1; COMMIT;')
            b.query('UPDATE course_concurrency.on_call SET active=false WHERE id=2; COMMIT;')
            require(observer.query('SELECT count(*) FROM course_concurrency.on_call WHERE active;') == ['0'], 'RR write skew reproduced')
            report('PASS: Repeatable Read permits this disjoint-row write skew.')

            observer.query('UPDATE course_concurrency.on_call SET active=true;')
            for session in (a, b):
                session.query('BEGIN ISOLATION LEVEL SERIALIZABLE;')
                require(session.query('SELECT count(*) FROM course_concurrency.on_call WHERE active;') == ['2'], 'Serializable predicate read')
            a.query('UPDATE course_concurrency.on_call SET active=false WHERE id=1; COMMIT;')
            output = b.query('UPDATE course_concurrency.on_call SET active=false WHERE id=2;', ('40001',))
            output += b.query('COMMIT;', ('40001',))
            require(any('40001' in line for line in output), 'Expected serialization failure, not a silent skew')
            b.query('ROLLBACK;')
            require(observer.query('SELECT count(*) FROM course_concurrency.on_call WHERE active;') == ['1'], 'Invariant survived the conflicting schedule')
            report('PASS: Serializable rejects the conflicting transaction with SQLSTATE 40001.')

            a.query('BEGIN; SELECT id FROM course_concurrency.jobs WHERE id=1 FOR UPDATE;')
            got = b.query("WITH c AS (SELECT id FROM course_concurrency.jobs WHERE status='queued' "
                "ORDER BY id FOR UPDATE SKIP LOCKED LIMIT 1) UPDATE course_concurrency.jobs j "
                "SET status='running' FROM c WHERE j.id=c.id RETURNING j.id;")
            require(got == ['2'], f'Expected job 2 while A holds job 1, got {got}')
            a.query('ROLLBACK;')
            report('PASS: SKIP LOCKED claims a different unlocked job without waiting for job 1.')

            a.query('BEGIN; UPDATE course_concurrency.resources SET value=value+1 WHERE id=1;')
            b.query('BEGIN; UPDATE course_concurrency.resources SET value=value+1 WHERE id=2;')
            a.send('UPDATE course_concurrency.resources SET value=value+1 WHERE id=2;')
            deadline = time.monotonic() + 8
            while True:
                blocked = observer.query(f'SELECT {b.pid}=ANY(pg_blocking_pids({a.pid}));')
                if blocked == ['t']:
                    break
                require(time.monotonic() < deadline, 'Could not observe A waiting for B')
                time.sleep(0.05)
            b.send('UPDATE course_concurrency.resources SET value=value+1 WHERE id=1;')
            out_a = a.receive(('40P01',))
            out_b = b.receive(('40P01',))
            errors = [line for line in out_a + out_b if 'ERROR:' in line]
            require(len(errors) == 1 and '40P01' in errors[0], f'Expected one deadlock victim, got {errors}')
            a.query('ROLLBACK;')
            b.query('ROLLBACK;')
            report('PASS: An observed lock cycle produces one deadlock victim, SQLSTATE 40P01.')

            a.query('BEGIN ISOLATION LEVEL REPEATABLE READ;')
            require(a.query('SELECT body FROM course_concurrency.document WHERE id=1;') == ['version one'], 'Old document version')
            b.query("UPDATE course_concurrency.document SET body='version two' WHERE id=1;")
            b.query('VACUUM course_concurrency.document;')
            require(a.query('SELECT body FROM course_concurrency.document WHERE id=1;') == ['version one'], 'Old snapshot survives concurrent vacuum')
            a.query('COMMIT;')
            require(a.query('SELECT body FROM course_concurrency.document WHERE id=1;') == ['version two'], 'New snapshot sees new version')
            report('PASS: An active snapshot retains the old visible version across vacuum.')

            available = observer.query("SELECT to_regprocedure('capstone.claim_one(integer,text,text,integer)') IS NOT NULL;")
            if available == ['t']:
                observer.query("DELETE FROM capstone.jobs WHERE project_id=98 AND idempotency_key LIKE 'concurrency:%'; "
                    "INSERT INTO capstone.jobs(project_id,idempotency_key,pool,prompt) VALUES "
                    "(98,'concurrency:a','cpu','test A'),(98,'concurrency:b','cpu','test B');")
                a.query('BEGIN;')
                first = a.query("SELECT id FROM capstone.claim_one(98,'cpu','concurrent-A',60);")
                b.query('BEGIN;')
                second = b.query("SELECT id FROM capstone.claim_one(98,'cpu','concurrent-B',60);")
                require(len(first) == 1 and len(second) == 1 and first != second, 'Concurrent capstone claims must be distinct')
                a.query('COMMIT;')
                b.query('COMMIT;')
                require(observer.query("SELECT count(*) FROM capstone.jobs WHERE project_id=98 "
                    "AND idempotency_key LIKE 'concurrency:%' AND status='running';") == ['2'], 'Both claims persisted')
                observer.query("DELETE FROM capstone.jobs WHERE project_id=98 AND idempotency_key LIKE 'concurrency:%';")
                report('PASS: Capstone claims remain distinct while the first claim transaction is uncommitted.')
            else:
                report('SKIP: Capstone schema absent. Run the capstone first to include its two-connection test.')
            report('CONCURRENCY_PASSED')
            return 0
        except (Exception, KeyboardInterrupt) as error:
            report(f'FAILED: {type(error).__name__}: {error}')
            return 1
        finally:
            for session in sessions:
                session.close()
            print(f'Evidence log: {logfile}')


if __name__ == '__main__':
    raise SystemExit(main())
