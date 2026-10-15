import Base
import ../../src/c16/sheet.bend as SH
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c06/xp.bend as X
import ../../src/c06/prof.bend as F
import ../../src/c06/iv.bend as I
import ../../src/base/ex.bend as E

def xk(+v: F64) -> X.Xp:
  X.X_k{v}
def env0() -> X.Env:
  X.env_of([])
def fb(+b: Bool) -> String:
  match b:
    case True{}: "1"
    case False{}: "0"
def fbits(+v: F64) -> String:
  U64.show(F64.bits(v))
def gr_tag(+g: SH.GR) -> String:
  match g:
    case SH.GR_ok{}: "ok"
    case SH.GR_no{+why, +fix}: "no:" ++ why
def kp_tag(+k: SH.KP) -> String:
  SH.KP{+kk, +rot} = k
  U64.show(kk) ++ "/" ++ fb(rot)
def pk_tag(+p: SH.PK) -> String:
  match p:
    case SH.K0{}: "0"
    case SH.K1{}: "1"
    case SH.K2{}: "2"
    case SH.K3{}: "3"
    case SH.K4{}: "4"
    case SH.K5{}: "5"
    case SH.K6{}: "6"
    case SH.K7{}: "7"
    case SH.K8{}: "8"
    case SH.K9{}: "9"
    case SH.K10{}: "10"
    case SH.K11{}: "11"
def fbend(+n: U64, +r: F64, +deg: U64) -> SH.FT:
  SH.FT_bend{n, xk(r), deg}
def fhem(+n: U64, +l: F64) -> SH.FT:
  SH.FT_hem{n, xk(l)}
def scf(+l: F64, +w: F64, +t: F64, +fs: List<&2, SH.FT>) -> SH.SC:
  SH.SC_ok{xk(l), xk(w), xk(t), fs}
def sc100(+fs: List<&2, SH.FT>) -> SH.SC:
  scf(100.0f64, 50.0f64, 2.0f64, fs)
def cks(+s: SH.SC) -> String:
  gr_tag(SH.ck_chain(s, env0(), X.xp_ev(SH.sc_l(s), env0()), X.xp_ev(SH.sc_w(s), env0()), X.xp_ev(SH.sc_t(s), env0())))
def ib_tag(+a: I.I) -> String:
  fbits(I.i_lo(a)) ++ "/" ++ fbits(I.i_hi(a))
def arcs_go(ss: List<&2, SH.Sg>, +n: Nat) -> Nat:
  match ss:
    case []: n
    case +s <> t:
      match s:
        case SH.Sg_ln{+a, +b}: arcs_go(t, n)
        case SH.Sg_ar{+a, +cx, +cy, +r, +b, +ccw}: arcs_go(t, Nat.add(n, 1n))
def prof_counts(+p: SH.PR) -> String:
  SH.PR{+pts, +segs} = p
  Nat.show(List.length(&2, SH.Sg, segs)) ++ "/" ++ Nat.show(List.length(&2, SH.P2, pts))
def prof_arcs(+p: SH.PR) -> String:
  SH.PR{+pts, +segs} = p
  Nat.show(arcs_go(segs, 0n))
def legs_bits_go(ls: List<&2, X.Xp>, +e: X.Env, +first: Bool) -> String:
  match ls:
    case []: ""
    case +h <> t:
      Bool.pick(String, first, "", "/") ++ fbits(X.xp_ev(h, e)) ++ legs_bits_go(t, e, False{})
def legs_bits(+s: SH.SC) -> String:
  legs_bits_go(SH.flat_legs(s), env0(), True{})
def dev_of(+s: SH.SC, +klo: F64, +khi: F64) -> I.I:
  +e = env0()
  +rows = SH.flat_rows(SH.bns_of(SH.sc_feats(s), e), X.xp_ev(SH.sc_t(s), e), klo, khi)
  SH.dev_rows(rows, SH.dev_legs(SH.flat_legs(s), e, I.ipt(0.0f64)))
def fr_tag(+f: SH.FR) -> String:
  SH.FR{+i, +n, +deg, +r, +lo, +hi} = f
  "fr:" ++ Nat.show(i) ++ "/" ++ U64.show(n) ++ "/" ++ U64.show(deg) ++ "/" ++ fbits(r) ++ "/" ++
    fbits(lo) ++ "/" ++ fbits(hi)
def sa(+s: String) -> S.Sx:
  S.Sx_a{s}
def sl(+xs: List<&2, S.Sx>) -> S.Sx:
  S.Sx_l{xs}
def opnm(+o: M.Op) -> String:
  M.op_name(o)
def parsed(+x: S.Sx) -> String:
  opnm(S.op_of(x, []))
def shown(+x: S.Sx) -> String:
  S.sx_show(S.op_sx(S.op_of(x, []), []))
def ck_ok_single__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 90u64)]))
def ck_ok_single__want() -> String:
  "ok"
def ck_ok_u__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 90u64), fbend(2u64, 3.0f64, 90u64)]))
def ck_ok_u__want() -> String:
  "ok"
def ck_ok_hemflat__got() -> String:
  cks(sc100([fhem(0u64, 10.0f64)]))
def ck_ok_hemflat__want() -> String:
  "ok"
def ck_ok_tip__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 90u64), fhem(0u64, 10.0f64)]))
def ck_ok_tip__want() -> String:
  "ok"
def ck_ok_tipu__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 90u64), fbend(2u64, 3.0f64, 90u64), fhem(0u64, 10.0f64)]))
def ck_ok_tipu__want() -> String:
  "ok"
def ck_ok_flat__got() -> String:
  cks(sc100([]))
def ck_ok_flat__want() -> String:
  "ok"
def ck_ok_180__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 180u64)]))
def ck_ok_180__want() -> String:
  "ok"
def ck_ok_dn__got() -> String:
  cks(sc100([fbend(1u64, 3.0f64, 90u64)]))
def ck_ok_dn__want() -> String:
  "ok"
def ck_bad_ang__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 45u64)]))
def ck_bad_ang__want() -> String:
  "no:bend-angle-not-certified"
def ck_bad_edge__got() -> String:
  cks(sc100([fbend(9u64, 3.0f64, 90u64)]))
def ck_bad_edge__want() -> String:
  "no:bend-edge-not-admitted"
def ck_bad_base__got() -> String:
  cks(SH.SC_bad{})
def ck_bad_base__want() -> String:
  "no:bend-base-not-admitted"
def ck_bad_base2__got() -> String:
  cks(sc100([fhem(0u64, 10.0f64), fbend(0u64, 3.0f64, 90u64)]))
def ck_bad_base2__want() -> String:
  "no:bend-base-not-admitted"
def ck_bad_gram3__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 90u64), fbend(2u64, 3.0f64, 90u64), fbend(0u64, 3.0f64, 90u64)]))
def ck_bad_gram3__want() -> String:
  "no:bend-edge-not-admitted"
def ck_bad_gramz__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 90u64), fbend(3u64, 3.0f64, 90u64)]))
def ck_bad_gramz__want() -> String:
  "no:bend-edge-not-admitted"
def ck_bad_gramsame__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 90u64), fbend(1u64, 3.0f64, 90u64)]))
def ck_bad_gramsame__want() -> String:
  "no:bend-edge-not-admitted"
def ck_bad_gram180u__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 180u64), fbend(2u64, 3.0f64, 90u64)]))
def ck_bad_gram180u__want() -> String:
  "no:bend-edge-not-admitted"
def ck_bad_gramtip__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 180u64), fhem(0u64, 10.0f64)]))
def ck_bad_gramtip__want() -> String:
  "no:bend-edge-not-admitted"
def ck_bad_gramhem2__got() -> String:
  cks(sc100([fhem(0u64, 10.0f64), fhem(2u64, 10.0f64)]))
def ck_bad_gramhem2__want() -> String:
  "no:bend-edge-not-admitted"
def ck_bad_urasym__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 90u64), fbend(2u64, 4.0f64, 90u64)]))
def ck_bad_urasym__want() -> String:
  "no:bend-edge-not-admitted"
def ck_bad_rt__got() -> String:
  cks(scf(100.0f64, 50.0f64, 2.0f64, [fbend(0u64, 1.5f64, 90u64)]))
def ck_bad_rt__want() -> String:
  "no:bend-radius-too-tight"
def ck_bad_size__got() -> String:
  cks(scf(8.0f64, 50.0f64, 2.0f64, [fbend(0u64, 3.0f64, 90u64)]))
def ck_bad_size__want() -> String:
  "no:bend-consumes-face"
def ck_bad_len__got() -> String:
  cks(sc100([fhem(0u64, 200.0f64)]))
def ck_bad_len__want() -> String:
  "no:hem-consumes-face"
def ck_bad_len_tip__got() -> String:
  cks(sc100([fbend(0u64, 3.0f64, 90u64), fhem(0u64, 45.0f64)]))
def ck_bad_len_tip__want() -> String:
  "no:hem-consumes-face"
def ck_bad_fin__got() -> String:
  cks(scf(100.0f64, 50.0f64, 0.0f64, [fbend(0u64, 3.0f64, 90u64)]))
def ck_bad_fin__want() -> String:
  "no:degenerate-feature"
def ck_order__got() -> String:
  cks(sc100([fbend(9u64, 3.0f64, 45u64)]))
def ck_order__want() -> String:
  "no:bend-angle-not-certified"
def k_zone__got() -> String:
  fb(SH.k_ok(0.3f64, 0.5f64)) ++ "/" ++ fb(SH.k_ok(0.0f64, 0.5f64)) ++ "/" ++ fb(SH.k_ok(0.5f64, 1.0f64)) ++
    "/" ++ fb(SH.k_ok(0.6f64, 0.4f64)) ++ "/" ++ fb(SH.k_ok(0.5f64, 0.5f64))
def k_zone__want() -> String:
  "1/0/0/0/1"
def rt_bound__got() -> String:
  fb(SH.rt_ok(SH.rt_min(), 1.0f64)) ++ "/" ++ fb(SH.rt_ok(E.f64_next_down(SH.rt_min()), 1.0f64)) ++ "/" ++
    fb(SH.rt_ok(2.0f64, 1.0f64))
def rt_bound__want() -> String:
  "1/0/1"
def size_bound__got() -> String:
  fb(SH.size_ok(0u64, 10.0f64, 2.0f64, 3.0f64)) ++ "/" ++
    fb(SH.size_ok(0u64, E.f64_next_up(10.0f64), 2.0f64, 3.0f64)) ++ "/" ++ fb(SH.size_ok(6u64, 10.0f64, 2.0f64, 3.0f64))
def size_bound__want() -> String:
  "0/1/1"
def len_bound__got() -> String:
  fb(SH.len_ok(6u64, 100.0f64, 2.0f64, 3.0f64, 100.0f64, True{})) ++ "/" ++
    fb(SH.len_ok(6u64, 100.0f64, 2.0f64, 3.0f64, E.f64_next_down(100.0f64), True{})) ++ "/" ++
    fb(SH.len_ok(0u64, 100.0f64, 2.0f64, 3.0f64, 100.0f64, True{}))
def len_bound__want() -> String:
  "0/1/1"
def ang_edge_table__got() -> String:
  fb(SH.ang_ok(90u64)) ++ fb(SH.ang_ok(180u64)) ++ fb(SH.ang_ok(45u64)) ++ fb(SH.ang_ok(0u64)) ++ "/" ++
    fb(SH.edge_ok(0u64)) ++ fb(SH.edge_ok(3u64)) ++ fb(SH.edge_ok(4u64))
def ang_edge_table__want() -> String:
  "1100/110"
def prof_single0__got() -> String:
  kp_tag(SH.sc_prof(sc100([fbend(0u64, 3.0f64, 90u64)])))
def prof_single0__want() -> String:
  "0/0"
def prof_single3__got() -> String:
  kp_tag(SH.sc_prof(sc100([fbend(3u64, 3.0f64, 90u64)])))
def prof_single3__want() -> String:
  "0/1"
def prof_180_2__got() -> String:
  kp_tag(SH.sc_prof(sc100([fbend(2u64, 3.0f64, 180u64)])))
def prof_180_2__want() -> String:
  "3/1"
def prof_u__got() -> String:
  kp_tag(SH.sc_prof(sc100([fbend(0u64, 3.0f64, 90u64), fbend(2u64, 3.0f64, 90u64)])))
def prof_u__want() -> String:
  "4/0"
def prof_udn__got() -> String:
  kp_tag(SH.sc_prof(sc100([fbend(1u64, 3.0f64, 90u64), fbend(3u64, 3.0f64, 90u64)])))
def prof_udn__want() -> String:
  "4/1"
def prof_hem2__got() -> String:
  kp_tag(SH.sc_prof(sc100([fhem(2u64, 10.0f64)])))
def prof_hem2__want() -> String:
  "7/1"
def prof_tip__got() -> String:
  kp_tag(SH.sc_prof(sc100([fbend(0u64, 3.0f64, 90u64), fhem(0u64, 10.0f64)])))
def prof_tip__want() -> String:
  "8/0"
def prof_tip3__got() -> String:
  kp_tag(SH.sc_prof(sc100([fbend(3u64, 3.0f64, 90u64), fhem(2u64, 10.0f64)])))
def prof_tip3__want() -> String:
  "9/1"
def prof_tipu__got() -> String:
  kp_tag(SH.sc_prof(sc100([fbend(0u64, 3.0f64, 90u64), fbend(2u64, 3.0f64, 90u64), fhem(2u64, 10.0f64)])))
def prof_tipu__want() -> String:
  "11/0"
def prof_tipud__got() -> String:
  kp_tag(SH.sc_prof(sc100([fbend(1u64, 3.0f64, 90u64), fbend(3u64, 3.0f64, 90u64), fhem(0u64, 10.0f64)])))
def prof_tipud__want() -> String:
  "11/1"
def prof_flat__got() -> String:
  kp_tag(SH.sc_prof(sc100([])))
def prof_flat__want() -> String:
  "254/0"
def prof_badb__got() -> String:
  kp_tag(SH.sc_prof(SH.SC_bad{}))
def prof_badb__want() -> String:
  "255/0"
def prof_deep__got() -> String:
  kp_tag(SH.sc_prof(sc100([fbend(0u64, 3.0f64, 90u64), fbend(2u64, 3.0f64, 90u64), fhem(0u64, 10.0f64), fhem(2u64, 10.0f64)])))
def prof_deep__want() -> String:
  "4/0"
def pk_map__got() -> String:
  pk_tag(SH.pk_of_k(5u64)) ++ "/" ++ pk_tag(SH.pk_of_k(11u64)) ++ "/" ++ pk_tag(SH.pk_of_k(255u64)) ++ "/" ++
    pk_tag(SH.pk_of_k(99u64))
def pk_map__want() -> String:
  "5/11/0/0"
def counts_k0__got() -> String:
  prof_counts(SH.sh_prof(SH.K0{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64)))
def counts_k0__want() -> String:
  "7/8"
def counts_k2__got() -> String:
  prof_counts(SH.sh_prof(SH.K2{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64)))
def counts_k2__want() -> String:
  "7/8"
def counts_k4__got() -> String:
  prof_counts(SH.sh_prof(SH.K4{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64)))
def counts_k4__want() -> String:
  "11/12"
def counts_k6__got() -> String:
  prof_counts(SH.sh_prof(SH.K6{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64)))
def counts_k6__want() -> String:
  "5/6"
def counts_k8__got() -> String:
  prof_counts(SH.sh_prof(SH.K8{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64)))
def counts_k8__want() -> String:
  "9/10"
def counts_k10__got() -> String:
  prof_counts(SH.sh_prof(SH.K10{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64)))
def counts_k10__want() -> String:
  "13/14"
def arcs_all__got() -> String:
  prof_arcs(SH.sh_prof(SH.K0{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64))) ++ "/" ++
    prof_arcs(SH.sh_prof(SH.K2{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64))) ++ "/" ++
    prof_arcs(SH.sh_prof(SH.K4{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64))) ++ "/" ++
    prof_arcs(SH.sh_prof(SH.K6{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64)))
def arcs_all__want() -> String:
  "2/2/4/0"
def rot_counts__got() -> String:
  +p = SH.sh_prof(SH.K0{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64))
  +q = SH.rot180(p, xk(100.0f64), xk(50.0f64))
  prof_counts(p) ++ "/" ++ prof_counts(q)
def rot_counts__want() -> String:
  "7/8/7/8"
def rg_start(+o: F.Loop) -> String:
  match o:
    case F.L_path{+x, +y, +ss}:
      Nat.show(List.length(&2, F.Seg, ss)) ++ "/" ++ fbits(X.xp_ev(x, env0())) ++ "/" ++ fbits(X.xp_ev(y, env0()))
    case F.L_circ{+cx, +cy, +r}: "circ"
def rg_info(+rg: F.Region) -> String:
  F.Rg{+o, +hs} = rg
  rg_start(o)
def rg_segs(+rg: F.Region) -> String:
  F.Rg{+o, +hs} = rg
  match o:
    case F.L_path{+x, +y, +ss}: Nat.show(List.length(&2, F.Seg, ss))
    case F.L_circ{+cx, +cy, +r}: "circ"
def rg_k0__got() -> String:
  rg_info(SH.to_region(SH.sh_prof(SH.K0{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64))))
def rg_k0__want() -> String:
  "7/0/0"
def rg_k6__got() -> String:
  rg_segs(SH.to_region(SH.sh_prof(SH.K6{}, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64))))
def rg_k6__want() -> String:
  "5"
def vol_k0__got() -> String:
  fbits(SH.sh_vol(0u64, 100.0f64, 2.0f64, 3.0f64, 50.0f64, 10.0f64))
def vol_k0__want() -> String:
  "4666793716325635124"
def vol_k2__got() -> String:
  fbits(SH.sh_vol(2u64, 100.0f64, 2.0f64, 3.0f64, 50.0f64, 10.0f64))
def vol_k2__want() -> String:
  "4667139138090870887"
def vol_k4__got() -> String:
  fbits(SH.sh_vol(4u64, 100.0f64, 2.0f64, 3.0f64, 50.0f64, 10.0f64))
def vol_k4__want() -> String:
  "4669338161346422888"
def vol_k6__got() -> String:
  fbits(SH.sh_vol(6u64, 100.0f64, 2.0f64, 3.0f64, 50.0f64, 10.0f64))
def vol_k6__want() -> String:
  "4667272928281231360"
def vol_k8__got() -> String:
  fbits(SH.sh_vol(8u64, 100.0f64, 2.0f64, 3.0f64, 50.0f64, 10.0f64))
def vol_k8__want() -> String:
  "4667343472139523124"
def vol_k10__got() -> String:
  fbits(SH.sh_vol(10u64, 100.0f64, 2.0f64, 3.0f64, 50.0f64, 10.0f64))
def vol_k10__want() -> String:
  "4669887917160310888"
def vol_flat__got() -> String:
  fbits(SH.sh_vol(254u64, 100.0f64, 2.0f64, 3.0f64, 50.0f64, 10.0f64))
def vol_flat__want() -> String:
  "4666723172467343360"
def allow90__got() -> String:
  ib_tag(SH.allow_i(90u64, 3.0f64, 2.0f64, 0.3f64, 0.5f64))
def allow90__want() -> String:
  "4618052832404213495/4618760256179416350"
def allow180__got() -> String:
  ib_tag(SH.allow_i(180u64, 3.0f64, 2.0f64, 0.3f64, 0.5f64))
def allow180__want() -> String:
  "4622556432031583991/4623263855806786846"
def allow_mono__got() -> String:
  +a = SH.allow_i(90u64, 3.0f64, 2.0f64, 0.3f64, 0.5f64)
  +b = SH.allow_i(180u64, 3.0f64, 2.0f64, 0.3f64, 0.5f64)
  fb(F64.is_le(I.i_lo(a), I.i_hi(a))) ++ "/" ++ fb(F64.is_le(I.i_lo(b), I.i_hi(b)))
def allow_mono__want() -> String:
  "1/1"
def rows_2__got() -> String:
  +e = env0()
  +rows = SH.flat_rows(SH.bns_of([fbend(0u64, 3.0f64, 90u64), fbend(2u64, 3.0f64, 90u64)], e), 2.0f64, 0.3f64, 0.5f64)
  Nat.show(List.length(&2, SH.FR, rows))
def rows_2__want() -> String:
  "2"
def rows_0__got() -> String:
  Nat.show(List.length(&2, SH.FR, SH.flat_rows([], 2.0f64, 0.3f64, 0.5f64)))
def rows_0__want() -> String:
  "0"
def row_head(rs: List<&2, SH.FR>) -> String:
  match rs:
    case []: "empty"
    case +f <> t: fr_tag(f)
def row0_tag__got() -> String:
  +e = env0()
  row_head(SH.flat_rows(SH.bns_of([fbend(0u64, 3.0f64, 90u64)], e), 2.0f64, 0.3f64, 0.5f64))
def row0_tag__want() -> String:
  "fr:0/0/90/4613937818241073152/4618052832404213495/4618760256179416350"
def legs_flat__got() -> String:
  legs_bits(sc100([]))
def legs_flat__want() -> String:
  "4636737291354636288"
def legs_k0__got() -> String:
  legs_bits(sc100([fbend(0u64, 3.0f64, 90u64)]))
def legs_k0__want() -> String:
  "4632233691727265792/4631530004285489152"
def legs_k4__got() -> String:
  legs_bits(sc100([fbend(0u64, 3.0f64, 90u64), fbend(2u64, 3.0f64, 90u64)]))
def legs_k4__want() -> String:
  "4627026404658118656/4636033603912859648/4627026404658118656"
def legs_k8__got() -> String:
  legs_bits(sc100([fbend(0u64, 3.0f64, 90u64), fhem(0u64, 10.0f64)]))
def legs_k8__want() -> String:
  "4632233691727265792/4630122629401935872/4611686018427387904/4621819117588971520/4621819117588971520"
def legs_k10__got() -> String:
  legs_bits(sc100([fbend(0u64, 3.0f64, 90u64), fbend(2u64, 3.0f64, 90u64), fhem(0u64, 10.0f64)]))
def legs_k10__want() -> String:
  "4623226492472524800/4611686018427387904/4621819117588971520/4621819117588971520/4636033603912859648/4627026404658118656"
def dev_k0__got() -> String:
  ib_tag(dev_of(sc100([fbend(0u64, 3.0f64, 90u64)]), 0.3f64, 0.5f64))
def dev_k0__want() -> String:
  "4636783373507299565/4636827587493249748"
def dev_flat__got() -> String:
  ib_tag(dev_of(sc100([]), 0.3f64, 0.5f64))
def dev_flat__want() -> String:
  "4636737291354636287/4636737291354636289"
def opw_tags__got() -> String:
  +e = env0()
  Nat.show(List.length(&2, U64, M.op_w(M.O_flat{xk(1.0f64), xk(1.0f64), xk(1.0f64)}, e))) ++ "/" ++
    U64.show(M.op_base(M.O_bend{7u64, 0u64, xk(1.0f64), 90u64})) ++ "/" ++ opnm(M.O_hem{7u64, 0u64, xk(1.0f64)})
def opw_tags__want() -> String:
  "7/7/hem"
def w_head(ws: List<&2, U64>) -> String:
  match ws:
    case []: "empty"
    case +h <> t: U64.show(h)
def opw_head__got() -> String:
  w_head(M.op_w(M.O_flat{xk(1.0f64), xk(1.0f64), xk(1.0f64)}, env0()))
def opw_head__want() -> String:
  "32"
def opw_head_b__got() -> String:
  w_head(M.op_w(M.O_bend{7u64, 0u64, xk(1.0f64), 90u64}, env0()))
def opw_head_b__want() -> String:
  "33"
def opw_head_h__got() -> String:
  w_head(M.op_w(M.O_hem{7u64, 0u64, xk(1.0f64)}, env0()))
def opw_head_h__want() -> String:
  "34"
def opname_base__got() -> String:
  opnm(M.O_flat{xk(1.0f64), xk(1.0f64), xk(1.0f64)}) ++ "/" ++ opnm(M.O_bend{7u64, 0u64, xk(1.0f64), 90u64}) ++ "/" ++
    U64.show(M.op_base(M.O_flat{xk(1.0f64), xk(1.0f64), xk(1.0f64)})) ++ "/" ++ fb(M.op_has_base(M.O_flat{xk(1.0f64), xk(1.0f64), xk(1.0f64)})) ++
    fb(M.op_has_base(M.O_bend{7u64, 0u64, xk(1.0f64), 90u64}))
def opname_base__want() -> String:
  "flat/bend/0/01"
def parse_flat__got() -> String:
  parsed(sl([sa("flat"), sa("100"), sa("50"), sa("2")]))
def parse_flat__want() -> String:
  "flat"
def parse_bend__got() -> String:
  parsed(sl([sa("bend"), sa("1"), sl([sa("edge"), sa("0")]), sa("2"), sa("90")]))
def parse_bend__want() -> String:
  "bend"
def parse_hem__got() -> String:
  parsed(sl([sa("hem"), sa("1"), sl([sa("edge"), sa("0")]), sa("10")]))
def parse_hem__want() -> String:
  "hem"
def parse_badlen__got() -> String:
  parsed(sl([sa("bend"), sa("1"), sa("2"), sa("3")]))
def parse_badlen__want() -> String:
  "unknown"
def parse_baddeg__got() -> String:
  parsed(sl([sa("bend"), sa("1"), sl([sa("edge"), sa("0")]), sa("2"), sa("x")]))
def parse_baddeg__want() -> String:
  "unknown"
def parse_badedge__got() -> String:
  parsed(sl([sa("hem"), sa("1"), sa("0"), sa("10")]))
def parse_badedge__want() -> String:
  "unknown"
def round_flat__got() -> String:
  shown(sl([sa("flat"), sa("100"), sa("50"), sa("2")]))
def round_flat__want() -> String:
  "(flat 100 50 2)"
def round_bend__got() -> String:
  shown(sl([sa("bend"), sa("1"), sl([sa("edge"), sa("0")]), sa("2"), sa("90")]))
def round_bend__want() -> String:
  "(bend 1 (edge 0) 2 90)"
def round_hem__got() -> String:
  shown(sl([sa("hem"), sa("1"), sl([sa("edge"), sa("0")]), sa("10")]))
def round_hem__want() -> String:
  "(hem 1 (edge 0) 10)"
def is_feat__got() -> String:
  fb(S.op_is_sheet("flat")) ++ fb(S.op_is_sheet("bend")) ++ fb(S.op_is_sheet("hem")) ++ fb(S.op_is_feat("flat")) ++
    fb(S.op_is_feat("sweep"))
def is_feat__want() -> String:
  "11101"
def k_go_tag__got() -> String:
  gr_tag(SH.k_go(False{}, 0.6f64, 0.4f64))
def k_go_tag__want() -> String:
  "no:bad-k-zone"
def u_bits_eq__got() -> String:
  +e = env0()
  fb(SH.u_full(0u64, 2u64, 90u64, 90u64, X.X_add{xk(1.0f64), xk(2.0f64)}, xk(3.0f64), e))
def u_bits_eq__want() -> String:
  "1"
def first_ar_go(ss: List<&2, SH.Sg>) -> String:
  match ss:
    case []: "none"
    case +s <> t:
      match s:
        case SH.Sg_ln{+a, +b}: first_ar_go(t)
        case SH.Sg_ar{+a, +cx, +cy, +r, +b, +ccw}: fbits(X.xp_ev(cx, env0())) ++ "/" ++ fbits(X.xp_ev(cy, env0()))
def pr_segs(+p: SH.PR) -> List<&2, SH.Sg>:
  SH.PR{+pts, +segs} = p
  segs
def rot_arc(+k: U64) -> String:
  first_ar_go(pr_segs(SH.rot180(SH.sh_prof(SH.pk_of_k(k), xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64)),
    SH.prof_w(k, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64)),
    SH.prof_h(k, xk(100.0f64), xk(2.0f64), xk(3.0f64), xk(10.0f64)))))
def rot_k0__got() -> String:
  rot_arc(0u64)
def rot_k0__want() -> String:
  "4617315517961601024/4631530004285489152"
def rot_k2__got() -> String:
  rot_arc(2u64)
def rot_k2__want() -> String:
  "4617315517961601024/4617315517961601024"
