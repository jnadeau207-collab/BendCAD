import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'neg-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-neg-c15'

BOX = '(param W 10 9.9 10.1) (param H 20) (node 1 (box W H 30) (intent create 6 0 1 0))'
CYL = '(param R 5) (node 1 (cylinder R 10) (intent create 3 0 1 0))'
CASES = []


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


def read(design):
    return wsl('cat', f'{WORK}/{design}')[0]


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def case(name):
    def wrap(fn):
        CASES.append((name, fn))
        return fn
    return wrap


def refused(msg, *args, design='n.bcd', edits=(BOX,)):
    fresh(design, *edits)
    before = read(design)
    out, _ = cli(design, 'pmi', *args)
    after = read(design)
    ok = (msg in out and before == after)
    return ok, out.strip()[:200]


@case('verb.unknown')
def c_verb():
    return refused('unknown verb', 'frobnicate', '(pmi (node 1))')


@case('parse.failed')
def c_parse():
    return refused('pmi-parse-failed', 'check', '(pmi (node 1) (datum A)')


@case('parse.entry')
def c_entry():
    return refused('unknown-pmi-entry', 'check', '(pmi (node 1) (frobnicate 1))')


@case('parse.needs_node')
def c_needs():
    return refused('pmi-needs-node', 'check', '(pmi (datum A n1.c0.top))')


@case('parse.singular')
def c_singular():
    return refused('give one (node N) entry', 'check', '(pmi (nodes 1 1))')


@case('parse.pair')
def c_pair():
    return refused('give one (nodes A B) entry', 'toler', '(pmi (node 1))')


@case('parse.duplicate')
def c_dup():
    return refused('duplicate-datum', 'check', '(pmi (node 1) (datum A n1.c0.top) (datum A n1.c0.top))')


@case('datum.malformed')
def c_datum():
    return refused('bad-datum', 'check', '(pmi (node 1) (datum A))')


@case('node.unknown')
def c_unode():
    return refused('unknown-node 9', 'check', '(pmi (node 9))')


@case('node.failed')
def c_node_fail():
    p = f'{WORK}/f.bcd'
    open(p, 'w').write('(bendcad 1)\n(param 1 W 10 9.9 10.1) (param 2 H 20 20 20) '
                       + '(node 1 (box W H 30) (intent create 6 0 1 0))\n'
                       + '(node 2 (box 1 1 1) (intent remove 1 2 1 1))\n')
    before = read('f.bcd')
    out, _ = cli('f.bcd', 'pmi', 'check', '(pmi (node 2))')
    after = read('f.bcd')
    ok = ('error: node 2; nothing evaluated' in out and before == after)
    return ok, out.strip()[:200]


@case('node.unknown_toler')
def c_utoler():
    return refused('unknown-node 9', 'toler', '(pmi (nodes 1 9))')


@case('node.failed_toler')
def c_toler_fail():
    p = f'{WORK}/ft.bcd'
    open(p, 'w').write('(bendcad 1)\n(param 1 W 10 9.9 10.1) (param 2 H 20 20 20) '
                       + '(node 1 (box W H 30) (intent create 6 0 1 0))\n'
                       + '(node 2 (box 1 1 1) (intent remove 1 2 1 1))\n')
    before = read('ft.bcd')
    out, _ = cli('ft.bcd', 'pmi', 'toler', '(pmi (nodes 1 2))')
    after = read('ft.bcd')
    ok = ('error: node 2; nothing compared' in out and before == after)
    return ok, out.strip()[:200]


@case('sel.unknown')
def c_sel():
    return refused('unknown-selector n9.c0.top', 'check', '(pmi (node 1) (datum A n9.c0.top))')


@case('dim.unknown_param')
def c_pparam():
    return refused('unknown-param Q', 'check', '(pmi (node 1) (dim d Q))')


@case('dim.bad')
def c_dim():
    return refused('bad-dim', 'check', '(pmi (node 1) (dim d 10 11 9))')


@case('dim.quoted_name')
def c_dimq():
    return refused('bad-dim', 'check', "(pmi (node 1) (dim d'W W))")


@case('dim.unknown')
def c_udim():
    return refused('unknown-dim dQ', 'stack', '(pmi (node 1) (dim d W) (stack s d dQ))')


@case('dim.stack_empty')
def c_sempty():
    return refused('stack-needs-dim', 'stack', '(pmi (node 1) (dim d W) (stack s))')


@case('tol.kind')
def c_kind():
    return refused('unsupported-tol-kind position', 'check',
                   '(pmi (node 1) (tol t position 0.05 n1.c0.top rfs))')


@case('tol.modifier')
def c_mod():
    return refused('unsupported-modifier mmc', 'check',
                   '(pmi (node 1) (tol t flatness 0.02 n1.c0.top mmc))')


@case('tol.bad')
def c_tol():
    return refused('bad-tol', 'check', '(pmi (node 1) (tol t flatness nope n1.c0.top rfs))')


@case('tol.datum_unknown')
def c_udatum():
    return refused('unknown-datum Z', 'check',
                   '(pmi (node 1) (datum A n1.c0.top) (tol t perpendicularity 0.05 n1.c0.wall.0.0 rfs Z))')


@case('tol.flat_takes_no_datum')
def c_flat_drf():
    return refused('tol-kind-takes-no-datum', 'check',
                   '(pmi (node 1) (datum A n1.c0.top) (tol t flatness 0.02 n1.c0.bottom rfs A))')


@case('tol.needs_one_datum')
def c_orient_drf():
    return refused('tol-needs-one-datum', 'check',
                   '(pmi (node 1) (tol t perpendicularity 0.05 n1.c0.wall.0.0 rfs))')


@case('tol.face_not_plane')
def c_face():
    return refused('tol-face-not-plane', 'check',
                   '(pmi (node 1) (tol t flatness 0.02 n1.c0.wall.0.0 rfs))', edits=(CYL,))


@case('tol.datum_not_plane')
def c_ddatum():
    return refused('tol-datum-not-plane', 'check',
                   '(pmi (node 1) (datum C n1.c0.wall.0.0) (tol t perpendicularity 0.05 n1.c0.top rfs C))',
                   edits=(CYL,))


@case('state.bad')
def c_state():
    return refused('bad-state', 'stack', '(pmi (node 1) (dim d W) (stack s d) (state hot 0))')


@case('step42.refusal_writes_nothing')
def c_step42():
    fresh('s.bcd', BOX)
    before = read('s.bcd')
    out, _ = cli('s.bcd', 'pmi', 'step42', f'{WORK}/no.stp', '(pmi (node 1) (datum A n9.c0.top))')
    after = read('s.bcd')
    ok = ('unknown-selector n9.c0.top' in out and before == after
          and not os.path.exists(f'{WORK}/no.stp'))
    return ok, out.strip()[:200]


@case('step42.needs_output')
def c_step42_out():
    fresh('s.bcd', BOX)
    before = read('s.bcd')
    out, _ = cli('s.bcd', 'pmi', 'step42', '', '(pmi (node 1))')
    after = read('s.bcd')
    ok = ('step42-needs-output' in out and before == after)
    return ok, out.strip()[:200]


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    rows = []
    for name, fn in CASES:
        t = time.time()
        try:
            ok, detail = fn()
        except Exception as e:
            ok, detail = False, f'{type(e).__name__}: {e}'[:200]
        rows.append(dict(name=name, ok=bool(ok), seconds=round(time.time() - t, 2), detail=detail))
        print(('PASS ' if ok else 'FAIL ') + name, flush=True)
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in rows),
               total=len(rows), results=rows)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} neg journeys hold")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
