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
WORK = '/tmp/bc-e2e-c161'
RESULTS = []

IC = '(intent create any any any any)'
IA = '(intent add any any any any)'
L, W, T, R, LH = 100.0, 50.0, 2.0, 3.0, 10.0
KLO, KHI = 0.3, 0.5
FLAT = f'(node 1 (flat {L:g} {W:g} {T:g}) {IC})'
B90 = lambda b=1, n=0, r=R, d=90, i=2: f'(node {i} (bend {b} (edge {n}) {r:g} {d}) {IA})'
HEM = lambda b=1, n=0, l=LH, i=2: f'(node {i} (hem {b} (edge {n}) {l:g}) {IA})'

VOL0 = 10128.31853071796
VOL2 = 10756.637061435917
VOL4 = 14756.637061435918
VOL6 = 11000.0
VOL8 = 11128.31853071796
VOL10 = 15756.637061435918
A90 = (5.654866776461623, 6.283185307179592)


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


FLT = r'([0-9.eE+-]+|b:\d+)'


def contains(iv, x):
    return iv is not None and iv[0] <= x <= iv[1]


def vol(out, node):
    m = re.search(rf'node {node}: ok .*?volume=\[([^,]+), ([^\]]+)\]', out)
    return (float(m.group(1)), float(m.group(2))) if m else None


def bbox(out, node):
    m = re.search(rf'node {node}: ok .*?bbox=\[([^,]+), ([^\]]+)\]x\[([^,]+), ([^\]]+)\]x\[([^,]+), ([^\]]+)\]', out)
    return [float(m.group(i)) for i in range(1, 7)] if m else None


def bbox_eq(got, want):
    return got is not None and all(abs(g - w) < 1e-9 for g, w in zip(got, want))


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


def oracle_selftest():
    return (OC.sh_vol(0, L, T, R, W, LH) == VOL0 and OC.sh_vol(2, L, T, R, W, LH) == VOL2 and
            OC.sh_vol(4, L, T, R, W, LH) == VOL4 and OC.sh_vol(6, L, T, R, W, LH) == VOL6 and
            OC.sh_vol(8, L, T, R, W, LH) == VOL8 and OC.sh_vol(10, L, T, R, W, LH) == VOL10 and
            OC.allow(90, R, T, KLO, KHI) == A90 and OC.legs(0, L, T, R, LH) == [50.0, 45.0])


def flat_blank():
    assert oracle_selftest()
    out, dt = fresh('f.bcd', FLAT)
    ev, _ = cli('f.bcd', 'eval')
    chk, _ = cli('f.bcd', 'check', '1')
    fl, _ = cli('f.bcd', 'faces', '1')
    fo, _ = cli('f.bcd', 'flat', '1', str(KLO), str(KHI))
    dv = OC.developed(254, L, T, R, LH, [])
    checks = dict(committed='committed' in out, eval_vol=contains(vol(ev, 1), L * W * T),
                  check=chk.startswith('ok:'), faces=len(face_lines(fl)) == 6,
                  header='flat node 1 bends 0 hems 0' in fo, legs=flat_legs(fo) == [L],
                  dev=flat_field(fo, 'developed') == dv, blank=f'blank {L:g} {W:g}' in fo)
    record('flat.blank', all(checks.values()), **checks)


def bend_single():
    out, dt = fresh('b.bcd', FLAT, B90())
    ev, _ = cli('b.bcd', 'eval')
    chk, _ = cli('b.bcd', 'check', '2')
    fl, _ = cli('b.bcd', 'faces', '2')
    fo, _ = cli('b.bcd', 'flat', '2', str(KLO), str(KHI))
    a90 = OC.allow(90, R, T, KLO, KHI)
    m = re.search(r'bend 0 edge 0 deg 90 r ' + FLT + r' allowance \[(.+?), (.+?)\] certified', fo)
    row = (num(m.group(2)), num(m.group(3))) if m else None
    checks = dict(committed='committed' in out, check=chk.startswith('ok:'),
                  volume=contains(vol(ev, 2), VOL0), faces=len(face_lines(fl)) == 10,
                  cyl=kind_n(face_lines(fl), 'cylinder') == 2,
                  bbox=bbox_eq(bbox(ev, 2), [0.0, 55.0, 0.0, 50.0, 0.0, 50.0]),
                  header='flat node 2 bends 1 hems 0' in fo, allow=row == a90,
                  legs=flat_legs(fo) == [50.0, 45.0],
                  dev=flat_field(fo, 'developed') == OC.developed(0, L, T, R, LH, [a90]))
    record('bend.single90', all(checks.values()), seconds=dt, **checks)


def bend_variants():
    rows = {}
    cases = [('90n0', [FLAT, B90(1, 0)], 2, 10, VOL0, [0.0, 55.0, 0.0, 50.0, 0.0, 50.0]),
             ('90n1', [FLAT, B90(1, 1)], 2, 10, VOL0, [0.0, 55.0, 0.0, 50.0, 0.0, 50.0]),
             ('90n2', [FLAT, B90(1, 2)], 2, 10, VOL0, [0.0, 55.0, 0.0, 50.0, 0.0, 50.0]),
             ('90n3', [FLAT, B90(1, 3)], 2, 10, VOL0, [0.0, 55.0, 0.0, 50.0, 0.0, 50.0]),
             ('180n0', [FLAT, B90(1, 0, R, 180)], 2, 10, VOL2, [0.0, 55.0, 0.0, 10.0, 0.0, 50.0]),
             ('180n1', [FLAT, B90(1, 1, R, 180)], 2, 10, VOL2, [0.0, 55.0, 0.0, 10.0, 0.0, 50.0]),
             ('180n2', [FLAT, B90(1, 2, R, 180)], 2, 10, VOL2, [0.0, 55.0, 0.0, 10.0, 0.0, 50.0]),
             ('180n3', [FLAT, B90(1, 3, R, 180)], 2, 10, VOL2, [0.0, 55.0, 0.0, 10.0, 0.0, 50.0]),
             ('Uup', [FLAT, B90(1, 0), B90(2, 2, R, 90, 3)], 3, 14, VOL4, [0.0, 100.0, 0.0, 27.5, 0.0, 50.0]),
             ('Udn', [FLAT, B90(1, 1), B90(2, 3, R, 90, 3)], 3, 14, VOL4, [0.0, 100.0, 0.0, 27.5, 0.0, 50.0]),
             ('Uswap', [FLAT, B90(1, 2), B90(2, 0, R, 90, 3)], 3, 14, VOL4, [0.0, 100.0, 0.0, 27.5, 0.0, 50.0]),
             ('hemT', [FLAT, HEM(1, 0)], 2, 8, VOL6, [0.0, 100.0, 0.0, 4.0, 0.0, 50.0]),
             ('hemB', [FLAT, HEM(1, 1)], 2, 8, VOL6, [0.0, 100.0, 0.0, 4.0, 0.0, 50.0]),
             ('hem2', [FLAT, HEM(1, 2)], 2, 8, VOL6, [0.0, 100.0, 0.0, 4.0, 0.0, 50.0]),
             ('hem3', [FLAT, HEM(1, 3)], 2, 8, VOL6, [0.0, 100.0, 0.0, 4.0, 0.0, 50.0]),
             ('tipU', [FLAT, B90(1, 0), HEM(2, 0, LH, 3)], 3, 12, VOL8, [0.0, 57.0, 0.0, 50.0, 0.0, 50.0]),
             ('tipD', [FLAT, B90(1, 1), HEM(2, 1, LH, 3)], 3, 12, VOL8, [0.0, 57.0, 0.0, 50.0, 0.0, 50.0]),
             ('tip2', [FLAT, B90(1, 2), HEM(2, 2, LH, 3)], 3, 12, VOL8, [0.0, 57.0, 0.0, 50.0, 0.0, 50.0]),
             ('tip3', [FLAT, B90(1, 3), HEM(2, 3, LH, 3)], 3, 12, VOL8, [0.0, 57.0, 0.0, 50.0, 0.0, 50.0]),
             ('tipUR', [FLAT, B90(1, 0), B90(2, 2, R, 90, 3), HEM(3, 0, LH, 4)], 4, 16, VOL10,
              [0.0, 102.0, 0.0, 27.5, 0.0, 50.0]),
             ('tipUL', [FLAT, B90(1, 0), B90(2, 2, R, 90, 3), HEM(3, 2, LH, 4)], 4, 16, VOL10,
              [0.0, 102.0, 0.0, 27.5, 0.0, 50.0]),
             ('tipUDR', [FLAT, B90(1, 1), B90(2, 3, R, 90, 3), HEM(3, 0, LH, 4)], 4, 16, VOL10,
              [0.0, 102.0, 0.0, 27.5, 0.0, 50.0]),
             ('tipUDL', [FLAT, B90(1, 1), B90(2, 3, R, 90, 3), HEM(3, 2, LH, 4)], 4, 16, VOL10,
              [0.0, 102.0, 0.0, 27.5, 0.0, 50.0])]
    for name, edits, node, faces, volume, box in cases:
        out, _ = fresh(f'v-{name}.bcd', *edits)
        ev, _ = cli(f'v-{name}.bcd', 'eval')
        chk, _ = cli(f'v-{name}.bcd', 'check', str(node))
        fl, _ = cli(f'v-{name}.bcd', 'faces', str(node))
        rows[name] = ('committed' in out and chk.startswith('ok:') and
                      len(face_lines(fl)) == faces and contains(vol(ev, node), volume) and
                      bbox_eq(bbox(ev, node), box))
    record('bend.variants', all(rows.values()), **rows)


def bend_bracket():
    out, dt = fresh('u.bcd', FLAT, B90(), B90(2, 2, R, 90, 3), HEM(3, 0, LH, 4))
    ev, _ = cli('u.bcd', 'eval')
    chk, _ = cli('u.bcd', 'check', '4')
    fl, _ = cli('u.bcd', 'faces', '4')
    fo, _ = cli('u.bcd', 'flat', '4', str(KLO), str(KHI))
    a90 = OC.allow(90, R, T, KLO, KHI)
    rows = re.findall(r'bend \d+ edge \d+ deg 90 r ' + FLT + r' allowance \[(.+?), (.+?)\] certified', fo)
    allows = [(num(a), num(b)) for _, a, b in rows]
    checks = dict(committed='committed' in out, check=chk.startswith('ok:'),
                  volume=contains(vol(ev, 4), VOL10), faces=len(face_lines(fl)) == 16,
                  cyl=kind_n(face_lines(fl), 'cylinder') == 4,
                  bbox=bbox_eq(bbox(ev, 4), [0.0, 102.0, 0.0, 27.5, 0.0, 50.0]),
                  header='flat node 4 bends 2 hems 1' in fo, allows=allows == [a90, a90],
                  hem='hem 0 edge 0 len 10' in fo,
                  legs=flat_legs(fo) == [12.5, 2.0, 10.0, 10.0, 90.0, 22.5],
                  dev=flat_field(fo, 'developed') == OC.developed(10, L, T, R, LH, [a90, a90]))
    record('bend.bracket', all(checks.values()), seconds=dt, **checks)


def bend_hemflat():
    out, dt = fresh('h.bcd', FLAT, HEM())
    ev, _ = cli('h.bcd', 'eval')
    chk, _ = cli('h.bcd', 'check', '2')
    fl, _ = cli('h.bcd', 'faces', '2')
    fo, _ = cli('h.bcd', 'flat', '2', str(KLO), str(KHI))
    checks = dict(committed='committed' in out, check=chk.startswith('ok:'),
                  volume=contains(vol(ev, 2), VOL6), faces=len(face_lines(fl)) == 8,
                  header='flat node 2 bends 0 hems 1' in fo, hem='hem 0 edge 0 len 10' in fo,
                  legs=flat_legs(fo) == [100.0, 2.0, 10.0],
                  dev=flat_field(fo, 'developed') == OC.developed(6, L, T, R, LH, []))
    record('bend.hemflat', all(checks.values()), **checks)


def bend_180():
    out, dt = fresh('f180.bcd', FLAT, B90(1, 0, R, 180))
    ev, _ = cli('f180.bcd', 'eval')
    chk, _ = cli('f180.bcd', 'check', '2')
    fl, _ = cli('f180.bcd', 'faces', '2')
    fo, _ = cli('f180.bcd', 'flat', '2', str(KLO), str(KHI))
    a180 = OC.allow(180, R, T, KLO, KHI)
    m = re.search(r'bend 0 edge 0 deg 180 r ' + FLT + r' allowance \[(.+?), (.+?)\] certified', fo)
    row = (num(m.group(2)), num(m.group(3))) if m else None
    checks = dict(committed='committed' in out, check=chk.startswith('ok:'),
                  volume=contains(vol(ev, 2), VOL2), faces=len(face_lines(fl)) == 10,
                  cyl=kind_n(face_lines(fl), 'cylinder') == 2, allow=row == a180,
                  bbox=bbox_eq(bbox(ev, 2), [0.0, 55.0, 0.0, 10.0, 0.0, 50.0]))
    record('bend.fold180', all(checks.values()), **checks)


def bend_edit():
    fresh('e.bcd', '(param L 100)', '(param T 2)', f'(node 1 (flat L 50 T) {IC})',
          f'(node 2 (bend 1 (edge 0) 3 90) {IA})')
    f0, _ = cli('e.bcd', 'flat', '2', str(KLO), str(KHI))
    v0, _ = cli('e.bcd', 'eval')
    out, _ = cli('e.bcd', 'apply', '(param L 120)')
    f1, _ = cli('e.bcd', 'flat', '2', str(KLO), str(KHI))
    v1, _ = cli('e.bcd', 'eval')
    se, _ = cli('e.bcd', 'sens', 'L', '2')
    sm = re.search(r'd_volume=([^ ]+)', se)
    a90 = OC.allow(90, R, T, KLO, KHI)
    checks = dict(committed='committed' in out,
                  dev0=flat_field(f0, 'developed') == OC.developed(0, L, T, R, LH, [a90]),
                  dev1=flat_field(f1, 'developed') == OC.developed(0, 120.0, T, R, LH, [a90]),
                  vol1=contains(vol(v1, 2), OC.sh_vol(0, 120.0, T, R, W, LH)),
                  legs1=flat_legs(f1) == [60.0, 55.0],
                  sens=bool(sm) and abs(float(sm.group(1)) - 100.0) < 0.01 and 'reused' in se)
    record('bend.edit', all(checks.values()), **checks)


def bend_tess():
    import trimesh
    fresh('t.bcd', FLAT, B90())
    out, _ = cli('t.bcd', 'tess', '2', f'{WORK}/bend.obj')
    p = f'{WORK}/bend.obj'
    m = trimesh.load(p, force='mesh') if os.path.exists(p) else None
    bb = m.bounds.tolist() if m is not None else None
    want = [[0.0, 0.0, 0.0], [55.0, 50.0, 50.0]]
    close = (bb is not None and all(abs(bb[i][j] - want[i][j]) < 0.05 for i in (0, 1) for j in (0, 1, 2)))
    mv = bool(abs(m.volume - VOL0) / VOL0 < 0.01) if m is not None else False
    checks = dict(obj=os.path.exists(p), bbox=close, meshvol=mv, verts=len(m.vertices) > 0 if m is not None else False)
    record('bend.tess', all(checks.values()), mesh_bb=bb, mesh_vol=float(m.volume) if m is not None else None, **checks)


def bend_step():
    from build123d import import_step
    fresh('s.bcd', FLAT, B90(), B90(2, 2, R, 90, 3), HEM(3, 0, LH, 4))
    out, _ = cli('s.bcd', 'step', '4', f'{WORK}/bracket.stp')
    p = f'{WORK}/bracket.stp'
    s = import_step(p) if os.path.exists(p) else None
    solids = s.solids() if s is not None else []
    faces = s.faces() if s is not None else []
    cyl = sum(1 for f in faces if getattr(f.geom_type, 'name', f.geom_type) == 'CYLINDER') if faces else -1
    vv = solids[0].volume if len(solids) == 1 else None
    checks = dict(step=os.path.exists(p), solids=len(solids) == 1, faces=len(faces) == 16, cyl=cyl == 4,
                  volume=vv is not None and abs(vv - VOL10) / VOL10 < 1e-6)
    record('bend.step', all(checks.values()), stp_volume=float(vv) if vv is not None else None, stp_faces=len(faces), stp_cyl=cyl, **checks)


def bend_replay():
    fresh('r.bcd', FLAT, B90(), B90(2, 2, R, 90, 3), HEM(3, 0, LH, 4))
    sh, _ = cli('r.bcd', 'show')
    cli('r2.bcd', 'new')
    nodes = [ln for ln in sh.splitlines() if ln.startswith('(node ')]
    out, _ = cli('r2.bcd', 'apply', *nodes)
    e1, _ = cli('r.bcd', 'eval')
    e2, _ = cli('r2.bcd', 'eval')
    ao, _ = cli('r.bcd', 'archive', '4', f'{WORK}/rBrn.bin')
    ap = f'{WORK}/rBrn.bin'
    ro, _ = wsl(BIN, 'geom', 'reopen', ap, '-v')
    m = re.search(r'volume=\[([^,]+), ([^\]]+)\]', ro)
    riv = (num(m.group(1)), num(m.group(2))) if m else None
    checks = dict(nodes=len(nodes) == 4, committed='committed' in out, replay=e1 == e2,
                  archive=os.path.exists(ap) and os.path.getsize(ap) > 0,
                  reopen=sum(1 for ln in ro.splitlines() if 'loops=' in ln) == 16 and
                  riv is not None and contains(riv, VOL10))
    record('bend.replay', all(checks.values()), **checks)


def mcp_parity():
    fresh('m.bcd', FLAT, B90(), B90(2, 2, R, 90, 3), HEM(3, 0, LH, 4))
    srv = os.path.join(HERE, '..', '..', 'tools', 'mcp', 'bendcad-mcp.mjs')
    msgs = [dict(method='initialize', params=dict(protocolVersion='2024-11-05')),
            dict(method='tools/list'),
            dict(method='tools/call', params=dict(name='flat_pattern',
                 arguments=dict(design=f'{WORK}/m.bcd', node=4, klo=KLO, khi=KHI)))]
    text = ''.join(json.dumps(dict(jsonrpc='2.0', id=i + 1, **m)) + '\n' for i, m in enumerate(msgs))
    r = subprocess.run(['node', srv], input=text, capture_output=True, text=True, timeout=900,
                       env=dict(os.environ, BENDCAD_BIN=BIN))
    rs = {x['id']: x for x in map(json.loads, r.stdout.strip().splitlines())}
    body = lambda i: rs[i]['result']['content'][0]['text']
    names = [t['name'] for t in rs[2]['result']['tools']]
    c_f, _ = cli('m.bcd', 'flat', '4', str(KLO), str(KHI))
    checks = dict(tool='flat_pattern' in names, parity=body(3).strip() == c_f.strip())
    record('mcp.parity', all(checks.values()), **checks)


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (flat_blank, bend_single, bend_variants, bend_bracket, bend_hemflat, bend_180,
              bend_edit, bend_tess, bend_step, bend_replay, mcp_parity):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} journeys hold")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
