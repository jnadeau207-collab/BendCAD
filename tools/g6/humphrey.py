import json
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'g5'))
import jet as J5
import joints as JN

ROOT = J5.ROOT
SZ = json.load(open(os.path.join(ROOT, 'docs', 'receipts', 'g6', 'sizing.json'), encoding='utf-8'))
CY = json.load(open(os.path.join(ROOT, 'docs', 'receipts', 'g6', 'cycle.json'), encoding='utf-8'))
RD = json.load(open(os.path.join(ROOT, 'docs', 'receipts', 'g6', 'rdc.json'), encoding='utf-8'))
BEARING = J5.BRG['bearings']['7004 ACE/HCP4A']
CMC = json.load(open(os.path.join(ROOT, 'data', 'std', 'cmc.json'), encoding='utf-8'))['grades']['SIC-SIC-N24A']
IC, IA, IR, IS = JN.IC, JN.IA, JN.IR, JN.IS
f, region, rz_region, rev, polar, done = J5.f, J5.region, J5.rz_region, J5.rev, J5.polar, J5.done

C = SZ['compressor']
T = SZ['turbine']
RPM = C['shaft_rpm']
R2 = C['D2_mm'] / 2
R1T = C['inducer_tip_mm'] / 2
R1H = R1T * C['inducer_hub_tip']
B2 = 0.06 * C['D2_mm']
Z_IMP0, L_IMP = 0.0, 0.33 * C['D2_mm']
Z_EXIT = Z_IMP0 + L_IMP
G_TIP = 0.40
HUB_RIM = 0.5
R_DIF0, R_DIF1, DIF_N = R2 * 1.04, R2 * 1.28, 23
DIF_ALPHA = 68.0
R_CASE_O = 136.0
T_CASE = 1.0
R_CASE_I = R_CASE_O - T_CASE
RDC_W = 10.0
RDC_RM = 114.0
RDC_RI, RDC_RO = RDC_RM - RDC_W / 2, RDC_RM + RDC_W / 2
Z_INJ = 100.0
L_RDC = 120.0
Z_RDC1 = Z_INJ + L_RDC
L_STATOR = 45.0
Z_TUR = Z_RDC1 + L_STATOR + 5.0
Z_NGV0 = Z_TUR - 18.0
TH = T['hub_radius_mm']
TT = T['tip_radius_mm']
B_TUR = 22.0
G_TT = 0.15
Z_NOZ1 = Z_TUR + B_TUR + 120.0
R_NOZ = SZ['nozzle']['exit_dia_mm'] / 2
R_SHAFT = BEARING['d'] / 2
R_SPAN = R_SHAFT + 2.0
B_W, B_DO = BEARING['B'], BEARING['D']
B_BALL = BEARING['ball_d']
B_N = 12
B_PITCH = (BEARING['d'] + BEARING['D']) / 4
B_GROOVE = 0.52 * B_BALL
B_IL, B_OL = B_PITCH - 0.3527 * B_BALL, B_PITCH + 0.3527 * B_BALL
B_CI, B_CO = B_PITCH - 0.2646 * B_BALL, B_PITCH + 0.2646 * B_BALL
Z_FLANGE = Z_EXIT + 4.0
Z_BRG_F = Z_EXIT + 25.0
Z_BRG_R = Z_TUR - 4.0 - 2.0 - B_W
Z_TUN1 = Z_TUR - 4.0 - 1.5
R_TUN_O = B_DO / 2 + 5.0
Z_WEB = Z_RDC1 + 20.0
VAP_Z = (325.0, 350.0, 375.0, 400.0)
VAP_R, VAP_T = 3.0, 0.5
T_RDC, T_NOZ = 2.5, 1.2
NGV_N, TUR_N, INJ_N = 29, 41, 120
GRADES = {
    10: '17-4PH-H1075', 19: 'TI-6AL-4V-ANN', 20: 'TI-6AL-4V-ANN', 23: 'AL-A356.0-T6', 24: 'AL-A356.0-T6',
    40: 'INCONEL-625', 41: 'INCONEL-625', 42: ('SIC-SIC-N24A', CMC['rho_kg_m3'], CMC['cte_per_K_1204C'], CMC['E_MPa_1204C'], CMC['nu']), 27: 'WASPALOY-AMS5704', 28: 'INCONEL-625',
    43: 'AISI304-ANN', 44: 'A286-AMS5732', 461: 'INCONEL-625', 462: 'INCONEL-625', 463: 'INCONEL-625', 464: 'INCONEL-625',
    51: J5.lit('BEARING-STEEL'), 52: J5.lit('BEARING-STEEL'), 53: J5.lit('SI3N4'), 54: J5.PEEK,
    61: J5.lit('BEARING-STEEL'), 62: J5.lit('BEARING-STEEL'), 63: J5.lit('SI3N4'), 64: J5.PEEK,
}


def shaft_edits():
    p = [(5.0, -12.0), (R_SHAFT, -12.0), (R_SHAFT, Z_BRG_F + B_W + 1.0), (R_SPAN, Z_BRG_F + B_W + 1.0), (R_SPAN, Z_BRG_R - 1.0),
         (R_SHAFT, Z_BRG_R - 1.0), (R_SHAFT, Z_TUR + B_TUR + 10.0), (5.0, Z_TUR + B_TUR + 10.0)]
    return [rev(1001, p), done(10, 1001)]


def b_inner(nid, z0):
    dz = (B_GROOVE ** 2 - (B_PITCH - B_IL) ** 2) ** 0.5
    zc = z0 + B_W / 2
    p = [f'{f(R_SHAFT)} {f(z0)}', f'(line {f(B_IL)} {f(z0)})', f'(line {f(B_IL)} {f(zc - dz)})',
         f'(arc {f(B_PITCH)} {f(zc)} {f(B_GROOVE)} {f(B_IL)} {f(zc + dz)} cw)', f'(line {f(B_IL)} {f(z0 + B_W)})',
         f'(line {f(R_SHAFT)} {f(z0 + B_W)})', f'(line {f(R_SHAFT)} {f(z0)})']
    return [f'(node {nid} (revolve {region(*p)}) {IC})']


def b_outer(nid, z0):
    dz = (B_GROOVE ** 2 - (B_OL - B_PITCH) ** 2) ** 0.5
    zc = z0 + B_W / 2
    p = [f'{f(B_OL)} {f(z0)}', f'(line {f(B_DO / 2)} {f(z0)})', f'(line {f(B_DO / 2)} {f(z0 + B_W)})', f'(line {f(B_OL)} {f(z0 + B_W)})',
         f'(line {f(B_OL)} {f(zc + dz)})', f'(arc {f(B_PITCH)} {f(zc)} {f(B_GROOVE)} {f(B_OL)} {f(zc - dz)} cw)', f'(line {f(B_OL)} {f(z0)})']
    return [f'(node {nid} (revolve {region(*p)}) {IC})']


def bearing_edits(base, z0):
    zc = z0 + B_W / 2
    e = b_inner(base + 1, z0) + b_outer(base + 2, z0)
    e += [f'(node {base + 3} (sphere {f(B_BALL / 2)}) {IC})', f'(node {base + 4} (move {base + 3} {f(B_PITCH)} 0.0 {f(zc)} 0) {IS})']
    r, balls = J5.ring_of(base + 100, [(base + 4, 360.0 * k / B_N) for k in range(B_N)])
    e += r
    cz0, cz1 = zc - 0.25 * B_BALL, zc + B_BALL / 2 + 0.1 + 0.15 * B_BALL
    e += [rev(base + 5, [(B_CI, cz0), (B_CO, cz0), (B_CO, cz1), (B_CI, cz1)]), f'(node {base + 6} (sphere {f(B_BALL / 2 + 0.1)}) {IC})',
          f'(node {base + 7} (move {base + 6} {f(B_PITCH)} 0.0 {f(zc)} 0) {IS})']
    r, pockets = J5.ring_of(base + 200, [(base + 7, 360.0 * k / B_N) for k in range(B_N)])
    e += r + [f'(node {base + 8} (difference {base + 5} {pockets}) {IR})']
    k = base // 100
    return e + [done(k + 1, base + 1), done(k + 2, base + 2), done(k + 3, balls), done(k + 4, base + 8)], dict(inner=k + 1, outer=k + 2, balls=k + 3, cage=k + 4)


def hub_r(z):
    s = (z - Z_IMP0) / L_IMP
    return R1H + (R2 - R1H) * (1 - math.cos(math.pi / 2 * s))


def hub_z(r):
    s = 2.0 / math.pi * math.acos(1.0 - (r - R1H) / (R2 - R1H))
    return Z_IMP0 + L_IMP * s


def back_t(r):
    return 5.0 + 20.0 * ((R2 - r) / (R2 - 30.0)) ** 2


def imp_sec(m, m0, th_scale=1.0):
    zh = Z_IMP0 + L_IMP * m
    rh = hub_r(min(zh, Z_EXIT))
    zs = Z_IMP0 + (L_IMP - B2) * m
    rs = R1T + (R2 - R1T) * (1 - math.cos(math.pi / 2 * m)) ** 1.0
    dr, dz = rs - rh, zs - zh
    ln = math.hypot(dr, dz)
    rh, zh = rh - 0.8 * dr / ln, zh - 0.8 * dz / ln
    ln += 0.8 - G_TIP
    th = -0.55 * (1 - m) ** 2
    c, s = math.cos(th), math.sin(th)
    k = min(1.0, (m - m0) / 0.2)
    k = k * k * (3 - 2 * k)
    t_h, t_s = (1.2 + 2.0 * k) * th_scale, (0.8 + 0.8 * k) * th_scale
    a, b, cc, d = (0.0, -t_h / 2), (ln, -t_s / 2), (ln, t_s / 2), (0.0, t_h / 2)
    run = lambda p, q: f'(run {f(p[0])} {f(p[1])} {f(q[0])} {f(q[1])})'
    o = (rh * c, rh * s, zh)
    u = (dr / math.hypot(dr, dz) * c, dr / math.hypot(dr, dz) * s, dz / math.hypot(dr, dz))
    v = (-s, c, 0.0)
    fr = '(frame ' + ' '.join(f(x) for x in (*o, *u, *v, 1.0)) + ')'
    return f'(sec {run(a, b)} {run(b, cc)} {run(cc, d)} {run(d, a)} {fr})'


def impeller_edits():
    hub = [(R_SHAFT, Z_IMP0 - 6.0), (R1H - 0.5, Z_IMP0 - 6.0), (R1H, Z_IMP0)]
    for i in range(1, 8):
        z = Z_IMP0 + L_IMP * i / 8
        hub.append((hub_r(z), z))
    hub += [(R2 + HUB_RIM, Z_EXIT), (R2 + HUB_RIM, Z_EXIT + 5.0)] + [(r, min(Z_EXIT + 5.0, hub_z(r) + back_t(r))) for r in (90.0, 80.0, 70.0, 60.0, 50.0, 40.0, 30.0)] + [
        (R_SHAFT + 8.0, Z_EXIT + 14.0), (R_SHAFT, Z_EXIT + 14.0)]
    main = ' '.join(imp_sec(0.02 + 0.98 * i / 10, 0.02) for i in range(11))
    spl = ' '.join(imp_sec(0.40 + 0.60 * i / 7, 0.40, 0.85) for i in range(8))
    e = [rev(1901, hub), f'(node 1903 (skin {main}) {IC})', f'(node 1904 (skin {spl}) {IC})', f'(node 1905 (rotate 1904 z 15.0) {IS})']
    r, top = J5.ring_of(1900, [(1903 if j == 0 else 1905, 30.0 * k) for k in range(12) for j in range(2)])
    return e + r + [f'(node 1999 (union 1901 {top}) {IA})', done(19, 1999)]


def casing_edits():
    p = [(R_CASE_I, -20.0), (R_CASE_O, -20.0), (R_CASE_O, Z_TUR + B_TUR + 10.0), (R_CASE_I, Z_TUR + B_TUR + 10.0)]
    return [rev(20, p)]


def contour(m):
    return R1T + G_TIP + (R2 - R1T) * (1 - math.cos(math.pi / 2 * m)), Z_IMP0 + (L_IMP - B2) * m


def contour_n(m):
    dr, dz = (R2 - R1T) * math.pi / 2 * math.sin(math.pi / 2 * m), L_IMP - B2
    ln = math.hypot(dr, dz)
    return dz / ln, -dr / ln


def shroud_edits():
    t = 3.0
    ms = [i / 8 for i in range(9)]
    outer = [(contour(m)[0] + t * contour_n(m)[0], contour(m)[1] + t * contour_n(m)[1]) for m in ms]
    prof = [(R1T + G_TIP, Z_IMP0 - 30.0), (R1T + G_TIP + t, Z_IMP0 - 30.0)] + outer + [(R_CASE_I, Z_EXIT - B2 - t), (R_CASE_I, Z_EXIT - B2)]
    prof += [contour(m) for m in reversed(ms)]
    return [rev(23, prof)]


def spiral_vane(t=2.0, n=10):
    k = 1.0 / math.tan(math.radians(DIF_ALPHA))
    th1 = math.log(R_DIF1 / R_DIF0) / k
    side = []
    for i in range(n + 1):
        th = th1 * i / n
        r = R_DIF0 * math.exp(k * th)
        side.append((r * math.cos(th), r * math.sin(th)))
    dt = [t / R_DIF0 * R_DIF0 / math.hypot(*p) for p in side]
    other = [(x * math.cos(d) - y * math.sin(d), x * math.sin(d) + y * math.cos(d)) for (x, y), d in zip(side, dt)]
    pts = side + other[::-1]
    return region(f'{f(pts[0][0])} {f(pts[0][1])}', *[f'(line {f(x)} {f(y)})' for x, y in pts[1:] + [pts[0]]])


def diffuser_edits():
    p = [(R_SHAFT + 7.0, Z_EXIT + 0.5), (R2 + 2.0, Z_EXIT + 0.5), (R2 + 2.0, Z_EXIT), (R_DIF1 + 2.0, Z_EXIT), (R_DIF1 + 2.0, Z_EXIT + 4.0),
         (R_SHAFT + 7.0, Z_EXIT + 4.0)]
    e = [rev(2401, p), f'(node 2402 (prism {f(Z_EXIT - B2)} {f(Z_EXIT + 0.2)} {spiral_vane()}) {IC})']
    r, top = J5.ring_of(2400, [(2402, 360.0 / DIF_N * k) for k in range(DIF_N)])
    return e + r + [f'(node 2499 (union 2401 {top}) {IA})', done(24, 2499)]


def rdc_edits():
    body = [(RDC_RI - T_RDC, Z_INJ - 5.0), (RDC_RO, Z_INJ - 5.0), (RDC_RO, Z_INJ), (RDC_RI, Z_INJ), (RDC_RI, Z_RDC1), (RDC_RI - T_RDC, Z_RDC1)]
    e = [rev(4005, body)]
    holes = []
    ids = JN.Ids(400100)
    for k in range(INJ_N):
        x, y = polar(RDC_RM, 360.0 / INJ_N * k)
        a = ids()
        e += JN.cyl(a, 0.6, Z_INJ - 6.0, Z_INJ + 1.0)
        holes.append(a)
        e[-1] = e[-1].replace(' 0.0 0.0 ', f' {f(x)} {f(y)} ', 1)
    ce, top = JN.tree_union(holes, ids)
    return e + ce + [f'(node 4099 (difference 4005 {top}) {IR})', done(40, 4099)]


def stator_edits():
    z0, z1 = Z_RDC1, Z_NGV0
    ah = math.atan2(RDC_RI - TH, z1 - z0)
    dh = T_RDC / math.cos(ah)
    zh = z0 + (z1 - z0) * ((TH - T_RDC) - (RDC_RI - dh)) / (TH - RDC_RI)
    hub = [(RDC_RI, z0), (TH, z1), (TH, Z_TUR - 1.0), (TH - T_RDC, Z_TUR - 1.0), (TH - T_RDC, zh), (RDC_RI - dh, z0)]
    rs = TT + G_TT
    a_s = math.atan2(RDC_RO - rs, z1 - z0)
    ds = T_RDC / math.cos(a_s)
    zs = z0 + (z1 - z0) * ((rs + T_RDC) - (RDC_RO + ds)) / (rs - RDC_RO)
    zk = z0 + (ds - T_RDC) * (z1 - z0) / (RDC_RO - rs)
    shr = [(RDC_RO, Z_INJ - 5.0), (RDC_RO + T_RDC, Z_INJ - 5.0), (RDC_RO + T_RDC, zk), (rs + T_RDC, zs), (rs + T_RDC, Z_TUR + B_TUR + 2.0),
           (rs, Z_TUR + B_TUR + 2.0), (rs, z1), (RDC_RO, z0)]
    vane = J5.airfoil(Z_TUR - 3.0 - z1, 0.12, 0.0, math.tan(math.radians(68.0)), 0.6)
    secs = ' '.join(J5.foil_sec(r, z1 + 1.0, vane) for r in (TH - 0.6, 0.5 * (TH + rs), rs + 0.6))
    e = [rev(4201, hub), rev(4202, shr), f'(node 4203 (union 4201 4202) {IA})', f'(node 4204 (skin {secs}) {IC})']
    r, prev = J5.ring_union(4200, 4204, NGV_N, 4203, 360.0 / NGV_N)
    return e + r + [done(42, prev)]


def turbine_edits():
    disc = [(R_SHAFT, Z_TUR - 4.0), (20.0, Z_TUR - 4.0), (20.0, Z_TUR + 7.0), (TH - 10.0, Z_TUR + 7.0), (TH - 10.0, Z_TUR), (TH, Z_TUR), (TH, Z_TUR + B_TUR),
            (TH - 10.0, Z_TUR + B_TUR), (TH - 10.0, Z_TUR + 15.0), (20.0, Z_TUR + 15.0), (20.0, Z_TUR + B_TUR + 4.0), (R_SHAFT, Z_TUR + B_TUR + 4.0)]
    b_hub = J5.airfoil(B_TUR - 2.0, 0.18, math.tan(math.radians(42.0)), -math.tan(math.radians(60.0)), 0.6)
    b_tip = J5.airfoil(B_TUR - 2.0, 0.10, math.tan(math.radians(25.0)), -math.tan(math.radians(64.0)), 0.4)
    secs = J5.foil_sec(TH - 0.8, Z_TUR + 1.0, b_hub) + ' ' + J5.foil_sec(TT, Z_TUR + 1.0, b_tip)
    e = [rev(2701, disc), f'(node 2702 (skin {secs}) {IC})']
    r, prev = J5.ring_union(2700, 2702, TUR_N, 2701, 360.0 / TUR_N)
    return e + r + [done(27, prev)]


def nozzle_edits():
    z0, zc0, zc1 = Z_TUR + B_TUR + 2.0, Z_TUR + B_TUR + 8.0, Z_NOZ1 - 30.0
    shell = [(TT + 4.0, z0), (TT + 4.0 + T_NOZ, z0), (R_NOZ + T_NOZ, Z_NOZ1), (R_NOZ, Z_NOZ1)]
    cone = [(0.0, zc0), (TH - 2.0, zc0), (8.0, zc1), (0.0, zc1)]
    cin = [(0.0, zc0 + 1.0), (TH - 3.6, zc0 + 1.0), (6.4, zc1 - 1.0), (0.0, zc1 - 1.0)]
    e = [rev(2801, shell), rev(2802, cone), rev(2804, cin), f'(node 2805 (difference 2802 2804) {IR})']
    zs = 0.5 * (zc0 + zc1)
    r0 = cone_r(zs) - 1.0
    r1 = nozzle_r(zs) + 0.5
    e += [f'(node 2810 (box {f(r1 - r0)} 2.0 20.0) {IC})', f'(node 2811 (move 2810 {f(r0)} -1.0 {f(zs - 10.0)} 0) {IS})']
    e += [f'(node {2812 + k} (rotate 2811 z {f(120.0 * k)}) {IS})' for k in range(3)]
    e += ['(node 2820 (union 2812 2813) ' + IA + ')', '(node 2821 (union 2820 2814) ' + IA + ')', f'(node 2822 (union 2805 2821) {IA})', f'(node 2823 (union 2822 2801) {IA})']
    return e + [done(28, 2823)]


def cone_r(z):
    zc0, zc1 = Z_TUR + B_TUR + 8.0, Z_NOZ1 - 30.0
    return (TH - 2.0) + (8.0 - (TH - 2.0)) * (z - zc0) / (zc1 - zc0)


def reservoir_edits():
    r, l0, l1, t = 18.0, -95.0, -38.0, 2.0
    def cap(nid, rr):
        pts = [f'{f(0.0)} {f(l0 - rr)}', f'(arc 0.0 {f(l0)} {f(rr)} {f(rr)} {f(l0)} ccw)', f'(line {f(rr)} {f(l1)})', f'(arc 0.0 {f(l1)} {f(rr)} 0.0 {f(l1 + rr)} ccw)', f'(line 0.0 {f(l0 - rr)})']
        return f'(node {nid} (revolve {region(*pts)}) {IC})'
    return [cap(4301, r), cap(4302, r - t), f'(node 4303 (difference 4301 4302) {IR})', done(43, 4303)]


def hub_inner_r(z):
    dh = T_RDC / math.cos(math.atan2(RDC_RI - TH, Z_NGV0 - Z_RDC1))
    return (RDC_RI - dh) + (TH - RDC_RI) * (z - Z_RDC1) / (Z_NGV0 - Z_RDC1)


def tunnel_edits():
    web_r = hub_inner_r(Z_WEB + 3.0) - 0.2
    p = [(B_DO / 2, Z_FLANGE), (40.0, Z_FLANGE), (40.0, Z_FLANGE + 3.0), (R_TUN_O, Z_FLANGE + 6.0), (R_TUN_O, Z_WEB), (web_r, Z_WEB),
         (web_r, Z_WEB + 3.0), (R_TUN_O, Z_WEB + 6.0), (R_TUN_O, Z_TUN1), (B_DO / 2, Z_TUN1)]
    return [rev(4401, p), done(44, 4401)]


def vaporiser_edits():
    e = []
    for k, z in enumerate(VAP_Z):
        rc = nozzle_r(z) + T_NOZ + VAP_R + 0.5
        a, b = 4510 + 10 * k, 4511 + 10 * k
        e += [f'(node {a} (revolve {torus_reg(rc, z, VAP_R)}) {IC})',
              f'(node {b} (revolve {torus_reg(rc, z, VAP_R - VAP_T)}) {IC})', f'(node {4512 + 10 * k} (difference {a} {b}) {IR})',
              done(461 + k, 4512 + 10 * k)]
    return e


def torus_reg(rc, z, rr):
    return region(f'{f(rc + rr)} {f(z)}', f'(arc {f(rc)} {f(z)} {f(rr)} {f(rc - rr)} {f(z)} ccw)', f'(arc {f(rc)} {f(z)} {f(rr)} {f(rc + rr)} {f(z)} ccw)')


def nozzle_r(z):
    z0, z1 = Z_TUR + B_TUR + 2.0, Z_NOZ1
    return TT + 4.0 + (R_NOZ - (TT + 4.0)) * (z - z0) / (z1 - z0)


def materials():
    return [J5.mat_edit(n, g) for n, g in GRADES.items() if n in USED]


def parts():
    return [('shaft', shaft_edits()), ('casing', casing_edits()), ('shroud', shroud_edits()), ('diffuser', diffuser_edits()), ('rdc', rdc_edits()),
            ('stator', stator_edits()), ('turbine', turbine_edits()), ('nozzle', nozzle_edits()), ('reservoir', reservoir_edits()), ('impeller', impeller_edits()),
            ('tunnel', tunnel_edits()), ('vaporiser', vaporiser_edits()), ('bearing_front', bearing_edits(5000, Z_BRG_F)[0]),
            ('bearing_rear', bearing_edits(6000, Z_BRG_R)[0])]


USED = {10, 19, 20, 23, 24, 40, 42, 27, 28, 43, 44, 461, 462, 463, 464, 51, 52, 53, 54, 61, 62, 63, 64}


def write(path):
    lines = ['(bendcad 1)']
    for tag, edits in parts():
        lines += edits
    lines += materials()
    open(path, 'w', newline='\n').write('\n'.join(lines) + '\n')
    return len(lines)


if __name__ == '__main__':
    print('lines', write(sys.argv[1]))
    print('envelope: D', 2 * R_CASE_O, 'L', Z_NOZ1 - (-95.0 - 18.0), 'rpm', round(RPM))
