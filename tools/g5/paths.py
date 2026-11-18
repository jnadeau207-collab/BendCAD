import json
import math
import os
import sys
import subprocess
import time

sys.path.insert(0, os.path.dirname(__file__))
import jet
from kq import kq, DESIGN, BIN

REC = os.path.join(jet.ROOT, 'docs', 'receipts', 'g5')
STEP = 0.25
BRG = [4201, 4202, 4203, 4204, 4211, 4212, 4213, 4214]


def cyl(r, phi, z):
    a = math.radians(phi)
    return (r * math.cos(a), r * math.sin(a), z)


def seg(p, q):
    n = max(1, int(math.ceil(math.dist(p, q) / STEP)))
    return [tuple(p[i] + (q[i] - p[i]) * k / n for i in range(3)) for k in range(n)]


def arc(r, phi0, phi1, z):
    n = max(1, int(math.ceil(abs(math.radians(phi1 - phi0)) * r / STEP)))
    return [cyl(r, phi0 + (phi1 - phi0) * k / n, z) for k in range(n)]


def walk(legs):
    pts = []
    for lg in legs:
        pts += lg
    return pts


def fuel():
    ph, z = jet.FUEL_PHI, jet.FUEL_Z
    nphi = 30.0
    rs = 34.0
    legs = [seg(cyl(66.0, ph, z), cyl(rs, ph, z)), arc(rs, ph, nphi, z), seg(cyl(rs, nphi, z), cyl(rs, nphi, 53.0)),
            seg(cyl(rs, nphi, 53.0), cyl(rs, nphi, 88.0)), [cyl(rs, nphi, 88.0)]]
    return dict(name='fuel', to='primary_zone', parts=[20, 33, 30, 22], pts=walk(legs),
                bores_mm=dict(fitting_bore=0.6, ring_stub_bore=0.6, needle_bore=0.2, vaporiser_stick_bore=1.75),
                end=dict(r=rs, z=88.0, liner_gas=[jet.R_LIN_I + jet.T_LIN, jet.R_LIN_O - jet.T_LIN, jet.Z_LIN0 + jet.T_LIN, 149.5]),
                route='fuel fitting bore (phi 60) -> casing port -> fuel ring stub -> ring channel to the needle at phi 30 -> needle bore -> vaporiser stick -> stick exit inside the liner')


def lube():
    ph, z = jet.LUBE_PHI, jet.LUBE_Z
    rg = jet.IR_LAND + 0.17
    zf = jet.Z_FRONT_BRG + jet.B_W / 2.0
    zr = jet.Z_REAR_BRG + jet.B_W / 2.0
    feed = [seg(cyl(66.0, ph, z), cyl(7.5, ph, z))]
    front = feed + [seg(cyl(7.5, ph, z), cyl(7.5, ph, 38.0)), seg(cyl(7.5, ph, 38.0), cyl(rg, ph, jet.Z_SPRING)),
                    seg(cyl(rg, ph, jet.Z_SPRING), cyl(rg, ph, zf)), [cyl(rg, ph, zf)]]
    rear = feed + [seg(cyl(7.5, ph, z), cyl(7.5, ph, jet.Z_REAR_BRG - 2.0)), seg(cyl(7.5, ph, jet.Z_REAR_BRG - 2.0), cyl(rg, ph, jet.Z_REAR_BRG + 0.5)),
                   seg(cyl(rg, ph, jet.Z_REAR_BRG + 0.5), cyl(rg, ph, zr)), [cyl(rg, ph, zr)]]
    parts = [20, 35, 34, 15, 10, 4221] + BRG
    gap = math.pi * (jet.CAGE_RI ** 2 - jet.IR_LAND ** 2)
    b = dict(fitting_bore=0.6, tube_bore=0.5, tunnel_hole=0.5, annulus=[jet.R_SPACER, 9.5], bearing_land_to_cage_mm2=round(gap, 3))
    return [dict(name='lube_front', to='bearing_front', parts=parts, pts=walk(front), bores_mm=b, end=dict(r=rg, z=zf),
                 route='lube fitting bore (phi 210) -> casing port -> lube tube -> tunnel cross hole -> shaft annulus -> between inner-ring land and cage of the front bearing'),
            dict(name='lube_rear', to='bearing_rear', parts=parts, pts=walk(rear), bores_mm=b, end=dict(r=rg, z=zr),
                 route='lube fitting bore (phi 210) -> casing port -> lube tube -> tunnel cross hole -> shaft annulus to the rear -> between inner-ring land and cage of the rear bearing')]


def classify_all(qs):
    if os.environ.get('G5_PORT'):
        return {q: (kq('classify', *q).strip().splitlines() or ['none'])[-1].strip() for q in qs}
    args = []
    for q in qs:
        args += (['::'] if args else []) + ['classify', *q]
    out = subprocess.run([BIN, DESIGN, 'batch', *args], capture_output=True, text=True, timeout=86400).stdout
    res, cur, last = {}, None, None
    for ln in out.splitlines():
        if ln.startswith('== classify '):
            if cur is not None:
                res[cur] = last
            cur, last = tuple(ln[len('== classify '):].split()), 'none'
        elif ln.strip() and ln.strip() != 'batch done':
            last = ln.strip()
    if cur is not None:
        res[cur] = last
    return res


def run():
    rows = []
    t0 = time.time()
    paths = [fuel()] + lube()
    qs = sorted({(str(part), *('%.6f' % c for c in p)) for path in paths for p in path['pts'] for part in path['parts']})
    got = classify_all(qs)
    for path in paths:
        blocked = []
        for i, p in enumerate(path['pts']):
            for part in path['parts']:
                c = got.get((str(part), *('%.6f' % x for x in p)), 'none')
                if c != 'outside':
                    blocked.append(dict(i=i, at=[round(x, 3) for x in p], part=part, says=c))
        rb = min(v for v in path['bores_mm'].values() if isinstance(v, float))
        ok = not blocked
        rows.append(dict(name=path['name'], to=path['to'], route=path['route'], samples=len(path['pts']), step_mm=STEP, parts=path['parts'],
                         connected=ok, end=path['end'], blocked=blocked[:20], n_blocked=len(blocked), min_section_mm2=round(math.pi * rb * rb, 4), bores_mm=path['bores_mm']))
        print(path['name'], 'connected' if ok else 'BLOCKED', len(path['pts']), 'samples', len(blocked), 'blocked', blocked[:3], flush=True)
    rep = dict(source='bendcad batch classify (certified point classification on one evaluation) along each stated route, every %.2f mm, against every part the route passes' % STEP,
               binary=BIN, design=DESIGN, queries=len(qs), seconds=round(time.time() - t0, 1), paths=rows)
    for sub, names in (('lube', ('lube_front', 'lube_rear')), ('fuel', ('fuel',))):
        os.makedirs(os.path.join(REC, sub), exist_ok=True)
        rr = [r for r in rows if r['name'] in names]
        json.dump(dict(rep, paths=rr), open(os.path.join(REC, sub, 'paths.json'), 'w'), indent=1)


if __name__ == '__main__':
    run()
