import json
import os
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
import humphrey as H

REC = os.path.join(H.ROOT, 'docs', 'receipts', 'g6')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
DESIGN = os.environ.get('G6_DESIGN', '/home/jesse/g6/g6r.bcd')
WORK = os.environ.get('G6_PMI_WORK', '/var/tmp/g6pmi')
TIP = H.TT + H.G_TT
SETS = [
    ('stator', 4202, 'check',
     f'(pmi (node 4202) (datum A n4202.c0.wall.0.0) (tol fl flatness 0.01 n4202.c0.wall.0.0 rfs) '
     f'(dim shroud {TIP!r} {TIP - 0.005!r} {TIP + 0.005!r}) (dim rdc_ro {H.RDC_RO!r} {H.RDC_RO - 0.005!r} {H.RDC_RO + 0.005!r}) (state cold 1))'),
    ('turbine tip clearance stack', 4202, 'stack',
     f'(pmi (node 4202) (dim shroud {TIP!r} {TIP - 0.005!r} {TIP + 0.005!r}) (dim tip {-H.TT!r} {-H.TT - 0.005!r} {-H.TT + 0.005!r}) (state cold 1) (stack gtt shroud tip))'),
    ('RDC channel height stack', 4202, 'stack',
     f'(pmi (node 4202) (dim ro {H.RDC_RO!r} {H.RDC_RO - 0.005!r} {H.RDC_RO + 0.005!r}) (dim ri {-H.RDC_RI!r} {-H.RDC_RI - 0.005!r} {-H.RDC_RI + 0.005!r}) (state cold 1) (stack chan ro ri))'),
    ('compressor tip clearance stack', 23, 'stack',
     f'(pmi (node 23) (dim offset {H.G_TIP!r} {H.G_TIP - 0.005!r} {H.G_TIP + 0.005!r}) (dim blade 0.0 -0.005 0.005) (state cold 1) (stack gtip offset blade))'),
    ('RDC injector face and orifices', 40, 'check',
     f'(pmi (node 40) (datum A n4005.c0.wall.2.0) (tol fl flatness 0.01 n4005.c0.wall.2.0 rfs) (dim orifice 1.2 1.19 1.21) '
     f'(dim pcd {2 * H.RDC_RM!r} {2 * H.RDC_RM - 0.01!r} {2 * H.RDC_RM + 0.01!r}) (state cold 1))'),
    ('front bearing outer ring in the tunnel bore', 44, 'fits',
     '(pmi (node 44) (temp cold 20) (temp hot 150) (fit housing 44 n4401.c0.wall.9.0 52 n5002.c0.wall.1.0 H7/h6 clearance))'),
    ('front bearing inner ring on the shaft journal', 10, 'fits',
     '(pmi (node 10) (temp cold 20) (temp hot 150) (fit journal 51 n5001.c0.wall.5.0 10 n1001.c0.wall.1.0 H6/k5 transition))'),
]


def nodes(path):
    out, order, mats = {}, [], {}
    for ln in open(path, encoding='utf-8'):
        m = re.match(r'\((node|material) (\d+) ', ln)
        if m and m.group(1) == 'node':
            out[int(m.group(2))] = ln
            order.append(int(m.group(2)))
        elif m:
            mats[int(m.group(2))] = ln
    return out, order, mats


def closure(ns, roots):
    need, todo = set(), list(roots)
    while todo:
        n = todo.pop()
        if n in need or n not in ns:
            continue
        need.add(n)
        body = ns[n].split(' ', 2)[2]
        todo += [int(x) for x in re.findall(r'(?<![\d.\-])(\d+)(?![\d.])', body) if int(x) in ns]
    return need


def design(ns, order, mats, roots, name):
    keep = closure(ns, roots)
    p = os.path.join(WORK, name + '.bcd')
    with open(p, 'w', newline='\n') as f:
        f.write('(bendcad 1)\n' + ''.join(ns[n] for n in order if n in keep) + ''.join(mats[n] for n in sorted(mats) if n in keep))
    return p


def main():
    os.makedirs(WORK, exist_ok=True)
    ns, order, mats = nodes(DESIGN)
    rows = []
    for name, anchor, verb, form in SETS:
        roots = [anchor] + [int(x) for x in re.findall(r'\(fit \S+ (\d+) \S+ (\d+)', form)[0]] if verb == 'fits' else [anchor]
        d = design(ns, order, mats, roots, re.sub(r'\W+', '_', name))
        t = time.time()
        p = subprocess.run([BIN, d, 'pmi', verb, form], capture_output=True, text=True, timeout=7200)
        out = (p.stdout + p.stderr).strip()
        ok = 'error' not in out and 'refused' not in out and ('pmi ok' in out or 'certified' in out or verb == 'fits')
        rows.append(dict(name=name, verb=verb, form=form, seconds=round(time.time() - t, 1), verdict='pass' if ok else 'fail', out=out[-1500:]))
        print('PASS' if ok else 'FAIL', name, rows[-1]['seconds'], 's |', out.replace('\n', ' | ')[:300], flush=True)
    rep = dict(source='bendcad pmi check / stack / fits on the built HUMPHREY-1 parts (ISO GPS semantics; fits per ISO 286 with each part grown by its own material)',
               binary=BIN, design=DESIGN, green=all(r['verdict'] == 'pass' for r in rows), rows=rows,
               notes='A bearing bore is modelled as ISO 286 H6: the ISO 492 bore deviation (0 to -10 um at 20 mm) has no ISO 286 class.')
    json.dump(rep, open(os.path.join(REC, 'pmi.json'), 'w', encoding='utf-8'), indent=1)


if __name__ == '__main__':
    main()
