import json
import os
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blower

ROOT = blower.ROOT
BIN = os.environ['BENDCAD_BIN']
WORK = os.environ.get('G4_WORK', '/tmp/bendcad-g4')
RUN1 = os.path.join(ROOT, 'docs', 'receipts', 'g4', 'run1')
RUN = os.path.join(ROOT, 'docs', 'receipts', 'g4', sys.argv[1] if len(sys.argv) > 1 else 'run2')
EXP = os.path.join(WORK, 'export')
DESIGN = os.path.join(WORK, 'g4.bcd')


def cli(*a, timeout=86400):
    t = time.time()
    p = subprocess.run([BIN, DESIGN, *a], capture_output=True, text=True, timeout=timeout)
    return p.stdout + p.stderr, round(time.time() - t, 1)


def job(t):
    tag, args = t
    out, dt = cli(*args)
    return dict(job=tag, seconds=dt, tail=out.strip().splitlines()[-1][:300] if out.strip() else '')


if __name__ == '__main__':
    os.makedirs(EXP, exist_ok=True)
    for d in ('calc', 'q'):
        shutil.copytree(os.path.join(RUN1, d), os.path.join(RUN, d), dirs_exist_ok=True)
    shutil.copy(os.path.join(RUN1, 'parts.txt'), RUN)
    if os.path.exists(DESIGN):
        os.remove(DESIGN)
    subprocess.run([BIN, DESIGN, 'new'], capture_output=True)
    out, dt = cli('apply', *blower.master_edits())
    log = dict(binary=BIN, sha256=subprocess.run(['sha256sum', BIN], capture_output=True, text=True).stdout.split()[0],
               master_committed='committed' in out, master_seconds=dt, jobs=[])
    print('master', log['master_committed'], dt, flush=True)
    if not log['master_committed']:
        log['master_tail'] = out[-3000:]
    else:
        jobs = [('step_%s' % n, ['step', str(i), '%s/%s.stp' % (EXP, n)]) for n, i in blower.PART_NODES]
        jobs += [('stl_%s' % n, ['stl', str(i), '%s/%s.stl' % (EXP, n), '3']) for n, i in blower.PART_NODES]
        jobs.append(('step_assembly', ['asm', 'step', '%s/blower_assembly.stp' % EXP, blower.assembly()]))
        with ThreadPoolExecutor(int(os.environ.get('JOBS', '2'))) as ex:
            for r in ex.map(job, jobs):
                log['jobs'].append(r)
                print(r['job'], r['seconds'], r['tail'][:120], flush=True)
    json.dump(log, open(os.path.join(RUN, 'export_log.json'), 'w'), indent=1)
    if log['master_committed']:
        g = subprocess.run([sys.executable, os.path.join(ROOT, 'tools', 'grade', 'g4.py'), RUN, EXP], capture_output=True, text=True, cwd=RUN)
        open(os.path.join(RUN, 'grade.log'), 'w').write(g.stdout + g.stderr)
        print(g.stdout[-2000:])
