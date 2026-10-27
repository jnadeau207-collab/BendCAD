import os
import re
import sys

import numpy as np

import g3_render as R

R.COLORS = [('oring', (30, 30, 34)), ('lip_seal', (40, 40, 48)), ('circlip', (70, 72, 80)), ('screw', (70, 72, 80)),
            ('dowel', (120, 125, 135)), ('bush', (205, 160, 70)), ('key', (184, 115, 51)), ('drive', (64, 120, 220)),
            ('idler', (40, 170, 160)), ('front_cover', (196, 204, 216)), ('rear_cover', (196, 204, 216)),
            ('body', (176, 184, 196))]

EXPLODE = {'front_cover': -70, 'rear_cover': 70, 'bush_front': -110, 'bush_rear': 105, 'oring_front': -35,
           'oring_rear': 38, 'lip_seal': -150, 'circlip': -175, 'screw': 150, 'dowel': 0, 'key': -40}


def placed(run, exp):
    files = {}
    for ln in open(os.path.join(run, 'parts.txt')):
        if not ln.startswith('#'):
            p = ln.split()
            files[int(p[1])] = os.path.join(exp, p[2] + '.stl')
    txt = open(os.path.join(run, 'q', 'assembly_g2.txt')).read()
    cache = {}
    out = []
    for m in re.finditer(r'\(inst (\S+) (\d+) (\S+) (\S+) (\S+) 0\)', txt):
        node = int(m.group(2))
        if node not in cache:
            cache[node] = R.load_stl(files[node])
        out.append((m.group(1), cache[node] + np.array([float(m.group(3)), float(m.group(4)), float(m.group(5))])))
    return out


def shift(name):
    for k, dz in EXPLODE.items():
        if name.startswith(k):
            return dz
    return 0


def main(run, exp):
    ps = placed(run, exp)
    R.render(ps, 1400, 1000, tilt=0.45, spin=-0.75, title='G2 gear pump: assembled').save(os.path.join(run, 'g2_assembly.png'))
    ex = [(n, m + np.array([0, 0, shift(n)])) for n, m in ps]
    R.render(ex, 1000, 1500, tilt=0.3, spin=-0.7, title='G2 gear pump: exploded').save(os.path.join(run, 'g2_exploded.png'))
    zm = 0.025 + 35.0 / 2
    sec = [(n, R.clip(m, axis=2, keep_below=zm)) for n, m in ps
           if n in ('body', 'drive_shaft', 'idler_shaft', 'front_cover', 'oring_front', 'dowel0', 'dowel1', 'key', 'lip_seal',
                    'circlip', 'bush_front_drive', 'bush_front_idler')]
    R.render([(n, m) for n, m in sec if len(m)], 1400, 1100, tilt=1.25, spin=0.0,
             title='G2 gear pump: section through the gear mid-plane').save(os.path.join(run, 'g2_section.png'))
    print('rendered', len(ps), 'instances')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
