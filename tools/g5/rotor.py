import json
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
import jet
from kq import kq, DESIGN, BIN

REC = os.path.join(jet.ROOT, 'docs', 'receipts', 'g5')
CYC = jet.CYC
RPM = CYC['shaft_rpm']
PRELOAD_N = 40.0
NUM = r'(-?\d+(?:\.\d+)?(?:e-?\d+)?)'


def hertz_ball_stiffness():
    b = jet.BEARING
    Z, D, a = b['balls'], b['ball_d'], math.radians(b['contact_deg'])
    st, sn = jet.BRG['materials']['BEARING-STEEL'], jet.BRG['materials']['SI3N4']
    Ep = 2.0 / ((1 - st['nu'] ** 2) / st['E_MPa'] + (1 - sn['nu'] ** 2) / sn['E_MPa'])
    dm = 2.0 * jet.PITCH_R
    f = jet.GROOVE_R / D
    Q = PRELOAD_N / (Z * math.sin(a))
    qa = math.pi / 2.0 - 1.0
    cs = []
    for rx in (D * (dm - D * math.cos(a)) / (2.0 * dm), D * (dm + D * math.cos(a)) / (2.0 * dm)):
        ry = f * D / (2.0 * f - 1.0)
        R = 1.0 / (1.0 / rx + 1.0 / ry)
        ar = ry / rx
        k = ar ** (2.0 / math.pi)
        Ee = 1.0 + qa / ar
        F = math.pi / 2.0 + qa * math.log(ar)
        delta = F * ((9.0 / (2.0 * Ee * R)) * (Q / (math.pi * k * Ep)) ** 2) ** (1.0 / 3.0)
        cs.append(dict(Rx=rx, Ry=ry, k=k, delta_mm=delta, k_N_per_mm=1.5 * Q / delta))
    kn = 1.0 / sum(1.0 / c['k_N_per_mm'] for c in cs)
    kr = 0.5 * Z * kn * math.cos(a) ** 2
    return dict(method='Hertz elliptical point contact, Hamrock-Brewe approximations for ellipticity and elliptic integrals; inner and outer contacts in series; radial stiffness 0.5 Z k_n cos^2(alpha) of an axially preloaded bearing (Harris and Kotzalas, Rolling Bearing Analysis)',
                preload_N=PRELOAD_N, preload_basis='PROJECTED: design preload of the spring', ball_normal_load_N=Q, E_prime_MPa=Ep, conformity=f,
                contacts=dict(inner=cs[0], outer=cs[1]), k_n_N_per_mm=kn, k_radial_N_per_mm=kr)


def moments(node):
    out = kq('mass', str(node), '0')
    m = re.search(r'moments volume=\[' + NUM + ', ' + NUM + r'\] centroid \[' + NUM + ', ' + NUM + r'\]x\[' + NUM + ', ' + NUM + r'\]x\[' + NUM + ', ' + NUM + r'\] inertia-centroid \[' + NUM + ', ' + NUM + r'\] \[' + NUM + ', ' + NUM + r'\] \[' + NUM + ', ' + NUM + r'\]', out)
    if not m:
        raise RuntimeError(f'node {node}: no moments line: {out[-300:]}')
    v = [float(x) for x in m.groups()]
    return dict(volume=(v[0] + v[1]) / 2, cz=(v[6] + v[7]) / 2, ixx=(v[8] + v[9]) / 2, iyy=(v[10] + v[11]) / 2, izz=(v[12] + v[13]) / 2, raw=out.strip().splitlines()[-1][:300])


def run():
    st = jet.STD['17-4PH-H1075']
    E, nu, rho = st['e'] * 1000.0 * jet.KSI, st['nu'], st['rho'] * jet.LBIN3
    rc = jet.T.ext_tooth(8.0, 1.0, jet.T.ES_6G[8.0])[0]
    prof = [(jet.Z_NOSE, -1.0, 2 * rc), (-1.0, jet.Z_SPRING, 2 * jet.R_JOURNAL), (jet.Z_SPRING, jet.Z_REAR_BRG, 2 * jet.R_SPACER),
            (jet.Z_REAR_BRG, jet.Z_NUT_R, 2 * jet.R_JOURNAL), (jet.Z_NUT_R, jet.Z_TAIL, 2 * rc)]
    discs = []
    prev = os.path.join(REC, 'modes', 'rotor.json')
    old = {d['node']: d['moments'] for d in json.load(open(prev))['discs']} if os.environ.get('G5_ROTOR_REUSE') and os.path.exists(prev) else {}
    for name, node in (('impeller', 19), ('turbine', 27)):
        mo = old.get(node) or moments(node)
        dens = jet.density(node)
        m_kg = mo['volume'] * 1e-9 * dens
        jd = 0.5 * (mo['ixx'] + mo['iyy']) * 1e-9 * dens
        discs.append(dict(name=name, node=node, z=round(mo['cz'], 6), m_kg=m_kg, jd_kg_mm2=jd, moments=mo))
    bs = hertz_ball_stiffness()
    zs = sorted({z for a, b, _ in prof for z in (a, b)} | {d['z'] for d in discs} | {jet.Z_FRONT_BRG + jet.B_W / 2, jet.Z_REAR_BRG + jet.B_W / 2})
    segs = []
    for z0, z1 in zip(zs, zs[1:]):
        od = next(d for a, b, d in prof if a - 1e-9 <= z0 and z1 <= b + 1e-9)
        segs.append(f'(seg {z1 - z0!r} {od!r} 0 {E!r} {nu!r} {rho!r})')
    x0 = zs[0]
    spec = '(rotor ' + ' '.join(segs) + ' ' + ' '.join(f"(disc {d['z'] - x0!r} {d['m_kg']!r} {d['jd_kg_mm2']!r})" for d in discs) + ' ' + \
        ' '.join(f"(brg {z - x0!r} {bs['k_radial_N_per_mm']!r} 0)" for z in (jet.Z_FRONT_BRG + jet.B_W / 2, jet.Z_REAR_BRG + jet.B_W / 2)) + ' (n 8) (modes 3))'
    out = kq('rotor', spec)
    crit = [float(m.group(3)) for m in re.finditer(r'critical \d+ rpm=\[' + NUM + ', ' + NUM + r'\] extrapolated=' + NUM, out)]
    rows = [dict(rpm_est=c, ratio_to_design=c / RPM) for c in crit]
    near = [r for r in rows if abs(r['ratio_to_design'] - 1.0) < 0.15]
    rep = dict(source='bendcad rotor (Timoshenko beam elements, Sturm-count bisection, N/2N/4N refinement with extrapolated bound)', binary=BIN, design=DESIGN,
               shaft_material='17-4PH-H1075 (MIL-HDBK-5J Table 2.6.9.0(d))', discs=discs, bearing=bs, spec=spec, raw=out.strip()[-1500:],
               critical_speeds_rpm=crit, design_rpm=RPM, within_15pct=near,
               note='bearing stiffness COMPUTED from Hertz contact at the stated spring preload; disc mass and diametral inertia from the kernel moments and the cited density; shaft as the stepped revolve of jet.py')
    os.makedirs(os.path.join(REC, 'modes'), exist_ok=True)
    json.dump(rep, open(os.path.join(REC, 'modes', 'rotor.json'), 'w'), indent=1)
    print('critical speeds', crit, 'design', RPM, 'near', near)


if __name__ == '__main__':
    run()
