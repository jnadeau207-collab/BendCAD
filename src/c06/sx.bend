import Base
import ./xp.bend as X
import ./prof.bend as F
import ./model.bend as M

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
  Chr{x} = c
  x

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

def f_rt(m: Maybe<&2, F64>, +v: F64) -> Bool:
  match m:
    case None{}: False{}
    case Some{w}: U64.is_eq(F64.bits(w), F64.bits(v))

def f_show_d(whole: Bool, +n: U64, +v: F64) -> String:
  match whole:
    case True{}: U64.show(n)
    case False{}:
      +s = F64.show(v)
      Bool.pick(String, f_rt(F64.read(s), v), s, "b:" ++ U64.show(F64.bits(v)))

def f_show(+v: F64) -> String:
  +n = F64.to_u64(v)
  f_show_d(U64.is_eq(F64.bits(U64.to_f64(n)), F64.bits(v)), n, v)

def pfx_b(s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{h, t}:
      match t:
        case SNil{}: False{}
        case SCon{h2, u}: Bool.and(U32.is_eq(chr_code(h), 98), U32.is_eq(chr_code(h2), 58))

def drop2(s: String) -> String:
  match s:
    case SNil{}: SNil{}
    case SCon{h, t}:
      match t:
        case SNil{}: SNil{}
        case SCon{h2, u}: u

def bits_of(m: Maybe<&2, U64>) -> Maybe<&2, F64>:
  match m:
    case None{}: None{}
    case Some{b}: Some{F64{b}}

def is_dg(+c: U32) -> Bool:
  Bool.and(U32.is_le(48, c), U32.is_le(c, 57))

def dg_v(c: U32) -> U64:
  U32.to_u64(U32.sub(c, 48))

def is_ech(+c: U32) -> Bool:
  Bool.or(U32.is_eq(c, 101), U32.is_eq(c, 69))

def dp_ph(+ph: U64, +c: U32) -> U64:
  Bool.pick(U64, is_dg(c), Bool.pick(U64, U64.is_le(ph, 1u64), ph, Bool.pick(U64, U64.is_eq(ph, 9u64), 9u64, 4u64)),
    Bool.pick(U64, Bool.and(U64.is_eq(ph, 0u64), U32.is_eq(c, 46)), 1u64,
      Bool.pick(U64, Bool.and(U64.is_le(ph, 1u64), is_ech(c)), 2u64,
        Bool.pick(U64, Bool.and(U64.is_eq(ph, 2u64), Bool.or(U32.is_eq(c, 43), U32.is_eq(c, 45))), 3u64, 9u64))))

def sig(+ph: U64, +c: U32, +nd: U64) -> Bool:
  Bool.and(Bool.and(is_dg(c), U64.is_le(ph, 1u64)), Bool.or(U64.is_lt(0u64, nd), Bool.not(U32.is_eq(c, 48))))

def dp_mant(+ph: U64, +c: U32, +m: U64, +nd: U64) -> U64:
  Bool.pick(U64, Bool.and(sig(ph, c, nd), U64.is_lt(nd, 19u64)), U64.add(U64.mul(m, 10u64), dg_v(c)), m)

def dp_nd(+ph: U64, +c: U32, +nd: U64) -> U64:
  Bool.pick(U64, sig(ph, c, nd), U64.add(nd, 1u64), nd)

def dp_fk(+ph: U64, +c: U32, +nd: U64, +fk: U64) -> U64:
  Bool.pick(U64, Bool.and(Bool.and(is_dg(c), U64.is_eq(ph, 1u64)), U64.is_lt(nd, 19u64)), U64.add(fk, 1u64), fk)

def dp_es(+ph: U64, +c: U32, es: Bool) -> Bool:
  Bool.or(es, Bool.and(U64.is_eq(ph, 2u64), U32.is_eq(c, 45)))

def dp_e(+ph: U64, +c: U32, +e: U64) -> U64:
  Bool.pick(U64, Bool.and(Bool.and(is_dg(c), U64.is_le(2u64, ph)), U64.is_lt(e, 10000u64)), U64.add(U64.mul(e, 10u64), dg_v(c)), e)

def p10(n: Nat, +p: U64) -> F64:
  match n:
    case 0n: 1.0f64
    case 1n+k: Bool.pick(F64, U64.is_eq(p, 0u64), 1.0f64, F64.mul(10.0f64, p10(k, U64.sub(p, 1u64))))

def dp_syn(+ph: U64, sd: Bool) -> Bool:
  Bool.and(sd, Bool.or(U64.is_le(ph, 1u64), U64.is_eq(ph, 4u64)))

def dp_ok(+nd: U64, +m: U64, +pw: U64) -> Bool:
  Bool.and(U64.is_le(nd, 18u64), Bool.or(U64.is_eq(m, 0u64), Bool.and(U64.is_le(m, 9007199254740992u64), U64.is_le(pw, 22u64))))

def dp_val(+m: U64, +up: Bool, +pw: U64) -> F64:
  +mf = U64.to_f64(m)
  Bool.pick(F64, U64.is_eq(m, 0u64), 0.0f64, Bool.pick(F64, up, F64.mul(mf, p10(22n, pw)), F64.div(mf, p10(22n, pw))))

def dp_fin(+m: U64, +nd: U64, +fk: U64, +es: Bool, +e: U64, +ph: U64, sd: Bool, s0: String) -> Maybe<&2, F64>:
  +up = Bool.and(Bool.not(es), U64.is_le(fk, e))
  +pw = Bool.pick(U64, es, U64.add(e, fk), Bool.pick(U64, up, U64.sub(e, fk), U64.sub(fk, e)))
  Bool.pick(Maybe<&2, F64>, dp_syn(ph, sd), Bool.pick(Maybe<&2, F64>, dp_ok(nd, m, pw), Some{dp_val(m, up, pw)}, F64.read(s0)), None{})

def dp(s: String, +ph: U64, +m: U64, +nd: U64, +fk: U64, +es: Bool, +e: U64, sd: Bool, s0: String) -> Maybe<&2, F64>:
  match s:
    case SNil{}: dp_fin(m, nd, fk, es, e, ph, sd, s0)
    case SCon{h, t}:
      +c = chr_code(h)
      dp(t, dp_ph(ph, c), dp_mant(ph, c, m, nd), dp_nd(ph, c, nd), dp_fk(ph, c, nd, fk), dp_es(ph, c, es), dp_e(ph, c, e), Bool.or(sd, Bool.and(is_dg(c), U64.is_le(ph, 1u64))), s0)

def neg_m(m: Maybe<&2, F64>) -> Maybe<&2, F64>:
  match m:
    case None{}: None{}
    case Some{v}: Some{F64.neg(v)}

def is_minus(s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{h, t}: U32.is_eq(chr_code(h), 45)

def tail_s(s: String) -> String:
  match s:
    case SNil{}: SNil{}
    case SCon{h, t}: t

def dec_pos(+s: String) -> Maybe<&2, F64>:
  dp(s, 0u64, 0u64, 0u64, 0u64, False{}, 0u64, False{}, s)

def dec(+s: String) -> Maybe<&2, F64>:
  Bool.pick(Maybe<&2, F64>, is_minus(s), neg_m(dec_pos(tail_s(s))), dec_pos(s))

def num(+s: String) -> Maybe<&2, F64>:
  Bool.pick(Maybe<&2, F64>, pfx_b(s), bits_of(U64.read(drop2(s))), dec(s))

def is_some(m: Maybe<&2, F64>) -> Bool:
  match m:
    case None{}: False{}
    case Some{v}: True{}

def some_v(m: Maybe<&2, F64>) -> F64:
  match m:
    case None{}: F64.nan()
    case Some{v}: v

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
  M.Sel{u64_of(sx_nth(xs, 1n)), U64.to_nat(u64_of(sx_nth(xs, 2n))),
    Bool.pick(U64, String.eq(sx_s(sx_nth(xs, 3n)), "bottom"), 1u64, 0u64)}

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

def ch_op(+xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  ch_go(len3(xs), xs, ns)

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

def fil5(a5: Bool, +xs: List<&2, Sx>, +ns: List<&2, NI>) -> M.Op:
  match a5:
    case False{}: M.O_unk{"fillet"}
    case True{}: fil5b(fil_edge_ok(sx_nth(xs, 2n)), xs, ns)

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
  M.O_unk{h})))))))))))))))

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
  Bool.pick(M.Op, op_is_feat(h), op_of_feat(h, xs, ns), op_of_core(h, xs, e1, e2, e3, ns))

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
  M.Sel{nd, k, side} = s
  ls([at("face"), at(U64.show(nd)), at(Nat.show(k)), at(Bool.pick(String, U64.is_eq(side, 1u64), "bottom", "top"))])

def amt_sx(+thru: Bool, x: X.Xp, +ns: List<&2, NI>) -> Sx:
  Bool.pick(Sx, thru, at("through"), xp_sx(x, ns))

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

def part_show(+p: M.Part) -> String:
  M.Pt{+ps, ns} = p
  "(bendcad 1)\n" ++ part_lines(List.append(&2, Sx, pms_sx(ps), nds_sx(ns, nis_of(ps))))

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

def part_of(+xs: List<&2, Sx>) -> M.Part:
  +ps = pms_of(xs)
  M.Pt{ps, nds_of(xs, nis_of(ps))}
