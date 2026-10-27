import bc, sys, threading
D = '/home/jesse/g2/parts/p_static.bcd'
BODY = ('(pmi (node 11) (datum A n1.c0.bottom) (datum B n1.c1.wall.0.0) '
        '(dim hLB 17.525 17.524 17.527) (dim hB -17.5 -17.5 -17.498) (dim flat -0.002 -0.002 0) (dim dTside 0.0125 0.0125 0.0125) '
        '(dim Rc 12.6825 12.6825 12.6865) (dim ra -12.6525 -12.6525 -12.6485) (dim ecc -0.005 -0.005 0) (dim dTtip 0.00905 0.00905 0.00905) '
        '(tol tFlatTop flatness 0.002 n1.c0.top rfs) (tol tFlatBot flatness 0.002 n1.c0.bottom rfs) (tol tPar parallelism 0.004 n1.c0.top rfs A) '
        '(state cold20 1) '
        '(stack side_20C hLB hB flat) (stack side_80C hLB hB flat dTside) (stack tip_20C Rc ra ecc) (stack tip_80C Rc ra ecc dTtip))')
BUSH = ('(pmi (node 13) (datum A n13.c0.wall.0.0) '
        '(dim hous16 18 17.9945 18.0055) (dim wall16 -2 -2 -1.96) (dim jour16 -15.968 -15.968 -15.95) '
        '(dim hous12 14 13.9945 14.0055) (dim wall12 -2 -2 -1.96) (dim jour12 -11.968 -11.968 -11.95) '
        '(state cold20 1) (stack run_DU1615 hous16 wall16 jour16) (stack run_DU1215 hous12 wall12 jour12))')
FRONT = ('(pmi (node 38) (datum A n24.c0.top) (datum P n29.c0.wall.0.0) (dim pilot 82.55 82.496 82.55) '
         '(tol tParPilotFace parallelism 0.03 n29.c0.bottom rfs A) (tol tFlatInner flatness 0.002 n24.c0.top rfs) (state cold20 1) (stack pilot_dia pilot))')
REAR = '(pmi (node 44) (datum A n39.c0.bottom.p0) (tol tFlatInner flatness 0.002 n39.c0.bottom.p0 rfs) (tol tFlatIsland flatness 0.002 n39.c0.bottom.p1 rfs) (tol tParIsland parallelism 0.004 n39.c0.bottom.p1 rfs A) (state cold20 1))'
jobs = []
for nm, p in (('body', BODY), ('bush', BUSH), ('front', FRONT), ('rear', REAR)):
    for act in ('check', 'stack'):
        jobs.append((nm, act, p))
    jobs.append((nm, 'step42', p))
def run(nm, act, p):
    kw = dict(design=D, action=act, pmi=p)
    if act == 'step42':
        kw['out'] = '/home/jesse/g2/export/%s_pmi_ap242.stp' % {'body': 'body', 'bush': 'bushing_DU1615', 'front': 'front_cover', 'rear': 'rear_cover'}[nm]
    r = bc.call('pmi', **kw)
    open('../q/pmi_%s_%s.txt' % (nm, act), 'w', encoding='utf-8').write(p + '\n\n' + r)
    print('==', nm, act, '\n', r[:3000], flush=True)
ts = [threading.Thread(target=run, args=j) for j in jobs if (len(sys.argv) < 2 or j[0] in sys.argv[1:])]
[t.start() for t in ts]; [t.join() for t in ts]
