#!/usr/bin/env python3
"""Operate only this disposable course project. Python 3.10+, standard library."""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
COMPOSE = ['docker', 'compose', '--project-directory', str(ROOT), '-f', str(ROOT / 'docker-compose.yml')]
PSQL = ['exec', '-T', 'postgres', 'psql', '-X', '-U', 'course', '-d', 'advanced_sql', '-v', 'ON_ERROR_STOP=1']


def need_docker() -> None:
    if shutil.which('docker') is None:
        raise RuntimeError('Docker was not found. Install/start Docker with Compose v2, then retry.')


def execute(args: list[str], *, log_name: str | None = None) -> None:
    need_docker()
    command = COMPOSE + args
    if log_name is None:
        subprocess.run(command, cwd=ROOT, check=True)
        return
    directory = ROOT / 'outputs'
    directory.mkdir(exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    path = directory / f'{stamp}_{log_name}.log'
    print(f'Evidence log: {path}', flush=True)
    with path.open('w', encoding='utf-8') as target:
        with subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, text=True,
                              encoding='utf-8', errors='replace') as process:
            assert process.stdout is not None
            for line in process.stdout:
                print(line, end='')
                target.write(line)
            code = process.wait()
            if code:
                raise subprocess.CalledProcessError(code, command)


def select_entry(number: int, collection: str = 'lessons') -> dict:
    manifest = json.loads((ROOT / 'course_manifest.json').read_text(encoding='utf-8'))
    for item in manifest[collection]:
        if item['number'] == number:
            return item
    valid = ', '.join(str(item['number']) for item in manifest[collection])
    raise ValueError(f'Choose a number from: {valid}')


def run_sql(relative: str, label: str) -> None:
    path = (ROOT / relative).resolve()
    if not path.is_relative_to(ROOT) or path.suffix != '.sql' or not path.is_file():
        raise ValueError('Expected an existing .sql file inside this course folder.')
    relative = path.relative_to(ROOT).as_posix()
    if not relative.startswith(('sql/', 'legacy/')):
        raise ValueError('SQL must be in the bundled sql/ or legacy/ folders.')
    sync_course_files()
    execute(PSQL + ['-f', '/course/' + relative], log_name=label)


def sync_course_files() -> None:
    """Copy editable host sources into the container without requiring bind mounts."""
    for name in ('sql', 'scripts', 'legacy'):
        execute(['exec', '-T', 'postgres', 'rm', '-rf', f'/course/{name}'])
        execute(['cp', str(ROOT / name), 'postgres:/course/'])


def confirm(yes: bool, operation: str) -> None:
    if not yes:
        raise ValueError(f'{operation} changes or deletes course data. Read the operating guide, then add --yes.')


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    for cmd in ('up', 'down', 'status', 'psql', 'test', 'concurrency-test', 'capstone', 'legacy', 'backup'):
        sub.add_parser(cmd)
    for cmd in ('lab', 'solution', 'bonus', 'clean'):
        item = sub.add_parser(cmd)
        item.add_argument('number', type=int)
    reset = sub.add_parser('reset')
    reset.add_argument('--yes', action='store_true')
    reseed = sub.add_parser('reseed')
    reseed.add_argument('--rows', type=int, default=500000)
    reseed.add_argument('--yes', action='store_true')
    restore = sub.add_parser('restore')
    restore.add_argument('file', type=Path)
    restore.add_argument('--yes', action='store_true')
    return parser


def main(argv: list[str] | None = None) -> int:
    args = make_parser().parse_args(argv)
    try:
        cmd = args.command
        if cmd == 'up':
            execute(['up', '-d', '--build', '--wait', '--wait-timeout', '600'])
            sync_course_files()
        elif cmd == 'down':
            execute(['down'])
        elif cmd == 'status':
            execute(['ps'])
            execute(PSQL + ['-c', 'SELECT version(); TABLE course_meta.installation;'])
        elif cmd == 'psql':
            execute(['exec', 'postgres', 'psql', '-X', '-U', 'course', '-d', 'advanced_sql'])
        elif cmd in ('lab', 'solution', 'bonus'):
            entry = select_entry(args.number, 'extras' if cmd == 'bonus' else 'lessons')
            key = 'solution_sql' if cmd == 'solution' else 'lab'
            run_sql(entry[key], f'{cmd}_{args.number:02d}')
        elif cmd == 'clean':
            if not 1 <= args.number <= 26:
                raise ValueError('Only lab schemas 01 through 26 may be cleaned.')
            execute(PSQL + ['-c', f"SELECT course_meta.reset_lab('lab{args.number:02d}', false);"])
        elif cmd == 'test':
            sync_course_files()
            execute(['exec', '-T', 'postgres', 'sh', '/course/scripts/smoke.sh'], log_name='smoke')
        elif cmd == 'concurrency-test':
            sync_course_files()
            subprocess.run([sys.executable, str(ROOT / 'scripts/concurrency_test.py')], cwd=ROOT, check=True)
        elif cmd == 'capstone':
            print('Rebuilding only the capstone teaching schema.')
            run_sql('sql/capstone/run_all.sql', 'capstone')
        elif cmd == 'legacy':
            run_sql('legacy/01_index_lab.sql', 'legacy')
        elif cmd == 'reset':
            confirm(args.yes, 'Reset')
            execute(['down', '-v'])
            execute(['up', '-d', '--build', '--wait', '--wait-timeout', '600'])
            sync_course_files()
        elif cmd == 'reseed':
            confirm(args.yes, 'Reseed')
            if not 10000 <= args.rows <= 5000000:
                raise ValueError('--rows must be between 10000 and 5000000.')
            sync_course_files()
            # Remove only known teaching schemas, including dependent capstone FKs.
            schemas = [f'lab{i:02d}' for i in range(1, 27)]
            schemas += ['capstone', 'course_concurrency']
            cleanup = ';'.join(f'DROP SCHEMA IF EXISTS {name} CASCADE' for name in schemas) + ';'
            execute(PSQL + ['-c', cleanup])
            execute(PSQL + ['-v', f'n_runs={args.rows}', '-f', '/course/sql/setup/02_seed.sql',
                            '-f', '/course/sql/setup/03_ready.sql'], log_name='reseed')
        elif cmd == 'backup':
            need_docker()
            directory = ROOT / 'backups'
            directory.mkdir(exist_ok=True)
            stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
            path = directory / f'advanced_sql_{stamp}.dump'
            try:
                with path.open('xb') as target:
                    subprocess.run(COMPOSE + ['exec', '-T', 'postgres', 'pg_dump', '-U', 'course',
                                              '-d', 'advanced_sql', '-Fc'], cwd=ROOT, stdout=target, check=True)
            except BaseException:
                path.unlink(missing_ok=True)
                raise
            print(f'Binary-safe logical backup saved: {path}')
        elif cmd == 'restore':
            confirm(args.yes, 'Restore rehearsal')
            path = args.file.expanduser().resolve()
            if not path.is_file():
                raise ValueError(f'Backup not found: {path}')
            # Intentionally refuses if this separate restore database already exists.
            execute(['exec', '-T', 'postgres', 'createdb', '-U', 'course', 'advanced_sql_restore'])
            with path.open('rb') as source:
                subprocess.run(COMPOSE + ['exec', '-T', 'postgres', 'pg_restore', '-U', 'course',
                    '-d', 'advanced_sql_restore', '--no-owner', '--no-privileges', '--exit-on-error'],
                    cwd=ROOT, stdin=source, check=True)
            execute(['exec', '-T', 'postgres', 'psql', '-X', '-U', 'course', '-d', 'advanced_sql_restore',
                     '-v', 'ON_ERROR_STOP=1', '-c',
                     'SELECT count(*) AS restored_runs FROM course.runs; TABLE course_meta.installation;'])
            print('Restored into advanced_sql_restore. The original database was not overwritten.')
        return 0
    except (ValueError, RuntimeError, OSError, subprocess.CalledProcessError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print('\nInterrupted. Inspect session state and roll back open transactions.', file=sys.stderr)
        return 130


if __name__ == '__main__':
    raise SystemExit(main())
