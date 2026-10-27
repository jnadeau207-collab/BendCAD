import bc,time,math,sys
D='/home/jesse/g2/parts/t10.bcd'
for n in [int(a) for a in sys.argv[1:]]:
    pts=[(12*math.cos(2*math.pi*k/n),12*math.sin(2*math.pi*k/n)) for k in range(n)]
    poly='(path %r %r %s)'%(pts[0][0],pts[0][1],' '.join('(line %r %r)'%p for p in pts[1:]))
    bc.call('new_design', design=D)
    t=time.time()
    r=bc.call('apply', design=D, edits=['(node 1 (prism 0.025 35.025 (region %s)) (intent create any 0 1 0))'%poly,'(node 2 (pad 1 (face 1 0 top) 14.5 (region (circle 0 0 8))) (intent add any any 1 0))','(node 3 (pad 2 (face 1 0 bottom) 14.5 (region (circle 0 0 8))) (intent add any any 1 0))'])
    print(n, round(time.time()-t,1), r[-60:].replace('\n',' '), flush=True)
