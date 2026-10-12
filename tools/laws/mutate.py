import hashlib
import json
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
WORK = os.environ.get('MUT_WORK', '/tmp/bendcad-mut')
BEND = os.environ.get('BEND', os.path.expanduser('~/.bend/bin/bend'))

MUTANTS = [
    ('c00', 'failure keeps the model', 'src/c00/eval.bend',
     '    case True{}:\n      T.mk_failed(T.F_exhausted{}, m, id)',
     '    case True{}:\n      T.mk_failed(T.F_exhausted{}, T.model_seed(), id)'),
    ('c00', 'outcome attributed to its request', 'src/c00/eval.bend',
     '      T.mk_failed(T.F_cancelled{}, m, id)', '      T.mk_failed(T.F_cancelled{}, m, 0u64)'),
    ('c01', 'transpose involution', 'src/c01/types.bend',
     '  M3{a, d, g, b, e, h, c, f, i}', '  M3{a, d, g, b, e, h, f, c, i}'),
    ('c01', 'negation involution', 'src/c01/types.bend',
     '  V3{F64.neg(x), F64.neg(y), F64.neg(z)}', '  V3{F64.neg(x), F64.neg(y), F64.abs(z)}'),
    ('c01', 'frame/rigid round trip', 'src/c01/ops.bend',
     '  V.Fr{tx, ty, tz, a, d, g, b, e, h, c, f, i}', '  V.Fr{tx, ty, tz, a, b, g, d, e, h, c, f, i}'),
    ('c02', 'triangle winding invariance', 'src/c02/ops.bend',
     '  +bad = Bool.or(Bool.and(o0neg, pp), Bool.and(Bool.not(o0neg), nn))',
     '  +bad = Bool.or(Bool.and(o0neg, pp), Bool.and(Bool.not(o0neg), pp))'),
    ('c02', 'proper crossing', 'src/c02/ops.bend',
     '  +proper = Bool.and(o12, o34)', '  +proper = Bool.and(o12, Bool.and(o34, z1))'),
    ('base', 'parallel map is map', 'src/base/par.bend',
     '          List.append(&2, B, a, b)', '          List.append(&2, B, b, a)'),
    ('base', 'table read after write', 'src/base/par.bend',
     '    case TL{v} _: TL{x}', '    case TL{v} _: TL{v}'),
    ('base', 'split rejoins', 'src/base/par.bend',
     '    case h <> t False{}: drop_u(A, t, (k - 1 : U32), U32.is_eq(k, 1))',
     '    case h <> t False{}: drop_u(A, t, (k - 1 : U32), U32.is_eq(k, 2))'),
    ('c03', 'split halves meet', 'src/c03/ops.bend',
     '    case True{}: G.gok_bz(G.Bz{f, e, c, p3})', '    case True{}: G.gok_bz(G.Bz{e, e, c, p3})'),
    ('c03', 'domain split', 'src/c03/ops.bend',
     '        case True{}: G.gok_dom(G.Dom{t, hi})', '        case True{}: G.gok_dom(G.Dom{lo, hi})'),
    ('c04', 'validator returns its input', 'src/c04/ops.bend',
     'Bool.pick(Ty.TRes, verdict(b, prof, fuel), Ty.tok_brep(b), Ty.terr(T.F_invalid{}))',
     'Bool.pick(Ty.TRes, verdict(b, prof, fuel), Ty.tok_brep(Ty.brep_empty()), Ty.terr(T.F_invalid{}))'),
    ('c06', 'one entry per node', 'src/c06/model.bend',
     '      ev_nodes(t, e, old, CE{nd, key, r} <> acc, all)', '      ev_nodes(t, e, old, CE{0u64, key, r} <> acc, all)'),
    ('c06', 'intent mismatch refused', 'src/c06/model.bend',
     '    case True{}: NR_ok{r, f}\n    case False{}:\n      bad("intent"',
     '    case False{}: NR_ok{r, f}\n    case True{}:\n      bad("intent"'),
    ('c07', 'key order reflexive', 'src/c07/sym.bend',
     '        case []: B.Sz{}\n        case y <> u: B.Sn{}', '        case []: B.Sn{}\n        case y <> u: B.Sn{}'),
    ('c07', 'polynomial negation involution', 'src/c07/sym.bend',
     '      Mo{E.ex_neg(c), ks} <> p_neg(t)', '      Mo{E.ex_neg(c), []} <> p_neg(t)'),
    ('c07', 'key order antisymmetric', 'src/c07/sym.bend',
     'Bool.pick(B.Sgn, U64.is_lt(y, x), B.Sp{}, k_cmp(t, u))', 'Bool.pick(B.Sgn, U64.is_lt(y, x), B.Sn{}, k_cmp(t, u))'),
    ('c08', 'samples decide the regularized outcome', 'src/c08/bool.bend',
     'U64.is_eq(aggb, agg_in())), dec_bina(), 3u64)', 'U64.is_eq(aggb, agg_in())), dec_ainb(), 3u64)'),
    ('c08', 'regularized outcome table', 'src/c08/bool.bend',
     'Bool.pick(U64, Bool.or(U64.is_eq(code, fc_out()), U64.is_eq(code, fc_opp())), 1u64, 0u64)',
     'Bool.pick(U64, Bool.or(U64.is_eq(code, fc_in()), U64.is_eq(code, fc_opp())), 1u64, 0u64)'),
    ('c08', 'empty algebra', 'src/c08/bool.bend',
     '    case False{}: Bool.pick(U64, U64.is_eq(op, tag_inter()), 3u64, 0u64)',
     '    case False{}: Bool.pick(U64, U64.is_eq(op, tag_diff()), 3u64, 0u64)'),
    ('c09', 'frustum loops closed and balanced', 'src/c09/feat.bend',
     'use_of(9n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64))', 'use_of(9n, False{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64))'),
    ('c09', 'fillet closed solid', 'src/c09/feat.bend',
     '  [2n, 8n, 11n, 5n, 17n, 23n, 20n, 14n, 1n, 4n, 16n, 13n, 19n, 22n, 10n, 7n, 12n, 18n, 6n, 0n, 3n, 9n, 21n, 15n]',
     '  [2n, 8n, 11n, 5n, 17n, 23n, 20n, 14n, 1n, 4n, 16n, 13n, 19n, 22n, 10n, 7n, 12n, 18n, 6n, 0n, 3n, 9n, 15n, 21n]'),
    ('c09', 'frustum edge ends', 'src/c09/feat.bend',
     '  [1n, 2n, 3n, 0n, 5n, 6n, 7n, 4n, 4n, 5n, 6n, 7n]', '  [1n, 2n, 3n, 0n, 5n, 6n, 7n, 4n, 4n, 5n, 6n, 8n]'),
    ('c10', 'quality constructor keeps fields', 'src/c10/mesh.bend',
     'def q_mk(+chord: F64, +angle: F64, +max_tris: Nat, +profile: U64) -> Q:\n  Q{chord, angle, max_tris, profile}',
     'def q_mk(+chord: F64, +angle: F64, +max_tris: Nat, +profile: U64) -> Q:\n  Q{angle, chord, max_tris, profile}'),
    ('c10', 'success marks ok', 'src/c10/mesh.bend',
     '  Tres{True{}, "", obj, nv, nt, est, chord, ang, nsamp}',
     '  Tres{False{}, "", obj, nv, nt, est, chord, ang, nsamp}'),
    ('c10', 'over budget refuses and keeps the estimate', 'src/c06/tess.bend',
     '    case False{}: M10.tres_fail_est("tess-budget-exceeded", est)\n    case True{}: pri_emit(b, q, est)',
     '    case False{}: pri_emit(b, q, est)\n    case True{}: M10.tres_fail_est("tess-budget-exceeded", est)'),
    ('c10', 'side strip delivers the estimate', 'src/c06/tess.bend',
     '          Tri{b, bn, tn} <> Tri{b, tn, t} <> strip_go(bt, tt, b0, t0)',
     '          Tri{b, bn, tn} <> strip_go(bt, tt, b0, t0)'),
    ('c10', 'ring indices in range', 'src/c06/tess.bend',
     '    case 1n+m: b <> n_seq(m, Nat.add(b, 1n))',
     '    case 1n+m: Nat.add(b, 1n) <> n_seq(m, Nat.add(b, 1n))'),
    ('c10', 'open curves sample from one', 'src/c10/mesh.bend',
     '  Bool.pick(Nat, edge_closed(g, d), 3n, 1n)', '  Bool.pick(Nat, edge_closed(g, d), 3n, 2n)'),
]


def check(pkt):
    r = subprocess.run([BEND, f'laws/{pkt}/PROOF.bend', '--check-only'], cwd=WORK, capture_output=True, text=True, timeout=7200)
    out = (r.stdout + r.stderr).strip().splitlines()
    return out[0] if out else ''


def main():
    only = sys.argv[1:]
    rows = []
    for pkt, name, path, old, new in MUTANTS:
        if only and pkt not in only:
            continue
        shutil.rmtree(WORK, ignore_errors=True)
        shutil.copytree(ROOT, WORK, ignore=shutil.ignore_patterns('.git', '__pycache__', 'e2e-meshes'))
        f = os.path.join(WORK, path)
        s = open(f, encoding='utf-8').read()
        if s.count(old) != 1:
            rows.append(dict(pkt=pkt, law=name, ok=False, verdict='mutation site not unique: %d' % s.count(old)))
            print('FAIL', pkt, name, rows[-1]['verdict'], flush=True)
            continue
        open(f, 'w', encoding='utf-8', newline='\n').write(s.replace(old, new))
        v = check(pkt)
        ok = v == 'SOME PROOFS FAIL'
        rows.append(dict(pkt=pkt, law=name, file=path, ok=ok, verdict=v))
        print('PASS' if ok else 'FAIL', pkt, name, '->', v, flush=True)
    if only:
        rp = os.path.join(ROOT, 'tools', 'laws', 'mutate-report.json')
        names = {(m[0], m[1]) for m in MUTANTS}
        old = json.load(open(rp)) if os.path.exists(rp) else []
        rows = [r for r in old if r['pkt'] not in only and (r['pkt'], r['law']) in names] + rows
        rows.sort(key=lambda r: [m[:2] for m in MUTANTS].index((r['pkt'], r['law'])))
    blob = json.dumps(rows, indent=1)
    open(os.path.join(ROOT, 'tools', 'laws', 'mutate-report.json'), 'w', newline='\n').write(blob + '\n')
    bad = [r for r in rows if not r['ok']]
    print(f'{len(rows) - len(bad)}/{len(rows)} mutants killed; sha256 {hashlib.sha256(blob.encode()).hexdigest()}')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
