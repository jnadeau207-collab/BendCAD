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
RESULTS = []


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


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if k != 'detail'})


def contains(iv, x):
    return iv is not None and iv[0] <= x <= iv[1]


def vol(out, node):
    m = re.search(rf'node {node}: ok .*?volume=\[([^,]+), ([^\]]+)\]', out)
    return (float(m.group(1)), float(m.group(2))) if m else None


def vol_plain(out):
    m = re.search(r'volume=\[([^,]+), ([^\]]+)\]', out)
    return (float(m.group(1)), float(m.group(2))) if m else None


def fx(out, node):
    m = re.search(rf'node {node}: ok material=(\w+) faces_created=(\d+) faces_modified=(\d+) '
                  rf'solids=(\d+) through_holes=(\d+)', out)
    return m.groups() if m else None


def l20_ok(out, u_node, i_node, a_node, b_node, total):
    vu, vi, va, vb = vol(out, u_node), vol(out, i_node), vol(out, a_node), vol(out, b_node)
    if None in (vu, vi, va, vb):
        return False, dict(union=vu, inter=vi, a=va, b=vb)
    ok = (vu[0] + vi[0] <= total <= vu[1] + vi[1] and
          abs((vu[0] + vu[1]) / 2 + (vi[0] + vi[1]) / 2 - total) < 1e-6 and
          abs((va[0] + va[1]) / 2 + (vb[0] + vb[1]) / 2 - total) < 1e-6)
    return ok, dict(union=vu, inter=vi)


def bbox_x(out, node):
    m = re.search(rf'node {node}: ok .*?bbox=\[([^,]+), ([^\]]+)\]', out)
    return (float(m.group(1)), float(m.group(2))) if m else None


def mesh_ok(path, euler, v_exact, tol):
    local = fetch_obj(path)
    mc = check(*load_obj(local))
    rel = abs(mc['volume'] - v_exact) / v_exact
    good = mc['watertight'] and mc['euler_characteristic'] == euler and rel < tol
    return good, dict(triangles=mc['triangles'], watertight=mc['watertight'], euler=mc['euler_characteristic'],
                      mesh_volume=mc['volume'], rel_err=rel,
                      sha256=hashlib.sha256(open(local, 'rb').read()).hexdigest())


def disjoint():
    out, dt = fresh('disj.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))',
                    '(node 5 (difference 1 3) (intent same 0 0 1 0))',
                    '(node 6 (intersection 1 3) (intent same 0 0 0 0))')
    record('disjoint.union', 'committed' in out and fx(out, 4) == ('add', '0', '0', '2', '0') and contains(vol(out, 4), 2000.0),
           fx=fx(out, 4), volume=vol(out, 4), seconds=dt)
    record('disjoint.diff', fx(out, 5) == ('same', '0', '0', '1', '0') and contains(vol(out, 5), 1000.0),
           fx=fx(out, 5), volume=vol(out, 5))
    record('disjoint.inter', fx(out, 6) == ('same', '0', '0', '0', '0') and vol(out, 6) == (0.0, 0.0),
           fx=fx(out, 6), volume=vol(out, 6))
    ok20, info20 = l20_ok(out, 4, 6, 1, 3, 2000.0)
    record('disjoint.volume_identity', ok20, **info20)
    record('disjoint.proof', 'proof: disjoint-boxes A[' in out and out.count('disjoint-boxes') >= 3,
           count=out.count('disjoint-boxes'))
    c4, _ = cli('disj.bcd', 'check', '4')
    c5, _ = cli('disj.bcd', 'check', '5')
    record('disjoint.check', c4.startswith('ok:') and c5.startswith('ok:'), union=c4.strip(), diff=c5.strip())
    got = {}
    for pt, want in (('5 5 5', 'inside'), ('25 5 5', 'inside'), ('15 5 5', 'outside'), ('-5 5 5', 'outside')):
        o, _ = cli('disj.bcd', 'classify', '4', *pt.split())
        got[pt] = o.strip()
    record('disjoint.classify', got == {'5 5 5': 'inside', '25 5 5': 'inside', '15 5 5': 'outside', '-5 5 5': 'outside'}, got=got)
    faces, _ = cli('disj.bcd', 'faces', '4')
    fl = faces.strip().splitlines()
    record('disjoint.faces', len(fl) == 12 and sum('n1.c' in ln for ln in fl) == 6 and sum('n2.c' in ln for ln in fl) == 6
           and all(ln.endswith('plane loops=1') for ln in fl), count=len(fl))
    m, _ = cli('disj.bcd', 'measure', '4')
    record('disjoint.measure', contains(vol_plain(m), 2000.0), volume=vol_plain(m))
    cli('disj.bcd', 'tess', '4', f'{WORK}/disj.obj')
    good, info = mesh_ok(f'{WORK}/disj.obj', 4, 2000.0, 0.01)
    record('disjoint.mesh', good, **info)
    v4, _ = cli('disj.bcd', 'faces', '4', '-v')
    v5, _ = cli('disj.bcd', 'faces', '5', '-v')
    v6, _ = cli('disj.bcd', 'faces', '6', '-v')
    record('disjoint.deleted_union_empty', v4.strip().splitlines() == fl,
           verbose=len(v4.strip().splitlines()))
    d5 = [ln for ln in v5.strip().splitlines() if ln.startswith('deleted ')]
    record('disjoint.deleted_diff_carry', len(d5) == 6 and all('classified-away' in ln for ln in d5)
           and all('n2.c' in ln for ln in d5), count=len(d5))
    d6 = [ln for ln in v6.strip().splitlines() if ln.startswith('deleted ')]
    record('disjoint.deleted_inter_empty', len(d6) == 12 and all('classified-away' in ln for ln in d6),
           count=len(d6))
    text1 = read('disj.bcd')
    out2, _ = cli('disj.bcd', 'eval')
    record('disjoint.reopen', vol(out2, 4) == vol(out, 4), volume=vol(out2, 4))
    faces2, _ = cli('disj.bcd', 'faces', '4')
    record('disjoint.replay_lineage', faces2 == faces)
    cli('disj.bcd', 'apply', '(node 4 (union 1 3) (intent add 0 0 2 0))')
    record('disjoint.serialize_stable', read('disj.bcd') == text1)


def containment():
    out, dt = fresh('cont.bcd',
                    '(node 1 (box 20 20 20) (intent create 6 0 1 0))',
                    '(node 2 (box 4 4 4) (intent create 6 0 1 0))',
                    '(node 3 (move 2 8 8 8 0) (intent same 0 0 1 0))',
                    '(node 4 (difference 1 3) (intent remove 6 0 1 0))',
                    '(node 5 (intersection 1 3) (intent same 0 0 1 0))',
                    '(node 6 (union 1 3) (intent same 0 0 1 0))')
    record('containment.cavity', 'committed' in out and fx(out, 4) == ('remove', '6', '0', '1', '0')
           and contains(vol(out, 4), 7936.0), fx=fx(out, 4), volume=vol(out, 4), seconds=dt)
    record('containment.inter', fx(out, 5) == ('same', '0', '0', '1', '0') and contains(vol(out, 5), 64.0),
           fx=fx(out, 5), volume=vol(out, 5))
    record('containment.union', fx(out, 6) == ('same', '0', '0', '1', '0') and contains(vol(out, 6), 8000.0),
           fx=fx(out, 6), volume=vol(out, 6))
    c4, _ = cli('cont.bcd', 'check', '4')
    record('containment.check', c4.startswith('ok:'), out=c4.strip())
    got = {}
    for pt, want in (('1 1 1', 'inside'), ('10 10 10', 'outside'), ('19 19 19', 'inside'), ('30 30 30', 'outside')):
        o, _ = cli('cont.bcd', 'classify', '4', *pt.split())
        got[pt] = o.strip()
    record('containment.classify', got == {'1 1 1': 'inside', '10 10 10': 'outside', '19 19 19': 'inside', '30 30 30': 'outside'},
           got=got)
    faces, _ = cli('cont.bcd', 'faces', '4')
    fl = faces.strip().splitlines()
    record('containment.faces', len(fl) == 12 and sum(ln.startswith('n1.c') for ln in fl) == 6
           and sum(ln.startswith('n4.cav.') for ln in fl) == 6
           and all(ln.endswith('plane loops=1') for ln in fl), count=len(fl))
    facesv, _ = cli('cont.bcd', 'faces', '4', '-v')
    vl = facesv.strip().splitlines()
    record('containment.faces_verbose_empty_del', vl == fl,
           verbose_count=len(vl), plain_count=len(fl))
    cli('cont.bcd', 'tess', '4', f'{WORK}/cont.obj')
    good, info = mesh_ok(f'{WORK}/cont.obj', 4, 7936.0, 0.01)
    record('containment.mesh', good, **info)
    ok20, info20 = l20_ok(out, 6, 5, 1, 3, 8064.0)
    record('containment.volume_identity', ok20, **info20)


def mirror():
    out, dt = fresh('mirror.bcd',
                    '(node 1 (box 20 20 20) (intent create 6 0 1 0))',
                    '(node 2 (box 4 4 4) (intent create 6 0 1 0))',
                    '(node 3 (move 2 8 8 8 0) (intent same 0 0 1 0))',
                    '(node 4 (union 3 1) (intent same 0 0 1 0))',
                    '(node 5 (difference 3 1) (intent same 0 0 0 0))',
                    '(node 6 (intersection 3 1) (intent same 0 0 1 0))')
    record('mirror.union', 'committed' in out and fx(out, 4) == ('same', '0', '0', '1', '0')
           and contains(vol(out, 4), 8000.0), fx=fx(out, 4), volume=vol(out, 4), seconds=dt)
    record('mirror.diff', fx(out, 5) == ('same', '0', '0', '0', '0') and vol(out, 5) == (0.0, 0.0),
           fx=fx(out, 5), volume=vol(out, 5))
    record('mirror.inter', fx(out, 6) == ('same', '0', '0', '1', '0') and contains(vol(out, 6), 64.0),
           fx=fx(out, 6), volume=vol(out, 6))
    ok20, info20 = l20_ok(out, 4, 6, 3, 1, 8064.0)
    record('mirror.volume_identity', ok20, **info20)
    v5, _ = cli('mirror.bcd', 'faces', '5', '-v')
    d5 = [ln for ln in v5.strip().splitlines() if ln.startswith('deleted ')]
    record('mirror.deleted_emptied', len(d5) == 12, count=len(d5))


def kiss_inside():
    out, dt = fresh('kiss.bcd',
                    '(node 1 (box 20 20 20) (intent create 6 0 1 0))',
                    '(node 2 (box 4 4 4) (intent create 6 0 1 0))',
                    '(node 3 (move 2 0 8 8 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent same 0 0 1 0))',
                    '(node 5 (intersection 1 3) (intent same 0 0 1 0))')
    record('kiss.union', 'committed' in out and fx(out, 4) == ('same', '0', '0', '1', '0')
           and contains(vol(out, 4), 8000.0), fx=fx(out, 4), volume=vol(out, 4), seconds=dt)
    record('kiss.inter', fx(out, 5) == ('same', '0', '0', '1', '0') and contains(vol(out, 5), 64.0),
           fx=fx(out, 5), volume=vol(out, 5))
    ok20, info20 = l20_ok(out, 4, 5, 1, 3, 8064.0)
    record('kiss.volume_identity', ok20, **info20)
    out6, _ = cli('kiss.bcd', 'apply', '(node 6 (difference 1 3) (intent remove 0 0 1 0))')
    m6 = re.search(r'node 6: error (\S+) .*?why: ([^|]+)', out6)
    record('kiss.diff_pinched', m6 is not None and 'validation-rejected' in m6.group(2)
           and '(difference 1 3)' not in read('kiss.bcd'),
           why=m6 and m6.group(2).strip())


def contact():
    out, dt = fresh('touch.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (move 2 10 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))',
                    '(node 5 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 6 (move 5 10 10 0 0) (intent same 0 0 1 0))',
                    '(node 7 (union 1 6) (intent add 0 0 2 0))',
                    '(node 8 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 9 (move 8 10 10 10 0) (intent same 0 0 1 0))',
                    '(node 10 (union 1 9) (intent add 0 0 2 0))',
                    '(node 11 (intersection 1 3) (intent same 0 0 0 0))')
    record('contact.face', 'committed' in out and fx(out, 4) == ('add', '0', '0', '2', '0') and contains(vol(out, 4), 2000.0),
           fx=fx(out, 4), volume=vol(out, 4), seconds=dt)
    record('contact.edge', fx(out, 7) == ('add', '0', '0', '2', '0') and contains(vol(out, 7), 2000.0),
           fx=fx(out, 7), volume=vol(out, 7))
    record('contact.vertex', fx(out, 10) == ('add', '0', '0', '2', '0') and contains(vol(out, 10), 2000.0),
           fx=fx(out, 10), volume=vol(out, 10))
    c4, _ = cli('touch.bcd', 'check', '4')
    c7, _ = cli('touch.bcd', 'check', '7')
    c10, _ = cli('touch.bcd', 'check', '10')
    record('contact.check', c4.startswith('ok:') and c7.startswith('ok:') and c10.startswith('ok:'),
           face=c4.strip(), edge=c7.strip(), vertex=c10.strip())
    got = {}
    for pt, want in (('5 5 5', 'inside'), ('15 5 5', 'inside'), ('10 5 15', 'outside')):
        o, _ = cli('touch.bcd', 'classify', '4', *pt.split())
        got[pt] = o.strip()
    record('contact.classify', got == {'5 5 5': 'inside', '15 5 5': 'inside', '10 5 15': 'outside'}, got=got)
    cli('touch.bcd', 'tess', '4', f'{WORK}/touch.obj')
    good, info = mesh_ok(f'{WORK}/touch.obj', 4, 2000.0, 0.01)
    record('contact.mesh', good, **info)
    record('contact.inter_empty', fx(out, 11) == ('same', '0', '0', '0', '0') and vol(out, 11) == (0.0, 0.0),
           fx=fx(out, 11), volume=vol(out, 11))
    ok20, info20 = l20_ok(out, 4, 11, 1, 3, 2000.0)
    record('contact.volume_identity', ok20, **info20)


def identical():
    out, dt = fresh('ident.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (union 1 1) (intent same 0 0 1 0))',
                    '(node 3 (difference 1 1) (intent same 0 0 0 0))',
                    '(node 4 (intersection 1 1) (intent same 0 0 1 0))')
    record('identical.union', 'committed' in out and fx(out, 2) == ('same', '0', '0', '1', '0') and contains(vol(out, 2), 1000.0),
           fx=fx(out, 2), volume=vol(out, 2), seconds=dt)
    record('identical.diff', fx(out, 3) == ('same', '0', '0', '0', '0') and vol(out, 3) == (0.0, 0.0),
           fx=fx(out, 3), volume=vol(out, 3))
    record('identical.inter', fx(out, 4) == ('same', '0', '0', '1', '0') and contains(vol(out, 4), 1000.0),
           fx=fx(out, 4), volume=vol(out, 4))
    v2, _ = cli('ident.bcd', 'faces', '2', '-v')
    v3, _ = cli('ident.bcd', 'faces', '3', '-v')
    v4, _ = cli('ident.bcd', 'faces', '4', '-v')
    d2 = [ln for ln in v2.strip().splitlines() if ln.startswith('deleted ')]
    d3 = [ln for ln in v3.strip().splitlines() if ln.startswith('deleted ')]
    d4 = [ln for ln in v4.strip().splitlines() if ln.startswith('deleted ')]
    record('identical.deleted_carry_empty', d2 == [] and d4 == [] and sum(ln.startswith('n1.c') for ln in v2.strip().splitlines()) == 6,
           union=len(d2), inter=len(d4))
    record('identical.deleted_diff_once', len(d3) == 6 and len(set(d3)) == 6 and all('classified-away' in ln for ln in d3),
           count=len(d3))
    ok20, info20 = l20_ok(out, 2, 4, 1, 1, 2000.0)
    record('identical.volume_identity', ok20, **info20)


def empty_algebra():
    out, dt = fresh('empty.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (intersection 1 3) (intent same 0 0 0 0))',
                    '(node 5 (union 4 1) (intent same 0 0 1 0))',
                    '(node 6 (difference 4 1) (intent same 0 0 0 0))',
                    '(node 7 (union 4 4) (intent same 0 0 0 0))',
                    '(node 8 (difference 1 4) (intent same 0 0 1 0))',
                    '(node 9 (intersection 1 4) (intent same 0 0 0 0))')
    record('empty.union_empty_left', 'committed' in out and fx(out, 5) == ('same', '0', '0', '1', '0')
           and contains(vol(out, 5), 1000.0), fx=fx(out, 5), volume=vol(out, 5), seconds=dt)
    record('empty.diff_empty_left', fx(out, 6) == ('same', '0', '0', '0', '0') and vol(out, 6) == (0.0, 0.0),
           fx=fx(out, 6), volume=vol(out, 6))
    record('empty.union_both_empty', fx(out, 7) == ('same', '0', '0', '0', '0') and vol(out, 7) == (0.0, 0.0),
           fx=fx(out, 7), volume=vol(out, 7))
    record('empty.diff_empty_right', fx(out, 8) == ('same', '0', '0', '1', '0') and contains(vol(out, 8), 1000.0),
           fx=fx(out, 8), volume=vol(out, 8))
    record('empty.inter_empty_right', fx(out, 9) == ('same', '0', '0', '0', '0') and vol(out, 9) == (0.0, 0.0),
           fx=fx(out, 9), volume=vol(out, 9))
    o, _ = cli('empty.bcd', 'apply', '(node 10 (pad 4 (face 4 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 1 0))')
    record('empty.feature_on_empty', 'feature-on-empty-compound' in o, why=re.findall(r'why: ([^|]+)', o))
    # Node 5 carries node 1. Selectors name the creating node, so (face 5 ...) is face-not-found.
    o, _ = cli('empty.bcd', 'apply', '(node 10 (pad 5 (face 5 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 1 0))')
    record('empty.feature_on_carry_ok', 'face-not-found' in o and 'committed' not in o
           and 'feature-on-empty-compound' not in o and 'feature-on-boolean-result' not in o,
           why=re.findall(r'why: ([^|]+)', o))
    ok20, info20 = l20_ok(out, 5, 9, 4, 1, 1000.0)
    record('empty.volume_identity', ok20, **info20)


def feature_on_boolean():
    out, _ = fresh('feat.bcd',
                   '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                   '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                   '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
                   '(node 4 (union 1 3) (intent add 0 0 2 0))')
    o, _ = cli('feat.bcd', 'apply', '(node 5 (pad 4 (face 4 0 top) 5 (region (circle 5 5 2))) (intent add 2 1 2 0))')
    record('boolean.feature_refused', 'feature-on-boolean-result' in o, why=re.findall(r'why: ([^|]+)', o))


def slanted():
    tri = '(prism 0 10 (region (path 0 0 (line 10 0) (line 0 10))))'
    out, dt = fresh('slant.bcd',
                    f'(node 1 {tri} (intent create 5 0 1 0))',
                    f'(node 2 {tri} (intent create 5 0 1 0))',
                    '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))')
    record('slanted.union', 'committed' in out and fx(out, 4) == ('add', '0', '0', '2', '0') and contains(vol(out, 4), 1000.0),
           fx=fx(out, 4), volume=vol(out, 4), seconds=dt)
    faces, _ = cli('slant.bcd', 'faces', '1')
    record('slanted.bicubic_wall_present', 'planar-patch' in faces and len(faces.strip().splitlines()) == 5, faces=faces.strip())
    c4, _ = cli('slant.bcd', 'check', '4')
    record('slanted.check', c4.startswith('ok:'), out=c4.strip())
    cli('slant.bcd', 'tess', '4', f'{WORK}/slant.obj')
    good, info = mesh_ok(f'{WORK}/slant.obj', 4, 1000.0, 0.01)
    record('slanted.mesh', good, **info)


def crossing():
    out, dt = fresh('cross.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (move 2 5 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 1 0))',
                    '(node 5 (difference 1 3) (intent remove 0 0 1 0))',
                    '(node 6 (intersection 1 3) (intent remove 0 0 1 0))')
    hits = {n: re.search(rf'node {n}: error (unsupported-op) .*?why: boundaries-cross-or-overlap', out)
            for n in (4, 5, 6)}
    record('crossing.union_refused', hits[4] is not None, seconds=dt)
    record('crossing.diff_refused', hits[5] is not None)
    record('crossing.inter_refused', hits[6] is not None)
    f4, _ = cli('cross.bcd', 'faces', '4')
    record('crossing.failed_nodes_absent', '(union 1 3)' not in read('cross.bcd')
           and 'node failed' in f4, faces=f4.strip()[:40])
    o2, _ = fresh('straddle.bcd',
                  '(node 1 (box 20 20 20) (intent create 6 0 1 0))',
                  '(node 2 (box 4 4 4) (intent create 6 0 1 0))',
                  '(node 3 (move 2 18 8 8 0) (intent same 0 0 1 0))',
                  '(node 4 (difference 1 3) (intent remove 0 0 1 0))')
    record('crossing.straddle_refused', 'boundaries-cross-or-overlap' in o2)


def intent_gate():
    out, _ = fresh('gate.bcd',
                   '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                   '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                   '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
                   '(node 4 (union 1 3) (intent create 6 0 1 0))')
    record('intent.mismatch', 'declared material=create' in out and 'but measured material=add' in out,
           why=re.findall(r'why: ([^|]+)', out))


def zone_refusal():
    fresh('zbool.bcd',
          '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
          '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
          '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
          '(node 4 (union 1 3) (intent add 0 0 2 0))')
    o, _ = cli('zbool.bcd', 'zone', '4')
    record('zone.boolean_refused', 'topology-not-certified-over-zone' in o
           and 'refuse before any zone split' in o and 'keep profile segments' not in o, out=o.strip())


def sens_cache():
    out, dt = fresh('sens.bcd', '(param W 10)',
                    '(node 1 (box W 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (move 2 30 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))')
    s, _ = cli('sens.bcd', 'sens', 'W', '4')
    m = re.search(r'd_volume=([^ ]+)', s)
    record('sens.union', m is not None and abs(float(m.group(1)) - 100) < 1e-3 and 'reused' in s,
           d_volume=m and float(m.group(1)), seconds=dt)


def rotated():
    out, dt = fresh('rot.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (rotate 2 z 90) (intent same 0 0 1 0))',
                    '(node 4 (move 3 40 0 0 0) (intent same 0 0 1 0))',
                    '(node 5 (union 1 4) (intent add 0 0 2 0))',
                    '(node 6 (move 2 0 40 0 2) (intent same 0 0 1 0))',
                    '(node 7 (union 1 6) (intent add 0 0 2 0))')
    record('rotated.union', 'committed' in out and fx(out, 5) == ('add', '0', '0', '2', '0') and contains(vol(out, 5), 2000.0),
           fx=fx(out, 5), volume=vol(out, 5), seconds=dt)
    record('rotated.quarter_turn', fx(out, 7) == ('add', '0', '0', '2', '0') and contains(vol(out, 7), 2000.0),
           fx=fx(out, 7), volume=vol(out, 7))
    c5, _ = cli('rot.bcd', 'check', '5')
    record('rotated.check', c5.startswith('ok:'), out=c5.strip())
    out2, _ = fresh('rot45.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (rotate 2 z 45) (intent same 0 0 1 0))',
                    '(node 4 (move 3 40 0 0 0) (intent same 0 0 1 0))',
                    '(node 5 (union 1 4) (intent add 0 0 2 0))')
    m = re.search(r'node 5: error (\S+) .*?why: ([^|]+)', out2)
    record('rotated.inexact_refused', m is not None and m.group(1) == 'unsupported-op'
           and 'interval-placement' in m.group(2), why=m and m.group(2).strip())


def moved_chain():
    out, dt = fresh('mvchain.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))',
                    '(node 5 (move 4 100 0 0 0) (intent same 0 0 2 0))',
                    '(node 6 (box 4 4 4) (intent create 6 0 1 0))',
                    '(node 7 (move 6 101 1 1 0) (intent same 0 0 1 0))',
                    '(node 8 (intersection 5 7) (intent same 0 0 1 0))',
                    '(node 9 (difference 5 7) (intent remove 6 0 2 0))',
                    '(node 10 (union 5 7) (intent same 0 0 2 0))')
    record('moved.inter', 'committed' in out and fx(out, 8) == ('same', '0', '0', '1', '0')
           and contains(vol(out, 8), 64.0), fx=fx(out, 8), volume=vol(out, 8), seconds=dt)
    record('moved.diff_cavity', fx(out, 9) == ('remove', '6', '0', '2', '0') and contains(vol(out, 9), 1936.0),
           fx=fx(out, 9), volume=vol(out, 9))
    record('moved.union_carry', fx(out, 10) == ('same', '0', '0', '2', '0') and contains(vol(out, 10), 2000.0),
           fx=fx(out, 10), volume=vol(out, 10))
    bx = bbox_x(out, 5)
    record('moved.world_box', bx is not None and 99.0 <= bx[0] <= 101.0 and 129.0 <= bx[1] <= 131.0, bbox=bx)
    ok20, info20 = l20_ok(out, 10, 8, 5, 7, 2064.0)
    record('moved.volume_identity', ok20, **info20)


def pierce():
    out, dt = fresh('pierce.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 2 2 20) (intent create 6 0 1 0))',
                    '(node 3 (move 2 4 4 -5 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 1 0))',
                    '(node 5 (difference 1 3) (intent remove 0 0 1 0))',
                    '(node 6 (intersection 1 3) (intent remove 0 0 1 0))')
    hits = {n: re.search(rf'node {n}: error (unsupported-op) .*?why: boundaries-cross-or-overlap', out)
            for n in (4, 5, 6)}
    record('pierce.union_refused', hits[4] is not None, seconds=dt)
    record('pierce.diff_refused', hits[5] is not None)
    record('pierce.inter_refused', hits[6] is not None)
    out2, _ = fresh('pierce2.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (sphere 6) (intent create 2 0 1 0))',
                    '(node 3 (union 1 2) (intent add 0 0 1 0))')
    record('pierce.sphere_cross_refused', 'boundaries-cross-or-overlap' in out2)


def curved():
    out, dt = fresh('curved.bcd',
                    '(node 1 (cylinder 2 10) (intent create 3 0 1 0))',
                    '(node 2 (sphere 3) (intent create 2 0 1 0))',
                    '(node 3 (move 2 50 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))')
    record('curved.disjoint', 'committed' in out and fx(out, 4) == ('add', '0', '0', '2', '0')
           and contains(vol(out, 4), 76 * PI), fx=fx(out, 4), volume=vol(out, 4), seconds=dt)
    out2, _ = fresh('curved2.bcd',
                    '(node 1 (box 20 20 20) (intent create 6 0 1 0))',
                    '(node 2 (sphere 4) (intent create 2 0 1 0))',
                    '(node 3 (move 2 10 10 10 0) (intent same 0 0 1 0))',
                    '(node 4 (difference 1 3) (intent remove 2 0 1 0))',
                    '(node 5 (intersection 1 3) (intent same 0 0 1 0))',
                    '(node 6 (union 1 3) (intent same 0 0 1 0))')
    record('curved.cavity', fx(out2, 4) == ('remove', '2', '0', '1', '0')
           and contains(vol(out2, 4), 8000.0 - 256 * PI / 3), fx=fx(out2, 4), volume=vol(out2, 4))
    record('curved.inter', fx(out2, 5) == ('same', '0', '0', '1', '0')
           and contains(vol(out2, 5), 256 * PI / 3), fx=fx(out2, 5), volume=vol(out2, 5))
    record('curved.union_carry', fx(out2, 6) == ('same', '0', '0', '1', '0')
           and contains(vol(out2, 6), 8000.0), fx=fx(out2, 6), volume=vol(out2, 6))
    ok20, info20 = l20_ok(out2, 6, 5, 1, 3, 8000.0 + 256 * PI / 3)
    record('curved.volume_identity', ok20, **info20)
    c4, _ = cli('curved2.bcd', 'check', '4')
    record('curved.check', c4.startswith('ok:'), out=c4.strip())


def tangent():
    out, dt = fresh('tangent.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (sphere 5) (intent create 2 0 1 0))',
                    '(node 3 (move 2 5 5 15 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))',
                    '(node 5 (intersection 1 3) (intent same 0 0 0 0))')
    record('tangent.sphere_on_plane', 'committed' in out and fx(out, 4) == ('add', '0', '0', '2', '0')
           and contains(vol(out, 4), 1000.0 + 500 * PI / 3), fx=fx(out, 4), volume=vol(out, 4), seconds=dt)
    record('tangent.inter_empty', fx(out, 5) == ('same', '0', '0', '0', '0') and vol(out, 5) == (0.0, 0.0),
           fx=fx(out, 5), volume=vol(out, 5))
    ok20, info20 = l20_ok(out, 4, 5, 1, 3, 1000.0 + 500 * PI / 3)
    record('tangent.volume_identity', ok20, **info20)
    out2, _ = fresh('kiss2.bcd',
                    '(node 1 (sphere 5) (intent create 2 0 1 0))',
                    '(node 2 (sphere 5) (intent create 2 0 1 0))',
                    '(node 3 (move 2 10 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))')
    record('tangent.kissing', fx(out2, 4) == ('add', '0', '0', '2', '0')
           and contains(vol(out2, 4), 1000 * PI / 3), fx=fx(out2, 4), volume=vol(out2, 4))


def tangent_cyl():
    out, dt = fresh('tancyl.bcd',
                    '(node 1 (cylinder 4 8) (intent create 3 0 1 0))',
                    '(node 2 (cylinder 4 8) (intent create 3 0 1 0))',
                    '(node 3 (move 2 8 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))',
                    '(node 5 (intersection 1 3) (intent same 0 0 0 0))')
    record('tangent_cyl.union', 'committed' in out and fx(out, 4) == ('add', '0', '0', '2', '0')
           and contains(vol(out, 4), 256 * PI), fx=fx(out, 4), volume=vol(out, 4), seconds=dt)
    record('tangent_cyl.inter_empty', fx(out, 5) == ('same', '0', '0', '0', '0') and vol(out, 5) == (0.0, 0.0),
           fx=fx(out, 5), volume=vol(out, 5))
    ok20, info20 = l20_ok(out, 4, 5, 1, 3, 256 * PI)
    record('tangent_cyl.volume_identity', ok20, **info20)
    c4, _ = cli('tancyl.bcd', 'check', '4')
    record('tangent_cyl.check', c4.startswith('ok:'), out=c4.strip())
    out2, _ = fresh('microov.bcd',
                    '(node 1 (cylinder 4 8) (intent create 3 0 1 0))',
                    '(node 2 (cylinder 4 8) (intent create 3 0 1 0))',
                    '(node 3 (move 2 7.999999 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 1 0))',
                    '(node 5 (difference 1 3) (intent remove 0 0 1 0))',
                    '(node 6 (intersection 1 3) (intent remove 0 0 1 0))')
    hits = {n: re.search(rf'node {n}: error (unsupported-op) .*?why: boundaries-cross-or-overlap', out2)
            for n in (4, 5, 6)}
    record('tangent_cyl.micro_union_refused', hits[4] is not None)
    record('tangent_cyl.micro_diff_refused', hits[5] is not None)
    record('tangent_cyl.micro_inter_refused', hits[6] is not None)


def chained():
    out, dt = fresh('chained.bcd',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (move 2 20 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))',
                    '(node 5 (box 4 4 4) (intent create 6 0 1 0))',
                    '(node 6 (move 5 23 3 3 0) (intent same 0 0 1 0))',
                    '(node 7 (difference 4 6) (intent remove 6 0 2 0))')
    record('chained.union_then_diff', 'committed' in out and fx(out, 7) == ('remove', '6', '0', '2', '0')
           and contains(vol(out, 7), 1936.0), fx=fx(out, 7), volume=vol(out, 7), seconds=dt)
    c7, _ = cli('chained.bcd', 'check', '7')
    record('chained.check', c7.startswith('ok:'), out=c7.strip())
    out2, _ = fresh('multi.bcd',
                    '(node 1 (prism 0 10 (region (path 1 1 (line 5 1) (line 5 5) (line 1 5))) (region (path 100 100 (line 105 100) (line 105 105) (line 100 105)))) (intent create 12 0 2 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (move 2 200 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 3 0))')
    record('chained.multi_region', fx(out2, 4) == ('add', '0', '0', '3', '0')
           and contains(vol(out2, 4), 1410.0), fx=fx(out2, 4), volume=vol(out2, 4))
    out3, _ = fresh('mixed.bcd',
                    '(node 1 (box 40 40 40) (intent create 6 0 1 0))',
                    '(node 2 (move 1 0 0 -20 0) (intent same 0 0 1 0))',
                    '(node 3 (prism 0 10 (region (path 1 1 (line 5 1) (line 5 5) (line 1 5))) (region (path 100 100 (line 105 100) (line 105 105) (line 100 105)))) (intent create 12 0 2 0))',
                    '(node 4 (difference 2 3) (intent remove 0 0 1 0))')
    m = re.search(r'node 4: error (\S+) .*?why: ([^|]+)', out3)
    record('chained.mixed_refused', m is not None and m.group(1) == 'unsupported-op'
           and 'mixed-solid-relations' in m.group(2), why=m and m.group(2).strip())


def sens():
    out, dt = fresh('sens.bcd', '(param X 30)',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (move 2 X 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))')
    s, _ = cli('sens.bcd', 'sens', 'X', '4')
    record('sens.step', 'd_volume=0' in s and 'reused' in s, out=s.strip()[:120], seconds=dt)
    v4, _ = cli('sens.bcd', 'faces', '4', '-v')
    fl = [ln for ln in v4.strip().splitlines() if ln and not ln.startswith('deleted ')]
    record('replay.lineage', len(fl) == 12 and all(ln.startswith('n1.c0.') or ln.startswith('n2.c0.') for ln in fl),
           count=len(fl), sample=fl[:2])


def face_lines(text):
    return [ln for ln in text.strip().splitlines() if ln and not ln.startswith('deleted ')]


def sens_flip():
    # h = max(|D|, 1) * 2^-20, so D = 10.000005 overlaps on the minus side.
    out, dt = fresh('flip.bcd', '(param D 10.000005)',
                    '(node 1 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 2 (box 10 10 10) (intent create 6 0 1 0))',
                    '(node 3 (move 2 D 0 0 0) (intent same 0 0 1 0))',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))')
    s, _ = cli('flip.bcd', 'sens', 'D', '4')
    reused = re.search(r'reused (\d+) of (\d+) nodes', s)
    record('sens.flip_refused', 'no derivative: the design fails within the step' in s, out=s.strip()[:160],
           seconds=dt)
    record('sens.flip_cache', reused is not None and reused.group(1) == '2' and reused.group(2) == '4',
           reused=reused.groups() if reused else None)
    # h cannot publish both a carry and an append: the overlap between them fails.
    # fns_eq is the kept face lists of those two successful outcomes.
    inn, _ = fresh('flip2.bcd', '(param D 3)',
                   '(node 1 (box 20 20 20) (intent create 6 0 1 0))',
                   '(node 2 (box 4 4 4) (intent create 6 0 1 0))',
                   '(node 3 (move 2 D 8 8 0) (intent same 0 0 1 0))',
                   '(node 4 (union 1 3) (intent same 0 0 1 0))')
    carried, _ = cli('flip2.bcd', 'faces', '4')
    edited, _ = cli('flip2.bcd', 'apply', '(param D 40)',
                    '(node 4 (union 1 3) (intent add 0 0 2 0))')
    appended, _ = cli('flip2.bcd', 'faces', '4')
    s2, _ = cli('flip2.bcd', 'sens', 'D', '4')
    reused2 = re.search(r'reused (\d+) of (\d+) nodes', s2)
    ca, ap = face_lines(carried), face_lines(appended)
    record('sens.flip_fns', 'committed' in inn and 'committed' in edited
           and len(ca) == 6 and all(ln.startswith('n1.') for ln in ca)
           and len(ap) == 12 and any(ln.startswith('n2.') for ln in ap) and ca != ap
           and 'd_volume=0' in s2
           and reused2 is not None and reused2.group(1) == '2' and reused2.group(2) == '4',
           carried=len(ca), appended=len(ap),
           reused=reused2.groups() if reused2 else None, out=s2.strip()[:160])


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (disjoint, containment, mirror, kiss_inside, contact, identical, empty_algebra, feature_on_boolean,
              slanted, crossing, intent_gate, zone_refusal, sens_cache, rotated, moved_chain, pierce, curved,
              tangent, tangent_cyl, chained, sens, sens_flip):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} passed")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
