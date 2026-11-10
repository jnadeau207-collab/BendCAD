import math

PITCH = {3.0: 0.5, 4.0: 0.7, 5.0: 0.8, 6.0: 1.0, 8.0: 1.0, 10.0: 1.5, 12.0: 1.75}
ES_6G = {3.0: -0.020, 4.0: -0.022, 5.0: -0.024, 8.0: -0.026}
HEAD = {3.0: (5.5, 3.0, 2.5, 1.3), 4.0: (7.0, 4.0, 3.0, 2.0), 5.0: (8.5, 5.0, 4.0, 2.5)}
PER_TURN = 12
OVERLAP = 0.03
SEAM_OFF = math.radians(37.0)


def f(x):
    return repr(float(x))


T30 = math.tan(math.radians(30.0))


def d1(d, p):
    return d - 1.0825317547305483 * p


def d3(d, p):
    return d - 1.2268684878 * p


def tooth(hw0, uc):
    return [(-OVERLAP, -(hw0 + OVERLAP * T30)), (uc, -(hw0 - uc * T30)), (uc, hw0 - uc * T30), (-OVERLAP, hw0 + OVERLAP * T30)]


def ext_tooth(d, p, es):
    hw0 = 0.375 * p + (d1(d, p) - d3(d, p)) / 2.0 * T30
    return d3(d, p) / 2.0 + es / 2.0, tooth(hw0, (d - d3(d, p)) / 2.0)


def int_tooth(d, p, extra=0.02):
    return d1(d, p) / 2.0, tooth(0.375 * p, (d - d1(d, p)) / 2.0 + extra)


def wrap_clear(phase, per_turn):
    for k in range(per_turn):
        a = math.degrees(phase + 2.0 * math.pi * k / per_turn) % 180.0
        if min(a, 180.0 - a) < 2.0:
            return False
    return True


def helix_secs(r_base, z0, length, p, pts, per_turn=PER_TURN, phase=0.0):
    while not wrap_clear(phase, per_turn):
        per_turn += 1
    n = max(2, int(round(length / p * per_turn)) + 1)
    out = []
    q = pts + [pts[0]]
    run = ' '.join(f'(run {f(q[j][0])} {f(q[j][1])} {f(q[j + 1][0])} {f(q[j + 1][1])})' for j in range(len(pts)))
    for i in range(n):
        th = phase + 2.0 * math.pi * (length / p) * i / (n - 1)
        c, s = math.cos(th), math.sin(th)
        o = (r_base * c, r_base * s, z0 + length * i / (n - 1))
        fr = '(frame ' + ' '.join(f(x) for x in (*o, c, s, 0.0, 0.0, 0.0, 1.0, 1.0)) + ')'
        out.append(f'(sec {run} {fr})')
    return ' '.join(out)


def ext_helix(nid, d, z0, length, ic, p=None, datum=None):
    p = p or PITCH[d]
    r, pts = ext_tooth(d, p, ES_6G[d])
    ph = SEAM_OFF + 2.0 * math.pi * (z0 - (z0 if datum is None else datum)) / p
    return f'(node {nid} (skin {helix_secs(r, z0, length, p, pts, phase=ph)}) {ic})'


def int_helix(nid, d, z0, length, ic, p=None):
    p = p or PITCH[d]
    r, pts = int_tooth(d, p)
    return f'(node {nid} (skin {helix_secs(r, z0, length, p, pts)}) {ic})'
