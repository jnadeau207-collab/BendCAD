import json
import math
import re
import sys

sys.path.insert(0, __file__.rsplit('/', 1)[0] if '/' in __file__ else '.')
from g1 import flat, parse, wsl_cat, wsl_run
from mesh import check, load_obj


def exact_volume(p):
    L, S, T, D, K, M, Q = (p[k] for k in 'L S T D K M Q'.split())
    return (L * S + math.pi * (S / 2) ** 2) * T - 2 * math.pi * (D / 2) ** 2 * T - K * M * Q


def main(design, obj, log_path, out):
    res = {}
    tree = parse(wsl_cat(design))
    params = {x[2]: float(x[3]) for x in tree if isinstance(x, list) and x and x[0] == 'param'}
    nodes = [x for x in tree if isinstance(x, list) and x and x[0] == 'node']
    want = dict(L=120, S=30, T=10, D=12, K=40, M=14, Q=4)
    res['params_values'] = {k: params.get(k) for k in want}
    res['params_final'] = all(abs(params.get(k, -1) - v) < 1e-12 for k, v in want.items())
    res['ops'] = [n[2][0] for n in nodes]
    res['has_arcs'] = any('arc' in flat(n[2]) or 'circle' in flat(n[2]) for n in nodes[:1])
    res['holes_follow_L'] = any('L' in flat(n[2]) for n in nodes if n[2][0] in ('holes', 'pocket'))
    res['every_node_has_intent'] = all(len(n) > 3 and isinstance(n[3], list) and n[3][0] == 'intent' for n in nodes)
    last = nodes[-1][1] if nodes else None
    ev = wsl_run('/home/jesse/bc/bendcad', design, 'eval')
    line = [l for l in ev.splitlines() if l.startswith(f'node {last}:')]
    m = re.search(r'volume=\[([^,]+), ([^\]]+)\]', line[0]) if line else None
    vol = (float(m.group(1)), float(m.group(2))) if m else None
    V = exact_volume(want)
    res['exact_volume'] = V
    res['kernel_volume_interval'] = vol
    res['kernel_interval_contains_exact'] = bool(vol and vol[0] <= V <= vol[1])
    vs, fs = load_obj(obj)
    mc = check(vs, fs)
    res['mesh'] = {k: v for k, v in mc.items() if k != 'bbox'}
    lo, hi = mc['bbox']
    res['mesh_bbox'] = [lo, hi]
    res['mesh_bbox_ok'] = all(abs(a - b) < 1e-9 for a, b in zip(lo + hi, [0, 0, 0, 150, 30, 10]))
    res['mesh_genus_2'] = mc['euler_characteristic'] == -2
    res['mesh_volume_within_1pct'] = abs(mc['volume'] - V) / V < 0.01
    res['watertight'] = mc['watertight']
    calls = [json.loads(l) for l in open(log_path)]
    cmds = [c['args'][1] if len(c['args']) > 1 else '' for c in calls]
    res['tool_sequence'] = cmds
    sens = [c['out'] for c in calls if len(c['args']) > 1 and c['args'][1] == 'sens']
    sm = re.search(r'd_volume=([^ ]+)', sens[-1]) if sens else None
    res['sensitivity'] = float(sm.group(1)) if sm else None
    res['sensitivity_ok'] = sm is not None and abs(float(sm.group(1)) - want['S'] * want['T']) < 1e-3
    applies = [c for c in calls if len(c['args']) > 1 and c['args'][1] == 'apply']
    deep = [c for c in applies if any(re.match(r'\(param Q 12', a) for a in c['args'][2:])]
    res['deep_pocket_rejected'] = bool(deep) and all('rejected' in c['out'] and 'depth-reaches-opposite-face' in c['out'] for c in deep)
    res['committed_edit_of_L'] = any(any(re.match(r'\(param L 120', a) for a in c['args'][2:]) and 'committed' in c['out'] for c in applies)
    res['did_tess'] = 'tess' in cmds
    checks = ['params_final', 'has_arcs', 'holes_follow_L', 'every_node_has_intent', 'kernel_interval_contains_exact',
              'mesh_bbox_ok', 'mesh_genus_2', 'mesh_volume_within_1pct', 'watertight', 'sensitivity_ok',
              'deep_pocket_rejected', 'committed_edit_of_L', 'did_tess']
    res['verdict'] = 'PASS' if all(res[c] for c in checks) else 'FAIL'
    res['failed'] = [c for c in checks if not res[c]]
    json.dump(res, open(out, 'w'), indent=2)
    print(json.dumps(res, indent=2))


if __name__ == '__main__':
    main(*sys.argv[1:5])
