import hashlib
import json
import os
import re
import struct
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, 'e2e-report.json')
BASE = os.path.join(HERE, 'baseline.json')
ART = os.path.join(HERE, 'artifacts')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-c13'
VERSION = 1
RESULTS = []
HASHONLY = ('.bin', '.stl')
BLESS = '--bless' in sys.argv

IC = '(intent create any any any any)'
IA = '(intent add any any any any)'

L, W, T, R, LH = 100.0, 50.0, 2.0, 3.0, 10.0
KLO, KHI = 0.3, 0.5
FLAT = f'(node 1 (flat {L:g} {W:g} {T:g}) {IC})'
B90 = lambda b=1, n=0, r=R, d=90, i=2: f'(node {i} (bend {b} (edge {n}) {r:g} {d}) {IA})'
HEM = lambda b=1, n=0, l=LH, i=2: f'(node {i} (hem {b} (edge {n}) {l:g}) {IA})'
BRACKET = [FLAT, B90(), B90(2, 2, R, 90, 3), HEM(3, 0, LH, 4)]


def pt(x, y, z):
    return f'(pt {x:g} {y:g} {z:g})'


XS = [0.0, 4.0, 6.0, 10.0]
YS = [0.0, 2.0, 3.0, 5.0]
RECT_PTS = [(x, y, 0.0) for y in YS for x in XS]
COWL_PTS = [(x, y, (x * (10.0 - x) * y * (5.0 - y)) / 500.0 if 0.0 < x < 10.0 and 0.0 < y < 5.0 else 0.0)
            for y in YS for x in XS]
PATCH = lambda pts, i=1: f"(node {i} (patch {' '.join(pt(*p) for p in pts)}) {IC})"
LOFT = lambda z, b, t, i=1: (f"(node {i} (loft-open {z:g} "
                             f"(region (path {b[0]:g} {b[1]:g} (line {b[2]:g} {b[1]:g}) (line {b[2]:g} {b[3]:g}) (line {b[0]:g} {b[3]:g}))) "
                             f"(region (path {t[0]:g} {t[1]:g} (line {t[2]:g} {t[1]:g}) (line {t[2]:g} {t[3]:g}) (line {t[0]:g} {t[3]:g})))) {IC})")
THICK = lambda b, t, i: f'(node {i} (thicken-open {b} {t:g}) {IA})'

NACA = lambda m, p, t, c, n, i=1: f'(node {i} (naca4 {m} {p} {t:g} {c:g} {n}) {IC})'
BLADE = lambda secs, z, tw, tp, i: f"(node {i} (blade {' '.join(str(s) for s in secs)} {z:g} {tw} {tp}) {IC})"

BOX = f'(node 1 (box 10 10 10) {IC})'


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


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def dump(rel, text):
    p = os.path.join(WORK, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, 'w', newline='\n') as f:
        f.write(text)
    return rel


def num(tok):
    if tok.startswith('b:'):
        return struct.unpack('>d', struct.pack('>Q', int(tok[2:])))[0]
    return float(tok)


def faces_n(out, node):
    m = re.search(rf'node {node}: ok .*?faces=(\d+)', out)
    return int(m.group(1)) if m else None


def face_lines(text):
    return [ln for ln in text.strip().splitlines() if ln and not ln.startswith('deleted ')]


def kind_n(lines, kind):
    return sum(1 for ln in lines if len(ln.split()) >= 2 and ln.split()[1] == kind)


def blade_header(out):
    m = re.search(r'blade node (\d+) sections (\d+) span (\S+) twist (\d+) taper (\d+)', out)
    return m.groups() if m else None


def blade_sched(out):
    m = re.search(r'twist-schedule (.*)', out)
    return [num(t) for t in m.group(1).split()] if m else None


def record(name, ok, artifacts=(), **checks):
    RESULTS.append(dict(name=name, ok=bool(ok), checks=checks,
                        artifacts={a: sha(os.path.join(WORK, a)) for a in artifacts
                                   if os.path.exists(os.path.join(WORK, a))}))
    print(('PASS ' if ok else 'FAIL ') + name, flush=True)


def g3_gearbox():
    d = os.path.join(WORK, 'g3')
    r = subprocess.run([sys.executable, os.path.join(ROOT, 'tools', 'g3', 'gearbox.py'), d, 'parts'],
                       capture_output=True, text=True, timeout=3600,
                       env=dict(os.environ, BENDCAD_BIN=BIN, BEND_NO_TELEMETRY='1'))
    rp = os.path.join(d, 'report.json')
    rep = json.load(open(rp)) if os.path.exists(rp) else None
    checks = dict(exit0=r.returncode == 0,
                  stages=rep is not None and rep.get('stages') == {'housing': 'committed', 'lid': 'committed',
                                                                   'drivetrain': 'committed', 'purchased': 'committed'},
                  solve=rep is not None and re.match(r'asm solved ninst 119 nmates 122 dof 0 ',
                                                     rep.get('solve', '')) is not None,
                  files=all(os.path.exists(os.path.join(d, f)) for f in ('gearbox.bcd', 'assembly.txt')))
    record('g3.gearbox', all(checks.values()),
           artifacts=('g3/gearbox.bcd', 'g3/assembly.txt', 'g3/report.json'),
           solve_line=rep.get('solve') if rep else None, **checks)


def sheet_bracket():
    out, _ = fresh('cb.bcd', *BRACKET)
    ev, _ = cli('cb.bcd', 'eval')
    fl, _ = cli('cb.bcd', 'faces', '4')
    fo, _ = cli('cb.bcd', 'flat', '4', str(KLO), str(KHI))
    sh, _ = cli('cb.bcd', 'show')
    cli('cb.bcd', 'tess', '4', f'{WORK}/cb.obj')
    cli('cb.bcd', 'step', '4', f'{WORK}/cb.stp')
    cli('cb.bcd', 'archive', '4', f'{WORK}/cb.bin')
    lines = face_lines(fl)
    checks = dict(committed='committed' in out, volume='volume=' in ev,
                  faces=len(lines) == 16, cyl=kind_n(lines, 'cylinder') == 4,
                  header='flat node 4 bends 2 hems 1' in fo, show='(node 4' in sh)
    dump('cb.eval.txt', ev)
    dump('cb.faces.txt', fl)
    dump('cb.flat.txt', fo)
    dump('cb.show.txt', sh)
    record('sheet.bracket', all(checks.values()),
           artifacts=('cb.bcd', 'cb.eval.txt', 'cb.faces.txt', 'cb.flat.txt', 'cb.show.txt',
                      'cb.stp', 'cb.obj', 'cb.bin'), **checks)


def surf_cowl():
    out, _ = fresh('cc.bcd', PATCH(COWL_PTS))
    su, _ = cli('cc.bcd', 'surf', '1')
    out2, _ = fresh('cs.bcd', PATCH(RECT_PTS), THICK(1, 2.0, 2))
    ev, _ = cli('cs.bcd', 'eval')
    sl, _ = cli('cs.bcd', 'faces', '2')
    sh, _ = cli('cs.bcd', 'show')
    cli('cs.bcd', 'step', '2', f'{WORK}/cs.stp')
    cli('cs.bcd', 'archive', '2', f'{WORK}/cs.bin')
    checks = dict(committed='committed' in out and 'committed' in out2,
                  header='surf node 1 kind patch faces 1 boundary 4' in su,
                  volume='volume=' in ev, faces=len(face_lines(sl)) == 6, show='(node 2' in sh)
    dump('cc.surf.txt', su)
    dump('cs.eval.txt', ev)
    dump('cs.faces.txt', sl)
    dump('cs.show.txt', sh)
    record('surf.cowl', all(checks.values()),
           artifacts=('cc.bcd', 'cs.bcd', 'cc.surf.txt', 'cs.eval.txt', 'cs.faces.txt',
                      'cs.show.txt', 'cs.stp', 'cs.bin'), **checks)


def surf_duct():
    out, _ = fresh('cd.bcd', LOFT(8.0, (0, 0, 10, 5), (1, 1, 9, 4)), THICK(1, 1.0, 2))
    ev, _ = cli('cd.bcd', 'eval')
    chk, _ = cli('cd.bcd', 'check', '2')
    fl, _ = cli('cd.bcd', 'faces', '2')
    sh, _ = cli('cd.bcd', 'show')
    cli('cd.bcd', 'archive', '2', f'{WORK}/cd.bin')
    lines = [ln for ln in chk.splitlines() if ln]
    checks = dict(committed='committed' in out, volume='volume=' in ev,
                  faces=faces_n(ev, 2) == 16,
                  check=bool(lines) and all(ln.startswith('face-check-unsupported') or
                                            ln.startswith('face-face-uncertain') for ln in lines),
                  show='(node 2' in sh)
    dump('cd.eval.txt', ev)
    dump('cd.check.txt', chk)
    dump('cd.faces.txt', fl)
    dump('cd.show.txt', sh)
    record('surf.duct', all(checks.values()),
           artifacts=('cd.bcd', 'cd.eval.txt', 'cd.check.txt', 'cd.faces.txt', 'cd.show.txt',
                      'cd.bin'), **checks)


def blade_stack():
    secs = [NACA(4, 4, 12, 100, 17, i=i + 1) for i in range(5)]
    out, _ = fresh('cb3.bcd', *secs, BLADE((1, 2, 3, 4, 5), 200, 20, 75, 6))
    ev, _ = cli('cb3.bcd', 'eval')
    rp, _ = cli('cb3.bcd', 'blade', '6')
    secs2 = [NACA(0, 0, 12, 100, 17, i=i + 1) for i in range(2)]
    out2, _ = fresh('cp.bcd', *secs2, BLADE((1, 2), 50, 0, 100, 3))
    ev2, _ = cli('cp.bcd', 'eval')
    sh, _ = cli('cp.bcd', 'show')
    cli('cp.bcd', 'step', '3', f'{WORK}/cp.stp')
    cli('cp.bcd', 'archive', '3', f'{WORK}/cp.bin')
    checks = dict(committed='committed' in out and 'committed' in out2,
                  header=blade_header(rp) == ('6', '5', '200', '20', '75'),
                  sched=blade_sched(rp) == [0.0, 5.0, 10.0, 15.0, 20.0],
                  volume='volume=' in ev and 'volume=' in ev2, show='(node 3' in sh)
    dump('cb3.eval.txt', ev)
    dump('cb3.blade.txt', rp)
    dump('cp.eval.txt', ev2)
    dump('cp.show.txt', sh)
    record('blade.stack', all(checks.values()),
           artifacts=('cb3.bcd', 'cp.bcd', 'cb3.eval.txt', 'cb3.blade.txt', 'cp.eval.txt',
                      'cp.show.txt', 'cp.stp', 'cp.bin'), **checks)


JOURNEYS = [g3_gearbox, sheet_bracket, surf_cowl, surf_duct, blade_stack]


def first_diff(a, b):
    la, lb = a.splitlines(), b.splitlines()
    for i, (x, y) in enumerate(zip(la, lb)):
        if x != y:
            return i + 1, x[:200], y[:200]
    if len(la) != len(lb):
        i = min(len(la), len(lb))
        x = la[i] if i < len(la) else '<eof>'
        y = lb[i] if i < len(lb) else '<eof>'
        return i + 1, x[:200], y[:200]
    return None


def baseline_check():
    want = json.load(open(BASE)) if os.path.exists(BASE) else None
    if BLESS:
        if not all(r['ok'] for r in RESULTS):
            return dict(blessed=0, skipped='red-present')
        base = dict(version=VERSION, artifacts={})
        for r in RESULTS:
            for rel, h in r['artifacts'].items():
                base['artifacts'][rel] = h
                if not rel.endswith(HASHONLY):
                    dst = os.path.join(ART, rel)
                    os.makedirs(os.path.dirname(dst) or ART, exist_ok=True)
                    with open(os.path.join(WORK, rel), 'rb') as f, open(dst, 'wb') as g:
                        g.write(f.read())
        json.dump(base, open(BASE, 'w'), indent=1, sort_keys=True)
        return dict(blessed=len(base['artifacts']))
    if want is None or want.get('version') != VERSION:
        for r in RESULTS:
            r['ok'] = False
            r['checks'] = dict(r['checks'], baseline='missing-or-stale-run-with---bless')
        return dict(baseline='missing')
    drift = {}
    for r in RESULTS:
        for rel, h in r['artifacts'].items():
            if want['artifacts'].get(rel) != h:
                info = dict(got=h, want=want['artifacts'].get(rel))
                if not rel.endswith(HASHONLY):
                    ap = os.path.join(ART, rel)
                    if os.path.exists(ap):
                        d = first_diff(open(ap, encoding='utf-8', errors='replace').read(),
                                       open(os.path.join(WORK, rel), encoding='utf-8', errors='replace').read())
                        if d:
                            info['first_diff_line'] = d[0]
                            info['blessed_head'] = d[1]
                            info['got_head'] = d[2]
                drift[rel] = info
    for r in RESULTS:
        bad = [a for a in r['artifacts'] if a in drift]
        if bad:
            r['ok'] = False
            r['checks'] = dict(r['checks'], baseline_stable=False)
            r['drift'] = {a: drift[a] for a in bad}
        else:
            r['checks'] = dict(r['checks'], baseline_stable=True)
    return dict(drift=sorted(drift))


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    want = [a for a in sys.argv[1:] if not a.startswith('-')]
    for f in JOURNEYS:
        if want and not any(w in f.__name__ for w in want):
            continue
        t = time.time()
        try:
            f()
        except Exception as e:
            record(f.__name__.replace('_', '.', 1), False, error=f'{type(e).__name__}: {e}'[:300])
        RESULTS[-1]['seconds'] = round(time.time() - t, 1)
    base = baseline_check()
    rep = dict(baseline_version=VERSION, binary=BIN,
               binary_sha256=wsl('sha256sum', BIN)[0].split()[0],
               passed=sum(r['ok'] for r in RESULTS), total=len(RESULTS),
               baseline=base, results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} e2e journeys hold")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
