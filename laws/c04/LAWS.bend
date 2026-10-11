import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c03/ops.bend as GO
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as Op
import ../../src/base/par.bend as B

def pt_bits_eq(+p: V.Point, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  Bool.and(U64.is_eq(F64.bits(V.pt_x(p)), wx),
    Bool.and(U64.is_eq(F64.bits(V.pt_y(p)), wy),
      U64.is_eq(F64.bits(V.pt_z(p)), wz)))

def dr_bits_eq(+d: V.Dir, +wx: U64, +wy: U64, +wz: U64) -> Bool:
  Bool.and(U64.is_eq(F64.bits(V.dr_x(d)), wx),
    Bool.and(U64.is_eq(F64.bits(V.dr_y(d)), wy),
      U64.is_eq(F64.bits(V.dr_z(d)), wz)))

def v2_bits_eq(+v: V.Vec2, +wx: U64, +wy: U64) -> Bool:
  Bool.and(U64.is_eq(F64.bits(V.v2_x(v)), wx),
    U64.is_eq(F64.bits(V.v2_y(v)), wy))

def ts_zero_bits(t: G.GVal) -> Bool:
  match t:
    case G.GV_ts{w}:
      G.Ts{a, b} = w
      Bool.and(v2_bits_eq(a, 0u64, 0u64),
        v2_bits_eq(b, 0u64, 0u64))
    case _: False{}

def pl_zero_bits(s: G.GVal) -> Bool:
  match s:
    case G.GV_pl{w}:
      G.Pl{o, u, v} = w
      Bool.and(pt_bits_eq(o, 0u64, 0u64, 0u64),
        Bool.and(dr_bits_eq(u, 0u64, 0u64, 0u64),
          dr_bits_eq(v, 0u64, 0u64, 0u64)))
    case _: False{}

def hv_null_chk(h: Ty.HVertex) -> Bool:
  Ty.HV{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def he_null_chk(h: Ty.HEdge) -> Bool:
  Ty.HE{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def hc_null_chk(h: Ty.HCoedge) -> Bool:
  Ty.HC{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def hlp_null_chk(h: Ty.HLoop) -> Bool:
  Ty.HL{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def hfa_null_chk(h: Ty.HFace) -> Bool:
  Ty.HF{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def hsh_null_chk(h: Ty.HShell) -> Bool:
  Ty.HS{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def hso_null_chk(h: Ty.HSolid) -> Bool:
  Ty.HSo{i, g} = h
  Bool.and(Nat.is_eq(i, 0n), U64.is_eq(g, 0u64))

def r_vx_zero(+r: Ty.TRes) -> Bool:
  +v = Ty.tres_vx(r)
  Bool.and(U64.is_eq(Ty.vx_gen(v), 0u64),
    pt_bits_eq(Ty.vx_p(v), 0u64, 0u64, 0u64))

def r_ed_dflt(+r: Ty.TRes) -> Bool:
  +e = Ty.tres_ed(r)
  Bool.and(U64.is_eq(Ty.ed_gen(e), 0u64),
    Bool.and(hv_null_chk(Ty.ed_v0(e)),
      Bool.and(hv_null_chk(Ty.ed_v1(e)),
        U64.is_eq(Ty.ekind_tag(Ty.ed_kind(e)), 1u64))))

def r_ce_dflt(+r: Ty.TRes) -> Bool:
  +c = Ty.tres_ce(r)
  Bool.and(U64.is_eq(Ty.ce_gen(c), 0u64),
    Bool.and(he_null_chk(Ty.ce_edge(c)),
      Bool.and(Bool.not(Ty.ce_fwd(c)),
        ts_zero_bits(Ty.ce_trim(c)))))

def r_lp_dflt(+r: Ty.TRes) -> Bool:
  +l = Ty.tres_lp(r)
  Bool.and(U64.is_eq(Ty.lp_gen(l), 0u64),
    Bool.and(Bool.not(Ty.hce_nonempty(Ty.lp_ces(l))),
      U64.is_eq(Ty.lkind_tag(Ty.lp_kind(l)), 0u64)))

def r_fa_dflt(+r: Ty.TRes) -> Bool:
  +f = Ty.tres_fa(r)
  Bool.and(U64.is_eq(Ty.fa_gen(f), 0u64),
    Bool.and(pl_zero_bits(Ty.fa_surf(f)),
      Bool.and(Bool.not(Ty.hlp_nonempty(Ty.fa_loops(f))),
        Ty.fa_same(f))))

def r_sh_dflt(+r: Ty.TRes) -> Bool:
  +s = Ty.tres_sh(r)
  Bool.and(U64.is_eq(Ty.sh_gen(s), 0u64),
    Bool.and(Bool.not(Ty.hfa_nonempty(Ty.sh_faces(s))),
      U64.is_eq(Ty.skind_tag(Ty.sh_kind(s)), 2u64)))

def r_so_dflt(+r: Ty.TRes) -> Bool:
  +s = Ty.tres_so(r)
  Bool.and(U64.is_eq(Ty.so_gen(s), 0u64),
    Bool.and(hsh_null_chk(Ty.so_outer(s)),
      Bool.not(Ty.hsh_nonempty(Ty.so_cavities(s)))))

def r_cp_empty(+r: Ty.TRes) -> Bool:
  +c = Ty.tres_cp(r)
  Bool.and(Bool.not(Ty.hso_nonempty(Ty.cp_solids(c))),
    Bool.not(Ty.hsh_nonempty(Ty.cp_shells(c))))

def r_brep_empty(+r: Ty.TRes) -> Bool:
  +b = Ty.tres_brep(r)
  Bool.and(U64.is_eq(Ty.brep_stamp(b), 0u64),
    Bool.and(
      Nat.is_eq(Ty.tres_n(Ty.vx_len(Ty.brep_vs(b), 8n)), 0n),
      Bool.not(Ty.cp_has_solids(Ty.brep_top(b)))))

def l1_v0() -> Ty.HVertex:
  Ty.mk_hv(0n, 1u64)

def l1_v1() -> Ty.HVertex:
  Ty.mk_hv(1n, 2u64)

def l1_he0() -> Ty.HEdge:
  Ty.mk_he(0n, 4u64)

def l1_hc0() -> Ty.HCoedge:
  Ty.mk_hc(0n, 6u64)

def l1_hc1() -> Ty.HCoedge:
  Ty.mk_hc(1n, 7u64)

def l1_p0() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def l1_d0() -> V.Dir:
  V.Dr{1.0f64, 0.0f64, 0.0f64}

def l1_ln() -> G.GVal:
  G.GV_ln{G.Ln{l1_p0(), l1_d0()}}

def l1_dom() -> G.Dom:
  G.Dom{0.0f64, 1.0f64}

def l1_es_line() -> List<&2, Ty.Edge>:
  Ty.Ed{4u64, l1_v0(), l1_v1(),
    Ty.EK_curve{l1_ln(), l1_dom()}} <> Nil{}

def l1_ces_seam(+f: Bool) -> List<&2, Ty.Coedge>:
  Ty.Ce{6u64, l1_he0(), f, Ty.trim_zero()} <>
    Ty.Ce{7u64, l1_he0(), Bool.not(f), Ty.trim_zero()} <>
    Nil{}

def l1_ix(+es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>) -> Ty.Ix:
  Ty.ix_mk(Nil{}, es, ces, Nil{}, Nil{}, Nil{}, Nil{})

def l1_b_ec(+es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>) -> Ty.Brep:
  Ty.Br{Nil{}, es, ces, Nil{}, Nil{}, Nil{}, Nil{},
    Ty.Cp{Nil{}, Nil{}}, 12u64}

law tok_ok:
  for v: Ty.TVal
  {Ty.tres_ok(Ty.Tok{v}) == True{} : Bool}

law tok_kind_doc:
  for v: Ty.TVal
  {Ty.tres_kind(Ty.Tok{v}) == T.F_invalid{} : T.FailKind}

law tok_show_ok:
  for v: Ty.TVal
  {String.eq(Ty.tres_show(Ty.Tok{v}), "ok") == True{} : Bool}

law terr_not_ok:
  for k: T.FailKind
  {Ty.tres_ok(Ty.terr(k)) == False{} : Bool}

law terr_kind:
  for k: T.FailKind
  {Ty.tres_kind(Ty.terr(k)) == k : T.FailKind}

law terr_show:
  for k: T.FailKind
  {Ty.tres_show(Ty.terr(k)) == T.FailKind.show(k) : String}

law terr_f_zero:
  for k: T.FailKind
  {U64.is_eq(F64.bits(Ty.tres_f(Ty.terr(k))), 0u64)
    == True{} : Bool}

law terr_n_zero:
  for k: T.FailKind
  {Nat.is_eq(Ty.tres_n(Ty.terr(k)), 0n) == True{} : Bool}

law terr_b_false:
  for k: T.FailKind
  {Ty.tres_b(Ty.terr(k)) == False{} : Bool}

law terr_vx_zero:
  for k: T.FailKind
  {r_vx_zero(Ty.terr(k)) == True{} : Bool}

law terr_ed_dflt:
  for k: T.FailKind
  {r_ed_dflt(Ty.terr(k)) == True{} : Bool}

law terr_ce_dflt:
  for k: T.FailKind
  {r_ce_dflt(Ty.terr(k)) == True{} : Bool}

law terr_lp_dflt:
  for k: T.FailKind
  {r_lp_dflt(Ty.terr(k)) == True{} : Bool}

law terr_fa_dflt:
  for k: T.FailKind
  {r_fa_dflt(Ty.terr(k)) == True{} : Bool}

law terr_sh_dflt:
  for k: T.FailKind
  {r_sh_dflt(Ty.terr(k)) == True{} : Bool}

law terr_so_dflt:
  for k: T.FailKind
  {r_so_dflt(Ty.terr(k)) == True{} : Bool}

law terr_cp_empty:
  for k: T.FailKind
  {r_cp_empty(Ty.terr(k)) == True{} : Bool}

law terr_brep_empty:
  for k: T.FailKind
  {r_brep_empty(Ty.terr(k)) == True{} : Bool}

law terr_hv_null:
  for k: T.FailKind
  {hv_null_chk(Ty.tres_hv(Ty.terr(k))) == True{} : Bool}

law terr_he_null:
  for k: T.FailKind
  {he_null_chk(Ty.tres_he(Ty.terr(k))) == True{} : Bool}

law terr_hc_null:
  for k: T.FailKind
  {hc_null_chk(Ty.tres_hc(Ty.terr(k))) == True{} : Bool}

law terr_hlp_null:
  for k: T.FailKind
  {hlp_null_chk(Ty.tres_hlp(Ty.terr(k))) == True{} : Bool}

law terr_hfa_null:
  for k: T.FailKind
  {hfa_null_chk(Ty.tres_hfa(Ty.terr(k))) == True{} : Bool}

law terr_hsh_null:
  for k: T.FailKind
  {hsh_null_chk(Ty.tres_hsh(Ty.terr(k))) == True{} : Bool}

law terr_hso_null:
  for k: T.FailKind
  {hso_null_chk(Ty.tres_hso(Ty.terr(k))) == True{} : Bool}

law mk_hv_idx:
  for i: Nat
  for g: U64
  {Ty.hv_idx(Ty.mk_hv(i, g)) == i : Nat}

law mk_hv_gen:
  for i: Nat
  for g: U64
  {Ty.hv_gen(Ty.mk_hv(i, g)) == g : U64}

law mk_he_idx:
  for i: Nat
  for g: U64
  {Ty.he_idx(Ty.mk_he(i, g)) == i : Nat}

law mk_he_gen:
  for i: Nat
  for g: U64
  {Ty.he_gen(Ty.mk_he(i, g)) == g : U64}

law mk_hc_idx:
  for i: Nat
  for g: U64
  {Ty.hc_idx(Ty.mk_hc(i, g)) == i : Nat}

law mk_hc_gen:
  for i: Nat
  for g: U64
  {Ty.hc_gen(Ty.mk_hc(i, g)) == g : U64}

law mk_hlp_idx:
  for i: Nat
  for g: U64
  {Ty.hlp_idx(Ty.mk_hlp(i, g)) == i : Nat}

law mk_hlp_gen:
  for i: Nat
  for g: U64
  {Ty.hlp_gen(Ty.mk_hlp(i, g)) == g : U64}

law mk_hfa_idx:
  for i: Nat
  for g: U64
  {Ty.hfa_idx(Ty.mk_hfa(i, g)) == i : Nat}

law mk_hfa_gen:
  for i: Nat
  for g: U64
  {Ty.hfa_gen(Ty.mk_hfa(i, g)) == g : U64}

law mk_hsh_idx:
  for i: Nat
  for g: U64
  {Ty.hsh_idx(Ty.mk_hsh(i, g)) == i : Nat}

law mk_hsh_gen:
  for i: Nat
  for g: U64
  {Ty.hsh_gen(Ty.mk_hsh(i, g)) == g : U64}

law mk_hso_idx:
  for i: Nat
  for g: U64
  {Ty.hso_idx(Ty.mk_hso(i, g)) == i : Nat}

law mk_hso_gen:
  for i: Nat
  for g: U64
  {Ty.hso_gen(Ty.mk_hso(i, g)) == g : U64}

law l1_use_solid_spec:
  for c: Nat
  for t: Bool
  for f: Bool
  {Op.use_rule_ok(c, t, f, Ty.P_manifold_solid{})
    == Bool.and(Nat.is_eq(c, 2n), Bool.and(t, f)) : Bool}

law l1_use_open_spec:
  for c: Nat
  for t: Bool
  for f: Bool
  {Op.use_rule_ok(c, t, f, Ty.P_open_shell{})
    == Bool.or(Nat.is_eq(c, 1n),
      Bool.and(Nat.is_eq(c, 2n), Bool.and(t, f))) : Bool}

law l1_use_solid_non2:
  for c: Nat
  for t: Bool
  for f: Bool
  {Bool.or(Nat.is_eq(c, 2n),
    Bool.not(Op.use_rule_ok(c, t, f,
      Ty.P_manifold_solid{}))) == True{} : Bool}

law l1_use_solid_pair:
  for t: Bool
  for f: Bool
  {Op.use_rule_ok(2n, t, f, Ty.P_manifold_solid{})
    == Bool.and(t, f) : Bool}

law l1_use_open_1:
  for t: Bool
  for f: Bool
  {Op.use_rule_ok(1n, t, f, Ty.P_open_shell{})
    == True{} : Bool}

law l1_use_open_non12:
  for c: Nat
  for t: Bool
  for f: Bool
  {Bool.or(Bool.or(Nat.is_eq(c, 1n), Nat.is_eq(c, 2n)),
    Bool.not(Op.use_rule_ok(c, t, f, Ty.P_open_shell{})))
    == True{} : Bool}

law l1_use_open_pair:
  for t: Bool
  for f: Bool
  {Op.use_rule_ok(2n, t, f, Ty.P_open_shell{})
    == Bool.and(t, f) : Bool}

law l1_use_go_nil:
  for i: Nat
  for keys: List<&2, Op.UK>
  for prof: Ty.Profile
  {Op.use_go(Nil{}, i, keys, prof) == True{} : Bool}

law l1_es_use_nil:
  for ces: List<&2, Ty.Coedge>
  for prof: Ty.Profile
  {Op.use_ok(l1_b_ec(Nil{}, ces), prof) == True{} : Bool}

law l1_seam_use:
  for f: Bool
  {Op.use_ok(l1_b_ec(l1_es_line(), l1_ces_seam(f)),
    Ty.P_manifold_solid{}) == True{} : Bool}

law l1_outer_rule:
  for g: U64
  for su: G.GVal
  for ls: List<&2, Ty.HLoop>
  for sa: Bool
  for x: Ty.Ix
  {Op.fas_kind_ok(Ty.Fa{g, su, ls, sa} <> Nil{}, x)
    == Bool.and(Nat.is_eq(Op.hls_outer(ls, x), 1n), True{}) : Bool}

law l1_ov_start:
  for a: Ty.HVertex
  for b: Ty.HVertex
  for f: Bool
  {Op.o_v_start(Ty.Ed{0u64, a, b, Ty.EK_degenerate{}},
    f) == Bool.pick(Ty.HVertex, f, a, b) : Ty.HVertex}

law l1_ov_end:
  for a: Ty.HVertex
  for b: Ty.HVertex
  for f: Bool
  {Op.o_v_end(Ty.Ed{0u64, a, b, Ty.EK_degenerate{}},
    f) == Bool.pick(Ty.HVertex, f, b, a) : Ty.HVertex}

law l1_ov_swap:
  for a: Ty.HVertex
  for b: Ty.HVertex
  for f: Bool
  {Op.o_v_start(Ty.Ed{0u64, a, b, Ty.EK_degenerate{}},
    f) == Op.o_v_end(Ty.Ed{0u64, a, b,
      Ty.EK_degenerate{}}, Bool.not(f)) : Ty.HVertex}

law l1_closed_start:
  for a: Ty.HVertex
  for f: Bool
  {Op.o_v_start(Ty.Ed{0u64, a, a, Ty.EK_degenerate{}},
    f) == a : Ty.HVertex}

law l1_closed_end:
  for a: Ty.HVertex
  for f: Bool
  {Op.o_v_end(Ty.Ed{0u64, a, a, Ty.EK_degenerate{}},
    f) == a : Ty.HVertex}

law l1_trim_ts_start:
  for a: V.Vec2
  for b: V.Vec2
  {Op.trim_start(G.GV_ts{G.Ts{a, b}}) == a : V.Vec2}

law l1_trim_ts_end:
  for a: V.Vec2
  for b: V.Vec2
  {Op.trim_end(G.GV_ts{G.Ts{a, b}}) == b : V.Vec2}

law l1_trim_tb_start:
  for b0: V.Vec2
  for b1: V.Vec2
  for b2: V.Vec2
  for b3: V.Vec2
  {Op.trim_start(G.GV_tb{G.Tb{b0, b1, b2, b3}})
    == b0 : V.Vec2}

law l1_trim_tb_end:
  for b0: V.Vec2
  for b1: V.Vec2
  for b2: V.Vec2
  for b3: V.Vec2
  {Op.trim_end(G.GV_tb{G.Tb{b0, b1, b2, b3}})
    == b3 : V.Vec2}

law l1_trim_o_start:
  for t: G.GVal
  for f: Bool
  {Op.trim_o_start(t, f)
    == Bool.pick(V.Vec2, f, Op.trim_start(t),
      Op.trim_end(t)) : V.Vec2}

law l1_trim_o_end:
  for t: G.GVal
  for f: Bool
  {Op.trim_o_end(t, f)
    == Bool.pick(V.Vec2, f, Op.trim_end(t),
      Op.trim_start(t)) : V.Vec2}

law l1_trim_swap:
  for t: G.GVal
  for f: Bool
  {Op.trim_o_start(t, f)
    == Op.trim_o_end(t, Bool.not(f)) : V.Vec2}

law l1_closure:
  for x: Ty.Ix
  for pv: Ty.HVertex
  for fv: Ty.HVertex
  for pt: V.Vec2
  for ft: V.Vec2
  {Op.loop_rest_go(Nil{}, x, pv, fv, pt, ft)
    == Bool.and(Ty.hv_eq(pv, fv), Op.v2_eq(pt, ft)) : Bool}

law l1_nodup_nil:
  for fuel: Nat
  {Op.hc_nodup_c(Nil{}, fuel) == 3n : Nat}

law l1_nodup_single:
  for h: Ty.HCoedge
  {Op.hc_nodup_c(h <> Nil{}, 2n) == 3n : Nat}

law l1_seam_run_nil:
  for pk: Op.HK
  for pf: Bool
  for run: Nat
  {Op.seam_go(Nil{}, pk, pf, run) == True{} : Bool}

law l1_seam_go_nil:
  for x: Ty.Ix
  {Op.loop_seam_ok(Nil{}, x) == True{} : Bool}

law l1_seam_accept:
  for f: Bool
  {Op.loop_seam_ok(l1_hc0() <> l1_hc1() <> Nil{},
    l1_ix(l1_es_line(), l1_ces_seam(f))) == True{} : Bool}

law l1_pole_nil:
  for +hcs: List<&2, Ty.HCoedge>
  for +x: Ty.Ix
  {Op.loop_pole_ok(hcs, x)
    == Bool.or(Nat.is_eq(Op.hcs_ndeg(hcs, x), 0n),
      Bool.and(Nat.is_eq(List.length(&2, Ty.HCoedge, hcs), 1n),
        Nat.is_eq(Op.hcs_ndeg(hcs, x), 1n))) : Bool}

law l1_last_nil:
  for d: Ty.HCoedge
  {Op.hc_last(Nil{}, d) == d : Ty.HCoedge}

law l1_link_open:
  for b: Ty.Brep
  for fuel: Nat
  {Op.brep_link_c(b, Ty.P_open_shell{}, fuel) == 3n : Nat}

law l1_cov_nil:
  for i: Nat
  for cls: List<&2, Op.CL>
  {Op.cov_go(Nil{}, i, cls) == True{} : Bool}

law l1_start_nil:
  for x: Ty.Ix
  for i: Nat
  {Op.svs_of(Nil{}, x, i) == Nil{} : List<&2, Op.SV>}

law l1_have_nil:
  for x: Ty.Ix
  for p: U32
  for acc: List<&2, Op.EP>
  {Op.hcs_ekeys(Nil{}, x, p, acc) == acc : List<&2, Op.EP>}

law l1_share_nil:
  for x: Ty.Ix
  {Op.sh_adj(Nil{}, x) == Nil{} : List<&2, B.Ed>}

law l1_hls_nil:
  for x: Ty.Ix
  for p: U32
  for acc: List<&2, Op.EP>
  {Op.hls_ekeys(Nil{}, x, p, acc) == acc : List<&2, Op.EP>}

law l1_hlps_nil:
  for x: Ty.Ix
  for p: U32
  {Op.hfs_ekeys(Nil{}, x, p) == Nil{} : List<&2, Op.EP>}

law l1_conn_nil:
  for x: Ty.Ix
  {Op.sh_conn_ok(Nil{}, x) == True{} : Bool}

law l1_conn_rule:
  for ok: Bool
  for ps: List<&2, U32>
  {Op.cc_conn(B.CC{ok, ps}) == Bool.and(ok, Op.all_zero(ps)) : Bool}

law l1_line_ln:
  for w: G.Line3
  {Op.gval_is_line(G.GV_ln{w}) == True{} : Bool}

law l1_line_cc:
  for w: G.Circle3
  {Op.gval_is_line(G.GV_cc{w}) == False{} : Bool}

law l1_line_bz:
  for w: G.Bez3
  {Op.gval_is_line(G.GV_bz{w}) == False{} : Bool}

law l1_line_rq:
  for w: G.RQBez
  {Op.gval_is_line(G.GV_rq{w}) == False{} : Bool}

law l1_line_nb:
  for w: G.Nurb
  {Op.gval_is_line(G.GV_nb{w}) == False{} : Bool}

law l1_line_pl:
  for w: G.Plane3
  {Op.gval_is_line(G.GV_pl{w}) == False{} : Bool}

law l1_ekind_curve:
  for c: G.GVal
  for d: G.Dom
  {Op.ekind_is_line(Ty.EK_curve{c, d})
    == Op.gval_is_line(c) : Bool}

law l1_edge_line:
  for g: U64
  for v0: Ty.HVertex
  for v1: Ty.HVertex
  for k: Ty.EdgeKind
  {Op.edge_is_line(Ty.Ed{g, v0, v1, k})
    == Op.ekind_is_line(k) : Bool}

law l1_lines_nil:
  for x: Ty.Ix
  {Op.hcs_all_lines(Nil{}, x) == True{} : Bool}

law l1_lines_cons:
  for h: Ty.HCoedge
  for t: List<&2, Ty.HCoedge>
  for +x: Ty.Ix
  {Op.hcs_all_lines(h <> t, x)
    == Bool.and(Op.edge_is_line(Ty.tres_ed(Ty.ix_ed(x,
      Ty.ce_edge(Ty.tres_ce(Ty.ix_ce(x, h)))))),
      Op.hcs_all_lines(t, x)) : Bool}

law l1_plane_pos:
  for w: G.Plane3
  {Op.surf_is_plane(G.GV_pl{w}) == True{} : Bool}

law l1_plane_cy:
  for w: G.Cyl
  {Op.surf_is_plane(G.GV_cy{w}) == False{} : Bool}

law l1_plane_co:
  for w: G.Cone
  {Op.surf_is_plane(G.GV_co{w}) == False{} : Bool}

law l1_plane_sp:
  for w: G.Sphere
  {Op.surf_is_plane(G.GV_sp{w}) == False{} : Bool}

law l1_plane_to:
  for w: G.Torus
  {Op.surf_is_plane(G.GV_to{w}) == False{} : Bool}

law l1_plane_bp:
  for w: G.BezP
  {Op.surf_is_plane(G.GV_bp{w}) == False{} : Bool}

law l1_varying_nofail:
  for +s: G.GVal
  for hcs: List<&2, Ty.HCoedge>
  for x: Ty.Ix
  for same: Bool
  for kind: Ty.LoopKind
  {Bool.or(Op.surf_is_plane(s),
    Bool.not(Nat.is_eq(Op.loop_orient_class(hcs, x, s, same, kind),
      2n))) == True{} : Bool}

law l1_plnorm_unsupported:
  for s: G.GVal
  {Bool.or(Op.surf_is_plane(s),
    Bool.not(G.gres_ok(Op.plane_normal_of(s))))
    == True{} : Bool}

law l1_orient_c_spec:
  for +hcs: List<&2, Ty.HCoedge>
  for +x: Ty.Ix
  for +surf: G.GVal
  for +same: Bool
  for +kind: Ty.LoopKind
  {Op.loop_orient_c(hcs, x, surf, same, kind)
    == Ty.okd_pack(Bool.not(Nat.is_eq(Op.loop_orient_class(hcs, x,
      surf, same, kind), 2n)), True{}) : Nat}

law l1_oct_hls_nil:
  for x: Ty.Ix
  for surf: G.GVal
  for same: Bool
  for o: Op.OCt
  {Op.hls_oct(Nil{}, x, surf, same, o) == o : Op.OCt}

law l1_oct_skip:
  for bad: Bool
  for cert: Nat
  for skip: Nat
  {Op.oct_add(Op.OCt{bad, cert, skip}, 0n)
    == Op.OCt{Bool.or(bad, False{}), Nat.add(cert, 0n),
      Nat.add(skip, 1n)} : Op.OCt}

law l1_oct_fas_nil:
  for x: Ty.Ix
  for o: Op.OCt
  {Op.fas_oct(Nil{}, x, o) == o : Op.OCt}

law l1_oct_bad:
  for bad: Bool
  for cert: Nat
  for skip: Nat
  {Op.oct_add(Op.OCt{bad, cert, skip}, 2n)
    == Op.OCt{Bool.or(bad, True{}), Nat.add(cert, 1n),
      Nat.add(skip, 0n)} : Op.OCt}

law l1_cnt_false:
  for n: Nat
  {Op.cnt_pack(n, False{}) == 0n : Nat}

def accepted_or(r: Ty.TRes, +d: Ty.Brep) -> Ty.Brep:
  match r:
    case Ty.Tok{v}:
      match v:
        case Ty.T_brep{w}: w
        case _: d
    case Ty.Terr{kind}: d

law checked_returns_input:
  for +b: Ty.Brep
  for +prof: Ty.Profile
  for +fuel: Nat
  {accepted_or(Op.brep_checked(b, prof, fuel), b) == b : Ty.Brep}
