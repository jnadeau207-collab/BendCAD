import json
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'thermo'))
import nasa as N

T0, P0 = 288.15, 101325.0


def tsfc_lb(mf_kg_s, f_n):
    return mf_kg_s * 3600.0 / 0.45359237 / (f_n / 4.4482216152605)


def solve_far(a, T_in, TIT, eb, LHV):
    hf = N.h_rt('Jet-A(g)', 298.15) * N.R * 298.15 / N.mw('Jet-A(g)') * 1000.0
    def res(f):
        return (1.0 + f) * N.burned(f).h(TIT) - a.h(T_in) - f * hf + (1.0 - eb) * f * LHV
    f0, f1 = 0.01, 0.02
    for _ in range(80):
        r0, r1 = res(f0), res(f1)
        f0, f1 = f1, f1 - r1 * (f1 - f0) / (r1 - r0)
        if abs(f1 - f0) < 1e-13:
            break
    return f1


def deck(PR, ec, et, TIT, dp_comb, eb=0.99, em=0.98, cv=0.98, thrust=None, mdot=1.0, gain=None):
    a = N.air()
    LHV = N.fuel_lhv()
    p2 = P0 * PR
    T2s = a.isentropic(T0, P0, p2)
    h2 = a.h(T0) + (a.h(T2s) - a.h(T0)) / ec
    T2 = a.t_of_h(h2, T2s)
    wc = h2 - a.h(T0)
    far = solve_far(a, T2, TIT, eb, LHV)
    g = N.burned(far)
    p4 = p2 * (gain if gain is not None else 1.0 - dp_comb)
    wt = wc / ((1 + far) * em)
    h5 = g.h(TIT) - wt
    T5 = g.t_of_h(h5, TIT - 200)
    T5s = g.t_of_h(g.h(TIT) - wt / et, TIT - 200)
    p5 = p4 * math.exp((g.s0(T5s) - g.s0(TIT)) / g.r)
    gm = g.gamma(T5)
    crit = ((gm + 1) / 2) ** (gm / (gm - 1))
    choked = p5 / P0 >= crit
    p9 = p5 / crit if choked else P0
    T9s = g.t_of_s(g.s0(T5), p9, p5, T5 - 100)
    V9 = cv * math.sqrt(2 * (h5 - g.h(T9s)))
    T9 = g.t_of_h(h5 - 0.5 * V9 * V9, T9s)
    rho9 = p9 / (g.r * T9)
    fs = (1 + far) * V9 + (p9 - P0) * (1 + far) / (rho9 * V9)
    m = thrust / fs if thrust else mdot
    F = m * fs
    eta_th = ((1 + far) * V9 ** 2 / 2 + (p9 - P0) * (1 + far) / (rho9 * V9) * V9) / (far * LHV)
    return dict(PR=PR, eta_c=ec, eta_t=et, TIT_K=TIT, T2_K=T2, p2_kPa=p2 / 1e3, p4_kPa=p4 / 1e3, comb_pt_ratio=p4 / p2, far=far, T5_K=T5, p5_kPa=p5 / 1e3,
                choked=choked, V9_m_s=V9, specific_thrust_N_s_kg=fs, mdot_kg_s=m, thrust_N=F, fuel_kg_s=m * far,
                tsfc_lb_lbf_h=tsfc_lb(m * far, F), tsfc_g_kN_s=m * far / F * 1e6, thermal_eff=eta_th, A9_mm2=m * (1 + far) / (rho9 * V9) * 1e6)


if __name__ == '__main__':
    for tit in (1100.0, 1150.0, 1200.0, 1250.0):
        r = deck(4.2, 0.76, 0.84, tit, 0.04, thrust=1500.0)
        print(f"TIT {tit:.0f} K: mdot {r['mdot_kg_s']:.3f} kg/s, Fs {r['specific_thrust_N_s_kg']:.0f} N s/kg, TSFC {r['tsfc_lb_lbf_h']:.3f} lb/lbf/h, eta_th {r['thermal_eff']:.3f}, T5 {r['T5_K']:.0f}")
