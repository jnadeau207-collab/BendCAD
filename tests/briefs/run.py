import json
import os
import re
import shutil
import subprocess
import sys
import time
from concurrent.futures import ProcessPoolExecutor

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, 'tools', 'mesh'))
from briefs import BRIEFS

BIN = os.environ.get('BENDCAD_BIN', os.environ.get('BRIEF_BIN', '/home/jesse/bc/bendcad-a15'))
WORK = os.environ.get('BRIEF_WORK', '/var/tmp/briefs')
OUT = os.path.join(ROOT, 'docs', 'receipts', 'briefs')
TIMEOUT = float(os.environ.get('BRIEF_TIMEOUT', '600'))
KEEP = os.environ.get('BRIEF_KEEP', '0') == '1'
BUDGET = dict(edit_s=5.0, part_s=60.0, export_s=300.0)


def kernel(design, *args, timeout=TIMEOUT):
    t0 = time.time()
    try:
        p = subprocess.run([BIN, design, *args], capture_output=True, text=True, timeout=timeout)
        return dict(out=p.stdout + p.stderr, s=round(time.time() - t0, 3), timeout=False, code=p.returncode)
    except subprocess.TimeoutExpired:
        return dict(out='', s=round(time.time() - t0, 3), timeout=True, code=None)


def clip(s, n=4000):
    return s if len(s) <= n else s[:n // 2] + f'\n...[{len(s) - n} chars clipped]...\n' + s[-n // 2:]


def refusals(out):
    rows = []
    for ln in out.splitlines():
        if 'error ' in ln or ln.startswith('refused'):
            w = re.search(r'why: ([^|]*)', ln)
            fx = re.search(r'fix: (.*)$', ln)
            rows.append(dict(line=ln.strip()[:600], why=w.group(1).strip() if w else None, fix=fx.group(1).strip() if fx else None))
    return rows


def node_line(out, n):
    m = None
    for m in re.finditer(rf'^node {n}: (.*)$', out, re.M):
        pass
    return m.group(1) if m else ''


def volume(line):
    m = re.search(r'volume=\[(\S+), (\S+)\]', line)
    return [float(m.group(1)), float(m.group(2))] if m else None


def edit_text(e):
    return e if isinstance(e, str) else ' '.join(e)


def edit_args(e):
    return [e] if isinstance(e, str) else list(e)


def apply(design, e, timeout=TIMEOUT):
    r = kernel(design, 'apply', *edit_args(e), timeout=timeout)
    st = 'timeout' if r['timeout'] else 'committed' if re.search(r'^committed', r['out'], re.M) else 'rejected'
    return dict(edit=edit_text(e), status=st, s=r['s'], refusals=refusals(r['out']) if st == 'rejected' else [], out=clip(r['out'], 3000))


def ival(text, key):
    m = re.search(key + r'\s*\[(\S+), (\S+?)\]', text)
    return (float(m.group(1)), float(m.group(2))) if m else None


def judge(spec, out):
    k, a = spec[0], spec[1:]
    if k == 'na':
        return 'not-analyzed', a[0]
    if not out.strip():
        return 'not-analyzed', 'no output (timeout or crash)'
    if re.search(r'^(error|refused)', out, re.M) and k not in ('refused', 'contains_any', 'fits'):
        rr = refusals(out)
        return 'not-analyzed', 'kernel refused: ' + (rr[0]['line'] if rr else out.strip()[:300])
    if k == 'check_ok':
        return ('pass', out.strip().splitlines()[0]) if out.lstrip().startswith('ok:') else ('fail', out.strip()[:400])
    if k in ('wall_ge', 'clear_ge', 'dist_ge'):
        key = {'wall_ge': 'min-wall', 'clear_ge': 'clearance', 'dist_ge': 'distance'}[k]
        iv = ival(out, key)
        if iv is None and re.search(key + r' 0\b', out):
            iv = (0.0, 0.0)
        if iv is None:
            return 'not-analyzed', f'no {key} interval in output'
        if iv[0] >= a[0]:
            return 'pass', f'{key} {list(iv)} >= {a[0]}'
        if iv[1] < a[0]:
            return 'fail', f'{key} {list(iv)} < {a[0]}'
        return 'not-analyzed', f'{key} {list(iv)} straddles {a[0]}'
    if k in ('clear_in', 'dist_in', 'gap_in', 'wall_in'):
        key = {'clear_in': 'clearance', 'dist_in': 'distance', 'gap_in': 'gap=', 'wall_in': 'min-wall'}[k]
        iv = ival(out, key)
        if iv is None and k == 'clear_in' and re.search(r'clearance 0\b', out):
            iv = (0.0, 0.0)
        if iv is None:
            return 'not-analyzed', f'no {key} interval in output'
        lo, hi = a
        if lo <= iv[0] and iv[1] <= hi:
            return 'pass', f'{key} {list(iv)} within [{lo}, {hi}]'
        if iv[1] < lo or iv[0] > hi:
            return 'fail', f'{key} {list(iv)} outside [{lo}, {hi}]'
        return 'not-analyzed', f'{key} {list(iv)} not decided against [{lo}, {hi}]'
    if k == 'relation':
        m = re.search(r'relation (\S+) status=(\S+)', out)
        if not m:
            return 'not-analyzed', 'no relation line'
        if m.group(2) != 'certified':
            return 'not-analyzed', m.group(0)
        return ('pass' if m.group(1) in a[0].split('|') else 'fail'), m.group(0)
    if k == 'machinable':
        m = re.search(r'verdict (\S+)', out)
        st = re.search(r'status=(\S+)\s*$', out.strip())
        if not m:
            return 'not-analyzed', 'no verdict line'
        line = [ln for ln in out.splitlines() if ln.startswith('verdict')][0]
        if m.group(1) == 'machinable' and 'status=certified' in line:
            return 'pass', line
        if m.group(1) == 'not-machinable':
            return 'fail', line
        return 'not-analyzed', line
    if k == 'contains':
        return ('pass' if all(s in out for s in a) else 'fail'), clip(out.strip(), 400)
    if k == 'contains_any':
        return ('pass' if any(s in out for s in a) else 'fail'), clip(out.strip(), 400)
    if k == 'regex':
        return ('pass' if re.search(a[0], out, re.M) else 'fail'), clip(out.strip(), 400)
    if k == 'refused':
        return ('pass' if re.search(r'^(error|refused)', out, re.M) else 'fail'), clip(out.strip(), 400)
    if k == 'absent_interference':
        blocks = re.findall(r'^pair (\S+) (\S+)\n((?:(?!pair ).*\n?)*)', out, re.M)
        if not blocks:
            return 'not-analyzed', 'no pair lines'
        bad = [f'{a}-{b}: {r.splitlines()[0]}' for a, b, r in blocks if 'relation interference' in r and 'declared press-fit' not in r]
        unc = [f'{a}-{b}: {r.splitlines()[0]}' for a, b, r in blocks if 'status=certified' not in r and 'declared press-fit' not in r]
        if bad:
            return 'fail', '; '.join(bad)[:800]
        if unc:
            return 'not-analyzed', '; '.join(unc)[:800]
        dec = sum(1 for a, b, r in blocks if 'declared press-fit' in r)
        return 'pass', f'{len(blocks)} pairs certified, {dec} declared press fits'
    if k == 'fits':
        bad = re.findall(r'fit-not-\S+|refused|error', out)
        return ('fail' if bad else 'pass'), clip(out.strip(), 600)
    return 'not-analyzed', f'unknown judge {k}'


def run_check(design, c):
    if c.get('cmd') is None:
        v, d = judge(c['judge'], '')
        return dict(req=c['req'], verdict=v, detail=d, cmd=None, s=0.0, info=c.get('info', False))
    r = kernel(design, *c['cmd'], timeout=c.get('timeout', TIMEOUT))
    if r['timeout']:
        v, d = 'not-analyzed', f'timeout after {r["s"]} s'
    else:
        v, d = judge(c['judge'], r['out'])
    return dict(req=c['req'], verdict=v, detail=d, cmd=' '.join(c['cmd']), s=r['s'], info=c.get('info', False), out=clip(r['out'], 2500))


def occt_volume(path):
    from build123d import import_step
    from OCP.BRepGProp import BRepGProp
    from OCP.GProp import GProp_GProps
    shape = import_step(path)
    g = GProp_GProps()
    BRepGProp.VolumeProperties_s(shape.wrapped, g, 1e-9)
    n = len(shape.solids()) if hasattr(shape, 'solids') else None
    return g.Mass(), n


def step_part(design, wd, n, cert):
    sp = os.path.join(wd, f'n{n}.stp')
    r = kernel(design, 'step', str(n), sp)
    rec = dict(node=n, s=r['s'], out=clip(r['out'], 400), timeout=r['timeout'])
    if r['timeout'] or not os.path.exists(sp):
        rec['agree'] = None
        rec['why'] = 'timeout' if r['timeout'] else 'no STEP written'
        return rec
    try:
        ov, ns = occt_volume(sp)
        rec['occt_volume'], rec['occt_solids'] = ov, ns
        if cert:
            lo, hi = cert
            rec['certified'] = cert
            rec['agree'] = bool(abs(ov - 0.5 * (lo + hi)) <= 1e-7 * max(1.0, hi) + (hi - lo))
            rec['rel_err'] = (ov - 0.5 * (lo + hi)) / (0.5 * (lo + hi))
        else:
            rec['agree'] = None
    except Exception as ex:
        rec['agree'] = False
        rec['occt_error'] = str(ex)[:300]
    return rec


def tess_part(design, wd, n, cert):
    from check import check
    ob = os.path.join(wd, f'n{n}.obj')
    r = kernel(design, 'tess', str(n), ob)
    rec = dict(node=n, s=r['s'], out=clip(r['out'], 500), timeout=r['timeout'])
    if r['timeout'] or not os.path.exists(ob) or not r['out'].startswith('wrote'):
        rec['conforming'] = None
        rec['why'] = 'timeout' if r['timeout'] else r['out'].strip()[:400]
        return rec
    t0 = time.time()
    mc = check(ob)
    rec['judge_s'] = round(time.time() - t0, 2)
    rec.update({k: mc[k] for k in ('triangles', 'vertices', 'zero_area', 'edge_uses', 'same_direction_pairs', 't_junctions', 'conforming', 'volume')})
    if cert:
        mid = 0.5 * (cert[0] + cert[1])
        rec['volume_rel_err'] = (mc['volume'] - mid) / mid
    return rec


def stl_part(design, wd, n):
    sp = os.path.join(wd, f'n{n}.stl')
    r = kernel(design, 'stl', str(n), sp, '3')
    ok = (not r['timeout']) and r['out'].startswith('wrote')
    return dict(node=n, preset=3, s=r['s'], ok=ok, timeout=r['timeout'], out=clip(r['out'], 400))


def probes(design, wd, b, at):
    rows = []
    for i, p in enumerate(b.get('probes', [])):
        if p.get('at', 'end') != at:
            continue
        pd = os.path.join(wd, f'probe{i}.bcd')
        shutil.copy(design, pd)
        steps = []
        for e in p['edits']:
            steps.append(apply(pd, e))
            if steps[-1]['status'] != 'committed':
                break
        extra = [dict(cmd=' '.join(c), **{k: v for k, v in kernel(pd, *c).items() if k != 'code'}) for c in p.get('then', [])] \
            if all(s['status'] == 'committed' for s in steps) else []
        for x in extra:
            x['out'] = clip(x['out'], 1500)
        rows.append(dict(name=p['name'], note=p.get('note', ''), steps=steps, then=extra))
    return rows


def friction_count(bid):
    try:
        fr = json.load(open(os.path.join(OUT, 'friction.json'), encoding='utf-8'))
    except (OSError, ValueError):
        return None
    return sum(1 for e in fr.get('entries', []) if e.get('brief') == bid and e.get('type') == 'refusal')


def brief(b):
    bid = b['id']
    wd = os.path.join(WORK, bid)
    shutil.rmtree(wd, ignore_errors=True)
    os.makedirs(wd)
    d = os.path.join(wd, 'design.bcd')
    t_all = time.time()
    kernel(d, 'new')
    rec = dict(id=bid, sentence=b['sentence'], process=b['process'], binary=BIN, parts=b['parts'], design_notes=b.get('notes', ''))
    steps, built = [], True
    pr = []
    for i, e in enumerate(b['edits']):
        s = apply(d, e)
        steps.append(s)
        pr += probes(d, wd, b, i)
        if s['status'] != 'committed':
            built = False
            break
    rec['edits'] = steps
    rec['built'] = built
    rec['build_incremental_s'] = round(sum(s['s'] for s in steps), 3)
    if built:
        pr += probes(d, wd, b, 'end')
        d1 = os.path.join(wd, 'oneshot.bcd')
        kernel(d1, 'new')
        one = kernel(d1, 'apply', *[x for e in b['edits'] for x in edit_args(e)])
        rec['build_oneshot'] = dict(s=one['s'], timeout=one['timeout'],
                                    committed=bool(re.search(r'^committed', one['out'], re.M)))
    else:
        rec['build_oneshot'] = None
    rec['probes'] = pr
    ev = kernel(d, 'eval')
    rec['eval'] = dict(s=ev['s'], out=clip(ev['out'], 6000))
    certs = {n: volume(node_line(ev['out'], n)) for n in b['parts']}
    rec['certified_volume'] = {str(n): v for n, v in certs.items()}
    have = [n for n in b['parts'] if certs.get(n)]
    rec['check'] = [dict(node=n, **{k: v for k, v in kernel(d, 'check', str(n)).items() if k != 'code'}) for n in have]
    rec['mass'] = [dict(node=n, **{k: v for k, v in kernel(d, 'mass', str(n)).items() if k != 'code'}) for n in have]
    for x in rec['check'] + rec['mass']:
        x['out'] = clip(x['out'], 1500)
    rec['step'] = [step_part(d, wd, n, certs[n]) for n in have]
    rec['tess'] = [tess_part(d, wd, n, certs[n]) for n in have]
    rec['stl_manufacturing'] = [stl_part(d, wd, n) for n in have[:1]]
    rec['checks'] = [run_check(d, c) for c in b['checks']] if built or b.get('check_partial') else \
        [dict(req=c['req'], verdict='not-analyzed', detail='design not built', cmd=None, s=0.0) for c in b['checks']]
    ed = b.get('edit')
    if built and ed:
        ea = apply(d, ed['edit'])
        after = dict(label=ed['label'], apply=ea)
        if ea['status'] == 'committed':
            p0 = b['parts'][0]
            ck = kernel(d, 'check', str(p0))
            ob = os.path.join(wd, 'edit.obj')
            ts = kernel(d, 'tess', str(p0), ob)
            after['check'] = dict(s=ck['s'], out=clip(ck['out'], 600))
            after['tess'] = dict(s=ts['s'], out=clip(ts['out'], 400), timeout=ts['timeout'])
            after['visible_rechecked_s'] = round(ea['s'] + ck['s'] + ts['s'], 3)
            after['checks'] = [run_check(d, c) for c in b['checks']]
        rec['timed_edit'] = after
    else:
        rec['timed_edit'] = None
    rec['budgets'] = budgets(rec)
    rec['verdicts'] = tally(rec['checks'])
    rec['authoring_refusals'] = friction_count(bid)
    rec['wall_s'] = round(time.time() - t_all, 1)
    rec['pass'] = bool(built and rec['verdicts']['fail'] == 0 and rec['verdicts']['not-analyzed'] == 0 and
                       all(s.get('agree') for s in rec['step']) and all(t.get('conforming') for t in rec['tess']) and
                       all(v['verdict'] == 'pass' for k, v in rec['budgets'].items() if k != 'scene'))
    if not KEEP:
        for f in os.listdir(wd):
            if f.endswith(('.stp', '.obj', '.stl', '.3mf')):
                os.remove(os.path.join(wd, f))
    json.dump(rec, open(os.path.join(OUT, f'{bid}.json'), 'w', encoding='utf-8', newline='\n'), indent=1)
    return rec


def verdict(x, lim):
    if x is None:
        return dict(verdict='not-measured', measured_s=None, budget_s=lim)
    return dict(verdict='pass' if x <= lim else 'fail', measured_s=x, budget_s=lim)


def budgets(rec):
    te = rec.get('timed_edit') or {}
    one = rec.get('build_oneshot') or {}
    part = None if not one or one.get('timeout') else one.get('s')
    stl = rec['stl_manufacturing'][0] if rec['stl_manufacturing'] else None
    st = rec['step'][0] if rec['step'] else None
    exp = None
    if stl and st and stl['ok'] and not st.get('timeout'):
        exp = round(stl['s'] + st['s'], 3)
    out = dict(edit=verdict(te.get('visible_rechecked_s'), BUDGET['edit_s']),
               part=verdict(part, BUDGET['part_s']),
               export=verdict(exp, BUDGET['export_s']),
               scene=dict(verdict='not-exercised', measured_s=None, budget_s=60.0))
    if stl and stl['timeout']:
        out['export'] = dict(verdict='fail', measured_s=f'>{stl["s"]} (timeout)', budget_s=BUDGET['export_s'])
    if one and one.get('timeout'):
        out['part'] = dict(verdict='fail', measured_s=f'>{one["s"]} (timeout)', budget_s=BUDGET['part_s'])
    return out


def tally(cs):
    t = {'pass': 0, 'fail': 0, 'not-analyzed': 0}
    for c in cs:
        if not c.get('info'):
            t[c['verdict']] += 1
    return t


def row(r):
    te = r.get('timed_edit_serial') or r.get('timed_edit') or {}
    ts = r['tess']
    st = r['step']
    occ = 'n/a' if not st else ('yes' if all(s.get('agree') for s in st) else 'no' if any(s.get('agree') is False for s in st) else 'n/a')
    conf = 'n/a' if not ts else ('yes' if all(t.get('conforming') for t in ts) else 'no')
    tris = sum(t.get('triangles') or 0 for t in ts)
    tsec = round(sum(t['s'] for t in ts), 2)
    one = r.get('build_oneshot') or {}
    v = r['verdicts']
    b = r['budgets']
    return dict(id=r['id'], binary=r.get('binary'), built=r['built'], build_s=r.get('build_oneshot_serial_s', one.get('s')), build_incremental_s=r['build_incremental_s'],
                refusals_probes=sum(1 for p in r['probes'] for s in p['steps'] if s['status'] != 'committed'),
                refusals_authoring=r.get('authoring_refusals'),
                checks=f"{v['pass']}/{v['fail']}/{v['not-analyzed']}", occt=occ, conforming=conf, triangles=tris, tess_s=tsec,
                edit_s=te.get('visible_rechecked_s'), budget_edit=b['edit']['verdict'], budget_part=b['part']['verdict'],
                budget_export=b['export']['verdict'], passed=r['pass'])


def finalize(r):
    b = r['budgets']
    stl = r['stl_manufacturing'][0] if r['stl_manufacturing'] else None
    if stl and not stl['ok'] and not stl['timeout']:
        b['export'] = dict(verdict='fail', measured_s=None, budget_s=BUDGET['export_s'], note='manufacturing STL refused: ' + stl['out'].strip()[:200])
    te = r.get('timed_edit_serial') or {}
    ta = (r.get('timed_edit') or {}).get('apply') or {}
    if te.get('apply_status') == 'rejected' or (not te and ta.get('status') == 'rejected'):
        b['edit'] = dict(verdict='fail', measured_s=None, budget_s=BUDGET['edit_s'], note='the timed edit was refused by the kernel')
    if te.get('visible_rechecked_s') is None and te.get('apply_status') == 'committed':
        b['edit'] = dict(verdict='fail', measured_s=None, budget_s=BUDGET['edit_s'], note='edit committed but the part could not be shown: ' + te.get('tess_out', '')[:200])
    if r.get('timed_edit_serial'):
        r['build_oneshot_serial_s'] = r['timed_edit_serial']['build_s']
    r['authoring_refusals'] = friction_count(r['id'])
    r['pass'] = bool(r['built'] and r['verdicts']['fail'] == 0 and r['verdicts']['not-analyzed'] == 0 and
                     all(s.get('agree') for s in r['step']) and all(t.get('conforming') for t in r['tess']) and
                     all(v['verdict'] == 'pass' for k, v in b.items() if k != 'scene'))
    return r


def summary():
    rows = []
    for b in BRIEFS:
        p = os.path.join(OUT, f"{b['id']}.json")
        if os.path.exists(p):
            r = finalize(json.load(open(p, encoding='utf-8')))
            json.dump(r, open(p, 'w', encoding='utf-8', newline='\n'), indent=1)
            rows.append(row(r))
    json.dump(dict(binary=BIN, budgets=BUDGET, rows=rows), open(os.path.join(OUT, 'summary.json'), 'w', encoding='utf-8', newline='\n'), indent=1)
    hd = ['brief', 'binary', 'built', 'kernel build s', 'refusals (authoring+probes)', 'checks p/f/na', 'OCCT agrees', 'mesh conforming', 'triangles',
          'tess s', 'edit s', 'edit 5 s', 'part 60 s', 'export 5 min', 'pass']
    lines = ['# Brief ladder', '', 'Each row names the binary its receipt was measured on. Generated by `tests/briefs/run.py` from `docs/receipts/briefs/<id>.json`.',
             'Kernel build and edit times are serial re-times (`--retime`) where present; tess, STEP, STL and check times were measured with up to seven briefs running at once on 16 cores.',
             'Refusals are authoring refusals from `friction.json` plus refused probe steps. Checks count requirements only (informational checks excluded). The 25-part scene budget is not exercised.', '',
             '| ' + ' | '.join(hd) + ' |', '|' + '---|' * len(hd)]
    for x in rows:
        lines.append('| ' + ' | '.join(str(v) for v in [x['id'], os.path.basename(x['binary'] or ''), 'yes' if x['built'] else 'no', x['build_s'],
                                                          f"{x['refusals_authoring']}+{x['refusals_probes']}", x['checks'], x['occt'],
                                                          x['conforming'], x['triangles'], x['tess_s'], x['edit_s'], x['budget_edit'],
                                                          x['budget_part'], x['budget_export'], 'yes' if x['passed'] else 'no']) + ' |')
    open(os.path.join(OUT, 'summary.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(lines) + '\n')
    return rows


def main():
    args = sys.argv[1:]
    jobs = 1
    if '--jobs' in args:
        i = args.index('--jobs')
        jobs = int(args[i + 1])
        del args[i:i + 2]
    if '--summary' in args:
        for x in summary():
            print(x)
        return
    if '--retime' in args:
        args.remove('--retime')
        for b in [b for b in BRIEFS if not args or b['id'] in args]:
            p = os.path.join(OUT, f"{b['id']}.json")
            if not os.path.exists(p) or not b.get('edit'):
                continue
            rec = json.load(open(p, encoding='utf-8'))
            if not rec['built']:
                continue
            wd = os.path.join(WORK, b['id'] + '-retime')
            shutil.rmtree(wd, ignore_errors=True)
            os.makedirs(wd)
            d = os.path.join(wd, 'design.bcd')
            kernel(d, 'new')
            one = kernel(d, 'apply', *[x for e in b['edits'] for x in edit_args(e)])
            ea = apply(d, b['edit']['edit'])
            t = dict(label=b['edit']['label'], build_s=one['s'], apply_s=ea['s'], apply_status=ea['status'])
            if ea['status'] == 'committed':
                p0 = b['parts'][0]
                ck = kernel(d, 'check', str(p0))
                ts = kernel(d, 'tess', str(p0), os.path.join(wd, 'edit.obj'))
                t.update(check_s=ck['s'], tess_s=ts['s'], tess_out=ts['out'][:300], visible_rechecked_s=round(ea['s'] + ck['s'] + ts['s'], 3))
            rec['timed_edit_serial'] = t
            rec['budgets']['edit'] = verdict(t.get('visible_rechecked_s'), BUDGET['edit_s'])
            rec['budgets']['edit']['note'] = 'serial re-time on an otherwise idle machine (timed_edit_serial); timed_edit holds the run under parallel load'
            rec['budgets']['part'] = verdict(one['s'], BUDGET['part_s'])
            rec['budgets']['part']['note'] = 'serial re-time of the one-shot build'
            rec['pass'] = bool(rec['built'] and rec['verdicts']['fail'] == 0 and rec['verdicts']['not-analyzed'] == 0 and
                               all(s.get('agree') for s in rec['step']) and all(x.get('conforming') for x in rec['tess']) and
                               all(v['verdict'] == 'pass' for k, v in rec['budgets'].items() if k != 'scene'))
            json.dump(rec, open(p, 'w', encoding='utf-8', newline='\n'), indent=1)
            for f in os.listdir(wd):
                if f.endswith('.obj'):
                    os.remove(os.path.join(wd, f))
            print(b['id'], t, flush=True)
        summary()
        return
    if '--edits-only' in args:
        args.remove('--edits-only')
        for b in [b for b in BRIEFS if b['id'] in args]:
            wd = os.path.join(WORK, b['id'] + '-dry')
            os.makedirs(wd, exist_ok=True)
            d = os.path.join(wd, 'design.bcd')
            kernel(d, 'new')
            for e in b['edits']:
                s = apply(d, e)
                print(b['id'], s['status'], s['s'], s['edit'][:100])
                if s['status'] != 'committed':
                    print(s['out'][-1500:])
                    break
            else:
                print(kernel(d, 'eval')['out'][-1200:])
        return
    want = [b for b in BRIEFS if not args or b['id'] in args]
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(WORK, exist_ok=True)
    with ProcessPoolExecutor(min(jobs, 8)) as ex:
        for r in ex.map(brief, want):
            print(json.dumps(row(r)), flush=True)
    summary()


if __name__ == '__main__':
    main()
