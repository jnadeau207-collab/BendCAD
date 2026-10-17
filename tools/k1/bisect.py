import re
import subprocess
import sys

src = sys.argv[1]
tmp = src.replace('.bend', '_zb.bend')
text = open(src, encoding='utf-8').read()
parts = re.split(r'(?m)^(?=(?:def|type) )', text)
head, blocks = parts[0], parts[1:]


def ok(n):
    open(tmp, 'w', encoding='utf-8', newline='\n').write(head + ''.join(blocks[:n]))
    w = tmp.replace('/mnt/c/', '').replace('C:/dev/BendCAD/', '')
    r = subprocess.run(['wsl', '-e', 'bash', '-lc',
                        'cd /mnt/c/dev/BendCAD; BEND_NO_TELEMETRY=1 timeout 20 ~/bin/bendcap ' + w + ' --check-only'],
                       capture_output=True, text=True)
    return r.returncode != 124


lo, hi = 0, len(blocks)
while hi - lo > 1:
    mid = (lo + hi) // 2
    if ok(mid):
        lo = mid
    else:
        hi = mid
    print(lo, hi, flush=True)
print('first slow block:', blocks[hi - 1].split('\n')[0])
import os
os.remove(tmp)
