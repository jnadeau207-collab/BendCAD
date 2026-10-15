import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'neg-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-neg-c163'

IC = '(intent create any any any any)'
IR = '(intent remove any any any any)'
S1 = '(node 1 (naca4 0 0 12 100 17) (intent create any any any any))'
S2 = '(node 2 (naca4 0 0 12 100 17) (intent create any any any any))'
B3 = '(node 3 (blade 1 2 50 0 100) (intent create any any any any))'
BOX = '(node 1 (box 100 100 10) (intent create any any any any))'
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


def query(msg, design, *args, edits=(BOX,)):
    fresh(design, *edits)
    before = read(design)
    out, _ = cli(design, *args)
    after = read(design)
    return (msg in out and before == after, out.strip()[:200])


@case('digits.m_high')
def c_dm():
    return reject([], '(node 1 (naca4 10 4 12 100 17) (intent create any any any any))', 1,
                  'unsupported-op', 'naca-digits-not-admitted')


@case('digits.p_zero')
def c_dp():
    return reject([], '(node 1 (naca4 2 0 12 100 17) (intent create any any any any))', 1,
                  'unsupported-op', 'naca-digits-not-admitted')


@case('digits.t_low')
def c_dtl():
    return reject([], '(node 1 (naca4 0 0 5 100 17) (intent create any any any any))', 1,
                  'unsupported-op', 'naca-digits-not-admitted')


@case('digits.t_high')
def c_dth():
    return reject([], '(node 1 (naca4 0 0 25 100 17) (intent create any any any any))', 1,
                  'unsupported-op', 'naca-digits-not-admitted')


@case('points.bad')
def c_pts():
    return reject([], '(node 1 (naca4 0 0 12 100 25) (intent create any any any any))', 1,
                  'unsupported-op', 'naca-points-not-admitted')


@case('chord.zero')
def c_ch():
    return reject([], '(node 1 (naca4 0 0 12 0 17) (intent create any any any any))', 1,
                  'invalid-input', 'degenerate-feature')


@case('naca.malformed')
def c_nm():
    return reject([], '(node 1 (naca4 0 0 12) (intent create any any any any))', 1,
                  'invalid-input', 'unknown-op')


@case('sections.one')
def c_s1():
    return reject([S1], '(node 2 (blade 1 50 0 100) (intent create any any any any))', 2,
                  'unsupported-op', 'blade-sections-not-admitted')


@case('sections.nine')
def c_s9():
    secs = ['(node %d (naca4 0 0 12 100 17) (intent create any any any any))' % i for i in range(1, 10)]
    ids = ' '.join(str(i) for i in range(1, 10))
    return reject(secs, '(node 10 (blade %s 50 0 100) (intent create any any any any))' % ids, 10,
                  'unsupported-op', 'blade-sections-not-admitted')


@case('twist.bad')
def c_tw():
    return reject([S1, S2], '(node 3 (blade 1 2 50 45 100) (intent create any any any any))', 3,
                  'unsupported-op', 'twist-not-admitted')


@case('taper.bad')
def c_tp():
    return reject([S1, S2], '(node 3 (blade 1 2 50 0 33) (intent create any any any any))', 3,
                  'unsupported-op', 'taper-not-admitted')


@case('span.zero')
def c_sp():
    return reject([S1, S2], '(node 3 (blade 1 2 0 0 100) (intent create any any any any))', 3,
                  'invalid-input', 'degenerate-feature')


@case('blade.malformed')
def c_bm():
    return reject([], '(node 1 (blade 1) (intent create any any any any))', 1,
                  'invalid-input', 'unknown-op')


@case('stack.nonaca')
def c_sn():
    return reject([BOX, S2.replace('(node 2', '(node 2', 1)],
                  '(node 3 (blade 1 2 50 0 100) (intent create any any any any))', 3,
                  'numerical-uncertainty', 'blade-stack-not-ruled')


@case('stack.npts')
def c_sp2():
    s33 = '(node 2 (naca4 0 0 12 100 33) (intent create any any any any))'
    return reject([S1, s33], '(node 3 (blade 1 2 50 0 100) (intent create any any any any))', 3,
                  'numerical-uncertainty', 'blade-stack-not-ruled')


@case('stack.chord')
def c_sc():
    s50 = '(node 2 (naca4 0 0 12 50 17) (intent create any any any any))'
    return reject([S1, s50], '(node 3 (blade 1 2 50 0 100) (intent create any any any any))', 3,
                  'numerical-uncertainty', 'blade-stack-not-ruled')


@case('stack.missing')
def c_sm():
    return reject([S1], '(node 2 (blade 1 99 50 0 100) (intent create any any any any))', 2,
                  'numerical-uncertainty', 'blade-stack-not-ruled')


@case('query.nonblade')
def c_qb():
    return query('blade-needs-blade', 'q.bcd', 'blade', '1')


@case('query.naca4')
def c_qn():
    return query('blade-needs-blade', 'qn.bcd', 'blade', '1', edits=(S1,))


@case('query.unknown')
def c_qu():
    return query('unknown-node', 'qu.bcd', 'blade', '99', edits=(S1,))


@case('query.failed')
def c_qf():
    fresh('qf.bcd', S1)
    before = read('qf.bcd')
    out, _ = cli('qf.bcd', 'blade', '2')
    return ('unknown-node' in out and before == read('qf.bcd'), out.strip()[:160])


@case('zone.blade')
def c_zb():
    fresh('z.bcd', S1, S2, B3)
    before = read('z.bcd')
    out, _ = cli('z.bcd', 'zone', '3')
    return ('topology-not-certified-over-zone' in out and before == read('z.bcd'), out.strip()[:160])


@case('feature.onblade')
def c_fb():
    return reject([S1, S2, B3],
                  '(node 4 (holes 3 (face 3 0 top) through (hole 5 5 1)) (intent remove any any any any))', 4,
                  'unsupported-op', 'features-need-an-extruded-body')


@case('ring.inherit')
def c_ri():
    hole = '(node 2 (holes 1 (face 1 0 top) through (hole 35 50 2)) (intent remove any any any any))'
    ring = ('(node 3 (pad 2 (face 1 0 top) 5 (region (path 30 30 (line 70 30) (line 70 70) (line 30 70)) '
            '(path 40 40 (line 60 40) (line 60 60) (line 40 60)))) (intent add any any any any))')
    return reject([BOX, hole], ring, 3,
                  'invalid-input', 'footprint-contains-or-meets-existing-feature')


@case('obstacle.inherit')
def c_oi():
    top = ('(node 2 (pocket 1 (face 1 0 top) 6 (region (path 40 40 (line 60 40) (line 60 60) '
           '(line 40 60)))) (intent remove any any any any))')
    bot = ('(node 3 (pocket 1 (face 1 0 bottom) 12 (region (path 40 40 (line 60 40) (line 60 60) '
           '(line 40 60)))) (intent remove any any any any))')
    return reject([BOX, top], bot, 3, 'invalid-input', 'depth-reaches-opposite-face')


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    rows = []
    for name, fn in CASES:
        try:
            ok, info = fn()
        except Exception as e:
            ok, info = False, repr(e)[:200]
        rows.append(dict(name=name, ok=bool(ok), info=info))
        print(('PASS ' if ok else 'FAIL ') + name, flush=True)
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0],
               passed=sum(r['ok'] for r in rows), total=len(rows), results=rows)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} refusals hold")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
