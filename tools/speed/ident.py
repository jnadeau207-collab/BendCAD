import concurrent.futures
import hashlib
import json
import os
import subprocess
import sys
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
G1 = 'docs/receipts/g1/rerun-2026-10-27'
PUMP = 'tests/speed/gearpump.bcd'
BOX = 'tests/speed/gearbox.bcd'
PAIR = '(assembly (inst body 11 0 0 0 0) (inst front_cover 38 0 0 0 0) (fix 1 body) (fix 2 front_cover))'


def battery():
    asm = open(os.path.join(ROOT, 'tests/speed/gearpump_asm.txt')).read().strip()
    solve = asm[:asm.index(' (press ')] + ')'
    return [
        ('g1-bracket-eval', G1 + '/run1/bracket.bcd', ['eval'], None),
        ('g1-strap-eval', G1 + '/run3/strap.bcd', ['eval'], None),
        ('g1-bracket-mass', G1 + '/run1/bracket.bcd', ['mass', 'LAST'], None),
        ('g2-eval', PUMP, ['eval'], None),
        ('g2-mass-38', PUMP, ['mass', '38'], None),
        ('g2-interf-11-38', PUMP, ['interf', '11', '38'], None),
        ('g2-step-38', PUMP, ['step', '38', 'OUT'], 'step38.stp'),
        ('g2-asm-solve', PUMP, ['asm', 'solve', solve], None),
        ('g2-asm-interf-pair', PUMP, ['asm', 'interf', PAIR], None),
        ('g2-threads-38', PUMP, ['threads', '38'], None),
        ('g3-eval', BOX, ['eval'], None),
    ]


def last_node(path):
    ids = [int(l.split()[1]) for l in open(os.path.join(ROOT, path)) if l.startswith('(node ')]
    return str(max(ids))


def run_one(binp, out, item):
    name, design, args, fout = item
    args = [last_node(design) if a == 'LAST' else a for a in args]
    fp = os.path.join(out, fout) if fout else None
    args = [fp if a == 'OUT' else a for a in args]
    t0 = time.time()
    p = subprocess.run([binp, os.path.join(ROOT, design)] + args, capture_output=True, text=True, cwd=out)
    dt = time.time() - t0
    text = p.stdout.replace(out, 'OUT')
    open(os.path.join(out, name + '.out'), 'w').write(text)
    rec = dict(name=name, seconds=round(dt, 2), rc=p.returncode, stdout_sha256=hashlib.sha256(text.encode()).hexdigest(),
               stdout_head=text[:160])
    if fp:
        rec['file_sha256'] = hashlib.sha256(open(fp, 'rb').read()).hexdigest() if os.path.exists(fp) else None
    return rec


def run(binp, out, jobs, only):
    os.makedirs(out, exist_ok=True)
    sha = hashlib.sha256(open(binp, 'rb').read()).hexdigest()
    items = [it for it in battery() if not only or it[0] in only]
    with concurrent.futures.ThreadPoolExecutor(jobs) as ex:
        rows = list(ex.map(lambda it: run_one(binp, out, it), items))
    prev = os.path.join(out, 'ident.json')
    if only and os.path.exists(prev):
        keep = [r for r in json.load(open(prev))['rows'] if r['name'] not in only]
        rows = sorted(keep + rows, key=lambda r: [b[0] for b in battery()].index(r['name']))
    json.dump(dict(binary=binp, sha256=sha, jobs=jobs, rows=rows), open(os.path.join(out, 'ident.json'), 'w'), indent=1)
    for r in rows:
        print('%-22s %9.1f s rc=%d %s' % (r['name'], r['seconds'], r['rc'], r['stdout_sha256'][:12]))


def compare(a, b, out):
    ra = {r['name']: r for r in json.load(open(os.path.join(a, 'ident.json')))['rows']}
    jb = json.load(open(os.path.join(b, 'ident.json')))
    lines, bad = [], 0
    for r in jb['rows']:
        x = ra[r['name']]
        same = x['stdout_sha256'] == r['stdout_sha256'] and x['rc'] == r['rc'] and x.get('file_sha256') == r.get('file_sha256')
        bad += not same
        lines.append('%-22s %s  ref %9.1f s  new %9.1f s  x%.2f' % (r['name'], 'IDENTICAL' if same else 'DIFFERENT', x['seconds'], r['seconds'],
                                                                   x['seconds'] / max(r['seconds'], 0.01)))
    lines.append('%d/%d identical' % (len(jb['rows']) - bad, len(jb['rows'])))
    open(out, 'w').write('\n'.join(lines) + '\n')
    print('\n'.join(lines))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    if sys.argv[1] == 'run':
        run(sys.argv[2], sys.argv[3], int(sys.argv[4]) if len(sys.argv) > 4 else 4, sys.argv[5:])
    else:
        compare(sys.argv[2], sys.argv[3], sys.argv[4])
