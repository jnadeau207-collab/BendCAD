import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'media')
W, H, SS = 960, 440, 2
FRAMES = 90
FONT = 'C:/Windows/Fonts/segoeui.ttf'
FONT_B = 'C:/Windows/Fonts/segoeuib.ttf'
MONO = 'C:/Windows/Fonts/consola.ttf'

THEMES = {
    'dark': dict(bg=(13, 17, 23), grid=(30, 38, 50), shadow=(7, 9, 13), face=(88, 120, 190), lit=(150, 190, 255), edge=(120, 240, 255),
                 text=(230, 237, 243), dim=(139, 148, 158), accent=(120, 240, 255)),
    'light': dict(bg=(255, 255, 255), grid=(228, 233, 240), shadow=(222, 227, 235), face=(150, 175, 225), lit=(225, 235, 255), edge=(70, 120, 210),
                  text=(31, 35, 40), dim=(101, 109, 118), accent=(20, 90, 200)),
}

CAPTIONS = [
    ('volume', 'certified interval, not a guess'),
    ('230 laws', 'proven for every input'),
    ('refusals', 'named, with a fix, never silent'),
    ('parallel', 'every core, by construction'),
]


def load_obj(path):
    vs, fs = [], []
    for line in open(path):
        p = line.split()
        if not p:
            continue
        if p[0] == 'v':
            vs.append([float(x) for x in p[1:4]])
        elif p[0] == 'f':
            fs.append([int(x.split('/')[0]) - 1 for x in p[1:4]])
    return np.array(vs), np.array(fs)


def feature_edges(v, f, deg=25):
    n = np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]])
    n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-12
    owners = {}
    for ti, t in enumerate(f):
        for a, b in ((t[0], t[1]), (t[1], t[2]), (t[2], t[0])):
            owners.setdefault((min(a, b), max(a, b)), []).append(ti)
    cos = math.cos(math.radians(deg))
    per_tri = [[] for _ in f]
    for e, ts in owners.items():
        if len(ts) != 2 or float(n[ts[0]] @ n[ts[1]]) < cos:
            per_tri[ts[0]].append(e)
    return n, per_tri


def rot(tilt, spin):
    ca, sa, cb, sb = math.cos(tilt), math.sin(tilt), math.cos(spin), math.sin(spin)
    rx = np.array([[1, 0, 0], [0, ca, -sa], [0, sa, ca]])
    ry = np.array([[cb, 0, sb], [0, 1, 0], [-sb, 0, cb]])
    up = np.array([[1, 0, 0], [0, 0, 1], [0, -1, 0]])
    return rx @ ry @ up


def frame(v, f, n, per_tri, t, th, fonts):
    w, h = W * SS, H * SS
    im = Image.new('RGB', (w, h), th['bg'])
    d = ImageDraw.Draw(im)
    for x in range(0, w, 40 * SS):
        d.line([(x, 0), (x, h)], fill=th['grid'], width=1)
    for y in range(0, h, 40 * SS):
        d.line([(0, y), (w, y)], fill=th['grid'], width=1)
    ang = 2 * math.pi * t
    r = rot(0.55 + 0.08 * math.sin(ang), ang)
    p = v @ r.T
    nn = n @ r.T
    sc = 0.50 * w / (2 * np.linalg.norm(v, axis=1).max())
    cx, cy = 0.72 * w, 0.47 * h
    sx = cx + p[:, 0] * sc
    sy = cy - p[:, 1] * sc
    rr = 0.5 * w / 2 * 0.92
    for k in range(12, 0, -1):
        a = k / 12
        col = tuple(int(th['bg'][i] + (th['shadow'][i] - th['bg'][i]) * (1 - a) ** 0.7) for i in range(3))
        d.ellipse([cx - rr * a, cy + 0.36 * h - 0.10 * h * a, cx + rr * a, cy + 0.36 * h + 0.10 * h * a], fill=col)
    light = np.array([0.35, 0.55, 0.76])
    order = np.argsort(p[f].mean(axis=1)[:, 2])
    for ti in order:
        if nn[ti, 2] <= 0:
            continue
        k = max(0.0, float(nn[ti] @ light))
        col = tuple(int(th['face'][i] + (th['lit'][i] - th['face'][i]) * k) for i in range(3))
        a, b, c = f[ti]
        d.polygon([(sx[a], sy[a]), (sx[b], sy[b]), (sx[c], sy[c])], fill=col)
        for e0, e1 in per_tri[ti]:
            d.line([(sx[e0], sy[e0]), (sx[e1], sy[e1])], fill=th['edge'], width=2 * SS)
    big, mid, small, mono = fonts
    d.text((56 * SS, 120 * SS), 'BendCAD', font=big, fill=th['text'])
    d.text((58 * SS, 196 * SS), 'a CAD kernel agents can trust', font=mid, fill=th['dim'])
    i = int(t * len(CAPTIONS)) % len(CAPTIONS)
    u = (t * len(CAPTIONS)) % 1.0
    a = min(1.0, u / 0.15, (1.0 - u) / 0.15)
    head, body = CAPTIONS[i]
    hc = tuple(int(th['bg'][j] + (th['accent'][j] - th['bg'][j]) * a) for j in range(3))
    bc = tuple(int(th['bg'][j] + (th['text'][j] - th['bg'][j]) * a) for j in range(3))
    d.line([(60 * SS, 287 * SS), (68 * SS, 296 * SS), (82 * SS, 276 * SS)], fill=hc, width=3 * SS, joint='curve')
    d.text((94 * SS, 270 * SS), head, font=mono, fill=hc)
    d.text((58 * SS, 306 * SS), body, font=small, fill=bc)
    return im.resize((W, H), Image.LANCZOS)


def main():
    v, f = load_obj(os.path.join(ROOT, 'tests', 'c06', 'e2e-meshes', 'bracket.obj'))
    v = v - (v.min(axis=0) + v.max(axis=0)) / 2
    n, per_tri = feature_edges(v, f)
    fonts = (ImageFont.truetype(FONT_B, 64 * SS), ImageFont.truetype(FONT, 26 * SS),
             ImageFont.truetype(FONT, 22 * SS), ImageFont.truetype(MONO, 26 * SS))
    os.makedirs(OUT, exist_ok=True)
    for name, th in THEMES.items():
        ims = [frame(v, f, n, per_tri, k / FRAMES, th, fonts) for k in range(FRAMES)]
        pal = ims[0].quantize(colors=128, method=Image.MEDIANCUT)
        q = [im.quantize(palette=pal, dither=Image.NONE) for im in ims]
        path = os.path.join(OUT, 'hero.gif' if name == 'light' else 'hero_dark.gif')
        q[0].save(path, save_all=True, append_images=q[1:], duration=60, loop=0, optimize=True, disposal=1)
        print(path, os.path.getsize(path))


if __name__ == '__main__':
    sys.exit(main())
