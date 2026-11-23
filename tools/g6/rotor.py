import json
import math
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
import humphrey as H
import asm as ASM

REC = os.path.join(H.ROOT, 'docs', 'receipts', 'g6')
J5 = H.J5
PRELOAD_N = 60.0
NUM = r'(-?\d+(?:\.\d+)?(?:e-?\d+)?)'
G_BAL = 2.5
PAIR = float(os.environ.get('G6_FRONT_PAIR', repr(H.Z_BRG_F2 - H.Z_BRG_F)))


def stiffness():
    D, a, Z = H.B_BALL, math.radians(H.BEARING['contact_deg']), H.B_N
    st, sn = J5.BRG['materials']['BEARING-STEEL'], J5.BRG['materials']['SI3N4']
    Ep = 2.0 / ((1 - st['nu'] ** 2) / st['E_MPa'] + (1 - sn['nu'] ** 2) / sn['E_MPa'])
    dm, f = 2.0 * H.B_PITCH, H.B_GROOVE / D
    Q = PRELOAD_N / (Z * math.sin(a))
    qa = math.pi / 2.0 - 1.0
    ks = []
    for rx in (D * (dm - D * math.cos(a)) / (2.0 * dm), D * (dm + D * math.cos(a)) / (2.0 * dm)):
        ry = f * D / (2.0 * f - 1.0)
        R, ar = 1.0 / (1.0 / rx + 1.0 / ry), ry / rx
        k, Ee, F = ar ** (2.0 / math.pi), 1.0 + qa / ar, math.pi / 2.0 + qa * math.log(ar)
        delta = F * ((9.0 / (2.0 * Ee * R)) * (Q / (math.pi * k * Ep)) ** 2) ** (1.0 / 3.0)
        ks.append(1.5 * Q / delta)
    kn = 1.0 / sum(1.0 / k for k in ks)
    return dict(method='Hertz elliptical point contact (Hamrock-Brewe), inner and outer contacts in series, radial stiffness 0.5 Z k_n cos^2(alpha) under axial preload (Harris and Kotzalas)',
                preload_N=PRELOAD_N, preload_basis='PROJECTED: design spring preload', ball_load_N=Q, k_n_N_per_mm=kn, k_radial_N_per_mm=0.5 * Z * kn * math.cos(a) ** 2)


def disc(name, node, mass):
    out = open(os.path.join(REC, f'moments_{node}.txt'), encoding='utf-8').read()
    m = re.search(r'moments volume=\[' + NUM + ', ' + NUM + r'\] centroid \[' + NUM + ', ' + NUM + r'\]x\[' + NUM + ', ' + NUM + r'\]x\[' + NUM + ', ' + NUM +
                  r'\] inertia-centroid \[' + NUM + ', ' + NUM + r'\] \[' + NUM + ', ' + NUM + r'\] \[' + NUM + ', ' + NUM + r'\]', out)
    v = [float(x) for x in m.groups()]
    vol = 0.5 * (v[0] + v[1])
    p = next(p for p in mass['parts'] if p['node'] == node)
    kg = 0.5 * (p['mass_kg'][0] + p['mass_kg'][1])
    rho = kg / (vol * 1e-9)
    jd = 0.25 * (v[8] + v[9] + v[10] + v[11]) * 1e-9 * rho
    jp = 0.5 * (v[12] + v[13]) * 1e-9 * rho
    return dict(name=name, node=node, z=0.5 * (v[6] + v[7]), m_kg=kg, jd_kg_mm2=jd, jp_kg_mm2=jp, raw=out.strip().splitlines()[-1][:300])


def main():
    st = J5.STD['17-4PH-H1075']
    E, nu, rho = st['e'] * 1000.0 * J5.KSI, st['nu'], st['rho'] * J5.LBIN3
    z0, z1 = -12.0, H.Z_TUR + H.B_TUR + 10.0
    zf, zr = H.Z_BRG_F + H.B_W / 2, H.Z_BRG_R + H.B_W / 2
    brgs = [zf, zr] + ([zf + PAIR] if PAIR else [])
    prof = [(z0, H.Z_BRG_F + H.B_W + 1.0, 2 * H.R_SHAFT), (H.Z_BRG_F + H.B_W + 1.0, H.Z_BRG_R - 1.0, 2 * H.R_SPAN), (H.Z_BRG_R - 1.0, z1, 2 * H.R_SHAFT)]
    mass = json.load(open(os.path.join(REC, 'mass.json'), encoding='utf-8'))
    discs = [disc('impeller', 19, mass), disc('turbine', 27, mass)]
    bs = stiffness()
    zs = sorted({z for a, b, _ in prof for z in (a, b)} | {d['z'] for d in discs} | set(brgs))
    segs = [f'(seg {b - a!r} {next(d for p, q, d in prof if p - 1e-9 <= a and b <= q + 1e-9)!r} 10.0 {E!r} {nu!r} {rho!r})' for a, b in zip(zs, zs[1:])]
    spec = ('(rotor ' + ' '.join(segs) + ' ' + ' '.join(f"(disc {d['z'] - zs[0]!r} {d['m_kg']!r} {d['jd_kg_mm2']!r})" for d in discs) + ' ' +
            ' '.join(f"(brg {z - zs[0]!r} {bs['k_radial_N_per_mm']!r} 0)" for z in brgs) + ' (n 8) (modes 3))')
    out, s = ASM.kernel('rotor', spec)
    crit = [float(m.group(3)) for m in re.finditer(r'critical \d+ rpm=\[' + NUM + ', ' + NUM + r'\] extrapolated=' + NUM, out)]
    w = H.RPM * math.pi / 30.0
    span = zr - zf
    loads = {}
    for d in discs:
        e_mm = G_BAL / w
        u = d['m_kg'] * 1e3 * e_mm
        f = d['m_kg'] * e_mm * 1e-3 * w * w
        af, ar = (zr - d['z']) / span, (d['z'] - zf) / span
        loads[d['name']] = dict(residual_unbalance_g_mm=u, force_N=f, front_N=f * af, rear_N=f * ar)
    rep = dict(source='bendcad rotor (Timoshenko beam elements, Sturm-count bisection, N/2N/4N refinement with an extrapolated bound) on the HUMPHREY-1 shaft', binary=ASM.BIN,
               design=ASM.DESIGN, shaft='17-4PH-H1075 (MIL-HDBK-5J), hollow 10 mm bore as tools/g6/humphrey.py shaft_edits', discs=discs, bearing=bs, spec=spec, seconds=s,
               raw=out.strip()[-1500:], critical_speeds_rpm=crit, design_rpm=H.RPM, within_15pct=[c for c in crit if abs(c / H.RPM - 1.0) < 0.15],
               balance=dict(grade=f'ISO 21940-11 G{G_BAL}', basis='COMPUTED: permissible residual unbalance U = 9549 G m / n per disc; bearing loads from the static split of the disc force between the bearings', discs=loads),
               provisions='the impeller and turbine are balanced as AM parts in two correction planes each before assembly; the hollow shaft carries no correction')
    json.dump(rep, open(os.path.join(REC, 'rotor.json'), 'w', encoding='utf-8'), indent=1)
    print('critical speeds', crit, 'design', round(H.RPM), 'within 15%', rep['within_15pct'])


if __name__ == '__main__':
    main()
