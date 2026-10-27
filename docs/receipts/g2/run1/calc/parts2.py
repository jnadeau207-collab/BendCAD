import math, subprocess, sys
from geo import *

M, Z, X, BL, HA, NF = 1.75, 12, 0.35, 0.05, 0.88, 8


def gear_path(phase):
    return subprocess.run([sys.executable, 'C:/dev/BendCAD-k2/docs/receipts/g2/gear.py', str(Z), str(M), str(X), repr(phase), str(BL), str(HA), str(NF)],
                          capture_output=True, text=True).stdout.strip()


def hexagon(s):
    R = s / math.sqrt(3)
    p = [(R * math.cos(k * math.pi / 3), R * math.sin(k * math.pi / 3)) for k in range(6)]
    return '(path %s %s %s)' % (repr(p[0][0]), repr(p[0][1]), ' '.join('(line %s %s)' % (repr(x), repr(y)) for x, y in p[1:]))


def keyed_end():
    r, w, yb = 7.9375, 1.985, 5.705
    yk = math.sqrt(r * r - w * w)
    return ('(path %r %r (arc 0 0 %s %s 0 ccw) (arc 0 0 %s 0 %s ccw) (arc 0 0 %s %s 0 ccw) (arc 0 0 %s %r %r ccw) '
            '(line %r %s) (line %r %s))') % (-w, yk, f(r), f(-r), f(r), f(-r), f(r), f(r), f(r), w, yk, w, f(yb), -w, f(yb))


def drive(d):
    g = 'drive'
    d.node('gd_body', '(prism %s %s (region %s))' % (f(ZG), f(ZG + B), gear_path(0.0)), 'create any 0 1 0', g)
    n = d.node('gd_core0', '(prism %s 10 (region %s))' % (f(-(TF + TP)), circle(0, 0, 8)), 'create any 0 1 0', g)
    n = d.node('gd_core', '(pad %d (face %d 0 top) %s (region %s))' % (n, n, f(ZG + B + 14.5 - 10), circle(0, 0, 6)), 'add any any 1 0', g)
    n = d.node('gd_end', '(pad %d (face %d 0 bottom) 31.75 (region %s))' % (n, d.i('gd_core0'), keyed_end()), 'add any any 1 0', g)
    d.node('drive_shaft', '(union %d %d)' % (d.i('gd_body'), n), 'add any any 1 0', g)


def idler(d):
    g = 'idler'
    d.node('gi_body', '(prism %s %s (region %s))' % (f(ZG), f(ZG + B), gear_path(math.pi / 12)), 'create any 0 1 0', g)
    d.node('gi_core', '(prism %s %s (region %s))' % (f(ZG - 14.5), f(ZG + B + 14.5), circle(0, 0, 6)), 'create any 0 1 0', g)
    d.node('idler_shaft', '(union %d %d)' % (d.i('gi_body'), d.i('gi_core')), 'add any any 1 0', g)


SEAL = ('(path 9.4 0 (line 14 0) (line 14 7) (line 12.8 7) (line 12.8 2.6) (line 11.6 2.6) (line 9 6) (line 8 6) '
        '(line 8 5) (line 10.4 1) (line 9.4 1))')


def small(d):
    g = 'small'
    d.node('key', '(box 3.97 3.97 22)', 'create any 0 1 0', g)
    d.node('bushing16', '(prism 0 15 (region %s %s))' % (circle(0, 0, 9), circle(0, 0, 8)), 'create any 0 1 1', g)
    d.node('bushing12', '(prism 0 15 (region %s %s))' % (circle(0, 0, 7), circle(0, 0, 6)), 'create any 0 1 1', g)
    d.node('lip_seal', '(revolve (region %s))' % SEAL, 'create any 0 1 any', g)
    n = d.node('cc_ring', '(prism 0 1.2 (region %s %s))' % (circle(0, 0, 14.7), circle(0, 0, 11.1)), 'create any 0 1 1', g)
    n = d.node('cc_gap', '(pocket %d (face %d 0 top) through (region %s))' % (n, n, rect(-3, 10, 3, 16)), 'remove any any 1 0', g)
    d.node('circlip', '(holes %d (face %d 0 top) through (hole 5.2 11.9 1) (hole -5.2 11.9 1))' % (n, d.i('cc_ring')), 'remove any any 1 2', g)
    d.node('sc_head', '(prism 0 8 (region %s))' % circle(0, 0, 6.5), 'create any 0 1 0', g)
    n = d.node('sc_shank', '(pad %d (face %d 0 bottom) 80 (region %s))' % (d.i('sc_head'), d.i('sc_head'), circle(0, 0, 4)), 'add any any 1 0', g)
    d.node('screw', '(pocket %d (face %d 0 top) 4 (region %s))' % (n, d.i('sc_head'), hexagon(6)), 'remove any any 1 0', g)
    d.node('dw_cyl', '(cylinder 3 50)', 'create any 0 1 0', g)
    d.node('dowel', '(chamfer %d 0.6)' % d.i('dw_cyl'), 'remove any any 1 0', g)


def oring_track(rc):
    return ('(along (path 0 %s (line %s %s) (arc %s 0 %s %s %s ccw) (line 0 %s) (arc 0 0 %s 0 %s ccw)))'
            % (f(-rc), f(A), f(-rc), f(A), f(rc), f(A), f(rc), f(rc), f(rc), f(-rc)))


def oring_xsec():
    h = GD / 2
    a = 3.18 / 2 - h
    return ('(region (path %s %s (line %s %s) (arc %s %s %s %s 0 ccw) (line %s 0) (arc %s %s %s %s %s ccw)))'
            % (f(-a), f(-GD), f(a), f(-GD), f(a), f(-h), f(h), f(a), f(-a), f(-a), f(-h), f(h), f(-a), f(-GD)))


def oring(d):
    d.node('o_ring', '(sweep %s %s)' % (oring_track(RO - 3.18 / 2), oring_xsec()), 'create any any 1 1', 'oring')


def relief():
    return '(region %s) (region %s)' % (rect(9.6, YREL, 12.45, 5.9), rect(9.6, -5.9, 12.45, -YREL))


def front(d):
    g = 'front'
    p = d.node('fc_plate', '(prism %s 0 (region %s))' % (f(-TF), flange()), 'create any 0 1 0', g)
    n = d.node('fc_groove', '(pocket %d (face %d 0 top) %s (region %s %s))' % (p, p, f(GD), stadium(RO), stadium(RI)), 'remove any any 1 any', g)
    n = d.node('fc_bb', '(holes %d (face %d 0 top) 15 (hole 0 0 9))' % (n, p), 'remove any any 1 any', g)
    n = d.node('fc_bbi', '(holes %d (face %d 0 top) 15.5 (hole %s 0 7))' % (n, p, f(A)), 'remove any any 1 any', g)
    n = d.node('fc_seal', '(holes %d (face %d 0 bottom) %s (hole 0 0 14))' % (n, p, f(10.3 - TP)), 'remove any any 1 any', g)
    seal = n
    n = d.node('fc_pilot', '(pad %d (face %d 0 bottom) %s (region %s %s))' % (n, p, f(TP), circle(0, 0, 41.275), circle(0, 0, 14)), 'add any any 1 any', g)
    n = d.node('fc_cav', '(holes %d (face %d n%d.c0.top) 8.55 (hole 0 0 11))' % (n, seal, seal), 'remove any any 1 any', g)
    n = d.node('fc_thru', '(holes %d (face %d 0 top) through (hole 0 0 8.5))' % (n, p), 'remove any any 1 any', g)
    d.node('fc_ring', '(prism -32.25 -30.95 (region %s %s))' % (circle(0, 0, 14.7), circle(0, 0, 13.5)), 'create any 0 1 1', g)
    n = d.node('fc_clip', '(difference %d %d)' % (n, d.i('fc_ring')), 'remove any any 1 any', g)
    n = d.node('fc_drain', '(holes %d (face %d 0 top) 16.5 (hole 11.5 3 1))' % (n, p), 'remove any any 1 any', g)
    n = d.node('fc_relief', '(pocket %d (face %d 0 top) 1 %s)' % (n, p, relief()), 'remove any any 1 any', g)
    n = d.node('fc_taps', '(holes %d (face %d 0 top) 26 %s)' % (n, p, ' '.join('(hole %s %s 3.4)' % (f(x), f(y)) for x, y in SCREWS)), 'remove any any 1 any', g)
    n = d.node('fc_dowels', '(holes %d (face %d 0 top) 8.5 %s)' % (n, p, ' '.join('(hole %s %s 3)' % (f(x), f(y)) for x, y in DOWELS)), 'remove any any 1 any', g)
    d.node('front_cover', '(holes %d (face %d 0 top) through (hole 0 53.2 5.55) (hole 0 -53.2 5.55))' % (n, p), 'remove any any 1 any', g)



def rear(d):
    g = 'rear'
    p = d.node('rc_plate', '(prism %s %s (region %s))' % (f(LB), f(LB + TR), rrect(BX0, -BY, BX1, BY, 4)), 'create any 0 1 0', g)
    n = d.node('rc_bb', '(holes %d (face %d 0 bottom) 15.5 (hole 0 0 7) (hole %s 0 7))' % (p, p, f(A)), 'remove any any 1 any', g)
    n = d.node('rc_relief', '(pocket %d (face %d 0 bottom) 1 %s)' % (n, p, relief()), 'remove any any 1 any', g)
    n = d.node('rc_screws', '(holes %d (face %d 0 bottom) through %s)' % (n, p, ' '.join('(hole %s %s 4.5)' % (f(x), f(y)) for x, y in SCREWS)), 'remove any any 1 any', g)
    n = d.node('rc_dowels', '(holes %d (face %d 0 bottom) 8.5 %s)' % (n, p, ' '.join('(hole %s %s 3)' % (f(x), f(y)) for x, y in DOWELS)), 'remove any any 1 any', g)
    d.node('rear_cover', '(pocket %d (face %d 0 bottom) %s (region %s %s))' % (n, p, f(GD), stadium(RO), stadium(RI)), 'remove any any 1 any', g)
