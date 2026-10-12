import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-c10'
OUT = os.path.join(HERE, 'e2e-report.json')
RESULTS = []

PRESETS = {0: (2.0, 0.4, 'display'), 1: (1.0, 0.2, 'display'),
           2: (0.25, 0.05, 'display'), 3: (0.05, 0.01, 'manufacturing')}


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    out, dt = wsl(BIN, f'{WORK}/{design}', *args)
    return out, dt


def read(design):
    return wsl('cat', f'{WORK}/{design}')[0]


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if k != 'detail'})


def wrote(out):
    m = re.search(r'wrote (\S+) nverts (\d+) ntris (\d+) est (\d+) chord (\S+) ang (\S+) '
                  r'nsamp (\d+) profile (\w+) \(sampled, not certified\)', out)
    if not m:
        return None
    g = m.groups()
    return dict(out=g[0], nverts=int(g[1]), ntris=int(g[2]), est=int(g[3]),
                chord=float(g[4]), ang=float(g[5]), nsamp=int(g[6]), profile=g[7])


def mesh(path):
    nv = 0
    nf = 0
    bad = 0
    edges = {}
    for ln in read(path).splitlines():
        if ln.startswith('v '):
            nv += 1
        elif ln.startswith('f '):
            ids = [int(x) for x in ln.split()[1:]]
            nf += 1
            if len(ids) != 3 or any(i < 1 or i > nv for i in ids):
                bad += 1
            for a, b in zip(ids, ids[1:] + ids[:1]):
                e = (a, b) if a < b else (b, a)
                edges[e] = edges.get(e, 0) + 1
    e1 = sum(1 for c in edges.values() if c == 1)
    e2 = sum(1 for c in edges.values() if c == 2)
    ex = sum(1 for c in edges.values() if c > 2)
    return dict(nv=nv, nf=nf, bad=bad, e1=e1, e2=e2, ex=ex, euler=nv - len(edges) + nf)


def bounds_ok(w, chord, ang, prof):
    return (w is not None and w['chord'] <= chord and w['ang'] <= ang
            and w['profile'] == prof and w['est'] >= w['ntris'])


IC = '(intent create any any any any)'
IR = '(intent remove any any any any)'


def box():
    out, dt = fresh('box.bcd', f'(node 1 (box 10 10 10) {IC})')
    t, _ = cli('box.bcd', 'tess', '1', f'{WORK}/box.obj')
    w = wrote(t)
    m = mesh('box.obj')
    record('tess.box', w is not None and (w['nverts'], w['ntris']) == (8, 12)
           and (m['nv'], m['nf'], m['bad'], m['e1'], m['ex']) == (8, 12, 0, 0, 0)
           and m['euler'] == 2 and bounds_ok(w, 1.0, 0.2, 'display'),
           line=t.strip()[:200], mesh=m, seconds=dt)


def cyl():
    out, dt = fresh('cyl.bcd', f'(node 1 (cylinder 5 10) {IC})')
    t, _ = cli('cyl.bcd', 'tess', '1', f'{WORK}/cyl.obj')
    w = wrote(t)
    m = mesh('cyl.obj')
    record('tess.cyl', w is not None and (w['nverts'], w['ntris']) == (64, 124)
           and m['bad'] == 0 and m['e1'] == 0 and m['ex'] == 0 and m['euler'] == 2
           and bounds_ok(w, 1.0, 0.2, 'display'),
           line=t.strip()[:200], mesh=m, seconds=dt)


def presets():
    fresh('pre.bcd', f'(node 1 (cylinder 5 10) {IC})')
    want = {0: (32, 60), 2: (252, 500), 3: (1258, 2512)}
    got = {}
    oks = []
    for p, (ev, ef) in want.items():
        t, _ = cli('pre.bcd', 'tess', '1', f'{WORK}/p{p}.obj', str(p))
        w = wrote(t)
        m = mesh(f'p{p}.obj')
        c, a, pr = PRESETS[p]
        ok = (w is not None and (w['nverts'], w['ntris']) == (ev, ef)
              and m['bad'] == 0 and m['e1'] == 0 and m['ex'] == 0 and m['euler'] == 2
              and bounds_ok(w, c, a, pr))
        oks.append(ok)
        got[p] = dict(ok=ok, line=t.strip()[:160])
    record('tess.presets', all(oks), detail=got)


def rev():
    rg = '(region (path 2 0 (line 4 0) (line 4 3) (line 2 3)))'
    out, dt = fresh('rev.bcd', f'(node 1 (revolve {rg}) {IC})')
    t, _ = cli('rev.bcd', 'tess', '1', f'{WORK}/rev.obj')
    w = wrote(t)
    m = mesh('rev.obj')
    record('tess.rev', w is not None and (w['nverts'], w['ntris']) == (128, 256)
           and m['bad'] == 0 and m['e1'] == 0 and m['ex'] == 0 and m['euler'] == 0
           and bounds_ok(w, 1.0, 0.2, 'display'),
           line=t.strip()[:200], mesh=m, seconds=dt)


def rev_fine():
    rg = '(region (path 2 0 (line 4 0) (line 4 3) (line 2 3)))'
    fresh('rev3.bcd', f'(node 1 (revolve {rg}) {IC})')
    t, dt = cli('rev3.bcd', 'tess', '1', f'{WORK}/rev3.obj', '3')
    w = wrote(t)
    m = mesh('rev3.obj')
    record('tess.rev_fine', w is not None and (w['nverts'], w['ntris']) == (2516, 5032)
           and m['bad'] == 0 and m['e1'] == 0 and m['ex'] == 0 and m['euler'] == 0
           and bounds_ok(w, 0.05, 0.01, 'manufacturing'),
           line=t.strip()[:200], mesh=m, seconds=dt)


def overrides():
    fresh('ov.bcd', f'(node 1 (cylinder 5 10) {IC})')
    t, _ = cli('ov.bcd', 'tess', '1', f'{WORK}/ov.obj', '1', '0.1')
    w = wrote(t)
    t2, _ = cli('ov.bcd', 'tess', '1', f'{WORK}/ov2.obj', '1', '1', '0.2', '1000000', 'manufacturing')
    w2 = wrote(t2)
    record('tess.overrides', w is not None and w['chord'] <= 0.1 and w['ntris'] > 124
           and w2 is not None and w2['profile'] == 'manufacturing'
           and (w2['nverts'], w2['ntris']) == (64, 124),
           chord=w and w['chord'], ntris=w and w['ntris'], prof2=w2 and w2['profile'])


def refusal():
    fresh('ref.bcd', f'(node 1 (cylinder 5 10) {IC})')
    before = read('ref.bcd')
    t, _ = cli('ref.bcd', 'tess', '1', f'{WORK}/ref.obj', '1', '1', '0.2', '10')
    after = read('ref.bcd')
    ls, _ = wsl('ls', f'{WORK}/ref.obj')
    m = re.search(r'refused tess-budget-exceeded \| tess @ node 1 \| est 196 max 10 \| fix: (.*)', t)
    record('tess.refusal', m is not None and 'coarsen quality' in m.group(1)
           and 'no such file' in ls.lower() and before == after,
           line=t.strip()[:200], design_same=before == after)


def replay():
    fresh('rep.bcd', f'(node 1 (cylinder 5 10) {IC})')
    cli('rep.bcd', 'tess', '1', f'{WORK}/rep1.obj', '2')
    cli('rep.bcd', 'tess', '1', f'{WORK}/rep2.obj', '2')
    a = read('rep1.obj')
    b = read('rep2.obj')
    record('tess.replay', a == b and len(a) > 1000, bytes=len(a))


def prism_slant():
    out, dt = fresh('tri.bcd',
                    f'(node 1 (prism 0 5 (region (path 0 0 (line 4 0) (line 2 3)))) {IC})')
    t, _ = cli('tri.bcd', 'tess', '1', f'{WORK}/tri.obj')
    w = wrote(t)
    m = mesh('tri.obj')
    record('tess.prism_slant', w is not None and (w['nverts'], w['ntris']) == (6, 8)
           and m['bad'] == 0 and m['e1'] == 0 and m['ex'] == 0 and m['euler'] == 2
           and bounds_ok(w, 1.0, 0.2, 'display'),
           line=t.strip()[:200], mesh=m, seconds=dt)


def prism_arc():
    out, dt = fresh('darc.bcd',
                    f'(node 1 (prism 0 5 (region (path 0 0 (line 4 0) (arc 2 0 2 0 0)))) {IC})')
    t, _ = cli('darc.bcd', 'tess', '1', f'{WORK}/darc.obj')
    w = wrote(t)
    m = mesh('darc.obj')
    record('tess.prism_arc', w is not None and (w['nverts'], w['ntris']) == (22, 40)
           and m['bad'] == 0 and m['e1'] == 0 and m['ex'] == 0 and m['euler'] == 2
           and bounds_ok(w, 1.0, 0.2, 'display'),
           line=t.strip()[:200], mesh=m, seconds=dt)


def shell_cavity():
    out, dt = fresh('sh.bcd',
                    f'(node 1 (box 10 10 10) {IC})',
                    f'(node 2 (shell 1 1) {IR})')
    t, _ = cli('sh.bcd', 'tess', '2', f'{WORK}/sh.obj')
    w = wrote(t)
    m = mesh('sh.obj')
    record('tess.shell_cavity', w is not None and w['est'] >= w['ntris']
           and m['bad'] == 0 and m['e1'] == 0 and m['ex'] == 0 and m['euler'] == 4
           and bounds_ok(w, 1.0, 0.2, 'display'),
           line=t.strip()[:200], mesh=m, seconds=dt)


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (box, cyl, presets, rev, rev_fine, overrides, refusal, replay, prism_slant, prism_arc,
              shell_cavity):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} passed")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
