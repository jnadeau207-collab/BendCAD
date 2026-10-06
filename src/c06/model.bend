import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c04/types.bend as Ty
import ../c04/ops.bend as B4
import ../base/par.bend as B
import ../base/ex.bend as E
import ../c05/exact.bend as XE
import ./xp.bend as X
import ./prof.bend as F
import ./build.bend as BD
import ./revolve.bend as RV
import ./iv.bend as I

type Sel is Data:
  Sel{ nd: U64, k: Nat, side: U64 }

type Hl is Data:
  Hl{ x: X.Xp, y: X.Xp, r: X.Xp }

type Op is Data:
  O_prism{ rs: List<&2, F.Region>, z0: X.Xp, z1: X.Xp }
  O_box{ x: X.Xp, y: X.Xp, z: X.Xp }
  O_cyl{ r: X.Xp, h: X.Xp }
  O_pad{ base: U64, f: Sel, rs: List<&2, F.Region>, h: X.Xp }
  O_pocket{ base: U64, f: Sel, rs: List<&2, F.Region>, d: X.Xp, thru: Bool }
  O_holes{ base: U64, f: Sel, hs: List<&2, Hl>, d: X.Xp, thru: Bool }
  O_move{ base: U64, tx: X.Xp, ty: X.Xp, tz: X.Xp, q: U64 }
  O_rot{ base: U64, ax: U64, deg: X.Xp }
  O_unk{ name: String }
  O_revolve{ rs: List<&2, F.Region> }
  O_cone{ r: X.Xp, h: X.Xp }
  O_sph{ r: X.Xp }
  O_tor{ bigr: X.Xp, r: X.Xp }

type Mat is Data:
  M_create{}
  M_add{}
  M_remove{}
  M_same{}
  M_unknown{}

type Cnt is Data:
  C_any{}
  C_eq{ n: Nat }

type It is Data:
  It{ mat: Mat, fc: Cnt, fm: Cnt, sh: Cnt, ho: Cnt }

type Fx is Data:
  Fx{ mat: Mat, fc: Nat, fm: Nat, sh: Nat, ho: Nat }

type Dim is Data:
  Dm{ nom: F64, lo: F64, hi: F64 }

type Param is Data:
  Pm{ id: U64, name: String, dim: Dim }

type Node is Data:
  Nd{ id: U64, op: Op, it: It }

type Part is Data:
  Pt{ ps: List<&2, Param>, ns: List<&2, Node> }

type Pl is Data:
  Pl{ m: V.Mat3, tx: F64, ty: F64, tz: F64, mi: List<&2, I.I>, ti: List<&2, I.I> }

type Body is Data:
  Bd{ cells: List<&2, BD.Cl>, brep: Ty.Brep, fns: List<&2, BD.Fn>, pl: Pl, rv: List<&2, F.Lp> }

type Dg is Data:
  Dg{ what: String, loc: String, why: String, fix: String }

type NR is Data:
  NR_ok{ b: Body, fx: Fx }
  NR_err{ kind: T.FailKind, d: Dg }

type CE is Data:
  CE{ id: U64, key: List<&2, U64>, r: NR }

type Ms is Data:
  Ms{ vol: I.I, area: I.I, x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64, nv: Nat, ne: Nat, nf: Nat,
    ns: Nat, genus: Nat, lin: F64 }

type Acc is Data:
  Acc{ vol: I.I, area: I.I, per: I.I }

type Bb is Data:
  Bb{ x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64 }

type NS is Data:
  NS{ k: List<&2, U64>, lp: Nat, ce: Nat }

def nr_err(+k: T.FailKind, +w: String, +l: String, +y: String, +f: String) -> NR:
  NR_err{k, Dg{w, l, y, f}}

def bad(+w: String, +l: String, +y: String, +f: String) -> NR:
  nr_err(T.F_invalid{}, w, l, y, f)

def m3_id() -> V.Mat3:
  V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64}

def ipts(xs: List<&2, F64>) -> List<&2, I.I>:
  match xs:
    case []: []
    case +x <> t: I.ipt(x) <> ipts(t)

def pl_id() -> Pl:
  Pl{m3_id(), 0.0f64, 0.0f64, 0.0f64, ipts([1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64]), ipts([0.0f64, 0.0f64, 0.0f64])}

def pe_why(+c: U64) -> String:
  match c:
    case 1u64: "nonfinite-coordinate"
    case 2u64: "zero-length-segment"
    case 3u64: "nonpositive-radius"
    case 4u64: "arc-start-off-circle"
    case 5u64: "arc-end-off-circle"
    case 6u64: "arc-endpoints-same-direction"
    case 7u64: "loop-encloses-no-area"
    case 8u64: "repeated-point"
    case 9u64: "curves-cross-or-touch"
    case 10u64: "adjacent-segments-overlap"
    case 11u64: "orientation-uncertain"
    case 12u64: "hole-outside-outer"
    case 13u64: "holes-nested"
    case 14u64: "regions-overlap"
    case 15u64: "clearance-not-certified"
    case 16u64: "arc-split-point-not-certified"
    case 17u64: "unknown-parameter"
    case 18u64: "footprint-outside-face"
    case 19u64: "footprint-contains-or-meets-existing-feature"
    case 20u64: "profile-crosses-revolve-axis"
    case 21u64: "hole-touches-revolve-axis"
    case 22u64: "axis-pinch"
    case 23u64: "consecutive-axis-segments"
    case 24u64: "surface-not-representable"
    case _: "profile-error"

def pe_fix(+c: U64) -> String:
  match c:
    case 1u64: "make every coordinate expression finite"
    case 2u64: "remove the zero-length segment"
    case 3u64: "use a positive radius"
    case 4u64: "put the arc start on its circle (distance to center = radius)"
    case 5u64: "put the arc end on its circle (distance to center = radius)"
    case 6u64: "use a full circle loop or distinct arc endpoints"
    case 7u64: "give the loop at least two non-collinear pieces"
    case 8u64: "remove the repeated vertex"
    case 9u64: "separate the crossing or touching curves"
    case 10u64: "remove the backtracking segment"
    case 11u64: "give the loop a clearly nonzero area"
    case 12u64: "move the hole inside its outer loop"
    case 13u64: "do not nest holes; make an island region instead"
    case 14u64: "keep regions disjoint or put islands inside holes"
    case 15u64: "increase the clearance between these curves"
    case 16u64: "move the arc so its quadrant points are representable"
    case 17u64: "define the parameter"
    case 18u64: "keep the footprint strictly inside the selected face"
    case 19u64: "keep the footprint clear of existing features on the face"
    case 20u64: "keep the whole profile at x >= 0 (x is the radius)"
    case 21u64: "keep holes strictly off the axis"
    case 22u64: "touch the axis only along an axis segment, not at a lone vertex"
    case 23u64: "merge consecutive segments that lie on the axis"
    case 24u64: "adjust the slanted line or arc (cone apex not certifiable, or arc centre at x < 0)"
    case _: "report this"

def pe_nr(e: F.Er, +what: String) -> NR:
  F.Er{+code, +lp, +sg} = e
  nr_err(Bool.pick(T.FailKind, Bool.or(U64.is_eq(code, 11u64), Bool.or(U64.is_eq(code, 15u64),
      U64.is_eq(code, 16u64))), T.F_uncertain{}, T.F_invalid{}),
    what, "loop " ++ Nat.show(lp) ++ " segment " ++ Nat.show(sg), pe_why(code), pe_fix(code))

def iabs(+c: I.I) -> I.I:
  +l = I.i_lo(c)
  +h = I.i_hi(c)
  +s = Bool.and(F64.is_le(l, 0.0f64), F64.is_le(0.0f64, h))
  I.I{Bool.pick(F64, s, 0.0f64, F64.min(F64.abs(l), F64.abs(h))), F64.max(F64.abs(l), F64.abs(h))}

def cr_i(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> I.I:
  I.iscale(I.of_ex(F.cr_ex(ax, ay, bx, by)), 0.5f64)

def pc_theta(+cx: F64, +cy: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> I.I:
  +c = I.of_ex(XE.orient2(cx, cy, ax, ay, bx, by))
  I.atan2q(iabs(c), I.of_ex(F.dot_ex(cx, cy, ax, ay, bx, by)))

def pc_sin(+cx: F64, +cy: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> I.I:
  +c = I.of_ex(XE.orient2(cx, cy, ax, ay, bx, by))
  I.idiv(iabs(c), I.isqrt(I.imul(I.of_ex(F.d2_ex(ax, ay, cx, cy)), I.of_ex(F.d2_ex(bx, by, cx, cy)))))

def arc_pc_area(p: F.Pc, +cx: F64, +cy: F64, +r: F64, +ccw: Bool) -> I.I:
  match p:
    case F.P_ln{ax, ay, bx, by}: cr_i(ax, ay, bx, by)
    case F.P_ar{+ax, +ay, px, py, w, +bx, +by}:
      +th = pc_theta(cx, cy, ax, ay, bx, by)
      +sg = I.iscale(I.imul(I.isq(I.ipt(r)), I.isub(th, pc_sin(cx, cy, ax, ay, bx, by))), 0.5f64)
      I.iadd(cr_i(ax, ay, bx, by), Bool.pick(I.I, ccw, sg, I.ineg(sg)))

def arc_pc_len(p: F.Pc, +cx: F64, +cy: F64, +r: F64) -> I.I:
  match p:
    case F.P_ln{ax, ay, bx, by}: I.isqrt(I.of_ex(F.d2_ex(ax, ay, bx, by)))
    case F.P_ar{+ax, +ay, px, py, w, +bx, +by}: I.imul(I.ipt(r), pc_theta(cx, cy, ax, ay, bx, by))

def arcs_area(ps: List<&2, F.Pc>, +cx: F64, +cy: F64, +r: F64, +ccw: Bool) -> I.I:
  match ps:
    case []: I.ipt(0.0f64)
    case p <> t: I.iadd(arc_pc_area(p, cx, cy, r, ccw), arcs_area(t, cx, cy, r, ccw))

def arcs_len(ps: List<&2, F.Pc>, +cx: F64, +cy: F64, +r: F64) -> I.I:
  match ps:
    case []: I.ipt(0.0f64)
    case p <> t: I.iadd(arc_pc_len(p, cx, cy, r), arcs_len(t, cx, cy, r))

def sg_area(s: F.Sg) -> I.I:
  match s:
    case F.G_ln{p}: arc_pc_area(p, 0.0f64, 0.0f64, 1.0f64, True{})
    case F.G_ar{cx, cy, r, ccw, ps}: arcs_area(ps, cx, cy, r, ccw)

def sg_len(s: F.Sg) -> I.I:
  match s:
    case F.G_ln{p}: arc_pc_len(p, 0.0f64, 0.0f64, 1.0f64)
    case F.G_ar{cx, cy, r, ccw, ps}: arcs_len(ps, cx, cy, r)

def sgs_area(ss: List<&2, F.Sg>) -> I.I:
  match ss:
    case []: I.ipt(0.0f64)
    case s <> t: I.iadd(sg_area(s), sgs_area(t))

def sgs_len(ss: List<&2, F.Sg>) -> I.I:
  match ss:
    case []: I.ipt(0.0f64)
    case s <> t: I.iadd(sg_len(s), sgs_len(t))

def lp_area(l: F.Lp) -> I.I:
  match l:
    case F.K_path{sgs}: sgs_area(sgs)
    case F.K_circ{cx, cy, r}: I.imul(I.pi_i(), I.isq(I.ipt(r)))

def lp_len(l: F.Lp) -> I.I:
  match l:
    case F.K_path{sgs}: sgs_len(sgs)
    case F.K_circ{cx, cy, r}: I.imul(I.iscale(I.pi_i(), 2.0f64), I.ipt(r))

def ilen(+mat: Bool, +lo: F64, +hi: F64) -> I.I:
  Bool.pick(I.I, mat, I.isub(I.ipt(hi), I.ipt(lo)), I.ipt(0.0f64))

def walls_h(ws: List<&2, BD.Wl>) -> I.I:
  match ws:
    case []: I.ipt(0.0f64)
    case w <> t:
      BD.Wl{lo, hi, ins} = w
      I.iadd(I.isub(I.ipt(hi), I.ipt(lo)), walls_h(t))

def acc_add(a: Acc, +v: I.I, +s: I.I, +p: I.I) -> Acc:
  Acc{+av, +aa, +ap} = a
  Acc{I.iadd(av, v), I.iadd(aa, s), I.iadd(ap, p)}

def ms_go(ds: List<&2, BD.Cd>, +tb: B.Tb<&2, BD.Cd>, +acc: Acc) -> Acc:
  match ds:
    case []: acc
    case +d <> t:
      +c = BD.cd_c(d)
      +l = BD.cl_lp(c)
      +a = lp_area(l)
      +pr = lp_len(l)
      +p = BD.cl_par(c)
      +has = Bool.not(Nat.is_eq(p, 0n))
      +pc = BD.cd_c(B.tb_get(BD.Cd, tb, U32.from_nat(Nat.sub(p, 1n))))
      +pm = Bool.and(has, BD.cl_mat(pc))
      +mat = BD.cl_mat(c)
      +v = I.imul(a, I.isub(ilen(mat, BD.cl_lo(c), BD.cl_hi(c)), ilen(pm, BD.cl_lo(pc), BD.cl_hi(pc))))
      +topn = Bool.pick(F64, Bool.and(mat, Bool.not(BD.cd_ttr(d))), 1.0f64, 0.0f64)
      +botn = Bool.pick(F64, Bool.and(mat, Bool.not(BD.cd_btr(d))), 1.0f64, 0.0f64)
      +tsub = Bool.pick(F64, Bool.and(pm, Bool.not(BD.cd_ttr(d))), 1.0f64, 0.0f64)
      +bsub = Bool.pick(F64, Bool.and(pm, Bool.not(BD.cd_btr(d))), 1.0f64, 0.0f64)
      +hz = I.iscale(a, F64.sub(F64.add(topn, botn), F64.add(tsub, bsub)))
      +wa = I.imul(pr, walls_h(BD.cd_ws(d)))
      ms_go(t, tb, acc_add(acc, v, I.iadd(hz, wa), I.imul(pr, I.iadd(walls_h(BD.cd_ws(d)), I.ipt(2.0f64)))))

def bb_pt(b: Bb, +x: F64, +y: F64) -> Bb:
  Bb{x0, x1, y0, y1, z0, z1} = b
  Bb{F64.min(x0, x), F64.max(x1, x), F64.min(y0, y), F64.max(y1, y), z0, z1}

def bb_pcs(ps: List<&2, F.Pc>, +b: Bb) -> Bb:
  match ps:
    case []: b
    case +p <> t: bb_pcs(t, bb_pt(b, F.pc_ax(p), F.pc_ay(p)))

def bb_lp(l: F.Lp, +b: Bb) -> Bb:
  match l:
    case F.K_path{sgs}: bb_pcs(F.sgs_pcs(sgs), b)
    case F.K_circ{+cx, +cy, +r}:
      bb_pt(bb_pt(b, I.dn(F64.sub(cx, r)), I.dn(F64.sub(cy, r))), I.up(F64.add(cx, r)), I.up(F64.add(cy, r)))

def bb_z(b: Bb, +lo: F64, +hi: F64) -> Bb:
  Bb{x0, x1, y0, y1, z0, z1} = b
  Bb{x0, x1, y0, y1, F64.min(z0, lo), F64.max(z1, hi)}

def bb_cells(cs: List<&2, BD.Cl>, +b: Bb) -> Bb:
  match cs:
    case []: b
    case +c <> t: bb_cells(t, Bool.pick(Bb, BD.cl_mat(c), bb_z(bb_lp(BD.cl_lp(c), b), BD.cl_lo(c), BD.cl_hi(c)), b))

def inf() -> F64:
  F64.div(1.0f64, 0.0f64)

def bb_empty() -> Bb:
  Bb{inf(), F64.neg(inf()), inf(), F64.neg(inf()), inf(), F64.neg(inf())}

def amax(+a: F64, +b: F64) -> F64:
  F64.max(F64.abs(a), F64.abs(b))

def bb_m(b: Bb) -> F64:
  Bb{x0, x1, y0, y1, z0, z1} = b
  F64.max(amax(x0, x1), F64.max(amax(y0, y1), amax(z0, z1)))

def bb_wid(b: Bb, +e: F64) -> Bb:
  Bb{x0, x1, y0, y1, z0, z1} = b
  Bb{I.dn(F64.sub(x0, e)), I.up(F64.add(x1, e)), I.dn(F64.sub(y0, e)), I.up(F64.add(y1, e)),
    I.dn(F64.sub(z0, e)), I.up(F64.add(z1, e))}

def br_counts(+b: Ty.Brep) -> List<&2, Nat>:
  +nf = List.length(&2, Ty.Face, Ty.brep_fas(b))
  [List.length(&2, Ty.Vertex, Ty.brep_vs(b)), List.length(&2, Ty.Edge, Ty.brep_es(b)), nf,
    List.length(&2, Ty.Loop, Ty.brep_lps(b)), List.length(&2, Ty.Shell, Ty.brep_shs(b)), List.length(&2, Ty.Solid, Ty.brep_sos(b))]

def nth_n(xs: List<&2, Nat>, +i: Nat) -> Nat:
  match xs:
    case []: 0n
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_n(t, j)

def genus_of(+b: Ty.Brep) -> Nat:
  +c = br_counts(b)
  +v = nth_n(c, 0n)
  +e = nth_n(c, 1n)
  +f = nth_n(c, 2n)
  +l = nth_n(c, 3n)
  +s = nth_n(c, 4n)
  +r = Nat.sub(l, f)
  Nat.div(Nat.sub(Nat.add(Nat.add(Nat.mul(2n, s), e), r), Nat.add(v, f)), 2n)

def pl_bb(b: Bb, p: Pl) -> Bb:
  Bb{+x0, +x1, +y0, +y1, +z0, +z1} = b
  Pl{m, +tx, +ty, +tz, mi, ti} = p
  V.M3{+a, +m2, +c, +d, +e, +f, +g, +h, +i} = m
  +px0 = F64.add(F64.add(F64.min(F64.mul(a, x0), F64.mul(a, x1)), F64.min(F64.mul(m2, y0), F64.mul(m2, y1))), F64.min(F64.mul(c, z0), F64.mul(c, z1)))
  +px1 = F64.add(F64.add(F64.max(F64.mul(a, x0), F64.mul(a, x1)), F64.max(F64.mul(m2, y0), F64.mul(m2, y1))), F64.max(F64.mul(c, z0), F64.mul(c, z1)))
  +py0 = F64.add(F64.add(F64.min(F64.mul(d, x0), F64.mul(d, x1)), F64.min(F64.mul(e, y0), F64.mul(e, y1))), F64.min(F64.mul(f, z0), F64.mul(f, z1)))
  +py1 = F64.add(F64.add(F64.max(F64.mul(d, x0), F64.mul(d, x1)), F64.max(F64.mul(e, y0), F64.mul(e, y1))), F64.max(F64.mul(f, z0), F64.mul(f, z1)))
  +pz0 = F64.add(F64.add(F64.min(F64.mul(g, x0), F64.mul(g, x1)), F64.min(F64.mul(h, y0), F64.mul(h, y1))), F64.min(F64.mul(i, z0), F64.mul(i, z1)))
  +pz1 = F64.add(F64.add(F64.max(F64.mul(g, x0), F64.mul(g, x1)), F64.max(F64.mul(h, y0), F64.mul(h, y1))), F64.max(F64.mul(i, z0), F64.mul(i, z1)))
  Bb{I.dn(F64.add(px0, tx)), I.up(F64.add(px1, tx)), I.dn(F64.add(py0, ty)), I.up(F64.add(py1, ty)),
    I.dn(F64.add(pz0, tz)), I.up(F64.add(pz1, tz))}

def ms_mk(acc: Acc, b: Bb, +lin: F64, +br: Ty.Brep) -> Ms:
  Acc{vol, +area, per} = acc
  Bb{x0, x1, y0, y1, z0, z1} = b
  +c = br_counts(br)
  Ms{I.iwiden(vol, F64.mul(I.i_hi(area), lin)), I.iwiden(area, F64.mul(I.i_hi(per), lin)), x0, x1, y0, y1, z0, z1,
    nth_n(c, 0n), nth_n(c, 1n), nth_n(c, 2n), nth_n(c, 5n), genus_of(br), lin}

def ipt_exact(xs: List<&2, I.I>) -> Bool:
  match xs:
    case []: True{}
    case +x <> t:
      Bool.and(Bool.and(F64.is_eq(I.i_lo(x), I.i_hi(x)), Bool.or(F64.is_eq(F64.abs(I.i_lo(x)), 1.0f64), F64.is_eq(I.i_lo(x), 0.0f64))), ipt_exact(t))

def pl_exact(p: Pl) -> Bool:
  Pl{m, tx, ty, tz, mi, ti} = p
  ipt_exact(mi)

def i_nth(xs: List<&2, I.I>, +i: Nat) -> I.I:
  match xs:
    case []: I.ipt(F64.nan())
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: i_nth(t, j)

def pl_mi(p: Pl) -> List<&2, I.I>:
  Pl{m, tx, ty, tz, mi, ti} = p
  mi

def pl_ti(p: Pl) -> List<&2, I.I>:
  Pl{m, tx, ty, tz, mi, ti} = p
  ti

def bb_iv(b: Bb, +x: I.I, +y: I.I, +z: I.I) -> Bb:
  Bb{x0, x1, y0, y1, z0, z1} = b
  Bb{F64.min(x0, I.i_lo(x)), F64.max(x1, I.i_hi(x)), F64.min(y0, I.i_lo(y)), F64.max(y1, I.i_hi(y)),
    F64.min(z0, I.i_lo(z)), F64.max(z1, I.i_hi(z))}

def ext_add(+c: I.I, +e: I.I) -> I.I:
  I.I{I.dn(F64.sub(I.i_lo(c), I.i_hi(e))), I.up(F64.add(I.i_hi(c), I.i_hi(e)))}

def row_h(+mi: List<&2, I.I>, +r: Nat) -> I.I:
  +k = Nat.mul(r, 3n)
  I.isqrt(I.iadd(I.isq(i_nth(mi, k)), I.isq(i_nth(mi, Nat.add(k, 1n)))))

def row_n(+mi: List<&2, I.I>, +r: Nat) -> I.I:
  +k = Nat.mul(r, 3n)
  I.isqrt(I.iadd(I.iadd(I.isq(i_nth(mi, k)), I.isq(i_nth(mi, Nat.add(k, 1n)))), I.isq(i_nth(mi, Nat.add(k, 2n)))))

def is_pt(+a: I.I) -> Bool:
  F64.is_eq(I.i_lo(a), I.i_hi(a))

def pmul(+a: I.I, +b: I.I) -> I.I:
  +x = I.i_lo(a)
  +y = I.i_lo(b)
  +p = F64.mul(x, y)
  Bool.pick(I.I, Bool.and(Bool.and(is_pt(a), is_pt(b)), F64.is_eq(F64.fma(x, y, F64.neg(p)), 0.0f64)), I.ipt(p), I.imul(a, b))

def padd(+a: I.I, +b: I.I) -> I.I:
  +x = I.i_lo(a)
  +y = I.i_lo(b)
  +s = F64.add(x, y)
  +big = Bool.pick(F64, F64.is_le(F64.abs(y), F64.abs(x)), x, y)
  +small = Bool.pick(F64, F64.is_le(F64.abs(y), F64.abs(x)), y, x)
  Bool.pick(I.I, Bool.and(Bool.and(is_pt(a), is_pt(b)), F64.is_eq(F64.sub(s, big), small)), I.ipt(s), I.iadd(a, b))

def i_dot3(+a: List<&2, I.I>, +r: Nat, +b: List<&2, I.I>, +c: Nat, +st: Nat) -> I.I:
  +k = Nat.mul(r, 3n)
  padd(padd(pmul(i_nth(a, k), i_nth(b, c)), pmul(i_nth(a, Nat.add(k, 1n)), i_nth(b, Nat.add(c, st)))),
    pmul(i_nth(a, Nat.add(k, 2n)), i_nth(b, Nat.add(c, Nat.mul(2n, st)))))

def im_ap(+a: List<&2, I.I>, +v: List<&2, I.I>) -> List<&2, I.I>:
  [i_dot3(a, 0n, v, 0n, 1n), i_dot3(a, 1n, v, 0n, 1n), i_dot3(a, 2n, v, 0n, 1n)]

def gp_go(+mi: List<&2, I.I>, +ti: List<&2, I.I>, +x: F64, +y: F64, +z: F64) -> List<&2, I.I>:
  +w = im_ap(mi, [I.ipt(x), I.ipt(y), I.ipt(z)])
  [I.iadd(i_nth(w, 0n), i_nth(ti, 0n)), I.iadd(i_nth(w, 1n), i_nth(ti, 1n)), I.iadd(i_nth(w, 2n), i_nth(ti, 2n))]

def bb_gtor(b: Bb, +p: Pl, +cx: F64, +cy: F64, +cz: F64, +big: F64, +r: F64) -> Bb:
  +mi = pl_mi(p)
  +w = gp_go(mi, pl_ti(p), cx, cy, cz)
  +bi = I.ipt(F64.abs(big))
  +ri = I.ipt(F64.abs(r))
  bb_iv(b, ext_add(i_nth(w, 0n), I.iadd(I.imul(bi, row_h(mi, 0n)), I.imul(ri, row_n(mi, 0n)))),
    ext_add(i_nth(w, 1n), I.iadd(I.imul(bi, row_h(mi, 1n)), I.imul(ri, row_n(mi, 1n)))),
    ext_add(i_nth(w, 2n), I.iadd(I.imul(bi, row_h(mi, 2n)), I.imul(ri, row_n(mi, 2n)))))

def bb_gpt(b: Bb, +p: Pl, +x: F64, +y: F64, +z: F64) -> Bb:
  +w = gp_go(pl_mi(p), pl_ti(p), x, y, z)
  bb_iv(b, i_nth(w, 0n), i_nth(w, 1n), i_nth(w, 2n))

def bb_gsg(b: Bb, s: F.Sg, +p: Pl, +lo: F64, +hi: F64) -> Bb:
  match s:
    case F.G_ln{+q}:
      +ax = F.pc_ax(q)
      +ay = F.pc_ay(q)
      +bx = F.pc_bx(q)
      +by = F.pc_by(q)
      bb_gpt(bb_gpt(bb_gpt(bb_gpt(b, p, ax, ay, lo), p, ax, ay, hi), p, bx, by, lo), p, bx, by, hi)
    case F.G_ar{+cx, +cy, +r, ccw, ps}: bb_gtor(bb_gtor(b, p, cx, cy, lo, r, 0.0f64), p, cx, cy, hi, r, 0.0f64)

def bb_gsgs(ss: List<&2, F.Sg>, +b: Bb, +p: Pl, +lo: F64, +hi: F64) -> Bb:
  match ss:
    case []: b
    case s <> t: bb_gsgs(t, bb_gsg(b, s, p, lo, hi), p, lo, hi)

def bb_glp(l: F.Lp, +b: Bb, +p: Pl, +lo: F64, +hi: F64) -> Bb:
  match l:
    case F.K_path{sgs}: bb_gsgs(sgs, b, p, lo, hi)
    case F.K_circ{+cx, +cy, +r}: bb_gtor(bb_gtor(b, p, cx, cy, lo, r, 0.0f64), p, cx, cy, hi, r, 0.0f64)

def bb_gcells(cs: List<&2, BD.Cl>, +b: Bb, +p: Pl) -> Bb:
  match cs:
    case []: b
    case +c <> t: bb_gcells(t, Bool.pick(Bb, BD.cl_mat(c), bb_glp(BD.cl_lp(c), b, p, BD.cl_lo(c), BD.cl_hi(c)), b), p)

def prism_ms(bd: Body) -> Ms:
  Bd{+cells, brep, fns, +pl, rv} = bd
  +ds = BD.cds_of(cells)
  +tb = B.tb_of(BD.Cd, ds, BD.cd_pad())
  +acc = ms_go(ds, tb, Acc{I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(0.0f64)})
  +bb0 = bb_cells(cells, bb_empty())
  +lin = F64.mul(bb_m(bb0), 1.7763568394002505e-15f64)
  ms_mk(acc, Bool.pick(Bb, pl_exact(pl), pl_bb(bb_wid(bb0, lin), pl), bb_wid(bb_gcells(cells, bb_empty(), pl), F64.mul(2.0f64, lin))), lin, brep)

def bd_rv(b: Body) -> List<&2, F.Lp>:
  Bd{cells, brep, fns, pl, rv} = b
  rv

def bd_pl(b: Body) -> Pl:
  Bd{cells, brep, fns, pl, rv} = b
  pl

def bd_brep(b: Body) -> Ty.Brep:
  Bd{cells, brep, fns, pl, rv} = b
  brep

def r_line(+ax: F64, +ay: F64, +bx: F64, +by: F64) -> I.I:
  +ra = I.ipt(ax)
  +rb = I.ipt(bx)
  I.idiv(I.imul(I.isub(I.ipt(by), I.ipt(ay)), I.iadd(I.iadd(I.isq(ra), I.imul(ra, rb)), I.isq(rb))), I.ipt(6.0f64))

def r_seg(+cx: F64, +cy: F64, +r: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +ccw: Bool) -> I.I:
  +th = pc_theta(cx, cy, ax, ay, bx, by)
  +aseg = I.iscale(I.imul(I.isq(I.ipt(r)), I.isub(th, pc_sin(cx, cy, ax, ay, bx, by))), 0.5f64)
  +half = I.idiv(I.isqrt(I.of_ex(F.d2_ex(ax, ay, bx, by))), I.ipt(F64.mul(2.0f64, r)))
  +sx = I.of_ex(E.ex_add(E.ex_dif(ax, cx), E.ex_dif(bx, cx)))
  +sy = I.of_ex(E.ex_add(E.ex_dif(ay, cy), E.ex_dif(by, cy)))
  +bxu = I.idiv(sx, I.isqrt(I.iadd(I.isq(sx), I.isq(sy))))
  +cub = I.imul(I.imul(half, half), half)
  +t = I.iadd(I.imul(aseg, I.ipt(cx)), I.imul(I.iscale(I.imul(I.imul(I.isq(I.ipt(r)), I.ipt(r)), cub), F64.div(2.0f64, 3.0f64)), bxu))
  I.iadd(r_line(ax, ay, bx, by), Bool.pick(I.I, ccw, t, I.ineg(t)))

def r_pc(p: F.Pc, +cx: F64, +cy: F64, +r: F64, +ccw: Bool) -> I.I:
  match p:
    case F.P_ln{ax, ay, bx, by}: r_line(ax, ay, bx, by)
    case F.P_ar{ax, ay, px, py, w, bx, by}: r_seg(cx, cy, r, ax, ay, bx, by, ccw)

def a_pc(p: F.Pc, +cx: F64, +cy: F64, +r: F64, +ccw: Bool) -> I.I:
  match p:
    case F.P_ln{+ax, ay, +bx, by}:
      I.iscale(I.imul(I.isqrt(I.of_ex(F.d2_ex(ax, ay, bx, by))), I.iadd(I.ipt(ax), I.ipt(bx))), 0.5f64)
    case F.P_ar{+ax, +ay, px, py, w, +bx, +by}:
      +th = pc_theta(cx, cy, ax, ay, bx, by)
      +dy = I.isub(I.ipt(by), I.ipt(ay))
      I.iadd(I.imul(I.imul(I.ipt(r), I.ipt(cx)), th), I.imul(I.ipt(r), Bool.pick(I.I, ccw, dy, I.ineg(dy))))

def rpcs(ps: List<&2, F.Pc>, +cx: F64, +cy: F64, +r: F64, +ccw: Bool, +area: Bool) -> I.I:
  match ps:
    case []: I.ipt(0.0f64)
    case +p <> t:
      I.iadd(Bool.pick(I.I, area, Bool.pick(I.I, RV.pc_axis(p), I.ipt(0.0f64), a_pc(p, cx, cy, r, ccw)), r_pc(p, cx, cy, r, ccw)),
        rpcs(t, cx, cy, r, ccw, area))

def rsg(s: F.Sg, +area: Bool) -> I.I:
  match s:
    case F.G_ln{p}: rpcs([p], 0.0f64, 0.0f64, 1.0f64, True{}, area)
    case F.G_ar{cx, cy, r, ccw, ps}: rpcs(ps, cx, cy, r, ccw, area)

def rsgs(ss: List<&2, F.Sg>, +area: Bool) -> I.I:
  match ss:
    case []: I.ipt(0.0f64)
    case s <> t: I.iadd(rsg(s, area), rsgs(t, area))

def rlps(ls: List<&2, F.Lp>, +area: Bool) -> I.I:
  match ls:
    case []: I.ipt(0.0f64)
    case l <> t: I.iadd(rsgs(RV.lp_sgs(l), area), rlps(t, area))

def rbb_pcs(ps: List<&2, F.Pc>, +b: Bb) -> Bb:
  match ps:
    case []: b
    case +p <> t:
      +x = F.pc_ax(p)
      +y = F.pc_ay(p)
      rbb_pcs(t, bb_z(bb_pt(bb_pt(b, x, x), F64.neg(x), F64.neg(x)), y, y))

def rbb(ls: List<&2, F.Lp>, +b: Bb) -> Bb:
  match ls:
    case []: b
    case l <> t: rbb(t, rbb_pcs(F.lp_pcs(l), b))

def rbb_gsg(b: Bb, s: F.Sg, +p: Pl) -> Bb:
  match s:
    case F.G_ln{+q}:
      bb_gtor(bb_gtor(b, p, 0.0f64, 0.0f64, F.pc_ay(q), F.pc_ax(q), 0.0f64), p, 0.0f64, 0.0f64, F.pc_by(q), F.pc_bx(q), 0.0f64)
    case F.G_ar{+cx, +cy, +r, ccw, ps}: bb_gtor(b, p, 0.0f64, 0.0f64, cy, cx, r)

def rbb_gsgs(ss: List<&2, F.Sg>, +b: Bb, +p: Pl) -> Bb:
  match ss:
    case []: b
    case s <> t: rbb_gsgs(t, rbb_gsg(b, s, p), p)

def rbb_glps(ls: List<&2, F.Lp>, +b: Bb, +p: Pl) -> Bb:
  match ls:
    case []: b
    case l <> t:
      match l:
        case F.K_path{sgs}: rbb_glps(t, rbb_gsgs(sgs, b, p), p)
        case F.K_circ{+cx, +cy, +r}: rbb_glps(t, bb_gtor(b, p, 0.0f64, 0.0f64, cy, cx, r), p)

def rev_ms(+rv: List<&2, F.Lp>, +br: Ty.Brep, +pl: Pl) -> Ms:
  +tp = I.iscale(I.pi_i(), 2.0f64)
  +vol = I.imul(tp, rlps(rv, False{}))
  +area = I.imul(tp, rlps(rv, True{}))
  +bb0 = rbb(rv, bb_empty())
  +lin = F64.mul(bb_m(bb0), 1.7763568394002505e-15f64)
  +bb = Bool.pick(Bb, pl_exact(pl), pl_bb(bb_wid(bb0, lin), pl), bb_wid(rbb_glps(rv, bb_empty(), pl), F64.mul(2.0f64, lin)))
  ms_mk(Acc{vol, area, I.ipt(F64.mul(4.0f64, F64.mul(bb_m(bb0), 100.0f64)))}, bb, lin, br)

def body_ms(+bd: Body) -> Ms:
  Bool.pick(Ms, Nat.is_eq(List.length(&2, F.Lp, bd_rv(bd)), 0n), prism_ms(bd), rev_ms(bd_rv(bd), bd_brep(bd), bd_pl(bd)))

def xk(+v: F64) -> X.Xp:
  X.X_k{v}

def rect_rg(+x: X.Xp, +y: X.Xp) -> F.Region:
  F.Rg{F.L_path{xk(0.0f64), xk(0.0f64), [F.S_line{x, xk(0.0f64)}, F.S_line{x, y}, F.S_line{xk(0.0f64), y}]}, []}

def circ_rg(+r: X.Xp) -> F.Region:
  F.Rg{F.L_circ{xk(0.0f64), xk(0.0f64), r}, []}

def hl_rg(h: Hl) -> F.Region:
  Hl{x, y, r} = h
  F.Rg{F.L_circ{x, y, r}, []}

def hls_rgs(hs: List<&2, Hl>) -> List<&2, F.Region>:
  match hs:
    case []: []
    case h <> t: hl_rg(h) <> hls_rgs(t)

def rl_mat(r: F.Rl) -> Bool:
  match r:
    case F.K_hole{o}: False{}
    case _: True{}

def cells_new(ls: List<&2, F.Lp>, ps: List<&2, Nat>, rls: List<&2, F.Rl>, +base: Nat, +nd: U64, +k: Nat,
    +lo1: F64, +hi1: F64, +m1: Bool, +lo0: F64, +hi0: F64, +m0: Bool) -> List<&2, BD.Cl>:
  match ls:
    case []: []
    case l <> t:
      match ps:
        case []: []
        case +p <> pt:
          match rls:
            case []: []
            case +r <> rt:
              +ins = rl_mat(r)
              BD.Cl{Nat.add(base, k), p, nd, k, l, Bool.pick(Bool, ins, m1, m0), Bool.pick(F64, ins, lo1, lo0),
                Bool.pick(F64, ins, hi1, hi0)} <> cells_new(t, pt, rt, base, nd, Nat.add(k, 1n), lo1, hi1, m1, lo0, hi0, m0)

def chk_fin2(+a: F64, +b: F64) -> Bool:
  Bool.and(T.is_finite(a), Bool.and(T.is_finite(b), F64.is_lt(a, b)))

def fuel_of(+b: Ty.Brep) -> Nat:
  Nat.add(Nat.mul(4n, Nat.add(List.length(&2, Ty.Coedge, Ty.brep_ces(b)), List.length(&2, Ty.Vertex, Ty.brep_vs(b)))), 64n)

def stage_why(+c: U64) -> String:
  match c:
    case 2u64: "incidence"
    case 3u64: "edge-use"
    case 4u64: "loop-closure-or-trim"
    case 5u64: "face-kind"
    case 6u64: "ownership"
    case 7u64: "embedding"
    case 8u64: "vertex-link"
    case 9u64: "shell-connectivity"
    case 10u64: "coincident-vertices"
    case 11u64: "segment-crossing"
    case 12u64: "orientation"
    case _: "stage-unknown"

def okc(+c: Nat, +s: U64) -> U64:
  Bool.pick(U64, Ty.okd_ok(c), 0u64, s)

def pk0(+a: U64, +b: U64) -> U64:
  Bool.pick(U64, U64.is_eq(a, 0u64), b, a)

def stage_of(+b: Ty.Brep, +fuel: Nat) -> U64:
  pk0(okc(B4.brep_incid_c(b, fuel), 2u64), pk0(okc(B4.brep_use_c(b, Ty.P_manifold_solid{}, fuel), 3u64),
    pk0(okc(B4.brep_loop_c(b, fuel), 4u64), pk0(okc(B4.brep_facekind_c(b, fuel), 5u64),
      pk0(okc(B4.brep_prof_c(b, Ty.P_manifold_solid{}, fuel), 6u64), pk0(okc(B4.brep_embed_c(b, fuel), 7u64),
        pk0(okc(B4.brep_link_c(b, Ty.P_manifold_solid{}, fuel), 8u64), pk0(okc(B4.brep_conn_c(b, fuel), 9u64),
          pk0(okc(B4.brep_coin_c(b, fuel), 10u64), pk0(okc(B4.brep_xing_c(b, fuel), 11u64),
            okc(B4.brep_orient_c(b, fuel), 12u64)))))))))))

def ck_go(ok: Bool, +b: Ty.Brep, +fns: List<&2, BD.Fn>, +cs: List<&2, BD.Cl>, +pl: Pl, +what: String, +rv: List<&2, F.Lp>) -> NR:
  match ok:
    case True{}: NR_ok{Bd{cs, b, fns, pl, rv}, Fx{M_same{}, 0n, 0n, 0n, 0n}}
    case False{}:
      nr_err(T.F_uncertain{}, what, "brep stage " ++ stage_why(stage_of(b, fuel_of(b))),
        "the built boundary failed validation; no geometry is published", "report this design")

def tres_ok(r: Ty.TRes) -> Bool:
  match r:
    case Ty.Tok{v}: True{}
    case Ty.Terr{k}: False{}

def bt_check(bt: BD.Bt, +cs: List<&2, BD.Cl>, +pl: Pl, +what: String, +rv: List<&2, F.Lp>) -> NR:
  BD.Bt{+b, +fns} = bt
  ck_go(tres_ok(B4.brep_checked(b, Ty.P_manifold_solid{}, fuel_of(b))), b, fns, cs, pl, what, rv)

def body_of_cells(+cs: List<&2, BD.Cl>, +pl: Pl, +what: String) -> NR:
  +bt = BD.build(cs)
  bt_check(bt, cs, pl, what, [])

def prism_ck(c: F.CK, +rls: List<&2, F.Rl>, +nd: U64, +z0: F64, +z1: F64) -> NR:
  match c:
    case F.CK_err{e}: pe_nr(e, "prism profile")
    case F.CK_ok{ls, ps}:
      body_of_cells(cells_new(ls, ps, rls, 0n, nd, 0n, z0, z1, True{}, 0.0f64, 0.0f64, False{}), pl_id(), "prism")

def prism_go(ok: Bool, +rs: List<&2, F.Region>, +e: X.Env, +nd: U64, +z0: F64, +z1: F64) -> NR:
  match ok:
    case False{}: bad("prism heights", "node " ++ U64.show(nd), "need finite z0 < z1", "set z0 below z1")
    case True{}:
      +rls = F.rg_rls(rs, 0n, F.K_free{})
      prism_ck(F.prof_check(rs, e), rls, nd, z0, z1)

def op_prism(+rs: List<&2, F.Region>, +z0: X.Xp, +z1: X.Xp, +e: X.Env, +nd: U64) -> NR:
  +a = X.xp_ev(z0, e)
  +b = X.xp_ev(z1, e)
  prism_go(chk_fin2(a, b), rs, e, nd, a, b)

def find_cell(cs: List<&2, BD.Cd>, +nd: U64, +k: Nat) -> Nat:
  match cs:
    case []: 0n
    case +d <> t:
      +c = BD.cd_c(d)
      Bool.pick(Nat, Bool.and(U64.is_eq(BD.cl_nd(c), nd), Nat.is_eq(BD.cl_k(c), k)), Nat.add(BD.cl_id(c), 1n),
        find_cell(t, nd, k))

def kid_lps(cs: List<&2, BD.Cl>, +pid: Nat) -> List<&2, F.Lp>:
  match cs:
    case []: []
    case +c <> t:
      +r = kid_lps(t, pid)
      Bool.pick(List<&2, F.Lp>, Nat.is_eq(BD.cl_par(c), pid), BD.cl_lp(c) <> r, r)

def obst_rls(n: Nat) -> List<&2, F.Rl>:
  match n:
    case 0n: []
    case 1n+m: F.K_obst{0n} <> obst_rls(m)

def rl_shift(rs: List<&2, F.Rl>, +s: Nat) -> List<&2, F.Rl>:
  match rs:
    case []: []
    case r <> +t:
      match r:
        case F.K_hole{o}: F.K_hole{Nat.add(o, s)} <> rl_shift(t, s)
        case F.K_in{c}: F.K_in{c} <> rl_shift(t, s)
        case F.K_free{}: F.K_in{0n} <> rl_shift(t, s)
        case F.K_root{}: F.K_root{} <> rl_shift(t, s)
        case F.K_obst{c}: F.K_obst{c} <> rl_shift(t, s)

def lp_drop(ls: List<&2, F.Lp>, +n: Nat) -> List<&2, F.Lp>:
  match ls:
    case []: []
    case l <> +t:
      match n:
        case 0n: l <> t
        case 1n+m: lp_drop(t, m)

def n_drop(ls: List<&2, Nat>, +n: Nat) -> List<&2, Nat>:
  match ls:
    case []: []
    case l <> +t:
      match n:
        case 0n: l <> t
        case 1n+m: n_drop(t, m)

def rl_drop(ls: List<&2, F.Rl>, +n: Nat) -> List<&2, F.Rl>:
  match ls:
    case []: []
    case l <> +t:
      match n:
        case 0n: l <> t
        case 1n+m: rl_drop(t, m)

def par_map(ps: List<&2, Nat>, +opar: Nat, +m1: Nat, +base: Nat) -> List<&2, Nat>:
  match ps:
    case []: []
    case +p <> t:
      Bool.pick(Nat, Nat.is_eq(p, 1n), opar, Nat.add(base, Nat.sub(p, m1))) <> par_map(t, opar, m1, base)

def feat_ck(c: F.CK, +rls: List<&2, F.Rl>, +m1: Nat, +opar: Nat, +cs: List<&2, BD.Cl>, +nd: U64,
    +lo1: F64, +hi1: F64, +mat1: Bool, +lo0: F64, +hi0: F64, +pl: Pl, +what: String) -> NR:
  match c:
    case F.CK_err{e}: pe_nr(e, what ++ " footprint")
    case F.CK_ok{+ls, +ps}:
      +base = List.length(&2, BD.Cl, cs)
      body_of_cells(List.append(&2, BD.Cl, cs, cells_new(lp_drop(ls, m1), par_map(n_drop(ps, m1), opar, m1, base),
        rl_drop(rls, m1), base, nd, 0n, lo1, hi1, mat1, lo0, hi0, True{})), pl, what)

def feat_ev(r: F.EV, +o: BD.Cl, +cs: List<&2, BD.Cl>, +rs: List<&2, F.Region>, +nd: U64, +lo1: F64, +hi1: F64,
    +mat1: Bool, +pl: Pl, +what: String) -> NR:
  match r:
    case F.EV_err{e}: pe_nr(e, what ++ " footprint")
    case F.EV_ok{fls}:
      +id1 = Nat.add(BD.cl_id(o), 1n)
      +kids = kid_lps(cs, id1)
      +nk = List.length(&2, F.Lp, kids)
      +m1 = Nat.add(nk, 1n)
      +rls = List.append(&2, F.Rl, F.K_root{} <> obst_rls(nk), rl_shift(F.rg_rls(rs, 0n, F.K_free{}), m1))
      feat_ck(F.check(List.append(&2, F.Lp, BD.cl_lp(o) <> kids, fls), rls), rls, m1, id1, cs, nd, lo1, hi1,
        mat1, BD.cl_lo(o), BD.cl_hi(o), pl, what)

def bd_cells(b: Body) -> List<&2, BD.Cl>:
  Bd{cells, brep, fns, pl, rv} = b
  cells

def bd_fns(b: Body) -> List<&2, BD.Fn>:
  Bd{cells, brep, fns, pl, rv} = b
  fns

def ivl(+kind: U64, +side: U64, +lo: F64, +hi: F64, +a: F64, +thru: Bool) -> List<&2, F64>:
  match kind:
    case 0u64: Bool.pick(List<&2, F64>, U64.is_eq(side, 0u64), [lo, F64.add(hi, a), 1.0f64], [F64.sub(lo, a), hi, 1.0f64])
    case _:
      Bool.pick(List<&2, F64>, thru, [0.0f64, 0.0f64, 0.0f64],
        Bool.pick(List<&2, F64>, U64.is_eq(side, 0u64), [lo, F64.sub(hi, a), 1.0f64], [F64.add(lo, a), hi, 1.0f64]))

def f_nth(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: 0.0f64
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: f_nth(t, j)

def kind_what(+kind: U64) -> String:
  match kind:
    case 0u64: "pad"
    case 1u64: "pocket"
    case _: "holes"

def feat_go(code: U64, +o: BD.Cl, +cs: List<&2, BD.Cl>, +rs: List<&2, F.Region>, +e: X.Env, +nd: U64,
    +iv: List<&2, F64>, +pl: Pl, +kind: U64) -> NR:
  match code:
    case 0u64:
      feat_ev(F.loops_ev(F.rg_loops(rs), e, 0n), o, cs, rs, nd, f_nth(iv, 0n), f_nth(iv, 1n),
        F64.is_eq(f_nth(iv, 2n), 1.0f64), pl, kind_what(kind))
    case 1u64: bad(kind_what(kind), "node " ++ U64.show(nd), "face-not-found", "select a face by its creating node, cell and side")
    case 5u64: nr_err(T.F_unsupported{}, kind_what(kind), "node " ++ U64.show(nd), "features-need-an-extruded-body",
      "features act on prism, box and cylinder bodies along z; other placements need booleans (C08)")
    case 2u64: bad(kind_what(kind), "node " ++ U64.show(nd), "no-such-face", "that cell's top or bottom is part of another face; select the owning cell")
    case 3u64: bad(kind_what(kind), "node " ++ U64.show(nd), "nonpositive-amount", "use a positive finite height or depth")
    case _: bad(kind_what(kind), "node " ++ U64.show(nd), "depth-reaches-opposite-face", "use a smaller depth or a through cut")

def op_feat(+kind: U64, +b: Body, +s: Sel, +rs: List<&2, F.Region>, +amt: X.Xp, +thru: Bool, +e: X.Env, +nd: U64) -> NR:
  Sel{+snd, +sk, +side} = s
  +cs = bd_cells(b)
  +ds = BD.cds_of(cs)
  +ix = find_cell(ds, snd, sk)
  +d = B.tb_get(BD.Cd, B.tb_of(BD.Cd, ds, BD.cd_pad()), U32.from_nat(Nat.sub(ix, 1n)))
  +o = BD.cd_c(d)
  +owner = Bool.and(BD.cl_mat(o), Bool.not(Bool.pick(Bool, U64.is_eq(side, 0u64), BD.cd_ttr(d), BD.cd_btr(d))))
  +a = X.xp_ev(amt, e)
  +aok = Bool.or(Bool.and(thru, Bool.not(U64.is_eq(kind, 0u64))), Bool.and(T.is_finite(a), F64.is_lt(0.0f64, a)))
  +iv = ivl(kind, side, BD.cl_lo(o), BD.cl_hi(o), a, thru)
  +nonempty = Bool.or(F64.is_eq(f_nth(iv, 2n), 0.0f64), F64.is_lt(f_nth(iv, 0n), f_nth(iv, 1n)))
  +code = Bool.pick(U64, Nat.is_eq(List.length(&2, BD.Cl, cs), 0n), 5u64, Bool.pick(U64, Nat.is_eq(ix, 0n), 1u64, Bool.pick(U64, Bool.not(owner), 2u64,
    Bool.pick(U64, Bool.not(aok), 3u64, Bool.pick(U64, Bool.not(nonempty), 4u64, 0u64)))))
  feat_go(code, o, cs, rs, e, nd, iv, bd_pl(b), kind)

def q_mat(+q: U64) -> V.Mat3:
  match q:
    case 1u64: V.M3{0.0f64, F64.neg(1.0f64), 0.0f64, 1.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64}
    case 2u64: V.M3{F64.neg(1.0f64), 0.0f64, 0.0f64, 0.0f64, F64.neg(1.0f64), 0.0f64, 0.0f64, 0.0f64, 1.0f64}
    case 3u64: V.M3{0.0f64, 1.0f64, 0.0f64, F64.neg(1.0f64), 0.0f64, 0.0f64, 0.0f64, 0.0f64, 1.0f64}
    case 4u64: V.M3{1.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, F64.neg(1.0f64), 0.0f64, 1.0f64, 0.0f64}
    case 5u64: V.M3{0.0f64, 0.0f64, 1.0f64, 0.0f64, 1.0f64, 0.0f64, F64.neg(1.0f64), 0.0f64, 0.0f64}
    case _: m3_id()

def m3_mul(a: V.Mat3, b: V.Mat3) -> V.Mat3:
  V.M3{+a0, +a1, +a2, +a3, +a4, +a5, +a6, +a7, +a8} = a
  V.M3{+b0, +b1, +b2, +b3, +b4, +b5, +b6, +b7, +b8} = b
  V.M3{F64.add(F64.add(F64.mul(a0, b0), F64.mul(a1, b3)), F64.mul(a2, b6)),
    F64.add(F64.add(F64.mul(a0, b1), F64.mul(a1, b4)), F64.mul(a2, b7)),
    F64.add(F64.add(F64.mul(a0, b2), F64.mul(a1, b5)), F64.mul(a2, b8)),
    F64.add(F64.add(F64.mul(a3, b0), F64.mul(a4, b3)), F64.mul(a5, b6)),
    F64.add(F64.add(F64.mul(a3, b1), F64.mul(a4, b4)), F64.mul(a5, b7)),
    F64.add(F64.add(F64.mul(a3, b2), F64.mul(a4, b5)), F64.mul(a5, b8)),
    F64.add(F64.add(F64.mul(a6, b0), F64.mul(a7, b3)), F64.mul(a8, b6)),
    F64.add(F64.add(F64.mul(a6, b1), F64.mul(a7, b4)), F64.mul(a8, b7)),
    F64.add(F64.add(F64.mul(a6, b2), F64.mul(a7, b5)), F64.mul(a8, b8))}

def m3_ap(m: V.Mat3, +x: F64, +y: F64, +z: F64) -> List<&2, F64>:
  V.M3{+a0, +a1, +a2, +a3, +a4, +a5, +a6, +a7, +a8} = m
  [F64.add(F64.add(F64.mul(a0, x), F64.mul(a1, y)), F64.mul(a2, z)),
    F64.add(F64.add(F64.mul(a3, x), F64.mul(a4, y)), F64.mul(a5, z)),
    F64.add(F64.add(F64.mul(a6, x), F64.mul(a7, y)), F64.mul(a8, z))]

def m3_l(m: V.Mat3) -> List<&2, F64>:
  V.M3{a0, a1, a2, a3, a4, a5, a6, a7, a8} = m
  [a0, a1, a2, a3, a4, a5, a6, a7, a8]

def im_mul(+a: List<&2, I.I>, +b: List<&2, I.I>) -> List<&2, I.I>:
  [i_dot3(a, 0n, b, 0n, 3n), i_dot3(a, 0n, b, 1n, 3n), i_dot3(a, 0n, b, 2n, 3n),
    i_dot3(a, 1n, b, 0n, 3n), i_dot3(a, 1n, b, 1n, 3n), i_dot3(a, 1n, b, 2n, 3n),
    i_dot3(a, 2n, b, 0n, 3n), i_dot3(a, 2n, b, 1n, 3n), i_dot3(a, 2n, b, 2n, 3n)]

def pl_move(p: Pl, +q: U64, +dx: F64, +dy: F64, +dz: F64) -> Pl:
  Pl{m, tx, ty, tz, mi, +ti} = p
  +r = q_mat(q)
  +t = m3_ap(r, tx, ty, tz)
  +ri = ipts(m3_l(r))
  +tr = im_ap(ri, ti)
  Pl{m3_mul(r, m), F64.add(f_nth(t, 0n), dx), F64.add(f_nth(t, 1n), dy), F64.add(f_nth(t, 2n), dz), im_mul(ri, mi),
    [padd(i_nth(tr, 0n), I.ipt(dx)), padd(i_nth(tr, 1n), I.ipt(dy)), padd(i_nth(tr, 2n), I.ipt(dz))]}

def imid(+a: I.I) -> F64:
  F64.add(F64.mul(0.5f64, I.i_lo(a)), F64.mul(0.5f64, I.i_hi(a)))

def rot_im(+ax: U64, +c: I.I, +s: I.I) -> List<&2, I.I>:
  +o = I.ipt(1.0f64)
  +z = I.ipt(0.0f64)
  Bool.pick(List<&2, I.I>, U64.is_eq(ax, 0u64), [o, z, z, z, c, I.ineg(s), z, s, c],
    Bool.pick(List<&2, I.I>, U64.is_eq(ax, 1u64), [c, z, s, z, o, z, I.ineg(s), z, c], [c, I.ineg(s), z, s, c, z, z, z, o]))

def im_mid(xs: List<&2, I.I>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> t: imid(x) <> im_mid(t)

def m3_of(+xs: List<&2, F64>) -> V.Mat3:
  V.M3{f_nth(xs, 0n), f_nth(xs, 1n), f_nth(xs, 2n), f_nth(xs, 3n), f_nth(xs, 4n), f_nth(xs, 5n), f_nth(xs, 6n), f_nth(xs, 7n), f_nth(xs, 8n)}

def pl_rot(p: Pl, +ax: U64, +sc: List<&2, I.I>) -> Pl:
  Pl{m, tx, ty, tz, mi, ti} = p
  +ri = rot_im(ax, i_nth(sc, 0n), i_nth(sc, 1n))
  +r = m3_of(im_mid(ri))
  +t = m3_ap(r, tx, ty, tz)
  Pl{m3_mul(r, m), f_nth(t, 0n), f_nth(t, 1n), f_nth(t, 2n), im_mul(ri, mi), im_ap(ri, ti)}

def op_move(+b: Body, +tx: X.Xp, +ty: X.Xp, +tz: X.Xp, +q: U64, +e: X.Env, +nd: U64) -> NR:
  +x = X.xp_ev(tx, e)
  +y = X.xp_ev(ty, e)
  +z = X.xp_ev(tz, e)
  +ok = Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), Bool.and(T.is_finite(z), U64.is_lt(q, 6u64))))
  Bool.pick(NR, ok, NR_ok{Bd{bd_cells(b), bd_brep(b), bd_fns(b), pl_move(bd_pl(b), q, x, y, z), bd_rv(b)}, Fx{M_same{}, 0n, 0n, 0n, 0n}},
    bad("move", "node " ++ U64.show(nd), "nonfinite-translation-or-bad-turn", "finite offsets and a turn code 0-5"))

def op_rot(+b: Body, +ax: U64, +deg: X.Xp, +e: X.Env, +nd: U64) -> NR:
  +d = X.xp_ev(deg, e)
  +ok = Bool.and(Bool.and(T.is_finite(d), F64.is_le(F64.abs(d), 1000000.0f64)), U64.is_lt(ax, 3u64))
  Bool.pick(NR, ok, NR_ok{Bd{bd_cells(b), bd_brep(b), bd_fns(b), pl_rot(bd_pl(b), ax, I.sin_cos_deg(d)), bd_rv(b)}, Fx{M_same{}, 0n, 0n, 0n, 0n}},
    bad("rotate", "node " ++ U64.show(nd), "bad-axis-or-angle", "an axis x, y or z and a finite angle in degrees with |angle| <= 1000000"))

def seg_w(s: F.Seg, +e: X.Env, +acc: List<&2, U64>) -> List<&2, U64>:
  match s:
    case F.S_line{x, y}: 21u64 <> X.xp_w(x, e, X.xp_w(y, e, acc))
    case F.S_arc{cx, cy, r, x, y, ccw}:
      22u64 <> Bool.pick(U64, ccw, 1u64, 0u64) <> X.xp_w(cx, e, X.xp_w(cy, e, X.xp_w(r, e, X.xp_w(x, e, X.xp_w(y, e, acc)))))

def segs_w(ss: List<&2, F.Seg>, +e: X.Env, +acc: List<&2, U64>) -> List<&2, U64>:
  match ss:
    case []: 29u64 <> acc
    case s <> t: seg_w(s, e, segs_w(t, e, acc))

def loop_w(l: F.Loop, +e: X.Env, +acc: List<&2, U64>) -> List<&2, U64>:
  match l:
    case F.L_path{x, y, segs}: 31u64 <> X.xp_w(x, e, X.xp_w(y, e, segs_w(segs, e, acc)))
    case F.L_circ{cx, cy, r}: 32u64 <> X.xp_w(cx, e, X.xp_w(cy, e, X.xp_w(r, e, acc)))

def loops_w(ls: List<&2, F.Loop>, +e: X.Env, +acc: List<&2, U64>) -> List<&2, U64>:
  match ls:
    case []: 39u64 <> acc
    case l <> t: loop_w(l, e, loops_w(t, e, acc))

def rgs_w(rs: List<&2, F.Region>, +e: X.Env, +acc: List<&2, U64>) -> List<&2, U64>:
  match rs:
    case []: 49u64 <> acc
    case r <> t:
      F.Rg{o, hs} = r
      41u64 <> loop_w(o, e, loops_w(hs, e, rgs_w(t, e, acc)))

def hls_w(hs: List<&2, Hl>, +e: X.Env, +acc: List<&2, U64>) -> List<&2, U64>:
  match hs:
    case []: 59u64 <> acc
    case h <> t:
      Hl{x, y, r} = h
      51u64 <> X.xp_w(x, e, X.xp_w(y, e, X.xp_w(r, e, hls_w(t, e, acc))))

def sel_w(s: Sel, +acc: List<&2, U64>) -> List<&2, U64>:
  Sel{nd, k, side} = s
  nd <> U64.from_nat(k) <> side <> acc

def op_w(o: Op, +e: X.Env) -> List<&2, U64>:
  match o:
    case O_prism{rs, z0, z1}: 1u64 <> rgs_w(rs, e, X.xp_w(z0, e, X.xp_w(z1, e, [])))
    case O_box{x, y, z}: 2u64 <> X.xp_w(x, e, X.xp_w(y, e, X.xp_w(z, e, [])))
    case O_cyl{r, h}: 3u64 <> X.xp_w(r, e, X.xp_w(h, e, []))
    case O_pad{base, f, rs, h}: 4u64 <> base <> sel_w(f, rgs_w(rs, e, X.xp_w(h, e, [])))
    case O_pocket{base, f, rs, d, thru}:
      5u64 <> base <> Bool.pick(U64, thru, 1u64, 0u64) <> sel_w(f, rgs_w(rs, e, X.xp_w(d, e, [])))
    case O_holes{base, f, hs, d, thru}:
      6u64 <> base <> Bool.pick(U64, thru, 1u64, 0u64) <> sel_w(f, hls_w(hs, e, X.xp_w(d, e, [])))
    case O_move{base, tx, ty, tz, q}: 7u64 <> base <> q <> X.xp_w(tx, e, X.xp_w(ty, e, X.xp_w(tz, e, [])))
    case O_rot{base, ax, deg}: 12u64 <> base <> ax <> X.xp_w(deg, e, [])
    case O_unk{name}: [13u64]
    case O_revolve{rs}: 8u64 <> rgs_w(rs, e, [])
    case O_cone{r, h}: 9u64 <> X.xp_w(r, e, X.xp_w(h, e, []))
    case O_sph{r}: 10u64 <> X.xp_w(r, e, [])
    case O_tor{bigr, r}: 11u64 <> X.xp_w(bigr, e, X.xp_w(r, e, []))

def op_base(o: Op) -> U64:
  match o:
    case O_pad{base, f, rs, h}: base
    case O_pocket{base, f, rs, d, thru}: base
    case O_holes{base, f, hs, d, thru}: base
    case O_move{base, tx, ty, tz, q}: base
    case O_rot{base, ax, deg}: base
    case _: 0u64

def op_has_base(o: Op) -> Bool:
  match o:
    case O_pad{base, f, rs, h}: True{}
    case O_pocket{base, f, rs, d, thru}: True{}
    case O_holes{base, f, hs, d, thru}: True{}
    case O_move{base, tx, ty, tz, q}: True{}
    case O_rot{base, ax, deg}: True{}
    case _: False{}

def op_name(o: Op) -> String:
  match o:
    case O_prism{rs, z0, z1}: "prism"
    case O_box{x, y, z}: "box"
    case O_cyl{r, h}: "cylinder"
    case O_pad{base, f, rs, h}: "pad"
    case O_pocket{base, f, rs, d, thru}: "pocket"
    case O_holes{base, f, hs, d, thru}: "holes"
    case O_move{base, tx, ty, tz, q}: "move"
    case O_rot{base, ax, deg}: "rotate"
    case O_unk{name}: "unknown"
    case O_revolve{rs}: "revolve"
    case O_cone{r, h}: "cone"
    case O_sph{r}: "sphere"
    case O_tor{bigr, r}: "torus"

def rls_holes(rs: List<&2, F.Rl>) -> List<&2, Bool>:
  match rs:
    case []: []
    case r <> t: Bool.not(rl_mat(r)) <> rls_holes(t)

def rev_go(e: F.Er, +ls: List<&2, F.Lp>, +ps: List<&2, Nat>, +hs: List<&2, Bool>, +nd: U64) -> NR:
  F.Er{+code, +lp, +sg} = e
  match code:
    case 0u64: bt_check(RV.rev_brep(ls, ps, hs, nd), [], pl_id(), "revolve", ls)
    case _: pe_nr(F.Er{code, lp, sg}, "revolve profile")

def rev_ck(c: F.CK, +rls: List<&2, F.Rl>, +nd: U64) -> NR:
  match c:
    case F.CK_err{e}: pe_nr(e, "revolve profile")
    case F.CK_ok{+ls, +ps}:
      +hs = rls_holes(rls)
      +pp = RV.lps_prep(ls, hs)
      rev_go(RV.ax_codes(pp, hs, 0n), pp, ps, hs, nd)

def op_rev(+rs: List<&2, F.Region>, +e: X.Env, +nd: U64) -> NR:
  rev_ck(F.prof_check(rs, e), F.rg_rls(rs, 0n, F.K_free{}), nd)

def path_rg(+x0: X.Xp, +y0: X.Xp, +segs: List<&2, F.Seg>) -> F.Region:
  F.Rg{F.L_path{x0, y0, segs}, []}

def cone_rg(+r: X.Xp, +h: X.Xp) -> F.Region:
  path_rg(xk(0.0f64), xk(0.0f64), [F.S_line{r, xk(0.0f64)}, F.S_line{xk(0.0f64), h}])

def sph_rg(+r: X.Xp) -> F.Region:
  path_rg(xk(0.0f64), X.X_neg{r}, [F.S_arc{xk(0.0f64), xk(0.0f64), r, xk(0.0f64), r, True{}}])

def tor_rg(+bigr: X.Xp, +r: X.Xp) -> F.Region:
  F.Rg{F.L_circ{bigr, xk(0.0f64), r}, []}

def op_build(o: Op, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_prism{rs, z0, z1}: op_prism(rs, z0, z1, e, nd)
    case O_box{x, y, z}: op_prism([rect_rg(x, y)], xk(0.0f64), z, e, nd)
    case O_cyl{r, h}: op_prism([circ_rg(r)], xk(0.0f64), h, e, nd)
    case O_pad{base, f, rs, h}: op_feat(0u64, b, f, rs, h, False{}, e, nd)
    case O_pocket{base, f, rs, d, thru}: op_feat(1u64, b, f, rs, d, thru, e, nd)
    case O_holes{base, f, hs, d, thru}: op_feat(2u64, b, f, hls_rgs(hs), d, thru, e, nd)
    case O_move{base, tx, ty, tz, q}: op_move(b, tx, ty, tz, q, e, nd)
    case O_rot{base, ax, deg}: op_rot(b, ax, deg, e, nd)
    case O_unk{name}: bad(name, "node " ++ U64.show(nd), "unknown-op", "use box, cylinder, prism, pad, pocket, holes, move, rotate, revolve, cone, sphere or torus")
    case O_revolve{rs}: op_rev(rs, e, nd)
    case O_cone{r, h}: op_rev([cone_rg(r, h)], e, nd)
    case O_sph{r}: op_rev([sph_rg(r)], e, nd)
    case O_tor{bigr, r}: op_rev([tor_rg(bigr, r)], e, nd)

def fn_w(f: BD.Fn) -> List<&2, U64>:
  BD.Fn{nd, k, role, i, j} = f
  [nd, U64.from_nat(k), role, U64.from_nat(i), U64.from_nat(j)]

def lp_at(ls: List<&2, Ty.Loop>, +i: Nat) -> Ty.Loop:
  match ls:
    case []: Ty.Lp{0u64, [], Ty.LK_outer{}}
    case l <> t:
      match i:
        case 0n: l
        case 1n+j: lp_at(t, j)

def lps_nce(ls: List<&2, Ty.HLoop>, +b: Ty.Brep) -> Nat:
  match ls:
    case []: 0n
    case h <> t:
      Ty.HL{idx, gen} = h
      Nat.add(List.length(&2, Ty.HCoedge, Ty.lp_ces(lp_at(Ty.brep_lps(b), idx))), lps_nce(t, b))

def fa_sig(+b: Ty.Brep, f: Ty.Face) -> List<&2, Nat>:
  Ty.Fa{g, s, +ls, same} = f
  [List.length(&2, Ty.HLoop, ls), lps_nce(ls, b)]

def ns_of(fns: List<&2, BD.Fn>, fas: List<&2, Ty.Face>, +b: Ty.Brep) -> List<&2, NS>:
  match fns:
    case []: []
    case f <> t:
      match fas:
        case []: []
        case +a <> u:
          +s = fa_sig(b, a)
          NS{fn_w(f), nth_n(s, 0n), nth_n(s, 1n)} <> ns_of(t, u, b)

def kcmp(a: List<&2, U64>, b: List<&2, U64>) -> B.Sgn:
  match a b:
    case Nil{} Nil{}: B.Sz{}
    case Nil{} _: B.Sn{}
    case _ Nil{}: B.Sp{}
    case Con{+x, xt} Con{+y, yt}:
      Bool.pick(B.Sgn, U64.is_lt(x, y), B.Sn{}, Bool.pick(B.Sgn, U64.is_lt(y, x), B.Sp{}, kcmp(xt, yt)))

def ns_k(x: NS) -> List<&2, U64>:
  NS{k, lp, ce} = x
  k

def ns_lp(x: NS) -> Nat:
  NS{k, lp, ce} = x
  lp

def ns_ce(x: NS) -> Nat:
  NS{k, lp, ce} = x
  ce

def ns_cmp(a: NS, b: NS) -> B.Sgn:
  kcmp(ns_k(a), ns_k(b))

def so_ns(s: B.So<&2, NS>) -> List<&2, NS>:
  B.So{ok, xs} = s
  xs

def ns_sort(+xs: List<&2, NS>) -> List<&2, NS>:
  so_ns(B.msort(~NS, ~ns_cmp, xs))

def diff_go(n: Nat, rs: List<&2, NS>, bs: List<&2, NS>, +fc: Nat, +fm: Nat) -> List<&2, Nat>:
  match n:
    case 0n: [fc, fm]
    case 1n+(+m):
      match rs:
        case []: [fc, fm]
        case +r <> +rt:
          match bs:
            case []: diff_go(m, rt, [], Nat.add(fc, 1n), fm)
            case +b <> +bt:
              +c = kcmp(ns_k(r), ns_k(b))
              +lt = F.sgn_neg(c)
              +gt = F.sgn_pos(c)
              +chg = Bool.or(Bool.not(Nat.is_eq(ns_lp(r), ns_lp(b))), Bool.not(Nat.is_eq(ns_ce(r), ns_ce(b))))
              diff_go(m, Bool.pick(List<&2, NS>, gt, r <> rt, rt), Bool.pick(List<&2, NS>, lt, b <> bt, bt),
                Bool.pick(Nat, lt, Nat.add(fc, 1n), fc),
                Bool.pick(Nat, Bool.and(Bool.not(lt), Bool.and(Bool.not(gt), chg)), Nat.add(fm, 1n), fm))

def body_ns(+b: Body) -> List<&2, NS>:
  +br = bd_brep(b)
  ns_sort(ns_of(bd_fns(b), Ty.brep_fas(br), br))

def mat_cmp(+r: I.I, +b: I.I) -> Mat:
  Bool.pick(Mat, F64.is_lt(I.i_hi(b), I.i_lo(r)), M_add{}, Bool.pick(Mat, F64.is_lt(I.i_hi(r), I.i_lo(b)), M_remove{}, M_unknown{}))

def ms_vol(m: Ms) -> I.I:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  vol

def ms_ns(m: Ms) -> Nat:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  ns

def ms_genus(m: Ms) -> Nat:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  genus

def fx_of(+o: Op, +hasb: Bool, +b: Body, +r: Body) -> Fx:
  +rm = body_ms(r)
  +rn = body_ns(r)
  +bn = Bool.pick(List<&2, NS>, hasb, body_ns(b), [])
  +d = diff_go(Nat.add(List.length(&2, NS, rn), List.length(&2, NS, bn)), rn, bn, 0n, 0n)
  +isMove = Bool.or(String.eq(op_name(o), "move"), String.eq(op_name(o), "rotate"))
  +mat = Bool.pick(Mat, Bool.not(hasb), M_create{}, Bool.pick(Mat, isMove, M_same{}, mat_cmp(ms_vol(rm), ms_vol(body_ms(b)))))
  Fx{mat, Bool.pick(Nat, isMove, 0n, nth_n(d, 0n)), Bool.pick(Nat, isMove, 0n, nth_n(d, 1n)), ms_ns(rm), ms_genus(rm)}

def mat_tag(m: Mat) -> U64:
  match m:
    case M_create{}: 0u64
    case M_add{}: 1u64
    case M_remove{}: 2u64
    case M_same{}: 3u64
    case M_unknown{}: 4u64

def mat_show(m: Mat) -> String:
  match m:
    case M_create{}: "create"
    case M_add{}: "add"
    case M_remove{}: "remove"
    case M_same{}: "same"
    case M_unknown{}: "uncertain"

def cnt_ok(c: Cnt, +n: Nat) -> Bool:
  match c:
    case C_any{}: True{}
    case C_eq{m}: Nat.is_eq(m, n)

def fx_show(f: Fx) -> String:
  Fx{mat, fc, fm, sh, ho} = f
  "material=" ++ mat_show(mat) ++ " faces_created=" ++ Nat.show(fc) ++ " faces_modified=" ++ Nat.show(fm) ++
    " solids=" ++ Nat.show(sh) ++ " through_holes=" ++ Nat.show(ho)

def cnt_show(c: Cnt) -> String:
  match c:
    case C_any{}: "any"
    case C_eq{n}: Nat.show(n)

def it_show(i: It) -> String:
  It{mat, fc, fm, sh, ho} = i
  "material=" ++ mat_show(mat) ++ " faces_created=" ++ cnt_show(fc) ++ " faces_modified=" ++ cnt_show(fm) ++
    " solids=" ++ cnt_show(sh) ++ " through_holes=" ++ cnt_show(ho)

def it_ok(i: It, f: Fx) -> Bool:
  It{im, ifc, ifm, ish, iho} = i
  Fx{m, fc, fm, sh, ho} = f
  Bool.and(U64.is_eq(mat_tag(im), mat_tag(m)), Bool.and(cnt_ok(ifc, fc), Bool.and(cnt_ok(ifm, fm),
    Bool.and(cnt_ok(ish, sh), cnt_ok(iho, ho)))))

def gate_go(ok: Bool, +r: Body, +f: Fx, +it: It, +nd: U64) -> NR:
  match ok:
    case True{}: NR_ok{r, f}
    case False{}:
      bad("intent", "node " ++ U64.show(nd), "declared " ++ it_show(it) ++ " but measured " ++ fx_show(f),
        "fix the operation or declare the effect it has")

def publish(r: NR, +o: Op, +hasb: Bool, +b: Body, +it: It, +nd: U64) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+rb, f0}:
      +f = fx_of(o, hasb, b, rb)
      gate_go(it_ok(it, f), rb, f, it, nd)

def cnt_w(c: Cnt) -> U64:
  match c:
    case C_any{}: 18446744073709551615u64
    case C_eq{n}: U64.from_nat(n)

def it_w(i: It) -> List<&2, U64>:
  It{mat, fc, fm, sh, ho} = i
  [mat_tag(mat), cnt_w(fc), cnt_w(fm), cnt_w(sh), cnt_w(ho)]

def pvs_of(ps: List<&2, Param>) -> List<&2, X.PV>:
  match ps:
    case []: []
    case p <> t:
      Pm{id, name, dim} = p
      Dm{nom, lo, hi} = dim
      X.PV{id, nom} <> pvs_of(t)

def ce_id(c: CE) -> U64:
  CE{id, key, r} = c
  id

def ce_key(c: CE) -> List<&2, U64>:
  CE{id, key, r} = c
  key

def ce_r(c: CE) -> NR:
  CE{id, key, r} = c
  r

def keq(a: List<&2, U64>, b: List<&2, U64>) -> Bool:
  match a b:
    case Nil{} Nil{}: True{}
    case Con{x, xt} Con{y, yt}: Bool.and(U64.is_eq(x, y), keq(xt, yt))
    case _ _: False{}

def ce_find(cs: List<&2, CE>, +id: U64) -> CE:
  match cs:
    case []: CE{0u64, [], bad("node", "-", "missing-input-node", "reference an earlier node id")}
    case +c <> t: Bool.pick(CE, U64.is_eq(ce_id(c), id), c, ce_find(t, id))

def ce_has(cs: List<&2, CE>, +id: U64) -> Bool:
  match cs:
    case []: False{}
    case c <> t: Bool.or(U64.is_eq(ce_id(c), id), ce_has(t, id))

def nr_ok(r: NR) -> Bool:
  match r:
    case NR_ok{b, f}: True{}
    case NR_err{k, d}: False{}

def nr_body(r: NR) -> Body:
  match r:
    case NR_ok{b, f}: b
    case NR_err{k, d}: Bd{[], Ty.brep_empty(), [], pl_id(), []}

def hit_go(hit: Bool, +old: CE, +o: Op, +hasb: Bool, +b: Body, +e: X.Env, +it: It, +nd: U64) -> NR:
  match hit:
    case True{}: ce_r(old)
    case False{}: publish(op_build(o, b, e, nd), o, hasb, b, it, nd)

def node_go(okb: Bool, +o: Op, +hasb: Bool, +b: Body, +e: X.Env, +it: It, +nd: U64, +key: List<&2, U64>,
    +old: List<&2, CE>) -> NR:
  match okb:
    case False{}: bad(op_name(o), "node " ++ U64.show(nd), "input-node-missing-or-failed", "fix the input node first")
    case True{}:
      +oc = ce_find(old, nd)
      hit_go(Bool.and(ce_has(old, nd), keq(ce_key(oc), key)), oc, o, hasb, b, e, it, nd)

def ev_nodes(ns: List<&2, Node>, +e: X.Env, +old: List<&2, CE>, +acc: List<&2, CE>) -> List<&2, CE>:
  match ns:
    case []: List.reverse(&2, CE, acc)
    case n <> t:
      Nd{+nd, +o, +it} = n
      +hasb = op_has_base(o)
      +bc = ce_find(acc, op_base(o))
      +okb = Bool.or(Bool.not(hasb), Bool.and(ce_has(acc, op_base(o)), nr_ok(ce_r(bc))))
      +key = List.append(&2, U64, op_w(o, e), List.append(&2, U64, it_w(it), Bool.pick(List<&2, U64>, hasb, ce_key(bc), [])))
      +r = node_go(okb, o, hasb, nr_body(ce_r(bc)), e, it, nd, key, old)
      ev_nodes(t, e, old, CE{nd, key, r} <> acc)

def nd_id(n: Node) -> U64:
  Nd{id, op, it} = n
  id

def pm_id(p: Param) -> U64:
  Pm{id, name, dim} = p
  id

def nd_ids(ns: List<&2, Node>) -> List<&2, U64>:
  match ns:
    case []: []
    case n <> t: nd_id(n) <> nd_ids(t)

def pm_ids(ps: List<&2, Param>) -> List<&2, U64>:
  match ps:
    case []: []
    case p <> t: pm_id(p) <> pm_ids(t)

def u_cmp_go(+a: U64, +b: U64) -> B.Sgn:
  B.sgn_pick(U64.is_lt(a, b), U64.is_lt(b, a))

def u_cmp(a: U64, b: U64) -> B.Sgn:
  u_cmp_go(a, b)

def so_u(s: B.So<&2, U64>) -> List<&2, U64>:
  B.So{ok, xs} = s
  xs

def u_dup(xs: List<&2, U64>, +prev: U64, +first: Bool) -> Bool:
  match xs:
    case []: False{}
    case +h <> t: Bool.or(Bool.and(Bool.not(first), U64.is_eq(h, prev)), u_dup(t, h, False{}))

def ids_dup(+xs: List<&2, U64>) -> Bool:
  u_dup(so_u(B.msort(~U64, ~u_cmp, xs)), 0u64, True{})

def ev_go(ok: Bool, +p: Part, +old: List<&2, CE>) -> List<&2, CE>:
  match ok:
    case False{}: [CE{0u64, [], bad("part", "-", "duplicate-node-or-parameter-id", "give every node and parameter a distinct id")}]
    case True{}:
      Pt{ps, ns} = p
      ev_nodes(ns, X.env_of(pvs_of(ps)), old, [])

def ev_part(+p: Part, +old: List<&2, CE>) -> List<&2, CE>:
  Pt{+ps, +ns} = p
  ev_go(Bool.not(Bool.or(ids_dup(nd_ids(ns)), ids_dup(pm_ids(ps)))), p, old)
