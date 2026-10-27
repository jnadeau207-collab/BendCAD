from geo import *
def F(v):
    return f(v)
def assembly(gears=True, press=False):
    I, M = [], []
    def inst(n, node, t):
        I.append('(inst %s %d %s %s %s 0)' % (n, node, F(t[0]), F(t[1]), F(t[2])))
    def co(a, pa, b, pb):
        M.append('(coinc %d %s %s %s %s %s %s %s %s)' % (len(M) + 1, a, F(pa[0]), F(pa[1]), F(pa[2]), b, F(pb[0]), F(pb[1]), F(pb[2])))
    inst('body', 11, (0, 0, 0)); M.append('(fix 1 body)')
    dx, dy = DOWELS[0]
    inst('front_cover', 38, (0, 0, 0)); co('front_cover', (dx, dy, 0), 'body', (dx, dy, 0))
    inst('rear_cover', 44, (0, 0, 0)); co('rear_cover', (dx, dy, LB), 'body', (dx, dy, LB))
    for k, (x, y) in enumerate(DOWELS):
        inst('dowel%d' % k, 23, (x, y, LB / 2 - 25)); co('dowel%d' % k, (0, 0, 25), 'body', (x, y, LB / 2))
    inst('bush_front_drive', 13, (0, 0, -15)); co('bush_front_drive', (0, 0, 15), 'front_cover', (0, 0, 0))
    inst('bush_front_idler', 14, (A, 0, -15)); co('bush_front_idler', (0, 0, 15), 'front_cover', (A, 0, 0))
    inst('bush_rear_drive', 14, (0, 0, LB)); co('bush_rear_drive', (0, 0, 0), 'rear_cover', (0, 0, LB))
    inst('bush_rear_idler', 14, (A, 0, LB)); co('bush_rear_idler', (0, 0, 0), 'rear_cover', (A, 0, LB))
    if gears:
        inst('drive_shaft', 49, (0, 0, 0)); co('drive_shaft', (0, 0, ZG), 'body', (0, 0, ZG))
        inst('idler_shaft', 52, (A, 0, 0)); co('idler_shaft', (0, 0, ZG), 'body', (A, 0, ZG))
        inst('key', 12, (-1.985, 5.705, -63.1)); co('key', (0, 0, 0), 'drive_shaft', (-1.985, 5.705, -63.1))
    inst('oring_front', 53, (0, 0, 0)); co('oring_front', (0, 0, 0), 'front_cover', (0, 0, 0))
    inst('oring_rear', 53, (0, 0, LB + GD)); co('oring_rear', (0, 0, 0), 'rear_cover', (0, 0, LB + GD))
    inst('lip_seal', 15, (0, 0, -31.05)); co('lip_seal', (0, 0, 0), 'front_cover', (0, 0, -31.05))
    inst('circlip', 18, (0, 0, -32.25)); co('circlip', (0, 0, 0), 'front_cover', (0, 0, -32.25))
    for k, (x, y) in enumerate(SCREWS):
        inst('screw%d' % k, 21, (x, y, LB + TR)); co('screw%d' % k, (0, 0, 0), 'rear_cover', (x, y, LB + TR))
    P = []
    if press:
        P = ['(press pf_front_drive front_cover n26.c0.wall.0.0 bush_front_drive n13.c0.wall.0.0)',
             '(press pf_front_idler front_cover n27.c0.wall.0.0 bush_front_idler n14.c0.wall.0.0)',
             '(press pf_rear_drive rear_cover n40.c0.wall.0.0 bush_rear_drive n14.c0.wall.0.0)',
             '(press pf_rear_idler rear_cover n40.c1.wall.0.0 bush_rear_idler n14.c0.wall.0.0)']
    return '(assembly %s %s %s)' % (' '.join(I), ' '.join(M), ' '.join(P))
if __name__ == '__main__':
    print(assembly())
