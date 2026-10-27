import concurrent.futures
import math
import os
import subprocess
import sys
import time


def design(n):
    pts = [(12 * math.cos(2 * math.pi * k / n), 12 * math.sin(2 * math.pi * k / n)) for k in range(n)]
    path = '(path %.9f %.9f %s)' % (pts[0][0], pts[0][1], ' '.join('(line %.9f %.9f)' % p for p in pts[1:]))
    return ('(bendcad 1)\n(node 1 (prism 0.025 35.025 (region %s)) (intent create any 0 1 0))\n'
            '(node 2 (prism -34.35 10 (region (circle 0 0 8))) (intent create any 0 1 0))\n'
            '(node 3 (union 1 2) (intent add any any 1 0))\n') % path


def one(binp, out, n):
    f = os.path.join(out, 'u%d.bcd' % n)
    open(f, 'w').write(design(n))
    t0 = time.time()
    p = subprocess.run([binp, f, 'measure', '3'], capture_output=True, text=True)
    return n, time.time() - t0, p.stdout


if __name__ == '__main__':
    binp, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(5) as ex:
        rows = list(ex.map(lambda n: one(binp, out, n), [16, 32, 64, 128, 256]))
    for n, dt, txt in rows:
        print('n=%d %.2f s %s' % (n, dt, txt.split('|')[1].strip()[:60] if '|' in txt else txt[:60]))
