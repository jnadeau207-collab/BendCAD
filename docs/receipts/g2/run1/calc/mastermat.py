import bc, mt, time
D = '/home/jesse/g2/parts/gearpump.bcd'
e = mt.edits([11, 12, 13, 14, 15, 18, 21, 23, 38, 44]) + ['(material 49 16MnCr5 7850 1.15e-05)', '(material 52 16MnCr5 7850 1.15e-05)']
t = time.time()
r = bc.call('apply', design=D, edits=e)
print(round(time.time() - t), r.rstrip()[-30:])
