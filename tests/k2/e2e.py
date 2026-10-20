import json
import math
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, 'docs', 'receipts', 'g3'))
OUT = os.path.join(HERE, 'e2e-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-k2'
RESULTS = []

IC = '(intent create any any any any)'
IS = '(intent same any any any any)'
ID = '(intent remove any any any any)'


def wsl(*args, timeout=900):
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


def put(name, text):
    wsl('bash', '-c', f'cat > {WORK}/{name} <<"EOF"\n{text}\nEOF')
    return f'{WORK}/{name}'


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if not ok})


def iv(text, key):
    m = re.search(key + r'=\[([^,\]]+), ([^\]]+)\]', text)
    return (float(m.group(1)), float(m.group(2))) if m else None


def contains(v, x, tol=0.0):
    return v is not None and v[0] - tol <= x <= v[1] + tol


def width(v):
    return None if v is None else v[1] - v[0]


AL = '(material 1 6082-T6 2700 23.4e-6)'


def materials():
    out, _ = fresh('m.bcd', f'(node 1 (box 10 20 30) {IC})', AL)
    ms, _ = cli('m.bcd', 'mass', '1')
    m = iv(ms, 'mass')
    record('material.mass', 'committed' in out and 'material 6082-T6' in ms and contains(m, 0.0162)
           and width(m) < 1e-9, mass=m, out=ms[-300:])
    cli('m.bcd', 'step', '1', f'{WORK}/m.stp')
    stp, _ = wsl('cat', f'{WORK}/m.stp')
    record('material.step', "MATERIAL_DESIGNATION('6082-T6'" in stp and 'DENSITY' in stp.upper()
           and '2700.' in stp, has=("MATERIAL_DESIGNATION" in stp))
    out2, _ = cli('m.bcd', 'apply', '(material 1 S355 7850 12e-6)')
    ms2, _ = cli('m.bcd', 'mass', '1')
    record('material.rebind', 'committed' in out2 and 'material S355' in ms2
           and contains(iv(ms2, 'mass'), 0.0471), mass=iv(ms2, 'mass'))
    sh, _ = cli('m.bcd', 'show')
    record('material.persists', '(material 1 S355 7850' in sh, show=sh[-300:])


def asm_mass():
    fresh('a.bcd', f'(node 1 (box 10 10 10) {IC})', f'(node 2 (cylinder 5 10) {IC})',
          '(material 1 6082-T6 2700 23.4e-6)', '(material 2 16MnCr5 7850 11.5e-6)')
    f = '(assembly (inst A 1 0 0 0 0) (inst B 2 30 0 0 0) (inst C 2 60 0 0 0) (fix 1 A) (fix 2 B) (fix 3 C))'
    out, _ = cli('a.bcd', 'asm', 'mass', f)
    want = 1000e-9 * 2700 + 2 * (250 * math.pi * 1e-9 * 7850)
    record('asm.mass', contains(iv(out, 'total'), want, 1e-12) and 'A 6082-T6' in out and 'C 16MnCr5' in out,
           out=out[-400:], want=want)
    fresh('b.bcd', f'(node 1 (box 10 10 10) {IC})', f'(node 2 (cylinder 5 10) {IC})', AL)
    out2, _ = cli('b.bcd', 'asm', 'mass', f)
    record('asm.mass_unbound_refused', 'material-not-bound' in out2 and 'total' not in out2, out=out2[-300:])


def plate_holes():
    return [f'(node 1 (box 40 30 20) {IC})',
            f'(node 2 (pocket 1 (face 1 0 top) 16 (region (circle 10 15 3.4))) {ID})',
            f'(node 3 (pocket 2 (face 1 0 top) 16 (region (circle 30 15 2.5))) {ID})']


def threads():
    out, _ = fresh('t.bcd', *plate_holes())
    fs, _ = cli('t.bcd', 'faces', '3')
    cyls = [ln.split()[0] for ln in fs.splitlines() if ' cylinder' in ln]
    h8 = next((c for c in cyls if c.startswith('n2.')), None)
    h6 = next((c for c in cyls if c.startswith('n3.')), None)
    o1, _ = cli('t.bcd', 'apply', f'(thread 3 tap8 {h8} M8x1.25 6H 8 20)', f'(thread 3 tap6 {h6} M6 6H 10 20)')
    tl, _ = cli('t.bcd', 'threads', '3')
    record('thread.semantic', 'committed' in o1 and 'tap8 M8x1.25 6H z=[8, 20] length=12' in tl
           and 'tap6 M6x1 6H z=[10, 20] length=10' in tl and 'minor=[6.647, 6.912]' in tl, out=o1[-200:], threads=tl)
    o2, _ = cli('t.bcd', 'apply', f'(thread 3 bad {h8} M10 6H 8 20)')
    record('thread.minor_mismatch', 'thread-minor-diameter-mismatch' in o2 and 'committed' not in o2, out=o2[-300:])
    cli('t.bcd', 'step', '3', f'{WORK}/t.stp')
    stp, _ = wsl('cat', f'{WORK}/t.stp')
    record('thread.step', "'M8x1.25 6H'" in stp and "'M6x1 6H'" in stp and 'AP242' in stp, size=len(stp))
    return h8


def screw_and_engage(h8):
    fresh('s.bcd', *plate_holes(), f'(node 4 (cylinder 4 30) {IC})',
          f'(thread 3 tap8 {h8} M8x1.25 6H 8 20)')
    fs, _ = cli('s.bcd', 'faces', '4')
    side = next((ln.split()[0] for ln in fs.splitlines() if ' cylinder' in ln), None)
    o, _ = cli('s.bcd', 'apply', f'(thread 4 ext {side} M8x1.25 6g 0 20)')
    f = '(assembly (inst P 3 0 0 0 0) (inst S 4 10 15 8 0) (fix 1 P) (fix 2 S))'
    out, _ = cli('s.bcd', 'asm', 'engage', 'S', 'ext', 'P', 'tap8', f)
    record('thread.engagement', 'committed' in o and contains(iv(out, 'engagement'), 12.0) and width(iv(out, 'engagement')) < 1e-9
           and 'ratio=1.5' in out, out=out[-300:])


def fits():
    out, _ = fresh('f.bcd', f'(node 1 (box 40 40 20) {IC})',
                   f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 20 20 10))) {ID})',
                   f'(node 3 (cylinder 10 30) {IC})', f'(node 4 (cylinder 10 30) {IC})',
                   '(material 2 6082-T6 2700 23.4e-6)', '(material 3 16MnCr5 7850 11.5e-6)',
                   '(material 4 6082-T6 2700 23.4e-6)')
    fs2, _ = cli('f.bcd', 'faces', '2')
    hole = next((ln.split()[0] for ln in fs2.splitlines() if ' cylinder' in ln), None)
    fs3, _ = cli('f.bcd', 'faces', '3')
    shaft = next((ln.split()[0] for ln in fs3.splitlines() if ' cylinder' in ln), None)
    fs4, _ = cli('f.bcd', 'faces', '4')
    shaft4 = next((ln.split()[0] for ln in fs4.splitlines() if ' cylinder' in ln), None)
    p = (f'(pmi (node 2) (temp cold 20) (temp hot 80) (fit run 2 {hole} 3 {shaft} H7/g6 clearance) '
         f'(fit press 2 {hole} 4 {shaft4} H7/p6 press))')
    o, _ = cli('f.bcd', 'pmi', 'fits', p)
    run20 = re.search(r'fit run .*?temp cold .*?clearance=\[([^,]+), ([^\]]+)\]', o, re.S)
    hot = re.search(r'fit run .*?temp hot .*?clearance=\[([^,]+), ([^\]]+)\]', o, re.S)
    pr = re.search(r'fit press .*?temp cold .*?interference=\[([^,]+), ([^\]]+)\]', o, re.S)
    ah, as_ = 1 + 23.4e-6 * 60, 1 + 11.5e-6 * 60
    hot_lo = 20.0 * ah - 19.993 * as_
    hot_hi = 20.021 * ah - 19.980 * as_
    ok_run = run20 and abs(float(run20.group(1)) - 0.007) < 1e-9 and abs(float(run20.group(2)) - 0.041) < 1e-9
    ok_hot = hot and abs(float(hot.group(1)) - hot_lo) < 1e-9 and abs(float(hot.group(2)) - hot_hi) < 1e-9
    ok_pr = pr and abs(float(pr.group(1)) - 0.001) < 1e-9 and abs(float(pr.group(2)) - 0.035) < 1e-9
    record('fit.iso286', bool(ok_run) and bool(ok_hot) and bool(ok_pr) and 'status=certified' in o
           and 'verdict=press-certified' in o and 'verdict=clearance-certified' in o, out=o[-900:])
    p2 = f'(pmi (node 2) (temp cold 20) (fit bad 2 {hole} 3 {shaft} H7/g6 press))'
    o2, _ = cli('f.bcd', 'pmi', 'fits', p2)
    record('fit.declared_kind_refused', 'fit-not-press' in o2, out=o2[-300:])
    p4 = f'(pmi (node 2) (temp cold 20) (temp hot 80) (fit dowel 2 {hole} 3 {shaft} H7/k6 transition))'
    o4, _ = cli('f.bcd', 'pmi', 'fits', p4)
    tr = re.search(r'temp cold .*?clearance=\[([^,]+), ([^\]]+)\]', o4)
    record('fit.transition', tr is not None and abs(float(tr.group(1)) + 0.015) < 1e-9 and abs(float(tr.group(2)) - 0.019) < 1e-9
           and 'verdict=transition-certified' in o4, out=o4[-400:])
    p5 = f'(pmi (node 2) (fit loose 2 {hole} 3 {shaft} H7/g6 transition))'
    o5, _ = cli('f.bcd', 'pmi', 'fits', p5)
    record('fit.transition_refused', 'fit-not-transition' in o5 and 'transition-certified' not in o5, out=o5[-300:])
    p3 = f'(pmi (node 2) (fit odd 2 {hole} 3 {shaft} Q9/z1 clearance))'
    o3, _ = cli('f.bcd', 'pmi', 'fits', p3)
    record('fit.unknown_class', 'unknown-fit-class' in o3, out=o3[-300:])


def mesh():
    fresh('g.bcd', f'(node 1 (box 60 40 10) {IC})',
          f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 30 20 10.04))) {ID})',
          f'(node 3 (cylinder 10 10) {IC})', f'(node 4 (cylinder 10 10) {IC})')
    f = '(assembly (inst B 2 0 0 0 0) (inst G 3 30 20 0 0) (inst H 4 50.05 20 0 0) (fix 1 B) (fix 2 G) (fix 3 H))'
    o1, _ = cli('g.bcd', 'asm', 'gap', 'G', 'B', f)
    o2, _ = cli('g.bcd', 'asm', 'gap', 'G', 'H', f)
    record('mesh.tip_to_bore', contains(iv(o1, 'gap'), 0.04, 1e-9) and width(iv(o1, 'gap')) < 1e-6
           and 'status=certified' in o1, out=o1[-300:])
    record('mesh.gear_to_gear', contains(iv(o2, 'gap'), 0.05, 1e-9) and width(iv(o2, 'gap')) < 1e-6
           and 'status=certified' in o2, out=o2[-300:])
    o3, _ = cli('g.bcd', 'asm', 'mesh', 'G', '11', 'H', '11', f)
    record('mesh.rotating', contains(iv(o3, 'gap'), 0.05, 1e-6) and 'over=pitch' in o3 and 'status=certified' in o3,
           out=o3[-300:])


def poly_of(path):
    nums = [float(v) for v in re.findall(r'-?[0-9.]+', path)]
    return list(zip(nums[0::2], nums[1::2]))


def oracle_mesh(pa, pb, ca, cb, za, zb, n=4000):
    from shapely.geometry import Polygon
    from shapely import affinity
    a0, b0 = Polygon(pa), Polygon(pb)
    k = za / zb

    def d(th):
        a = affinity.rotate(a0, th, origin=ca, use_radians=True)
        b = affinity.rotate(b0, -k * th, origin=cb, use_radians=True)
        return a.distance(b)
    step = 2 * math.pi / za / n
    ds = [(d(i * step), i * step) for i in range(n + 1)]
    best, t = min(ds)
    lo, hi = t - step, t + step
    for _ in range(80):
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        if d(m1) < d(m2):
            hi = m2
        else:
            lo = m1
    return min(best, d((lo + hi) / 2)), d(0.0)


def mesh_involute():
    from gear import gear_path
    z, m = 12, 3.0
    ga = gear_path(z, m=m)
    gb = gear_path(z, m=m, phase=math.pi / z)
    ra = m * z / 2 + m
    put('ga.txt', ga)
    out, dt = fresh('inv.bcd', f'(node 1 (prism 0 20 (region {ga})) {IC})', f'(node 2 (prism 0 20 (region {gb})) {IC})',
                    f'(node 3 (box 120 60 20) {IC})',
                    f'(node 4 (pocket 3 (face 3 0 top) through (region (circle 30 30 {ra + 0.04!r}))) {ID})')
    cd = m * z
    f = (f'(assembly (inst A 1 30 30 0 0) (inst B 2 {30 + cd!r} 30 0 0) (inst H 4 0 0 0 0) '
         '(fix 1 A) (fix 2 B) (fix 3 H))')
    t0 = time.time()
    o1, _ = cli('inv.bcd', 'asm', 'mesh', 'A', str(z), 'B', str(z), f)
    tm = time.time() - t0
    o2, _ = cli('inv.bcd', 'asm', 'gap', 'A', 'B', f)
    o3, _ = cli('inv.bcd', 'asm', 'gap', 'A', 'H', f)
    omin, o0 = oracle_mesh(poly_of(ga), [(x + cd, y) for x, y in poly_of(gb)], (0.0, 0.0), (cd, 0.0), z, z)
    g1, g2, g3 = iv(o1, 'gap'), iv(o2, 'gap'), iv(o3, 'gap')
    record('mesh.involute_rotating', 'committed' in out and g1 is not None and g1[0] <= omin + 1e-9 and g1[1] <= omin + 1e-6
           and width(g1) < 1e-3 and 'verdict=clearance status=certified' in o1,
           gap=g1, oracle=omin, seconds=tm, out=o1[-300:])
    record('mesh.involute_static', contains(g2, o0, 1e-9) and width(g2) < 1e-6, gap=g2, oracle=o0, out=o2[-300:])
    tip = ra + 0.04 - max(math.hypot(x, y) for x, y in poly_of(ga))
    record('mesh.involute_tip_to_bore', contains(g3, tip, 1e-9) and width(g3) < 1e-6 and 'status=certified' in o3,
           gap=g3, oracle=tip, out=o3[-300:])


def thin_tori():
    out, _ = fresh('or.bcd', f'(node 1 (torus 30 1.5) {IC})', f'(node 2 (torus 20 0.5) {IC})', f'(node 3 (torus 24.155 1.31) {IC})',
                   '(material 1 NBR70 1250 2.3e-4)', '(material 2 1.4310 7900 1.6e-5)', '(material 3 NBR70 1250 2.3e-4)')
    ev, _ = cli('or.bcd', 'eval')
    for node, big, r, rho, tag in ((1, 30.0, 1.5, 1250, 'oring'), (2, 20.0, 0.5, 7900, 'garter'), (3, 24.155, 1.31, 1250, 'oring_inexact')):
        v = 2 * math.pi ** 2 * big * r * r
        line = next((ln for ln in ev.splitlines() if ln.startswith(f'node {node}:')), '')
        ck, _ = cli('or.bcd', 'check', str(node))
        ms, _ = cli('or.bcd', 'mass', str(node))
        cli('or.bcd', 'step', str(node), f'{WORK}/{tag}.stp')
        sv, _ = wsl('python3', '-c', 'from build123d import import_step;'
                    f's=import_step("{WORK}/{tag}.stp");print(len(s.solids()), s.solids()[0].volume)')
        parts = sv.split()
        stp_ok = len(parts) >= 2 and parts[-2] == '1' and abs(float(parts[-1]) - v) / v < 1e-6
        record(f'torus.{tag}', 'committed' in out and contains(iv(line, 'volume'), v) and ck.startswith('ok:')
               and contains(iv(ms, 'mass'), v * 1e-9 * rho, 1e-15) and stp_ok,
               ratio=big / r, volume=iv(line, 'volume'), exact=v, check=ck.strip()[:80], step=sv.strip()[-80:])


ORING_HALF = [
    '(node 1 (revolve (region (path 16.075 -1.95 (line 17.305 -1.95) (arc 17.305 -0.975 0.975 17.305 0 ccw) '
    '(line 16.075 0) (arc 16.075 -0.975 0.975 16.075 -1.95 ccw)))) (intent create any any any any))',
    f'(node 2 (box 40 80 4) {IC})',
    '(node 3 (move 2 -40 -40 -3 0) (intent same 0 0 1 0))',
    '(node 4 (intersection 1 3) (intent same any any 1 0))',
]
STADIUM = ('(region (path -0.615 -1.95 (line 0.615 -1.95) (arc 0.615 -0.975 0.975 0.615 0 ccw) '
           '(line -0.615 0) (arc -0.615 -0.975 0.975 -0.615 -1.95 ccw)))')
TRACK = ('(along (path 0 -16.69 (line 22.05 -16.69) (arc 22.05 0 16.69 22.05 16.69 ccw) '
         '(line 0 16.69) (arc 0 0 16.69 0 -16.69 ccw)))')


def solid_journey(tag, design, node, v, out, ev):
    line = next((ln for ln in ev.splitlines() if ln.startswith(f'node {node}:')), '')
    ck, _ = cli(design, 'check', str(node))
    cli(design, 'step', str(node), f'{WORK}/{tag}.stp')
    sv, _ = wsl('python3', '-c', 'from build123d import import_step;'
                f's=import_step("{WORK}/{tag}.stp");print(len(s.solids()), s.solids()[0].volume)')
    parts = sv.split()
    stp_ok = len(parts) >= 2 and parts[-2] == '1' and abs(float(parts[-1]) - v) / v < 1e-6
    record(f'torus.{tag}', 'committed' in out and contains(iv(line, 'volume'), v) and ck.startswith('ok:') and stp_ok,
           volume=iv(line, 'volume'), exact=v, check=ck.strip()[:80], step=sv.strip()[-80:], line=line[:200])


def oring_racetrack():
    area = 1.23 * 1.95 + math.pi * 0.975 ** 2
    out, _ = fresh('oh.bcd', *ORING_HALF)
    ev, _ = cli('oh.bcd', 'eval')
    solid_journey('oring_half', 'oh.bcd', 4, math.pi * 16.69 * area, out, ev)
    out, _ = fresh('rt.bcd', f'(node 1 (sweep {TRACK} {STADIUM}) (intent create any any 1 1))')
    ev, _ = cli('rt.bcd', 'eval')
    solid_journey('oring_racetrack', 'rt.bcd', 1, area * (2 * math.pi * 16.69 + 2 * 22.05), out, ev)


def bean_sweep():
    c, sn = math.cos(math.pi / 6), math.sin(math.pi / 6)
    f = lambda r, sg: f'{r * c!r} {sg * r * sn!r}'
    path = (f'(path {f(50, -1)} (arc 0 0 50 {f(50, 1)} ccw) (arc {f(45, 1)} 5 {f(40, 1)} ccw) '
            f'(arc 0 0 40 {f(40, -1)} cw) (arc {f(45, -1)} 5 {f(50, -1)} ccw))')
    out, _ = fresh('bn.bcd', f'(node 1 (sweep (along {path}) (region (path 1 0 (line 3 0) (line 3 2) (line 1 2) (line 1 0)))) (intent create any any 1 1))')
    ev, _ = cli('bn.bcd', 'eval')
    solid_journey('bean_concave_turn', 'bn.bcd', 1, 176 * math.pi, out, ev)


def asm_step():
    fresh('as.bcd', f'(node 1 (box 10 20 30) {IC})', f'(node 2 (cylinder 5 10) {IC})')
    f = ('(assembly (inst base 1 0 0 0 0) (inst pin 2 0 0 0 0) (fix 1 base) '
         '(coinc 2 base 5 10 30 pin 0 0 0))')
    out, _ = cli('as.bcd', 'asm', 'step', f'{WORK}/as.stp', f)
    sv, _ = wsl('python3', '-c', 'from build123d import import_step;'
                f's=import_step("{WORK}/as.stp");'
                'print(";".join("%.9f %.6f %.6f %.6f %.6f" % (x.volume, x.bounding_box().min.X, x.bounding_box().min.Y, '
                'x.bounding_box().min.Z, x.bounding_box().max.Z) for x in s.solids()))')
    rows = sorted(tuple(float(v) for v in r.split()) for r in sv.strip().splitlines()[-1].split(';')) if ';' in sv else []
    pin = rows[0] if len(rows) == 2 else None
    base = rows[1] if len(rows) == 2 else None
    record('asm.step', 'instances base,pin' in out and len(rows) == 2
           and abs(pin[0] - 250 * math.pi) < 1e-6 and abs(base[0] - 6000) < 1e-6
           and abs(pin[1] - 0.0) < 1e-6 and abs(pin[2] - 5.0) < 1e-6 and abs(pin[3] - 30.0) < 1e-6 and abs(pin[4] - 40.0) < 1e-6,
           out=out[-300:], solids=rows, raw=sv[-300:])
    o2, _ = cli('as.bcd', 'asm', 'step', f'{WORK}/bad.stp', '(assembly (inst a 9 0 0 0 0) (fix 1 a))')
    record('asm.step_refused', 'refused' in o2 and 'wrote' not in o2, out=o2[-300:])


def press_declared():
    fresh('pr.bcd', f'(node 1 (box 40 40 20) {IC})',
          f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 20 20 10))) {ID})',
          f'(node 3 (cylinder 10.02 20) {IC})', f'(node 4 (cylinder 5 10) {IC})')
    base = ('(inst H 2 0 0 0 0) (inst B 3 20 20 0 0) (inst P 4 80 0 0 0) '
            '(fix 1 H) (fix 2 B) (fix 3 P)')
    fh, _ = cli('pr.bcd', 'faces', '2')
    fb, _ = cli('pr.bcd', 'faces', '3')
    hf = next((ln.split()[0] for ln in fh.splitlines() if ' cylinder' in ln), None)
    sf = next((ln.split()[0] for ln in fb.splitlines() if ' cylinder' in ln), None)
    out, _ = cli('pr.bcd', 'asm', 'interf', f'(assembly {base} (press bush H {hf} B {sf}))')
    blocks = out.split('pair ')
    hb = next((b for b in blocks if b.startswith('H B')), '')
    hp = next((b for b in blocks if b.startswith('H P')), '')
    rad = re.search(r'witness=press radial=([0-9.e-]+)', hb)
    record('press.declared', 'relation interference status=certified' in hb and 'declared press-fit bush status=declared' in hb
           and rad is not None and abs(float(rad.group(1)) - 0.02) < 1e-9
           and 'relation disjoint' in hp and 'declared' not in hp, out=out[-600:])
    o1, _ = cli('pr.bcd', 'asm', 'interf', f'(assembly {base} (press bare H B))')
    record('press.bare_on_certified_interference', 'relation interference status=certified method=exact-intersection' in o1
           and 'declared press-fit bare status=declared' in o1 and 'witness=press' not in o1, out=o1[-400:])
    o2, _ = cli('pr.bcd', 'asm', 'interf', f'(assembly {base} (press wrong H {hf} P n4.c0.wall.0.0))')
    record('press.declared_not_interfering', 'declared-press-not-interfering wrong' in o2, out=o2[-400:])
    o3, _ = cli('pr.bcd', 'asm', 'interf', f'(assembly {base} (press ghost H {hf} Q {sf}))')
    record('press.unknown_instance', 'press-names-unknown-instance ghost' in o3, out=o3[-300:])


def interf_exact():
    fresh('ix.bcd', f'(node 1 (box 10 10 10) {IC})')
    out, _ = cli('ix.bcd', 'asm', 'interf', '(assembly (inst a 1 0 0 0 0) (inst b 1 10 0 0 0) (inst c 1 5 0 0 0) '
                 '(fix 1 a) (fix 2 b) (fix 3 c))')
    blocks = out.split('pair ')
    ab = next((b for b in blocks if b.startswith('a b')), '')
    ac = next((b for b in blocks if b.startswith('a c')), '')
    record('interf.exact_contact', 'relation disjoint status=certified method=exact-intersection' in ab
           and 'relation interference status=certified' in ac, out=out[-700:])


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    materials()
    asm_mass()
    h8 = threads()
    screw_and_engage(h8)
    fits()
    mesh()
    mesh_involute()
    thin_tori()
    oring_racetrack()
    bean_sweep()
    asm_step()
    press_declared()
    interf_exact()
    json.dump(RESULTS, open(OUT, 'w'), indent=1)
    n = sum(1 for r in RESULTS if r['ok'])
    print(f'{n}/{len(RESULTS)} passed')
    sys.exit(0 if n == len(RESULTS) else 1)


if __name__ == '__main__':
    main()
