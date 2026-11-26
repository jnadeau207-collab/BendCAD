import json
import math
import os
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'tools', 'g4'))
from blower import snap

BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad-r39')
OUT = os.environ.get('WREATH_OUT', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out'))

N = 8
RO = 178.0
RI = 138.0
T = 8.0
GAP = 0.1
C = 0.15
NECK = 5.0
MOUTH = 8.0
DEPTH = 10.0
HOLE_R = 2.5
BED = 180.0


def rot(p, a):
    ca, sa = math.cos(a), math.sin(a)
    return (p[0] * ca - p[1] * sa, p[0] * sa + p[1] * ca)


def offset_line(p, q, d):
    dx, dy = q[0] - p[0], q[1] - p[1]
    L = math.hypot(dx, dy)
    nx, ny = dy / L * d, -dx / L * d
    return (p[0] + nx, p[1] + ny), (q[0] + nx, q[1] + ny)


def at_y(p, q, y):
    s = (y - p[1]) / (q[1] - p[1])
    return (p[0] + s * (q[0] - p[0]), y)


def f(v):
    return repr(float(v))


def design():
    rm = 0.5 * (RO + RI)
    a = 2 * math.pi / N
    l0, l1 = (rm - NECK, 0.0), (rm - MOUTH, DEPTH)
    r0, r1 = (rm + NECK, 0.0), (rm + MOUTH, DEPTH)
    lo = offset_line(l0, l1, -C)
    ro = offset_line(r1, r0, -C)
    sl0, sl1 = at_y(*lo, GAP), at_y(*lo, DEPTH + C)
    sr0, sr1 = at_y(*ro, GAP), at_y(*ro, DEPTH + C)
    xi0 = snap((math.sqrt(RI * RI - GAP * GAP), GAP), [((0.0, 0.0), RI)])
    xo0 = snap((math.sqrt(RO * RO - GAP * GAP), GAP), [((0.0, 0.0), RO)])
    o45 = snap(rot((RO, 0.0), a), [((0.0, 0.0), RO)])
    i45 = snap(rot((RI, 0.0), a), [((0.0, 0.0), RI)])
    tail = [rot(p, a) for p in (r0, r1, l1, l0)]
    pts = [sl0, sl1, sr1, sr0, xo0]
    segs = ' '.join('(line %s %s)' % (f(x), f(y)) for x, y in pts)
    segs += ' (arc 0.0 0.0 %s %s %s ccw)' % (f(RO), f(o45[0]), f(o45[1]))
    segs += ' ' + ' '.join('(line %s %s)' % (f(x), f(y)) for x, y in tail + [i45])
    segs += ' (arc 0.0 0.0 %s %s %s cw)' % (f(RI), f(xi0[0]), f(xi0[1]))
    region = '(region (path %s %s %s))' % (f(xi0[0]), f(xi0[1]), segs)
    holes = ' '.join('(hole %s %s %s)' % (f(rm * math.cos(t)), f(rm * math.sin(t)), f(HOLE_R))
                     for t in (a / 3, 2 * a / 3))
    lines = ['(bendcad 1)',
             '(node 1 (prism 0.0 %s %s) (intent create any any 1 0))' % (f(T), region),
             '(node 2 (holes 1 (face 1 0 top) through %s) (intent remove any any 1 2))' % holes,
             '(material 2 PLA 1240 68e-6 3500 0.36)',
             '(node 3 (rotate 2 z %s) (intent same any any 1 2))' % f(360.0 / N),
             '(node 4 (rotate 2 z %s) (intent same any any 1 2))' % f(-360.0 / N)]
    return '\n'.join(lines) + '\n'


def kern(dpath, *args, timeout=1800):
    t0 = time.time()
    p = subprocess.run([BIN, dpath] + [str(x) for x in args], capture_output=True, text=True, timeout=timeout)
    return dict(cmd=' '.join(str(x) for x in args), seconds=round(time.time() - t0, 2), out=(p.stdout + p.stderr).strip())


def stl_box(path):
    import struct
    with open(path, 'rb') as fh:
        data = fh.read()
    lo, hi = [math.inf] * 3, [-math.inf] * 3
    if data[:5] == b'solid':
        for m in re.finditer(rb'vertex\s+(\S+)\s+(\S+)\s+(\S+)', data):
            v = [float(x) for x in m.groups()]
            lo = [min(a, b) for a, b in zip(lo, v)]
            hi = [max(a, b) for a, b in zip(hi, v)]
    else:
        n = struct.unpack('<I', data[80:84])[0]
        for i in range(n):
            vs = struct.unpack('<12f', data[84 + 50 * i:84 + 50 * i + 48])[3:]
            for k in range(3):
                v = vs[3 * k:3 * k + 3]
                lo = [min(a, b) for a, b in zip(lo, v)]
                hi = [max(a, b) for a, b in zip(hi, v)]
    return lo, hi


def fits_bed(lo, hi):
    w, h, z = hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2]
    if z > BED:
        return False, None
    best = None
    for k in range(0, 1800):
        t = math.radians(k * 0.1)
        best_w = abs(w * math.cos(t)) + abs(h * math.sin(t))
        best_h = abs(w * math.sin(t)) + abs(h * math.cos(t))
        if best_w <= BED and best_h <= BED:
            best = k * 0.1
            break
    return best is not None, best


def main():
    os.makedirs(OUT, exist_ok=True)
    dpath = os.path.join(OUT, 'wreath.bcd')
    with open(dpath, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(design())
    rec = dict(bin=BIN, ring=dict(sections=N, outer_d=2 * RO, inner_d=2 * RI, thickness=T, joint='dovetail',
                                  clearance=C, end_gap=GAP, wire_hole_d=2 * HOLE_R), steps=[])
    stl = os.path.join(OUT, 'wreath_section.stl')
    mf = os.path.join(OUT, 'wreath_section.3mf')
    for args in (('eval',), ('check', 2), ('wall', 2), ('mass', 2, 0), ('make', 2, 'fdm'),
                 ('interf', 2, 3), ('clearance', 2, 3), ('interf', 2, 4), ('clearance', 2, 4), ('stl', 2, stl, 3), ('3mf', 2, mf, 3)):
        r = kern(dpath, *args)
        rec['steps'].append(r)
        print('== %s (%.1fs)\n%s' % (r['cmd'], r['seconds'], r['out'][:1500]), flush=True)
    outs = {s['cmd'].split()[0] + (' ' + s['cmd'].split()[1] if len(s['cmd'].split()) > 1 else ''): s['out'] for s in rec['steps']}
    checks = {}
    ev = outs['eval']
    checks['all_nodes_ok'] = all(re.match(r'node \d+: ok', ln) for ln in ev.split('\n') if ln.startswith('node '))
    checks['check'] = outs['check 2'].startswith('ok')
    m = re.search(r'min-wall \[([\d.e+-]+), ', outs['wall 2'])
    checks['min_wall'] = float(m.group(1)) if m else None
    checks['wall_ok_fdm'] = bool(m) and float(m.group(1)) >= 0.8
    checks['neighbour_disjoint'] = 'relation disjoint' in outs['interf 2'] and 'relation disjoint' in outs['interf 2'] and len([x for x in rec['steps'] if x['cmd'].startswith('interf') and 'relation disjoint' in x['out']]) == 2
    cl = [x['out'] for x in rec['steps'] if x['cmd'].startswith('clearance')]
    ms = [re.search(r'clearance \[([\d.e+-]+), ([\d.e+-]+)\]', o) for o in cl]
    m = ms[0] if all(ms) else None
    checks['joint_clearance'] = [float(m.group(1)), float(m.group(2))] if m else None
    checks['joint_clearance_other_side'] = [float(ms[1].group(1)), float(ms[1].group(2))] if m else None
    checks['joint_snug'] = bool(m) and all(0.05 <= float(x.group(1)) and float(x.group(2)) <= 0.2 for x in ms)
    checks['fdm_makeable'] = 'verdict makeable' in outs['make 2']
    checks['stl_written'] = os.path.exists(stl) and os.path.getsize(stl) > 0
    checks['3mf_written'] = os.path.exists(mf) and os.path.getsize(mf) > 0
    if checks['stl_written']:
        lo, hi = stl_box(stl)
        ok, ang = fits_bed(lo, hi)
        checks['stl_bbox'] = [round(hi[i] - lo[i], 3) for i in range(3)]
        checks['fits_a1_mini'] = ok
        checks['bed_rotation_deg'] = ang
    rec['checks'] = checks
    rec['pass'] = all(v for k, v in checks.items() if isinstance(v, bool))
    with open(os.path.join(OUT, 'wreath.json'), 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(rec, fh, indent=1)
    print(json.dumps(checks, indent=1))
    print('PASS' if rec['pass'] else 'FAIL')
    sys.exit(0 if rec['pass'] else 1)


if __name__ == '__main__':
    main()
