import Base
import ../c00/types.bend as T
import ./xp.bend as X
import ./iv.bend as I
import ./model.bend as M
import ./prof.bend as F
import ./build.bend as BD
import ../base/par.bend as B
import ../c07/zt.bend as ZT
import ../c07/sym.bend as Y
import ../c07/zd.bend as D

type ZR is Data:
  Z_ok{ v: I.I, a: I.I }
  Z_err{ why: String }

type ZE is Data:
  ZE{ lo: X.Env, hi: X.Env }

type Sc is Data:
  Sc{ lp: F.Loop, lo: X.Xp, hi: X.Xp }

type Zm is Data:
  Zm{ ok: Bool, v: I.I, a: I.I }

type Dz is Data:
  Dz{ v: D.Dv, a: D.Dv }

def pvs_lo(ps: List<&2, M.Param>) -> List<&2, X.PV>:
  match ps:
    case []: []
    case p <> t:
      M.Pm{id, name, dim} = p
      M.Dm{nom, lo, hi} = dim
      X.PV{id, lo} <> pvs_lo(t)

def pvs_hi(ps: List<&2, M.Param>) -> List<&2, X.PV>:
  match ps:
    case []: []
    case p <> t:
      M.Pm{id, name, dim} = p
      M.Dm{nom, lo, hi} = dim
      X.PV{id, hi} <> pvs_hi(t)

def ze_of(+ps: List<&2, M.Param>) -> ZE:
  ZE{X.env_of(pvs_lo(ps)), X.env_of(pvs_hi(ps))}

def ze_lo(z: ZE) -> X.Env:
  ZE{lo, hi} = z
  lo

def ze_hi(z: ZE) -> X.Env:
  ZE{lo, hi} = z
  hi

def p_iv(+z: ZE, +id: U64) -> I.I:
  I.I{X.env_get(ze_lo(z), id), X.env_get(ze_hi(z), id)}

def xp_iv(x: X.Xp, +z: ZE) -> I.I:
  match x:
    case X.X_k{v}: I.ipt(v)
    case X.X_p{id}: p_iv(z, id)
    case X.X_add{a, b}: I.iadd(xp_iv(a, z), xp_iv(b, z))
    case X.X_sub{a, b}: I.isub(xp_iv(a, z), xp_iv(b, z))
    case X.X_mul{a, b}: I.imul(xp_iv(a, z), xp_iv(b, z))
    case X.X_div{a, b}: I.idiv(xp_iv(a, z), xp_iv(b, z))
    case X.X_neg{a}: I.ineg(xp_iv(a, z))

def pos(+a: I.I) -> Bool:
  Bool.and(F64.is_lt(0.0f64, I.i_lo(a)), Bool.and(F64.is_le(I.i_lo(a), I.i_hi(a)), T.is_finite(I.i_hi(a))))

def kf(+a: F64, +b: F64) -> I.I:
  I.idiv(I.ipt(a), I.ipt(b))

def two_pi() -> I.I:
  I.imul(I.ipt(2.0f64), I.pi_i())

def z_pos(ok: Bool, +v: I.I, +a: I.I) -> ZR:
  match ok:
    case True{}: Z_ok{v, a}
    case False{}: Z_err{"dimension-not-certified-positive-over-zone"}

def z_box(+x: I.I, +y: I.I, +h: I.I) -> ZR:
  +area = I.imul(I.ipt(2.0f64), I.iadd(I.imul(x, y), I.iadd(I.imul(y, h), I.imul(h, x))))
  z_pos(Bool.and(pos(x), Bool.and(pos(y), pos(h))), I.imul(I.imul(x, y), h), area)

def z_cyl(+r: I.I, +h: I.I) -> ZR:
  +area = I.iadd(I.imul(two_pi(), I.isq(r)), I.imul(two_pi(), I.imul(r, h)))
  z_pos(Bool.and(pos(r), pos(h)), I.imul(I.imul(I.pi_i(), I.isq(r)), h), area)

def z_cone(+r: I.I, +h: I.I) -> ZR:
  +area = I.iadd(I.imul(I.pi_i(), I.isq(r)), I.imul(I.imul(I.pi_i(), r), I.isqrt(I.iadd(I.isq(r), I.isq(h)))))
  z_pos(Bool.and(pos(r), pos(h)), I.imul(I.imul(I.imul(I.pi_i(), I.isq(r)), h), kf(1.0f64, 3.0f64)), area)

def z_sph(+r: I.I) -> ZR:
  +area = I.imul(I.imul(I.ipt(4.0f64), I.pi_i()), I.isq(r))
  z_pos(pos(r), I.imul(I.imul(kf(4.0f64, 3.0f64), I.pi_i()), I.imul(I.isq(r), r)), area)

def z_tor(+bigr: I.I, +r: I.I) -> ZR:
  +pp = I.isq(I.pi_i())
  +area = I.imul(I.imul(I.ipt(4.0f64), pp), I.imul(bigr, r))
  z_pos(Bool.and(pos(r), pos(I.isub(bigr, r))), I.imul(I.imul(I.ipt(2.0f64), pp), I.imul(bigr, I.isq(r))), area)

def nd_find(ns: List<&2, M.Node>, +id: U64) -> Maybe<&2, M.Op>:
  match ns:
    case []: None{}
    case x <> t:
      M.Nd{nid, op, it} = x
      Bool.pick(Maybe<&2, M.Op>, U64.is_eq(nid, id), Some{op}, nd_find(t, id))

def z_go(n: Nat, mo: Maybe<&2, M.Op>, +ns: List<&2, M.Node>, +z: ZE) -> ZR:
  match n:
    case 0n: Z_err{"move-chain-too-long"}
    case 1n+(+m):
      match mo:
        case None{}: Z_err{"input-node-missing"}
        case Some{o}:
          match o:
            case M.O_box{x, y, h}: z_box(xp_iv(x, z), xp_iv(y, z), xp_iv(h, z))
            case M.O_cyl{r, h}: z_cyl(xp_iv(r, z), xp_iv(h, z))
            case M.O_cone{r, h}: z_cone(xp_iv(r, z), xp_iv(h, z))
            case M.O_sph{r}: z_sph(xp_iv(r, z))
            case M.O_tor{bigr, r}: z_tor(xp_iv(bigr, z), xp_iv(r, z))
            case M.O_move{base, tx, ty, tz, q}: z_go(m, nd_find(ns, base), ns, z)
            case M.O_rot{base, ax, deg}: z_go(m, nd_find(ns, base), ns, z)
            case _: Z_err{"profile-node"}

def zones_ok(ps: List<&2, M.Param>) -> Bool:
  match ps:
    case []: True{}
    case p <> t:
      M.Pm{id, name, dim} = p
      M.Dm{+nom, +lo, +hi} = dim
      Bool.and(Bool.and(F64.is_le(lo, nom), F64.is_le(nom, hi)), zones_ok(t))

def body_of(r: M.NR) -> Maybe<&2, M.Body>:
  match r:
    case M.NR_err{k, d}: None{}
    case M.NR_ok{b, fx}: Some{b}

def zm_ok(m: Zm) -> Bool:
  Zm{ok, v, a} = m
  Bool.and(ok, Bool.and(pos(v), pos(a)))

def lzs_of(ls: List<&2, F.Loop>, +z: ZT.Zb) -> List<&2, ZT.Lz>:
  match ls:
    case []: []
    case l <> t: ZT.loop_z(l, z) <> lzs_of(t, z)

def rv_ok(ls: List<&2, F.Loop>, rl: List<&2, F.Rl>, +z: ZT.Zb) -> Bool:
  match ls:
    case []: True{}
    case l <> t:
      match rl:
        case []: False{}
        case r <> u: Bool.and(ZT.pms_xok(ZT.lz_ps(ZT.loop_z(l, z)), Bool.not(M.rl_mat(r))), rv_ok(t, u, z))

def dz_add(+a: Dz, +b: Dz) -> Dz:
  Dz{v1, a1} = a
  Dz{v2, a2} = b
  Dz{D.dadd(v1, v2), D.dadd(a1, a2)}

def dz_zero(+n: Nat) -> Dz:
  Dz{D.dk(n, I.ipt(0.0f64)), D.dk(n, I.ipt(0.0f64))}

def rv_go(ls: List<&2, F.Loop>, rl: List<&2, F.Rl>, +z: ZT.Zd) -> Dz:
  match ls:
    case []: dz_zero(ZT.zd_n(z))
    case l <> t:
      match rl:
        case []: dz_zero(ZT.zd_n(z))
        case r <> u:
          +dm = ZT.dloop(l, z)
          +v = ZT.dabs(ZT.dm_rv(dm))
          dz_add(Dz{Bool.pick(D.Dv, M.rl_mat(r), v, D.dneg(v)), ZT.dm_ra(dm)}, rv_go(t, u, z))

def rv_ok_all(+rs: List<&2, F.Region>, +z: ZT.Zb) -> Bool:
  +ls = F.rg_loops(rs)
  Bool.and(rv_ok(ls, F.rg_rls(rs, 0n, F.K_free{}), z), ZT.cert([], lzs_of(ls, z)))

def dz_tp(d: Dz) -> Dz:
  Dz{v, a} = d
  +tp = I.iscale(I.pi_i(), 2.0f64)
  Dz{D.dsc(tp, v), D.dsc(tp, a)}

def rv_dz(+rs: List<&2, F.Region>, +z: ZT.Zd) -> Dz:
  dz_tp(rv_go(F.rg_loops(rs), F.rg_rls(rs, 0n, F.K_free{}), z))

def hl_rgs(hs: List<&2, M.Hl>) -> List<&2, F.Region>:
  match hs:
    case []: []
    case h <> t: M.hl_rg(h) <> hl_rgs(t)

def x_sub(+a: X.Xp, +b: X.Xp) -> X.Xp:
  X.X_sub{a, b}

def ipos(+x: X.Xp, +z: ZT.Zb) -> Bool:
  ZT.pos(ZT.xi(x, z))

def sel_nd(s: M.Sel) -> U64:
  M.Sel{nd, k, side} = s
  nd

def sel_k(s: M.Sel) -> Nat:
  M.Sel{nd, k, side} = s
  k

def sel_side(s: M.Sel) -> U64:
  M.Sel{nd, k, side} = s
  side

def xz() -> X.Xp:
  X.X_k{0.0f64}

def lp_none() -> F.Loop:
  F.L_circ{xz(), xz(), xz()}

def sc_none() -> Sc:
  Sc{lp_none(), xz(), xz()}

def lp_at(ls: List<&2, F.Loop>, +k: Nat) -> F.Loop:
  match ls:
    case []: lp_none()
    case l <> t:
      match k:
        case 0n: l
        case 1n+j: lp_at(t, j)

def rl_at(ls: List<&2, F.Rl>, +k: Nat) -> F.Rl:
  match ls:
    case []: F.K_free{}
    case l <> t:
      match k:
        case 0n: l
        case 1n+j: rl_at(t, j)

def x_add(+a: X.Xp, +b: X.Xp) -> X.Xp:
  X.X_add{a, b}

def ivl_lo(+kind: U64, +side: U64, +lo: X.Xp, +a: X.Xp, +thru: Bool) -> X.Xp:
  Bool.pick(X.Xp, U64.is_eq(kind, 0u64), Bool.pick(X.Xp, U64.is_eq(side, 0u64), lo, x_sub(lo, a)),
    Bool.pick(X.Xp, thru, xz(), Bool.pick(X.Xp, U64.is_eq(side, 0u64), lo, x_add(lo, a))))

def ivl_hi(+kind: U64, +side: U64, +hi: X.Xp, +a: X.Xp, +thru: Bool) -> X.Xp:
  Bool.pick(X.Xp, U64.is_eq(kind, 0u64), Bool.pick(X.Xp, U64.is_eq(side, 0u64), x_add(hi, a), hi),
    Bool.pick(X.Xp, thru, xz(), Bool.pick(X.Xp, U64.is_eq(side, 0u64), x_sub(hi, a), hi)))

def sc_lo(s: Sc) -> X.Xp:
  Sc{lp, lo, hi} = s
  lo

def sc_hi(s: Sc) -> X.Xp:
  Sc{lp, lo, hi} = s
  hi

def sc_feat(+o: Sc, +rs: List<&2, F.Region>, +k: Nat, +kind: U64, +side: U64, +a: X.Xp, +thru: Bool) -> Sc:
  +ins = M.rl_mat(rl_at(F.rg_rls(rs, 0n, F.K_free{}), k))
  +lo = sc_lo(o)
  +hi = sc_hi(o)
  Sc{lp_at(F.rg_loops(rs), k), Bool.pick(X.Xp, ins, ivl_lo(kind, side, lo, a, thru), lo), Bool.pick(X.Xp, ins, ivl_hi(kind, side, hi, a, thru), hi)}

def sc_prism(+rs: List<&2, F.Region>, +k: Nat, +z0: X.Xp, +z1: X.Xp) -> Sc:
  +ins = M.rl_mat(rl_at(F.rg_rls(rs, 0n, F.K_free{}), k))
  Sc{lp_at(F.rg_loops(rs), k), Bool.pick(X.Xp, ins, z0, xz()), Bool.pick(X.Xp, ins, z1, xz())}

def sc_op(n: Nat, mo: Maybe<&2, M.Op>, +ns: List<&2, M.Node>, +k: Nat) -> Sc:
  match n:
    case 0n: sc_none()
    case 1n+(+m):
      match mo:
        case None{}: sc_none()
        case Some{o}:
          match o:
            case M.O_prism{rs, z0, z1}: sc_prism(rs, k, z0, z1)
            case M.O_box{x, y, h}: Sc{lp_at(F.rg_loops([M.rect_rg(x, y)]), 0n), xz(), h}
            case M.O_cyl{r, h}: Sc{lp_at(F.rg_loops([M.circ_rg(r)]), 0n), xz(), h}
            case M.O_pad{base, +f, rs, h}: sc_feat(sc_op(m, nd_find(ns, sel_nd(f)), ns, sel_k(f)), rs, k, 0u64, sel_side(f), h, False{})
            case M.O_pocket{base, +f, rs, d, thru}: sc_feat(sc_op(m, nd_find(ns, sel_nd(f)), ns, sel_k(f)), rs, k, 1u64, sel_side(f), d, thru)
            case M.O_holes{base, +f, hs, d, thru}: sc_feat(sc_op(m, nd_find(ns, sel_nd(f)), ns, sel_k(f)), hl_rgs(hs), k, 2u64, sel_side(f), d, thru)
            case _: sc_none()

def sc_lp(s: Sc) -> F.Loop:
  Sc{lp, lo, hi} = s
  lp

def kid_lzs(cs: List<&2, BD.Cl>, done: Bool, +pid: Nat, +nd: U64, +ns: List<&2, M.Node>, +z: ZT.Zb, +fuel: Nat) -> List<&2, ZT.Lz>:
  match cs:
    case []: []
    case +c <> t:
      match done:
        case True{}: []
        case False{}:
          +stop = U64.is_eq(BD.cl_nd(c), nd)
          +rest = kid_lzs(t, stop, pid, nd, ns, z, fuel)
          Bool.pick(List<&2, ZT.Lz>, Bool.and(Bool.not(stop), Nat.is_eq(BD.cl_par(c), pid)), ZT.loop_z(sc_lp(sc_op(fuel, nd_find(ns, BD.cl_nd(c)), ns, BD.cl_k(c))), z) <> rest, rest)

def cell_id(cs: List<&2, BD.Cl>, +nd: U64, +k: Nat) -> Nat:
  match cs:
    case []: 0n
    case +c <> t: Bool.pick(Nat, Bool.and(U64.is_eq(BD.cl_nd(c), nd), Nat.is_eq(BD.cl_k(c), k)), Nat.add(BD.cl_id(c), 1n), cell_id(t, nd, k))

def feat_ok(+o: Sc, +rs: List<&2, F.Region>, +kind: U64, +side: U64, +a: X.Xp, +thru: Bool, +kids: List<&2, ZT.Lz>, +z: ZT.Zb) -> Bool:
  +lo = sc_lo(o)
  +hi = sc_hi(o)
  +amt = Bool.or(Bool.and(thru, Bool.not(U64.is_eq(kind, 0u64))), ipos(a, z))
  +room = Bool.or(Bool.or(U64.is_eq(kind, 0u64), thru), ipos(x_sub(ivl_hi(kind, side, hi, a, thru), ivl_lo(kind, side, lo, a, thru)), z))
  Bool.and(Bool.and(amt, room), ZT.cert(ZT.loop_z(sc_lp(o), z) <> kids, lzs_of(F.rg_loops(rs), z)))

def feat_node(+m: Nat, +f: M.Sel, +rs: List<&2, F.Region>, +kind: U64, +a: X.Xp, +thru: Bool, +ns: List<&2, M.Node>, +cs: List<&2, BD.Cl>, +nd: U64, +z: ZT.Zb) -> Bool:
  +sn = sel_nd(f)
  +sk = sel_k(f)
  feat_ok(sc_op(m, nd_find(ns, sn), ns, sk), rs, kind, sel_side(f), a, thru, kid_lzs(cs, False{}, cell_id(cs, sn, sk), nd, ns, z, m), z)

def node_ok(n: Nat, mo: Maybe<&2, M.Op>, +ns: List<&2, M.Node>, +cs: List<&2, BD.Cl>, +nd: U64, +z: ZT.Zb) -> Bool:
  match n:
    case 0n: False{}
    case 1n+(+m):
      match mo:
        case None{}: False{}
        case Some{o}:
          match o:
            case M.O_prism{rs, +z0, z1}: Bool.and(ipos(x_sub(z1, z0), z), ZT.cert([], lzs_of(F.rg_loops(rs), z)))
            case M.O_box{x, y, h}: Bool.and(ipos(x, z), Bool.and(ipos(y, z), ipos(h, z)))
            case M.O_cyl{r, h}: Bool.and(ipos(r, z), ipos(h, z))
            case M.O_move{+base, tx, ty, tz, q}: node_ok(m, nd_find(ns, base), ns, cs, base, z)
            case M.O_rot{+base, ax, deg}: node_ok(m, nd_find(ns, base), ns, cs, base, z)
            case M.O_pad{+base, f, rs, h}: Bool.and(feat_node(m, f, rs, 0u64, h, False{}, ns, cs, nd, z), node_ok(m, nd_find(ns, base), ns, cs, base, z))
            case M.O_pocket{+base, f, rs, d, thru}: Bool.and(feat_node(m, f, rs, 1u64, d, thru, ns, cs, nd, z), node_ok(m, nd_find(ns, base), ns, cs, base, z))
            case M.O_holes{+base, f, hs, d, thru}: Bool.and(feat_node(m, f, hl_rgs(hs), 2u64, d, thru, ns, cs, nd, z), node_ok(m, nd_find(ns, base), ns, cs, base, z))
            case _: False{}

def rel_ok(+a: X.Xp, +b: X.Xp, +na: F64, +nb: F64, +z: ZT.Zb) -> Bool:
  Bool.pick(Bool, F64.is_eq(na, nb), Y.same(a, b), Bool.pick(Bool, F64.is_lt(na, nb), ipos(x_sub(b, a), z), ipos(x_sub(a, b), z)))

def wl_h(+mat: Bool, +pm: Bool, +lo: D.Dv, +hi: D.Dv, +plo: D.Dv, +phi: D.Dv, +nlo: F64, +nhi: F64, +nplo: F64, +nphi: F64, +n: Nat) -> D.Dv:
  +z0 = D.dk(n, I.ipt(0.0f64))
  +wlo = Bool.pick(D.Dv, F64.is_eq(nlo, nplo), z0, Bool.pick(D.Dv, F64.is_lt(nlo, nplo), D.dsub(plo, lo), D.dsub(lo, plo)))
  +whi = Bool.pick(D.Dv, F64.is_eq(nhi, nphi), z0, Bool.pick(D.Dv, F64.is_lt(nphi, nhi), D.dsub(hi, phi), D.dsub(phi, hi)))
  Bool.pick(D.Dv, mat, Bool.pick(D.Dv, pm, D.dadd(wlo, whi), D.dsub(hi, lo)), Bool.pick(D.Dv, pm, D.dsub(phi, plo), z0))

def flag(+b: Bool) -> F64:
  Bool.pick(F64, b, 1.0f64, 0.0f64)

def cell_ok(+c: BD.Cl, +pc: BD.Cl, +has: Bool, +ns: List<&2, M.Node>, +z: ZT.Zb, +fuel: Nat) -> Bool:
  +sc = sc_op(fuel, nd_find(ns, BD.cl_nd(c)), ns, BD.cl_k(c))
  +ps = sc_op(fuel, nd_find(ns, BD.cl_nd(pc)), ns, BD.cl_k(pc))
  +rel = Bool.or(Bool.not(has), Bool.and(rel_ok(sc_lo(sc), sc_lo(ps), BD.cl_lo(c), BD.cl_lo(pc), z), rel_ok(sc_hi(sc), sc_hi(ps), BD.cl_hi(c), BD.cl_hi(pc), z)))
  Bool.and(rel, ZT.lz_ok(ZT.loop_z(sc_lp(sc), z)))

def cell_md(+d: BD.Cd, +pc: BD.Cl, +has: Bool, +ns: List<&2, M.Node>, +z: ZT.Zd, +fuel: Nat) -> Dz:
  +n = ZT.zd_n(z)
  +c = BD.cd_c(d)
  +sc = sc_op(fuel, nd_find(ns, BD.cl_nd(c)), ns, BD.cl_k(c))
  +ps = sc_op(fuel, nd_find(ns, BD.cl_nd(pc)), ns, BD.cl_k(pc))
  +dm = ZT.dloop(sc_lp(sc), z)
  +a = ZT.dabs(ZT.dm_ar(dm))
  +pr = ZT.dm_ln(dm)
  +mat = BD.cl_mat(c)
  +pm = Bool.and(has, BD.cl_mat(pc))
  +ttr = BD.cd_ttr(d)
  +btr = BD.cd_btr(d)
  +lo = ZT.xd(sc_lo(sc), z)
  +hi = ZT.xd(sc_hi(sc), z)
  +plo = ZT.xd(sc_lo(ps), z)
  +phi = ZT.xd(sc_hi(ps), z)
  +z0 = D.dk(n, I.ipt(0.0f64))
  +own = Bool.pick(D.Dv, mat, D.dsub(hi, lo), z0)
  +par = Bool.pick(D.Dv, pm, D.dsub(phi, plo), z0)
  +k = F64.sub(F64.add(flag(Bool.and(mat, Bool.not(ttr))), flag(Bool.and(mat, Bool.not(btr)))), F64.add(flag(Bool.and(pm, Bool.not(ttr))), flag(Bool.and(pm, Bool.not(btr)))))
  +wh = wl_h(mat, pm, lo, hi, plo, phi, BD.cl_lo(c), BD.cl_hi(c), BD.cl_lo(pc), BD.cl_hi(pc), n)
  Dz{D.dmul(a, D.dsub(own, par)), D.dadd(D.dsc(I.ipt(k), a), D.dmul(pr, wh))}

def cells_ok(ds: List<&2, BD.Cd>, +tb: B.Tb<&2, BD.Cd>, +ns: List<&2, M.Node>, +z: ZT.Zb, +fuel: Nat) -> Bool:
  match ds:
    case []: True{}
    case +d <> t:
      +c = BD.cd_c(d)
      +p = BD.cl_par(c)
      +has = Bool.not(Nat.is_eq(p, 0n))
      +pc = BD.cd_c(B.tb_get(BD.Cd, tb, U32.from_nat(Nat.sub(p, 1n))))
      Bool.and(cell_ok(c, pc, has, ns, z, fuel), cells_ok(t, tb, ns, z, fuel))

def cells_md(ds: List<&2, BD.Cd>, +tb: B.Tb<&2, BD.Cd>, +ns: List<&2, M.Node>, +z: ZT.Zd, +fuel: Nat) -> Dz:
  match ds:
    case []: dz_zero(ZT.zd_n(z))
    case +d <> t:
      +p = BD.cl_par(BD.cd_c(d))
      +has = Bool.not(Nat.is_eq(p, 0n))
      +pc = BD.cd_c(B.tb_get(BD.Cd, tb, U32.from_nat(Nat.sub(p, 1n))))
      dz_add(cell_md(d, pc, has, ns, z, fuel), cells_md(t, tb, ns, z, fuel))

def zb_of(+ps: List<&2, M.Param>) -> ZT.Zb:
  ZT.Zb{X.env_of(pvs_lo(ps)), X.env_of(pvs_hi(ps))}

def p_ids(ps: List<&2, M.Param>) -> List<&2, U64>:
  match ps:
    case []: []
    case p <> t:
      M.Pm{id, name, dim} = p
      id <> p_ids(t)

def p_ivs(ps: List<&2, M.Param>, +mid: Bool) -> List<&2, I.I>:
  match ps:
    case []: []
    case p <> t:
      M.Pm{id, name, dim} = p
      M.Dm{nom, +lo, +hi} = dim
      +m = F64.mul(0.5f64, F64.add(lo, hi))
      Bool.pick(I.I, mid, I.ipt(m), I.I{lo, hi}) <> p_ivs(t, mid)

def p_w(ps: List<&2, M.Param>) -> List<&2, I.I>:
  match ps:
    case []: []
    case p <> t:
      M.Pm{id, name, dim} = p
      M.Dm{nom, +lo, +hi} = dim
      +m = F64.mul(0.5f64, F64.add(lo, hi))
      I.isub(I.I{lo, hi}, I.ipt(m)) <> p_w(t)

def widest(ps: List<&2, M.Param>, +best: U64, +w: F64) -> U64:
  match ps:
    case []: best
    case p <> t:
      M.Pm{+id, name, dim} = p
      M.Dm{nom, +lo, +hi} = dim
      +d = F64.sub(hi, lo)
      +more = F64.is_lt(w, d)
      widest(t, Bool.pick(U64, more, id, best), Bool.pick(F64, more, d, w))

def cut_dim(+left: Bool, +nom: F64, +lo: F64, +hi: F64) -> M.Dim:
  +m = F64.mul(0.5f64, F64.add(lo, hi))
  Bool.pick(M.Dim, left, M.Dm{nom, lo, m}, M.Dm{nom, m, hi})

def cut_ps(ps: List<&2, M.Param>, +id: U64, +left: Bool) -> List<&2, M.Param>:
  match ps:
    case []: []
    case p <> t:
      M.Pm{+pid, name, dim} = p
      M.Dm{+nom, +lo, +hi} = dim
      M.Pm{pid, name, Bool.pick(M.Dim, U64.is_eq(pid, id), cut_dim(left, nom, lo, hi), M.Dm{nom, lo, hi})} <> cut_ps(t, id, left)

def prof_ok(+n: Nat, mo: Maybe<&2, M.Op>, +ns: List<&2, M.Node>, +b: M.Body, +id: U64, +z: ZT.Zb) -> Bool:
  match n:
    case 0n: False{}
    case 1n+(+m):
      match mo:
        case None{}: False{}
        case Some{+o}:
          match o:
            case M.O_revolve{rs}: rv_ok_all(rs, z)
            case M.O_move{+base, tx, ty, tz, q}: prof_ok(m, nd_find(ns, base), ns, b, base, z)
            case M.O_rot{+base, ax, deg}: prof_ok(m, nd_find(ns, base), ns, b, base, z)
            case _:
              +cs = M.bd_cells(b)
              +ds = BD.cds_of(cs)
              Bool.and(cells_ok(ds, B.tb_of(BD.Cd, ds, BD.cd_pad()), ns, z, n), node_ok(n, Some{o}, ns, cs, id, z))

def zfuel(+ns: List<&2, M.Node>) -> Nat:
  Nat.add(1n, List.length(&2, M.Node, ns))

def prof_dz(+n: Nat, mo: Maybe<&2, M.Op>, +ns: List<&2, M.Node>, +b: M.Body, +z: ZT.Zd) -> Dz:
  match n:
    case 0n: dz_zero(ZT.zd_n(z))
    case 1n+(+m):
      match mo:
        case None{}: dz_zero(ZT.zd_n(z))
        case Some{o}:
          match o:
            case M.O_revolve{rs}: rv_dz(rs, z)
            case M.O_move{base, tx, ty, tz, q}: prof_dz(m, nd_find(ns, base), ns, b, z)
            case M.O_rot{base, ax, deg}: prof_dz(m, nd_find(ns, base), ns, b, z)
            case _:
              +ds = BD.cds_of(M.bd_cells(b))
              cells_md(ds, B.tb_of(BD.Cd, ds, BD.cd_pad()), ns, z, n)

def dz_at(+ps: List<&2, M.Param>, +ns: List<&2, M.Node>, +b: M.Body, +id: U64, +mid: Bool) -> Dz:
  prof_dz(zfuel(ns), nd_find(ns, id), ns, b, ZT.Zd{p_ids(ps), p_ivs(ps, mid)})

def dz_v(d: Dz) -> D.Dv:
  Dz{v, a} = d
  v

def dz_a(d: Dz) -> D.Dv:
  Dz{v, a} = d
  a

def mv_of(+ps: List<&2, M.Param>, +ns: List<&2, M.Node>, +b: M.Body, +id: U64, +vol: Bool) -> I.I:
  +m = dz_at(ps, ns, b, id, True{})
  +x = dz_at(ps, ns, b, id, False{})
  Bool.pick(I.I, vol, D.mvf(dz_v(m), dz_v(x), p_w(ps)), D.mvf(dz_a(m), dz_a(x), p_w(ps)))

def cdim(p: M.Param, +g: I.I, +up: Bool) -> M.Param:
  M.Pm{id, name, dim} = p
  M.Dm{+nom, +lo, +hi} = dim
  +inc = ZT.pos(g)
  +dec = ZT.neg(g)
  +at = Bool.pick(F64, Bool.and(inc, up), hi, Bool.pick(F64, inc, lo, Bool.pick(F64, up, lo, hi)))
  M.Pm{id, name, Bool.pick(M.Dim, Bool.or(inc, dec), M.Dm{nom, at, at}, M.Dm{nom, lo, hi})}

def corner(ps: List<&2, M.Param>, gs: List<&2, I.I>, +up: Bool) -> List<&2, M.Param>:
  match ps:
    case []: []
    case +p <> +t:
      match gs:
        case []: p <> t
        case g <> u: cdim(p, g, up) <> corner(t, u, up)

def bound(+ps: List<&2, M.Param>, +ns: List<&2, M.Node>, +b: M.Body, +id: U64, +vol: Bool) -> I.I:
  +x = dz_at(ps, ns, b, id, False{})
  +g = D.dgrad(Bool.pick(D.Dv, vol, dz_v(x), dz_a(x)))
  +lo = mv_of(corner(ps, g, False{}), ns, b, id, vol)
  +hi = mv_of(corner(ps, g, True{}), ns, b, id, vol)
  I.I{I.i_lo(lo), I.i_hi(hi)}

def zm_box(+ps: List<&2, M.Param>, +ns: List<&2, M.Node>, +b: M.Body, +id: U64) -> Zm:
  Zm{prof_ok(zfuel(ns), nd_find(ns, id), ns, b, id, zb_of(ps)), bound(ps, ns, b, id, True{}), bound(ps, ns, b, id, False{})}

def zm_hull(+a: Zm, +b: Zm) -> Zm:
  Zm{ok1, v1, a1} = a
  Zm{ok2, v2, a2} = b
  Zm{Bool.and(ok1, ok2), I.ihull(v1, v2), I.ihull(a1, a2)}

def zsplit(d: Nat, ok: Bool, +m: Zm, +ps: List<&2, M.Param>, +ns: List<&2, M.Node>, +b: M.Body, +id: U64) -> Zm:
  match d:
    case 0n: m
    case 1n+(+e):
      match ok:
        case True{}: m
        case False{}:
          +w = widest(ps, 0u64, F64.neg(1.0f64))
          +l = cut_ps(ps, w, True{})
          +r = cut_ps(ps, w, False{})
          +ml = zm_box(l, ns, b, id)
          +mr = zm_box(r, ns, b, id)
          zm_hull(zsplit(e, zm_ok(ml), ml, l, ns, b, id), zsplit(e, zm_ok(mr), mr, r, ns, b, id))

def zm_res(m: Zm) -> ZR:
  Zm{ok, +v, +a} = m
  Bool.pick(ZR, Bool.and(ok, Bool.and(pos(v), pos(a))), Z_ok{v, a}, Z_err{"topology-not-certified-over-zone"})

def prof_zone(mb: Maybe<&2, M.Body>, +ps: List<&2, M.Param>, +ns: List<&2, M.Node>, +id: U64) -> ZR:
  match mb:
    case None{}: Z_err{"node-failed-at-nominal"}
    case Some{+b}:
      +m0 = zm_box(ps, ns, b, id)
      zm_res(zsplit(3n, zm_ok(m0), m0, ps, ns, b, id))

def zone_prof(+p: M.Part, +id: U64) -> ZR:
  M.Pt{+ps, +ns} = p
  prof_zone(body_of(M.ce_r(M.ce_find(M.ev_part(M.Pt{ps, ns}, []), id))), ps, ns, id)

def zone_pick(prof: Bool, +w: String, +p: M.Part, +id: U64) -> ZR:
  match prof:
    case True{}: zone_prof(p, id)
    case False{}: Z_err{w}

def zone_k(r: ZR, +p: M.Part, +id: U64) -> ZR:
  match r:
    case Z_err{+w}: zone_pick(String.eq(w, "profile-node"), w, p, id)
    case Z_ok{v, a}: Z_ok{v, a}

def zone(+p: M.Part, +id: U64) -> ZR:
  M.Pt{+ps, +ns} = p
  zone_k(Bool.pick(ZR, zones_ok(ps), z_go(Nat.add(1n, List.length(&2, M.Node, ns)), nd_find(ns, id), ns, ze_of(ps)), Z_err{"zone-not-ordered"}), M.Pt{ps, ns}, id)
