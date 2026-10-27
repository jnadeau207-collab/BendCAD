import math, subprocess, sys
import bc
from geo import *

import os
DES = os.environ.get('DES', '/home/jesse/g2/parts/gearpump.bcd')
ZP = LB / 2

class Design:
    def __init__(self):
        self.ids = {}
        self.n = 0
        self.groups = {}
    def node(self, name, op, intent, grp):
        self.n += 1
        self.ids[name] = self.n
        self.groups.setdefault(grp, []).append('(node %d %s (intent %s))' % (self.n, op, intent))
        return self.n
    def i(self, name):
        return self.ids[name]

def body(d):
    g = 'body'
    d.node('b_blank', '(prism 0 %s (region %s %s))' % (f(LB), rrect(BX0, -BY, BX1, BY, 4), fig8()), 'create any 0 1 1', g)
    s = d.node('b_s_spot', '(pocket %d (face %d n%d.c0.wall.4.0) 0.5 (region %s))' % (d.i('b_blank'), d.i('b_blank'), d.i('b_blank'), circle(XM, -ZP, 14.5)), 'remove any any 1 1', g)
    s = d.node('b_s_cb', '(holes %d (face %d n%d.c0.bottom) 2.4 (hole %s %s 11.9))' % (s, s, s, f(XM), f(-ZP)), 'remove any any 1 1', g)
    s = d.node('b_s_tap', '(holes %d (face %d n%d.c0.bottom) 15.6 (hole %s %s 10.25))' % (s, s, s, f(XM), f(-ZP)), 'remove any any 1 1', g)
    s = d.node('b_s_pass', '(holes %d (face %d n%d.c0.bottom) 11.5 (hole %s %s 9.45))' % (s, s, s, f(XM), f(-ZP)), 'remove any any 1 any', g)
    p = d.node('b_p_spot', '(pocket %d (face %d n%d.c0.wall.0.0) 0.5 (region %s))' % (s, d.i('b_blank'), d.i('b_blank'), circle(XM, ZP, 13)), 'remove any any 1 any', g)
    p = d.node('b_p_cb', '(holes %d (face %d n%d.c0.bottom) 2.4 (hole %s %s 9.9))' % (p, p, p, f(XM), f(ZP)), 'remove any any 1 any', g)
    p = d.node('b_p_tap', '(holes %d (face %d n%d.c0.bottom) 14.6 (hole %s %s 8.25))' % (p, p, p, f(XM), f(ZP)), 'remove any any 1 any', g)
    p = d.node('b_p_pass', '(holes %d (face %d n%d.c0.bottom) 12.5 (hole %s %s 5.5))' % (p, p, p, f(XM), f(ZP)), 'remove any any 1 any', g)
    p = d.node('b_screws', '(holes %d (face %d 0 top) through %s)' % (p, d.i('b_blank'), ' '.join('(hole %s %s 4.5)' % (f(x), f(y)) for x, y in SCREWS)), 'remove any any 1 any', g)
    p = d.node('body', '(holes %d (face %d 0 top) through %s)' % (p, d.i('b_blank'), ' '.join('(hole %s %s 3)' % (f(x), f(y)) for x, y in DOWELS)), 'remove any any 1 any', g)

def apply(d, grp):
    import time
    t = time.time()
    ed = sum((d.groups[g] for g in grp.split('+')), [])
    r = bc.call('apply', design=DES, edits=ed)
    print(grp, 'seconds', round(time.time() - t))
    print(grp, 'COMMITTED' if '\ncommitted' in r or r.strip().endswith('committed') else 'REJECTED')
    if 'committed' not in r.split('\n')[-3:] and 'committed' not in r[-40:]:
        print(r[-6000:])
    return r

def build(d):
    import parts2
    body(d)
    for fn in (parts2.small, parts2.front, parts2.rear, parts2.drive, parts2.idler):
        fn(d)

if __name__ == '__main__':
    d = Design()
    build(d)
    if sys.argv[1:] and sys.argv[1] == 'new':
        print(bc.call('new_design', design=DES))
    for grp in sys.argv[2:]:
        if grp.startswith('only:'):
            g = grp[5:]
            r = bc.call('apply', design=DES, edits=d.groups[g])
            print(g, r[-3000:])
        else:
            apply(d, grp)
    print(d.ids)
