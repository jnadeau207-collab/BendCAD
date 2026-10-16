import importlib.util
import json
import math
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'perf-report.json')
BUDGETS = os.path.join(HERE, 'perf-budget.json')
BIN = os.environ.get('BENDCAD_BIN', '/home/jesse/bc/bendcad')
RESULTS = []
BLESS = '--bless' in sys.argv
SLOW = 60.0


def load_e2e():
    spec = importlib.util.spec_from_file_location('e2e_c13', os.path.join(HERE, 'e2e.py'))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


E = load_e2e()


def record(name, ok, **info):
    RESULTS.append(dict(name=name, ok=bool(ok), **info))
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in info.items() if k != 'detail'})


def best(n, fn):
    ts = sorted(fn() for _ in range(n))
    return ts[0]


def box_eval():
    def one():
        E.fresh('pb.bcd', E.BOX)
        _, t = E.cli('pb.bcd', 'eval')
        return t
    return best(3, one)


def bracket_commit():
    def one():
        _, t = E.fresh('pk.bcd', *E.BRACKET)
        _, u = E.cli('pk.bcd', 'eval')
        return t + u
    return best(3, one)


def bracket_tess():
    E.fresh('pt.bcd', *E.BRACKET)
    return best(3, lambda: E.cli('pt.bcd', 'tess', '4', f'{E.WORK}/pt.obj')[1])


def bracket_step():
    E.fresh('ps.bcd', *E.BRACKET)
    return best(2, lambda: E.cli('ps.bcd', 'step', '4', f'{E.WORK}/ps.stp')[1])


def slab_archive():
    def one():
        E.fresh('pa.bcd', E.PATCH(E.RECT_PTS), E.THICK(1, 2.0, 2))
        _, t = E.cli('pa.bcd', 'archive', '2', f'{E.WORK}/pa.bin')
        _, u = E.wsl(BIN, 'geom', 'reopen', f'{E.WORK}/pa.bin', '-v')
        return t + u
    return best(2, one)


def g3_parts():
    d = os.path.join(E.WORK, 'pg3')
    t = time.time()
    r = subprocess.run([sys.executable, os.path.join(E.ROOT, 'tools', 'g3', 'gearbox.py'), d, 'parts'],
                       capture_output=True, text=True, timeout=3600,
                       env=dict(os.environ, BENDCAD_BIN=BIN, BEND_NO_TELEMETRY='1'))
    if r.returncode != 0:
        raise RuntimeError(f'gearbox parts exit {r.returncode}: {(r.stdout + r.stderr)[-300:]}')
    return time.time() - t


OPS = [('box.eval', box_eval), ('bracket.commit', bracket_commit), ('bracket.tess', bracket_tess),
       ('bracket.step', bracket_step), ('slab.archive', slab_archive), ('g3.parts', g3_parts)]


def bless_budget(obs):
    return math.ceil(max(30.0, obs * (4.0 if obs >= SLOW else 8.0)))


def main():
    E.wsl('rm', '-rf', E.WORK)
    E.wsl('mkdir', '-p', E.WORK)
    want = [a for a in sys.argv[1:] if not a.startswith('-')]
    budgets = json.load(open(BUDGETS)).get('budgets', {}) if os.path.exists(BUDGETS) else {}
    if BLESS:
        budgets = {}
    for name, fn in OPS:
        if want and not any(w in name for w in want):
            continue
        t = time.time()
        try:
            obs = fn()
            err = None
        except Exception as e:
            obs = None
            err = f'{type(e).__name__}: {e}'[:300]
        if BLESS and obs is not None:
            budgets[name] = bless_budget(obs)
        bud = budgets.get(name)
        ok = obs is not None and bud is not None and obs <= bud
        record(name, ok if not BLESS else obs is not None, seconds=round(obs, 1) if obs is not None else None,
               budget=bud, wall=round(time.time() - t, 1), error=err)
    if BLESS:
        json.dump(dict(version=1, budgets=budgets), open(BUDGETS, 'w'), indent=1, sort_keys=True)
    rep = dict(binary=BIN, binary_sha256=E.wsl('sha256sum', BIN)[0].split()[0],
               passed=sum(r['ok'] for r in RESULTS), total=len(RESULTS), results=RESULTS)
    json.dump(rep, open(OUT, 'w'), indent=1)
    print(f"{rep['passed']}/{rep['total']} perf ops hold")
    sys.exit(0 if rep['passed'] == rep['total'] else 1)


if __name__ == '__main__':
    main()
