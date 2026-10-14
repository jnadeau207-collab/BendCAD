import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-c14'
OUT = os.path.join(HERE, 'e2e-report.json')
RESULTS = []

IC = '(intent create any any any any)'
BOX10 = f'(node 1 (box 10 10 10) {IC})'
BOX4 = f'(node 2 (box 4 4 4) {IC})'
ASM1 = '(assembly (inst a 1 0 0 0 0) (inst b 2 0 0 0 0) (fix 1 a) (coinc 2 a 14 5 5 b 0 2 2))'


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    out, dt = wsl(BIN, f'{WORK}/{design}', *args)
    return out, dt


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if k != 'detail'})


def t_of(s, name):
    m = re.search(r'inst %s node \d+ t=(\S+) (\S+) (\S+) q=\d+' % name, s)
    return tuple(float(m.group(i)) for i in (1, 2, 3)) if m else None


def num_of(s, key):
    m = re.search(r'%s (\S+)' % key, s)
    return float(m.group(1)) if m else None


def close(a, b, tol=1e-6):
    return a is not None and all(abs(x - y) <= tol for x, y in zip(a, b))


def solve_basic():
    fresh('s.bcd', BOX10, BOX4)
    o, dt = cli('s.bcd', 'asm', 'solve', ASM1)
    ta, tb = t_of(o, 'a'), t_of(o, 'b')
    dof = num_of(o, 'dof')
    res = num_of(o, 'max-residual')
    ok = (o.startswith('asm solved') and dof == 0 and close(ta, (0, 0, 0))
          and close(tb, (14, 3, 3)) and res is not None and res < 1e-6
          and 'redundant []' in o and 'lineage asm(a=n1,b=n2) mates[1,2]' in o)
    record('solve.basic', ok, ta=ta, tb=tb, dof=dof, res=res, seconds=round(dt, 2), detail=o)


def solve_chain_large():
    fresh('ch.bcd', BOX10)
    insts = ' '.join(f'(inst i{k} 1 {20 * k} 0 0 0)' for k in range(3, 7))
    fixes = ' '.join(f'(fix {k + 1} i{k})' for k in range(3, 7))
    asm = ('(assembly (inst a 1 0 0 0 0) (inst b 1 20 0 0 0) (inst c 1 40 0 0 0) ' + insts +
           ' (fix 1 a) (coinc 2 a 10 0 0 b 0 0 0) (coinc 3 b 10 0 0 c 0 0 0) ' + fixes + ')')
    o, dt = cli('ch.bcd', 'asm', 'solve', asm)
    ta, tb, tc = t_of(o, 'a'), t_of(o, 'b'), t_of(o, 'c')
    dof, res = num_of(o, 'dof'), num_of(o, 'max-residual')
    ok = (o.startswith('asm solved') and dof == 0 and close(ta, (0, 0, 0)) and close(tb, (10, 0, 0))
          and close(tc, (20, 0, 0)) and close(t_of(o, 'i6'), (120, 0, 0)) and res is not None and res < 1e-6)
    record('solve.chain_large', ok, ninst=7, ta=ta, tb=tb, tc=tc, dof=dof, res=res, seconds=round(dt, 2), detail=o)


def solve_under():
    fresh('u.bcd', BOX10)
    asm = '(assembly (inst a 1 1 2 3 0))'
    o, dt = cli('u.bcd', 'asm', 'solve', asm)
    ta, dof = t_of(o, 'a'), num_of(o, 'dof')
    ok = (o.startswith('asm underconstrained') and dof == 3 and close(ta, (1, 2, 3))
          and 'redundant []' in o and 'lineage asm(a=n1) mates[]' in o)
    record('solve.under', ok, ta=ta, dof=dof, seconds=round(dt, 2), detail=o)


def solve_redundant():
    fresh('r.bcd', BOX10)
    asm = '(assembly (inst a 1 1 2 3 0) (fix 1 a) (fix 2 a))'
    o, dt = cli('r.bcd', 'asm', 'solve', asm)
    m = re.search(r'redundant \[([\d,]*)\]', o)
    ids = sorted(int(x) for x in m.group(1).split(',') if x) if m else None
    ta, dof = t_of(o, 'a'), num_of(o, 'dof')
    ok = (o.startswith('asm solved') and dof == 0 and close(ta, (1, 2, 3))
          and ids is not None and len(ids) > 0 and set(ids) <= {1, 2})
    record('solve.redundant', ok, ta=ta, dof=dof, red=ids, seconds=round(dt, 2), detail=o)


def solve_conflict():
    fresh('c.bcd', BOX10)
    asm = ('(assembly (inst a 1 0 0 0 0) (plane 1 a 0 0 0 0 0 1 0) '
           '(plane 2 a 0 0 0 0 0 1 10))')
    o, dt = cli('c.bcd', 'asm', 'solve', asm)
    m = re.search(r'viol \[([\d,]*)\]', o)
    ids = sorted(int(x) for x in m.group(1).split(',') if x) if m else None
    res = num_of(o, 'max-residual')
    placed = [x for x in o.splitlines() if x.startswith('inst ')]
    ok = (o.startswith('asm conflict') and ids == [1, 2] and res is not None
          and 4.0 < res < 6.0 and placed == []
          and 'fix: loosen or correct the violating mates' in o)
    record('solve.conflict', ok, viol=ids, res=res, seconds=round(dt, 2), detail=o)


def solve_plane_axis():
    fresh('p.bcd', BOX10)
    asm = ('(assembly (inst a 1 0 0 0 0) (plane 1 a 0 0 0 0 0 1 9) '
           '(axis 2 a 0 0 0 5 6 9 0 0 1))')
    o, dt = cli('p.bcd', 'asm', 'solve', asm)
    ta, dof = t_of(o, 'a'), num_of(o, 'dof')
    res = num_of(o, 'max-residual')
    ok = (o.startswith('asm solved') and dof == 0 and close(ta, (5, 6, 9))
          and res is not None and res < 1e-6)
    record('solve.plane_axis', ok, ta=ta, dof=dof, res=res, seconds=round(dt, 2), detail=o)


def interf_disjoint():
    fresh('d.bcd', BOX10, BOX4)
    o, dt = cli('d.bcd', 'asm', 'interf', ASM1)
    ok = ('assembly pairs ninst 2' in o and 'pair a b' in o
          and 'relation disjoint status=certified' in o)
    record('interf.disjoint', ok, seconds=round(dt, 2), detail=o)


def interf_overlap():
    fresh('v.bcd', BOX10, BOX4)
    asm = '(assembly (inst a 1 0 0 0 0) (inst b 2 0 0 0 0) (fix 1 a) (coinc 2 a 8 8 8 b 0 0 0))'
    o, dt = cli('v.bcd', 'asm', 'interf', asm)
    ok = ('pair a b' in o and 'relation interference status=certified' in o)
    record('interf.overlap', ok, seconds=round(dt, 2), detail=o)


def interf_touch():
    fresh('t.bcd', BOX10, BOX4)
    asm = '(assembly (inst a 1 0 0 0 0) (inst b 2 0 0 0 0) (fix 1 a) (coinc 2 a 10 0 0 b 0 0 0))'
    o, dt = cli('t.bcd', 'asm', 'interf', asm)
    honest = ('relation disjoint status=certified' in o
              or 'relation uncertain status=estimated' in o)
    ok = ('pair a b' in o and honest and 'relation interference' not in o)
    record('interf.touch', ok, seconds=round(dt, 2), detail=o)


def clear_certified():
    fresh('l.bcd', BOX10, BOX4)
    o, dt = cli('l.bcd', 'asm', 'clear', ASM1)
    m = re.search(r'clearance \[(\S+), (\S+)\]', o)
    lo, hi = (float(m.group(1)), float(m.group(2))) if m else (None, None)
    ok = (lo is not None and abs(lo - 4.0) < 1e-6 and hi >= 4.0 - 1e-9
          and 'lo=certified' in o)
    record('clear.certified', ok, lo=lo, hi=hi, expect=4.0, seconds=round(dt, 2), detail=o)


def clear_interference():
    fresh('i.bcd', BOX10, BOX4)
    asm = '(assembly (inst a 1 0 0 0 0) (inst b 2 0 0 0 0) (fix 1 a) (coinc 2 a 8 8 8 b 0 0 0))'
    o, dt = cli('i.bcd', 'asm', 'clear', asm)
    ok = 'clearance 0 status=certified state=interference' in o
    record('clear.interference', ok, seconds=round(dt, 2), detail=o)


def explode_basic():
    fresh('e.bcd', BOX10, BOX4)
    o, dt = cli('e.bcd', 'asm', 'explode', '0', '0', '1', '5', ASM1)
    ta, tb = t_of(o, 'a'), t_of(o, 'b')
    ok = (o.startswith('asm exploded ninst 2 dir=0 0 1 gap=5')
          and close(ta, (0, 0, 0)) and close(tb, (14, 3, 8)))
    record('explode.basic', ok, ta=ta, tb=tb, seconds=round(dt, 2), detail=o)


def faces_box():
    fresh('f.bcd', BOX10, BOX4)
    o, dt = cli('f.bcd', 'asm', 'faces', 'b', ASM1)
    lines = [x for x in o.splitlines() if x.startswith('b.n2.')]
    kinds = [x.split()[-2] if len(x.split()) >= 3 else '' for x in lines]
    loops = [x.split('loops=')[-1] if 'loops=' in x else '' for x in lines]
    ok = (len(lines) == 6 and all(k == 'plane' for k in kinds) and all(x == '1' for x in loops))
    record('faces.box', ok, n=len(lines), kinds=kinds, loops=loops, seconds=round(dt, 2), detail=o)


def faces_hole():
    fresh('h.bcd', BOX10,
          '(node 2 (box 4 4 4) (intent create any any any any))',
          '(node 3 (holes 2 (face 2 0 top) through (hole 2 2 1)) (intent remove 1 2 1 1))')
    asm = '(assembly (inst a 1 0 0 0 0) (inst c 3 0 0 0 0) (fix 1 a) (fix 2 c))'
    o, dt = cli('h.bcd', 'asm', 'faces', 'c', asm)
    lines = [x for x in o.splitlines() if x.startswith('c.n')]
    kinds = sorted(x.split()[-2] for x in lines if len(x.split()) >= 3)
    cyl = [x for x in lines if ' cylinder ' in x]
    top = [x for x in lines if x.startswith('c.n2.c0.top ')]
    ok = (len(lines) == 7 and kinds.count('plane') == 6 and kinds.count('cylinder') == 1
          and all(x.startswith('c.n2.') for x in lines if ' plane ' in x)
          and len(cyl) == 1 and cyl[0].startswith('c.n3.')
          and len(top) == 1 and top[0].endswith('loops=2'))
    record('faces.hole', ok, n=len(lines), kinds=kinds, seconds=round(dt, 2), detail=o)


def edit_propagate():
    fresh('g.bcd', BOX10, BOX4)
    o1, _ = cli('g.bcd', 'asm', 'interf', ASM1)
    s1, _ = cli('g.bcd', 'asm', 'solve', ASM1)
    cli('g.bcd', 'apply', '(node 1 (box 16 16 16) (intent create any any any any))')
    o2, dt = cli('g.bcd', 'asm', 'interf', ASM1)
    s2, _ = cli('g.bcd', 'asm', 'solve', ASM1)
    tb1, tb2 = t_of(s1, 'b'), t_of(s2, 'b')
    ok = ('relation disjoint status=certified' in o1
          and 'relation interference status=certified' in o2
          and close(tb1, (14, 3, 3)) and close(tb2, (14, 3, 3)))
    record('edit.propagate', ok, tb1=tb1, tb2=tb2, seconds=round(dt, 2),
           detail='BEFORE:\n' + o1 + '\nAFTER:\n' + o2)


def mcp_parity():
    fresh('m.bcd', BOX10, BOX4)
    srv = os.path.join(HERE, '..', '..', 'tools', 'mcp', 'bendcad-mcp.mjs')
    msgs = [dict(method='initialize', params=dict(protocolVersion='2024-11-05')),
            dict(method='tools/list'),
            dict(method='tools/call', params=dict(name='assembly',
                 arguments=dict(design=f'{WORK}/m.bcd', action='solve', assembly=ASM1))),
            dict(method='tools/call', params=dict(name='assembly',
                 arguments=dict(design=f'{WORK}/m.bcd', action='interf', assembly=ASM1))),
            dict(method='tools/call', params=dict(name='assembly',
                 arguments=dict(design=f'{WORK}/m.bcd', action='explode', assembly=ASM1,
                                dx=0, dy=0, dz=1, gap=5))),
            dict(method='tools/call', params=dict(name='assembly',
                 arguments=dict(design=f'{WORK}/m.bcd', action='faces', assembly=ASM1, inst='b')))]
    text = ''.join(json.dumps(dict(jsonrpc='2.0', id=i + 1, **m)) + '\n' for i, m in enumerate(msgs))
    r = subprocess.run(['node', srv], input=text, capture_output=True, text=True, timeout=900,
                       env=dict(os.environ, BENDCAD_BIN=BIN))
    rs = {x['id']: x for x in map(json.loads, r.stdout.strip().splitlines())}
    body = lambda i: rs[i]['result']['content'][0]['text']
    names = [t['name'] for t in rs[2]['result']['tools']]
    have = 'assembly' in names
    c_so, _ = cli('m.bcd', 'asm', 'solve', ASM1)
    c_in, _ = cli('m.bcd', 'asm', 'interf', ASM1)
    c_ex, _ = cli('m.bcd', 'asm', 'explode', '0', '0', '1', '5', ASM1)
    c_fa, _ = cli('m.bcd', 'asm', 'faces', 'b', ASM1)
    same = (body(3).strip() == c_so.strip() and body(4).strip() == c_in.strip()
            and body(5).strip() == c_ex.strip() and body(6).strip() == c_fa.strip())
    ok = (have and same and all('isError' not in rs[i] or not rs[i].get('isError')
                                for i in range(3, 7)))
    record('mcp.parity', ok, tools=have, text_match=same)


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (solve_basic, solve_chain_large, solve_under, solve_redundant, solve_conflict, solve_plane_axis,
              interf_disjoint, interf_overlap, interf_touch, clear_certified,
              clear_interference, explode_basic, faces_box, faces_hole, edit_propagate,
              mcp_parity):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} passed")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
