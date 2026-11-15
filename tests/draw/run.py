import json
import math
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import dxfcheck as DX

BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = os.environ.get('DRAW_WORK', '/var/tmp/draw-e2e')
OUT = os.environ.get('DRAW_OUT', os.path.join(ROOT, 'docs', 'receipts', 'draw', 'draw.json'))

HEX = ('(node 1000 (prism 0 10 (region (path 3.1754264805429417 0 (line 1.5877132402714709 2.75) (line -1.5877132402714709 2.75) '
       '(line -3.1754264805429417 0) (line -1.5877132402714709 -2.75) (line 1.5877132402714709 -2.75)))) (intent create any 0 1 0))')
M8_ROOT = 4.0 - 0.5 * 1.0825317547305483 * 1.25
CASES = [
    dict(name='plate', node=2, hidden=True, edits=[
        '(node 1 (box 60 40 8) (intent create any 0 1 0))',
        '(node 2 (holes 1 (face 1 n1.c0.top) through (hole 8 8 3) (hole 52 8 3) (hole 52 32 3) (hole 8 32 3) (counterbore M5 30 20)) (intent remove any any 1 5))']),
    dict(name='standoff_modelled_thread', node=1001, hidden=True, thread=dict(ext=False, rc=1.25, rr=1.5, z=(0.0, 10.0)), edits=[
        HEX, '(node 1001 (holes 1000 (face 1000 0 top) through (tapped M3 0 0 modelled)) (intent remove any any 1 1))']),
    dict(name='stud_external_thread', node=2, hidden=False, thread=dict(ext=True, rc=3.975, rr=M8_ROOT, z=(0.0, 16.0)), edits=[
        '(node 1 (cylinder 3.975 16) (intent create any 0 1 0))', '(node 2 (xthread 1 (face 1 n1.c0.wall.0.0) M8 6g) (intent remove any any 1 0))']),
    dict(name='cylinder_seam', node=1, hidden=False, seam=dict(kind='cyl', r=5.0), edits=['(node 1 (cylinder 5 20) (intent create any 0 1 0))']),
    dict(name='torus_seam', node=1, hidden=False, seam=dict(kind='torus', R=20.0, r=3.0), edits=['(node 1 (torus 20 3) (intent create any 0 1 1))']),
]
VIEWS = {'FRONT': ((0, -1, 0), (1, 0, 0), (0, 0, 1)), 'TOP': ((0, 0, 1), (1, 0, 0), (0, 1, 0)), 'LEFT': ((-1, 0, 0), (0, -1, 0), (0, 0, 1))}


def kernel(design, *args, timeout=300):
    t0 = time.time()
    p = subprocess.run([BIN, design, *args], capture_output=True, text=True, timeout=timeout)
    return p.stdout + p.stderr, round(time.time() - t0, 3)


def occt_views(stp):
    from OCP.STEPControl import STEPControl_Reader
    from OCP.HLRBRep import HLRBRep_PolyAlgo, HLRBRep_PolyHLRToShape
    from OCP.HLRAlgo import HLRAlgo_Projector
    from OCP.BRepMesh import BRepMesh_IncrementalMesh
    from OCP.gp import gp_Ax2, gp_Pnt, gp_Dir
    from OCP.Bnd import Bnd_Box
    from OCP.BRepBndLib import BRepBndLib
    r = STEPControl_Reader()
    r.ReadFile(stp)
    r.TransferRoots()
    shape = r.OneShape()
    BRepMesh_IncrementalMesh(shape, 0.005, False, 0.1, True)
    res = {}
    for nm, (d, rr, u) in VIEWS.items():
        algo = HLRBRep_PolyAlgo()
        algo.Load(shape)
        algo.Projector(HLRAlgo_Projector(gp_Ax2(gp_Pnt(0, 0, 0), gp_Dir(*d), gp_Dir(*rr))))
        algo.Update()
        hs = HLRBRep_PolyHLRToShape()
        hs.Update(algo)
        xs = []
        for comp in (hs.VCompound(), hs.OutLineVCompound(), hs.Rg1LineVCompound()):
            if comp is None or comp.IsNull():
                continue
            b = Bnd_Box()
            BRepBndLib.Add_s(comp, b)
            if not b.IsVoid():
                lo, hi = b.CornerMin(), b.CornerMax()
                xs.append((lo.X(), lo.Y(), hi.X(), hi.Y()))
        res[nm] = dict(w=max(x[2] for x in xs) - min(x[0] for x in xs), h=max(x[3] for x in xs) - min(x[1] for x in xs)) if xs else dict(w=0.0, h=0.0)
    return res


def on(v, want, tol=2e-6):
    return abs(v - want) <= tol


def thread_checks(segs, th):
    rc, rr, (z0, z1) = th['rc'], th['rr'], th['z']
    lc, lr = ('VISIBLE', 'THIN') if th['ext'] else ('HIDDEN', 'HIDDEN')
    fr = segs['FRONT']
    vert = [(a[0], min(a[1], b[1]), max(a[1], b[1]), l) for a, b, l in fr if on(a[0], b[0])]

    def span(x, layer):
        ys = sorted((y0, y1) for xx, y0, y1, l in vert if l == layer and on(xx, x))
        if not ys or not on(ys[0][0], z0):
            return False
        end = ys[0][1]
        for y0, y1 in ys[1:]:
            if y0 > end + 2e-6:
                return False
            end = max(end, y1)
        return on(end, z1)

    out = [('FRONT crest lines at +-%.4f on %s over the thread length' % (rc, lc), span(rc, lc) and span(-rc, lc)),
           ('FRONT root lines at +-%.4f on %s over the thread length' % (rr, lr), span(rr, lr) and span(-rr, lr))]
    tp = segs['TOP']
    pts = lambda layer: [p for a, b, l in tp if l == layer for p in (a, b)]
    cr = [p for p in pts('VISIBLE') if on(math.hypot(*p), rc)]
    rt = pts('THIN')
    ang = sorted({round(a + 360.0 if a < 45.0 else a, 6) for a in (math.degrees(math.atan2(p[1], p[0])) % 360.0 for p in rt)})
    out.append(('TOP crest circle at r=%.4f (visible, full turn)' % rc, len(cr) >= 16 and max(math.atan2(p[1], p[0]) for p in cr) - min(math.atan2(p[1], p[0]) for p in cr) > 6.0))
    out.append(('TOP root arc at r=%.4f on THIN, three quarters from 90 to 360 degrees, open in the upper-right quadrant' % rr,
                len(ang) >= 12 and all(on(math.hypot(*p), rr) for p in rt) and on(ang[0], 90.0, 1e-3) and on(ang[-1], 360.0, 1e-3)
                and max(b - a for a, b in zip(ang, ang[1:])) <= 20.0))
    out.append(('no helix edge drawn: FRONT has no non-axial lines inside the thread band', not any(
        not on(a[0], b[0]) and not on(a[1], b[1]) and min(abs(a[0]), abs(b[0])) < rc - 1e-6 and z0 + 1e-6 < min(a[1], b[1]) and max(a[1], b[1]) < z1 - 1e-6 for a, b, l in fr)))
    return out


def seam_checks(segs, sp):
    if sp['kind'] == 'cyl':
        r = sp['r']
        bad = [nm for nm in ('FRONT', 'LEFT') for a, b, l in segs[nm] if on(a[0], b[0]) and abs(a[0]) < r - 0.06]
        sil = [nm for nm in ('FRONT', 'LEFT') if sum(1 for a, b, l in segs[nm] if l == 'VISIBLE' and on(a[0], b[0]) and r - 0.06 <= abs(a[0]) <= r + 1e-6) != 2]
        return [('no line inside the cylinder outline (FRONT, LEFT)', not bad), ('each side view outlines the cylinder with exactly two straight silhouette lines', not sil)]
    R, r = sp['R'], sp['r']
    fr = [1 for a, b, l in segs['FRONT'] if any(abs(p[1]) < 2e-6 and abs(p[0]) < R - r - 0.1 for p in (a, b))]
    tp = [1 for a, b, l in segs['TOP'] if R - r + 0.1 < math.hypot((a[0] + b[0]) / 2, (a[1] + b[1]) / 2) < R + r - 0.1]
    return [('no equator seam across the torus in FRONT', not fr), ('no seam inside the ring in TOP (only the R+r and R-r outlines)', not tp)]


def run_case(c):
    wd = os.path.join(WORK, c['name'])
    os.makedirs(wd, exist_ok=True)
    d = os.path.join(wd, 'part.bcd')
    if os.path.exists(d):
        os.remove(d)
    kernel(d, 'new')
    ap, ts = kernel(d, 'apply', *c['edits'])
    bb = DX.bbox(ap, c['node'])
    rec = dict(case=c['name'], node=c['node'], apply_s=ts, committed=bool(re.search(r'^committed', ap, re.M)), bbox=bb)
    dx = os.path.join(wd, 'part.dxf')
    out, td = kernel(d, 'drawing', str(c['node']), dx)
    rec.update(drawing_s=td, drawing_out=out.strip()[:500])
    ok = rec['committed'] and out.startswith('wrote ') and os.path.exists(dx) and bb is not None
    checks = []
    if ok:
        dc, cks, segs = DX.check(dx, bb)
        rec['dxf'] = dc
        checks += cks
        checks.append(('drawing within the 5 s edit budget', td <= 5.0))
        if c['hidden']:
            checks.append(('hidden features are drawn dashed in FRONT', dc['views']['FRONT']['hidden'] > 0))
        if c.get('thread'):
            checks.append(('drawing reports one conventional thread', 'threads=1 ' in out))
            checks += thread_checks(segs, c['thread'])
        else:
            checks.append(('no THIN lines and no thread note without a thread', all(v['thin'] == 0 for v in dc['views'].values()) and 'threads=0 ' in out))
        if c.get('seam'):
            checks += seam_checks(segs, c['seam'])
        stp = os.path.join(wd, 'part.stp')
        so, tsp = kernel(d, 'step', str(c['node']), stp, timeout=600)
        rec['step_s'] = tsp
        try:
            t0 = time.time()
            oc = occt_views(stp)
            rec['occt'] = oc
            rec['occt_s'] = round(time.time() - t0, 2)
            for nm, v in dc['views'].items():
                o = oc[nm]
                checks.append(('%s extents agree with OCCT polygonal hidden-line projection' % nm, abs(o['w'] - v['w']) <= 0.06 + 2e-3 * o['w'] and abs(o['h'] - v['h']) <= 0.06 + 2e-3 * o['h']))
        except Exception as ex:
            rec['occt_error'] = str(ex)[:300]
            checks.append(('OCCT hidden-line projection ran', False))
    else:
        checks.append(('drawing written', False))
    rec['checks'] = [dict(name=n, ok=bool(v)) for n, v in checks]
    rec['pass'] = all(v for _, v in checks)
    return rec


def main():
    names = sys.argv[1:]
    cases = [c for c in CASES if not names or c['name'] in names]
    recs = []
    for c in cases:
        r = run_case(c)
        recs.append(r)
        print('%-4s %7.2f s  %s' % ('pass' if r['pass'] else 'fail', r.get('drawing_s', 0.0), c['name']), flush=True)
        for ch in r['checks']:
            if not ch['ok']:
                print('       fail: ' + ch['name'], flush=True)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(dict(binary=BIN, cases=recs, passed=sum(r['pass'] for r in recs), total=len(recs)), open(OUT, 'w'), indent=1)
    print('%d/%d pass -> %s' % (sum(r['pass'] for r in recs), len(recs), OUT))
    return 0 if all(r['pass'] for r in recs) else 1


if __name__ == '__main__':
    sys.exit(main())
