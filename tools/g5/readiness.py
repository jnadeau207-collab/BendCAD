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
DESIGN = os.environ.get('G5_DESIGN', '/home/jesse/g5/g5p.bcd')
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

def receipt(sub, name):
    f = os.path.join(REC, sub, name)
    return json.load(open(f, encoding='utf-8')) if os.path.exists(f) else None


fp = receipt('fuel', 'paths.json')
if not fp:
    chk('fuel reaches the primary zone (injector inside the liner)', 'not-analyzed', 'no docs/receipts/g5/fuel/paths.json', 'none')
else:
    r = fp['paths'][0]
    e = r['end']
    lo_r, hi_r, lo_z, hi_z = e['liner_gas']
    inl = lo_r < e['r'] < hi_r and lo_z < e['z'] < hi_z
    chk('fuel reaches the primary zone (injector inside the liner)', 'pass' if r['connected'] and inl else 'fail',
        f"{r['route']}: {r['samples']} samples, {r['n_blocked']} blocked, narrowest bore {r['min_section_mm2']} mm2, ends at r={e['r']} z={e['z']} {'inside' if inl else 'outside'} the liner gas volume",
        'measured: ' + fp['source'])

rn = receipt('running', 'running.json')
if not rn:
    chk('rotor running clearances survive thermal and centrifugal growth', 'not-analyzed', 'no docs/receipts/g5/running/running.json', 'none')
else:
    bad = [f"{x['pair']} {x['running_mm']}" for x in rn['rows'] if x['status'] != 'pass']
    tt = next(x for x in rn['rows'] if x['rotor'] == 'turbine' and x['stator'] == 'ngv')
    chk('rotor running clearances survive thermal and centrifugal growth', 'pass' if rn['ok'] else 'fail',
        f"turbine tip cold {tt['cold_certified_mm'][0]:.3f} running {tt['running_mm']:.3f} mm; {len(rn['rows'])} pairs, failing: {bad or 'none'}",
        'computed: ' + rn['source'])

brg = jet.BEARING
lim = brg['n_oil_air_rpm']
chk('bearing speed within catalog limit', 'pass' if rpm <= lim else 'fail',
    f"708 CE/HCP4A (SKF, hybrid, 8 x {brg['ball_d']} Si3N4 balls) at {rpm:.0f} r/min against the catalog attainable speed {lim} r/min with oil-air lubrication (oil-in-fuel feed), margin {lim / rpm:.2f}",
    'catalog: data/std/bearings.json')

sys.path.insert(0, os.path.join(ROOT, 'tools', 'mesh'))
import check as meshcheck

bad = {}
for p in sc['parts']:
    if not os.path.exists(os.path.join(VIEW, p['mesh'])):
        bad[p['name']] = 'no mesh: the part did not evaluate'
        continue
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
