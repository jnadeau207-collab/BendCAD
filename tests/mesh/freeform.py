import json
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, 'tools', 'mesh'))
import check as MC

BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = os.environ.get('MESH_WORK', '/var/tmp/mesh-freeform')
OUT = os.environ.get('MESH_OUT', os.path.join(ROOT, 'docs', 'receipts', 'mesh', 'freeform.json'))
CASES = [
    dict(name='turbine_blade', design=os.path.join(ROOT, 'tests', 'std', 'moments_patch', 'design.bcd'), node=1, preset=2, volume=94.57149877616622,
         claim='a skinned turbine blade (19 bicubic faces, 2 planar caps) meshes conforming: no zero-area triangle, every edge used twice in opposite directions, no T-junction, and the mesh volume within 0.5% of the certified volume'),
]


def run():
    os.makedirs(WORK, exist_ok=True)
    rows = []
    for c in CASES:
        obj = os.path.join(WORK, c['name'] + '.obj')
        t = time.time()
        p = subprocess.run([BIN, c['design'], 'tess', str(c['node']), obj, str(c['preset'])], capture_output=True, text=True, timeout=600)
        s = round(time.time() - t, 2)
        r = MC.check(obj) if os.path.exists(obj) else None
        err = abs(r['volume'] / c['volume'] - 1.0) if r else None
        ok = bool(r and r['conforming'] and err <= 0.005)
        rows.append(dict(name=c['name'], claim=c['claim'], seconds=s, kernel=(p.stdout + p.stderr).strip()[-400:], check=r, volume_rel_err=err,
                         verdict='pass' if ok else 'fail'))
        print(c['name'], 'pass' if ok else 'FAIL', s, 's', r and {k: r[k] for k in ('triangles', 'zero_area', 'edge_uses', 't_junctions', 'conforming')}, 'vol err', err, flush=True)
    sha = subprocess.run(['sha256sum', BIN], capture_output=True, text=True).stdout.split()[0]
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(dict(binary=BIN, sha256=sha, passed=sum(r['verdict'] == 'pass' for r in rows), total=len(rows), cases=rows), open(OUT, 'w'), indent=1)
    sys.exit(0 if all(r['verdict'] == 'pass' for r in rows) else 1)


if __name__ == '__main__':
    run()
