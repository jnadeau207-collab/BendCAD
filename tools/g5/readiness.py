import glob
import json
import os
import re
import subprocess
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
VIEW = os.path.join(ROOT, 'viewer', 'g5')
REC = os.path.join(ROOT, 'docs', 'receipts', 'g5')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
DESIGN = '/home/jesse/g5/g5.bcd'
sys.path.insert(0, os.path.dirname(__file__))
import jet

checks = []


def chk(name, status, evidence, basis):
    checks.append(dict(check=name, status=status, evidence=evidence, basis=basis))
    print(f'{status.upper():13s} {name}: {evidence}', flush=True)


def kernel(*a):
    p = subprocess.run(['wsl.exe', '-e', BIN, DESIGN, *a], capture_output=True, text=True, env=dict(os.environ, MSYS_NO_PATHCONV='1'), timeout=900)
    return p.stdout + p.stderr


def verts(name):
    with open(os.path.join(VIEW, name + '.obj'), encoding='utf-8') as f:
        return np.array([ln.split()[1:4] for ln in f if ln.startswith('v ')], float)


cyc = json.load(open(os.path.join(REC, 'run1', 'cycle.json'), encoding='utf-8'))
sc = json.load(open(os.path.join(VIEW, 'scene.json'), encoding='utf-8'))
m = re.search(r'([\d,]+) r/min', sc.get('subtitle', ''))
shown = float(m.group(1).replace(',', '')) if m else None
rpm = cyc['shaft_rpm']
chk('design point is one number everywhere', 'pass' if shown and abs(shown - rpm) <= 0.01 * rpm else 'fail',
    f'cycle.json shaft_rpm={rpm:.0f}, scene/plan states {shown:.0f} r/min' if shown else 'scene states no speed', 'computed: cycle.json vs scene subtitle')

faces = kernel('faces', '22')
perforated = [ln for ln in faces.splitlines() if 'cylinder' in ln and re.search(r'loops=(\d+)', ln) and int(re.search(r'loops=(\d+)', ln).group(1)) > 1]
chk('combustor liner admits air (perforated walls)', 'pass' if perforated else 'fail',
    f'{len(perforated)} liner cylinder faces with holes; kernel lists {len(faces.splitlines())} faces, all loops=1' if not perforated else f'{len(perforated)} perforated faces',
    'kernel: faces 22 (certified B-rep topology)')

inside = []
for p in sc['parts']:
    if p['name'] == 'liner':
        continue
    v = verts(p['name'])
    r = np.hypot(v[:, 0], v[:, 1])
    if np.any((r > 22.6) & (r < 45.4) & (v[:, 2] > 60.6) & (v[:, 2] < 149.9)):
        inside.append(p['name'])
chk('fuel reaches the primary zone (injector inside the liner)', 'pass' if inside else 'fail',
    f'parts reaching into the liner gas volume: {inside or "none"}', 'measured: kernel tessellation vertices vs liner interior')

sw = json.load(open(os.path.join(REC, 'review', 'swept_clearance.json'), encoding='utf-8'))
gap = next(r['gap_mm'] for r in sw['rows'] if r['rotor'] == 'turbine' and r['stator'] == 'ngv')
alpha = next(m[3] for m in jet.MATERIALS if m[0] == 27)
growth = alpha * 33.0 * (cyc['inputs']['TIT_K'] - 293.0)
chk('turbine tip clearance survives thermal growth', 'pass' if gap > growth else 'fail',
    f'cold swept gap {gap:.3f} mm vs free thermal growth of a 33 mm IN713C rim at TIT {growth:.3f} mm (shroud growth and spin not yet subtracted)',
    'estimated: swept_clearance.json + alpha*r*dT')

ndm = cyc['bearing_ndm_mm_per_min']
chk('bearing speed within catalog limit', 'not-analyzed', f'n*dm={ndm:.0f} mm/min; no catalog limit or lubrication path is in the repo', 'none')

bad = {}
for p in sc['parts']:
    t = []
    with open(os.path.join(VIEW, p['mesh']), encoding='utf-8') as f:
        vv = []
        for ln in f:
            if ln.startswith('v '):
                vv.append(ln.split()[1:4])
            elif ln.startswith('f '):
                t.append([int(x) - 1 for x in ln.split()[1:4]])
    V = np.array(vv, float)
    T = V[np.array(t)]
    a = np.linalg.norm(np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]), axis=1)
    z = int((a <= 1e-12).sum())
    if z:
        bad[p['name']] = z
chk('kernel meshes are conforming (no zero-area T-junction fillers)', 'fail' if bad else 'pass',
    f'zero-area triangles: {bad}' if bad else 'none', 'measured: tessellation of every part')

for name, pat in (('airflow simulated through the running machine (CFD)', 'cfd'), ('stress and creep at speed (FEM)', 'fem'),
                  ('rotor dynamics: critical speeds and blade modes', 'modes'), ('lubrication path to both bearings', 'lube')):
    found = glob.glob(os.path.join(REC, pat, '*.json'))
    chk(name, 'pass' if found else 'not-analyzed', f'{len(found)} receipts in docs/receipts/g5/{pat}', 'receipt presence')

rep = dict(binary=BIN, ready=all(c['status'] == 'pass' for c in checks), checks=checks)
os.makedirs(os.path.join(REC, 'review'), exist_ok=True)
json.dump(rep, open(os.path.join(REC, 'review', 'readiness.json'), 'w', encoding='utf-8'), indent=1)
print('READY' if rep['ready'] else 'NOT READY', sum(c['status'] == 'pass' for c in checks), '/', len(checks), 'pass')
sys.exit(0 if rep['ready'] else 1)
