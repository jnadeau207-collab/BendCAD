import json
import os
import re
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
import jet
from kq import kq, DESIGN, BIN

REC = os.path.join(jet.ROOT, 'docs', 'receipts', 'g5')
RPM = jet.CYC['shaft_rpm']
NUM = r'(-?\d+(?:\.\d+)?(?:e[-+]?\d+)?)'
CASES = {
    'turbine_blade': dict(node=2702, clamp=(0, 0, 0, 0, 0, 1, 21.5), orders=[1, 2, jet.NGV_N, 2 * jet.NGV_N],
                          why='one turbine blade cantilevered where it enters the disc rim (r <= 21.5); excitation: 1x, 2x, NGV passing (19) and its harmonic'),
}


def run(name, h, k=4):
    c = CASES[name]
    t = time.time()
    out = kq('modes', str(c['node']), str(k), repr(h), *(repr(float(x)) for x in c['clamp']), timeout=int(os.environ.get('G5_MODES_TIMEOUT', '14400')))
    fs = [dict(lo=float(m.group(1)), mid=float(m.group(2)), hi=float(m.group(3)), est=float(m.group(4)), bound=float(m.group(5)), status=m.group(6))
          for m in re.finditer(r'\[' + NUM + ', ' + NUM + ', ' + NUM + r'\] est=' + NUM + ' bound=' + NUM + r' status=(\S+)', out)]
    camp = []
    for i, f in enumerate(fs):
        for eo in c['orders']:
            n_cross = 60.0 * f['est'] / eo
            camp.append(dict(mode=i + 1, eo=eo, f_hz=f['est'], crossing_rpm=n_cross, margin_at_design=n_cross / RPM - 1.0,
                             in_range_50_110=0.5 * RPM <= n_cross <= 1.1 * RPM))
    rep = dict(source='bendcad modes (curved T10 tetrahedra at three element sizes, LOBPCG, extrapolated estimate and bound)', binary=BIN, design=DESIGN,
               case=name, node=c['node'], clamp=c['clamp'], why=c['why'], H=h, seconds=round(time.time() - t, 1), modes=fs, campbell=camp,
               raw=out.strip()[-2500:], note='spin is linear in the kernel: no centrifugal stiffening, so the rotating frequencies are lower bounds of the running ones')
    os.makedirs(os.path.join(REC, 'modes'), exist_ok=True)
    json.dump(rep, open(os.path.join(REC, 'modes', name + '.json'), 'w'), indent=1)
    print(name, 'H', h, [round(f['est'], 1) for f in fs], 'crossings 50-110%:', [(x['mode'], x['eo'], round(x['crossing_rpm'])) for x in camp if x['in_range_50_110']])


if __name__ == '__main__':
    run(sys.argv[1], float(sys.argv[2]), int(sys.argv[3]) if len(sys.argv) > 3 else 4)
