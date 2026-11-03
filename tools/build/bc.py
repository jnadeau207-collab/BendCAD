#!/usr/bin/env python3
import os, socket, subprocess, sys, time
BIN = os.environ.get('BENDCAD_BIN', os.path.expanduser('~/bc/bendcad'))
PORT = int(os.environ.get('BENDCAD_PORT', '7790'))
REQ = '/tmp/bc-req'
args = sys.argv[1:]
if len(args) < 2 or args[1] in ('new',) or any('\n' in a for a in args):
    os.execv(BIN, [BIN] + args)
os.makedirs(REQ, exist_ok=True)
fn = os.path.join(REQ, '%d-%d.req' % (os.getpid(), time.time_ns()))
open(fn, 'w').write('\n'.join([os.path.abspath(args[0])] + args[1:] + ['<<end>>']) + '\n')
def ask():
    s = socket.create_connection(('127.0.0.1', PORT), timeout=86400)
    s.sendall((fn + '\n').encode())
    out = b''
    while True:
        d = s.recv(65536)
        if not d:
            break
        out += d
    return out.decode()
try:
    out = ask()
except OSError:
    subprocess.Popen(['setsid', BIN, 'serve', str(PORT)], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    for _ in range(300):
        time.sleep(0.1)
        try:
            out = ask()
            break
        except OSError:
            pass
os.remove(fn)
sys.stdout.write(out)
