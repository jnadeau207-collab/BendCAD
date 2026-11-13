import concurrent.futures
import hashlib
import json
import math
import os
import re
import shutil
import subprocess
import sys
import time

import numpy as np

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, 'tools', 'mesh'))
from briefs import BRIEFS
from check import check, load

BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad-p2')
TAG = os.path.basename(BIN)
WORK = os.environ.get('MESH_WORK', f'/var/tmp/mesh-{TAG}')
OUT = os.environ.get('MESH_OUT', os.path.join(ROOT, 'docs', 'receipts', 'briefs', 'mesh.json'))
TIMEOUT = float(os.environ.get('MESH_TIMEOUT', '1200'))
WARM_SKIP_S = float(os.environ.get('MESH_WARM_SKIP_S', '90'))
CORES = [int(x) for x in os.environ.get('MESH_CORES', '2,4,6,8,10,12,14').split(',')]
BUDGET = dict(brief_mesh_s=2.0, edit_s=5.0, tri_factor=2.0, plate_s={25: 5.0, 100: 5.0, 400: 20.0}, slower_factor=1.10, slower_slack_s=0.25)
RULED = {'plane', 'planar-patch', 'cylinder', 'cone'}
KIND = {'planar-patch': 'bicubic'}
PRESET_CHORD = {None: 1.0, '0': 2.0, '1': 1.0, '2': 0.25, '3': 0.05}
PRESET_ANGLE = {None: 0.2, '0': 0.4, '1': 0.2, '2': 0.05, '3': 0.01}


def run(args, core=None, timeout=TIMEOUT):
    cmd = (['taskset', '-c', str(core)] if core is not None else []) + ['/usr/bin/time', '-f', 'maxrss_kb %M', BIN, *args]
    t0 = time.time()
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        m = re.search(r'maxrss_kb (\d+)\s*$', p.stderr)
        err = p.stderr[:m.start()] if m else p.stderr
        return dict(out=p.stdout + err, s=round(time.time() - t0, 3), timeout=False, rss_kb=int(m.group(1)) if m else None)
    except subprocess.TimeoutExpired:
        return dict(out='', s=round(time.time() - t0, 3), timeout=True)


def edit_args(e):
    return [e] if isinstance(e, str) else list(e)


def build(design, edits):
    run([design, 'new'])
    r = run([design, 'apply', *[x for e in edits for x in edit_args(e)]])
    if re.search(r'^committed', r['out'], re.M):
        return True, r['s']
    run([design, 'new'])
    for e in edits:
        if not re.search(r'^committed', run([design, 'apply', *edit_args(e)])['out'], re.M):
            return 'partial', None
    return True, None


def sha(path):
    return hashlib.sha256(open(path, 'rb').read()).hexdigest() if os.path.exists(path) else None


def vec(s):
    return np.array([float(x) for x in s.split(',')])


def ival(line, key):
    m = re.search(key + r'=\[(\S+), (\S+?)\]', line)
    return [float(m.group(1)), float(m.group(2))] if m else None


def surfaces(text):
    out = []
    for ln in text.splitlines():
        p = ln.split()
        if len(p) < 2:
            continue
        k = p[1]
        g = dict(kind=k)
        m = re.search(r'frame o=\(([^)]*)\) x=\(([^)]*)\) y=\(([^)]*)\) n=\(([^)]*)\)', ln)
        if k == 'plane' and m:
            g.update(o=vec(m.group(1)), n=vec(m.group(4)))
        m = re.search(r'axis o=\(([^)]*)\) d=\(([^)]*)\) radius=\[(\S+),', ln)
        if k == 'cylinder' and m:
            g.update(o=vec(m.group(1)), a=vec(m.group(2)), r=float(m.group(3)))
        m = re.search(r'apex=\(([^)]*)\) axis=\(([^)]*)\) tan-half-angle=\[(\S+),', ln)
        if k == 'cone' and m:
            g.update(o=vec(m.group(1)), a=vec(m.group(2)), t=float(m.group(3)))
        m = re.search(r'center=\(([^)]*)\) radius=\[(\S+),', ln)
        if k == 'sphere' and m:
            g.update(o=vec(m.group(1)), r=float(m.group(2)))
        m = re.search(r'center=\(([^)]*)\) axis=\(([^)]*)\) major-radius=\[(\S+), \S+\] minor-radius=\[(\S+),', ln)
        if k == 'torus' and m:
            g.update(o=vec(m.group(1)), a=vec(m.group(2)), R=float(m.group(3)), r=float(m.group(4)))
        out.append(g)
    return out


def sdist(g, P):
    k = g['kind']
    if k == 'plane' and 'n' in g:
        n = g['n'] / np.linalg.norm(g['n'])
        return np.abs((P - g['o']) @ n)
    if k in ('cylinder', 'cone', 'torus') and 'a' in g:
        a = g['a'] / np.linalg.norm(g['a'])
        w = P - g['o']
        h = w @ a
        rho = np.linalg.norm(w - np.outer(h, a), axis=1)
        if k == 'cylinder':
            return np.abs(rho - g['r'])
        if k == 'cone':
            return np.abs(rho - g['t'] * np.abs(h)) / math.sqrt(1 + g['t'] ** 2)
        return np.abs(np.sqrt((rho - g['R']) ** 2 + h ** 2) - g['r'])
    if k == 'sphere' and 'r' in g:
        return np.abs(np.linalg.norm(P - g['o'], axis=1) - g['r'])
    return None


def snormal(g, P):
    k = g['kind']
    if k in ('cylinder', 'cone', 'torus') and 'a' in g:
        a = g['a'] / np.linalg.norm(g['a'])
        w = P - g['o']
        h = w @ a
        rad = w - np.outer(h, a)
        rho = np.linalg.norm(rad, axis=1)
        e = rad / np.maximum(rho, 1e-300)[:, None]
        if k == 'cylinder':
            return e
        if k == 'cone':
            n = e - np.outer(g['t'] * np.sign(h), a)
            return n / np.linalg.norm(n, axis=1)[:, None]
        n = w - g['R'] * e
        return n / np.maximum(np.linalg.norm(n, axis=1), 1e-300)[:, None]
    if k == 'sphere' and 'r' in g:
        n = P - g['o']
        return n / np.maximum(np.linalg.norm(n, axis=1), 1e-300)[:, None]
    return None


def normal_dev(g, tri):
    fn = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    ln = np.linalg.norm(fn, axis=1)
    sn = snormal(g, tri.reshape(-1, 3))
    if sn is None:
        return None
    c = np.abs(np.einsum('ij,ikj->ik', fn, sn.reshape(-1, 3, 3))) / np.maximum(ln, 1e-300)[:, None]
    return np.arccos(np.clip(c.min(axis=1), -1.0, 1.0))


def deviation(obj, faces_text, ang):
    V, T, tags = load(obj)
    sf = surfaces(faces_text)
    res = dict(per_kind={}, mapped=True, unmeasured_faces=0)
    gid = np.array([int(t.split()[0][1:]) if t and t.startswith('f') else -1 for t in tags])
    for fi in sorted(set(gid.tolist())):
        sel = gid == fi
        tag = tags[int(np.nonzero(sel)[0][0])]
        kind = tag.split()[1] if tag and len(tag.split()) > 1 else 'other'
        if fi < 0 or fi >= len(sf) or KIND.get(sf[fi]['kind'], sf[fi]['kind']) != KIND.get(kind, kind):
            res['mapped'] = False
            continue
        tri = V[T[sel]]
        samples = np.concatenate([tri.mean(axis=1), 0.5 * (tri[:, 0] + tri[:, 1]), 0.5 * (tri[:, 1] + tri[:, 2]), 0.5 * (tri[:, 2] + tri[:, 0])])
        dv = sdist(sf[fi], tri.reshape(-1, 3))
        ds = sdist(sf[fi], samples)
        if ds is None:
            res['unmeasured_faces'] += 1
            continue
        pk = res['per_kind'].setdefault(kind, dict(faces=0, triangles=0, max_dev=0.0, max_vertex_off=0.0, max_normal=0.0, normal_over=0))
        pk['faces'] += 1
        pk['triangles'] += int(sel.sum())
        pk['max_dev'] = max(pk['max_dev'], float(ds.max()))
        pk['max_vertex_off'] = max(pk['max_vertex_off'], float(dv.max()))
        nd = normal_dev(sf[fi], tri)
        if nd is not None and len(nd):
            pk['max_normal'] = max(pk['max_normal'], float(nd.max()))
            pk['normal_over'] += int((nd > max(2.0 * ang, NORMAL_FLOOR)).sum())
    devs = [v['max_dev'] for v in res['per_kind'].values()]
    res['max_dev'] = max(devs) if devs else None
    offs = [v['max_vertex_off'] for v in res['per_kind'].values()]
    res['max_vertex_off'] = max(offs) if offs else None
    res['max_normal'] = max([v['max_normal'] for v in res['per_kind'].values()], default=None)
    res['normal_over'] = sum(v['normal_over'] for v in res['per_kind'].values())
    res['normal_limit'] = max(2.0 * ang, NORMAL_FLOOR)
    return res


def mesh_area(obj):
    V, T, _ = load(obj)
    P = V[T]
    return float(0.5 * np.linalg.norm(np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0]), axis=1).sum())


def tess_line(out):
    m = re.search(r'nverts (\d+) ntris (\d+) est (\d+) chord (\S+) ang (\S+)', out)
    return dict(ntris=int(m.group(2)), est=int(m.group(3)), chord=float(m.group(4)), ang=float(m.group(5))) if m else {}


def plate_edits(n):
    hs = ' '.join(f'(hole {10 + i * 10} {10 + j * 10} 3)' for i in range(n) for j in range(n))
    w = 20 + n * 10
    return [f'(node 1 (box {w} {w} 8) (intent create 6 0 1 0))', f'(node 2 (holes 1 (face 1 0 top) through {hs}) (intent remove any any 1 any))']


def DIMPLE(z):
    return ['(node 1 (box 20 20 10) (intent create any any any any))', '(node 2 (sphere 6) (intent create any any any any))',
            f'(node 3 (move 2 10 10 {z} 0) (intent same any any any any))', '(node 4 (difference 1 3) (intent remove any any any any))']


BALLHOLE = ['(node 1 (sphere 6) (intent create any any any any))', '(node 2 (cylinder 2 20) (intent create any any any any))',
            '(node 4 (move 2 0 0 -10 0) (intent same any any any any))', '(node 3 (difference 1 4) (intent remove any any any any))']
SPHEREBOX = ['(node 1 (box 20 20 20) (intent create any any any any))', '(node 2 (sphere 12) (intent create any any any any))',
             '(node 4 (move 2 10 10 10 0) (intent same any any any any))', '(node 3 (intersection 1 4) (intent same any any any any))']
XDRILL = ['(node 1 (cylinder 8 30) (intent create any any any any))', '(node 2 (cylinder 3 30) (intent create any any any any))',
          '(node 5 (rotate 2 y 90) (intent same any any any any))', '(node 4 (move 5 -15 0 15 0) (intent same any any any any))',
          '(node 3 (difference 1 4) (intent remove any any any any))']
OBLIQUE = ['(node 1 (cylinder 8 30) (intent create any any any any))', '(node 2 (box 40 40 20) (intent create any any any any))',
           '(node 5 (move 2 -20 -20 0 0) (intent same any any any any))', '(node 6 (rotate 5 x 30) (intent same any any any any))',
           '(node 4 (move 6 0 0 22 0) (intent same any any any any))', '(node 3 (difference 1 4) (intent remove any any any any))']
RSS_KB = 4000000
NORMAL_FLOOR = 0.1


def cases():
    cs = []
    for b in BRIEFS:
        parts = list(b['parts']) + ([1001] if b['id'] == 'B10' else [])
        for n in parts:
            cs.append(dict(id=f"{b['id']}.n{n}", group='brief', brief=b['id'], edits=b['edits'], node=n, preset=None,
                           budget_s=BUDGET['brief_mesh_s'], budget_on='mesh_s'))
    for n in (5, 10, 20):
        cs.append(dict(id=f'plate.holes{n * n}', group='plate', edits=plate_edits(n), node=2, preset='2', holes=n * n,
                       budget_s=BUDGET['plate_s'][n * n], budget_on='tess_s'))
    for n in (3, 6):
        cs.append(dict(id=f'blade.n{n}', group='blade', design=os.path.join(ROOT, 'tests', 'speed', 'k4blade.bcd'), node=n, preset=None,
                       budget_s=None, budget_on='ref'))
    for z in (9, 10, 12):
        for pr in (None, '2'):
            cs.append(dict(id=f"curved.dimple{z}.p{pr or '1'}", group='curved', edits=DIMPLE(z), node=4, preset=pr, budget_s=BUDGET['brief_mesh_s'], budget_on='mesh_s'))
    for nm, ed in (('ballhole', BALLHOLE), ('spherebox', SPHEREBOX), ('xdrill', XDRILL), ('oblique', OBLIQUE)):
        for pr in (None, '2'):
            cs.append(dict(id=f'curved.{nm}.p{pr or "1"}', group='curved', edits=ed, node=3, preset=pr, budget_s=BUDGET['brief_mesh_s'], budget_on='mesh_s'))
    for pr in (None, '2'):
        cs.append(dict(id=f'curved.fz103.p{pr or "1"}', group='curved', design=os.path.join(ROOT, 'tests', 'speed', 'fz103.bcd'), node=100, preset=pr,
                       budget_s=BUDGET['brief_mesh_s'], budget_on='mesh_s'))
    b11 = [b for b in BRIEFS if b['id'] == 'B11'][0]
    cs.append(dict(id='curved.B11.p2', group='fine', brief='B11', edits=b11['edits'], node=1110, preset='2', budget_s=None, budget_on='none'))
    cs.append(dict(id='curved.B11.p3', group='fine', brief='B11', edits=b11['edits'], node=1110, preset='3', budget_s=None, budget_on='none'))
    cs.append(dict(id='repro.tess_display_slow.n705', group='repro', design=os.path.join(ROOT, 'tests', 'briefs', 'repro', 'tess_display_slow', 'design.bcd'),
                   node=705, preset=None, budget_s=BUDGET['brief_mesh_s'], budget_on='mesh_s'))
    return cs


def designs(cs):
    os.makedirs(WORK, exist_ok=True)
    built = {}
    for c in cs:
        key = c.get('brief') or c['id'] if 'edits' in c else c['design']
        if key not in built:
            d = os.path.join(WORK, re.sub(r'[^A-Za-z0-9]+', '_', key) + '.bcd')
            if 'edits' in c:
                ok, s = build(d, c['edits'])
            else:
                shutil.copy(c['design'], d)
                ok, s = True, None
            built[key] = (d, ok, s)
        c['design_path'], c['built'], c['build_s'] = built[key]
    return cs


def tess_args(c, ob):
    return [c['design_path'], 'tess', str(c['node']), ob] + ([c['preset']] if c['preset'] else [])


def serial(c, core):
    r = dict(id=c['id'], group=c['group'], node=c['node'], preset=c['preset'] or 'default (1)', built=c['built'], core=core)
    if c.get('holes'):
        r['holes'] = c['holes']
    if not c['built']:
        r['why'] = 'design did not build on this binary'
        return r
    d, n = c['design_path'], str(c['node'])
    run([d, 'measure', n], core)
    me = run([d, 'measure', n], core)
    line = me['out'].strip().splitlines()[0] if me['out'].strip() else ''
    r['eval_s'] = me['s']
    if not line.startswith('ok'):
        r['built'] = False
        r['why'] = 'node does not evaluate on this binary: ' + line[:300]
        return r
    r['certified_volume'] = ival(line, 'volume')
    r['certified_area'] = ival(line, 'area')
    fx = run([d, 'faces', n, '-f'], core)
    r['faces_text'] = fx['out']
    kinds = sorted({ln.split()[1] for ln in fx['out'].splitlines() if len(ln.split()) > 1})
    r['surface_kinds'] = kinds
    r['ruled_only'] = bool(kinds) and set(kinds) <= RULED
    ob = os.path.join(WORK, re.sub(r'[^A-Za-z0-9]+', '_', c['id']) + '.obj')
    if os.path.exists(ob):
        os.remove(ob)
    t1 = run(tess_args(c, ob), core)
    runs = [t1['s']]
    t = t1
    if not t1['timeout'] and t1['s'] <= WARM_SKIP_S:
        t = run(tess_args(c, ob), core)
        runs.append(t['s'])
    r['tess_runs_s'] = runs
    r['tess_s'] = t['s']
    r['timing'] = ('warm: second of two runs' if len(runs) == 2 else 'first run only (over %g s, warm repeat skipped)' % WARM_SKIP_S) + f', one core (taskset -c {core})'
    r['timeout'] = t['timeout']
    r['tess_out'] = t['out'].strip()[:600]
    r['mesh_s'] = round(t['s'] - me['s'], 3)
    ok = (not t['timeout']) and t['out'].startswith('wrote') and os.path.exists(ob)
    r['written'] = ok
    if not ok:
        return r
    r.update(tess_line(t['out']))
    r['tess_maxrss_kb'] = t.get('rss_kb')
    m = re.search(r'refined=(\d+)', t['out'])
    r['refined'] = int(m.group(1)) if m else None
    m = re.search(r'normal-dev=(\S+)', t['out'])
    r['normal_dev_reported'] = float(m.group(1)) if m else None
    m = re.search(r'freeform=(\d+)', t['out'])
    r['freeform'] = int(m.group(1)) if m else None
    r['obj'] = ob
    r['obj_sha256'] = sha(ob)
    mc = check(ob)
    r.update({k: mc[k] for k in ('triangles', 'vertices', 'zero_area', 'zero_area_by_group', 'edge_uses', 'same_direction_pairs', 't_junctions', 'duplicate_triangles', 'conforming', 'volume')})
    r['mesh_area'] = mesh_area(ob)
    dv = deviation(ob, fx['out'], PRESET_ANGLE[c['preset']])
    r['deviation'] = dv
    if r['certified_volume']:
        lo, hi = r['certified_volume']
        mid = 0.5 * (lo + hi)
        r['volume_err'] = mc['volume'] - mid
        r['volume_rel_err'] = (mc['volume'] - mid) / mid
        dmax = max(r.get('chord') or 0.0, dv['max_dev'] or 0.0)
        r['volume_bound_achieved'] = dmax * r['mesh_area'] + 0.5 * (hi - lo)
        r['volume_bound_preset'] = PRESET_CHORD[c['preset']] * r['mesh_area'] + 0.5 * (hi - lo)
    return r


def parallel(c, r):
    if not r.get('written'):
        return r
    ob = r['obj'] + '.par.obj'
    t = run(tess_args(c, ob))
    r['tess_all_cores_s'] = t['s']
    r['all_cores'] = os.cpu_count()
    r['identical_across_threads'] = sha(ob) == r['obj_sha256']
    if os.path.exists(ob):
        os.remove(ob)
    return r


def stl(c):
    sp = os.path.join(WORK, re.sub(r'[^A-Za-z0-9]+', '_', c['id']) + '.stl')
    t = run([c['design_path'], 'stl', str(c['node']), sp, '3'])
    ok = (not t['timeout']) and t['out'].startswith('wrote')
    if os.path.exists(sp):
        os.remove(sp)
    return dict(id=c['id'], s=t['s'], ok=ok, timeout=t['timeout'], out=t['out'].strip()[:300], maxrss_kb=t.get('rss_kb'),
                crashed=bool(not ok and not t['timeout'] and not t['out'].startswith(('refused', 'error'))), timing='one run, all cores, nothing else running')


def edit(b):
    if not b.get('edit'):
        return None
    wd = os.path.join(WORK, 'edit')
    os.makedirs(wd, exist_ok=True)
    d = os.path.join(wd, b['id'] + '.bcd')
    ok, _ = build(d, b['edits'])
    rec = dict(brief=b['id'], label=b['edit']['label'], built=ok, timing='one run, all cores, nothing else running')
    if not ok:
        return rec
    p0 = str(b['parts'][0])
    ea = run([d, 'apply', *edit_args(b['edit']['edit'])])
    rec['apply_s'] = ea['s']
    rec['apply_status'] = 'committed' if re.search(r'^committed', ea['out'], re.M) else 'rejected'
    if rec['apply_status'] != 'committed':
        rec['apply_out'] = ea['out'][-600:]
        return rec
    ck = run([d, 'check', p0])
    ob = os.path.join(wd, b['id'] + '.obj')
    ts = run([d, 'tess', p0, ob])
    rec.update(check_s=ck['s'], tess_s=ts['s'], tess_out=ts['out'].strip()[:300], shown=ts['out'].startswith('wrote'))
    rec['visible_rechecked_s'] = round(ea['s'] + ck['s'] + ts['s'], 3)
    rec['verdict'] = 'pass' if rec['shown'] and rec['visible_rechecked_s'] <= BUDGET['edit_s'] else 'fail'
    if os.path.exists(ob):
        os.remove(ob)
    return rec


def zero_cnt(r):
    return dict(zero_area=r.get('zero_area'), same_direction_pairs=r.get('same_direction_pairs'), t_junctions=r.get('t_junctions'),
                bad_edge_uses=sum(v for k, v in (r.get('edge_uses') or {}).items() if k != '2'))


def judge(rows, ref, stls, refstl, edits):
    v = {}
    br = [r for r in rows if r['group'] in ('brief', 'repro')]
    for r in rows:
        b = []
        if r.get('written'):
            if r['group'] in ('brief', 'repro'):
                b.append(('time', r['mesh_s'] <= BUDGET['brief_mesh_s'], f"mesh {r['mesh_s']} s (tess {r['tess_s']} - eval {r['eval_s']}) <= {BUDGET['brief_mesh_s']}"))
            if r['group'] == 'plate':
                b.append(('time', r['tess_s'] <= BUDGET['plate_s'][r['holes']], f"tess {r['tess_s']} s <= {BUDGET['plate_s'][r['holes']]}"))
            if r['group'] == 'curved':
                b.append(('time', r['mesh_s'] <= BUDGET['brief_mesh_s'], f"mesh {r['mesh_s']} s <= {BUDGET['brief_mesh_s']}"))
                b.append(('triangles', r['triangles'] <= BUDGET['tri_factor'] * r['est'], f"{r['triangles']} <= {BUDGET['tri_factor']} x est {r['est']}"))
            if r['group'] in ('curved', 'fine'):
                b.append(('direct', r.get('refined') == 0, f"refined={r.get('refined')} (every analytic face on the direct path)"))
            if r['group'] == 'fine':
                b.append(('memory', (r.get('tess_maxrss_kb') or 1e12) <= RSS_KB, f"peak RSS {r.get('tess_maxrss_kb')} kB <= {RSS_KB}"))
            if r['ruled_only'] and r['group'] != 'blade':
                b.append(('triangles', r['triangles'] <= BUDGET['tri_factor'] * r['est'], f"{r['triangles']} <= {BUDGET['tri_factor']} x est {r['est']}"))
            b.append(('conforming', bool(r['conforming']), f"zero-area {r['zero_area']}, edge uses {r['edge_uses']}, same-direction {r['same_direction_pairs']}, T {r['t_junctions']}, duplicate triangles {r.get('duplicate_triangles')}"))
            if r['group'] != 'blade':
                ch = PRESET_CHORD[r['preset'] if r['preset'] != 'default (1)' else None]
                b.append(('chord_claim', r.get('chord') is not None and r['chord'] <= ch, f"reported chord {r.get('chord')} <= preset {ch}"))
                md = r['deviation']['max_dev']
                if md is None or not r['deviation']['mapped']:
                    b.append(('deviation_measured', None, f"not measured: the mesh has no face groups that match faces -f (mapped {r['deviation']['mapped']}, max {md})"))
                else:
                    b.append(('deviation_measured', md <= max(r.get('chord') or 0.0, 1e-9) * (1 + 1e-6) + 1e-9,
                              f"measured max deviation {md} <= reported chord {r.get('chord')} over {sum(v['faces'] for v in r['deviation']['per_kind'].values())} analytic faces, {r['deviation']['unmeasured_faces']} freeform faces not measured"))
                mn = r['deviation'].get('max_normal')
                if mn is not None and r['deviation']['mapped']:
                    b.append(('normals', mn <= r['deviation']['normal_limit'] * (1 + 1e-9),
                              f"largest angle between a triangle and the surface normal at its vertices {mn:.4f} rad <= {r['deviation']['normal_limit']} (twice the preset angle, floor {NORMAL_FLOOR}); {r['deviation']['normal_over']} triangles over"))
                nr = r.get('normal_dev_reported')
                if mn is not None and r['deviation']['mapped'] and nr is not None and r.get('refined') == 0 and r.get('freeform') == 0:
                    b.append(('normal_claim', mn <= nr * (1 + 1e-6) + 1e-9, f"measured {mn:.6f} rad <= reported normal-dev {nr}"))
                if 'volume_err' in r:
                    b.append(('volume', abs(r['volume_err']) <= r['volume_bound_achieved'], f"|dV| {abs(r['volume_err']):.6g} <= chord x area {r['volume_bound_achieved']:.6g}"))
            if r['group'] == 'blade' and ref.get(r['id']):
                q = ref[r['id']]
                if q.get('written'):
                    lim = q['tess_s'] * BUDGET['slower_factor'] + BUDGET['slower_slack_s']
                    b.append(('not_slower', r['tess_s'] <= lim, f"{r['tess_s']} s <= ref {q['tess_s']} x {BUDGET['slower_factor']} + {BUDGET['slower_slack_s']}"))
                    a, z = zero_cnt(r), zero_cnt(q)
                    b.append(('conformity_kept', all((a[k] or 0) <= (z[k] or 0) for k in a), f'now {a} ref {z}'))
            if 'identical_across_threads' in r:
                b.append(('deterministic', r['identical_across_threads'], f"1 core and {r.get('all_cores')} cores byte-identical"))
        else:
            b.append(('written', False, r.get('why') or r.get('tess_out', '')[:200]))
        r['budgets'] = [dict(name=n, verdict='not-measured' if ok is None else 'pass' if ok else 'fail', detail=d) for n, ok, d in b]
        r['pass'] = all(ok is not False for _, ok, _ in b)
    v['1_display_time'] = dict(
        brief_parts_le_2s=all(r.get('written') and r['mesh_s'] <= 2.0 for r in br if r['built']),
        holes100_le_5s=any(r['id'] == 'plate.holes100' for r in rows) and all(r.get('written') and r['tess_s'] <= 5.0 for r in rows if r['id'] == 'plate.holes100'),
        worst=max((((r.get('mesh_s') or 1e9) if r.get('written') else 1e9, r['id']) for r in br if r['built']), default=None))
    v['2_triangles'] = dict(ruled_parts_le_2x_est=all(r['triangles'] <= 2 * r['est'] for r in rows if r.get('written') and r['ruled_only'] and r['group'] != 'blade'),
                            curved_parts=[dict(id=r['id'], kinds=r['surface_kinds'], triangles=r.get('triangles'), est=r.get('est')) for r in rows
                                          if r.get('surface_kinds') and not r['ruled_only']])
    v['3_conforming'] = dict(all=all(r.get('conforming') for r in rows if r['built'] and r['group'] != 'blade'),
                             volume_within_chord_bound=all(abs(r['volume_err']) <= r['volume_bound_achieved'] for r in rows if 'volume_err' in r and r['group'] != 'blade'))
    v['5_b11'] = [dict(id=r['id'], written=r.get('written'), conforming=r.get('conforming'), out=r.get('tess_out', '')[:200]) for r in rows if r['id'].startswith('B11.')]
    pl = sorted([r for r in rows if r['group'] == 'plate' and r.get('written')], key=lambda r: r['holes'])
    if len(pl) >= 2:
        x = np.log([r['triangles'] for r in pl])
        y = np.log([max(r['mesh_s'], 1e-3) for r in pl])
        v['8_scaling'] = dict(points=[dict(holes=r['holes'], triangles=r['triangles'], tess_s=r['tess_s'], eval_s=r['eval_s'], mesh_s=r['mesh_s']) for r in pl],
                              loglog_slope_mesh_s_vs_triangles=float(np.polyfit(x, y, 1)[0]))
    if stls is not None:
        rs = {s['id']: s for s in refstl} if refstl else {}
        for s in stls:
            q = rs.get(s['id'])
            if q and q['ok']:
                s['ref_s'] = q['s']
                s['not_slower'] = bool(s['ok'] and s['s'] <= q['s'] * BUDGET['slower_factor'] + BUDGET['slower_slack_s'])
        v['7_stl_not_slower'] = all(s.get('not_slower', True) for s in stls) if rs else None
        v['7_stl_no_crash'] = dict(all=not any(s.get('crashed') for s in stls), crashed=[s['id'] for s in stls if s.get('crashed')])
    if edits is not None:
        v['4_edit_budget'] = {e['brief']: dict(verdict=e.get('verdict', 'fail'), s=e.get('visible_rechecked_s'), apply_s=e.get('apply_s'), check_s=e.get('check_s'),
                                               tess_s=e.get('tess_s')) for e in edits if e}
    return v


def main():
    args = sys.argv[1:]
    jobs = 1
    if '--jobs' in args:
        i = args.index('--jobs')
        jobs = int(args[i + 1])
        del args[i:i + 2]
    refp = None
    if '--ref' in args:
        i = args.index('--ref')
        refp = args[i + 1]
        del args[i:i + 2]
    if '--rejudge' in args:
        rj = json.load(open(OUT, encoding='utf-8'))
        rf = {}
        rs = None
        if refp and os.path.exists(refp):
            q = json.load(open(refp, encoding='utf-8'))
            rf = {r['id']: r for r in q['rows']}
            rs = q.get('stl')
        rj['acceptance'] = judge(rj['rows'], rf, rj.get('stl'), rs, rj.get('edits'))
        rj['ref'] = refp
        rj['passed'] = sum(1 for r in rj['rows'] if r['pass'])
        json.dump(rj, open(OUT, 'w', encoding='utf-8', newline='\n'), indent=1)
        print(json.dumps(rj['acceptance'], indent=1))
        print(f"{rj['passed']}/{rj['total']} cases pass -> {OUT}")
        return
    do_stl = '--stl' in args
    do_edit = '--edit' in args
    only = [a for a in args if not a.startswith('--')]
    cs = [c for c in cases() if not only or any(c['id'] == o or c['id'].startswith(o + '.') for o in only)]
    t0 = time.time()
    designs(cs)
    with concurrent.futures.ThreadPoolExecutor(min(jobs, len(CORES))) as ex:
        futs = {}
        for i, c in enumerate(cs):
            futs[ex.submit(serial, c, CORES[i % min(jobs, len(CORES))])] = c
        rows = {}
        for f in concurrent.futures.as_completed(futs):
            r = f.result()
            rows[r['id']] = r
            print(json.dumps({k: r.get(k) for k in ('id', 'tess_s', 'eval_s', 'mesh_s', 'triangles', 'est', 'conforming', 'chord')}), flush=True)
    rows = [rows[c['id']] for c in cs]
    for c, r in zip(cs, rows):
        parallel(c, r)
    ref = {}
    refstl = None
    if refp and os.path.exists(refp):
        rj = json.load(open(refp, encoding='utf-8'))
        ref = {r['id']: r for r in rj['rows']}
        refstl = rj.get('stl')
    stls = [stl(c) for c in cs if c['group'] == 'brief' and c['built']] if do_stl else None
    edits = [edit(b) for b in BRIEFS] if do_edit else None
    v = judge(rows, ref, stls, refstl, edits)
    for r in rows:
        r.pop('faces_text', None)
        ob = r.pop('obj', None)
        if ob and os.path.exists(ob):
            os.remove(ob)
    rec = dict(binary=BIN, sha256=sha(BIN), host_cores=os.cpu_count(), runner='tests/briefs/mesh.py', budgets=BUDGET, ref=refp,
               method='each case built from its brief edits; measure and tess run twice pinned to one core, the second run recorded; mesh_s = tess_s - eval_s (eval_s from measure); '
                      'one more tess on all cores checks byte identity across thread counts; tools/mesh/check.py judges conformity; deviation samples each triangle centroid and edge midpoints '
                      'against the analytic surface printed by faces -f; normals compares each triangle normal with the analytic surface normal at its three vertices; '
                      'duplicate triangles are triangles with the same three welded vertices',
               wall_s=round(time.time() - t0, 1), acceptance=v, rows=rows, stl=stls, edits=edits,
               passed=sum(1 for r in rows if r['pass']), total=len(rows))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(rec, open(OUT, 'w', encoding='utf-8', newline='\n'), indent=1)
    print(json.dumps(v, indent=1))
    print(f"{rec['passed']}/{rec['total']} cases pass -> {OUT}")
    sys.exit(0 if rec['passed'] == rec['total'] else 1)


if __name__ == '__main__':
    main()
