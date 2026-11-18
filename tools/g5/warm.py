import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
from kq import kq, DESIGN, BIN, PORT

PARTS = [10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 23, 24, 28, 29, 30, 32, 34, 31, 33, 35, 36,
         4201, 4202, 4203, 4204, 4211, 4212, 4213, 4214, 4221, 4222, 4223, 4224, 22, 26, 27, 19]

if __name__ == '__main__':
    out = '/var/tmp/g5warm.json'
    rows = json.load(open(out)) if os.path.exists(out) and len(sys.argv) > 1 and sys.argv[1] == 'resume' else {}
    for n in PARTS:
        if str(n) in rows:
            continue
        t = time.time()
        txt = kq('mass', str(n))
        rows[str(n)] = dict(s=round(time.time() - t, 1), mass=next((l for l in txt.splitlines() if l.startswith('mass ')), None),
                            moments=next((l[:240] for l in txt.splitlines() if l.startswith('moments ')), None),
                            material=next((l for l in txt.splitlines() if l.startswith('material ')), None),
                            error=None if 'mass ' in txt else txt.strip()[-500:])
        json.dump(dict(rows, _meta=dict(design=DESIGN, binary=BIN, port=PORT)) if False else rows, open(out, 'w'), indent=1)
        print(n, rows[str(n)]['s'], (rows[str(n)]['mass'] or rows[str(n)]['error'] or '')[:140], flush=True)
