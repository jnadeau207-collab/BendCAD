import json
import re
import os
import subprocess
import sys
import time
from fractions import Fraction
import math

from mpmath import mp, mpf, cos, sin, atan2, sqrt, acos, pi

mp.dps = 50

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = os.environ.get('G4_WORK', '/home/jesse/g4')
IC = '(intent create any any any any)'
IA = '(intent add any any any any)'
IR = '(intent remove any any any any)'
IS = '(intent same any any any any)'

SZ = json.load(open(os.path.join(ROOT, 'docs/receipts/g4/run1/calc/sizing.json')))
IMP = SZ['impeller']
R2 = mpf(IMP['d2']) * 500
R1 = mpf(IMP['d1_leading_edge']) * 500
R_THROAT = mpf(round(IMP['d0_eye'] * 2000) / 4)
CONE_T = mpf(2)
SEAL = mpf('1.5')
REYE = R_THROAT + CONE_T + SEAL
B = mpf(round(IMP['b'] * 2000) / 2)
BETA1 = mpf(IMP['beta1_blade_deg']) * pi / 180
BETA2 = mpf(IMP['beta2_blade_deg']) * pi / 180
Z = IMP['z']
TB = mpf(4)
RF = mpf(5)
T_HUB = mpf(8)
T_SHR = mpf(6)
BORE = mpf(14)
R_BOSS = mpf(30)
Z_NOSE = mpf(30)
L_BORE = mpf(62)
COLLAR_T = mpf(5)
COLLAR_L = mpf(18)
R_DISC = R2 + RF + 1


def sn(x):
    return 0.0 if abs(float(x)) < 1e-12 else float(x)


def f2(p):
    return f'{sn(p[0])!r} {sn(p[1])!r}'


def blade_camber(r1, r2, b1, b2):
    R = (r2 * r2 - r1 * r1) / (2 * (r2 * cos(b2) - r1 * cos(b1)))
    rho = sqrt(r1 * r1 + R * R - 2 * r1 * R * cos(b1))
    best = None
    for sgn in (1, -1):
        ang = acos((r1 * r1 + rho * rho - R * R) / (2 * r1 * rho))
        c = (rho * cos(sgn * ang), rho * sin(sgn * ang))
        for sg2 in (1, -1):
            a2 = acos((r2 * r2 + rho * rho - R * R) / (2 * r2 * rho))
            th2 = atan2(c[1], c[0]) - sg2 * a2
            p2 = (r2 * cos(th2), r2 * sin(th2))
            if abs(sqrt((p2[0] - c[0]) ** 2 + (p2[1] - c[1]) ** 2) - R) > mpf(10) ** -30:
                continue
            if th2 < 0 and th2 > -pi:
                phi1 = atan2(-c[1], r1 - c[0])
                phi2 = atan2(p2[1] - c[1], p2[0] - c[0])
                cand = (c, R, phi1, phi2, th2)
                if best is None or abs(th2) < abs(best[4]):
                    best = cand
    return best


def check_angles(c, R, phi, r_expect):
    p = (c[0] + R * cos(phi), c[1] + R * sin(phi))
    r = sqrt(p[0] ** 2 + p[1] ** 2)
    cosb = (r * r + R * R - (c[0] ** 2 + c[1] ** 2)) / (2 * r * R)
    return float(r), float(acos(cosb) * 180 / pi)


def on_circ(c, r, p):
    cx, cy, rr = Fraction(c[0]), Fraction(c[1]), Fraction(r)
    x, y = Fraction(p[0]), Fraction(p[1])
    f = lambda a, b: (a - cx) ** 2 + (b - cy) ** 2 - rr * rr
    if f(x, y) == 0:
        return True
    xs = [Fraction(math.nextafter(p[0], -math.inf)), Fraction(math.nextafter(p[0], math.inf))]
    ys = [Fraction(math.nextafter(p[1], -math.inf)), Fraction(math.nextafter(p[1], math.inf))]
    s0 = f(x, y) > 0
    return any((f(a, b) > 0) != s0 or f(a, b) == 0 for a in xs for b in ys)


def snap(p, circles):
    x0, y0 = float(p[0]), float(p[1])
    best = None
    for i in range(-6, 7):
        for j in range(-6, 7):
            x = x0
            for _ in range(abs(i)):
                x = math.nextafter(x, math.inf if i > 0 else -math.inf)
            y = y0
            for _ in range(abs(j)):
                y = math.nextafter(y, math.inf if j > 0 else -math.inf)
            if all(on_circ(c, r, (x, y)) for c, r in circles):
                d = abs(i) + abs(j)
                if best is None or d < best[0]:
                    best = (d, (x, y))
    if best is None:
        raise SystemExit('no representable point on all circles near %r' % (p,))
    return best[1]


def path_sx(start, segs):
    fl = lambda q: (float(q[0]), float(q[1]))
    cs = [(fl(cen), float(r)) for cen, r, end, d in segs]
    pts = [start] + [x[2] for x in segs]
    n = len(segs)
    snapped = []
    for i in range(n):
        snapped.append(snap(pts[i], [cs[i - 1], cs[i]]))
    out = f'(path {snapped[0][0]!r} {snapped[0][1]!r}'
    for i, (cen, r, end, d) in enumerate(segs):
        e = snapped[(i + 1) % n]
        out += f' (arc {cs[i][0][0]!r} {cs[i][0][1]!r} {cs[i][1]!r} {e[0]!r} {e[1]!r} {d})'
    return out + ')'


def seg_area(start, segs):
    tot = mpf(0)
    a = start
    for cen, r, end, d in segs:
        t0 = atan2(a[1] - cen[1], a[0] - cen[0])
        t1 = atan2(end[1] - cen[1], end[0] - cen[0])
        sw = (t1 - t0) % (2 * pi)
        if d == 'cw':
            sw = sw - 2 * pi
        tot += (cen[0] * (end[1] - a[1]) - cen[1] * (end[0] - a[0])) / 2 + r * r * sw / 2
        a = end
    return tot


def pyth(phi):
    t = tan_half = float(mp.tan(phi / 2))
    best = None
    for n in range(1, 401):
        m = round(t * n)
        err = abs(m / n - t)
        if best is None or err < best[0] - 1e-15:
            best = (err, m, n)
    _, m, n = best
    q = n * n + m * m
    return n * n - m * m, 2 * m * n, q


def grid(x, e=45):
    return Fraction(round(float(x) * 2 ** e), 2 ** e)


def blade_exact(k):
    h = TB / 2
    c, R, phi1, phi2, th2 = blade_camber(R1 + h, R2 - h, BETA1, BETA2)
    rot = 2 * pi * k / Z
    rc = lambda p: (p[0] * cos(rot) - p[1] * sin(rot), p[0] * sin(rot) + p[1] * cos(rot))
    e1s = rc((c[0] + R * cos(phi1), c[1] + R * sin(phi1)))
    pa, ra, qa = pyth(phi1 + rot + pi)
    pb, rb, qb = pyth(phi2 + rot)
    e = 45
    m = round(float(R) * 2 ** e / (qa * qb))
    Rx = Fraction(qa * qb * m, 2 ** e)
    E1 = (grid(e1s[0]), grid(e1s[1]))
    C = (E1[0] + Fraction(qb * m * pa, 2 ** e), E1[1] + Fraction(qb * m * ra, 2 ** e))
    E2 = (C[0] + Fraction(qa * m * pb, 2 ** e), C[1] + Fraction(qa * m * rb, 2 ** e))
    for v in (Rx, *E1, *C, *E2):
        assert Fraction(float(v)) == v, 'not representable'
    assert (C[0] - E1[0]) ** 2 + (C[1] - E1[1]) ** 2 == Rx * Rx
    assert (E2[0] - C[0]) ** 2 + (E2[1] - C[1]) ** 2 == Rx * Rx
    return dict(E1=E1, C=C, E2=E2, R=Rx, d1=(Fraction(pa, qa), Fraction(ra, qa)), d2=(Fraction(pb, qb), Fraction(rb, qb)), sweep=float(phi2 - phi1))


def blade_path(k):
    b = blade_exact(k)
    h = Fraction(TB / 2)
    E1, C, E2, R, d1, d2 = b['E1'], b['C'], b['E2'], b['R'], b['d1'], b['d2']
    s = 1 if b['sweep'] > 0 else -1
    ro, ri = R + h, R - h
    po1 = (E1[0] - h * d1[0], E1[1] - h * d1[1])
    pi1 = (E1[0] + h * d1[0], E1[1] + h * d1[1])
    po2 = (E2[0] + h * d2[0], E2[1] + h * d2[1])
    pi2 = (E2[0] - h * d2[0], E2[1] - h * d2[1])
    d = 'ccw' if s > 0 else 'cw'
    dn = 'cw' if s > 0 else 'ccw'
    segs = [(C, ro, po2, d), (E2, h, pi2, d), (C, ri, pi1, dn), (E1, h, po1, d)]
    start = po1
    tofl = lambda q: (float(q[0]), float(q[1]))
    area = seg_area(tuple(mpf(x) for x in tofl(start)), [(tuple(mpf(x) for x in tofl(cen)), mpf(float(r)), tuple(mpf(x) for x in tofl(en)), dd) for cen, r, en, dd in segs])
    if area < 0:
        pts = [start] + [x[2] for x in segs]
        segs = [(segs[i][0], segs[i][1], pts[i], 'cw' if segs[i][3] == 'ccw' else 'ccw') for i in range(len(segs) - 1, -1, -1)]
    return path_sx(start, segs)


def blade_profile():
    b, r = float(B), float(RF)
    return (f'(region (path -0.5 -1 (line {r} -1) (line {r} 0) (arc {r} {r} {r} 0 {r} cw) (line 0 {b - r}) '
            f'(arc {r} {b - r} {r} {r} {b} cw) (line {r} {b + 1}) (line -0.5 {b + 1}) (line -0.5 -1)))')


def hub_profile():
    r2, th, bo, rb, zn = float(R_DISC), float(T_HUB), float(BORE), float(R_BOSS), float(Z_NOSE)
    lb = float(L_BORE - Z_NOSE)
    f = 6.0
    rn = 24.0
    return (f'(region (path {bo} {-lb} (line {rb} {-lb}) (line {rb} {-th - f}) (arc {rb + f} {-th - f} {f} {rb + f} {-th} cw) '
            f'(line {r2} {-th}) (line {r2} 0) (line {rn + f} 0) (arc {rn + f} {f} {f} {rn} {f} cw) (line {rn} {zn}) (line {bo} {zn}) (line {bo} {-lb})))')


def shroud_profile():
    r2, b, t, re = float(R_DISC), float(B), float(T_SHR), float(REYE)
    ct, cl, f = float(COLLAR_T), float(COLLAR_L), 6.0
    return (f'(region (path {re} {b} (line {r2} {b}) (line {r2} {b + t}) (line {re + ct + f} {b + t}) '
            f'(arc {re + ct + f} {b + t + f} {f} {re + ct} {b + t + f} cw) (line {re + ct} {b + t + cl}) (line {re} {b + t + cl}) (line {re} {b})))')


KEY_W = 8.0
KEY_Y1 = 17.3
KEY_L = float(L_BORE)
BAL_R = 5.0
BAL_RC = 180.0
VOL = SZ['volute']
B_VOL = mpf(125)
Z_BACK = mpf(-20)
Z_FRONT = Z_BACK + B_VOL
T_SHEET = mpf(3)
Y_OUT = mpf(640)
R_TONGUE = mpf(10)
N_ARCS = 16
R_HOLE_BACK = mpf(40)
R_BELL = mpf(30)
Z_CONE_TIP = mpf(67)
R_CONE_FL = mpf(200)
T_CONE_FL = mpf(3)
R_CONE_HOLE = mpf(155)
T_RING = mpf(8)
R_RING = mpf(250)
R_FRONT_OPEN = mpf(232)
PCD_FRONT = mpf(241)
N_FRONT = 12
T_FPLATE = mpf(8)
N_CONE_BOLT = 8
R_CONE_PCD = mpf(177.5)


def loop_fix(start, segs):
    pts = [start] + [sg[-1] if sg[0] == 'l' else sg[3] for sg in segs]
    n = len(segs)
    circ = [((float(sg[1][0]), float(sg[1][1])), float(sg[2])) if sg[0] == 'a' else None for sg in segs]
    snapped = [None] * n
    for i in range(n):
        cs = [c for c in (circ[i - 1], circ[i]) if c is not None]
        if not cs:
            snapped[i] = (float(pts[i][0]), float(pts[i][1]))
            continue
        try:
            snapped[i] = snap(pts[i], cs)
        except SystemExit:
            if circ[i] is None or circ[i - 1] is None:
                raise
            (cx, cy), r = circ[i]
            for k in range(1, 400):
                for sgn in (1, -1):
                    rr = r
                    for _ in range(k):
                        rr = math.nextafter(rr, math.inf if sgn > 0 else -math.inf)
                    try:
                        snapped[i] = snap(pts[i], [circ[i - 1], ((cx, cy), rr)])
                        circ[i] = ((cx, cy), rr)
                        break
                    except SystemExit:
                        pass
                if snapped[i] is not None:
                    break
            if snapped[i] is None:
                raise SystemExit('no representable junction near %r' % (pts[i],))
    for i in range(n):
        for c in (circ[i - 1], circ[i]):
            if c is not None and not on_circ(c[0], c[1], snapped[i]):
                raise SystemExit('junction %d left its circle after nudging' % i)
    return snapped, circ


def loop_exact(start, segs):
    snapped, circ = loop_fix(start, segs)
    n = len(segs)
    out = []
    for i, sg in enumerate(segs):
        e = snapped[(i + 1) % n]
        out.append(('l', e) if sg[0] == 'l' else ('a', circ[i][0], circ[i][1], e, sg[4]))
    return snapped[0], out


def loop_sx(start, segs):
    snapped, circ = loop_fix(start, segs)
    n = len(segs)
    out = f'(path {snapped[0][0]!r} {snapped[0][1]!r}'
    for i, sg in enumerate(segs):
        e = snapped[(i + 1) % n]
        if sg[0] == 'l':
            out += f' (line {e[0]!r} {e[1]!r})'
        else:
            out += f' (arc {circ[i][0][0]!r} {circ[i][0][1]!r} {circ[i][1]!r} {e[0]!r} {e[1]!r} {sg[4]})'
    return out + ')'


def spiral_fit():
    r3 = mpf(VOL['r3']) * 1000
    a = mpf(SZ['inputs']['q_m3s']) / (2 * pi * B_VOL / 1000 * mpf(VOL['k_cu_r']))
    sp = lambda th: (r3 * mp.e ** (a * th) * cos(th), r3 * mp.e ** (a * th) * sin(th))
    tan_at = lambda th: (a * cos(th) - sin(th), a * sin(th) + cos(th))
    arcs = []
    p = sp(mpf(0))
    t = tan_at(mpf(0))
    tl = sqrt(t[0] ** 2 + t[1] ** 2)
    t = (t[0] / tl, t[1] / tl)
    dev = mpf(0)
    for k in range(N_ARCS):
        e = sp(2 * pi * (k + 1) / N_ARCS)
        nrm = (-t[1], t[0])
        d = (e[0] - p[0], e[1] - p[1])
        rho = (d[0] ** 2 + d[1] ** 2) / (2 * (d[0] * nrm[0] + d[1] * nrm[1]))
        c = (p[0] + rho * nrm[0], p[1] + rho * nrm[1])
        arcs.append((c, rho, p, e))
        for j in range(1, 20):
            a0 = atan2(p[1] - c[1], p[0] - c[0])
            a1 = atan2(e[1] - c[1], e[0] - c[0])
            sw = (a1 - a0) % (2 * pi)
            q = (c[0] + rho * cos(a0 + sw * j / 20), c[1] + rho * sin(a0 + sw * j / 20))
            th = atan2(q[1], q[0]) % (2 * pi)
            if k == N_ARCS - 1 and th < pi:
                th += 2 * pi
            rq = sqrt(q[0] ** 2 + q[1] ** 2)
            dev = max(dev, abs(rq - r3 * mp.e ** (a * th)))
        ne = ((e[0] - c[0]) / rho, (e[1] - c[1]) / rho)
        t = (-ne[1], ne[0])
        p = e
    return dict(r3=r3, a=a, arcs=arcs, end_tangent=t, max_dev=dev)


def casing_contours():
    f = spiral_fit()
    arcs, t_end = f['arcs'], f['end_tangent']
    p0 = arcs[0][2]
    t0 = (arcs[0][2][0] - arcs[0][0][0], arcs[0][2][1] - arcs[0][0][1])
    n0 = (t0[0] / arcs[0][1], t0[1] / arcs[0][1])
    tc = (p0[0] + R_TONGUE * n0[0], p0[1] + R_TONGUE * n0[1])
    xd = tc[0] + R_TONGUE
    pe = arcs[-1][3]
    qo = (pe[0] + t_end[0] / t_end[1] * (Y_OUT - pe[1]), Y_OUT)

    def contour(off):
        segs = []
        for c, rho, a0, e in arcs:
            ue = ((e[0] - c[0]) / rho, (e[1] - c[1]) / rho)
            segs.append(('a', c, rho + off, (c[0] + (rho + off) * ue[0], c[1] + (rho + off) * ue[1]), 'ccw'))
        pe_o = segs[-1][3]
        lx = pe_o[0]
        segs.append(('l', (lx, Y_OUT)))
        segs.append(('l', (xd - off, Y_OUT)))
        segs.append(('l', (xd - off, tc[1])))
        p0_o = (arcs[0][0][0] + (arcs[0][1] + off) * n0[0], arcs[0][0][1] + (arcs[0][1] + off) * n0[1])
        segs.append(('a', tc, R_TONGUE - off, p0_o, 'cw'))
        return p0_o, segs

    return f, contour(mpf(0)), contour(T_SHEET), dict(p0=p0, tc=tc, xd=xd, qo=qo, pe=pe)


def rev_segs(start, segs):
    pts = [start] + [sg[-1] if sg[0] == 'l' else sg[3] for sg in segs]
    out = []
    for i in range(len(segs) - 1, -1, -1):
        sg = segs[i]
        if sg[0] == 'l':
            out.append(('l', pts[i]))
        else:
            out.append(('a', sg[1], sg[2], pts[i], 'cw' if sg[4] == 'ccw' else 'ccw'))
    return pts[-1], out


def casing_edits():
    f, inn, outr, key = casing_contours()
    ps_i, si = loop_exact(*inn)
    ps_o, so = loop_exact(*outr)
    n = N_ARCS
    loop = []
    start = so[n][1]
    loop.append(('l', so[n - 1][3]))
    for k in range(n - 1, -1, -1):
        c, r, e, d = so[k][1], so[k][2], so[k][3], so[k][4]
        prev = so[k - 1][3] if k > 0 else ps_o
        loop.append(('a', c, r, prev, 'cw'))
    loop.append(('a', so[n + 3][1], so[n + 3][2], so[n + 2][1], 'ccw'))
    loop.append(('l', so[n + 1][1]))
    loop.append(('l', si[n + 1][1]))
    loop.append(('l', si[n + 2][1]))
    loop.append(('a', si[n + 3][1], si[n + 3][2], ps_i, 'cw'))
    for k in range(n):
        loop.append(si[k])
    loop.append(('l', si[n][1]))
    loop.append(('l', start))
    band = loop_sx(start, loop)
    outer = loop_sx(ps_o, so)
    zb, zf, t = float(Z_BACK), float(Z_FRONT), float(T_SHEET)
    back = f'(region {outer} {circ_sx(R_HOLE_BACK)} {holes_sx(pcd(6, 130.0, float(pi) / 6), 5.5)})'
    fpts = pcd(N_FRONT, PCD_FRONT, float(pi) / N_FRONT)
    front = f'(region {outer} {circ_sx(R_FRONT_OPEN)} {holes_sx(fpts, 3.4)})'
    ring = f'(region {circ_sx(R_RING)} {circ_sx(R_FRONT_OPEN)} {holes_sx(fpts, 3.4)})'
    xi, xo = float(key['xd'] - T_SHEET), float(so[n][1][0])
    fx0, fx1, fz0, fz1 = xi - 45, xo + 45, zb - t - 45, zf + t + 45
    fh = [(fx0 + 20, fz0 + 20 + k * (fz1 - fz0 - 40) / 3) for k in range(4)] + [(fx1 - 20, fz0 + 20 + k * (fz1 - fz0 - 40) / 3) for k in range(4)]
    fh += [(fx0 + 20 + k * (fx1 - fx0 - 40) / 4, fz) for k in range(1, 4) for fz in (fz0 + 20, fz1 - 20)]
    frame = (f'(region (path {fx0!r} {fz0!r} (line {fx1!r} {fz0!r}) (line {fx1!r} {fz1!r}) (line {fx0!r} {fz1!r}) (line {fx0!r} {fz0!r})) '
             f'(path {xi!r} {zb - t!r} (line {xo!r} {zb - t!r}) (line {xo!r} {zf + t!r}) (line {xi!r} {zf + t!r}) (line {xi!r} {zb - t!r})) '
             f'{holes_sx(fh, 5.0)})')
    yo = float(Y_OUT)
    e = [f'(node 2001 (prism {zb} {zf} (region {band})) {IC})',
         f'(node 2002 (prism {zb - t} {zb} {back}) {IC})',
         f'(node 2003 (prism {zf} {zf + t} {front}) {IC})',
         f'(node 2006 (prism {zf - float(T_RING)} {zf} {ring}) {IC})',
         f'(node 2004 (union 2001 2002) {IA})', f'(node 2005 (union 2003 2006) {IA})', f'(node 2007 (union 2004 2005) {IA})',
         f'(node 2009 (prism {-yo - 2} {-yo + 8} {frame}) {IC})', f'(node 2008 (move 2009 0 0 0 4) {IS})', f'(node 2 (union 2007 2008) {IA})']
    key['frame'] = frame
    key['flange_holes'] = fh
    return e, f, key


def circ_sx(r, cx=0.0, cy=0.0):
    return f'(circle {float(cx)!r} {float(cy)!r} {float(r)!r})'


def pcd(n, r, a0=0.0):
    return [(float(r * cos(2 * pi * k / n + a0)), float(r * sin(2 * pi * k / n + a0))) for k in range(n)]


def rnd(x, q=4096):
    return round(float(x) * q) / q


def holes_sx(pts, r):
    return ' '.join(circ_sx(r, x, y) for x, y in pts)


def cone_edits():
    rt, t, rb = float(R_THROAT), float(CONE_T), float(R_BELL)
    zt = float(Z_FRONT + T_SHEET + T_FPLATE)
    cz = zt - rb + t
    ro, tf = float(R_CONE_FL), float(T_CONE_FL)
    prof = (f'(region (path {rt} {float(Z_CONE_TIP)} (line {rt + t} {float(Z_CONE_TIP)}) (line {rt + t} {cz}) '
            f'(arc {rt + rb} {cz} {rb - t} {rt + rb} {zt} cw) (line {ro} {zt}) (line {ro} {zt + tf}) (line {rt + rb} {zt + tf}) '
            f'(line {rt + rb} {cz + rb}) (arc {rt + rb} {cz} {rb} {rt} {cz} ccw) (line {rt} {float(Z_CONE_TIP)})))')
    e = [f'(node 3001 (revolve {prof}) {IC})']
    prev = 3001
    for j, (x, y) in enumerate(pcd(N_CONE_BOLT, R_CONE_PCD, float(pi) / N_CONE_BOLT)):
        e.append(f'(node {3010 + j} (prism {zt - 1} {zt + tf + 1} (region {circ_sx(3.3, x, y)})) {IC})')
        nid = 3 if j == N_CONE_BOLT - 1 else 3020 + j
        e.append(f'(node {nid} (difference {prev} {3010 + j}) {IR})')
        prev = nid
    return e


def front_plate_edits():
    z0 = float(Z_FRONT + T_SHEET)
    reg = (f'(region {circ_sx(R_RING)} {circ_sx(R_CONE_HOLE)} {holes_sx(pcd(N_FRONT, PCD_FRONT, float(pi) / N_FRONT), 4.5)} '
           f'{holes_sx(pcd(N_CONE_BOLT, R_CONE_PCD, float(pi) / N_CONE_BOLT), 2.5)})')
    return [f'(node 13 (prism {z0} {z0 + float(T_FPLATE)} {reg}) {IC})']


def pedestal_edits():
    zb, zf = -38.0, float(Z_BACK - T_SHEET)
    m12 = pcd(4, 107.5, float(pi) / 4)
    m10 = pcd(6, 130.0, float(pi) / 6)
    plate = (f'(region (path -160 -505 (line 160 -505) (line 160 160) (line -160 160) (line -160 -505)) {circ_sx(35)} '
             f'{holes_sx(m12, 5.1)} {holes_sx(m10, 4.25)})')
    tri = '(region (path 38 -505 (line 280 -505) (line 38 -200) (line 38 -505)))'
    return [f'(node 4001 (prism {zb} {zf} {plate}) {IC})',
            f'(node 4002 (pocket 4001 (face 4001 0 bottom) 4.5 (region {circ_sx(90.0175)})) {IR})',
            f'(node 4003 (prism -300 {zf} (region (path -200 -520 (line 200 -520) (line 200 -505) (line -200 -505) (line -200 -520)))) {IC})',
            f'(node 4004 (union 4002 4003) {IA})',
            f'(node 4015 (prism -122 -110 {tri}) {IC})', f'(node 4005 (move 4015 0 0 0 5) {IS})',
            f'(node 4016 (prism 110 122 {tri}) {IC})', f'(node 4006 (move 4016 0 0 0 5) {IS})',
            f'(node 4007 (union 4004 4005) {IA})', f'(node 4 (union 4007 4006) {IA})']


def motor_edits():
    fl = f'(region {circ_sx(125)} {holes_sx(pcd(4, 107.5, float(pi) / 4), 7.5)})'
    return [f'(node 5001 (prism -49 -38 {fl}) {IC})',
            f'(node 5002 (prism -38 -34 (region {circ_sx(90)})) {IC})', f'(node 5003 (union 5001 5002) {IA})',
            f'(node 5015 (prism -64 -49 (region {circ_sx(95)})) {IC})', f'(node 5016 (union 5003 5015) {IA})',
            f'(node 5004 (prism -433 -64 (region {circ_sx(112.5)})) {IC})', f'(node 5005 (union 5016 5004) {IA})',
            f'(node 5006 (prism -34 -32 (region {circ_sx(17.5)})) {IC})', f'(node 5007 (union 5005 5006) {IA})',
            f'(node 5008 (prism -32 28 (region {circ_sx(14)})) {IC})', f'(node 5009 (union 5007 5008) {IA})',
            f'(node 5010 (prism -300 -100 (region (path -75 100 (line 75 100) (line 75 185) (line -75 185) (line -75 100)))) {IC})',
            f'(node 5011 (union 5009 5010) {IA})',
            f'(node 5012 (pocket 5011 (face 5008 0 top) 22 (region {circ_sx(4.25)})) {IR})',
            f'(node 5014 (box 8 10 50) {IC})', f'(node 5013 (move 5014 -4 10 -30 0) {IS})',
            f'(node 5 (difference 5012 5013) {IR})']


def key_edits():
    return [f'(node 6001 (box 8 7 50) {IC})', f'(node 6 (move 6001 -4 10 -30 0) {IS})']


def washer_edits():
    return [f'(node 7 (prism 0 6 (region {circ_sx(22)} {circ_sx(5.5)})) {IC})']


def screw_edits(nid, d, k_head, d_head, length, s_hex, t_hex):
    r = s_hex / math.sqrt(3)
    hx = ' '.join(f'(line {r * math.cos(2 * math.pi * j / 6)!r} {r * math.sin(2 * math.pi * j / 6)!r})' for j in range(1, 6))
    return [f'(node {nid}1 (prism 0 {k_head} (region {circ_sx(d_head / 2)})) {IC})',
            f'(node {nid}2 (pad {nid}1 (face {nid}1 0 bottom) {length} (region {circ_sx(d / 2)})) {IA})',
            f'(node {nid} (pocket {nid}2 (face {nid}1 0 top) {t_hex} (region (path {r!r} 0 {hx}))) {IR})']


def hexbolt_edits(nid, d, k_head, s_head, length):
    r = s_head / math.sqrt(3)
    hx = ' '.join(f'(line {r * math.cos(2 * math.pi * j / 6)!r} {r * math.sin(2 * math.pi * j / 6)!r})' for j in range(1, 6))
    return [f'(node {nid}1 (prism 0 {k_head} (region (path {r!r} 0 {hx}))) {IC})',
            f'(node {nid} (pad {nid}1 (face {nid}1 0 bottom) {length} (region {circ_sx(d / 2)})) {IA})']


def impeller_edits(nblades):
    e = [f'(node 1001 (revolve {hub_profile()}) {IC})']
    prev = 1001
    for k in range(nblades):
        e.append(f'(node {1100 + k} (sweep (wall {blade_path(k)}) {blade_profile()}) {IC})')
        e.append(f'(node {1200 + k} (union {prev} {1100 + k}) {IA})')
        prev = 1200 + k
    e.append(f'(node 1002 (revolve {shroud_profile()}) {IC})')
    e.append(f'(node 1003 (union {prev} 1002) {IA})')
    e.append(f'(node 1005 (box 8 7.3 80) {IC})')
    e.append(f'(node 1004 (move 1005 -4 10 -40 0) {IS})')
    e.append(f'(node 1008 (difference 1003 1004) {IR})')
    rc, dc = balance_pocket()
    e.append(f'(node 1009 (prism {-float(T_HUB) - 1} {-float(T_HUB) + float(dc)!r} (region {circ_sx(BAL_R, 0.0, -rc)})) {IC})')
    e.append(f'(node 1 (difference 1008 1009) {IR})')
    return e


def keyway_moment():
    f = lambda x: (KEY_Y1 ** 2 - (BORE ** 2 - x * x)) / 2
    g = lambda x: KEY_Y1 - math.sqrt(BORE ** 2 - x * x)
    n = 20000
    xs = [-KEY_W / 2 + KEY_W * (k + 0.5) / n for k in range(n)]
    area = sum(g(x) for x in xs) * KEY_W / n
    my = sum(f(x) for x in xs) * KEY_W / n
    return area * KEY_L, my * KEY_L


def balance_pocket():
    v, m = keyway_moment()
    rc = BAL_RC
    return rc, float(m) / rc / (math.pi * BAL_R ** 2)


def hexbolt_up_edits(nid, d, k_head, s_head, length):
    r = s_head / math.sqrt(3)
    hx = ' '.join(f'(line {r * math.cos(2 * math.pi * j / 6)!r} {r * math.sin(2 * math.pi * j / 6)!r})' for j in range(1, 6))
    return [f'(node {nid}1 (prism {-k_head} 0 (region (path {r!r} 0 {hx}))) {IC})',
            f'(node {nid} (pad {nid}1 (face {nid}1 0 top) {length} (region {circ_sx(d / 2)})) {IA})']


def assembly():
    inst, mates = [], []
    k = [0]

    def add(name, node, x, y, z, mate=None):
        inst.append(f'(inst {name} {node} {x!r} {y!r} {z!r} 0)')
        if mate is not None:
            k[0] += 1
            mates.append(mate(k[0], name))

    co = lambda pa, a, pb, b: (lambda i, n: f'(coinc {i} {n} {a[0]!r} {a[1]!r} {a[2]!r} {pb} {b[0]!r} {b[1]!r} {b[2]!r})')
    add('pedestal', 4, 0.0, 0.0, 0.0)
    k[0] += 1
    mates.append(f'(fix {k[0]} pedestal)')
    add('motor', 5, 0.0, 0.0, 0.0, co('motor', (0.0, 0.0, -38.0), 'pedestal', (0.0, 0.0, -38.0)))
    add('casing', 2, 0.0, 0.0, 0.0, co('casing', (0.0, 0.0, -23.0), 'pedestal', (0.0, 0.0, -23.0)))
    add('impeller', 1, 0.0, 0.0, 0.0, co('impeller', (0.0, 0.0, -32.0), 'motor', (0.0, 0.0, -32.0)))
    add('key', 6, 0.0, 0.0, 0.0, co('key', (4.0, 0.0, 0.0), 'motor', (0.0, 10.0, -30.0)))
    add('washer', 7, 0.0, 0.0, 30.0, co('washer', (0.0, 0.0, 0.0), 'impeller', (0.0, 0.0, 30.0)))
    add('screw_m10', 8, 0.0, 0.0, 36.0, co('screw_m10', (0.0, 0.0, 0.0), 'washer', (0.0, 0.0, 6.0)))
    zf = float(Z_FRONT + T_SHEET)
    add('front_plate', 13, 0.0, 0.0, 0.0, co('front_plate', (0.0, 0.0, zf), 'casing', (0.0, 0.0, zf)))
    add('cone', 3, 0.0, 0.0, 0.0, co('cone', (0.0, 0.0, zf + float(T_FPLATE)), 'front_plate', (0.0, 0.0, zf + float(T_FPLATE))))
    add('gasket', 12, 0.0, 0.0, 0.0, co('gasket', (0.0, 0.0, -float(Y_OUT) - 2), 'casing', (0.0, float(Y_OUT) + 2, 0.0)))
    zc = zf + float(T_FPLATE) + float(T_CONE_FL)
    for j, (x, y) in enumerate(pcd(N_CONE_BOLT, R_CONE_PCD, float(pi) / N_CONE_BOLT)):
        add(f'screw_m6_{j}', 9, x, y, zc, co(f'screw_m6_{j}', (0.0, 0.0, 0.0), 'cone', (x, y, zc)))
    for j, (x, y) in enumerate(pcd(N_FRONT, PCD_FRONT, float(pi) / N_FRONT)):
        add(f'bolt_m8_{j}', 14, x, y, zf + float(T_FPLATE), co(f'bolt_m8_{j}', (0.0, 0.0, 0.0), 'front_plate', (x, y, zf + float(T_FPLATE))))
    for j, (x, y) in enumerate(pcd(6, 130.0, float(pi) / 6)):
        add(f'bolt_m10_{j}', 10, x, y, float(Z_BACK), co(f'bolt_m10_{j}', (0.0, 0.0, 0.0), 'casing', (x, y, float(Z_BACK))))
    for j, (x, y) in enumerate(pcd(4, 107.5, float(pi) / 4)):
        add(f'bolt_m12_{j}', 11, x, y, -49.0, co(f'bolt_m12_{j}', (0.0, 0.0, 0.0), 'motor', (x, y, -49.0)))
    return '(assembly ' + ' '.join(inst + mates) + ')'


MATERIALS = [
    (1, 'EN-AW-6082-T6', 2700, 2.34e-5, 70000, 0.3),
    (2, 'S235JR', 7850, 1.2e-5, 210000, 0.3),
    (3, 'DC01', 7850, 1.2e-5, 210000, 0.3),
    (4, 'S235JR', 7850, 1.2e-5, 210000, 0.3),
    (6, 'C45', 7850, 1.15e-5, 210000, 0.3),
    (7, 'C45', 7850, 1.15e-5, 210000, 0.3),
    (8, 'ISO898-1-12.9', 7850, 1.15e-5, 210000, 0.3),
    (9, 'ISO898-1-8.8', 7850, 1.15e-5, 210000, 0.3),
    (10, 'ISO898-1-8.8', 7850, 1.15e-5, 210000, 0.3),
    (11, 'ISO898-1-8.8', 7850, 1.15e-5, 210000, 0.3),
    (12, 'EPDM-70', 1150, 1.6e-4, 7, 0.49),
    (13, 'S235JR', 7850, 1.2e-5, 210000, 0.3),
    (14, 'ISO898-1-8.8', 7850, 1.15e-5, 210000, 0.3),
]


def parts(nblades=None):
    e, f, key = casing_edits()
    gasket = [f"(node 12001 (prism {-float(Y_OUT) - 5} {-float(Y_OUT) - 2} {key['frame']}) {IC})", f"(node 12 (move 12001 0 0 0 4) {IS})"]
    return [('impeller', impeller_edits(nblades or Z)), ('casing', e), ('cone', cone_edits()), ('front_plate', front_plate_edits()),
            ('pedestal', pedestal_edits()), ('motor', motor_edits()), ('key', key_edits()), ('washer', washer_edits()),
            ('screw_m10x25', screw_edits(8, 10, 10, 16, 25, 8, 5.5)), ('screw_m6x12', screw_edits(9, 6, 6, 10, 12, 5, 3.5)),
            ('bolt_m10x16', hexbolt_edits(10, 10, 6.4, 16, 16)), ('bolt_m12x25', hexbolt_up_edits(11, 12, 7.5, 18, 25)),
            ('gasket', gasket), ('bolt_m8x20', hexbolt_edits(14, 8, 5.3, 13, 20))]


def threads():
    zf, t = float(Z_FRONT), float(T_SHEET)
    zp = zf + t
    out = []
    for j in range(N_FRONT):
        out.append(f'(thread 2 front_tap{j} n2003.c{j + 2}.wall.0.0 M8 6H {zf!r} {zp!r})')
        out.append(f'(thread 2 ring_tap{j} n2006.c{j + 2}.wall.0.0 M8 6H {zf - float(T_RING)!r} {zf!r})')
    for j in range(N_CONE_BOLT):
        out.append(f'(thread 13 cone_tap{j} n13.c{j + 2 + N_FRONT}.wall.0.0 M6 6H {zp!r} {zp + float(T_FPLATE)!r})')
    zb = float(Z_BACK - T_SHEET)
    for j in range(4):
        out.append(f'(thread 4 motor_tap{j} n4001.c{j + 2}.wall.0.0 M12 6H -38.0 {zb!r})')
    for j in range(6):
        out.append(f'(thread 4 casing_tap{j} n4001.c{j + 6}.wall.0.0 M10 6H -38.0 {zb!r})')
    return out


def materials():
    return [f'(material {n} {g} {rho} {cte!r} {e} {nu})' for n, g, rho, cte, e, nu in MATERIALS]


def master_edits():
    e = []
    for tag, edits in parts():
        e += edits
    ids = [int(m) for x in e for m in re.findall(r'^\(node (\d+) ', x)]
    if len(ids) != len(set(ids)):
        raise SystemExit('duplicate node ids %r' % sorted({i for i in ids if ids.count(i) > 1}))
    return e + materials() + threads()


PART_NODES = [('impeller', 1), ('casing', 2), ('cone', 3), ('pedestal', 4), ('motor', 5), ('key', 6), ('washer', 7),
              ('screw_m10x25', 8), ('screw_m6x12', 9), ('bolt_m10x16', 10), ('bolt_m12x25', 11), ('gasket', 12),
              ('front_plate', 13), ('bolt_m8x20', 14)]


def analyses():
    rpm = 2900.0
    jobs = []
    for name, n in PART_NODES:
        jobs.append(('mass_%s' % name, ['mass', str(n)]))
    jobs.append(('balance', ['balance', '1', '0', '0', '0', '0', '0', '1', repr(rpm), '2.5']))
    jobs.append(('threads_casing', ['threads', '2']))
    jobs.append(('threads_pedestal', ['threads', '4']))
    jobs.append(('threads_front_plate', ['threads', '13']))
    for name, n in PART_NODES:
        jobs.append(('step_%s' % name, ['step', str(n), '%s/export/%s.stp' % (WORK, name)]))
    jobs.append(('step_assembly', ['asm', 'step', '%s/export/blower_assembly.stp' % WORK, assembly()]))
    jobs.append(('asm_solve', ['asm', 'solve', assembly()]))
    for name, n in PART_NODES:
        jobs.append(('stl_%s' % name, ['stl', str(n), '%s/export/%s.stl' % (WORK, name), '3']))
    jobs.append(('clear_impeller_cone', ['clearance', '1', '3']))
    jobs.append(('clear_impeller_casing', ['clearance', '1', '2']))
    jobs.append(('clear_impeller_front_plate', ['clearance', '1', '13']))
    jobs.append(('wall_casing', ['wall', '2']))
    jobs.append(('wall_impeller', ['wall', '1']))
    jobs.append(('machine_impeller', ['machine', '1', '10', '30', '25', '60', '5', '4']))
    jobs.append(('asm_interf', ['asm', 'interf', assembly()]))
    for tag, spec in rotor_specs():
        jobs.append(('rotor_%s' % tag, ['rotor', spec]))
    jobs.append(('modes_probe_h8', ['modes', '1', '6', '8', '0', '0', '0', '0', '0', '1', '14.5']))
    return jobs


MOTOR_KG = 42.0
IMP_M = 6.83364
IMP_JD = 37043314704.0 * 2.7e-6
IMP_ZCG = 19.391
Z_DE = -70.0


def rotor_specs():
    st = '210000 0.3 7850'
    out = []
    for span in (200.0, 330.0):
        for kb in (2e4, 2e5):
            for core in (6.0, 12.0):
                segs = [(span / 2, 30), (span / 2, 30), (-34.0 - Z_DE, 35), (2.0, 35), (IMP_ZCG + 32.0, 28), (28.0 - IMP_ZCG, 28)]
                x_imp = span + (-34.0 - Z_DE) + 2.0 + IMP_ZCG + 32.0
                spec = '(rotor %s (disc %r %r 0) (disc %r %r %r) (brg 0 %r 0) (brg %r %r 0) (n 8) (modes 2))' % (
                    ' '.join('(seg %r %d 0 %s)' % (l, d, st) for l, d in segs), span / 2, core, x_imp, IMP_M, IMP_JD, kb, span, kb)
                out.append(('s%d_k%d_c%d' % (span, kb, core), spec))
    return out


def part_boxes():
    txt = open(os.path.join(ROOT, 'docs/receipts/g4/run1/q/master_apply.txt')).read()
    out = {}
    for name, n in PART_NODES:
        m = re.search(r'^node %d: ok .*?bbox=\[([^,]+), ([^\]]+)\]x\[([^,]+), ([^\]]+)\]x\[([^,]+), ([^\]]+)\]' % n, txt, re.M)
        out[name] = [float(m.group(k)) for k in range(1, 7)]
    return out


def tip_range():
    rs = [math.hypot(float(e['E2'][0]), float(e['E2'][1])) + float(TB / 2) for e in map(blade_exact, range(Z))]
    return [min(rs), max(rs)]


def casing_contours_claims():
    e, f, key = casing_edits()
    bx = part_boxes()
    lo, hi = [1e9] * 3, [-1e9] * 3
    for m in re.finditer(r'\(inst (\S+) (\d+) (\S+) (\S+) (\S+) 0\)', assembly()):
        n = int(m.group(2))
        b = bx[[k for k, v in PART_NODES if v == n][0]]
        t = [float(m.group(3)), float(m.group(4)), float(m.group(5))]
        for a in range(3):
            lo[a] = min(lo[a], b[2 * a] + t[a])
            hi[a] = max(hi[a], b[2 * a + 1] + t[a])
    tc = [float(v) for v in key['tc']]
    r_tip = math.hypot(*tc) - float(R_TONGUE)
    h = float(TB) / 2
    claims = dict(z=Z, beta_deg=[float(SZ['impeller']['beta1_blade_deg']), float(SZ['impeller']['beta2_blade_deg'])],
                  r_le=float(R1) + h, r_te=float(R2) - h, d2_mm=2 * float(R2), tip_radius_mm=tip_range(), disc_od_mm=2 * float(R_DISC),
                  envelope=[lo, hi], outlet_hole_r=5.0, outlet_holes_xz=[[float(x), float(z)] for x, z in key['flange_holes']],
                  front_tap_r=3.4, front_taps=N_FRONT, front_pcd=2 * float(PCD_FRONT),
                  collar_top_z=float(B + T_SHR + COLLAR_L), cone_radial_mm=float(REYE - R_THROAT - CONE_T), cone_overlap_min_mm=10.0,
                  tongue_box=[[tc[0] - 25, tc[1] - 25, float(Z_BACK)], [tc[0] + 25, tc[1] + 25, float(Z_FRONT)]],
                  tongue_clearance_mm=r_tip - float(R_DISC),
                  back_box=[[-230.0, -230.0, float(Z_BACK - T_SHEET)], [230.0, 230.0, float(Z_BACK)]],
                  back_clearance_mm=min(float(R_HOLE_BACK - R_BOSS), float(Z_BACK) * -1 - float(T_HUB)),
                  allowed_overlaps=[['bolt_m8', 'casing'], ['screw_m6', 'front_plate'], ['bolt_m12', 'pedestal'],
                                    ['bolt_m10', 'pedestal'], ['motor', 'screw_m10']])
    open(os.path.join(ROOT, 'docs/receipts/g4/run1/calc/claims.json'), 'w').write(json.dumps(claims, indent=1))
    return claims, f, key


def wsl(*args, timeout=86400):
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    env = dict(os.environ, MSYS_NO_PATHCONV='1', BEND_NO_TELEMETRY='1')
    t = time.time()
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout, env=env)
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args, timeout=86400):
    return wsl(BIN, f'{WORK}/{design}', *args, timeout=timeout)


def split_batch(q, jobs, stream):
    out = wsl('cat', stream)[0]
    open(os.path.join(q, os.path.basename(stream).replace('.out', '_raw.txt')), 'w', newline=chr(10)).write(out)
    heads = re.findall(r'^== (.*)$', out, flags=re.M)
    parts_out = re.split(r'^== .*$', out, flags=re.M)[1:]
    for (t, a), h, body in zip(jobs, heads, parts_out):
        if h.split()[0] != a[0]:
            raise SystemExit('batch section %r does not match job %s' % (h[:80], t))
        open(os.path.join(q, t + '.txt'), 'w', newline=chr(10)).write('$ %s%s%s' % (' '.join(x[:200] for x in a), chr(10), body.strip() + chr(10)))
        print(t, body.strip().splitlines()[-1][:160] if body.strip() else '', flush=True)
    print('sections', len(parts_out), 'jobs', len(jobs))


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'angles':
        h = TB / 2
        c, R, phi1, phi2, th2 = blade_camber(R1 + h, R2 - h, BETA1, BETA2)
        print('R', float(R), 'center', float(c[0]), float(c[1]), 'wrap deg', float(th2 * 180 / pi))
        print('at LE', check_angles(c, R, phi1, R1), 'at TE', check_angles(c, R, phi2, R2))
        print(blade_path(0))
        print(blade_profile())
        print(hub_profile())
        print(shroud_profile())
    elif cmd == 'casing':
        e, f, key = casing_edits()
        print(chr(10).join(x[:300] for x in e))
        print({k: [float(x) for x in v] if isinstance(v, tuple) else float(v) for k, v in key.items()})
    elif cmd == 'build':
        name = sys.argv[2]
        only = sys.argv[3:]
        if not only:
            print(cli(name, 'new')[0])
        log = []
        for tag, edits in parts():
            if only and tag not in only:
                continue
            out, dt = cli(name, 'apply', *edits)
            ok = 'committed' in out
            log.append(dict(part=tag, ok=ok, seconds=round(dt, 1), tail=out[-1500:]))
            print(tag, ok, round(dt, 1), out[-600:] if not ok else '')
            json.dump(log, open(os.path.join(ROOT, 'docs/receipts/g4/run1/build_log_%s.json' % '_'.join(only or ['all'])), 'w'), indent=1)
    elif cmd == 'master':
        name = sys.argv[2]
        print(cli(name, 'new')[0])
        out, dt = cli(name, 'apply', *master_edits())
        q = os.path.join(ROOT, 'docs/receipts/g4/run1/q')
        os.makedirs(q, exist_ok=True)
        open(os.path.join(q, 'master_apply.txt'), 'w', newline=chr(10)).write(out)
        print('committed' in out, round(dt, 1))
        print(chr(10).join(l[:300] for l in out.splitlines() if 'error' in l or 'rejected' in l or 'committed' in l))
    elif cmd == 'analyze':
        name = sys.argv[2]
        only = set(sys.argv[3:])
        q = os.path.join(ROOT, 'docs/receipts/g4/run1/q')
        os.makedirs(q, exist_ok=True)
        wsl('mkdir', '-p', '%s/export' % WORK)
        for tag, args in analyses():
            if only and tag not in only:
                continue
            out, dt = cli(name, *args)
            open(os.path.join(q, tag + '.txt'), 'w', newline=chr(10)).write('$ %s%s%s%sseconds %.1f%s' % (' '.join(a[:200] for a in args), chr(10), out, chr(10), dt, chr(10)))
            print(tag, round(dt, 1), out.strip().splitlines()[-1][:200] if out.strip() else '', flush=True)
    elif cmd == 'batch':
        name = sys.argv[2]
        only = set(sys.argv[3:])
        q = os.path.join(ROOT, 'docs/receipts/g4/run1/q')
        os.makedirs(q, exist_ok=True)
        wsl('mkdir', '-p', '%s/export' % WORK)
        jobs = [(t, a) for t, a in analyses() if not only or t in only]
        flat = []
        for k, (t, a) in enumerate(jobs):
            flat += (['::'] if k else []) + a
        t0 = time.time()
        tag = os.environ.get('G4_STREAM', 'batch')
        stream = '%s/%s.out' % (WORK, tag)
        script = os.path.join(ROOT, 'docs/receipts/g4/run1/calc/%s_args.json' % tag)
        json.dump([BIN, '%s/%s' % (WORK, name), 'batch'] + flat, open(script, 'w'))
        wsl('python3', '/mnt/c/dev/BendCAD-k3/tools/g4/runbatch.py', '/mnt/c/dev/BendCAD-k3/docs/receipts/g4/run1/calc/%s_args.json' % tag, stream)
        split_batch(q, jobs, stream)
        print('batch seconds', round(time.time() - t0, 1))
    elif cmd == 'split':
        q = os.path.join(ROOT, 'docs/receipts/g4/run1/q')
        only = set(sys.argv[3:])
        split_batch(q, [(t, a) for t, a in analyses() if not only or t in only], sys.argv[2])
    elif cmd == 'parts':
        q = os.path.join(ROOT, 'docs/receipts/g4/run1/q')
        asm = assembly()
        open(os.path.join(q, 'assembly.txt'), 'w', newline=chr(10)).write(asm + chr(10))
        counts = {}
        for m in re.finditer(r'\(inst \S+ (\d+) ', asm):
            counts[int(m.group(1))] = counts.get(int(m.group(1)), 0) + 1
        mats = {n: (g, rho) for n, g, rho, cte, e, nu in MATERIALS}
        rows = ['# part node file material density_kg_m3 count volume_mm3_lo volume_mm3_hi  (volume certified by BendCAD mass; '
                'motor density = catalog weight %r kg over the catalog envelope volume)' % MOTOR_KG]
        for name, n in PART_NODES:
            t = open(os.path.join(q, 'mass_%s.txt' % name)).read()
            m = re.search(r'mass volume=\[([^,]+), ([^\]]+)\]', t)
            lo, hi = float(m.group(1)), float(m.group(2))
            g, rho = mats.get(n, ('ABB-M2QA112M2A-catalog', MOTOR_KG / ((lo + hi) / 2) * 1e9))
            rows.append('%s %d %s %s %r %d %r %r' % (name, n, name, g, rho, counts.get(n, 0), lo, hi))
        open(os.path.join(ROOT, 'docs/receipts/g4/run1/parts.txt'), 'w', newline=chr(10)).write(chr(10).join(rows) + chr(10))
        print(chr(10).join(rows))
    elif cmd == 'claims':
        e, f, key = casing_contours_claims()
        print(json.dumps(e, indent=1))
    elif cmd == 'proto':
        n = int(sys.argv[2])
        name = sys.argv[3]
        print(cli(name, 'new')[0])
        out, dt = cli(name, 'apply', *impeller_edits(n))
        print(out[-3000:], '\nseconds', round(dt, 1))
