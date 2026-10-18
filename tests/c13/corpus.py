import hashlib
import importlib.util
import json
import math
import os
import re
import struct
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, 'corpus-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-corpus-c13'
VERSION = 1
RESULTS = []

IC = '(intent create any any any any)'
IA = '(intent add any any any any)'
IS = '(intent same any any any any)'

L, W, T, R, LH = 100.0, 50.0, 2.0, 3.0, 10.0
KLO, KHI = 0.3, 0.5
FLAT = f'(node 1 (flat {L:g} {W:g} {T:g}) {IC})'
B90 = lambda b=1, n=0, r=R, d=90, i=2: f'(node {i} (bend {b} (edge {n}) {r:g} {d}) {IA})'
HEM = lambda b=1, n=0, l=LH, i=2: f'(node {i} (hem {b} (edge {n}) {l:g}) {IA})'
BRACKET = [FLAT, B90(), B90(2, 2, R, 90, 3), HEM(3, 0, LH, 4)]


def pt(x, y, z):
    return f'(pt {x:g} {y:g} {z:g})'


XS = [0.0, 4.0, 6.0, 10.0]
YS = [0.0, 2.0, 3.0, 5.0]
RECT_PTS = [(x, y, 0.0) for y in YS for x in XS]
COWL_PTS = [(x, y, (x * (10.0 - x) * y * (5.0 - y)) / 500.0 if 0.0 < x < 10.0 and 0.0 < y < 5.0 else 0.0)
            for y in YS for x in XS]
PATCH = lambda pts, i=1: f"(node {i} (patch {' '.join(pt(*p) for p in pts)}) {IC})"
LOFT = lambda z, b, t, i=1: (f"(node {i} (loft-open {z:g} "
                             f"(region (path {b[0]:g} {b[1]:g} (line {b[2]:g} {b[1]:g}) (line {b[2]:g} {b[3]:g}) (line {b[0]:g} {b[3]:g}))) "
                             f"(region (path {t[0]:g} {t[1]:g} (line {t[2]:g} {t[1]:g}) (line {t[2]:g} {t[3]:g}) (line {t[0]:g} {t[3]:g})))) {IC})")
THICK = lambda b, t, i: f'(node {i} (thicken-open {b} {t:g}) {IA})'
TAPERLO = (8.0, 0.0, 0.0, 10.0, 5.0, 1.0, 1.0, 9.0, 4.0)

NACA = lambda m, p, t, c, n, i=1: f'(node {i} (naca4 {m} {p} {t:g} {c:g} {n}) {IC})'
BLADE = lambda secs, z, tw, tp, i: f"(node {i} (blade {' '.join(str(s) for s in secs)} {z:g} {tw} {tp}) {IC})"

BOX = f'(node 1 (box 10 10 10) {IC})'


def load_oracle(pkt):
    p = os.path.join(ROOT, 'tests', pkt, 'oracle.py')
    spec = importlib.util.spec_from_file_location('oc_' + pkt.replace('.', '_'), p)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


OC1 = load_oracle('c16.1')
OC2 = load_oracle('c16.2')
OC3 = load_oracle('c16.3')


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    env = dict(os.environ, MSYS_NO_PATHCONV='1', BEND_NO_TELEMETRY='1')
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout, env=env)
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


def geom(*args):
    return wsl(BIN, 'geom', *args)


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def read(design):
    return wsl('cat', f'{WORK}/{design}')[0]


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def jval(v):
    if isinstance(v, (tuple, list)):
        return [jval(x) for x in v]
    if getattr(type(v), '__module__', '') == 'numpy':
        return v.item()
    return v


def record(name, ok, artifacts=(), **checks):
    RESULTS.append(dict(name=name, ok=bool(ok), checks={k: jval(v) for k, v in checks.items()},
                        artifacts={a: sha(os.path.join(WORK, a)) for a in artifacts
                                   if os.path.exists(os.path.join(WORK, a))}))
    print(('PASS ' if ok else 'FAIL ') + name, flush=True)


def num(tok):
    if tok.startswith('b:'):
        return struct.unpack('>d', struct.pack('>Q', int(tok[2:])))[0]
    return float(tok)


def contains(iv, x):
    return iv is not None and iv[0] <= x <= iv[1]


def vol(out, node):
    m = re.search(rf'node {node}: ok .*?volume=\[([^,]+), ([^\]]+)\]', out)
    return (float(m.group(1)), float(m.group(2))) if m else None


def bbox(out, node):
    m = re.search(rf'node {node}: ok .*?bbox=\[([^,]+), ([^\]]+)\]x\[([^,]+), ([^\]]+)\]x\[([^,]+), ([^\]]+)\]', out)
    return [float(m.group(i)) for i in range(1, 7)] if m else None


def genus(out, node):
    m = re.search(rf'node {node}: ok .*?genus=(\d+)', out)
    return int(m.group(1)) if m else None


def faces_n(out, node):
    m = re.search(rf'node {node}: ok .*?faces=(\d+)', out)
    return int(m.group(1)) if m else None


def face_lines(text):
    return [ln for ln in text.strip().splitlines() if ln and not ln.startswith('deleted ')]


def kind_n(lines, kind):
    return sum(1 for ln in lines if len(ln.split()) >= 2 and ln.split()[1] == kind)


def flat_field(out, key):
    m = re.search(rf'{key} \[(.+?), (.+?)\] certified', out)
    return (num(m.group(1)), num(m.group(2))) if m else None


def flat_legs(out):
    m = re.search(r'legs \[(.*?)\]', out)
    return [num(t) for t in m.group(1).split(', ')] if m else None


def surf_field(out, key):
    m = re.search(rf'{key} \[(.+?), (.+?)\] (certified|estimated)', out)
    return (num(m.group(1)), num(m.group(2)), m.group(3)) if m else None


def surf_edges(out):
    return re.findall(r'edge n\d+\.e\d+ len \[(.+?), (.+?)\] (certified|estimated)', out)


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


def blade_header(out):
    m = re.search(r'blade node (\d+) sections (\d+) span (\S+) twist (\d+) taper (\d+)', out)
    return m.groups() if m else None


def blade_sched(out):
    m = re.search(r'twist-schedule (.*)', out)
    return [num(t) for t in m.group(1).split()] if m else None


def g3_gearbox():
    rep = {}
    arts = []
    for tag in ('g3a', 'g3b'):
        d = os.path.join(WORK, tag)
        t = time.time()
        r = subprocess.run([sys.executable, os.path.join(ROOT, 'tools', 'g3', 'gearbox.py'), d, 'parts'],
                           capture_output=True, text=True, timeout=3600,
                           env=dict(os.environ, BENDCAD_BIN=BIN, BEND_NO_TELEMETRY='1'))
        rep[tag] = dict(rc=r.returncode, seconds=round(time.time() - t, 1),
                        report=json.load(open(os.path.join(d, 'report.json'))) if os.path.exists(
                            os.path.join(d, 'report.json')) else None,
                        bcd=open(os.path.join(d, 'gearbox.bcd')).read() if os.path.exists(
                            os.path.join(d, 'gearbox.bcd')) else None)
        arts += [f'{tag}/report.json', f'{tag}/gearbox.bcd', f'{tag}/assembly.txt']
    a, b = rep['g3a'], rep['g3b']
    ra, rb = a['report'], b['report']
    stages_ok = (ra is not None and rb is not None and
                 ra['stages'] == rb['stages'] == {'housing': 'committed', 'lid': 'committed',
                                                 'drivetrain': 'committed', 'purchased': 'committed'})
    solve_ok = (ra is not None and rb is not None and ra['solve'] == rb['solve'] and
                re.match(r'asm solved ninst 119 nmates 122 dof 0 ', ra['solve']) is not None)
    checks = dict(exit0=a['rc'] == 0 and b['rc'] == 0, stages=stages_ok, solve=solve_ok,
                  eval_eq=ra is not None and rb is not None and ra['eval'] == rb['eval'],
                  bcd_eq=a['bcd'] is not None and a['bcd'] == b['bcd'],
                  asm_eq=open(os.path.join(WORK, 'g3a', 'assembly.txt')).read() ==
                  open(os.path.join(WORK, 'g3b', 'assembly.txt')).read()
                  if os.path.exists(os.path.join(WORK, 'g3a', 'assembly.txt')) and
                  os.path.exists(os.path.join(WORK, 'g3b', 'assembly.txt')) else False)
    record('g3.gearbox', all(checks.values()), artifacts=arts, solve_line=ra['solve'] if ra else None,
           seconds=(a['seconds'], b['seconds']), **checks)


def sheet_bracket():
    import trimesh
    from build123d import import_step
    assert OC1.sh_vol(10, L, T, R, W, LH) == 15756.637061435918
    a90 = OC1.allow(90, R, T, KLO, KHI)
    want = OC1.sh_vol(10, L, T, R, W, LH)
    out, _ = fresh('cb.bcd', *BRACKET)
    ev, _ = cli('cb.bcd', 'eval')
    chk, _ = cli('cb.bcd', 'check', '4')
    fl, _ = cli('cb.bcd', 'faces', '4')
    fo, _ = cli('cb.bcd', 'flat', '4', str(KLO), str(KHI))
    rows = re.findall(r'bend \d+ edge \d+ deg 90 r ' + r'([0-9.eE+-]+|b:\d+)' + r' allowance \[(.+?), (.+?)\] certified', fo)
    cli('cb.bcd', 'tess', '4', f'{WORK}/cb.obj')
    m = trimesh.load(f'{WORK}/cb.obj', force='mesh') if os.path.exists(f'{WORK}/cb.obj') else None
    cli('cb.bcd', 'step', '4', f'{WORK}/cb.stp')
    s = import_step(f'{WORK}/cb.stp') if os.path.exists(f'{WORK}/cb.stp') else None
    solids = s.solids() if s is not None else []
    faces = s.faces() if s is not None else []
    cyl = sum(1 for f in faces if getattr(f.geom_type, 'name', f.geom_type) == 'CYLINDER') if faces else -1
    vv = solids[0].volume if len(solids) == 1 else None
    sh, _ = cli('cb.bcd', 'show')
    cli('cb2.bcd', 'new')
    nodes = [ln for ln in sh.splitlines() if ln.startswith('(node ')]
    out2, _ = cli('cb2.bcd', 'apply', *nodes)
    e2, _ = cli('cb2.bcd', 'eval')
    cli('cb.bcd', 'archive', '4', f'{WORK}/cb.bin')
    ro, _ = wsl(BIN, 'geom', 'reopen', f'{WORK}/cb.bin', '-v')
    rm = re.search(r'volume=\[([^,]+), ([^\]]+)\]', ro)
    riv = (num(rm.group(1)), num(rm.group(2))) if rm else None
    bb = bbox(ev, 4)
    checks = dict(committed='committed' in out, check=chk.startswith('ok:'),
                  volume=contains(vol(ev, 4), want), faces=len(face_lines(fl)) == 16,
                  cyl=kind_n(face_lines(fl), 'cylinder') == 4,
                  bbox=bb is not None and all(abs(g - w) < 1e-9 for g, w in
                                              zip(bb, [0.0, 102.0, 0.0, 27.5, 0.0, 50.0])),
                  header='flat node 4 bends 2 hems 1' in fo,
                  allows=[(num(a), num(b)) for _, a, b in rows] == [a90, a90],
                  legs=flat_legs(fo) == [12.5, 2.0, 10.0, 10.0, 90.0, 22.5],
                  dev=flat_field(fo, 'developed') == OC1.developed(10, L, T, R, LH, [a90, a90]),
                  mesh=m is not None and abs(m.volume - want) / want < 0.01,
                  step=len(solids) == 1 and len(faces) == 16 and cyl == 4 and
                  vv is not None and abs(vv - want) / want < 1e-6,
                  replay='committed' in out2 and e2 == ev and len(nodes) == 4,
                  reopen=sum(1 for ln in ro.splitlines() if 'loops=' in ln) == 16 and
                  riv is not None and contains(riv, want))
    record('sheet.bracket', all(checks.values()),
           artifacts=('cb.bcd', 'cb.obj', 'cb.stp', 'cb.bin'), stp_volume=vv, **checks)


def sheet_edits():
    fresh('ce.bcd', '(param L 100)', '(param T 2)', f'(node 1 (flat L 50 T) {IC})',
          f'(node 2 (bend 1 (edge 0) 3 90) {IA})')
    e0, _ = cli('ce.bcd', 'eval')
    a90 = OC1.allow(90, R, T, KLO, KHI)
    oks = []
    for v in ('120', '100', '140', '120', '100'):
        o, _ = cli('ce.bcd', 'apply', f'(param L {v})')
        oks.append('committed' in o)
        if v == '120' and len(oks) == 1:
            f1, _ = cli('ce.bcd', 'flat', '2', str(KLO), str(KHI))
    e1, _ = cli('ce.bcd', 'eval')
    se, _ = cli('ce.bcd', 'sens', 'L', '2')
    sm = re.search(r'd_volume=([^ ]+)', se)
    checks = dict(edits=all(oks), cycle=e1 == e0,
                  dev1=flat_field(f1, 'developed') == OC1.developed(0, 120.0, T, R, LH, [a90]),
                  legs1=flat_legs(f1) == [60.0, 55.0],
                  sens=bool(sm) and abs(float(sm.group(1)) - 100.0) < 0.01 and 'reused' in se)
    record('sheet.edits', all(checks.values()), artifacts=('ce.bcd',), **checks)


def sheet_fold180():
    want = OC1.sh_vol(2, L, T, R, W, LH)
    out, _ = fresh('cf.bcd', FLAT, B90(1, 0, R, 180))
    ev, _ = cli('cf.bcd', 'eval')
    chk, _ = cli('cf.bcd', 'check', '2')
    fl, _ = cli('cf.bcd', 'faces', '2')
    bb = bbox(ev, 2)
    checks = dict(committed='committed' in out, check=chk.startswith('ok:'),
                  volume=contains(vol(ev, 2), want), faces=len(face_lines(fl)) == 10,
                  cyl=kind_n(face_lines(fl), 'cylinder') == 2,
                  bbox=bb is not None and all(abs(g - w) < 1e-9 for g, w in
                                              zip(bb, [0.0, 55.0, 0.0, 10.0, 0.0, 50.0])))
    record('sheet.fold180', all(checks.values()), artifacts=('cf.bcd',), **checks)


def surf_cowl():
    from build123d import import_step
    out, _ = fresh('cc.bcd', PATCH(COWL_PTS))
    su, _ = cli('cc.bcd', 'surf', '1')
    fl, _ = cli('cc.bcd', 'faces', '1')
    a = surf_field(su, 'area')
    want = OC2.patch_area(COWL_PTS)
    out2, _ = fresh('cs.bcd', PATCH(RECT_PTS), THICK(1, 2.0, 2))
    ev, _ = cli('cs.bcd', 'eval')
    chk, _ = cli('cs.bcd', 'check', '2')
    sl, _ = cli('cs.bcd', 'faces', '2')
    cli('cs.bcd', 'step', '2', f'{WORK}/cs.stp')
    s = import_step(f'{WORK}/cs.stp') if os.path.exists(f'{WORK}/cs.stp') else None
    solids = s.solids() if s is not None else []
    vv = solids[0].volume if len(solids) == 1 else None
    sh, _ = cli('cs.bcd', 'show')
    cli('cs2.bcd', 'new')
    nodes = [ln for ln in sh.splitlines() if ln.startswith('(node ')]
    out3, _ = cli('cs2.bcd', 'apply', *nodes)
    e2, _ = cli('cs2.bcd', 'eval')
    cli('cs.bcd', 'archive', '2', f'{WORK}/cs.bin')
    ro, _ = wsl(BIN, 'geom', 'reopen', f'{WORK}/cs.bin', '-v')
    rm = re.search(r'volume=\[([^,]+), ([^\]]+)\]', ro)
    riv = (float(rm.group(1)), float(rm.group(2))) if rm else None
    checks = dict(committed='committed' in out and 'committed' in out2,
                  header='surf node 1 kind patch faces 1 boundary 4' in su,
                  edges=len(surf_edges(su)) == 4 and all(t == 'estimated' for _, _, t in surf_edges(su)),
                  area=a is not None and abs(a[0] - want) / want < 0.01,
                  slab=chk.startswith('ok:') and contains(vol(ev, 2), 100.0) and
                  len(face_lines(sl)) == 6 and genus(ev, 2) == 0,
                  step=len(solids) == 1 and vv is not None and abs(vv - 100.0) / 100.0 < 1e-6,
                  replay='committed' in out3 and e2 == ev and len(nodes) == 2,
                  reopen=sum(1 for ln in ro.splitlines() if 'loops=' in ln) == 6 and
                  riv is not None and contains(riv, 100.0))
    record('surf.cowl', all(checks.values()), artifacts=('cc.bcd', 'cs.bcd', 'cs.stp', 'cs.bin'),
           oracle_area=want, **checks)


def surf_duct():
    out, _ = fresh('cd.bcd', LOFT(8.0, (0, 0, 10, 5), (1, 1, 9, 4)), THICK(1, 1.0, 2))
    ev, _ = cli('cd.bcd', 'eval')
    chk, _ = cli('cd.bcd', 'check', '2')
    want = OC2.duct_vol(TAPERLO, 1.0)
    lines = [ln for ln in chk.splitlines() if ln]
    bez = (lines and all(ln.startswith('face-check-unsupported') or
                         ln.startswith('face-face-uncertain') for ln in lines))
    cli('cd.bcd', 'archive', '2', f'{WORK}/cd.bin')
    ro, _ = wsl(BIN, 'geom', 'reopen', f'{WORK}/cd.bin', '-v')
    rm = re.search(r'volume=\[([^,]+), ([^\]]+)\]', ro)
    riv = (float(rm.group(1)), float(rm.group(2))) if rm else None
    checks = dict(committed='committed' in out, check=bez,
                  vol=contains(vol(ev, 2), want), faces=faces_n(ev, 2) == 16,
                  genus=genus(ev, 2) == 1,
                  reopen=sum(1 for ln in ro.splitlines() if 'loops=' in ln) == 16 and
                  riv is not None and contains(riv, want))
    record('surf.duct', all(checks.values()), artifacts=('cd.bcd', 'cd.bin'),
           oracle_vol=want, **checks)


def blade_stack():
    from build123d import import_step
    secs = [NACA(4, 4, 12, 100, 17, i=i + 1) for i in range(5)]
    out, _ = fresh('cb3.bcd', *secs, BLADE((1, 2, 3, 4, 5), 200, 20, 75, 6))
    ev, _ = cli('cb3.bcd', 'eval')
    rp, _ = cli('cb3.bcd', 'blade', '6')
    chk, _ = cli('cb3.bcd', 'check', '6')
    verdict, _ = check_honest(chk)
    secs2 = [NACA(0, 0, 12, 100, 17, i=i + 1) for i in range(2)]
    fresh('cp.bcd', *secs2, BLADE((1, 2), 50, 0, 100, 3))
    cli('cp.bcd', 'step', '3', f'{WORK}/cp.stp')
    s = import_step(f'{WORK}/cp.stp') if os.path.exists(f'{WORK}/cp.stp') else None
    solids = s.solids() if s is not None else []
    faces = s.faces() if s is not None else []
    kinds = sorted(getattr(f.geom_type, 'name', f.geom_type) for f in faces)
    vv = solids[0].volume if len(solids) == 1 else None
    want = OC3.float_area(OC3.float_ring(0, 0, 12, 100.0, 17)) * 50.0
    sh, _ = cli('cp.bcd', 'show')
    cli('cp2.bcd', 'new')
    nodes = [ln for ln in sh.splitlines() if ln.startswith('(node ')]
    out2, _ = cli('cp2.bcd', 'apply', *nodes)
    e2, _ = cli('cp.bcd', 'eval')
    e3, _ = cli('cp2.bcd', 'eval')
    cli('cp.bcd', 'archive', '3', f'{WORK}/cp.bin')
    ro, _ = wsl(BIN, 'geom', 'reopen', f'{WORK}/cp.bin', '-v')
    rm = re.search(r'volume=\[([^,]+), ([^\]]+)\]', ro)
    riv = (float(rm.group(1)), float(rm.group(2))) if rm else None
    checks = dict(committed='committed' in out,
                  header=blade_header(rp) == ('6', '5', '200', '20', '75'),
                  sched=blade_sched(rp) == [0.0, 5.0, 10.0, 15.0, 20.0],
                  faces=faces_n(ev, 6) == 4 * 32 + 2, genus=genus(ev, 6) == 0,
                  check=verdict == 'ruled',
                  step=len(solids) == 1 and len(faces) == 34 and
                  kinds == ['BSPLINE'] * 32 + ['PLANE'] * 2 and
                  vv is not None and abs(vv - want) / want < 1e-6,
                  replay='committed' in out2 and e2 == e3 and len(nodes) == 3,
                  reopen=sum(1 for ln in ro.splitlines() if 'loops=' in ln) == 34 and
                  riv is not None and contains(riv, want))
    record('blade.stack', all(checks.values()),
           artifacts=('cb3.bcd', 'cp.bcd', 'cp.stp', 'cp.bin'), stp_volume=vv, **checks)


def scale_sweep():
    rows = {}
    spans = {}
    for s in (0.01, 1.0, 100.0, 1000.0):
        tag = ('%g' % s).replace('.', 'p')
        out, _ = fresh(f'sc{tag}.bcd', f'(node 1 (box {s:g} {s:g} {s:g}) {IC})')
        ev, _ = cli(f'sc{tag}.bcd', 'eval')
        bb = bbox(ev, 1)
        rows[tag] = ('committed' in out and contains(vol(ev, 1), s ** 3) and
                     bb is not None and all(abs((bb[2 * i + 1] - bb[2 * i]) - s) / s < 1e-9
                                            for i in range(3)))
        spans[tag] = bb
    record('scale.sweep', all(rows.values()), artifacts=tuple(f'sc{t}.bcd' for t in rows), **rows)


def mixed_union():
    from build123d import import_step
    base = [PATCH(RECT_PTS), THICK(1, 2.0, 2),
            LOFT(8.0, (0, 0, 10, 5), (1, 1, 9, 4), i=3), THICK(3, 1.0, 4),
            f'(node 5 (move 4 0 0 40 0) {IS})']
    out, _ = fresh('mx.bcd', *base)
    ev, _ = cli('mx.bcd', 'eval')
    m2 = re.search(r'node 2: ok .*?solids=(\d+)', ev)
    m5 = re.search(r'node 5: ok .*?solids=(\d+)', ev)
    before = read('mx.bcd')
    rej, _ = cli('mx.bcd', 'apply', '(node 6 (union 2 5) (intent add any any any any))')
    after = read('mx.bcd')
    cli('mx.bcd', 'step', '2', f'{WORK}/mx2.stp')
    cli('mx.bcd', 'step', '5', f'{WORK}/mx5.stp')
    s2 = import_step(f'{WORK}/mx2.stp') if os.path.exists(f'{WORK}/mx2.stp') else None
    s5 = import_step(f'{WORK}/mx5.stp') if os.path.exists(f'{WORK}/mx5.stp') else None
    checks = dict(committed='committed' in out,
                  solids=m2 is not None and m2.group(1) == '1' and
                  m5 is not None and m5.group(1) == '1',
                  refused='bezier-patch-operand' in rej and 'rejected' in rej and after == before,
                  step=s2 is not None and len(s2.solids()) == 1 and
                  s5 is not None and len(s5.solids()) == 1)
    record('mixed.union', all(checks.values()), artifacts=('mx.bcd', 'mx2.stp', 'mx5.stp'), **checks)


def ring_arcs():
    semi12 = '(path 12 0 (arc 0 0 12 -12 0 ccw) (arc 0 0 12 12 0 ccw))'
    semi10 = '(path 10 0 (arc 0 0 10 -10 0 ccw) (arc 0 0 10 10 0 ccw))'
    ring = ('(path 0 -18 (line 10 -18) (arc 10 -10 8 18 -10 ccw) (line 18 10) (arc 10 10 8 10 18 ccw) (line 0 18) '
            '(arc 0 10 8 -8 10 ccw) (line -8 -10) (arc 0 -10 8 0 -18 ccw))')
    inner = ('(path 0 -15 (line 10 -15) (arc 10 -10 5 15 -10 ccw) (line 15 10) (arc 10 10 5 10 15 ccw) (line 0 15) '
             '(arc 0 10 5 -5 10 ccw) (line -5 -10) (arc 0 -10 5 0 -15 ccw))')
    rows = {}
    cases = [('arcs_vs_arcs', semi12, semi10, math.pi * 44 * 5),
             ('rounded_ring', ring, inner, ((26 * 36 - (4 - math.pi) * 64) - (20 * 30 - (4 - math.pi) * 25)) * 5)]
    for name, outer, hole, exact in cases:
        out, _ = fresh('ra_%s.bcd' % name,
                       f'(node 1 (prism 0 5 (region {outer} {hole})) (intent create any 0 1 1))')
        rows[name] = ('committed' in out and contains(vol(out, 1), exact))
    bad = [('touching', semi12, '(path 12 0 (arc 0 0 12 -12 0 ccw) (arc 0 0 12 12 0 ccw))'),
           ('crossing', semi12, '(path 13 0 (arc 0 0 13 -13 0 ccw) (arc 0 0 13 13 0 ccw))'),
           ('tangent_inside', semi12, '(circle 1 0 11)')]
    for name, outer, hole in bad:
        out, _ = fresh('rb_%s.bcd' % name,
                       f'(node 1 (prism 0 5 (region {outer} {hole})) (intent create any 0 1 1))')
        rows['refuse_' + name] = ('rejected' in out and ('curves-cross-or-touch' in out or
                                                         'clearance-not-certified' in out or 'hole-outside-outer' in out))
    record('ring.arcs', all(rows.values()), artifacts=('ra_arcs_vs_arcs.bcd', 'ra_rounded_ring.bcd'), **rows)


def corrupt_inputs():
    rows = {}
    fresh('ks.bcd', BOX)
    o, _ = cli('ks.bcd', 'step', '1', f'{WORK}/kbox.step')
    assert o.startswith('wrote '), o
    box_step = open(f'{WORK}/kbox.step').read()
    fresh('ka.bcd', BOX)
    o, _ = cli('ka.bcd', 'archive', '1', f'{WORK}/kbox.bca', 'corpus')
    assert o.startswith('wrote '), o
    box_arc = open(f'{WORK}/kbox.bca').read()
    imps = [('garbage', 'not a step file\n', 'step-no-solid'),
            ('badent', 'ISO-10303-21;\nHEADER;\nENDSEC;\nDATA;\n#1 = \nENDSEC;\nEND-ISO-10303-21;\n',
             'step-entity-parse-failed'),
            ('cone', box_step.replace('PLANE(', 'CONICAL_SURFACE(', 1), 'step-cone-recovery-failed')]
    for name, text, why in imps:
        open(f'{WORK}/k{name}.step', 'w').write(text)
        out, _ = geom('step_import', f'{WORK}/k{name}.step', f'{WORK}/k{name}.bca')
        rows['import_' + name] = (why in out and not os.path.exists(f'{WORK}/k{name}.bca'))
    arcs = [('garbage', 'hello\n', 'archive-sections-count'),
            ('badver', 'BCAD0' + box_arc[5:], 'archive-bad-version'),
            ('badunits', box_arc.replace('|mm|', '|inch|', 1), 'archive-units-not-supported')]
    for name, text, why in arcs:
        open(f'{WORK}/kr{name}.bca', 'w').write(text)
        out, _ = geom('reopen', f'{WORK}/kr{name}.bca')
        rows['reopen_' + name] = (why in out)
    for verb, ext, msg in (('step_of', 'step', 'error invalid-input | step_of'),
                           ('stl_of', 'stl', 'error: node failed; nothing exported'),
                           ('3mf_of', '3mf', 'error: node failed; nothing exported')):
        open(f'{WORK}/kx.bca', 'w').write('hello\n')
        out, _ = geom(verb, f'{WORK}/kx.bca', f'{WORK}/kx.{ext}')
        rows[verb] = (msg in out and not os.path.exists(f'{WORK}/kx.{ext}'))
    before = read('ka.bcd')
    out, _ = cli('ka.bcd', 'step', '99', f'{WORK}/kx2.step')
    rows['node_failed'] = ('error: node failed; nothing exported' in out and read('ka.bcd') == before and
                           not os.path.exists(f'{WORK}/kx2.step'))
    record('corrupt.inputs', all(rows.values()), artifacts=('kbox.step', 'kbox.bca'), **rows)


def crash_recovery():
    fresh('kr.bcd', *BRACKET)
    e0, _ = cli('kr.bcd', 'eval')
    before = read('kr.bcd')
    out, _ = cli('kr.bcd', 'apply', '(node 5 (bend 4 (edge 9) 3 90) (intent add any any any any))')
    intact = (read('kr.bcd') == before and 'rejected' in out)
    cli('kr.bcd', 'archive', '4', f'{WORK}/kr.bin')
    os.remove(f'{WORK}/kr.bcd')
    ro, _ = wsl(BIN, 'geom', 'reopen', f'{WORK}/kr.bin', '-v')
    rm = re.search(r'volume=\[([^,]+), ([^\]]+)\]', ro)
    riv = (num(rm.group(1)), num(rm.group(2))) if rm else None
    want = OC1.sh_vol(10, L, T, R, W, LH)
    fresh('kr2.bcd', *BRACKET)
    sh, _ = cli('kr2.bcd', 'show')
    cli('kr3.bcd', 'new')
    nodes = [ln for ln in sh.splitlines() if ln.startswith('(node ')]
    out2, _ = cli('kr3.bcd', 'apply', *nodes)
    e2, _ = cli('kr2.bcd', 'eval')
    e3, _ = cli('kr3.bcd', 'eval')
    half = read('kr2.bcd')
    open(f'{WORK}/kh.bcd', 'w').write(half[:len(half) // 2])
    out3, _ = cli('kh.bcd', 'eval')
    kh_after = open(f'{WORK}/kh.bcd').read()
    checks = dict(reject_atomic=intact,
                  archive_restore=sum(1 for ln in ro.splitlines() if 'loops=' in ln) == 16 and
                  riv is not None and contains(riv, want),
                  transcript='committed' in out2 and e2 == e3 and e2 == e0,
                  truncated_no_commit='committed' not in out3 and kh_after == half[:len(half) // 2])
    record('crash.recovery', all(checks.values()), artifacts=('kr.bin', 'kr2.bcd'),
           truncated_head=out3.strip()[:200], **checks)


def long_sequence():
    rr = '(path R 0 (line (- W R) 0) (arc (- W R) R R W R ccw) (line W (- H R)) (arc (- W R) (- H R) R (- W R) H ccw) (line R H) (arc R (- H R) R 0 (- H R) ccw) (line 0 R) (arc R R R R 0 ccw))'
    base = ['(param W 120 119.9 120.1)', '(param H 80)', '(param T 8)', '(param R 10)', '(param D 8)',
            '(param E 12)', '(param B 40)', '(param P 12)', '(param C 20)',
            f'(node 1 (prism 0 T (region {rr})) (intent create 10 0 1 0))',
            '(node 2 (holes 1 (face 1 0 top) through (hole E E (/ D 2)) (hole (- W E) E (/ D 2)) (hole E (- H E) (/ D 2)) (hole (- W E) (- H E) (/ D 2))) (intent remove 4 2 1 4))',
            '(node 3 (pad 2 (face 1 0 top) P (region (circle (/ W 2) (/ H 2) (/ B 2)))) (intent add 2 1 1 4))',
            '(node 4 (holes 3 (face 3 0 top) through (hole (/ W 2) (/ H 2) (/ C 2))) (intent remove 1 2 1 5))']
    out, _ = fresh('kl.bcd', *base)
    e0, _ = cli('kl.bcd', 'eval')
    ok = 'committed' in out
    n = 0
    for i in range(40):
        o, _ = cli('kl.bcd', 'apply', '(param W %d)' % (120 if i % 2 else 140))
        ok = ok and 'committed' in o
        n += 1
        if i % 5 == 4:
            q, _ = cli('kl.bcd', 'measure', '4')
            ok = ok and 'volume=' in q
            q, _ = cli('kl.bcd', 'show')
            ok = ok and '(node 4' in q
    e1, _ = cli('kl.bcd', 'eval')
    exact = (120 * 80 - (4 - math.pi) * 100 - 4 * math.pi * 16) * 8 + math.pi * 400 * 12 - math.pi * 100 * 20
    checks = dict(sequence=ok and n == 40, cycle=e1 == e0, volume=contains(vol(e1, 4), exact))
    record('long.sequence', all(checks.values()), artifacts=('kl.bcd',), **checks)


MEMBERS = [g3_gearbox, sheet_bracket, sheet_edits, sheet_fold180, surf_cowl, surf_duct,
           blade_stack, scale_sweep, mixed_union, ring_arcs, corrupt_inputs,
           crash_recovery, long_sequence]


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    want = [a for a in sys.argv[1:] if not a.startswith('-')]
    for f in MEMBERS:
        if want and not any(w in f.__name__ for w in want):
            continue
        t = time.time()
        try:
            f()
        except Exception as e:
            record(f.__name__.replace('_', '.', 1), False, error=f'{type(e).__name__}: {e}'[:300])
        RESULTS[-1]['seconds'] = round(time.time() - t, 1)
    rep = dict(corpus_version=VERSION, binary=BIN,
               binary_sha256=wsl('sha256sum', BIN)[0].split()[0],
               passed=sum(r['ok'] for r in RESULTS), total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} corpus members hold")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
