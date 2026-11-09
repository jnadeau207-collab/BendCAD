import json
import os
import sys
import time

import numpy as np
from scipy import ndimage

VIEW = sys.argv[1]
OUT = sys.argv[2]
H = float(os.environ.get('FP_H', '0.25'))
DZ = float(os.environ.get('FP_DZ', '0.5'))


def load(path):
    vs, fs = [], []
    with open(path, encoding='utf-8') as f:
        for ln in f:
            if ln.startswith('v '):
                vs.append(ln.split()[1:4])
            elif ln.startswith('f '):
                fs.append(ln.split()[1:4])
    v = np.array(vs, float)
    f = np.array(fs, int) - 1
    t = v[f]
    a = np.linalg.norm(np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0]), axis=1)
    return t[a > 1e-12]


def section(tri, z):
    d = tri[:, :, 2] - z
    s = np.sign(d)
    s[s == 0] = 1
    cut = ~((s[:, 0] == s[:, 1]) & (s[:, 1] == s[:, 2]))
    t, dd, ss = tri[cut], d[cut], s[cut]
    segs = []
    for i, j in ((0, 1), (1, 2), (2, 0)):
        m = ss[:, i] != ss[:, j]
        w = dd[m, i] / (dd[m, i] - dd[m, j])
        segs.append((np.nonzero(m)[0], t[m, i, :2] + w[:, None] * (t[m, j, :2] - t[m, i, :2])))
    pts = {}
    for idx, p in segs:
        for k, q in zip(idx, p):
            pts.setdefault(k, []).append(q)
    out = [v for v in pts.values() if len(v) == 2]
    return np.array(out) if out else np.zeros((0, 2, 2))


def fill(seg, xs, ys):
    occ = np.zeros((len(ys), len(xs)), bool)
    if not len(seg):
        return occ
    y0, y1 = seg[:, 0, 1], seg[:, 1, 1]
    lo, hi = np.minimum(y0, y1), np.maximum(y0, y1)
    order = np.argsort(lo)
    lo_s = lo[order]
    for r, y in enumerate(ys):
        k = order[: np.searchsorted(lo_s, y, side='right')]
        k = k[hi[k] > y]
        if not len(k):
            continue
        a, b = seg[k, 0], seg[k, 1]
        x = a[:, 0] + (y - a[:, 1]) / (b[:, 1] - a[:, 1]) * (b[:, 0] - a[:, 0])
        x.sort()
        for u in range(0, len(x) - 1, 2):
            occ[r, np.searchsorted(xs, x[u]):np.searchsorted(xs, x[u + 1])] = True
    return occ


t0 = time.time()
sc = json.load(open(os.path.join(VIEW, 'scene.json'), encoding='utf-8'))
parts = {p['name']: load(os.path.join(VIEW, p['mesh'])) for p in sc['parts']}
allv = np.concatenate([t.reshape(-1, 3) for t in parts.values()])
R = np.hypot(allv[:, 0], allv[:, 1]).max() + 2 * H
zs = np.arange(allv[:, 2].min() - 4 * DZ, allv[:, 2].max() + 4 * DZ, DZ)
xs = np.arange(-R, R, H) + H / 2
ys = xs.copy()
X, Y = np.meshgrid(xs, ys)
RR = np.hypot(X, Y)
zr = {n: (t[:, :, 2].min(), t[:, :, 2].max()) for n, t in parts.items()}
solid = np.zeros((len(zs), len(ys), len(xs)), bool)
for i, z in enumerate(zs):
    for n, t in parts.items():
        if zr[n][0] < z < zr[n][1]:
            solid[i] |= fill(section(t, z), xs, ys)
print('voxelised', solid.shape, round(time.time() - t0, 1), 's', flush=True)
air = ~solid
air[:, RR > R - H] = True
lab, nlab = ndimage.label(air)
outside = lab[0, 0, 0]
inside = (lab != outside) & air
ilab, nin = ndimage.label(inside)
sizes = ndimage.sum(inside, ilab, range(1, nin + 1)) * H * H * DZ
regions = sorted([(float(s), k + 1) for k, s in enumerate(sizes)], reverse=True)


def probe(r, z, th=0.0):
    i = int(round((z - zs[0]) / DZ))
    x, y = r * np.cos(th), r * np.sin(th)
    return int(lab[i, int((y - ys[0]) / H), int((x - xs[0]) / H)]), int(ilab[i, int((y - ys[0]) / H), int((x - xs[0]) / H)])


inlet_z, exit_z = allv[:, 2].min(), allv[:, 2].max()
probes = {
    'intake throat (r=10, z=-20)': probe(10, -20),
    'compressor inducer (r=20, z=5)': probe(20, 5),
    'outer combustor annulus (r=50, z=100)': probe(50, 100),
    'inner combustor annulus (r=18.5, z=100)': probe(18.5, 100),
    'combustion zone inside liner (r=34, z=105)': probe(34, 105),
    'nozzle exit (r=18, z=228)': probe(18, 228),
}
sec = []
for i, z in enumerate(zs):
    a = air[i] & (RR < (53.0 if 20.0 < z < 175.0 else R - 2 * H))
    sl = lab[i]
    conn = (sl == outside) & a
    sec.append(dict(z=round(float(z), 2), open_connected_mm2=round(float(conn.sum() * H * H), 1),
                    sealed_mm2=round(float((a & (sl != outside)).sum() * H * H), 1)))
rep = dict(method=f'voxels {H} mm x {H} mm x {DZ} mm from kernel tessellation, rotor frozen, zero-area triangles dropped; '
                  'air connected to the outside world vs sealed pockets', grid=list(solid.shape),
           outside_label=int(outside),
           probes={k: dict(connected_to_outside=bool(v[0] == outside), sealed_region=int(v[1])) for k, v in probes.items()},
           sealed_pockets=[dict(region=k, volume_mm3=round(s, 1)) for s, k in regions[:12]],
           sections=sec, seconds=round(time.time() - t0, 1))
json.dump(rep, open(OUT, 'w'), indent=1)
for k, v in rep['probes'].items():
    print(f"{k:45s} {'open to inlet/outlet' if v['connected_to_outside'] else 'SEALED pocket ' + str(v['sealed_region'])}")
print('largest sealed pockets mm3:', [p['volume_mm3'] for p in rep['sealed_pockets'][:6]])
