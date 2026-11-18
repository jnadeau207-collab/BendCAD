import json
import math
import os

import threads as T

FAST = json.load(open(os.path.join(os.path.dirname(__file__), '..', '..', 'data', 'std', 'fasteners.json'), encoding='utf-8'))
FCOL = FAST['columns']


def fz(size, col):
    return FAST['sizes'][size][FCOL.index(col)]

IC, IA, IR, IS = ('(intent %s any any any any)' % k for k in ('create', 'add', 'remove', 'same'))
f = T.f
CLEAR = {3.0: 1.7, 5.0: 2.75}


class Ids:
    def __init__(self, start):
        self.n = start

    def __call__(self):
        self.n += 1
        return self.n


def place(src, fr, ids):
    kind = fr[0]
    if kind == 'z+':
        n = ids()
        return [f'(node {n} (move {src} {f(fr[1])} {f(fr[2])} {f(fr[3])} 0) {IS})'], n
    if kind == 'z-':
        a, b = ids(), ids()
        return [f'(node {a} (rotate {src} x 180.0) {IS})', f'(node {b} (move {a} {f(fr[1])} {f(fr[2])} {f(fr[3])} 0) {IS})'], b
    phi, r, z = fr[1], fr[2], fr[3]
    a, b, c = ids(), ids(), ids()
    x, y = r * math.cos(math.radians(phi)), r * math.sin(math.radians(phi))
    return [f'(node {a} (rotate {src} y -90.0) {IS})', f'(node {b} (rotate {a} z {f(phi)}) {IS})',
            f'(node {c} (move {b} {f(x)} {f(y)} {f(z)} 0) {IS})'], c


def axis_of(fr):
    if fr[0] == 'z+':
        return (fr[1], fr[2], fr[3]), (0.0, 0.0, 1.0)
    if fr[0] == 'z-':
        return (fr[1], fr[2], fr[3]), (0.0, 0.0, -1.0)
    phi, r, z = math.radians(fr[1]), fr[2], fr[3]
    return (r * math.cos(phi), r * math.sin(phi), z), (-math.cos(phi), -math.sin(phi), 0.0)


def cyl(nid, r, z0, z1):
    a = nid * 10 + 1
    return [f'(node {a} (cylinder {f(r)} {f(z1 - z0)}) {IC})', f'(node {nid} (move {a} 0.0 0.0 {f(z0)} 0) {IS})']


def tree_union(ids_list, ids):
    e = []
    while len(ids_list) > 1:
        nx = []
        for i in range(0, len(ids_list) - 1, 2):
            n = ids()
            e.append(f'(node {n} (union {ids_list[i]} {ids_list[i + 1]}) {IA})')
            nx.append(n)
        if len(ids_list) % 2:
            nx.append(ids_list[-1])
        ids_list = nx
    return e, ids_list[0]


class Screw:
    def __init__(self, d, length, nid):
        self.d, self.L, self.nid = d, length, nid
        self.p = T.PITCH[d]
        self.z0, self.z1 = 0.4, length - 0.5

    def size(self):
        return 'M%d' % int(self.d)

    def edits(self):
        n = self.nid
        return [f'(node {n}1 (screw ISO4762 {self.size()} {f(self.L)}) {IC})', f'(node {n}2 (rotate {n}1 x 180.0) {IS})',
                f'(node {n} (move {n}2 0.0 0.0 {f(self.L)} 0) {IS})']


class Joint:
    def __init__(self, name, screw, frames, clamp, t_clamp, tapped, drill_to, thread_to, through=False):
        self.name, self.screw, self.frames = name, screw, frames
        self.clamp, self.t_clamp, self.tapped = clamp, t_clamp, tapped
        self.drill_to, self.thread_to, self.through = drill_to, thread_to, through

    def phase(self, zg0):
        return T.SEAM_OFF + 2.0 * math.pi * (zg0 - self.screw.z0) / self.screw.p

    def clear_cutter(self, ids):
        b = ids()
        e = cyl(b, CLEAR[self.screw.d], -0.3, self.t_clamp + 0.3)
        out = []
        for fr in self.frames:
            pe, n = place(b, fr, ids)
            e += pe
            out.append(n)
        u, top = tree_union(out, ids)
        return e + u, top

    def tap_cutter(self, ids):
        b = ids()
        z0, z1 = self.t_clamp - 0.3, self.drill_to + (0.3 if self.through else 0.0)
        e = cyl(b, fz(self.screw.size(), 'tap_drill') / 2.0, z0, z1)
        self.tap_prim = b * 10 + 1
        self.tap_span = (self.t_clamp, self.thread_to if not self.through else self.drill_to)
        out = []
        for fr in self.frames:
            pe, n = place(b, fr, ids)
            e += pe
            out.append(n)
        u, top = tree_union(out, ids)
        return e + u, top

    def instances(self, ids):
        e, out = [], []
        for fr in self.frames:
            pe, n = place(self.screw.nid, fr, ids)
            e += pe
            out.append(n)
        return e, out

    def engaged(self):
        lo = max(self.t_clamp, self.screw.z0)
        hi = min(self.drill_to if self.through else self.thread_to, self.screw.z1)
        return hi - lo


def apply_cuts(base, cutters, ids, final):
    e = []
    prev = base
    for c in cutters:
        n = ids()
        e.append(f'(node {n} (difference {prev} {c}) {IR})')
        prev = n
    e.append(f'(node {final} (move {prev} 0.0 0.0 0.0 0) {IS})')
    return e
