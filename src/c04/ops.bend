import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c02/types.bend as P
import ../c02/ops.bend as PO
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../base/par.bend as B
import ./types.bend as Ty

type HK is Data:
  HK{ i: Nat, g: U64 }

type UK is Data:
  UK{ k: HK, f: Bool }

type UC is Data:
  UC{ n: Nat, t: Bool, f: Bool, rest: List<&2, UK> }

type PV is Data:
  PV{ k: HK, l: Nat, j: Nat, p: Ty.HCoedge }

type ET is Data:
  ET{ k: HK, c: Nat, h: Ty.HCoedge }

type T2 is Data:
  T2{ k: HK, a: Ty.HCoedge, b: Ty.HCoedge, two: Bool }

type Hmap is Data:
  Hmap{ pk: B.Tb<&2, HK>, pp: B.Tb<&2, Ty.HCoedge>, tk: B.Tb<&2, HK>, tv: B.Tb<&2, T2> }

type GC is Data:
  GC{ m: Hmap, x: Ty.Ix, s: B.Tb<&2, HK> }

type JM is Data:
  JM{ j: U32, m: U32 }

type LN is Data:
  LN{ lab: U32, n: Nat }

type Orb is Data:
  Orb{ s: B.Tb<&2, HK>, nx: B.Tb<&2, U32>, cyc: B.Tb<&2, Bool>, lab: B.Tb<&2, U32>, ndc: B.Tb<&2, Nat>, nd: B.Tb<&2, Bool> }

type SV is Data:
  SV{ k: HK, c: Nat, h: Ty.HCoedge }

type SS is Data:
  SS{ hs: List<&2, Ty.HCoedge>, rest: List<&2, SV> }

type OC is Data:
  OC{ o: Orb, x: Ty.Ix }

type CL is Data:
  CL{ k: HK, l: Nat }

type CN is Data:
  CN{ n: Nat, rest: List<&2, CL> }

type EP is Data:
  EP{ k: HK, p: U32 }

type SG is Data:
  SG{ e: Ty.Edge, a: V.Point, b: V.Point, safe: Bool }

type SP2 is Data:
  SP2{ safe: List<&2, SG>, risky: List<&2, SG> }

type OCt is Data:
  OCt{ bad: Bool, cert: Nat, skip: Nat }

type FL is Data:
  FL{ k: HK, f: Nat, h: Ty.HFace }

type RC is Data:
  RC{ x: Ty.Ix, ck: B.Tb<&2, HK>, cl: B.Tb<&2, Nat>, lg: B.Tb<&2, Ty.Loop>, fk: B.Tb<&2, HK>, fh: B.Tb<&2, Ty.HFace>, cls: B.Tb<&2, Nat> }

def pt_eq(+a: V.Point, +b: V.Point) -> Bool:
  Bool.and(F64.is_eq(V.pt_x(a), V.pt_x(b)),
    Bool.and(F64.is_eq(V.pt_y(a), V.pt_y(b)),
      F64.is_eq(V.pt_z(a), V.pt_z(b))))

def v2_eq(+a: V.Vec2, +b: V.Vec2) -> Bool:
  Bool.and(F64.is_eq(V.v2_x(a), V.v2_x(b)),
    F64.is_eq(V.v2_y(a), V.v2_y(b)))

def trim_start(t: G.GVal) -> V.Vec2:
  match t:
    case G.GV_ts{w}:
      G.Ts{a, b} = w
      a
    case G.GV_tb{w}:
      G.Tb{b0, b1, b2, b3} = w
      b0
    case _: V.V2{0.0f64, 0.0f64}

def trim_end(t: G.GVal) -> V.Vec2:
  match t:
    case G.GV_ts{w}:
      G.Ts{a, b} = w
      b
    case G.GV_tb{w}:
      G.Tb{b0, b1, b2, b3} = w
      b3
    case _: V.V2{0.0f64, 0.0f64}

def trim_fin(t: G.GVal) -> Bool:
  match t:
    case G.GV_ts{w}: G.ts_fin(w)
    case G.GV_tb{w}: G.tb_fin(w)
    case _: False{}

def trim_o_start(t: G.GVal, fwd: Bool) -> V.Vec2:
  match fwd:
    case True{}: trim_start(t)
    case False{}: trim_end(t)

def trim_o_end(t: G.GVal, fwd: Bool) -> V.Vec2:
  match fwd:
    case True{}: trim_end(t)
    case False{}: trim_start(t)

def curve_fin_ok(c: G.GVal, fuel: Nat) -> Bool:
  match c:
    case G.GV_ln{w}: G.ln_valid(w)
    case G.GV_cc{w}: G.cc_valid(w)
    case G.GV_bz{w}: G.bz_fin(w)
    case G.GV_rq{w}: G.rq_valid(w)
    case G.GV_nb{w}: G.gres_ok(GO.nurbs_checked(w, fuel))
    case _: False{}

def surf_fin_ok(s: G.GVal) -> Bool:
  match s:
    case G.GV_pl{w}: G.gres_ok(GO.plane_checked(w))
    case G.GV_cy{w}: G.cy_valid(w)
    case G.GV_co{w}: G.co_valid(w)
    case G.GV_sp{w}: G.sp_valid(w)
    case G.GV_to{w}: G.to_valid(w)
    case G.GV_bp{w}: G.bp_fin(w)
    case _: False{}

def curve_at(c: G.GVal, t: F64, fuel: Nat) -> G.GRes:
  match c:
    case G.GV_ln{w}: GO.line_eval(w, t)
    case G.GV_cc{w}: GO.circ_eval(w, t)
    case G.GV_bz{w}: GO.bez3_eval(w, t)
    case G.GV_rq{w}: GO.rqb_eval(w, t)
    case G.GV_nb{w}: GO.nurbs_eval(w, t, fuel)
    case _: G.gerr(T.F_invalid{})

def edge_ends_on_curve(kind: Ty.EdgeKind, p0: V.Point, p1: V.Point,
    +fuel: Nat) -> Bool:
  match kind:
    case Ty.EK_curve{+curve, +dom}:
      +lo = G.dom_lo(dom)
      +hi = G.dom_hi(dom)
      +r0 = curve_at(curve, lo, fuel)
      +r1 = curve_at(curve, hi, fuel)
      Bool.and(G.gres_ok(r0),
        Bool.and(G.gres_ok(r1),
          Bool.and(pt_eq(G.gres_p(r0), p0), pt_eq(G.gres_p(r1), p1))))
    case Ty.EK_degenerate{}: True{}

def surf_at(s: G.GVal, u: F64, v: F64) -> G.GRes:
  match s:
    case G.GV_pl{w}: GO.plane_eval(w, u, v)
    case G.GV_bp{w}: GO.bezp_eval(w, u, v)
    case _: G.gerr(T.F_unsupported{})

def use_rule_ok(+count: Nat, saw_t: Bool, saw_f: Bool,
    p: Ty.Profile) -> Bool:
  match p:
    case Ty.P_manifold_solid{}:
      Bool.and(Nat.is_eq(count, 2n),
        Bool.and(saw_t, saw_f))
    case Ty.P_open_shell{}:
      Bool.or(Nat.is_eq(count, 1n),
        Bool.and(Nat.is_eq(count, 2n),
          Bool.and(saw_t, saw_f)))

def o_v_start(+e: Ty.Edge, fwd: Bool) -> Ty.HVertex:
  match fwd:
    case True{}: Ty.ed_v0(e)
    case False{}: Ty.ed_v1(e)

def o_v_end(+e: Ty.Edge, fwd: Bool) -> Ty.HVertex:
  match fwd:
    case True{}: Ty.ed_v1(e)
    case False{}: Ty.ed_v0(e)

def newell_add(+n: V.Dir, +p: V.Point, +q: V.Point) -> V.Dir:
  +nx = F64.add(V.dr_x(n), F64.mul(F64.sub(V.pt_y(p),
    V.pt_y(q)), F64.add(V.pt_z(p), V.pt_z(q))))
  +ny = F64.add(V.dr_y(n), F64.mul(F64.sub(V.pt_z(p),
    V.pt_z(q)), F64.add(V.pt_x(p), V.pt_x(q))))
  +nz = F64.add(V.dr_z(n), F64.mul(F64.sub(V.pt_x(p),
    V.pt_x(q)), F64.add(V.pt_y(p), V.pt_y(q))))
  V.Dr{nx, ny, nz}

def dr_is_zero(+d: V.Dir) -> Bool:
  Bool.and(F64.is_eq(V.dr_x(d), 0.0f64),
    Bool.and(F64.is_eq(V.dr_y(d), 0.0f64),
      F64.is_eq(V.dr_z(d), 0.0f64)))

def dr_neg(+d: V.Dir) -> V.Dir:
  V.Dr{F64.neg(V.dr_x(d)), F64.neg(V.dr_y(d)),
    F64.neg(V.dr_z(d))}

def surf_is_plane(+s: G.GVal) -> Bool:
  match s:
    case G.GV_pl{w}: True{}
    case _: False{}

def gval_is_line(+c: G.GVal) -> Bool:
  match c:
    case G.GV_ln{w}: True{}
    case _: False{}

def ekind_is_line(+k: Ty.EdgeKind) -> Bool:
  match k:
    case Ty.EK_curve{curve, dom}: gval_is_line(curve)
    case Ty.EK_degenerate{}: False{}

def edge_is_line(+e: Ty.Edge) -> Bool:
  Ty.Ed{gen, v0, v1, kind} = e
  ekind_is_line(kind)

def bezp_normal_at(+w: G.BezP, +u: F64, +v: F64) -> G.GRes:
  +du = GO.bezp_du(w, u, v)
  +dv = GO.bezp_dv(w, u, v)
  +ok = Bool.and(G.gres_ok(du), G.gres_ok(dv))
  +n = GO.dd_cross_raw(G.gres_d(du), G.gres_d(dv))
  GO.gate_d(n, Bool.and(ok, V.dr_fin(n)), T.F_uncertain{})

def plane_normal_of(+surf: G.GVal) -> G.GRes:
  match surf:
    case G.GV_pl{w}: GO.plane_normal(w)
    case _: G.gerr(T.F_unsupported{})

def cnt_pack(+count: Nat, +done: Bool) -> Nat:
  match done:
    case False{}: 0n
    case True{}: Nat.add(count, 1n)

def cnt_done(+c: Nat) -> Bool:
  Bool.not(Nat.is_eq(c, 0n))

def cnt_count(+c: Nat) -> Nat:
  match c:
    case 0n: 0n
    case 1n+p: p

def gval_is_ln(c: G.GVal) -> Bool:
  match c:
    case G.GV_ln{w}: True{}
    case _: False{}

def ed_straight(+e: Ty.Edge) -> Bool:
  +k = Ty.ed_kind(e)
  +c = Ty.ekind_curve(k)
  Bool.pick(Bool, Ty.ekind_is_curve(k), gval_is_ln(c), False{})

def hes_share_end(+a: Ty.Edge, +b: Ty.Edge) -> Bool:
  +a0 = Ty.ed_v0(a)
  +a1 = Ty.ed_v1(a)
  +b0 = Ty.ed_v0(b)
  +b1 = Ty.ed_v1(b)
  +m0 = Ty.hv_eq(a0, b0)
  +m1 = Ty.hv_eq(a0, b1)
  +m2 = Ty.hv_eq(a1, b0)
  +m3 = Ty.hv_eq(a1, b1)
  Bool.or(m0, Bool.or(m1, Bool.or(m2, m3)))

def xrel_is_proper(x: P.Xrel) -> Bool:
  match x:
    case P.X_proper{}: True{}
    case _: False{}

def segx_proper2(+a: V.Vec2, +b: V.Vec2, +c: V.Vec2,
    +d: V.Vec2) -> Bool:
  +r = PO.seg_seg(a, b, c, d)
  Bool.pick(Bool, P.xres_ok(r),
    xrel_is_proper(P.xres_rel(r)), True{})

def pt_xy(+p: V.Point) -> V.Vec2:
  V.V2{V.pt_x(p), V.pt_y(p)}

def pt_xz(+p: V.Point) -> V.Vec2:
  V.V2{V.pt_x(p), V.pt_z(p)}

def pt_yz(+p: V.Point) -> V.Vec2:
  V.V2{V.pt_y(p), V.pt_z(p)}

def segx_pair(+a: V.Point, +b: V.Point, +c: V.Point,
    +d: V.Point) -> Bool:
  +r3 = PO.orient3d(a, b, c, d)
  +cop = Bool.pick(Bool, P.pres_ok(r3),
    P.sign_is_zero(P.pres_sign(r3)), True{})
  +pxy = segx_proper2(pt_xy(a), pt_xy(b), pt_xy(c), pt_xy(d))
  +pxz = segx_proper2(pt_xz(a), pt_xz(b), pt_xz(c), pt_xz(d))
  +pyz = segx_proper2(pt_yz(a), pt_yz(b), pt_yz(c), pt_yz(d))
  +anyp = Bool.or(pxy, Bool.or(pxz, pyz))
  Bool.and(cop, anyp)

def okc(+ok: Bool, +done: Bool) -> Nat:
  Ty.okd_pack(Bool.and(ok, done), done)

def ck_done(+b: Ty.Brep, +fuel: Nat) -> Bool:
  Nat.is_le(Ty.ix_bound(b), fuel)

def hk_i(k: HK) -> Nat:
  HK{i, g} = k
  i

def hk_g(k: HK) -> U64:
  HK{i, g} = k
  g

def nat_cmp_go(+a: Nat, +b: Nat) -> B.Sgn:
  B.sgn_pick(Nat.is_lt(a, b), Nat.is_lt(b, a))

def hk_tie(c: B.Sgn, +x: U64, +y: U64) -> B.Sgn:
  match c:
    case B.Sz{}: Ty.u64_cmp_go(x, y)
    case _: c

def hk_cmp_go(+a: HK, +b: HK) -> B.Sgn:
  hk_tie(nat_cmp_go(hk_i(a), hk_i(b)), hk_g(a), hk_g(b))

def hk_cmp(a: HK, b: HK) -> B.Sgn:
  hk_cmp_go(a, b)

def hk_eq(+a: HK, +b: HK) -> Bool:
  Bool.and(Nat.is_eq(hk_i(a), hk_i(b)), U64.is_eq(hk_g(a), hk_g(b)))

def so_hk(s: B.So<&2, HK>) -> List<&2, HK>:
  B.So{ok, xs} = s
  xs

def hk_adj_go(xs: List<&2, HK>, +prev: HK, first: Bool) -> Bool:
  match xs:
    case Nil{}: True{}
    case +h <> t: Bool.and(Bool.or(first, Bool.not(hk_eq(h, prev))), hk_adj_go(t, h, False{}))

def hks_distinct(+xs: List<&2, HK>) -> Bool:
  hk_adj_go(so_hk(B.msort(~HK, ~hk_cmp, xs)), HK{0n, 0u64}, True{})

def hc_key(h: Ty.HCoedge) -> HK:
  Ty.HC{i, g} = h
  HK{i, g}

def hl_key(h: Ty.HLoop) -> HK:
  Ty.HL{i, g} = h
  HK{i, g}

def hf_key(h: Ty.HFace) -> HK:
  Ty.HF{i, g} = h
  HK{i, g}

def hs_key(h: Ty.HShell) -> HK:
  Ty.HS{i, g} = h
  HK{i, g}

def ho_key(h: Ty.HSolid) -> HK:
  Ty.HSo{i, g} = h
  HK{i, g}

def he_key(h: Ty.HEdge) -> HK:
  Ty.HE{i, g} = h
  HK{i, g}

def hv_key(h: Ty.HVertex) -> HK:
  Ty.HV{i, g} = h
  HK{i, g}

def hcs_keys(xs: List<&2, Ty.HCoedge>, acc: List<&2, HK>) -> List<&2, HK>:
  match xs:
    case Nil{}: acc
    case h <> t: hc_key(h) <> hcs_keys(t, acc)

def hls_keys(xs: List<&2, Ty.HLoop>, acc: List<&2, HK>) -> List<&2, HK>:
  match xs:
    case Nil{}: acc
    case h <> t: hl_key(h) <> hls_keys(t, acc)

def hfs_keys(xs: List<&2, Ty.HFace>, acc: List<&2, HK>) -> List<&2, HK>:
  match xs:
    case Nil{}: acc
    case h <> t: hf_key(h) <> hfs_keys(t, acc)

def hss_keys(xs: List<&2, Ty.HShell>, acc: List<&2, HK>) -> List<&2, HK>:
  match xs:
    case Nil{}: acc
    case h <> t: hs_key(h) <> hss_keys(t, acc)

def hos_keys(xs: List<&2, Ty.HSolid>, acc: List<&2, HK>) -> List<&2, HK>:
  match xs:
    case Nil{}: acc
    case h <> t: ho_key(h) <> hos_keys(t, acc)

def hc_nodup_go(done: Bool, +xs: List<&2, Ty.HCoedge>) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(hks_distinct(hcs_keys(xs, [])), True{})

def hc_nodup_c(+xs: List<&2, Ty.HCoedge>, +fuel: Nat) -> Nat:
  hc_nodup_go(Nat.is_le(List.length(&2, Ty.HCoedge, xs), fuel), xs)

def hsh_nodup_go(done: Bool, +xs: List<&2, Ty.HShell>) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(hks_distinct(hss_keys(xs, [])), True{})

def hsh_nodup_c(+xs: List<&2, Ty.HShell>, +fuel: Nat) -> Nat:
  hsh_nodup_go(Nat.is_le(List.length(&2, Ty.HShell, xs), fuel), xs)

def hcs_live(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(Ty.tres_ok(Ty.ix_ce(x, h)), hcs_live(t, x))

def hls_live(xs: List<&2, Ty.HLoop>, +x: Ty.Ix) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(Ty.tres_ok(Ty.ix_lp(x, h)), hls_live(t, x))

def hfs_live(xs: List<&2, Ty.HFace>, +x: Ty.Ix) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(Ty.tres_ok(Ty.ix_fa(x, h)), hfs_live(t, x))

def hss_live(xs: List<&2, Ty.HShell>, +x: Ty.Ix) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(Ty.tres_ok(Ty.ix_sh(x, h)), hss_live(t, x))

def hos_live(xs: List<&2, Ty.HSolid>, +x: Ty.Ix) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(Ty.tres_ok(Ty.ix_so(x, h)), hos_live(t, x))

def es_live(es: List<&2, Ty.Edge>, +x: Ty.Ix) -> Bool:
  match es:
    case Nil{}: True{}
    case +h <> t:
      Bool.and(Bool.and(Ty.tres_ok(Ty.ix_vx(x, Ty.ed_v0(h))), Ty.tres_ok(Ty.ix_vx(x, Ty.ed_v1(h)))),
        es_live(t, x))

def ces_live(cs: List<&2, Ty.Coedge>, +x: Ty.Ix) -> Bool:
  match cs:
    case Nil{}: True{}
    case h <> t: Bool.and(Ty.tres_ok(Ty.ix_ed(x, Ty.ce_edge(h))), ces_live(t, x))

def lps_live(ls: List<&2, Ty.Loop>, +x: Ty.Ix) -> Bool:
  match ls:
    case Nil{}: True{}
    case h <> t: Bool.and(hcs_live(Ty.lp_ces(h), x), lps_live(t, x))

def fas_live(fs: List<&2, Ty.Face>, +x: Ty.Ix) -> Bool:
  match fs:
    case Nil{}: True{}
    case h <> t: Bool.and(hls_live(Ty.fa_loops(h), x), fas_live(t, x))

def shs_live(ss: List<&2, Ty.Shell>, +x: Ty.Ix) -> Bool:
  match ss:
    case Nil{}: True{}
    case h <> t: Bool.and(hfs_live(Ty.sh_faces(h), x), shs_live(t, x))

def sos_live(os: List<&2, Ty.Solid>, +x: Ty.Ix) -> Bool:
  match os:
    case Nil{}: True{}
    case +h <> t:
      Bool.and(Bool.and(Ty.tres_ok(Ty.ix_sh(x, Ty.so_outer(h))), hss_live(Ty.so_cavities(h), x)),
        sos_live(t, x))

def incid_ok(+b: Ty.Brep, +x: Ty.Ix) -> Bool:
  +top = Ty.brep_top(b)
  Bool.and(Bool.and(Bool.and(es_live(Ty.brep_es(b), x), ces_live(Ty.brep_ces(b), x)),
    Bool.and(lps_live(Ty.brep_lps(b), x), fas_live(Ty.brep_fas(b), x))),
    Bool.and(Bool.and(shs_live(Ty.brep_shs(b), x), sos_live(Ty.brep_sos(b), x)),
      Bool.and(hos_live(Ty.cp_solids(top), x), hss_live(Ty.cp_shells(top), x))))

def incid_c_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(incid_ok(b, Ty.ix_of(b)), True{})

def brep_incid_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  incid_c_go(ck_done(b, fuel), b)

def uk_k(u: UK) -> HK:
  UK{k, f} = u
  k

def uk_f(u: UK) -> Bool:
  UK{k, f} = u
  f

def uk_cmp_go(+a: UK, +b: UK) -> B.Sgn:
  hk_cmp_go(uk_k(a), uk_k(b))

def uk_cmp(a: UK, b: UK) -> B.Sgn:
  uk_cmp_go(a, b)

def so_uk(s: B.So<&2, UK>) -> List<&2, UK>:
  B.So{ok, xs} = s
  xs

def ces_uks(cs: List<&2, Ty.Coedge>) -> List<&2, UK>:
  match cs:
    case Nil{}: []
    case +h <> t: UK{he_key(Ty.ce_edge(h)), Ty.ce_fwd(h)} <> ces_uks(t)

def uk_lt(+u: UK, +k: HK) -> Bool:
  B.sgn_is(hk_cmp_go(uk_k(u), k), B.Sn{})

def uk_skip_nx(xs: List<&2, UK>, +k: HK) -> Bool:
  match xs:
    case Nil{}: False{}
    case +h <> t: uk_lt(h, k)

def uk_skip(xs: List<&2, UK>, +k: HK, go: Bool) -> List<&2, UK>:
  match xs go:
    case h <> +t True{}: uk_skip(t, k, uk_skip_nx(t, k))
    case _ _: xs

def uc_rest(c: UC) -> List<&2, UK>:
  UC{n, t, f, rest} = c
  rest

def uk_take_nx(xs: List<&2, UK>, +k: HK) -> Bool:
  match xs:
    case Nil{}: False{}
    case +h <> t: hk_eq(uk_k(h), k)

def uk_take(xs: List<&2, UK>, +k: HK, +n: Nat, st: Bool, sf: Bool, go: Bool) -> UC:
  match xs go:
    case h <> +t True{}:
      +fw = uk_f(h)
      uk_take(t, k, Nat.add(n, 1n), Bool.or(st, fw), Bool.or(sf, Bool.not(fw)), uk_take_nx(t, k))
    case _ _: UC{n, st, sf, xs}

def uc_ok(c: UC, +p: Ty.Profile) -> Bool:
  UC{+n, t, f, rest} = c
  use_rule_ok(n, t, f, p)

def use_go(es: List<&2, Ty.Edge>, +i: Nat, +keys: List<&2, UK>, +p: Ty.Profile) -> Bool:
  match es:
    case Nil{}: True{}
    case h <> t:
      +k = {HK{i, Ty.ed_gen(h)} : HK}
      +s = uk_skip(keys, k, uk_skip_nx(keys, k))
      +c = uk_take(s, k, 0n, False{}, False{}, uk_take_nx(s, k))
      Bool.and(uc_ok(c, p), use_go(t, Nat.add(i, 1n), uc_rest(c), p))

def use_ok(+b: Ty.Brep, +p: Ty.Profile) -> Bool:
  use_go(Ty.brep_es(b), 0n, so_uk(B.msort(~UK, ~uk_cmp, ces_uks(Ty.brep_ces(b)))), p)

def use_c_go(done: Bool, +b: Ty.Brep, +prof: Ty.Profile) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(use_ok(b, prof), True{})

def brep_use_c(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Nat:
  use_c_go(ck_done(b, fuel), b, prof)

def loop_rest_go(rest: List<&2, Ty.HCoedge>, +x: Ty.Ix, +prev_v: Ty.HVertex, +first_v: Ty.HVertex,
    +prev_t: V.Vec2, +first_t: V.Vec2) -> Bool:
  match rest:
    case Nil{}: Bool.and(Ty.hv_eq(prev_v, first_v), v2_eq(prev_t, first_t))
    case h <> t:
      +ce = Ty.tres_ce(Ty.ix_ce(x, h))
      +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
      +fwd = Ty.ce_fwd(ce)
      +trim = Ty.ce_trim(ce)
      +step = Bool.and(Ty.hv_eq(prev_v, o_v_start(ed, fwd)), v2_eq(prev_t, trim_o_start(trim, fwd)))
      Bool.and(step, loop_rest_go(t, x, o_v_end(ed, fwd), first_v, trim_o_end(trim, fwd), first_t))

def hcs_uks(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> List<&2, UK>:
  match xs:
    case Nil{}: []
    case h <> t:
      +ce = Ty.tres_ce(Ty.ix_ce(x, h))
      UK{he_key(Ty.ce_edge(ce)), Ty.ce_fwd(ce)} <> hcs_uks(t, x)

def seam_go(xs: List<&2, UK>, +pk: HK, +pf: Bool, +run: Nat) -> Bool:
  match xs:
    case Nil{}: True{}
    case +h <> t:
      +same = Bool.and(Nat.is_lt(0n, run), hk_eq(uk_k(h), pk))
      +f = uk_f(h)
      +n2 = Bool.pick(Nat, same, Nat.add(run, 1n), 1n)
      +bad = Bool.and(same, Bool.or(Nat.is_le(2n, run), Bool.not(Bool.xor(f, pf))))
      Bool.and(Bool.not(bad), seam_go(t, uk_k(h), f, n2))

def loop_seam_ok(+hcs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> Bool:
  seam_go(so_uk(B.msort(~UK, ~uk_cmp, hcs_uks(hcs, x))), HK{0n, 0u64}, False{}, 0n)

def ed_degen(+e: Ty.Edge) -> Bool:
  U64.is_eq(Ty.ekind_tag(Ty.ed_kind(e)), 1u64)

def hcs_ndeg(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> Nat:
  match xs:
    case Nil{}: 0n
    case h <> t:
      +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(Ty.tres_ce(Ty.ix_ce(x, h)))))
      Nat.add(Bool.pick(Nat, ed_degen(ed), 1n, 0n), hcs_ndeg(t, x))

def loop_pole_ok(+hcs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> Bool:
  +nd = hcs_ndeg(hcs, x)
  Bool.or(Nat.is_eq(nd, 0n), Bool.and(Nat.is_eq(List.length(&2, Ty.HCoedge, hcs), 1n), Nat.is_eq(nd, 1n)))

def loop_one_ok(+hcs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> Bool:
  match hcs:
    case Nil{}: True{}
    case +fh <> +rest:
      +fce = Ty.tres_ce(Ty.ix_ce(x, fh))
      +fed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(fce)))
      +ffwd = Ty.ce_fwd(fce)
      +ftrim = Ty.ce_trim(fce)
      +all = {fh <> rest : List<&2, Ty.HCoedge>}
      +chain = loop_rest_go(rest, x, o_v_end(fed, ffwd), o_v_start(fed, ffwd),
        trim_o_end(ftrim, ffwd), trim_o_start(ftrim, ffwd))
      Bool.and(Bool.and(chain, hks_distinct(hcs_keys(all, []))),
        Bool.and(loop_seam_ok(all, x), loop_pole_ok(all, x)))

def lps_loop_ok(ls: List<&2, Ty.Loop>, +x: Ty.Ix) -> Bool:
  match ls:
    case Nil{}: True{}
    case h <> t: Bool.and(loop_one_ok(Ty.lp_ces(h), x), lps_loop_ok(t, x))

def loop_c_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(lps_loop_ok(Ty.brep_lps(b), Ty.ix_of(b)), True{})

def brep_loop_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  loop_c_go(ck_done(b, fuel), b)

def hls_outer(xs: List<&2, Ty.HLoop>, +x: Ty.Ix) -> Nat:
  match xs:
    case Nil{}: 0n
    case h <> t:
      +o = U64.is_eq(Ty.lkind_tag(Ty.lp_kind(Ty.tres_lp(Ty.ix_lp(x, h)))), 0u64)
      Nat.add(Bool.pick(Nat, o, 1n, 0n), hls_outer(t, x))

def fas_kind_ok(fs: List<&2, Ty.Face>, +x: Ty.Ix) -> Bool:
  match fs:
    case Nil{}: True{}
    case h <> t: Bool.and(Nat.is_eq(hls_outer(Ty.fa_loops(h), x), 1n), fas_kind_ok(t, x))

def facekind_c_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(fas_kind_ok(Ty.brep_fas(b), Ty.ix_of(b)), True{})

def brep_facekind_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  facekind_c_go(ck_done(b, fuel), b)

def so_sh_list(+s: Ty.Solid) -> List<&2, Ty.HShell>:
  Ty.so_outer(s) <> Ty.so_cavities(s)

def fas_lkeys(fs: List<&2, Ty.Face>) -> List<&2, HK>:
  match fs:
    case Nil{}: []
    case h <> t: hls_keys(Ty.fa_loops(h), fas_lkeys(t))

def shs_fkeys(ss: List<&2, Ty.Shell>) -> List<&2, HK>:
  match ss:
    case Nil{}: []
    case h <> t: hfs_keys(Ty.sh_faces(h), shs_fkeys(t))

def sos_skeys(os: List<&2, Ty.Solid>, acc: List<&2, HK>) -> List<&2, HK>:
  match os:
    case Nil{}: acc
    case h <> t: hss_keys(so_sh_list(h), sos_skeys(t, acc))

def shs_no_open(ss: List<&2, Ty.Shell>) -> Bool:
  match ss:
    case Nil{}: True{}
    case h <> t: Bool.and(U64.is_ne(Ty.skind_tag(Ty.sh_kind(h)), 2u64), shs_no_open(t))

def hss_kind(xs: List<&2, Ty.HShell>, +x: Ty.Ix, +tag: U64) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(U64.is_eq(Ty.skind_tag(Ty.sh_kind(Ty.tres_sh(Ty.ix_sh(x, h)))), tag), hss_kind(t, x, tag))

def sos_kinds(os: List<&2, Ty.Solid>, +x: Ty.Ix) -> Bool:
  match os:
    case Nil{}: True{}
    case +h <> t:
      Bool.and(Bool.and(hss_kind([Ty.so_outer(h)], x, 0u64), hss_kind(Ty.so_cavities(h), x, 1u64)),
        sos_kinds(t, x))

def prof_ok(+b: Ty.Brep, +x: Ty.Ix, p: Ty.Profile) -> Bool:
  match p:
    case Ty.P_manifold_solid{}:
      +top = Ty.brep_top(b)
      +own = Bool.and(hks_distinct(fas_lkeys(Ty.brep_fas(b))), hks_distinct(shs_fkeys(Ty.brep_shs(b))))
      +sh = hks_distinct(sos_skeys(Ty.brep_sos(b), hss_keys(Ty.cp_shells(top), [])))
      Bool.and(Bool.and(own, sh), Bool.and(Bool.and(shs_no_open(Ty.brep_shs(b)), sos_kinds(Ty.brep_sos(b), x)),
        hks_distinct(hos_keys(Ty.cp_solids(top), []))))
    case Ty.P_open_shell{}:
      Bool.and(hks_distinct(fas_lkeys(Ty.brep_fas(b))), hks_distinct(shs_fkeys(Ty.brep_shs(b))))

def prof_c_go(done: Bool, +b: Ty.Brep, +prof: Ty.Profile) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(prof_ok(b, Ty.ix_of(b), prof), True{})

def brep_prof_c(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Nat:
  prof_c_go(ck_done(b, fuel), b, prof)

def es_embed_ok(es: List<&2, Ty.Edge>, +x: Ty.Ix, +fuel: Nat) -> Bool:
  match es:
    case Nil{}: True{}
    case +h <> t:
      +kind = Ty.ed_kind(h)
      +fin_ok = Bool.or(Bool.not(Ty.ekind_is_curve(kind)), curve_fin_ok(Ty.ekind_curve(kind), fuel))
      +p0 = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v0(h))))
      +p1 = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v1(h))))
      Bool.and(Bool.and(fin_ok, edge_ends_on_curve(kind, p0, p1, fuel)), es_embed_ok(t, x, fuel))

def ces_trim_ok(cs: List<&2, Ty.Coedge>) -> Bool:
  match cs:
    case Nil{}: True{}
    case h <> t: Bool.and(trim_fin(Ty.ce_trim(h)), ces_trim_ok(t))

def fas_surf_ok(fs: List<&2, Ty.Face>) -> Bool:
  match fs:
    case Nil{}: True{}
    case h <> t: Bool.and(surf_fin_ok(Ty.fa_surf(h)), fas_surf_ok(t))

def ce_coinc_ok(+ce: Ty.Coedge, +ed: Ty.Edge, +x: Ty.Ix, +surf: G.GVal) -> Bool:
  +fwd = Ty.ce_fwd(ce)
  +trim = Ty.ce_trim(ce)
  +ts = trim_o_start(trim, fwd)
  +te = trim_o_end(trim, fwd)
  +ps = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, o_v_start(ed, fwd))))
  +pe = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, o_v_end(ed, fwd))))
  +rs = surf_at(surf, V.v2_x(ts), V.v2_y(ts))
  +re = surf_at(surf, V.v2_x(te), V.v2_y(te))
  Bool.and(G.gres_ok(rs), Bool.and(G.gres_ok(re), Bool.and(pt_eq(G.gres_p(rs), ps), pt_eq(G.gres_p(re), pe))))

def pt_on(surf: G.GVal, +p: V.Point) -> Bool:
  match surf:
    case G.GV_sp{w}: GO.sph_on(w, p)
    case G.GV_cy{w}: GO.cyl_on(w, p)
    case G.GV_co{w}: GO.cone_on(w, p)
    case G.GV_to{w}: GO.tor_on(w, p)
    case _: False{}

def vx_surf_on(+x: Ty.Ix, +hv: Ty.HVertex, +surf: G.GVal) -> Bool:
  pt_on(surf, Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, hv))))

def hcs_face_ok(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +surf: G.GVal, +coinc: Bool, +memb: Bool) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t:
      +ce = Ty.tres_ce(Ty.ix_ce(x, h))
      +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
      +fw = Ty.ce_fwd(ce)
      +c = Bool.or(Bool.not(coinc), ce_coinc_ok(ce, ed, x, surf))
      +m = Bool.or(Bool.not(memb), Bool.and(vx_surf_on(x, o_v_start(ed, fw), surf), vx_surf_on(x, o_v_end(ed, fw), surf)))
      Bool.and(Bool.and(c, m), hcs_face_ok(t, x, surf, coinc, memb))

def hls_face_ok(xs: List<&2, Ty.HLoop>, +x: Ty.Ix, +surf: G.GVal, +coinc: Bool, +memb: Bool) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(hcs_face_ok(Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, h))), x, surf, coinc, memb), hls_face_ok(t, x, surf, coinc, memb))

def surf_coinc(s: G.GVal) -> Bool:
  match s:
    case G.GV_pl{w}: True{}
    case G.GV_bp{w}: True{}
    case _: False{}

def surf_quad(s: G.GVal) -> Bool:
  match s:
    case G.GV_sp{w}: True{}
    case G.GV_cy{w}: True{}
    case G.GV_co{w}: True{}
    case G.GV_to{w}: True{}
    case _: False{}

def fas_coinc_ok(fs: List<&2, Ty.Face>, +x: Ty.Ix) -> Bool:
  match fs:
    case Nil{}: True{}
    case +h <> t:
      +sf = Ty.fa_surf(h)
      Bool.and(hls_face_ok(Ty.fa_loops(h), x, sf, surf_coinc(sf), surf_quad(sf)), fas_coinc_ok(t, x))

def embed_ok(+b: Ty.Brep, +x: Ty.Ix, +fuel: Nat) -> Bool:
  Bool.and(Bool.and(es_embed_ok(Ty.brep_es(b), x, fuel), ces_trim_ok(Ty.brep_ces(b))),
    Bool.and(fas_surf_ok(Ty.brep_fas(b)), fas_coinc_ok(Ty.brep_fas(b), x)))

def embed_c_go(done: Bool, +b: Ty.Brep, +fuel: Nat) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(embed_ok(b, Ty.ix_of(b), fuel), True{})

def brep_embed_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  embed_c_go(ck_done(b, fuel), b, fuel)

def hk_top() -> HK:
  HK{U64.to_nat(281474976710655u64), 18446744073709551615u64}

def hk_lt(+a: HK, +b: HK) -> Bool:
  B.sgn_is(hk_cmp_go(a, b), B.Sn{})

def trk_min(t: B.Tr<&2, HK>) -> HK:
  match t:
    case B.TL{v}: v
    case B.TN{l, r}: trk_min(l)

def kz_of(t: B.Tr<&2, HK>, +k: HK) -> Bool:
  match t:
    case B.TL{v}: False{}
    case B.TN{l, r}: hk_lt(k, trk_min(r))

def kf_go(t: B.Tr<&2, HK>, +k: HK, +base: U32, +n: U32, z: Bool) -> U32:
  match t z:
    case B.TL{v} _: base
    case B.TN{+l, r} True{}: kf_go(l, k, base, U32.shr(n), kz_of(l, k))
    case B.TN{l, +r} False{}:
      +h = U32.shr(n)
      kf_go(r, k, (base + h : U32), h, kz_of(r, k))

def kfind(tb: B.Tb<&2, HK>, +k: HK) -> U32:
  B.Tb{+n, +t} = tb
  kf_go(t, k, 0, n, kz_of(t, k))

def ktb(+ks: List<&2, HK>) -> B.Tb<&2, HK>:
  B.tb_of(HK, ks, hk_top())

def khas(+tb: B.Tb<&2, HK>, +k: HK) -> Bool:
  hk_eq(B.tb_get(HK, tb, kfind(tb, k)), k)

def hk_keep(c: Bool, +h: HK, rest: List<&2, HK>) -> List<&2, HK>:
  match c:
    case True{}: h <> rest
    case False{}: rest

def hk_uniq(xs: List<&2, HK>, +prev: HK, first: Bool) -> List<&2, HK>:
  match xs:
    case Nil{}: []
    case +h <> t: hk_keep(Bool.or(first, Bool.not(hk_eq(h, prev))), h, hk_uniq(t, h, False{}))

def hks_sorted_uniq(+xs: List<&2, HK>) -> List<&2, HK>:
  hk_uniq(so_hk(B.msort(~HK, ~hk_cmp, xs)), HK{0n, 0u64}, True{})

def hc_of(k: HK) -> Ty.HCoedge:
  HK{i, g} = k
  Ty.mk_hc(i, g)

def pv_k(x: PV) -> HK:
  PV{k, l, j, p} = x
  k

def pv_p(x: PV) -> Ty.HCoedge:
  PV{k, l, j, p} = x
  p

def hk_tie2(c: B.Sgn, +a: Nat, +b: Nat) -> B.Sgn:
  match c:
    case B.Sz{}: nat_cmp_go(a, b)
    case _: c

def pv_tie(c: B.Sgn, +la: Nat, +lb: Nat, +ja: Nat, +jb: Nat) -> B.Sgn:
  match c:
    case B.Sz{}: hk_tie2(nat_cmp_go(la, lb), ja, jb)
    case _: c

def pv_cmp_go(+a: PV, +b: PV) -> B.Sgn:
  PV{ka, la, ja, pa} = a
  PV{kb, lb, jb, pb} = b
  pv_tie(hk_cmp_go(ka, kb), la, lb, ja, jb)

def pv_cmp(a: PV, b: PV) -> B.Sgn:
  pv_cmp_go(a, b)

def so_pv(s: B.So<&2, PV>) -> List<&2, PV>:
  B.So{ok, xs} = s
  xs

def hc_last(xs: List<&2, Ty.HCoedge>, +d: Ty.HCoedge) -> Ty.HCoedge:
  match xs:
    case Nil{}: d
    case h <> t: hc_last(t, h)

def pv_loop(hs: List<&2, Ty.HCoedge>, +l: Nat, +j: Nat, +prev: Ty.HCoedge, acc: List<&2, PV>) -> List<&2, PV>:
  match hs:
    case Nil{}: acc
    case +h <> t: PV{hc_key(h), l, j, prev} <> pv_loop(t, l, Nat.add(j, 1n), h, acc)

def pv_all(ls: List<&2, Ty.Loop>, +l: Nat) -> List<&2, PV>:
  match ls:
    case Nil{}: []
    case h <> t:
      +hs = Ty.lp_ces(h)
      pv_loop(hs, l, 0n, hc_last(hs, Ty.hc_null()), pv_all(t, Nat.add(l, 1n)))

def pv_keep(c: Bool, +h: PV, rest: List<&2, PV>) -> List<&2, PV>:
  match c:
    case True{}: h <> rest
    case False{}: rest

def pv_first(xs: List<&2, PV>, +prev: HK, first: Bool) -> List<&2, PV>:
  match xs:
    case Nil{}: []
    case +h <> t: pv_keep(Bool.or(first, Bool.not(hk_eq(pv_k(h), prev))), h, pv_first(t, pv_k(h), False{}))

def pvs_ks(xs: List<&2, PV>) -> List<&2, HK>:
  match xs:
    case Nil{}: []
    case h <> t: pv_k(h) <> pvs_ks(t)

def pvs_ps(xs: List<&2, PV>) -> List<&2, Ty.HCoedge>:
  match xs:
    case Nil{}: []
    case h <> t: pv_p(h) <> pvs_ps(t)

def et_k(x: ET) -> HK:
  ET{k, c, h} = x
  k

def et_h(x: ET) -> Ty.HCoedge:
  ET{k, c, h} = x
  h

def et_cmp_go(+a: ET, +b: ET) -> B.Sgn:
  ET{ka, ca, ha} = a
  ET{kb, cb, hb} = b
  hk_tie2(hk_cmp_go(ka, kb), ca, cb)

def et_cmp(a: ET, b: ET) -> B.Sgn:
  et_cmp_go(a, b)

def so_et(s: B.So<&2, ET>) -> List<&2, ET>:
  B.So{ok, xs} = s
  xs

def ets_of(cs: List<&2, Ty.Coedge>, +i: Nat) -> List<&2, ET>:
  match cs:
    case Nil{}: []
    case +h <> t: ET{he_key(Ty.ce_edge(h)), i, Ty.mk_hc(i, Ty.ce_gen(h))} <> ets_of(t, Nat.add(i, 1n))

def t2_k(x: T2) -> HK:
  T2{k, a, b, two} = x
  k

def t2_emit(+n: Nat, +k: HK, +a: Ty.HCoedge, +b: Ty.HCoedge, acc: List<&2, T2>) -> List<&2, T2>:
  match n:
    case 0n: acc
    case 1n+m: T2{k, a, b, Nat.is_lt(1n, n)} <> acc

def t2_grp(xs: List<&2, ET>, +cur: HK, +a: Ty.HCoedge, +b: Ty.HCoedge, +n: Nat, +acc: List<&2, T2>) -> List<&2, T2>:
  match xs:
    case Nil{}: t2_emit(n, cur, a, b, acc)
    case +h <> t:
      +same = Bool.and(Nat.is_lt(0n, n), hk_eq(et_k(h), cur))
      t2_grp(t, et_k(h), Bool.pick(Ty.HCoedge, same, a, et_h(h)), Bool.pick(Ty.HCoedge, Bool.and(same, Nat.is_eq(n, 1n)), et_h(h), Bool.pick(Ty.HCoedge, same, b, Ty.hc_null())),
        Bool.pick(Nat, same, Nat.add(n, 1n), 1n), Bool.pick(List<&2, T2>, same, acc, t2_emit(n, cur, a, b, acc)))

def t2s_ks(xs: List<&2, T2>) -> List<&2, HK>:
  match xs:
    case Nil{}: []
    case h <> t: t2_k(h) <> t2s_ks(t)

def hmap_of(+b: Ty.Brep) -> Hmap:
  +pvs = pv_first(so_pv(B.msort(~PV, ~pv_cmp, pv_all(Ty.brep_lps(b), 0n))), HK{0n, 0u64}, True{})
  +t2 = List.reverse(&2, T2, t2_grp(so_et(B.msort(~ET, ~et_cmp, ets_of(Ty.brep_ces(b), 0n))), HK{0n, 0u64}, Ty.hc_null(), Ty.hc_null(), 0n, []))
  Hmap{ktb(pvs_ks(pvs)), B.tb_of(Ty.HCoedge, pvs_ps(pvs), Ty.hc_null()), ktb(t2s_ks(t2)),
    B.tb_of(T2, t2, T2{hk_top(), Ty.hc_null(), Ty.hc_null(), False{}})}

def hm_prev(+m: Hmap, +h: Ty.HCoedge) -> Ty.HCoedge:
  Hmap{+pk, +pp, tk, tv} = m
  +i = kfind(pk, hc_key(h))
  Bool.pick(Ty.HCoedge, hk_eq(B.tb_get(HK, pk, i), hc_key(h)), B.tb_get(Ty.HCoedge, pp, i), h)

def t2_twin(x: T2, +p: Ty.HCoedge) -> Ty.HCoedge:
  T2{k, +a, b, two} = x
  Bool.pick(Ty.HCoedge, Bool.not(Ty.hc_eq(a, p)), a, Bool.pick(Ty.HCoedge, two, b, p))

def hm_twin(+m: Hmap, +x: Ty.Ix, +p: Ty.HCoedge) -> Ty.HCoedge:
  Hmap{pk, pp, +tk, +tv} = m
  +ek = he_key(Ty.ce_edge(Ty.tres_ce(Ty.ix_ce(x, p))))
  +i = kfind(tk, ek)
  Bool.pick(Ty.HCoedge, hk_eq(B.tb_get(HK, tk, i), ek), t2_twin(B.tb_get(T2, tv, i), p), p)

def hm_step(+m: Hmap, +x: Ty.Ix, +h: Ty.HCoedge) -> Ty.HCoedge:
  hm_twin(m, x, hm_prev(m, h))

def hc_nondegen(+x: Ty.Ix, +h: Ty.HCoedge) -> Bool:
  Bool.not(ed_degen(Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(Ty.tres_ce(Ty.ix_ce(x, h)))))))

def slot_keys(cs: List<&2, Ty.Coedge>, +i: Nat, acc: List<&2, HK>) -> List<&2, HK>:
  match cs:
    case Nil{}: acc
    case h <> t: HK{i, Ty.ce_gen(h)} <> slot_keys(t, Nat.add(i, 1n), acc)

def mem_keys(ls: List<&2, Ty.Loop>, acc: List<&2, HK>) -> List<&2, HK>:
  match ls:
    case Nil{}: acc
    case h <> t: hcs_keys(Ty.lp_ces(h), mem_keys(t, acc))

def nxt_of(c: GC, k: HK) -> U32:
  GC{+m, +x, +s} = c
  kfind(s, hc_key(hm_step(m, x, hc_of(k))))

def nd_of(c: GC, k: HK) -> Bool:
  GC{m, +x, s} = c
  hc_nondegen(x, hc_of(k))

def jm_j(x: JM) -> U32:
  JM{j, m} = x
  j

def jm_m(x: JM) -> U32:
  JM{j, m} = x
  m

def jm_step(t: B.Tb<&2, JM>, x: JM) -> JM:
  JM{+j, m} = x
  +y = B.tb_get(JM, t, j)
  JM{jm_j(y), U32.min(m, jm_m(y))}

def jm_rounds(r: Nat, +xs: List<&2, JM>) -> List<&2, JM>:
  match r:
    case 0n: xs
    case 1n+q: jm_rounds(q, B.pmap(~JM, ~B.Tb<&2, JM>, ~JM, ~jm_step, B.tb_of(JM, xs, JM{0, 0}), xs))

def jm_init(xs: List<&2, U32>, +i: U32) -> List<&2, JM>:
  match xs:
    case Nil{}: []
    case h <> t: JM{h, i} <> jm_init(t, (i + 1 : U32))

def mark_go(xs: List<&2, JM>, +t: B.Tb<&2, Bool>) -> B.Tb<&2, Bool>:
  match xs:
    case Nil{}: t
    case h <> r: mark_go(r, B.tb_set(Bool, t, jm_j(h), True{}))

def ln_lab(x: LN) -> U32:
  LN{lab, n} = x
  lab

def ln_cmp_go(+a: LN, +b: LN) -> B.Sgn:
  B.u_cmp_go(ln_lab(a), ln_lab(b))

def ln_cmp(a: LN, b: LN) -> B.Sgn:
  ln_cmp_go(a, b)

def so_ln(s: B.So<&2, LN>) -> List<&2, LN>:
  B.So{ok, xs} = s
  xs

def ln_keep(c: Bool, +lab: U32, +n: Nat, rest: List<&2, LN>) -> List<&2, LN>:
  match c:
    case True{}: LN{lab, n} <> rest
    case False{}: rest

def cyc_lns(xs: List<&2, JM>, nds: List<&2, Bool>, +cyc: B.Tb<&2, Bool>, +i: U32) -> List<&2, LN>:
  match xs:
    case Nil{}: []
    case h <> t:
      match nds:
        case Nil{}: []
        case d <> dt:
          ln_keep(B.tb_get(Bool, cyc, i), jm_m(h), Bool.pick(Nat, d, 1n, 0n), cyc_lns(t, dt, cyc, (i + 1 : U32)))

def ln_sum(xs: List<&2, LN>, +t: B.Tb<&2, Nat>) -> B.Tb<&2, Nat>:
  match xs:
    case Nil{}: t
    case h <> r:
      LN{+lab, n} = h
      ln_sum(r, B.tb_set(Nat, t, lab, Nat.add(n, B.tb_get(Nat, t, lab))))

def jms_m(xs: List<&2, JM>) -> List<&2, U32>:
  match xs:
    case Nil{}: []
    case h <> t: jm_m(h) <> jms_m(t)

def orb_of(+b: Ty.Brep, +x: Ty.Ix, +m: Hmap) -> Orb:
  +sk = hks_sorted_uniq(slot_keys(Ty.brep_ces(b), 0n, mem_keys(Ty.brep_lps(b), [])))
  +st = ktb(sk)
  +n = B.ulen(HK, sk)
  +gc = {GC{m, x, st} : GC}
  +nxt = B.pmap(~HK, ~GC, ~U32, ~nxt_of, gc, sk)
  +nds = B.pmap(~HK, ~GC, ~Bool, ~nd_of, gc, sk)
  +jm = jm_rounds(B.rounds_of(n), jm_init(nxt, 0))
  +cyc = mark_go(jm, B.tb_of(Bool, B.rep_n(Bool, U32.to_nat(n), False{}), False{}))
  +lns = so_ln(B.msort(~LN, ~ln_cmp, cyc_lns(jm, nds, cyc, 0)))
  Orb{st, B.tb_of(U32, nxt, 0), cyc, B.tb_of(U32, jms_m(jm), 0),
    ln_sum(lns, B.tb_of(Nat, B.rep_n(Nat, U32.to_nat(n), 0n), 0n)), B.tb_of(Bool, nds, False{})}

def sv_k(x: SV) -> HK:
  SV{k, c, h} = x
  k

def sv_h(x: SV) -> Ty.HCoedge:
  SV{k, c, h} = x
  h

def sv_cmp_go(+a: SV, +b: SV) -> B.Sgn:
  SV{ka, ca, ha} = a
  SV{kb, cb, hb} = b
  hk_tie2(hk_cmp_go(ka, kb), ca, cb)

def sv_cmp(a: SV, b: SV) -> B.Sgn:
  sv_cmp_go(a, b)

def so_sv(s: B.So<&2, SV>) -> List<&2, SV>:
  B.So{ok, xs} = s
  xs

def svs_of(cs: List<&2, Ty.Coedge>, +x: Ty.Ix, +i: Nat) -> List<&2, SV>:
  match cs:
    case Nil{}: []
    case +h <> t:
      +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(h)))
      SV{hv_key(o_v_start(ed, Ty.ce_fwd(h))), i, Ty.mk_hc(i, Ty.ce_gen(h))} <> svs_of(t, x, Nat.add(i, 1n))

def sv_lt(+s: SV, +k: HK) -> Bool:
  hk_lt(sv_k(s), k)

def sv_skip_nx(xs: List<&2, SV>, +k: HK) -> Bool:
  match xs:
    case Nil{}: False{}
    case +h <> t: sv_lt(h, k)

def sv_skip(xs: List<&2, SV>, +k: HK, go: Bool) -> List<&2, SV>:
  match xs go:
    case h <> +t True{}: sv_skip(t, k, sv_skip_nx(t, k))
    case _ _: xs

def sv_take_nx(xs: List<&2, SV>, +k: HK) -> Bool:
  match xs:
    case Nil{}: False{}
    case +h <> t: hk_eq(sv_k(h), k)

def sv_take(xs: List<&2, SV>, +k: HK, acc: List<&2, Ty.HCoedge>, go: Bool) -> SS:
  match xs go:
    case +h <> +t True{}: sv_take(t, k, sv_h(h) <> acc, sv_take_nx(t, k))
    case _ _: SS{List.reverse(&2, Ty.HCoedge, acc), xs}

def ss_hs(x: SS) -> List<&2, Ty.HCoedge>:
  SS{hs, rest} = x
  hs

def ss_rest(x: SS) -> List<&2, SV>:
  SS{hs, rest} = x
  rest

def oc_id(+c: OC, +h: Ty.HCoedge) -> U32:
  OC{o, x} = c
  Orb{s, nx, cyc, lab, ndc, nd} = o
  kfind(s, hc_key(h))

def hcs_nd(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> Nat:
  match xs:
    case Nil{}: 0n
    case h <> t: Nat.add(Bool.pick(Nat, hc_nondegen(x, h), 1n, 0n), hcs_nd(t, x))

def fnd_pick(c: Bool, +h: Ty.HCoedge, rest: Ty.HCoedge) -> Ty.HCoedge:
  match c:
    case True{}: h
    case False{}: rest

def hcs_first_nd(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> Ty.HCoedge:
  match xs:
    case Nil{}: Ty.hc_null()
    case +h <> t: fnd_pick(hc_nondegen(x, h), h, hcs_first_nd(t, x))

def orb_nx(o: Orb, +i: U32) -> U32:
  Orb{s, nx, cyc, lab, ndc, nd} = o
  B.tb_get(U32, nx, i)

def orb_steps(o: Orb, +i: U32) -> Nat:
  Orb{s, nx, cyc, +lab, +ndc, +nd} = o
  +c1 = B.tb_get(U32, nx, i)
  Nat.sub(Nat.add(1n, B.tb_get(Nat, ndc, B.tb_get(U32, lab, i))), Bool.pick(Nat, B.tb_get(Bool, nd, c1), 1n, 0n))

def orb_cyc(o: Orb, +i: U32) -> Bool:
  Orb{s, nx, cyc, lab, ndc, nd} = o
  B.tb_get(Bool, cyc, i)

def vx_orbit_ok(+o: Orb, +x: Ty.Ix, +ss: List<&2, Ty.HCoedge>) -> Bool:
  +nd = hcs_nd(ss, x)
  +i = oc_id(OC{o, x}, hcs_first_nd(ss, x))
  +c1 = orb_nx(o, i)
  +one = U32.is_eq(c1, i)
  +closed = Bool.or(one, orb_cyc(o, i))
  +steps = Bool.pick(Nat, one, 1n, orb_steps(o, i))
  Bool.or(Nat.is_eq(nd, 0n), Bool.and(closed, Nat.is_eq(steps, nd)))

def vs_link_go(vs: List<&2, Ty.Vertex>, +i: Nat, +svs: List<&2, SV>, +o: Orb, +x: Ty.Ix) -> Bool:
  match vs:
    case Nil{}: True{}
    case h <> t:
      +k = {HK{i, Ty.vx_gen(h)} : HK}
      +s = sv_skip(svs, k, sv_skip_nx(svs, k))
      +g = sv_take(s, k, [], sv_take_nx(s, k))
      Bool.and(vx_orbit_ok(o, x, ss_hs(g)), vs_link_go(t, Nat.add(i, 1n), ss_rest(g), o, x))

def cl_k(x: CL) -> HK:
  CL{k, l} = x
  k

def cl_l(x: CL) -> Nat:
  CL{k, l} = x
  l

def cl_cmp_go(+a: CL, +b: CL) -> B.Sgn:
  hk_tie2(hk_cmp_go(cl_k(a), cl_k(b)), cl_l(a), cl_l(b))

def cl_cmp(a: CL, b: CL) -> B.Sgn:
  cl_cmp_go(a, b)

def so_cl(s: B.So<&2, CL>) -> List<&2, CL>:
  B.So{ok, xs} = s
  xs

def cls_hcs(xs: List<&2, Ty.HCoedge>, +l: Nat, acc: List<&2, CL>) -> List<&2, CL>:
  match xs:
    case Nil{}: acc
    case h <> t: CL{hc_key(h), l} <> cls_hcs(t, l, acc)

def cls_all(ls: List<&2, Ty.Loop>, +l: Nat) -> List<&2, CL>:
  match ls:
    case Nil{}: []
    case h <> t: cls_hcs(Ty.lp_ces(h), l, cls_all(t, Nat.add(l, 1n)))

def cl_skip_nx(xs: List<&2, CL>, +k: HK) -> Bool:
  match xs:
    case Nil{}: False{}
    case +h <> t: hk_lt(cl_k(h), k)

def cl_skip(xs: List<&2, CL>, +k: HK, go: Bool) -> List<&2, CL>:
  match xs go:
    case h <> +t True{}: cl_skip(t, k, cl_skip_nx(t, k))
    case _ _: xs

def cl_take_nx(xs: List<&2, CL>, +k: HK) -> Bool:
  match xs:
    case Nil{}: False{}
    case +h <> t: hk_eq(cl_k(h), k)

def cl_take(xs: List<&2, CL>, +k: HK, +n: Nat, +pl: Nat, go: Bool) -> CN:
  match xs go:
    case +h <> +t True{}:
      +l = cl_l(h)
      +nw = Bool.or(Nat.is_eq(n, 0n), Bool.not(Nat.is_eq(l, pl)))
      cl_take(t, k, Nat.add(n, Bool.pick(Nat, nw, 1n, 0n)), l, cl_take_nx(t, k))
    case _ _: CN{n, xs}

def cn_n(x: CN) -> Nat:
  CN{n, rest} = x
  n

def cn_rest(x: CN) -> List<&2, CL>:
  CN{n, rest} = x
  rest

def cov_go(cs: List<&2, Ty.Coedge>, +i: Nat, +cls: List<&2, CL>) -> Bool:
  match cs:
    case Nil{}: True{}
    case h <> t:
      +k = {HK{i, Ty.ce_gen(h)} : HK}
      +s = cl_skip(cls, k, cl_skip_nx(cls, k))
      +c = cl_take(s, k, 0n, 0n, cl_take_nx(s, k))
      Bool.and(Nat.is_eq(cn_n(c), 1n), cov_go(t, Nat.add(i, 1n), cn_rest(c)))

def cls_sorted(+b: Ty.Brep) -> List<&2, CL>:
  so_cl(B.msort(~CL, ~cl_cmp, cls_all(Ty.brep_lps(b), 0n)))

def link_ok(+b: Ty.Brep, +x: Ty.Ix) -> Bool:
  +m = hmap_of(b)
  +o = orb_of(b, x, m)
  +svs = so_sv(B.msort(~SV, ~sv_cmp, svs_of(Ty.brep_ces(b), x, 0n)))
  Bool.and(cov_go(Ty.brep_ces(b), 0n, cls_sorted(b)), vs_link_go(Ty.brep_vs(b), 0n, svs, o, x))

def link_c_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(link_ok(b, Ty.ix_of(b)), True{})

def brep_link_c(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Nat:
  match prof:
    case Ty.P_manifold_solid{}: link_c_go(ck_done(b, fuel), b)
    case Ty.P_open_shell{}: 3n

def ep_k(x: EP) -> HK:
  EP{k, p} = x
  k

def ep_p(x: EP) -> U32:
  EP{k, p} = x
  p

def ep_cmp_go(+a: EP, +b: EP) -> B.Sgn:
  hk_cmp_go(ep_k(a), ep_k(b))

def ep_cmp(a: EP, b: EP) -> B.Sgn:
  ep_cmp_go(a, b)

def so_ep(s: B.So<&2, EP>) -> List<&2, EP>:
  B.So{ok, xs} = s
  xs

def hcs_ekeys(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +p: U32, acc: List<&2, EP>) -> List<&2, EP>:
  match xs:
    case Nil{}: acc
    case h <> t: EP{he_key(Ty.ce_edge(Ty.tres_ce(Ty.ix_ce(x, h)))), p} <> hcs_ekeys(t, x, p, acc)

def hls_ekeys(xs: List<&2, Ty.HLoop>, +x: Ty.Ix, +p: U32, acc: List<&2, EP>) -> List<&2, EP>:
  match xs:
    case Nil{}: acc
    case h <> t: hcs_ekeys(Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, h))), x, p, hls_ekeys(t, x, p, acc))

def fa_ekeys(+x: Ty.Ix, +f: Ty.HFace, +p: U32, acc: List<&2, EP>) -> List<&2, EP>:
  hls_ekeys(Ty.fa_loops(Ty.tres_fa(Ty.ix_fa(x, f))), x, p, acc)

def hfs_ekeys(xs: List<&2, Ty.HFace>, +x: Ty.Ix, +p: U32) -> List<&2, EP>:
  match xs:
    case Nil{}: []
    case h <> t: fa_ekeys(x, h, p, hfs_ekeys(t, x, (p + 1 : U32)))

def ed_keep(c: Bool, +u: U32, +v: U32, rest: List<&2, B.Ed>) -> List<&2, B.Ed>:
  match c:
    case True{}: B.Ed{u, v} <> rest
    case False{}: rest

def ep_edges(xs: List<&2, EP>, +pk: HK, +pp: U32, first: Bool) -> List<&2, B.Ed>:
  match xs:
    case Nil{}: []
    case +h <> t:
      +k = ep_k(h)
      +p = ep_p(h)
      ed_keep(Bool.and(Bool.not(first), hk_eq(k, pk)), pp, p, ep_edges(t, k, p, False{}))

def all_zero(xs: List<&2, U32>) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(U32.is_eq(h, 0), all_zero(t))

def cc_conn(c: B.CC) -> Bool:
  B.CC{ok, ps} = c
  Bool.and(ok, all_zero(ps))

def sh_adj(+fs: List<&2, Ty.HFace>, +x: Ty.Ix) -> List<&2, B.Ed>:
  ep_edges(so_ep(B.msort(~EP, ~ep_cmp, hfs_ekeys(fs, x, 0))), HK{0n, 0u64}, 0, True{})

def sh_conn_ok(+fs: List<&2, Ty.HFace>, +x: Ty.Ix) -> Bool:
  Bool.and(hks_distinct(hfs_keys(fs, [])), cc_conn(B.components(B.ulen(Ty.HFace, fs), sh_adj(fs, x))))

def shs_conn_ok(ss: List<&2, Ty.Shell>, +x: Ty.Ix) -> Bool:
  match ss:
    case Nil{}: True{}
    case h <> t: Bool.and(sh_conn_ok(Ty.sh_faces(h), x), shs_conn_ok(t, x))

def conn_c_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(shs_conn_ok(Ty.brep_shs(b), Ty.ix_of(b)), True{})

def brep_conn_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  conn_c_go(ck_done(b, fuel), b)

def vx_coin_pt(+p: V.Point, +q: V.Point) -> Bool:
  PO.pteq3(V.pt_x(p), V.pt_y(p), V.pt_z(p), V.pt_x(q), V.pt_y(q), V.pt_z(q))

def f_nan(+x: F64) -> Bool:
  Bool.not(F64.is_eq(x, x))

def pt_nan(+p: V.Point) -> Bool:
  Bool.or(f_nan(V.pt_x(p)), Bool.or(f_nan(V.pt_y(p)), f_nan(V.pt_z(p))))

def f_cmp_go(+a: F64, +b: F64) -> B.Sgn:
  B.sgn_pick(F64.is_lt(a, b), F64.is_lt(b, a))

def f_tie(c: B.Sgn, +a: F64, +b: F64) -> B.Sgn:
  match c:
    case B.Sz{}: f_cmp_go(a, b)
    case _: c

def pt_cmp_go(+p: V.Point, +q: V.Point) -> B.Sgn:
  f_tie(f_tie(f_cmp_go(V.pt_x(p), V.pt_x(q)), V.pt_y(p), V.pt_y(q)), V.pt_z(p), V.pt_z(q))

def pt_cmp(p: V.Point, q: V.Point) -> B.Sgn:
  pt_cmp_go(p, q)

def so_pt(s: B.So<&2, V.Point>) -> List<&2, V.Point>:
  B.So{ok, xs} = s
  xs

def pt_keep(c: Bool, +p: V.Point, rest: List<&2, V.Point>) -> List<&2, V.Point>:
  match c:
    case True{}: p <> rest
    case False{}: rest

def vs_pts(vs: List<&2, Ty.Vertex>) -> List<&2, V.Point>:
  match vs:
    case Nil{}: []
    case h <> t:
      +p = Ty.vx_p(h)
      pt_keep(Bool.not(pt_nan(p)), p, vs_pts(t))

def pt_adj(xs: List<&2, V.Point>, +prev: V.Point, first: Bool) -> Bool:
  match xs:
    case Nil{}: True{}
    case +h <> t: Bool.and(Bool.or(first, Bool.not(vx_coin_pt(h, prev))), pt_adj(t, h, False{}))

def coin_ok(vs: List<&2, Ty.Vertex>) -> Bool:
  pt_adj(so_pt(B.msort(~V.Point, ~pt_cmp, vs_pts(vs))), V.Pt{0.0f64, 0.0f64, 0.0f64}, True{})

def coin_c_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(coin_ok(Ty.brep_vs(b)), True{})

def brep_coin_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  coin_c_go(ck_done(b, fuel), b)

def sg_e(s: SG) -> Ty.Edge:
  SG{e, a, b, safe} = s
  e

def sg_a(s: SG) -> V.Point:
  SG{e, a, b, safe} = s
  a

def sg_b(s: SG) -> V.Point:
  SG{e, a, b, safe} = s
  b

def sg_safe(s: SG) -> Bool:
  SG{e, a, b, safe} = s
  safe

def f_safe(+x: F64) -> Bool:
  +ax = F64.abs(x)
  Bool.or(F64.is_eq(x, 0.0f64), Bool.and(F64.is_le(F64{3256102530588868608u64}, ax), F64.is_le(ax, F64{5958262307011166208u64})))

def p_safe(+p: V.Point) -> Bool:
  Bool.and(f_safe(V.pt_x(p)), Bool.and(f_safe(V.pt_y(p)), f_safe(V.pt_z(p))))

def sg_bad(+s: SG, +t: SG) -> Bool:
  Bool.and(Bool.not(hes_share_end(sg_e(s), sg_e(t))), segx_pair(sg_a(s), sg_b(s), sg_a(t), sg_b(t)))

def sg_keep(c: Bool, +s: SG, rest: List<&2, SG>) -> List<&2, SG>:
  match c:
    case True{}: s <> rest
    case False{}: rest

def hcs_segs(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix, acc: List<&2, SG>) -> List<&2, SG>:
  match xs:
    case Nil{}: acc
    case h <> t:
      +e = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(Ty.tres_ce(Ty.ix_ce(x, h)))))
      +a = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v0(e))))
      +b = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v1(e))))
      sg_keep(ed_straight(e), SG{e, a, b, Bool.and(p_safe(a), p_safe(b))}, hcs_segs(t, x, acc))

def hls_segs(xs: List<&2, Ty.HLoop>, +x: Ty.Ix) -> List<&2, SG>:
  match xs:
    case Nil{}: []
    case h <> t: hcs_segs(Ty.lp_ces(Ty.tres_lp(Ty.ix_lp(x, h))), x, hls_segs(t, x))

def pcoord(p: V.Point, k: Nat) -> F64:
  match k:
    case 0n: V.pt_x(p)
    case 1n: V.pt_y(p)
    case _: V.pt_z(p)

def sg_lo(+s: SG, +k: Nat) -> F64:
  F64.min(pcoord(sg_a(s), k), pcoord(sg_b(s), k))

def sg_hi(+s: SG, +k: Nat) -> F64:
  F64.max(pcoord(sg_a(s), k), pcoord(sg_b(s), k))

def sg_ov(+s: SG, +t: SG) -> Bool:
  Bool.and(Bool.and(F64.is_le(sg_lo(s, 1n), sg_hi(t, 1n)), F64.is_le(sg_lo(t, 1n), sg_hi(s, 1n))),
    Bool.and(F64.is_le(sg_lo(s, 2n), sg_hi(t, 2n)), F64.is_le(sg_lo(t, 2n), sg_hi(s, 2n))))

def sg_cmp_go(+s: SG, +t: SG) -> B.Sgn:
  f_cmp_go(sg_lo(s, 0n), sg_lo(t, 0n))

def sg_cmp(s: SG, t: SG) -> B.Sgn:
  sg_cmp_go(s, t)

def so_sg(s: B.So<&2, SG>) -> List<&2, SG>:
  B.So{ok, xs} = s
  xs

def sp_add(c: Bool, +h: SG, acc: SP2) -> SP2:
  match c:
    case True{}:
      SP2{safe, risky} = acc
      SP2{h <> safe, risky}
    case False{}:
      SP2{safe, risky} = acc
      SP2{safe, h <> risky}

def sg_split(xs: List<&2, SG>, acc: SP2) -> SP2:
  match xs:
    case Nil{}: acc
    case +h <> t: sg_split(t, sp_add(sg_safe(h), h, acc))

def peek_x(xs: List<&2, SG>, +h: SG) -> Bool:
  match xs:
    case Nil{}: False{}
    case +y <> r: F64.is_le(sg_lo(y, 0n), sg_hi(h, 0n))

def pair_bad(ov: Bool, +h: SG, +y: SG) -> Bool:
  match ov:
    case False{}: False{}
    case True{}: sg_bad(h, y)

def sweep_one(xs: List<&2, SG>, +h: SG, go: Bool) -> Bool:
  match xs:
    case Nil{}: True{}
    case +y <> +r:
      match go:
        case False{}: True{}
        case True{}: Bool.and(Bool.not(pair_bad(sg_ov(h, y), h, y)), sweep_one(r, h, peek_x(r, h)))

def sweep_all(xs: List<&2, SG>) -> Bool:
  match xs:
    case Nil{}: True{}
    case +h <> +t: Bool.and(sweep_one(t, h, peek_x(t, h)), sweep_all(t))

def vs_all(+s: SG, xs: List<&2, SG>) -> Bool:
  match xs:
    case Nil{}: True{}
    case +h <> t: Bool.and(Bool.not(sg_bad(s, h)), vs_all(s, t))

def risky_ok(rs: List<&2, SG>, +all: List<&2, SG>) -> Bool:
  match rs:
    case Nil{}: True{}
    case +h <> t: Bool.and(vs_all(h, all), risky_ok(t, all))

def sp_ok(p: SP2, +all: List<&2, SG>) -> Bool:
  SP2{safe, risky} = p
  Bool.and(sweep_all(so_sg(B.msort(~SG, ~sg_cmp, safe))), risky_ok(risky, all))

def face_xing_ok(+x: Ty.Ix, fl: List<&2, Ty.HLoop>) -> Bool:
  +segs = hls_segs(fl, x)
  sp_ok(sg_split(segs, SP2{[], []}), segs)

def fas_xing_ok(fs: List<&2, Ty.Face>, +x: Ty.Ix) -> Bool:
  match fs:
    case Nil{}: True{}
    case h <> t: Bool.and(face_xing_ok(x, Ty.fa_loops(h)), fas_xing_ok(t, x))

def xing_c_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(fas_xing_ok(Ty.brep_fas(b), Ty.ix_of(b)), True{})

def brep_xing_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  xing_c_go(ck_done(b, fuel), b)

def hcs_all_lines(xs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t: Bool.and(edge_is_line(Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(Ty.tres_ce(Ty.ix_ce(x, h)))))), hcs_all_lines(t, x))

def hc_start_pt(+x: Ty.Ix, +h: Ty.HCoedge) -> V.Point:
  +ce = Ty.tres_ce(Ty.ix_ce(x, h))
  +ed = Ty.tres_ed(Ty.ix_ed(x, Ty.ce_edge(ce)))
  Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, o_v_start(ed, Ty.ce_fwd(ce)))))

def lp_newell_go(rest: List<&2, Ty.HCoedge>, +x: Ty.Ix, +prev: V.Point, +first: V.Point, +n: V.Dir) -> V.Dir:
  match rest:
    case Nil{}: newell_add(n, prev, first)
    case h <> t:
      +cur = hc_start_pt(x, h)
      lp_newell_go(t, x, cur, first, newell_add(n, prev, cur))

def lp_newell(hcs: List<&2, Ty.HCoedge>, +x: Ty.Ix) -> V.Dir:
  match hcs:
    case Nil{}: V.Dr{0.0f64, 0.0f64, 0.0f64}
    case fh <> rest:
      +p0 = hc_start_pt(x, fh)
      lp_newell_go(rest, x, p0, p0, V.Dr{0.0f64, 0.0f64, 0.0f64})

def loop_orient_class(+hcs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +surf: G.GVal, +same: Bool, +kind: Ty.LoopKind) -> Nat:
  +plane = surf_is_plane(surf)
  +lines = hcs_all_lines(hcs, x)
  +n = lp_newell(hcs, x)
  +nz = dr_is_zero(n)
  +nr = plane_normal_of(surf)
  +nok = G.gres_ok(nr)
  +adj = Bool.pick(V.Dir, same, G.gres_d(nr), dr_neg(G.gres_d(nr)))
  +dot = GO.dd_dot_raw(n, adj)
  +fin = T.is_finite(dot)
  +zdot = F64.is_eq(dot, 0.0f64)
  +outer = U64.is_eq(Ty.lkind_tag(kind), 0u64)
  +wrong = Bool.pick(Bool, outer, F64.is_lt(dot, 0.0f64), F64.is_lt(0.0f64, dot))
  +determ = Bool.and(plane, Bool.and(lines, Bool.and(Bool.not(nz), Bool.and(nok, Bool.and(fin, Bool.not(zdot))))))
  Bool.pick(Nat, determ, Bool.pick(Nat, wrong, 2n, 1n), 0n)

def loop_orient_c(+hcs: List<&2, Ty.HCoedge>, +x: Ty.Ix, +surf: G.GVal, +same: Bool, +kind: Ty.LoopKind) -> Nat:
  Ty.okd_pack(Bool.not(Nat.is_eq(loop_orient_class(hcs, x, surf, same, kind), 2n)), True{})

def lp_class(+x: Ty.Ix, +h: Ty.HLoop, +surf: G.GVal, +same: Bool) -> Nat:
  +lp = Ty.tres_lp(Ty.ix_lp(x, h))
  loop_orient_class(Ty.lp_ces(lp), x, surf, same, Ty.lp_kind(lp))

def oct_add(o: OCt, +c: Nat) -> OCt:
  OCt{bad, cert, skip} = o
  OCt{Bool.or(bad, Nat.is_eq(c, 2n)), Nat.add(cert, Bool.pick(Nat, Nat.is_eq(c, 0n), 0n, 1n)),
    Nat.add(skip, Bool.pick(Nat, Nat.is_eq(c, 0n), 1n, 0n))}

def hls_oct(xs: List<&2, Ty.HLoop>, +x: Ty.Ix, +surf: G.GVal, +same: Bool, o: OCt) -> OCt:
  match xs:
    case Nil{}: o
    case h <> t: hls_oct(t, x, surf, same, oct_add(o, lp_class(x, h, surf, same)))

def fas_oct(fs: List<&2, Ty.Face>, +x: Ty.Ix, o: OCt) -> OCt:
  match fs:
    case Nil{}: o
    case +h <> t: fas_oct(t, x, hls_oct(Ty.fa_loops(h), x, Ty.fa_surf(h), Ty.fa_same(h), o))

def oct_of(+b: Ty.Brep, +x: Ty.Ix) -> OCt:
  fas_oct(Ty.brep_fas(b), x, OCt{False{}, 0n, 0n})

def oct_bad(o: OCt) -> Bool:
  OCt{bad, cert, skip} = o
  bad

def oct_cert(o: OCt) -> Nat:
  OCt{bad, cert, skip} = o
  cert

def oct_skip(o: OCt) -> Nat:
  OCt{bad, cert, skip} = o
  skip

def orient_c_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(Bool.not(oct_bad(oct_of(b, Ty.ix_of(b)))), True{})

def brep_orient_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  orient_c_go(ck_done(b, fuel), b)

def orient_cert_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: 0n
    case True{}: cnt_pack(oct_cert(oct_of(b, Ty.ix_of(b))), True{})

def brep_orient_cert_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  orient_cert_go(ck_done(b, fuel), b)

def orient_skip_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: 0n
    case True{}: cnt_pack(oct_skip(oct_of(b, Ty.ix_of(b))), True{})

def brep_orient_skip_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  orient_skip_go(ck_done(b, fuel), b)

def fl_k(x: FL) -> HK:
  FL{k, f, h} = x
  k

def fl_h(x: FL) -> Ty.HFace:
  FL{k, f, h} = x
  h

def fl_cmp_go(+a: FL, +b: FL) -> B.Sgn:
  FL{ka, fa, ha} = a
  FL{kb, fb, hb} = b
  hk_tie2(hk_cmp_go(ka, kb), fa, fb)

def fl_cmp(a: FL, b: FL) -> B.Sgn:
  fl_cmp_go(a, b)

def so_fl(s: B.So<&2, FL>) -> List<&2, FL>:
  B.So{ok, xs} = s
  xs

def fls_hls(xs: List<&2, Ty.HLoop>, +f: Nat, +hf: Ty.HFace, acc: List<&2, FL>) -> List<&2, FL>:
  match xs:
    case Nil{}: acc
    case h <> t: FL{hl_key(h), f, hf} <> fls_hls(t, f, hf, acc)

def fls_all(fs: List<&2, Ty.Face>, +f: Nat) -> List<&2, FL>:
  match fs:
    case Nil{}: []
    case +h <> t: fls_hls(Ty.fa_loops(h), f, Ty.mk_hfa(f, Ty.fa_gen(h)), fls_all(t, Nat.add(f, 1n)))

def fl_keep(c: Bool, +h: FL, rest: List<&2, FL>) -> List<&2, FL>:
  match c:
    case True{}: h <> rest
    case False{}: rest

def fl_first(xs: List<&2, FL>, +prev: HK, first: Bool) -> List<&2, FL>:
  match xs:
    case Nil{}: []
    case +h <> t: fl_keep(Bool.or(first, Bool.not(hk_eq(fl_k(h), prev))), h, fl_first(t, fl_k(h), False{}))

def fls_ks(xs: List<&2, FL>) -> List<&2, HK>:
  match xs:
    case Nil{}: []
    case h <> t: fl_k(h) <> fls_ks(t)

def fls_hs(xs: List<&2, FL>) -> List<&2, Ty.HFace>:
  match xs:
    case Nil{}: []
    case h <> t: fl_h(h) <> fls_hs(t)

def cl_keep(c: Bool, +h: CL, rest: List<&2, CL>) -> List<&2, CL>:
  match c:
    case True{}: h <> rest
    case False{}: rest

def cl_first(xs: List<&2, CL>, +prev: HK, first: Bool) -> List<&2, CL>:
  match xs:
    case Nil{}: []
    case +h <> t: cl_keep(Bool.or(first, Bool.not(hk_eq(cl_k(h), prev))), h, cl_first(t, cl_k(h), False{}))

def cls_ks(xs: List<&2, CL>) -> List<&2, HK>:
  match xs:
    case Nil{}: []
    case h <> t: cl_k(h) <> cls_ks(t)

def cls_ls(xs: List<&2, CL>) -> List<&2, Nat>:
  match xs:
    case Nil{}: []
    case h <> t: cl_l(h) <> cls_ls(t)

def hl_pick(c: Bool, +l: Nat, lp: Ty.Loop) -> Ty.HLoop:
  match c:
    case True{}: Ty.mk_hlp(l, Ty.lp_gen(lp))
    case False{}: Ty.hlp_null()

def rc_owner_l(+r: RC, +h: Ty.HCoedge) -> Ty.HLoop:
  RC{x, +ck, +cl, +lg, fk, fh, cls} = r
  +i = kfind(ck, hc_key(h))
  +l = B.tb_get(Nat, cl, i)
  hl_pick(hk_eq(B.tb_get(HK, ck, i), hc_key(h)), l, B.tb_get(Ty.Loop, lg, U32.from_nat(l)))

def rc_owner_f(+r: RC, +h: Ty.HLoop) -> Ty.HFace:
  RC{x, ck, cl, lg, +fk, +fh, cls} = r
  +i = kfind(fk, hl_key(h))
  Bool.pick(Ty.HFace, hk_eq(B.tb_get(HK, fk, i), hl_key(h)), B.tb_get(Ty.HFace, fh, i), Ty.hfa_null())

def cls_pick(c: Bool, +v: Nat, +x: Ty.Ix, +hl: Ty.HLoop, +hf: Ty.HFace) -> Nat:
  match c:
    case True{}: v
    case False{}:
      +fa = Ty.tres_fa(Ty.ix_fa(x, hf))
      lp_class(x, hl, Ty.fa_surf(fa), Ty.fa_same(fa))

def rc_cls(+r: RC, +hl: Ty.HLoop, +hf: Ty.HFace) -> Nat:
  RC{+x, ck, cl, lg, fk, fh, +cls} = r
  Ty.HL{+li, lgn} = hl
  +known = Bool.and(Nat.is_lt(li, Ty.ix_nl(x)), Bool.not(Ty.hlp_eq(hl, Ty.hlp_null())))
  cls_pick(known, B.tb_get(Nat, cls, U32.from_nat(li)), x, hl, hf)

def own_cls(ls: List<&2, Ty.Loop>, +i: Nat, +x: Ty.Ix, +fk: B.Tb<&2, HK>, +fh: B.Tb<&2, Ty.HFace>) -> List<&2, Nat>:
  match ls:
    case Nil{}: []
    case h <> t:
      +hl = Ty.mk_hlp(i, Ty.lp_gen(h))
      +j = kfind(fk, hl_key(hl))
      +hf = Bool.pick(Ty.HFace, hk_eq(B.tb_get(HK, fk, j), hl_key(hl)), B.tb_get(Ty.HFace, fh, j), Ty.hfa_null())
      +fa = Ty.tres_fa(Ty.ix_fa(x, hf))
      lp_class(x, hl, Ty.fa_surf(fa), Ty.fa_same(fa)) <> own_cls(t, Nat.add(i, 1n), x, fk, fh)

def rc_of(+b: Ty.Brep, +x: Ty.Ix) -> RC:
  +cf = cl_first(cls_sorted(b), HK{0n, 0u64}, True{})
  +ff = fl_first(so_fl(B.msort(~FL, ~fl_cmp, fls_all(Ty.brep_fas(b), 0n))), HK{0n, 0u64}, True{})
  +fk = ktb(fls_ks(ff))
  +fh = B.tb_of(Ty.HFace, fls_hs(ff), Ty.hfa_null())
  RC{x, ktb(cls_ks(cf)), B.tb_of(Nat, cls_ls(cf), 0n), B.tb_of(Ty.Loop, Ty.brep_lps(b), Ty.lp_dflt()), fk, fh,
    B.tb_of(Nat, own_cls(Ty.brep_lps(b), 0n, x, fk, fh), 0n)}

def edge_recheck_ok(+r: RC, x2: T2) -> Bool:
  T2{k, +a, +b, two} = x2
  +la = rc_owner_l(r, a)
  +lb = rc_owner_l(r, b)
  +fa = rc_owner_f(r, la)
  +fb = rc_owner_f(r, lb)
  Bool.or(Ty.hfa_eq(fa, fb), Bool.and(Bool.not(Nat.is_eq(rc_cls(r, la, fa), 2n)), Bool.not(Nat.is_eq(rc_cls(r, lb, fb), 2n))))

def uc_twice(c: UC) -> Bool:
  UC{+n, t, f, rest} = c
  use_rule_ok(n, t, f, Ty.P_manifold_solid{})

def rchk_pick(tw: Bool, +m: Hmap, +r: RC, +k: HK) -> Bool:
  match tw:
    case False{}: True{}
    case True{}:
      Hmap{pk, pp, +tk, +tv} = m
      edge_recheck_ok(r, B.tb_get(T2, tv, kfind(tk, k)))

def rchk_go(es: List<&2, Ty.Edge>, +i: Nat, +keys: List<&2, UK>, +m: Hmap, +r: RC) -> Bool:
  match es:
    case Nil{}: True{}
    case h <> t:
      +k = {HK{i, Ty.ed_gen(h)} : HK}
      +s = uk_skip(keys, k, uk_skip_nx(keys, k))
      +c = uk_take(s, k, 0n, False{}, False{}, uk_take_nx(s, k))
      Bool.and(rchk_pick(uc_twice(c), m, r, k), rchk_go(t, Nat.add(i, 1n), uc_rest(c), m, r))

def recheck_ok(+b: Ty.Brep, +x: Ty.Ix) -> Bool:
  rchk_go(Ty.brep_es(b), 0n, so_uk(B.msort(~UK, ~uk_cmp, ces_uks(Ty.brep_ces(b)))), hmap_of(b), rc_of(b, x))

def recheck_c_go(done: Bool, +b: Ty.Brep) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(recheck_ok(b, Ty.ix_of(b)), True{})

def brep_recheck_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  recheck_c_go(ck_done(b, fuel), b)

def hc_keep2(c: Bool, +h: Ty.HCoedge, rest: List<&2, Ty.HCoedge>) -> List<&2, Ty.HCoedge>:
  match c:
    case True{}: h <> rest
    case False{}: rest

def svs_at(xs: List<&2, SV>, +k: HK) -> List<&2, Ty.HCoedge>:
  match xs:
    case Nil{}: []
    case +h <> t: hc_keep2(hk_eq(sv_k(h), k), sv_h(h), svs_at(t, k))

def vx_link_done(+b: Ty.Brep, +v: Ty.HVertex) -> Nat:
  +x = Ty.ix_of(b)
  +o = orb_of(b, x, hmap_of(b))
  okc(vx_orbit_ok(o, x, svs_at(svs_of(Ty.brep_ces(b), x, 0n), hv_key(v))), True{})

def vx_link_go(done: Bool, +b: Ty.Brep, +v: Ty.HVertex) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: vx_link_done(b, v)

def vx_link_ok(+b: Ty.Brep, +v: Ty.HVertex, +fuel: Nat) -> Nat:
  vx_link_go(ck_done(b, fuel), b, v)

def own_done(+n: Nat, +m: Nat, +fuel: Nat, +ffull: Nat) -> Bool:
  Bool.and(Nat.is_le(n, fuel), Nat.is_le(Nat.max(n, m), ffull))

def fas_loop_own_go(done: Bool, +fas: List<&2, Ty.Face>) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(hks_distinct(fas_lkeys(fas)), True{})

def fas_loop_own_c(+fas: List<&2, Ty.Face>, +fuel: Nat, +ffull: Nat) -> Nat:
  fas_loop_own_go(own_done(List.length(&2, Ty.Face, fas), Ty.fas_maxlen(fas, 0n), fuel, ffull), fas)

def shs_face_own_go(done: Bool, +shs: List<&2, Ty.Shell>) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(hks_distinct(shs_fkeys(shs)), True{})

def shs_face_own_c(+shs: List<&2, Ty.Shell>, +fuel: Nat, +ffull: Nat) -> Nat:
  shs_face_own_go(own_done(List.length(&2, Ty.Shell, shs), Ty.shs_maxlen(shs, 0n), fuel, ffull), shs)

def sos_own_go(done: Bool, +sos: List<&2, Ty.Solid>) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(hks_distinct(sos_skeys(sos, [])), True{})

def sos_own_c(+sos: List<&2, Ty.Solid>, +fuel: Nat, +ffull: Nat) -> Nat:
  sos_own_go(own_done(List.length(&2, Ty.Solid, sos), Nat.add(Ty.sos_maxlen(sos, 0n), 1n), fuel, ffull), sos)

def cp_sh_own_go(done: Bool, +cs: List<&2, Ty.HShell>, +sos: List<&2, Ty.Solid>) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(hks_distinct(hss_keys(cs, hks_sorted_uniq(sos_skeys(sos, [])))), True{})

def cp_sh_own_c(+top: Ty.Compound, +sos: List<&2, Ty.Solid>, +ffull: Nat) -> Nat:
  +cs = Ty.cp_shells(top)
  cp_sh_own_go(Nat.is_le(Nat.max(List.length(&2, Ty.HShell, cs), List.length(&2, Ty.Solid, sos)), ffull), cs, sos)

def cp_so_own_go(done: Bool, +cs: List<&2, Ty.HSolid>) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(hks_distinct(hos_keys(cs, [])), True{})

def cp_so_own_c(+top: Ty.Compound, +ffull: Nat) -> Nat:
  +cs = Ty.cp_solids(top)
  cp_so_own_go(Nat.is_le(List.length(&2, Ty.HSolid, cs), ffull), cs)

def sos_outer_all(os: List<&2, Ty.Solid>, +x: Ty.Ix) -> Bool:
  match os:
    case Nil{}: True{}
    case h <> t: Bool.and(hss_kind([Ty.so_outer(h)], x, 0u64), sos_outer_all(t, x))

def sos_outer_go(done: Bool, +sos: List<&2, Ty.Solid>, +shs: List<&2, Ty.Shell>) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(sos_outer_all(sos, Ty.ix_mk([], [], [], [], [], shs, [])), True{})

def sos_outer_kind_c(+sos: List<&2, Ty.Solid>, +shs: List<&2, Ty.Shell>, +fuel: Nat, +ffull: Nat) -> Nat:
  sos_outer_go(own_done(List.length(&2, Ty.Solid, sos), List.length(&2, Ty.Shell, shs), fuel, ffull), sos, shs)

def shs_no_open_go(done: Bool, +shs: List<&2, Ty.Shell>) -> Nat:
  match done:
    case False{}: Ty.okd_pack(False{}, False{})
    case True{}: okc(shs_no_open(shs), True{})

def shs_no_open_c(+shs: List<&2, Ty.Shell>, +fuel: Nat) -> Nat:
  shs_no_open_go(Nat.is_le(List.length(&2, Ty.Shell, shs), fuel), shs)

def ck_l(ok: Bool, +b: Ty.Brep, +x: Ty.Ix) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: Bool.and(Bool.not(oct_bad(oct_of(b, x))), recheck_ok(b, x))

def ck_k(ok: Bool, +b: Ty.Brep, +x: Ty.Ix) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: ck_l(fas_xing_ok(Ty.brep_fas(b), x), b, x)

def ck_j(ok: Bool, +b: Ty.Brep, +x: Ty.Ix) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: ck_k(coin_ok(Ty.brep_vs(b)), b, x)

def ck_i(ok: Bool, +b: Ty.Brep, +x: Ty.Ix) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: ck_j(shs_conn_ok(Ty.brep_shs(b), x), b, x)

def link_prof(+b: Ty.Brep, +x: Ty.Ix, p: Ty.Profile) -> Bool:
  match p:
    case Ty.P_manifold_solid{}: link_ok(b, x)
    case Ty.P_open_shell{}: True{}

def ck_h(ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: ck_i(link_prof(b, x, prof), b, x)

def ck_g(ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: ck_h(embed_ok(b, x, fuel), b, x, prof)

def ck_f(ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: ck_g(prof_ok(b, x, prof), b, x, prof, fuel)

def ck_e(ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: ck_f(fas_kind_ok(Ty.brep_fas(b), x), b, x, prof, fuel)

def ck_d(ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: ck_e(lps_loop_ok(Ty.brep_lps(b), x), b, x, prof, fuel)

def ck_c(ok: Bool, +b: Ty.Brep, +x: Ty.Ix, +prof: Ty.Profile, +fuel: Nat) -> Bool:
  match ok:
    case False{}: False{}
    case True{}: ck_d(use_ok(b, prof), b, x, prof, fuel)

def verdict(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Bool:
  +x = Ty.ix_of(b)
  ck_c(incid_ok(b, x), b, x, prof, fuel)

def ck_done_go(done: Bool, +b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  match done:
    case False{}: Ty.terr(T.F_exhausted{})
    case True{}: Bool.pick(Ty.TRes, verdict(b, prof, fuel), Ty.tok_brep(b), Ty.terr(T.F_invalid{}))

def ck_after_a(ok: Bool, +ra: Ty.TRes, +b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  match ok:
    case False{}: ra
    case True{}: ck_done_go(ck_done(b, fuel), b, prof, fuel)

def brep_checked_go(done: Bool, +b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  match done:
    case False{}: Ty.terr(T.F_exhausted{})
    case True{}:
      +ra = Ty.mk_brep(Ty.brep_vs(b), Ty.brep_es(b), Ty.brep_ces(b), Ty.brep_lps(b), Ty.brep_fas(b),
        Ty.brep_shs(b), Ty.brep_sos(b), Ty.brep_top(b), Ty.brep_stamp(b), fuel)
      ck_after_a(Ty.tres_ok(ra), ra, b, prof, fuel)

def brep_checked(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  brep_checked_go(ck_done(b, fuel), b, prof, fuel)
