#!/usr/bin/env python3
"""Offline structural checks only. This is NOT a SQL parser or runtime test."""
from __future__ import annotations
import argparse
import ast
import hashlib
import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def validate() -> dict:
    errors: list[str] = []
    checks: dict[str, int | bool | str] = {}
    def require(ok: bool, message: str) -> None:
        if not ok:
            errors.append(message)
    manifest = json.loads((ROOT / 'course_manifest.json').read_text(encoding='utf-8'))
    require([e['number'] for e in manifest['lessons']] == list(range(1, 22)), 'Expected core lessons 1 through 21')
    require([e['number'] for e in manifest['extras']] == list(range(22, 27)), 'Expected supplements 22 through 26')
    checked_paths = 0
    for group in ('lessons', 'extras'):
        for item in manifest[group]:
            for key in ('doc', 'lab', 'solution_sql', 'solution_doc'):
                if key in item:
                    path = ROOT / item[key]
                    require(path.is_file(), f'Missing manifest file: {item[key]}')
                    checked_paths += 1
    checks['manifest_paths'] = checked_paths
    links = 0
    for path in ROOT.rglob('*.md'):
        if '__pycache__' in path.parts:
            continue
        text = path.read_text(encoding='utf-8')
        for destination in re.findall(r'\[[^\]\n]*\]\(([^\s)]+)(?:\s+"[^"]*")?\)', text):
            parts = urlsplit(destination)
            if parts.scheme or parts.netloc or not parts.path:
                continue
            target = (path.parent / unquote(parts.path)).resolve()
            require(target.is_relative_to(ROOT), f'Link escapes package: {path.relative_to(ROOT)} -> {destination}')
            require(target.exists(), f'Broken link: {path.relative_to(ROOT)} -> {destination}')
            links += 1
    checks['local_markdown_links'] = links
    inventory = re.findall(r'^- `([^`]+)`$', (ROOT / 'CONTENTS.md').read_text(encoding='utf-8'), re.MULTILINE)
    for relative in inventory:
        require((ROOT / relative).is_file(), f'Missing file from CONTENTS.md inventory: {relative}')
    checks['contents_inventory_files'] = len(inventory)
    includes = 0
    for path in ROOT.rglob('*.sql'):
        text = path.read_text(encoding='utf-8')
        require('\r' not in text, f'CR characters in {path.relative_to(ROOT)}')
        for kind, destination in re.findall(r'^\s*\\(ir|i)\s+([^\s]+)', text, re.MULTILINE):
            if destination.startswith('/course/'):
                target = ROOT / destination[len('/course/'):]
            elif kind == 'ir':
                target = path.parent / destination
            else:
                errors.append(f'Unresolved cwd-dependent include: {path} -> {destination}')
                continue
            require(target.is_file(), f'Missing SQL include: {path.relative_to(ROOT)} -> {destination}')
            includes += 1
    checks['sql_include_paths'] = includes
    py_count = 0
    for path in ROOT.rglob('*.py'):
        ast.parse(path.read_text(encoding='utf-8'), filename=str(path))
        py_count += 1
    checks['python_files_parsed'] = py_count
    for item in manifest['lessons']:
        n = item['number']
        require(f'LAB_{n:02d}_COMPLETED' in (ROOT / item['lab']).read_text(), f'Lab {n}: missing completion marker')
        require(f'SOLUTION_{n:02d}_PASSED' in (ROOT / item['solution_sql']).read_text(), f'Solution {n}: missing assertion completion marker')
        require('DoneContract' in (ROOT / item['solution_doc']).read_text(), f'Lesson {n}: missing DoneContract')
    checks['core_labs_with_solutions'] = 21
    with zipfile.ZipFile(ROOT / 'legacy/original_learning_pack.zip') as original:
        for entry in original.namelist():
            if entry.endswith('/'):
                continue
            require((ROOT / 'legacy' / Path(entry).name).read_bytes() == original.read(entry),
                    f'Legacy file differs from original archive: {entry}')
    checks['original_files_match_embedded_archive'] = True
    compose = (ROOT / 'docker-compose.yml').read_text()
    for token in ('postgres:18-bookworm', 'postgres18_data:/var/lib/postgresql', 'build:',
                  'healthcheck:', 'course_meta.installation', 'shared_preload_libraries=pg_stat_statements'):
        require(token in compose, f'Compose missing expected safety/baseline field: {token}')
    require('ports:' not in compose, 'Compose should not publish a host database port; use docker compose exec')
    session = (ROOT / 'sql/lib/session.sql').read_text()
    require("server_version_num')::integer/10000<>18" in session,
            'SQL session guard must require PostgreSQL 18')
    checks['postgres_major_version_guard'] = True
    dockerfile = ROOT / 'Dockerfile'
    require(dockerfile.is_file(), 'Missing Dockerfile used to bundle course files into the PostgreSQL image')
    if dockerfile.is_file():
        for token in ('COPY docker/init/', 'COPY sql/', 'COPY scripts/', 'COPY legacy/'):
            require(token in dockerfile.read_text(), f'Dockerfile missing required course files: {token}')
    checks['compose_expected_fields_present'] = True
    checks['compose_yaml_parser'] = 'Not checked by this standard-library validator'
    checks['sql_syntax_and_runtime'] = 'Not checked; requires PostgreSQL 18'
    files = [p for p in ROOT.rglob('*') if p.is_file() and '.git' not in p.parts
             and '__pycache__' not in p.parts
             and not p.relative_to(ROOT).as_posix().startswith(('outputs/', 'backups/'))]
    checks['files_excluding_output_and_backup_contents'] = len(files)
    checks['markdown_files'] = len(list(ROOT.rglob('*.md')))
    checks['sql_files'] = len(list(ROOT.rglob('*.sql')))
    return {'status': 'PASS' if not errors else 'FAIL', 'checks': checks, 'errors': errors,
            'runtime_executed': False, 'scope': 'Offline structural validation only'}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--json', type=Path, help='Write this run report to a file')
    parser.add_argument('--checksums', action='store_true', help='Verify files against the packaged SHA256SUMS baseline')
    args = parser.parse_args()
    try:
        result = validate()
        if args.checksums:
            count = 0
            for line in (ROOT / 'SHA256SUMS').read_text().splitlines():
                digest, relative = line.split('  ', 1)
                path = (ROOT / relative).resolve()
                if not path.is_relative_to(ROOT) or not path.is_file():
                    result['errors'].append(f'Checksum file missing/invalid: {relative}')
                elif hashlib.sha256(path.read_bytes()).hexdigest() != digest:
                    result['errors'].append(f'Checksum differs: {relative}')
                count += 1
            result['checks']['baseline_checksums_verified'] = count
            result['status'] = 'PASS' if not result['errors'] else 'FAIL'
        rendered = json.dumps(result, indent=2)
        print(rendered)
        if args.json:
            args.json.parent.mkdir(parents=True, exist_ok=True)
            args.json.write_text(rendered + '\n', encoding='utf-8')
        return 0 if result['status'] == 'PASS' else 1
    except (OSError, ValueError, SyntaxError, zipfile.BadZipFile) as error:
        print(f'Validation failed: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
