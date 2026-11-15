import json
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OLD = os.environ.get('OLD_BIN', '/home/jesse/bc/bendcad-p6o')
NEW = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = os.environ.get('CLEAR_WORK', '/var/tmp/clear-e2e')
OUT = os.environ.get('CLEAR_OUT', os.path.join(ROOT, 'docs', 'receipts', 'clear', 'crossing.json'))
LIMIT = float(os.environ.get('CLEAR_LIMIT', '180'))

EDITS = [
    '(node 1 (box 40 30 8) (intent create any 0 1 0))',
    '(node 2 (holes 1 (face 1 0 top) through (hole 20 15 6)) (intent remove any any 1 1))',
    '(node 3 (cylinder 6.05 20) (intent create any 0 1 0))',
    '(node 4 (move 3 20 15 -6 0) (intent same any any 1 0))',
    '(node 5 (cylinder 5.9 20) (intent create any 0 1 0))',
    '(node 6 (move 5 20 15 -6 0) (intent same any any 1 0))',
    '(node 7 (box 4 4 4) (intent create any 0 1 0))',
    '(node 8 (move 7 5 5 2 0) (intent same any any 1 0))',
    '(node 9 (box 10 10 8) (intent create any 0 1 0))',
    '(node 10 (move 9 40 0 0 0) (intent same any any 1 0))',
    '(node 11 (move 7 34 24 6 0) (intent same any any 1 0))',
    '(node 12 (rotate 3 x 30) (intent same any any 1 0))',
    '(node 13 (move 12 20 15 4 0) (intent same any any 1 0))',
    '(node 14 (move 7 100 0 0 0) (intent same any any 1 0))',
    '(node 15 (union 8 14) (intent add any any 2 0))',
]

CASES = [
    ('oversize pin through the hole', '2', '4', 'interference', True),
    ('the same pair the other way round', '4', '2', 'interference', True),
    ('fit pin, 0.1 radial', '2', '6', 'clearance', False),
    ('cube buried in the plate material', '2', '8', 'nested', False),
    ('block touching the end face', '2', '10', 'touching', False),
    ('cube through the top corner', '2', '11', 'interference', True),
    ('oversize pin tilted 30 degrees through the hole', '2', '13', 'interference', True),
    ('two solids: one buried in the plate, one far away', '2', '15', 'nested', False),
    ('thinner pin inside the thicker one, end caps shared', '4', '6', 'interference', False),
]


def run(binary, design, *args, limit=LIMIT):
    t0 = time.time()
    try:
        p = subprocess.run([binary, design, *args], capture_output=True, text=True, timeout=limit)
        return (p.stdout + p.stderr).strip(), round(time.time() - t0, 3), False
    except subprocess.TimeoutExpired:
        return '', round(time.time() - t0, 3), True


def main():
    os.makedirs(WORK, exist_ok=True)
    design = os.path.join(WORK, 'design.bcd')
    if os.path.exists(design):
        os.remove(design)
    run(NEW, design, 'new')
    out, _, _ = run(NEW, design, 'apply', *EDITS)
    sha = {b: subprocess.run(['sha256sum', b], capture_output=True, text=True).stdout.split()[0] for b in (OLD, NEW)}
    rep = dict(old=OLD, new=NEW, sha256=sha, design=EDITS, committed=out.endswith('committed'), cases=[])
    if not rep['committed']:
        rep['apply'] = out[-2000:]
    for name, a, b, kind, fast in CASES:
        o, ot, otime = run(OLD, design, 'clearance', a, b)
        n, nt, ntime = run(NEW, design, 'clearance', a, b)
        row = dict(case=name, pair=[a, b], kind=kind, old=o, old_s=ot, old_timeout=otime, new=n, new_s=nt, new_timeout=ntime)
        row['identical'] = (not otime) and (not ntime) and o == n
        row['interference'] = n.endswith('state=interference')
        row['ok'] = row['identical'] and row['interference'] == (kind == 'interference') and (not fast or nt <= 2.0)
        rep['cases'].append(row)
        print(f"{'PASS' if row['ok'] else 'FAIL'} {name}: old {ot} s{' TIMEOUT' if otime else ''}, new {nt} s | {n[:110]}", flush=True)
    rep['passed'] = sum(c['ok'] for c in rep['cases'])
    rep['total'] = len(rep['cases'])
    rep['ok'] = rep['committed'] and rep['passed'] == rep['total']
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='') as f:
        json.dump(rep, f, indent=1)
    print(f"{rep['passed']}/{rep['total']} pass, design committed={rep['committed']} -> {OUT}")
    sys.exit(0 if rep['ok'] else 1)


main()
