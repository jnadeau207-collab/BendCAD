import collections
import json
import os
import subprocess
import sys
import time
import urllib.request

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
BIN = os.environ.get('G5_BIN', '/home/jesse/bc/bendcad')
PORT = int(os.environ.get('G5_VIEW_PORT', '8791'))
WROOT = '/mnt/' + ROOT[0].lower() + ROOT[2:].replace('\\', '/')


def wsl(cmd, timeout=600):
    return subprocess.run(['wsl.exe', '-e', 'bash', '-lc', cmd], capture_output=True, text=True, timeout=timeout,
                          env=dict(os.environ, MSYS_NO_PATHCONV='1'))


def get(path):
    with urllib.request.urlopen(f'http://127.0.0.1:{PORT}{path}', timeout=60) as r:
        return r.status, r.headers.get('Content-Type', ''), r.read().decode('utf-8', 'replace')


def status(path):
    try:
        return get(path)[0]
    except urllib.error.HTTPError as e:
        return e.code


def obj_check(txt):
    vs = [tuple(map(float, l.split()[1:4])) for l in txt.splitlines() if l.startswith('v ')]
    fs = [[int(x.split('/')[0]) for x in l.split()[1:]] for l in txt.splitlines() if l.startswith('f ')]
    key = {}
    ids = []
    for v in vs:
        ids.append(key.setdefault(v, len(key)))
    ec = collections.Counter()
    vol = 0.0
    for f in fs:
        a, b, c = (vs[i - 1] for i in f[:3])
        vol += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0]) + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
        w = [ids[i - 1] for i in f[:3]]
        for i in range(3):
            ec[(w[i], w[(i + 1) % 3])] += 1
    unpaired = sum(1 for (a, b), n in ec.items() if ec.get((b, a), 0) != n)
    return {'verts': len(vs), 'tris': len(fs), 'unpaired_directed_edges': unpaired, 'volume': vol}


def main(scene_rel, out, oracle=None):
    rep = {'binary': BIN, 'scene': scene_rel, 'checks': []}
    ref = json.load(open(oracle)) if oracle else {}

    def chk(name, ok, **kw):
        rep['checks'].append(dict(name=name, ok=bool(ok), **kw))
        print(('PASS ' if ok else 'FAIL ') + name, kw if kw else '', flush=True)

    wsl(f'cd /var/tmp && setsid {BIN} view {PORT} {WROOT}/viewer < /dev/null > /var/tmp/e2e_view.log 2>&1 & sleep 1')
    pid = wsl(f"pgrep -f '^{BIN} view {PORT}'").stdout.split()[0]
    try:
        for _ in range(100):
            try:
                get('/index.html')
                break
            except OSError:
                time.sleep(0.1)
        s, ct, html = get('/')
        chk('root serves the viewer page', s == 200 and 'text/html' in ct and 'bcview.js' in html)
        s, ct, js = get('/bcview.js')
        chk('viewer script served', s == 200 and 'javascript' in ct and 'MediaRecorder' in js and 'explode' in js)
        chk('missing file is 404', status('/no/such.obj') == 404)
        chk('path traversal refused', status('/../README.md') == 404)
        s, ct, sj = get('/' + scene_rel)
        sc = json.loads(sj)
        chk('scene json served', s == 200 and 'json' in ct, parts=len(sc['parts']))
        base = '/' + scene_rel.rsplit('/', 1)[0] + '/'
        for p in sc['parts']:
            s, ct, txt = get(base + p['mesh'])
            m = obj_check(txt)
            rv = ref.get(p['name'], {}).get('volume')
            close = rv is None or abs(m['volume'] - rv) <= 0.03 * rv
            chk(f"mesh {p['name']} closed, outward, volume matches OCCT", s == 200 and m['tris'] == p['tris'] and m['unpaired_directed_edges'] == 0
                and m['volume'] > 0 and close, node=p['node'], tris=m['tris'], volume=round(m['volume'], 3), occt_volume=rv, spin=p['rotor'])
        rot = [p['name'] for p in sc['parts'] if p['rotor'] > 0]
        chk('scene has a rotor group for run mode', len(rot) > 0, rotor=rot)
        chk('scene has explode offsets', any(any(p['explode']) for p in sc['parts']))
    finally:
        wsl(f'kill {pid}')
    rep['pass'] = all(c['ok'] for c in rep['checks'])
    json.dump(rep, open(out, 'w'), indent=1)
    print('PASS' if rep['pass'] else 'FAIL', sum(c['ok'] for c in rep['checks']), '/', len(rep['checks']))
    return rep['pass']


if __name__ == '__main__':
    sys.exit(0 if main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None) else 1)
