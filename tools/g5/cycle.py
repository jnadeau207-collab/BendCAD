import json
import math

g, R, cp_c, cp_h, g_h = 1.4, 287.05, 1005.0, 1150.0, 1.33
T0, p0 = 288.15, 101325.0
LHV = 43.0e6

PR = 2.4
eta_c = 0.74
eta_t = 0.80
eta_b = 0.95
dp_b = 0.05
eta_m = 0.97
TIT = 973.0
mdot = 0.265

T2 = T0 * (1 + (PR ** ((g - 1) / g) - 1) / eta_c)
w_c = cp_c * (T2 - T0)
p2 = p0 * PR
far = cp_h * (TIT - T2) / (eta_b * LHV - cp_h * TIT)
m4 = mdot * (1 + far)
w_t = w_c * mdot / (m4 * eta_m)
T5 = TIT - w_t / cp_h
T5s = TIT - w_t / (cp_h * eta_t)
p4 = p2 * (1 - dp_b)
p5 = p4 * (T5s / TIT) ** (g_h / (g_h - 1))
npr = p5 / p0
crit = ((g_h + 1) / 2) ** (g_h / (g_h - 1))
choked = npr >= crit
p9 = p0 * crit if choked else p0
T9 = T5 * (p9 / p5) ** ((g_h - 1) / g_h)
V9 = math.sqrt(2 * cp_h * (T5 - T9))
rho9 = p9 / (R * T9)
A9 = m4 / (rho9 * V9)
F = m4 * V9 + (p9 - p0) * A9
sfc = mdot * far / F * 3600 * 1000

Z_BLADES = 12
BETA2B = math.radians(30.0)
PHI2 = 0.30
sigma = 1 - math.sqrt(math.cos(BETA2B)) / Z_BLADES ** 0.7
U2 = math.sqrt(w_c / (sigma - PHI2 * math.tan(BETA2B)))
D2 = 0.066
N = U2 / (math.pi * D2) * 60

out = {
    'inputs': {'PR': PR, 'eta_c': eta_c, 'eta_t': eta_t, 'eta_b': eta_b, 'dp_b': dp_b, 'eta_m': eta_m,
               'TIT_K': TIT, 'mdot_kg_s': mdot, 'LHV_J_kg': LHV, 'impeller_D2_m': D2},
    'T2_K': round(T2, 1), 'compressor_work_J_kg': round(w_c), 'fuel_air': round(far, 4),
    'T5_K': round(T5, 1), 'p5_kPa': round(p5 / 1000, 1), 'nozzle_choked': choked,
    'nozzle_exit_area_mm2': round(A9 * 1e6), 'nozzle_exit_dia_mm': round(math.sqrt(4 * A9 / math.pi) * 1000, 1),
    'jet_velocity_m_s': round(V9), 'thrust_N': round(F, 1), 'tsfc_g_per_kN_s': round(sfc / 3.6, 1),
    'fuel_flow_g_s': round(mdot * far * 1000, 2), 'tip_speed_m_s': round(U2), 'shaft_rpm': round(N),
    'slip_wiesner': round(sigma, 4), 'blades_main_plus_splitter': Z_BLADES, 'backsweep_deg': 30.0,
    'exit_flow_coefficient': PHI2, 'bearing_ndm_mm_per_min': round(N * 15.0),
}
print(json.dumps(out, indent=1))
