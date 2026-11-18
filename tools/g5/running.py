import json
import math
import os
import re
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REC = os.path.join(ROOT, 'docs', 'receipts', 'g5')
sys.path.insert(0, os.path.dirname(__file__))
import jet
from kq import kq, DESIGN

CYC = jet.CYC
OMEGA = CYC['shaft_rpm'] * 2.0 * math.pi / 60.0
T0 = 293.15

TEMP = {
    'impeller': (CYC['T2_K'], 'compressor delivery total temperature, the whole wheel (hottest uniform state)'),
    'front_cover': (288.15, 'ISA intake air, the coldest state of the shroud contour (closes the gap most)'),
    'diffuser': (CYC['T2_K'], 'compressor delivery total temperature'),
    'tunnel': (CYC['T2_K'], 'immersed in compressor delivery air, fuel-oil fed'),
    'shaft': (CYC['T2_K'] + 50.0, 'compressor delivery plus 50 K of heat soak from the turbine end'),
    'turbine': (CYC['inputs']['TIT_K'], 'turbine inlet total temperature, the whole wheel (hottest uniform state)'),
    'ngv': (CYC['T5_K'], 'turbine exit total temperature, the coldest gas washing the shroud (closes the gap most)'),
    'exhaust': (CYC['T5_K'], 'turbine exit total temperature'),
    'casing': (CYC['T2_K'], 'compressor delivery air inside, ambient outside: the inner (hotter) state'),
}
NODE = {'casing': 20, 'impeller': 19, 'front_cover': 23, 'diffuser': 24, 'tunnel': 15, 'shaft': 10, 'turbine': 27, 'ngv': 26, 'exhaust': 28}
Z_ROTOR, Z_STATOR = jet.Z_REAR_BRG + jet.B_W / 2.0, jet.Z_REAR_BRG

PAIRS = [
    dict(rotor='turbine', stator='ngv', rn=[2702], sn=2602, what='turbine blade tip to shroud', dirn='radial', r=32.98, z=170.61),
    dict(rotor='impeller', stator='front_cover', rn=[1903, 1905], sn=2301, what='compressor blade tip to shroud contour', dirn='normal', r=23.34, z=12.0, arc=(33.0, 10.5)),
    dict(rotor='impeller', stator='diffuser', rn=[1901], sn=2401, what='impeller rim to diffuser step (radial)', dirn='radial', r=34.0, z=26.96),
    dict(rotor='impeller', stator='diffuser', rn=[1901], sn=2401, what='impeller back face to diffuser disc (axial)', dirn='axial', r=20.0, z=27.5, sign=1.0, key='impeller/diffuser'),
    dict(rotor='impeller', stator='tunnel', rn=[1901], sn=1501, what='impeller hub to tunnel front face (axial)', dirn='axial', r=10.5, z=28.01, sign=1.0),
    dict(rotor='turbine', stator='exhaust', rn=[2701], sn=2801, what='turbine disc rim to exhaust cone (axial)', dirn='axial', r=21.5, z=171.5, sign=1.0),
]


def mat(part):
    return jet.STD[jet.grade_name(NODE[part])]


def alpha_mean(m, t_k):
    tf = (t_k - 273.15) * 1.8 + 32.0
    pts = [(70.0, m['alpha'][0][1])] + [(float(a), float(b)) for a, b in m['alpha']]
    if tf <= pts[0][0]:
        return pts[0][1] * 1.8e-6
    for (a, x), (b, y) in zip(pts, pts[1:]):
        if tf <= b:
            return (x + (y - x) * (tf - a) / (b - a)) * 1.8e-6
    if tf > pts[-1][0] + 50.0:
        raise ValueError(f'{t_k} K is beyond the expansion curve of {m["name"]}')
    return pts[-1][1] * 1.8e-6


def si(m):
    return m['rho'] * jet.LBIN3, m['e'] * 1.0e3 * jet.KSI * 1.0e6, m['nu']


def disc_u(m, a, b, t, pull, r):
    rho, E, nu = si(m)
    q = rho * OMEGA ** 2
    P = pull / (2.0 * math.pi * b * t)
    c1, c2 = (3.0 + nu) / 8.0 * q, (1.0 + 3.0 * nu) / 8.0 * q
    B = (P + c1 * (b * b - a * a)) / (1.0 / (a * a) - 1.0 / (b * b))
    A = B / (a * a) + c1 * a * a
    sr = A - B / (r * r) - c1 * r * r
    st = A + B / (r * r) - c2 * r * r
    return r * (st - nu * sr) / E, dict(bore_hoop_MPa=(A + B / (a * a) - c2 * a * a) / 1e6, rim_pull_MPa=P / 1e6)


def blade_stretch(m, rh, rt):
    rho, E, nu = si(m)
    n = 200
    acc = 0.0
    for i in range(n):
        r = rh + (rt - rh) * (i + 0.5) / n
        acc += rho * OMEGA ** 2 * (rt * rt - r * r) / 2.0 / E * (rt - rh) / n
    return acc


def nums(txt):
    return [float(x) for x in re.findall(r'-?\d+\.\d+(?:e-?\d+)?|-?\d+(?:e-?\d+)?', txt)]


def cold():
    out = {}
    for p in PAIRS:
        if p['rotor'] + '/' + p['stator'] in out:
            continue
        best = None
        for rn in p['rn']:
            t = time.time()
            txt = kq('clearance', str(rn), str(p['sn']))
            line = next((ln for ln in txt.splitlines() if ln.startswith('clearance')), txt.strip()[-300:])
            m = re.search(r'\[([-\d.e]+), ([-\d.e]+)\]', line)
            row = dict(rotor_node=rn, stator_node=p['sn'], line=line, lo=float(m.group(1)) if m else None, hi=float(m.group(2)) if m else None,
                       seconds=round(time.time() - t, 1))
            print(p['rotor'], rn, p['stator'], p['sn'], line, row['seconds'], 's', flush=True)
            if best is None or (row['lo'] is not None and (best['lo'] is None or row['lo'] < best['lo'])):
                best = row
        out[p['rotor'] + '/' + p['stator']] = best
    os.makedirs(os.path.join(REC, 'clear'), exist_ok=True)
    json.dump(dict(design=DESIGN, source='bendcad clearance between one rotor blade (or the rotor revolve) and the stator surface of revolution facing it: the stator wall is axisymmetric, so the certified gap of one blade is the gap of every blade at every rotor angle', pairs=out),
              open(os.path.join(REC, 'clear', 'cold.json'), 'w'), indent=1)


def growth(part, r, z):
    m = mat(part)
    t, why = TEMP[part]
    a = alpha_mean(m, t)
    dr = r * a * (t - T0)
    rot = part in ('impeller', 'turbine', 'shaft')
    if rot:
        dz = (z - Z_ROTOR) * alpha_mean(mat('shaft'), TEMP['shaft'][0]) * (TEMP['shaft'][0] - T0)
    elif part in ('exhaust', 'casing'):
        zf = jet.Z_CASE0 + 2.0
        dz = ((38.5 - Z_STATOR) * alpha_mean(mat('tunnel'), TEMP['tunnel'][0]) * (TEMP['tunnel'][0] - T0)
              + (z - zf) * alpha_mean(mat('casing'), TEMP['casing'][0]) * (TEMP['casing'][0] - T0))
    else:
        dz = (z - Z_STATOR) * alpha_mean(mat('tunnel'), TEMP['tunnel'][0]) * (TEMP['tunnel'][0] - T0)
    cf, info = 0.0, {}
    if part == 'turbine':
        bl = json.load(open(os.path.join(REC, 'clear', 'blades.json')))['turbine']
        pull = jet.TUR_N * si(m)[0] * bl['volume_mm3'] * 1e-9 * OMEGA ** 2 * bl['centroid_r_mm'] * 1e-3
        u, info = disc_u(m, 4.0e-3, 21.5e-3, 9.0e-3, pull, 21.5e-3)
        cf = u * 1e3 + blade_stretch(m, 21.5e-3, r * 1e-3) * 1e3
        info.update(blade_pull_N=pull)
    if part == 'impeller':
        bl = json.load(open(os.path.join(REC, 'clear', 'blades.json')))['impeller']
        pull = 6 * si(m)[0] * (bl['volume_mm3'] + bl['splitter_mm3']) * 1e-9 * OMEGA ** 2 * bl['centroid_r_mm'] * 1e-3
        u, info = disc_u(m, 4.0e-3, 33.0e-3, 26.0e-3, 0.0, min(r, 33.0) * 1e-3)
        cf = u * 1e3
        info.update(note='hub as a rotating annular disc a=4 b=33 t=26 mm; blades as distributed mass in the disc (pull not applied as rim load)', blade_pull_N=pull)
    return dict(dr_thermal=dr, dr_spin=cf, dz=dz, T_K=t, T_basis=why, alpha_mean_per_K=a, **info)


def run():
    cd = json.load(open(os.path.join(REC, 'clear', 'cold.json')))['pairs']
    rows, ok = [], True
    for p in PAIRS:
        key = p.get('key', p['rotor'] + '/' + p['stator'])
        c = cd[key]
        gr = growth(p['rotor'], p['r'], p['z'])
        gs = growth(p['stator'], p['r'], p['z'])
        if p['dirn'] == 'radial':
            close = (gr['dr_thermal'] + gr['dr_spin']) - gs['dr_thermal']
        elif p['dirn'] == 'axial':
            close = p['sign'] * (gr['dz'] - gs['dz'])
        else:
            cr, cz = p['arc']
            vr, vz = p['r'] - cr, p['z'] - cz
            L = math.hypot(vr, vz)
            nr, nz = -vr / L, -vz / L
            close = nr * ((gr['dr_thermal'] + gr['dr_spin']) - gs['dr_thermal']) + nz * (gr['dz'] - gs['dz'])
        run_gap = c['lo'] - close
        good = run_gap > 0.0
        ok &= good
        rows.append(dict(pair=p['what'], rotor=p['rotor'], stator=p['stator'], cold_certified_mm=[c['lo'], c['hi']], closure_mm=round(close, 4),
                         running_mm=round(run_gap, 4), status='pass' if good else 'fail', rotor_growth=gr, stator_growth=gs,
                         basis='COMPUTED: cold gap certified by the kernel; growth from MIL-HDBK-5J mean expansion at the stated temperature and rotating-disc theory (Timoshenko) at ' + str(CYC['shaft_rpm']) + ' r/min'))
        print(f"{p['what']:45s} cold {c['lo']:.4f} closure {close:+.4f} running {run_gap:.4f} {'pass' if good else 'FAIL'}", flush=True)
    rep = dict(source='tools/g5/running.py + bendcad clearance', design=DESIGN, rpm=CYC['shaft_rpm'], ok=ok, rows=rows,
               datums=dict(rotor_axial_z=Z_ROTOR, stator_axial_z=Z_STATOR, why='the rear bearing outer ring seats on the tunnel shoulder at z=138; the front bearing floats on the preload spring'))
    os.makedirs(os.path.join(REC, 'running'), exist_ok=True)
    json.dump(rep, open(os.path.join(REC, 'running', 'running.json'), 'w'), indent=1)


if __name__ == '__main__':
    {'cold': cold, 'run': run}[sys.argv[1]]()
