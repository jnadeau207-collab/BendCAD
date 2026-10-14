import Base
import ../c00/types.bend as T
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../base/par.bend as P
import ../c05/sqr.bend as Q
import ../c05/solve.bend as SL
import ../c06/model.bend as M
import ../c06/sx.bend as S
import ../c06/build.bend as BD
import ../c11/qdist.bend as QD
import ../c11/qinterf.bend as QI

type Inst is Data:
  Inst{ name: String, node: U64, tx: F64, ty: F64, tz: F64, q: U64 }

type Mate is Data:
  Mate{ id: U64, kind: U64, a: String, b: String, p: List<&2, F64> }

type Asm is Data:
  Asm{ insts: List<&2, Inst>, mates: List<&2, Mate> }

type AR is Data:
  AR_ok{ a: Asm }
  AR_err{ why: String, fix: String }

type AS is Data:
  AS_ok{ xs: List<&2, F64>, dof: Nat, red: List<&2, U64>, res: F64 }
  AS_conf{ ids: List<&2, U64>, res: F64 }

type ER is Data:
  ER_inst{ i: Inst }
  ER_mate{ m: Mate }
  ER_err{ why: String, fix: String }

type IR is Data:
  IR_ok{ l: List<&2, Inst> }
  IR_err{ why: String, fix: String }

type MR is Data:
  MR_ok{ l: List<&2, Mate> }
  MR_err{ why: String, fix: String }

type IN is Data:
  IN{ i: Inst, r: M.NR }

type RQ is Data:
  RQ{ q: U64, nm: String, d: List<&2, F64> }

def inst_name(i: Inst) -> String:
  Inst{+name, +node, +tx, +ty, +tz, +q} = i
  name

def inst_node(i: Inst) -> U64:
  Inst{+name, +node, +tx, +ty, +tz, +q} = i
  node

def inst_tx(i: Inst) -> F64:
  Inst{+name, +node, +tx, +ty, +tz, +q} = i
  tx

def inst_ty(i: Inst) -> F64:
  Inst{+name, +node, +tx, +ty, +tz, +q} = i
  ty

def inst_tz(i: Inst) -> F64:
  Inst{+name, +node, +tx, +ty, +tz, +q} = i
  tz

def inst_q(i: Inst) -> U64:
  Inst{+name, +node, +tx, +ty, +tz, +q} = i
  q

def mate_id(m: Mate) -> U64:
  Mate{+id, +kind, +a, +b, +p} = m
  id

def mate_kind(m: Mate) -> U64:
  Mate{+id, +kind, +a, +b, +p} = m
  kind

def mate_a(m: Mate) -> String:
  Mate{+id, +kind, +a, +b, +p} = m
  a

def mate_b(m: Mate) -> String:
  Mate{+id, +kind, +a, +b, +p} = m
  b

def mate_p(m: Mate) -> List<&2, F64>:
  Mate{+id, +kind, +a, +b, +p} = m
  p

def asm_insts(a: Asm) -> List<&2, Inst>:
  Asm{+insts, +mates} = a
  insts

def asm_mates(a: Asm) -> List<&2, Mate>:
  Asm{+insts, +mates} = a
  mates

def in_name(x: IN) -> String:
  IN{+i, +r} = x
  inst_name(i)

def in_nr(x: IN) -> M.NR:
  IN{+i, +r} = x
  r

def cat(xs: List<&2, String>) -> String:
  match xs:
    case []: ""
    case x <> t: x ++ " " ++ cat(t)

def sdrop(xs: List<&2, String>, +i: Nat) -> List<&2, String>:
  match xs:
    case []: []
    case x <> +t:
      match i:
        case 0n: x <> t
        case 1n+j: sdrop(t, j)

def fnum_m(m: Maybe<&2, F64>) -> F64:
  match m:
    case None{}: F64.nan()
    case Some{v}: v

def fnum(+x: S.Sx) -> F64:
  fnum_m(S.dec(S.sx_s(x)))

def sdec(+s: String) -> F64:
  fnum_m(S.dec(s))

def is_u64_m(m: Maybe<&2, U64>) -> Bool:
  match m:
    case None{}: False{}
    case Some{v}: True{}

def is_u64(+x: S.Sx) -> Bool:
  is_u64_m(U64.read(S.sx_s(x)))

def uval_m(m: Maybe<&2, U64>) -> U64:
  match m:
    case None{}: 0u64
    case Some{v}: v

def uval(+x: S.Sx) -> U64:
  uval_m(U64.read(S.sx_s(x)))

def p6(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64) -> List<&2, F64>:
  [a, b, c, d, e, f]

def p7(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64, +g: F64) -> List<&2, F64>:
  [a, b, c, d, e, f, g]

def p9(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64, +g: F64, +h: F64,
    +i: F64) -> List<&2, F64>:
  [a, b, c, d, e, f, g, h, i]

def fins(xs: List<&2, F64>) -> Bool:
  match xs:
    case []: True{}
    case x <> t: Bool.and(T.is_finite(x), fins(t))

def nzn(+x: F64, +y: F64, +z: F64) -> Bool:
  Bool.not(Bool.and(F64.is_eq(x, 0.0f64), Bool.and(F64.is_eq(y, 0.0f64), F64.is_eq(z, 0.0f64))))

def entry_kind(+h: String) -> U64:
  Bool.pick(U64, String.eq(h, "inst"), 1u64,
    Bool.pick(U64, Bool.or(String.eq(h, "fix"),
      Bool.or(String.eq(h, "coinc"), Bool.or(String.eq(h, "plane"), String.eq(h, "axis")))), 2u64, 0u64))

def inst_of(+x: S.Sx) -> ER:
  +xs = S.sx_xs(x)
  +nm = S.sx_s(S.sx_nth(xs, 1n))
  +nd = uval(S.sx_nth(xs, 2n))
  +tx = fnum(S.sx_nth(xs, 3n))
  +ty = fnum(S.sx_nth(xs, 4n))
  +tz = fnum(S.sx_nth(xs, 5n))
  +q = uval(S.sx_nth(xs, 6n))
  +ok = Bool.and(Nat.is_eq(List.length(&2, S.Sx, xs), 7n),
    Bool.and(Bool.not(String.eq(nm, "")), Bool.and(is_u64(S.sx_nth(xs, 2n)),
      Bool.and(T.is_finite(tx), Bool.and(T.is_finite(ty), Bool.and(T.is_finite(tz),
        Bool.and(is_u64(S.sx_nth(xs, 6n)), U64.is_lt(q, 6u64))))))))
  Bool.pick(ER, ok, ER_inst{Inst{nm, nd, tx, ty, tz, q}},
    ER_err{"bad-instance", "write (inst NAME NODE TX TY TZ Q) with finite numbers and a turn code 0-5"})

def mate_fix(+xs: List<&2, S.Sx>) -> ER:
  +b = S.sx_s(S.sx_nth(xs, 2n))
  +ok = Bool.and(Nat.is_eq(List.length(&2, S.Sx, xs), 3n),
    Bool.and(is_u64(S.sx_nth(xs, 1n)), Bool.not(String.eq(b, ""))))
  Bool.pick(ER, ok, ER_mate{Mate{uval(S.sx_nth(xs, 1n)), 1u64, "", b, []}},
    ER_err{"bad-mate", "write (fix ID INST)"})

def mate_coinc(+xs: List<&2, S.Sx>) -> ER:
  +a = S.sx_s(S.sx_nth(xs, 2n))
  +b = S.sx_s(S.sx_nth(xs, 6n))
  +p = p6(fnum(S.sx_nth(xs, 3n)), fnum(S.sx_nth(xs, 4n)), fnum(S.sx_nth(xs, 5n)),
    fnum(S.sx_nth(xs, 7n)), fnum(S.sx_nth(xs, 8n)), fnum(S.sx_nth(xs, 9n)))
  +ok = Bool.and(Nat.is_eq(List.length(&2, S.Sx, xs), 10n),
    Bool.and(is_u64(S.sx_nth(xs, 1n)), Bool.and(Bool.not(String.eq(a, "")),
      Bool.and(Bool.not(String.eq(b, "")), Bool.and(Bool.not(String.eq(a, b)), fins(p))))))
  Bool.pick(ER, ok, ER_mate{Mate{uval(S.sx_nth(xs, 1n)), 2u64, a, b, p}},
    ER_err{"bad-mate", "write (coinc ID A AX AY AZ B BX BY BZ) naming two different instances with finite numbers"})

def mate_plane(+xs: List<&2, S.Sx>) -> ER:
  +b = S.sx_s(S.sx_nth(xs, 2n))
  +p = p7(fnum(S.sx_nth(xs, 3n)), fnum(S.sx_nth(xs, 4n)), fnum(S.sx_nth(xs, 5n)),
    fnum(S.sx_nth(xs, 6n)), fnum(S.sx_nth(xs, 7n)), fnum(S.sx_nth(xs, 8n)), fnum(S.sx_nth(xs, 9n)))
  +ok = Bool.and(Nat.is_eq(List.length(&2, S.Sx, xs), 10n),
    Bool.and(is_u64(S.sx_nth(xs, 1n)), Bool.and(Bool.not(String.eq(b, "")),
      Bool.and(fins(p), nzn(M.f_nth(p, 3n), M.f_nth(p, 4n), M.f_nth(p, 5n))))))
  Bool.pick(ER, ok, ER_mate{Mate{uval(S.sx_nth(xs, 1n)), 3u64, "", b, p}},
    ER_err{"bad-mate", "write (plane ID INST BX BY BZ NX NY NZ D) with finite numbers and a nonzero normal"})

def mate_axis(+xs: List<&2, S.Sx>) -> ER:
  +b = S.sx_s(S.sx_nth(xs, 2n))
  +p = p9(fnum(S.sx_nth(xs, 3n)), fnum(S.sx_nth(xs, 4n)), fnum(S.sx_nth(xs, 5n)),
    fnum(S.sx_nth(xs, 6n)), fnum(S.sx_nth(xs, 7n)), fnum(S.sx_nth(xs, 8n)),
    fnum(S.sx_nth(xs, 9n)), fnum(S.sx_nth(xs, 10n)), fnum(S.sx_nth(xs, 11n)))
  +ok = Bool.and(Nat.is_eq(List.length(&2, S.Sx, xs), 12n),
    Bool.and(is_u64(S.sx_nth(xs, 1n)), Bool.and(Bool.not(String.eq(b, "")),
      Bool.and(fins(p), nzn(M.f_nth(p, 6n), M.f_nth(p, 7n), M.f_nth(p, 8n))))))
  Bool.pick(ER, ok, ER_mate{Mate{uval(S.sx_nth(xs, 1n)), 4u64, "", b, p}},
    ER_err{"bad-mate", "write (axis ID INST BX BY BZ PX PY PZ DX DY DZ) with finite numbers and a nonzero direction"})

def mate_of(+x: S.Sx) -> ER:
  +xs = S.sx_xs(x)
  +h = S.sx_s(S.sx_nth(xs, 0n))
  Bool.pick(ER, String.eq(h, "fix"), mate_fix(xs),
    Bool.pick(ER, String.eq(h, "coinc"), mate_coinc(xs),
      Bool.pick(ER, String.eq(h, "plane"), mate_plane(xs),
        Bool.pick(ER, String.eq(h, "axis"), mate_axis(xs),
          ER_err{"unknown-mate", "use fix, coinc, plane or axis"}))))

def inst_has(+il: List<&2, Inst>, +nm: String) -> Bool:
  match il:
    case []: False{}
    case i <> t: Bool.or(String.eq(inst_name(i), nm), inst_has(t, nm))

def inst_at(+il: List<&2, Inst>, +nm: String) -> Inst:
  match il:
    case []: Inst{"", 0u64, 0.0f64, 0.0f64, 0.0f64, 0u64}
    case +i <> t: Bool.pick(Inst, String.eq(inst_name(i), nm), i, inst_at(t, nm))

def inst_idx(+il: List<&2, Inst>, +nm: String, +k: Nat) -> Nat:
  match il:
    case []: k
    case i <> t: Bool.pick(Nat, String.eq(inst_name(i), nm), k, inst_idx(t, nm, Nat.add(k, 1n)))

def insts_wrap_dup(+d: Bool, +rec: IR) -> IR:
  match d:
    case True{}: IR_err{"duplicate-instance", "give every instance a different name"}
    case False{}: rec

def insts_wrap_inst(+r: ER, +rec: IR, +acc: List<&2, Inst>) -> IR:
  match r:
    case ER_inst{+i}: insts_wrap_dup(inst_has(acc, inst_name(i)), rec)
    case ER_mate{+m}: IR_err{"bad-instance", "write (inst NAME NODE TX TY TZ Q)"}
    case ER_err{+why, +fix}: IR_err{why, fix}

def insts_wrap(+k: U64, +r: ER, +rec: IR, +acc: List<&2, Inst>) -> IR:
  match k:
    case 1u64: insts_wrap_inst(r, rec, acc)
    case 2u64: rec
    case _: IR_err{"unknown-assembly-entry", "use (inst ...) or a mate (fix, coinc, plane, axis)"}

def insts_nacc_i(+r: ER, +acc: List<&2, Inst>) -> List<&2, Inst>:
  match r:
    case ER_inst{+i}: Bool.pick(List<&2, Inst>, inst_has(acc, inst_name(i)), acc, i <> acc)
    case _: acc

def insts_nacc(+k: U64, +r: ER, +acc: List<&2, Inst>) -> List<&2, Inst>:
  match k:
    case 1u64: insts_nacc_i(r, acc)
    case _: acc

def insts_go(xs: List<&2, S.Sx>, +acc: List<&2, Inst>) -> IR:
  match xs:
    case []: IR_ok{List.reverse(&2, Inst, acc)}
    case +x <> t:
      +k = entry_kind(S.sx_s(S.sx_nth(S.sx_xs(x), 0n)))
      +r = inst_of(x)
      insts_wrap(k, r, insts_go(t, insts_nacc(k, r, acc)), acc)

def mate_ref_ok(+m: Mate, +il: List<&2, Inst>) -> Bool:
  Bool.pick(Bool, U64.is_eq(mate_kind(m), 2u64),
    Bool.and(inst_has(il, mate_a(m)), inst_has(il, mate_b(m))), inst_has(il, mate_b(m)))

def mates_wrap_ref(+ok: Bool, +rec: MR) -> MR:
  match ok:
    case True{}: rec
    case False{}: MR_err{"unknown-instance", "name an instance from the assembly"}

def mates_wrap_mate(+r: ER, +rec: MR, +il: List<&2, Inst>) -> MR:
  match r:
    case ER_mate{+m}: mates_wrap_ref(mate_ref_ok(m, il), rec)
    case ER_inst{+i}: MR_err{"bad-mate", "use fix, coinc, plane or axis"}
    case ER_err{+why, +fix}: MR_err{why, fix}

def mates_wrap(+k: U64, +r: ER, +rec: MR, +il: List<&2, Inst>) -> MR:
  match k:
    case 1u64: rec
    case 2u64: mates_wrap_mate(r, rec, il)
    case _: MR_err{"unknown-assembly-entry", "use (inst ...) or a mate (fix, coinc, plane, axis)"}

def mates_nacc_m(+r: ER, +il: List<&2, Inst>, +acc: List<&2, Mate>) -> List<&2, Mate>:
  match r:
    case ER_mate{+m}: Bool.pick(List<&2, Mate>, mate_ref_ok(m, il), m <> acc, acc)
    case _: acc

def mates_nacc(+k: U64, +r: ER, +il: List<&2, Inst>, +acc: List<&2, Mate>) -> List<&2, Mate>:
  match k:
    case 2u64: mates_nacc_m(r, il, acc)
    case _: acc

def mates_go(xs: List<&2, S.Sx>, +il: List<&2, Inst>, +acc: List<&2, Mate>) -> MR:
  match xs:
    case []: MR_ok{List.reverse(&2, Mate, acc)}
    case +x <> t:
      +k = entry_kind(S.sx_s(S.sx_nth(S.sx_xs(x), 0n)))
      +r = mate_of(x)
      mates_wrap(k, r, mates_go(t, il, mates_nacc(k, r, il, acc)), il)

def asm_join_ml(+r: MR, +il: List<&2, Inst>) -> AR:
  match r:
    case MR_err{+why, +fix}: AR_err{why, fix}
    case MR_ok{+l}: AR_ok{Asm{il, l}}

def asm_join_e(+e: Bool, +r: MR, +il: List<&2, Inst>) -> AR:
  match e:
    case True{}: AR_err{"assembly-needs-instance", "add (inst NAME NODE TX TY TZ Q)"}
    case False{}: asm_join_ml(r, il)

def asm_join(+il: List<&2, Inst>, +r: MR) -> AR:
  asm_join_e(Nat.is_eq(List.length(&2, Inst, il), 0n), r, il)

def asm_ir(+r: IR, +xs: List<&2, S.Sx>) -> AR:
  match r:
    case IR_err{+why, +fix}: AR_err{why, fix}
    case IR_ok{+l}: asm_join(l, mates_go(xs, l, []))

def asm_head_go(+h: Bool, +x: S.Sx) -> AR:
  match h:
    case False{}: AR_err{"assembly-parse-failed", "write one (assembly ...) form"}
    case True{}:
      +xs = S.sx_drop(S.sx_xs(x), 1n)
      asm_ir(insts_go(xs, []), xs)

def asm_head(+x: S.Sx) -> AR:
  asm_head_go(S.head_is(x, "assembly"), x)

def asm_one(+xs: List<&2, S.Sx>) -> AR:
  Bool.pick(AR, Nat.is_eq(List.length(&2, S.Sx, xs), 1n), asm_head(S.sx_nth(xs, 0n)),
    AR_err{"assembly-parse-failed", "write one (assembly ...) form"})

def asm_ps(r: S.PS) -> AR:
  S.PS{+ok, +xs} = r
  match ok:
    case False{}: AR_err{"assembly-parse-failed", "write one (assembly ...) form"}
    case True{}: asm_one(xs)

def asm_parse(+s: String) -> AR:
  asm_ps(S.parse(s))

def col_of(+k: Nat, +i: Nat) -> U32:
  U32.from_nat(Nat.add(Nat.mul(k, 3n), i))

def node_off(+cs: List<&2, M.CE>, +nd: U64, +q: U64, +x: F64, +y: F64, +z: F64, +i: Nat) -> F64:
  +pl = M.bd_pl(M.nr_body(M.ce_r(M.ce_find(cs, nd))))
  +l = M.m3_ap(M.pl_m(pl), x, y, z)
  +wx = F64.add(M.f_nth(l, 0n), M.pl_tx(pl))
  +wy = F64.add(M.f_nth(l, 1n), M.pl_ty(pl))
  +wz = F64.add(M.f_nth(l, 2n), M.pl_tz(pl))
  M.f_nth(M.m3_ap(M.q_mat(q), wx, wy, wz), i)

def sv_put(+v: F64, +c: U32, +rest: List<&2, Q.Sv>) -> List<&2, Q.Sv>:
  Bool.pick(List<&2, Q.Sv>, F64.is_eq(v, 0.0f64), rest, Q.Sv{c, v} <> rest)

def rows_fix(+id: U64, +k: Nat, +i: Inst) -> List<&2, SL.Dr>:
  [SL.Dr{id, F64.neg(inst_tx(i)), [Q.Sv{col_of(k, 0n), 1.0f64}]},
    SL.Dr{id, F64.neg(inst_ty(i)), [Q.Sv{col_of(k, 1n), 1.0f64}]},
    SL.Dr{id, F64.neg(inst_tz(i)), [Q.Sv{col_of(k, 2n), 1.0f64}]}]

def coinc_xs(+ka: Nat, +kb: Nat, +i: Nat) -> List<&2, Q.Sv>:
  Bool.pick(List<&2, Q.Sv>, Nat.is_lt(ka, kb),
    [Q.Sv{col_of(ka, i), F64.neg(1.0f64)}, Q.Sv{col_of(kb, i), 1.0f64}],
    [Q.Sv{col_of(kb, i), 1.0f64}, Q.Sv{col_of(ka, i), F64.neg(1.0f64)}])

def coinc_c(+cs: List<&2, M.CE>, +ia: Inst, +ib: Inst, +p: List<&2, F64>, +i: Nat) -> F64:
  F64.sub(node_off(cs, inst_node(ia), inst_q(ia), M.f_nth(p, 0n), M.f_nth(p, 1n), M.f_nth(p, 2n), i),
    node_off(cs, inst_node(ib), inst_q(ib), M.f_nth(p, 3n), M.f_nth(p, 4n), M.f_nth(p, 5n), i))

def rows_coinc(+m: Mate, +il: List<&2, Inst>, +cs: List<&2, M.CE>) -> List<&2, SL.Dr>:
  +ka = inst_idx(il, mate_a(m), 0n)
  +kb = inst_idx(il, mate_b(m), 0n)
  +ia = inst_at(il, mate_a(m))
  +ib = inst_at(il, mate_b(m))
  +p = mate_p(m)
  +id = mate_id(m)
  [SL.Dr{id, F64.neg(coinc_c(cs, ia, ib, p, 0n)), coinc_xs(ka, kb, 0n)},
    SL.Dr{id, F64.neg(coinc_c(cs, ia, ib, p, 1n)), coinc_xs(ka, kb, 1n)},
    SL.Dr{id, F64.neg(coinc_c(cs, ia, ib, p, 2n)), coinc_xs(ka, kb, 2n)}]

def rows_plane(+m: Mate, +il: List<&2, Inst>, +cs: List<&2, M.CE>) -> List<&2, SL.Dr>:
  +kb = inst_idx(il, mate_b(m), 0n)
  +ib = inst_at(il, mate_b(m))
  +p = mate_p(m)
  +nx = M.f_nth(p, 3n)
  +ny = M.f_nth(p, 4n)
  +nz = M.f_nth(p, 5n)
  +ox = node_off(cs, inst_node(ib), inst_q(ib), M.f_nth(p, 0n), M.f_nth(p, 1n), M.f_nth(p, 2n), 0n)
  +oy = node_off(cs, inst_node(ib), inst_q(ib), M.f_nth(p, 0n), M.f_nth(p, 1n), M.f_nth(p, 2n), 1n)
  +oz = node_off(cs, inst_node(ib), inst_q(ib), M.f_nth(p, 0n), M.f_nth(p, 1n), M.f_nth(p, 2n), 2n)
  +c = F64.sub(M.f_nth(p, 6n), F64.add(F64.add(F64.mul(nx, ox), F64.mul(ny, oy)), F64.mul(nz, oz)))
  [SL.Dr{mate_id(m), F64.neg(c),
    sv_put(nx, col_of(kb, 0n), sv_put(ny, col_of(kb, 1n), sv_put(nz, col_of(kb, 2n), [])))}]

def ax_pick(+dx: F64, +dy: F64, +dz: F64) -> U64:
  +ax = F64.abs(dx)
  +ay = F64.abs(dy)
  +az = F64.abs(dz)
  +m1 = Bool.pick(U64, F64.is_lt(ay, ax), 1u64, 0u64)
  +am = Bool.pick(F64, U64.is_eq(m1, 1u64), ay, ax)
  Bool.pick(U64, F64.is_lt(az, am), 2u64, m1)

def ax_e1(+dx: F64, +dy: F64, +dz: F64, +m: U64) -> List<&2, F64>:
  match m:
    case 0u64: [0.0f64, dz, F64.neg(dy)]
    case 1u64: [F64.neg(dz), 0.0f64, dx]
    case _: [dy, F64.neg(dx), 0.0f64]

def vnorm3(+x: F64, +y: F64, +z: F64) -> F64:
  F64.sqrt(F64.add(F64.add(F64.mul(x, x), F64.mul(y, y)), F64.mul(z, z)))

def rows_axis(+m: Mate, +il: List<&2, Inst>, +cs: List<&2, M.CE>) -> List<&2, SL.Dr>:
  +kb = inst_idx(il, mate_b(m), 0n)
  +ib = inst_at(il, mate_b(m))
  +p = mate_p(m)
  +ox = node_off(cs, inst_node(ib), inst_q(ib), M.f_nth(p, 0n), M.f_nth(p, 1n), M.f_nth(p, 2n), 0n)
  +oy = node_off(cs, inst_node(ib), inst_q(ib), M.f_nth(p, 0n), M.f_nth(p, 1n), M.f_nth(p, 2n), 1n)
  +oz = node_off(cs, inst_node(ib), inst_q(ib), M.f_nth(p, 0n), M.f_nth(p, 1n), M.f_nth(p, 2n), 2n)
  +rx = F64.sub(M.f_nth(p, 3n), ox)
  +ry = F64.sub(M.f_nth(p, 4n), oy)
  +rz = F64.sub(M.f_nth(p, 5n), oz)
  +dx = M.f_nth(p, 6n)
  +dy = M.f_nth(p, 7n)
  +dz = M.f_nth(p, 8n)
  +u = ax_e1(dx, dy, dz, ax_pick(dx, dy, dz))
  +n1 = vnorm3(M.f_nth(u, 0n), M.f_nth(u, 1n), M.f_nth(u, 2n))
  +ax = F64.div(M.f_nth(u, 0n), n1)
  +ay = F64.div(M.f_nth(u, 1n), n1)
  +az = F64.div(M.f_nth(u, 2n), n1)
  +dn = vnorm3(dx, dy, dz)
  +bx = F64.div(F64.sub(F64.mul(dy, az), F64.mul(dz, ay)), dn)
  +by = F64.div(F64.sub(F64.mul(dz, ax), F64.mul(dx, az)), dn)
  +bz = F64.div(F64.sub(F64.mul(dx, ay), F64.mul(dy, ax)), dn)
  +id = mate_id(m)
  [SL.Dr{id, F64.neg(F64.add(F64.add(F64.mul(ax, rx), F64.mul(ay, ry)), F64.mul(az, rz))),
    sv_put(ax, col_of(kb, 0n), sv_put(ay, col_of(kb, 1n), sv_put(az, col_of(kb, 2n), [])))},
    SL.Dr{id, F64.neg(F64.add(F64.add(F64.mul(bx, rx), F64.mul(by, ry)), F64.mul(bz, rz))),
    sv_put(bx, col_of(kb, 0n), sv_put(by, col_of(kb, 1n), sv_put(bz, col_of(kb, 2n), [])))}]

def mate_rows_go(+k: U64, +m: Mate, +il: List<&2, Inst>, +cs: List<&2, M.CE>) -> List<&2, SL.Dr>:
  match k:
    case 1u64: rows_fix(mate_id(m), inst_idx(il, mate_b(m), 0n), inst_at(il, mate_b(m)))
    case 2u64: rows_coinc(m, il, cs)
    case 3u64: rows_plane(m, il, cs)
    case _: rows_axis(m, il, cs)

def mate_rows(+m: Mate, +il: List<&2, Inst>, +cs: List<&2, M.CE>) -> List<&2, SL.Dr>:
  mate_rows_go(mate_kind(m), m, il, cs)

def asm_rows(+ml: List<&2, Mate>, +il: List<&2, Inst>, +cs: List<&2, M.CE>) -> List<&2, SL.Dr>:
  match ml:
    case []: []
    case m <> t: List.append(&2, SL.Dr, mate_rows(m, il, cs), asm_rows(t, il, cs))

def decl_ts(+il: List<&2, Inst>) -> List<&2, F64>:
  match il:
    case []: []
    case +i <> t: inst_tx(i) <> inst_ty(i) <> inst_tz(i) <> decl_ts(t)

def ev_xs(xs: List<&2, Q.Sv>, +sol: List<&2, F64>) -> F64:
  match xs:
    case []: 0.0f64
    case +s <> t: F64.add(F64.mul(Q.sv_v(s), M.f_nth(sol, U32.to_nat(Q.sv_c(s)))), ev_xs(t, sol))

def row_res(+d: SL.Dr, +sol: List<&2, F64>) -> F64:
  F64.abs(F64.add(ev_xs(SL.dr_v(d), sol), SL.dr_r(d)))

def maxres_go(ds: List<&2, SL.Dr>, +sol: List<&2, F64>, +m: F64) -> F64:
  match ds:
    case []: m
    case d <> t: maxres_go(t, sol, F64.max(m, row_res(d, sol)))

def row_bad(+d: SL.Dr, +sol: List<&2, F64>) -> Bool:
  +e = ev_xs(SL.dr_v(d), sol)
  +rr = SL.dr_r(d)
  F64.is_lt(F64.mul(0.000000001f64, F64.add(1.0f64, F64.max(F64.abs(e), F64.abs(rr)))),
    F64.abs(F64.add(e, rr)))

def u_has(+xs: List<&2, U64>, +v: U64) -> Bool:
  match xs:
    case []: False{}
    case x <> t: Bool.or(U64.is_eq(x, v), u_has(t, v))

def u_add(+xs: List<&2, U64>, +v: U64) -> List<&2, U64>:
  Bool.pick(List<&2, U64>, u_has(xs, v), xs, v <> xs)

def viol_go(ds: List<&2, SL.Dr>, +sol: List<&2, F64>, +acc: List<&2, U64>) -> List<&2, U64>:
  match ds:
    case []: List.reverse(&2, U64, acc)
    case +d <> t: viol_go(t, sol, Bool.pick(List<&2, U64>, row_bad(d, sol), u_add(acc, SL.dr_id(d)), acc))

def redup(+js: List<&2, U32>, +it: P.Tb<&2, U64>, +acc: List<&2, U64>) -> List<&2, U64>:
  match js:
    case []: List.reverse(&2, U64, acc)
    case j <> t: redup(t, it, u_add(acc, P.tb_get(U64, it, j)))

def nd_t(x: Q.ND) -> Q.NT:
  Q.ND{+ord, +t} = x
  t

def nd_pm(x: Q.ND, +np: U32) -> P.Tb<&2, U32>:
  Q.ND{+ord, +t} = x
  Q.mp_set(ord, 0, P.tb_of(U32, P.rep_n(U32, U32.to_nat(np), 0), 0))

def asm_verdict(+dof: Nat, +red: List<&2, U64>, +sol: List<&2, F64>, +res: F64,
    +viol: List<&2, U64>) -> AS:
  match viol:
    case []: AS_ok{sol, dof, red, res}
    case _ <> _: AS_conf{viol, res}

def asm_rank(+n: Nat, +ds: List<&2, SL.Dr>) -> AS:
  +m = P.ulen(SL.Dr, ds)
  +nb = P.tb_of(F64, SL.dr_nrms(ds), 0.0f64)
  +srt = SL.so_tj(P.msort(~SL.Tj, ~SL.tj_cmp, SL.tj_all(ds, 0)))
  +cq = Q.rank(m, nb, SL.brows(srt))
  +red = redup(SL.cq_red(cq), P.tb_of(U64, SL.dr_ids(ds), 0u64), [])
  +np = U32.from_nat(n)
  +nd = Q.nd_order(np, SL.ds_es(ds))
  +pm = nd_pm(nd, np)
  +sol = SL.gather(n, 0, pm, SL.ptb(Q.lsq_nt(np, nd_t(nd), SL.lsq_rows(ds, pm))))
  +res = maxres_go(ds, sol, 0.0f64)
  asm_verdict(Nat.sub(n, SL.cq_kept(cq)), red, sol, res, viol_go(ds, sol, []))

def asm_solve(+a: Asm, +cs: List<&2, M.CE>) -> AS:
  +il = asm_insts(a)
  +ml = asm_mates(a)
  +n = Nat.mul(List.length(&2, Inst, il), 3n)
  +ds = asm_rows(ml, il, cs)
  Bool.pick(AS, Nat.is_eq(List.length(&2, SL.Dr, ds), 0n), AS_ok{decl_ts(il), n, [], 0.0f64},
    asm_rank(n, ds))

def ids_tail(xs: List<&2, U64>) -> String:
  match xs:
    case []: ""
    case h <> t: "," ++ U64.show(h) ++ ids_tail(t)

def ids_show(xs: List<&2, U64>) -> String:
  match xs:
    case []: "[]"
    case h <> t: "[" ++ U64.show(h) ++ ids_tail(t) ++ "]"

def mate_ids(+ml: List<&2, Mate>) -> List<&2, U64>:
  match ml:
    case []: []
    case m <> t: mate_id(m) <> mate_ids(t)

def lin_go(+il: List<&2, Inst>, +first: Bool) -> String:
  match il:
    case []: ""
    case +i <> t: Bool.pick(String, first, "", ",") ++ inst_name(i) ++ "=n" ++
      U64.show(inst_node(i)) ++ lin_go(t, False{})

def lineage(+il: List<&2, Inst>, +ml: List<&2, Mate>) -> String:
  "lineage asm(" ++ lin_go(il, True{}) ++ ") mates" ++ ids_show(mate_ids(ml)) ++ "\n"

def inst_line(+i: Inst, +x: F64, +y: F64, +z: F64) -> String:
  "inst " ++ inst_name(i) ++ " node " ++ U64.show(inst_node(i)) ++ " t=" ++ S.f_show(x) ++
    " " ++ S.f_show(y) ++ " " ++ S.f_show(z) ++ " q=" ++ U64.show(inst_q(i)) ++ "\n"

def insts_rep(+il: List<&2, Inst>, +xs: List<&2, F64>, +k: Nat) -> String:
  match il:
    case []: ""
    case i <> t:
      +bx = Nat.mul(k, 3n)
      inst_line(i, M.f_nth(xs, bx), M.f_nth(xs, Nat.add(bx, 1n)), M.f_nth(xs, Nat.add(bx, 2n))) ++
        insts_rep(t, xs, Nat.add(k, 1n))

def solve_rep(+a: Asm, +xs: List<&2, F64>, +dof: Nat, +red: List<&2, U64>, +res: F64) -> String:
  +il = asm_insts(a)
  +ml = asm_mates(a)
  "asm " ++ Bool.pick(String, Nat.is_eq(dof, 0n), "solved", "underconstrained") ++
    " ninst " ++ Nat.show(List.length(&2, Inst, il)) ++ " nmates " ++
    Nat.show(List.length(&2, Mate, ml)) ++ " dof " ++ Nat.show(dof) ++ " max-residual " ++
    S.f_show(res) ++ "\n" ++ insts_rep(il, xs, 0n) ++ "redundant " ++ ids_show(red) ++ "\n" ++
    lineage(il, ml)

def conf_rep(+a: Asm, +ids: List<&2, U64>, +res: F64) -> String:
  +il = asm_insts(a)
  +ml = asm_mates(a)
  "asm conflict ninst " ++ Nat.show(List.length(&2, Inst, il)) ++ " nmates " ++
    Nat.show(List.length(&2, Mate, ml)) ++ " viol " ++ ids_show(ids) ++ " max-residual " ++
    S.f_show(res) ++ " | fix: loosen or correct the violating mates"

def placed_nr(+r: M.NR, +q: U64, +x: F64, +y: F64, +z: F64) -> M.NR:
  match r:
    case M.NR_err{+k, +d}: M.NR_err{k, d}
    case M.NR_ok{+b, +fx}: M.NR_ok{M.Bd{M.bd_cells(b), M.bd_brep(b), M.bd_fns(b),
      M.pl_move(M.bd_pl(b), q, x, y, z), M.bd_rv(b), M.bd_xb(b)}, fx}

def inst_nr(+cs: List<&2, M.CE>, +i: Inst, +x: F64, +y: F64, +z: F64) -> M.NR:
  placed_nr(M.ce_r(M.ce_find(cs, inst_node(i))), inst_q(i), x, y, z)

def place_all(+il: List<&2, Inst>, +xs: List<&2, F64>, +cs: List<&2, M.CE>, +k: Nat) -> List<&2, IN>:
  match il:
    case []: []
    case +i <> t:
      +bx = Nat.mul(k, 3n)
      IN{i, inst_nr(cs, i, M.f_nth(xs, bx), M.f_nth(xs, Nat.add(bx, 1n)),
        M.f_nth(xs, Nat.add(bx, 2n)))} <> place_all(t, xs, cs, Nat.add(k, 1n))

def pairs_inner(+x: IN, +ys: List<&2, IN>, +cl: Bool) -> String:
  match ys:
    case []: ""
    case +y <> t: "pair " ++ in_name(x) ++ " " ++ in_name(y) ++ "\n" ++
      Bool.pick(String, cl, QD.clear_s(in_nr(x), in_nr(y)), QI.rel_s(in_nr(x), in_nr(y))) ++
      "\n" ++ pairs_inner(x, t, cl)

def pairs_go(+xs: List<&2, IN>, +cl: Bool) -> String:
  match xs:
    case []: ""
    case x <> t: pairs_inner(x, t, cl) ++ pairs_go(t, cl)

def pairs_rep(+a: Asm, +xs: List<&2, F64>, +cs: List<&2, M.CE>, +cl: Bool) -> String:
  +il = asm_insts(a)
  +ml = asm_mates(a)
  "assembly pairs ninst " ++ Nat.show(List.length(&2, Inst, il)) ++ "\n" ++
    pairs_go(place_all(il, xs, cs, 0n), cl)

def explode_go(+il: List<&2, Inst>, +xs: List<&2, F64>, +k: Nat, +o: F64, +dx: F64, +dy: F64,
    +dz: F64, +gap: F64) -> String:
  match il:
    case []: ""
    case i <> t:
      +bx = Nat.mul(k, 3n)
      inst_line(i, F64.add(M.f_nth(xs, bx), F64.mul(o, dx)),
        F64.add(M.f_nth(xs, Nat.add(bx, 1n)), F64.mul(o, dy)),
        F64.add(M.f_nth(xs, Nat.add(bx, 2n)), F64.mul(o, dz))) ++
        explode_go(t, xs, Nat.add(k, 1n), F64.add(o, gap), dx, dy, dz, gap)

def explode_rep(+a: Asm, +xs: List<&2, F64>, +d: List<&2, F64>) -> String:
  +il = asm_insts(a)
  +ml = asm_mates(a)
  "asm exploded ninst " ++ Nat.show(List.length(&2, Inst, il)) ++ " dir=" ++
    S.f_show(M.f_nth(d, 0n)) ++ " " ++ S.f_show(M.f_nth(d, 1n)) ++ " " ++
    S.f_show(M.f_nth(d, 2n)) ++ " gap=" ++ S.f_show(M.f_nth(d, 3n)) ++ "\n" ++
    explode_go(il, xs, 0n, 0.0f64, M.f_nth(d, 0n), M.f_nth(d, 1n), M.f_nth(d, 2n), M.f_nth(d, 3n))

def afn_s(+f: BD.Fn, +pre: String) -> String:
  BD.Fn{+nd, +k, +role, +i, +j} = f
  pre ++ Bool.pick(String, U64.is_eq(role, 4u64),
    "n" ++ U64.show(nd) ++ ".cav." ++ Nat.show(k) ++ "." ++ Nat.show(i) ++ "." ++ Nat.show(j),
    "n" ++ U64.show(nd) ++ ".c" ++ Nat.show(k) ++ Bool.pick(String, U64.is_eq(role, 0u64), ".top",
      Bool.pick(String, U64.is_eq(role, 1u64), ".bottom", ".wall." ++ Nat.show(i) ++ "." ++ Nat.show(j))))

def asurf_s(s: G.GVal) -> String:
  match s:
    case G.GV_pl{w}: "plane"
    case G.GV_cy{w}: "cylinder"
    case G.GV_bp{w}: "planar-patch"
    case G.GV_sp{w}: "sphere"
    case G.GV_co{w}: "cone"
    case G.GV_to{w}: "torus"
    case _: "other"

def afaces_go(fs: List<&2, BD.Fn>, fas: List<&2, Ty.Face>, +pre: String) -> String:
  match fs:
    case []: ""
    case f <> t:
      match fas:
        case []: ""
        case a <> u:
          Ty.Fa{g, s, ls, same} = a
          afn_s(f, pre) ++ " " ++ asurf_s(s) ++ " loops=" ++
            Nat.show(List.length(&2, Ty.HLoop, ls)) ++ "\n" ++ afaces_go(t, u, pre)

def faces_has(+h: Bool, +a: Asm, +xs: List<&2, F64>, +cs: List<&2, M.CE>, +nm: String) -> String:
  match h:
    case False{}: "error invalid-input | asm faces | why: unknown-instance " ++ nm ++
      " | fix: name an instance from the assembly"
    case True{}:
      +il = asm_insts(a)
      +ml = asm_mates(a)
      +i = inst_at(il, nm)
      +bx = Nat.mul(inst_idx(il, nm, 0n), 3n)
      +b = M.nr_body(inst_nr(cs, i, M.f_nth(xs, bx), M.f_nth(xs, Nat.add(bx, 1n)),
        M.f_nth(xs, Nat.add(bx, 2n))))
      afaces_go(M.bd_fns(b), Ty.brep_fas(M.bd_brep(b)), nm ++ ".")

def faces_rep(+a: Asm, +xs: List<&2, F64>, +cs: List<&2, M.CE>, +nm: String) -> String:
  +il = asm_insts(a)
  +ml = asm_mates(a)
  faces_has(inst_has(il, nm), a, xs, cs, nm)

def ok_out(+a: Asm, +xs: List<&2, F64>, +dof: Nat, +red: List<&2, U64>, +res: F64,
    +cs: List<&2, M.CE>, +rq: RQ) -> String:
  RQ{+q, +nm, +d} = rq
  match q:
    case 1u64: solve_rep(a, xs, dof, red, res)
    case 2u64: pairs_rep(a, xs, cs, False{})
    case 3u64: pairs_rep(a, xs, cs, True{})
    case 4u64: explode_rep(a, xs, d)
    case _: faces_rep(a, xs, cs, nm)

def asm_out(+a: Asm, +s: AS, +cs: List<&2, M.CE>, +rq: RQ) -> String:
  match s:
    case AS_conf{+ids, +res}: conf_rep(a, ids, res)
    case AS_ok{+xs, +dof, +red, +res}: ok_out(a, xs, dof, red, res, cs, rq)

def nodes_ce(+h: Bool, +ok: Bool, +i: Inst, +rec: String) -> String:
  match h:
    case False{}: "error invalid-input | asm | why: unknown-node " ++ inst_name(i) ++
      " | fix: name a node from the design (eval)"
    case True{}: Bool.pick(String, ok, rec, "error: node " ++ U64.show(inst_node(i)) ++
      "; nothing assembled")

def nodes_err(+il: List<&2, Inst>, +ml: List<&2, Mate>, +cs: List<&2, M.CE>) -> String:
  match il:
    case []: ""
    case +i <> t: nodes_ce(M.ce_has(cs, inst_node(i)),
      M.nr_ok(M.ce_r(M.ce_find(cs, inst_node(i)))), i, nodes_err(t, ml, cs))

def asm_q_go(+p: M.Part, +ar: AR, +rq: RQ) -> String:
  match ar:
    case AR_err{+why, +fix}: "error invalid-input | asm | why: " ++ why ++ " | fix: " ++ fix
    case AR_ok{+a}:
      +cs = M.ev_part(p, [])
      +e = nodes_err(asm_insts(a), asm_mates(a), cs)
      Bool.pick(String, String.eq(e, ""), asm_out(a, asm_solve(a, cs), cs, rq), e)

def ex_ok(+dx: F64, +dy: F64, +dz: F64, +gap: F64) -> Bool:
  Bool.and(T.is_finite(dx), Bool.and(T.is_finite(dy), Bool.and(T.is_finite(dz),
    Bool.and(T.is_finite(gap), nzn(dx, dy, dz)))))

def asm_explode_go(+ok: Bool, +p: M.Part, +xs: List<&2, String>, +dx: F64, +dy: F64,
    +dz: F64, +gap: F64) -> String:
  match ok:
    case False{}: "error invalid-input | asm explode | why: need DX DY DZ GAP finite with a nonzero direction | fix: asm explode DX DY DZ GAP (assembly ...)"
    case True{}: asm_q_go(p, asm_parse(cat(sdrop(xs, 5n))), RQ{4u64, "", [dx, dy, dz, gap]})

def asm_explode_v(+p: M.Part, +xs: List<&2, String>) -> String:
  +dx = sdec(S.arg_at(xs, 1n))
  +dy = sdec(S.arg_at(xs, 2n))
  +dz = sdec(S.arg_at(xs, 3n))
  +gap = sdec(S.arg_at(xs, 4n))
  asm_explode_go(ex_ok(dx, dy, dz, gap), p, xs, dx, dy, dz, gap)

def asm_faces_go(+e: Bool, +p: M.Part, +xs: List<&2, String>, +nm: String) -> String:
  match e:
    case True{}: "error invalid-input | asm faces | why: need an instance name | fix: asm faces INST (assembly ...)"
    case False{}: asm_q_go(p, asm_parse(cat(sdrop(xs, 2n))), RQ{5u64, nm, []})

def asm_faces_v(+p: M.Part, +xs: List<&2, String>) -> String:
  +nm = S.arg_at(xs, 1n)
  asm_faces_go(String.eq(nm, ""), p, xs, nm)

def verb_code(+v: String) -> U64:
  Bool.pick(U64, String.eq(v, "solve"), 1u64, Bool.pick(U64, String.eq(v, "interf"), 2u64,
    Bool.pick(U64, String.eq(v, "clear"), 3u64, Bool.pick(U64, String.eq(v, "explode"), 4u64,
      Bool.pick(U64, String.eq(v, "faces"), 5u64, 0u64)))))

def asm_verb(+code: U64, +p: M.Part, +xs: List<&2, String>) -> String:
  match code:
    case 1u64: asm_q_go(p, asm_parse(cat(sdrop(xs, 1n))), RQ{1u64, "", []})
    case 2u64: asm_q_go(p, asm_parse(cat(sdrop(xs, 1n))), RQ{2u64, "", []})
    case 3u64: asm_q_go(p, asm_parse(cat(sdrop(xs, 1n))), RQ{3u64, "", []})
    case 4u64: asm_explode_v(p, xs)
    case 5u64: asm_faces_v(p, xs)
    case _: "error invalid-input | asm | why: unknown verb | fix: asm solve|interf|clear|explode|faces ..."

def asm_go(+p: M.Part, +xs: List<&2, String>) -> String:
  asm_verb(verb_code(S.arg_at(xs, 0n)), p, xs)
