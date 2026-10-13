import json
import math
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
WORK = '/tmp/bc-e2e-c11'
OUT = os.path.join(HERE, 'e2e-report.json')
PI = math.pi
RESULTS = []


def wsl(*args, timeout=900):
    t = time.time()
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    r = subprocess.run([*pre, *args], capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'))
    return r.stdout + r.stderr, time.time() - t


def cli(design, *args):
    out, dt = wsl(BIN, f'{WORK}/{design}', *args)
    return out, dt


def geom(*args):
    out, dt = wsl(BIN, 'geom', *args)
    return out, dt


def read(design):
    return wsl('cat', f'{WORK}/{design}')[0]


def fresh(design, *edits):
    cli(design, 'new')
    return cli(design, 'apply', *edits)


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if k != 'detail'})


def contains(iv, x):
    return iv is not None and iv[0] <= x <= iv[1]


def iv_of(s):
    m = re.search(r'\[([^,]+), ([^\]]+)\]', s)
    return (float(m.group(1)), float(m.group(2))) if m else None


def width(iv):
    return iv[1] - iv[0]


def overlap(a, b):
    return a is not None and b is not None and a[0] <= b[1] and b[0] <= a[1]


def dist_line(out):
    m = re.search(r'distance \[([^,]+), ([^\]]+)\] (\w+) lo=(\w+) nearest=([^ ]+) samples=(\d+)', out)
    if m:
        g = m.groups()
        return dict(lo=float(g[0]), hi=float(g[1]), st=g[2], locert=g[3], near=g[4], nsamp=int(g[5]))
    m = re.search(r'distance 0 status=(\w+) state=(\w+)', out)
    if m:
        return dict(zero=True, st=m.group(1), state=m.group(2))
    return None


def mass_lines(out):
    m1 = re.search(r'mass volume=(\[[^\]]+\]) certified octree=(\[[^\]]+\]) depth=(\d+) cells=(\d+)/(\d+)/(\d+)', out)
    m2 = re.search(r'centroid (\[[^\]]+\])x(\[[^\]]+\])x(\[[^\]]+\]) status=(\w+)( incomplete-cells=(\d+))?', out)
    m3 = re.search(r'inertia-centroid (\[[^\]]+\]) (\[[^\]]+\]) (\[[^\]]+\]) (\[[^\]]+\]) (\[[^\]]+\]) (\[[^\]]+\]) status=(\w+)', out)
    if not (m1 and m2 and m3):
        return None
    iv = lambda s: (float(s[1:-1].split(', ')[0]), float(s[1:-1].split(', ')[1]))
    return dict(vol=iv(m1.group(1)), oct=iv(m1.group(2)), depth=int(m1.group(3)),
                cells=(int(m1.group(4)), int(m1.group(5)), int(m1.group(6))),
                cen=(iv(m2.group(1)), iv(m2.group(2)), iv(m2.group(3))), censt=m2.group(4),
                ine=tuple(iv(m3.group(i)) for i in range(1, 7)), inest=m3.group(7))


def wall_line(out):
    m = re.search(r'min-wall \[([^,]+), ([^\]]+)\] (\w+) (lo=\w+) faces=(\d+) pairs=(\d+) pruned=(\d+)', out)
    if m:
        g = m.groups()
        return dict(lo=float(g[0]), hi=float(g[1]), st=g[2], locert=g[3], faces=int(g[4]),
                    pairs=int(g[5]), pruned=int(g[6]))
    m = re.search(r'min-wall none status=(\w+) reason=([\w-]+)', out)
    if m:
        return dict(none=True, st=m.group(1), reason=m.group(2))
    return None


def clear_line(out):
    m = re.search(r'clearance \[([^,]+), ([^\]]+)\] (\w+) (lo=\w+) samples=(\d+)x(\d+)', out)
    if m:
        g = m.groups()
        return dict(lo=float(g[0]), hi=float(g[1]), st=g[2], locert=g[3])
    m = re.search(r'clearance 0 status=(\w+) state=(\w+)', out)
    if m:
        return dict(zero=True, st=m.group(1), state=m.group(2))
    return None


def rel_line(out):
    m = re.findall(r'^relation .*$', out, re.M)
    return m[-1] if m else None


def sect_summary(out):
    m = re.search(r'summary faces=(\d+) curves=(\d+) unresolved=(\d+) coincident=(\d+) status=(\w+)( plane=mapped)?', out)
    if not m:
        return None
    g = m.groups()
    return dict(faces=int(g[0]), curves=int(g[1]), unres=int(g[2]), coin=int(g[3]), st=g[4],
                mapped=g[5] is not None)


IC = '(intent create any any any any)'
IS = '(intent same any any any any)'


def dist_box():
    fresh('d.bcd', f'(node 1 (box 10 10 10) {IC})')
    o, _ = cli('d.bcd', 'dist', '1', '15', '5', '5')
    d = dist_line(o)
    record('dist.box_out', d is not None and not d.get('zero') and d['lo'] <= 5.0 <= d['hi']
           and d['st'] == 'estimated' and d['locert'] == 'certified' and d['nsamp'] == 26, **(d or {}))
    o, _ = cli('d.bcd', 'dist', '1', '5', '5', '5')
    d = dist_line(o)
    record('dist.box_in', d is not None and d.get('zero') and d['st'] == 'certified'
           and d['state'] == 'inside', **(d or {}))
    o, _ = cli('d.bcd', 'dist', '1', '0', '5', '5')
    d = dist_line(o)
    record('dist.box_boundary', d is not None and d.get('zero') and d['st'] == 'certified'
           and d['state'] == 'boundary', **(d or {}))


def dist_cyl():
    fresh('dc.bcd', f'(node 1 (cylinder 5 10) {IC})')
    o, _ = cli('dc.bcd', 'dist', '1', '12', '0', '5')
    d = dist_line(o)
    record('dist.cyl_radial', d is not None and not d.get('zero') and d['lo'] <= 7.0 <= d['hi']
           and d['locert'] == 'certified', **(d or {}))


def extrema_box():
    fresh('e.bcd', f'(node 1 (box 10 10 10) {IC})')
    m, _ = cli('e.bcd', 'measure', '1')
    b = re.search(r'bbox=(\[[^\]]+\])x(\[[^\]]+\])x(\[[^\]]+\])', m)
    o, _ = cli('e.bcd', 'extrema', '1')
    e = re.search(r'extrema x=(\[[^\]]+\]) y=(\[[^\]]+\]) z=(\[[^\]]+\]) status=(\w+)', o)
    w = re.search(r'witnesses xmin=([^ ]+) xmax=([^ ]+) ymin=([^ ]+) ymax=([^ ]+) zmin=([^ ]+) zmax=([^ ]+) status=(\w+)', o)
    ok = (b is not None and e is not None and w is not None and e.group(4) == 'certified'
          and w.group(7) == 'sampled' and (e.group(1), e.group(2), e.group(3)) == (b.group(1), b.group(2), b.group(3)))
    record('extrema.box', ok, bounds=e.groups()[:3] if e else None)


def mass_box():
    fresh('m.bcd', f'(node 1 (box 10 10 10) {IC})')
    o, dt = cli('m.bcd', 'mass', '1', '4')
    r = mass_lines(o)
    ixx = 1000.0 * 200.0 / 12.0
    ok = (r is not None and contains(r['vol'], 1000.0) and contains(r['oct'], 1000.0)
          and r['depth'] == 4 and sum(r['cells']) == 4096 and r['cells'][1] == 0
          and all(contains(c, 5.0) for c in r['cen']) and r['censt'] == 'certified'
          and all(contains(r['ine'][i], ixx) for i in range(3))
          and all(contains(r['ine'][i], 0.0) for i in range(3, 6)) and r['inest'] == 'certified')
    record('mass.box4', ok, vol=r['vol'] if r else None, cells=r['cells'] if r else None,
           cen=r['cen'] if r else None, ine=r['ine'] if r else None, seconds=round(dt, 2))


def mass_depths():
    fresh('md.bcd', f'(node 1 (box 10 10 10) {IC})')
    rows = {}
    for d in (2, 3, 4):
        o, dt = cli('md.bcd', 'mass', '1', str(d))
        r = mass_lines(o)
        rows[d] = (r, dt)
    ok = all(r is not None and sum(r['cells']) == 8 ** d and contains(r['vol'], 1000.0)
             and all(contains(c, 5.0) for c in r['cen']) for d, (r, dt) in rows.items())
    ws = {d: width(r['cen'][0]) for d, (r, dt) in rows.items()}
    ok = ok and ws[4] < ws[3] < ws[2]
    o, _ = cli('md.bcd', 'mass', '1')
    rd = mass_lines(o)
    ok = ok and rd is not None and rd['depth'] == 4
    record('mass.depths', ok, widths=ws,
           seconds={d: round(dt, 2) for d, (r, dt) in rows.items()},
           cells={d: r['cells'] for d, (r, dt) in rows.items()})


def mass_box6():
    fresh('m6.bcd', f'(node 1 (box 10 10 10) {IC})')
    o, dt = cli('m6.bcd', 'mass', '1', '6')
    r = mass_lines(o)
    ixx = 1000.0 * 200.0 / 12.0
    ok = (r is not None and sum(r['cells']) == 262144 and contains(r['vol'], 1000.0)
          and all(contains(c, 5.0) for c in r['cen'])
          and all(contains(r['ine'][i], ixx) for i in range(3))
          and all(contains(r['ine'][i], 0.0) for i in range(3, 6)))
    record('mass.box6', ok, cells=r['cells'] if r else None,
           cenwidth=round(width(r['cen'][0]), 4) if r else None,
           inewidth=round(width(r['ine'][0]), 2) if r else None, seconds=round(dt, 1))


def mass_moved():
    fresh('mm.bcd', f'(node 1 (box 10 10 10) {IC})',
          f'(node 2 (move 1 20 0 0 0) {IS})')
    o, _ = cli('mm.bcd', 'mass', '2', '3')
    r = mass_lines(o)
    o1, _ = cli('mm.bcd', 'mass', '1', '3')
    r1 = mass_lines(o1)
    ok = (r is not None and r1 is not None and contains(r['cen'][0], 25.0)
          and contains(r['cen'][1], 5.0) and contains(r['cen'][2], 5.0)
          and all(overlap(r['ine'][i], r1['ine'][i]) for i in range(6)))
    record('mass.moved_invariance', ok, cen=r['cen'] if r else None,
           ine=r['ine'] if r else None, ine1=r1['ine'] if r1 else None)


def mass_curved():
    fresh('mc.bcd', f'(node 1 (cylinder 5 10) {IC})', f'(node 2 (sphere 10) {IC})')
    o, dtc = cli('mc.bcd', 'mass', '1', '3')
    r = mass_lines(o)
    vc = PI * 25.0 * 10.0
    okc = (r is not None and contains(r['vol'], vc) and contains(r['oct'], vc)
           and contains(r['cen'][0], 0.0) and contains(r['cen'][1], 0.0) and contains(r['cen'][2], 5.0))
    record('mass.cylinder', okc, vol=r['vol'] if r else None, cen=r['cen'] if r else None,
           seconds=round(dtc, 1))
    o, dts = cli('mc.bcd', 'mass', '2', '3')
    r = mass_lines(o)
    vs = 4.0 / 3.0 * PI * 1000.0
    oks = (r is not None and contains(r['vol'], vs) and contains(r['oct'], vs)
           and all(contains(c, 0.0) for c in r['cen']))
    record('mass.sphere', oks, vol=r['vol'] if r else None, cen=r['cen'] if r else None,
           seconds=round(dts, 1))


def sect_circle():
    fresh('sc.bcd', f'(node 1 (cylinder 5 10) {IC})')
    o, dt = cli('sc.bcd', 'section', '1', '0', '0', '1', '5')
    s = sect_summary(o)
    pts = re.findall(r'p (\[[^\]]+\])x(\[[^\]]+\])x(\[[^\]]+\])', o)
    iv = lambda t: (float(t[1:-1].split(', ')[0]), float(t[1:-1].split(', ')[1]))
    good = 0
    for x, y, z in pts:
        xi, yi, zi = iv(x), iv(y), iv(z)
        xm, ym = (xi[0] + xi[1]) / 2, (yi[0] + yi[1]) / 2
        if contains(zi, 5.0) and abs(xm * xm + ym * ym - 25.0) < 0.5:
            good += 1
    ok = (s is not None and s['faces'] == 3 and s['curves'] == 4 and s['unres'] == 4
          and s['coin'] == 0 and s['st'] == 'estimated' and not s['mapped']
          and len(pts) > 0 and good == len(pts) and dt < 60)
    record('section.cyl_circle', ok, summary=s, samples=len(pts), on_circle=good, seconds=round(dt, 1))


def sect_sphere():
    fresh('ss.bcd', f'(node 1 (sphere 10) {IC})')
    o, dt = cli('ss.bcd', 'section', '1', '0', '0', '1', '0')
    s = sect_summary(o)
    pts = re.findall(r'p (\[[^\]]+\])x(\[[^\]]+\])x(\[[^\]]+\])', o)
    iv = lambda t: (float(t[1:-1].split(', ')[0]), float(t[1:-1].split(', ')[1]))
    good = 0
    for x, y, z in pts:
        xi, yi, zi = iv(x), iv(y), iv(z)
        xm, ym = (xi[0] + xi[1]) / 2, (yi[0] + yi[1]) / 2
        if contains(zi, 0.0) and abs(xm * xm + ym * ym - 100.0) < 2.0:
            good += 1
    ok = (s is not None and s['curves'] == 8 and s['unres'] == 8 and s['st'] == 'estimated'
          and len(pts) > 0 and good == len(pts) and dt < 60)
    record('section.sphere_circle', ok, summary=s, samples=len(pts), on_circle=good,
           seconds=round(dt, 1))


def sect_box_estimated():
    fresh('sb.bcd', f'(node 1 (box 10 10 10) {IC})')
    o, dt = cli('sb.bcd', 'section', '1', '0', '0', '1', '5')
    s = sect_summary(o)
    more = re.findall(r'unresolved more=(\d+) hull=', o)
    ok = (s is not None and s['faces'] == 6 and s['curves'] == 2 and s['unres'] == 65537
          and s['coin'] == 0 and s['st'] == 'estimated' and not s['mapped'] and len(more) == 2)
    record('section.box_estimated', ok, summary=s, seconds=round(dt, 1))


def sect_mapped():
    fresh('sm.bcd', f'(node 1 (box 10 10 10) {IC})', f'(node 2 (move 1 20 0 0 0) {IS})')
    o, dt = cli('sm.bcd', 'section', '2', '1', '0', '0', '25')
    s = sect_summary(o)
    ok = (s is not None and s['mapped'] and s['st'] == 'estimated')
    record('section.mapped', ok, summary=s, seconds=round(dt, 1))


def sect_coin():
    o, dt = geom('intersect', '(plane 0 0 0 1 0 0 0 1 0)', '(plane 0 0 0 1 0 0 0 1 0)',
                 '(box -5 5 -5 5 -5 5)')
    m = re.search(r'summary curves=(\d+) unresolved=(\d+) coincident=(\d+)', o)
    ok = (m is not None and m.groups() == ('0', '0', '1')
          and 'overlap surfaces coincide' in o and dt < 60)
    record('section.coin', ok, line=o.strip()[:160], seconds=round(dt, 1))


def interf_cases():
    fresh('ri.bcd', f'(node 1 (box 10 10 10) {IC})',
          f'(node 2 (box 2 2 2) {IC})',
          f'(node 3 (move 2 4 4 4 0) {IS})',
          f'(node 4 (box 10 10 10) {IC})',
          f'(node 5 (move 4 20 0 0 0) {IS})',
          f'(node 6 (box 10 10 10) {IC})',
          f'(node 7 (move 6 5 0 0 0) {IS})',
          f'(node 8 (box 10 10 10) {IC})',
          f'(node 9 (move 8 10 0 0 0) {IS})')
    o, _ = cli('ri.bcd', 'interf', '1', '5')
    r = rel_line(o)
    record('interf.disjoint', r == 'relation disjoint status=certified', line=r)
    o, _ = cli('ri.bcd', 'interf', '1', '7')
    r = rel_line(o)
    record('interf.overlap', r is not None and r.startswith('relation interference status=certified'), line=r)
    o, _ = cli('ri.bcd', 'interf', '3', '1')
    r = rel_line(o)
    record('interf.inside_a', r == 'relation inside a-in-b status=certified', line=r)
    o, _ = cli('ri.bcd', 'interf', '1', '3')
    r = rel_line(o)
    record('interf.inside_b', r == 'relation inside b-in-a status=certified', line=r)
    o, _ = cli('ri.bcd', 'interf', '1', '9')
    r = rel_line(o)
    record('interf.contact', r is not None and r.startswith('relation uncertain status=estimated')
           and 'boxes-overlap=1' in r, line=r)


def interf_aabb_trap():
    o, _ = fresh('rt.bcd', f'(node 1 (box 20 20 20) {IC})',
                 f'(node 2 (box 4 4 4) {IC})',
                 f'(node 3 (move 2 15 15 15 0) {IS})',
                 '(node 4 (difference 1 3) (intent remove any any any any))',
                 f'(node 5 (box 1 1 1) {IC})',
                 f'(node 6 (move 5 16.5 16.5 16.5 0) {IS})')
    if 'committed' not in o:
        record('interf.aabb_trap', False, apply=o.strip()[:200])
        return
    o, dt = cli('rt.bcd', 'interf', '4', '6')
    r = rel_line(o)
    record('interf.aabb_trap', r == 'relation disjoint status=certified', line=r,
           seconds=round(dt, 1))


def interf_cavity():
    fresh('rc.bcd', f'(node 1 (box 10 10 10) {IC})',
          '(node 2 (shell 1 1) (intent remove any any any any))')
    o, dt = cli('rc.bcd', 'interf', '2', '1')
    r = rel_line(o)
    cav = re.findall(r'^cavity .*$', o, re.M)
    ok = (r is not None and r.startswith('relation interference status=certified')
          and 'cavity 1 inside 0 status=certified' in cav)
    record('interf.cavity', ok, line=r, cavities=cav, seconds=round(dt, 1))


def clearance_cases():
    fresh('rl.bcd', f'(node 1 (box 10 10 10) {IC})',
          f'(node 2 (box 10 10 10) {IC})',
          f'(node 3 (move 2 20 0 0 0) {IS})',
          f'(node 4 (box 10 10 10) {IC})',
          f'(node 5 (move 4 5 0 0 0) {IS})',
          f'(node 6 (box 2 2 2) {IC})',
          f'(node 7 (move 6 4 4 4 0) {IS})')
    o, _ = cli('rl.bcd', 'clearance', '1', '3')
    c = clear_line(o)
    record('clearance.disjoint', c is not None and not c.get('zero') and c['lo'] <= 10.0 <= c['hi']
           and c['locert'] == 'lo=certified', **{k: v for k, v in (c or {}).items()})
    o, _ = cli('rl.bcd', 'clearance', '1', '5')
    c = clear_line(o)
    record('clearance.interf', c is not None and c.get('zero') and c['st'] == 'certified'
           and c['state'] == 'interference', **{k: v for k, v in (c or {}).items()})
    o, _ = cli('rl.bcd', 'clearance', '7', '1')
    c = clear_line(o)
    record('clearance.contained', c is not None and not c.get('zero') and c['lo'] == 0.0
           and c['hi'] > 0.0, **{k: v for k, v in (c or {}).items()})


def wall_cases():
    fresh('w.bcd', f'(node 1 (box 10 10 10) {IC})',
          f'(node 2 (box 40 30 10) {IC})',
          f'(node 3 (cone 5 10) {IC})')
    o, _ = cli('w.bcd', 'wall', '1')
    w = wall_line(o)
    record('wall.box', w is not None and not w.get('none') and w['lo'] <= 10.0 <= w['hi']
           and w['locert'] == 'lo=certified' and w['faces'] == 6 and w['pairs'] == 3,
           **{k: v for k, v in (w or {}).items()})
    o, _ = cli('w.bcd', 'wall', '2')
    w = wall_line(o)
    record('wall.slab', w is not None and not w.get('none') and w['lo'] <= 10.0 <= w['hi']
           and w['locert'] == 'lo=certified', **{k: v for k, v in (w or {}).items()})
    o, _ = cli('w.bcd', 'wall', '3')
    w = wall_line(o)
    record('wall.cone_none', w is not None and w.get('none') and w['st'] == 'certified'
           and w['reason'] == 'all-faces-adjacent', **{k: v for k, v in (w or {}).items()})


def carried_queries():
    fresh('q.bcd', f'(node 1 (box 10 10 10) {IC})')
    o, _ = cli('q.bcd', 'classify', '1', '5', '5', '5')
    record('carried.classify', o.strip() == 'inside', line=o.strip()[:80])
    o, _ = cli('q.bcd', 'check', '1')
    record('carried.check', o.strip() == 'ok: embedded, shells outward, cavities nested',
           line=o.strip()[:80])
    o, _ = geom('intersect', '(line 0 0 0 1 0 0 -5 5)', '(line 0 0 0 0 1 0 -5 5)')
    m = re.search(r'summary points=(\d+) overlaps=(\d+) unresolved=(\d+)', o)
    record('carried.geom', m is not None and m.groups() == ('1', '0', '0'), line=o.strip()[:120])


def mcp_queries():
    srv = os.path.join(HERE, '..', '..', 'tools', 'mcp', 'bendcad-mcp.mjs')
    msgs = [dict(method='tools/call', params=dict(name='new_design', arguments=dict(design=f'{WORK}/mq.bcd'))),
            dict(method='tools/call', params=dict(name='apply', arguments=dict(design=f'{WORK}/mq.bcd', edits=[
                f'(node 1 (box 10 10 10) {IC})', f'(node 2 (cylinder 5 10) {IC})',
                f'(node 3 (move 1 20 0 0 0) {IS})']))),
            dict(method='tools/call', params=dict(name='distance', arguments=dict(design=f'{WORK}/mq.bcd', node=1, x=15, y=5, z=5))),
            dict(method='tools/call', params=dict(name='extrema', arguments=dict(design=f'{WORK}/mq.bcd', node=1))),
            dict(method='tools/call', params=dict(name='mass', arguments=dict(design=f'{WORK}/mq.bcd', node=1, depth=2))),
            dict(method='tools/call', params=dict(name='section', arguments=dict(design=f'{WORK}/mq.bcd', node=2, a=0, b=0, c=1, d=5))),
            dict(method='tools/call', params=dict(name='interference', arguments=dict(design=f'{WORK}/mq.bcd', a=1, b=3))),
            dict(method='tools/call', params=dict(name='clearance', arguments=dict(design=f'{WORK}/mq.bcd', a=1, b=3))),
            dict(method='tools/call', params=dict(name='min_wall', arguments=dict(design=f'{WORK}/mq.bcd', node=1)))]
    text = ''.join(json.dumps(dict(jsonrpc='2.0', id=i + 1, **m)) + '\n' for i, m in enumerate(msgs))
    r = subprocess.run(['node', srv], input=text, capture_output=True, text=True, timeout=900,
                       env=dict(os.environ, BENDCAD_BIN=BIN))
    rs = {x['id']: x for x in map(json.loads, r.stdout.strip().splitlines())}
    body = lambda i: rs[i]['result']['content'][0]['text']
    checks = dict(
        distance='distance [4.999999999999987' in body(3) and 'lo=certified' in body(3),
        extrema='status=certified' in body(4),
        mass='cells=8/0/56' in body(5),
        section='curves=4' in body(6) and 'unresolved=4' in body(6),
        interference=body(7).strip() == 'relation disjoint status=certified',
        clearance='lo=certified' in body(8),
        min_wall='lo=certified' in body(9) and 'faces=6' in body(9))
    record('mcp.queries', all(checks.values()), **checks)


def main():
    wsl('rm', '-rf', WORK)
    wsl('mkdir', '-p', WORK)
    for f in (dist_box, dist_cyl, extrema_box, mass_box, mass_depths, mass_box6, mass_moved,
              mass_curved, sect_circle, sect_sphere, sect_box_estimated, sect_mapped,
              sect_coin, interf_cases, interf_aabb_trap, interf_cavity, clearance_cases,
              wall_cases, carried_queries, mcp_queries):
        f()
    rep = dict(binary_sha256=wsl('sha256sum', BIN)[0].split()[0], passed=sum(r['ok'] for r in RESULTS),
               total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} passed")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
