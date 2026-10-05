import os
import random, sys, re
from fractions import Fraction as Q
from shapely.geometry import LineString
from shapely.ops import unary_union, polygonize_full

random.seed(int(sys.argv[3]) if len(sys.argv) > 3 else 7)


def rsegs():
    k = random.random()
    out = []
    if k < 0.4:
        for _ in range(random.randint(1, 3)):
            x0, y0 = random.randint(0, 8), random.randint(0, 8)
            w, h = random.randint(1, 6), random.randint(1, 6)
            out += [(x0, y0, x0 + w, y0), (x0 + w, y0, x0 + w, y0 + h), (x0 + w, y0 + h, x0, y0 + h), (x0, y0 + h, x0, y0)]
    for _ in range(random.randint(0 if out else 2, 7)):
        while True:
            s = tuple(random.randint(0, 10) for _ in range(4))
            if s[:2] != s[2:]:
                break
        out.append(s)
    random.shuffle(out)
    ids = random.sample(range(1, 200), len(out))
    return [(i,) + s for i, s in zip(ids, out)]


def rect(x0, y0, x1, y1):
    return [(x0, y0, x1, y0), (x1, y0, x1, y1), (x1, y1, x0, y1), (x0, y1, x0, y0)]


def nsegs():
    out = []
    for _ in range(random.randint(1, 2)):
        cx, cy = random.randint(8, 40), random.randint(8, 40)
        for r in sorted(random.sample(range(1, 8), random.randint(1, 4)), reverse=True):
            out += rect(cx - r, cy - r - random.randint(0, 1), cx + r + random.randint(0, 1), cy + r)
    for _ in range(random.randint(0, 3)):
        x0, y0 = random.randint(0, 44), random.randint(0, 44)
        out += rect(x0, y0, x0 + random.randint(1, 8), y0 + random.randint(1, 8))
    for _ in range(random.randint(0, 2)):
        while True:
            p = [(random.randint(0, 48), random.randint(0, 48)) for _ in range(3)]
            if (p[1][0] - p[0][0]) * (p[2][1] - p[0][1]) != (p[1][1] - p[0][1]) * (p[2][0] - p[0][0]):
                break
        out += [p[0] + p[1], p[1] + p[2], p[2] + p[0]]
    random.shuffle(out)
    ids = random.sample(range(1, 1000), len(out))
    return [(i,) + s for i, s in zip(ids, out)]


cases = [(nsegs if sys.argv[5:] == ["nest"] else rsegs)() for _ in range(int(sys.argv[4]) if len(sys.argv) > 4 else 150)]


def lit(v):
    return f"{float(v)}f64"


def cross(s, r):
    _, ax, ay, bx, by = map(Q, s)
    _, cx, cy, dx, dy = map(Q, r)
    den = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx)
    t = ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / den
    return (ax + t * (bx - ax), ay + t * (by - ay))


def coords(key, segs):
    by = {s[0]: s for s in segs}
    m = re.fullmatch(r"e(\d+)\.(\d)", key)
    if m:
        s = by[int(m[1])]
        return (Q(s[1]), Q(s[2])) if m[2] == "0" else (Q(s[3]), Q(s[4]))
    m = re.fullmatch(r"x(\d+)\.(\d+)", key)
    return cross(by[int(m[1])], by[int(m[2])])


def area(pts):
    return sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1] for i in range(len(pts))) / 2


def parse(line):
    m = re.fullmatch(r"v=(\d+) e=(\d+) c=(\d+) R(.*) D(.*)", line)
    regs = []
    for body in re.findall(r"\{([^}]*)\}", m[4]):
        loops = [re.findall(r"(\S+)\[([\d,]*)\]", part) for part in body.split("|")]
        regs.append(loops)
    return int(m[1]), int(m[2]), int(m[3]), regs, m[5].split()


if sys.argv[1] == "gen":
    src = os.path.relpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "src"), os.path.dirname(os.path.abspath(sys.argv[2]))).replace(os.sep, "/")
    rows = []
    for segs in cases:
        rows.append("[" + ", ".join(f"A.Seg{{{i}u64, {lit(a)}, {lit(b)}, {lit(c)}, {lit(d)}}}" for i, a, b, c, d in segs) + "]")
    body = ",\n   ".join(rows)
    open(sys.argv[2], "w", newline="\n").write(f"""import Base
import {src}/c05/arrange.bend as A

def cs() -> List<&2, List<&2, A.Seg>>:
  [{body}]

def go(xs: List<&2, List<&2, A.Seg>>) -> String:
  match xs:
    case Nil{{}}: ""
    case h <> t: A.ares_show(A.arrange(h, 1000n)) ++ "\\n" ++ go(t)

def main() -> String:
  go(cs())
""")
    sys.exit()

got = open(sys.argv[2]).read().strip().strip('"').replace("\\n", "\n").strip().split("\n")
assert len(got) == len(cases), (len(got), len(cases))
bad = 0
for n, (segs, line) in enumerate(zip(cases, got)):
    errs = []
    nv, ne, nc, regs, dang = parse(line)
    lines = [LineString([(s[1], s[2]), (s[3], s[4])]) for s in segs]
    noded = unary_union(lines)
    polys, cuts, dangles, invalid = polygonize_full(noded)
    want = sorted((round(p.area, 9), len(p.interiors)) for p in polys.geoms)
    have = []
    for loops in regs:
        outer, holes = loops[0], loops[1:]
        pts = [coords(k, segs) for k, _ in outer]
        a = area(pts)
        if a <= 0:
            errs.append("outer not CCW")
        for h in holes:
            ha = area([coords(k, segs) for k, _ in h])
            if ha >= 0:
                errs.append("hole not CW")
            a += ha
        have.append((round(float(a), 9), len(holes)))
        for lp in loops:
            if len(set(k for k, _ in lp)) != len(lp):
                errs.append("repeated vertex in loop")
    have.sort()
    if have != want:
        errs.append(f"faces {have} != shapely {want}")
    vset = set()
    for g in getattr(noded, "geoms", [noded]):
        for c in g.coords:
            vset.add(c)
    if nv != len(vset):
        errs.append(f"nv {nv} != {len(vset)}")
    nseg = sum(len(g.coords) - 1 for g in getattr(noded, "geoms", [noded]))
    if ne != nseg:
        errs.append(f"ne {ne} != {nseg}")
    nd = len(dang) // 1
    wd = sum(len(g.coords) - 1 for g in list(cuts.geoms) + list(dangles.geoms))
    if len(dang) != wd:
        errs.append(f"dangling {len(dang)} != {wd}")
    if errs:
        bad += 1
        if bad <= 5:
            print("case", n, segs, "\n  ", line, "\n  ", errs)
print(f"arrangement oracle: {len(cases)} cases, mismatches={bad}")
