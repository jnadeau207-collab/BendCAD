import json
import math
import os
import re
import subprocess
import sys
import time
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-c12'
OUT = os.path.join(HERE, 'e2e-report.json')
PI = math.pi
RESULTS = []

ORACLE = {'box': '/tmp/oracle_box.step', 'hole': '/tmp/oracle_hole.step',
          'multi': '/tmp/oracle_multi.step'}


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    out, dt = wsl(BIN, f'{WORK}/{design}', *args)
    return out, dt


def geom(*args):
    out, dt = wsl(BIN, 'geom', *args)
    return out, dt


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if k != 'detail'})


def contains(iv, x):
    return iv is not None and iv[0] <= x <= iv[1]


def vol_of(s):
    m = re.search(r'volume=\[([^,]+), ([^\]]+)\]', s)
    return (float(m.group(1)), float(m.group(2))) if m else None


def solids_of(s):
    m = re.findall(r'solids=(\d+)', s)
    return int(m[-1]) if m else None


def step_info(path):
    from build123d import import_step, GeomType
    sh = import_step(path)
    solids = sh.solids() if hasattr(sh, 'solids') else [sh]
    vols = [s.volume for s in solids]
    faces = [f for s in solids for f in s.faces()]
    kinds = sorted(set(str(f.geom_type) for f in faces))
    bb = sh.bounding_box()
    return dict(nsol=len(solids), vols=vols, nfaces=len(faces), kinds=kinds,
                bbox=(bb.min.X, bb.min.Y, bb.min.Z, bb.max.X, bb.max.Y, bb.max.Z),
                valid=all(s.is_valid for s in solids))


def mesh_info(path):
    import trimesh
    m = trimesh.load(path, force='mesh')
    return dict(vol=float(m.volume), bounds=[float(x) for x in m.bounds.flatten()],
                watertight=bool(m.is_watertight), nfaces=int(len(m.faces)))


IC = '(intent create any any any any)'


def step_box():
    fresh('b.bcd', f'(node 1 (box 10 10 10) {IC})')
    o, dt = cli('b.bcd', 'step', '1', f'{WORK}/box.step')
    ok = o.startswith('wrote ') and os.path.exists(f'{WORK}/box.step')
    txt = open(f'{WORK}/box.step').read()
    units = 'SI_UNIT(.MILLI.,.METRE.)' in txt
    ents = re.search(r'entities (\d+) products (\d+)', o)
    info = step_info(f'{WORK}/box.step') if ok else None
    good = (info is not None and info['nsol'] == 1 and abs(info['vols'][0] - 1000.0) < 1e-6
            and info['nfaces'] == 6 and info['kinds'] == ['GeomType.PLANE'] and info['valid']
            and all(abs(a - b) < 1e-6 for a, b in zip(info['bbox'], (0, 0, 0, 10, 10, 10))))
    record('step.box', ok and units and good and ents is not None and ents.group(2) == '1',
           entities=ents.group(1) if ents else None, oracle=info, seconds=round(dt, 2))


def step_hole():
    fresh('h.bcd', f'(node 1 (box 10 10 10) {IC})',
          '(node 2 (holes 1 (face 1 0 top) through (hole 5 5 2)) (intent remove 1 2 1 1))')
    o, dt = cli('h.bcd', 'step', '2', f'{WORK}/hole.step')
    ok = o.startswith('wrote ')
    info = step_info(f'{WORK}/hole.step') if ok else None
    exp = 1000.0 - PI * 4 * 10
    good = (info is not None and info['nsol'] == 1 and abs(info['vols'][0] - exp) < 1e-4
            and 'GeomType.CYLINDER' in info['kinds'] and info['valid'])
    record('step.hole', ok and good, oracle=info, expect=exp, seconds=round(dt, 2))


def step_curved():
    fresh('s.bcd', f'(node 1 (sphere 10) {IC})')
    o, dt = cli('s.bcd', 'step', '1', f'{WORK}/sphere.step')
    ok = o.startswith('wrote ')
    info = step_info(f'{WORK}/sphere.step') if ok else None
    exp = 4 / 3 * PI * 1000
    gs = (info is not None and info['nsol'] == 1 and abs(info['vols'][0] - exp) < 1e-3
          and info['kinds'] == ['GeomType.SPHERE'] and info['valid'])
    record('step.sphere', ok and gs, oracle=info, expect=exp, seconds=round(dt, 2))
    fresh('t.bcd', f'(node 1 (torus 30 10) {IC})')
    o, dt = cli('t.bcd', 'step', '1', f'{WORK}/torus.step')
    ok = o.startswith('wrote ')
    info = step_info(f'{WORK}/torus.step') if ok else None
    exp = 2 * PI * PI * 30 * 100
    gt = (info is not None and info['nsol'] == 1 and abs(info['vols'][0] - exp) < 1e-2
          and info['kinds'] == ['GeomType.TORUS'] and info['valid'])
    record('step.torus', ok and gt, oracle=info, expect=exp, seconds=round(dt, 2))


def counts_of(s):
    m = re.search(r'vertices=(\d+) edges=(\d+) faces=(\d+)', s)
    return (int(m.group(1)), int(m.group(2)), int(m.group(3))) if m else None


def arc_roundtrip():
    fresh('a.bcd', f'(node 1 (box 10 10 10) {IC})')
    m, _ = cli('a.bcd', 'measure', '1')
    o, _ = cli('a.bcd', 'archive', '1', f'{WORK}/box.bca', 'shoebox demo')
    ok = o.startswith('wrote ') and os.path.exists(f'{WORK}/box.bca')
    head = open(f'{WORK}/box.bca').read()[:24]
    r, _ = geom('reopen', f'{WORK}/box.bca')
    same = (counts_of(m) == counts_of(r) == (8, 12, 6) and contains(vol_of(r), 1000.0)
            and 'units mm' in r and 'lineage shoebox demo' in r)
    rv, _ = geom('reopen', f'{WORK}/box.bca', '-v')
    faces = rv.count(' plane loops=') if same else 0
    record('arc.box', ok and head == 'BCAD1|mm|shoebox demo|B1' and same and faces == 6,
           head=head, vol=vol_of(r), faces=faces)
    fresh('as.bcd', f'(node 1 (sphere 10) {IC})')
    m, _ = cli('as.bcd', 'measure', '1')
    cli('as.bcd', 'archive', '1', f'{WORK}/sphere.bca', '')
    r, _ = geom('reopen', f'{WORK}/sphere.bca')
    rv, _ = geom('reopen', f'{WORK}/sphere.bca', '-v')
    ok = (counts_of(m) == counts_of(r) and contains(vol_of(r), 4 / 3 * PI * 1000)
          and ' sphere loops=' in rv and 'lineage  |' in r)
    record('arc.sphere', ok, vol=vol_of(r))


def imp_oracle():
    for name in ('box', 'hole'):
        exp = step_info(ORACLE[name])
        o, dt = geom('step_import', ORACLE[name], f'{WORK}/imp-{name}.bca')
        v = vol_of(o)
        saved = os.path.exists(f'{WORK}/imp-{name}.bca')
        good = (o.startswith('imported ') and v is not None and saved
                and all(contains(v, x) for x in exp['vols']))
        record(f'imp.{name}', good, vol=v, expect=exp['vols'], nfaces=exp['nfaces'],
               seconds=round(dt, 2))


def imp_multi():
    exp = step_info(ORACLE['multi'])
    o, dt = geom('step_import', ORACLE['multi'], f'{WORK}/imp-multi.bca')
    v = vol_of(o)
    ns = solids_of(o)
    r, _ = geom('reopen', f'{WORK}/imp-multi.bca')
    s, _ = geom('step_of', f'{WORK}/imp-multi.bca', f'{WORK}/multi2.step')
    back = step_info(f'{WORK}/multi2.step') if s.startswith('wrote ') else None
    ok = (o.startswith('imported ') and ns == 2 and v is not None
          and contains(v, sum(exp['vols'])) and 'solids=2' in r
          and back is not None and back['nsol'] == 2
          and all(abs(a - 1000.0) < 1e-6 for a in back['vols']))
    record('imp.multi', ok, vol=v, expect=exp['vols'], back=back, seconds=round(dt, 2))


def stl_box():
    fresh('l.bcd', f'(node 1 (box 10 10 10) {IC})')
    o, dt = cli('l.bcd', 'stl', '1', f'{WORK}/box.stl', '1')
    ok = o.startswith('wrote ') and '(sampled, not certified)' in o
    info = mesh_info(f'{WORK}/box.stl') if ok else None
    good = (info is not None and info['watertight'] and abs(info['vol'] - 1000.0) < 1e-6
            and info['nfaces'] == 12)
    record('stl.box', ok and good, mesh=info, seconds=round(dt, 2))
    txt = open(f'{WORK}/box.stl').read()
    record('stl.text', txt.startswith('solid bendcad\n') and txt.endswith('endsolid bendcad\n')
           and txt.count('facet normal') == 12)


def mf3_box():
    fresh('f.bcd', f'(node 1 (box 10 10 10) {IC})')
    o, dt = cli('f.bcd', '3mf', '1', f'{WORK}/box.3mf', '1')
    ok = o.startswith('wrote ') and '(sampled, not certified)' in o
    names = []
    crc_ok = False
    if ok:
        zf = zipfile.ZipFile(f'{WORK}/box.3mf')
        names = sorted(zf.namelist())
        crc_ok = zf.testzip() is None
        model = zf.read('3D/3dmodel.model').decode()
    info = mesh_info(f'{WORK}/box.3mf') if ok else None
    good = (info is not None and info['watertight'] and abs(info['vol'] - 1000.0) < 1e-6
            and names == ['3D/3dmodel.model', '[Content_Types].xml', '_rels/.rels'] and crc_ok
            and 'unit="millimeter"' in model)
    record('mf3.box', ok and good, mesh=info, parts=names, seconds=round(dt, 2))


def mesh_of():
    fresh('o.bcd', f'(node 1 (box 10 10 10) {IC})')
    cli('o.bcd', 'archive', '1', f'{WORK}/o.bca', '')
    o, _ = geom('stl_of', f'{WORK}/o.bca', f'{WORK}/o.stl', '1')
    s_ok = o.startswith('wrote ')
    info = mesh_info(f'{WORK}/o.stl') if s_ok else None
    record('stl.of', s_ok and info is not None and abs(info['vol'] - 1000.0) < 1e-6, mesh=info)
    o, _ = geom('3mf_of', f'{WORK}/o.bca', f'{WORK}/o.3mf', '1')
    m_ok = o.startswith('wrote ')
    info = mesh_info(f'{WORK}/o.3mf') if m_ok else None
    record('mf3.of', m_ok and info is not None and abs(info['vol'] - 1000.0) < 1e-6, mesh=info)
    o, _ = geom('step_of', f'{WORK}/o.bca', f'{WORK}/o.step')
    back = step_info(f'{WORK}/o.step') if o.startswith('wrote ') else None
    record('step.of', back is not None and abs(back['vols'][0] - 1000.0) < 1e-6, oracle=back)


def mcp_parity():
    fresh('p.bcd', f'(node 1 (box 10 10 10) {IC})')
    cli('p.bcd', 'archive', '1', f'{WORK}/p.bca', 'mcp')
    srv = os.path.join(HERE, '..', '..', 'tools', 'mcp', 'bendcad-mcp.mjs')
    msgs = [dict(method='initialize', params=dict(protocolVersion='2024-11-05')),
            dict(method='tools/list'),
            dict(method='tools/call', params=dict(name='step_export',
                 arguments=dict(design=f'{WORK}/p.bcd', node=1, out=f'{WORK}/m.step'))),
            dict(method='tools/call', params=dict(name='archive',
                 arguments=dict(design=f'{WORK}/p.bcd', node=1, out=f'{WORK}/m.bca', lineage='mcp'))),
            dict(method='tools/call', params=dict(name='reopen',
                 arguments=dict(file=f'{WORK}/m.bca'))),
            dict(method='tools/call', params=dict(name='step_of',
                 arguments=dict(file=f'{WORK}/m.bca', out=f'{WORK}/m2.step'))),
            dict(method='tools/call', params=dict(name='step_import',
                 arguments=dict(file=ORACLE['box']))),
            dict(method='tools/call', params=dict(name='stl_export',
                 arguments=dict(design=f'{WORK}/p.bcd', node=1, out=f'{WORK}/m.stl', preset=1))),
            dict(method='tools/call', params=dict(name='threemf_export',
                 arguments=dict(design=f'{WORK}/p.bcd', node=1, out=f'{WORK}/m.3mf', preset=1))),
            dict(method='tools/call', params=dict(name='stl_of',
                 arguments=dict(file=f'{WORK}/m.bca', out=f'{WORK}/m2.stl', preset=1))),
            dict(method='tools/call', params=dict(name='threemf_of',
                 arguments=dict(file=f'{WORK}/m.bca', out=f'{WORK}/m2.3mf', preset=1)))]
    text = ''.join(json.dumps(dict(jsonrpc='2.0', id=i + 1, **m)) + '\n' for i, m in enumerate(msgs))
    r = subprocess.run(['node', srv], input=text, capture_output=True, text=True, timeout=900,
                       env=dict(os.environ, BENDCAD_BIN=BIN))
    rs = {x['id']: x for x in map(json.loads, r.stdout.strip().splitlines())}
    body = lambda i: rs[i]['result']['content'][0]['text']
    names = [t['name'] for t in rs[2]['result']['tools']]
    have = all(n in names for n in ('step_export', 'step_import', 'archive', 'reopen', 'step_of',
                                    'stl_export', 'stl_of', 'threemf_export', 'threemf_of'))
    c_step, _ = cli('p.bcd', 'step', '1', f'{WORK}/c.step')
    c_arc, _ = cli('p.bcd', 'archive', '1', f'{WORK}/c.bca', 'mcp')
    c_re, _ = geom('reopen', f'{WORK}/m.bca')
    c_so, _ = geom('step_of', f'{WORK}/m.bca', f'{WORK}/c2.step')
    c_si, _ = geom('step_import', ORACLE['box'])
    c_st, _ = cli('p.bcd', 'stl', '1', f'{WORK}/c.stl', '1')
    c_mf, _ = cli('p.bcd', '3mf', '1', f'{WORK}/c.3mf', '1')
    c_s2, _ = geom('stl_of', f'{WORK}/m.bca', f'{WORK}/c2.stl', '1')
    c_m2, _ = geom('3mf_of', f'{WORK}/m.bca', f'{WORK}/c2.3mf', '1')
    outs = [(body(3), c_step, 'm.step', 'c.step'), (body(4), c_arc, 'm.bca', 'c.bca'),
            (body(5), c_re, None, None), (body(6), c_so, 'm2.step', 'c2.step'),
            (body(7), c_si, None, None), (body(8), c_st, 'm.stl', 'c.stl'),
            (body(9), c_mf, 'm.3mf', 'c.3mf'), (body(10), c_s2, 'm2.stl', 'c2.stl'),
            (body(11), c_m2, 'm2.3mf', 'c2.3mf')]
    same = True
    for bt, ct, mf, cf in outs:
        if bt.strip() != ct.strip().replace(cf or '', mf or ''):
            same = False
    record('mcp.parity', have and same and all('isError' not in rs[i] or not rs[i].get('isError')
           for i in range(3, 12)), tools=have, text_match=same)


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (step_box, step_hole, step_curved, arc_roundtrip, imp_oracle, imp_multi, stl_box,
              mf3_box, mesh_of, mcp_parity):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} passed")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
