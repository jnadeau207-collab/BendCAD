import hashlib
import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, 'errors-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-err-c13'
RESULTS = []

IC = '(intent create any any any any)'
IA = '(intent add any any any any)'
BOX1 = '(node 1 (box 10 10 10) %s)' % IC
BOX2 = '(node 2 (box 5 5 5) %s)' % IC
PAD99 = '(node 2 (pad 99 top 5 (region (path 0 0 (line 1 0) (line 1 1) (line 0 1)))) %s)' % IA
CYL = '(node 1 (cylinder 5 10) %s)' % IC
ZPARAM = '(param X 5 1.5 5)'
ZNODES = ['(node 1 (box 20 20 5) (intent create 6 0 1 0))',
          '(node 2 (holes 1 (face 1 0 top) through (hole X 10 2)) (intent remove 1 2 1 1))']

GRAMMAR = re.compile(r'^error (\S+) \| (.*?)(?: @ (.*?))? \| why: (.*?) \| fix: (.*)$')


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    env = dict(os.environ, MSYS_NO_PATHCONV='1', BEND_NO_TELEMETRY='1')
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout, env=env)
    return r.stdout + r.stderr, time.time() - t, r.returncode


def cli(design, *args):
    return wsl(BIN, '%s/%s' % (WORK, design), *args)


def geom(*args):
    return wsl(BIN, 'geom', *args)


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def read(design):
    return wsl('cat', '%s/%s' % (WORK, design))[0]


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name,
          {k: v for k, v in info.items() if k not in ('detail', 'unparsed')})


def classify(ln):
    if ln.startswith('{"node"'):
        try:
            o = json.loads(ln)
        except Exception:
            return None
        return 'json' if isinstance(o, dict) and 'node' in o and 'ok' in o else None
    if GRAMMAR.match(ln):
        return 'grammar'
    if re.match(r'^refused \S+ \| ', ln):
        return 'refused'
    if ln.startswith('error unknown command '):
        return 'unknown-command'
    if ln.startswith('error: '):
        return 'legacy'
    if ln.startswith('rejected: '):
        return 'rejected'
    return 'info'


def diag_ok():
    t = 0.0
    fresh('e.bcd', BOX1, BOX2)
    d1, a, c1 = cli('e.bcd', 'diag')
    d2, b, c2 = cli('e.bcd', 'diag')
    t += a + b
    rows = [json.loads(ln) for ln in d1.strip().splitlines()]
    ok = [r for r in rows if r.get('ok') is True]
    record('diag.ok', c1 == 0 and c2 == 0 and d1 == d2 and len(rows) == 2 and len(ok) == 2
           and sorted(r['node'] for r in rows) == [1, 2], secs=round(t, 3),
           design_sha256=sha('%s/e.bcd' % WORK),
           sha256=hashlib.sha256(d1.encode()).hexdigest())


def write_failing():
    body = read('e.bcd')
    show = '(bendcad 1)\n%s\n%s\n' % (BOX1, PAD99)
    assert body.startswith('(bendcad 1)')
    open('%s/f.bcd' % WORK, 'w', newline='\n').write(show)
    return show


def diag_fail():
    t = 0.0
    show = write_failing()
    d, a, c1 = cli('f.bcd', 'diag')
    e, b, c2 = cli('f.bcd', 'eval')
    t += a + b
    rows = [json.loads(ln) for ln in d.strip().splitlines()]
    bad = [r for r in rows if r.get('ok') is False]
    m = re.search(r'node 2: error (\S+) \| (.*?) @ (.*?) \| why: (.*?) \| fix: (.*)', e)
    agree = (m is not None and len(bad) == 1 and bad[0]['node'] == 2
             and bad[0]['kind'] == m.group(1) and bad[0]['what'] == m.group(2)
             and bad[0]['loc'] == m.group(3) and bad[0]['why'] == m.group(4)
             and bad[0]['fix'] == m.group(5))
    record('diag.fail', c1 == 0 and c2 == 0 and len(rows) == 2 and agree
           and bad[0]['code'] == 1 and bad[0]['why'] == 'input-node-missing-or-failed',
           secs=round(t, 3), sha256=hashlib.sha256(d.encode()).hexdigest())


def diag_empty():
    cli('n.bcd', 'new')
    d, t, c = cli('n.bcd', 'diag')
    record('diag.empty', c == 0 and d.strip() == '', secs=round(t, 3))


def cap_under():
    t = 0.0
    fresh('u.bcd', BOX1)
    e1, a, c1 = cli('u.bcd', 'eval')
    e2, b, c2 = cli('u.bcd', '--max-nodes', '1', 'eval')
    d1, c, c3 = cli('u.bcd', 'diag')
    d2, d, c4 = cli('u.bcd', '--max-nodes', '1', 'diag')
    t += a + b + c + d
    record('cap.under', c1 == 0 and c2 == 0 and c3 == 0 and c4 == 0 and e1 == e2 and d1 == d2
           and 'node 1: ok' in e1, secs=round(t, 3))


def cap_huge():
    t = 0.0
    fresh('h.bcd', BOX1)
    e1, a, c1 = cli('h.bcd', 'eval')
    e2, b, c2 = cli('h.bcd', '--max-nodes', '18446744073709551615', 'eval')
    t += a + b
    record('cap.huge', c1 == 0 and c2 == 0 and e1 == e2 and 'node 1: ok' in e2, secs=round(t, 3))


def cap_over():
    t = 0.0
    fresh('o.bcd', BOX1)
    p = '%s/o.bcd' % WORK
    want_eval = ('error resource-exhausted | eval @ %s | why: node-budget-exceeded '
                 '| fix: raise --max-nodes N or split the design' % p)
    e, a, c1 = cli('o.bcd', '--max-nodes', '0', 'eval')
    m, b, c2 = cli('o.bcd', '--max-nodes', '0', 'measure', '1')
    d, c, c3 = cli('o.bcd', '--max-nodes', '0', 'diag')
    g, dd, c4 = cli('o.bcd', '--max-nodes', '0', 'tess', '1', '%s/o.obj' % WORK)
    ls, _, _ = wsl('ls', '%s/o.obj' % WORK)
    t += a + b + c + dd
    jo = json.loads(d.strip())
    record('cap.over', c1 == 0 and c2 == 0 and c3 == 0 and c4 == 0 and e.strip() == want_eval
           and m.strip() == want_eval.replace('| eval @', '| measure @')
           and jo == dict(node=0, ok=False, code=6, kind='resource-exhausted', what='diag',
                          loc=p, why='node-budget-exceeded',
                          fix='raise --max-nodes N or split the design')
           and 'node-budget-exceeded' in g and 'no such file' in ls.lower(), secs=round(t, 3))


def cap_atomic():
    fresh('a.bcd', BOX1)
    before = read('a.bcd')
    out, t, c = cli('a.bcd', '--max-nodes', '0', 'apply', '(param W 3 1 5)')
    after = read('a.bcd')
    ev, _, _ = cli('a.bcd', 'eval')
    record('cap.atomic', c == 0 and 'node-budget-exceeded' in out and before == after
           and 'node 1: ok' in ev, secs=round(t, 3))


def cancel():
    t = 0.0
    fresh('x.bcd', BOX1)
    p = '%s/x.bcd' % WORK
    want = ('error cancelled | eval @ %s | why: request-cancelled | fix: reissue the request' % p)
    e, a, c1 = cli('x.bcd', '--cancelled', 'eval')
    d, b, c2 = cli('x.bcd', '--cancelled', 'diag')
    before = read('x.bcd')
    ap, c, c3 = cli('x.bcd', '--cancelled', '--max-nodes', '0', 'apply', '(param W 3 1 5)')
    after = read('x.bcd')
    t += a + b + c
    jo = json.loads(d.strip())
    record('cancel', c1 == 0 and c2 == 0 and c3 == 0 and e.strip() == want
           and jo['code'] == 5 and jo['kind'] == 'cancelled' and jo['why'] == 'request-cancelled'
           and 'request-cancelled' in ap and before == after, secs=round(t, 3))


def flags():
    t = 0.0
    fresh('s.bcd', BOX1)
    p = '%s/s.bcd' % WORK
    u, a, c1 = cli('s.bcd', '--bogus', 'eval')
    v, b, c2 = cli('s.bcd', '--max-nodes', 'abc', 'eval')
    w, c, c3 = cli('s.bcd', '--max-nodes')
    e1, d, c4 = cli('s.bcd', 'eval')
    e2, e, c5 = cli('s.bcd', 'eval', '--max-nodes', '0')
    n, f, c6 = cli('s.bcd')
    t += a + b + c + d + e + f
    record('flags', all(c == 0 for c in (c1, c2, c3, c4, c5, c6))
           and u.strip() == ('error invalid-input | args @ %s | why: unknown-flag --bogus '
                             '| fix: use [--max-nodes N] [--cancelled] before the verb' % p)
           and 'why: bad-max-nodes abc |' in v and 'why: bad-max-nodes |' in w
           and e1 == e2 and 'node 1: ok' in e2 and n.strip().startswith('error unknown command '),
           secs=round(t, 3))


def mcp_call(calls, env_extra=None):
    srv = os.path.join(ROOT, 'tools', 'mcp', 'bendcad-mcp.mjs')
    msgs = [dict(jsonrpc='2.0', id=1, method='initialize', params=dict(protocolVersion='2024-11-05'))]
    for i, (tool, args) in enumerate(calls):
        msgs.append(dict(jsonrpc='2.0', id=i + 2, method='tools/call',
                         params=dict(name=tool, arguments=args)))
    text = ''.join(json.dumps(m) + '\n' for m in msgs)
    env = dict(os.environ, BENDCAD_BIN=BIN)
    if env_extra:
        env.update(env_extra)
    r = subprocess.run(['node', srv], input=text, capture_output=True, text=True, timeout=900, env=env)
    rs = {}
    for ln in r.stdout.strip().splitlines():
        o = json.loads(ln)
        if 'id' in o and o['id'] is not None:
            rs[o['id']] = o
    return rs


def mcp_structured():
    t = time.time()
    fresh('m.bcd', BOX1)
    write_failing()
    rs = mcp_call([('measure', dict(design='%s/m.bcd' % WORK, node=99)),
                   ('evaluate', dict(design='%s/f.bcd' % WORK)),
                   ('diagnose', dict(design='%s/f.bcd' % WORK)),
                   ('evaluate', dict(design='%s/m.bcd' % WORK)),
                   ('flat_pattern', dict(design='%s/m.bcd' % WORK, node=1, klo=0.3, khi=0.5))])
    body = lambda i: rs[i]['result']['content'][0]['text']
    err = lambda i: bool(rs[i]['result'].get('isError'))
    dgs = lambda i: rs[i]['result'].get('diagnostics')
    d1, d2, d3, d4, d5 = dgs(2), dgs(3), dgs(4), dgs(5), dgs(6)
    jl = [json.loads(ln) for ln in body(4).strip().splitlines()]
    record('mcp.structured', err(2) and err(3) and err(4) and not err(5) and err(6)
           and isinstance(d1, list) and d1 and d1[0]['kind'] == 'invalid-input'
           and d1[0]['why'] == 'missing-input-node' and d1[0]['code'] == 1
           and isinstance(d2, list) and d2 and d2[0]['why'] == 'input-node-missing-or-failed'
           and d2[0]['code'] == 1 and d2[0]['node'] == 2 and isinstance(d3, list) and d3
           and d3[0]['why'] == 'input-node-missing-or-failed' and d4 == []
           and isinstance(d5, list) and d5 and d5[0]['why'] == 'flat-needs-sheet'
           and d5[0]['code'] == 1 and d5[0]['loc'] is None
           and len(jl) == 2 and sum(1 for r in jl if r.get('ok') is False) == 1,
           secs=round(time.time() - t, 3))


def mcp_cancel():
    t = time.time()
    fresh('k.bcd', BOX1)
    rs = mcp_call([('evaluate', dict(design='%s/k.bcd' % WORK))],
                  dict(BENDCAD_TIMEOUT_MS='1'))
    body = rs[2]['result']['content'][0]['text']
    dg = rs[2]['result'].get('diagnostics')
    record('mcp.cancel', bool(rs[2]['result'].get('isError'))
           and 'error cancelled | mcp-timeout @ bendcad-mcp | why: cli-exceeded-timeout' in body
           and isinstance(dg, list) and dg and dg[0]['why'] == 'cli-exceeded-timeout'
           and dg[0]['code'] == 5, secs=round(time.time() - t, 3))


def mcp_cap():
    t = time.time()
    fresh('q.bcd', BOX1)
    rs = mcp_call([('evaluate', dict(design='%s/q.bcd' % WORK))], dict(BENDCAD_MAX_NODES='0'))
    body = rs[2]['result']['content'][0]['text']
    dg = rs[2]['result'].get('diagnostics')
    rs2 = mcp_call([('evaluate', dict(design='%s/q.bcd' % WORK))], dict(BENDCAD_MAX_NODES='abc'))
    body2 = rs2[2]['result']['content'][0]['text']
    record('mcp.cap', bool(rs[2]['result'].get('isError')) and 'node-budget-exceeded' in body
           and isinstance(dg, list) and dg and dg[0]['code'] == 6
           and bool(rs2[2]['result'].get('isError')) and 'bad-max-nodes abc' in body2,
           secs=round(time.time() - t, 3))


def sweep():
    t = 0.0
    fresh('s.bcd', BOX1)
    fresh('c.bcd', CYL)
    write_failing()
    fresh('z.bcd', ZPARAM, *ZNODES)
    items = [('measure.99', 's.bcd', ['measure', '99'], 'missing-input-node'),
             ('faces.99', 's.bcd', ['faces', '99'], 'node failed'),
             ('classify.99', 's.bcd', ['classify', '99', '1', '2', '3'], 'nothing classified'),
             ('check.99', 's.bcd', ['check', '99'], 'nothing checked'),
             ('dist.99', 's.bcd', ['dist', '99', '1', '2', '3'], 'nothing measured'),
             ('extrema.99', 's.bcd', ['extrema', '99'], 'nothing measured'),
             ('mass.99', 's.bcd', ['mass', '99'], 'nothing measured'),
             ('section.99', 's.bcd', ['section', '99', '0', '0', '1', '5'], 'nothing sectioned'),
             ('interf.99a', 's.bcd', ['interf', '99', '1'], 'nothing compared'),
             ('interf.99b', 's.bcd', ['interf', '1', '99'], 'nothing compared'),
             ('clearance.99', 's.bcd', ['clearance', '1', '99'], 'nothing measured'),
             ('wall.99', 's.bcd', ['wall', '99'], 'nothing measured'),
             ('step.99', 's.bcd', ['step', '99', '%s/sw.step' % WORK], 'nothing exported'),
             ('archive.99', 's.bcd', ['archive', '99', '%s/sw.bca' % WORK], 'nothing archived'),
             ('stl.99', 's.bcd', ['stl', '99', '%s/sw.stl' % WORK], 'nothing exported'),
             ('threemf.99', 's.bcd', ['3mf', '99', '%s/sw.3mf' % WORK], 'nothing exported'),
             ('tess.99', 's.bcd', ['tess', '99', '%s/sw.obj' % WORK], 'nothing tessellated'),
             ('apply.garbage', 's.bcd', ['apply', 'garbage'], 'edits must be (param'),
             ('tess.budget', 'c.bcd', ['tess', '1', '%s/cb.obj' % WORK, '1', '1', '0.2', '10'],
              'tess-budget-exceeded'),
             ('tess.preset9', 's.bcd', ['tess', '1', '%s/sp.obj' % WORK, '9'], 'preset 9 needs 0..3'),
             ('unknown.cmd', 's.bcd', ['frobnicate'], 'error unknown command frobnicate'),
             ('flag.unknown', 's.bcd', ['--bogus', 'eval'], 'unknown-flag --bogus'),
             ('flag.badval', 's.bcd', ['--max-nodes', 'abc', 'eval'], 'bad-max-nodes abc'),
             ('flag.missing', 's.bcd', ['--max-nodes'], 'why: bad-max-nodes |'),
             ('diag.fail', 'f.bcd', ['diag'], '"ok":false'),
             ('eval.fail', 'f.bcd', ['eval'], 'input-node-missing-or-failed'),
             ('zone.neg', 'z.bcd', ['zone', '2'], 'topology-not-certified-over-zone'),
             ('flat.box', 's.bcd', ['flat', '1', '0.3', '0.5'], 'flat-needs-sheet'),
             ('surf.box', 's.bcd', ['surf', '1'], 'surf-needs-open-shell'),
             ('blade.box', 's.bcd', ['blade', '1'], 'blade-needs-blade'),
             ('sens.unknown', 's.bcd', ['sens', 'P', '1'], 'unknown parameter P'),
             ('asm.verb', 's.bcd', ['asm', 'frobnicate', '(assembly (inst a 1 0 0 0 0))'], 'unknown verb'),
             ('asm.parse', 's.bcd', ['asm', 'solve', '(assembly'], 'assembly-parse-failed'),
             ('pmi.verb', 's.bcd', ['pmi', 'frobnicate', '(pmi (node 1))'], 'unknown verb'),
             ('pmi.parse', 's.bcd', ['pmi', 'check', '(pmi (node 1) (datum A)'], 'pmi-parse-failed')]
    bad_code, unparsed, missing = [], [], []
    for label, design, args, msg in items:
        out, dt, code = cli(design, *args)
        t += dt
        if code != 0:
            bad_code.append(label)
        if msg not in out:
            missing.append(label)
        for ln in out.splitlines():
            s = ln.strip()
            nm = re.match(r'^node \d+: (error.*|rejected.*)$', s)
            if nm:
                s = nm.group(1)
            watched = s.startswith('{') or s.startswith(('error', 'refused', 'rejected'))
            if s == '' or not watched:
                continue
            if classify(s) in (None, 'info'):
                unparsed.append('%s: %s' % (label, s[:120]))
    record('sweep', not bad_code and not unparsed and not missing, items=len(items),
           secs=round(t, 3), unparsed=unparsed[:8], bad_code=bad_code, missing=missing)


def observed():
    out, t, code = wsl(BIN, '%s/nope.bcd' % WORK, 'eval')
    go, u, gcode = geom('reopen', '%s/nope.bca' % WORK)
    record('observed.missing_file', True, eval_code=code, eval_bytes=len(out),
           eval_sha256=hashlib.sha256(out.encode()).hexdigest(), reopen_code=gcode,
           reopen_bytes=len(go), reopen_sha256=hashlib.sha256(go.encode()).hexdigest(),
           eval_head=out.strip()[:200], reopen_head=go.strip()[:200], secs=round(t + u, 3))


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (diag_ok, diag_fail, diag_empty, cap_under, cap_huge, cap_over, cap_atomic, cancel, flags,
              mcp_structured, mcp_cancel, mcp_cap, sweep, observed):
        f()
    fails = [r['name'] for r in RESULTS if not r['ok']]
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=len(RESULTS) - len(fails),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print('%d/%d journeys hold' % (rep['passed'], rep['total']))
    if fails:
        print('FAILED:', fails)
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
