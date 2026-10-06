import hashlib
import json
import math
import os
import random
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-c07-solid'
OUT = os.path.join(HERE, 'solid-report.json')
N = int(os.environ.get('C07_SOLID_N', '40'))
MARGIN = 1e-3
CALL_S = float(os.environ.get('C07_SOLID_CALL_S', '60'))


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    try:
        r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                           env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    except subprocess.TimeoutExpired:
        return 'timeout', time.time() - t
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args, timeout=CALL_S)


RESULTS = []


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if k != 'detail'})


def box_o(a, b, c):
    def f(x, y, z):
        m = min(x, a - x, y, b - y, z, c - z)
        return m > 0, abs(m)
    return f, [(0, a), (0, b), (0, c)]


def cyl_o(r, h):
    def f(x, y, z):
        m = min(r - math.hypot(x, y), z, h - z)
        return m > 0, abs(m)
    return f, [(-r, r), (-r, r), (0, h)]


def cone_o(r, h):
    k = math.hypot(r, h)

    def f(x, y, z):
        m = min(z, (h * (r - math.hypot(x, y)) - r * z) / k)
        return m > 0, abs(m)
    return f, [(-r, r), (-r, r), (0, h)]


def sph_o(r, c=(0, 0, 0)):
    def f(x, y, z):
        m = r - math.dist((x, y, z), c)
        return m > 0, abs(m)
    return f, [(c[i] - r, c[i] + r) for i in range(3)]


def tor_m(R, r, x, y, z):
    return r - math.hypot(math.hypot(x, y) - R, z)


def tor_o(R, r):
    def f(x, y, z):
        m = tor_m(R, r, x, y, z)
        return m > 0, abs(m)
    return f, [(-R - r, R + r), (-R - r, R + r), (-r, r)]


def rot_x(deg, f):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))

    def g(x, y, z):
        return f(x, c * y + s * z, -s * y + c * z)
    return g


def cavity_o():
    def f(x, y, z):
        m = min(40 - math.hypot(x, y), z, 30 - z, -tor_m(20, 5, x, y, z - 15))
        return m > 0, abs(m)
    return f, [(-40, 40), (-40, 40), (0, 30)]


def rrect_m(x, y, W, H, R):
    cx = min(max(x, R), W - R)
    cy = min(max(y, R), H - R)
    if R <= x <= W - R or R <= y <= H - R:
        return min(x, W - x, y, H - y)
    return R - math.hypot(x - cx, y - cy)


def bracket_o():
    W, H, T, R = 80, 50, 6, 8

    def f(x, y, z):
        m = min(rrect_m(x, y, W, H, R), z, T - z, math.hypot(x - 10, y - 10) - 3, math.hypot(x - 70, y - 10) - 3)
        return m > 0, abs(m)
    return f, [(0, W), (0, H), (0, T)]


def pocket_o():
    def f(x, y, z):
        rr = math.hypot(x - 30, y - 20)
        outer = min(x, 60 - x, y, 40 - y, z, 10 - z)
        pocket = max(rr - 8, 6 - z)
        hole = rr - 4
        m = min(outer, pocket, hole)
        return m > 0, abs(m)
    return f, [(0, 60), (0, 40), (0, 10)]


PARTS = [
    ('box', ['(node 1 (box 10 20 30) (intent create 6 0 1 0))'], box_o(10, 20, 30), 1),
    ('cylinder', ['(node 1 (cylinder 5 10) (intent create 3 0 1 0))'], cyl_o(5, 10), 1),
    ('cone', ['(node 1 (cone 6 9) (intent create any 0 1 0))'], cone_o(6, 9), 1),
    ('sphere', ['(node 1 (sphere 7) (intent create 2 0 1 0))'], sph_o(7), 1),
    ('torus', ['(node 1 (torus 20 5) (intent create 8 0 1 1))'], tor_o(20, 5), 1),
    ('cavity', ['(node 1 (revolve (region (path 0 0 (line 40 0) (line 40 30) (line 0 30)) (circle 20 15 5))) (intent create any 0 1 1))'], cavity_o(), 1),
    ('bracket', ['(param W 80)', '(param H 50)', '(param T 6)', '(param R 8)',
                 '(node 1 (prism 0 T (region (path R 0 (line (- W R) 0) (arc (- W R) R R W R ccw) (line W (- H R)) (arc (- W R) (- H R) R (- W R) H ccw) (line R H) (arc R (- H R) R 0 (- H R) ccw) (line 0 R) (arc R R R R 0 ccw)))) (intent create 10 0 1 0))',
                 '(node 2 (holes 1 (face 1 0 top) through (hole 10 10 3) (hole (- W 10) 10 3)) (intent remove 2 2 1 2))'], bracket_o(), 2),
    ('pocket', ['(node 1 (box 60 40 10) (intent create 6 0 1 0))',
                '(node 2 (pocket 1 (face 1 0 top) 4 (region (circle 30 20 8))) (intent remove 2 1 1 0))',
                '(node 3 (holes 2 (face 2 0 top) through (hole 30 20 4)) (intent remove 1 2 1 1))'], pocket_o(), 3),
    ('moved-sphere', ['(node 1 (sphere 10) (intent create 2 0 1 0))', '(node 2 (move 1 20 0 0 0) (intent same 0 0 1 0))',
                      '(node 3 (rotate 2 z 90) (intent same 0 0 1 0))'], sph_o(10, (0, 20, 0)), 3),
    ('rotated-torus', ['(node 1 (torus 30 10) (intent create 8 0 1 1))', '(node 2 (rotate 1 x 30) (intent same 0 0 1 1))'],
     (rot_x(30, tor_o(30, 10)[0]), [(-40, 40), (-40, 40), (-30, 30)]), 2),
]




def main():
    wsl('mkdir', '-p', WORK)
    rng = random.Random(7)
    total_wrong = 0
    total_unc = 0
    for name, edits, (orc, bb), node in PARTS:
        d = f'{name}.bcd'
        cli(d, 'new')
        out, _ = cli(d, 'apply', *edits)
        if 'committed' not in out:
            record(f'solid.{name}.build', False, detail=out)
            continue
        out, dt = cli(d, 'check', str(node))
        record(f'solid.{name}.check', out.strip().startswith('ok'), out=out.strip(), secs=round(dt, 3))
        wrong, unc, times, pts = 0, 0, [], []
        while len(pts) < N:
            p = [rng.uniform(lo - 0.1 * (hi - lo), hi + 0.1 * (hi - lo)) for lo, hi in bb]
            p = [float(f'{c:.6g}') for c in p]
            inside, m = orc(*p)
            if m < MARGIN:
                continue
            pts.append((p, inside))
        detail = []
        for p, inside in pts:
            out, dt = cli(d, 'classify', str(node), *[repr(c) for c in p])
            times.append(dt)
            got = out.strip().split(' ')[0]
            want = 'inside' if inside else 'outside'
            if got in ('uncertain', 'timeout'):
                unc += 1
            elif got != want:
                wrong += 1
            detail.append(dict(p=p, want=want, got=got))
        total_wrong += wrong
        total_unc += unc
        record(f'solid.{name}.classify', wrong == 0 and unc == 0, points=len(pts), wrong=wrong, uncertain=unc,
               median_s=round(sorted(times)[len(times) // 2], 3), detail=detail)
    for name, node, p in [('box', 1, (5, 10, 30)), ('sphere', 1, (0, 7, 0)), ('cylinder', 1, (5, 0, 4)), ('torus', 1, (0, 25, 0)),
                          ('cavity', 1, (0, 20, 20)), ('moved-sphere', 3, (-10, 20, 0)), ('torus.seam', 1, (25, 0, 0)),
                          ('cavity.seam', 1, (20, 0, 20)), ('cone', 1, (0, 3, 4.5)), ('bracket', 2, (13, 10, 3))]:
        out, _ = cli(f"{name.split('.')[0]}.bcd", 'classify', str(node), *[repr(float(c)) for c in p])
        record(f'solid.{name}.boundary', out.strip().startswith('boundary'), out=out.strip(), p=p)
    blob = json.dumps(RESULTS, indent=1, sort_keys=True)
    open(OUT, 'w', newline='\n').write(blob)
    fails = [r['name'] for r in RESULTS if not r['ok']]
    print(f'{len(RESULTS) - len(fails)}/{len(RESULTS)} passed; sha256 {hashlib.sha256(blob.encode()).hexdigest()}')
    if fails:
        print('FAILED:', fails)
        sys.exit(1)


if __name__ == '__main__':
    main()
