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
WORK = '/tmp/bc-e2e-c162'
RESULTS = []

IC = '(intent create any any any any)'
IA = '(intent add any any any any)'
IS = '(intent same any any any any)'


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
SWEEP = lambda deg, r, i=1: (f"(node {i} (sweep-open (arc {deg}) "
                             f"(region (path {r[0]:g} {r[2]:g} (line {r[1]:g} {r[2]:g}) (line {r[1]:g} {r[3]:g}) (line {r[0]:g} {r[3]:g})))) {IC})")
THICK = lambda b, t, i: f'(node {i} (thicken-open {b} {t:g}) {IA})'

BOXLO = (8.0, 0.0, 0.0, 10.0, 5.0, 0.0, 0.0, 10.0, 5.0)
TAPERLO = (8.0, 0.0, 0.0, 10.0, 5.0, 1.0, 1.0, 9.0, 4.0)
SEC = (2.0, 6.0, 0.0, 4.0)


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


def face_lines(text):
    return [ln for ln in text.strip().splitlines() if ln and not ln.startswith('deleted ')]


def kind_n(lines, kind):
    return sum(1 for ln in lines if len(ln.split()) >= 2 and ln.split()[1] == kind)


def surf_field(out, key):
    m = re.search(rf'{key} \[(.+?), (.+?)\] (certified|estimated)', out)
    return (num(m.group(1)), num(m.group(2)), m.group(3)) if m else None


def surf_edges(out):
    return re.findall(r'edge n\d+\.e\d+ len \[(.+?), (.+?)\] (certified|estimated)', out)


def surf_bbox(out):
    m = re.search(r'bbox (\S+) (\S+) (\S+) (\S+) (\S+) (\S+)', out)
    return [num(m.group(i)) for i in range(1, 7)] if m else None


def patch_cowl():
    out, _ = fresh('c.bcd', PATCH(COWL_PTS))
    ev, _ = cli('c.bcd', 'eval')
    fl, _ = cli('c.bcd', 'faces', '1')
    su, _ = cli('c.bcd', 'surf', '1')
    a = surf_field(su, 'area')
    want = OC.patch_area(COWL_PTS)
    checks = dict(committed='committed' in out,
                  header='surf node 1 kind patch faces 1 boundary 4' in su,
                  edges=len(surf_edges(su)) == 4 and all(t == 'estimated' for _, _, t in surf_edges(su)),
                  area=a is not None and abs(a[0] - want) / want < 0.01,
                  blen=surf_field(su, 'blen') is not None,
                  sbbox=surf_bbox(su) == [0.0, 10.0, 0.0, 5.0, 0.0, 0.288],
                  faces=len(face_lines(fl)) == 1, vol=contains(vol(ev, 1), 0.0))
    record('patch.cowl', all(checks.values()), oracle_area=want, **checks)


def patch_slab():
    out, _ = fresh('p.bcd', PATCH(RECT_PTS), THICK(1, 2.0, 2))
    ev, _ = cli('p.bcd', 'eval')
    chk, _ = cli('p.bcd', 'check', '2')
    fl, _ = cli('p.bcd', 'faces', '2')
    lines = face_lines(fl)
    checks = dict(committed='committed' in out, check=chk.startswith('ok:'),
                  vol=contains(vol(ev, 2), 100.0), faces=len(lines) == 6,
                  planes=kind_n(lines, 'plane') == 6, genus=genus(ev, 2) == 0,
                  bbox=bbox(ev, 2) is not None and abs(bbox(ev, 2)[4] + 1.0) < 1e-9 and
                  abs(bbox(ev, 2)[5] - 1.0) < 1e-9)
    record('patch.slab', all(checks.values()), **checks)


def loft_duct():
    out, _ = fresh('d.bcd', LOFT(8.0, (0, 0, 10, 5), (0, 0, 10, 5)))
    su, _ = cli('d.bcd', 'surf', '1')
    a = surf_field(su, 'area')
    b = surf_field(su, 'blen')
    checks = dict(committed='committed' in out,
                  header='surf node 1 kind loft-open faces 4 boundary 8' in su,
                  edges=len(surf_edges(su)) == 8 and all(t == 'certified' for _, _, t in surf_edges(su)),
                  area=a is not None and a[2] == 'certified' and contains((a[0], a[1]), 240.0) and
                  a[1] - a[0] < 1e-9,
                  blen=b is not None and contains((b[0], b[1]), 60.0),
                  sbbox=surf_bbox(su) == [0.0, 10.0, 0.0, 5.0, 0.0, 8.0])
    record('loft.duct', all(checks.values()), **checks)


def loft_taper():
    out, _ = fresh('t.bcd', LOFT(8.0, (0, 0, 10, 5), (1, 1, 9, 4)), THICK(1, 1.0, 2))
    ev, _ = cli('t.bcd', 'eval')
    chk, _ = cli('t.bcd', 'check', '2')
    want = OC.duct_vol(TAPERLO, 1.0)
    lines = [ln for ln in chk.splitlines() if ln]
    bez = (lines and all(ln.startswith('face-check-unsupported') or
                         ln.startswith('face-face-uncertain') for ln in lines))
    checks = dict(committed='committed' in out, check=bez,
                  vol=contains(vol(ev, 2), want), faces=faces_n(ev, 2) == 16,
                  genus=genus(ev, 2) == 1)
    record('loft.taper', all(checks.values()), oracle_vol=want, check_lines=len(lines), **checks)


def sweep_sector():
    out, _ = fresh('s.bcd', SWEEP(90, SEC))
    su, _ = cli('s.bcd', 'surf', '1')
    a = surf_field(su, 'area')
    b = surf_field(su, 'blen')
    want = OC.sector_area(90, *SEC)
    checks = dict(committed='committed' in out,
                  header='surf node 1 kind sweep-open faces 4 boundary 8' in su,
                  edges=len(surf_edges(su)) == 8 and all(t == 'certified' for _, _, t in surf_edges(su)),
                  area=a is not None and contains((a[0], a[1]), want) and a[1] - a[0] < 1e-9,
                  blen=b is not None and contains((b[0], b[1]), 32.0))
    record('sweep.sector', all(checks.values()), oracle_area=want, **checks)


def sweep_thick():
    out, _ = fresh('w.bcd', SWEEP(90, SEC), THICK(1, 1.0, 2))
    ev, _ = cli('w.bcd', 'eval')
    chk, _ = cli('w.bcd', 'check', '2')
    want = OC.sector_vol(90, *SEC, 1.0)
    checks = dict(committed='committed' in out, check=chk.startswith('ok:'),
                  vol=contains(vol(ev, 2), want), faces=faces_n(ev, 2) == 16,
                  genus=genus(ev, 2) == 1)
    record('sweep.thick', all(checks.values()), oracle_vol=want, **checks)


def surf_edit():
    fresh('e.bcd', '(param W 10)', '(param PX 0)',
          LOFT(8.0, (0, 0, 10, 5), (0, 0, 10, 5)),
          '(node 2 (patch (pt PX 0 0) (pt 4 0 0) (pt 6 0 0) (pt 10 0 0) '
          '(pt PX 2 0) (pt 4 2 0) (pt 6 2 0) (pt 10 2 0) '
          '(pt PX 3 0) (pt 4 3 0) (pt 6 3 0) (pt 10 3 0) '
          '(pt PX 5 0) (pt 4 5 0) (pt 6 5 0) (pt 10 5 0)) (intent create any any any any))')
    s0, _ = cli('e.bcd', 'surf', '2')
    out, _ = cli('e.bcd', 'apply', '(param PX 2)')
    s1, _ = cli('e.bcd', 'surf', '2')
    checks = dict(committed='committed' in out,
                  sbbox0=surf_bbox(s0) is not None and surf_bbox(s0)[0] == 0.0,
                  sbbox1=surf_bbox(s1) is not None and surf_bbox(s1)[0] == 2.0,
                  changed=s0 != s1)
    record('surf.edit', all(checks.values()), **checks)


def surf_tess():
    import trimesh
    fresh('t.bcd', PATCH(COWL_PTS))
    out, _ = cli('t.bcd', 'tess', '1', f'{WORK}/cowl.obj')
    p = f'{WORK}/cowl.obj'
    m = trimesh.load(p, force='mesh') if os.path.exists(p) else None
    bb = m.bounds.tolist() if m is not None else None
    crown = OC.patch_center(COWL_PTS)
    flat = [[0.0, 0.0], [10.0, 5.0]]
    close = (bb is not None and all(abs(bb[i][j] - flat[i][j]) < 1e-9 for i in (0, 1) for j in (0, 1)))
    top = bb is not None and abs(bb[1][2] - crown) < 0.005 and abs(bb[0][2]) < 1e-9
    raw = open(p).read().splitlines() if os.path.exists(p) else []
    nv = sum(1 for ln in raw if ln.startswith('v '))
    nt = sum(1 for ln in raw if ln.startswith('f '))
    checks = dict(obj=os.path.exists(p), bbox=close, crown=top, verts=nv > 81, tris=nt >= 128)
    record('surf.tess', all(checks.values()), mesh_bb=bb, oracle_crown=crown, obj_verts=nv,
           obj_tris=nt, **checks)


def surf_step():
    from build123d import import_step
    fresh('s.bcd', PATCH(RECT_PTS), THICK(1, 2.0, 2),
          LOFT(8.0, (0, 0, 10, 5), (1, 1, 9, 4), i=3), THICK(3, 1.0, 4))
    cli('s.bcd', 'step', '2', f'{WORK}/slab.stp')
    cli('s.bcd', 'step', '4', f'{WORK}/duct.stp')
    p, q = f'{WORK}/slab.stp', f'{WORK}/duct.stp'
    s = import_step(p) if os.path.exists(p) else None
    d = import_step(q) if os.path.exists(q) else None
    solids = s.solids() if s is not None else []
    faces = s.faces() if s is not None else []
    dfaces = d.faces() if d is not None else []
    kinds = [getattr(f.geom_type, 'name', f.geom_type) for f in dfaces]
    vv = solids[0].volume if len(solids) == 1 else None
    dv = d.solids()[0].volume if d is not None and len(d.solids()) == 1 else None
    want = OC.duct_vol(TAPERLO, 1.0)
    checks = dict(slab=os.path.exists(p), solids=len(solids) == 1, faces=len(faces) == 6,
                  volume=vv is not None and abs(vv - 100.0) / 100.0 < 1e-6,
                  duct=os.path.exists(q),
                  dkinds=sorted(kinds) == ['BSPLINE'] * 8 + ['PLANE'] * 8,
                  dvol=dv is not None and abs(dv - want) / want < 1e-6)
    record('surf.step', all(checks.values()), stp_volume=float(vv) if vv is not None else None,
           duct_faces=len(dfaces), duct_kinds=sorted(kinds), **checks)


def surf_replay():
    fresh('r.bcd', LOFT(8.0, (0, 0, 10, 5), (0, 0, 10, 5)), THICK(1, 1.0, 2))
    sh, _ = cli('r.bcd', 'show')
    cli('r2.bcd', 'new')
    nodes = [ln for ln in sh.splitlines() if ln.startswith('(node ')]
    out, _ = cli('r2.bcd', 'apply', *nodes)
    e1, _ = cli('r.bcd', 'eval')
    e2, _ = cli('r2.bcd', 'eval')
    ao, _ = cli('r.bcd', 'archive', '2', f'{WORK}/rTube.bin')
    ap = f'{WORK}/rTube.bin'
    ro, _ = wsl(BIN, 'geom', 'reopen', ap, '-v')
    m = re.search(r'volume=\[([^,]+), ([^\]]+)\]', ro)
    riv = (float(m.group(1)), float(m.group(2))) if m else None
    want = OC.duct_vol(BOXLO, 1.0)
    checks = dict(nodes=len(nodes) == 2, committed='committed' in out, replay=e1 == e2,
                  archive=os.path.exists(ap) and os.path.getsize(ap) > 0,
                  reopen=sum(1 for ln in ro.splitlines() if 'loops=' in ln) == 16 and
                  riv is not None and contains(riv, want))
    record('surf.replay', all(checks.values()), oracle_vol=want, **checks)


def union_export():
    from build123d import import_step
    fresh('u.bcd', PATCH(RECT_PTS), THICK(1, 2.0, 2),
          f'(node 3 (move 2 0 0 20 0) {IS})',
          '(node 4 (union 2 3) (intent add any any any any))')
    ev, _ = cli('u.bcd', 'eval')
    m = re.search(r'node 4: ok .*?solids=(\d+)', ev)
    cli('u.bcd', 'step', '4', f'{WORK}/pair.stp')
    p = f'{WORK}/pair.stp'
    s = import_step(p) if os.path.exists(p) else None
    solids = s.solids() if s is not None else []
    checks = dict(solids=m is not None and m.group(1) == '2',
                  step=len(solids) == 2)
    record('union.export', all(checks.values()), **checks)


def mcp_parity():
    fresh('m.bcd', LOFT(8.0, (0, 0, 10, 5), (0, 0, 10, 5)))
    srv = os.path.join(HERE, '..', '..', 'tools', 'mcp', 'bendcad-mcp.mjs')
    msgs = [dict(method='initialize', params=dict(protocolVersion='2024-11-05')),
            dict(method='tools/list'),
            dict(method='tools/call', params=dict(name='surface',
                 arguments=dict(design=f'{WORK}/m.bcd', node=1)))]
    text = ''.join(json.dumps(dict(jsonrpc='2.0', id=i + 1, **m)) + '\n' for i, m in enumerate(msgs))
    r = subprocess.run(['node', srv], input=text, capture_output=True, text=True, timeout=900,
                       env=dict(os.environ, BENDCAD_BIN=BIN))
    rs = {x['id']: x for x in map(json.loads, r.stdout.strip().splitlines())}
    body = lambda i: rs[i]['result']['content'][0]['text']
    names = [t['name'] for t in rs[2]['result']['tools']]
    c_f, _ = cli('m.bcd', 'surf', '1')
    checks = dict(tool='surface' in names, parity=body(3).strip() == c_f.strip())
    record('mcp.parity', all(checks.values()), **checks)


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (patch_cowl, patch_slab, loft_duct, loft_taper, sweep_sector, sweep_thick,
              surf_edit, surf_tess, surf_step, surf_replay, union_export, mcp_parity):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} journeys hold")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
