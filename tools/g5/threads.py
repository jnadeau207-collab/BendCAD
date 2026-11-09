import math

PITCH = {3.0: 0.5, 4.0: 0.7, 5.0: 0.8, 6.0: 1.0, 8.0: 1.25, 10.0: 1.5, 12.0: 1.75}


def f(x):
    return repr(float(x))


def iso_tooth(p, overlap):
    h = 5.0 * math.sqrt(3.0) / 16.0 * p
    root, crest = 0.375 * p, 0.0625 * p
    return h, [(-overlap, -root - overlap * math.tan(math.radians(30.0))), (h, -crest), (h, crest), (-overlap, root + overlap * math.tan(math.radians(30.0)))]


def helix_secs(r_base, z0, length, p, pts, per_turn=16, hand=1.0):
    n = max(2, int(round(length / p * per_turn)) + 1)
    out = []
    for i in range(n):
        th = hand * 2.0 * math.pi * (length / p) * i / (n - 1)
        c, s = math.cos(th), math.sin(th)
        o = (r_base * c, r_base * s, z0 + length * i / (n - 1))
        q = pts + [pts[0]]
        run = ' '.join(f'(run {f(q[j][0])} {f(q[j][1])} {f(q[j + 1][0])} {f(q[j + 1][1])})' for j in range(len(pts)))
        fr = '(frame ' + ' '.join(f(x) for x in (*o, c, s, 0.0, 0.0, 0.0, 1.0, 1.0)) + ')'
        out.append(f'(sec {run} {fr})')
    return ' '.join(out)


def external(nid, d, z0, length, ic, per_turn=16):
    p = PITCH[d]
    h, pts = iso_tooth(p, 0.05)
    r_minor = d / 2.0 - h
    return [f'(node {nid} (skin {helix_secs(r_minor, z0, length, p, pts, per_turn)}) {ic})'], r_minor


def internal(nid, d, z0, length, ic, per_turn=16):
    p = PITCH[d]
    h, pts = iso_tooth(p, 0.05)
    r_minor = d / 2.0 - h
    return [f'(node {nid} (skin {helix_secs(r_minor, z0, length, p, pts, per_turn)}) {ic})'], r_minor
