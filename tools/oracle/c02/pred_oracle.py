import os, math, random, struct, sys
from fractions import Fraction as Q

random.seed(int(sys.argv[3]) if len(sys.argv) > 3 else 2)
N = int(sys.argv[4]) if len(sys.argv) > 4 else 300


def rnd():
    k = random.random()
    if k < 0.3:
        return random.uniform(-1e3, 1e3)
    if k < 0.5:
        return random.uniform(-1, 1) * 2.0 ** random.randint(-60, 60)
    if k < 0.7:
        return float(random.randint(-10 ** 6, 10 ** 6)) / 1024
    return random.choice([0.1, 0.2, 0.3, 3.0, -7.25, 1e-10, 12345.678])


def scale(ps, s):
    return [x * s for x in ps]


def o2_case():
    if random.random() < 0.5:
        return [rnd() for _ in range(6)]
    ax, ay, dx, dy, t = rnd(), rnd(), rnd(), rnd(), random.uniform(-3, 3)
    return [ax, ay, ax + dx, ay + dy, ax + t * dx, ay + t * dy]


def o3_case():
    if random.random() < 0.4:
        return [rnd() for _ in range(12)]
    a = [rnd() for _ in range(3)]
    u = [rnd() for _ in range(3)]
    v = [rnd() for _ in range(3)]
    s, t = random.uniform(-2, 2), random.uniform(-2, 2)
    b = [a[i] + u[i] for i in range(3)]
    c = [a[i] + v[i] for i in range(3)]
    d = [a[i] + s * u[i] + t * v[i] for i in range(3)]
    return a + b + c + d


def ic_case():
    if random.random() < 0.4:
        return [rnd() for _ in range(8)]
    cx, cy, r = rnd(), rnd(), abs(rnd()) + 1e-3
    pts = []
    for _ in range(4):
        th = random.uniform(0, 2 * math.pi)
        pts += [cx + r * math.cos(th), cy + r * math.sin(th)]
    return pts


def is_case():
    if random.random() < 0.4:
        return [rnd() for _ in range(15)]
    c, r = [rnd() for _ in range(3)], abs(rnd()) + 1e-3
    pts = []
    for _ in range(5):
        th, ph = random.uniform(0, 2 * math.pi), random.uniform(0, math.pi)
        pts += [c[0] + r * math.sin(ph) * math.cos(th), c[1] + r * math.sin(ph) * math.sin(th), c[2] + r * math.cos(ph)]
    return pts


cases = []
for mk, kind in ((o2_case, "o2"), (o3_case, "o3"), (ic_case, "ic"), (is_case, "is")):
    for _ in range(N):
        cases.append((kind, mk()))
    for _ in range(N // 10):
        cases.append((kind, scale(mk(), 2.0 ** random.randint(-300, 300))))
    cases.append((kind, [float(random.randint(-9, 9)) for _ in range({"o2": 6, "o3": 12, "ic": 8, "is": 15}[kind])]))


def sign(v):
    return "pos" if v > 0 else "neg" if v < 0 else "zero"


def d3(a, b, c, d, e, f, g, h, i):
    return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)


def exact(kind, c):
    x = list(map(Q, c))
    if kind == "o2":
        ax, ay, bx, by, cx, cy = x
        return sign((ax - cx) * (by - cy) - (ay - cy) * (bx - cx))
    if kind == "o3":
        d = x[9:12]
        m = [x[3 * k + j] - d[j] for k in range(3) for j in range(3)]
        return sign(d3(*m))
    if kind == "ic":
        d = x[6:8]
        r = []
        for k in range(3):
            px, py = x[2 * k] - d[0], x[2 * k + 1] - d[1]
            r += [px, py, px * px + py * py]
        return sign(d3(*r))
    e = x[12:15]
    v = [[x[3 * k + j] - e[j] for j in range(3)] for k in range(4)]
    q = [a * a + b * b + c * c for a, b, c in v]
    (ax, ay, az), (bx, by, bz), (cx, cy, cz), (dx, dy, dz) = v
    aq, bq, cq, dq = q
    t0 = ax * d3(by, bz, bq, cy, cz, cq, dy, dz, dq)
    t1 = ay * d3(bx, bz, bq, cx, cz, cq, dx, dz, dq)
    t2 = az * d3(bx, by, bq, cx, cy, cq, dx, dy, dq)
    t3 = aq * d3(bx, by, bz, cx, cy, cz, dx, dy, dz)
    return sign(t0 - t1 + t2 - t3)


def moderate(c):
    return all(x == 0 or 2.0 ** -120 <= abs(x) <= 2.0 ** 120 for x in c)


def lit(x):
    return "F64{" + str(struct.unpack("<Q", struct.pack("<d", x))[0]) + "u64}"


def call(kind, c):
    L = [lit(v) for v in c]
    if kind == "o2":
        return f"O.orient2d(V.V2{{{L[0]}, {L[1]}}}, V.V2{{{L[2]}, {L[3]}}}, V.V2{{{L[4]}, {L[5]}}})"
    if kind == "ic":
        return "O.incircle(" + ", ".join(f"V.V2{{{L[2*k]}, {L[2*k+1]}}}" for k in range(4)) + ")"
    n = 4 if kind == "o3" else 5
    f = "O.orient3d" if kind == "o3" else "O.insphere"
    return f + "(" + ", ".join(f"V.Pt{{{L[3*k]}, {L[3*k+1]}, {L[3*k+2]}}}" for k in range(n)) + ")"


if sys.argv[1] == "gen":
    src = os.path.relpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "src"), os.path.dirname(os.path.abspath(sys.argv[2]))).replace(os.sep, "/")
    body = [f'  sh({call(k, c)}) ++ "\\n"' for k, c in cases]
    parts = "".join(f"def part{i}() -> String:\n" + "\n  ++ ".join(b.strip() for b in body[i:i + 100]).join(["  ", "\n\n"]) for i in range(0, len(body), 100))
    open(sys.argv[2], "w", newline="\n").write(f"""import Base
import {src}/c01/types.bend as V
import {src}/c02/types.bend as P
import {src}/c02/ops.bend as O

def sh(+r: P.PRes) -> String:
  P.pres_show(r) ++ ":" ++ P.pres_sign_show(r)

{parts}def main() -> String:
  {" ++ ".join(f"part{i}()" for i in range(0, len(body), 100))}
""")
    sys.exit()

got = open(sys.argv[2]).read().strip().strip('"').replace("\\n", "\n").strip().split("\n")
assert len(got) == len(cases), (len(got), len(cases))
wrong, unc, unc_mod = 0, 0, 0
for (kind, c), g in zip(cases, got):
    show, sgn = g.split(":")
    want = exact(kind, c)
    if show == "numerical-uncertainty":
        unc += 1
        unc_mod += moderate(c)
    elif sgn != want:
        wrong += 1
        if wrong <= 5:
            print("WRONG", kind, c, g, want)
print(f"predicate oracle: {len(cases)} cases, wrong={wrong}, uncertain={unc} (moderate-magnitude {unc_mod})")
