import json
import random
import re
import sys
from collections import Counter

from shapely.geometry import LineString, MultiLineString
from shapely.ops import polygonize, unary_union


def fl(x):
    return 'F64.neg(%rf64)' % -x if x < 0 else '%rf64' % x


def gen(seed, count):
    rng = random.Random(seed)
    cases = []
    for k in range(count):
        kind = rng.choice(['grid', 'float', 'polys'])
        segs = []
        if kind == 'grid':
            for _ in range(rng.randint(2, 9)):
                a = (rng.randint(0, 6), rng.randint(0, 6))
                b = (rng.randint(0, 6), rng.randint(0, 6))
                if a != b:
                    segs.append((float(a[0]), float(a[1]), float(b[0]), float(b[1])))
        elif kind == 'float':
            for _ in range(rng.randint(2, 9)):
                segs.append(tuple(rng.uniform(-10, 10) for _ in range(4)))
        else:
            for _ in range(rng.randint(1, 3)):
                cx, cy, r, n = rng.uniform(-5, 5), rng.uniform(-5, 5), rng.uniform(1, 5), rng.randint(3, 6)
                import math
                pts = [(cx + r * math.cos(2 * math.pi * i / n + 0.3), cy + r * math.sin(2 * math.pi * i / n + 0.3)) for i in range(n)]
                for i in range(n):
                    segs.append((*pts[i], *pts[(i + 1) % n]))
        cases.append(dict(tag='%s-%d' % (kind, k), kind=kind, segs=segs))
    return cases


def bend(cases, path):
    out = ['import Base', 'import ../../src/c05/arrange.bend as A', 'import ../../tests/c05/check.bend as C', '']
    names = []
    for i, c in enumerate(cases):
        n = 'case_%d' % i
        names.append(n)
        segs = ', '.join('A.Seg{%du64, %s, %s, %s, %s}' % (10 * (j + 1), *map(fl, s)) for j, s in enumerate(c['segs']))
        out += ['def %s() -> String:' % n, '  "%s " ++ C.arr([%s], 2000n)' % (c['tag'], segs), '']
    out += ['def pr(xs: List<&2, String>) -> IO(Unit):', '  match xs:', '    case []:', '      do IO<Unit>:', '        return Unit{}',
            '    case h <> t:', '      do IO<Unit>:', '        IO.print(h)', '        pr(t)', '']
    chunks = [names[i:i + 60] for i in range(0, len(names), 60)]
    for j, ch in enumerate(chunks):
        out += ['def part_%d() -> List<&2, String>:' % j, '  [%s]' % ', '.join(n + '()' for n in ch), '']
    expr = 'part_0()'
    for j in range(1, len(chunks)):
        expr = 'List.append(&2, String, %s, part_%d())' % (expr, j)
    out += ['def main() -> IO(Unit):', '  pr(%s)' % expr]
    open(path, 'w', newline='\n').write('\n'.join(out) + '\n')


def oracle(segs):
    if not segs:
        return 0, 0, 0, 0
    u = unary_union([LineString([(s[0], s[1]), (s[2], s[3])]) for s in segs])
    lines = list(u.geoms) if isinstance(u, MultiLineString) else [u]
    verts = set()
    for l in lines:
        for p in l.coords:
            verts.add((round(p[0], 9), round(p[1], 9)))
    faces = list(polygonize(lines))
    comps = unary_union(lines)
    from shapely.geometry import Polygon
    ncomp = len(list(comps.geoms)) if hasattr(comps, 'geoms') else 1
    return len(verts), len(lines), len(faces), sum(f.area for f in faces)


def judge(cases, text):
    got = {l.split(' ', 1)[0]: l.split(' ', 1)[1] for l in text.splitlines() if ' ' in l}
    rows = []
    for c in cases:
        g = got.get(c['tag'], 'missing')
        v, e, f, area = oracle(c['segs'])
        m = re.match(r'v=(\d+) e=(\d+) c=(\d+) R(.*) D(.*)', g)
        row = dict(tag=c['tag'], kind=c['kind'], got=g[:300], oracle=dict(v=v, e=e, faces=f))
        if not m:
            row['verdict'] = 'ERR ' + g[:80]
        else:
            gv, ge, gc = int(m.group(1)), int(m.group(2)), int(m.group(3))
            nreg = m.group(4).count('{')
            bad = []
            if gv != v:
                bad.append('v %d vs %d' % (gv, v))
            if ge != e:
                bad.append('e %d vs %d' % (ge, e))
            if nreg != f:
                bad.append('faces %d vs %d' % (nreg, f))
            if nreg != ge - gv + gc:
                bad.append('euler: faces %d != e-v+c %d' % (nreg, ge - gv + gc))
            row['verdict'] = 'PASS' if not bad else 'WRONG: ' + '; '.join(bad)
        rows.append(row)
    return rows


if __name__ == '__main__':
    cmd, seed, count, path = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    cases = gen(seed, count)
    if cmd == 'gen':
        bend(cases, path)
    else:
        rows = judge(cases, open(sys.argv[5]).read())
        json.dump(rows, open(path, 'w'), indent=1)
        print(Counter((r['kind'], r['verdict'].split(':')[0].split(' ')[0]) for r in rows))
        for r in rows:
            if r['verdict'] != 'PASS':
                print(r['tag'], r['verdict'], '|', r['got'][:100])
