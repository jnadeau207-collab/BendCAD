import json
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'thermo'))
import nasa as N

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CYC = json.load(open(os.path.join(ROOT, 'docs/receipts/g5/run1/cycle.json'), encoding='utf-8'))
I = CYC['inputs']


def deck(rpm_frac=1.0):
    a = N.air()
    T0, p0 = 288.15, 101325.0
    PR, ec, et, eb, dpb, em = I['PR'], I['eta_c'], I['eta_t'], I['eta_b'], I['dp_b'], I['eta_m']
    TIT, mdot = I['TIT_K'], I['mdot_kg_s']
    LHV = N.fuel_lhv()
    p2 = p0 * PR
    T2s = a.isentropic(T0, p0, p2)
    h2 = a.h(T0) + (a.h(T2s) - a.h(T0)) / ec
    T2 = a.t_of_h(h2, T2s)
    wc = h2 - a.h(T0)
    hfuel = N.h_rt('Jet-A(g)', 298.15) * N.R * 298.15 / N.mw('Jet-A(g)') * 1000.0
    def res(f):
        return (1.0 + f) * N.burned(f).h(TIT) - a.h(T2) - f * hfuel + (1.0 - eb) * f * LHV
    f0, f1 = 0.01, 0.02
    for _ in range(60):
        r0, r1 = res(f0), res(f1)
        f0, f1 = f1, f1 - r1 * (f1 - f0) / (r1 - r0)
        if abs(f1 - f0) < 1e-13:
            break
    far = f1
    g = N.burned(far)
    m4 = mdot * (1 + far)
    wt = wc * mdot / (m4 * em)
    h5 = g.h(TIT) - wt
    T5 = g.t_of_h(h5, TIT - 150)
    h5s = g.h(TIT) - wt / et
    T5s = g.t_of_h(h5s, TIT - 150)
    p4 = p2 * (1 - dpb)
    p5 = p4 * math.exp((g.s0(T5s) - g.s0(TIT)) / g.r)
    gm = g.gamma(T5)
    crit = ((gm + 1) / 2) ** (gm / (gm - 1))
    choked = p5 / p0 >= crit
    p9 = p0 * crit if choked else p0
    T9s = g.t_of_s(g.s0(T5) - g.r * math.log(p5 / p5), p9, p5, T5 - 50)
    V9 = math.sqrt(2 * (h5 - g.h(T9s)))
    rho9 = p9 / (g.r * T9s)
    A9 = m4 / (rho9 * V9)
    F = m4 * V9 + (p9 - p0) * A9
    return dict(T2_K=T2, compressor_work_J_kg=wc, fuel_air=far, T5_K=T5, p5_kPa=p5 / 1000, thrust_N=F, nozzle_exit_area_mm2=A9 * 1e6,
                jet_velocity_m_s=V9, tsfc_g_per_kN_s=mdot * far / F * 1e6, LHV_J_kg=LHV)


if __name__ == '__main__':
    r = deck()
    print(json.dumps({k: round(v, 4) if isinstance(v, float) else v for k, v in r.items()}, indent=1))
    print('constant-cp deck thrust', CYC['thrust_N'], 'nozzle area', CYC['nozzle_exit_area_mm2'])
