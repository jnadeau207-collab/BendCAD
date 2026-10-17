import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c06/iv.bend as I
import ../../src/c06/model.bend as M
import ../../src/c06/prof.bend as F
import ../../src/c06/xp.bend as X
import ../../src/c07/sol.bend as SO
import ../../src/c08/bool.bend as B8
import ../../src/k1/core.bend as KC
import ../../src/k1/curve.bend as KU
import ../../src/k1/clip.bend as QC
import ../../src/k1/surg.bend as K1

def unnr(+r: M.NR) -> M.Body:
  match r:
    case M.NR_ok{+b, fx}: b
    case M.NR_err{k, d}:
      M.Bd{[], Ty.Br{[], [], [], [], [], [], [], Ty.Cp{[], []}, 0u64}, [], M.pl_id(), [], M.xb_id()}

def box10(+e: X.Env, +nd: U64) -> M.Body:
  unnr(M.op_prism([M.rect_rg(M.xk(10.0f64), M.xk(10.0f64))], M.xk(0.0f64), M.xk(10.0f64), e, nd))

def moved(+b: M.Body, +x: F64, +y: F64, +z: F64, +e: X.Env, +nd: U64) -> M.Body:
  unnr(M.op_move(b, M.xk(x), M.xk(y), M.xk(z), 0u64, e, nd))

def zcyl(+r: F64, +z0: F64, +z1: F64, +e: X.Env, +nd: U64) -> M.Body:
  unnr(M.op_prism([M.circ_rg(M.xk(r))], M.xk(z0), M.xk(z1), e, nd))

def ksum(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +kr = K1.k1run(op, ba, bb)
  Bool.pick(String, K1.kr_ok(kr),
    "k1ok V" ++ Nat.show(K1.kr_nv(kr)) ++ " E" ++ Nat.show(K1.kr_ne(kr)) ++ " F" ++
      Nat.show(K1.kr_nf(kr)) ++ " S" ++ Nat.show(K1.kr_nc(kr)),
    "k1no why=" ++ U64.show(K1.kr_why(kr)))

def kwhy(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> U64:
  K1.kr_why(K1.k1run(op, ba, bb))

def pk_cc_cylpar__got() -> U64:
  KC.pk_cc(KC.rel_cylpar())

def pk_cc_cylpar__want() -> U64:
  3u64

def pk_cc_cylcoin__got() -> U64:
  KC.pk_cc(KC.rel_cylcoin())

def pk_cc_cylcoin__want() -> U64:
  11u64

def pk_pp_coplanar__got() -> U64:
  KC.pk_pp(KC.rel_coplanar())

def pk_pp_coplanar__want() -> U64:
  15u64

def pk_pc_perp__got() -> U64:
  KC.pk_pc(KC.rel_transverse(), KC.pp_perp())

def pk_pc_perp__want() -> U64:
  11u64

def kfrag_pm__got() -> U64:
  KC.kfrag(14u64, 0u64, 3u64, 1u64, 0u64)

def kfrag_pm__want() -> U64:
  0u64

def kfrag_mp__got() -> U64:
  KC.kfrag(14u64, 0u64, 3u64, 0u64, 1u64)

def kfrag_mp__want() -> U64:
  1u64

def kfrag_unc__got() -> U64:
  KC.kfrag(14u64, 0u64, 2u64, 2u64, 2u64)

def kfrag_unc__want() -> U64:
  2u64

def k_overlap__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 2.0f64, 2.0f64, e, 3u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_overlap__want() -> String:
  "k1ok V44 E84 F42 S1"

def k_straddle__got() -> String:
  +e = X.env_mk([])
  +b1 = unnr(M.op_prism([M.rect_rg(M.xk(20.0f64), M.xk(20.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 1u64))
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(4.0f64), M.xk(4.0f64))], M.xk(0.0f64), M.xk(4.0f64), e, 2u64)), 18.0f64, 8.0f64, 8.0f64, e, 3u64)
  ksum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_straddle__want() -> String:
  "k1ok V48 E92 F46 S1"

def k_pierce__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(unnr(M.op_prism([M.rect_rg(M.xk(2.0f64), M.xk(2.0f64))], M.xk(0.0f64), M.xk(20.0f64), e, 2u64)), 4.0f64, 4.0f64, F64.neg(5.0f64), e, 3u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_pierce__want() -> String:
  "k1ok V40 E76 F38 S1"

def k_port__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_port__want() -> String:
  "k1ok V12 E16 F10 S1"

def k_cbore__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  ksum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_cbore__want() -> String:
  "k1ok V14 E22 F12 S1"

def k_cbu__got() -> String:
  +e = X.env_mk([])
  +b1 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 1u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +b3 = moved(zcyl(1.5f64, F64.neg(5.0f64), 8.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_cbu__want() -> String:
  "k1ok V5 E5 F6 S1"

def k_bore__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  ksum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_bore__want() -> String:
  "k1ok V10 E14 F7 S1"

def k_fig8__got() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_fig8__want() -> String:
  "k1ok V12 E20 F10 S1"

def k_ident__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +ba = B8.bake_of(M.bool_in(b1))
  ksum(B8.tag_union(), ba, ba)

def k_ident__want() -> String:
  "k1ok V8 E12 F6 S1"

def i_overlap__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 2.0f64, 2.0f64, e, 3u64)
  ksum(B8.tag_inter(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def i_overlap__want() -> String:
  "k1ok V8 E12 F6 S1"

def i_fig8__got() -> String:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  ksum(B8.tag_inter(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def i_fig8__want() -> String:
  "k1ok V8 E12 F6 S1"

def i_port__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +b3 = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  ksum(B8.tag_inter(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def i_port__want() -> String:
  "k1ok V2 E2 F3 S1"

def i_bore__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  ksum(B8.tag_inter(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def i_bore__want() -> String:
  "k1ok V2 E2 F3 S1"

def two_sq() -> List<&2, F.Region>:
  [F.Rg{F.L_path{M.xk(1.0f64), M.xk(1.0f64), [F.S_line{M.xk(5.0f64), M.xk(1.0f64)}, F.S_line{M.xk(5.0f64), M.xk(5.0f64)}, F.S_line{M.xk(1.0f64), M.xk(5.0f64)}]}, []},
   F.Rg{F.L_path{M.xk(100.0f64), M.xk(100.0f64), [F.S_line{M.xk(105.0f64), M.xk(100.0f64)}, F.S_line{M.xk(105.0f64), M.xk(105.0f64)}, F.S_line{M.xk(100.0f64), M.xk(105.0f64)}]}, []}]

def k_mixreg__got() -> U64:
  +e = X.env_mk([])
  +b1 = unnr(M.op_prism([M.rect_rg(M.xk(40.0f64), M.xk(40.0f64))], M.xk(0.0f64), M.xk(40.0f64), e, 1u64))
  +b2 = moved(unnr(M.op_prism(two_sq(), M.xk(0.0f64), M.xk(10.0f64), e, 2u64)), 0.0f64, 0.0f64, 5.0f64, e, 3u64)
  kwhy(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b2)))

def k_mixreg__want() -> U64:
  50u64

def k_coin__got() -> U64:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 0.0f64, 0.0f64, 5.0f64, e, 3u64)
  kwhy(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_coin__want() -> U64:
  38u64

def k_sph__got() -> U64:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = unnr(M.op_rev([M.sph_rg(M.xk(6.0f64))], e, 2u64))
  kwhy(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))

def k_sph__want() -> U64:
  2u64

def venn_dia_pieces__got() -> Nat:
  +q = QC.qg_ar(2.0f64, F64.neg(2.23606797749979f64), 2.0f64, 2.23606797749979f64, 0.0f64,
    0.0f64, 3.0f64, True{}, QC.lab_newar(), 0n)
  List.length(&2, QC.QG, QC.venn_dia_loop([q], 0.0f64, 0.0f64, 3.0f64))

def venn_dia_pieces__want() -> Nat:
  2n

def venn_dia_head(+ps: List<&2, QC.QG>) -> F64:
  match ps:
    case []: 0.0f64
    case +h <> +t: QC.qg_bx(h)

def venn_dia_pt__got() -> F64:
  +q = QC.qg_ar(2.0f64, F64.neg(2.23606797749979f64), 2.0f64, 2.23606797749979f64, 0.0f64,
    0.0f64, 3.0f64, True{}, QC.lab_newar(), 0n)
  venn_dia_head(QC.venn_dia_loop([q], 0.0f64, 0.0f64, 3.0f64))

def venn_dia_pt__want() -> F64:
  3.0f64

def tcut_pts_go(ps: List<&2, V.Vec2>, +ax: F64, +ay: F64) -> V.Vec2:
  match ps:
    case []: V.V2{ax, ay}
    case +h <> +t: tcut_pts_go(t, F64.add(ax, V.v2_x(h)), F64.add(ay, F64.abs(V.v2_y(h))))

def tcut_pts() -> V.Vec2:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  +ks = KU.analist(ba, bb, SO.fds_of(ba), SO.fds_of(bb))
  +fa = KU.nth_fa0(Ty.brep_fas(ba), 2n)
  +fr = K1.fr_of(Ty.fa_surf(fa), KU.surfkind(Ty.fa_surf(fa)))
  +tc = K1.tcut_for(ks, 2n, 0u64, bb, fr, 0.0f64, 10.0f64)
  tcut_pts_go(K1.tc_pts(tc), 0.0f64, 0.0f64)

def tcut_count__got() -> Nat:
  +e = X.env_mk([])
  +b1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +b3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  +ba = B8.bake_of(M.bool_in(b1))
  +bb = B8.bake_of(M.bool_in(b3))
  +ks = KU.analist(ba, bb, SO.fds_of(ba), SO.fds_of(bb))
  +fa = KU.nth_fa0(Ty.brep_fas(ba), 2n)
  +fr = K1.fr_of(Ty.fa_surf(fa), KU.surfkind(Ty.fa_surf(fa)))
  +tc = K1.tcut_for(ks, 2n, 0u64, bb, fr, 0.0f64, 10.0f64)
  List.length(&2, V.Vec2, K1.tc_pts(tc))

def tcut_count__want() -> Nat:
  2n

def tcut_sumx__got() -> F64:
  V.v2_x(tcut_pts())

def tcut_sumx__want() -> F64:
  4.0f64

def tcut_sumay__got() -> F64:
  V.v2_y(tcut_pts())

def tcut_sumay__want() -> F64:
  4.47213595499958f64

def circtool(+e: X.Env, +nd: U64) -> M.Body:
  moved(unnr(M.op_prism([M.circ_rg(M.xk(1.0f64))], M.xk(10.0f64), M.xk(13.0f64), e, nd)),
    2.0f64, 5.0f64, 0.0f64, e, nd)

def k_padcirc_fresh__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +tool = circtool(e, 5u64)
  ksum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(tool)))

def k_padcirc_fresh__want() -> String:
  "k1ok V10 E14 F8 S1"

def k_padcirc__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +tool = circtool(e, 5u64)
  ksum(B8.tag_union(), K1.kr_brep(kr), B8.bake_of(M.bool_in(tool)))

def k_padcirc__want() -> String:
  "k1ok V18 E30 F16 S1"

def msum(+m: K1.K1M) -> String:
  Bool.pick(String, K1.k1m_ok(m),
    "tv[" ++ F64.show(I.i_lo(K1.k1m_vol(m))) ++ "," ++ F64.show(I.i_hi(K1.k1m_vol(m))) ++
      "]ta[" ++ F64.show(I.i_lo(K1.k1m_ar(m))) ++ "," ++ F64.show(I.i_hi(K1.k1m_ar(m))) ++ "]",
    "tno")

def tsum(+op: U64, +ba: Ty.Brep, +bb: Ty.Brep) -> String:
  +kr = K1.k1run(op, ba, bb)
  Bool.pick(String, K1.kr_ok(kr), msum(K1.k1tight(K1.kr_brep(kr))), "k1no")

def coltool(+e: X.Env, +nd: U64) -> M.Body:
  moved(unnr(M.op_prism([M.circ_rg(M.xk(1.0f64))], M.xk(0.0f64), M.xk(13.0f64), e, nd)),
    2.0f64, 5.0f64, 0.0f64, e, nd)

def t_bore__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +bore = moved(zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  tsum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(bore)))

def t_bore__want() -> String:
  "tv[874.3362938552627,874.336293857554]ta[700.5309649144885,700.5309649152581]"

def t_cbore__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cbore = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  tsum(B8.tag_diff(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(cbore)))

def t_cbore__want() -> String:
  "tv[886.9026644684643,886.9026644730708]ta[675.3982236855707,675.3982236867394]"

def t_port__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +cz = zcyl(2.0f64, F64.neg(5.0f64), 15.0f64, e, 2u64)
  +cx = unnr(M.op_rot(cz, 1u64, M.xk(90.0f64), e, 2u64))
  +port = moved(cx, 0.0f64, 5.0f64, 5.0f64, e, 3u64)
  tsum(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(port)))

def t_port__want() -> String:
  "tv[1125.6637061421504,1125.6637061450333]ta[725.6637061431301,725.6637061440535]"

def t_fig8__got() -> String:
  +e = X.env_mk([])
  +f1 = zcyl(3.0f64, 0.0f64, 10.0f64, e, 1u64)
  +f3 = moved(zcyl(3.0f64, 0.0f64, 10.0f64, e, 2u64), 4.0f64, 0.0f64, 0.0f64, e, 3u64)
  tsum(B8.tag_union(), B8.bake_of(M.bool_in(f1)), B8.bake_of(M.bool_in(f3)))

def t_fig8__want() -> String:
  "tv[503.5370360414677,503.5370360463865]ta[376.7702851700689,376.77028517274914]"

def t_cbu__got() -> String:
  +e = X.env_mk([])
  +u1 = moved(zcyl(3.0f64, 6.0f64, 14.0f64, e, 1u64), 5.0f64, 5.0f64, 0.0f64, e, 3u64)
  +u3 = moved(zcyl(1.5f64, F64.neg(5.0f64), 8.0f64, e, 2u64), 5.0f64, 5.0f64, 0.0f64, e, 4u64)
  tsum(B8.tag_union(), B8.bake_of(M.bool_in(u1)), B8.bake_of(M.bool_in(u3)))

def t_cbu__want() -> String:
  "tv[303.94908923397986,303.94908923564515]ta[311.01767270504376,311.01767270573527]"

def t_colpad__got() -> String:
  +e = X.env_mk([])
  +b1 = box10(e, 1u64)
  +b3 = moved(box10(e, 2u64), 5.0f64, 0.0f64, 0.0f64, e, 3u64)
  +kr = K1.k1run(B8.tag_union(), B8.bake_of(M.bool_in(b1)), B8.bake_of(M.bool_in(b3)))
  +tool = coltool(e, 5u64)
  +kr2 = K1.k1run(B8.tag_union(), K1.kr_brep(kr), B8.bake_of(M.bool_in(tool)))
  Bool.pick(String, K1.kr_ok(kr2), msum(K1.k1tight(K1.kr_brep(kr2))), "k1no")

def t_colpad__want() -> String:
  "tv[1509.4247779576933,1509.4247779638456]ta[818.8495559207722,818.8495559223051]"

def ck_none__got() -> U64:
  KC.ck_none()

def ck_none__want() -> U64:
  0u64

def ck_line__got() -> U64:
  KC.ck_line()

def ck_line__want() -> U64:
  1u64

def ck_circle__got() -> U64:
  KC.ck_circle()

def ck_circle__want() -> U64:
  2u64

def ck_segs__got() -> U64:
  KC.ck_segs()

def ck_segs__want() -> U64:
  3u64

def ck_ring__got() -> U64:
  KC.ck_ring()

def ck_ring__want() -> U64:
  4u64

def pk_cc_transverse__got() -> U64:
  KC.pk_cc(KC.rel_transverse())

def pk_cc_transverse__want() -> U64:
  19u64

def kr_ok__got() -> U64:
  KC.kr_ok()

def kr_ok__want() -> U64:
  0u64

def kr_nonconic__got() -> U64:
  KC.kr_nonconic()

def kr_nonconic__want() -> U64:
  1u64

def kr_curvedside__got() -> U64:
  KC.kr_curvedside()

def kr_curvedside__want() -> U64:
  2u64

def kr_angled__got() -> U64:
  KC.kr_angled()

def kr_angled__want() -> U64:
  3u64

def kr_thetacut__got() -> U64:
  KC.kr_thetacut()

def kr_thetacut__want() -> U64:
  4u64

def kr_uncertain__got() -> U64:
  KC.kr_uncertain()

def kr_uncertain__want() -> U64:
  5u64

def kr_inconsistent__got() -> U64:
  KC.kr_inconsistent()

def kr_inconsistent__want() -> U64:
  6u64

def kr_degenerate__got() -> U64:
  KC.kr_degenerate()

def kr_degenerate__want() -> U64:
  7u64

def kr_offdomain__got() -> U64:
  KC.kr_offdomain()

def kr_offdomain__want() -> U64:
  8u64
