import math, sys


def inv(a):
    return math.tan(a) - a


def gear_path(z, m=2.0, alpha=20.0, backlash=0.1, phase=0.0, cx=0.0, cy=0.0, nflank=4, addendum=1.0):
    a = math.radians(alpha)
    r = m * z / 2
    rb = r * math.cos(a)
    ra = r + addendum * m
    rf = r - 1.25 * m
    half = (math.pi * m / 2 - backlash) / (2 * r) + inv(a)
    radii = []
    if rf < rb:
        radii.append(rf)
    lo = max(rb, rf)
    radii += [lo + (ra - lo) * k / nflank for k in range(nflank + 1)]
    pts = []
    for t in range(z):
        c = phase + 2 * math.pi * t / z
        left, right = [], []
        for rho in radii:
            h = half - (inv(math.acos(rb / rho)) if rho >= rb else 0.0)
            right.append((rho, c - h))
            left.append((rho, c + h))
        for rho, th in right:
            pts.append((cx + rho * math.cos(th), cy + rho * math.sin(th)))
        for rho, th in reversed(left):
            pts.append((cx + rho * math.cos(th), cy + rho * math.sin(th)))
    f = lambda v: ('%.6f' % v).rstrip('0').rstrip('.')
    x0, y0 = pts[0]
    return '(path %s %s %s)' % (f(x0), f(y0), ' '.join('(line %s %s)' % (f(x), f(y)) for x, y in pts[1:]))


if __name__ == '__main__':
    z = int(sys.argv[1]); phase = float(sys.argv[2]) if len(sys.argv) > 2 else 0.0
    add = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
    print(gear_path(z, phase=phase, addendum=add))
