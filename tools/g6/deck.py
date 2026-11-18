import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import brayton as B

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'docs', 'receipts', 'g6', 'cycle.json')
PR, EC, ET, TIT, F = 4.2, 0.78, 0.84, 1150.0, 1500.0
ET_RDC = ET - 0.02
GV = 0.05
EAP_MEASURED = -0.0684
EAP_SIM = (0.11, 0.14)
TARGET = 1.05
TJ150 = 1.167


def need_gain(tit):
    lo, hi = -0.3, 1.0
    for _ in range(80):
        m = (lo + hi) / 2
        if B.deck(PR, EC, ET_RDC, tit, None, thrust=F, gain=(1 + m) * (1 - GV))['tsfc_lb_lbf_h'] > TARGET:
            lo = m
        else:
            hi = m
    return hi


def r5(d):
    return {k: round(v, 5) if isinstance(v, float) else v for k, v in d.items()}


if __name__ == '__main__':
    br = B.deck(PR, EC, ET, TIT, 0.04, thrust=F)
    hm = B.deck(PR, EC, ET_RDC, TIT, None, thrust=F, gain=(1 + EAP_MEASURED) * (1 - GV))
    hs = [B.deck(PR, EC, ET_RDC, TIT, None, thrust=F, gain=(1 + g) * (1 - GV)) for g in EAP_SIM]
    sweep = [dict(TIT_K=t, brayton_tsfc=round(B.deck(PR, EC, ET, t, 0.04, thrust=F)['tsfc_lb_lbf_h'], 4), rdc_gain_needed=round(need_gain(t), 4)) for t in (1100.0, 1150.0, 1200.0, 1250.0)]
    rep = dict(
        source='tools/g6/deck.py over tools/g6/brayton.py and tools/thermo/nasa.py (NASA TM-4513 polynomials, complete Jet-A combustion)',
        inputs=dict(PR=PR, eta_c=EC, eta_t_brayton=ET, eta_t_rdc=ET_RDC, TIT_K=TIT, thrust_N=F, guide_vane_loss=GV, brayton_dp=0.04,
                    basis={'PR': 'brief section 1', 'eta_c': 'COMPUTED: the top of the brief band 0.70-0.78, needed for PR 4.2 inside the 460 m/s tip-speed limit with 12+12 radial blades (Wiesner slip 0.892, tip 457 m/s)',
                           'eta_t': 'COMPUTED choice for an uncooled single axial stage of this size', 'eta_t_rdc': 'eta_t minus 2 points for unsteady inflow (brief section 1.4)',
                           'guide_vane_loss': 'MEASURED: Welsh et al. rigs, as charged by the brief', 'TIT_K': 'COMPUTED choice for uncooled cast nickel blades'}),
        brayton=r5(br),
        humphrey_measured_rdc=dict(r5(hm), rdc_eap_gain=EAP_MEASURED,
                                   rdc_source='MEASURED: best equivalent-available-pressure gain -6.84% (Tesla-valve inlet RDE, Experimental Thermal and Fluid Science 2023, sciencedirect.com/science/article/abs/pii/S0894177723000651), which surveys -8% as the best earlier result; a Michigan axial-inlet RDC measured at best a 20% total-pressure loss (deepblue.lib.umich.edu)'),
        humphrey_simulated_rdc=[dict(r5(h), rdc_eap_gain=g, basis='PROJECTED: Frolov et al. H2-air simulations, +11 to +14%') for g, h in zip(EAP_SIM, hs)],
        tsfc_sweep=sweep, target_tsfc_lb_lbf_h=TARGET, tj150_tsfc_lb_lbf_h=TJ150,
        refusal=dict(code='g6-tsfc-not-closed', target='TSFC <= 1.05 lb/lbf/h at 1500 N',
                     computed=f"{hm['tsfc_lb_lbf_h']:.3f} lb/lbf/h with the best measured RDC pressure gain ({EAP_MEASURED * 100:.2f}%) and the 5% guide-vane loss; the Brayton baseline gives {br['tsfc_lb_lbf_h']:.3f}",
                     physics=f"the deck closes 1.05 only with a net RDC equivalent-available-pressure gain of {need_gain(TIT) * 100:.1f}% at TIT {TIT:.0f} K; every measured RDC pressure gain found is negative"))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(json.dumps(dict(brayton=round(br['tsfc_lb_lbf_h'], 3), measured_rdc=round(hm['tsfc_lb_lbf_h'], 3), sim=[round(h['tsfc_lb_lbf_h'], 3) for h in hs],
                          mdot=round(br['mdot_kg_s'], 3), need=round(need_gain(TIT), 4)), indent=1))
