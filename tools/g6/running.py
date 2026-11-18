import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'g5'))
import humphrey as H
import jet as J5

REC = os.path.join(H.ROOT, 'docs', 'receipts', 'g6')
CY = H.CY
B = CY['brayton']
HU = CY['humphrey_measured_rdc']
OMEGA = H.RPM * 2.0 * math.pi / 60.0
T0 = 293.15


def alpha_mean(m, t_k):
    tf = (t_k - 273.15) * 1.8 + 32.0
    pts = [(70.0, m['alpha'][0][1])] + [(float(a), float(b)) for a, b in m['alpha']]
    if tf > pts[-1][0] + 50.0:
        raise ValueError(f'{t_k} K is beyond the expansion curve of {m["name"]} (last point {pts[-1][0]} F)')
    for (a, x), (b, y) in zip(pts, pts[1:]):
        if tf <= b:
            return (x + (y - x) * (max(tf, a) - a) / (b - a)) * 1.8e-6
    return pts[-1][1] * 1.8e-6


def si(m):
    return m['rho'] * J5.LBIN3, m['e'] * 1.0e3 * J5.KSI * 1.0e6, m['nu']


def disc_u(m, a, b, pull, t):
    rho, E, nu = si(m)
    q = rho * OMEGA ** 2
    P = pull / (2.0 * math.pi * b * t)
    c1, c2 = (3.0 + nu) / 8.0 * q, (1.0 + 3.0 * nu) / 8.0 * q
    Bc = (P + c1 * (b * b - a * a)) / (1.0 / (a * a) - 1.0 / (b * b))
    A = Bc / (a * a) + c1 * a * a
    sr = A - Bc / (b * b) - c1 * b * b
    st = A + Bc / (b * b) - c2 * b * b
    return b * (st - nu * sr) / E, (A + Bc / (a * a) - c2 * a * a) / 1e6


def area(p):
    return 0.5 * abs(sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p))))


def turbine():
    mw = J5.STD[J5.grade_name(27)] if 27 in J5.GRADES and J5.GRADES[27] == H.GRADES[27] else J5.STD[H.GRADES[27]]
    rho, E, nu = si(mw)
    hub = J5.airfoil(H.B_TUR - 2.0, 0.18, math.tan(math.radians(42.0)), -math.tan(math.radians(60.0)), 0.6)[0]
    tip = J5.airfoil(H.B_TUR - 2.0, 0.10, math.tan(math.radians(25.0)), -math.tan(math.radians(64.0)), 0.4)[0]
    rh, rt = H.TH - 0.8, H.TT
    n = 400
    pull, vol, mom = 0.0, 0.0, 0.0
    stretch = 0.0
    for i in range(n):
        r = rh + (rt - rh) * (i + 0.5) / n
        s = (r - rh) / (rt - rh)
        a = area([(p[0] + (q[0] - p[0]) * s, p[1] + (q[1] - p[1]) * s) for p, q in zip(hub, tip)])
        dr = (rt - rh) / n
        vol += a * dr
        pull += rho * OMEGA ** 2 * a * 1e-6 * r * 1e-3 * dr * 1e-3
    for i in range(n):
        r = (rh + (rt - rh) * (i + 0.5) / n) * 1e-3
        stretch += rho * OMEGA ** 2 * ((rt * 1e-3) ** 2 - r * r) / 2.0 / E * (rt - rh) * 1e-3 / n
    t_blade = CY['inputs']['TIT_K']
    t_disc = 0.5 * (HU['T2_K'] + t_blade)
    u_disc, bore = disc_u(mw, H.R_SHAFT * 1e-3, H.TH * 1e-3, H.TUR_N * pull, (H.B_TUR + 8.0) * 1e-3)
    th_disc = H.TH * alpha_mean(mw, t_disc) * (t_disc - T0)
    th_blade = (rt - H.TH) * alpha_mean(mw, t_blade) * (t_blade - T0)
    rotor = dict(material=H.GRADES[27], disc_T_K=t_disc, blade_T_K=t_blade, thermal_disc_mm=th_disc, thermal_blade_mm=th_blade,
                 spin_disc_mm=u_disc * 1e3, spin_blade_stretch_mm=stretch * 1e3, blade_pull_N=pull, blade_volume_mm3=vol, disc_bore_hoop_MPa=bore,
                 basis='COMPUTED: MIL-HDBK-5J Waspaloy mean expansion (Figure 6.3.8.0) at the stated temperatures; rotating annular disc (Timoshenko) r 10-62.3 mm, 30 mm thick, 41 blades as rim pull; blade self-stretch')
    cmc = H.CMC
    t_sh = HU['T5_K']
    th_sh = (H.TT + H.G_TT) * cmc['cte_per_K_1204C'] * (t_sh - T0)
    stator = dict(material='SIC-SIC-N24A', T_K=t_sh, thermal_mm=th_sh,
                  basis='COMPUTED: measured N24A expansion 6.0e-6/K (NASA TM-2009-215806, Table IV) at the turbine exit gas temperature, the coldest gas washing the shroud (closes the gap most)')
    close = th_disc + th_blade + (u_disc + stretch) * 1e3 - th_sh
    return dict(pair='turbine blade tip to CMC shroud (radial)', cold_mm=H.G_TT, cold_basis='design value of tools/g6/humphrey.py (G_TT); the kernel clearance certificate of the built design replaces it',
                closure_mm=close, running_mm=H.G_TT - close, ok=H.G_TT - close > 0.0, rotor=rotor, stator=stator,
                cold_needed_mm=close + 0.05, needed_basis='closure plus 0.05 mm running margin')


def compressor():
    mt = J5.STD[H.GRADES[19]]
    ms = J5.STD[H.GRADES[23]]
    rho, E, nu = si(mt)
    t_imp = HU['T2_K']
    rows = []
    dr, dz = (H.R2 - H.R1T) * math.pi / 2.0, H.L_IMP - H.B2
    nr = dz / math.hypot(dr, dz)
    for name, r, kr in (('inducer tip (radial)', H.R1T, 1.0), ('exducer tip at the shroud contour (contour normal)', H.R2, nr)):
        th = r * alpha_mean(mt, t_imp) * (t_imp - T0)
        u = (1.0 - nu) / 4.0 * rho * OMEGA ** 2 * (r * 1e-3) ** 2 / E * r
        ths = r * alpha_mean(ms, 288.15) * (288.15 - T0)
        close = kr * (th + u - ths)
        rows.append(dict(pair='impeller ' + name, cold_mm=H.G_TIP, closure_mm=close, running_mm=H.G_TIP - close, ok=H.G_TIP - close > 0.0,
                         rotor=dict(material=H.GRADES[19], T_K=t_imp, thermal_mm=th, spin_mm=u, basis='COMPUTED: MIL-HDBK-5J Ti-6Al-4V mean expansion (Figure 5.4.1.0); solid rotating disc hoop growth (1-nu)/4 rho w^2 r^2 / E'),
                         stator=dict(material=H.GRADES[23], T_K=288.15, thermal_mm=ths, basis='ISA intake air, the coldest state of the shroud (closes the gap most)')))
    return rows


def run():
    rows = [turbine()] + compressor()
    ok = all(r['ok'] for r in rows)
    refusals = []
    t = rows[0]
    if not t['ok']:
        refusals.append(dict(code='g6-turbine-tip-clearance', target='cold turbine tip clearance <= 0.15 mm that stays positive at temperature (brief section 4.4)',
                             computed=f"cold {t['cold_mm']:.2f} mm closes {t['closure_mm']:.3f} mm at {H.RPM:.0f} r/min: running {t['running_mm']:.3f} mm (rub); a positive running gap needs {t['cold_needed_mm']:.2f} mm cold",
                             physics=f"the Waspaloy rotor grows {t['rotor']['thermal_disc_mm'] + t['rotor']['thermal_blade_mm']:.3f} mm thermally and {t['rotor']['spin_disc_mm'] + t['rotor']['spin_blade_stretch_mm']:.3f} mm by spin, while the monolithic SiC/SiC shroud (6.0e-6/K) grows only {t['stator']['thermal_mm']:.3f} mm; the brief fixes the shroud as part of the CMC monolith, so no carrier ring can match the rotor"))
    rep = dict(source='tools/g6/running.py', rpm=H.RPM, cycle='docs/receipts/g6/cycle.json humphrey_measured_rdc', ok=ok, rows=rows, refusals=refusals)
    os.makedirs(REC, exist_ok=True)
    json.dump(rep, open(os.path.join(REC, 'running.json'), 'w', encoding='utf-8'), indent=1)
    for r in rows:
        print(f"{r['pair']:45s} cold {r['cold_mm']:.3f} closure {r['closure_mm']:+.3f} running {r['running_mm']:+.3f} {'pass' if r['ok'] else 'FAIL'}")
    for f in refusals:
        print('REFUSAL', f['code'], f['computed'])


if __name__ == '__main__':
    run()
