import json
import os
import re
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad-a15')
WORK = os.environ.get('REPRO_WORK', '/var/tmp/repro')
OUT = os.environ.get('REPRO_OUT', os.path.join(ROOT, 'docs', 'receipts', 'briefs', 'repro.json'))


def fill(s, env):
    return re.sub(r'\{(\w+)\}', lambda m: env.get(m.group(1), m.group(0)), s)


def step(design, st, env, default_limit):
    args = [fill(a, env) for a in st['args']]
    lim = st.get('limit_s', default_limit)
    t0 = time.time()
    try:
        p = subprocess.run([BIN, design, *args], capture_output=True, text=True, timeout=lim)
        out, timed = p.stdout + p.stderr, False
    except subprocess.TimeoutExpired as ex:
        out, timed = (ex.stdout or b'').decode() if isinstance(ex.stdout, bytes) else (ex.stdout or ''), True
    s = round(time.time() - t0, 3)
    miss = [r for r in st.get('must', []) if not re.search(fill(r, env), out, re.M)]
    bad = [r for r in st.get('must_not', []) if re.search(fill(r, env), out, re.M)]
    for k, r in st.get('capture', {}).items():
        m = re.search(r, out, re.M)
        if m:
            env[k] = m.group(1)
        else:
            miss.append(f'capture {k}: {r}')
    v = 'timeout' if timed else 'pass' if not miss and not bad else 'fail'
    return dict(cmd='BIN design.bcd ' + ' '.join(args), seconds=s, limit_s=lim, verdict=v, missing=miss, forbidden=bad,
                output_head=out[:1500])


def case(name):
    d = os.path.join(HERE, name)
    ex = json.load(open(os.path.join(d, 'expect.json'), encoding='utf-8'))
    wd = os.path.join(WORK, name)
    shutil.rmtree(wd, ignore_errors=True)
    os.makedirs(wd)
    design = os.path.join(wd, 'design.bcd')
    shutil.copy(os.path.join(d, 'design.bcd'), design)
    env, rows = {}, []
    for st in ex['steps']:
        rows.append(step(design, st, env, ex.get('limit_s', 120)))
        if rows[-1]['verdict'] != 'pass' and st.get('stop_on_fail', True):
            break
    ok = len(rows) == len(ex['steps']) and all(r['verdict'] == 'pass' for r in rows)
    shutil.rmtree(wd, ignore_errors=True)
    return dict(case=name, item=ex.get('item'), claim=ex.get('claim', ''), verdict='pass' if ok else 'fail',
                seconds=round(sum(r['seconds'] for r in rows), 3), steps=rows)


def main():
    want = sys.argv[1:]
    names = sorted(n for n in os.listdir(HERE) if os.path.exists(os.path.join(HERE, n, 'expect.json')) and (not want or n in want))
    sha = subprocess.run(['sha256sum', BIN], capture_output=True, text=True).stdout.split()[0]
    cases = []
    for n in names:
        c = case(n)
        cases.append(c)
        print(f"{c['verdict']:5} {c['seconds']:8.2f} s  {n}", flush=True)
    rep = dict(binary=BIN, sha256=sha, passed=sum(c['verdict'] == 'pass' for c in cases), total=len(cases), cases=cases)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(rep, open(OUT, 'w', encoding='utf-8', newline='\n'), indent=1)
    print(f"{rep['passed']}/{rep['total']} pass -> {OUT}")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
