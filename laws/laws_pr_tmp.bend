# C06 laws: intent-checked solid builders over C00-C05.
# Contract: docs/c06-contract.md. Convention: laws/c05.bend
# (ground pins ok_/neg_ plus quantified definitional laws).

import Base
import ../src/c00/types.bend as T
import ../src/c01/types.bend as V
import ../src/c03/types.bend as G
import ../src/c04/types.bend as Ty
import ../src/c06/types.bend as Y
import ../src/c06/ops.bend as O
import ../src/c06/eval.bend as EV
import ../src/c06/surfx.bend as SX

def unit_box() -> Ty.Brep:
  O.box_core(0.0f64, 0.0f64, 0.0f64, 1.0f64, 2.0f64, 3.0f64)

def id_rigid() -> V.Rigid:
  V.Rg{V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64},
    0.0f64, 0.0f64, 0.0f64}

def org() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def axis_z() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}


# --- P. Result-protocol gap pins (extends A/B/O). ---

law intent_proj_fm:
  for m: Y.MatFx
  for fc: Nat
  for fm: Nat
  for sh: Nat
  for ho: Nat
  {Y.intent_fm(Y.mk_intent(m, fc, fm, sh, ho)) == fm : Nat}

def intent_proj_fm(m, fc, fm, sh, ho):
  {==}

law intent_proj_shells:
  for m: Y.MatFx
  for fc: Nat
  for fm: Nat
  for sh: Nat
  for ho: Nat
  {Y.intent_shells(Y.mk_intent(m, fc, fm, sh, ho)) == sh : Nat}

def intent_proj_shells(m, fc, fm, sh, ho):
  {==}

law matfx_tag_create:
  {Y.matfx_tag(Y.M_create{}) == 0u64 : U64}

def matfx_tag_create():
  {==}

law matfx_tag_add:
  {Y.matfx_tag(Y.M_add{}) == 1u64 : U64}

def matfx_tag_add():
  {==}

law matfx_tag_remove:
  {Y.matfx_tag(Y.M_remove{}) == 2u64 : U64}

def matfx_tag_remove():
  {==}

law matfx_tag_same:
  {Y.matfx_tag(Y.M_same{}) == 3u64 : U64}

def matfx_tag_same():
  {==}

law sok_iv_rt:
  for v: Y.Iv
  {Y.sok_iv_of(Y.sok_iv(v)) == v : Y.Iv}

def sok_iv_rt(v):
  {==}

law sok_s_rt:
  for s: String
  {Y.sok_s_of(Y.sok_s(s)) == s : String}

def sok_s_rt(s):
  {==}

law sok_fx_rt:
  for e: Y.Effect
  {Y.sok_fx_of(Y.sok_fx(e)) == e : Y.Effect}

def sok_fx_rt(e):
  {==}

law sok_body_rt:
  for b: Y.Body
  {Y.sok_body_of(Y.sok_body(b)) == b : Y.Body}

def sok_body_rt(b):
  {==}

law sok_part_rt:
  for p: Y.Part
  {Y.sok_part_of(Y.sok_part(p)) == p : Y.Part}

def sok_part_rt(p):
  {==}

law sok_ms_rt:
  for m: Y.Measure
  {Y.sok_ms_of(Y.sok_ms(m)) == m : Y.Measure}

def sok_ms_rt(m):
  {==}

law sok_iv_wrong_arm:
  for u: U64
  {Y.sok_iv_of(Y.sok_u(u)) == Y.Iv{0.0f64, 0.0f64} : Y.Iv}

def sok_iv_wrong_arm(u):
  {==}

law sok_s_wrong_arm:
  for u: U64
  {Y.sok_s_of(Y.sok_u(u)) == "" : String}

def sok_s_wrong_arm(u):
  {==}

law sok_fx_wrong_arm:
  {Y.sok_fx_of(Y.sok_u(5u64)) == Y.mk_fx(Y.M_same{}, 0n, 0n, 0n, 0n) : Y.Effect}

def sok_fx_wrong_arm():
  {==}

law sok_ms_wrong_arm:
  {Y.sok_ms_of(Y.sok_u(5u64))
    == Y.mk_ms(Y.Iv{0.0f64, 0.0f64}, Y.Iv{0.0f64, 0.0f64},
      V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64},
      0n, 0n, 0n) : Y.Measure}

def sok_ms_wrong_arm():
  {==}

law sok_part_wrong_arm:
  {Y.sok_part_of(Y.sok_u(5u64)) == Y.part_empty() : Y.Part}

def sok_part_wrong_arm():
  {==}

law sok_body_wrong_arm:
  {Y.sok_body_of(Y.sok_u(5u64)) == Y.sok_def_body() : Y.Body}

def sok_body_wrong_arm():
  {==}

law serr_kind_keep:
  for k: T.FailKind
  {Y.sres_kind(Y.serr(k, Y.diag_null())) == k : T.FailKind}

def serr_kind_keep(k):
  {==}

law ms_vol_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_vol(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == v : Y.Iv}

def ms_vol_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_area_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_area(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == a : Y.Iv}

def ms_area_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_blo_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_blo(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == lo : V.Point}

def ms_blo_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_bhi_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_bhi(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == hi : V.Point}

def ms_bhi_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_nv_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_nv(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == nv : Nat}

def ms_nv_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_ne_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_ne(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == ne : Nat}

def ms_ne_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ms_nf_proj:
  for v: Y.Iv
  for a: Y.Iv
  for lo: V.Point
  for hi: V.Point
  for nv: Nat
  for ne: Nat
  for nf: Nat
  {Y.ms_nf(Y.mk_ms(v, a, lo, hi, nv, ne, nf)) == nf : Nat}

def ms_nf_proj(v, a, lo, hi, nv, ne, nf):
  {==}

law ok_kind_tag_cyl:
  {SX.surf_kind_tag(G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}) == 2u64 : U64}

def ok_kind_tag_cyl():
  {==}

law ok_kind_tag_sph:
  {SX.surf_kind_tag(G.GV_sp{G.Sp{org(), 2.0f64}}) == 5u64 : U64}

def ok_kind_tag_sph():
  {==}

law neg_kind_tag_f:
  {SX.surf_kind_tag(G.GV_f{1.0f64}) == 99u64 : U64}

def neg_kind_tag_f():
  {==}

law ok_kind_show_cyl:
  {SX.surf_kind_show(G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}) == "cyl" : String}

def ok_kind_show_cyl():
  {==}

law ok_kind_show_sph:
  {SX.surf_kind_show(G.GV_sp{G.Sp{org(), 2.0f64}}) == "sphere" : String}

def ok_kind_show_sph():
  {==}

law neg_kind_show_f:
  {SX.surf_kind_show(G.GV_f{1.0f64}) == "other" : String}

def neg_kind_show_f():
  {==}

# --- R. C06 quad-trim check. ---

def trim_cyl() -> G.GVal:
  G.GV_cy{G.Cy{org(), axis_z(), 1.0f64}}

def trim_cone() -> G.GVal:
  G.GV_co{G.Co{org(), axis_z(), 1.0f64}}

def trim_tor() -> G.GVal:
  G.GV_to{G.To{org(), axis_z(), 5.0f64, 1.0f64}}

def trim_sph() -> G.GVal:
  G.GV_sp{G.Sp{org(), 2.0f64}}

def trim_wide() -> G.GVal:
  G.GV_cy{G.Cy{org(), V.Dr{0.0f64, 0.0f64, 10.0f64}, 1.0f64}}

law ok_trim_quad_cyl:
  {Y.sok_u_of(O.trim_quad(trim_cyl(), 0.0f64, 0.0f64)) == 0u64 : U64}

def ok_trim_quad_cyl():
  {==}

law ok_trim_quad_cone:
  {Y.sok_u_of(O.trim_quad(trim_cone(), 0.0f64, 2.0f64)) == 0u64 : U64}

def ok_trim_quad_cone():
  {==}

law ok_trim_quad_tor:
  {Y.sok_u_of(O.trim_quad(trim_tor(), 0.0f64, 0.0f64)) == 0u64 : U64}

def ok_trim_quad_tor():
  {==}

law ok_trim_quad_sph:
  {Y.sok_u_of(O.trim_quad(trim_sph(), 1.0f64, 0.0f64)) == 0u64 : U64}

def ok_trim_quad_sph():
  {==}

law neg_trim_quad_t:
  {Y.sres_show(O.trim_quad(trim_cyl(), 2.0f64, 0.0f64))
    == "invalid-input" : String}

def neg_trim_quad_t():
  {==}

law neg_trim_quad_r:
  {Y.sres_show(O.trim_quad(G.GV_cy{G.Cy{org(), axis_z(), 0.0f64}}, 0.0f64,
    0.0f64)) == "invalid-input" : String}

def neg_trim_quad_r():
  {==}

law neg_trim_quad_spindle:
  {Y.sres_show(O.trim_quad(G.GV_to{G.To{org(), axis_z(), 1.0f64, 5.0f64}},
    0.0f64, 0.0f64)) == "invalid-input" : String}

def neg_trim_quad_spindle():
  {==}

law neg_trim_quad_cone_h:
  {Y.sres_show(O.trim_quad(trim_cone(), 0.0f64, F64.neg(2.0f64)))
    == "invalid-input" : String}

def neg_trim_quad_cone_h():
  {==}

law neg_trim_quad_other:
  {Y.sres_show(O.trim_quad(G.GV_f{1.0f64}, 0.0f64, 0.0f64))
    == "invalid-input" : String}

def neg_trim_quad_other():
  {==}

law diag_trim_quad_other:
  {Y.diag_show(Y.sres_diag(O.trim_quad(G.GV_f{1.0f64}, 0.0f64, 0.0f64)))
    == "surface @ trim_quad [not-quad] fix: route plane/bezier trims through the C04 stages" : String}

def diag_trim_quad_other():
  {==}

law neg_trim_quad_huge:
  {Y.sres_show(O.trim_quad(trim_cyl(), 0.0f64, F64{9218868437227405312u64}))
    == "invalid-input" : String}

def neg_trim_quad_huge():
  {==}

law neg_trim_quad_over:
  {Y.sres_show(O.trim_quad(trim_wide(), 0.0f64, 1.0e308f64))
    == "numerical-uncertainty" : String}

def neg_trim_quad_over():
  {==}

law neg_trim_quad_map_ex:
  {Y.sres_show(O.trim_quad_map(G.gerr(T.F_exhausted{})))
    == "resource-exhausted" : String}

def neg_trim_quad_map_ex():
  {==}

law neg_trim_quad_map_nc:
  {Y.sres_show(O.trim_quad_map(G.gerr(T.F_nonconverged{})))
    == "nonconvergence" : String}

def neg_trim_quad_map_nc():
  {==}

law ok_trim_quad_fin:
  {Y.sok_u_of(O.trim_quad_fin(True{}, True{}, True{})) == 0u64 : U64}

def ok_trim_quad_fin():
  {==}

law neg_trim_quad_fin_x:
  {Y.sres_show(O.trim_quad_fin(False{}, True{}, True{}))
    == "numerical-uncertainty" : String}

def neg_trim_quad_fin_x():
  {==}

law neg_trim_quad_pt_huge:
  {Y.sres_show(O.trim_quad_pt(V.Pt{F64{9218868437227405312u64}, 0.0f64,
    0.0f64})) == "numerical-uncertainty" : String}

def neg_trim_quad_pt_huge():
  {==}

