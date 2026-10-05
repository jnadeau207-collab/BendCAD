import Base
import ../c00/types.bend as T
import ./xp.bend as X
import ./iv.bend as I
import ./model.bend as M

type ZR is Data:
  Z_ok{ v: I.I, a: I.I }
  Z_err{ why: String }

type ZE is Data:
  ZE{ lo: X.Env, hi: X.Env }

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
    case 1n+m:
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
            case _: Z_err{"envelope-topology-not-certified"}

def zones_ok(ps: List<&2, M.Param>) -> Bool:
  match ps:
    case []: True{}
    case p <> t:
      M.Pm{id, name, dim} = p
      M.Dm{+nom, +lo, +hi} = dim
      Bool.and(Bool.and(F64.is_le(lo, nom), F64.is_le(nom, hi)), zones_ok(t))

def zone(+p: M.Part, +id: U64) -> ZR:
  M.Pt{+ps, +ns} = p
  Bool.pick(ZR, zones_ok(ps), z_go(Nat.add(1n, List.length(&2, M.Node, ns)), nd_find(ns, id), ns, ze_of(ps)), Z_err{"zone-not-ordered"})
