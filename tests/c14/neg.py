import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'neg-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-neg-c14'

IC = '(intent create any any any any)'
BOX = '(node 1 (box 10 10 10) (intent create any any any any))'
BOX4 = '(node 2 (box 4 4 4) (intent create any any any any))'
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


def refused(msg, *args, design='n.bcd', edits=(BOX, BOX4)):
    fresh(design, *edits)
    before = read(design)
    out, _ = cli(design, 'asm', *args)
    after = read(design)
    ok = (msg in out and before == after)
    return ok, out.strip()[:200]


@case('verb.unknown')
def c_verb():
    return refused('unknown verb', 'frobnicate', '(assembly (inst a 1 0 0 0 0))')


@case('parse.failed')
def c_parse():
    return refused('assembly-parse-failed', 'solve', '(assembly')


@case('parse.needs_instance')
def c_needs():
    return refused('assembly-needs-instance', 'solve', '(assembly)')


@case('inst.bad_q')
def c_badq():
    return refused('bad-instance', 'solve', '(assembly (inst a 1 0 0 0 9))')


@case('inst.duplicate')
def c_dup():
    return refused('duplicate-instance', 'solve',
                   '(assembly (inst a 1 0 0 0 0) (inst a 2 0 0 0 0))')


@case('entry.unknown')
def c_entry():
    return refused('unknown-assembly-entry', 'solve',
                   '(assembly (inst a 1 0 0 0 0) (bogus 1 2))')


@case('mate.bad_arity')
def c_arity():
    return refused('bad-mate', 'solve', '(assembly (inst a 1 0 0 0 0) (fix 1))')


@case('mate.unknown_inst')
def c_mate_unk():
    return refused('unknown-instance', 'solve',
                   '(assembly (inst a 1 0 0 0 0) (fix 1 zzz))')


@case('mate.coinc_self')
def c_self():
    return refused('bad-mate', 'solve',
                   '(assembly (inst a 1 0 0 0 0) (coinc 1 a 0 0 0 a 1 1 1))')


@case('mate.plane_zeron')
def c_zeron():
    return refused('bad-mate', 'solve',
                   '(assembly (inst a 1 0 0 0 0) (plane 1 a 0 0 0 0 0 0 5))')


@case('mate.axis_zerod')
def c_zerod():
    return refused('bad-mate', 'solve',
                   '(assembly (inst a 1 0 0 0 0) (axis 1 a 0 0 0 1 2 3 0 0 0))')


@case('node.unknown')
def c_node_unk():
    return refused('unknown-node b', 'solve',
                   '(assembly (inst a 1 0 0 0 0) (inst b 99 0 0 0 0) (fix 1 a))')


@case('node.failed')
def c_node_fail():
    p = f'{WORK}/f.bcd'
    open(p, 'w').write('(bendcad 1)\n' + BOX + '\n'
                       + '(node 2 (box 1 1 1) (intent remove 1 2 1 1))\n')
    before = read('f.bcd')
    out, _ = cli('f.bcd', 'asm', 'solve',
                 '(assembly (inst a 1 0 0 0 0) (inst b 2 0 0 0 0) (fix 1 a))')
    after = read('f.bcd')
    ok = ('error: node 2; nothing assembled' in out and before == after)
    return ok, out.strip()[:200]


@case('explode.zero_dir')
def c_explode_zero():
    return refused('need DX DY DZ GAP', 'explode', '0', '0', '0', '5',
                   '(assembly (inst a 1 0 0 0 0))')


@case('explode.nonnumeric')
def c_explode_nan():
    return refused('need DX DY DZ GAP', 'explode', 'a', 'b', 'c', 'd',
                   '(assembly (inst a 1 0 0 0 0))')


@case('faces.needy')
def c_faces_needy():
    return refused('need an instance name', 'faces')


@case('faces.unknown_inst')
def c_faces_unk():
    return refused('unknown-instance zzz', 'faces', 'zzz',
                   '(assembly (inst a 1 0 0 0 0) (inst b 2 0 0 0 0))')


@case('delete.propagate')
def c_delete():
    fresh('d.bcd', BOX, BOX4)
    cli('d.bcd', 'apply', '(delete 2)')
    before = read('d.bcd')
    out, _ = cli('d.bcd', 'asm', 'solve',
                 '(assembly (inst a 1 0 0 0 0) (inst b 2 0 0 0 0) (fix 1 a))')
    after = read('d.bcd')
    ok = ('unknown-node b' in out and before == after)
    return ok, out.strip()[:200]


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    results = []
    for name, fn in CASES:
        try:
            ok, info = fn()
        except Exception as e:
            ok, info = False, 'EXC %r' % e
        results.append(dict(name=name, ok=bool(ok), detail=str(info)[:300]))
        print(('PASS ' if ok else 'FAIL ') + name, str(info)[:160])
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0],
               passed=sum(r['ok'] for r in results), total=len(results), results=results)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} passed")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
