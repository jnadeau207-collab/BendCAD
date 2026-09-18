"""Temporary recovery receiver. Never logs or commits source credentials."""
import base64
import hashlib
import hmac
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request
import zlib

ROOT = Path.cwd()
QUEUE = ROOT / '.recovery-transfer-v2'
QUEUE.mkdir(exist_ok=True)
WORK = Path(tempfile.mkdtemp(prefix='bendcad-transfer-'))
PRIVATE = WORK / 'private.pem'
PUBLIC = QUEUE / 'public.pem'
SOURCE = 'eeca9ad782640f97bc15423e72319acea310d36f'


def cmd(*args, data=None):
    return subprocess.run(args, input=data, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, check=True).stdout


def git(*args):
    return cmd('git', *args).decode().strip()


def publish(message, *paths):
    git('add', '--', *paths)
    if not git('diff', '--cached', '--name-only'):
        return
    git('commit', '-m', message)
    for attempt in range(5):
        try:
            git('push', 'origin', 'HEAD:main')
            return
        except subprocess.CalledProcessError:
            git('fetch', 'origin', 'main')
            git('rebase', 'origin/main')
    raise RuntimeError('Could not fast-forward publish recovery')


def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


def receive(packet):
    wrapped, iv, ciphertext, mac = [base64.b64decode(packet[k], validate=True)
                                   for k in ('key', 'iv', 'data', 'mac')]
    key = cmd('openssl', 'pkeyutl', '-decrypt', '-inkey', str(PRIVATE),
              '-pkeyopt', 'rsa_padding_mode:oaep', '-pkeyopt', 'rsa_oaep_md:sha256', data=wrapped)
    if len(key) != 64 or len(iv) != 16 or not hmac.compare_digest(
            mac, hmac.new(key[32:], wrapped + iv + ciphertext, hashlib.sha256).digest()):
        raise RuntimeError('Encrypted packet authentication failed')
    packed = cmd('openssl', 'enc', '-d', '-aes-256-ctr', '-K', key[:32].hex(),
                 '-iv', iv.hex(), data=ciphertext)
    rows = json.loads(zlib.decompress(packed))
    if not isinstance(rows, list) or len(rows) > 300:
        raise RuntimeError('Invalid batch size')
    successes, failures = [], []
    for row in rows:
        path = PurePosixPath(row['path'])
        if path.is_absolute() or '..' in path.parts or not path.parts or '.git' in path.parts:
            raise RuntimeError('Unsafe source path')
        if not re.fullmatch('[0-9a-f]{40}', row['sha']):
            raise RuntimeError('Invalid blob hash')
        url = row['url']
        parsed = urllib.parse.urlsplit(url)
        expected = '/jnadeau207-collab/reepo/' + SOURCE + '/' + str(path)
        if parsed.scheme != 'https' or parsed.netloc != 'raw.githubusercontent.com' or urllib.parse.unquote(parsed.path) != expected:
            raise RuntimeError('Unapproved source URL')
        for token in urllib.parse.parse_qs(parsed.query).get('token', []):
            print('::add-mask::' + token, flush=True)
        destination = ROOT / 'legacy' / 'aethalgard' / path
        if destination.is_file() and not destination.is_symlink() and blob(destination.read_bytes()) == row['sha']:
            successes.append(str(path))
            continue
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                data = response.read(20 * 1024 * 1024 + 1)
        except Exception:
            failures.append(str(path))
            continue
        if len(data) > 20 * 1024 * 1024 or blob(data) != row['sha']:
            failures.append(str(path) + ' (hash mismatch)')
            continue
        if destination.is_symlink():
            raise RuntimeError('Refusing symlink overwrite')
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        os.chmod(destination, 0o755 if row.get('mode') == '100755' else 0o644)
        successes.append(str(path))
    return successes, failures


git('config', 'user.name', 'BendCAD Recovery')
git('config', 'user.email', 'actions@users.noreply.github.com')
cmd('openssl', 'genpkey', '-algorithm', 'RSA', '-pkeyopt', 'rsa_keygen_bits:3072', '-out', str(PRIVATE))
os.chmod(PRIVATE, 0o600)
PUBLIC.write_bytes(cmd('openssl', 'pkey', '-in', str(PRIVATE), '-pubout'))
publish('chore: publish recovery session public key', '.recovery-transfer-v2/public.pem')
seen = set()
deadline = time.monotonic() + 1320
try:
    while time.monotonic() < deadline:
        git('fetch', 'origin', 'main')
        git('merge', '--ff-only', 'FETCH_HEAD')
        for batch in sorted(QUEUE.glob('batch-*.json')):
            digest = hashlib.sha256(batch.read_bytes()).hexdigest()
            if digest in seen:
                continue
            successes, failures = receive(json.loads(batch.read_text()))
            receipt = QUEUE / (batch.stem + '.receipt.json')
            receipt.write_text(json.dumps({'source': SOURCE, 'verified': successes,
                                           'failed': failures}, indent=2) + '\n')
            publish('archive: recover verified legacy batch ' + batch.stem,
                    'legacy/aethalgard', str(receipt.relative_to(ROOT)))
            seen.add(digest)
            print(batch.name, len(successes), 'verified,', len(failures), 'failed', flush=True)
        if (QUEUE / 'FINISH').exists():
            print('Transfer session explicitly closed.', flush=True)
            break
        time.sleep(4)
    else:
        raise RuntimeError('Transfer deadline reached')
finally:
    PRIVATE.unlink(missing_ok=True)
