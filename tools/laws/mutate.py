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
    ('c11', 'box constructor keeps fields', 'src/c11/qaccel.bend',
     'def ab_mk(+x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64) -> Ab:\n  Ab{x0, x1, y0, y1, z0, z1}',
     'def ab_mk(+x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64) -> Ab:\n  Ab{x1, x0, y0, y1, z0, z1}'),
    ('c11', 'overlap is not disjoint', 'src/c11/qaccel.bend',
     'def ab_overlap(+a: Ab, +b: Ab) -> Bool:\n  Bool.not(ab_disjoint(a, b))',
     'def ab_overlap(+a: Ab, +b: Ab) -> Bool:\n  ab_disjoint(a, b)'),
    ('c11', 'bound constructor keeps fields', 'src/c11/qcert.bend',
     'def bv_mk(+lo: F64, +hi: F64, +st: U64) -> Bv:\n  Bv{lo, hi, st}',
     'def bv_mk(+lo: F64, +hi: F64, +st: U64) -> Bv:\n  Bv{hi, lo, st}'),
    ('c11', 'failure measures nothing', 'src/c11/qdist.bend',
     'def dist_s(r: M.NR, +x: F64, +y: F64, +z: F64) -> String:\n  match r:\n    case M.NR_err{k, d}: "error: node failed; nothing measured"',
     'def dist_s(r: M.NR, +x: F64, +y: F64, +z: F64) -> String:\n  match r:\n    case M.NR_err{k, d}: "error: node failed; nothing gauged"'),
    ('c11', 'disjoint verdict says disjoint', 'src/c11/qinterf.bend',
     'def rel_pair_go(dis: Bool, +a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> String:\n  match dis:\n    case True{}: "relation disjoint status=certified"',
     'def rel_pair_go(dis: Bool, +a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> String:\n  match dis:\n    case True{}: "relation uncertain status=estimated"'),
    ('c11', 'empty summary counts zero', 'src/c11/qsect.bend',
     'def cnt(hs: List<&2, Y.Hx>, +k: U64) -> Nat:\n  match hs:\n    case []: 0n',
     'def cnt(hs: List<&2, Y.Hx>, +k: U64) -> Nat:\n  match hs:\n    case []: 1n'),
    ('c11', 'nothing is a member of nothing', 'src/c11/qaccel.bend',
     'def n_mem(+x: Nat, ys: List<&2, Nat>) -> Bool:\n  match ys:\n    case []: False{}',
     'def n_mem(+x: Nat, ys: List<&2, Nat>) -> Bool:\n  match ys:\n    case []: True{}'),
    ('c11', 'depth parses its digits', 'src/c11/qmass.bend',
     'def mass_dn(m: Maybe<&2, U64>) -> Nat:\n  match m:\n    case None{}: 99n\n    case Some{v}: U64.to_nat(v)',
     'def mass_dn(m: Maybe<&2, U64>) -> Nat:\n  match m:\n    case None{}: 99n\n    case Some{v}: 99n'),
    ('c11', 'inside names its side', 'src/c11/qinterf.bend',
     '"relation inside a-in-b status=certified"', '"relation inside b-in-a status=certified"'),
    ('c11', 'witness refusal stays silent', 'src/c11/qinterf.bend',
     'def wit_go(+ovl: Bool, +a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> Bool:\n  match ovl:\n    case False{}: False{}',
     'def wit_go(+ovl: Bool, +a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> Bool:\n  match ovl:\n    case False{}: True{}'),
    ('c11', 'witness verdict says interference', 'src/c11/qinterf.bend',
     '"relation interference status=certified witness=subdiv"', '"relation uncertain status=estimated"'),
    ('c11', 'witness search short-circuits', 'src/c11/qinterf.bend',
     '      match hit:\n        case True{}: True{}', '      match hit:\n        case True{}: False{}'),
    ('c12', 'archive units gate', 'src/c12/blob.bend',
     'def ar_units_ok(+u: String) -> Bool:\n  String.eq(u, "mm")',
     'def ar_units_ok(+u: String) -> Bool:\n  True{}'),
    ('c12', 'entity classifier names its kind', 'src/c12/stepr.bend',
     'Bool.pick(U64, String.eq(s, "CARTESIAN_POINT"), 1u64,',
     'Bool.pick(U64, String.eq(s, "CARTESIAN_POINT"), 2u64,'),
    ('c12', 'writer counts its units block', 'src/c12/stepw.bend',
     'Nat.add(er2_n(r), 19n), np}', 'Nat.add(er2_n(r), 20n), np}'),
    ('c12', 'entity cap refusal keeps its name', 'src/c12/stepr.bend',
     'step-too-many-entities', 'step-too-many'),
    ('c12', 'section scan enters data', 'src/c12/stepr.bend',
     'case "DATA;": sr_sec_go(t, True{}, acc)', 'case "DATA;": sr_sec_go(t, False{}, acc)'),
    ('c12', 'mesh vertex header byte', 'src/c12/mesh.bend',
     'U32.is_eq(c0, 118)', 'U32.is_eq(c0, 119)'),
    ('c12', 'archive drops its envelope', 'src/c12/blob.bend',
     'case _ <> rest: rest', 'case _ <> rest: u'),
    ('c12', 'string builder un-reverses', 'src/c12/stepr.bend',
     'def sr_mkstr(xs: List<&2, Char>) -> String:\n  sr_mkstr_go(xs, "")',
     'def sr_mkstr(xs: List<&2, Char>) -> String:\n  sr_mkstr_go(List.reverse(&2, Char, xs), "")'),
    ('c12', 'brep stamp covers its gens', 'src/c12/blob.bend',
     'Ty.Br{vs, es, ces, lps, fas, shs, sos, top, br_stamp(vs, es, ces, lps, fas, shs, sos)}',
     'Ty.Br{vs, es, ces, lps, fas, shs, sos, top, 0u64}'),
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
