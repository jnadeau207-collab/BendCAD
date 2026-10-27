import bc, sys
from geo import *
import pump
D='/home/jesse/g2/parts/t3.bcd'
d=pump.Design(); pump.body(d)
base=d.groups['body'][:4]
var=sys.argv[1:]
print(bc.call('new_design', design=D))
print(bc.call('apply', design=D, edits=base)[-80:])
for v in var:
    dep,r,xo=v.split(',')
    out=bc.call('apply', design=D, edits=['(node 5 (holes 4 (face 4 n4.c0.bottom) %s (hole %s %s %s)) (intent remove any any 1 any))'%(dep,f(XM+float(xo)),f(-LB/2),r)])
    print(v, out[-400:])
