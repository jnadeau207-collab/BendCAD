import json
import math
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, 'docs', 'receipts', 'g3'))
import gear

BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
H = 46.0
XS = (0.0, 72.0, 144.0)
CAV = ((-20.0, -56.0), (202.0, 56.0))
BOLTS = [(-10, 76), (90, 76), (190, 76), (-10, -76), (90, -76), (190, -76), (-40, 30), (-40, -30), (222, 30), (222, -30)]
DOWELS = [(-40, 0), (222, 0)]
MOUNTS = [(-56, 70), (-56, -70), (238, 70), (238, -70)]
VENT = (36, -45)
G = 0.9
LP = 11.3
LB = 62 + G
LC = LB + LP
LT = LB + 26
SPACERS = {'spacer_2': 2.0, 'spacer_1_8': 1.8, 'spacer_15_8': 15.8, 'spacer_24': 24.0}
STACK = {
    0.0: [('spacer_2', 16.0), ('spacer_15_8', 46.0)],
    72.0: [('spacer_2', 16.0), ('spacer_1_8', 60.0)],
    144.0: [('spacer_24', 16.0), ('spacer_1_8', 60.0)],
}
SHAFTS = (('input_shaft', 0.0, 3.5, 122.0), ('cluster_shaft', 72.0, 3.5, 74.5), ('output_shaft', 144.0, -44.0, 74.5))
GEARS = (('pinion_input', 'input_shaft', 0.0), ('gear_stage1', 'cluster_shaft', 72.0),
         ('pinion_stage2', 'cluster_shaft', 72.0), ('gear_stage2', 'output_shaft', 144.0))
LOG = []
PART_OF = {}


def f(v):
    s = ('%.12f' % v).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def rrect(c0, c1, r):
    (x0, y0), (x1, y1) = c0, c1
    return ('(path %s %s (line %s %s) (arc %s %s %s %s %s ccw) (line %s %s) (arc %s %s %s %s %s ccw) '
            '(line %s %s) (arc %s %s %s %s %s ccw) (line %s %s) (arc %s %s %s %s %s ccw))') % tuple(map(f, (
                x0, y0 - r, x1, y0 - r, x1, y0, r, x1 + r, y0, x1 + r, y1, x1, y1, r, x1, y1 + r,
                x0, y1 + r, x0, y1, r, x0 - r, y1, x0 - r, y0, x0, y0, r, x0, y0 - r)))


def flats(cx, cy):
    r, a, b = 21.25, 21.0, 3.25
    p = [(cx + a, cy + b), (cx + b, cy + a), (cx - b, cy + a), (cx - a, cy + b),
         (cx - a, cy - b), (cx - b, cy - a), (cx + b, cy - a), (cx + a, cy - b)]
    s = '(path %s %s' % (f(p[0][0]), f(p[0][1]))
    for i in range(1, 9):
        q = p[i % 8]
        if i % 2:
            s += ' (arc %s %s %s %s %s ccw)' % (f(cx), f(cy), f(r), f(q[0]), f(q[1]))
        else:
            s += ' (line %s %s)' % (f(q[0]), f(q[1]))
    return s + ')'


def circle(x, y, r):
    return '(circle %s %s %s)' % (f(x), f(y), f(r))


def dshape():
    return '(path 8 6 (arc 0 0 10 8 -6 ccw))'


def hexagon(s):
    R = s / math.sqrt(3)
    p = [(R * math.cos(k * math.pi / 3), R * math.sin(k * math.pi / 3)) for k in range(6)]
    return '(path %s %s %s)' % (repr(p[0][0]), repr(p[0][1]), ' '.join('(line %s %s)' % (repr(x), repr(y)) for x, y in p[1:]))


class Design:
    def __init__(self):
        self.edits = []
        self.ids = {}
        self.n = 0

    def node(self, name, op, intent):
        self.n += 1
        self.ids[name] = self.n
        self.edits.append('(node %d %s (intent %s))' % (self.n, op, intent))
        return self.n

    def face(self, name, kind, cell=0):
        return '(face %d %d %s)' % (self.ids[name], cell, kind)


def housing(d):
    d.edits.append('(param H %s %s %s)' % (f(H), f(H - 0.03), f(H + 0.03)))
    d.node('floor', '(prism -10 16 (region %s))' % rrect((-56, -82), (238, 82), 10), 'create any 0 1 0')
    d.node('walls', '(pad %d %s H (region %s %s))' % (d.ids['floor'], d.face('floor', 'top'), rrect(*CAV, 26), rrect(*CAV, 10)),
           'add any any 1 0')
    d.node('hpockets', '(pocket %d %s 12 %s)' % (d.ids['walls'], d.face('walls', 'top', 1), ' '.join('(region %s)' % flats(x, 0) for x in XS)),
           'remove any any 1 0')
    d.node('hrelief0', '(pocket %d %s 1 (region %s))' % (d.ids['hpockets'], d.face('hpockets', 'top', 0), circle(0, 0, 18.5)), 'remove any any 1 0')
    d.node('hrelief1', '(pocket %d %s 1 (region %s))' % (d.ids['hrelief0'], d.face('hpockets', 'top', 1), circle(72, 0, 18.5)), 'remove any any 1 0')
    d.node('hseal', '(pocket %d %s 7 (region %s))' % (d.ids['hrelief1'], d.face('hpockets', 'top', 2), circle(144, 0, 17.5)), 'remove any any 1 0')
    d.node('hthru', '(holes %d %s through (hole 144 0 11))' % (d.ids['hseal'], d.face('hseal', 'top')), 'remove any any 1 1')
    d.node('hinserts', '(holes %d %s 12 %s)' % (d.ids['hthru'], d.face('walls', 'top'), ' '.join('(hole %s %s 3.2)' % (f(x), f(y)) for x, y in BOLTS)),
           'remove any any 1 1')
    d.node('hdowels', '(holes %d %s 10 %s)' % (d.ids['hinserts'], d.face('walls', 'top'), ' '.join('(hole %s %s 2.5)' % (f(x), f(y)) for x, y in DOWELS)),
           'remove any any 1 1')
    d.node('housing', '(holes %d %s through %s)' % (d.ids['hdowels'], d.face('floor', 'top'), ' '.join('(hole %s %s 3.3)' % (f(x), f(y)) for x, y in MOUNTS)),
           'remove any any 1 5')


def lid(d):
    d.node('lplate', '(prism %s %s (region %s))' % (f(LB), f(LT), rrect(*CAV, 26)), 'create any 0 1 0')
    d.node('lpockets', '(pocket %d %s %s %s)' % (d.ids['lplate'], d.face('lplate', 'bottom'), f(LP), ' '.join('(region %s)' % flats(x, 0) for x in XS)),
           'remove any any 1 0')
    d.node('lseal', '(pocket %d %s 7 (region %s))' % (d.ids['lpockets'], d.face('lpockets', 'bottom', 0), circle(0, 0, 17.5)), 'remove any any 1 0')
    d.node('lrelief1', '(pocket %d %s 1 (region %s))' % (d.ids['lseal'], d.face('lpockets', 'bottom', 1), circle(72, 0, 18.5)), 'remove any any 1 0')
    d.node('lrelief2', '(pocket %d %s 1 (region %s))' % (d.ids['lrelief1'], d.face('lpockets', 'bottom', 2), circle(144, 0, 18.5)), 'remove any any 1 0')
    d.node('lthru', '(holes %d %s through (hole 0 0 11))' % (d.ids['lrelief2'], d.face('lseal', 'bottom')), 'remove any any 1 1')
    d.node('lbolts', '(holes %d %s through %s)' % (d.ids['lthru'], d.face('lplate', 'top'), ' '.join('(hole %s %s 2.75)' % (f(x), f(y)) for x, y in BOLTS)),
           'remove any any 1 11')
    d.node('ldowels', '(holes %d %s 8 %s)' % (d.ids['lbolts'], d.face('lplate', 'bottom'), ' '.join('(hole %s %s 2.5)' % (f(x), f(y)) for x, y in DOWELS)),
           'remove any any 1 11')
    d.node('lid', '(holes %d %s through (hole %s %s 6))' % (d.ids['ldowels'], d.face('lplate', 'top'), f(VENT[0]), f(VENT[1])), 'remove any any 1 12')


def drivetrain(d):
    for name, _, z0, z1 in SHAFTS:
        d.node(name, '(prism %s %s (region %s))' % (f(z0), f(z1), dshape()), 'create any 0 1 0')
    g18 = gear.gear_path(18)
    g54 = gear.gear_path(54, phase=math.pi / 54)
    d.node('pn_body', '(prism 18 38 (region %s))' % g18, 'create any 0 1 0')
    d.node('pn_hub', '(pad %d %s 8 (region %s))' % (d.ids['pn_body'], d.face('pn_body', 'top'), circle(0, 0, 14)), 'add any any 1 0')
    d.node('pinion_input', '(pocket %d %s through (region %s))' % (d.ids['pn_hub'], d.face('pn_hub', 'top'), dshape()), 'remove any any 1 1')
    d.node('gear_stage1', '(prism 18 38 (region %s %s))' % (g54, dshape()), 'create any 0 1 1')
    d.node('pinion_stage2', '(prism 38 60 (region %s %s))' % (g18, dshape()), 'create any 0 1 1')
    d.node('gear_stage2', '(prism 40 60 (region %s %s))' % (g54, dshape()), 'create any 0 1 1')
    for name, ln in SPACERS.items():
        d.node(name, '(prism 0 %s (region %s %s))' % (f(ln), circle(0, 0, 12), dshape()), 'create any 0 1 1')


def purchased(d):
    d.node('bearing_inner', '(revolve (region (path 10 0 (line 13.9 0) (line 13.9 3) (arc 15.5 6 3.4 13.9 9 cw) (line 13.9 12) (line 10 12))))',
           'create any 0 1 any')
    d.node('bearing_outer', '(revolve (region (path 17.1 0 (line 21 0) (line 21 12) (line 17.1 12) (line 17.1 9) (arc 15.5 6 3.4 17.1 3 cw))))',
           'create any 0 1 any')
    d.node('bearing_ball', '(sphere 3.175)', 'create any 0 1 0')
    d.node('bearing_seal', '(prism 0 1 (region %s %s))' % (circle(0, 0, 17), circle(0, 0, 14)), 'create any 0 1 1')
    up = '(path 16.5 0 (line 17.5 0) (line 17.5 7) (line 11.5 7) (line 11.5 6) (line 13 6) (line 13 4.5) (arc 13 1.5 3 10 1.5 ccw) (line 10 1) (line 12.5 1) (line 12.5 0.6) (line 16.5 0.6))'
    down = '(path 16.5 7 (line 16.5 6.4) (line 12.5 6.4) (line 12.5 6) (line 10 6) (line 10 5.5) (arc 13 5.5 3 13 2.5 ccw) (line 13 1) (line 11.5 1) (line 11.5 0) (line 17.5 0) (line 17.5 7))'
    for name, prof in (('lip_seal_up', up), ('lip_seal_down', down)):
        d.node(name, '(revolve (region %s))' % prof, 'create any 0 1 any')
    d.node('sc_head', '(prism 0 3.5 (region %s))' % hexagon(8), 'create any 0 1 0')
    d.node('screw_m5x35', '(pad %d %s 35 (region %s))' % (d.ids['sc_head'], d.face('sc_head', 'bottom'), circle(0, 0, 2.5)), 'add any any 1 0')
    d.node('insert_m5', '(prism 0 9.5 (region %s %s))' % (circle(0, 0, 3.2), circle(0, 0, 2.5)), 'create any 0 1 1')
    d.node('dowel_5x16', '(cylinder 2.5 16)', 'create any 0 1 0')
    holes = ' '.join(circle(x, y, 2.75) for x, y in BOLTS) + ' ' + ' '.join(circle(x, y, 2.5) for x, y in DOWELS)
    d.node('gasket', '(prism 0 %s (region %s %s %s))' % (f(G), rrect(*CAV, 26), rrect(*CAV, 10), holes), 'create any 0 1 13')
    d.node('vt_cap', '(prism 0 4 (region %s))' % circle(0, 0, 9), 'create any 0 1 0')
    d.node('vent_plug', '(pad %d %s 10 (region %s))' % (d.ids['vt_cap'], d.face('vt_cap', 'bottom'), circle(0, 0, 6)), 'add any any 1 0')


def assembly(d):
    insts, mates = [], []

    def inst(name, part, t):
        PART_OF[name] = part
        insts.append((name, part, t))

    def coinc(a, pa, b, pb):
        mates.append('(coinc %d %s %s %s %s %s %s %s %s)' % (len(mates) + 1, a, f(pa[0]), f(pa[1]), f(pa[2]), b, f(pb[0]), f(pb[1]), f(pb[2])))

    inst('housing', 'housing', (0, 0, 0))
    mates.append('(fix 1 housing)')
    inst('lid', 'lid', (0, 0, 0))
    coinc('lid', (0, 0, 0), 'housing', (0, 0, 0))
    for nm, x, _, _ in SHAFTS:
        inst(nm, nm, (x, 0, 0))
        mates.append('(axis %d %s 0 0 0 %s 0 0 0 0 1)' % (len(mates) + 1, nm, f(x)))
        mates.append('(plane %d %s 0 0 0 0 0 1 0)' % (len(mates) + 1, nm))
        for k, (sp, z) in enumerate(STACK[x]):
            n = '%s_%s_%d' % (nm, sp, k)
            inst(n, sp, (x, 0, z))
            coinc(n, (0, 0, 0), nm, (0, 0, z))
    for nm, shaft, x in GEARS:
        inst(nm, nm, (x, 0, 0))
        coinc(nm, (0, 0, 0), shaft, (0, 0, 0))
    for x in XS:
        for lvl, zb, host in (('lo', 4, 'housing'), ('hi', LC - 12, 'lid')):
            b = 'brg_%d_%s' % (x, lvl)
            inst(b + '_outer', 'bearing_outer', (x, 0, zb))
            coinc(b + '_outer', (0, 0, 0), host, (x, 0, zb))
            inst(b + '_inner', 'bearing_inner', (x, 0, zb))
            coinc(b + '_inner', (0, 0, 0), b + '_outer', (0, 0, 0))
            for k in range(9):
                a = 2 * math.pi * k / 9
                p = (15.5 * math.cos(a), 15.5 * math.sin(a), 6)
                inst('%s_ball%d' % (b, k), 'bearing_ball', (x + p[0], p[1], zb + 6))
                coinc('%s_ball%d' % (b, k), (0, 0, 0), b + '_inner', p)
            for s, z in (('s0', 0.4), ('s1', 10.6)):
                inst('%s_%s' % (b, s), 'bearing_seal', (x, 0, zb + z))
                coinc('%s_%s' % (b, s), (0, 0, 0), b + '_outer', (0, 0, z))
    inst('seal_input', 'lip_seal_up', (0, 0, LC))
    coinc('seal_input', (0, 0, 0), 'lid', (0, 0, LC))
    inst('seal_output', 'lip_seal_down', (144, 0, -3))
    coinc('seal_output', (0, 0, 0), 'housing', (144, 0, -3))
    for i, (x, y) in enumerate(BOLTS):
        inst('screw%d' % i, 'screw_m5x35', (x, y, LT))
        coinc('screw%d' % i, (0, 0, 0), 'lid', (x, y, LT))
        inst('insert%d' % i, 'insert_m5', (x, y, 52.5))
        coinc('insert%d' % i, (0, 0, 0), 'housing', (x, y, 52.5))
    for i, (x, y) in enumerate(DOWELS):
        inst('dowel%d' % i, 'dowel_5x16', (x, y, 54))
        coinc('dowel%d' % i, (0, 0, 0), 'housing', (x, y, 54))
    inst('gasket', 'gasket', (0, 0, 62))
    coinc('gasket', (0, 0, 0), 'housing', (0, 0, 62))
    inst('vent_plug', 'vent_plug', (VENT[0], VENT[1], LT))
    coinc('vent_plug', (0, 0, 0), 'lid', (VENT[0], VENT[1], LT))
    text = '(assembly %s %s)' % (' '.join('(inst %s %d %s %s %s 0)' % (n, d.ids[p], f(t[0]), f(t[1]), f(t[2])) for n, p, t in insts),
                                  ' '.join(mates))
    return insts, text


def pmi(d):
    return ('(pmi (node %d) (datum A n%d.c0.bottom) (dim dH H) (dim dD1 12 11.97 12.03) (dim dD2 11.3 11.27 11.33) '
            '(dim dG 0.9 0.8 1) (dim dB1 -12 -12 -11.88) (dim dB2 -12 -12 -11.88) (dim dL -45.8 -45.83 -45.77) '
            '(tol tFlat flatness 0.05 n%d.c0.top rfs) (tol tPar parallelism 0.05 n%d.c0.top rfs A) '
            '(state cold 1) (state hot 1.001) (stack end_float dH dD1 dG dD2 dB1 dB2 dL))') % (
        d.ids['housing'], d.ids['floor'], d.ids['walls'], d.ids['walls'])


def cli(design, *args, timeout=7200):
    t = time.time()
    r = subprocess.run([BIN, design, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, BEND_NO_TELEMETRY='1'))
    out = r.stdout + r.stderr
    LOG.append(dict(args=[a if len(a) < 400 else a[:400] + '...' for a in args], seconds=round(time.time() - t, 2), out=out[-4000:]))
    return out


def save(out, rep):
    json.dump(dict(rep, parts_of=PART_OF), open(os.path.join(out, 'report.json'), 'w'), indent=1)
    json.dump(LOG, open(os.path.join(out, 'log.json'), 'w'), indent=1)


def main(out, stage):
    os.makedirs(os.path.join(out, 'parts'), exist_ok=True)
    os.makedirs(os.path.join(out, 'placed'), exist_ok=True)
    des = os.path.join(out, 'gearbox.bcd')
    d = Design()
    rep = dict(stages={}, eval={})
    cli(des, 'new')
    for name, build in (('housing', housing), ('lid', lid), ('drivetrain', drivetrain), ('purchased', purchased)):
        k = len(d.edits)
        build(d)
        o = cli(des, 'apply', *d.edits[k:])
        ok = 'committed' in o
        rep['stages'][name] = 'committed' if ok else [l for l in o.splitlines() if 'error' in l][:12]
        print(name, 'committed' if ok else 'REJECTED', '%.1fs' % LOG[-1]['seconds'])
        for l in o.splitlines():
            m = re.match(r'node (\d+): ok .*?volume=\[([^,]+), ([^\]]+)\]', l)
            if m:
                rep['eval'][int(m.group(1))] = (float(m.group(2)), float(m.group(3)))
        if not ok:
            print('\n'.join(rep['stages'][name]))
            rep['ids'] = d.ids
            save(out, rep)
            return 1
    rep['ids'] = d.ids
    insts, asm = assembly(d)
    open(os.path.join(out, 'assembly.txt'), 'w').write(asm)
    o = cli(des, 'asm', 'solve', asm)
    rep['solve'] = o.splitlines()[0] if o else ''
    print(rep['solve'][:300], '%.1fs' % LOG[-1]['seconds'])
    ts = {m.group(1): tuple(float(m.group(i)) for i in (2, 3, 4)) for m in re.finditer(r'inst (\S+) node \d+ t=(\S+) (\S+) (\S+) q=\d+', o)}
    rep['translations'] = ts
    save(out, rep)
    if stage == 'parts' or not o.startswith('asm solved'):
        return 0
    base = 1000
    snap = lambda v: repr(round(v, 9) + 0.0)
    placed = ['(node %d (move %d %s %s %s 0) (intent same 0 0 1 any))' % (base + i, d.ids[part], snap(ts[name][0]), snap(ts[name][1]), snap(ts[name][2]))
              for i, (name, part, _) in enumerate(insts)]
    o = cli(des, 'apply', *placed)
    print('placed', 'committed' if 'committed' in o else 'REJECTED', '%.1fs' % LOG[-1]['seconds'])
    only = [x for x in os.environ.get('G3_ONLY', '').split(',') if x]
    for part in sorted(set(PART_OF.values())):
        if only and part not in only:
            continue
        for kind, ext in (('step', 'stp'), ('stl', 'stl')):
            r = cli(des, kind, str(d.ids[part]), os.path.join(out, 'parts', '%s.%s' % (part, ext)))
            if not r.startswith('wrote'):
                print('export', part, ext, r.strip()[:200])
    print('parts exported')
    for i, (name, part, _) in enumerate(insts):
        if only and part not in only:
            continue
        for kind, ext in (('step', 'stp'), ('stl', 'stl')):
            r = cli(des, kind, str(base + i), os.path.join(out, 'placed', '%s.%s' % (name, ext)))
            if not r.startswith('wrote'):
                print('export', name, ext, r.strip()[:200])
    print('placed exported')
    rep['explode'] = cli(des, 'asm', 'explode', '0', '0', '1', '12', asm)
    p = pmi(d)
    rep['pmi'] = p
    rep['pmi_check'] = cli(des, 'pmi', 'check', p)
    rep['pmi_stack'] = cli(des, 'pmi', 'stack', p)
    rep['pmi_step42'] = cli(des, 'pmi', 'step42', os.path.join(out, 'housing_pmi_ap242.stp'), p)
    save(out, rep)
    print('done')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else 'all'))
