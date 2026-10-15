import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty
import ../c06/xp.bend as X
import ../c06/prof.bend as F
import ../c06/build.bend as BD
import ../c06/revolve.bend as RV
import ../c06/iv.bend as I
import ../base/num.bend as N
import ../c09/feat.bend as F9

type GR is Data:
  GR_ok{}
  GR_no{ why: String, fix: String }
type LO is Data:
  LO{ z: F64, x0: F64, y0: F64, x1: F64, y1: F64, u0: F64, v0: F64, u1: F64, v1: F64 }
type SWO is Data:
  SWO{ deg: U64, r0: F64, r1: F64, z0: F64, z1: F64 }
type QD is Data:
  Q1{}
  Q2{}
  Q3{}
type PP is Data:
  PP{ p00: V.Point, p01: V.Point, p02: V.Point, p03: V.Point, p10: V.Point, p11: V.Point,
    p12: V.Point, p13: V.Point, p20: V.Point, p21: V.Point, p22: V.Point, p23: V.Point,
    p30: V.Point, p31: V.Point, p32: V.Point, p33: V.Point }
type RT is Data:
  RT{ r0: F64, r1: F64, z0: F64, z1: F64, ok: Bool }
type SO is Data:
  SO_lo{ z: X.Xp, bot: F.Region, top: F.Region, tw: U64, cont: U64 }
  SO_sw{ deg: U64, rs: List<&2, F.Region>, g: U64, gd: U64, tw: U64 }
  SO_pt{ ps: List<&2, X.Xp> }
  SO_bad{}
type BE is Data:
  BE{ eid: Nat, lo: F64, hi: F64, cert: Bool }
type BR is Data:
  BR{ i: Nat, eid: Nat, lo: F64, hi: F64, cert: Bool }
type DD is Data:
  DD{ ox0: F64, oy0: F64, ox1: F64, oy1: F64, ou0: F64, ov0: F64, ou1: F64, ov1: F64,
    ix0: F64, iy0: F64, ix1: F64, iy1: F64, iu0: F64, iv0: F64, iu1: F64, iv1: F64, z: F64 }
type SD is Data:
  SD{ r0o: F64, r1o: F64, z0o: F64, z1o: F64, r0i: F64, r1i: F64, z0i: F64, z1i: F64 }
def lo_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"loft-open-not-planar", "loft-open axis-aligned rect pairs with planar walls"}
    case True{}: GR_ok{}
def sa_go(+ok: Bool, +deg: U64) -> GR:
  match ok:
    case False{}: GR_no{"sweep-angle-not-certified", "sweep-open 90, 180 or 270 degrees"}
    case True{}: GR_ok{}
def sp_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"sweep-profile-not-admitted", "sweep-open one axis-aligned rect profile off the axis"}
    case True{}: GR_ok{}
def pa_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"patch-degenerate", "give 16 finite control points with distinct rows, columns and corners"}
    case True{}: GR_ok{}
def tc_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"thicken-curvature-not-certified", "thicken rect patches, rect ducts and rect sectors only"}
    case True{}: GR_ok{}
def ts_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"thicken-consumes-shell", "keep wall thickness below the shell minimum"}
    case True{}: GR_ok{}
def su_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"surf-needs-open-shell", "run surf on a loft-open, sweep-open or patch node"}
    case True{}: GR_ok{}
def th_go(+ok: Bool) -> GR:
  match ok:
    case False{}: GR_no{"thicken-needs-open-shell", "thicken-open an open-shell node"}
    case True{}: GR_ok{}
def dg_go(+ok: Bool, +t: F64) -> GR:
  match ok:
    case False{}: GR_no{"degenerate-feature", "give finite positive wall thickness"}
    case True{}: GR_ok{}
def gr_ok(+g: GR) -> Bool:
  match g:
    case GR_ok{}: True{}
    case GR_no{+why, +fix}: False{}
def gr_why(+g: GR) -> String:
  match g:
    case GR_ok{}: ""
    case GR_no{+why, +fix}: why
def gr_fix(+g: GR) -> String:
  match g:
    case GR_ok{}: ""
    case GR_no{+why, +fix}: fix
def ck_pick(+g: GR, +n: GR) -> GR:
  match g:
    case GR_ok{}: n
    case GR_no{+why, +fix}: g
def swo_deg_ok(+deg: U64) -> Bool:
  match deg:
    case 90u64: True{}
    case 180u64: True{}
    case 270u64: True{}
    case _: False{}
def qd_of(+deg: U64) -> QD:
  match deg:
    case 90u64: Q1{}
    case 180u64: Q2{}
    case 270u64: Q3{}
    case _: Q1{}
def qd_n(+q: QD) -> Nat:
  match q:
    case Q1{}: 1n
    case Q2{}: 2n
    case Q3{}: 3n
def qd_deg(+q: QD) -> U64:
  match q:
    case Q1{}: 90u64
    case Q2{}: 180u64
    case Q3{}: 270u64
def ptx(+p: V.Point) -> F64:
  V.Pt{+x, +y, +z} = p
  x
def pty(+p: V.Point) -> F64:
  V.Pt{+x, +y, +z} = p
  y
def ptz(+p: V.Point) -> F64:
  V.Pt{+x, +y, +z} = p
  z
def pt(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}
def psub(+a: V.Point, +b: V.Point) -> V.Dir:
  V.Dr{F64.sub(ptx(a), ptx(b)), F64.sub(pty(a), pty(b)), F64.sub(ptz(a), ptz(b))}
def drx(+d: V.Dir) -> F64:
  V.Dr{+x, +y, +z} = d
  x
def dry(+d: V.Dir) -> F64:
  V.Dr{+x, +y, +z} = d
  y
def drz(+d: V.Dir) -> F64:
  V.Dr{+x, +y, +z} = d
  z
def padr(+p: V.Point, +d: V.Dir) -> V.Point:
  pt(F64.add(ptx(p), drx(d)), F64.add(pty(p), dry(d)), F64.add(ptz(p), drz(d)))
def dmul(+d: V.Dir, +k: F64) -> V.Dir:
  V.Dr{F64.mul(drx(d), k), F64.mul(dry(d), k), F64.mul(drz(d), k)}
def pdd(+a: V.Point, +b: V.Point) -> V.Dir:
  psub(a, b)
def pcross(+a: V.Dir, +b: V.Dir) -> V.Dir:
  V.Dr{F64.sub(F64.mul(dry(a), drz(b)), F64.mul(drz(a), dry(b))),
    F64.sub(F64.mul(drz(a), drx(b)), F64.mul(drx(a), drz(b))),
    F64.sub(F64.mul(drx(a), dry(b)), F64.mul(dry(a), drx(b)))}
def pdot(+a: V.Dir, +b: V.Dir) -> F64:
  F64.add(F64.add(F64.mul(drx(a), drx(b)), F64.mul(dry(a), dry(b))), F64.mul(drz(a), drz(b)))
def dnorm2(+d: V.Dir) -> F64:
  pdot(d, d)
def dnorm(+d: V.Dir) -> F64:
  F64.sqrt(dnorm2(d))
def dunit(+d: V.Dir) -> V.Dir:
  dmul(d, F64.div(1.0f64, dnorm(d)))
def plerp(+a: V.Point, +b: V.Point, +t: F64) -> V.Point:
  pt(F64.add(ptx(a), F64.mul(t, F64.sub(ptx(b), ptx(a)))),
    F64.add(pty(a), F64.mul(t, F64.sub(pty(b), pty(a)))),
    F64.add(ptz(a), F64.mul(t, F64.sub(ptz(b), ptz(a)))))
def pbeq(+a: V.Point, +b: V.Point) -> Bool:
  Bool.and(U64.is_eq(F64.bits(ptx(a)), F64.bits(ptx(b))),
    Bool.and(U64.is_eq(F64.bits(pty(a)), F64.bits(pty(b))), U64.is_eq(F64.bits(ptz(a)), F64.bits(ptz(b)))))
def pfin(+p: V.Point) -> Bool:
  Bool.and(T.is_finite(ptx(p)), Bool.and(T.is_finite(pty(p)), T.is_finite(ptz(p))))
def fin_pp(+p: PP) -> Bool:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  Bool.and(pfin(p00), Bool.and(pfin(p01), Bool.and(pfin(p02), Bool.and(pfin(p03),
    Bool.and(pfin(p10), Bool.and(pfin(p11), Bool.and(pfin(p12), Bool.and(pfin(p13),
      Bool.and(pfin(p20), Bool.and(pfin(p21), Bool.and(pfin(p22), Bool.and(pfin(p23),
        Bool.and(pfin(p30), Bool.and(pfin(p31), Bool.and(pfin(p32), pfin(p33))))))))))))))))
def row_eq(+a0: V.Point, +a1: V.Point, +a2: V.Point, +a3: V.Point, +b0: V.Point, +b1: V.Point,
    +b2: V.Point, +b3: V.Point) -> Bool:
  Bool.and(pbeq(a0, b0), Bool.and(pbeq(a1, b1), Bool.and(pbeq(a2, b2), pbeq(a3, b3))))
def rows_distinct(+p: PP) -> Bool:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  Bool.not(Bool.or(row_eq(p00, p01, p02, p03, p10, p11, p12, p13),
    Bool.or(row_eq(p00, p01, p02, p03, p20, p21, p22, p23),
      Bool.or(row_eq(p00, p01, p02, p03, p30, p31, p32, p33),
        Bool.or(row_eq(p10, p11, p12, p13, p20, p21, p22, p23),
          Bool.or(row_eq(p10, p11, p12, p13, p30, p31, p32, p33),
            row_eq(p20, p21, p22, p23, p30, p31, p32, p33)))))))
def cols_distinct(+p: PP) -> Bool:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  Bool.not(Bool.or(row_eq(p00, p10, p20, p30, p01, p11, p21, p31),
    Bool.or(row_eq(p00, p10, p20, p30, p02, p12, p22, p32),
      Bool.or(row_eq(p00, p10, p20, p30, p03, p13, p23, p33),
        Bool.or(row_eq(p01, p11, p21, p31, p02, p12, p22, p32),
          Bool.or(row_eq(p01, p11, p21, p31, p03, p13, p23, p33),
            row_eq(p02, p12, p22, p32, p03, p13, p23, p33)))))))
def corns_distinct(+p: PP) -> Bool:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  Bool.not(Bool.or(pbeq(p00, p03),
    Bool.or(pbeq(p00, p33), Bool.or(pbeq(p00, p30),
      Bool.or(pbeq(p03, p33), Bool.or(pbeq(p03, p30), pbeq(p33, p30)))))))
def pa_ok(+p: PP) -> Bool:
  Bool.and(fin_pp(p), Bool.and(rows_distinct(p), Bool.and(cols_distinct(p), corns_distinct(p))))
def colin(+a: V.Point, +b: V.Point, +c: V.Point) -> Bool:
  +n = pcross(psub(b, a), psub(c, a))
  Bool.and(F64.is_eq(drx(n), 0.0f64), Bool.and(F64.is_eq(dry(n), 0.0f64), F64.is_eq(drz(n), 0.0f64)))
def row_straight(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> Bool:
  Bool.and(colin(a, b, d), colin(a, c, d))
def pp_straight(+p: PP) -> Bool:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  Bool.and(row_straight(p00, p01, p02, p03),
    Bool.and(row_straight(p10, p11, p12, p13),
      Bool.and(row_straight(p20, p21, p22, p23),
        Bool.and(row_straight(p30, p31, p32, p33),
          Bool.and(row_straight(p00, p10, p20, p30),
            Bool.and(row_straight(p01, p11, p21, p31),
              Bool.and(row_straight(p02, p12, p22, p32), row_straight(p03, p13, p23, p33))))))))
def mid2_eq(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> Bool:
  Bool.and(F64.is_eq(F64.add(ptx(a), ptx(b)), F64.add(ptx(c), ptx(d))),
    Bool.and(F64.is_eq(F64.add(pty(a), pty(b)), F64.add(pty(c), pty(d))),
      F64.is_eq(F64.add(ptz(a), ptz(b)), F64.add(ptz(c), ptz(d)))))
def corn_rect(+p: PP) -> Bool:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  +d0 = dnorm2(psub(p00, p33))
  +d1 = dnorm2(psub(p03, p30))
  Bool.and(mid2_eq(p00, p33, p03, p30),
    Bool.and(F64.is_eq(d0, d1), F64.is_lt(0.0f64, d0)))
def rect_slab_ok(+p: PP) -> Bool:
  Bool.and(corn_rect(p), pp_straight(p))
def xps_ev(xs: List<&2, X.Xp>, +e: X.Env) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> t: X.xp_ev(x, e) <> xps_ev(t, e)
def f_nth(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: 0.0f64
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: f_nth(t, j)
def fpt(+xs: List<&2, F64>, +i: Nat) -> V.Point:
  pt(f_nth(xs, i), f_nth(xs, Nat.add(i, 1n)), f_nth(xs, Nat.add(i, 2n)))
def pp_of(+xs: List<&2, F64>) -> PP:
  PP{fpt(xs, 0n), fpt(xs, 3n), fpt(xs, 6n), fpt(xs, 9n), fpt(xs, 12n), fpt(xs, 15n), fpt(xs, 18n),
    fpt(xs, 21n), fpt(xs, 24n), fpt(xs, 27n), fpt(xs, 30n), fpt(xs, 33n), fpt(xs, 36n), fpt(xs, 39n),
    fpt(xs, 42n), fpt(xs, 45n)}
def pp_ev(+ps: List<&2, X.Xp>, +e: X.Env) -> PP:
  pp_of(xps_ev(ps, e))
def rg_out(+r: F.Region) -> F.Loop:
  F.Rg{+o, +hs} = r
  o
def rg_has_h(+r: F.Region) -> Bool:
  F.Rg{+o, +hs} = r
  Bool.not(Nat.is_eq(List.length(&2, F.Loop, hs), 0n))
def ev_code(+ev: F.EV) -> U64:
  match ev:
    case F.EV_ok{ls}: 0u64
    case F.EV_err{e}:
      F.Er{+code, +lp, +sg} = e
      code
def lp0(+ls: List<&2, F.Lp>) -> F.Lp:
  match ls:
    case []: F.K_circ{0.0f64, 0.0f64, 1.0f64}
    case h <> t: h
def ev_lp(+ev: F.EV) -> F.Lp:
  match ev:
    case F.EV_ok{ls}: lp0(ls)
    case F.EV_err{e}: lp0([])
def lo_of_lf(+l: F9.LF, +zv: F64) -> LO:
  LO{zv, F9.lf_x0(l), F9.lf_y0(l), F9.lf_x1(l), F9.lf_y1(l), F9.lf_u0(l), F9.lf_v0(l), F9.lf_u1(l),
    F9.lf_v1(l)}
def lo_fr(+lo: LO, +nd: U64) -> F9.FR:
  LO{+z, +x0, +y0, +x1, +y1, +u0, +v0, +u1, +v1} = lo
  F9.FR{x0, y0, x1, y1, u0, v0, u1, v1, z, nd}
def v2(+x: F64, +y: F64) -> V.Vec2:
  V.V2{x, y}
def use_of(+e: Nat, +fwd: Bool, +ta: V.Vec2, +tb: V.Vec2) -> BD.Use:
  BD.Us{e, fwd, ta, tb}
def loft_wall_fs(+fr: F9.FR) -> List<&2, BD.FS>:
  F9.FR{+x0, +y0, +x1, +y1, +u0, +v0, +u1, +v1, +z, +nd} = fr
  +v0p = F9.fr_pt(0n, fr)
  +v1p = F9.fr_pt(1n, fr)
  +v2p = F9.fr_pt(2n, fr)
  +v3p = F9.fr_pt(3n, fr)
  +v4p = F9.fr_pt(4n, fr)
  +v5p = F9.fr_pt(5n, fr)
  +v6p = F9.fr_pt(6n, fr)
  +v7p = F9.fr_pt(7n, fr)
  [F9.face1(G.GV_bp{F9.bp_of(v0p, v1p, v5p, v4p)},
      [use_of(0n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)), use_of(9n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(4n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)), use_of(8n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 2n),
    F9.face1(G.GV_bp{F9.bp_of(v2p, v3p, v7p, v6p)},
      [use_of(2n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)), use_of(11n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(6n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)), use_of(10n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 3n),
    F9.face1(G.GV_bp{F9.bp_of(v3p, v0p, v4p, v7p)},
      [use_of(3n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)), use_of(8n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(7n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)), use_of(11n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 4n),
    F9.face1(G.GV_bp{F9.bp_of(v1p, v2p, v6p, v5p)},
      [use_of(1n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)), use_of(10n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(5n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)), use_of(9n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 5n)]
def loft_open_bt(+lo: LO, +nd: U64) -> BD.Bt:
  +fr = lo_fr(lo, nd)
  F9.pack(F9.fr_vs(8n, 0n, fr), F9.fr_es(12n, 0n, fr), loft_wall_fs(fr))
def pc_is_ln(+p: F.Pc) -> Bool:
  match p:
    case F.P_ln{+ax, +ay, +bx, +by}: True{}
    case F.P_ar{+ax, +ay, +px, +py, +w, +bx, +by}: False{}
def pc_axis_al(+p: F.Pc) -> Bool:
  Bool.or(F64.is_eq(F.pc_ax(p), F.pc_bx(p)), F64.is_eq(F.pc_ay(p), F.pc_by(p)))
def pcs_ln_al(ps: List<&2, F.Pc>) -> Bool:
  match ps:
    case []: True{}
    case +p <> t: Bool.and(Bool.and(pc_is_ln(p), pc_axis_al(p)), pcs_ln_al(t))
def pcs_minx(ps: List<&2, F.Pc>, +m: F64) -> F64:
  match ps:
    case []: m
    case +p <> t: pcs_minx(t, F64.min(m, F64.min(F.pc_ax(p), F.pc_bx(p))))
def pcs_maxx(ps: List<&2, F.Pc>, +m: F64) -> F64:
  match ps:
    case []: m
    case +p <> t: pcs_maxx(t, F64.max(m, F64.max(F.pc_ax(p), F.pc_bx(p))))
def pcs_miny(ps: List<&2, F.Pc>, +m: F64) -> F64:
  match ps:
    case []: m
    case +p <> t: pcs_miny(t, F64.min(m, F64.min(F.pc_ay(p), F.pc_by(p))))
def pcs_maxy(ps: List<&2, F.Pc>, +m: F64) -> F64:
  match ps:
    case []: m
    case +p <> t: pcs_maxy(t, F64.max(m, F64.max(F.pc_ay(p), F.pc_by(p))))
def on_grid(+v: F64, +lo: F64, +hi: F64) -> Bool:
  Bool.or(F64.is_eq(v, lo), F64.is_eq(v, hi))
def pcs_grid(ps: List<&2, F.Pc>, +x0: F64, +x1: F64, +y0: F64, +y1: F64) -> Bool:
  match ps:
    case []: True{}
    case +p <> t:
      Bool.and(Bool.and(on_grid(F.pc_ax(p), x0, x1), on_grid(F.pc_bx(p), x0, x1)),
        Bool.and(Bool.and(on_grid(F.pc_ay(p), y0, y1), on_grid(F.pc_by(p), y0, y1)), pcs_grid(t, x0, x1, y0, y1)))
def pcs_link_go(ps: List<&2, F.Pc>, +fx: F64, +fy: F64, +px: F64, +py: F64) -> Bool:
  match ps:
    case []: Bool.and(F64.is_eq(px, fx), F64.is_eq(py, fy))
    case +p <> t:
      Bool.and(Bool.and(F64.is_eq(F.pc_ax(p), px), F64.is_eq(F.pc_ay(p), py)),
        pcs_link_go(t, fx, fy, F.pc_bx(p), F.pc_by(p)))
def pcs_link(ps: List<&2, F.Pc>) -> Bool:
  match ps:
    case []: False{}
    case +p <> t: pcs_link_go(t, F.pc_ax(p), F.pc_ay(p), F.pc_bx(p), F.pc_by(p))
def sw_rect_go(+p: F.Pc, +ps: List<&2, F.Pc>) -> RT:
  +x0 = pcs_minx(ps, F64.min(F.pc_ax(p), F.pc_bx(p)))
  +x1 = pcs_maxx(ps, F64.max(F.pc_ax(p), F.pc_bx(p)))
  +y0 = pcs_miny(ps, F64.min(F.pc_ay(p), F.pc_by(p)))
  +y1 = pcs_maxy(ps, F64.max(F.pc_ay(p), F.pc_by(p)))
  +ok = Bool.and(Nat.is_eq(List.length(&2, F.Pc, ps), 4n),
    Bool.and(pcs_ln_al(ps),
      Bool.and(Bool.and(F64.is_lt(x0, x1), F64.is_lt(y0, y1)),
        Bool.and(F64.is_lt(0.0f64, x0), Bool.and(pcs_grid(ps, x0, x1, y0, y1), pcs_link(ps))))))
  RT{x0, x1, y0, y1, ok}
def sw_rect_of(ps: List<&2, F.Pc>) -> RT:
  match ps:
    case []: RT{0.0f64, 0.0f64, 0.0f64, 0.0f64, False{}}
    case +p <> t: sw_rect_go(p, ps)
def rt_ok(+r: RT) -> Bool:
  RT{+r0, +r1, +z0, +z1, +ok} = r
  ok
def swo_of(+deg: U64, +r: RT) -> SWO:
  RT{+r0, +r1, +z0, +z1, +ok} = r
  SWO{deg, r0, r1, z0, z1}
def swo_deg(+s: SWO) -> U64:
  SWO{+deg, +r0, +r1, +z0, +z1} = s
  deg
def swo_pcs(+s: SWO) -> List<&2, F.Pc>:
  SWO{+deg, +r0, +r1, +z0, +z1} = s
  [F.P_ln{r0, z0, r1, z0}, F.P_ln{r1, z0, r1, z1}, F.P_ln{r1, z1, r0, z1}, F.P_ln{r0, z1, r0, z0}]
def swo_open_bt(+s: SWO, +q: QD, +nd: U64) -> BD.Bt:
  +ps = swo_pcs(s)
  +n = qd_n(q)
  RV.sec_bt(RV.sec_vs(ps, 4n, Nat.add(n, 1n)), RV.sec_es(ps, 4n, n), RV.sides_all(n, ps, 4n, 0n, n, nd, 0n))
def patch_bp(+p: PP) -> G.BezP:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33}
def patch_vs(+p: PP) -> List<&2, Ty.Vertex>:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  [Ty.Vx{0u64, p00}, Ty.Vx{0u64, p03}, Ty.Vx{0u64, p33}, Ty.Vx{0u64, p30}]
def bz_ed(+ia: Nat, +ib: Nat, +a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> Ty.Edge:
  Ty.Ed{0u64, BD.hv(ia), BD.hv(ib), Ty.EK_curve{G.GV_bz{G.Bz{a, b, c, d}}, G.Dom{0.0f64, 1.0f64}}}
def patch_es(+p: PP) -> List<&2, Ty.Edge>:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  [bz_ed(0n, 1n, p00, p01, p02, p03), bz_ed(1n, 2n, p03, p13, p23, p33),
    bz_ed(2n, 3n, p33, p32, p31, p30), bz_ed(3n, 0n, p30, p20, p10, p00)]
def patch_fs(+p: PP, +nd: U64) -> List<&2, BD.FS>:
  [F9.face1(G.GV_bp{patch_bp(p)},
    [use_of(0n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)),
      use_of(1n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
      use_of(2n, True{}, v2(1.0f64, 1.0f64), v2(0.0f64, 1.0f64)),
      use_of(3n, True{}, v2(0.0f64, 1.0f64), v2(0.0f64, 0.0f64))], nd, 0n)]
def patch_open_bt(+p: PP, +nd: U64) -> BD.Bt:
  F9.pack(patch_vs(p), patch_es(p), patch_fs(p, nd))
def slab_c0(+p: PP) -> V.Point:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  p00
def slab_c1(+p: PP) -> V.Point:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  p03
def slab_c2(+p: PP) -> V.Point:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  p33
def slab_c3(+p: PP) -> V.Point:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  p30
def slab_n(+p: PP) -> V.Dir:
  dunit(pcross(psub(slab_c1(p), slab_c0(p)), psub(slab_c3(p), slab_c0(p))))
def slab_e1(+p: PP) -> V.Dir:
  dunit(psub(slab_c1(p), slab_c0(p)))
def slab_e2(+p: PP) -> V.Dir:
  dunit(psub(slab_c3(p), slab_c0(p)))
def slab_b(+p: PP, +t: F64, +i: Nat) -> V.Point:
  +h = dmul(slab_n(p), F64.div(t, 2.0f64))
  +c = Bool.pick(V.Point, Nat.is_eq(i, 0n), slab_c0(p),
    Bool.pick(V.Point, Nat.is_eq(i, 1n), slab_c1(p),
      Bool.pick(V.Point, Nat.is_eq(i, 2n), slab_c2(p), slab_c3(p))))
  padr(c, dmul(h, F64.neg(1.0f64)))
def slab_t(+p: PP, +t: F64, +i: Nat) -> V.Point:
  +h = dmul(slab_n(p), F64.div(t, 2.0f64))
  +c = Bool.pick(V.Point, Nat.is_eq(i, 0n), slab_c0(p),
    Bool.pick(V.Point, Nat.is_eq(i, 1n), slab_c1(p),
      Bool.pick(V.Point, Nat.is_eq(i, 2n), slab_c2(p), slab_c3(p))))
  padr(c, h)
def slab_vs(+p: PP, +t: F64) -> List<&2, Ty.Vertex>:
  [Ty.Vx{0u64, slab_b(p, t, 0n)}, Ty.Vx{0u64, slab_b(p, t, 1n)}, Ty.Vx{0u64, slab_b(p, t, 2n)},
    Ty.Vx{0u64, slab_b(p, t, 3n)}, Ty.Vx{0u64, slab_t(p, t, 0n)}, Ty.Vx{0u64, slab_t(p, t, 1n)},
    Ty.Vx{0u64, slab_t(p, t, 2n)}, Ty.Vx{0u64, slab_t(p, t, 3n)}]
def slab_es(+p: PP, +t: F64) -> List<&2, Ty.Edge>:
  [F9.ed_ln(0n, 1n, slab_b(p, t, 0n), slab_b(p, t, 1n)), F9.ed_ln(1n, 2n, slab_b(p, t, 1n), slab_b(p, t, 2n)),
    F9.ed_ln(2n, 3n, slab_b(p, t, 2n), slab_b(p, t, 3n)), F9.ed_ln(3n, 0n, slab_b(p, t, 3n), slab_b(p, t, 0n)),
    F9.ed_ln(4n, 5n, slab_t(p, t, 0n), slab_t(p, t, 1n)), F9.ed_ln(5n, 6n, slab_t(p, t, 1n), slab_t(p, t, 2n)),
    F9.ed_ln(6n, 7n, slab_t(p, t, 2n), slab_t(p, t, 3n)), F9.ed_ln(7n, 4n, slab_t(p, t, 3n), slab_t(p, t, 0n)),
    F9.ed_ln(0n, 4n, slab_b(p, t, 0n), slab_t(p, t, 0n)), F9.ed_ln(1n, 5n, slab_b(p, t, 1n), slab_t(p, t, 1n)),
    F9.ed_ln(2n, 6n, slab_b(p, t, 2n), slab_t(p, t, 2n)), F9.ed_ln(3n, 7n, slab_b(p, t, 3n), slab_t(p, t, 3n))]
def pl_use(+e: Nat, +fwd: Bool, +pa: V.Point, +pb: V.Point, +o: V.Point, +u: V.Dir, +v: V.Dir) -> BD.Use:
  BD.Us{e, fwd, RV.trim_uv(pa, o, u, v), RV.trim_uv(pb, o, u, v)}
def slab_fs(+p: PP, +t: F64, +nd: U64) -> List<&2, BD.FS>:
  +e1 = slab_e1(p)
  +e2 = slab_e2(p)
  +n = slab_n(p)
  +ne2 = dmul(e2, F64.neg(1.0f64))
  +ne1 = dmul(e1, F64.neg(1.0f64))
  +b0 = slab_b(p, t, 0n)
  +b1 = slab_b(p, t, 1n)
  +b2 = slab_b(p, t, 2n)
  +b3 = slab_b(p, t, 3n)
  +t0 = slab_t(p, t, 0n)
  +t1 = slab_t(p, t, 1n)
  +t2 = slab_t(p, t, 2n)
  +t3 = slab_t(p, t, 3n)
  [F9.face1(G.GV_pl{G.Pl{b0, e1, ne2}},
      [pl_use(3n, False{}, b3, b0, b0, e1, ne2), pl_use(2n, False{}, b2, b3, b0, e1, ne2),
        pl_use(1n, False{}, b1, b2, b0, e1, ne2), pl_use(0n, False{}, b0, b1, b0, e1, ne2)], nd, 0n),
    F9.face1(G.GV_pl{G.Pl{t0, e1, e2}},
      [pl_use(4n, True{}, t0, t1, t0, e1, e2), pl_use(5n, True{}, t1, t2, t0, e1, e2),
        pl_use(6n, True{}, t2, t3, t0, e1, e2), pl_use(7n, True{}, t3, t0, t0, e1, e2)], nd, 1n),
    F9.face1(G.GV_pl{G.Pl{b0, e1, n}},
      [pl_use(0n, True{}, b0, b1, b0, e1, n), pl_use(9n, True{}, b1, t1, b0, e1, n),
        pl_use(4n, False{}, t0, t1, b0, e1, n), pl_use(8n, False{}, b0, t0, b0, e1, n)], nd, 2n),
    F9.face1(G.GV_pl{G.Pl{b1, e2, n}},
      [pl_use(1n, True{}, b1, b2, b1, e2, n), pl_use(10n, True{}, b2, t2, b1, e2, n),
        pl_use(5n, False{}, t1, t2, b1, e2, n), pl_use(9n, False{}, b1, t1, b1, e2, n)], nd, 3n),
    F9.face1(G.GV_pl{G.Pl{b2, ne1, n}},
      [pl_use(2n, True{}, b2, b3, b2, ne1, n), pl_use(11n, True{}, b3, t3, b2, ne1, n),
        pl_use(6n, False{}, t2, t3, b2, ne1, n), pl_use(10n, False{}, b2, t2, b2, ne1, n)], nd, 4n),
    F9.face1(G.GV_pl{G.Pl{b3, ne2, n}},
      [pl_use(3n, True{}, b3, b0, b3, ne2, n), pl_use(8n, True{}, b0, t0, b3, ne2, n),
        pl_use(7n, False{}, t3, t0, b3, ne2, n), pl_use(11n, False{}, b3, t3, b3, ne2, n)], nd, 5n)]
def slab_bt(+p: PP, +t: F64, +nd: U64) -> BD.Bt:
  F9.pack(slab_vs(p, t), slab_es(p, t), slab_fs(p, t, nd))
def slab_vol(+p: PP, +t: F64) -> F64:
  F64.mul(dnorm(pcross(psub(slab_c1(p), slab_c0(p)), psub(slab_c3(p), slab_c0(p)))), t)
def duct_dims(+lo: LO, +t: F64) -> DD:
  LO{+z, +x0, +y0, +x1, +y1, +u0, +v0, +u1, +v1} = lo
  +h = F64.div(t, 2.0f64)
  +lf = F64.sqrt(F64.add(F64.mul(F64.sub(v0, y0), F64.sub(v0, y0)), F64.mul(z, z)))
  +lb = F64.sqrt(F64.add(F64.mul(F64.sub(v1, y1), F64.sub(v1, y1)), F64.mul(z, z)))
  +ll = F64.sqrt(F64.add(F64.mul(F64.sub(u0, x0), F64.sub(u0, x0)), F64.mul(z, z)))
  +lr = F64.sqrt(F64.add(F64.mul(F64.sub(u1, x1), F64.sub(u1, x1)), F64.mul(z, z)))
  +mf = F64.div(h, F64.div(F64.neg(z), lf))
  +mb = F64.div(h, F64.div(z, lb))
  +ml = F64.div(h, F64.div(F64.neg(z), ll))
  +mr = F64.div(h, F64.div(z, lr))
  DD{F64.add(x0, ml), F64.add(y0, mf), F64.add(x1, mr), F64.add(y1, mb), F64.add(u0, ml),
    F64.add(v0, mf), F64.add(u1, mr), F64.add(v1, mb), F64.sub(x0, ml), F64.sub(y0, mf),
    F64.sub(x1, mr), F64.sub(y1, mb), F64.sub(u0, ml), F64.sub(v0, mf), F64.sub(u1, mr),
    F64.sub(v1, mb), z}
def duct_inner_ok(+d: DD) -> Bool:
  DD{+ox0, +oy0, +ox1, +oy1, +ou0, +ov0, +ou1, +ov1, +ix0, +iy0, +ix1, +iy1, +iu0, +iv0, +iu1,
    +iv1, +z} = d
  Bool.and(F64.is_lt(ix0, ix1),
    Bool.and(F64.is_lt(iy0, iy1), Bool.and(F64.is_lt(iu0, iu1), F64.is_lt(iv0, iv1))))
def duct_vol(+d: DD) -> F64:
  DD{+ox0, +oy0, +ox1, +oy1, +ou0, +ov0, +ou1, +ov1, +ix0, +iy0, +ix1, +iy1, +iu0, +iv0, +iu1,
    +iv1, +z} = d
  F64.sub(F9.vol_frust(z, ox0, oy0, ox1, oy1, ou0, ov0, ou1, ov1),
    F9.vol_frust(z, ix0, iy0, ix1, iy1, iu0, iv0, iu1, iv1))
def duct_ob(+d: DD, +i: Nat) -> V.Point:
  DD{+ox0, +oy0, +ox1, +oy1, +ou0, +ov0, +ou1, +ov1, +ix0, +iy0, +ix1, +iy1, +iu0, +iv0, +iu1,
    +iv1, +z} = d
  Bool.pick(V.Point, Nat.is_eq(i, 0n), pt(ox0, oy0, 0.0f64),
    Bool.pick(V.Point, Nat.is_eq(i, 1n), pt(ox1, oy0, 0.0f64),
      Bool.pick(V.Point, Nat.is_eq(i, 2n), pt(ox1, oy1, 0.0f64), pt(ox0, oy1, 0.0f64))))
def duct_ot(+d: DD, +i: Nat) -> V.Point:
  DD{+ox0, +oy0, +ox1, +oy1, +ou0, +ov0, +ou1, +ov1, +ix0, +iy0, +ix1, +iy1, +iu0, +iv0, +iu1,
    +iv1, +z} = d
  Bool.pick(V.Point, Nat.is_eq(i, 0n), pt(ou0, ov0, z),
    Bool.pick(V.Point, Nat.is_eq(i, 1n), pt(ou1, ov0, z),
      Bool.pick(V.Point, Nat.is_eq(i, 2n), pt(ou1, ov1, z), pt(ou0, ov1, z))))
def duct_ib(+d: DD, +i: Nat) -> V.Point:
  DD{+ox0, +oy0, +ox1, +oy1, +ou0, +ov0, +ou1, +ov1, +ix0, +iy0, +ix1, +iy1, +iu0, +iv0, +iu1,
    +iv1, +z} = d
  Bool.pick(V.Point, Nat.is_eq(i, 0n), pt(ix0, iy0, 0.0f64),
    Bool.pick(V.Point, Nat.is_eq(i, 1n), pt(ix1, iy0, 0.0f64),
      Bool.pick(V.Point, Nat.is_eq(i, 2n), pt(ix1, iy1, 0.0f64), pt(ix0, iy1, 0.0f64))))
def duct_it(+d: DD, +i: Nat) -> V.Point:
  DD{+ox0, +oy0, +ox1, +oy1, +ou0, +ov0, +ou1, +ov1, +ix0, +iy0, +ix1, +iy1, +iu0, +iv0, +iu1,
    +iv1, +z} = d
  Bool.pick(V.Point, Nat.is_eq(i, 0n), pt(iu0, iv0, z),
    Bool.pick(V.Point, Nat.is_eq(i, 1n), pt(iu1, iv0, z),
      Bool.pick(V.Point, Nat.is_eq(i, 2n), pt(iu1, iv1, z), pt(iu0, iv1, z))))
def duct_vs(+d: DD) -> List<&2, Ty.Vertex>:
  [Ty.Vx{0u64, duct_ob(d, 0n)}, Ty.Vx{0u64, duct_ob(d, 1n)}, Ty.Vx{0u64, duct_ob(d, 2n)},
    Ty.Vx{0u64, duct_ob(d, 3n)}, Ty.Vx{0u64, duct_ot(d, 0n)}, Ty.Vx{0u64, duct_ot(d, 1n)},
    Ty.Vx{0u64, duct_ot(d, 2n)}, Ty.Vx{0u64, duct_ot(d, 3n)}, Ty.Vx{0u64, duct_ib(d, 0n)},
    Ty.Vx{0u64, duct_ib(d, 1n)}, Ty.Vx{0u64, duct_ib(d, 2n)}, Ty.Vx{0u64, duct_ib(d, 3n)},
    Ty.Vx{0u64, duct_it(d, 0n)}, Ty.Vx{0u64, duct_it(d, 1n)}, Ty.Vx{0u64, duct_it(d, 2n)},
    Ty.Vx{0u64, duct_it(d, 3n)}]
def duct_es(+d: DD) -> List<&2, Ty.Edge>:
  [F9.ed_ln(0n, 1n, duct_ob(d, 0n), duct_ob(d, 1n)), F9.ed_ln(1n, 2n, duct_ob(d, 1n), duct_ob(d, 2n)),
    F9.ed_ln(2n, 3n, duct_ob(d, 2n), duct_ob(d, 3n)), F9.ed_ln(3n, 0n, duct_ob(d, 3n), duct_ob(d, 0n)),
    F9.ed_ln(4n, 5n, duct_ot(d, 0n), duct_ot(d, 1n)), F9.ed_ln(5n, 6n, duct_ot(d, 1n), duct_ot(d, 2n)),
    F9.ed_ln(6n, 7n, duct_ot(d, 2n), duct_ot(d, 3n)), F9.ed_ln(7n, 4n, duct_ot(d, 3n), duct_ot(d, 0n)),
    F9.ed_ln(0n, 4n, duct_ob(d, 0n), duct_ot(d, 0n)), F9.ed_ln(1n, 5n, duct_ob(d, 1n), duct_ot(d, 1n)),
    F9.ed_ln(2n, 6n, duct_ob(d, 2n), duct_ot(d, 2n)), F9.ed_ln(3n, 7n, duct_ob(d, 3n), duct_ot(d, 3n)),
    F9.ed_ln(8n, 9n, duct_ib(d, 0n), duct_ib(d, 1n)), F9.ed_ln(9n, 10n, duct_ib(d, 1n), duct_ib(d, 2n)),
    F9.ed_ln(10n, 11n, duct_ib(d, 2n), duct_ib(d, 3n)),
    F9.ed_ln(11n, 8n, duct_ib(d, 3n), duct_ib(d, 0n)),
    F9.ed_ln(12n, 13n, duct_it(d, 0n), duct_it(d, 1n)),
    F9.ed_ln(13n, 14n, duct_it(d, 1n), duct_it(d, 2n)),
    F9.ed_ln(14n, 15n, duct_it(d, 2n), duct_it(d, 3n)),
    F9.ed_ln(15n, 12n, duct_it(d, 3n), duct_it(d, 0n)),
    F9.ed_ln(8n, 12n, duct_ib(d, 0n), duct_it(d, 0n)),
    F9.ed_ln(9n, 13n, duct_ib(d, 1n), duct_it(d, 1n)),
    F9.ed_ln(10n, 14n, duct_ib(d, 2n), duct_it(d, 2n)),
    F9.ed_ln(11n, 15n, duct_ib(d, 3n), duct_it(d, 3n)),
    F9.ed_ln(0n, 8n, duct_ob(d, 0n), duct_ib(d, 0n)), F9.ed_ln(1n, 9n, duct_ob(d, 1n), duct_ib(d, 1n)),
    F9.ed_ln(2n, 10n, duct_ob(d, 2n), duct_ib(d, 2n)),
    F9.ed_ln(3n, 11n, duct_ob(d, 3n), duct_ib(d, 3n)),
    F9.ed_ln(4n, 12n, duct_ot(d, 0n), duct_it(d, 0n)),
    F9.ed_ln(5n, 13n, duct_ot(d, 1n), duct_it(d, 1n)),
    F9.ed_ln(6n, 14n, duct_ot(d, 2n), duct_it(d, 2n)),
    F9.ed_ln(7n, 15n, duct_ot(d, 3n), duct_it(d, 3n))]
def dxneg() -> V.Dir:
  V.Dr{F64.neg(1.0f64), 0.0f64, 0.0f64}
def dyneg() -> V.Dir:
  V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64}
def dxu() -> V.Dir:
  V.Dr{1.0f64, 0.0f64, 0.0f64}
def dyu() -> V.Dir:
  V.Dr{0.0f64, 1.0f64, 0.0f64}
def duct_fs(+d: DD, +nd: U64) -> List<&2, BD.FS>:
  +ob0 = duct_ob(d, 0n)
  +ob1 = duct_ob(d, 1n)
  +ob2 = duct_ob(d, 2n)
  +ob3 = duct_ob(d, 3n)
  +ot0 = duct_ot(d, 0n)
  +ot1 = duct_ot(d, 1n)
  +ot2 = duct_ot(d, 2n)
  +ot3 = duct_ot(d, 3n)
  +ib0 = duct_ib(d, 0n)
  +ib1 = duct_ib(d, 1n)
  +ib2 = duct_ib(d, 2n)
  +ib3 = duct_ib(d, 3n)
  +it0 = duct_it(d, 0n)
  +it1 = duct_it(d, 1n)
  +it2 = duct_it(d, 2n)
  +it3 = duct_it(d, 3n)
  [F9.face1(G.GV_bp{F9.bp_of(ob0, ob1, ot1, ot0)},
      [use_of(0n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)),
        use_of(9n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(4n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)),
        use_of(8n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 0n),
    F9.face1(G.GV_bp{F9.bp_of(ob2, ob3, ot3, ot2)},
      [use_of(2n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)),
        use_of(11n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(6n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)),
        use_of(10n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 1n),
    F9.face1(G.GV_bp{F9.bp_of(ob3, ob0, ot0, ot3)},
      [use_of(3n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)),
        use_of(8n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(7n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)),
        use_of(11n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 2n),
    F9.face1(G.GV_bp{F9.bp_of(ob1, ob2, ot2, ot1)},
      [use_of(1n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)),
        use_of(10n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(5n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)),
        use_of(9n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 3n),
    F9.face1(G.GV_bp{F9.bp_of(ib0, it0, it1, ib1)},
      [use_of(20n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)),
        use_of(16n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(21n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)),
        use_of(12n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 4n),
    F9.face1(G.GV_bp{F9.bp_of(ib2, it2, it3, ib3)},
      [use_of(22n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)),
        use_of(18n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(23n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)),
        use_of(14n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 5n),
    F9.face1(G.GV_bp{F9.bp_of(ib3, it3, it0, ib0)},
      [use_of(23n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)),
        use_of(19n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(20n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)),
        use_of(15n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 6n),
    F9.face1(G.GV_bp{F9.bp_of(ib1, it1, it2, ib2)},
      [use_of(21n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)),
        use_of(17n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(22n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)),
        use_of(13n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 7n),
    F9.face1(G.GV_pl{G.Pl{ob0, dxu(), dyneg()}},
      [pl_use(24n, True{}, ob0, ib0, ob0, dxu(), dyneg()),
        pl_use(12n, True{}, ib0, ib1, ob0, dxu(), dyneg()),
        pl_use(25n, False{}, ob1, ib1, ob0, dxu(), dyneg()),
        pl_use(0n, False{}, ob0, ob1, ob0, dxu(), dyneg())], nd, 8n),
    F9.face1(G.GV_pl{G.Pl{ob1, dyu(), dxu()}},
      [pl_use(25n, True{}, ob1, ib1, ob1, dyu(), dxu()),
        pl_use(13n, True{}, ib1, ib2, ob1, dyu(), dxu()),
        pl_use(26n, False{}, ob2, ib2, ob1, dyu(), dxu()),
        pl_use(1n, False{}, ob1, ob2, ob1, dyu(), dxu())], nd, 9n),
    F9.face1(G.GV_pl{G.Pl{ob2, dxneg(), dyu()}},
      [pl_use(26n, True{}, ob2, ib2, ob2, dxneg(), dyu()),
        pl_use(14n, True{}, ib2, ib3, ob2, dxneg(), dyu()),
        pl_use(27n, False{}, ob3, ib3, ob2, dxneg(), dyu()),
        pl_use(2n, False{}, ob2, ob3, ob2, dxneg(), dyu())], nd, 10n),
    F9.face1(G.GV_pl{G.Pl{ob3, dyneg(), dxneg()}},
      [pl_use(27n, True{}, ob3, ib3, ob3, dyneg(), dxneg()),
        pl_use(15n, True{}, ib3, ib0, ob3, dyneg(), dxneg()),
        pl_use(24n, False{}, ob0, ib0, ob3, dyneg(), dxneg()),
        pl_use(3n, False{}, ob3, ob0, ob3, dyneg(), dxneg())], nd, 11n),
    F9.face1(G.GV_pl{G.Pl{ot0, dxu(), dyu()}},
      [pl_use(4n, True{}, ot0, ot1, ot0, dxu(), dyu()), pl_use(29n, True{}, ot1, it1, ot0, dxu(), dyu()),
        pl_use(16n, False{}, it0, it1, ot0, dxu(), dyu()), pl_use(28n, False{}, ot0, it0, ot0, dxu(), dyu())],
      nd, 12n),
    F9.face1(G.GV_pl{G.Pl{ot1, dyu(), dxneg()}},
      [pl_use(5n, True{}, ot1, ot2, ot1, dyu(), dxneg()),
        pl_use(30n, True{}, ot2, it2, ot1, dyu(), dxneg()),
        pl_use(17n, False{}, it1, it2, ot1, dyu(), dxneg()),
        pl_use(29n, False{}, ot1, it1, ot1, dyu(), dxneg())], nd, 13n),
    F9.face1(G.GV_pl{G.Pl{ot2, dxneg(), dyneg()}},
      [pl_use(6n, True{}, ot2, ot3, ot2, dxneg(), dyneg()),
        pl_use(31n, True{}, ot3, it3, ot2, dxneg(), dyneg()),
        pl_use(18n, False{}, it2, it3, ot2, dxneg(), dyneg()),
        pl_use(30n, False{}, ot2, it2, ot2, dxneg(), dyneg())], nd, 14n),
    F9.face1(G.GV_pl{G.Pl{ot3, dyneg(), dxu()}},
      [pl_use(7n, True{}, ot3, ot0, ot3, dyneg(), dxu()), pl_use(28n, True{}, ot0, it0, ot3, dyneg(), dxu()),
        pl_use(19n, False{}, it3, it0, ot3, dyneg(), dxu()), pl_use(31n, False{}, ot3, it3, ot3, dyneg(), dxu())],
      nd, 15n)]
def duct_bt(+d: DD, +nd: U64) -> BD.Bt:
  F9.pack(duct_vs(d), duct_es(d), duct_fs(d, nd))
def sec_dims(+s: SWO, +t: F64) -> SD:
  SWO{+deg, +r0, +r1, +z0, +z1} = s
  +h = F64.div(t, 2.0f64)
  SD{F64.sub(r0, h), F64.add(r1, h), F64.sub(z0, h), F64.add(z1, h), F64.add(r0, h), F64.sub(r1, h),
    F64.add(z0, h), F64.sub(z1, h)}
def sec_t_go(d: SD) -> Bool:
  SD{+r0o, +r1o, +z0o, +z1o, +r0i, +r1i, +z0i, +z1i} = d
  Bool.and(F64.is_lt(0.0f64, r0o), Bool.and(F64.is_lt(r0i, r1i), F64.is_lt(z0i, z1i)))
def sec_t_ok(+s: SWO, +t: F64) -> Bool:
  sec_t_go(sec_dims(s, t))
def pi() -> F64:
  F64{4614256656552045848u64}
def sec_vol_go(+deg: U64, d: SD) -> F64:
  SD{+r0o, +r1o, +z0o, +z1o, +r0i, +r1i, +z0i, +z1i} = d
  +ao = F64.mul(F64.sub(F64.mul(r1o, r1o), F64.mul(r0o, r0o)), F64.sub(z1o, z0o))
  +ai = F64.mul(F64.sub(F64.mul(r1i, r1i), F64.mul(r0i, r0i)), F64.sub(z1i, z0i))
  F64.mul(F64.mul(F9.sw_k(deg), pi()), F64.sub(ao, ai))
def sec_vol(+s: SWO, +t: F64) -> F64:
  SWO{+deg, +r0, +r1, +z0, +z1} = s
  sec_vol_go(deg, sec_dims(s, t))
def sec_pcs_o(+d: SD) -> List<&2, F.Pc>:
  SD{+r0o, +r1o, +z0o, +z1o, +r0i, +r1i, +z0i, +z1i} = d
  [F.P_ln{r0o, z0o, r1o, z0o}, F.P_ln{r1o, z0o, r1o, z1o}, F.P_ln{r1o, z1o, r0o, z1o},
    F.P_ln{r0o, z1o, r0o, z0o}]
def sec_pcs_i(+d: SD) -> List<&2, F.Pc>:
  SD{+r0o, +r1o, +z0o, +z1o, +r0i, +r1i, +z0i, +z1i} = d
  [F.P_ln{r0i, z0i, r1i, z0i}, F.P_ln{r1i, z0i, r1i, z1i}, F.P_ln{r1i, z1i, r0i, z1i},
    F.P_ln{r0i, z1i, r0i, z0i}]
def sec_eo(+q: Nat) -> Nat:
  Nat.add(Nat.mul(4n, q), Nat.mul(4n, Nat.add(q, 1n)))
def sec_arcs_off(left: Nat, +ps: List<&2, F.Pc>, +s: Nat, +i: Nat, +vo: Nat) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k:
      RV.sec_ed(Nat.add(RV.v_at(s, i, 4n), vo), Nat.add(RV.v_at(Nat.add(s, 1n), i, 4n), vo),
        RV.sec_arc_gv(ps, 4n, s, i)) <> sec_arcs_off(k, ps, s, Nat.add(i, 1n), vo)
def sec_arcs_all_off(left: Nat, +ps: List<&2, F.Pc>, +s: Nat, +vo: Nat) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k:
      List.append(&2, Ty.Edge, sec_arcs_off(4n, ps, s, 0n, vo), sec_arcs_all_off(k, ps, Nat.add(s, 1n), vo))
def sec_prof_off(left: Nat, +ps: List<&2, F.Pc>, +s: Nat, +i: Nat, +vo: Nat) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k:
      +j = RV.sec_imod(i, 4n)
      RV.sec_ed(Nat.add(RV.v_at(s, i, 4n), vo), Nat.add(RV.v_at(s, j, 4n), vo),
        RV.sec_bz(RV.sec_pt(ps, 4n, RV.v_at(s, i, 4n)), RV.sec_pt(ps, 4n, RV.v_at(s, j, 4n)))) <>
        sec_prof_off(k, ps, s, Nat.add(i, 1n), vo)
def sec_prof_all_off(left: Nat, +ps: List<&2, F.Pc>, +s: Nat, +vo: Nat) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k:
      List.append(&2, Ty.Edge, sec_prof_off(4n, ps, s, 0n, vo), sec_prof_all_off(k, ps, Nat.add(s, 1n), vo))
def sec_es_off(+ps: List<&2, F.Pc>, +q: Nat, +vo: Nat) -> List<&2, Ty.Edge>:
  List.append(&2, Ty.Edge, sec_arcs_all_off(q, ps, 0n, vo), sec_prof_all_off(Nat.add(q, 1n), ps, 0n, vo))
def sec_vs(+d: SD, +q: Nat) -> List<&2, Ty.Vertex>:
  List.append(&2, Ty.Vertex, RV.sec_vs(sec_pcs_o(d), 4n, Nat.add(q, 1n)),
    RV.sec_vs(sec_pcs_i(d), 4n, Nat.add(q, 1n)))
def sec_radial(+o: V.Point, +i: V.Point, +vo: Nat, +io: Nat) -> Ty.Edge:
  F9.ed_ln(vo, io, o, i)
def sec_es(+d: SD, +q: Nat) -> List<&2, Ty.Edge>:
  +pso = sec_pcs_o(d)
  +psi = sec_pcs_i(d)
  +vo = Nat.mul(4n, Nat.add(q, 1n))
  +eo = sec_eo(q)
  List.append(&2, Ty.Edge, RV.sec_es(pso, 4n, q),
    List.append(&2, Ty.Edge, sec_es_off(psi, q, vo),
      [sec_radial(RV.sec_pt(pso, 4n, 0n), RV.sec_pt(psi, 4n, 0n), 0n, vo),
        sec_radial(RV.sec_pt(pso, 4n, 1n), RV.sec_pt(psi, 4n, 1n), 1n, Nat.add(vo, 1n)),
        sec_radial(RV.sec_pt(pso, 4n, 2n), RV.sec_pt(psi, 4n, 2n), 2n, Nat.add(vo, 2n)),
        sec_radial(RV.sec_pt(pso, 4n, 3n), RV.sec_pt(psi, 4n, 3n), 3n, Nat.add(vo, 3n)),
        sec_radial(RV.sec_pt(pso, 4n, Nat.mul(q, 4n)), RV.sec_pt(psi, 4n, Nat.mul(q, 4n)),
          Nat.mul(q, 4n), Nat.add(vo, Nat.mul(q, 4n))),
        sec_radial(RV.sec_pt(pso, 4n, Nat.add(Nat.mul(q, 4n), 1n)),
          RV.sec_pt(psi, 4n, Nat.add(Nat.mul(q, 4n), 1n)), Nat.add(Nat.mul(q, 4n), 1n),
          Nat.add(vo, Nat.add(Nat.mul(q, 4n), 1n))),
        sec_radial(RV.sec_pt(pso, 4n, Nat.add(Nat.mul(q, 4n), 2n)),
          RV.sec_pt(psi, 4n, Nat.add(Nat.mul(q, 4n), 2n)), Nat.add(Nat.mul(q, 4n), 2n),
          Nat.add(vo, Nat.add(Nat.mul(q, 4n), 2n))),
        sec_radial(RV.sec_pt(pso, 4n, Nat.add(Nat.mul(q, 4n), 3n)),
          RV.sec_pt(psi, 4n, Nat.add(Nat.mul(q, 4n), 3n)), Nat.add(Nat.mul(q, 4n), 3n),
          Nat.add(vo, Nat.add(Nat.mul(q, 4n), 3n)))]))
def side_rev_loop(+s: Nat, +i: Nat, +q: Nat, +pl: Bool, +surf: G.GVal, +ps: List<&2, F.Pc>,
    +eo: Nat) -> List<&2, BD.Use>:
  +j = RV.sec_imod(i, 4n)
  [RV.sec_use(Nat.add(RV.p_at(s, i, 4n, q), eo), True{}, RV.v_at(s, i, 4n), RV.v_at(s, j, 4n), pl, surf,
      ps, 4n),
    RV.sec_use(Nat.add(RV.a_at(s, j, 4n), eo), True{}, RV.v_at(s, j, 4n), RV.v_at(Nat.add(s, 1n), j, 4n),
      pl, surf, ps, 4n),
    RV.sec_use(Nat.add(RV.p_at(Nat.add(s, 1n), i, 4n, q), eo), False{}, RV.v_at(Nat.add(s, 1n), i, 4n),
      RV.v_at(Nat.add(s, 1n), j, 4n), pl, surf, ps, 4n),
    RV.sec_use(Nat.add(RV.a_at(s, i, 4n), eo), False{}, RV.v_at(s, i, 4n), RV.v_at(Nat.add(s, 1n), i, 4n),
      pl, surf, ps, 4n)]
def sides_rev_row(left: Nat, +ps: List<&2, F.Pc>, +s: Nat, +i: Nat, +q: Nat, +nd: U64, +fi: Nat,
    +eo: Nat) -> List<&2, BD.FS>:
  match left:
    case 0n: []
    case 1n+k:
      +ss = RV.side_ss(ps, i)
      +surf = RV.ss_s(ss)
      +pl = RV.ss_plane(ss)
      BD.FS{0n, surf, Bool.not(RV.ss_same(ss)), [side_rev_loop(s, i, q, pl, surf, ps, eo)],
        BD.Fn{nd, 0n, 2u64, fi, 0n}} <> sides_rev_row(k, ps, s, Nat.add(i, 1n), q, nd, Nat.add(fi, 1n), eo)
def sides_rev_all(left: Nat, +ps: List<&2, F.Pc>, +s: Nat, +q: Nat, +nd: U64, +fi: Nat,
    +eo: Nat) -> List<&2, BD.FS>:
  match left:
    case 0n: []
    case 1n+k:
      List.append(&2, BD.FS, sides_rev_row(4n, ps, s, 0n, q, nd, fi, eo),
        sides_rev_all(k, ps, Nat.add(s, 1n), q, nd, Nat.add(fi, 4n), eo))
def ring_use(+e: Nat, +fwd: Bool, +pa: V.Point, +pb: V.Point, +surf: G.GVal) -> BD.Use:
  BD.Us{e, fwd, RV.trim_pl(surf, pa), RV.trim_pl(surf, pb)}
def ring_strip(+oa: V.Point, +ob: V.Point, +ia: V.Point, +ib: V.Point, +oi: Nat, +ii: Nat,
    +ra: Nat, +rb: Nat, +surf: G.GVal, +nd: U64, +fi: Nat, +rev: Bool) -> BD.FS:
  BD.FS{0n, surf, RV.cap_same(Bool.pick(List<&2, V.Point>, rev, [oa, ia, ib, ob], [oa, ob, ib, ia]), surf),
    [Bool.pick(List<&2, BD.Use>, rev,
      [ring_use(ra, True{}, oa, ia, surf), ring_use(ii, True{}, ia, ib, surf),
        ring_use(rb, False{}, ob, ib, surf), ring_use(oi, False{}, oa, ob, surf)],
      [ring_use(oi, True{}, oa, ob, surf), ring_use(rb, True{}, ob, ib, surf),
        ring_use(ii, False{}, ia, ib, surf), ring_use(ra, False{}, oa, ia, surf)])],
    BD.Fn{nd, 0n, 2u64, fi, 0n}}
def ring_fs(+pso: List<&2, F.Pc>, +psi: List<&2, F.Pc>, +s: Nat, +q: Nat, +surf: G.GVal, +nd: U64,
    +fi: Nat, +eo: Nat, +ro: Nat, +rev: Bool) -> List<&2, BD.FS>:
  +o0 = RV.sec_pt(pso, 4n, RV.v_at(s, 0n, 4n))
  +o1 = RV.sec_pt(pso, 4n, RV.v_at(s, 1n, 4n))
  +o2 = RV.sec_pt(pso, 4n, RV.v_at(s, 2n, 4n))
  +o3 = RV.sec_pt(pso, 4n, RV.v_at(s, 3n, 4n))
  +i0 = RV.sec_pt(psi, 4n, RV.v_at(s, 0n, 4n))
  +i1 = RV.sec_pt(psi, 4n, RV.v_at(s, 1n, 4n))
  +i2 = RV.sec_pt(psi, 4n, RV.v_at(s, 2n, 4n))
  +i3 = RV.sec_pt(psi, 4n, RV.v_at(s, 3n, 4n))
  [ring_strip(o0, o1, i0, i1, RV.p_at(s, 0n, 4n, q), Nat.add(RV.p_at(s, 0n, 4n, q), eo), ro,
      Nat.add(ro, 1n), surf, nd, fi, rev),
    ring_strip(o1, o2, i1, i2, RV.p_at(s, 1n, 4n, q), Nat.add(RV.p_at(s, 1n, 4n, q), eo), Nat.add(ro, 1n),
      Nat.add(ro, 2n), surf, nd, Nat.add(fi, 1n), rev),
    ring_strip(o2, o3, i2, i3, RV.p_at(s, 2n, 4n, q), Nat.add(RV.p_at(s, 2n, 4n, q), eo), Nat.add(ro, 2n),
      Nat.add(ro, 3n), surf, nd, Nat.add(fi, 2n), rev),
    ring_strip(o3, o0, i3, i0, RV.p_at(s, 3n, 4n, q), Nat.add(RV.p_at(s, 3n, 4n, q), eo), Nat.add(ro, 3n),
      ro, surf, nd, Nat.add(fi, 3n), rev)]
def sec_fs(+d: SD, +q: Nat, +nd: U64) -> List<&2, BD.FS>:
  +pso = sec_pcs_o(d)
  +psi = sec_pcs_i(d)
  +eo = sec_eo(q)
  +ro = Nat.add(eo, eo)
  +nf = Nat.mul(4n, q)
  List.append(&2, BD.FS, RV.sides_all(q, pso, 4n, 0n, q, nd, 0n),
    List.append(&2, BD.FS, sides_rev_all(q, psi, 0n, q, nd, nf, eo),
      List.append(&2, BD.FS, ring_fs(pso, psi, 0n, q, RV.cap_start(), nd, Nat.add(nf, nf), eo, ro,
          False{}),
        ring_fs(pso, psi, q, q, RV.cap_end(q), nd, Nat.add(Nat.add(nf, nf), 4n), eo, Nat.add(ro, 4n),
          True{}))))
def sec_bt(+d: SD, +q: Nat, +nd: U64) -> BD.Bt:
  F9.pack(sec_vs(d, q), sec_es(d, q), sec_fs(d, q, nd))
def rls_holes(rs: List<&2, F.Rl>) -> List<&2, Bool>:
  match rs:
    case []: []
    case r <> t: F.rl_hole(r) <> rls_holes(t)
def iabs(+a: I.I) -> I.I:
  +lo = I.i_lo(a)
  +hi = I.i_hi(a)
  Bool.pick(I.I, Bool.and(F64.is_le(lo, 0.0f64), F64.is_le(0.0f64, hi)), I.I{0.0f64, F64.max(F64.abs(lo), F64.abs(hi))},
    I.I{F64.min(F64.abs(lo), F64.abs(hi)), F64.max(F64.abs(lo), F64.abs(hi))})
def idist(+a: F64, +b: F64) -> I.I:
  iabs(I.isub(I.ipt(a), I.ipt(b)))
def lo_len_I(+lo: LO, +e: Nat) -> I.I:
  LO{+z, +x0, +y0, +x1, +y1, +u0, +v0, +u1, +v1} = lo
  Bool.pick(I.I, Nat.is_eq(e, 0n), idist(x0, x1),
    Bool.pick(I.I, Nat.is_eq(e, 1n), idist(y0, y1),
      Bool.pick(I.I, Nat.is_eq(e, 2n), idist(x0, x1),
        Bool.pick(I.I, Nat.is_eq(e, 3n), idist(y0, y1),
          Bool.pick(I.I, Nat.is_eq(e, 4n), idist(u0, u1),
            Bool.pick(I.I, Nat.is_eq(e, 5n), idist(v0, v1),
              Bool.pick(I.I, Nat.is_eq(e, 6n), idist(u0, u1),
                Bool.pick(I.I, Nat.is_eq(e, 7n), idist(v0, v1), I.ipt(0.0f64)))))))))
def sw_seg(+e: Nat) -> Nat:
  Nat.sub(e, Nat.mul(Nat.div(e, 4n), 4n))
def sw_len_I(+s: SWO, +e: Nat) -> I.I:
  SWO{+deg, +r0, +r1, +z0, +z1} = s
  +g = sw_seg(e)
  Bool.pick(I.I, Bool.or(Nat.is_eq(g, 0n), Nat.is_eq(g, 2n)), idist(r0, r1), idist(z0, z1))
def bz_mid(+a: V.Point, +b: V.Point) -> V.Point:
  plerp(a, b, 0.5f64)
def bz_len_go(+n: Nat, +a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> F64:
  match n:
    case 0n: dnorm(psub(a, d))
    case 1n+k:
      +m01 = bz_mid(a, b)
      +m12 = bz_mid(b, c)
      +m23 = bz_mid(c, d)
      +m012 = bz_mid(m01, m12)
      +m123 = bz_mid(m12, m23)
      +m = bz_mid(m012, m123)
      F64.add(bz_len_go(k, a, m01, m012, m), bz_len_go(k, m, m123, m23, d))
def bz_len(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> F64:
  bz_len_go(10n, a, b, c, d)
def pt_bnd_len(+p: PP, +e: Nat) -> F64:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  Bool.pick(F64, Nat.is_eq(e, 0n), bz_len(p00, p01, p02, p03),
    Bool.pick(F64, Nat.is_eq(e, 1n), bz_len(p03, p13, p23, p33),
      Bool.pick(F64, Nat.is_eq(e, 2n), bz_len(p33, p32, p31, p30),
        Bool.pick(F64, Nat.is_eq(e, 3n), bz_len(p30, p20, p10, p00), 0.0f64))))
def loft_bnd_ids() -> List<&2, Nat>:
  [0n, 1n, 2n, 3n, 4n, 5n, 6n, 7n]
def swo_bnd_ids(+q: QD) -> List<&2, Nat>:
  +n = qd_n(q)
  +b = Nat.mul(4n, n)
  +t = Nat.add(b, Nat.mul(4n, n))
  [b, Nat.add(b, 1n), Nat.add(b, 2n), Nat.add(b, 3n), t, Nat.add(t, 1n), Nat.add(t, 2n), Nat.add(t, 3n)]
def patch_bnd_ids() -> List<&2, Nat>:
  [0n, 1n, 2n, 3n]
def be_of_I(+e: Nat, +a: I.I) -> BE:
  BE{e, I.i_lo(a), I.i_hi(a), True{}}
def be_of_e(+e: Nat, +l: F64) -> BE:
  BE{e, l, l, False{}}
def loft_bes(+lo: LO, ids: List<&2, Nat>) -> List<&2, BE>:
  match ids:
    case []: []
    case +e <> t: be_of_I(e, lo_len_I(lo, e)) <> loft_bes(lo, t)
def swo_bes(+s: SWO, ids: List<&2, Nat>) -> List<&2, BE>:
  match ids:
    case []: []
    case +e <> t: be_of_I(e, sw_len_I(s, e)) <> swo_bes(s, t)
def patch_bes(+p: PP, ids: List<&2, Nat>) -> List<&2, BE>:
  match ids:
    case []: []
    case +e <> t: be_of_e(e, pt_bnd_len(p, e)) <> patch_bes(p, t)
def loft_bnd(+lo: LO) -> List<&2, BE>:
  loft_bes(lo, loft_bnd_ids())
def swo_bnd(+s: SWO, +q: QD) -> List<&2, BE>:
  swo_bes(s, swo_bnd_ids(q))
def patch_bnd(+p: PP) -> List<&2, BE>:
  patch_bes(p, patch_bnd_ids())
def be_eid(+b: BE) -> Nat:
  BE{+eid, +lo, +hi, +cert} = b
  eid
def be_lo(+b: BE) -> F64:
  BE{+eid, +lo, +hi, +cert} = b
  lo
def be_hi(+b: BE) -> F64:
  BE{+eid, +lo, +hi, +cert} = b
  hi
def be_cert(+b: BE) -> Bool:
  BE{+eid, +lo, +hi, +cert} = b
  cert
def bnd_row(+i: Nat, +b: BE) -> BR:
  BR{i, be_eid(b), be_lo(b), be_hi(b), be_cert(b)}
def bnd_rows(bs: List<&2, BE>, +i: Nat) -> List<&2, BR>:
  match bs:
    case []: []
    case +b <> t: bnd_row(i, b) <> bnd_rows(t, Nat.add(i, 1n))
def surf_rows(+bs: List<&2, BE>) -> List<&2, BR>:
  bnd_rows(bs, 0n)
def br_eid(+r: BR) -> Nat:
  BR{+i, +eid, +lo, +hi, +cert} = r
  eid
def br_lo(+r: BR) -> F64:
  BR{+i, +eid, +lo, +hi, +cert} = r
  lo
def br_hi(+r: BR) -> F64:
  BR{+i, +eid, +lo, +hi, +cert} = r
  hi
def br_cert(+r: BR) -> Bool:
  BR{+i, +eid, +lo, +hi, +cert} = r
  cert
def br_i(+r: BR) -> Nat:
  BR{+i, +eid, +lo, +hi, +cert} = r
  i
def cert_tag(+c: Bool) -> String:
  Bool.pick(String, c, "certified", "estimated")
def row_s(+id: U64, +r: BR) -> String:
  BR{+i, +eid, +lo, +hi, +cert} = r
  "edge n" ++ U64.show(id) ++ ".e" ++ Nat.show(eid) ++ " len [" ++ N.f_show(lo) ++ ", " ++
    N.f_show(hi) ++ "] " ++ cert_tag(cert) ++ "\n"
def rows_s(+id: U64, rs: List<&2, BR>) -> String:
  match rs:
    case []: ""
    case +r <> t: row_s(id, r) ++ rows_s(id, t)
def blen_I(bs: List<&2, BE>, +acc: I.I) -> I.I:
  match bs:
    case []: acc
    case +b <> t:
      BE{+eid, +lo, +hi, +cert} = b
      blen_I(t, I.iadd(acc, I.I{lo, hi}))
def blen_e(bs: List<&2, BE>, +acc: F64) -> F64:
  match bs:
    case []: acc
    case +b <> t:
      BE{+eid, +lo, +hi, +cert} = b
      blen_e(t, F64.add(acc, lo))
def tri_I(+a: V.Point, +b: V.Point, +c: V.Point) -> I.I:
  +ux = I.isub(I.ipt(ptx(b)), I.ipt(ptx(a)))
  +uy = I.isub(I.ipt(pty(b)), I.ipt(pty(a)))
  +uz = I.isub(I.ipt(ptz(b)), I.ipt(ptz(a)))
  +vx = I.isub(I.ipt(ptx(c)), I.ipt(ptx(a)))
  +vy = I.isub(I.ipt(pty(c)), I.ipt(pty(a)))
  +vz = I.isub(I.ipt(ptz(c)), I.ipt(ptz(a)))
  +nx = I.isub(I.imul(uy, vz), I.imul(uz, vy))
  +ny = I.isub(I.imul(uz, vx), I.imul(ux, vz))
  +nz = I.isub(I.imul(ux, vy), I.imul(uy, vx))
  I.iscale(I.isqrt(I.iadd(I.iadd(I.imul(nx, nx), I.imul(ny, ny)), I.imul(nz, nz))), 0.5f64)
def quad_I(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> I.I:
  I.iadd(tri_I(a, b, c), tri_I(a, c, d))
def loft_area_I(+lo: LO) -> I.I:
  +fr = lo_fr(lo, 0u64)
  I.iadd(quad_I(F9.fr_pt(0n, fr), F9.fr_pt(1n, fr), F9.fr_pt(5n, fr), F9.fr_pt(4n, fr)),
    I.iadd(quad_I(F9.fr_pt(2n, fr), F9.fr_pt(3n, fr), F9.fr_pt(7n, fr), F9.fr_pt(6n, fr)),
      I.iadd(quad_I(F9.fr_pt(3n, fr), F9.fr_pt(0n, fr), F9.fr_pt(4n, fr), F9.fr_pt(7n, fr)),
        quad_I(F9.fr_pt(1n, fr), F9.fr_pt(2n, fr), F9.fr_pt(6n, fr), F9.fr_pt(5n, fr)))))
def swo_theta_I(+deg: U64) -> I.I:
  I.imul(I.ipt(F9.sw_k(deg)), I.imul(I.ipt(2.0f64), I.pi_i()))
def swo_area_I(+s: SWO) -> I.I:
  SWO{+deg, +r0, +r1, +z0, +z1} = s
  +th = swo_theta_I(deg)
  +ann = I.isub(I.imul(I.ipt(r1), I.ipt(r1)), I.imul(I.ipt(r0), I.ipt(r0)))
  +cyl = I.imul(I.iadd(I.ipt(r1), I.ipt(r0)), I.isub(I.ipt(z1), I.ipt(z0)))
  I.imul(th, I.iadd(ann, cyl))
def n2f(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))
def bb0(+t: F64) -> F64:
  F64.mul(F64.sub(1.0f64, t), F64.mul(F64.sub(1.0f64, t), F64.sub(1.0f64, t)))
def bb1(+t: F64) -> F64:
  F64.mul(3.0f64, F64.mul(F64.mul(F64.sub(1.0f64, t), F64.sub(1.0f64, t)), t))
def bb2(+t: F64) -> F64:
  F64.mul(3.0f64, F64.mul(F64.sub(1.0f64, t), F64.mul(t, t)))
def bb3(+t: F64) -> F64:
  F64.mul(F64.mul(t, t), t)
def bz4_pt(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point, +t: F64) -> V.Point:
  +w0 = bb0(t)
  +w1 = bb1(t)
  +w2 = bb2(t)
  +w3 = bb3(t)
  pt(F64.add(F64.add(F64.mul(w0, ptx(a)), F64.mul(w1, ptx(b))),
      F64.add(F64.mul(w2, ptx(c)), F64.mul(w3, ptx(d)))),
    F64.add(F64.add(F64.mul(w0, pty(a)), F64.mul(w1, pty(b))),
      F64.add(F64.mul(w2, pty(c)), F64.mul(w3, pty(d)))),
    F64.add(F64.add(F64.mul(w0, ptz(a)), F64.mul(w1, ptz(b))),
      F64.add(F64.mul(w2, ptz(c)), F64.mul(w3, ptz(d)))))
def bezp_pt(+p: PP, +u: F64, +v: F64) -> V.Point:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  bz4_pt(bz4_pt(p00, p01, p02, p03, u), bz4_pt(p10, p11, p12, p13, u), bz4_pt(p20, p21, p22, p23, u),
    bz4_pt(p30, p31, p32, p33, u), v)
def tri_e(+a: V.Point, +b: V.Point, +c: V.Point) -> F64:
  F64.mul(0.5f64, dnorm(pcross(psub(b, a), psub(c, a))))
def quad_e(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> F64:
  F64.add(tri_e(a, b, c), tri_e(a, c, d))
def grid_row(+p: PP, +i: Nat, +j: Nat, +n: Nat) -> F64:
  +u0 = F64.div(n2f(i), n2f(n))
  +u1 = F64.div(n2f(Nat.add(i, 1n)), n2f(n))
  +v0 = F64.div(n2f(j), n2f(n))
  +v1 = F64.div(n2f(Nat.add(j, 1n)), n2f(n))
  quad_e(bezp_pt(p, u0, v0), bezp_pt(p, u1, v0), bezp_pt(p, u1, v1), bezp_pt(p, u0, v1))
def grid_cols(left: Nat, +p: PP, +i: Nat, +j: Nat, +n: Nat, +acc: F64) -> F64:
  match left:
    case 0n: acc
    case 1n+k: grid_cols(k, p, i, Nat.add(j, 1n), n, F64.add(acc, grid_row(p, i, j, n)))
def grid_rows(left: Nat, +p: PP, +i: Nat, +n: Nat, +acc: F64) -> F64:
  match left:
    case 0n: acc
    case 1n+k: grid_rows(k, p, Nat.add(i, 1n), n, grid_cols(n, p, i, 0n, n, acc))
def patch_area_est(+p: PP) -> F64:
  grid_rows(32n, p, 0n, 32n, 0.0f64)
def bb_pt(+x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64, +p: V.Point) -> List<&2, F64>:
  [F64.min(x0, ptx(p)), F64.max(x1, ptx(p)), F64.min(y0, pty(p)), F64.max(y1, pty(p)),
    F64.min(z0, ptz(p)), F64.max(z1, ptz(p))]
def bb_init(+p: V.Point) -> List<&2, F64>:
  [ptx(p), ptx(p), pty(p), pty(p), ptz(p), ptz(p)]
def bb_add(+b: List<&2, F64>, +p: V.Point) -> List<&2, F64>:
  bb_pt(f_nth(b, 0n), f_nth(b, 1n), f_nth(b, 2n), f_nth(b, 3n), f_nth(b, 4n), f_nth(b, 5n), p)
def bb_pts(ps: List<&2, V.Point>, +b: List<&2, F64>) -> List<&2, F64>:
  match ps:
    case []: b
    case +p <> t: bb_pts(t, bb_add(b, p))
def bb_of(+ps: List<&2, V.Point>) -> List<&2, F64>:
  match ps:
    case []: [0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64]
    case +p <> t: bb_pts(t, bb_init(p))
def bb_s(+b: List<&2, F64>) -> String:
  "bbox " ++ N.f_show(f_nth(b, 0n)) ++ " " ++ N.f_show(f_nth(b, 1n)) ++ " " ++ N.f_show(f_nth(b, 2n)) ++
    " " ++ N.f_show(f_nth(b, 3n)) ++ " " ++ N.f_show(f_nth(b, 4n)) ++ " " ++ N.f_show(f_nth(b, 5n)) ++ "\n"
def pp_corners(+p: PP) -> List<&2, V.Point>:
  PP{+p00, +p01, +p02, +p03, +p10, +p11, +p12, +p13, +p20, +p21, +p22, +p23, +p30, +p31,
    +p32, +p33} = p
  [p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33]
def loft_corners(+lo: LO) -> List<&2, V.Point>:
  +fr = lo_fr(lo, 0u64)
  [F9.fr_pt(0n, fr), F9.fr_pt(1n, fr), F9.fr_pt(2n, fr), F9.fr_pt(3n, fr), F9.fr_pt(4n, fr),
    F9.fr_pt(5n, fr), F9.fr_pt(6n, fr), F9.fr_pt(7n, fr)]
def swo_corners_go(left: Nat, +ps: List<&2, F.Pc>, +s: Nat) -> List<&2, V.Point>:
  match left:
    case 0n: []
    case 1n+k:
      List.append(&2, V.Point,
        [RV.sec_pt(ps, 4n, RV.v_at(s, 0n, 4n)), RV.sec_pt(ps, 4n, RV.v_at(s, 1n, 4n)),
          RV.sec_pt(ps, 4n, RV.v_at(s, 2n, 4n)), RV.sec_pt(ps, 4n, RV.v_at(s, 3n, 4n))],
        swo_corners_go(k, ps, Nat.add(s, 1n)))
def swo_corners(+s: SWO, +q: QD) -> List<&2, V.Point>:
  swo_corners_go(Nat.add(qd_n(q), 1n), swo_pcs(s), 0n)
def iv_s(+a: I.I, +cert: Bool) -> String:
  "[" ++ N.f_show(I.i_lo(a)) ++ ", " ++ N.f_show(I.i_hi(a)) ++ "] " ++ cert_tag(cert) ++ "\n"
def est_s(+v: F64) -> String:
  "[" ++ N.f_show(v) ++ ", " ++ N.f_show(v) ++ "] estimated\n"
def loft_rep(+id: U64, +lo: LO) -> String:
  +bes = loft_bnd(lo)
  "surf node " ++ U64.show(id) ++ " kind loft-open faces 4 boundary 8\n" ++ rows_s(id, surf_rows(bes)) ++
    "area " ++ iv_s(loft_area_I(lo), True{}) ++ "blen " ++
    iv_s(blen_I(bes, I.ipt(0.0f64)), True{}) ++ bb_s(bb_of(loft_corners(lo)))
def swo_rep(+id: U64, +s: SWO, +q: QD) -> String:
  +bes = swo_bnd(s, q)
  +nf = Nat.mul(4n, qd_n(q))
  "surf node " ++ U64.show(id) ++ " kind sweep-open faces " ++ Nat.show(nf) ++ " boundary 8\n" ++
    rows_s(id, surf_rows(bes)) ++ "area " ++ iv_s(swo_area_I(s), True{}) ++ "blen " ++
    iv_s(blen_I(bes, I.ipt(0.0f64)), True{}) ++ bb_s(bb_of(swo_corners(s, q)))
def pt_rep(+id: U64, +p: PP) -> String:
  +bes = patch_bnd(p)
  "surf node " ++ U64.show(id) ++ " kind patch faces 1 boundary 4\n" ++ rows_s(id, surf_rows(bes)) ++
    "area " ++ est_s(patch_area_est(p)) ++ "blen " ++ est_s(blen_e(bes, 0.0f64)) ++
    bb_s(bb_of(pp_corners(p)))
def so_ok(+s: SO) -> Bool:
  match s:
    case SO_lo{+z, +bot, +top, +tw, +cont}: True{}
    case SO_sw{+deg, +rs, +g, +gd, +tw}: True{}
    case SO_pt{+ps}: True{}
    case SO_bad{}: False{}
def surf_gr(+g: GR) -> String:
  match g:
    case GR_ok{}: ""
    case GR_no{+why, +fix}: "error invalid-input | surf | why: " ++ why ++ " | fix: " ++ fix
def hs_nth(hs: List<&2, Bool>, +i: Nat) -> Bool:
  match hs:
    case []: True{}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: hs_nth(t, j)
def pp_single(+ls: List<&2, F.Lp>, +hs: List<&2, Bool>) -> Bool:
  Bool.and(Nat.is_eq(List.length(&2, F.Lp, ls), 1n),
    Bool.and(Nat.is_eq(List.length(&2, Bool, hs), 1n), Bool.not(hs_nth(hs, 0n))))
def surf_lo(+id: U64, +z: X.Xp, +bot: F.Region, +top: F.Region, +tw: U64, +cont: U64,
    +e: X.Env) -> String:
  +zv = X.xp_ev(z, e)
  +eb = F.loops_ev([rg_out(bot)], e, 0n)
  +et = F.loops_ev([rg_out(top)], e, 0n)
  +l = F9.loft_lf(Bool.or(rg_has_h(bot), rg_has_h(top)), ev_lp(eb), ev_lp(et), U64.to_nat(tw), cont, zv)
  +k = F9.lf_kind(l)
  Bool.pick(String, Bool.or(U64.is_eq(k, 1u64), U64.is_eq(k, 2u64)), loft_rep(id, lo_of_lf(l, zv)),
    "error: node " ++ U64.show(id) ++ "; nothing surfaced")
def surf_sw_rt(ok: Bool, +id: U64, +deg: U64, +r: RT) -> String:
  match ok:
    case False{}: "error: node " ++ U64.show(id) ++ "; nothing surfaced"
    case True{}: swo_rep(id, swo_of(deg, r), qd_of(deg))
def surf_sw_pp(ok: Bool, +id: U64, +deg: U64, +pp: List<&2, F.Lp>) -> String:
  match ok:
    case False{}: "error: node " ++ U64.show(id) ++ "; nothing surfaced"
    case True{}:
      +r = sw_rect_of(F.lp_pcs(lp0(pp)))
      surf_sw_rt(rt_ok(r), id, deg, r)
def surf_sw_ck(c: F.CK, +id: U64, +deg: U64, +rs: List<&2, F.Region>) -> String:
  match c:
    case F.CK_err{e}: "error: node " ++ U64.show(id) ++ "; nothing surfaced"
    case F.CK_ok{ls, ps}:
      +hs = rls_holes(F.rg_rls(rs, 0n, F.K_free{}))
      +pp = RV.lps_prep(ls, hs)
      surf_sw_pp(pp_single(pp, hs), id, deg, pp)
def surf_sw(+id: U64, +deg: U64, +rs: List<&2, F.Region>, +e: X.Env) -> String:
  surf_sw_ck(F.prof_check(rs, e), id, deg, rs)
def surf_pt(+id: U64, +ps: List<&2, X.Xp>, +e: X.Env) -> String:
  +p = pp_ev(ps, e)
  Bool.pick(String, pa_ok(p), pt_rep(id, p), "error: node " ++ U64.show(id) ++ "; nothing surfaced")
def surf_rep(+id: U64, +s: SO, +e: X.Env) -> String:
  match s:
    case SO_lo{+z, +bot, +top, +tw, +cont}: surf_lo(id, z, bot, top, tw, cont, e)
    case SO_sw{+deg, +rs, +g, +gd, +tw}: surf_sw(id, deg, rs, e)
    case SO_pt{+ps}: surf_pt(id, ps, e)
    case SO_bad{}: surf_gr(su_go(False{}))
