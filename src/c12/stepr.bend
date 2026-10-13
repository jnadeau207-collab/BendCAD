import Base
import ../base/num.bend as N
import ../base/par.bend as B
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c04/ops.bend as B4
import ./blob.bend as BL

type SA is Data:
  SA_num{ s: String }
  SA_str{ s: String }
  SA_en{ s: String }
  SA_ref{ id: U64 }
  SA_ls{ xs: List<&2, SA> }
  SA_mt{}

type SPt is Data:
  SPt{ nm: String, args: List<&2, SA> }

type SE is Data:
  SE{ id: U64, ps: List<&2, SPt> }

type KR is Data:
  KR{ id: U64, kind: U64, rank: Nat }

type KC is Data:
  KC{ nv: Nat, ne: Nat, nce: Nat, nlp: Nat, nf: Nat, nsh: Nat, nso: Nat }

type ST is Data:
  ST{ ents: B.Tb<&2, SE>, krs: B.Tb<&2, KR>, n: Nat }

type SF is Data:
  SF{ ok: Bool, pos: Nat }

type SR_N is Data:
  SR_N{ ok: Bool, v: F64 }

type SR_P is Data:
  SR_P{ ok: Bool, p: V.Point }

type SR_D is Data:
  SR_D{ ok: Bool, d: V.Dir }

type SR_B is Data:
  SR_B{ ok: Bool, b: Bool }

type SR_I is Data:
  SR_I{ ok: Bool, i: Nat }

type SR_RL is Data:
  SR_RL{ ok: Bool, xs: List<&2, Nat> }

type SR_C is Data:
  SR_C{ ok: Bool, g: G.GVal, lo: F64, hi: F64 }

type SR_S is Data:
  SR_S{ ok: Bool, g: G.GVal }

type CE_F is Data:
  CE_F{ ce: Nat, fa: Nat, flip: Bool }

type BD_F is Data:
  BD_F{ bd: Nat, first: Bool, flip: Bool }

type VL_F is Data:
  VL_F{ bd: Nat, vp: Nat, first: Bool }

type SR_VL is Data:
  SR_VL{ ok: Bool, vls: List<&2, VL_F>, bad: U64 }

type SR_ID is Data:
  SR_ID{ ok: Bool, id: U64, rest: String }

type SR_NM is Data:
  SR_NM{ nm: String, rest: String }

type SR_IN is Data:
  SR_IN{ ok: Bool, inner: String, rest: String }

type SR_A is Data:
  SR_A{ ok: Bool, a: SA }

type SR_PS is Data:
  SR_PS{ ok: Bool, ps: List<&2, SPt>, rest: String }

type SR_E is Data:
  SR_E{ ok: Bool, id: U64, ps: List<&2, SPt> }

type SR_LS is Data:
  LS{ cur: List<&2, Char>, acc: List<&2, String> }

type SR_JS is Data:
  JS{ cur: String, started: Bool, acc: List<&2, String> }

type SR_IDS is Data:
  IDS{ acc: U64, done: Bool, fail: Bool, rest: String, sp: Bool }

type SR_SN is Data:
  SN{ idx: Nat, found: Bool, at: Nat }

type SR_SK is Data:
  SK{ idx: Nat, found: Bool, at: Nat }

type SR_NX is Data:
  NX{ idx: Nat, found: Bool, at: Nat }

type SR_IX is Data:
  IX{ idx: Nat, depth: Nat, instr: Bool, found: Bool, at: Nat }

type SR_T is Data:
  TT_lp{}
  TT_rp{}
  TT_co{}
  TT_ref{ id: U64 }
  TT_str{ s: String }
  TT_en{ s: String }
  TT_num{ s: String }
  TT_mt{}
  TT_bad{}

type SR_AS is Data:
  SR_AS{ ok: Bool, xs: List<&2, SA> }

type SR_TS is Data:
  TS{ mode: U64, cur: List<&2, Char>, out: List<&2, SR_T>, acc: U64, nd: Nat }

type SR_PL is Data:
  PL{ s: String, acc: List<&2, SPt>, ok: Bool, done: Bool }

type SR_EN is Data:
  SR_EN{ ok: Bool, xs: List<&2, SE> }

type SR_FX is Data:
  FX{ lo: Nat, hi: Nat, found: Bool, pos: Nat }

type SR_PX is Data:
  SR_PX{ ok: Bool, xs: List<&2, SA> }

type SR_AX is Data:
  SR_AX{ ok: Bool, o: V.Point, w: V.Dir, u: V.Dir }

type SR_PF is Data:
  PF{ found: Bool, xs: List<&2, SA> }

type SR_LN is Data:
  LN{ ok: Bool, o: V.Point, d: V.Dir }

type SR_CC is Data:
  CC{ ok: Bool, c: V.Point, u: V.Dir, v: V.Dir, r: F64 }

type SR_TM is Data:
  TM{ ok: Bool, basis: U64, sense: Bool }

type SR_CST is Data:
  CST{ id: U64, done: Bool, res: SR_C, esense: Bool }

type SR_UL is Data:
  UL{ ok: Bool, xs: List<&2, U64> }

type SR_NL is Data:
  NL{ ok: Bool, xs: List<&2, F64> }

type SR_UU is Data:
  UU{ ok: Bool, v: U64 }

type SR_FR is Data:
  FR{ ok: Bool, o: V.Point, u: V.Dir, v: V.Dir }

type SR_CEL is Data:
  SR_CEL{ ok: Bool, xs: List<&2, CE_F> }

type SR_BDL is Data:
  SR_BDL{ ok: Bool, xs: List<&2, BD_F> }

type SR_NAT is Data:
  SR_NAT{ ok: Bool, xs: List<&2, Nat> }

type SR_VW is Data:
  VW{ rows: List<&2, String>, pts: List<&2, V.Point>, ok: Bool, bad: U64 }

type SR_ER is Data:
  SR_ER{ ok: Bool, row: String, e0: Nat, e1: Nat, why: U64 }

type SR_EW is Data:
  EW{ rows: List<&2, String>, e0s: List<&2, Nat>, e1s: List<&2, Nat>, ok: Bool, bad: U64,
    why: U64 }

type SR_FC is Data:
  SR_FC{ ok: Bool, row: String, g: G.GVal, ces: List<&2, CE_F>, bds: List<&2, BD_F>, why: U64 }

type SR_BP is Data:
  SR_BP{ ok: Bool, ces: List<&2, CE_F>, bds: List<&2, BD_F>, why: U64 }

type SR_FW is Data:
  FW{ rows: List<&2, String>, surfs: List<&2, G.GVal>, ces: List<&2, CE_F>, bds: List<&2, BD_F>,
    ok: Bool, bad: U64, why: U64, nfa: Nat }

type SR_LW is Data:
  LW{ rows: List<&2, String>, ok: Bool, bad: U64, why: U64 }

type SR_LS2 is Data:
  LS2{ bds: List<&2, BD_F>, nlp: Nat, rows: List<&2, String>, ok: Bool, bad: U64, why: U64,
    vls: List<&2, VL_F> }

type SR_CW is Data:
  CW{ rows: List<&2, String>, ok: Bool, bad: U64, why: U64 }

type SR_CS2 is Data:
  CS2{ ces: List<&2, CE_F>, nce: Nat, rows: List<&2, String>, ok: Bool, bad: U64, why: U64 }

type SR_SW is Data:
  SW{ rows: List<&2, String>, ok: Bool, bad: U64 }

type SR_OR is Data:
  SR_OR{ ok: Bool, row: String, sh: Nat }

type SR_OW is Data:
  OW{ rows: List<&2, String>, used: List<&2, Nat>, ok: Bool, bad: U64 }

def sr_is_sp(+c: U32) -> Bool:
  Bool.or(Bool.or(U32.is_eq(c, 32), U32.is_eq(c, 9)), Bool.or(U32.is_eq(c, 10), U32.is_eq(c, 13)))

def sr_is_nm(+c: U32) -> Bool:
  Bool.or(Bool.or(Bool.and(U32.is_le(65, c), U32.is_le(c, 90)), N.is_dg(c)), U32.is_eq(c, 95))

def sr_mkstr_go(xs: List<&2, Char>, +acc: String) -> String:
  match xs:
    case []: acc
    case c <> t: sr_mkstr_go(t, SCon{c, acc})

def sr_mkstr(xs: List<&2, Char>) -> String:
  sr_mkstr_go(xs, "")

def sr_chars_go(s: String, +acc: List<&2, Char>) -> List<&2, Char>:
  match s:
    case SNil{}: List.reverse(&2, Char, acc)
    case SCon{h, t}: sr_chars_go(t, h <> acc)

def sr_chars(s: String) -> List<&2, Char>:
  sr_chars_go(s, [])

def sr_lines_nx3(+cr: Bool, h: Char, +cur: List<&2, Char>, +acc: List<&2, String>) -> SR_LS:
  match cr:
    case True{}: LS{cur, acc}
    case False{}: LS{h <> cur, acc}

def sr_lines_nx2(+nl: Bool, +cr: Bool, h: Char, +cur: List<&2, Char>,
    +acc: List<&2, String>) -> SR_LS:
  match nl:
    case True{}: LS{[], sr_mkstr(cur) <> acc}
    case False{}: sr_lines_nx3(cr, h, cur, acc)

def sr_lines_nx(+c: U32, h: Char, +st: SR_LS) -> SR_LS:
  match st:
    case LS{+cur, +acc}: sr_lines_nx2(U32.is_eq(c, 10), U32.is_eq(c, 13), h, cur, acc)

def sr_lines_end(+st: SR_LS) -> List<&2, String>:
  match st:
    case LS{+cur, +acc}: List.reverse(&2, String, sr_mkstr(cur) <> acc)

def sr_lines_go(s: String, +st: SR_LS) -> List<&2, String>:
  match s:
    case SNil{}: sr_lines_end(st)
    case SCon{+h, t}: sr_lines_go(t, sr_lines_nx(N.chr_code(h), h, st))

def sr_lines(s: String) -> List<&2, String>:
  sr_lines_go(s, LS{[], []})

def sr_is_hash(s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{h, t}: U32.is_eq(N.chr_code(h), 35)

def sr_join_app2(+started: Bool, +cur: String, +l: String, +acc: List<&2, String>) -> SR_JS:
  match started:
    case True{}: JS{cur ++ l, True{}, acc}
    case False{}: JS{"", False{}, acc}

def sr_join_push2(+started: Bool, +l: String, +cur: String, +acc: List<&2, String>) -> SR_JS:
  match started:
    case True{}: JS{l, True{}, cur <> acc}
    case False{}: JS{l, True{}, acc}

def sr_join_nx2(+hash: Bool, +l: String, +cur: String, +started: Bool,
    +acc: List<&2, String>) -> SR_JS:
  match hash:
    case True{}: sr_join_push2(started, l, cur, acc)
    case False{}: sr_join_app2(started, cur, l, acc)

def sr_join_nx(+l: String, +st: SR_JS) -> SR_JS:
  match st:
    case JS{+cur, +started, +acc}: sr_join_nx2(sr_is_hash(l), l, cur, started, acc)

def sr_join_fin2(+started: Bool, +cur: String, +acc: List<&2, String>) -> List<&2, String>:
  match started:
    case True{}: List.reverse(&2, String, cur <> acc)
    case False{}: List.reverse(&2, String, acc)

def sr_join_end(+st: SR_JS) -> List<&2, String>:
  match st:
    case JS{+cur, +started, +acc}: sr_join_fin2(started, cur, acc)

def sr_join_go(ls: List<&2, String>, +st: SR_JS) -> List<&2, String>:
  match ls:
    case []: sr_join_end(st)
    case l <> t: sr_join_go(t, sr_join_nx(l, st))

def sr_join(ls: List<&2, String>) -> List<&2, String>:
  sr_join_go(ls, JS{"", False{}, []})

def sr_parse_id_m5(+spc: Bool, +c: U32, +acc: U64, +sp: Bool) -> SR_IDS:
  match spc:
    case True{}: IDS{acc, False{}, False{}, "", True{}}
    case False{}: IDS{acc, False{}, True{}, "", sp}

def sr_parse_id_m4d(+sp: Bool, +c: U32, +acc: U64) -> SR_IDS:
  match sp:
    case True{}: IDS{acc, False{}, True{}, "", True{}}
    case False{}: IDS{U64.add(U64.mul(acc, 10u64), N.dg_v(c)), False{}, False{}, "", False{}}

def sr_parse_id_m4(+dg: Bool, +c: U32, +acc: U64, +sp: Bool) -> SR_IDS:
  match dg:
    case True{}: sr_parse_id_m4d(sp, c, acc)
    case False{}: sr_parse_id_m5(sr_is_sp(c), c, acc, sp)

def sr_parse_id_m3(+eq: Bool, +dg: Bool, +c: U32, t: String, +acc: U64, +sp: Bool) -> SR_IDS:
  match eq:
    case True{}: IDS{acc, True{}, False{}, t, sp}
    case False{}: sr_parse_id_m4(dg, c, acc, sp)

def sr_parse_id_m2(+fail: Bool, +c: U32, t: String, +acc: U64, +rest: String, +sp: Bool) -> SR_IDS:
  match fail:
    case True{}: IDS{acc, False{}, True{}, rest, sp}
    case False{}: sr_parse_id_m3(U32.is_eq(c, 61), N.is_dg(c), c, t, acc, sp)

def sr_parse_id_m(+done: Bool, +fail: Bool, +c: U32, t: String, +acc: U64, +rest: String,
    +sp: Bool) -> SR_IDS:
  match done:
    case True{}: IDS{acc, True{}, fail, rest, sp}
    case False{}: sr_parse_id_m2(fail, c, t, acc, rest, sp)

def sr_parse_id_nx(+c: U32, t: String, +st: SR_IDS) -> SR_IDS:
  match st:
    case IDS{+acc, +done, +fail, +rest, +sp}: sr_parse_id_m(done, fail, c, t, acc, rest, sp)

def sr_parse_id_fin(+done: Bool, +fail: Bool, +acc: U64, +rest: String) -> SR_ID:
  match done:
    case True{}: SR_ID{Bool.not(fail), acc, rest}
    case False{}: SR_ID{False{}, 0u64, ""}

def sr_parse_id_end(+st: SR_IDS) -> SR_ID:
  match st:
    case IDS{+acc, +done, +fail, +rest, +sp}: sr_parse_id_fin(done, fail, acc, rest)

def sr_parse_id_go(s: String, +st: SR_IDS) -> SR_ID:
  match s:
    case SNil{}: sr_parse_id_end(st)
    case SCon{+h, +t}: sr_parse_id_go(t, sr_parse_id_nx(N.chr_code(h), t, st))

def sr_parse_id(s: String, +acc: U64) -> SR_ID:
  sr_parse_id_go(s, IDS{acc, False{}, False{}, "", False{}})

def sr_snip_m2(+semi: Bool, +idx: Nat, +at: Nat) -> SR_SN:
  match semi:
    case True{}: SN{Nat.add(idx, 1n), True{}, idx}
    case False{}: SN{Nat.add(idx, 1n), False{}, Nat.add(idx, 1n)}

def sr_snip_m(+found: Bool, +semi: Bool, +idx: Nat, +at: Nat) -> SR_SN:
  match found:
    case True{}: SN{Nat.add(idx, 1n), True{}, at}
    case False{}: sr_snip_m2(semi, idx, at)

def sr_snip_nx(+c: U32, +st: SR_SN) -> SR_SN:
  match st:
    case SN{+idx, +found, +at}: sr_snip_m(found, U32.is_eq(c, 59), idx, at)

def sr_snip_go(xs: List<&2, Char>, +st: SR_SN) -> SR_SN:
  match xs:
    case []: st
    case c <> t: sr_snip_go(t, sr_snip_nx(N.chr_code(c), st))

def sr_sn_at(+r: SR_SN) -> Nat:
  SN{idx, found, at} = r
  at

def sr_ldrop(xs: List<&2, Char>, +n: Nat) -> List<&2, Char>:
  match xs:
    case []: []
    case h <> t:
      match n:
        case 0n: h <> t
        case 1n+j: sr_ldrop(t, j)

def sr_body_of(+s: String) -> String:
  +cs = List.reverse(&2, Char, sr_chars(s))
  +st = sr_snip_go(cs, SN{0n, False{}, 0n})
  sr_mkstr(sr_ldrop(cs, Nat.add(sr_sn_at(st), 1n)))

def sr_skip_m2(+sp: Bool, +idx: Nat, +at: Nat) -> SR_SK:
  match sp:
    case True{}: SK{Nat.add(idx, 1n), False{}, Nat.add(idx, 1n)}
    case False{}: SK{Nat.add(idx, 1n), True{}, idx}

def sr_skip_m(+found: Bool, +sp: Bool, +idx: Nat, +at: Nat) -> SR_SK:
  match found:
    case True{}: SK{Nat.add(idx, 1n), True{}, at}
    case False{}: sr_skip_m2(sp, idx, at)

def sr_skip_nx(+c: U32, +st: SR_SK) -> SR_SK:
  match st:
    case SK{+idx, +found, +at}: sr_skip_m(found, sr_is_sp(c), idx, at)

def sr_skip_go(s: String, +st: SR_SK) -> SR_SK:
  match s:
    case SNil{}: st
    case SCon{+h, t}: sr_skip_go(t, sr_skip_nx(N.chr_code(h), st))

def sr_sk_at(+r: SR_SK) -> Nat:
  SK{idx, found, at} = r
  at

def sr_drop(s: String, +n: Nat) -> String:
  match s:
    case SNil{}: SNil{}
    case SCon{h, t}:
      match n:
        case 0n: SCon{h, t}
        case 1n+j: sr_drop(t, j)

def sr_skip_sp(+s: String) -> String:
  sr_drop(s, sr_sk_at(sr_skip_go(s, SK{0n, False{}, 0n})))

def sr_is_lparen(s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{h, t}: U32.is_eq(N.chr_code(h), 40)

def sr_is_rparen(s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{h, t}: U32.is_eq(N.chr_code(h), 41)

def sr_nx_m2(+nm: Bool, +idx: Nat, +at: Nat) -> SR_NX:
  match nm:
    case True{}: NX{Nat.add(idx, 1n), False{}, Nat.add(idx, 1n)}
    case False{}: NX{Nat.add(idx, 1n), True{}, idx}

def sr_nx_m(+found: Bool, +nm: Bool, +idx: Nat, +at: Nat) -> SR_NX:
  match found:
    case True{}: NX{Nat.add(idx, 1n), True{}, at}
    case False{}: sr_nx_m2(nm, idx, at)

def sr_nx_nx(+c: U32, +st: SR_NX) -> SR_NX:
  match st:
    case NX{+idx, +found, +at}: sr_nx_m(found, sr_is_nm(c), idx, at)

def sr_nx_go(s: String, +st: SR_NX) -> SR_NX:
  match s:
    case SNil{}: st
    case SCon{+h, t}: sr_nx_go(t, sr_nx_nx(N.chr_code(h), st))

def sr_nx_at(+r: SR_NX) -> Nat:
  NX{idx, found, at} = r
  at

def sr_take_go(s: String, +n: Nat, +acc: List<&2, Char>) -> String:
  match s:
    case SNil{}: sr_mkstr(acc)
    case SCon{h, t}:
      match n:
        case 0n: sr_mkstr(acc)
        case 1n+j: sr_take_go(t, j, h <> acc)

def sr_take(s: String, +n: Nat) -> String:
  sr_take_go(s, n, [])

def sr_take_nm(+s: String) -> SR_NM:
  +at = sr_nx_at(sr_nx_go(s, NX{0n, False{}, 0n}))
  SR_NM{sr_take(s, at), sr_drop(s, at)}

def sr_inner_m5(+rp0: Bool, +idx: Nat, +depth: Nat, +at: Nat) -> SR_IX:
  match rp0:
    case True{}: IX{Nat.add(idx, 1n), depth, False{}, True{}, idx}
    case False{}: IX{Nat.add(idx, 1n), Nat.sub(depth, 1n), False{}, False{}, at}

def sr_inner_m4c(+rp: Bool, +idx: Nat, +depth: Nat, +at: Nat) -> SR_IX:
  match rp:
    case True{}: sr_inner_m5(Nat.is_eq(depth, 0n), idx, depth, at)
    case False{}: IX{Nat.add(idx, 1n), depth, False{}, False{}, at}

def sr_inner_m4b(+lp: Bool, +rp: Bool, +idx: Nat, +depth: Nat, +at: Nat) -> SR_IX:
  match lp:
    case True{}: IX{Nat.add(idx, 1n), Nat.add(depth, 1n), False{}, False{}, at}
    case False{}: sr_inner_m4c(rp, idx, depth, at)

def sr_inner_m4(+qu: Bool, +lp: Bool, +rp: Bool, +idx: Nat, +depth: Nat, +at: Nat) -> SR_IX:
  match qu:
    case True{}: IX{Nat.add(idx, 1n), depth, True{}, False{}, at}
    case False{}: sr_inner_m4b(lp, rp, idx, depth, at)

def sr_inner_m3(+qu: Bool, +idx: Nat, +depth: Nat, +at: Nat) -> SR_IX:
  match qu:
    case True{}: IX{Nat.add(idx, 1n), depth, False{}, False{}, at}
    case False{}: IX{Nat.add(idx, 1n), depth, True{}, False{}, at}

def sr_inner_m2(+instr: Bool, +c: U32, +idx: Nat, +depth: Nat, +at: Nat) -> SR_IX:
  match instr:
    case True{}: sr_inner_m3(U32.is_eq(c, 39), idx, depth, at)
    case False{}: sr_inner_m4(U32.is_eq(c, 39), U32.is_eq(c, 40), U32.is_eq(c, 41), idx, depth, at)

def sr_inner_m(+found: Bool, +instr: Bool, +c: U32, +idx: Nat, +depth: Nat, +at: Nat) -> SR_IX:
  match found:
    case True{}: IX{Nat.add(idx, 1n), depth, instr, True{}, at}
    case False{}: sr_inner_m2(instr, c, idx, depth, at)

def sr_inner_nx(+c: U32, +st: SR_IX) -> SR_IX:
  match st:
    case IX{+idx, +depth, +instr, +found, +at}: sr_inner_m(found, instr, c, idx, depth, at)

def sr_inner_go(s: String, +st: SR_IX) -> SR_IX:
  match s:
    case SNil{}: st
    case SCon{+h, t}: sr_inner_go(t, sr_inner_nx(N.chr_code(h), st))

def sr_ix_found(+r: SR_IX) -> Bool:
  IX{idx, depth, instr, found, at} = r
  found

def sr_ix_at(+r: SR_IX) -> Nat:
  IX{idx, depth, instr, found, at} = r
  at

def sr_inner(+s: String) -> SR_IN:
  +st = sr_inner_go(s, IX{0n, 0n, False{}, False{}, 0n})
  +at = sr_ix_at(st)
  SR_IN{sr_ix_found(st), sr_take(s, at), sr_drop(s, Nat.add(at, 1n))}

def sr_is_numc(+c: U32) -> Bool:
  Bool.or(Bool.or(N.is_dg(c), U32.is_eq(c, 46)),
    Bool.or(Bool.or(U32.is_eq(c, 43), U32.is_eq(c, 45)),
      Bool.or(U32.is_eq(c, 101), U32.is_eq(c, 69))))

def sr_is_nmc(+c: U32) -> Bool:
  Bool.or(Bool.or(Bool.and(U32.is_le(65, c), U32.is_le(c, 90)), Bool.and(U32.is_le(97, c), U32.is_le(c, 122))),
    U32.is_eq(c, 95))

def sr_is_nmc2(+c: U32) -> Bool:
  Bool.or(sr_is_nmc(c), N.is_dg(c))

def sr_ck(+c: U32) -> U64:
  Bool.pick(U64, U32.is_eq(c, 40), 1u64, Bool.pick(U64, U32.is_eq(c, 41), 2u64,
    Bool.pick(U64, U32.is_eq(c, 44), 3u64, Bool.pick(U64, U32.is_eq(c, 35), 4u64,
      Bool.pick(U64, U32.is_eq(c, 39), 5u64, Bool.pick(U64, U32.is_eq(c, 46), 6u64,
        Bool.pick(U64, Bool.or(U32.is_eq(c, 36), U32.is_eq(c, 42)), 7u64,
          Bool.pick(U64, sr_is_sp(c), 8u64, Bool.pick(U64, sr_is_nmc(c), 10u64,
            Bool.pick(U64, sr_is_numc(c), 9u64, 0u64))))))))))

def sr_tok_nx_b2(+k: U64, h: Char, +out: List<&2, SR_T>) -> SR_TS:
  match k:
    case 1u64: TS{0u64, [], TT_lp{} <> out, 0u64, 0n}
    case 2u64: TS{0u64, [], TT_rp{} <> out, 0u64, 0n}
    case 3u64: TS{0u64, [], TT_co{} <> out, 0u64, 0n}
    case 4u64: TS{3u64, [], out, 0u64, 0n}
    case 5u64: TS{1u64, [], out, 0u64, 0n}
    case 6u64: TS{4u64, [], out, 0u64, 0n}
    case 7u64: TS{0u64, [], TT_mt{} <> out, 0u64, 0n}
    case 8u64: TS{0u64, [], out, 0u64, 0n}
    case 9u64: TS{2u64, [h], out, 0u64, 0n}
    case 10u64: TS{6u64, [], out, 0u64, 0n}
    case _: TS{0u64, [], TT_bad{} <> out, 0u64, 0n}

def sr_tok_nx_b(+c: U32, h: Char, +out: List<&2, SR_T>) -> SR_TS:
  sr_tok_nx_b2(sr_ck(c), h, out)

def sr_tok_nx_f2(+nc: Bool, +c: U32, h: Char, +out: List<&2, SR_T>) -> SR_TS:
  match nc:
    case True{}: TS{6u64, [], out, 0u64, 0n}
    case False{}: sr_tok_nx_b(c, h, out)

def sr_tok_nx_f(+c: U32, h: Char, +out: List<&2, SR_T>) -> SR_TS:
  sr_tok_nx_f2(sr_is_nmc2(c), c, h, out)

def sr_tok_nx_s2(+qu: Bool, h: Char, +cur: List<&2, Char>, +out: List<&2, SR_T>) -> SR_TS:
  match qu:
    case True{}: TS{5u64, cur, out, 0u64, 0n}
    case False{}: TS{1u64, h <> cur, out, 0u64, 0n}

def sr_tok_nx_s(+c: U32, h: Char, +cur: List<&2, Char>, +out: List<&2, SR_T>) -> SR_TS:
  sr_tok_nx_s2(U32.is_eq(c, 39), h, cur, out)

def sr_tok_nx_n2(+nc: Bool, +c: U32, h: Char, +cur: List<&2, Char>, +out: List<&2, SR_T>) -> SR_TS:
  match nc:
    case True{}: TS{2u64, h <> cur, out, 0u64, 0n}
    case False{}: sr_tok_nx_b(c, h, TT_num{sr_mkstr(cur)} <> out)

def sr_tok_nx_n(+c: U32, h: Char, +cur: List<&2, Char>, +out: List<&2, SR_T>) -> SR_TS:
  sr_tok_nx_n2(sr_is_numc(c), c, h, cur, out)

def sr_tok_nx_r3(+nd: Nat, +c: U32, h: Char, +acc: U64, +out: List<&2, SR_T>) -> SR_TS:
  match nd:
    case 0n: sr_tok_nx_b(c, h, TT_bad{} <> out)
    case 1n+d: sr_tok_nx_b(c, h, TT_ref{acc} <> out)

def sr_tok_nx_r2(+dg: Bool, +c: U32, h: Char, +acc: U64, +nd: Nat, +out: List<&2, SR_T>) -> SR_TS:
  match dg:
    case True{}: TS{3u64, [], out, U64.add(U64.mul(acc, 10u64), N.dg_v(c)), Nat.add(nd, 1n)}
    case False{}: sr_tok_nx_r3(nd, c, h, acc, out)

def sr_tok_nx_r(+c: U32, h: Char, +acc: U64, +nd: Nat, +out: List<&2, SR_T>) -> SR_TS:
  sr_tok_nx_r2(N.is_dg(c), c, h, acc, nd, out)

def sr_tok_nx_e2(+dot: Bool, h: Char, +cur: List<&2, Char>, +out: List<&2, SR_T>) -> SR_TS:
  match dot:
    case True{}: TS{0u64, [], TT_en{sr_mkstr(cur)} <> out, 0u64, 0n}
    case False{}: TS{4u64, h <> cur, out, 0u64, 0n}

def sr_tok_nx_e(+c: U32, h: Char, +cur: List<&2, Char>, +out: List<&2, SR_T>) -> SR_TS:
  sr_tok_nx_e2(U32.is_eq(c, 46), h, cur, out)

def sr_tok_nx_q2(+qu: Bool, h: Char, +c: U32, +cur: List<&2, Char>, +out: List<&2, SR_T>) -> SR_TS:
  match qu:
    case True{}: TS{1u64, h <> cur, out, 0u64, 0n}
    case False{}: sr_tok_nx_b(c, h, TT_str{sr_mkstr(cur)} <> out)

def sr_tok_nx_q(+c: U32, h: Char, +cur: List<&2, Char>, +out: List<&2, SR_T>) -> SR_TS:
  sr_tok_nx_q2(U32.is_eq(c, 39), h, c, cur, out)

def sr_tok_nx_m(+mode: U64, +c: U32, h: Char, +cur: List<&2, Char>, +out: List<&2, SR_T>,
    +acc: U64, +nd: Nat) -> SR_TS:
  match mode:
    case 0u64: sr_tok_nx_b(c, h, out)
    case 1u64: sr_tok_nx_s(c, h, cur, out)
    case 2u64: sr_tok_nx_n(c, h, cur, out)
    case 3u64: sr_tok_nx_r(c, h, acc, nd, out)
    case 4u64: sr_tok_nx_e(c, h, cur, out)
    case 5u64: sr_tok_nx_q(c, h, cur, out)
    case 6u64: sr_tok_nx_f(c, h, out)
    case _: TS{0u64, [], TT_bad{} <> out, 0u64, 0n}

def sr_tok_nx(+c: U32, h: Char, +st: SR_TS) -> SR_TS:
  TS{+mode, +cur, +out, +acc, +nd} = st
  sr_tok_nx_m(mode, c, h, cur, out, acc, nd)

def sr_tok_end_n(+cur: List<&2, Char>, +out: List<&2, SR_T>) -> List<&2, SR_T>:
  match cur:
    case []: out
    case _ <> _: TT_num{sr_mkstr(cur)} <> out

def sr_tok_end_r(+nd: Nat, +acc: U64, +out: List<&2, SR_T>) -> List<&2, SR_T>:
  match nd:
    case 0n: TT_bad{} <> out
    case 1n+d: TT_ref{acc} <> out

def sr_tok_end_m(+mode: U64, +cur: List<&2, Char>, +out: List<&2, SR_T>, +acc: U64,
    +nd: Nat) -> List<&2, SR_T>:
  match mode:
    case 0u64: List.reverse(&2, SR_T, out)
    case 1u64: List.reverse(&2, SR_T, TT_str{sr_mkstr(cur)} <> out)
    case 2u64: List.reverse(&2, SR_T, sr_tok_end_n(cur, out))
    case 3u64: List.reverse(&2, SR_T, sr_tok_end_r(nd, acc, out))
    case 4u64: List.reverse(&2, SR_T, TT_bad{} <> out)
    case 5u64: List.reverse(&2, SR_T, TT_str{sr_mkstr(cur)} <> out)
    case 6u64: List.reverse(&2, SR_T, out)
    case _: List.reverse(&2, SR_T, TT_bad{} <> out)

def sr_tok_end(+st: SR_TS) -> List<&2, SR_T>:
  TS{+mode, +cur, +out, +acc, +nd} = st
  sr_tok_end_m(mode, cur, out, acc, nd)

def sr_tok_go(s: String, +st: SR_TS) -> List<&2, SR_T>:
  match s:
    case SNil{}: sr_tok_end(st)
    case SCon{+h, t}: sr_tok_go(t, sr_tok_nx(N.chr_code(h), h, st))

def sr_tokens(s: String) -> List<&2, SR_T>:
  sr_tok_go(s, TS{0u64, [], [], 0u64, 0n})

def sr_sa_add(st: List<&2, List<&2, SA>>, +x: SA) -> List<&2, List<&2, SA>>:
  match st:
    case []: [[x]]
    case f <> t: (x <> f) <> t

def sr_sa_pop(st: List<&2, List<&2, SA>>) -> List<&2, List<&2, SA>>:
  match st:
    case []: []
    case f <> t: sr_sa_add(t, SA_ls{List.reverse(&2, SA, f)})

def sr_sa_len(st: List<&2, List<&2, SA>>) -> Nat:
  List.length(&2, List<&2, SA>, st)

def sr_sa_top(st: List<&2, List<&2, SA>>) -> List<&2, SA>:
  match st:
    case []: []
    case f <> t: List.reverse(&2, SA, f)

def sr_sa_go(ts: List<&2, SR_T>, +st: List<&2, List<&2, SA>>, +ok: Bool) -> SR_AS:
  match ts:
    case []: SR_AS{Bool.and(ok, Nat.is_eq(sr_sa_len(st), 1n)), sr_sa_top(st)}
    case t <> r:
      match t:
        case TT_lp{}: sr_sa_go(r, [] <> st, ok)
        case TT_rp{}: sr_sa_go(r, sr_sa_pop(st), Bool.and(ok, Nat.is_le(2n, sr_sa_len(st))))
        case TT_co{}: sr_sa_go(r, st, ok)
        case TT_ref{+id}: sr_sa_go(r, sr_sa_add(st, SA_ref{id}), ok)
        case TT_str{+s}: sr_sa_go(r, sr_sa_add(st, SA_str{s}), ok)
        case TT_en{+s}: sr_sa_go(r, sr_sa_add(st, SA_en{s}), ok)
        case TT_num{+s}: sr_sa_go(r, sr_sa_add(st, SA_num{s}), ok)
        case TT_mt{}: sr_sa_go(r, sr_sa_add(st, SA_mt{}), ok)
        case TT_bad{}: sr_sa_go(r, st, False{})

def sr_sa(ts: List<&2, SR_T>) -> SR_AS:
  sr_sa_go(ts, [[]], True{})

def sr_nm_s(+r: SR_NM) -> String:
  SR_NM{nm, rest} = r
  nm

def sr_nm_rest(+r: SR_NM) -> String:
  SR_NM{nm, rest} = r
  rest

def sr_in_ok(+r: SR_IN) -> Bool:
  SR_IN{ok, inner, rest} = r
  ok

def sr_in_inner(+r: SR_IN) -> String:
  SR_IN{ok, inner, rest} = r
  inner

def sr_in_rest(+r: SR_IN) -> String:
  SR_IN{ok, inner, rest} = r
  rest

def sr_as_ok(+r: SR_AS) -> Bool:
  SR_AS{ok, xs} = r
  ok

def sr_as_xs(+r: SR_AS) -> List<&2, SA>:
  SR_AS{ok, xs} = r
  xs

def sr_ps_ok(+r: SR_PS) -> Bool:
  SR_PS{ok, ps, rest} = r
  ok

def sr_ps_xs(+r: SR_PS) -> List<&2, SPt>:
  SR_PS{ok, ps, rest} = r
  ps

def sr_ps_rest(+r: SR_PS) -> String:
  SR_PS{ok, ps, rest} = r
  rest

def sr_ps_hd2(ps: List<&2, SPt>) -> SPt:
  match ps:
    case []: SPt{"", []}
    case h <> t: h

def sr_ps_hd(+r: SR_PS) -> SPt:
  SR_PS{ok, ps, rest} = r
  sr_ps_hd2(ps)

def sr_id_ok(+r: SR_ID) -> Bool:
  SR_ID{ok, id, rest} = r
  ok

def sr_id_v(+r: SR_ID) -> U64:
  SR_ID{ok, id, rest} = r
  id

def sr_id_rest(+r: SR_ID) -> String:
  SR_ID{ok, id, rest} = r
  rest

def sr_e_ok(+r: SR_E) -> Bool:
  SR_E{ok, id, ps} = r
  ok

def sr_e_id(+r: SR_E) -> U64:
  SR_E{ok, id, ps} = r
  id

def sr_e_ps(+r: SR_E) -> List<&2, SPt>:
  SR_E{ok, id, ps} = r
  ps

def sr_tail(s: String) -> String:
  match s:
    case SNil{}: SNil{}
    case SCon{h, t}: t

def sr_partial_as(+w: Bool, +pnm: String, +a: SR_AS, +rest: String) -> SR_PS:
  match w:
    case False{}: SR_PS{False{}, [], ""}
    case True{}: SR_PS{True{}, [SPt{pnm, sr_as_xs(a)}], rest}

def sr_partial_in(+w: Bool, +pnm: String, +r: SR_IN) -> SR_PS:
  match w:
    case False{}: SR_PS{False{}, [], ""}
    case True{}:
      +a = sr_sa(sr_tokens(sr_in_inner(r)))
      sr_partial_as(sr_as_ok(a), pnm, a, sr_in_rest(r))

def sr_partial_lp(+lp: Bool, +pnm: String, +c: String) -> SR_PS:
  match lp:
    case False{}: SR_PS{False{}, [], ""}
    case True{}:
      +r = sr_inner(sr_tail(c))
      sr_partial_in(sr_in_ok(r), pnm, r)

def sr_partial(s: String) -> SR_PS:
  +b = sr_skip_sp(s)
  +nm = sr_take_nm(b)
  +c = sr_skip_sp(sr_nm_rest(nm))
  sr_partial_lp(sr_is_lparen(c), sr_nm_s(nm), c)

def sr_is_blank(s: String) -> Bool:
  String.eq(sr_skip_sp(s), "")

def sr_pl_acc(+w: Bool, +r: SR_PS, +acc: List<&2, SPt>) -> List<&2, SPt>:
  match w:
    case True{}: sr_ps_hd(r) <> acc
    case False{}: acc

def sr_partials_m2(+blank: Bool, +b: String, +s: String, +acc: List<&2, SPt>, +ok: Bool) -> SR_PL:
  match blank:
    case True{}: PL{s, acc, ok, True{}}
    case False{}:
      +r = sr_partial(b)
      PL{sr_ps_rest(r), sr_pl_acc(sr_ps_ok(r), r, acc), Bool.and(ok, sr_ps_ok(r)), False{}}

def sr_partials_m(+done: Bool, +blank: Bool, +b: String, +s: String, +acc: List<&2, SPt>,
    +ok: Bool) -> SR_PL:
  match done:
    case True{}: PL{s, acc, ok, True{}}
    case False{}: sr_partials_m2(blank, b, s, acc, ok)

def sr_partials_nx(+b: String, +st: SR_PL) -> SR_PL:
  match st:
    case PL{+s, +acc, +ok, +done}: sr_partials_m(done, String.eq(b, ""), b, s, acc, ok)

def sr_pl_s(+r: SR_PL) -> String:
  PL{s, acc, ok, done} = r
  s

def sr_partials_go(+fuel: Nat, +st: SR_PL) -> SR_PL:
  match fuel:
    case 0n: st
    case 1n+f: sr_partials_go(f, sr_partials_nx(sr_skip_sp(sr_pl_s(st)), st))

def sr_partials_fin(+st: SR_PL) -> SR_PS:
  match st:
    case PL{+s, +acc, +ok, +done}: SR_PS{Bool.and(ok, done), List.reverse(&2, SPt, acc), ""}

def sr_partials(+fuel: Nat, +s: String) -> SR_PS:
  sr_partials_fin(sr_partials_go(fuel, PL{s, [], True{}, False{}}))

def sr_ent_end(+blank: Bool, +id: U64, +r: SR_PS) -> SR_E:
  match blank:
    case False{}: SR_E{False{}, 0u64, []}
    case True{}: SR_E{True{}, id, sr_ps_xs(r)}

def sr_ent_tail(+w: Bool, +id: U64, +r: SR_PS) -> SR_E:
  match w:
    case False{}: SR_E{False{}, 0u64, []}
    case True{}: sr_ent_end(sr_is_blank(sr_ps_rest(r)), id, r)

def sr_ent_cx3(+w: Bool, +id: U64, +pr: SR_PS, +rest: String) -> SR_E:
  match w:
    case False{}: SR_E{False{}, 0u64, []}
    case True{}: sr_ent_end(sr_is_blank(rest), id, pr)

def sr_ent_cx2(+w: Bool, +id: U64, +fuel: Nat, +inr: SR_IN) -> SR_E:
  match w:
    case False{}: SR_E{False{}, 0u64, []}
    case True{}:
      +pr = sr_partials(fuel, sr_in_inner(inr))
      sr_ent_cx3(sr_ps_ok(pr), id, pr, sr_in_rest(inr))

def sr_ent_cx(+cx: Bool, +id: U64, +b: String, +fuel: Nat) -> SR_E:
  match cx:
    case True{}:
      +inr = sr_inner(sr_tail(b))
      sr_ent_cx2(sr_in_ok(inr), id, fuel, inr)
    case False{}:
      +r = sr_partial(b)
      sr_ent_tail(sr_ps_ok(r), id, r)

def sr_ent_body(+id: U64, +rest: String, +fuel: Nat) -> SR_E:
  +b = sr_skip_sp(sr_body_of(rest))
  sr_ent_cx(sr_is_lparen(b), id, b, fuel)

def sr_ent_id(+w: Bool, +r: SR_ID, +fuel: Nat) -> SR_E:
  match w:
    case False{}: SR_E{False{}, 0u64, []}
    case True{}: sr_ent_body(sr_id_v(r), sr_id_rest(r), fuel)

def sr_ent_h(+hash: Bool, t: String, +fuel: Nat) -> SR_E:
  match hash:
    case False{}: SR_E{False{}, 0u64, []}
    case True{}:
      +r = sr_parse_id(t, 0u64)
      sr_ent_id(sr_id_ok(r), r, fuel)

def sr_ent(+e: String, +fuel: Nat) -> SR_E:
  match e:
    case SNil{}: SR_E{False{}, 0u64, []}
    case SCon{h, t}: sr_ent_h(U32.is_eq(N.chr_code(h), 35), t, fuel)

def sr_cap() -> Nat:
  100000n

def sr_fuel_of(s: String) -> Nat:
  Nat.add(List.length(&2, Char, sr_chars(s)), 1n)

def sr_ents_acc2(+w: Bool, +r: SR_E, +acc: List<&2, SE>) -> List<&2, SE>:
  match w:
    case False{}: []
    case True{}: SE{sr_e_id(r), sr_e_ps(r)} <> acc

def sr_ents_acc(+oko: Bool, +w: Bool, +r: SR_E, +acc: List<&2, SE>) -> List<&2, SE>:
  match oko:
    case False{}: []
    case True{}: sr_ents_acc2(w, r, acc)

def sr_ents_go(es: List<&2, String>, +acc: List<&2, SE>, +n: Nat, +ok: Bool) -> SR_EN:
  match es:
    case []: SR_EN{Bool.and(ok, Nat.is_le(n, sr_cap())), List.reverse(&2, SE, acc)}
    case +h <> t:
      +r = sr_ent(h, sr_fuel_of(h))
      sr_ents_go(t, sr_ents_acc(ok, sr_e_ok(r), r, acc), Nat.add(n, 1n), Bool.and(ok, sr_e_ok(r)))

def sr_ents(es: List<&2, String>) -> SR_EN:
  sr_ents_go(es, [], 0n, True{})

def sr_spt_nm(+r: SPt) -> String:
  SPt{nm, args} = r
  nm

def sr_has_nm(ps: List<&2, SPt>, +s: String) -> Bool:
  match ps:
    case []: False{}
    case +h <> t: Bool.or(String.eq(sr_spt_nm(h), s), sr_has_nm(t, s))

def sr_first_nm(ps: List<&2, SPt>) -> String:
  match ps:
    case []: ""
    case h <> t: sr_spt_nm(h)

def sr_kind_nm(+s: String) -> U64:
  Bool.pick(U64, String.eq(s, "CARTESIAN_POINT"), 1u64,
    Bool.pick(U64, String.eq(s, "DIRECTION"), 2u64,
      Bool.pick(U64, String.eq(s, "VECTOR"), 3u64,
        Bool.pick(U64, String.eq(s, "LINE"), 4u64,
          Bool.pick(U64, String.eq(s, "CIRCLE"), 5u64,
            Bool.pick(U64, String.eq(s, "TRIMMED_CURVE"), 6u64,
              Bool.pick(U64, String.eq(s, "AXIS2_PLACEMENT_3D"), 9u64,
                Bool.pick(U64, String.eq(s, "PLANE"), 10u64,
                  Bool.pick(U64, String.eq(s, "SPHERICAL_SURFACE"), 11u64,
                    Bool.pick(U64, String.eq(s, "CYLINDRICAL_SURFACE"), 12u64,
                      Bool.pick(U64, String.eq(s, "TOROIDAL_SURFACE"), 13u64,
                        Bool.pick(U64, String.eq(s, "CONICAL_SURFACE"), 27u64,
                          Bool.pick(U64, String.eq(s, "VERTEX_POINT"), 15u64,
                            Bool.pick(U64, String.eq(s, "EDGE_CURVE"), 16u64,
                              Bool.pick(U64, String.eq(s, "ORIENTED_EDGE"), 17u64,
                                Bool.pick(U64, String.eq(s, "EDGE_LOOP"), 18u64,
                                  Bool.pick(U64, String.eq(s, "FACE_BOUND"), 19u64,
                                    Bool.pick(U64, String.eq(s, "FACE_OUTER_BOUND"), 26u64,
                                      Bool.pick(U64, String.eq(s, "ADVANCED_FACE"), 20u64,
                                        Bool.pick(U64, String.eq(s, "CLOSED_SHELL"), 21u64,
                                          Bool.pick(U64, String.eq(s, "OPEN_SHELL"), 28u64,
                                            Bool.pick(U64, String.eq(s, "MANIFOLD_SOLID_BREP"), 22u64,
                                              Bool.pick(U64, String.eq(s, "VERTEX_LOOP"), 23u64,
                                                Bool.pick(U64, String.eq(s, "SURFACE_CURVE"), 24u64,
                                                  Bool.pick(U64, String.eq(s, "SEAM_CURVE"), 25u64,
                                                    Bool.pick(U64, String.eq(s, "BREP_WITH_VOIDS"), 30u64,
                                                      Bool.pick(U64, String.eq(s, "MAPPED_ITEM"), 31u64,
                                                        Bool.pick(U64, String.eq(s, "REPRESENTATION_MAP"), 31u64,
                                                          Bool.pick(U64, String.eq(s, "ITEM_DEFINED_TRANSFORMATION"), 31u64,
                                                            Bool.pick(U64, String.eq(s, "CONTEXT_DEPENDENT_SHAPE_REPRESENTATION"), 31u64,
                                                              Bool.pick(U64, String.eq(s, "NEXT_ASSEMBLY_USAGE_OCCURRENCE"), 31u64,
                                                                Bool.pick(U64, String.eq(s, "REPRESENTATION_RELATIONSHIP_WITH_TRANSFORMATION"), 31u64,
                                                                  0u64))))))))))))))))))))))))))))))))

def sr_kind_cx3(+bsk: Bool, +ps: List<&2, SPt>) -> U64:
  match bsk:
    case True{}: 14u64
    case False{}: sr_kind_nm(sr_first_nm(ps))

def sr_kind_cx2(+bck: Bool, +bsk: Bool, +ps: List<&2, SPt>) -> U64:
  match bck:
    case True{}: 8u64
    case False{}: sr_kind_cx3(bsk, ps)

def sr_kind_cx(+rat: Bool, +bck: Bool, +bsk: Bool, +ps: List<&2, SPt>) -> U64:
  match rat:
    case True{}: 7u64
    case False{}: sr_kind_cx2(bck, bsk, ps)

def sr_has_asm(+ps: List<&2, SPt>) -> Bool:
  Bool.or(sr_has_nm(ps, "MAPPED_ITEM"), Bool.or(sr_has_nm(ps, "REPRESENTATION_MAP"),
    Bool.or(sr_has_nm(ps, "ITEM_DEFINED_TRANSFORMATION"),
      Bool.or(sr_has_nm(ps, "CONTEXT_DEPENDENT_SHAPE_REPRESENTATION"),
        Bool.or(sr_has_nm(ps, "NEXT_ASSEMBLY_USAGE_OCCURRENCE"),
          sr_has_nm(ps, "REPRESENTATION_RELATIONSHIP_WITH_TRANSFORMATION"))))))

def sr_kind_as(+asm: Bool, +rat: Bool, +bck: Bool, +bsk: Bool, +ps: List<&2, SPt>) -> U64:
  match asm:
    case True{}: 31u64
    case False{}: sr_kind_cx(rat, bck, bsk, ps)

def sr_kind_si(+si: Bool, +asm: Bool, +rat: Bool, +bck: Bool, +bsk: Bool, +ps: List<&2, SPt>) ->
    U64:
  match si:
    case True{}: 29u64
    case False{}: sr_kind_as(asm, rat, bck, bsk, ps)

def sr_kind_of(+e: SE) -> U64:
  SE{+id, +ps} = e
  sr_kind_si(sr_has_nm(ps, "SI_UNIT"), sr_has_asm(ps), sr_has_nm(ps, "RATIONAL_B_SPLINE_CURVE"),
    sr_has_nm(ps, "B_SPLINE_CURVE_WITH_KNOTS"), sr_has_nm(ps, "B_SPLINE_SURFACE_WITH_KNOTS"), ps)

def sr_se_cmp(a: SE, b: SE) -> B.Sgn:
  SE{+x, +px} = a
  SE{+y, +py} = b
  B.sgn_pick(Nat.is_lt(U64.to_nat(x), U64.to_nat(y)), Nat.is_lt(U64.to_nat(y), U64.to_nat(x)))

def sr_so_ok(+r: B.So<&2, SE>) -> Bool:
  B.So{ok, xs} = r
  ok

def sr_so_xs(+r: B.So<&2, SE>) -> List<&2, SE>:
  B.So{ok, xs} = r
  xs

def sr_c_fail() -> SR_C:
  SR_C{False{}, G.GV_ln{G.Ln{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64}}},
    0.0f64, 0.0f64}

def sr_kr_rank(+r: KR) -> Nat:
  KR{+id, +kind, +rank} = r
  rank

def sr_rank_k(+w: Bool, +k: KR) -> SR_I:
  match w:
    case False{}: SR_I{False{}, 0n}
    case True{}: SR_I{True{}, sr_kr_rank(k)}

def sr_kr_at(+st: ST, +pos: Nat) -> KR:
  ST{+ents, +krs, +n} = st
  B.tb_get(KR, krs, U32.from_nat(pos))

def sr_kr_kind(+r: KR) -> U64:
  KR{+id, +kind, +rank} = r
  kind

def sr_rank_f(+w: Bool, +st: ST, +pos: Nat, +kind: U64) -> SR_I:
  match w:
    case False{}: SR_I{False{}, 0n}
    case True{}:
      +k = sr_kr_at(st, pos)
      sr_rank_k(U64.is_eq(sr_kr_kind(k), kind), k)

def sr_f_ok(+r: SF) -> Bool:
  SF{ok, pos} = r
  ok

def sr_f_pos(+r: SF) -> Nat:
  SF{ok, pos} = r
  pos

def sr_find_fin(+fx: SR_FX) -> SF:
  match fx:
    case FX{+lo, +hi, +found, +pos}: SF{found, pos}

def sr_cmp_id(+x: U64, +y: U64) -> U64:
  Bool.pick(U64, U64.is_eq(x, y), 1u64,
    Bool.pick(U64, Nat.is_lt(U64.to_nat(x), U64.to_nat(y)), 0u64, 2u64))

def sr_ent_at(+st: ST, +pos: Nat) -> SE:
  ST{+ents, +krs, +n} = st
  B.tb_get(SE, ents, U32.from_nat(pos))

def sr_find_c(+c: U64, +lo: Nat, +mid: Nat, +hi: Nat) -> SR_FX:
  match c:
    case 0u64: FX{Nat.add(mid, 1n), hi, False{}, 0n}
    case 1u64: FX{lo, hi, True{}, mid}
    case _: FX{lo, mid, False{}, 0n}

def sr_se_id(+e: SE) -> U64:
  SE{+id, +ps} = e
  id

def sr_find_w(+w: Bool, +st: ST, +id: U64, +lo: Nat, +hi: Nat) -> SR_FX:
  match w:
    case False{}: FX{lo, hi, False{}, 0n}
    case True{}:
      +mid = Nat.add(lo, Nat.div(Nat.sub(hi, lo), 2n))
      sr_find_c(sr_cmp_id(sr_se_id(sr_ent_at(st, mid)), id), lo, mid, hi)

def sr_find_m(+found: Bool, +w: Bool, +st: ST, +id: U64, +lo: Nat, +hi: Nat, +pos: Nat) -> SR_FX:
  match found:
    case True{}: FX{lo, hi, True{}, pos}
    case False{}: sr_find_w(w, st, id, lo, hi)

def sr_find_nx(+st: ST, +id: U64, +fx: SR_FX) -> SR_FX:
  match fx:
    case FX{+lo, +hi, +found, +pos}: sr_find_m(found, Nat.is_lt(lo, hi), st, id, lo, hi, pos)

def sr_find_go(+fuel: Nat, +st: ST, +id: U64, +fx: SR_FX) -> SF:
  match fuel:
    case 0n: sr_find_fin(fx)
    case 1n+f: sr_find_go(f, st, id, sr_find_nx(st, id, fx))

def sr_st_n(+st: ST) -> Nat:
  ST{+ents, +krs, +n} = st
  n

def sr_find(+st: ST, +id: U64) -> SF:
  sr_find_go(64n, st, id, FX{0n, sr_st_n(st), False{}, 0n})

def sr_rank_id(+st: ST, +id: U64, +kind: U64) -> SR_I:
  +f = sr_find(st, id)
  sr_rank_f(sr_f_ok(f), st, sr_f_pos(f), kind)

def sr_rank_of(+st: ST, +a: SA, +kind: U64) -> SR_I:
  match a:
    case SA_ref{+id}: sr_rank_id(st, id, kind)
    case _: SR_I{False{}, 0n}

def sr_i_v(+r: SR_I) -> Nat:
  SR_I{ok, i} = r
  i

def sr_rl_acc2(+w: Bool, +r: SR_I, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match w:
    case True{}: sr_i_v(r) <> acc
    case False{}: acc

def sr_rl_acc(+oko: Bool, +w: Bool, +r: SR_I, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match oko:
    case False{}: []
    case True{}: sr_rl_acc2(w, r, acc)

def sr_i_ok(+r: SR_I) -> Bool:
  SR_I{ok, i} = r
  ok

def sr_reflist_go(xs: List<&2, SA>, +st: ST, +kind: U64, +acc: List<&2, Nat>, +ok: Bool) ->
    SR_RL:
  match xs:
    case []: SR_RL{ok, List.reverse(&2, Nat, acc)}
    case +a <> t:
      +r = sr_rank_of(st, a, kind)
      sr_reflist_go(t, st, kind, sr_rl_acc(ok, sr_i_ok(r), r, acc), Bool.and(ok, sr_i_ok(r)))

def sr_reflist(+st: ST, +a: SA, +kind: U64) -> SR_RL:
  match a:
    case SA_ls{+xs}: sr_reflist_go(xs, st, kind, [], True{})
    case _: SR_RL{False{}, []}

def sr_spt_args(+r: SPt) -> List<&2, SA>:
  SPt{nm, args} = r
  args

def sr_p0(ps: List<&2, SPt>) -> SR_PX:
  match ps:
    case []: SR_PX{False{}, []}
    case h <> t: SR_PX{True{}, sr_spt_args(h)}

def sr_a_ok(+r: SR_A) -> Bool:
  SR_A{ok, a} = r
  ok

def sr_a_v(+r: SR_A) -> SA:
  SR_A{ok, a} = r
  a

def sr_nth_go(xs: List<&2, SA>, +i: Nat) -> SR_A:
  match xs:
    case []: SR_A{False{}, SA_mt{}}
    case h <> t:
      match i:
        case 0n: SR_A{True{}, h}
        case 1n+j: sr_nth_go(t, j)

def sr_nth(xs: List<&2, SA>, +i: Nat) -> SR_A:
  sr_nth_go(xs, i)

def sr_n_ok(+r: SR_N) -> Bool:
  SR_N{ok, v} = r
  ok

def sr_n_v(+r: SR_N) -> F64:
  SR_N{ok, v} = r
  v

def sr_num_maybe(m: Maybe<&2, F64>) -> SR_N:
  match m:
    case None{}: SR_N{False{}, 0.0f64}
    case Some{+v}: SR_N{T.is_finite(v), v}

def sr_num_of(+a: SA) -> SR_N:
  match a:
    case SA_num{+s}: sr_num_maybe(N.num(s))
    case _: SR_N{False{}, 0.0f64}

def sr_pt_ok(+w: Bool, +x: F64, +y: F64, +z: F64) -> SR_P:
  match w:
    case True{}: SR_P{True{}, V.Pt{x, y, z}}
    case False{}: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}

def sr_pt_xyz(+a: SA, +b: SA, +c: SA) -> SR_P:
  +rx = sr_num_of(a)
  +ry = sr_num_of(b)
  +rz = sr_num_of(c)
  sr_pt_ok(Bool.and(sr_n_ok(rx), Bool.and(sr_n_ok(ry), sr_n_ok(rz))), sr_n_v(rx), sr_n_v(ry),
    sr_n_v(rz))

def sr_pt_abc(+w: Bool, +a: SA, +b: SA, +c: SA) -> SR_P:
  match w:
    case False{}: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_pt_xyz(a, b, c)

def sr_pt_3(+w: Bool, +xs: List<&2, SA>) -> SR_P:
  match w:
    case False{}: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +ra = sr_nth(xs, 0n)
      +rb = sr_nth(xs, 1n)
      +rc = sr_nth(xs, 2n)
      sr_pt_abc(Bool.and(sr_a_ok(ra), Bool.and(sr_a_ok(rb), sr_a_ok(rc))), sr_a_v(ra), sr_a_v(rb),
        sr_a_v(rc))

def sr_pt_ls(+xs: List<&2, SA>) -> SR_P:
  sr_pt_3(Nat.is_eq(List.length(&2, SA, xs), 3n), xs)

def sr_pt_of(+a: SA) -> SR_P:
  match a:
    case SA_ls{+xs}: sr_pt_ls(xs)
    case _: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}

def sr_pt_a(+w: Bool, +a: SA) -> SR_P:
  match w:
    case False{}: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_pt_of(a)

def sr_pt_x(+w: Bool, +xs: List<&2, SA>) -> SR_P:
  match w:
    case False{}: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_pt_a(sr_a_ok(r), sr_a_v(r))

def sr_px_ok(+r: SR_PX) -> Bool:
  SR_PX{ok, xs} = r
  ok

def sr_px_xs(+r: SR_PX) -> List<&2, SA>:
  SR_PX{ok, xs} = r
  xs

def sr_pt_e(+e: SE) -> SR_P:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_pt_x(sr_px_ok(r), sr_px_xs(r))

def sr_pt_f(+w: Bool, +st: ST, +pos: Nat) -> SR_P:
  match w:
    case False{}: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_pt_e(sr_ent_at(st, pos))

def sr_pt_ent(+st: ST, +id: U64) -> SR_P:
  +f = sr_find(st, id)
  sr_pt_f(sr_f_ok(f), st, sr_f_pos(f))

def sr_vx_a2(+a: SA, +st: ST) -> SR_P:
  match a:
    case SA_ref{+id}: sr_pt_ent(st, id)
    case _: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}

def sr_vx_a(+w: Bool, +a: SA, +st: ST) -> SR_P:
  match w:
    case False{}: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_vx_a2(a, st)

def sr_vx_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_P:
  match w:
    case False{}: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_vx_a(sr_a_ok(r), sr_a_v(r), st)

def sr_vx_e(+k: U64, +e: SE, +st: ST) -> SR_P:
  match k:
    case 15u64:
      SE{+id, +ps} = e
      +r = sr_p0(ps)
      sr_vx_x(sr_px_ok(r), sr_px_xs(r), st)
    case _: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}

def sr_vx_f(+w: Bool, +st: ST, +pos: Nat) -> SR_P:
  match w:
    case False{}: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_vx_e(sr_kr_kind(sr_kr_at(st, pos)), sr_ent_at(st, pos), st)

def sr_vx_pt(+st: ST, +id: U64) -> SR_P:
  +f = sr_find(st, id)
  sr_vx_f(sr_f_ok(f), st, sr_f_pos(f))

def sr_ln_ok(+r: SR_LN) -> Bool:
  LN{ok, o, d} = r
  ok

def sr_ln_o(+r: SR_LN) -> V.Point:
  LN{ok, o, d} = r
  o

def sr_ln_d(+r: SR_LN) -> V.Dir:
  LN{ok, o, d} = r
  d

def sr_d_ok(+r: SR_D) -> Bool:
  SR_D{ok, d} = r
  ok

def sr_d_v(+r: SR_D) -> V.Dir:
  SR_D{ok, d} = r
  d

def sr_ln_v4(+w: Bool, +o: V.Point, +d: V.Dir) -> SR_LN:
  match w:
    case False{}: LN{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: LN{True{}, o, d}

def sr_norm_n(+w: Bool, +x: F64, +y: F64, +z: F64, +n: F64) -> SR_D:
  match w:
    case True{}: SR_D{True{}, V.Dr{F64.div(x, n), F64.div(y, n), F64.div(z, n)}}
    case False{}: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}

def sr_norm(+d: V.Dir) -> SR_D:
  V.Dr{+x, +y, +z} = d
  +n = F64.sqrt(F64.add(F64.mul(x, x), F64.add(F64.mul(y, y), F64.mul(z, z))))
  sr_norm_n(Bool.and(T.is_finite(n), F64.is_lt(0.0f64, n)), x, y, z, n)

def sr_ln_v3(+w: Bool, +o: V.Point, +d0: V.Dir) -> SR_LN:
  match w:
    case False{}: LN{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +r = sr_norm(d0)
      sr_ln_v4(sr_d_ok(r), o, sr_d_v(r))

def sr_dr_ok(+w: Bool, +x: F64, +y: F64, +z: F64) -> SR_D:
  match w:
    case True{}: SR_D{True{}, V.Dr{x, y, z}}
    case False{}: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}

def sr_dr_xyz(+a: SA, +b: SA, +c: SA) -> SR_D:
  +rx = sr_num_of(a)
  +ry = sr_num_of(b)
  +rz = sr_num_of(c)
  sr_dr_ok(Bool.and(sr_n_ok(rx), Bool.and(sr_n_ok(ry), sr_n_ok(rz))), sr_n_v(rx), sr_n_v(ry),
    sr_n_v(rz))

def sr_dr_abc(+w: Bool, +a: SA, +b: SA, +c: SA) -> SR_D:
  match w:
    case False{}: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_dr_xyz(a, b, c)

def sr_dr_3(+w: Bool, +xs: List<&2, SA>) -> SR_D:
  match w:
    case False{}: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +ra = sr_nth(xs, 0n)
      +rb = sr_nth(xs, 1n)
      +rc = sr_nth(xs, 2n)
      sr_dr_abc(Bool.and(sr_a_ok(ra), Bool.and(sr_a_ok(rb), sr_a_ok(rc))), sr_a_v(ra), sr_a_v(rb),
        sr_a_v(rc))

def sr_dr_of(+a: SA) -> SR_D:
  match a:
    case SA_ls{+xs}: sr_dr_3(Nat.is_eq(List.length(&2, SA, xs), 3n), xs)
    case _: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}

def sr_dr_a(+w: Bool, +a: SA) -> SR_D:
  match w:
    case False{}: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_dr_of(a)

def sr_dr_x(+w: Bool, +xs: List<&2, SA>) -> SR_D:
  match w:
    case False{}: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_dr_a(sr_a_ok(r), sr_a_v(r))

def sr_dr_e(+e: SE) -> SR_D:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_dr_x(sr_px_ok(r), sr_px_xs(r))

def sr_dr_f(+w: Bool, +st: ST, +pos: Nat) -> SR_D:
  match w:
    case False{}: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_dr_e(sr_ent_at(st, pos))

def sr_dr_ent(+st: ST, +id: U64) -> SR_D:
  +f = sr_find(st, id)
  sr_dr_f(sr_f_ok(f), st, sr_f_pos(f))

def sr_vec_a(+a: SA, +st: ST) -> SR_D:
  match a:
    case SA_ref{+id}: sr_dr_ent(st, id)
    case _: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}

def sr_vec_ref(+w: Bool, +a: SA, +st: ST) -> SR_D:
  match w:
    case False{}: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_vec_a(a, st)

def sr_vec_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_D:
  match w:
    case False{}: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_vec_ref(sr_a_ok(r), sr_a_v(r), st)

def sr_vec_e(+e: SE, +st: ST) -> SR_D:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_vec_x(sr_px_ok(r), sr_px_xs(r), st)

def sr_vec_f(+w: Bool, +st: ST, +pos: Nat) -> SR_D:
  match w:
    case False{}: SR_D{False{}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_vec_e(sr_ent_at(st, pos), st)

def sr_vec_ent(+st: ST, +id: U64) -> SR_D:
  +f = sr_find(st, id)
  sr_vec_f(sr_f_ok(f), st, sr_f_pos(f))

def sr_ln_v2(+a: SA, +st: ST, +o: V.Point) -> SR_LN:
  match a:
    case SA_ref{+id}:
      +r = sr_vec_ent(st, id)
      sr_ln_v3(sr_d_ok(r), o, sr_d_v(r))
    case _: LN{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64}}

def sr_ln_v(+w: Bool, +a: SA, +st: ST, +o: V.Point) -> SR_LN:
  match w:
    case False{}: LN{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_ln_v2(a, st, o)

def sr_ln_p3(+w: Bool, +st: ST, +xs: List<&2, SA>, +o: V.Point) -> SR_LN:
  match w:
    case False{}: LN{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +r = sr_nth(xs, 2n)
      sr_ln_v(sr_a_ok(r), sr_a_v(r), st, o)

def sr_p_ok(+r: SR_P) -> Bool:
  SR_P{ok, p} = r
  ok

def sr_p_v(+r: SR_P) -> V.Point:
  SR_P{ok, p} = r
  p

def sr_ln_p2(+a: SA, +st: ST, +xs: List<&2, SA>) -> SR_LN:
  match a:
    case SA_ref{+id}:
      +r = sr_pt_ent(st, id)
      sr_ln_p3(sr_p_ok(r), st, xs, sr_p_v(r))
    case _: LN{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64}}

def sr_ln_p(+w: Bool, +a: SA, +st: ST, +xs: List<&2, SA>) -> SR_LN:
  match w:
    case False{}: LN{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_ln_p2(a, st, xs)

def sr_ln_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_LN:
  match w:
    case False{}: LN{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_ln_p(sr_a_ok(r), sr_a_v(r), st, xs)

def sr_line_of(+st: ST, +e: SE) -> SR_LN:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_ln_x(sr_px_ok(r), sr_px_xs(r), st)

def sr_cc_fail() -> SR_CC:
  CC{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 0.0f64}, 0.0f64}

def sr_cc_pos(+w: Bool, +rv: F64, +o: V.Point, +uw: V.Dir, +vw: V.Dir) -> SR_CC:
  match w:
    case False{}: sr_cc_fail()
    case True{}: CC{True{}, o, uw, vw, rv}

def sr_cc_r3(+w: Bool, +rv: F64, +o: V.Point, +uw: V.Dir, +vw: V.Dir) -> SR_CC:
  match w:
    case False{}: sr_cc_fail()
    case True{}: sr_cc_pos(F64.is_lt(0.0f64, rv), rv, o, uw, vw)

def sr_cc_r2(+a: SA, +o: V.Point, +uw: V.Dir, +vw: V.Dir) -> SR_CC:
  +r = sr_num_of(a)
  sr_cc_r3(sr_n_ok(r), sr_n_v(r), o, uw, vw)

def sr_cc_r(+w: Bool, +a: SA, +o: V.Point, +uw: V.Dir, +vw: V.Dir) -> SR_CC:
  match w:
    case False{}: sr_cc_fail()
    case True{}: sr_cc_r2(a, o, uw, vw)

def sr_fr_o(+r: SR_FR) -> V.Point:
  FR{ok, o, u, v} = r
  o

def sr_fr_u(+r: SR_FR) -> V.Dir:
  FR{ok, o, u, v} = r
  u

def sr_fr_v(+r: SR_FR) -> V.Dir:
  FR{ok, o, u, v} = r
  v

def sr_cc_fr(+w: Bool, +fr: SR_FR, +xs: List<&2, SA>) -> SR_CC:
  match w:
    case False{}: sr_cc_fail()
    case True{}:
      +r = sr_nth(xs, 2n)
      sr_cc_r(sr_a_ok(r), sr_a_v(r), sr_fr_o(fr), sr_fr_u(fr), sr_fr_v(fr))

def sr_fr_ok(+r: SR_FR) -> Bool:
  FR{ok, o, u, v} = r
  ok

def sr_fr_fail() -> SR_FR:
  FR{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 0.0f64}}

def sr_ax_o(+r: SR_AX) -> V.Point:
  SR_AX{ok, o, w, u} = r
  o

def sr_ax_w(+r: SR_AX) -> V.Dir:
  SR_AX{ok, o, w, u} = r
  w

def sr_ax_u2(+r: SR_AX) -> V.Dir:
  SR_AX{ok, o, w, u} = r
  u

def sr_frame_v(+w: Bool, +ax: SR_AX, +ww: V.Dir, +u: V.Dir) -> SR_FR:
  match w:
    case False{}: sr_fr_fail()
    case True{}: FR{True{}, sr_ax_o(ax), u,
      BL.cross3(V.dr_x(ww), V.dr_y(ww), V.dr_z(ww), V.dr_x(u), V.dr_y(u), V.dr_z(u))}

def sr_dot3(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64, +bz: F64) -> F64:
  F64.add(F64.mul(ax, bx), F64.add(F64.mul(ay, by), F64.mul(az, bz)))

def sr_gsub(+u: V.Dir, +w: V.Dir) -> V.Dir:
  V.Dr{+ux, +uy, +uz} = u
  V.Dr{+wx, +wy, +wz} = w
  +t = sr_dot3(ux, uy, uz, wx, wy, wz)
  V.Dr{F64.sub(ux, F64.mul(t, wx)), F64.sub(uy, F64.mul(t, wy)), F64.sub(uz, F64.mul(t, wz))}

def sr_frame_u(+w: Bool, +ax: SR_AX, +ww: V.Dir, +u0: V.Dir) -> SR_FR:
  match w:
    case False{}: sr_fr_fail()
    case True{}:
      +u = sr_gsub(u0, ww)
      +r = sr_norm(u)
      sr_frame_v(sr_d_ok(r), ax, ww, sr_d_v(r))

def sr_frame_w(+w: Bool, +ax: SR_AX, +ww: V.Dir) -> SR_FR:
  match w:
    case False{}: sr_fr_fail()
    case True{}:
      +r = sr_norm(sr_ax_u2(ax))
      sr_frame_u(sr_d_ok(r), ax, ww, sr_d_v(r))

def sr_frame_ax(+ax: SR_AX) -> SR_FR:
  +r = sr_norm(sr_ax_w(ax))
  sr_frame_w(sr_d_ok(r), ax, sr_d_v(r))

def sr_cc_frame(+ax: SR_AX, +xs: List<&2, SA>) -> SR_CC:
  +r = sr_frame_ax(ax)
  sr_cc_fr(sr_fr_ok(r), r, xs)

def sr_ax_u(+w: Bool, +o: V.Point, +ax: V.Dir, +u: V.Dir) -> SR_AX:
  match w:
    case False{}: SR_AX{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: SR_AX{True{}, o, ax, u}

def sr_ax_a(+a: SA, +st: ST, +o: V.Point, +ax: V.Dir) -> SR_AX:
  match a:
    case SA_ref{+id}:
      +r = sr_dr_ent(st, id)
      sr_ax_u(sr_d_ok(r), o, ax, sr_d_v(r))
    case _: sr_ax_u(True{}, o, ax, BL.perp_of(V.dr_x(ax), V.dr_y(ax), V.dr_z(ax)))

def sr_ax_ref(+w: Bool, +a: SA, +st: ST, +o: V.Point, +ax: V.Dir) -> SR_AX:
  match w:
    case False{}: SR_AX{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_ax_a(a, st, o, ax)

def sr_ax_ax3(+w: Bool, +st: ST, +xs: List<&2, SA>, +o: V.Point, +ax: V.Dir) -> SR_AX:
  match w:
    case False{}: SR_AX{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +r = sr_nth(xs, 3n)
      sr_ax_ref(sr_a_ok(r), sr_a_v(r), st, o, ax)

def sr_ax_ax2(+a: SA, +st: ST, +xs: List<&2, SA>, +o: V.Point) -> SR_AX:
  match a:
    case SA_ref{+id}:
      +r = sr_dr_ent(st, id)
      sr_ax_ax3(sr_d_ok(r), st, xs, o, sr_d_v(r))
    case _: SR_AX{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 0.0f64}}

def sr_ax_ax(+w: Bool, +a: SA, +st: ST, +xs: List<&2, SA>, +o: V.Point) -> SR_AX:
  match w:
    case False{}: SR_AX{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_ax_ax2(a, st, xs, o)

def sr_ax_loc3(+w: Bool, +st: ST, +xs: List<&2, SA>, +o: V.Point) -> SR_AX:
  match w:
    case False{}: SR_AX{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +r = sr_nth(xs, 2n)
      sr_ax_ax(sr_a_ok(r), sr_a_v(r), st, xs, o)

def sr_ax_loc2(+a: SA, +st: ST, +xs: List<&2, SA>) -> SR_AX:
  match a:
    case SA_ref{+id}:
      +r = sr_pt_ent(st, id)
      sr_ax_loc3(sr_p_ok(r), st, xs, sr_p_v(r))
    case _: SR_AX{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 0.0f64}}

def sr_ax_loc(+w: Bool, +a: SA, +st: ST, +xs: List<&2, SA>) -> SR_AX:
  match w:
    case False{}: SR_AX{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_ax_loc2(a, st, xs)

def sr_ax_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_AX:
  match w:
    case False{}: SR_AX{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_ax_loc(sr_a_ok(r), sr_a_v(r), st, xs)

def sr_ax_e(+e: SE, +st: ST) -> SR_AX:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_ax_x(sr_px_ok(r), sr_px_xs(r), st)

def sr_ax_f(+w: Bool, +st: ST, +pos: Nat) -> SR_AX:
  match w:
    case False{}: SR_AX{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
      V.Dr{0.0f64, 0.0f64, 0.0f64}}
    case True{}: sr_ax_e(sr_ent_at(st, pos), st)

def sr_ax_ent(+st: ST, +id: U64) -> SR_AX:
  +f = sr_find(st, id)
  sr_ax_f(sr_f_ok(f), st, sr_f_pos(f))

def sr_ax_ok(+r: SR_AX) -> Bool:
  SR_AX{ok, o, w, u} = r
  ok

def sr_cc_a3(+w: Bool, +ax: SR_AX, +xs: List<&2, SA>) -> SR_CC:
  match w:
    case False{}: sr_cc_fail()
    case True{}: sr_cc_frame(ax, xs)

def sr_cc_a2(+a: SA, +st: ST, +xs: List<&2, SA>) -> SR_CC:
  match a:
    case SA_ref{+id}:
      +r = sr_ax_ent(st, id)
      sr_cc_a3(sr_ax_ok(r), r, xs)
    case _: sr_cc_fail()

def sr_cc_a(+w: Bool, +a: SA, +st: ST, +xs: List<&2, SA>) -> SR_CC:
  match w:
    case False{}: sr_cc_fail()
    case True{}: sr_cc_a2(a, st, xs)

def sr_cc_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_CC:
  match w:
    case False{}: sr_cc_fail()
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_cc_a(sr_a_ok(r), sr_a_v(r), st, xs)

def sr_circ_of(+st: ST, +e: SE) -> SR_CC:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_cc_x(sr_px_ok(r), sr_px_xs(r), st)

def sr_cc_ok(+r: SR_CC) -> Bool:
  CC{ok, c, u, v, r} = r
  ok

def sr_cc_c(+r: SR_CC) -> V.Point:
  CC{ok, c, u, v, r} = r
  c

def sr_cc_u2(+r: SR_CC) -> V.Dir:
  CC{ok, c, u, v, r} = r
  u

def sr_cc_v(+r: SR_CC) -> V.Dir:
  CC{ok, c, u, v, r} = r
  v

def sr_cc_rv(+r: SR_CC) -> F64:
  CC{ok, c, u, v, r} = r
  r

def sr_tm_ok(+r: SR_TM) -> Bool:
  TM{ok, basis, sense} = r
  ok

def sr_tm_basis(+r: SR_TM) -> U64:
  TM{ok, basis, sense} = r
  basis

def sr_tm_sense(+r: SR_TM) -> Bool:
  TM{ok, basis, sense} = r
  sense

def sr_tm_fail() -> SR_TM:
  TM{False{}, 0u64, True{}}

def sr_b_ok(+r: SR_B) -> Bool:
  SR_B{ok, b} = r
  ok

def sr_b_v(+r: SR_B) -> Bool:
  SR_B{ok, b} = r
  b

def sr_en_f(+f: Bool) -> SR_B:
  match f:
    case True{}: SR_B{True{}, False{}}
    case False{}: SR_B{False{}, False{}}

def sr_en_b(+t: Bool, +f: Bool) -> SR_B:
  match t:
    case True{}: SR_B{True{}, True{}}
    case False{}: sr_en_f(f)

def sr_en_of(+a: SA) -> SR_B:
  match a:
    case SA_en{+s}: sr_en_b(String.eq(s, "T"), String.eq(s, "F"))
    case _: SR_B{False{}, False{}}

def sr_tm_s2(+w: Bool, +sense: Bool, +basis: U64) -> SR_TM:
  match w:
    case False{}: sr_tm_fail()
    case True{}: TM{True{}, basis, sense}

def sr_tm_s(+w: Bool, +a: SA, +basis: U64) -> SR_TM:
  match w:
    case False{}: sr_tm_fail()
    case True{}:
      +r = sr_en_of(a)
      sr_tm_s2(sr_b_ok(r), sr_b_v(r), basis)

def sr_tm_b2(+a: SA, +xs: List<&2, SA>) -> SR_TM:
  match a:
    case SA_ref{+id}:
      +r = sr_nth(xs, 4n)
      sr_tm_s(sr_a_ok(r), sr_a_v(r), id)
    case _: sr_tm_fail()

def sr_tm_b(+w: Bool, +a: SA, +xs: List<&2, SA>) -> SR_TM:
  match w:
    case False{}: sr_tm_fail()
    case True{}: sr_tm_b2(a, xs)

def sr_tm_x(+w: Bool, +xs: List<&2, SA>) -> SR_TM:
  match w:
    case False{}: sr_tm_fail()
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_tm_b(sr_a_ok(r), sr_a_v(r), xs)

def sr_trim_of(+e: SE) -> SR_TM:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_tm_x(sr_px_ok(r), sr_px_xs(r))

def sr_wrap_b2(+a: SA) -> SR_TM:
  match a:
    case SA_ref{+id}: TM{True{}, id, True{}}
    case _: sr_tm_fail()

def sr_wrap_b(+w: Bool, +a: SA) -> SR_TM:
  match w:
    case False{}: sr_tm_fail()
    case True{}: sr_wrap_b2(a)

def sr_wrap_x(+w: Bool, +xs: List<&2, SA>) -> SR_TM:
  match w:
    case False{}: sr_tm_fail()
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_wrap_b(sr_a_ok(r), sr_a_v(r))

def sr_wrap_of(+e: SE) -> SR_TM:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_wrap_x(sr_px_ok(r), sr_px_xs(r))

def sr_xnor_t(+b: Bool) -> Bool:
  match b:
    case True{}: True{}
    case False{}: False{}

def sr_xnor_f(+b: Bool) -> Bool:
  match b:
    case True{}: False{}
    case False{}: True{}

def sr_xnor(+a: Bool, +b: Bool) -> Bool:
  match a:
    case True{}: sr_xnor_t(b)
    case False{}: sr_xnor_f(b)

def sr_padd(+o: V.Point, +t: F64, +d: V.Dir) -> V.Point:
  V.Pt{+ox, +oy, +oz} = o
  V.Dr{+dx, +dy, +dz} = d
  V.Pt{F64.add(ox, F64.mul(t, dx)), F64.add(oy, F64.mul(t, dy)), F64.add(oz, F64.mul(t, dz))}

def sr_dneg(+d: V.Dir) -> V.Dir:
  V.Dr{+x, +y, +z} = d
  V.Dr{F64.neg(x), F64.neg(y), F64.neg(z)}

def sr_pt_eq(+a: V.Point, +b: V.Point) -> Bool:
  V.Pt{+ax, +ay, +az} = a
  V.Pt{+bx, +by, +bz} = b
  Bool.and(F64.is_eq(ax, bx), Bool.and(F64.is_eq(ay, by), F64.is_eq(az, bz)))

def sr_line_cv_se(+esense: Bool, +o: V.Point, +d: V.Dir, +lo: F64, +hi: F64) -> SR_C:
  match esense:
    case True{}: SR_C{True{}, G.GV_ln{G.Ln{o, d}}, lo, hi}
    case False{}: SR_C{True{}, G.GV_ln{G.Ln{sr_padd(o, hi, d), sr_dneg(d)}}, 0.0f64,
      F64.sub(hi, lo)}

def sr_line_cv_ord(+w: Bool, +esense: Bool, +o: V.Point, +d: V.Dir, +lo: F64, +hi: F64) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_line_cv_se(esense, o, d, lo, hi)

def sr_line_cv2(+w: Bool, +o: V.Point, +d: V.Dir, +v0: V.Point, +v1: V.Point,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      V.Pt{+ox, +oy, +oz} = o
      V.Dr{+dx, +dy, +dz} = d
      V.Pt{+x0, +y0, +z0} = v0
      V.Pt{+x1, +y1, +z1} = v1
      +lo = sr_dot3(F64.sub(x0, ox), F64.sub(y0, oy), F64.sub(z0, oz), dx, dy, dz)
      +hi = sr_dot3(F64.sub(x1, ox), F64.sub(y1, oy), F64.sub(z1, oz), dx, dy, dz)
      sr_line_cv_ord(Bool.and(T.is_finite(lo), Bool.and(T.is_finite(hi), F64.is_lt(lo, hi))),
        esense, o, d, lo, hi)

def sr_line_cv(+st: ST, +e: SE, +v0: V.Point, +v1: V.Point, +esense: Bool) -> SR_C:
  +r = sr_line_of(st, e)
  sr_line_cv2(sr_ln_ok(r), sr_ln_o(r), sr_ln_d(r), v0, v1, esense)

def sr_clamp11(+x: F64) -> F64:
  Bool.pick(F64, F64.is_lt(x, F64.neg(1.0f64)), F64.neg(1.0f64),
    Bool.pick(F64, F64.is_lt(1.0f64, x), 1.0f64, x))

def sr_circ_tan4(+xc: F64, +y: F64) -> SR_N:
  +ch = F64.sqrt(F64.div(F64.add(1.0f64, xc), 2.0f64))
  +sh = F64.sqrt(F64.div(F64.sub(1.0f64, xc), 2.0f64))
  +sg = Bool.pick(F64, F64.is_lt(y, 0.0f64), F64.neg(sh), sh)
  +t = F64.div(sg, F64.add(1.0f64, ch))
  SR_N{T.is_finite(t), t}

def sr_circ_inv(+w: Bool, +x: F64, +y: F64) -> SR_N:
  match w:
    case False{}: SR_N{False{}, 0.0f64}
    case True{}: sr_circ_tan4(sr_clamp11(x), y)

def sr_circ_t(+p: V.Point, +c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64) -> SR_N:
  V.Pt{+px, +py, +pz} = p
  V.Pt{+cx, +cy, +cz} = c
  V.Dr{+ux, +uy, +uz} = u
  V.Dr{+vx, +vy, +vz} = v
  +x = F64.div(sr_dot3(F64.sub(px, cx), F64.sub(py, cy), F64.sub(pz, cz), ux, uy, uz), r)
  +y = F64.div(sr_dot3(F64.sub(px, cx), F64.sub(py, cy), F64.sub(pz, cz), vx, vy, vz), r)
  sr_circ_inv(Bool.and(T.is_finite(x), T.is_finite(y)), x, y)

def sr_circ_full_se(+esense: Bool, +c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64) -> SR_C:
  match esense:
    case True{}: SR_C{True{}, G.GV_cc{G.Cc{c, u, v, r}}, F64.neg(1.0f64), 1.0f64}
    case False{}: SR_C{True{}, G.GV_cc{G.Cc{c, u, sr_dneg(v), r}}, F64.neg(1.0f64), 1.0f64}

def sr_circ_full_v(+w: Bool, +esense: Bool, +c: V.Point, +u: V.Dir, +ww: V.Dir,
    +r: F64) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +v = BL.cross3(V.dr_x(ww), V.dr_y(ww), V.dr_z(ww), V.dr_x(u), V.dr_y(u), V.dr_z(u))
      sr_circ_full_se(esense, c, u, v, r)

def sr_circ_full(+esense: Bool, +c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64,
    +p: V.Point) -> SR_C:
  V.Pt{+cx, +cy, +cz} = c
  V.Pt{+px, +py, +pz} = p
  +ww = BL.cross3(V.dr_x(u), V.dr_y(u), V.dr_z(u), V.dr_x(v), V.dr_y(v), V.dr_z(v))
  +rn = sr_norm(V.Dr{F64.sub(cx, px), F64.sub(cy, py), F64.sub(cz, pz)})
  sr_circ_full_v(sr_d_ok(rn), esense, c, sr_d_v(rn), ww, r)

def sr_circ_tr2(+w: Bool, +c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64, +t0: F64,
    +t1: F64) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: SR_C{True{}, G.GV_cc{G.Cc{c, u, v, r}}, t0, t1}

def sr_circ_tr3(+w: Bool, +c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64, +t0: F64,
    +t1: F64) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: SR_C{True{}, G.GV_cc{G.Cc{c, u, sr_dneg(v), r}}, F64.neg(t0), F64.neg(t1)}

def sr_circ_tr(+esense: Bool, +c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64, +t0: F64,
    +t1: F64) -> SR_C:
  match esense:
    case True{}: sr_circ_tr2(F64.is_lt(t0, t1), c, u, v, r, t0, t1)
    case False{}: sr_circ_tr3(F64.is_lt(t1, t0), c, u, v, r, t0, t1)

def sr_circ_tm(+w: Bool, +esense: Bool, +c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64, +t0: F64,
    +t1: F64) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_circ_tr(esense, c, u, v, r, t0, t1)

def sr_circ_cl(+closed: Bool, +esense: Bool, +c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64,
    +v0: V.Point, +v1: V.Point) -> SR_C:
  match closed:
    case True{}: sr_circ_full(esense, c, u, v, r, v0)
    case False{}:
      +r0 = sr_circ_t(v0, c, u, v, r)
      +r1 = sr_circ_t(v1, c, u, v, r)
      sr_circ_tm(Bool.and(sr_n_ok(r0), sr_n_ok(r1)), esense, c, u, v, r, sr_n_v(r0), sr_n_v(r1))

def sr_circ_cv2(+w: Bool, +cc: SR_CC, +v0: V.Point, +v1: V.Point, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_circ_cl(sr_pt_eq(v0, v1), esense, sr_cc_c(cc), sr_cc_u2(cc), sr_cc_v(cc),
      sr_cc_rv(cc), v0, v1)

def sr_circ_cv(+st: ST, +e: SE, +v0: V.Point, +v1: V.Point, +esense: Bool) -> SR_C:
  +r = sr_circ_of(st, e)
  sr_circ_cv2(sr_cc_ok(r), r, v0, v1, esense)

def sr_ul_ok(+r: SR_UL) -> Bool:
  UL{ok, xs} = r
  ok

def sr_ul_xs(+r: SR_UL) -> List<&2, U64>:
  UL{ok, xs} = r
  xs

def sr_nl_ok(+r: SR_NL) -> Bool:
  NL{ok, xs} = r
  ok

def sr_nl_xs(+r: SR_NL) -> List<&2, F64>:
  NL{ok, xs} = r
  xs

def sr_uu_ok(+r: SR_UU) -> Bool:
  UU{ok, v} = r
  ok

def sr_uu_v(+r: SR_UU) -> U64:
  UU{ok, v} = r
  v

def sr_ul_acc(+ok: Bool, +id: U64, +acc: List<&2, U64>) -> List<&2, U64>:
  match ok:
    case True{}: id <> acc
    case False{}: []

def sr_refs_go(xs: List<&2, SA>, +acc: List<&2, U64>, +ok: Bool) -> SR_UL:
  match xs:
    case []: UL{ok, List.reverse(&2, U64, acc)}
    case h <> t:
      match h:
        case SA_ref{+id}: sr_refs_go(t, sr_ul_acc(ok, id, acc), ok)
        case _: sr_refs_go(t, [], False{})

def sr_refs_of(+a: SA) -> SR_UL:
  match a:
    case SA_ls{+xs}: sr_refs_go(xs, [], True{})
    case _: UL{False{}, []}

def sr_nl_acc2(+w: Bool, +v: F64, +acc: List<&2, F64>) -> List<&2, F64>:
  match w:
    case True{}: v <> acc
    case False{}: []

def sr_nl_acc(+oko: Bool, +w: Bool, +v: F64, +acc: List<&2, F64>) -> List<&2, F64>:
  match oko:
    case False{}: []
    case True{}: sr_nl_acc2(w, v, acc)

def sr_nums_go(xs: List<&2, SA>, +acc: List<&2, F64>, +ok: Bool) -> SR_NL:
  match xs:
    case []: NL{ok, List.reverse(&2, F64, acc)}
    case +a <> t:
      +r = sr_num_of(a)
      sr_nums_go(t, sr_nl_acc(ok, sr_n_ok(r), sr_n_v(r), acc), Bool.and(ok, sr_n_ok(r)))

def sr_nums_of(+a: SA) -> SR_NL:
  match a:
    case SA_ls{+xs}: sr_nums_go(xs, [], True{})
    case _: NL{False{}, []}

def sr_unth_go(xs: List<&2, U64>, +i: Nat) -> SR_UU:
  match xs:
    case []: UU{False{}, 0u64}
    case h <> t:
      match i:
        case 0n: UU{True{}, h}
        case 1n+j: sr_unth_go(t, j)

def sr_unth(xs: List<&2, U64>, +i: Nat) -> SR_UU:
  sr_unth_go(xs, i)

def sr_fnth_go(xs: List<&2, F64>, +i: Nat) -> SR_N:
  match xs:
    case []: SR_N{False{}, 0.0f64}
    case h <> t:
      match i:
        case 0n: SR_N{True{}, h}
        case 1n+j: sr_fnth_go(t, j)

def sr_fnth(xs: List<&2, F64>, +i: Nat) -> SR_N:
  sr_fnth_go(xs, i)

def sr_is_33(+a: F64, +b: F64) -> Bool:
  Bool.and(F64.is_eq(a, 3.0f64), F64.is_eq(b, 3.0f64))

def sr_is_44(+a: F64, +b: F64) -> Bool:
  Bool.and(F64.is_eq(a, 4.0f64), F64.is_eq(b, 4.0f64))

def sr_is_01(+a: F64, +b: F64) -> Bool:
  Bool.and(F64.is_eq(a, 0.0f64), F64.is_eq(b, 1.0f64))

def sr_rat_se(+esense: Bool, +p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64, +w1: F64,
    +w2: F64) -> SR_C:
  match esense:
    case True{}: SR_C{True{}, G.GV_rq{G.Rq{p0, p1, p2, w0, w1, w2}}, 0.0f64, 1.0f64}
    case False{}: SR_C{True{}, G.GV_rq{G.Rq{p2, p1, p0, w2, w1, w0}}, 0.0f64, 1.0f64}

def sr_rat_done(+w: Bool, +p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64, +w1: F64,
    +w2: F64, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_se(esense, p0, p1, p2, w0, w1, w2)

def sr_rat_kk(+w: Bool, +ka: F64, +kb: F64, +p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64,
    +w1: F64, +w2: F64, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_done(sr_is_01(ka, kb), p0, p1, p2, w0, w1, w2, esense)

def sr_rat_kn4(+w: Bool, +xs: List<&2, F64>, +p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64,
    +w1: F64, +w2: F64, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r0 = sr_fnth(xs, 0n)
      +r1 = sr_fnth(xs, 1n)
      sr_rat_kk(Bool.and(sr_n_ok(r0), sr_n_ok(r1)), sr_n_v(r0), sr_n_v(r1), p0, p1, p2, w0, w1,
        w2, esense)

def sr_rat_kn3(+w: Bool, +xs: List<&2, F64>, +p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64,
    +w1: F64, +w2: F64, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_kn4(Nat.is_eq(List.length(&2, F64, xs), 2n), xs, p0, p1, p2, w0, w1, w2,
      esense)

def sr_rat_kn2(+w: Bool, +a: SA, +p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64, +w1: F64,
    +w2: F64, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_nums_of(a)
      sr_rat_kn3(sr_nl_ok(r), sr_nl_xs(r), p0, p1, p2, w0, w1, w2, esense)

def sr_rat_kn(+kx: List<&2, SA>, +p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64, +w1: F64,
    +w2: F64, +esense: Bool) -> SR_C:
  +r = sr_nth(kx, 1n)
  sr_rat_kn2(sr_a_ok(r), sr_a_v(r), p0, p1, p2, w0, w1, w2, esense)

def sr_rat_mm2(+w: Bool, +kx: List<&2, SA>, +p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64,
    +w1: F64, +w2: F64, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_kn(kx, p0, p1, p2, w0, w1, w2, esense)

def sr_rat_mm(+w: Bool, +ma: F64, +mb: F64, +kx: List<&2, SA>, +p0: V.Point, +p1: V.Point,
    +p2: V.Point, +w0: F64, +w1: F64, +w2: F64, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_mm2(sr_is_33(ma, mb), kx, p0, p1, p2, w0, w1, w2, esense)

def sr_rat_mu4(+w: Bool, +xs: List<&2, F64>, +kx: List<&2, SA>, +p0: V.Point, +p1: V.Point,
    +p2: V.Point, +w0: F64, +w1: F64, +w2: F64, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r0 = sr_fnth(xs, 0n)
      +r1 = sr_fnth(xs, 1n)
      sr_rat_mm(Bool.and(sr_n_ok(r0), sr_n_ok(r1)), sr_n_v(r0), sr_n_v(r1), kx, p0, p1, p2, w0,
        w1, w2, esense)

def sr_rat_mu3(+w: Bool, +xs: List<&2, F64>, +kx: List<&2, SA>, +p0: V.Point, +p1: V.Point,
    +p2: V.Point, +w0: F64, +w1: F64, +w2: F64, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_mu4(Nat.is_eq(List.length(&2, F64, xs), 2n), xs, kx, p0, p1, p2, w0, w1,
      w2, esense)

def sr_rat_mu2(+w: Bool, +a: SA, +kx: List<&2, SA>, +p0: V.Point, +p1: V.Point, +p2: V.Point,
    +w0: F64, +w1: F64, +w2: F64, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_nums_of(a)
      sr_rat_mu3(sr_nl_ok(r), sr_nl_xs(r), kx, p0, p1, p2, w0, w1, w2, esense)

def sr_rat_mu(+kx: List<&2, SA>, +p0: V.Point, +p1: V.Point, +p2: V.Point, +w0: F64, +w1: F64,
    +w2: F64, +esense: Bool) -> SR_C:
  +r = sr_nth(kx, 0n)
  sr_rat_mu2(sr_a_ok(r), sr_a_v(r), kx, p0, p1, p2, w0, w1, w2, esense)

def sr_rat_ww(+w: Bool, +w0: F64, +w1: F64, +w2: F64, +st: ST, +p0: V.Point, +p1: V.Point,
    +p2: V.Point, +kx: List<&2, SA>, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_mu(kx, p0, p1, p2, w0, w1, w2, esense)

def sr_rat_w5(+w: Bool, +w0: F64, +w1: F64, +w2: F64, +st: ST, +p0: V.Point, +p1: V.Point,
    +p2: V.Point, +kx: List<&2, SA>, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_ww(Bool.and(F64.is_lt(0.0f64, w0),
      Bool.and(F64.is_lt(0.0f64, w1), F64.is_lt(0.0f64, w2))), w0, w1, w2, st, p0, p1, p2, kx,
      esense)

def sr_rat_w4(+w: Bool, +xs: List<&2, F64>, +st: ST, +p0: V.Point, +p1: V.Point, +p2: V.Point,
    +kx: List<&2, SA>, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r0 = sr_fnth(xs, 0n)
      +r1 = sr_fnth(xs, 1n)
      +r2 = sr_fnth(xs, 2n)
      sr_rat_w5(Bool.and(sr_n_ok(r0), Bool.and(sr_n_ok(r1), sr_n_ok(r2))), sr_n_v(r0), sr_n_v(r1),
        sr_n_v(r2), st, p0, p1, p2, kx, esense)

def sr_rat_w3(+w: Bool, +xs: List<&2, F64>, +st: ST, +p0: V.Point, +p1: V.Point, +p2: V.Point,
    +kx: List<&2, SA>, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_w4(Nat.is_eq(List.length(&2, F64, xs), 3n), xs, st, p0, p1, p2, kx,
      esense)

def sr_rat_w2(+w: Bool, +a: SA, +st: ST, +p0: V.Point, +p1: V.Point, +p2: V.Point,
    +kx: List<&2, SA>, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_nums_of(a)
      sr_rat_w3(sr_nl_ok(r), sr_nl_xs(r), st, p0, p1, p2, kx, esense)

def sr_rat_w(+rx: List<&2, SA>, +st: ST, +p0: V.Point, +p1: V.Point, +p2: V.Point,
    +kx: List<&2, SA>, +esense: Bool) -> SR_C:
  +r = sr_nth(rx, 0n)
  sr_rat_w2(sr_a_ok(r), sr_a_v(r), st, p0, p1, p2, kx, esense)

def sr_rat_q3(+w: Bool, +p0: V.Point, +p1: V.Point, +p2: V.Point, +st: ST, +rx: List<&2, SA>,
    +kx: List<&2, SA>, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_w(rx, st, p0, p1, p2, kx, esense)

def sr_rat_pl7(+w: Bool, +i0: U64, +i1: U64, +i2: U64, +st: ST, +rx: List<&2, SA>,
    +kx: List<&2, SA>, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +p0 = sr_pt_ent(st, i0)
      +p1 = sr_pt_ent(st, i1)
      +p2 = sr_pt_ent(st, i2)
      sr_rat_q3(Bool.and(sr_p_ok(p0), Bool.and(sr_p_ok(p1), sr_p_ok(p2))), sr_p_v(p0), sr_p_v(p1),
        sr_p_v(p2), st, rx, kx, esense)

def sr_rat_pl6(+w: Bool, +xs: List<&2, U64>, +st: ST, +rx: List<&2, SA>, +kx: List<&2, SA>,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r0 = sr_unth(xs, 0n)
      +r1 = sr_unth(xs, 1n)
      +r2 = sr_unth(xs, 2n)
      sr_rat_pl7(Bool.and(sr_uu_ok(r0), Bool.and(sr_uu_ok(r1), sr_uu_ok(r2))), sr_uu_v(r0),
        sr_uu_v(r1), sr_uu_v(r2), st, rx, kx, esense)

def sr_rat_pl5(+w: Bool, +xs: List<&2, U64>, +st: ST, +rx: List<&2, SA>, +kx: List<&2, SA>,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_pl6(Nat.is_eq(List.length(&2, U64, xs), 3n), xs, st, rx, kx, esense)

def sr_rat_pl(+w: Bool, +a: SA, +st: ST, +rx: List<&2, SA>, +kx: List<&2, SA>,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_refs_of(a)
      sr_rat_pl5(sr_ul_ok(r), sr_ul_xs(r), st, rx, kx, esense)

def sr_rat_poles(+bx: List<&2, SA>, +st: ST, +rx: List<&2, SA>, +kx: List<&2, SA>,
    +esense: Bool) -> SR_C:
  +r = sr_nth(bx, 1n)
  sr_rat_pl(sr_a_ok(r), sr_a_v(r), st, rx, kx, esense)

def sr_rat_deg4(+w: Bool, +bx: List<&2, SA>, +st: ST, +rx: List<&2, SA>, +kx: List<&2, SA>,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_poles(bx, st, rx, kx, esense)

def sr_rat_deg3(+w: Bool, +dv: F64, +bx: List<&2, SA>, +st: ST, +rx: List<&2, SA>,
    +kx: List<&2, SA>, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_rat_deg4(F64.is_eq(dv, 2.0f64), bx, st, rx, kx, esense)

def sr_rat_deg2(+w: Bool, +a: SA, +bx: List<&2, SA>, +st: ST, +rx: List<&2, SA>,
    +kx: List<&2, SA>, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_num_of(a)
      sr_rat_deg3(sr_n_ok(r), sr_n_v(r), bx, st, rx, kx, esense)

def sr_rat_deg(+bx: List<&2, SA>, +st: ST, +rx: List<&2, SA>, +kx: List<&2, SA>,
    +esense: Bool) -> SR_C:
  +r = sr_nth(bx, 0n)
  sr_rat_deg2(sr_a_ok(r), sr_a_v(r), bx, st, rx, kx, esense)

def sr_rat_ps3(+wk: Bool, +st: ST, +bsc: SR_PX, +rto: SR_PX, +kno: SR_PX, +esense: Bool) -> SR_C:
  match wk:
    case False{}: sr_c_fail()
    case True{}: sr_rat_deg(sr_px_xs(bsc), st, sr_px_xs(rto), sr_px_xs(kno), esense)

def sr_rat_ps2(+wr: Bool, +wk: Bool, +st: ST, +bsc: SR_PX, +rto: SR_PX, +kno: SR_PX,
    +esense: Bool) -> SR_C:
  match wr:
    case False{}: sr_c_fail()
    case True{}: sr_rat_ps3(wk, st, bsc, rto, kno, esense)

def sr_rat_ps(+wb: Bool, +wr: Bool, +wk: Bool, +st: ST, +bsc: SR_PX, +rto: SR_PX, +kno: SR_PX,
    +esense: Bool) -> SR_C:
  match wb:
    case False{}: sr_c_fail()
    case True{}: sr_rat_ps2(wr, wk, st, bsc, rto, kno, esense)

def sr_part_end(+st: SR_PF) -> SR_PX:
  match st:
    case PF{+found, +xs}: SR_PX{found, xs}

def sr_part_m2(+eq: Bool, +args: List<&2, SA>, +xs: List<&2, SA>) -> SR_PF:
  match eq:
    case True{}: PF{True{}, args}
    case False{}: PF{False{}, xs}

def sr_part_m(+found: Bool, +eq: Bool, +args: List<&2, SA>, +xs: List<&2, SA>) -> SR_PF:
  match found:
    case True{}: PF{True{}, xs}
    case False{}: sr_part_m2(eq, args, xs)

def sr_part_nx(+h: SPt, +nm: String, +st: SR_PF) -> SR_PF:
  match st:
    case PF{+found, +xs}: sr_part_m(found, String.eq(sr_spt_nm(h), nm), sr_spt_args(h), xs)

def sr_part_go(ps: List<&2, SPt>, +nm: String, +st: SR_PF) -> SR_PX:
  match ps:
    case []: sr_part_end(st)
    case +h <> t: sr_part_go(t, nm, sr_part_nx(h, nm, st))

def sr_part(ps: List<&2, SPt>, +nm: String) -> SR_PX:
  sr_part_go(ps, nm, PF{False{}, []})

def sr_rat_of(+st: ST, +e: SE, +esense: Bool) -> SR_C:
  SE{+id, +ps} = e
  +bsc = sr_part(ps, "B_SPLINE_CURVE")
  +rto = sr_part(ps, "RATIONAL_B_SPLINE_CURVE")
  +kno = sr_part(ps, "B_SPLINE_CURVE_WITH_KNOTS")
  sr_rat_ps(sr_px_ok(bsc), sr_px_ok(rto), sr_px_ok(kno), st, bsc, rto, kno, esense)

def sr_bez_se(+esense: Bool, +p0: V.Point, +p1: V.Point, +p2: V.Point, +p3: V.Point) -> SR_C:
  match esense:
    case True{}: SR_C{True{}, G.GV_bz{G.Bz{p0, p1, p2, p3}}, 0.0f64, 1.0f64}
    case False{}: SR_C{True{}, G.GV_bz{G.Bz{p3, p2, p1, p0}}, 0.0f64, 1.0f64}

def sr_bez_done(+w: Bool, +p0: V.Point, +p1: V.Point, +p2: V.Point, +p3: V.Point,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_bez_se(esense, p0, p1, p2, p3)

def sr_bez_kk(+w: Bool, +ka: F64, +kb: F64, +p0: V.Point, +p1: V.Point, +p2: V.Point,
    +p3: V.Point, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_bez_done(sr_is_01(ka, kb), p0, p1, p2, p3, esense)

def sr_bez_kn4(+w: Bool, +xs: List<&2, F64>, +p0: V.Point, +p1: V.Point, +p2: V.Point,
    +p3: V.Point, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r0 = sr_fnth(xs, 0n)
      +r1 = sr_fnth(xs, 1n)
      sr_bez_kk(Bool.and(sr_n_ok(r0), sr_n_ok(r1)), sr_n_v(r0), sr_n_v(r1), p0, p1, p2, p3,
        esense)

def sr_bez_kn3(+w: Bool, +xs: List<&2, F64>, +p0: V.Point, +p1: V.Point, +p2: V.Point,
    +p3: V.Point, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_bez_kn4(Nat.is_eq(List.length(&2, F64, xs), 2n), xs, p0, p1, p2, p3, esense)

def sr_bez_kn2(+w: Bool, +a: SA, +p0: V.Point, +p1: V.Point, +p2: V.Point, +p3: V.Point,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_nums_of(a)
      sr_bez_kn3(sr_nl_ok(r), sr_nl_xs(r), p0, p1, p2, p3, esense)

def sr_bez_mm2(+w: Bool, +kx: List<&2, SA>, +ki: Nat, +p0: V.Point, +p1: V.Point, +p2: V.Point,
    +p3: V.Point, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_nth(kx, Nat.add(ki, 1n))
      sr_bez_kn2(sr_a_ok(r), sr_a_v(r), p0, p1, p2, p3, esense)

def sr_bez_mm(+w: Bool, +ma: F64, +mb: F64, +kx: List<&2, SA>, +ki: Nat, +p0: V.Point,
    +p1: V.Point, +p2: V.Point, +p3: V.Point, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_bez_mm2(sr_is_44(ma, mb), kx, ki, p0, p1, p2, p3, esense)

def sr_bez_mu4(+w: Bool, +xs: List<&2, F64>, +kx: List<&2, SA>, +ki: Nat, +p0: V.Point,
    +p1: V.Point, +p2: V.Point, +p3: V.Point, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r0 = sr_fnth(xs, 0n)
      +r1 = sr_fnth(xs, 1n)
      sr_bez_mm(Bool.and(sr_n_ok(r0), sr_n_ok(r1)), sr_n_v(r0), sr_n_v(r1), kx, ki, p0, p1, p2,
        p3, esense)

def sr_bez_mu3(+w: Bool, +xs: List<&2, F64>, +kx: List<&2, SA>, +ki: Nat, +p0: V.Point,
    +p1: V.Point, +p2: V.Point, +p3: V.Point, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_bez_mu4(Nat.is_eq(List.length(&2, F64, xs), 2n), xs, kx, ki, p0, p1, p2,
      p3, esense)

def sr_bez_mu2(+w: Bool, +a: SA, +kx: List<&2, SA>, +ki: Nat, +p0: V.Point, +p1: V.Point,
    +p2: V.Point, +p3: V.Point, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_nums_of(a)
      sr_bez_mu3(sr_nl_ok(r), sr_nl_xs(r), kx, ki, p0, p1, p2, p3, esense)

def sr_bez_mu(+kx: List<&2, SA>, +ki: Nat, +p0: V.Point, +p1: V.Point, +p2: V.Point,
    +p3: V.Point, +esense: Bool) -> SR_C:
  +r = sr_nth(kx, ki)
  sr_bez_mu2(sr_a_ok(r), sr_a_v(r), kx, ki, p0, p1, p2, p3, esense)

def sr_bez_q3(+w: Bool, +p0: V.Point, +p1: V.Point, +p2: V.Point, +p3: V.Point,
    +kx: List<&2, SA>, +ki: Nat, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_bez_mu(kx, ki, p0, p1, p2, p3, esense)

def sr_bez_q2(+w: Bool, +i3: U64, +st: ST, +i0: U64, +i1: U64, +i2: U64, +kx: List<&2, SA>,
    +ki: Nat, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +p0 = sr_pt_ent(st, i0)
      +p1 = sr_pt_ent(st, i1)
      +p2 = sr_pt_ent(st, i2)
      +p3 = sr_pt_ent(st, i3)
      sr_bez_q3(Bool.and(sr_p_ok(p0), Bool.and(sr_p_ok(p1), Bool.and(sr_p_ok(p2), sr_p_ok(p3)))),
        sr_p_v(p0), sr_p_v(p1), sr_p_v(p2), sr_p_v(p3), kx, ki, esense)

def sr_bez_q1(+w: Bool, +i2: U64, +xs: List<&2, U64>, +st: ST, +i0: U64, +i1: U64,
    +kx: List<&2, SA>, +ki: Nat, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r3 = sr_unth(xs, 3n)
      sr_bez_q2(sr_uu_ok(r3), sr_uu_v(r3), st, i0, i1, i2, kx, ki, esense)

def sr_bez_q0(+w: Bool, +i1: U64, +xs: List<&2, U64>, +st: ST, +i0: U64, +kx: List<&2, SA>,
    +ki: Nat, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r2 = sr_unth(xs, 2n)
      sr_bez_q1(sr_uu_ok(r2), sr_uu_v(r2), xs, st, i0, i1, kx, ki, esense)

def sr_bez_pl(+w: Bool, +i0: U64, +xs: List<&2, U64>, +st: ST, +kx: List<&2, SA>, +ki: Nat,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r1 = sr_unth(xs, 1n)
      sr_bez_q0(sr_uu_ok(r1), sr_uu_v(r1), xs, st, i0, kx, ki, esense)

def sr_bez_pl3(+w: Bool, +xs: List<&2, U64>, +st: ST, +kx: List<&2, SA>, +ki: Nat,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r0 = sr_unth(xs, 0n)
      sr_bez_pl(sr_uu_ok(r0), sr_uu_v(r0), xs, st, kx, ki, esense)

def sr_bez_pl2(+w: Bool, +xs: List<&2, U64>, +st: ST, +kx: List<&2, SA>, +ki: Nat,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_bez_pl3(Nat.is_eq(List.length(&2, U64, xs), 4n), xs, st, kx, ki, esense)

def sr_bez_poles(+w: Bool, +a: SA, +st: ST, +kx: List<&2, SA>, +ki: Nat, +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_refs_of(a)
      sr_bez_pl2(sr_ul_ok(r), sr_ul_xs(r), st, kx, ki, esense)

def sr_bez_deg2(+w: Bool, +bx: List<&2, SA>, +st: ST, +kx: List<&2, SA>, +ki: Nat,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_nth(bx, 1n)
      sr_bez_poles(sr_a_ok(r), sr_a_v(r), st, kx, ki, esense)

def sr_bez_deg(+w: Bool, +dv: F64, +bx: List<&2, SA>, +st: ST, +kx: List<&2, SA>, +ki: Nat,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}: sr_bez_deg2(F64.is_eq(dv, 3.0f64), bx, st, kx, ki, esense)

def sr_bez_bx2(+w: Bool, +a: SA, +bx: List<&2, SA>, +st: ST, +kx: List<&2, SA>, +ki: Nat,
    +esense: Bool) -> SR_C:
  match w:
    case False{}: sr_c_fail()
    case True{}:
      +r = sr_num_of(a)
      sr_bez_deg(sr_n_ok(r), sr_n_v(r), bx, st, kx, ki, esense)

def sr_bez_bx(+bx: List<&2, SA>, +st: ST, +kx: List<&2, SA>, +ki: Nat, +esense: Bool) -> SR_C:
  +r = sr_nth(bx, 0n)
  sr_bez_bx2(sr_a_ok(r), sr_a_v(r), bx, st, kx, ki, esense)

def sr_bx_tail(+bx: List<&2, SA>) -> List<&2, SA>:
  match bx:
    case []: []
    case _ <> t: t

def sr_bez_cx(+cx: Bool, +st: ST, +bsc: SR_PX, +kno: SR_PX, +esense: Bool) -> SR_C:
  match cx:
    case True{}: sr_bez_bx(sr_px_xs(bsc), st, sr_px_xs(kno), 0n, esense)
    case False{}:
      +kx = sr_bx_tail(sr_px_xs(kno))
      sr_bez_bx(kx, st, kx, 5n, esense)

def sr_bez_cx3(+wk: Bool, +st: ST, +bsc: SR_PX, +kno: SR_PX, +esense: Bool) -> SR_C:
  match wk:
    case False{}: sr_c_fail()
    case True{}: sr_bez_cx(False{}, st, bsc, kno, esense)

def sr_bez_cx2(+wb: Bool, +wk: Bool, +st: ST, +bsc: SR_PX, +kno: SR_PX, +esense: Bool) -> SR_C:
  match wb:
    case True{}: sr_bez_cx(True{}, st, bsc, kno, esense)
    case False{}: sr_bez_cx3(wk, st, bsc, kno, esense)

def sr_bez_of(+st: ST, +e: SE, +esense: Bool) -> SR_C:
  SE{+id, +ps} = e
  +bsc = sr_part(ps, "B_SPLINE_CURVE")
  +kno = sr_part(ps, "B_SPLINE_CURVE_WITH_KNOTS")
  sr_bez_cx2(sr_px_ok(bsc), sr_px_ok(kno), st, bsc, kno, esense)

def sr_curve_fin2(+done: Bool, +res: SR_C) -> SR_C:
  match done:
    case True{}: res
    case False{}: sr_c_fail()

def sr_curve_fin(+cs: SR_CST) -> SR_C:
  match cs:
    case CST{+id, +done, +res, +esense}: sr_curve_fin2(done, res)

def sr_wrap_nx2(+w: Bool, +basis: U64, +id: U64, +esense: Bool) -> SR_CST:
  match w:
    case False{}: CST{id, True{}, sr_c_fail(), esense}
    case True{}: CST{basis, False{}, sr_c_fail(), esense}

def sr_wrap_nx(+st: ST, +e: SE, +id: U64, +esense: Bool) -> SR_CST:
  +r = sr_wrap_of(e)
  sr_wrap_nx2(sr_tm_ok(r), sr_tm_basis(r), id, esense)

def sr_trim_be(+w: Bool, +st: ST, +pos: Nat, +v0: V.Point, +v1: V.Point, +esense: Bool,
    +tsense: Bool, +id: U64) -> SR_CST:
  match w:
    case False{}: CST{id, True{}, sr_c_fail(), esense}
    case True{}: CST{id, True{}, sr_line_cv(st, sr_ent_at(st, pos), v0, v1,
      sr_xnor(esense, tsense)), esense}

def sr_trim_be2(+w: Bool, +st: ST, +pos: Nat, +v0: V.Point, +v1: V.Point, +esense: Bool,
    +tsense: Bool, +id: U64) -> SR_CST:
  match w:
    case False{}: CST{id, True{}, sr_c_fail(), esense}
    case True{}: CST{id, True{}, sr_circ_cv(st, sr_ent_at(st, pos), v0, v1,
      sr_xnor(esense, tsense)), esense}

def sr_trim_kd(+kind: U64, +st: ST, +e: SE, +v0: V.Point, +v1: V.Point, +esense: Bool,
    +tsense: Bool, +basis: U64, +id: U64) -> SR_CST:
  match kind:
    case 4u64:
      +f = sr_find(st, basis)
      sr_trim_be(sr_f_ok(f), st, sr_f_pos(f), v0, v1, esense, tsense, id)
    case 5u64:
      +f = sr_find(st, basis)
      sr_trim_be2(sr_f_ok(f), st, sr_f_pos(f), v0, v1, esense, tsense, id)
    case 6u64: CST{basis, False{}, sr_c_fail(), sr_xnor(esense, tsense)}
    case 24u64: CST{basis, False{}, sr_c_fail(), sr_xnor(esense, tsense)}
    case 25u64: CST{basis, False{}, sr_c_fail(), sr_xnor(esense, tsense)}
    case _: CST{id, True{}, sr_c_fail(), esense}

def sr_trim_bk2(+w: Bool, +pos: Nat, +st: ST, +e: SE, +v0: V.Point, +v1: V.Point,
    +esense: Bool, +tm: SR_TM, +id: U64) -> SR_CST:
  match w:
    case False{}: CST{id, True{}, sr_c_fail(), esense}
    case True{}: sr_trim_kd(sr_kr_kind(sr_kr_at(st, pos)), st, e, v0, v1, esense,
      sr_tm_sense(tm), sr_tm_basis(tm), id)

def sr_trim_bk(+f: SF, +st: ST, +e: SE, +v0: V.Point, +v1: V.Point, +esense: Bool, +tm: SR_TM,
    +id: U64) -> SR_CST:
  match f:
    case SF{+ok, +pos}: sr_trim_bk2(ok, pos, st, e, v0, v1, esense, tm, id)

def sr_trim_nx2(+w: Bool, +st: ST, +e: SE, +v0: V.Point, +v1: V.Point, +esense: Bool, +tm: SR_TM,
    +id: U64) -> SR_CST:
  match w:
    case False{}: CST{id, True{}, sr_c_fail(), esense}
    case True{}:
      +f = sr_find(st, sr_tm_basis(tm))
      sr_trim_bk(f, st, e, v0, v1, esense, tm, id)

def sr_trim_nx(+st: ST, +e: SE, +v0: V.Point, +v1: V.Point, +esense: Bool, +id: U64) -> SR_CST:
  +tm = sr_trim_of(e)
  sr_trim_nx2(sr_tm_ok(tm), st, e, v0, v1, esense, tm, id)

def sr_curve_kd(+kind: U64, +st: ST, +e: SE, +v0: V.Point, +v1: V.Point, +esense: Bool,
    +id: U64) -> SR_CST:
  match kind:
    case 4u64: CST{id, True{}, sr_line_cv(st, e, v0, v1, esense), esense}
    case 5u64: CST{id, True{}, sr_circ_cv(st, e, v0, v1, esense), esense}
    case 6u64: sr_trim_nx(st, e, v0, v1, esense, id)
    case 7u64: CST{id, True{}, sr_rat_of(st, e, esense), esense}
    case 8u64: CST{id, True{}, sr_bez_of(st, e, esense), esense}
    case 24u64: sr_wrap_nx(st, e, id, esense)
    case 25u64: sr_wrap_nx(st, e, id, esense)
    case _: CST{id, True{}, sr_c_fail(), esense}

def sr_curve_m2(+w: Bool, +st: ST, +v0: V.Point, +v1: V.Point, +esense: Bool, +id: U64,
    +pos: Nat) -> SR_CST:
  match w:
    case False{}: CST{id, True{}, sr_c_fail(), esense}
    case True{}: sr_curve_kd(sr_kr_kind(sr_kr_at(st, pos)), st, sr_ent_at(st, pos), v0, v1,
      esense, id)

def sr_curve_m(+done: Bool, +st: ST, +v0: V.Point, +v1: V.Point, +esense: Bool, +id: U64,
    +res: SR_C) -> SR_CST:
  match done:
    case True{}: CST{id, True{}, res, esense}
    case False{}:
      +f = sr_find(st, id)
      sr_curve_m2(sr_f_ok(f), st, v0, v1, esense, id, sr_f_pos(f))

def sr_curve_nx(+st: ST, +v0: V.Point, +v1: V.Point, +cs: SR_CST) -> SR_CST:
  match cs:
    case CST{+id, +done, +res, +esense}: sr_curve_m(done, st, v0, v1, esense, id, res)

def sr_curve_go(+fuel: Nat, +st: ST, +v0: V.Point, +v1: V.Point, +cs: SR_CST) -> SR_CST:
  match fuel:
    case 0n: cs
    case 1n+f: sr_curve_go(f, st, v0, v1, sr_curve_nx(st, v0, v1, cs))

def sr_curve_of(+st: ST, +id: U64, +v0: V.Point, +v1: V.Point, +esense: Bool) -> SR_C:
  sr_curve_fin(sr_curve_go(8n, st, v0, v1, CST{id, False{}, sr_c_fail(), esense}))

def sr_frame_ax2(+w: Bool, +ax: SR_AX) -> SR_FR:
  match w:
    case False{}: sr_fr_fail()
    case True{}: sr_frame_ax(ax)

def sr_frame_of(+st: ST, +id: U64) -> SR_FR:
  +r = sr_ax_ent(st, id)
  sr_frame_ax2(sr_ax_ok(r), r)

def sr_s_fail() -> SR_S:
  SR_S{False{}, G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 0.0f64}}}}

def sr_pl_fr(+w: Bool, +fr: SR_FR) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: SR_S{True{}, G.GV_pl{G.Pl{sr_fr_o(fr), sr_fr_u(fr), sr_fr_v(fr)}}}

def sr_pl_a2(+a: SA, +st: ST) -> SR_S:
  match a:
    case SA_ref{+id}:
      +r = sr_frame_of(st, id)
      sr_pl_fr(sr_fr_ok(r), r)
    case _: sr_s_fail()

def sr_pl_a(+w: Bool, +a: SA, +st: ST) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: sr_pl_a2(a, st)

def sr_pl_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_pl_a(sr_a_ok(r), sr_a_v(r), st)

def sr_pl_of(+st: ST, +e: SE) -> SR_S:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_pl_x(sr_px_ok(r), sr_px_xs(r), st)

def sr_sp_pos(+w: Bool, +rv: F64, +o: V.Point) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: SR_S{True{}, G.GV_sp{G.Sp{o, rv}}}

def sr_sp_r(+w: Bool, +rv: F64, +o: V.Point) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: sr_sp_pos(F64.is_lt(0.0f64, rv), rv, o)

def sr_sp_n(+w: Bool, +a: SA, +o: V.Point) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_num_of(a)
      sr_sp_r(sr_n_ok(r), sr_n_v(r), o)

def sr_sp_ax(+w: Bool, +ax: SR_AX, +xs: List<&2, SA>) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_nth(xs, 2n)
      sr_sp_n(sr_a_ok(r), sr_a_v(r), sr_ax_o(ax))

def sr_sp_a2(+a: SA, +st: ST, +xs: List<&2, SA>) -> SR_S:
  match a:
    case SA_ref{+id}:
      +r = sr_ax_ent(st, id)
      sr_sp_ax(sr_ax_ok(r), r, xs)
    case _: sr_s_fail()

def sr_sp_a(+w: Bool, +a: SA, +st: ST, +xs: List<&2, SA>) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: sr_sp_a2(a, st, xs)

def sr_sp_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_sp_a(sr_a_ok(r), sr_a_v(r), st, xs)

def sr_sp_of(+st: ST, +e: SE) -> SR_S:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_sp_x(sr_px_ok(r), sr_px_xs(r), st)

def sr_cy_pos(+w: Bool, +rv: F64, +o: V.Point, +ww: V.Dir) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: SR_S{True{}, G.GV_cy{G.Cy{o, ww, rv}}}

def sr_cy_r(+w: Bool, +rv: F64, +o: V.Point, +ww: V.Dir) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: sr_cy_pos(F64.is_lt(0.0f64, rv), rv, o, ww)

def sr_cy_n(+w: Bool, +a: SA, +o: V.Point, +ww: V.Dir) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_num_of(a)
      sr_cy_r(sr_n_ok(r), sr_n_v(r), o, ww)

def sr_cy_w(+w: Bool, +ax: SR_AX, +xs: List<&2, SA>, +ww: V.Dir) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_nth(xs, 2n)
      sr_cy_n(sr_a_ok(r), sr_a_v(r), sr_ax_o(ax), ww)

def sr_cy_ax(+w: Bool, +ax: SR_AX, +xs: List<&2, SA>) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_norm(sr_ax_w(ax))
      sr_cy_w(sr_d_ok(r), ax, xs, sr_d_v(r))

def sr_cy_a2(+a: SA, +st: ST, +xs: List<&2, SA>) -> SR_S:
  match a:
    case SA_ref{+id}:
      +r = sr_ax_ent(st, id)
      sr_cy_ax(sr_ax_ok(r), r, xs)
    case _: sr_s_fail()

def sr_cy_a(+w: Bool, +a: SA, +st: ST, +xs: List<&2, SA>) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: sr_cy_a2(a, st, xs)

def sr_cy_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_cy_a(sr_a_ok(r), sr_a_v(r), st, xs)

def sr_cy_of(+st: ST, +e: SE) -> SR_S:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_cy_x(sr_px_ok(r), sr_px_xs(r), st)

def sr_to_pos(+w: Bool, +rv: F64, +o: V.Point, +ww: V.Dir, +rv2: F64) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: SR_S{True{}, G.GV_to{G.To{o, ww, rv, rv2}}}

def sr_to_rr(+w: Bool, +rv: F64, +o: V.Point, +ww: V.Dir, +rv2: F64) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: sr_to_pos(Bool.and(F64.is_lt(0.0f64, rv), F64.is_lt(0.0f64, rv2)), rv, o, ww,
      rv2)

def sr_to_n2(+w: Bool, +a: SA, +o: V.Point, +ww: V.Dir, +rv: F64) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_num_of(a)
      sr_to_rr(sr_n_ok(r), rv, o, ww, sr_n_v(r))

def sr_to_n3(+w: Bool, +rv: F64, +xs: List<&2, SA>, +o: V.Point, +ww: V.Dir) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_nth(xs, 3n)
      sr_to_n2(sr_a_ok(r), sr_a_v(r), o, ww, rv)

def sr_to_n(+w: Bool, +a: SA, +xs: List<&2, SA>, +o: V.Point, +ww: V.Dir) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_num_of(a)
      sr_to_n3(sr_n_ok(r), sr_n_v(r), xs, o, ww)

def sr_to_w(+w: Bool, +ax: SR_AX, +xs: List<&2, SA>, +ww: V.Dir) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_nth(xs, 2n)
      sr_to_n(sr_a_ok(r), sr_a_v(r), xs, sr_ax_o(ax), ww)

def sr_to_ax(+w: Bool, +ax: SR_AX, +xs: List<&2, SA>) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_norm(sr_ax_w(ax))
      sr_to_w(sr_d_ok(r), ax, xs, sr_d_v(r))

def sr_to_a2(+a: SA, +st: ST, +xs: List<&2, SA>) -> SR_S:
  match a:
    case SA_ref{+id}:
      +r = sr_ax_ent(st, id)
      sr_to_ax(sr_ax_ok(r), r, xs)
    case _: sr_s_fail()

def sr_to_a(+w: Bool, +a: SA, +st: ST, +xs: List<&2, SA>) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: sr_to_a2(a, st, xs)

def sr_to_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_to_a(sr_a_ok(r), sr_a_v(r), st, xs)

def sr_to_of(+st: ST, +e: SE) -> SR_S:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_to_x(sr_px_ok(r), sr_px_xs(r), st)

def sr_surf_kd(+kind: U64, +st: ST, +e: SE) -> SR_S:
  match kind:
    case 10u64: sr_pl_of(st, e)
    case 11u64: sr_sp_of(st, e)
    case 12u64: sr_cy_of(st, e)
    case 13u64: sr_to_of(st, e)
    case _: sr_s_fail()

def sr_surf_f(+w: Bool, +st: ST, +pos: Nat) -> SR_S:
  match w:
    case False{}: sr_s_fail()
    case True{}: sr_surf_kd(sr_kr_kind(sr_kr_at(st, pos)), st, sr_ent_at(st, pos))

def sr_surf_of(+st: ST, +id: U64) -> SR_S:
  +f = sr_find(st, id)
  sr_surf_f(sr_f_ok(f), st, sr_f_pos(f))

def sr_ck_ln(+w: G.Line3, +lo: F64, +hi: F64) -> BL.ES:
  match w:
    case G.Ln{+p, +d}: BL.es_ok("1," ++ BL.pt_s(p) ++ "," ++ BL.dr_s(d) ++ "," ++ N.f_show(lo) ++
      "," ++ N.f_show(hi))

def sr_ck_cc(+w: G.Circle3, +lo: F64, +hi: F64) -> BL.ES:
  match w:
    case G.Cc{+c, +u, +v, +r}: BL.es_ok("2," ++ BL.pt_s(c) ++ "," ++ BL.dr_s(u) ++ "," ++
      BL.dr_s(v) ++ "," ++ N.f_show(r) ++ "," ++ N.f_show(lo) ++ "," ++ N.f_show(hi))

def sr_ck_rq(+w: G.RQBez, +lo: F64, +hi: F64) -> BL.ES:
  match w:
    case G.Rq{+p0, +p1, +p2, +w0, +w1, +w2}: BL.es_ok("3," ++ BL.pt_s(p0) ++ "," ++
      BL.pt_s(p1) ++ "," ++ BL.pt_s(p2) ++ "," ++ N.f_show(w0) ++ "," ++ N.f_show(w1) ++ "," ++
      N.f_show(w2) ++ "," ++ N.f_show(lo) ++ "," ++ N.f_show(hi))

def sr_ck_bz(+w: G.Bez3, +lo: F64, +hi: F64) -> BL.ES:
  match w:
    case G.Bz{+p0, +p1, +p2, +p3}: BL.es_ok("4," ++ BL.pt_s(p0) ++ "," ++ BL.pt_s(p1) ++ "," ++
      BL.pt_s(p2) ++ "," ++ BL.pt_s(p3) ++ "," ++ N.f_show(lo) ++ "," ++ N.f_show(hi))

def sr_ck_of(+g: G.GVal, +lo: F64, +hi: F64) -> BL.ES:
  match g:
    case G.GV_ln{+w}: sr_ck_ln(w, lo, hi)
    case G.GV_cc{+w}: sr_ck_cc(w, lo, hi)
    case G.GV_rq{+w}: sr_ck_rq(w, lo, hi)
    case G.GV_bz{+w}: sr_ck_bz(w, lo, hi)
    case _: BL.es_fail("step-curve-kind-not-in-profile")

def sr_sf_pl(+w: G.Plane3) -> BL.ES:
  match w:
    case G.Pl{+o, +u, +v}: BL.es_ok("10," ++ BL.pt_s(o) ++ "," ++ BL.dr_s(u) ++ "," ++
      BL.dr_s(v))

def sr_sf_sp(+w: G.Sphere) -> BL.ES:
  match w:
    case G.Sp{+c, +r}: BL.es_ok("11," ++ BL.pt_s(c) ++ "," ++ N.f_show(r))

def sr_sf_cy(+w: G.Cyl) -> BL.ES:
  match w:
    case G.Cy{+o, +a, +r}: BL.es_ok("12," ++ BL.pt_s(o) ++ "," ++ BL.dr_s(a) ++ "," ++
      N.f_show(r))

def sr_sf_to(+w: G.Torus) -> BL.ES:
  match w:
    case G.To{+o, +a, +R, +r}: BL.es_ok("13," ++ BL.pt_s(o) ++ "," ++ BL.dr_s(a) ++ "," ++
      N.f_show(R) ++ "," ++ N.f_show(r))

def sr_sf_of(+g: G.GVal) -> BL.ES:
  match g:
    case G.GV_pl{+w}: sr_sf_pl(w)
    case G.GV_sp{+w}: sr_sf_sp(w)
    case G.GV_cy{+w}: sr_sf_cy(w)
    case G.GV_to{+w}: sr_sf_to(w)
    case _: BL.es_fail("step-surface-kind-not-in-profile")

def sr_pnth_go(xs: List<&2, V.Point>, +i: Nat) -> SR_P:
  match xs:
    case []: SR_P{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case h <> t:
      match i:
        case 0n: SR_P{True{}, h}
        case 1n+j: sr_pnth_go(t, j)

def sr_pnth(xs: List<&2, V.Point>, +i: Nat) -> SR_P:
  sr_pnth_go(xs, i)

def sr_nnth_go(xs: List<&2, Nat>, +i: Nat) -> SR_I:
  match xs:
    case []: SR_I{False{}, 0n}
    case h <> t:
      match i:
        case 0n: SR_I{True{}, h}
        case 1n+j: sr_nnth_go(t, j)

def sr_nnth(xs: List<&2, Nat>, +i: Nat) -> SR_I:
  sr_nnth_go(xs, i)

def sr_gnth_go(xs: List<&2, G.GVal>, +i: Nat) -> SR_S:
  match xs:
    case []: sr_s_fail()
    case h <> t:
      match i:
        case 0n: SR_S{True{}, h}
        case 1n+j: sr_gnth_go(t, j)

def sr_gnth(xs: List<&2, G.GVal>, +i: Nat) -> SR_S:
  sr_gnth_go(xs, i)

def sr_ce_cmp(a: CE_F, b: CE_F) -> B.Sgn:
  CE_F{+x, +fx, +px} = a
  CE_F{+y, +fy, +py} = b
  B.sgn_pick(Nat.is_lt(x, y), Nat.is_lt(y, x))

def sr_bd_cmp(a: BD_F, b: BD_F) -> B.Sgn:
  BD_F{+x, +fx, +px} = a
  BD_F{+y, +fy, +py} = b
  B.sgn_pick(Nat.is_lt(x, y), Nat.is_lt(y, x))

def sr_nat_go(+x: Nat, +y: Nat) -> B.Sgn:
  B.sgn_pick(Nat.is_lt(x, y), Nat.is_lt(y, x))

def sr_nat_cmp(a: Nat, b: Nat) -> B.Sgn:
  sr_nat_go(a, b)

def sr_ce_m(+m: B.So<&2, CE_F>) -> SR_CEL:
  match m:
    case B.So{+ok, +xs}: SR_CEL{ok, xs}

def sr_ce_sorted(+xs: List<&2, CE_F>) -> SR_CEL:
  sr_ce_m(B.msort(~CE_F, ~sr_ce_cmp, xs))

def sr_bd_m(+m: B.So<&2, BD_F>) -> SR_BDL:
  match m:
    case B.So{+ok, +xs}: SR_BDL{ok, xs}

def sr_bd_sorted(+xs: List<&2, BD_F>) -> SR_BDL:
  sr_bd_m(B.msort(~BD_F, ~sr_bd_cmp, xs))

def sr_nat_m(+m: B.So<&2, Nat>) -> SR_NAT:
  match m:
    case B.So{+ok, +xs}: SR_NAT{ok, xs}

def sr_nat_sorted(+xs: List<&2, Nat>) -> SR_NAT:
  sr_nat_m(B.msort(~Nat, ~sr_nat_cmp, xs))

def sr_vw_rows(+r: SR_VW) -> List<&2, String>:
  VW{rows, pts, ok, bad} = r
  rows

def sr_vw_pts(+r: SR_VW) -> List<&2, V.Point>:
  VW{rows, pts, ok, bad} = r
  pts

def sr_vw_ok(+r: SR_VW) -> Bool:
  VW{rows, pts, ok, bad} = r
  ok

def sr_vw_bad(+r: SR_VW) -> U64:
  VW{rows, pts, ok, bad} = r
  bad

def sr_vw_hit2(+w: Bool, +id: U64, +p: V.Point, +rows: List<&2, String>,
    +pts: List<&2, V.Point>, +bad: U64) -> SR_VW:
  match w:
    case True{}: VW{BL.pt_s(p) <> rows, p <> pts, True{}, bad}
    case False{}: VW{rows, pts, False{}, id}

def sr_vw_hit(+w: Bool, +id: U64, +p: V.Point, +rows: List<&2, String>,
    +pts: List<&2, V.Point>, +ok: Bool, +bad: U64) -> SR_VW:
  match ok:
    case False{}: VW{rows, pts, False{}, bad}
    case True{}: sr_vw_hit2(w, id, p, rows, pts, bad)

def sr_vw_m(+kind: U64, +h: SE, +st: ST, +rows: List<&2, String>, +pts: List<&2, V.Point>,
    +ok: Bool, +bad: U64) -> SR_VW:
  match kind:
    case 15u64:
      +r = sr_vx_pt(st, sr_se_id(h))
      sr_vw_hit(sr_p_ok(r), sr_se_id(h), sr_p_v(r), rows, pts, ok, bad)
    case _: VW{rows, pts, ok, bad}

def sr_vw_nx(+kind: U64, +h: SE, +st: ST, +vw: SR_VW) -> SR_VW:
  match vw:
    case VW{+rows, +pts, +ok, +bad}: sr_vw_m(kind, h, st, rows, pts, ok, bad)

def sr_vw_go(es: List<&2, SE>, +st: ST, +vw: SR_VW) -> SR_VW:
  match es:
    case []: vw
    case +h <> t: sr_vw_go(t, st, sr_vw_nx(sr_kind_of(h), h, st, vw))

def sr_vrows(+es: List<&2, SE>, +st: ST) -> SR_VW:
  sr_vw_go(es, st, VW{[], [], True{}, 0u64})

def sr_vl_bd(+r: VL_F) -> Nat:
  VL_F{bd, vp, first} = r
  bd

def sr_vl_vp(+r: VL_F) -> Nat:
  VL_F{bd, vp, first} = r
  vp

def sr_vl_first(+r: VL_F) -> Bool:
  VL_F{bd, vp, first} = r
  first

def sr_vl_ok(+r: SR_VL) -> Bool:
  SR_VL{ok, vls, bad} = r
  ok

def sr_vl_xs(+r: SR_VL) -> List<&2, VL_F>:
  SR_VL{ok, vls, bad} = r
  vls

def sr_vl_bad(+r: SR_VL) -> U64:
  SR_VL{ok, vls, bad} = r
  bad

def sr_u64_mem(xs: List<&2, U64>, +id: U64) -> Bool:
  match xs:
    case []: False{}
    case +h <> t: Bool.or(U64.is_eq(h, id), sr_u64_mem(t, id))

def sr_firsts_hr(+h: SA, +acc: List<&2, U64>) -> List<&2, U64>:
  match h:
    case SA_ref{+id}: id <> acc
    case _: acc

def sr_firsts_hl(xs: List<&2, SA>, +acc: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case []: acc
    case +h <> _: sr_firsts_hr(h, acc)

def sr_firsts_hd(+a: SA, +acc: List<&2, U64>) -> List<&2, U64>:
  match a:
    case SA_ls{+xs}: sr_firsts_hl(xs, acc)
    case _: acc

def sr_firsts_fc(+w: Bool, +a: SA, +acc: List<&2, U64>) -> List<&2, U64>:
  match w:
    case False{}: acc
    case True{}: sr_firsts_hd(a, acc)

def sr_firsts_px(+w: Bool, +xs: List<&2, SA>, +acc: List<&2, U64>) -> List<&2, U64>:
  match w:
    case False{}: acc
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_firsts_fc(sr_a_ok(r), sr_a_v(r), acc)

def sr_firsts_nx(+kind: U64, +h: SE, +acc: List<&2, U64>) -> List<&2, U64>:
  match kind:
    case 20u64:
      SE{+id, +ps} = h
      +r = sr_p0(ps)
      sr_firsts_px(sr_px_ok(r), sr_px_xs(r), acc)
    case _: acc

def sr_firsts_go(es: List<&2, SE>, +acc: List<&2, U64>) -> List<&2, U64>:
  match es:
    case []: acc
    case +h <> t: sr_firsts_go(t, sr_firsts_nx(sr_kind_of(h), h, acc))

def sr_firsts(es: List<&2, SE>) -> List<&2, U64>:
  sr_firsts_go(es, [])

def sr_bloop_kind2(+w: Bool, +st: ST, +pos: Nat) -> U64:
  match w:
    case False{}: 0u64
    case True{}: sr_kr_kind(sr_kr_at(st, pos))

def sr_bloop_lr(+a: SA, +st: ST) -> U64:
  match a:
    case SA_ref{+lid}:
      +f = sr_find(st, lid)
      sr_bloop_kind2(sr_f_ok(f), st, sr_f_pos(f))
    case _: 0u64

def sr_bloop_bx2(+w: Bool, +a: SA, +st: ST) -> U64:
  match w:
    case False{}: 0u64
    case True{}: sr_bloop_lr(a, st)

def sr_bloop_bx(+w: Bool, +xs: List<&2, SA>, +st: ST) -> U64:
  match w:
    case False{}: 0u64
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_bloop_bx2(sr_a_ok(r), sr_a_v(r), st)

def sr_bloop_kind(+h: SE, +st: ST) -> U64:
  SE{+id, +ps} = h
  +r = sr_p0(ps)
  sr_bloop_bx(sr_px_ok(r), sr_px_xs(r), st)

def sr_vl_vp2(+w: Bool, +a: SA, +st: ST) -> SR_I:
  match w:
    case False{}: SR_I{False{}, 0n}
    case True{}: sr_rank_of(st, a, 15u64)

def sr_vl_vp_xs(+xs: List<&2, SA>, +st: ST) -> SR_I:
  +r = sr_nth(xs, 1n)
  sr_vl_vp2(sr_a_ok(r), sr_a_v(r), st)

def sr_vl_px(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_I:
  match w:
    case False{}: SR_I{False{}, 0n}
    case True{}: sr_vl_vp_xs(xs, st)

def sr_vloop_vp(+e: SE, +st: ST) -> SR_I:
  SE{+id, +ps} = e
  +r = sr_p0(ps)
  sr_vl_px(sr_px_ok(r), sr_px_xs(r), st)

def sr_vls_vp(+w: Bool, +vp: Nat, +h: SE, +firsts: List<&2, U64>, +bd: Nat,
    +acc: List<&2, VL_F>, +bad: U64) -> SR_VL:
  match w:
    case False{}: SR_VL{False{}, [], sr_se_id(h)}
    case True{}: SR_VL{True{}, VL_F{bd, vp, sr_u64_mem(firsts, sr_se_id(h))} <> acc, bad}

def sr_vls_lf(+w: Bool, +st: ST, +pos: Nat, +h: SE, +firsts: List<&2, U64>, +bd: Nat,
    +acc: List<&2, VL_F>, +bad: U64) -> SR_VL:
  match w:
    case False{}: SR_VL{False{}, [], sr_se_id(h)}
    case True{}:
      +i = sr_vloop_vp(sr_ent_at(st, pos), st)
      sr_vls_vp(sr_i_ok(i), sr_i_v(i), h, firsts, bd, acc, bad)

def sr_vls_lref(+a: SA, +st: ST, +h: SE, +firsts: List<&2, U64>, +bd: Nat,
    +acc: List<&2, VL_F>, +bad: U64) -> SR_VL:
  match a:
    case SA_ref{+lid}:
      +f = sr_find(st, lid)
      sr_vls_lf(sr_f_ok(f), st, sr_f_pos(f), h, firsts, bd, acc, bad)
    case _: SR_VL{False{}, [], sr_se_id(h)}

def sr_vls_lr(+w: Bool, +a: SA, +st: ST, +h: SE, +firsts: List<&2, U64>, +bd: Nat,
    +acc: List<&2, VL_F>, +bad: U64) -> SR_VL:
  match w:
    case False{}: SR_VL{False{}, [], sr_se_id(h)}
    case True{}: sr_vls_lref(a, st, h, firsts, bd, acc, bad)

def sr_vls_px(+w: Bool, +xs: List<&2, SA>, +st: ST, +h: SE, +firsts: List<&2, U64>,
    +bd: Nat, +acc: List<&2, VL_F>, +bad: U64) -> SR_VL:
  match w:
    case False{}: SR_VL{False{}, [], sr_se_id(h)}
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_vls_lr(sr_a_ok(r), sr_a_v(r), st, h, firsts, bd, acc, bad)

def sr_vls_lp(+h: SE, +st: ST, +firsts: List<&2, U64>, +bd: Nat, +acc: List<&2, VL_F>,
    +bad: U64) -> SR_VL:
  SE{+id, +ps} = h
  +r = sr_p0(ps)
  sr_vls_px(sr_px_ok(r), sr_px_xs(r), st, h, firsts, bd, acc, bad)

def sr_vls_lk(+lk: U64, +h: SE, +st: ST, +firsts: List<&2, U64>, +bd: Nat,
    +acc: List<&2, VL_F>, +bad: U64) -> SR_VL:
  match lk:
    case 23u64: sr_vls_lp(h, st, firsts, bd, acc, bad)
    case _: SR_VL{True{}, acc, bad}

def sr_vls_bd(+h: SE, +st: ST, +firsts: List<&2, U64>, +bd: Nat, +acc: List<&2, VL_F>,
    +ok: Bool, +bad: U64) -> SR_VL:
  match ok:
    case False{}: SR_VL{False{}, [], bad}
    case True{}: sr_vls_lk(sr_bloop_kind(h, st), h, st, firsts, bd, acc, bad)

def sr_vls_nx(+kind: U64, +h: SE, +st: ST, +firsts: List<&2, U64>, +bd: Nat,
    +acc: List<&2, VL_F>, +ok: Bool, +bad: U64) -> SR_VL:
  match kind:
    case 19u64: sr_vls_bd(h, st, firsts, bd, acc, ok, bad)
    case 26u64: sr_vls_bd(h, st, firsts, bd, acc, ok, bad)
    case _: SR_VL{ok, acc, bad}

def sr_vls_bd_c(+kind: U64, +bd: Nat) -> Nat:
  match kind:
    case 19u64: Nat.add(bd, 1n)
    case 26u64: Nat.add(bd, 1n)
    case _: bd

def sr_vls_go(es: List<&2, SE>, +st: ST, +firsts: List<&2, U64>, +bd: Nat,
    +acc: List<&2, VL_F>, +ok: Bool, +bad: U64) -> SR_VL:
  match es:
    case []: SR_VL{ok, List.reverse(&2, VL_F, acc), bad}
    case +h <> t:
      +k = sr_kind_of(h)
      +r = sr_vls_nx(k, h, st, firsts, bd, acc, ok, bad)
      sr_vls_go(t, st, firsts, sr_vls_bd_c(k, bd), sr_vl_xs(r), sr_vl_ok(r), sr_vl_bad(r))

def sr_vls(+es: List<&2, SE>, +st: ST) -> SR_VL:
  sr_vls_go(es, st, sr_firsts(es), 0n, [], True{}, 0u64)

def sr_er_ok(+r: SR_ER) -> Bool:
  SR_ER{ok, row, e0, e1, why} = r
  ok

def sr_er_row(+r: SR_ER) -> String:
  SR_ER{ok, row, e0, e1, why} = r
  row

def sr_er_e0(+r: SR_ER) -> Nat:
  SR_ER{ok, row, e0, e1, why} = r
  e0

def sr_er_e1(+r: SR_ER) -> Nat:
  SR_ER{ok, row, e0, e1, why} = r
  e1

def sr_er_why(+r: SR_ER) -> U64:
  SR_ER{ok, row, e0, e1, why} = r
  why

def sr_why4d(+wk: Bool) -> U64:
  match wk:
    case False{}: 4u64
    case True{}: 0u64

def sr_why4c(+wc: Bool, +wk: Bool) -> U64:
  match wc:
    case False{}: 3u64
    case True{}: sr_why4d(wk)

def sr_why4b(+ws: Bool, +wc: Bool, +wk: Bool) -> U64:
  match ws:
    case False{}: 2u64
    case True{}: sr_why4c(wc, wk)

def sr_why4(+wv: Bool, +ws: Bool, +wc: Bool, +wk: Bool) -> U64:
  match wv:
    case False{}: 1u64
    case True{}: sr_why4b(ws, wc, wk)

def sr_er_fail(+why: U64) -> SR_ER:
  SR_ER{False{}, "", 0n, 0n, why}

def sr_c_g(+r: SR_C) -> G.GVal:
  SR_C{ok, g, lo, hi} = r
  g

def sr_c_hi(+r: SR_C) -> F64:
  SR_C{ok, g, lo, hi} = r
  hi

def sr_c_lo(+r: SR_C) -> F64:
  SR_C{ok, g, lo, hi} = r
  lo

def sr_edge_ck(+w: Bool, +ck: BL.ES, +cv: SR_C, +i0: Nat, +i1: Nat, +wv: Bool, +ws: Bool) ->
    SR_ER:
  match w:
    case False{}: sr_er_fail(sr_why4(wv, ws, True{}, False{}))
    case True{}: SR_ER{True{}, Nat.show(i0) ++ "," ++ Nat.show(i1) ++ "," ++ BL.es_s(ck), i0,
      i1, 0u64}

def sr_edge_cv(+w: Bool, +cv: SR_C, +i0: Nat, +i1: Nat, +wv: Bool, +ws: Bool) -> SR_ER:
  match w:
    case False{}: sr_er_fail(sr_why4(wv, ws, False{}, False{}))
    case True{}:
      +ck = sr_ck_of(sr_c_g(cv), sr_c_lo(cv), sr_c_hi(cv))
      sr_edge_ck(BL.es_ok_of(ck), ck, cv, i0, i1, wv, ws)

def sr_c_ok(+r: SR_C) -> Bool:
  SR_C{ok, g, lo, hi} = r
  ok

def sr_edge_cid2(+a: SA, +st: ST, +v0c: V.Point, +v1c: V.Point, +esense: Bool, +i0: Nat,
    +i1: Nat, +wv: Bool, +ws: Bool) -> SR_ER:
  match a:
    case SA_ref{+cid}:
      +cv = sr_curve_of(st, cid, v0c, v1c, esense)
      sr_edge_cv(sr_c_ok(cv), cv, i0, i1, wv, ws)
    case _: sr_er_fail(sr_why4(wv, ws, False{}, False{}))

def sr_edge_cid(+w: Bool, +a: SA, +st: ST, +v0c: V.Point, +v1c: V.Point, +esense: Bool, +i0: Nat,
    +i1: Nat, +wv: Bool, +ws: Bool) -> SR_ER:
  match w:
    case False{}: sr_er_fail(sr_why4(wv, ws, False{}, False{}))
    case True{}: sr_edge_cid2(a, st, v0c, v1c, esense, i0, i1, wv, ws)

def sr_edge_se2(+w: Bool, +esense: Bool, +xs: List<&2, SA>, +st: ST, +v0c: V.Point,
    +v1c: V.Point, +i0: Nat, +i1: Nat, +wv: Bool) -> SR_ER:
  match w:
    case False{}: sr_er_fail(sr_why4(wv, False{}, False{}, False{}))
    case True{}:
      +r = sr_nth(xs, 3n)
      sr_edge_cid(sr_a_ok(r), sr_a_v(r), st, v0c, v1c, esense, i0, i1, wv, True{})

def sr_edge_se(+w: Bool, +a: SA, +xs: List<&2, SA>, +st: ST, +v0c: V.Point, +v1c: V.Point,
    +i0: Nat, +i1: Nat, +wv: Bool) -> SR_ER:
  match w:
    case False{}: sr_er_fail(sr_why4(wv, False{}, False{}, False{}))
    case True{}:
      +r = sr_en_of(a)
      sr_edge_se2(sr_b_ok(r), sr_b_v(r), xs, st, v0c, v1c, i0, i1, wv)

def sr_edge_vv(+w: Bool, +v0c: V.Point, +v1c: V.Point, +xs: List<&2, SA>, +st: ST, +i0: Nat,
    +i1: Nat) -> SR_ER:
  match w:
    case False{}: sr_er_fail(1u64)
    case True{}:
      +r = sr_nth(xs, 4n)
      sr_edge_se(sr_a_ok(r), sr_a_v(r), xs, st, v0c, v1c, i0, i1, True{})

def sr_edge_v13(+w: Bool, +v1c: V.Point, +xs: List<&2, SA>, +st: ST, +i0: Nat, +i1: Nat,
    +v0c: V.Point) -> SR_ER:
  match w:
    case False{}: sr_er_fail(1u64)
    case True{}: sr_edge_vv(True{}, v0c, v1c, xs, st, i0, i1)

def sr_edge_v12(+w: Bool, +i1: Nat, +st: ST, +xs: List<&2, SA>, +vpts: List<&2, V.Point>,
    +i0: Nat, +v0c: V.Point) -> SR_ER:
  match w:
    case False{}: sr_er_fail(1u64)
    case True{}:
      +p1 = sr_pnth(vpts, i1)
      sr_edge_v13(sr_p_ok(p1), sr_p_v(p1), xs, st, i0, i1, v0c)

def sr_edge_v1(+w: Bool, +a: SA, +st: ST, +xs: List<&2, SA>, +vpts: List<&2, V.Point>,
    +i0: Nat, +v0c: V.Point) -> SR_ER:
  match w:
    case False{}: sr_er_fail(1u64)
    case True{}:
      +r1 = sr_rank_of(st, a, 15u64)
      sr_edge_v12(sr_i_ok(r1), sr_i_v(r1), st, xs, vpts, i0, v0c)

def sr_edge_v03(+w: Bool, +v0c: V.Point, +st: ST, +xs: List<&2, SA>, +vpts: List<&2, V.Point>,
    +i0: Nat) -> SR_ER:
  match w:
    case False{}: sr_er_fail(1u64)
    case True{}:
      +r = sr_nth(xs, 2n)
      sr_edge_v1(sr_a_ok(r), sr_a_v(r), st, xs, vpts, i0, v0c)

def sr_edge_v02(+w: Bool, +i0: Nat, +st: ST, +xs: List<&2, SA>, +vpts: List<&2, V.Point>) ->
    SR_ER:
  match w:
    case False{}: sr_er_fail(1u64)
    case True{}:
      +p0 = sr_pnth(vpts, i0)
      sr_edge_v03(sr_p_ok(p0), sr_p_v(p0), st, xs, vpts, i0)

def sr_edge_v0(+w: Bool, +a: SA, +st: ST, +xs: List<&2, SA>, +vpts: List<&2, V.Point>) -> SR_ER:
  match w:
    case False{}: sr_er_fail(1u64)
    case True{}:
      +r0 = sr_rank_of(st, a, 15u64)
      sr_edge_v02(sr_i_ok(r0), sr_i_v(r0), st, xs, vpts)

def sr_edge_x(+w: Bool, +xs: List<&2, SA>, +st: ST, +vpts: List<&2, V.Point>) -> SR_ER:
  match w:
    case False{}: sr_er_fail(1u64)
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_edge_v0(sr_a_ok(r), sr_a_v(r), st, xs, vpts)

def sr_edge_row(+st: ST, +h: SE, +vpts: List<&2, V.Point>) -> SR_ER:
  SE{+id, +ps} = h
  +r = sr_p0(ps)
  sr_edge_x(sr_px_ok(r), sr_px_xs(r), st, vpts)

def sr_ew_rows(+r: SR_EW) -> List<&2, String>:
  EW{rows, e0s, e1s, ok, bad, why} = r
  rows

def sr_ew_e0s(+r: SR_EW) -> List<&2, Nat>:
  EW{rows, e0s, e1s, ok, bad, why} = r
  e0s

def sr_ew_e1s(+r: SR_EW) -> List<&2, Nat>:
  EW{rows, e0s, e1s, ok, bad, why} = r
  e1s

def sr_ew_ok(+r: SR_EW) -> Bool:
  EW{rows, e0s, e1s, ok, bad, why} = r
  ok

def sr_ew_bad(+r: SR_EW) -> U64:
  EW{rows, e0s, e1s, ok, bad, why} = r
  bad

def sr_ew_why(+r: SR_EW) -> U64:
  EW{rows, e0s, e1s, ok, bad, why} = r
  why

def sr_ew_hit2(+w: Bool, +er: SR_ER, +id: U64, +rows: List<&2, String>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +bad: U64, +why: U64) -> SR_EW:
  match w:
    case True{}: EW{sr_er_row(er) <> rows, sr_er_e0(er) <> e0s, sr_er_e1(er) <> e1s, True{}, bad,
      why}
    case False{}: EW{rows, e0s, e1s, False{}, id, sr_er_why(er)}

def sr_ew_hit(+er: SR_ER, +id: U64, +rows: List<&2, String>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +ok: Bool, +bad: U64, +why: U64) -> SR_EW:
  match ok:
    case False{}: EW{rows, e0s, e1s, False{}, bad, why}
    case True{}: sr_ew_hit2(sr_er_ok(er), er, id, rows, e0s, e1s, bad, why)

def sr_ew_m(+kind: U64, +h: SE, +st: ST, +vpts: List<&2, V.Point>, +rows: List<&2, String>,
    +e0s: List<&2, Nat>, +e1s: List<&2, Nat>, +ok: Bool, +bad: U64, +why: U64) -> SR_EW:
  match kind:
    case 16u64: sr_ew_hit(sr_edge_row(st, h, vpts), sr_se_id(h), rows, e0s, e1s, ok, bad, why)
    case _: EW{rows, e0s, e1s, ok, bad, why}

def sr_ew_nx(+kind: U64, +h: SE, +st: ST, +vpts: List<&2, V.Point>, +ew: SR_EW) -> SR_EW:
  match ew:
    case EW{+rows, +e0s, +e1s, +ok, +bad, +why}: sr_ew_m(kind, h, st, vpts, rows, e0s, e1s, ok,
      bad, why)

def sr_ew_go(es: List<&2, SE>, +st: ST, +vpts: List<&2, V.Point>, +ew: SR_EW) -> SR_EW:
  match es:
    case []: ew
    case +h <> t: sr_ew_go(t, st, vpts, sr_ew_nx(sr_kind_of(h), h, st, vpts, ew))

def sr_erows(+es: List<&2, SE>, +st: ST, +vpts: List<&2, V.Point>) -> SR_EW:
  sr_ew_go(es, st, vpts, EW{[], [], [], True{}, 0u64, 0u64})

def sr_se_ps(+e: SE) -> List<&2, SPt>:
  SE{+id, +ps} = e
  ps

def sr_why_curve5(+a: SA) -> U64:
  match a:
    case SA_ref{+cid}: cid
    case _: 0u64

def sr_bdrank_k(+kind: U64, +k: KR) -> SR_I:
  match kind:
    case 19u64: SR_I{True{}, sr_kr_rank(k)}
    case 26u64: SR_I{True{}, sr_kr_rank(k)}
    case _: SR_I{False{}, 0n}

def sr_bdrank_f(+w: Bool, +st: ST, +pos: Nat) -> SR_I:
  match w:
    case False{}: SR_I{False{}, 0n}
    case True{}:
      +k = sr_kr_at(st, pos)
      sr_bdrank_k(sr_kr_kind(k), k)

def sr_bdrank_id(+st: ST, +id: U64) -> SR_I:
  +f = sr_find(st, id)
  sr_bdrank_f(sr_f_ok(f), st, sr_f_pos(f))

def sr_bdrank_of(+st: ST, +a: SA) -> SR_I:
  match a:
    case SA_ref{+id}: sr_bdrank_id(st, id)
    case _: SR_I{False{}, 0n}

def sr_bds_go(xs: List<&2, SA>, +st: ST, +acc: List<&2, Nat>, +ok: Bool) -> SR_RL:
  match xs:
    case []: SR_RL{ok, List.reverse(&2, Nat, acc)}
    case +a <> t:
      +r = sr_bdrank_of(st, a)
      sr_bds_go(t, st, sr_rl_acc(ok, sr_i_ok(r), r, acc), Bool.and(ok, sr_i_ok(r)))

def sr_bds(+st: ST, +a: SA) -> SR_RL:
  match a:
    case SA_ls{+xs}: sr_bds_go(xs, st, [], True{})
    case _: SR_RL{False{}, []}

def sr_nstrs_go(xs: List<&2, Nat>, +acc: List<&2, String>) -> List<&2, String>:
  match xs:
    case []: List.reverse(&2, String, acc)
    case h <> t: sr_nstrs_go(t, Nat.show(h) <> acc)

def sr_nstrs(xs: List<&2, Nat>) -> List<&2, String>:
  sr_nstrs_go(xs, [])

def sr_fc_ok(+r: SR_FC) -> Bool:
  SR_FC{ok, row, g, ces, bds, why} = r
  ok

def sr_fc_row(+r: SR_FC) -> String:
  SR_FC{ok, row, g, ces, bds, why} = r
  row

def sr_fc_g(+r: SR_FC) -> G.GVal:
  SR_FC{ok, row, g, ces, bds, why} = r
  g

def sr_fc_ces(+r: SR_FC) -> List<&2, CE_F>:
  SR_FC{ok, row, g, ces, bds, why} = r
  ces

def sr_fc_bds(+r: SR_FC) -> List<&2, BD_F>:
  SR_FC{ok, row, g, ces, bds, why} = r
  bds

def sr_fc_why(+r: SR_FC) -> U64:
  SR_FC{ok, row, g, ces, bds, why} = r
  why

def sr_fc_fail(+why: U64) -> SR_FC:
  SR_FC{False{}, "", G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 0.0f64, 0.0f64}}}, [], [], why}

def sr_bp_ok(+r: SR_BP) -> Bool:
  SR_BP{ok, ces, bds, why} = r
  ok

def sr_bp_ces(+r: SR_BP) -> List<&2, CE_F>:
  SR_BP{ok, ces, bds, why} = r
  ces

def sr_bp_bds(+r: SR_BP) -> List<&2, BD_F>:
  SR_BP{ok, ces, bds, why} = r
  bds

def sr_bp_why(+r: SR_BP) -> U64:
  SR_BP{ok, ces, bds, why} = r
  why

def sr_bp_fail(+why: U64) -> SR_BP:
  SR_BP{False{}, [], [], why}

def sr_bp_ces3(xs: List<&2, Nat>, +fa: Nat, +flip: Bool, +ces: List<&2, CE_F>) ->
    List<&2, CE_F>:
  match xs:
    case []: ces
    case h <> t: sr_bp_ces3(t, fa, flip, CE_F{h, fa, flip} <> ces)

def sr_bp_ces2(+w: Bool, +xs: List<&2, Nat>, +fa: Nat, +flip: Bool, +bd: Nat, +first: Bool,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match w:
    case False{}: sr_bp_fail(5u64)
    case True{}: SR_BP{True{}, sr_bp_ces3(xs, fa, flip, ces), BD_F{bd, first, flip} <> bds, 0u64}

def sr_rl_ok(+r: SR_RL) -> Bool:
  SR_RL{ok, xs} = r
  ok

def sr_rl_xs(+r: SR_RL) -> List<&2, Nat>:
  SR_RL{ok, xs} = r
  xs

def sr_bp_loop2(+w: Bool, +a: SA, +st: ST, +fa: Nat, +flip: Bool, +bd: Nat, +first: Bool,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match w:
    case False{}: sr_bp_fail(5u64)
    case True{}:
      +r = sr_reflist(st, a, 17u64)
      sr_bp_ces2(sr_rl_ok(r), sr_rl_xs(r), fa, flip, bd, first, ces, bds)

def sr_bp_loop(+w: Bool, +xs: List<&2, SA>, +st: ST, +fa: Nat, +flip: Bool, +bd: Nat,
    +first: Bool, +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match w:
    case False{}: sr_bp_fail(5u64)
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_bp_loop2(sr_a_ok(r), sr_a_v(r), st, fa, flip, bd, first, ces, bds)

def sr_bp_lkind(+kind: U64, +e: SE, +st: ST, +fa: Nat, +flip: Bool, +bd: Nat, +first: Bool,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match kind:
    case 18u64:
      SE{+id, +ps} = e
      +r = sr_p0(ps)
      sr_bp_loop(sr_px_ok(r), sr_px_xs(r), st, fa, flip, bd, first, ces, bds)
    case 23u64: sr_bp_fail(6u64)
    case _: sr_bp_fail(5u64)

def sr_bp_lpos(+w: Bool, +st: ST, +pos: Nat, +fa: Nat, +flip: Bool, +bd: Nat, +first: Bool,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match w:
    case False{}: sr_bp_fail(5u64)
    case True{}: sr_bp_lkind(sr_kr_kind(sr_kr_at(st, pos)), sr_ent_at(st, pos), st, fa, flip,
      bd, first, ces, bds)

def sr_bp_lref(+a: SA, +st: ST, +fa: Nat, +flip: Bool, +bd: Nat, +first: Bool,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match a:
    case SA_ref{+lid}:
      +f = sr_find(st, lid)
      sr_bp_lpos(sr_f_ok(f), st, sr_f_pos(f), fa, flip, bd, first, ces, bds)
    case _: sr_bp_fail(5u64)

def sr_bp_ori3(+w: Bool, +a: SA, +st: ST, +fa: Nat, +flip: Bool, +bd: Nat, +first: Bool,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match w:
    case False{}: sr_bp_fail(5u64)
    case True{}: sr_bp_lref(a, st, fa, flip, bd, first, ces, bds)

def sr_bp_ori2(+w: Bool, +sense: Bool, +xs: List<&2, SA>, +st: ST, +fa: Nat, +bd: Nat,
    +first: Bool, +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match w:
    case False{}: sr_bp_fail(5u64)
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_bp_ori3(sr_a_ok(r), sr_a_v(r), st, fa, Bool.not(sense), bd, first, ces, bds)

def sr_bp_ori(+w: Bool, +a: SA, +xs: List<&2, SA>, +st: ST, +fa: Nat, +bd: Nat, +first: Bool,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match w:
    case False{}: sr_bp_fail(5u64)
    case True{}:
      +r = sr_en_of(a)
      sr_bp_ori2(sr_b_ok(r), sr_b_v(r), xs, st, fa, bd, first, ces, bds)

def sr_bp_one3(+w: Bool, +xs: List<&2, SA>, +st: ST, +fa: Nat, +bd: Nat, +first: Bool,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match w:
    case False{}: sr_bp_fail(5u64)
    case True{}:
      +r = sr_nth(xs, 2n)
      sr_bp_ori(sr_a_ok(r), sr_a_v(r), xs, st, fa, bd, first, ces, bds)

def sr_bp_one2(+w: Bool, +st: ST, +pos: Nat, +fa: Nat, +bd: Nat, +first: Bool,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>) -> SR_BP:
  match w:
    case False{}: sr_bp_fail(5u64)
    case True{}:
      +r = sr_p0(sr_se_ps(sr_ent_at(st, pos)))
      sr_bp_one3(sr_px_ok(r), sr_px_xs(r), st, fa, bd, first, ces, bds)

def sr_bp_one(+id: U64, +st: ST, +fa: Nat, +bd: Nat, +first: Bool, +ces: List<&2, CE_F>,
    +bds: List<&2, BD_F>) -> SR_BP:
  +f = sr_find(st, id)
  sr_bp_one2(sr_f_ok(f), st, sr_f_pos(f), fa, bd, first, ces, bds)

def sr_bp_go(ids: List<&2, U64>, +ranks: List<&2, Nat>, +st: ST, +fa: Nat, +first: Bool,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>, +ok: Bool, +why: U64) -> SR_BP:
  match ids:
    case []: SR_BP{ok, ces, bds, why}
    case +id <> tids:
      match ranks:
        case []: SR_BP{False{}, [], [], 5u64}
        case +bd <> tranks:
          match ok:
            case False{}: SR_BP{False{}, [], [], why}
            case True{}:
              +r = sr_bp_one(id, st, fa, bd, first, ces, bds)
              sr_bp_go(tids, tranks, st, fa, False{}, sr_bp_ces(r), sr_bp_bds(r), sr_bp_ok(r),
                sr_bp_why(r))

def sr_face_bp5(+w: Bool, +ids: List<&2, U64>, +st: ST, +fa: Nat, +ranks: List<&2, Nat>) ->
    SR_BP:
  match w:
    case False{}: sr_bp_fail(1u64)
    case True{}: sr_bp_go(ids, ranks, st, fa, True{}, [], [], True{}, 0u64)

def sr_refs_of_list(ys: List<&2, SA>) -> SR_UL:
  sr_refs_go(ys, [], True{})

def sr_face_bp4(ys: List<&2, SA>, +st: ST, +fa: Nat, +ranks: List<&2, Nat>) -> SR_BP:
  +r = sr_refs_of_list(ys)
  sr_face_bp5(sr_ul_ok(r), sr_ul_xs(r), st, fa, ranks)

def sr_face_bp3(+a: SA, +st: ST, +fa: Nat, +ranks: List<&2, Nat>) -> SR_BP:
  match a:
    case SA_ls{+ys}: sr_face_bp4(ys, st, fa, ranks)
    case _: sr_bp_fail(1u64)

def sr_face_bp2(+w: Bool, +a: SA, +st: ST, +fa: Nat, +ranks: List<&2, Nat>) -> SR_BP:
  match w:
    case False{}: sr_bp_fail(1u64)
    case True{}: sr_face_bp3(a, st, fa, ranks)

def sr_face_bp(+xs: List<&2, SA>, +st: ST, +fa: Nat, +ranks: List<&2, Nat>) -> SR_BP:
  +r = sr_nth(xs, 1n)
  sr_face_bp2(sr_a_ok(r), sr_a_v(r), st, fa, ranks)

def sr_face_done(+bp: SR_BP, +sf: BL.ES, +same: Bool, +ranks: List<&2, Nat>, +g: G.GVal) ->
    SR_FC:
  SR_FC{sr_bp_ok(bp), BL.es_s(sf) ++ "," ++ BL.bit_s(same) ++ "," ++
    Nat.show(List.length(&2, Nat, ranks)) ++ BL.jn_tail(sr_nstrs(ranks), ","), g, sr_bp_ces(bp),
    sr_bp_bds(bp), sr_bp_why(bp)}

def sr_face_bp6(+w: Bool, +bp: SR_BP, +sf: BL.ES, +same: Bool, +ranks: List<&2, Nat>,
    +g: G.GVal) -> SR_FC:
  match w:
    case False{}: sr_fc_fail(sr_bp_why(bp))
    case True{}: sr_face_done(bp, sf, same, ranks, g)

def sr_face_sf(+w: Bool, +sf: BL.ES, +xs: List<&2, SA>, +st: ST, +fa: Nat, +same: Bool,
    +ranks: List<&2, Nat>, +g: G.GVal) -> SR_FC:
  match w:
    case False{}: sr_fc_fail(4u64)
    case True{}:
      +bp = sr_face_bp(xs, st, fa, ranks)
      sr_face_bp6(sr_bp_ok(bp), bp, sf, same, ranks, g)

def sr_s_g(+r: SR_S) -> G.GVal:
  SR_S{ok, g} = r
  g
def sr_face_sg(+w: Bool, +sg: SR_S, +xs: List<&2, SA>, +st: ST, +fa: Nat, +same: Bool,
    +ranks: List<&2, Nat>) -> SR_FC:
  match w:
    case False{}: sr_fc_fail(3u64)
    case True{}:
      +sf = sr_sf_of(sr_s_g(sg))
      sr_face_sf(BL.es_ok_of(sf), sf, xs, st, fa, same, ranks, sr_s_g(sg))

def sr_s_ok(+r: SR_S) -> Bool:
  SR_S{ok, g} = r
  ok

def sr_face_su2(+a: SA, +xs: List<&2, SA>, +st: ST, +fa: Nat, +same: Bool,
    +ranks: List<&2, Nat>) -> SR_FC:
  match a:
    case SA_ref{+sid}:
      +sg = sr_surf_of(st, sid)
      sr_face_sg(sr_s_ok(sg), sg, xs, st, fa, same, ranks)
    case _: sr_fc_fail(3u64)

def sr_face_su(+w: Bool, +a: SA, +xs: List<&2, SA>, +st: ST, +fa: Nat, +same: Bool,
    +ranks: List<&2, Nat>) -> SR_FC:
  match w:
    case False{}: sr_fc_fail(3u64)
    case True{}: sr_face_su2(a, xs, st, fa, same, ranks)

def sr_face_se(+w: Bool, +same: Bool, +xs: List<&2, SA>, +st: ST, +fa: Nat,
    +ranks: List<&2, Nat>) -> SR_FC:
  match w:
    case False{}: sr_fc_fail(2u64)
    case True{}:
      +r = sr_nth(xs, 2n)
      sr_face_su(sr_a_ok(r), sr_a_v(r), xs, st, fa, same, ranks)

def sr_face_sn(+w: Bool, +a: SA, +xs: List<&2, SA>, +st: ST, +fa: Nat, +ranks: List<&2, Nat>) ->
    SR_FC:
  match w:
    case False{}: sr_fc_fail(2u64)
    case True{}:
      +r = sr_en_of(a)
      sr_face_se(sr_b_ok(r), sr_b_v(r), xs, st, fa, ranks)

def sr_face_bd3(+w: Bool, +ranks: List<&2, Nat>, +xs: List<&2, SA>, +st: ST, +fa: Nat) -> SR_FC:
  match w:
    case False{}: sr_fc_fail(1u64)
    case True{}:
      +r = sr_nth(xs, 3n)
      sr_face_sn(sr_a_ok(r), sr_a_v(r), xs, st, fa, ranks)

def sr_face_bd2(+w: Bool, +a: SA, +xs: List<&2, SA>, +st: ST, +fa: Nat) -> SR_FC:
  match w:
    case False{}: sr_fc_fail(1u64)
    case True{}:
      +r = sr_bds(st, a)
      sr_face_bd3(sr_rl_ok(r), sr_rl_xs(r), xs, st, fa)

def sr_face_bd(+w: Bool, +xs: List<&2, SA>, +st: ST, +fa: Nat) -> SR_FC:
  match w:
    case False{}: sr_fc_fail(1u64)
    case True{}:
      +rb = sr_nth(xs, 1n)
      sr_face_bd2(sr_a_ok(rb), sr_a_v(rb), xs, st, fa)

def sr_face_x(+w: Bool, +xs: List<&2, SA>, +st: ST, +fa: Nat) -> SR_FC:
  match w:
    case False{}: sr_fc_fail(1u64)
    case True{}: sr_face_bd(True{}, xs, st, fa)

def sr_face_row(+st: ST, +h: SE, +fa: Nat) -> SR_FC:
  SE{+id, +ps} = h
  +r = sr_p0(ps)
  sr_face_x(sr_px_ok(r), sr_px_xs(r), st, fa)

def sr_fw_rows(+r: SR_FW) -> List<&2, String>:
  FW{rows, surfs, ces, bds, ok, bad, why, nfa} = r
  rows

def sr_fw_surfs(+r: SR_FW) -> List<&2, G.GVal>:
  FW{rows, surfs, ces, bds, ok, bad, why, nfa} = r
  surfs

def sr_fw_ces(+r: SR_FW) -> List<&2, CE_F>:
  FW{rows, surfs, ces, bds, ok, bad, why, nfa} = r
  ces

def sr_fw_bds(+r: SR_FW) -> List<&2, BD_F>:
  FW{rows, surfs, ces, bds, ok, bad, why, nfa} = r
  bds

def sr_fw_ok(+r: SR_FW) -> Bool:
  FW{rows, surfs, ces, bds, ok, bad, why, nfa} = r
  ok

def sr_fw_bad(+r: SR_FW) -> U64:
  FW{rows, surfs, ces, bds, ok, bad, why, nfa} = r
  bad

def sr_fw_why(+r: SR_FW) -> U64:
  FW{rows, surfs, ces, bds, ok, bad, why, nfa} = r
  why

def sr_fw_hit2(+w: Bool, +fc: SR_FC, +id: U64, +rows: List<&2, String>,
    +surfs: List<&2, G.GVal>, +ces: List<&2, CE_F>, +bds: List<&2, BD_F>, +bad: U64, +why: U64,
    +nfa: Nat) -> SR_FW:
  match w:
    case True{}: FW{sr_fc_row(fc) <> rows, sr_fc_g(fc) <> surfs,
      List.append(&2, CE_F, sr_fc_ces(fc), ces), List.append(&2, BD_F, sr_fc_bds(fc), bds),
      True{}, bad, why, Nat.add(nfa, 1n)}
    case False{}: FW{rows, surfs, ces, bds, False{}, id, sr_fc_why(fc), nfa}

def sr_fw_hit(+fc: SR_FC, +id: U64, +rows: List<&2, String>, +surfs: List<&2, G.GVal>,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>, +ok: Bool, +bad: U64, +why: U64, +nfa: Nat) ->
    SR_FW:
  match ok:
    case False{}: FW{rows, surfs, ces, bds, False{}, bad, why, nfa}
    case True{}: sr_fw_hit2(sr_fc_ok(fc), fc, id, rows, surfs, ces, bds, bad, why, nfa)

def sr_fw_m(+kind: U64, +h: SE, +st: ST, +rows: List<&2, String>, +surfs: List<&2, G.GVal>,
    +ces: List<&2, CE_F>, +bds: List<&2, BD_F>, +ok: Bool, +bad: U64, +why: U64, +nfa: Nat) ->
    SR_FW:
  match kind:
    case 20u64: sr_fw_hit(sr_face_row(st, h, nfa), sr_se_id(h), rows, surfs, ces, bds, ok, bad,
      why, nfa)
    case _: FW{rows, surfs, ces, bds, ok, bad, why, nfa}

def sr_fw_nx(+kind: U64, +h: SE, +st: ST, +fw: SR_FW) -> SR_FW:
  match fw:
    case FW{+rows, +surfs, +ces, +bds, +ok, +bad, +why, +nfa}: sr_fw_m(kind, h, st, rows, surfs,
      ces, bds, ok, bad, why, nfa)

def sr_fw_go(es: List<&2, SE>, +st: ST, +fw: SR_FW) -> SR_FW:
  match es:
    case []: fw
    case +h <> t: sr_fw_go(t, st, sr_fw_nx(sr_kind_of(h), h, st, fw))

def sr_frows(+es: List<&2, SE>, +st: ST) -> SR_FW:
  sr_fw_go(es, st, FW{[], [], [], [], True{}, 0u64, 0u64, 0n})

def sr_why_curve4(+w: Bool, +a: SA) -> U64:
  match w:
    case False{}: 0u64
    case True{}: sr_why_curve5(a)

def sr_why_surf3(+w: Bool, +xs: List<&2, SA>) -> U64:
  match w:
    case False{}: 0u64
    case True{}:
      +r = sr_nth(xs, 2n)
      sr_why_curve4(sr_a_ok(r), sr_a_v(r))

def sr_loop_lx2(+w: Bool, +a: SA, +st: ST) -> SR_RL:
  match w:
    case False{}: SR_RL{False{}, []}
    case True{}: sr_reflist(st, a, 17u64)

def sr_loop_lx(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_RL:
  match w:
    case False{}: SR_RL{False{}, []}
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_loop_lx2(sr_a_ok(r), sr_a_v(r), st)

def sr_loop_lk(+kind: U64, +e: SE, +st: ST) -> SR_RL:
  match kind:
    case 18u64:
      SE{+id, +ps} = e
      +r = sr_p0(ps)
      sr_loop_lx(sr_px_ok(r), sr_px_xs(r), st)
    case _: SR_RL{False{}, []}

def sr_loop_lp(+w: Bool, +st: ST, +pos: Nat) -> SR_RL:
  match w:
    case False{}: SR_RL{False{}, []}
    case True{}: sr_loop_lk(sr_kr_kind(sr_kr_at(st, pos)), sr_ent_at(st, pos), st)

def sr_loop_lr(+a: SA, +st: ST) -> SR_RL:
  match a:
    case SA_ref{+lid}:
      +f = sr_find(st, lid)
      sr_loop_lp(sr_f_ok(f), st, sr_f_pos(f))
    case _: SR_RL{False{}, []}

def sr_loop_bx2(+w: Bool, +a: SA, +st: ST) -> SR_RL:
  match w:
    case False{}: SR_RL{False{}, []}
    case True{}: sr_loop_lr(a, st)

def sr_loop_bx(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_RL:
  match w:
    case False{}: SR_RL{False{}, []}
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_loop_bx2(sr_a_ok(r), sr_a_v(r), st)

def sr_loop_ces(+h: SE, +st: ST) -> SR_RL:
  SE{+id, +ps} = h
  +r = sr_p0(ps)
  sr_loop_bx(sr_px_ok(r), sr_px_xs(r), st)

def sr_lw_rows(+r: SR_LW) -> List<&2, String>:
  LW{rows, ok, bad, why} = r
  rows

def sr_lw_ok(+r: SR_LW) -> Bool:
  LW{rows, ok, bad, why} = r
  ok

def sr_lw_bad(+r: SR_LW) -> U64:
  LW{rows, ok, bad, why} = r
  bad

def sr_lw_why(+r: SR_LW) -> U64:
  LW{rows, ok, bad, why} = r
  why

def sr_lw_kind2(+first: Bool) -> Nat:
  match first:
    case True{}: 0n
    case False{}: 1n

def sr_lw_kind(+outer: Bool, +first: Bool) -> Nat:
  match outer:
    case True{}: 0n
    case False{}: sr_lw_kind2(first)

def sr_lw_ord(+flip: Bool, +xs: List<&2, Nat>) -> List<&2, Nat>:
  match flip:
    case True{}: List.reverse(&2, Nat, xs)
    case False{}: xs

def sr_lw_row(+outer: Bool, +first: Bool, +flip: Bool, +xs: List<&2, Nat>) -> String:
  +ys = sr_lw_ord(flip, xs)
  Nat.show(sr_lw_kind(outer, first)) ++ "," ++ Nat.show(List.length(&2, Nat, ys)) ++
    BL.jn_tail(sr_nstrs(ys), ",")

def sr_lw_ces(+w: Bool, +r: SR_RL, +outer: Bool, +first: Bool, +flip: Bool, +ps: List<&2, BD_F>,
    +nlp: Nat, +rows: List<&2, String>, +bad: U64, +why: U64, +id: U64,
    +vls: List<&2, VL_F>) -> SR_LS2:
  match w:
    case False{}: LS2{ps, Nat.add(nlp, 1n), rows, False{}, id, 5u64, vls}
    case True{}: LS2{ps, Nat.add(nlp, 1n), sr_lw_row(outer, first, flip, sr_rl_xs(r)) <> rows,
      True{}, bad, why, vls}

def sr_bd_b(+r: BD_F) -> Nat:
  BD_F{bd, first, flip} = r
  bd

def sr_bd_first(+r: BD_F) -> Bool:
  BD_F{bd, first, flip} = r
  first

def sr_bd_flip(+r: BD_F) -> Bool:
  BD_F{bd, first, flip} = r
  flip

def sr_lw_ck2(+lt: Bool, +p: BD_F, +ps: List<&2, BD_F>, +h: SE, +nlp: Nat,
    +rows: List<&2, String>, +why: U64, +vls: List<&2, VL_F>) -> SR_LS2:
  match lt:
    case True{}: LS2{ps, Nat.add(nlp, 1n), rows, False{}, sr_se_id(h), 7u64, vls}
    case False{}: LS2{p <> ps, Nat.add(nlp, 1n), rows, False{}, sr_se_id(h), 8u64, vls}

def sr_lw_ck(+w: Bool, +p: BD_F, +ps: List<&2, BD_F>, +outer: Bool, +h: SE, +st: ST, +nlp: Nat,
    +rows: List<&2, String>, +bad: U64, +why: U64, +vls: List<&2, VL_F>) -> SR_LS2:
  match w:
    case False{}: sr_lw_ck2(Nat.is_lt(sr_bd_b(p), nlp), p, ps, h, nlp, rows, why, vls)
    case True{}:
      +r = sr_loop_ces(h, st)
      sr_lw_ces(sr_rl_ok(r), r, outer, sr_bd_first(p), sr_bd_flip(p), ps, nlp, rows, bad, why,
        sr_se_id(h), vls)

def sr_lw_bds(+bds: List<&2, BD_F>, +outer: Bool, +h: SE, +st: ST, +nlp: Nat,
    +rows: List<&2, String>, +bad: U64, +why: U64, +vls: List<&2, VL_F>) -> SR_LS2:
  match bds:
    case []: LS2{[], Nat.add(nlp, 1n), rows, False{}, sr_se_id(h), 8u64, vls}
    case +p <> ps:
      match p:
        case BD_F{+bd, +first, +flip}: sr_lw_ck(Nat.is_eq(bd, nlp), p, ps, outer, h, st, nlp,
          rows, bad, why, vls)

def sr_lw_pole_m(+m: Bool, +v: VL_F, +t: List<&2, VL_F>, +outer: Bool, +h: SE,
    +bds: List<&2, BD_F>, +nlp: Nat, +rows: List<&2, String>) -> SR_LS2:
  match m:
    case False{}: LS2{bds, Nat.add(nlp, 1n), rows, False{}, sr_se_id(h), 8u64, v <> t}
    case True{}: LS2{bds, Nat.add(nlp, 1n), sr_lw_row(outer, sr_vl_first(v), False{}, []) <> rows,
      True{}, 0u64, 0u64, t}

def sr_lw_pole(+outer: Bool, +h: SE, +st: ST, +bds: List<&2, BD_F>, +nlp: Nat,
    +rows: List<&2, String>, +vls: List<&2, VL_F>) -> SR_LS2:
  match vls:
    case []: LS2{bds, Nat.add(nlp, 1n), rows, False{}, sr_se_id(h), 8u64, []}
    case +v <> t: sr_lw_pole_m(Nat.is_eq(sr_vl_bd(v), nlp), v, t, outer, h, bds, nlp, rows)

def sr_lw_lk(+lk: U64, +outer: Bool, +h: SE, +st: ST, +bds: List<&2, BD_F>, +nlp: Nat,
    +rows: List<&2, String>, +bad: U64, +why: U64, +vls: List<&2, VL_F>) -> SR_LS2:
  match lk:
    case 18u64: sr_lw_bds(bds, outer, h, st, nlp, rows, bad, why, vls)
    case 23u64: sr_lw_pole(outer, h, st, bds, nlp, rows, vls)
    case _: LS2{bds, Nat.add(nlp, 1n), rows, False{}, sr_se_id(h), 5u64, vls}

def sr_lw_hit(+outer: Bool, +h: SE, +st: ST, +bds: List<&2, BD_F>, +nlp: Nat,
    +rows: List<&2, String>, +ok: Bool, +bad: U64, +why: U64, +vls: List<&2, VL_F>) -> SR_LS2:
  match ok:
    case False{}: LS2{bds, Nat.add(nlp, 1n), rows, False{}, bad, why, vls}
    case True{}: sr_lw_lk(sr_bloop_kind(h, st), outer, h, st, bds, nlp, rows, bad, why, vls)

def sr_lw_m(+kind: U64, +h: SE, +st: ST, +bds: List<&2, BD_F>, +nlp: Nat,
    +rows: List<&2, String>, +ok: Bool, +bad: U64, +why: U64, +vls: List<&2, VL_F>) -> SR_LS2:
  match kind:
    case 19u64: sr_lw_hit(False{}, h, st, bds, nlp, rows, ok, bad, why, vls)
    case 26u64: sr_lw_hit(True{}, h, st, bds, nlp, rows, ok, bad, why, vls)
    case _: LS2{bds, nlp, rows, ok, bad, why, vls}

def sr_lw_nx(+kind: U64, +h: SE, +st: ST, +lw: SR_LS2) -> SR_LS2:
  match lw:
    case LS2{+bds, +nlp, +rows, +ok, +bad, +why, +vls}: sr_lw_m(kind, h, st, bds, nlp, rows, ok,
      bad, why, vls)

def sr_lw_fin4(+vls: List<&2, VL_F>, +rows: List<&2, String>, +bad: U64, +why: U64) -> SR_LW:
  match vls:
    case []: LW{rows, True{}, bad, why}
    case _ <> _: LW{rows, False{}, bad, 7u64}

def sr_lw_fin3(+bds: List<&2, BD_F>, +vls: List<&2, VL_F>, +rows: List<&2, String>, +bad: U64,
    +why: U64) -> SR_LW:
  match bds:
    case []: sr_lw_fin4(vls, rows, bad, why)
    case _ <> _: LW{rows, False{}, bad, 7u64}

def sr_lw_fin2(+ok: Bool, +bds: List<&2, BD_F>, +vls: List<&2, VL_F>, +rows: List<&2, String>,
    +bad: U64, +why: U64) -> SR_LW:
  match ok:
    case False{}: LW{rows, False{}, bad, why}
    case True{}: sr_lw_fin3(bds, vls, rows, bad, why)

def sr_lw_fin(+lw: SR_LS2) -> SR_LW:
  match lw:
    case LS2{+bds, +nlp, +rows, +ok, +bad, +why, +vls}: sr_lw_fin2(ok, bds, vls, rows, bad, why)

def sr_lw_go(es: List<&2, SE>, +st: ST, +lw: SR_LS2) -> SR_LW:
  match es:
    case []: sr_lw_fin(lw)
    case +h <> t: sr_lw_go(t, st, sr_lw_nx(sr_kind_of(h), h, st, lw))

def sr_lrows_vl(+w: Bool, +vl: SR_VL, +es: List<&2, SE>, +st: ST, +bds: List<&2, BD_F>) -> SR_LW:
  match w:
    case False{}: LW{[], False{}, sr_vl_bad(vl), 9u64}
    case True{}: sr_lw_go(es, st, LS2{bds, 0n, [], True{}, 0u64, 0u64, sr_vl_xs(vl)})

def sr_lrows(+es: List<&2, SE>, +st: ST, +bds: List<&2, BD_F>) -> SR_LW:
  +vl = sr_vls(es, st)
  sr_lrows_vl(sr_vl_ok(vl), vl, es, st, bds)

def sr_proj(+p: V.Point, +o: V.Point, +u: V.Dir, +v: V.Dir) -> V.Vec2:
  V.Pt{+px, +py, +pz} = p
  V.Pt{+ox, +oy, +oz} = o
  V.Dr{+ux, +uy, +uz} = u
  V.Dr{+vx, +vy, +vz} = v
  V.V2{sr_dot3(F64.sub(px, ox), F64.sub(py, oy), F64.sub(pz, oz), ux, uy, uz),
    sr_dot3(F64.sub(px, ox), F64.sub(py, oy), F64.sub(pz, oz), vx, vy, vz)}

def sr_ce_pl(+w: G.Plane3, +ps: V.Point, +pe: V.Point, +e: Nat, +fwd: Bool) -> String:
  match w:
    case G.Pl{+o, +u, +v}:
      +ts = sr_proj(ps, o, u, v)
      +te = sr_proj(pe, o, u, v)
      Nat.show(e) ++ "," ++ BL.bit_s(fwd) ++ ",0," ++ N.f_show(V.v2_x(ts)) ++ "," ++
        N.f_show(V.v2_y(ts)) ++ "," ++ N.f_show(V.v2_x(te)) ++ "," ++ N.f_show(V.v2_y(te))

def sr_ce_zero(+e: Nat, +fwd: Bool) -> String:
  Nat.show(e) ++ "," ++ BL.bit_s(fwd) ++ ",0,0,0,0,0"

def sr_ce_tm(+g: G.GVal, +ps: V.Point, +pe: V.Point, +e: Nat, +fwd: Bool) -> BL.ES:
  match g:
    case G.GV_pl{+w}: BL.es_ok(sr_ce_pl(w, ps, pe, e, fwd))
    case G.GV_sp{+w}: BL.es_ok(sr_ce_zero(e, fwd))
    case G.GV_cy{+w}: BL.es_ok(sr_ce_zero(e, fwd))
    case G.GV_to{+w}: BL.es_ok(sr_ce_zero(e, fwd))
    case _: BL.es_fail("step-trim-surface-not-in-profile")

def sr_ce_ends4(+w: Bool, +g: G.GVal, +v0c: V.Point, +v1c: V.Point, +e: Nat, +fwd: Bool) ->
    BL.ES:
  match w:
    case False{}: BL.es_fail("step-coedge-bad-face")
    case True{}: sr_ce_tm(g, v0c, v1c, e, fwd)

def sr_ce_ends3(+w: Bool, +v0c: V.Point, +v1c: V.Point, +fsurfs: List<&2, G.GVal>, +fa: Nat,
    +e: Nat, +fwd: Bool) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-coedge-bad-edge")
    case True{}:
      +g = sr_gnth(fsurfs, fa)
      sr_ce_ends4(sr_s_ok(g), sr_s_g(g), v0c, v1c, e, fwd)

def sr_ce_ends2(+w: Bool, +i0: Nat, +i1: Nat, +vpts: List<&2, V.Point>,
    +fsurfs: List<&2, G.GVal>, +fa: Nat, +e: Nat, +fwd: Bool) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-coedge-bad-edge")
    case True{}:
      +p0 = sr_pnth(vpts, i0)
      +p1 = sr_pnth(vpts, i1)
      sr_ce_ends3(Bool.and(sr_p_ok(p0), sr_p_ok(p1)), sr_p_v(p0), sr_p_v(p1), fsurfs, fa, e,
        fwd)

def sr_ce_ends(+vpts: List<&2, V.Point>, +e0s: List<&2, Nat>, +e1s: List<&2, Nat>,
    +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool, +e: Nat, +fwd: Bool) -> BL.ES:
  +r0 = sr_nnth(e0s, e)
  +r1 = sr_nnth(e1s, e)
  sr_ce_ends2(Bool.and(sr_i_ok(r0), sr_i_ok(r1)), sr_i_v(r0), sr_i_v(r1), vpts, fsurfs, fa, e,
    fwd)

def sr_ce_fwd(+flip: Bool, +fwd0: Bool) -> Bool:
  match flip:
    case True{}: Bool.not(fwd0)
    case False{}: fwd0

def sr_ce_fw2(+w: Bool, +fwd0: Bool, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool, +e: Nat) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-coedge-bad-sense")
    case True{}: sr_ce_ends(vpts, e0s, e1s, fsurfs, fa, flip, e, sr_ce_fwd(flip, fwd0))

def sr_ce_fw(+w: Bool, +a: SA, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool, +e: Nat) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-coedge-bad-sense")
    case True{}:
      +r = sr_en_of(a)
      sr_ce_fw2(sr_b_ok(r), sr_b_v(r), vpts, e0s, e1s, fsurfs, fa, flip, e)

def sr_ce_e4(+w: Bool, +e: Nat, +ss: SA, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-coedge-bad-edge")
    case True{}: sr_ce_fw(True{}, ss, vpts, e0s, e1s, fsurfs, fa, flip, e)

def sr_ce_e3(+w: Bool, +st: ST, +pos: Nat, +ss: SA, +vpts: List<&2, V.Point>,
    +e0s: List<&2, Nat>, +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool) ->
    BL.ES:
  match w:
    case False{}: BL.es_fail("step-coedge-bad-edge")
    case True{}:
      +k = sr_kr_at(st, pos)
      sr_ce_e4(U64.is_eq(sr_kr_kind(k), 16u64), sr_kr_rank(k), ss, vpts, e0s, e1s, fsurfs, fa,
        flip)

def sr_ce_e2(+a: SA, +st: ST, +ss: SA, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool) -> BL.ES:
  match a:
    case SA_ref{+eid}:
      +f = sr_find(st, eid)
      sr_ce_e3(sr_f_ok(f), st, sr_f_pos(f), ss, vpts, e0s, e1s, fsurfs, fa, flip)
    case _: BL.es_fail("step-coedge-bad-edge")

def sr_ce_e(+w: Bool, +a: SA, +st: ST, +ss: SA, +vpts: List<&2, V.Point>,
    +e0s: List<&2, Nat>, +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool) ->
    BL.ES:
  match w:
    case False{}: BL.es_fail("step-coedge-bad-edge")
    case True{}: sr_ce_e2(a, st, ss, vpts, e0s, e1s, fsurfs, fa, flip)

def sr_ce_xc(+is5: Bool, +xs: List<&2, SA>, +st: ST, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool) -> BL.ES:
  match is5:
    case False{}: BL.es_fail("step-coedge-bad-edge")
    case True{}:
      +re = sr_nth(xs, 3n)
      +rs = sr_nth(xs, 4n)
      sr_ce_e(sr_a_ok(re), sr_a_v(re), st, sr_a_v(rs), vpts, e0s, e1s, fsurfs, fa, flip)

def sr_ce_xb(+is3: Bool, +is5: Bool, +xs: List<&2, SA>, +st: ST, +vpts: List<&2, V.Point>,
    +e0s: List<&2, Nat>, +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool) ->
    BL.ES:
  match is3:
    case True{}:
      +re = sr_nth(xs, 1n)
      +rs = sr_nth(xs, 2n)
      sr_ce_e(sr_a_ok(re), sr_a_v(re), st, sr_a_v(rs), vpts, e0s, e1s, fsurfs, fa, flip)
    case False{}: sr_ce_xc(is5, xs, st, vpts, e0s, e1s, fsurfs, fa, flip)

def sr_ce_x(+w: Bool, +xs: List<&2, SA>, +st: ST, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-coedge-bad-edge")
    case True{}:
      +n = List.length(&2, SA, xs)
      sr_ce_xb(Nat.is_eq(n, 3n), Nat.is_eq(n, 5n), xs, st, vpts, e0s, e1s, fsurfs, fa, flip)

def sr_ce_row(+h: SE, +st: ST, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +fa: Nat, +flip: Bool) -> BL.ES:
  SE{+id, +ps} = h
  +r = sr_p0(ps)
  sr_ce_x(sr_px_ok(r), sr_px_xs(r), st, vpts, e0s, e1s, fsurfs, fa, flip)

def sr_cw_rows(+r: SR_CW) -> List<&2, String>:
  CW{rows, ok, bad, why} = r
  rows

def sr_cw_ok(+r: SR_CW) -> Bool:
  CW{rows, ok, bad, why} = r
  ok

def sr_cw_bad(+r: SR_CW) -> U64:
  CW{rows, ok, bad, why} = r
  bad

def sr_cw_why(+r: SR_CW) -> U64:
  CW{rows, ok, bad, why} = r
  why

def sr_ce_fa(+r: CE_F) -> Nat:
  CE_F{ce, fa, flip} = r
  fa

def sr_ce_flip(+r: CE_F) -> Bool:
  CE_F{ce, fa, flip} = r
  flip

def sr_ce_ce(+r: CE_F) -> Nat:
  CE_F{ce, fa, flip} = r
  ce

def sr_cw_row(+w: Bool, +er: BL.ES, +ps: List<&2, CE_F>, +nce: Nat, +rows: List<&2, String>,
    +bad: U64, +why: U64, +id: U64) -> SR_CS2:
  match w:
    case False{}: CS2{ps, Nat.add(nce, 1n), rows, False{}, id, 9u64}
    case True{}: CS2{ps, Nat.add(nce, 1n), BL.es_s(er) <> rows, True{}, bad, why}

def sr_cw_ck2(+lt: Bool, +p: CE_F, +ps: List<&2, CE_F>, +h: SE, +nce: Nat,
    +rows: List<&2, String>, +why: U64) -> SR_CS2:
  match lt:
    case True{}: CS2{ps, Nat.add(nce, 1n), rows, False{}, sr_se_id(h), 7u64}
    case False{}: CS2{p <> ps, Nat.add(nce, 1n), rows, False{}, sr_se_id(h), 8u64}

def sr_cw_ck(+w: Bool, +p: CE_F, +ps: List<&2, CE_F>, +h: SE, +st: ST, +vpts: List<&2, V.Point>,
    +e0s: List<&2, Nat>, +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +nce: Nat,
    +rows: List<&2, String>, +bad: U64, +why: U64) -> SR_CS2:
  match w:
    case False{}: sr_cw_ck2(Nat.is_lt(sr_ce_ce(p), nce), p, ps, h, nce, rows, why)
    case True{}:
      +er = sr_ce_row(h, st, vpts, e0s, e1s, fsurfs, sr_ce_fa(p), sr_ce_flip(p))
      sr_cw_row(BL.es_ok_of(er), er, ps, nce, rows, bad, why, sr_se_id(h))

def sr_cw_ces(+ces: List<&2, CE_F>, +h: SE, +st: ST, +vpts: List<&2, V.Point>,
    +e0s: List<&2, Nat>, +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +nce: Nat,
    +rows: List<&2, String>, +bad: U64, +why: U64) -> SR_CS2:
  match ces:
    case []: CS2{[], Nat.add(nce, 1n), rows, False{}, sr_se_id(h), 8u64}
    case +p <> ps:
      match p:
        case CE_F{+ce, +fa, +flip}: sr_cw_ck(Nat.is_eq(ce, nce), p, ps, h, st, vpts, e0s, e1s,
          fsurfs, nce, rows, bad, why)

def sr_cw_hit(+h: SE, +st: ST, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +ces: List<&2, CE_F>, +nce: Nat,
    +rows: List<&2, String>, +ok: Bool, +bad: U64, +why: U64) -> SR_CS2:
  match ok:
    case False{}: CS2{ces, Nat.add(nce, 1n), rows, False{}, bad, why}
    case True{}: sr_cw_ces(ces, h, st, vpts, e0s, e1s, fsurfs, nce, rows, bad, why)

def sr_cw_m(+kind: U64, +h: SE, +st: ST, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +ces: List<&2, CE_F>, +nce: Nat,
    +rows: List<&2, String>, +ok: Bool, +bad: U64, +why: U64) -> SR_CS2:
  match kind:
    case 17u64: sr_cw_hit(h, st, vpts, e0s, e1s, fsurfs, ces, nce, rows, ok, bad, why)
    case _: CS2{ces, nce, rows, ok, bad, why}

def sr_cw_nx(+kind: U64, +h: SE, +st: ST, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +cs: SR_CS2) -> SR_CS2:
  match cs:
    case CS2{+ces, +nce, +rows, +ok, +bad, +why}: sr_cw_m(kind, h, st, vpts, e0s, e1s, fsurfs,
      ces, nce, rows, ok, bad, why)

def sr_cw_fin3(+ces: List<&2, CE_F>, +rows: List<&2, String>, +bad: U64, +why: U64) -> SR_CW:
  match ces:
    case []: CW{rows, True{}, bad, why}
    case _ <> _: CW{rows, False{}, bad, 7u64}

def sr_cw_fin2(+ok: Bool, +ces: List<&2, CE_F>, +rows: List<&2, String>, +bad: U64,
    +why: U64) -> SR_CW:
  match ok:
    case False{}: CW{rows, False{}, bad, why}
    case True{}: sr_cw_fin3(ces, rows, bad, why)

def sr_cw_fin(+cs: SR_CS2) -> SR_CW:
  match cs:
    case CS2{+ces, +nce, +rows, +ok, +bad, +why}: sr_cw_fin2(ok, ces, rows, bad, why)

def sr_cw_go(es: List<&2, SE>, +st: ST, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +cs: SR_CS2) -> SR_CW:
  match es:
    case []: sr_cw_fin(cs)
    case +h <> t: sr_cw_go(t, st, vpts, e0s, e1s, fsurfs,
      sr_cw_nx(sr_kind_of(h), h, st, vpts, e0s, e1s, fsurfs, cs))

def sr_crows(+es: List<&2, SE>, +st: ST, +vpts: List<&2, V.Point>, +e0s: List<&2, Nat>,
    +e1s: List<&2, Nat>, +fsurfs: List<&2, G.GVal>, +ces: List<&2, CE_F>) -> SR_CW:
  sr_cw_go(es, st, vpts, e0s, e1s, fsurfs, CS2{ces, 0n, [], True{}, 0u64, 0u64})

def sr_opens_n(+w: Bool, +n: Nat) -> Nat:
  match w:
    case True{}: Nat.add(n, 1n)
    case False{}: n

def sr_opens_go(es: List<&2, SE>, +n: Nat) -> Nat:
  match es:
    case []: n
    case +h <> t: sr_opens_go(t, sr_opens_n(U64.is_eq(sr_kind_of(h), 28u64), n))

def sr_opens(+es: List<&2, SE>) -> Nat:
  sr_opens_go(es, 0n)

def sr_voids_go(es: List<&2, SE>, +n: Nat) -> Nat:
  match es:
    case []: n
    case +h <> t: sr_voids_go(t, sr_opens_n(U64.is_eq(sr_kind_of(h), 30u64), n))

def sr_voids(+es: List<&2, SE>) -> Nat:
  sr_voids_go(es, 0n)

def sr_asm_go(es: List<&2, SE>, +n: Nat) -> Nat:
  match es:
    case []: n
    case +h <> t: sr_asm_go(t, sr_opens_n(U64.is_eq(sr_kind_of(h), 31u64), n))

def sr_asm_ct(+es: List<&2, SE>) -> Nat:
  sr_asm_go(es, 0n)

def sr_sh_fs(+w: Bool, +xs: List<&2, Nat>) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-shell-bad-faces")
    case True{}: BL.es_ok("0," ++ Nat.show(List.length(&2, Nat, xs)) ++
      BL.jn_tail(sr_nstrs(xs), ","))

def sr_sh_a(+w: Bool, +a: SA, +st: ST) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-shell-bad-faces")
    case True{}:
      +r = sr_reflist(st, a, 20u64)
      sr_sh_fs(sr_rl_ok(r), sr_rl_xs(r))

def sr_sh_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> BL.ES:
  match w:
    case False{}: BL.es_fail("step-shell-bad-faces")
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_sh_a(sr_a_ok(r), sr_a_v(r), st)

def sr_sh_row(+st: ST, +h: SE) -> BL.ES:
  SE{+id, +ps} = h
  +r = sr_p0(ps)
  sr_sh_x(sr_px_ok(r), sr_px_xs(r), st)

def sr_sw_rows(+r: SR_SW) -> List<&2, String>:
  SW{rows, ok, bad} = r
  rows

def sr_sw_ok(+r: SR_SW) -> Bool:
  SW{rows, ok, bad} = r
  ok

def sr_sw_bad(+r: SR_SW) -> U64:
  SW{rows, ok, bad} = r
  bad

def sr_sw_hit2(+w: Bool, +er: BL.ES, +id: U64, +rows: List<&2, String>, +bad: U64) -> SR_SW:
  match w:
    case True{}: SW{BL.es_s(er) <> rows, True{}, bad}
    case False{}: SW{rows, False{}, id}

def sr_sw_hit(+er: BL.ES, +id: U64, +rows: List<&2, String>, +ok: Bool, +bad: U64) -> SR_SW:
  match ok:
    case False{}: SW{rows, False{}, bad}
    case True{}: sr_sw_hit2(BL.es_ok_of(er), er, id, rows, bad)

def sr_sw_m(+kind: U64, +h: SE, +st: ST, +rows: List<&2, String>, +ok: Bool, +bad: U64) -> SR_SW:
  match kind:
    case 21u64: sr_sw_hit(sr_sh_row(st, h), sr_se_id(h), rows, ok, bad)
    case _: SW{rows, ok, bad}

def sr_sw_nx(+kind: U64, +h: SE, +st: ST, +sw: SR_SW) -> SR_SW:
  match sw:
    case SW{+rows, +ok, +bad}: sr_sw_m(kind, h, st, rows, ok, bad)

def sr_sw_go(es: List<&2, SE>, +st: ST, +sw: SR_SW) -> SR_SW:
  match es:
    case []: sw
    case +h <> t: sr_sw_go(t, st, sr_sw_nx(sr_kind_of(h), h, st, sw))

def sr_srows(+es: List<&2, SE>, +st: ST) -> SR_SW:
  sr_sw_go(es, st, SW{[], True{}, 0u64})

def sr_or_ok(+r: SR_OR) -> Bool:
  SR_OR{ok, row, sh} = r
  ok

def sr_or_row(+r: SR_OR) -> String:
  SR_OR{ok, row, sh} = r
  row

def sr_or_sh(+r: SR_OR) -> Nat:
  SR_OR{ok, row, sh} = r
  sh

def sr_so_sh(+w: Bool, +sh: Nat) -> SR_OR:
  match w:
    case False{}: SR_OR{False{}, "", 0n}
    case True{}: SR_OR{True{}, Nat.show(sh) ++ ",0", sh}

def sr_so_a(+w: Bool, +a: SA, +st: ST) -> SR_OR:
  match w:
    case False{}: SR_OR{False{}, "", 0n}
    case True{}:
      +r = sr_rank_of(st, a, 21u64)
      sr_so_sh(sr_i_ok(r), sr_i_v(r))

def sr_so_x(+w: Bool, +xs: List<&2, SA>, +st: ST) -> SR_OR:
  match w:
    case False{}: SR_OR{False{}, "", 0n}
    case True{}:
      +r = sr_nth(xs, 1n)
      sr_so_a(sr_a_ok(r), sr_a_v(r), st)

def sr_so_row(+st: ST, +h: SE) -> SR_OR:
  SE{+id, +ps} = h
  +r = sr_p0(ps)
  sr_so_x(sr_px_ok(r), sr_px_xs(r), st)

def sr_ow_rows(+r: SR_OW) -> List<&2, String>:
  OW{rows, used, ok, bad} = r
  rows

def sr_ow_used(+r: SR_OW) -> List<&2, Nat>:
  OW{rows, used, ok, bad} = r
  used

def sr_ow_ok(+r: SR_OW) -> Bool:
  OW{rows, used, ok, bad} = r
  ok

def sr_ow_bad(+r: SR_OW) -> U64:
  OW{rows, used, ok, bad} = r
  bad

def sr_ow_hit2(+w: Bool, +orr: SR_OR, +id: U64, +rows: List<&2, String>,
    +used: List<&2, Nat>, +bad: U64) -> SR_OW:
  match w:
    case True{}: OW{sr_or_row(orr) <> rows, sr_or_sh(orr) <> used, True{}, bad}
    case False{}: OW{rows, used, False{}, id}

def sr_ow_hit(+orr: SR_OR, +id: U64, +rows: List<&2, String>, +used: List<&2, Nat>, +ok: Bool,
    +bad: U64) -> SR_OW:
  match ok:
    case False{}: OW{rows, used, False{}, bad}
    case True{}: sr_ow_hit2(sr_or_ok(orr), orr, id, rows, used, bad)

def sr_ow_m(+kind: U64, +h: SE, +st: ST, +rows: List<&2, String>, +used: List<&2, Nat>, +ok: Bool,
    +bad: U64) -> SR_OW:
  match kind:
    case 22u64: sr_ow_hit(sr_so_row(st, h), sr_se_id(h), rows, used, ok, bad)
    case _: OW{rows, used, ok, bad}

def sr_ow_nx(+kind: U64, +h: SE, +st: ST, +ow: SR_OW) -> SR_OW:
  match ow:
    case OW{+rows, +used, +ok, +bad}: sr_ow_m(kind, h, st, rows, used, ok, bad)

def sr_ow_go(es: List<&2, SE>, +st: ST, +ow: SR_OW) -> SR_OW:
  match es:
    case []: ow
    case +h <> t: sr_ow_go(t, st, sr_ow_nx(sr_kind_of(h), h, st, ow))

def sr_orows(+es: List<&2, SE>, +st: ST) -> SR_OW:
  sr_ow_go(es, st, OW{[], [], True{}, 0u64})

def sr_range_go(+n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: acc
    case 1n+j: sr_range_go(j, j <> acc)

def sr_range(+n: Nat) -> List<&2, Nat>:
  sr_range_go(n, [])

def sr_freediff_go(+fuel: Nat, all: List<&2, Nat>, +used: List<&2, Nat>, +acc: List<&2, Nat>) ->
    List<&2, Nat>:
  match fuel:
    case 0n: List.reverse(&2, Nat, acc)
    case 1n+j:
      match all:
        case []: List.reverse(&2, Nat, acc)
        case +a <> +t:
          match used:
            case []: List.append(&2, Nat, List.reverse(&2, Nat, acc), a <> t)
            case +u <> +us:
              +eq = Nat.is_eq(a, u)
              +lt = Nat.is_lt(a, u)
              sr_freediff_go(j, Bool.pick(List<&2, Nat>, eq, t, Bool.pick(List<&2, Nat>, lt, t,
                a <> t)), Bool.pick(List<&2, Nat>, eq, us, Bool.pick(List<&2, Nat>, lt, u <> us,
                us)), Bool.pick(List<&2, Nat>, eq, acc, Bool.pick(List<&2, Nat>, lt, a <> acc, acc)))

def sr_freediff(+all: List<&2, Nat>, +used: List<&2, Nat>) -> List<&2, Nat>:
  sr_freediff_go(Nat.add(List.length(&2, Nat, all), Nat.add(List.length(&2, Nat, used), 1n)), all,
    used, [])

def sr_en_ok(+r: SR_EN) -> Bool:
  SR_EN{ok, xs} = r
  ok

def sr_en_xs(+r: SR_EN) -> List<&2, SE>:
  SR_EN{ok, xs} = r
  xs

def sr_na_ok(+r: SR_NAT) -> Bool:
  SR_NAT{ok, xs} = r
  ok

def sr_na_xs(+r: SR_NAT) -> List<&2, Nat>:
  SR_NAT{ok, xs} = r
  xs

def sr_cel_ok(+r: SR_CEL) -> Bool:
  SR_CEL{ok, xs} = r
  ok

def sr_cel_xs(+r: SR_CEL) -> List<&2, CE_F>:
  SR_CEL{ok, xs} = r
  xs

def sr_bdl_ok(+r: SR_BDL) -> Bool:
  SR_BDL{ok, xs} = r
  ok

def sr_bdl_xs(+r: SR_BDL) -> List<&2, BD_F>:
  SR_BDL{ok, xs} = r
  xs

def sr_kind_f(+w: Bool, +st: ST, +pos: Nat) -> U64:
  match w:
    case False{}: 0u64
    case True{}: sr_kr_kind(sr_kr_at(st, pos))

def sr_kind_of_id(+st: ST, +id: U64) -> U64:
  +f = sr_find(st, id)
  sr_kind_f(sr_f_ok(f), st, sr_f_pos(f))

def sr_fail_curve(+kind: U64, +cid: U64) -> BL.PR:
  match kind:
    case 7u64: BL.pr_fail("step-spline-not-bezier-form #" ++ U64.show(cid))
    case 8u64: BL.pr_fail("step-spline-not-bezier-form #" ++ U64.show(cid))
    case 6u64: BL.pr_fail("step-trim-recovery-failed #" ++ U64.show(cid))
    case 4u64: BL.pr_fail("step-line-recovery-failed #" ++ U64.show(cid))
    case 5u64: BL.pr_fail("step-circle-recovery-failed #" ++ U64.show(cid))
    case 24u64: BL.pr_fail("step-wrapped-curve-failed #" ++ U64.show(cid))
    case 25u64: BL.pr_fail("step-wrapped-curve-failed #" ++ U64.show(cid))
    case _: BL.pr_fail("step-curve-not-in-profile #" ++ U64.show(cid))

def sr_fail_surf(+kind: U64, +sid: U64) -> BL.PR:
  match kind:
    case 14u64: BL.pr_fail("step-bpatch-face-not-in-profile")
    case 27u64: BL.pr_fail("step-conical-surface-not-in-profile")
    case 10u64: BL.pr_fail("step-plane-recovery-failed #" ++ U64.show(sid))
    case 11u64: BL.pr_fail("step-sphere-recovery-failed #" ++ U64.show(sid))
    case 12u64: BL.pr_fail("step-cylinder-recovery-failed #" ++ U64.show(sid))
    case 13u64: BL.pr_fail("step-torus-recovery-failed #" ++ U64.show(sid))
    case _: BL.pr_fail("step-surface-not-in-profile #" ++ U64.show(sid))

def sr_why_curve3(+w: Bool, +xs: List<&2, SA>) -> U64:
  match w:
    case False{}: 0u64
    case True{}:
      +r = sr_nth(xs, 3n)
      sr_why_curve4(sr_a_ok(r), sr_a_v(r))

def sr_why_curve2(+w: Bool, +st: ST, +pos: Nat) -> U64:
  match w:
    case False{}: 0u64
    case True{}:
      +r = sr_p0(sr_se_ps(sr_ent_at(st, pos)))
      sr_why_curve3(sr_px_ok(r), sr_px_xs(r))

def sr_why_curve(+st: ST, +id: U64) -> U64:
  +f = sr_find(st, id)
  sr_why_curve2(sr_f_ok(f), st, sr_f_pos(f))

def sr_fail_edge(+why: U64, +bad: U64, +st: ST) -> BL.PR:
  match why:
    case 1u64: BL.pr_fail("step-edge-bad-vertex #" ++ U64.show(bad))
    case 2u64: BL.pr_fail("step-edge-bad-sense #" ++ U64.show(bad))
    case 3u64:
      +cid = sr_why_curve(st, bad)
      sr_fail_curve(sr_kind_of_id(st, cid), cid)
    case _: BL.pr_fail("step-edge-bad-curve #" ++ U64.show(bad))

def sr_why_surf2(+w: Bool, +st: ST, +pos: Nat) -> U64:
  match w:
    case False{}: 0u64
    case True{}:
      +r = sr_p0(sr_se_ps(sr_ent_at(st, pos)))
      sr_why_surf3(sr_px_ok(r), sr_px_xs(r))

def sr_why_surf(+st: ST, +id: U64) -> U64:
  +f = sr_find(st, id)
  sr_why_surf2(sr_f_ok(f), st, sr_f_pos(f))

def sr_fail_face(+why: U64, +bad: U64, +st: ST) -> BL.PR:
  match why:
    case 1u64: BL.pr_fail("step-face-bad-bounds #" ++ U64.show(bad))
    case 2u64: BL.pr_fail("step-face-bad-sense #" ++ U64.show(bad))
    case 3u64:
      +sid = sr_why_surf(st, bad)
      sr_fail_surf(sr_kind_of_id(st, sid), sid)
    case 4u64:
      +sid = sr_why_surf(st, bad)
      sr_fail_surf(sr_kind_of_id(st, sid), sid)
    case 5u64: BL.pr_fail("step-face-bad-loop #" ++ U64.show(bad))
    case 6u64: BL.pr_fail("step-vertex-loop-not-in-profile face #" ++ U64.show(bad))
    case _: BL.pr_fail("step-face-failed #" ++ U64.show(bad))

def sr_fail_loop(+why: U64, +bad: U64) -> BL.PR:
  match why:
    case 5u64: BL.pr_fail("step-bound-bad-loop #" ++ U64.show(bad))
    case 7u64: BL.pr_fail("step-bound-in-two-faces #" ++ U64.show(bad))
    case 8u64: BL.pr_fail("step-bound-without-face #" ++ U64.show(bad))
    case 9u64: BL.pr_fail("step-bad-pole-vertex #" ++ U64.show(bad))
    case _: BL.pr_fail("step-loop-failed #" ++ U64.show(bad))

def sr_fail_ce(+why: U64, +bad: U64) -> BL.PR:
  match why:
    case 7u64: BL.pr_fail("step-coedge-in-two-loops #" ++ U64.show(bad))
    case 8u64: BL.pr_fail("step-coedge-without-loop #" ++ U64.show(bad))
    case 9u64: BL.pr_fail("step-coedge-trim-failed #" ++ U64.show(bad))
    case _: BL.pr_fail("step-coedge-failed #" ++ U64.show(bad))

def sr_tp2(+a: String, +b: String) -> List<&2, String>:
  a <> b <> []

def sr_build_go4(+v: List<&2, String>, +e: List<&2, String>, +c: List<&2, String>,
    +l: List<&2, String>, +f: List<&2, String>, +s: List<&2, String>, +o: List<&2, String>,
    +nv: Nat, +ne: Nat, +nce: Nat, +nlp: Nat, +nf: Nat, +nsh: Nat, +nso: Nat,
    +free: List<&2, Nat>) -> BL.PR:
  +srn = sr_range(nso)
  +t0 = Nat.show(nso) ++ BL.jn_tail(sr_nstrs(srn), ",")
  +t1 = Nat.show(List.length(&2, Nat, free)) ++ BL.jn_tail(sr_nstrs(free), ",")
  +rs = BL.rs_mk(BL.sp_mk(True{}, v), BL.sp_mk(True{}, e), BL.sp_mk(True{}, c),
    BL.sp_mk(True{}, l), BL.sp_mk(True{}, f), BL.sp_mk(True{}, s), BL.sp_mk(True{}, o))
  +tp = sr_tp2(t0, t1)
  +ps = "B1|" ++ Nat.show(nv) ++ "," ++ Nat.show(ne) ++ "," ++ Nat.show(nce) ++ "," ++
    Nat.show(nlp) ++ "," ++ Nat.show(nf) ++ "," ++ Nat.show(nsh) ++ "," ++ Nat.show(nso) ++ "|" ++
    BL.jn(v, ";") ++ "|" ++ BL.jn(e, ";") ++ "|" ++ BL.jn(c, ";") ++ "|" ++ BL.jn(l, ";") ++ "|" ++
    BL.jn(f, ";") ++ "|" ++ BL.jn(s, ";") ++ "|" ++ BL.jn(o, ";") ++ "|" ++ t0 ++ ";" ++ t1
  BL.pay_build(rs, tp, ps)

def sr_build_go3(+v: List<&2, String>, +e: List<&2, String>, +c: List<&2, String>,
    +l: List<&2, String>, +f: List<&2, String>, +s: List<&2, String>, +o: List<&2, String>,
    +nv: Nat, +ne: Nat, +nce: Nat, +nlp: Nat, +nf: Nat, +nsh: Nat, +nso: Nat,
    +sxs: List<&2, Nat>) -> BL.PR:
  +free = sr_freediff(sr_range(nsh), sxs)
  sr_build_go4(v, e, c, l, f, s, o, nv, ne, nce, nlp, nf, nsh, nso, free)

def sr_build_go2(+v: List<&2, String>, +e: List<&2, String>, +c: List<&2, String>,
    +l: List<&2, String>, +f: List<&2, String>, +s: List<&2, String>, +o: List<&2, String>,
    +sok: Bool, +sxs: List<&2, Nat>) -> BL.PR:
  match sok:
    case False{}: BL.pr_fail("step-sort-failed")
    case True{}: sr_build_go3(v, e, c, l, f, s, o, List.length(&2, String, v),
      List.length(&2, String, e), List.length(&2, String, c), List.length(&2, String, l),
      List.length(&2, String, f), List.length(&2, String, s), List.length(&2, String, o), sxs)

def sr_build_go(+v: List<&2, String>, +e: List<&2, String>, +c: List<&2, String>,
    +l: List<&2, String>, +f: List<&2, String>, +s: List<&2, String>, +o: List<&2, String>,
    +used: List<&2, Nat>) -> BL.PR:
  +su = sr_nat_sorted(used)
  sr_build_go2(v, e, c, l, f, s, o, sr_na_ok(su), sr_na_xs(su))

def sr_build(+vr: SR_VW, +er: SR_EW, +cr: SR_CW, +lr: SR_LW, +fr: SR_FW, +sw: SR_SW,
    +ow: SR_OW) -> BL.PR:
  sr_build_go(List.reverse(&2, String, sr_vw_rows(vr)), List.reverse(&2, String, sr_ew_rows(er)),
    List.reverse(&2, String, sr_cw_rows(cr)), List.reverse(&2, String, sr_lw_rows(lr)),
    List.reverse(&2, String, sr_fw_rows(fr)), List.reverse(&2, String, sr_sw_rows(sw)),
    List.reverse(&2, String, sr_ow_rows(ow)), sr_ow_used(ow))

def sr_parse_nso(+w: Bool, +vr: SR_VW, +er: SR_EW, +cr: SR_CW, +lr: SR_LW, +fr: SR_FW, +sw: SR_SW,
    +ow: SR_OW) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-no-solid")
    case True{}: sr_build(vr, er, cr, lr, fr, sw, ow)

def sr_parse_o(+w: Bool, +es: List<&2, SE>, +st: ST, +vr: SR_VW, +er: SR_EW, +cr: SR_CW, +lr: SR_LW,
    +fr: SR_FW, +sw: SR_SW, +ow: SR_OW) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-bad-solid #" ++ U64.show(sr_ow_bad(ow)))
    case True{}: sr_parse_nso(Nat.is_lt(0n, List.length(&2, String, sr_ow_rows(ow))), vr, er, cr,
      lr, fr, sw, ow)

def sr_parse_s(+w: Bool, +es: List<&2, SE>, +st: ST, +vr: SR_VW, +er: SR_EW, +cr: SR_CW, +lr: SR_LW,
    +fr: SR_FW, +sw: SR_SW) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-bad-shell #" ++ U64.show(sr_sw_bad(sw)))
    case True{}:
      +ow = sr_orows(es, st)
      sr_parse_o(sr_ow_ok(ow), es, st, vr, er, cr, lr, fr, sw, ow)

def sr_parse_c(+w: Bool, +es: List<&2, SE>, +st: ST, +vr: SR_VW, +er: SR_EW, +cr: SR_CW, +lr: SR_LW,
    +fr: SR_FW) -> BL.PR:
  match w:
    case False{}: sr_fail_ce(sr_cw_why(cr), sr_cw_bad(cr))
    case True{}:
      +sw = sr_srows(es, st)
      sr_parse_s(sr_sw_ok(sw), es, st, vr, er, cr, lr, fr, sw)

def sr_parse_l(+w: Bool, +es: List<&2, SE>, +st: ST, +vr: SR_VW, +er: SR_EW, +lr: SR_LW, +fr: SR_FW,
    +cs: SR_CEL) -> BL.PR:
  match w:
    case False{}: sr_fail_loop(sr_lw_why(lr), sr_lw_bad(lr))
    case True{}:
      +cr = sr_crows(es, st, List.reverse(&2, V.Point, sr_vw_pts(vr)),
        List.reverse(&2, Nat, sr_ew_e0s(er)), List.reverse(&2, Nat, sr_ew_e1s(er)),
        List.reverse(&2, G.GVal, sr_fw_surfs(fr)), sr_cel_xs(cs))
      sr_parse_c(sr_cw_ok(cr), es, st, vr, er, cr, lr, fr)

def sr_parse_g(+w: Bool, +es: List<&2, SE>, +st: ST, +vr: SR_VW, +er: SR_EW, +fr: SR_FW, +cs: SR_CEL,
    +bs: SR_BDL) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-sort-failed")
    case True{}:
      +lr = sr_lrows(es, st, sr_bdl_xs(bs))
      sr_parse_l(sr_lw_ok(lr), es, st, vr, er, lr, fr, cs)

def sr_parse_f(+w: Bool, +es: List<&2, SE>, +st: ST, +vr: SR_VW, +er: SR_EW, +fr: SR_FW) -> BL.PR:
  match w:
    case False{}: sr_fail_face(sr_fw_why(fr), sr_fw_bad(fr), st)
    case True{}:
      +cs = sr_ce_sorted(sr_fw_ces(fr))
      +bs = sr_bd_sorted(sr_fw_bds(fr))
      sr_parse_g(Bool.and(sr_cel_ok(cs), sr_bdl_ok(bs)), es, st, vr, er, fr, cs, bs)

def sr_parse_e(+w: Bool, +es: List<&2, SE>, +st: ST, +vr: SR_VW, +er: SR_EW) -> BL.PR:
  match w:
    case False{}: sr_fail_edge(sr_ew_why(er), sr_ew_bad(er), st)
    case True{}:
      +fr = sr_frows(es, st)
      sr_parse_f(sr_fw_ok(fr), es, st, vr, er, fr)

def sr_parse_v(+w: Bool, +es: List<&2, SE>, +st: ST, +vr: SR_VW) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-bad-vertex-point #" ++ U64.show(sr_vw_bad(vr)))
    case True{}:
      +er = sr_erows(es, st, List.reverse(&2, V.Point, sr_vw_pts(vr)))
      sr_parse_e(sr_ew_ok(er), es, st, vr, er)

def sr_parse_op(+w: Bool, +es: List<&2, SE>, +st: ST) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-open-shell-not-in-profile")
    case True{}:
      +vr = sr_vrows(es, st)
      sr_parse_v(sr_vw_ok(vr), es, st, vr)

def sr_spt_xs(+r: SPt) -> List<&2, SA>:
  SPt{nm, args} = r
  args

def sr_si_xs_go(ps: List<&2, SPt>) -> List<&2, SA>:
  match ps:
    case []: []
    case +h <> t: Bool.pick(List<&2, SA>, String.eq(sr_spt_nm(h), "SI_UNIT"), sr_spt_xs(h),
      sr_si_xs_go(t))

def sr_si_xs(ps: List<&2, SPt>) -> List<&2, SA>:
  sr_si_xs_go(ps)

def sr_si_en_go(xs: List<&2, SA>, +acc: List<&2, String>) -> List<&2, String>:
  match xs:
    case []: acc
    case h <> t:
      match h:
        case SA_en{+s}: sr_si_en_go(t, s <> acc)
        case _: sr_si_en_go(t, acc)

def sr_si_en(xs: List<&2, SA>) -> List<&2, String>:
  sr_si_en_go(xs, [])

def sr_has_en(xs: List<&2, String>, +s: String) -> Bool:
  match xs:
    case []: False{}
    case h <> t: Bool.or(String.eq(h, s), sr_has_en(t, s))

def sr_unit_ok(+e: SE) -> Bool:
  SE{+id, +ps} = e
  +ens = sr_si_en(sr_si_xs(ps))
  Bool.or(Bool.not(sr_has_en(ens, "METRE")), sr_has_en(ens, "MILLI"))

def sr_unit_t(+w: Bool, +h: SE) -> Bool:
  match w:
    case True{}: sr_unit_ok(h)
    case False{}: True{}

def sr_units_go(es: List<&2, SE>, +ok: Bool) -> Bool:
  match es:
    case []: ok
    case +h <> t: sr_units_go(t, Bool.and(ok, sr_unit_t(U64.is_eq(sr_kind_of(h), 29u64), h)))

def sr_units(+es: List<&2, SE>) -> Bool:
  sr_units_go(es, True{})

def sr_parse_as(+w: Bool, +es: List<&2, SE>, +st: ST) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-assembly-not-in-profile")
    case True{}: sr_parse_op(Nat.is_eq(sr_opens(es), 0n), es, st)

def sr_parse_vd(+w: Bool, +es: List<&2, SE>, +st: ST) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-voids-not-in-profile")
    case True{}: sr_parse_as(Nat.is_eq(sr_asm_ct(es), 0n), es, st)

def sr_parse_tb(+es: List<&2, SE>, +st: ST) -> BL.PR:
  sr_parse_vd(Nat.is_eq(sr_voids(es), 0n), es, st)

def sr_parse_un(+w: Bool, +es: List<&2, SE>, +st: ST) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-units-not-supported")
    case True{}: sr_parse_tb(es, st)

def sr_kc_bump_m(+kind: U64, +nv: Nat, +ne: Nat, +nce: Nat, +nlp: Nat, +nf: Nat, +nsh: Nat,
    +nso: Nat) -> KC:
  match kind:
    case 15u64: KC{Nat.add(nv, 1n), ne, nce, nlp, nf, nsh, nso}
    case 16u64: KC{nv, Nat.add(ne, 1n), nce, nlp, nf, nsh, nso}
    case 17u64: KC{nv, ne, Nat.add(nce, 1n), nlp, nf, nsh, nso}
    case 19u64: KC{nv, ne, nce, Nat.add(nlp, 1n), nf, nsh, nso}
    case 26u64: KC{nv, ne, nce, Nat.add(nlp, 1n), nf, nsh, nso}
    case 20u64: KC{nv, ne, nce, nlp, Nat.add(nf, 1n), nsh, nso}
    case 21u64: KC{nv, ne, nce, nlp, nf, Nat.add(nsh, 1n), nso}
    case 22u64: KC{nv, ne, nce, nlp, nf, nsh, Nat.add(nso, 1n)}
    case _: KC{nv, ne, nce, nlp, nf, nsh, nso}

def sr_kc_bump(+kc: KC, +kind: U64) -> KC:
  KC{+nv, +ne, +nce, +nlp, +nf, +nsh, +nso} = kc
  sr_kc_bump_m(kind, nv, ne, nce, nlp, nf, nsh, nso)

def sr_kc_rank_m(+kind: U64, +nv: Nat, +ne: Nat, +nce: Nat, +nlp: Nat, +nf: Nat, +nsh: Nat,
    +nso: Nat) -> Nat:
  match kind:
    case 15u64: nv
    case 16u64: ne
    case 17u64: nce
    case 19u64: nlp
    case 26u64: nlp
    case 20u64: nf
    case 21u64: nsh
    case 22u64: nso
    case _: 0n

def sr_kc_rank(+kc: KC, +kind: U64) -> Nat:
  KC{+nv, +ne, +nce, +nlp, +nf, +nsh, +nso} = kc
  sr_kc_rank_m(kind, nv, ne, nce, nlp, nf, nsh, nso)

def sr_kc_go(es: List<&2, SE>, +kc: KC, +acc: List<&2, KR>) -> List<&2, KR>:
  match es:
    case []: List.reverse(&2, KR, acc)
    case +h <> t:
      +k = sr_kind_of(h)
      sr_kc_go(t, sr_kc_bump(kc, k), KR{sr_se_id(h), k, sr_kc_rank(kc, k)} <> acc)

def sr_kc_init() -> KC:
  KC{0n, 0n, 0n, 0n, 0n, 0n, 0n}

def sr_kr_pad() -> KR:
  KR{0u64, 0u64, 0n}

def sr_se_pad() -> SE:
  SE{0u64, []}

def sr_table(+es: List<&2, SE>) -> ST:
  ST{B.tb_of(SE, es, sr_se_pad()), B.tb_of(KR, sr_kc_go(es, sr_kc_init(), []), sr_kr_pad()),
    List.length(&2, SE, es)}

def sr_parse_du(+w: Bool, +es: List<&2, SE>) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-duplicate-id")
    case True{}: sr_parse_un(sr_units(es), es, sr_table(es))

def sr_nodup_go(es: List<&2, SE>, +prev: U64, +first: Bool, +ok: Bool) -> Bool:
  match es:
    case []: ok
    case +h <> t:
      sr_nodup_go(t, sr_se_id(h), False{},
        Bool.and(ok, Bool.or(first, Nat.is_lt(U64.to_nat(prev), U64.to_nat(sr_se_id(h))))))

def sr_nodup(es: List<&2, SE>) -> Bool:
  sr_nodup_go(es, 0u64, True{}, True{})

def sr_parse_so(+w: Bool, +es: List<&2, SE>) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-sort-failed")
    case True{}: sr_parse_du(sr_nodup(es), es)

def sr_sorted(+es: List<&2, SE>) -> SR_EN:
  +m = B.msort(~SE, ~sr_se_cmp, es)
  SR_EN{sr_so_ok(m), sr_so_xs(m)}

def sr_parse_en(+w: Bool, +es: List<&2, SE>) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-entity-parse-failed")
    case True{}:
      +r = sr_sorted(es)
      sr_parse_so(sr_en_ok(r), sr_en_xs(r))

def sr_parse_cap(+w: Bool, +js: List<&2, String>) -> BL.PR:
  match w:
    case False{}: BL.pr_fail("step-too-many-entities")
    case True{}:
      +r = sr_ents(js)
      sr_parse_en(sr_en_ok(r), sr_en_xs(r))

def sr_parse(+payload: String) -> BL.PR:
  +js = sr_join(sr_lines(payload))
  sr_parse_cap(Nat.is_le(List.length(&2, String, js), sr_cap()), js)

def sr_sec_go(ls: List<&2, String>, +ind: Bool, +acc: List<&2, String>) -> List<&2, String>:
  match ls:
    case []: List.reverse(&2, String, acc)
    case +h <> t:
      match h:
        case "DATA;": sr_sec_go(t, True{}, acc)
        case "ENDSEC;":
          match ind:
            case True{}: List.reverse(&2, String, acc)
            case False{}: sr_sec_go(t, False{}, acc)
        case _:
          match ind:
            case True{}: sr_sec_go(t, True{}, h <> acc)
            case False{}: sr_sec_go(t, False{}, acc)

def sr_data(+payload: String) -> String:
  BL.jn(sr_sec_go(sr_lines(payload), False{}, []), "\n")

def sr_file(+payload: String) -> BL.PR:
  sr_parse(sr_data(payload))

def sr_pos_of(+st: ST, +a: SA) -> SF:
  match a:
    case SA_ref{+id}: sr_find(st, id)
    case _: SF{False{}, 0n}

type SR_TE is Data:
  SR_TE{ ok: Bool, dev: F64 }

def sr_te_ok(+r: SR_TE) -> Bool:
  SR_TE{ok, dev} = r
  ok

def sr_te_dev(+r: SR_TE) -> F64:
  SR_TE{ok, dev} = r
  dev

def sr_tol_rel() -> F64:
  F64.div(1.0f64, 68719476736.0f64)

def sr_tol_abs() -> F64:
  F64.div(1.0f64, 4294967296.0f64)

def sr_fmax(+a: F64, +b: F64) -> F64:
  Bool.pick(F64, F64.is_lt(a, b), b, a)

def sr_te_and(+a: SR_TE, +b: SR_TE) -> SR_TE:
  SR_TE{Bool.and(sr_te_ok(a), sr_te_ok(b)), sr_fmax(sr_te_dev(a), sr_te_dev(b))}

def sr_pres(+a: V.Point, +b: V.Point) -> F64:
  sr_fmax(F64.abs(F64.sub(V.pt_x(a), V.pt_x(b))),
    sr_fmax(F64.abs(F64.sub(V.pt_y(a), V.pt_y(b))), F64.abs(F64.sub(V.pt_z(a), V.pt_z(b)))))

def sr_pscale(+p: V.Point) -> F64:
  sr_fmax(1.0f64,
    sr_fmax(F64.abs(V.pt_x(p)), sr_fmax(F64.abs(V.pt_y(p)), F64.abs(V.pt_z(p)))))

def sr_within(+r: F64, +s: F64) -> Bool:
  F64.is_le(r, F64.add(sr_tol_abs(), F64.mul(sr_tol_rel(), s)))

def sr_edge_tol_g(+o0: Bool, +o1: Bool, +r0: G.GRes, +r1: G.GRes, +p0: V.Point,
    +p1: V.Point) -> SR_TE:
  match o0:
    case False{}: SR_TE{False{}, 0.0f64}
    case True{}:
      match o1:
        case False{}: SR_TE{False{}, 0.0f64}
        case True{}:
          +d0 = sr_pres(G.gres_p(r0), p0)
          +d1 = sr_pres(G.gres_p(r1), p1)
          +s0 = sr_pscale(p0)
          +s1 = sr_pscale(p1)
          SR_TE{Bool.and(sr_within(d0, s0), sr_within(d1, s1)), sr_fmax(d0, d1)}

def sr_edge_tol_f(+fin: Bool, +o0: Bool, +o1: Bool, +r0: G.GRes, +r1: G.GRes, +p0: V.Point,
    +p1: V.Point) -> SR_TE:
  match fin:
    case False{}: SR_TE{False{}, 0.0f64}
    case True{}: sr_edge_tol_g(o0, o1, r0, r1, p0, p1)

def sr_edge_tol(+kind: Ty.EdgeKind, +p0: V.Point, +p1: V.Point, +fuel: Nat) -> SR_TE:
  match kind:
    case Ty.EK_curve{+curve, +dom}:
      +fin = B4.curve_fin_ok(curve, fuel)
      +lo = G.dom_lo(dom)
      +r0 = B4.curve_at(curve, lo, fuel)
      +hi = G.dom_hi(dom)
      +r1 = B4.curve_at(curve, hi, fuel)
      sr_edge_tol_f(fin, G.gres_ok(r0), G.gres_ok(r1), r0, r1, p0, p1)
    case Ty.EK_degenerate{}: SR_TE{True{}, 0.0f64}

def sr_estol_go(es: List<&2, Ty.Edge>, +x: Ty.Ix, +fuel: Nat) -> SR_TE:
  match es:
    case Nil{}: SR_TE{True{}, 0.0f64}
    case +h <> t:
      +p0 = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v0(h))))
      +p1 = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v1(h))))
      sr_te_and(sr_edge_tol(Ty.ed_kind(h), p0, p1, fuel), sr_estol_go(t, x, fuel))

def sr_coinc_tol(+ce: Ty.Coedge, +ed: Ty.Edge, +x: Ty.Ix, +surf: G.GVal) -> SR_TE:
  +fwd = Ty.ce_fwd(ce)
  +trim = Ty.ce_trim(ce)
  +ts = B4.trim_o_start(trim, fwd)
  +te = B4.trim_o_end(trim, fwd)
  +ps = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, B4.o_v_start(ed, fwd))))
  +pe = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, B4.o_v_end(ed, fwd))))
  +rs = B4.surf_at(surf, V.v2_x(ts), V.v2_y(ts))
  +re = B4.surf_at(surf, V.v2_x(te), V.v2_y(te))
  sr_edge_tol_g(G.gres_ok(rs), G.gres_ok(re), rs, re, ps, pe)

def sr_hctol_go(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +surf: G.GVal) -> SR_TE:
  match xs:
    case Nil{}: SR_TE{True{}, 0.0f64}
    case h <> t:
      +ce = Ty.tres_ce(Ty.ix_ce(x, h))
      +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
      sr_te_and(sr_coinc_tol(ce, ed, x, surf), sr_hctol_go(t, x, surf))

def sr_hlstol_go(xs: List<&2, Ty.HLoop>, +x: Ty.Ix, +surf: G.GVal) -> SR_TE:
  match xs:
    case Nil{}: SR_TE{True{}, 0.0f64}
    case h <> t:
      sr_te_and(sr_hctol_go(Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, h))), x, surf),
        sr_hlstol_go(t, x, surf))

def sr_fctol_m(+quad: Bool, +fa: Ty.Face, +x: Ty.Ix, +surf: G.GVal) -> SR_TE:
  match quad:
    case True{}: SR_TE{B4.hls_face_ok(Ty.fa_loops(fa), x, surf, False{}, True{}), 0.0f64}
    case False{}: SR_TE{True{}, 0.0f64}

def sr_fctol_q(+quad: Bool, +coinc: Bool, +fa: Ty.Face, +x: Ty.Ix, +surf: G.GVal) -> SR_TE:
  match coinc:
    case True{}: sr_hlstol_go(Ty.fa_loops(fa), x, surf)
    case False{}: sr_fctol_m(quad, fa, x, surf)

def sr_fctol(+fa: Ty.Face, +x: Ty.Ix) -> SR_TE:
  +sf = Ty.fa_surf(fa)
  sr_fctol_q(B4.surf_quad(sf), B4.surf_coinc(sf), fa, x, sf)

def sr_fastol_go(fs: List<&2, Ty.Face>, +x: Ty.Ix) -> SR_TE:
  match fs:
    case Nil{}: SR_TE{True{}, 0.0f64}
    case h <> t: sr_te_and(sr_fctol(h, x), sr_fastol_go(t, x))

def sr_embed_tol(+b: Ty.Brep, +x: Ty.Ix, +fuel: Nat) -> SR_TE:
  sr_estol_go(Ty.brep_es(b), x, fuel)

def sr_ck_h(+ok: Bool, +te: SR_TE, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile) -> SR_TE:
  match ok:
    case False{}: te
    case True{}: sr_te_and(te, SR_TE{B4.ck_i(B4.link_prof(b, x, prof), b, x), 0.0f64})

def sr_mc_h(+b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> SR_TE:
  +te = sr_embed_tol(b, x, fuel)
  sr_ck_h(sr_te_ok(te), te, b, x, prof)

def sr_mc_g(+ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> SR_TE:
  match ok:
    case False{}: SR_TE{False{}, 0.0f64}
    case True{}: sr_mc_h(b, x, prof, fuel)

def sr_mc_f(+ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> SR_TE:
  match ok:
    case False{}: SR_TE{False{}, 0.0f64}
    case True{}: sr_mc_g(B4.fas_kind_ok(Ty.brep_fas(b), x), b, x, prof, fuel)

def sr_mc_e(+ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> SR_TE:
  match ok:
    case False{}: SR_TE{False{}, 0.0f64}
    case True{}: sr_mc_f(B4.lps_loop_ok(Ty.brep_lps(b), x), b, x, prof, fuel)

def sr_mc_d(+ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> SR_TE:
  match ok:
    case False{}: SR_TE{False{}, 0.0f64}
    case True{}: sr_mc_e(B4.use_ok(b, prof), b, x, prof, fuel)

def sr_mc_c(+ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> SR_TE:
  match ok:
    case False{}: SR_TE{False{}, 0.0f64}
    case True{}: sr_mc_d(B4.incid_ok(b, x), b, x, prof, fuel)

def sr_verdict_tol(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> SR_TE:
  +x = Ty.ix_of(b)
  sr_mc_c(B4.incid_ok(b, x), b, x, prof, fuel)

def sr_checked_tol_a(+ok: Bool, +b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> SR_TE:
  match ok:
    case False{}: SR_TE{False{}, 0.0f64}
    case True{}: sr_verdict_tol(b, prof, fuel)

def sr_checked_tol_go(+done: Bool, +b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> SR_TE:
  match done:
    case False{}: SR_TE{False{}, 0.0f64}
    case True{}:
      +ra = Ty.mk_brep(Ty.brep_vs(b), Ty.brep_es(b), Ty.brep_ces(b), Ty.brep_lps(b),
        Ty.brep_fas(b), Ty.brep_shs(b), Ty.brep_sos(b), Ty.brep_top(b), Ty.brep_stamp(b), fuel)
      sr_checked_tol_a(Ty.tres_ok(ra), b, prof, fuel)

def sr_brep_tol(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> SR_TE:
  sr_embed_tol(b, Ty.ix_of(b), fuel)

def sr_tol_re(+c: U32) -> Nat:
  Bool.pick(Nat, U32.is_eq(c, 58), 1n, 0n)

def sr_tol_st(+c: U32, +st: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_eq(st, 4n), 4n,
    Bool.pick(Nat, Nat.is_eq(st, 3n), Bool.pick(Nat, U32.is_eq(c, 108), 4n, sr_tol_re(c)),
      Bool.pick(Nat, Nat.is_eq(st, 2n), Bool.pick(Nat, U32.is_eq(c, 111), 3n, sr_tol_re(c)),
        Bool.pick(Nat, Nat.is_eq(st, 1n), Bool.pick(Nat, U32.is_eq(c, 116), 2n, sr_tol_re(c)),
          sr_tol_re(c)))))

def sr_tol_go(s: String, +st: Nat) -> Bool:
  match s:
    case SNil{}: Nat.is_eq(st, 4n)
    case SCon{+h, t}: sr_tol_go(t, sr_tol_st(N.chr_code(h), st))

def sr_has_tol(s: String) -> Bool:
  sr_tol_go(s, 0n)
