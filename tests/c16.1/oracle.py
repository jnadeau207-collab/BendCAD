import math
import struct

PI_BITS = 4614256656552045848
PI_LO_BITS = 4614256656552045847
PI_HI_BITS = 4614256656552045849


def bits(v):
    return struct.unpack('>Q', struct.pack('>d', v))[0]


def unbits(n):
    return struct.unpack('>d', struct.pack('>Q', n))[0]


def dn(x):
    return math.nextafter(x, -math.inf)


def up(x):
    return math.nextafter(x, math.inf)


def iadd(a, b):
    return (dn(a[0] + b[0]), up(a[1] + b[1]))


def imul(a, b):
    ps = (a[0] * b[0], a[0] * b[1], a[1] * b[0], a[1] * b[1])
    return (dn(min(ps)), up(max(ps)))


def ipt(x):
    return (x, x)


PI = unbits(PI_BITS)
PI_I = (unbits(PI_LO_BITS), unbits(PI_HI_BITS))


def allow(deg, r, t, klo, khi):
    kk = (klo, khi)
    rt = iadd(ipt(r), imul(kk, ipt(t)))
    c = imul(ipt(2.0), PI_I)
    f = 0.5 if deg == 180 else 0.25
    return imul(ipt(f), imul(c, rt))


def legs(k, l, t, r, lh):
    l1 = l / 2.0
    ro = r + t
    f1 = l1 - ro
    fu = (l - 2.0 * ro) / 4.0
    web = l - 2.0 * ro
    if k in (0, 1, 2, 3):
        return [l1, f1]
    if k in (4, 5):
        return [fu, web, fu]
    if k in (6, 7):
        return [l, t, lh]
    if k in (8, 9):
        return [l1, f1 - lh, t, lh, lh]
    if k in (10, 11):
        return [fu - lh, t, lh, lh, web, fu]
    return [l]


def developed(k, l, t, r, lh, allows):
    acc = (0.0, 0.0)
    for v in legs(k, l, t, r, lh):
        acc = iadd(acc, ipt(v))
    for a in allows:
        acc = iadd(acc, a)
    return acc


def vol_arc(l, t, r, w, half):
    l1 = l / 2.0
    ro = r + t
    f1 = l1 - ro
    q = PI / 2.0 if half else PI / 4.0
    d = ro * ro - r * r
    an = q * d
    a = l1 * t + (f1 * t + an)
    return a * w


def vol_u(l, t, r, w):
    ro = r + t
    fu = (l - 2.0 * ro) / 4.0
    t1 = fu - (t + r)
    leg = (2.0 * t) * t1
    tt = t * (2.0 * r + t)
    an = (PI / 2.0) * tt
    a = l * t + (leg + an)
    return a * w


def vol_hemf(l, t, w, lh):
    return (l * t + lh * t) * w


def sh_vol(k, l, t, r, w, lh):
    if k in (0, 1):
        return vol_arc(l, t, r, w, False)
    if k in (2, 3):
        return vol_arc(l, t, r, w, True)
    if k in (4, 5):
        return vol_u(l, t, r, w)
    if k in (6, 7):
        return vol_hemf(l, t, w, lh)
    if k in (8, 9):
        return vol_arc(l, t, r, w, False) + (lh * t) * w
    if k in (10, 11):
        return vol_u(l, t, r, w) + (lh * t) * w
    if k == 254:
        return (l * t) * w
    return 0.0


def num(tok):
    if tok.startswith('b:'):
        return unbits(int(tok[2:]))
    return float(tok)


if __name__ == '__main__':
    L, W, T, R, LH = 100.0, 50.0, 2.0, 3.0, 10.0
    KLO, KHI = 0.3, 0.5
    a90 = allow(90, R, T, KLO, KHI)
    a180 = allow(180, R, T, KLO, KHI)
    print('allow90', bits(a90[0]), bits(a90[1]), a90)
    print('allow180', bits(a180[0]), bits(a180[1]), a180)
    for k in (0, 2, 4, 6, 8, 10, 254):
        v = sh_vol(k, L, T, R, W, LH)
        print('vol%d' % k, bits(v), v)
    print('legs0', legs(0, L, T, R, LH))
    print('legs4', legs(4, L, T, R, LH))
    print('legs6', legs(6, L, T, R, LH))
    print('legs8', legs(8, L, T, R, LH))
    print('legs10', legs(10, L, T, R, LH))
    print('dev0', developed(0, L, T, R, LH, [a90]))
    print('dev10', developed(10, L, T, R, LH, [a90, a90]))
