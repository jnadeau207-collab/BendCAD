"""C16.2 suite-side oracles: independent subdivision/geometry references.

Pure Python (stdlib only). The kernel's certified intervals must contain the
oracle values; its subdivision estimates must agree within 1%.
"""

import math


def bbern(t):
    s = 1.0 - t
    return (s * s * s, 3.0 * s * s * t, 3.0 * s * t * t, t * t * t)


def bez3(p0, p1, p2, p3, t):
    b0, b1, b2, b3 = bbern(t)
    return tuple(b0 * a + b1 * b + b2 * c + b3 * d for a, b, c, d in zip(p0, p1, p2, p3))


def bezp(pp, u, v):
    rows = [bez3(*pp[r * 4:(r + 1) * 4], u) for r in range(4)]
    bu = bbern(u)
    _ = bu
    return bez3(*rows, v)


def tri_area(a, b, c):
    ux, uy, uz = (bj - ai for ai, bj in zip(a, b))
    vx, vy, vz = (cj - ai for ai, cj in zip(a, c))
    nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
    return 0.5 * math.sqrt(nx * nx + ny * ny + nz * nz)


def patch_area(pp, n=96):
    tot = 0.0
    for i in range(n):
        for j in range(n):
            u0, u1 = i / n, (i + 1) / n
            v0, v1 = j / n, (j + 1) / n
            a = bezp(pp, u0, v0)
            b = bezp(pp, u1, v0)
            c = bezp(pp, u1, v1)
            d = bezp(pp, u0, v1)
            tot += tri_area(a, b, c) + tri_area(a, c, d)
    return tot


def curve_length(p0, p1, p2, p3, n=2048):
    tot = 0.0
    prev = p0
    for i in range(1, n + 1):
        cur = bez3(p0, p1, p2, p3, i / n)
        tot += math.dist(prev, cur)
        prev = cur
    return tot


def patch_boundary(pp):
    r0 = (pp[0], pp[1], pp[2], pp[3])
    c3 = (pp[3], pp[7], pp[11], pp[15])
    r3 = (pp[15], pp[14], pp[13], pp[12])
    c0 = (pp[12], pp[8], pp[4], pp[0])
    return [curve_length(*c) for c in (r0, c3, r3, c0)]


def frustum_vol(z, x0, y0, x1, y1, u0, v0, u1, v1):
    a0 = (x1 - x0) * (y1 - y0)
    a1 = (u1 - u0) * (v1 - v0)
    am = ((x1 - x0) + (u1 - u0)) / 2.0 * ((y1 - y0) + (v1 - v0)) / 2.0
    return z / 6.0 * (a0 + a1 + 4.0 * am)


def duct_vol(lo, t):
    z, x0, y0, x1, y1, u0, v0, u1, v1 = lo
    h = t / 2.0

    def off(d, ny):
        return h / ny

    lf = math.hypot(v0 - y0, z)
    lb = math.hypot(v1 - y1, z)
    ll = math.hypot(u0 - x0, z)
    lr = math.hypot(u1 - x1, z)
    mf, mb, ml, mr = -h * lf / z, h * lb / z, -h * ll / z, h * lr / z
    outer = (x0 + ml, y0 + mf, x1 + mr, y1 + mb, u0 + ml, v0 + mf, u1 + mr, v1 + mb)
    inner = (x0 - ml, y0 - mf, x1 - mr, y1 - mb, u0 - ml, v0 - mf, u1 - mr, v1 - mb)
    return frustum_vol(z, *outer) - frustum_vol(z, *inner)


def sector_vol(deg, r0, r1, z0, z1, t):
    h = t / 2.0
    k = deg / 360.0 * math.pi
    ao = ((r1 + h) ** 2 - (r0 - h) ** 2) * ((z1 + h) - (z0 - h))
    ai = ((r1 - h) ** 2 - (r0 + h) ** 2) * ((z1 - h) - (z0 + h))
    return k * (ao - ai)


def sector_area(deg, r0, r1, z0, z1):
    th = deg / 360.0 * 2.0 * math.pi
    return th * ((r1 * r1 - r0 * r0) + (r1 + r0) * (z1 - z0))


def loft_area(lo):
    z, x0, y0, x1, y1, u0, v0, u1, v1 = lo
    b = [(x0, y0, 0.0), (x1, y0, 0.0), (x1, y1, 0.0), (x0, y1, 0.0)]
    t = [(u0, v0, z), (u1, v0, z), (u1, v1, z), (u0, v1, z)]
    tot = 0.0
    for i in range(4):
        j = (i + 1) % 4
        tot += tri_area(b[i], b[j], t[j]) + tri_area(b[i], t[j], t[i])
    return tot


def patch_center(pp):
    return bezp(pp, 0.5, 0.5)[2]


def slab_vol(c0, c1, c3, t):
    e1 = [b - a for a, b in zip(c0, c1)]
    e2 = [b - a for a, b in zip(c0, c3)]
    n = (e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0])
    return math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2) * t
