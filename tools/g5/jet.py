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
    (21, 'X5CrNi18-10', 7900, 1.6e-5, 200000, 0.29),
    (22, 'NiCr22Mo9Nb', 8440, 1.28e-5, 205000, 0.31),
    (19, 'AlZn5.5MgCu-T6', 2810, 2.36e-5, 71700, 0.33),
]

R_CASE_O, T_CASE, Z_CASE0, Z_CASE1 = 54.0, 0.8, 20.0, 175.0
R_NOZ_IN, R_NOZ_OUT, Z_NOZ1 = R_CASE_O - T_CASE, 23.2, 230.0
R_LIN_I, R_LIN_O, T_LIN, Z_LIN0, Z_LIN1 = 22.0, 46.0, 0.5, 60.0, 150.0

Z_TUN0, Z_TUN1 = Z_FRONT_BRG - 4.0, Z_REAR_BRG + B_W + 3.0
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
    z0 = B_W / 2 - CAGE_W / 2
    p = [f'{f(CAGE_RI)} {f(z0)}', f'(line {f(CAGE_RO)} {f(z0)})', f'(line {f(CAGE_RO)} {f(z0 + CAGE_W)})',
         f'(line {f(CAGE_RI)} {f(z0 + CAGE_W)})', f'(line {f(CAGE_RI)} {f(z0)})']
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
    hx = ' '.join(f'(line {f(r * math.cos(math.pi / 3 * k))} {f(r * math.sin(math.pi / 3 * k))})' for k in range(1, 7))
    return [f'(node {nid}1 (prism 0.0 {f(h)} (region (path {f(r)} 0.0 {hx}) (circle 0.0 0.0 {f(R_JOURNAL - 0.65)}))) {IC})',
            f'(node {nid} (move {nid}1 0.0 0.0 0.0 0) {IS})']


def ring_rev(r0, r1, z0, z1):
    return region(f'{f(r0)} {f(z0)}', f'(line {f(r1)} {f(z0)})', f'(line {f(r1)} {f(z1)})', f'(line {f(r0)} {f(z1)})', f'(line {f(r0)} {f(z0)})')


def casing_edits():
    return [f'(node 20 (revolve {ring_rev(R_CASE_O - T_CASE, R_CASE_O, Z_CASE0, Z_CASE1)}) {IC})']


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
    ln += 1.6
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
           f'(line {f(34.0)} {f(z0 + 26.5)})', f'(line {f(12.0)} {f(z0 + 26.5)})', f'(line {f(12.0)} {f(z0 + 30)})',
           f'(line {f(4.0)} {f(z0 + 30)})', f'(line {f(4.0)} {f(z0 - 2)})']
    env = [f'0.0 {f(z0 - 3)}', f'(line {f(IMP_RS1 - 0.5 - g)} {f(z0 - 3)})', f'(line {f(IMP_RS1 - g)} {f(z0 + 9.5)})',
           f'(arc {f(IMP_R2)} {f(z0 + 9.5)} {f(9.5 + g)} {f(IMP_R2)} {f(z0 + 19 + g)} cw)',
           f'(line {f(IMP_R2)} {f(z0 + 31)})', f'(line 0.0 {f(z0 + 31)})', f'(line 0.0 {f(z0 - 3)})']
    main = ' '.join(imp_sec(-0.03 + (1.013 + 0.03) * i / 10, -0.03) for i in range(11))
    spl = ' '.join(imp_sec(0.35 + (1.013 - 0.35) * i / 8, 0.35) for i in range(9))
    e = [f'(node 1901 (revolve {region(*hub)}) {IC})', f'(node 1902 (revolve {region(*env)}) {IC})',
         f'(node 1903 (skin {main}) {IC})', f'(node 1904 (skin {spl}) {IC})', f'(node 1905 (rotate 1904 z 30.0) {IS})']
    prev = 1901
    for k in range(6):
        for j, src in enumerate((1903, 1905)):
            bid = 1910 + 2 * k + j
            e.append(f'(node {bid} (rotate {src} z {f(60.0 * k)}) {IS})')
            e.append(f'(node {bid + 20} (union {prev} {bid}) {IA})')
            prev = bid + 20
    e.append(f'(node 19 (intersection {prev} 1902) {IR})')
    return e


def materials():
    return [f'(material {n} {g} {rho} {cte!r} {e} {nu})' for n, g, rho, cte, e, nu in MATERIALS]


def parts():
    return [('shaft', shaft_edits()), ('inner_ring', inner_ring_edits()), ('outer_ring', outer_ring_edits()),
            ('ball', ball_edits()), ('cage', cage_edits()), ('tunnel', tunnel_edits()), ('spring', spring_edits()),
            ('nut_front', nut_edits(17)), ('nut_rear', nut_edits(18)),
            ('casing', casing_edits()), ('nozzle', nozzle_edits()), ('liner', liner_edits()),
            ('impeller', impeller_edits())]


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
