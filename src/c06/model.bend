import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c04/types.bend as Ty
import ../c03/types.bend as G
import ../c04/ops.bend as B4
import ../base/par.bend as B
import ../base/ex.bend as E
import ../c05/exact.bend as XE
import ./xp.bend as X
import ./prof.bend as F
import ./build.bend as BD
import ./revolve.bend as RV
import ./iv.bend as I
import ../c08/bool.bend as B8
import ../c07/sol.bend as SO
import ../c07/mem.bend as Mm
import ../c07/im.bend as MM
import ../k1/fb.bend as FB
import ../c09/feat.bend as F9
import ../c12/blob.bend as BL
import ../c16/sheet.bend as SH
import ../c16/surf.bend as SU
import ../c16/blade.bend as BA

type Sel is Data:
  Sel{ nd: U64, k: Nat, side: U64, nm: String }

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
  O_blob{ fmt: U64, payload: String }
  O_revolve{ rs: List<&2, F.Region> }
  O_cone{ r: X.Xp, h: X.Xp }
  O_sph{ r: X.Xp }
  O_tor{ bigr: X.Xp, r: X.Xp }
  O_union{ a: U64, b: U64 }
  O_difference{ a: U64, b: U64 }
  O_intersection{ a: U64, b: U64 }
  O_sw_line{ z: X.Xp, rs: List<&2, F.Region>, g: U64, gd: U64, tw: U64 }
  O_sw_arc{ deg: U64, rs: List<&2, F.Region>, g: U64, gd: U64, tw: U64 }
  O_loft{ z: X.Xp, bot: F.Region, top: F.Region, twist: U64, cont: U64 }
  O_chamfer{ base: U64, d: X.Xp }
  O_echamf{ base: U64, f: Sel, cx: X.Xp, cy: X.Xp, r: X.Xp, c: X.Xp }
  O_lchamf{ base: U64, nd: U64, n1: String, n2: String, c: X.Xp }
  O_fillet{ base: U64, r: X.Xp }
  O_fillet_e{ base: U64, n: U64, r0: X.Xp, r1: X.Xp }
  O_draft{ base: U64, inset: X.Xp }
  O_offset{ base: U64, d: X.Xp }
  O_shell{ base: U64, t: X.Xp, open: Bool }
  O_thicken{ base: U64, t: X.Xp }
  O_pat_lin{ base: U64, nx: U64, dx: X.Xp, ny: U64, dy: X.Xp, nz: U64, dz: X.Xp }
  O_pat_circ{ base: U64, n: U64, r: X.Xp }
  O_ph_lin{ base: U64, f: Sel, nx: U64, ny: U64, dx: X.Xp, dy: X.Xp, x0: X.Xp, y0: X.Xp, r: X.Xp, d: X.Xp, thru: Bool }
  O_ph_circ{ base: U64, f: Sel, n: U64, rad: X.Xp, cx: X.Xp, cy: X.Xp, r: X.Xp, d: X.Xp, thru: Bool }
  O_flat{ l: X.Xp, w: X.Xp, t: X.Xp }
  O_bend{ base: U64, n: U64, r: X.Xp, deg: U64 }
  O_hem{ base: U64, n: U64, l: X.Xp }
  O_loft_open{ z: X.Xp, bot: F.Region, top: F.Region, twist: U64, cont: U64 }
  O_sw_open{ deg: U64, rs: List<&2, F.Region>, g: U64, gd: U64, tw: U64 }
  O_patch{ ps: List<&2, X.Xp> }
  O_thicken_open{ base: U64, t: X.Xp }
  O_naca4{ m: U64, p: U64, t: U64, c: X.Xp, n: U64 }
  O_blade{ secs: List<&2, U64>, z: X.Xp, tw: U64, tp: U64 }

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

type Ms is Data:
  Ms{ vol: I.I, area: I.I, x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64, nv: Nat, ne: Nat, nf: Nat,
    ns: Nat, genus: Nat, lin: F64 }

type Acc is Data:
  Acc{ vol: I.I, area: I.I, per: I.I }

type Bb is Data:
  Bb{ x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64 }

type Xb is Data:
  Xb{ mx: List<&2, Ms>, nc: Nat, bo: Bool, pr: String, dl: List<&2, B8.Del> }

type Body is Data:
  Bd{ cells: List<&2, BD.Cl>, brep: Ty.Brep, fns: List<&2, BD.Fn>, pl: Pl, rv: List<&2, F.Lp>, xb: Xb }

type Dg is Data:
  Dg{ what: String, loc: String, why: String, fix: String }

type NR is Data:
  NR_ok{ b: Body, fx: Fx }
  NR_err{ kind: T.FailKind, d: Dg }

type CE is Data:
  CE{ id: U64, key: List<&2, U64>, r: NR }

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

def ti_pt(+t: F64, +a: I.I) -> Bool:
  Bool.and(F64.is_eq(I.i_lo(a), I.i_hi(a)), F64.is_eq(I.i_lo(a), t))

def ti_tail(xs: List<&2, I.I>) -> Bool:
  match xs:
    case []: True{}
    case +x <> t: ti_tail(t)

def ti3z(+ok: Bool, +tz: F64, xs: List<&2, I.I>) -> Bool:
  match xs:
    case []: False{}
    case z <> t: Bool.and(Bool.and(ok, ti_pt(tz, z)), ti_tail(t))

def ti3y(+ok: Bool, +ty: F64, +tz: F64, xs: List<&2, I.I>) -> Bool:
  match xs:
    case []: False{}
    case +y <> t: ti3z(Bool.and(ok, ti_pt(ty, y)), tz, t)

def ti3(+tx: F64, +ty: F64, +tz: F64, xs: List<&2, I.I>) -> Bool:
  match xs:
    case []: False{}
    case +x <> t: ti3y(ti_pt(tx, x), ty, tz, t)

def pl_exact(p: Pl) -> Bool:
  Pl{m, +tx, +ty, +tz, mi, +ti} = p
  Bool.and(ipt_exact(mi), ti3(tx, ty, tz, ti))

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

def pl_m(p: Pl) -> V.Mat3:
  Pl{m, tx, ty, tz, mi, ti} = p
  m

def pl_tx(p: Pl) -> F64:
  Pl{m, tx, ty, tz, mi, ti} = p
  tx

def pl_ty(p: Pl) -> F64:
  Pl{m, tx, ty, tz, mi, ti} = p
  ty

def pl_tz(p: Pl) -> F64:
  Pl{m, tx, ty, tz, mi, ti} = p
  tz

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
  Bd{+cells, brep, fns, +pl, rv, xb} = bd
  +ds = BD.cds_of(cells)
  +tb = B.tb_of(BD.Cd, ds, BD.cd_pad())
  +acc = ms_go(ds, tb, Acc{I.ipt(0.0f64), I.ipt(0.0f64), I.ipt(0.0f64)})
  +bb0 = bb_cells(cells, bb_empty())
  +lin = F64.mul(bb_m(bb0), 1.7763568394002505e-15f64)
  ms_mk(acc, Bool.pick(Bb, pl_exact(pl), pl_bb(bb_wid(bb0, lin), pl), bb_wid(bb_gcells(cells, bb_empty(), pl), F64.mul(2.0f64, lin))), lin, brep)

def bd_rv(b: Body) -> List<&2, F.Lp>:
  Bd{cells, brep, fns, pl, rv, xb} = b
  rv

def bd_pl(b: Body) -> Pl:
  Bd{cells, brep, fns, pl, rv, xb} = b
  pl

def bd_brep(b: Body) -> Ty.Brep:
  Bd{cells, brep, fns, pl, rv, xb} = b
  brep

def xb_id() -> Xb:
  Xb{[], 0n, False{}, "", []}

def bd_xb(b: Body) -> Xb:
  Bd{cells, brep, fns, pl, rv, xb} = b
  xb

def xb_mx(x: Xb) -> List<&2, Ms>:
  Xb{mx, nc, bo, pr, dl} = x
  mx

def xb_nc(x: Xb) -> Nat:
  Xb{mx, nc, bo, pr, dl} = x
  nc

def xb_bo(x: Xb) -> Bool:
  Xb{mx, nc, bo, pr, dl} = x
  bo

def xb_pr(x: Xb) -> String:
  Xb{mx, nc, bo, pr, dl} = x
  pr

def xb_dl(x: Xb) -> List<&2, B8.Del>:
  Xb{mx, nc, bo, pr, dl} = x
  dl

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

def ms_vol(m: Ms) -> I.I:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  vol

def ms_ns(m: Ms) -> Nat:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  ns

def ms_genus(m: Ms) -> Nat:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  genus

def ms_area(m: Ms) -> I.I:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  area

def ms_x0(m: Ms) -> F64:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  x0

def ms_x1(m: Ms) -> F64:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  x1

def ms_y0(m: Ms) -> F64:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  y0

def ms_y1(m: Ms) -> F64:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  y1

def ms_z0(m: Ms) -> F64:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  z0

def ms_z1(m: Ms) -> F64:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  z1

def ms_lin(m: Ms) -> F64:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  lin

def ms_bb(+m: Ms) -> Bb:
  Bb{ms_x0(m), ms_x1(m), ms_y0(m), ms_y1(m), ms_z0(m), ms_z1(m)}

def ms_with_bb(+m: Ms, b: Bb) -> Ms:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  Bb{nx0, nx1, ny0, ny1, nz0, nz1} = b
  Ms{vol, area, nx0, nx1, ny0, ny1, nz0, nz1, nv, ne, nf, ns, genus, lin}

def hw_nth(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: 0.0f64
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: hw_nth(t, j)

def i_hw(+x: I.I) -> F64:
  F64.mul(0.5f64, F64.sub(I.i_hi(x), I.i_lo(x)))

def hw_list(xs: List<&2, I.I>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> t: i_hw(x) <> hw_list(t)

def maxabs3(+b: Bb) -> List<&2, F64>:
  Bb{x0, x1, y0, y1, z0, z1} = b
  [F64.max(F64.abs(x0), F64.abs(x1)), F64.max(F64.abs(y0), F64.abs(y1)),
    F64.max(F64.abs(z0), F64.abs(z1))]

def slop_row(+h0: F64, +h1: F64, +h2: F64, +m0: F64, +m1: F64, +m2: F64, +ht: F64) -> F64:
  F64.add(F64.add(F64.add(F64.mul(h0, m0), F64.mul(h1, m1)), F64.mul(h2, m2)), ht)

def pl_slop(+b: Bb, +p: Pl) -> F64:
  +hw = hw_list(pl_mi(p))
  +ht = hw_list(pl_ti(p))
  +mx = maxabs3(b)
  +m0 = hw_nth(mx, 0n)
  +m1 = hw_nth(mx, 1n)
  +m2 = hw_nth(mx, 2n)
  F64.max(slop_row(hw_nth(hw, 0n), hw_nth(hw, 1n), hw_nth(hw, 2n), m0, m1, m2, hw_nth(ht, 0n)),
    F64.max(slop_row(hw_nth(hw, 3n), hw_nth(hw, 4n), hw_nth(hw, 5n), m0, m1, m2, hw_nth(ht, 1n)),
      slop_row(hw_nth(hw, 6n), hw_nth(hw, 7n), hw_nth(hw, 8n), m0, m1, m2, hw_nth(ht, 2n))))

def ms_placed(+s: Ms, +p: Pl) -> Ms:
  +b = ms_bb(s)
  +w = pl_bb(b, p)
  ms_with_bb(s, Bool.pick(Bb, pl_exact(p), w, bb_wid(w, pl_slop(b, p))))

def body_mx(+bd: Body, m: List<&2, Ms>) -> Ms:
  match m:
    case s <> t: ms_placed(s, bd_pl(bd))
    case []:
      Bool.pick(Ms, Nat.is_eq(List.length(&2, F.Lp, bd_rv(bd)), 0n), prism_ms(bd),
        rev_ms(bd_rv(bd), bd_brep(bd), bd_pl(bd)))

def body_ms(+bd: Body) -> Ms:
  body_mx(bd, xb_mx(bd_xb(bd)))

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

def stage_of_open(+b: Ty.Brep, +fuel: Nat) -> U64:
  pk0(okc(B4.brep_incid_c(b, fuel), 2u64), pk0(okc(B4.brep_use_c(b, Ty.P_open_shell{}, fuel), 3u64),
    pk0(okc(B4.brep_loop_c(b, fuel), 4u64), pk0(okc(B4.brep_facekind_c(b, fuel), 5u64),
      pk0(okc(B4.brep_prof_c(b, Ty.P_open_shell{}, fuel), 6u64), pk0(okc(B4.brep_embed_c(b, fuel), 7u64),
        pk0(okc(B4.brep_link_c(b, Ty.P_open_shell{}, fuel), 8u64), pk0(okc(B4.brep_conn_c(b, fuel), 9u64),
          pk0(okc(B4.brep_coin_c(b, fuel), 10u64), pk0(okc(B4.brep_xing_c(b, fuel), 11u64),
            okc(B4.brep_orient_c(b, fuel), 12u64)))))))))))

def ck_go(ok: Bool, +b: Ty.Brep, +fns: List<&2, BD.Fn>, +cs: List<&2, BD.Cl>, +pl: Pl, +what: String, +rv: List<&2, F.Lp>) -> NR:
  match ok:
    case True{}: NR_ok{Bd{cs, b, fns, pl, rv, xb_id()}, Fx{M_same{}, 0n, 0n, 0n, 0n}}
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

def ck_go_open(ok: Bool, +b: Ty.Brep, +fns: List<&2, BD.Fn>, +cs: List<&2, BD.Cl>, +pl: Pl, +what: String,
    +rv: List<&2, F.Lp>) -> NR:
  match ok:
    case True{}: NR_ok{Bd{cs, b, fns, pl, rv, xb_id()}, Fx{M_same{}, 0n, 0n, 0n, 0n}}
    case False{}:
      nr_err(T.F_uncertain{}, what, "brep stage " ++ stage_why(stage_of_open(b, fuel_of(b))),
        "the built boundary failed validation; no geometry is published", "report this design")

def bt_check_open(bt: BD.Bt, +cs: List<&2, BD.Cl>, +pl: Pl, +what: String, +rv: List<&2, F.Lp>) -> NR:
  BD.Bt{+b, +fns} = bt
  ck_go_open(tres_ok(B4.brep_checked(b, Ty.P_open_shell{}, fuel_of(b))), b, fns, cs, pl, what, rv)

def bd_open(+b: Body) -> Bool:
  +br = bd_brep(b)
  Bool.and(Ty.okd_ok(B4.brep_use_c(br, Ty.P_open_shell{}, fuel_of(br))),
    Bool.not(Ty.okd_ok(B4.brep_use_c(br, Ty.P_manifold_solid{}, fuel_of(br)))))

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

def find_cell_ex(cs: List<&2, BD.Cd>, +nd: U64, +k: Nat) -> Nat:
  match cs:
    case []: 0n
    case +d <> t:
      +c = BD.cd_c(d)
      Bool.pick(Nat, Bool.and(U64.is_eq(BD.cl_nd(c), nd), Nat.is_eq(BD.cl_k(c), k)), Nat.add(BD.cl_id(c), 1n),
        find_cell_ex(t, nd, k))

def find_cell_nth(cs: List<&2, BD.Cd>, +k: Nat, +i: Nat) -> Nat:
  match cs:
    case []: 0n
    case +d <> t:
      +c = BD.cd_c(d)
      Bool.pick(Nat, Nat.is_eq(k, i), Nat.add(BD.cl_id(c), 1n), find_cell_nth(t, k, Nat.add(i, 1n)))

def find_cell(+cs: List<&2, BD.Cd>, +nd: U64, +k: Nat, +base: U64) -> Nat:
  +ix = find_cell_ex(cs, nd, k)
  Bool.pick(Nat, Bool.and(Nat.is_eq(ix, 0n), U64.is_eq(nd, base)), find_cell_nth(cs, k, 0n), ix)

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
  Bd{cells, brep, fns, pl, rv, xb} = b
  cells

def bd_fns(b: Body) -> List<&2, BD.Fn>:
  Bd{cells, brep, fns, pl, rv, xb} = b
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

def rot_im(+ax: U64, +c: I.I, +s: I.I) -> List<&2, I.I>:
  +o = I.ipt(1.0f64)
  +z = I.ipt(0.0f64)
  Bool.pick(List<&2, I.I>, U64.is_eq(ax, 0u64), [o, z, z, z, c, I.ineg(s), z, s, c],
    Bool.pick(List<&2, I.I>, U64.is_eq(ax, 1u64), [c, z, s, z, o, z, I.ineg(s), z, c], [c, I.ineg(s), z, s, c, z, z, z, o]))

def im_mid(xs: List<&2, I.I>) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> t: I.imid(x) <> im_mid(t)

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
  Bool.pick(NR, ok, NR_ok{Bd{bd_cells(b), bd_brep(b), bd_fns(b), pl_move(bd_pl(b), q, x, y, z), bd_rv(b), bd_xb(b)}, Fx{M_same{}, 0n, 0n, 0n, 0n}},
    bad("move", "node " ++ U64.show(nd), "nonfinite-translation-or-bad-turn", "finite offsets and a turn code 0-5"))

def op_rot(+b: Body, +ax: U64, +deg: X.Xp, +e: X.Env, +nd: U64) -> NR:
  +d = X.xp_ev(deg, e)
  +ok = Bool.and(Bool.and(T.is_finite(d), F64.is_le(F64.abs(d), 1000000.0f64)), U64.is_lt(ax, 3u64))
  Bool.pick(NR, ok, NR_ok{Bd{bd_cells(b), bd_brep(b), bd_fns(b), pl_rot(bd_pl(b), ax, I.sin_cos_deg(d)), bd_rv(b), bd_xb(b)}, Fx{M_same{}, 0n, 0n, 0n, 0n}},
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

def chars_w(cs: List<&2, Char>, +acc: List<&2, U64>) -> List<&2, U64>:
  match cs:
    case []: acc
    case c <> t: U32.to_u64(Char.to_u32(c)) <> chars_w(t, acc)

def sel_w(s: Sel, +acc: List<&2, U64>) -> List<&2, U64>:
  Sel{nd, k, side, +nm} = s
  nd <> U64.from_nat(k) <> side <> U64.from_nat(String.length(nm)) <> chars_w(String.to_list(nm), acc)

def xps_w(xs: List<&2, X.Xp>, +e: X.Env, +acc: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case []: 61u64 <> acc
    case x <> t: X.xp_w(x, e, xps_w(t, e, acc))

def us_w_go(xs: List<&2, U64>, +acc: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case []: acc
    case +h <> t: h <> us_w_go(t, acc)

def us_w(+xs: List<&2, U64>, +acc: List<&2, U64>) -> List<&2, U64>:
  U64.from_nat(List.length(&2, U64, xs)) <> us_w_go(xs, acc)

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
    case O_blob{fmt, +payload}: 31u64 <> fmt <> BL.fnv_s(payload) <> U64.from_nat(BL.s_len(payload)) <> []
    case O_revolve{rs}: 8u64 <> rgs_w(rs, e, [])
    case O_cone{r, h}: 9u64 <> X.xp_w(r, e, X.xp_w(h, e, []))
    case O_sph{r}: 10u64 <> X.xp_w(r, e, [])
    case O_tor{bigr, r}: 11u64 <> X.xp_w(bigr, e, X.xp_w(r, e, []))
    case O_union{a, b}: B8.tag_union() <> a <> b <> []
    case O_difference{a, b}: B8.tag_diff() <> a <> b <> []
    case O_intersection{a, b}: B8.tag_inter() <> a <> b <> []
    case O_sw_line{z, rs, g, gd, tw}: 17u64 <> g <> gd <> tw <> X.xp_w(z, e, rgs_w(rs, e, []))
    case O_sw_arc{deg, rs, g, gd, tw}: 18u64 <> deg <> g <> gd <> tw <> rgs_w(rs, e, [])
    case O_loft{z, bot, top, twist, cont}: 19u64 <> twist <> cont <> X.xp_w(z, e, rgs_w([bot, top], e, []))
    case O_chamfer{base, d}: 20u64 <> base <> X.xp_w(d, e, [])
    case O_echamf{base, f, cx, cy, r, c}: 41u64 <> base <> sel_w(f, X.xp_w(cx, e, X.xp_w(cy, e, X.xp_w(r, e, X.xp_w(c, e, [])))))
    case O_lchamf{base, nd, +n1, +n2, c}: 42u64 <> base <> nd <> U64.from_nat(String.length(n1)) <> chars_w(String.to_list(n1), U64.from_nat(String.length(n2)) <> chars_w(String.to_list(n2), X.xp_w(c, e, [])))
    case O_fillet{base, r}: 21u64 <> base <> X.xp_w(r, e, [])
    case O_fillet_e{base, n, r0, r1}: 22u64 <> base <> n <> X.xp_w(r0, e, X.xp_w(r1, e, []))
    case O_draft{base, inset}: 23u64 <> base <> X.xp_w(inset, e, [])
    case O_offset{base, d}: 24u64 <> base <> X.xp_w(d, e, [])
    case O_shell{base, t, open}: 25u64 <> base <> Bool.pick(U64, open, 1u64, 0u64) <> X.xp_w(t, e, [])
    case O_thicken{base, t}: 26u64 <> base <> X.xp_w(t, e, [])
    case O_pat_lin{base, nx, dx, ny, dy, nz, dz}:
      27u64 <> base <> nx <> ny <> nz <> X.xp_w(dx, e, X.xp_w(dy, e, X.xp_w(dz, e, [])))
    case O_pat_circ{base, n, r}: 28u64 <> base <> n <> X.xp_w(r, e, [])
    case O_ph_lin{base, f, nx, ny, dx, dy, x0, y0, r, d, thru}:
      29u64 <> base <> nx <> ny <> Bool.pick(U64, thru, 1u64, 0u64) <> sel_w(f, X.xp_w(dx, e, X.xp_w(dy, e, X.xp_w(x0, e, X.xp_w(y0, e, X.xp_w(r, e, X.xp_w(d, e, [])))))))
    case O_ph_circ{base, f, n, rad, cx, cy, r, d, thru}:
      30u64 <> base <> n <> Bool.pick(U64, thru, 1u64, 0u64) <> sel_w(f, X.xp_w(rad, e, X.xp_w(cx, e, X.xp_w(cy, e, X.xp_w(r, e, X.xp_w(d, e, []))))))
    case O_flat{l, w, t}: 32u64 <> X.xp_w(l, e, X.xp_w(w, e, X.xp_w(t, e, [])))
    case O_bend{base, n, r, deg}: 33u64 <> base <> n <> deg <> X.xp_w(r, e, [])
    case O_hem{base, n, l}: 34u64 <> base <> n <> X.xp_w(l, e, [])
    case O_loft_open{z, bot, top, twist, cont}: 35u64 <> twist <> cont <> X.xp_w(z, e, rgs_w([bot, top], e, []))
    case O_sw_open{deg, rs, g, gd, tw}: 36u64 <> deg <> g <> gd <> tw <> rgs_w(rs, e, [])
    case O_patch{ps}: 37u64 <> xps_w(ps, e, [])
    case O_thicken_open{base, t}: 38u64 <> base <> X.xp_w(t, e, [])
    case O_naca4{m, p, t, c, n}: 39u64 <> m <> p <> t <> n <> X.xp_w(c, e, [])
    case O_blade{secs, z, tw, tp}: 40u64 <> tw <> tp <> us_w(secs, X.xp_w(z, e, []))

def op_base(o: Op) -> U64:
  match o:
    case O_pad{base, f, rs, h}: base
    case O_pocket{base, f, rs, d, thru}: base
    case O_holes{base, f, hs, d, thru}: base
    case O_move{base, tx, ty, tz, q}: base
    case O_rot{base, ax, deg}: base
    case O_union{a, b}: a
    case O_difference{a, b}: a
    case O_intersection{a, b}: a
    case O_chamfer{base, d}: base
    case O_echamf{base, f, cx, cy, r, c}: base
    case O_lchamf{base, nd, n1, n2, c}: base
    case O_fillet{base, r}: base
    case O_fillet_e{base, n, r0, r1}: base
    case O_draft{base, inset}: base
    case O_offset{base, d}: base
    case O_shell{base, t, open}: base
    case O_thicken{base, t}: base
    case O_pat_lin{base, nx, dx, ny, dy, nz, dz}: base
    case O_pat_circ{base, n, r}: base
    case O_ph_lin{base, f, nx, ny, dx, dy, x0, y0, r, d, thru}: base
    case O_ph_circ{base, f, n, rad, cx, cy, r, d, thru}: base
    case O_bend{base, n, r, deg}: base
    case O_hem{base, n, l}: base
    case O_thicken_open{base, t}: base
    case _: 0u64

def op_has_base(o: Op) -> Bool:
  match o:
    case O_pad{base, f, rs, h}: True{}
    case O_pocket{base, f, rs, d, thru}: True{}
    case O_holes{base, f, hs, d, thru}: True{}
    case O_move{base, tx, ty, tz, q}: True{}
    case O_rot{base, ax, deg}: True{}
    case O_union{a, b}: True{}
    case O_difference{a, b}: True{}
    case O_intersection{a, b}: True{}
    case O_chamfer{base, d}: True{}
    case O_echamf{base, f, cx, cy, r, c}: True{}
    case O_lchamf{base, nd, n1, n2, c}: True{}
    case O_fillet{base, r}: True{}
    case O_fillet_e{base, n, r0, r1}: True{}
    case O_draft{base, inset}: True{}
    case O_offset{base, d}: True{}
    case O_shell{base, t, open}: True{}
    case O_thicken{base, t}: True{}
    case O_pat_lin{base, nx, dx, ny, dy, nz, dz}: True{}
    case O_pat_circ{base, n, r}: True{}
    case O_ph_lin{base, f, nx, ny, dx, dy, x0, y0, r, d, thru}: True{}
    case O_ph_circ{base, f, n, rad, cx, cy, r, d, thru}: True{}
    case O_bend{base, n, r, deg}: True{}
    case O_hem{base, n, l}: True{}
    case O_thicken_open{base, t}: True{}
    case _: False{}

def op_base2(o: Op) -> U64:
  match o:
    case O_union{a, b}: b
    case O_difference{a, b}: b
    case O_intersection{a, b}: b
    case _: 0u64

def op_has_b2(o: Op) -> Bool:
  match o:
    case O_union{a, b}: True{}
    case O_difference{a, b}: True{}
    case O_intersection{a, b}: True{}
    case _: False{}

def op_is_bool(o: Op) -> Bool:
  op_has_b2(o)

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
    case O_blob{fmt, payload}: "import"
    case O_revolve{rs}: "revolve"
    case O_cone{r, h}: "cone"
    case O_sph{r}: "sphere"
    case O_tor{bigr, r}: "torus"
    case O_union{a, b}: "union"
    case O_difference{a, b}: "difference"
    case O_intersection{a, b}: "intersection"
    case O_sw_line{z, rs, g, gd, tw}: "sweep"
    case O_sw_arc{deg, rs, g, gd, tw}: "sweep"
    case O_loft{z, bot, top, twist, cont}: "loft"
    case O_chamfer{base, d}: "chamfer"
    case O_echamf{base, f, cx, cy, r, c}: "chamfer"
    case O_lchamf{base, nd, n1, n2, c}: "chamfer"
    case O_fillet{base, r}: "fillet"
    case O_fillet_e{base, n, r0, r1}: "fillet"
    case O_draft{base, inset}: "draft"
    case O_offset{base, d}: "offset"
    case O_shell{base, t, open}: "shell"
    case O_thicken{base, t}: "thicken"
    case O_pat_lin{base, nx, dx, ny, dy, nz, dz}: "pattern"
    case O_pat_circ{base, n, r}: "pattern"
    case O_ph_lin{base, f, nx, ny, dx, dy, x0, y0, r, d, thru}: "pattern-holes"
    case O_ph_circ{base, f, n, rad, cx, cy, r, d, thru}: "pattern-holes"
    case O_flat{l, w, t}: "flat"
    case O_bend{base, n, r, deg}: "bend"
    case O_hem{base, n, l}: "hem"
    case O_loft_open{z, bot, top, twist, cont}: "loft-open"
    case O_sw_open{deg, rs, g, gd, tw}: "sweep-open"
    case O_patch{ps}: "patch"
    case O_thicken_open{base, t}: "thicken-open"
    case O_naca4{m, p, t, c, n}: "naca4"
    case O_blade{secs, z, tw, tp}: "blade"

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

def bool_tag(o: Op) -> U64:
  match o:
    case O_union{a, b}: B8.tag_union()
    case O_difference{a, b}: B8.tag_diff()
    case O_intersection{a, b}: B8.tag_inter()
    case _: 0u64

def bool_in(+x: Body) -> B8.In:
  +m = body_ms(x)
  +p = bd_pl(x)
  B8.In{bd_brep(x), bd_cells(x), bd_fns(x), pl_m(p), pl_tx(p), pl_ty(p), pl_tz(p), bd_rv(x), ms_vol(m),
    ms_area(m), B8.BX{ms_x0(m), ms_x1(m), ms_y0(m), ms_y1(m), ms_z0(m), ms_z1(m)}, ms_lin(m),
    xb_bo(bd_xb(x)), pl_exact(p)}

def bool_mat(+t: U64) -> Mat:
  Bool.pick(Mat, U64.is_eq(t, 1u64), M_add{},
    Bool.pick(Mat, U64.is_eq(t, 2u64), M_remove{},
      Bool.pick(Mat, U64.is_eq(t, 3u64), M_same{}, M_unknown{})))

def bool_kind(+t: U64) -> T.FailKind:
  Bool.pick(T.FailKind, U64.is_eq(t, 0u64), T.F_invalid{},
    Bool.pick(T.FailKind, U64.is_eq(t, 1u64), T.F_uncertain{}, T.F_unsupported{}))

def bool_stored_ms(+r: B8.Out, +b: Ty.Brep) -> Ms:
  Ms{B8.Out_vol(r), B8.Out_area(r), B8.BX_x0(B8.Out_bb(r)), B8.BX_x1(B8.Out_bb(r)),
    B8.BX_y0(B8.Out_bb(r)), B8.BX_y1(B8.Out_bb(r)), B8.BX_z0(B8.Out_bb(r)), B8.BX_z1(B8.Out_bb(r)),
    List.length(&2, Ty.Vertex, Ty.brep_vs(b)), List.length(&2, Ty.Edge, Ty.brep_es(b)),
    List.length(&2, Ty.Face, Ty.brep_fas(b)), B8.Out_sh(r), B8.Out_ho(r), B8.Out_lin(r)}

def bool_body(+r: B8.Out) -> Body:
  +b = B8.Out_brep(r)
  Bd{B8.Out_cells(r), b, B8.Out_fns(r), pl_id(), B8.Out_rv(r),
    Xb{[bool_stored_ms(r, b)], B8.Out_nc(r), True{}, B8.Out_proof(r), B8.Out_del(r)}}

def bool_rewrap(+r: B8.Out, +b: Body) -> Body:
  Bd{bd_cells(b), bd_brep(b), bd_fns(b), bd_pl(b), bd_rv(b),
    Xb{xb_mx(bd_xb(b)), xb_nc(bd_xb(b)), xb_bo(bd_xb(b)), B8.Out_proof(r), B8.Out_del(r)}}

def bool_carry(+r: B8.Out, +b: Body, +b2: Body) -> Body:
  Bool.pick(Body, U64.is_eq(B8.Out_carry(r), 2u64), bool_rewrap(r, b2),
    Bool.pick(Body, U64.is_eq(B8.Out_carry(r), 1u64), bool_rewrap(r, b), bool_body(r)))

def bool_nr(+r: B8.Out, +b: Body, +b2: Body) -> NR:
  Bool.pick(NR, B8.Out_ok(r),
    NR_ok{bool_carry(r, b, b2),
      Fx{bool_mat(B8.Out_mat(r)), B8.Out_fc(r), B8.Out_fm(r), B8.Out_sh(r), B8.Out_ho(r)}},
    nr_err(bool_kind(B8.Out_kind(r)), B8.Out_what(r), B8.Out_loc(r), B8.Out_why(r), B8.Out_fix(r)))

def bool_run(+o: Op, +b: Body, +b2: Body, +nd: U64) -> NR:
  bool_nr(B8.run(bool_tag(o), bool_in(b), bool_in(b2), nd, op_base(o), op_base2(o),
    U64.is_eq(op_base(o), op_base2(o))), b, b2)

def feat_k1_nr(+t: NR, +tag: U64, +b: Body, +nd: U64, +kind: U64) -> NR:
  match t:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+tb, fx}:
      Bool.pick(NR, Nat.is_eq(B8.nsolids(bd_brep(b)), 1n),
        bool_nr(B8.run(tag, bool_in(b), bool_in(tb), nd, 0u64, 0u64, False{}), b, tb),
        bad(kind_what(kind), "node " ++ U64.show(nd), "feature-on-compound",
          "features on multi-solid booleans need per-solid application"))

def feat_k1(+kind: U64, +b: Body, +rs: List<&2, F.Region>, +lo: F64, +hi: F64,
    +thru: Bool, +e: X.Env, +nd: U64) -> NR:
  +m = body_ms(b)
  +z0 = ms_z0(m)
  +z1 = ms_z1(m)
  +mg = F64.add(F64.sub(z1, z0), 1.0f64)
  +t0 = Bool.pick(F64, thru, F64.sub(z0, mg), lo)
  +t1 = Bool.pick(F64, thru, F64.add(z1, mg), hi)
  +tag = Bool.pick(U64, U64.is_eq(kind, 0u64), B8.tag_union(), B8.tag_diff())
  feat_k1_nr(op_prism(rs, xk(t0), xk(t1), e, nd), tag, b, nd, kind)

def feat_or(+k: NR, +orig: NR) -> NR:
  match k:
    case NR_ok{+b, fx}: NR_ok{b, fx}
    case NR_err{kk, d}: orig

def feat_fb(r: NR, +kind: U64, +b: Body, +rs: List<&2, F.Region>, +lo: F64, +hi: F64, +iv: List<&2, F64>,
    +e: X.Env, +nd: U64) -> NR:
  match r:
    case NR_ok{+bb, fx}: NR_ok{bb, fx}
    case NR_err{k, d}:
      +a0 = f_nth(iv, 0n)
      +a1 = f_nth(iv, 1n)
      +top = Bool.not(F64.is_eq(a1, hi))
      feat_or(feat_k1(kind, b, rs, Bool.pick(F64, top, F64.min(a1, hi), F64.min(a0, lo)),
        Bool.pick(F64, top, F64.max(a1, hi), F64.max(a0, lo)), F64.is_eq(f_nth(iv, 2n), 0.0f64), e, nd), NR_err{k, d})

def feat_go(code: U64, +o: BD.Cl, +cs: List<&2, BD.Cl>, +rs: List<&2, F.Region>, +e: X.Env, +nd: U64,
    +iv: List<&2, F64>, +pl: Pl, +kind: U64, +b: Body) -> NR:
  match code:
    case 0u64:
      +r = feat_ev(F.loops_ev(F.rg_loops(rs), e, 0n), o, cs, rs, nd, f_nth(iv, 0n), f_nth(iv, 1n),
        F64.is_eq(f_nth(iv, 2n), 1.0f64), pl, kind_what(kind))
      feat_fb(r, kind, b, rs, BD.cl_lo(o), BD.cl_hi(o), iv, e, nd)
    case 1u64: bad(kind_what(kind), "node " ++ U64.show(nd), "face-not-found", "select a face by its creating node, cell and side")
    case 5u64: nr_err(T.F_unsupported{}, kind_what(kind), "node " ++ U64.show(nd), "features-need-an-extruded-body",
      "features act on prism, box and cylinder bodies along z; other placements need booleans (C08)")
    case 6u64: bad(kind_what(kind), "node " ++ U64.show(nd), "feature-on-empty-compound",
      "features need material to act on; pick a non-empty base node")
    case 7u64:
      +lo = BD.cl_lo(o)
      +hi = BD.cl_hi(o)
      +a0 = f_nth(iv, 0n)
      +a1 = f_nth(iv, 1n)
      +top = Bool.not(F64.is_eq(a1, hi))
      feat_k1(kind, b, rs, Bool.pick(F64, top, F64.min(a1, hi), F64.min(a0, lo)),
        Bool.pick(F64, top, F64.max(a1, hi), F64.max(a0, lo)), F64.is_eq(f_nth(iv, 2n), 0.0f64), e, nd)
    case 2u64: bad(kind_what(kind), "node " ++ U64.show(nd), "no-such-face", "that cell's top or bottom is part of another face; select the owning cell")
    case 3u64: bad(kind_what(kind), "node " ++ U64.show(nd), "nonpositive-amount", "use a positive finite height or depth")
    case _: bad(kind_what(kind), "node " ++ U64.show(nd), "depth-reaches-opposite-face", "use a smaller depth or a through cut")

def sel_nm(s: Sel) -> String:
  Sel{nd, k, side, nm} = s
  nm

def name_idx(fs: List<&2, BD.Fn>, +nm: String, +i: Nat) -> Nat:
  match fs:
    case []: i
    case +f <> t: Bool.pick(Nat, String.eq(BD.fn_name(f), nm), i, name_idx(t, nm, Nat.add(i, 1n)))

def name_pieces(fs: List<&2, BD.Fn>, +nm: String, +n: Nat) -> Nat:
  match fs:
    case []: n
    case +f <> t: name_pieces(t, nm, Bool.pick(Nat, Bool.and(String.eq(BD.fn_base(f), nm), U64.is_lt(0u64, BD.fn_piece_of(f))), Nat.add(n, 1n), n))

def fa_nth(fs: List<&2, Ty.Face>, +i: Nat) -> Ty.Face:
  match fs:
    case []: Ty.Fa{0u64, Ty.surf_zero(), [], True{}, 0.0f64, 0.0f64}
    case f <> t:
      match i:
        case 0n: f
        case 1n+j: fa_nth(t, j)

type FR is Data:
  FR{ ok: Bool, o: V.Point, u: V.Dir, w: V.Dir, n: V.Dir }

def fr_ok(+f: FR) -> Bool:
  FR{ok, o, u, w, n} = f
  ok

def fr_o(+f: FR) -> V.Point:
  FR{ok, o, u, w, n} = f
  o

def fr_u(+f: FR) -> V.Dir:
  FR{ok, o, u, w, n} = f
  u

def fr_w(+f: FR) -> V.Dir:
  FR{ok, o, u, w, n} = f
  w

def fr_n(+f: FR) -> V.Dir:
  FR{ok, o, u, w, n} = f
  n

def unit_ax(+x: F64) -> Bool:
  Bool.or(F64.is_eq(x, 0.0f64), F64.is_eq(F64.abs(x), 1.0f64))

def dir_ax(+d: V.Dir) -> Bool:
  Bool.and(unit_ax(V.dr_x(d)), Bool.and(unit_ax(V.dr_y(d)), unit_ax(V.dr_z(d))))

def dcross(+a: V.Dir, +b: V.Dir) -> V.Dir:
  V.Dr{F64.sub(F64.mul(V.dr_y(a), V.dr_z(b)), F64.mul(V.dr_z(a), V.dr_y(b))),
    F64.sub(F64.mul(V.dr_z(a), V.dr_x(b)), F64.mul(V.dr_x(a), V.dr_z(b))),
    F64.sub(F64.mul(V.dr_x(a), V.dr_y(b)), F64.mul(V.dr_y(a), V.dr_x(b)))}

def dneg(+a: V.Dir) -> V.Dir:
  V.Dr{F64.neg(V.dr_x(a)), F64.neg(V.dr_y(a)), F64.neg(V.dr_z(a))}

def frame_of(f: Ty.Face) -> FR:
  Ty.Fa{g, +sf, ls, +same, slv, sla} = f
  match sf:
    case G.GV_pl{w}:
      G.Pl{+o, +u, +v} = w
      +n0 = dcross(u, v)
      +n = Bool.pick(V.Dir, same, n0, dneg(n0))
      +y = dcross(n, u)
      FR{Bool.and(dir_ax(u), Bool.and(dir_ax(y), dir_ax(n))), o, u, y, n}
    case _: FR{False{}, V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}}

def fa_planar(f: Ty.Face) -> Bool:
  Ty.Fa{g, sf, ls, same, slv, sla} = f
  match sf:
    case G.GV_pl{w}: True{}
    case _: False{}

def pl_frame(p: Pl, +fr: FR) -> Pl:
  Pl{+m, +tx, +ty, +tz, +mi, +ti} = p
  FR{ok, +o, +u, +y, +n} = fr
  +fm = {V.M3{V.dr_x(u), V.dr_x(y), V.dr_x(n), V.dr_y(u), V.dr_y(y), V.dr_y(n), V.dr_z(u), V.dr_z(y), V.dr_z(n)} : V.Mat3}
  +fi = ipts(m3_l(fm))
  +t = m3_ap(m, V.pt_x(o), V.pt_y(o), V.pt_z(o))
  +tr = im_ap(mi, ipts([V.pt_x(o), V.pt_y(o), V.pt_z(o)]))
  Pl{m3_mul(m, fm), F64.add(f_nth(t, 0n), tx), F64.add(f_nth(t, 1n), ty), F64.add(f_nth(t, 2n), tz), im_mul(mi, fi),
    [padd(i_nth(tr, 0n), i_nth(ti, 0n)), padd(i_nth(tr, 1n), i_nth(ti, 1n)), padd(i_nth(tr, 2n), i_nth(ti, 2n))]}

def feat_nm_nr(+t: NR, +tag: U64, +b: Body, +fr: FR, +nd: U64, +kind: U64) -> NR:
  match t:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+tb, fx}:
      +tool = {Bd{bd_cells(tb), bd_brep(tb), bd_fns(tb), pl_frame(bd_pl(b), fr), bd_rv(tb), bd_xb(tb)} : Body}
      Bool.pick(NR, Nat.is_eq(B8.nsolids(bd_brep(b)), 1n),
        bool_nr(B8.run(tag, bool_in(b), bool_in(tool), nd, 0u64, 0u64, False{}), b, tool),
        bad(kind_what(kind), "node " ++ U64.show(nd), "feature-on-compound",
          "features on multi-solid bodies need per-solid application"))

def feat_nm_go(+code: U64, +kind: U64, +b: Body, +nm: String, +fr: FR, +rs: List<&2, F.Region>, +lo: F64, +hi: F64,
    +e: X.Env, +nd: U64, +np: Nat) -> NR:
  match code:
    case 0u64:
      +tag = Bool.pick(U64, U64.is_eq(kind, 0u64), B8.tag_union(), B8.tag_diff())
      feat_nm_nr(op_prism(rs, xk(lo), xk(hi), e, nd), tag, b, fr, nd, kind)
    case 1u64: bad(kind_what(kind), "node " ++ U64.show(nd), "face-not-found: " ++ nm, "select a face name from the faces verb")
    case 2u64: bad(kind_what(kind), "node " ++ U64.show(nd), "ambiguous-face: " ++ nm ++ " was split into " ++ Nat.show(np) ++ " pieces",
      "select one of " ++ nm ++ ".p0 to " ++ nm ++ ".p" ++ Nat.show(Nat.sub(np, 1n)))
    case 3u64: bad(kind_what(kind), "node " ++ U64.show(nd), "feature-face-not-planar: " ++ nm, "features act on planar faces")
    case 4u64: nr_err(T.F_unsupported{}, kind_what(kind), "node " ++ U64.show(nd), "feature-face-oblique: " ++ nm,
      "features on faces whose frame is not axis-aligned need general placements")
    case _: bad(kind_what(kind), "node " ++ U64.show(nd), "nonpositive-amount", "use a positive finite height or depth")

def op_feat_nm(+kind: U64, +b: Body, +nm: String, +rs: List<&2, F.Region>, +amt: X.Xp, +thru: Bool, +e: X.Env, +nd: U64) -> NR:
  +fns = bd_fns(b)
  +fi = name_idx(fns, nm, 0n)
  +nf = List.length(&2, BD.Fn, fns)
  +np = name_pieces(fns, nm, 0n)
  +fa = fa_nth(Ty.brep_fas(bd_brep(b)), fi)
  +fr = frame_of(fa)
  +a = X.xp_ev(amt, e)
  +ms = body_ms(b)
  +big = F64.add(F64.add(F64.add(F64.sub(ms_x1(ms), ms_x0(ms)), F64.sub(ms_y1(ms), ms_y0(ms))), F64.sub(ms_z1(ms), ms_z0(ms))), 1.0f64)
  +aok = Bool.or(Bool.and(thru, Bool.not(U64.is_eq(kind, 0u64))), Bool.and(T.is_finite(a), F64.is_lt(0.0f64, a)))
  +lo = Bool.pick(F64, U64.is_eq(kind, 0u64), 0.0f64, Bool.pick(F64, thru, F64.neg(big), F64.neg(a)))
  +hi = Bool.pick(F64, U64.is_eq(kind, 0u64), a, 0.0f64)
  +code = Bool.pick(U64, Nat.is_lt(fi, nf),
    Bool.pick(U64, fa_planar(fa), Bool.pick(U64, fr_ok(fr), Bool.pick(U64, aok, 0u64, 5u64), 4u64), 3u64),
    Bool.pick(U64, Nat.is_lt(0n, np), 2u64, 1u64))
  feat_nm_go(code, kind, b, nm, fr, rs, lo, hi, e, nd, np)

type FI is Data:
  FI{ planar: Bool, fr: FR }

def fi_planar(+x: FI) -> Bool:
  FI{planar, fr} = x
  planar

def fi_fr(+x: FI) -> FR:
  FI{planar, fr} = x
  fr

def face_fi(+f: Ty.Face) -> FI:
  FI{fa_planar(f), frame_of(f)}

def fi_at(+br: Ty.Brep, +i: Nat) -> FI:
  face_fi(fa_nth(Ty.brep_fas(br), i))

def tri_rg(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64) -> F.Region:
  path_rg(xk(ax), xk(ay), [F.S_line{xk(bx), xk(by)}, F.S_line{xk(cx), xk(cy)}])

def ech_rg(+hole: Bool, +r: F64, +c: F64) -> F.Region:
  +e = F64.mul(0.25f64, c)
  +lo = F64.neg(F64.add(c, e))
  +rin = F64.sub(r, e)
  +rout = F64.add(F64.add(r, c), e)
  +bin = F64.sub(F64.sub(r, c), e)
  +bout = F64.add(r, e)
  Bool.pick(F.Region, hole, tri_rg(rin, lo, rout, e, rin, e), tri_rg(bin, e, bout, lo, bout, e))

def fd_by(fs: List<&2, SO.Fd>, +fi: Nat) -> SO.Fd:
  match fs:
    case []: SO.fd_dflt()
    case +f <> t: Bool.pick(SO.Fd, Nat.is_eq(SO.fd_fi(f), fi), f, fd_by(t, fi))

def on_face(+b: Ty.Brep, +fi: Nat, +p: V.Point) -> Bool:
  +fd = fd_by(SO.fds_of(b), fi)
  U64.is_eq(Mm.member(SO.fd_fc(fd), MM.p3(p), SO.fd_im(fd)), 1u64)

def lin3(+a: F64, +x: F64, +u: F64, +y: F64, +w: F64) -> F64:
  F64.add(F64.add(a, F64.mul(x, u)), F64.mul(y, w))

def pt3(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}

def fr_at(+fr: FR, +x: F64, +y: F64) -> FR:
  FR{ok, +o, +u, +w, +n} = fr
  +px = lin3(V.pt_x(o), x, V.dr_x(u), y, V.dr_x(w))
  +py = lin3(V.pt_y(o), x, V.dr_y(u), y, V.dr_y(w))
  +pz = lin3(V.pt_z(o), x, V.dr_z(u), y, V.dr_z(w))
  FR{ok, pt3(px, py, pz), u, w, n}

def fr_pt(+fr: FR) -> V.Point:
  FR{ok, o, u, w, n} = fr
  o

def ech_nr(+t: NR, +b: Body, +fr: FR, +nd: U64) -> NR:
  match t:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+tb, fx}:
      +tool = {Bd{bd_cells(tb), bd_brep(tb), bd_fns(tb), pl_frame(bd_pl(b), fr), bd_rv(tb), bd_xb(tb)} : Body}
      bool_nr(B8.run(B8.tag_diff(), bool_in(b), bool_in(tool), nd, 0u64, 0u64, False{}), b, tool)

def ech_go(+code: U64, +b: Body, +nm: String, +fr: FR, +hole: Bool, +r: F64, +c: F64, +e: X.Env, +nd: U64, +np: Nat) -> NR:
  match code:
    case 0u64: ech_nr(op_rev([ech_rg(hole, r, c)], e, nd), b, fr, nd)
    case 1u64: bad("chamfer", "node " ++ U64.show(nd), "face-not-found: " ++ nm, "select a face name from the faces verb")
    case 2u64: bad("chamfer", "node " ++ U64.show(nd), "ambiguous-face: " ++ nm ++ " was split into " ++ Nat.show(np) ++ " pieces",
      "select one of " ++ nm ++ ".p0 to " ++ nm ++ ".p" ++ Nat.show(Nat.sub(np, 1n)))
    case 3u64: bad("chamfer", "node " ++ U64.show(nd), "feature-face-not-planar: " ++ nm, "edge chamfers act on circles in planar faces")
    case 4u64: nr_err(T.F_unsupported{}, "chamfer", "node " ++ U64.show(nd), "feature-face-oblique: " ++ nm,
      "edge chamfers on faces whose frame is not axis-aligned need general placements")
    case _: bad("chamfer", "node " ++ U64.show(nd), "bad-chamfer", "use a positive chamfer smaller than the circle radius")

def op_echamf(+b: Body, +s: Sel, +xx: X.Xp, +yy: X.Xp, +rr: X.Xp, +cc: X.Xp, +e: X.Env, +nd: U64) -> NR:
  +nm = sel_nm(s)
  +fns = bd_fns(b)
  +fi = name_idx(fns, nm, 0n)
  +nf = List.length(&2, BD.Fn, fns)
  +np = name_pieces(fns, nm, 0n)
  +inf = fi_at(bd_brep(b), fi)
  +x = X.xp_ev(xx, e)
  +y = X.xp_ev(yy, e)
  +r = X.xp_ev(rr, e)
  +c = X.xp_ev(cc, e)
  +fr = fr_at(fi_fr(inf), x, y)
  +probe = fr_pt(fr_at(fi_fr(inf), F64.add(x, F64.add(r, F64.mul(0.5f64, c))), y))
  +hole = on_face(bd_brep(b), fi, probe)
  +cok = Bool.and(Bool.and(T.is_finite(c), F64.is_lt(0.0f64, c)), Bool.and(T.is_finite(r), F64.is_lt(c, r)))
  +code = Bool.pick(U64, Nat.is_lt(fi, nf),
    Bool.pick(U64, fi_planar(inf), Bool.pick(U64, fr_ok(fr), Bool.pick(U64, cok, 0u64, 5u64), 4u64), 3u64),
    Bool.pick(U64, Nat.is_lt(0n, np), 2u64, 1u64))
  ech_go(code, b, nm, fr, hole, r, c, e, nd, np)
def nat_has(xs: List<&2, Nat>, +x: Nat) -> Bool:
  match xs:
    case []: False{}
    case +h <> t: Bool.or(Nat.is_eq(h, x), nat_has(t, x))

def shared_go(+n: Nat, +e: Nat, +b: Ty.Brep, +f1: Nat, +f2: Nat) -> Nat:
  match n:
    case 0n: e
    case 1n+m:
      +fs = FB.edge_faces(b, e)
      Bool.pick(Nat, Bool.and(nat_has(fs, f1), nat_has(fs, f2)), e, shared_go(m, Nat.add(e, 1n), b, f1, f2))

def dsc(+k: F64, +d: V.Dir) -> V.Dir:
  V.Dr{F64.mul(k, V.dr_x(d)), F64.mul(k, V.dr_y(d)), F64.mul(k, V.dr_z(d))}

def pmove(+p: V.Point, +k: F64, +d: V.Dir) -> V.Point:
  pt3(F64.add(V.pt_x(p), F64.mul(k, V.dr_x(d))), F64.add(V.pt_y(p), F64.mul(k, V.dr_y(d))), F64.add(V.pt_z(p), F64.mul(k, V.dr_z(d))))

def pdot(+a: V.Point, +b: V.Point, +d: V.Dir) -> F64:
  F64.add(F64.add(F64.mul(F64.sub(V.pt_x(b), V.pt_x(a)), V.dr_x(d)), F64.mul(F64.sub(V.pt_y(b), V.pt_y(a)), V.dr_y(d))),
    F64.mul(F64.sub(V.pt_z(b), V.pt_z(a)), V.dr_z(d)))

def lch_nr(+t: NR, +b: Body, +fr: FR, +nd: U64) -> NR:
  match t:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+tb, fx}:
      +tool = {Bd{bd_cells(tb), bd_brep(tb), bd_fns(tb), pl_frame(bd_pl(b), fr), bd_rv(tb), bd_xb(tb)} : Body}
      bool_nr(B8.run(B8.tag_diff(), bool_in(b), bool_in(tool), nd, 0u64, 0u64, False{}), b, tool)

def lch_go(+code: U64, +b: Body, +n1: String, +n2: String, +fr: FR, +c: F64, +len: F64, +e: X.Env, +nd: U64) -> NR:
  match code:
    case 0u64:
      +x = F64.mul(0.25f64, c)
      +rg = tri_rg(F64.neg(x), F64.neg(x), F64.add(c, x), F64.neg(x), F64.neg(x), F64.add(c, x))
      lch_nr(op_prism([rg], xk(F64.neg(x)), xk(F64.add(len, x)), e, nd), b, fr, nd)
    case 1u64: bad("chamfer", "node " ++ U64.show(nd), "face-not-found: " ++ n1 ++ " or " ++ n2, "select face names from the faces verb")
    case 2u64: bad("chamfer", "node " ++ U64.show(nd), "faces-share-no-edge: " ++ n1 ++ " " ++ n2, "name two planar faces that meet along one straight edge")
    case 3u64: nr_err(T.F_unsupported{}, "chamfer", "node " ++ U64.show(nd), "edge-not-convex: " ++ n1 ++ " " ++ n2,
      "chamfers add no material; a concave edge needs a fillet or a pad")
    case 4u64: nr_err(T.F_unsupported{}, "chamfer", "node " ++ U64.show(nd), "feature-face-oblique: " ++ n1 ++ " " ++ n2,
      "edge chamfers need axis-aligned faces and edges; oblique placements need general placements")
    case _: bad("chamfer", "node " ++ U64.show(nd), "bad-chamfer", "use a positive chamfer")

def op_lchamf(+b: Body, +n1: String, +n2: String, +cc: X.Xp, +e: X.Env, +nd: U64) -> NR:
  +br = bd_brep(b)
  +fns = bd_fns(b)
  +nf = List.length(&2, BD.Fn, fns)
  +f1 = name_idx(fns, n1, 0n)
  +f2 = name_idx(fns, n2, 0n)
  +i1 = fi_at(br, f1)
  +i2 = fi_at(br, f2)
  +a = fr_n(fi_fr(i1))
  +bn = fr_n(fi_fr(i2))
  +d = dcross(a, bn)
  +ne = FB.nedges(br)
  +ei = shared_go(ne, 0n, br, f1, f2)
  +p0 = FB.vpt(br, Ty.ed_v0(FB.edge_at(br, ei)))
  +p1 = FB.vpt(br, Ty.ed_v1(FB.edge_at(br, ei)))
  +t = pdot(p0, p1, d)
  +o = Bool.pick(V.Point, F64.is_lt(0.0f64, t), p0, p1)
  +len = F64.abs(t)
  +c = X.xp_ev(cc, e)
  +fr = {FR{True{}, o, dneg(a), dneg(bn), d} : FR}
  +probe = pmove(pmove(pmove(o, F64.mul(0.5f64, len), d), F64.neg(F64.mul(0.25f64, c)), a), F64.neg(F64.mul(0.25f64, c)), bn)
  +convex = U64.is_eq(SO.classify(SO.fds_of(br), probe), 1u64)
  +axok = Bool.and(fr_ok(fi_fr(i1)), Bool.and(fr_ok(fi_fr(i2)), dir_ax(d)))
  +cok = Bool.and(T.is_finite(c), F64.is_lt(0.0f64, c))
  +code = Bool.pick(U64, Bool.and(Nat.is_lt(f1, nf), Nat.is_lt(f2, nf)),
    Bool.pick(U64, Bool.and(fi_planar(i1), fi_planar(i2)),
      Bool.pick(U64, Nat.is_lt(ei, ne), Bool.pick(U64, axok, Bool.pick(U64, convex, Bool.pick(U64, cok, 0u64, 5u64), 3u64), 4u64), 2u64), 2u64),
    1u64)
  lch_go(code, b, n1, n2, fr, c, len, e, nd)
def op_feat_cell(+kind: U64, +b: Body, +s: Sel, +rs: List<&2, F.Region>, +amt: X.Xp, +thru: Bool, +e: X.Env, +nd: U64, +base: U64) -> NR:
  Sel{+snd, +sk, +side, nm} = s
  +cs = bd_cells(b)
  +ds = BD.cds_of(cs)
  +ix = find_cell(ds, snd, sk, base)
  +d = B.tb_get(BD.Cd, B.tb_of(BD.Cd, ds, BD.cd_pad()), U32.from_nat(Nat.sub(ix, 1n)))
  +o = BD.cd_c(d)
  +owner = Bool.and(BD.cl_mat(o), Bool.not(Bool.pick(Bool, U64.is_eq(side, 0u64), BD.cd_ttr(d), BD.cd_btr(d))))
  +a = X.xp_ev(amt, e)
  +aok = Bool.or(Bool.and(thru, Bool.not(U64.is_eq(kind, 0u64))), Bool.and(T.is_finite(a), F64.is_lt(0.0f64, a)))
  +iv = ivl(kind, side, BD.cl_lo(o), BD.cl_hi(o), a, thru)
  +nonempty = Bool.or(F64.is_eq(f_nth(iv, 2n), 0.0f64), F64.is_lt(f_nth(iv, 0n), f_nth(iv, 1n)))
  +isEmpty = Bool.and(Nat.is_eq(List.length(&2, BD.Cl, cs), 0n),
    Nat.is_eq(List.length(&2, Ty.Solid, Ty.brep_sos(bd_brep(b))), 0n))
  +isBool = xb_bo(bd_xb(b))
  +code = Bool.pick(U64, isEmpty, 6u64,
    Bool.pick(U64, Nat.is_eq(List.length(&2, BD.Cl, cs), 0n), 5u64,
      Bool.pick(U64, Nat.is_eq(ix, 0n), 1u64, Bool.pick(U64, Bool.not(owner), 2u64,
        Bool.pick(U64, Bool.not(aok), 3u64, Bool.pick(U64, Bool.not(nonempty), 4u64,
          Bool.pick(U64, isBool, 7u64, 0u64)))))))
  feat_go(code, o, cs, rs, e, nd, iv, bd_pl(b), kind, b)

def op_feat_sel(+named: Bool, +kind: U64, +b: Body, +s: Sel, +rs: List<&2, F.Region>, +amt: X.Xp, +thru: Bool, +e: X.Env, +nd: U64, +base: U64) -> NR:
  match named:
    case True{}:
      Sel{snd, sk, side, +nm} = s
      op_feat_nm(kind, b, nm, rs, amt, thru, e, nd)
    case False{}: op_feat_cell(kind, b, s, rs, amt, thru, e, nd, base)

def op_feat(+kind: U64, +b: Body, +s: Sel, +rs: List<&2, F.Region>, +amt: X.Xp, +thru: Bool, +e: X.Env, +nd: U64, +base: U64) -> NR:
  op_feat_sel(Bool.not(String.is_empty(sel_nm(s))), kind, b, s, rs, amt, thru, e, nd, base)

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
  Ty.Fa{g, s, +ls, same, slv, sla} = f
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

def mat_eq(+r: I.I, +b: I.I) -> Bool:
  Bool.and(F64.is_eq(I.i_lo(r), I.i_lo(b)), F64.is_eq(I.i_hi(r), I.i_hi(b)))

def mat_go(eq: Bool, +r: I.I, +b: I.I) -> Mat:
  match eq:
    case True{}: M_same{}
    case False{}: Bool.pick(Mat, F64.is_lt(I.i_hi(b), I.i_lo(r)), M_add{}, Bool.pick(Mat, F64.is_lt(I.i_hi(r), I.i_lo(b)), M_remove{}, M_unknown{}))

def mat_cmp(+r: I.I, +b: I.I) -> Mat:
  mat_go(mat_eq(r, b), r, b)

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
      +f = Bool.pick(Fx, op_is_bool(o), f0, fx_of(o, hasb, b, rb))
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
    case NR_err{k, d}: Bd{[], Ty.brep_empty(), [], pl_id(), [], xb_id()}

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

def n2f(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))

def fpos(+v: F64) -> Bool:
  Bool.and(T.is_finite(v), F64.is_lt(0.0f64, v))

def eq0(+v: F64) -> Bool:
  F64.is_eq(v, 0.0f64)

def why_unsup(+y: String) -> Bool:
  Bool.or(String.eq(y, "guide-not-admitted"), Bool.or(String.eq(y, "twist-not-admitted"),
    Bool.or(String.eq(y, "sweep-angle-not-certified"), Bool.or(String.eq(y, "continuity-not-met"),
      Bool.or(String.eq(y, "chamfer-base-not-admitted"), Bool.or(String.eq(y, "fillet-base-not-admitted"),
        Bool.or(String.eq(y, "fillet-edge-not-admitted"), Bool.or(String.eq(y, "draft-base-not-admitted"),
          Bool.or(String.eq(y, "offset-base-not-admitted"), Bool.or(String.eq(y, "shell-base-not-admitted"),
            Bool.or(String.eq(y, "pattern-copies-overlap"), Bool.or(String.eq(y, "pattern-angle-not-certified"),
              Bool.or(String.eq(y, "pattern-count-not-admitted"), Bool.or(String.eq(y, "bend-angle-not-certified"),
                Bool.or(String.eq(y, "bend-edge-not-admitted"), Bool.or(String.eq(y, "bend-radius-too-tight"),
  Bool.or(String.eq(y, "loft-open-not-planar"), Bool.or(String.eq(y, "sweep-profile-not-admitted"),
    Bool.or(String.eq(y, "thicken-curvature-not-certified"), Bool.or(String.eq(y, "naca-digits-not-admitted"),
      Bool.or(String.eq(y, "naca-points-not-admitted"), Bool.or(String.eq(y, "blade-sections-not-admitted"),
        String.eq(y, "taper-not-admitted")))))))))))))))))))))))

def why_k(u: Bool, +c: Bool) -> T.FailKind:
  match u:
    case True{}: T.F_unsupported{}
    case False{}:
      match c:
        case True{}: T.F_uncertain{}
        case False{}: T.F_invalid{}

def why_nr(+what: String, +nd: U64, +y: String) -> NR:
  nr_err(why_k(why_unsup(y), String.eq(y, "loft-not-certified")), what, "node " ++ U64.show(nd), y, "stay inside the admitted feature")

def unc_nr(+what: String, +nd: U64, +y: String) -> NR:
  nr_err(T.F_uncertain{}, what, "node " ++ U64.show(nd), y, "report this design")

def nd_op(ns: List<&2, Node>, +id: U64) -> Op:
  match ns:
    case []: O_unk{"missing"}
    case n <> t:
      Nd{nid, op, it} = n
      Bool.pick(Op, U64.is_eq(nid, id), op, nd_op(t, id))

def base_kind(o: Op) -> U64:
  match o:
    case O_box{x, y, z}: 1u64
    case O_cyl{r, h}: 2u64
    case _: 0u64

def bb_vx(b: Bb, v: Ty.Vertex) -> Bb:
  Ty.Vx{id, p} = v
  V.Pt{x, y, +z} = p
  bb_z(bb_pt(b, x, y), z, z)

def bb_vs(vs: List<&2, Ty.Vertex>, +b: Bb) -> Bb:
  match vs:
    case []: b
    case v <> t: bb_vs(t, bb_vx(b, v))

def ms_formula(+vol: F64, +br: Ty.Brep) -> Ms:
  +bb0 = bb_vs(Ty.brep_vs(br), bb_empty())
  +lin = F64.mul(bb_m(bb0), 1.7763568394002505e-15f64)
  +bm = bb_m(bb0)
  ms_mk(Acc{I.ipt(vol), I.ipt(F64.mul(24.0f64, F64.mul(bm, bm))), I.ipt(F64.mul(8.0f64, bm))}, bb_wid(bb0, lin), lin, br)

def ms_set_vol(+m: Ms, +v: F64) -> Ms:
  Ms{vol, +area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, +lin} = m
  Ms{I.iwiden(I.ipt(v), F64.mul(I.i_hi(area), lin)), area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin}

def ms_scale_vol(+m: Ms, +k: F64) -> Ms:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  I.I{lo, hi} = vol
  Ms{I.I{F64.mul(lo, k), F64.mul(hi, k)}, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin}

def ms_put_vol(+m: Ms, +v: I.I) -> Ms:
  Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  Ms{v, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin}

def dels_why(fs: List<&2, BD.Fn>, +w: U64) -> List<&2, B8.Del>:
  match fs:
    case []: []
    case f <> t: B8.Del{f, w} <> dels_why(t, w)

def nr_rv(clear: Bool, +rv: List<&2, F.Lp>) -> List<&2, F.Lp>:
  match clear:
    case True{}: []
    case False{}: rv

def nr_take_ok(+b: Body, +fx: Fx, +vol: F64, +pr: String, +dl: List<&2, B8.Del>, +bo: Bool, +clear: Bool) -> NR:
  NR_ok{Bd{[], bd_brep(b), bd_fns(b), bd_pl(b), nr_rv(clear, bd_rv(b)), Xb{[ms_set_vol(body_ms(b), vol)], xb_nc(bd_xb(b)), bo, pr, dl}}, fx}

def nr_take(r: NR, +vol: F64, +pr: String, +dl: List<&2, B8.Del>, +bo: Bool, +clear: Bool) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+b, fx}: nr_take_ok(b, fx, vol, pr, dl, bo, clear)

def nr_pr_ok(+b: Body, +fx: Fx, +pr: String) -> NR:
  NR_ok{Bd{bd_cells(b), bd_brep(b), bd_fns(b), bd_pl(b), bd_rv(b), Xb{xb_mx(bd_xb(b)), xb_nc(bd_xb(b)), xb_bo(bd_xb(b)), pr, xb_dl(bd_xb(b))}}, fx}

def nr_pr(r: NR, +pr: String) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+b, fx}: nr_pr_ok(b, fx, pr)

def nr_ident(+b: Body, +pr: String) -> NR:
  NR_ok{Bd{[], bd_brep(b), bd_fns(b), bd_pl(b), [], Xb{[body_ms(b)], xb_nc(bd_xb(b)), False{}, pr, []}},
    Fx{M_same{}, 0n, 0n, 0n, 0n}}

def nr_rewhy_ok(+b: Body, +fx: Fx, +w: U64) -> NR:
  NR_ok{Bd{bd_cells(b), bd_brep(b), bd_fns(b), bd_pl(b), bd_rv(b), Xb{xb_mx(bd_xb(b)), xb_nc(bd_xb(b)), xb_bo(bd_xb(b)), xb_pr(bd_xb(b)), dels_why(bd_fns(b), w)}}, fx}

def nr_rewhy(r: NR, +w: U64) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+b, fx}: nr_rewhy_ok(b, fx, w)

def mesh_nr(r: NR, +vol: F64, +dl: List<&2, B8.Del>, +pr: String) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+b, fx}:
      NR_ok{Bd{[], bd_brep(b), bd_fns(b), pl_id(), [], Xb{[ms_formula(vol, bd_brep(b))], 0n, False{}, pr, dl}}, fx}

def mesh_go(bt: BD.Bt, +vol: F64, +what: String, +dl: List<&2, B8.Del>, +pr: String) -> NR:
  mesh_nr(bt_check(bt, [], pl_id(), what, []), vol, dl, pr)

def mesh_go_open(bt: BD.Bt, +what: String) -> NR:
  mesh_nr(bt_check_open(bt, [], pl_id(), what, []), 0.0f64, [], "open-shell-1")

def sw_pe_go(z: Bool, +e: F.Er, +nd: U64) -> NR:
  match z:
    case True{}: why_nr("sweep", nd, "degenerate-feature")
    case False{}: pe_nr(e, "sweep profile")

def sw_pe(e: F.Er, +nd: U64) -> NR:
  F.Er{+code, lp, sg} = e
  sw_pe_go(U64.is_eq(code, 7u64), F.Er{code, lp, sg}, nd)

def sw_lp(c: F.CK, +z: X.Xp, +rs: List<&2, F.Region>, +g: U64, +e: X.Env, +nd: U64) -> NR:
  match c:
    case F.CK_err{e}: sw_pe(e, nd)
    case F.CK_ok{ls, ps}: nr_pr(op_prism(rs, xk(0.0f64), z, e, nd), F9.guide_pr(g))

def sw_lt(ok: Bool, +z: X.Xp, +rs: List<&2, F.Region>, +g: U64, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("sweep", nd, "twist-not-admitted")
    case True{}: sw_lp(F.prof_check(rs, e), z, rs, g, e, nd)

def sw_lg(ok: Bool, +z: X.Xp, +rs: List<&2, F.Region>, +g: U64, +tw: U64, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("sweep", nd, "guide-not-admitted")
    case True{}: sw_lt(String.eq(F9.why_twist(tw), ""), z, rs, g, e, nd)

def sw_lz(ok: Bool, +z: X.Xp, +rs: List<&2, F.Region>, +g: U64, +gd: U64, +tw: U64, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("sweep", nd, "degenerate-feature")
    case True{}: sw_lg(String.eq(F9.why_guide(0u64, g, gd, 0u64), ""), z, rs, g, tw, e, nd)

def op_sw_line(+z: X.Xp, +rs: List<&2, F.Region>, +g: U64, +gd: U64, +tw: U64, +e: X.Env, +nd: U64) -> NR:
  sw_lz(fpos(X.xp_ev(z, e)), z, rs, g, gd, tw, e, nd)

def sw_scale(r: NR, +pp: List<&2, F.Lp>, +deg: U64, +g: U64) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+b, fx}:
      +m = ms_scale_vol(rev_ms(pp, bd_brep(b), pl_id()), F9.sw_k(deg))
      NR_ok{Bd{[], bd_brep(b), bd_fns(b), pl_id(), [], Xb{[m], 0n, False{}, F9.guide_pr(g), []}}, fx}

def sw_sec_go(ok: Bool, +code: U64, +lp: Nat, +b: BD.Bt, +pp: List<&2, F.Lp>, +deg: U64, +g: U64) -> NR:
  match ok:
    case False{}: pe_nr(F.Er{code, lp, 0n}, "sweep profile")
    case True{}: sw_scale(bt_check(b, [], pl_id(), "sweep", []), pp, deg, g)

def sw_sec(r: RV.RR, +pp: List<&2, F.Lp>, +deg: U64, +g: U64) -> NR:
  RV.RR{+code, lp, b} = r
  sw_sec_go(U64.is_eq(code, 0u64), code, lp, b, pp, deg, g)

def sw_full(full: Bool, +pp: List<&2, F.Lp>, +ps: List<&2, Nat>, +hs: List<&2, Bool>, +deg: U64, +g: U64, +nd: U64) -> NR:
  match full:
    case True{}: nr_pr(rev_go(F.Er{0u64, 0n, 0n}, pp, ps, hs, nd), F9.guide_pr(g))
    case False{}: sw_sec(RV.sec_rr(pp, hs, nd, F9.sw_quads(deg)), pp, deg, g)

def sw_ax_go(ok: Bool, +e: F.Er, +pp: List<&2, F.Lp>, +ps: List<&2, Nat>, +hs: List<&2, Bool>, +deg: U64, +g: U64, +nd: U64) -> NR:
  match ok:
    case False{}: pe_nr(e, "sweep profile")
    case True{}: sw_full(U64.is_eq(deg, 360u64), pp, ps, hs, deg, g, nd)

def sw_ax(e: F.Er, +pp: List<&2, F.Lp>, +ps: List<&2, Nat>, +hs: List<&2, Bool>, +deg: U64, +g: U64, +nd: U64) -> NR:
  F.Er{+code, lp, sg} = e
  sw_ax_go(U64.is_eq(code, 0u64), F.Er{code, lp, sg}, pp, ps, hs, deg, g, nd)

def sw_ap(c: F.CK, +deg: U64, +rs: List<&2, F.Region>, +g: U64, +nd: U64) -> NR:
  match c:
    case F.CK_err{e}: sw_pe(e, nd)
    case F.CK_ok{ls, ps}:
      +hs = rls_holes(F.rg_rls(rs, 0n, F.K_free{}))
      +pp = RV.lps_prep(ls, hs)
      sw_ax(RV.ax_codes(pp, hs, 0n), pp, ps, hs, deg, g, nd)

def sw_at(ok: Bool, +deg: U64, +rs: List<&2, F.Region>, +g: U64, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("sweep", nd, "twist-not-admitted")
    case True{}: sw_ap(F.prof_check(rs, e), deg, rs, g, nd)

def sw_ag(ok: Bool, +deg: U64, +rs: List<&2, F.Region>, +g: U64, +tw: U64, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("sweep", nd, "guide-not-admitted")
    case True{}: sw_at(String.eq(F9.why_twist(tw), ""), deg, rs, g, e, nd)

def sw_aa(ok: Bool, +deg: U64, +rs: List<&2, F.Region>, +g: U64, +gd: U64, +tw: U64, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("sweep", nd, "sweep-angle-not-certified")
    case True{}: sw_ag(String.eq(F9.why_guide(1u64, g, gd, deg), ""), deg, rs, g, tw, e, nd)

def op_sw_arc(+deg: U64, +rs: List<&2, F.Region>, +g: U64, +gd: U64, +tw: U64, +e: X.Env, +nd: U64) -> NR:
  sw_aa(String.eq(F9.why_sw_ang(deg), ""), deg, rs, g, gd, tw, e, nd)

def rg_out(r: F.Region) -> F.Loop:
  F.Rg{o, hs} = r
  o

def rg_has_h(r: F.Region) -> Bool:
  F.Rg{o, hs} = r
  Bool.not(Nat.is_eq(List.length(&2, F.Loop, hs), 0n))

def ev_code(ev: F.EV) -> U64:
  match ev:
    case F.EV_ok{ls}: 0u64
    case F.EV_err{e}:
      F.Er{code, lp, sg} = e
      code

def lp0(ls: List<&2, F.Lp>) -> F.Lp:
  match ls:
    case []: F.K_circ{0.0f64, 0.0f64, 1.0f64}
    case h <> t: h

def ev_lp(ev: F.EV) -> F.Lp:
  match ev:
    case F.EV_ok{ls}: lp0(ls)
    case F.EV_err{e}: F.K_circ{0.0f64, 0.0f64, 1.0f64}

def loft_pe(ev: F.EV, +nd: U64) -> NR:
  match ev:
    case F.EV_ok{ls}: why_nr("loft", nd, "loft-topology-mismatch")
    case F.EV_err{e}: pe_nr(e, "loft profile")

def loft_which(bot_ok: Bool, +eb: F.EV, +et: F.EV, +nd: U64) -> NR:
  match bot_ok:
    case True{}: loft_pe(et, nd)
    case False{}: loft_pe(eb, nd)

def loft_kind(k: U64, +why: String, +l: F9.LF, +bot: F.Region, +zv: F64, +e: X.Env, +nd: U64) -> NR:
  match k:
    case 0u64: why_nr("loft", nd, why)
    case 1u64: op_prism([bot], xk(0.0f64), xk(zv), e, nd)
    case 2u64: mesh_go(F9.frust_bt(F9.lf_x0(l), F9.lf_y0(l), F9.lf_x1(l), F9.lf_y1(l), F9.lf_u0(l), F9.lf_v0(l), F9.lf_u1(l), F9.lf_v1(l), zv, nd), F9.vol_frust(zv, F9.lf_x0(l), F9.lf_y0(l), F9.lf_x1(l), F9.lf_y1(l), F9.lf_u0(l), F9.lf_v0(l), F9.lf_u1(l), F9.lf_v1(l)), "loft", [], "")
    case _: unc_nr("loft", nd, "loft-not-certified")

def loft_use(+l: F9.LF, +bot: F.Region, +zv: F64, +e: X.Env, +nd: U64) -> NR:
  loft_kind(F9.lf_kind(l), F9.lf_why(l), l, bot, zv, e, nd)

def loft_err(bad: Bool, +cb: U64, +eb: F.EV, +et: F.EV, +zv: F64, +bot: F.Region, +twist: U64, +cont: U64, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: loft_which(U64.is_eq(cb, 0u64), eb, et, nd)
    case False{}: loft_use(F9.loft_lf(False{}, ev_lp(eb), ev_lp(et), U64.to_nat(twist), cont, zv), bot, zv, e, nd)

def loft_c7(bad: Bool, +cb: U64, +eb: F.EV, +et: F.EV, +zv: F64, +bot: F.Region, +twist: U64, +cont: U64, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("loft", nd, "degenerate-feature")
    case False{}: loft_err(Bool.or(Bool.not(U64.is_eq(cb, 0u64)), Bool.not(U64.is_eq(ev_code(et), 0u64))), cb, eb, et, zv, bot, twist, cont, e, nd)

def loft_ev2(+cb: U64, +ct: U64, +eb: F.EV, +et: F.EV, +zv: F64, +bot: F.Region, +twist: U64, +cont: U64, +e: X.Env, +nd: U64) -> NR:
  loft_c7(Bool.or(U64.is_eq(cb, 7u64), U64.is_eq(ct, 7u64)), cb, eb, et, zv, bot, twist, cont, e, nd)

def loft_ev(+eb: F.EV, +et: F.EV, +zv: F64, +bot: F.Region, +twist: U64, +cont: U64, +e: X.Env, +nd: U64) -> NR:
  loft_ev2(ev_code(eb), ev_code(et), eb, et, zv, bot, twist, cont, e, nd)

def loft_holes(bad: Bool, +zv: F64, +bot: F.Region, +top: F.Region, +twist: U64, +cont: U64, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("loft", nd, "loft-topology-mismatch")
    case False{}: loft_ev(F.loops_ev([rg_out(bot)], e, 0n), F.loops_ev([rg_out(top)], e, 0n), zv, bot, twist, cont, e, nd)

def loft_z(ok: Bool, +zv: F64, +bot: F.Region, +top: F.Region, +twist: U64, +cont: U64, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("loft", nd, "degenerate-feature")
    case True{}: loft_holes(Bool.or(rg_has_h(bot), rg_has_h(top)), zv, bot, top, twist, cont, e, nd)

def op_loft(+z: X.Xp, +bot: F.Region, +top: F.Region, +twist: U64, +cont: U64, +e: X.Env, +nd: U64) -> NR:
  +zv = X.xp_ev(z, e)
  loft_z(Bool.and(T.is_finite(zv), F64.is_lt(0.0f64, zv)), zv, bot, top, twist, cont, e, nd)

def ch_box_c(bad: Bool, +x: F64, +y: F64, +z: F64, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("chamfer", nd, "chamfer-consumes-face")
    case False{}: nr_take(op_prism([F9.chamfer_rg(x, y, d)], xk(0.0f64), xk(z), e, nd), F9.vol_chamfer_box(x, y, z, d), "", dels_why(bd_fns(b), 3u64), False{}, True{})

def ch_box(o: Op, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_box{x, y, z}:
      +xv = X.xp_ev(x, e)
      +yv = X.xp_ev(y, e)
      +zv = X.xp_ev(z, e)
      ch_box_c(Bool.not(Bool.and(F64.is_lt(F64.mul(2.0f64, d), xv), F64.is_lt(F64.mul(2.0f64, d), yv))), xv, yv, zv, d, b, e, nd)
    case _: why_nr("chamfer", nd, "chamfer-base-not-admitted")

def ch_cyl_c(bad: Bool, +r: F64, +h: F64, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("chamfer", nd, "chamfer-consumes-face")
    case False{}: nr_take(op_rev([F9.cyl_chamfer_rg(r, h, d)], e, nd), F9.vol_chamfer_cyl(r, h, d), "", dels_why(bd_fns(b), 3u64), False{}, True{})

def ch_cyl(o: Op, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_cyl{r, h}:
      +rv = X.xp_ev(r, e)
      +hv = X.xp_ev(h, e)
      ch_cyl_c(Bool.not(Bool.and(F64.is_lt(d, rv), F64.is_lt(F64.mul(2.0f64, d), hv))), rv, hv, d, b, e, nd)
    case _: why_nr("chamfer", nd, "chamfer-base-not-admitted")

def ch_kind(k: U64, +o: Op, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match k:
    case 1u64: ch_box(o, d, b, e, nd)
    case 2u64: ch_cyl(o, d, b, e, nd)
    case _: why_nr("chamfer", nd, "chamfer-base-not-admitted")

def ch_d(bad: Bool, +dv: F64, +o: Op, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("chamfer", nd, "degenerate-feature")
    case False{}: ch_kind(base_kind(o), o, dv, b, e, nd)

def op_chamfer(+base: U64, +d: X.Xp, +b: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>) -> NR:
  +dv = X.xp_ev(d, e)
  ch_d(Bool.not(fpos(dv)), dv, nd_op(ns, base), b, e, nd)

def fi_box_c(bad: Bool, +x: F64, +y: F64, +z: F64, +r: F64, +b: Body, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("fillet", nd, "fillet-consumes-face")
    case False{}: mesh_go(F9.fillet_bt(x, y, z, r, nd), F9.vol_fillet_box(x, y, z, r), "fillet", dels_why(bd_fns(b), 4u64), "")

def fi_box(o: Op, +r: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_box{x, y, z}:
      +xv = X.xp_ev(x, e)
      +yv = X.xp_ev(y, e)
      +zv = X.xp_ev(z, e)
      +two = F64.mul(2.0f64, r)
      fi_box_c(Bool.not(Bool.and(F64.is_lt(two, xv), Bool.and(F64.is_lt(two, yv), F64.is_lt(two, zv)))), xv, yv, zv, r, b, nd)
    case _: why_nr("fillet", nd, "fillet-base-not-admitted")

def fi_cyl_c(bad: Bool, +rc: F64, +h: F64, +r: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("fillet", nd, "fillet-consumes-face")
    case False{}: nr_take(op_rev([F9.cyl_fillet_rg(rc, h, r)], e, nd), F9.vol_fillet_cyl(rc, h, r), "", dels_why(bd_fns(b), 4u64), False{}, True{})

def fi_cyl(o: Op, +r: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_cyl{rc0, h0}:
      +rc = X.xp_ev(rc0, e)
      +hv = X.xp_ev(h0, e)
      fi_cyl_c(Bool.not(Bool.and(F64.is_lt(r, rc), F64.is_lt(F64.mul(2.0f64, r), hv))), rc, hv, r, b, e, nd)
    case _: why_nr("fillet", nd, "fillet-base-not-admitted")

def fi_kind(k: U64, +o: Op, +r: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match k:
    case 1u64: fi_box(o, r, b, e, nd)
    case 2u64: fi_cyl(o, r, b, e, nd)
    case _: why_nr("fillet", nd, "fillet-base-not-admitted")

def fi_d(bad: Bool, +rv: F64, +o: Op, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("fillet", nd, "degenerate-feature")
    case False{}: fi_kind(base_kind(o), o, rv, b, e, nd)

def op_fillet(+base: U64, +r: X.Xp, +b: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>) -> NR:
  +rv = X.xp_ev(r, e)
  fi_d(Bool.not(fpos(rv)), rv, nd_op(ns, base), b, e, nd)

def larger(+a: F64, +b: F64) -> F64:
  Bool.pick(F64, F64.is_lt(a, b), b, a)

def fe_eq(eq: Bool, +x: F64, +y: F64, +z: F64, +r0: F64, +r1: F64, +n: U64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match eq:
    case True{}: nr_take(op_prism([F9.fil_edge_rg(n, x, y, r0)], xk(0.0f64), xk(z), e, nd), F9.vol_fillet_edge(x, y, z, r0, r1), "", dels_why(bd_fns(b), 4u64), False{}, True{})
    case False{}: nr_err(T.F_unsupported{}, "fillet", "node " ++ U64.show(nd), "fillet-cone-not-certified", "give the edge equal end radii")

def fe_cons(bad: Bool, +x: F64, +y: F64, +z: F64, +r0: F64, +r1: F64, +n: U64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("fillet", nd, "fillet-consumes-face")
    case False{}: fe_eq(F64.is_eq(r0, r1), x, y, z, r0, r1, n, b, e, nd)

def fe_box(o: Op, +n: U64, +r0: F64, +r1: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_box{x, y, z}:
      +xv = X.xp_ev(x, e)
      +yv = X.xp_ev(y, e)
      +zv = X.xp_ev(z, e)
      +two = F64.mul(2.0f64, larger(r0, r1))
      fe_cons(Bool.not(Bool.and(F64.is_lt(two, xv), F64.is_lt(two, yv))), xv, yv, zv, r0, r1, n, b, e, nd)
    case _: why_nr("fillet", nd, "fillet-edge-not-admitted")

def fe_admit(ok: Bool, +o: Op, +n: U64, +r0: F64, +r1: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("fillet", nd, "fillet-edge-not-admitted")
    case True{}: fe_box(o, n, r0, r1, b, e, nd)

def fe_d(bad: Bool, +a: F64, +c: F64, +n: U64, +o: Op, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("fillet", nd, "degenerate-feature")
    case False{}: fe_admit(Bool.and(U64.is_eq(base_kind(o), 1u64), U64.is_lt(n, 4u64)), o, n, a, c, b, e, nd)

def op_fillet_e(+base: U64, +n: U64, +r0: X.Xp, +r1: X.Xp, +b: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>) -> NR:
  +a = X.xp_ev(r0, e)
  +c = X.xp_ev(r1, e)
  fe_d(Bool.not(Bool.and(fpos(a), fpos(c))), a, c, n, nd_op(ns, base), b, e, nd)

def dr_build(id0: Bool, +x: F64, +y: F64, +z: F64, +inset: F64, +b: Body, +nd: U64) -> NR:
  match id0:
    case True{}: nr_ident(b, "draft-identity")
    case False{}: mesh_go(F9.frust_bt(0.0f64, 0.0f64, x, y, inset, inset, F64.sub(x, inset), F64.sub(y, inset), z, nd), F9.vol_draft(x, y, z, inset), "draft", dels_why(bd_fns(b), 5u64), "")

def dr_cons(bad: Bool, +x: F64, +y: F64, +z: F64, +inset: F64, +b: Body, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("draft", nd, "draft-consumes-face")
    case False{}: dr_build(eq0(inset), x, y, z, inset, b, nd)

def dr_box(o: Op, +inset: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_box{x, y, z}:
      +xv = X.xp_ev(x, e)
      +yv = X.xp_ev(y, e)
      +zv = X.xp_ev(z, e)
      +two = F64.mul(2.0f64, inset)
      dr_cons(Bool.and(F64.is_lt(0.0f64, inset), Bool.not(Bool.and(F64.is_lt(two, xv), F64.is_lt(two, yv)))), xv, yv, zv, inset, b, nd)
    case _: why_nr("draft", nd, "draft-base-not-admitted")

def dr_k(ok: Bool, +o: Op, +inset: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("draft", nd, "draft-base-not-admitted")
    case True{}: dr_box(o, inset, b, e, nd)

def op_draft(+base: U64, +inset: X.Xp, +b: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>) -> NR:
  +o = nd_op(ns, base)
  dr_k(U64.is_eq(base_kind(o), 1u64), o, X.xp_ev(inset, e), b, e, nd)

def of_box_b(ok: Bool, +x: F64, +y: F64, +z: F64, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("offset", nd, "offset-self-intersection")
    case True{}: nr_take(op_prism([F9.rg(F64.neg(d), F64.neg(d), [F9.ln(F64.add(x, d), F64.neg(d)), F9.ln(F64.add(x, d), F64.add(y, d)), F9.ln(F64.neg(d), F64.add(y, d))])], xk(F64.neg(d)), xk(F64.add(z, d)), e, nd), F9.vol_offset_box(x, y, z, d), "", dels_why(bd_fns(b), 6u64), False{}, True{})

def of_id(id0: Bool, +px: Bool, +py: Bool, +pz: Bool, +x: F64, +y: F64, +z: F64, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match id0:
    case True{}: nr_ident(b, "offset-identity")
    case False{}: of_box_b(Bool.and(px, Bool.and(py, pz)), x, y, z, d, b, e, nd)

def of_box(o: Op, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_box{x, y, z}:
      +xv = X.xp_ev(x, e)
      +yv = X.xp_ev(y, e)
      +zv = X.xp_ev(z, e)
      of_id(eq0(d), fpos(F64.add(xv, F64.mul(2.0f64, d))), fpos(F64.add(yv, F64.mul(2.0f64, d))), fpos(F64.add(zv, F64.mul(2.0f64, d))), xv, yv, zv, d, b, e, nd)
    case _: why_nr("offset", nd, "offset-base-not-admitted")

def of_cyl_b(ok: Bool, +r: F64, +h: F64, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("offset", nd, "offset-self-intersection")
    case True{}: nr_take(op_prism([circ_rg(xk(F64.add(r, d)))], xk(F64.neg(d)), xk(F64.add(h, d)), e, nd), F9.vol_offset_cyl(r, h, d), "", dels_why(bd_fns(b), 6u64), False{}, True{})

def of_cyl_id(id0: Bool, +pr: Bool, +ph: Bool, +r: F64, +h: F64, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match id0:
    case True{}: nr_ident(b, "offset-identity")
    case False{}: of_cyl_b(Bool.and(pr, ph), r, h, d, b, e, nd)

def of_cyl(o: Op, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_cyl{r, h}:
      +rv = X.xp_ev(r, e)
      +hv = X.xp_ev(h, e)
      of_cyl_id(eq0(d), fpos(F64.add(rv, d)), fpos(F64.add(hv, F64.mul(2.0f64, d))), rv, hv, d, b, e, nd)
    case _: why_nr("offset", nd, "offset-base-not-admitted")

def of_kind(k: U64, +o: Op, +d: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match k:
    case 1u64: of_box(o, d, b, e, nd)
    case 2u64: of_cyl(o, d, b, e, nd)
    case _: why_nr("offset", nd, "offset-base-not-admitted")

def op_offset(+base: U64, +d: X.Xp, +b: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>) -> NR:
  +o = nd_op(ns, base)
  of_kind(base_kind(o), o, X.xp_ev(d, e), b, e, nd)

def nr_shell_ok(+b: Body, +fx: Fx, +vol: F64, +dl: List<&2, B8.Del>) -> NR:
  NR_ok{Bd{[], bd_brep(b), bd_fns(b), bd_pl(b), [], Xb{[ms_set_vol(body_ms(b), vol)], xb_nc(bd_xb(b)), True{}, xb_pr(bd_xb(b)), dl}}, fx}

def nr_shell(r: NR, +vol: F64, +dl: List<&2, B8.Del>) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+b, fx}: nr_shell_ok(b, fx, vol, dl)

def sh_diff(inner: NR, +outer: Body, +vol: F64, +nd: U64) -> NR:
  match inner:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+ib, fx}: nr_shell(bool_nr(B8.run(B8.tag_diff(), bool_in(outer), bool_in(ib), nd, 0u64, 0u64, False{}), outer, ib), vol, dels_why(bd_fns(outer), 7u64))

def sh_box_go(open: Bool, +x: F64, +y: F64, +z: F64, +t: F64, +b: Body, +base: U64, +e: X.Env, +nd: U64) -> NR:
  match open:
    case True{}: nr_take(op_feat(1u64, b, Sel{base, 0n, 0u64, ""}, [F9.rg(t, t, [F9.ln(F64.sub(x, t), t), F9.ln(F64.sub(x, t), F64.sub(y, t)), F9.ln(t, F64.sub(y, t))])], xk(F64.sub(z, t)), False{}, e, nd, base), F9.vol_shell_open(x, y, z, t), "", dels_why(bd_fns(b), 7u64), False{}, True{})
    case False{}: sh_diff(op_prism([F9.rg(t, t, [F9.ln(F64.sub(x, t), t), F9.ln(F64.sub(x, t), F64.sub(y, t)), F9.ln(t, F64.sub(y, t))])], xk(t), xk(F64.sub(z, t)), e, nd), b, F9.vol_shell_box(x, y, z, t), nd)

def sh_box_c(bad: Bool, +open: Bool, +x: F64, +y: F64, +z: F64, +t: F64, +b: Body, +base: U64, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("shell", nd, "shell-consumes-solid")
    case False{}: sh_box_go(open, x, y, z, t, b, base, e, nd)

def sh_box(o: Op, +open: Bool, +t: F64, +b: Body, +base: U64, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_box{x, y, z}:
      +xv = X.xp_ev(x, e)
      +yv = X.xp_ev(y, e)
      +zv = X.xp_ev(z, e)
      +two = F64.mul(2.0f64, t)
      sh_box_c(Bool.or(Bool.not(F64.is_lt(two, xv)), Bool.or(Bool.not(F64.is_lt(two, yv)), Bool.or(Bool.not(F64.is_lt(two, zv)), Bool.and(open, Bool.not(F64.is_lt(t, zv)))))), open, xv, yv, zv, t, b, base, e, nd)
    case _: why_nr("shell", nd, "shell-base-not-admitted")

def sh_cyl_c(bad: Bool, +r: F64, +h: F64, +t: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("shell", nd, "shell-consumes-solid")
    case False{}: sh_diff(op_prism([circ_rg(xk(F64.sub(r, t)))], xk(t), xk(F64.sub(h, t)), e, nd), b, F9.vol_shell_cyl(r, h, t), nd)

def sh_cyl_ev(+r: X.Xp, +h: X.Xp, +t: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  +rv = X.xp_ev(r, e)
  +hv = X.xp_ev(h, e)
  sh_cyl_c(Bool.or(Bool.not(F64.is_lt(t, rv)), Bool.not(F64.is_lt(F64.mul(2.0f64, t), hv))), rv, hv, t, b, e, nd)

def sh_cyl_o(open: Bool, +r: X.Xp, +h: X.Xp, +t: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match open:
    case True{}: why_nr("shell", nd, "shell-base-not-admitted")
    case False{}: sh_cyl_ev(r, h, t, b, e, nd)

def sh_cyl(o: Op, +open: Bool, +t: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_cyl{r, h}: sh_cyl_o(open, r, h, t, b, e, nd)
    case _: why_nr("shell", nd, "shell-base-not-admitted")

def sh_kind(k: U64, +o: Op, +open: Bool, +t: F64, +b: Body, +base: U64, +e: X.Env, +nd: U64) -> NR:
  match k:
    case 1u64: sh_box(o, open, t, b, base, e, nd)
    case 2u64: sh_cyl(o, open, t, b, e, nd)
    case _: why_nr("shell", nd, "shell-base-not-admitted")

def sh_t(bad: Bool, +o: Op, +open: Bool, +t: F64, +b: Body, +base: U64, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("shell", nd, "degenerate-feature")
    case False{}: sh_kind(base_kind(o), o, open, t, b, base, e, nd)

def sh_base(foreign: Bool, +badt: Bool, +o: Op, +open: Bool, +t: F64, +b: Body, +base: U64, +e: X.Env, +nd: U64) -> NR:
  match foreign:
    case True{}: why_nr("shell", nd, "shell-base-not-admitted")
    case False{}: sh_t(badt, o, open, t, b, base, e, nd)

def op_shell(+base: U64, +t: X.Xp, +open: Bool, +b: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>) -> NR:
  +tv = X.xp_ev(t, e)
  +o = nd_op(ns, base)
  sh_base(U64.is_eq(base_kind(o), 0u64), Bool.not(fpos(tv)), o, open, tv, b, base, e, nd)

def th_d(bad: Bool, +tv: F64, +b: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>, +base: U64) -> NR:
  match bad:
    case True{}: why_nr("thicken", nd, "degenerate-feature")
    case False{}: nr_rewhy(op_offset(base, xk(tv), b, e, nd, ns), 8u64)

def op_thicken(+base: U64, +t: X.Xp, +b: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>) -> NR:
  +tv = X.xp_ev(t, e)
  th_d(Bool.not(fpos(tv)), tv, b, e, nd, ns, base)

def p_ix(+p: Nat, +nx: Nat) -> Nat:
  F9.modn(p, nx)

def p_iy(+p: Nat, +nx: Nat, +ny: Nat) -> Nat:
  F9.modn(Nat.div(p, nx), ny)

def p_iz(+p: Nat, +nx: Nat, +ny: Nat) -> Nat:
  Nat.div(p, Nat.mul(nx, ny))

def shf(+a: F64, +i: Nat, +d: F64) -> F64:
  F64.add(a, F64.mul(n2f(i), d))

def sep1(+a0: F64, +a1: F64, +b0: F64, +b1: F64) -> Bool:
  Bool.or(F64.is_lt(a1, b0), F64.is_lt(b1, a0))

def sep3(+ax0: F64, +ax1: F64, +ay0: F64, +ay1: F64, +az0: F64, +az1: F64, +bx0: F64, +bx1: F64, +by0: F64, +by1: F64, +bz0: F64, +bz1: F64) -> Bool:
  Bool.or(sep1(ax0, ax1, bx0, bx1), Bool.or(sep1(ay0, ay1, by0, by1), sep1(az0, az1, bz0, bz1)))

def ov_pair(+j: Nat, +i: Nat, +x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64, +dx: F64, +dy: F64, +dz: F64, +nx: Nat, +ny: Nat) -> Bool:
  Bool.not(sep3(shf(x0, p_ix(j, nx), dx), shf(x1, p_ix(j, nx), dx), shf(y0, p_iy(j, nx, ny), dy), shf(y1, p_iy(j, nx, ny), dy), shf(z0, p_iz(j, nx, ny), dz), shf(z1, p_iz(j, nx, ny), dz), shf(x0, p_ix(i, nx), dx), shf(x1, p_ix(i, nx), dx), shf(y0, p_iy(i, nx, ny), dy), shf(y1, p_iy(i, nx, ny), dy), shf(z0, p_iz(i, nx, ny), dz), shf(z1, p_iz(i, nx, ny), dz)))

def ov_j(j: Nat, +i: Nat, +x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64, +dx: F64, +dy: F64, +dz: F64, +nx: Nat, +ny: Nat) -> Bool:
  match j:
    case 0n: False{}
    case 1n++k: Bool.pick(Bool, ov_pair(k, i, x0, x1, y0, y1, z0, z1, dx, dy, dz, nx, ny), True{}, ov_j(k, i, x0, x1, y0, y1, z0, z1, dx, dy, dz, nx, ny))

def ov_i(i: Nat, +x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64, +dx: F64, +dy: F64, +dz: F64, +nx: Nat, +ny: Nat) -> Bool:
  match i:
    case 0n: False{}
    case 1n++k: Bool.pick(Bool, ov_j(k, k, x0, x1, y0, y1, z0, z1, dx, dy, dz, nx, ny), True{}, ov_i(k, x0, x1, y0, y1, z0, z1, dx, dy, dz, nx, ny))

def retag(fs: List<&2, BD.Fn>, +nd: U64, +i: Nat) -> List<&2, BD.Fn>:
  match fs:
    case []: []
    case f <> t: BD.Fn{nd, 0n, 2u64, i, 0n} <> retag(t, nd, Nat.add(i, 1n))

def nr_pat_go(+acc: Body, +bv: I.I, +base: Body, +n: Nat, +nd: U64) -> NR:
  NR_ok{Bd{[], bd_brep(acc), retag(bd_fns(acc), nd, 0n), bd_pl(acc), [], Xb{[ms_put_vol(body_ms(acc), I.I{F64.mul(I.i_lo(bv), n2f(n)), F64.mul(I.i_hi(bv), n2f(n))})], xb_nc(bd_xb(acc)), True{}, xb_pr(bd_xb(acc)), dels_why(bd_fns(base), 9u64)}}, Fx{M_add{}, 0n, 0n, 0n, 0n}}

def nr_pat_body(+acc: Body, +base: Body, +n: Nat, +nd: U64) -> NR:
  nr_pat_go(acc, ms_vol(body_ms(base)), base, n, nd)

def pat_finish(r: NR, +b0: Body, +n: Nat, +nd: U64) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{b, fx}: nr_pat_body(b, b0, n, nd)

def pat_union_mv(mv: NR, +acc: Body, +nd: U64) -> NR:
  match mv:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+mb, fx}: bool_nr(B8.run(B8.tag_union(), bool_in(acc), bool_in(mb), nd, 0u64, 0u64, False{}), acc, mb)

def pat_union(+b0: Body, +acc: Body, +i: Nat, +dx: F64, +dy: F64, +dz: F64, +nx: Nat, +ny: Nat, +e: X.Env, +nd: U64) -> NR:
  pat_union_mv(op_move(b0, xk(shf(0.0f64, p_ix(i, nx), dx)), xk(shf(0.0f64, p_iy(i, nx, ny), dy)), xk(shf(0.0f64, p_iz(i, nx, ny), dz)), 0u64, e, nd), acc, nd)

def pat_step(left: Nat, +r: NR, +i: Nat, +n: Nat, +b0: Body, +dx: F64, +dy: F64, +dz: F64, +nx: Nat, +ny: Nat, +e: X.Env, +nd: U64) -> NR:
  match left:
    case 0n: pat_finish(r, b0, n, nd)
    case 1n+k:
      match r:
        case NR_err{k0, d}: NR_err{k0, d}
        case NR_ok{b, fx}: pat_step(k, pat_union(b0, b, i, dx, dy, dz, nx, ny, e, nd), Nat.add(i, 1n), n, b0, dx, dy, dz, nx, ny, e, nd)

def pat_lin_id(id0: Bool, +b: Body, +nx: Nat, +ny: Nat, +nz: Nat, +dx: F64, +dy: F64, +dz: F64, +e: X.Env, +nd: U64) -> NR:
  match id0:
    case True{}: nr_ident(b, "pattern-identity")
    case False{}: pat_step(Nat.sub(Nat.mul(nx, Nat.mul(ny, nz)), 1n), NR_ok{b, Fx{M_same{}, 0n, 0n, 0n, 0n}}, 1n, Nat.mul(nx, Nat.mul(ny, nz)), b, dx, dy, dz, nx, ny, e, nd)

def pat_lin_ov(hit: Bool, +b: Body, +nx: Nat, +ny: Nat, +nz: Nat, +dx: F64, +dy: F64, +dz: F64, +e: X.Env, +nd: U64) -> NR:
  match hit:
    case True{}: why_nr("pattern", nd, "pattern-copies-overlap")
    case False{}: pat_lin_id(Bool.and(Nat.is_eq(nx, 1n), Bool.and(Nat.is_eq(ny, 1n), Nat.is_eq(nz, 1n))), b, nx, ny, nz, dx, dy, dz, e, nd)

def pat_lin_z(bad: Bool, +b: Body, +nx: Nat, +ny: Nat, +nz: Nat, +dx: F64, +dy: F64, +dz: F64, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("pattern", nd, "pattern-count-not-admitted")
    case False{}:
      +m = body_ms(b)
      pat_lin_ov(ov_i(Nat.mul(nx, Nat.mul(ny, nz)), ms_x0(m), ms_x1(m), ms_y0(m), ms_y1(m), ms_z0(m), ms_z1(m), dx, dy, dz, nx, ny), b, nx, ny, nz, dx, dy, dz, e, nd)

def op_pat_lin(+base: U64, +nx: U64, +dx: X.Xp, +ny: U64, +dy: X.Xp, +nz: U64, +dz: X.Xp, +b: Body, +e: X.Env, +nd: U64) -> NR:
  pat_lin_z(Bool.or(U64.is_eq(nx, 0u64), Bool.or(U64.is_eq(ny, 0u64), U64.is_eq(nz, 0u64))), b, U64.to_nat(nx), U64.to_nat(ny), U64.to_nat(nz), X.xp_ev(dx, e), X.xp_ev(dy, e), X.xp_ev(dz, e), e, nd)

def cdx3(k: Nat, +r: F64) -> F64:
  match k:
    case 0n: F64.neg(r)
    case _: 0.0f64

def cdx2(j: Nat, +r: F64) -> F64:
  match j:
    case 0n: 0.0f64
    case 1n+k: cdx3(k, r)

def cdx1(i: Nat, +r: F64) -> F64:
  match i:
    case 0n: r
    case 1n+j: cdx2(j, r)

def cdx(i: Nat, +r: F64) -> F64:
  cdx1(i, r)

def cdy3(k: Nat, +r: F64) -> F64:
  match k:
    case 0n: 0.0f64
    case _: F64.neg(r)

def cdy2(j: Nat, +r: F64) -> F64:
  match j:
    case 0n: r
    case 1n+k: cdy3(k, r)

def cdy1(i: Nat, +r: F64) -> F64:
  match i:
    case 0n: 0.0f64
    case 1n+j: cdy2(j, r)

def cdy(i: Nat, +r: F64) -> F64:
  cdy1(i, r)

def circ_sep(+i: Nat, +j: Nat, +x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64, +r: F64) -> Bool:
  sep3(F64.add(x0, cdx(i, r)), F64.add(x1, cdx(i, r)), F64.add(y0, cdy(i, r)), F64.add(y1, cdy(i, r)), z0, z1, F64.add(x0, cdx(j, r)), F64.add(x1, cdx(j, r)), F64.add(y0, cdy(j, r)), F64.add(y1, cdy(j, r)), z0, z1)

def circ_ov(+x0: F64, +x1: F64, +y0: F64, +y1: F64, +z0: F64, +z1: F64, +r: F64) -> Bool:
  Bool.not(Bool.and(circ_sep(0n, 1n, x0, x1, y0, y1, z0, z1, r), Bool.and(circ_sep(0n, 2n, x0, x1, y0, y1, z0, z1, r), Bool.and(circ_sep(0n, 3n, x0, x1, y0, y1, z0, z1, r), Bool.and(circ_sep(1n, 2n, x0, x1, y0, y1, z0, z1, r), Bool.and(circ_sep(1n, 3n, x0, x1, y0, y1, z0, z1, r), circ_sep(2n, 3n, x0, x1, y0, y1, z0, z1, r)))))))

def circ_mv(mv: NR, +acc: Body, +e: X.Env, +nd: U64) -> NR:
  match mv:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+mb, fx}: bool_nr(B8.run(B8.tag_union(), bool_in(acc), bool_in(mb), nd, 0u64, 0u64, False{}), acc, mb)

def circ_u(r: NR, +src: Body, +tx: F64, +ty: F64, +e: X.Env, +nd: U64) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{acc, fx}: circ_mv(op_move(src, xk(tx), xk(ty), xk(0.0f64), 0u64, e, nd), acc, e, nd)

def circ_fin(r: NR, +b: Body, +nd: U64) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{acc, fx}: nr_pat_body(acc, b, 4n, nd)

def pat_circ_ov(hit: Bool, +b: Body, +r: F64, +e: X.Env, +nd: U64) -> NR:
  match hit:
    case True{}: why_nr("pattern", nd, "pattern-copies-overlap")
    case False{}: circ_fin(circ_u(circ_u(circ_u(op_move(b, xk(r), xk(0.0f64), xk(0.0f64), 0u64, e, nd), b, 0.0f64, r, e, nd), b, F64.neg(r), 0.0f64, e, nd), b, 0.0f64, F64.neg(r), e, nd), b, nd)

def pat_circ_r(bad: Bool, +b: Body, +r: F64, +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("pattern", nd, "pattern-angle-not-certified")
    case False{}:
      +m = body_ms(b)
      pat_circ_ov(circ_ov(ms_x0(m), ms_x1(m), ms_y0(m), ms_y1(m), ms_z0(m), ms_z1(m), r), b, r, e, nd)

def pat_circ_n(z: Bool, +bad: Bool, +b: Body, +r: F64, +e: X.Env, +nd: U64) -> NR:
  match z:
    case True{}: why_nr("pattern", nd, "pattern-count-not-admitted")
    case False{}: pat_circ_r(bad, b, r, e, nd)

def op_pat_circ(+base: U64, +n: U64, +r: X.Xp, +b: Body, +e: X.Env, +nd: U64) -> NR:
  +rv = X.xp_ev(r, e)
  pat_circ_n(U64.is_eq(n, 0u64), Bool.not(Bool.and(U64.is_eq(n, 4u64), Bool.and(T.is_finite(rv), Bool.not(eq0(rv))))), b, rv, e, nd)

def hl_cell(+i: Nat, +j: Nat, +dx: F64, +dy: F64, +x0: F64, +y0: F64, +r: F64) -> Hl:
  Hl{xk(F64.add(x0, F64.mul(n2f(i), dx))), xk(F64.add(y0, F64.mul(n2f(j), dy))), xk(r)}

def hl_row(left: Nat, +j: Nat, +i: Nat, +dx: F64, +dy: F64, +x0: F64, +y0: F64, +r: F64) -> List<&2, Hl>:
  match left:
    case 0n: []
    case 1n+k: hl_cell(i, j, dx, dy, x0, y0, r) <> hl_row(k, Nat.add(j, 1n), i, dx, dy, x0, y0, r)

def hl_grid(left: Nat, +i: Nat, +ny: Nat, +dx: F64, +dy: F64, +x0: F64, +y0: F64, +r: F64) -> List<&2, Hl>:
  match left:
    case 0n: []
    case 1n+k: List.append(&2, Hl, hl_row(ny, 0n, i, dx, dy, x0, y0, r), hl_grid(k, Nat.add(i, 1n), ny, dx, dy, x0, y0, r))

def ph_lin_z(bad: Bool, +f: Sel, +nx: Nat, +ny: Nat, +dx: F64, +dy: F64, +x0: F64, +y0: F64, +r: F64, +d: X.Xp, +thru: Bool, +b: Body, +e: X.Env, +nd: U64, +base: U64) -> NR:
  match bad:
    case True{}: why_nr("pattern-holes", nd, "pattern-count-not-admitted")
    case False{}: op_feat(2u64, b, f, hls_rgs(hl_grid(nx, 0n, ny, dx, dy, x0, y0, r)), d, thru, e, nd, base)

def op_ph_lin(+base: U64, +f: Sel, +nx: U64, +ny: U64, +dx: X.Xp, +dy: X.Xp, +x0: X.Xp, +y0: X.Xp, +r: X.Xp, +d: X.Xp, +thru: Bool, +b: Body, +e: X.Env, +nd: U64) -> NR:
  ph_lin_z(Bool.or(U64.is_eq(nx, 0u64), U64.is_eq(ny, 0u64)), f, U64.to_nat(nx), U64.to_nat(ny), X.xp_ev(dx, e), X.xp_ev(dy, e), X.xp_ev(x0, e), X.xp_ev(y0, e), X.xp_ev(r, e), d, thru, b, e, nd, base)

def hl_circ(+rad: F64, +cx: F64, +cy: F64, +r: F64) -> List<&2, Hl>:
  [Hl{xk(F64.add(cx, rad)), xk(cy), xk(r)}, Hl{xk(cx), xk(F64.add(cy, rad)), xk(r)}, Hl{xk(F64.sub(cx, rad)), xk(cy), xk(r)}, Hl{xk(cx), xk(F64.sub(cy, rad)), xk(r)}]

def ph_circ_a(four: Bool, +f: Sel, +rad: F64, +cx: F64, +cy: F64, +r: F64, +d: X.Xp, +thru: Bool, +b: Body, +e: X.Env, +nd: U64, +base: U64) -> NR:
  match four:
    case False{}: why_nr("pattern-holes", nd, "pattern-angle-not-certified")
    case True{}: op_feat(2u64, b, f, hls_rgs(hl_circ(rad, cx, cy, r)), d, thru, e, nd, base)

def ph_circ_n(z: Bool, +four: Bool, +f: Sel, +rad: F64, +cx: F64, +cy: F64, +r: F64, +d: X.Xp, +thru: Bool, +b: Body, +e: X.Env, +nd: U64, +base: U64) -> NR:
  match z:
    case True{}: why_nr("pattern-holes", nd, "pattern-count-not-admitted")
    case False{}: ph_circ_a(four, f, rad, cx, cy, r, d, thru, b, e, nd, base)

def op_ph_circ(+base: U64, +f: Sel, +n: U64, +rad: X.Xp, +cx: X.Xp, +cy: X.Xp, +r: X.Xp, +d: X.Xp, +thru: Bool, +b: Body, +e: X.Env, +nd: U64) -> NR:
  ph_circ_n(U64.is_eq(n, 0u64), U64.is_eq(n, 4u64), f, X.xp_ev(rad, e), X.xp_ev(cx, e), X.xp_ev(cy, e), X.xp_ev(r, e), d, thru, b, e, nd, base)
def blob_fns_go(+k: Nat, +nd: U64, +acc: List<&2, BD.Fn>) -> List<&2, BD.Fn>:
  match k:
    case 0n: acc
    case 1n+j:
      +i = Nat.sub(k, 1n)
      blob_fns_go(j, nd, BD.Fn{nd, i, 2u64, i, 0n} <> acc)

def blob_fns(+nf: Nat, +nd: U64) -> List<&2, BD.Fn>:
  blob_fns_go(nf, nd, [])

def blob_ms(+ir: BL.IR) -> Ms:
  +m = BL.ir_m(ir)
  +vol = BL.im_vol(m)
  +ar = BL.im_ar(m)
  +bb = BL.im_bb(m)
  +ct = BL.im_ct(m)
  Ms{I.I{BL.li_lo(vol), BL.li_hi(vol)}, I.I{BL.li_lo(ar), BL.li_hi(ar)}, BL.lb_x0(bb), BL.lb_x1(bb),
    BL.lb_y0(bb), BL.lb_y1(bb), BL.lb_z0(bb), BL.lb_z1(bb), BL.lc_nv(ct), BL.lc_ne(ct), BL.lc_nf(ct),
    BL.lc_ns(ct), BL.lc_genus(ct), BL.im_lin(m)}

def sh_rec(+fuel: Nat, +o: Op, +ns: List<&2, Node>) -> SH.SC:
  match fuel:
    case 0n: SH.SC_bad{}
    case 1n+k:
      match o:
        case O_flat{l, w, t}: SH.SC_ok{l, w, t, []}
        case O_bend{base, n, r, deg}: SH.sc_push(sh_rec(k, nd_op(ns, base), ns), SH.FT_bend{n, r, deg})
        case O_hem{base, n, l}: SH.sc_push(sh_rec(k, nd_op(ns, base), ns), SH.FT_hem{n, l})
        case _: SH.SC_bad{}
def sh_chain(+ns: List<&2, Node>, +id: U64) -> SH.SC:
  sh_rec(Nat.add(List.length(&2, Node, ns), 1n), nd_op(ns, id), ns)
def sheet_pr(+rot: Bool, +pr: SH.PR, +mx: X.Xp, +my: X.Xp) -> SH.PR:
  match rot:
    case True{}: SH.rot180(pr, mx, my)
    case False{}: pr
def sheet_build(+sc: SH.SC, +b: Body, +e: X.Env, +nd: U64, +l: F64, +t: F64, +w: F64) -> NR:
  +fs = SH.sc_feats(sc)
  +kp = SH.sc_prof(sc)
  +kk = SH.kp_k(kp)
  +lx = SH.sc_l(sc)
  +tx = SH.sc_t(sc)
  +rx = SH.first_rx(fs)
  +lhx = SH.first_lhx(fs)
  +pr = sheet_pr(SH.kp_rot(kp), SH.sh_prof(SH.pk_of_k(kk), lx, tx, rx, lhx), SH.prof_w(kk, lx, tx, rx, lhx),
    SH.prof_h(kk, lx, tx, rx, lhx))
  nr_take(op_prism([SH.to_region(pr)], xk(0.0f64), SH.sc_w(sc), e, nd),
    SH.sh_vol(kk, l, t, SH.first_r(fs, e), w, SH.first_lh(fs, e)), "", dels_why(bd_fns(b), 8u64), False{}, True{})
def sheet_go(+g: SH.GR, +sc: SH.SC, +b: Body, +e: X.Env, +nd: U64, +what: String, +l: F64, +t: F64,
    +w: F64) -> NR:
  match g:
    case SH.GR_ok{}: sheet_build(sc, b, e, nd, l, t, w)
    case SH.GR_no{+why, +fix}: nr_err(why_k(why_unsup(why), False{}), what, "node " ++ U64.show(nd), why, fix)
def op_sheet(+f: SH.FT, +base: U64, +b: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>) -> NR:
  +sc = SH.sc_push(sh_chain(ns, base), f)
  +l = X.xp_ev(SH.sc_l(sc), e)
  +w = X.xp_ev(SH.sc_w(sc), e)
  +t = X.xp_ev(SH.sc_t(sc), e)
  sheet_go(SH.ck_chain(sc, e, l, w, t), sc, b, e, nd, Bool.pick(String, SH.ft_is_bend(f), "bend", "hem"), l, t, w)

def su_refuse(+g: SU.GR, +what: String, +nd: U64) -> NR:
  match g:
    case SU.GR_ok{}: bad(what, "node " ++ U64.show(nd), "refusal-missing", "report this design")
    case SU.GR_no{+why, +fix}: nr_err(why_k(why_unsup(why), False{}), what, "node " ++ U64.show(nd), why, fix)

def su_go(o: Op) -> SU.SO:
  match o:
    case O_loft_open{z, bot, top, twist, cont}: SU.SO_lo{z, bot, top, twist, cont}
    case O_sw_open{deg, rs, g, gd, tw}: SU.SO_sw{deg, rs, g, gd, tw}
    case O_patch{ps}: SU.SO_pt{ps}
    case _: SU.SO_bad{}

def su_chain(+ns: List<&2, Node>, +id: U64) -> SU.SO:
  su_go(nd_op(ns, id))

def loft_open_0(+why: String, +nd: U64) -> NR:
  Bool.pick(NR, String.eq(why, "loft-face-not-planar"), su_refuse(SU.lo_go(False{}), "loft-open", nd),
    why_nr("loft-open", nd, why))

def loft_open_kind(k: U64, +why: String, +l: F9.LF, +zv: F64, +nd: U64) -> NR:
  match k:
    case 0u64: loft_open_0(why, nd)
    case 1u64: mesh_go_open(SU.loft_open_bt(SU.lo_of_lf(l, zv), nd), "loft-open")
    case 2u64: mesh_go_open(SU.loft_open_bt(SU.lo_of_lf(l, zv), nd), "loft-open")
    case _: unc_nr("loft-open", nd, "loft-not-certified")

def loft_open_use(+l: F9.LF, +zv: F64, +nd: U64) -> NR:
  loft_open_kind(F9.lf_kind(l), F9.lf_why(l), l, zv, nd)

def loft_open_err(bad: Bool, +cb: U64, +eb: F.EV, +et: F.EV, +zv: F64, +twist: U64, +cont: U64, +nd: U64) -> NR:
  match bad:
    case True{}: loft_which(U64.is_eq(cb, 0u64), eb, et, nd)
    case False{}:
      loft_open_use(F9.loft_lf(False{}, ev_lp(eb), ev_lp(et), U64.to_nat(twist), cont, zv), zv, nd)

def loft_open_c7(bad: Bool, +cb: U64, +eb: F.EV, +et: F.EV, +zv: F64, +twist: U64, +cont: U64, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("loft-open", nd, "degenerate-feature")
    case False{}:
      loft_open_err(Bool.or(Bool.not(U64.is_eq(cb, 0u64)), Bool.not(U64.is_eq(ev_code(et), 0u64))), cb, eb,
        et, zv, twist, cont, nd)

def loft_open_ev2(+cb: U64, +ct: U64, +eb: F.EV, +et: F.EV, +zv: F64, +twist: U64, +cont: U64, +nd: U64) -> NR:
  loft_open_c7(Bool.or(U64.is_eq(cb, 7u64), U64.is_eq(ct, 7u64)), cb, eb, et, zv, twist, cont, nd)

def loft_open_ev(+eb: F.EV, +et: F.EV, +zv: F64, +twist: U64, +cont: U64, +nd: U64) -> NR:
  loft_open_ev2(ev_code(eb), ev_code(et), eb, et, zv, twist, cont, nd)

def loft_open_holes(bad: Bool, +zv: F64, +bot: F.Region, +top: F.Region, +twist: U64, +cont: U64,
    +e: X.Env, +nd: U64) -> NR:
  match bad:
    case True{}: why_nr("loft-open", nd, "loft-topology-mismatch")
    case False{}: loft_open_ev(F.loops_ev([rg_out(bot)], e, 0n), F.loops_ev([rg_out(top)], e, 0n), zv, twist, cont, nd)

def loft_open_z(ok: Bool, +zv: F64, +bot: F.Region, +top: F.Region, +twist: U64, +cont: U64, +e: X.Env,
    +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("loft-open", nd, "degenerate-feature")
    case True{}: loft_open_holes(Bool.or(rg_has_h(bot), rg_has_h(top)), zv, bot, top, twist, cont, e, nd)

def op_loft_open(+z: X.Xp, +bot: F.Region, +top: F.Region, +twist: U64, +cont: U64, +e: X.Env,
    +nd: U64) -> NR:
  +zv = X.xp_ev(z, e)
  loft_open_z(Bool.and(T.is_finite(zv), F64.is_lt(0.0f64, zv)), zv, bot, top, twist, cont, e, nd)

def sw_open_rect(ok: Bool, +deg: U64, +r: SU.RT, +nd: U64) -> NR:
  match ok:
    case False{}: su_refuse(SU.sp_go(False{}), "sweep-open", nd)
    case True{}: mesh_go_open(SU.swo_open_bt(SU.swo_of(deg, r), SU.qd_of(deg), nd), "sweep-open")

def sw_open_single(ok: Bool, +deg: U64, +pp: List<&2, F.Lp>, +nd: U64) -> NR:
  match ok:
    case False{}: pe_nr(F.Er{24u64, 0n, 0n}, "sweep profile")
    case True{}:
      +r = SU.sw_rect_of(F.lp_pcs(SU.lp0(pp)))
      sw_open_rect(SU.rt_ok(r), deg, r, nd)

def sw_open_ax_go(ok: Bool, +e: F.Er, +pp: List<&2, F.Lp>, +hs: List<&2, Bool>, +deg: U64, +nd: U64) -> NR:
  match ok:
    case False{}: pe_nr(e, "sweep profile")
    case True{}: sw_open_single(SU.pp_single(pp, hs), deg, pp, nd)

def sw_open_ax(e: F.Er, +pp: List<&2, F.Lp>, +hs: List<&2, Bool>, +deg: U64, +nd: U64) -> NR:
  F.Er{+code, +lp, +sg} = e
  sw_open_ax_go(U64.is_eq(code, 0u64), F.Er{code, lp, sg}, pp, hs, deg, nd)

def sw_open_ap(c: F.CK, +deg: U64, +rs: List<&2, F.Region>, +nd: U64) -> NR:
  match c:
    case F.CK_err{e}: sw_pe(e, nd)
    case F.CK_ok{ls, ps}:
      +hs = rls_holes(F.rg_rls(rs, 0n, F.K_free{}))
      +pp = RV.lps_prep(ls, hs)
      sw_open_ax(RV.ax_codes(pp, hs, 0n), pp, hs, deg, nd)

def sw_open_at(ok: Bool, +deg: U64, +rs: List<&2, F.Region>, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("sweep-open", nd, "twist-not-admitted")
    case True{}: sw_open_ap(F.prof_check(rs, e), deg, rs, nd)

def sw_open_ag(ok: Bool, +deg: U64, +rs: List<&2, F.Region>, +tw: U64, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: why_nr("sweep-open", nd, "guide-not-admitted")
    case True{}: sw_open_at(String.eq(F9.why_twist(tw), ""), deg, rs, e, nd)

def sw_open_aa(ok: Bool, +deg: U64, +rs: List<&2, F.Region>, +g: U64, +gd: U64, +tw: U64, +e: X.Env,
    +nd: U64) -> NR:
  match ok:
    case False{}: su_refuse(SU.sa_go(False{}, deg), "sweep-open", nd)
    case True{}: sw_open_ag(String.eq(F9.why_guide(1u64, g, gd, deg), ""), deg, rs, tw, e, nd)

def op_sw_open(+deg: U64, +rs: List<&2, F.Region>, +g: U64, +gd: U64, +tw: U64, +e: X.Env, +nd: U64) -> NR:
  sw_open_aa(Bool.and(String.eq(F9.why_sw_ang(deg), ""), U64.is_ne(deg, 360u64)), deg, rs, g, gd, tw, e, nd)

def op_patch(+ps: List<&2, X.Xp>, +e: X.Env, +nd: U64) -> NR:
  +p = SU.pp_ev(ps, e)
  Bool.pick(NR, SU.pa_ok(p), mesh_go_open(SU.patch_open_bt(p, nd), "patch"),
    su_refuse(SU.pa_go(False{}), "patch", nd))

def th_base_ok(o: Op) -> Bool:
  match o:
    case O_loft_open{z, bot, top, twist, cont}: True{}
    case O_sw_open{deg, rs, g, gd, tw}: True{}
    case O_patch{ps}: True{}
    case _: False{}

def th_lo_size(ok: Bool, +d: SU.DD, +b: Body, +nd: U64) -> NR:
  match ok:
    case False{}: su_refuse(SU.ts_go(False{}), "thicken-open", nd)
    case True{}: mesh_nr(bt_check(SU.duct_bt(d, nd), [], pl_id(), "thicken-open", []), SU.duct_vol(d),
      dels_why(bd_fns(b), 10u64), "")

def th_lo_kind(k: U64, +l: F9.LF, +zv: F64, +tv: F64, +b: Body, +nd: U64) -> NR:
  match k:
    case 1u64: th_lo_size(SU.duct_inner_ok(SU.duct_dims(SU.lo_of_lf(l, zv), tv)), SU.duct_dims(SU.lo_of_lf(l, zv), tv), b, nd)
    case 2u64: th_lo_size(SU.duct_inner_ok(SU.duct_dims(SU.lo_of_lf(l, zv), tv)), SU.duct_dims(SU.lo_of_lf(l, zv), tv), b, nd)
    case 0u64: loft_open_0(F9.lf_why(l), nd)
    case _: unc_nr("thicken-open", nd, "loft-not-certified")

def th_lo_ev(+eb: F.EV, +et: F.EV, +zv: F64, +tv: F64, +twist: U64, +cont: U64, +b: Body, +nd: U64) -> NR:
  +l = F9.loft_lf(False{}, ev_lp(eb), ev_lp(et), U64.to_nat(twist), cont, zv)
  th_lo_kind(F9.lf_kind(l), l, zv, tv, b, nd)

def thicken_loft(+z: X.Xp, +bot: F.Region, +top: F.Region, +twist: U64, +cont: U64, +tv: F64, +b: Body,
    +e: X.Env, +nd: U64) -> NR:
  th_lo_ev(F.loops_ev([rg_out(bot)], e, 0n), F.loops_ev([rg_out(top)], e, 0n), X.xp_ev(z, e), tv, twist,
    cont, b, nd)

def th_sw_size(ok: Bool, +s: SU.SWO, +tv: F64, +b: Body, +nd: U64) -> NR:
  match ok:
    case False{}: su_refuse(SU.ts_go(False{}), "thicken-open", nd)
    case True{}:
      mesh_nr(bt_check(SU.sec_bt(SU.sec_dims(s, tv), SU.qd_n(SU.qd_of(SU.swo_deg(s))), nd), [],
        pl_id(), "thicken-open", []), SU.sec_vol(s, tv), dels_why(bd_fns(b), 10u64), "")

def th_sw_rect(ok: Bool, +deg: U64, +r: SU.RT, +tv: F64, +b: Body, +nd: U64) -> NR:
  match ok:
    case False{}: su_refuse(SU.sp_go(False{}), "thicken-open", nd)
    case True{}:
      +s = SU.swo_of(deg, r)
      th_sw_size(SU.sec_t_ok(s, tv), s, tv, b, nd)

def th_sw_single(ok: Bool, +deg: U64, +pp: List<&2, F.Lp>, +tv: F64, +b: Body, +nd: U64) -> NR:
  match ok:
    case False{}: pe_nr(F.Er{24u64, 0n, 0n}, "sweep profile")
    case True{}:
      +r = SU.sw_rect_of(F.lp_pcs(SU.lp0(pp)))
      th_sw_rect(SU.rt_ok(r), deg, r, tv, b, nd)

def th_sw_ax_go(ok: Bool, +e: F.Er, +pp: List<&2, F.Lp>, +hs: List<&2, Bool>, +deg: U64, +tv: F64,
    +b: Body, +nd: U64) -> NR:
  match ok:
    case False{}: pe_nr(e, "sweep profile")
    case True{}: th_sw_single(SU.pp_single(pp, hs), deg, pp, tv, b, nd)

def th_sw_ax(e: F.Er, +pp: List<&2, F.Lp>, +hs: List<&2, Bool>, +deg: U64, +tv: F64, +b: Body,
    +nd: U64) -> NR:
  F.Er{+code, +lp, +sg} = e
  th_sw_ax_go(U64.is_eq(code, 0u64), F.Er{code, lp, sg}, pp, hs, deg, tv, b, nd)

def th_sw_ap(c: F.CK, +deg: U64, +rs: List<&2, F.Region>, +tv: F64, +b: Body, +nd: U64) -> NR:
  match c:
    case F.CK_err{e}: sw_pe(e, nd)
    case F.CK_ok{ls, ps}:
      +hs = rls_holes(F.rg_rls(rs, 0n, F.K_free{}))
      +pp = RV.lps_prep(ls, hs)
      th_sw_ax(RV.ax_codes(pp, hs, 0n), pp, hs, deg, tv, b, nd)

def thicken_swo(+deg: U64, +rs: List<&2, F.Region>, +tv: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  th_sw_ap(F.prof_check(rs, e), deg, rs, tv, b, nd)

def thicken_patch(+ps: List<&2, X.Xp>, +tv: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  +p = SU.pp_ev(ps, e)
  Bool.pick(NR, SU.rect_slab_ok(p),
    mesh_nr(bt_check(SU.slab_bt(p, tv, nd), [], pl_id(), "thicken-open", []), SU.slab_vol(p, tv),
      dels_why(bd_fns(b), 10u64), ""),
    su_refuse(SU.tc_go(False{}), "thicken-open", nd))

def th_kind(o: Op, +tv: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match o:
    case O_loft_open{z, bot, top, twist, cont}: thicken_loft(z, bot, top, twist, cont, tv, b, e, nd)
    case O_sw_open{deg, rs, g, gd, tw}: thicken_swo(deg, rs, tv, b, e, nd)
    case O_patch{ps}: thicken_patch(ps, tv, b, e, nd)
    case _: su_refuse(SU.th_go(False{}), "thicken-open", nd)

def th_t(ok: Bool, +o: Op, +tv: F64, +b: Body, +e: X.Env, +nd: U64) -> NR:
  match ok:
    case False{}: su_refuse(SU.dg_go(False{}, tv), "thicken-open", nd)
    case True{}: th_kind(o, tv, b, e, nd)

def op_thicken_open(+base: U64, +t: X.Xp, +b: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>) -> NR:
  +o = nd_op(ns, base)
  +tv = X.xp_ev(t, e)
  Bool.pick(NR, th_base_ok(o), th_t(Bool.and(T.is_finite(tv), F64.is_lt(0.0f64, tv)), o, tv, b, e, nd),
    su_refuse(SU.th_go(False{}), "thicken-open", nd))
def bl_refuse(+g: BA.GR, +what: String, +nd: U64) -> NR:
  match g:
    case BA.GR_ok{}: bad(what, "node " ++ U64.show(nd), "refusal-missing", "report this design")
    case BA.GR_no{+why, +fix}:
      nr_err(why_k(why_unsup(why), String.eq(why, "blade-stack-not-ruled")), what, "node " ++ U64.show(nd),
        why, fix)

def bl_mesh(r: NR, +v: I.I) -> NR:
  match r:
    case NR_err{k, d}: NR_err{k, d}
    case NR_ok{+b, fx}:
      NR_ok{Bd{bd_cells(b), bd_brep(b), bd_fns(b), bd_pl(b), bd_rv(b),
        Xb{[ms_put_vol(body_ms(b), v)], xb_nc(bd_xb(b)), xb_bo(bd_xb(b)), xb_pr(bd_xb(b)), xb_dl(bd_xb(b))}},
        fx}

def bl_mesh_go(bt: BD.Bt, +v: I.I, +what: String) -> NR:
  bl_mesh(mesh_go(bt, I.imid(v), what, [], ""), v)

def na_build(+sec: BA.Sec, +nd: U64) -> NR:
  +ses = BA.place_secs([sec, sec], 1.0f64, 0u64, 100u64)
  +m = BA.ring_m(BA.sec_k(sec))
  +z0 = I.imid(BA.se_z(BA.se_at(ses, 0n)))
  +z1 = I.imid(BA.se_z(BA.se_at(ses, 1n)))
  bl_mesh_go(BA.blade_bt(ses, 2n, m, nd, z0, z1), BA.blade_vol_I(ses, m, 1.0f64, 2n), "naca4")

def na_fin(+fin: Bool, +sec: BA.Sec, +nd: U64) -> NR:
  match fin:
    case False{}: bl_refuse(BA.fin_go(False{}), "naca4", nd)
    case True{}: na_build(sec, nd)

def na_np(+np: Bool, +fin: Bool, +sec: BA.Sec, +nd: U64) -> NR:
  match np:
    case False{}: bl_refuse(BA.np_go(False{}), "naca4", nd)
    case True{}: na_fin(fin, sec, nd)

def na_dg(+dg: Bool, +m: U64, +p: U64, +t: U64, +cv: F64, +n: U64, +e: X.Env, +nd: U64) -> NR:
  match dg:
    case False{}: bl_refuse(BA.dg_go(False{}), "naca4", nd)
    case True{}: na_np(BA.np_ok(n), Bool.and(T.is_finite(cv), F64.is_lt(0.0f64, cv)),
      BA.Sec{m, p, t, cv, BA.ring_k(BA.nq_of(n))}, nd)

def op_naca4(+m: U64, +p: U64, +t: U64, +c: X.Xp, +n: U64, +e: X.Env, +nd: U64) -> NR:
  +cv = X.xp_ev(c, e)
  na_dg(BA.dg_ok(m, p, t), m, p, t, cv, n, e, nd)

def bl_is_na(o: Op) -> Bool:
  match o:
    case O_naca4{m, p, t, c, n}: True{}
    case _: False{}

def bl_na(o: Op) -> BA.NA:
  match o:
    case O_naca4{m, p, t, c, n}: BA.NA{m, p, t, c, n}
    case _: BA.NA{10u64, 0u64, 5u64, xk(0.0f64), 0u64}

def bl_nas_go(+ns: List<&2, Node>, ids: List<&2, U64>) -> List<&2, BA.NA>:
  match ids:
    case []: []
    case +h <> t: bl_na(nd_op(ns, h)) <> bl_nas_go(ns, t)

def bl_nas_ok_go(+ns: List<&2, Node>, ids: List<&2, U64>) -> Bool:
  match ids:
    case []: True{}
    case +h <> t: Bool.and(bl_is_na(nd_op(ns, h)), bl_nas_ok_go(ns, t))

def bl_build(+ss: List<&2, BA.Sec>, +zv: F64, +tw: U64, +tp: U64, +nd: U64) -> NR:
  +n = List.length(&2, BA.Sec, ss)
  +ses = BA.place_secs(ss, zv, tw, tp)
  +m = BA.ring_m(BA.sec_k(BA.se_at_sec(ss)))
  +z0 = I.imid(BA.se_z(BA.se_at(ses, 0n)))
  +z1 = I.imid(BA.se_z(BA.se_at(ses, Nat.sub(n, 1n))))
  bl_mesh_go(BA.blade_bt(ses, n, m, nd, z0, z1), BA.blade_vol_I(ses, m, zv, n), "blade")

def bl_rl(+ruled: Bool, +ss: List<&2, BA.Sec>, +zv: F64, +tw: U64, +tp: U64, +nd: U64) -> NR:
  match ruled:
    case False{}: bl_refuse(BA.rl_go(False{}), "blade", nd)
    case True{}: bl_build(ss, zv, tw, tp, nd)

def bl_cf(+fin: Bool, +ss: List<&2, BA.Sec>, +zv: F64, +tw: U64, +tp: U64, +nd: U64) -> NR:
  match fin:
    case False{}: bl_refuse(BA.fin_go(False{}), "blade", nd)
    case True{}: bl_rl(BA.ruled_ok(ss), ss, zv, tw, tp, nd)

def bl_np(+np: Bool, +nas: List<&2, BA.NA>, +ss: List<&2, BA.Sec>, +zv: F64, +tw: U64, +tp: U64,
    +nd: U64) -> NR:
  match np:
    case False{}: bl_refuse(BA.np_go(False{}), "blade", nd)
    case True{}: bl_cf(BA.secs_fin_ok(ss), ss, zv, tw, tp, nd)

def bl_dg(+dg: Bool, +nas: List<&2, BA.NA>, +ss: List<&2, BA.Sec>, +zv: F64, +tw: U64, +tp: U64,
    +nd: U64) -> NR:
  match dg:
    case False{}: bl_refuse(BA.dg_go(False{}), "blade", nd)
    case True{}: bl_np(BA.nas_np_ok(nas), nas, ss, zv, tw, tp, nd)

def bl_secs(+ok: Bool, +nas: List<&2, BA.NA>, +e: X.Env, +zv: F64, +tw: U64, +tp: U64, +nd: U64) -> NR:
  match ok:
    case False{}: bl_refuse(BA.rl_go(False{}), "blade", nd)
    case True{}:
      +ss = BA.secs_of(nas, e)
      bl_dg(BA.secs_dg_ok(ss), nas, ss, zv, tw, tp, nd)

def bl_zv(+fin: Bool, +secs: List<&2, U64>, +zv: F64, +tw: U64, +tp: U64, +e: X.Env, +nd: U64,
    +ns: List<&2, Node>) -> NR:
  match fin:
    case False{}: bl_refuse(BA.fin_go(False{}), "blade", nd)
    case True{}: bl_secs(bl_nas_ok_go(ns, secs), bl_nas_go(ns, secs), e, zv, tw, tp, nd)

def bl_tp(+ok: Bool, +secs: List<&2, U64>, +z: X.Xp, +tw: U64, +tp: U64, +e: X.Env, +nd: U64,
    +ns: List<&2, Node>) -> NR:
  match ok:
    case False{}: bl_refuse(BA.tp_go(False{}, tp), "blade", nd)
    case True{}:
      +zv = X.xp_ev(z, e)
      bl_zv(Bool.and(T.is_finite(zv), F64.is_lt(0.0f64, zv)), secs, zv, tw, tp, e, nd, ns)

def bl_tw(+ok: Bool, +secs: List<&2, U64>, +z: X.Xp, +tw: U64, +tp: U64, +e: X.Env, +nd: U64,
    +ns: List<&2, Node>) -> NR:
  match ok:
    case False{}: bl_refuse(BA.tw_go(False{}, tw), "blade", nd)
    case True{}: bl_tp(BA.tp_ok(tp), secs, z, tw, tp, e, nd, ns)

def bl_ns(+ok: Bool, +secs: List<&2, U64>, +z: X.Xp, +tw: U64, +tp: U64, +e: X.Env, +nd: U64,
    +ns: List<&2, Node>) -> NR:
  match ok:
    case False{}: bl_refuse(BA.ns_go(False{}), "blade", nd)
    case True{}: bl_tw(BA.tw_ok(tw), secs, z, tw, tp, e, nd, ns)

def op_blade(+secs: List<&2, U64>, +z: X.Xp, +tw: U64, +tp: U64, +e: X.Env, +nd: U64,
    +ns: List<&2, Node>) -> NR:
  bl_ns(BA.ns_ok(List.length(&2, U64, secs)), secs, z, tw, tp, e, nd, ns)

def bl_bo(o: Op, +ns: List<&2, Node>) -> BA.BO:
  match o:
    case O_blade{+secs, z, tw, tp}:
      Bool.pick(BA.BO, bl_nas_ok_go(ns, secs), BA.BO_bd{bl_nas_go(ns, secs), z, tw, tp}, BA.BO_bad{})
    case _: BA.BO_bad{}

def bl_chain(+ns: List<&2, Node>, +id: U64) -> BA.BO:
  bl_bo(nd_op(ns, id), ns)

def op_blob_ms(+w: Bool, +ir: BL.IR, +b: Ty.Brep, +nd: U64) -> NR:
  match w:
    case False{}: bad("import", "node " ++ U64.show(nd), BL.ir_why(ir), "re-import the STEP file")
    case True{}: NR_ok{Bd{[], b, blob_fns(BL.lc_nf(BL.im_ct(BL.ir_m(ir))), nd), pl_id(), [],
      Xb{blob_ms(ir) <> [], 0n, False{}, "import:step", []}}, Fx{M_same{}, 0n, 0n, 0n, 0n}}

def op_blob_go(+ir: BL.IR, +b: Ty.Brep, +nd: U64) -> NR:
  op_blob_ms(BL.ir_ok_of(ir), ir, b, nd)

def op_blob_ck(+t: Ty.TRes, +b: Ty.Brep, +nd: U64) -> NR:
  match t:
    case Ty.Tok{v}: op_blob_go(BL.imp_ms(b), b, nd)
    case Ty.Terr{k}: bad("import", "node " ++ U64.show(nd),
      "import-validation-failed at brep stage " ++ stage_why(stage_of(b, fuel_of(b))), "re-import the STEP file")

def op_blob_pay(+w: Bool, +pr: BL.PR, +nd: U64) -> NR:
  match w:
    case False{}: bad("import", "node " ++ U64.show(nd), BL.pr_why(pr), "re-import the STEP file")
    case True{}:
      +b = BL.pr_b(pr)
      op_blob_ck(B4.brep_checked(b, Ty.P_manifold_solid{}, fuel_of(b)), b, nd)

def op_blob_fmt(+w: Bool, +payload: String, +nd: U64) -> NR:
  match w:
    case False{}: bad("import", "node " ++ U64.show(nd), "import-format-unknown", "use format 1 payloads")
    case True{}:
      +pr = BL.pay_brep(payload)
      op_blob_pay(BL.pr_ok_of(pr), pr, nd)

def op_blob(+fmt: U64, +payload: String, +nd: U64) -> NR:
  op_blob_fmt(U64.is_eq(fmt, 1u64), payload, nd)

def op_build(o: Op, +b: Body, +b2: Body, +e: X.Env, +nd: U64, +ns: List<&2, Node>) -> NR:
  match o:
    case O_prism{rs, z0, z1}: op_prism(rs, z0, z1, e, nd)
    case O_box{x, y, z}: op_prism([rect_rg(x, y)], xk(0.0f64), z, e, nd)
    case O_cyl{r, h}: op_prism([circ_rg(r)], xk(0.0f64), h, e, nd)
    case O_pad{base, f, rs, h}: op_feat(0u64, b, f, rs, h, False{}, e, nd, base)
    case O_pocket{base, f, rs, d, thru}: op_feat(1u64, b, f, rs, d, thru, e, nd, base)
    case O_holes{base, f, hs, d, thru}: op_feat(2u64, b, f, hls_rgs(hs), d, thru, e, nd, base)
    case O_move{base, tx, ty, tz, q}: op_move(b, tx, ty, tz, q, e, nd)
    case O_rot{base, ax, deg}: op_rot(b, ax, deg, e, nd)
    case O_unk{name}: bad(name, "node " ++ U64.show(nd), "unknown-op", "use box, cylinder, prism, pad, pocket, holes, move, rotate, revolve, cone, sphere, torus, sweep, loft, chamfer, fillet, draft, offset, shell, thicken, pattern, pattern-holes, flat, bend, hem, loft-open, sweep-open, patch, thicken-open, naca4, blade or import")
    case O_blob{fmt, payload}: op_blob(fmt, payload, nd)
    case O_revolve{rs}: op_rev(rs, e, nd)
    case O_cone{r, h}: op_rev([cone_rg(r, h)], e, nd)
    case O_sph{r}: op_rev([sph_rg(r)], e, nd)
    case O_tor{bigr, r}: op_rev([tor_rg(bigr, r)], e, nd)
    case O_union{an, bn}: bool_run(o, b, b2, nd)
    case O_difference{an, bn}: bool_run(o, b, b2, nd)
    case O_intersection{an, bn}: bool_run(o, b, b2, nd)
    case O_sw_line{z, rs, g, gd, tw}: op_sw_line(z, rs, g, gd, tw, e, nd)
    case O_sw_arc{deg, rs, g, gd, tw}: op_sw_arc(deg, rs, g, gd, tw, e, nd)
    case O_loft{z, bot, top, twist, cont}: op_loft(z, bot, top, twist, cont, e, nd)
    case O_chamfer{base, d}: op_chamfer(base, d, b, e, nd, ns)
    case O_echamf{base, f, cx, cy, r, c}: op_echamf(b, f, cx, cy, r, c, e, nd)
    case O_lchamf{base, sn, n1, n2, c}: op_lchamf(b, n1, n2, c, e, nd)
    case O_fillet{base, r}: op_fillet(base, r, b, e, nd, ns)
    case O_fillet_e{base, n, r0, r1}: op_fillet_e(base, n, r0, r1, b, e, nd, ns)
    case O_draft{base, inset}: op_draft(base, inset, b, e, nd, ns)
    case O_offset{base, d}: op_offset(base, d, b, e, nd, ns)
    case O_shell{base, t, open}: op_shell(base, t, open, b, e, nd, ns)
    case O_thicken{base, t}: op_thicken(base, t, b, e, nd, ns)
    case O_pat_lin{base, nx, dx, ny, dy, nz, dz}: op_pat_lin(base, nx, dx, ny, dy, nz, dz, b, e, nd)
    case O_pat_circ{base, n, r}: op_pat_circ(base, n, r, b, e, nd)
    case O_ph_lin{base, f, nx, ny, dx, dy, x0, y0, r, d, thru}: op_ph_lin(base, f, nx, ny, dx, dy, x0, y0, r, d, thru, b, e, nd)
    case O_ph_circ{base, f, n, rad, cx, cy, r, d, thru}: op_ph_circ(base, f, n, rad, cx, cy, r, d, thru, b, e, nd)
    case O_flat{l, w, t}: op_prism([rect_rg(l, w)], xk(0.0f64), t, e, nd)
    case O_bend{base, n, r, deg}: op_sheet(SH.FT_bend{n, r, deg}, base, b, e, nd, ns)
    case O_hem{base, n, l}: op_sheet(SH.FT_hem{n, l}, base, b, e, nd, ns)
    case O_loft_open{z, bot, top, twist, cont}: op_loft_open(z, bot, top, twist, cont, e, nd)
    case O_sw_open{deg, rs, g, gd, tw}: op_sw_open(deg, rs, g, gd, tw, e, nd)
    case O_patch{ps}: op_patch(ps, e, nd)
    case O_thicken_open{base, t}: op_thicken_open(base, t, b, e, nd, ns)
    case O_naca4{m, p, t, c, n}: op_naca4(m, p, t, c, n, e, nd)
    case O_blade{secs, z, tw, tp}: op_blade(secs, z, tw, tp, e, nd, ns)

def hit_go(hit: Bool, +old: CE, +o: Op, +hasb: Bool, +b: Body, +b2: Body, +e: X.Env, +it: It, +nd: U64,
    +ns: List<&2, Node>) -> NR:
  match hit:
    case True{}: ce_r(old)
    case False{}: publish(op_build(o, b, b2, e, nd, ns), o, hasb, b, it, nd)

def node_go(okb: Bool, +o: Op, +hasb: Bool, +b: Body, +b2: Body, +e: X.Env, +it: It, +nd: U64,
    +key: List<&2, U64>, +old: List<&2, CE>, +ns: List<&2, Node>) -> NR:
  match okb:
    case False{}: bad(op_name(o), "node " ++ U64.show(nd), "input-node-missing-or-failed", "fix the input node first")
    case True{}:
      +oc = ce_find(old, nd)
      hit_go(Bool.and(ce_has(old, nd), keq(ce_key(oc), key)), oc, o, hasb, b, b2, e, it, nd, ns)

def ev_nodes(ns: List<&2, Node>, +e: X.Env, +old: List<&2, CE>, +acc: List<&2, CE>, +all: List<&2, Node>) -> List<&2, CE>:
  match ns:
    case []: List.reverse(&2, CE, acc)
    case n <> t:
      Nd{+nd, +o, +it} = n
      +hasb = op_has_base(o)
      +hasb2 = op_has_b2(o)
      +bc = ce_find(acc, op_base(o))
      +bc2 = ce_find(acc, op_base2(o))
      +okb = Bool.and(Bool.or(Bool.not(hasb), Bool.and(ce_has(acc, op_base(o)), nr_ok(ce_r(bc)))),
        Bool.or(Bool.not(hasb2), Bool.and(ce_has(acc, op_base2(o)), nr_ok(ce_r(bc2)))))
      +key = List.append(&2, U64, op_w(o, e), List.append(&2, U64, it_w(it),
        List.append(&2, U64, Bool.pick(List<&2, U64>, hasb, ce_key(bc), []),
          Bool.pick(List<&2, U64>, hasb2, ce_key(bc2), []))))
      +r = node_go(okb, o, hasb, nr_body(ce_r(bc)), nr_body(ce_r(bc2)), e, it, nd, key, old, all)
      ev_nodes(t, e, old, CE{nd, key, r} <> acc, all)

def ev_go(ok: Bool, +p: Part, +old: List<&2, CE>) -> List<&2, CE>:
  match ok:
    case False{}: [CE{0u64, [], bad("part", "-", "duplicate-node-or-parameter-id", "give every node and parameter a distinct id")}]
    case True{}:
      Pt{ps, +ns} = p
      ev_nodes(ns, X.env_of(pvs_of(ps)), old, [], ns)

def ev_part(+p: Part, +old: List<&2, CE>) -> List<&2, CE>:
  Pt{+ps, +ns} = p
  ev_go(Bool.not(Bool.or(ids_dup(nd_ids(ns)), ids_dup(pm_ids(ps)))), p, old)

