import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
import jet

DESIGN = 'g5.bcd'
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
VIEW = os.environ.get('G5_VIEW', os.path.join(ROOT, 'viewer', 'g5'))
EXPORT = f'{jet.WORK}/export'

AL, AL2, SS, SH, RG = (0.80, 0.82, 0.85), (0.86, 0.87, 0.89), (0.64, 0.66, 0.69), (0.45, 0.47, 0.50), (0.72, 0.74, 0.77)
CER, PEEK, SPR, INC, NIA, HRS = (0.20, 0.22, 0.25), (0.55, 0.42, 0.28), (0.30, 0.34, 0.45), (0.58, 0.52, 0.42), (0.62, 0.56, 0.48), (0.52, 0.47, 0.43)
CAGE_SPEED = 0.5 * (1.0 - jet.BALL_D / (2.0 * jet.PITCH_R))

PARTS = [
    ('shaft', 10, SH, 1.0, (0, 0, 0)),
    ('impeller', 19, AL, 1.0, (0, 0, -55)),
    ('turbine', 27, INC, 1.0, (0, 0, 45)),
    ('nut_front', 4222, SS, 1.0, (0, 0, -80)),
    ('nut_rear', 4223, SS, 1.0, (0, 0, 75)),
    ('bearing_front_inner', 4201, RG, 1.0, (0, 0, -14)),
    ('bearing_front_balls', 4203, CER, CAGE_SPEED, (0, 0, -14)),
    ('bearing_front_cage', 4204, PEEK, CAGE_SPEED, (0, 0, -14)),
    ('bearing_front_outer', 4202, RG, 0.0, (0, 0, -14)),
    ('bearing_rear_inner', 4211, RG, 1.0, (0, 0, 22)),
    ('bearing_rear_balls', 4213, CER, CAGE_SPEED, (0, 0, 22)),
    ('bearing_rear_cage', 4214, PEEK, CAGE_SPEED, (0, 0, 22)),
    ('bearing_rear_outer', 4212, RG, 0.0, (0, 0, 22)),
    ('spring', 4221, SPR, 0.0, (0, 0, -6)),
    ('tunnel', 15, SS, 0.0, (0, 0, 0)),
    ('front_cover', 23, AL, 0.0, (0, 0, -100)),
    ('intake', 29, AL2, 0.0, (0, 0, -130)),
    ('diffuser', 24, AL, 0.0, (0, 0, -38)),
    ('straightener', 25, AL, 0.0, (0, 0, -26)),
    ('liner', 22, NIA, 0.0, (0, 75, 0)),
    ('manifold', 30, SS, 0.0, (0, 0, -15)),
    ('ngv', 26, INC, 0.0, (0, 0, 30)),
    ('casing', 20, SS, 0.0, (-130, 0, 0)),
    ('exhaust', 28, HRS, 0.0, (0, 0, 110)),
]

LOOK = {
    'shaft': ('ground-steel', '42CrMo4-QT', 7850, 'rotor cartridge'),
    'impeller': ('aluminum-machined', 'AlZn5.5MgCu-T6', 2810, 'rotor cartridge'),
    'turbine': ('inconel-cast', 'IN713C', 7910, 'rotor cartridge'),
    'nut_front': ('stainless-bright', 'X5CrNi18-10', 7900, 'rotor cartridge'),
    'nut_rear': ('stainless-bright', 'X5CrNi18-10', 7900, 'rotor cartridge'),
    'bearing_front_inner': ('bearing-steel', '100Cr6', 7810, 'rotor cartridge'),
    'bearing_front_balls': ('ceramic', 'Si3N4', 3200, 'rotor cartridge'),
    'bearing_front_cage': ('peek-cf', 'PEEK-CF30', 1410, 'rotor cartridge'),
    'bearing_front_outer': ('bearing-steel', '100Cr6', 7810, 'rotor cartridge'),
    'bearing_rear_inner': ('bearing-steel', '100Cr6', 7810, 'rotor cartridge'),
    'bearing_rear_balls': ('ceramic', 'Si3N4', 3200, 'rotor cartridge'),
    'bearing_rear_cage': ('peek-cf', 'PEEK-CF30', 1410, 'rotor cartridge'),
    'bearing_rear_outer': ('bearing-steel', '100Cr6', 7810, 'rotor cartridge'),
    'spring': ('spring-blued', '51CrV4', 7850, 'rotor cartridge'),
    'tunnel': ('stainless-brushed', 'X5CrNi18-10', 7900, 'rotor cartridge'),
    'front_cover': ('aluminum-cast-blue', 'AlSi7Mg-T6', 2680, 'flow path'),
    'intake': ('aluminum-spun', 'AlMg3-H22', 2670, 'flow path'),
    'diffuser': ('aluminum-cast-satin', 'AlSi7Mg-T6', 2680, 'flow path'),
    'straightener': ('aluminum-cast-graphite', 'AlSi7Mg-T6', 2680, 'flow path'),
    'liner': ('inconel-heat', 'NiCr22Mo9Nb', 8440, 'flow path'),
    'manifold': ('stainless-bright', 'X5CrNi18-10', 7900, 'flow path'),
    'ngv': ('inconel-cast', 'IN713C', 7910, 'flow path'),
    'casing': ('stainless-brushed', 'X5CrNi18-10', 7900, 'flow path'),
    'exhaust': ('stainless-heat', 'X15CrNiSi25-21', 7900, 'flow path'),
}


def decorate(sc):
    for p in sc['parts']:
        finish, grade, rho, group = LOOK[p['name']]
        p.update(finish=finish, grade=grade, density=rho, group=group)
    sc['subtitle'] = '100 N class, 99,700 r/min design point, BendCAD kernel geometry'
    return sc


def say(tag, out, dt):
    ok = ('committed' in out or 'wrote' in out) and 'rejected' not in out
    print(f'{tag:28s} {round(dt, 1):8.1f}s  {out.strip().splitlines()[-1][:160] if out.strip() else ""}', flush=True)
    return ok


def build(only=None):
    if not only:
        jet.cli(DESIGN, 'new')
    for tag, edits in jet.parts():
        if only and tag not in only:
            continue
        out, dt = jet.cli(DESIGN, 'apply', *edits, timeout=7200)
        if not say(tag, out, dt):
            print(out[-1500:])
            return False
    out, dt = jet.cli(DESIGN, 'apply', *jet.materials())
    return say('materials', out, dt)


def scene():
    jet.wsl('mkdir', '-p', '/mnt/' + VIEW[0].lower() + VIEW[2:].replace('\\', '/'))
    d = '/mnt/' + VIEW[0].lower() + VIEW[2:].replace('\\', '/')
    spec = []
    for name, node, col, spin, ex in PARTS:
        spec += [name, str(node), *(repr(c) for c in col), repr(spin), *(repr(float(e)) for e in ex)]
    out, dt = jet.cli(DESIGN, 'scene', d, 'G5 micro turbojet', *spec, timeout=14400)
    say('scene', out, dt)
    sc = json.load(open(os.path.join(VIEW, 'scene.json')))
    json.dump(decorate(sc), open(os.path.join(VIEW, 'scene.json'), 'w'), indent=1)
    return out


def step():
    jet.wsl('mkdir', '-p', EXPORT)
    for name, node, *_ in PARTS:
        out, dt = jet.cli(DESIGN, 'step', str(node), f'{EXPORT}/{name}.stp', timeout=3600)
        say(f'step {name}', out, dt)
    inst = ' '.join(f'(inst {name} {node} 0.0 0.0 0.0 0)' for name, node, *_ in PARTS)
    fix = ' '.join(f'(fix {i + 1} {name})' for i, (name, *_) in enumerate(PARTS))
    out, dt = jet.cli(DESIGN, 'asm', 'step', f'{EXPORT}/g5_assembly.stp', f'(assembly {inst} {fix})', timeout=7200)
    say('step assembly', out, dt)


if __name__ == '__main__':
    what = sys.argv[1]
    t0 = time.time()
    if what == 'build':
        build(sys.argv[2:] or None)
    elif what == 'scene':
        scene()
    elif what == 'step':
        step()
    elif what == 'look':
        f = os.path.join(VIEW, 'scene.json')
        json.dump(decorate(json.load(open(f))), open(f, 'w'), indent=1)
    print('total', round(time.time() - t0, 1))
