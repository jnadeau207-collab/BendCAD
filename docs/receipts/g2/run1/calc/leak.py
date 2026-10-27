import math, sys
sys.path.insert(0, '.')
from size import geo

MU50 = 30.5e-6 * 870.0


def leak(z, m, x, ha, b, A, hs, c, dp=21e6, rj=8.0, n=3000, mu=MU50, ns=3, drained=1, faces=((8.0, 0), (6.0, 0), (6.0, 0), (6.0, 0)), cb=0.025e-3):
    g = geo(z, m, x, b, ha)
    ra, rf, rb = m * z / 2 + m * (ha + x), m * z / 2 - m * (1.25 - x), m * z / 2 * math.cos(math.radians(20))
    pb = math.pi * m * math.cos(math.radians(20))
    aw = math.acos(2 * rb / A)
    rw = A / 2
    V = 2 * math.pi * b * (ra ** 2 - rw ** 2 - pb ** 2 / 12)
    qth = V * 1e-9 * n / 60
    hub = 0.0
    for rjf, dr in faces:
        C = math.pi * hs ** 3 / (6 * mu * math.log(rf / rjf))
        hub += C * dp / 2 if dr else C * dp / 4
    hub += math.pi * 16e-3 * cb ** 3 * (dp / 2) / (12 * mu * 15e-3)
    yrel = pb * math.cos(aw) / 2
    wm = (2 * ra - A) * 1e-3
    mesh = 2 * hs ** 3 * dp * wm / (12 * mu * 2 * yrel * 1e-3)
    smid = m * math.pi / 2 * 1e-3
    trans = 4 * hs ** 3 * dp * ((ra - rf) * 1e-3) / (12 * mu * ns * smid)
    om = 2 * math.pi * n / 60
    sa = g['sa'] * 1e-3
    tip = 2 * (b * 1e-3 * c ** 3 * dp / (12 * mu * ns * sa) - b * 1e-3 * c * om * ra * 1e-3 / 2)
    q = dict(hub=hub, mesh=mesh, trans=trans, tip=tip)
    tot = sum(q.values())
    return V, qth, q, tot, 1 - tot / qth, rf, ra, yrel


if __name__ == '__main__':
    for args in [(12, 1.75, 0.35, 0.88, 35.0, 22.05), (13, 1.75, 0.3, 0.9, 32.0, 23.6), (14, 1.65, 0.25, 0.9, 33.5, 24.6)]:
        for hs in (0.02e-3, 0.025e-3, 0.035e-3):
            V, qth, q, tot, eta, rf, ra, yrel = leak(*args, hs=hs, c=0.035e-3)
            print(args, hs * 1e3, 'V=%.3f rf=%.3f ra=%.3f eta=%.3f' % (V / 1000, rf, ra, eta), {k: round(v * 6e4, 2) for k, v in q.items()})
