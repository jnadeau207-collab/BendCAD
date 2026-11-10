import json
import math
import os
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
import joints as J
import threads as T

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bin/bc')
WORK = os.environ.get('G5_WORK', '/home/jesse/g5')
IC, IA, IR, IS = J.IC, J.IA, J.IR, J.IS

CYC = json.load(open(os.path.join(ROOT, 'docs/receipts/g5/run1/cycle.json'), encoding='utf-8'))
RPM = CYC['shaft_rpm']

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
Z_NOSE = -9.0
Z_TAIL = 180.0
Z_NUT_F, Z_NUT_R = -7.5, 172.0
Z_SPRING = Z_FRONT_BRG + B_W
SPR_RI, SPR_RO, SPR_T, SPR_H = 9.0, 10.9, 0.25, 0.15
Z_SPR_SEAT = Z_SPRING + SPR_T + SPR_H
SHAFT_TH_F = (-8.6, -1.4)
SHAFT_TH_R = (172.4, 179.6)

A2, A286 = ('X5CrNi18-10', 7900, 1.6e-5, 200000, 0.29), ('X6NiCrTiMoVB25-15-2', 7940, 1.65e-5, 201000, 0.31)
GRADES = {
    10: ('42CrMo4-QT', 7850, 1.15e-5, 210000, 0.29), 11: ('100Cr6', 7810, 1.15e-5, 208000, 0.30),
    12: ('100Cr6', 7810, 1.15e-5, 208000, 0.30), 13: ('Si3N4', 3200, 3.2e-6, 310000, 0.27),
    14: ('PEEK-CF30', 1410, 1.5e-5, 13000, 0.40), 15: A2, 16: ('51CrV4', 7850, 1.2e-5, 206000, 0.30),
    17: A2, 18: A2, 20: A2, 22: ('NiCr22Mo9Nb', 8440, 1.28e-5, 205000, 0.31),
    19: ('AlZn5.5MgCu-T6', 2810, 2.36e-5, 71700, 0.33), 23: ('AlSi7Mg-T6', 2680, 2.15e-5, 72000, 0.33),
    24: ('AlSi7Mg-T6', 2680, 2.15e-5, 72000, 0.33), 26: ('IN713C', 7910, 1.06e-5, 206000, 0.30),
    27: ('IN713C', 7910, 1.06e-5, 206000, 0.30), 28: ('X15CrNiSi25-21', 7900, 1.7e-5, 196000, 0.30),
    29: ('AlMg3-H22', 2670, 2.4e-5, 70000, 0.33), 30: A2, 31: A2, 32: ('42CrMo4-QT', 7850, 1.15e-5, 210000, 0.29),
    33: A2, 34: A2, 35: A2, 36: A2, 50: A2, 51: A2, 52: A2, 53: A286,
}

R_CASE_O, T_CASE, Z_CASE0, Z_CASE1 = 54.0, 0.8, 14.0, 175.0
R_CASE_I = R_CASE_O - T_CASE
R_SPIGOT = 53.15
R_LIN_I, R_LIN_O, T_LIN, Z_LIN0 = 22.0, 46.0, 0.5, 60.0
R_SHROUD = 33.28


def f(x):
    return repr(float(x))


def region(*pts_and_arcs):
    return '(region (path ' + ' '.join(pts_and_arcs) + '))'


def rz_region(pts):
    head = f'{f(pts[0][0])} {f(pts[0][1])}'
    segs = []
    for q in pts[1:] + [pts[0]]:
        if len(q) == 2:
            segs.append(f'(line {f(q[0])} {f(q[1])})')
        else:
            segs.append(f'(arc {f(q[2])} {f(q[3])} {f(q[4])} {f(q[0])} {f(q[1])} {q[5]})')
    return region(head, *segs)


def rev(nid, pts):
    return f'(node {nid} (revolve {rz_region(pts)}) {IC})'


def mv(nid, src, z):
    return f'(node {nid} (move {src} 0.0 0.0 {f(z)} 0) {IS})'


def radial_cyl(nid, r_cyl, r0, r1, phi, z, ids):
    a, b, c = ids(), ids(), ids()
    return [f'(node {a} (cylinder {f(r_cyl)} {f(r1 - r0)}) {IC})', f'(node {b} (rotate {a} y 90.0) {IS})',
            f'(node {c} (move {b} {f(r0)} 0.0 {f(z)} 0) {IS})', f'(node {nid} (rotate {c} z {f(phi)}) {IS})']


def axial_cyl(nid, r_cyl, x, y, z0, z1, ids):
    a = ids()
    return [f'(node {a} (cylinder {f(r_cyl)} {f(z1 - z0)}) {IC})', f'(node {nid} (move {a} {f(x)} {f(y)} {f(z0)} 0) {IS})']


def polar(r, deg):
    return r * math.cos(math.radians(deg)), r * math.sin(math.radians(deg))


def union_all(base, parts, ids):
    e, top = J.tree_union(parts, ids)
    n = ids()
    return e + [f'(node {n} (union {base} {top}) {IA})'], n


def cut_all(base, parts, ids):
    e, top = J.tree_union(parts, ids)
    n = ids()
    return e + [f'(node {n} (difference {base} {top}) {IR})'], n


def done(nid, prev):
    return f'(node {nid} (move {prev} 0.0 0.0 0.0 0) {IS})'


M3x6 = J.Screw(3.0, 6.0, 50)
M3x8 = J.Screw(3.0, 8.0, 51)
M3x10 = J.Screw(3.0, 10.0, 52)
SCREWS = [M3x6, M3x8, M3x10]

DIF_N = 18
DIF_R0, DIF_R1, DIF_A0, DIF_A1, DIF_T0, DIF_T1 = 35.5, 46.5, 65.0, 53.0, 0.6, 2.4
DIF_BOSS_R, DIF_BOSS_D = 43.5, 6.2
TUN_BOLT_R, NGV_BOLT_R, INTAKE_BOLT_R = 19.0, 17.5, 35.0


def dif_alpha(r):
    return math.radians(DIF_A0 + (DIF_A1 - DIF_A0) * (r - DIF_R0) / (DIF_R1 - DIF_R0))


def dif_theta(r, n=400):
    h = (r - DIF_R0) / n
    acc = 0.0
    for i in range(n):
        a, b = DIF_R0 + i * h, DIF_R0 + (i + 1) * h
        m = 0.5 * (a + b)
        acc += h / 6.0 * (math.tan(dif_alpha(a)) / a + 4.0 * math.tan(dif_alpha(m)) / m + math.tan(dif_alpha(b)) / b)
    return acc


def dif_vane(n=13):
    left, right = [], []
    for i in range(n):
        r = DIF_R0 + (DIF_R1 - DIF_R0) * i / (n - 1)
        th = dif_theta(r)
        ta = math.tan(dif_alpha(r))
        tx, ty = math.cos(th) - ta * math.sin(th), math.sin(th) + ta * math.cos(th)
        l = math.hypot(tx, ty)
        nx, ny = -ty / l, tx / l
        h = 0.5 * (DIF_T0 + (DIF_T1 - DIF_T0) * i / (n - 1))
        x, y = r * math.cos(th), r * math.sin(th)
        left.append((x + h * nx, y + h * ny))
        right.append((x - h * nx, y - h * ny))
    pts = left + right[::-1]
    return region(f'{f(pts[0][0])} {f(pts[0][1])}', *[f'(line {f(x)} {f(y)})' for x, y in pts[1:] + [pts[0]]])


def dif_boss_xy(k):
    return polar(DIF_BOSS_R, math.degrees(dif_theta(DIF_BOSS_R)) + 360.0 / DIF_N * 3 * k)


J_COVER_CASE = J.Joint('cover_casing', M3x6, [('r-', 22.5 + 45.0 * k, R_CASE_O, 17.0) for k in range(8)],
                       'casing', T_CASE, 'front_cover', 6.8, 6.3)
J_EXH_CASE = J.Joint('exhaust_casing', M3x6, [('r-', 22.5 + 45.0 * k, R_CASE_O, 172.0) for k in range(8)],
                     'casing', T_CASE, 'exhaust', R_CASE_O - 48.0, 0.0, through=True)
J_DIF_COVER = J.Joint('diffuser_cover', M3x10, [('z+', *dif_boss_xy(k), 16.0) for k in range(6)],
                      'front_cover', 4.0, 'diffuser', 11.0, 10.5)
J_INTAKE_COVER = J.Joint('intake_cover', M3x8, [('z+', *polar(INTAKE_BOLT_R, 45.0 + 90.0 * k), -11.0) for k in range(4)],
                         'intake', 3.0, 'front_cover', 8.0, 0.0, through=True)
J_TUNNEL_DIF = J.Joint('tunnel_diffuser', M3x8, [('z-', *polar(TUN_BOLT_R, 60.0 * k), 38.5) for k in range(6)],
                       'tunnel', 3.0, 'diffuser', 8.7, 8.2)
J_NGV_TUNNEL = J.Joint('ngv_tunnel', M3x8, [('z-', *polar(NGV_BOLT_R, 30.0 + 60.0 * k), 148.0) for k in range(6)],
                       'ngv', 3.0, 'tunnel', 9.0, 8.5)
JOINTS = [J_COVER_CASE, J_EXH_CASE, J_DIF_COVER, J_INTAKE_COVER, J_TUNNEL_DIF, J_NGV_TUNNEL]


class Fitting:
    def __init__(self, nid, length_in, z0, z1):
        self.d, self.p, self.nid = 5.0, T.PITCH[5.0], nid
        self.L, self.z0, self.z1 = length_in, z0, z1


GLOW = Fitting(31, 6.2, 0.3, 5.8)
ADAPTER = Fitting(36, 6.0, 0.3, 5.5)
BOSS_R1 = 59.0
FUEL_PHI, FUEL_Z = 60.0, 45.5
LUBE_PHI, LUBE_Z = 210.0, 42.0
GLOW_PHI, GLOW_Z = 0.0, 85.0
J_GLOW = J.Joint('glow_plug', GLOW, [('r-', GLOW_PHI, BOSS_R1, GLOW_Z)], None, 0.0, 'casing', BOSS_R1 - 52.9, 0.0, through=True)
J_FUEL = J.Joint('fuel_port', ADAPTER, [('r-', FUEL_PHI, BOSS_R1, FUEL_Z)], None, 0.0, 'casing', BOSS_R1 - 52.9, 0.0, through=True)
J_LUBE = J.Joint('lube_port', ADAPTER, [('r-', LUBE_PHI, BOSS_R1, LUBE_Z)], None, 0.0, 'casing', BOSS_R1 - 52.9, 0.0, through=True)
PORTS = [J_GLOW, J_FUEL, J_LUBE]


def tapped_into(part):
    return [j for j in JOINTS + PORTS if j.tapped == part]


def clamped_by(part):
    return [j for j in JOINTS if j.clamp == part]


def joint_cuts(part, ids):
    e, cs = [], []
    for j in clamped_by(part):
        ce, c = j.clear_cutter(ids)
        e += ce
        cs.append(c)
    for j in tapped_into(part):
        ce, c = j.tap_cutter(ids)
        e += ce
        cs.append(c)
    return e, cs


JOINTS_ON = os.environ.get('G5_JOINTS', '1') != '0'


def finish(part, nid, base, ids, extra_cuts=()):
    e, cs = joint_cuts(part, ids) if JOINTS_ON else ([], [])
    cs = list(extra_cuts) + cs
    if not cs:
        return e + [done(nid, base)]
    ce, n = cut_all(base, cs, ids)
    return e + ce + [done(nid, n)]


def shaft_edits():
    rc = T.ext_tooth(8.0, 1.0, T.ES_6G[8.0])[0]
    p = [(0.0, Z_NOSE), (rc - 0.25, Z_NOSE), (rc, Z_NOSE + 0.25), (rc, -1.0), (R_JOURNAL, -1.0), (R_JOURNAL, Z_SPRING),
         (R_SPACER, Z_SPRING), (R_SPACER, Z_REAR_BRG), (R_JOURNAL, Z_REAR_BRG), (R_JOURNAL, Z_NUT_R), (rc, Z_NUT_R),
         (rc, Z_TAIL - 0.25), (rc - 0.25, Z_TAIL), (0.0, Z_TAIL)]
    hw = max(z for _, z in T.ext_tooth(8.0, 1.0, T.ES_6G[8.0])[1]) + 0.1
    a, b = Z_NOSE + 0.25 + hw, -1.0 - hw
    c, d = Z_NUT_R + hw, Z_TAIL - 0.25 - hw
    if not JOINTS_ON:
        q = [(0.0, Z_NOSE), (R_JOURNAL, Z_NOSE), (R_JOURNAL, Z_SPRING), (R_SPACER, Z_SPRING), (R_SPACER, Z_REAR_BRG),
             (R_JOURNAL, Z_REAR_BRG), (R_JOURNAL, Z_TAIL), (0.0, Z_TAIL)]
        return [rev(1001, q), done(10, 1001)]
    return [rev(1001, p), T.ext_helix(1002, 8.0, a, b - a, IC, datum=SHAFT_TH_F[0]),
            T.ext_helix(1003, 8.0, c, d - c, IC, datum=SHAFT_TH_R[0]),
            f'(node 1004 (union 1001 1002) {IA})', f'(node 1005 (union 1004 1003) {IA})', done(10, 1005)]


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
    p = [(CAGE_RI, z0), (CAGE_RO, z0), (CAGE_RO, z1), (CAGE_RI, z1)]
    e = [rev(1401, p), f'(node 1402 (sphere {f(BALL_D / 2 + 0.1)}) {IC})',
         f'(node 1403 (move 1402 {f(PITCH_R)} 0.0 {f(B_W / 2)} 0) {IS})',
         f'(node 1410 (difference 1401 1403) {IR})']
    for k in range(1, BALL_N):
        a = 2 * math.pi * k / BALL_N
        e.append(f'(node {1420 + k} (move 1402 {f(PITCH_R * math.cos(a))} {f(PITCH_R * math.sin(a))} {f(B_W / 2)} 0) {IS})')
        e.append(f'(node {1410 + k} (difference {1410 + k - 1} {1420 + k}) {IR})')
    e.append(done(14, 1410 + BALL_N - 1))
    return e


def tunnel_edits():
    ids = J.Ids(150000)
    p = [(B_DO / 2, 28.0), (15.0, 28.0), (15.0, 35.5), (23.0, 35.5), (23.0, 38.5), (15.0, 38.5), (15.0, 138.0), (20.0, 138.0),
         (20.0, 145.0), (B_DO / 2, 145.0), (B_DO / 2, Z_REAR_BRG), (9.5, Z_REAR_BRG), (9.5, Z_SPR_SEAT), (B_DO / 2, Z_SPR_SEAT)]
    e = [rev(1501, p)]
    e += radial_cyl(1502, 1.05, 13.0, 15.6, LUBE_PHI, LUBE_Z, ids)
    e += radial_cyl(1503, 0.5, 9.2, 13.2, LUBE_PHI, LUBE_Z, ids)
    return e + finish('tunnel', 15, 1501, ids, [1502, 1503])


def spring_edits():
    p = [(SPR_RI, 0.0), (SPR_RO, SPR_H), (SPR_RO, SPR_H + SPR_T), (SPR_RI, SPR_T)]
    return [rev(16, p)]


def nut_edits(nid, z_nut, z_th0, width_af=13.0, h=6.5):
    r = width_af / 3 ** 0.5
    hx = ' '.join(f'(line {f(r * math.cos(math.pi / 3 * k))} {f(r * math.sin(math.pi / 3 * k))})' for k in range(1, 6)) + f' (line {f(r)} 0.0)'
    dw = 0.95 * width_af / 2
    c = (r + 0.1 - dw) * math.tan(math.radians(30.0))
    e0 = 0.1 / math.tan(math.radians(30.0))
    ch = [(0.0, -0.1), (dw - e0, -0.1), (r + 0.1, c), (r + 0.1, h - c), (dw - e0, h + 0.1), (0.0, h + 0.1)]
    rb, pts = T.int_tooth(8.0, 1.0)
    phase = T.SEAM_OFF + 2.0 * math.pi * (z_nut - 0.3 - z_th0) / 1.0
    if not JOINTS_ON:
        return [f'(node {nid}1 (prism 0.0 {f(h)} (region (path {f(r)} 0.0 {hx}) (circle 0.0 0.0 {f(R_JOURNAL)}))) {IC})',
                rev(int(f'{nid}2'), ch), f'(node {nid}3 (intersection {nid}1 {nid}2) {IS})', done(nid, int(f'{nid}3'))]
    return [f'(node {nid}1 (prism 0.0 {f(h)} (region (path {f(r)} 0.0 {hx}))) {IC})', rev(int(f'{nid}2'), ch),
            f'(node {nid}3 (intersection {nid}1 {nid}2) {IS})',
            f'(node {nid}4 (cylinder {f(rb)} {f(h + 0.6)}) {IC})', f'(node {nid}5 (move {nid}4 0.0 0.0 -0.3 0) {IS})',
            f'(node {nid}6 (skin {T.helix_secs(rb, -0.3, h + 0.6, 1.0, pts, phase=phase)}) {IC})',
            f'(node {nid}7 (union {nid}5 {nid}6) {IA})', f'(node {nid}8 (difference {nid}3 {nid}7) {IR})', done(nid, int(f'{nid}8'))]


def spacer_edits():
    return [rev(32, [(R_JOURNAL, 0.0), (6.0, 0.0), (6.0, 17.0), (R_JOURNAL, 17.0)])]


def casing_edits():
    ids = J.Ids(200000)
    e = [rev(2001, [(R_CASE_I, Z_CASE0), (R_CASE_O, Z_CASE0), (R_CASE_O, Z_CASE1), (R_CASE_I, Z_CASE1)])]
    bosses = []
    for phi, z in ((GLOW_PHI, GLOW_Z), (FUEL_PHI, FUEL_Z), (LUBE_PHI, LUBE_Z)):
        b = ids()
        e += radial_cyl(b, 4.0, 53.6, BOSS_R1, phi, z, ids)
        bosses.append(b)
    ue, n = union_all(2001, bosses, ids)
    return e + ue + finish('casing', 20, n, ids)


def liner_edits():
    ids = J.Ids(220000)
    a, b, t = R_LIN_I, R_LIN_O, T_LIN
    p = [(a, Z_LIN0), (b, Z_LIN0), (b, 149.5), (b - t, 149.5), (b - t, Z_LIN0 + t), (a + t, Z_LIN0 + t), (a + t, 150.5), (a, 150.5)]
    e = [rev(2201, p)]
    sticks, bores = [], []
    for k in range(6):
        x, y = polar(34.0, 30.0 + 60.0 * k)
        s1, s2 = ids(), ids()
        e += axial_cyl(s1, 2.25, x, y, 50.0, 85.0, ids) + axial_cyl(s2, 1.75, x, y, 49.5, 85.5, ids)
        sticks.append(s1)
        bores.append(s2)
    ue, n = union_all(2201, sticks, ids)
    e += ue
    holes = []
    rows = [(72.0, 18, 2.0, 12, 1.5), (95.0, 18, 2.5, 12, 1.75), (125.0, 12, 4.5, 12, 2.5)]
    for z, no, ro, ni, ri in rows:
        for k in range(no):
            h = ids()
            e += radial_cyl(h, ro, b - t - 0.6, b + 0.6, 10.0 + 360.0 / no * k, z, ids)
            holes.append(h)
        for k in range(ni):
            h = ids()
            e += radial_cyl(h, ri, a - 0.6, a + t + 0.6, 15.0 + 360.0 / ni * k, z, ids)
            holes.append(h)
    h = ids()
    e += radial_cyl(h, 2.1, b - t - 0.6, b + 0.6, GLOW_PHI, GLOW_Z, ids)
    holes.append(h)
    ce, n2 = cut_all(n, bores + holes, ids)
    return e + ce + [done(22, n2)]


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


def ring_of(base, srcs):
    e, ids = [], []
    for k, (src, ang) in enumerate(srcs):
        e.append(f'(node {base + 10 + k} (rotate {src} z {f(ang)}) {IS})')
        ids.append(base + 10 + k)
    nxt = [base + 50]

    def nid():
        nxt[0] += 1
        return nxt[0] - 1
    t, top = J.tree_union(ids, nid)
    return e + t, top


def ring_union(base, src, n, first, step_deg, phase=0.0):
    e, top = ring_of(base, [(src, phase + step_deg * k) for k in range(n)])
    e.append(f'(node {base + 99} (union {first} {top}) {IA})')
    return e, base + 99


def impeller_edits():
    z0 = IMP_Z0
    ka = math.radians(80.0)
    ar, az = IMP_R2 - 24.0 * math.cos(ka), z0 + 24.0 * math.sin(ka)
    hub = [f'{f(4.0)} {f(z0 - 2)}', f'(line {f(IMP_RH1 - 0.2)} {f(z0 - 2)})', f'(line {f(IMP_RH1)} {f(z0)})',
           f'(arc {f(IMP_R2)} {f(z0)} 24.0 {f(ar)} {f(az)} cw)', f'(line {f(34.0)} {f(az)})',
           f'(line {f(34.0)} {f(z0 + 26.5)})', f'(line {f(10.5)} {f(z0 + 26.5)})', f'(line {f(10.5)} {f(z0 + 29)})',
           f'(line {f(4.0)} {f(z0 + 29)})', f'(line {f(4.0)} {f(z0 - 2)})']
    main = ' '.join(imp_sec(0.02 + (1.013 - 0.02) * i / 10, 0.02) for i in range(11))
    spl = ' '.join(imp_sec(0.35 + (1.013 - 0.35) * i / 8, 0.35) for i in range(9))
    e = [f'(node 1901 (revolve {region(*hub)}) {IC})',
         f'(node 1903 (skin {main}) {IC})', f'(node 1904 (skin {spl}) {IC})', f'(node 1905 (rotate 1904 z 30.0) {IS})']
    r, top = ring_of(1900, [(1903 if j == 0 else 1905, 60.0 * k) for k in range(6) for j in range(2)])
    return e + r + [f'(node 1999 (union 1901 {top}) {IA})', done(19, 1999)]


def front_cover_edits():
    ids = J.Ids(230000)
    p = [(23.0, -8.0), (38.0, -8.0), (38.0, -3.0), (30.0, -3.0), (26.0, 1.0), (26.0, 7.0), (35.0, 16.0), (46.5, 16.0),
         (46.5, 14.0), (R_SPIGOT, 14.0), (R_SPIGOT, 20.0), (33.0, 20.0), (23.5, 10.5, 33.0, 10.5, 9.5, 'ccw'), (23.0, -2.0)]
    return [rev(2301, p)] + finish('front_cover', 23, 2301, ids)


def diffuser_edits():
    ids = J.Ids(240000)
    p = [(15.5, 28.0), (34.5, 28.0), (34.5, 24.635), (47.0, 24.635), (47.0, 40.0), (45.5, 40.0), (45.5, 30.5), (15.5, 30.5)]
    e = [rev(2401, p), f'(node 2402 (prism 20.0 24.9 {dif_vane()}) {IC})']
    adds = []
    for k in range(DIF_N):
        n = ids()
        e.append(f'(node {n} (rotate 2402 z {f(360.0 / DIF_N * k)}) {IS})')
        adds.append(n)
    for k in range(6):
        n = ids()
        e += axial_cyl(n, DIF_BOSS_D / 2, *dif_boss_xy(k), 20.0, 24.9, ids)
        adds.append(n)
        n = ids()
        e += axial_cyl(n, 3.5, *polar(TUN_BOLT_R, 60.0 * k), 30.3, 35.5, ids)
        adds.append(n)
    vane = airfoil(10.0, 0.08, math.tan(math.radians(50.0)), 0.0, 0.3)
    e.append(f'(node 2403 (skin {foil_sec(46.8, 28.5, vane)} {foil_sec(52.9, 28.5, vane)}) {IC})')
    for k in range(STR_N):
        n = ids()
        e.append(f'(node {n} (rotate 2403 z {f(360.0 / STR_N * k)}) {IS})')
        adds.append(n)
    ue, top = union_all(2401, adds, ids)
    return e + ue + finish('diffuser', 24, top, ids)


STR_N = 30


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
    ids = J.Ids(260000)
    hub = [(9.5, 145.0), (21.95, 145.0), (21.95, 151.0), (22.0, 151.0), (22.0, 161.0), (20.5, 161.0), (20.5, 148.0), (9.5, 148.0)]
    shr = [(R_SHROUD, 153.5), (44.95, 150.0), (44.95, 146.0), (45.45, 146.0), (45.45, 151.0), (34.68, 155.2), (34.68, 174.0), (R_SHROUD, 174.0)]
    vane = airfoil(7.0, 0.12, 0.0, math.tan(math.radians(65.0)), 0.3)
    secs = ' '.join(foil_sec(r, 153.75, vane) for r in (21.4, 27.25, 33.6))
    e = [rev(2601, hub), rev(2602, shr), f'(node 2603 (union 2601 2602) {IA})', f'(node 2604 (skin {secs}) {IC})']
    r, prev = ring_union(2600, 2604, NGV_N, 2603, 360.0 / NGV_N)
    return e + r + finish('ngv', 26, prev, ids)


def turbine_edits():
    disc = [(4.0, 162.0), (12.0, 162.0), (12.0, 164.0), (18.0, 164.0), (18.0, 162.5), (21.5, 162.5), (21.5, 171.5),
            (18.0, 171.5), (18.0, 170.0), (12.0, 170.0), (12.0, 172.0), (4.0, 172.0)]
    b_hub = airfoil(7.5, 0.16, math.tan(math.radians(38.0)), -math.tan(math.radians(62.0)), 0.4)
    b_tip = airfoil(7.5, 0.10, math.tan(math.radians(20.0)), -math.tan(math.radians(66.0)), 0.3)
    secs = foil_sec(20.9, 163.25, b_hub) + ' ' + foil_sec(32.2, 163.25, b_tip)
    e = [rev(2701, disc), f'(node 2702 (skin {secs}) {IC})']
    r, prev = ring_union(2700, 2702, TUR_N, 2701, 360.0 / TUR_N)
    return e + r + [done(27, prev)]


def exhaust_edits():
    ids = J.Ids(280000)
    shell = [(48.0, 169.0), (R_SPIGOT, 169.0), (R_SPIGOT, 176.5), (35.6, 176.5), (24.0, 230.0), (23.2, 230.0),
             (34.73, 176.5), (34.73, 170.0), (35.6, 170.0), (35.6, 175.0), (48.0, 175.0)]
    cone = [(9.0, 174.0), (21.0, 174.0), (5.0, 206.0), (0.0, 206.0), (0.0, 181.0), (9.0, 181.0)]
    env = [(0.0, 174.0), (35.2, 174.0), (35.2, 176.5), (23.6, 230.0), (0.0, 230.0)]
    e = [rev(2801, cone), f'(node 2802 (box 54.0 2.0 8.0) {IC})', f'(node 2803 (move 2802 6.0 -1.0 185.0 0) {IS})',
         rev(2804, env), f'(node 2805 (intersection 2803 2804) {IS})', rev(2806, shell)]
    r, top = ring_of(2800, [(2805, 60.0 + 120.0 * k) for k in range(3)])
    return e + r + [f'(node 2898 (union 2801 {top}) {IA})', f'(node 2899 (union 2898 2806) {IA})'] + finish('exhaust', 28, 2899, ids)


def intake_edits():
    ids = J.Ids(290000)
    p = [(23.0, -8.0), (38.0, -8.0), (38.0, -11.0), (25.0, -11.0), (25.0, -14.0), (33.0, -22.0, 33.0, -14.0, 8.0, 'ccw'),
         (33.0, -24.0), (23.0, -14.0, 33.0, -14.0, 10.0, 'cw')]
    return [rev(2901, p)] + finish('intake', 29, 2901, ids)


def rect_path(r0, r1, z0, z1):
    return f'(path {f(r0)} {f(z0)} (line {f(r1)} {f(z0)}) (line {f(r1)} {f(z1)}) (line {f(r0)} {f(z1)}) (line {f(r0)} {f(z0)}))'


def fuel_ring_edits():
    ids = J.Ids(300000)
    ring = f'(region {rect_path(32.5, 35.5, 44.0, 47.0)} {rect_path(33.0, 35.0, 44.5, 46.5)})'
    e = [f'(node 3001 (revolve {ring}) {IC})']
    adds, cuts = [], []
    for k in range(6):
        x, y = polar(34.0, 30.0 + 60.0 * k)
        a, b = ids(), ids()
        e += axial_cyl(a, 0.4, x, y, 46.6, 53.0, ids) + axial_cyl(b, 0.2, x, y, 46.0, 53.3, ids)
        adds.append(a)
        cuts.append(b)
    a, b = ids(), ids()
    e += radial_cyl(a, 1.0, 35.2, 55.5, FUEL_PHI, FUEL_Z, ids) + radial_cyl(b, 0.6, 34.2, 55.6, FUEL_PHI, FUEL_Z, ids)
    adds.append(a)
    cuts.append(b)
    ue, n = union_all(3001, adds, ids)
    ce, n2 = cut_all(n, cuts, ids)
    return e + ue + ce + [done(30, n2)]


def lube_tube_edits():
    ids = J.Ids(340000)
    e = radial_cyl(3401, 1.0, 13.2, 55.5, LUBE_PHI, LUBE_Z, ids) + radial_cyl(3402, 0.5, 12.9, 55.6, LUBE_PHI, LUBE_Z, ids)
    return e + [f'(node 3403 (difference 3401 3402) {IR})', done(34, 3403)]


def hexprism(nid, af, z0, z1):
    r = af / 3 ** 0.5
    hx = ' '.join(f'(line {f(r * math.cos(math.pi / 3 * k))} {f(r * math.sin(math.pi / 3 * k))})' for k in range(1, 6)) + f' (line {f(r)} 0.0)'
    return f'(node {nid} (prism {f(z0)} {f(z1)} (region (path {f(r)} 0.0 {hx}))) {IC})'


def m5_body(nid, fit, ids):
    rc = T.ext_tooth(5.0, 0.8, T.ES_6G[5.0])[0]
    c = ids()
    return J.cyl(c, rc, 0.0, fit.L) + [T.ext_helix(nid, 5.0, fit.z0, fit.z1 - fit.z0, IC)], c


def glow_edits():
    ids = J.Ids(310000)
    hx = ids()
    e = [hexprism(hx, 8.0, -4.0, 0.0)]
    th = ids()
    be, core = m5_body(th, GLOW, ids)
    e += be
    el, term = ids(), ids()
    e += J.cyl(el, 1.1, GLOW.L - 0.1, 15.5) + J.cyl(term, 1.5, -6.0, -3.9)
    ue, n = union_all(hx, [core, th, el, term], ids)
    pe, placed = J.place(n, J_GLOW.frames[0], ids)
    return e + ue + pe + [done(31, placed)]


def adapter_edits():
    ids = J.Ids(360000)
    hx = ids()
    e = [hexprism(hx, 7.0, -3.0, 0.0)]
    th = ids()
    be, core = m5_body(th, ADAPTER, ids)
    e += be
    barb, bore, sock = ids(), ids(), ids()
    e += J.cyl(barb, 1.5, -9.0, -2.9) + J.cyl(bore, 0.6, -9.3, ADAPTER.L + 0.3) + J.cyl(sock, 1.05, 3.0, ADAPTER.L + 0.3)
    ue, n = union_all(hx, [core, th, barb], ids)
    ce, n2 = cut_all(n, [bore, sock], ids)
    e += ue + ce + [done(36, n2)]
    for nid, jt in ((33, J_FUEL), (35, J_LUBE)):
        pe, placed = J.place(36, jt.frames[0], ids)
        e += pe + [done(nid, placed)]
    return e


def screw_edits():
    e = []
    for s in SCREWS:
        e += s.edits()
    return e


SCREW_BASE = 60000


def screw_instances():
    ids = J.Ids(SCREW_BASE)
    e, out = [], []
    for j in JOINTS:
        pe, ns = j.instances(ids)
        e += pe
        out += [(j, k, n) for k, n in enumerate(ns)]
    return e, out


def placement_edits():
    r, top = ring_of(4100, [(13, 360.0 * k / BALL_N) for k in range(BALL_N)])
    return r + [mv(4201, 11, Z_FRONT_BRG), mv(4202, 12, Z_FRONT_BRG), mv(4203, top, Z_FRONT_BRG), mv(4204, 14, Z_FRONT_BRG),
                mv(4211, 11, Z_REAR_BRG), mv(4212, 12, Z_REAR_BRG), mv(4213, top, Z_REAR_BRG), mv(4214, 14, Z_REAR_BRG),
                mv(4221, 16, Z_SPRING), mv(4222, 17, Z_NUT_F), mv(4223, 18, Z_NUT_R), mv(4224, 32, Z_REAR_BRG + B_W)]


def materials():
    ms = [f'(material {n} {g} {rho} {cte!r} {e} {nu})' for n, (g, rho, cte, e, nu) in GRADES.items()]
    for j, k, n in (screw_instances()[1] if JOINTS_ON else []):
        g, rho, cte, e, nu = A286 if j in (J_EXH_CASE, J_NGV_TUNNEL) else A2
        ms.append(f'(material {n} {g} {rho} {cte!r} {e} {nu})')
    return ms


def parts():
    return ([('screws', screw_edits())] if JOINTS_ON else []) + [('shaft', shaft_edits()), ('inner_ring', inner_ring_edits()), ('outer_ring', outer_ring_edits()),
            ('ball', ball_edits()), ('cage', cage_edits()), ('tunnel', tunnel_edits()), ('spring', spring_edits()),
            ('nut_front', nut_edits(17, Z_NUT_F, SHAFT_TH_F[0])), ('nut_rear', nut_edits(18, Z_NUT_R, SHAFT_TH_R[0])),
            ('spacer', spacer_edits()), ('casing', casing_edits()), ('liner', liner_edits()),
            ('impeller', impeller_edits()), ('front_cover', front_cover_edits()), ('diffuser', diffuser_edits()),
            ('ngv', ngv_edits()), ('turbine', turbine_edits()), ('exhaust', exhaust_edits()), ('intake', intake_edits()),
            ('fuel_ring', fuel_ring_edits()), ('lube_tube', lube_tube_edits())] + (
            [('glow_plug', glow_edits()), ('adapters', adapter_edits())] if JOINTS_ON else []) + [('placement', placement_edits())] + (
            [('screw_instances', screw_instances()[0])] if JOINTS_ON else [])


def wsl(*args, timeout=600):
    t0 = time.time()
    p = subprocess.run(['wsl.exe', '-e'] + list(args), capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'), stdin=subprocess.DEVNULL)
    return p.stdout + p.stderr, time.time() - t0


def wpath(fn):
    return '/mnt/' + fn[0].lower() + fn[2:].replace(chr(92), '/')


PORT = int(os.environ.get('G5_PORT', '0'))
REQ = os.path.join(ROOT, '.g5req')


def ask(design, *args, timeout=600):
    import socket
    os.makedirs(REQ, exist_ok=True)
    t0 = time.time()
    fn = os.path.join(REQ, '%d.req' % int(t0 * 1e6))
    open(fn, 'w', newline=chr(10)).write(chr(10).join([f'{WORK}/{design}'] + list(args) + ['<<end>>']) + chr(10))
    wp = wpath(fn)
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
    if sum(len(a) for a in args) < 24000:
        return wsl(BIN, f'{WORK}/{design}', *args, timeout=timeout)
    os.makedirs(REQ, exist_ok=True)
    fn = os.path.join(REQ, '%d.args' % int(time.time() * 1e6))
    open(fn, 'w', encoding='utf-8', newline=chr(10)).write(chr(10).join(args) + chr(10))
    wp = wpath(fn)
    out = wsl('bash', '-c', 'mapfile -t E < "$1"; exec "$2" "$3" "${E[@]}"', '_', wp, BIN, f'{WORK}/{design}', timeout=timeout)
    os.remove(fn)
    return out


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
