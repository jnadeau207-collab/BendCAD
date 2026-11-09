import json
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
DESIGN = '/var/tmp/agent_demo.bcd'
VIEW = os.path.join(ROOT, 'viewer', 'demo')
WVIEW = '/mnt/' + VIEW[0].lower() + VIEW[2:].replace('\\', '/')
IC, IR, IS, IA = (f'(intent {k} any any any any)' for k in ('create', 'remove', 'same', 'add'))


def run(*args):
    t0 = time.time()
    p = subprocess.run(['wsl.exe', '-e', BIN, DESIGN, *args], capture_output=True, text=True,
                       env=dict(os.environ, MSYS_NO_PATHCONV='1'), stdin=subprocess.DEVNULL, timeout=600)
    return (p.stdout + p.stderr).strip(), round(time.time() - t0, 2)


def last(out, *keys):
    lines = [ln for ln in out.splitlines() if not keys or any(k in ln for k in keys)]
    return lines[-1] if lines else out


steps = []


def step(say, args, expect, show=None, pick=None):
    out, dt = run(*args)
    rec = dict(say=say, cmd='bendcad design ' + ' '.join(args), seconds=dt, reply=out, show=show or [])
    rec['key'] = pick(out) if pick else last(out)
    rec['ok'] = expect(out)
    steps.append(rec)
    print(('PASS ' if rec['ok'] else 'FAIL ') + say + f'  ({dt}s)\n    {rec["key"][:220]}', flush=True)
    return out


subprocess.run(['wsl.exe', '-e', 'rm', '-f', DESIGN])
step('Agent creates a design file', ['new'], lambda o: 'created' in o)
step('Agent builds a 60x40x10 mm plate with an 8 mm through hole, declaring the intent of every node',
     ['apply', f'(node 1 (box 60 40 10) {IC})', f'(node 2 (cylinder 4 10) {IC})', f'(node 3 (move 2 30 20 0 0) {IS})', f'(node 4 (difference 1 3) {IR})'],
     lambda o: o.strip().endswith('committed'), show=['plate_one_hole'], pick=lambda o: last(o, 'node 4:'))
exact = 60 * 40 * 10 - 3.141592653589793 * 16 * 10
step(f'Agent asks for the certified volume (exact answer {exact:.6f} mm3)', ['mass', '4'],
     lambda o: (lambda a, b: a <= exact <= b)(*map(float, o.split('volume=[')[1].split(']')[0].split(', '))), pick=lambda o: last(o, 'volume='))
step('Agent adds a 6 mm bolt through the hole', ['apply', f'(node 5 (cylinder 3 25) {IC})', f'(node 6 (move 5 30 20 -5 0) {IS})'],
     lambda o: o.strip().endswith('committed'), show=['plate_one_hole', 'bolt'], pick=lambda o: last(o, 'node 6:'))
step('Agent checks bolt-to-hole clearance: proven, not sampled', ['clearance', '4', '6', '0.001'],
     lambda o: 'certified' in o and '[0.99' in o, pick=lambda o: last(o, 'clearance'))
step('Agent tries a second hole but declares it ADDS material (a reasoning slip)',
     ['apply', f'(node 30 (cylinder 2 10) {IC})', f'(node 31 (move 30 10 10 0 0) {IS})', f'(node 32 (difference 4 31) {IA})'],
     lambda o: 'rejected: the design was not changed' in o and 'fix:' in o, pick=lambda o: last(o, 'node 32:'))
step('Kernel refused with the measured effect and a fix; agent corrects the declared intent',
     ['apply', f'(node 30 (cylinder 2 10) {IC})', f'(node 31 (move 30 10 10 0 0) {IS})', f'(node 32 (difference 4 31) {IR})'],
     lambda o: o.strip().endswith('committed'), show=['plate', 'bolt'], pick=lambda o: last(o, 'node 32:'))
exact2 = exact - 3.141592653589793 * 4 * 10
step(f'Agent re-checks the volume (exact {exact2:.6f} mm3)', ['mass', '32'],
     lambda o: (lambda a, b: a <= exact2 <= b)(*map(float, o.split('volume=[')[1].split(']')[0].split(', '))), pick=lambda o: last(o, 'volume='))
subprocess.run(['wsl.exe', '-e', 'mkdir', '-p', WVIEW])
step('Kernel tessellates the result for the viewer, tagged by B-rep face',
     ['scene', WVIEW, 'Agent loop demo', 'plate_one_hole', '4', '0.7', '0.72', '0.75', '0', '0', '0', '0', 'plate', '32', '0.7', '0.72', '0.75', '0', '0', '0', '0', 'bolt', '6', '0.5', '0.5', '0.5', '0', '0', '0', '30'],
     lambda o: 'wrote' in o and 'parts 3' in o, pick=lambda o: o.splitlines()[-1][:200])
sc = json.load(open(os.path.join(VIEW, 'scene.json'), encoding='utf-8'))
look = {'plate_one_hole': ('aluminum-machined', 'AlZn5.5MgCu-T6', 2810, 'bracket'), 'plate': ('aluminum-machined', 'AlZn5.5MgCu-T6', 2810, 'bracket'), 'bolt': ('stainless-bright', 'A2-70', 7900, 'fastener')}
for p in sc['parts']:
    p['finish'], p['grade'], p['density'], p['group'] = look[p['name']]
sc['subtitle'] = 'Agent loop: edit, prove, refuse, correct'
json.dump(sc, open(os.path.join(VIEW, 'scene.json'), 'w', encoding='utf-8'), indent=1)
rep = dict(binary=BIN, sha256=subprocess.run(['wsl.exe', '-e', 'sha256sum', BIN], capture_output=True, text=True).stdout.split()[0],
           steps=steps, pass_=all(s['ok'] for s in steps))
json.dump(rep, open(os.path.join(VIEW, 'transcript.json'), 'w', encoding='utf-8'), indent=1)
print('PASS' if rep['pass_'] else 'FAIL', sum(s['ok'] for s in steps), '/', len(steps))
sys.exit(0 if rep['pass_'] else 1)
