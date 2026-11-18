import sys

from build123d import import_step
from OCP.BRep import BRep_Tool
from OCP.BRepAdaptor import BRepAdaptor_Surface
from OCP.BRepAlgoAPI import BRepAlgoAPI_Common, BRepAlgoAPI_Fuse
from OCP.BRepCheck import BRepCheck_Analyzer
from OCP.BRepGProp import BRepGProp
from OCP.BRepMesh import BRepMesh_IncrementalMesh
from OCP.GProp import GProp_GProps
from OCP.TopAbs import TopAbs_FACE, TopAbs_REVERSED
from OCP.TopExp import TopExp_Explorer
from OCP.TopLoc import TopLoc_Location
from OCP.TopoDS import TopoDS


def vol(s):
    g = GProp_GProps()
    BRepGProp.VolumeProperties_s(s, g, 1e-9)
    return g.Mass()


def fuse(a_path, b_path, u_path):
    a, b, u = (import_step(p).wrapped for p in (a_path, b_path, u_path))
    f = BRepAlgoAPI_Fuse(a, b)
    f.Build()
    c = BRepAlgoAPI_Common(a, b)
    c.Build()
    print('A %.9f B %.9f' % (vol(a), vol(b)))
    print('occt fuse %.9f common %.9f valid %s' % (vol(f.Shape()), vol(c.Shape()), BRepCheck_Analyzer(f.Shape()).IsValid()))
    print('kernel union readback %.9f valid %s' % (vol(u), BRepCheck_Analyzer(u).IsValid()))


def face_rows(path, c, defl):
    shape = import_step(path).wrapped
    BRepMesh_IncrementalMesh(shape, defl, False, 0.05, True)
    ex = TopExp_Explorer(shape, TopAbs_FACE)
    rows = []
    while ex.More():
        f = TopoDS.Face(ex.Current())
        loc = TopLoc_Location()
        tri = BRep_Tool.Triangulation_s(f, loc)
        v = 0.0
        if tri is not None:
            tf = loc.Transformation()
            pts = []
            for j in range(1, tri.NbNodes() + 1):
                p = tri.Node(j).Transformed(tf)
                pts.append((p.X() - c[0], p.Y() - c[1], p.Z() - c[2]))
            rev = f.Orientation() == TopAbs_REVERSED
            for j in range(1, tri.NbTriangles() + 1):
                i0, i1, i2 = tri.Triangle(j).Get()
                if rev:
                    i1, i2 = i2, i1
                p, q, r = pts[i0 - 1], pts[i1 - 1], pts[i2 - 1]
                v += (p[0] * (q[1] * r[2] - q[2] * r[1]) - p[1] * (q[0] * r[2] - q[2] * r[0]) + p[2] * (q[0] * r[1] - q[1] * r[0])) / 6.0
        g = GProp_GProps()
        BRepGProp.SurfaceProperties_s(f, g, 1e-10)
        rows.append((str(BRepAdaptor_Surface(f).GetType()).split('_')[-1], v, g.Mass()))
        ex.Next()
    return rows


def faces(u_path, kernel_path, cx, cy, cz, defl='0.002'):
    o = face_rows(u_path, (float(cx), float(cy), float(cz)), float(defl))
    k = [l.split() for l in open(kernel_path) if l.startswith('face ')]
    used, bad = set(), 0
    for a in k:
        kv, kar = float(a[5]), float(a[9])
        j = min((j for j in range(len(o)) if j not in used), key=lambda j: (round(abs(o[j][2] - kar) / max(1.0, kar), 6), abs(o[j][1] - kv)))
        used.add(j)
        kind, ov, oar = o[j]
        off = abs(kv - ov) > 2e-3 * max(1.0, abs(ov)) + 0.01 or abs(kar - oar) > 1e-4 * max(1.0, oar)
        bad += off
        print('%3s k%s %-9s kernel vol %14.4f area %11.4f  occt vol %14.4f area %11.4f %s' % (a[1], a[3], kind, kv, kar, ov, oar, '<<<' if off else ''))
    print('kernel total %.6f occt total %.6f mismatched faces %d' % (sum(float(a[5]) for a in k), sum(r[1] for r in o), bad))


if __name__ == '__main__':
    {'fuse': fuse, 'faces': faces}[sys.argv[1]](*sys.argv[2:])
