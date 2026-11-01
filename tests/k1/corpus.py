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


def csink():
    tool = '(node 2 (revolve (region (path 0 5 (line 1 5) (line 4 11) (line 0 11)))) (intent create any any any any))'
    t = triple('cs.bcd', [BOX], [tool, '(node 3 (move 2 5 5 0 0) (intent same 0 0 1 0))'], 1, 3,
               1044.2440965380563, 87.70279491271505, 912.297205087285)
    cx, _ = cli('cs.bcd', 'apply', PRISM(7, -5, 15, 5, 5, 1.5), f'(node 8 (difference {t["d"]} 7) {ID})')
    ev2, _ = cli('cs.bcd', 'eval')
    r2 = dict(out=t['out'] + cx, ev=ev2)
    checks, info = finish('cs', 'cs.bcd', r2, 8, 874.8598926320066, 8, 1)
    checks.update(hunion=contains(t['vu'], 1044.2440965380563), hinter=contains(t['vi'], 87.70279491271505),
                  hdiff=contains(t['vd'], 912.297205087285), ident=t['ident'], bore='committed' in cx)
    record('csink', all(checks.values()), artifacts=('cs.bcd', 'cs.stp', 'cs.bin'), seconds=t['seconds'],
           **checks, **info)


def frames(design, node):
    out, _ = cli(design, 'faces', str(node), '-f')
    fr = {}
    for ln in out.splitlines():
        m = re.match(r'(\S+) plane .*frame o=\(([^)]*)\) x=\(([^)]*)\) y=\(([^)]*)\) n=\(([^)]*)\)', ln)
        if m:
            fr[m.group(1)] = [tuple(float(v) for v in m.group(k).split(',')) for k in (2, 3, 4, 5)]
    return fr


def local(fr, p):
    o, x, y, n = fr
    d = tuple(p[i] - o[i] for i in range(3))
    return sum(d[i] * x[i] for i in range(3)), sum(d[i] * y[i] for i in range(3))


def wall_with(fr, normal):
    for nm, f in fr.items():
        if all(abs(f[3][i] - normal[i]) < 1e-12 for i in range(3)):
            return nm, f
    return None, None


def sidefeat():
    out, dt = fresh('sf.bcd', BOX)
    fr = frames('sf.bcd', 1)
    nm, f = wall_with(fr, (1.0, 0.0, 0.0))
    u, v = local(f, (10.0, 5.0, 5.0)) if f else (0.0, 0.0)
    o2, _ = cli('sf.bcd', 'apply',
                f'(node 2 (pocket 1 (face 1 {nm}) 3 (region (circle {u!r} {v!r} 2))) {ID})')
    fr2 = frames('sf.bcd', 2)
    nm2, f2 = wall_with(fr2, (0.0, -1.0, 0.0))
    u2, v2 = local(f2, (5.0, 0.0, 5.0)) if f2 else (0.0, 0.0)
    o3, _ = cli('sf.bcd', 'apply',
                f'(node 3 (pad 2 (face 2 {nm2}) 4 (region (circle {u2!r} {v2!r} 1.5))) {IA})')
    nm3, f3 = wall_with(fr2, (0.0, 0.0, 1.0))
    u3, v3 = local(f3, (2.0, 8.0, 10.0)) if f3 else (0.0, 0.0)
    o4, _ = cli('sf.bcd', 'apply',
                f'(node 4 (pocket 3 (face 3 {nm3}) through (region (circle {u3!r} {v3!r} 1))) {ID})')
    ev, _ = cli('sf.bcd', 'eval')
    h2 = 1000 - 12 * math.pi
    h3 = h2 + 9 * math.pi
    h4 = h3 - 10 * math.pi
    r = dict(out=out + o2 + o3 + o4, ev=ev)
    checks, info = finish('sf', 'sf.bcd', r, 4, h4, 4, 1)
    checks.update(frame=nm is not None and nm2 is not None and nm3 is not None,
                  side_pocket=contains(vol(ev, 2), h2), side_pad=contains(vol(ev, 3), h3),
                  thru=contains(vol(ev, 4), h4),
                  missing='face-not-found' in cli('sf.bcd', 'apply', f'(node 5 (pad 4 (face 4 n9.c0.top) 1 (region (circle 1 1 0.5))) {IA})')[0])
    record('sidefeat', all(checks.values()), artifacts=('sf.bcd', 'sf.stp', 'sf.bin'), seconds=dt,
           **checks, **info)


def chamfer_edges():
    out, dt = fresh('ch.bcd', '(node 1 (box 20 20 10) (intent create any any any any))',
                    f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 10 10 3))) {ID})')
    fr = frames('ch.bcd', 2)
    nm, f = wall_with(fr, (0.0, 0.0, 1.0))
    u, v = local(f, (10.0, 10.0, 10.0)) if f else (0.0, 0.0)
    o3, _ = cli('ch.bcd', 'apply', f'(node 3 (chamfer 2 (face 2 {nm}) (circle {u!r} {v!r} 3) 1) {ID})')
    o4, _ = cli('ch.bcd', 'apply', '(node 4 (cylinder 2 6) (intent create any any any any))',
                '(node 5 (move 4 4 4 10 0) (intent same 0 0 1 0))', f'(node 6 (union 3 5) {IA})')
    fr6 = frames('ch.bcd', 6)
    tops = [(k, f6) for k, f6 in fr6.items() if abs(f6[3][2] - 1) < 1e-12 and abs(f6[0][2] - 16) < 1e-9]
    nm6, f6 = tops[0] if tops else (None, None)
    u6, v6 = local(f6, (4.0, 4.0, 16.0)) if f6 else (0.0, 0.0)
    o7, _ = cli('ch.bcd', 'apply', f'(node 7 (chamfer 6 (face 6 {nm6}) (circle {u6!r} {v6!r} 2) 0.5) {ID})')
    ev, _ = cli('ch.bcd', 'eval')
    h2 = 4000 - 90 * math.pi
    h3 = h2 - math.pi * (1 * (3 * 3 + 3 * 4 + 4 * 4) / 3 - 9)
    h6 = h3 + 24 * math.pi
    h7 = h6 - math.pi * (0.5 * 4 - 0.5 * (4 + 2 * 1.5 + 1.5 * 1.5) / 3)
    r = dict(out=out + o3 + o4 + o7, ev=ev)
    checks, info = finish('ch', 'ch.bcd', r, 7, h7, 7, 1)
    checks.update(hole=contains(vol(ev, 3), h3), pad=contains(vol(ev, 6), h6), boss=contains(vol(ev, 7), h7),
                  named=nm is not None and nm6 is not None)
    record('chamfer', all(checks.values()), artifacts=('ch.bcd', 'ch.stp', 'ch.bin'), seconds=dt, **checks, **info)


def edgechamfer():
    out, dt = fresh('ec.bcd', BOX)
    fr = frames('ec.bcd', 1)
    top, _ = wall_with(fr, (0.0, 0.0, 1.0))
    px, _ = wall_with(fr, (1.0, 0.0, 0.0))
    bot, _ = wall_with(fr, (0.0, 0.0, -1.0))
    my, _ = wall_with(fr, (0.0, -1.0, 0.0))
    o2, _ = cli('ec.bcd', 'apply', f'(node 2 (chamfer 1 (edge 1 {top} {px}) 1) {ID})')
    o3, _ = cli('ec.bcd', 'apply', f'(node 3 (chamfer 2 (edge 2 {bot} {my}) 2) {ID})')
    ev, _ = cli('ec.bcd', 'eval')
    r = dict(out=out + o2 + o3, ev=ev)
    checks, info = finish('ec', 'ec.bcd', r, 3, 975.0, 3, 0)
    checks.update(first=contains(vol(ev, 2), 995.0), second=contains(vol(ev, 3), 975.0))
    record('edgechamfer', all(checks.values()), artifacts=('ec.bcd', 'ec.stp', 'ec.bin'), seconds=dt, **checks, **info)


def g3limits():
    l1, _ = fresh('l1.bcd', '(node 1 (box 20 20 10) (intent create any any any any))',
                  f'(node 2 (pocket 1 (face 1 0 top) 3 (region (circle 10 10 2))) {ID})',
                  f'(node 3 (pocket 2 (face 1 0 bottom) 3 (region (circle 10 10 3))) {ID})')
    e1, _ = cli('l1.bcd', 'eval')
    l3, _ = fresh('l3.bcd', '(node 1 (prism 0 20 (region (circle 0 0 2.5))) (intent create any any any any))',
                  '(node 2 (prism 20 25 (region (circle 0 0 4.25))) (intent create any any any any))',
                  f'(node 3 (union 1 2) {IA})')
    fr3 = frames('l3.bcd', 3)
    tops = [(k, f3) for k, f3 in fr3.items() if abs(f3[3][2] - 1) < 1e-12 and abs(f3[0][2] - 25) < 1e-9]
    nm3, f3 = tops[0] if tops else (None, None)
    s = 4 / math.sqrt(3)
    hexpts = [(s * math.cos(k * math.pi / 3), s * math.sin(k * math.pi / 3)) for k in range(6)]
    loc = [local(f3, (x, y, 25.0)) for x, y in hexpts] if f3 else [(0, 0)] * 6
    path = f'(path {loc[0][0]!r} {loc[0][1]!r} ' + ' '.join(f'(line {a!r} {b!r})' for a, b in loc[1:]) + ')'
    o4, _ = cli('l3.bcd', 'apply', f'(node 4 (pocket 3 (face 3 {nm3}) 3 (region {path})) {ID})')
    e3, _ = cli('l3.bcd', 'eval')
    l4, _ = fresh('l4.bcd', '(node 1 (box 20 20 10) (intent create any any any any))',
                  f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 10 10 2))) {ID})',
                  f'(node 3 (pocket 2 (face 1 0 top) 1 (region (circle 10 10 5) (circle 10 10 4))) {ID})')
    e4, _ = cli('l4.bcd', 'eval')
    hexa = 1.5 * math.sqrt(3) * s * s
    checks = dict(l1=contains(vol(e1, 3), 4000 - 39 * math.pi),
                  l3=contains(vol(e3, 4), 125 * math.pi + 90.3125 * math.pi - 3 * hexa),
                  l4=contains(vol(e4, 3), 4000 - 40 * math.pi - 9 * math.pi))
    record('g3limits', all(checks.values()), **checks)


def fig8(r):
    h = math.sqrt(r * r - 49)
    return (f'(path 29 {20 + h!r} (arc 22 20 {r!r} 29 {20 - h!r} ccw) '
            f'(arc 36 20 {r!r} 29 {20 + h!r} ccw))')


def fig8_area(r):
    return 2 * math.pi * r * r - (2 * r * r * math.acos(7 / r) - 7 * math.sqrt(4 * r * r - 196))


def port_vol():
    xs, ws = gauss_legendre(64)
    return sum(w * 18 * math.cos(t) ** 2 * (20 - math.sqrt(64 - 9 * math.sin(t) ** 2)) * math.pi / 2
               for t, w in ((x * math.pi / 2, w) for x, w in zip(xs, ws)))


def gauss_legendre(n):
    xs, ws = [], []
    for i in range(1, n + 1):
        x = math.cos(math.pi * (i - 0.25) / (n + 0.5))
        for _ in range(100):
            p0, p1 = 1.0, x
            for k in range(2, n + 1):
                p0, p1 = p1, ((2 * k - 1) * x * p1 - (k - 1) * p0) / k
            dp = n * (x * p1 - p0) / (x * x - 1)
            dx = p1 / dp
            x -= dx
            if abs(dx) < 1e-16:
                break
        xs.append(x)
        ws.append(2 / ((1 - x * x) * dp * dp))
    return xs, ws


def g2pump():
    out, dt = fresh('gp.bcd', '(node 1 (box 60 40 20) (intent create any any any any))',
                    f'(node 2 (pocket 1 (face 1 0 top) 10 (region {fig8(8)})) {ID})',
                    f'(node 3 (pocket 2 (face 1 0 top) 1.5 (region {fig8(11)} {fig8(9.5)})) {ID})')
    fr = frames('gp.bcd', 3)
    nm, f = wall_with(fr, (0.0, -1.0, 0.0))
    u, v = local(f, (22.0, 0.0, 15.0)) if f else (0.0, 0.0)
    o4, _ = cli('gp.bcd', 'apply',
                f'(node 4 (pocket 3 (face 3 {nm}) 20 (region (circle {u!r} {v!r} 3))) {ID})')
    ev, _ = cli('gp.bcd', 'eval')
    h2 = 48000 - 10 * fig8_area(8)
    h3 = h2 - 1.5 * (fig8_area(11) - fig8_area(9.5))
    h4 = h3 - port_vol()
    r = dict(out=out + o4, ev=ev)
    checks, info = finish('gp', 'gp.bcd', r, 4, h4, 4, 1)
    checks.update(chamber=contains(vol(ev, 2), h2), groove=contains(vol(ev, 3), h3), wall=nm is not None)
    record('g2pump', all(checks.values()), artifacts=('gp.bcd', 'gp.stp', 'gp.bin'), seconds=dt,
           **checks, **info)


def lens(r1, r2, d):
    return math.pi * (r1 + r2 - d) ** 2 * (d * d + 2 * d * (r1 + r2) - 3 * (r1 - r2) ** 2) / (12 * d)


def spheres():
    hu, hi, hd = 1000 + 27 * math.pi, 175 * math.pi / 3, 1000 - 175 * math.pi / 3
    t = triple('sp.bcd', [BOX], [f'(node 2 (sphere 4) {IC})', '(node 3 (move 2 5 5 9 0) (intent same 0 0 1 0))'],
               1, 3, hu, hi, hd)
    checks, info = finish('sp', 'sp.bcd', t, t['d'], hd, t['d'])
    checks.update(hunion=contains(t['vu'], hu), hinter=contains(t['vi'], hi), ident=t['ident'])
    ball, _ = cli('sp.bcd', 'apply', PRISM(10, 0, 10, 20, 20, 3), f'(node 11 (sphere 3) {IC})',
                  '(node 12 (move 11 20 20 10 0) (intent same 0 0 1 0))', f'(node 13 (union 10 12) {IA})')
    ss, _ = cli('sp.bcd', 'apply', f'(node 20 (sphere 5) {IC})', f'(node 21 (sphere 3) {IC})',
                '(node 22 (move 21 0 0.3 4.5 0) (intent same 0 0 1 0))', f'(node 23 (intersection 20 22) {IS})',
                f'(node 24 (union 20 22) {IA})')
    ev, _ = cli('sp.bcd', 'eval')
    lz = lens(5, 3, math.sqrt(0.09 + 20.25))
    checks.update(ball=contains(vol(ev, 13), 108 * math.pi), lens=contains(vol(ev, 23), lz),
                  lens_union=contains(vol(ev, 24), 500 * math.pi / 3 + 36 * math.pi - lz))
    record('spheres', all(checks.values()), artifacts=('sp.bcd', 'sp.stp', 'sp.bin'), seconds=t['seconds'],
           ball_vol=vol(ev, 13), lens_vol=vol(ev, 23), **checks, **info)


def fil_hole(r, p):
    return 2 * math.pi * (p * p * (r + p / 2) - math.pi * p * p * (r + p) / 4 + p ** 3 / 3)


def fil_boss(r, p):
    return 2 * math.pi * (p * p * (r - p / 2) - math.pi * p * p * (r - p) / 4 - p ** 3 / 3)


def fillets():
    out, dt = fresh('fl.bcd', '(node 1 (box 20 20 10) (intent create any any any any))',
                    f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 10 10 3))) {ID})')
    fr = frames('fl.bcd', 2)
    nm, f = wall_with(fr, (0.0, 0.0, 1.0))
    u, v = local(f, (10.0, 10.0, 10.0)) if f else (0.0, 0.0)
    o3, _ = cli('fl.bcd', 'apply', f'(node 3 (fillet 2 (face 2 {nm}) (circle {u!r} {v!r} 3) 1) {ID})')
    o4, _ = cli('fl.bcd', 'apply', '(node 4 (cylinder 2 6) (intent create any any any any))',
                '(node 5 (move 4 4 4 10 0) (intent same 0 0 1 0))', f'(node 6 (union 3 5) {IA})')
    fr6 = frames('fl.bcd', 6)
    tops = [(k, f6) for k, f6 in fr6.items() if abs(f6[3][2] - 1) < 1e-12 and abs(f6[0][2] - 16) < 1e-9]
    nm6, f6 = tops[0] if tops else (None, None)
    u6, v6 = local(f6, (4.0, 4.0, 16.0)) if f6 else (0.0, 0.0)
    o7, _ = cli('fl.bcd', 'apply', f'(node 7 (fillet 6 (face 6 {nm6}) (circle {u6!r} {v6!r} 2) 0.5) {ID})')
    ev, _ = cli('fl.bcd', 'eval')
    h3 = 4000 - 90 * math.pi - fil_hole(3, 1)
    h6 = h3 + 24 * math.pi
    h7 = h6 - fil_boss(2, 0.5)
    r = dict(out=out + o3 + o4 + o7, ev=ev)
    checks, info = finish('fl', 'fl.bcd', r, 7, h7, 7, 1)
    checks.update(hole=contains(vol(ev, 3), h3), pad=contains(vol(ev, 6), h6), boss=contains(vol(ev, 7), h7),
                  named=nm is not None and nm6 is not None)
    record('fillets', all(checks.values()), artifacts=('fl.bcd', 'fl.stp', 'fl.bin'), seconds=dt, **checks, **info)


def volute_panel():
    band, back = open(os.path.join(HERE, 'volute.sx')).read().splitlines()[:2]
    out, dt = fresh('vp.bcd', f'(node 1 (prism -20 105 {band}) {IC})', f'(node 2 (prism -23 -20 {back}) {IC})', f'(node 3 (union 1 2) {IA})')
    ev, _ = cli('vp.bcd', 'eval')
    r = dict(out=out, ev=ev)
    checks, info = finish('vp', 'vp.bcd', r, 3, None, 3, 7)
    one = re.search(r'node 3: ok .*?solids=(\d+)', ev)
    checks.update(sum=iv_overlap(vol(ev, 3), iv_add(vol(ev, 1), vol(ev, 2))), fused=one is not None and one.group(1) == '1')
    record('volute_panel', all(checks.values()), artifacts=('vp.bcd', 'vp.stp', 'vp.bin'), seconds=dt, **checks, **info)


G4_SHROUD = ('(region (path 123.75 54.0 (line 227.0 54.0) (line 227.0 60.0) (line 134.75 60.0) (arc 134.75 66.0 6.0 128.75 66.0 cw) '
             '(line 128.75 78.0) (line 123.75 78.0) (line 123.75 54.0)))')


def keyway_cut():
    x = lambda t: t / 2 * math.sqrt(196 - t * t) + 98 * math.asin(t / 14)
    return (8 * 7.3 - ((x(4) - x(-4)) - 80)) * 62


def g4rotor():
    h0 = g4_footprint()
    h1 = g4_footprint((26.12230196103542, -107.21818437608977), (108.40827724624296, 78.76322380719142),
                      (216.19899366773637, -34.89310443621139), 203.37174316623742)
    out, dt = fresh('gr.bcd', f'(node 1 (revolve {G4_HUB}) {IC})', f'(node 2 (sweep (wall {G4_BLADE}) {G4_PROF}) {IC})',
                    f'(node 3 (union 1 2) {IA})', f'(node 4 (sweep (wall {G4_BLADE1}) {G4_PROF}) {IC})', f'(node 5 (union 3 4) {IA})',
                    f'(node 6 (revolve {G4_SHROUD}) {IC})', f'(node 7 (union 5 6) {IA})', f'(node 9 (box 8 7.3 80) {IC})',
                    '(node 8 (move 9 -4 10 -40 0) (intent same 0 0 1 0))', f'(node 10 (difference 7 8) {ID})')
    ev, _ = cli('gr.bcd', 'eval')
    v = {n: vol(ev, n) for n in (1, 2, 4, 6, 7, 10)}
    ok = all(v.values())
    sh = (v[1][0] + v[2][0] + v[4][0] + v[6][0] - 2 * (h0 + h1), v[1][1] + v[2][1] + v[4][1] + v[6][1] - 2 * (h0 + h1)) if ok else None
    kc = keyway_cut()
    r = dict(out=out, ev=ev)
    checks, info = finish('gr', 'gr.bcd', r, 10, None, 10, 3)
    checks.update(shroud=ok and iv_overlap(v[7], sh), keyway=ok and iv_overlap(v[10], (sh[0] - kc, sh[1] - kc)))
    record('g4rotor', all(checks.values()), artifacts=('gr.bcd', 'gr.stp', 'gr.bin'), seconds=dt, **checks, **info)


def frame_seam():
    frame = ('(region (path -5 -8 (line 15 -8) (line 15 15) (line -5 15) (line -5 -8)) '
             '(path 0 -3 (line 10 -3) (line 10 10) (line 0 10) (line 0 -3)))')
    out, dt = fresh('fs.bcd', BOX, f'(node 2 (box 10 10 3) {IC})', '(node 3 (move 2 0 0 -3 0) (intent same 0 0 1 0))',
                    f'(node 4 (union 1 3) {IA})', f'(node 5 (prism -12 -8 {frame}) {IC})',
                    '(node 6 (move 5 0 0 0 4) (intent same 0 0 1 1))', f'(node 7 (union 4 6) {IA})')
    ev, _ = cli('fs.bcd', 'eval')
    hand = 1300 + (20 * 23 - 10 * 13) * 4
    r = dict(out=out, ev=ev)
    checks, info = finish('fs', 'fs.bcd', r, 7, hand, 7, 0)
    checks.update(stack=contains(vol(ev, 4), 1300), frame=contains(vol(ev, 6), hand - 1300))
    record('frame_seam', all(checks.values()), artifacts=('fs.bcd', 'fs.stp', 'fs.bin'), seconds=dt, **checks, **info)


G4_HUB = ('(region (path 14.0 -32.0 (line 30.0 -32.0) (line 30.0 -14.0) (arc 36.0 -14.0 6.0 36.0 -8.0 cw) (line 227.0 -8.0) '
          '(line 227.0 0) (line 30.0 0) (arc 30.0 6.0 6.0 24.0 6.0 cw) (line 24.0 30.0) (line 14.0 30.0) (line 14.0 -32.0)))')
G4_BLADE = ('(path 135.72971219375614 1.004039703782334 (arc 134.0 0.0 2.0 132.27028780624386 -1.004039703782334 ccw) '
            '(arc -41.88515439275838 -102.0954115682855 201.36927152119628 152.46815310271845 -154.78673323083166 cw) '
            '(arc 154.39847053424393 -155.3100635410076 2.0 156.3287879657694 -155.83339385118353 ccw) '
            '(arc -41.88515439275838 -102.0954115682855 205.36927152119628 135.72971219375614 1.004039703782334 ccw))')
G4_PROF = ('(region (path -0.5 -1 (line 5.0 -1) (line 5.0 0) (arc 5.0 5.0 5.0 0 5.0 cw) (line 0 49.0) (arc 5.0 49.0 5.0 5.0 54.0 cw) '
           '(line 5.0 55.0) (line -0.5 55.0) (line -0.5 -1)))')


G4_BLADE1 = ('(path 109.21749463312395 80.59220363779905 (arc 108.40827724624296 78.76322380719142 2.0 107.59905985936197 76.9342439765838 ccw) '
             '(arc 26.12230196103542 -107.21818437608977 201.37174316623742 214.3297399676161 -35.60436430755703 cw) '
             '(arc 216.19899366773637 -34.89310443621139 2.0 218.06824736785666 -34.18184456486575 ccw) '
             '(arc 26.12230196103542 -107.21818437608977 205.37174316623742 109.21749463312395 80.59220363779905 ccw))')


def g4_footprint(c=(-41.88515439275838, -102.0954115682855), e1=(134.0, 0.0), e2=(154.39847053424393, -155.3100635410076),
                 rc=203.36927152119628):
    d = abs(math.atan2(e1[1] - c[1], e1[0] - c[0]) - math.atan2(e2[1] - c[1], e2[0] - c[0]))
    ro, ri, h, f = rc + 2.0, rc - 2.0, 2.0, 5.0
    a = d / 2 * (ro * ro - ri * ri) + math.pi * h * h
    p = d * (ro + ri) + 2 * math.pi * h
    return a + f * p + math.pi * f * f


def g4blade():
    hi = g4_footprint()
    t = triple('g4.bcd', [f'(node 1 (revolve {G4_HUB}) {IC})'], [f'(node 2 (sweep (wall {G4_BLADE}) {G4_PROF}) {IC})'],
               1, 2, None, hi, None)
    ab = iv_add(t['va'], t['vb'])
    hu = (ab[0] - hi, ab[1] - hi) if ab else None
    checks, info = finish('g4', 'g4.bcd', t, t['u'], None, t['d'], 1)
    o2, _ = cli('g4.bcd', 'apply', f'(node 6 (sweep (wall {G4_BLADE1}) {G4_PROF}) {IC})', f'(node 7 (union {t["u"]} 6) {IA})')
    ev2, _ = cli('g4.bcd', 'eval')
    h1 = g4_footprint((26.12230196103542, -107.21818437608977), (108.40827724624296, 78.76322380719142),
                      (216.19899366773637, -34.89310443621139), 203.37174316623742)
    u1 = iv_add(vol(ev2, t['u']), vol(ev2, 6))
    checks.update(hinter=contains(t['vi'], hi), hunion=iv_overlap(t['vu'], hu), ident=t['ident'], second='committed' in o2,
                  hunion2=u1 is not None and iv_overlap(vol(ev2, 7), (u1[0] - h1, u1[1] - h1)))
    record('g4blade', all(checks.values()), artifacts=('g4.bcd', 'g4.stp', 'g4.bin'), seconds=t['seconds'], **checks, **info)


def main():
    os.makedirs(WORK, exist_ok=True)
    bore_eq()
    bore_uneq()
    offaxis()
    fig8port()
    cbore()
    oring()
    csink()
    sidefeat()
    chamfer_edges()
    edgechamfer()
    g3limits()
    g2pump()
    spheres()
    fillets()
    g4blade()
    g4rotor()
    frame_seam()
    volute_panel()
    json.dump(RESULTS, open(OUT, 'w'), indent=1)
    n = sum(1 for r in RESULTS if r['ok'])
    print(f'{n}/{len(RESULTS)} corpus members hold')
    sys.exit(0 if n == len(RESULTS) else 1)


if __name__ == '__main__':
    main()
