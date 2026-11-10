import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import threads as T

IC, IA, IR, IS = ('(intent %s any any any any)' % k for k in ('create', 'add', 'remove', 'same'))
rc = T.ext_tooth(3.0, 0.5, T.ES_6G[3.0])[0]
rb = T.d1(3.0, 0.5) / 2
CASES = {
    'h1': [T.ext_helix(1, 3.0, 0.0, 0.5, IC)],
    'h5': [T.ext_helix(1, 3.0, 0.0, 2.5, IC)],
    'u5': [T.ext_helix(1, 3.0, 0.5, 2.5, IC), f'(node 2 (cylinder {rc!r} 3.5) {IC})', f'(node 3 (union 2 1) {IA})'],
    't5': [f'(node 1 (box 8.0 8.0 4.0) {IC})', f'(node 2 (move 1 -4.0 -4.0 0.0 0) {IS})',
           f'(node 3 (cylinder {rb!r} 5.0) {IC})', f'(node 4 (move 3 0.0 0.0 -0.5 0) {IS})',
           f'(node 5 (difference 2 4) {IR})', T.int_helix(6, 3.0, -0.3, 3.0, IC), f'(node 7 (difference 5 6) {IR})'],
}
out = sys.argv[1]
for k, v in CASES.items():
    open(os.path.join(out, f'thr_{k}.txt'), 'w', newline='\n').write('\n'.join(v) + '\n')
print('ok', rc, rb)
