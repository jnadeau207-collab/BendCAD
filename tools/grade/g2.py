import json
import math
import os
import re
import sys

import numpy as np
from build123d import import_step
from OCP.BRepAdaptor import BRepAdaptor_Curve, BRepAdaptor_Surface
from OCP.BRepAlgoAPI import BRepAlgoAPI_Section
from OCP.BRepExtrema import BRepExtrema_DistShapeShape
from OCP.BRepGProp import BRepGProp
from OCP.GProp import GProp_GProps
from OCP.GCPnts import GCPnts_QuasiUniformDeflection
from OCP.GeomAbs import GeomAbs_Cylinder
from OCP.gp import gp_Dir, gp_Pln, gp_Pnt
from OCP.TopAbs import TopAbs_EDGE, TopAbs_FACE
from OCP.TopExp import TopExp_Explorer
from OCP.TopoDS import TopoDS
from shapely.affinity import rotate
from shapely.geometry import LineString, Point
from shapely.ops import polygonize, unary_union

RUN, EXP = sys.argv[1], sys.argv[2]
OUT = []


def check(name, ok, **kw):
    OUT.append(dict(check=name, pass_=bool(ok), **kw))
    print(('PASS ' if ok else 'FAIL ') + name, json.dumps(kw)[:400], flush=True)


def parts():
    rows = []
    for ln in open(os.path.join(RUN, 'parts.txt')):
        if ln.startswith('#'):
            continue
        p = ln.split()
        rows.append(dict(name=p[0], node=int(p[1]), file=p[2], mat=p[3], rho=float(p[4]), n=int(p[5]),
                         vlo=float(p[6]), vhi=float(p[7]), mlo=float(p[8]), mhi=float(p[9])))
    return rows


def solids(path):
    return list(import_step(path).solids())


def vol(s):
    g = GProp_GProps()
    BRepGProp.VolumeProperties_s(s.wrapped, g, 1e-9)
    return g.Mass()


def bbox(s):
    b = s.bounding_box()
    return np.array([b.min.X, b.min.Y, b.min.Z]), np.array([b.max.X, b.max.Y, b.max.Z])


def dist(a, b):
    d = BRepExtrema_DistShapeShape(a.wrapped, b.wrapped)
    d.Perform()
    return d.Value()


def section_lines(shape, z):
    sec = BRepAlgoAPI_Section(shape.wrapped, gp_Pln(gp_Pnt(0, 0, z), gp_Dir(0, 0, 1)))
    sec.Build()
    lines = []
    ex = TopExp_Explorer(sec.Shape(), TopAbs_EDGE)
    while ex.More():
        c = BRepAdaptor_Curve(TopoDS.Edge(ex.Current()))
        q = GCPnts_QuasiUniformDeflection(c, 1e-4)
        pts = [(q.Value(i).X(), q.Value(i).Y()) for i in range(1, q.NbPoints() + 1)]
        if len(pts) > 1:
            lines.append(LineString(pts))
        ex.Next()
    return unary_union(lines)


def section(shape, z):
    return unary_union(list(polygonize(section_lines(shape, z))))


def cylinders(shape):
    out = []
    ex = TopExp_Explorer(shape.wrapped, TopAbs_FACE)
    while ex.More():
        s = BRepAdaptor_Surface(TopoDS.Face(ex.Current()))
        if s.GetType() == GeomAbs_Cylinder:
            c = s.Cylinder()
            a, l = c.Axis().Direction(), c.Location()
            out.append(dict(r=c.Radius(), d=(a.X(), a.Y(), a.Z()), p=(l.X(), l.Y(), l.Z())))
        ex.Next()
    return out


def instances():
    txt = open(os.path.join(RUN, 'q', 'assembly_g2.txt')).read()
    return [(m.group(1), int(m.group(2)), np.array([float(m.group(3)), float(m.group(4)), float(m.group(5))]))
            for m in re.finditer(r'\(inst (\S+) (\d+) (\S+) (\S+) (\S+) 0\)', txt)]


def main():
    ps = parts()
    by_node = {p['node']: p for p in ps}
    part_solid = {}
    tot = 0.0
    for p in ps:
        ss = solids(os.path.join(EXP, p['file'] + '.stp'))
        v = sum(vol(s) for s in ss)
        mid = (p['vlo'] + p['vhi']) / 2
        part_solid[p['node']] = ss[0] if ss else None
        tot += v * p['rho'] * 1e-9 * p['n']
        check('part.' + p['name'], len(ss) == 1 and abs(v - mid) <= 1e-6 * mid, solids=len(ss), step_volume=v,
              certified=[p['vlo'], p['vhi']], mass_kg=v * p['rho'] * 1e-9, evidence=p['file'] + '.stp')
    tlo = sum(p['mlo'] * p['n'] for p in ps)
    thi = sum(p['mhi'] * p['n'] for p in ps)
    check('mass.total', abs(tot - (tlo + thi) / 2) <= 1e-6 * tot, step_mass_kg=tot, certified=[tlo, thi])

    ins = instances()
    asm = solids(os.path.join(EXP, 'gear_pump_assembly.stp'))
    ok = len(asm) == len(ins)
    bad = []
    for (name, node, t), s in zip(ins, asm):
        ref = part_solid[node]
        lo, hi = bbox(s)
        rlo, rhi = bbox(ref)
        if abs(vol(s) - vol(ref)) > 1e-6 * vol(ref) or np.abs(lo - (rlo + t)).max() > 1e-6 or np.abs(hi - (rhi + t)).max() > 1e-6:
            bad.append(name)
    check('assembly.instances', ok and not bad, solids=len(asm), instances=len(ins), mismatched=bad)
    placed = {name: s for (name, node, t), s in zip(ins, asm)}
    press = {('bush_front_drive', 'front_cover'), ('bush_front_idler', 'front_cover'),
             ('bush_rear_drive', 'rear_cover'), ('bush_rear_idler', 'rear_cover')}
    rel = []
    names = list(placed)
    boxes = {n: bbox(placed[n]) for n in names}
    for i, na in enumerate(names):
        for nb in names[i + 1:]:
            (alo, ahi), (blo, bhi) = boxes[na], boxes[nb]
            if (alo > bhi + 1e-6).any() or (blo > ahi + 1e-6).any():
                continue
            common = placed[na].intersect(placed[nb])
            cv = sum(vol(x) for x in common.solids()) if common is not None else 0.0
            d = dist(placed[na], placed[nb])
            rel.append(dict(a=na, b=nb, common_mm3=cv, distance_mm=d,
                            relation='interference' if cv > 1e-6 else ('contact' if d < 1e-6 else 'clear')))
    eng = float(re.search(r'engagement=\[([\d.]+)', open(os.path.join(RUN, 'q', 'master_engage.txt')).read()).group(1))
    thread_v = math.pi / 4 * (8.0 ** 2 - 6.8 ** 2) * eng
    threads = {tuple(sorted(('front_cover', 'screw%d' % i))) for i in range(4)}
    key = lambda r: tuple(sorted((r['a'], r['b'])))
    want = {tuple(sorted(p)) for p in press}
    hit = {key(r) for r in rel if r['relation'] == 'interference'}
    thread_bad = [[r['a'], r['b'], r['common_mm3']] for r in rel if key(r) in threads and abs(r['common_mm3'] - thread_v) > 1e-6 * thread_v]
    press_bad = [[r['a'], r['b'], r['relation']] for r in rel if key(r) in want and r['relation'] != 'contact']
    seen = {key(r) for r in rel}
    check('interference.full', hit == threads and not thread_bad and not press_bad and want <= seen and threads <= seen,
          pairs_checked=len(rel), pairs_total=len(names) * (len(names) - 1) // 2,
          unexpected=sorted(hit - threads), thread_overlap_mm3=thread_v, thread_bad=thread_bad,
          press_nominal_contact=sorted(want & seen), press_bad=press_bad,
          rule='only the four M8 tapped holes overlap, each by the 6.8 mm tap-drill to 8 mm major annulus over the certified engagement; '
               'the four press fits touch at nominal size (interference is the declared ISO 286 fit); every other pair clear or touching',
          method='occt-boolean common volume, box-pruned', evidence='q/interf_occt.json')
    json.dump(rel, open(os.path.join(RUN, 'q', 'interf_occt.json'), 'w'), indent=1)

    lo = np.min([bbox(s)[0] for s in asm], axis=0)
    hi = np.max([bbox(s)[1] for s in asm], axis=0)
    check('envelope', True, box_mm=[list(lo), list(hi)], size_mm=list(hi - lo))
    fc = cylinders(placed['front_cover'])
    pilot = [c for c in fc if abs(abs(c['d'][2]) - 1) < 1e-9 and abs(2 * c['r'] - 82.55) < 0.05]
    holes = sorted({(round(c['p'][0], 3), round(c['p'][1], 3)) for c in fc if abs(abs(c['d'][2]) - 1) < 1e-9 and 4.5 < c['r'] < 8}, key=lambda q: q[1])
    span = max((math.dist(a, b) for a in holes for b in holes), default=0.0)
    check('flange.pilot', bool(pilot), pilot_diameter_mm=[2 * c['r'] for c in pilot][:1])
    check('flange.holes', abs(span - 106.4) < 1e-3, hole_centres=holes, span_mm=span)
    body = cylinders(placed['body'])
    side = [c for c in body if abs(c['d'][2]) < 1e-9 and abs(abs(c['d'][1]) - 1) < 1e-9]
    ys = sorted({round(c['p'][1], 6) for c in side})
    rmax = {}
    for c in side:
        k = 'neg' if c['p'][1] < 0 or (c['p'][1] == 0 and c['d'][1] < 0) else 'pos'
        rmax[k] = max(rmax.get(k, 0.0), c['r'])
    check('ports', len(rmax) == 2 and rmax.get('pos', 0) != rmax.get('neg', 0), port_axes='y (perpendicular to z gear axes)',
          max_bore_radius_mm=rmax)

    zm = 0.025 + 35.0 / 2
    ch = section_lines(placed['body'], zm)
    gd = section(placed['drive_shaft'], zm)
    gi = section(placed['idler_shaft'], zm)
    ra_d = max(math.hypot(x, y) for x, y in gd.exterior.coords)
    ra_i = max(math.hypot(x - 22.05, y) for x, y in gi.exterior.coords)
    tip_d = ch.distance(gd)
    tip_i = ch.distance(gi)
    check('clearance.tip', 0.02 <= min(tip_d, tip_i) <= 0.06, drive_mm=tip_d, idler_mm=tip_i, window=[0.02, 0.06],
          ra_drive=ra_d, ra_idler=ra_i)
    sd = min(dist(placed['drive_shaft'], placed['front_cover']), dist(placed['drive_shaft'], placed['rear_cover']))
    si = min(dist(placed['idler_shaft'], placed['front_cover']), dist(placed['idler_shaft'], placed['rear_cover']))
    check('clearance.side', 0.02 <= min(sd, si) <= 0.05, drive_mm=sd, idler_mm=si, window=[0.02, 0.05])

    steps = 120
    pitch = 2 * math.pi / 12
    mind = 1e9
    cross = False
    rho = []
    for k in range(steps):
        th = pitch * k / steps
        a = rotate(gd, th, origin=(0, 0), use_radians=True)
        b = rotate(gi, -th, origin=(22.05, 0), use_radians=True)
        if a.intersects(b) and a.intersection(b).area > 1e-9:
            cross = True
        d = a.distance(b)
        mind = min(mind, d)
        pa, pb = nearest(a, b)
        c = ((pa[0] + pb[0]) / 2, (pa[1] + pb[1]) / 2)
        rho.append((math.hypot(*c), math.hypot(c[0] - 22.05, c[1])))
    check('mesh', not cross and mind > 0, min_gap_mm=mind, steps=steps, pitch_deg=30)
    b = 35.0
    q = np.mean([(2 * ra_d ** 2 - r1 ** 2 - r2 ** 2) / 2 for r1, r2 in rho]) * b
    vrev = 2 * math.pi * q / 1000.0
    check('displacement', abs(vrev - 8.0) <= 0.24, cm3_per_rev=vrev, method='flow integral b*(2ra^2-rho1^2-rho2^2)/2 over the contact path of the exported outlines',
          window=[7.76, 8.24])

    calls = [json.loads(ln) for ln in open(os.path.join(RUN, 'calls.jsonl'), encoding='utf-8') if ln.strip()]
    outs = [c.get('out', '') for c in calls]
    want = ['fit bush_front_drive', 'fit bush_front_idler', 'fit bush_rear_drive', 'fit bush_rear_idler', 'fit dowel_body_a',
            'fit dowel_body_b', 'fit dowel_front_a', 'fit dowel_front_b', 'fit dowel_rear_a', 'fit dowel_rear_b',
            'stack side_20C', 'stack side_80C', 'stack tip_20C', 'stack tip_80C', 'stack run_DU1615', 'stack pilot_dia',
            'engage screw0']
    missing = [w for w in want if not any(w in o and 'certified' in o[o.index(w):o.index(w) + 600] for o in outs)]
    check('fits.in_calls', not missing, claimed=len(want), missing=missing, evidence='calls.jsonl')
    json.dump(OUT, open(os.path.join(RUN, 'grade.json'), 'w'), indent=1)
    n = sum(o['pass_'] for o in OUT)
    md = ['# G2 grade', '', 'Verdict: **%s** (%d/%d checks pass)' % ('PASS' if n == len(OUT) else 'FAIL', n, len(OUT)), '',
          'Graded from the exported STEP files with OCCT (build123d 0.13) as a reader only; no BendCAD call.', '',
          '| Check | Result | Numbers |', '|---|---|---|']
    for o in OUT:
        nums = ', '.join('%s=%s' % (k, json.dumps(v)) for k, v in o.items() if k not in ('check', 'pass_'))
        md.append('| %s | %s | %s |' % (o['check'], 'PASS' if o['pass_'] else 'FAIL', nums.replace('|', '/')))
    open(os.path.join(RUN, 'grade.md'), 'w').write(chr(10).join(md) + chr(10))
    print(n, '/', len(OUT))


def nearest(a, b):
    from shapely.ops import nearest_points
    p, q = nearest_points(a.boundary, b.boundary)
    return (p.x, p.y), (q.x, q.y)


if __name__ == '__main__':
    main()
