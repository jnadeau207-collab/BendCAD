"""Verify the immutable recovered source against its pinned Git identities.

Requires Python 3 and Git, but no network, third-party packages, or CAD runtime.
This is source-integrity verification, not native-build or geometry qualification.
"""
from pathlib import Path
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def git(*args: str) -> bytes:
    return subprocess.run(
        ['git', *args], cwd=ROOT, check=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    ).stdout


def main() -> None:
    manifest = json.loads((ROOT / 'legacy/manifest.json').read_text(encoding='utf-8'))
    prefix = manifest['destination']
    expected = {prefix: manifest['recovered_archive_tree']}
    for group in ('trees', 'blobs'):
        expected.update({prefix + '/' + p: sha for p, sha in manifest[group].items()})
    failures = []
    for path, sha in expected.items():
        actual = git('rev-parse', 'HEAD:' + path).decode().strip()
        if actual != sha:
            failures.append(path + ': expected ' + sha + ', found ' + actual)
    git('diff', '--quiet', 'HEAD', '--', prefix)
    if git('ls-files', '--others', '--exclude-standard', '--', prefix):
        failures.append('Untracked files exist inside the immutable archive')
    paths = [prefix + '/' + p for group in ('trees', 'blobs') for p in manifest[group]]
    entries = git('ls-tree', '-r', '-l', '-z', 'HEAD', '--', *paths).split(b'\0')
    count = size = 0
    for entry in entries:
        if not entry:
            continue
        meta, _ = entry.split(b'\t', 1)
        _, kind, _, length = meta.split()
        if kind != b'blob':
            failures.append('Unexpected non-blob entry in core selection')
            continue
        count += 1
        size += int(length)
    if count != manifest['core_file_count'] or size != manifest['core_byte_count']:
        failures.append('Core count mismatch: ' + str(count) + ' files, ' + str(size) + ' bytes')
    receipt = {
        'status': 'FAIL' if failures else 'PASS',
        'scope': 'source identity only',
        'source_commit': manifest['source_commit'],
        'verified_commit': git('rev-parse', 'HEAD').decode().strip(),
        'identity_checks': len(expected),
        'core_files': count,
        'core_bytes': size,
        'failures': failures,
    }
    print(json.dumps(receipt, indent=2))
    if failures:
        raise SystemExit(1)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print('Legacy verification failed: ' + str(error), file=sys.stderr)
        raise SystemExit(1) from error
