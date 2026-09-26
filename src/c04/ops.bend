# C04 boundary-representation validators: brep_checked under explicit profiles.
# Data + constructors live in types.bend; this file validates incidence,
# edge-use pairing, loop closure, trimming, embedding, shell ownership,
# and solid/open rules.
# Every failure is C00 FailKind (invalid-input or resource-exhausted); no new
# taxonomy. Every list walk is Nat-fuel-bounded (BN-8); handles are
# generational (idx, gen) into explicit Brep lists (BN-7); no batch ops (BN-9).
#
# Pipeline (first match wins; order matters for exhausted-vs-invalid):
#  A. store re-validation via mk_brep (value + gen + nodup; catches raw Br).
#  B. incidence: every member handle resolves (dangling => invalid).
#  C. edge-use pairing: solid = exactly twice opposite fwd; open =
#     once/twice (twice => opposite). Covers inverted,
#     nonmanifold-edge, open-boundary. This is PAIRING only: face/shell
#     orientation coherence (outward normals) is DEFERRED, contract §12.
#  D. loop closure (oriented vertex chain meets + closed) +
#     repeated-start-vertex check (a narrow duplicate-vertex proxy, NOT
#     general geometric self-intersection, contract §12) + trimming
#     meets in face (u,v).
#  E. face loop kinds: exactly one LK_outer per face.
#  F. shell/solid/profile: solid forbids SK_open, outer IS SK_outer,
#     cavities are SK_inner, and every shell is owned at most once (no
#     outer/cavity aliasing, no cavity dup, no reuse across solids, no
#     sharing between solids and the compound root); open admits SK_open
#     and boundary (once-used) edges and skips solid/cavity ownership.
#  G. embedding: C03 interior validity + vertex-on-curve (all curves) +
#     trim-on-surface coincidence for plane/bezp only (sphere/cyl/cone/torus
#     have no C03 surface eval; their trims pass on uv-meet + finiteness).
#  H. vertex links (C04.2): every coedge in exactly one loop; each
#     vertex fan a single twin(prev()) orbit over non-degenerate
#     outgoing uses (degenerate uses transparent; poles vacuous).
#  I. shell connectedness (C04.2): faces of each shell connected
#     via shared edges (BFS from the first face; both profiles).
#  J. coincident distinct vertices: no two vertex slots share one
#     point (exact C02 pteq3 pairwise; both profiles).
#  K. same-face straight-edge segment crossing: no two non-adjacent
#     line-curve edges of one face cross (C02 orient3d coplanarity
#     + seg_seg proper in xy/xz/yz; curved edges out of scope;
#     both profiles).
#  L. orientation: per-face boundary winding agrees with the
#     same-adjusted surface normal (plane/bezp/quadric C03 normals;
#     zero-area winding or unavailable normal skips), and shared
#     edges propagate same-flag agreement across distinct faces
#     (seams and boundary edges skip; both profiles).
# On success returns Tok brep (the validated input); else Terr.

import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c02/types.bend as P
import ../c02/ops.bend as PO
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

# --- HVertex nodup for the repeated-start-vertex proxy (starts must be
# distinct). Narrow duplicate-handle check only, NOT general geometric
# self-intersection (contract §12). ---
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

# --- Stage F profile: solid forbids SK_open (tag 2), outer IS SK_outer
# (tag 0), cavities SK_inner (tag 1), and every shell is owned at most
# once. Runs after stage B, so all resolves succeed (Tres defaults
# unreachable). P_open_shell skips solid/cavity ownership entirely. ---
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

def sos_outer_kind_c(sos: List<&2, Ty.Solid>, +shs: List<&2, Ty.Shell>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match sos:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = sos_outer_kind_c(t, shs, f, ffull)
          +sh = Ty.tres_sh(Ty.sh_resolve(shs, Ty.so_outer(h), ffull))
          +ok = U64.is_eq(Ty.skind_tag(Ty.sh_kind(sh)), 0u64)
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)), Ty.okd_done(rest))

# One solid's owned shell handles: outer first, then cavities.
def so_sh_list(+s: Ty.Solid) -> List<&2, Ty.HShell>:
  Ty.so_outer(s) <> Ty.so_cavities(s)

# HShell absence + nodup (mirrors hv_free_of/hv_nodup_c).
def hsh_free_of(xs: List<&2, Ty.HShell>, +g: Ty.HShell,
    fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hsh_free_of(t, g, f)
          +neq = Bool.not(Ty.hsh_eq(h, g))
          Ty.okd_pack(Bool.and(neq, Ty.okd_ok(rest)),
            Ty.okd_done(rest))

def hsh_nodup_c(xs: List<&2, Ty.HShell>, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +hg = h
          Ty.okd_all(hsh_free_of(t, hg, ff), hsh_nodup_c(t, ff))

# Every handle in xs absent from ys (fuel 1 per xs element; each
# absence scan gets the full cap).
def hsh_list_free_of(xs: List<&2, Ty.HShell>,
    +ys: List<&2, Ty.HShell>, fuel: Nat, +ffull: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hsh_list_free_of(t, ys, f, ffull)
          +code = hsh_free_of(ys, h, ffull)
          Ty.okd_all(code, rest)

# Handles in xs absent from every solid's owned shells in sos.
def hsh_free_of_sos(+xs: List<&2, Ty.HShell>,
    +sos: List<&2, Ty.Solid>, fuel: Nat, +ffull: Nat) -> Nat:
  match sos:
    case Nil{}: 3n
    case s <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hsh_free_of_sos(xs, t, f, ffull)
          +code = hsh_list_free_of(xs, so_sh_list(s), ffull,
            ffull)
          Ty.okd_all(code, rest)

# Per-solid ownership: internal nodup (outer not among cavities, no
# cavity dup) + disjointness from every LATER solid (pairwise across
# the store by induction, mirroring the nodup_c pattern).
def sos_own_c(sos: List<&2, Ty.Solid>, fuel: Nat,
    +ffull: Nat) -> Nat:
  match sos:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +hh = so_sh_list(h)
          +self_nd = hsh_nodup_c(hh, ffull)
          +vs_tail = hsh_free_of_sos(hh, t, ffull, ffull)
          +rest = sos_own_c(t, ff, ffull)
          Ty.okd_all(self_nd, Ty.okd_all(vs_tail, rest))

# Compound open sheets: nodup + disjoint from every solid's shells.
def cp_sh_own_c(+top: Ty.Compound, +sos: List<&2, Ty.Solid>,
    +ffull: Nat) -> Nat:
  +cs = Ty.cp_shells(top)
  Ty.okd_all(hsh_nodup_c(cs, ffull),
    hsh_free_of_sos(cs, sos, ffull, ffull))

def brep_prof_c(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Nat:
  match prof:
    case Ty.P_manifold_solid{}:
      +shs = Ty.brep_shs(b)
      +sos = Ty.brep_sos(b)
      +top = Ty.brep_top(b)
      Ty.okd_all(shs_no_open_c(shs, fuel),
        Ty.okd_all(sos_cav_inner_c(sos, shs, fuel, fuel),
          Ty.okd_all(sos_outer_kind_c(sos, shs, fuel, fuel),
            Ty.okd_all(sos_own_c(sos, fuel, fuel),
              cp_sh_own_c(top, sos, fuel)))))
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

# --- Quadric vertex membership (C04.2 G-extension): every face
# vertex on the implicit quadric (P1 exact predicates). Trim (u,v)
# endpoints stay unchecked on quadrics (no surf_at; C03
# surface-eval extension prerequisite). ---
def vx_surf_on(+vs: List<&2, Ty.Vertex>, +hv: Ty.HVertex,
    +surf: G.GVal, +ffull: Nat) -> Bool:
  match surf:
    case G.GV_sp{w}:
      GO.sph_on(w, Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs, hv,
        ffull))))
    case G.GV_cy{w}:
      GO.cyl_on(w, Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs, hv,
        ffull))))
    case G.GV_co{w}:
      GO.cone_on(w, Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs, hv,
        ffull))))
    case G.GV_to{w}:
      GO.tor_on(w, Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs, hv,
        ffull))))
    case _: False{}

def hce_memb_go(hcs: List<&2, Ty.HCoedge>,
    +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, +surf: G.GVal, fuel: Nat,
    +ffull: Nat) -> Nat:
  match hcs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hce_memb_go(t, ces, es, vs, surf, f, ffull)
          +ce = Ty.tres_ce(Ty.ce_resolve(ces, h, ffull))
          +ed = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(ce),
            ffull))
          +fw = Ty.ce_fwd(ce)
          +ok = Bool.and(vx_surf_on(vs, o_v_start(ed, fw),
              surf, ffull),
            vx_surf_on(vs, o_v_end(ed, fw), surf, ffull))
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)),
            Ty.okd_done(rest))

def hlp_memb_go(hls: List<&2, Ty.HLoop>,
    +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>,
    +surf: G.GVal, fuel: Nat, +ffull: Nat) -> Nat:
  match hls:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hlp_memb_go(t, lps, ces, es, vs, surf, f,
            ffull)
          +lp = Ty.tres_lp(Ty.lp_resolve(lps, h, ffull))
          +code = hce_memb_go(Ty.lp_ces(lp), ces, es, vs,
            surf, ffull, ffull)
          Ty.okd_all(code, rest)

def face_memb_one(surf: G.GVal, loops: List<&2, Ty.HLoop>,
    +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>,
    +ffull: Nat) -> Nat:
  match surf:
    case G.GV_sp{w}:
      hlp_memb_go(loops, lps, ces, es, vs, surf, ffull, ffull)
    case G.GV_cy{w}:
      hlp_memb_go(loops, lps, ces, es, vs, surf, ffull, ffull)
    case G.GV_co{w}:
      hlp_memb_go(loops, lps, ces, es, vs, surf, ffull, ffull)
    case G.GV_to{w}:
      hlp_memb_go(loops, lps, ces, es, vs, surf, ffull, ffull)
    case _: 3n

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
          +sf = Ty.fa_surf(h)
          +ll = Ty.fa_loops(h)
          +code = face_coinc_one(sf, ll, lps, ces, es, vs,
            ffull)
          +memb = face_memb_one(sf, ll, lps, ces, es, vs,
            ffull)
          Ty.okd_all(code, Ty.okd_all(memb, rest))

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
# --- Stage H vertex links: single-fan per vertex (solid profile).
# Fan permutation is twin(prev()) over loop order; one orbit must
# cover every non-degenerate outgoing use. Degenerate (collapsed)
# uses are transparent (they subtend no fan sector), so poles pass
# vacuously when no non-degenerate fan exists. Every coedge must
# sit in exactly one store loop (traversal well-definedness).
# Fuel discipline: outer walks decrement fuel; inner scans take
# constant ffull, exact because stage B already walked every store
# scanned here (ffull shortage exhausts at B before H runs). ---
def hc_mem(xs: List<&2, Ty.HCoedge>, +hc: Ty.HCoedge,
    +ffull: Nat) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t:
      match ffull:
        case 0n: False{}
        case 1n+f:
          Bool.or(Ty.hc_eq(h, hc), hc_mem(t, hc, f))

def hc_last_go(xs: List<&2, Ty.HCoedge>, +cand: Ty.HCoedge,
    +ffull: Nat) -> Ty.HCoedge:
  match xs:
    case Nil{}: cand
    case h <> t:
      match ffull:
        case 0n: cand
        case 1n+f: hc_last_go(t, h, f)

def hc_last(xs: List<&2, Ty.HCoedge>, +dflt: Ty.HCoedge,
    +ffull: Nat) -> Ty.HCoedge:
  hc_last_go(xs, dflt, ffull)

def lp_prev_go(xs: List<&2, Ty.HCoedge>, +hc: Ty.HCoedge,
    +prev: Ty.HCoedge, +ffull: Nat) -> Ty.HCoedge:
  match xs:
    case Nil{}: hc
    case +h <> t:
      match ffull:
        case 0n: hc
        case 1n+f:
          Bool.pick(Ty.HCoedge, Ty.hc_eq(h, hc), prev,
            lp_prev_go(t, hc, h, f))

def lp_prev_in(+xs: List<&2, Ty.HCoedge>, +hc: Ty.HCoedge,
    +ffull: Nat) -> Ty.HCoedge:
  lp_prev_go(xs, hc, hc_last(xs, hc, ffull), ffull)

def hc_prev(+lps: List<&2, Ty.Loop>, +hc: Ty.HCoedge,
    +ffull: Nat) -> Ty.HCoedge:
  match lps:
    case Nil{}: hc
    case h <> t:
      match ffull:
        case 0n: hc
        case 1n+f:
          +ces = Ty.lp_ces(h)
          Bool.pick(Ty.HCoedge, hc_mem(ces, hc, ffull),
            lp_prev_in(ces, hc, ffull), hc_prev(t, hc, f))

def hc_twin_go(ces: List<&2, Ty.Coedge>, +se: Ty.HEdge,
    +shc: Ty.HCoedge, +idx: Nat, +ffull: Nat) -> Ty.HCoedge:
  match ces:
    case Nil{}: shc
    case +h <> t:
      match ffull:
        case 0n: shc
        case 1n+f:
          +hh = Ty.mk_hc(idx, Ty.ce_gen(h))
          +hit = Bool.and(Ty.he_eq(Ty.ce_edge(h), se),
            Bool.not(Ty.hc_eq(hh, shc)))
          Bool.pick(Ty.HCoedge, hit, hh,
            hc_twin_go(t, se, shc, Nat.add(idx, 1n), f))

def hc_nondegen(+ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +hc: Ty.HCoedge,
    +ffull: Nat) -> Bool:
  +ce = Ty.tres_ce(Ty.ce_resolve(ces, hc, ffull))
  +ed = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(ce), ffull))
  Bool.not(U64.is_eq(Ty.ekind_tag(Ty.ed_kind(ed)), 1u64))

def hc_step(+b: Ty.Brep, +hc: Ty.HCoedge,
    +ffull: Nat) -> Ty.HCoedge:
  +p = hc_prev(Ty.brep_lps(b), hc, ffull)
  +pc = Ty.tres_ce(Ty.ce_resolve(Ty.brep_ces(b), p, ffull))
  +pe = Ty.ce_edge(pc)
  hc_twin_go(Ty.brep_ces(b), pe, p, 0n, ffull)

def hc_cov_some(+lps: List<&2, Ty.Loop>, +hc: Ty.HCoedge,
    fuel: Nat, +ffull: Nat) -> Nat:
  match lps:
    case Nil{}: 2n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +here = hc_mem(Ty.lp_ces(h), hc, ffull)
          Bool.pick(Nat, here, 3n, hc_cov_some(t, hc, f, ffull))

def hc_cov_one(+lps: List<&2, Ty.Loop>, +hc: Ty.HCoedge,
    fuel: Nat, +ffull: Nat) -> Nat:
  match lps:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +here = hc_mem(Ty.lp_ces(h), hc, ffull)
          +later = hc_cov_some(t, hc, ffull, ffull)
          +excl = Bool.not(Bool.and(here, Ty.okd_ok(later)))
          +rest = hc_cov_one(t, hc, f, ffull)
          Ty.okd_all(Ty.okd_pack(excl, Ty.okd_done(later)), rest)

def ces_cov_go(ces: List<&2, Ty.Coedge>,
    +lps: List<&2, Ty.Loop>, +idx: Nat, fuel: Nat,
    +ffull: Nat) -> Nat:
  match ces:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +hh = Ty.mk_hc(idx, Ty.ce_gen(h))
          +some = hc_cov_some(lps, hh, ffull, ffull)
          +one = hc_cov_one(lps, hh, ffull, ffull)
          +rest = ces_cov_go(t, lps, Nat.add(idx, 1n), f, ffull)
          Ty.okd_all(some, Ty.okd_all(one, rest))

def ces_start_pick(hit: Bool, +hh: Ty.HCoedge,
    +rest: List<&2, Ty.HCoedge>) -> List<&2, Ty.HCoedge>:
  match hit:
    case True{}: hh <> rest
    case False{}: rest

def ces_start_go(ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +v: Ty.HVertex, +idx: Nat,
    +ffull: Nat) -> List<&2, Ty.HCoedge>:
  match ces:
    case Nil{}: Nil{}
    case +h <> t:
      match ffull:
        case 0n: Nil{}
        case 1n+f:
          +hh = Ty.mk_hc(idx, Ty.ce_gen(h))
          +ed = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(h),
            ffull))
          +rest = ces_start_go(t, es, v, Nat.add(idx, 1n), f)
          +hit = Ty.hv_eq(o_v_start(ed, Ty.ce_fwd(h)), v)
          ces_start_pick(hit, hh, rest)

def hc_count_nd(+ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, ss: List<&2, Ty.HCoedge>,
    +ffull: Nat) -> Nat:
  match ss:
    case Nil{}: 0n
    case h <> t:
      match ffull:
        case 0n: 0n
        case 1n+f:
          +rest = hc_count_nd(ces, es, t, f)
          Bool.pick(Nat, hc_nondegen(ces, es, h, ffull),
            Nat.add(rest, 1n), rest)

def hc_first_nd(+ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, ss: List<&2, Ty.HCoedge>,
    +ffull: Nat) -> Ty.HCoedge:
  match ss:
    case Nil{}: Ty.hc_null()
    case +h <> t:
      match ffull:
        case 0n: Ty.hc_null()
        case 1n+f:
          Bool.pick(Ty.HCoedge, hc_nondegen(ces, es, h, ffull),
            h, hc_first_nd(ces, es, t, f))

# Closure is tested on the step TARGET before recursing, and the
# caller seeds k=1 for {start} visited: each orbit element is
# counted exactly once (H-ORBIT fix: the old code stepped, counted
# the arrival, and only then tested cur==start, double-counting the
# closing revisit as steps=nd+1 on every closed single orbit).
def vorbit_go(+b: Ty.Brep, +start: Ty.HCoedge, fuel: Nat,
    +cur: Ty.HCoedge, +k: Nat, +ffull: Nat) -> Ty.VOrbit:
  match fuel:
    case 0n:
      Bool.pick(Ty.VOrbit, Ty.hc_eq(cur, start),
        Ty.VO{k, True{}}, Ty.VO{k, False{}})
    case 1n+f:
      +nxt = hc_step(b, cur, ffull)
      +nn = Bool.pick(Nat,
        hc_nondegen(Ty.brep_ces(b), Ty.brep_es(b), nxt, ffull),
        Nat.add(k, 1n), k)
      Bool.pick(Ty.VOrbit, Ty.hc_eq(nxt, start),
        Ty.VO{nn, True{}}, vorbit_go(b, start, f, nxt, nn,
          ffull))

def vx_link_orbit(+b: Ty.Brep, ss: List<&2, Ty.HCoedge>,
    +nd: Nat, fuel: Nat, +ffull: Nat) -> Nat:
  +ces = Ty.brep_ces(b)
  +es = Ty.brep_es(b)
  +st = hc_first_nd(ces, es, ss, ffull)
  +c1 = hc_step(b, st, ffull)
  +vo = Bool.pick(Ty.VOrbit, Ty.hc_eq(c1, st),
    Ty.VO{1n, True{}}, vorbit_go(b, st, fuel, c1, 1n, ffull))
  +done = Ty.vo_closed(vo)
  Ty.okd_pack(Bool.and(done, Nat.is_eq(Ty.vo_steps(vo), nd)),
    done)

def vx_link_ok(+b: Ty.Brep, +v: Ty.HVertex, fuel: Nat,
    +ffull: Nat) -> Nat:
  match fuel:
    case 0n: 0n
    case 1n+f:
      +ces = Ty.brep_ces(b)
      +es = Ty.brep_es(b)
      +ss = ces_start_go(ces, es, v, 0n, ffull)
      +nd = hc_count_nd(ces, es, ss, ffull)
      Bool.pick(Nat, Nat.is_eq(nd, 0n), 3n,
        vx_link_orbit(b, ss, nd, f, ffull))

def vs_link_go(vs: List<&2, Ty.Vertex>, +b: Ty.Brep,
    +idx: Nat, fuel: Nat, +ffull: Nat) -> Nat:
  match vs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +vv = Ty.mk_hv(idx, Ty.vx_gen(h))
          +code = vx_link_ok(b, vv, ffull, ffull)
          +rest = vs_link_go(t, b, Nat.add(idx, 1n), f, ffull)
          Ty.okd_all(code, rest)

def brep_link_c(+b: Ty.Brep, +prof: Ty.Profile,
    +fuel: Nat) -> Nat:
  match prof:
    case Ty.P_manifold_solid{}:
      Ty.okd_all(ces_cov_go(Ty.brep_ces(b), Ty.brep_lps(b),
        0n, fuel, fuel),
        vs_link_go(Ty.brep_vs(b), b, 0n, fuel, fuel))
    case Ty.P_open_shell{}: 3n

# --- Stage I shell connectedness (C04.2): faces of each shell
# connected via shared edges (BFS from the first face; dedup seen
# and frontier so pops stay within the face count). Both profiles:
# an open sheet is one connected surface too. Inner scans take
# constant ffull (exact: stage B walked every store scanned here). ---
def hfa_mem(xs: List<&2, Ty.HFace>, +h: Ty.HFace,
    +ffull: Nat) -> Bool:
  match xs:
    case Nil{}: False{}
    case g <> t:
      match ffull:
        case 0n: False{}
        case 1n+f:
          Bool.or(Ty.hfa_eq(g, h), hfa_mem(t, h, f))

def hfa_len(+xs: List<&2, Ty.HFace>, +ffull: Nat) -> Nat:
  match xs:
    case Nil{}: 0n
    case g <> t:
      match ffull:
        case 0n: 0n
        case 1n+f: Nat.add(hfa_len(t, f), 1n)

def hcs_have_edge(hcs: List<&2, Ty.HCoedge>, +tgt: Ty.HEdge,
    +ces: List<&2, Ty.Coedge>, +ffull: Nat) -> Bool:
  match hcs:
    case Nil{}: False{}
    case h <> t:
      match ffull:
        case 0n: False{}
        case 1n+f:
          +ce = Ty.tres_ce(Ty.ce_resolve(ces, h, ffull))
          Bool.or(Ty.he_eq(Ty.ce_edge(ce), tgt),
            hcs_have_edge(t, tgt, ces, f))

def hcs_share_edge(hcs1: List<&2, Ty.HCoedge>,
    +hcs2: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>,
    +ffull: Nat) -> Bool:
  match hcs1:
    case Nil{}: False{}
    case h <> t:
      match ffull:
        case 0n: False{}
        case 1n+f:
          +ce = Ty.tres_ce(Ty.ce_resolve(ces, h, ffull))
          Bool.or(hcs_have_edge(hcs2, Ty.ce_edge(ce), ces,
            ffull), hcs_share_edge(t, hcs2, ces, f))

def hls_have_edge(+hls2: List<&2, Ty.HLoop>,
    +lpces: List<&2, Ty.HCoedge>, +lps: List<&2, Ty.Loop>,
    +ces: List<&2, Ty.Coedge>, +ffull: Nat) -> Bool:
  match hls2:
    case Nil{}: False{}
    case h <> t:
      match ffull:
        case 0n: False{}
        case 1n+f:
          +lp = Ty.tres_lp(Ty.lp_resolve(lps, h, ffull))
          Bool.or(hcs_share_edge(lpces, Ty.lp_ces(lp), ces,
            ffull), hls_have_edge(t, lpces, lps, ces, f))

def hlps_share_edge(hls1: List<&2, Ty.HLoop>,
    +hls2: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>,
    +ces: List<&2, Ty.Coedge>, +ffull: Nat) -> Bool:
  match hls1:
    case Nil{}: False{}
    case h <> t:
      match ffull:
        case 0n: False{}
        case 1n+f:
          +lp = Ty.tres_lp(Ty.lp_resolve(lps, h, ffull))
          Bool.or(hls_have_edge(hls2, Ty.lp_ces(lp), lps,
            ces, ffull), hlps_share_edge(t, hls2, lps, ces,
            f))

def faces_share_edge(+b: Ty.Brep, +f1: Ty.HFace,
    +f2: Ty.HFace, +ffull: Nat) -> Bool:
  +fa1 = Ty.tres_fa(Ty.fa_resolve(Ty.brep_fas(b), f1, ffull))
  +fa2 = Ty.tres_fa(Ty.fa_resolve(Ty.brep_fas(b), f2, ffull))
  hlps_share_edge(Ty.fa_loops(fa1), Ty.fa_loops(fa2),
    Ty.brep_lps(b), Ty.brep_ces(b), ffull)

def sh_seen_add_go(hit: Bool, +seen: List<&2, Ty.HFace>,
    +f: Ty.HFace) -> List<&2, Ty.HFace>:
  match hit:
    case True{}: seen
    case False{}: f <> seen

def sh_seen_add(+seen: List<&2, Ty.HFace>, +f: Ty.HFace,
    +ffull: Nat) -> List<&2, Ty.HFace>:
  sh_seen_add_go(hfa_mem(seen, f, ffull), seen, f)

def sh_front_pick(hit: Bool, +g: Ty.HFace,
    +rest: List<&2, Ty.HFace>) -> List<&2, Ty.HFace>:
  match hit:
    case True{}: g <> rest
    case False{}: rest

def sh_frontier(+b: Ty.Brep, +f: Ty.HFace,
    all: List<&2, Ty.HFace>, +seen: List<&2, Ty.HFace>,
    +ffull: Nat) -> List<&2, Ty.HFace>:
  match all:
    case Nil{}: Nil{}
    case +g <> t:
      match ffull:
        case 0n: Nil{}
        case 1n+h:
          +rest = sh_frontier(b, f, t, seen, h)
          +new = Bool.and(faces_share_edge(b, f, g, ffull),
            Bool.not(hfa_mem(seen, g, ffull)))
          sh_front_pick(new, g, rest)

def hfa_prepend_pick(hit: Bool, +h: Ty.HFace,
    +rest: List<&2, Ty.HFace>) -> List<&2, Ty.HFace>:
  match hit:
    case True{}: h <> rest
    case False{}: rest

def hfa_prepend_new(fr: List<&2, Ty.HFace>,
    +todo: List<&2, Ty.HFace>, +seen: List<&2, Ty.HFace>,
    +ffull: Nat) -> List<&2, Ty.HFace>:
  match fr:
    case Nil{}: todo
    case +h <> t:
      match ffull:
        case 0n: todo
        case 1n+f:
          +rest = hfa_prepend_new(t, todo, seen, f)
          +fresh = Bool.and(Bool.not(hfa_mem(todo, h, ffull)),
            Bool.not(hfa_mem(seen, h, ffull)))
          hfa_prepend_pick(fresh, h, rest)

# Fuel-explicit list coverage (I-LEN fix): hfa_len truncates at
# fuel-out, so comparing truncated lengths alone is fail-open on
# direct calls with short fuel. Coverage gates both bits.
def hfa_walked(xs: List<&2, Ty.HFace>, fuel: Nat) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t:
      match fuel:
        case 0n: False{}
        case 1n+f: hfa_walked(t, f)

def sh_bfs_done(+seen: List<&2, Ty.HFace>,
    +all: List<&2, Ty.HFace>, +ffull: Nat) -> Nat:
  +w = hfa_walked(all, ffull)
  +eq = Nat.is_eq(hfa_len(seen, ffull), hfa_len(all, ffull))
  +ok = Bool.and(w, eq)
  Ty.okd_pack(ok, w)

def sh_bfs_go(+b: Ty.Brep, fuel: Nat,
    +todo: List<&2, Ty.HFace>, +seen: List<&2, Ty.HFace>,
    +all: List<&2, Ty.HFace>, +ffull: Nat) -> Nat:
  match fuel:
    case 0n:
      match todo:
        case Nil{}: sh_bfs_done(seen, all, ffull)
        case +h <> t: 0n
    case 1n+f:
      match todo:
        case Nil{}: sh_bfs_done(seen, all, ffull)
        case +h <> t:
          +seen2 = sh_seen_add(seen, h, ffull)
          +fr = sh_frontier(b, h, all, seen2, ffull)
          +todo2 = hfa_prepend_new(fr, t, seen2, ffull)
          sh_bfs_go(b, f, todo2, seen2, all, ffull)

def sh_conn_faces(+b: Ty.Brep, +faces: List<&2, Ty.HFace>,
    fuel: Nat, +ffull: Nat) -> Nat:
  match faces:
    case Nil{}: 3n
    case f0 <> _:
      sh_bfs_go(b, fuel, f0 <> Nil{}, Nil{}, faces, ffull)

def sh_conn_shell(+b: Ty.Brep, +sh: Ty.Shell, fuel: Nat,
    +ffull: Nat) -> Nat:
  sh_conn_faces(b, Ty.sh_faces(sh), fuel, ffull)

def shs_conn_go(shs: List<&2, Ty.Shell>, +b: Ty.Brep,
    fuel: Nat, +ffull: Nat) -> Nat:
  match shs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +code = sh_conn_shell(b, h, ffull, ffull)
          +rest = shs_conn_go(t, b, f, ffull)
          Ty.okd_all(code, rest)

def brep_conn_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  shs_conn_go(Ty.brep_shs(b), b, fuel, fuel)

# --- Stage J coincident distinct vertices (C04.2/A1): pairwise exact
# C02 pteq3 over the vertex store (nodup shape mirrors hv_nodup_c:
# outer walk decrements, inner scan takes the remaining cap, so fuel
# >= store length suffices). NaN coordinates never coincide (ordered
# == is reflexive-false); stage A already rejects nonfinite points.
# Both profiles. ---
def vx_coin_pt(+p: V.Point, +q: V.Point) -> Bool:
  PO.pteq3(V.pt_x(p), V.pt_y(p), V.pt_z(p), V.pt_x(q),
    V.pt_y(q), V.pt_z(q))

def vs_free_of_pt(xs: List<&2, Ty.Vertex>, +q: V.Point,
    fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = vs_free_of_pt(t, q, f)
          +neq = Bool.not(vx_coin_pt(Ty.vx_p(h), q))
          Ty.okd_pack(Bool.and(neq, Ty.okd_ok(rest)),
            Ty.okd_done(rest))

def vs_coin_c(xs: List<&2, Ty.Vertex>, fuel: Nat) -> Nat:
  match xs:
    case Nil{}: 3n
    case h <> +t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +ff = f
          +qp = Ty.vx_p(h)
          Ty.okd_all(vs_free_of_pt(t, qp, ff), vs_coin_c(t, ff))

def brep_coin_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  vs_coin_c(Ty.brep_vs(b), fuel)

# --- Stage K same-face straight-edge segment crossing (C04.2/A1):
# every pair of line-curve edges of one face (across all its loops)
# with no shared endpoint vertex must not properly cross. Crossing
# = orient3d-coplanar AND seg_seg-proper in at least one of the
# xy/xz/yz projections (a proper 3D crossing projects to a shared
# interior point in every projection; coplanar + proper in one
# projection lifts to a 3D interior intersection). Degenerate and
# curved edges skip (general curved intersection is C07). Predicate
# failure is fail-closed (counts as crossing). Both profiles. ---
def gval_is_ln(c: G.GVal) -> Bool:
  match c:
    case G.GV_ln{w}: True{}
    case _: False{}

def ed_straight(+e: Ty.Edge) -> Bool:
  +k = Ty.ed_kind(e)
  +c = Ty.ekind_curve(k)
  Bool.pick(Bool, Ty.ekind_is_curve(k), gval_is_ln(c), False{})

def hes_share_end(+a: Ty.Edge, +b: Ty.Edge) -> Bool:
  +a0 = Ty.ed_v0(a)
  +a1 = Ty.ed_v1(a)
  +b0 = Ty.ed_v0(b)
  +b1 = Ty.ed_v1(b)
  +m0 = Ty.hv_eq(a0, b0)
  +m1 = Ty.hv_eq(a0, b1)
  +m2 = Ty.hv_eq(a1, b0)
  +m3 = Ty.hv_eq(a1, b1)
  Bool.or(m0, Bool.or(m1, Bool.or(m2, m3)))

def xrel_is_proper(x: P.Xrel) -> Bool:
  match x:
    case P.X_proper{}: True{}
    case _: False{}

def segx_proper2(+a: V.Vec2, +b: V.Vec2, +c: V.Vec2,
    +d: V.Vec2) -> Bool:
  +r = PO.seg_seg(a, b, c, d)
  Bool.pick(Bool, P.xres_ok(r),
    xrel_is_proper(P.xres_rel(r)), True{})

def pt_xy(+p: V.Point) -> V.Vec2:
  V.V2{V.pt_x(p), V.pt_y(p)}

def pt_xz(+p: V.Point) -> V.Vec2:
  V.V2{V.pt_x(p), V.pt_z(p)}

def pt_yz(+p: V.Point) -> V.Vec2:
  V.V2{V.pt_y(p), V.pt_z(p)}

def segx_pair(+a: V.Point, +b: V.Point, +c: V.Point,
    +d: V.Point) -> Bool:
  +r3 = PO.orient3d(a, b, c, d)
  +cop = Bool.pick(Bool, P.pres_ok(r3),
    P.sign_is_zero(P.pres_sign(r3)), True{})
  +pxy = segx_proper2(pt_xy(a), pt_xy(b), pt_xy(c), pt_xy(d))
  +pxz = segx_proper2(pt_xz(a), pt_xz(b), pt_xz(c), pt_xz(d))
  +pyz = segx_proper2(pt_yz(a), pt_yz(b), pt_yz(c), pt_yz(d))
  +anyp = Bool.or(pxy, Bool.or(pxz, pyz))
  Bool.and(cop, anyp)

def hcs_x_one(+hc1: Ty.HCoedge, hcs2: List<&2, Ty.HCoedge>,
    +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, fuel: Nat, +ffull: Nat) -> Nat:
  match hcs2:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hcs_x_one(hc1, t, ces, es, vs, f, ffull)
          +ce1 = Ty.tres_ce(Ty.ce_resolve(ces, hc1, ffull))
          +ce2 = Ty.tres_ce(Ty.ce_resolve(ces, h, ffull))
          +e1 = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(ce1),
            ffull))
          +e2 = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(ce2),
            ffull))
          +st = Bool.and(ed_straight(e1), ed_straight(e2))
          +sh = hes_share_end(e1, e2)
          +p1 = Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs,
            Ty.ed_v0(e1), ffull)))
          +p2 = Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs,
            Ty.ed_v1(e1), ffull)))
          +p3 = Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs,
            Ty.ed_v0(e2), ffull)))
          +p4 = Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs,
            Ty.ed_v1(e2), ffull)))
          +x = segx_pair(p1, p2, p3, p4)
          +bad = Bool.and(st, Bool.and(Bool.not(sh), x))
          +ok = Bool.not(bad)
          Ty.okd_pack(Bool.and(ok, Ty.okd_ok(rest)),
            Ty.okd_done(rest))

def hcs_x_c(hcs1: List<&2, Ty.HCoedge>,
    +hcs2: List<&2, Ty.HCoedge>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, fuel: Nat,
    +ffull: Nat) -> Nat:
  match hcs1:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hcs_x_c(t, hcs2, ces, es, vs, f, ffull)
          +code = hcs_x_one(h, hcs2, ces, es, vs, ffull,
            ffull)
          Ty.okd_all(code, rest)

def hls_x_one(+hcs1: List<&2, Ty.HCoedge>,
    hls2: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>,
    +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, fuel: Nat, +ffull: Nat) -> Nat:
  match hls2:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hls_x_one(hcs1, t, lps, ces, es, vs, f,
            ffull)
          +lp2 = Ty.tres_lp(Ty.lp_resolve(lps, h, ffull))
          +code = hcs_x_c(hcs1, Ty.lp_ces(lp2), ces, es, vs,
            ffull, ffull)
          Ty.okd_all(code, rest)

def hls_x_c(hls1: List<&2, Ty.HLoop>,
    +hls2: List<&2, Ty.HLoop>, +lps: List<&2, Ty.Loop>,
    +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, fuel: Nat, +ffull: Nat) -> Nat:
  match hls1:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hls_x_c(t, hls2, lps, ces, es, vs, f,
            ffull)
          +lp1 = Ty.tres_lp(Ty.lp_resolve(lps, h, ffull))
          +code = hls_x_one(Ty.lp_ces(lp1), hls2, lps, ces,
            es, vs, ffull, ffull)
          Ty.okd_all(code, rest)

def fas_xing_c(fas: List<&2, Ty.Face>,
    +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, fuel: Nat,
    +ffull: Nat) -> Nat:
  match fas:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = fas_xing_c(t, lps, ces, es, vs, f, ffull)
          +ll = Ty.fa_loops(h)
          +code = hls_x_c(ll, ll, lps, ces, es, vs, ffull,
            ffull)
          Ty.okd_all(code, rest)

def brep_xing_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  fas_xing_c(Ty.brep_fas(b), Ty.brep_lps(b), Ty.brep_ces(b),
    Ty.brep_es(b), Ty.brep_vs(b), fuel, fuel)

# --- Stage L orientation, part 1: per-face self-consistency
# (C04.2/A1). Each loop's boundary winding (Newell sum over the
# oriented vertex chain) must agree with the same-adjusted surface
# normal: plane via plane_normal, bezp via cross(bezp_du, bezp_dv)
# at (0.5, 0.5), quadrics via *_grad at the first loop vertex.
# Skip-vs-fail policy: zero-area winding or an unavailable normal
# skips (passes) — the check fires only on a strictly negative
# (finite) dot, i.e. positive evidence of a winding/normal
# mismatch. Both profiles. ---
def newell_add(+n: V.Dir, +p: V.Point, +q: V.Point) -> V.Dir:
  +nx = F64.add(V.dr_x(n), F64.mul(F64.sub(V.pt_y(p),
    V.pt_y(q)), F64.add(V.pt_z(p), V.pt_z(q))))
  +ny = F64.add(V.dr_y(n), F64.mul(F64.sub(V.pt_z(p),
    V.pt_z(q)), F64.add(V.pt_x(p), V.pt_x(q))))
  +nz = F64.add(V.dr_z(n), F64.mul(F64.sub(V.pt_x(p),
    V.pt_x(q)), F64.add(V.pt_y(p), V.pt_y(q))))
  V.Dr{nx, ny, nz}

def dr_is_zero(+d: V.Dir) -> Bool:
  Bool.and(F64.is_eq(V.dr_x(d), 0.0f64),
    Bool.and(F64.is_eq(V.dr_y(d), 0.0f64),
      F64.is_eq(V.dr_z(d), 0.0f64)))

def dr_neg(+d: V.Dir) -> V.Dir:
  V.Dr{F64.neg(V.dr_x(d)), F64.neg(V.dr_y(d)),
    F64.neg(V.dr_z(d))}

def hcs_walked(xs: List<&2, Ty.HCoedge>, fuel: Nat) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t:
      match fuel:
        case 0n: False{}
        case 1n+f: hcs_walked(t, f)

def lp_newell_go(rest: List<&2, Ty.HCoedge>,
    +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, fuel: Nat, +ffull: Nat,
    +prev: V.Point, +first: V.Point, +n: V.Dir) -> V.Dir:
  match rest:
    case Nil{}: newell_add(n, prev, first)
    case h <> t:
      match fuel:
        case 0n: n
        case 1n+f:
          +ce = Ty.tres_ce(Ty.ce_resolve(ces, h, ffull))
          +ed = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(ce),
            ffull))
          +fw = Ty.ce_fwd(ce)
          +cs = o_v_start(ed, fw)
          +cur = Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs, cs,
            ffull)))
          lp_newell_go(t, ces, es, vs, f, ffull, cur, first,
            newell_add(n, prev, cur))

def lp_newell(hcs: List<&2, Ty.HCoedge>,
    +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, +ffull: Nat) -> V.Dir:
  match hcs:
    case Nil{}: V.Dr{0.0f64, 0.0f64, 0.0f64}
    case fh <> rest:
      +fce = Ty.tres_ce(Ty.ce_resolve(ces, fh, ffull))
      +fed = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(fce),
        ffull))
      +ffw = Ty.ce_fwd(fce)
      +p0 = Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs,
        o_v_start(fed, ffw), ffull)))
      lp_newell_go(rest, ces, es, vs, ffull, ffull, p0, p0,
        V.Dr{0.0f64, 0.0f64, 0.0f64})

def lp_first_pt(hcs: List<&2, Ty.HCoedge>,
    +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, +ffull: Nat) -> V.Point:
  match hcs:
    case Nil{}: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case fh <> _:
      +fce = Ty.tres_ce(Ty.ce_resolve(ces, fh, ffull))
      +fed = Ty.tres_ed(Ty.ed_resolve(es, Ty.ce_edge(fce),
        ffull))
      Ty.vx_p(Ty.tres_vx(Ty.vx_resolve(vs,
        o_v_start(fed, Ty.ce_fwd(fce)), ffull)))

def bezp_normal(+w: G.BezP) -> G.GRes:
  +du = GO.bezp_du(w, 0.5f64, 0.5f64)
  +dv = GO.bezp_dv(w, 0.5f64, 0.5f64)
  +ok = Bool.and(G.gres_ok(du), G.gres_ok(dv))
  +n = GO.dd_cross_raw(G.gres_d(du), G.gres_d(dv))
  GO.gate_d(n, Bool.and(ok, V.dr_fin(n)), T.F_uncertain{})

def surf_normal_at(+surf: G.GVal, +q: V.Point) -> G.GRes:
  match surf:
    case G.GV_pl{w}: GO.plane_normal(w)
    case G.GV_sp{w}: GO.sph_grad(w, q)
    case G.GV_cy{w}: GO.cyl_grad(w, q)
    case G.GV_co{w}: GO.cone_grad(w, q)
    case G.GV_to{w}: GO.tor_grad(w, q)
    case G.GV_bp{w}: bezp_normal(w)
    case _: G.gerr(T.F_unsupported{})

def loop_orient_c(+hcs: List<&2, Ty.HCoedge>,
    +ces: List<&2, Ty.Coedge>, +es: List<&2, Ty.Edge>,
    +vs: List<&2, Ty.Vertex>, +surf: G.GVal, +same: Bool,
    +ffull: Nat) -> Nat:
  +walked = hcs_walked(hcs, ffull)
  +n = lp_newell(hcs, ces, es, vs, ffull)
  +nz = dr_is_zero(n)
  +q0 = lp_first_pt(hcs, ces, es, vs, ffull)
  +nr = surf_normal_at(surf, q0)
  +nok = G.gres_ok(nr)
  +adj = Bool.pick(V.Dir, same, G.gres_d(nr),
    dr_neg(G.gres_d(nr)))
  +dot = GO.dd_dot_raw(n, adj)
  +fin = T.is_finite(dot)
  +pos = F64.is_lt(0.0f64, dot)
  +skip = Bool.or(nz, Bool.not(nok))
  +ok = Bool.or(skip, Bool.and(fin, pos))
  Ty.okd_pack(Bool.and(walked, ok), walked)

def hlp_orient_go(hls: List<&2, Ty.HLoop>,
    +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>,
    +surf: G.GVal, +same: Bool, fuel: Nat,
    +ffull: Nat) -> Nat:
  match hls:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = hlp_orient_go(t, lps, ces, es, vs, surf,
            same, f, ffull)
          +lp = Ty.tres_lp(Ty.lp_resolve(lps, h, ffull))
          +code = loop_orient_c(Ty.lp_ces(lp), ces, es, vs,
            surf, same, ffull)
          Ty.okd_all(code, rest)

def fas_orient_c(fas: List<&2, Ty.Face>,
    +lps: List<&2, Ty.Loop>, +ces: List<&2, Ty.Coedge>,
    +es: List<&2, Ty.Edge>, +vs: List<&2, Ty.Vertex>, fuel: Nat,
    +ffull: Nat) -> Nat:
  match fas:
    case Nil{}: 3n
    case +h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +rest = fas_orient_c(t, lps, ces, es, vs, f, ffull)
          +code = hlp_orient_go(Ty.fa_loops(h), lps, ces,
            es, vs, Ty.fa_surf(h), Ty.fa_same(h), ffull,
            ffull)
          Ty.okd_all(code, rest)

def brep_orient_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  fas_orient_c(Ty.brep_fas(b), Ty.brep_lps(b), Ty.brep_ces(b),
    Ty.brep_es(b), Ty.brep_vs(b), fuel, fuel)

# --- Stage L orientation, part 2: propagation (C04.2/A1). Every
# edge used exactly twice with opposite fwd whose two uses sit in
# distinct faces requires same-flag agreement across those faces
# (combinatorial; global outwardness needs the C07 interior
# classifier and stays out of scope). Seams (both uses in one
# face) and boundary (once-used) edges skip. Both profiles. ---
def hlp_mem(xs: List<&2, Ty.HLoop>, +hl: Ty.HLoop,
    +ffull: Nat) -> Bool:
  match xs:
    case Nil{}: False{}
    case h <> t:
      match ffull:
        case 0n: False{}
        case 1n+f:
          Bool.or(Ty.hlp_eq(h, hl), hlp_mem(t, hl, f))

def hc_owner_go(lps: List<&2, Ty.Loop>, +hc: Ty.HCoedge,
    +idx: Nat, +ffull: Nat) -> Ty.HLoop:
  match lps:
    case Nil{}: Ty.hlp_null()
    case +h <> t:
      match ffull:
        case 0n: Ty.hlp_null()
        case 1n+f:
          Bool.pick(Ty.HLoop, hc_mem(Ty.lp_ces(h), hc, ffull),
            Ty.mk_hlp(idx, Ty.lp_gen(h)),
            hc_owner_go(t, hc, Nat.add(idx, 1n), f))

def hl_owner_go(fas: List<&2, Ty.Face>, +hl: Ty.HLoop,
    +idx: Nat, +ffull: Nat) -> Ty.HFace:
  match fas:
    case Nil{}: Ty.hfa_null()
    case +h <> t:
      match ffull:
        case 0n: Ty.hfa_null()
        case 1n+f:
          Bool.pick(Ty.HFace, hlp_mem(Ty.fa_loops(h), hl,
            ffull), Ty.mk_hfa(idx, Ty.fa_gen(h)),
            hl_owner_go(t, hl, Nat.add(idx, 1n), f))

def lps_walked(xs: List<&2, Ty.Loop>, fuel: Nat) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t:
      match fuel:
        case 0n: False{}
        case 1n+f: lps_walked(t, f)

def fas_walked(xs: List<&2, Ty.Face>, fuel: Nat) -> Bool:
  match xs:
    case Nil{}: True{}
    case h <> t:
      match fuel:
        case 0n: False{}
        case 1n+f: fas_walked(t, f)

def ces_nth_user(ces: List<&2, Ty.Coedge>, +tgt: Ty.HEdge,
    +skip: Ty.HCoedge, +idx: Nat, +ffull: Nat) -> Ty.HCoedge:
  match ces:
    case Nil{}: Ty.hc_null()
    case +h <> t:
      match ffull:
        case 0n: Ty.hc_null()
        case 1n+f:
          +hh = Ty.mk_hc(idx, Ty.ce_gen(h))
          +hit = Bool.and(Ty.he_eq(Ty.ce_edge(h), tgt),
            Bool.not(Ty.hc_eq(hh, skip)))
          Bool.pick(Ty.HCoedge, hit, hh,
            ces_nth_user(t, tgt, skip, Nat.add(idx, 1n), f))

def edge_prop_c(+b: Ty.Brep, +he: Ty.HEdge,
    +ffull: Nat) -> Nat:
  +ces = Ty.brep_ces(b)
  +use = ces_use_go(ces, he, Ty.P_manifold_solid{}, ffull, 0n,
    False{}, False{})
  +twice = Bool.and(Ty.okd_done(use), Ty.okd_ok(use))
  +hcA = ces_nth_user(ces, he, Ty.hc_null(), 0n, ffull)
  +hcB = ces_nth_user(ces, he, hcA, 0n, ffull)
  +hlA = hc_owner_go(Ty.brep_lps(b), hcA, 0n, ffull)
  +hlB = hc_owner_go(Ty.brep_lps(b), hcB, 0n, ffull)
  +hfA = hl_owner_go(Ty.brep_fas(b), hlA, 0n, ffull)
  +hfB = hl_owner_go(Ty.brep_fas(b), hlB, 0n, ffull)
  +adq = Bool.and(lps_walked(Ty.brep_lps(b), ffull),
    fas_walked(Ty.brep_fas(b), ffull))
  +faA = Ty.tres_fa(Ty.fa_resolve(Ty.brep_fas(b), hfA, ffull))
  +faB = Ty.tres_fa(Ty.fa_resolve(Ty.brep_fas(b), hfB, ffull))
  +distinct = Bool.not(Ty.hfa_eq(hfA, hfB))
  +sA = Ty.fa_same(faA)
  +sB = Ty.fa_same(faB)
  +sameq = Bool.pick(Bool, sA, sB, Bool.not(sB))
  +agree = Bool.or(Bool.not(distinct), sameq)
  +ok = Bool.pick(Bool, twice, Bool.and(adq, agree), True{})
  +done = Bool.and(Ty.okd_done(use), adq)
  Ty.okd_pack(Bool.and(ok, done), done)

def es_prop_c(es: List<&2, Ty.Edge>, +b: Ty.Brep, fuel: Nat,
    +ffull: Nat, +idx: Nat) -> Nat:
  match es:
    case Nil{}: 3n
    case h <> t:
      match fuel:
        case 0n: 0n
        case 1n+f:
          +tgt = Ty.mk_he(idx, Ty.ed_gen(h))
          +code = edge_prop_c(b, tgt, ffull)
          +rest = es_prop_c(t, b, f, ffull, Nat.add(idx, 1n))
          Ty.okd_all(code, rest)

def brep_prop_c(+b: Ty.Brep, +fuel: Nat) -> Nat:
  es_prop_c(Ty.brep_es(b), b, fuel, fuel, 0n)

def brep_ck_l(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +c1 = brep_orient_c(b, fuel)
  +c2 = brep_prop_c(b, fuel)
  +cl = Ty.okd_all(c1, c2)
  +done_l = Ty.okd_done(cl)
  +ok_l = Ty.okd_ok(cl)
  +win = Ty.tok_brep(b)
  +ok_branch = Bool.pick(Ty.TRes, ok_l, win, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_l, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_k(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +ck = brep_xing_c(b, fuel)
  +done_k = Ty.okd_done(ck)
  +ok_k = Ty.okd_ok(ck)
  +rest = brep_ck_l(b, prof, fuel)
  +ok_branch = Bool.pick(Ty.TRes, ok_k, rest, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_k, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_j(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +cj = brep_coin_c(b, fuel)
  +done_j = Ty.okd_done(cj)
  +ok_j = Ty.okd_ok(cj)
  +rest = brep_ck_k(b, prof, fuel)
  +ok_branch = Bool.pick(Ty.TRes, ok_j, rest, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_j, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_i(+b: Ty.Brep, +prof: Ty.Profile,
    +fuel: Nat) -> Ty.TRes:
  +ci = brep_conn_c(b, fuel)
  +done_i = Ty.okd_done(ci)
  +ok_i = Ty.okd_ok(ci)
  +win = brep_ck_j(b, prof, fuel)
  +ok_branch = Bool.pick(Ty.TRes, ok_i, win, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_i, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_h(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +ch = brep_link_c(b, prof, fuel)
  +done_h = Ty.okd_done(ch)
  +ok_h = Ty.okd_ok(ch)
  +rest = brep_ck_i(b, prof, fuel)
  +ok_branch = Bool.pick(Ty.TRes, ok_h, rest, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_h, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_g(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +cg = brep_embed_c(b, fuel)
  +done_g = Ty.okd_done(cg)
  +ok_g = Ty.okd_ok(cg)
  +rest = brep_ck_h(b, prof, fuel)
  +ok_branch = Bool.pick(Ty.TRes, ok_g, rest, Ty.terr(T.F_invalid{}))
  Bool.pick(Ty.TRes, done_g, ok_branch, Ty.terr(T.F_exhausted{}))

def brep_ck_f(+b: Ty.Brep, +prof: Ty.Profile, +fuel: Nat) -> Ty.TRes:
  +cf = brep_prof_c(b, prof, fuel)
  +done_f = Ty.okd_done(cf)
  +ok_f = Ty.okd_ok(cf)
  +rest = brep_ck_g(b, prof, fuel)
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
