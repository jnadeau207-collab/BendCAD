import bc, sys, threading
f = sys.argv[1]
items = [a.split(':') for a in sys.argv[2:]]
D = '/home/jesse/g2/parts/%s.bcd' % f
out = {}
def one(node, name):
    n = int(node)
    r1 = bc.call('step_export', design=D, node=n, out='/home/jesse/g2/export/%s.stp' % name)
    r2 = bc.call('stl_export', design=D, node=n, out='/home/jesse/g2/export/%s.stl' % name, preset=3, maxTris=4000000)
    r3 = bc.call('mass', design=D, node=n)
    open('../q/exp_%s.txt' % name, 'w', encoding='utf-8').write('STEP\n%s\nSTL\n%s\nMASS\n%s\n' % (r1, r2, r3))
    print(name, r1.strip()[:120], '|', r2.strip()[:160], '|', r3.strip()[:300], flush=True)
ts = [threading.Thread(target=one, args=it) for it in items]
[t.start() for t in ts]; [t.join() for t in ts]
