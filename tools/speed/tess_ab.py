import json
import os
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'tests', 'eval'))
import tess_acc as TA

CASES = [('/var/tmp/sv1.bcd', 9001), ('/var/tmp/sv1.bcd', 4204), ('/home/jesse/g6/g6u.bcd', 4271)] + TA.CASES


def run(binp, design, node, preset, work):
    out = os.path.join(work, 'ab_%s_%d.obj' % (os.path.basename(binp), node))
    t0 = time.time()
    p = subprocess.run([binp, design, 'tess', str(node), out, str(preset)], capture_output=True, text=True, timeout=7200)
    head = (p.stdout + p.stderr).strip().split('\n')[0]
    rec = dict(seconds=round(time.time() - t0, 1), head=head[:200])
    for k in ('ntris', 'nverts'):
        m = re.search(k + r' (\d+)', head)
        rec[k] = int(m.group(1)) if m else None
    for k in ('chord', 'normal-dev'):
        m = re.search(r'\b' + k + r'[ =](\S+)', head)
        rec[k] = float(m.group(1)) if m else None
    if os.path.exists(out) and os.path.getsize(out) > 0:
        rec.update(TA.mesh_stats(*TA.obj(out)))
        os.remove(out)
    return rec


def main():
    a, b, preset, dest = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
    work = os.environ.get('TESS_WORK', '/var/tmp')
    only = os.environ.get('TESS_AB_ONLY')
    rows = []
    for design, node in CASES:
        if only and str(node) not in only.split(','):
            continue
        TA.BIN = a
        ex = TA.exact(design, node)
        mid = 0.5 * (ex[0] + ex[1]) if ex else None
        row = dict(design=os.path.basename(design), node=node, exact=ex)
        for tag, binp in (('a', a), ('b', b)):
            r = run(binp, design, node, preset, work)
            if mid and 'volume' in r:
                r['rel_err'] = (r['volume'] - mid) / mid
            row[tag] = r
        rows.append(row)
        ra, rb = row['a'], row['b']
        print('%-10s %5d  a %7.1fs tris=%-8s err=%-9s unm=%-4s folds=%-4s nd=%-8s | b %7.1fs tris=%-8s err=%-9s unm=%-4s folds=%-4s nd=%s' % (
            row['design'], node, ra['seconds'], ra.get('tris'), '%.2e' % ra['rel_err'] if 'rel_err' in ra else '-', ra.get('unmatched'), ra.get('folds'),
            '%.4f' % ra['normal-dev'] if ra.get('normal-dev') is not None else '-',
            rb['seconds'], rb.get('tris'), '%.2e' % rb['rel_err'] if 'rel_err' in rb else '-', rb.get('unmatched'), rb.get('folds'),
            '%.4f' % rb['normal-dev'] if rb.get('normal-dev') is not None else '-'), flush=True)
    json.dump(dict(a=a, b=b, preset=preset, rows=rows), open(dest, 'w', encoding='utf-8'), indent=1)


if __name__ == '__main__':
    main()
