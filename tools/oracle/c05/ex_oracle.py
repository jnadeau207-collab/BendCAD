import os
import math, random, struct, sys
from fractions import Fraction as Q

random.seed(5)


def rnd():
    k = random.random()
    if k < 0.3:
        return random.uniform(-1e3, 1e3)
    if k < 0.5:
        return random.uniform(-1, 1) * 2.0 ** random.randint(-60, 60)
    if k < 0.7:
        return float(random.randint(-10 ** 6, 10 ** 6)) / 1024
    return random.choice([0.1, 0.2, 0.3, 1e-300, 1e300, 3.0, -7.25, 1e-10])


def near_coll():
    ax, ay = rnd(), rnd()
    dx, dy = rnd(), rnd()
    t = random.uniform(-3, 3)
    return [ax, ay, ax + dx, ay + dy, ax + t * dx, ay + t * dy]


cases = [[rnd() for _ in range(6)] for _ in range(1200)]
cases += [near_coll() for _ in range(700)]
cases += [[0.0, 0.0, 1.0, 1.0, 2.0, 2.0], [0.1, 0.1, 0.2, 0.2, 0.3, 0.3],
          [1e-160, 1e-160, 3e-160, 1e-160, 1e-160, 5e-160],
          [1e300, 1e300, -1e300, 1e300, 1e300, -1e300]]
for _ in range(96):
    s = 2.0 ** random.randint(-1000, 1000)
    cases.append([x * s for x in near_coll()])


def sign(v):
    return "pos" if v > 0 else "neg" if v < 0 else "zero"


def exact(c):
    if not all(math.isfinite(x) for x in c):
        return "uncertain"
    ax, ay, bx, by, cx, cy = map(Q, c)
    return sign((bx - ax) * (cy - ay) - (by - ay) * (cx - ax))


def lit(x):
    return "F64{" + str(struct.unpack("<Q", struct.pack("<d", x))[0]) + "u64}"


if sys.argv[1] == "gen":
    src = os.path.relpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "src"), os.path.dirname(os.path.abspath(sys.argv[2]))).replace(os.sep, "/")
    rows = ",\n".join("   C6{" + ", ".join(lit(x) for x in c) + "}" for c in cases)
    prog = f"""import Base
import {src}/c05/exact.bend as X
import {src}/base/ex.bend as E
import {src}/base/par.bend as P

type C6 is Data:
  C6{{ ax: F64, ay: F64, bx: F64, by: F64, cx: F64, cy: F64 }}

def cs() -> List<&2, C6>:
  [{rows}]

def row(c: C6) -> String:
  C6{{+ax, +ay, +bx, +by, +cx, +cy}} = c
  P.sgn_show(E.ex_sign(X.orient2(ax, ay, bx, by, cx, cy))) ++ "/" ++ P.sgn_show(X.orient2s(ax, ay, bx, by, cx, cy))

def rows(xs: List<&2, C6>) -> String:
  match xs:
    case Nil{{}}: ""
    case h <> t: row(h) ++ " " ++ rows(t)

def main() -> String:
  rows(cs())
"""
    open(sys.argv[2], "w", newline="\n").write(prog)
else:
    pairs = [t.split("/") for t in open(sys.argv[2]).read().strip().strip('"').split()]
    got = [p[0] for p in pairs]
    filt = [p[1] for p in pairs]
    want = [exact(c) for c in cases]
    fbad = [(i, w, g) for i, (w, g) in enumerate(zip(want, filt)) if g != w and g != "uncertain"]
    fdiff = [i for i, (a, b) in enumerate(zip(got, filt)) if a != b]
    print(f"filtered orient2s: wrong={len(fbad)}, differs from exact path={len(fdiff)}", fbad[:5])
    bad = [(i, w, g) for i, (w, g) in enumerate(zip(want, got)) if g != w and g != "uncertain"]
    unc = [i for i, g in enumerate(got) if g == "uncertain"]
    unc_true = [i for i in unc if want[i] != "uncertain"]
    print(f"{len(got)}/{len(want)} cases, wrong={len(bad)}, uncertain={len(unc)} (of which finite-input {len(unc_true)})", bad[:5])
    for i in unc_true[:6]:
        print("  unc", cases[i])
