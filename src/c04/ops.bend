# C04 boundary-representation validators: brep_checked under explicit profiles.
# Data + constructors live in types.bend; this file validates incidence,
# usage/orientation, loop closure, trimming, embedding, and solid/open rules.
# Every failure is C00 FailKind (invalid-input or resource-exhausted); no new
# taxonomy. Every list walk is Nat-fuel-bounded (BN-8); handles are
# generational (idx, gen) into explicit Brep lists (BN-7); no batch ops (BN-9).
#
# Pipeline (first match wins; order matters for exhausted-vs-invalid):
#  A. store re-validation via mk_brep (value + gen + nodup; catches raw Br).
#  B. incidence: every member handle resolves (dangling => invalid).
#  C. edge usage: solid = exactly twice opposite fwd; open = once/twice
#     (twice => opposite). Covers inverted, nonmanifold-edge, open-boundary.
#  D. loop closure (oriented vertex chain meets + closed) + self-intersection
#     (no repeated start vertex) + trimming meets in face (u,v).
#  E. face loop kinds: exactly one LK_outer per face.
#  F. shell/solid/profile: solid forbids SK_open, cavities are SK_inner;
#     open admits SK_open and boundary (once-used) edges.
#  G. embedding: C03 interior validity + vertex-on-curve (all curves) +
#     trim-on-surface coincidence for plane/bezp only (sphere/cyl/cone/torus
#     have no C03 surface eval; their trims pass on uv-meet + finiteness).
# On success returns Tok brep (the validated input); else Terr.

import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c03/ops.bend as GO
import ./types.bend as Ty

# --- Exact point/vec equality (fixtures use exact values). ---
def pt_eq(+a: V.Point, +b: V.Point) -> Bool:
  Bool.and(F64.is_eq(V.pt_x(a), V.pt_x(b)),
    Bool.and(F64.is_eq(V.pt_y(a), V.pt_y(b)),
      F64.is_eq(V.pt_z(a), V.pt_z(b))))

def v2_eq(+a: V.Vec2, +b: V.Vec2) -> Bool:
  Bool.and(F64.is_eq(V.v2_x(a), V.v2_x(b)),
    F64.is_eq(V.v2_y(a), V.v2_y(b)))

# --- Trim endpoints in face (u,v). TSeg a->b; TBez b0->b3. ---
def trim_start(t: G.GVal) -> V.Vec2:
  match t:
    case G.GV_ts{w}:
      G.Ts{a, b} = w
      a
    case G.GV_tb{w}:
      G.Tb{b0, b1, b2, b3} = w
      b0
    case _: V.V2{0.0f64, 0.0f64}

def trim_end(t: G.GVal) -> V.Vec2:
  match t:
    case G.GV_ts{w}:
      G.Ts{a, b} = w
      b
    case G.GV_tb{w}:
      G.Tb{b0, b1, b2, b3} = w
      b3
    case _: V.V2{0.0f64, 0.0f64}

def trim_fin(t: G.GVal) -> Bool:
  match t:
    case G.GV_ts{w}: G.ts_fin(w)
    case G.GV_tb{w}: G.tb_fin(w)
    case _: False{}

# Oriented trim ends by coedge fwd (False swaps).
def trim_o_start(t: G.GVal, fwd: Bool) -> V.Vec2:
  match fwd:
    case True{}: trim_start(t)
    case False{}: trim_end(t)

def trim_o_end(t: G.GVal, fwd: Bool) -> V.Vec2:
  match fwd:
    case True{}: trim_end(t)
    case False{}: trim_start(t)

# --- C03 interior validity dispatch (raw GVal interiors; C04 classifiers
# alone accept bad interiors, so embedding re-validates). ---
def curve_fin_ok(c: G.GVal, fuel: Nat) -> Bool:
  match c:
    case G.GV_ln{w}: G.ln_valid(w)
    case G.GV_cc{w}: G.cc_valid(w)
    case G.GV_bz{w}: G.bz_fin(w)
    case G.GV_rq{w}: G.rq_valid(w)
    case G.GV_nb{w}: G.gres_ok(GO.nurbs_checked(w, fuel))
    case _: False{}

def surf_fin_ok(s: G.GVal) -> Bool:
  match s:
    case G.GV_pl{w}: G.gres_ok(GO.plane_checked(w))
    case G.GV_cy{w}: G.cy_valid(w)
    case G.GV_co{w}: G.co_valid(w)
    case G.GV_sp{w}: G.sp_valid(w)
    case G.GV_to{w}: G.to_valid(w)
    case G.GV_bp{w}: G.bp_fin(w)
    case _: False{}

# --- Curve eval at one parameter (Nurb takes fuel; others total). ---
def curve_at(c: G.GVal, t: F64, fuel: Nat) -> G.GRes:
  match c:
    case G.GV_ln{w}: GO.line_eval(w, t)
    case G.GV_cc{w}: GO.circ_eval(w, t)
    case G.GV_bz{w}: GO.bez3_eval(w, t)
    case G.GV_rq{w}: GO.rqb_eval(w, t)
    case G.GV_nb{w}: GO.nurbs_eval(w, t, fuel)
    case _: G.gerr(T.F_invalid{})

# Edge endpoints on curve: v0 == eval(lo), v1 == eval(hi) (exact).
# Closed edges (v0 handle == v1 handle) still check both ends.
def edge_ends_on_curve(kind: Ty.EdgeKind, p0: V.Point, p1: V.Point,
    +fuel: Nat) -> Bool:
  match kind:
    case Ty.EK_curve{+curve, +dom}:
      +lo = G.dom_lo(dom)
      +hi = G.dom_hi(dom)
      +r0 = curve_at(curve, lo, fuel)
      +r1 = curve_at(curve, hi, fuel)
      Bool.and(G.gres_ok(r0),
        Bool.and(G.gres_ok(r1),
          Bool.and(pt_eq(G.gres_p(r0), p0), pt_eq(G.gres_p(r1), p1))))
    case Ty.EK_degenerate{}: True{}

# --- Surface eval at (u,v) for plane/bezp (others have no C03 eval). ---
def surf_at(s: G.GVal, u: F64, v: F64) -> G.GRes:
  match s:
    case G.GV_pl{w}: GO.plane_eval(w, u, v)
    case G.GV_bp{w}: GO.bezp_eval(w, u, v)
    case _: G.gerr(T.F_unsupported{})

# --- Stage B incidence: handle-list liveness walks (each handle must
# resolve; fuel 1 per handle for the walk, full cap per resolve). ---
def hce_live_c(xs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hce_live_c(t, ces, f, ffull)
          +ok = Ty.tres_ok(Ty.ce_resolve(ces, h, ffull))
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def hlp_live_c(xs: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hlp_live_c(t, lps, f, ffull)
          +ok = Ty.tres_ok(Ty.lp_resolve(lps, h, ffull))
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def hfa_live_c(xs: List<&2, Ty.HFace>, +fas: List<&2, Ty.Face>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hfa_live_c(t, fas, f, ffull)
          +ok = Ty.tres_ok(Ty.fa_resolve(fas, h, ffull))
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def hsh_live_c(xs: List<&2, Ty.HShell>, +shs: List<&2, Ty.Shell>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hsh_live_c(t, shs, f, ffull)
          +ok = Ty.tres_ok(Ty.sh_resolve(shs, h, ffull))
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def hso_live_c(xs: List<&2, Ty.HSolid>, +sos: List<&2, Ty.Solid>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hso_live_c(t, sos, f, ffull)
          +ok = Ty.tres_ok(Ty.so_resolve(sos, h, ffull))
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

# Single-handle liveness (no walk; resolve with full fuel).
def edge_ends_live(+e: Ty.Edge, +vs: List<&2, Ty.Vertex>,
    +ffull: Nat) -> Bool:
  +v0 = Ty.ed_v0(e)
  +v1 = Ty.ed_v1(e)
  Bool.and(Ty.tres_ok(Ty.vx_resolve(vs, v0, ffull)),
    Ty.tres_ok(Ty.vx_resolve(vs, v1, ffull)))

def ce_edge_live(c: Ty.Coedge, es: List<&2, Ty.Edge>,
    +ffull: Nat) -> Bool:
  Ty.tres_ok(Ty.ed_resolve(es, Ty.ce_edge(c), ffull))

def so_shells_live(+s: Ty.Solid, +shs: List<&2, Ty.Shell>,
    +ffull: Nat) -> Nat:
  +ok_o = Ty.tres_ok(Ty.sh_resolve(shs, Ty.so_outer(s), ffull))
  +code_c = hsh_live_c(Ty.so_cavities(s), shs, ffull, ffull)
  Ty.okd_all(Ty.okd_pack(ok_o, True{}), code_c)

# Per-store incidence walks (fuel 1 per slot; sub-resolves get full cap).
def es_incid_c(es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match es:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = es_incid_c(t, vs, f, ffull)
          +ok = edge_ends_live(h, vs, ffull)
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def ces_incid_c(ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match ces:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = ces_incid_c(t, es, f, ffull)
          +ok = ce_edge_live(h, es, ffull)
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def lps_incid_c(lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match lps:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = lps_incid_c(t, ces, f, ffull)
          +code = hce_live_c(Ty.lp_ces(h), ces, ffull, ffull)
          Ty.okd_all(code, rest)

def fas_incid_c(fas: List<&2, Ty.Face>, +lps: List<&2, Ty.Loop>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match fas:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = fas_incid_c(t, lps, f, ffull)
          +code = hlp_live_c(Ty.fa_loops(h), lps, ffull, ffull)
          Ty.okd_all(code, rest)

def shs_incid_c(shs: List<&2, Ty.Shell>, +fas: List<&2, Ty.Face>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match shs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = shs_incid_c(t, fas, f, ffull)
          +code = hfa_live_c(Ty.sh_faces(h), fas, ffull, ffull)
          Ty.okd_all(code, rest)

def sos_incid_c(sos: List<&2, Ty.Solid>, +shs: List<&2, Ty.Shell>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match sos:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = sos_incid_c(t, shs, f, ffull)
          +code = so_shells_live(h, shs, ffull)
          Ty.okd_all(code, rest)

def top_incid_c(+top: Ty.Compound, sos: List<&2, Ty.Solid>,
    shs: List<&2, Ty.Shell>, +ffull: Nat) -> Nat:
  +a = hso_live_c(Ty.cp_solids(top), sos, ffull, ffull)
  +b = hsh_live_c(Ty.cp_shells(top), shs, ffull, ffull)
  Ty.okd_all(a, b)

def brep_incid_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  +vs = Ty.brep_vs(b)
  +es = Ty.brep_es(b)
  +ces = Ty.brep_ces(b)
  +lps = Ty.brep_lps(b)
  +fas = Ty.brep_fas(b)
  +shs = Ty.brep_shs(b)
  +sos = Ty.brep_sos(b)
  +top = Ty.brep_top(b)
  Ty.okd_all(es_incid_c(es, vs, fuel, fuel),
    Ty.okd_all(ces_incid_c(ces, es, fuel, fuel),
      Ty.okd_all(lps_incid_c(lps, ces, fuel, fuel),
        Ty.okd_all(fas_incid_c(fas, lps, fuel, fuel),
          Ty.okd_all(shs_incid_c(shs, fas, fuel, fuel),
            Ty.okd_all(sos_incid_c(sos, shs, fuel, fuel),
              top_incid_c(top, sos, shs, fuel)))))))

# --- Stage C usage: per-edge coedge count + fwd (solid = twice opposite;
# open = once or twice-opposite). Inner scan threads (count, sawT, sawF). ---
def use_rule_ok(+count: Nat, saw_t: Bool, saw_f: Bool,
    p: Ty.Profile) -> Bool:
  match p:
    case Ty.P_manifold_solid{}:
      Bool.and(Nat.is_eq(count, 2n),
        Bool.and(saw_t, saw_f))
    case Ty.P_open_shell{}:
      Bool.or(Nat.is_eq(count, 1n),
        Bool.and(Nat.is_eq(count, 2n),
          Bool.and(saw_t, saw_f)))

def ces_use_go(ces: List<&2, Ty.Coedge>, +tgt: Ty.HEdge,
    +prof: Ty.Profile, fuel: Nat, +count: Nat, saw_t: Bool,
    saw_f: Bool) -> Nat:
  match ces:
    case Nil{}:
      Ty.okd_pack(use_rule_ok(count, saw_t, saw_f, prof), True{})
    case +h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +is_m = Ty.he_eq(Ty.ce_edge(h), tgt)
          +fwd = Ty.ce_fwd(h)
          +nc = Bool.pick(Nat, is_m, Nat.add(count, 1n), count)
          +nt = Bool.or(saw_t, Bool.and(is_m, fwd))
          +nf = Bool.or(saw_f, Bool.and(is_m, Bool.not(fwd)))
          ces_use_go(t, tgt, prof, f, nc, nt, nf)

def es_use_c(es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>,
    +prof: Ty.Profile, fuel: Nat, +ffull: Nat, +idx: Nat) -> Nat:
  match es:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +gen = Ty.ed_gen(h)
          +tgt = Ty.mk_he(idx, gen)
          +code = ces_use_go(ces, tgt, prof, ffull, 0n, False{},
            False{})
          +rest = es_use_c(t, ces, prof, f, ffull,
            Nat.add(idx, 1n))
          Ty.okd_all(code, rest)

def brep_use_c(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Nat:
  +es = Ty.brep_es(b)
  +ces = Ty.brep_ces(b)
  es_use_c(es, ces, prof, fuel, fuel, 0n)

# --- HVertex nodup for loop self-intersection (starts must be distinct). ---
def hv_free_of(xs: List<&2, Ty.HVertex>, +g: Ty.HVertex,
    fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hv_free_of(t, g, f)
          +neq = Bool.not(Ty.hv_eq(h, g))
          Ty.okd_pack(Bool.and(neq, Ty.okd_ok(rest)),
            Ty.okd_done(rest))

def hv_nodup_c(xs: List<&2, Ty.HVertex>, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +hg = h
          Ty.okd_all(hv_free_of(t, hg, ff), hv_nodup_c(t, ff))

# Oriented edge endpoints by coedge fwd.
def o_v_start(+e: Ty.Edge, fwd: Bool) -> Ty.HVertex:
  match fwd:
    case True{}: Ty.ed_v0(e)
    case False{}: Ty.ed_v1(e)

def o_v_end(+e: Ty.Edge, fwd: Bool) -> Ty.HVertex:
  match fwd:
    case True{}: Ty.ed_v1(e)
    case False{}: Ty.ed_v0(e)

# Loop chain tail walk: meets (vertex handles + uv) incremental, starts
# collected for nodup, closure checked at Nil. Runs after stage B passed,
# so all resolves succeed ( Tres defaults unreachable ); fuel exhaustion
# surfaces only from the outer walks. 10 args (arity-safe).
def loop_rest_go(rest: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, fuel: Nat, +ffull: Nat,
    +prev_v: Ty.HVertex, +first_v: Ty.HVertex, +prev_t: V.Vec2,
    +first_t: V.Vec2, +starts: List<&2, Ty.HVertex>) -> Nat:
  match rest:
    case Nil{}:
      +close_v = Ty.hv_eq(prev_v, first_v)
      +close_t = v2_eq(prev_t, first_t)
      +close_ok = Bool.and(close_v, close_t)
      +nd = hv_nodup_c(starts, ffull)
      Ty.okd_all(Ty.okd_pack(close_ok, True{}), nd)
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ce = Ty.tres_ce(Ty.ce_resolve(ces, h, ffull))
          +ed = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(ce), ffull))
          +fwd = Ty.ce_fwd(ce)
          +cs = o_v_start(ed, fwd)
          +ce_ = o_v_end(ed, fwd)
          +trim = Ty.ce_trim(ce)
          +ts = trim_o_start(trim, fwd)
          +te = trim_o_end(trim, fwd)
          +mv = Ty.hv_eq(prev_v, cs)
          +mt = v2_eq(prev_t, ts)
          +step = Bool.and(mv, mt)
          +rest2 = loop_rest_go(t, ces, es, f, ffull, ce_,
            first_v, te, first_t, cs <> starts)
          Ty.okd_all(Ty.okd_pack(step, True{}), rest2)

# One loop: peel first coedge, then tail walk (closure + nodup at Nil).
def loop_one_c(hcs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +ffull: Nat) -> Nat:
  match hcs:
    case Nil{}: 3n
    case fh <> rest:
      +fce = Ty.tres_ce(Ty.ce_resolve(ces, fh, ffull))
      +fed = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(fce), ffull))
      +ffwd = Ty.ce_fwd(fce)
      +fvs = o_v_start(fed, ffwd)
      +fve = o_v_end(fed, ffwd)
      +ftrim = Ty.ce_trim(fce)
      +fts = trim_o_start(ftrim, ffwd)
      +fte = trim_o_end(ftrim, ffwd)
      loop_rest_go(rest, ces, es, ffull, ffull, fve, fvs, fte,
        fts, fvs <> Nil{})

def lps_loop_c(lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, fuel: Nat, +ffull: Nat) -> Nat:
  match lps:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = lps_loop_c(t, ces, es, f, ffull)
          +code = loop_one_c(Ty.lp_ces(h), ces, es, ffull)
          Ty.okd_all(code, rest)

def brep_loop_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  +lps = Ty.brep_lps(b)
  +ces = Ty.brep_ces(b)
  +es = Ty.brep_es(b)
  lps_loop_c(lps, ces, es, fuel, fuel)

# --- Stage E face kinds: exactly one LK_outer per face (tag 0). ---
def hlp_outer_go(hls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>,
    fuel: Nat, +ffull: Nat, +count: Nat) -> Nat:
  match hls:
    case Nil{}:
      Ty.okd_pack(Nat.is_eq(count, 1n), True{})
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +lp = Ty.tres_lp(Ty.lp_resolve(lps, h, ffull))
          +is_o = U64.is_eq(Ty.lkind_tag(Ty.lp_kind(lp)), 0u64)
          +nc = Bool.pick(Nat, is_o, Nat.add(count, 1n), count)
          hlp_outer_go(t, lps, f, ffull, nc)

def fas_kind_c(fas: List<&2, Ty.Face>, +lps: List<&2, Ty.Loop>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match fas:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = fas_kind_c(t, lps, f, ffull)
          +code = hlp_outer_go(Ty.fa_loops(h), lps, ffull, ffull, 0n)
          Ty.okd_all(code, rest)

def brep_facekind_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  +fas = Ty.brep_fas(b)
  +lps = Ty.brep_lps(b)
  fas_kind_c(fas, lps, fuel, fuel)

# --- Stage F profile: solid forbids SK_open (tag 2), cavities SK_inner(1). ---
def shs_no_open_c(shs: List<&2, Ty.Shell>, fuel: Nat) -> Nat:
  match shs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = shs_no_open_c(t, f)
          +ok = U64.is_ne(Ty.skind_tag(Ty.sh_kind(h)), 2u64)
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def hsh_all_inner_go(hs: List<&2, Ty.HShell>, +shs: List<&2, Ty.Shell>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match hs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hsh_all_inner_go(t, shs, f, ffull)
          +sh = Ty.tres_sh(Ty.sh_resolve(shs, h, ffull))
          +ok = U64.is_eq(Ty.skind_tag(Ty.sh_kind(sh)), 1u64)
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def sos_cav_inner_c(sos: List<&2, Ty.Solid>, +shs: List<&2, Ty.Shell>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match sos:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = sos_cav_inner_c(t, shs, f, ffull)
          +code = hsh_all_inner_go(Ty.so_cavities(h), shs, ffull,
            ffull)
          Ty.okd_all(code, rest)

def brep_prof_c(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Nat:
  match prof:
    case Ty.P_manifold_solid{}:
      +shs = Ty.brep_shs(b)
      +sos = Ty.brep_sos(b)
      Ty.okd_all(shs_no_open_c(shs, fuel),
        sos_cav_inner_c(sos, shs, fuel, fuel))
    case Ty.P_open_shell{}: 3n

# --- Stage G embedding: C03 interiors + vertex-on-curve + trim coincidence
# (plane/bezp only; other surfaces skip 3D coincidence, see header). ---
def es_embed_c(es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match es:
    case Nil{}: 3n
    case +h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = es_embed_c(t, vs, f, ffull)
          +kind = Ty.ed_kind(h)
          +is_curve = Ty.ekind_is_curve(kind)
          +cv = Ty.ekind_curve(kind)
          +fin_ok = Bool.or(Bool.not(is_curve),
            curve_fin_ok(cv, ffull))
          +p0 = Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs, Ty.ed_v0(h),
            ffull)))
          +p1 = Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs, Ty.ed_v1(h),
            ffull)))
          +on_ok = edge_ends_on_curve(kind, p0, p1, ffull)
          +ok = Bool.and(fin_ok, on_ok)
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def ces_trimfin_c(ces: List<&2, Ty.Coedge>, fuel: Nat) -> Nat:
  match ces:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = ces_trimfin_c(t, f)
          +ok = trim_fin(Ty.ce_trim(h))
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def fas_surf_c(fas: List<&2, Ty.Face>, fuel: Nat) -> Nat:
  match fas:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = fas_surf_c(t, f)
          +ok = surf_fin_ok(Ty.fa_surf(h))
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

# One coedge trim coincidence: surf(trim ends) == oriented vertex points.
# Runs after B (resolves succeed); surf is plane/bezp (eval supported).
def ce_coinc_ok(+ce: Ty.Coedge, +ed: Ty.Edge, +vs: List<&2, Ty.Vertex>,
    +surf: G.GVal, +ffull: Nat) -> Bool:
  +fwd = Ty.ce_fwd(ce)
  +trim = Ty.ce_trim(ce)
  +ts = trim_o_start(trim, fwd)
  +te = trim_o_end(trim, fwd)
  +hv_s = o_v_start(ed, fwd)
  +hv_e = o_v_end(ed, fwd)
  +ps = Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs, hv_s, ffull)))
  +pe = Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs, hv_e, ffull)))
  +rs = surf_at(surf, V.v2_x(ts), V.v2_y(ts))
  +re = surf_at(surf, V.v2_x(te), V.v2_y(te))
  Bool.and(G.gres_ok(rs),
    Bool.and(G.gres_ok(re),
      Bool.and(pt_eq(G.gres_p(rs), ps), pt_eq(G.gres_p(re), pe))))

def hce_coinc_go(hcs: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, +surf: G.GVal,
    fuel: Nat, +ffull: Nat) -> Nat:
  match hcs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hce_coinc_go(t, ces, es, vs, surf, f, ffull)
          +ce = Ty.tres_ce(Ty.ce_resolve(ces, h, ffull))
          +ed = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(ce), ffull))
          +ok = ce_coinc_ok(ce, ed, vs, surf, ffull)
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

def hlp_coinc_go(hls: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>,
    +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, +surf: G.GVal, fuel: Nat,
    +ffull: Nat) -> Nat:
  match hls:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hlp_coinc_go(t, lps, ces, es, vs, surf, f, ffull)
          +lp = Ty.tres_lp(Ty.lp_resolve(lps, h, ffull))
          +code = hce_coinc_go(Ty.lp_ces(lp), ces, es, vs, surf,
            ffull, ffull)
          Ty.okd_all(code, rest)

# Per-face coincidence dispatch (plane/bezp checked, others skip 3D).
def face_coinc_one(surf: G.GVal, loops: List<&2, Ty.HLoop>,
    +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>,
    +ffull: Nat) -> Nat:
  match surf:
    case G.GV_pl{w}:
      hlp_coinc_go(loops, lps, ces, es, vs, surf, ffull, ffull)
    case G.GV_bp{w}:
      hlp_coinc_go(loops, lps, ces, es, vs, surf, ffull, ffull)
    case _: 3n

def fas_coinc_c(fas: List<&2, Ty.Face>, +lps: List<&2, Ty.Loop>,
    +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, fuel: Nat, +ffull: Nat) -> Nat:
  match fas:
    case Nil{}: 3n
    case +h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = fas_coinc_c(t, lps, ces, es, vs, f, ffull)
          +code = face_coinc_one(Ty.fa_surf(h), Ty.fa_loops(h), lps,
            ces, es, vs, ffull)
          Ty.okd_all(code, rest)

def brep_embed_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  +vs = Ty.brep_vs(b)
  +es = Ty.brep_es(b)
  +ces = Ty.brep_ces(b)
  +lps = Ty.brep_lps(b)
  +fas = Ty.brep_fas(b)
  Ty.okd_all(es_embed_c(es, vs, fuel, fuel),
    Ty.okd_all(ces_trimfin_c(ces, fuel),
      Ty.okd_all(fas_surf_c(fas, fuel),
        fas_coinc_c(fas, lps, ces, es, vs, fuel, fuel))))

# --- brep_checked pipeline (sequential via picks; earlier invalid wins over
# later exhaustion; earlier exhaustion wins over later anything). ---
def brep_ck_g(+b: Ty.Brep, +fuel: Nat) -> Ty.TRes:
  +cg = brep_embed_c(b, fuel)
  +done_g = Ty.okd_done(cg)
  +ok_g = Ty.okd_ok(cg)
  +win = Ty.tok_brep(b)
  +ok_branch = Bool.pick(Ty.TRes, ok_g, win, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_g, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_f(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +cf = brep_prof_c(b, prof, fuel)
  +done_f = Ty.okd_done(cf)
  +ok_f = Ty.okd_ok(cf)
  +rest = brep_ck_g(b, fuel)
  +ok_branch = Bool.pick(Ty.TRes, ok_f, rest, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_f, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_e(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +ce = brep_facekind_c(b, fuel)
  +done_e = Ty.okd_done(ce)
  +ok_e = Ty.okd_ok(ce)
  +rest = brep_ck_f(b, prof, fuel)
  +ok_branch = Bool.pick(Ty.TRes, ok_e, rest, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_e, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_d(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +cd = brep_loop_c(b, fuel)
  +done_d = Ty.okd_done(cd)
  +ok_d = Ty.okd_ok(cd)
  +rest = brep_ck_e(b, prof, fuel)
  +ok_branch = Bool.pick(Ty.TRes, ok_d, rest, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_d, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_c(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +cc = brep_use_c(b, prof, fuel)
  +done_c = Ty.okd_done(cc)
  +ok_c = Ty.okd_ok(cc)
  +rest = brep_ck_d(b, prof, fuel)
  +ok_branch = Bool.pick(Ty.TRes, ok_c, rest, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_c, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_b(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +cb = brep_incid_c(b, fuel)
  +done_b = Ty.okd_done(cb)
  +ok_b = Ty.okd_ok(cb)
  +rest = brep_ck_c(b, prof, fuel)
  +ok_branch = Bool.pick(Ty.TRes, ok_b, rest, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_b, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_checked(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +vs = Ty.brep_vs(b)
  +es = Ty.brep_es(b)
  +ces = Ty.brep_ces(b)
  +lps = Ty.brep_lps(b)
  +fas = Ty.brep_fas(b)
  +shs = Ty.brep_shs(b)
  +sos = Ty.brep_sos(b)
  +top = Ty.brep_top(b)
  +stamp = Ty.brep_stamp(b)
  +ra = Ty.mk_brep(vs, es, ces, lps, fas, shs, sos, top, stamp,
    fuel)
  +ok_a = Ty.tres_ok(ra)
  +rest = brep_ck_b(b, prof, fuel)
  Bool.pick(Ty.TRes, ok_a, rest, ra)
