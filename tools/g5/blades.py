import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
import jet

BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
DESIGN = os.environ.get('G5_DESIGN', '/home/jesse/g5/g5p.bcd')
NUM = r'(-?\d+(?:\.\d+)?(?:e[-+]?\d+)?)'


def moments(node):
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    out = subprocess.run([*pre, BIN, DESIGN, 'mass', str(node), '0'], capture_output=True, text=True, timeout=3600,
                         env=dict(os.environ, MSYS_NO_PATHCONV='1')).stdout
    m = re.search(r'moments volume=\[' + NUM + ', ' + NUM + r'\] centroid \[' + NUM + ', ' + NUM + r'\]x\[' + NUM + ', ' + NUM + r'\]', out)
    if not m or 'status=certified' not in out:
        raise SystemExit(f'node {node}: no certified moments\n{out[-600:]}')
    v = [float(m.group(1)), float(m.group(2))]
    cx, cy = 0.5 * (float(m.group(3)) + float(m.group(4))), 0.5 * (float(m.group(5)) + float(m.group(6)))
    return v, (cx * cx + cy * cy) ** 0.5, out


def main():
    rows = {}
    for key, node in (('turbine', 2702), ('impeller', 1903), ('splitter', 1904)):
        v, r, _ = moments(node)
        rows[key] = dict(node=node, volume_mm3=[round(v[0], 6), round(v[1], 6)], centroid_r_mm=round(r, 6))
        print(key, node, rows[key], flush=True)
    sha = subprocess.run((['wsl.exe', '-e'] if os.name == 'nt' else []) + ['sha256sum', BIN], capture_output=True, text=True).stdout.split()[0]
    rep = dict(source=f'bendcad mass NODE 0 (certified divergence-theorem moments, Bezier patches by Green\'s theorem) on {os.path.basename(BIN)} sha256 {sha}, design {DESIGN}',
               note='replaces the receipt of 2026-11-16, whose turbine blade volume 31.64 mm3 came from the torus-formula defect fixed in tests/std/moments_patch',
               turbine=dict(node=2702, volume_mm3=sum(rows['turbine']['volume_mm3']) / 2, volume_iv=rows['turbine']['volume_mm3'], centroid_r_mm=rows['turbine']['centroid_r_mm']),
               impeller=dict(node=1903, volume_mm3=sum(rows['impeller']['volume_mm3']) / 2, volume_iv=rows['impeller']['volume_mm3'], centroid_r_mm=rows['impeller']['centroid_r_mm'],
                             splitter_node=1904, splitter_mm3=sum(rows['splitter']['volume_mm3']) / 2, splitter_iv=rows['splitter']['volume_mm3'], splitter_r_mm=rows['splitter']['centroid_r_mm']))
    out = os.path.join(jet.ROOT, 'docs', 'receipts', 'g5', 'clear', 'blades.json')
    json.dump(rep, open(out, 'w', encoding='utf-8'), indent=1)
    print('wrote', out)


if __name__ == '__main__':
    main()
