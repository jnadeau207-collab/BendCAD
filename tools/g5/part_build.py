import os
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
import jet

BIN = os.environ.get('BENDCAD_DIRECT', '/home/jesse/bc/bendcad-k5l')


def wsl(*args):
    return subprocess.run(['wsl.exe', '-e', BIN] + list(args), capture_output=True, text=True)


def report(name, out, dt):
    bad = [l for l in out.splitlines() if ': error' in l or l.startswith('error')]
    print(name, 'committed' in out, round(dt, 1), bad[:2] if bad else '', flush=True)
    return 'committed' in out


def run(name):
    edits = dict(jet.parts())[name]
    path = f'{jet.WORK}/p_{name}.bcd'
    wsl(path, 'new')
    t0 = time.time()
    p = wsl(path, 'apply', *edits)
    return report(name, p.stdout + p.stderr, time.time() - t0)


def have(path):
    p = subprocess.run(['wsl.exe', '-e', 'cat', path], capture_output=True, text=True)
    return set(int(n) for n in re.findall(r'\(node (\d+)', p.stdout))


def inc(name, path=None):
    edits = dict(jet.parts())[name]
    path = path or f'{jet.WORK}/p_{name}.bcd'
    done = have(path)
    if not done:
        wsl(path, 'new')
    for e in edits:
        nid = int(re.match(r'\(node (\d+)', e).group(1))
        if nid in done:
            continue
        t0 = time.time()
        p = wsl(path, 'apply', e)
        if not report(f'{name}:{nid}', p.stdout + p.stderr, time.time() - t0):
            return False
    return True


if __name__ == '__main__':
    args = sys.argv[1:]
    if args and args[0] == '--inc':
        path = None
        if len(args) > 2 and args[1] == '--file':
            path, args = args[2], args[3:]
        else:
            args = args[1:]
        for n in args:
            inc(n, path)
    else:
        for n in args:
            run(n)
