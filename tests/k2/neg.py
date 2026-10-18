import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import e2e as E

OUT = os.path.join(HERE, 'neg-report.json')
CASES = []


def case(name):
    def deco(f):
        CASES.append((name, f))
        return f
    return deco


def refused(out, why):
    return why in out and 'committed' not in out


def cyl_face(design, node, prefix=''):
    fs, _ = E.cli(design, 'faces', str(node))
    return next((ln.split()[0] for ln in fs.splitlines() if ' cylinder' in ln and ln.startswith(prefix)), None)


def plate():
    E.fresh('n.bcd', *E.plate_holes(), f'(node 4 (cylinder 4 30) {E.IC})')
    return cyl_face('n.bcd', 3, 'n2.'), cyl_face('n.bcd', 4)


@case('material.bad_density')
def c1():
    out, _ = E.fresh('n.bcd', f'(node 1 (box 1 1 1) {E.IC})', '(material 1 X 0 1e-5)')
    return refused(out, 'bad-material'), out[-200:]


@case('material.bad_cte')
def c2():
    out, _ = E.fresh('n.bcd', f'(node 1 (box 1 1 1) {E.IC})', '(material 1 X 1000 nan)')
    return refused(out, 'bad-material'), out[-200:]


@case('material.unknown_node')
def c3():
    out, _ = E.fresh('n.bcd', f'(node 1 (box 1 1 1) {E.IC})', '(material 9 X 1000 1e-5)')
    return refused(out, 'unknown-node 9'), out[-200:]


@case('thread.unknown_designation')
def c4():
    h, _ = plate()
    out, _ = E.cli('n.bcd', 'apply', f'(thread 3 t {h} M7x0.3 6H 8 20)')
    return refused(out, 'unknown-thread M7x0.3'), out[-200:]


@case('thread.unknown_class')
def c5():
    h, _ = plate()
    out, _ = E.cli('n.bcd', 'apply', f'(thread 3 t {h} M8 9Z 8 20)')
    return refused(out, 'unknown-thread-class 9Z'), out[-200:]


@case('thread.face_missing')
def c6():
    plate()
    out, _ = E.cli('n.bcd', 'apply', '(thread 3 t n9.c0.wall.0.0 M8 6H 8 20)')
    return refused(out, 'face-not-found'), out[-200:]


@case('thread.face_not_cylindrical')
def c7():
    plate()
    out, _ = E.cli('n.bcd', 'apply', '(thread 3 t n1.c0.top M8 6H 8 20)')
    return refused(out, 'thread-face-not-cylindrical'), out[-200:]


@case('thread.span_outside_face')
def c8():
    h, _ = plate()
    out, _ = E.cli('n.bcd', 'apply', f'(thread 3 t {h} M8 6H 2 20)')
    return refused(out, 'thread-span-outside-face'), out[-200:]


@case('thread.external_major_mismatch')
def c9():
    _, s = plate()
    out, _ = E.cli('n.bcd', 'apply', f'(thread 4 t {s} M10 6g 0 20)')
    return refused(out, 'thread-major-diameter-mismatch'), out[-200:]


@case('engage.designation_mismatch')
def c10():
    h, s = plate()
    h6 = cyl_face('n.bcd', 3, 'n3.')
    E.cli('n.bcd', 'apply', f'(thread 3 tap6 {h6} M6 6H 10 20)', f'(thread 4 ext {s} M8x1.25 6g 0 20)')
    f = '(assembly (inst P 3 0 0 0 0) (inst S 4 30 15 8 0) (fix 1 P) (fix 2 S))'
    out, _ = E.cli('n.bcd', 'asm', 'engage', 'S', 'ext', 'P', 'tap6', f)
    return 'thread-designation-mismatch' in out, out[-200:]


@case('engage.not_coaxial')
def c11():
    h, s = plate()
    E.cli('n.bcd', 'apply', f'(thread 3 tap8 {h} M8x1.25 6H 8 20)', f'(thread 4 ext {s} M8x1.25 6g 0 20)')
    f = '(assembly (inst P 3 0 0 0 0) (inst S 4 11 15 8 0) (fix 1 P) (fix 2 S))'
    out, _ = E.cli('n.bcd', 'asm', 'engage', 'S', 'ext', 'P', 'tap8', f)
    return 'threads-not-coaxial' in out, out[-200:]


@case('fit.size_outside_table')
def c12():
    E.fresh('n.bcd', f'(node 1 (box 2000 2000 20) {E.IC})',
            f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 1000 1000 600))) {E.ID})',
            f'(node 3 (cylinder 600 30) {E.IC})')
    f = f'(pmi (node 2) (fit big 2 {cyl_face("n.bcd", 2)} 3 {cyl_face("n.bcd", 3)} H7/g6 clearance))'
    out, _ = E.cli('n.bcd', 'pmi', 'fits', f)
    return 'fit-size-outside-table' in out, out[-200:]


@case('fit.nominal_mismatch')
def c13():
    E.fresh('n.bcd', f'(node 1 (box 40 40 20) {E.IC})',
            f'(node 2 (pocket 1 (face 1 0 top) through (region (circle 20 20 10))) {E.ID})',
            f'(node 3 (cylinder 8 30) {E.IC})')
    f = f'(pmi (node 2) (fit off 2 {cyl_face("n.bcd", 2)} 3 {cyl_face("n.bcd", 3)} H7/g6 clearance))'
    out, _ = E.cli('n.bcd', 'pmi', 'fits', f)
    return 'fit-nominal-mismatch' in out, out[-200:]


@case('fit.face_not_cylindrical')
def c14():
    E.fresh('n.bcd', f'(node 1 (box 40 40 20) {E.IC})', f'(node 3 (cylinder 8 30) {E.IC})')
    f = f'(pmi (node 1) (fit flat 1 n1.c0.top 3 {cyl_face("n.bcd", 3)} H7/g6 clearance))'
    out, _ = E.cli('n.bcd', 'pmi', 'fits', f)
    return 'fit-face-not-cylindrical' in out, out[-200:]


@case('gap.axes_not_parallel')
def c15():
    E.fresh('n.bcd', f'(node 1 (cylinder 5 10) {E.IC})', f'(node 2 (cylinder 5 10) {E.IC})')
    f = '(assembly (inst A 1 0 0 0 0) (inst B 2 30 0 0 1) (fix 1 A) (fix 2 B))'
    out, _ = E.cli('n.bcd', 'asm', 'gap', 'A', 'B', f)
    return 'gap-axes-not-parallel' in out, out[-200:]


@case('gap.interference')
def c16():
    E.fresh('n.bcd', f'(node 1 (cylinder 5 10) {E.IC})', f'(node 2 (cylinder 5 10) {E.IC})')
    f = '(assembly (inst A 1 0 0 0 0) (inst B 2 9 0 0 0) (fix 1 A) (fix 2 B))'
    out, _ = E.cli('n.bcd', 'asm', 'gap', 'A', 'B', f)
    return 'verdict=interference' in out and 'status=certified' in out, out[-200:]


def main():
    E.wsl('rm', '-rf', E.WORK)
    E.wsl('mkdir', '-p', E.WORK)
    rows = []
    for name, fn in CASES:
        try:
            ok, info = fn()
        except Exception as e:
            ok, info = False, repr(e)
        rows.append(dict(name=name, ok=bool(ok), info=info))
        print(('PASS ' if ok else 'FAIL ') + name, '' if ok else info)
    json.dump(rows, open(OUT, 'w'), indent=1)
    n = sum(1 for r in rows if r['ok'])
    print(f'{n}/{len(rows)} refusals hold')
    sys.exit(0 if n == len(rows) else 1)


if __name__ == '__main__':
    main()
