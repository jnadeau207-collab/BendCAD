import bc, sys
D = '/home/jesse/g2/parts/p_static.bcd'
P = ('(pmi (node 38) (temp cold 20) (temp hot 80) '
     '(fit bush_front_drive 38 n26.c0.wall.0.0 13 n13.c0.wall.0.0 JS6/r9 press) '
     '(fit bush_front_idler 38 n27.c0.wall.0.0 14 n14.c0.wall.0.0 JS6/r9 press) '
     '(fit bush_rear_drive 44 n40.c0.wall.0.0 14 n14.c0.wall.0.0 JS6/r9 press) '
     '(fit bush_rear_idler 44 n40.c1.wall.0.0 14 n14.c0.wall.0.0 JS6/r9 press) '
     '(fit dowel_body_a 11 n11.c0.wall.0.0 23 n23.c0.wall.2.0 H7/m6 transition) '
     '(fit dowel_body_b 11 n11.c1.wall.0.0 23 n23.c0.wall.2.0 H7/m6 transition) '
     '(fit dowel_front_a 38 n37.c0.wall.0.0 23 n23.c0.wall.2.0 E8/m6 clearance) '
     '(fit dowel_front_b 38 n37.c1.wall.0.0 23 n23.c0.wall.2.0 E8/m6 clearance) '
     '(fit dowel_rear_a 44 n43.c0.wall.0.0 23 n23.c0.wall.2.0 E8/m6 clearance) '
     '(fit dowel_rear_b 44 n43.c1.wall.0.0 23 n23.c0.wall.2.0 E8/m6 clearance))')
r = bc.call('pmi', design=D, action='fits', pmi=P)
open('../q/fits.txt', 'w', encoding='utf-8').write(P + '\n\n' + r)
print(r)
