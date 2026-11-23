import json
import os
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
import humphrey as H
import asm as ASM

REC = os.path.join(H.ROOT, 'docs', 'receipts', 'g6')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
DESIGN = os.environ.get('G6_DESIGN', '/home/jesse/g6/g6r.bcd')
NUM = r'(-?\d+(?:\.\d+)?(?:e[-+]?\d+)?)'
QUERIES = [
    ('turbine tip clearance', ['clearance', '2702', '4202'], H.G_TT, 'one turbine blade against the CMC shroud revolve: the shroud is axisymmetric, so the gap of one blade is the gap of every blade at every angle'),
    ('compressor tip clearance', ['clearance', '1903', '23'], H.G_TIP, 'one main blade against the shroud revolve'),
    ('compressor splitter tip clearance', ['clearance', '1904', '23'], H.G_TIP, 'one splitter blade against the shroud revolve'),
    ('RDC channel height', ['clearance', '9401', '9402'], H.RDC_W, 'the RDC body (with its injector orifices) and the stator rings cut to the channel span Z_INJ + 1 to Z_RDC1 - 1 (analysis nodes 9401, 9402; the bodies meet at the injector flange outside that span): both walls are surfaces of revolution, so the certified gap holds around the full circumference'),
    ('RDC outer body minimum wall', ['wall', '40'], None, 'minimum material thickness of the finished RDC body'),
    ('vaporiser loop minimum wall', ['wall', '461'], None, 'minimum material thickness of vaporiser coil 1 (the four coils are the same part moved)'),
]


def kernel(*a, timeout=14400):
    t = time.time()
    if ASM.PORT:
        return ASM.served(a, timeout), round(time.time() - t, 1)
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    p = subprocess.run([*pre, BIN, DESIGN, *a], capture_output=True, text=True, timeout=timeout, env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return p.stdout + p.stderr, round(time.time() - t, 1)


def main():
    rows = []
    for name, args, want, why in QUERIES:
        out, s = kernel(*args)
        m = re.search(r'^(clearance|min-wall) \[' + NUM + ', ' + NUM + r'\] (\S+)', out, re.M)
        lo, hi, st = (float(m.group(2)), float(m.group(3)), m.group(4)) if m else (None, None, 'none')
        ok = m is not None and st == 'certified' and lo > 0.0 and (want is None or lo <= want + 1e-6 <= hi + 0.005)
        rows.append(dict(query=name, args=args, why=why, design_mm=want, certified_mm=[lo, hi] if m else None, status=st, seconds=s,
                         verdict='pass' if ok else 'fail', raw=out.strip()[-600:]))
        print(f"{'PASS' if ok else 'FAIL'} {name}: {[lo, hi]} {st} {s}s", flush=True)
    rep = dict(source='bendcad clearance / wall on the built design (certified branch-and-bound lower bound, witness upper bound)', binary=BIN, design=DESIGN,
               green=all(r['verdict'] == 'pass' for r in rows), rows=rows)
    json.dump(rep, open(os.path.join(REC, 'certs.json'), 'w', encoding='utf-8'), indent=1)


if __name__ == '__main__':
    main()
