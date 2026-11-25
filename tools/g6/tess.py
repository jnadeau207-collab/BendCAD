import json
import os
import re
import sys
import time
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(__file__))
import humphrey as H
import asm as ASM

REC = os.path.join(H.ROOT, 'docs', 'receipts', 'g6')
OUT = os.environ.get('G6_TESS_OUT', '/home/jesse/g6/tess')
FLOW = [('impeller', 19), ('shroud', 23), ('diffuser', 24), ('rdc', 40), ('stator', 42), ('turbine', 27), ('nozzle', 28)]


def conform(path):
    tris = []
    for ln in open(path, encoding='utf-8'):
        if ln.startswith('f '):
            tris.append([int(x.split('/')[0]) for x in ln.split()[1:4]])
    d = Counter()
    for a, b, c in tris:
        for e in ((a, b), (b, c), (c, a)):
            d[e] += 1
    und = defaultdict(int)
    for (a, b), k in d.items():
        und[(min(a, b), max(a, b))] += k
    same = sum(1 for k in d.values() if k > 1)
    uses = Counter(und.values())
    return dict(triangles=len(tris), same_direction=same, edge_uses=dict(uses), closed=same == 0 and set(uses) == {2})


def one(item):
    name, node = item
    p = os.path.join(OUT, name + '.obj')
    out, s = ASM.kernel('tess', str(node), p, '3')
    head = out.strip().splitlines()[0] if out.strip() else ''
    c = conform(p) if head.startswith('wrote') and os.path.exists(p) else None
    m = re.search(r'chord-bound=(\S+)', head)
    row = dict(part=name, node=node, seconds=s, kernel=head[:400], chord_bound=m.group(1) if m else None, mesh=c,
               verdict='pass' if c and c['closed'] else 'fail')
    print(row['verdict'].upper(), name, s, 's', head[:160], c, flush=True)
    return row


def main():
    os.makedirs(OUT, exist_ok=True)
    jobs = int(os.environ.get('G6_TESS_JOBS', '1'))
    order = sorted(FLOW, key=lambda f: f[0] not in ('stator', 'turbine'))
    with ThreadPoolExecutor(max_workers=jobs) as ex:
        done = dict(zip(order, ex.map(one, order)))
    rows = [done[f] for f in FLOW]
    rep = dict(source='bendcad tess NODE OUT 3 (manufacturing preset: chord 0.05 mm, angle 0.01 rad) on the flow-path parts; closure counted from the OBJ',
               binary=ASM.BIN, design=ASM.DESIGN, green=all(r['verdict'] == 'pass' for r in rows), rows=rows)
    json.dump(rep, open(os.path.join(REC, 'tess.json'), 'w', encoding='utf-8'), indent=1)


if __name__ == '__main__':
    main()
