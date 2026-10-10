import json
import math
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-c09'
OUT = os.path.join(HERE, 'e2e-report.json')
PI = math.pi
RESULTS = []


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


def contains(iv, x):
    return iv is not None and iv[0] <= x <= iv[1]


def vol(out, node):
    m = re.search(rf'node {node}: ok .*?volume=\[([^,]+), ([^\]]+)\]', out)
    return (float(m.group(1)), float(m.group(2))) if m else None


def vol_text(out, node):
    m = re.search(rf'node {node}: ok .*?(volume=\[[^\]]+\])', out)
    return m.group(1) if m else None


def fx(out, node):
    m = re.search(rf'node {node}: ok material=(\w+) faces_created=(\d+) faces_modified=(\d+) '
                  rf'solids=(\d+) through_holes=(\d+)', out)
    return m.groups() if m else None


def face_lines(text):
    return [ln for ln in text.strip().splitlines() if ln and not ln.startswith('deleted ')]


def kind_n(lines, kind):
    return sum(1 for ln in lines if len(ln.split()) >= 2 and ln.split()[1] == kind)


def rg(x0, y0, x1, y1):
    return (f'(region (path {x0} {y0} (line {x1} {y0}) (line {x1} {y1}) (line {x0} {y1})))')


IC = '(intent create any any any any)'
IA = '(intent add any any any any)'
IR = '(intent remove any any any any)'
IS = '(intent same any any any any)'


def sweep():
    rect = rg(0, 0, 4, 3)
    out, dt = fresh('sweep.bcd',
                    f'(node 1 (prism 0 5 {rect}) {IC})',
                    f'(node 2 (sweep (line 5) {rect}) {IC})',
                    f'(node 3 (sweep (line 5) {rect} (guide (line 0)) (twist 0)) {IC})')
    record('sweep.line_matches_prism',
           contains(vol(out, 1), 60.0) and vol(out, 1) == vol(out, 2) == vol(out, 3)
           and 'proof: guide: path' in out,
           prism=vol(out, 1), sweep=vol(out, 2), seconds=dt, budget='ok' if dt < 1 else 'miss')


def sweep_arc():
    rect = rg(2, 0, 4, 3)
    out, dt = fresh('arc.bcd',
                    f'(node 1 (sweep (arc 90) {rect}) {IC})',
                    f'(node 2 (sweep (arc 180) {rect}) {IC})',
                    f'(node 3 (sweep (arc 270) {rect}) {IC})',
                    f'(node 4 (sweep (arc 360) {rect}) {IC})',
                    f'(node 5 (revolve {rect}) {IC})')
    want = (9 * PI, 18 * PI, 27 * PI, 36 * PI)
    vols = [vol(out, n) for n in (1, 2, 3, 4)]
    record('sweep.arc_volumes', all(contains(v, w) for v, w in zip(vols, want)) and contains(vol(out, 5), 36 * PI),
           volumes=vols, revolve=vol(out, 5), seconds=dt, budget='ok' if dt < 1 else 'miss')
    fa, _ = cli('arc.bcd', 'faces', '4')
    fr, _ = cli('arc.bcd', 'faces', '5')
    record('sweep.arc360_faces_match_revolve', face_lines(fa) and len(face_lines(fa)) == len(face_lines(fr)),
           sweep=len(face_lines(fa)), revolve=len(face_lines(fr)))


def loft():
    out, dt = fresh('loft.bcd',
                    f'(node 1 (loft 5 {rg(-5, -5, 5, 5)} {rg(-3, -3, 3, 3)}) {IC})',
                    f'(node 2 (loft 6 {rg(0, 0, 10, 8)} {rg(2, 2, 8, 6)}) {IC})',
                    f'(node 3 (loft 3 {rg(0, 0, 4, 5)} {rg(0, 0, 4, 5)}) {IC})',
                    f'(node 4 (prism 0 3 {rg(0, 0, 4, 5)}) {IC})')
    record('loft.squares', contains(vol(out, 1), 980.0 / 3.0), volume=vol(out, 1), seconds=dt,
           budget='ok' if dt < 1 else 'miss')
    record('loft.prismatoid', contains(vol(out, 2), 296.0), volume=vol(out, 2))
    record('loft.identical_prism', contains(vol(out, 3), 60.0) and vol(out, 3) == vol(out, 4),
           loft=vol(out, 3), prism=vol(out, 4))


def chamfer():
    out, dt = fresh('cham.bcd',
                    f'(node 1 (box 10 10 10) {IC})',
                    f'(node 2 (chamfer 1 1) {IR})',
                    f'(node 3 (cylinder 5 10) {IC})',
                    f'(node 4 (chamfer 3 1) {IR})')
    faces, _ = cli('cham.bcd', 'faces', '2')
    fl = face_lines(faces)
    record('chamfer.box', contains(vol(out, 2), 980.0) and len(fl) == 10, volume=vol(out, 2), faces=len(fl),
           seconds=dt, budget='ok' if dt < 1 else 'miss')
    record('chamfer.cyl', contains(vol(out, 4), 722.0 * PI / 3.0), volume=vol(out, 4))


def fillet():
    # Node 8 (variable-radius cone) goes in its own apply: it is honestly
    # refused (surface-not-representable; see receipt), and bundling it here
    # would veto the atomic commit of nodes 1-7. Same journeys, same asserts.
    out, dt = fresh('fil.bcd',
                    f'(node 1 (box 10 10 10) {IC})',
                    f'(node 2 (fillet 1 1) {IR})',
                    f'(node 3 (cylinder 5 10) {IC})',
                    f'(node 4 (fillet 3 1) {IR})',
                    f'(node 5 (box 10 10 10) {IC})',
                    f'(node 6 (fillet 5 (edge 0) 1 1) {IR})',
                    f'(node 7 (box 10 10 10) {IC})')
    cone_out, _ = cli('fil.bcd', 'apply', f'(node 8 (fillet 7 (edge 0) 1 2) {IR})')
    faces, _ = cli('fil.bcd', 'faces', '2')
    fl = face_lines(faces)
    record('fillet.box',
           contains(vol(out, 2), 896.0 + 76.0 * PI / 3.0) and len(fl) == 26
           and kind_n(fl, 'sphere') == 8 and kind_n(fl, 'cylinder') == 12 and kind_n(fl, 'plane') == 6,
           volume=vol(out, 2), faces=len(fl), seconds=dt, budget='ok' if dt < 1 else 'miss')
    record('fillet.cyl', contains(vol(out, 4), 232.0 * PI + 4.0 * PI * PI), volume=vol(out, 4))
    e1, _ = cli('fil.bcd', 'faces', '6')
    e2, _ = cli('fil.bcd', 'faces', '8')
    record('fillet.edge_equal', contains(vol(out, 6), 990.0 + 2.5 * PI) and len(face_lines(e1)) == 7,
           volume=vol(out, 6), faces=len(face_lines(e1)))
    record('fillet.edge_cone',
           contains(vol(cone_out, 8), 1000.0 - 70.0 / 3.0 + 70.0 * PI / 12.0) and len(face_lines(e2)) == 7,
           volume=vol(cone_out, 8), faces=len(face_lines(e2)))


def fillet_edit():
    out, dt = fresh('filx.bcd', '(param X 10)',
                    f'(node 1 (box X 10 10) {IC})',
                    f'(node 2 (fillet 1 1) {IR})')
    edited, _ = cli('filx.bcd', 'apply', '(param X 12)')
    record('fillet.param_edit',
           contains(vol(out, 2), 896.0 + 76.0 * PI / 3.0)
           and contains(vol(edited, 2), 1088.0 + (82.0 / 3.0) * PI),
           before=vol(out, 2), after=vol(edited, 2), seconds=dt, budget='ok' if dt < 1 else 'miss')


def draft():
    out, dt = fresh('draft.bcd',
                    f'(node 1 (box 10 8 6) {IC})',
                    f'(node 2 (draft 1 1) {IR})',
                    f'(node 3 (draft 1 0) {IS})')
    faces, _ = cli('draft.bcd', 'faces', '2')
    record('draft.inset', contains(vol(out, 2), 380.0) and len(face_lines(faces)) == 6
           and fx(out, 2) is not None and fx(out, 2)[0] == 'remove',
           volume=vol(out, 2), faces=len(face_lines(faces)), seconds=dt, budget='ok' if dt < 1 else 'miss')
    record('draft.identity', contains(vol(out, 3), 480.0) and 'proof: draft-identity' in out
           and fx(out, 3) is not None and fx(out, 3)[0] == 'same',
           volume=vol(out, 3), fx=fx(out, 3))


def offset():
    out, dt = fresh('off.bcd',
                    f'(node 1 (box 10 10 10) {IC})',
                    f'(node 2 (offset 1 1) {IA})',
                    f'(node 3 (thicken 1 1) {IA})',
                    f'(node 4 (cylinder 5 10) {IC})',
                    f'(node 5 (offset 4 1) {IA})')
    record('offset.box', contains(vol(out, 2), 1728.0) and fx(out, 2) is not None and fx(out, 2)[0] == 'add',
           volume=vol(out, 2), seconds=dt, budget='ok' if dt < 1 else 'miss')
    record('thicken.matches_offset', vol(out, 2) == vol(out, 3) and contains(vol(out, 3), 1728.0),
           offset=vol(out, 2), thicken=vol(out, 3))
    record('offset.cyl', contains(vol(out, 5), 432.0 * PI), volume=vol(out, 5))


def shell():
    out, dt = fresh('shell.bcd',
                    f'(node 1 (box 10 10 10) {IC})',
                    f'(node 2 (shell 1 1) {IR})',
                    f'(node 3 (shell 1 1 open) {IR})',
                    f'(node 4 (cylinder 5 10) {IC})',
                    f'(node 5 (shell 4 1) {IR})')
    faces, _ = cli('shell.bcd', 'faces', '2')
    chk, _ = cli('shell.bcd', 'check', '2')
    fl = face_lines(faces)
    record('shell.closed_box', contains(vol(out, 2), 488.0) and any('.cav.' in ln for ln in fl)
           and chk.startswith('ok:'),
           volume=vol(out, 2), cavity=sum('.cav.' in ln for ln in fl), check=chk.strip()[:80],
           seconds=dt, budget='ok' if dt < 1 else 'miss')
    record('shell.open_box', contains(vol(out, 3), 424.0), volume=vol(out, 3))
    record('shell.closed_cyl', contains(vol(out, 5), 122.0 * PI), volume=vol(out, 5))


def patterns():
    out, dt = fresh('pat.bcd',
                    f'(node 1 (box 10 10 10) {IC})',
                    f'(node 2 (pattern 1 (linear 2 20 1 0 1 0)) {IA})',
                    f'(node 3 (move 2 0 40 0 0) {IS})',
                    f'(node 4 (box 10 10 10) {IC})',
                    f'(node 5 (union 3 4) {IA})',
                    f'(node 6 (pattern 1 (circular 4 20)) {IA})')
    f2 = fx(out, 2)
    f6 = fx(out, 6)
    f5 = fx(out, 5)
    record('pattern.linear', contains(vol(out, 2), 2000.0) and f2 is not None and f2[0] == 'add' and f2[3] == '2',
           volume=vol(out, 2), fx=f2, seconds=dt, budget='ok' if dt < 5 else 'miss')
    record('pattern.move_union', contains(vol(out, 5), 3000.0) and f5 is not None and f5[3] == '3',
           volume=vol(out, 5), fx=f5)
    record('pattern.circular', contains(vol(out, 6), 4000.0) and f6 is not None and f6[0] == 'add' and f6[3] == '4',
           volume=vol(out, 6), fx=f6, budget='ok' if dt < 5 else 'miss')


def holes():
    out, dt = fresh('holes.bcd',
                    f'(node 1 (box 10 10 10) {IC})',
                    f'(node 2 (pattern-holes 1 (face 1 0 top) (linear 2 2 4 4 2 2) (hole 0.5) through) {IR})',
                    f'(node 3 (pattern-holes 1 (face 1 0 top) (linear 2 2 4 4 2 2) (hole 0.5) 2) {IR})',
                    f'(node 4 (pattern-holes 1 (face 1 0 top) (circular 4 2 5 5) (hole 0.5) through) {IR})')
    c2, _ = cli('holes.bcd', 'check', '2')
    c3, _ = cli('holes.bcd', 'check', '3')
    c4, _ = cli('holes.bcd', 'check', '4')
    record('pattern.holes_linear_through', contains(vol(out, 2), 1000.0 - 10.0 * PI) and c2.startswith('ok:'),
           volume=vol(out, 2), check=c2.strip()[:80], seconds=dt, budget='ok' if dt < 5 else 'miss')
    record('pattern.holes_linear_blind', contains(vol(out, 3), 1000.0 - 2.0 * PI) and c3.startswith('ok:'),
           volume=vol(out, 3), check=c3.strip()[:80])
    record('pattern.holes_circular', contains(vol(out, 4), 1000.0 - 10.0 * PI) and c4.startswith('ok:'),
           volume=vol(out, 4), check=c4.strip()[:80])


def replay():
    out, dt = fresh('replay.bcd',
                    f'(node 1 (box 10 10 10) {IC})',
                    f'(node 2 (fillet 1 1) {IR})')
    again, _ = cli('replay.bcd', 'eval')
    record('replay.volume_text', vol_text(out, 2) is not None and vol_text(out, 2) == vol_text(again, 2),
           first=vol_text(out, 2), second=vol_text(again, 2), seconds=dt)


def rigid():
    law = open(os.path.join(HERE, '..', '..', 'laws', 'c09.bend'), encoding='utf-8').read()
    names = ('law rigid_path:', 'law rigid_triangle:', 'law rigid_rectangle:',
             'law rigid_tangent_whole:', 'law rigid_drag_clean:')
    record('rigid.law_names', all(n in law for n in names) and 'kind-not-decomposed' in law,
           missing=[n for n in names if n not in law])


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (sweep, sweep_arc, loft, chamfer, fillet, fillet_edit, draft, offset, shell, patterns, holes, replay, rigid):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} passed")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
