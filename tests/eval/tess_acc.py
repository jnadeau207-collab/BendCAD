import collections
import json
import math
import os
import re
import subprocess
import sys
import time

BIN = os.environ.get('TESS_BIN', '/home/jesse/bc/bendcad')
CASES = [('/home/jesse/g5/d_balls.bcd', 13), ('/home/jesse/g5/d_balls.bcd', 4150), ('/home/jesse/g5/d_balls.bcd', 4155),
         ('/home/jesse/g5/d_tess3.bcd', 20), ('/home/jesse/g5/d_tess3.bcd', 30), ('/home/jesse/g5/d_tess3.bcd', 14)]


def obj(path):
    vs, fs = [], []
    for ln in open(path):
        if ln.startswith('v '):
            vs.append(tuple(map(float, ln.split()[1:4])))
        elif ln.startswith('f '):
            fs.append(tuple(int(x.split('/')[0]) - 1 for x in ln.split()[1:4]))
    return vs, fs


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def mesh_stats(vs, fs):
    vol = 0.0
    area = 0.0
    nrm = []
    for a, b, c in fs:
        n = cross(sub(vs[b], vs[a]), sub(vs[c], vs[a]))
        ln = math.sqrt(dot(n, n))
        area += ln / 2
        vol += dot(vs[a], cross(vs[b], vs[c])) / 6
        nrm.append((tuple(x / ln for x in n) if ln > 0 else None, ln / 2))
    key = [tuple(round(x, 9) for x in v) for v in vs]
    directed = collections.Counter()
    owners = collections.defaultdict(list)
    for i, (a, b, c) in enumerate(fs):
        for x, y in ((a, b), (b, c), (c, a)):
            if key[x] != key[y]:
                directed[(key[x], key[y])] += 1
                owners[frozenset((key[x], key[y]))].append(i)
    unmatched = sum(1 for (x, y), k in directed.items() if directed.get((y, x), 0) != k)
    folds = 0
    fold_area = 0.0
    for ts in owners.values():
        if len(ts) == 2 and nrm[ts[0]][0] and nrm[ts[1]][0] and dot(nrm[ts[0]][0], nrm[ts[1]][0]) < -0.5:
            folds += 1
            fold_area += nrm[ts[0]][1] + nrm[ts[1]][1]
    return dict(tris=len(fs), volume=vol, area=area, unmatched=unmatched, folds=folds, fold_area=fold_area)


def exact(design, node):
    p = subprocess.run([BIN, design, 'mass', str(node)], capture_output=True, text=True, timeout=3600)
    m = re.search(r'mass volume=\[(\S+), (\S+)\]', p.stdout)
    return (float(m.group(1)), float(m.group(2))) if m else None


def one(design, node, preset, work):
    out = os.path.join(work, 'acc_%d.obj' % node)
    if os.path.exists(out):
        os.remove(out)
    t0 = time.time()
    p = subprocess.run([BIN, design, 'tess', str(node), out, str(preset)], capture_output=True, text=True, timeout=3600)
    rec = dict(design=os.path.basename(design), node=node, preset=preset, seconds=round(time.time() - t0, 2),
               tess=(p.stdout + p.stderr).strip().split('\n')[0][:160])
    ex = exact(design, node)
    rec['exact'] = ex
    if os.path.exists(out) and os.path.getsize(out) > 0:
        rec.update(mesh_stats(*obj(out)))
        if ex:
            mid = 0.5 * (ex[0] + ex[1])
            rec['rel_err'] = (rec['volume'] - mid) / mid
        os.remove(out)
    return rec


if __name__ == '__main__':
    preset, dest = int(sys.argv[1]), sys.argv[2]
    work = os.environ.get('TESS_WORK', '/var/tmp')
    rows = [one(d, n, preset, work) for d, n in CASES]
    sha = subprocess.run(['sha256sum', BIN], capture_output=True, text=True).stdout.split()[0]
    json.dump(dict(binary=BIN, sha256=sha, preset=preset, rows=rows), open(dest, 'w'), indent=1)
    for r in rows:
        print('%-12s %5d %7.1fs tris=%-7s err=%-10s unm=%-5s folds=%-5s %s' % (
            r['design'], r['node'], r['seconds'], r.get('tris'), ('%.5f' % r['rel_err']) if 'rel_err' in r else '-',
            r.get('unmatched'), r.get('folds'), '' if 'tris' in r else r['tess']))
