import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'g5'))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'tools', 'g5'))
import jet
import math

m0, m1, n = float(sys.argv[1]), float(sys.argv[2]), int(sys.argv[3])


def fl(x):
    return f'F64.add(k, {float(x)!r}f64)' if x >= 0 else f'F64.add(k, F64.neg({float(-x)!r}f64))'


def sec(m):
    hr, hz = jet.imp_hub_pt(m)
    sr, sz = jet.imp_shr_pt(m)
    dr, dz = sr - hr, sz - hz
    ln = math.hypot(dr, dz)
    hr, hz = hr - 0.6 * dr / ln, hz - 0.6 * dz / ln
    L = ln + 1.6
    th = jet.imp_theta(m)
    c, s = math.cos(th), math.sin(th)
    kk = min(1.0, (m - m0) / 0.2)
    kk = kk * kk * (3 - 2 * kk)
    a, b = 0.5 + 1.1 * kk, 0.4 + 0.4 * kk
    P = [(0.0, -a / 2), (L, -b / 2), (L, b / 2), (0.0, a / 2)]
    v2 = lambda p: f'V.V2{{{fl(p[0])}, {fl(p[1])}}}'
    runs = ', '.join(f'[{v2(P[i])}, {v2(P[(i + 1) % 4])}]' for i in range(4))
    o = f'V.Pt{{{fl(hr * c)}, {fl(hr * s)}, {fl(hz)}}}'
    u = f'V.Dr{{{fl(dr / ln * c)}, {fl(dr / ln * s)}, {fl(dz / ln)}}}'
    v = f'V.Dr{{{fl(-s)}, {fl(c)}, 0.0f64}}'
    return f'SK.Sc{{([{runs}]), SK.Fr{{{o}, {u}, {v}, 1.0f64}}}}'


secs = ', '.join(sec(m0 + (m1 - m0) * i / (n - 1)) for i in range(n))
src = open(os.path.join(os.path.dirname(__file__), 'zim.tmpl')).read().replace('@SECS@', secs)
open(os.path.join(os.path.dirname(__file__), 'zim.bend'), 'w', newline='\n').write(src)
