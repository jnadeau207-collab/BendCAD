MAT = {
    11: ('6082-T6', 2700, 23.4e-6), 38: ('6082-T6', 2700, 23.4e-6), 44: ('6082-T6', 2700, 23.4e-6),
    12: ('C45', 7850, 11.5e-6), 13: ('DU-PTFE/bronze/steel', 7600, 11e-6), 14: ('DU-PTFE/bronze/steel', 7600, 11e-6),
    15: ('NBR70+DC04-insert', 2830, 1.0e-4), 18: ('C75S', 7850, 11.5e-6), 21: ('ISO898-1-12.9', 7850, 11.5e-6),
    23: ('100Cr6', 7810, 11.5e-6),
}
GEARMAT = ('16MnCr5', 7850, 11.5e-6)
THR = {
    38: ['(thread 38 tap%d n36.c%d.wall.0.0 M8 6H -24 0)' % (k, k) for k in range(4)],
    11: ['(thread 11 suction n4.c0.wall.0.0 M22x1.5 6H 19 32.1)', '(thread 11 pressure n8.c0.wall.0.0 M18x1.5 6H -32.1 -20)'],
    21: ['(thread 21 ext n20.c0.wall.0.0 M8 6g -80 -52)'],
}
def edits(nodes):
    e = ['(material %d %s %r %r)' % (n, *MAT[n]) for n in nodes if n in MAT]
    for n in nodes:
        e += THR.get(n, [])
    return e
