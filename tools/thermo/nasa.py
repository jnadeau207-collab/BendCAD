import json
import math
import os

R = 8.314462618
DATA = json.load(open(os.path.join(os.path.dirname(__file__), '..', '..', 'data', 'thermo', 'nasa7.json'), encoding='utf-8'))['species']
AW = {'C': 12.011, 'H': 1.008, 'O': 15.999, 'N': 14.007, 'Ar': 39.948}
AIR = {'N2': 0.78084, 'O2': 0.20946, 'Ar': 0.00934, 'CO2': 0.00036}


def mw(sp):
    return sum(AW[e] * n for e, n in DATA[sp]['composition'].items())


def coef(sp, t):
    d = DATA[sp]
    r = d['ranges']
    return d['data'][0] if t < r[1] or len(d['data']) == 1 else d['data'][1]


def cp_r(sp, t):
    a = coef(sp, t)
    return a[0] + a[1] * t + a[2] * t ** 2 + a[3] * t ** 3 + a[4] * t ** 4


def h_rt(sp, t):
    a = coef(sp, t)
    return a[0] + a[1] * t / 2 + a[2] * t ** 2 / 3 + a[3] * t ** 3 / 4 + a[4] * t ** 4 / 5 + a[5] / t


def s_r(sp, t):
    a = coef(sp, t)
    return a[0] * math.log(t) + a[1] * t + a[2] * t ** 2 / 2 + a[3] * t ** 3 / 3 + a[4] * t ** 4 / 4 + a[6]


class Mix:
    def __init__(self, x):
        s = sum(x.values())
        self.x = {k: v / s for k, v in x.items()}
        self.M = sum(v * mw(k) for k, v in self.x.items()) / 1000.0
        self.r = R / self.M

    def cp(self, t):
        return sum(v * cp_r(k, t) for k, v in self.x.items()) * R / self.M

    def h(self, t):
        return sum(v * h_rt(k, t) for k, v in self.x.items()) * R * t / self.M

    def s0(self, t):
        return sum(v * (s_r(k, t) - (math.log(v) if v > 0 else 0.0)) for k, v in self.x.items()) * R / self.M

    def gamma(self, t):
        c = self.cp(t)
        return c / (c - self.r)

    def t_of_h(self, h, t=1000.0):
        for _ in range(60):
            dt = (h - self.h(t)) / self.cp(t)
            t += dt
            if abs(dt) < 1e-9:
                break
        return t

    def t_of_s(self, s, p, p_ref, t=1000.0):
        for _ in range(60):
            f = self.s0(t) - self.r * math.log(p / p_ref) - s
            dt = -f / (self.cp(t) / t)
            t += dt
            if abs(dt) < 1e-9:
                break
        return t

    def isentropic(self, t1, p1, p2):
        return self.t_of_s(self.s0(t1) - self.r * math.log(p1 / p1), p2, p1, t1 * (p2 / p1) ** (0.28))


def burned(far, fuel='Jet-A(g)'):
    c = DATA[fuel]['composition']
    nc, nh = c.get('C', 0), c.get('H', 0)
    mair = sum(v * mw(k) for k, v in AIR.items())
    nf = far * mair / mw(fuel)
    x = dict(AIR)
    o2 = x['O2'] - nf * (nc + nh / 4.0)
    if o2 < 0:
        raise ValueError('rich mixture: complete combustion needs O2')
    x['O2'] = o2
    x['CO2'] = x.get('CO2', 0.0) + nf * nc
    x['H2O'] = x.get('H2O', 0.0) + nf * nh / 2.0
    return Mix(x)


def air():
    return Mix(AIR)


def fuel_lhv(fuel='Jet-A(g)', t=298.15):
    c = DATA[fuel]['composition']
    nc, nh = c.get('C', 0), c.get('H', 0)
    h = {k: h_rt(k, t) * R * t for k in (fuel, 'O2', 'CO2', 'H2O')}
    return (h[fuel] + (nc + nh / 4.0) * h['O2'] - nc * h['CO2'] - nh / 2.0 * h['H2O']) / mw(fuel) * 1000.0


def stoich_far(fuel='Jet-A(g)'):
    c = DATA[fuel]['composition']
    need_o2 = c.get('C', 0) + c.get('H', 0) / 4.0
    mair = sum(v * mw(k) for k, v in AIR.items())
    return mw(fuel) * AIR['O2'] / (need_o2 * mair)
