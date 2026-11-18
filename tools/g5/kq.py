import os
import socket
import subprocess
import time

DESIGN = os.environ.get('G5_DESIGN', '/home/jesse/g5/g5p.bcd')
PORT = int(os.environ.get('G5_PORT', '0'))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad-r1c')


def kq(*args, timeout=14400):
    if not PORT:
        p = subprocess.run([BIN, DESIGN, *args], capture_output=True, text=True, timeout=timeout)
        return p.stdout + p.stderr
    fn = '/var/tmp/g5q-%d-%d.req' % (os.getpid(), int(time.time() * 1e6))
    open(fn, 'w').write('\n'.join([DESIGN] + list(args) + ['<<end>>']) + '\n')
    s = socket.create_connection(('127.0.0.1', PORT), timeout=timeout)
    s.sendall((fn + '\n').encode())
    out = b''
    while True:
        d = s.recv(65536)
        if not d:
            break
        out += d
    s.close()
    os.remove(fn)
    return out.decode()
