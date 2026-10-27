import bc, time, subprocess, sys
D='/home/jesse/g2/parts/t9.bcd'
nf=sys.argv[1]
g=subprocess.run([sys.executable,'../../gear.py','12','1.75','0.35','0','0.05','0.88',nf],capture_output=True,text=True).stdout.strip()
E=['(node 1 (prism 0.025 35.025 (region %s)) (intent create any 0 1 0))'%g]+sys.argv[3:]
bc.call('new_design', design=D)
k=int(sys.argv[2])
t=time.time(); r=bc.call('apply', design=D, edits=E[:k]); print(k, round(time.time()-t,1), r[-300:].replace('\n',' '), flush=True)
