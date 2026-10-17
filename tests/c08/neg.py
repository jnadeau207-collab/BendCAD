import json
import math
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'neg-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-neg'

BOX10 = '(box 10 10 10)'
I11 = '(intent same 0 0 1 0)'
ICR = '(intent create 6 0 1 0)'


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def node_err(out, n):
    m = re.search(rf'node {n}: error (\S+)( .*?)?why: ([^|]+)', out)
    return (m.group(1), m.group(3).strip()) if m else (None, None)


def node_vol(out, n):
    m = re.search(rf'node {n}: ok .*?volume=\[([^,]+), ([^\]]+)\]', out)
    return (float(m.group(1)), float(m.group(2))) if m else None


def vol_ok(out, n, x):
    v = node_vol(out, n)
    return v is not None and v[0] <= x <= v[1]


CASES = []


def case(name):
    def wrap(fn):
        CASES.append((name, fn))
        return fn
    return wrap


@case('cross.boxes')
def c_cross():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   f'(node 2 {BOX10} {ICR})',
                   f'(node 3 (move 2 5 0 0 0) {I11})',
                   '(node 4 (union 1 3) (intent add 0 0 1 0))')
    return ('committed' in out and vol_ok(out, 4, 1500.0)
            and 'proof: k1-crossing-certified' in out, node_vol(out, 4))


@case('cross.straddle')
def c_straddle():
    out, _ = fresh('n.bcd',
                   '(node 1 (box 20 20 20) (intent create 6 0 1 0))',
                   '(node 2 (box 4 4 4) (intent create 6 0 1 0))',
                   '(node 3 (move 2 18 8 8 0) (intent same 0 0 1 0))',
                   '(node 4 (difference 1 3) (intent remove 0 0 1 0))')
    return ('committed' in out and vol_ok(out, 4, 7968.0)
            and 'proof: k1-crossing-certified' in out, node_vol(out, 4))


@case('cross.pierce_rod')
def c_pierce():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   '(node 2 (box 2 2 20) (intent create 6 0 1 0))',
                   '(node 3 (move 2 4 4 -5 0) (intent same 0 0 1 0))',
                   '(node 4 (union 1 3) (intent add 0 0 1 0))')
    return ('committed' in out and vol_ok(out, 4, 1040.0)
            and 'proof: k1-crossing-certified' in out, node_vol(out, 4))


@case('cross.sphere')
def c_sphere():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   '(node 2 (sphere 6) (intent create 2 0 1 0))',
                   '(node 3 (union 1 2) (intent add 0 0 1 0))')
    k, w = node_err(out, 3)
    return (k == 'unsupported-op' and 'curved-surface-operand' in w, (k, w))


@case('ok.mixed_cavity')
def c_mixed():
    tri = '(prism 0 10 (region (path 1 1 (line 5 1) (line 5 5) (line 1 5))) (region (path 100 100 (line 105 100) (line 105 105) (line 100 105))))'
    out, _ = fresh('n.bcd',
                   '(node 1 (box 40 40 40) (intent create 6 0 1 0))',
                   '(node 2 (move 1 0 0 -20 0) (intent same 0 0 1 0))',
                   f'(node 3 {tri} (intent create 12 0 2 0))',
                   '(node 4 (difference 2 3) (intent remove 0 0 1 0))')
    return ('committed' in out and vol_ok(out, 4, 63840.0)
            and 'proof: k1-crossing-certified' in out, node_vol(out, 4))


@case('place.rot45_union')
def c_rot45u():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   f'(node 2 {BOX10} {ICR})',
                   '(node 3 (rotate 2 z 45) (intent same 0 0 1 0))',
                   '(node 4 (move 3 40 0 0 0) (intent same 0 0 1 0))',
                   '(node 5 (union 1 4) (intent add 0 0 2 0))')
    k, w = node_err(out, 5)
    return (k == 'unsupported-op' and w.startswith('interval-placement'), w)


@case('place.rot45_diff')
def c_rot45d():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   f'(node 2 {BOX10} {ICR})',
                   '(node 3 (rotate 2 z 45) (intent same 0 0 1 0))',
                   '(node 4 (move 3 40 0 0 0) (intent same 0 0 1 0))',
                   '(node 5 (difference 1 4) (intent same 0 0 1 0))')
    k, w = node_err(out, 5)
    return (k == 'unsupported-op' and w.startswith('interval-placement'), w)


@case('feature.on_boolean')
def c_featb():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   f'(node 2 {BOX10} {ICR})',
                   f'(node 3 (move 2 5 0 0 0) {I11})',
                   '(node 4 (union 1 3) (intent add 0 0 1 0))',
                   '(node 5 (pad 4 (face 4 0 top) 3 (region (circle 2 5 1))) (intent add 3 3 1 0))')
    return ('committed' in out and vol_ok(out, 5, 1500.0 + 3.0 * math.pi)
            and 'proof: k1-crossing-certified' in out, node_vol(out, 5))


@case('feature.on_compound')
def c_featc():
    fresh('n.bcd',
          f'(node 1 {BOX10} {ICR})',
          f'(node 2 {BOX10} {ICR})',
          '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
          '(node 4 (union 1 3) (intent add 0 0 2 0))')
    o, _ = cli('n.bcd', 'apply', '(node 5 (pad 4 (face 4 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 2 0))')
    return ('feature-on-compound' in o, o.strip()[:160])


@case('feature.on_empty')
def c_feate():
    fresh('n.bcd',
          f'(node 1 {BOX10} {ICR})',
          f'(node 2 {BOX10} {ICR})',
          '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
          '(node 4 (intersection 1 3) (intent same 0 0 0 0))')
    o, _ = cli('n.bcd', 'apply', '(node 5 (pad 4 (face 4 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 1 0))')
    return ('feature-on-empty-compound' in o, o.strip()[:100])


@case('intent.mismatch')
def c_intent():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   f'(node 2 {BOX10} {ICR})',
                   '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
                   '(node 4 (union 1 3) (intent create 6 0 1 0))')
    return ('declared material=create' in out and 'but measured material=add' in out, out.strip()[:160])


@case('zone.boolean')
def c_zone():
    fresh('n.bcd',
          f'(node 1 {BOX10} {ICR})',
          f'(node 2 {BOX10} {ICR})',
          '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
          '(node 4 (union 1 3) (intent add 0 0 2 0))')
    o, _ = cli('n.bcd', 'zone', '4')
    return ('topology-not-certified-over-zone' in o and 'refuse before any zone split' in o
            and 'keep profile segments' not in o, o.strip()[:180])


@case('diff.pinched')
def c_pinch():
    out, _ = fresh('n.bcd',
                   '(node 1 (box 20 20 20) (intent create 6 0 1 0))',
                   '(node 2 (box 4 4 4) (intent create 6 0 1 0))',
                   '(node 3 (move 2 0 8 8 0) (intent same 0 0 1 0))',
                   '(node 6 (difference 1 3) (intent remove 0 0 1 0))')
    k, w = node_err(out, 6)
    return (k == 'numerical-uncertainty' and w.startswith('validation-rejected'), (k, w))


@case('ok.ident_union')
def c_ident():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   f'(node 2 {BOX10} {ICR})',
                   '(node 3 (union 1 2) (intent add 0 0 1 0))')
    return ('committed' in out and vol_ok(out, 3, 1000.0)
            and 'proof: k1-crossing-certified' in out, node_vol(out, 3))


@case('diff.no_container')
def c_nocont():
    out, _ = fresh('n.bcd',
                   '(node 1 (box 20 20 20) (intent create 6 0 1 0))',
                   '(node 2 (box 20 20 10) (intent create 6 0 1 0))',
                   '(node 3 (difference 1 2) (intent remove 0 0 1 0))')
    k, w = node_err(out, 3)
    return (k == 'numerical-uncertainty' and w.startswith('no-container-sample'), (k, w))


@case('chain.failed_operand')
def c_chain():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   '(node 2 (sphere 6) (intent create 2 0 1 0))',
                   '(node 3 (union 1 2) (intent add 0 0 1 0))',
                   '(node 4 (union 3 1) (intent add 0 0 1 0))')
    k, w = node_err(out, 4)
    return (k is not None and 'committed' not in out, (k, w))


@case('ok.touch_face')
def c_oktouch():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   f'(node 2 {BOX10} {ICR})',
                   '(node 3 (move 2 10 0 0 0) (intent same 0 0 1 0))',
                   '(node 4 (union 1 3) (intent add 0 0 2 0))')
    m = re.search(r'node 4: ok material=add faces_created=0 faces_modified=0 solids=2 through_holes=0', out)
    return ('committed' in out and m is not None, out.strip()[:120])


@case('ok.identical')
def c_okident():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   '(node 2 (union 1 1) (intent same 0 0 1 0))')
    return ('committed' in out, out.strip()[:120])


@case('ok.contained')
def c_okcont():
    out, _ = fresh('n.bcd',
                   '(node 1 (box 20 20 20) (intent create 6 0 1 0))',
                   '(node 2 (box 4 4 4) (intent create 6 0 1 0))',
                   '(node 3 (move 2 8 8 8 0) (intent same 0 0 1 0))',
                   '(node 4 (union 3 1) (intent same 0 0 1 0))')
    return ('committed' in out, out.strip()[:120])


@case('ok.disjoint_proof')
def c_okdis():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   f'(node 2 {BOX10} {ICR})',
                   '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
                   '(node 4 (union 1 3) (intent add 0 0 2 0))')
    return ('committed' in out and 'proof: disjoint-boxes A[' in out, out.strip()[:200])


@case('ok.quarter_turn')
def c_okrot():
    out, _ = fresh('n.bcd',
                   f'(node 1 {BOX10} {ICR})',
                   f'(node 2 {BOX10} {ICR})',
                   '(node 3 (rotate 2 z 90) (intent same 0 0 1 0))',
                   '(node 4 (move 3 40 0 0 0) (intent same 0 0 1 0))',
                   '(node 5 (union 1 4) (intent add 0 0 2 0))')
    return ('committed' in out, out.strip()[:160])


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
