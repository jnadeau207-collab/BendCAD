import json
import math
import re
import subprocess
import sys

sys.path.insert(0, __file__.rsplit('/', 1)[0] if '/' in __file__ else '.')
from mesh import check, load_obj


def wsl_cat(path):
    return subprocess.run(['wsl.exe', '-e', 'cat', path], capture_output=True, text=True).stdout


def wsl_run(*args):
    return subprocess.run(['wsl.exe', '-e', *args], capture_output=True, text=True).stdout


def tokens(s):
    return re.findall(r'\(|\)|[^\s()]+', s)


def parse(s):
    st = [[]]
    for t in tokens(s):
        if t == '(':
            st.append([])
        elif t == ')':
            x = st.pop()
            st[-1].append(x)
        else:
            st[-1].append(t)
    return st[0]


def exact_volume(p):
    W, H, T, R, D, E, B, P, C = (p[k] for k in 'W H T R D E B P C'.split())
    plate = W * H - (4 - math.pi) * R * R - 4 * math.pi * (D / 2) ** 2
    return plate * T + math.pi * (B / 2) ** 2 * P - math.pi * (C / 2) ** 2 * (T + P)


def flat(x):
    return [x] if isinstance(x, str) else [a for y in x for a in flat(y)]


def main(design, obj, log_path, out):
    res = {}
    text = wsl_cat(design)
    tree = parse(text)
    params = {x[2]: float(x[3]) for x in tree if isinstance(x, list) and x and x[0] == 'param'}
    nodes = [x for x in tree if isinstance(x, list) and x and x[0] == 'node']
    want = dict(W=140, H=80, T=8, R=10, D=8, E=12, B=40, P=12, C=20)
    res['params_present'] = all(k in params for k in want)
    res['params_values'] = {k: params.get(k) for k in want}
    res['params_final'] = all(abs(params.get(k, -1) - v) < 1e-12 for k, v in want.items())
    ops = [n[2][0] for n in nodes]
    res['ops'] = ops
    hole_nodes = [n for n in nodes if n[2][0] == 'holes']
    res['holes_reference_W_and_H'] = any('W' in flat(n[2]) and 'H' in flat(n[2]) for n in hole_nodes)
    res['has_arcs'] = any('arc' in flat(n[2]) for n in nodes)
    res['every_node_has_intent'] = all(len(n) > 3 and isinstance(n[3], list) and n[3][0] == 'intent' for n in nodes)
    last = nodes[-1][1] if nodes else None
    ev = wsl_run('/home/jesse/bc/bendcad', design, 'eval')
    line = [l for l in ev.splitlines() if l.startswith(f'node {last}:')]
    vol = None
    if line:
        m = re.search(r'volume=\[([^,]+), ([^\]]+)\]', line[0])
        vol = (float(m.group(1)), float(m.group(2))) if m else None
    V = exact_volume(want)
    res['exact_volume'] = V
    res['kernel_volume_interval'] = vol
    res['kernel_interval_contains_exact'] = bool(vol and vol[0] <= V <= vol[1])
    res['kernel_interval_width'] = (vol[1] - vol[0]) if vol else None
    vs, fs = load_obj(obj)
    mc = check(vs, fs)
    res['mesh'] = {k: v for k, v in mc.items() if k != 'bbox'}
    lo, hi = mc['bbox']
    res['mesh_bbox'] = [lo, hi]
    res['mesh_bbox_ok'] = all(abs(a - b) < 1e-9 for a, b in zip(lo + hi, [0, 0, 0, 140, 80, 20]))
    res['mesh_genus_5'] = mc['euler_characteristic'] == 2 - 2 * 5
    res['mesh_volume_within_1pct'] = abs(mc['volume'] - V) / V < 0.01
    calls = [json.loads(l) for l in open(log_path)] if log_path else []
    cmds = [c['args'][1] if len(c['args']) > 1 else '' for c in calls]
    res['tool_sequence'] = cmds
    res['did_evaluate_twice_or_more'] = cmds.count('eval') >= 2
    res['did_show'] = 'show' in cmds
    res['did_faces'] = 'faces' in cmds
    res['did_sens'] = 'sens' in cmds
    res['did_tess'] = 'tess' in cmds
    res['committed_edit_of_W'] = any(len(c['args']) > 1 and c['args'][1] == 'apply' and any(re.match(r'\(param W 140', a) for a in c['args'][2:])
                                     and 'committed' in c['out'] for c in calls)
    checks = ['params_present', 'params_final', 'holes_reference_W_and_H', 'has_arcs', 'every_node_has_intent',
              'kernel_interval_contains_exact', 'mesh_bbox_ok', 'mesh_genus_5', 'mesh_volume_within_1pct',
              'did_evaluate_twice_or_more', 'did_show', 'did_faces', 'did_sens', 'did_tess', 'committed_edit_of_W']
    res['watertight'] = mc['watertight']
    checks.append('watertight')
    res['verdict'] = 'PASS' if all(res[c] for c in checks) else 'FAIL'
    res['failed'] = [c for c in checks if not res[c]]
    json.dump(res, open(out, 'w'), indent=2)
    print(json.dumps(res, indent=2))


if __name__ == '__main__':
    main(*sys.argv[1:5])
