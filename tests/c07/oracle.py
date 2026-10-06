from fractions import Fraction as Fr


def F(x):
    return Fr(x)


def padd(a, b):
    n = max(len(a), len(b))
    return [(a[i] if i < len(a) else 0) + (b[i] if i < len(b) else 0) for i in range(n)]


def pscale(s, a):
    return [s * x for x in a]


def pmul(a, b):
    if not a or not b:
        return []
    r = [Fr(0)] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        if x == 0:
            continue
        for j, y in enumerate(b):
            r[i + j] += x * y
    return r


def ptrim(a):
    a = list(a)
    while a and a[-1] == 0:
        a.pop()
    return a


def peval(a, t):
    r = Fr(0)
    for c in reversed(a):
        r = r * t + c
    return r


def pder(a):
    return [i * a[i] for i in range(1, len(a))]


def pdivmod(a, b):
    a = ptrim(a)
    b = ptrim(b)
    q = [Fr(0)] * max(len(a) - len(b) + 1, 1)
    while len(a) >= len(b) and a:
        k = len(a) - len(b)
        c = a[-1] / b[-1]
        q[k] = c
        a = ptrim(padd(a, pscale(-c, [Fr(0)] * k + b)))
    return q, a


def sturm(p):
    p = ptrim(p)
    seq = [p, ptrim(pder(p))]
    while seq[-1]:
        _, r = pdivmod(seq[-2], seq[-1])
        seq.append(ptrim(pscale(-1, r)))
    return seq[:-1]


def sign_changes(seq, x):
    vals = [peval(s, x) for s in seq]
    vals = [v for v in vals if v != 0]
    return sum(1 for a, b in zip(vals, vals[1:]) if (a < 0) != (b < 0))


def count_roots(seq, a, b):
    return sign_changes(seq, a) - sign_changes(seq, b)


def squarefree(p):
    p = ptrim(p)
    d = ptrim(pder(p))
    g = p
    h = d
    while h:
        _, r = pdivmod(g, h)
        g, h = h, ptrim(r)
    if len(g) <= 1:
        return p
    q, _ = pdivmod(p, g)
    return ptrim(q)


def isolate(p, a, b, eps=Fr(1, 10 ** 30)):
    p = squarefree(p)
    if not p or len(p) == 1:
        return []
    seq = sturm(p)
    out = []
    stack = [(Fr(a), Fr(b))]
    while stack:
        lo, hi = stack.pop()
        n = count_roots(seq, lo, hi)
        if peval(p, hi) == 0:
            out.append((hi, hi))
            n -= 1
            hi = hi - eps / 4
            if n <= 0:
                continue
        if n == 0:
            continue
        if n == 1 and hi - lo < eps:
            out.append((lo, hi))
            continue
        mid = (lo + hi) / 2
        stack.append((lo, mid))
        stack.append((mid, hi))
    if peval(p, Fr(a)) == 0:
        out.append((Fr(a), Fr(a)))
    uniq = []
    for r in sorted(out):
        if not uniq or r[0] > uniq[-1][1]:
            uniq.append(r)
    return uniq


def curve_poly(kind, v):
    if kind == 'line':
        p, d = [F(x) for x in v[0:3]], [F(x) for x in v[3:6]]
        X = [[p[i], d[i]] for i in range(3)]
        return X, [Fr(1)], (F(v[6]), F(v[7]))
    if kind == 'circle':
        c, u, w, r = [F(x) for x in v[0:3]], [F(x) for x in v[3:6]], [F(x) for x in v[6:9]], F(v[9])
        D = [Fr(1), Fr(0), Fr(2), Fr(0), Fr(1)]
        N1 = [Fr(1), Fr(0), Fr(-6), Fr(0), Fr(1)]
        N2 = [Fr(0), Fr(4), Fr(0), Fr(-4), Fr(0)]
        X = [padd(padd(pscale(c[i], D), pscale(r * u[i], N1)), pscale(r * w[i], N2)) for i in range(3)]
        return X, D, (F(v[10]), F(v[11]))
    if kind == 'bezier':
        P = [[F(x) for x in v[3 * k:3 * k + 3]] for k in range(4)]
        X = []
        for i in range(3):
            a, b, c, d = P[0][i], P[1][i], P[2][i], P[3][i]
            X.append([a, 3 * (b - a), 3 * (c - 2 * b + a), d - 3 * c + 3 * b - a])
        return X, [Fr(1)], (F(v[12]), F(v[13]))
    if kind == 'conic':
        P = [[F(x) for x in v[3 * k:3 * k + 3]] for k in range(3)]
        w = [F(x) for x in v[9:12]]
        X = []
        for i in range(3):
            a, b, c = w[0] * P[0][i], w[1] * P[1][i], w[2] * P[2][i]
            X.append([a, 2 * (b - a), a - 2 * b + c])
        W = [w[0], 2 * (w[1] - w[0]), w[0] - 2 * w[1] + w[2]]
        return X, W, (F(v[12]), F(v[13]))
    raise ValueError(kind)


def surf_comp(kind, v, X, W):
    ww = pmul(W, W)
    if kind == 'plane':
        o, u, w = [F(x) for x in v[0:3]], [F(x) for x in v[3:6]], [F(x) for x in v[6:9]]
        n = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]]
        M = [padd(X[i], pscale(-o[i], W)) for i in range(3)]
        return padd(padd(pscale(n[0], M[0]), pscale(n[1], M[1])), pscale(n[2], M[2]))
    o = [F(x) for x in v[0:3]]
    M = [padd(X[i], pscale(-o[i], W)) for i in range(3)]
    mm = padd(padd(pmul(M[0], M[0]), pmul(M[1], M[1])), pmul(M[2], M[2]))
    if kind == 'sphere':
        r = F(v[3])
        return padd(mm, pscale(-r * r, ww))
    a = [F(x) for x in v[3:6]]
    aa = sum(x * x for x in a)
    am = padd(padd(pscale(a[0], M[0]), pscale(a[1], M[1])), pscale(a[2], M[2]))
    if kind == 'cylinder':
        r = F(v[6])
        return padd(padd(pscale(aa, mm), pscale(-1, pmul(am, am))), pscale(-aa * r * r, ww))
    if kind == 'cone':
        k = F(v[6])
        return padd(pscale(aa, mm), pscale(-(1 + k * k), pmul(am, am)))
    if kind == 'torus':
        R, r = F(v[6]), F(v[7])
        q = padd(mm, pscale(R * R - r * r, ww))
        return padd(pscale(aa, pmul(q, q)), pscale(-4 * R * R, pmul(ww, padd(pscale(aa, mm), pscale(-1, pmul(am, am))))))
    raise ValueError(kind)


def curve_surface_roots(ck, cv, sk, sv):
    X, W, (lo, hi) = curve_poly(ck, cv)
    f = ptrim(surf_comp(sk, sv, X, W))
    if not f:
        return 'identical', []
    roots = isolate(f, lo, hi)
    if sk == 'cone':
        o = [F(x) for x in sv[0:3]]
        a = [F(x) for x in sv[3:6]]
        keep = []
        for r in roots:
            t = (r[0] + r[1]) / 2
            w = peval(W, t)
            pt = [peval(X[i], t) / w for i in range(3)]
            side = sum(a[i] * (pt[i] - o[i]) for i in range(3))
            if side >= 0:
                keep.append(r)
        roots = keep
    return 'roots', roots


def line_poly_2d(ck, cv, i, j, lk, lv):
    X, W, dom = curve_poly(ck, cv)
    p, d = [F(x) for x in lv[0:3]], [F(x) for x in lv[3:6]]
    f = padd(pscale(d[j], padd(X[i], pscale(-p[i], W))), pscale(-d[i], padd(X[j], pscale(-p[j], W))))
    return ptrim(f), dom
