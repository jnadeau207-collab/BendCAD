import json
import os
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
import jet

DST = os.environ.get('G5_DESIGN', '/home/jesse/g5/g5r.bcd')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad-r1c')
PARTS = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 22, 23, 24, 26, 27, 28, 29, 30, 32, 34]


def write():
    lines = ['(bendcad 1)']
    for tag, edits in jet.parts():
        lines += edits
    lines += jet.materials()
    if jet.PORTS_ON:
        lines += jet.shaft_threads() + jet.port_threads()
    open(DST, 'w', newline='\n').write('\n'.join(lines) + '\n')
    return len(lines)


def prove(jobs):
    out = '/var/tmp/g5r-prove'
    os.makedirs(out, exist_ok=True)
    cmd = ('one() { s=$(date +%s%N); timeout 7200 "$B" "$D" mass $1 > "$O/$1.out" 2>&1; rc=$?; e=$(date +%s%N); '
           'echo "$1 rc=$rc ms=$(( (e - s) / 1000000 ))" >> "$O/times.txt"; }; export -f one; '
           'printf "%s\\n" "$@" | xargs -P ' + str(jobs) + ' -I{} bash -c "one {}"')
    open(os.path.join(out, 'times.txt'), 'w').close()
    env = dict(os.environ, B=BIN, D=DST, O=out)
    subprocess.run(['bash', '-c', cmd, '_'] + [str(p) for p in sorted(PARTS, key=lambda n: n not in (19, 27, 22, 26))], env=env)
    rows = {}
    for ln in open(os.path.join(out, 'times.txt')):
        n, rc, ms = ln.split()
        txt = open(os.path.join(out, n + '.out')).read()
        rows[n] = dict(rc=int(rc.split('=')[1]), s=int(ms.split('=')[1]) / 1000.0,
                       mass=next((l for l in txt.splitlines() if l.startswith('mass ')), None),
                       material=next((l for l in txt.splitlines() if l.startswith('material ')), None),
                       moments=next((l[:200] for l in txt.splitlines() if l.startswith('moments ')), None),
                       error=None if 'mass ' in txt else txt.strip()[-400:])
    json.dump(dict(binary=BIN, design=DST, parts=rows), open(os.path.join(out, 'prove.json'), 'w'), indent=1)
    for n, r in sorted(rows.items(), key=lambda x: -x[1]['s']):
        print(n, r['rc'], r['s'], (r['mass'] or r['error'] or '')[:120])


if __name__ == '__main__':
    assert jet.JOINTS_MODE in ('0', 'ports'), 'run with G5_JOINTS=0 or ports'
    print('lines', write())
    if len(sys.argv) > 1:
        prove(int(sys.argv[1]))
