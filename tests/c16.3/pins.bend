import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as B4
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c06/xp.bend as X
import ../../src/c06/build.bend as BD
import ../../src/c06/iv.bend as I
import ../../src/c16/blade.bend as BA

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
def ibits(+a: I.I) -> String:
  fbits(I.i_lo(a)) ++ "/" ++ fbits(I.i_hi(a))
def sa(+s: String) -> S.Sx:
  S.Sx_a{s}
def sl(+xs: List<&2, S.Sx>) -> S.Sx:
  S.Sx_l{xs}
def opnm(o: M.Op) -> String:
  M.op_name(o)
def parsed(+x: S.Sx) -> String:
  opnm(S.op_of(x, []))
def shown(+x: S.Sx) -> String:
  S.sx_show(S.op_sx(S.op_of(x, []), []))
def gr_s(+g: BA.GR) -> String:
  match g:
    case BA.GR_ok{}: "ok"
    case BA.GR_no{+why, +fix}: "no:" ++ why ++ " | " ++ fix
def uhd(+xs: List<&2, U64>) -> U64:
  match xs:
    case []: 0u64
    case +h <> t: h
def tok_man(+bt: BD.Bt) -> String:
  BD.Bt{+b, +fns} = bt
  fb(Ty.tres_ok(B4.brep_checked(b, Ty.P_manifold_solid{}, M.fuel_of(b))))
def stagev(+b: Ty.Brep, +fuel: Nat) -> String:
  fb(Ty.okd_ok(B4.brep_incid_c(b, fuel))) ++ fb(Ty.okd_ok(B4.brep_use_c(b, Ty.P_manifold_solid{}, fuel))) ++
    fb(Ty.okd_ok(B4.brep_loop_c(b, fuel))) ++ fb(Ty.okd_ok(B4.brep_facekind_c(b, fuel))) ++
    fb(Ty.okd_ok(B4.brep_prof_c(b, Ty.P_manifold_solid{}, fuel))) ++ fb(Ty.okd_ok(B4.brep_embed_c(b, fuel))) ++
    fb(Ty.okd_ok(B4.brep_link_c(b, Ty.P_manifold_solid{}, fuel))) ++ fb(Ty.okd_ok(B4.brep_conn_c(b, fuel))) ++
    fb(Ty.okd_ok(B4.brep_coin_c(b, fuel))) ++ fb(Ty.okd_ok(B4.brep_xing_c(b, fuel))) ++
    fb(Ty.okd_ok(B4.brep_orient_c(b, fuel)))
def stv_man(+bt: BD.Bt) -> String:
  BD.Bt{+b, +fns} = bt
  stagev(b, M.fuel_of(b))
def s0012() -> BA.Sec:
  BA.Sec{0u64, 0u64, 12u64, 100.0f64, 17n}
def s4412() -> BA.Sec:
  BA.Sec{4u64, 4u64, 12u64, 100.0f64, 17n}
def s0006() -> BA.Sec:
  BA.Sec{0u64, 0u64, 6u64, 100.0f64, 17n}
def s0012_33() -> BA.Sec:
  BA.Sec{0u64, 0u64, 12u64, 100.0f64, 33n}
def s0012_65() -> BA.Sec:
  BA.Sec{0u64, 0u64, 12u64, 100.0f64, 65n}
def ses2() -> List<&2, BA.SecE>:
  BA.place_secs([s0012(), s0012()], 50.0f64, 0u64, 100u64)
def ses2c() -> List<&2, BA.SecE>:
  BA.place_secs([s4412(), s4412()], 50.0f64, 0u64, 100u64)
def ses2t() -> List<&2, BA.SecE>:
  BA.place_secs([s0012(), s0012()], 50.0f64, 0u64, 50u64)
def se0(+ss: List<&2, BA.SecE>) -> BA.SecE:
  BA.se_at(ss, 0n)
def ip_s(+p: BA.IP) -> String:
  ibits(BA.ip_x(p)) ++ "/" ++ ibits(BA.ip_y(p))
def adm_digits__got() -> String:
  fb(BA.dg_ok(0u64, 0u64, 12u64)) ++ "/" ++ fb(BA.dg_ok(4u64, 4u64, 12u64)) ++ "/" ++
    fb(BA.dg_ok(10u64, 4u64, 12u64)) ++ "/" ++ fb(BA.dg_ok(4u64, 10u64, 12u64)) ++ "/" ++
    fb(BA.dg_ok(2u64, 0u64, 12u64)) ++ "/" ++ fb(BA.dg_ok(0u64, 0u64, 5u64)) ++ "/" ++
    fb(BA.dg_ok(0u64, 0u64, 25u64)) ++ "/" ++ fb(BA.dg_ok(0u64, 0u64, 6u64)) ++ "/" ++
    fb(BA.dg_ok(0u64, 9u64, 24u64))
def adm_digits__want() -> String:
  "1/1/0/0/0/0/0/1/1"
def adm_npts__got() -> String:
  fb(BA.np_ok(17u64)) ++ "/" ++ fb(BA.np_ok(33u64)) ++ "/" ++ fb(BA.np_ok(65u64)) ++ "/" ++
    fb(BA.np_ok(16u64)) ++ "/" ++ fb(BA.np_ok(25u64)) ++ "/" ++ fb(BA.np_ok(0u64))
def adm_npts__want() -> String:
  "1/1/1/0/0/0"
def adm_tw__got() -> String:
  fb(BA.tw_ok(0u64)) ++ "/" ++ fb(BA.tw_ok(10u64)) ++ "/" ++ fb(BA.tw_ok(20u64)) ++ "/" ++
    fb(BA.tw_ok(30u64)) ++ "/" ++ fb(BA.tw_ok(45u64)) ++ "/" ++ fb(BA.tw_ok(5u64))
def adm_tw__want() -> String:
  "1/1/1/1/0/0"
def adm_tp__got() -> String:
  fb(BA.tp_ok(50u64)) ++ "/" ++ fb(BA.tp_ok(75u64)) ++ "/" ++ fb(BA.tp_ok(100u64)) ++ "/" ++
    fb(BA.tp_ok(33u64)) ++ "/" ++ fb(BA.tp_ok(0u64))
def adm_tp__want() -> String:
  "1/1/1/0/0"
def adm_ns__got() -> String:
  fb(BA.ns_ok(1n)) ++ "/" ++ fb(BA.ns_ok(2n)) ++ "/" ++ fb(BA.ns_ok(5n)) ++ "/" ++ fb(BA.ns_ok(8n)) ++
    "/" ++ fb(BA.ns_ok(9n))
def adm_ns__want() -> String:
  "0/1/1/1/0"
def ring_m__got() -> String:
  Nat.show(BA.ring_m(17n)) ++ "/" ++ Nat.show(BA.ring_m(33n)) ++ "/" ++ Nat.show(BA.ring_m(65n))
def ring_m__want() -> String:
  "32/64/128"
def ring_next__got() -> String:
  Nat.show(BA.ring_next(32n, 31n)) ++ "/" ++ Nat.show(BA.ring_next(32n, 0n)) ++ "/" ++
    Nat.show(BA.ring_next(64n, 63n))
def ring_next__want() -> String:
  "0/1/0"
def stn_te0012__got() -> String:
  ip_s(BA.ring_ip(s0012(), 0n))
def stn_te0012__want() -> String:
  "4607182418800017406/4607182418800017410/13603122674472583176/4379750637617807368"
def stn_le0012__got() -> String:
  ip_s(BA.ring_ip(s0012(), 16n))
def stn_le0012__want() -> String:
  "9223372036854775812/4/9223372036854775816/2177153190293537324"
def stn_mid0012__got() -> String:
  ip_s(BA.ring_ip(s0012(), 8n))
def stn_mid0012__want() -> String:
  "4602678819172646910/4602678819172646914/4587778966338579003/4587778966338579071"
def stn_lo0012__got() -> String:
  ip_s(BA.ring_ip(s0012(), 24n))
def stn_lo0012__want() -> String:
  "4602678819172646910/4602678819172646914/13811151003193354879/13811151003193354811"
def stn_te4412__got() -> String:
  ip_s(BA.ring_ip(s4412(), 0n))
def stn_te4412__want() -> String:
  "4607182418800017405/4607182418800017410/13604689715303197109/4381317678448421301"
def stn_le4412__got() -> String:
  ip_s(BA.ring_ip(s4412(), 16n))
def stn_le4412__want() -> String:
  "11390134684695158512/5/9223372036854775818/2177028553770759842"
def stn_mid4412__got() -> String:
  ip_s(BA.ring_ip(s4412(), 8n))
def stn_mid4412__want() -> String:
  "4602689397318446413/4602689397318446417/4591274792919127473/4591274792919127529"
def stn_lo4412__got() -> String:
  ip_s(BA.ring_ip(s4412(), 24n))
def stn_lo4412__want() -> String:
  "4602657662881047905/4602657662881047910/13802572800393263773/13802572800393263339"
def stn_65__got() -> String:
  ip_s(BA.ring_ip(s0012_65(), 0n)) ++ "|" ++ ip_s(BA.ring_ip(s0012_65(), 64n)) ++ "|" ++
    ip_s(BA.ring_ip(s0012_65(), 96n))
def stn_65__want() -> String:
  "4607182418800017406/4607182418800017410/13603122674472583176/4379750637617807368|9223372036854775812/4/9223372036854775816/2177153190293537324|4602678819172646910/4602678819172646914/13811151003193354879/13811151003193354811"
def area0012__got() -> String:
  ibits(BA.sec_area(se0(ses2()), 32n))
def area0012__want() -> String:
  "4650292367448465610/4650292367448466951"
def area4412__got() -> String:
  ibits(BA.sec_area(se0(ses2c()), 32n))
def area4412__want() -> String:
  "4650315505790939155/4650315505790941346"
def cen0012__got() -> String:
  ip_s(BA.sec_cen(se0(ses2()), 32n, BA.sec_area(se0(ses2()), 32n)))
def cen0012__want() -> String:
  "4631147839049416001/4631147839049418399/13641122013403060835/4417754988108030726"
def cen4412__got() -> String:
  ip_s(BA.sec_cen(se0(ses2c()), 32n, BA.sec_area(se0(ses2c()), 32n)))
def cen4412__want() -> String:
  "4631141611326735642/4631141611326739514/4614259903683363955/4614259903683367972"
def th0012__got() -> String:
  ip_s(BA.sec_th(se0(ses2())))
def th0012__want() -> String:
  "4588803352573229958/4588803352573230003/0/0"
def th4412__got() -> String:
  ip_s(BA.sec_th(se0(ses2c())))
def th4412__want() -> String:
  "4588803352573229958/4588803352573230003/4585902910560691799/4585902910560691833"
def th0006__got() -> String:
  ip_s(BA.sec_th(se0(BA.place_secs([s0006(), s0006()], 50.0f64, 0u64, 100u64))))
def th0006__want() -> String:
  "4584299752945859462/4584299752945859507/0/0"
def vol_slab__got() -> String:
  +ses = BA.place_secs([s0012(), s0012()], 1.0f64, 0u64, 100u64)
  +v = BA.blade_vol_I(ses, 32n, 1.0f64, 2n)
  ibits(v) ++ "/" ++ fbits(I.imid(v))
def vol_slab__want() -> String:
  "4650292367448465583/4650292367448466977/4650292367448466280"
def vol_blade2__got() -> String:
  +v = BA.blade_vol_I(ses2(), 32n, 50.0f64, 2n)
  ibits(v) ++ "/" ++ fbits(I.imid(v))
def vol_blade2__want() -> String:
  "4675764963293738888/4675764963293739977/4675764963293739432"
def vol_taper__got() -> String:
  +v = BA.blade_vol_I(ses2t(), 32n, 50.0f64, 2n)
  ibits(v) ++ "/" ++ fbits(I.imid(v))
def vol_taper__want() -> String:
  "4672183388618124123/4672183388618125444/4672183388618124784"
def dev_taper__got() -> String:
  ibits(BA.dev_of(ses2t()))
def dev_taper__want() -> String:
  "4623226492472524784/4623226492472524820"
def dev_plain__got() -> String:
  ibits(BA.dev_of(ses2()))
def dev_plain__want() -> String:
  "9223372036854775809/4403394535661502467"
def angs20__got() -> String:
  BA.angs_s(20u64, 5n)
def angs20__want() -> String:
  "0 5 10 15 20 "
def angs30__got() -> String:
  BA.angs_s(30u64, 5n)
def angs30__want() -> String:
  "0 7.5 15 22.5 30 "
def counts_2_17__got() -> String:
  Nat.show(List.length(&2, Ty.Vertex, BA.blade_vs(ses2(), 2n, 32n))) ++ "/" ++
    Nat.show(List.length(&2, Ty.Edge, BA.blade_es(ses2(), 2n, 32n))) ++ "/" ++
    Nat.show(List.length(&2, BD.FS, BA.blade_fs(ses2(), 2n, 32n, 1u64, 0.0f64, 50.0f64)))
def counts_2_17__want() -> String:
  "64/96/34"
def rows_len__got() -> String:
  Nat.show(List.length(&2, BA.BR,
    BA.blade_rows(BA.place_secs([s0012(), s0012(), s0012(), s0012(), s0012()], 200.0f64, 20u64, 75u64),
      32n)))
def rows_len__want() -> String:
  "5"
def gr_digits__got() -> String:
  gr_s(BA.dg_go(False{}))
def gr_digits__want() -> String:
  "no:naca-digits-not-admitted | use M 0-9, P 0-9 with P nonzero when M is nonzero, T 06-24"
def gr_points__got() -> String:
  gr_s(BA.np_go(False{}))
def gr_points__want() -> String:
  "no:naca-points-not-admitted | use 17, 33 or 65 points per surface"
def gr_secs__got() -> String:
  gr_s(BA.ns_go(False{}))
def gr_secs__want() -> String:
  "no:blade-sections-not-admitted | stack 2 to 8 naca4 sections"
def gr_twist__got() -> String:
  gr_s(BA.tw_go(False{}, 45u64))
def gr_twist__want() -> String:
  "no:twist-not-admitted | twist 0, 10, 20 or 30 degrees"
def gr_taper__got() -> String:
  gr_s(BA.tp_go(False{}, 33u64))
def gr_taper__want() -> String:
  "no:taper-not-admitted | taper 50, 75 or 100 tip-chord percent"
def gr_ruled__got() -> String:
  gr_s(BA.rl_go(False{}))
def gr_ruled__want() -> String:
  "no:blade-stack-not-ruled | stack admitted naca4 sections with equal points and chord"
def gr_blade__got() -> String:
  gr_s(BA.bl_go(False{}))
def gr_blade__want() -> String:
  "no:blade-needs-blade | run blade on a blade node"
def gr_fin__got() -> String:
  gr_s(BA.fin_go(False{}))
def gr_fin__want() -> String:
  "no:degenerate-feature | give finite positive chord and span"
def op_tags__got() -> String:
  +e = env0()
  U64.show(uhd(M.op_w(M.O_naca4{0u64, 0u64, 12u64, xk(100.0f64), 17u64}, e))) ++ "/" ++
    U64.show(uhd(M.op_w(M.O_blade{[1u64, 2u64], xk(50.0f64), 20u64, 75u64}, e)))
def op_tags__want() -> String:
  "39/40"
def op_names__got() -> String:
  opnm(M.O_naca4{0u64, 0u64, 12u64, xk(100.0f64), 17u64}) ++ "/" ++
    opnm(M.O_blade{[1u64, 2u64], xk(50.0f64), 20u64, 75u64})
def op_names__want() -> String:
  "naca4/blade"
def op_base__got() -> String:
  U64.show(M.op_base(M.O_blade{[1u64, 2u64], xk(50.0f64), 20u64, 75u64})) ++ "/" ++
    fb(M.op_has_base(M.O_blade{[1u64, 2u64], xk(50.0f64), 20u64, 75u64})) ++ "/" ++
    fb(M.op_has_base(M.O_naca4{0u64, 0u64, 12u64, xk(100.0f64), 17u64}))
def op_base__want() -> String:
  "0/0/0"
def parse_naca__got() -> String:
  parsed(sl([sa("naca4"), sa("0"), sa("0"), sa("12"), sa("100"), sa("17")]))
def parse_naca__want() -> String:
  "naca4"
def parse_blade__got() -> String:
  parsed(sl([sa("blade"), sa("1"), sa("2"), sa("50"), sa("20"), sa("75")]))
def parse_blade__want() -> String:
  "blade"
def parse_bad__got() -> String:
  parsed(sl([sa("naca4"), sa("0")])) ++ "/" ++ parsed(sl([sa("blade"), sa("50"), sa("0"), sa("100")])) ++
    "/" ++ parsed(sl([sa("blade"), sa("a"), sa("2"), sa("50"), sa("0"), sa("100")]))
def parse_bad__want() -> String:
  "unknown/unknown/unknown"
def show_naca__got() -> String:
  shown(sl([sa("naca4"), sa("0"), sa("0"), sa("12"), sa("100"), sa("17")]))
def show_naca__want() -> String:
  "(naca4 0 0 12 100 17)"
def show_blade__got() -> String:
  shown(sl([sa("blade"), sa("1"), sa("2"), sa("3"), sa("50"), sa("20"), sa("75")]))
def show_blade__want() -> String:
  "(blade 1 2 3 50 20 75)"
def tok_blade__got() -> String:
  +ses = ses2()
  tok_man(BA.blade_bt(ses, 2n, 32n, 1u64, I.imid(BA.se_z(BA.se_at(ses, 0n))),
    I.imid(BA.se_z(BA.se_at(ses, 1n)))))
def tok_blade__want() -> String:
  "1"
def stv_blade__got() -> String:
  +ses = ses2()
  stv_man(BA.blade_bt(ses, 2n, 32n, 1u64, I.imid(BA.se_z(BA.se_at(ses, 0n))),
    I.imid(BA.se_z(BA.se_at(ses, 1n)))))
def stv_blade__want() -> String:
  "11111111111"
def ruled__got() -> String:
  fb(BA.ruled_ok(BA.secs_of([BA.NA{0u64, 0u64, 12u64, xk(100.0f64), 17u64},
    BA.NA{4u64, 4u64, 12u64, xk(100.0f64), 17u64}], env0()))) ++ "/" ++
    fb(BA.ruled_ok(BA.secs_of([BA.NA{0u64, 0u64, 12u64, xk(100.0f64), 17u64},
      BA.NA{0u64, 0u64, 12u64, xk(100.0f64), 33u64}], env0()))) ++ "/" ++
    fb(BA.ruled_ok(BA.secs_of([BA.NA{0u64, 0u64, 12u64, xk(100.0f64), 17u64},
      BA.NA{0u64, 0u64, 12u64, xk(50.0f64), 17u64}], env0())))
def ruled__want() -> String:
  "1/0/0"
