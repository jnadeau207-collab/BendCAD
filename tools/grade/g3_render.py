import glob
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

SS = 2
FONT = 'C:/Windows/Fonts/segoeui.ttf'
BG = (250, 251, 253)
COLORS = [('housing', (176, 184, 196)), ('frame', (176, 184, 196)), ('wall', (176, 184, 196)), ('brg', (210, 90, 80)), ('base', (160, 168, 182)), ('cover', (190, 198, 210)),
          ('shaft', (205, 160, 70)), ('pinion', (64, 120, 220)), ('gear', (40, 170, 160)),
          ('bearing', (210, 90, 80)), ('seal', (60, 60, 70))]


def color(name):
    n = name.lower()
    for k, c in COLORS:
        if k in n:
            return c
    return (150, 150, 200)


def load_stl(path):
    tri = []
    cur = []
    for line in open(path):
        p = line.split()
        if p and p[0] == 'vertex':
            cur.append([float(x) for x in p[1:4]])
            if len(cur) == 3:
                tri.append(cur)
                cur = []
    return np.array(tri)


def view(tilt, spin):
    ct, st, cs, ss = math.cos(tilt), math.sin(tilt), math.cos(spin), math.sin(spin)
    rz = np.array([[cs, -ss, 0], [ss, cs, 0], [0, 0, 1]])
    rx = np.array([[1, 0, 0], [0, ct, -st], [0, st, ct]])
    swap = np.array([[1, 0, 0], [0, 0, 1], [0, -1, 0]])
    return rx @ swap @ rz


def render(meshes, w, h, tilt=0.5, spin=-0.7, title=None, pad=0.08):
    r = view(tilt, spin)
    allp = np.concatenate([m.reshape(-1, 3) for _, m in meshes]) @ r.T
    lo, hi = allp.min(axis=0), allp.max(axis=0)
    W, H = w * SS, h * SS
    top = (40 if title else 0) * SS
    sc = min((1 - 2 * pad) * W / max(hi[0] - lo[0], 1e-9), (1 - 2 * pad) * (H - top) / max(hi[1] - lo[1], 1e-9))
    cx, cy = (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2
    img = np.empty((H, W, 3), np.float32)
    img[:] = BG
    zb = np.full((H, W), -np.inf, np.float32)
    light = np.array([0.3, 0.5, 0.81])
    light /= np.linalg.norm(light)
    for name, m in meshes:
        p = m @ r.T
        n = np.cross(p[:, 1] - p[:, 0], p[:, 2] - p[:, 0])
        nl = np.linalg.norm(n, axis=1, keepdims=True)
        n = n / (nl + 1e-12)
        base = np.array(color(name), np.float32)
        sx = W / 2 + (p[:, :, 0] - cx) * sc
        sy = top + (H - top) / 2 - (p[:, :, 1] - cy) * sc
        sz = p[:, :, 2]
        for i in range(len(p)):
            x0, x1 = int(max(0, np.floor(sx[i].min()))), int(min(W - 1, np.ceil(sx[i].max())))
            y0, y1 = int(max(0, np.floor(sy[i].min()))), int(min(H - 1, np.ceil(sy[i].max())))
            if x1 < x0 or y1 < y0:
                continue
            (ax, bx, cx2), (ay, by, cy2) = sx[i], sy[i]
            den = (by - cy2) * (ax - cx2) + (cx2 - bx) * (ay - cy2)
            if abs(den) < 1e-12:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            l0 = ((by - cy2) * (gx - cx2) + (cx2 - bx) * (gy - cy2)) / den
            l1 = ((cy2 - ay) * (gx - cx2) + (ax - cx2) * (gy - cy2)) / den
            l2 = 1 - l0 - l1
            inside = (l0 >= -1e-4) & (l1 >= -1e-4) & (l2 >= -1e-4)
            if not inside.any():
                continue
            z = l0 * sz[i, 0] + l1 * sz[i, 1] + l2 * sz[i, 2]
            sub = zb[y0:y1 + 1, x0:x1 + 1]
            vis = inside & (z > sub)
            if not vis.any():
                continue
            k = 0.35 + 0.65 * abs(float(n[i] @ light))
            sub[vis] = z[vis]
            img[y0:y1 + 1, x0:x1 + 1][vis] = np.minimum(255, base * k + 20)
    im = Image.fromarray(img.astype(np.uint8))
    if title:
        ImageDraw.Draw(im).text((16 * SS, 10 * SS), title, font=ImageFont.truetype(FONT, 20 * SS), fill=(30, 34, 40))
    return im.resize((w, h), Image.LANCZOS)


def grid(items, cols, cw, ch):
    rows = (len(items) + cols - 1) // cols
    out = Image.new('RGB', (cols * cw, rows * ch), BG)
    for i, (name, m) in enumerate(items):
        out.paste(render([(name, m)], cw, ch, title=name), ((i % cols) * cw, (i // cols) * ch))
    return out


def main(root, out, explode_json=None):
    parts = [(os.path.splitext(os.path.basename(p))[0], load_stl(p)) for p in sorted(glob.glob(os.path.join(root, 'parts', '*.stl')))]
    placed = [(os.path.splitext(os.path.basename(p))[0], load_stl(p)) for p in sorted(glob.glob(os.path.join(root, 'placed', '*.stl')))]
    grid(parts, 4, 420, 340).save(os.path.join(out, 'g3_parts.png'))
    render(placed, 1400, 1000, title='G3 gearbox: assembled').save(os.path.join(out, 'g3_assembly.png'))
    inner = [(n, m) for n, m in placed if not any(k in n.lower() for k in ('frame', 'wall', 'cover'))]
    render(inner, 1400, 1000, tilt=0.6, spin=-0.5, title='G3 gearbox: cover and walls removed').save(os.path.join(out, 'g3_gear_train.png'))
    if explode_json:
        off = json.load(open(explode_json))
        ex = [(n, m + np.array(off.get(n, [0, 0, 0]))) for n, m in placed]
        render(ex, 1000, 1400, tilt=0.35, spin=-0.6, title='G3 gearbox: exploded').save(os.path.join(out, 'g3_exploded.png'))
    print('rendered', len(parts), 'parts,', len(placed), 'placed')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
