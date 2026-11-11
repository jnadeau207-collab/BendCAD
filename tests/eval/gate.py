import json
import os
import sys
import time
from concurrent.futures import ProcessPoolExecutor

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fuzz

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(HERE, 'gate-baseline.json')
SEEDS = [3, 4, 5, 9, 10, 11, 12, 15, 19, 20, 23, 29, 37, 38, 41, 46, 49, 55, 58, 60, 61, 63, 64, 72, 73, 74, 81, 84, 85, 86, 92, 106, 112, 115, 116, 117, 131, 143, 145, 146, 149, 150]


def compare(base, new):
    bad, gain, slow = [], [], []
    b = {c['seed']: c for c in base['cases']}
    for c in new['cases']:
        o = b.get(c['seed'])
        if c.get('id_ui') is False or c.get('id_di') is False:
            bad.append(f"seed {c['seed']}: volume identity violated")
        if c.get('occt_ok') is False:
            bad.append(f"seed {c['seed']}: OCCT disagrees ({c.get('occt_v')} vs {c['ops']['union'].get('v')})")
        if not o:
            continue
        for op, r in c['ops'].items():
            p = o['ops'].get(op, {})
            if p.get('ok') and not r['ok']:
                bad.append(f"seed {c['seed']} {op}: committed before, now refused: {r.get('why')}")
            elif r['ok'] and not p.get('ok'):
                gain.append(f"seed {c['seed']} {op}: refused before, now commits")
            elif r['ok'] and p.get('ok') and r.get('v') and p.get('v'):
                lo, hi = max(r['v'][0], p['v'][0]), min(r['v'][1], p['v'][1])
                if lo > hi + 1e-9 * max(1.0, abs(hi)):
                    bad.append(f"seed {c['seed']} {op}: certified volume {r['v']} disjoint from baseline {p['v']}")
            if p.get('s') and p.get('ok') == r['ok'] and r['s'] > 2.0 * p['s'] + 5.0:
                slow.append(f"seed {c['seed']} {op}: {p['s']} s -> {r['s']} s")
    return bad, gain, slow


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser(description='Fixed fuzz subset compared with gate-baseline.json; exit 1 on any regression.')
    ap.add_argument('--jobs', type=int, default=os.cpu_count())
    ap.add_argument('--out', default='/tmp/bendcad-gate.json')
    ap.add_argument('--seeds', default='')
    ap.add_argument('--write-baseline', action='store_true')
    a = ap.parse_args()
    seeds = [int(s) for s in a.seeds.split(',') if s] or (json.load(open(BASE))['seeds'] if os.path.exists(BASE) else SEEDS)
    os.makedirs(fuzz.WORK, exist_ok=True)
    t0 = time.time()
    with ProcessPoolExecutor(a.jobs) as ex:
        recs = list(ex.map(fuzz.one, seeds))
    rep = dict(binary=fuzz.BIN, seeds=seeds, seconds=round(time.time() - t0, 1), summary=fuzz.summarize(recs), cases=recs)
    json.dump(rep, open(a.out, 'w'), indent=1)
    if a.write_baseline:
        json.dump(rep, open(BASE, 'w'), indent=1)
        print(f'baseline written: {len(seeds)} seeds, {rep["summary"]["committed"]}/{rep["summary"]["ops"]} committed, {rep["seconds"]} s')
        sys.exit(0)
    bad, gain, slow = compare(json.load(open(BASE)), rep)
    for x in gain:
        print('GAIN', x)
    for x in slow:
        print('SLOW', x)
    for x in bad:
        print('FAIL', x)
    s = rep['summary']
    print(f"{s['committed']}/{s['ops']} committed, {len(bad)} regressions, {len(slow)} slowdowns, {len(gain)} gains, {rep['seconds']} s")
    sys.exit(1 if bad or slow else 0)
