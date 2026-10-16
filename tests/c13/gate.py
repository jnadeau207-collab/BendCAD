import glob
import hashlib
import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, 'gate-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
RUNNERS = ('e2e.py', 'neg.py', 'solid.py', 'solid_neg.py', 'zone.py', 'corpus.py', 'errors.py', 'perf.py')
SLOW = {'corpus.py': 10800.0, 'perf.py': 7200.0}
DEFAULT_TIMEOUT = 3600.0
RESULTS = []


def record(suite, ok, **info):
    RESULTS.append(dict(suite=suite, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + suite, {k: v for k, v in info.items() if k != 'reports'},
          flush=True)


def bin_hash():
    h = hashlib.sha256()
    with open(BIN, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def discover():
    found = []
    for p in sorted(glob.glob(os.path.join(ROOT, 'tests', '*', '*.py'))):
        if '__pycache__' in p or os.path.basename(p) not in RUNNERS:
            continue
        found.append(p)
    return found


def fresh_reports(d, start):
    reps = []
    for p in glob.glob(os.path.join(d, '*-report.json')):
        if os.path.basename(p) == 'gate-report.json':
            continue
        if os.path.getmtime(p) >= start:
            try:
                reps.append((p, json.load(open(p))))
            except Exception:
                pass
    return reps


def run_suite(path):
    suite = os.path.relpath(path, ROOT)
    d = os.path.dirname(path)
    start = time.time()
    timeout = SLOW.get(os.path.basename(path), DEFAULT_TIMEOUT)
    try:
        r = subprocess.run([sys.executable, path], capture_output=True, text=True, timeout=timeout,
                           env=dict(os.environ, BENDCAD_BIN=BIN, BEND_NO_TELEMETRY='1',
                                    MSYS_NO_PATHCONV='1'))
        rc, tail = r.returncode, (r.stdout + r.stderr)[-500:]
    except subprocess.TimeoutExpired as e:
        record(suite, False, rc='timeout', seconds=timeout, detail=str(e)[:300])
        return
    secs = round(time.time() - start, 1)
    reps = fresh_reports(d, start)
    if not reps:
        record(suite, False, rc=rc, seconds=secs, detail='no-fresh-report', tail=tail)
        return
    passed = sum(int(r[1].get('passed', sum(1 for x in r[1].get('results', []) if x.get('ok')))) for r in reps)
    total = sum(int(r[1].get('total', len(r[1].get('results', [])))) for r in reps)
    hashes = {r[1].get('binary_sha256') for r in reps if r[1].get('binary_sha256')}
    ok = rc == 0 and passed == total and total > 0
    record(suite, ok, rc=rc, seconds=secs, passed=passed, total=total,
           binary_sha256=sorted(hashes), reports=[os.path.basename(r[0]) for r in reps],
           detail=None if ok else tail)


def main():
    t0 = time.time()
    want = [a for a in sys.argv[1:] if not a.startswith('-')]
    suites = [p for p in discover() if not want or any(w in os.path.relpath(p, ROOT) for w in want)]
    if not suites:
        print('gate: no suites match')
        sys.exit(2)
    start_hash = bin_hash()
    for p in suites:
        run_suite(p)
    end_hash = bin_hash()
    swapped = start_hash != end_hash
    foreign = sorted((r['suite'], h) for r in RESULTS for h in (r.get('binary_sha256') or [])
                     if h != end_hash)
    if swapped:
        for r in RESULTS:
            r['ok'] = False
            r['detail'] = f'binary-swapped-mid-run: {start_hash} -> {end_hash}'
    rep = dict(binary=BIN, binary_sha256=end_hash, binary_swapped=swapped,
               foreign_hashes=[dict(suite=s, binary_sha256=h) for s, h in foreign],
               suites_passed=sum(r['ok'] for r in RESULTS), suites_total=len(RESULTS),
               journeys_passed=sum(r.get('passed', 0) for r in RESULTS),
               journeys_total=sum(r.get('total', 0) for r in RESULTS),
               wall_seconds=round(time.time() - t0, 1), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"gate: {rep['suites_passed']}/{rep['suites_total']} suites, "
          f"{rep['journeys_passed']}/{rep['journeys_total']} journeys, {rep['wall_seconds']}s",
          flush=True)
    sys.exit(0 if rep['suites_passed'] == rep['suites_total'] else 1)


if __name__ == '__main__':
    main()
