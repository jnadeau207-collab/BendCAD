import math
import sys


def inv(a):
    return math.tan(a) - a


def gear_path(z, m, x=0.0, phase=0.0, backlash=0.0, ha=1.0, nflank=8, alpha=20.0):
    a = math.radians(alpha)
    r = m * z / 2
    rb = r * math.cos(a)
    ra = r + m * (ha + x)
    rf = r - m * (1.25 - x)
    s = m * (math.pi / 2 + 2 * x * math.tan(a)) - backlash
    half = s / (2 * r) + inv(a)
    lo = max(rb, rf)
    radii = ([rf] if rf < rb else []) + [lo + (ra - lo) * k / nflank for k in range(nflank + 1)]
    pts = []
    for t in range(z):
        c = phase + 2 * math.pi * t / z
        side = [(rho, half - (inv(math.acos(rb / rho)) if rho >= rb else 0.0)) for rho in radii]
        pts += [(rho * math.cos(c - h), rho * math.sin(c - h)) for rho, h in side]
        pts += [(rho * math.cos(c + h), rho * math.sin(c + h)) for rho, h in reversed(side)]
    f = lambda v: ('%.9f' % v).rstrip('0').rstrip('.')
    x0, y0 = pts[0]
    return '(path %s %s %s)' % (f(x0), f(y0), ' '.join('(line %s %s)' % (f(px), f(py)) for px, py in pts[1:]))


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('usage: gear.py Z MODULE [SHIFT_X] [PHASE_RAD] [BACKLASH_MM] [ADDENDUM_COEFF] [FLANK_POINTS]')
        sys.exit(2)
    z, m = int(sys.argv[1]), float(sys.argv[2])
    rest = [float(v) for v in sys.argv[3:]]
    keys = ['x', 'phase', 'backlash', 'ha', 'nflank']
    kw = dict(zip(keys, rest))
    if 'nflank' in kw:
        kw['nflank'] = int(kw['nflank'])
    print(gear_path(z, m, **kw))
