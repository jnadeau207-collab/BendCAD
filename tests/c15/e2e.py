import json
import math
import os
import re
import struct
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ap242

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'e2e-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-c15'
RESULTS = []

BOX = '(param W 10 9.9 10.1) (param H 20) (node 1 (box W H 30) (intent create 6 0 1 0))'
PAIR = BOX + ' (node 2 (box 4 4 4) (intent create 6 0 1 0)) (node 3 (move 2 24 0 0 0) (intent same 0 0 1 0))'
CYL = '(param R 5) (node 1 (cylinder R 10) (intent create 3 0 1 0))'
PMI_FULL = ('(pmi (node 1) (datum A n1.c0.top) (dim dW W) (dim dH H) '
            '(tol t1 flatness 0.02 n1.c0.bottom rfs) '
            '(tol t2 perpendicularity 0.05 n1.c0.wall.0.0 rfs A) '
            '(state cold 1) (state hot 1.002) (stack s1 dW dH))')


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def record(name, ok, **checks):
    RESULTS.append(dict(name=name, ok=bool(ok), checks=checks))
    print(('PASS ' if ok else 'FAIL ') + name, flush=True)


def num(tok):
    if tok.startswith('b:'):
        return struct.unpack('>d', struct.pack('>Q', int(tok[2:])))[0]
    return float(tok)


FLT = r'([0-9.eE+-]+|b:\d+)'


def iadd(a, b):
    return (math.nextafter(a[0] + b[0], -math.inf), math.nextafter(a[1] + b[1], math.inf))


def iscale(a, g):
    return (math.nextafter(a[0] * g, -math.inf), math.nextafter(a[1] * g, math.inf))


def check_ok():
    fresh('c.bcd', BOX)
    out, _ = cli('c.bcd', 'pmi', 'check', PMI_FULL)
    m = re.search(r'tol t2 perpendicularity conforms actual \[' + FLT + r', ' + FLT +
                  r'\] certified datum A', out)
    checks = dict(
        header='pmi node 1 items 8' in out,
        datum='datum A ok n1.c0.top plane' in out,
        dimw='dim dW nominal 10 zone [9.9, 10.1]' in out,
        dimh='dim dH nominal 20 zone [20, 20]' in out,
        flat='tol t1 flatness conforms actual 0 certified' in out,
        perp=bool(m) and num(m.group(2)) <= 1e-6,
        cold='state cold grow 1' in out,
        hot='state hot grow 1.002' in out,
        stack='stack s1 dims 2' in out,
        footer='pmi ok 8 items' in out)
    record('check.ok', all(checks.values()), **checks)


def check_parallelism():
    fresh('c.bcd', BOX)
    o1, _ = cli('c.bcd', 'pmi', 'check',
                '(pmi (node 1) (datum A n1.c0.top) '
                '(tol t3 parallelism 0.05 n1.c0.bottom rfs A))')
    o2, _ = cli('c.bcd', 'pmi', 'check',
                '(pmi (node 1) (datum A n1.c0.top) '
                '(tol t3 parallelism 0.05 n1.c0.wall.0.0 rfs A))')
    m1 = re.search(r'tol t3 parallelism conforms actual \[' + FLT + r', ' + FLT + r'\] certified', o1)
    m2 = re.search(r'tol t3 parallelism violates actual \[' + FLT + r', ' + FLT + r'\] certified', o2)
    checks = dict(conforms=bool(m1), violates=bool(m2) and num(m2.group(1)) > 1)
    record('check.parallelism', all(checks.values()), **checks)


def stack_basic():
    fresh('c.bcd', BOX)
    out, _ = cli('c.bcd', 'pmi', 'stack',
                 '(pmi (node 1) (dim dW W) (dim dH H) (state cold 1) (state hot 1.002) (stack s1 dW dH))')
    env = iadd(iadd((0.0, 0.0), (9.9, 10.1)), (20.0, 20.0))
    hot = iscale(env, 1.002)
    m = re.search(r'stack s1 nominal ' + FLT + r' envelope \[' + FLT + r', ' + FLT + r'\] certified', out)
    mh = re.search(r'state hot grow 1\.002 \[' + FLT + r', ' + FLT + r'\]', out)
    mc = re.search(r'state cold grow 1 \[' + FLT + r', ' + FLT + r'\]', out)
    checks = dict(
        header='pmi node 1 stacks 1 states 2' in out,
        nominal=bool(m) and num(m.group(1)) == 30.0,
        env=bool(m) and (num(m.group(2)), num(m.group(3))) == env,
        cold=bool(mc) and (num(mc.group(1)), num(mc.group(2))) == iscale(env, 1.0),
        hot=bool(mh) and (num(mh.group(1)), num(mh.group(2))) == hot)
    record('stack.basic', all(checks.values()), **checks)


def stack_default_state():
    fresh('c.bcd', BOX)
    out, _ = cli('c.bcd', 'pmi', 'stack', '(pmi (node 1) (dim dW W) (stack s1 dW))')
    env = iadd((0.0, 0.0), (9.9, 10.1))
    m = re.search(r'state nominal grow 1 \[' + FLT + r', ' + FLT + r'\]', out)
    checks = dict(nominal=bool(m) and (num(m.group(1)), num(m.group(2))) == iscale(env, 1.0))
    record('stack.default_state', all(checks.values()), **checks)


def toler_states():
    fresh('c.bcd', PAIR)
    ref, _ = cli('c.bcd', 'clearance', '1', '3')
    mc = re.search(r'clearance \[' + FLT + r', ' + FLT + r'\] estimated lo=certified samples=(\d+)x(\d+)', ref)
    out, _ = cli('c.bcd', 'pmi', 'toler', '(pmi (nodes 1 3) (state cold 1) (state hot 1.002))')
    m0 = re.search(r'state cold grow 1 clearance \[' + FLT + r', ' + FLT + r'\] estimated lo=certified samples=(\d+)x(\d+)', out)
    m1 = re.search(r'state hot grow 1\.002 clearance \[' + FLT + r', ' + FLT + r'\] estimated lo=certified samples=(\d+)x(\d+)', out)
    clo, chi = num(mc.group(1)), num(mc.group(2))
    checks = dict(
        header='toler nodes 1 3 states 2' in out,
        nominal='nominal relation:\nrelation disjoint status=certified' in out,
        rel_cold='state cold grow 1 relation relation disjoint status=certified' in out,
        rel_hot='state hot grow 1.002 relation relation disjoint status=certified' in out,
        cold=bool(m0) and num(m0.group(1)) == math.nextafter(clo, -math.inf)
        and num(m0.group(2)) == math.nextafter(chi, math.inf),
        hot=bool(m1) and num(m1.group(1)) == math.nextafter(clo * 1.002, -math.inf)
        and num(m1.group(2)) == math.nextafter(chi * 1.002, math.inf),
        samples=bool(m0) and (m0.group(3), m0.group(4)) == (mc.group(3), mc.group(4)))
    record('toler.states', all(checks.values()), **checks)


def toler_interf():
    fresh('c.bcd', PAIR)
    cli('c.bcd', 'apply', '(node 4 (move 2 8 0 0 0) (intent same 0 0 1 0))')
    out, _ = cli('c.bcd', 'pmi', 'toler', '(pmi (nodes 1 4) (state cold 1) (state hot 1.002))')
    me = re.search(r'envelope clearance \[' + FLT + r', ' + FLT + r'\] estimated widen=' + FLT, out)
    w = (10.1 - 9.9) + (20.0 - 20.0)
    rcold = re.search(r'state cold grow 1 relation (relation interference status=certified[^\n]*)', out)
    rhot = re.search(r'state hot grow 1\.002 relation (relation interference status=certified[^\n]*)', out)
    checks = dict(
        nominal='nominal relation:\nrelation interference status=certified' in out,
        invariant=bool(rcold) and bool(rhot) and rcold.group(1) == rhot.group(1),
        cold='state cold grow 1 clearance 0 status=certified state=interference' in out,
        hot='state hot grow 1.002 clearance 0 status=certified state=interference' in out,
        widen=bool(me) and num(me.group(3)) == w,
        env_rel='envelope relation interference status=estimated widen=' in out)
    record('toler.interf', all(checks.values()), **checks)


def toler_inside():
    fresh('c.bcd', PAIR)
    cli('c.bcd', 'apply', '(node 4 (move 2 1 1 1) (intent same 0 0 1 0))')
    ref, _ = cli('c.bcd', 'clearance', '1', '4')
    mc = re.search(r'clearance \[' + FLT + r', ' + FLT + r'\] estimated lo=certified samples=(\d+)x(\d+)', ref)
    out, _ = cli('c.bcd', 'pmi', 'toler', '(pmi (nodes 1 4) (state cold 1))')
    m0 = re.search(r'state cold grow 1 clearance \[' + FLT + r', ' + FLT + r'\] estimated lo=certified samples=(\d+)x(\d+)', out)
    clo, chi = num(mc.group(1)), num(mc.group(2))
    checks = dict(
        nominal='nominal relation:\nrelation inside b-in-a status=certified' in out,
        state='state cold grow 1 relation relation inside b-in-a status=certified' in out,
        clear=bool(m0) and num(m0.group(1)) == math.nextafter(clo, -math.inf)
        and num(m0.group(2)) == math.nextafter(chi, math.inf),
        env_rel='envelope relation inside status=estimated widen=' in out)
    record('toler.inside', all(checks.values()), **checks)


def toler_envelope():
    fresh('c.bcd', PAIR)
    ref, _ = cli('c.bcd', 'clearance', '1', '3')
    mc = re.search(r'clearance \[' + FLT + r', ' + FLT + r'\]', ref)
    out, _ = cli('c.bcd', 'pmi', 'toler', '(pmi (nodes 1 3) (state cold 1))')
    me = re.search(r'envelope clearance \[' + FLT + r', ' + FLT + r'\] estimated widen=' + FLT, out)
    clo, chi = num(mc.group(1)), num(mc.group(2))
    w = num(me.group(3)) if me else float('nan')
    checks = dict(
        lo=bool(me) and num(me.group(1)) == clo - w,
        hi=bool(me) and num(me.group(2)) == chi + w,
        rel='envelope relation disjoint status=estimated widen=' in out)
    record('toler.envelope', all(checks.values()), **checks)


def step42_export():
    fresh('c.bcd', BOX)
    pmi = ('(pmi (node 1) (datum A n1.c0.top) (dim dW W) '
           '(tol t1 flatness 0.02 n1.c0.bottom rfs) '
           '(tol t2 perpendicularity 0.05 n1.c0.wall.0.0 rfs A))')
    out, _ = cli('c.bcd', 'pmi', 'step42', f'{WORK}/p.stp', pmi)
    cli('c.bcd', 'step', '1', f'{WORK}/g.stp')
    got = ap242.read_pmi(f'{WORK}/p.stp')
    want = {'datums': {'A': 'n1.c0.top'}, 'dims': {'dW': (10.0, 9.9, 10.1)},
            'tols': {'t1': ('flatness', 0.02, 'n1.c0.bottom', []),
                     't2': ('perpendicularity', 0.05, 'n1.c0.wall.0.0', ['A'])}}
    g42 = ap242.geom_entities(f'{WORK}/p.stp')
    g12 = ap242.geom_entities(f'{WORK}/g.stp')
    checks = dict(
        msg='wrote' in out and 'ap242 PMI 19 entities' in out,
        identity={k: got[k] for k in ('datums', 'dims', 'tols')} == want,
        count=got['count'] == 19,
        geom=g42 == g12)
    record('step42.export', all(checks.values()), **checks)


def step42_violates_exports():
    fresh('c.bcd', BOX)
    pmi = ('(pmi (node 1) (datum A n1.c0.top) '
           '(tol t3 parallelism 0.05 n1.c0.wall.0.0 rfs A))')
    out, _ = cli('c.bcd', 'pmi', 'step42', f'{WORK}/v.stp', pmi)
    got = ap242.read_pmi(f'{WORK}/v.stp')
    checks = dict(
        msg='ap242 PMI 7 entities' in out,
        tol=got['tols'] == {'t3': ('parallelism', 0.05, 'n1.c0.wall.0.0', ['A'])})
    record('step42.violates_exports', all(checks.values()), **checks)


def edit_propagate():
    fresh('c.bcd', BOX)
    cli('c.bcd', 'apply', '(param W 10 9.8 10.2)')
    o1, _ = cli('c.bcd', 'pmi', 'check', '(pmi (node 1) (dim dW W))')
    o2, _ = cli('c.bcd', 'pmi', 'stack', '(pmi (node 1) (dim dW W) (stack s1 dW))')
    env = iadd((0.0, 0.0), (9.8, 10.2))
    m = re.search(r'envelope \[' + FLT + r', ' + FLT + r'\] certified', o2)
    checks = dict(zone='dim dW nominal 10 zone [9.8, 10.2]' in o1,
                  env=bool(m) and (num(m.group(1)), num(m.group(2))) == env)
    record('edit.propagate', all(checks.values()), **checks)


def faces_crosscheck():
    fresh('c.bcd', BOX)
    faces, _ = cli('c.bcd', 'faces', '1')
    names = [ln.split()[0] for ln in faces.strip().splitlines()]
    pmi = '(pmi (node 1) ' + ' '.join(f'(datum D{i} {n})' for i, n in enumerate(names)) + ')'
    out, _ = cli('c.bcd', 'pmi', 'check', pmi)
    checks = dict(count=f'pmi node 1 items {len(names)}' in out and f'pmi ok {len(names)} items' in out,
                  names=all(n in out for n in names))
    record('faces.crosscheck', all(checks.values()), **checks)


def mcp_parity():
    fresh('m.bcd', PAIR)
    srv = os.path.join(HERE, '..', '..', 'tools', 'mcp', 'bendcad-mcp.mjs')
    msgs = [dict(method='initialize', params=dict(protocolVersion='2024-11-05')),
            dict(method='tools/list'),
            dict(method='tools/call', params=dict(name='pmi',
                 arguments=dict(design=f'{WORK}/m.bcd', action='check', pmi=PMI_FULL))),
            dict(method='tools/call', params=dict(name='pmi',
                 arguments=dict(design=f'{WORK}/m.bcd', action='toler',
                                pmi='(pmi (nodes 1 3) (state cold 1))'))),
            dict(method='tools/call', params=dict(name='pmi',
                 arguments=dict(design=f'{WORK}/m.bcd', action='step42', pmi=PMI_FULL,
                                out=f'{WORK}/mcp.stp')))]
    text = ''.join(json.dumps(dict(jsonrpc='2.0', id=i + 1, **m)) + '\n' for i, m in enumerate(msgs))
    r = subprocess.run(['node', srv], input=text, capture_output=True, text=True, timeout=900,
                       env=dict(os.environ, BENDCAD_BIN=BIN))
    rs = {x['id']: x for x in map(json.loads, r.stdout.strip().splitlines())}
    body = lambda i: rs[i]['result']['content'][0]['text']
    names = [t['name'] for t in rs[2]['result']['tools']]
    c_c, _ = cli('m.bcd', 'pmi', 'check', PMI_FULL)
    c_t, _ = cli('m.bcd', 'pmi', 'toler', '(pmi (nodes 1 3) (state cold 1))')
    checks = dict(tool='pmi' in names,
                  check=body(3).strip() == c_c.strip(),
                  toler=body(4).strip() == c_t.strip(),
                  step42=os.path.exists(f'{WORK}/mcp.stp') and 'ap242 PMI' in body(5))
    record('mcp.parity', all(checks.values()), **checks)


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (check_ok, check_parallelism, stack_basic, stack_default_state,
              toler_states, toler_interf, toler_inside, toler_envelope, step42_export,
              step42_violates_exports, edit_propagate, faces_crosscheck, mcp_parity):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} journeys hold")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
