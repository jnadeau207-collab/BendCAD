import os
import math, random, re, sys
import numpy as np

LIN, ANG = 1e-7, 1e-9
seed = int(sys.argv[3]) if len(sys.argv) > 3 else 1
count = int(sys.argv[4]) if len(sys.argv) > 4 else 120
FUEL = int(sys.argv[5]) if len(sys.argv) > 5 else 200
random.seed(seed)


def q(x):
    return round(x * 1024) / 1024


class Sk:
    def __init__(self):
        self.ps, self.cs, self.pts, self.circs, self.nid = [], [], [], [], 1

    def par(self, v):
        self.ps.append(v)
        return len(self.ps) - 1

    def pt(self, x, y):
        p = (self.par(x), self.par(y))
        self.pts.append(p)
        return p

    def add(self, *c):
        self.cs.append((self.nid,) + c)
        self.nid += 1


def xy(ps, p):
    return ps[p[0]], ps[p[1]]


def build(poison):
    s = Sk()
    n = random.randint(3, 6)
    for _ in range(n):
        s.pt(q(random.uniform(-10, 10)), q(random.uniform(-10, 10)))
    lines = [(s.pts[i], s.pts[i + 1]) for i in range(n - 1)]
    for a, b in lines:
        k = random.random()
        if k < 0.2:
            s.ps[b[1]] = s.ps[a[1]]
            s.add("horiz", a, b)
        elif k < 0.35:
            s.ps[b[0]] = s.ps[a[0]]
            s.add("vert", a, b)
    for _ in range(random.randint(0, 2)):
        c = s.pt(q(random.uniform(-10, 10)), q(random.uniform(-10, 10)))
        r = s.par(q(random.uniform(1, 5)))
        s.circs.append((c, r))
    if len(lines) >= 2 and random.random() < 0.5:
        (a, b), (c, d) = random.sample(lines, 2)
        if len({a, b, c, d}) == 4 and not any(d in x[2:4] for x in s.cs if x[1] in ("horiz", "vert")):
            ax, ay = xy(s.ps, a)
            bx, by = xy(s.ps, b)
            cx, cy = xy(s.ps, c)
            t = random.uniform(0.5, 1.5)
            if random.random() < 0.5:
                s.ps[d[0]], s.ps[d[1]] = cx + t * (bx - ax), cy + t * (by - ay)
                s.add("par", a, b, c, d)
            else:
                s.ps[d[0]], s.ps[d[1]] = cx - t * (by - ay), cy + t * (bx - ax)
                s.add("perp", a, b, c, d)
    for _ in range(random.randint(0, 3)):
        locked = {x for c in s.cs for x in c[2:] if isinstance(x, tuple)}
        cand = [t for t in s.pts[1:n] if t not in locked]
        a, b = random.choice(lines)
        cand = [t for t in cand if t not in (a, b)]
        k = random.choice(["online", "mid", "equal", "hdist", "vdist"])
        if k in ("hdist", "vdist"):
            p1, p2 = random.sample(s.pts[:n], 2)
            j = 0 if k == "hdist" else 1
            s.add(k, p1, p2, s.ps[p2[j]] - s.ps[p1[j]])
            continue
        if not cand or math.dist(xy(s.ps, a), xy(s.ps, b)) < 0.5:
            continue
        t = random.choice(cand)
        ax, ay = xy(s.ps, a)
        bx, by = xy(s.ps, b)
        if k == "online":
            u = random.uniform(-0.5, 1.5)
            s.ps[t[0]], s.ps[t[1]] = ax + u * (bx - ax), ay + u * (by - ay)
            s.add("online", t, a, b)
        elif k == "mid":
            s.ps[t[0]], s.ps[t[1]] = (ax + bx) / 2, (ay + by) / 2
            s.add("mid", t, a, b)
        else:
            c = random.choice([x for x in s.pts[:n] if x != t])
            cx, cy = xy(s.ps, c)
            tx, ty = xy(s.ps, t)
            l = math.hypot(tx - cx, ty - cy)
            if l < 0.5:
                continue
            m = math.hypot(bx - ax, by - ay) / l
            s.ps[t[0]], s.ps[t[1]] = cx + (tx - cx) * m, cy + (ty - cy) * m
            s.add("equal", a, b, c, t)
    if len(s.circs) == 2 and random.random() < 0.5:
        (c1, r1), (c2, r2) = s.circs
        (x1, y1), (x2, y2) = xy(s.ps, c1), xy(s.ps, c2)
        l = math.hypot(x2 - x1, y2 - y1)
        if l > 0.5:
            m = (s.ps[r1] + s.ps[r2]) / l
            s.ps[c2[0]], s.ps[c2[1]] = x1 + (x2 - x1) * m, y1 + (y2 - y1) * m
            s.add("tancc", c1, r1, c2, r2)
    for c, r in s.circs:
        if any(x[1] == "tancc" for x in s.cs):
            continue
        if random.random() < 0.4:
            a, b = random.choice(lines)
            (ax, ay), (bx, by), (ox, oy) = xy(s.ps, a), xy(s.ps, b), xy(s.ps, c)
            sd = ((bx - ax) * (oy - ay) - (by - ay) * (ox - ax)) / max(math.hypot(bx - ax, by - ay), 1e-300)
            if abs(sd) > 0.5 and math.hypot(bx - ax, by - ay) > 0.5:
                s.ps[r] = abs(sd)
                s.add("tanlc", a, b, c, r)
            continue
        p = random.choice(s.pts[:n])
        s.ps[r] = math.dist(xy(s.ps, p), xy(s.ps, c))
        if s.ps[r] > 0.5:
            s.add("oncirc", p, c, r)
    for _ in range(random.randint(1, 4)):
        a, b = random.sample(s.pts[:n], 2)
        d = math.dist(xy(s.ps, a), xy(s.ps, b))
        if d > 0.5:
            s.add("dist", a, b, d)
    if len(lines) >= 2 and random.random() < 0.5:
        (a, b), (c, d) = random.sample(lines, 2)
        ux, uy = s.ps[b[0]] - s.ps[a[0]], s.ps[b[1]] - s.ps[a[1]]
        vx, vy = s.ps[d[0]] - s.ps[c[0]], s.ps[d[1]] - s.ps[c[1]]
        if (a, b) != (c, d) and math.hypot(ux, uy) > 0.5 and math.hypot(vx, vy) > 0.5:
            th = math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            s.add("angle", a, b, c, d, math.cos(th), math.sin(th))
    for c, r in s.circs:
        s.add("radius", r, s.ps[r])
    if poison:
        ds = [c for c in s.cs if c[1] == "dist"]
        if not ds:
            return None
        c = random.choice(ds)
        s.add("dist", c[2], c[3], c[4] + random.uniform(0.5, 2))
    truth = list(s.ps)
    free = [True] * len(s.ps)
    free[s.pts[0][0]] = free[s.pts[0][1]] = False
    start = [v if not f else v + random.uniform(-0.3, 0.3) for v, f in zip(truth, free)]
    return s, [q(v) if f else v for v, f in zip(start, free)], free


def resid(c, ps, ps0=None):
    k = c[1]
    if k == "coinc":
        (ax, ay), (bx, by) = xy(ps, c[2]), xy(ps, c[3])
        return [ax - bx, ay - by], [LIN, LIN]
    if k in ("horiz", "vert"):
        (ax, ay), (bx, by) = xy(ps, c[2]), xy(ps, c[3])
        e = math.atan2(by - ay, bx - ax)
        return [math.sin(e) if k == "horiz" else math.cos(e)], [ANG]
    if k == "dist":
        return [math.dist(xy(ps, c[2]), xy(ps, c[3])) - c[4]], [LIN]
    if k == "radius":
        return [ps[c[2]] - c[3]], [LIN]
    if k == "oncirc":
        return [math.dist(xy(ps, c[2]), xy(ps, c[3])) - ps[c[4]]], [LIN]
    if k in ("hdist", "vdist"):
        j = 0 if k == "hdist" else 1
        return [ps[c[3][j]] - ps[c[2][j]] - c[4]], [LIN]
    if k == "tancc":
        d = math.dist(xy(ps, c[2]), xy(ps, c[4]))
        a0, b0 = ps0[c[3]], ps0[c[5]]
        if math.dist(xy(ps0, c[2]), xy(ps0, c[4])) < max(a0, b0):
            sg = -1.0 if a0 - b0 < 0 else 1.0
            return [d - sg * (ps[c[3]] - ps[c[5]])], [LIN]
        return [d - ps[c[3]] - ps[c[5]]], [LIN]
    if k == "tanlc":
        def sd(q):
            (ax, ay), (bx, by), (ox, oy) = xy(q, c[2]), xy(q, c[3]), xy(q, c[4])
            return ((bx - ax) * (oy - ay) - (by - ay) * (ox - ax)) / math.hypot(bx - ax, by - ay)
        return [(-1.0 if sd(ps0) < 0 else 1.0) * sd(ps) - ps[c[5]]], [LIN]
    if k == "online":
        (px_, py_), (ax, ay), (bx, by) = xy(ps, c[2]), xy(ps, c[3]), xy(ps, c[4])
        return [((bx - ax) * (py_ - ay) - (by - ay) * (px_ - ax)) / math.hypot(bx - ax, by - ay)], [LIN]
    if k == "mid":
        (mx, my), (ax, ay), (bx, by) = xy(ps, c[2]), xy(ps, c[3]), xy(ps, c[4])
        return [2 * mx - ax - bx, 2 * my - ay - by], [LIN, LIN]
    if k == "equal":
        return [math.dist(xy(ps, c[2]), xy(ps, c[3])) - math.dist(xy(ps, c[4]), xy(ps, c[5]))], [LIN]
    a, b, cc, d = c[2:6]
    cs, sn = (1.0, 0.0) if k == "par" else (0.0, 1.0) if k == "perp" else c[6:8]
    ux, uy = ps[b[0]] - ps[a[0]], ps[b[1]] - ps[a[1]]
    vx, vy = ps[d[0]] - ps[cc[0]], ps[d[1]] - ps[cc[1]]
    if k == "angle":
        e = math.atan2(vy, vx) - math.atan2(uy, ux) - math.atan2(sn, cs)
        e = math.atan2(math.sin(e), math.cos(e))
        return [math.sin(e) if abs(e) <= math.pi / 2 else math.copysign(2 - abs(math.sin(e)), e)], [ANG]
    wx, wy = cs * ux - sn * uy, sn * ux + cs * uy
    return [(wx * vy - wy * vx) / (math.hypot(ux, uy) * math.hypot(vx, vy))], [ANG]


def rows(s, ps, ps0):
    out = []
    for c in s.cs:
        r, t = resid(c, ps, ps0)
        out += [(c[0], ri / ti) for ri, ti in zip(r, t)]
    return out


def jac(s, ps, free, ps0):
    base = np.array([r for _, r in rows(s, ps, ps0)])
    cols = []
    for i, f in enumerate(free):
        if not f:
            continue
        h = 1e-3 * max(1.0, abs(ps[i]))

        def at(k):
            pk = list(ps)
            pk[i] += k * h
            return np.array([r for _, r in rows(s, pk, ps0)])
        cols.append((8 * (at(1) - at(-1)) - (at(2) - at(-2))) / (12 * h))
    return np.array(cols).T if cols else np.zeros((len(base), 0))


def rank(m):
    if m.size == 0:
        return 0
    sv = np.linalg.svd(m, compute_uv=False)
    return int((sv > 1e-5 * max(sv[0], 1.0)).sum())


def lit(v):
    t = repr(float(abs(v)))
    if "e" in t or "inf" in t or "nan" in t:
        t = format(abs(v), ".20f")
    if "." not in t:
        t += ".0"
    return f"F64.neg({t}f64)" if math.copysign(1, v) < 0 and v != 0 else f"{t}f64"


def pt(p):
    return f"S.Pt{{{p[0]}n, {p[1]}n}}"


def cn(c):
    k, i = c[1], c[0]
    if k in ("horiz", "vert", "coinc"):
        return f"S.K_{k}{{{i}u64, {pt(c[2])}, {pt(c[3])}}}"
    if k == "dist":
        return f"S.K_dist{{{i}u64, {pt(c[2])}, {pt(c[3])}, {lit(c[4])}}}"
    if k == "radius":
        return f"S.K_radius{{{i}u64, {c[2]}n, {lit(c[3])}}}"
    if k == "oncirc":
        return f"S.K_on_circ{{{i}u64, {pt(c[2])}, {pt(c[3])}, {c[4]}n}}"
    if k in ("par", "perp"):
        return f"S.K_{k}{{{i}u64, {', '.join(pt(p) for p in c[2:6])}}}"
    if k in ("hdist", "vdist"):
        return f"S.K_{k}{{{i}u64, {pt(c[2])}, {pt(c[3])}, {lit(c[4])}}}"
    if k == "tancc":
        return f"S.K_tan_cc{{{i}u64, {pt(c[2])}, {c[3]}n, {pt(c[4])}, {c[5]}n}}"
    if k == "tanlc":
        return f"S.K_tan_lc{{{i}u64, {pt(c[2])}, {pt(c[3])}, {pt(c[4])}, {c[5]}n}}"
    if k == "online":
        return f"S.K_on_line{{{i}u64, {pt(c[2])}, {pt(c[3])}, {pt(c[4])}}}"
    if k == "mid":
        return f"S.K_midpoint{{{i}u64, {pt(c[2])}, {pt(c[3])}, {pt(c[4])}}}"
    if k == "equal":
        return f"S.K_equal{{{i}u64, {', '.join(pt(p) for p in c[2:6])}}}"
    return f"S.K_angle{{{i}u64, {', '.join(pt(p) for p in c[2:6])}, {lit(c[6])}, {lit(c[7])}}}"


def trap(kind):
    s = Sk()
    a = s.pt(q(random.uniform(-5, 5)), q(random.uniform(-5, 5)))
    phi = random.uniform(-math.pi, math.pi)
    L = random.uniform(2, 8)
    b = s.pt(s.ps[a[0]] + L * math.cos(phi), s.ps[a[1]] + L * math.sin(phi))
    free = [False] * 4
    if kind == "flip":
        c = s.pt(q(random.uniform(-5, 5)), q(random.uniform(-5, 5)))
        th = random.uniform(-math.pi, math.pi)
        m = random.uniform(2, 8)
        dl = random.uniform(-0.35, 0.35)
        d = s.pt(s.ps[c[0]] + m * math.cos(phi + th + math.pi + dl), s.ps[c[1]] + m * math.sin(phi + th + math.pi + dl))
        s.add("angle", a, b, c, d, math.cos(th), math.sin(th))
        s.add("dist", c, d, m)
        free = [False] * 6 + [True, True]
    elif kind == "collapse":
        s.add("horiz", a, b)
        s.add("vert", a, b) if random.random() < 0.5 else s.add("coinc", a, b)
        free = [False, False, True, True]
    else:
        o = s.pt(s.ps[a[0]] + 0.5 * L * math.cos(phi) - 2 * math.sin(phi), s.ps[a[1]] + 0.5 * L * math.sin(phi) + 2 * math.cos(phi))
        r = s.par(2.0)
        s.add("tanlc", a, b, o, r)
        cph = math.cos(phi)
        if abs(cph) < 0.3:
            return trap(kind)
        s.add("vdist", a, o, s.ps[o[1]] - s.ps[a[1]] - (2 / abs(cph)) * random.uniform(1.5, 3) * (1 if cph > 0 else -1))
        free = [False] * 4 + [False, True, True]
    return s, list(s.ps), free, kind


def shift(x, off):
    if isinstance(x, tuple):
        return (x[0] + off, x[1] + off)
    if isinstance(x, int):
        return x + off
    return x


def multi():
    subs = []
    while len(subs) < random.randint(2, 4):
        pz = random.random() < 0.3
        b = build(poison=pz)
        if b:
            subs.append(b + (pz,))
    m = Sk()
    start, free, cons = [], [], []
    for t, st, fr, pz in subs:
        off = len(m.ps)
        m.ps += t.ps
        start += st
        free += fr
        tw = next(c for c in t.cs if c[1] == "dist" and c[2:4] == t.cs[-1][2:4]) if pz else None
        for c in t.cs:
            cons.append(((c[1],) + tuple(shift(x, off) for x in c[2:]), id(t), pz, c is t.cs[-1] and pz, c is tw))
    random.shuffle(cons)
    m.cs = [(i + 1,) + c[0] for i, c in enumerate(cons)]
    m.part = {i + 1: c[1] for i, c in enumerate(cons)}
    m.pzids = {i + 1 for i, c in enumerate(cons) if c[2]}
    parts = {}
    for i, c in enumerate(cons):
        if c[3] or c[4]:
            parts.setdefault(c[1], set()).add(i + 1)
    m.pairs = list(parts.values())
    return m, start, free, "multi"


cases = []
while len(cases) < count:
    b = build(poison=len(cases) % 3 == 2)
    if b:
        cases.append(b + ("poison" if len(cases) % 3 == 2 else "consistent",))
cases += [trap(["flip", "collapse", "negrad"][i % 3]) for i in range(count // 3)]
cases += [multi() for _ in range(count // 3)]

def blist(xs, ty):
    if len(xs) <= 128:
        return "[" + ", ".join(xs) + "]"
    return f"List.append(&2, {ty}, [" + ", ".join(xs[:128]) + "], " + blist(xs[128:], ty) + ")"


if sys.argv[1] == "gen":
    src = os.path.relpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "src"), os.path.dirname(os.path.abspath(sys.argv[2]))).replace(os.sep, "/")
    body = []
    for s, start, free, role in cases:
        body.append("  S.sol_show(S.solve(" + blist([lit(v) for v in start], "F64") + ", "
                    + blist(["True{}" if f else "False{}" for f in free], "Bool") + ", "
                    + blist([cn(c) for c in s.cs], "S.Cn") + f", tol(), {FUEL}n)) ++ \"\\n\"")
    open(sys.argv[2], "w", newline="\n").write("""import Base
import SRC/c00/types.bend as T
import SRC/c05/solve.bend as S

def tol() -> T.Tol:
  T.mk_tol(0.0000001f64, 0.000000001f64, 0.000000001f64, 0.000001f64, 0.0000001f64)

""".replace("SRC", src) + "".join(f"def part{k}() -> String:\n" + "\n  ++ ".join(b.strip() for b in body[k:k + 100]).join(["  ", "\n\n"]) for k in range(0, len(body), 100))
        + "def main() -> String:\n  " + " ++ ".join(f"part{k}()" for k in range(0, len(body), 100)) + "\n")
    sys.exit()

got = open(sys.argv[2]).read().strip().strip('"').replace("\\n", "\n").strip().split("\n")
assert len(got) == len(cases), (len(got), len(cases))
tally = {}
bad = 0
for n, ((s, start, free, role), line) in enumerate(zip(cases, got)):
    poison = role == "poison" or (role == "multi" and bool(s.pzids))
    errs = []
    m = re.fullmatch(r"ok dof=(\d+) red=\[([\d,]*)\] ps=(.*)", line)
    kind = "ok" if m else line.split()[0] if not line.startswith("err") else line
    tally[(role, kind)] = tally.get((role, kind), 0) + 1
    if role in ("collapse", "negrad"):
        if m:
            errs.append(f"{role} trap reported ok")
    elif role == "flip" and not m:
        errs.append("flipped start did not solve")
    elif m:
        ps = [float(v) for v in m[3].split()]
        if poison:
            errs.append("poisoned system reported ok")
        worst = max((abs(r) for _, r in rows(s, ps, start)), default=0)
        if worst > 1 + 1e-6:
            errs.append(f"residual {worst} tol-units")
        if any(p != v for p, v, f in zip(ps, start, free) if not f):
            errs.append("fixed parameter moved")
        J = jac(s, ps, free, start)
        ids = [r[0] for r in rows(s, ps, start)]
        kept, dep, grey = [], set(), False
        for i, rid in enumerate(ids):
            v = J[i]
            w = v.copy()
            for _ in range(2):
                for q_ in kept:
                    w = w - (q_ @ w) * q_
            nv, nw = np.linalg.norm(v), np.linalg.norm(w)
            if nw <= 1e-9 * nv:
                dep.add(rid)
            elif nw >= 1e-6 * nv:
                kept.append(w / nw)
            else:
                grey = True
        red = [int(x) for x in m[2].split(",") if x]
        if grey:
            tally[("grey", "skipped")] = tally.get(("grey", "skipped"), 0) + 1
        else:
            if sum(free) - len(kept) != int(m[1]):
                errs.append(f"dof {m[1]} != reference {sum(free) - len(kept)}")
            if set(red) != dep:
                errs.append(f"redundant {sorted(red)} != reference {sorted(dep)}")
    elif role == "multi" and line.startswith("conflict") and poison:
        named = {int(x) for x in re.search(r"\[([\d,]*)\]", line)[1].split(",") if x}
        if not named <= s.pzids:
            errs.append(f"conflict {sorted(named)} blames constraints outside the poisoned parts")
        if not any(pr <= named for pr in s.pairs):
            errs.append(f"conflict {sorted(named)} names no complete contradicting pair {s.pairs}")
    elif role == "multi" and not poison:
        errs.append(f"consistent multi-part system reported {line[:40]}")
    elif role == "multi" and line.startswith("err") and "nonconvergence" not in line:
        errs.append("unexpected error arm")
    elif role != "consistent" and role != "poison":
        pass
    elif line.startswith("conflict") and not poison:
        errs.append("consistent system reported conflict")
    elif line.startswith("conflict"):
        named = {int(x) for x in re.search(r"\[([\d,]*)\]", line)[1].split(",") if x}
        pz = s.cs[-1]
        twin = next(c[0] for c in s.cs if c[1] == "dist" and c[2:4] == pz[2:4])
        if not {pz[0], twin} <= named:
            errs.append(f"conflict {sorted(named)} misses the contradicting pair {twin},{pz[0]}")
    elif line.startswith("err") and "nonconvergence" not in line:
        errs.append("unexpected error arm")
    if errs:
        bad += 1
        if bad <= 6:
            print("case", n, role, s.cs, "\n  ", line[:300], "\n  ", errs)
print(f"solver oracle: {len(cases)} cases, wrong={bad}, arms={sorted(tally.items())}")
