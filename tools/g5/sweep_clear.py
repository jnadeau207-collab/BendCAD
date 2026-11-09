import json
import os
import sys

import numpy as np
from scipy.spatial import cKDTree

VIEW = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '..', '..', 'viewer', 'g5')
OUT = sys.argv[2] if len(sys.argv) > 2 else None


def verts(path):
    with open(path, encoding='utf-8') as f:
        return np.array([list(map(float, ln.split()[1:4])) for ln in f if ln.startswith('v ')])


def meridional(v):
    return np.column_stack([np.hypot(v[:, 0], v[:, 1]), v[:, 2]])


sc = json.load(open(os.path.join(VIEW, 'scene.json'), encoding='utf-8'))
rot = {p['name']: meridional(verts(os.path.join(VIEW, p['mesh']))) for p in sc['parts'] if p['rotor'] == 1}
sta = {p['name']: meridional(verts(os.path.join(VIEW, p['mesh']))) for p in sc['parts'] if p['rotor'] == 0}
bear = {p['name'] for p in sc['parts'] if 'bearing' in p['name'] or p['name'] == 'spring'}
rows = []
for sn, s in sta.items():
    t = cKDTree(s)
    for rn, r in rot.items():
        if (rn in bear) or (sn in bear):
            continue
        d, i = t.query(r, k=1)
        j = int(np.argmin(d))
        rows.append(dict(rotor=rn, stator=sn, gap_mm=round(float(d[j]), 3), at_r=round(float(r[j, 0]), 2), at_z=round(float(r[j, 1]), 2)))
rows.sort(key=lambda x: x['gap_mm'])
for x in rows[:16]:
    print(f"{x['rotor']:10s} vs {x['stator']:13s} min swept gap {x['gap_mm']:7.3f} mm at r={x['at_r']:6.2f} z={x['at_z']:7.2f}")
if OUT:
    json.dump(dict(method='meridional (r,z) vertex-cloud distance, rotor swept through 360 deg; sampled, cold, not certified', rows=rows), open(OUT, 'w'), indent=1)
