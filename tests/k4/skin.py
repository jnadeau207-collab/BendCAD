import json
import math
import os
import re
import subprocess
import sys
import time

BIN = os.environ.get('K4_BIN', '/home/jesse/bc/bendcad')
WORK = '/home/jesse/k4'
IC = '(intent create any any any any)'
IS = '(intent same any any any any)'
IA = '(intent add any any any any)'
IR = '(intent remove any any any any)'
HERE = os.path.dirname(os.path.abspath(__file__))
rows = []


def wsl(*args, timeout=900):
    t0 = time.time()
    p = subprocess.run(['wsl.exe', '-e'] + list(args), capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'), stdin=subprocess.DEVNULL)
    return p.stdout + p.stderr, time.time() - t0


def fresh(name, *edits):
    wsl('mkdir', '-p', WORK)
    wsl('rm', '-f', f'{WORK}/{name}')
    wsl(BIN, f'{WORK}/{name}', 'new')
    return wsl(BIN, f'{WORK}/{name}', 'apply', *edits)


def line(out, n):
    m = re.search(rf'^node {n}: (.*)$', out, re.M)
    return m.group(1) if m else ''


def vol(s):
    m = re.search(r'volume=\[(\S+), (\S+)\]', s)
    return (float(m.group(1)), float(m.group(2))) if m else None


def f(x):
    return f'{x:.9f}'


def frame(o, u, v, s=1.0):
    return '(frame ' + ' '.join(f(c) for c in (*o, *u, *v, s)) + ')'


def circle_run(r, n=36):
    pts = []
    for k in range(n + 1):
        t = 2 * math.pi * k / n
        pts += [r * math.cos(t), r * math.sin(t)]
    return '(run ' + ' '.join(f(c) for c in pts) + ')'


def record(name, ok, **kw):
    rows.append(dict(name=name, ok=bool(ok), **kw))
    print(('PASS ' if ok else 'FAIL ') + name, json.dumps(kw)[:400])


def cylinder():
    s0 = f'(sec {circle_run(10)} {frame((0, 0, 0), (1, 0, 0), (0, 1, 0))})'
    s1 = f'(sec {circle_run(10)} {frame((0, 0, 20), (1, 0, 0), (0, 1, 0))})'
    out, dt = fresh('sk_cyl.bcd', f'(node 1 (skin {s0} {s1}) {IC})')
    v = vol(line(out, 1))
    ex = math.pi * 100 * 20
    record('skin.cylinder', v is not None and abs((v[0] + v[1]) / 2 - ex) / ex < 2e-6, seconds=round(dt, 2), vol=v, exact=ex,
           line=line(out, 1)[:300])


def frustum_tilted():
    a = math.radians(25)
    s0 = f'(sec {circle_run(10)} {frame((0, 0, 0), (1, 0, 0), (0, 1, 0))})'
    s1 = f'(sec {circle_run(10)} {frame((0, 0, 20), (math.cos(a), 0, math.sin(a)), (0, 1, 0), 0.5)})'
    out, dt = fresh('sk_tilt.bcd', f'(node 1 (skin {s0} {s1}) {IC})')
    record('skin.tilted_scaled', 'committed' in out, seconds=round(dt, 2), line=line(out, 1)[:300])


def blade_secs(n, span, twist_deg, taper):
    secs = []
    for i in range(n):
        z = span * i / (n - 1)
        t = math.radians(twist_deg * i / (n - 1))
        s = 1 - (1 - taper) * i / (n - 1)
        secs.append(f'(sec (naca 1) {frame((0, 0, z), (math.cos(t), math.sin(t), 0), (-math.sin(t), math.cos(t), 0), s)})')
    return ' '.join(secs)


def blade_bool():
    nodes = [f'(node 1 (naca4 4 4 12 40 33) {IC})', f'(node 3 (skin {blade_secs(4, 30, 30, 0.7)}) {IC})',
             f'(node 4 (box 60 60 10) {IC})', f'(node 5 (move 4 -10.0 -30.0 -5.0 0) {IS})']
    out, dt = fresh('sk_bl.bcd', *nodes, f'(node 6 (union 3 5) {IA})')
    if 'committed' not in out:
        fresh('sk_bl.bcd', *nodes)
    outi, dti = fresh('sk_bli.bcd', *nodes, f'(node 6 (intersection 3 5) {IS})')
    vb, vx, vu, vi = vol(line(out, 3)), vol(line(out, 5)), vol(line(out, 6)), vol(line(outi, 6))
    record('skin.blade', vb is not None, seconds=round(dt, 2), line=line(out, 3)[:300])
    ok = all([vb, vx, vu, vi])
    if ok:
        lhs = (vu[0] + vi[0], vu[1] + vi[1])
        rhs = (vb[0] + vx[0], vb[1] + vx[1])
        ok = lhs[0] <= rhs[1] + 1e-6 and rhs[0] <= lhs[1] + 1e-6
    record('skin.blade_union_identity', ok, union=line(out, 6)[:200], inter=line(outi, 6)[:200], seconds=[round(dt, 2), round(dti, 2)])


def cyl_bool():
    s0 = f'(sec {circle_run(10)} {frame((0, 0, 0), (1, 0, 0), (0, 1, 0))})'
    s1 = f'(sec {circle_run(10)} {frame((0, 0, 20), (1, 0, 0), (0, 1, 0))})'
    nodes = [f'(node 1 (skin {s0} {s1}) {IC})', f'(node 2 (box 30 30 10) {IC})', f'(node 3 (move 2 -15.0 -15.0 -5.0 0) {IS})']
    out, dt = fresh('sk_cb.bcd', *nodes, f'(node 4 (union 1 3) {IA})')
    outi, dti = fresh('sk_cbi.bcd', *nodes, f'(node 4 (intersection 1 3) {IS})')
    va, vb, vu, vi = vol(line(out, 1)), vol(line(out, 3)), vol(line(out, 4)), vol(line(outi, 4))
    ok = all([va, vb, vu, vi])
    if ok:
        ok = vu[0] + vi[0] <= va[1] + vb[1] + 1e-6 and va[0] + vb[0] <= vu[1] + vi[1] + 1e-6
    record('skin.cylinder_box_identity', ok, union=line(out, 4)[:200], inter=line(outi, 4)[:200], seconds=[round(dt, 2), round(dti, 2)])


def self_cross():
    a = math.radians(80)
    s0 = f'(sec {circle_run(10)} {frame((0, 0, 0), (1, 0, 0), (0, 1, 0))})'
    s1 = f'(sec {circle_run(10)} {frame((0, 0, 5), (math.cos(a), 0, math.sin(a)), (0, 1, 0))})'
    out, dt = fresh('sk_bad.bcd', f'(node 1 (skin {s0} {s1}) {IC})')
    record('skin.self_intersection_refused', 'skin-self-intersection-uncertain' in line(out, 1), seconds=round(dt, 2), line=line(out, 1)[:300])


def exports():
    out, dt = wsl(BIN, f'{WORK}/sk_bl.bcd', 'mass', '3')
    m = re.search(r'volume=\[(\S+), (\S+)\]', out)
    record('skin.mass', m is not None, seconds=round(dt, 2), out=out.strip()[:300])
    out, dt = wsl(BIN, f'{WORK}/sk_bl.bcd', 'step', '3', f'{WORK}/sk_bl.stp')
    st, _ = wsl('bash', '-c', f'grep -c B_SPLINE_SURFACE {WORK}/sk_bl.stp 2>/dev/null || echo 0; grep -c ADVANCED_FACE {WORK}/sk_bl.stp 2>/dev/null || echo 0')
    n = [int(x) for x in st.split() if x.isdigit()]
    nf = re.search(r'faces=(\d+)', line(open(os.path.join(HERE, 'skin-report.json')).read() if False else '', 3) or '')
    record('skin.step', len(n) == 2 and n[1] >= 49 and n[0] == n[1] - 2, seconds=round(dt, 2), counts=n, out=out.strip()[:200])


def main():
    self_cross()
    cylinder()
    cyl_bool()
    frustum_tilted()
    blade_bool()
    exports()
    json.dump(dict(binary=BIN, rows=rows), open(os.path.join(HERE, 'skin-report.json'), 'w'), indent=1)
    print(sum(r['ok'] for r in rows), '/', len(rows))


if __name__ == '__main__':
    main()
