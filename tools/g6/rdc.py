import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CYC = json.load(open(os.path.join(ROOT, 'docs', 'receipts', 'g6', 'cycle.json'), encoding='utf-8'))
OUT = os.path.join(ROOT, 'docs', 'receipts', 'g6', 'rdc.json')
V_DET = 1850.0
T_MIX = 600.0
FILL_K = 12.0
FILL_K_LO = 7.0
D_MAX = 0.272
WALLS = 0.012
LAM_1ATM_353K = 60.4

SOURCES = {
    'lambda_1atm': 'MEASURED: stoichiometric JP-10/air at 353 K, mean cell width 60.4 mm (39-84), Austin and Shepherd, Detonations in hydrocarbon fuel blends, Combust. Flame 132 (2003); kerosene vapour/air at 353 K about 60 mm in the same review literature',
    'lambda_scaling': 'PROJECTED: cell width taken inversely proportional to initial pressure and to the square root of initial temperature; Pintgen and Shepherd (ISABE-2005-1304) report partially oxidised kerosene/air cells of 22-24 mm at 1 atm and 3-9 mm at 6 atm (24-404 C), consistent with the inverse-pressure trend',
    'fill_height': 'MEASURED rule: critical fresh-mixture height h* = (12 +/- 5) cell widths, Bykovskii, Zhdan and Vedernikov, Continuous spin detonations, J. Propulsion Power 22(6) 2006, as restated in Zhou, Wu and Wang, Progress of continuously rotating detonation engines, Chinese J. Aeronautics 2016',
    'v_det': 'brief section 4.3: 1800-2000 m/s class; 1850 m/s used',
    'h2_credit': 'PROJECTED: the 10% hydrogen pilot energy is credited with a 15% smaller cell; Austin and Shepherd (2003) show hydrogen addition shrinking hydrocarbon cells, but give no number at this fraction and pressure',
}


def run():
    br = CYC['brayton']
    mdot = br['mdot_kg_s']
    p = br['p2_kPa'] * 1e3
    rho = p / (287.0 * T_MIX)
    rows = []
    for tag, lam in (('scaled kerosene, 10% H2 energy credited at 15%', LAM_1ATM_353K * (101.325e3 / p) * math.sqrt(353.0 / T_MIX) * 0.85),
                     ('needed for one wave at a 2-cell channel', None)):
        dm = D_MAX - 2 * WALLS - 0.02
        if lam is None:
            lo, hi = 0.5, 30.0
            for _ in range(60):
                m = (lo + hi) / 2
                tau = math.pi * dm / V_DET
                w = mdot / (rho * (FILL_K * m * 1e-3 / tau) * math.pi * dm)
                if w * 1e3 > 2 * m:
                    lo = m
                else:
                    hi = m
            lam = hi
        for n in (1, 2):
            tau = math.pi * dm / (n * V_DET)
            for k in (FILL_K, FILL_K_LO):
                u = k * lam * 1e-3 / tau
                w = mdot / (rho * u * math.pi * dm)
                rows.append(dict(case=tag, lambda_mm=round(lam, 2), waves=n, fill_factor=k, mean_diameter_mm=round(dm * 1e3, 1), fill_height_mm=round(k * lam, 1),
                                 fill_velocity_m_s=round(u, 1), fill_mach=round(u / math.sqrt(1.4 * 287 * T_MIX), 3), channel_width_mm=round(w * 1e3, 2),
                                 channel_over_cell=round(w * 1e3 / lam, 2), fits=w * 1e3 >= lam and u / math.sqrt(1.4 * 287 * T_MIX) < 0.5))
    fit = [r for r in rows if r['fits'] and r['case'].startswith('scaled')]
    rep = dict(source='tools/g6/rdc.py', basis='COMPUTED from the cycle mass flow and the sources below', sources=SOURCES, mixture_T_K=T_MIX, plenum_p_kPa=p / 1e3,
               rows=rows, refusal=None if fit else dict(code='g6-rdc-cell-size-not-fit', target='annular RDC whose channel holds its detonation cells inside the 272 mm envelope',
                                                        computed=f"one wave in a {rows[0]['mean_diameter_mm']} mm annulus needs {rows[0]['fill_velocity_m_s']} m/s fill (Mach {rows[0]['fill_mach']}) through a {rows[0]['channel_width_mm']} mm channel, {rows[0]['channel_over_cell']} cell widths",
                                                        physics=f"with cells near {rows[0]['lambda_mm']} mm at the delivery pressure the fill height of 12 cells cannot be met at a subsonic fill velocity in a channel at least one cell wide; it fits once the cell is at most {rows[-1]['lambda_mm']} mm, which needs more hydrogen or oxygen enrichment than the brief's 10% hydrogen energy"))
    json.dump(rep, open(OUT, 'w'), indent=1)
    for r in rows:
        print(r)
    print('refusal' if rep['refusal'] else 'fits', rep['refusal'] and rep['refusal']['physics'])


if __name__ == '__main__':
    run()
