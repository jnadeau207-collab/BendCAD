import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'neg-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-neg-c12'

BOX = '(node 1 (box 10 10 10) (intent create any any any any))'
CASES = []
ORACLE_SPHERE = '/tmp/oracle_sphere.step'
ORACLE_TORUS = '/tmp/oracle_torus.step'


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    return wsl(BIN, f'{WORK}/{design}', *args)


def geom(*args):
    return wsl(BIN, 'geom', *args)


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


def node_failed(cmd, args, msg):
    fresh('n.bcd', BOX)
    before = read('n.bcd')
    out, _ = cli('n.bcd', cmd, *args)
    after = read('n.bcd')
    gone = all(not os.path.exists(f'{WORK}/{a}') for a in args if a.endswith(('.step', '.bca', '.stl', '.3mf')))
    ok = (msg in out and before == after and gone)
    return ok, out.strip()[:160]


def setup_box_step():
    fresh('s.bcd', BOX)
    o, _ = cli('s.bcd', 'step', '1', f'{WORK}/box.step')
    assert o.startswith('wrote '), o
    return open(f'{WORK}/box.step').read()


def setup_box_arc():
    fresh('a.bcd', BOX)
    o, _ = cli('a.bcd', 'archive', '1', f'{WORK}/box.bca', 'neg')
    assert o.startswith('wrote '), o
    return open(f'{WORK}/box.bca').read()


def imp_refused(name, text, why):
    p = f'{WORK}/{name}.step'
    open(p, 'w').write(text)
    out, _ = geom('step_import', p, f'{WORK}/{name}.bca')
    ok = (why in out and not os.path.exists(f'{WORK}/{name}.bca'))
    return ok, out.strip()[:200]


@case('step.node_failed')
def c_step_nf():
    return node_failed('step', ['99', f'{WORK}/x.step'], 'error: node failed; nothing exported')


@case('archive.node_failed')
def c_arc_nf():
    return node_failed('archive', ['99', f'{WORK}/x.bca'], 'error: node failed; nothing archived')


@case('stl.node_failed')
def c_stl_nf():
    return node_failed('stl', ['99', f'{WORK}/x.stl'], 'error: node failed; nothing exported')


@case('mf3.node_failed')
def c_mf3_nf():
    return node_failed('3mf', ['99', f'{WORK}/x.3mf'], 'error: node failed; nothing exported')


@case('stl.budget')
def c_stl_b():
    fresh('n.bcd', BOX)
    out, _ = cli('n.bcd', 'stl', '1', f'{WORK}/b.stl', '0', '', '', '1')
    ok = ('refused tess-budget-exceeded' in out and not os.path.exists(f'{WORK}/b.stl'))
    return ok, out.strip()[:200]


@case('mf3.budget')
def c_mf3_b():
    fresh('n.bcd', BOX)
    out, _ = cli('n.bcd', '3mf', '1', f'{WORK}/b.3mf', '0', '', '', '1')
    ok = ('refused tess-budget-exceeded' in out and not os.path.exists(f'{WORK}/b.3mf'))
    return ok, out.strip()[:200]


@case('import.garbage')
def c_imp_g():
    return imp_refused('garbage', 'not a step file\n', 'step-no-solid')


@case('import.badent')
def c_imp_e():
    return imp_refused('badent', 'ISO-10303-21;\nHEADER;\nENDSEC;\nDATA;\n#1 = \nENDSEC;\nEND-ISO-10303-21;\n',
                       'step-entity-parse-failed')


@case('import.cone')
def c_imp_c():
    txt = setup_box_step().replace('PLANE(', 'CONICAL_SURFACE(', 1)
    return imp_refused('cone', txt, 'step-conical-surface-not-in-profile')


@case('import.open')
def c_imp_o():
    txt = setup_box_step().replace('CLOSED_SHELL', 'OPEN_SHELL')
    return imp_refused('open', txt, 'step-open-shell-not-in-profile')


@case('import.inch')
def c_imp_u():
    txt = setup_box_step().replace('SI_UNIT(.MILLI.,.METRE.)', 'SI_UNIT($,.METRE.)')
    return imp_refused('inch', txt, 'step-units-not-supported')


@case('import.nosolid')
def c_imp_n():
    return imp_refused('nosolid', 'ISO-10303-21;\nHEADER;\nENDSEC;\nDATA;\nENDSEC;\nEND-ISO-10303-21;\n',
                       'step-no-solid')


@case('import.dupid')
def c_imp_d():
    txt = setup_box_step()
    first = next(l for l in txt.splitlines() if l.startswith('#'))
    return imp_refused('dupid', txt.replace('DATA;\n', 'DATA;\n' + first + '\n', 1), 'step-duplicate-id')


@case('import.vloop')
def c_imp_v():
    txt = setup_box_step().replace('EDGE_LOOP(', 'VERTEX_LOOP(', 1)
    return imp_refused('vloop', txt, 'step-vertex-loop-not-in-profile')


@case('import.voids')
def c_imp_w():
    txt = setup_box_step().replace('MANIFOLD_SOLID_BREP(', 'BREP_WITH_VOIDS(', 1)
    return imp_refused('voids', txt, 'step-voids-not-in-profile')


@case('import.sphere_vloop')
def c_imp_sv():
    out, _ = geom('step_import', ORACLE_SPHERE, f'{WORK}/sploop.bca')
    ok = ('step-vertex-loop-not-in-profile' in out and not os.path.exists(f'{WORK}/sploop.bca'))
    return ok, out.strip()[:200]


@case('import.torus_dust')
def c_imp_td():
    out, _ = geom('step_import', ORACLE_TORUS, f'{WORK}/tdust.bca')
    ok = ('import-validation-failed at brep stage embedding' in out
          and not os.path.exists(f'{WORK}/tdust.bca'))
    return ok, out.strip()[:200]


@case('reopen.garbage')
def c_re_g():
    p = f'{WORK}/rg.bca'
    open(p, 'w').write('hello\n')
    out, _ = geom('reopen', p)
    return 'archive-sections-count' in out, out.strip()[:160]


@case('reopen.badver')
def c_re_v():
    txt = setup_box_arc()
    p = f'{WORK}/rv.bca'
    open(p, 'w').write('BCAD0' + txt[5:])
    out, _ = geom('reopen', p)
    return 'archive-bad-version' in out, out.strip()[:160]


@case('reopen.badunits')
def c_re_u():
    txt = setup_box_arc()
    p = f'{WORK}/ru.bca'
    open(p, 'w').write(txt.replace('|mm|', '|inch|', 1))
    out, _ = geom('reopen', p)
    return 'archive-units-not-supported' in out, out.strip()[:160]


@case('step_of.garbage')
def c_so_g():
    p = f'{WORK}/so.bca'
    open(p, 'w').write('hello\n')
    out, _ = geom('step_of', p, f'{WORK}/so.step')
    ok = ('error invalid-input | step_of' in out and not os.path.exists(f'{WORK}/so.step'))
    return ok, out.strip()[:160]


@case('stl_of.garbage')
def c_lo_g():
    p = f'{WORK}/lo.bca'
    open(p, 'w').write('hello\n')
    out, _ = geom('stl_of', p, f'{WORK}/lo.stl')
    ok = ('error: node failed; nothing exported' in out and not os.path.exists(f'{WORK}/lo.stl'))
    return ok, out.strip()[:160]


@case('mf3_of.garbage')
def c_mo_g():
    p = f'{WORK}/mo.bca'
    open(p, 'w').write('hello\n')
    out, _ = geom('3mf_of', p, f'{WORK}/mo.3mf')
    ok = ('error: node failed; nothing exported' in out and not os.path.exists(f'{WORK}/mo.3mf'))
    return ok, out.strip()[:160]


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
