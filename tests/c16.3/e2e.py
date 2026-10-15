import json
import math
import os
import re
import struct
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import oracle as OC

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'e2e-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-c163'
RESULTS = []

IC = '(intent create any any any any)'
IS = '(intent same any any any any)'

NACA = lambda m, p, t, c, n, i=1: f'(node {i} (naca4 {m} {p} {t:g} {c:g} {n}) {IC})'
BLADE = lambda secs, z, tw, tp, i: f"(node {i} (blade {' '.join(str(s) for s in secs)} {z:g} {tw} {tp}) {IC})"


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def record(name, ok, **checks):
    RESULTS.append(dict(name=name, ok=bool(ok), checks=checks))
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


def check_lines(out):
    return [ln for ln in out.strip().splitlines() if ln]


def check_honest(out):
    ls = check_lines(out)
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


def blade_secs(out):
    rows = {}
    for m in re.finditer(r'sec (\d+) naca (\d+) chord (\S+) z \[(.+?), (.+?)\] certified '
                         r'area \[(.+?), (.+?)\] certified cx \[(.+?), (.+?)\] certified '
                         r'cy \[(.+?), (.+?)\] certified tmax \[(.+?), (.+?)\] certified '
                         r'cmax \[(.+?), (.+?)\] certified', out):
        g = m.groups()
        rows[int(g[0])] = dict(naca=g[1], chord=num(g[2]), z=(num(g[3]), num(g[4])),
                               area=(num(g[5]), num(g[6])), cx=(num(g[7]), num(g[8])),
                               cy=(num(g[9]), num(g[10])), tmax=(num(g[11]), num(g[12])),
                               cmax=(num(g[13]), num(g[14])))
    return rows


def blade_dev(out):
    m = re.search(r'deviation \[(.+?), (.+?)\] certified', out)
    return (num(m.group(1)), num(m.group(2))) if m else None


def blade_sched(out):
    m = re.search(r'twist-schedule (.*)', out)
    return [num(t) for t in m.group(1).split()] if m else None


def section_slab():
    out, _ = fresh('s.bcd', NACA(0, 0, 12, 100, 17))
    ev, _ = cli('s.bcd', 'eval')
    chk, _ = cli('s.bcd', 'check', '1')
    fl, _ = cli('s.bcd', 'faces', '1')
    fa = OC.float_area(OC.float_ring(0, 0, 12, 100.0, 17))
    v = vol(ev, 1)
    bb = bbox(ev, 1)
    verdict, lines = check_honest(chk)
    nfl = len([ln for ln in fl.strip().splitlines() if ln and not ln.startswith('deleted ')])
    checks = dict(committed='committed' in out, vol=v is not None and contains(v, fa),
                  vol_tight=v is not None and (v[1] - v[0]) / fa < 1e-9,
                  faces=faces_n(ev, 1) == 34 and nfl == 34, genus=genus(ev, 1) == 0,
                  check=verdict == 'prismatic',
                  bbox=bb is not None and abs(bb[0]) < 1e-9 and abs(bb[1] - 100.0) < 1e-9 and
                  abs(bb[4]) < 1e-6 and abs(bb[5] - 1.0) < 1e-9)
    record('section.slab', all(checks.values()), oracle_area=fa, verdict=verdict,
           check_n=len(lines), **checks)


def section_report():
    out, _ = fresh('r.bcd', NACA(4, 4, 12, 100, 33), NACA(4, 4, 12, 100, 33, i=2),
                   BLADE((1, 2), 50, 0, 100, 3))
    ev, _ = cli('r.bcd', 'eval')
    rp, _ = cli('r.bcd', 'blade', '3')
    fa = OC.float_area(OC.float_ring(4, 4, 12, 100.0, 33))
    v = vol(ev, 3)
    hdr = blade_header(rp)
    rows = blade_secs(rp)
    sched = blade_sched(rp)
    dev = blade_dev(rp)
    r0 = rows.get(0, {})
    ay, ac = OC.sec_th(4, 4, 12, 33)
    otmax = (OC.imid(ay) * 2.0 * 100.0, OC.imid(ac) * 100.0)
    checks = dict(committed='committed' in out,
                  header=hdr == ('3', '2', '50', '0', '100'),
                  rows=len(rows) == 2 and rows[0]['naca'] == '4412',
                  area=contains(r0.get('area'), fa),
                  chord=r0.get('chord') == 100.0,
                  tmax=r0.get('tmax') is not None and contains(r0['tmax'], otmax[0]),
                  cmax=r0.get('cmax') is not None and contains(r0['cmax'], otmax[1]),
                  vol=v is not None and contains(v, fa * 50.0),
                  dev=dev is not None and dev[1] < 1e-6,
                  sched=sched == [0.0, 0.0])
    record('section.report', all(checks.values()), oracle_area=fa, **checks)


def blade_twisted():
    secs = [NACA(4, 4, 12, 100, 17, i=i + 1) for i in range(5)]
    out, dt = fresh('b.bcd', *secs, BLADE((1, 2, 3, 4, 5), 200, 20, 75, 6))
    ev, _ = cli('b.bcd', 'eval')
    rp, _ = cli('b.bcd', 'blade', '6')
    chk, _ = cli('b.bcd', 'check', '6')
    hdr = blade_header(rp)
    rows = blade_secs(rp)
    sched = blade_sched(rp)
    dev = blade_dev(rp)
    v = vol(ev, 6)
    verdict, lines = check_honest(chk)
    ring0 = OC.float_ring(4, 4, 12, 100.0, 17)
    a0 = OC.float_area(ring0)
    areas = [a0 * (1 - 0.25 * i / 4) ** 2 for i in range(5)]
    fr = OC.frustum_vol(areas, 200.0)
    ok_rows = (len(rows) == 5 and all(contains(rows[i]['area'], areas[i]) for i in range(5)))
    ses5 = OC.stack([(4, 4, 12, 100.0, 17)] * 5, 200.0, 0, 75)
    odev = OC.deviation(ses5)
    checks = dict(committed='committed' in out, build_s=round(dt, 2),
                  header=hdr == ('6', '5', '200', '20', '75'), rows=ok_rows,
                  sched=sched == [0.0, 5.0, 10.0, 15.0, 20.0],
                  dev=dev is not None and contains(dev, (odev[0] + odev[1]) / 2),
                  vol=v is not None and abs((v[0] + v[1]) / 2 - fr) / fr < 0.005,
                  faces=faces_n(ev, 6) == 4 * 32 + 2, genus=genus(ev, 6) == 0,
                  check=verdict == 'ruled')
    record('blade.twisted', all(checks.values()), oracle_frustum=fr, verdict=verdict,
           check_n=len(lines), **checks)


def blade_eight():
    secs = [NACA(0, 0, 12, 60, 65, i=i + 1) for i in range(8)]
    out, dt = fresh('e.bcd', *secs, BLADE(tuple(range(1, 9)), 300, 30, 50, 9))
    ev, _ = cli('e.bcd', 'eval')
    rp, _ = cli('e.bcd', 'blade', '9')
    chk, _ = cli('e.bcd', 'check', '9')
    rows = blade_secs(rp)
    verdict, lines = check_honest(chk)
    checks = dict(committed='committed' in out, build_s=round(dt, 2), budget=dt < 30.0,
                  faces=faces_n(ev, 9) == 7 * 128 + 2, rows=len(rows) == 8,
                  sched=blade_sched(rp) is not None and len(blade_sched(rp)) == 8,
                  check=verdict == 'ruled')
    record('blade.eight', all(checks.values()), verdict=verdict, check_n=len(lines), **checks)


def tip_clearance():
    fresh('g.bcd', '(param CHORD 100)', '(param SPAN 200)',
          '(node 1 (naca4 0 0 12 CHORD 17) (intent create any any any any))',
          '(node 2 (naca4 0 0 12 CHORD 17) (intent create any any any any))',
          '(node 3 (blade 1 2 SPAN 0 100) (intent create any any any any))',
          '(node 4 (box 160 160 60) (intent create any any any any))',
          '(node 5 (move 4 -30 -80 170 0) (intent same any any any any))',
          '(node 6 (holes 5 (face 4 0 top) through (hole 80 80 60)) (intent remove any any any any))')
    ev, _ = cli('g.bcd', 'eval')
    cl, _ = cli('g.bcd', 'clearance', '3', '6')
    m = re.search(r'clearance \[([^,]+), ([^\]]+)\] (\w+) (lo=\w+) samples=(\d+)x(\d+)', cl)
    mz = re.search(r'clearance 0 status=(\w+) state=(\w+)', cl)
    ring = OC.float_ring(0, 0, 12, 100.0, 17)
    corner = max(math.hypot(x - 50.0, y) for x, y in ring)
    gap = 60.0 - corner
    st, _ = cli('g.bcd', 'pmi', 'stack',
                '(pmi (node 3) (dim dC CHORD) (dim dS SPAN) (state cold 1) (state hot 1.002) (stack s1 dC dS))')
    sm = re.search(r'stack s1 nominal (\S+) envelope \[(\S+), (\S+)\] certified', st)
    sh = re.search(r'state hot grow 1.002 \[(\S+), (\S+)\]', st)
    checks = dict(
        clearance=m is not None and float(m.group(1)) <= gap <= float(m.group(2)) and
        m.group(3) == 'estimated' and m.group(4) == 'lo=certified',
        no_zero=mz is None,
        stack='stacks 1 states 2' in st and sm is not None and sh is not None and
        float(sm.group(2)) <= 300.0 <= float(sm.group(3)) and
        float(sh.group(1)) <= 300.6 <= float(sh.group(2)))
    record('tip.clearance', all(checks.values()), oracle_gap=gap, raw=cl.strip()[:120],
           stackrows=[ln for ln in st.splitlines() if 'stack s1' in ln][:2], **checks)


def blade_edit():
    fresh('d.bcd', '(param CHORD 100)',
          '(node 1 (naca4 0 0 12 CHORD 17) (intent create any any any any))',
          '(node 2 (naca4 0 0 12 CHORD 17) (intent create any any any any))',
          '(node 3 (blade 1 2 200 0 100) (intent create any any any any))')
    r0, _ = cli('d.bcd', 'blade', '3')
    out, _ = cli('d.bcd', 'apply', '(param CHORD 120)')
    r1, _ = cli('d.bcd', 'blade', '3')
    e1, _ = cli('d.bcd', 'eval')
    rows0, rows1 = blade_secs(r0), blade_secs(r1)
    checks = dict(committed='committed' in out, changed=r0 != r1,
                  chord0=rows0.get(0, {}).get('chord') == 100.0,
                  chord1=rows1.get(0, {}).get('chord') == 120.0,
                  vol=contains(vol(e1, 3), OC.float_area(OC.float_ring(0, 0, 12, 120.0, 17)) * 200.0))
    record('blade.edit', all(checks.values()), **checks)


def blade_tess():
    import trimesh
    secs = [NACA(4, 4, 12, 100, 17, i=i + 1) for i in range(3)]
    fresh('t.bcd', *secs, BLADE((1, 2, 3), 200, 20, 75, 4))
    ev, _ = cli('t.bcd', 'eval')
    cli('t.bcd', 'tess', '4', f'{WORK}/blade.obj')
    p = f'{WORK}/blade.obj'
    m = trimesh.load(p, force='mesh') if os.path.exists(p) else None
    bb = bbox(ev, 4)
    want_bb = m.bounds.tolist() if m is not None else None
    placed, zt, _ = OC.float_stack_sec(4, 4, 12, 100.0, 17, 200.0, 20, 75, 3, 2)
    tip = placed[0]
    near = None
    if m is not None:
        import numpy as np
        d = np.linalg.norm(np.asarray(m.vertices) - np.array([tip[0], tip[1], zt]), axis=1)
        near = float(np.min(d))
    raw = open(p).read().splitlines() if os.path.exists(p) else []
    nv = sum(1 for ln in raw if ln.startswith('v '))
    nt = sum(1 for ln in raw if ln.startswith('f '))
    close = (bb is not None and want_bb is not None and
             all(abs(a - b) < 1e-6 for a, b in
                 [(bb[0], want_bb[0][0]), (bb[1], want_bb[1][0]), (bb[2], want_bb[0][1]),
                  (bb[3], want_bb[1][1]), (bb[4], want_bb[0][2]), (bb[5], want_bb[1][2])]))
    checks = dict(obj=os.path.exists(p), bbox=close, tip=near is not None and near < 1e-3,
                  verts=nv > 96, tris=nt >= 2 * 32 * 2)
    record('blade.tess', all(checks.values()), mesh_bb=want_bb, tip_near=near, obj_verts=nv,
           obj_tris=nt, **checks)


def blade_step():
    from build123d import import_step
    secs = [NACA(0, 0, 12, 100, 17, i=i + 1) for i in range(2)]
    fresh('p.bcd', *secs, BLADE((1, 2), 50, 0, 100, 3))
    cli('p.bcd', 'step', '3', f'{WORK}/blade.stp')
    p = f'{WORK}/blade.stp'
    s = import_step(p) if os.path.exists(p) else None
    solids = s.solids() if s is not None else []
    faces = s.faces() if s is not None else []
    kinds = sorted(getattr(f.geom_type, 'name', f.geom_type) for f in faces)
    vv = solids[0].volume if len(solids) == 1 else None
    want = OC.float_area(OC.float_ring(0, 0, 12, 100.0, 17)) * 50.0
    checks = dict(step=os.path.exists(p), solids=len(solids) == 1, faces=len(faces) == 34,
                  kinds=kinds == ['BSPLINE'] * 32 + ['PLANE'] * 2,
                  volume=vv is not None and abs(vv - want) / want < 1e-6)
    record('blade.step', all(checks.values()), stp_volume=float(vv) if vv is not None else None,
           kindsample=kinds[:4] + ['...'] if kinds else None, **checks)


def blade_replay():
    secs = [NACA(0, 0, 12, 100, 17, i=i + 1) for i in range(2)]
    fresh('r.bcd', *secs, BLADE((1, 2), 50, 10, 75, 3))
    sh, _ = cli('r.bcd', 'show')
    cli('r2.bcd', 'new')
    nodes = [ln for ln in sh.splitlines() if ln.startswith('(node ')]
    out, _ = cli('r2.bcd', 'apply', *nodes)
    e1, _ = cli('r.bcd', 'eval')
    e2, _ = cli('r2.bcd', 'eval')
    b1, _ = cli('r.bcd', 'blade', '3')
    b2, _ = cli('r2.bcd', 'blade', '3')
    cli('r.bcd', 'archive', '3', f'{WORK}/blade.bin')
    ap = f'{WORK}/blade.bin'
    ro, _ = wsl(BIN, 'geom', 'reopen', ap, '-v')
    m = re.search(r'volume=\[([^,]+), ([^\]]+)\]', ro)
    riv = (float(m.group(1)), float(m.group(2))) if m else None
    want = OC.float_area(OC.float_ring(0, 0, 12, 100.0, 17))
    checks = dict(nodes=len(nodes) == 3, committed='committed' in out, replay=e1 == e2,
                  breplay=b1 == b2,
                  archive=os.path.exists(ap) and os.path.getsize(ap) > 0,
                  reopen=sum(1 for ln in ro.splitlines() if 'loops=' in ln) == 34 and
                  riv is not None and contains(riv, want * 50.0 * 2.3125 / 3.0))
    record('blade.replay', all(checks.values()), **checks)


def blade_sweep():
    edits = [NACA(0, 0, t, 100, 17, i=i + 1) for i, t in enumerate(range(6, 25))]
    out, dt = fresh('w.bcd', *edits)
    ev, _ = cli('w.bcd', 'eval')
    oks = sum(1 for i in range(1, 20) if re.search(rf'node {i}: ok ', ev))
    out2, _ = cli('w.bcd', 'apply', BLADE((1, 1), 50, 0, 100, 20))
    ev2, _ = cli('w.bcd', 'eval')
    thin = OC.float_area(OC.float_ring(0, 0, 6, 100.0, 17))
    checks = dict(committed='committed' in out, all19=oks == 19, sweep_s=round(dt, 2),
                  thin='committed' in out2 and contains(vol(ev2, 20), thin * 50.0))
    record('blade.sweep', all(checks.values()), **checks)


def mcp_parity():
    fresh('m.bcd', NACA(0, 0, 12, 100, 17), NACA(0, 0, 12, 100, 17, i=2), BLADE((1, 2), 50, 0, 100, 3))
    srv = os.path.join(HERE, '..', '..', 'tools', 'mcp', 'bendcad-mcp.mjs')
    msgs = [dict(method='initialize', params=dict(protocolVersion='2024-11-05')),
            dict(method='tools/list'),
            dict(method='tools/call', params=dict(name='blade',
                 arguments=dict(design=f'{WORK}/m.bcd', node=3)))]
    text = ''.join(json.dumps(dict(jsonrpc='2.0', id=i + 1, **m)) + '\n' for i, m in enumerate(msgs))
    r = subprocess.run(['node', srv], input=text, capture_output=True, text=True, timeout=900,
                       env=dict(os.environ, BENDCAD_BIN=BIN))
    rs = {x['id']: x for x in map(json.loads, r.stdout.strip().splitlines())}
    body = lambda i: rs[i]['result']['content'][0]['text']
    names = [t['name'] for t in rs[2]['result']['tools']]
    c_f, _ = cli('m.bcd', 'blade', '3')
    checks = dict(tool='blade' in names, parity=body(3).strip() == c_f.strip())
    record('mcp.parity', all(checks.values()), **checks)


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (section_slab, section_report, blade_twisted, blade_eight, tip_clearance,
              blade_edit, blade_tess, blade_step, blade_replay, blade_sweep, mcp_parity):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} journeys hold")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
