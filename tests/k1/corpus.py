import hashlib
import json
import math
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, 'corpus-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-corpus-k1'
RESULTS = []

IC = '(intent create any any any any)'
IA = '(intent add any any any any)'
IS = '(intent same any any any any)'
ID = '(intent remove any any any any)'

BOX = f'(node 1 (box 10 10 10) {IC})'
PRISM = lambda i, z0, z1, x, y, r: f'(node {i} (prism {z0:g} {z1:g} (region (circle {x:g} {y:g} {r:g}))) {IC})'


def wsl(*args, timeout=900):
    t = time.time()
    env = dict(os.environ, MSYS_NO_PATHCONV='1', BEND_NO_TELEMETRY='1')
    r = subprocess.run([*args], capture_output=True, text=True, timeout=timeout, env=env)
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def record(name, ok, artifacts=(), **checks):
    RESULTS.append(dict(name=name, ok=bool(ok), checks={k: (list(v) if isinstance(v, tuple) else v)
                                                        for k, v in checks.items()},
                        artifacts={a: sha(os.path.join(WORK, a)) for a in artifacts
                                   if os.path.exists(os.path.join(WORK, a))}))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in checks.items() if not v},
          flush=True)


def contains(iv, x):
    return iv is not None and iv[0] <= x <= iv[1]


def iv_add(a, b):
    return (a[0] + b[0], a[1] + b[1]) if a and b else None


def iv_overlap(a, b):
    return a is not None and b is not None and not (a[1] < b[0] or b[1] < a[0])


def vol(out, node):
    m = re.search(rf'node {node}: ok .*?volume=\[([^,]+), ([^\]]+)\]', out)
    return (float(m.group(1)), float(m.group(2))) if m else None


def genus(out, node):
    m = re.search(rf'node {node}: ok .*?genus=(\d+)', out)
    return int(m.group(1)) if m else None


def check_honest(out):
    ls = [ln for ln in out.strip().splitlines() if ln]
    if len(ls) == 1 and ls[0].startswith('ok:'):
        return ('ok', ls)
    bad = [ln for ln in ls if not (ln.startswith('face-check-unsupported') or
                                   ln.startswith('face-face-uncertain') or
                                   ln.startswith('orientation-uncertain'))]
    orient = sum(1 for ln in ls if ln.startswith('orientation-uncertain'))
    if ls and not bad and orient <= 1:
        return ('prismatic' if orient == 0 else 'ruled', ls)
    return ('BAD', ls)


def step_vol(design, node, tag):
    from build123d import import_step
    cli(design, 'step', str(node), f'{WORK}/{tag}.stp')
    s = import_step(f'{WORK}/{tag}.stp') if os.path.exists(f'{WORK}/{tag}.stp') else None
    solids = s.solids() if s is not None else []
    faces = s.faces() if s is not None else []
    vv = solids[0].volume if len(solids) == 1 else None
    return len(solids), len(faces), vv


def replay(design, nodes):
    sh, _ = cli(design, 'show')
    lines = [ln for ln in sh.splitlines() if ln.startswith('(node ')]
    cli(design.replace('.bcd', '2.bcd'), 'new')
    out2, _ = cli(design.replace('.bcd', '2.bcd'), 'apply', *lines)
    e2, _ = cli(design.replace('.bcd', '2.bcd'), 'eval')
    return out2, e2, len(lines) == nodes


def reopen_vol(design, node, tag):
    cli(design, 'archive', str(node), f'{WORK}/{tag}.bin')
    ro, _ = wsl(BIN, 'geom', 'reopen', f'{WORK}/{tag}.bin', '-v')
    rm = re.search(r'volume=\[([^,]+), ([^\]]+)\]', ro)
    return (float(rm.group(1)), float(rm.group(2))) if rm else None


def triple(design, a_nodes, b_nodes, ia, ib, hunion, hinter, hdiff):
    out, dt = fresh(design, *a_nodes, *b_nodes)
    n0 = len(a_nodes) + len(b_nodes)
    u, i, d = n0 + 1, n0 + 2, n0 + 3
    out2, _ = cli(design, 'apply',
                  f'(node {u} (union {ia} {ib}) {IA})',
                  f'(node {i} (intersection {ia} {ib}) {IS})',
                  f'(node {d} (difference {ia} {ib}) {ID})')
    out = out2
    ev, _ = cli(design, 'eval')
    va = vol(ev, ia)
    vb = vol(ev, ib)
    vu = vol(ev, u)
    vi = vol(ev, i)
    vd = vol(ev, d)
    ident = iv_overlap(iv_add(vu, vi), iv_add(va, vb))
    return dict(out=out, ev=ev, va=va, vb=vb, vu=vu, vi=vi, vd=vd, u=u, i=i, d=d,
                ident=ident, seconds=dt)


def finish(tag, design, r, node, hand, isn=0, genus_exp=0):
    ev = r['ev']
    kv = vol(ev, node)
    ref = hand if hand is not None else (kv[0] + kv[1]) / 2 if kv else None
    chk, _ = cli(design, 'check', str(node))
    ch = check_honest(chk)[0]
    nsol, nfaces, vv = step_vol(design, node, tag)
    out2, e2, nlen = replay(design, isn)
    riv = reopen_vol(design, node, tag)
    checks = dict(committed='committed' in r['out'], proof='proof: k1-crossing-certified' in r['out'],
                  hand=contains(kv, hand) if hand is not None else kv is not None,
                  check=ch != 'BAD', genus=genus(ev, node) == genus_exp,
                  step=nsol == 1 and vv is not None and ref is not None and
                  abs(vv - ref) / ref < 1e-6,
                  replay='committed' in out2 and e2 == ev and nlen,
                  reopen=riv is not None and (contains(riv, hand) if hand is not None
                                              else iv_overlap(riv, kv)))
    return checks, dict(nfaces=nfaces, stp_volume=vv, check_verdict=ch)


def bore_eq():
    t = triple('be.bcd', [BOX], [PRISM(2, -5, 15, 5, 5, 2)], 1, 2,
               1000 + 40 * math.pi, 40 * math.pi, 1000 - 40 * math.pi)
    cx, _ = cli('be.bcd', 'apply', PRISM(6, -5, 15, 5, 5, 2),
                '(node 7 (rotate 6 y 90) (intent same 0 0 1 0))',
                '(node 8 (move 7 0 0 10 0) (intent same 0 0 1 0))',
                f'(node 9 (difference {t["d"]} 8) {ID})')
    ri, _ = cli('be.bcd', 'apply', f'(node 10 (intersection {t["d"]} 8) {IS})')
    ru, _ = cli('be.bcd', 'apply', f'(node 11 (union {t["d"]} 8) {IA})')
    ev2, _ = cli('be.bcd', 'eval')
    hand9 = 1000 - 80 * math.pi + 128 / 3
    r2 = dict(out=t['out'] + cx, ev=ev2)
    checks, info = finish('be', 'be.bcd', r2, 9, hand9, 9, 3)
    checks.update(hunion=contains(t['vu'], 1000 + 40 * math.pi),
                  hinter=contains(t['vi'], 40 * math.pi), ident=t['ident'],
                  cross='committed' in cx,
                  inter_refused='non-manifold-result' in ri and 'committed' not in ri,
                  union_refused='non-manifold-result' in ru and 'committed' not in ru)
    record('bore.eq', all(checks.values()), artifacts=('be.bcd', 'be.stp', 'be.bin'),
           seconds=t['seconds'], **checks, **info)


def bore_uneq():
    t = triple('bu.bcd', [BOX], [PRISM(2, -5, 15, 5, 5, 1.5)], 1, 2,
               1000 + 22.5 * math.pi, 22.5 * math.pi, 1000 - 22.5 * math.pi)
    out, ev = t['out'], t['ev']
    cx, _ = cli('bu.bcd', 'apply', PRISM(6, -5, 15, 5, 5, 1),
                '(node 7 (rotate 6 y 90) (intent same 0 0 1 0))',
                '(node 8 (move 7 0 0 10 0) (intent same 0 0 1 0))',
                f'(node 9 (difference {t["d"]} 8) {ID})',
                f'(node 10 (intersection {t["d"]} 8) {IS})',
                f'(node 11 (union {t["d"]} 8) {IA})')
    ev2, _ = cli('bu.bcd', 'eval')
    vd9, vi10, vu11, vd5, vb8 = (vol(ev2, n) for n in (9, 10, 11, t['d'], 8))
    ident2 = iv_overlap(iv_add(vu11, vi10), iv_add(vd5, vb8))
    r2 = dict(out=t['out'] + cx, ev=ev2)
    checks, info = finish('bu', 'bu.bcd', r2, t['d'], 1000 - 22.5 * math.pi, 11, 1)
    checks.update(hunion=contains(t['vu'], 1000 + 22.5 * math.pi),
                  hinter=contains(t['vi'], 22.5 * math.pi), ident=t['ident'], ident2=ident2,
                  cross='committed' in cx and vd9 is not None and vi10 is not None)
    record('bore.uneq', all(checks.values()), artifacts=('bu.bcd', 'bu.stp', 'bu.bin'),
           seconds=t['seconds'], **checks, **info)


def offaxis():
    t = triple('oa.bcd', [BOX], [PRISM(2, -5, 15, 2, 3, 1)], 1, 2,
               1000 + 10 * math.pi, 10 * math.pi, 1000 - 10 * math.pi)
    checks, info = finish('oa', 'oa.bcd', t, t['d'], 1000 - 10 * math.pi, 5, 1)
    checks.update(hunion=contains(t['vu'], 1000 + 10 * math.pi),
                  hinter=contains(t['vi'], 10 * math.pi), ident=t['ident'])
    record('offaxis', all(checks.values()), artifacts=('oa.bcd', 'oa.stp', 'oa.bin'),
           seconds=t['seconds'], **checks, **info)


def fig8port():
    a = [PRISM(1, 0, 10, 0, 0, 3), PRISM(2, 0, 10, 0, 0, 3), '(node 3 (move 2 4 0 0 0) (intent same 0 0 1 0))',
         f'(node 4 (union 1 3) {IA})']
    b = [PRISM(5, -5, 15, 0, 0, 2), '(node 6 (rotate 5 y 90) (intent same 0 0 1 0))',
         '(node 7 (move 6 0 4 5 0) (intent same 0 0 1 0))']
    t = triple('fp.bcd', a, b, 4, 7, None, None, None)
    out, ev = t['out'], t['ev']
    va4 = vol(ev, 4)
    hand_a = 503.5370360439269
    checks, info = finish('fp', 'fp.bcd', t, t['u'], None, 10)
    checks.update(chamber=contains(va4, hand_a), ident=t['ident'],
                  union_ok=t['vu'] is not None and t['vi'] is not None and t['vd'] is not None)
    record('fig8port', all(checks.values()), artifacts=('fp.bcd', 'fp.stp', 'fp.bin'),
           seconds=t['seconds'], chamber_vol=va4, union_vol=t['vu'], **checks, **info)


def cbore():
    h_shank = 1000 - 10 * math.pi
    h_final = 1000 - 22 * math.pi
    out, dt = fresh('cb.bcd', BOX, PRISM(2, -5, 15, 5, 5, 1),
                    f'(node 3 (difference 1 2) {ID})',
                    f'(node 6 (intersection 1 2) {IS})',
                    PRISM(4, 6, 14, 5, 5, 2),
                    f'(node 5 (difference 3 4) {ID})',
                    f'(node 7 (intersection 3 4) {IS})')
    ev, _ = cli('cb.bcd', 'eval')
    v1, v2, v3, v4, v5, v6, v7 = (vol(ev, n) for n in (1, 2, 3, 4, 5, 6, 7))
    r = dict(out=out, ev=ev)
    checks, info = finish('cb', 'cb.bcd', r, 5, h_final, 7, 1)
    checks.update(shank=contains(v3, h_shank), inter1=contains(v6, 10 * math.pi),
                  inter2=contains(v7, 12 * math.pi),
                  ident1=iv_overlap(iv_add(v3, v6), v1),
                  ident2=iv_overlap(iv_add(v5, v7), v3))
    record('cbore', all(checks.values()), artifacts=('cb.bcd', 'cb.stp', 'cb.bin'),
           seconds=dt, **checks, **info)


def oring():
    h2 = 1000 - 32 * math.pi
    h3 = 1000 - 14 * math.pi
    h4 = 1000 - 42 * math.pi
    out, dt = fresh('or.bcd', BOX,
                    f'(node 2 (pocket 1 (face 1 0 top) 2 (region (circle 5 5 4))) {ID})',
                    f'(node 3 (pad 2 (face 2 0 top) 2 (region (circle 5 5 3))) {IA})',
                    f'(node 4 (pocket 3 (face 3 0 top) 7 (region (circle 5 5 2))) {ID})')
    ev, _ = cli('or.bcd', 'eval')
    v2, v3, v4 = (vol(ev, n) for n in (2, 3, 4))
    chk, _ = cli('or.bcd', 'check', '4')
    ch = check_honest(chk)[0]
    nsol, nfaces, vv = step_vol('or.bcd', 4, 'or')
    out2, e2, nlen = replay('or.bcd', 4)
    riv = reopen_vol('or.bcd', 4, 'or')
    checks = dict(committed='committed' in out, groove=contains(v2, h2),
                  island=contains(v3, h3), cavity=contains(v4, h4), check=ch != 'BAD',
                  genus=genus(ev, 4) == 0,
                  step=nsol == 1 and vv is not None and abs(vv - h4) / h4 < 1e-6,
                  replay='committed' in out2 and e2 == ev and nlen,
                  reopen=riv is not None and contains(riv, h4))
    record('oring', all(checks.values()), artifacts=('or.bcd', 'or.stp', 'or.bin'),
           seconds=dt, nfaces=nfaces, stp_volume=vv, check_verdict=ch, **checks)


def main():
    os.makedirs(WORK, exist_ok=True)
    bore_eq()
    bore_uneq()
    offaxis()
    fig8port()
    cbore()
    oring()
    json.dump(RESULTS, open(OUT, 'w'), indent=1)
    n = sum(1 for r in RESULTS if r['ok'])
    print(f'{n}/{len(RESULTS)} corpus members hold')
    sys.exit(0 if n == len(RESULTS) else 1)


if __name__ == '__main__':
    main()
