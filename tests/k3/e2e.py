import json
import math
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'e2e-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-k3'
RESULTS = []
PI = math.pi

IC = '(intent create any any any any)'
IS = '(intent same any any any any)'
IA = '(intent add any any any any)'
ID = '(intent remove any any any any)'
NUM = r'(-?[0-9.]+(?:e-?[0-9]+)?)'
IVR = r'\[' + NUM + r', ' + NUM + r'\]'


def wsl(*args, timeout=1800):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    env = dict(os.environ, MSYS_NO_PATHCONV='1', BEND_NO_TELEMETRY='1')
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout, env=env)
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if not ok})


def moments(design, node):
    out, dt = cli(design, 'mass', str(node))
    m = re.search(r'moments volume=' + IVR + r' centroid ' + IVR + 'x' + IVR + 'x' + IVR + r' inertia-centroid ' +
                  ' '.join([IVR] * 6) + r' status=certified', out)
    if not m:
        return None, out, dt
    g = [float(x) for x in m.groups()]
    ivs = [(g[i], g[i + 1]) for i in range(0, len(g), 2)]
    return dict(vol=ivs[0], c=ivs[1:4], i=ivs[4:10]), out, dt


def has(iv, x, rel=0.0):
    tol = rel * max(1.0, abs(x))
    return iv is not None and iv[0] - tol <= x <= iv[1] + tol


def tight(iv, x, rel, scale=1.0):
    return has(iv, x) and iv[1] - iv[0] <= rel * max(scale, abs(x))


def all_tight(mo, vol, c, ii, rel):
    big = max(abs(v) for v in ii[:3])
    return (mo is not None and tight(mo['vol'], vol, rel) and all(tight(mo['c'][k], c[k], rel) for k in range(3))
            and all(tight(mo['i'][k], ii[k], rel, big) for k in range(6)))


def closed(name, design, edits, node, vol, c, ii, rel=1e-9):
    out, _ = fresh(design, *edits)
    mo, raw, dt = moments(design, node)
    record(name, 'committed' in out and all_tight(mo, vol, c, ii, rel), got=mo, want=dict(vol=vol, c=c, i=ii),
           seconds=dt, raw=raw[-400:])


def occt(stp):
    code = ('from build123d import import_step\n'
            f's=import_step("{stp}")\n'
            'so=s.solids()[0]\n'
            'from OCP.GProp import GProp_GProps\n'
            'from OCP.BRepGProp import BRepGProp\n'
            'g=GProp_GProps()\n'
            'BRepGProp.VolumeProperties_s(so.wrapped,g,1e-12,True)\n'
            'c=g.CentreOfMass()\n'
            'm=g.MatrixOfInertia()\n'
            'print(g.Mass(),c.X(),c.Y(),c.Z(),m.Value(1,1),m.Value(2,2),m.Value(3,3),m.Value(1,2),m.Value(1,3),m.Value(2,3))\n')
    out, _ = wsl('python3', '-c', code)
    try:
        return [float(x) for x in out.split()[-10:]]
    except ValueError:
        return None


def against_occt(name, design, edits, node, rel):
    out, _ = fresh(design, *edits)
    mo, raw, dt = moments(design, node)
    cli(design, 'step', str(node), f'{WORK}/{design}.stp')
    o = occt(f'{WORK}/{design}.stp')
    ok = mo is not None and o is not None and has(mo['vol'], o[0], rel) and all(has(mo['c'][k], o[1 + k], rel) for k in range(3))
    if ok:
        want_i = [o[4], o[5], o[6], o[7], o[8], o[9]]
        ok = all(has(mo['i'][k], want_i[k], rel) for k in range(6))
    record(name, 'committed' in out and ok, got=mo, occt=o, seconds=dt, raw=raw[-400:])


def bal(design, node, axis, rpm, g):
    out, dt = cli(design, 'balance', str(node), *[repr(float(x)) for x in axis], repr(float(rpm)), repr(float(g)))
    m = re.search(r'balance mass=' + IVR + r' kg offset=' + IVR + r' mm residual=' + IVR + r' g\.mm permissible=' + IVR +
                  r' g\.mm .*?products=' + IVR + r' kg\.mm2 (within|exceeds|undecided) status=(\w+)', out)
    if not m:
        return None, out
    g_ = m.groups()
    iv = lambda k: (float(g_[2 * k]), float(g_[2 * k + 1]))
    return dict(m=iv(0), e=iv(1), u=iv(2), up=iv(3), pr=iv(4), verdict=g_[10], status=g_[11]), out


def balance():
    rho, rpm, g = 2700.0, 2900.0, 2.5
    w = rpm * 2 * PI / 60
    ad = PI * 50 * 50
    out, _ = fresh('bd.bcd', f'(node 1 (cylinder 50 10) {IC})', '(node 2 (move 1 0.005 0 0 0) (intent same 0 0 1 0))',
                   f'(material 2 6082-T6 {rho} 0.0000234)')
    b, raw = bal('bd.bcd', 2, [0, 0, 0, 0, 0, 1], rpm, g)
    mk = ad * 10 * rho * 1e-9
    record('balance.offset_disc', 'committed' in out and b is not None and has(b['e'], 0.005, 1e-9) and has(b['m'], mk, 1e-9)
           and has(b['u'], mk * 1000 * 0.005, 1e-9) and has(b['up'], mk * 1000 * g / w, 1e-9) and b['verdict'] == 'within'
           and b['status'] == 'certified' and b['pr'][1] <= 1e-4 * mk * 2500, got=b, raw=raw[-400:])
    ah = PI * 5 * 5
    e = ah * 20 / (ad - ah)
    out, _ = fresh('bh.bcd', f'(node 1 (cylinder 50 10) {IC})',
                   f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 20 0 5))) {ID})', f'(material 2 6082-T6 {rho} 0.0000234)')
    b, raw = bal('bh.bcd', 2, [0, 0, 0, 0, 0, 1], rpm, g)
    mk = (ad - ah) * 10 * rho * 1e-9
    record('balance.drilled_disc', 'committed' in out and b is not None and has(b['e'], e, 1e-7) and has(b['u'], mk * 1000 * e, 1e-7)
           and b['verdict'] == 'exceeds' and b['status'] == 'certified' and b['pr'][0] <= 1e-9 * mk * 2500, got=b, want_e=e, raw=raw[-400:])
    o, _ = cli('bh.bcd', 'balance', '2', '0', '0', '0', '0', '0', '0', '2900', '2.5')
    o2, _ = cli('bd.bcd', 'balance', '1', '0', '0', '0', '0', '0', '1', '2900', '2.5')
    record('balance.refusals', 'non-zero axis' in o and 'node-has-no-material' in o2, axis=o[-200:], nomat=o2[-200:])


def rotor_run(spec):
    out, _ = cli('b.bcd', 'rotor', spec)
    rs = [(float(m.group(1)), float(m.group(2)), float(m.group(3)))
          for m in re.finditer(r'rpm=' + IVR + r' extrapolated=' + NUM, out)]
    return rs, out


def kap(nu):
    return 6 * (1 + nu) / (7 + 6 * nu)


def ss_timo(L, D, E, nu, rho, n):
    A, I, G = PI * D * D / 4, PI * D ** 4 / 64, E / (2 * (1 + nu))
    k = n * PI / L
    rt = rho * 1e-12
    a = rt * rt * I / (kap(nu) * G)
    b = -(rt * A + rt * I * k * k * (1 + E / (kap(nu) * G)))
    c = E * I * k ** 4
    w2 = (-b - math.sqrt(b * b - 4 * a * c)) / (2 * a)
    return math.sqrt(w2) * 60 / (2 * PI)


def within(r, x):
    return r is not None and r[0] - 1e-6 * abs(x) <= x <= r[1] + 1e-6 * abs(x) and abs(r[2] - x) <= 1e-4 * abs(x)


def rotor():
    E, nu, rho, K = 210000.0, 0.3, 7850.0, 1e13
    for name, L, D in (('rotor.pinned_slender', 1000.0, 20.0), ('rotor.pinned_thick', 200.0, 50.0)):
        rs, out = rotor_run(f'(rotor (seg {L} {D} 0 {E} {nu} {rho}) (brg 0 {K} 0) (brg {L} {K} 0) (n 8) (modes 2))')
        want = [ss_timo(L, D, E, nu, rho, 1), ss_timo(L, D, E, nu, rho, 2)]
        record(name, len(rs) == 2 and all(within(r, w) for r, w in zip(rs, want)), got=rs, want=want, raw=out[-500:])
    L, D, m = 500.0, 20.0, 10.0
    A, I, G = PI * D * D / 4, PI * D ** 4 / 64, E / (2 * (1 + nu))
    delta = L ** 3 / (48 * E * I) + L / (4 * kap(nu) * G * A)
    wj = math.sqrt(1 / (m * 1e-3 * delta)) * 60 / (2 * PI)
    rs, out = rotor_run(f'(rotor (seg {L/2} {D} 0 {E} {nu} 1e-6) (seg {L/2} {D} 0 {E} {nu} 1e-6) (brg 0 {K} 0) (brg {L} {K} 0) (disc {L/2} {m} 0) (n 4) (modes 1))')
    record('rotor.jeffcott', len(rs) == 1 and within(rs[0], wj), got=rs, want=wj, raw=out[-400:])
    L, D, m, jd = 150.0, 30.0, 5.0, 1e4
    A, I = PI * D * D / 4, PI * D ** 4 / 64
    ph = 12 * E * I / (kap(nu) * G * A * L * L)
    f = E * I / ((1 + ph) * L ** 3)
    k11, k12, k22 = 12 * f, -6 * L * f, (4 + ph) * L * L * f
    mm, jj = m * 1e-3, jd * 1e-3
    a, b, c = mm * jj, -(k11 * jj + k22 * mm), k11 * k22 - k12 * k12
    w1 = math.sqrt((-b - math.sqrt(b * b - 4 * a * c)) / (2 * a)) * 60 / (2 * PI)
    rs, out = rotor_run(f'(rotor (seg {L} {D} 0 {E} {nu} 1e-6) (brg 0 {K} {K * 1e4}) (disc {L} {m} {jd}) (n 4) (modes 1))')
    record('rotor.overhung_disc', len(rs) == 1 and within(rs[0], w1), got=rs, want=w1, raw=out[-400:])
    o, _ = cli('b.bcd', 'rotor', '(rotor (seg 100 20 0 210000 0.3 7850) (disc 50 1 0) (brg 0 1e9 0))')
    record('rotor.refusal_off_node', 'error invalid-input | rotor' in o, raw=o[-300:])


def fem_lines(out, key):
    return [(float(m.group(1)), float(m.group(2)), float(m.group(3)), float(m.group(4)), float(m.group(5)), m.group(6))
            for m in re.finditer(key + r' ?\[' + NUM + ', ' + NUM + ', ' + NUM + r'\] est=' + NUM + ' bound=' + NUM + r' status=(\S+)', out)]


def lamb(E, nu, rho, a, x):
    cs = math.sqrt(E / (2 * (1 + nu)) / (rho * 1e-12))
    return x * cs / (2 * PI * a)


def fem():
    E, nu, rho = 200000.0, 0.3, 7850.0
    out, _ = fresh('fs.bcd', f'(node 1 (sphere 10) {IC})', f'(material 1 steel {rho} 0.000012 {E} {nu})')
    o, dt = wsl(BIN, f'{WORK}/fs.bcd', 'modes', '1', '10', '4', timeout=7200)
    ms = fem_lines(o, r'mode \d+ hz=')
    want = [lamb(E, nu, rho, 10.0, 2.501133)] * 5 + [lamb(E, nu, rho, 10.0, 2.646217)] * 5
    record('modes.free_sphere_lamb', 'committed' in out and len(ms) == 10 and 'rigid=6' in o
           and all(abs(m[3] - w) <= m[4] and m[4] <= 2e-3 * w for m, w in zip(ms, want)),
           got=[(m[2], m[3], m[4]) for m in ms], want=want, seconds=dt, raw=o[-900:])
    o, dt = wsl(BIN, f'{WORK}/fs.bcd', 'spin', '1', '60000', '4', '0', '0', '0', '0', '0', '1', '0', timeout=7200)
    wk = fem_lines(o, 'work_nmm')
    exact = 1.4629528959588416
    record('spin.free_sphere_chree', len(wk) == 1 and abs(wk[0][3] - exact) <= wk[0][4] and wk[0][4] <= 1e-3 * exact
           and all(x <= exact * (1 + 1e-9) for x in wk[0][:3]), got=wk, want=exact, seconds=dt, raw=o[-900:])
    out, _ = fresh('fn.bcd', f'(node 1 (sphere 10) {IC})', f'(material 1 steel {rho} 0.000012)')
    o1, _ = cli('fn.bcd', 'modes', '1', '5', '3')
    o2, _ = cli('fs.bcd', 'modes', '1', '0', '3')
    o3, _ = cli('fs.bcd', 'spin', '1', '60000', '3', '0', '0', '0', '0', '0', '0', '1')
    out4, _ = fresh('fo.bcd', f'(node 1 (box 10 10 10) {IC})', '(node 2 (move 1 20 0 0 0) (intent same 0 0 1 0))',
                    f'(material 2 steel {rho} 0.000012 {E} {nu})')
    o4, _ = wsl(BIN, f'{WORK}/fo.bcd', 'spin', '2', '60000', '4', '0', '0', '0', '0', '0', '1', '0', timeout=3600)
    o5, _ = cli('fs.bcd', 'apply', f'(material 1 steel {rho} 0.000012 {E} 0.6)')
    record('fem.refusals', 'material-lacks-elastic-constants' in o1 and 'needs NODE K H' in o2 and 'needs NODE RPM H' in o3
           and 'refused spin-unsupported' in o4 and 'bad-material' in o5,
           noel=o1[-200:], k0=o2[-200:], axis0=o3[-200:], offaxis=o4[-300:], nu=o5[-300:])


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    v = 6000.0
    closed('box', 'b.bcd', [f'(node 1 (box 10 20 30) {IC})'], 1, v, [5, 10, 15],
           [v * (400 + 900) / 12, v * (100 + 900) / 12, v * (100 + 400) / 12, 0, 0, 0])
    vc = 250 * PI
    closed('cylinder', 'c.bcd', [f'(node 1 (cylinder 5 10) {IC})'], 1, vc, [0, 0, 5],
           [vc * (3 * 25 + 100) / 12, vc * (3 * 25 + 100) / 12, vc * 25 / 2, 0, 0, 0], 1e-5)
    vs = 4 * PI * 64 / 3
    closed('sphere', 's.bcd', [f'(node 1 (sphere 4) {IC})'], 1, vs, [0, 0, 0], [0.4 * vs * 16] * 3 + [0, 0, 0], 3e-4)
    vt = 2 * PI * PI * 30 * 100
    closed('torus', 't.bcd', [f'(node 1 (torus 30 10) {IC})'], 1, vt, [0, 0, 0],
           [vt * (900 / 2 + 5 * 100 / 8), vt * (900 / 2 + 5 * 100 / 8), vt * (900 + 3 * 100 / 4), 0, 0, 0], 2e-6)
    hv = 6000.0 - PI * 4 * 30
    cx = (6000.0 * 5 - PI * 4 * 30 * 3) / hv
    cy = (6000.0 * 10 - PI * 4 * 30 * 6) / hv
    out, _ = fresh('h.bcd', f'(node 1 (box 10 20 30) {IC})',
                   f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 3 6 2))) {ID})')
    mo, raw, dt = moments('h.bcd', 2)
    record('box.off_centre_hole', 'committed' in out and mo is not None and tight(mo['vol'], hv, 1e-8)
           and tight(mo['c'][0], cx, 3e-8) and tight(mo['c'][1], cy, 1e-8) and tight(mo['c'][2], 15.0, 3e-9),
           got=mo, want=dict(vol=hv, cx=cx, cy=cy), raw=raw[-400:])
    out, _ = fresh('m.bcd', f'(node 1 (box 10 20 30) {IC})', '(node 2 (move 1 7 -3 2 4) (intent same 0 0 1 0))')
    mo, raw, dt = moments('m.bcd', 2)
    ev, _ = cli('m.bcd', 'eval')
    bb = re.search(r'node 2:.*?bbox=' + IVR + 'x' + IVR + 'x' + IVR, ev)
    centre = [(float(bb.group(2 * k + 1)) + float(bb.group(2 * k + 2))) / 2 for k in range(3)] if bb else None
    record('box.moved_turned', mo is not None and centre is not None and all(tight(mo['c'][k], centre[k], 1e-9) for k in range(3))
           and sorted(round((x[0] + x[1]) / 2) for x in mo['i'][:3]) == [250000, 500000, 650000],
           got=mo, bbox_centre=centre, raw=raw[-400:])
    against_occt('fillet.hole', 'f.bcd', [f'(node 1 (box 20 20 10) {IC})',
                 f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 10 10 3))) {ID})',
                 f'(node 3 (fillet 2 (face 2 n1.c0.top) (circle 10 10 3) 1) {ID})'], 3, 1e-7)
    against_occt('sphere.cut_by_box', 'sb.bcd', [f'(node 1 (box 10 10 10) {IC})', f'(node 2 (sphere 4) {IC})',
                 '(node 3 (move 2 5 5 9 0) (intent same 0 0 1 0))', f'(node 4 (difference 1 3) {ID})'], 4, 1e-7)
    against_occt('cone.revolve', 'cn.bcd', [f'(node 1 (revolve (region (path 0 0 (line 4 0) (line 1 6) (line 0 6)))) {IC})',
                 '(node 2 (move 1 3 2 1 0) (intent same 0 0 1 0))'], 2, 1e-8)
    balance()
    rotor()
    fem()
    json.dump(RESULTS, open(OUT, 'w'), indent=1)
    n = sum(1 for r in RESULTS if r['ok'])
    print(f'{n}/{len(RESULTS)} passed')
    sys.exit(0 if n == len(RESULTS) else 1)


if __name__ == '__main__':
    main()
