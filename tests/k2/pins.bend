import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/k1/sf.bend as KS
import ../../src/k2/fit.bend as F
import ../../src/k2/thr.bend as KT
import ../../src/k2/kgap.bend as KG

def near(+a: F64, +b: F64, +tol: F64) -> Bool:
  F64.is_le(F64.abs(F64.sub(a, b)), tol)

def lim_is(+v: V.Vec2, +lo: F64, +hi: F64) -> Bool:
  Bool.and(near(V.v2_x(v), lo, 1.0e-12f64), near(V.v2_y(v), hi, 1.0e-12f64))

def win_of(+cls: String, +d: String) -> V.Vec2:
  +ds = KT.desig(d)
  KT.win(KT.cls_code(cls), ds, KT.pr_or(KT.pr_find(KT.pitches(), KT.ds_p(ds))))

def win_is(+v: V.Vec2, +lo: F64, +hi: F64) -> Bool:
  Bool.and(near(V.v2_x(v), lo, 5.0e-4f64), near(V.v2_y(v), hi, 5.0e-4f64))

def di_has(+d: KG.DI, +x: F64, +w: F64) -> Bool:
  KG.DI{+lo, +hi} = d
  Bool.and(Bool.and(F64.is_le(lo, x), F64.is_le(x, hi)), F64.is_le(F64.sub(hi, lo), w))

def seg(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> KG.TR:
  KG.TR{1u64, ax, ay, bx, by, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 10.0f64, True{}}

def circ(+cx: F64, +cy: F64, +r: F64) -> KG.TR:
  KG.TR{2u64, cx, cy, 0.0f64, 0.0f64, r, 0.0f64, KS.two_pi(), 0.0f64, 10.0f64, True{}}

def h7_at_20__got() -> Bool:
  lim_is(F.hole_lim("H", 7n, 20.0f64), 20.0f64, 20.021f64)

def h7_at_20__want() -> Bool:
  True{}

def g6_at_20__got() -> Bool:
  lim_is(F.shaft_lim("g", 6n, 20.0f64), 19.980f64, 19.993f64)

def g6_at_20__want() -> Bool:
  True{}

def p6_at_20__got() -> Bool:
  lim_is(F.shaft_lim("p", 6n, 20.0f64), 20.022f64, 20.035f64)

def p6_at_20__want() -> Bool:
  True{}

def k6_at_20__got() -> Bool:
  lim_is(F.shaft_lim("k", 6n, 20.0f64), 20.002f64, 20.015f64)

def k6_at_20__want() -> Bool:
  True{}

def k8_at_20_has_zero_deviation__got() -> Bool:
  lim_is(F.shaft_lim("k", 8n, 20.0f64), 20.0f64, 20.033f64)

def k8_at_20_has_zero_deviation__want() -> Bool:
  True{}

def js6_at_20__got() -> Bool:
  lim_is(F.shaft_lim("js", 6n, 20.0f64), 19.9935f64, 20.0065f64)

def js6_at_20__want() -> Bool:
  True{}

def f8_hole_at_20__got() -> Bool:
  lim_is(F.hole_lim("F", 8n, 20.0f64), 20.020f64, 20.053f64)

def f8_hole_at_20__want() -> Bool:
  True{}

def d9_at_50__got() -> Bool:
  lim_is(F.shaft_lim("d", 9n, 50.0f64), 49.858f64, 49.920f64)

def d9_at_50__want() -> Bool:
  True{}

def r6_at_65_uses_subrange__got() -> Bool:
  lim_is(F.shaft_lim("r", 6n, 65.0f64), 65.041f64, 65.060f64)

def r6_at_65_uses_subrange__want() -> Bool:
  True{}

def s7_at_100__got() -> Bool:
  lim_is(F.shaft_lim("s", 7n, 100.0f64), 100.071f64, 100.106f64)

def s7_at_100__want() -> Bool:
  True{}

def h7_range_top_is_inclusive__got() -> Bool:
  Bool.and(lim_is(F.hole_lim("H", 7n, 30.0f64), 30.0f64, 30.021f64), lim_is(F.hole_lim("H", 7n, 30.5f64), 30.5f64, 30.525f64))

def h7_range_top_is_inclusive__want() -> Bool:
  True{}

def m8_coarse_pitch__got() -> F64:
  KT.coarse_p(KT.coarse(), 8.0f64)

def m8_coarse_pitch__want() -> F64:
  1.25f64

def m8_6h_minor_window__got() -> Bool:
  win_is(win_of("6H", "M8x1.25"), 6.647f64, 6.912f64)

def m8_6h_minor_window__want() -> Bool:
  True{}

def m6_6h_minor_window__got() -> Bool:
  win_is(win_of("6H", "M6"), 4.917f64, 5.153f64)

def m6_6h_minor_window__want() -> Bool:
  True{}

def m10_7h_minor_window__got() -> Bool:
  win_is(win_of("7H", "M10"), 8.376f64, 8.751f64)

def m10_7h_minor_window__want() -> Bool:
  True{}

def m8_6g_major_window__got() -> Bool:
  win_is(win_of("6g", "M8"), 7.760f64, 7.972f64)

def m8_6g_major_window__want() -> Bool:
  True{}

def m20x1_5_6e_major_window__got() -> Bool:
  win_is(win_of("6e", "M20x1.5"), 19.697f64, 19.933f64)

def m20x1_5_6e_major_window__want() -> Bool:
  True{}

def point_to_segment__got() -> Bool:
  di_has(KG.pt_seg(0.0f64, 1.0f64, F64.neg(1.0f64), 0.0f64, 1.0f64, 0.0f64), 1.0f64, 1.0e-10f64)

def point_to_segment__want() -> Bool:
  True{}

def crossing_segments_touch__got() -> F64:
  KG.di_lo(KG.seg_seg(seg(F64.neg(1.0f64), 0.0f64, 1.0f64, 0.0f64), seg(0.0f64, F64.neg(1.0f64), 0.0f64, 1.0f64)))

def crossing_segments_touch__want() -> F64:
  0.0f64

def concentric_circles_gap__got() -> Bool:
  di_has(KG.arc_arc(circ(0.0f64, 0.0f64, 10.0f64), circ(0.0f64, 0.0f64, 10.04f64)), 0.04f64, 1.0e-9f64)

def concentric_circles_gap__want() -> Bool:
  True{}

def prefilter_keeps_nearest__got() -> Bool:
  di_has(KG.d_all([seg(0.0f64, 0.0f64, 1.0f64, 0.0f64), seg(100.0f64, 0.0f64, 101.0f64, 0.0f64)],
    [seg(0.0f64, 0.25f64, 1.0f64, 0.25f64), seg(50.0f64, 5.0f64, 51.0f64, 5.0f64)], KG.DI{KG.inf(), KG.inf()}), 0.25f64, 1.0e-10f64)

def prefilter_keeps_nearest__want() -> Bool:
  True{}

def rotating_circles_mesh__got() -> Bool:
  +g = KG.mg_of([circ(0.0f64, 0.0f64, 10.0f64)], [circ(20.05f64, 0.0f64, 10.0f64)], 1.0f64,
    V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{20.05f64, 0.0f64, 0.0f64})
  di_has(KG.mesh_d(g, 11.0f64), 0.05f64, 1.0e-6f64)

def rotating_circles_mesh__want() -> Bool:
  True{}

def elevated_line_is_straight__got() -> Bool:
  KG.bz_line(G.GV_bz{G.Bz{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{1.0f64, 2.0f64, 0.0f64}, V.Pt{2.0f64, 4.0f64, 0.0f64}, V.Pt{3.0f64, 6.0f64, 0.0f64}}})

def elevated_line_is_straight__want() -> Bool:
  True{}

def bowed_bezier_is_curved__got() -> Bool:
  KG.bz_line(G.GV_bz{G.Bz{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{1.0f64, 2.0001f64, 0.0f64}, V.Pt{2.0f64, 4.0f64, 0.0f64}, V.Pt{3.0f64, 6.0f64, 0.0f64}}})

def bowed_bezier_is_curved__want() -> Bool:
  False{}
