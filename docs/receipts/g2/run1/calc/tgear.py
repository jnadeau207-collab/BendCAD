import bc, time, parts2, pump, sys
d=pump.Design(); pump.build(d)
D='/home/jesse/g2/parts/t13.bcd'
bc.call('new_design', design=D)
for grp in sys.argv[1:]:
    t=time.time(); r=bc.call('apply', design=D, edits=d.groups[grp]); print(grp, round(time.time()-t), '\n'.join(l[:300] for l in r.split('\n') if 'error' in l or 'commit' in l or 'reject' in l), flush=True)
