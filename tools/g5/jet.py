import json
import math
import os
import subprocess
import sys
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bin/bc')
WORK = os.environ.get('G5_WORK', '/home/jesse/g5')
IC = '(intent create any any any any)'
IA = '(intent add any any any any)'
IR = '(intent remove any any any any)'
IS = '(intent same any any any any)'

CYC = json.load(open(os.path.join(ROOT, 'docs/receipts/g5/run1/cycle.json')))

B_D, B_DO, B_W = 8.0, 22.0, 7.0
BALL_D = 3.969
BALL_N = 7
PITCH_R = 7.5
GROOVE_R = 0.52 * BALL_D
IR_LAND = 6.1
OR_LAND = 8.9
CAGE_RI, CAGE_RO, CAGE_W = 6.45, 8.55, 2.4

Z_FRONT_BRG = 30.0
Z_REAR_BRG = 138.0
R_JOURNAL = 4.0
R_SPACER = 5.0
Z_NOSE = -6.0
Z_TAIL = 178.0

MATERIALS = [
    (10, '42CrMo4-QT', 7850, 1.15e-5, 210000, 0.29),
    (11, '100Cr6', 7810, 1.15e-5, 208000, 0.30),
    (12, '100Cr6', 7810, 1.15e-5, 208000, 0.30),
    (13, 'Si3N4', 3200, 3.2e-6, 310000, 0.27),
    (14, 'PEEK-CF30', 1410, 1.5e-5, 13000, 0.40),
    (15, 'X5CrNi18-10', 7900, 1.6e-5, 200000, 0.29),
    (16, '51CrV4', 7850, 1.2e-5, 206000, 0.30),
    (17, 'X5CrNi18-10', 7900, 1.6e-5, 200000, 0.29),
    (18, 'X5CrNi18-10', 7900, 1.6e-5, 200000, 0.29),
    (20, 'X5CrNi18-10', 7900, 1.6e-5, 200000, 0.29),
    (22, 'NiCr22Mo9Nb', 8440, 1.28e-5, 205000, 0.31),
    (19, 'AlZn5.5MgCu-T6', 2810, 2.36e-5, 71700, 0.33),
    (23, 'AlSi7Mg-T6', 2680, 2.15e-5, 72000, 0.33),
    (24, 'AlSi7Mg-T6', 2680, 2.15e-5, 72000, 0.33),
    (25, 'AlSi7Mg-T6', 2680, 2.15e-5, 72000, 0.33),
    (26, 'IN713C', 7910, 1.06e-5, 206000, 0.30),
    (27, 'IN713C', 7910, 1.06e-5, 206000, 0.30),
    (28, 'X15CrNiSi25-21', 7900, 1.7e-5, 196000, 0.30),
    (29, 'AlMg3-H22', 2670, 2.4e-5, 70000, 0.33),
    (30, 'X5CrNi18-10', 7900, 1.6e-5, 200000, 0.29),
]

R_CASE_O, T_CASE, Z_CASE0, Z_CASE1 = 54.0, 0.8, 20.0, 175.0
R_NOZ_IN, R_NOZ_OUT, Z_NOZ1 = R_CASE_O - T_CASE, 23.2, 230.0
R_LIN_I, R_LIN_O, T_LIN, Z_LIN0, Z_LIN1 = 22.0, 46.0, 0.5, 60.0, 150.0

Z_TUN0, Z_TUN1 = Z_FRONT_BRG - 2.0, Z_REAR_BRG + B_W + 3.0
R_TUN_O, R_TUN_MID = 15.0, 9.5
SPR_RI, SPR_RO, SPR_T, SPR_H = 5.6, 10.8, 0.5, 0.45


def f(x):
    return repr(float(x))


def region(*pts_and_arcs):
    return '(region (path ' + ' '.join(pts_and_arcs) + '))'


def shaft_edits():
    p = [f'{f(0.0)} {f(Z_NOSE)}', f'(line {f(R_JOURNAL)} {f(Z_NOSE)})',
         f'(line {f(R_JOURNAL)} {f(Z_FRONT_BRG + B_W)})', f'(line {f(R_SPACER)} {f(Z_FRONT_BRG + B_W)})',
         f'(line {f(R_SPACER)} {f(Z_REAR_BRG)})', f'(line {f(R_JOURNAL)} {f(Z_REAR_BRG)})',
         f'(line {f(R_JOURNAL)} {f(Z_TAIL)})', f'(line {f(0.0)} {f(Z_TAIL)})', f'(line {f(0.0)} {f(Z_NOSE)})']
    return [f'(node 10 (revolve {region(*p)}) {IC})']


def groove_z():
    dz = (GROOVE_R ** 2 - (PITCH_R - IR_LAND) ** 2) ** 0.5
    return B_W / 2 - dz, B_W / 2 + dz


def inner_ring_edits():
    z0, z1 = groove_z()
    p = [f'{f(B_D / 2)} 0.0', f'(line {f(IR_LAND)} 0.0)', f'(line {f(IR_LAND)} {f(z0)})',
         f'(arc {f(PITCH_R)} {f(B_W / 2)} {f(GROOVE_R)} {f(IR_LAND)} {f(z1)} cw)',
         f'(line {f(IR_LAND)} {f(B_W)})', f'(line {f(B_D / 2)} {f(B_W)})', f'(line {f(B_D / 2)} 0.0)']
    return [f'(node 11 (revolve {region(*p)}) {IC})']


def outer_ring_edits():
    dz = (GROOVE_R ** 2 - (OR_LAND - PITCH_R) ** 2) ** 0.5
    z0, z1 = B_W / 2 - dz, B_W / 2 + dz
    p = [f'{f(OR_LAND)} 0.0', f'(line {f(B_DO / 2)} 0.0)', f'(line {f(B_DO / 2)} {f(B_W)})',
         f'(line {f(OR_LAND)} {f(B_W)})', f'(line {f(OR_LAND)} {f(z1)})',
         f'(arc {f(PITCH_R)} {f(B_W / 2)} {f(GROOVE_R)} {f(OR_LAND)} {f(z0)} cw)', f'(line {f(OR_LAND)} 0.0)']
    return [f'(node 12 (revolve {region(*p)}) {IC})']


def ball_edits():
    return [f'(node 1301 (sphere {f(BALL_D / 2)}) {IC})',
            f'(node 13 (move 1301 {f(PITCH_R)} 0.0 {f(B_W / 2)} 0) {IS})']


def cage_edits():
    z0 = B_W / 2 - 1.0
    z1 = B_W / 2 + BALL_D / 2 + 0.1 + 0.6
    p = [f'{f(CAGE_RI)} {f(z0)}', f'(line {f(CAGE_RO)} {f(z0)})', f'(line {f(CAGE_RO)} {f(z1)})',
         f'(line {f(CAGE_RI)} {f(z1)})', f'(line {f(CAGE_RI)} {f(z0)})']
    e = [f'(node 1401 (revolve {region(*p)}) {IC})', f'(node 1402 (sphere {f(BALL_D / 2 + 0.1)}) {IC})',
         f'(node 1403 (move 1402 {f(PITCH_R)} 0.0 {f(B_W / 2)} 0) {IS})',
         f'(node 1410 (difference 1401 1403) {IR})']
    for k in range(1, BALL_N):
        a = 2 * math.pi * k / BALL_N
        e.append(f'(node {1420 + k} (move 1402 {f(PITCH_R * math.cos(a))} {f(PITCH_R * math.sin(a))} {f(B_W / 2)} 0) {IS})')
        e.append(f'(node {1410 + k} (difference {1410 + k - 1} {1420 + k}) {IR})')
    e.append(f'(node 14 (move {1410 + BALL_N - 1} 0.0 0.0 0.0 0) {IS})')
    return e


def tunnel_edits():
    zf, zr = Z_FRONT_BRG + B_W, Z_REAR_BRG
    p = [f'{f(B_DO / 2)} {f(Z_TUN0)}', f'(line {f(R_TUN_O)} {f(Z_TUN0)})', f'(line {f(R_TUN_O)} {f(Z_TUN1)})',
         f'(line {f(B_DO / 2)} {f(Z_TUN1)})', f'(line {f(B_DO / 2)} {f(zr - 2.0)})', f'(line {f(R_TUN_MID)} {f(zr - 2.0)})',
         f'(line {f(R_TUN_MID)} {f(zf + 2.0)})', f'(line {f(B_DO / 2)} {f(zf + 2.0)})', f'(line {f(B_DO / 2)} {f(Z_TUN0)})']
    return [f'(node 15 (revolve {region(*p)}) {IC})']


def spring_edits():
    p = [f'{f(SPR_RI)} 0.0', f'(line {f(SPR_RO)} {f(SPR_H)})', f'(line {f(SPR_RO)} {f(SPR_H + SPR_T)})',
         f'(line {f(SPR_RI)} {f(SPR_T)})', f'(line {f(SPR_RI)} 0.0)']
    return [f'(node 16 (revolve {region(*p)}) {IC})']


def nut_edits(nid, width_af=13.0, h=6.5):
    r = width_af / 3 ** 0.5
    hx = ' '.join(f'(line {f(r * math.cos(math.pi / 3 * k))} {f(r * math.sin(math.pi / 3 * k))})' for k in range(1, 6)) + f' (line {f(r)} 0.0)'
    return [f'(node {nid}1 (prism 0.0 {f(h)} (region (path {f(r)} 0.0 {hx}) (circle 0.0 0.0 {f(R_JOURNAL)}))) {IC})',
            f'(node {nid} (move {nid}1 0.0 0.0 0.0 0) {IS})']


def ring_rev(r0, r1, z0, z1):
    return region(f'{f(r0)} {f(z0)}', f'(line {f(r1)} {f(z0)})', f'(line {f(r1)} {f(z1)})', f'(line {f(r0)} {f(z1)})', f'(line {f(r0)} {f(z0)})')


def xbar(nid, r, h, x, z):
    return [f'(node {nid} (cylinder {f(r)} {f(h)}) {IC})', f'(node {nid + 1} (rotate {nid} y 90.0) {IS})',
            f'(node {nid + 2} (move {nid + 1} {f(x)} 0.0 {f(z)} 0) {IS})']


def casing_edits():
    return ([f'(node 2001 (revolve {ring_rev(R_CASE_O - T_CASE, R_CASE_O, Z_CASE0, Z_CASE1)}) {IC})'] +
            xbar(2002, 4.0, 7.0, 52.6, 85.0) + [f'(node 2005 (union 2001 2004) {IA})'] +
            xbar(2006, 2.1, 12.0, 48.0, 85.0) + [f'(node 2009 (difference 2005 2008) {IR})'] +
            xbar(2010, 1.3, 10.0, 49.0, 55.0) + [f'(node 2013 (difference 2009 2012) {IR})',
                                                  f'(node 20 (move 2013 0.0 0.0 0.0 0) {IS})'])


def nozzle_edits():
    p = [f'{f(R_NOZ_IN)} {f(Z_CASE1)}', f'(line {f(R_CASE_O)} {f(Z_CASE1)})', f'(line {f(R_NOZ_OUT + T_CASE)} {f(Z_NOZ1)})',
         f'(line {f(R_NOZ_OUT)} {f(Z_NOZ1)})', f'(line {f(R_NOZ_IN)} {f(Z_CASE1)})']
    return [f'(node 21 (revolve {region(*p)}) {IC})']


def liner_edits():
    a, b, t = R_LIN_I, R_LIN_O, T_LIN
    p = [f'{f(a)} {f(Z_LIN0)}', f'(line {f(b)} {f(Z_LIN0)})', f'(line {f(b)} {f(Z_LIN1)})', f'(line {f(b - t)} {f(Z_LIN1)})',
         f'(line {f(b - t)} {f(Z_LIN0 + t)})', f'(line {f(a + t)} {f(Z_LIN0 + t)})', f'(line {f(a + t)} {f(Z_LIN1)})',
         f'(line {f(a)} {f(Z_LIN1)})', f'(line {f(a)} {f(Z_LIN0)})']
    return [f'(node 22 (revolve {region(*p)}) {IC})']


IMP_Z0, IMP_R2, IMP_RH1, IMP_RS1, IMP_G = 1.0, 33.0, 9.0, 23.5, 0.3
IMP_LS = 9.5 + 9.5 * math.pi / 2


def imp_hub_pt(m):
    if m < 0.0:
        return IMP_RH1, IMP_Z0 + m * 24.0 * math.pi / 2
    if m > 1.0:
        return IMP_R2 + (m - 1.0) * 24.0 * math.pi / 2, IMP_Z0 + 24.0
    a = m * math.pi / 2
    return IMP_R2 - 24.0 * math.cos(a), IMP_Z0 + 24.0 * math.sin(a)


def imp_shr_pt(m):
    s = m * IMP_LS
    if s <= 9.5:
        return IMP_RS1 - 0.5 * (9.5 - s) / 12.5, IMP_Z0 + s
    if m > 1.0:
        return IMP_R2 + s - IMP_LS, IMP_Z0 + 19.0
    a = (s - 9.5) / 9.5
    return IMP_R2 - 9.5 * math.cos(a), IMP_Z0 + 9.5 + 9.5 * math.sin(a)


def imp_theta(m):
    a, b, s = 0.0825, 0.0175, m * IMP_LS
    if s <= IMP_LS:
        return -(a * s + (b - a) * s * s / (2 * IMP_LS))
    return -(IMP_LS * (a + b) / 2 + b * (s - IMP_LS))


def imp_sec(m, m0):
    hr, hz = imp_hub_pt(m)
    sr, sz = imp_shr_pt(m)
    dr, dz = sr - hr, sz - hz
    ln = math.hypot(dr, dz)
    hr, hz = hr - 0.6 * dr / ln, hz - 0.6 * dz / ln
    ln += 0.6 - IMP_G
    th = imp_theta(m)
    c, s = math.cos(th), math.sin(th)
    k = min(1.0, (m - m0) / 0.2)
    k = k * k * (3 - 2 * k)
    th_h, th_s = 0.5 + 1.1 * k, 0.4 + 0.4 * k
    a, b, cc, d = (0.0, -th_h / 2), (ln, -th_s / 2), (ln, th_s / 2), (0.0, th_h / 2)
    run = lambda p, q: f'(run {f(p[0])} {f(p[1])} {f(q[0])} {f(q[1])})'
    o = (hr * c, hr * s, hz)
    n = math.hypot(dr, dz)
    u = (dr / n * c, dr / n * s, dz / n)
    v = (-s, c, 0.0)
    fr = '(frame ' + ' '.join(f(x) for x in (*o, *u, *v, 1.0)) + ')'
    return f'(sec {run(a, b)} {run(b, cc)} {run(cc, d)} {run(d, a)} {fr})'


def impeller_edits():
    z0, g = IMP_Z0, IMP_G
    ka = math.radians(80.0)
    ar, az = IMP_R2 - 24.0 * math.cos(ka), z0 + 24.0 * math.sin(ka)
    hub = [f'{f(4.0)} {f(z0 - 2)}', f'(line {f(IMP_RH1 - 0.2)} {f(z0 - 2)})', f'(line {f(IMP_RH1)} {f(z0)})',
           f'(arc {f(IMP_R2)} {f(z0)} 24.0 {f(ar)} {f(az)} cw)', f'(line {f(34.0)} {f(az)})',
           f'(line {f(34.0)} {f(z0 + 26.5)})', f'(line {f(10.5)} {f(z0 + 26.5)})', f'(line {f(10.5)} {f(z0 + 29)})',
           f'(line {f(4.0)} {f(z0 + 29)})', f'(line {f(4.0)} {f(z0 - 2)})']
    env = [f'0.0 {f(z0 - 3)}', f'(line {f(IMP_RS1 - 0.5 - g)} {f(z0 - 3)})', f'(line {f(IMP_RS1 - g)} {f(z0 + 9.5)})',
           f'(arc {f(IMP_R2)} {f(z0 + 9.5)} {f(9.5 + g)} {f(IMP_R2)} {f(z0 + 19 + g)} cw)',
           f'(line {f(IMP_R2)} {f(z0 + 29)})', f'(line 0.0 {f(z0 + 29)})', f'(line 0.0 {f(z0 - 3)})']
    main = ' '.join(imp_sec(0.02 + (1.013 - 0.02) * i / 10, 0.02) for i in range(11))
    spl = ' '.join(imp_sec(0.35 + (1.013 - 0.35) * i / 8, 0.35) for i in range(9))
    e = [f'(node 1901 (revolve {region(*hub)}) {IC})', f'(node 1902 (revolve {region(*env)}) {IC})',
         f'(node 1903 (skin {main}) {IC})', f'(node 1904 (skin {spl}) {IC})', f'(node 1905 (rotate 1904 z 30.0) {IS})']
    r, top = ring_of(1900, [(1903 if j == 0 else 1905, 60.0 * k) for k in range(6) for j in range(2)])
    e += r + [f'(node 1999 (union 1901 {top}) {IA})']
    prev = 1999
    e.append(f'(node 19 (move {prev} 0.0 0.0 0.0 0) {IS})')
    return e


def rz_region(pts):
    head = f'{f(pts[0][0])} {f(pts[0][1])}'
    segs = []
    for q in pts[1:]:
        if len(q) == 2:
            segs.append(f'(line {f(q[0])} {f(q[1])})')
        else:
            segs.append(f'(arc {f(q[2])} {f(q[3])} {f(q[4])} {f(q[0])} {f(q[1])} {q[5]})')
    return region(head, *segs)


def front_cover_edits():
    p = [(23.0, -8.0), (26.0, -8.0), (26.0, 7.0), (35.0, 16.0), (54.0, 16.0), (54.0, 20.0), (33.0, 20.0),
         (23.5, 10.5, 33.0, 10.5, 9.5, 'ccw'), (23.0, -2.0), (23.0, -8.0)]
    return [f'(node 23 (revolve {rz_region(p)}) {IC})']


def dif_vane(r0=35.0, r1=45.0, alpha=72.0, t0=0.5, t1=2.4, n=9):
    ta = math.tan(math.radians(alpha))
    left, right = [], []
    for i in range(n):
        r = r0 + (r1 - r0) * i / (n - 1)
        th = ta * math.log(r / r0)
        tx, ty = math.cos(th) - ta * math.sin(th), math.sin(th) + ta * math.cos(th)
        l = math.hypot(tx, ty)
        nx, ny = -ty / l, tx / l
        h = 0.5 * (t0 + (t1 - t0) * i / (n - 1))
        x, y = r * math.cos(th), r * math.sin(th)
        left.append((x + h * nx, y + h * ny))
        right.append((x - h * nx, y - h * ny))
    pts = left + right[::-1]
    return region(f'{f(pts[0][0])} {f(pts[0][1])}', *[f'(line {f(x)} {f(y)})' for x, y in pts[1:] + [pts[0]]])


DIF_N = 17


def tree_union(ids, nxt):
    e = []
    while len(ids) > 1:
        nx = []
        for i in range(0, len(ids) - 1, 2):
            e.append(f'(node {nxt} (union {ids[i]} {ids[i + 1]}) {IA})')
            nx.append(nxt)
            nxt += 1
        if len(ids) % 2:
            nx.append(ids[-1])
        ids = nx
    return e, ids[0]


def ring_of(base, srcs):
    e, ids = [], []
    for k, (src, ang) in enumerate(srcs):
        e.append(f'(node {base + 10 + k} (rotate {src} z {f(ang)}) {IS})')
        ids.append(base + 10 + k)
    t, top = tree_union(ids, base + 50)
    return e + t, top


def ring_union(base, src, n, first, step_deg, phase=0.0):
    e, top = ring_of(base, [(src, phase + step_deg * k) for k in range(n)])
    e.append(f'(node {base + 99} (union {first} {top}) {IA})')
    return e, base + 99


def diffuser_edits():
    plate = [(34.5, 24.635), (47.0, 24.635), (47.0, 27.0), (34.5, 27.0), (34.5, 24.635)]
    e = [f'(node 2401 (revolve {rz_region(plate)}) {IC})', f'(node 2402 (prism 20.0 24.9 {dif_vane()}) {IC})']
    r, prev = ring_union(2400, 2402, DIF_N, 2401, 360.0 / DIF_N)
    return e + r + [f'(node 24 (move {prev} 0.0 0.0 0.0 0) {IS})']


STR_N = 24


def straightener_edits():
    ring = [(45.5, 27.0), (47.0, 27.0), (47.0, 40.0), (45.5, 40.0), (45.5, 27.0)]
    e = [f'(node 2501 (revolve {rz_region(ring)}) {IC})', f'(node 2502 (box 6.0 1.2 10.0) {IC})',
         f'(node 2503 (move 2502 46.9 -0.6 28.5 0) {IS})']
    r, prev = ring_union(2500, 2503, STR_N, 2501, 360.0 / STR_N)
    return e + r + [f'(node 25 (move {prev} 0.0 0.0 0.0 0) {IS})']


def airfoil(c, tmax, s_in, s_out, te, n=11):
    a = (s_out - s_in) / (2.0 * c)
    up, lo = [], []
    for i in range(n):
        x = c * 0.5 * (1.0 - math.cos(math.pi * i / (n - 1)))
        q = x / c
        yt = 5.0 * tmax * c * (0.2969 * math.sqrt(q) - 0.1260 * q - 0.3516 * q * q + 0.2843 * q ** 3 - 0.1015 * q ** 4) + 0.5 * te * q
        yc = s_in * x + a * x * x
        th = math.atan(s_in + 2.0 * a * x)
        up.append((x - yt * math.sin(th), yc + yt * math.cos(th)))
        lo.append((x + yt * math.sin(th), yc - yt * math.cos(th)))
    return [lo[::-1] + up[1:], [up[-1], lo[-1]]]


def run2(pts):
    return '(run ' + ' '.join(f'{f(x)} {f(y)}' for x, y in pts) + ')'


def foil_sec(r, z_le, runs):
    fr = '(frame ' + ' '.join(f(x) for x in (r, 0.0, z_le, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0)) + ')'
    return '(sec ' + ' '.join(run2(rn) for rn in runs) + ' ' + fr + ')'


NGV_N = 19
TUR_N = 23


def ngv_edits():
    hub = [(20.5, 151.0), (22.0, 151.0), (22.0, 161.0), (20.5, 161.0), (20.5, 151.0)]
    shr = [(33.1, 153.5), (45.5, 150.5), (46.5, 150.5), (34.5, 155.0), (34.5, 174.0), (33.1, 174.0), (33.1, 153.5)]
    vane = airfoil(7.0, 0.12, 0.0, math.tan(math.radians(65.0)), 0.3)
    secs = ' '.join(foil_sec(r, 153.75, vane) for r in (21.4, 27.25, 33.6))
    e = [f'(node 2601 (revolve {rz_region(hub)}) {IC})', f'(node 2602 (revolve {rz_region(shr)}) {IC})',
         f'(node 2603 (union 2601 2602) {IA})', f'(node 2604 (skin {secs}) {IC})']
    r, prev = ring_union(2600, 2604, NGV_N, 2603, 360.0 / NGV_N)
    return e + r + [f'(node 26 (move {prev} 0.0 0.0 0.0 0) {IS})']


def turbine_edits():
    disc = [(4.0, 162.0), (12.0, 162.0), (12.0, 164.0), (18.0, 164.0), (18.0, 162.5), (21.5, 162.5), (21.5, 171.5),
            (18.0, 171.5), (18.0, 170.0), (12.0, 170.0), (12.0, 172.0), (4.0, 172.0), (4.0, 162.0)]
    b_hub = airfoil(7.5, 0.16, math.tan(math.radians(38.0)), -math.tan(math.radians(62.0)), 0.4)
    b_tip = airfoil(7.5, 0.10, math.tan(math.radians(20.0)), -math.tan(math.radians(66.0)), 0.3)
    secs = foil_sec(20.9, 163.25, b_hub) + ' ' + foil_sec(32.2, 163.25, b_tip)
    e = [f'(node 2701 (revolve {rz_region(disc)}) {IC})', f'(node 2702 (skin {secs}) {IC})']
    r, prev = ring_union(2700, 2702, TUR_N, 2701, 360.0 / TUR_N)
    return e + r + [f'(node 27 (move {prev} 0.0 0.0 0.0 0) {IS})']


def tail_cone_edits():
    cone = [(9.0, 174.0), (21.0, 174.0), (5.0, 206.0), (0.0, 206.0), (0.0, 181.0), (9.0, 181.0), (9.0, 174.0)]
    env = [(0.0, Z_CASE1), (R_CASE_O - T_CASE / 2, Z_CASE1), (R_NOZ_OUT + T_CASE / 2, Z_NOZ1), (0.0, Z_NOZ1), (0.0, Z_CASE1)]
    noz = [(R_NOZ_IN, Z_CASE1), (R_CASE_O, Z_CASE1), (R_NOZ_OUT + T_CASE, Z_NOZ1), (R_NOZ_OUT, Z_NOZ1), (R_NOZ_IN, Z_CASE1)]
    e = [f'(node 2801 (revolve {rz_region(cone)}) {IC})', f'(node 2802 (box 54.0 2.0 8.0) {IC})',
         f'(node 2803 (move 2802 6.0 -1.0 185.0 0) {IS})', f'(node 2804 (revolve {rz_region(env)}) {IC})',
         f'(node 2805 (intersection 2803 2804) {IS})', f'(node 2806 (revolve {rz_region(noz)}) {IC})']
    r, top = ring_of(2800, [(2805, 60.0 + 120.0 * k) for k in range(3)])
    return e + r + [f'(node 2898 (union 2801 {top}) {IA})', f'(node 2899 (union 2898 2806) {IA})',
                    f'(node 28 (move 2899 0.0 0.0 0.0 0) {IS})']


def intake_edits():
    p = [(21.0, -8.0), (23.0, -8.0), (23.0, -14.0), (31.0, -22.0, 31.0, -14.0, 8.0, 'ccw'), (31.0, -24.0),
         (21.0, -14.0, 31.0, -14.0, 10.0, 'cw'), (21.0, -8.0)]
    return [f'(node 29 (revolve {rz_region(p)}) {IC})']


def rect_path(r0, r1, z0, z1):
    return f'(path {f(r0)} {f(z0)} (line {f(r1)} {f(z0)}) (line {f(r1)} {f(z1)}) (line {f(r0)} {f(z1)}) (line {f(r0)} {f(z0)}))'


def manifold_edits():
    ring = f'(region {rect_path(46.5, 49.5, 53.5, 56.5)} {rect_path(47.25, 48.75, 54.25, 55.75)})'
    return ([f'(node 3001 (revolve {ring}) {IC})'] + xbar(3002, 1.2, 10.0, 48.5, 55.0) +
            [f'(node 3005 (union 3001 3004) {IA})'] + xbar(3006, 0.7, 11.0, 48.0, 55.0) +
            [f'(node 3009 (difference 3005 3008) {IR})', f'(node 30 (move 3009 0.0 0.0 0.0 0) {IS})'])


def igniter_edits():
    return [f'(node 3101 (cylinder 4.0 7.0) {IC})', f'(node 3102 (cylinder 2.1 7.0) {IC})',
            f'(node 3103 (difference 3101 3102) {IR})', f'(node 3104 (rotate 3103 y 90.0) {IS})',
            f'(node 31 (move 3104 52.6 0.0 85.0 0) {IS})']


Z_NUT_F, Z_NUT_R, Z_SPRING = -7.5, 172.0, Z_FRONT_BRG + B_W


def mv(nid, src, z):
    return f'(node {nid} (move {src} 0.0 0.0 {f(z)} 0) {IS})'


def placement_edits():
    r, top = ring_of(4100, [(13, 360.0 * k / BALL_N) for k in range(BALL_N)])
    return r + [mv(4201, 11, Z_FRONT_BRG), mv(4202, 12, Z_FRONT_BRG), mv(4203, top, Z_FRONT_BRG), mv(4204, 14, Z_FRONT_BRG),
                mv(4211, 11, Z_REAR_BRG), mv(4212, 12, Z_REAR_BRG), mv(4213, top, Z_REAR_BRG), mv(4214, 14, Z_REAR_BRG),
                mv(4221, 16, Z_SPRING), mv(4222, 17, Z_NUT_F), mv(4223, 18, Z_NUT_R)]


def materials():
    return [f'(material {n} {g} {rho} {cte!r} {e} {nu})' for n, g, rho, cte, e, nu in MATERIALS]


def parts():
    return [('shaft', shaft_edits()), ('inner_ring', inner_ring_edits()), ('outer_ring', outer_ring_edits()),
            ('ball', ball_edits()), ('cage', cage_edits()), ('tunnel', tunnel_edits()), ('spring', spring_edits()),
            ('nut_front', nut_edits(17)), ('nut_rear', nut_edits(18)),
            ('casing', casing_edits()), ('liner', liner_edits()),
            ('impeller', impeller_edits()), ('front_cover', front_cover_edits()), ('diffuser', diffuser_edits()),
            ('straightener', straightener_edits()), ('ngv', ngv_edits()), ('turbine', turbine_edits()),
            ('tail_cone', tail_cone_edits()), ('intake', intake_edits()), ('manifold', manifold_edits()),
            ('placement', placement_edits())]


def wsl(*args, timeout=600):
    t0 = time.time()
    p = subprocess.run(['wsl.exe', '-e'] + list(args), capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'), stdin=subprocess.DEVNULL)
    return p.stdout + p.stderr, time.time() - t0


PORT = int(os.environ.get('G5_PORT', '0'))
REQ = os.path.join(ROOT, '.g5req')


def ask(design, *args, timeout=600):
    import socket
    os.makedirs(REQ, exist_ok=True)
    t0 = time.time()
    fn = os.path.join(REQ, '%d.req' % int(t0 * 1e6))
    open(fn, 'w', newline=chr(10)).write(chr(10).join([f'{WORK}/{design}'] + list(args) + ['<<end>>']) + chr(10))
    wp = '/mnt/' + fn[0].lower() + fn[2:].replace(chr(92), '/')
    s = socket.create_connection(('127.0.0.1', PORT), timeout=timeout)
    s.sendall((wp + chr(10)).encode())
    out = b''
    while True:
        d = s.recv(65536)
        if not d:
            break
        out += d
    s.close()
    os.remove(fn)
    return out.decode(), time.time() - t0


def cli(design, *args, timeout=600):
    if PORT and args and args[0] != 'new':
        return ask(design, *args, timeout=timeout)
    return wsl(BIN, f'{WORK}/{design}', *args, timeout=timeout)


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'build':
        name = sys.argv[2]
        only = sys.argv[3:]
        wsl('mkdir', '-p', WORK)
        if not only:
            print(cli(name, 'new')[0].strip())
        for tag, edits in parts():
            if only and tag not in only:
                continue
            out, dt = cli(name, 'apply', *edits)
            print(tag, 'committed' in out, round(dt, 1), '' if 'committed' in out else out[-800:])
        out, dt = cli(name, 'apply', *materials())
        print('materials', 'committed' in out, round(dt, 1), '' if 'committed' in out else out[-400:])
