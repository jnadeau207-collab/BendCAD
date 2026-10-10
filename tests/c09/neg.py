import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'neg-report.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-neg-c09'

BOX = '(node 1 (box 10 10 10) (intent create any any any any))'
CYL = '(node 1 (cylinder 5 10) (intent create any any any any))'
IC = '(intent create any any any any)'
IR = '(intent remove any any any any)'
IA = '(intent add any any any any)'


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


def node_err(out, n):
    m = re.search(rf'node {n}: error (\S+)( .*?)?why: ([^|]+)', out)
    return (m.group(1), m.group(3).strip()) if m else (None, None)


def rg(x0, y0, x1, y1):
    return f'(region (path {x0} {y0} (line {x1} {y0}) (line {x1} {y1}) (line {x0} {y1})))'


RECT = rg(2, 0, 4, 3)
SQ = rg(0, 0, 4, 4)

CASES = []


def case(name):
    def wrap(fn):
        CASES.append((name, fn))
        return fn
    return wrap


def reject(prefix, bad, n, kind, why):
    fresh('n.bcd', *prefix)
    before = read('n.bcd')
    out, _ = cli('n.bcd', 'apply', bad)
    after = read('n.bcd')
    k, w = node_err(out, n)
    return (k == kind and w == why and before == after, (k, w, before == after))


@case('sweep.angle')
def c_angle():
    return reject([], f'(node 1 (sweep (arc 45) {RECT}) {IC})', 1,
                  'unsupported-op', 'sweep-angle-not-certified')


@case('sweep.degenerate')
def c_sw0():
    return reject([], f'(node 1 (sweep (line 0) {RECT}) {IC})', 1,
                  'invalid-input', 'degenerate-feature')


@case('sweep.guide')
def c_guide():
    return reject([], f'(node 1 (sweep (line 5) {RECT} (guide (arc 90))) {IC})', 1,
                  'unsupported-op', 'guide-not-admitted')


@case('sweep.twist')
def c_twist():
    return reject([], f'(node 1 (sweep (line 5) {RECT} (twist 1)) {IC})', 1,
                  'unsupported-op', 'twist-not-admitted')


@case('loft.mismatch')
def c_mis():
    tri = '(region (path 0 0 (line 4 0) (line 2 3)))'
    return reject([], f'(node 1 (loft 5 {SQ} {tri}) {IC})', 1,
                  'invalid-input', 'loft-topology-mismatch')


@case('loft.g1')
def c_g1():
    return reject([], f'(node 1 (loft 5 {SQ} {SQ} (continuity g1)) {IC})', 1,
                  'unsupported-op', 'continuity-not-met')


@case('loft.nonplanar')
def c_np():
    return reject([], f'(node 1 (loft 5 {SQ} {SQ} (twist 1)) {IC})', 1,
                  'invalid-input', 'loft-face-not-planar')


@case('loft.self')
def c_self():
    return reject([], f'(node 1 (loft 5 {SQ} {SQ} (twist 2)) {IC})', 1,
                  'invalid-input', 'loft-self-intersection')


@case('chamfer.moved')
def c_ch_mv():
    return reject([BOX, '(node 2 (move 1 1 0 0 0) (intent same any any any any))'],
                  f'(node 3 (chamfer 2 1) {IR})', 3,
                  'unsupported-op', 'chamfer-base-not-admitted')


@case('chamfer.consumes')
def c_ch_eat():
    return reject([BOX], f'(node 2 (chamfer 1 5) {IR})', 2,
                  'invalid-input', 'chamfer-consumes-face')


@case('fillet.moved')
def c_fi_mv():
    return reject([BOX, '(node 2 (move 1 1 0 0 0) (intent same any any any any))'],
                  f'(node 3 (fillet 2 1) {IR})', 3,
                  'unsupported-op', 'fillet-base-not-admitted')


@case('fillet.consumes')
def c_fi_eat():
    return reject([BOX], f'(node 2 (fillet 1 5) {IR})', 2,
                  'invalid-input', 'fillet-consumes-face')


@case('fillet.zero')
def c_fi0():
    return reject([BOX], f'(node 2 (fillet 1 0) {IR})', 2,
                  'invalid-input', 'degenerate-feature')


@case('fillet.edge')
def c_edge():
    return reject([BOX], f'(node 2 (fillet 1 (edge 4) 1 1) {IR})', 2,
                  'unsupported-op', 'fillet-edge-not-admitted')


@case('fillet.cone')
def c_cone():
    # Pending owner amendment of intent S2: the R0!=R1 cone is honestly
    # refused (its tangent-point vertices cannot satisfy the exact cone
    # predicate; see receipt). Pin the refusal so it cannot rot into a
    # silent publish or a different diagnosis.
    return reject([BOX], f'(node 2 (fillet 1 (edge 0) 1 2) {IR})', 2,
                  'numerical-uncertainty', 'surface-not-representable')


@case('draft.consumes')
def c_dr():
    return reject(['(node 1 (box 10 8 6) (intent create any any any any))'],
                  f'(node 2 (draft 1 5) {IR})', 2,
                  'invalid-input', 'draft-consumes-face')


@case('draft.base')
def c_drb():
    return reject([CYL], f'(node 2 (draft 1 1) {IR})', 2,
                  'unsupported-op', 'draft-base-not-admitted')


@case('offset.self')
def c_off():
    return reject([BOX], f'(node 2 (offset 1 -6) {IA})', 2,
                  'invalid-input', 'offset-self-intersection')


@case('offset.base')
def c_offb():
    return reject(['(node 1 (sphere 5) (intent create any any any any))'],
                  f'(node 2 (offset 1 1) {IA})', 2,
                  'unsupported-op', 'offset-base-not-admitted')


@case('shell.consumes')
def c_sh():
    return reject([BOX], f'(node 2 (shell 1 5) {IR})', 2,
                  'invalid-input', 'shell-consumes-solid')


@case('shell.open_cyl')
def c_sho():
    return reject([CYL], f'(node 2 (shell 1 1 open) {IR})', 2,
                  'unsupported-op', 'shell-base-not-admitted')


@case('pattern.overlap')
def c_ov():
    return reject([BOX], f'(node 2 (pattern 1 (linear 2 10 1 0 1 0)) {IA})', 2,
                  'unsupported-op', 'pattern-copies-overlap')


@case('pattern.angle')
def c_ang():
    return reject([BOX], f'(node 2 (pattern 1 (circular 3 20)) {IA})', 2,
                  'unsupported-op', 'pattern-angle-not-certified')


@case('pattern.count')
def c_cnt():
    return reject([BOX], f'(node 2 (pattern 1 (linear 0 20 1 0 1 0)) {IA})', 2,
                  'unsupported-op', 'pattern-count-not-admitted')


@case('fillet.pad')
def c_pad():
    foot = rg(3, 3, 4, 4)
    return reject([BOX, f'(node 2 (fillet 1 1) {IR})'],
                  f'(node 3 (pad 2 (face 2 0 top) 1 {foot}) {IA})', 3,
                  'unsupported-op', 'features-need-an-extruded-body')


@case('rigid.kind')
def c_kind():
    law = open(os.path.join(HERE, '..', '..', 'laws', 'c09.bend'), encoding='utf-8').read()
    line = '{SV.rr_why(sd_rep(tancc())) == "kind-not-decomposed" : String}'
    return (line in law, 'kind-not-decomposed')


@case('rigid.budget')
def c_budget():
    src = open(os.path.join(HERE, '..', '..', 'src', 'c05', 'solve.bend'), encoding='utf-8').read()
    return ('R_whole{"rigid-budget"}' in src, 'rigid-budget')


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
