import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ../base/par.bend as B

def sk_other() -> U64:
  0u64

def sk_planex() -> U64:
  1u64

def sk_planey() -> U64:
  2u64

def sk_planez() -> U64:
  3u64

def sk_cylx() -> U64:
  4u64

def sk_cyly() -> U64:
  5u64

def sk_cylz() -> U64:
  6u64

def sk_sphere() -> U64:
  7u64

def sk_cone() -> U64:
  8u64

def sk_torus() -> U64:
  9u64

def sk_pgen() -> U64:
  10u64

def sk_cgen() -> U64:
  11u64

def sk_is_plane(+k: U64) -> Bool:
  Bool.and(U64.is_le(1u64, k), U64.is_le(k, 3u64))

def sk_is_cyl(+k: U64) -> Bool:
  Bool.and(U64.is_le(4u64, k), U64.is_le(k, 6u64))

def sk_axis(+k: U64) -> U64:
  Bool.pick(U64, sk_is_plane(k), U64.sub(k, 1u64),
    Bool.pick(U64, sk_is_cyl(k), U64.sub(k, 4u64), 3u64))

def rel_disjoint() -> U64:
  0u64

def rel_transverse() -> U64:
  1u64

def rel_parallel() -> U64:
  2u64

def rel_coplanar() -> U64:
  3u64

def rel_coaxial() -> U64:
  4u64

def rel_tangent() -> U64:
  5u64

def rel_cylcoin() -> U64:
  6u64

def rel_cylpar() -> U64:
  7u64

def ck_none() -> U64:
  0u64

def ck_line() -> U64:
  1u64

def ck_circle() -> U64:
  2u64

def ck_segs() -> U64:
  3u64

def ck_ring() -> U64:
  4u64

def kr_ok() -> U64:
  0u64

def kr_nonconic() -> U64:
  1u64

def kr_curvedside() -> U64:
  2u64

def kr_angled() -> U64:
  3u64

def kr_thetacut() -> U64:
  4u64

def kr_uncertain() -> U64:
  5u64

def kr_inconsistent() -> U64:
  6u64

def kr_degenerate() -> U64:
  7u64

def kr_offdomain() -> U64:
  8u64

def dec_pack(+splitA: Bool, +splitB: Bool, +curve: U64, +refuse: U64) -> U64:
  U64.add(Bool.pick(U64, splitA, 1u64, 0u64),
    U64.add(Bool.pick(U64, splitB, 2u64, 0u64),
      U64.add(U64.mul(curve, 4u64), U64.mul(refuse, 32u64))))

def dec_splitA(+d: U64) -> Bool:
  U64.is_eq(U64.and(d, 1u64), 1u64)

def dec_splitB(+d: U64) -> Bool:
  U64.is_eq(U64.and(d, 2u64), 2u64)

def dec_curve(+d: U64) -> U64:
  U64.and(U64.div(d, 4u64), 7u64)

def dec_refuse(+d: U64) -> U64:
  U64.div(d, 32u64)

def dec_ok(+d: U64) -> Bool:
  U64.is_eq(dec_refuse(d), kr_ok())

def dec_swap(+d: U64) -> U64:
  dec_pack(dec_splitB(d), dec_splitA(d), dec_curve(d), dec_refuse(d))

def dec_none() -> U64:
  dec_pack(False{}, False{}, ck_none(), kr_ok())

def pk_pp(+rel: U64) -> U64:
  Bool.pick(U64, U64.is_eq(rel, rel_coplanar()), dec_pack(True{}, True{}, ck_segs(), kr_ok()),
    Bool.pick(U64, U64.is_eq(rel, rel_transverse()), dec_pack(True{}, True{}, ck_line(), kr_ok()),
      dec_none()))

def pp_parallel() -> U64:
  0u64

def pp_perp() -> U64:
  1u64

def pp_angled() -> U64:
  2u64

def pk_pc(+rel: U64, +perp: U64) -> U64:
  Bool.pick(U64, U64.is_eq(rel, rel_transverse()),
    Bool.pick(U64, U64.is_eq(perp, pp_perp()), dec_pack(True{}, True{}, ck_circle(), kr_ok()),
      Bool.pick(U64, U64.is_eq(perp, pp_parallel()), dec_pack(False{}, False{}, ck_none(), kr_thetacut()),
        dec_pack(False{}, False{}, ck_none(), kr_angled()))),
    dec_none())

def pk_pq(+rel: U64, +cone: Bool, +perp: U64) -> U64:
  Bool.pick(U64, U64.is_eq(rel, rel_transverse()),
    Bool.pick(U64, cone,
      Bool.pick(U64, U64.is_eq(perp, pp_parallel()), dec_pack(False{}, False{}, ck_none(), kr_thetacut()),
        Bool.pick(U64, U64.is_eq(perp, pp_angled()), dec_pack(False{}, False{}, ck_none(), kr_angled()),
          dec_pack(False{}, False{}, ck_none(), kr_curvedside()))),
      dec_pack(False{}, False{}, ck_none(), kr_curvedside())),
    dec_none())

def pk_cc(+rel: U64) -> U64:
  Bool.pick(U64, U64.is_eq(rel, rel_cylcoin()), dec_pack(True{}, True{}, ck_circle(), kr_ok()),
    Bool.pick(U64, U64.is_eq(rel, rel_cylpar()), dec_pack(True{}, True{}, ck_none(), kr_ok()),
      Bool.pick(U64, U64.is_eq(rel, rel_transverse()), dec_pack(True{}, True{}, ck_ring(), kr_ok()),
        dec_none())))

def pk_gen(+rel: U64) -> U64:
  Bool.pick(U64, U64.is_eq(rel, rel_transverse()), dec_pack(False{}, False{}, ck_none(), kr_curvedside()),
    Bool.pick(U64, U64.is_eq(rel, rel_cylcoin()), dec_pack(False{}, False{}, ck_none(), kr_thetacut()),
      Bool.pick(U64, U64.is_eq(rel, rel_cylpar()), dec_pack(False{}, False{}, ck_none(), kr_thetacut()),
        dec_none())))

def pk_kind(+ka: U64, +kb: U64) -> U64:
  Bool.pick(U64, Bool.and(sk_is_plane(ka), sk_is_plane(kb)), 1u64,
    Bool.pick(U64, Bool.and(sk_is_plane(ka), sk_is_cyl(kb)), 2u64,
      Bool.pick(U64, Bool.and(sk_is_cyl(ka), sk_is_plane(kb)), 3u64,
        Bool.pick(U64, Bool.and(sk_is_cyl(ka), sk_is_cyl(kb)), 4u64,
          Bool.pick(U64, Bool.or(Bool.and(sk_is_plane(ka), U64.is_eq(kb, sk_sphere())),
            Bool.or(Bool.and(U64.is_eq(ka, sk_sphere()), sk_is_plane(kb)),
              Bool.or(Bool.and(sk_is_plane(ka), U64.is_eq(kb, sk_cone())),
                Bool.and(U64.is_eq(ka, sk_cone()), sk_is_plane(kb))))), 5u64, 0u64)))))

def pk_cone_side(+ka: U64, +kb: U64) -> Bool:
  Bool.or(U64.is_eq(ka, sk_cone()), U64.is_eq(kb, sk_cone()))

def pk_decide(+ka: U64, +kb: U64, +rel: U64, +perp: U64) -> U64:
  +kk = pk_kind(ka, kb)
  Bool.pick(U64, U64.is_eq(kk, 1u64), pk_pp(rel),
    Bool.pick(U64, U64.is_eq(kk, 2u64), pk_pc(rel, perp),
      Bool.pick(U64, U64.is_eq(kk, 3u64), dec_swap(pk_pc(rel, perp)),
        Bool.pick(U64, U64.is_eq(kk, 4u64), pk_cc(rel),
          Bool.pick(U64, U64.is_eq(kk, 5u64), pk_pq(rel, pk_cone_side(ka, kb), perp), pk_gen(rel))))))

def fc_out() -> U64:
  0u64

def fc_in() -> U64:
  1u64

def fc_same() -> U64:
  2u64

def fc_opp() -> U64:
  3u64

def fc_unc() -> U64:
  4u64

def fc_coin() -> U64:
  5u64

def kkeep(+op: U64, +code: U64) -> U64:
  Bool.pick(U64, U64.is_eq(code, fc_unc()), 2u64,
    Bool.pick(U64, U64.is_eq(op, 14u64),
      Bool.pick(U64, Bool.or(U64.is_eq(code, fc_out()), U64.is_eq(code, fc_same())), 1u64, 0u64),
      Bool.pick(U64, U64.is_eq(op, 15u64),
        Bool.pick(U64, Bool.or(U64.is_eq(code, fc_out()), U64.is_eq(code, fc_opp())), 1u64, 0u64),
        Bool.pick(U64, Bool.or(U64.is_eq(code, fc_in()), U64.is_eq(code, fc_same())), 1u64, 0u64))))

def cls_out() -> U64:
  0u64

def cls_in() -> U64:
  1u64

def cls_unc() -> U64:
  2u64

def coinrule(+op: U64, +side: U64, +c1: U64, +c2: U64) -> U64:
  Bool.pick(U64, U64.is_eq(side, 0u64),
    Bool.pick(U64, U64.is_eq(op, 14u64), Bool.pick(U64, U64.is_eq(c1, cls_out()), 1u64, 0u64),
      Bool.pick(U64, U64.is_eq(op, 15u64), Bool.pick(U64, U64.is_eq(c2, cls_out()), 1u64, 0u64),
        Bool.pick(U64, U64.is_eq(c2, cls_in()), 1u64, 0u64))),
    0u64)

def kkeepb(+op: U64, +code: U64) -> U64:
  Bool.pick(U64, U64.is_eq(op, 15u64),
    Bool.pick(U64, U64.is_eq(code, fc_unc()), 2u64,
      Bool.pick(U64, U64.is_eq(code, fc_in()), 1u64, 0u64)),
    kkeep(op, code))

def kflip(+op: U64, +side: U64) -> Bool:
  Bool.and(U64.is_eq(op, 15u64), U64.is_eq(side, 1u64))

def kcomb(+c0: U64, +c1: U64, +c2: U64) -> U64:
  Bool.pick(U64, U64.is_eq(c0, cls_in()), fc_in(),
    Bool.pick(U64, U64.is_eq(c0, cls_out()), fc_out(),
      Bool.pick(U64, Bool.and(U64.is_eq(c1, cls_in()), U64.is_eq(c2, cls_in())), fc_in(),
        Bool.pick(U64, Bool.and(U64.is_eq(c1, cls_out()), U64.is_eq(c2, cls_out())), fc_out(),
          Bool.pick(U64,
            Bool.or(Bool.and(U64.is_eq(c1, cls_in()), U64.is_eq(c2, cls_out())),
              Bool.and(U64.is_eq(c1, cls_out()), U64.is_eq(c2, cls_in()))), fc_coin(), fc_unc())))))

def kfrag(+op: U64, +side: U64, +c0: U64, +c1: U64, +c2: U64) -> U64:
  +k = kcomb(c0, c1, c2)
  Bool.pick(U64, U64.is_eq(k, fc_coin()), coinrule(op, side, c1, c2),
    Bool.pick(U64, U64.is_eq(side, 1u64), kkeepb(op, k), kkeep(op, k)))

def band_sm(+flip: Bool, +same: Bool) -> Bool:
  Bool.pick(Bool, flip, Bool.not(same), same)

def band_fw_lo(+sm: Bool, +pos: Bool) -> Bool:
  Bool.or(Bool.and(sm, pos), Bool.and(Bool.not(sm), Bool.not(pos)))

def band_fw_hi(+sm: Bool, +pos: Bool) -> Bool:
  Bool.or(Bool.and(sm, Bool.not(pos)), Bool.and(Bool.not(sm), pos))

def pk_dom(+ka: U64, +kb: U64, +rel: U64, +perp: U64) -> U64:
  Bool.pick(U64,
    Bool.and(Bool.or(U64.is_le(10u64, ka), U64.is_le(10u64, kb)), U64.is_eq(rel, rel_transverse())),
    dec_pack(False{}, False{}, ck_none(), kr_offdomain()),
    pk_decide(ka, kb, rel, perp))


