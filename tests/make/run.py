import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = os.environ.get('MAKE_WORK', '/var/tmp/make-e2e')
OUT = os.environ.get('MAKE_OUT', os.path.join(ROOT, 'docs', 'receipts', 'make', 'make.json'))

HEX = ('(node 1000 (prism 0 10 (region (path 3.1754264805429417 0 (line 1.5877132402714709 2.75) (line -1.5877132402714709 2.75) '
       '(line -3.1754264805429417 0) (line -1.5877132402714709 -2.75) (line 1.5877132402714709 -2.75)))) (intent create any 0 1 0))')
RECT = '(region (path 10 5 (line 30 5) (line 30 25) (line 10 25)))'
RRECT = ('(region (path 13 5 (line 27 5) (arc 27 8 3 30 8 ccw) (line 30 22) (arc 27 22 3 27 25 ccw) (line 13 25) '
         '(arc 13 22 3 10 22 ccw) (line 10 8) (arc 13 8 3 13 5 ccw)))')
PASS = r'status=pass'
CASES = [
    dict(name='mill_plate_holes', process='mill', node=2, verdict='makeable', why='drilled holes, a counterbore and an open top are all reachable with held tools', edits=[
        '(node 1 (box 60 40 8) (intent create any 0 1 0))',
        '(node 2 (holes 1 (face 1 n1.c0.top) through (hole 8 8 3) (hole 52 8 3) (hole 52 32 3) (hole 8 32 3) (counterbore M5 30 20)) (intent remove any any 1 5))'],
        expect=[(r'cylinder hole d=6 setup=[+-]z depth=8 tool="drill 6 jobber l2=57 \(ISO 235\)" status=pass', 4),
                (r'cylinder hole d=5\.5 setup=[+-]z depth=8 tool="drill 5\.5 jobber l2=57', 1),
                (r'cylinder hole d=10 setup=\+z depth=\S+ tool="drill 10 jobber', 1),
                (r'plane floor setup=\+z depth=0 tool="end mill 20 lc=38', 1)]),
    dict(name='mill_c_bore', process='mill', node=2, verdict='makeable', why='a hole that breaks out of a side still wraps more than half its circumference and is drilled',
         edits=['(node 1 (box 20 20 10) (intent create any 0 1 0))', '(node 2 (holes 1 (face 1 n1.c0.top) through (hole 2 10 3)) (intent remove any any 1 0))'],
         expect=[(r'cylinder hole d=6 setup=[+-]z depth=10 tool="drill 6 jobber l2=57 \(ISO 235\)" status=pass', 1)]),
    dict(name='mill_pocket_sharp', process='mill', node=2, verdict='not-makeable', why='a rectangular pocket has four sharp inside corners along the tool axis',
         edits=['(node 1 (box 40 30 10) (intent create any 0 1 0))', '(node 2 (pocket 1 (face 1 0 top) 4 %s) (intent remove any any 1 0))' % RECT],
         expect=[(r'make corner edge=\d+ faces=\S+ at=\S+ along=\(0,0,[+-]?1\) why=sharp-inside-corner: .* status=fail$', 4)]),
    dict(name='mill_pocket_round', process='mill', node=2, verdict='makeable', why='the same pocket with R3 corners takes a 6 mm end mill',
         edits=['(node 1 (box 40 30 10) (intent create any 0 1 0))', '(node 2 (pocket 1 (face 1 0 top) 4 %s) (intent remove any any 1 0))' % RRECT],
         expect=[(r'cylinder inside-radius r=3 setup=\+z depth=4 tool="end mill 6 lc=13', 4), (r'make corner', 0)]),
    dict(name='mill_undercut', process='mill', node=4, verdict='not-makeable', why='a cavity that widens below its opening hides its cone and floor from all six setups',
         edits=['(node 1 (box 40 40 20) (intent create any 0 1 0))', '(node 2 (revolve (region (path 0 10 (line 8 10) (line 4 20.5) (line 0 20.5)))) (intent create any 0 1 0))',
                '(node 3 (move 2 20 20 0 0) (intent same any any 1 0))', '(node 4 (difference 1 3) (intent remove any any 1 0))'],
         expect=[(r'make face \S+ unreachable from every setup \(material covers part of the face from all six directions\) status=fail', 4)]),
    dict(name='mill_modelled_thread', process='mill', node=1001, verdict='not-analyzed', why='a full-length M3 thread through 10 mm is deeper than the held taps are rated (3xD = 9)',
         edits=[HEX, '(node 1001 (holes 1000 (face 1000 0 top) through (tapped M3 0 0 modelled)) (intent remove any any 1 1))'],
         expect=[(r'helicoid thread M3 through length=10 setup=[+-]z why=deeper than the held taps\' rated 3xD = 9; shorten the thread or tap it from both ends status=not-analyzed', 4)]),
    dict(name='lathe_stud', process='lathe', node=2, verdict='makeable', why='an M8 6g stud: faced ends, threads cut with a 1.25 insert',
         edits=['(node 1 (cylinder 3.975 16) (intent create any 0 1 0))', '(node 2 (xthread 1 (face 1 n1.c0.wall.0.0) M8 6g) (intent remove any any 1 0))'],
         expect=[(r'helicoid external-thread d=7\.95 pitch=1\.25 single-point threading tool="16ER 1\.25 ISO insert" status=pass', 4), (r'plane faced on the turning axis', 2)]),
    dict(name='lathe_ring_groove', process='lathe', node=2, verdict='makeable', why='a DIN 471 groove on an 8 mm shaft takes the 0.9 mm partial-profile insert, not a turning insert',
         edits=['(node 1 (revolve (region (path 0 0 (line 4 0) (line 4 20) (line 0 20)))) (intent create any 0 1 0))',
                '(node 2 (groove 1 (face 1 n1.c0.wall.1.0) (ring DIN471) 8) (intent remove any any 1 0))'],
         expect=[(r'cylinder groove width=0\.9 tool="grooving insert m=0\.9 \(DIN 471 partial profile\)" status=pass', 2), (r'cylinder outside d=7\.6 turned', 0)]),
    dict(name='lathe_bush', process='lathe', node=1, verdict='makeable', why='a bush with an 8 mm bore drilled on the axis',
         edits=['(node 1 (revolve (region (path 4 0 (line 15 0) (line 15 20) (line 4 20)))) (intent create any 0 1 1))'],
         expect=[(r'cylinder bore d=8 depth=20 drilled on the turning axis tool="drill 8 jobber l2=75', 2), (r'cylinder outside d=30 turned', 2)]),
    dict(name='lathe_bush_bored', process='lathe', node=1, verdict='not-analyzed', why='a 22 mm bore is not a held drill size and boring bars are not held',
         edits=['(node 1 (revolve (region (path 11 0 (line 20 0) (line 20 10) (line 11 10)))) (intent create any 0 1 1))'],
         expect=[(r'cylinder bore d=22 depth=10 on the turning axis why=not a held drill size; boring bars are not held', 2)]),
    dict(name='lathe_cross_hole', process='lathe', node=4, verdict='makeable', why='a cross hole off the turning axis is drilled with live tooling',
         edits=['(node 1 (cylinder 6 10) (intent create any 0 1 0))', '(node 2 (cylinder 2 20) (intent create any 0 1 0))',
                '(node 3 (move 2 -10 0 5 5) (intent same any any 1 0))', '(node 4 (difference 1 3) (intent remove any any 1 1))'],
         expect=[(r'secondary \(live tooling\) cylinder hole d=4 setup=[+-]x depth=\S+ tool="drill 4 jobber l2=43', 1)]),
    dict(name='fdm_box', process='fdm', node=1, verdict='makeable', why='a block prints flat with no support',
         edits=['(node 1 (box 20 20 10) (intent create any 0 1 0))'],
         expect=[(r'make orientation up=\+z support-area=0\b', 1), (r'best orientation up=\+z support-area=0 \(no support\)', 1)]),
    dict(name='fdm_mushroom', process='fdm', node=4, verdict='makeable', why='a cap on a stem overhangs when stood on the stem and prints clean upside down',
         edits=['(node 1 (cylinder 3 10) (intent create any 0 1 0))', '(node 2 (cylinder 10 5) (intent create any 0 1 0))',
                '(node 3 (move 2 0 0 10 0) (intent same any any 1 0))', '(node 4 (union 1 3) (intent add any any 1 0))'],
         expect=[(r'make orientation up=\+z support-area=2\d\d\.\d+', 1), (r'best orientation up=-z support-area=0 \(no support\)', 1)]),
    dict(name='fdm_thin_wall', process='fdm', node=1, verdict='not-makeable', why='a 0.6 mm sheet is under the 0.8 mm FDM wall',
         edits=['(node 1 (box 20 20 0.6) (intent create any 0 1 0))'],
         expect=[(r'make wall min-wall \[0\.59\d*, 0\.6\d*\] certified limit=0\.8 status=fail', 1)]),
    dict(name='sla_thin_wall', process='sla', node=1, verdict='makeable', why='the same sheet clears the 0.5 mm SLA wall',
         edits=['(node 1 (box 20 20 0.6) (intent create any 0 1 0))'],
         expect=[(r'make wall min-wall \[0\.59\d*, 0\.6\d*\] certified limit=0\.5 status=pass', 1)]),
]


def kernel(design, *args, timeout=600):
    t0 = time.time()
    p = subprocess.run([BIN, design, *args], capture_output=True, text=True, timeout=timeout)
    return p.stdout + p.stderr, round(time.time() - t0, 3)


def run_case(c):
    wd = os.path.join(WORK, c['name'])
    os.makedirs(wd, exist_ok=True)
    d = os.path.join(wd, 'part.bcd')
    if os.path.exists(d):
        os.remove(d)
    kernel(d, 'new')
    ap, ta = kernel(d, 'apply', *c['edits'])
    rec = dict(case=c['name'], process=c['process'], node=c['node'], why=c['why'], apply_s=ta, committed=bool(re.search(r'^committed', ap, re.M)))
    checks = [('design committed', rec['committed'])]
    if rec['committed']:
        out, tm = kernel(d, 'make', str(c['node']), c['process'])
        rec.update(make_s=tm, out=out.strip())
        m = re.search(r'^verdict (\S+) status=(\S+)', out, re.M)
        rec['verdict'] = m.group(1) if m else None
        checks.append(('verdict %s' % c['verdict'], rec['verdict'] == c['verdict']))
        checks.append(('every face line ends in a status', all(re.search(r' status=(pass|fail|not-analyzed)$', ln) for ln in out.splitlines() if ln.startswith('make face') or ln.startswith('make corner'))))
        checks.append(('summary line present', bool(re.search(r'^make node %d: ' % c['node'], out, re.M))))
        checks.append(('make within the 5 s edit budget', tm <= 5.0))
        for pat, n in c['expect']:
            k = len(re.findall(pat, out, re.M))
            checks.append(('%d line(s) match %s (found %d)' % (n, pat, k), k == n))
    rec['checks'] = [dict(name=n, ok=bool(v)) for n, v in checks]
    rec['pass'] = all(v for _, v in checks)
    return rec


def main():
    names = sys.argv[1:]
    recs = []
    for c in CASES:
        if names and c['name'] not in names:
            continue
        r = run_case(c)
        recs.append(r)
        print('%-4s %6.2f s  %-22s %s' % ('pass' if r['pass'] else 'fail', r.get('make_s', 0.0), c['name'], r.get('verdict')), flush=True)
        for ch in r['checks']:
            if not ch['ok']:
                print('       fail: ' + ch['name'], flush=True)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(dict(binary=BIN, cases=recs, passed=sum(r['pass'] for r in recs), total=len(recs)), open(OUT, 'w'), indent=1)
    print('%d/%d pass -> %s' % (sum(r['pass'] for r in recs), len(recs), OUT))
    return 0 if all(r['pass'] for r in recs) else 1


if __name__ == '__main__':
    sys.exit(main())
