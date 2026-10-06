import hashlib
import itertools
import json
import math
import os
import random
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-c07-zone'
OUT = os.path.join(HERE, 'zone-report.json')
N = int(os.environ.get('C07_ZONE_N', '12'))
IV = r'\[([^,\]]+), ([^\]]+)\]'


def wsl(*args, timeout=600):
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    t = time.time()
    try:
        r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                           env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    except subprocess.TimeoutExpired:
        return 'timeout', time.time() - t
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


RESULTS = []


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if k not in ('detail',)})


BRACKET = ['(node 1 (prism 0 T (region (path R 0 (line (- W R) 0) (arc (- W R) R R W R ccw) (line W (- H R)) (arc (- W R) (- H R) R (- W R) H ccw) (line R H) (arc R (- H R) R 0 (- H R) ccw) (line 0 R) (arc R R R R 0 ccw)))) (intent create 10 0 1 0))',
           '(node 2 (holes 1 (face 1 0 top) through (hole E E (/ D 2)) (hole (- W E) E (/ D 2))) (intent remove 2 2 1 2))',
           '(node 3 (pocket 2 (face 1 0 top) P (region (circle (/ W 2) (/ H 2) G))) (intent remove any any 1 any))']

PARTS = [
    ('plate', {'W': (40, 39.8, 40.2), 'H': (20, 19.9, 20.1), 'T': (5, 4.9, 5.1)},
     ['(node 1 (prism 0 T (region (path 0 0 (line W 0) (line W H) (line 0 H)))) (intent create 6 0 1 0))'], [1],
     lambda p: (p['W'] * p['H'] * p['T'], 2 * (p['W'] * p['H'] + (p['W'] + p['H']) * p['T']))),
    ('bracket', {'W': (80, 79.9, 80.1), 'H': (50, 49.9, 50.1), 'T': (6, 5.9, 6.1), 'R': (8, 7.9, 8.1), 'D': (6, 5.95, 6.05),
                 'E': (10, 9.9, 10.1), 'P': (2, 1.9, 2.1), 'G': (8, 7.9, 8.1)}, BRACKET, [1, 2, 3], None),
    ('pad', {'A': (30, 29.9, 30.1), 'K': (4, 3.9, 4.1), 'Q': (6, 5.8, 6.2)},
     ['(node 1 (box A A K) (intent create 6 0 1 0))', '(node 2 (pad 1 (face 1 0 top) Q (region (circle (/ A 2) (/ A 2) 5))) (intent add 2 1 1 0))'], [2],
     lambda p: (p['A'] ** 2 * p['K'] + math.pi * 25 * p['Q'], 2 * p['A'] ** 2 + 4 * p['A'] * p['K'] + 2 * math.pi * 5 * p['Q'])),
    ('revolve-cavity', {'A': (40, 39.5, 40.5), 'C': (5, 4.9, 5.1)},
     ['(node 1 (revolve (region (path 0 0 (line A 0) (line A 30) (line 0 30)) (circle 20 15 C))) (intent create any 0 1 1))'], [1],
     lambda p: (math.pi * p['A'] ** 2 * 30 - 2 * math.pi ** 2 * 20 * p['C'] ** 2,
                2 * math.pi * p['A'] ** 2 + 2 * math.pi * p['A'] * 30 + 4 * math.pi ** 2 * 20 * p['C'])),
    ('revolve-slant', {'A': (10, 9.8, 10.2), 'B': (4, 3.9, 4.1), 'Z': (12, 11.8, 12.2)},
     ['(node 1 (revolve (region (path 0 0 (line A 0) (line B Z) (line 0 Z)))) (intent create any 0 1 0))'], [1],
     lambda p: (math.pi * p['Z'] / 3 * (p['A'] ** 2 + p['A'] * p['B'] + p['B'] ** 2),
                math.pi * (p['A'] ** 2 + p['B'] ** 2) + math.pi * (p['A'] + p['B']) * math.hypot(p['A'] - p['B'], p['Z']))),
    ('rotated', {'W': (40, 39.8, 40.2), 'T': (5, 4.9, 5.1)},
     ['(node 1 (prism 0 T (region (path 0 0 (line W 0) (arc W 10 10 W 20 ccw) (line 0 20)))) (intent create any 0 1 0))', '(node 2 (rotate 1 x 30) (intent same 0 0 1 0))'], [2],
     lambda p: ((p['W'] * 20 + math.pi * 50) * p['T'], 2 * (p['W'] * 20 + math.pi * 50) + (2 * p['W'] + 20 + math.pi * 10) * p['T'])),
]

NEG = [
    ('hole-crosses-edge', {'X': (5, 1.5, 5)}, ['(node 1 (box 20 20 5) (intent create 6 0 1 0))', '(node 2 (holes 1 (face 1 0 top) through (hole X 10 2)) (intent remove 1 2 1 1))'], 2),
    ('holes-collide', {'S': (10, 3.5, 10)}, ['(node 1 (box 30 20 5) (intent create 6 0 1 0))', '(node 2 (holes 1 (face 1 0 top) through (hole 8 10 2) (hole (+ 8 S) 10 2)) (intent remove 2 2 1 2))'], 2),
    ('arc-not-identical', {'R': (5, 4.9, 5.1), 'Q': (5, 4.9, 5.1)}, ['(node 1 (prism 0 2 (region (path 0 0 (line 10 0) (arc 10 R R 10 (+ R Q) ccw) (line 0 10)))) (intent create any 0 1 0))'], 1),
    ('depth-reaches-floor', {'P': (2, 1, 6)}, ['(node 1 (box 20 20 5) (intent create 6 0 1 0))', '(node 2 (pocket 1 (face 1 0 top) P (region (circle 10 10 3))) (intent remove any any 1 any))'], 2),
]


def params_cmds(ps, at=None):
    out = []
    for k, (nom, lo, hi) in ps.items():
        v = nom if at is None else at[k]
        out.append(f'(param {k} {v!r} {min(lo, v)!r} {max(hi, v)!r})' if at is None else f'(param {k} {v!r} {v!r} {v!r})')
    return out


def zone_of(out):
    m = re.search(r'volume=' + IV + r' area=' + IV, out)
    return [float(m.group(i)) for i in range(1, 5)] if m else None


def eval_of(out, node):
    m = re.search(rf'node {node}: ok .*?volume=' + IV + r' area=' + IV, out)
    return [float(m.group(i)) for i in range(1, 5)] if m else None


def main():
    wsl('mkdir', '-p', WORK)
    rng = random.Random(11)
    for name, ps, nodes, targets, exact in PARTS:
        d = f'{name}.bcd'
        cli(d, 'new')
        out, _ = cli(d, 'apply', *params_cmds(ps), *nodes)
        if 'committed' not in out:
            record(f'zone.{name}.build', False, detail=out)
            continue
        zs = {}
        for t in targets:
            out, dt = cli(d, 'zone', str(t))
            z = zone_of(out)
            zs[t] = z
            record(f'zone.{name}.n{t}.certified', z is not None, secs=round(dt, 3), out=out.strip()[:200])
        keys = list(ps)
        corners = [dict(zip(keys, c)) for c in itertools.product(*[(ps[k][1], ps[k][2]) for k in keys])][:16]
        samples = corners + [{k: rng.uniform(ps[k][1], ps[k][2]) for k in keys} for _ in range(N)]
        sd = f'{name}-s.bcd'
        inside = {t: True for t in targets}
        lo_seen = {t: [math.inf, math.inf] for t in targets}
        hi_seen = {t: [-math.inf, -math.inf] for t in targets}
        exact_ok = True
        for smp in samples:
            smp = {k: float(f'{v:.9g}') for k, v in smp.items()}
            cli(sd, 'new')
            out, _ = cli(sd, 'apply', *params_cmds(ps, smp), *nodes)
            ev, _ = cli(sd, 'eval')
            for t in targets:
                e = eval_of(ev, t)
                z = zs.get(t)
                if e is None or z is None:
                    inside[t] = False
                    continue
                inside[t] &= z[0] <= e[1] and e[0] <= z[1] and z[2] <= e[3] and e[2] <= z[3]
                lo_seen[t] = [min(lo_seen[t][0], e[0]), min(lo_seen[t][1], e[2])]
                hi_seen[t] = [max(hi_seen[t][0], e[1]), max(hi_seen[t][1], e[3])]
            if exact:
                v, a = exact(smp)
                z = zs[targets[-1]]
                exact_ok &= z is not None and z[0] <= v <= z[1] and z[2] <= a <= z[3]
        for t in targets:
            z = zs[t]
            if z is None:
                continue
            spread = [hi_seen[t][0] - lo_seen[t][0], hi_seen[t][1] - lo_seen[t][1]]
            width = [z[1] - z[0], z[3] - z[2]]
            ratio = [width[i] / spread[i] if spread[i] > 0 else math.inf for i in range(2)]
            record(f'zone.{name}.n{t}.encloses', inside[t], samples=len(samples), zone=z, seen=[lo_seen[t], hi_seen[t]])
            record(f'zone.{name}.n{t}.tight', max(ratio) < 1.6, width_over_spread=[round(r, 3) for r in ratio])
        if exact:
            record(f'zone.{name}.analytic', exact_ok)
    for name, ps, nodes, t in NEG:
        d = f'neg-{name}.bcd'
        cli(d, 'new')
        out, _ = cli(d, 'apply', *params_cmds(ps), *nodes)
        if 'committed' not in out:
            record(f'zone.neg.{name}.build', False, detail=out)
            continue
        out, dt = cli(d, 'zone', str(t))
        record(f'zone.neg.{name}', 'topology-not-certified-over-zone' in out and 'numerical-uncertainty' in out, out=out.strip()[:200], secs=round(dt, 3))
    blob = json.dumps(RESULTS, indent=1, sort_keys=True)
    open(OUT, 'w', newline='\n').write(blob)
    fails = [r['name'] for r in RESULTS if not r['ok']]
    print(f'{len(RESULTS) - len(fails)}/{len(RESULTS)} passed; sha256 {hashlib.sha256(blob.encode()).hexdigest()}')
    if fails:
        print('FAILED:', fails)
        sys.exit(1)


if __name__ == '__main__':
    main()
