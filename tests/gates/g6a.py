import collections
import json
import os
import sys
import time
from concurrent.futures import ProcessPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, 'tests', 'eval'))
import fuzz

OUT = os.environ.get('G6A_OUT', os.path.join(ROOT, 'docs', 'receipts', 'gates', 'g6a.json'))
RATE, P95 = 0.99, 10.0


def pct(xs, q):
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(round(q * (len(xs) - 1))))] if xs else None


def judge(recs):
    by = collections.defaultdict(lambda: [0, 0])
    secs, wrong, ident = [], [], []
    for c in recs:
        key = '%s x %s / %s' % (*sorted((c['a'], c['b'])), c['mode'])
        for op, r in c['ops'].items():
            by[key][1] += 1
            by[key][0] += 1 if r['ok'] else 0
            if r.get('s') is not None:
                secs.append(r['s'])
        if c.get('occt_ok') is False:
            wrong.append(dict(seed=c['seed'], kernel=c['ops']['union'].get('v'), occt=c.get('occt_v')))
        if c.get('id_ui') is False or c.get('id_di') is False:
            ident.append(c['seed'])
    ops = sum(v[1] for v in by.values())
    com = sum(v[0] for v in by.values())
    weak = {k: f'{v[0]}/{v[1]}' for k, v in sorted(by.items()) if v[0] < RATE * v[1]}
    p95 = pct(secs, 0.95)
    checks = [
        dict(check=f'commit rate >= {RATE:.0%} overall', status='pass' if com >= RATE * ops else 'fail', evidence=f'{com}/{ops} = {com / max(ops, 1):.3f}'),
        dict(check=f'commit rate >= {RATE:.0%} in every pair and mode', status='pass' if not weak else 'fail', evidence=f'{len(weak)} groups below: {weak}'),
        dict(check='0 wrong answers against OCCT', status='pass' if not wrong else 'fail', evidence=f'{len(wrong)} mismatches {wrong[:5]}'),
        dict(check='0 volume-identity violations', status='pass' if not ident else 'fail', evidence=f'{len(ident)} seeds {ident[:10]}'),
        dict(check=f'p95 operation time < {P95} s', status='pass' if p95 is not None and p95 < P95 else 'fail', evidence=f'p95 {p95} s over {len(secs)} operations'),
    ]
    return checks


def main(n, jobs, s0):
    seeds = list(range(s0, s0 + n))
    os.makedirs(fuzz.WORK, exist_ok=True)
    t0 = time.time()
    with ProcessPoolExecutor(jobs) as ex:
        recs = list(ex.map(fuzz.one, seeds))
    checks = judge(recs)
    rep = dict(gate='G6a robustness', binary=fuzz.BIN, seeds=[s0, s0 + n - 1], seconds=round(time.time() - t0, 1), ready=all(c['status'] == 'pass' for c in checks),
               checks=checks, summary=fuzz.summarize(recs), cases=recs)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(rep, open(OUT, 'w', encoding='utf-8'), indent=1)
    for c in checks:
        print(f"{c['status'].upper():5s} {c['check']}: {c['evidence'][:300]}")
    print('G6a', 'PASS' if rep['ready'] else 'FAIL', sum(c['status'] == 'pass' for c in checks), '/', len(checks))
    sys.exit(0 if rep['ready'] else 1)


if __name__ == '__main__':
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 150, int(sys.argv[2]) if len(sys.argv) > 2 else 8, int(sys.argv[3]) if len(sys.argv) > 3 else 1)
