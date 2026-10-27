import json,sys
lines=open('C:/dev/BendCAD-k2/docs/receipts/g2/run1/calls.jsonl',encoding='utf-8').read().strip().split('\n')
k=int(sys.argv[1]) if len(sys.argv)>1 else 1
pat=sys.argv[2] if len(sys.argv)>2 else ''
r=json.loads(lines[-k])
print(' '.join(a[:120] for a in r['args'][:6]))
for l in r['out'].split('\n'):
    if pat in l: print(l[:400])
