import Base
import ./xp.bend as X
import ./prof.bend as F
import ./model.bend as M
import ../base/num.bend as N

type Sx is Data:
  Sx_a{ s: String }
  Sx_l{ xs: List<&2, Sx> }

type Tk is Data:
  T_o{}
  T_c{}
  T_a{ s: String }

type PS is Data:
  PS{ ok: Bool, xs: List<&2, Sx> }

type NI is Data:
  NI{ name: String, id: U64 }

def ch_kind(+c: U32) -> U64:
  Bool.pick(U64, U32.is_eq(c, 40), 1u64, Bool.pick(U64, U32.is_eq(c, 41), 2u64,
    Bool.pick(U64, Bool.or(U32.is_eq(c, 32), Bool.or(U32.is_eq(c, 9), Bool.or(U32.is_eq(c, 10), U32.is_eq(c, 13)))), 3u64, 0u64)))

def str_rev(s: String, +acc: String) -> String:
  match s:
    case SNil{}: acc
    case SCon{h, t}: str_rev(t, SCon{h, acc})

def flush(cur: String, +acc: List<&2, Tk>) -> List<&2, Tk>:
  match cur:
    case SNil{}: acc
    case SCon{h, t}: T_a{str_rev(SCon{h, t}, SNil{})} <> acc

def tok_step(+k: U64, +h: Char, +cur: String, +acc: List<&2, Tk>) -> List<&2, Tk>:
  match k:
    case 1u64: T_o{} <> flush(cur, acc)
    case 2u64: T_c{} <> flush(cur, acc)
    case _: flush(cur, acc)

def chr_code(c: Char) -> U32:
  N.chr_code(c)

def tok_go(s: String, +cur: String, +acc: List<&2, Tk>) -> List<&2, Tk>:
  match s:
    case SNil{}: List.reverse(&2, Tk, flush(cur, acc))
    case SCon{+h, t}:
      +k = ch_kind(chr_code(h))
      +z = U64.is_eq(k, 0u64)
      tok_go(t, Bool.pick(String, z, SCon{h, cur}, SNil{}), Bool.pick(List<&2, Tk>, z, acc, tok_step(k, h, cur, acc)))

def tokens(+s: String) -> List<&2, Tk>:
  tok_go(s, SNil{}, [])

def fr_add(st: List<&2, List<&2, Sx>>, +x: Sx) -> List<&2, List<&2, Sx>>:
  match st:
    case []: [[x]]
    case f <> t: (x <> f) <> t

def fr_pop(st: List<&2, List<&2, Sx>>) -> List<&2, List<&2, Sx>>:
  match st:
    case []: []
    case f <> t: fr_add(t, Sx_l{List.reverse(&2, Sx, f)})

def st_len(st: List<&2, List<&2, Sx>>) -> Nat:
  List.length(&2, List<&2, Sx>, st)

def st_top(st: List<&2, List<&2, Sx>>) -> List<&2, Sx>:
  match st:
    case []: []
    case f <> t: List.reverse(&2, Sx, f)

def parse_go(ts: List<&2, Tk>, +st: List<&2, List<&2, Sx>>, +ok: Bool) -> PS:
  match ts:
    case []: PS{Bool.and(ok, Nat.is_eq(st_len(st), 1n)), st_top(st)}
    case t <> +r:
      match t:
        case T_o{}: parse_go(r, [] <> st, ok)
        case T_c{}: parse_go(r, fr_pop(st), Bool.and(ok, Nat.is_le(2n, st_len(st))))
        case T_a{s}: parse_go(r, fr_add(st, Sx_a{s}), ok)

def parse(+s: String) -> PS:
  parse_go(tokens(s), [[]], True{})

def show_go(xs: List<&2, Sx>, +first: Bool) -> String:
  match xs:
    case []: ""
    case x <> +t:
      match x:
        case Sx_a{s}: Bool.pick(String, first, "", " ") ++ s ++ show_go(t, False{})
        case Sx_l{ys}: Bool.pick(String, first, "", " ") ++ "(" ++ show_go(ys, True{}) ++ ")" ++ show_go(t, False{})

def sx_show(+x: Sx) -> String:
  show_go([x], True{})

def at(+s: String) -> Sx:
  Sx_a{s}

def ls(+xs: List<&2, Sx>) -> Sx:
  Sx_l{xs}

def sx_s(x: Sx) -> String:
  match x:
    case Sx_a{s}: s
    case Sx_l{xs}: ""

def sx_xs(x: Sx) -> List<&2, Sx>:
  match x:
    case Sx_a{s}: []
    case Sx_l{xs}: xs

def sx_nth(xs: List<&2, Sx>, +i: Nat) -> Sx:
  match xs:
    case []: Sx_l{[]}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: sx_nth(t, j)

def sx_drop(xs: List<&2, Sx>, +i: Nat) -> List<&2, Sx>:
  match xs:
    case []: []
    case x <> +t:
      match i:
        case 0n: x <> t
        case 1n+j: sx_drop(t, j)

def head_is(+x: Sx, +h: String) -> Bool:
  String.eq(sx_s(sx_nth(sx_xs(x), 0n)), h)

def f_show(+v: F64) -> String:
  N.f_show(v)

def dec(+s: String) -> Maybe<&2, F64>:
  N.dec(s)

def num(+s: String) -> Maybe<&2, F64>:
  N.num(s)

def is_some(m: Maybe<&2, F64>) -> Bool:
  N.is_some(m)

def some_v(m: Maybe<&2, F64>) -> F64:
  N.some_v(m)

def ni_find(ns: List<&2, NI>, +s: String) -> U64:
  match ns:
    case []: 0u64
    case n <> t:
      NI{name, id} = n
      Bool.pick(U64, String.eq(name, s), id, ni_find(t, s))

def ni_name(ns: List<&2, NI>, +id: U64) -> String:
  match ns:
    case []: "p" ++ U64.show(id)
    case n <> t:
      NI{name, i} = n
      Bool.pick(String, U64.is_eq(i, id), name, ni_name(t, id))

def xp_atom(+s: String, +ns: List<&2, NI>) -> X.Xp:
  Bool.pick(X.Xp, is_some(num(s)), X.X_k{some_v(num(s))}, X.X_p{ni_find(ns, s)})

def xp_ops(+op: String, +n: Nat, +a: X.Xp, +b: X.Xp) -> X.Xp:
  Bool.pick(X.Xp, String.eq(op, "+"), X.X_add{a, b}, Bool.pick(X.Xp, String.eq(op, "-"),
    Bool.pick(X.Xp, Nat.is_eq(n, 2n), X.X_neg{a}, X.X_sub{a, b}),
    Bool.pick(X.Xp, String.eq(op, "*"), X.X_mul{a, b}, Bool.pick(X.Xp, String.eq(op, "/"), X.X_div{a, b},
      X.X_k{F64.nan()}))))

def xp_go(f: Nat, x: Sx, +ns: List<&2, NI>) -> X.Xp:
  match f:
    case 0n: X.X_k{F64.nan()}
    case 1n+(+g):
      match x:
        case Sx_a{s}: xp_atom(s, ns)
        case Sx_l{ys}:
          match ys:
            case []: X.X_k{F64.nan()}
            case h <> +t:
              xp_ops(sx_s(h), Nat.add(List.length(&2, Sx, t), 1n), xp_go(g, sx_nth(t, 0n), ns), xp_go(g, sx_nth(t, 1n), ns))

def to_xp(+x: Sx, +ns: List<&2, NI>) -> X.Xp:
  xp_go(40n, x, ns)

def xp_sx(x: X.Xp, +ns: List<&2, NI>) -> Sx:
  match x:
    case X.X_k{v}: at(f_show(v))
    case X.X_p{id}: at(ni_name(ns, id))
    case X.X_add{a, b}: ls([at("+"), xp_sx(a, ns), xp_sx(b, ns)])
    case X.X_sub{a, b}: ls([at("-"), xp_sx(a, ns), xp_sx(b, ns)])
    case X.X_mul{a, b}: ls([at("*"), xp_sx(a, ns), xp_sx(b, ns)])
    case X.X_div{a, b}: ls([at("/"), xp_sx(a, ns), xp_sx(b, ns)])
    case X.X_neg{a}: ls([at("-"), xp_sx(a, ns)])

def seg_of(+x: Sx, +ns: List<&2, NI>) -> F.Seg:
  +xs = sx_xs(x)
  Bool.pick(F.Seg, head_is(x, "line"), F.S_line{to_xp(sx_nth(xs, 1n), ns), to_xp(sx_nth(xs, 2n), ns)},
    F.S_arc{to_xp(sx_nth(xs, 1n), ns), to_xp(sx_nth(xs, 2n), ns), to_xp(sx_nth(xs, 3n), ns),
      to_xp(sx_nth(xs, 4n), ns), to_xp(sx_nth(xs, 5n), ns), Bool.not(String.eq(sx_s(sx_nth(xs, 6n)), "cw"))})

def segs_of(xs: List<&2, Sx>, +ns: List<&2, NI>) -> List<&2, F.Seg>:
  match xs:
    case []: []
    case x <> t: seg_of(x, ns) <> segs_of(t, ns)

def loop_of(+x: Sx, +ns: List<&2, NI>) -> F.Loop:
  +xs = sx_xs(x)
  Bool.pick(F.Loop, head_is(x, "circle"), F.L_circ{to_xp(sx_nth(xs, 1n), ns), to_xp(sx_nth(xs, 2n), ns), to_xp(sx_nth(xs, 3n), ns)},
    F.L_path{to_xp(sx_nth(xs, 1n), ns), to_xp(sx_nth(xs, 2n), ns), segs_of(sx_drop(xs, 3n), ns)})

def loops_of(xs: List<&2, Sx>, +ns: List<&2, NI>) -> List<&2, F.Loop>:
  match xs:
    case []: []
    case x <> t: loop_of(x, ns) <> loops_of(t, ns)

def rg_of(+x: Sx, +ns: List<&2, NI>) -> F.Region:
  +xs = sx_xs(x)
  F.Rg{loop_of(sx_nth(xs, 1n), ns), loops_of(sx_drop(xs, 2n), ns)}

def rgs_of(xs: List<&2, Sx>, +ns: List<&2, NI>) -> List<&2, F.Region>:
  match xs:
    case []: []
    case x <> t: rg_of(x, ns) <> rgs_of(t, ns)

def hl_of(+x: Sx, +ns: List<&2, NI>) -> M.Hl:
  +xs = sx_xs(x)
  M.Hl{to_xp(sx_nth(xs, 1n), ns), to_xp(sx_nth(xs, 2n), ns), to_xp(sx_nth(xs, 3n), ns)}

def hls_of(xs: List<&2, Sx>, +ns: List<&2, NI>) -> List<&2, M.Hl>:
  match xs:
    case []: []
    case x <> t: hl_of(x, ns) <> hls_of(t, ns)

def u64_m(m: Maybe<&2, U64>) -> U64:
  match m:
    case None{}: 0u64
    case Some{v}: v

def u64_of(+x: Sx) -> U64:
  u64_m(U64.read(sx_s(x)))

def sel_of(+x: Sx) -> M.Sel:
  +xs = sx_xs(x)
  +named = Nat.is_eq(List.length(&2, Sx, xs), 3n)
  M.Sel{u64_of(sx_nth(xs, 1n)), Bool.pick(Nat, named, 0n, U64.to_nat(u64_of(sx_nth(xs, 2n)))),
    Bool.pick(U64, String.eq(sx_s(sx_nth(xs, 3n)), "bottom"), 1u64, 0u64),
    Bool.pick(String, named, sx_s(sx_nth(xs, 2n)), "")}

def is_thru(+x: Sx) -> Bool:
  String.eq(sx_s(x), "through")

def axis_of(+s: String) -> U64:
  Bool.pick(U64, String.eq(s, "x"), 0u64, Bool.pick(U64, String.eq(s, "y"), 1u64, Bool.pick(U64, String.eq(s, "z"), 2u64, 9u64)))

def axis_s(+a: U64) -> String:
  Bool.pick(String, U64.is_eq(a, 0u64), "x", Bool.pick(String, U64.is_eq(a, 1u64), "y", Bool.pick(String, U64.is_eq(a, 2u64), "z", "?")))

type SW is Data:
  SW{ ok: Bool, kind: U64, z: X.Xp, deg: U64, rs: List<&2, F.Region>, g: U64, gd: U64, tw: U64, gg: Bool, tt: Bool }

type LP is Data:
  LP{ ok: Bool, tw: U64, cont: U64, tt: Bool, cc: Bool }

def u64_some(m: Maybe<&2, U64>) -> Bool:
  match m:
    case None{}: False{}
    case Some{v}: True{}

def nat_ok(x: Sx) -> Bool:
  match x:
    case Sx_a{s}: u64_some(U64.read(s))
    case Sx_l{xs}: False{}

def sw_kind_s(+s: String) -> U64:
  Bool.pick(U64, String.eq(s, "line"), 1u64, Bool.pick(U64, String.eq(s, "arc"), 2u64, 0u64))

def sw_path(x: Sx, +ns: List<&2, NI>) -> SW:
  +ys = sx_xs(x)
  +k = sw_kind_s(sx_s(sx_nth(ys, 0n)))
  +a = sx_nth(ys, 1n)
  +two = Nat.is_eq(List.length(&2, Sx, ys), 2n)
  +ok = Bool.or(Bool.and(U64.is_eq(k, 1u64), two), Bool.and(Bool.and(U64.is_eq(k, 2u64), two), nat_ok(a)))
  SW{ok, k, to_xp(a, ns), u64_of(a), [], 0u64, 0u64, 0u64, False{}, False{}}

def g_inner(x: Sx) -> Sx:
  sx_nth(sx_xs(x), 1n)

def g_code(x: Sx) -> U64:
  +inn = g_inner(x)
  +h = sx_s(sx_nth(sx_xs(inn), 0n))
  Bool.pick(U64, String.eq(h, "line"), 1u64, Bool.pick(U64, Bool.and(String.eq(h, "arc"), nat_ok(sx_nth(sx_xs(inn), 1n))), 2u64, 3u64))

def g_deg(x: Sx) -> U64:
  +inn = g_inner(x)
  Bool.pick(U64, String.eq(sx_s(sx_nth(sx_xs(inn), 0n)), "arc"), u64_of(sx_nth(sx_xs(inn), 1n)), 0u64)

def sw_bad(st: SW) -> SW:
  SW{ok, kind, z, deg, rs, g, gd, tw, gg, tt} = st
  SW{False{}, kind, z, deg, rs, g, gd, tw, gg, tt}

def sw_reg(st: SW, +x: Sx, +ns: List<&2, NI>) -> SW:
  SW{+ok, kind, z, deg, rs, g, gd, tw, +gg, +tt} = st
  SW{Bool.and(ok, Bool.not(Bool.or(gg, tt))), kind, z, deg, List.append(&2, F.Region, rs, [rg_of(x, ns)]), g, gd, tw, gg, tt}

def sw_gui(st: SW, +x: Sx) -> SW:
  SW{+ok, kind, z, deg, rs, g, gd, tw, +gg, tt} = st
  SW{Bool.and(ok, Bool.not(gg)), kind, z, deg, rs, g_code(x), g_deg(x), tw, True{}, tt}

def sw_twi(st: SW, +x: Sx) -> SW:
  SW{+ok, kind, z, deg, rs, g, gd, tw, gg, tt} = st
  +ys = sx_xs(x)
  +n = sx_nth(ys, 1n)
  +good = Bool.and(Bool.not(tt), Bool.and(Nat.is_eq(List.length(&2, Sx, ys), 2n), nat_ok(n)))
  SW{Bool.and(ok, good), kind, z, deg, rs, g, gd, u64_of(n), gg, True{}}

def sw_tag(+x: Sx) -> U64:
  Bool.pick(U64, head_is(x, "region"), 1u64, Bool.pick(U64, head_is(x, "guide"), 2u64, Bool.pick(U64, head_is(x, "twist"), 3u64, 0u64)))

def sw_arm(k: U64, +st: SW, +x: Sx, +ns: List<&2, NI>) -> SW:
  match k:
    case 1u64: sw_reg(st, x, ns)
    case 2u64: sw_gui(st, x)
    case 3u64: sw_twi(st, x)
    case _: sw_bad(st)

def sw_add(st: SW, +x: Sx, +ns: List<&2, NI>) -> SW:
  sw_arm(sw_tag(x), st, x, ns)

def sw_walk(xs: List<&2, Sx>, +st: SW, +ns: List<&2, NI>) -> SW:
  match xs:
    case []: st
    case x <> t: sw_walk(t, sw_add(st, x, ns), ns)

def sw_has(rs: List<&2, F.Region>) -> Bool:
  match rs:
    case []: False{}
    case h <> t: True{}

def sw_line(st: SW) -> M.Op:
  SW{ok, k, z, deg, rs, g, gd, tw, gg, tt} = st
  M.O_sw_line{z, rs, g, gd, tw}

def sw_arc(st: SW) -> M.Op:
  SW{ok, k, z, deg, rs, g, gd, tw, gg, tt} = st
  M.O_sw_arc{deg, rs, g, gd, tw}

def sw_kind(kind: U64, +st: SW) -> M.Op:
  match kind:
    case 1u64: sw_line(st)
    case 2u64: sw_arc(st)
    case _: M.O_unk{"sweep"}

def sw_knd(st: SW) -> U64:
  SW{ok, kind, z, deg, rs, g, gd, tw, gg, tt} = st
  kind

def sw_ok(ok: Bool, +st: SW) -> M.Op:
  match ok:
    case False{}: M.O_unk{"sweep"}
    case True{}: sw_kind(sw_knd(st), st)

def sw_fin(st: SW) -> M.Op:
  SW{+ok, kind, z, deg, +rs, g, gd, tw, gg, tt} = st
  sw_ok(Bool.and(ok, sw_has(rs)), SW{ok, kind, z, deg, rs, g, gd, tw, gg, tt})

def sw_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  sw_fin(sw_walk(sx_drop(xs, 2n), sw_path(sx_nth(xs, 1n), ns), ns))

def lf_bad(st: LP) -> LP:
  LP{ok, tw, cont, tt, cc} = st
  LP{False{}, tw, cont, tt, cc}

def lf_tw(st: LP, +x: Sx) -> LP:
  LP{+ok, tw, cont, tt, cc} = st
  +ys = sx_xs(x)
  +n = sx_nth(ys, 1n)
  +good = Bool.and(Bool.not(tt), Bool.and(Nat.is_eq(List.length(&2, Sx, ys), 2n), nat_ok(n)))
  LP{Bool.and(ok, good), u64_of(n), cont, True{}, cc}

def lf_co_c(+s: String) -> U64:
  Bool.pick(U64, String.eq(s, "g0"), 0u64, Bool.pick(U64, String.eq(s, "g1"), 1u64, 9u64))

def lf_co(st: LP, +x: Sx) -> LP:
  LP{+ok, tw, cont, tt, cc} = st
  +ys = sx_xs(x)
  +c = lf_co_c(sx_s(sx_nth(ys, 1n)))
  +good = Bool.and(Bool.not(cc), Bool.and(Nat.is_eq(List.length(&2, Sx, ys), 2n), U64.is_lt(c, 2u64)))
  LP{Bool.and(ok, good), tw, c, tt, True{}}

def lf_tag(+x: Sx) -> U64:
  Bool.pick(U64, head_is(x, "twist"), 1u64, Bool.pick(U64, head_is(x, "continuity"), 2u64, 0u64))

def lf_arm(k: U64, +st: LP, +x: Sx) -> LP:
  match k:
    case 1u64: lf_tw(st, x)
    case 2u64: lf_co(st, x)
    case _: lf_bad(st)

def lf_walk(xs: List<&2, Sx>, +st: LP) -> LP:
  match xs:
    case []: st
    case +x <> t: lf_walk(t, lf_arm(lf_tag(x), st, x))

def lf_fin_b(ok: Bool, +tw: U64, +cont: U64, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"loft"}
    case True{}: M.O_loft{to_xp(sx_nth(xs, 1n), ns), rg_of(sx_nth(xs, 2n), ns), rg_of(sx_nth(xs, 3n), ns), tw, cont}

def lf_fin(st: LP, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  LP{ok, tw, cont, tt, cc} = st
  lf_fin_b(ok, tw, cont, xs, ns)

def lf_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"loft"}
    case True{}: lf_fin(lf_walk(sx_drop(xs, 4n), LP{True{}, 0u64, 0u64, False{}, False{}}), xs, ns)

def lf_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  lf_go(Bool.and(Nat.is_le(4n, List.length(&2, Sx, xs)), Bool.and(head_is(sx_nth(xs, 2n), "region"), head_is(sx_nth(xs, 3n), "region"))), xs, ns)

def len3(+xs: List<&2, Sx>) -> Bool:
  Bool.and(Nat.is_eq(List.length(&2, Sx, xs), 3n), nat_ok(sx_nth(xs, 1n)))

def ch_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_chamfer{u64_of(sx_nth(xs, 1n)), to_xp(sx_nth(xs, 2n), ns)}
    case False{}: M.O_unk{"chamfer"}

def ech_of(+xs: List<&2, Sx>, +ns: List<&2, NI>, +fl: Bool) -> M.Op:
  +cs = sx_xs(sx_nth(xs, 3n))
  M.O_echamf{u64_of(sx_nth(xs, 1n)), sel_of(sx_nth(xs, 2n)), to_xp(sx_nth(cs, 1n), ns), to_xp(sx_nth(cs, 2n), ns),
    to_xp(sx_nth(cs, 3n), ns), to_xp(sx_nth(xs, 4n), ns), fl}

def ech_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: ech_of(xs, ns, False{})
    case False{}: ch_go(len3(xs), xs, ns)

def lch_of(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  +es = sx_xs(sx_nth(xs, 2n))
  M.O_lchamf{u64_of(sx_nth(xs, 1n)), u64_of(sx_nth(es, 1n)), sx_s(sx_nth(es, 2n)), sx_s(sx_nth(es, 3n)), to_xp(sx_nth(xs, 3n), ns)}

def lch_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: lch_of(xs, ns)
    case False{}: ech_go(Bool.and(Nat.is_eq(List.length(&2, Sx, xs), 5n), Bool.and(head_is(sx_nth(xs, 2n), "face"), head_is(sx_nth(xs, 3n), "circle"))), xs, ns)

def ch_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  lch_go(Bool.and(Nat.is_eq(List.length(&2, Sx, xs), 4n), head_is(sx_nth(xs, 2n), "edge")), xs, ns)

def dr_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_draft{u64_of(sx_nth(xs, 1n)), to_xp(sx_nth(xs, 2n), ns)}
    case False{}: M.O_unk{"draft"}

def dr_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  dr_go(len3(xs), xs, ns)

def of_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_offset{u64_of(sx_nth(xs, 1n)), to_xp(sx_nth(xs, 2n), ns)}
    case False{}: M.O_unk{"offset"}

def of_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  of_go(len3(xs), xs, ns)

def tk_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_thicken{u64_of(sx_nth(xs, 1n)), to_xp(sx_nth(xs, 2n), ns)}
    case False{}: M.O_unk{"thicken"}

def tk_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  tk_go(len3(xs), xs, ns)

def sh3(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_shell{u64_of(sx_nth(xs, 1n)), to_xp(sx_nth(xs, 2n), ns), False{}}
    case False{}: M.O_unk{"shell"}

def sh4b(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_shell{u64_of(sx_nth(xs, 1n)), to_xp(sx_nth(xs, 2n), ns), True{}}
    case False{}: M.O_unk{"shell"}

def sh4(a4: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match a4:
    case False{}: M.O_unk{"shell"}
    case True{}: sh4b(Bool.and(nat_ok(sx_nth(xs, 1n)), String.eq(sx_s(sx_nth(xs, 3n)), "open")), xs, ns)

def sh_len(a3: Bool, +a4: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match a3:
    case True{}: sh3(nat_ok(sx_nth(xs, 1n)), xs, ns)
    case False{}: sh4(a4, xs, ns)

def sh_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  sh_len(Nat.is_eq(List.length(&2, Sx, xs), 3n), Nat.is_eq(List.length(&2, Sx, xs), 4n), xs, ns)

def fil_edge_ok(+x: Sx) -> Bool:
  +ys = sx_xs(x)
  Bool.and(head_is(x, "edge"), Bool.and(Nat.is_eq(List.length(&2, Sx, ys), 2n), nat_ok(sx_nth(ys, 1n))))

def fil3(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_fillet{u64_of(sx_nth(xs, 1n)), to_xp(sx_nth(xs, 2n), ns)}
    case False{}: M.O_unk{"fillet"}

def fil5c(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_fillet_e{u64_of(sx_nth(xs, 1n)), u64_of(sx_nth(sx_xs(sx_nth(xs, 2n)), 1n)), to_xp(sx_nth(xs, 3n), ns), to_xp(sx_nth(xs, 4n), ns)}
    case False{}: M.O_unk{"fillet"}

def fil5b(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"fillet"}
    case True{}: fil5c(nat_ok(sx_nth(xs, 1n)), xs, ns)

def fil5f(fc: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match fc:
    case True{}: ech_of(xs, ns, True{})
    case False{}: fil5b(fil_edge_ok(sx_nth(xs, 2n)), xs, ns)

def fil5(a5: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match a5:
    case False{}: M.O_unk{"fillet"}
    case True{}: fil5f(Bool.and(head_is(sx_nth(xs, 2n), "face"), head_is(sx_nth(xs, 3n), "circle")), xs, ns)

def fil_len(a3: Bool, +a5: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match a3:
    case True{}: fil3(nat_ok(sx_nth(xs, 1n)), xs, ns)
    case False{}: fil5(a5, xs, ns)

def fil_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  fil_len(Nat.is_eq(List.length(&2, Sx, xs), 3n), Nat.is_eq(List.length(&2, Sx, xs), 5n), xs, ns)

def lin_ok(+ys: List<&2, Sx>) -> Bool:
  Bool.and(Nat.is_eq(List.length(&2, Sx, ys), 7n), Bool.and(nat_ok(sx_nth(ys, 1n)), Bool.and(nat_ok(sx_nth(ys, 3n)), nat_ok(sx_nth(ys, 5n)))))

def cir_ok(+ys: List<&2, Sx>) -> Bool:
  Bool.and(Nat.is_eq(List.length(&2, Sx, ys), 3n), nat_ok(sx_nth(ys, 1n)))

def pat_lin(ok: Bool, +base: U64, +x: Sx, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"pattern"}
    case True{}:
      +ys = sx_xs(x)
      M.O_pat_lin{base, u64_of(sx_nth(ys, 1n)), to_xp(sx_nth(ys, 2n), ns), u64_of(sx_nth(ys, 3n)), to_xp(sx_nth(ys, 4n), ns), u64_of(sx_nth(ys, 5n)), to_xp(sx_nth(ys, 6n), ns)}

def pat_cir(ok: Bool, +base: U64, +x: Sx, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_pat_circ{base, u64_of(sx_nth(sx_xs(x), 1n)), to_xp(sx_nth(sx_xs(x), 2n), ns)}
    case False{}: M.O_unk{"pattern"}

def pat_kind(+x: Sx) -> U64:
  Bool.pick(U64, head_is(x, "linear"), 1u64, Bool.pick(U64, head_is(x, "circular"), 2u64, 0u64))

def pat_spec(k: U64, +base: U64, +x: Sx, +ns: List<&2, NI>) -> M.Op:
  match k:
    case 1u64: pat_lin(lin_ok(sx_xs(x)), base, x, ns)
    case 2u64: pat_cir(cir_ok(sx_xs(x)), base, x, ns)
    case _: M.O_unk{"pattern"}

def pat_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"pattern"}
    case True{}: pat_spec(pat_kind(sx_nth(xs, 2n)), u64_of(sx_nth(xs, 1n)), sx_nth(xs, 2n), ns)

def pat_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  pat_go(Bool.and(Nat.is_eq(List.length(&2, Sx, xs), 3n), nat_ok(sx_nth(xs, 1n))), xs, ns)

def hole_ok(+x: Sx) -> Bool:
  Bool.and(head_is(x, "hole"), Nat.is_eq(List.length(&2, Sx, sx_xs(x)), 2n))

def ph_lin_ok(+ys: List<&2, Sx>) -> Bool:
  Bool.and(Nat.is_eq(List.length(&2, Sx, ys), 7n), Bool.and(nat_ok(sx_nth(ys, 1n)), nat_ok(sx_nth(ys, 2n))))

def ph_cir_ok(+ys: List<&2, Sx>) -> Bool:
  Bool.and(Nat.is_eq(List.length(&2, Sx, ys), 5n), nat_ok(sx_nth(ys, 1n)))

def ph_lin(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"pattern-holes"}
    case True{}:
      +ys = sx_xs(sx_nth(xs, 3n))
      +hole = sx_xs(sx_nth(xs, 4n))
      +dep = sx_nth(xs, 5n)
      M.O_ph_lin{u64_of(sx_nth(xs, 1n)), sel_of(sx_nth(xs, 2n)), u64_of(sx_nth(ys, 1n)), u64_of(sx_nth(ys, 2n)), to_xp(sx_nth(ys, 3n), ns), to_xp(sx_nth(ys, 4n), ns), to_xp(sx_nth(ys, 5n), ns), to_xp(sx_nth(ys, 6n), ns), to_xp(sx_nth(hole, 1n), ns), to_xp(dep, ns), is_thru(dep)}

def ph_cir(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"pattern-holes"}
    case True{}:
      +ys = sx_xs(sx_nth(xs, 3n))
      +hole = sx_xs(sx_nth(xs, 4n))
      +dep = sx_nth(xs, 5n)
      M.O_ph_circ{u64_of(sx_nth(xs, 1n)), sel_of(sx_nth(xs, 2n)), u64_of(sx_nth(ys, 1n)), to_xp(sx_nth(ys, 2n), ns), to_xp(sx_nth(ys, 3n), ns), to_xp(sx_nth(ys, 4n), ns), to_xp(sx_nth(hole, 1n), ns), to_xp(dep, ns), is_thru(dep)}

def ph_spec(k: U64, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match k:
    case 1u64: ph_lin(ph_lin_ok(sx_xs(sx_nth(xs, 3n))), xs, ns)
    case 2u64: ph_cir(ph_cir_ok(sx_xs(sx_nth(xs, 3n))), xs, ns)
    case _: M.O_unk{"pattern-holes"}

def ph_hole(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"pattern-holes"}
    case True{}: ph_spec(pat_kind(sx_nth(xs, 3n)), xs, ns)

def ph_base(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"pattern-holes"}
    case True{}: ph_hole(hole_ok(sx_nth(xs, 4n)), xs, ns)

def ph_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"pattern-holes"}
    case True{}: ph_base(nat_ok(sx_nth(xs, 1n)), xs, ns)

def ph_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  ph_go(Nat.is_eq(List.length(&2, Sx, xs), 6n), xs, ns)

def guide_xs(g: U64, +gd: U64) -> List<&2, Sx>:
  match g:
    case 0u64: []
    case 1u64: [ls([at("guide"), ls([at("line"), at("0")])])]
    case 2u64: [ls([at("guide"), ls([at("arc"), at(U64.show(gd))])])]
    case _: [ls([at("guide"), ls([at("other")])])]

def tw_xs(tw: U64) -> List<&2, Sx>:
  match tw:
    case 0u64: []
    case _: [ls([at("twist"), at(U64.show(tw))])]

def cont_xs(c: U64) -> List<&2, Sx>:
  match c:
    case 0u64: []
    case _: [ls([at("continuity"), at("g1")])]

def open_xs(o: Bool) -> List<&2, Sx>:
  match o:
    case True{}: [at("open")]
    case False{}: []

def sx_cat(a: List<&2, Sx>, +b: List<&2, Sx>) -> List<&2, Sx>:
  List.append(&2, Sx, a, b)

def flat_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_flat{to_xp(sx_nth(xs, 1n), ns), to_xp(sx_nth(xs, 2n), ns), to_xp(sx_nth(xs, 3n), ns)}
    case False{}: M.O_unk{"flat"}

def flat_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  flat_go(Nat.is_eq(List.length(&2, Sx, xs), 4n), xs, ns)

def bend5c(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_bend{u64_of(sx_nth(xs, 1n)), u64_of(sx_nth(sx_xs(sx_nth(xs, 2n)), 1n)), to_xp(sx_nth(xs, 3n), ns), u64_of(sx_nth(xs, 4n))}
    case False{}: M.O_unk{"bend"}

def bend5b(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"bend"}
    case True{}: bend5c(Bool.and(nat_ok(sx_nth(xs, 1n)), nat_ok(sx_nth(xs, 4n))), xs, ns)

def bend5(a5: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match a5:
    case False{}: M.O_unk{"bend"}
    case True{}: bend5b(fil_edge_ok(sx_nth(xs, 2n)), xs, ns)

def bend_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  bend5(Nat.is_eq(List.length(&2, Sx, xs), 5n), xs, ns)

def hem4c(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_hem{u64_of(sx_nth(xs, 1n)), u64_of(sx_nth(sx_xs(sx_nth(xs, 2n)), 1n)), to_xp(sx_nth(xs, 3n), ns)}
    case False{}: M.O_unk{"hem"}

def hem4b(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"hem"}
    case True{}: hem4c(nat_ok(sx_nth(xs, 1n)), xs, ns)

def hem4(a4: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match a4:
    case False{}: M.O_unk{"hem"}
    case True{}: hem4b(fil_edge_ok(sx_nth(xs, 2n)), xs, ns)

def hem_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  hem4(Nat.is_eq(List.length(&2, Sx, xs), 4n), xs, ns)

def op_is_sheet(+h: String) -> Bool:
  Bool.or(String.eq(h, "flat"), Bool.or(String.eq(h, "bend"), String.eq(h, "hem")))

def op_of_sheet(+h: String, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  Bool.pick(M.Op, String.eq(h, "flat"), flat_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "bend"), bend_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "hem"), hem_op(xs, ns), M.O_unk{h})))

def lop_fin_b(ok: Bool, +tw: U64, +cont: U64, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"loft-open"}
    case True{}: M.O_loft_open{to_xp(sx_nth(xs, 1n), ns), rg_of(sx_nth(xs, 2n), ns), rg_of(sx_nth(xs, 3n), ns), tw, cont}

def lop_fin(st: LP, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  LP{ok, tw, cont, tt, cc} = st
  lop_fin_b(ok, tw, cont, xs, ns)

def lop_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"loft-open"}
    case True{}: lop_fin(lf_walk(sx_drop(xs, 4n), LP{True{}, 0u64, 0u64, False{}, False{}}), xs, ns)

def lop_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  lop_go(Bool.and(Nat.is_le(4n, List.length(&2, Sx, xs)), Bool.and(head_is(sx_nth(xs, 2n), "region"), head_is(sx_nth(xs, 3n), "region"))), xs, ns)

def sw_open_fin(st: SW) -> M.Op:
  SW{+ok, kind, z, deg, +rs, g, gd, tw, gg, tt} = st
  Bool.pick(M.Op, Bool.and(Bool.and(ok, sw_has(rs)), U64.is_eq(kind, 2u64)), M.O_sw_open{deg, rs, g, gd, tw},
    M.O_unk{"sweep-open"})

def sw_open_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  sw_open_fin(sw_walk(sx_drop(xs, 2n), sw_path(sx_nth(xs, 1n), ns), ns))

def pt_ok(+x: Sx) -> Bool:
  +ys = sx_xs(x)
  Bool.and(head_is(x, "pt"), Nat.is_eq(List.length(&2, Sx, ys), 4n))

def all_pt(xs: List<&2, Sx>) -> Bool:
  match xs:
    case []: True{}
    case +x <> t: Bool.and(pt_ok(x), all_pt(t))

def pt_xps(+x: Sx, +ns: List<&2, NI>) -> List<&2, X.Xp>:
  +ys = sx_xs(x)
  [to_xp(sx_nth(ys, 1n), ns), to_xp(sx_nth(ys, 2n), ns), to_xp(sx_nth(ys, 3n), ns)]

def pts_go(xs: List<&2, Sx>, +ns: List<&2, NI>) -> List<&2, X.Xp>:
  match xs:
    case []: []
    case +x <> t: List.append(&2, X.Xp, pt_xps(x, ns), pts_go(t, ns))

def patch_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  Bool.pick(M.Op, Bool.and(Nat.is_eq(List.length(&2, Sx, xs), 17n), all_pt(sx_drop(xs, 1n))),
    M.O_patch{pts_go(sx_drop(xs, 1n), ns)}, M.O_unk{"patch"})

def tko_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case True{}: M.O_thicken_open{u64_of(sx_nth(xs, 1n)), to_xp(sx_nth(xs, 2n), ns)}
    case False{}: M.O_unk{"thicken-open"}

def tko_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  tko_go(len3(xs), xs, ns)

def op_is_surf(+h: String) -> Bool:
  Bool.or(String.eq(h, "loft-open"), Bool.or(String.eq(h, "sweep-open"), Bool.or(String.eq(h, "patch"),
    String.eq(h, "thicken-open"))))

def op_of_surf(+h: String, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  Bool.pick(M.Op, String.eq(h, "loft-open"), lop_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "sweep-open"), sw_open_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "patch"), patch_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "thicken-open"), tko_op(xs, ns), M.O_unk{h}))))

def naca_nat(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"naca4"}
    case True{}:
      M.O_naca4{u64_of(sx_nth(xs, 1n)), u64_of(sx_nth(xs, 2n)), u64_of(sx_nth(xs, 3n)),
        to_xp(sx_nth(xs, 4n), ns), u64_of(sx_nth(xs, 5n))}

def naca_go(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match ok:
    case False{}: M.O_unk{"naca4"}
    case True{}:
      naca_nat(Bool.and(nat_ok(sx_nth(xs, 1n)),
        Bool.and(nat_ok(sx_nth(xs, 2n)), Bool.and(nat_ok(sx_nth(xs, 3n)), nat_ok(sx_nth(xs, 5n))))),
        xs, ns)

def naca_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  naca_go(Nat.is_eq(List.length(&2, Sx, xs), 6n), xs, ns)

def blade_us(xs: List<&2, Sx>, +k: Nat) -> List<&2, U64>:
  match xs:
    case []: []
    case +h <> t: Bool.pick(List<&2, U64>, Nat.is_eq(k, 0n), [], u64_of(h) <> blade_us(t, Nat.sub(k, 1n)))

def blade_nok(xs: List<&2, Sx>, +k: Nat) -> Bool:
  match xs:
    case []: Nat.is_eq(k, 0n)
    case +h <> t:
      Bool.pick(Bool, Nat.is_eq(k, 0n), True{}, Bool.and(nat_ok(h), blade_nok(t, Nat.sub(k, 1n))))

def blade_nat(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>, +n: Nat) -> M.Op:
  match ok:
    case False{}: M.O_unk{"blade"}
    case True{}:
      M.O_blade{blade_us(sx_drop(xs, 1n), n), to_xp(sx_nth(xs, Nat.add(n, 1n)), ns),
        u64_of(sx_nth(xs, Nat.add(n, 2n))), u64_of(sx_nth(xs, Nat.add(n, 3n)))}

def blade_len(ok: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>, +n: Nat) -> M.Op:
  match ok:
    case False{}: M.O_unk{"blade"}
    case True{}:
      blade_nat(Bool.and(blade_nok(sx_drop(xs, 1n), n),
        Bool.and(nat_ok(sx_nth(xs, Nat.add(n, 2n))), nat_ok(sx_nth(xs, Nat.add(n, 3n))))), xs, ns, n)

def blade_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  +l = List.length(&2, Sx, xs)
  blade_len(Bool.and(Nat.is_le(5n, l), Nat.is_le(l, 13n)), xs, ns, Nat.sub(l, 4n))

def op_is_blade(+h: String) -> Bool:
  Bool.or(String.eq(h, "naca4"), String.eq(h, "blade"))

def op_of_blade(+h: String, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  Bool.pick(M.Op, String.eq(h, "naca4"), naca_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "blade"), blade_op(xs, ns), M.O_unk{h}))

def op_is_feat(+h: String) -> Bool:
  Bool.or(String.eq(h, "sweep"), Bool.or(String.eq(h, "loft"), Bool.or(String.eq(h, "chamfer"),
    Bool.or(String.eq(h, "fillet"), Bool.or(String.eq(h, "draft"), Bool.or(String.eq(h, "offset"),
      Bool.or(String.eq(h, "shell"), Bool.or(String.eq(h, "thicken"), Bool.or(String.eq(h, "pattern"),
        String.eq(h, "pattern-holes"))))))))))

def op_of_core(+h: String, +xs: List<&2, Sx>, +e1: Sx, +e2: Sx, +e3: Sx, +ns: List<&2, NI>) -> M.Op:
  Bool.pick(M.Op, String.eq(h, "prism"), M.O_prism{rgs_of(sx_drop(xs, 3n), ns), to_xp(e1, ns), to_xp(e2, ns)},
  Bool.pick(M.Op, String.eq(h, "box"), M.O_box{to_xp(e1, ns), to_xp(e2, ns), to_xp(e3, ns)},
  Bool.pick(M.Op, String.eq(h, "cylinder"), M.O_cyl{to_xp(e1, ns), to_xp(e2, ns)},
  Bool.pick(M.Op, String.eq(h, "pad"), M.O_pad{u64_of(e1), sel_of(e2), rgs_of(sx_drop(xs, 4n), ns), to_xp(e3, ns)},
  Bool.pick(M.Op, String.eq(h, "pocket"), M.O_pocket{u64_of(e1), sel_of(e2), rgs_of(sx_drop(xs, 4n), ns), to_xp(e3, ns), is_thru(e3)},
  Bool.pick(M.Op, String.eq(h, "holes"), M.O_holes{u64_of(e1), sel_of(e2), hls_of(sx_drop(xs, 4n), ns), to_xp(e3, ns), is_thru(e3)},
  Bool.pick(M.Op, String.eq(h, "revolve"), M.O_revolve{rgs_of(sx_drop(xs, 1n), ns)},
  Bool.pick(M.Op, String.eq(h, "cone"), M.O_cone{to_xp(e1, ns), to_xp(e2, ns)},
  Bool.pick(M.Op, String.eq(h, "sphere"), M.O_sph{to_xp(e1, ns)},
  Bool.pick(M.Op, String.eq(h, "torus"), M.O_tor{to_xp(e1, ns), to_xp(e2, ns)},
  Bool.pick(M.Op, String.eq(h, "move"), M.O_move{u64_of(e1), to_xp(e2, ns), to_xp(e3, ns), to_xp(sx_nth(xs, 4n), ns), u64_of(sx_nth(xs, 5n))},
  Bool.pick(M.Op, String.eq(h, "rotate"), M.O_rot{u64_of(e1), axis_of(sx_s(e2)), to_xp(e3, ns)},
  Bool.pick(M.Op, String.eq(h, "union"), M.O_union{u64_of(e1), u64_of(e2)},
  Bool.pick(M.Op, String.eq(h, "difference"), M.O_difference{u64_of(e1), u64_of(e2)},
  Bool.pick(M.Op, String.eq(h, "intersection"), M.O_intersection{u64_of(e1), u64_of(e2)},
  Bool.pick(M.Op, String.eq(h, "import"), M.O_blob{u64_of(e1), sx_s(e2)},
  M.O_unk{h}))))))))))))))))

def op_of_feat(+h: String, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  Bool.pick(M.Op, String.eq(h, "sweep"), sw_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "loft"), lf_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "chamfer"), ch_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "fillet"), fil_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "draft"), dr_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "offset"), of_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "shell"), sh_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "thicken"), tk_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "pattern"), pat_op(xs, ns),
  Bool.pick(M.Op, String.eq(h, "pattern-holes"), ph_op(xs, ns), M.O_unk{h}))))))))))

def op_of(+x: Sx, +ns: List<&2, NI>) -> M.Op:
  +xs = sx_xs(x)
  +h = sx_s(sx_nth(xs, 0n))
  +e1 = sx_nth(xs, 1n)
  +e2 = sx_nth(xs, 2n)
  +e3 = sx_nth(xs, 3n)
  Bool.pick(M.Op, op_is_sheet(h), op_of_sheet(h, xs, ns),
    Bool.pick(M.Op, op_is_surf(h), op_of_surf(h, xs, ns),
      Bool.pick(M.Op, op_is_blade(h), op_of_blade(h, xs, ns),
      Bool.pick(M.Op, op_is_feat(h), op_of_feat(h, xs, ns), op_of_core(h, xs, e1, e2, e3, ns)))))

def cnt_of(+x: Sx) -> M.Cnt:
  Bool.pick(M.Cnt, String.eq(sx_s(x), "any"), M.C_any{}, M.C_eq{U64.to_nat(u64_of(x))})

def mat_of(+s: String) -> M.Mat:
  Bool.pick(M.Mat, String.eq(s, "create"), M.M_create{}, Bool.pick(M.Mat, String.eq(s, "add"), M.M_add{},
    Bool.pick(M.Mat, String.eq(s, "remove"), M.M_remove{}, Bool.pick(M.Mat, String.eq(s, "same"), M.M_same{}, M.M_unknown{}))))

def it_of(+x: Sx) -> M.It:
  +xs = sx_xs(x)
  M.It{mat_of(sx_s(sx_nth(xs, 1n))), cnt_of(sx_nth(xs, 2n)), cnt_of(sx_nth(xs, 3n)), cnt_of(sx_nth(xs, 4n)),
    cnt_of(sx_nth(xs, 5n))}

def seg_sx(s: F.Seg, +ns: List<&2, NI>) -> Sx:
  match s:
    case F.S_line{x, y}: ls([at("line"), xp_sx(x, ns), xp_sx(y, ns)])
    case F.S_arc{cx, cy, r, x, y, ccw}:
      ls([at("arc"), xp_sx(cx, ns), xp_sx(cy, ns), xp_sx(r, ns), xp_sx(x, ns), xp_sx(y, ns), at(Bool.pick(String, ccw, "ccw", "cw"))])

def segs_sx(ss: List<&2, F.Seg>, +ns: List<&2, NI>) -> List<&2, Sx>:
  match ss:
    case []: []
    case s <> t: seg_sx(s, ns) <> segs_sx(t, ns)

def loop_sx(l: F.Loop, +ns: List<&2, NI>) -> Sx:
  match l:
    case F.L_circ{cx, cy, r}: ls([at("circle"), xp_sx(cx, ns), xp_sx(cy, ns), xp_sx(r, ns)])
    case F.L_path{x, y, segs}: ls(at("path") <> xp_sx(x, ns) <> xp_sx(y, ns) <> segs_sx(segs, ns))

def loops_sx(ls0: List<&2, F.Loop>, +ns: List<&2, NI>) -> List<&2, Sx>:
  match ls0:
    case []: []
    case l <> t: loop_sx(l, ns) <> loops_sx(t, ns)

def rgs_sx(rs: List<&2, F.Region>, +ns: List<&2, NI>) -> List<&2, Sx>:
  match rs:
    case []: []
    case r <> t:
      F.Rg{o, hs} = r
      ls(at("region") <> loop_sx(o, ns) <> loops_sx(hs, ns)) <> rgs_sx(t, ns)

def hls_sx(hs: List<&2, M.Hl>, +ns: List<&2, NI>) -> List<&2, Sx>:
  match hs:
    case []: []
    case h <> t:
      M.Hl{x, y, r} = h
      ls([at("hole"), xp_sx(x, ns), xp_sx(y, ns), xp_sx(r, ns)]) <> hls_sx(t, ns)

def sel_sx(s: M.Sel) -> Sx:
  M.Sel{+nd, +k, +side, +nm} = s
  Bool.pick(Sx, String.is_empty(nm),
    ls([at("face"), at(U64.show(nd)), at(Nat.show(k)), at(Bool.pick(String, U64.is_eq(side, 1u64), "bottom", "top"))]),
    ls([at("face"), at(U64.show(nd)), at(nm)]))

def amt_sx(+thru: Bool, x: X.Xp, +ns: List<&2, NI>) -> Sx:
  Bool.pick(Sx, thru, at("through"), xp_sx(x, ns))

def pt_sx(+a: X.Xp, +b: X.Xp, +c: X.Xp, +ns: List<&2, NI>) -> Sx:
  ls([at("pt"), xp_sx(a, ns), xp_sx(b, ns), xp_sx(c, ns)])

def xp_nth(xs: List<&2, X.Xp>, +i: Nat) -> X.Xp:
  match xs:
    case []: X.X_k{0.0f64}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: xp_nth(t, j)

def ptg_go2(left: Nat, +xs: List<&2, X.Xp>, +o: Nat, +ns: List<&2, NI>) -> List<&2, Sx>:
  match left:
    case 0n: []
    case 1n+k:
      pt_sx(xp_nth(xs, o), xp_nth(xs, Nat.add(o, 1n)), xp_nth(xs, Nat.add(o, 2n)), ns) <>
        ptg_go2(k, xs, Nat.add(o, 3n), ns)

def ptg_go(+xs: List<&2, X.Xp>, +ns: List<&2, NI>) -> List<&2, Sx>:
  ptg_go2(Nat.div(List.length(&2, X.Xp, xs), 3n), xs, 0n, ns)

def us_sx(xs: List<&2, U64>) -> List<&2, Sx>:
  match xs:
    case []: []
    case +h <> t: at(U64.show(h)) <> us_sx(t)

def op_sx(o: M.Op, +ns: List<&2, NI>) -> Sx:
  match o:
    case M.O_prism{rs, z0, z1}: ls(at("prism") <> xp_sx(z0, ns) <> xp_sx(z1, ns) <> rgs_sx(rs, ns))
    case M.O_box{x, y, z}: ls([at("box"), xp_sx(x, ns), xp_sx(y, ns), xp_sx(z, ns)])
    case M.O_cyl{r, h}: ls([at("cylinder"), xp_sx(r, ns), xp_sx(h, ns)])
    case M.O_pad{base, f, rs, h}: ls(at("pad") <> at(U64.show(base)) <> sel_sx(f) <> xp_sx(h, ns) <> rgs_sx(rs, ns))
    case M.O_pocket{base, f, rs, d, +thru}:
      ls(at("pocket") <> at(U64.show(base)) <> sel_sx(f) <> amt_sx(thru, d, ns) <> rgs_sx(rs, ns))
    case M.O_holes{base, f, hs, d, +thru}:
      ls(at("holes") <> at(U64.show(base)) <> sel_sx(f) <> amt_sx(thru, d, ns) <> hls_sx(hs, ns))
    case M.O_move{base, tx, ty, tz, q}:
      ls([at("move"), at(U64.show(base)), xp_sx(tx, ns), xp_sx(ty, ns), xp_sx(tz, ns), at(U64.show(q))])
    case M.O_rot{base, ax, deg}: ls([at("rotate"), at(U64.show(base)), at(axis_s(ax)), xp_sx(deg, ns)])
    case M.O_unk{name}: ls([at(name)])
    case M.O_revolve{rs}: ls(at("revolve") <> rgs_sx(rs, ns))
    case M.O_cone{r, h}: ls([at("cone"), xp_sx(r, ns), xp_sx(h, ns)])
    case M.O_sph{r}: ls([at("sphere"), xp_sx(r, ns)])
    case M.O_tor{bigr, r}: ls([at("torus"), xp_sx(bigr, ns), xp_sx(r, ns)])
    case M.O_union{a, b}: ls([at("union"), at(U64.show(a)), at(U64.show(b))])
    case M.O_difference{a, b}: ls([at("difference"), at(U64.show(a)), at(U64.show(b))])
    case M.O_intersection{a, b}: ls([at("intersection"), at(U64.show(a)), at(U64.show(b))])
    case M.O_sw_line{z, rs, g, gd, tw}:
      ls(at("sweep") <> ls([at("line"), xp_sx(z, ns)]) <> sx_cat(rgs_sx(rs, ns), sx_cat(guide_xs(g, gd), tw_xs(tw))))
    case M.O_sw_arc{deg, rs, g, gd, tw}:
      ls(at("sweep") <> ls([at("arc"), at(U64.show(deg))]) <> sx_cat(rgs_sx(rs, ns), sx_cat(guide_xs(g, gd), tw_xs(tw))))
    case M.O_loft{z, bot, top, twist, cont}:
      ls(at("loft") <> xp_sx(z, ns) <> sx_cat(rgs_sx([bot], ns), sx_cat(rgs_sx([top], ns), sx_cat(tw_xs(twist), cont_xs(cont)))))
    case M.O_chamfer{base, d}: ls([at("chamfer"), at(U64.show(base)), xp_sx(d, ns)])
    case M.O_echamf{base, f, cx, cy, r, c, fl}: ls([at(Bool.pick(String, fl, "fillet", "chamfer")), at(U64.show(base)), sel_sx(f), ls([at("circle"), xp_sx(cx, ns), xp_sx(cy, ns), xp_sx(r, ns)]), xp_sx(c, ns)])
    case M.O_lchamf{base, nd, n1, n2, c}: ls([at("chamfer"), at(U64.show(base)), ls([at("edge"), at(U64.show(nd)), at(n1), at(n2)]), xp_sx(c, ns)])
    case M.O_fillet{base, r}: ls([at("fillet"), at(U64.show(base)), xp_sx(r, ns)])
    case M.O_fillet_e{base, n, r0, r1}:
      ls([at("fillet"), at(U64.show(base)), ls([at("edge"), at(U64.show(n))]), xp_sx(r0, ns), xp_sx(r1, ns)])
    case M.O_draft{base, inset}: ls([at("draft"), at(U64.show(base)), xp_sx(inset, ns)])
    case M.O_offset{base, d}: ls([at("offset"), at(U64.show(base)), xp_sx(d, ns)])
    case M.O_shell{base, t, open}: ls(at("shell") <> at(U64.show(base)) <> xp_sx(t, ns) <> open_xs(open))
    case M.O_thicken{base, t}: ls([at("thicken"), at(U64.show(base)), xp_sx(t, ns)])
    case M.O_pat_lin{base, nx, dx, ny, dy, nz, dz}:
      ls([at("pattern"), at(U64.show(base)), ls([at("linear"), at(U64.show(nx)), xp_sx(dx, ns), at(U64.show(ny)), xp_sx(dy, ns), at(U64.show(nz)), xp_sx(dz, ns)])])
    case M.O_pat_circ{base, n, r}:
      ls([at("pattern"), at(U64.show(base)), ls([at("circular"), at(U64.show(n)), xp_sx(r, ns)])])
    case M.O_ph_lin{base, f, nx, ny, dx, dy, x0, y0, r, d, thru}:
      ls([at("pattern-holes"), at(U64.show(base)), sel_sx(f), ls([at("linear"), at(U64.show(nx)), at(U64.show(ny)), xp_sx(dx, ns), xp_sx(dy, ns), xp_sx(x0, ns), xp_sx(y0, ns)]), ls([at("hole"), xp_sx(r, ns)]), amt_sx(thru, d, ns)])
    case M.O_ph_circ{base, f, n, rad, cx, cy, r, d, thru}:
      ls([at("pattern-holes"), at(U64.show(base)), sel_sx(f), ls([at("circular"), at(U64.show(n)), xp_sx(rad, ns), xp_sx(cx, ns), xp_sx(cy, ns)]), ls([at("hole"), xp_sx(r, ns)]), amt_sx(thru, d, ns)])
    case M.O_flat{l, w, t}: ls([at("flat"), xp_sx(l, ns), xp_sx(w, ns), xp_sx(t, ns)])
    case M.O_bend{base, n, r, deg}:
      ls([at("bend"), at(U64.show(base)), ls([at("edge"), at(U64.show(n))]), xp_sx(r, ns), at(U64.show(deg))])
    case M.O_hem{base, n, l}:
      ls([at("hem"), at(U64.show(base)), ls([at("edge"), at(U64.show(n))]), xp_sx(l, ns)])
    case M.O_loft_open{z, bot, top, twist, cont}:
      ls(at("loft-open") <> xp_sx(z, ns) <> sx_cat(rgs_sx([bot], ns), sx_cat(rgs_sx([top], ns), sx_cat(tw_xs(twist), cont_xs(cont)))))
    case M.O_sw_open{deg, rs, g, gd, tw}:
      ls(at("sweep-open") <> ls([at("arc"), at(U64.show(deg))]) <> sx_cat(rgs_sx(rs, ns), sx_cat(guide_xs(g, gd), tw_xs(tw))))
    case M.O_patch{ps}: ls(at("patch") <> ptg_go(ps, ns))
    case M.O_thicken_open{base, t}: ls([at("thicken-open"), at(U64.show(base)), xp_sx(t, ns)])
    case M.O_naca4{m, p, t, c, n}:
      ls([at("naca4"), at(U64.show(m)), at(U64.show(p)), at(U64.show(t)), xp_sx(c, ns), at(U64.show(n))])
    case M.O_blade{secs, z, tw, tp}:
      ls(sx_cat([at("blade")], sx_cat(us_sx(secs), [xp_sx(z, ns), at(U64.show(tw)), at(U64.show(tp))])))
    case M.O_blob{fmt, payload}: ls([at("import"), at(U64.show(fmt)), at(payload)])

def cnt_sx(c: M.Cnt) -> Sx:
  match c:
    case M.C_any{}: at("any")
    case M.C_eq{n}: at(Nat.show(n))

def it_sx(i: M.It) -> Sx:
  M.It{mat, fc, fm, sh, ho} = i
  ls([at("intent"), at(M.mat_show(mat)), cnt_sx(fc), cnt_sx(fm), cnt_sx(sh), cnt_sx(ho)])

def pm_sx(p: M.Param) -> Sx:
  M.Pm{id, name, dim} = p
  M.Dm{nom, lo, hi} = dim
  ls([at("param"), at(U64.show(id)), at(name), at(f_show(nom)), at(f_show(lo)), at(f_show(hi))])

def nd_sx(n: M.Node, +ns: List<&2, NI>) -> Sx:
  M.Nd{id, op, it} = n
  ls([at("node"), at(U64.show(id)), op_sx(op, ns), it_sx(it)])

def nis_of(ps: List<&2, M.Param>) -> List<&2, NI>:
  match ps:
    case []: []
    case p <> t:
      M.Pm{id, name, dim} = p
      NI{name, id} <> nis_of(t)

def pms_sx(ps: List<&2, M.Param>) -> List<&2, Sx>:
  match ps:
    case []: []
    case p <> t: pm_sx(p) <> pms_sx(t)

def nds_sx(xs: List<&2, M.Node>, +ns: List<&2, NI>) -> List<&2, Sx>:
  match xs:
    case []: []
    case n <> t: nd_sx(n, ns) <> nds_sx(t, ns)

def part_lines(xs: List<&2, Sx>) -> String:
  match xs:
    case []: ""
    case +x <> t: sx_show(x) ++ "\n" ++ part_lines(t)

def mt_sx(m: M.Grade) -> Sx:
  M.Gr{n, g, rho, cte} = m
  ls([at("material"), at(U64.show(n)), at(g), at(f_show(rho)), at(f_show(cte))])

def mts_sx(xs: List<&2, M.Grade>) -> List<&2, Sx>:
  match xs:
    case []: []
    case m <> t: mt_sx(m) <> mts_sx(t)

def th_sx(t: M.Thr) -> Sx:
  M.Th{n, nm, f, d, c, z0, z1} = t
  ls([at("thread"), at(U64.show(n)), at(nm), at(f), at(d), at(c), at(f_show(z0)), at(f_show(z1))])

def ths_sx(xs: List<&2, M.Thr>) -> List<&2, Sx>:
  match xs:
    case []: []
    case h <> t: th_sx(h) <> ths_sx(t)

def part_show(+p: M.Part) -> String:
  M.Pt{+ps, ns, +ms, +ts} = p
  "(bendcad 1)\n" ++ part_lines(List.append(&2, Sx, pms_sx(ps), List.append(&2, Sx, nds_sx(ns, nis_of(ps)),
    List.append(&2, Sx, mts_sx(ms), ths_sx(ts)))))

def pm_of(+x: Sx) -> M.Param:
  +xs = sx_xs(x)
  +nom = some_v(num(sx_s(sx_nth(xs, 3n))))
  +lo = num(sx_s(sx_nth(xs, 4n)))
  +hi = num(sx_s(sx_nth(xs, 5n)))
  M.Pm{u64_of(sx_nth(xs, 1n)), sx_s(sx_nth(xs, 2n)),
    M.Dm{nom, Bool.pick(F64, is_some(lo), some_v(lo), nom), Bool.pick(F64, is_some(hi), some_v(hi), nom)}}

def pms_of(xs: List<&2, Sx>) -> List<&2, M.Param>:
  match xs:
    case []: []
    case +x <> t:
      +r = pms_of(t)
      Bool.pick(List<&2, M.Param>, head_is(x, "param"), pm_of(x) <> r, r)

def nd_one(isn: Bool, +x: Sx, +ns: List<&2, NI>) -> List<&2, M.Node>:
  match isn:
    case False{}: []
    case True{}:
      +ys = sx_xs(x)
      [M.Nd{u64_of(sx_nth(ys, 1n)), op_of(sx_nth(ys, 2n), ns), it_of(sx_nth(ys, 3n))}]

def nds_of(xs: List<&2, Sx>, +ns: List<&2, NI>) -> List<&2, M.Node>:
  match xs:
    case []: []
    case +x <> t: List.append(&2, M.Node, nd_one(head_is(x, "node"), x, ns), nds_of(t, ns))

def fnum_or(+x: Sx) -> F64:
  +n = num(sx_s(x))
  Bool.pick(F64, is_some(n), some_v(n), F64.nan())

def mt_of(+x: Sx) -> M.Grade:
  +xs = sx_xs(x)
  M.Gr{u64_of(sx_nth(xs, 1n)), sx_s(sx_nth(xs, 2n)), fnum_or(sx_nth(xs, 3n)), fnum_or(sx_nth(xs, 4n))}

def mts_of(xs: List<&2, Sx>) -> List<&2, M.Grade>:
  match xs:
    case []: []
    case +x <> t:
      +r = mts_of(t)
      Bool.pick(List<&2, M.Grade>, head_is(x, "material"), mt_of(x) <> r, r)

def th_of(+x: Sx) -> M.Thr:
  +xs = sx_xs(x)
  M.Th{u64_of(sx_nth(xs, 1n)), sx_s(sx_nth(xs, 2n)), sx_s(sx_nth(xs, 3n)), sx_s(sx_nth(xs, 4n)), sx_s(sx_nth(xs, 5n)),
    fnum_or(sx_nth(xs, 6n)), fnum_or(sx_nth(xs, 7n))}

def ths_of(xs: List<&2, Sx>) -> List<&2, M.Thr>:
  match xs:
    case []: []
    case +x <> t:
      +r = ths_of(t)
      Bool.pick(List<&2, M.Thr>, head_is(x, "thread"), th_of(x) <> r, r)

def part_of(+xs: List<&2, Sx>) -> M.Part:
  +ps = pms_of(xs)
  M.Pt{ps, nds_of(xs, nis_of(ps)), mts_of(xs), ths_of(xs)}

def arg_at(xs: List<&2, String>, +i: Nat) -> String:
  match xs:
    case []: ""
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: arg_at(t, j)

def ps_xs(r: PS) -> List<&2, Sx>:
  PS{ok, xs} = r
  xs

def args_l(xs: List<String>) -> List<&2, String>:
  match xs:
    case []: []
    case x <> t: x <> args_l(t)
