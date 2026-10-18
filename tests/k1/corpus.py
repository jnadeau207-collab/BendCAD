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
    spheres()
    json.dump(RESULTS, open(OUT, 'w'), indent=1)
    n = sum(1 for r in RESULTS if r['ok'])
    print(f'{n}/{len(RESULTS)} corpus members hold')
    sys.exit(0 if n == len(RESULTS) else 1)


if __name__ == '__main__':
    main()
