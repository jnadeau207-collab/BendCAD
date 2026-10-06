import hashlib
import json
import math
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools', 'grade'))
from mesh import check, load_obj

BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e'
OUT = os.path.join(HERE, 'e2e-report.json')
PI = math.pi


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    out, dt = wsl(BIN, f'{WORK}/{design}', *args)
    return out, dt


def read(design):
    return wsl('cat', f'{WORK}/{design}')[0]


def fetch_obj(path):
    out, _ = wsl('cat', path)
    local = os.path.join(HERE, 'e2e-meshes', os.path.basename(path))
    os.makedirs(os.path.dirname(local), exist_ok=True)
    open(local, 'w', newline='\n').write(out)
    return local


def vol(out, node):
    m = re.search(rf'node {node}: ok .*?volume=\[([^,]+), ([^\]]+)\]', out)
    return (float(m.group(1)), float(m.group(2))) if m else None


def bbox(out, node):
    m = re.search(rf'node {node}: ok .*?bbox=\[([^,]+), ([^\]]+)\]x\[([^,]+), ([^\]]+)\]x\[([^,]+), ([^\]]+)\]', out)
    return [float(m.group(i)) for i in range(1, 7)] if m else None


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


RESULTS = []


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if k != 'detail'})


def contains(iv, x):
    return iv is not None and iv[0] <= x <= iv[1]


def mesh_ok(path, genus, v_exact, tol, euler=None):
    local = fetch_obj(path)
    mc = check(*load_obj(local))
    rel = abs(mc['volume'] - v_exact) / v_exact
    want = 2 - 2 * genus if euler is None else euler
    good = mc['watertight'] and mc['euler_characteristic'] == want and rel < tol
    return good, dict(triangles=mc['triangles'], watertight=mc['watertight'], euler=mc['euler_characteristic'],
                      mesh_volume=mc['volume'], rel_err=rel,
                      sha256=hashlib.sha256(open(local, 'rb').read()).hexdigest())


def bracket():
    rr = '(path R 0 (line (- W R) 0) (arc (- W R) R R W R ccw) (line W (- H R)) (arc (- W R) (- H R) R (- W R) H ccw) (line R H) (arc R (- H R) R 0 (- H R) ccw) (line 0 R) (arc R R R R 0 ccw))'
    out, dt = fresh('bracket.bcd', '(param W 120 119.9 120.1)', '(param H 80)', '(param T 8)', '(param R 10)', '(param D 8)', '(param E 12)',
                    '(param B 40)', '(param P 12)', '(param C 20)',
                    f'(node 1 (prism 0 T (region {rr})) (intent create 10 0 1 0))',
                    '(node 2 (holes 1 (face 1 0 top) through (hole E E (/ D 2)) (hole (- W E) E (/ D 2)) (hole E (- H E) (/ D 2)) (hole (- W E) (- H E) (/ D 2))) (intent remove 4 2 1 4))',
                    '(node 3 (pad 2 (face 1 0 top) P (region (circle (/ W 2) (/ H 2) (/ B 2)))) (intent add 2 1 1 4))',
                    '(node 4 (holes 3 (face 3 0 top) through (hole (/ W 2) (/ H 2) (/ C 2))) (intent remove 1 2 1 5))')

    def exact(W):
        return (W * 80 - (4 - PI) * 100 - 4 * PI * 16) * 8 + PI * 400 * 12 - PI * 100 * 20

    record('bracket.build', 'committed' in out and contains(vol(out, 4), exact(120)), volume=vol(out, 4), exact=exact(120), seconds=dt)
    text1 = read('bracket.bcd')
    out2, _ = cli('bracket.bcd', 'eval')
    record('bracket.reopen', vol(out2, 4) == vol(out, 4), volume=vol(out2, 4))
    cli('bracket.bcd', 'apply', '(param W 120 119.9 120.1)')
    record('bracket.serialize_stable', read('bracket.bcd') == text1)
    s, _ = cli('bracket.bcd', 'sens', 'W', '4')
    m = re.search(r'd_volume=([^ ]+)', s)
    record('bracket.sensitivity', m is not None and abs(float(m.group(1)) - 640) < 1e-3, d_volume=m and float(m.group(1)))
    sc, _ = cli('bracket.bcd', 'sens', 'C', '4')
    m = re.search(r'd_volume=([^ ]+).*reused (\d+) of (\d+) nodes', sc)
    record('bracket.sensitivity_reuses_cache', m is not None and abs(float(m.group(1)) + PI * 10 * 20) < 1e-3 and m.group(2) == '3' and m.group(3) == '4',
           out=sc.strip())
    faces, _ = cli('bracket.bcd', 'faces', '4')
    record('bracket.faces', len(faces.strip().splitlines()) == 17 and 'n4.c0.wall.0.0 cylinder' in faces, count=len(faces.strip().splitlines()))
    out3, _ = cli('bracket.bcd', 'apply', '(param W 140)')
    record('bracket.edit', 'committed' in out3 and contains(vol(out3, 4), exact(140)), volume=vol(out3, 4), exact=exact(140))
    cli('bracket.bcd', 'tess', '4', f'{WORK}/bracket.obj')
    good, info = mesh_ok(f'{WORK}/bracket.obj', 5, exact(140), 0.01)
    record('bracket.mesh', good, **info)
    out4, _ = cli('bracket.bcd', 'apply', '(delete 4)')
    record('bracket.delete', 'committed' in out4 and 'node 4' not in out4 and contains(vol(out4, 3), exact(140) + PI * 100 * 20),
           volume=vol(out4, 3), exact=exact(140) + PI * 100 * 20)


def primitives():
    cases = [('box', '(node 1 (box 10 20 30) (intent create 6 0 1 0))', 6000.0, 0),
             ('cylinder', '(node 1 (cylinder 5 12) (intent create 3 0 1 0))', PI * 25 * 12, 0),
             ('cone', '(node 1 (cone 10 20) (intent create 4 0 1 0))', PI * 100 * 20 / 3, 0),
             ('sphere', '(node 1 (sphere 10) (intent create 2 0 1 0))', 4 / 3 * PI * 1000, 0),
             ('torus', '(node 1 (torus 30 10) (intent create 8 0 1 1))', 2 * PI * PI * 30 * 100, 1)]
    for name, node, v, g in cases:
        out, dt = fresh(f'{name}.bcd', node)
        record(f'primitive.{name}', 'committed' in out and contains(vol(out, 1), v), volume=vol(out, 1), exact=v, seconds=dt)
        cli(f'{name}.bcd', 'tess', '1', f'{WORK}/{name}.obj')
        good, info = mesh_ok(f'{WORK}/{name}.obj', g, v, 0.02)
        record(f'primitive.{name}.mesh', good, **info)


def revolve_cavity():
    out, _ = fresh('cav.bcd', '(node 1 (revolve (region (path 0 0 (line 40 0) (line 40 30) (line 0 30)) (circle 20 15 5))) (intent create 14 0 1 1))')
    v = PI * 1600 * 30 - 2 * PI * 20 * PI * 25
    record('revolve.cavity', 'committed' in out and contains(vol(out, 1), v), volume=vol(out, 1), exact=v)
    cli('cav.bcd', 'tess', '1', f'{WORK}/cav.obj')
    local = fetch_obj(f'{WORK}/cav.obj')
    mc = check(*load_obj(local))
    record('revolve.cavity.mesh', mc['watertight'] and mc['euler_characteristic'] == 2 and abs(mc['volume'] - v) / v < 0.02,
           euler=mc['euler_characteristic'], mesh_volume=mc['volume'])


def counterbore_island():
    out, _ = fresh('cb.bcd', '(node 1 (box 60 40 10) (intent create 6 0 1 0))',
                   '(node 2 (pocket 1 (face 1 0 top) 4 (region (circle 30 20 8))) (intent remove 2 1 1 0))',
                   '(node 3 (holes 2 (face 2 0 top) through (hole 30 20 4)) (intent remove 1 2 1 1))')
    v = 60 * 40 * 10 - PI * 64 * 4 - PI * 16 * 6
    record('feature.counterbore', 'committed' in out and contains(vol(out, 3), v), volume=vol(out, 3), exact=v)
    cli('cb.bcd', 'tess', '3', f'{WORK}/cb.obj')
    good, info = mesh_ok(f'{WORK}/cb.obj', 1, v, 0.02)
    record('feature.counterbore.mesh', good, **info)
    out, _ = fresh('isl.bcd', '(node 1 (prism 0 5 (region (path 0 0 (line 50 0) (line 50 50) (line 0 50)) (circle 25 25 15)) (region (circle 25 25 5))) (intent create 10 0 2 1))')
    v = (2500 - PI * 225 + PI * 25) * 5
    record('feature.island', 'committed' in out and contains(vol(out, 1), v), volume=vol(out, 1), exact=v)
    cli('isl.bcd', 'tess', '1', f'{WORK}/isl.obj')
    good, info = mesh_ok(f'{WORK}/isl.obj', 0, v, 0.02, euler=2)
    record('feature.island.mesh', good, **info)


def move():
    out, _ = fresh('mv.bcd', '(node 1 (box 10 20 30) (intent create 6 0 1 0))', '(node 2 (move 1 100 0 0 1) (intent same 0 0 1 0))')
    b = bbox(out, 2)
    record('move.rotate_translate', b is not None and abs(b[0] - 80) < 1e-9 and abs(b[1] - 100) < 1e-9 and abs(b[3] - 10) < 1e-9, bbox=b)


def atomic_rejections():
    fresh('rej.bcd', '(node 1 (box 10 20 30) (intent create 6 0 1 0))')
    before = read('rej.bcd')
    bad = ['(node 2 (holes 1 (face 1 0 top) through (hole 9.5 10 1)) (intent remove 1 2 1 1))',
           '(node 2 (holes 1 (face 1 0 top) through (hole 5 10 1)) (intent add 1 2 1 1))',
           '(node 2 (pocket 1 (face 1 0 top) 30 (region (circle 5 10 2))) (intent remove any any 1 any))',
           '(node 2 (prism 0 1 (region (path 0 0 (line 10 10) (line 10 0) (line 0 10)))) (intent create any 0 1 0))',
           '(node 2 (revolve (region (path -1 0 (line 5 0) (line 5 5) (line -1 5)))) (intent create any 0 1 0))',
           '(node 2 (holes 7 (face 7 0 top) through (hole 5 10 1)) (intent remove any any 1 any))',
           '(node 2 (sphere 10) (intent create any any 1 any)) (node 3 (holes 2 (face 2 0 top) through (hole 0 0 1)) (intent remove any any 1 any))',
           '(node 2 (holes 1 (face 9 0 top) through (hole 5 10 1)) (intent remove any any 1 any))',
           '(node 2 (holes 1 (face 1 0 top) through (hole 5 10 2)) (intent remove 1 2 1 1)) (node 3 (pad 2 (face 1 0 top) 5 (region (circle 5 10 3))) (intent add any any 1 any))']
    whys = ['curves-cross-or-touch', 'declared material=add', 'depth-reaches-opposite-face', 'curves-cross-or-touch',
            'profile-crosses-revolve-axis', 'input-node-missing-or-failed', 'features-need-an-extruded-body', 'face-not-found',
            'footprint-contains-or-meets-existing-feature']
    for i, e in enumerate(bad):
        out, _ = cli('rej.bcd', 'apply', e)
        record(f'reject.{i}', 'rejected' in out and whys[i] in out and read('rej.bcd') == before, why=re.findall(r'why: ([^|]+)', out)[-1:])


def rotation():
    c30, s30, c45, s45 = math.cos(math.radians(30)), math.sin(math.radians(30)), math.cos(math.radians(45)), math.sin(math.radians(45))
    out, _ = fresh('rot.bcd', '(param A 30)', '(node 1 (box 10 20 30) (intent create 6 0 1 0))', '(node 2 (rotate 1 z A) (intent same 0 0 1 0))',
                   '(node 3 (holes 2 (face 1 0 top) through (hole 5 10 2)) (intent remove 1 2 1 1))',
                   '(node 4 (cylinder 5 12) (intent create 3 0 1 0))', '(node 5 (rotate 4 x 45) (intent same 0 0 1 0))',
                   '(node 6 (torus 30 10) (intent create 8 0 1 1))', '(node 7 (rotate 6 x 30) (intent same 0 0 1 1))',
                   '(node 8 (sphere 10) (intent create 2 0 1 0))', '(node 9 (move 8 20 0 0 0) (intent same 0 0 1 0))', '(node 10 (rotate 9 z 90) (intent same 0 0 1 0))')
    want = {2: [-20 * s30, 10 * c30, 0, 10 * s30 + 20 * c30, 0, 30],
            5: [-5, 5, -5 * c45 - 12 * s45, 5 * c45, -5 * s45, 5 * s45 + 12 * c45],
            7: [-40, 40, -(30 * c30 + 10), 30 * c30 + 10, -(30 * s30 + 10), 30 * s30 + 10],
            10: [-10, 10, 10, 30, -10, 10]}
    for n, e in want.items():
        b = bbox(out, n)
        record(f'rotate.bbox{n}', 'committed' in out and b is not None and all(abs(x - y) < 1e-9 for x, y in zip(b, e)) and
               all(b[i] <= e[i] + 1e-12 if i % 2 == 0 else b[i] >= e[i] - 1e-12 for i in range(6)), bbox=b, exact=e)
    record('rotate.volume_invariant', contains(vol(out, 2), 6000.0) and contains(vol(out, 7), 2 * PI * PI * 30 * 100),
           v2=vol(out, 2), v7=vol(out, 7))
    record('rotate.feature_on_rotated', contains(vol(out, 3), 6000 - PI * 4 * 30), volume=vol(out, 3))
    cli('rot.bcd', 'tess', '3', f'{WORK}/rot3.obj')
    good, info = mesh_ok(f'{WORK}/rot3.obj', 1, 6000 - PI * 4 * 30, 0.02)
    mb = check(*load_obj(os.path.join(HERE, 'e2e-meshes', 'rot3.obj')))['bbox']
    kb = bbox(out, 3)
    inside = kb is not None and all(kb[2 * i] <= mb[0][i] + 1e-9 and mb[1][i] <= kb[2 * i + 1] + 1e-9 for i in range(3))
    record('rotate.mesh_inside_bbox', good and inside, kernel_bbox=kb, mesh_bbox=mb, **info)
    o, _ = fresh('bracket_rot.bcd', '(param W 120)', '(param H 80)', '(param R 10)',
                 '(node 1 (prism 0 8 (region (path R 0 (line (- W R) 0) (arc (- W R) R R W R ccw) (line W (- H R)) (arc (- W R) (- H R) R (- W R) H ccw) (line R H) (arc R (- H R) R 0 (- H R) ccw) (line 0 R) (arc R R R R 0 ccw)))) (intent create 10 0 1 0))',
                 '(node 2 (rotate 1 z 30) (intent same 0 0 1 0))')
    cli('bracket_rot.bcd', 'tess', '2', f'{WORK}/bracket_rot.obj')
    fetch_obj(f'{WORK}/bracket_rot.obj')
    mb = check(*load_obj(os.path.join(HERE, 'e2e-meshes', 'bracket_rot.obj')))['bbox']
    kb = bbox(o, 2)
    encl = kb is not None and all(kb[2 * i] <= mb[0][i] + 1e-9 and mb[1][i] <= kb[2 * i + 1] + 1e-9 and
                                  mb[0][i] - kb[2 * i] < 10 and kb[2 * i + 1] - mb[1][i] < 10 for i in range(3))
    record('rotate.arc_bbox_encloses', 'committed' in o and encl, kernel_bbox=kb, mesh_bbox=mb)
    before = read('rot.bcd')
    rej = []
    for e in ['(node 11 (rotate 1 w 30) (intent same 0 0 1 0))', '(node 11 (rotate 1 z 1e7) (intent same 0 0 1 0))',
              '(node 11 (fillet 1 2) (intent same 0 0 1 0))']:
        o, _ = cli('rot.bcd', 'apply', e)
        rej.append(re.findall(r'why: ([^|]+)', o)[-1:])
    ok = (read('rot.bcd') == before and rej[0] == ['bad-axis-or-angle '] and rej[1] == ['bad-axis-or-angle '] and rej[2] == ['unknown-op '])
    record('rotate.rejections', ok, why=rej)


def zones():
    out, _ = fresh('z.bcd', '(param X 10 9.9 10.1)', '(param Y 20 19.9 20.1)', '(param Z 30 29.9 30.1)', '(param R 30 29 31)', '(param r 10 9 11)',
                   '(node 1 (box X Y Z) (intent create 6 0 1 0))', '(node 2 (move 1 5 5 5 4) (intent same 0 0 1 0))',
                   '(node 3 (torus R r) (intent create 8 0 1 1))')
    zs = {}
    for n in (1, 2, 3):
        o, _ = cli('z.bcd', 'zone', str(n))
        m = re.search(r'volume=\[([^,]+), ([^\]]+)\] area=\[([^,]+), ([^\]]+)\]', o)
        zs[n] = [float(m.group(i)) for i in range(1, 5)] if m else None
    lo, hi = 9.9 * 19.9 * 29.9, 10.1 * 20.1 * 30.1
    alo, ahi = 2 * (9.9 * 19.9 + 19.9 * 29.9 + 29.9 * 9.9), 2 * (10.1 * 20.1 + 20.1 * 30.1 + 30.1 * 10.1)
    box_ok = (zs[1] is not None and zs[1][0] <= lo and hi <= zs[1][1] and zs[1][1] - zs[1][0] < (hi - lo) * (1 + 1e-12) + 1e-9
              and zs[1][2] <= alo and ahi <= zs[1][3])
    tlo, thi = 2 * PI * PI * 29 * 81, 2 * PI * PI * 31 * 121
    tor_ok = zs[3] is not None and zs[3][0] <= tlo and thi <= zs[3][1] and zs[3][1] - zs[3][0] < (thi - tlo) * 1.001
    record('zone.box', 'committed' in out and box_ok, zone=zs[1], exact=[lo, hi])
    record('zone.move', zs[2] == zs[1], zone=zs[2])
    record('zone.torus', tor_ok, zone=zs[3], exact=[tlo, thi])
    o, _ = cli('z.bcd', 'apply', '(param r 10 9 31)')
    o2, _ = cli('z.bcd', 'zone', '3')
    record('zone.torus_overlap', 'committed' in o and 'dimension-not-certified-positive-over-zone' in o2, out=o2.strip())
    o, _ = cli('bracket.bcd', 'zone', '3')
    ev, _ = cli('bracket.bcd', 'eval')
    zb = re.search(r'volume=\[([^,]+), ([^\]]+)\]', o)
    eb = vol(ev, 3)
    record('zone.bracket_certified', zb is not None and eb is not None and float(zb.group(1)) <= eb[1] and eb[0] <= float(zb.group(2)), out=o.strip(), eval=eb)
    before = read('z.bcd')
    bad = ['(param X 10 11 12)', '(param X 10 9)', '(param X abc)', '(param X 1e400)', '(param X 10 12 9)']
    rej = []
    for e in bad:
        o, _ = cli('z.bcd', 'apply', e)
        rej.append('finite numbers LO <= NOM <= HI' in o and read('z.bcd') == before)
    record('zone.bad_params_rejected', all(rej), each=rej)


def mcp():
    srv = os.path.join(HERE, '..', '..', 'tools', 'mcp', 'bendcad-mcp.mjs')
    msgs = [dict(method='initialize', params=dict(protocolVersion='2024-11-05')),
            dict(method='tools/list'),
            dict(method='tools/call', params=dict(name='new_design', arguments=dict(design=f'{WORK}/mcp.bcd'))),
            dict(method='tools/call', params=dict(name='apply', arguments=dict(design=f'{WORK}/mcp.bcd', edits=[
                '(param W 40)', '(node 1 (box W 30 10) (intent create 6 0 1 0))',
                '(node 2 (holes 1 (face 1 0 top) through (hole 20 15 4)) (intent remove 1 2 1 1))']))),
            dict(method='tools/call', params=dict(name='apply', arguments=dict(design=f'{WORK}/mcp.bcd', edits=[
                '(node 3 (holes 2 (face 1 0 top) through (hole 20 15 6)) (intent remove 1 2 1 2))']))),
            dict(method='tools/call', params=dict(name='faces', arguments=dict(design=f'{WORK}/mcp.bcd', node=2))),
            dict(method='tools/call', params=dict(name='sensitivity', arguments=dict(design=f'{WORK}/mcp.bcd', param='W', node=2))),
            dict(method='tools/call', params=dict(name='nope', arguments={})),
            dict(method='tools/call', params=dict(name='new_design', arguments=dict(design=f'{WORK}/mcp2.bcd'))),
            dict(method='tools/call', params=dict(name='apply', arguments=dict(design=f'{WORK}/mcp2.bcd',
                edits='(param W 40) (node 1 (box W 30 10) (intent create 6 0 1 0))')))]
    text = ''.join(json.dumps(dict(jsonrpc='2.0', id=i + 1, **m)) + '\n' for i, m in enumerate(msgs))
    r = subprocess.run(['node', srv], input=text, capture_output=True, text=True, timeout=600,
                       env=dict(os.environ, BENDCAD_BIN=BIN))
    rs = {x['id']: x for x in map(json.loads, r.stdout.strip().splitlines())}
    names = [t['name'] for t in rs[2]['result']['tools']]
    body = lambda i: rs[i]['result']['content'][0]['text']
    v = 40 * 30 * 10 - PI * 16 * 10
    checks = dict(
        handshake=rs[1]['result']['serverInfo']['name'] == 'bendcad',
        tools=set(names) == {'reference', 'new_design', 'apply', 'show', 'evaluate', 'measure', 'faces', 'sensitivity', 'tessellate', 'zone'},
        apply_ok=not rs[4]['result']['isError'] and contains(vol(body(4), 2), v),
        apply_rejected=rs[5]['result']['isError'] and 'rejected' in body(5),
        faces=len(body(6).splitlines()) == 7,
        sensitivity=abs(float(re.search(r'd_volume=([^ ]+)', body(7)).group(1)) - 300) < 1e-3,
        unknown_tool='error' in rs[8],
        edits_as_one_string=not rs[10]['result']['isError'] and 'committed' in body(10))
    record('mcp.session', all(checks.values()), **checks)


def performance():
    for n in (10, 20):
        hs = ' '.join(f'(hole {10 + i * 10} {10 + j * 10} 3)' for i in range(n) for j in range(n))
        w = 20 + n * 10
        out, dt = fresh(f'perf{n}.bcd', f'(node 1 (box {w} {w} 8) (intent create 6 0 1 0))',
                        f'(node 2 (holes 1 (face 1 0 top) through {hs}) (intent remove any any 1 any))')
        _, dt2 = cli(f'perf{n}.bcd', 'tess', '2', f'{WORK}/perf{n}.obj')
        budget = {10: (1.0, 5.0), 20: (2.0, 20.0)}[n]
        record(f'perf.holes{n * n}', 'committed' in out and dt < budget[0] and dt2 < budget[1], build_s=round(dt, 3), tess_s=round(dt2, 3),
               budget=budget)
        good, info = mesh_ok(f'{WORK}/perf{n}.obj', n * n, (w * w - n * n * PI * 9) * 8, 0.02)
        record(f'perf.holes{n * n}.mesh', good, **{k: v for k, v in info.items() if k != 'sha256'})


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (bracket, primitives, revolve_cavity, counterbore_island, move, atomic_rejections, rotation, zones, mcp, performance):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} passed")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
