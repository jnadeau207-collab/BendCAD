import math
import struct


def bits(v):
    return struct.unpack('>Q', struct.pack('>d', v))[0]


def unbits(n):
    return struct.unpack('>d', struct.pack('>Q', n))[0]


def dn(x):
    return math.nextafter(x, -math.inf)


def up(x):
    return math.nextafter(x, math.inf)


def ipt(x):
    return (x, x)


def imid(a):
    return 0.5 * a[0] + 0.5 * a[1]


def iadd(a, b):
    return (dn(a[0] + b[0]), up(a[1] + b[1]))


def isub(a, b):
    return (dn(a[0] - b[1]), up(a[1] - b[0]))


def imul(a, b):
    ps = (a[0] * b[0], a[0] * b[1], a[1] * b[0], a[1] * b[1])
    return (dn(min(ps)), up(max(ps)))


def idiv(a, b):
    if b[0] <= 0.0 <= b[1]:
        return (math.nan, math.nan)
    ps = (a[0] / b[0], a[0] / b[1], a[1] / b[0], a[1] / b[1])
    return (dn(min(ps)), up(max(ps)))


def isqrt(a):
    return (dn(math.sqrt(max(0.0, a[0]))), up(math.sqrt(a[1])))


def iscale(a, k):
    return imul(a, ipt(k))


def imax(a, b):
    return (max(a[0], b[0]), max(a[1], b[1]))


def iabs(a):
    lo, hi = a
    l = 0.0 if (lo <= 0.0 <= hi) else min(abs(lo), abs(hi))
    return (l, max(abs(lo), abs(hi)))


def st_x(i, k):
    return idiv(ipt(float(i)), ipt(float(k - 1)))


def m_I(m):
    return idiv(ipt(float(m)), ipt(100.0))


def p_I(p):
    return idiv(ipt(float(p)), ipt(10.0))


def t_I(t):
    return idiv(ipt(float(t)), ipt(100.0))


def yt_I(t, x):
    x2 = imul(x, x)
    x3 = imul(x2, x)
    x4 = imul(x3, x)
    sq = isqrt(x)
    y1 = imul(ipt(0.2969), sq)
    y2 = imul(ipt(0.1260), x)
    y3 = imul(ipt(0.3516), x2)
    y4 = imul(ipt(0.2843), x3)
    y5 = imul(ipt(0.1036), x4)
    return imul(imul(ipt(5.0), t), isub(iadd(y1, y4), iadd(iadd(y2, y3), y5)))


def yc_lo(m, p, x):
    mpp = idiv(m, imul(p, p))
    return imul(mpp, isub(imul(imul(ipt(2.0), p), x), imul(x, x)))


def yc_hi(m, p, x):
    q = isub(ipt(1.0), p)
    mqq = idiv(m, imul(q, q))
    c0 = isub(ipt(1.0), imul(ipt(2.0), p))
    return imul(mqq, isub(iadd(c0, imul(imul(ipt(2.0), p), x)), imul(x, x)))


def dyc_lo(m, p, x):
    mpp = idiv(m, imul(p, p))
    return imul(mpp, isub(imul(ipt(2.0), p), imul(ipt(2.0), x)))


def dyc_hi(m, p, x):
    q = isub(ipt(1.0), p)
    mqq = idiv(m, imul(q, q))
    return imul(mqq, isub(imul(ipt(2.0), p), imul(ipt(2.0), x)))


def camber(m, p, x):
    if m == 0:
        return (ipt(0.0), ipt(0.0))
    mi, pi = m_I(m), p_I(p)
    if imid(x) < imid(pi):
        return (yc_lo(mi, pi, x), dyc_lo(mi, pi, x))
    return (yc_hi(mi, pi, x), dyc_hi(mi, pi, x))


def surf_ip(m, p, t, k, i, upper):
    x = st_x(i, k)
    yt = yt_I(t_I(t), x)
    yc, dd = camber(m, p, x)
    ell = isqrt(iadd(ipt(1.0), imul(dd, dd)))
    qx = idiv(imul(yt, dd), ell)
    qy = idiv(yt, ell)
    if upper:
        return (isub(x, qx), iadd(yc, qy))
    return (iadd(x, qx), isub(yc, qy))


def ring_ip(m, p, t, k, j):
    if j < k:
        return surf_ip(m, p, t, k, k - 1 - j, True)
    return surf_ip(m, p, t, k, j - (k - 1), False)


def ring_m(k):
    return 2 * k - 2


def ang_I(tw, i, n):
    return imul(ipt(float(tw)), idiv(ipt(float(i)), ipt(float(n - 1))))


def z_I(zv, i, n):
    return imul(ipt(zv), idiv(ipt(float(i)), ipt(float(n - 1))))


def scl_I(tp, i, n):
    f = idiv(isub(ipt(float(tp)), ipt(100.0)), ipt(100.0))
    return iadd(ipt(1.0), imul(f, idiv(ipt(float(i)), ipt(float(n - 1)))))


def csc_exact():
    return (ipt(1.0), ipt(0.0))


def stk_Q(m, p, chord):
    yc, _ = camber(m, p, ipt(0.25))
    return (imul(ipt(0.25), chord), imul(yc, chord))


def place_sec(m, p, t, c, k, zv, tw, tp, n, i, csc=None):
    chord = imul(ipt(c), scl_I(tp, i, n))
    z = z_I(zv, i, n)
    if csc is None:
        a = imid(ang_I(tw, i, n))
        assert a == 0.0, a
        cos, sin = csc_exact()
    else:
        cos, sin = csc
    qx, qy = stk_Q(m, p, chord)
    return dict(m=m, p=p, t=t, c=c, k=k, chord=chord, z=z, cos=cos, sin=sin, qx=qx, qy=qy)


def place_ip(se, j):
    px, py = ring_ip(se['m'], se['p'], se['t'], se['k'], j)
    sx = imul(px, se['chord'])
    sy = imul(py, se['chord'])
    dx = isub(sx, se['qx'])
    dy = isub(sy, se['qy'])
    rx = iadd(isub(imul(dx, se['cos']), imul(dy, se['sin'])), se['qx'])
    ry = iadd(iadd(imul(dx, se['sin']), imul(dy, se['cos'])), se['qy'])
    return (rx, ry)


def cross(a, b):
    return isub(imul(a[0], b[1]), imul(b[0], a[1]))


def sec_area(se):
    m = ring_m(se['k'])
    acc = ipt(0.0)
    for j in range(m):
        j1 = (j + 1) % m
        acc = iadd(acc, cross(place_ip(se, j), place_ip(se, j1)))
    return iscale(acc, 0.5)


def sec_cen(se, area):
    m = ring_m(se['k'])
    ax, ay = ipt(0.0), ipt(0.0)
    for j in range(m):
        j1 = (j + 1) % m
        a = place_ip(se, j)
        b = place_ip(se, j1)
        c = cross(a, b)
        ax = iadd(ax, imul(iadd(a[0], b[0]), c))
        ay = iadd(ay, imul(iadd(a[1], b[1]), c))
    d = imul(ipt(6.0), area)
    return (idiv(ax, d), idiv(ay, d))


def sec_th(m, p, t, k):
    ti = t_I(t)
    ay, ac = ipt(0.0), ipt(0.0)
    for i in range(k):
        x = st_x(i, k)
        ay = imax(ay, yt_I(ti, x))
        yc, _ = camber(m, p, x)
        ac = imax(ac, iabs(yc))
    return (ay, ac)


def sec_row(se, i):
    m = ring_m(se['k'])
    a = sec_area(se)
    cx, cy = sec_cen(se, a)
    ay, ac = sec_th(se['m'], se['p'], se['t'], se['k'])
    tmax = imul(se['chord'], imul(ipt(2.0), ay))
    cmax = imul(se['chord'], ac)
    return dict(i=i, area=a, cx=cx, cy=cy, tmax=tmax, cmax=cmax, z=se['z'])


def deviation(ses):
    h, q = ses[0], ses[-1]
    dx = isub(q['qx'], h['qx'])
    dy = isub(q['qy'], h['qy'])
    return isqrt(iadd(imul(dx, dx), imul(dy, dy)))


def mid_area(a, b):
    m = ring_m(a['k'])
    acc = ipt(0.0)
    for j in range(m):
        j1 = (j + 1) % m
        pa0, pb0 = place_ip(a, j), place_ip(b, j)
        pa1, pb1 = place_ip(a, j1), place_ip(b, j1)
        u = (iscale(iadd(pa0[0], pb0[0]), 0.5), iscale(iadd(pa0[1], pb0[1]), 0.5))
        v = (iscale(iadd(pa1[0], pb1[0]), 0.5), iscale(iadd(pa1[1], pb1[1]), 0.5))
        acc = iadd(acc, cross(u, v))
    return iscale(acc, 0.5)


def blade_vol(ses, zv):
    n = len(ses)
    h = idiv(ipt(zv), ipt(float(n - 1)))
    acc = ipt(0.0)
    for s in range(n - 1):
        aa = sec_area(ses[s])
        ab = sec_area(ses[s + 1])
        am = mid_area(ses[s], ses[s + 1])
        acc = iadd(acc, imul(idiv(h, ipt(6.0)), iadd(aa, iadd(imul(ipt(4.0), am), ab))))
    return acc


def frustum_vol(areas, zv):
    import math as _m
    n = len(areas)
    h = zv / (n - 1)
    tot = 0.0
    for s in range(n - 1):
        a, b = areas[s], areas[s + 1]
        tot += h / 3.0 * (a + b + _m.sqrt(a * b))
    return tot


def stack(secs, zv, tw, tp, cscs=None):
    n = len(secs)
    out = []
    for i, (m, p, t, c, k) in enumerate(secs):
        csc = None if cscs is None else cscs[i]
        out.append(place_sec(m, p, t, c, k, zv, tw, tp, n, i, csc))
    return out


def float_ring(m, p, t, c, k):
    import math as _m
    mm, pp, tt = m / 100.0, p / 10.0, t / 100.0

    def yt(x):
        return 5 * tt * (0.2969 * _m.sqrt(x) - 0.1260 * x - 0.3516 * x * x +
                         0.2843 * x**3 - 0.1036 * x**4)

    def cam(x):
        if m == 0:
            return (0.0, 0.0)
        if x < pp:
            return (mm / (pp**2) * (2 * pp * x - x * x), mm / (pp**2) * (2 * pp - 2 * x))
        q = 1 - pp
        return (mm / (q**2) * ((1 - 2 * pp) + 2 * pp * x - x * x),
                mm / (q**2) * (2 * pp - 2 * x))

    pts = []
    for j in range(ring_m(k)):
        if j < k:
            i, upper = k - 1 - j, True
        else:
            i, upper = j - (k - 1), False
        x = i / (k - 1)
        y, d = cam(x)
        th = yt(x)
        ell = _m.sqrt(1 + d * d)
        if upper:
            pts.append((c * (x - th * d / ell), c * (y + th / ell)))
        else:
            pts.append((c * (x + th * d / ell), c * (y - th / ell)))
    return pts


def float_area(pts):
    a = 0.0
    m = len(pts)
    for j in range(m):
        x0, y0 = pts[j]
        x1, y1 = pts[(j + 1) % m]
        a += x0 * y1 - x1 * y0
    return a / 2.0


def float_place(pts, chord_scale, deg, q):
    import math as _m
    r = _m.radians(deg)
    co, si = _m.cos(r), _m.sin(r)
    qx, qy = q
    out = []
    for x, y in pts:
        sx, sy = x * chord_scale, y * chord_scale
        dx, dy = sx - qx, sy - qy
        out.append((dx * co - dy * si + qx, dx * si + dy * co + qy))
    return out


def twist_csc(deg):
    import math as _m
    r = _m.radians(deg)
    co, si = _m.cos(r), _m.sin(r)
    return ((dn(co), up(co)), (dn(si), up(si)))


def float_cam(m, p, x):
    if m == 0:
        return 0.0
    mm, pp = m / 100.0, p / 10.0
    if x < pp:
        return mm / (pp ** 2) * (2 * pp * x - x * x)
    q = 1 - pp
    return mm / (q ** 2) * ((1 - 2 * pp) + 2 * pp * x - x * x)


def float_stack_sec(m, p, t, c, k, zv, tw, tp, n, i):
    chord = c * (1 + (tp - 100) / 100.0 * i / (n - 1))
    q = (0.25 * chord, float_cam(m, p, 0.25) * chord)
    ring = float_ring(m, p, t, chord, k)
    deg = tw * i / (n - 1)
    return float_place(ring, 1.0, deg, q), zv * i / (n - 1), q


def bpair(tag, iv):
    lo, hi = iv
    return f'{tag} {bits(lo)} {bits(hi)}'
