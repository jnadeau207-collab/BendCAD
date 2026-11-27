import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, 'docs', 'receipts', 'g3'))
sys.path.insert(0, os.path.join(ROOT, 'tools', 'g5'))
sys.path.insert(0, os.path.join(ROOT, 'tools', 'g4'))
from blower import snap
from gear import gear_path
import threads as THR

A = '(intent {} any any 1 any)'
IC, IA, IR, IS = (A.format(k) for k in ('create', 'add', 'remove', 'same'))


def f(x):
    return repr(float(x))


def C(req, cmd, judge, info=False, timeout=600):
    return dict(req=req, cmd=cmd, judge=judge, info=info, timeout=timeout)


def NA(req, reason):
    return dict(req=req, cmd=None, judge=('na', reason), info=False)


DRAWING = C('drawing output valid for another tool', ['drawing'], ('drawing_ok',))
NO_STD = 'the kernel holds no {} data; the size was supplied by the agent from memory and nothing checks it against the standard'


def rrect(x0, y0, x1, y1, r):
    return (f'(path {f(x0 + r)} {f(y0)} (line {f(x1 - r)} {f(y0)}) (arc {f(x1 - r)} {f(y0 + r)} {f(r)} {f(x1)} {f(y0 + r)} ccw) '
            f'(line {f(x1)} {f(y1 - r)}) (arc {f(x1 - r)} {f(y1 - r)} {f(r)} {f(x1 - r)} {f(y1)} ccw) (line {f(x0 + r)} {f(y1)}) '
            f'(arc {f(x0 + r)} {f(y1 - r)} {f(r)} {f(x0)} {f(y1 - r)} ccw) (line {f(x0)} {f(y0 + r)}) '
            f'(arc {f(x0 + r)} {f(y0 + r)} {f(r)} {f(x0 + r)} {f(y0)} ccw))')


def keyed_bore(r, b, t2):
    y = math.sqrt(r * r - (b / 2) ** 2)
    h = b / 2
    return f'(path {f(h)} {f(y)} (line {f(h)} {f(r + t2)}) (line {f(-h)} {f(r + t2)}) (line {f(-h)} {f(y)}) (arc 0 0 {f(r)} {f(h)} {f(y)} ccw))'


def blade(cx, cy, R, t, a0, a1, rot, exact=True):
    c, s = math.cos(rot), math.sin(rot)
    rx = lambda x, y: (c * x - s * y, s * x + c * y)
    cc = rx(cx, cy)
    pt = lambda rad, a: rx(cx + rad * math.cos(a), cy + rad * math.sin(a))
    ri, ro = R - t / 2, R + t / 2
    sn = (lambda p, c: snap(p, c)) if exact else (lambda p, c: p)
    i0, i1 = (sn(pt(ri, a), [(cc, ri)]) for a in (a0, a1))
    o1, o0 = (sn(pt(ro, a), [(cc, ro)]) for a in (a1, a0))
    return (f'(region (path {f(i0[0])} {f(i0[1])} (arc {f(cc[0])} {f(cc[1])} {f(R - t / 2)} {f(i1[0])} {f(i1[1])} cw) '
            f'(line {f(o1[0])} {f(o1[1])}) (arc {f(cc[0])} {f(cc[1])} {f(R + t / 2)} {f(o0[0])} {f(o0[1])} ccw)))')


def fan_blade_arc():
    p1 = (9.5, 0.0)
    a = math.radians(-35.0)
    p2 = (28.5 * math.cos(a), 28.5 * math.sin(a))
    R = 22.0
    mx, my = (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2
    dx, dy = p2[0] - p1[0], p2[1] - p1[1]
    L = math.hypot(dx, dy)
    h = math.sqrt(R * R - (L / 2) ** 2)
    cx, cy = mx + h * dy / L, my - h * dx / L
    return cx, cy, R, math.atan2(p1[1] - cy, p1[0] - cx), math.atan2(p2[1] - cy, p2[0] - cx)


S45 = 17.67766952966369

B1 = dict(
    id='B1', sentence='L-bracket, 3 mm plate, two M5 clearance holes per leg, inside fillet', process='sheet or mill', parts=[3],
    notes='Milled from an L profile extruded 30 mm; inside fillet R3 is an arc in the profile; M5 clearance holes from the kernel ISO 273 record (medium series).',
    edits=['(param T 3)', '(param L 40)', '(param W 30)', '(param R 3)',
           '(node 1 (prism 0 W (region (path 0 0 (line L 0) (line L T) (line (+ T R) T) (arc (+ T R) (+ T R) R T (+ T R) cw) (line T L) (line 0 L)))) (intent create any 0 1 0))',
           '(node 2 (holes 1 (face 1 n1.c0.wall.2.0) through (clearance M5 25 -8) (clearance M5 25 -22)) (intent remove any any 1 2))',
           '(node 3 (holes 2 (face 1 n1.c0.wall.4.0) through (clearance M5 25 8) (clearance M5 25 22)) (intent remove any any 1 4))'],
    checks=[C('valid solid', ['check', '3'], ('check_ok',)),
            C('3 mm plate', ['wall', '3'], ('wall_in', 2.999, 3.001)),
            C('two holes per leg (4 through holes)', ['measure', '3'], ('contains', 'through_holes=4')),
            C('inside fillet present (cylinder face in the corner)', ['faces', '3'], ('contains', 'n1.c0.wall.3.0 cylinder')),
            C('M5 clearance diameter to ISO 273', ['std', '3'], ('std', 4, 'clearance M5')),
            C('hole diameter measured', ['faces', '3', '-f'], ('regex', r'(?s)(diameter=\[5\.5, 5\.5\].*){4}')),
            C('3-axis mill reach (ball end mill D6)', ['machine', '3', '6', '20', '10', '40', '3', '3'], ('machinable',), info=True),
            C('makeable on the declared process with standard tools', ['make', 'mill'], ('make_ok',)),
            DRAWING],
    edit=dict(label='plate thickness 3 -> 4 mm', edit='(param T 4)'),
    probes=[dict(name='sheet-metal route: holes on a bent sheet', at='end', note='the brief allows sheet; the sheet route is tried for the record',
                 edits=['(node 50 (flat 80 30 3) (intent create any any 1 any))', '(node 51 (bend 50 (edge 0) 3 90) (intent add any any 1 any))',
                        '(node 52 (holes 51 (face 50 0 top) through (hole 20 15 2.75)) (intent remove any any 1 any))'],
                 then=[['flat', '51', '0.3', '0.5']])])

B2 = dict(
    id='B2', sentence='NEMA 17 motor mount plate: 31 mm bolt square, 22 mm pilot, M3 clearance, two adjustment slots', process='mill', parts=[4],
    notes='60 x 80 x 6 plate; motor centre (30, 30); pilot hole 22.1 for the 22 mm boss; M3 clearance holes from the kernel ISO 273 record; two 5.5 x 13.5 slots for M5, travel 8 mm.',
    edits=['(param S 31)', '(param P 22.1)',
           '(node 1 (box 60 80 6) (intent create 6 0 1 0))',
           '(node 2 (holes 1 (face 1 0 top) through (hole 30 30 (/ P 2))) (intent remove any any 1 1))',
           '(node 3 (holes 2 (face 1 0 top) through (clearance M3 (- 30 (/ S 2)) (- 30 (/ S 2))) (clearance M3 (+ 30 (/ S 2)) (- 30 (/ S 2))) (clearance M3 (- 30 (/ S 2)) (+ 30 (/ S 2))) (clearance M3 (+ 30 (/ S 2)) (+ 30 (/ S 2)))) (intent remove any any 1 5))',
           '(node 4 (pocket 3 (face 1 0 top) through (region (path 14.75 63 (line 14.75 71) (arc 12 71 2.75 9.25 71 ccw) (line 9.25 63) (arc 12 63 2.75 14.75 63 ccw))) (region (path 50.75 63 (line 50.75 71) (arc 48 71 2.75 45.25 71 ccw) (line 45.25 63) (arc 48 63 2.75 50.75 63 ccw)))) (intent remove any any 1 7))',
           '(node 90 (cylinder 10.95 4) (intent create any 0 1 0))', '(node 91 (move 90 30 30 1 0) (intent same any any 1 0))'],
    checks=[C('valid solid', ['check', '4'], ('check_ok',)),
            C('22 mm pilot: gauge pin 21.9 clears by 0.1', ['clearance', '91', '4'], ('clear_in', 0.0999, 0.1001)),
            C('7 through openings (pilot, 4 bolts, 2 slots)', ['measure', '4'], ('contains', 'through_holes=7')),
            C('minimum wall between features >= 3 mm', ['wall', '4'], ('wall_ge', 3.0)),
            C('31 mm bolt square measured', ['std', '4'], ('regex', r'(?s)(?=.*at=\(14\.5,14\.5,6\)[^\n]*status=pass)(?=.*at=\(45\.5,14\.5,6\)[^\n]*status=pass)(?=.*at=\(14\.5,45\.5,6\)[^\n]*status=pass)(?=.*at=\(45\.5,45\.5,6\)[^\n]*status=pass)')),
            C('M3 clearance to ISO 273', ['std', '4'], ('std', 4, 'clearance M3')),
            C('NEMA 17 interface to NEMA ICS 16', ['iface', 'NEMA17', '4', '30', '30', '6'], ('regex', r'^verdict pass$')),
            C('3-axis mill reach (ball end mill D6)', ['machine', '4', '6', '20', '10', '40', '3', '3'], ('machinable',), info=True),
            C('makeable on the declared process with standard tools', ['make', 'mill'], ('make_ok',)),
            DRAWING],
    edit=dict(label='bolt square 31 -> 31.5 mm', edit='(param S 31.5)'),
    probes=[])

HOUSING = ['(param DS 22 H7)',
           '(node 101 (revolve (region (path 9.5 0 (line 32 0) (line 32 6) (line 16 6) (line 16 17.1) (line (/ DS 2) 17.1) (line (/ DS 2) 6.9) (line 9.5 6.9)))) (intent create any 0 1 1))',
           '(node 102 (groove 101 (face 101 n101.c0.wall.5.0) (ring DIN472) 13.9) (intent remove any any 1 1))',
           f'(node 103 (holes 102 (face 101 n101.c0.wall.2.0) through (clearance M5 {S45} {S45}) (clearance M5 -{S45} {S45}) (clearance M5 -{S45} -{S45}) (clearance M5 {S45} -{S45})) (intent remove any any 1 5))']

B3 = dict(
    id='B3', sentence='Flanged housing for a 608 bearing: H7 seat, shoulder, retaining-ring groove, four-bolt flange', process='lathe and mill', parts=[103],
    notes='One revolve profile (seat 22 H7 as an ISO 286 class parameter, zone [22, 22.021] from the tables; hub to z = 17.1 so the land above the ring groove is 2.1 mm: the agent first had 1.5, which the wall check certified as a fail, then exactly 2, which an outward-rounded bound cannot decide against >= 2, shoulder bore 19), flange 64 x 6 with four M5 clearance holes (ISO 273 record) on a 50 PCD at 45 deg, and a DIN 472 groove built by the groove feature from the 22 seat at the bearing end (z 13.9), notched into the revolve profile.',
    edits=HOUSING + ['(node 190 (cylinder 10.9 4) (intent create any 0 1 0))', '(node 191 (move 190 0 0 8 0) (intent same any any 1 0))',
                     '(node 192 (cylinder 9.4 3) (intent create any 0 1 0))', '(node 193 (move 192 0 0 2 0) (intent same any any 1 0))'],
    checks=[C('valid solid', ['check', '103'], ('check_ok',)),
            C('22 H7 seat: gauge pin 21.8 clears by 0.1 at nominal', ['clearance', '191', '103'], ('clear_in', 0.0999, 0.1001)),
            C('shoulder bore 19: gauge pin 18.8 clears by 0.1', ['clearance', '193', '103'], ('clear_in', 0.0999, 0.1001)),
            C('H7 seat zone certified (zone volume over DS in [22, 22.021])', ['zone', '103'], ('regex', r'volume=\[')),
            C('five through openings (bore + four bolt holes)', ['measure', '103'], ('contains', 'through_holes=5')),
            C('minimum wall >= 2 mm', ['wall', '103'], ('wall_ge', 2.0)),
            C('retaining-ring groove to DIN 472', ['std', '103'], ('std', 1, 'ring-groove')),
            C('four M5 flange holes to ISO 273', ['std', '103'], ('std', 4, 'clearance M5')),
            C('H7 tolerance from ISO 286 applied to the seat', ['show'], ('regex', r'^\(param \d+ DS 22 22 22\.021 H7\)$')),
            C('3-axis mill reach (ball end mill D6)', ['machine', '103', '6', '20', '10', '40', '3', '3'], ('machinable',), info=True),
            C('makeable on the declared process (lathe) with standard tools', ['make', 'lathe'], ('make_ok',)),
            DRAWING],
    edit=dict(label='bolt holes M5 -> M6 clearance (5.5 -> 6.6 mm)', edit=f'(node 103 (holes 102 (face 101 n101.c0.wall.2.0) through (clearance M6 {S45} {S45}) (clearance M6 -{S45} {S45}) (clearance M6 -{S45} -{S45}) (clearance M6 {S45} -{S45})) (intent remove any any 1 5))'),
    probes=[dict(name='holes on the half face that does not contain them', at='end',
                 edits=[f'(node 150 (holes 103 (face 101 n101.c0.wall.2.1) through (hole 0 25 1)) (intent remove any any 1 any))']),
            dict(name='fillet on a revolve edge', at='end', edits=['(node 151 (fillet 103 1) (intent remove any any 1 any))'])])

SHAFT = ['(param DK 8 k5)',
         '(node 201 (revolve (region (path 0 0 (line 3.475 0) (line 3.975 0.5) (line 3.975 8) (line (/ DK 2) 8) (line (/ DK 2) 16) (line 5 16) (line 5 40) (line (/ DK 2) 40) (line (/ DK 2) 47) (line 3.995 47) (line 3.995 59.5) (line 3.5 60) (line 0 60)))) (intent create any 0 1 0))',
         '(node 202 (groove 201 (face 201 n201.c0.wall.4.0) (ring DIN471) 8) (intent remove any any 1 0))',
         '(node 204 (keyway 202 (face 201 n201.c0.wall.12.0) +y 10 48.9) (intent remove any any 1 0))',
         '(thread 204 m8 n201.c0.wall.2.0 M8x1 6g 0.5 8)']

B4 = dict(
    id='B4', sentence='8 mm shaft: two k5 bearing seats, shoulder, keyway, ring groove, M8x1 thread, chamfers', process='lathe', parts=[204],
    notes='One revolve profile: M8x1 at 7.95 (6g major window), seat A 8 k5 (an ISO 286 class parameter: zone [8.001, 8.007], modelled at its middle 8.004), shoulder 10, seat B and journal 8, 0.5 chamfers at both ends; a DIN 471 groove built by the groove feature at the start of seat A (z 8) and a DIN 6885-1 keyseat built by the keyway feature on the journal (+y, z 48.9, L 10: at z 49 it ended exactly 1 mm from the shaft end, which an outward-rounded wall bound cannot decide against >= 1).',
    edits=SHAFT,
    checks=[C('valid solid', ['check', '204'], ('check_ok',)),
            C('M8x1 6g thread callout certified', ['threads', '204'], ('contains', 'M8x1 6g', 'status=certified')),
            C('k5 seats zone certified', ['zone', '204'], ('regex', r'volume=\[')),
            C('minimum wall >= 1 mm', ['wall', '204'], ('wall_ge', 1.0)),
            C('ring groove to DIN 471', ['std', '204'], ('std', 1, 'ring-groove')),
            C('keyway to DIN 6885', ['std', '204'], ('std', 1, 'keyway')),
            C('k5 class from ISO 286 applied to the seats', ['show'], ('regex', r'^\(param \d+ DK 8 8\.001 8\.007 k5\)$')),
            C('makeable on the declared process (lathe) with standard tools', ['make', 'lathe'], ('make_ok',)),
            DRAWING],
    edit=dict(label='seat diameter 8.004 -> 8.006', edit='(param DK 8.006 8.001 8.007)'),
    probes=[dict(name='thread callout on the other half of the split cylinder', at='end',
                 edits=['(thread 204 m8b n201.c0.wall.2.1 M8x1 6g 0.5 8)'])])

COLLAR = ['(node 301 (prism 0 10.2 (region (circle 0 0 12) (circle 0 0 4))) (intent create any 0 1 1))',
          '(node 302 (box 10 1 12) (intent create any 0 1 0))', '(node 303 (move 302 3 -0.5 -1 0) (intent same any any 1 0))',
          '(node 304 (difference 301 303) (intent remove any any 1 0))',
          '(node 305 (cylinder 4 8) (intent create any 0 1 0))', '(node 306 (move 305 8 -4.5 5.1 4) (intent same any any 1 0))',
          '(node 307 (difference 304 306) (intent remove any any 1 0))',
          '(node 308 (cylinder 2.25 5) (intent create any 0 1 0))', '(node 309 (move 308 8 0 5.1 4) (intent same any any 1 0))',
          '(node 310 (difference 307 309) (intent remove any any 1 any))',
          '(node 311 (cylinder 1.65 13) (intent create any 0 1 0))', '(node 312 (move 311 8 13 5.1 4) (intent same any any 1 0))',
          '(node 313 (difference 310 312) (intent remove any any 1 any))',
          '(thread 313 m4 n311.c0.wall.0.0 M4 6H 0.5 7)']

B5 = dict(
    id='B5', sentence='Split shaft collar for 8 mm with an M4 cap screw: counterbore one side, tapped the other', process='mill', parts=[313],
    notes='Ring 24 x 8 x 10.2 with a 1 mm split in C45 steel (10 thick left exactly 1 mm above and below the 8 mm counterbore, which an outward-rounded wall bound cannot decide against >= 1); screw axis along y at x = 8, z = 5.1: counterbore 8 dia to y = -4.5 (DIN 974-1 for ISO 4762 M4), clearance 4.5, tap drill 3.3 with an M4 6H callout; an ISO 4762 M4 x 10 screw (a catalog part, bought) seated on the counterbore floor with its tip at y = 5.5, inside the 0.5-7 thread (an M4 x 12 reaches y = 7.5 and jams in the untapped drill past the thread, which fasten reports as interference).',
    edits=COLLAR + ['(material 313 C45 7850 11.5e-6)', '(node 314 (screw ISO4762 M4 10) (intent create any 0 1 0))',
                    '(node 315 (rotate 314 x 90) (intent same any any 1 0))', '(node 316 (move 315 8 5.5 5.1 0) (intent same any any 1 0))'],
    checks=[C('valid solid', ['check', '313'], ('check_ok',)),
            C('M4 6H tapped side certified', ['threads', '313'], ('contains', 'M4x0.7 6H', 'status=certified')),
            C('minimum wall >= 1 mm', ['wall', '313'], ('wall_ge', 1.0)),
            C('counterbore and clearance to DIN 974-1 / ISO 273', ['fasten', '316', '313'], ('regex', r'^fasten holes .*\(DIN 974-1 for ISO 4762 M4\) .*\(ISO 273 \w+\) status=pass$')),
            C('cap screw fits (head in counterbore, thread engagement)', ['fasten', '316', '313'], ('regex', r'^verdict pass$')),
            C('3-axis mill reach (ball end mill D6)', ['machine', '313', '6', '20', '10', '40', '3', '3'], ('machinable',), info=True),
            C('makeable on the declared process with standard tools', ['make', 'mill'], ('make_ok',)),
            DRAWING],
    edit=dict(label='collar OD 24 -> 25 mm', edit='(node 301 (prism 0 10.2 (region (circle 0 0 12.5) (circle 0 0 4))) (intent create any 0 1 1))'),
    probes=[dict(name='counterbore as a feature on the collar (holes on a curved face)', at='end',
                 edits=['(node 350 (holes 304 (face 301 n301.c0.wall.0.0) 4 (hole 0 0 4)) (intent remove any any 1 any))']),
            dict(name='thread span stated in the cylinder local frame', at='end', edits=['(thread 313 m4c n311.c0.wall.0.0 M4 6H 0 8)'])])

G20 = gear_path(20, m=1.0, backlash=0.05)
G40 = gear_path(40, m=1.0, backlash=0.05, phase=math.pi / 40)

B6 = dict(
    id='B6', sentence='Spur gear pair, module 1, 20 and 40 teeth, bores with keyways, centre distance certified', process='mill or print', parts=[4, 5],
    notes='Tooth outlines are polylines from docs/receipts/g3/gear.py (4 flank stations, 0.05 backlash): the kernel has no involute or gear feature. Bores 8 and 10 with DIN 6885-1 hub keyways built by the keyway feature from the records (2 wide, t2 1.0; 3 wide, t2 1.4); the 6 mm pinion bore the agent first drew has no DIN 6885-1 row (the table starts over 6 mm), and its hand-drawn 2 x 1.0 keyways were not checked against anything. Face width 8.',
    edits=[f'(node 1 (prism 0 8 (region {G20} (circle 0 0 4))) (intent create any 0 1 1))',
           f'(node 2 (prism 0 8 (region {G40} (circle 0 0 5))) (intent create any 0 1 1))',
           '(node 4 (keyway 1 (face 1 n1.c1.wall.0.0) +y through) (intent remove any any 1 1))',
           '(node 5 (keyway 2 (face 2 n2.c1.wall.0.0) +y through) (intent remove any any 1 1))',
           '(node 3 (move 5 30 0 0 0) (intent same any any 1 1))'],
    checks=[C('gear 20 valid', ['check', '4'], ('check_ok',)),
            C('gear 40 valid', ['check', '5'], ('check_ok',)),
            C('centre distance 30 from the solved assembly', ['asm', 'solve', '(assembly (inst p 4 0 0 0 0) (inst w 5 30 0 0 0) (fix 1 p) (fix 2 w))'], ('contains', 'w', '30')),
            C('mesh gap over one pitch > 0 (no interference while turning)', ['asm', 'mesh', 'p', '20', 'w', '40', '(assembly (inst p 4 0 0 0 0) (inst w 5 30 0 0 0) (fix 1 p) (fix 2 w))'], ('gap_in', 1e-6, 0.2)),
            C('gears disjoint at assembly', ['interf', '4', '3'], ('relation', 'disjoint'), timeout=1200),
            NA('involute profile to ISO 53 / ISO 21771', 'no involute or gear generator; the polyline approximates the involute at 4 radii and nothing certifies conjugate action or backlash'),
            C('pinion keyway to DIN 6885-1', ['std', '4'], ('std', 1, 'keyway')),
            C('wheel keyway to DIN 6885-1', ['std', '5'], ('std', 1, 'keyway')),
            C('makeable on the declared process with standard tools', ['make', 'mill|fdm'], ('make_ok',)),
            DRAWING],
    edit=dict(label='face width 8 -> 10 mm (gear 20)', edit=f'(node 1 (prism 0 10 (region {G20} (circle 0 0 4))) (intent create any 0 1 1))'),
    probes=[])

B7_BODY = ['(param H 30)',
           f'(node 701 (prism 0 H (region {rrect(0, 0, 100, 60, 6)})) (intent create any 0 1 0))',
           f'(node 702 (pocket 701 (face 701 0 top) (- H 2) (region {rrect(2, 2, 98, 58, 4)})) (intent remove any any 1 0))',
           '(node 703 (pad 702 (face 702 n702.c0.top) 24 (region (circle 8 8 3.5)) (region (circle 92 8 3.5)) (region (circle 8 52 3.5)) (region (circle 92 52 3.5))) (intent add any any 1 0))',
           '(node 704 (holes 703 (face 703 n703.c0.top) 6 (hole 8 8 2) (hole 92 8 2) (hole 8 52 2) (hole 92 52 2)) (intent remove any any 1 0))',
           '(node 705 (holes 704 (face 701 n701.c0.wall.2.0) 3 (hole 30 15 4)) (intent remove any any 1 1))']
B7_LID = [f'(node 711 (prism 0 2 (region {rrect(0, 0, 100, 60, 6)})) (intent create any 0 1 0))',
          f'(node 712 (pad 711 (face 711 0 bottom) 3 (region {rrect(2.2, 2.2, 97.8, 57.8, 3.8)} {rrect(3.8, 3.8, 96.2, 56.2, 2.2)})) (intent add any any 1 any))',
          '(node 713 (holes 712 (face 711 0 top) through (hole 8 8 1.7) (hole 92 8 1.7) (hole 8 52 1.7) (hole 92 52 1.7)) (intent remove any any 1 any))',
          '(node 714 (move 713 0 0 H 0) (intent same any any 1 any))']
ASM7 = '(assembly (inst body 705 0 0 0 0) (inst lid 713 0 0 30 0) (fix 1 body) (fix 2 lid))'

B7 = dict(
    id='B7', sentence='Electronics enclosure 100 x 60 x 30 with lid, four M3 insert bosses, rounded edges, cable port', process='print', parts=[705, 713],
    notes='Body: rounded-rectangle prism (R6), 2 mm walls and floor, four 7 mm bosses with 4.0 x 6 heat-set insert holes, 8 mm cable port in the +x wall. Lid: 2 mm plate with a 1.6 mm locating lip (0.2 clearance to the wall) and four 3.4 holes; placed at z = 30.',
    edits=B7_BODY + B7_LID,
    checks=[C('body valid', ['check', '705'], ('check_ok',)),
            C('lid valid', ['check', '713'], ('check_ok',)),
            C('lid does not interfere with body', ['interf', '705', '714'], ('relation', 'disjoint')),
            C('lip-to-wall clearance 0.2 (z-extruded gap)', ['asm', 'gap', 'lid', 'body', *[f'n702.c0.wall.{i}.0' for i in range(8)], ASM7], ('gap_in', 0.1999, 0.2001)),
            C('printable wall >= 1.2 mm (body)', ['wall', '705'], ('wall_ge', 1.2)),
            C('four bosses with insert holes (pad + holes committed, faces present)', ['faces', '705'], ('contains', 'n704.c0.wall.0.0', 'n704.c3.wall.0.0')),
            C('cable port opening present', ['faces', '705'], ('contains', 'n705.c0.wall.0.0')),
            C('vertical edges rounded (corner cylinders)', ['faces', '705'], ('contains', 'n701.c0.wall.1.0 cylinder')),
            NA('outer top and bottom edges rounded', 'fillet takes only a box, a cylinder, a box vertical edge or a circular edge; a fillet along a rounded-rectangle edge loop is refused (probe)'),
            NA('M3 heat-set insert hole to the insert maker', NO_STD.format('heat-set insert')),
            C('makeable by FDM/SLA (overhang, bridging, min feature)', ['make', 'fdm'], ('make_ok',)),
            DRAWING],
    edit=dict(label='enclosure height 30 -> 32 mm', edit='(param H 32)'),
    probes=[dict(name='fillet the outer edges of the rounded-rectangle body', at='end', edits=['(node 750 (fillet 701 2) (intent remove any any 1 any))']),
            dict(name='shell the body (shell on a prism)', at='end', edits=['(node 751 (shell 701 2 open) (intent remove any any 1 any))']),
            dict(name='insert holes addressed by pad cell face (face 703 0 top)', at='end',
                 edits=['(node 752 (holes 703 (face 703 0 top) 6 (hole 8 8 2) (hole 92 8 2) (hole 8 52 2) (hole 92 52 2)) (intent remove any any 1 0))'],
                 then=[['faces', '752'], ['step', '752', '/var/tmp/briefs/B7/probe_cav.stp']]),
            dict(name='lip gap with the body first (all faces)', at='end', edits=[], then=[['asm', 'gap', 'body', 'lid', ASM7]])])

FL = ['(param GD 2.65)',
      '(node 801 (revolve (region (path 30.75 0 (line 82.5 0) (line 82.5 18) (line 51 18) (line 51 20) (line 42.8 20) (line 42.8 (- 20 GD)) (line 38 (- 20 GD)) (line 38 20) (line 30.75 20)))) (intent create any 0 1 1))',
      f'(node 802 (holes 801 (face 801 n801.c0.wall.2.0) through (hole 44.19417382415922 44.19417382415922 9) (hole -44.19417382415922 44.19417382415922 9) (hole -44.19417382415922 -44.19417382415922 9) (hole 44.19417382415922 -44.19417382415922 9)) (intent remove any any 1 5))',
      '(node 803 (torus 41.035 1.765) (intent create any 0 1 1))', '(node 804 (move 803 0 0 (+ (- 20 GD) 1.765) 0) (intent same any any 1 1))']

B8 = dict(
    id='B8', sentence='Pipe flange with bolt circle, raised face and O-ring groove to the standard', process='lathe and mill', parts=[802, 803],
    notes='EN 1092-1 type 01 DN50 PN16 as remembered by the agent: D 165, bore 61.5, thickness 18, K 125 with 4 x 18 holes, raised face d1 102 x 2. Face O-ring groove 4.8 x 2.65 at ID 76 for a 3.53 cord (Parker-style face-seal gland); O-ring seated against the outer groove wall.',
    edits=FL,
    checks=[C('flange valid', ['check', '802'], ('check_ok',)),
            C('O-ring valid', ['check', '803'], ('check_ok',)),
            C('O-ring seated in the groove without interference', ['interf', '802', '804'], ('relation', 'disjoint')),
            C('O-ring touches the groove (clearance 0)', ['clearance', '802', '804'], ('clear_in', 0.0, 1e-6)),
            C('five through openings (bore + 4 bolt holes)', ['measure', '802'], ('contains', 'through_holes=5')),
            NA('flange dimensions to EN 1092-1 / ASME B16.5', NO_STD.format('EN 1092-1 / ASME B16.5 flange')),
            NA('O-ring groove and squeeze to ISO 3601-2', NO_STD.format('ISO 3601 O-ring and gland') + '; no seal squeeze or gland-fill check'),
            dict(C('makeable on the declared process with standard tools', ['make', 'lathe'], ('make_ok',)), bought={803: 'O-ring 3.53 cord, moulded elastomer, a catalog part'}),
            DRAWING],
    edit=dict(label='groove depth 2.65 -> 2.7 mm', edit='(param GD 2.7)'),
    probes=[])

def leaf(sign):
    xa = 2.8284271247461903
    if sign < 0:
        return f'(region (path -25 -1 (line -{xa} -1) (arc 0 0 3 -{xa} 1 ccw) (line -25 1)) (circle 0 0 1.6))'
    return f'(region (path 25 -1 (line {xa} -1) (arc 0 0 3 {xa} 1 cw) (line 25 1)) (circle 0 0 1.6))'


HINGE = [f'(node 901 (prism 0 40 {leaf(-1)}) (intent create any 0 1 1))',
         '(node 902 (cylinder 3.4 10.4) (intent create any 0 1 0))', '(node 903 (move 902 0 0 9.8 0) (intent same any any 1 0))',
         '(node 904 (move 902 0 0 29.8 0) (intent same any any 1 0))',
         '(node 905 (difference 901 903) (intent remove any any any any))', '(node 906 (difference 905 904) (intent remove any any any any))',
         f'(node 911 (prism 0 40 {leaf(1)}) (intent create any 0 1 1))',
         '(node 912 (move 902 0 0 -0.2 0) (intent same any any 1 0))', '(node 913 (move 902 0 0 19.8 0) (intent same any any 1 0))',
         '(node 914 (difference 911 912) (intent remove any any any any))', '(node 915 (difference 914 913) (intent remove any any any any))',
         '(node 921 (cylinder 1.5 40) (intent create any 0 1 0))',
         '(node 931 (rotate 915 z 60) (intent same any any any any))', '(node 932 (rotate 915 z 90) (intent same any any any any))',
         '(node 933 (rotate 915 z 120) (intent same any any any any))', '(node 934 (rotate 915 z 175) (intent same any any any any))']

B9 = dict(
    id='B9', sentence='Butt hinge: two leaves, knuckles, pin, clearance certified through the swing', process='mill', parts=[906, 915, 921],
    notes='Swing 0-120 deg (leaf B rotated about the pin axis from flat open). Leaves 25 x 2 centred on the pin axis, with knuckle OD 6 and 3.2 pin bore, 4 knuckles of 9.6 with 0.4 axial gaps, 0.4 radial relief cut around the mating knuckles; pin 3.0. Swing sampled by rotating leaf B about the pin axis.',
    edits=HINGE,
    checks=[C('leaf A valid', ['check', '906'], ('check_ok',)),
            C('leaf B valid', ['check', '915'], ('check_ok',)),
            C('pin to leaf A clearance 0.1', ['clearance', '921', '906'], ('clear_in', 0.0999, 0.1001)),
            C('pin to leaf B clearance 0.1', ['clearance', '921', '915'], ('clear_in', 0.0999, 0.1001)),
            C('leaves clear at 0 deg', ['clearance', '906', '915'], ('clear_ge', 0.3)),
            C('leaves clear at 60 deg', ['clearance', '906', '931'], ('clear_ge', 0.3)),
            C('leaves clear at 90 deg', ['clearance', '906', '932'], ('clear_ge', 0.3)),
            C('leaves clear at 120 deg', ['clearance', '906', '933'], ('clear_ge', 0.3)),
            C('closing limit: leaves meet before 175 deg (expected interference)', ['interf', '906', '934'], ('relation', 'interference'), info=True),
            NA('clearance certified through the whole swing', 'no certified clearance over a motion range: assemblies fix orientations (quarter turns) and asm mesh rotates only z-extruded gear traces; the swing is sampled at 4 angles'),
            C('3-axis mill reach leaf A (ball end mill D3)', ['machine', '906', '3', '20', '6', '40', '3', '3'], ('machinable',), info=True),
            C('makeable on the declared process with standard tools', ['make', 'mill'], ('make_ok',)),
            DRAWING],
    edit=dict(label='pin 3.0 -> 2.9 mm', edit='(node 921 (cylinder 1.45 40) (intent create any 0 1 0))'),
    probes=[dict(name='hinge as an assembly with a rotated instance', at='end',
                 edits=[], then=[['asm', 'clear', '(assembly (inst a 906 0 0 0 0) (inst b 915 0 0 0 1) (fix 1 a) (fix 2 b))']])])

RB = THR.d1(3.0, 0.5) / 2
B10 = dict(
    id='B10', sentence='M3 x 10 hex standoff with a tapped through hole, thread modelled', process='lathe', parts=[1001],
    notes='Hex AF 5.5 x 10 (ISO 4032 M3 record) with a tapped M3 6H through hole from the kernel record (ISO 2306 tap drill 2.5, callout bound by the feature), its ISO 68-1 thread modelled as four exact helicoid faces by the hole feature itself. Aluminium 6082-T6, as aluminium hex standoffs are made: the 10 mm through thread is deeper than the 3 x D = 9 rating of a standard tap and is cut by an extra-long non-ferrous tap rated 4 x D.',
    edits=['(node 1000 (prism 0 10 (region (path 3.1754264805429417 0 (line 1.5877132402714709 2.75) (line -1.5877132402714709 2.75) (line -3.1754264805429417 0) (line -1.5877132402714709 -2.75) (line 1.5877132402714709 -2.75)))) (intent create any 0 1 0))',
           '(node 1001 (holes 1000 (face 1000 0 top) through (tapped M3 0 0 modelled)) (intent remove any any 1 1))', '(material 1001 6082-T6 2700 23.4e-6)'],
    checks=[C('valid solid', ['check', '1001'], ('check_ok',)),
            C('M3 6H callout certified', ['threads', '1001'], ('contains', 'M3x0.5 6H', 'modelled', 'status=certified')),
            C('thread modelled (helical flank faces present)', ['faces', '1001', '-f'], ('contains', 'helicoid', 'flank half-angle=30')),
            C('minimum wall >= 0.8 mm', ['wall', '1001'], ('wall_ge', 0.8)),
            C('hex across flats 5.5 to ISO 272 / standoff catalog', ['faces', '1001', '-f'], ('regex', r'(?s)(?=.*frame o=\([^,]+,2\.75,[^)]*\)[^\n]*n=\(0,1,0\))(?=.*frame o=\([^,]+,-2\.75,[^)]*\)[^\n]*n=\(0,-1,0\))')),
            C('tapped M3 6H through hole to ISO 2306 / ISO 965-1', ['std', '1001'], ('std', 1, 'tapped M3')),
            C('makeable on the declared process with standard tools', ['make', 'lathe'], ('make_ok',)),
            DRAWING],
    check_partial=True,
    edit=dict(label='length 10 -> 12 mm', edit='(node 1000 (prism 0 12 (region (path 3.1754264805429417 0 (line 1.5877132402714709 2.75) (line -1.5877132402714709 2.75) (line -3.1754264805429417 0) (line -1.5877132402714709 -2.75) (line 1.5877132402714709 -2.75)))) (intent create any 0 1 0))'),
    probes=[dict(name='callout on a bore at the basic minor diameter d1 = 2.4587', at=0,
                 edits=[f'(node 1050 (prism 0 10 (region (circle 0 0 4) (circle 0 0 {f(RB)}))) (intent create any 0 1 1))', '(thread 1050 m3b n1050.c1.wall.0.0 M3 6H 0 10)']),
            dict(name='full-length modelled thread on a hex whose bore is exactly d1/2 (the tools/g5 thr_cases t5 construction)', at=0,
                 edits=[f'(node 1070 (prism 0 10 (region (path 3.1754264805429417 0 (line 1.5877132402714709 2.75) (line -1.5877132402714709 2.75) (line -3.1754264805429417 0) (line -1.5877132402714709 -2.75) (line 1.5877132402714709 -2.75)) (circle 0 0 {f(RB)}))) (intent create any 0 1 1))',
                        THR.int_helix(1071, 3.0, -0.3, 10.6, IC), '(node 1072 (difference 1070 1071) (intent remove any any 1 any))']),
            dict(name='smallest modelled thread: one turn (0.5 mm) of internal helix differenced from a block', at=0,
                 edits=['(node 1060 (box 8 8 1.5) (intent create any 0 1 0))', '(node 1061 (move 1060 -4 -4 0 0) (intent same any any 1 0))',
                        f'(node 1062 (cylinder {f(RB)} 2.5) (intent create any 0 1 0))', '(node 1063 (move 1062 0 0 -0.5 0) (intent same any any 1 0))',
                        '(node 1064 (difference 1061 1063) (intent remove any any 1 any))', THR.int_helix(1065, 3.0, 0.2, 1.0, IC),
                        '(node 1066 (difference 1064 1065) (intent remove any any 1 any))'])])

B11 = dict(
    id='B11', sentence='Handwheel: revolved rim and hub, three spokes, D-bore', process='print', parts=[1110],
    notes='Rim: revolve of a 10 mm circle at R 50; hub: revolve 20 x 16; spokes: 7 mm cylinders from r 7 to 49 at 0/120/240 deg; D-bore 8 with a flat at 3.5.',
    edits=['(node 1101 (revolve (region (circle 50 0 5))) (intent create any 0 1 1))',
           '(node 1102 (revolve (region (path 0 -8 (line 10 -8) (line 10 8) (line 0 8)))) (intent create any 0 1 0))',
           '(node 1103 (cylinder 3.5 42) (intent create any 0 1 0))', '(node 1104 (move 1103 7 0 0 5) (intent same any any 1 0))',
           '(node 1105 (rotate 1104 z 120) (intent same any any 1 0))', '(node 1106 (rotate 1104 z 240) (intent same any any 1 0))',
           '(node 1107 (union 1102 1104) (intent add any any 1 any))', '(node 1108 (union 1107 1105) (intent add any any 1 any))',
           '(node 1109 (union 1108 1106) (intent add any any 1 any))', '(node 1111 (union 1109 1101) (intent add any any 1 any))',
           '(node 1112 (prism -10 10 (region (path 3.5 -1.9364916731037085 (line 3.5 1.9364916731037085) (arc 0 0 4 3.5 -1.9364916731037085 ccw)))) (intent create any 0 1 0))',
           '(node 1110 (difference 1111 1112) (intent remove any any 1 any))'],
    checks=[C('valid solid', ['check', '1110'], ('check_ok',)),
            C('one solid with rim, hub and three spokes (genus 3 + bore = 4)', ['measure', '1110'], ('contains', 'solids=1', 'through_holes=4')),
            C('printable wall >= 1.2 mm', ['wall', '1110'], ('wall_ge', 1.2)),
            NA('D-bore to the mating shaft standard', NO_STD.format('D-shaft')),
            C('makeable by FDM/SLA (overhang, bridging, min feature)', ['make', 'fdm'], ('make_ok',)),
            DRAWING],
    edit=dict(label='spoke diameter 7 -> 8 mm', edit='(node 1103 (cylinder 4 42) (intent create any 0 1 0))'),
    probes=[])

B12 = dict(
    id='B12', sentence='Bearing cap with a pocket, two ribs and four countersunk holes', process='mill', parts=[1208],
    notes='80 x 50 x 14 block, 32 x 6 bearing pocket from below, two 48 x 4 x 6 ribs on top, four M5 countersunk holes from the kernel record (ISO 273 medium bore, DIN 74 F 90 degree countersink to 11.47 for ISO 10642).',
    edits=['(node 1201 (box 80 50 14) (intent create 6 0 1 0))',
           '(node 1202 (pocket 1201 (face 1201 0 bottom) 6 (region (circle 40 25 16))) (intent remove any any 1 0))',
           '(node 1203 (pad 1202 (face 1201 0 top) 6 (region (path 16 10 (line 64 10) (line 64 14) (line 16 14))) (region (path 16 36 (line 64 36) (line 64 40) (line 16 40)))) (intent add any any 1 0))',
           '(node 1208 (holes 1203 (face 1201 0 top) through (countersink M5 6 6) (countersink M5 74 6) (countersink M5 6 44) (countersink M5 74 44)) (intent remove any any 1 4))'],
    checks=[C('valid solid', ['check', '1208'], ('check_ok',)),
            C('four through holes', ['measure', '1208'], ('contains', 'through_holes=4')),
            C('countersink cones present', ['faces', '1208'], ('contains', 'cone')),
            C('minimum wall >= 3 mm', ['wall', '1208'], ('wall_ge', 3.0)),
            C('countersink to ISO 10642 / ISO 15065', ['std', '1208'], ('std', 4, 'countersink M5')),
            C('3-axis mill reach (ball end mill D6)', ['machine', '1208', '6', '20', '10', '40', '3', '3'], ('machinable',), info=True),
            C('makeable on the declared process with standard tools', ['make', 'mill'], ('make_ok',)),
            DRAWING],
    edit=dict(label='countersunk screws M5 -> M4', edit='(node 1208 (holes 1203 (face 1201 0 top) through (countersink M4 6 6) (countersink M4 74 6) (countersink M4 6 44) (countersink M4 74 44)) (intent remove any any 1 4))'),
    probes=[])

BEARING = ['(node 401 (bearing 608 outer) (intent create any any 1 1))', '(node 402 (bearing 608 inner) (intent create any any 1 1))',
           '(node 403 (bearing 608 balls) (intent create any any 7 0))', '(node 404 (bearing 608 cage) (intent create any any 1 1))',
           '(material 401 100Cr6 7810 11.5e-6)', '(material 402 100Cr6 7810 11.5e-6)', '(material 403 100Cr6 7810 11.5e-6)', '(material 404 PEEK-GF30 1510 18e-6)',
           '(material 103 6082-T6 2700 23.4e-6)', '(material 204 C45 7850 11.5e-6)', '(material 313 C45 7850 11.5e-6)']
ASM13 = ('(assembly (inst housing 103 0 0 0 0) (inst bearing 401 0 0 0 0) (inst inner 402 0 0 0 0) (inst balls 403 0 0 0 0) (inst cage 404 0 0 0 0) '
         '(inst shaft 204 0 0 0 0) (inst collar 313 0 0 0 0) (fix 1 housing) '
         '(coinc 2 bearing 0 0 0 housing 0 0 6.9) (coinc 3 shaft 0 0 8.9 bearing 0 0 0) (coinc 4 collar 0 0 0 shaft 0 0 47.5) '
         '(coinc 5 inner 0 0 0 bearing 0 0 0) (coinc 6 balls 0 0 0 bearing 0 0 0) (coinc 7 cage 0 0 0 bearing 0 0 0))')
ASM13P = ASM13[:-1] + ' (press inner inner n402.c0.wall.7.0 shaft n201.c0.wall.6.0))'
ASM608 = ('(assembly (inst outer 401 0 0 0 0) (inst inner 402 0 0 0 0) (inst balls 403 0 0 0 0) (inst cage 404 0 0 0 0) (fix 1 outer) '
          '(coinc 2 inner 0 0 0 outer 0 0 0) (coinc 3 balls 0 0 0 outer 0 0 0) (coinc 4 cage 0 0 0 outer 0 0 0))')

B13 = dict(
    id='B13', sentence='Assembly of B3, B4, B5 and a 608 bearing: fits, clearances and interference certified', process='-', parts=[103, 204, 313, 401, 402, 403, 404],
    notes='The B3, B4 and B5 edits verbatim in one design, a 608 bearing as four parts built by the bearing feature from the kernel catalog record (SKF 608 boundary dimensions and ratings, NSK ball set, GMN pitch and land diameters; balls at the mean CN radial clearance of JTEKT Table 10-2; groove conformity 0.52 assumed; crown cage in PEEK-GF30 at design proportions), materials on all seven, and one assembly form mated by coincident points.',
    edits=HOUSING + SHAFT + COLLAR + BEARING,
    checks=[C('assembly solves (fully constrained)', ['asm', 'solve', ASM13], ('regex', r'dof 0|dof=0')),
            C('no interference between any pair except the declared inner-ring press fit', ['asm', 'interf', ASM13P], ('absent_interference',)),
            C('pairwise clearances certified', ['asm', 'clear', ASM13], ('regex', r'status=certified')),
            C('housing seat H7 on bearing OD (h5 = ISO 492 normal for 22 mm)', ['pmi', 'fits', '(pmi (node 103) (temp cold 20) (temp hot 60) (fit seat 103 n101.c0.wall.9.0 401 n401.c0.wall.2.0 H7/h5 clearance))'], ('fits',)),
            C('bearing bore (ISO 492 Normal, L0) on the k5 shaft seat: interference at 20 and 60 C', ['pmi', 'fits', '(pmi (node 402) (temp cold 20) (temp hot 60) (fit bore 402 n402.c0.wall.7.0 204 n201.c0.wall.6.0 L0/k5 press))'], ('fits',)),
            C('assembly mass', ['asm', 'mass', ASM13], ('regex', r'total')),
            NA('collar clamping on the shaft', 'no clamp/preload or screw-torque check'),
            C('608 outer ring from the catalog record', ['std', '401'], ('std', 1, 'bearing')),
            C('608 inner ring from the catalog record', ['std', '402'], ('std', 1, 'bearing')),
            C('608 ball set from the catalog record (count, diameter, pitch circle)', ['std', '403'], ('std', 1, 'bearing')),
            C('608 cage between the ring lands', ['std', '404'], ('std', 1, 'bearing')),
            C('608 mass against the catalog 0.012 kg (given to the gram)', ['asm', 'mass', ASM608], ('mass_in', 0.0115, 0.0125)),
            DRAWING],
    edit=dict(label='housing seat nominal 22 -> 22.01', edit='(param DS 22.01 22 22.021)'),
    probes=[dict(name='asm solve with the press declaration in the assembly form', at='end', edits=[], then=[['asm', 'solve', ASM13P]]),
            dict(name='asm interf without declaring the press fit', at='end', edits=[], then=[['asm', 'interf', ASM13]])])

FAN = fan_blade_arc()
FAN_BLADES = ' '.join(blade(FAN[0], FAN[1], FAN[2], 1.2, FAN[3], FAN[4], k * math.pi / 4) for k in range(8))
B14 = dict(
    id='B14', sentence='Small radial fan wheel with eight backward-curved blades on a hub with a bore', process='print', parts=[1403],
    notes='Revolved back plate 60 x 2 with hub 16 x 10 and 5 mm bore; eight 1.2 mm circular-arc blades (R22, root r 9.5, tip r 28.5, 35 deg wrap backward), z 1.5..14, built as one prism of eight computed regions and unioned with the plate.',
    edits=['(node 1401 (revolve (region (path 2.5 0 (line 30 0) (line 30 2) (line 8 2) (line 8 10) (line 2.5 10)))) (intent create any 0 1 1))',
           f'(node 1402 (prism 1.5 14 {FAN_BLADES}) (intent create any 0 8 0))',
           '(node 1403 (union 1401 1402) (intent add any any 1 1))',
           '(material 1403 PLA 1240 68e-6 3500 0.36)'],
    checks=[C('valid solid', ['check', '1403'], ('check_ok',)),
            C('one solid (blades fused to plate)', ['measure', '1403'], ('contains', 'solids=1')),
            C('balanced to G6.3 at 3000 rpm', ['balance', '1403', '0', '0', '0', '0', '0', '1', '3000', '6.3'], ('contains', 'within')),
            C('printable wall >= 1.0 mm', ['wall', '1403'], ('wall_ge', 1.0)),
            NA('blade angles / fan performance', 'no fan or flow analysis'),
            C('makeable by FDM/SLA (overhang, bridging, min feature)', ['make', 'fdm'], ('make_ok',)),
            DRAWING],
    edit=dict(label='blade height 14 -> 16 mm', edit=f'(node 1402 (prism 1.5 16 {FAN_BLADES}) (intent create any 0 8 0))'),
    probes=[dict(name='blade arcs with endpoints computed by cos/sin (no ulp snap)', at=0,
                 edits=[f'(node 1449 (prism 1.5 14 {blade(FAN[0], FAN[1], FAN[2], 1.2, FAN[3], FAN[4], 0.0, exact=False)}) (intent create any 0 1 0))']),
            dict(name='one blade plus an 8-way circular pattern', at='end',
                 edits=[f'(node 1450 (prism 1.5 14 {blade(FAN[0], FAN[1], FAN[2], 1.2, FAN[3], FAN[4], 0.0)}) (intent create any 0 1 0))',
                        '(node 1451 (pattern 1450 (circular 8 0)) (intent add any any any any))']),
            dict(name='one blade rotated 45 deg and unioned', at='end',
                 edits=[f'(node 1452 (prism 1.5 14 {blade(FAN[0], FAN[1], FAN[2], 1.2, FAN[3], FAN[4], 0.0)}) (intent create any 0 1 0))',
                        '(node 1453 (rotate 1452 z 45) (intent same any any 1 0))', '(node 1454 (union 1401 1453) (intent add any any 1 1))'])])

BRIEFS = [B1, B2, B3, B4, B5, B6, B7, B8, B9, B10, B11, B12, B13, B14]
