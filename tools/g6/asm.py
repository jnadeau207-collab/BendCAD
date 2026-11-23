import json
import os
import re
import socket
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
import humphrey as H

REC = os.path.join(H.ROOT, 'docs', 'receipts', 'g6')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
DESIGN = os.environ.get('G6_DESIGN', '/home/jesse/g6/g6.bcd')
ZBF, ZBR = H.Z_BRG_F + H.B_W / 2, H.Z_BRG_R + H.B_W / 2
MATES = [
    ('casing', 20, None, None, 'fixed: the engine datum'),
    ('shroud', 23, 'casing', H.Z_EXIT - H.B2 - 4.0, 'shroud flange seats on the casing bore'),
    ('diffuser', 24, 'shroud', H.Z_EXIT, 'diffuser plate against the shroud exit face'),
    ('rdc', 40, 'casing', H.Z_INJ - 5.0, 'injector ring on the casing'),
    ('stator', 42, 'rdc', H.Z_RDC1, 'CMC detonation stator monolith continues the RDC bodies'),
    ('nozzle', 28, 'stator', H.Z_TUR + H.B_TUR + 2.0, 'nozzle shell on the stator shroud end'),
    ('tunnel', 44, 'diffuser', H.Z_FLANGE, 'bearing tunnel flange on the diffuser back face'),
    ('bearing_front_outer', 52, 'tunnel', ZBF, 'front outer ring in the tunnel bore'),
    ('bearing_rear_outer', 62, 'tunnel', ZBR, 'rear outer ring in the tunnel bore'),
    ('bearing_front_balls', 53, 'bearing_front_outer', ZBF, 'balls on the outer raceway'),
    ('bearing_rear_balls', 63, 'bearing_rear_outer', ZBR, 'balls on the outer raceway'),
    ('bearing_front_inner', 51, 'bearing_front_balls', ZBF, 'inner ring on the balls'),
    ('bearing_rear_inner', 61, 'bearing_rear_balls', ZBR, 'inner ring on the balls'),
    ('bearing_front_cage', 54, 'bearing_front_balls', ZBF, 'cage on the balls'),
    ('bearing_rear_cage', 64, 'bearing_rear_balls', ZBR, 'cage on the balls'),
    ('shaft', 10, 'bearing_front_inner', ZBF, 'shaft journal in the front inner ring'),
    ('impeller', 19, 'shaft', H.Z_IMP0, 'impeller hub on the shaft'),
    ('turbine', 27, 'shaft', H.Z_TUR, 'turbine disc on the shaft'),
    ('reservoir', 43, 'shroud', -66.0, 'pilot tank on the intake'),
] + [(f'vaporiser_{k + 1}', 461 + k, 'nozzle', z, 'vaporiser coil on the nozzle shell') for k, z in enumerate(H.VAP_Z)]


def form(names=None):
    keep = [m for m in MATES if names is None or m[0] in names]
    ins = ' '.join(f'(inst {m[0]} {m[1]} 0 0 0 0)' for m in keep)
    cons = []
    for i, (name, node, to, z, why) in enumerate(keep):
        if to is None:
            cons.append(f'(fix {i + 1} {name})')
        else:
            cons.append(f'(coinc {i + 1} {name} 0 0 {z!r} {to} 0 0 {z!r})')
    return f'(assembly {ins} {" ".join(cons)})'


PORT = int(os.environ.get('G6_PORT', '0'))


def served(args, timeout):
    fn = '/var/tmp/g6q-%d-%d.req' % (os.getpid(), int(time.time() * 1e6))
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


def kernel(*a, timeout=86400):
    t = time.time()
    if PORT:
        return served(a, timeout), round(time.time() - t, 1)
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    p = subprocess.run([*pre, BIN, DESIGN, *a], capture_output=True, text=True, timeout=timeout, env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return p.stdout + p.stderr, round(time.time() - t, 1)


def main(what):
    f = os.path.join(REC, 'asm.json')
    rep = json.load(open(f, encoding='utf-8')) if os.path.exists(f) else dict(source='bendcad asm solve / asm interf on tools/g6/asm.py MATES', binary=BIN, design=DESIGN)
    rep['mates'] = [dict(part=m[0], node=m[1], to=m[2], z=m[3], why=m[4]) for m in MATES]
    if 'solve' in what:
        out, s = kernel('asm', 'solve', form())
        m = re.search(r'dof[ =](\d+)', out)
        rep.update(dof=int(m.group(1)) if m else None, solve_seconds=s, solve_raw=out.strip()[-1500:])
        print('solve', s, 's dof', rep['dof'])
    if 'interf' in what:
        out, s = kernel('asm', 'interf', form())
        rel = re.findall(r'^pair (\S+) (\S+)\s*\n\s*relation (\S+)', out, re.M)
        bad = [f'{x} {y} {r}' for x, y, r in rel if r not in ('disjoint',)]
        rep.update(interf_seconds=s, interf_raw=out.strip()[-4000:], pairs=len(rel),
                   relations={r: sum(1 for *_, q in rel if q == r) for r in sorted({q for *_, q in rel})},
                   interference='none' if rel and not bad else (bad or out.strip()[-600:]))
        print('interf', s, 's', rep['interference'][:300])
    json.dump(rep, open(f, 'w', encoding='utf-8'), indent=1)


if __name__ == '__main__':
    main(sys.argv[1:])
