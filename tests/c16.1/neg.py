import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'neg-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-neg-c161'

IC = '(intent create any any any any)'
IA = '(intent add any any any any)'
FLAT = '(node 1 (flat 100 50 2) (intent create any any any any))'
B90 = '(node 2 (bend 1 (edge 0) 3 90) (intent add any any any any))'
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


def node_err(out, n):
    m = re.search(rf'node {n}: error (\S+)( .*?)?why: ([^|]+)', out)
    return (m.group(1), m.group(3).strip()) if m else (None, None)


def reject(prefix, bad, n, kind, why, design='n.bcd'):
    fresh(design, *prefix)
    before = read(design)
    out, _ = cli(design, 'apply', bad)
    after = read(design)
    k, w = node_err(out, n)
    return (k == kind and w == why and before == after, (k, w, before == after))


def query(msg, design, *args, edits=(FLAT,)):
    fresh(design, *edits)
    before = read(design)
    out, _ = cli(design, *args)
    after = read(design)
    return (msg in out and before == after, out.strip()[:160])


@case('bend.angle')
def c_angle():
    return reject([FLAT], '(node 2 (bend 1 (edge 0) 3 45) (intent add any any any any))', 2,
                  'unsupported-op', 'bend-angle-not-certified')


@case('bend.edge')
def c_edge():
    return reject([FLAT], '(node 2 (bend 1 (edge 9) 3 90) (intent add any any any any))', 2,
                  'unsupported-op', 'bend-edge-not-admitted')


@case('bend.boxbase')
def c_boxbase():
    return reject(['(node 1 (box 10 10 10) (intent create any any any any))'],
                  '(node 2 (bend 1 (edge 0) 3 90) (intent add any any any any))', 2,
                  'invalid-input', 'bend-base-not-admitted')


@case('hem.toolong')
def c_toolong():
    return reject([FLAT], '(node 2 (hem 1 (edge 0) 200) (intent add any any any any))', 2,
                  'invalid-input', 'hem-consumes-face')


@case('hem.tip_boundary')
def c_tipb():
    return reject([FLAT, B90], '(node 3 (hem 2 (edge 0) 45) (intent add any any any any))', 3,
                  'invalid-input', 'hem-consumes-face')


@case('bend.toosmall')
def c_small():
    return reject(['(node 1 (flat 8 50 2) (intent create any any any any))'],
                  '(node 2 (bend 1 (edge 0) 3 90) (intent add any any any any))', 2,
                  'invalid-input', 'bend-consumes-face')


@case('bend.tight')
def c_tight():
    return reject([FLAT], '(node 2 (bend 1 (edge 0) 0.5 90) (intent add any any any any))', 2,
                  'unsupported-op', 'bend-radius-too-tight')


@case('bend.malformed')
def c_malformed():
    return reject([FLAT], '(node 2 (bend 1 2) (intent add any any any any))', 2,
                  'invalid-input', 'unknown-op')


@case('bend.third')
def c_third():
    u = [FLAT, B90, '(node 3 (bend 2 (edge 2) 3 90) (intent add any any any any))']
    return reject(u, '(node 4 (bend 3 (edge 0) 3 90) (intent add any any any any))', 4,
                  'unsupported-op', 'bend-edge-not-admitted')


@case('bend.zshape')
def c_z():
    return reject([FLAT, B90], '(node 3 (bend 2 (edge 3) 3 90) (intent add any any any any))', 3,
                  'unsupported-op', 'bend-edge-not-admitted')


@case('bend.sameend')
def c_same():
    return reject([FLAT, B90], '(node 3 (bend 2 (edge 1) 3 90) (intent add any any any any))', 3,
                  'unsupported-op', 'bend-edge-not-admitted')


@case('bend.afterhem')
def c_afterhem():
    return reject([FLAT, '(node 2 (hem 1 (edge 0) 10) (intent add any any any any))'],
                  '(node 3 (bend 2 (edge 0) 3 90) (intent add any any any any))', 3,
                  'invalid-input', 'bend-base-not-admitted')


@case('hem.afterhem')
def c_afterhem2():
    return reject([FLAT, '(node 2 (hem 1 (edge 0) 10) (intent add any any any any))'],
                  '(node 3 (hem 2 (edge 2) 10) (intent add any any any any))', 3,
                  'unsupported-op', 'bend-edge-not-admitted')


@case('hem.on180')
def c_180hem():
    b = [FLAT, '(node 2 (bend 1 (edge 0) 3 180) (intent add any any any any))']
    return reject(b, '(node 3 (hem 2 (edge 0) 10) (intent add any any any any))', 3,
                  'unsupported-op', 'bend-edge-not-admitted')


@case('bend.asymmetric_u')
def c_asym():
    return reject([FLAT, B90], '(node 3 (bend 2 (edge 2) 4 90) (intent add any any any any))', 3,
                  'unsupported-op', 'bend-edge-not-admitted')


@case('bend.degenerate')
def c_degen():
    return reject([FLAT], '(node 2 (bend 1 (edge 0) 0 90) (intent add any any any any))', 2,
                  'invalid-input', 'degenerate-feature')


@case('flat.boxnode')
def c_flatbox():
    return query('flat-needs-sheet', 'f.bcd', 'flat', '1', '0.3', '0.5',
                 edits=('(node 1 (box 10 10 10) (intent create any any any any))',))


@case('flat.badk_inverted')
def c_khi():
    return query('bad-k-zone', 'f.bcd', 'flat', '1', '0.6', '0.4')


@case('flat.badk_zero')
def c_k0():
    return query('bad-k-zone', 'f.bcd', 'flat', '1', '0', '0.5')


@case('flat.badk_one')
def c_k1():
    return query('bad-k-zone', 'f.bcd', 'flat', '2', '0.3', '1', edits=(FLAT, B90))


@case('flat.badk_missing')
def c_karg():
    return query('bad-k-zone', 'f.bcd', 'flat', '1')


@case('flat.unknown_node')
def c_unk():
    return query('unknown-node 99', 'f.bcd', 'flat', '99', '0.3', '0.5')


@case('flat.failed_node')
def c_failed():
    wsl('mkdir', '-p', WORK)
    with open(f'{WORK}/f.bcd', 'w') as f:
        f.write('(bendcad 1)\n(node 1 (flat 100 50 2) (intent create any any any any))\n'
                '(node 2 (bend 1 (edge 0) 3 45) (intent add any any any any))\n')
    before = read('f.bcd')
    out, _ = cli('f.bcd', 'flat', '2', '0.3', '0.5')
    return ('nothing flattened' in out and before == read('f.bcd'), out.strip()[:160])


@case('zone.sheet')
def c_zone():
    fresh('z.bcd', FLAT, B90)
    before = read('z.bcd')
    out, _ = cli('z.bcd', 'zone', '2')
    return ('topology-not-certified-over-zone' in out and before == read('z.bcd'), out.strip()[:160])


@case('feature.onbend')
def c_feat():
    return reject([FLAT, B90],
                  '(node 3 (holes 2 (face 2 0 top) through (hole 5 5 1)) (intent remove any any any any))', 3,
                  'unsupported-op', 'features-need-an-extruded-body')


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    rows = []
    for name, fn in CASES:
        t = time.time()
        try:
            ok, detail = fn()
        except Exception as e:
            ok, detail = False, f'{type(e).__name__}: {e}'[:200]
        rows.append(dict(name=name, ok=bool(ok), seconds=round(time.time() - t, 2), detail=detail))
        print(('PASS ' if ok else 'FAIL ') + name, flush=True)
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in rows),
               total=len(rows), results=rows)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} neg journeys hold")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
