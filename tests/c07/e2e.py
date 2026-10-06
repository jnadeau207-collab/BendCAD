import json
import os
import random
import re
import subprocess
import sys
import time
from fractions import Fraction as Fr

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import oracle as O

BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
OUT = os.path.join(HERE, 'e2e-report.json')
RESULTS = []
TIMES = []


def run(*args):
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    t = time.time()
    r = subprocess.run([*pre, BIN, 'geom', *args], capture_output=True, text=True, timeout=600)
    TIMES.append(time.time() - t)
    return r.stdout + r.stderr


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    if not ok:
        print('FAIL', name, info)


IV = r'\[([^,\]]+), ([^\]]+)\]'


def parse(out):
    pts, uns, ovs = [], [], []
    for ln in out.splitlines():
        m = re.match(r'point s=' + IV + r' t=' + IV + r'.*class=(.*)$', ln)
        if m:
            pts.append((Fr(float(m.group(1))), Fr(float(m.group(2))), Fr(float(m.group(3))), Fr(float(m.group(4))), m.group(5).strip()))
            continue
        m = re.match(r'unresolved s=' + IV + r' t=' + IV, ln)
        if m:
            uns.append((Fr(float(m.group(1))), Fr(float(m.group(2))), Fr(float(m.group(3))), Fr(float(m.group(4)))))
            continue
        m = re.match(r'overlap s=' + IV + r' t=' + IV, ln)
        if m:
            ovs.append((Fr(float(m.group(1))), Fr(float(m.group(2)))))
    return pts, uns, ovs, out


def sx(kind, vals):
    return '(' + kind + ' ' + ' '.join(repr(float(v)) for v in vals) + ')'


def check_1d(name, oracle_kind, roots, out, in_domain=None):
    pts, uns, ovs, raw = parse(out)
    if 'error' in raw:
        record(name, False, out=raw)
        return
    if oracle_kind == 'identical':
        record(name, len(ovs) == 1 and not pts, kind='identical', out=raw)
        return
    covered = True
    for lo, hi in roots:
        r = (lo + hi) / 2
        inp = sum(1 for p in pts if p[0] <= r <= p[1])
        inu = sum(1 for u in uns if u[0] <= r <= u[1])
        if inp != 1 and inu == 0:
            covered = False
    each = all(sum(1 for lo, hi in roots if p[0] <= (lo + hi) / 2 <= p[1]) == 1 for p in pts)
    record(name, covered and each and not ovs, oracle_roots=len(roots), points=len(pts), unresolved=len(uns))


def rnd(a, b, k=2):
    return round(random.uniform(a, b), k)


def unit_like():
    while True:
        v = [rnd(-1, 1, 1) for _ in range(3)]
        if any(v):
            return v


def gen_curve(kind):
    if kind == 'line':
        return [rnd(-3, 3) for _ in range(3)] + unit_like() + [-4.0, 4.0]
    if kind == 'circle':
        c = [rnd(-2, 2) for _ in range(3)]
        a = random.choice([[1, 0, 0, 0, 1, 0], [1, 0, 0, 0, 0, 1], [0, 1, 0, 0, 0, 1], [1, 0, 0, 0, 0.6, 0.8], [0.6, 0.8, 0, 0, 0, 1]])
        lo = random.choice([-1.0, -0.5, -0.25])
        hi = random.choice([1.0, 0.5, 0.75])
        return c + a + [rnd(0.5, 3, 1), lo, hi]
    if kind == 'bezier':
        return [rnd(-3, 3, 1) for _ in range(12)] + [0.0, 1.0]
    if kind == 'conic':
        return [rnd(-3, 3, 1) for _ in range(9)] + [1.0, random.choice([0.5, 0.75, 1.0, 1.5, 2.0]), 1.0, 0.0, 1.0]


def gen_surf(kind):
    if kind == 'plane':
        return [rnd(-1, 1) for _ in range(3)] + random.choice([[1, 0, 0, 0, 1, 0], [1, 0, 0, 0, 0, 1], [0, 1, 0, 0, 0, 1], [0.6, 0.8, 0, 0, 0, 1]])
    if kind == 'sphere':
        return [rnd(-1, 1) for _ in range(3)] + [rnd(0.5, 3, 1)]
    if kind == 'cylinder':
        return [rnd(-1, 1) for _ in range(3)] + random.choice([[0, 0, 1], [1, 0, 0], [0, 1, 0], [0, 0.6, 0.8]]) + [rnd(0.5, 2, 1)]
    if kind == 'cone':
        return [rnd(-1, 1) for _ in range(3)] + random.choice([[0, 0, 1], [1, 0, 0], [0, 0.6, 0.8]]) + [rnd(0.2, 1.5, 1)]
    if kind == 'torus':
        R = rnd(1.5, 3, 1)
        return [rnd(-1, 1) for _ in range(3)] + random.choice([[0, 0, 1], [1, 0, 0], [0, 0.6, 0.8]]) + [R, rnd(0.2, R - 0.3, 1)]


def random_cs(n):
    random.seed(7)
    kinds_c = ['line', 'circle', 'bezier', 'conic']
    kinds_s = ['plane', 'sphere', 'cylinder', 'cone', 'torus']
    for i in range(n):
        ck = kinds_c[i % 4]
        sk = kinds_s[(i // 4) % 5]
        cv = gen_curve(ck)
        sv = gen_surf(sk)
        kind, roots = O.curve_surface_roots(ck, cv, sk, sv)
        out = run('intersect', sx(ck, cv), sx(sk, sv))
        check_1d(f'cs.{i}.{ck}-{sk}', kind, roots, out)


def special_cs():
    cases = [
        ('tangent.line-sphere', 'line', [-5, 2, 0, 1, 0, 0, 0, 10], 'sphere', [0, 0, 0, 2]),
        ('endpoint.line-plane', 'line', [0, 0, -1, 0, 0, 1, 0, 1], 'plane', [0, 0, 0, 1, 0, 0, 0, 1, 0]),
        ('seam.circle-plane', 'circle', [0, 0, 0, 1, 0, 0, 0, 1, 0, 2, -1, 1], 'plane', [0, 0, 0, 1, 0, 0, 0, 0, 1]),
        ('tangent.seam-circle-plane', 'circle', [0, 0, 0, 1, 0, 0, 0, 1, 0, 2, -1, 1], 'plane', [-2, 0, 0, 0, 1, 0, 0, 0, 1]),
        ('near.circle-sphere', 'circle', [0, 0, 0.6, 1, 0, 0, 0, 1, 0, 0.8, -1, 1], 'sphere', [0, 0, 0, 1]),
        ('on.circle-torus', 'circle', [0, 0, 0, 1, 0, 0, 0, 1, 0, 4, -1, 1], 'torus', [0, 0, 0, 0, 0, 1, 3, 1]),
        ('on.circle-sphere', 'circle', [0, 0, 3, 1, 0, 0, 0, 1, 0, 4, -1, 1], 'sphere', [0, 0, 0, 5]),
        ('on.line-cylinder', 'line', [1, 0, 0, 0, 0, 1, -2, 2], 'cylinder', [0, 0, 0, 0, 0, 1, 1]),
        ('on.line-cone', 'line', [0, 0, 0, 1, 0, 2, 0, 3], 'cone', [0, 0, 0, 0, 0, 1, 0.5]),
        ('other-nappe.line-cone', 'line', [0, 0, 0, 1, 0, -2, 0, 3], 'cone', [0, 0, 0, 0, 0, 1, 0.5]),
        ('through-apex.line-cone', 'line', [0, 0, 0, 1, 0, 2, -3, 3], 'cone', [0, 0, 0, 0, 0, 1, 0.5]),
        ('miss.line-sphere', 'line', [-5, 3, 0, 1, 0, 0, 0, 10], 'sphere', [0, 0, 0, 2]),
        ('cluster.bezier-plane', 'bezier', [0, -1, 0, 1, 1, 0, 2, -1, 0, 3, 1, 0, 0, 1], 'plane', [0, 0, 0, 1, 0, 0, 0, 0, 1]),
    ]
    for name, ck, cv, sk, sv in cases:
        out = run('intersect', sx(ck, cv), sx(sk, sv))
        pts, uns, ovs, raw = parse(out)
        kind, roots = O.curve_surface_roots(ck, cv, sk, sv)
        if name.startswith('on.'):
            record(name, kind == 'identical' and len(ovs) == 1 and not pts and not uns, out=raw)
        elif name.startswith('other-nappe'):
            record(name, len(pts) == 1 and pts[0][0] <= 0 <= pts[0][1] and not ovs and not uns, out=raw)
        elif name.startswith('through-apex'):
            record(name, len(ovs) == 1 and ovs[0][0] <= 0 and ovs[0][1] == 3 and not pts and not uns, out=raw)
        elif name.startswith('tangent.line'):
            record(name, not pts and len(uns) >= 1 and all(u[0] <= Fr(5) <= u[1] for u in uns[:1]), out=raw)
        elif name.startswith('endpoint'):
            record(name, len(pts) == 1 and 'a-end' in pts[0][4], out=raw)
        elif name.startswith('seam'):
            record(name, len(pts) == 2 and sorted(p[4] for p in pts) == ['interior', 'seam'], out=raw)
        elif name.startswith('tangent.seam'):
            record(name, not pts and len(uns) >= 1, out=raw)
        elif name.startswith('near.'):
            record(name, kind == 'roots' and not pts and not ovs and len(roots) == 0 and not uns and TIMES[-1] < 30, out=raw, secs=TIMES[-1], roots=len(roots))
        else:
            check_1d(name, kind, roots, out)


def random_cc2(n):
    random.seed(11)
    for i in range(n):
        ck = ['line', 'circle', 'bezier', 'conic'][i % 4]
        cv = gen_curve(ck)
        if ck == 'circle':
            cv[3:9] = [1, 0, 0, 0, 1, 0]
        cv = [v for v in cv]
        if ck in ('bezier', 'conic'):
            for k in range(2, 12 if ck == 'bezier' else 9, 3):
                cv[k] = 0.0
        else:
            cv[2] = 0.0
            if ck == 'line':
                cv[5] = 0.0
                if cv[3] == 0 and cv[4] == 0:
                    cv[3] = 1.0
        lv = [rnd(-2, 2), rnd(-2, 2), 0.0, rnd(-1, 1, 1) or 0.5, rnd(-1, 1, 1) or 0.3, 0.0, -10.0, 10.0]
        f, (lo, hi) = O.line_poly_2d(ck, cv, 0, 1, 'line', lv)
        roots = O.isolate(f, lo, hi) if f else []
        out = run('intersect', sx(ck, cv), sx('line', lv))
        if ck == 'line':
            pts, uns, ovs, raw = parse(out)
            record(f'cc2.{i}.line-line', (len(pts) == len(roots) or (not f and (ovs or not pts))), out=raw, roots=len(roots))
            continue
        check_1d(f'cc2.{i}.{ck}-line', 'roots', roots, out)


def parse_ss(out):
    curves, uns, coin = [], 0, 'coincide' in out
    cur = None
    for ln in out.splitlines():
        if ln.startswith('curve '):
            cur = dict(closed=ln.split()[1] == 'closed', pts=[])
            curves.append(cur)
        elif ln.startswith('  p ') and cur is not None:
            iv = re.findall(IV, ln.split(' a=')[0])
            cur['pts'].append([(Fr(float(a)), Fr(float(b))) for a, b in iv[:3]])
        elif ln.startswith('summary'):
            m = re.search(r'unresolved=(\d+)', ln)
            uns = int(m.group(1)) if m else 0
    return curves, uns, coin


def imp(kind, v, p):
    x = [Fr(c) for c in p]
    if kind == 'plane':
        o, u, w = [Fr(c) for c in v[0:3]], [Fr(c) for c in v[3:6]], [Fr(c) for c in v[6:9]]
        n = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]]
        return sum(n[i] * (x[i] - o[i]) for i in range(3)), sum(abs(c) for c in n)
    o = [Fr(c) for c in v[0:3]]
    m = [x[i] - o[i] for i in range(3)]
    mm = sum(c * c for c in m)
    if kind == 'sphere':
        return mm - Fr(v[3]) ** 2, 2 * sum(abs(c) for c in m)
    a = [Fr(c) for c in v[3:6]]
    aa = sum(c * c for c in a)
    am = sum(a[i] * m[i] for i in range(3))
    if kind == 'cylinder':
        return aa * mm - am * am - aa * Fr(v[6]) ** 2, 2 * aa * sum(abs(c) for c in m) + 2 * abs(am) * sum(abs(c) for c in a)
    if kind == 'torus':
        R, r = Fr(v[6]), Fr(v[7])
        w = mm + R * R - r * r
        return aa * w * w - 4 * R * R * (aa * mm - am * am), 4 * aa * abs(w) * sum(abs(c) for c in m) + 8 * R * R * aa * sum(abs(c) for c in m)


def on_both(k1, v1, k2, v2, curves):
    for c in curves:
        for box in c['pts']:
            mid = [(lo + hi) / 2 for lo, hi in box]
            diag = sum(hi - lo for lo, hi in box) + Fr(1, 10 ** 12)
            for k, v in ((k1, v1), (k2, v2)):
                g, grad = imp(k, v, [float(t) for t in mid])
                if abs(g) > (grad + 1) * diag * 4:
                    return False
    return True


def ss_case(name, k1, v1, k2, v2, box, want, closed=None):
    out = run('intersect', sx(k1, v1), sx(k2, v2), sx('box', box))
    curves, uns, coin = parse_ss(out)
    if want == 'coincide':
        record(name, coin and not curves, out=out[:300])
        return
    ok = len(curves) == want and uns == 0 and on_both(k1, v1, k2, v2, curves)
    if closed is not None:
        ok = ok and all(c['closed'] == closed for c in curves)
    record(name, ok, curves=len(curves), want=want, unresolved=uns, closed=[c['closed'] for c in curves])


def random_ss(n):
    random.seed(23)
    for i in range(n):
        kind = i % 5
        if kind == 0:
            c = [rnd(-1, 1) for _ in range(3)]
            r = rnd(0.5, 2, 1)
            z = rnd(-2.5, 2.5)
            want = 1 if abs(z - c[2]) < r else 0
            if abs(abs(z - c[2]) - r) < 0.05:
                continue
            ss_case(f'ss.{i}.sphere-plane', 'sphere', c + [r], 'plane', [0, 0, z, 1, 0, 0, 0, 1, 0], [-4, 4.1, -4, 4.2, -4, 4.3], want, True)
        elif kind == 1:
            c1 = [rnd(-1, 1) for _ in range(3)]
            c2 = [rnd(-1, 1) for _ in range(3)]
            r1, r2 = rnd(0.5, 2, 1), rnd(0.5, 2, 1)
            d = sum((a - b) ** 2 for a, b in zip(c1, c2)) ** 0.5
            want = 1 if abs(r1 - r2) < d < r1 + r2 else 0
            if abs(d - (r1 + r2)) < 0.05 or abs(d - abs(r1 - r2)) < 0.05:
                continue
            ss_case(f'ss.{i}.sphere-sphere', 'sphere', c1 + [r1], 'sphere', c2 + [r2], [-4, 4.1, -4, 4.2, -4, 4.3], want, True)
        elif kind == 2:
            r = rnd(0.5, 1.5, 1)
            pl = [0, 0, rnd(-1, 1), 1, 0, rnd(0.2, 0.9, 1), 0, 1, 0]
            ss_case(f'ss.{i}.cylinder-plane', 'cylinder', [0, 0, 0, 0, 0, 1, r], 'plane', pl, [-4, 4.1, -4, 4.2, -4, 4.3], 1, True)
        elif kind == 3:
            r1 = rnd(0.8, 1.5, 1)
            r2 = rnd(0.2, 1.2, 1)
            c = rnd(-1, 1, 1)
            import math
            phis = [2 * math.pi * k / 4000 for k in range(4000)]
            pos = [r1 * r1 - (c + r2 * math.cos(f)) ** 2 > 0 for f in phis]
            if all(pos):
                want = 2
            elif not any(pos):
                want = 0
            else:
                runs = sum(1 for k in range(4000) if pos[k] and not pos[k - 1])
                want = runs
            mins = min(abs(r1 * r1 - (c + r2 * math.cos(f)) ** 2) for f in phis)
            if mins < 1e-3:
                continue
            ss_case(f'ss.{i}.cyl-cyl', 'cylinder', [0, 0, 0, 0, 0, 1, r1], 'cylinder', [0, c, 0, 1, 0, 0, r2], [-3, 3.1, -3, 3.2, -3, 3.3], want, True)
        else:
            R = rnd(2, 3, 1)
            r = rnd(0.3, 1, 1)
            z = rnd(-1.2, 1.2)
            if abs(abs(z) - r) < 1e-3:
                continue
            want = 2 if abs(z) < r else 0
            ss_case(f'ss.{i}.torus-plane', 'torus', [0, 0, 0, 0, 0, 1, R, r], 'plane', [0, 0, z, 1, 0, 0, 0, 1, 0], [-5, 5.1, -5, 5.2, -2, 2.3], want, True)
    ss_case('ss.coincide.planes', 'plane', [0, 0, 1, 1, 0, 0, 0, 1, 0], 'plane', [5, 5, 1, 0, 1, 0, 2, 0, 0], [-3, 3, -3, 3, -3, 3], 'coincide')
    ss_case('ss.coincide.tori', 'torus', [0, 0, 0, 0, 0, 1, 3, 1], 'torus', [0, 0, 0, 0, 0, 2, 3, 1], [-5, 5, -5, 5, -2, 2], 'coincide')
    for name, k1, v1, k2, v2 in [('ss.tangent.sphere-plane', 'sphere', [0, 0, 0, 1.5], 'plane', [0, 0, 1.5, 1, 0, 0, 0, 1, 0]),
                                 ('ss.tangent.spheres', 'sphere', [0, 0, 0, 1], 'sphere', [2, 0, 0, 1]),
                                 ('ss.tangent.inside', 'sphere', [0, 0, 0, 2], 'sphere', [1, 0, 0, 1])]:
        out = run('intersect', sx(k1, v1), sx(k2, v2), sx('box', [-4, 4.1, -4, 4.2, -4, 4.3]))
        curves, uns, coin = parse_ss(out)
        record(name, uns >= 1 and all(not c['closed'] for c in curves) and on_both(k1, v1, k2, v2, curves), curves=len(curves), unresolved=uns)
    ss_case('ss.plane-plane', 'plane', [0, 0, 1, 1, 0, 0, 0, 1, 0], 'plane', [0, 0, 0, 1, 0, 0, 0, 0.6, 0.8], [-3, 3.1, -3, 3.2, -3, 3.3], 1, False)


def main():
    random_cs(int(os.environ.get('C07_N', '120')))
    special_cs()
    random_cc2(int(os.environ.get('C07_N2', '60')))
    random_ss(int(os.environ.get('C07_N3', '60')))
    rep = dict(passed=sum(r['ok'] for r in RESULTS), total=len(RESULTS), mean_query_s=sum(TIMES) / max(len(TIMES), 1),
               max_query_s=max(TIMES) if TIMES else 0, results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1, default=str)
    print(f"{rep['passed']}/{rep['total']} passed; mean {rep['mean_query_s']:.3f}s max {rep['max_query_s']:.3f}s")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
