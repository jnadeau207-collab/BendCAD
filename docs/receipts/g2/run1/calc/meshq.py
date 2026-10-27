import bc, threading
D = '/home/jesse/g2/parts/p_mesh.bcd'
ASM = '(assembly (inst body 11 0 0 0 0) (inst drive_gear 45 0 0 0 0) (inst idler_gear 50 22.05 0 0 0) (fix 1 body) (coinc 2 drive_gear 0 0 0.025 body 0 0 0.025) (coinc 3 idler_gear 0 0 0.025 body 22.05 0 0.025))'
jobs = {'mesh': dict(action='mesh', inst='drive_gear', teeth=12, inst2='idler_gear', teeth2=12),
        'gap_drive': dict(action='gap', inst='drive_gear', inst2='body', faces=['n1.c1.wall.0.0', 'n1.c1.wall.1.0']),
        'gap_idler': dict(action='gap', inst='idler_gear', inst2='body', faces=['n1.c1.wall.0.0', 'n1.c1.wall.1.0']),
        'gap_gears': dict(action='gap', inst='drive_gear', inst2='idler_gear'),
        'solve': dict(action='solve')}
def run(k, a):
    r = bc.call('assembly', design=D, assembly=ASM, **a)
    open('../q/mesh_%s.txt' % k, 'w', encoding='utf-8').write(ASM + '\n\n' + r)
    print('==', k, r[:1500], flush=True)
ts = [threading.Thread(target=run, args=kv) for kv in jobs.items()]
[t.start() for t in ts]; [t.join() for t in ts]
