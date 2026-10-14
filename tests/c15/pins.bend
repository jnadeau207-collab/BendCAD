import Base
import ../../src/c15/pmi.bend as PM
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c06/build.bend as BD
import ../../src/c06/iv.bend as I
import ../../src/c11/qdist.bend as QD
import ../../src/c11/qinterf.bend as QI
import ../../src/c11/qaccel.bend as QA
import ../../src/c12/stepw.bend as SW
import ../../src/c12/blob.bend as BL
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty

def ps_xs(+r: S.PS) -> List<&2, S.Sx>:
  S.PS{+ok, +xs} = r
  xs
def part(+src: String) -> M.Part:
  S.part_of(ps_xs(S.parse(src)))
def evcs(+src: String) -> List<&2, M.CE>:
  M.ev_part(part(src), [])
def bod(+src: String, +id: U64) -> M.Body:
  M.nr_body(M.ce_r(M.ce_find(evcs(src), id)))
def btof(+src: String, +id: U64) -> PM.BT:
  PM.bt_of(bod(src, id))
def plof(+src: String, +id: U64) -> M.Pl:
  M.bd_pl(bod(src, id))
def sa(+s: String) -> S.Sx:
  S.Sx_a{s}
def sl(+xs: List<&2, S.Sx>) -> S.Sx:
  S.Sx_l{xs}
def bs(+b: Bool) -> String:
  match b:
    case True{}: "1"
    case False{}: "0"
def fbits(+v: F64) -> String:
  U64.show(F64.bits(v))
def pr_ok(+m: PM.PMI) -> String:
  PM.PMI{+nd, +dts, +dms, +tls, +sts, +sks, +ers} = m
  "ok:" ++ Nat.show(List.length(&2, PM.Datum, dts)) ++ "/" ++
    Nat.show(List.length(&2, PM.Dim, dms)) ++ "/" ++ Nat.show(List.length(&2, PM.Tol, tls)) ++
    "/" ++ Nat.show(List.length(&2, PM.State, sts)) ++ "/" ++
    Nat.show(List.length(&2, PM.Stack, sks))
def pr_tag(+r: PM.PR) -> String:
  match r:
    case PM.PR_ok{+m}: pr_ok(m)
    case PM.PR_err{+why, +fix}: "err:" ++ why
def er_tol(+t: PM.Tol) -> String:
  PM.Tol{+name, +kind, +tv, +sel, +drf} = t
  "tol:" ++ U64.show(kind)
def er_tag(+e: PM.ER) -> String:
  match e:
    case PM.ER_dt{+d}: "dt"
    case PM.ER_dm{+d}: "dm"
    case PM.ER_tol{+t}: er_tol(t)
    case PM.ER_st{+s}: "st"
    case PM.ER_sk{+s}: "sk"
    case PM.ER_err{+why, +fix}: "err:" ++ why
def rv_line(+r: PM.RV) -> String:
  match r:
    case PM.RV_ok{+line}: line
    case PM.RV_bad{+why, +fix}: "BAD:" ++ why ++ "|" ++ fix
def fb_tag(+f: PM.FB) -> String:
  match f:
    case PM.FB_ok{}: "ok"
    case PM.FB_bad{+why, +fix}: "bad:" ++ why
def fr_tag(+r: PM.FR) -> String:
  match r:
    case PM.FR_ok{+s, +n}: "ok:" ++ Nat.show(n)
    case PM.FR_err{+why, +fix}: "err:" ++ why
    case PM.FR_line{+l}: "line:" ++ l
def em_s(+e: PM.EM) -> String:
  PM.EM{+ok, +why, +s, +next, +n, +dm} = e
  s
def em_nn(+e: PM.EM) -> String:
  PM.EM{+ok, +why, +s, +next, +n, +dm} = e
  bs(ok) ++ "/" ++ Nat.show(next) ++ "/" ++ Nat.show(n)
def oe_v(+e: PM.OE, +t: F64) -> U64:
  match e:
    case PM.OE_ok{+lo, +hi}: PM.voe(lo, hi, t)
    case PM.OE_bad{+why, +fix}: 9u64
def oe_bits(+e: PM.OE) -> String:
  match e:
    case PM.OE_ok{+lo, +hi}: fbits(lo) ++ "," ++ fbits(hi)
    case PM.OE_bad{+why, +fix}: "BAD:" ++ why
def sr_bits_st(+st: PM.State, +nom: F64, +lo: F64, +hi: F64) -> String:
  PM.State{+name, +grow} = st
  name ++ "," ++ fbits(nom) ++ "," ++ fbits(lo) ++ "," ++ fbits(hi)
def sr_bits(+r: PM.SR) -> String:
  PM.SR{+st, +nom, +lo, +hi} = r
  sr_bits_st(st, nom, lo, hi)
def ci_bits(+c: PM.CI) -> String:
  PM.CI{+hit, +lo, +hi, +na, +nb} = c
  bs(hit) ++ "," ++ fbits(lo) ++ "," ++ fbits(hi) ++ "," ++ Nat.show(na) ++ "x" ++ Nat.show(nb)
def ds_box() -> String:
  "(param 1 W 10 9.9 10.1) (param 2 H 20 20 20) (node 1 (box W H 30) (intent create 6 0 1 0))"
def ds_pair() -> String:
  ds_box() ++ " (node 2 (box 4 4 4) (intent create 6 0 1 0)) (node 3 (move 2 24 0 0 0) (intent same 0 0 1 0))"
def ds_cyl() -> String:
  "(param 1 R 5 5 5) (node 1 (cylinder R 10) (intent create 3 0 1 0))"
def ds_fail() -> String:
  "(node 1 (box 10 10 10) (intent create 5 0 1 0))"
def dt_a() -> PM.Datum:
  PM.Datum{"A", "n1.c0.top"}
def dts_a() -> List<&2, PM.Datum>:
  [dt_a()]
def dm_w() -> PM.Dim:
  PM.Dim{"dW", 10.0f64, 9.9f64, 10.1f64}
def dm_h() -> PM.Dim:
  PM.Dim{"dH", 20.0f64, 20.0f64, 20.0f64}
def dms_wh() -> List<&2, PM.Dim>:
  [dm_w(), dm_h()]
def st_cold() -> PM.State:
  PM.State{"cold", 1.0f64}
def st_hot() -> PM.State:
  PM.State{"hot", 1.002f64}
def datum_ent__got() -> String:
  er_tag(PM.datum_of(sl([sa("datum"), sa("A"), sa("n1.c0.top")])))
def datum_ent__want() -> String:
  "dt"
def datum_bad__got() -> String:
  er_tag(PM.datum_of(sl([sa("datum"), sa("A")])))
def datum_bad__want() -> String:
  "err:bad-datum"
def datum_quote__got() -> String:
  er_tag(PM.datum_of(sl([sa("datum"), sa("A'B"), sa("n1.c0.top")])))
def datum_quote__want() -> String:
  "err:bad-datum"
def dim_par__got() -> String:
  er_tag(PM.dim_of(sl([sa("dim"), sa("dW"), sa("W")]), part(ds_box())))
def dim_par__want() -> String:
  "dm"
def dim_par_zone__got() -> String:
  rv_line(PM.res_one(PM.dim_of(sl([sa("dim"), sa("dW"), sa("W")]), part(ds_box())), [],
    [], btof(ds_box(), 1u64), plof(ds_box(), 1u64)))
def dim_par_zone__want() -> String:
  "dim dW nominal 10 zone [9.9, 10.1]\n"
def dim_par_quote__got() -> String:
  er_tag(PM.dim_of(sl([sa("dim"), sa("d'W"), sa("W")]), part(ds_box())))
def dim_par_quote__want() -> String:
  "err:bad-dim"
def dim_unknown_par__got() -> String:
  er_tag(PM.dim_of(sl([sa("dim"), sa("dW"), sa("Q")]), part(ds_box())))
def dim_unknown_par__want() -> String:
  "err:unknown-param Q"
def dim_exp__got() -> String:
  er_tag(PM.dim_of(sl([sa("dim"), sa("e"), sa("20"), sa("19.9"), sa("20.1")]), part(ds_box())))
def dim_exp__want() -> String:
  "dm"
def dim_exp_order__got() -> String:
  er_tag(PM.dim_of(sl([sa("dim"), sa("e"), sa("20"), sa("20.1"), sa("19.9")]), part(ds_box())))
def dim_exp_order__want() -> String:
  "err:bad-dim"
def dim_arity__got() -> String:
  er_tag(PM.dim_of(sl([sa("dim"), sa("e")]), part(ds_box())))
def dim_arity__want() -> String:
  "err:bad-dim"
def tol_flat__got() -> String:
  er_tag(PM.tol_of(sl([sa("tol"), sa("t1"), sa("flatness"), sa("0.02"), sa("n1.c0.bottom"), sa("rfs")])))
def tol_flat__want() -> String:
  "tol:1"
def tol_perp__got() -> String:
  er_tag(PM.tol_of(sl([sa("tol"), sa("t2"), sa("perpendicularity"), sa("0.05"),
    sa("n1.c0.wall.0.0"), sa("rfs"), sa("A")])))
def tol_perp__want() -> String:
  "tol:2"
def tol_par__got() -> String:
  er_tag(PM.tol_of(sl([sa("tol"), sa("t3"), sa("parallelism"), sa("0.05"), sa("n1.c0.top"),
    sa("rfs"), sa("A")])))
def tol_par__want() -> String:
  "tol:3"
def tol_kind__got() -> String:
  er_tag(PM.tol_of(sl([sa("tol"), sa("t9"), sa("position"), sa("0.05"), sa("n1.c0.top"), sa("rfs")])))
def tol_kind__want() -> String:
  "err:unsupported-tol-kind position"
def tol_mod__got() -> String:
  er_tag(PM.tol_of(sl([sa("tol"), sa("t9"), sa("flatness"), sa("0.02"), sa("n1.c0.top"), sa("mmc")])))
def tol_mod__want() -> String:
  "err:unsupported-modifier mmc"
def tol_neg__got() -> String:
  er_tag(PM.tol_of(sl([sa("tol"), sa("t9"), sa("flatness"), sa("neg"), sa("n1.c0.top"), sa("rfs")])))
def tol_neg__want() -> String:
  "err:bad-tol"
def tol_arity__got() -> String:
  er_tag(PM.tol_of(sl([sa("tol"), sa("t9")])))
def tol_arity__want() -> String:
  "err:bad-tol"
def state_ok__got() -> String:
  er_tag(PM.st_of(sl([sa("state"), sa("hot"), sa("1.002")])))
def state_ok__want() -> String:
  "st"
def state_grow__got() -> String:
  er_tag(PM.st_of(sl([sa("state"), sa("hot"), sa("0")])))
def state_grow__want() -> String:
  "err:bad-state"
def state_text__got() -> String:
  er_tag(PM.st_of(sl([sa("state"), sa("hot"), sa("fast")])))
def state_text__want() -> String:
  "err:bad-state"
def stack_ok__got() -> String:
  er_tag(PM.sk_of(sl([sa("stack"), sa("s1"), sa("dW"), sa("dH")])))
def stack_ok__want() -> String:
  "sk"
def stack_empty__got() -> String:
  er_tag(PM.sk_of(sl([sa("stack"), sa("s1")])))
def stack_empty__want() -> String:
  "err:stack-needs-dim"
def node_sing__got() -> String:
  er_tag(PM.entry_of(sl([sa("node"), sa("1")]), part(ds_box())))
def node_sing__want() -> String:
  "err:unknown-pmi-entry"
def entry_unknown__got() -> String:
  er_tag(PM.entry_of(sl([sa("frobnicate"), sa("1")]), part(ds_box())))
def entry_unknown__want() -> String:
  "err:unknown-pmi-entry"
def entry_atom__got() -> String:
  er_tag(PM.entry_of(sa("datum"), part(ds_box())))
def entry_atom__want() -> String:
  "err:unknown-pmi-entry"
def scan_full__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (node 1) (datum A n1.c0.top) (dim dW W) (tol t1 flatness 0.02 n1.c0.bottom rfs) (state cold 1) (stack s1 dW))", part(ds_box())))
def scan_full__want() -> String:
  "ok:1/1/1/1/1"
def scan_garbage__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (node 1) (datum A)", part(ds_box())))
def scan_garbage__want() -> String:
  "err:pmi-parse-failed"
def scan_two_forms__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (node 1)) (pmi (node 1))", part(ds_box())))
def scan_two_forms__want() -> String:
  "err:pmi-parse-failed"
def scan_wrong_head__got() -> String:
  pr_tag(PM.pmi_parse("(assembly (inst a 1 0 0 0 0))", part(ds_box())))
def scan_wrong_head__want() -> String:
  "err:pmi-parse-failed"
def scan_no_node__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (datum A n1.c0.top))", part(ds_box())))
def scan_no_node__want() -> String:
  "ok:1/0/0/0/0"
def scan_dup_datum__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (node 1) (datum A n1.c0.top) (datum A n1.c0.bottom))", part(ds_box())))
def scan_dup_datum__want() -> String:
  "err:duplicate-datum"
def scan_dup_dim__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (node 1) (dim d W) (dim d W))", part(ds_box())))
def scan_dup_dim__want() -> String:
  "err:duplicate-dim"
def scan_dup_tol__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (node 1) (tol t flatness 0.02 n1.c0.top rfs) (tol t flatness 0.02 n1.c0.top rfs))", part(ds_box())))
def scan_dup_tol__want() -> String:
  "err:duplicate-tol"
def scan_dup_state__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (node 1) (state s 1) (state s 2))", part(ds_box())))
def scan_dup_state__want() -> String:
  "err:duplicate-state"
def scan_dup_stack__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (node 1) (dim d W) (stack s d) (stack s d))", part(ds_box())))
def scan_dup_stack__want() -> String:
  "err:duplicate-stack"
def scan_dup_node__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (node 1) (node 1))", part(ds_box())))
def scan_dup_node__want() -> String:
  "err:duplicate-node"
def scan_first_bad__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (node 1) (dim d W) (dim d W) (datum A n1.c0.top) (datum A n1.c0.top))", part(ds_box())))
def scan_first_bad__want() -> String:
  "err:duplicate-dim"
def scan_nodes__got() -> String:
  pr_tag(PM.pmi_parse("(pmi (nodes 1 3) (state cold 1))", part(ds_pair())))
def scan_nodes__want() -> String:
  "ok:0/0/0/1/0"
def pfn_top__got() -> String:
  PM.pfn_s(BD.Fn{1u64, 0n, 0u64, 0n, 0n})
def pfn_top__want() -> String:
  "n1.c0.top"
def pfn_bottom__got() -> String:
  PM.pfn_s(BD.Fn{2u64, 1n, 1u64, 0n, 0n})
def pfn_bottom__want() -> String:
  "n2.c1.bottom"
def pfn_wall__got() -> String:
  PM.pfn_s(BD.Fn{1u64, 0n, 2u64, 3n, 0n})
def pfn_wall__want() -> String:
  "n1.c0.wall.3.0"
def pfn_cav__got() -> String:
  PM.pfn_s(BD.Fn{1u64, 2n, 4u64, 1n, 0n})
def pfn_cav__want() -> String:
  "n1.cav.2.1.0"
def sel_hit__got() -> String:
  bs(PM.sel_mem(M.bd_fns(bod(ds_box(), 1u64)), "n1.c0.top"))
def sel_hit__want() -> String:
  "1"
def sel_miss__got() -> String:
  bs(PM.sel_mem(M.bd_fns(bod(ds_box(), 1u64)), "n9.c0.top"))
def sel_miss__want() -> String:
  "0"
def sel_idx_top__got() -> String:
  Nat.show(PM.sel_idx(M.bd_fns(bod(ds_box(), 1u64)), "n1.c0.top"))
def sel_idx_top__want() -> String:
  "0"
def sel_idx_wall__got() -> String:
  Nat.show(PM.sel_idx(M.bd_fns(bod(ds_box(), 1u64)), "n1.c0.wall.3.0"))
def sel_idx_wall__want() -> String:
  "5"
def sel_idx_miss__got() -> String:
  Nat.show(PM.sel_idx(M.bd_fns(bod(ds_box(), 1u64)), "n9.c0.top"))
def sel_idx_miss__want() -> String:
  "6"
def sel_kind_plane__got() -> String:
  U64.show(PM.sel_kind(btof(ds_box(), 1u64), "n1.c0.top"))
def sel_kind_plane__want() -> String:
  "0"
def sel_kind_cyl__got() -> String:
  U64.show(PM.sel_kind(btof(ds_cyl(), 1u64), "n1.c0.wall.0.0"))
def sel_kind_cyl__want() -> String:
  "1"
def sel_kind_miss__got() -> String:
  U64.show(PM.sel_kind(btof(ds_box(), 1u64), "n9.c0.top"))
def sel_kind_miss__want() -> String:
  "7"
def res_datum__got() -> String:
  rv_line(PM.res_one(PM.ER_dt{dt_a()}, dts_a(), dms_wh(), btof(ds_box(), 1u64), plof(ds_box(), 1u64)))
def res_datum__want() -> String:
  "datum A ok n1.c0.top plane\n"
def res_datum_cyl__got() -> String:
  rv_line(PM.res_one(PM.ER_dt{PM.Datum{"C", "n1.c0.wall.0.0"}}, [PM.Datum{"C", "n1.c0.wall.0.0"}],
    [], btof(ds_cyl(), 1u64), plof(ds_cyl(), 1u64)))
def res_datum_cyl__want() -> String:
  "datum C ok n1.c0.wall.0.0 cylinder\n"
def res_datum_sel__got() -> String:
  rv_line(PM.res_one(PM.ER_dt{PM.Datum{"A", "n9.c0.top"}}, dts_a(), dms_wh(), btof(ds_box(), 1u64),
    plof(ds_box(), 1u64)))
def res_datum_sel__want() -> String:
  "BAD:unknown-selector n9.c0.top|select a face from the faces verb"
def res_dim__got() -> String:
  rv_line(PM.res_one(PM.ER_dm{dm_w()}, dts_a(), dms_wh(), btof(ds_box(), 1u64), plof(ds_box(), 1u64)))
def res_dim__want() -> String:
  "dim dW nominal 10 zone [9.9, 10.1]\n"
def res_state__got() -> String:
  rv_line(PM.res_one(PM.ER_st{st_hot()}, dts_a(), dms_wh(), btof(ds_box(), 1u64), plof(ds_box(), 1u64)))
def res_state__want() -> String:
  "state hot grow 1.002\n"
def res_stack__got() -> String:
  rv_line(PM.res_one(PM.ER_sk{PM.Stack{"s1", ["dW", "dH"]}}, dts_a(), dms_wh(), btof(ds_box(), 1u64),
    plof(ds_box(), 1u64)))
def res_stack__want() -> String:
  "stack s1 dims 2\n"
def res_stack_dim__got() -> String:
  rv_line(PM.res_one(PM.ER_sk{PM.Stack{"s1", ["dW", "dQ"]}}, dts_a(), dms_wh(), btof(ds_box(), 1u64),
    plof(ds_box(), 1u64)))
def res_stack_dim__want() -> String:
  "BAD:unknown-dim dQ|name a dim from the pmi set"
def res_flat__got() -> String:
  rv_line(PM.res_one(PM.ER_tol{PM.Tol{"t1", 1u64, 0.02f64, "n1.c0.bottom", []}}, dts_a(), dms_wh(),
    btof(ds_box(), 1u64), plof(ds_box(), 1u64)))
def res_flat__want() -> String:
  "tol t1 flatness conforms actual 0 certified\n"
def res_flat_cyl__got() -> String:
  rv_line(PM.res_one(PM.ER_tol{PM.Tol{"t1", 1u64, 0.02f64, "n1.c0.wall.0.0", []}}, dts_a(), dms_wh(),
    btof(ds_cyl(), 1u64), plof(ds_cyl(), 1u64)))
def res_flat_cyl__want() -> String:
  "BAD:tol-face-not-plane|flatness, perpendicularity and parallelism apply to plane faces"
def res_flat_datum__got() -> String:
  rv_line(PM.res_one(PM.ER_tol{PM.Tol{"t1", 1u64, 0.02f64, "n1.c0.bottom", ["A"]}}, dts_a(), dms_wh(),
    btof(ds_box(), 1u64), plof(ds_box(), 1u64)))
def res_flat_datum__want() -> String:
  "BAD:tol-kind-takes-no-datum|flatness takes no datum references"
def res_orient_datum__got() -> String:
  rv_line(PM.res_one(PM.ER_tol{PM.Tol{"t2", 2u64, 0.05f64, "n1.c0.wall.0.0", []}}, dts_a(), dms_wh(),
    btof(ds_box(), 1u64), plof(ds_box(), 1u64)))
def res_orient_datum__want() -> String:
  "BAD:tol-needs-one-datum|orientation takes exactly one datum"
def res_orient_unknown__got() -> String:
  rv_line(PM.res_one(PM.ER_tol{PM.Tol{"t2", 2u64, 0.05f64, "n1.c0.wall.0.0", ["Z"]}}, dts_a(), dms_wh(),
    btof(ds_box(), 1u64), plof(ds_box(), 1u64)))
def res_orient_unknown__want() -> String:
  "BAD:unknown-datum Z|name a datum from the pmi set"
def ii_bits(+a: I.I) -> String:
  fbits(I.i_lo(a)) ++ "," ++ fbits(I.i_hi(a))
def wn_checks(+w: PM.WN) -> String:
  PM.WN{+ok, +x, +y, +z} = w
  bs(ok) ++ bs(Bool.and(F64.is_le(I.i_lo(x), 0.0f64), F64.is_le(0.0f64, I.i_hi(x)))) ++
    bs(Bool.and(F64.is_le(I.i_lo(y), 0.0f64), F64.is_le(0.0f64, I.i_hi(y)))) ++
    bs(F64.is_lt(0.99f64, I.i_lo(z)))
def ci_lo_eq(+c: PM.CI, +a: M.Body, +b: M.Body) -> String:
  PM.CI{+hit, +lo, +hi, +na, +nb} = c
  bs(U64.is_eq(F64.bits(lo), F64.bits(QA.ab_ab_lo(QI.wbox(a), QI.wbox(b)))))
def ci_hi_eq(+c: PM.CI, +a: M.Body, +b: M.Body) -> String:
  PM.CI{+hit, +lo, +hi, +na, +nb} = c
  bs(U64.is_eq(F64.bits(hi), F64.bits(QD.pts_min(QI.sms_of(a), QI.sms_of(b), V.dbl_max()))))
def ci_hit_eq(+c: PM.CI, +a: M.Body, +b: M.Body) -> String:
  PM.CI{+hit, +lo, +hi, +na, +nb} = c
  bs(Bool.or(Bool.and(hit, QI.rel_interf(a, b)), Bool.and(Bool.not(hit), Bool.not(QI.rel_interf(a, b)))))
def ci_nn(+c: PM.CI) -> String:
  PM.CI{+hit, +lo, +hi, +na, +nb} = c
  Nat.show(na) ++ "x" ++ Nat.show(nb)
def mb_tag(+m: Maybe<&2, String>) -> String:
  match m:
    case None{}: "none"
    case Some{+s}: "some:" ++ s
def wrap42_nent(+e: SW.ER2) -> String:
  bs(Nat.is_eq(SW.ws_nent(SW.sw_wrap42(e, 1n, "PMI", 7n)),
    Nat.add(Nat.add(SW.er2_n(e), 19n), 7n)))
def wrap42_np(+e: SW.ER2) -> String:
  Nat.show(SW.ws_nprod(SW.sw_wrap42(e, 1n, "PMI", 7n)))
def wrap42_pre(+e: SW.ER2) -> String:
  bs(PM.rw_pre(SW.ws_s(SW.sw_wrap42(e, 1n, "PMI", 7n)), SW.sw_head42()))
def orient_perp_ok__got() -> U64:
  oe_v(PM.orient_all(btof(ds_box(), 1u64), plof(ds_box(), 1u64), 2n, 0n, 2u64), 0.05f64)
def orient_perp_ok__want() -> U64:
  0u64
def orient_perp_bad__got() -> U64:
  oe_v(PM.orient_all(btof(ds_box(), 1u64), plof(ds_box(), 1u64), 0n, 1n, 2u64), 0.05f64)
def orient_perp_bad__want() -> U64:
  1u64
def orient_par_ok__got() -> U64:
  oe_v(PM.orient_all(btof(ds_box(), 1u64), plof(ds_box(), 1u64), 0n, 1n, 3u64), 0.05f64)
def orient_par_ok__want() -> U64:
  0u64
def orient_par_bad__got() -> U64:
  oe_v(PM.orient_all(btof(ds_box(), 1u64), plof(ds_box(), 1u64), 2n, 0n, 3u64), 0.05f64)
def orient_par_bad__want() -> U64:
  1u64
def orient_uncertain__got() -> U64:
  oe_v(PM.orient_all(btof(ds_box(), 1u64), plof(ds_box(), 1u64), 2n, 0n, 2u64), 0.0f64)
def orient_uncertain__want() -> U64:
  2u64
def orient_face__got() -> String:
  oe_bits(PM.orient_all(btof(ds_cyl(), 1u64), plof(ds_cyl(), 1u64), 2n, 0n, 2u64))
def orient_face__want() -> String:
  "BAD:tol-face-not-plane"
def orient_datum__got() -> String:
  oe_bits(PM.orient_all(btof(ds_cyl(), 1u64), plof(ds_cyl(), 1u64), 0n, 2n, 2u64))
def orient_datum__want() -> String:
  "BAD:tol-datum-not-plane"
def voe_conforms__got() -> U64:
  PM.voe(0.0f64, 0.05f64, 0.05f64)
def voe_conforms__want() -> U64:
  0u64
def voe_violates__got() -> U64:
  PM.voe(0.06f64, 0.07f64, 0.05f64)
def voe_violates__want() -> U64:
  1u64
def voe_uncertain__got() -> U64:
  PM.voe(0.0f64, 0.06f64, 0.05f64)
def voe_uncertain__want() -> U64:
  2u64
def voe_edge__got() -> U64:
  PM.voe(0.05f64, 0.05f64, 0.05f64)
def voe_edge__want() -> U64:
  0u64
def iabs_pos__got() -> I.I:
  PM.iabs(I.I{0.5f64, 0.6f64})
def iabs_pos__want() -> I.I:
  I.I{0.5f64, 0.6f64}
def iabs_neg__got() -> I.I:
  PM.iabs(I.I{F64.neg(0.6f64), F64.neg(0.5f64)})
def iabs_neg__want() -> I.I:
  I.I{0.5f64, 0.6f64}
def iabs_straddle__got() -> I.I:
  PM.iabs(I.I{F64.neg(0.5f64), 0.6f64})
def iabs_straddle__want() -> I.I:
  I.I{0.0f64, 0.6f64}
def odev3_zero__got() -> String:
  ii_bits(PM.orient_dev(3u64, I.I{0.0f64, 0.0f64}))
def odev3_zero__want() -> String:
  "4607182418800017406,4607182418800017409"
def oe_range(+e: PM.OE) -> String:
  match e:
    case PM.OE_ok{+lo, +hi}: bs(Bool.and(F64.is_lt(20.0f64, lo), F64.is_lt(hi, 25.0f64)))
    case PM.OE_bad{+why, +fix}: "BAD"
def face_ext_box__got() -> String:
  oe_range(PM.face_ext(btof(ds_box(), 1u64), 0n))
def face_ext_box__want() -> String:
  "1"
def face_ext_empty__got() -> String:
  oe_bits(PM.face_ext_go([]))
def face_ext_empty__want() -> String:
  "BAD:tol-degenerate-face"
def wnorm_z__got() -> String:
  wn_checks(PM.wnorm(plof(ds_box(), 1u64), G.Pl{V.Pt{0.0f64, 0.0f64, 0.0f64},
    V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}))
def wnorm_z__want() -> String:
  "1111"
def stk_bits__got() -> String:
  sr_bits(PM.stk_dim(["dW", "dH"], dms_wh(), 0.0f64, I.I{0.0f64, 0.0f64}))
def stk_bits__want() -> String:
  ",4629137466983448576,4629109319485777509,4629165614481119643"
def stk_miss__got() -> String:
  sr_bits(PM.stk_dim(["dW", "dQ"], dms_wh(), 0.0f64, I.I{0.0f64, 0.0f64}))
def stk_miss__want() -> String:
  ",4621819117588971520,4621762822593629388,4621875412584313652"
def stk_row_bits__got() -> String:
  sr_bits(PM.stk_row(PM.stk_dim(["dW", "dH"], dms_wh(), 0.0f64, I.I{0.0f64, 0.0f64}), st_hot()))
def stk_row_bits__want() -> String:
  "hot,4629154355482051215,4629126151689384805,4629182559274717626"
def stk_rows_len__got() -> String:
  Nat.show(List.length(&2, PM.SR, PM.stk_rows(PM.stk_dim(["dW"], dms_wh(), 0.0f64,
    I.I{0.0f64, 0.0f64}), [st_cold(), st_hot()])))
def stk_rows_len__want() -> String:
  "2"
def sr_rep_clean__got() -> String:
  PM.sr_rep(PM.SR{st_hot(), 30.0f64, 29.9f64, 30.1f64})
def sr_rep_clean__want() -> String:
  "state hot grow 1.002 [29.9, 30.1]\n"
def states_dflt__got() -> List<&2, PM.State>:
  PM.states_or_dflt([])
def states_dflt__want() -> List<&2, PM.State>:
  [PM.State{"nominal", 1.0f64}]
def states_keep__got() -> List<&2, PM.State>:
  PM.states_or_dflt([st_cold()])
def states_keep__want() -> List<&2, PM.State>:
  [st_cold()]
def ci_lo_id__got() -> String:
  ci_lo_eq(PM.clr_iv(bod(ds_pair(), 1u64), bod(ds_pair(), 3u64)), bod(ds_pair(), 1u64), bod(ds_pair(), 3u64))
def ci_lo_id__want() -> String:
  "1"
def ci_hi_id__got() -> String:
  ci_hi_eq(PM.clr_iv(bod(ds_pair(), 1u64), bod(ds_pair(), 3u64)), bod(ds_pair(), 1u64), bod(ds_pair(), 3u64))
def ci_hi_id__want() -> String:
  "1"
def ci_hit_id__got() -> String:
  ci_hit_eq(PM.clr_iv(bod(ds_pair(), 1u64), bod(ds_pair(), 3u64)), bod(ds_pair(), 1u64), bod(ds_pair(), 3u64))
def ci_hit_id__want() -> String:
  "1"
def ci_nn_pair__got() -> String:
  ci_nn(PM.clr_iv(bod(ds_pair(), 1u64), bod(ds_pair(), 3u64)))
def ci_nn_pair__want() -> String:
  "30x30"
def pmi_w_box__got() -> String:
  fbits(PM.pmi_w(part(ds_box())))
def pmi_w_box__want() -> String:
  "4596373779694328192"
def env_rep_clean__got() -> String:
  PM.env_rep(4.0f64, 4.5f64, 0.2f64)
def env_rep_clean__want() -> String:
  "envelope clearance [3.8, 4.7] estimated widen=0.2\n"
def rw_disjoint__got() -> String:
  PM.rw_of("relation disjoint status=certified")
def rw_disjoint__want() -> String:
  "disjoint"
def rw_inside__got() -> String:
  PM.rw_of("relation inside a-in-b status=certified")
def rw_inside__want() -> String:
  "inside"
def rw_interf__got() -> String:
  PM.rw_of("relation interference status=certified witness=subdiv")
def rw_interf__want() -> String:
  "interference"
def rw_uncertain__got() -> String:
  PM.rw_of("relation uncertain status=estimated a:in=0 out=1")
def rw_uncertain__want() -> String:
  "uncertain"
def rw_unknown__got() -> String:
  PM.rw_of("garbage")
def rw_unknown__want() -> String:
  "unknown"
def rel_st_pair__got() -> String:
  PM.rel_st(st_cold(), QI.rel_pair(bod(ds_pair(), 1u64), bod(ds_pair(), 3u64)))
def rel_st_pair__want() -> String:
  "state cold grow 1 relation relation disjoint status=certified\n"
def clr_hit_line__got() -> String:
  PM.clr_hit(True{}, 0.0f64, 0.0f64, 0n, 0n, st_cold())
def clr_hit_line__want() -> String:
  "state cold grow 1 clearance 0 status=certified state=interference\n"
def em_dt_one__got() -> String:
  em_s(PM.pmi_emit([PM.ER_dt{dt_a()}], 100n, 80n, 90n, 96n))
def em_dt_one__want() -> String:
  "#100=(DATUM('A')SHAPE_ASPECT('','',#90,.F.));\n#101=(DATUM_FEATURE()SHAPE_ASPECT('df-A','n1.c0.top',#90,.T.));\n#102=SHAPE_ASPECT_RELATIONSHIP('','',#101,#100);\n"
def em_dt_nn__got() -> String:
  em_nn(PM.pmi_emit([PM.ER_dt{dt_a()}], 100n, 80n, 90n, 96n))
def em_dt_nn__want() -> String:
  "1/103/3"
def em_dm_one__got() -> String:
  em_s(PM.pmi_emit([PM.ER_dm{dm_w()}], 103n, 80n, 90n, 96n))
def em_dm_one__want() -> String:
  "#103=SHAPE_ASPECT('size','dW',#90,.T.);\n#104=DIMENSIONAL_SIZE(#103,'dW');\n#105=(MEASURE_REPRESENTATION_ITEM()MEASURE_WITH_UNIT(LENGTH_MEASURE(10.0),#80)REPRESENTATION_ITEM('nominal'));\n#106=(REPRESENTATION('dW-nom',(#105),#96)SHAPE_DIMENSION_REPRESENTATION()SHAPE_REPRESENTATION());\n#107=(MEASURE_REPRESENTATION_ITEM()MEASURE_WITH_UNIT(LENGTH_MEASURE(9.9),#80)REPRESENTATION_ITEM('lower'));\n#108=(REPRESENTATION('dW-lo',(#107),#96)SHAPE_DIMENSION_REPRESENTATION()SHAPE_REPRESENTATION());\n#109=(MEASURE_REPRESENTATION_ITEM()MEASURE_WITH_UNIT(LENGTH_MEASURE(10.1),#80)REPRESENTATION_ITEM('upper'));\n#110=(REPRESENTATION('dW-hi',(#109),#96)SHAPE_DIMENSION_REPRESENTATION()SHAPE_REPRESENTATION());\n#111=(DIMENSIONAL_CHARACTERISTIC_REPRESENTATION(#104,#106)INDEPENDENT_LIMITS_OF_LINEAR_DIMENSIONAL_SIZE_CHARACTERISTIC_REPRESENTATION((#108,#110)));\n"
def em_flat_one__got() -> String:
  em_s(PM.pmi_emit([PM.ER_tol{PM.Tol{"t1", 1u64, 0.02f64, "n1.c0.bottom", []}}], 112n, 80n, 90n, 96n))
def em_flat_one__want() -> String:
  "#112=SHAPE_ASPECT('tol-face','n1.c0.bottom',#90,.T.);\n#113=(LENGTH_MEASURE_WITH_UNIT()MEASURE_WITH_UNIT(LENGTH_MEASURE(0.02),#80));\n#114=FLATNESS_TOLERANCE('t1','flatness',#113,#112);\n"
def em_ori_one__got() -> String:
  em_s(PM.pmi_emit([PM.ER_dt{dt_a()}, PM.ER_tol{PM.Tol{"t2", 2u64, 0.05f64, "n1.c0.wall.0.0", ["A"]}}],
    100n, 80n, 90n, 96n))
def em_ori_one__want() -> String:
  "#100=(DATUM('A')SHAPE_ASPECT('','',#90,.F.));\n#101=(DATUM_FEATURE()SHAPE_ASPECT('df-A','n1.c0.top',#90,.T.));\n#102=SHAPE_ASPECT_RELATIONSHIP('','',#101,#100);\n#103=SHAPE_ASPECT('tol-face','n1.c0.wall.0.0',#90,.T.);\n#104=(LENGTH_MEASURE_WITH_UNIT()MEASURE_WITH_UNIT(LENGTH_MEASURE(0.05),#80));\n#105=DATUM_REFERENCE(1,#100);\n#106=(GEOMETRIC_TOLERANCE('t2','perpendicularity',#104,#103)GEOMETRIC_TOLERANCE_WITH_DATUM_REFERENCE((#105))PERPENDICULARITY_TOLERANCE());\n"
def em_skip__got() -> String:
  em_nn(PM.pmi_emit([PM.ER_st{st_cold()}, PM.ER_sk{PM.Stack{"s1", ["dW"]}}], 100n, 80n, 90n, 96n))
def em_skip__want() -> String:
  "1/100/0"
def em_count__got() -> String:
  em_nn(PM.pmi_emit([PM.ER_dt{dt_a()}, PM.ER_dm{dm_w()},
    PM.ER_tol{PM.Tol{"t1", 1u64, 0.02f64, "n1.c0.bottom", []}},
    PM.ER_tol{PM.Tol{"t2", 2u64, 0.05f64, "n1.c0.wall.0.0", ["A"]}},
    PM.ER_st{st_cold()}, PM.ER_sk{PM.Stack{"s1", ["dW"]}}], 100n, 80n, 90n, 96n))
def em_count__want() -> String:
  "1/119/19"
def em_bad_shape__got() -> String:
  em_nn(PM.em_bad(PM.EM{True{}, "", "", 100n, 0n, []}, "step-float-not-exact 1e999"))
def em_bad_shape__want() -> String:
  "0/100/0"
def st_esc_quote__got() -> String:
  PM.st_esc("a'b")
def st_esc_quote__want() -> String:
  "a''b"
def st_esc_plain__got() -> String:
  PM.st_esc("plain")
def st_esc_plain__want() -> String:
  "plain"
def nm_quote__got() -> String:
  bs(PM.nm_bad("a'b"))
def nm_quote__want() -> String:
  "1"
def nm_clean__got() -> String:
  bs(PM.nm_bad("abc"))
def nm_clean__want() -> String:
  "0"
def head42_exact__got() -> String:
  SW.sw_head42()
def head42_exact__want() -> String:
  "ISO-10303-21;\nHEADER;\nFILE_DESCRIPTION(('BendCAD AP242 PMI export'),'2;1');\nFILE_NAME('bendcad.step','',('BendCAD'),('BendCAD'),'BendCAD','BendCAD','');\nFILE_SCHEMA(('AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF'));\nENDSEC;\nDATA;\n"
def wrap42_fail__got() -> String:
  bs(SW.ws_ok(SW.sw_wrap42(SW.ER2{False{}, "", "step-test", 0n, []}, 1n, "", 0n)))
def wrap42_fail__want() -> String:
  "0"
def wrap42_why__got() -> String:
  SW.ws_why(SW.sw_wrap42(SW.ER2{False{}, "", "step-test", 0n, []}, 1n, "", 0n))
def wrap42_why__want() -> String:
  "step-test"
def wrap42_nent_box__got() -> String:
  wrap42_nent(SW.sw_stage(M.bd_brep(bod(ds_box(), 1u64)), M.bd_pl(bod(ds_box(), 1u64)), 1n))
def wrap42_nent_box__want() -> String:
  "1"
def wrap42_np_box__got() -> String:
  wrap42_np(SW.sw_stage(M.bd_brep(bod(ds_box(), 1u64)), M.bd_pl(bod(ds_box(), 1u64)), 1n))
def wrap42_np_box__want() -> String:
  "1"
def wrap42_pre_box__got() -> String:
  wrap42_pre(SW.sw_stage(M.bd_brep(bod(ds_box(), 1u64)), M.bd_pl(bod(ds_box(), 1u64)), 1n))
def wrap42_pre_box__want() -> String:
  "1"
def vc_check__got() -> U64:
  PM.verb_code("check")
def vc_check__want() -> U64:
  1u64
def vc_stack__got() -> U64:
  PM.verb_code("stack")
def vc_stack__want() -> U64:
  2u64
def vc_toler__got() -> U64:
  PM.verb_code("toler")
def vc_toler__want() -> U64:
  3u64
def vc_step42__got() -> U64:
  PM.verb_code("step42")
def vc_step42__want() -> U64:
  4u64
def vc_bogus__got() -> U64:
  PM.verb_code("bogus")
def vc_bogus__want() -> U64:
  0u64
def go_verb__got() -> String:
  PM.pmi_go(part(ds_box()), ["bogus"])
def go_verb__want() -> String:
  "error invalid-input | pmi | why: unknown verb | fix: pmi check|stack|toler|step42 ..."
def go_file__got() -> String:
  PM.pmi_go(part(ds_box()), ["step42", "o.stp", "(pmi (node 1))"])
def go_file__want() -> String:
  "error invalid-input | pmi | why: step42 needs an output path | fix: pmi step42 OUT (pmi ...)"
def go_check_simple__got() -> String:
  PM.pmi_go(part(ds_box()), ["check", "(pmi (node 1) (datum A n1.c0.top) (dim dW W) (state cold 1))"])
def go_check_simple__want() -> String:
  "pmi node 1 items 3\ndatum A ok n1.c0.top plane\ndim dW nominal 10 zone [9.9, 10.1]\nstate cold grow 1\npmi ok 3 items\n"
def go_check_needs__got() -> String:
  PM.pmi_go(part(ds_box()), ["check", "(pmi (datum A n1.c0.top))"])
def go_check_needs__want() -> String:
  "error invalid-input | pmi check | why: pmi-needs-node | fix: give one (node N) entry"
def go_check_nodes__got() -> String:
  PM.pmi_go(part(ds_box()), ["check", "(pmi (nodes 1 2))"])
def go_check_nodes__want() -> String:
  "error invalid-input | pmi check | why: pmi-needs-node | fix: give one (node N) entry"
def go_check_unode__got() -> String:
  PM.pmi_go(part(ds_box()), ["check", "(pmi (node 9))"])
def go_check_unode__want() -> String:
  "error invalid-input | pmi check | why: unknown-node 9 | fix: name a node from the design (eval)"
def go_check_failed__got() -> String:
  PM.pmi_go(part(ds_fail()), ["check", "(pmi (node 1))"])
def go_check_failed__want() -> String:
  "error: node 1; nothing evaluated"
def go_stack_err__got() -> String:
  PM.pmi_go(part(ds_box()), ["stack", "(pmi (node 1) (dim dW W) (stack s1 dW dQ))"])
def go_stack_err__want() -> String:
  "error invalid-input | pmi stack | why: unknown-dim dQ | fix: name a dim from the pmi set"
def go_toler_unode__got() -> String:
  PM.pmi_go(part(ds_pair()), ["toler", "(pmi (nodes 1 9))"])
def go_toler_unode__want() -> String:
  "error invalid-input | pmi toler | why: unknown-node 9 | fix: name a node from the design (eval)"
def go_toler_failed__got() -> String:
  PM.pmi_go(part(ds_box() ++ " (node 2 (box 4 4 4) (intent create 5 0 1 0))"), ["toler", "(pmi (nodes 1 2))"])
def go_toler_failed__want() -> String:
  "error: node 2; nothing compared"
def file_out__got() -> String:
  fr_tag(PM.pmi_file(part(ds_box()), ["step42"]))
def file_out__want() -> String:
  "err:step42-needs-output"
def file_simple__got() -> String:
  fr_tag(PM.pmi_file(part(ds_box()), ["step42", "o.stp", "(pmi (node 1) (datum A n1.c0.top) (dim dW W))"]))
def file_simple__want() -> String:
  "ok:12"
def file_bad__got() -> String:
  fr_tag(PM.pmi_file(part(ds_box()), ["step42", "o.stp", "(pmi (node 1) (dim dW Q))"]))
def file_bad__want() -> String:
  "err:unknown-param Q"
def file_line__got() -> String:
  fr_tag(PM.pmi_file(part(ds_box()), ["step42", "o.stp", "(pmi (node 9))"]))
def file_line__want() -> String:
  "line:error invalid-input | pmi step42 | why: unknown-node 9 | fix: name a node from the design (eval)"
def kind_flat__got() -> U64:
  PM.kind_of("flatness")
def kind_flat__want() -> U64:
  1u64
def kind_perp__got() -> U64:
  PM.kind_of("perpendicularity")
def kind_perp__want() -> U64:
  2u64
def kind_par__got() -> U64:
  PM.kind_of("parallelism")
def kind_par__want() -> U64:
  3u64
def kind_bogus__got() -> U64:
  PM.kind_of("roundness")
def kind_bogus__want() -> U64:
  0u64
def kinds_round__got() -> String:
  PM.kind_s(1u64) ++ "/" ++ PM.kind_s(2u64) ++ "/" ++ PM.kind_s(3u64) ++ "/" ++ PM.kind_s(9u64)
def kinds_round__want() -> String:
  "flatness/perpendicularity/parallelism/unknown-kind"
def st_go_yes__got() -> String:
  er_tag(PM.st_go(True{}, "s", 2.0f64))
def st_go_yes__want() -> String:
  "st"
def st_go_no__got() -> String:
  er_tag(PM.st_go(False{}, "s", 2.0f64))
def st_go_no__want() -> String:
  "err:bad-state"
def dup_yes__got() -> PM.DU:
  PM.dup_go(True{}, "a", ["b"])
def dup_yes__want() -> PM.DU:
  PM.DU{True{}, ["b"]}
def dup_no__got() -> PM.DU:
  PM.dup_go(False{}, "a", ["b"])
def dup_no__want() -> PM.DU:
  PM.DU{False{}, ["a", "b"]}
def dt_id_hit__got() -> String:
  Nat.show(PM.dt_id([PM.DI{"A", 100n}], "A"))
def dt_id_hit__want() -> String:
  "100"
def dt_id_miss__got() -> String:
  Nat.show(PM.dt_id([PM.DI{"A", 100n}], "Z"))
def dt_id_miss__want() -> String:
  "0"
def sk_bad_hit__got() -> String:
  mb_tag(PM.sk_bad(["dW", "dQ"], dms_wh()))
def sk_bad_hit__want() -> String:
  "some:dQ"
def sk_bad_ok__got() -> String:
  mb_tag(PM.sk_bad(["dW"], dms_wh()))
def sk_bad_ok__want() -> String:
  "none"
def drf_head_two__got() -> String:
  PM.drf_head(["A", "B"])
def drf_head_two__want() -> String:
  "A"
def drf_head_empty__got() -> String:
  PM.drf_head([])
def drf_head_empty__want() -> String:
  ""
def check_fb_bad__got() -> String:
  PM.check_fb(PM.FB_bad{"w1", "f1"}, [], "H\n")
def check_fb_bad__want() -> String:
  "error invalid-input | pmi check | why: w1 | fix: f1"
def check_rep_one__got() -> String:
  PM.check_rep([PM.RV_ok{"x\n"}], "H\n")
def check_rep_one__want() -> String:
  "H\nx\npmi ok 1 items\n"
