import json
import math
import os
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
import humphrey as H
from prove import PARTS

from OCP.BRepBndLib import BRepBndLib
from OCP.BRepClass3d import BRepClass3d_SolidClassifier
from OCP.BRepExtrema import BRepExtrema_DistShapeShape
from OCP.Extrema import Extrema_ExtAlgo_Tree, Extrema_ExtFlag_MIN
from OCP.BRepGProp import BRepGProp
from OCP.Bnd import Bnd_Box
from OCP.BRepAdaptor import BRepAdaptor_Curve, BRepAdaptor_Surface
from OCP.GeomAbs import GeomAbs_Circle, GeomAbs_Cylinder
from OCP.GProp import GProp_GProps
from OCP.TopAbs import TopAbs_EDGE, TopAbs_FACE, TopAbs_IN
from OCP.BRep import BRep_Builder
from OCP.TopoDS import TopoDS_Compound
from OCP.BRepMesh import BRepMesh_IncrementalMesh
from OCP.BRep import BRep_Tool
from OCP.TopLoc import TopLoc_Location
from OCP.TopExp import TopExp_Explorer
from OCP.TopoDS import TopoDS
from OCP.gp import gp_Pnt
from build123d import import_step

REC = os.path.join(H.ROOT, 'docs', 'receipts', 'g6')
T0 = time.time()
EXPORT = os.environ.get('G6_EXPORT', '/home/jesse/g6/export')


def load(name):
    return import_step(os.path.join(EXPORT, name + '.stp')).wrapped


def volume(s):
    g = GProp_GProps()
    BRepGProp.VolumeProperties_s(s, g, 1e-9)
    return g.Mass()


def bbox(s):
    b = Bnd_Box()
    BRepBndLib.Add_s(s, b)
    lo, hi = b.CornerMin(), b.CornerMax()
    return lo.X(), lo.Y(), lo.Z(), hi.X(), hi.Y(), hi.Z()


def dist(a, b):
    d = BRepExtrema_DistShapeShape()
    d.LoadS1(a)
    d.LoadS2(b)
    d.SetFlag(Extrema_ExtFlag_MIN)
    d.SetAlgo(Extrema_ExtAlgo_Tree)
    d.Perform()
    return d.Value()


def face_r(f):
    x0, y0, z0, x1, y1, z1 = bbox(f)
    near = math.hypot(0.0 if x0 <= 0.0 <= x1 else min(abs(x0), abs(x1)), 0.0 if y0 <= 0.0 <= y1 else min(abs(y0), abs(y1)))
    return near, math.hypot(max(abs(x0), abs(x1)), max(abs(y0), abs(y1))), z0, z1


def wall_r(f, rn):
    a = BRepAdaptor_Surface(TopoDS.Face(f))
    return a.Cylinder().Radius() if a.GetType() == GeomAbs_Cylinder else rn


def faces_of(s):
    out = []
    ex = TopExp_Explorer(s, TopAbs_FACE)
    while ex.More():
        out.append(ex.Current())
        ex.Next()
    return out


def in_wedge(f, half_deg):
    x0, y0, z0, x1, y1, z1 = bbox(f)
    t = math.tan(math.radians(half_deg))
    return x1 > 0.0 and y0 < x1 * t and y1 > -x1 * t


def faces_where(s, keep):
    c = TopoDS_Compound()
    bld = BRep_Builder()
    bld.MakeCompound(c)
    n = 0
    ex = TopExp_Explorer(s, TopAbs_FACE)
    while ex.More():
        f = ex.Current()
        if keep(f, *face_r(f)):
            bld.Add(c, f)
            n += 1
        ex.Next()
    return c, n


def mesh_pts(c, defl):
    BRepMesh_IncrementalMesh(c, defl, False, 0.05, True)
    pts = []
    ex = TopExp_Explorer(c, TopAbs_FACE)
    while ex.More():
        f = TopoDS.Face(ex.Current())
        loc = TopLoc_Location()
        t = BRep_Tool.Triangulation_s(f, loc)
        if t is not None:
            tr = loc.Transformation()
            for i in range(1, t.NbNodes() + 1):
                q = t.Node(i).Transformed(tr)
                pts.append((math.hypot(q.X(), q.Y()), q.Z()))
        ex.Next()
    return pts


def meridian(s):
    segs = []
    ex = TopExp_Explorer(s, TopAbs_FACE)
    while ex.More():
        f = TopoDS.Face(ex.Current())
        cs = []
        ee = TopExp_Explorer(f, TopAbs_EDGE)
        while ee.More():
            c = BRepAdaptor_Curve(TopoDS.Edge(ee.Current()))
            if c.GetType() == GeomAbs_Circle:
                k = c.Circle()
                cs.append((round(k.Radius(), 12), round(k.Location().Z(), 12)))
            ee.Next()
        cs = sorted(set(cs))
        if len(cs) == 2:
            segs.append((cs[0], cs[1]))
        ex.Next()
    return segs


def seg_d(p, a, b):
    ax, ay = b[0] - a[0], b[1] - a[1]
    t = max(0.0, min(1.0, ((p[0] - a[0]) * ax + (p[1] - a[1]) * ay) / (ax * ax + ay * ay)))
    return math.hypot(p[0] - a[0] - t * ax, p[1] - a[1] - t * ay)


def tip_dist(rotor, stator, r_lo, r_hi, z_lo, z_hi, r_wall, wedge):
    a, na = faces_where(rotor, lambda f, rn, rf, z0, z1: rf >= r_lo and z1 >= z_lo and z0 <= z_hi and in_wedge(f, wedge))
    b, nb = faces_where(stator, lambda f, rn, rf, z0, z1: wall_r(f, rn) >= r_wall and rn <= r_hi and z1 >= z_lo and z0 <= z_hi)
    print(f'{time.time() - T0:7.1f}s tip faces {na} x {nb}', file=sys.stderr, flush=True)
    return dist(a, b), na, nb


CLS = {}


def inside(s, x, y, z):
    k = id(s)
    if k not in CLS:
        CLS[k] = BRepClass3d_SolidClassifier(s)
    c = CLS[k]
    c.Perform(gp_Pnt(x, y, z), 1e-7)
    return c.State() == TopAbs_IN


def edge_r(s, a, b, z, c, sn, want):
    for _ in range(60):
        m = 0.5 * (a + b)
        if inside(s, m * c, m * sn, z) == want:
            a = m
        else:
            b = m
    return 0.5 * (a + b)


def air_gap(inner, outer, z, phi=0.37, r0=100.0, r1=130.0, n=300):
    c, sn = math.cos(phi), math.sin(phi)
    st = (r1 - r0) / n
    rs = [r0 + st * i for i in range(n + 1)]
    lo = max((r for r in rs if inside(inner, r * c, r * sn, z)), default=None)
    hi = min((r for r in rs if inside(outer, r * c, r * sn, z)), default=None)
    if lo is None or hi is None:
        return None
    return edge_r(outer, hi, hi - st, z, c, sn, True) - edge_r(inner, lo, lo + st, z, c, sn, True)


def bores(s, radius, tol=1e-6):
    axes = set()
    ex = TopExp_Explorer(s, TopAbs_FACE)
    while ex.More():
        a = BRepAdaptor_Surface(TopoDS.Face(ex.Current()))
        if a.GetType() == GeomAbs_Cylinder and abs(a.Cylinder().Radius() - radius) < tol:
            l, d = a.Cylinder().Location(), a.Cylinder().Axis().Direction()
            axes.add((round(l.X(), 4), round(l.Y(), 4), round(abs(d.Z()), 6)))
        ex.Next()
    return len(axes)


def main():
    mass = json.load(open(os.path.join(REC, 'mass.json'), encoding='utf-8'))
    kparts = {p['name']: p for p in mass['parts']}
    shapes = {}
    for name in PARTS:
        shapes[name] = load(name)
        print(f'{time.time() - T0:7.1f}s read {name}', file=sys.stderr, flush=True)
    rows, checks = [], []
    zmin, zmax, rmax = 1e9, -1e9, 0.0
    for name, s in shapes.items():
        v = volume(s)
        print(f'{time.time() - T0:7.1f}s volume {name} {v}', file=sys.stderr, flush=True)
        x0, y0, z0, x1, y1, z1 = bbox(s)
        zmin, zmax = min(zmin, z0), max(zmax, z1)
        rmax = max(rmax, abs(x0), abs(x1), abs(y0), abs(y1))
        kv = kparts.get(name, {}).get('volume_mm3')
        rel = abs(v / (0.5 * (kv[0] + kv[1])) - 1.0) if kv else None
        rows.append(dict(part=name, step_volume_mm3=v, kernel_volume_mm3=kv, rel_diff=rel))
    def chk(name, ok, ev):
        checks.append(dict(check=name, status='pass' if ok else 'fail', evidence=ev))
        print(f"{time.time() - T0:7.1f}s {'PASS' if ok else 'FAIL'} {name}: {ev}", file=sys.stderr, flush=True)
    bad = [r['part'] for r in rows if r['rel_diff'] is None or r['rel_diff'] > 1e-6]
    chk('every part read back from STEP with the kernel-certified volume (1e-6)', not bad, f'disagree or missing: {bad or "none"}')
    chk('envelope diameter <= 272 mm', 2 * rmax <= 272.0 + 1e-6, f'D {2 * rmax:.3f} mm from the STEP bounding boxes')
    chk('envelope length <= 560 mm', zmax - zmin <= 560.0 + 1e-6, f'L {zmax - zmin:.3f} mm')
    gap = air_gap(shapes['rdc'], shapes['stator'], 0.5 * (H.Z_INJ + H.Z_RDC1))
    chk('RDC channel height measured from the export equals the model (0.01 mm)', gap is not None and abs(gap - H.RDC_W) <= 0.01, f'{gap} mm vs {H.RDC_W}')
    rt, nrt = faces_where(shapes['turbine'], lambda f, rn, rf, z0, z1: rf >= H.TT - 1.0 and in_wedge(f, 360.0 / H.TUR_N * 1.5))
    walls = [wall_r(f, 0.0) for f in faces_of(shapes['stator']) if wall_r(f, 0.0) >= H.TT - 1e-6 and face_r(f)[2] <= H.Z_TUR + H.B_TUR and face_r(f)[3] >= H.Z_TUR]
    tt = min(walls) - max(r for r, z in mesh_pts(rt, 1e-4))
    chk('turbine tip clearance from the export equals the design (0.005 mm)', abs(tt - H.G_TT) <= 0.005, f'{tt:.4f} mm vs {H.G_TT}')
    ri, nri = faces_where(shapes['impeller'], lambda f, rn, rf, z0, z1: rf >= H.R1T - 1.0 and in_wedge(f, 22.5))
    segs = meridian(shapes['shroud'])
    ct = min(min(seg_d(p, a, b) for a, b in segs) for p in mesh_pts(ri, 1e-4) if p[0] >= H.R1T - 1.0)
    chk('compressor tip clearance from the export equals the design (0.005 mm)', abs(ct - H.G_TIP) <= 0.005, f'{ct:.4f} mm vs {H.G_TIP}')
    holes = bores(shapes['rdc'], 0.6)
    chk('injector orifices counted from the export', holes == H.INJ_N, f'{holes} distinct r 0.6 bores (cylinder faces grouped by axis) vs {H.INJ_N}')
    a9 = math.pi * H.R_NOZ ** 2
    chk('nozzle exit area from the geometry matches the deck (0.5%)', abs(a9 / H.SZ['nozzle']['exit_area_mm2'] - 1) <= 0.005, f'{a9:.1f} vs {H.SZ["nozzle"]["exit_area_mm2"]:.1f} mm2')
    an = math.pi * (H.TT ** 2 - H.TH ** 2)
    chk('turbine annulus from the geometry matches the deck (0.5%)', abs(an / H.SZ['turbine']['annulus_mm2'] - 1) <= 0.005, f'{an:.1f} vs {H.SZ["turbine"]["annulus_mm2"]:.1f} mm2')
    rep = dict(source='tools/g6/grade.py: OCCT (OCP 7.x via build123d) reading the STEP AP242 exports, an independent code path from the kernel',
               export=EXPORT, ready=all(c['status'] == 'pass' for c in checks), checks=checks, parts=rows)
    json.dump(rep, open(os.path.join(REC, 'grading.json'), 'w', encoding='utf-8'), indent=1)
    for c in checks:
        print(f"{c['status'].upper():5s} {c['check']}: {c['evidence']}")


if __name__ == '__main__':
    main()
