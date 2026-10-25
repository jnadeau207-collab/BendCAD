import json
import math
import os
import re
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import e2e

OUT = os.path.join(HERE, 'corpus-report.json')
IC = e2e.IC
STEEL = '(material 1 steel 7850 0.000012 200000 0.3)'
RESULTS = []

TORSION = 7825.88576431322
ROD_T = [1115.92467306268, 3039.50640708873, 5858.7656417103]
ROD_EB = [1123.33704734549, 3096.52182745981, 6070.4208772597]
CANT_T = [702.147250238084, 4259.44177720725]
CANT_EB = [706.140404690695, 4425.30637737099]
DISC_W = 196.050693585673
DISC_GROW = (0.00420551554158856, 0.00425272771951658)
DISC_MODEL = 0.00177843245889509


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if not ok})


def modes(design, *args):
    t = time.time()
    out, _ = e2e.wsl(e2e.BIN, f'{e2e.WORK}/{design}', 'modes', *args, timeout=14400)
    return e2e.fem_lines(out, r'mode \d+ hz='), out, time.time() - t


def near(ms, f):
    return min(ms, key=lambda m: abs(m[3] - f))


def bending(ms, ref, eb):
    rows = []
    for t, e in zip(ref, eb):
        pair = sorted(ms, key=lambda m: abs(m[3] - t))[:2]
        budget = 0.25 * abs(t - e)
        rows.append(dict(timoshenko=t, euler=e, est=[m[3] for m in pair], bound=[m[4] for m in pair], model=budget,
                         ok=all(abs(m[3] - t) <= m[4] + budget for m in pair)))
    return rows


def rod_free(h):
    out, _ = e2e.fresh('rf.bcd', f'(node 1 (cylinder 5 200) {IC})', STEEL)
    ms, raw, dt = modes('rf.bcd', '1', '7', h)
    tor = near(ms, TORSION) if ms else None
    rows = bending(ms, ROD_T, ROD_EB) if len(ms) == 7 else []
    record('corpus.rod_free_free', 'committed' in out and tor is not None and abs(tor[3] - TORSION) <= tor[4]
           and rows and all(r['ok'] for r in rows), torsion=dict(exact=TORSION, got=tor), bending=rows, seconds=dt, raw=raw[-1500:])


def cantilever(h):
    out, _ = e2e.fresh('rc.bcd', f'(node 1 (cylinder 5 100) {IC})', STEEL)
    ms, raw, dt = modes('rc.bcd', '1', '5', h, 'plane', '0', '0', '0', '0', '0', '1', '1e-6')
    tor = near(ms, TORSION) if ms else None
    rows = bending(ms, CANT_T, CANT_EB) if len(ms) == 5 else []
    record('corpus.rod_cantilever', 'committed' in out and tor is not None and abs(tor[3] - TORSION) <= tor[4]
           and rows and all(r['ok'] for r in rows), torsion=dict(exact=TORSION, got=tor), bending=rows, seconds=dt, raw=raw[-1500:])


def disc_spin(h):
    out, _ = e2e.fresh('ds.bcd', f'(node 1 (cylinder 25 5) {IC})', STEEL)
    t = time.time()
    o, _ = e2e.wsl(e2e.BIN, f'{e2e.WORK}/ds.bcd', 'spin', '1', '60000', h, '0', '0', '0', '0', '0', '1', '0', timeout=14400)
    dt = time.time() - t
    wk = e2e.fem_lines(o, 'work_nmm')
    tip = e2e.fem_lines(o, 'tip_growth_mm')
    ok_w = len(wk) == 1 and abs(wk[0][3] - DISC_W) <= wk[0][4] + DISC_MODEL
    ok_t = len(tip) == 1 and DISC_GROW[0] - tip[0][4] <= tip[0][3] <= DISC_GROW[1] + tip[0][4]
    record('corpus.disc_spin', 'committed' in out and ok_w and ok_t, work=dict(plane_stress=DISC_W, model=DISC_MODEL, got=wk),
           tip=dict(band=DISC_GROW, got=tip), seconds=dt, raw=o[-1200:])


DISC_3D = {(2, 0): 9954.5388, (0, 1): 16568.5839, (3, 0): 22048.9423}


def love(n, s, b=25.0, t=5.0, E=200000.0, nu=0.3, rho=7.85e-9):
    from mpmath import mp, besselj, besseli, diff, findroot, sqrt, pi
    mp.dps = 30
    J = lambda x: besselj(n, x)
    I = lambda x: besseli(n, x)
    dJ = lambda x: diff(J, x)
    dI = lambda x: diff(I, x)
    f = lambda x: ((x ** 2 * J(x) + (1 - nu) * (x * dJ(x) - n * n * J(x))) * (x ** 3 * dI(x) - (1 - nu) * n * n * (x * dI(x) - I(x)))
                   - (x ** 2 * I(x) - (1 - nu) * (x * dI(x) - n * n * I(x))) * (x ** 3 * dJ(x) + (1 - nu) * n * n * (x * dJ(x) - J(x))))
    roots, x, prev = [], 0.5, f(0.5)
    while len(roots) <= s:
        x2 = x + 0.05
        cur = f(x2)
        if prev * cur < 0:
            roots.append(findroot(f, (x, x2), solver='anderson'))
        x, prev = x2, cur
    lam = roots[s]
    d = E * t ** 3 / (12 * (1 - nu * nu))
    return float(lam ** 2 / (2 * pi * b * b) * sqrt(d / (rho * t)))


def disc_modes(h):
    out, _ = e2e.fresh('dm.bcd', f'(node 1 (cylinder 25 5) {IC})', STEEL)
    ms, raw, dt = modes('dm.bcd', '1', '5', h)
    rows = []
    for key, ref in DISC_3D.items():
        cnt = 2 if key[0] > 0 else 1
        got = sorted(ms, key=lambda m: abs(m[3] - ref))[:cnt]
        rows.append(dict(mode=key, ref3d=ref, love=love(key[0], 0), est=[m[3] for m in got], bound=[m[4] for m in got],
                         ok=len(got) == cnt and all(abs(m[3] - ref) <= m[4] for m in got)))
    record('corpus.disc_modes', 'committed' in out and len(ms) == 5 and all(r['ok'] for r in rows), modes=rows, seconds=dt, raw=raw[-1500:])


def blade_path(k, n, r1=25.0, rc=50.0, sweep=90.0, thick=2.0):
    from mpmath import mp, mpf, cos, sin, pi
    mp.dps = 50
    sn = lambda x: 0.0 if abs(float(x)) < 1e-12 else float(x)
    f = lambda p: f'{sn(p[0])!r} {sn(p[1])!r}'
    th = 2 * pi * k / n
    rc, h = mpf(rc), mpf(thick) / 2
    a0, a1 = th, th + mpf(sweep) * pi / 180
    c = (sn((mpf(r1) - rc) * cos(th)), sn((mpf(r1) - rc) * sin(th)))
    P = lambda r, a: (mpf(c[0]) + r * cos(a), mpf(c[1]) + r * sin(a))
    E = lambda a: (sn(mpf(c[0]) + rc * cos(a)), sn(mpf(c[1]) + rc * sin(a)))
    ro, ri = rc + h, rc - h
    return (f'(path {f(P(ro, a0))} (arc {f(c)} {float(ro)!r} {f(P(ro, a1))} ccw) (arc {f(E(a1))} {float(h)!r} {f(P(ri, a1))} ccw) '
            f'(arc {f(c)} {float(ri)!r} {f(P(ri, a0))} cw) (arc {f(E(a0))} {float(h)!r} {f(P(ro, a0))} ccw))')


def impeller():
    n = 6
    prof = '(region (path -0.5 -0.5 (line 1 -0.5) (line 1 0) (arc 1 1 1 0 1 cw) (line 0 15) (line -0.5 15) (line -0.5 -0.5)))'
    edits = [f'(node 2 (prism -6 0 (region (circle 0 0 60))) {IC})']
    prev = 2
    for k in range(n):
        nid = 100 + k if k < n - 1 else 1
        edits += [f'(node {10 + k} (sweep (wall {blade_path(k, n)}) {prof}) {IC})', f'(node {nid} (union {prev} {10 + k}) {e2e.IA})']
        prev = nid
    t = time.time()
    e2e.cli('imp.bcd', 'new')
    out, _ = e2e.wsl(e2e.BIN, f'{e2e.WORK}/imp.bcd', 'apply', *edits, timeout=14400)
    build = time.time() - t
    a0 = 51 * math.pi
    ln = 52 * math.pi
    area = lambda u: a0 + ln * u + math.pi * u * u
    wall = 0.5 * area(1) + a0 + ln * (1 - math.pi / 4) + math.pi * (5 / 3 - math.pi / 2) + 14 * a0
    exact = math.pi * 3600 * 6 + n * (wall - 0.5 * area(1))
    ev, _ = e2e.cli('imp.bcd', 'eval')
    m = re.search(r'node 1:.*?volume=' + e2e.IVR, ev)
    vol = (float(m.group(1)), float(m.group(2))) if m else None
    ck, _ = e2e.cli('imp.bcd', 'check', '1')
    mo, raw, _ = e2e.moments('imp.bcd', 1)
    e2e.cli('imp.bcd', 'step', '1', f'{e2e.WORK}/imp.stp')
    o = e2e.occt(f'{e2e.WORK}/imp.stp')
    sym = mo is not None and e2e.has(mo['c'][0], 0.0, 1e-12) and e2e.has(mo['c'][1], 0.0, 1e-12) and all(e2e.has(mo['i'][k], 0.0, 1e-9) for k in (3, 4, 5))
    occ = mo is not None and o is not None and abs(o[0] - exact) / exact < 1e-7 and e2e.has(mo['c'][2], o[3], 1e-6)
    t = time.time()
    mach, _ = e2e.wsl(e2e.BIN, f'{e2e.WORK}/imp.bcd', 'machine', '1', '1.6', '20', '10', '40', '5', '2', timeout=14400)
    mt = time.time() - t
    record('corpus.impeller', 'committed' in out and e2e.tight(vol, exact, 1e-11) and ck.startswith('ok:') and sym and occ
           and 'verdict machinable' in mach, volume=vol, exact=exact, check=ck.strip()[:120], moments=mo, occt=o,
           machine=mach[-600:], build_seconds=build, machine_seconds=mt)


SCROLL_IN = [('a', (0, 0), 66, (66, 0), (0, 66), 1), ('a', (0, -8), 74, (0, 66), (-74, -8), 1), ('a', (8, -8), 82, (-74, -8), (8, -90), 1),
             ('a', (8, 0), 90, (8, -90), (98, 0), 1), ('l', (98, 0), (98, 75)), ('l', (98, 75), (76, 75)), ('l', (76, 75), (76, 0)),
             ('a', (71, 0), 5, (76, 0), (66, 0), -1)]
SCROLL_OUT = [('a', (0, 0), 69, (69, 0), (0, 69), 1), ('a', (0, -8), 77, (0, 69), (-77, -8), 1), ('a', (8, -8), 85, (-77, -8), (8, -93), 1),
              ('a', (8, 0), 93, (8, -93), (101, 0), 1), ('l', (101, 0), (101, 70)), ('l', (101, 70), (73, 70)), ('l', (73, 70), (73, 0)),
              ('a', (71, 0), 2, (73, 0), (69, 0), -1)]


def rev_seg(seg):
    if seg[0] == 'l':
        return ('l', seg[2], seg[1])
    _, c, r, a, b, sg = seg
    return ('a', c, r, b, a, -sg)


def band_loop():
    outer = [('l', (101, 70), (101, 0))] + [rev_seg(x) for x in reversed(SCROLL_OUT[:4])] + [rev_seg(SCROLL_OUT[7]), ('l', (73, 0), (73, 70)),
             ('l', (73, 70), (76, 70)), ('l', (76, 70), (76, 0)), SCROLL_IN[7]] + SCROLL_IN[:4] + [('l', (98, 0), (98, 70)), ('l', (98, 70), (101, 70))]
    return outer


def region_sx(loop):
    s = f'(region (path {loop[0][3][0]} {loop[0][3][1]}' if loop[0][0] == 'a' else f'(region (path {loop[0][1][0]} {loop[0][1][1]}'
    for seg in loop:
        if seg[0] == 'l':
            s += f' (line {seg[2][0]} {seg[2][1]})'
        else:
            _, c, r, a, b, sg = seg
            s += f' (arc {c[0]} {c[1]} {r} {b[0]} {b[1]} {"ccw" if sg > 0 else "cw"})'
    return s + '))'


def green(loop):
    from mpmath import mp, mpf, quad, cos, sin, atan2, pi
    mp.dps = 40
    tot = [mpf(0)] * 6
    for seg in loop:
        if seg[0] == 'l':
            (x0, y0), (x1, y1) = seg[1], seg[2]
            X = lambda t: x0 + (x1 - x0) * t
            Y = lambda t: y0 + (y1 - y0) * t
            dX = lambda t: mpf(x1 - x0)
            dY = lambda t: mpf(y1 - y0)
            lo, hi = 0, 1
        else:
            _, c, r, a, b, sg = seg
            t0 = atan2(a[1] - c[1], a[0] - c[0])
            t1 = atan2(b[1] - c[1], b[0] - c[0])
            if sg > 0 and t1 <= t0:
                t1 += 2 * pi
            if sg < 0 and t1 >= t0:
                t1 -= 2 * pi
            X = lambda t, c=c, r=r: c[0] + r * cos(t)
            Y = lambda t, c=c, r=r: c[1] + r * sin(t)
            dX = lambda t, r=r: -r * sin(t)
            dY = lambda t, r=r: r * cos(t)
            lo, hi = t0, t1
        fs = [lambda t: (X(t) * dY(t) - Y(t) * dX(t)) / 2, lambda t: X(t) ** 2 * dY(t) / 2, lambda t: -Y(t) ** 2 * dX(t) / 2,
              lambda t: X(t) ** 3 * dY(t) / 3, lambda t: -Y(t) ** 3 * dX(t) / 3, lambda t: X(t) ** 2 * Y(t) * dY(t) / 2]
        for k in range(6):
            tot[k] += quad(fs[k], [lo, hi])
    return tot


def scroll_exact():
    from mpmath import mpf, pi
    o, i = green(SCROLL_OUT), green([('l', (98, 70), (76, 70)) if seg == ('l', (98, 75), (76, 75)) else
                                     ('l', (98, 0), (98, 70)) if seg == ('l', (98, 0), (98, 75)) else
                                     ('l', (76, 70), (76, 0)) if seg == ('l', (76, 75), (76, 0)) else seg for seg in SCROLL_IN])
    hr = mpf(45)
    hole = [pi * hr ** 2, 0, 0, pi * hr ** 4 / 4, pi * hr ** 4 / 4, 0]
    zs = [(o, mpf(-3), mpf(63), 1), (i, mpf(0), mpf(60), -1), (hole, mpf(60), mpf(63), -1)]
    m = [mpf(0)] * 10
    for a, z0, z1, sg in zs:
        h, z1m, z2m = z1 - z0, (z1 ** 2 - z0 ** 2) / 2, (z1 ** 3 - z0 ** 3) / 3
        vals = [a[0] * h, a[1] * h, a[2] * h, a[0] * z1m, a[3] * h, a[4] * h, a[0] * z2m, a[5] * h, a[2] * z1m, a[1] * z1m]
        m = [x + sg * v for x, v in zip(m, vals)]
    v, sx, sy, sz, sxx, syy, szz, sxy, syz, szx = m
    c = [sx / v, sy / v, sz / v]
    cxx, cyy, czz = sxx - v * c[0] ** 2, syy - v * c[1] ** 2, szz - v * c[2] ** 2
    cxy, cyz, czx = sxy - v * c[0] * c[1], syz - v * c[1] * c[2], szx - v * c[2] * c[0]
    ii = [cyy + czz, cxx + czz, cxx + cyy, -cxy, -czx, -cyz]
    return float(v), [float(x) for x in c], [float(x) for x in ii]


def scroll():
    front = region_sx(SCROLL_OUT)[:-1] + ' (path 45 0 (arc 0 0 45 -45 0 ccw) (arc 0 0 45 45 0 ccw)))'
    edits = [f'(node 20 (prism 0 60 {region_sx(band_loop())}) {IC})', f'(node 21 (prism -3 0 {region_sx(SCROLL_OUT)}) {IC})',
             f'(node 22 (prism 60 63 {front}) {IC})', f'(node 23 (union 20 21) {e2e.IA})', f'(node 1 (union 23 22) {e2e.IA})']
    e2e.cli('sc.bcd', 'new')
    t = time.time()
    out, _ = e2e.wsl(e2e.BIN, f'{e2e.WORK}/sc.bcd', 'apply', *edits, timeout=14400)
    build = time.time() - t
    v, c, ii = scroll_exact()
    ev, _ = e2e.cli('sc.bcd', 'eval')
    m = re.search(r'node 1:.*?volume=' + e2e.IVR, ev)
    vol = (float(m.group(1)), float(m.group(2))) if m else None
    ck, _ = e2e.cli('sc.bcd', 'check', '1')
    mo, raw, _ = e2e.moments('sc.bcd', 1)
    big = max(abs(x) for x in ii[:3])
    ok_m = mo is not None and e2e.tight(mo['vol'], v, 1e-9) and all(e2e.has(mo['c'][k], c[k], 1e-9) for k in range(3)) \
        and all(e2e.has(mo['i'][k], ii[k], 1e-9 * big / max(1.0, abs(ii[k]))) for k in range(6))
    e2e.cli('sc.bcd', 'step', '1', f'{e2e.WORK}/sc.stp')
    o = e2e.occt(f'{e2e.WORK}/sc.stp')
    record('corpus.scroll_casing', 'committed' in out and e2e.tight(vol, v, 1e-9) and ck.startswith('ok:') and ok_m
           and o is not None and abs(o[0] - v) / v < 1e-7, volume=vol, exact=dict(volume=v, centroid=c, inertia=ii), moments=mo,
           occt=o, check=ck.strip()[:120], build_seconds=build, raw=raw[-500:])


def main():
    e2e.WORK = '/tmp/bc-corpus-k3'
    e2e.wsl('mkdir', '-p', e2e.WORK)
    h = os.environ.get('CORPUS_H', '4')
    which = sys.argv[1:] or ['rod_free', 'cantilever', 'disc_spin', 'disc_modes', 'impeller', 'scroll']
    for w in which:
        globals()[w]() if w in ('impeller', 'scroll') else globals()[w](h)
    json.dump(RESULTS, open(OUT, 'w'), indent=1)
    n = sum(1 for r in RESULTS if r['ok'])
    print(f'{n}/{len(RESULTS)} corpus members hold')
    sys.exit(0 if n == len(RESULTS) else 1)


if __name__ == '__main__':
    main()
