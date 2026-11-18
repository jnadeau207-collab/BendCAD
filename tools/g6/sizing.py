import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'thermo'))
import nasa as N

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CYC = json.load(open(os.path.join(ROOT, 'docs', 'receipts', 'g6', 'cycle.json'), encoding='utf-8'))
OUT = os.path.join(ROOT, 'docs', 'receipts', 'g6', 'sizing.json')
Z_IMP = 24
U2 = 457.0
HUB_TIP_IN = 0.30
D2_MM = 200.0
INDUCER_RATIO = 0.70
PHI_T = 0.55
PSI_T = 1.6
M_NGV_EXIT = 0.9


def run():
    b = CYC['brayton']
    a = N.air()
    mdot = b['mdot_kg_s']
    w = a.h(b['T2_K']) - a.h(288.15)
    sigma = 1 - 1 / Z_IMP ** 0.7
    u2 = math.sqrt(w / sigma)
    gam = a.gamma(288.15)
    d2 = D2_MM * 1e-3
    n_rpm = u2 / (math.pi * d2) * 60
    r1t = INDUCER_RATIO * d2 / 2
    a1 = math.pi * r1t ** 2 * (1 - HUB_TIP_IN ** 2)
    m_in = 0.3
    for _ in range(80):
        t1 = 288.15 / (1 + (gam - 1) / 2 * m_in ** 2)
        p1 = 101325.0 / (1 + (gam - 1) / 2 * m_in ** 2) ** (gam / (gam - 1))
        m_new = mdot / (p1 / (a.r * t1) * a1) / math.sqrt(gam * a.r * t1)
        m_in = 0.5 * (m_in + m_new)
    t1 = 288.15 / (1 + (gam - 1) / 2 * m_in ** 2)
    c1 = m_in * math.sqrt(gam * a.r * t1)
    u1t = math.pi * 2 * r1t * n_rpm / 60
    w1t = math.hypot(c1, u1t)
    m1rel = w1t / math.sqrt(gam * a.r * t1)
    g = N.burned(b['far'])
    tit = b['TIT_K']
    wt = w / ((1 + b['far']) * 0.98)
    um = math.sqrt(wt / PSI_T)
    rm = um / (n_rpm * 2 * math.pi / 60)
    cx = PHI_T * um
    t4 = tit - cx * cx / (2 * g.cp(tit))
    p4 = b['p4_kPa'] * 1e3 * (t4 / tit) ** (g.gamma(tit) / (g.gamma(tit) - 1))
    rho4 = p4 / (g.r * t4)
    ann = mdot * (1 + b['far']) / (rho4 * cx)
    h_blade = ann / (2 * math.pi * rm)
    rep = dict(source='tools/g6/sizing.py', basis='COMPUTED (methods: Wiesner slip; inducer from inlet Mach and hub/tip ratio; turbine from loading psi = dh/U^2 and flow coefficient phi = cx/U)',
               compressor=dict(work_J_kg=w, slip=sigma, blades=f'{Z_IMP // 2} main + {Z_IMP // 2} splitter, radial exit', tip_speed_m_s=u2, tip_limit_m_s=460.0, D2_mm=d2 * 1e3,
                               inducer_tip_mm=2 * r1t * 1e3, inducer_hub_tip=HUB_TIP_IN, inlet_mach=m_in, diffuser_outer_mm=1.30 * d2 * 1e3, inducer_tip_rel_mach=m1rel, shaft_rpm=n_rpm,
                               diffuser='vaned radial diffuser then axial straightener into the RDC air plenum'),
               turbine=dict(work_J_kg=wt, loading_psi=PSI_T, flow_coeff_phi=PHI_T, mean_speed_m_s=um, mean_radius_mm=rm * 1e3, blade_height_mm=h_blade * 1e3,
                            tip_radius_mm=(rm + h_blade / 2) * 1e3, hub_radius_mm=(rm - h_blade / 2) * 1e3, inlet_T_K=tit, annulus_mm2=ann * 1e6),
               nozzle=dict(exit_area_mm2=b['A9_mm2'], exit_dia_mm=2 * math.sqrt(b['A9_mm2'] / math.pi), choked=b['choked']),
               envelope=dict(diameter_max_mm=272.0, length_max_mm=560.0, mass_max_kg=19.6, tj150_rpm=55300))
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(json.dumps({k: {kk: (round(vv, 3) if isinstance(vv, float) else vv) for kk, vv in v.items()} if isinstance(v, dict) else v for k, v in rep.items() if k in ('compressor', 'turbine', 'nozzle')}, indent=1))


if __name__ == '__main__':
    run()
