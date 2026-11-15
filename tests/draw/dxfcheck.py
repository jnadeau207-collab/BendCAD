import math
import re

LAYERS = ('VISIBLE', 'HIDDEN', 'THIN', 'DIM', 'TEXT')
EDGE = ('VISIBLE', 'HIDDEN', 'THIN')


def bbox(out, node):
    m = re.search(r'node %d: ok .*?bbox=\[(\S+), (\S+)\]x\[(\S+), (\S+)\]x\[(\S+), (\S+)\]' % node, out)
    return [float(x) for x in m.groups()] if m else None


def layout(bb):
    wx, wy, wz = bb[1] - bb[0], bb[3] - bb[2], bb[5] - bb[4]
    g = 20.0 + 0.15 * max(wx, wy, wz)
    return {'FRONT': (0.0, wy + g, wx, wz, bb[0], bb[4], 1.0), 'TOP': (0.0, 0.0, wx, wy, bb[0], bb[2], 1.0), 'LEFT': (wx + g, wy + g, wy, wz, -bb[3], bb[4], -1.0)}


def inside(e, ox, oy, w, h):
    xs, ys = (e.dxf.start.x, e.dxf.end.x), (e.dxf.start.y, e.dxf.end.y)
    return ox - 1e-6 <= min(xs) and max(xs) <= ox + w + 1e-6 and oy - 1e-6 <= min(ys) and max(ys) <= oy + h + 1e-6


def model_segs(lines, v):
    ox, oy, w, h, mx, my, sx = v
    return [((e.dxf.start.x - ox + mx, e.dxf.start.y - oy + my), (e.dxf.end.x - ox + mx, e.dxf.end.y - oy + my), e.dxf.layer) for e in lines if inside(e, ox, oy, w, h)]


def check(path, bb):
    from ezdxf import recover
    doc, aud = recover.readfile(path)
    msp = doc.modelspace()
    lines = [e for e in msp if e.dxftype() == 'LINE']
    edges = [e for e in lines if e.dxf.layer in EDGE]
    lay = layout(bb)
    views, segs = {}, {}
    for nm, v in lay.items():
        ox, oy, w, h = v[:4]
        mine = [e for e in edges if inside(e, ox, oy, w, h)]
        vv = [e for e in mine if e.dxf.layer == 'VISIBLE']
        xs = [p for e in vv for p in (e.dxf.start.x, e.dxf.end.x)]
        ys = [p for e in vv for p in (e.dxf.start.y, e.dxf.end.y)]
        views[nm] = dict(visible=len(vv), hidden=sum(e.dxf.layer == 'HIDDEN' for e in mine), thin=sum(e.dxf.layer == 'THIN' for e in mine),
                         w=(max(xs) - min(xs)) if xs else 0.0, h=(max(ys) - min(ys)) if ys else 0.0, want_w=w, want_h=h)
        segs[nm] = model_segs(mine, v)
    placed = sum(v['visible'] + v['hidden'] + v['thin'] for v in views.values())
    zero = sum(1 for e in edges if math.dist((e.dxf.start.x, e.dxf.start.y), (e.dxf.end.x, e.dxf.end.y)) < 1e-9)
    layers = sorted(l.dxf.name for l in doc.layers)
    checks = [('ezdxf audit: no errors', not aud.errors),
              ('layers VISIBLE HIDDEN THIN DIM TEXT and the HIDDEN linetype', all(x in layers for x in LAYERS) and 'HIDDEN' in [lt.dxf.name for lt in doc.linetypes]),
              ('every edge line sits inside its view box', placed == len(edges) and placed > 0),
              ('no zero-length edge lines', zero == 0)]
    for nm, v in views.items():
        checks.append(('%s visible extents equal the certified box (%.4f x %.4f)' % (nm, v['want_w'], v['want_h']),
                       abs(v['w'] - v['want_w']) <= 0.06 + 1e-3 * v['want_w'] and abs(v['h'] - v['want_h']) <= 0.06 + 1e-3 * v['want_h']))
    rec = dict(audit_errors=[str(e.message) for e in aud.errors], layers=layers, lines=len(lines), edge_lines=len(edges), placed=placed, zero_length=zero,
               views=views, texts=[e.dxf.text for e in msp if e.dxftype() == 'TEXT'])
    return rec, checks, segs
