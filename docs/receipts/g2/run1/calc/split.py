import bc, pump, sys, time
d = pump.Design(); pump.build(d)
name = sys.argv[1]; groups = sys.argv[2:]
D = '/home/jesse/g2/parts/%s.bcd' % name
print(bc.call('new_design', design=D).strip())
t = time.time()
r = bc.call('apply', design=D, edits=sum((d.groups[g] for g in groups), []))
print(name, round(time.time() - t), 'committed' if r.rstrip().endswith('committed') else r[-2000:])
