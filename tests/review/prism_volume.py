import math
import os
import random
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'eval'))
import fuzz

out = sys.argv[1]
worst = 0.0
for seed in range(1, 41):
    rng = random.Random(seed)
    n = rng.randint(3, 7)
    rad = rng.uniform(5, 15)
    pts = [(rad * math.cos(2 * math.pi * k / n + rng.uniform(-0.2, 0.2)), rad * math.sin(2 * math.pi * k / n + rng.uniform(-0.2, 0.2))) for k in range(n)]
    h = rng.uniform(4, 25)
    path = f'(path {fuzz.f(pts[0][0])} {fuzz.f(pts[0][1])} ' + ' '.join(f'(line {fuzz.f(x)} {fuzz.f(y)})' for x, y in pts[1:] + [pts[0]]) + ')'
    if os.path.exists(out):
        os.remove(out)
    fuzz.run(out, 'new')
    o, _ = fuzz.run(out, 'apply', f'(node 1 (prism 0.0 {fuzz.f(h)} (region {path})) {fuzz.IC})')
    v = fuzz.vol(fuzz.nline(o, 1))
    area = 0.5 * abs(sum(pts[i][0] * pts[(i + 1) % n][1] - pts[(i + 1) % n][0] * pts[i][1] for i in range(n)))
    exact = area * h
    inside = v is not None and v[0] <= exact <= v[1]
    rel = None if v is None else abs(0.5 * (v[0] + v[1]) - exact) / exact
    worst = max(worst, rel or 0.0)
    if not inside:
        print(seed, 'sides', n, 'exact', exact, 'kernel', v, 'rel', rel)
print('worst relative difference', worst)
