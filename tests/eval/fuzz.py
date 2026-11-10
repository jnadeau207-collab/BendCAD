import json
import math
import os
import random
import re
import subprocess
import sys
import time
from concurrent.futures import ProcessPoolExecutor

BIN = os.environ.get('FUZZ_BIN', '/home/jesse/bc/bendcad')
WORK = os.environ.get('FUZZ_WORK', '/var/tmp/fuzz')
OCCT = os.environ.get('FUZZ_OCCT', '1') == '1'
IC = '(intent create any any any any)'
IS = '(intent same any any any any)'
INTENT = {'union': 'add', 'intersection': 'same', 'difference': 'remove'}
KINDS = ['box', 'cylinder', 'cone', 'sphere', 'torus', 'revolve', 'prism']
MODES = ['general', 'general', 'general', 'axis', 'coplanar', 'tangent', 'coaxial', 'seam', 'nearmiss']


def f(x):
    return repr(float(x))


def shape(rng, nid, kind):
    if kind == 'box':
        a, b, c = (rng.uniform(4, 30) for _ in range(3))
        return [f'(node {nid} (box {f(a)} {f(b)} {f(c)}) {IC})'], dict(kind=kind, dims=(a, b, c))
    if kind == 'cylinder':
        r, h = rng.uniform(2, 15), rng.uniform(4, 30)
        return [f'(node {nid} (cylinder {f(r)} {f(h)}) {IC})'], dict(kind=kind, r=r, h=h)
    if kind == 'cone':
        r, h = rng.uniform(2, 15), rng.uniform(4, 30)
        return [f'(node {nid} (cone {f(r)} {f(h)}) {IC})'], dict(kind=kind, r=r, h=h)
    if kind == 'sphere':
        r = rng.uniform(2, 15)
        return [f'(node {nid} (sphere {f(r)}) {IC})'], dict(kind=kind, r=r)
    if kind == 'torus':
        big = rng.uniform(6, 18)
        return [f'(node {nid} (torus {f(big)} {f(rng.uniform(1, big * 0.6))}) {IC})'], dict(kind=kind, R=big)
    if kind == 'revolve':
        r0, r1 = rng.uniform(1, 5), rng.uniform(8, 18)
        z1 = rng.uniform(6, 25)
        rm = rng.uniform(r0 + 1, r1 + 4)
        p = (f'(region (path {f(r0)} 0.0 (line {f(r1)} 0.0) (line {f(rm)} {f(z1 * 0.5)}) (arc {f((rm + r1) / 2)} {f(z1 * 0.75)} '
             f'{f(math.hypot(rm - (rm + r1) / 2, z1 * 0.25))} {f(r1)} {f(z1)} ccw) (line {f(r0)} {f(z1)}) (line {f(r0)} 0.0)))')
        return [f'(node {nid} (revolve {p}) {IC})'], dict(kind=kind)
    n = rng.randint(3, 7)
    rad = rng.uniform(5, 15)
    pts = [(rad * math.cos(2 * math.pi * k / n + rng.uniform(-0.2, 0.2)), rad * math.sin(2 * math.pi * k / n + rng.uniform(-0.2, 0.2))) for k in range(n)]
    path = f'(path {f(pts[0][0])} {f(pts[0][1])} ' + ' '.join(f'(line {f(x)} {f(y)})' for x, y in pts[1:] + [pts[0]]) + ')'
    return [f'(node {nid} (prism 0.0 {f(rng.uniform(4, 25))} (region {path})) {IC})'], dict(kind='prism')


def place(rng, src, base, mode):
    e, cur = [], src
    if mode == 'general':
        for ax in rng.sample(['x', 'y', 'z'], 3):
            e.append(f'(node {base} (rotate {cur} {ax} {f(rng.uniform(-180, 180))}) {IS})')
            cur, base = base, base + 1
        off = [rng.uniform(-12, 12) for _ in range(3)]
    elif mode == 'axis':
        for ax in rng.sample(['x', 'y', 'z'], rng.randint(1, 2)):
            e.append(f'(node {base} (rotate {cur} {ax} {f(rng.choice([45.0, 90.0, 180.0, -90.0, 30.0]))}) {IS})')
            cur, base = base, base + 1
        off = [rng.choice([0.0, 2.5, -5.0, 7.0]) for _ in range(3)]
    elif mode == 'coplanar':
        off = [rng.choice([0.0, 5.0]), rng.choice([0.0, -3.0]), 0.0]
    elif mode == 'tangent':
        off = [0.0, 0.0, rng.choice([0.0, 10.0])]
    elif mode == 'coaxial':
        off = [0.0, 0.0, rng.uniform(-8, 8)]
    elif mode == 'seam':
        e.append(f'(node {base} (rotate {cur} z {f(rng.choice([0.0, 180.0, 90.0]))}) {IS})')
        cur, base = base, base + 1
        off = [rng.uniform(-6, 6), 0.0, rng.uniform(-6, 6)]
    else:
        off = [rng.uniform(-1e-6, 1e-6) + 20.0, 0.0, 0.0]
    e.append(f'(node {base} (move {cur} {f(off[0])} {f(off[1])} {f(off[2])} 0) {IS})')
    return e, base


def run(*args, timeout=1800):
    t0 = time.time()
    try:
        p = subprocess.run([BIN] + list(args), capture_output=True, text=True, timeout=timeout)
        return p.stdout + p.stderr, time.time() - t0
    except subprocess.TimeoutExpired:
        return 'TIMEOUT', time.time() - t0


def nline(out, n):
    m = re.search(rf'^node {n}: (.*)$', out, re.M)
    return m.group(1) if m else ''


def vol(line):
    m = re.search(r'volume=\[(\S+), (\S+)\]', line)
    return (float(m.group(1)), float(m.group(2))) if m else None


def why(line):
    m = re.search(r'why: ([^|]*)', line)
    k = re.search(r'\[k1 reason (\d+)\]', line)
    return ((m.group(1).strip()[:90] if m else line[:90]) + (f' [k1 {k.group(1)}]' if k else '')).strip()


def occt_volume(path):
    from build123d import import_step
    from OCP.BRepGProp import BRepGProp
    from OCP.GProp import GProp_GProps
    g = GProp_GProps()
    BRepGProp.VolumeProperties_s(import_step(path).wrapped, g, 1e-9)
    return g.Mass()


def one(seed):
    rng = random.Random(seed)
    ka, kb = rng.choice(KINDS), rng.choice(KINDS)
    mode = rng.choice(MODES)
    ea, ia = shape(rng, 1, ka)
    eb, ib = shape(rng, 2, kb)
    pe, bnode = place(rng, 2, 10, mode)
    d = f'{WORK}/c{seed}.bcd'
    run(d, 'new')
    out, dt0 = run(d, 'apply', *ea, *eb, *pe)
    rec = dict(seed=seed, a=ka, b=kb, mode=mode, ok_base='committed' in out)
    va, vb = vol(nline(out, 1)), vol(nline(out, bnode))
    rec['va'], rec['vb'] = va, vb
    res = {}
    for k, op in enumerate(('union', 'intersection', 'difference')):
        nid = 100 + k
        ed = f'(node {nid} ({op} 1 {bnode}) (intent {INTENT[op]} any any any any))'
        o, dt = run(d, 'apply', ed)
        ln = nline(o, nid)
        mis = 'declared material' in ln
        if mis:
            mm = re.search(r'measured material=(\w+)', ln)
            o, dt2 = run(d, 'apply', ed.replace(f'intent {INTENT[op]}', f'intent {mm.group(1) if mm else "same"}'))
            dt += dt2
            ln = nline(o, nid)
        r = dict(ok='committed' in o, s=round(dt, 2), intent_mismatch=mis)
        if o == 'TIMEOUT':
            r['why'] = 'TIMEOUT'
        elif not r['ok']:
            r['why'] = why(ln)
        else:
            r['v'] = vol(ln)
        res[op] = r
    rec['ops'] = res
    u, i, df = res['union'], res['intersection'], res['difference']
    if va and vb and u.get('v') and i.get('v'):
        lo = u['v'][0] + i['v'][0]
        hi = u['v'][1] + i['v'][1]
        a = va[0] + vb[0]
        b = va[1] + vb[1]
        sc = 1e-9 * max(1.0, b)
        rec['id_ui'] = bool(lo - sc <= b and a <= hi + sc)
    if va and i.get('v') and df.get('v'):
        lo, hi = df['v'][0] + i['v'][0], df['v'][1] + i['v'][1]
        sc = 1e-9 * max(1.0, va[1])
        rec['id_di'] = bool(lo - sc <= va[1] and va[0] <= hi + sc)
    if OCCT and u.get('v'):
        sp = f'{WORK}/c{seed}_u.stp'
        o, _ = run(d, 'step', '100', sp)
        try:
            ov = occt_volume(sp)
            lo, hi = u['v']
            rec['occt_v'] = ov
            rec['occt_ok'] = bool(abs(ov - 0.5 * (lo + hi)) <= 1e-7 * max(1.0, hi) + (hi - lo))
        except Exception as ex:
            rec['occt_err'] = str(ex)[:120]
            rec['occt_ok'] = False
    for p in (d, f'{WORK}/c{seed}_u.stp'):
        try:
            os.remove(p)
        except OSError:
            pass
    return rec


def summarize(recs):
    ops = [(r, op, r['ops'][op]) for r in recs if r['ok_base'] for op in r['ops']]
    tot = len(ops)
    ok = sum(1 for _, _, o in ops if o['ok'])
    why = {}
    for r, op, o in ops:
        if not o['ok']:
            why[o['why']] = why.get(o['why'], 0) + 1
    by = {}
    for r, op, o in ops:
        k = r['mode']
        b = by.setdefault(k, [0, 0])
        b[0] += 1
        b[1] += o['ok']
    times = sorted(o['s'] for _, _, o in ops)
    idf = [r for r in recs if r.get('id_ui') is False or r.get('id_di') is False]
    occ = [r for r in recs if 'occt_ok' in r]
    return dict(cases=len(recs), base_ok=sum(r['ok_base'] for r in recs), ops=tot, committed=ok,
                commit_rate=round(ok / tot, 4) if tot else None,
                refusals=dict(sorted(why.items(), key=lambda kv: -kv[1])),
                by_mode={k: dict(ops=v[0], committed=v[1]) for k, v in by.items()},
                identity_checked=sum(1 for r in recs if 'id_ui' in r or 'id_di' in r),
                identity_violations=[r['seed'] for r in idf],
                occt_checked=len(occ), occt_mismatch=[r['seed'] for r in occ if not r['occt_ok']],
                seconds_median=times[len(times) // 2] if times else None,
                seconds_p95=times[int(len(times) * 0.95)] if times else None,
                seconds_max=times[-1] if times else None,
                intent_mismatches=sum(1 for _, _, o in ops if o['intent_mismatch']))


if __name__ == '__main__':
    n, jobs, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    s0 = int(sys.argv[4]) if len(sys.argv) > 4 else 1
    os.makedirs(WORK, exist_ok=True)
    t0 = time.time()
    with ProcessPoolExecutor(jobs) as ex:
        recs = list(ex.map(one, range(s0, s0 + n)))
    rep = dict(binary=BIN, seconds=round(time.time() - t0, 1), summary=summarize(recs), cases=recs)
    json.dump(rep, open(out, 'w'), indent=1)
    print(json.dumps(rep['summary'], indent=1))
