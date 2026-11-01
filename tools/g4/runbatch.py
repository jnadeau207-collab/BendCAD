import json
import os
import pty
import subprocess
import sys

args = json.load(open(sys.argv[1]))
m, s = pty.openpty()
p = subprocess.Popen(args, stdout=s, stderr=s, stdin=subprocess.DEVNULL, close_fds=True)
os.close(s)
with open(sys.argv[2], 'wb') as out:
    while True:
        try:
            b = os.read(m, 65536)
        except OSError:
            break
        if not b:
            break
        out.write(b.replace(b'\r\n', b'\n'))
        out.flush()
p.wait()
