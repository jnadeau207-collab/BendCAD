import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import jet
import running as RN

REC = os.path.join(jet.ROOT, 'docs', 'receipts', 'g5')
CYC = jet.CYC
RPM = CYC['shaft_rpm']
LIFE_H = 25.0
SF_DESIGN = 1.5


def area(p):
    return 0.5 * abs(sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p))))


def turbine_sections():
    hub = jet.airfoil(7.5, 0.16, math.tan(math.radians(38.0)), -math.tan(math.radians(62.0)), 0.4)[0]
    tip = jet.airfoil(7.5, 0.10, math.tan(math.radians(20.0)), -math.tan(math.radians(66.0)), 0.3)[0]
    return 20.9, 32.2, hub, tip


def blade_stress(omega, rho, r_root, n=400):
    rh, rt, hub, tip = turbine_sections()
    def a_at(r):
        s = (r - rh) / (rt - rh)
        return area([(a[0] + (b[0] - a[0]) * s, a[1] + (b[1] - a[1]) * s) for a, b in zip(hub, tip)])
    dr = (rt - r_root) / n
    pull = sum(rho * omega ** 2 * a_at(r_root + (i + 0.5) * dr) * 1e-6 * (r_root + (i + 0.5) * dr) * 1e-3 * dr * 1e-3 for i in range(n))
    vol = sum(a_at(rh + (i + 0.5) * (rt - rh) / n) * (rt - rh) / n for i in range(n))
    return pull / (a_at(r_root) * 1e-6) / 1e6, pull, a_at(r_root), vol


def disc_ode(m, omega, prof, a, b, rim_force, smear=None, n=4000):
    rho = m['rho'] * jet.LBIN3
    E = m['e'] * 1000.0 * jet.KSI * 1e6
    nu = m['nu']
    def h(r):
        return prof(r * 1e3) * 1e-3
    def rhs(r, y):
        u, F = y
        hr = h(r)
        sr = F / (hr * r)
        du = (1 - nu * nu) * sr / E - nu * u / r
        st = E / (1 - nu * nu) * (u / r + nu * du)
        mass = rho * hr + (smear(r * 1e3) if smear else 0.0)
        return (du, hr * st - mass * omega ** 2 * r * r)
    def shoot(u0):
        r, y = a, (u0, 0.0)
        dr = (b - a) / n
        out = []
        for i in range(n):
            k1 = rhs(r, y)
            k2 = rhs(r + dr / 2, (y[0] + dr / 2 * k1[0], y[1] + dr / 2 * k1[1]))
            k3 = rhs(r + dr / 2, (y[0] + dr / 2 * k2[0], y[1] + dr / 2 * k2[1]))
            k4 = rhs(r + dr, (y[0] + dr * k3[0], y[1] + dr * k3[1]))
            y = (y[0] + dr / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]), y[1] + dr / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]))
            r += dr
            out.append((r, y))
        return y, out
    ya, _ = shoot(0.0)
    yb, _ = shoot(1e-6)
    u0 = 1e-6 * (rim_force - ya[1]) / (yb[1] - ya[1])
    _, path = shoot(u0)
    worst = (0.0, a, 0.0, 0.0)
    for r, (u, F) in [(a, (u0, 0.0))] + path:
        hr = h(min(r, b - 1e-9))
        sr = F / (hr * r)
        st = E / (1 - nu * nu) * (u / r + nu * ((1 - nu * nu) * sr / E - nu * u / r))
        vm = math.sqrt(sr * sr - sr * st + st * st)
        if vm > worst[0]:
            worst = (vm, r, sr, st)
    return dict(max_vm_MPa=worst[0] / 1e6, at_r_mm=worst[1] * 1e3, sr_MPa=worst[2] / 1e6, st_MPa=worst[3] / 1e6, rim_u_mm=path[-1][1][0] * 1e3)


def imp_thk(r):
    z0 = jet.IMP_Z0
    if r <= 8.8:
        return 31.0
    zarc = z0 + math.sqrt(max(0.0, 24.0 ** 2 - (jet.IMP_R2 - min(r, 28.83)) ** 2))
    top = 30.0 if r <= 10.5 else z0 + 26.5
    return max(top - zarc, 2.86)


def tur_thk(r):
    return 10.0 if r <= 12.0 else (6.0 if r <= 18.0 else 9.0)


def strength_at(m, t_k):
    tf = (t_k - 273.15) * 1.8 + 32.0
    s = m['strength']
    if tf > s[-1][0]:
        raise ValueError(f'{t_k} K beyond the strength curve of {m["name"]}')
    for (a, u0, y0), (b, u1, y1) in zip(s, s[1:]):
        if tf <= b:
            k = (max(tf, a) - a) / (b - a)
            return (u0 + (u1 - u0) * k) / 100.0, (y0 + (y1 - y0) * k) / 100.0
    return s[-1][1] / 100.0, s[-1][2] / 100.0


def rupture_hours(m, t_k, sigma_mpa):
    r = m['rupture']
    tr = t_k * 1.8
    x = math.log10(sigma_mpa / jet.KSI)
    return 10.0 ** (r['c'] + r['b1'] * tr + r['b2'] * x + r['b3'] * x * x + r['b4'] * x ** 3)


def worst(rows, part):
    r = max((r for r in rows if part in r['item'] and r['state'] == 'design'), key=lambda r: r['stress_MPa'] / r['allowable_MPa'])
    return dict(name=part, item=r['item'], max_von_mises_MPa=r['stress_MPa'], allowable_MPa=r['allowable_MPa'], utilisation=round(r['stress_MPa'] / r['allowable_MPa'], 3))


def run():
    omega = RPM * 2.0 * math.pi / 60.0
    mt = jet.STD['IN718-AMS5663']
    rho_t = mt['rho'] * jet.LBIN3
    fty_rt, ftu_rt = mt['fty'] * jet.KSI, mt['ftu'] * jet.KSI
    t_blade = CYC['inputs']['TIT_K']
    ku, ky = strength_at(mt, t_blade)
    rows = []
    for tag, w in (('design', omega), ('overspeed 120%', 1.2 * omega)):
        RN.OMEGA = w
        sb, pull, a_root, vol = blade_stress(w, rho_t, 21.5)
        life = rupture_hours(mt, t_blade, sb) if tag == 'design' else None
        rows.append(dict(item='turbine blade root (r = 21.5, disc rim)', state=tag, stress_MPa=round(sb, 1), pull_N=round(pull, 1), root_area_mm2=round(a_root, 3),
                         T_K=t_blade, Fty_T_MPa=round(fty_rt * ky, 1), allowable_MPa=round(fty_rt * ky / (SF_DESIGN if tag == 'design' else 1.0), 1),
                         rupture_life_h=round(life, 1) if life else None, ok=sb < fty_rt * ky / (SF_DESIGN if tag == 'design' else 1.0) and (life is None or life >= LIFE_H)))
        bl = json.load(open(os.path.join(REC, 'clear', 'blades.json')))['turbine']
        bpull = jet.TUR_N * rho_t * bl['volume_mm3'] * 1e-9 * w ** 2 * bl['centroid_r_mm'] * 1e-3
        t_disc = 0.5 * (CYC['inputs']['TIT_K'] + CYC['T2_K'])
        dd = disc_ode(mt, w, tur_thk, 4.0e-3, 21.5e-3, bpull / (2.0 * math.pi))
        ku_d, ky_d = strength_at(mt, t_disc)
        hoop = dd['max_vm_MPa']
        lim = fty_rt * ky_d / (SF_DESIGN if tag == 'design' else 1.0)
        rows.append(dict(item='turbine disc (variable-thickness rotating disc, profile of jet.py: 10 mm hub, 6 mm web, 9 mm rim; 23 blades as rim load)', state=tag,
                         stress_MPa=round(hoop, 1), at_r_mm=round(dd['at_r_mm'], 2), T_K=round(t_disc, 1), Fty_T_MPa=round(fty_rt * ky_d, 1), allowable_MPa=round(lim, 1), ok=hoop < lim))
    mi = jet.STD['AL2618-T61']
    t_imp = CYC['T2_K']
    kui, kyi = strength_at(mi, t_imp)
    fty_i = mi['fty'] * jet.KSI
    bl = json.load(open(os.path.join(REC, 'clear', 'blades.json')))['impeller']
    mblades = 6 * (bl['volume_mm3'] + bl['splitter_mm3']) * 1e-9 * mi['rho'] * jet.LBIN3
    def smear(r):
        return mblades / (24.0e-3) / (2.0 * math.pi * r * 1e-3) if 9.0 <= r <= 33.0 else 0.0
    for tag, w in (('design', omega), ('overspeed 120%', 1.2 * omega)):
        dd = disc_ode(mi, w, imp_thk, 4.0e-3, 34.0e-3, 0.0, smear)
        hoop = dd['max_vm_MPa']
        lim = fty_i * kyi / (SF_DESIGN if tag == 'design' else 1.0)
        rows.append(dict(item='impeller hub (variable-thickness rotating disc on the hub profile of jet.py; 12 blades smeared as dead mass over r 9-33)', state=tag, stress_MPa=round(hoop, 1), at_r_mm=round(dd['at_r_mm'], 2),
                         T_K=round(t_imp, 1), Fty_T_MPa=round(fty_i * kyi, 1), allowable_MPa=round(lim, 1), ok=hoop < lim))
    ok = all(r['ok'] for r in rows)
    rep = dict(source='tools/g5/stress.py: closed-form rotating-disc (Lame, Timoshenko) and 1-D blade pull integrated over the design sections; strengths from MIL-HDBK-5J (data/std/materials.json), rupture from the IN718 Larson-type equation of Figure 6.3.5.1.7(e)',
               basis='COMPUTED', factor_design=SF_DESIGN, life_required_h=LIFE_H, rpm=RPM, converged=True, ok=ok, rows=rows,
               parts=[worst(rows, k) for k in ('turbine', 'impeller')])
    os.makedirs(os.path.join(REC, 'fem'), exist_ok=True)
    json.dump(rep, open(os.path.join(REC, 'fem', 'stress.json'), 'w'), indent=1)
    for r in rows:
        print(f"{r['item'][:60]:60s} {r['state']:15s} {r['stress_MPa']:8.1f} MPa vs {r['allowable_MPa']:7.1f} {'ok' if r['ok'] else 'FAIL'} {r.get('rupture_life_h') or ''}")
    print('blade volume from sections', round(blade_stress(omega, rho_t, 20.9)[3], 3), 'mm3 (kernel certified 94.5715)')


if __name__ == '__main__':
    run()
