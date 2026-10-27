import bc, asm, threading, sys
D = '/home/jesse/g2/parts/gearpump.bcd'
A0 = asm.assembly()
AP = asm.assembly(press=True)
open('../q/assembly.txt', 'w').write(A0 + '\n\nwith press declarations:\n' + AP + '\n')
jobs = {'solve': dict(action='solve', assembly=A0), 'mass': dict(action='mass', assembly=A0),
        'step': dict(action='step', assembly=A0, out='/home/jesse/g2/export/gear_pump_assembly.stp'),
        'engage': dict(action='engage', assembly=A0, inst='screw0', thread='ext', inst2='front_cover', thread2='tap0'),
        'interf_press': dict(action='interf', assembly=AP), 'interf': dict(action='interf', assembly=A0),
        'explode': dict(action='explode', assembly=A0, dx=0, dy=0, dz=1, gap=20)}
sel = sys.argv[1:] or list(jobs)
def run(k):
    r = bc.call('assembly', design=D, **jobs[k])
    open('../q/master_%s.txt' % k, 'w', encoding='utf-8').write(r)
    print('==', k, r[:600], flush=True)
ts = [threading.Thread(target=run, args=(k,)) for k in sel]
[t.start() for t in ts]; [t.join() for t in ts]
