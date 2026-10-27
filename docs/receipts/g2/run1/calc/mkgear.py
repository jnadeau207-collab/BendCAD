import bc, pump, sys, time
d = pump.Design(); pump.build(d)
which = sys.argv[1]
D = '/home/jesse/g2/parts/%s.bcd' % which
bc.call('new_design', design=D)
if which == 'p_mesh':
    ed = d.groups['body'] + [e for e in d.groups['drive'] + d.groups['idler'] if ('(node %d ' % d.ids['gd_body']) in e or ('(node %d ' % d.ids['gi_body']) in e]
    ed += ['(material 11 6082-T6 2700 2.34e-05)', '(material %d 16MnCr5 7850 1.15e-05)' % d.ids['gd_body'], '(material %d 16MnCr5 7850 1.15e-05)' % d.ids['gi_body']]
else:
    g = 'drive' if which == 'p_drive' else 'idler'
    ed = d.groups[g] + ['(material %d 16MnCr5 7850 1.15e-05)' % d.ids[g + '_shaft']]
t = time.time()
r = bc.call('apply', design=D, edits=ed)
print(which, round(time.time() - t), r.rstrip()[-20:])
