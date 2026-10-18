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
            f'(node 3 (pocket 2 (face 1 0 top) 16 (region (circle 30 15 3.0))) {ID})']


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
                   '(material 4 16MnCr5 7850 11.5e-6)')
    fs2, _ = cli('f.bcd', 'faces', '2')
    hole = next((ln.split()[0] for ln in fs2.splitlines() if ' cylinder' in ln), None)
    fs3, _ = cli('f.bcd', 'faces', '3')
    shaft = next((ln.split()[0] for ln in fs3.splitlines() if ' cylinder' in ln), None)
    p = (f'(pmi (node 2) (temp cold 20) (temp hot 80) (fit run 2 {hole} 3 {shaft} H7/g6 clearance) '
         f'(fit press 2 {hole} 4 {shaft} H7/p6 press))')
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


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    materials()
    asm_mass()
    h8 = threads()
    screw_and_engage(h8)
    fits()
    mesh()
    json.dump(RESULTS, open(OUT, 'w'), indent=1)
    n = sum(1 for r in RESULTS if r['ok'])
    print(f'{n}/{len(RESULTS)} passed')
    sys.exit(0 if n == len(RESULTS) else 1)


if __name__ == '__main__':
    main()
