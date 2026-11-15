import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ./model.bend as M
import ./tess.bend as TS
import ./sx.bend as S
import ./build.bend as BD
import ./draw.bend as DW
import ../c10/mesh.bend as M10
import ../k1/sf.bend as KS
import ../k2/std.bend as SD
import ./iv.bend as I
import ../c07/sol.bend as SO
import ../c11/qclear.bend as QL
import ../c11/qaccel.bend as QA

def pz() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def dr(+x: F64, +y: F64, +z: F64) -> V.Dir:
  V.Dr{x, y, z}

def fs(+x: F64) -> String:
  DW.f3(x)

type Mc is Data:
  Mc{ wp: List<&2, V.Point>, wt: B.Tb<&2, V.Point>, ts: List<&2, TS.Tri>, tt: B.Tb<&2, TS.Tri>, hx: B.Tb<&2, Bool>, pos: Bool, eps: F64 }

def mc_wp(+c: Mc) -> List<&2, V.Point>:
  Mc{+wp, wt, ts, tt, hx, pos, eps} = c
  wp

def mc_wt(+c: Mc) -> B.Tb<&2, V.Point>:
  Mc{wp, +wt, ts, tt, hx, pos, eps} = c
  wt

def mc_ts(+c: Mc) -> List<&2, TS.Tri>:
  Mc{wp, wt, +ts, tt, hx, pos, eps} = c
  ts

def mc_tt(+c: Mc) -> B.Tb<&2, TS.Tri>:
  Mc{wp, wt, ts, +tt, hx, pos, eps} = c
  tt

def mc_hx(+c: Mc) -> B.Tb<&2, Bool>:
  Mc{wp, wt, ts, tt, +hx, pos, eps} = c
  hx

def mc_pos(+c: Mc) -> Bool:
  Mc{wp, wt, ts, tt, hx, +pos, eps} = c
  pos

def mc_eps(+c: Mc) -> F64:
  Mc{wp, wt, ts, tt, hx, pos, +eps} = c
  eps

type Su is Data:
  Su{ nm: String, d: V.Dir, top: F64, v: DW.Vw, oc: DW.Oc }

def su_nm(+u: Su) -> String:
  Su{+nm, d, top, v, oc} = u
  nm

def su_d(+u: Su) -> V.Dir:
  Su{nm, +d, top, v, oc} = u
  d

def su_top(+u: Su) -> F64:
  Su{nm, d, +top, v, oc} = u
  top

def su_v(+u: Su) -> DW.Vw:
  Su{nm, d, top, +v, oc} = u
  v

def su_oc(+u: Su) -> DW.Oc:
  Su{nm, d, top, v, +oc} = u
  oc

def top_go(pp: List<&2, V.Point>, +acc: F64) -> F64:
  match pp:
    case []: acc
    case +p <> t: top_go(t, F64.max(acc, V.pt_z(p)))

def su4(+nm: String, +v: DW.Vw, +pp: List<&2, V.Point>, +o: DW.Oc) -> Su:
  Su{nm, DW.vw_d(v), top_go(pp, F64.neg(1.0e300f64)), v, o}

def su3(+nm: String, +v: DW.Vw, +pt: B.Tb<&2, V.Point>, +pp: List<&2, V.Point>, +c: Mc) -> Su:
  su4(nm, v, pp, DW.Oc{DW.grid_of(mc_ts(c), pt, DW.bx_ps(pp, DW.bx0()), mc_pos(c)), pt, mc_tt(c), mc_hx(c), True{}, mc_eps(c), 0.1f64})

def su2(+nm: String, +v: DW.Vw, +pp: List<&2, V.Point>, +c: Mc) -> Su:
  su3(nm, v, B.tb_of(V.Point, pp, pz()), pp, c)

def su_mk(+nm: String, +v: DW.Vw, +c: Mc) -> Su:
  su2(nm, v, DW.prjs(mc_wp(c), v), c)

def sus_go(vs: List<&2, DW.Vw>, ns: List<&2, String>, +c: Mc) -> List<&2, Su>:
  match vs:
    case []: []
    case +v <> t:
      match ns:
        case []: []
        case +n <> u: su_mk(n, v, c) <> sus_go(t, u, c)

def sus(+c: Mc) -> List<&2, Su>:
  sus_go([DW.Vw{dr(0.0f64, 0.0f64, 1.0f64), dr(1.0f64, 0.0f64, 0.0f64), dr(0.0f64, 1.0f64, 0.0f64)},
    DW.Vw{dr(0.0f64, 0.0f64, F64.neg(1.0f64)), dr(1.0f64, 0.0f64, 0.0f64), dr(0.0f64, F64.neg(1.0f64), 0.0f64)},
    DW.Vw{dr(1.0f64, 0.0f64, 0.0f64), dr(0.0f64, 1.0f64, 0.0f64), dr(0.0f64, 0.0f64, 1.0f64)},
    DW.Vw{dr(F64.neg(1.0f64), 0.0f64, 0.0f64), dr(0.0f64, F64.neg(1.0f64), 0.0f64), dr(0.0f64, 0.0f64, 1.0f64)},
    DW.Vw{dr(0.0f64, 1.0f64, 0.0f64), dr(0.0f64, 0.0f64, 1.0f64), dr(1.0f64, 0.0f64, 0.0f64)},
    DW.Vw{dr(0.0f64, F64.neg(1.0f64), 0.0f64), dr(1.0f64, 0.0f64, 0.0f64), dr(0.0f64, 0.0f64, 1.0f64)}],
    ["+z", "-z", "+x", "-x", "+y", "-y"], c)

def fv_keys(ts: List<&2, TS.Tri>, fs: List<&2, Nat>, +acc: List<&2, U64>) -> List<&2, U64>:
  match ts:
    case []: acc
    case +t <> r:
      match fs:
        case []: acc
        case +f <> u: fv_keys(r, u, DW.fkey(f, TS.tc(t)) <> DW.fkey(f, TS.tb(t)) <> DW.fkey(f, TS.ta(t)) <> acc)

def uq_u(fuel: Nat, xs: List<&2, U64>, +prev: U64, +acc: List<&2, U64>) -> List<&2, U64>:
  match fuel:
    case 0n: acc
    case 1n+(+k):
      match xs:
        case []: acc
        case +h <> t: uq_u(k, t, h, Bool.pick(List<&2, U64>, U64.is_eq(h, prev), acc, h <> acc))

def uq_sorted(+ks: List<&2, U64>) -> List<&2, U64>:
  List.reverse(&2, U64, uq_u(Nat.add(List.length(&2, U64, ks), 1n), ks, 18446744073709551615u64, []))

def fv_tab(+ts: List<&2, TS.Tri>, +fid: List<&2, Nat>, +nf: Nat) -> B.Tb<&2, List<&2, Nat>>:
  B.tb_of(List<&2, Nat>, List.reverse(&2, List<&2, Nat>, DW.gr_run(uq_sorted(DW.so_u(B.msort(~U64, ~DW.u_lt, fv_keys(ts, fid, [])))), nf)), [])

def fa_rg(vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +d: V.Dir, +m: V.Vec2) -> V.Vec2:
  match vs:
    case []: m
    case +i <> t: fa_rg(t, wt, d, DW.rg_add(DW.dp(DW.pt2(wt, i), d), m))

def rg0() -> V.Vec2:
  V.V2{1.0e300f64, F64.neg(1.0e300f64)}

type Fx is Data:
  Fx{ acc: Bool, dlo: F64, dhi: F64 }

def fx_of2(+acc: Bool, +top: F64, +rg: V.Vec2) -> Fx:
  Fx{acc, F64.sub(top, V.v2_y(rg)), F64.sub(top, V.v2_x(rg))}

def vis_pts(ps: List<&2, V.Point>, +u: Su) -> Bool:
  match ps:
    case []: True{}
    case +q <> t: Bool.and(Bool.not(DW.hid(su_oc(u), DW.prj(su_v(u), q))), vis_pts(t, u))

def rg_pts(ps: List<&2, V.Point>, +d: V.Dir, +m: V.Vec2) -> V.Vec2:
  match ps:
    case []: m
    case +q <> t: rg_pts(t, d, DW.rg_add(DW.dp(q, d), m))

def ts_go(vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +o: V.Point, +a: V.Dir, +m: V.Vec2) -> V.Vec2:
  match vs:
    case []: m
    case +i <> t: ts_go(t, wt, o, a, DW.rg_add(KS.dot(KS.psub(DW.pt2(wt, i), o), a), m))

def nf0(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))

def ax_smp(c: Nat, +o: V.Point, +a: V.Dir, +lo: F64, +st: F64, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match c:
    case 0n: acc
    case 1n+(+k): ax_smp(k, o, a, lo, st, KS.padd(o, F64.add(lo, F64.mul(nf0(k), st)), a) <> acc)

def ax_seg(+o: V.Point, +a: V.Dir, +r: V.Vec2) -> List<&2, V.Point>:
  ax_smp(41n, o, a, V.v2_x(r), F64.div(F64.sub(V.v2_y(r), V.v2_x(r)), 40.0f64), [])

def fx_ax2(+ps: List<&2, V.Point>, +u: Su) -> Fx:
  fx_of2(vis_pts(ps, u), su_top(u), rg_pts(ps, su_d(u), rg0()))

def fx_acc(+x: Fx) -> Bool:
  Fx{+acc, dlo, dhi} = x
  acc

def fx_dhi(+x: Fx) -> F64:
  Fx{acc, dlo, +dhi} = x
  dhi

def fx_dlo(+x: Fx) -> F64:
  Fx{acc, +dlo, dhi} = x
  dlo

type Rl is Data:
  Rl{ st: Nat, s: String }

def rl_st(+r: Rl) -> Nat:
  Rl{+st, s} = r
  st

def rl_s(+r: Rl) -> String:
  Rl{st, +s} = r
  s

def rl_best(+a: Rl, +b: Rl) -> Rl:
  Bool.pick(Rl, Nat.is_le(rl_st(a), rl_st(b)), a, b)

def st_s(+k: Nat) -> String:
  Bool.pick(String, Nat.is_eq(k, 0n), "pass", Bool.pick(String, Nat.is_eq(k, 1n), "not-analyzed", "fail"))

def em_big(rs: List<&2, List<&2, F64>>, +dmax: F64, +depth: F64, +acc: List<&2, F64>) -> List<&2, F64>:
  match rs:
    case []: acc
    case +r <> t:
      em_big(t, dmax, depth, Bool.pick(List<&2, F64>, Bool.and(F64.is_le(SD.fv_go(r, 0n), F64.add(dmax, 1.0e-9f64)), F64.is_le(depth, F64.add(SD.fv_go(r, 1n), 1.0e-9f64))), r, acc))

def em_s(+r: List<&2, F64>) -> String:
  "end mill " ++ fs(SD.fv_go(r, 0n)) ++ " lc=" ++ fs(SD.fv_go(r, 1n)) ++ " (DIN 6527 L)"

def em_rl(+r: List<&2, F64>, +what: String, +dmax: F64, +depth: F64) -> Rl:
  Bool.pick(Rl, SD.row_ok(r), Rl{0n, what ++ " tool=\"" ++ em_s(r) ++ "\""},
    Rl{1n, what ++ " why=no-held-end-mill: none" ++ Bool.pick(String, F64.is_lt(dmax, 1.0e299f64), " of diameter <= " ++ fs(dmax), "") ++ " cuts " ++ fs(depth) ++ " deep (held: DIN 6527 L, 1 to 20 mm, lc up to 38)"})

def mill_side(+what: String, +dmax: F64, +depth: F64) -> Rl:
  em_rl(em_big(SD.tab("endmill"), dmax, depth, []), what, dmax, depth)

def fr(+x: F64, +k: F64) -> Bool:
  F64.is_lt(F64.abs(F64.sub(F64.mul(x, k), KS.f_round(F64.mul(x, k)))), 1.0e-6f64)

def dr_ser(+d: F64) -> Bool:
  Bool.or(Bool.and(Bool.and(F64.is_le(0.999999f64, d), F64.is_le(d, 13.900001f64)), fr(d, 10.0f64)),
    Bool.and(Bool.and(F64.is_le(13.999999f64, d), F64.is_le(d, 16.000001f64)), fr(d, 4.0f64)))

def drill_rl2(+r: List<&2, F64>, +d: F64, +depth: F64, +what: String) -> Rl:
  Bool.pick(Rl, F64.is_le(depth, F64.add(SD.fv_go(r, 2n), 1.0e-9f64)), Rl{0n, what ++ " tool=\"drill " ++ fs(d) ++ " jobber l2=" ++ fs(SD.fv_go(r, 2n)) ++ " (ISO 235)\""},
    em_rl(em_big(SD.tab("endmill"), F64.mul(0.8f64, d), depth, []), what ++ " drill-too-short(l2=" ++ fs(SD.fv_go(r, 2n)) ++ ")", F64.mul(0.8f64, d), depth))

def hole_rl(+ser: Bool, +d: F64, +depth: F64, +what: String) -> Rl:
  Bool.pick(Rl, Bool.and(ser, SD.row_ok(SD.row("drill", d))), drill_rl2(SD.row("drill", d), d, depth, what),
    em_rl(em_big(SD.tab("endmill"), F64.mul(0.8f64, d), depth, []), what ++ " not-a-drill-size interpolate", F64.mul(0.8f64, d), depth))

def cs_go(rs: List<&2, List<&2, F64>>, +d: F64) -> List<&2, F64>:
  match rs:
    case []: []
    case +r <> t: Bool.pick(List<&2, F64>, F64.is_le(d, F64.add(SD.fv_go(r, 0n), 1.0e-9f64)), r, cs_go(t, d))

def csk_rl(+d: F64, +what: String) -> Rl:
  Bool.pick(Rl, SD.row_ok(cs_go(SD.tab("csink"), d)), Rl{0n, what ++ " tool=\"countersink 90 " ++ fs(SD.fv_go(cs_go(SD.tab("csink"), d), 0n)) ++ " (DIN 335 C)\""},
    Rl{1n, what ++ " why=no-held-countersink: seat " ++ fs(d) ++ " is larger than 40"})

def f_lt2(+a: F64, +b: F64) -> B.Sgn:
  B.sgn_pick(F64.is_lt(a, b), F64.is_lt(b, a))

def f_lt(a: F64, b: F64) -> B.Sgn:
  f_lt2(a, b)

def so_f(s: B.So<&2, F64>) -> List<&2, F64>:
  B.So{ok, xs} = s
  xs

def ang_go(vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +o: V.Point, +e1: V.Dir, +e2: V.Dir, +acc: List<&2, F64>) -> List<&2, F64>:
  match vs:
    case []: acc
    case +i <> t: ang_go(t, wt, o, e1, e2, KS.fatan2(KS.dot(KS.psub(DW.pt2(wt, i), o), e2), KS.dot(KS.psub(DW.pt2(wt, i), o), e1)) <> acc)

def gap_go(xs: List<&2, F64>, +prev: F64, +g: F64) -> V.Vec2:
  match xs:
    case []: V.V2{g, prev}
    case +h <> t: gap_go(t, h, F64.max(g, F64.sub(h, prev)))

def full_g(+first: F64, +r: V.Vec2) -> Bool:
  F64.is_lt(F64.max(V.v2_x(r), F64.sub(F64.add(first, KS.two_pi()), V.v2_y(r))), KS.pi())

def full_of(xs: List<&2, F64>) -> Bool:
  match xs:
    case []: False{}
    case +h <> t: full_g(h, gap_go(t, h, 0.0f64))

def rad_go(vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +o: V.Point, +a: V.Dir, +acc: F64) -> F64:
  match vs:
    case []: acc
    case +i <> t: rad_go(t, wt, o, a, F64.max(acc, KS.dlen(KS.cross(KS.psub(DW.pt2(wt, i), o), a))))

type Fi is Data:
  Fi{ k: Nat, n: V.Dir, o: V.Point, r: F64, cc: Bool, full: Bool, rmax: F64, td: F64, tl: F64, pt: F64 }

def fi_k(+f: Fi) -> Nat:
  Fi{+k, n, o, r, cc, full, rmax, td, tl, pt} = f
  k

def fi_n(+f: Fi) -> V.Dir:
  Fi{k, +n, o, r, cc, full, rmax, td, tl, pt} = f
  n

def fi_r(+f: Fi) -> F64:
  Fi{k, n, o, +r, cc, full, rmax, td, tl, pt} = f
  r

def fi_cc(+f: Fi) -> Bool:
  Fi{k, n, o, r, +cc, full, rmax, td, tl, pt} = f
  cc

def fi_full(+f: Fi) -> Bool:
  Fi{k, n, o, r, cc, +full, rmax, td, tl, pt} = f
  full

def fi_rmax(+f: Fi) -> F64:
  Fi{k, n, o, r, cc, full, +rmax, td, tl, pt} = f
  rmax

def fi_td(+f: Fi) -> F64:
  Fi{k, n, o, r, cc, full, rmax, +td, tl, pt} = f
  td

def fi_tl(+f: Fi) -> F64:
  Fi{k, n, o, r, cc, full, rmax, td, +tl, pt} = f
  tl

def fi_o(+f: Fi) -> V.Point:
  Fi{k, n, +o, r, cc, full, rmax, td, tl, pt} = f
  o

def fi_pt(+f: Fi) -> F64:
  Fi{k, n, o, r, cc, full, rmax, td, tl, +pt} = f
  pt

def fi_an2(+k: U64, +a: V.Dir, +o: V.Point, +r: F64, +same: Bool, +vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>) -> Fi:
  Fi{U64.to_nat(k), Bool.pick(V.Dir, Bool.or(same, Bool.not(U64.is_eq(k, 1u64))), a, KS.dscale(F64.neg(1.0f64), a)), o, r, Bool.not(same),
    full_of(so_f(B.msort(~F64, ~f_lt, ang_go(vs, wt, o, KS.perp_of(a), KS.cross(a, KS.perp_of(a)), [])))), rad_go(vs, wt, o, a, 0.0f64), 0.0f64, 0.0f64, 0.0f64}

def fi_an(+sf: KS.SF, +same: Bool, +vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +pl: M.Pl) -> Fi:
  fi_an2(KS.sf_kind(sf), KS.dunit(M.pl_dir(KS.sf_a(sf), pl)), TS.pl_pt(KS.sf_o(sf), pl), KS.sf_r(sf), same, vs, wt)

def hr_find(hs: List<&2, DW.Hr>, +key: DW.Hr) -> DW.Hr:
  match hs:
    case []: key
    case +h <> t: Bool.pick(DW.Hr, DW.sgn_z(DW.hr_cmp(h, key)), h, hr_find(t, key))

def fi_hr(+h: DW.Hr) -> Fi:
  DW.Hr{+o, +a, +c, +r0, +r1, +z0, +z1, +e} = h
  Fi{Bool.pick(Nat, Nat.is_eq(e, 0n), 0n, 7n), a, o, r1, Nat.is_eq(e, 1n), True{}, r1, F64.mul(2.0f64, r1), F64.sub(z1, z0), F64.mul(KS.two_pi(), F64.abs(c))}

def fi_hx(+w: G.Helicoid, +pl: M.Pl, +hs: List<&2, DW.Hr>) -> Fi:
  G.Hx{+o, u, v, +a, +c, r0, z0, dr2, dz} = w
  fi_hr(hr_find(hs, DW.Hr{TS.pl_pt(o, pl), M.pl_dir(a, pl), c, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0n}))

def fi_s(s: G.GVal, +same: Bool, +vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +pl: M.Pl, +hs: List<&2, DW.Hr>) -> Fi:
  match s:
    case G.GV_hx{+w}: fi_hx(w, pl, hs)
    case _: fi_an(KS.sf_of(s), same, vs, wt, pl)

def fi_of(+f: Ty.Face, +vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +pl: M.Pl, +hs: List<&2, DW.Hr>) -> Fi:
  Ty.Fa{g, +s, ls, +same, slv, sla} = f
  fi_s(s, same, vs, wt, pl, hs)

def near1(+c: F64) -> Bool:
  F64.is_lt(0.999999f64, c)

def near0(+c: F64) -> Bool:
  F64.is_lt(F64.abs(c), 1.0e-6f64)

def dep_s(+nm: String, +x: Fx) -> String:
  " setup=" ++ nm ++ " depth=" ++ fs(fx_dhi(x))

def pl_rule(+c: F64, +dmax: F64, +x: Fx, +nm: String) -> Rl:
  Bool.pick(Rl, near1(c), mill_side("plane floor" ++ dep_s(nm, x), dmax, fx_dhi(x)),
    Bool.pick(Rl, near0(c), mill_side("plane wall" ++ dep_s(nm, x), dmax, fx_dhi(x)),
      Bool.pick(Rl, F64.is_lt(c, 0.0f64), Rl{2n, "plane faces away from " ++ nm},
        Rl{1n, "plane inclined to " ++ nm ++ " why=needs 3D surfacing with a ball end mill (not held)"})))

def cy_ax(+cc: Bool, +full: Bool, +d: F64, +dmax: F64, +x: Fx, +nm: String) -> Rl:
  Bool.pick(Rl, Bool.and(cc, full), hole_rl(dr_ser(d), d, fx_dhi(x), "cylinder hole d=" ++ fs(d) ++ dep_s(nm, x)),
    Bool.pick(Rl, cc, mill_side("cylinder inside-radius r=" ++ fs(F64.mul(0.5f64, d)) ++ dep_s(nm, x), F64.min(d, dmax), fx_dhi(x)),
      mill_side("cylinder outside d=" ++ fs(d) ++ dep_s(nm, x), 1.0e300f64, fx_dhi(x))))

def cy_rule(+ax: F64, +fi: Fi, +dmax: F64, +x: Fx, +nm: String) -> Rl:
  Bool.pick(Rl, near1(ax), cy_ax(fi_cc(fi), fi_full(fi), F64.mul(2.0f64, fi_r(fi)), dmax, x, nm),
    Rl{1n, "cylinder across " ++ nm ++ " why=needs 3D surfacing with a ball end mill (not held)"})

def co_cc(+k: F64, +d: F64, +nm: String) -> Rl:
  Bool.pick(Rl, F64.is_lt(F64.abs(F64.sub(k, 1.0f64)), 1.0e-6f64), csk_rl(d, "cone countersink-90 d=" ++ fs(d) ++ " setup=" ++ nm),
    Bool.pick(Rl, F64.is_lt(F64.abs(F64.sub(k, 1.6642794823505182f64)), 0.01f64), Rl{0n, "cone drill-point-118 setup=" ++ nm ++ " tool=\"drill (118 degree point)\""},
      Rl{1n, "cone tan-half-angle=" ++ fs(k) ++ " setup=" ++ nm ++ " why=no held tool for this angle"}))

def co_rule(+ax: F64, +fi: Fi, +nm: String) -> Rl:
  Bool.pick(Rl, Bool.and(near1(ax), fi_cc(fi)), co_cc(fi_r(fi), F64.mul(2.0f64, fi_rmax(fi)), nm),
    Rl{1n, "cone setup=" ++ nm ++ " why=an outside or tilted cone needs a chamfer mill or 3D surfacing (not held)"})

def tap_r3(+what: String, +k: F64, +ok: Bool, +d: F64, +l: F64) -> Rl:
  Bool.pick(Rl, Bool.and(ok, F64.is_lt(0.0f64, k)),
    Bool.pick(Rl, F64.is_le(l, F64.add(F64.mul(k, d), 1.0e-9f64)), Rl{0n, what ++ " tool=\"tap M" ++ fs(d) ++ " rated " ++ fs(k) ++ "xD (DIN 371/376)\""},
      Rl{1n, what ++ " why=deeper than the held taps' rated " ++ fs(k) ++ "xD = " ++ fs(F64.mul(k, d)) ++ "; shorten the thread or tap it from both ends"}),
    Rl{1n, what ++ " why=no held tap for this size and hole type"})

def tap_rl(+r: List<&2, F64>, +thr: Bool, +d: F64, +l: F64, +nm: String) -> Rl:
  tap_r3("helicoid thread M" ++ fs(d) ++ Bool.pick(String, thr, " through", " blind") ++ " length=" ++ fs(l) ++ " setup=" ++ nm,
    Bool.pick(F64, thr, SD.fv_go(r, 2n), SD.fv_go(r, 3n)), SD.row_ok(r), d, l)

def hx_rule(+ax: F64, +fi: Fi, +xo: Fx, +nm: String) -> Rl:
  Bool.pick(Rl, Bool.and(near1(ax), fi_cc(fi)), tap_rl(SD.row("tap", fi_td(fi)), fx_acc(xo), fi_td(fi), fi_tl(fi), nm),
    Rl{1n, "helicoid external-thread setup=" ++ nm ++ " why=thread milling cutters and dies are not held; cut it on the lathe"})

def rule3(+k: Nat, +fi: Fi, +dmax: F64, +x: Fx, +xo: Fx, +nm: String, +d: V.Dir) -> Rl:
  Bool.pick(Rl, Nat.is_eq(k, 1n), pl_rule(DW.dd(fi_n(fi), d), dmax, x, nm),
    Bool.pick(Rl, Nat.is_eq(k, 2n), cy_rule(F64.abs(DW.dd(fi_n(fi), d)), fi, dmax, x, nm),
      Bool.pick(Rl, Nat.is_eq(k, 3n), co_rule(F64.abs(DW.dd(fi_n(fi), d)), fi, nm),
        Bool.pick(Rl, Nat.is_eq(k, 7n), hx_rule(F64.abs(DW.dd(fi_n(fi), d)), fi, xo, nm),
          Rl{1n, "surface setup=" ++ nm ++ " why=sphere, torus or freeform needs 3D surfacing with a ball end mill (not held)"}))))

def rule2(acc: Bool, +fi: Fi, +dmax: F64, +x: Fx, +xo: Fx, +nm: String, +d: V.Dir) -> Rl:
  match acc:
    case False{}: Rl{2n, "unreachable from every setup (material covers part of the face from all six directions)"}
    case True{}: rule3(fi_k(fi), fi, dmax, x, xo, nm, d)

def best_go(xs: List<&2, Fx>, os: List<&2, Fx>, ss: List<&2, Su>, +fi: Fi, +dmax: F64, +acc: Rl) -> Rl:
  match xs:
    case []: acc
    case +x <> t:
      match os:
        case []: acc
        case +o <> u:
          match ss:
            case []: acc
            case +s <> w: best_go(t, u, w, fi, dmax, rl_best(acc, rule2(fx_acc(x), fi, dmax, x, o, su_nm(s), su_d(s))))

def swp(xs: List<&2, Fx>) -> List<&2, Fx>:
  match xs:
    case []: []
    case +a <> t:
      match t:
        case []: [a]
        case +b <> u: b <> a <> swp(u)

def out_u(+cc: Bool, +u: V.Dir) -> V.Dir:
  Bool.pick(V.Dir, cc, KS.dscale(F64.neg(1.0f64), u), u)

def rad_u(+p: V.Point, +o: V.Point, +a: V.Dir) -> V.Dir:
  KS.dunit(KS.cross(a, KS.cross(KS.psub(p, o), a)))

def tor_u(+p: V.Point, +o: V.Point, +a: V.Dir, +r: F64) -> V.Dir:
  KS.dunit(KS.psub(p, KS.padd(o, r, rad_u(p, o, a))))

def off_dir(+f: Fi, +p: V.Point) -> V.Dir:
  Bool.pick(V.Dir, Nat.is_eq(fi_k(f), 1n), fi_n(f),
    Bool.pick(V.Dir, Bool.or(Nat.is_eq(fi_k(f), 2n), Nat.is_eq(fi_k(f), 3n)), out_u(fi_cc(f), rad_u(p, fi_o(f), fi_n(f))),
      Bool.pick(V.Dir, Nat.is_eq(fi_k(f), 4n), out_u(fi_cc(f), KS.dunit(KS.psub(p, fi_o(f)))),
        Bool.pick(V.Dir, Nat.is_eq(fi_k(f), 5n), out_u(fi_cc(f), tor_u(p, fi_o(f), fi_n(f), fi_r(f))), dr(0.0f64, 0.0f64, 0.0f64)))))

def off_go(vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +f: Fi, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match vs:
    case []: acc
    case +i <> t: off_go(t, wt, f, KS.padd(DW.pt2(wt, i), 0.1f64, off_dir(f, DW.pt2(wt, i))) <> acc)

def fx_off(+vs: List<&2, Nat>, +u: Su, +wt: B.Tb<&2, V.Point>, +f: Fi) -> Fx:
  fx_of2(vis_pts(off_go(vs, wt, f, []), u), su_top(u), fa_rg(vs, wt, su_d(u), rg0()))

def fx_one(hx: Bool, +vs: List<&2, Nat>, +s: Su, +wt: B.Tb<&2, V.Point>, +f: Fi) -> Fx:
  match hx:
    case False{}: fx_off(vs, s, wt, f)
    case True{}: fx_ax2(ax_seg(fi_o(f), fi_n(f), ts_go(vs, wt, fi_o(f), fi_n(f), rg0())), s)

def fxs_go(ss: List<&2, Su>, +vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +f: Fi) -> List<&2, Fx>:
  match ss:
    case []: []
    case +s <> t: fx_one(Nat.is_eq(fi_k(f), 7n), vs, s, wt, f) <> fxs_go(t, vs, wt, f)

type Pr is Data:
  Pr{ e: Nat, a: Nat, b: Nat }

def pr_q(same: Bool, +a: U64, +b: U64, +acc: List<&2, Pr>) -> List<&2, Pr>:
  match same:
    case False{}: acc
    case True{}: Pr{DW.k_hi(a), DW.k_lo(a), DW.k_lo(b)} <> acc

def pr_go(fuel: Nat, xs: List<&2, U64>, +acc: List<&2, Pr>) -> List<&2, Pr>:
  match fuel:
    case 0n: acc
    case 1n+(+k):
      match xs:
        case []: acc
        case +a <> +t:
          match t:
            case []: acc
            case +b <> +u:
              +same = Nat.is_eq(DW.k_hi(a), DW.k_hi(b))
              pr_go(k, Bool.pick(List<&2, U64>, same, u, b <> u), pr_q(same, a, b, acc))

def prs2(+ks: List<&2, U64>) -> List<&2, Pr>:
  pr_go(Nat.add(List.length(&2, U64, ks), 1n), ks, [])

def prs_of(+br: Ty.Brep) -> List<&2, Pr>:
  prs2(DW.so_u(B.msort(~U64, ~DW.u_lt, DW.sm_fas(Ty.brep_fas(br), B.tb_of(Ty.Loop, Ty.brep_lps(br), Ty.lp_dflt()), B.tb_of(Ty.Coedge, Ty.brep_ces(br), Ty.ce_dflt()), 0n, []))))

def pr_keys(ps: List<&2, Pr>, +acc: List<&2, U64>) -> List<&2, U64>:
  match ps:
    case []: acc
    case +p <> t:
      Pr{e, +a, +b} = p
      pr_keys(t, DW.fkey(a, b) <> DW.fkey(b, a) <> acc)

def ek_ln2(c: G.GVal) -> Bool:
  match c:
    case G.GV_ln{w}: True{}
    case _: False{}

def ek_ln(k: Ty.EdgeKind) -> Bool:
  match k:
    case Ty.EK_curve{+c, dm}: ek_ln2(c)
    case _: False{}

def rise_go(vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +p: V.Point, +n: V.Dir, +acc: F64) -> F64:
  match vs:
    case []: acc
    case +i <> t: rise_go(t, wt, p, n, F64.max(acc, KS.dot(KS.psub(DW.pt2(wt, i), p), n)))

def cm_go(xa: List<&2, Fx>, xb: List<&2, Fx>, ss: List<&2, Su>, +t: V.Dir, +acc: V.Vec2) -> V.Vec2:
  match xa:
    case []: acc
    case +a <> ra:
      match xb:
        case []: acc
        case +b <> rb:
          match ss:
            case []: acc
            case +s <> rs:
              +both = Bool.and(fx_acc(a), fx_acc(b))
              cm_go(ra, rb, rs, t, V.V2{Bool.pick(F64, Bool.and(both, near0(KS.dot(t, su_d(s)))), 1.0f64, V.v2_x(acc)), Bool.pick(F64, both, 1.0f64, V.v2_y(acc))})

type Ck is Data:
  Ck{ ft: B.Tb<&2, Fi>, fv: B.Tb<&2, List<&2, Nat>>, fx: B.Tb<&2, List<&2, Fx>>, ss: List<&2, Su>, wt: B.Tb<&2, V.Point>, et: B.Tb<&2, Ty.Edge>, vt: B.Tb<&2, V.Point>, nm: B.Tb<&2, String> }

def ck_fi(+c: Ck, +i: Nat) -> Fi:
  Ck{+ft, fv, fx, ss, wt, et, vt, nm} = c
  B.tb_get(Fi, ft, U32.from_nat(i))

def ck_fv(+c: Ck, +i: Nat) -> List<&2, Nat>:
  Ck{ft, +fv, fx, ss, wt, et, vt, nm} = c
  B.tb_get(List<&2, Nat>, fv, U32.from_nat(i))

def ck_fx(+c: Ck, +i: Nat) -> List<&2, Fx>:
  Ck{ft, fv, +fx, ss, wt, et, vt, nm} = c
  B.tb_get(List<&2, Fx>, fx, U32.from_nat(i))

def ck_ss(+c: Ck) -> List<&2, Su>:
  Ck{ft, fv, fx, +ss, wt, et, vt, nm} = c
  ss

def ck_wt(+c: Ck) -> B.Tb<&2, V.Point>:
  Ck{ft, fv, fx, ss, +wt, et, vt, nm} = c
  wt

def ck_ed(+c: Ck, +e: Nat) -> Ty.Edge:
  Ck{ft, fv, fx, ss, wt, +et, vt, nm} = c
  B.tb_get(Ty.Edge, et, U32.from_nat(e))

def ck_vp(+c: Ck, +v: Ty.HVertex) -> V.Point:
  Ck{ft, fv, fx, ss, wt, et, +vt, nm} = c
  B.tb_get(V.Point, vt, U32.from_nat(Ty.hv_idx(v)))

def ck_nm(+c: Ck, +i: Nat) -> String:
  Ck{ft, fv, fx, ss, wt, et, vt, +nm} = c
  B.tb_get(String, nm, U32.from_nat(i))

def cyr3(+ax: F64, +above: Bool, +g: Fi) -> F64:
  Bool.pick(F64, Bool.or(near0(ax), Bool.and(near1(ax), above)), F64.mul(2.0f64, fi_r(g)), 1.0e300f64)

def cyr2(on: Bool, +g: Fi, +f: Fi, +gv: List<&2, Nat>, +wt: B.Tb<&2, V.Point>) -> F64:
  match on:
    case False{}: 1.0e300f64
    case True{}: cyr3(F64.abs(KS.dot(fi_n(g), fi_n(f))), F64.is_lt(1.0e-6f64, rise_go(gv, wt, fi_o(f), fi_n(f), F64.neg(1.0e300f64))), g)

def cyr(+g: Fi, +f: Fi, +gv: List<&2, Nat>, +wt: B.Tb<&2, V.Point>) -> F64:
  cyr2(Bool.and(Bool.and(Nat.is_eq(fi_k(g), 2n), fi_cc(g)), Nat.is_eq(fi_k(f), 1n)), g, f, gv, wt)

def dm_go(xs: List<&2, Nat>, +c: Ck, +f: Fi, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +g <> t: dm_go(t, c, f, F64.min(acc, cyr(ck_fi(c, g), f, ck_fv(c, g), ck_wt(c))))

def pt_s(+p: V.Point) -> String:
  "(" ++ fs(V.pt_x(p)) ++ "," ++ fs(V.pt_y(p)) ++ "," ++ fs(V.pt_z(p)) ++ ")"

def dr_s(+d: V.Dir) -> String:
  "(" ++ fs(V.dr_x(d)) ++ "," ++ fs(V.dr_y(d)) ++ "," ++ fs(V.dr_z(d)) ++ ")"

def cn_line(bad: Bool, +c: Ck, +e: Nat, +a: Nat, +b: Nat, +p: V.Point, +t: V.Dir) -> String:
  match bad:
    case False{}: ""
    case True{}:
      "make corner edge=" ++ Nat.show(e) ++ " faces=" ++ ck_nm(c, a) ++ "," ++ ck_nm(c, b) ++ " at=" ++ pt_s(p) ++ " along=" ++ dr_s(t) ++
        " why=sharp-inside-corner: every setup that reaches both faces looks along the edge, and no rotating tool cuts a sharp inside corner; fix: round it (radius >= 0.5, the smallest held end mill) or cut it by wire EDM status=fail\n"

def cn_t2(+c: Ck, +e: Nat, +a: Nat, +b: Nat, +p0: V.Point, +t: V.Dir, +cm: V.Vec2) -> String:
  cn_line(Bool.and(F64.is_lt(0.5f64, V.v2_y(cm)), F64.is_lt(V.v2_x(cm), 0.5f64)), c, e, a, b, p0, t)

def cn_t(+c: Ck, +e: Nat, +a: Nat, +b: Nat, +p0: V.Point, +p1: V.Point) -> String:
  cn_t2(c, e, a, b, p0, KS.dunit(KS.psub(p1, p0)), cm_go(ck_fx(c, a), ck_fx(c, b), ck_ss(c), KS.dunit(KS.psub(p1, p0)), V.V2{0.0f64, 0.0f64}))

def cn_cv(cv: Bool, +c: Ck, +e: Nat, +a: Nat, +b: Nat, +p0: V.Point, +p1: V.Point) -> String:
  match cv:
    case False{}: ""
    case True{}: cn_t(c, e, a, b, p0, p1)

def cn_ed(+c: Ck, +e: Nat, +a: Nat, +b: Nat, +ed: Ty.Edge, +pl: M.Pl) -> String:
  Ty.Ed{g, +v0, +v1, +k} = ed
  cn_cv(Bool.and(ek_ln(k), F64.is_lt(1.0e-6f64, rise_go(ck_fv(c, b), ck_wt(c), TS.pl_pt(ck_vp(c, v0), pl), fi_n(ck_fi(c, a)), F64.neg(1.0e300f64)))),
    c, e, a, b, TS.pl_pt(ck_vp(c, v0), pl), TS.pl_pt(ck_vp(c, v1), pl))

def cn_pl(pp: Bool, +c: Ck, +e: Nat, +a: Nat, +b: Nat, +pl: M.Pl) -> String:
  match pp:
    case False{}: ""
    case True{}: cn_ed(c, e, a, b, ck_ed(c, e), pl)

def cn_keep(+s: String, +acc: List<&2, String>) -> List<&2, String>:
  Bool.pick(List<&2, String>, String.is_empty(s), acc, s <> acc)

def cn_go(ps: List<&2, Pr>, +c: Ck, +pl: M.Pl, +acc: List<&2, String>) -> List<&2, String>:
  match ps:
    case []: acc
    case +p <> t:
      Pr{+e, +a, +b} = p
      cn_go(t, c, pl, cn_keep(cn_pl(Bool.and(Nat.is_eq(fi_k(ck_fi(c, a)), 1n), Nat.is_eq(fi_k(ck_fi(c, b)), 1n)), c, e, a, b, pl), acc))

type Pp is Data:
  Pp{ nm: String, wmin: F64 }

def tri_n(+t: TS.Tri, +wt: B.Tb<&2, V.Point>) -> V.Dir:
  KS.cross(KS.psub(DW.pt2(wt, TS.tb(t)), DW.pt2(wt, TS.ta(t))), KS.psub(DW.pt2(wt, TS.tc(t)), DW.pt2(wt, TS.ta(t))))

def tri_hi(+t: TS.Tri, +wt: B.Tb<&2, V.Point>, +u: V.Dir) -> F64:
  F64.max(DW.dp(DW.pt2(wt, TS.ta(t)), u), F64.max(DW.dp(DW.pt2(wt, TS.tb(t)), u), DW.dp(DW.pt2(wt, TS.tc(t)), u)))

def ov_two(+c: F64, +l2: F64, +bed: Bool, +br: Bool) -> F64:
  Bool.pick(F64, Bool.and(F64.is_lt(c, F64.neg(0.7071067811865476f64)), Bool.not(Bool.or(bed, br))), F64.mul(0.5f64, l2), 0.0f64)

def ov_one(+n: V.Dir, +hi: F64, +bed: F64, +br: Bool, +pos: Bool, +u: V.Dir) -> F64:
  ov_two(F64.div(Bool.pick(F64, pos, KS.dot(n, u), F64.neg(KS.dot(n, u))), F64.max(KS.dlen(n), 1.0e-300f64)), KS.dlen(n), F64.is_lt(F64.sub(hi, bed), 1.0e-6f64), br)

def ov_go(ts: List<&2, TS.Tri>, fs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +u: V.Dir, +bed: F64, +pos: Bool, +bt: B.Tb<&2, Bool>, +acc: F64) -> F64:
  match ts:
    case []: acc
    case +t <> r:
      match fs:
        case []: acc
        case +f <> w: ov_go(r, w, wt, u, bed, pos, bt, F64.add(acc, ov_one(tri_n(t, wt), tri_hi(t, wt, u), bed, B.tb_get(Bool, bt, U32.from_nat(f)), pos, u)))

def bed_go(ps: List<&2, V.Point>, +u: V.Dir, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +p <> t: bed_go(t, u, F64.min(acc, DW.dp(p, u)))

def wd2(+r1: V.Vec2, +r2: V.Vec2) -> F64:
  F64.min(F64.sub(V.v2_y(r1), V.v2_x(r1)), F64.sub(V.v2_y(r2), V.v2_x(r2)))

def br_one(+fi: Fi, +vs: List<&2, Nat>, +wt: B.Tb<&2, V.Point>, +u: V.Dir, +lim: F64) -> Bool:
  Bool.and(Bool.and(Nat.is_eq(fi_k(fi), 1n), F64.is_lt(KS.dot(fi_n(fi), u), F64.neg(0.9999f64))),
    F64.is_le(wd2(fa_rg(vs, wt, KS.perp_of(u), rg0()), fa_rg(vs, wt, KS.cross(u, KS.perp_of(u)), rg0())), lim))

def br_go(n: Nat, +i: Nat, +ft: B.Tb<&2, Fi>, +fv: B.Tb<&2, List<&2, Nat>>, +wt: B.Tb<&2, V.Point>, +u: V.Dir, +lim: F64) -> List<&2, Bool>:
  match n:
    case 0n: []
    case 1n+(+k): br_one(B.tb_get(Fi, ft, U32.from_nat(i)), B.tb_get(List<&2, Nat>, fv, U32.from_nat(i)), wt, u, lim) <> br_go(k, Nat.add(i, 1n), ft, fv, wt, u, lim)

type Pc is Data:
  Pc{ c: Mc, fid: List<&2, Nat>, ft: B.Tb<&2, Fi>, fv: B.Tb<&2, List<&2, Nat>>, nf: Nat, blim: F64 }

def pc_c(+x: Pc) -> Mc:
  Pc{+c, fid, ft, fv, nf, blim} = x
  c

def pc_fid(+x: Pc) -> List<&2, Nat>:
  Pc{c, +fid, ft, fv, nf, blim} = x
  fid

def pc_br(+x: Pc, +u: V.Dir) -> B.Tb<&2, Bool>:
  Pc{c, fid, +ft, +fv, +nf, +blim} = x
  B.tb_of(Bool, br_go(nf, 0n, ft, fv, mc_wt(c), u, blim), False{})

def or_area(+x: Pc, +u: V.Dir) -> F64:
  ov_go(mc_ts(pc_c(x)), pc_fid(x), mc_wt(pc_c(x)), u, bed_go(mc_wp(pc_c(x)), u, 1.0e300f64), mc_pos(pc_c(x)), pc_br(x, u), 0.0f64)

type Ob is Data:
  Ob{ s: String, a: F64, nm: String }

def ob_add(+nm: String, +a: F64, +acc: Ob) -> Ob:
  Ob{+s, +ba, +bn} = acc
  Ob{s ++ "make orientation up=" ++ nm ++ " support-area=" ++ fs(a) ++ "\n", F64.min(ba, a), Bool.pick(String, F64.is_lt(a, ba), nm, bn)}

def or_go(us: List<&2, V.Dir>, ns: List<&2, String>, +x: Pc, +acc: Ob) -> Ob:
  match us:
    case []: acc
    case +u <> t:
      match ns:
        case []: acc
        case +n <> w: or_go(t, w, x, ob_add(n, or_area(x, u), acc))

def or_dirs() -> List<&2, V.Dir>:
  [dr(0.0f64, 0.0f64, 1.0f64), dr(0.0f64, 0.0f64, F64.neg(1.0f64)), dr(1.0f64, 0.0f64, 0.0f64), dr(F64.neg(1.0f64), 0.0f64, 0.0f64), dr(0.0f64, 1.0f64, 0.0f64), dr(0.0f64, F64.neg(1.0f64), 0.0f64)]

def wl_st(+lo: F64, +hi: F64, +lim: F64) -> Nat:
  Bool.pick(Nat, F64.is_le(lim, lo), 0n, Bool.pick(Nat, F64.is_lt(hi, lim), 2n, 1n))

def pr_f2(+s: String, +a: F64, +bn: String, +ws: Nat, +w: I.I, +wok: Bool, +nd: U64, +nm: String, +lim: F64) -> String:
  "make node " ++ U64.show(nd) ++ " process=" ++ nm ++ " (rules: overhangs steeper than 45 degrees from vertical need support, horizontal spans up to 5 mm bridge, walls at least " ++ fs(lim) ++
    " mm; Hubs design guidelines, docs/std.md)\n" ++ s ++
    "make wall " ++ Bool.pick(String, wok, "min-wall [" ++ S.f_show(I.i_lo(w)) ++ ", " ++ S.f_show(I.i_hi(w)) ++ "] certified", "min-wall not certified (a face kind the certified wall search does not take)") ++
    " limit=" ++ fs(lim) ++ " status=" ++ st_s(ws) ++ "\n" ++
    "make node " ++ U64.show(nd) ++ ": best orientation up=" ++ bn ++ " support-area=" ++ fs(a) ++ Bool.pick(String, F64.is_lt(a, 1.0e-9f64), " (no support)", " (needs support)") ++ "\n" ++
    "verdict " ++ Bool.pick(String, Nat.is_eq(ws, 0n), "makeable", Bool.pick(String, Nat.is_eq(ws, 2n), "not-makeable", "not-analyzed")) ++
    " status=estimated (overhang area from a closed mesh at chord 0.05 mm; the wall is certified)"

def pr_fin(+o: Ob, +w: I.I, +wok: Bool, +nd: U64, +pp: Pp) -> String:
  Ob{+s, +a, +bn} = o
  Pp{+nm, +lim} = pp
  pr_f2(s, a, bn, Bool.pick(Nat, wok, wl_st(I.i_lo(w), I.i_hi(w), lim), 1n), w, wok, nd, nm, lim)

def pr_iv(ok: Bool, +fs0: List<&2, SO.Fd>) -> I.I:
  match ok:
    case True{}: QL.wall_iv(fs0, QL.diag(SO.bbox(fs0, [])))
    case False{}: I.I{0.0f64, 1.0e300f64}

def pr_w2(+x: Pc, +fs0: List<&2, SO.Fd>, +ok: Bool, +nd: U64, +pp: Pp) -> String:
  pr_fin(or_go(or_dirs(), ["+z", "-z", "+x", "-x", "+y", "-y"], x, Ob{"", 1.0e300f64, ""}), pr_iv(ok, fs0), ok, nd, pp)

def pr_w(+x: Pc, +fs0: List<&2, SO.Fd>, +nfa: Nat, +nd: U64, +pp: Pp) -> String:
  pr_w2(x, fs0, Bool.and(QA.fd_allok(fs0), Nat.is_eq(nfa, List.length(&2, SO.Fd, fs0))), nd, pp)

def fi0() -> Fi:
  Fi{0n, dr(0.0f64, 0.0f64, 1.0f64), pz(), 0.0f64, False{}, False{}, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def fis_go(fs: List<&2, Ty.Face>, +i: Nat, +fv: B.Tb<&2, List<&2, Nat>>, +wt: B.Tb<&2, V.Point>, +pl: M.Pl, +hs: List<&2, DW.Hr>) -> List<&2, Fi>:
  match fs:
    case []: []
    case +f <> t: fi_of(f, B.tb_get(List<&2, Nat>, fv, U32.from_nat(i)), wt, pl, hs) <> fis_go(t, Nat.add(i, 1n), fv, wt, pl, hs)

def fxt_go(c: Nat, +i: Nat, +fv: B.Tb<&2, List<&2, Nat>>, +ss: List<&2, Su>, +wt: B.Tb<&2, V.Point>, +ft: B.Tb<&2, Fi>) -> List<&2, List<&2, Fx>>:
  match c:
    case 0n: []
    case 1n+(+k): fxs_go(ss, B.tb_get(List<&2, Nat>, fv, U32.from_nat(i)), wt, B.tb_get(Fi, ft, U32.from_nat(i))) <> fxt_go(k, Nat.add(i, 1n), fv, ss, wt, ft)

def nms_go(xs: List<&2, BD.Fn>) -> List<&2, String>:
  match xs:
    case []: []
    case +x <> t: BD.fn_name(x) <> nms_go(t)

type Cn is Data:
  Cn{ s: String, np: Nat, na: Nat, nf: Nat }

def cn_add(+r: Rl, +nm: String, +acc: Cn) -> Cn:
  Rl{+st, +m} = r
  Cn{+s, +np, +na, +nf} = acc
  Cn{s ++ "make face " ++ nm ++ " " ++ m ++ " status=" ++ st_s(st) ++ "\n", Bool.pick(Nat, Nat.is_eq(st, 0n), Nat.add(np, 1n), np),
    Bool.pick(Nat, Nat.is_eq(st, 1n), Nat.add(na, 1n), na), Bool.pick(Nat, Nat.is_eq(st, 2n), Nat.add(nf, 1n), nf)}

def same_cyl(+g: Fi, +f: Fi) -> Bool:
  Bool.and(Bool.and(Nat.is_eq(fi_k(g), 2n), fi_cc(g)), Bool.and(F64.is_lt(F64.abs(F64.sub(fi_r(g), fi_r(f))), 1.0e-9f64),
    Bool.and(F64.is_lt(KS.dlen(KS.cross(fi_n(g), fi_n(f))), 1.0e-9f64), F64.is_lt(KS.dlen(KS.cross(KS.psub(fi_o(g), fi_o(f)), fi_n(f))), 1.0e-6f64))))

def nb_angs(xs: List<&2, Nat>, +c: Ck, +f: Fi, +acc: List<&2, F64>) -> List<&2, F64>:
  match xs:
    case []: acc
    case +j <> t: nb_angs(t, c, f, Bool.pick(List<&2, F64>, same_cyl(ck_fi(c, j), f), ang_go(ck_fv(c, j), ck_wt(c), fi_o(f), KS.perp_of(fi_n(f)), KS.cross(fi_n(f), KS.perp_of(fi_n(f))), acc), acc))

def fi_wf(+f: Fi, +full: Bool) -> Fi:
  Fi{+k, +n, +o, +r, +cc, fl, +rmax, +td, +tl, +pt} = f
  Fi{k, n, o, r, cc, full, rmax, td, tl, pt}

def fi_fix2(+f: Fi, +c: Ck, +i: Nat, +nb: List<&2, Nat>) -> Fi:
  fi_wf(f, full_of(so_f(B.msort(~F64, ~f_lt, nb_angs(nb, c, f, ang_go(ck_fv(c, i), ck_wt(c), fi_o(f), KS.perp_of(fi_n(f)), KS.cross(fi_n(f), KS.perp_of(fi_n(f))), []))))))

def fi_fix(go: Bool, +f: Fi, +c: Ck, +i: Nat, +nb: List<&2, Nat>) -> Fi:
  match go:
    case False{}: f
    case True{}: fi_fix2(f, c, i, nb)

def fi_at(+c: Ck, +i: Nat, +nb: List<&2, Nat>) -> Fi:
  fi_fix(Bool.and(Bool.and(Nat.is_eq(fi_k(ck_fi(c, i)), 2n), fi_cc(ck_fi(c, i))), Bool.not(fi_full(ck_fi(c, i)))), ck_fi(c, i), c, i, nb)

def face_rl(+c: Ck, +i: Nat, +dmax: F64, +nb: List<&2, Nat>) -> Rl:
  best_go(ck_fx(c, i), swp(ck_fx(c, i)), ck_ss(c), fi_at(c, i, nb), dmax, Rl{3n, ""})

def fa_go(n: Nat, +i: Nat, +c: Ck, +adj: B.Tb<&2, List<&2, Nat>>, +ft: B.Tb<&2, Fi>, +acc: Cn) -> Cn:
  match n:
    case 0n: acc
    case 1n+(+k): fa_go(k, Nat.add(i, 1n), c, adj, ft, cn_add(face_rl(c, i, dm_go(B.tb_get(List<&2, Nat>, adj, U32.from_nat(i)), c, ck_fi(c, i), 1.0e300f64), B.tb_get(List<&2, Nat>, adj, U32.from_nat(i))), ck_nm(c, i), acc))

def str_cat(xs: List<&2, String>) -> String:
  match xs:
    case []: ""
    case +x <> t: x ++ str_cat(t)

def verdict(+nf: Nat, +na: Nat) -> String:
  Bool.pick(String, Nat.is_lt(0n, nf), "not-makeable", Bool.pick(String, Nat.is_lt(0n, na), "not-analyzed", "makeable"))

def mill_fin(+r: Cn, +cs: List<&2, String>, +nd: U64, +nfa: Nat) -> String:
  Cn{+s, +np, +na, +nf} = r
  "make node " ++ U64.show(nd) ++ " process=mill (3-axis, setups +z -z +x -x +y -y; tools held: ISO 235 jobber drills 1-16, DIN 6527 L end mills 1-20, DIN 335 C 90 countersinks, DIN 371/376 taps; docs/std.md)\n" ++
    s ++ str_cat(cs) ++
    "make node " ++ U64.show(nd) ++ ": " ++ Nat.show(nfa) ++ " faces, " ++ Nat.show(np) ++ " pass, " ++ Nat.show(nf) ++ " fail, " ++ Nat.show(na) ++ " not-analyzed; " ++
    Nat.show(List.length(&2, String, cs)) ++ " sharp inside corners\n" ++
    "verdict " ++ verdict(Nat.add(nf, List.length(&2, String, cs)), na) ++ " status=estimated (tool access from a closed mesh at chord 0.05 mm; sizes and depths against the held tool tables)"

def mill_c(+c: Ck, +ps: List<&2, Pr>, +ft: B.Tb<&2, Fi>, +nfa: Nat, +pl: M.Pl, +nd: U64) -> String:
  mill_fin(fa_go(nfa, 0n, c, DW.fj_of(pr_keys(ps, []), nfa), ft, Cn{"", 0n, 0n, 0n}), cn_go(ps, c, pl, []), nd, nfa)

def ck_mk(+ft: B.Tb<&2, Fi>, +fv: B.Tb<&2, List<&2, Nat>>, +ss: List<&2, Su>, +wt: B.Tb<&2, V.Point>, +b: M.Body, +nfa: Nat) -> Ck:
  Ck{ft, fv, B.tb_of(List<&2, Fx>, fxt_go(nfa, 0n, fv, ss, wt, ft), []), ss, wt, B.tb_of(Ty.Edge, Ty.brep_es(M.bd_brep(b)), Ty.ed_dflt()),
    B.tb_of(V.Point, TS.vx_pts(Ty.brep_vs(M.bd_brep(b))), pz()), B.tb_of(String, nms_go(M.bd_fns(b)), "")}

def mill_t(+ft: B.Tb<&2, Fi>, +fv: B.Tb<&2, List<&2, Nat>>, +ss: List<&2, Su>, +wt: B.Tb<&2, V.Point>, +b: M.Body, +nfa: Nat, +nd: U64) -> String:
  mill_c(ck_mk(ft, fv, ss, wt, b, nfa), prs_of(M.bd_brep(b)), ft, nfa, M.bd_pl(b), nd)

type Ax is Data:
  Ax{ o: V.Point, a: V.Dir, r: F64, ok: Bool }

def ax_pick(+f: Fi, +acc: Ax) -> Ax:
  Ax{+o, +a, +r, +ok} = acc
  Bool.pick(Ax, Bool.and(Bool.or(Nat.is_eq(fi_k(f), 2n), Bool.or(Nat.is_eq(fi_k(f), 5n), Nat.is_eq(fi_k(f), 7n))), F64.is_lt(r, fi_r(f))), Ax{fi_o(f), fi_n(f), fi_r(f), True{}}, Ax{o, a, r, ok})

def ax_go(n: Nat, +i: Nat, +ft: B.Tb<&2, Fi>, +acc: Ax) -> Ax:
  match n:
    case 0n: acc
    case 1n+(+k): ax_go(k, Nat.add(i, 1n), ft, ax_pick(B.tb_get(Fi, ft, U32.from_nat(i)), acc))

def ax_a(+x: Ax) -> V.Dir:
  Ax{o, +a, r, ok} = x
  a

def ax_ok(+x: Ax) -> Bool:
  Ax{o, a, r, +ok} = x
  ok

def coax(+f: Fi, +x: Ax) -> Bool:
  Ax{+o, +a, r, ok} = x
  Bool.pick(Bool, Nat.is_eq(fi_k(f), 1n), F64.is_lt(KS.dlen(KS.cross(fi_n(f), a)), 1.0e-6f64),
    Bool.and(Bool.or(Nat.is_eq(fi_k(f), 4n), F64.is_lt(KS.dlen(KS.cross(fi_n(f), a)), 1.0e-6f64)), F64.is_lt(KS.dlen(KS.cross(KS.psub(fi_o(f), o), a)), 1.0e-6f64)))

def ti_go(rs: List<&2, List<&2, F64>>, +p: F64) -> Bool:
  match rs:
    case []: False{}
    case +r <> t: Bool.or(F64.is_lt(F64.abs(F64.sub(SD.fv_go(r, 0n), p)), 1.0e-6f64), ti_go(t, p))

def drill_l(+r: List<&2, F64>, +d: F64, +depth: F64) -> Rl:
  Bool.pick(Rl, F64.is_le(depth, F64.add(SD.fv_go(r, 2n), 1.0e-9f64)), Rl{0n, "cylinder bore d=" ++ fs(d) ++ " depth=" ++ fs(depth) ++ " drilled on the turning axis tool=\"drill " ++ fs(d) ++ " jobber l2=" ++ fs(SD.fv_go(r, 2n)) ++ " (ISO 235)\""},
    Rl{1n, "cylinder bore d=" ++ fs(d) ++ " depth=" ++ fs(depth) ++ " on the turning axis why=deeper than the jobber drill's flute (l2=" ++ fs(SD.fv_go(r, 2n)) ++ "); boring bars are not held"})

def la_bore(+d: F64, +depth: F64) -> Rl:
  Bool.pick(Rl, Bool.and(dr_ser(d), SD.row_ok(SD.row("drill", d))), drill_l(SD.row("drill", d), d, depth),
    Rl{1n, "cylinder bore d=" ++ fs(d) ++ " depth=" ++ fs(depth) ++ " on the turning axis why=not a held drill size; boring bars are not held (Sandvik: bar overhang up to 4xBD steel, 6xBD carbide, 14xBD dampened; the bar that fits this bore is not held)"})

def la_thr(+f: Fi, +thr: Bool, +depth: F64) -> Rl:
  Bool.pick(Rl, fi_cc(f), tap_rl(SD.row("tap", fi_td(f)), thr, fi_td(f), fi_tl(f), "turning-axis"),
    Bool.pick(Rl, ti_go(SD.tab("thread_insert"), fi_pt(f)), Rl{0n, "helicoid external-thread d=" ++ fs(fi_td(f)) ++ " pitch=" ++ fs(fi_pt(f)) ++ " single-point threading tool=\"16ER " ++ fs(fi_pt(f)) ++ " ISO insert\""},
      Rl{1n, "helicoid external-thread d=" ++ fs(fi_td(f)) ++ " pitch=" ++ fs(fi_pt(f)) ++ " why=no held 16ER full-profile insert for this pitch (held 0.7 to 3.0)"}))

def la_co(+f: Fi) -> Rl:
  Bool.pick(Rl, fi_cc(f), co_cc(fi_r(f), F64.mul(2.0f64, fi_rmax(f)), "turning-axis"), Rl{0n, "cone outside turned tool=\"turning insert\""})

def gi_go(rs: List<&2, List<&2, F64>>, +w: F64, +acc: F64) -> F64:
  match rs:
    case []: acc
    case +r <> t: gi_go(t, w, Bool.pick(F64, F64.is_le(SD.fv_go(r, 0n), F64.add(w, 1.0e-9f64)), SD.fv_go(r, 0n), acc))

def gr_r2(+m: F64, +w: F64) -> Rl:
  Bool.pick(Rl, F64.is_lt(0.0f64, m), Rl{0n, "cylinder groove width=" ++ fs(w) ++ " tool=\"grooving insert m=" ++ fs(m) ++ " (DIN 471 partial profile" ++ Bool.pick(String, F64.is_lt(F64.add(m, 1.0e-9f64), w), ", several plunges", "") ++ ")\""},
    Rl{1n, "cylinder groove width=" ++ fs(w) ++ " why=narrower than the narrowest held grooving insert (0.5)"})

def gr_rl(+w: F64) -> Rl:
  gr_r2(gi_go(SD.tab("groove_insert"), w, 0.0f64), w)

def la_cyo(+f: Fi, +gv: Bool, +w: F64) -> Rl:
  Bool.pick(Rl, gv, gr_rl(w), Rl{0n, "cylinder outside d=" ++ fs(F64.mul(2.0f64, fi_r(f))) ++ " turned tool=\"turning insert\""})

def la_rule(+f: Fi, +depth: F64, +thr: Bool, +gv: Bool, +w: F64) -> Rl:
  Bool.pick(Rl, Nat.is_eq(fi_k(f), 1n), Rl{0n, "plane faced on the turning axis tool=\"turning insert\""},
    Bool.pick(Rl, Nat.is_eq(fi_k(f), 2n), Bool.pick(Rl, fi_cc(f), la_bore(F64.mul(2.0f64, fi_r(f)), depth),
        la_cyo(f, gv, w)),
      Bool.pick(Rl, Nat.is_eq(fi_k(f), 3n), la_co(f),
        Bool.pick(Rl, Nat.is_eq(fi_k(f), 7n), la_thr(f, thr, depth),
          Bool.pick(Rl, fi_cc(f), Rl{1n, "surface inside on the turning axis why=internal profile needs a boring bar (not held)"},
            Rl{0n, "surface outside turned tool=\"turning insert\""})))))

def la_sec(+r: Rl) -> Rl:
  Rl{+st, +s} = r
  Rl{st, "secondary (live tooling) " ++ s}

def gw_two(+pl: Bool, +pos: F64, +sn: F64, +rg: V.Vec2, +acc: V.Vec2) -> V.Vec2:
  V.V2{Bool.pick(F64, Bool.and(pl, Bool.and(F64.is_lt(F64.abs(F64.sub(pos, V.v2_x(rg))), 1.0e-6f64), F64.is_lt(0.5f64, sn))), 1.0f64, V.v2_x(acc)),
    Bool.pick(F64, Bool.and(pl, Bool.and(F64.is_lt(F64.abs(F64.sub(pos, V.v2_y(rg))), 1.0e-6f64), F64.is_lt(sn, F64.neg(0.5f64)))), 1.0f64, V.v2_y(acc))}

def gw_one(+f: Fi, +a: V.Dir, +rg: V.Vec2, +acc: V.Vec2) -> V.Vec2:
  gw_two(Bool.and(Nat.is_eq(fi_k(f), 1n), F64.is_lt(KS.dlen(KS.cross(fi_n(f), a)), 1.0e-6f64)), DW.dp(fi_o(f), a), KS.dot(fi_n(f), a), rg, acc)

def gw_go(xs: List<&2, Nat>, +c: Ck, +a: V.Dir, +rg: V.Vec2, +acc: V.Vec2) -> V.Vec2:
  match xs:
    case []: acc
    case +g <> t: gw_go(t, c, a, rg, gw_one(ck_fi(c, g), a, rg, acc))

def la_dep(+f: Fi, +rg: V.Vec2, +top: F64, +bot: F64, +gw: V.Vec2) -> Rl:
  la_rule(f, F64.min(F64.sub(top, V.v2_x(rg)), F64.sub(V.v2_y(rg), bot)),
    Bool.and(F64.is_lt(F64.abs(F64.sub(V.v2_x(rg), bot)), 1.0e-6f64), F64.is_lt(F64.abs(F64.sub(V.v2_y(rg), top)), 1.0e-6f64)),
    Bool.and(Bool.and(Nat.is_eq(fi_k(f), 2n), Bool.not(fi_cc(f))), Bool.and(F64.is_lt(0.5f64, V.v2_x(gw)), F64.is_lt(0.5f64, V.v2_y(gw)))), F64.sub(V.v2_y(rg), V.v2_x(rg)))

def la_dp2(+f: Fi, +rg: V.Vec2, +top: F64, +bot: F64, +c: Ck, +a: V.Dir, +nb: List<&2, Nat>) -> Rl:
  la_dep(f, rg, top, bot, gw_go(nb, c, a, rg, V.V2{0.0f64, 0.0f64}))

def la_one(co: Bool, +c: Ck, +i: Nat, +dmax: F64, +x: Ax, +top: F64, +bot: F64, +wt: B.Tb<&2, V.Point>, +nb: List<&2, Nat>) -> Rl:
  match co:
    case False{}: la_sec(face_rl(c, i, dmax, nb))
    case True{}: la_dp2(ck_fi(c, i), fa_rg(ck_fv(c, i), wt, ax_a(x), rg0()), top, bot, c, ax_a(x), nb)

def la_go(n: Nat, +i: Nat, +c: Ck, +adj: B.Tb<&2, List<&2, Nat>>, +ft: B.Tb<&2, Fi>, +x: Ax, +top: F64, +bot: F64, +wt: B.Tb<&2, V.Point>, +acc: Cn) -> Cn:
  match n:
    case 0n: acc
    case 1n+(+k):
      la_go(k, Nat.add(i, 1n), c, adj, ft, x, top, bot, wt, cn_add(la_one(coax(ck_fi(c, i), x), c, i, dm_go(B.tb_get(List<&2, Nat>, adj, U32.from_nat(i)), c, ck_fi(c, i), 1.0e300f64), x, top, bot, wt, B.tb_get(List<&2, Nat>, adj, U32.from_nat(i))), ck_nm(c, i), acc))

def la_fin(+r: Cn, +x: Ax, +nd: U64, +nfa: Nat) -> String:
  Cn{+s, +np, +na, +nf} = r
  Ax{+o, +a, rr, ok} = x
  "make node " ++ U64.show(nd) ++ " process=lathe (turning axis through " ++ pt_s(o) ++ " along " ++ dr_s(a) ++ ", from the largest cylinder; faces off the axis are judged as live-tooling mill work; tools held: ISO 235 jobber drills, DIN 335 C countersinks, DIN 371/376 taps, 16ER ISO threading inserts 0.7-3.0; docs/std.md)\n" ++
    s ++ "make node " ++ U64.show(nd) ++ ": " ++ Nat.show(nfa) ++ " faces, " ++ Nat.show(np) ++ " pass, " ++ Nat.show(nf) ++ " fail, " ++ Nat.show(na) ++ " not-analyzed\n" ++
    "verdict " ++ verdict(nf, na) ++ " status=estimated (tool access from a closed mesh at chord 0.05 mm; sizes and depths against the held tool tables)"

def la_c(+c: Ck, +ps: List<&2, Pr>, +ft: B.Tb<&2, Fi>, +nfa: Nat, +x: Ax, +rg: V.Vec2, +wt: B.Tb<&2, V.Point>, +nd: U64) -> String:
  la_fin(la_go(nfa, 0n, c, DW.fj_of(pr_keys(ps, []), nfa), ft, x, V.v2_y(rg), V.v2_x(rg), wt, Cn{"", 0n, 0n, 0n}), x, nd, nfa)

def rg_ps(ps: List<&2, V.Point>, +a: V.Dir, +m: V.Vec2) -> V.Vec2:
  match ps:
    case []: m
    case +p <> t: rg_ps(t, a, DW.rg_add(DW.dp(p, a), m))

def la_ax(ok: Bool, +c: Ck, +ps: List<&2, Pr>, +ft: B.Tb<&2, Fi>, +nfa: Nat, +x: Ax, +wp: List<&2, V.Point>, +wt: B.Tb<&2, V.Point>, +nd: U64) -> String:
  match ok:
    case False{}: "refused make-no-turning-axis: the part has no cylinder face to turn about | make lathe | fix: check it as mill, fdm or sla"
    case True{}: la_c(c, ps, ft, nfa, x, rg_ps(wp, ax_a(x), rg0()), wt, nd)

def la_x2(+c: Ck, +ps: List<&2, Pr>, +ft: B.Tb<&2, Fi>, +nfa: Nat, +x: Ax, +wp: List<&2, V.Point>, +wt: B.Tb<&2, V.Point>, +nd: U64) -> String:
  la_ax(ax_ok(x), c, ps, ft, nfa, x, wp, wt, nd)

def lathe_t(+ft: B.Tb<&2, Fi>, +fv: B.Tb<&2, List<&2, Nat>>, +ss: List<&2, Su>, +wt: B.Tb<&2, V.Point>, +b: M.Body, +nfa: Nat, +nd: U64, +wp: List<&2, V.Point>) -> String:
  la_x2(ck_mk(ft, fv, ss, wt, b, nfa), prs_of(M.bd_brep(b)), ft, nfa, ax_go(nfa, 0n, ft, Ax{pz(), dr(0.0f64, 0.0f64, 1.0f64), 0.0f64, False{}}), wp, wt, nd)


def mk_l(lathe: Bool, +ft: B.Tb<&2, Fi>, +fv: B.Tb<&2, List<&2, Nat>>, +c: Mc, +m: TS.Mp, +b: M.Body, +nd: U64, +pr: String, +nfa: Nat) -> String:
  match lathe:
    case True{}: lathe_t(ft, fv, sus(c), mc_wt(c), b, nfa, nd, mc_wp(c))
    case False{}:
      pr_w(Pc{c, DW.fid_go(TS.mp_ns(m), 0n, []), ft, fv, nfa, 5.0f64}, SO.fds_of(M.bd_brep(b)), nfa, nd, Pp{pr, Bool.pick(F64, String.eq(pr, "sla"), 0.5f64, 0.8f64)})

def mk_d(mill: Bool, +ft: B.Tb<&2, Fi>, +fv: B.Tb<&2, List<&2, Nat>>, +c: Mc, +m: TS.Mp, +b: M.Body, +nd: U64, +pr: String, +nfa: Nat) -> String:
  match mill:
    case True{}: mill_t(ft, fv, sus(c), mc_wt(c), b, nfa, nd)
    case False{}: mk_l(String.eq(pr, "lathe"), ft, fv, c, m, b, nd, pr, nfa)

def mill_f(+fv: B.Tb<&2, List<&2, Nat>>, +c: Mc, +m: TS.Mp, +b: M.Body, +nd: U64, +pr: String) -> String:
  mk_d(String.eq(pr, "mill"), B.tb_of(Fi, fis_go(Ty.brep_fas(M.bd_brep(b)), 0n, fv, mc_wt(c), M.bd_pl(b),
      DW.hr_groups(DW.so_hr(B.msort(~DW.Hr, ~DW.hr_cmp, DW.hr_walk(Ty.brep_fas(M.bd_brep(b)), TS.mp_ns(m), 0n, DW.Hz{mc_tt(c), mc_wt(c), M.bd_pl(b)}, []))))), fi0()),
    fv, c, m, b, nd, pr, List.length(&2, Ty.Face, Ty.brep_fas(M.bd_brep(b))))

def mill_w(+wp: List<&2, V.Point>, +wt: B.Tb<&2, V.Point>, +tt: B.Tb<&2, TS.Tri>, +m: TS.Mp, +b: M.Body, +nd: U64, +pr: String) -> String:
  mill_f(fv_tab(TS.mp_ts(m), DW.fid_go(TS.mp_ns(m), 0n, []), List.length(&2, Ty.Face, Ty.brep_fas(M.bd_brep(b)))),
    Mc{wp, wt, TS.mp_ts(m), tt, B.tb_of(Bool, DW.fhx_go(Ty.brep_fas(M.bd_brep(b)), TS.mp_ns(m), []), False{}),
      F64.is_lt(0.0f64, DW.vol_go(TS.mp_ts(m), wt, DW.pt2(wt, 0n), 0.0f64)), 0.100001f64}, m, b, nd, pr)

def mill_p(+wp: List<&2, V.Point>, +m: TS.Mp, +b: M.Body, +nd: U64, +pr: String) -> String:
  mill_w(wp, B.tb_of(V.Point, wp, pz()), B.tb_of(TS.Tri, TS.mp_ts(m), TS.Tri{0n, 0n, 0n}), m, b, nd, pr)

def mill_m(ok: Bool, +m: TS.Mp, +b: M.Body, +nd: U64, +pr: String) -> String:
  match ok:
    case False{}: "refused make-mesh-not-closed: the part's mesh did not close, so tool access cannot be judged | make | fix: report the design"
    case True{}: mill_p(DW.wpts(TS.mp_ps(m), M.bd_pl(b)), m, b, nd, pr)

def mill_mp(+m: TS.Mp, +b: M.Body, +nd: U64, +pr: String) -> String:
  mill_m(TS.mp_ok(m), m, b, nd, pr)

def make_body(+b: M.Body, +nd: U64, +pr: String) -> String:
  mill_mp(TS.mesh_of(b, M10.q_mk(0.05f64, 0.05f64, 10000000n, 0u64)), b, nd, pr)
