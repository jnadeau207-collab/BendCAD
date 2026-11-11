import json
import os
import random
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, 'tests', 'eval'))
import fuzz

BIN = os.environ.get('BENDCAD_BIN', fuzz.BIN)
WORK = os.environ.get('REDUCE_WORK', '/tmp/bendcad-reduce')
CORPUS = os.path.join(ROOT, 'tests', 'corpus', 'k1')
INTENT = {'union': 'add', 'intersection': 'same', 'difference': 'remove'}
NUM = re.compile(r'-?\d+\.\d+(?:e-?\d+)?')


def case_edits(seed):
    rng = random.Random(seed)
    ka, kb = rng.choice(fuzz.KINDS), rng.choice(fuzz.KINDS)
    mode = rng.choice(fuzz.MODES)
    ea, _ = fuzz.shape(rng, 1, ka)
    eb, _ = fuzz.shape(rng, 2, kb)
    pe, bnode = fuzz.place(rng, 2, 10, mode)
    return ea + eb + pe, bnode, (ka, kb, mode)


def klass(line):
    m = re.search(r'error ([\w-]+) \| ([^|@]*)[^|]*\| why: ([\w-]+)', line)
    k = re.search(r'\[k1 reason (\d+)\]', line)
    return None if not m else (m.group(1), m.group(3), k.group(1) if k else None)


def attempt(edits, bnode, op, tag):
    d = f'{WORK}/{tag}.bcd'
    if os.path.exists(d):
        os.remove(d)
    subprocess.run([BIN, d, 'new'], capture_output=True)
    base = subprocess.run([BIN, d, 'apply', *edits], capture_output=True, text=True, timeout=1800).stdout
    if 'committed' not in base:
        return 'base', None
    ed = f'(node 100 ({op} 1 {bnode}) (intent {INTENT[op]} any any any any))'
    out = subprocess.run([BIN, d, 'apply', ed], capture_output=True, text=True, timeout=1800).stdout
    m = re.search(r'measured material=(\w+)', out)
    if m and 'declared material' in out:
        out = subprocess.run([BIN, d, 'apply', ed.replace(f'intent {INTENT[op]}', f'intent {m.group(1)}')], capture_output=True, text=True,
                             timeout=1800).stdout
    if 'committed' in out:
        return 'ok', None
    ln = next((l for l in out.splitlines() if l.startswith('node 100:')), out[:300])
    return 'refused', klass(ln)


def drop_rotations(edits, bnode):
    variants = []
    for i, e in enumerate(edits):
        m = re.match(r'\(node (\d+) \(rotate (\d+) ', e)
        if not m:
            continue
        me, src = m.group(1), m.group(2)
        rest = [re.sub(rf'\((rotate|move) {me} ', rf'(\1 {src} ', x) for j, x in enumerate(edits) if j != i]
        nb = bnode if int(me) != bnode else int(src)
        variants.append((rest, nb))
    return variants


def round_all(edits, sig):
    return [NUM.sub(lambda m: repr(float(f'{float(m.group(0)):.{sig}g}')), e) for e in edits]


def reduce(seed, op):
    os.makedirs(WORK, exist_ok=True)
    edits, bnode, info = case_edits(seed)
    st, want = attempt(edits, bnode, op, f's{seed}')
    if st != 'refused':
        return dict(seed=seed, op=op, status=st)
    steps = 0
    changed = True
    while changed:
        changed = False
        for ve, vb in drop_rotations(edits, bnode):
            if attempt(ve, vb, op, f's{seed}')[1] == want:
                edits, bnode, changed, steps = ve, vb, True, steps + 1
                break
    for sig in (1, 2, 3, 4, 6, 8, 12):
        ve = round_all(edits, sig)
        if ve != edits and attempt(ve, bnode, op, f's{seed}')[1] == want:
            edits, steps = ve, steps + 1
            break
    return dict(seed=seed, op=op, kinds=info, refusal=want, bnode=bnode, steps=steps, edits=edits)


def save(r):
    os.makedirs(CORPUS, exist_ok=True)
    name = f"s{r['seed']}-{r['op']}"
    with open(os.path.join(CORPUS, name + '.json'), 'w') as f:
        json.dump(r, f, indent=1)
    return name


def replay():
    rows = []
    for p in sorted(os.listdir(CORPUS)):
        if not p.endswith('.json'):
            continue
        r = json.load(open(os.path.join(CORPUS, p)))
        st, k = attempt(r['edits'], r['bnode'], r['op'], 'replay')
        rows.append(dict(case=p[:-5], expected=r['refusal'], now=st if st != 'refused' else k,
                         status='still-refused' if k == tuple(r['refusal']) or k == r['refusal'] else ('FIXED' if st == 'ok' else 'CHANGED')))
        print(f"{rows[-1]['status']:14s} {p[:-5]:28s} expected {r['refusal']} now {rows[-1]['now']}", flush=True)
    return rows


if __name__ == '__main__':
    if sys.argv[1] == 'replay':
        rows = replay()
        print(f"{sum(r['status'] == 'FIXED' for r in rows)} fixed, {sum(r['status'] == 'CHANGED' for r in rows)} changed class, "
              f"{sum(r['status'] == 'still-refused' for r in rows)} still refused")
    else:
        for spec in sys.argv[1:]:
            s, op = spec.split(':')
            r = reduce(int(s), op)
            print(json.dumps({k: v for k, v in r.items() if k != 'edits'}), flush=True)
            if 'edits' in r:
                save(r)
