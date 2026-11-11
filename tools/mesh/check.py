import collections
import json
import sys

import numpy as np


def load(path):
    vs, ts, tag, tags = [], [], None, []
    for ln in open(path, encoding='utf-8'):
        if ln.startswith('v '):
            vs.append([float(x) for x in ln.split()[1:4]])
        elif ln.startswith('f '):
            ts.append([int(x.split('/')[0]) - 1 for x in ln.split()[1:4]])
            tags.append(tag)
        elif ln.startswith('g '):
            tag = ln[2:].strip()
    return np.array(vs, float), np.array(ts, int), tags


def weld(V, T):
    key = {}
    m = np.empty(len(V), int)
    for i, p in enumerate(map(tuple, V)):
        m[i] = key.setdefault(p, len(key))
    W = np.zeros((len(key), 3))
    W[m] = V
    return W, m[T]


def tjunctions(W, T, edges, tol):
    from scipy.spatial import cKDTree
    tree = cKDTree(W)
    hits = []
    for (a, b), n in edges.items():
        if n != 1:
            continue
        pa, pb = W[a], W[b]
        d = pb - pa
        L = np.linalg.norm(d)
        if L == 0:
            continue
        for k in tree.query_ball_point((pa + pb) / 2, L / 2 + tol):
            if k in (a, b):
                continue
            t = np.dot(W[k] - pa, d) / (L * L)
            if 0 < t < 1 and np.linalg.norm(pa + t * d - W[k]) <= tol:
                hits.append((a, b, k))
    return hits


def check(path, tol=1e-9):
    V, T, tags = load(path)
    W, U = weld(V, T)
    P = W[U]
    area = 0.5 * np.linalg.norm(np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0]), axis=1)
    scale = max(1.0, float(np.abs(W).max())) if len(W) else 1.0
    zero = area <= 1e-12
    und = collections.Counter()
    dirc = collections.Counter()
    for a, b, c in U:
        for x, y in ((a, b), (b, c), (c, a)):
            und[(min(x, y), max(x, y))] += 1
            dirc[(x, y)] += 1
    uses = collections.Counter(und.values())
    flipped = sum(1 for (x, y), n in dirc.items() if n > 1)
    tj = tjunctions(W, U, und, tol * scale)
    zt = collections.Counter(tags[i] for i in np.nonzero(zero)[0])
    return dict(file=path, vertices=int(len(W)), triangles=int(len(U)), zero_area=int(zero.sum()),
                zero_area_by_group=dict(zt.most_common(10)), edge_uses={str(k): v for k, v in sorted(uses.items())},
                same_direction_pairs=flipped, t_junctions=len(tj),
                conforming=bool(zero.sum() == 0 and set(uses) <= {2} and flipped == 0 and not tj),
                min_area=float(area.min()) if len(area) else None,
                volume=float(np.einsum('ij,ij->i', P[:, 0], np.cross(P[:, 1], P[:, 2])).sum() / 6.0))


if __name__ == '__main__':
    rows = [check(p) for p in sys.argv[1:]]
    print(json.dumps(rows, indent=1))
    sys.exit(0 if all(r['conforming'] for r in rows) else 1)
