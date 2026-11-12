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
DESIGN = os.environ.get('G5_DESIGN', '/home/jesse/g5/g5.bcd')
sys.path.insert(0, os.path.dirname(__file__))
import jet

checks = []


def chk(name, status, evidence, basis):
    checks.append(dict(check=name, status=status, evidence=evidence, basis=basis))
    print(f'{status.upper():13s} {name}: {evidence}', flush=True)


def kernel(*a):
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    p = subprocess.run([*pre, BIN, DESIGN, *a], capture_output=True, text=True, env=dict(os.environ, MSYS_NO_PATHCONV='1'), timeout=900)
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

sys.path.insert(0, os.path.join(ROOT, 'tools', 'mesh'))
import check as meshcheck

bad = {}
for p in sc['parts']:
    r = meshcheck.check(os.path.join(VIEW, p['mesh']))
    if not r['conforming']:
        bad[p['name']] = {k: r[k] for k in ('zero_area', 'same_direction_pairs', 't_junctions') if r[k]} | (
            {'edge_uses': r['edge_uses']} if set(r['edge_uses']) - {'2'} else {})
chk('kernel meshes are conforming (no zero-area T-junction fillers)', 'fail' if bad else 'pass',
    f'non-conforming parts: {bad}' if bad else 'every part: no zero-area triangle, every edge used twice in opposite directions, no T-junction',
    'measured: tools/mesh/check.py on the tessellation of every part')

SPLIT = {'primary': 0.20, 'secondary': 0.30, 'dilution': 0.50}


def near(x, want, rel):
    return x is not None and abs(x / want - 1.0) <= rel


def cfd(r):
    sp = r.get('liner_split', {})
    bad = [k for k, w in SPLIT.items() if not near(sp.get(k), w, 0.10)]
    ok = (r.get('converged') is True and r.get('mesh_levels', 0) >= 3 and near(r.get('mass_flow_kg_s'), cyc['inputs']['mdot_kg_s'], 0.05)
          and near(r.get('pressure_ratio'), cyc['inputs']['PR'], 0.10) and not bad)
    return ok, (f"mdot {r.get('mass_flow_kg_s')} vs {cyc['inputs']['mdot_kg_s']}, PR {r.get('pressure_ratio')} vs {cyc['inputs']['PR']}, "
                f"split off plan: {bad or 'none'}, levels {r.get('mesh_levels')}, converged {r.get('converged')}")


def fem(r):
    ps = r.get('parts', [])
    over = [p['name'] for p in ps if not p.get('max_von_mises_MPa', 1e30) < p.get('allowable_MPa', 0)]
    need = {'impeller', 'turbine'} - {p['name'] for p in ps}
    return r.get('converged') is True and ps and not over and not need, f'over allowable: {over or "none"}; missing: {sorted(need) or "none"}'


def modes(r):
    crit = [c for c in r.get('critical_speeds_rpm', []) if abs(c / rpm - 1.0) < 0.15]
    return bool(r.get('critical_speeds_rpm')) and not crit, f'critical speeds within 15% of {rpm:.0f} r/min: {crit or "none"}'


def lube(r):
    hit = {p['to'] for p in r.get('paths', []) if p.get('connected') is True and p.get('min_section_mm2', 0) > 0}
    miss = {'bearing_front', 'bearing_rear'} - hit
    return not miss, f'bearings without a connected lube path: {sorted(miss) or "none"}'


for name, pat, judge in (('airflow simulated through the running machine (CFD)', 'cfd', cfd), ('stress and creep at speed (FEM)', 'fem', fem),
                         ('rotor dynamics: critical speeds and blade modes', 'modes', modes), ('lubrication path to both bearings', 'lube', lube)):
    found = sorted(glob.glob(os.path.join(REC, pat, '*.json')))
    rs = [json.load(open(p, encoding='utf-8')) for p in found]
    rs = [r for r in rs if r.get('source')]
    if not rs:
        chk(name, 'not-analyzed', f'no receipt with a named kernel or solver source in docs/receipts/g5/{pat}', 'none')
        continue
    ok, ev = judge(rs[-1])
    chk(name, 'pass' if ok else 'fail', ev, f'measured: {rs[-1]["source"]}')

rep = dict(binary=BIN, ready=all(c['status'] == 'pass' for c in checks), checks=checks)
os.makedirs(os.path.join(REC, 'review'), exist_ok=True)
json.dump(rep, open(os.path.join(REC, 'review', 'readiness.json'), 'w', encoding='utf-8'), indent=1)
print('READY' if rep['ready'] else 'NOT READY', sum(c['status'] == 'pass' for c in checks), '/', len(checks), 'pass')
sys.exit(0 if rep['ready'] else 1)
