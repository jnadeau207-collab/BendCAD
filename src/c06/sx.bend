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

def f_show(+v: F64) -> String:
  +s = F64.show(v)
  Bool.pick(String, f_rt(F64.read(s), v), s, "b:" ++ U64.show(F64.bits(v)))

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

def op_of(+x: Sx, +ns: List<&2, NI>) -> M.Op:
  +xs = sx_xs(x)
  +h = sx_s(sx_nth(xs, 0n))
  +e1 = sx_nth(xs, 1n)
  +e2 = sx_nth(xs, 2n)
  +e3 = sx_nth(xs, 3n)
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
  Bool.pick(M.Op, String.eq(h, "rotate"), M.O_rot{u64_of(e1), axis_of(sx_s(e2)), to_xp(e3, ns)}, M.O_unk{h}))))))))))))

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
