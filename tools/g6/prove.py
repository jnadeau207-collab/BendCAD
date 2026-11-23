import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(__file__))
import humphrey as H

REC = os.path.join(H.ROOT, 'docs', 'receipts', 'g6')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
DESIGN = os.environ.get('G6_DESIGN', '/home/jesse/g6/g6.bcd')
PARTS = {'shaft': 10, 'impeller': 19, 'casing': 20, 'shroud': 23, 'diffuser': 24, 'rdc': 40, 'stator': 42, 'turbine': 27, 'nozzle': 28,
         'reservoir': 43, 'tunnel': 44, 'vaporiser_1': 461, 'vaporiser_2': 462, 'vaporiser_3': 463, 'vaporiser_4': 464,
         'bearing_front_inner': 51, 'bearing_front_outer': 52, 'bearing_front_balls': 53, 'bearing_front_cage': 54,
         'bearing_rear_inner': 61, 'bearing_rear_outer': 62, 'bearing_rear_balls': 63, 'bearing_rear_cage': 64,
         'bearing_front2_inner': 71, 'bearing_front2_outer': 72, 'bearing_front2_balls': 73, 'bearing_front2_cage': 74}
NUM = r'(-?\d+(?:\.\d+)?(?:e[-+]?\d+)?)'


def run(name, node, timeout):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    try:
        p = subprocess.run([*pre, BIN, DESIGN, 'mass', str(node), '0'], capture_output=True, text=True, timeout=timeout, env=dict(os.environ, MSYS_NO_PATHCONV='1'))
        out = p.stdout + p.stderr
    except subprocess.TimeoutExpired:
        out = f'timeout after {timeout} s'
    m = re.search(r'material (\S+) .*mass=\[' + NUM + ', ' + NUM + r'\] kg status=(\S+)', out)
    v = re.search(r'^mass volume=\[' + NUM + ', ' + NUM + r'\]', out, re.M)
    row = dict(name=name, node=node, seconds=round(time.time() - t, 1), material=m.group(1) if m else None,
               mass_kg=[float(m.group(2)), float(m.group(3))] if m else None, status=m.group(4) if m else 'none',
               volume_mm3=[float(v.group(1)), float(v.group(2))] if v else None, error=None if m else out.strip()[-500:])
    print(name, node, row['seconds'], row['mass_kg'], row['status'], (row['error'] or '')[:160], flush=True)
    return row


def main(jobs, timeout, only):
    items = [(k, v) for k, v in PARTS.items() if not only or k in only]
    old = {}
    f = os.path.join(REC, 'mass.json')
    if only and os.path.exists(f):
        old = {p['name']: p for p in json.load(open(f, encoding='utf-8'))['parts']}
    with ThreadPoolExecutor(jobs) as ex:
        rows = list(ex.map(lambda kv: run(kv[0], kv[1], timeout), items))
    for r in rows:
        old[r['name']] = r
    parts = [old[k] for k in PARTS if k in old]
    done = all(p['mass_kg'] for p in parts) and len(parts) == len(PARTS)
    lo = sum(p['mass_kg'][0] for p in parts if p['mass_kg'])
    hi = sum(p['mass_kg'][1] for p in parts if p['mass_kg'])
    lim = H.SZ['envelope']['mass_max_kg']
    rep = dict(source='bendcad mass NODE 0 per part (certified divergence volume and moments; density from MIL-HDBK-5J, NASA TM-2009-215806 or the bearing catalog)', binary=BIN, design=DESIGN, parts=parts,
               complete=done, total_kg=[lo, hi] if done else None, partial_total_kg=[lo, hi], limit_kg=lim,
               refusal=dict(code='g6-mass-over-limit', target=f'dry mass <= {lim} kg', computed=f'{lo:.3f}-{hi:.3f} kg certified', physics='sum of the certified part masses') if done and lo > lim else None)
    json.dump(rep, open(f, 'w', encoding='utf-8'), indent=1)
    print('complete' if done else 'incomplete', round(lo, 3), round(hi, 3), 'kg of', lim)


if __name__ == '__main__':
    main(int(sys.argv[1]), int(sys.argv[2]), sys.argv[3:])
