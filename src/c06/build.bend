import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ./prof.bend as F

type Cl is Data:
  Cl{ id: Nat, par: Nat, nd: U64, k: Nat, lp: F.Lp, mat: Bool, lo: F64, hi: F64 }

type Wl is Data:
  Wl{ lo: F64, hi: F64, ins: Bool }

type Cd is Data:
  Cd{ c: Cl, pm: Bool, ttr: Bool, btr: Bool, tow: Nat, bow: Nat, sol: Nat, ws: List<&2, Wl>,
    hs: List<&2, F64>, vb: Nat, eb: Nat }

type SI is Data:
  SI{ kind: U64, p0: Nat, n: Nat, ccw: Bool, cx: F64, cy: F64, r: F64, ax: F64, ay: F64,
    bx: F64, by: F64 }

type Use is Data:
  Us{ e: Nat, fwd: Bool, ta: V.Vec2, tb: V.Vec2 }

type Fn is Data:
  Fn{ nd: U64, k: Nat, role: U64, i: Nat, j: Nat }

type FS is Data:
  FS{ sol: Nat, surf: G.GVal, same: Bool, lps: List<&2, List<&2, Use>>, nm: Fn }

type St is Data:
  St{ nce: Nat, nlp: Nat, ces: List<&2, Ty.Coedge>, lps: List<&2, Ty.Loop>, fas: List<&2, Ty.Face> }

type OD is Data:
  OD{ o: Nat, d: Nat }

type Bt is Data:
  Bt{ brep: Ty.Brep, fns: List<&2, Fn> }

def cl_id(c: Cl) -> Nat:
  Cl{id, par, nd, k, lp, mat, lo, hi} = c
  id

def cl_par(c: Cl) -> Nat:
  Cl{id, par, nd, k, lp, mat, lo, hi} = c
  par

def cl_nd(c: Cl) -> U64:
  Cl{id, par, nd, k, lp, mat, lo, hi} = c
  nd

def cl_k(c: Cl) -> Nat:
  Cl{id, par, nd, k, lp, mat, lo, hi} = c
  k

def cl_lp(c: Cl) -> F.Lp:
  Cl{id, par, nd, k, lp, mat, lo, hi} = c
  lp

def cl_mat(c: Cl) -> Bool:
  Cl{id, par, nd, k, lp, mat, lo, hi} = c
  mat

def cl_lo(c: Cl) -> F64:
  Cl{id, par, nd, k, lp, mat, lo, hi} = c
  lo

def cl_hi(c: Cl) -> F64:
  Cl{id, par, nd, k, lp, mat, lo, hi} = c
  hi

def cd_c(d: Cd) -> Cl:
  Cd{c, pm, ttr, btr, tow, bow, sol, ws, hs, vb, eb} = d
  c

def cd_ttr(d: Cd) -> Bool:
  Cd{c, pm, ttr, btr, tow, bow, sol, ws, hs, vb, eb} = d
  ttr

def cd_btr(d: Cd) -> Bool:
  Cd{c, pm, ttr, btr, tow, bow, sol, ws, hs, vb, eb} = d
  btr

def cd_tow(d: Cd) -> Nat:
  Cd{c, pm, ttr, btr, tow, bow, sol, ws, hs, vb, eb} = d
  tow

def cd_bow(d: Cd) -> Nat:
  Cd{c, pm, ttr, btr, tow, bow, sol, ws, hs, vb, eb} = d
  bow

def cd_sol(d: Cd) -> Nat:
  Cd{c, pm, ttr, btr, tow, bow, sol, ws, hs, vb, eb} = d
  sol

def cd_ws(d: Cd) -> List<&2, Wl>:
  Cd{c, pm, ttr, btr, tow, bow, sol, ws, hs, vb, eb} = d
  ws

def cd_hs(d: Cd) -> List<&2, F64>:
  Cd{c, pm, ttr, btr, tow, bow, sol, ws, hs, vb, eb} = d
  hs

def cd_vb(d: Cd) -> Nat:
  Cd{c, pm, ttr, btr, tow, bow, sol, ws, hs, vb, eb} = d
  vb

def cd_eb(d: Cd) -> Nat:
  Cd{c, pm, ttr, btr, tow, bow, sol, ws, hs, vb, eb} = d
  eb

def cd_pad() -> Cd:
  Cd{Cl{0n, 0n, 0u64, 0n, F.K_circ{0.0f64, 0.0f64, 1.0f64}, False{}, 0.0f64, 0.0f64}, False{}, False{},
    False{}, 0n, 0n, 0n, [], [], 0n, 0n}

def walls_lo(+lo: F64, +plo: F64) -> List<&2, Wl>:
  Bool.pick(List<&2, Wl>, F64.is_lt(lo, plo), [Wl{lo, plo, True{}}],
    Bool.pick(List<&2, Wl>, F64.is_lt(plo, lo), [Wl{plo, lo, False{}}], []))

def walls_hi(+hi: F64, +phi: F64) -> List<&2, Wl>:
  Bool.pick(List<&2, Wl>, F64.is_lt(phi, hi), [Wl{phi, hi, True{}}],
    Bool.pick(List<&2, Wl>, F64.is_lt(hi, phi), [Wl{hi, phi, False{}}], []))

def walls_of(mat: Bool, +pm: Bool, +lo: F64, +hi: F64, +plo: F64, +phi: F64) -> List<&2, Wl>:
  match mat:
    case False{}: Bool.pick(List<&2, Wl>, pm, [Wl{plo, phi, False{}}], [])
    case True{}:
      Bool.pick(List<&2, Wl>, pm, List.append(&2, Wl, walls_lo(lo, plo), walls_hi(hi, phi)),
        [Wl{lo, hi, True{}}])

def hs_of(ws: List<&2, Wl>) -> List<&2, F64>:
  match ws:
    case []: []
    case w <> t:
      Wl{lo, hi, ins} = w
      lo <> hi <> hs_of(t)

def lp_nvl(l: F.Lp) -> Nat:
  match l:
    case F.K_path{sgs}: F.sgs_npc(sgs)
    case F.K_circ{cx, cy, r}: 1n

def lp_nsg(l: F.Lp) -> Nat:
  match l:
    case F.K_path{sgs}: List.length(&2, F.Sg, sgs)
    case F.K_circ{cx, cy, r}: 0n

def cd_mk(+c: Cl, +pd: Cd, +has: Bool, +vb: Nat, +eb: Nat) -> Cd:
  +pc = cd_c(pd)
  +pm = Bool.and(has, cl_mat(pc))
  +mat = cl_mat(c)
  +ttr = Bool.and(pm, Bool.and(mat, F64.is_eq(cl_hi(c), cl_hi(pc))))
  +btr = Bool.and(pm, Bool.and(mat, F64.is_eq(cl_lo(c), cl_lo(pc))))
  +id = cl_id(c)
  +ws = walls_of(mat, pm, cl_lo(c), cl_hi(c), cl_lo(pc), cl_hi(pc))
  Cd{c, pm, ttr, btr, Bool.pick(Nat, ttr, cd_tow(pd), id), Bool.pick(Nat, btr, cd_bow(pd), id),
    Bool.pick(Nat, Bool.and(mat, Bool.not(pm)), id, cd_sol(pd)), ws, hs_of(ws), vb, eb}

def cd_nv(+d: Cd) -> Nat:
  Nat.mul(List.length(&2, F64, cd_hs(d)), lp_nvl(cl_lp(cd_c(d))))

def cd_ne(+d: Cd) -> Nat:
  +l = cl_lp(cd_c(d))
  Nat.add(Nat.mul(List.length(&2, F64, cd_hs(d)), lp_nvl(l)), Nat.mul(List.length(&2, Wl, cd_ws(d)), lp_nsg(l)))

def cd_go(cs: List<&2, Cl>, +tb: B.Tb<&2, Cd>, +vb: Nat, +eb: Nat) -> List<&2, Cd>:
  match cs:
    case []: []
    case +c <> t:
      +p = cl_par(c)
      +has = Bool.not(Nat.is_eq(p, 0n))
      +pd = B.tb_get(Cd, tb, U32.from_nat(Nat.sub(p, 1n)))
      +d = cd_mk(c, pd, has, vb, eb)
      d <> cd_go(t, B.tb_set(Cd, tb, U32.from_nat(cl_id(c)), d), Nat.add(vb, cd_nv(d)), Nat.add(eb, cd_ne(d)))

def cd_pads(n: Nat) -> List<&2, Cd>:
  match n:
    case 0n: [cd_pad()]
    case 1n+m: cd_pad() <> cd_pads(m)

def cds_of(+cs: List<&2, Cl>) -> List<&2, Cd>:
  cd_go(cs, B.tb_of(Cd, cd_pads(List.length(&2, Cl, cs)), cd_pad()), 0n, 0n)

def nat_f(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))

def hidx(hs: List<&2, F64>, +z: F64, +i: Nat) -> Nat:
  match hs:
    case []: i
    case h <> t: Bool.pick(Nat, F64.is_eq(h, z), i, hidx(t, z, Nat.add(i, 1n)))

def lv_pts(l: F.Lp) -> List<&2, V.Vec2>:
  match l:
    case F.K_path{sgs}: F.pcs_starts(F.sgs_pcs(sgs))
    case F.K_circ{cx, cy, r}: [V.V2{F64.sub(cx, r), cy}]

def vx_row(ps: List<&2, V.Vec2>, +z: F64, +g: Nat) -> List<&2, Ty.Vertex>:
  match ps:
    case []: []
    case p <> t:
      V.V2{x, y} = p
      Ty.Vx{U64.from_nat(Nat.add(g, 1n)), V.Pt{x, y, z}} <> vx_row(t, z, Nat.add(g, 1n))

def vx_rows(hs: List<&2, F64>, +ps: List<&2, V.Vec2>, +g: Nat) -> List<&2, Ty.Vertex>:
  match hs:
    case []: []
    case z <> t:
      List.append(&2, Ty.Vertex, vx_row(ps, z, g),
        vx_rows(t, ps, Nat.add(g, List.length(&2, V.Vec2, ps))))

def cds_vs(ds: List<&2, Cd>) -> List<&2, Ty.Vertex>:
  match ds:
    case []: []
    case +d <> t:
      List.append(&2, Ty.Vertex, vx_rows(cd_hs(d), lv_pts(cl_lp(cd_c(d))), cd_vb(d)), cds_vs(t))

def hv(+i: Nat) -> Ty.HVertex:
  Ty.HV{i, U64.from_nat(Nat.add(i, 1n))}

def he(+i: Nat) -> Ty.HEdge:
  Ty.HE{i, U64.from_nat(Nat.add(i, 1n))}

def pc_rev_store(p: F.Pc) -> Bool:
  match p:
    case F.P_ln{+ax, +ay, +bx, +by}:
      Bool.pick(Bool, F64.is_eq(ay, by), F64.is_lt(bx, ax),
        Bool.pick(Bool, F64.is_eq(ax, bx), F64.is_lt(by, ay), False{}))
    case F.P_ar{ax, ay, px, py, w, bx, by}: False{}

def pc_kind(p: F.Pc, +z: F64) -> Ty.EdgeKind:
  match p:
    case F.P_ln{+ax, +ay, +bx, +by}:
      Bool.pick(Ty.EdgeKind, F64.is_eq(ay, by),
        Ty.EK_curve{G.GV_ln{G.Ln{V.Pt{0.0f64, ay, z}, V.Dr{1.0f64, 0.0f64, 0.0f64}}},
          G.Dom{F64.min(ax, bx), F64.max(ax, bx)}},
        Bool.pick(Ty.EdgeKind, F64.is_eq(ax, bx),
          Ty.EK_curve{G.GV_ln{G.Ln{V.Pt{ax, 0.0f64, z}, V.Dr{0.0f64, 1.0f64, 0.0f64}}},
            G.Dom{F64.min(ay, by), F64.max(ay, by)}},
          Ty.EK_curve{G.GV_bz{G.Bz{V.Pt{ax, ay, z}, V.Pt{ax, ay, z}, V.Pt{bx, by, z}, V.Pt{bx, by, z}}},
            G.Dom{0.0f64, 1.0f64}}))
    case F.P_ar{ax, ay, px, py, w, bx, by}:
      Ty.EK_curve{G.GV_rq{G.Rq{V.Pt{ax, ay, z}, V.Pt{px, py, z}, V.Pt{bx, by, z}, 1.0f64, w, 1.0f64}},
        G.Dom{0.0f64, 1.0f64}}

def nxt(+i: Nat, +n: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_eq(Nat.add(i, 1n), n), 0n, Nat.add(i, 1n))

def ed_pc(+p: F.Pc, +z: F64, +va: Nat, +vb: Nat) -> Ty.Edge:
  +r = pc_rev_store(p)
  Ty.Ed{0u64, hv(Bool.pick(Nat, r, vb, va)), hv(Bool.pick(Nat, r, va, vb)), pc_kind(p, z)}

def ed_row(ps: List<&2, F.Pc>, +z: F64, +vbase: Nat, +i: Nat, +n: Nat) -> List<&2, Ty.Edge>:
  match ps:
    case []: []
    case p <> t: ed_pc(p, z, Nat.add(vbase, i), Nat.add(vbase, nxt(i, n))) <> ed_row(t, z, vbase, Nat.add(i, 1n), n)

def ed_circ(+cx: F64, +cy: F64, +r: F64, +z: F64, +v: Nat) -> Ty.Edge:
  Ty.Ed{0u64, hv(v), hv(v), Ty.EK_curve{G.GV_cc{G.Cc{V.Pt{cx, cy, z}, V.Dr{1.0f64, 0.0f64, 0.0f64},
    V.Dr{0.0f64, 1.0f64, 0.0f64}, r}}, G.Dom{F64.neg(1.0f64), 1.0f64}}}

def ed_hrow(l: F.Lp, +z: F64, +vbase: Nat) -> List<&2, Ty.Edge>:
  match l:
    case F.K_path{+sgs}:
      +ps = F.sgs_pcs(sgs)
      ed_row(ps, z, vbase, 0n, List.length(&2, F.Pc, ps))
    case F.K_circ{cx, cy, r}: [ed_circ(cx, cy, r, z, vbase)]

def ed_hrows(hs: List<&2, F64>, +l: F.Lp, +vbase: Nat, +nvl: Nat) -> List<&2, Ty.Edge>:
  match hs:
    case []: []
    case z <> t: List.append(&2, Ty.Edge, ed_hrow(l, z, vbase), ed_hrows(t, l, Nat.add(vbase, nvl), nvl))

def sg_starts(sgs: List<&2, F.Sg>, +i: Nat) -> List<&2, Nat>:
  match sgs:
    case []: []
    case +s <> t: i <> sg_starts(t, Nat.add(i, F.sg_npc(s)))

def lp_juncs(l: F.Lp) -> List<&2, Nat>:
  match l:
    case F.K_path{sgs}: sg_starts(sgs, 0n)
    case F.K_circ{cx, cy, r}: []

def pt_at(+pts: B.Tb<&2, V.Vec2>, +i: Nat) -> V.Vec2:
  B.tb_get(V.Vec2, pts, U32.from_nat(i))

def ed_vert(+q: V.Vec2, +z1: F64, +z2: F64, +v1: Nat, +v2: Nat) -> Ty.Edge:
  Ty.Ed{0u64, hv(v1), hv(v2), Ty.EK_curve{G.GV_ln{G.Ln{V.Pt{V.v2_x(q), V.v2_y(q), 0.0f64},
    V.Dr{0.0f64, 0.0f64, 1.0f64}}}, G.Dom{z1, z2}}}

def ed_vrow(js: List<&2, Nat>, +pts: B.Tb<&2, V.Vec2>, +z1: F64, +z2: F64, +b1: Nat, +b2: Nat) -> List<&2, Ty.Edge>:
  match js:
    case []: []
    case +j <> t:
      ed_vert(pt_at(pts, j), z1, z2, Nat.add(b1, j), Nat.add(b2, j)) <> ed_vrow(t, pts, z1, z2, b1, b2)

def ed_vrows(ws: List<&2, Wl>, +js: List<&2, Nat>, +pts: B.Tb<&2, V.Vec2>, +hs: List<&2, F64>, +vb: Nat,
    +nvl: Nat) -> List<&2, Ty.Edge>:
  match ws:
    case []: []
    case w <> t:
      Wl{+lo, +hi, ins} = w
      List.append(&2, Ty.Edge,
        ed_vrow(js, pts, lo, hi, Nat.add(vb, Nat.mul(hidx(hs, lo, 0n), nvl)),
          Nat.add(vb, Nat.mul(hidx(hs, hi, 0n), nvl))),
        ed_vrows(t, js, pts, hs, vb, nvl))

def v2_pad() -> V.Vec2:
  V.V2{0.0f64, 0.0f64}

def cd_es(+d: Cd) -> List<&2, Ty.Edge>:
  +l = cl_lp(cd_c(d))
  +hs = cd_hs(d)
  +nvl = lp_nvl(l)
  +pts = B.tb_of(V.Vec2, lv_pts(l), v2_pad())
  List.append(&2, Ty.Edge, ed_hrows(hs, l, cd_vb(d), nvl),
    ed_vrows(cd_ws(d), lp_juncs(l), pts, hs, cd_vb(d), nvl))

def cds_es(ds: List<&2, Cd>) -> List<&2, Ty.Edge>:
  match ds:
    case []: []
    case +d <> t: List.append(&2, Ty.Edge, cd_es(d), cds_es(t))

def ed_gen(es: List<&2, Ty.Edge>, +i: Nat) -> List<&2, Ty.Edge>:
  match es:
    case []: []
    case e <> t:
      Ty.Ed{g, v0, v1, k} = e
      Ty.Ed{U64.from_nat(Nat.add(i, 1n)), v0, v1, k} <> ed_gen(t, Nat.add(i, 1n))

def si_ln(p: F.Pc, +p0: Nat) -> SI:
  match p:
    case F.P_ln{+ax, +ay, +bx, +by}:
      SI{Bool.pick(U64, F64.is_eq(ay, by), 0u64, Bool.pick(U64, F64.is_eq(ax, bx), 1u64, 2u64)),
        p0, 1n, True{}, 0.0f64, 0.0f64, 0.0f64, ax, ay, bx, by}
    case F.P_ar{ax, ay, px, py, w, bx, by}:
      SI{2u64, p0, 1n, True{}, 0.0f64, 0.0f64, 0.0f64, ax, ay, bx, by}

def si_of(s: F.Sg, +p0: Nat) -> SI:
  match s:
    case F.G_ln{p}: si_ln(p, p0)
    case F.G_ar{cx, cy, r, ccw, +ps}:
      +h = F.pc_hd(ps)
      +l = F.pc_hd(F.pcs_rev(ps, []))
      SI{3u64, p0, List.length(&2, F.Pc, ps), ccw, cx, cy, r, F.pc_ax(h), F.pc_ay(h), F.pc_bx(l), F.pc_by(l)}

def sis_go(sgs: List<&2, F.Sg>, +p0: Nat) -> List<&2, SI>:
  match sgs:
    case []: []
    case +s <> t: si_of(s, p0) <> sis_go(t, Nat.add(p0, F.sg_npc(s)))

def lp_sis(l: F.Lp) -> List<&2, SI>:
  match l:
    case F.K_path{sgs}: sis_go(sgs, 0n)
    case F.K_circ{+cx, +cy, +r}:
      [SI{4u64, 0n, 1n, True{}, cx, cy, r, F64.sub(cx, r), cy, F64.sub(cx, r), cy}]

def uv_pt(+kind: U64, +q: Nat, +x: F64, +y: F64, +z: F64, +z1: F64) -> V.Vec2:
  match kind:
    case 0u64: V.V2{x, z}
    case 1u64: V.V2{y, z}
    case 2u64: V.V2{nat_f(q), Bool.pick(F64, F64.is_eq(z, z1), 0.0f64, 1.0f64)}
    case 3u64: V.V2{nat_f(q), z}
    case _: V.V2{0.0f64, z}

def us_h(+e: Nat, +p: F.Pc, +along: Bool, +ua: V.Vec2, +ub: V.Vec2) -> Use:
  +r = pc_rev_store(p)
  Us{e, Bool.xor(along, r), Bool.pick(V.Vec2, r, ub, ua), Bool.pick(V.Vec2, r, ua, ub)}

def row_uses(ps: List<&2, F.Pc>, +kind: U64, +q: Nat, +z: F64, +z1: F64, +ebase: Nat,
    +along: Bool) -> List<&2, Use>:
  match ps:
    case []: []
    case +p <> t:
      us_h(Nat.add(ebase, q), p, along, uv_pt(kind, q, F.pc_ax(p), F.pc_ay(p), z, z1),
        uv_pt(kind, Nat.add(q, 1n), F.pc_bx(p), F.pc_by(p), z, z1)) <> row_uses(t, kind, Nat.add(q, 1n), z, z1, ebase, along)

def us_rev(xs: List<&2, Use>, +acc: List<&2, Use>) -> List<&2, Use>:
  match xs:
    case []: acc
    case x <> t: us_rev(t, x <> acc)

def take_pcs(ps: List<&2, F.Pc>, +n: Nat) -> List<&2, F.Pc>:
  match ps:
    case []: []
    case p <> t:
      match n:
        case 0n: []
        case 1n+m: p <> take_pcs(t, m)

def drop_pcs(ps: List<&2, F.Pc>, +n: Nat) -> List<&2, F.Pc>:
  match ps:
    case []: []
    case p <> +t:
      match n:
        case 0n: p <> t
        case 1n+m: drop_pcs(t, m)

def surf_k(+kind: U64, +cx: F64, +cy: F64, +r: F64, +ax: F64, +ay: F64, +bx: F64, +by: F64, +z1: F64,
    +z2: F64) -> G.GVal:
  match kind:
    case 0u64: G.GV_pl{G.Pl{V.Pt{0.0f64, ay, 0.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}}}
    case 1u64: G.GV_pl{G.Pl{V.Pt{ax, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}}}
    case 2u64:
      +a1 = {V.Pt{ax, ay, z1} : V.Point}
      +b1 = {V.Pt{bx, by, z1} : V.Point}
      +a2 = {V.Pt{ax, ay, z2} : V.Point}
      +b2 = {V.Pt{bx, by, z2} : V.Point}
      G.GV_bp{G.Bp{a1, a1, b1, b1, a1, a1, b1, b1, a2, a2, b2, b2, a2, a2, b2, b2}}
    case _: G.GV_cy{G.Cy{V.Pt{cx, cy, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}, r}}

def surf_of(s: SI, +z1: F64, +z2: F64) -> G.GVal:
  SI{kind, p0, n, ccw, cx, cy, r, ax, ay, bx, by} = s
  surf_k(kind, cx, cy, r, ax, ay, bx, by, z1, z2)

def same_k(+kind: U64, +ins: Bool, +ccw: Bool, +ax: F64, +ay: F64, +bx: F64, +by: F64) -> Bool:
  match kind:
    case 0u64: Bool.not(Bool.xor(ins, F64.is_lt(ax, bx)))
    case 1u64: Bool.not(Bool.xor(ins, F64.is_lt(ay, by)))
    case 3u64: Bool.not(Bool.xor(ins, ccw))
    case _: ins

def same_of(s: SI, +ins: Bool) -> Bool:
  SI{kind, p0, n, ccw, cx, cy, r, ax, ay, bx, by} = s
  same_k(kind, ins, ccw, ax, ay, bx, by)

def si_kind(s: SI) -> U64:
  SI{kind, p0, n, ccw, cx, cy, r, ax, ay, bx, by} = s
  kind

def si_p0(s: SI) -> Nat:
  SI{kind, p0, n, ccw, cx, cy, r, ax, ay, bx, by} = s
  p0

def si_n(s: SI) -> Nat:
  SI{kind, p0, n, ccw, cx, cy, r, ax, ay, bx, by} = s
  n

def si_a(s: SI) -> V.Vec2:
  SI{kind, p0, n, ccw, cx, cy, r, ax, ay, bx, by} = s
  V.V2{ax, ay}

def si_b(s: SI) -> V.Vec2:
  SI{kind, p0, n, ccw, cx, cy, r, ax, ay, bx, by} = s
  V.V2{bx, by}

def us_v(+e: Nat, +up: Bool, +u1: V.Vec2, +u2: V.Vec2) -> Use:
  Us{e, up, u1, u2}

def wall_lps(+s: SI, +ps: List<&2, F.Pc>, +ins: Bool, +z1: F64, +z2: F64, +eb1: Nat, +eb2: Nat,
    +evs: Nat, +eve: Nat) -> List<&2, List<&2, Use>>:
  +k = si_kind(s)
  +n = si_n(s)
  +a = si_a(s)
  +b = si_b(s)
  +bot = row_uses(ps, k, 0n, z1, z1, eb1, ins)
  +top = row_uses(ps, k, 0n, z2, z1, eb2, Bool.not(ins))
  +vs = us_v(evs, Bool.not(ins), uv_pt(k, 0n, V.v2_x(a), V.v2_y(a), z1, z1), uv_pt(k, 0n, V.v2_x(a), V.v2_y(a), z2, z1))
  +ve = us_v(eve, ins, uv_pt(k, n, V.v2_x(b), V.v2_y(b), z1, z1), uv_pt(k, n, V.v2_x(b), V.v2_y(b), z2, z1))
  Bool.pick(List<&2, List<&2, Use>>, U64.is_eq(k, 4u64),
    Bool.pick(List<&2, List<&2, Use>>, ins, [bot, top], [top, bot]),
    [Bool.pick(List<&2, Use>, ins,
      List.append(&2, Use, bot, ve <> us_rev(top, [vs])),
      vs <> List.append(&2, Use, top, ve <> us_rev(bot, [])))])

def wl_lo(w: Wl) -> F64:
  Wl{lo, hi, ins} = w
  lo

def wl_hi(w: Wl) -> F64:
  Wl{lo, hi, ins} = w
  hi

def wl_ins(w: Wl) -> Bool:
  Wl{lo, hi, ins} = w
  ins

def wall_fs(sis: List<&2, SI>, +ps: List<&2, F.Pc>, +w: Wl, +wi: Nat, +si: Nat, +nsg: Nat, +d: Cd,
    +nvl: Nat) -> List<&2, FS>:
  match sis:
    case []: []
    case +s <> t:
      +z1 = wl_lo(w)
      +z2 = wl_hi(w)
      +ins = wl_ins(w)
      +hs = cd_hs(d)
      +eb = cd_eb(d)
      +c = cd_c(d)
      +p0 = si_p0(s)
      +n = si_n(s)
      +evb = Nat.add(eb, Nat.add(Nat.mul(List.length(&2, F64, hs), nvl), Nat.mul(wi, nsg)))
      +eb1 = Nat.add(eb, Nat.add(Nat.mul(hidx(hs, z1, 0n), nvl), p0))
      +eb2 = Nat.add(eb, Nat.add(Nat.mul(hidx(hs, z2, 0n), nvl), p0))
      FS{cd_sol(d), surf_of(s, z1, z2), same_of(s, ins),
        wall_lps(s, take_pcs(drop_pcs(ps, p0), n), ins, z1, z2, eb1, eb2, Nat.add(evb, si),
          Nat.add(evb, nxt(si, nsg))), Fn{cl_nd(c), cl_k(c), 2u64, si, wi}} <> wall_fs(t, ps, w, wi, Nat.add(si, 1n), nsg, d, nvl)

def lp_pcs1(l: F.Lp) -> List<&2, F.Pc>:
  match l:
    case F.K_path{sgs}: F.sgs_pcs(sgs)
    case F.K_circ{+cx, +cy, +r}: [F.P_ar{F64.sub(cx, r), cy, cx, cy, 1.0f64, F64.sub(cx, r), cy}]

def walls_fs(ws: List<&2, Wl>, +wi: Nat, +d: Cd) -> List<&2, FS>:
  match ws:
    case []: []
    case +w <> t:
      +l = cl_lp(cd_c(d))
      List.append(&2, FS, wall_fs(lp_sis(l), lp_pcs1(l), w, wi, 0n, Nat.max(lp_nsg(l), 1n), d, lp_nvl(l)),
        walls_fs(t, Nat.add(wi, 1n), d))

def hz_uses(ps: List<&2, F.Pc>, +ebase: Nat, +q: Nat, +along: Bool) -> List<&2, Use>:
  match ps:
    case []: []
    case +p <> t:
      us_h(Nat.add(ebase, q), p, along, V.V2{F.pc_ax(p), F.pc_ay(p)}, V.V2{F.pc_bx(p), F.pc_by(p)}) <> hz_uses(t, ebase, Nat.add(q, 1n), along)

def lp_ring(+d: Cd, +z: F64, +along: Bool) -> List<&2, Use>:
  +l = cl_lp(cd_c(d))
  +hs = cd_hs(d)
  +us = hz_uses(lp_pcs1(l), Nat.add(cd_eb(d), Nat.mul(hidx(hs, z, 0n), lp_nvl(l))), 0n, along)
  Bool.pick(List<&2, Use>, along, us, us_rev(us, []))

def od_o(x: OD) -> Nat:
  OD{o, d} = x
  o

def od_d(x: OD) -> Nat:
  OD{o, d} = x
  d

def od_cmp_go(+a: OD, +b: OD) -> B.Sgn:
  +s = B.sgn_pick(Nat.is_lt(od_o(a), od_o(b)), Nat.is_lt(od_o(b), od_o(a)))
  Bool.pick(B.Sgn, F.sgn_zero(s), B.sgn_pick(Nat.is_lt(od_d(a), od_d(b)), Nat.is_lt(od_d(b), od_d(a))), s)

def od_cmp(a: OD, b: OD) -> B.Sgn:
  od_cmp_go(a, b)

def so_od(s: B.So<&2, OD>) -> List<&2, OD>:
  B.So{ok, xs} = s
  xs

def ods_of(ds: List<&2, Cd>, +tb: B.Tb<&2, Cd>, +top: Bool) -> List<&2, OD>:
  match ds:
    case []: []
    case +d <> t:
      +c = cd_c(d)
      +p = cl_par(c)
      +pd = B.tb_get(Cd, tb, U32.from_nat(Nat.sub(p, 1n)))
      +tr = Bool.pick(Bool, top, cd_ttr(d), cd_btr(d))
      +ok = Bool.and(Bool.not(Nat.is_eq(p, 0n)), Bool.and(cl_mat(cd_c(pd)), Bool.not(tr)))
      +o = Bool.pick(Nat, top, cd_tow(pd), cd_bow(pd))
      +rest = ods_of(t, tb, top)
      Bool.pick(List<&2, OD>, ok, OD{o, cl_id(c)} <> rest, rest)

def od_peek(xs: List<&2, OD>, +o: Nat) -> Bool:
  match xs:
    case []: False{}
    case x <> t: Nat.is_eq(od_o(x), o)

def inner_take(xs: List<&2, OD>, +o: Nat, +tb: B.Tb<&2, Cd>, +z: F64, +along: Bool, go: Bool) -> List<&2, List<&2, Use>>:
  match xs go:
    case _ False{}: []
    case Nil{} True{}: []
    case Con{+x, +t} True{}:
      lp_ring(B.tb_get(Cd, tb, U32.from_nat(od_d(x))), z, along) <> inner_take(t, o, tb, z, along, od_peek(t, o))

def od_le(xs: List<&2, OD>, +o: Nat) -> Bool:
  match xs:
    case []: False{}
    case x <> t: Nat.is_le(od_o(x), o)

def inner_drop(+xs: List<&2, OD>, +o: Nat, go: Bool) -> List<&2, OD>:
  match xs go:
    case _ False{}: xs
    case Nil{} True{}: []
    case Con{x, +t} True{}: inner_drop(t, o, od_le(t, o))

def hplane(+z: F64) -> G.GVal:
  G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, z}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}}

def hz_top_go(ok: Bool, +d: Cd, +tb: B.Tb<&2, Cd>, +tops: List<&2, OD>) -> List<&2, FS>:
  match ok:
    case False{}: []
    case True{}:
      +c = cd_c(d)
      +hi = cl_hi(c)
      [FS{cd_sol(d), hplane(hi), True{}, lp_ring(d, hi, True{}) <> inner_take(tops, cl_id(c), tb, hi, False{}, od_peek(tops, cl_id(c))),
        Fn{cl_nd(c), cl_k(c), 0u64, 0n, 0n}}]

def hz_top(+d: Cd, +tb: B.Tb<&2, Cd>, +tops: List<&2, OD>) -> List<&2, FS>:
  hz_top_go(Bool.and(cl_mat(cd_c(d)), Bool.not(cd_ttr(d))), d, tb, tops)

def hz_bot_go(ok: Bool, +d: Cd, +tb: B.Tb<&2, Cd>, +bots: List<&2, OD>) -> List<&2, FS>:
  match ok:
    case False{}: []
    case True{}:
      +c = cd_c(d)
      +lo = cl_lo(c)
      [FS{cd_sol(d), hplane(lo), False{}, lp_ring(d, lo, False{}) <> inner_take(bots, cl_id(c), tb, lo, True{}, od_peek(bots, cl_id(c))),
        Fn{cl_nd(c), cl_k(c), 1u64, 0n, 0n}}]

def hz_bot(+d: Cd, +tb: B.Tb<&2, Cd>, +bots: List<&2, OD>) -> List<&2, FS>:
  hz_bot_go(Bool.and(cl_mat(cd_c(d)), Bool.not(cd_btr(d))), d, tb, bots)

def hz_fs(ds: List<&2, Cd>, +tb: B.Tb<&2, Cd>, +tops: List<&2, OD>, +bots: List<&2, OD>) -> List<&2, FS>:
  match ds:
    case []: []
    case +d <> t:
      +id = cl_id(cd_c(d))
      List.append(&2, FS, hz_top(d, tb, tops), List.append(&2, FS, hz_bot(d, tb, bots),
        hz_fs(t, tb, inner_drop(tops, id, od_le(tops, id)), inner_drop(bots, id, od_le(bots, id)))))

def cds_walls(ds: List<&2, Cd>) -> List<&2, FS>:
  match ds:
    case []: []
    case +d <> t: List.append(&2, FS, walls_fs(cd_ws(d), 0n, d), cds_walls(t))

def fs_sol(f: FS) -> Nat:
  FS{sol, surf, same, lps, nm} = f
  sol

def fs_cmp_go(+a: FS, +b: FS) -> B.Sgn:
  B.sgn_pick(Nat.is_lt(fs_sol(a), fs_sol(b)), Nat.is_lt(fs_sol(b), fs_sol(a)))

def fs_cmp(a: FS, b: FS) -> B.Sgn:
  fs_cmp_go(a, b)

def so_fs(s: B.So<&2, FS>) -> List<&2, FS>:
  B.So{ok, xs} = s
  xs

def us_ces(us: List<&2, Use>, +i: Nat) -> List<&2, Ty.Coedge>:
  match us:
    case []: []
    case u <> t:
      Us{e, fwd, ta, tb} = u
      Ty.Ce{U64.from_nat(Nat.add(i, 1n)), he(e), fwd, G.GV_ts{G.Ts{ta, tb}}} <> us_ces(t, Nat.add(i, 1n))

def hcs_n(n: Nat, +i: Nat) -> List<&2, Ty.HCoedge>:
  match n:
    case 0n: []
    case 1n+m: Ty.HC{i, U64.from_nat(Nat.add(i, 1n))} <> hcs_n(m, Nat.add(i, 1n))

def st_nlp(s: St) -> Nat:
  St{nce, nlp, ces, lps, fas} = s
  nlp

def lps_emit(ls: List<&2, List<&2, Use>>, +st: St, +first: Bool) -> St:
  match ls:
    case []: st
    case +us <> t:
      St{+nce, +nlp, +ces, +lps, +fas} = st
      +m = List.length(&2, Use, us)
      +lp = {Ty.Lp{U64.from_nat(Nat.add(nlp, 1n)), hcs_n(m, nce), Bool.pick(Ty.LoopKind, first, Ty.LK_outer{}, Ty.LK_inner{})} : Ty.Loop}
      lps_emit(t, St{Nat.add(nce, m), Nat.add(nlp, 1n), List.append(&2, Ty.Coedge, List.reverse(&2, Ty.Coedge, us_ces(us, nce)), ces),
        lp <> lps, fas}, False{})

def hls_n(n: Nat, +i: Nat) -> List<&2, Ty.HLoop>:
  match n:
    case 0n: []
    case 1n+m: Ty.HL{i, U64.from_nat(Nat.add(i, 1n))} <> hls_n(m, Nat.add(i, 1n))

def st_add_fa(s: St, +f: Ty.Face) -> St:
  St{nce, nlp, ces, lps, fas} = s
  St{nce, nlp, ces, lps, f <> fas}

def fs_emit(fs: List<&2, FS>, +st: St, +fi: Nat) -> St:
  match fs:
    case []: st
    case f <> t:
      FS{sol, surf, same, +lps, nm} = f
      +l0 = st_nlp(st)
      +st2 = lps_emit(lps, st, True{})
      fs_emit(t, st_add_fa(st2, Ty.Fa{U64.from_nat(Nat.add(fi, 1n)), surf, hls_n(List.length(&2, List<&2, Use>, lps), l0), same}),
        Nat.add(fi, 1n))

def hf_rev(xs: List<&2, Ty.HFace>) -> List<&2, Ty.HFace>:
  List.reverse(&2, Ty.HFace, xs)

def sol_runs(fs: List<&2, FS>, +i: Nat, +cur: Nat, +acc: List<&2, Ty.HFace>) -> List<&2, List<&2, Ty.HFace>>:
  match fs:
    case []: Bool.pick(List<&2, List<&2, Ty.HFace>>, Nat.is_eq(List.length(&2, Ty.HFace, acc), 0n), [], [hf_rev(acc)])
    case +f <> t:
      +s = fs_sol(f)
      +h = {Ty.HF{i, U64.from_nat(Nat.add(i, 1n))} : Ty.HFace}
      +same = Bool.or(Nat.is_eq(s, cur), Nat.is_eq(List.length(&2, Ty.HFace, acc), 0n))
      List.append(&2, List<&2, Ty.HFace>, Bool.pick(List<&2, List<&2, Ty.HFace>>, same, [], [hf_rev(acc)]),
        sol_runs(t, Nat.add(i, 1n), s, Bool.pick(List<&2, Ty.HFace>, same, h <> acc, [h])))

def shs_of(rs: List<&2, List<&2, Ty.HFace>>, +i: Nat) -> List<&2, Ty.Shell>:
  match rs:
    case []: []
    case r <> t: Ty.Sh{U64.from_nat(Nat.add(i, 1n)), r, Ty.SK_outer{}} <> shs_of(t, Nat.add(i, 1n))

def sos_of(n: Nat, +i: Nat) -> List<&2, Ty.Solid>:
  match n:
    case 0n: []
    case 1n+m: Ty.So{U64.from_nat(Nat.add(i, 1n)), Ty.HS{i, U64.from_nat(Nat.add(i, 1n))}, []} <> sos_of(m, Nat.add(i, 1n))

def hsos_of(n: Nat, +i: Nat) -> List<&2, Ty.HSolid>:
  match n:
    case 0n: []
    case 1n+m: Ty.HSo{i, U64.from_nat(Nat.add(i, 1n))} <> hsos_of(m, Nat.add(i, 1n))

def fs_names(fs: List<&2, FS>) -> List<&2, Fn>:
  match fs:
    case []: []
    case f <> t:
      FS{sol, surf, same, lps, nm} = f
      nm <> fs_names(t)

def st_br(st: St, +vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +shs: List<&2, Ty.Shell>,
    +sos: List<&2, Ty.Solid>, +top: Ty.Compound) -> Ty.Brep:
  St{nce, nlp, ces, lps, +fas} = st
  +n = Nat.add(List.length(&2, Ty.Vertex, vs), Nat.add(List.length(&2, Ty.Edge, es),
    Nat.add(nce, Nat.add(nlp, Nat.add(List.length(&2, Ty.Face, fas), List.length(&2, Ty.Shell, shs))))))
  Ty.Br{vs, es, List.reverse(&2, Ty.Coedge, ces), List.reverse(&2, Ty.Loop, lps), List.reverse(&2, Ty.Face, fas),
    shs, sos, top, U64.from_nat(Nat.add(n, 1n))}

def build(+cs: List<&2, Cl>) -> Bt:
  +ds = cds_of(cs)
  +tb = B.tb_of(Cd, ds, cd_pad())
  +tops = so_od(B.msort(~OD, ~od_cmp, ods_of(ds, tb, True{})))
  +bots = so_od(B.msort(~OD, ~od_cmp, ods_of(ds, tb, False{})))
  +fs = so_fs(B.msort(~FS, ~fs_cmp, List.append(&2, FS, hz_fs(ds, tb, tops, bots), cds_walls(ds))))
  +st = fs_emit(fs, St{0n, 0n, [], [], []}, 0n)
  +runs = sol_runs(fs, 0n, 0n, [])
  +ns = List.length(&2, List<&2, Ty.HFace>, runs)
  Bt{st_br(st, cds_vs(ds), ed_gen(cds_es(ds), 0n), shs_of(runs, 0n), sos_of(ns, 0n), Ty.Cp{hsos_of(ns, 0n), []}),
    fs_names(fs)}
