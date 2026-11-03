import json
import os
import re
import subprocess
import sys
import time

BIN = os.environ.get('K4_BIN', '/home/jesse/bc/bendcad-k4a')
WORK = '/home/jesse/k4'
IC = '(intent create any any any any)'
IS = '(intent same any any any any)'
IA = '(intent add any any any any)'
IR = '(intent remove any any any any)'
HERE = os.path.dirname(os.path.abspath(__file__))


def wsl(*args, timeout=900):
    t0 = time.time()
    p = subprocess.run(['wsl.exe', '-e'] + list(args), capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'), stdin=subprocess.DEVNULL)
    return p.stdout + p.stderr, time.time() - t0


def fresh(name, *edits):
    wsl('mkdir', '-p', WORK)
    wsl('rm', '-f', f'{WORK}/{name}')
    wsl(BIN, f'{WORK}/{name}', 'new')
    return wsl(BIN, f'{WORK}/{name}', 'apply', *edits)


def node_line(out, n):
    m = re.search(rf'^node {n}: (.*)$', out, re.M)
    return m.group(1) if m else ''


def vol(line):
    m = re.search(r'volume=\[(\S+), (\S+)\]', line)
    return (float(m.group(1)), float(m.group(2))) if m else None


def blade(tw):
    return [f'(node 1 (naca4 4 4 12 40 17) {IC})', f'(node 2 (naca4 4 4 12 40 17) {IC})',
            f'(node 3 (blade 1 2 30 {tw} 100) {IC})']


def base(op, intent, x=-10.0, y=-30.0, z=-5.0, h=10.0):
    return [f'(node 4 (box 60 60 {h}) {IC})', f'(node 5 (move 4 {x} {y} {z} 0) {IS})',
            f'(node 6 ({op} 3 5) {intent})']


def case(name, tw, op, intent, **kw):
    out, dt = fresh(f'{name}.bcd', *blade(tw), *base(op, intent, **kw))
    return dict(name=name, op=op, twist=tw, seconds=round(dt, 2), committed='committed' in out,
                blade=node_line(out, 3), box=node_line(out, 5), result=node_line(out, 6))


def identity(u, i):
    a, b, vu, vi = vol(u['blade']), vol(u['box']), vol(u['result']), vol(i['result'])
    if not (a and b and vu and vi):
        return dict(ok=False, why='missing volume')
    lhs = (vu[0] + vi[0], vu[1] + vi[1])
    rhs = (a[0] + b[0], a[1] + b[1])
    return dict(ok=lhs[0] <= rhs[1] and rhs[0] <= lhs[1], lhs=lhs, rhs=rhs, gap=abs((lhs[0] + lhs[1]) - (rhs[0] + rhs[1])) / 2)


def main():
    rows = []
    for tw in [int(t) for t in (sys.argv[1:] or ['20'])]:
        u = case(f'u{tw}', tw, 'union', IA)
        i = case(f'i{tw}', tw, 'intersection', IS)
        d = case(f'd{tw}', tw, 'difference', IR)
        rows += [u, i, d]
        rows.append(dict(name=f'identity{tw}', **identity(u, i)))
    rep = dict(binary=BIN, rows=rows)
    path = os.path.join(HERE, 'e2e-report.json')
    json.dump(rep, open(path, 'w'), indent=1)
    for r in rows:
        print(json.dumps(r)[:600])


if __name__ == '__main__':
    main()
