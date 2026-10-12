import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'neg-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-neg-c10'

BOX = '(node 1 (box 10 10 10) (intent create any any any any))'
CASES = []


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


def read(design):
    return wsl('cat', f'{WORK}/{design}')[0]


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def case(name):
    def wrap(fn):
        CASES.append((name, fn))
        return fn
    return wrap


def refused(args, why):
    fresh('n.bcd', BOX)
    before = read('n.bcd')
    out, _ = cli('n.bcd', 'tess', '1', f'{WORK}/n.obj', *args)
    after = read('n.bcd')
    ls, _ = wsl('ls', f'{WORK}/n.obj')
    wsl('rm', '-f', f'{WORK}/n.obj')
    m = re.search(r'error invalid-input \| tess \| why: ([^|]+)\| fix: (.*)', out)
    ok = (m is not None and m.group(1).strip() == why and len(m.group(2).strip()) > 0
          and 'no such file' in ls.lower() and before == after)
    return ok, (m.group(1).strip() if m else None, 'nofile' if 'no such file' in ls.lower() else 'WROTE',
                before == after)


@case('tess.preset_range')
def c_pr():
    a, i1 = refused(['4'], 'preset 4 needs 0..3')
    b, i2 = refused(['9'], 'preset 9 needs 0..3')
    return a and b, (i1, i2)


@case('tess.preset_garbage')
def c_pg():
    return refused(['abc'], 'preset abc needs 0..3')


@case('tess.chord_zero')
def c_c0():
    return refused(['1', '0'], 'chord needs a positive finite number')


@case('tess.chord_neg')
def c_cn():
    return refused(['1', '-2'], 'chord needs a positive finite number')


@case('tess.chord_garbage')
def c_cg():
    return refused(['1', 'abc'], 'chord needs a positive finite number')


@case('tess.angle_zero')
def c_a0():
    return refused(['1', '1', '0'], 'angle needs a positive finite number')


@case('tess.angle_neg')
def c_an():
    return refused(['1', '1', '-1'], 'angle needs a positive finite number')


@case('tess.angle_garbage')
def c_ag():
    return refused(['1', '1', 'abc'], 'angle needs a positive finite number')


@case('tess.max_zero')
def c_m0():
    return refused(['1', '1', '0.2', '0'], 'max-tris needs a positive integer')


@case('tess.max_garbage')
def c_mg():
    return refused(['1', '1', '0.2', 'abc'], 'max-tris needs a positive integer')


@case('tess.profile_bad')
def c_pb():
    return refused(['1', '1', '0.2', '100', 'foo'], 'profile needs display or manufacturing')


@case('tess.node_failed')
def c_nf():
    fresh('n.bcd', BOX)
    before = read('n.bcd')
    out, _ = cli('n.bcd', 'tess', '99', f'{WORK}/n.obj')
    after = read('n.bcd')
    ls, _ = wsl('ls', f'{WORK}/n.obj')
    ok = ('error: node failed; nothing tessellated' in out
          and 'no such file' in ls.lower() and before == after)
    return ok, out.strip()[:120]


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    sha = wsl('sha256sum', BIN)[0].split()[0]
    results = []
    for name, fn in CASES:
        t = time.time()
        try:
            ok, info = fn()
        except Exception as e:
            ok, info = False, f'{type(e).__name__}: {e}'
        results.append(dict(name=name, ok=bool(ok), info=str(info)[:300], seconds=round(time.time() - t, 2)))
        print(('PASS ' if ok else 'FAIL ') + name, str(info)[:160])
    rep = dict(binary_sha256=sha, passed=sum(r['ok'] for r in results), total=len(results), results=results)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} passed")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
