import json
import math
import os
import re
import sys

import numpy as np
from build123d import import_step
from OCP.BRepAdaptor import BRepAdaptor_Surface
from OCP.BRepAlgoAPI import BRepAlgoAPI_Common
from OCP.BRepExtrema import BRepExtrema_DistShapeShape
from OCP.BRepGProp import BRepGProp
from OCP.BRepPrimAPI import BRepPrimAPI_MakeBox
from OCP.GeomAbs import GeomAbs_Cylinder
from OCP.GProp import GProp_GProps
from OCP.gp import gp_Pnt
from OCP.TopAbs import TopAbs_FACE
from OCP.TopExp import TopExp_Explorer
from OCP.TopoDS import TopoDS
from scipy.linalg import eigh

RUN, EXP = sys.argv[1], sys.argv[2]
OUT = []
RPM = 2900.0
G = 2.5


def check(name, ok, deferred=None, **kw):
    st = 'DEFERRED' if deferred else ('PASS' if ok else 'FAIL')
    OUT.append(dict(check=name, status=st, pass_=bool(ok), **({'deferred': deferred} if deferred else {}), **kw))
    print(st + ' ' + name, json.dumps(kw)[:400], flush=True)


def stl_mesh(path):
    data = open(path, 'rb').read()
    vs = [tuple(map(float, m)) for m in re.findall(rb'vertex\s+(\S+)\s+(\S+)\s+(\S+)', data)]
    ts = [vs[i:i + 3] for i in range(0, len(vs), 3)]
    key = lambda v: (round(v[0], 6), round(v[1], 6), round(v[2], 6))
    es = {}
    vol = 0.0
    for a, b, c in ts:
        for u, v in ((a, b), (b, c), (c, a)):
            es[(key(u), key(v))] = es.get((key(u), key(v)), 0) + 1
        vol += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0]) + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
    return len(ts), sum(1 for (u, v), n in es.items() if es.get((v, u), 0) != n), vol


def parts():
    rows = []
    for ln in open(os.path.join(RUN, 'parts.txt')):
        if ln.startswith('#'):
            continue
        p = ln.split()
        rows.append(dict(name=p[0], node=int(p[1]), file=p[2], mat=p[3], rho=float(p[4]), n=int(p[5]),
                         vlo=float(p[6]), vhi=float(p[7])))
    return rows


def solids(path):
    return list(import_step(path).solids())


def props(s):
    g = GProp_GProps()
    BRepGProp.VolumeProperties_s(s.wrapped, g, 1e-9)
    c = g.CentreOfMass()
    return g.Mass(), np.array([c.X(), c.Y(), c.Z()]), g


def bbox(s):
    b = s.bounding_box()
    return np.array([b.min.X, b.min.Y, b.min.Z]), np.array([b.max.X, b.max.Y, b.max.Z])


def dist(a, b):
    d = BRepExtrema_DistShapeShape(a, b)
    d.Perform()
    return d.Value()


def common_volume(a, b):
    op = BRepAlgoAPI_Common(a, b)
    op.Build()
    g = GProp_GProps()
    BRepGProp.VolumeProperties_s(op.Shape(), g, 1e-9)
    return g.Mass()


def boxed(shape, lo, hi):
    bx = BRepPrimAPI_MakeBox(gp_Pnt(*lo), gp_Pnt(*hi)).Shape()
    op = BRepAlgoAPI_Common(shape, bx)
    op.Build()
    return op.Shape()


def cylinders(shape):
    out = []
    ex = TopExp_Explorer(shape, TopAbs_FACE)
    while ex.More():
        s = BRepAdaptor_Surface(TopoDS.Face(ex.Current()))
        if s.GetType() == GeomAbs_Cylinder:
            c = s.Cylinder()
            a, l = c.Axis().Direction(), c.Location()
            out.append(dict(r=c.Radius(), d=np.array([a.X(), a.Y(), a.Z()]), p=np.array([l.X(), l.Y(), l.Z()])))
        ex.Next()
    return out


def hole_axes(shape, r, axis, tol=1e-6):
    pts = []
    for c in cylinders(shape):
        if abs(c['r'] - r) < tol and abs(abs(np.dot(c['d'], axis)) - 1) < 1e-9:
            q = c['p'] - np.dot(c['p'], axis) * axis
            if not any(np.linalg.norm(q - x) < 1e-6 for x in pts):
                pts.append(q)
    return pts


def instances():
    txt = open(os.path.join(RUN, 'q', 'assembly.txt')).read()
    return [(m.group(1), int(m.group(2)), np.array([float(m.group(3)), float(m.group(4)), float(m.group(5))]))
            for m in re.finditer(r'\(inst (\S+) (\d+) (\S+) (\S+) (\S+) 0\)', txt)]


def camber_angle(p, centre, ccw):
    r = p - centre
    t = np.array([-r[1], r[0]]) * (1 if ccw else -1)
    t = t / np.linalg.norm(t)
    u = np.array([-p[1], p[0]]) / np.linalg.norm(p)
    return math.degrees(math.acos(min(1.0, abs(float(np.dot(t, u))))))


def blades(imp, spec):
    cs = [c for c in cylinders(imp.wrapped) if abs(c['d'][2]) > 1 - 1e-9 and 150 < c['r'] < 260]
    centres = []
    for c in cs:
        q = c['p'][:2]
        if np.linalg.norm(q) < 1e-6:
            continue
        if not any(np.linalg.norm(q - x) < 1e-6 for x in centres):
            centres.append(q)
    out = []
    for q in centres:
        rr = sorted({round(c['r'], 6) for c in cs if np.linalg.norm(c['p'][:2] - q) < 1e-6})
        rm = (rr[0] + rr[-1]) / 2 if len(rr) >= 2 else rr[0]
        d = np.linalg.norm(q)
        cross = []
        for rad in (spec['r_le'], spec['r_te']):
            a = (rad * rad - rm * rm + d * d) / (2 * d)
            h = math.sqrt(max(rad * rad - a * a, 0.0))
            base = q / d * a
            perp = np.array([-q[1], q[0]]) / d
            cands = [base + perp * h, base - perp * h]
            cross.append(cands)
        out.append(dict(centre=q, r_camber=rm, wall_radii=rr, pts=cross))
    return out


def eb_rotor(spec):
    segs = [tuple(map(float, m.groups())) for m in re.finditer(r'\(seg (\S+) (\S+) (\S+) (\S+) (\S+) (\S+)\)', spec)]
    discs = [tuple(map(float, m.groups())) for m in re.finditer(r'\(disc (\S+) (\S+) (\S+)\)', spec)]
    brgs = [tuple(map(float, m.groups())) for m in re.finditer(r'\(brg (\S+) (\S+) (\S+)\)', spec)]
    xs, els = [0.0], []
    for L, od, idi, e, nu, rho in segs:
        for k in range(40):
            els.append((xs[-1], L / 40, od, idi, e, rho))
            xs.append(xs[-1] + L / 40)
    n = 2 * len(xs)
    K, M = np.zeros((n, n)), np.zeros((n, n))
    for i, (x0, L, od, idi, e, rho) in enumerate(els):
        a = math.pi * (od ** 2 - idi ** 2) / 4
        ii = math.pi * (od ** 4 - idi ** 4) / 64
        k = e * ii / L ** 3 * np.array([[12, 6 * L, -12, 6 * L], [6 * L, 4 * L * L, -6 * L, 2 * L * L],
                                        [-12, -6 * L, 12, -6 * L], [6 * L, 2 * L * L, -6 * L, 4 * L * L]])
        m = rho * 1e-9 * a * L / 420 * np.array([[156, 22 * L, 54, -13 * L], [22 * L, 4 * L * L, 13 * L, -3 * L * L],
                                                [54, 13 * L, 156, -22 * L], [-13 * L, -3 * L * L, -22 * L, 4 * L * L]])
        d = [2 * i, 2 * i + 1, 2 * i + 2, 2 * i + 3]
        K[np.ix_(d, d)] += k
        M[np.ix_(d, d)] += m
    at = lambda x: int(np.argmin([abs(v - x) for v in xs]))
    for x, mass, jd in discs:
        j = at(x)
        M[2 * j, 2 * j] += mass
        M[2 * j + 1, 2 * j + 1] += jd
    for x, kw, kt in brgs:
        j = at(x)
        K[2 * j, 2 * j] += kw
        K[2 * j + 1, 2 * j + 1] += kt
    lam = eigh(K, M, eigvals_only=True)
    lam = np.sort(lam[lam > 1e-6])
    return math.sqrt(lam[0] * 1e3) / (2 * math.pi) * 60


def kernel_iv(path, verb):
    t = open(path).read()
    m = re.search(verb + r' \[([^,]+), ([^\]]+)\] (\w+)', t)
    return (float(m.group(1)), float(m.group(2)), m.group(3)) if m else None


def main():
    spec = json.load(open(os.path.join(RUN, 'calc', 'claims.json')))
    ps = parts()
    by_name = {p['name']: p for p in ps}
    part_solid = {}
    tot = 0.0
    for p in ps:
        ss = solids(os.path.join(EXP, p['file'] + '.stp'))
        v = sum(props(s)[0] for s in ss)
        mid = (p['vlo'] + p['vhi']) / 2
        part_solid[p['name']] = ss[0] if ss else None
        tot += v * p['rho'] * 1e-9 * p['n']
        check('part.' + p['name'], len(ss) == 1 and abs(v - mid) <= 1e-6 * mid, solids=len(ss), step_volume=v,
              certified=[p['vlo'], p['vhi']], mass_kg=v * p['rho'] * 1e-9, evidence=p['file'] + '.stp')
        sp = os.path.join(EXP, p['file'] + '.stl')
        if os.path.exists(sp):
            nt, op, sv = stl_mesh(sp)
            check('stl.' + p['name'], nt > 0 and op == 0 and abs(sv - v) <= 0.01 * v, triangles=nt, unpaired_edges=op,
                  mesh_volume=sv, step_volume=v, rule='closed, consistently oriented, volume within 1% of STEP',
                  evidence=p['file'] + '.stl')
        else:
            check('stl.' + p['name'], False, rule='STL at manufacturing tolerance exported', evidence='missing ' + p['file'] + '.stl')
    tlo = sum(p['vlo'] * p['rho'] * 1e-9 * p['n'] for p in ps)
    thi = sum(p['vhi'] * p['rho'] * 1e-9 * p['n'] for p in ps)
    check('mass.total', abs(tot - (tlo + thi) / 2) <= 1e-6 * tot, step_mass_kg=tot, certified=[tlo, thi])

    imp = part_solid['impeller']
    vi, ci, gi = props(imp)
    m_imp = vi * by_name['impeller']['rho'] * 1e-9
    e_um = float(np.linalg.norm(ci[:2])) * 1e3
    w = RPM * 2 * math.pi / 60
    e_perm = G / w * 1e3
    check('balance.static', e_um < e_perm, com_offset_um=e_um, permissible_um=e_perm, grade='G%.1f' % G, rpm=RPM,
          impeller_mass_kg=m_imp, residual_gmm=m_imp * 1e3 * e_um * 1e-3, permissible_gmm=m_imp * 1e3 * e_perm * 1e-3,
          claimed_um=spec.get('balance_offset_um'))

    lo, hi = bbox(imp)
    bl = blades(imp, spec)
    angs = []
    for b in bl:
        for k, cands in enumerate(b['pts']):
            vals = [camber_angle(p, b['centre'], True) for p in cands]
            angs.append((k, min(vals, key=lambda a: abs(a - spec['beta_deg'][k]))))
    le = [a for k, a in angs if k == 0]
    te = [a for k, a in angs if k == 1]
    check('impeller.blades', len(bl) == spec['z'] and le and te and max(abs(a - spec['beta_deg'][0]) for a in le) < 1.0 and
          max(abs(a - spec['beta_deg'][1]) for a in te) < 1.0,
          blades=len(bl), beta1_deg=[min(le), max(le)] if le else None, beta2_deg=[min(te), max(te)] if te else None,
          claimed=spec['beta_deg'], camber_radii=sorted({round(b['r_camber'], 3) for b in bl}))
    tips = [math.hypot(*c['p'][:2]) + c['r'] for c in cylinders(imp.wrapped)
            if abs(c['d'][2]) > 1 - 1e-9 and 1.5 < c['r'] < 2.5 and math.hypot(*c['p'][:2]) > 200]
    tr = spec['tip_radius_mm']
    check('impeller.diameter', abs(min(tips) - tr[0]) < 1e-6 and abs(max(tips) - tr[1]) < 1e-6 and abs(max(tips) * 2 - spec['d2_mm']) < 0.05
          and abs(hi[0] - lo[0] - spec['disc_od_mm']) < 1e-3,
          blade_tip_diameter_mm=[2 * min(tips), 2 * max(tips)], disc_od_mm=hi[0] - lo[0], claimed=[[2 * tr[0], 2 * tr[1]], spec['d2_mm'], spec['disc_od_mm']])

    ins = instances()
    asm = solids(os.path.join(EXP, 'blower_assembly.stp'))
    names = {p['node']: p['name'] for p in ps}
    placed = {}
    bad = []
    for (name, node, t), s in zip(ins, asm):
        ref = part_solid[names[node]]
        a, b = bbox(s)
        ra, rb = bbox(ref)
        if abs(props(s)[0] - props(ref)[0]) > 1e-6 * props(ref)[0] or np.abs(a - (ra + t)).max() > 1e-6 or np.abs(b - (rb + t)).max() > 1e-6:
            bad.append(name)
        placed[name] = s
    check('assembly.instances', len(asm) == len(ins) and not bad, solids=len(asm), instances=len(ins), mismatched=bad)

    elo = np.min([bbox(s)[0] for s in placed.values()], axis=0)
    ehi = np.max([bbox(s)[1] for s in placed.values()], axis=0)
    check('envelope', np.allclose(elo, spec['envelope'][0], atol=1e-3) and np.allclose(ehi, spec['envelope'][1], atol=1e-3),
          box_mm=[elo.tolist(), ehi.tolist()], claimed=spec['envelope'])

    cas = placed['casing'].wrapped
    cone = placed['cone'].wrapped
    impw = placed['impeller'].wrapped
    out_holes = hole_axes(cas, spec['outlet_hole_r'], np.array([0.0, 1.0, 0.0]))
    xz = sorted((round(float(p[0]), 6), round(float(p[2]), 6)) for p in out_holes)
    want = sorted((round(x, 6), round(z, 6)) for x, z in spec['outlet_holes_xz'])
    check('outlet.flange', xz == want, holes=len(xz), claimed=len(want), centres=xz)
    front = hole_axes(cas, spec['front_tap_r'], np.array([0.0, 0.0, 1.0]))
    pcd = sorted(round(float(np.linalg.norm(p[:2])) * 2, 6) for p in front)
    check('inlet.flange', len(front) == spec['front_taps'] and all(abs(d - spec['front_pcd']) < 1e-6 for d in pcd),
          holes=len(front), pcd_mm=sorted(set(pcd)), claimed=[spec['front_taps'], spec['front_pcd']])

    c_rad = dist(impw, cone)
    zc = bbox(placed['cone'])[0][2]
    overlap = spec['collar_top_z'] - zc
    check('clearance.cone', abs(c_rad - spec['cone_radial_mm']) < 1e-6 and overlap >= spec['cone_overlap_min_mm'],
          min_distance_mm=c_rad, axial_overlap_mm=overlap, claimed=[spec['cone_radial_mm'], spec['cone_overlap_min_mm']])
    tongue = boxed(cas, *spec['tongue_box'])
    t_clear = dist(impw, tongue)
    check('clearance.tongue', abs(t_clear - spec['tongue_clearance_mm']) < 1e-6,
          tongue_clearance_mm=t_clear, fraction_of_d2=t_clear / spec['d2_mm'], claimed=spec['tongue_clearance_mm'])
    back = boxed(cas, *spec['back_box'])
    b_clear = dist(impw, back)
    check('clearance.back_wall', abs(b_clear - spec['back_clearance_mm']) < 1e-6, back_wall_clearance_mm=b_clear,
          claimed=spec['back_clearance_mm'])

    for tag, occt in (('cone', c_rad), ('casing', min(t_clear, b_clear))):
        cp =os.path.join(RUN, 'q', 'clear_impeller_%s.txt' % tag)
        iv = kernel_iv(cp, 'clearance') if os.path.exists(cp) else None
        check('kernel_clearance.' + tag, iv is not None and iv[2] == 'certified' and iv[0] <= occt + 1e-9 and iv[0] > 0,
              deferred='certified clearance moved after G6 by the owner (2026-10-31)',
              kernel=iv, occt_mm=occt, rule='certified lo <= OCCT distance, lo > 0', evidence='q/clear_impeller_%s.txt' % tag)

    worst = None
    for f in sorted(os.listdir(os.path.join(RUN, 'q'))):
        if not f.startswith('rotor_'):
            continue
        t = open(os.path.join(RUN, 'q', f)).read()
        m = re.search(r'critical 1 rpm=\[([^,]+), ([^\]]+)\] extrapolated=(\S+)', t)
        k_rpm = float(m.group(3))
        g_rpm = eb_rotor(t.splitlines()[0])
        row = dict(case=f[:-4], kernel_rpm=k_rpm, grader_eb_rpm=g_rpm, rel=abs(g_rpm - k_rpm) / k_rpm)
        worst = row if worst is None or k_rpm < worst['kernel_rpm'] else worst
        check('rotor.' + f[6:-4], row['rel'] < 0.02 and min(k_rpm, g_rpm) >= 1.25 * RPM, **row,
              rule='Euler-Bernoulli FE (40 el/segment, consistent mass) within 2%% of the kernel Timoshenko result; >= 1.25 x %g rpm' % RPM)

    allowed = {tuple(sorted(p)) for p in spec['allowed_overlaps']}
    unexpected = []
    over = {}
    nms = list(placed)
    boxes = {n: bbox(placed[n]) for n in nms}
    for i, na in enumerate(nms):
        for nb in nms[i + 1:]:
            (alo, ahi), (blo, bhi) = boxes[na], boxes[nb]
            if (alo > bhi + 1e-6).any() or (blo > ahi + 1e-6).any():
                continue
            v = common_volume(placed[na].wrapped, placed[nb].wrapped)
            if v > 1e-6:
                key = tuple(sorted((re.sub(r'_\d+$', '', na), re.sub(r'_\d+$', '', nb))))
                over['%s|%s' % (na, nb)] = v
                if key not in allowed:
                    unexpected.append(['%s|%s' % (na, nb), v])
    check('interference.full', not unexpected, unexpected=unexpected, overlaps=len(over),
          rule='only declared thread engagements and key fits overlap', evidence='q/interf_occt.json')
    json.dump(over, open(os.path.join(RUN, 'q', 'interf_occt.json'), 'w'), indent=1)

    passed = sum(o['status'] == 'PASS' for o in OUT)
    failed = sum(o['status'] == 'FAIL' for o in OUT)
    deferred = sum(o['status'] == 'DEFERRED' for o in OUT)
    md = ['# G4 grade', '', 'Verdict: **%s** (%d pass, %d fail, %d deferred of %d)' % ('PASS' if failed == 0 else 'FAIL', passed, failed, deferred, len(OUT)), '',
          'Graded from the exported STEP files with OCCT (build123d) as a reader only; no BendCAD call.', '',
          '| Check | Result | Numbers |', '|---|---|---|']
    for o in OUT:
        nums = ', '.join('%s=%s' % (k, json.dumps(v)) for k, v in o.items() if k not in ('check', 'pass_', 'status'))
        md.append('| %s | %s | %s |' % (o['check'], o['status'], nums.replace('|', '/')))
    open(os.path.join(RUN, 'grade.md'), 'w').write('\n'.join(md) + '\n')
    json.dump(OUT, open(os.path.join(RUN, 'grade.json'), 'w'), indent=1)
    print('%d pass, %d fail, %d deferred of %d' % (passed, failed, deferred, len(OUT)))


if __name__ == '__main__':
    main()
