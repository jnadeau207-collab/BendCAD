import json
import math
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'e2e-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-k3'
RESULTS = []
PI = math.pi

IC = '(intent create any any any any)'
IS = '(intent same any any any any)'
IA = '(intent add any any any any)'
ID = '(intent remove any any any any)'
NUM = r'(-?[0-9.]+(?:e-?[0-9]+)?)'
IVR = r'\[' + NUM + r', ' + NUM + r'\]'


def wsl(*args, timeout=1800):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    env = dict(os.environ, MSYS_NO_PATHCONV='1', BEND_NO_TELEMETRY='1')
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout, env=env)
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if not ok})


def moments(design, node):
    out, dt = cli(design, 'mass', str(node))
    m = re.search(r'moments volume=' + IVR + r' centroid ' + IVR + 'x' + IVR + 'x' + IVR + r' inertia-centroid ' +
                  ' '.join([IVR] * 6) + r' status=certified', out)
    if not m:
        return None, out, dt
    g = [float(x) for x in m.groups()]
    ivs = [(g[i], g[i + 1]) for i in range(0, len(g), 2)]
    return dict(vol=ivs[0], c=ivs[1:4], i=ivs[4:10]), out, dt


def has(iv, x, rel=0.0):
    tol = rel * max(1.0, abs(x))
    return iv is not None and iv[0] - tol <= x <= iv[1] + tol


def tight(iv, x, rel, scale=1.0):
    return has(iv, x) and iv[1] - iv[0] <= rel * max(scale, abs(x))


def all_tight(mo, vol, c, ii, rel):
    big = max(abs(v) for v in ii[:3])
    return (mo is not None and tight(mo['vol'], vol, rel) and all(tight(mo['c'][k], c[k], rel) for k in range(3))
            and all(tight(mo['i'][k], ii[k], rel, big) for k in range(6)))


def closed(name, design, edits, node, vol, c, ii, rel=1e-9):
    out, _ = fresh(design, *edits)
    mo, raw, dt = moments(design, node)
    record(name, 'committed' in out and all_tight(mo, vol, c, ii, rel), got=mo, want=dict(vol=vol, c=c, i=ii),
           seconds=dt, raw=raw[-400:])


def occt(stp):
    code = ('from build123d import import_step\n'
            f's=import_step("{stp}")\n'
            'so=s.solids()[0]\n'
            'from OCP.GProp import GProp_GProps\n'
            'from OCP.BRepGProp import BRepGProp\n'
            'g=GProp_GProps()\n'
            'BRepGProp.VolumeProperties_s(so.wrapped,g,1e-12,True)\n'
            'c=g.CentreOfMass()\n'
            'm=g.MatrixOfInertia()\n'
            'print(g.Mass(),c.X(),c.Y(),c.Z(),m.Value(1,1),m.Value(2,2),m.Value(3,3),m.Value(1,2),m.Value(1,3),m.Value(2,3))\n')
    out, _ = wsl('python3', '-c', code)
    try:
        return [float(x) for x in out.split()[-10:]]
    except ValueError:
        return None


def against_occt(name, design, edits, node, rel):
    out, _ = fresh(design, *edits)
    mo, raw, dt = moments(design, node)
    cli(design, 'step', str(node), f'{WORK}/{design}.stp')
    o = occt(f'{WORK}/{design}.stp')
    ok = mo is not None and o is not None and has(mo['vol'], o[0], rel) and all(has(mo['c'][k], o[1 + k], rel) for k in range(3))
    if ok:
        want_i = [o[4], o[5], o[6], o[7], o[8], o[9]]
        ok = all(has(mo['i'][k], want_i[k], rel) for k in range(6))
    record(name, 'committed' in out and ok, got=mo, occt=o, seconds=dt, raw=raw[-400:])


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    v = 6000.0
    closed('box', 'b.bcd', [f'(node 1 (box 10 20 30) {IC})'], 1, v, [5, 10, 15],
           [v * (400 + 900) / 12, v * (100 + 900) / 12, v * (100 + 400) / 12, 0, 0, 0])
    vc = 250 * PI
    closed('cylinder', 'c.bcd', [f'(node 1 (cylinder 5 10) {IC})'], 1, vc, [0, 0, 5],
           [vc * (3 * 25 + 100) / 12, vc * (3 * 25 + 100) / 12, vc * 25 / 2, 0, 0, 0], 1e-5)
    vs = 4 * PI * 64 / 3
    closed('sphere', 's.bcd', [f'(node 1 (sphere 4) {IC})'], 1, vs, [0, 0, 0], [0.4 * vs * 16] * 3 + [0, 0, 0], 3e-4)
    vt = 2 * PI * PI * 30 * 100
    closed('torus', 't.bcd', [f'(node 1 (torus 30 10) {IC})'], 1, vt, [0, 0, 0],
           [vt * (900 / 2 + 5 * 100 / 8), vt * (900 / 2 + 5 * 100 / 8), vt * (900 + 3 * 100 / 4), 0, 0, 0], 2e-6)
    hv = 6000.0 - PI * 4 * 30
    cx = (6000.0 * 5 - PI * 4 * 30 * 3) / hv
    cy = (6000.0 * 10 - PI * 4 * 30 * 6) / hv
    out, _ = fresh('h.bcd', f'(node 1 (box 10 20 30) {IC})',
                   f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 3 6 2))) {ID})')
    mo, raw, dt = moments('h.bcd', 2)
    record('box.off_centre_hole', 'committed' in out and mo is not None and tight(mo['vol'], hv, 1e-8)
           and tight(mo['c'][0], cx, 3e-8) and tight(mo['c'][1], cy, 1e-8) and tight(mo['c'][2], 15.0, 3e-9),
           got=mo, want=dict(vol=hv, cx=cx, cy=cy), raw=raw[-400:])
    out, _ = fresh('m.bcd', f'(node 1 (box 10 20 30) {IC})', '(node 2 (move 1 7 -3 2 4) (intent same 0 0 1 0))')
    mo, raw, dt = moments('m.bcd', 2)
    ev, _ = cli('m.bcd', 'eval')
    bb = re.search(r'node 2:.*?bbox=' + IVR + 'x' + IVR + 'x' + IVR, ev)
    centre = [(float(bb.group(2 * k + 1)) + float(bb.group(2 * k + 2))) / 2 for k in range(3)] if bb else None
    record('box.moved_turned', mo is not None and centre is not None and all(tight(mo['c'][k], centre[k], 1e-9) for k in range(3))
           and sorted(round((x[0] + x[1]) / 2) for x in mo['i'][:3]) == [250000, 500000, 650000],
           got=mo, bbox_centre=centre, raw=raw[-400:])
    against_occt('fillet.hole', 'f.bcd', [f'(node 1 (box 20 20 10) {IC})',
                 f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 10 10 3))) {ID})',
                 f'(node 3 (fillet 2 (face 2 n1.c0.top) (circle 10 10 3) 1) {ID})'], 3, 1e-7)
    against_occt('sphere.cut_by_box', 'sb.bcd', [f'(node 1 (box 10 10 10) {IC})', f'(node 2 (sphere 4) {IC})',
                 '(node 3 (move 2 5 5 9 0) (intent same 0 0 1 0))', f'(node 4 (difference 1 3) {ID})'], 4, 1e-7)
    against_occt('cone.revolve', 'cn.bcd', [f'(node 1 (revolve (region (path 0 0 (line 4 0) (line 1 6) (line 0 6)))) {IC})',
                 '(node 2 (move 1 3 2 1 0) (intent same 0 0 1 0))'], 2, 1e-8)
    json.dump(RESULTS, open(OUT, 'w'), indent=1)
    n = sum(1 for r in RESULTS if r['ok'])
    print(f'{n}/{len(RESULTS)} passed')
    sys.exit(0 if n == len(RESULTS) else 1)


if __name__ == '__main__':
    main()
