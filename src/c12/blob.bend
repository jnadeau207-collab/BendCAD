import Base
import ../base/num.bend as N
import ../base/par.bend as B
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty

type ES is Data:
  ES{ ok: Bool, s: String, why: String }

type NS is Data:
  NS{ ok: Bool, s: String }

type SP is Data:
  SP{ ok: Bool, xs: List<&2, String> }

type LI is Data:
  LI{ lo: F64, hi: F64 }

type LB is Data:
  LB{ x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64 }

type LC is Data:
  LC{ nv: Nat, ne: Nat, nf: Nat, ns: Nat, genus: Nat }

type IMs is Data:
  IMs{ vol: LI, ar: LI, bb: LB, ct: LC, lin: F64 }

type IR is Data:
  IR{ ok: Bool, m: IMs, why: String }

type PR is Data:
  PR{ ok: Bool, b: Ty.Brep, why: String }

type SX is Data:
  SX{ cur: String, acc: List<&2, String> }

type SNX is Data:
  SNX{ ov: Bool, cur: String, acc: List<&2, String>, n: Nat }

type EB is Data:
  EB{ ok: Bool, b: LB }

type FR is Data:
  FR{ ok: Bool, t: F64 }

type LR is Data:
  LR{ ok: Bool, d: V.Dir, dom: G.Dom }

type UR is Data:
  UR{ ok: Bool, u: F64, v: F64 }

type APR is Data:
  APR{ ok: Bool, b: Ty.Brep, units: String, lineage: String, why: String }

def ver_maj() -> U64:
  1u64

def ver_min() -> U64:
  0u64

def ver_ok(+maj: U64, +min: U64) -> Bool:
  Bool.and(U64.is_eq(maj, ver_maj()), U64.is_le(min, ver_min()))

def es_ok(+s: String) -> ES:
  ES{True{}, s, ""}

def es_fail(+why: String) -> ES:
  ES{False{}, "", why}

def es_ok_of(+r: ES) -> Bool:
  ES{ok, s, why} = r
  ok

def es_s(+r: ES) -> String:
  ES{ok, s, why} = r
  s

def es_why(+r: ES) -> String:
  ES{ok, s, why} = r
  why

def es_app_t2(+w: Bool, +a: ES, +b: ES, +sep: String) -> ES:
  match w:
    case False{}: b
    case True{}: ES{True{}, es_s(a) ++ sep ++ es_s(b), ""}

def es_app_t(+w: Bool, +a: ES, +b: ES, +sep: String) -> ES:
  match w:
    case False{}: a
    case True{}: es_app_t2(es_ok_of(b), a, b, sep)

def es_app(+a: ES, +b: ES, +sep: String) -> ES:
  es_app_t(es_ok_of(a), a, b, sep)

def ns_mk(+ok: Bool, +s: String) -> NS:
  NS{ok, s}

def ns_ok(+r: NS) -> Bool:
  NS{ok, s} = r
  ok

def ns_s(+r: NS) -> String:
  NS{ok, s} = r
  s

def st_num(+v: F64) -> NS:
  NS{N.f_rt(F64.read(F64.show(v)), v), F64.show(v)}

def sp_mk(+ok: Bool, +xs: List<&2, String>) -> SP:
  SP{ok, xs}

def sp_ok(+r: SP) -> Bool:
  SP{ok, xs} = r
  ok

def sp_xs(+r: SP) -> List<&2, String>:
  SP{ok, xs} = r
  xs

def li_mk(+lo: F64, +hi: F64) -> LI:
  LI{lo, hi}

def li_lo(+r: LI) -> F64:
  LI{lo, hi} = r
  lo

def li_hi(+r: LI) -> F64:
  LI{lo, hi} = r
  hi

def lb_mk(+x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64) -> LB:
  LB{x0, x1, y0, y1, z0, z1}

def lb_x0(+r: LB) -> F64:
  LB{x0, x1, y0, y1, z0, z1} = r
  x0

def lb_x1(+r: LB) -> F64:
  LB{x0, x1, y0, y1, z0, z1} = r
  x1

def lb_y0(+r: LB) -> F64:
  LB{x0, x1, y0, y1, z0, z1} = r
  y0

def lb_y1(+r: LB) -> F64:
  LB{x0, x1, y0, y1, z0, z1} = r
  y1

def lb_z0(+r: LB) -> F64:
  LB{x0, x1, y0, y1, z0, z1} = r
  z0

def lb_z1(+r: LB) -> F64:
  LB{x0, x1, y0, y1, z0, z1} = r
  z1

def lc_mk(+nv: Nat, +ne: Nat, +nf: Nat, +ns: Nat, +genus: Nat) -> LC:
  LC{nv, ne, nf, ns, genus}

def lc_nv(+r: LC) -> Nat:
  LC{nv, ne, nf, ns, genus} = r
  nv

def lc_ne(+r: LC) -> Nat:
  LC{nv, ne, nf, ns, genus} = r
  ne

def lc_nf(+r: LC) -> Nat:
  LC{nv, ne, nf, ns, genus} = r
  nf

def lc_ns(+r: LC) -> Nat:
  LC{nv, ne, nf, ns, genus} = r
  ns

def lc_genus(+r: LC) -> Nat:
  LC{nv, ne, nf, ns, genus} = r
  genus

def im_mk(+vol: LI, +ar: LI, +bb: LB, +ct: LC, +lin: F64) -> IMs:
  IMs{vol, ar, bb, ct, lin}

def im_vol(+r: IMs) -> LI:
  IMs{vol, ar, bb, ct, lin} = r
  vol

def im_ar(+r: IMs) -> LI:
  IMs{vol, ar, bb, ct, lin} = r
  ar

def im_bb(+r: IMs) -> LB:
  IMs{vol, ar, bb, ct, lin} = r
  bb

def im_ct(+r: IMs) -> LC:
  IMs{vol, ar, bb, ct, lin} = r
  ct

def im_lin(+r: IMs) -> F64:
  IMs{vol, ar, bb, ct, lin} = r
  lin

def ir_ok(+m: IMs) -> IR:
  IR{True{}, m, ""}

def ir_fail(+why: String) -> IR:
  IR{False{}, IMs{LI{0.0f64, 0.0f64}, LI{0.0f64, 0.0f64}, LB{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}, LC{0n, 0n, 0n, 0n, 0n}, 0.0f64}, why}

def ir_ok_of(+r: IR) -> Bool:
  IR{ok, m, why} = r
  ok

def ir_m(+r: IR) -> IMs:
  IR{ok, m, why} = r
  m

def ir_why(+r: IR) -> String:
  IR{ok, m, why} = r
  why

def pr_ok(+b: Ty.Brep) -> PR:
  PR{True{}, b, ""}

def pr_fail(+why: String) -> PR:
  PR{False{}, Ty.brep_empty(), why}

def pr_ok_of(+r: PR) -> Bool:
  PR{ok, b, why} = r
  ok

def pr_b(+r: PR) -> Ty.Brep:
  PR{ok, b, why} = r
  b

def pr_why(+r: PR) -> String:
  PR{ok, b, why} = r
  why

def s_rev(s: String, +acc: String) -> String:
  match s:
    case SNil{}: acc
    case SCon{h, t}: s_rev(t, SCon{h, acc})

def s_len_go(s: String, +n: Nat) -> Nat:
  match s:
    case SNil{}: n
    case SCon{h, t}: s_len_go(t, Nat.add(n, 1n))

def s_len(+s: String) -> Nat:
  s_len_go(s, 0n)

def is_ws(+c: U32) -> Bool:
  Bool.or(U32.is_eq(c, 32), Bool.or(U32.is_eq(c, 9), Bool.or(U32.is_eq(c, 10), U32.is_eq(c, 13))))

def s_trim_go(+s: String, +done: Bool, +best: String) -> String:
  match s:
    case SNil{}: best
    case SCon{h, t}:
      match done:
        case True{}: best
        case False{}:
          +w = is_ws(N.chr_code(h))
          s_trim_go(t, Bool.not(w), Bool.pick(String, w, best, s))

def s_trim_l(s: String) -> String:
  s_trim_go(s, False{}, "")

def s_trim(+s: String) -> String:
  s_rev(s_trim_l(s_rev(s_trim_l(s), "")), "")

def s_split_nx(+w: Bool, +h: Char, +cur: String, +acc: List<&2, String>) -> SX:
  match w:
    case True{}: SX{"", s_rev(cur, "") <> acc}
    case False{}: SX{SCon{h, cur}, acc}

def sx_cur(+r: SX) -> String:
  SX{cur, acc} = r
  cur

def sx_acc(+r: SX) -> List<&2, String>:
  SX{cur, acc} = r
  acc

def s_split_go(s: String, +sep: U32, +cur: String, +acc: List<&2, String>) -> List<&2, String>:
  match s:
    case SNil{}: List.reverse(&2, String, s_rev(cur, "") <> acc)
    case SCon{+h, t}:
      +nx = s_split_nx(U32.is_eq(N.chr_code(h), sep), h, cur, acc)
      s_split_go(t, sep, sx_cur(nx), sx_acc(nx))

def s_split(+s: String, +sep: U32) -> List<&2, String>:
  s_split_go(s, sep, "", [])

def s_split_n_nx3(+w2: Bool, +cur: String, +acc: List<&2, String>, +n: Nat) -> SNX:
  match w2:
    case True{}: SNX{False{}, "", s_rev(cur, "") <> acc, Nat.add(n, 1n)}
    case False{}: SNX{True{}, "", acc, n}

def s_split_n_nx2(+w: Bool, +w2: Bool, +h: Char, +cur: String, +acc: List<&2, String>, +n: Nat) -> SNX:
  match w:
    case True{}: s_split_n_nx3(w2, cur, acc, n)
    case False{}: SNX{False{}, SCon{h, cur}, acc, n}

def s_split_n_nx(+ov: Bool, +w: Bool, +w2: Bool, +h: Char, +cur: String, +acc: List<&2, String>,
    +n: Nat) -> SNX:
  match ov:
    case True{}: SNX{True{}, "", acc, n}
    case False{}: s_split_n_nx2(w, w2, h, cur, acc, n)

def snx_ov(+r: SNX) -> Bool:
  SNX{ov, cur, acc, n} = r
  ov

def snx_cur(+r: SNX) -> String:
  SNX{ov, cur, acc, n} = r
  cur

def snx_acc(+r: SNX) -> List<&2, String>:
  SNX{ov, cur, acc, n} = r
  acc

def snx_n(+r: SNX) -> Nat:
  SNX{ov, cur, acc, n} = r
  n

def s_split_n_end(+ov: Bool, +cur: String, +acc: List<&2, String>) -> SP:
  match ov:
    case True{}: SP{False{}, []}
    case False{}: SP{True{}, List.reverse(&2, String, s_rev(cur, "") <> acc)}

def s_split_n_go(s: String, +sep: U32, +cur: String, +acc: List<&2, String>, +n: Nat, +mx: Nat,
    +ov: Bool) -> SP:
  match s:
    case SNil{}: SP{True{}, List.reverse(&2, String, s_rev(cur, "") <> acc)}
    case SCon{+h, t}:
      +nx = s_split_n_nx(ov, U32.is_eq(N.chr_code(h), sep), Nat.is_lt(n, mx), h, cur, acc, n)
      s_split_n_go(t, sep, snx_cur(nx), snx_acc(nx), snx_n(nx), mx, snx_ov(nx))

def s_split_n(+s: String, +sep: U32, +mx: Nat) -> SP:
  s_split_n_go(s, sep, "", [], 1n, mx, False{})

def up_c(+c: U32) -> U32:
  Bool.pick(U32, Bool.and(U32.is_le(97, c), U32.is_le(c, 122)), U32.sub(c, 32), c)

def s_eq_ci(a: String, +b: String) -> Bool:
  match a:
    case SNil{}:
      match b:
        case SNil{}: True{}
        case SCon{h2, t2}: False{}
    case SCon{h, t}:
      match b:
        case SNil{}: False{}
        case SCon{h2, t2}: Bool.and(U32.is_eq(up_c(N.chr_code(h)), up_c(N.chr_code(h2))), s_eq_ci(t, t2))

def take_go(+fuel: Nat, s: String, +acc: String) -> String:
  match fuel:
    case 0n: s_rev(acc, "")
    case 1n+f:
      match s:
        case SNil{}: s_rev(acc, "")
        case SCon{h, t}: take_go(f, t, SCon{h, acc})

def starts_with(+s: String, +pre: String) -> Bool:
  String.eq(take_go(Nat.add(s_len(pre), 1n), s, ""), pre)

def fld(fs: List<&2, String>, +i: Nat) -> String:
  match fs:
    case []: ""
    case f <> t:
      match i:
        case 0n: f
        case 1n+j: fld(t, j)

def fnum(fs: List<&2, String>, +i: Nat) -> Maybe<&2, F64>:
  N.num(fld(fs, i))

def fnum_f(fs: List<&2, String>, +i: Nat) -> F64:
  N.some_v(fnum(fs, i))

def fnat_t(m: Maybe<&2, U64>) -> Maybe<&2, Nat>:
  match m:
    case None{}: None{}
    case Some{v}: Some{U64.to_nat(v)}

def fnat(fs: List<&2, String>, +i: Nat) -> Maybe<&2, Nat>:
  fnat_t(U64.read(fld(fs, i)))

def fnat_d_t(m: Maybe<&2, Nat>, +dflt: Nat) -> Nat:
  match m:
    case None{}: dflt
    case Some{v}: v

def fnat_d(fs: List<&2, String>, +i: Nat, +dflt: Nat) -> Nat:
  fnat_d_t(fnat(fs, i), dflt)

def fbit(fs: List<&2, String>, +i: Nat) -> Bool:
  String.eq(fld(fs, i), "1")

def jn_go(xs: List<&2, String>, +sep: String, +acc: String) -> String:
  match xs:
    case []: acc
    case x <> t: jn_go(t, sep, acc ++ sep ++ x)

def jn(xs: List<&2, String>, +sep: String) -> String:
  match xs:
    case []: ""
    case x <> t: jn_go(t, sep, x)

def jn_tail(+xs: List<&2, String>, +sep: String) -> String:
  match xs:
    case []: ""
    case x <> t: sep ++ jn(xs, sep)

def u_xor(+a: U64, +b: U64) -> U64:
  U64.and(U64.or(a, b), U64.not(U64.and(a, b)))

def fnv_off() -> U64:
  14695981039346656037u64

def fnv_prime() -> U64:
  1099511628211u64

def fnv_go(s: String, +h: U64) -> U64:
  match s:
    case SNil{}: h
    case SCon{c, t}: fnv_go(t, U64.mul(u_xor(h, U32.to_u64(N.chr_code(c))), fnv_prime()))

def fnv_s(+s: String) -> U64:
  fnv_go(s, fnv_off())

def dot3(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64, +bz: F64) -> F64:
  F64.add(F64.add(F64.mul(ax, bx), F64.mul(ay, by)), F64.mul(az, bz))

def cross3(+ax: F64, +ay: F64, +az: F64, +bx: F64, +by: F64, +bz: F64) -> V.Dir:
  V.Dr{F64.sub(F64.mul(ay, bz), F64.mul(az, by)), F64.sub(F64.mul(az, bx), F64.mul(ax, bz)),
    F64.sub(F64.mul(ax, by), F64.mul(ay, bx))}

def vlen(+x: F64, +y: F64, +z: F64) -> F64:
  F64.sqrt(F64.add(F64.add(F64.mul(x, x), F64.mul(y, y)), F64.mul(z, z)))

def norm3(+x: F64, +y: F64, +z: F64) -> V.Dir:
  +l = vlen(x, y, z)
  V.Dr{F64.div(x, l), F64.div(y, l), F64.div(z, l)}

def perp_t2(+w: Bool, +ax: F64, +ay: F64, +az: F64) -> V.Dir:
  match w:
    case True{}: norm3(0.0f64, F64.neg(az), ay)
    case False{}: norm3(F64.neg(ay), ax, 0.0f64)

def perp_t3(+w: Bool, +ax: F64, +ay: F64, +az: F64) -> V.Dir:
  match w:
    case True{}: norm3(az, 0.0f64, F64.neg(ax))
    case False{}: norm3(F64.neg(ay), ax, 0.0f64)

def perp_t(+w: Bool, +ax: F64, +ay: F64, +az: F64) -> V.Dir:
  match w:
    case True{}: perp_t2(F64.is_le(F64.abs(ax), F64.abs(az)), ax, ay, az)
    case False{}: perp_t3(F64.is_le(F64.abs(ay), F64.abs(az)), ax, ay, az)

def perp_of(+ax: F64, +ay: F64, +az: F64) -> V.Dir:
  perp_t(F64.is_le(F64.abs(ax), F64.abs(ay)), ax, ay, az)

def widen(+x: F64) -> F64:
  F64.add(x, F64.mul(F64.abs(x), 1.7763568394002505e-15f64))

def pi_u() -> F64:
  3.141592653589794f64

def gv_nm(g: G.GVal) -> String:
  match g:
    case G.GV_f{v}: "float"
    case G.GV_p{v}: "point"
    case G.GV_d{v}: "dir"
    case G.GV_v2{v}: "vec2"
    case G.GV_dom{v}: "dom"
    case G.GV_ln{v}: "line"
    case G.GV_pl{v}: "plane"
    case G.GV_cc{v}: "circle"
    case G.GV_bz{v}: "bezier"
    case G.GV_rq{v}: "rational-quadratic"
    case G.GV_bp{v}: "bezier-patch"
    case G.GV_sp{v}: "sphere"
    case G.GV_cy{v}: "cylinder"
    case G.GV_co{v}: "cone"
    case G.GV_to{v}: "torus"
    case G.GV_bb{v}: "bbox"
    case G.GV_nb{v}: "nurbs"
    case G.GV_ts{v}: "trim-seg"
    case G.GV_tb{v}: "trim-bezier"

def f3(+x: F64, +y: F64, +z: F64) -> String:
  N.f_show(x) ++ "," ++ N.f_show(y) ++ "," ++ N.f_show(z)

def pt_s(+p: V.Point) -> String:
  f3(V.pt_x(p), V.pt_y(p), V.pt_z(p))

def dr_s(+d: V.Dir) -> String:
  f3(V.dr_x(d), V.dr_y(d), V.dr_z(d))

def hv_i(+h: Ty.HVertex) -> Nat:
  Ty.HV{i, g} = h
  i

def he_i(+h: Ty.HEdge) -> Nat:
  Ty.HE{i, g} = h
  i

def hc_i(+h: Ty.HCoedge) -> Nat:
  Ty.HC{i, g} = h
  i

def hl_i(+h: Ty.HLoop) -> Nat:
  Ty.HL{i, g} = h
  i

def hf_i(+h: Ty.HFace) -> Nat:
  Ty.HF{i, g} = h
  i

def hs_i(+h: Ty.HShell) -> Nat:
  Ty.HS{i, g} = h
  i

def hso_i(+h: Ty.HSolid) -> Nat:
  Ty.HSo{i, g} = h
  i

def bit_s(+b: Bool) -> String:
  match b:
    case True{}: "1"
    case False{}: "0"

def vs_s_go(vs: List<&2, Ty.Vertex>, +acc: List<&2, String>) -> List<&2, String>:
  match vs:
    case []: List.reverse(&2, String, acc)
    case v <> t: vs_s_go(t, pt_s(Ty.vx_p(v)) <> acc)

def ck_cv(+curve: G.GVal, +lo: F64, +hi: F64) -> ES:
  match curve:
    case G.GV_ln{w}:
      G.Ln{+p, +d} = w
      es_ok("1," ++ pt_s(p) ++ "," ++ dr_s(d) ++ "," ++ N.f_show(lo) ++ "," ++ N.f_show(hi))
    case G.GV_cc{w}:
      G.Cc{+c, +u, +v, +r} = w
      es_ok("2," ++ pt_s(c) ++ "," ++ dr_s(u) ++ "," ++ dr_s(v) ++ "," ++ N.f_show(r) ++ "," ++
        N.f_show(lo) ++ "," ++ N.f_show(hi))
    case G.GV_rq{w}:
      G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
      es_ok("3," ++ pt_s(p0) ++ "," ++ pt_s(p1) ++ "," ++ pt_s(p2) ++ "," ++ N.f_show(w0) ++ "," ++
        N.f_show(w1) ++ "," ++ N.f_show(w2) ++ "," ++ N.f_show(lo) ++ "," ++ N.f_show(hi))
    case G.GV_bz{w}:
      G.Bz{+p0, +p1, +p2, +p3} = w
      es_ok("4," ++ pt_s(p0) ++ "," ++ pt_s(p1) ++ "," ++ pt_s(p2) ++ "," ++ pt_s(p3) ++ "," ++
        N.f_show(lo) ++ "," ++ N.f_show(hi))
    case _: es_fail("payload-curve-not-in-profile " ++ gv_nm(curve))

def ck_s(k: Ty.EdgeKind) -> ES:
  match k:
    case Ty.EK_degenerate{}: es_ok("0")
    case Ty.EK_curve{+curve, +dom}: ck_cv(curve, G.dom_lo(dom), G.dom_hi(dom))

def es_join_go(xs: List<&2, ES>, +sep: String, +acc: ES, +first: Bool) -> ES:
  match xs:
    case []: acc
    case h <> t:
      match first:
        case True{}: es_join_go(t, sep, h, False{})
        case False{}: es_join_go(t, sep, es_app(acc, h, sep), False{})

def es_join(xs: List<&2, ES>, +sep: String) -> ES:
  es_join_go(xs, sep, es_ok(""), True{})

def es_rs(vs: List<&2, Ty.Edge>, +acc: List<&2, ES>) -> List<&2, ES>:
  match vs:
    case []: List.reverse(&2, ES, acc)
    case +e <> t:
      es_rs(t, es_app(es_ok(Nat.show(hv_i(Ty.ed_v0(e))) ++ "," ++ Nat.show(hv_i(Ty.ed_v1(e)))), ck_s(Ty.ed_kind(e)), ",") <> acc)

def tm_s(+t: G.GVal) -> ES:
  match t:
    case G.GV_ts{w}:
      G.Ts{+a, +b} = w
      es_ok("0," ++ N.f_show(V.v2_x(a)) ++ "," ++ N.f_show(V.v2_y(a)) ++ "," ++ N.f_show(V.v2_x(b)) ++ "," ++
        N.f_show(V.v2_y(b)))
    case _: es_fail("payload-trim-not-in-profile " ++ gv_nm(t))

def ces_rs(vs: List<&2, Ty.Coedge>, +acc: List<&2, ES>) -> List<&2, ES>:
  match vs:
    case []: List.reverse(&2, ES, acc)
    case +e <> t:
      ces_rs(t, es_app(es_ok(Nat.show(he_i(Ty.ce_edge(e))) ++ "," ++ bit_s(Ty.ce_fwd(e))), tm_s(Ty.ce_trim(e)), ",") <> acc)

def lk_n(k: Ty.LoopKind) -> Nat:
  match k:
    case Ty.LK_outer{}: 0n
    case Ty.LK_inner{}: 1n

def hcs_s(xs: List<&2, Ty.HCoedge>, +acc: List<&2, String>) -> List<&2, String>:
  match xs:
    case []: List.reverse(&2, String, acc)
    case h <> t: hcs_s(t, Nat.show(hc_i(h)) <> acc)

def lps_s_go(vs: List<&2, Ty.Loop>, +acc: List<&2, String>) -> List<&2, String>:
  match vs:
    case []: List.reverse(&2, String, acc)
    case +e <> t:
      +cs = hcs_s(Ty.lp_ces(e), [])
      lps_s_go(t, (Nat.show(lk_n(Ty.lp_kind(e))) ++ "," ++ Nat.show(List.length(&2, Ty.HCoedge, Ty.lp_ces(e))) ++
        jn_tail(cs, ",")) <> acc)

def sf_s(+g: G.GVal) -> ES:
  match g:
    case G.GV_pl{w}:
      G.Pl{+o, +u, +v} = w
      es_ok("10," ++ pt_s(o) ++ "," ++ dr_s(u) ++ "," ++ dr_s(v))
    case G.GV_sp{w}:
      G.Sp{+c, +r} = w
      es_ok("11," ++ pt_s(c) ++ "," ++ N.f_show(r))
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      es_ok("12," ++ pt_s(o) ++ "," ++ dr_s(a) ++ "," ++ N.f_show(r))
    case G.GV_to{w}:
      G.To{+o, +a, +R, +r} = w
      es_ok("13," ++ pt_s(o) ++ "," ++ dr_s(a) ++ "," ++ N.f_show(R) ++ "," ++ N.f_show(r))
    case G.GV_bp{w}:
      G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32,
        +p33} = w
      es_ok("14," ++ pt_s(p00) ++ "," ++ pt_s(p01) ++ "," ++ pt_s(p02) ++ "," ++ pt_s(p03) ++ "," ++
        pt_s(p10) ++ "," ++ pt_s(p11) ++ "," ++ pt_s(p12) ++ "," ++ pt_s(p13) ++ "," ++
        pt_s(p20) ++ "," ++ pt_s(p21) ++ "," ++ pt_s(p22) ++ "," ++ pt_s(p23) ++ "," ++
        pt_s(p30) ++ "," ++ pt_s(p31) ++ "," ++ pt_s(p32) ++ "," ++ pt_s(p33))
    case _: es_fail("payload-surface-not-in-profile " ++ gv_nm(g))

def hls_s(xs: List<&2, Ty.HLoop>, +acc: List<&2, String>) -> List<&2, String>:
  match xs:
    case []: List.reverse(&2, String, acc)
    case h <> t: hls_s(t, Nat.show(hl_i(h)) <> acc)

def fas_rs(vs: List<&2, Ty.Face>, +acc: List<&2, ES>) -> List<&2, ES>:
  match vs:
    case []: List.reverse(&2, ES, acc)
    case +e <> t:
      +ls = hls_s(Ty.fa_loops(e), [])
      fas_rs(t, es_app(sf_s(Ty.fa_surf(e)),
        es_ok(bit_s(Ty.fa_same(e)) ++ "," ++ Nat.show(List.length(&2, Ty.HLoop, Ty.fa_loops(e))) ++
          jn_tail(ls, ",") ++ "," ++ N.f_show(Ty.fa_slv(e)) ++ "," ++ N.f_show(Ty.fa_sla(e))), ",") <> acc)

def sk_n(k: Ty.ShellKind) -> Nat:
  match k:
    case Ty.SK_outer{}: 0n
    case Ty.SK_inner{}: 1n
    case Ty.SK_open{}: 2n

def hfs_s(xs: List<&2, Ty.HFace>, +acc: List<&2, String>) -> List<&2, String>:
  match xs:
    case []: List.reverse(&2, String, acc)
    case h <> t: hfs_s(t, Nat.show(hf_i(h)) <> acc)

def shs_s_go(vs: List<&2, Ty.Shell>, +acc: List<&2, String>) -> List<&2, String>:
  match vs:
    case []: List.reverse(&2, String, acc)
    case +e <> t:
      +fs = hfs_s(Ty.sh_faces(e), [])
      shs_s_go(t, (Nat.show(sk_n(Ty.sh_kind(e))) ++ "," ++ Nat.show(List.length(&2, Ty.HFace, Ty.sh_faces(e))) ++
        jn_tail(fs, ",")) <> acc)

def hsos_s(xs: List<&2, Ty.HShell>, +acc: List<&2, String>) -> List<&2, String>:
  match xs:
    case []: List.reverse(&2, String, acc)
    case h <> t: hsos_s(t, Nat.show(hs_i(h)) <> acc)

def sos_s_go(vs: List<&2, Ty.Solid>, +acc: List<&2, String>) -> List<&2, String>:
  match vs:
    case []: List.reverse(&2, String, acc)
    case +e <> t:
      +cs = hsos_s(Ty.so_cavities(e), [])
      sos_s_go(t, (Nat.show(hs_i(Ty.so_outer(e))) ++ "," ++
        Nat.show(List.length(&2, Ty.HShell, Ty.so_cavities(e))) ++
        jn_tail(cs, ",")) <> acc)

def hsos2_s(xs: List<&2, Ty.HSolid>, +acc: List<&2, String>) -> List<&2, String>:
  match xs:
    case []: List.reverse(&2, String, acc)
    case h <> t: hsos2_s(t, Nat.show(hso_i(h)) <> acc)

def top_s(+c: Ty.Compound) -> String:
  Ty.Cp{+solids, +shells} = c
  +ss = hsos2_s(solids, [])
  +hs = hsos_s(shells, [])
  Nat.show(List.length(&2, Ty.HSolid, solids)) ++ jn_tail(ss, ",") ++
    ";" ++ Nat.show(List.length(&2, Ty.HShell, shells)) ++
    jn_tail(hs, ",")

def brep_s(+b: Ty.Brep) -> ES:
  +vs = Ty.brep_vs(b)
  +es = Ty.brep_es(b)
  +ces = Ty.brep_ces(b)
  +lps = Ty.brep_lps(b)
  +fas = Ty.brep_fas(b)
  +shs = Ty.brep_shs(b)
  +sos = Ty.brep_sos(b)
  +hd = "B1|" ++ Nat.show(List.length(&2, Ty.Vertex, vs)) ++ "," ++ Nat.show(List.length(&2, Ty.Edge, es)) ++ "," ++
    Nat.show(List.length(&2, Ty.Coedge, ces)) ++ "," ++ Nat.show(List.length(&2, Ty.Loop, lps)) ++ "," ++
    Nat.show(List.length(&2, Ty.Face, fas)) ++ "," ++ Nat.show(List.length(&2, Ty.Shell, shs)) ++ "," ++
    Nat.show(List.length(&2, Ty.Solid, sos)) ++ "|" ++ jn(vs_s_go(vs, []), ";")
  es_app(es_app(es_app(es_app(es_ok(hd), es_join(es_rs(es, []), ";"), "|"), es_join(ces_rs(ces, []), ";"), "|"),
    es_app(es_ok(jn(lps_s_go(lps, []), ";")), es_join(fas_rs(fas, []), ";"), "|"), "|"),
    es_ok(jn(shs_s_go(shs, []), ";") ++ "|" ++ jn(sos_s_go(sos, []), ";") ++ "|" ++ top_s(Ty.brep_top(b))), "|")

def pay_maxlen() -> Nat:
  2000000n

def pay_maxrec() -> Nat:
  500000n

def recs_t(+w: Bool, +sec: String, +sep: U32, +mx: Nat) -> SP:
  match w:
    case True{}: SP{True{}, []}
    case False{}: s_split_n(sec, sep, mx)

def recs_n(+sec: String, +sep: U32, +mx: Nat) -> SP:
  recs_t(String.eq(sec, ""), sec, sep, mx)

def sps_ok(xs: List<&2, SP>) -> Bool:
  match xs:
    case []: True{}
    case h <> t: Bool.and(sp_ok(h), sps_ok(t))

def sp_nth(xs: List<&2, SP>, +i: Nat) -> SP:
  match xs:
    case []: SP{True{}, []}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: sp_nth(t, j)

def gn(+i: Nat) -> U64:
  U64.from_nat(Nat.add(i, 1n))

def pt_of(+fs: List<&2, String>, +i: Nat) -> V.Point:
  V.Pt{fnum_f(fs, i), fnum_f(fs, Nat.add(i, 1n)), fnum_f(fs, Nat.add(i, 2n))}

def dr_of(+fs: List<&2, String>, +i: Nat) -> V.Dir:
  V.Dr{fnum_f(fs, i), fnum_f(fs, Nat.add(i, 1n)), fnum_f(fs, Nat.add(i, 2n))}

def vs_of_go(rs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.Vertex>) -> List<&2, Ty.Vertex>:
  match rs:
    case []: List.reverse(&2, Ty.Vertex, acc)
    case r <> t: vs_of_go(t, Nat.add(i, 1n), Ty.Vx{gn(i), pt_of(s_split(r, 44), 0n)} <> acc)

def ck_t(+k: U64, +fs: List<&2, String>) -> Ty.EdgeKind:
  match k:
    case 0u64: Ty.EK_degenerate{}
    case 1u64:
      Ty.EK_curve{G.GV_ln{G.Ln{pt_of(fs, 3n), dr_of(fs, 6n)}}, G.Dom{fnum_f(fs, 9n), fnum_f(fs, 10n)}}
    case 2u64:
      Ty.EK_curve{G.GV_cc{G.Cc{pt_of(fs, 3n), dr_of(fs, 6n), dr_of(fs, 9n), fnum_f(fs, 12n)}},
        G.Dom{fnum_f(fs, 13n), fnum_f(fs, 14n)}}
    case 3u64:
      Ty.EK_curve{G.GV_rq{G.Rq{pt_of(fs, 3n), pt_of(fs, 6n), pt_of(fs, 9n), fnum_f(fs, 12n), fnum_f(fs, 13n),
        fnum_f(fs, 14n)}}, G.Dom{fnum_f(fs, 15n), fnum_f(fs, 16n)}}
    case 4u64:
      Ty.EK_curve{G.GV_bz{G.Bz{pt_of(fs, 3n), pt_of(fs, 6n), pt_of(fs, 9n), pt_of(fs, 12n)}},
        G.Dom{fnum_f(fs, 15n), fnum_f(fs, 16n)}}
    case _: Ty.EK_degenerate{}

def ck_of(+fs: List<&2, String>) -> Ty.EdgeKind:
  ck_t(U64.from_nat(fnat_d(fs, 2n, 7n)), fs)

def es_of_go(rs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.Edge>) -> List<&2, Ty.Edge>:
  match rs:
    case []: List.reverse(&2, Ty.Edge, acc)
    case r <> t:
      +fs = s_split(r, 44)
      +a = fnat_d(fs, 0n, 0n)
      +b = fnat_d(fs, 1n, 0n)
      es_of_go(t, Nat.add(i, 1n), Ty.Ed{gn(i), Ty.HV{a, gn(a)}, Ty.HV{b, gn(b)}, ck_of(fs)} <> acc)

def tm_t(+k: U64, +fs: List<&2, String>) -> G.GVal:
  match k:
    case 0u64: G.GV_ts{G.Ts{V.V2{fnum_f(fs, 3n), fnum_f(fs, 4n)}, V.V2{fnum_f(fs, 5n), fnum_f(fs, 6n)}}}
    case _: Ty.trim_zero()

def tm_of(+fs: List<&2, String>) -> G.GVal:
  tm_t(U64.from_nat(fnat_d(fs, 2n, 9n)), fs)

def ces_of_go(rs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.Coedge>) -> List<&2, Ty.Coedge>:
  match rs:
    case []: List.reverse(&2, Ty.Coedge, acc)
    case r <> t:
      +fs = s_split(r, 44)
      +e = fnat_d(fs, 0n, 0n)
      ces_of_go(t, Nat.add(i, 1n), Ty.Ce{gn(i), Ty.HE{e, gn(e)}, fbit(fs, 1n), tm_of(fs)} <> acc)

def hcs_of(n: Nat, +fs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.HCoedge>) -> List<&2, Ty.HCoedge>:
  match n:
    case 0n: List.reverse(&2, Ty.HCoedge, acc)
    case 1n+m:
      +x = fnat_d(fs, i, 0n)
      hcs_of(m, fs, Nat.add(i, 1n), Ty.HC{x, gn(x)} <> acc)

def lp_t(+k: U64, +fs: List<&2, String>, +i: Nat) -> Ty.Loop:
  match k:
    case 1u64: Ty.Lp{gn(i), hcs_of(fnat_d(fs, 1n, 0n), fs, 2n, []), Ty.LK_inner{}}
    case _: Ty.Lp{gn(i), hcs_of(fnat_d(fs, 1n, 0n), fs, 2n, []), Ty.LK_outer{}}

def lp_of(+fs: List<&2, String>, +i: Nat) -> Ty.Loop:
  lp_t(U64.from_nat(fnat_d(fs, 0n, 0n)), fs, i)

def lps_of_go(rs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.Loop>) -> List<&2, Ty.Loop>:
  match rs:
    case []: List.reverse(&2, Ty.Loop, acc)
    case r <> t: lps_of_go(t, Nat.add(i, 1n), lp_of(s_split(r, 44), i) <> acc)

def hls_of(n: Nat, +fs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.HLoop>) -> List<&2, Ty.HLoop>:
  match n:
    case 0n: List.reverse(&2, Ty.HLoop, acc)
    case 1n+m:
      +x = fnat_d(fs, i, 0n)
      hls_of(m, fs, Nat.add(i, 1n), Ty.HL{x, gn(x)} <> acc)

def fslv(+fs: List<&2, String>, +nidx: Nat, +lstart: Nat) -> F64:
  fnum_f(fs, Nat.add(lstart, fnat_d(fs, nidx, 0n)))

def fsla(+fs: List<&2, String>, +nidx: Nat, +lstart: Nat) -> F64:
  fnum_f(fs, Nat.add(Nat.add(lstart, 1n), fnat_d(fs, nidx, 0n)))

def fa_t(+k: U64, +fs: List<&2, String>, +i: Nat) -> Ty.Face:
  match k:
    case 10u64:
      Ty.Fa{gn(i), G.GV_pl{G.Pl{pt_of(fs, 1n), dr_of(fs, 4n), dr_of(fs, 7n)}}, hls_of(fnat_d(fs, 11n, 0n), fs, 12n, []),
        fbit(fs, 10n), fslv(fs, 11n, 12n), fsla(fs, 11n, 12n)}
    case 11u64:
      Ty.Fa{gn(i), G.GV_sp{G.Sp{pt_of(fs, 1n), fnum_f(fs, 4n)}}, hls_of(fnat_d(fs, 6n, 0n), fs, 7n, []),
        fbit(fs, 5n), fslv(fs, 6n, 7n), fsla(fs, 6n, 7n)}
    case 12u64:
      Ty.Fa{gn(i), G.GV_cy{G.Cy{pt_of(fs, 1n), dr_of(fs, 4n), fnum_f(fs, 7n)}},
        hls_of(fnat_d(fs, 9n, 0n), fs, 10n, []), fbit(fs, 8n), fslv(fs, 9n, 10n), fsla(fs, 9n, 10n)}
    case 13u64:
      Ty.Fa{gn(i), G.GV_to{G.To{pt_of(fs, 1n), dr_of(fs, 4n), fnum_f(fs, 7n), fnum_f(fs, 8n)}},
        hls_of(fnat_d(fs, 10n, 0n), fs, 11n, []), fbit(fs, 9n), fslv(fs, 10n, 11n), fsla(fs, 10n, 11n)}
    case 14u64:
      Ty.Fa{gn(i), G.GV_bp{G.Bp{pt_of(fs, 1n), pt_of(fs, 4n), pt_of(fs, 7n), pt_of(fs, 10n), pt_of(fs, 13n),
        pt_of(fs, 16n), pt_of(fs, 19n), pt_of(fs, 22n), pt_of(fs, 25n), pt_of(fs, 28n), pt_of(fs, 31n),
        pt_of(fs, 34n), pt_of(fs, 37n), pt_of(fs, 40n), pt_of(fs, 43n), pt_of(fs, 46n)}},
        hls_of(fnat_d(fs, 50n, 0n), fs, 51n, []), fbit(fs, 49n), fslv(fs, 50n, 51n), fsla(fs, 50n, 51n)}
    case _: Ty.Fa{gn(i), Ty.surf_zero(), [], False{}, 0.0f64, 0.0f64}

def fa_of(+fs: List<&2, String>, +i: Nat) -> Ty.Face:
  fa_t(U64.from_nat(fnat_d(fs, 0n, 99n)), fs, i)

def fas_of_go(rs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.Face>) -> List<&2, Ty.Face>:
  match rs:
    case []: List.reverse(&2, Ty.Face, acc)
    case r <> t: fas_of_go(t, Nat.add(i, 1n), fa_of(s_split(r, 44), i) <> acc)

def hfs_of(n: Nat, +fs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.HFace>) -> List<&2, Ty.HFace>:
  match n:
    case 0n: List.reverse(&2, Ty.HFace, acc)
    case 1n+m:
      +x = fnat_d(fs, i, 0n)
      hfs_of(m, fs, Nat.add(i, 1n), Ty.HF{x, gn(x)} <> acc)

def sh_t(+k: U64, +fs: List<&2, String>, +i: Nat) -> Ty.Shell:
  match k:
    case 1u64: Ty.Sh{gn(i), hfs_of(fnat_d(fs, 1n, 0n), fs, 2n, []), Ty.SK_inner{}}
    case 2u64: Ty.Sh{gn(i), hfs_of(fnat_d(fs, 1n, 0n), fs, 2n, []), Ty.SK_open{}}
    case _: Ty.Sh{gn(i), hfs_of(fnat_d(fs, 1n, 0n), fs, 2n, []), Ty.SK_outer{}}

def sh_of(+fs: List<&2, String>, +i: Nat) -> Ty.Shell:
  sh_t(U64.from_nat(fnat_d(fs, 0n, 0n)), fs, i)

def shs_of_go(rs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.Shell>) -> List<&2, Ty.Shell>:
  match rs:
    case []: List.reverse(&2, Ty.Shell, acc)
    case r <> t: shs_of_go(t, Nat.add(i, 1n), sh_of(s_split(r, 44), i) <> acc)

def hss_of(n: Nat, +fs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.HShell>) -> List<&2, Ty.HShell>:
  match n:
    case 0n: List.reverse(&2, Ty.HShell, acc)
    case 1n+m:
      +x = fnat_d(fs, i, 0n)
      hss_of(m, fs, Nat.add(i, 1n), Ty.HS{x, gn(x)} <> acc)

def so_of(+fs: List<&2, String>, +i: Nat) -> Ty.Solid:
  +o = fnat_d(fs, 0n, 0n)
  Ty.So{gn(i), Ty.HS{o, gn(o)}, hss_of(fnat_d(fs, 1n, 0n), fs, 2n, [])}

def sos_of_go(rs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.Solid>) -> List<&2, Ty.Solid>:
  match rs:
    case []: List.reverse(&2, Ty.Solid, acc)
    case r <> t: sos_of_go(t, Nat.add(i, 1n), so_of(s_split(r, 44), i) <> acc)

def hsos_of(n: Nat, +fs: List<&2, String>, +i: Nat, +acc: List<&2, Ty.HSolid>) -> List<&2, Ty.HSolid>:
  match n:
    case 0n: List.reverse(&2, Ty.HSolid, acc)
    case 1n+m:
      +x = fnat_d(fs, i, 0n)
      hsos_of(m, fs, Nat.add(i, 1n), Ty.HSo{x, gn(x)} <> acc)

def top_of(+rs: List<&2, String>) -> Ty.Compound:
  +a = s_split(fld(rs, 0n), 44)
  +b = s_split(fld(rs, 1n), 44)
  Ty.Cp{hsos_of(fnat_d(a, 0n, 0n), a, 1n, []), hss_of(fnat_d(b, 0n, 0n), b, 1n, [])}

def cm_t(m: Maybe<&2, Nat>, +xs: List<&2, String>) -> Bool:
  match m:
    case None{}: False{}
    case Some{n}: Nat.is_eq(n, List.length(&2, String, xs))

def cm_n(+cf: List<&2, String>, +i: Nat, +xs: List<&2, String>) -> Bool:
  cm_t(fnat(cf, i), xs)

def counts_match(+cf: List<&2, String>, +rs: List<&2, SP>) -> Bool:
  Bool.and(cm_n(cf, 0n, sp_xs(sp_nth(rs, 0n))),
    Bool.and(cm_n(cf, 1n, sp_xs(sp_nth(rs, 1n))),
      Bool.and(cm_n(cf, 2n, sp_xs(sp_nth(rs, 2n))),
        Bool.and(cm_n(cf, 3n, sp_xs(sp_nth(rs, 3n))),
          Bool.and(cm_n(cf, 4n, sp_xs(sp_nth(rs, 4n))),
            Bool.and(cm_n(cf, 5n, sp_xs(sp_nth(rs, 5n))), cm_n(cf, 6n, sp_xs(sp_nth(rs, 6n)))))))))

def pay_build_t2(+w: Bool, +b: Ty.Brep) -> PR:
  match w:
    case True{}: pr_ok(b)
    case False{}: pr_fail("payload-not-canonical")

def pay_build_t(+w: Bool, +e: ES, +b: Ty.Brep, +s: String) -> PR:
  match w:
    case False{}: pr_fail("payload-not-canonical")
    case True{}: pay_build_t2(String.eq(es_s(e), s), b)

def br_stamp(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>,
    +lps: List<&2, Ty.Loop>, +fas: List<&2, Ty.Face>, +shs: List<&2, Ty.Shell>,
    +sos: List<&2, Ty.Solid>) -> U64:
  U64.from_nat(Nat.max(List.length(&2, Ty.Vertex, vs), Nat.max(List.length(&2, Ty.Edge, es),
    Nat.max(List.length(&2, Ty.Coedge, ces), Nat.max(List.length(&2, Ty.Loop, lps),
      Nat.max(List.length(&2, Ty.Face, fas), Nat.max(List.length(&2, Ty.Shell, shs),
        List.length(&2, Ty.Solid, sos))))))))

def br_mk(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>,
    +lps: List<&2, Ty.Loop>, +fas: List<&2, Ty.Face>, +shs: List<&2, Ty.Shell>,
    +sos: List<&2, Ty.Solid>, +top: Ty.Compound) -> Ty.Brep:
  Ty.Br{vs, es, ces, lps, fas, shs, sos, top, br_stamp(vs, es, ces, lps, fas, shs, sos)}

def pay_build(+rs: List<&2, SP>, +tp: List<&2, String>, +s: String) -> PR:
  +bvs = vs_of_go(sp_xs(sp_nth(rs, 0n)), 0n, [])
  +bes = es_of_go(sp_xs(sp_nth(rs, 1n)), 0n, [])
  +bces = ces_of_go(sp_xs(sp_nth(rs, 2n)), 0n, [])
  +blps = lps_of_go(sp_xs(sp_nth(rs, 3n)), 0n, [])
  +bfas = fas_of_go(sp_xs(sp_nth(rs, 4n)), 0n, [])
  +bshs = shs_of_go(sp_xs(sp_nth(rs, 5n)), 0n, [])
  +bsos = sos_of_go(sp_xs(sp_nth(rs, 6n)), 0n, [])
  +btop = top_of(tp)
  +b = br_mk(bvs, bes, bces, blps, bfas, bshs, bsos, btop)
  +e = brep_s(b)
  pay_build_t(es_ok_of(e), e, b, s)

def pay_secs_t3(+w: Bool, +rs: List<&2, SP>, +tp: List<&2, String>, +secs: List<&2, String>) -> PR:
  match w:
    case False{}: pr_fail("payload-counts-mismatch")
    case True{}: pay_build(rs, tp, jn(secs, "|"))

def pay_secs_t2(+w: Bool, +rs: List<&2, SP>, +tp: SP, +secs: List<&2, String>) -> PR:
  match w:
    case False{}: pr_fail("payload-records-overflow")
    case True{}: pay_secs_t3(counts_match(s_split(fld(secs, 1n), 44), rs), rs, sp_xs(tp), secs)

def rs_mk(+a: SP, +b: SP, +c: SP, +d: SP, +e: SP, +f: SP, +g: SP) -> List<&2, SP>:
  [a, b, c, d, e, f, g]

def pay_secs_t(+w: Bool, +secs: List<&2, String>) -> PR:
  match w:
    case False{}: pr_fail("payload-bad-magic")
    case True{}:
      +rs = rs_mk(recs_n(fld(secs, 2n), 59, pay_maxrec()), recs_n(fld(secs, 3n), 59, pay_maxrec()),
        recs_n(fld(secs, 4n), 59, pay_maxrec()), recs_n(fld(secs, 5n), 59, pay_maxrec()),
        recs_n(fld(secs, 6n), 59, pay_maxrec()), recs_n(fld(secs, 7n), 59, pay_maxrec()),
        recs_n(fld(secs, 8n), 59, pay_maxrec()))
      +tp = recs_n(fld(secs, 9n), 59, 4n)
      pay_secs_t2(Bool.and(sps_ok(rs), sp_ok(tp)), rs, tp, secs)

def pay_secs(+secs: List<&2, String>) -> PR:
  pay_secs_t(String.eq(fld(secs, 0n), "B1"), secs)

def pay_go_t2(+w: Bool, +sp: SP) -> PR:
  match w:
    case False{}: pr_fail("payload-sections-count")
    case True{}: pay_secs(sp_xs(sp))

def pay_go_t(+w: Bool, +sp: SP) -> PR:
  match w:
    case False{}: pr_fail("payload-sections-overflow")
    case True{}: pay_go_t2(Nat.is_eq(List.length(&2, String, sp_xs(sp)), 10n), sp)

def pay_go(+sp: SP) -> PR:
  pay_go_t(sp_ok(sp), sp)

def pay_brep_t(+w: Bool, +s: String) -> PR:
  match w:
    case False{}: pr_fail("payload-too-large")
    case True{}: pay_go(s_split_n(s, 124, 10n))

def pay_brep(+s: String) -> PR:
  pay_brep_t(Nat.is_le(s_len(s), pay_maxlen()), s)

def pt_eq(+a: V.Point, +b: V.Point) -> Bool:
  Bool.and(F64.is_eq(V.pt_x(a), V.pt_x(b)),
    Bool.and(F64.is_eq(V.pt_y(a), V.pt_y(b)), F64.is_eq(V.pt_z(a), V.pt_z(b))))

def gres_pt_eq(r: G.GRes, +tgt: V.Point) -> Bool:
  match r:
    case G.Gerr{kind}: False{}
    case G.Gok{v}:
      match v:
        case G.GV_p{p}: pt_eq(p, tgt)
        case _: False{}

def lb_hull(+a: LB, +b: LB) -> LB:
  LB{F64.min(lb_x0(a), lb_x0(b)), F64.max(lb_x1(a), lb_x1(b)), F64.min(lb_y0(a), lb_y0(b)),
    F64.max(lb_y1(a), lb_y1(b)), F64.min(lb_z0(a), lb_z0(b)), F64.max(lb_z1(a), lb_z1(b))}

def lb_pt(+p: V.Point) -> LB:
  +x = V.pt_x(p)
  +y = V.pt_y(p)
  +z = V.pt_z(p)
  LB{x, x, y, y, z, z}

def lb_seg(+a: V.Point, +b: V.Point) -> LB:
  lb_hull(lb_pt(a), lb_pt(b))

def lb_cc(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64) -> LB:
  +ex = F64.mul(F64.abs(r), F64.add(F64.abs(V.dr_x(u)), F64.abs(V.dr_x(v))))
  +ey = F64.mul(F64.abs(r), F64.add(F64.abs(V.dr_y(u)), F64.abs(V.dr_y(v))))
  +ez = F64.mul(F64.abs(r), F64.add(F64.abs(V.dr_z(u)), F64.abs(V.dr_z(v))))
  LB{F64.sub(V.pt_x(c), ex), F64.add(V.pt_x(c), ex), F64.sub(V.pt_y(c), ey), F64.add(V.pt_y(c), ey),
    F64.sub(V.pt_z(c), ez), F64.add(V.pt_z(c), ez)}

def lb_rq(+w: G.RQBez) -> LB:
  G.Rq{+p0, +p1, +p2, +w0, +w1, +w2} = w
  lb_hull(lb_seg(p0, p1), lb_pt(p2))

def lb_bz(+w: G.Bez3) -> LB:
  G.Bz{+p0, +p1, +p2, +p3} = w
  lb_hull(lb_seg(p0, p1), lb_seg(p2, p3))

def eb_ok(+b: LB) -> EB:
  EB{True{}, b}

def eb_fail() -> EB:
  EB{False{}, LB{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}}

def eb_ok_of(+r: EB) -> Bool:
  EB{ok, b} = r
  ok

def eb_b(+r: EB) -> LB:
  EB{ok, b} = r
  b

def eb_of(k: Ty.EdgeKind, +p0: V.Point, +p1: V.Point) -> EB:
  match k:
    case Ty.EK_degenerate{}: eb_ok(lb_seg(p0, p1))
    case Ty.EK_curve{+curve, +dom}:
      match curve:
        case G.GV_ln{w}: eb_ok(lb_seg(p0, p1))
        case G.GV_cc{w}:
          G.Cc{+c, +u, +v, +r} = w
          eb_ok(lb_hull(lb_cc(c, u, v, r), lb_seg(p0, p1)))
        case G.GV_rq{w}: eb_ok(lb_hull(lb_rq(w), lb_seg(p0, p1)))
        case G.GV_bz{w}: eb_ok(lb_hull(lb_bz(w), lb_seg(p0, p1)))
        case _: eb_fail()

def vx_pad() -> Ty.Vertex:
  Ty.Vx{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}}

def ce_pad() -> Ty.Coedge:
  Ty.Ce{0u64, Ty.HE{0n, 1u64}, True{}, Ty.trim_zero()}

def lp_pad() -> Ty.Loop:
  Ty.Lp{0u64, [], Ty.LK_outer{}}

def v_get_t(+w: Bool, +tb: B.Tb<&2, Ty.Vertex>, +i: Nat) -> Ty.Vertex:
  match w:
    case True{}: B.tb_get(Ty.Vertex, tb, U32.from_nat(i))
    case False{}: vx_pad()

def v_get(+tb: B.Tb<&2, Ty.Vertex>, +n: Nat, +i: Nat) -> Ty.Vertex:
  v_get_t(Nat.is_lt(i, n), tb, i)

def ebs_of(es: List<&2, Ty.Edge>, +tv: B.Tb<&2, Ty.Vertex>, +nv: Nat,
    +acc: List<&2, EB>) -> List<&2, EB>:
  match es:
    case []: List.reverse(&2, EB, acc)
    case +e <> t:
      +r = eb_of(Ty.ed_kind(e), Ty.vx_p(v_get(tv, nv, hv_i(Ty.ed_v0(e)))),
        Ty.vx_p(v_get(tv, nv, hv_i(Ty.ed_v1(e)))))
      ebs_of(t, tv, nv, r <> acc)

def ebs_ok(xs: List<&2, EB>) -> Bool:
  match xs:
    case []: True{}
    case h <> t: Bool.and(eb_ok_of(h), ebs_ok(t))

def eb_get_t(+w: Bool, +teb: B.Tb<&2, EB>, +i: Nat) -> EB:
  match w:
    case True{}: B.tb_get(EB, teb, U32.from_nat(i))
    case False{}: eb_fail()

def eb_get(+teb: B.Tb<&2, EB>, +ne: Nat, +i: Nat) -> EB:
  eb_get_t(Nat.is_lt(i, ne), teb, i)

def lp_box(hs: List<&2, Ty.HCoedge>, +tce: B.Tb<&2, Ty.Coedge>, +nce: Nat, +teb: B.Tb<&2, EB>,
    +ne: Nat, +acc: LB, +ok: Bool) -> EB:
  match hs:
    case []: EB{ok, acc}
    case +h <> t:
      +okc = Nat.is_lt(hc_i(h), nce)
      +ce = B.tb_get(Ty.Coedge, tce, U32.from_nat(hc_i(h)))
      +r = eb_get(teb, ne, he_i(Ty.ce_edge(ce)))
      +bok = Bool.and(okc, eb_ok_of(r))
      lp_box(t, tce, nce, teb, ne, Bool.pick(LB, bok, lb_hull(acc, eb_b(r)), acc), Bool.and(ok, bok))

def lps_box(hs: List<&2, Ty.HLoop>, +tlp: B.Tb<&2, Ty.Loop>, +nlp: Nat, +tce: B.Tb<&2, Ty.Coedge>,
    +nce: Nat, +teb: B.Tb<&2, EB>, +ne: Nat, +acc: LB, +seed: LB, +ok: Bool) -> EB:
  match hs:
    case []: EB{ok, acc}
    case +h <> t:
      +okl = Nat.is_lt(hl_i(h), nlp)
      +l = lp_box(Ty.lp_ces(B.tb_get(Ty.Loop, tlp, U32.from_nat(hl_i(h)))), tce, nce, teb, ne, seed, True{})
      +bok = Bool.and(okl, eb_ok_of(l))
      lps_box(t, tlp, nlp, tce, nce, teb, ne, Bool.pick(LB, bok, lb_hull(acc, eb_b(l)), acc), seed,
        Bool.and(ok, bok))

def ax_unit(+a: V.Dir) -> V.Dir:
  norm3(V.dr_x(a), V.dr_y(a), V.dr_z(a))

def corp_t(+o: V.Point, +a: V.Dir, +x: F64, +y: F64, +z: F64) -> F64:
  dot3(F64.sub(x, V.pt_x(o)), F64.sub(y, V.pt_y(o)), F64.sub(z, V.pt_z(o)), V.dr_x(a), V.dr_y(a), V.dr_z(a))

def box_tr_go(+o: V.Point, +a: V.Dir, +b: LB, +k: Nat, +t0: F64, +t1: F64) -> LI:
  match k:
    case 0n: LI{t0, t1}
    case 1n+(+j):
      +x = Bool.pick(F64, U64.is_eq(U64.and(U64.from_nat(j), 1u64), 0u64), lb_x0(b), lb_x1(b))
      +y = Bool.pick(F64, U64.is_eq(U64.and(U64.from_nat(j), 2u64), 0u64), lb_y0(b), lb_y1(b))
      +z = Bool.pick(F64, U64.is_eq(U64.and(U64.from_nat(j), 4u64), 0u64), lb_z0(b), lb_z1(b))
      +t = corp_t(o, a, x, y, z)
      box_tr_go(o, a, b, j, F64.min(t0, t), F64.max(t1, t))

def cy_box(+o: V.Point, +a: V.Dir, +r: F64, +t0: F64, +t1: F64) -> LB:
  +u = ax_unit(a)
  +ux = V.dr_x(u)
  +uy = V.dr_y(u)
  +uz = V.dr_z(u)
  +ar = F64.abs(r)
  +ex = F64.mul(ar, F64.sqrt(F64.max(0.0f64, F64.sub(1.0f64, F64.mul(ux, ux)))))
  +ey = F64.mul(ar, F64.sqrt(F64.max(0.0f64, F64.sub(1.0f64, F64.mul(uy, uy)))))
  +ez = F64.mul(ar, F64.sqrt(F64.max(0.0f64, F64.sub(1.0f64, F64.mul(uz, uz)))))
  +ax0 = F64.add(V.pt_x(o), F64.mul(t0, ux))
  +ax1 = F64.add(V.pt_x(o), F64.mul(t1, ux))
  +ay0 = F64.add(V.pt_y(o), F64.mul(t0, uy))
  +ay1 = F64.add(V.pt_y(o), F64.mul(t1, uy))
  +az0 = F64.add(V.pt_z(o), F64.mul(t0, uz))
  +az1 = F64.add(V.pt_z(o), F64.mul(t1, uz))
  LB{F64.sub(F64.min(ax0, ax1), ex), F64.add(F64.max(ax0, ax1), ex), F64.sub(F64.min(ay0, ay1), ey),
    F64.add(F64.max(ay0, ay1), ey), F64.sub(F64.min(az0, az1), ez), F64.add(F64.max(az0, az1), ez)}

def sp_box(+c: V.Point, +r: F64) -> LB:
  +ar = F64.abs(r)
  LB{F64.sub(V.pt_x(c), ar), F64.add(V.pt_x(c), ar), F64.sub(V.pt_y(c), ar), F64.add(V.pt_y(c), ar),
    F64.sub(V.pt_z(c), ar), F64.add(V.pt_z(c), ar)}

def to_box(+o: V.Point, +a: V.Dir, +R: F64, +r: F64) -> LB:
  +u = ax_unit(a)
  +ux = F64.abs(V.dr_x(u))
  +uy = F64.abs(V.dr_y(u))
  +uz = F64.abs(V.dr_z(u))
  +rr = F64.add(F64.abs(R), F64.abs(r))
  +ar = F64.abs(r)
  +px = F64.sub(1.0f64, F64.mul(ux, ux))
  +py = F64.sub(1.0f64, F64.mul(uy, uy))
  +pz = F64.sub(1.0f64, F64.mul(uz, uz))
  +ex = F64.add(F64.mul(rr, F64.sqrt(F64.max(0.0f64, px))), F64.mul(ar, ux))
  +ey = F64.add(F64.mul(rr, F64.sqrt(F64.max(0.0f64, py))), F64.mul(ar, uy))
  +ez = F64.add(F64.mul(rr, F64.sqrt(F64.max(0.0f64, pz))), F64.mul(ar, uz))
  LB{F64.sub(V.pt_x(o), ex), F64.add(V.pt_x(o), ex), F64.sub(V.pt_y(o), ey), F64.add(V.pt_y(o), ey),
    F64.sub(V.pt_z(o), ez), F64.add(V.pt_z(o), ez)}

def bp_box(+w: G.BezP) -> LB:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32,
    +p33} = w
  lb_hull(lb_hull(lb_hull(lb_seg(p00, p01), lb_seg(p02, p03)), lb_hull(lb_seg(p10, p11), lb_seg(p12, p13))),
    lb_hull(lb_hull(lb_seg(p20, p21), lb_seg(p22, p23)), lb_hull(lb_seg(p30, p31), lb_seg(p32, p33))))

def fa_box(g: G.GVal, +loops: LB, +t0: F64, +t1: F64) -> EB:
  match g:
    case G.GV_pl{w}: eb_ok(loops)
    case G.GV_sp{w}:
      G.Sp{+c, +r} = w
      eb_ok(sp_box(c, r))
    case G.GV_cy{w}:
      G.Cy{+oo, +aa, +r} = w
      eb_ok(cy_box(oo, aa, r, t0, t1))
    case G.GV_to{w}:
      G.To{+oo, +aa, +R, +r} = w
      eb_ok(to_box(oo, aa, R, r))
    case G.GV_bp{w}: eb_ok(bp_box(w))
    case _: eb_fail()

def fa_tr(g: G.GVal, +loops: LB) -> LI:
  match g:
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      +u = ax_unit(a)
      +t = corp_t(o, u, lb_x0(loops), lb_y0(loops), lb_z0(loops))
      box_tr_go(o, u, loops, 8n, t, t)
    case _: LI{0.0f64, 0.0f64}

def seg_len2(+a: V.Point, +b: V.Point) -> F64:
  dot3(F64.sub(V.pt_x(b), V.pt_x(a)), F64.sub(V.pt_y(b), V.pt_y(a)), F64.sub(V.pt_z(b), V.pt_z(a)),
    F64.sub(V.pt_x(b), V.pt_x(a)), F64.sub(V.pt_y(b), V.pt_y(a)), F64.sub(V.pt_z(b), V.pt_z(a)))

def bp_du(+w: G.BezP) -> F64:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32,
    +p33} = w
  +m0 = F64.max(seg_len2(p00, p10), seg_len2(p10, p20))
  +m1 = F64.max(seg_len2(p20, p30), seg_len2(p01, p11))
  +m2 = F64.max(seg_len2(p11, p21), seg_len2(p21, p31))
  +m3 = F64.max(seg_len2(p02, p12), seg_len2(p12, p22))
  +m4 = F64.max(seg_len2(p22, p32), seg_len2(p03, p13))
  +m5 = F64.max(seg_len2(p13, p23), seg_len2(p23, p33))
  F64.sqrt(F64.max(F64.max(m0, m1), F64.max(F64.max(m2, m3), F64.max(m4, m5))))

def bp_dv(+w: G.BezP) -> F64:
  G.Bp{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31, +p32,
    +p33} = w
  +m0 = F64.max(seg_len2(p00, p01), seg_len2(p01, p02))
  +m1 = F64.max(seg_len2(p02, p03), seg_len2(p10, p11))
  +m2 = F64.max(seg_len2(p11, p12), seg_len2(p12, p13))
  +m3 = F64.max(seg_len2(p20, p21), seg_len2(p21, p22))
  +m4 = F64.max(seg_len2(p22, p23), seg_len2(p30, p31))
  +m5 = F64.max(seg_len2(p31, p32), seg_len2(p32, p33))
  F64.sqrt(F64.max(F64.max(m0, m1), F64.max(F64.max(m2, m3), F64.max(m4, m5))))

def fa_area_hi(g: G.GVal, +b: LB, +t0: F64, +t1: F64) -> F64:
  match g:
    case G.GV_pl{w}:
      widen(F64.add(F64.add(F64.mul(F64.sub(lb_x1(b), lb_x0(b)), F64.sub(lb_y1(b), lb_y0(b))),
        F64.mul(F64.sub(lb_y1(b), lb_y0(b)), F64.sub(lb_z1(b), lb_z0(b)))),
        F64.mul(F64.sub(lb_z1(b), lb_z0(b)), F64.sub(lb_x1(b), lb_x0(b)))))
    case G.GV_sp{w}:
      G.Sp{+c, +r} = w
      widen(F64.mul(F64.mul(4.0f64, pi_u()), F64.mul(r, r)))
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      widen(F64.mul(F64.mul(F64.mul(2.0f64, pi_u()), F64.abs(r)), F64.max(0.0f64, F64.sub(t1, t0))))
    case G.GV_to{w}:
      G.To{+o, +a, +R, +r} = w
      widen(F64.mul(F64.mul(F64.mul(4.0f64, pi_u()), pi_u()), F64.mul(F64.abs(R), F64.abs(r))))
    case G.GV_bp{+w}: widen(F64.mul(F64.mul(9.0f64, bp_du(w)), bp_dv(w)))
    case _: 0.0f64

def fas_ms_end(+ok: Bool, +ah: F64, +bb: LB) -> IR:
  match ok:
    case True{}: ir_ok(IMs{LI{0.0f64, 0.0f64}, LI{0.0f64, ah}, bb, LC{0n, 0n, 0n, 0n, 0n}, 0.0f64})
    case False{}: ir_fail("import-surface-not-bounded")

def fas_ms_go(fs: List<&2, Ty.Face>, +tlp: B.Tb<&2, Ty.Loop>, +nlp: Nat, +tce: B.Tb<&2, Ty.Coedge>,
    +nce: Nat, +teb: B.Tb<&2, EB>, +ne: Nat, +seed: LB, +bb: LB, +ah: F64, +ok: Bool) -> IR:
  match fs:
    case []: fas_ms_end(ok, ah, bb)
    case +f <> t:
      +loops = lps_box(Ty.fa_loops(f), tlp, nlp, tce, nce, teb, ne, seed, seed, True{})
      +tr = fa_tr(Ty.fa_surf(f), eb_b(loops))
      +r = fa_box(Ty.fa_surf(f), eb_b(loops), li_lo(tr), li_hi(tr))
      +rok = Bool.and(eb_ok_of(loops), eb_ok_of(r))
      +bb2 = Bool.pick(LB, rok, lb_hull(bb, eb_b(r)), bb)
      +ah2 = Bool.pick(F64, rok, F64.add(ah, fa_area_hi(Ty.fa_surf(f), eb_b(r), li_lo(tr), li_hi(tr))), ah)
      fas_ms_go(t, tlp, nlp, tce, nce, teb, ne, seed, bb2, ah2, Bool.and(ok, rok))

def vx_hull_go(vs: List<&2, Ty.Vertex>, +acc: LB, +any: Bool) -> LB:
  match vs:
    case []: acc
    case v <> t:
      match any:
        case True{}: vx_hull_go(t, lb_hull(acc, lb_pt(Ty.vx_p(v))), True{})
        case False{}: vx_hull_go(t, lb_pt(Ty.vx_p(v)), True{})

def imp_go_t(+w: Bool, +fm: IR, +seed: LB, +nv: Nat, +ne: Nat, +nf: Nat, +ns: Nat, +nlp: Nat,
    +nsh: Nat) -> IR:
  match w:
    case False{}: fm
    case True{}:
      +m = ir_m(fm)
      +bb = lb_hull(seed, im_bb(m))
      +dx = F64.max(0.0f64, F64.sub(lb_x1(bb), lb_x0(bb)))
      +dy = F64.max(0.0f64, F64.sub(lb_y1(bb), lb_y0(bb)))
      +dz = F64.max(0.0f64, F64.sub(lb_z1(bb), lb_z0(bb)))
      +gen = Nat.div(Nat.sub(Nat.add(Nat.add(Nat.mul(2n, nsh), ne), Nat.sub(nlp, nf)), Nat.add(nv, nf)), 2n)
      ir_ok(IMs{LI{0.0f64, widen(F64.mul(F64.mul(dx, dy), dz))}, LI{0.0f64, widen(li_hi(im_ar(m)))}, bb,
        LC{nv, ne, nf, ns, gen}, F64.mul(F64.add(F64.add(dx, dy), dz), 1.7763568394002505e-15f64)})

def imp_go(+fm: IR, +seed: LB, +nv: Nat, +ne: Nat, +nf: Nat, +ns: Nat, +nlp: Nat, +nsh: Nat) -> IR:
  imp_go_t(ir_ok_of(fm), fm, seed, nv, ne, nf, ns, nlp, nsh)

def imp_ms_t(+w: Bool, +fas: List<&2, Ty.Face>, +tlp: B.Tb<&2, Ty.Loop>, +nlp: Nat,
    +tce: B.Tb<&2, Ty.Coedge>, +nce: Nat, +teb: B.Tb<&2, EB>, +ne: Nat, +seed: LB, +nv: Nat, +ne2: Nat,
    +nf: Nat, +ns: Nat, +nsh: Nat) -> IR:
  match w:
    case False{}: ir_fail("import-edge-curve-not-bounded")
    case True{}: imp_go(fas_ms_go(fas, tlp, nlp, tce, nce, teb, ne, seed, seed, 0.0f64, True{}), seed, nv, ne2, nf, ns, nlp, nsh)

def imp_ms(+b: Ty.Brep) -> IR:
  +vs = Ty.brep_vs(b)
  +es = Ty.brep_es(b)
  +ces = Ty.brep_ces(b)
  +lps = Ty.brep_lps(b)
  +fas = Ty.brep_fas(b)
  +shs = Ty.brep_shs(b)
  +sos = Ty.brep_sos(b)
  +nv = List.length(&2, Ty.Vertex, vs)
  +ne = List.length(&2, Ty.Edge, es)
  +nce = List.length(&2, Ty.Coedge, ces)
  +nlp = List.length(&2, Ty.Loop, lps)
  +nf = List.length(&2, Ty.Face, fas)
  +nsh = List.length(&2, Ty.Shell, shs)
  +ns = List.length(&2, Ty.Solid, sos)
  +seed = vx_hull_go(vs, LB{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}, False{})
  +tv = B.tb_of(Ty.Vertex, vs, vx_pad())
  +tce = B.tb_of(Ty.Coedge, ces, ce_pad())
  +tlp = B.tb_of(Ty.Loop, lps, lp_pad())
  +ebs = ebs_of(es, tv, nv, [])
  +teb = B.tb_of(EB, ebs, eb_fail())
  imp_ms_t(ebs_ok(ebs), fas, tlp, nlp, tce, nce, teb, ne, seed, nv, ne, nf, ns, nsh)

def ln_at(+lp: V.Point, +ld: V.Dir, +t: F64, +tgt: V.Point) -> Bool:
  gres_pt_eq(GO.line_eval(G.Ln{lp, ld}, t), tgt)

def f_up(+t: F64, +k: Nat) -> F64:
  F64{U64.add(F64.bits(t), U64.from_nat(k))}

def f_dn(+t: F64, +k: Nat) -> F64:
  F64{U64.sub(F64.bits(t), U64.from_nat(k))}

def fr_ok(+t: F64) -> FR:
  FR{True{}, t}

def fr_fail(+t: F64) -> FR:
  FR{False{}, t}

def fr_ok_of(+r: FR) -> Bool:
  FR{ok, t} = r
  ok

def fr_t(+r: FR) -> F64:
  FR{ok, t} = r
  t

def seek_ln_fr(+w: Bool, +o: F64) -> FR:
  match w:
    case True{}: FR{True{}, o}
    case False{}: FR{False{}, o}

def seek_ln_dn(+w: Bool, +o: F64, +s: Nat) -> FR:
  match w:
    case True{}: FR{True{}, f_dn(o, s)}
    case False{}: FR{False{}, o}

def seek_ln_ud(+wu: Bool, +lp: V.Point, +ld: V.Dir, +tgt: V.Point, +o: F64, +s: Nat) -> FR:
  match wu:
    case True{}: FR{True{}, f_up(o, s)}
    case False{}: seek_ln_dn(ln_at(lp, ld, f_dn(o, s), tgt), o, s)

def seek_ln_hit(+s: Nat, +lp: V.Point, +ld: V.Dir, +tgt: V.Point, +o: F64) -> FR:
  match s:
    case 0n: seek_ln_fr(ln_at(lp, ld, o, tgt), o)
    case 1n+m: seek_ln_ud(ln_at(lp, ld, f_up(o, s), tgt), lp, ld, tgt, o, s)

def seek_ln_best(+h: FR, +best: FR) -> FR:
  FR{+ok, +t} = h
  match ok:
    case True{}: h
    case False{}: best

def seek_ln_go(+k: Nat, +lp: V.Point, +ld: V.Dir, +tgt: V.Point, +o: F64, +mx: Nat, +done: Bool,
    +best: FR) -> FR:
  match k:
    case 0n: best
    case 1n+j:
      match done:
        case True{}: best
        case False{}:
          +h = seek_ln_hit(Nat.sub(mx, k), lp, ld, tgt, o)
          seek_ln_go(j, lp, ld, tgt, o, mx, fr_ok_of(h), seek_ln_best(h, best))

def ln_par_t(+w: Bool, +ld: V.Dir, +r0: FR, +r1: FR, +t0: F64, +t1: F64) -> LR:
  match w:
    case True{}: LR{True{}, ld, G.Dom{fr_t(r0), fr_t(r1)}}
    case False{}: LR{False{}, ld, G.Dom{t0, t1}}

def ln_par_go(+lp: V.Point, +ld: V.Dir, +p0: V.Point, +p1: V.Point, +t0: F64, +t1: F64) -> LR:
  +r0 = seek_ln_go(64n, lp, ld, p0, t0, 64n, False{}, FR{False{}, t0})
  +r1 = seek_ln_go(64n, lp, ld, p1, t1, 64n, False{}, FR{False{}, t1})
  ln_par_t(Bool.and(fr_ok_of(r0), fr_ok_of(r1)), ld, r0, r1, t0, t1)

def ln_par_s(+w: Bool, +p0: V.Point, +p1: V.Point, +lp: V.Point, +ld: V.Dir, +t0: F64, +t1: F64) -> LR:
  match w:
    case True{}: ln_par_go(lp, ld, p0, p1, t0, t1)
    case False{}:
      ln_par_go(lp, V.Dr{F64.neg(V.dr_x(ld)), F64.neg(V.dr_y(ld)), F64.neg(V.dr_z(ld))}, p0, p1,
        F64.neg(t0), F64.neg(t1))

def ln_par(+p0: V.Point, +p1: V.Point, +lp: V.Point, +ld: V.Dir) -> LR:
  +t0 = dot3(F64.sub(V.pt_x(p0), V.pt_x(lp)), F64.sub(V.pt_y(p0), V.pt_y(lp)),
    F64.sub(V.pt_z(p0), V.pt_z(lp)), V.dr_x(ld), V.dr_y(ld), V.dr_z(ld))
  +t1 = dot3(F64.sub(V.pt_x(p1), V.pt_x(lp)), F64.sub(V.pt_y(p1), V.pt_y(lp)),
    F64.sub(V.pt_z(p1), V.pt_z(lp)), V.dr_x(ld), V.dr_y(ld), V.dr_z(ld))
  ln_par_s(F64.is_lt(t0, t1), p0, p1, lp, ld, t0, t1)

def pl_at(+pl: G.Plane3, +u: F64, +v: F64, +tgt: V.Point) -> Bool:
  gres_pt_eq(GO.plane_eval(pl, u, v), tgt)

def off_app(+t: F64, +mag: Nat, +neg: Bool) -> F64:
  match neg:
    case True{}: f_dn(t, mag)
    case False{}: f_up(t, mag)

def ur_ok_of(+r: UR) -> Bool:
  UR{ok, u, v} = r
  ok

def ur_u(+r: UR) -> F64:
  UR{ok, u, v} = r
  u

def ur_v(+r: UR) -> F64:
  UR{ok, u, v} = r
  v

def off_mag(+k: Nat) -> Nat:
  Nat.div(Nat.add(k, 1n), 2n)

def off_neg(+k: Nat) -> Bool:
  match k:
    case 0n: False{}
    case 1n+m: Nat.is_eq(Nat.mod(k, 2n), 0n)

def sk2_best(+hit: Bool, +uu: F64, +vv: F64, +best: UR) -> UR:
  match hit:
    case True{}: UR{True{}, uu, vv}
    case False{}: best

def sk2_go(+k: Nat, +pl: G.Plane3, +tgt: V.Point, +u: F64, +v: F64, +mx: Nat, +tot: Nat, +done: Bool,
    +best: UR) -> UR:
  match k:
    case 0n: best
    case 1n+j:
      match done:
        case True{}: best
        case False{}:
          +kk = Nat.sub(tot, k)
          +ku = Nat.div(kk, mx)
          +kv = Nat.mod(kk, mx)
          +uu = off_app(u, off_mag(ku), off_neg(ku))
          +vv = off_app(v, off_mag(kv), off_neg(kv))
          +hit = pl_at(pl, uu, vv, tgt)
          sk2_go(j, pl, tgt, u, v, mx, tot, hit, sk2_best(hit, uu, vv, best))

def pl_uv(+pl: G.Plane3, +tgt: V.Point) -> UR:
  G.Pl{+o, +u, +v} = pl
  +u0 = dot3(F64.sub(V.pt_x(tgt), V.pt_x(o)), F64.sub(V.pt_y(tgt), V.pt_y(o)),
    F64.sub(V.pt_z(tgt), V.pt_z(o)), V.dr_x(u), V.dr_y(u), V.dr_z(u))
  +v0 = dot3(F64.sub(V.pt_x(tgt), V.pt_x(o)), F64.sub(V.pt_y(tgt), V.pt_y(o)),
    F64.sub(V.pt_z(tgt), V.pt_z(o)), V.dr_x(v), V.dr_y(v), V.dr_z(v))
  sk2_go(1089n, pl, tgt, u0, v0, 33n, 1089n, False{}, UR{False{}, u0, v0})

def bp_at(+bp: G.BezP, +u: F64, +v: F64, +tgt: V.Point) -> Bool:
  gres_pt_eq(GO.bezp_eval(bp, u, v), tgt)

def bc_try_t4(+w: Bool, +c0: V.Vec2, +c1: V.Vec2, +c2: V.Vec2, +c3: V.Vec2) ->
    Maybe<&2, List<&2, V.Vec2>>:
  match w:
    case False{}: None{}
    case True{}: Some{[c0, c1, c2, c3]}

def bc_try_t3(+w: Bool, +bp: G.BezP, +v0: V.Point, +v1: V.Point, +v2: V.Point, +v3: V.Point, +c0: V.Vec2,
    +c1: V.Vec2, +c2: V.Vec2, +c3: V.Vec2) -> Maybe<&2, List<&2, V.Vec2>>:
  match w:
    case False{}: None{}
    case True{}: bc_try_t4(bp_at(bp, V.v2_x(c3), V.v2_y(c3), v3), c0, c1, c2, c3)

def bc_try_t2(+w: Bool, +bp: G.BezP, +v0: V.Point, +v1: V.Point, +v2: V.Point, +v3: V.Point, +c0: V.Vec2,
    +c1: V.Vec2, +c2: V.Vec2, +c3: V.Vec2) -> Maybe<&2, List<&2, V.Vec2>>:
  match w:
    case False{}: None{}
    case True{}: bc_try_t3(bp_at(bp, V.v2_x(c2), V.v2_y(c2), v2), bp, v0, v1, v2, v3, c0, c1, c2, c3)

def bc_try_t1(+w: Bool, +bp: G.BezP, +v0: V.Point, +v1: V.Point, +v2: V.Point, +v3: V.Point, +c0: V.Vec2,
    +c1: V.Vec2, +c2: V.Vec2, +c3: V.Vec2) -> Maybe<&2, List<&2, V.Vec2>>:
  match w:
    case False{}: None{}
    case True{}: bc_try_t2(bp_at(bp, V.v2_x(c1), V.v2_y(c1), v1), bp, v0, v1, v2, v3, c0, c1, c2, c3)

def bc_try(+bp: G.BezP, +v0: V.Point, +v1: V.Point, +v2: V.Point, +v3: V.Point, +c0: V.Vec2,
    +c1: V.Vec2, +c2: V.Vec2, +c3: V.Vec2) -> Maybe<&2, List<&2, V.Vec2>>:
  bc_try_t1(bp_at(bp, V.v2_x(c0), V.v2_y(c0), v0), bp, v0, v1, v2, v3, c0, c1, c2, c3)

def v2_nth(xs: List<&2, V.Vec2>, +i: Nat) -> V.Vec2:
  match xs:
    case []: V.V2{0.0f64, 0.0f64}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: v2_nth(t, j)

def bc_try4(+bp: G.BezP, +v0: V.Point, +v1: V.Point, +v2: V.Point, +v3: V.Point,
    +c: List<&2, V.Vec2>) -> Maybe<&2, List<&2, V.Vec2>>:
  bc_try(bp, v0, v1, v2, v3, v2_nth(c, 0n), v2_nth(c, 1n), v2_nth(c, 2n), v2_nth(c, 3n))

def bc_all(+bp: G.BezP, +v0: V.Point, +v1: V.Point, +v2: V.Point, +v3: V.Point,
    cs: List<&2, List<&2, V.Vec2>>, +acc: List<&2, Maybe<&2, List<&2, V.Vec2>>>) ->
    List<&2, Maybe<&2, List<&2, V.Vec2>>>:
  match cs:
    case []: List.reverse(&2, Maybe<&2, List<&2, V.Vec2>>, acc)
    case c <> t: bc_all(bp, v0, v1, v2, v3, t, bc_try4(bp, v0, v1, v2, v3, c) <> acc)

def bc_pick(xs: List<&2, Maybe<&2, List<&2, V.Vec2>>>) -> Maybe<&2, List<&2, V.Vec2>>:
  match xs:
    case []: None{}
    case m <> t:
      match m:
        case Some{x}: Some{x}
        case None{}: bc_pick(t)

def apr_ok(+r: APR) -> Bool:
  APR{ok, b, units, lineage, why} = r
  ok

def apr_b(+r: APR) -> Ty.Brep:
  APR{ok, b, units, lineage, why} = r
  b

def apr_units(+r: APR) -> String:
  APR{ok, b, units, lineage, why} = r
  units

def apr_lineage(+r: APR) -> String:
  APR{ok, b, units, lineage, why} = r
  lineage

def apr_why(+r: APR) -> String:
  APR{ok, b, units, lineage, why} = r
  why

def apr_fail(+why: String) -> APR:
  APR{False{}, Ty.brep_empty(), "", "", why}

def ar_ver() -> String:
  "BCAD2"

def ar_units_ok(+u: String) -> Bool:
  String.eq(u, "mm")

def ar_bar_go(s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{h, t}: Bool.or(U32.is_eq(N.chr_code(h), 124), ar_bar_go(t))

def ar_bar(+s: String) -> Bool:
  ar_bar_go(s)

def ar_mk_t(+w: Bool, +u: String, +l: String, +b: Ty.Brep) -> ES:
  match w:
    case False{}: es_fail("archive-bad-envelope")
    case True{}: es_app(es_ok(ar_ver() ++ "|" ++ u ++ "|" ++ l ++ "|"), brep_s(b), "")

def ar_mk(+u: String, +l: String, +b: Ty.Brep) -> ES:
  ar_mk_t(Bool.and(ar_units_ok(u), Bool.not(Bool.or(ar_bar(u), ar_bar(l)))), u, l, b)

def ar_drop3(secs: List<&2, String>) -> List<&2, String>:
  match secs:
    case _ <> t:
      match t:
        case _ <> u:
          match u:
            case _ <> rest: rest
            case []: []
        case []: []
    case []: []

def ar_of_t(+w: Bool, +p: PR, +u: String, +l: String) -> APR:
  match w:
    case False{}: APR{False{}, Ty.brep_empty(), u, l, pr_why(p)}
    case True{}: APR{True{}, pr_b(p), u, l, ""}

def ar_of_p(+p: PR, +u: String, +l: String) -> APR:
  ar_of_t(pr_ok_of(p), p, u, l)

def ar_of(+secs: List<&2, String>) -> APR:
  ar_of_p(pay_secs(ar_drop3(secs)), fld(secs, 1n), fld(secs, 2n))

def ar_secs_u(+w: Bool, +secs: List<&2, String>) -> APR:
  match w:
    case False{}: apr_fail("archive-units-not-supported")
    case True{}: ar_of(secs)

def ar_secs_v(+w: Bool, +secs: List<&2, String>) -> APR:
  match w:
    case False{}: apr_fail("archive-bad-version")
    case True{}: ar_secs_u(ar_units_ok(fld(secs, 1n)), secs)

def ar_secs(+secs: List<&2, String>) -> APR:
  ar_secs_v(String.eq(fld(secs, 0n), ar_ver()), secs)

def ar_parse_t2(+w: Bool, +sp: SP) -> APR:
  match w:
    case False{}: apr_fail("archive-sections-count")
    case True{}: ar_secs(sp_xs(sp))

def ar_parse_t(+w: Bool, +sp: SP) -> APR:
  match w:
    case False{}: apr_fail("archive-sections-overflow")
    case True{}: ar_parse_t2(Nat.is_eq(List.length(&2, String, sp_xs(sp)), 13n), sp)

def ar_parse_t0(+w: Bool, +s: String) -> APR:
  match w:
    case False{}: apr_fail("archive-too-large")
    case True{}:
      +sp = s_split_n(s, 124, 13n)
      ar_parse_t(sp_ok(sp), sp)

def ar_parse(+s: String) -> APR:
  ar_parse_t0(Nat.is_le(s_len(s), pay_maxlen()), s)
