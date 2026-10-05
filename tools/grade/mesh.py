import math
import sys
from collections import Counter


def load_obj(path):
    vs, fs = [], []
    with open(path) as f:
        for ln in f:
            p = ln.split()
            if not p:
                continue
            if p[0] == 'v':
                vs.append(tuple(float(x) for x in p[1:4]))
            elif p[0] == 'f':
                fs.append(tuple(int(x.split('/')[0]) - 1 for x in p[1:4]))
    return vs, fs


def check(vs, fs):
    directed = Counter()
    for a, b, c in fs:
        for u, v in ((a, b), (b, c), (c, a)):
            directed[(u, v)] += 1
    bad_dir = sum(1 for k, n in directed.items() if n != 1)
    unmatched = sum(1 for (u, v) in directed if (v, u) not in directed)
    vol = 0.0
    area = 0.0
    for a, b, c in fs:
        p, q, r = vs[a], vs[b], vs[c]
        vol += (p[0] * (q[1] * r[2] - q[2] * r[1]) - p[1] * (q[0] * r[2] - q[2] * r[0])
                + p[2] * (q[0] * r[1] - q[1] * r[0])) / 6.0
        u = [q[i] - p[i] for i in range(3)]
        w = [r[i] - p[i] for i in range(3)]
        cx = (u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0])
        area += 0.5 * math.sqrt(sum(x * x for x in cx))
    used = sorted({i for f in fs for i in f})
    lo = [min(vs[i][k] for i in used) for k in range(3)] if used else [0, 0, 0]
    hi = [max(vs[i][k] for i in used) for k in range(3)] if used else [0, 0, 0]
    edges = {(min(u, v), max(u, v)) for (u, v) in directed}
    chi = len(used) - len(edges) + len(fs)
    return {
        'triangles': len(fs),
        'watertight': bad_dir == 0 and unmatched == 0,
        'nonmanifold_directed_edges': bad_dir,
        'unmatched_edges': unmatched,
        'volume': vol,
        'area': area,
        'bbox': (lo, hi),
        'euler_characteristic': chi,
    }


if __name__ == '__main__':
    r = check(*load_obj(sys.argv[1]))
    for k, v in r.items():
        print(k, v)
