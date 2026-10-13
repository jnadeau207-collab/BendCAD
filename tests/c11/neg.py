import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'neg-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-neg-c11'

BOX = '(node 1 (box 10 10 10) (intent create any any any any))'
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


def refused(cmd, args, why):
    fresh('n.bcd', BOX)
    before = read('n.bcd')
    out, _ = cli('n.bcd', cmd, *args)
    after = read('n.bcd')
    m = re.search(r'error invalid-input \| ' + cmd + r' \| why: ([^|]+)\| fix: (.*)', out)
    ok = (m is not None and m.group(1).strip() == why and len(m.group(2).strip()) > 0
          and before == after)
    return ok, (m.group(1).strip() if m else None, 'same' if before == after else 'CHANGED')


def node_failed(cmd, args, msg):
    fresh('n.bcd', BOX)
    before = read('n.bcd')
    out, _ = cli('n.bcd', cmd, *args)
    after = read('n.bcd')
    ok = (msg in out and before == after)
    return ok, out.strip()[:120]


@case('dist.nan')
def c_dn():
    return refused('dist', ['1', 'nan', '0', '0'], 'the point needs three finite numbers')


@case('dist.garbage')
def c_dg():
    return refused('dist', ['1', 'abc', '0', '0'], 'the point needs three finite numbers')


@case('dist.missing')
def c_dm():
    return refused('dist', ['1'], 'the point needs three finite numbers')


@case('dist.node_failed')
def c_dnf():
    return node_failed('dist', ['99', '1', '2', '3'], 'error: node failed; nothing measured')


@case('extrema.node_failed')
def c_enf():
    return node_failed('extrema', ['99'], 'error: node failed; nothing measured')


@case('mass.depth_7')
def c_md7():
    return refused('mass', ['1', '7'], 'depth needs 0..6')


@case('mass.depth_garbage')
def c_mdg():
    return refused('mass', ['1', 'xyz'], 'depth needs 0..6')


@case('mass.depth_neg')
def c_mdn():
    return refused('mass', ['1', '-1'], 'depth needs 0..6')


@case('mass.node_failed')
def c_mnf():
    return node_failed('mass', ['99'], 'error: node failed; nothing measured')


@case('section.degenerate')
def c_sd():
    return refused('section', ['1', '0', '0', '0', '5'],
                   'the plane needs four finite numbers with a nonzero normal')


@case('section.nan')
def c_sn():
    return refused('section', ['1', 'nan', '0', '0', '1'],
                   'the plane needs four finite numbers with a nonzero normal')


@case('section.node_failed')
def c_snf():
    return node_failed('section', ['99', '0', '0', '1', '5'], 'error: node failed; nothing sectioned')


@case('interf.node_a')
def c_ia():
    return node_failed('interf', ['99', '1'], 'error: node failed; nothing compared')


@case('interf.node_b')
def c_ib():
    return node_failed('interf', ['1', '99'], 'error: node failed; nothing compared')


@case('clearance.node_failed')
def c_cnf():
    return node_failed('clearance', ['1', '99'], 'error: node failed; nothing measured')


@case('wall.node_failed')
def c_wnf():
    return node_failed('wall', ['99'], 'error: node failed; nothing measured')


@case('classify.nan')
def c_cln():
    return refused('classify', ['1', 'nan', '0', '0'], 'the point needs three finite numbers')


@case('classify.node_failed')
def c_clnf():
    return node_failed('classify', ['99', '1', '2', '3'], 'error: node failed; nothing classified')


@case('check.node_failed')
def c_chnf():
    return node_failed('check', ['99'], 'error: node failed; nothing checked')


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    sha = wsl('sha256sum', BIN)[0].split()[0]
    results = []
    for name, fn in CASES:
        t = time.time()
        try:
            ok, info = fn()
        except Exception as e:
            ok, info = False, f'{type(e).__name__}: {e}'
        results.append(dict(name=name, ok=bool(ok), info=str(info)[:300], seconds=round(time.time() - t, 2)))
        print(('PASS ' if ok else 'FAIL ') + name, str(info)[:160])
    rep = dict(binary_sha256=sha, passed=sum(r['ok'] for r in results), total=len(results), results=results)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} passed")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
