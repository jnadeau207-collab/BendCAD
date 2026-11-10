import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'eval'))
import fuzz

seed, out = int(sys.argv[1]), sys.argv[2]
rng = random.Random(seed)
ka, kb = rng.choice(fuzz.KINDS), rng.choice(fuzz.KINDS)
mode = rng.choice(fuzz.MODES)
ea, _ = fuzz.shape(rng, 1, ka)
eb, _ = fuzz.shape(rng, 2, kb)
pe, bnode = fuzz.place(rng, 2, 10, mode)
if os.path.exists(out):
    os.remove(out)
fuzz.run(out, 'new')
o, dt = fuzz.run(out, 'apply', *ea, *eb, *pe)
print(seed, ka, kb, mode, 'bnode', bnode, 'base', 'committed' in o, round(dt, 2))
