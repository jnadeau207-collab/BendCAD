import glob
import itertools
import math
import json
import os
import sys

from build123d import Compound, export_step, import_step
from OCP.BRepTools import BRepTools_WireExplorer
from OCP.BRep import BRep_Tool


def solid_of(path):
    sh = import_step(path)
    ss = sh.solids() if hasattr(sh, 'solids') else [sh]
    return ss[0] if len(ss) == 1 else Compound(ss), len(ss)


def outline(s, z):
    faces = [f for f in s.faces() if abs(f.center().Z - z) < 1e-6 and abs(abs(f.normal_at().Z) - 1) < 1e-9]
    f = max(faces, key=lambda f: f.area)
    ex = BRepTools_WireExplorer(f.outer_wire().wrapped)
    out = []
    while ex.More():
        p = BRep_Tool.Pnt_s(ex.CurrentVertex())
        out.append((p.X(), p.Y()))
        ex.Next()
    return out


def seg_d(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy)))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy)


def crosses(a, b, c, d):
    def o(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return o(a, b, c) * o(a, b, d) < 0 and o(c, d, a) * o(c, d, b) < 0


def inside(p, poly):
    c = False
    for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]):
        if (y1 > p[1]) != (y2 > p[1]) and p[0] < x1 + (p[1] - y1) * (x2 - x1) / (y2 - y1):
            c = not c
    return c


def mesh2d(a, b, z):
    A, B = outline(a, z), outline(b, z)
    sa, sb = list(zip(A, A[1:] + A[:1])), list(zip(B, B[1:] + B[:1]))
    d = min(min(min(seg_d(p, *e) for e in sb) for p in A), min(min(seg_d(p, *e) for e in sa) for p in B))
    return dict(vertices=[len(A), len(B)], min_distance=d,
                crossing=any(crosses(p, q, r, t) for p, q in sa for r, t in sb),
                inside=sum(inside(p, B) for p in A) + sum(inside(p, A) for p in B))


def box(s):
    b = s.bounding_box()
    return (b.min.X, b.min.Y, b.min.Z, b.max.X, b.max.Y, b.max.Z)


def boxes_touch(a, b, eps=1e-6):
    return all(a[i] <= b[i + 3] + eps and b[i] <= a[i + 3] + eps for i in range(3))


def main(placed, out):
    parts = {}
    for p in sorted(glob.glob(os.path.join(placed, '*.step')) + glob.glob(os.path.join(placed, '*.stp'))):
        name = os.path.splitext(os.path.basename(p))[0]
        s, n = solid_of(p)
        parts[name] = dict(solid=s, nsol=n, valid=bool(s.is_valid), volume=s.volume, box=box(s))
    pairs = []
    for (na, a), (nb, b) in itertools.combinations(parts.items(), 2):
        if not boxes_touch(a['box'], b['box']):
            continue
        common = a['solid'].intersect(b['solid'])
        cv = sum(x.volume for x in common.solids()) if common is not None else 0.0
        dist = a['solid'].distance(b['solid'])
        pairs.append(dict(a=na, b=nb, common_volume=cv, distance=dist,
                          relation='interference' if cv > 1e-6 else ('contact' if dist < 1e-6 else 'clear')))
    meshes = {}
    for pa, ga in (('pinion1', 'gear1'), ('pinion2', 'gear2')):
        if pa in parts and ga in parts:
            m = mesh2d(parts[pa]['solid'], parts[ga]['solid'], parts[pa]['box'][2])
            m['ok'] = not m['crossing'] and m['inside'] == 0 and m['min_distance'] > 0.05
            meshes[pa + '-' + ga] = m
    rep = dict(meshes=meshes, parts={k: dict(nsol=v['nsol'], valid=v['valid'], volume=v['volume'], box=v['box']) for k, v in parts.items()},
               pairs=pairs,
               interference=[p for p in pairs if p['relation'] == 'interference'],
               all_valid=all(v['valid'] and v['nsol'] == 1 for v in parts.values()))
    rep['pass'] = rep['all_valid'] and not rep['interference'] and len(parts) == 18 and all(m['ok'] for m in meshes.values()) and len(meshes) == 2
    export_step(Compound([v['solid'] for v in parts.values()]), os.path.join(out, 'gearbox_assembly.step'))
    json.dump(rep, open(os.path.join(out, 'grade.json'), 'w'), indent=1)
    print(json.dumps(meshes))
    print(json.dumps(dict(parts=len(parts), all_valid=rep['all_valid'], pairs_checked=len(pairs),
                          interference=rep['interference'], pass_=rep['pass'])))
    for p in pairs:
        print('%-14s %-14s %-12s common=%.6g dist=%.6g' % (p['a'], p['b'], p['relation'], p['common_volume'], p['distance']))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
