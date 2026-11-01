import json
import re
import math
import os
import sys

RHO = 101325.0 / (287.05 * 293.15)
MU = 1.813e-5
Q_D = 3000.0 / 3600.0
DP_D = 2500.0
DP_TARGET = 2600.0
N_RPM = 2900.0
OMEGA = 2 * math.pi * N_RPM / 60.0

Z = 10
BETA2 = math.radians(30.0)
T_BLADE = 0.004
D_HUB = 0.060
CONE_T = 0.002
SEAL_RADIAL = 0.0015
FILLET = 0.005
DISC_OVERHANG = 0.006
SEAL_GAP = 0.0015
CD_SEAL = 0.6
ZETA_IN = 0.15
LAM = 0.02
ZETA_DIFF = 0.15
ZETA_VOL = 0.25
ZETA_SHOCK = 0.6

AL_RHO = 2700.0
AL_RP02 = 240e6
AL_NU = 0.3
AL_E = 70e9
BORE_R = 0.014
BLADE_FOOTPRINT_M2 = 2405.137518937347e-6
SHAFT_SHOULDER_Z = -0.032


def eye_optimum():
    best = None
    for k in range(4000):
        d0 = 0.08 + k * 0.0001
        a = math.pi / 4 * (d0 * d0 - D_HUB * D_HUB)
        c0 = Q_D / a
        u = OMEGA * d0 / 2
        w = math.hypot(c0, u)
        if best is None or w < best[1]:
            best = (d0, w, c0, u)
    return best


def wiesner(beta2, z, ratio):
    sigma = 1 - math.sqrt(math.sin(beta2)) / z ** 0.7
    lim = math.exp(-8.16 * math.sin(beta2) / z)
    if ratio > lim:
        sigma *= 1 - ((ratio - lim) / (1 - lim)) ** 3
    return sigma, lim


def stage(d2, q, g, full=False):
    d1, b, beta1 = g['d1'], g['b'], g['beta1']
    r1, r2 = d1 / 2, d2 / 2
    u1, u2 = OMEGA * r1, OMEGA * r2
    tau1 = 1 - Z * T_BLADE / (math.pi * d1 * math.sin(beta1))
    tau2 = 1 - Z * T_BLADE / (math.pi * d2 * math.sin(BETA2))
    sigma, lim = wiesner(BETA2, Z, d1 / d2)
    d_eye = g['d0']
    a0 = math.pi / 4 * (d_eye ** 2 - D_HUB ** 2)
    dp_imp_static_guess = 0.7 * RHO * u2 * u2 / 2
    q_leak = CD_SEAL * math.pi * d_eye * SEAL_GAP * math.sqrt(2 * dp_imp_static_guess / RHO)
    qi = q + q_leak
    cm1 = qi / (math.pi * d1 * b * tau1)
    cm2 = qi / (math.pi * d2 * b * tau2)
    cu2 = u2 * sigma - cm2 / math.tan(BETA2)
    c2 = math.hypot(cm2, cu2)
    w1 = math.hypot(cm1, u1)
    w2 = math.hypot(cm2, u2 - cu2)
    w1b = cm1 / math.sin(beta1)
    c0 = qi / a0
    dp_th = RHO * u2 * cu2
    pitch_mean = math.pi * (d1 + d2) / 2 / Z
    blade_len = (r2 - r1) / math.sin((beta1 + BETA2) / 2)
    dh = 2 * b * pitch_mean * math.sin((beta1 + BETA2) / 2) / (b + pitch_mean * math.sin((beta1 + BETA2) / 2))
    wm = (w1 + w2) / 2
    l_in = ZETA_IN * RHO * c0 * c0 / 2
    l_fric = LAM * blade_len / dh * RHO * wm * wm / 2
    l_diff = ZETA_DIFF * RHO * (w1 - w2) ** 2 / 2 if w2 < w1 else 0.0
    l_shock = ZETA_SHOCK * RHO * (u1 * (1 - q / Q_D)) ** 2 / 2
    l_vol = ZETA_VOL * RHO * c2 * c2 / 2
    c3_design = g['c_vol']
    cu3 = cu2 * r2 / g['r_vol']
    l_mis = 0.5 * RHO * max(0.0, cu3 - c3_design * q / Q_D) ** 2 if q != Q_D else 0.0
    losses = l_in + l_fric + l_diff + l_shock + l_vol + l_mis
    dp_t = dp_th - losses
    re = RHO * OMEGA * r2 * r2 / MU
    cm = 0.0622 * (0.01 / r2) ** 0.1 * re ** -0.2
    p_df = 2 * 0.5 * cm * RHO * OMEGA ** 3 * r2 ** 5
    p_shaft = qi * dp_th + p_df
    eta = q * dp_t / p_shaft
    out = dict(q=q, dp_t=dp_t, p_shaft=p_shaft, eta_t=eta)
    if full:
        out.update(u1=u1, u2=u2, cm1=cm1, cm2=cm2, cu2=cu2, c2=c2, w1=w1, w2=w2, w1_blade=w1b, de_haller=w2 / w1,
                   beta2_flow_deg=math.degrees(math.atan2(cm2, u2 - cu2)), alpha2_deg=math.degrees(math.atan2(cm2, cu2)),
                   slip_sigma=sigma, wiesner_limit_ratio=lim, tau1=tau1, tau2=tau2, c0=c0, q_leak=q_leak, q_impeller=qi,
                   dp_theoretical=dp_th, losses=dict(inlet=l_in, friction=l_fric, diffusion=l_diff, shock=l_shock, volute=l_vol,
                   mismatch=l_mis), disc_friction_w=p_df, disc_cm=cm, reynolds_disc=re, hydraulic_eff=dp_t / dp_th,
                   blade_length=blade_len, hydraulic_diameter=dh)
    return out


def geometry(d2):
    d0opt, w, c0, u = eye_optimum()
    d0 = round(1.08 * d0opt * 4000) / 4000
    d1 = d0 + 2 * (CONE_T + SEAL_RADIAL + FILLET + T_BLADE / 2 + 0.00125)
    b = 1.05 * math.pi / 4 * (d0 * d0 - D_HUB * D_HUB) / (math.pi * d1)
    u1 = OMEGA * d1 / 2
    cm1 = Q_D * 1.04 / (math.pi * d1 * b)
    beta1 = math.atan(cm1 / u1) + math.radians(2.0)
    for _ in range(5):
        tau1 = 1 - Z * T_BLADE / (math.pi * d1 * math.sin(beta1))
        beta1 = math.atan(cm1 / tau1 / u1) + math.radians(2.0)
    return dict(d0=d0, d0_opt=d0opt, d1=d1, b=b, beta1=beta1)


def solve_d2():
    lo, hi = 0.30, 0.60
    for _ in range(80):
        mid = (lo + hi) / 2
        g = geometry(mid)
        g['r_vol'] = mid / 2 * 1.25
        g['c_vol'] = 1.0
        if stage(mid, Q_D, g)['dp_t'] < DP_TARGET:
            lo = mid
        else:
            hi = mid
    return round(hi * 1000) / 1000


def volute(d2, b, cu2, r_tongue_frac=0.12, width=None):
    r2 = d2 / 2
    r3 = r2 + DISC_OVERHANG + r_tongue_frac / 2 * d2
    bw = width or 0.125
    k = cu2 * r2
    rows = []
    for deg in range(0, 361, 15):
        th = math.radians(deg)
        q_th = Q_D * th / (2 * math.pi)
        ro = r3 * math.exp(q_th / (bw * k))
        rows.append(dict(theta_deg=deg, r_outer=ro, q=q_th))
    return dict(rule='free vortex c_u r = const, rectangular section of constant width B (Eck 1973, Bleier 1998)', r3=r3,
                width=bw, k_cu_r=k, spiral=rows, throat_area=(rows[-1]['r_outer'] - r3) * bw,
                c_throat=Q_D / ((rows[-1]['r_outer'] - r3) * bw))


def stresses(d2, b, t_hub, t_shroud, d_eye, mass_blades):
    out = {}
    for tag, nscale in (('running', 1.0), ('overspeed_120', 1.2)):
        w = OMEGA * nscale
        ro, ri = d2 / 2, BORE_R
        hub = (3 + AL_NU) / 4 * AL_RHO * w * w * (ro * ro + (1 - AL_NU) / (3 + AL_NU) * ri * ri)
        rs_in, rs_out = d_eye / 2, d2 / 2
        rim_area = t_shroud * (rs_out - rs_in)
        r_blade_cg = (rs_out + d_eye / 2 * 1.04) / 2
        f_blades = 0.5 * mass_blades * w * w * r_blade_cg
        ring_free = AL_RHO * w * w * (rs_in * rs_in + rs_in * rs_out + rs_out * rs_out) / 3
        ring_blade = f_blades / (2 * math.pi * rim_area)
        shroud = (3 + AL_NU) / 4 * AL_RHO * w * w * (rs_out * rs_out + (1 - AL_NU) / (3 + AL_NU) * rs_in * rs_in) + ring_blade
        out[tag] = dict(hub_bore_hoop_pa=hub, shroud_inner_hoop_pa=shroud, ring_free_pa=ring_free, blade_load_share_pa=ring_blade,
                        factor_on_proof=AL_RP02 / max(hub, shroud), tip_speed=w * d2 / 2)
    return out


def bearing(mass_imp, x_load, unbalance_g):
    e_perm = unbalance_g / OMEGA * 1e-3
    f_unb = mass_imp * e_perm * OMEGA * OMEGA
    f_w = mass_imp * 9.81
    fr = f_w + f_unb
    e = 0.060
    fx0, fxm = 1258.0, 1014.0
    perm = fx0 - x_load / e * (fx0 - fxm) if x_load <= e else fxm * e / x_load
    return dict(mass_impeller=mass_imp, load_point_from_shoulder=x_load, weight_n=f_w, unbalance_n_at_grade=f_unb,
                radial_n=fr, permissible_n=perm, ratio=fr / perm,
                source='ABB GB 12-2004 cast iron 112M 2-pole, 20,000 h: FX0 1258 N, FXmax 1014 N, E 60 mm')


def noise(z, q, dp):
    bpf = z * N_RPM / 60
    cfm = q * 2118.88
    inwg = dp / 249.089
    lw = 10 * math.log10(cfm) + 20 * math.log10(inwg) + 37
    return dict(bpf_hz=bpf, lw_db=lw, method='Madison (1949) Lw = 10 log10 Q[cfm] + 20 log10 p[in.wg] + 37, as given in Graham, ASHRAE fan sound',
                label='PROJECTED')


def main(out):
    d2 = solve_d2()
    g = geometry(d2)
    first = stage(d2, Q_D, dict(g, r_vol=d2 / 2 * 1.25, c_vol=1.0), full=True)
    vol = volute(d2, g['b'], first['cu2'])
    g['r_vol'] = (vol['r3'] + vol['spiral'][-1]['r_outer']) / 2
    g['c_vol'] = vol['c_throat']
    design = stage(d2, Q_D, g, full=True)
    curve = [stage(d2, Q_D * f, g) for f in [0.5 + 0.05 * k for k in range(15)]]
    for row, f in zip(curve, [0.5 + 0.05 * k for k in range(15)]):
        row['flow_fraction'] = round(f, 2)
    res = dict(inputs=dict(q_m3s=Q_D, dp_t_pa=DP_D, design_target_pa=DP_TARGET, rho=RHO, n_rpm=N_RPM, z=Z,
                           beta2_blade_deg=math.degrees(BETA2), blade_thickness=T_BLADE, hub_diameter=D_HUB, seal_gap=SEAL_GAP,
                           loss_coefficients=dict(inlet=ZETA_IN, friction_lambda=LAM, diffusion=ZETA_DIFF, volute=ZETA_VOL,
                                                  shock=ZETA_SHOCK, seal_cd=CD_SEAL)),
               impeller=dict(d2=d2, d0_eye=g['d0'], d0_optimum=g['d0_opt'], d1_leading_edge=g['d1'], b=g['b'],
                             beta1_blade_deg=math.degrees(g['beta1']), beta2_blade_deg=math.degrees(BETA2), z=Z),
               design_point=design, volute=vol, curve=curve, noise=noise(Z, Q_D, design['dp_t']),
               air_power_w=Q_D * DP_D)
    json.dump(res, open(os.path.join(out, 'sizing.json'), 'w'), indent=1)
    d = design
    print('D2 %.3f m  D0 %.4f (opt %.4f)  D1 %.4f  b %.4f  beta1 %.2f deg  beta2 %.1f deg  z %d' % (
        d2, g['d0'], g['d0_opt'], g['d1'], g['b'], math.degrees(g['beta1']), math.degrees(BETA2), Z))
    print('u2 %.2f cu2 %.2f cm2 %.2f c2 %.2f w1 %.2f w2 %.2f deHaller %.3f slip %.4f' % (
        d['u2'], d['cu2'], d['cm2'], d['c2'], d['w1'], d['w2'], d['de_haller'], d['slip_sigma']))
    print('dp_th %.1f dp_t %.1f P %.1f W eta %.3f leak %.4f m3/s Pdf %.1f W' % (
        d['dp_theoretical'], d['dp_t'], d['p_shaft'], d['eta_t'], d['q_leak'], d['disc_friction_w']))
    print('losses', {k: round(v, 1) for k, v in d['losses'].items()})
    print('volute r3 %.4f width %.4f throat %.5f m2 c_throat %.2f' % (vol['r3'], vol['width'], vol['throat_area'], vol['c_throat']))
    for r in curve:
        print('  Q %.2f  dp %.0f  P %.0f  eta %.3f' % (r['flow_fraction'], r['dp_t'], r['p_shaft'], r['eta_t']))


def mid(lo, hi):
    return (float(lo) + float(hi)) / 2


def moments(path):
    txt = open(path).read()
    m = re.search(r'moments volume=\[([^,]+), ([^\]]+)\] centroid \[([^,]+), ([^\]]+)\]x\[([^,]+), ([^\]]+)\]x\[([^,]+), ([^\]]+)\]', txt)
    return dict(volume_mm3=(float(m.group(1)), float(m.group(2))),
                centroid_mm=[(float(m.group(3)), float(m.group(4))), (float(m.group(5)), float(m.group(6))), (float(m.group(7)), float(m.group(8)))])


def post(out, q):
    sz = json.load(open(os.path.join(out, 'sizing.json')))
    imp = sz['impeller']
    mi = moments(os.path.join(q, 'mass_impeller.txt'))
    v_imp = mid(*mi['volume_mm3']) * 1e-9
    m_imp = v_imp * AL_RHO
    mb = re.search(r'^node 1100: ok .*?volume=\[([^,]+), ([^\]]+)\]', open(os.path.join(q, 'master_apply.txt')).read(), re.M)
    blade_one = mid(mb.group(1), mb.group(2)) * 1e-9
    ledges = 2 * BLADE_FOOTPRINT_M2 * 0.001
    m_blades = Z * (blade_one - ledges) * AL_RHO
    z_cg = mid(*mi['centroid_mm'][2]) * 1e-3
    res = dict(impeller_mass_kg=m_imp, impeller_volume_m3=v_imp, centroid_z_m=z_cg, blade_mass_total_kg=m_blades,
               stresses=stresses(imp['d2'], imp['b'], 0.008, 0.006, imp['d0_eye'], m_blades),
               bearing=bearing(m_imp, z_cg - SHAFT_SHOULDER_Z, 2.5))
    json.dump(res, open(os.path.join(out, 'post.json'), 'w'), indent=1)
    print(json.dumps(res, indent=1))


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'post':
        post(sys.argv[2], sys.argv[3])
    else:
        main(sys.argv[1] if len(sys.argv) > 1 else '.')
