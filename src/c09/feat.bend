import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ../c04/types.bend as Ty
import ../c06/build.bend as BD
import ../c06/prof.bend as F
import ../c06/xp.bend as X

type LF is Data:
  LF{ why: String, kind: U64, x0: F64, y0: F64, x1: F64, y1: F64, u0: F64, v0: F64, u1: F64, v1: F64 }

type CB is Data:
  CB{ ok: Bool, b: BD.Bt }

type Rw is Data:
  Rw{ a: V.Point, b: V.Point, c: V.Point, d: V.Point }

type FM is Data:
  FM{ x: F64, y: F64, z: F64, r: F64, nd: U64 }

type FR is Data:
  FR{ x0: F64, y0: F64, x1: F64, y1: F64, u0: F64, v0: F64, u1: F64, v1: F64, z: F64, nd: U64 }

type CN is Data:
  CN{ e: Nat, x: F64, y: F64, h: F64, r0: F64, r1: F64, za: F64, ax: F64, ay: F64, az: F64, k: F64, nd: U64, surf: G.GVal }

def pi() -> F64:
  F64{4614256656552045848u64}

def why_sw_ang(deg: U64) -> String:
  match deg:
    case 90u64: ""
    case 180u64: ""
    case 270u64: ""
    case 360u64: ""
    case _: "sweep-angle-not-certified"

def why_g_line(g: U64) -> String:
  match g:
    case 0u64: ""
    case 1u64: ""
    case _: "guide-not-admitted"

def why_g_arc2(ok: Bool) -> String:
  match ok:
    case True{}: ""
    case False{}: "guide-not-admitted"

def why_g_arc(z: Bool, +g: U64, +gd: U64, +deg: U64) -> String:
  match z:
    case True{}: ""
    case False{}: why_g_arc2(Bool.and(U64.is_eq(g, 2u64), U64.is_eq(gd, deg)))

def why_guide(kind: U64, +g: U64, +gd: U64, +deg: U64) -> String:
  match kind:
    case 0u64: why_g_line(g)
    case _: why_g_arc(U64.is_eq(g, 0u64), g, gd, deg)

def why_twist(t: U64) -> String:
  match t:
    case 0u64: ""
    case _: "twist-not-admitted"

def why_loft_g1(cont: U64) -> String:
  match cont:
    case 1u64: "continuity-not-met"
    case _: ""

def guide_pr(g: U64) -> String:
  match g:
    case 0u64: ""
    case _: "guide: path"

def sw_k(deg: U64) -> F64:
  match deg:
    case 90u64: 0.25f64
    case 180u64: 0.5f64
    case 270u64: F64.div(3.0f64, 4.0f64)
    case _: 1.0f64

def sw_quads(deg: U64) -> Nat:
  match deg:
    case 90u64: 1n
    case 180u64: 2n
    case 270u64: 3n
    case _: 4n

def vol_chamfer_box(+x: F64, +y: F64, +z: F64, +d: F64) -> F64:
  F64.sub(F64.mul(F64.mul(x, y), z), F64.mul(F64.mul(2.0f64, F64.mul(d, d)), z))

def vol_chamfer_cyl(+r: F64, +h: F64, +d: F64) -> F64:
  +rr = F64.mul(r, r)
  +dd = F64.mul(d, d)
  +num = F64.sub(F64.mul(F64.mul(3.0f64, rr), h), F64.mul(F64.mul(2.0f64, dd), F64.sub(F64.mul(3.0f64, r), d)))
  F64.div(F64.mul(pi(), num), 3.0f64)

def vol_fillet_box(+x: F64, +y: F64, +z: F64, +r: F64) -> F64:
  +a = F64.sub(x, F64.mul(2.0f64, r))
  +b = F64.sub(y, F64.mul(2.0f64, r))
  +c = F64.sub(z, F64.mul(2.0f64, r))
  +p = pi()
  +ab = F64.mul(a, b)
  +bc = F64.mul(b, c)
  +ca = F64.mul(c, a)
  +r2 = F64.mul(r, r)
  F64.add(F64.mul(ab, c), F64.add(F64.mul(F64.mul(2.0f64, F64.add(ab, F64.add(bc, ca))), r),
    F64.add(F64.mul(F64.mul(p, F64.add(a, F64.add(b, c))), r2),
      F64.mul(F64.mul(F64.div(4.0f64, 3.0f64), p), F64.mul(r2, r)))))

def vol_fillet_cyl(+rc: F64, +h: F64, +r: F64) -> F64:
  +p = pi()
  +r2 = F64.mul(r, r)
  +term = F64.sub(F64.mul(F64.mul(p, r2), F64.sub(F64.mul(2.0f64, rc), r)),
    F64.mul(F64.mul(F64.div(F64.mul(p, p), 2.0f64), F64.sub(rc, r)), r2))
  F64.sub(F64.mul(F64.mul(p, F64.mul(rc, rc)), h), F64.mul(2.0f64, term))

def vol_fillet_edge(+x: F64, +y: F64, +z: F64, +r0: F64, +r1: F64) -> F64:
  +i = F64.div(F64.mul(z, F64.add(F64.mul(r0, r0), F64.add(F64.mul(r0, r1), F64.mul(r1, r1)))), 3.0f64)
  F64.sub(F64.mul(F64.mul(x, y), z), F64.mul(F64.sub(1.0f64, F64.div(pi(), 4.0f64)), i))

def vol_draft(+x: F64, +y: F64, +z: F64, +inset: F64) -> F64:
  F64.mul(z, F64.add(F64.sub(F64.mul(x, y), F64.mul(inset, F64.add(x, y))),
    F64.mul(F64.div(4.0f64, 3.0f64), F64.mul(inset, inset))))

def vol_offset_box(+x: F64, +y: F64, +z: F64, +d: F64) -> F64:
  F64.mul(F64.mul(F64.add(x, F64.mul(2.0f64, d)), F64.add(y, F64.mul(2.0f64, d))), F64.add(z, F64.mul(2.0f64, d)))

def vol_offset_cyl(+r: F64, +h: F64, +d: F64) -> F64:
  +rd = F64.add(r, d)
  F64.mul(F64.mul(pi(), F64.mul(rd, rd)), F64.add(h, F64.mul(2.0f64, d)))

def vol_shell_box(+x: F64, +y: F64, +z: F64, +t: F64) -> F64:
  +a = F64.sub(x, F64.mul(2.0f64, t))
  +b = F64.sub(y, F64.mul(2.0f64, t))
  +c = F64.sub(z, F64.mul(2.0f64, t))
  F64.sub(F64.mul(F64.mul(x, y), z), F64.mul(F64.mul(a, b), c))

def vol_shell_open(+x: F64, +y: F64, +z: F64, +t: F64) -> F64:
  +a = F64.sub(x, F64.mul(2.0f64, t))
  +b = F64.sub(y, F64.mul(2.0f64, t))
  +c = F64.sub(z, t)
  F64.sub(F64.mul(F64.mul(x, y), z), F64.mul(F64.mul(a, b), c))

def vol_shell_cyl(+r: F64, +h: F64, +t: F64) -> F64:
  +ri = F64.sub(r, t)
  +hi = F64.sub(h, F64.mul(2.0f64, t))
  F64.mul(pi(), F64.sub(F64.mul(F64.mul(r, r), h), F64.mul(F64.mul(ri, ri), hi)))

def vol_loft(+z: F64, +b1: F64, +b2: F64, +m: F64) -> F64:
  F64.div(F64.mul(z, F64.add(b1, F64.add(b2, F64.mul(4.0f64, m)))), 6.0f64)

def area_r(+x0: F64, +y0: F64, +x1: F64, +y1: F64) -> F64:
  F64.mul(F64.sub(x1, x0), F64.sub(y1, y0))

def vol_frust(+z: F64, +x0: F64, +y0: F64, +x1: F64, +y1: F64, +u0: F64, +v0: F64, +u1: F64, +v1: F64) -> F64:
  vol_loft(z, area_r(x0, y0, x1, y1), area_r(u0, v0, u1, v1),
    area_r(F64.mul(0.5f64, F64.add(x0, u0)), F64.mul(0.5f64, F64.add(y0, v0)),
      F64.mul(0.5f64, F64.add(x1, u1)), F64.mul(0.5f64, F64.add(y1, v1))))

def xp(+v: F64) -> X.Xp:
  X.X_k{v}

def ln(+x: F64, +y: F64) -> F.Seg:
  F.S_line{xp(x), xp(y)}

def ar(+cx: F64, +cy: F64, +r: F64, +x: F64, +y: F64, +ccw: Bool) -> F.Seg:
  F.S_arc{xp(cx), xp(cy), xp(r), xp(x), xp(y), ccw}

def rg(+x0: F64, +y0: F64, +ss: List<&2, F.Seg>) -> F.Region:
  F.Rg{F.L_path{xp(x0), xp(y0), ss}, []}

def chamfer_rg(+x: F64, +y: F64, +d: F64) -> F.Region:
  rg(d, 0.0f64, [ln(F64.sub(x, d), 0.0f64), ln(x, d), ln(x, F64.sub(y, d)), ln(F64.sub(x, d), y),
    ln(d, y), ln(0.0f64, F64.sub(y, d)), ln(0.0f64, d)])

def fil_rg0(+x: F64, +y: F64, +r: F64) -> F.Region:
  rg(r, 0.0f64, [ar(r, r, r, 0.0f64, r, False{}), ln(0.0f64, y), ln(x, y), ln(x, 0.0f64)])

def fil_rg1(+x: F64, +y: F64, +r: F64) -> F.Region:
  rg(F64.sub(x, r), 0.0f64, [ar(F64.sub(x, r), r, r, x, r, True{}), ln(x, y), ln(0.0f64, y), ln(0.0f64, 0.0f64)])

def fil_rg2(+x: F64, +y: F64, +r: F64) -> F.Region:
  rg(x, F64.sub(y, r), [ar(F64.sub(x, r), F64.sub(y, r), r, F64.sub(x, r), y, True{}),
    ln(0.0f64, y), ln(0.0f64, 0.0f64), ln(x, 0.0f64)])

def fil_rg3(+x: F64, +y: F64, +r: F64) -> F.Region:
  rg(r, y, [ar(r, F64.sub(y, r), r, 0.0f64, F64.sub(y, r), True{}), ln(0.0f64, 0.0f64), ln(x, 0.0f64), ln(x, y)])

def fil_edge_rg(n: U64, +x: F64, +y: F64, +r: F64) -> F.Region:
  match n:
    case 0u64: fil_rg0(x, y, r)
    case 1u64: fil_rg1(x, y, r)
    case 2u64: fil_rg2(x, y, r)
    case _: fil_rg3(x, y, r)

def cyl_chamfer_rg(+r: F64, +h: F64, +d: F64) -> F.Region:
  rg(0.0f64, 0.0f64, [ln(F64.sub(r, d), 0.0f64), ln(r, d), ln(r, F64.sub(h, d)),
    ln(F64.sub(r, d), h), ln(0.0f64, h)])

def cyl_fillet_rg(+rc: F64, +h: F64, +r: F64) -> F.Region:
  rg(0.0f64, 0.0f64, [ln(F64.sub(rc, r), 0.0f64), ar(F64.sub(rc, r), r, r, rc, r, True{}),
    ln(rc, F64.sub(h, r)), ar(F64.sub(rc, r), F64.sub(h, r), r, F64.sub(rc, r), h, True{}), ln(0.0f64, h)])

def lf_z() -> LF:
  LF{"", 0u64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def lf_bad(+why: String) -> LF:
  LF{why, 0u64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def lf_why(l: LF) -> String:
  LF{why, kind, x0, y0, x1, y1, u0, v0, u1, v1} = l
  why

def lf_kind(l: LF) -> U64:
  LF{why, kind, x0, y0, x1, y1, u0, v0, u1, v1} = l
  kind

def lf_x0(l: LF) -> F64:
  LF{why, kind, x0, y0, x1, y1, u0, v0, u1, v1} = l
  x0

def lf_y0(l: LF) -> F64:
  LF{why, kind, x0, y0, x1, y1, u0, v0, u1, v1} = l
  y0

def lf_x1(l: LF) -> F64:
  LF{why, kind, x0, y0, x1, y1, u0, v0, u1, v1} = l
  x1

def lf_y1(l: LF) -> F64:
  LF{why, kind, x0, y0, x1, y1, u0, v0, u1, v1} = l
  y1

def lf_u0(l: LF) -> F64:
  LF{why, kind, x0, y0, x1, y1, u0, v0, u1, v1} = l
  u0

def lf_v0(l: LF) -> F64:
  LF{why, kind, x0, y0, x1, y1, u0, v0, u1, v1} = l
  v0

def lf_u1(l: LF) -> F64:
  LF{why, kind, x0, y0, x1, y1, u0, v0, u1, v1} = l
  u1

def lf_v1(l: LF) -> F64:
  LF{why, kind, x0, y0, x1, y1, u0, v0, u1, v1} = l
  v1

def cb_ok(c: CB) -> Bool:
  CB{ok, b} = c
  ok

def cb_b(c: CB) -> BD.Bt:
  CB{ok, b} = c
  b

def modn(+k: Nat, +n: Nat) -> Nat:
  Nat.sub(k, Nat.mul(Nat.div(k, n), n))

def bit0(+n: Nat) -> Bool:
  Bool.not(Nat.is_eq(Nat.mul(Nat.div(n, 2n), 2n), n))

def div2(+n: Nat) -> Nat:
  Nat.div(n, 2n)

def div3(+n: Nat) -> Nat:
  Nat.div(n, 3n)

def mod3(+n: Nat) -> Nat:
  Nat.sub(n, Nat.mul(Nat.div(n, 3n), 3n))

def nat_head(xs: List<&2, Nat>) -> Nat:
  match xs:
    case []: 0n
    case h <> t: h

def nat_tail(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case []: []
    case h <> t: t

def n_at(xs: List<&2, Nat>, +i: Nat) -> Nat:
  match xs:
    case []: 0n
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: n_at(t, j)

def pc_head(ps: List<&2, F.Pc>) -> F.Pc:
  match ps:
    case []: F.P_ln{0.0f64, 0.0f64, 0.0f64, 0.0f64}
    case h <> t: h

def pc_tail(ps: List<&2, F.Pc>) -> List<&2, F.Pc>:
  match ps:
    case []: []
    case h <> t: t

def pc_nth(ps: List<&2, F.Pc>, +i: Nat) -> F.Pc:
  match ps:
    case []: F.P_ln{0.0f64, 0.0f64, 0.0f64, 0.0f64}
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: pc_nth(t, j)

def pcs_ln(ps: List<&2, F.Pc>) -> Bool:
  match ps:
    case []: True{}
    case p <> t:
      match p:
        case F.P_ln{ax, ay, bx, by}: pcs_ln(t)
        case F.P_ar{ax, ay, px, py, w, bx, by}: False{}

def cross2(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64) -> F64:
  F64.sub(F64.mul(F64.sub(bx, ax), F64.sub(cy, ay)), F64.mul(F64.sub(by, ay), F64.sub(cx, ax)))

def proper4(+ax: F64, +ay: F64, +bx: F64, +by: F64, +cx: F64, +cy: F64, +dx: F64, +dy: F64) -> Bool:
  +p1 = F64.mul(cross2(ax, ay, bx, by, cx, cy), cross2(ax, ay, bx, by, dx, dy))
  +p2 = F64.mul(cross2(cx, cy, dx, dy, ax, ay), cross2(cx, cy, dx, dy, bx, by))
  Bool.and(F64.is_lt(p1, 0.0f64), F64.is_lt(p2, 0.0f64))

def top_at(+pt: List<&2, F.Pc>, +i: Nat, +tw: Nat, +n: Nat) -> F.Pc:
  pc_nth(pt, modn(Nat.add(i, tw), n))

def quad_ok(+i: Nat, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +n: Nat, +tw: Nat, +z: F64) -> Bool:
  +a = pc_nth(pb, i)
  +b = pc_nth(pb, modn(Nat.add(i, 1n), n))
  +d = top_at(pt, i, tw, n)
  +c = top_at(pt, modn(Nat.add(i, 1n), n), tw, n)
  +ax = F.pc_ax(a)
  +ay = F.pc_ay(a)
  +bax = F64.sub(F.pc_ax(b), ax)
  +bay = F64.sub(F.pc_ay(b), ay)
  +cx = F.pc_ax(c)
  +cy = F.pc_ay(c)
  +dx = F.pc_ax(d)
  +dy = F.pc_ay(d)
  +trip = F64.add(F64.mul(bax, F64.sub(dy, cy)), F64.mul(bay, F64.sub(cx, dx)))
  +crs = F64.add(F64.add(F64.mul(F64.mul(bay, z), F64.mul(bay, z)), F64.mul(F64.mul(bax, z), F64.mul(bax, z))),
    F64.mul(F64.sub(F64.mul(bax, F64.sub(dy, ay)), F64.mul(bay, F64.sub(dx, ax))),
      F64.sub(F64.mul(bax, F64.sub(dy, ay)), F64.mul(bay, F64.sub(dx, ax)))))
  Bool.and(F64.is_eq(trip, 0.0f64), F64.is_lt(0.0f64, crs))

def quads(left: Nat, +i: Nat, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +n: Nat, +tw: Nat, +z: F64) -> Bool:
  match left:
    case 0n: True{}
    case 1n+k: Bool.pick(Bool, quad_ok(i, pb, pt, n, tw, z), quads(k, Nat.add(i, 1n), pb, pt, n, tw, z), False{})

def x_ij(+i: Nat, +j: Nat, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +n: Nat, +tw: Nat) -> Bool:
  +a = pc_nth(pb, i)
  +b = top_at(pt, i, tw, n)
  +c = pc_nth(pb, j)
  +d = top_at(pt, j, tw, n)
  proper4(F.pc_ax(a), F.pc_ay(a), F.pc_ax(b), F.pc_ay(b), F.pc_ax(c), F.pc_ay(c), F.pc_ax(d), F.pc_ay(d))

def xing_j(left: Nat, +j: Nat, +i: Nat, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +n: Nat, +tw: Nat) -> Bool:
  match left:
    case 0n: False{}
    case 1n+k: Bool.pick(Bool, x_ij(i, j, pb, pt, n, tw), True{}, xing_j(k, Nat.add(j, 1n), i, pb, pt, n, tw))

def xing_i(left: Nat, +i: Nat, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +n: Nat, +tw: Nat) -> Bool:
  match left:
    case 0n: False{}
    case 1n+k: Bool.pick(Bool, xing_j(Nat.sub(n, Nat.add(i, 1n)), Nat.add(i, 1n), i, pb, pt, n, tw), True{}, xing_i(k, Nat.add(i, 1n), pb, pt, n, tw))

def rect4(+p0: F.Pc, +p1: F.Pc, +p2: F.Pc, +p3: F.Pc) -> Bool:
  Bool.and(F64.is_eq(F.pc_ay(p0), F.pc_ay(p1)), Bool.and(F64.is_eq(F.pc_ax(p1), F.pc_ax(p2)),
    Bool.and(F64.is_eq(F.pc_ay(p2), F.pc_ay(p3)), Bool.and(F64.is_eq(F.pc_ax(p3), F.pc_ax(p0)),
      Bool.and(F64.is_lt(F.pc_ax(p0), F.pc_ax(p1)), F64.is_lt(F.pc_ay(p0), F.pc_ay(p2)))))))

def bits_pt(+p: F.Pc, +q: F.Pc) -> Bool:
  Bool.and(U64.is_eq(F64.bits(F.pc_ax(p)), F64.bits(F.pc_ax(q))),
    U64.is_eq(F64.bits(F.pc_ay(p)), F64.bits(F.pc_ay(q))))

def lf_of(+kind: U64, +why: String, +p0: F.Pc, +p2: F.Pc, +q0: F.Pc, +q2: F.Pc) -> LF:
  LF{why, kind, F.pc_ax(p0), F.pc_ay(p0), F.pc_ax(p2), F.pc_ay(p2), F.pc_ax(q0), F.pc_ay(q0), F.pc_ax(q2), F.pc_ay(q2)}

def lf_pick2(rect: Bool, +p0: F.Pc, +p2: F.Pc, +q0: F.Pc, +q2: F.Pc) -> LF:
  match rect:
    case True{}: lf_of(2u64, "", p0, p2, q0, q2)
    case False{}: lf_bad("loft-not-certified")

def lf_pick(ident: Bool, +rect: Bool, +p0: F.Pc, +p2: F.Pc, +q0: F.Pc, +q2: F.Pc) -> LF:
  match ident:
    case True{}: lf_of(1u64, "", p0, p2, q0, q2)
    case False{}: lf_pick2(rect, p0, p2, q0, q2)

def lf_cls4(+tw0: Bool, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +tw: Nat, +n: Nat) -> LF:
  +p0 = pc_nth(pb, 0n)
  +p1 = pc_nth(pb, 1n)
  +p2 = pc_nth(pb, 2n)
  +p3 = pc_nth(pb, 3n)
  +q0 = top_at(pt, 0n, tw, n)
  +q1 = top_at(pt, 1n, tw, n)
  +q2 = top_at(pt, 2n, tw, n)
  +q3 = top_at(pt, 3n, tw, n)
  +rb = rect4(p0, p1, p2, p3)
  +rt = rect4(q0, q1, q2, q3)
  +same = Bool.and(Bool.and(bits_pt(p0, q0), bits_pt(p1, q1)), Bool.and(bits_pt(p2, q2), bits_pt(p3, q3)))
  lf_pick(Bool.and(tw0, Bool.and(same, Bool.and(rb, rt))), Bool.and(rb, rt), p0, p2, q0, q2)

def lf_cls(four: Bool, +tw0: Bool, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +tw: Nat, +n: Nat) -> LF:
  match four:
    case False{}: LF{"loft-not-certified", 3u64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}
    case True{}: lf_cls4(tw0, pb, pt, tw, n)

def lf_kind_go(g1: Bool, +tw0: Bool, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +tw: Nat, +n: Nat) -> LF:
  match g1:
    case True{}: lf_bad("continuity-not-met")
    case False{}: lf_cls(Nat.is_eq(n, 4n), tw0, pb, pt, tw, n)

def loft_xi(hit: Bool, +g1: Bool, +tw0: Bool, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +tw: Nat, +n: Nat) -> LF:
  match hit:
    case True{}: lf_bad("loft-self-intersection")
    case False{}: lf_kind_go(g1, tw0, pb, pt, tw, n)

def loft_pl(ok: Bool, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +n: Nat, +tw: Nat, +cont: U64) -> LF:
  match ok:
    case False{}: lf_bad("loft-face-not-planar")
    case True{}: loft_xi(xing_i(Nat.sub(n, 1n), 0n, pb, pt, n, tw), U64.is_eq(cont, 1u64), Nat.is_eq(tw, 0n), pb, pt, tw, n)

def loft_n(ok: Bool, +pb: List<&2, F.Pc>, +pt: List<&2, F.Pc>, +n: Nat, +tw: Nat, +cont: U64, +z: F64) -> LF:
  match ok:
    case False{}: lf_bad("loft-topology-mismatch")
    case True{}: loft_pl(quads(n, 0n, pb, pt, n, modn(tw, n), z), pb, pt, n, modn(tw, n), cont)

def loft_h(holes: Bool, +bot: F.Lp, +top: F.Lp, +tw: Nat, +cont: U64, +z: F64) -> LF:
  match holes:
    case True{}: lf_bad("loft-topology-mismatch")
    case False{}:
      +pb = F.lp_pcs(bot)
      +pt = F.lp_pcs(top)
      +nb = List.length(&2, F.Pc, pb)
      loft_n(Bool.and(Nat.is_eq(nb, List.length(&2, F.Pc, pt)), Bool.and(Nat.is_lt(2n, nb), Bool.and(pcs_ln(pb), pcs_ln(pt)))),
        pb, pt, nb, tw, cont, z)

def loft_lf(holes: Bool, +bot: F.Lp, +top: F.Lp, +tw: Nat, +cont: U64, +z: F64) -> LF:
  loft_h(holes, bot, top, tw, cont, z)

def pt(+x: F64, +y: F64, +z: F64) -> V.Point:
  V.Pt{x, y, z}

def sub_pt(+a: V.Point, +b: V.Point) -> V.Point:
  V.Pt{ax, ay, az} = a
  V.Pt{bx, by, bz} = b
  V.Pt{F64.sub(ax, bx), F64.sub(ay, by), F64.sub(az, bz)}

def lerp_pt(+a: V.Point, +b: V.Point, +t: F64) -> V.Point:
  V.Pt{ax, ay, az} = a
  V.Pt{bx, by, bz} = b
  V.Pt{F64.add(ax, F64.mul(t, F64.sub(bx, ax))), F64.add(ay, F64.mul(t, F64.sub(by, ay))),
    F64.add(az, F64.mul(t, F64.sub(bz, az)))}

def third() -> F64:
  F64.div(1.0f64, 3.0f64)

def two3() -> F64:
  F64.div(2.0f64, 3.0f64)

def elev(+a: V.Point, +b: V.Point) -> Rw:
  Rw{a, lerp_pt(a, b, third()), lerp_pt(a, b, two3()), b}

def lerp_rw(p: Rw, +q: Rw, +t: F64) -> Rw:
  Rw{a, b, c, d} = p
  Rw{e, f, g, h} = q
  Rw{lerp_pt(a, e, t), lerp_pt(b, f, t), lerp_pt(c, g, t), lerp_pt(d, h, t)}

def bp_rows(bot: Rw, +top: Rw, +r1: Rw, +r2: Rw) -> G.BezP:
  Rw{a0, b0, c0, d0} = bot
  Rw{a3, b3, c3, d3} = top
  Rw{a1, b1, c1, d1} = r1
  Rw{a2, b2, c2, d2} = r2
  G.Bp{a0, b0, c0, d0, a1, b1, c1, d1, a2, b2, c2, d2, a3, b3, c3, d3}

def bp_pair(+bot: Rw, +top: Rw) -> G.BezP:
  bp_rows(bot, top, lerp_rw(bot, top, third()), lerp_rw(bot, top, two3()))

def bp_of(+a: V.Point, +b: V.Point, +c: V.Point, +d: V.Point) -> G.BezP:
  bp_pair(elev(a, b), elev(d, c))

def dx() -> V.Dir:
  V.Dr{1.0f64, 0.0f64, 0.0f64}

def dy() -> V.Dir:
  V.Dr{0.0f64, 1.0f64, 0.0f64}

def dz() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, 1.0f64}

def dny() -> V.Dir:
  V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64}

def dnz() -> V.Dir:
  V.Dr{0.0f64, 0.0f64, F64.neg(1.0f64)}

def z2() -> V.Vec2:
  V.V2{0.0f64, 0.0f64}

def v2(+x: F64, +y: F64) -> V.Vec2:
  V.V2{x, y}

def ed_ln(+ia: Nat, +ib: Nat, +pa: V.Point, +pb: V.Point) -> Ty.Edge:
  V.Pt{ax, ay, az} = pa
  V.Pt{bx, by, bz} = pb
  Ty.Ed{0u64, BD.hv(ia), BD.hv(ib), Ty.EK_curve{G.GV_ln{G.Ln{pa, V.Dr{F64.sub(bx, ax), F64.sub(by, ay), F64.sub(bz, az)}}},
    G.Dom{0.0f64, 1.0f64}}}

def ed_rq(+ia: Nat, +ib: Nat, +gv: G.GVal) -> Ty.Edge:
  Ty.Ed{0u64, BD.hv(ia), BD.hv(ib), Ty.EK_curve{gv, G.Dom{0.0f64, 1.0f64}}}

def gv_or(r: G.GRes) -> G.GVal:
  match r:
    case G.Gok{v}: v
    case G.Gerr{kind}: G.GV_f{0.0f64}

def gv_rq(+c: V.Point, +u: V.Dir, +v: V.Dir, +r: F64) -> G.GVal:
  gv_or(GO.rq_quarter(c, u, v, r))

def use_of(+e: Nat, +fwd: Bool, +ta: V.Vec2, +tb: V.Vec2) -> BD.Use:
  BD.Us{e, fwd, ta, tb}

def use0(+e: Nat, +fwd: Bool) -> BD.Use:
  BD.Us{e, fwd, z2(), z2()}

def face1(+surf: G.GVal, +loop: List<&2, BD.Use>, +nd: U64, +i: Nat) -> BD.FS:
  BD.FS{0n, surf, True{}, [loop], BD.Fn{nd, 0n, 2u64, i, 0n}}

def vx_gen(vs: List<&2, Ty.Vertex>, +i: Nat) -> List<&2, Ty.Vertex>:
  match vs:
    case []: []
    case v <> t:
      Ty.Vx{g, p} = v
      Ty.Vx{U64.from_nat(Nat.add(i, 1n)), p} <> vx_gen(t, Nat.add(i, 1n))

def pack(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +fs: List<&2, BD.FS>) -> BD.Bt:
  +st = BD.fs_emit(fs, BD.St{0n, 0n, [], [], []}, 0n)
  +runs = BD.sol_runs(fs, 0n, 0n, [])
  +n = List.length(&2, List<&2, Ty.HFace>, runs)
  BD.Bt{BD.st_br(st, vx_gen(vs, 0n), BD.ed_gen(es, 0n), BD.shs_of(runs, 0n), BD.sos_of(n, 0n), Ty.Cp{BD.hsos_of(n, 0n), []}),
    BD.fs_names(fs)}

def bt_empty() -> BD.Bt:
  BD.Bt{Ty.brep_empty(), []}

def fr_ia() -> List<&2, Nat>:
  [0n, 1n, 2n, 3n, 4n, 5n, 6n, 7n, 0n, 1n, 2n, 3n]

def fr_ib() -> List<&2, Nat>:
  [1n, 2n, 3n, 0n, 5n, 6n, 7n, 4n, 4n, 5n, 6n, 7n]

def fr_pt6(c: Nat, +u0: F64, +v1: F64, +u1: F64, +v1b: F64, +z: F64) -> V.Point:
  match c:
    case 0n: pt(u1, v1b, z)
    case _: pt(u0, v1, z)

def fr_pt5(b: Nat, +u0: F64, +v0: F64, +u1: F64, +v1: F64, +z: F64) -> V.Point:
  match b:
    case 0n: pt(u1, v0, z)
    case 1n+c: fr_pt6(c, u0, v1, u1, v1, z)

def fr_pt4(a: Nat, +u0: F64, +v0: F64, +u1: F64, +v1: F64, +z: F64) -> V.Point:
  match a:
    case 0n: pt(u0, v0, z)
    case 1n+b: fr_pt5(b, u0, v0, u1, v1, z)

def fr_pt3(m: Nat, +x0: F64, +y1: F64, +u0: F64, +v0: F64, +u1: F64, +v1: F64, +z: F64) -> V.Point:
  match m:
    case 0n: pt(x0, y1, 0.0f64)
    case 1n+a: fr_pt4(a, u0, v0, u1, v1, z)

def fr_pt2(k: Nat, +x0: F64, +y0: F64, +x1: F64, +y1: F64, +u0: F64, +v0: F64, +u1: F64, +v1: F64, +z: F64) -> V.Point:
  match k:
    case 0n: pt(x1, y1, 0.0f64)
    case 1n+m: fr_pt3(m, x0, y1, u0, v0, u1, v1, z)

def fr_pt1(j: Nat, +x0: F64, +y0: F64, +x1: F64, +y1: F64, +u0: F64, +v0: F64, +u1: F64, +v1: F64, +z: F64) -> V.Point:
  match j:
    case 0n: pt(x1, y0, 0.0f64)
    case 1n+k: fr_pt2(k, x0, y0, x1, y1, u0, v0, u1, v1, z)

def fr_pt_go(i: Nat, +x0: F64, +y0: F64, +x1: F64, +y1: F64, +u0: F64, +v0: F64, +u1: F64, +v1: F64, +z: F64) -> V.Point:
  match i:
    case 0n: pt(x0, y0, 0.0f64)
    case 1n+j: fr_pt1(j, x0, y0, x1, y1, u0, v0, u1, v1, z)

def fr_pt(i: Nat, +fr: FR) -> V.Point:
  FR{x0, y0, x1, y1, u0, v0, u1, v1, z, nd} = fr
  fr_pt_go(i, x0, y0, x1, y1, u0, v0, u1, v1, z)

def xy_of(p: V.Point) -> V.Vec2:
  V.Pt{x, y, z} = p
  V.V2{x, y}

def xny(p: V.Point) -> V.Vec2:
  V.Pt{x, y, z} = p
  V.V2{x, F64.neg(y)}

def fr_es(left: Nat, +i: Nat, +fr: FR) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k:
      +a = n_at(fr_ia(), i)
      +b = n_at(fr_ib(), i)
      ed_ln(a, b, fr_pt(a, fr), fr_pt(b, fr)) <> fr_es(k, Nat.add(i, 1n), fr)

def fr_bot(+fr: FR) -> List<&2, BD.Use>:
  [use_of(3n, False{}, xny(fr_pt(3n, fr)), xny(fr_pt(0n, fr))),
    use_of(2n, False{}, xny(fr_pt(2n, fr)), xny(fr_pt(3n, fr))),
    use_of(1n, False{}, xny(fr_pt(1n, fr)), xny(fr_pt(2n, fr))),
    use_of(0n, False{}, xny(fr_pt(0n, fr)), xny(fr_pt(1n, fr)))]

def fr_top(+fr: FR) -> List<&2, BD.Use>:
  [use_of(4n, True{}, xy_of(fr_pt(4n, fr)), xy_of(fr_pt(5n, fr))),
    use_of(5n, True{}, xy_of(fr_pt(5n, fr)), xy_of(fr_pt(6n, fr))),
    use_of(6n, True{}, xy_of(fr_pt(6n, fr)), xy_of(fr_pt(7n, fr))),
    use_of(7n, True{}, xy_of(fr_pt(7n, fr)), xy_of(fr_pt(4n, fr)))]

def fr_fs(+fr: FR) -> List<&2, BD.FS>:
  FR{x0, y0, x1, y1, u0, v0, u1, v1, z, nd} = fr
  +v0p = fr_pt(0n, fr)
  +v1p = fr_pt(1n, fr)
  +v2p = fr_pt(2n, fr)
  +v3p = fr_pt(3n, fr)
  +v4p = fr_pt(4n, fr)
  +v5p = fr_pt(5n, fr)
  +v6p = fr_pt(6n, fr)
  +v7p = fr_pt(7n, fr)
  [face1(G.GV_pl{G.Pl{pt(0.0f64, 0.0f64, 0.0f64), dx(), dny()}}, fr_bot(fr), nd, 0n),
    face1(G.GV_pl{G.Pl{pt(0.0f64, 0.0f64, z), dx(), dy()}}, fr_top(fr), nd, 1n),
    face1(G.GV_bp{bp_of(v0p, v1p, v5p, v4p)},
      [use_of(0n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)), use_of(9n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(4n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)), use_of(8n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 2n),
    face1(G.GV_bp{bp_of(v2p, v3p, v7p, v6p)},
      [use_of(2n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)), use_of(11n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(6n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)), use_of(10n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 3n),
    face1(G.GV_bp{bp_of(v3p, v0p, v4p, v7p)},
      [use_of(3n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)), use_of(8n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(7n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)), use_of(11n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 4n),
    face1(G.GV_bp{bp_of(v1p, v2p, v6p, v5p)},
      [use_of(1n, True{}, v2(0.0f64, 0.0f64), v2(1.0f64, 0.0f64)), use_of(10n, True{}, v2(1.0f64, 0.0f64), v2(1.0f64, 1.0f64)),
        use_of(5n, False{}, v2(0.0f64, 1.0f64), v2(1.0f64, 1.0f64)), use_of(9n, False{}, v2(0.0f64, 0.0f64), v2(0.0f64, 1.0f64))], nd, 5n)]

def fr_vs(left: Nat, +i: Nat, +fr: FR) -> List<&2, Ty.Vertex>:
  match left:
    case 0n: []
    case 1n+k: Ty.Vx{0u64, fr_pt(i, fr)} <> fr_vs(k, Nat.add(i, 1n), fr)

def frust_bt(+x0: F64, +y0: F64, +x1: F64, +y1: F64, +u0: F64, +v0: F64, +u1: F64, +v1: F64, +z: F64, +nd: U64) -> BD.Bt:
  +fr = {FR{x0, y0, x1, y1, u0, v0, u1, v1, z, nd} : FR}
  pack(fr_vs(8n, 0n, fr), fr_es(12n, 0n, fr), fr_fs(fr))

def st24() -> List<&2, Nat>:
  [5n, 2n, 8n, 11n, 14n, 17n, 23n, 20n, 13n, 1n, 4n, 16n, 7n, 19n, 22n, 10n, 0n, 12n, 18n, 6n, 15n, 3n, 9n, 21n]

def en24() -> List<&2, Nat>:
  [2n, 8n, 11n, 5n, 17n, 23n, 20n, 14n, 1n, 4n, 16n, 13n, 19n, 22n, 10n, 7n, 12n, 18n, 6n, 0n, 3n, 9n, 21n, 15n]

def sp_es() -> List<&2, Nat>:
  [26n, 25n, 24n, 27n, 28n, 29n, 30n, 31n, 32n, 35n, 34n, 33n, 36n, 37n, 38n, 41n, 40n, 39n, 44n, 43n, 42n, 45n, 46n, 47n]

def sp_fw() -> List<&2, Nat>:
  [0n, 0n, 0n, 1n, 1n, 1n, 1n, 1n, 1n, 0n, 0n, 0n, 1n, 1n, 1n, 0n, 0n, 0n, 0n, 0n, 0n, 1n, 1n, 1n]

def cy_es() -> List<&2, Nat>:
  [24n, 8n, 36n, 16n, 30n, 18n, 42n, 12n, 27n, 20n, 39n, 10n, 33n, 14n, 45n, 22n,
    25n, 0n, 28n, 9n, 37n, 11n, 40n, 4n, 31n, 15n, 34n, 2n, 43n, 6n, 46n, 13n,
    26n, 19n, 32n, 1n, 38n, 7n, 44n, 17n, 29n, 3n, 35n, 21n, 41n, 23n, 47n, 5n]

def cy_fw() -> List<&2, Nat>:
  [1n, 0n, 0n, 0n, 0n, 0n, 1n, 0n, 0n, 0n, 1n, 0n, 1n, 0n, 0n, 0n,
    1n, 0n, 0n, 0n, 0n, 0n, 1n, 0n, 0n, 0n, 1n, 0n, 1n, 0n, 0n, 0n,
    1n, 0n, 0n, 0n, 0n, 0n, 1n, 0n, 0n, 0n, 1n, 0n, 1n, 0n, 0n, 0n]

def sgnf(b: Bool) -> F64:
  match b:
    case True{}: 1.0f64
    case False{}: F64.neg(1.0f64)

def pf(side: Bool, +span: F64, +r: F64) -> F64:
  match side:
    case True{}: F64.sub(span, r)
    case False{}: r

def wall(side: Bool, +span: F64) -> F64:
  match side:
    case True{}: span
    case False{}: 0.0f64

def corn(+sx: Bool, +sy: Bool, +sz: Bool, +fm: FM) -> V.Point:
  FM{x, y, z, r, nd} = fm
  pt(pf(sx, x, r), pf(sy, y, r), pf(sz, z, r))

def fil_pt_1(j: Nat, +sy: Bool, +sz: Bool, +cx: F64, +cy: F64, +cz: F64, +y: F64, +z: F64) -> V.Point:
  match j:
    case 0n: pt(cx, wall(sy, y), cz)
    case _: pt(cx, cy, wall(sz, z))

def pt_x(p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  x

def pt_y(p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  y

def pt_z(p: V.Point) -> F64:
  V.Pt{x, y, z} = p
  z

def fm_x(fm: FM) -> F64:
  FM{x, y, z, r, nd} = fm
  x

def fm_y(fm: FM) -> F64:
  FM{x, y, z, r, nd} = fm
  y

def fm_z(fm: FM) -> F64:
  FM{x, y, z, r, nd} = fm
  z

def fil_pt_k(k: Nat, +sx: Bool, +sy: Bool, +sz: Bool, +c: V.Point, +fm: FM) -> V.Point:
  match k:
    case 0n: pt(wall(sx, fm_x(fm)), pt_y(c), pt_z(c))
    case 1n+j: fil_pt_1(j, sy, sz, pt_x(c), pt_y(c), pt_z(c), fm_y(fm), fm_z(fm))

def fil_pt(+i: Nat, +fm: FM) -> V.Point:
  +c = div3(i)
  +sx = bit0(c)
  +sy = bit0(div2(c))
  +sz = bit0(div2(div2(c)))
  fil_pt_k(mod3(i), sx, sy, sz, corn(sx, sy, sz, fm), fm)

def arc_ia1(j: Nat, +b: Nat) -> Nat:
  match j:
    case 0n: Nat.add(b, 1n)
    case _: Nat.add(b, 2n)

def arc_ia(k: Nat, +b: Nat) -> Nat:
  match k:
    case 0n: b
    case 1n+j: arc_ia1(j, b)

def arc_ib1(j: Nat, +b: Nat) -> Nat:
  match j:
    case 0n: Nat.add(b, 2n)
    case _: b

def arc_ib(k: Nat, +b: Nat) -> Nat:
  match k:
    case 0n: Nat.add(b, 1n)
    case 1n+j: arc_ib1(j, b)

def arc_u1(j: Nat, +sy: Bool, +sz: Bool) -> V.Dir:
  match j:
    case 0n: V.Dr{0.0f64, sgnf(sy), 0.0f64}
    case _: V.Dr{0.0f64, 0.0f64, sgnf(sz)}

def arc_u(k: Nat, +sx: Bool, +sy: Bool, +sz: Bool) -> V.Dir:
  match k:
    case 0n: V.Dr{sgnf(sx), 0.0f64, 0.0f64}
    case 1n+j: arc_u1(j, sy, sz)

def arc_v1(j: Nat, +sx: Bool, +sz: Bool) -> V.Dir:
  match j:
    case 0n: V.Dr{0.0f64, 0.0f64, sgnf(sz)}
    case _: V.Dr{sgnf(sx), 0.0f64, 0.0f64}

def arc_v(k: Nat, +sx: Bool, +sy: Bool, +sz: Bool) -> V.Dir:
  match k:
    case 0n: V.Dr{0.0f64, sgnf(sy), 0.0f64}
    case 1n+j: arc_v1(j, sx, sz)

def fm_r(fm: FM) -> F64:
  FM{x, y, z, r, nd} = fm
  r

def fm_nd(fm: FM) -> U64:
  FM{x, y, z, r, nd} = fm
  nd

def fil_arc(+i: Nat, +fm: FM) -> Ty.Edge:
  +e = Nat.sub(i, 24n)
  +c = div3(e)
  +k = mod3(e)
  +b = Nat.mul(c, 3n)
  +sx = bit0(c)
  +sy = bit0(div2(c))
  +sz = bit0(div2(div2(c)))
  ed_rq(arc_ia(k, b), arc_ib(k, b), gv_rq(corn(sx, sy, sz, fm), arc_u(k, sx, sy, sz), arc_v(k, sx, sy, sz), fm_r(fm)))

def fil_ed_go(st: Bool, +i: Nat, +fm: FM) -> Ty.Edge:
  match st:
    case True{}:
      +a = n_at(st24(), i)
      +b = n_at(en24(), i)
      ed_ln(a, b, fil_pt(a, fm), fil_pt(b, fm))
    case False{}: fil_arc(i, fm)

def fil_es(left: Nat, +i: Nat, +fm: FM) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k: fil_ed_go(Nat.is_lt(i, 24n), i, fm) <> fil_es(k, Nat.add(i, 1n), fm)

def fil_vs(left: Nat, +i: Nat, +fm: FM) -> List<&2, Ty.Vertex>:
  match left:
    case 0n: []
    case 1n+k: Ty.Vx{0u64, fil_pt(i, fm)} <> fil_vs(k, Nat.add(i, 1n), fm)

def trf4(n: Nat, +p: V.Point) -> V.Vec2:
  match n:
    case 0n: V.V2{pt_y(p), F64.neg(pt_z(p))}
    case _: V.V2{pt_y(p), pt_z(p)}

def trf3(m: Nat, +p: V.Point) -> V.Vec2:
  match m:
    case 0n: V.V2{pt_x(p), F64.neg(pt_z(p))}
    case 1n+n: trf4(n, p)

def trf2(k: Nat, +p: V.Point) -> V.Vec2:
  match k:
    case 0n: V.V2{pt_x(p), pt_z(p)}
    case 1n+m: trf3(m, p)

def trf1(j: Nat, +p: V.Point) -> V.Vec2:
  match j:
    case 0n: V.V2{pt_x(p), pt_y(p)}
    case 1n+k: trf2(k, p)

def trf(face: Nat, +p: V.Point) -> V.Vec2:
  match face:
    case 0n: V.V2{pt_x(p), F64.neg(pt_y(p))}
    case 1n+j: trf1(j, p)

def fil_pu(+e: Nat, +face: Nat, +fm: FM) -> BD.Use:
  +a = n_at(st24(), e)
  +b = n_at(en24(), e)
  use_of(e, True{}, trf(face, fil_pt(a, fm)), trf(face, fil_pt(b, fm)))

def pl_k(left: Nat, +k: Nat, +face: Nat, +fm: FM) -> List<&2, BD.Use>:
  match left:
    case 0n: []
    case 1n+j: fil_pu(Nat.add(Nat.mul(face, 4n), k), face, fm) <> pl_k(j, Nat.add(k, 1n), face, fm)

def pl_o4(n: Nat, +x: F64) -> V.Point:
  match n:
    case 0n: pt(0.0f64, 0.0f64, 0.0f64)
    case _: pt(x, 0.0f64, 0.0f64)

def pl_o3(m: Nat, +fm: FM) -> V.Point:
  match m:
    case 0n: pt(0.0f64, fm_y(fm), 0.0f64)
    case 1n+n: pl_o4(n, fm_x(fm))

def pl_o2(k: Nat, +fm: FM) -> V.Point:
  match k:
    case 0n: pt(0.0f64, 0.0f64, 0.0f64)
    case 1n+m: pl_o3(m, fm)

def pl_o1(j: Nat, +fm: FM) -> V.Point:
  match j:
    case 0n: pt(0.0f64, 0.0f64, fm_z(fm))
    case 1n+k: pl_o2(k, fm)

def pl_o(face: Nat, +fm: FM) -> V.Point:
  match face:
    case 0n: pt(0.0f64, 0.0f64, 0.0f64)
    case 1n+j: pl_o1(j, fm)

def pl_v4(n: Nat) -> V.Dir:
  match n:
    case 0n: dnz()
    case _: dz()

def pl_v3(m: Nat) -> V.Dir:
  match m:
    case 0n: dnz()
    case 1n+n: pl_v4(n)

def pl_v2(k: Nat) -> V.Dir:
  match k:
    case 0n: dz()
    case 1n+m: pl_v3(m)

def pl_v1(j: Nat) -> V.Dir:
  match j:
    case 0n: dy()
    case 1n+k: pl_v2(k)

def pl_v(face: Nat) -> V.Dir:
  match face:
    case 0n: dny()
    case 1n+j: pl_v1(j)

def pl_u3(m: Nat) -> V.Dir:
  match m:
    case 0n: dx()
    case _: dy()

def pl_u2(k: Nat) -> V.Dir:
  match k:
    case 0n: dx()
    case 1n+m: pl_u3(m)

def pl_u1(j: Nat) -> V.Dir:
  match j:
    case 0n: dx()
    case 1n+k: pl_u2(k)

def pl_u(face: Nat) -> V.Dir:
  match face:
    case 0n: dx()
    case 1n+j: pl_u1(j)

def take_u(left: Nat, +i: Nat, +base: Nat, +es: List<&2, Nat>, +fw: List<&2, Nat>) -> List<&2, BD.Use>:
  match left:
    case 0n: []
    case 1n+j:
      +k = Nat.add(base, i)
      use0(n_at(es, k), Nat.is_eq(n_at(fw, k), 1n)) <> take_u(j, Nat.add(i, 1n), base, es, fw)

def done_n(+n: Nat) -> Nat:
  n

def cy_v(+sx: Bool, +sy: Bool, +fm: FM) -> G.GVal:
  FM{x, y, z, r, nd} = fm
  G.GV_cy{G.Cy{pt(pf(sx, x, r), pf(sy, y, r), 0.0f64), dz(), r}}

def cy_x(+sy: Bool, +sz: Bool, +fm: FM) -> G.GVal:
  FM{x, y, z, r, nd} = fm
  G.GV_cy{G.Cy{pt(0.0f64, pf(sy, y, r), pf(sz, z, r)), dx(), r}}

def cy_y(+sx: Bool, +sz: Bool, +fm: FM) -> G.GVal:
  FM{x, y, z, r, nd} = fm
  G.GV_cy{G.Cy{pt(pf(sx, x, r), 0.0f64, pf(sz, z, r)), dy(), r}}

def cy_h(xpar: Bool, +local: Nat, +fm: FM) -> G.GVal:
  match xpar:
    case True{}: cy_x(bit0(div2(local)), bit0(local), fm)
    case False{}: cy_y(bit0(div2(local)), bit0(local), fm)

def cy_g(vert: Bool, +fi: Nat, +fm: FM) -> G.GVal:
  match vert:
    case True{}: cy_v(bit0(div2(fi)), bit0(fi), fm)
    case False{}: cy_h(Nat.is_lt(fi, 8n), Nat.sub(fi, Bool.pick(Nat, Nat.is_lt(fi, 8n), 4n, 8n)), fm)

def cy_surf(+face: Nat, +fm: FM) -> G.GVal:
  cy_g(Nat.is_lt(Nat.sub(face, 14n), 4n), Nat.sub(face, 14n), fm)

def sp_surf(+face: Nat, +fm: FM) -> G.GVal:
  +c = Nat.sub(face, 6n)
  G.GV_sp{G.Sp{corn(bit0(c), bit0(div2(c)), bit0(div2(div2(c))), fm), fm_r(fm)}}

def fil_face_q(sp: Bool, +i: Nat, +fm: FM) -> BD.FS:
  match sp:
    case True{}: face1(sp_surf(i, fm), take_u(3n, 0n, Nat.mul(Nat.sub(i, 6n), 3n), sp_es(), sp_fw()), fm_nd(fm), i)
    case False{}: face1(cy_surf(i, fm), take_u(4n, 0n, Nat.mul(Nat.sub(i, 14n), 4n), cy_es(), cy_fw()), fm_nd(fm), i)

def fil_face_go(pl: Bool, +i: Nat, +fm: FM) -> BD.FS:
  match pl:
    case True{}: face1(G.GV_pl{G.Pl{pl_o(i, fm), pl_u(i), pl_v(i)}}, pl_k(4n, 0n, i, fm), fm_nd(fm), i)
    case False{}: fil_face_q(Nat.is_lt(i, 14n), i, fm)

def fil_fs(left: Nat, +i: Nat, +fm: FM) -> List<&2, BD.FS>:
  match left:
    case 0n: []
    case 1n+k: fil_face_go(Nat.is_lt(i, 6n), i, fm) <> fil_fs(k, Nat.add(i, 1n), fm)

def fillet_bt(+x: F64, +y: F64, +z: F64, +r: F64, +nd: U64) -> BD.Bt:
  +fm = {FM{x, y, z, r, nd} : FM}
  pack(fil_vs(24n, 0n, fm), fil_es(48n, 0n, fm), fil_fs(26n, 0n, fm))

def flip_x2(k: Nat) -> Bool:
  match k:
    case 0n: True{}
    case _: False{}

def flip_x1(j: Nat) -> Bool:
  match j:
    case 0n: True{}
    case 1n+k: flip_x2(k)

def flip_x(e: Nat) -> Bool:
  match e:
    case 0n: False{}
    case 1n+j: flip_x1(j)

def flip_y(e: Nat) -> Bool:
  Bool.not(Nat.is_eq(div2(e), 0n))

def mir_f(flip: Bool, +v: F64, +span: F64) -> F64:
  match flip:
    case True{}: F64.sub(span, v)
    case False{}: v

def mir_d(flip: Bool, +v: F64) -> F64:
  match flip:
    case True{}: F64.neg(v)
    case False{}: v

def mir_pt(+e: Nat, +spanx: F64, +spany: F64, +p: V.Point) -> V.Point:
  V.Pt{x, y, z} = p
  pt(mir_f(flip_x(e), x, spanx), mir_f(flip_y(e), y, spany), z)

def mir_dr(+e: Nat, +d: V.Dir) -> V.Dir:
  V.Dr{x, y, z} = d
  V.Dr{mir_d(flip_x(e), x), mir_d(flip_y(e), y), z}

def dr_x(d: V.Dir) -> F64:
  V.Dr{x, y, z} = d
  x

def dr_y(d: V.Dir) -> F64:
  V.Dr{x, y, z} = d
  y

def dr_z(d: V.Dir) -> F64:
  V.Dr{x, y, z} = d
  z

def unit3(+x: F64, +y: F64, +z: F64) -> V.Dir:
  +l = F64.sqrt(F64.add(F64.mul(x, x), F64.add(F64.mul(y, y), F64.mul(z, z))))
  V.Dr{F64.div(x, l), F64.div(y, l), F64.div(z, l)}

def cone_k(+mx: F64, +my: F64, +mz: F64, +ax: F64, +ay: F64, +az: F64) -> F64:
  +mm = F64.add(F64.mul(mx, mx), F64.add(F64.mul(my, my), F64.mul(mz, mz)))
  +ad = F64.add(F64.mul(mx, ax), F64.add(F64.mul(my, ay), F64.mul(mz, az)))
  F64.div(F64.sqrt(F64.sub(mm, F64.mul(ad, ad))), F64.abs(ad))

def cn_ia() -> List<&2, Nat>:
  [0n, 1n, 2n, 3n, 4n, 5n, 6n, 7n, 8n, 9n, 0n, 1n, 2n, 3n, 4n]

def cn_ib() -> List<&2, Nat>:
  [1n, 2n, 3n, 0n, 0n, 6n, 7n, 8n, 9n, 5n, 5n, 6n, 7n, 8n, 9n]

def cn_loc8(e: Nat, +x: F64, +y: F64, +h: F64) -> V.Point:
  match e:
    case 0n: pt(x, y, h)
    case _: pt(x, 0.0f64, h)

def cn_loc7(d: Nat, +x: F64, +y: F64, +h: F64) -> V.Point:
  match d:
    case 0n: pt(0.0f64, y, h)
    case 1n+e: cn_loc8(e, x, y, h)

def cn_loc6(c: Nat, +x: F64, +y: F64, +h: F64, +r1: F64) -> V.Point:
  match c:
    case 0n: pt(0.0f64, r1, h)
    case 1n+d: cn_loc7(d, x, y, h)

def cn_loc5(b: Nat, +x: F64, +y: F64, +h: F64, +r1: F64) -> V.Point:
  match b:
    case 0n: pt(r1, 0.0f64, h)
    case 1n+c: cn_loc6(c, x, y, h, r1)

def cn_loc4(a: Nat, +x: F64, +y: F64, +h: F64, +r1: F64) -> V.Point:
  match a:
    case 0n: pt(x, 0.0f64, 0.0f64)
    case 1n+b: cn_loc5(b, x, y, h, r1)

def cn_loc3(m: Nat, +x: F64, +y: F64, +h: F64, +r1: F64) -> V.Point:
  match m:
    case 0n: pt(x, y, 0.0f64)
    case 1n+a: cn_loc4(a, x, y, h, r1)

def cn_loc2(k: Nat, +x: F64, +y: F64, +h: F64, +r1: F64) -> V.Point:
  match k:
    case 0n: pt(0.0f64, y, 0.0f64)
    case 1n+m: cn_loc3(m, x, y, h, r1)

def cn_loc1(j: Nat, +x: F64, +y: F64, +h: F64, +r0: F64, +r1: F64) -> V.Point:
  match j:
    case 0n: pt(0.0f64, r0, 0.0f64)
    case 1n+k: cn_loc2(k, x, y, h, r1)

def cn_loc_go(i: Nat, +x: F64, +y: F64, +h: F64, +r0: F64, +r1: F64) -> V.Point:
  match i:
    case 0n: pt(r0, 0.0f64, 0.0f64)
    case 1n+j: cn_loc1(j, x, y, h, r0, r1)

def cn_loc(i: Nat, +c: CN) -> V.Point:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  cn_loc_go(i, x, y, h, r0, r1)

def cn_w(i: Nat, +c: CN) -> V.Point:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  mir_pt(e, x, y, cn_loc(i, c))

def cn_trim4(n: Nat, +p: V.Point) -> V.Vec2:
  match n:
    case 0n: V.V2{pt_y(p), pt_z(p)}
    case _: V.V2{pt_x(p), F64.neg(pt_z(p))}

def cn_trim3(m: Nat, +p: V.Point) -> V.Vec2:
  match m:
    case 0n: V.V2{pt_y(p), F64.neg(pt_z(p))}
    case 1n+n: cn_trim4(n, p)

def cn_trim2(k: Nat, +p: V.Point) -> V.Vec2:
  match k:
    case 0n: V.V2{pt_x(p), pt_z(p)}
    case 1n+m: cn_trim3(m, p)

def cn_trim1(j: Nat, +p: V.Point) -> V.Vec2:
  match j:
    case 0n: V.V2{pt_x(p), pt_y(p)}
    case 1n+k: cn_trim2(k, p)

def cn_trim(face: Nat, +p: V.Point) -> V.Vec2:
  match face:
    case 0n: V.V2{pt_x(p), F64.neg(pt_y(p))}
    case 1n+j: cn_trim1(j, p)

def cn_use_go(quad: Bool, +e: Nat, +fwd: Bool, +face: Nat, +c: CN) -> BD.Use:
  match quad:
    case True{}: use0(e, fwd)
    case False{}: use_of(e, fwd, cn_trim(face, cn_loc(n_at(cn_ia(), e), c)), cn_trim(face, cn_loc(n_at(cn_ib(), e), c)))

def cn_fes5(b: Nat) -> List<&2, Nat>:
  match b:
    case 0n: [12n, 7n, 13n, 2n]
    case _: [0n, 10n, 5n, 11n]

def cn_fes4(a: Nat) -> List<&2, Nat>:
  match a:
    case 0n: [3n, 13n, 8n, 14n]
    case 1n+b: cn_fes5(b)

def cn_fes3(m: Nat) -> List<&2, Nat>:
  match m:
    case 0n: [11n, 6n, 12n, 1n]
    case 1n+a: cn_fes4(a)

def cn_fes2(k: Nat) -> List<&2, Nat>:
  match k:
    case 0n: [4n, 14n, 9n, 10n]
    case 1n+m: cn_fes3(m)

def cn_fes1(j: Nat) -> List<&2, Nat>:
  match j:
    case 0n: [9n, 8n, 7n, 6n, 5n]
    case 1n+k: cn_fes2(k)

def cn_fes(face: Nat) -> List<&2, Nat>:
  match face:
    case 0n: [0n, 1n, 2n, 3n, 4n]
    case 1n+j: cn_fes1(j)

def cn_ffw5(b: Nat) -> List<&2, Nat>:
  match b:
    case 0n: [1n, 1n, 0n, 0n]
    case _: [0n, 1n, 1n, 0n]

def cn_ffw4(a: Nat) -> List<&2, Nat>:
  match a:
    case 0n: [0n, 1n, 1n, 0n]
    case 1n+b: cn_ffw5(b)

def cn_ffw3(m: Nat) -> List<&2, Nat>:
  match m:
    case 0n: [1n, 1n, 0n, 0n]
    case 1n+a: cn_ffw4(a)

def cn_ffw2(k: Nat) -> List<&2, Nat>:
  match k:
    case 0n: [0n, 1n, 1n, 0n]
    case 1n+m: cn_ffw3(m)

def cn_ffw1(j: Nat) -> List<&2, Nat>:
  match j:
    case 0n: [0n, 0n, 0n, 0n, 0n]
    case 1n+k: cn_ffw2(k)

def cn_ffw(face: Nat) -> List<&2, Nat>:
  match face:
    case 0n: [1n, 1n, 1n, 1n, 1n]
    case 1n+j: cn_ffw1(j)

def cn_loop(left: Nat, +i: Nat, +face: Nat, +c: CN) -> List<&2, BD.Use>:
  match left:
    case 0n: []
    case 1n+k: cn_use_go(Nat.is_eq(face, 6n), n_at(cn_fes(face), i), Nat.is_eq(n_at(cn_ffw(face), i), 1n), face, c) <> cn_loop(k, Nat.add(i, 1n), face, c)

def mir_pl(+c: CN, +o: V.Point, +u: V.Dir, +v: V.Dir) -> G.GVal:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  G.GV_pl{G.Pl{mir_pt(e, x, y, o), mir_dr(e, u), mir_dr(e, v)}}

def cn_surf5(b: Nat, +c: CN, +y: F64, +surf: G.GVal) -> G.GVal:
  match b:
    case 0n: mir_pl(c, pt(0.0f64, y, 0.0f64), dx(), dnz())
    case _: surf

def cn_surf4(a: Nat, +c: CN, +x: F64, +y: F64, +surf: G.GVal) -> G.GVal:
  match a:
    case 0n: mir_pl(c, pt(x, 0.0f64, 0.0f64), dy(), dz())
    case 1n+b: cn_surf5(b, c, y, surf)

def cn_surf3(m: Nat, +c: CN, +x: F64, +y: F64, +surf: G.GVal) -> G.GVal:
  match m:
    case 0n: mir_pl(c, pt(0.0f64, 0.0f64, 0.0f64), dy(), dnz())
    case 1n+a: cn_surf4(a, c, x, y, surf)

def cn_surf2(k: Nat, +c: CN, +x: F64, +y: F64, +h: F64, +surf: G.GVal) -> G.GVal:
  match k:
    case 0n: mir_pl(c, pt(0.0f64, 0.0f64, 0.0f64), dx(), dz())
    case 1n+m: cn_surf3(m, c, x, y, surf)

def cn_surf1(j: Nat, +c: CN, +x: F64, +y: F64, +h: F64, +surf: G.GVal) -> G.GVal:
  match j:
    case 0n: mir_pl(c, pt(0.0f64, 0.0f64, h), dx(), dy())
    case 1n+k: cn_surf2(k, c, x, y, h, surf)

def cn_surf_go(face: Nat, +c: CN, +x: F64, +y: F64, +h: F64, +surf: G.GVal) -> G.GVal:
  match face:
    case 0n: mir_pl(c, pt(0.0f64, 0.0f64, 0.0f64), dx(), dny())
    case 1n+j: cn_surf1(j, c, x, y, h, surf)

def cn_surf(face: Nat, +c: CN) -> G.GVal:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  cn_surf_go(face, c, x, y, h, surf)

def cn_nd(c: CN) -> U64:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  nd

def cn_fs(left: Nat, +i: Nat, +c: CN) -> List<&2, BD.FS>:
  match left:
    case 0n: []
    case 1n+k: face1(cn_surf(i, c), cn_loop(List.length(&2, Nat, cn_fes(i)), 0n, i, c), cn_nd(c), i) <> cn_fs(k, Nat.add(i, 1n), c)

def cn_vs(left: Nat, +i: Nat, +c: CN) -> List<&2, Ty.Vertex>:
  match left:
    case 0n: []
    case 1n+k: Ty.Vx{0u64, cn_w(i, c)} <> cn_vs(k, Nat.add(i, 1n), c)

def mir_gv(gv: G.GVal, +e: Nat, +x: F64, +y: F64) -> G.GVal:
  match gv:
    case G.GV_rq{q}:
      G.Rq{p0, p1, p2, w0, w1, w2} = q
      G.GV_rq{G.Rq{mir_pt(e, x, y, p0), mir_pt(e, x, y, p1), mir_pt(e, x, y, p2), w0, w1, w2}}
    case _: G.GV_f{0.0f64}

def cn_e(c: CN) -> Nat:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  e

def cn_x(c: CN) -> F64:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  x

def cn_y(c: CN) -> F64:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  y

def cn_h(c: CN) -> F64:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  h

def cn_r0(c: CN) -> F64:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  r0

def cn_r1(c: CN) -> F64:
  CN{e, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf} = c
  r1

def cn_arc(bot: Bool, +e: Nat, +x: F64, +y: F64, +h: F64, +r0: F64, +r1: F64, +a: Nat, +b: Nat) -> Ty.Edge:
  match bot:
    case True{}: ed_rq(a, b, mir_gv(gv_rq(pt(r0, r0, 0.0f64), V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64}, V.Dr{F64.neg(1.0f64), 0.0f64, 0.0f64}, r0), e, x, y))
    case False{}: ed_rq(a, b, mir_gv(gv_rq(pt(r1, r1, h), V.Dr{0.0f64, F64.neg(1.0f64), 0.0f64}, V.Dr{F64.neg(1.0f64), 0.0f64, 0.0f64}, r1), e, x, y))

def cn_ed_go(arc: Bool, +i: Nat, +c: CN) -> Ty.Edge:
  match arc:
    case False{}: ed_ln(n_at(cn_ia(), i), n_at(cn_ib(), i), cn_w(n_at(cn_ia(), i), c), cn_w(n_at(cn_ib(), i), c))
    case True{}: cn_arc(Nat.is_eq(i, 0n), cn_e(c), cn_x(c), cn_y(c), cn_h(c), cn_r0(c), cn_r1(c), n_at(cn_ia(), i), n_at(cn_ib(), i))

def cn_es(left: Nat, +i: Nat, +c: CN) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k: cn_ed_go(Bool.or(Nat.is_eq(i, 0n), Nat.is_eq(i, 5n)), i, c) <> cn_es(k, Nat.add(i, 1n), c)

def cone_go(ok: Bool, +c: CN) -> CB:
  match ok:
    case False{}: CB{False{}, bt_empty()}
    case True{}: CB{True{}, pack(cn_vs(10n, 0n, c), cn_es(15n, 0n, c), cn_fs(7n, 0n, c))}

def cone_bt(+edge: Nat, +x: F64, +y: F64, +h: F64, +r0: F64, +r1: F64, +nd: U64) -> CB:
  +za = F64.div(F64.mul(F64.neg(r0), h), F64.sub(r1, r0))
  +ud = unit3(r0, r0, F64.neg(za))
  +ax = dr_x(ud)
  +ay = dr_y(ud)
  +az = dr_z(ud)
  +k = cone_k(r0, 0.0f64, F64.neg(za), ax, ay, az)
  +apex = mir_pt(edge, x, y, pt(0.0f64, 0.0f64, za))
  +axis = mir_dr(edge, ud)
  +bx = dr_x(axis)
  +by = dr_y(axis)
  +bz = dr_z(axis)
  +surf = {G.GV_co{G.Co{apex, V.Dr{bx, by, bz}, k}} : G.GVal}
  +p0 = mir_pt(edge, x, y, pt(r0, 0.0f64, 0.0f64))
  +p1 = mir_pt(edge, x, y, pt(0.0f64, r0, 0.0f64))
  +p5 = mir_pt(edge, x, y, pt(r1, 0.0f64, h))
  +p6 = mir_pt(edge, x, y, pt(0.0f64, r1, h))
  +ok = Bool.and(Bool.and(T.is_finite(k), F64.is_lt(0.0f64, k)),
    Bool.and(Bool.and(GO.q_on_r(surf, p0), GO.q_on_r(surf, p1)), Bool.and(GO.q_on_r(surf, p5), GO.q_on_r(surf, p6))))
  cone_go(ok, CN{edge, x, y, h, r0, r1, za, ax, ay, az, k, nd, surf})
