import json, math, sys
sys.path.insert(0, '.')
from leak import leak, MU50
from geo import *

z, m, x, ha, alpha = 12, 1.75, 0.35, 0.88, math.radians(20)
inv = lambda a: math.tan(a) - a
r = m * z / 2
rb = r * math.cos(alpha)
ra = r + m * (ha + x)
rf = r - m * (1.25 - x)
pb = math.pi * m * math.cos(alpha)
aw = math.acos(2 * rb / A)
rw = A / 2
eps = (2 * math.sqrt(ra ** 2 - rb ** 2) - A * math.sin(aw)) / pb
s = m * (math.pi / 2 + 2 * x * math.tan(alpha)) - 0.05
aa = math.acos(rb / ra)
sa = 2 * ra * (s / (2 * r) + inv(alpha) - inv(aa))
xmin = (17 - z) / 17
c_root = A - ra - rf
jt = 2 * 0.05 + 2 * rw * (inv(aw) - inv(math.acos(rb / (A / 2))))
inv_aw0 = 2 * 2 * x * math.tan(alpha) / (2 * z) + inv(alpha)
a0 = None
lo, hi = 0.3, 0.6
for _ in range(80):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if inv(mid) < inv_aw0 else (lo, mid)
a0 = 2 * rb / math.cos(lo)
jn_center = 2 * (A - a0) * math.sin(aw)
V = 2 * math.pi * B * (ra ** 2 - rw ** 2 - pb ** 2 / 12)
Vest = 2 * math.pi * m * m * z * B
n = 3000
Q = V * n / 1e6
rip = (pb ** 2 / 4) / (ra ** 2 - rw ** 2 - pb ** 2 / 12)
Qs = V * 1e-9 * n / 60
v_s = Qs / (math.pi * (18.9e-3 / 2) ** 2)
v_p = Qs / (math.pi * (11e-3 / 2) ** 2)
v_s_thread = Qs / (math.pi * (20.5e-3 / 2) ** 2)
dT = 30
hs50 = (LB - B) / 2 + B * (23.4e-6 - 11.5e-6) * dT / 2
c50 = (RC - ra) + ra * (23.4e-6 - 11.5e-6) * dT
eta = {}
for lab, hs, c in (('nominal_50C', hs50, c50), ('min_20C', 0.022, 0.025), ('max_80C', 0.0415, 0.052)):
    Vv, qth, q, tot, e, *_ = leak(z, m, x, ha, B, A, hs * 1e-3, c * 1e-3)
    eta[lab] = dict(side_mm=hs, tip_mm=c, eta=e, slip_lpm={k: v * 6e4 for k, v in q.items()}, slip_total_lpm=tot * 6e4)
pk = 25.0
ri, ro = RC, -BX0
wall = -BX0 - RC
lame = pk * (ro ** 2 + ri ** 2) / (ro ** 2 - ri ** 2)
Rp = 250.0
A_seal = math.pi * RO ** 2 + 2 * RO * A
F_sep = pk * A_seal
Mb = F_sep * 48.05 / 8
Zs = (70 - 36) * TR ** 2 / 6 + 36 * (TR - 15.5) ** 2 / 6
sig_cover = Mb / Zs
F_M = 29.6e3
phi = 0.2
F_A = F_sep / 4
F_kr = 0.85 * F_M - (1 - phi) * F_A
F_r210 = 0.75 * 21.0 * B * 2 * ra
F_r250 = 0.75 * 25.0 * B * 2 * ra
p_b = F_r210 / 2 / (16 * 15)
v_b = math.pi * 0.016 * n / 60
T = 25e6 * V * 1e-9 / (2 * math.pi) / 0.85
yrel = pb * math.cos(aw) / 2
out = dict(gear=dict(z=z, m=m, x=x, ha=ha, d=2 * r, db=2 * rb, da=2 * ra, df=2 * rf, a=A, alpha_w_deg=math.degrees(aw), eps=eps,
                     tip_thickness=sa, xmin=xmin, root_clearance=c_root, a_zero_backlash=a0, normal_backlash_mm=0.05 * 2 * math.cos(alpha) + jn_center),
           displacement=dict(V_kin_cm3=V / 1000, V_2pim2zb_cm3=Vest / 1000, dev_pct=(V / 1000 - 8) / 8 * 100, Q_th_lpm=Q, ripple=rip),
           ports=dict(v_suction=v_s, v_pressure=v_p, v_suction_tapdrill=v_s_thread),
           efficiency=eta, mu50=MU50,
           wall=dict(min_wall=wall, lame_MPa=lame, SF=Rp / lame),
           cover=dict(A_seal_mm2=A_seal, F_sep_N=F_sep, M_Nmm=Mb, Z_mm3=Zs, sigma=sig_cover, SF=Rp / sig_cover),
           screws=dict(F_A_per_screw=F_A, F_M=F_M, F_residual=F_kr, engagement=80 - (LB + TR)),
           bushing=dict(F_gear_210=F_r210, F_gear_250=F_r250, p_MPa=p_b, v_ms=v_b, pv=p_b * v_b),
           torque_peak_Nm=T, relief_half_gap=yrel)
print(json.dumps(out, indent=1))
json.dump(out, open('sizing.json', 'w'), indent=1)
