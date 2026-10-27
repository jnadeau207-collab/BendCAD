import itertools, re, subprocess, sys, time, os, concurrent.futures as cf
Q = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'q')
D = '/home/jesse/g2/parts/gearpump.bcd'
B = '/home/jesse/bc/bendcad-g2'
sol = open(os.path.join(Q, 'master_solve.txt')).read()
ins = [(m.group(1), m.group(2), [float(x) for x in m.group(3).split()]) for m in re.finditer(r'inst (\S+) node (\d+) t=(\S+ \S+ \S+) q=0', sol)]
def run(pair):
    (na, da, ta), (nb, db, tb) = pair
    f = '(assembly (inst %s %s %r %r %r 0) (inst %s %s %r %r %r 0) (fix 1 %s) (fix 2 %s))' % (na, da, *ta, nb, db, *tb, na, nb)
    t = time.time()
    try:
        r = subprocess.run(['wsl.exe', '-e', B, D, 'asm', 'interf', f], capture_output=True, text=True, timeout=600,
                           env=dict(os.environ, MSYS_NO_PATHCONV='1'))
        out = r.stdout + r.stderr
    except subprocess.TimeoutExpired:
        out = 'TIMEOUT 600s'
    dt = time.time() - t
    rel = next((ln for ln in out.splitlines() if ln.startswith('relation') or 'TIMEOUT' in ln or 'error' in ln), out[:120])
    open(os.path.join(Q, 'pairs', '%s__%s.txt' % (na, nb)), 'w').write(f + '\n' + out)
    return na, nb, dt, rel
pairs = list(itertools.combinations(ins, 2))
with cf.ThreadPoolExecutor(12) as ex:
    for na, nb, dt, rel in ex.map(run, pairs):
        print('%-18s %-18s %7.1fs %s' % (na, nb, dt, rel[:110]), flush=True)
