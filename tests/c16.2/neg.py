import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'neg-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-neg-c162'

IC = '(intent create any any any any)'
IA = '(intent add any any any any)'
BOX = '(node 9 (box 10 10 10) (intent create any any any any))'
CASES = []


def pt(x, y, z):
    return f'(pt {x:g} {y:g} {z:g})'


XS = [0.0, 4.0, 6.0, 10.0]
YS = [0.0, 2.0, 3.0, 5.0]
RECT = [(x, y, 0.0) for y in YS for x in XS]
COWL = [(x, y, (x * (10.0 - x) * y * (5.0 - y)) / 500.0 if 0.0 < x < 10.0 and 0.0 < y < 5.0 else 0.0)
        for y in YS for x in XS]
PATCH = lambda pts, i=1: f"(node {i} (patch {' '.join(pt(*p) for p in pts)}) {IC})"
LOFT = lambda z, b, t, i=1, extra='': (f"(node {i} (loft-open {z:g} "
                                       f"(region (path {b[0]:g} {b[1]:g} (line {b[2]:g} {b[1]:g}) (line {b[2]:g} {b[3]:g}) (line {b[0]:g} {b[3]:g}))) "
                                       f"(region (path {t[0]:g} {t[1]:g} (line {t[2]:g} {t[1]:g}) (line {t[2]:g} {t[3]:g}) (line {t[0]:g} {t[3]:g}))){extra}) {IC})")
SWEEP = lambda deg, r, i=1, extra='': (f"(node {i} (sweep-open (arc {deg}) "
                                       f"(region (path {r[0]:g} {r[2]:g} (line {r[1]:g} {r[2]:g}) (line {r[1]:g} {r[3]:g}) (line {r[0]:g} {r[3]:g}))){extra}) {IC})")
THICK = lambda b, t, i: f'(node {i} (thicken-open {b} {t:g}) {IA})'
RECTN = PATCH(RECT)
COWLN = PATCH(COWL)
LOFTN = LOFT(8.0, (0, 0, 10, 5), (0, 0, 10, 5))
SWEEPN = SWEEP(90, (2.0, 6.0, 0.0, 4.0))


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


def query(msg, design, *args, edits=(RECTN,)):
    fresh(design, *edits)
    before = read(design)
    out, _ = cli(design, *args)
    after = read(design)
    return (msg in out and before == after, out.strip()[:160])


@case('loft.nonplanar')
def c_nonplanar():
    return reject([], LOFT(8.0, (0, 0, 10, 5), (0, 0, 10, 5), extra=' (twist 1)'), 1,
                  'unsupported-op', 'loft-open-not-planar')


@case('loft.continuity')
def c_cont():
    return reject([], LOFT(8.0, (0, 0, 10, 5), (0, 0, 10, 5), extra=' (continuity g1)'), 1,
                  'unsupported-op', 'continuity-not-met')


@case('loft.hole')
def c_hole():
    bad = ('(node 1 (loft-open 8 (region (path 0 0 (line 10 0) (line 10 5) (line 0 5)) '
           '(path 2 2 (line 4 2) (line 4 4) (line 2 4))) '
           '(region (path 0 0 (line 10 0) (line 10 5) (line 0 5)))) (intent create any any any any))')
    return reject([], bad, 1, 'invalid-input', 'loft-topology-mismatch')


@case('loft.zeroheight')
def c_z0():
    return reject([], LOFT(0.0, (0, 0, 10, 5), (0, 0, 10, 5)), 1,
                  'invalid-input', 'degenerate-feature')


@case('loft.badpair')
def c_badpair():
    tri = '(region (path 0 0 (line 10 0) (line 5 8)))'
    bad = (f'(node 1 (loft-open 8 (region (path 0 0 (line 10 0) (line 10 5) (line 0 5))) {tri}) '
           f'{IC})')
    return reject([], bad, 1, 'invalid-input', 'loft-topology-mismatch')


@case('loft.nonquad')
def c_nonquad():
    p = '(path 0 0 (line 10 0) (line 12 3) (line 5 6) (line -2 3))'
    bad = f'(node 1 (loft-open 8 (region {p}) (region {p})) {IC})'
    return reject([], bad, 1, 'numerical-uncertainty', 'loft-not-certified')


@case('sweep.angle45')
def c_a45():
    return reject([], SWEEP(45, (2.0, 6.0, 0.0, 4.0)), 1,
                  'unsupported-op', 'sweep-angle-not-certified')


@case('sweep.angle360')
def c_a360():
    return reject([], SWEEP(360, (2.0, 6.0, 0.0, 4.0)), 1,
                  'unsupported-op', 'sweep-angle-not-certified')


@case('sweep.slant')
def c_slant():
    bad = ('(node 1 (sweep-open (arc 90) (region (path 2 0 (line 6 0) (line 5 4) (line 2 4)))) '
           f'{IC})')
    return reject([], bad, 1, 'unsupported-op', 'sweep-profile-not-admitted')


@case('sweep.twist')
def c_stw():
    return reject([], SWEEP(90, (2.0, 6.0, 0.0, 4.0), extra=' (twist 1)'), 1,
                  'unsupported-op', 'twist-not-admitted')


@case('patch.rows')
def c_rows():
    pts = list(RECT)
    pts[4:8] = pts[0:4]
    return reject([], PATCH(pts), 1, 'invalid-input', 'patch-degenerate')


@case('patch.corners')
def c_corners():
    pts = list(RECT)
    pts[15] = pts[0]
    return reject([], PATCH(pts), 1, 'invalid-input', 'patch-degenerate')


@case('patch.short')
def c_short():
    return reject([], '(node 1 (patch (pt 0 0 0)) (intent create any any any any))', 1,
                  'invalid-input', 'unknown-op')


@case('thicken.curve')
def c_curve():
    return reject([COWLN], THICK(1, 1.0, 2), 2,
                  'unsupported-op', 'thicken-curvature-not-certified')


@case('thicken.boxbase')
def c_boxbase():
    return reject([BOX], THICK(9, 1.0, 2), 2, 'invalid-input', 'thicken-needs-open-shell')


@case('thicken.closedbase')
def c_closedbase():
    return reject([RECTN, THICK(1, 2.0, 2)], THICK(2, 1.0, 3), 3,
                  'invalid-input', 'thicken-needs-open-shell')


@case('thicken.consumes')
def c_consumes():
    return reject([LOFTN], THICK(1, 6.0, 2), 2, 'invalid-input', 'thicken-consumes-shell')


@case('thicken.zeroT')
def c_zerot():
    return reject([RECTN], THICK(1, 0.0, 2), 2, 'invalid-input', 'degenerate-feature')


@case('surf.closed')
def c_sclosed():
    return query('surf-needs-open-shell', 'f.bcd', 'surf', '9', edits=(BOX,))


@case('surf.thickened')
def c_sthick():
    fresh('f.bcd', RECTN, THICK(1, 2.0, 2))
    before = read('f.bcd')
    out, _ = cli('f.bcd', 'surf', '2')
    return ('surf-needs-open-shell' in out and before == read('f.bcd'), out.strip()[:160])


@case('surf.unknown_node')
def c_sunk():
    return query('unknown-node 99', 'f.bcd', 'surf', '99')


def rowsame():
    pts = list(RECT)
    pts[4:8] = pts[0:4]
    return pts


@case('surf.failed_node')
def c_sfailed():
    wsl('mkdir', '-p', WORK)
    with open(f'{WORK}/f.bcd', 'w') as f:
        f.write('(bendcad 1)\n' + PATCH(RECT) + '\n' + PATCH(rowsame(), 2) + '\n')
    before = read('f.bcd')
    out, _ = cli('f.bcd', 'surf', '2')
    return ('nothing surfaced' in out and before == read('f.bcd'), out.strip()[:160])


@case('zone.surf')
def c_zone():
    fresh('z.bcd', RECTN)
    before = read('z.bcd')
    out, _ = cli('z.bcd', 'zone', '1')
    return ('topology-not-certified-over-zone' in out and before == read('z.bcd'), out.strip()[:160])


@case('feature.onpatch')
def c_feat():
    return reject([RECTN],
                  '(node 3 (holes 1 (face 1 0 top) through (hole 5 5 1)) (intent remove any any any any))', 3,
                  'unsupported-op', 'features-need-an-extruded-body')


@case('step.open')
def c_step():
    fresh('o.bcd', RECTN)
    before = read('o.bcd')
    out, _ = cli('o.bcd', 'step', '1', f'{WORK}/open.stp')
    return ('step-open-shell-not-in-profile' in out and before == read('o.bcd') and
            not os.path.exists(f'{WORK}/open.stp'), out.strip()[:160])


@case('archive.open')
def c_arc():
    fresh('o.bcd', RECTN)
    before = read('o.bcd')
    out, _ = cli('o.bcd', 'archive', '1', f'{WORK}/open.bin')
    return ('archive-open-shell-not-in-profile' in out and before == read('o.bcd') and
            not os.path.exists(f'{WORK}/open.bin'), out.strip()[:160])


@case('check.open')
def c_check():
    return query('check-needs-solid', 'f.bcd', 'check', '1')


@case('classify.open')
def c_classify():
    return query('classify-needs-solid', 'f.bcd', 'classify', '1', '5', '2', '0')


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
