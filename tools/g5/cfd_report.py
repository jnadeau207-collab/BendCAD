import glob
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import jet

REC = os.path.join(jet.ROOT, 'docs', 'receipts', 'g5', 'cfd')
CYC = jet.CYC
ROWS = ('primary', 'secondary', 'dilution')


def series(case, name):
    fs = sorted(glob.glob(os.path.join(case, 'postProcessing', name, '*', '*.dat')))
    rows = []
    for f in fs:
        for ln in open(f, encoding='utf-8'):
            if ln.startswith('#') or not ln.strip():
                continue
            parts = ln.replace('(', ' ').replace(')', ' ').split()
            rows.append([float(x) for x in parts])
    rows.sort(key=lambda r: r[0])
    return rows


def last(case, name, col=1, n=1):
    s = series(case, name)
    return [r[col] for r in s[-n:]] if s else None


def steady(vals, tol):
    if not vals or len(vals) < 10:
        return False
    a = sum(vals[: len(vals) // 2]) / (len(vals) // 2)
    b = sum(vals[len(vals) // 2:]) / (len(vals) - len(vals) // 2)
    return abs(a - b) <= tol * max(abs(b), 1e-30)


def liner(case):
    flux = {}
    for row in ROWS:
        tot = 0.0
        for side in ('outer', 'inner'):
            v = last(case, f'{row}_{side}', col=1, n=1)
            if v is None:
                return None
            tot += abs(v[0])
        flux[row] = tot
    s = sum(flux.values())
    mi = last(case, 'massIn', n=50)
    hist = {row: [abs(a) + abs(b) for a, b in zip(last(case, f'{row}_outer', n=50) or [], last(case, f'{row}_inner', n=50) or [])] for row in ROWS}
    return dict(split={k: v / s for k, v in flux.items()}, flux_kg_s=flux, mass_in_kg_s=abs(mi[-1]) if mi else None,
                converged=steady(mi, 0.005) and all(steady(h, 0.01) for h in hist.values()))


def compressor(case):
    mi = last(case, 'massIn', n=50)
    ma = last(case, 'massAmb', n=50) or [0.0]
    po = last(case, 'pOut', col=1, n=50)
    if not mi or not po:
        return None
    m = -(mi[-1] + ma[-1])
    pr = po[-1] / 101325.0
    return dict(mass_flow_kg_s=m, pressure_ratio=pr, converged=steady(mi, 0.005) and steady(po, 0.005))


def main():
    lv = {}
    for case in sorted(glob.glob(os.path.join(jet.ROOT, 'cfd', 'g5comp_L*'))):
        r = compressor(case)
        if r:
            lv.setdefault(case[-2:], {})['compressor'] = r
    for case in sorted(glob.glob(os.path.join(jet.ROOT, 'cfd', 'g5liner_L*'))):
        r = liner(case)
        if r:
            lv.setdefault(case[-2:], {})['liner'] = r
    full = [k for k, v in sorted(lv.items()) if 'compressor' in v and 'liner' in v]
    if not full:
        print('no complete level', lv)
        return
    fine = lv[full[-1]]
    rep = dict(source='OpenFOAM 2412 rhoSimpleFoam (opencfd/openfoam-default:2412): compressor with MRF at the design speed against the cycle delivery pressure (cfd/g5comp_L*), liner cold flow at delivery conditions (cfd/g5liner_L*); snappyHexMesh on the kernel meshes of viewer/g5',
               levels={k: v for k, v in sorted(lv.items())}, mesh_levels=len(full), converged=all(lv[k]['compressor']['converged'] and lv[k]['liner']['converged'] for k in full),
               mass_flow_kg_s=fine['compressor']['mass_flow_kg_s'], pressure_ratio=fine['compressor']['pressure_ratio'], liner_split=fine['liner']['split'],
               design=dict(mdot_kg_s=CYC['inputs']['mdot_kg_s'], PR=CYC['inputs']['PR']))
    os.makedirs(REC, exist_ok=True)
    json.dump(rep, open(os.path.join(REC, 'g5.json'), 'w', encoding='utf-8'), indent=1)
    print(json.dumps({k: rep[k] for k in ('mesh_levels', 'converged', 'mass_flow_kg_s', 'pressure_ratio', 'liner_split')}))


if __name__ == '__main__':
    main()
