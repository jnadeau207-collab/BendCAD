import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import humphrey as H
from prove import PARTS

from OCP.BRepBndLib import BRepBndLib
from OCP.BRepClass3d import BRepClass3d_SolidClassifier
from OCP.BRepExtrema import BRepExtrema_DistShapeShape
from OCP.BRepGProp import BRepGProp
from OCP.Bnd import Bnd_Box
from OCP.BRepAdaptor import BRepAdaptor_Curve
from OCP.GeomAbs import GeomAbs_Circle
from OCP.GProp import GProp_GProps
from OCP.TopAbs import TopAbs_EDGE, TopAbs_IN
from OCP.TopExp import TopExp_Explorer
from OCP.TopoDS import TopoDS
from OCP.gp import gp_Pnt
from build123d import import_step

REC = os.path.join(H.ROOT, 'docs', 'receipts', 'g6')
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
    return b.Get()


def dist(a, b):
    d = BRepExtrema_DistShapeShape(a, b)
    d.Perform()
    return d.Value()


def inside(s, x, y, z):
    c = BRepClass3d_SolidClassifier(s, gp_Pnt(x, y, z), 1e-7)
    return c.State() == TopAbs_IN


def air_gap(inner, outer, z, phi=0.37, r0=100.0, r1=130.0, n=3000):
    c, sn = math.cos(phi), math.sin(phi)
    rs = [r0 + (r1 - r0) * i / n for i in range(n + 1)]
    lo = max((r for r in rs if inside(inner, r * c, r * sn, z)), default=None)
    hi = min((r for r in rs if inside(outer, r * c, r * sn, z)), default=None)
    return (hi - lo) if lo is not None and hi is not None else None


def circles(s, radius, tol=1e-6):
    n = 0
    ex = TopExp_Explorer(s, TopAbs_EDGE)
    while ex.More():
        c = BRepAdaptor_Curve(TopoDS.Edge_s(ex.Current()))
        if c.GetType() == GeomAbs_Circle and abs(c.Circle().Radius() - radius) < tol:
            n += 1
        ex.Next()
    return n


def main():
    mass = json.load(open(os.path.join(REC, 'mass.json'), encoding='utf-8'))
    kparts = {p['name']: p for p in mass['parts']}
    shapes = {name: load(name) for name in PARTS}
    rows, checks = [], []
    zmin, zmax, rmax = 1e9, -1e9, 0.0
    for name, s in shapes.items():
        v = volume(s)
        x0, y0, z0, x1, y1, z1 = bbox(s)
        zmin, zmax = min(zmin, z0), max(zmax, z1)
        rmax = max(rmax, abs(x0), abs(x1), abs(y0), abs(y1))
        kv = kparts.get(name, {}).get('volume_mm3')
        rel = abs(v / (0.5 * (kv[0] + kv[1])) - 1.0) if kv else None
        rows.append(dict(part=name, step_volume_mm3=v, kernel_volume_mm3=kv, rel_diff=rel))
    def chk(name, ok, ev):
        checks.append(dict(check=name, status='pass' if ok else 'fail', evidence=ev))
    bad = [r['part'] for r in rows if r['rel_diff'] is None or r['rel_diff'] > 1e-6]
    chk('every part read back from STEP with the kernel-certified volume (1e-6)', not bad, f'disagree or missing: {bad or "none"}')
    chk('envelope diameter <= 272 mm', 2 * rmax <= 272.0 + 1e-6, f'D {2 * rmax:.3f} mm from the STEP bounding boxes')
    chk('envelope length <= 560 mm', zmax - zmin <= 560.0 + 1e-6, f'L {zmax - zmin:.3f} mm')
    gap = air_gap(shapes['rdc'], shapes['stator'], 0.5 * (H.Z_INJ + H.Z_RDC1))
    chk('RDC channel height measured from the export equals the model (0.01 mm)', gap is not None and abs(gap - H.RDC_W) <= 0.01, f'{gap} mm vs {H.RDC_W}')
    tt = dist(shapes['turbine'], shapes['stator'])
    chk('turbine tip clearance from the export equals the design (0.005 mm)', abs(tt - H.G_TT) <= 0.005, f'{tt:.4f} mm vs {H.G_TT}')
    ct = dist(shapes['impeller'], shapes['shroud'])
    chk('compressor tip clearance from the export equals the design (0.005 mm)', abs(ct - H.G_TIP) <= 0.005, f'{ct:.4f} mm vs {H.G_TIP}')
    holes = circles(shapes['rdc'], 0.6)
    chk('injector orifices counted from the export', holes == 2 * H.INJ_N, f'{holes} circles of r 0.6 = {holes // 2} orifices vs {H.INJ_N}')
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
