import hashlib
import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'solid-neg-report.json')
BIN = '/tmp/bc-solid-neg'

PEN = ('edge-face-penetration', 'face-penetration', 'edge-crossing', 'edge-face-overlap', 'face-overlap', 'edge-overlap')
WANT = {
    'ok.box': lambda c: c == ['ok'],
    'ok.disjoint': lambda c: c == ['ok'],
    'inverted': lambda c: c == ['inverted-shell'],
    'overlap.boxes': lambda c: 'edge-face-penetration' in c,
    'cavity.ok': lambda c: c == ['ok'],
    'cavity.curved': lambda c: c == ['ok'],
    'cavity.unflipped': lambda c: c == ['inverted-shell'],
    'cavity.outside': lambda c: 'cavity-outside' in c,
    'cavity.nested': lambda c: 'cavities-nested' in c,
    'cavity.crossing': lambda c: 'edge-face-penetration' in c,
    'touch.face': lambda c: c != ['ok'] and any(k in c for k in PEN),
    'touch.edge': lambda c: c != ['ok'] and any(k in c for k in PEN),
    'overlap.sphere': lambda c: any(k in c for k in PEN),
}


def wsl(cmd, timeout):
    pre = ['wsl.exe', '-e'] if os.name == 'nt' else []
    return subprocess.run([*pre, 'bash', '-lc', cmd], capture_output=True, text=True, timeout=timeout)


def main():
    t = time.time()
    b = wsl(f'cd /mnt/c/dev/BendCAD 2>/dev/null || cd {os.path.dirname(os.path.dirname(HERE))}; '
            f'PATH=$HOME/.bend/bin:$PATH bend tests/c07/solid_neg.bend -o {BIN}', 3600)
    build_s = time.time() - t
    t = time.time()
    r = wsl(BIN, 3600)
    run_s = time.time() - t
    results = []
    seen = set()
    for ln in r.stdout.splitlines():
        if not ln.startswith('CASE '):
            continue
        name, rest = ln[5:].split(': ', 1)
        codes = ['ok'] if rest.strip() == 'ok' else sorted({f.split()[0] for f in rest.split(';') if f.strip()})
        ok = WANT[name](codes)
        seen.add(name)
        results.append(dict(name=name, ok=ok, codes=codes, findings=rest.strip()))
        print(('PASS ' if ok else 'FAIL ') + name, codes)
    for name in WANT:
        if name not in seen:
            results.append(dict(name=name, ok=False, codes=[], findings='missing'))
            print('FAIL ' + name, 'missing', b.stderr[-400:])
    rep = dict(passed=sum(x['ok'] for x in results), total=len(results), build_s=round(build_s, 1), run_s=round(run_s, 2), results=results)
    blob = json.dumps(rep, indent=1, sort_keys=True)
    open(OUT, 'w', newline='\n').write(blob)
    print(f"{rep['passed']}/{rep['total']} passed in {rep['run_s']}s; sha256 {hashlib.sha256(json.dumps(results, sort_keys=True).encode()).hexdigest()}")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
