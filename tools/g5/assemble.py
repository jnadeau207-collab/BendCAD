import json
import math
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

DM = 2.0 * jet.PITCH_R
BALL_SELF = -(DM / (2.0 * jet.BALL_D)) * (1.0 - (jet.BALL_D / DM) ** 2)
TH = 'threaded fasteners'

PARTS = [
    ('shaft', 10, SH, 1.0, (0, 0, 0)),
    ('impeller', 19, AL, 1.0, (0, 0, -55)),
    ('turbine', 27, INC, 1.0, (0, 0, 45)),
    ('nut_front', 4222, SS, 1.0, (0, 0, -80)),
    ('nut_rear', 4223, SS, 1.0, (0, 0, 75)),
    ('spacer', 4224, SH, 1.0, (0, 0, 32)),
    ('bearing_front_inner', 4201, RG, 1.0, (0, 0, -14)),
    ('bearing_front_cage', 4204, PEEK, CAGE_SPEED, (0, 0, -14)),
    ('bearing_front_outer', 4202, RG, 0.0, (0, 0, -14)),
    ('bearing_rear_inner', 4211, RG, 1.0, (0, 0, 22)),
    ('bearing_rear_cage', 4214, PEEK, CAGE_SPEED, (0, 0, 22)),
    ('bearing_rear_outer', 4212, RG, 0.0, (0, 0, 22)),
    ('spring', 4221, SPR, 0.0, (0, 0, -6)),
    ('tunnel', 15, SS, 0.0, (0, 0, 0)),
    ('front_cover', 23, AL, 0.0, (0, 0, -100)),
    ('intake', 29, AL2, 0.0, (0, 0, -130)),
    ('diffuser', 24, AL, 0.0, (0, 0, -38)),
    ('liner', 22, NIA, 0.0, (0, 75, 0)),
    ('fuel_ring', 30, SS, 0.0, (0, 0, -15)),
    ('lube_tube', 34, SS, 0.0, (-40, 0, 0)),
    ('ngv', 26, INC, 0.0, (0, 0, 30)),
    ('casing', 20, SS, 0.0, (-130, 0, 0)),
    ('exhaust', 28, HRS, 0.0, (0, 0, 110)),
    ('glow_plug', 31, SS, 0.0, (40, 0, 0)),
    ('fuel_adapter', 33, SS, 0.0, (0, 40, 0)),
    ('lube_adapter', 35, SS, 0.0, (-35, -20, 0)),
]

LOOK = {
    'shaft': ('ground-steel', '42CrMo4-QT', 7850, 'rotor cartridge'),
    'impeller': ('aluminum-machined', 'AlZn5.5MgCu-T6', 2810, 'rotor cartridge'),
    'turbine': ('inconel-cast', 'IN713C', 7910, 'rotor cartridge'),
    'nut_front': ('stainless-bright', 'X5CrNi18-10', 7900, 'rotor cartridge'),
    'nut_rear': ('stainless-bright', 'X5CrNi18-10', 7900, 'rotor cartridge'),
    'spacer': ('ground-steel', '42CrMo4-QT', 7850, 'rotor cartridge'),
    'bearing_front_inner': ('bearing-steel', '100Cr6', 7810, 'rotor cartridge'),
    'bearing_front_cage': ('peek-cf', 'PEEK-CF30', 1410, 'rotor cartridge'),
    'bearing_front_outer': ('bearing-steel', '100Cr6', 7810, 'rotor cartridge'),
    'bearing_rear_inner': ('bearing-steel', '100Cr6', 7810, 'rotor cartridge'),
    'bearing_rear_cage': ('peek-cf', 'PEEK-CF30', 1410, 'rotor cartridge'),
    'bearing_rear_outer': ('bearing-steel', '100Cr6', 7810, 'rotor cartridge'),
    'spring': ('spring-blued', '51CrV4', 7850, 'rotor cartridge'),
    'tunnel': ('stainless-brushed', 'X5CrNi18-10', 7900, 'rotor cartridge'),
    'front_cover': ('aluminum-cast-blue', 'AlSi7Mg-T6', 2680, 'flow path'),
    'intake': ('aluminum-spun', 'AlMg3-H22', 2670, 'flow path'),
    'diffuser': ('aluminum-cast-satin', 'AlSi7Mg-T6', 2680, 'flow path'),
    'liner': ('inconel-heat', 'NiCr22Mo9Nb', 8440, 'flow path'),
    'fuel_ring': ('stainless-bright', 'X5CrNi18-10', 7900, 'fuel and lube'),
    'lube_tube': ('stainless-bright', 'X5CrNi18-10', 7900, 'fuel and lube'),
    'ngv': ('inconel-cast', 'IN713C', 7910, 'flow path'),
    'casing': ('stainless-brushed', 'X5CrNi18-10', 7900, 'flow path'),
    'exhaust': ('stainless-heat', 'X15CrNiSi25-21', 7900, 'flow path'),
    'glow_plug': ('stainless-bright', 'X5CrNi18-10', 7900, 'fuel and lube'),
    'fuel_adapter': ('stainless-bright', 'X5CrNi18-10', 7900, 'fuel and lube'),
    'lube_adapter': ('stainless-bright', 'X5CrNi18-10', 7900, 'fuel and lube'),
    'ball': ('ceramic', 'Si3N4', 3200, 'rotor cartridge'),
    'screw': ('stainless-bright', 'X5CrNi18-10', 7900, TH),
}


def frame_xf(fr):
    if fr[0] == 'z+':
        m = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
        t = fr[1:4]
    elif fr[0] == 'z-':
        m = [[1, 0, 0], [0, -1, 0], [0, 0, -1]]
        t = fr[1:4]
    else:
        c, s_ = math.cos(math.radians(fr[1])), math.sin(math.radians(fr[1]))
        ry = [[0, 0, -1], [0, 1, 0], [1, 0, 0]]
        rz = [[c, -s_, 0], [s_, c, 0], [0, 0, 1]]
        m = [[sum(rz[a][q] * ry[q][b] for q in range(3)) for b in range(3)] for a in range(3)]
        t = (fr[2] * c, fr[2] * s_, fr[3])
    return [m[0][0], m[1][0], m[2][0], 0, m[0][1], m[1][1], m[2][1], 0, m[0][2], m[1][2], m[2][2], 0, t[0], t[1], t[2], 1]


def instances():
    out = []
    ex = {n: e for n, _, _, _, e in PARTS}
    for j in jet.JOINTS:
        mesh = 'screw_m3x%d' % int(j.screw.L)
        for k, fr in enumerate(j.frames):
            _, ax = jet.J.axis_of(fr)
            e = ex[j.tapped]
            out.append(dict(name='%s_screw_%d' % (j.name, k), look='screw', node=j.screw.nid, mesh=mesh, color=SS, rotor=0.0,
                            explode=[e[q] - 18.0 * ax[q] for q in range(3)], xf=frame_xf(fr)))
    for tag, z, e in (('front', jet.Z_FRONT_BRG, -14), ('rear', jet.Z_REAR_BRG, 22)):
        for k in range(jet.BALL_N):
            a = 2.0 * math.pi * k / jet.BALL_N
            out.append(dict(name='bearing_%s_ball_%d' % (tag, k), look='ball', node=1301, mesh='ball', color=CER, rotor=CAGE_SPEED,
                            selfspin=BALL_SELF, explode=[0, 0, e],
                            xf=[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, jet.PITCH_R * math.cos(a), jet.PITCH_R * math.sin(a), z + jet.B_W / 2, 1]))
    return out


def scene_parts():
    ps = [dict(name=n, look=n, node=node, mesh=n, color=col, rotor=spin, explode=list(e)) for n, node, col, spin, e in PARTS]
    return ps + (instances() if jet.JOINTS_ON else [])


def decorate(sc):
    for p in sc['parts']:
        finish, grade, rho, group = LOOK[p.get('look', p['name'])]
        p.update(finish=finish, grade=grade, density=rho, group=group)
    sc['subtitle'] = '%d N class, %s r/min design point, BendCAD kernel geometry' % (round(jet.CYC['thrust_N']), format(round(jet.RPM), ','))
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


def meshes():
    m = {n: node for n, node, *_ in PARTS}
    for p in scene_parts():
        m.setdefault(p['mesh'], p['node'])
    return m


def tess(jobs=6):
    lst = os.path.join(VIEW, 'tess_list.txt')
    os.makedirs(VIEW, exist_ok=True)
    open(lst, 'w', newline=chr(10)).write(''.join(f'{n} {node}{chr(10)}' for n, node in meshes().items()))
    out, _ = jet.wsl('bash', jet.wpath(os.path.join(ROOT, 'tools', 'g5', 'tess_par.sh')), jet.BIN, f'{jet.WORK}/{DESIGN}',
                  jet.wpath(VIEW), jet.wpath(lst), str(jobs), timeout=86400)
    print(out, flush=True)
    return out


def tris(path):
    with open(path, encoding='utf-8') as fh:
        return sum(1 for ln in fh if ln.startswith('f '))


def scene():
    ps = scene_parts()
    for p in ps:
        p['mesh'] = p['mesh'] + '.obj'
        p['tris'] = tris(os.path.join(VIEW, p['mesh']))
    sc = dict(name='G5 micro turbojet', parts=ps, view=dict(tgt=[0, 0, 100], dist=760, yaw=-1.0, pitch=0.3, rps=3.0))
    json.dump(decorate(sc), open(os.path.join(VIEW, 'scene.json'), 'w'), indent=1)
    return sc


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
    elif what == 'tess':
        tess(int(sys.argv[2]) if len(sys.argv) > 2 else 6)
    elif what == 'scene':
        scene()
    elif what == 'step':
        step()
    elif what == 'look':
        f = os.path.join(VIEW, 'scene.json')
        json.dump(decorate(json.load(open(f))), open(f, 'w'), indent=1)
    print('total', round(time.time() - t0, 1))
