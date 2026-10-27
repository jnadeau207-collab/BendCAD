import json
import math
import random
import re
import sys

import numpy as np


def fl(x):
    return 'F64.neg(%rf64)' % -x if x < 0 or (x == 0 and math.copysign(1, x) < 0) else '%rf64' % x


def pt(i):
    return 'C.pt(%dn, %dn)' % (2 * i, 2 * i + 1)


def rigid(rng, n, mode):
    P = [(rng.uniform(-50, 50), rng.uniform(-50, 50)) for _ in range(n)]
    cs = []
    cid = [0]

    def nid():
        cid[0] += 1
        return cid[0]

    def dist(i, j):
        return math.dist(P[i], P[j])
    for i in range(n - 1):
        cs.append(('dist', nid(), i, i + 1, dist(i, i + 1)))
    for i in range(2, n):
        cs.append(('dist', nid(), 0, i, dist(0, i)))
    want = 'ok'
    if mode == 'redundant':
        i, j = rng.sample(range(n), 2)
        cs.append(('dist', nid(), i, j, dist(i, j)))
        want = 'redundant'
    if mode == 'conflict':
        i, j = rng.sample(range(n), 2)
        cs.append(('dist', nid(), i, j, dist(i, j) * 1.05 + 0.5))
        want = 'conflict'
    free = [True] * (2 * n)
    free[0] = free[1] = free[3] = False
    return P, free, cs, want


def frame(rng, mode):
    w, h = rng.uniform(5, 60), rng.uniform(5, 60)
    x0, y0 = rng.uniform(-20, 20), rng.uniform(-20, 20)
    P = [(x0, y0), (x0 + w, y0), (x0 + w, y0 + h), (x0, y0 + h)]
    cs = [('horiz', 1, 0, 1), ('vert', 2, 1, 2), ('horiz', 3, 2, 3), ('vert', 4, 3, 0), ('dist', 5, 0, 1, w), ('dist', 6, 1, 2, h)]
    if mode == 'perp':
        cs = [('horiz', 1, 0, 1), ('perp', 2, 0, 1, 1, 2), ('perp', 3, 1, 2, 2, 3), ('perp', 4, 2, 3, 3, 0), ('dist', 5, 0, 1, w), ('dist', 6, 1, 2, h)]
    if mode == 'angle':
        a = rng.uniform(0.3, 1.2)
        P = [(x0, y0), (x0 + w, y0), (x0 + w + h * math.cos(a), y0 + h * math.sin(a))]
        cs = [('horiz', 1, 0, 1), ('dist', 2, 0, 1, w), ('dist', 3, 1, 2, h), ('angle', 4, 0, 1, 1, 2, math.cos(a), math.sin(a))]
    free = [True] * (2 * len(P))
    free[0] = free[1] = False
    return P, free, cs, 'ok'


def cn_bend(c):
    k = c[0]
    if k == 'dist':
        return 'S.K_dist{%du64, %s, %s, %s}' % (c[1], pt(c[2]), pt(c[3]), fl(c[4]))
    if k == 'horiz':
        return 'S.K_horiz{%du64, %s, %s}' % (c[1], pt(c[2]), pt(c[3]))
    if k == 'vert':
        return 'S.K_vert{%du64, %s, %s}' % (c[1], pt(c[2]), pt(c[3]))
    if k == 'perp':
        return 'S.K_perp{%du64, %s, %s, %s, %s}' % (c[1], pt(c[2]), pt(c[3]), pt(c[4]), pt(c[5]))
    if k == 'angle':
        return 'S.K_angle{%du64, %s, %s, %s, %s, %s, %s}' % (c[1], pt(c[2]), pt(c[3]), pt(c[4]), pt(c[5]), fl(c[6]), fl(c[7]))


def resid(c, x):
    p = lambda i: np.array([x[2 * i], x[2 * i + 1]])
    k = c[0]
    if k == 'dist':
        return [np.linalg.norm(p(c[3]) - p(c[2])) - c[4]]
    if k == 'horiz':
        return [p(c[3])[1] - p(c[2])[1]]
    if k == 'vert':
        return [p(c[3])[0] - p(c[2])[0]]
    if k == 'perp':
        u, v = p(c[3]) - p(c[2]), p(c[5]) - p(c[4])
        return [float(u @ v) / (np.linalg.norm(u) * np.linalg.norm(v))]
    if k == 'angle':
        u, v = p(c[3]) - p(c[2]), p(c[5]) - p(c[4])
        u, v = u / np.linalg.norm(u), v / np.linalg.norm(v)
        return [u @ v - c[6], u[0] * v[1] - u[1] * v[0] - c[7]]


def rank_dof(cs, x, free):
    f = lambda y: np.concatenate([resid(c, y) for c in cs])
    J = []
    for i in range(len(x)):
        if not free[i]:
            continue
        e = np.zeros(len(x))
        e[i] = 1e-6
        J.append((f(x + e) - f(x - e)) / 2e-6)
    J = np.array(J).T
    r = np.linalg.matrix_rank(J, tol=1e-6 * max(1.0, np.abs(J).max()))
    return sum(free) - r


def gen(seed, count):
    rng = random.Random(seed)
    cases = []
    for k in range(count):
        kind = rng.choice(['rigid', 'rigid', 'redundant', 'conflict', 'frame', 'perp', 'angle'])
        if kind in ('rigid', 'redundant', 'conflict'):
            P, free, cs, want = rigid(rng, rng.randint(3, 7), kind)
        else:
            P, free, cs, want = frame(rng, kind)
        noise = rng.choice([0.01, 0.1, 0.3])
        scale = max(math.dist(a, b) for a in P for b in P)
        x0 = [v for q in P for v in q]
        start = [v + (rng.gauss(0, noise * scale) if free[i] else 0.0) for i, v in enumerate(x0)]
        cases.append(dict(tag='%s-%d' % (kind, k), kind=kind, want=want, truth=x0, start=start, free=free, cs=cs, noise=noise))
    return cases


def bend(cases, path):
    out = ['import Base', 'import ../../src/c05/solve.bend as S', 'import ../../tests/c05/check.bend as C', '']
    names = []
    for i, c in enumerate(cases):
        n = 'case_%d' % i
        names.append(n)
        out.append('def %s() -> String:' % n)
        out.append('  "%s " ++ C.sol([%s], [%s], [%s], 400n)' % (c['tag'], ', '.join(fl(v) for v in c['start']),
                   ', '.join('True{}' if f else 'False{}' for f in c['free']), ', '.join(cn_bend(k) for k in c['cs'])))
        out.append('')
    out.append('def pr(xs: List<&2, String>) -> IO(Unit):')
    out.append('  match xs:')
    out.append('    case []:')
    out.append('      do IO<Unit>:')
    out.append('        return Unit{}')
    out.append('    case h <> t:')
    out.append('      do IO<Unit>:')
    out.append('        IO.print(h)')
    out.append('        pr(t)')
    out.append('')
    chunks = [names[i:i + 60] for i in range(0, len(names), 60)]
    for j, ch in enumerate(chunks):
        out.append('def part_%d() -> List<&2, String>:' % j)
        out.append('  [%s]' % ', '.join(n + '()' for n in ch))
        out.append('')
    expr = 'part_0()'
    for j in range(1, len(chunks)):
        expr = 'List.append(&2, String, %s, part_%d())' % (expr, j)
    out.append('def main() -> IO(Unit):')
    out.append('  pr(%s)' % expr)
    open(path, 'w', newline='\n').write('\n'.join(out) + '\n')


def judge(cases, text):
    lines = {l.split(' ', 1)[0]: l.split(' ', 1)[1] for l in text.splitlines() if ' ' in l}
    rows = []
    for c in cases:
        got = lines.get(c['tag'], 'missing')
        row = dict(tag=c['tag'], kind=c['kind'], want=c['want'], noise=c['noise'], got=got[:200])
        exp_dof = rank_dof(c['cs'], np.array(c['truth']), c['free'])
        row['oracle_dof'] = int(exp_dof)
        m = re.match(r'ok dof=(\d+) red=\[([\d,]*)\] ps=(.*)', got)
        if m:
            ps = np.array([float(v) for v in m.group(3).split()])
            res = max(abs(r) for k in c['cs'] for r in resid(k, ps))
            scale = max(1.0, max(abs(v) for v in c['truth']))
            fixed_ok = all(abs(ps[i] - c['start'][i]) == 0 for i in range(len(ps)) if not c['free'][i])
            row.update(status='ok', dof=int(m.group(1)), red=[int(v) for v in m.group(2).split(',') if v], resid=float(res), fixed_kept=fixed_ok)
            if c['want'] == 'conflict':
                row['verdict'] = 'WRONG: inconsistent system reported solved' if res > 1e-6 * scale else 'odd: conflict reported ok within tol'
            else:
                bad = []
                if res > 1e-6 * scale:
                    bad.append('residual %.3g' % res)
                if row['dof'] != exp_dof:
                    bad.append('dof %d vs oracle %d' % (row['dof'], exp_dof))
                if c['want'] == 'redundant' and not row['red']:
                    bad.append('redundancy not named')
                if c['want'] == 'ok' and row['red']:
                    bad.append('spurious redundancy %s' % row['red'])
                if not fixed_ok:
                    bad.append('fixed parameter moved')
                row['verdict'] = 'PASS' if not bad else 'WRONG: ' + '; '.join(bad)
        elif got.startswith('conflict'):
            row['status'] = 'conflict'
            row['verdict'] = 'PASS' if c['want'] == 'conflict' else 'WRONG: consistent system reported conflict'
        elif got.startswith('unresolved'):
            row['status'] = 'unresolved'
            row['verdict'] = 'PASS' if c['want'] == 'conflict' else 'UNSOLVED-honest'
        elif got.startswith('err'):
            row['status'] = got
            row['verdict'] = 'FAIL-TO-SOLVE' if c['want'] != 'conflict' else 'weak: conflict reported as ' + got
        else:
            row['status'] = 'missing'
            row['verdict'] = 'MISSING'
        rows.append(row)
    return rows


def scale(seed, n):
    rng = random.Random(seed)
    P, free, cs, want = rigid(rng, n, 'rigid')
    x0 = [v for q in P for v in q]
    start = [v + (rng.gauss(0, 0.01 * 100) if free[i] else 0.0) for i, v in enumerate(x0)]
    return [dict(tag='big%d' % n, kind='rigid', want=want, truth=x0, start=start, free=free, cs=cs, noise=0.01)]


if __name__ == '__main__':
    cmd, seed, count, path = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    cases = scale(seed, count) if cmd.startswith('scale') else gen(seed, count)
    if cmd in ('gen', 'scale'):
        bend(cases, path)
    else:
        rows = judge(cases, open(sys.argv[5]).read())
        json.dump(rows, open(path, 'w'), indent=1)
        from collections import Counter
        print(Counter((r['kind'], r['verdict'].split(':')[0]) for r in rows))
        for r in rows:
            if r['verdict'] != 'PASS':
                print(r['tag'], r['noise'], r['verdict'], '|', r['got'][:120])
