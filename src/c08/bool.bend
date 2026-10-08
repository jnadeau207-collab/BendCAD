# C08 — regularized B-rep booleans: union, difference, intersection.
#
# Pipeline (docs/c08-intent.md section 2): admit, broad-phase, intersect,
# split, classify, select+assemble, orient, validate, publish. This module
# implements every stage for operand pairs whose boundaries do not cross:
# disjoint, contained, contact-only and identical operands, plus the empty
# compound algebra. Pairs whose boundaries cross or overlap fail with the
# named diagnosis `boundaries-cross-or-overlap` (unsupported-op): fusing
# them needs face splitting and shell assembly, which this packet does not
# implement (see the closeout receipt for the exact outstanding scope).
#
# Packet decisions (docs/c08-intent.md D1/D2, section 6):
# - D1: NURBS operands are refused (`nurbs-operand`). C07 membership
#   answers uncertain on NURBS faces, so no boolean over them can certify
#   classification; extending membership is C11 freeform-trims work.
# - D2: flat bicubic walls are reduced to planes exactly, in `gv_im`
#   (src/c07/xs.bend): an exactly-planar control net yields the exact plane
#   with an expansion-arithmetic normal, so general prisms boolean.
# - Section 6: carried faces stay feature-addressable through their
#   original selectors; created cavity faces are not cells and answer
#   face-not-found; features on an empty compound are invalid-input.
#
# Contact and L2/L9: L9 requires contact-only compounds to publish, but
# C04 `brep_coin_c` rejects distinct coincident vertices. C08 therefore
# validates published results with the C04 stages minus `coin_c`, plus a
# contact-aware coincidence check (per-solid exact duplicates fail;
# inter-solid coincidences join the contact report), plus C07 `solid_fi`
# and the contact-aware `emb_fi` (cross-solid endpoint touch reports
# `contact-*` instead of failing). Any other finding fails validation.
# This L9 qualification of L2 needs owner review at closeout.
#
# Placement: operands are baked to the world frame at their midpoint
# placement before combination. Only certified-exact placements (`move`
# and quarter turns) are admitted (F4); general-angle rotations refuse as
# `interval-placement` rather than publishing midpoint geometry as
# certified. Operands are trusted by induction (each was validated at its
# own publication); rigidity preserves validity geometrically, and every
# assembled result is fully re-validated, so bake rounding can only fail
# loudly. Broad-phase boxes are recomputed from baked faces (F3).
#
# No partial publish: every stage returns an `Out`; failure carries the
# diagnosis and no geometry escapes (L3). Same inputs, same pin:
# bit-identical results on every lane (L14): sampling order is brep
# order, reductions are ordered folds, pmap only maps.

import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c04/ops.bend as B4
import ../base/par.bend as B
import ../base/ex.bend as E
import ../c06/iv.bend as I
import ../c06/prof.bend as F
import ../c06/build.bend as BD
import ../c07/sol.bend as SO
import ../c07/ivx.bend as X
import ../c07/emb.bend as EM
import ../c07/xs.bend as S
import ../c07/im.bend as MM
import ../c07/rb.bend as R

# Operator tags. C06 cache-key tags run 1..13; booleans take 14..16.

def tag_union() -> U64:
  14u64

def tag_diff() -> U64:
  15u64

def tag_inter() -> U64:
  16u64

def op_name(+op: U64) -> String:
  Bool.pick(String, U64.is_eq(op, tag_union()), "union",
    Bool.pick(String, U64.is_eq(op, tag_diff()), "difference", "intersection"))

def is_bool_op(+op: U64) -> Bool:
  Bool.or(U64.is_eq(op, tag_union()), Bool.or(U64.is_eq(op, tag_diff()), U64.is_eq(op, tag_inter())))

# Fragment classification codes (intent section 2.5).
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

# Regularized selection tables (Layer A). Returns 0 drop, 1 keep, 2 fail.
# Union keeps what is outside the other operand plus same-normal
# coincidence (shared outer wall); opposite-normal coincidence is interior
# and drops. Difference keeps what is outside plus opposite-normal
# coincidence ( untouched wall against the tool); same-normal coincidence
# borders removed material and drops. Intersection keeps what is inside
# plus same-normal coincidence; opposite-normal contact has no interior.
def keep_frag(+op: U64, +code: U64) -> U64:
  Bool.pick(U64, U64.is_eq(code, fc_unc()), 2u64,
    Bool.pick(U64, U64.is_eq(op, tag_union()),
      Bool.pick(U64, Bool.or(U64.is_eq(code, fc_out()), U64.is_eq(code, fc_same())), 1u64, 0u64),
      Bool.pick(U64, U64.is_eq(op, tag_diff()),
        Bool.pick(U64, Bool.or(U64.is_eq(code, fc_out()), U64.is_eq(code, fc_opp())), 1u64, 0u64),
        Bool.pick(U64, Bool.or(U64.is_eq(code, fc_in()), U64.is_eq(code, fc_same())), 1u64, 0u64))))

# Per-solid aggregate sample masks. Bit 0 strictly inside, bit 1 strictly
# outside, bit 2 on the boundary. Uncertain samples fail immediately (L4).
def agg_of(+has_in: Bool, +has_out: Bool, +has_on: Bool) -> U64:
  Bool.pick(U64, has_in, Bool.pick(U64, has_out, 3u64, 1u64), Bool.pick(U64, has_out, 2u64, 0u64))

def agg_in() -> U64:
  1u64

def agg_out() -> U64:
  2u64

# agg 0 (all boundary) fails as `contact-not-certified`; agg 3 (mixed
# strictly inside and outside) proves a crossing and fails as
# `boundaries-cross-or-overlap` (see `rel_why`).
def agg_ok(+a: U64) -> Bool:
  Bool.or(U64.is_eq(a, agg_in()), U64.is_eq(a, agg_out()))

# Pair decisions from per-operand aggregates (every solid of an operand
# agrees; mixed solids fail before this runs).
def dec_sep() -> U64:
  0u64

def dec_ainb() -> U64:
  1u64

def dec_bina() -> U64:
  2u64

def decide(+agga: U64, +aggb: U64) -> U64:
  Bool.pick(U64, Bool.and(U64.is_eq(agga, agg_out()), U64.is_eq(aggb, agg_out())), dec_sep(),
    Bool.pick(U64, Bool.and(U64.is_eq(agga, agg_in()), U64.is_eq(aggb, agg_out())), dec_ainb(),
      Bool.pick(U64, Bool.and(U64.is_eq(agga, agg_out()), U64.is_eq(aggb, agg_in())), dec_bina(), 3u64)))

# Outcomes: 0 carry A, 1 carry B, 2 append, 3 empty, 4 cavity, 5 fail.
# Every outcome flows through the `keep_frag` tie-break tables: whole
# operands are fragments that classify strictly inside or outside (the
# intersect stage proves no straddlers exist), and the tables decide
# keep/drop per operand. Assembly follows from the keeps.
def agg_code(+a: U64) -> U64:
  Bool.pick(U64, U64.is_eq(a, agg_in()), fc_in(), fc_out())

def dec_aggA(+dec: U64) -> U64:
  Bool.pick(U64, U64.is_eq(dec, dec_ainb()), agg_in(), agg_out())

def dec_aggB(+dec: U64) -> U64:
  Bool.pick(U64, U64.is_eq(dec, dec_bina()), agg_in(), agg_out())

def outcome_go(+op: U64, +dec: U64) -> U64:
  +ka = keep_frag(op, agg_code(dec_aggA(dec)))
  +kb = keep_frag(op, agg_code(dec_aggB(dec)))
  Bool.pick(U64, U64.is_eq(op, tag_union()),
    Bool.pick(U64, U64.is_eq(ka, 1u64), Bool.pick(U64, U64.is_eq(kb, 1u64), 2u64, 0u64),
      Bool.pick(U64, U64.is_eq(kb, 1u64), 1u64, 5u64)),
    Bool.pick(U64, U64.is_eq(op, tag_inter()),
      Bool.pick(U64, U64.is_eq(ka, 1u64), Bool.pick(U64, U64.is_eq(kb, 1u64), 5u64, 0u64),
        Bool.pick(U64, U64.is_eq(kb, 1u64), 1u64, 3u64)),
      Bool.pick(U64, U64.is_eq(ka, 1u64), Bool.pick(U64, U64.is_eq(kb, 1u64), 0u64, 4u64), 3u64)))

def outcome(+op: U64, +dec: U64) -> U64:
  Bool.pick(U64, U64.is_eq(dec, 3u64), 5u64, outcome_go(op, dec))

# Failure-kind tags for `Out.kind`: 0 invalid, 1 uncertain, 2 unsupported.
def fk_invalid() -> U64:
  0u64

def fk_uncertain() -> U64:
  1u64

def fk_unsupported() -> U64:
  2u64

# Finding-code partition for C07 check output. Contact codes are
# information (L9); everything else fails. Fail-closed: unknown codes fail.
def is_contact(+c: String) -> Bool:
  Bool.or(String.eq(c, "contact-edge-edge"), Bool.or(String.eq(c, "contact-edge-face"),
    String.eq(c, "contact-face-face")))

def is_uncertain_code(+c: String) -> Bool:
  Bool.or(String.eq(c, "edge-crossing-uncertain"), Bool.or(String.eq(c, "edge-face-uncertain"),
    Bool.or(String.eq(c, "face-face-uncertain"), Bool.or(String.eq(c, "face-overlap-uncertain"),
      Bool.or(String.eq(c, "orientation-uncertain"), String.eq(c, "nesting-uncertain"))))))

def is_unsupported_code(+c: String) -> Bool:
  Bool.or(String.eq(c, "edge-check-unsupported"),
    Bool.or(String.eq(c, "face-check-unsupported"), String.eq(c, "edge-face-unsupported")))

# Known definite-failure codes (F9): transverse crossings, overlaps,
# nesting failures. An unrecognized code fails closed toward uncertainty
# with the raw code preserved — never mislabeled as crossing/overlap.
def is_transverse_code(+c: String) -> Bool:
  Bool.or(String.eq(c, "edge-crossing"),
    Bool.or(String.eq(c, "edge-overlap"),
      Bool.or(String.eq(c, "edge-face-penetration"),
        Bool.or(String.eq(c, "edge-face-overlap"),
          Bool.or(String.eq(c, "face-penetration"),
            Bool.or(String.eq(c, "face-overlap"),
              Bool.or(String.eq(c, "inverted-shell"),
                Bool.or(String.eq(c, "cavities-nested"), String.eq(c, "cavity-outside")))))))))

# Shared by model.bend: C04 stage names and fuel (single source).
def stage_why(+c: U64) -> String:
  match c:
    case 2u64: "incidence"
    case 3u64: "edge-use"
    case 4u64: "loop-closure-or-trim"
    case 5u64: "face-kind"
    case 6u64: "ownership"
    case 7u64: "embedding"
    case 8u64: "vertex-link"
    case 9u64: "shell-connectivity"
    case 10u64: "coincident-vertices"
    case 11u64: "segment-crossing"
    case 12u64: "orientation"
    case _: "stage-unknown"

def fuel_of(+b: Ty.Brep) -> Nat:
  Nat.add(Nat.mul(4n, Nat.add(List.length(&2, Ty.Coedge, Ty.brep_ces(b)), List.length(&2, Ty.Vertex, Ty.brep_vs(b)))), 64n)

def okc(+c: Nat, +s: U64) -> U64:
  Bool.pick(U64, Ty.okd_ok(c), 0u64, s)

def pk0(+a: U64, +b: U64) -> U64:
  Bool.pick(U64, U64.is_eq(a, 0u64), b, a)

# C04 stages except coincident-vertices (10), which C08 replaces with the
# contact-aware coincidence check. Returns 0 when all pass, else the
# first failing stage number.
def stage10_of(+b: Ty.Brep, +fuel: Nat) -> U64:
  pk0(okc(B4.brep_incid_c(b, fuel), 2u64), pk0(okc(B4.brep_use_c(b, Ty.P_manifold_solid{}, fuel), 3u64),
    pk0(okc(B4.brep_loop_c(b, fuel), 4u64), pk0(okc(B4.brep_facekind_c(b, fuel), 5u64),
      pk0(okc(B4.brep_prof_c(b, Ty.P_manifold_solid{}, fuel), 6u64), pk0(okc(B4.brep_embed_c(b, fuel), 7u64),
        pk0(okc(B4.brep_link_c(b, Ty.P_manifold_solid{}, fuel), 8u64), pk0(okc(B4.brep_conn_c(b, fuel), 9u64),
          pk0(okc(B4.brep_xing_c(b, fuel), 11u64), okc(B4.brep_orient_c(b, fuel), 12u64))))))))))

type BX is Data:
  BX{ x0: F64, x1: F64, y0: F64, y1: F64, z0: F64, z1: F64 }

def bx_disjoint(a: BX, b: BX) -> Bool:
  BX{+ax0, +ax1, +ay0, +ay1, +az0, +az1} = a
  BX{+bx0, +bx1, +by0, +by1, +bz0, +bz1} = b
  Bool.or(F64.is_lt(ax1, bx0), Bool.or(F64.is_lt(bx1, ax0), Bool.or(F64.is_lt(ay1, by0),
    Bool.or(F64.is_lt(by1, ay0), Bool.or(F64.is_lt(az1, bz0), F64.is_lt(bz1, az0))))))

def bx_hull(a: BX, b: BX) -> BX:
  BX{+ax0, +ax1, +ay0, +ay1, +az0, +az1} = a
  BX{+bx0, +bx1, +by0, +by1, +bz0, +bz1} = b
  BX{F64.min(ax0, bx0), F64.max(ax1, bx1), F64.min(ay0, by0), F64.max(ay1, by1), F64.min(az0, bz0),
    F64.max(az1, bz1)}

def bx_zero() -> BX:
  BX{0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def bx_show(b: BX) -> String:
  BX{x0, x1, y0, y1, z0, z1} = b
  "[" ++ F64.show(x0) ++ ", " ++ F64.show(x1) ++ "]x[" ++ F64.show(y0) ++ ", " ++ F64.show(y1) ++
    "]x[" ++ F64.show(z0) ++ ", " ++ F64.show(z1) ++ "]"

def bx_diag(b: BX) -> F64:
  BX{x0, x1, y0, y1, z0, z1} = b
  F64.add(F64.sub(x1, x0), F64.add(F64.sub(y1, y0), F64.sub(z1, z0)))

def bx_mag(+b: BX) -> F64:
  BX{x0, x1, y0, y1, z0, z1} = b
  F64.max(F64.max(F64.abs(x0), F64.abs(x1)),
    F64.max(F64.max(F64.abs(y0), F64.abs(y1)), F64.max(F64.abs(z0), F64.abs(z1))))

# Bake error bound: input linearity plus bake rounding (each baked
# coordinate is 3 muls + 3 adds; 4 eps of magnitude covers it).
def bake_eps(+bb: BX, +lin: F64) -> F64:
  F64.add(lin, F64.mul(F64.add(bx_mag(bb), 1.0f64), 8.881784197001252e-16f64))

def bx_widen(+b: BX, +e: F64) -> BX:
  BX{+x0, +x1, +y0, +y1, +z0, +z1} = b
  BX{I.dn(F64.sub(x0, e)), I.up(F64.add(x1, e)), I.dn(F64.sub(y0, e)), I.up(F64.add(y1, e)),
    I.dn(F64.sub(z0, e)), I.up(F64.add(z1, e))}

def iv_nth(xs: List<&2, I.I>, +i: Nat) -> I.I:
  match xs:
    case []: I.ipt(0.0f64)
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: iv_nth(t, j)

def iv_bx(+xs: List<&2, I.I>) -> BX:
  +x = iv_nth(xs, 0n)
  +y = iv_nth(xs, 1n)
  +z = iv_nth(xs, 2n)
  BX{I.i_lo(x), I.i_hi(x), I.i_lo(y), I.i_hi(y), I.i_lo(z), I.i_hi(z)}

def bx_hull_iv(+acc: BX, +xs: List<&2, I.I>) -> BX:
  bx_hull(acc, iv_bx(xs))

# Certified world box from baked faces (F3): hull of the C07 face boxes
# over the baked brep. Face boxes conservatively contain their faces
# (planes: boundary hull; curved: surface-aware boxes), so this never
# under-approximates — unlike the stored advisory `In.bb`, which a later
# move/rotate leaves in the pre-move frame.
def wbox_fds(fs: List<&2, SO.Fd>, +acc: BX) -> BX:
  match fs:
    case []: acc
    case +f <> t: wbox_fds(t, bx_hull_iv(acc, SO.fd_bx(f)))

def wbox_of_go(fs: List<&2, SO.Fd>) -> BX:
  match fs:
    case []: bx_zero()
    case +f <> t: wbox_fds(t, iv_bx(SO.fd_bx(f)))

def wbox_of(+b: Ty.Brep) -> BX:
  wbox_of_go(SO.fds_of(b))

def world_box_go(+w0: BX, +lin: F64) -> BX:
  bx_widen(w0, bake_eps(w0, lin))

def world_box(+b: Ty.Brep, +lin: F64) -> BX:
  world_box_go(wbox_of(b), lin)

# Operand input: everything `run` needs, without importing the design
# model (model.bend imports this module, so it must stay model-free).
# `bb` is advisory (display, handoff); no disjoint decision trusts it
# (F3: the broad-phase recomputes world boxes from baked faces). `px`
# says the midpoint placement is certified exact (F4).
type In is Data:
  In{ brep: Ty.Brep, cells: List<&2, BD.Cl>, fns: List<&2, BD.Fn>, m: V.Mat3, tx: F64, ty: F64,
    tz: F64, rv: List<&2, F.Lp>, vol: I.I, area: I.I, bb: BX, lin: F64, bo: Bool, px: Bool }

# Pipeline result. On failure only ok/kind/what/loc/why/fix are
# meaningful. carry selects republishing an input unchanged (1 A, 2 B);
# otherwise the assembled geometry holds. mat/fc/fm/sh/ho is the measured
# effect; hasm says measures are stored (append, cavity, empty). `proof`
# carries the disjoint-proof operand boxes for broad-phase short-circuits
# (F15), else "".
type Del is Data:
  Del{ f: BD.Fn, why: U64 }

type Out is Data:
  Out{ ok: Bool, kind: U64, what: String, loc: String, why: String, fix: String, carry: U64,
    brep: Ty.Brep, cells: List<&2, BD.Cl>, fns: List<&2, BD.Fn>, rv: List<&2, F.Lp>, nc: Nat,
    vol: I.I, area: I.I, bb: BX, lin: F64, hasm: Bool, mat: U64, fc: Nat, fm: Nat, sh: Nat,
    ho: Nat, nct: Nat, proof: String, del: List<&2, Del> }

def out_fail(+kind: U64, +what: String, +loc: String, +why: String, +fix: String) -> Out:
  Out{False{}, kind, what, loc, why, fix, 0u64, Ty.brep_empty(), [], [], [], 0n, I.ipt(0.0f64),
    I.ipt(0.0f64), bx_zero(), 0.0f64, False{}, 4u64, 0n, 0n, 0n, 0n, 0n, "", []}

# Lineage. Carried faces keep their input Fn words verbatim. Created
# cavity faces take role 4: Fn{boolean node, target solid, 4, source face
# index in the tool brep, tool operand (0 A, 1 B)}. Deleted input entities
# are recorded per result with reasons (F12, `Del`), not derived by the
# reader. No positional matching (L11).
def role_created() -> U64:
  4u64

def fn_created(+nd: U64, +k: Nat, +src: Nat, +tool: U64) -> BD.Fn:
  BD.Fn{nd, k, role_created(), src, U64.to_nat(tool)}

def fn_nd(f: BD.Fn) -> U64:
  BD.Fn{nd, k, role, i, j} = f
  nd

def fn_k(f: BD.Fn) -> Nat:
  BD.Fn{nd, k, role, i, j} = f
  k

def fn_role(f: BD.Fn) -> U64:
  BD.Fn{nd, k, role, i, j} = f
  role

def fn_i(f: BD.Fn) -> Nat:
  BD.Fn{nd, k, role, i, j} = f
  i

def fn_j(f: BD.Fn) -> Nat:
  BD.Fn{nd, k, role, i, j} = f
  j

def fn_created_n(fns: List<&2, BD.Fn>) -> Nat:
  match fns:
    case []: 0n
    case f <> t: Nat.add(Bool.pick(Nat, U64.is_eq(fn_role(f), role_created()), 1n, 0n), fn_created_n(t))

def fn_show(+f: BD.Fn) -> String:
  BD.Fn{+nd, +k, +role, +i, +j} = f
  Bool.pick(String, U64.is_eq(role, 0u64), "n" ++ U64.show(nd) ++ ".c" ++ Nat.show(k) ++ ".top",
    Bool.pick(String, U64.is_eq(role, 1u64), "n" ++ U64.show(nd) ++ ".c" ++ Nat.show(k) ++ ".bottom",
      Bool.pick(String, U64.is_eq(role, 2u64),
        "n" ++ U64.show(nd) ++ ".c" ++ Nat.show(k) ++ ".wall." ++ Nat.show(i) ++ "." ++ Nat.show(j),
        Bool.pick(String, U64.is_eq(role, 3u64),
          "n" ++ U64.show(nd) ++ ".c" ++ Nat.show(k) ++ ".wall." ++ Nat.show(i) ++ "." ++ Nat.show(j),
          "n" ++ U64.show(nd) ++ ".cav." ++ Nat.show(k) ++ "." ++ Nat.show(i) ++ "." ++ Nat.show(j)))))

# Deleted lineage (F12/L11): consumed input entities with reasons.
# 0 classified-away, 1 regularized-away, 2 merged. In non-crossing scope
# every deletion is classified-away (carries consume the other operand's
# faces; empties consume both); appends and cavity transplants delete
# nothing. The field is the contract: empty lists are asserted too.

def del_classified(fs: List<&2, BD.Fn>) -> List<&2, Del>:
  match fs:
    case []: []
    case +f <> t: Del{f, 0u64} <> del_classified(t)

def del_why_s(+w: U64) -> String:
  Bool.pick(String, U64.is_eq(w, 0u64), "classified-away",
    Bool.pick(String, U64.is_eq(w, 1u64), "regularized-away", "merged"))

def del_show(d: Del) -> String:
  Del{f, w} = d
  fn_show(f) ++ " " ++ del_why_s(w)

def dels_show(ds: List<&2, Del>) -> String:
  match ds:
    case []: ""
    case d <> t: del_show(d) ++ "\n" ++ dels_show(t)

# Durable lineage selector resolution (L12): exact five-word patterns
# resolve to one entity or miss; three-word prefixes resolve to the
# explicitly intended set or miss. Full patterns that match twice are
# ambiguous (unreachable while lineage prefixes stay unique per operand,
# pinned by law; the arm exists for future split fragments). Pure function
# of stored lineage: no geometric search, no nearest match.
type Rs is Data:
  R_one{ i: Nat }
  R_set{ js: List<&2, Nat> }
  R_miss{ cands: Nat }
  R_amb{ js: List<&2, Nat> }

def fn_full_eq(+f: BD.Fn, +nd: U64, +k: Nat, +role: U64, +i: Nat, +j: Nat) -> Bool:
  Bool.and(U64.is_eq(fn_nd(f), nd), Bool.and(Nat.is_eq(fn_k(f), k), Bool.and(U64.is_eq(fn_role(f), role),
    Bool.and(Nat.is_eq(fn_i(f), i), Nat.is_eq(fn_j(f), j)))))

def fn_pre_eq(+f: BD.Fn, +nd: U64, +k: Nat, +role: U64) -> Bool:
  Bool.and(U64.is_eq(fn_nd(f), nd), Bool.and(Nat.is_eq(fn_k(f), k), U64.is_eq(fn_role(f), role)))

def res_full(fns: List<&2, BD.Fn>, +nd: U64, +k: Nat, +role: U64, +i: Nat, +j: Nat, +at: Nat,
    +found: Nat, +n: Nat, +tot: Nat, +acc: List<&2, Nat>) -> Rs:
  match fns:
    case []:
      Bool.pick(Rs, Nat.is_eq(n, 0n), R_miss{tot},
        Bool.pick(Rs, Nat.is_eq(n, 1n), R_one{found}, R_amb{List.reverse(&2, Nat, acc)}))
    case f <> +t:
      Bool.pick(Rs, fn_full_eq(f, nd, k, role, i, j),
        res_full(t, nd, k, role, i, j, Nat.add(at, 1n), at, Nat.add(n, 1n), tot, at <> acc),
        res_full(t, nd, k, role, i, j, Nat.add(at, 1n), found, n, tot, acc))

def res_pre_go(fns: List<&2, BD.Fn>, +nd: U64, +k: Nat, +role: U64, +at: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match fns:
    case []: List.reverse(&2, Nat, acc)
    case f <> t:
      res_pre_go(t, nd, k, role, Nat.add(at, 1n),
        Bool.pick(List<&2, Nat>, fn_pre_eq(f, nd, k, role), at <> acc, acc))

def resolve(+fns: List<&2, BD.Fn>, +nd: U64, +k: Nat, +role: U64, +i: Nat, +j: Nat, +full: Bool) -> Rs:
  match full:
    case True{}: res_full(fns, nd, k, role, i, j, 0n, 0n, 0n, List.length(&2, BD.Fn, fns), [])
    case False{}:
      +m = res_pre_go(fns, nd, k, role, 0n, [])
      Bool.pick(Rs, Nat.is_eq(List.length(&2, Nat, m), 0n), R_miss{List.length(&2, BD.Fn, fns)}, R_set{m})

# Total list indexing with defaults.
def nth_vx(xs: List<&2, Ty.Vertex>, +i: Nat) -> Ty.Vertex:
  match xs:
    case []: Ty.Vx{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_vx(t, j)

def nth_ed(xs: List<&2, Ty.Edge>, +i: Nat) -> Ty.Edge:
  match xs:
    case []: Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{0n, 0u64}, Ty.EK_degenerate{}}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_ed(t, j)

def nth_ce(xs: List<&2, Ty.Coedge>, +i: Nat) -> Ty.Coedge:
  match xs:
    case []: Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, Ty.trim_zero()}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_ce(t, j)

def nth_lp(xs: List<&2, Ty.Loop>, +i: Nat) -> Ty.Loop:
  match xs:
    case []: Ty.Lp{0u64, [], Ty.LK_outer{}}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_lp(t, j)

def nth_fa(xs: List<&2, Ty.Face>, +i: Nat) -> Ty.Face:
  match xs:
    case []: Ty.Fa{0u64, G.GV_f{0.0f64}, [], True{}}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_fa(t, j)

def nth_sh(xs: List<&2, Ty.Shell>, +i: Nat) -> Ty.Shell:
  match xs:
    case []: Ty.Sh{0u64, [], Ty.SK_open{}}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_sh(t, j)

def nth_so(xs: List<&2, Ty.Solid>, +i: Nat) -> Ty.Solid:
  match xs:
    case []: Ty.So{0u64, Ty.HS{0n, 0u64}, []}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_so(t, j)

def nth_fn(xs: List<&2, BD.Fn>, +i: Nat) -> BD.Fn:
  match xs:
    case []: BD.Fn{0u64, 0n, 0u64, 0n, 0n}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_fn(t, j)

def res_names(+fns: List<&2, BD.Fn>, js: List<&2, Nat>) -> String:
  match js:
    case []: ""
    case i <> t: " " ++ fn_show(nth_fn(fns, i)) ++ res_names(fns, t)

def res_show(r: Rs, +fns: List<&2, BD.Fn>) -> String:
  match r:
    case R_one{+i}: "one " ++ fn_show(nth_fn(fns, i))
    case R_set{+js}: "set " ++ Nat.show(List.length(&2, Nat, js)) ++ res_names(fns, js)
    case R_miss{+cands}: "missing (no face matches; " ++ Nat.show(cands) ++ " faces stored)"
    case R_amb{+js}: "ambiguous (" ++ Nat.show(List.length(&2, Nat, js)) ++ " faces match)" ++ res_names(fns, js)

def nth_nat(xs: List<&2, Nat>, +i: Nat) -> Nat:
  match xs:
    case []: 0n
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: nth_nat(t, j)

def br_counts(+b: Ty.Brep) -> List<&2, Nat>:
  [List.length(&2, Ty.Vertex, Ty.brep_vs(b)), List.length(&2, Ty.Edge, Ty.brep_es(b)),
    List.length(&2, Ty.Face, Ty.brep_fas(b)), List.length(&2, Ty.Loop, Ty.brep_lps(b)),
    List.length(&2, Ty.Shell, Ty.brep_shs(b)), List.length(&2, Ty.Solid, Ty.brep_sos(b))]

def genus_of(+b: Ty.Brep) -> Nat:
  +c = br_counts(b)
  +v = nth_nat(c, 0n)
  +e = nth_nat(c, 1n)
  +f = nth_nat(c, 2n)
  +l = nth_nat(c, 3n)
  +s = nth_nat(c, 4n)
  +r = Nat.sub(l, f)
  Nat.div(Nat.sub(Nat.add(Nat.add(Nat.mul(2n, s), e), r), Nat.add(v, f)), 2n)

def nsolids(+b: Ty.Brep) -> Nat:
  List.length(&2, Ty.Solid, Ty.brep_sos(b))

# Placement baking: rigid motion to the world frame at the midpoint
# placement (exact for exact placements). Points translate; directions
# rotate. Trims are surface-parameter values and do not move.
def xf_pt(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64, +p: V.Point) -> V.Point:
  V.M3{+a0, +a1, +a2, +a3, +a4, +a5, +a6, +a7, +a8} = m
  V.Pt{+x, +y, +z} = p
  V.Pt{F64.add(F64.add(F64.add(F64.mul(a0, x), F64.mul(a1, y)), F64.mul(a2, z)), tx),
    F64.add(F64.add(F64.add(F64.mul(a3, x), F64.mul(a4, y)), F64.mul(a5, z)), ty),
    F64.add(F64.add(F64.add(F64.mul(a6, x), F64.mul(a7, y)), F64.mul(a8, z)), tz)}

def xf_dr(+m: V.Mat3, +d: V.Dir) -> V.Dir:
  V.M3{+a0, +a1, +a2, +a3, +a4, +a5, +a6, +a7, +a8} = m
  V.Dr{+x, +y, +z} = d
  V.Dr{F64.add(F64.add(F64.mul(a0, x), F64.mul(a1, y)), F64.mul(a2, z)),
    F64.add(F64.add(F64.mul(a3, x), F64.mul(a4, y)), F64.mul(a5, z)),
    F64.add(F64.add(F64.mul(a6, x), F64.mul(a7, y)), F64.mul(a8, z))}

def xf_pts(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64, ps: List<&2, V.Point>) -> List<&2, V.Point>:
  match ps:
    case []: []
    case p <> t: xf_pt(m, tx, ty, tz, p) <> xf_pts(m, tx, ty, tz, t)

def bb_lo(ps: List<&2, V.Point>, +lo: V.Point) -> V.Point:
  match ps:
    case []: lo
    case +p <> t:
      bb_lo(t, V.Pt{F64.min(V.pt_x(lo), V.pt_x(p)), F64.min(V.pt_y(lo), V.pt_y(p)),
        F64.min(V.pt_z(lo), V.pt_z(p))})

def bb_hi(ps: List<&2, V.Point>, +hi: V.Point) -> V.Point:
  match ps:
    case []: hi
    case +p <> t:
      bb_hi(t, V.Pt{F64.max(V.pt_x(hi), V.pt_x(p)), F64.max(V.pt_y(hi), V.pt_y(p)),
        F64.max(V.pt_z(hi), V.pt_z(p))})

def bb_of_pts(ps: List<&2, V.Point>) -> G.GVal:
  match ps:
    case []: G.GV_bb{G.Bb{V.Pt{0.0f64, 0.0f64, 0.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}}}
    case +p <> +t: G.GV_bb{G.Bb{bb_lo(t, p), bb_hi(t, p)}}

def xf_gval(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64, +g: G.GVal) -> G.GVal:
  match g:
    case G.GV_ln{G.Ln{p, d}}:
      G.GV_ln{G.Ln{xf_pt(m, tx, ty, tz, p), xf_dr(m, d)}}
    case G.GV_pl{G.Pl{o, u, v}}:
      G.GV_pl{G.Pl{xf_pt(m, tx, ty, tz, o), xf_dr(m, u), xf_dr(m, v)}}
    case G.GV_cc{G.Cc{c, u, v, r}}:
      G.GV_cc{G.Cc{xf_pt(m, tx, ty, tz, c), xf_dr(m, u), xf_dr(m, v), r}}
    case G.GV_bz{G.Bz{p0, p1, p2, p3}}:
      G.GV_bz{G.Bz{xf_pt(m, tx, ty, tz, p0), xf_pt(m, tx, ty, tz, p1), xf_pt(m, tx, ty, tz, p2),
        xf_pt(m, tx, ty, tz, p3)}}
    case G.GV_rq{G.Rq{p0, p1, p2, w0, w1, w2}}:
      G.GV_rq{G.Rq{xf_pt(m, tx, ty, tz, p0), xf_pt(m, tx, ty, tz, p1), xf_pt(m, tx, ty, tz, p2), w0,
        w1, w2}}
    case G.GV_bp{G.Bp{p00, p01, p02, p03, p10, p11, p12, p13, p20, p21, p22, p23, p30, p31, p32, p33}}:
      G.GV_bp{G.Bp{xf_pt(m, tx, ty, tz, p00), xf_pt(m, tx, ty, tz, p01), xf_pt(m, tx, ty, tz, p02),
        xf_pt(m, tx, ty, tz, p03), xf_pt(m, tx, ty, tz, p10), xf_pt(m, tx, ty, tz, p11),
        xf_pt(m, tx, ty, tz, p12), xf_pt(m, tx, ty, tz, p13), xf_pt(m, tx, ty, tz, p20),
        xf_pt(m, tx, ty, tz, p21), xf_pt(m, tx, ty, tz, p22), xf_pt(m, tx, ty, tz, p23),
        xf_pt(m, tx, ty, tz, p30), xf_pt(m, tx, ty, tz, p31), xf_pt(m, tx, ty, tz, p32),
        xf_pt(m, tx, ty, tz, p33)}}
    case G.GV_sp{G.Sp{c, r}}:
      G.GV_sp{G.Sp{xf_pt(m, tx, ty, tz, c), r}}
    case G.GV_cy{G.Cy{o, a, r}}:
      G.GV_cy{G.Cy{xf_pt(m, tx, ty, tz, o), xf_dr(m, a), r}}
    case G.GV_co{G.Co{o, a, k}}:
      G.GV_co{G.Co{xf_pt(m, tx, ty, tz, o), xf_dr(m, a), k}}
    case G.GV_to{G.To{o, a, bigr, r}}:
      G.GV_to{G.To{xf_pt(m, tx, ty, tz, o), xf_dr(m, a), bigr, r}}
    case G.GV_bb{G.Bb{+lo, +hi}}:
      +x0 = V.pt_x(lo)
      +y0 = V.pt_y(lo)
      +z0 = V.pt_z(lo)
      +x1 = V.pt_x(hi)
      +y1 = V.pt_y(hi)
      +z1 = V.pt_z(hi)
      bb_of_pts(xf_pts(m, tx, ty, tz, [V.Pt{x0, y0, z0}, V.Pt{x0, y0, z1}, V.Pt{x0, y1, z0},
        V.Pt{x0, y1, z1}, V.Pt{x1, y0, z0}, V.Pt{x1, y0, z1}, V.Pt{x1, y1, z0}, V.Pt{x1, y1, z1}]))
    case G.GV_nb{G.Nb{ks, ps, ws}}:
      G.GV_nb{G.Nb{ks, xf_pts(m, tx, ty, tz, ps), ws}}
    case _: g

def xf_ek(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64, +k: Ty.EdgeKind) -> Ty.EdgeKind:
  match k:
    case Ty.EK_curve{c, d}: Ty.EK_curve{xf_gval(m, tx, ty, tz, c), d}
    case Ty.EK_degenerate{}: Ty.EK_degenerate{}

def xf_vs(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64, xs: List<&2, Ty.Vertex>) -> List<&2, Ty.Vertex>:
  match xs:
    case []: []
    case Ty.Vx{g, p} <> t:
      Ty.Vx{g, xf_pt(m, tx, ty, tz, p)} <> xf_vs(m, tx, ty, tz, t)

def xf_es(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64, xs: List<&2, Ty.Edge>) -> List<&2, Ty.Edge>:
  match xs:
    case []: []
    case Ty.Ed{g, v0, v1, k} <> t:
      Ty.Ed{g, v0, v1, xf_ek(m, tx, ty, tz, k)} <> xf_es(m, tx, ty, tz, t)

def xf_fas(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64, xs: List<&2, Ty.Face>) -> List<&2, Ty.Face>:
  match xs:
    case []: []
    case Ty.Fa{g, s, ls, same} <> t:
      Ty.Fa{g, xf_gval(m, tx, ty, tz, s), ls, same} <> xf_fas(m, tx, ty, tz, t)

def xf_brep(+m: V.Mat3, +tx: F64, +ty: F64, +tz: F64, +b: Ty.Brep) -> Ty.Brep:
  Ty.Br{xf_vs(m, tx, ty, tz, Ty.brep_vs(b)), xf_es(m, tx, ty, tz, Ty.brep_es(b)), Ty.brep_ces(b),
    Ty.brep_lps(b), xf_fas(m, tx, ty, tz, Ty.brep_fas(b)), Ty.brep_shs(b), Ty.brep_sos(b),
    Ty.brep_top(b), Ty.brep_stamp(b)}

# Brep append: shift every handle index of `b` by the sizes of `a`, then
# restamp all generations to idx+1 (the builder convention). O(n).
def sh_hv(+s: Nat, +h: Ty.HVertex) -> Ty.HVertex:
  Ty.HV{i, g} = h
  Ty.HV{Nat.add(i, s), g}

def sh_he(+s: Nat, +h: Ty.HEdge) -> Ty.HEdge:
  Ty.HE{i, g} = h
  Ty.HE{Nat.add(i, s), g}

def sh_hc(+s: Nat, +h: Ty.HCoedge) -> Ty.HCoedge:
  Ty.HC{i, g} = h
  Ty.HC{Nat.add(i, s), g}

def sh_hl(+s: Nat, +h: Ty.HLoop) -> Ty.HLoop:
  Ty.HL{i, g} = h
  Ty.HL{Nat.add(i, s), g}

def sh_hf(+s: Nat, +h: Ty.HFace) -> Ty.HFace:
  Ty.HF{i, g} = h
  Ty.HF{Nat.add(i, s), g}

def sh_hs(+s: Nat, +h: Ty.HShell) -> Ty.HShell:
  Ty.HS{i, g} = h
  Ty.HS{Nat.add(i, s), g}

def sh_hso(+s: Nat, +h: Ty.HSolid) -> Ty.HSolid:
  Ty.HSo{i, g} = h
  Ty.HSo{Nat.add(i, s), g}

def sh_hcs(+s: Nat, xs: List<&2, Ty.HCoedge>) -> List<&2, Ty.HCoedge>:
  match xs:
    case []: []
    case h <> t: sh_hc(s, h) <> sh_hcs(s, t)

def sh_hls(+s: Nat, xs: List<&2, Ty.HLoop>) -> List<&2, Ty.HLoop>:
  match xs:
    case []: []
    case h <> t: sh_hl(s, h) <> sh_hls(s, t)

def sh_hfs(+s: Nat, xs: List<&2, Ty.HFace>) -> List<&2, Ty.HFace>:
  match xs:
    case []: []
    case h <> t: sh_hf(s, h) <> sh_hfs(s, t)

def sh_hss(+s: Nat, xs: List<&2, Ty.HShell>) -> List<&2, Ty.HShell>:
  match xs:
    case []: []
    case h <> t: sh_hs(s, h) <> sh_hss(s, t)

def sh_hsos(+s: Nat, xs: List<&2, Ty.HSolid>) -> List<&2, Ty.HSolid>:
  match xs:
    case []: []
    case h <> t: sh_hso(s, h) <> sh_hsos(s, t)

def sh_es(+s: Nat, xs: List<&2, Ty.Edge>) -> List<&2, Ty.Edge>:
  match xs:
    case []: []
    case Ty.Ed{g, v0, v1, k} <> t:
      Ty.Ed{g, sh_hv(s, v0), sh_hv(s, v1), k} <> sh_es(s, t)

def sh_ces(+s: Nat, xs: List<&2, Ty.Coedge>) -> List<&2, Ty.Coedge>:
  match xs:
    case []: []
    case Ty.Ce{g, e, fwd, tr} <> t:
      Ty.Ce{g, sh_he(s, e), fwd, tr} <> sh_ces(s, t)

def sh_lps(+s: Nat, xs: List<&2, Ty.Loop>) -> List<&2, Ty.Loop>:
  match xs:
    case []: []
    case Ty.Lp{g, hs, k} <> t:
      Ty.Lp{g, sh_hcs(s, hs), k} <> sh_lps(s, t)

def sh_fas(+s: Nat, xs: List<&2, Ty.Face>) -> List<&2, Ty.Face>:
  match xs:
    case []: []
    case Ty.Fa{g, su, ls, same} <> t:
      Ty.Fa{g, su, sh_hls(s, ls), same} <> sh_fas(s, t)

def sh_shs(+s: Nat, xs: List<&2, Ty.Shell>) -> List<&2, Ty.Shell>:
  match xs:
    case []: []
    case Ty.Sh{g, fs, k} <> t:
      Ty.Sh{g, sh_hfs(s, fs), k} <> sh_shs(s, t)

def sh_sos(+s: Nat, xs: List<&2, Ty.Solid>) -> List<&2, Ty.Solid>:
  match xs:
    case []: []
    case Ty.So{g, ou, cs} <> t:
      Ty.So{g, sh_hs(s, ou), sh_hss(s, cs)} <> sh_sos(s, t)

def gen_at(+i: Nat) -> U64:
  U64.from_nat(Nat.add(i, 1n))

def rs_vs(xs: List<&2, Ty.Vertex>, +i: Nat) -> List<&2, Ty.Vertex>:
  match xs:
    case []: []
    case Ty.Vx{g, p} <> t:
      Ty.Vx{gen_at(i), p} <> rs_vs(t, Nat.add(i, 1n))

def rs_hv(+h: Ty.HVertex) -> Ty.HVertex:
  Ty.HV{+i, g} = h
  Ty.HV{i, gen_at(i)}

def rs_he(+h: Ty.HEdge) -> Ty.HEdge:
  Ty.HE{+i, g} = h
  Ty.HE{i, gen_at(i)}

def rs_hc(+h: Ty.HCoedge) -> Ty.HCoedge:
  Ty.HC{+i, g} = h
  Ty.HC{i, gen_at(i)}

def rs_hl(+h: Ty.HLoop) -> Ty.HLoop:
  Ty.HL{+i, g} = h
  Ty.HL{i, gen_at(i)}

def rs_hf(+h: Ty.HFace) -> Ty.HFace:
  Ty.HF{+i, g} = h
  Ty.HF{i, gen_at(i)}

def rs_hs(+h: Ty.HShell) -> Ty.HShell:
  Ty.HS{+i, g} = h
  Ty.HS{i, gen_at(i)}

def rs_hso(+h: Ty.HSolid) -> Ty.HSolid:
  Ty.HSo{+i, g} = h
  Ty.HSo{i, gen_at(i)}

def rs_hcs(xs: List<&2, Ty.HCoedge>) -> List<&2, Ty.HCoedge>:
  match xs:
    case []: []
    case h <> t: rs_hc(h) <> rs_hcs(t)

def rs_hls(xs: List<&2, Ty.HLoop>) -> List<&2, Ty.HLoop>:
  match xs:
    case []: []
    case h <> t: rs_hl(h) <> rs_hls(t)

def rs_hfs(xs: List<&2, Ty.HFace>) -> List<&2, Ty.HFace>:
  match xs:
    case []: []
    case h <> t: rs_hf(h) <> rs_hfs(t)

def rs_hss(xs: List<&2, Ty.HShell>) -> List<&2, Ty.HShell>:
  match xs:
    case []: []
    case h <> t: rs_hs(h) <> rs_hss(t)

def rs_hsos(xs: List<&2, Ty.HSolid>) -> List<&2, Ty.HSolid>:
  match xs:
    case []: []
    case h <> t: rs_hso(h) <> rs_hsos(t)

def rs_es(xs: List<&2, Ty.Edge>, +i: Nat) -> List<&2, Ty.Edge>:
  match xs:
    case []: []
    case Ty.Ed{g, v0, v1, k} <> t:
      Ty.Ed{gen_at(i), rs_hv(v0), rs_hv(v1), k} <> rs_es(t, Nat.add(i, 1n))

def rs_ces(xs: List<&2, Ty.Coedge>, +i: Nat) -> List<&2, Ty.Coedge>:
  match xs:
    case []: []
    case Ty.Ce{g, e, fwd, tr} <> t:
      Ty.Ce{gen_at(i), rs_he(e), fwd, tr} <> rs_ces(t, Nat.add(i, 1n))

def rs_lps(xs: List<&2, Ty.Loop>, +i: Nat) -> List<&2, Ty.Loop>:
  match xs:
    case []: []
    case Ty.Lp{g, hs, k} <> t:
      Ty.Lp{gen_at(i), rs_hcs(hs), k} <> rs_lps(t, Nat.add(i, 1n))

def rs_fas(xs: List<&2, Ty.Face>, +i: Nat) -> List<&2, Ty.Face>:
  match xs:
    case []: []
    case Ty.Fa{g, su, ls, same} <> t:
      Ty.Fa{gen_at(i), su, rs_hls(ls), same} <> rs_fas(t, Nat.add(i, 1n))

def rs_shs(xs: List<&2, Ty.Shell>, +i: Nat) -> List<&2, Ty.Shell>:
  match xs:
    case []: []
    case Ty.Sh{g, fs, k} <> t:
      Ty.Sh{gen_at(i), rs_hfs(fs), k} <> rs_shs(t, Nat.add(i, 1n))

def rs_sos(xs: List<&2, Ty.Solid>, +i: Nat) -> List<&2, Ty.Solid>:
  match xs:
    case []: []
    case Ty.So{g, ou, cs} <> t:
      Ty.So{gen_at(i), rs_hs(ou), rs_hss(cs)} <> rs_sos(t, Nat.add(i, 1n))

def stamp_of(+b: Ty.Brep) -> U64:
  U64.from_nat(Nat.add(List.length(&2, Ty.Vertex, Ty.brep_vs(b)), Nat.add(List.length(&2, Ty.Edge,
    Ty.brep_es(b)), Nat.add(List.length(&2, Ty.Coedge, Ty.brep_ces(b)), Nat.add(List.length(&2, Ty.Loop,
    Ty.brep_lps(b)), Nat.add(List.length(&2, Ty.Face, Ty.brep_fas(b)),
    List.length(&2, Ty.Shell, Ty.brep_shs(b))))))))

def restamp_top(+b: Ty.Brep, t: Ty.Compound) -> Ty.Brep:
  Ty.Cp{sos, shs} = t
  Ty.Br{rs_vs(Ty.brep_vs(b), 0n), rs_es(Ty.brep_es(b), 0n), rs_ces(Ty.brep_ces(b), 0n),
    rs_lps(Ty.brep_lps(b), 0n), rs_fas(Ty.brep_fas(b), 0n), rs_shs(Ty.brep_shs(b), 0n),
    rs_sos(Ty.brep_sos(b), 0n), Ty.Cp{rs_hsos(sos), rs_hss(shs)},
    U64.add(stamp_of(b), 1u64)}

def restamp(+b: Ty.Brep) -> Ty.Brep:
  restamp_top(b, Ty.brep_top(b))

def brep_append_go(+a: Ty.Brep, +b: Ty.Brep, ta: Ty.Compound, tb: Ty.Compound) -> Ty.Brep:
  Ty.Cp{+asos, +ashs} = ta
  Ty.Cp{+bsos, +bshs} = tb
  +nv = List.length(&2, Ty.Vertex, Ty.brep_vs(a))
  +ne = List.length(&2, Ty.Edge, Ty.brep_es(a))
  +nc = List.length(&2, Ty.Coedge, Ty.brep_ces(a))
  +nl = List.length(&2, Ty.Loop, Ty.brep_lps(a))
  +nf = List.length(&2, Ty.Face, Ty.brep_fas(a))
  +nh = List.length(&2, Ty.Shell, Ty.brep_shs(a))
  +nso = List.length(&2, Ty.Solid, Ty.brep_sos(a))
  restamp(Ty.Br{List.append(&2, Ty.Vertex, Ty.brep_vs(a), Ty.brep_vs(b)),
    List.append(&2, Ty.Edge, Ty.brep_es(a), sh_es(nv, Ty.brep_es(b))),
    List.append(&2, Ty.Coedge, Ty.brep_ces(a), sh_ces(ne, Ty.brep_ces(b))),
    List.append(&2, Ty.Loop, Ty.brep_lps(a), sh_lps(nc, Ty.brep_lps(b))),
    List.append(&2, Ty.Face, Ty.brep_fas(a), sh_fas(nl, Ty.brep_fas(b))),
    List.append(&2, Ty.Shell, Ty.brep_shs(a), sh_shs(nf, Ty.brep_shs(b))),
    List.append(&2, Ty.Solid, Ty.brep_sos(a), sh_sos(nh, Ty.brep_sos(b))),
    Ty.Cp{List.append(&2, Ty.HSolid, asos, sh_hsos(nso, bsos)),
      List.append(&2, Ty.HShell, ashs, sh_hss(nh, bshs))}, 0u64})

def brep_append(+a: Ty.Brep, +b: Ty.Brep) -> Ty.Brep:
  brep_append_go(a, b, Ty.brep_top(a), Ty.brep_top(b))

# Vertex-to-solid map via coedge -> loop -> face -> shell -> solid walk.
# Built from faces: for each solid, its shells' faces give loops, coedges,
# edges, vertices. Returns an association list (vertex idx, solid idx).
type VS is Data:
  VS{ v: Nat, s: Nat }

def vs_of_ces(+b: Ty.Brep, hs: List<&2, Ty.HCoedge>, +so: Nat, +acc: List<&2, VS>) -> List<&2, VS>:
  match hs:
    case []: acc
    case Ty.HC{+ci, g} <> t:
      +e = nth_ed(Ty.brep_es(b), Ty.he_idx(Ty.ce_edge(nth_ce(Ty.brep_ces(b), ci))))
      vs_of_ces(b, t, so, VS{Ty.hv_idx(Ty.ed_v0(e)), so} <> VS{Ty.hv_idx(Ty.ed_v1(e)), so} <> acc)

def vs_of_lps(+b: Ty.Brep, hs: List<&2, Ty.HLoop>, +so: Nat, +acc: List<&2, VS>) -> List<&2, VS>:
  match hs:
    case []: acc
    case Ty.HL{+li, g} <> t:
      vs_of_lps(b, t, so, vs_of_ces(b, Ty.lp_ces(nth_lp(Ty.brep_lps(b), li)), so, acc))

def vs_of_hs(+b: Ty.Brep, hs: List<&2, Ty.HFace>, +sh: Nat, +mp: List<&2, Nat>, +acc: List<&2, VS>) -> List<&2, VS>:
  match hs:
    case []: acc
    case Ty.HF{+fi, g} <> t:
      vs_of_hs(b, t, sh, mp, vs_of_lps(b, Ty.fa_loops(nth_fa(Ty.brep_fas(b), fi)), nth_nat(mp, sh), acc))

def vs_of_shs(+b: Ty.Brep, +shs: List<&2, Ty.Shell>, +mp: List<&2, Nat>, +at: Nat,
    +acc: List<&2, VS>) -> List<&2, VS>:
  match shs:
    case []: acc
    case Ty.Sh{g, fs, k} <> t:
      vs_of_shs(b, t, mp, Nat.add(at, 1n), vs_of_hs(b, fs, at, mp, acc))

def vsmap_of(+b: Ty.Brep) -> List<&2, VS>:
  vs_of_shs(b, Ty.brep_shs(b), Ty.shmap_of(b), 0n, [])

def vs_find(xs: List<&2, VS>, +v: Nat, +dflt: Nat) -> Nat:
  match xs:
    case []: dflt
    case VS{+w, +s} <> t:
      Bool.pick(Nat, Nat.is_eq(w, v), s, vs_find(t, v, dflt))

# Contact-aware coincidence: exact duplicate vertices within one solid
# fail; coincidences across solids join the contact report. Returns the
# first intra-solid duplicate index pair, or counts only. Simpler sound
# rule used here: sort (point, solid) pairs; adjacent equal points with
# equal solids fail; adjacent equal points with differing solids count as
# contact. Points carry their vertex index for the report.
type PV is Data:
  PV{ p: V.Point, s: Nat, v: Nat }

def pv_of(+b: Ty.Brep, +vs: List<&2, Ty.Vertex>, +mp: List<&2, VS>, +at: Nat, +nso: Nat) -> List<&2, PV>:
  match vs:
    case []: []
    case Ty.Vx{g, p} <> t:
      PV{p, vs_find(mp, at, nso), at} <> pv_of(b, t, mp, Nat.add(at, 1n), nso)

def pt_lt(+p: V.Point, +q: V.Point) -> Bool:
  Bool.pick(Bool, F64.is_lt(V.pt_x(p), V.pt_x(q)), True{},
    Bool.pick(Bool, F64.is_lt(V.pt_x(q), V.pt_x(p)), False{},
      Bool.pick(Bool, F64.is_lt(V.pt_y(p), V.pt_y(q)), True{},
        Bool.pick(Bool, F64.is_lt(V.pt_y(q), V.pt_y(p)), False{},
          Bool.pick(Bool, F64.is_lt(V.pt_z(p), V.pt_z(q)), True{},
            Bool.pick(Bool, F64.is_lt(V.pt_z(q), V.pt_z(p)), False{}, False{}))))))

def pt_eq3(+p: V.Point, +q: V.Point) -> Bool:
  Bool.and(F64.is_eq(V.pt_x(p), V.pt_x(q)), Bool.and(F64.is_eq(V.pt_y(p), V.pt_y(q)),
    F64.is_eq(V.pt_z(p), V.pt_z(q))))

def pv_lt(a: PV, b: PV) -> B.Sgn:
  PV{+pa, +sa, +va} = a
  PV{+pb, +sb, +vb} = b
  Bool.pick(B.Sgn, pt_lt(pa, pb), B.Sn{},
    Bool.pick(B.Sgn, pt_lt(pb, pa), B.Sp{},
      Bool.pick(B.Sgn, Nat.is_eq(sa, sb), B.sgn_pick(Nat.is_lt(va, vb), Nat.is_lt(vb, va)),
        B.sgn_pick(Nat.is_lt(sa, sb), Nat.is_lt(sb, sa)))))

def pv_so(s: B.So<&2, PV>) -> List<&2, PV>:
  B.So{ok, xs} = s
  xs

# Returns (intra_ok, contacts, dup_a, dup_b): whether no intra-solid
# duplicates exist, how many inter-solid contact coincidences, and the
# first intra duplicate pair for the report.
type CR is Data:
  CR{ ok: Bool, nc: Nat, a: Nat, b: Nat }

def surf_admit_nb(+s: G.GVal) -> U64:
  match s:
    case G.GV_nb{w}: 2u64
    case G.GV_bp{w}: 1u64
    case _: 3u64

def surf_admit_go(m: Maybe<&2, MM.Im>, +s: G.GVal) -> U64:
  match m:
    case Some{im}: 0u64
    case None{}: surf_admit_nb(s)

# Admit scans (L5: the admitted domain is exactly what C07 can both
# intersect and classify). A face is admitted when `gv_im` yields its
# implicit form: planes, cylinders, cones, spheres, tori, and exactly-flat
# bicubic patches (reduced to planes by `gv_im`, decision D2). Anything
# else refuses: NURBS faces as `nurbs-operand` (D1), curved patches as
# `bezier-patch-operand`, other arms as `face-kind-not-supported`.
# Edge curves must be lines, cubics, circles or rational quadratics.
def surf_admit(+s: G.GVal) -> U64:
  surf_admit_go(S.gv_im(s), s)

def surf_why(+c: U64) -> String:
  match c:
    case 1u64: "bezier-patch-operand"
    case 2u64: "nurbs-operand"
    case _: "face-kind-not-supported"

def admit_fas(fs: List<&2, Ty.Face>, +at: Nat) -> U64:
  match fs:
    case []: 0u64
    case Ty.Fa{g, s, ls, same} <> t:
      +c = surf_admit(s)
      Bool.pick(U64, U64.is_eq(c, 0u64), admit_fas(t, Nat.add(at, 1n)), c)

def admit_fas_at(fs: List<&2, Ty.Face>, +at: Nat) -> Nat:
  match fs:
    case []: 0n
    case Ty.Fa{g, s, ls, same} <> t:
      Bool.pick(Nat, U64.is_eq(surf_admit(s), 0u64), admit_fas_at(t, Nat.add(at, 1n)), at)

def edge_code(+k: Ty.EdgeKind) -> U64:
  match k:
    case Ty.EK_degenerate{}: 0u64
    case Ty.EK_curve{G.GV_ln{w}, d}: 0u64
    case Ty.EK_curve{G.GV_bz{w}, d}: 0u64
    case Ty.EK_curve{G.GV_cc{w}, d}: 0u64
    case Ty.EK_curve{G.GV_rq{w}, d}: 0u64
    case _: 1u64

def admit_eds(es: List<&2, Ty.Edge>) -> U64:
  match es:
    case []: 0u64
    case Ty.Ed{g, v0, v1, k} <> t:
      Bool.pick(U64, U64.is_eq(edge_code(k), 0u64), admit_eds(t), 1u64)

def admit_eds_at(es: List<&2, Ty.Edge>, +at: Nat) -> Nat:
  match es:
    case []: 0n
    case Ty.Ed{g, v0, v1, k} <> t:
      Bool.pick(Nat, U64.is_eq(edge_code(k), 0u64), admit_eds_at(t, Nat.add(at, 1n)), at)

def shell_open(+k: Ty.ShellKind) -> Bool:
  match k:
    case Ty.SK_open{}: True{}
    case _: False{}

def admit_shs(ss: List<&2, Ty.Shell>) -> Bool:
  match ss:
    case []: False{}
    case Ty.Sh{g, fs, k} <> t:
      Bool.or(shell_open(k), admit_shs(t))

# Sampling: the first vertex of every face of a solid's outer shell, in
# brep order. With no boundary crossings (certified by the intersect
# stage), one strict sample decides the solid; boundary samples escalate
# to the next; all-boundary fails as `contact-not-certified`.
def ce_v0(+b: Ty.Brep, +h: Ty.HCoedge) -> V.Point:
  Ty.HC{+ci, g} = h
  +e = nth_ed(Ty.brep_es(b), Ty.he_idx(Ty.ce_edge(nth_ce(Ty.brep_ces(b), ci))))
  Ty.vx_p(nth_vx(Ty.brep_vs(b), Ty.hv_idx(Ty.ed_v0(e))))

# Face sampling is total (F24): loopless faces contribute no sample
# instead of a phantom origin point. Unreachable after the intersect
# stage's C04 check (every face has exactly one outer loop), but total
# by construction rather than by convention.
def lp_v0(+b: Ty.Brep, hs: List<&2, Ty.HCoedge>) -> Maybe<&2, V.Point>:
  match hs:
    case []: None{}
    case h <> t: Some{ce_v0(b, h)}

def fa_v0(+b: Ty.Brep, hs: List<&2, Ty.HLoop>) -> Maybe<&2, V.Point>:
  match hs:
    case []: None{}
    case Ty.HL{+li, g} <> t:
      lp_v0(b, Ty.lp_ces(nth_lp(Ty.brep_lps(b), li)))

def face_pts_go(+mp: Maybe<&2, V.Point>, +rest: List<&2, V.Point>) -> List<&2, V.Point>:
  match mp:
    case None{}: rest
    case Some{p}: p <> rest

# Edge-midpoint samples (seam-vertex soundness): loop-first-vertex
# sampling strands solids whose every sampled vertex lies in a small
# patch. A cylinder's two rim-seam vertices both sit on one generator,
# so a tangent cylinder sampled boundary-only (spurious
# `contact-not-certified`) and a 1e-6-overlapped cylinder sampled
# inside-only (a silent wrong carry). Every admitted edge curve also
# contributes its parametric midpoint (`gv_cv` covers exactly the
# admitted edge domain, so this is total on admitted operands);
# seam/antipodal pairs cannot both hide in a sub-feature-scale lens.
# Boundary samples only ever add strict evidence, never change a
# decided verdict (same argument as the F18 interior samples).
def mid_pt(+q: List<&2, I.I>) -> V.Point:
  V.Pt{X.imid(X.vn(q, 0n)), X.imid(X.vn(q, 1n)), X.imid(X.vn(q, 2n))}

def cv_mid(+m: Maybe<&2, R.Cv>) -> Maybe<&2, V.Point>:
  match m:
    case None{}: None{}
    case Some{+c}: Some{mid_pt(R.cv_box(c, I.ipt(0.5f64)))}

def ed_mid(+k: Ty.EdgeKind) -> Maybe<&2, V.Point>:
  match k:
    case Ty.EK_curve{+g, +d}: cv_mid(S.gv_cv(g, d))
    case _: None{}

def ce_mid(+b: Ty.Brep, +h: Ty.HCoedge) -> Maybe<&2, V.Point>:
  Ty.HC{+ci, g} = h
  +e = nth_ed(Ty.brep_es(b), Ty.he_idx(Ty.ce_edge(nth_ce(Ty.brep_ces(b), ci))))
  ed_mid(Ty.ed_kind(e))

def mid_cons(+mp: Maybe<&2, V.Point>, +rest: List<&2, V.Point>) -> List<&2, V.Point>:
  match mp:
    case None{}: rest
    case Some{p}: p <> rest

def lp_mids(+b: Ty.Brep, hs: List<&2, Ty.HCoedge>) -> List<&2, V.Point>:
  match hs:
    case []: []
    case h <> t: mid_cons(ce_mid(b, h), lp_mids(b, t))

def fa_mids(+b: Ty.Brep, hs: List<&2, Ty.HLoop>) -> List<&2, V.Point>:
  match hs:
    case []: []
    case Ty.HL{+li, g} <> t:
      List.append(&2, V.Point, lp_mids(b, Ty.lp_ces(nth_lp(Ty.brep_lps(b), li))), fa_mids(b, t))

def face_pts(+b: Ty.Brep, hs: List<&2, Ty.HFace>) -> List<&2, V.Point>:
  match hs:
    case []: []
    case Ty.HF{+fi, g} <> t:
      +lps = Ty.fa_loops(nth_fa(Ty.brep_fas(b), fi))
      face_pts_go(fa_v0(b, lps), List.append(&2, V.Point, fa_mids(b, lps), face_pts(b, t)))

def solid_pts(+b: Ty.Brep, +o: Ty.HShell) -> List<&2, V.Point>:
  face_pts(b, Ty.sh_faces(nth_sh(Ty.brep_shs(b), Ty.hsh_idx(o))))

def ag_mask(+m: U64, +c: U64) -> U64:
  Bool.pick(U64, U64.is_eq(c, 1u64), U64.or(m, 1u64),
    Bool.pick(U64, U64.is_eq(c, 0u64), U64.or(m, 2u64), U64.or(m, 4u64)))

def ag_set(ms: List<&2, U64>, +s: Nat, +c: U64, +at: Nat) -> List<&2, U64>:
  match ms:
    case []: []
    case +m <> t:
      Bool.pick(U64, Nat.is_eq(at, s), ag_mask(m, c), m) <> ag_set(t, s, c, Nat.add(at, 1n))

type SM is Data:
  SM{ p: V.Point, s: Nat }

def sm_tag(ps: List<&2, V.Point>, +s: Nat) -> List<&2, SM>:
  match ps:
    case []: []
    case p <> t: SM{p, s} <> sm_tag(t, s)

def sm_of(+b: Ty.Brep, ss: List<&2, Ty.Solid>, +at: Nat) -> List<&2, SM>:
  match ss:
    case []: []
    case Ty.So{g, ou, cs} <> t:
      List.append(&2, SM, sm_tag(solid_pts(b, ou), at), sm_of(b, t, Nat.add(at, 1n)))

def sm_has(ps: List<&2, SM>, +p: V.Point, +s: Nat) -> Bool:
  match ps:
    case []: False{}
    case SM{+q, +r} <> t:
      Bool.or(Bool.and(Nat.is_eq(r, s), pt_eq3(p, q)), sm_has(t, p, s))

def ag_masks(+n: Nat) -> List<&2, U64>:
  match n:
    case 0n: []
    case 1n+m: 0u64 <> ag_masks(m)

# Parallel classification over all samples (L16); the fold stays ordered.
type Cj is Data:
  Cj{ fds: List<&2, SO.Fd>, bb: List<&2, I.I> }

def cj_class(c: Cj, x: SM) -> U64:
  Cj{fds, bb} = c
  SM{p, s} = x
  SO.classify_in(fds, bb, p)

def cj_run(+fds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +xs: List<&2, SM>) -> List<&2, U64>:
  B.pmap_g(~SM, ~Cj, ~U64, ~cj_class, 2, Cj{fds, bb}, xs)

# Aggregate fold per solid over ordered (sample, class) pairs. Class 2
# (uncertain) fails the whole operation (L4); class 3 (boundary) keeps
# looking; mixed strict inside/outside is inconsistent.
type AG is Data:
  AG{ ok: Bool, unc: Bool, bad: Nat, masks: List<&2, U64> }

def ag_agg(+m: U64) -> U64:
  Bool.pick(U64, U64.is_eq(U64.and(m, 3u64), 3u64), 3u64,
    Bool.pick(U64, U64.is_eq(U64.and(m, 1u64), 1u64), agg_in(),
      Bool.pick(U64, U64.is_eq(U64.and(m, 2u64), 2u64), agg_out(), 0u64)))

# Which solid of `m` contains the point: the first whose face subset
# classifies it strictly inside. Face subsets come from the shell map.
def fd_in_shs(+sh: Nat, hs: List<&2, Nat>) -> Bool:
  match hs:
    case []: False{}
    case h <> t: Bool.or(Nat.is_eq(h, sh), fd_in_shs(sh, t))

def fds_sub(fs: List<&2, SO.Fd>, +hs: List<&2, Nat>) -> List<&2, SO.Fd>:
  match fs:
    case []: []
    case +f <> t:
      +rest = fds_sub(t, hs)
      Bool.pick(List<&2, SO.Fd>, fd_in_shs(SO.fd_sh(f), hs), f <> rest, rest)

def sh_ids_go(cs: List<&2, Ty.HShell>) -> List<&2, Nat>:
  match cs:
    case []: []
    case h <> t: Ty.hsh_idx(h) <> sh_ids_go(t)

def sh_ids(o: Ty.HShell, cs: List<&2, Ty.HShell>) -> List<&2, Nat>:
  Ty.hsh_idx(o) <> sh_ids_go(cs)

# Face-interior samples (F18 tangent contact): vertex-only sampling
# strands solids whose every sampled vertex lies on the other
# operand's boundary (a sphere kissing a plane samples its seam
# vertex at the tangent point). Each face also contributes its
# trim-certified interior point (`SO.interior`); with no crossings
# (intersect stage) one strict sample still decides the solid, so the
# extra samples only add strict evidence, never change a decided
# verdict. Faces without a certified interior point contribute none.
def sm_mid_pt(+m: Maybe<&2, List<&2, I.I>>, +at: Nat) -> List<&2, SM>:
  match m:
    case None{}: []
    case Some{+q}: [SM{V.Pt{X.imid(X.vn(q, 0n)), X.imid(X.vn(q, 1n)), X.imid(X.vn(q, 2n))}, at}]

def sm_int_fd(fs: List<&2, SO.Fd>, +at: Nat) -> List<&2, SM>:
  match fs:
    case []: []
    case +f <> t: List.append(&2, SM, sm_mid_pt(SO.interior(f), at), sm_int_fd(t, at))

def sm_int_of(+own: List<&2, SO.Fd>, ss: List<&2, Ty.Solid>, +at: Nat) -> List<&2, SM>:
  match ss:
    case []: []
    case Ty.So{g, ou, cs} <> t:
      List.append(&2, SM, sm_int_fd(fds_sub(own, sh_ids(ou, cs)), at),
        sm_int_of(own, t, Nat.add(at, 1n)))

def container_go(ss: List<&2, Ty.Solid>, +fs: List<&2, SO.Fd>, +p: V.Point, +at: Nat, +nso: Nat) -> Nat:
  match ss:
    case []: nso
    case Ty.So{g, ou, cs} <> t:
      +sub = fds_sub(fs, sh_ids(ou, cs))
      Bool.pick(Nat, U64.is_eq(SO.classify_in(sub, SO.bbox(sub, []), p), 1u64), at,
        container_go(t, fs, p, Nat.add(at, 1n), nso))

def container_of(+m: Ty.Brep, +fs: List<&2, SO.Fd>, +p: V.Point) -> Nat:
  container_go(Ty.brep_sos(m), fs, p, 0n, nsolids(m))

def CR_ok(c: CR) -> Bool:
  CR{ok, nc, a, b} = c
  ok

def CR_nc(c: CR) -> Nat:
  CR{ok, nc, a, b} = c
  nc

def CR_a(c: CR) -> Nat:
  CR{ok, nc, a, b} = c
  a

def CR_b(c: CR) -> Nat:
  CR{ok, nc, a, b} = c
  b

# Per-solid relations from aggregate masks: 1 strictly inside, 2 strictly
# outside, anything else fails (3 mixed, 0 touching-only or unsampled).
def rel_list(ms: List<&2, U64>) -> List<&2, U64>:
  match ms:
    case []: []
    case m <> t: ag_agg(m) <> rel_list(t)

# Validation core shared by the intersect stage (over the appended brep)
# and the validate stage (over the assembled result): C04 minus coin,
# contact-aware coin, C07 orientation/nesting, contact-aware embedding.
type VR is Data:
  VR{ ok: Bool, stage: U64, nc: Nat, code: String, a: Nat, b: Nat }

def vr_fail(+stage: U64, +code: String, +a: Nat, +b: Nat) -> VR:
  VR{False{}, stage, 0n, code, a, b}

def fi_partition(fs: List<&2, SO.Fi>, +acc: VR) -> VR:
  match fs:
    case []: acc
    case SO.Fi{+c, +a, +b} <> t:
      VR{+ok, +st, +nc, +co, +ca, +cb} = acc
      fi_partition(t, Bool.pick(VR, is_contact(c), VR{ok, st, Nat.add(nc, 1n), co, ca, cb},
        Bool.pick(VR, ok, VR{False{}, st, nc, c, a, b}, acc)))

def vr_stage(+f10: U64, +cr: CR, +b: Ty.Brep, +fds: List<&2, SO.Fd>) -> VR:
  Bool.pick(VR, Bool.not(U64.is_eq(f10, 0u64)), vr_fail(f10, "c04-" ++ stage_why(f10), 0n, 0n),
    Bool.pick(VR, Bool.not(CR_ok(cr)), vr_fail(10u64, "coincident-vertices", CR_a(cr), CR_b(cr)),
      fi_partition(List.append(&2, SO.Fi, SO.solid_fi(b, fds), EM.emb_fi(b, fds)),
        VR{True{}, 0u64, CR_nc(cr), "", 0n, 0n})))

def VR_ok(v: VR) -> Bool:
  VR{ok, stage, nc, code, a, b} = v
  ok

# Relation class: 1 all inside, 2 all outside, 5 mixed, 6 bad.
def rel_class(rs: List<&2, U64>, +nin: Nat, +nout: Nat, +nbad: Nat) -> U64:
  match rs:
    case []:
      Bool.pick(U64, Nat.is_eq(nbad, 0n),
        Bool.pick(U64, Nat.is_eq(nin, 0n), Bool.pick(U64, Nat.is_eq(nout, 0n), 6u64, 2u64),
          Bool.pick(U64, Nat.is_eq(nout, 0n), 1u64, 5u64)), 6u64)
    case +r <> t:
      rel_class(t, Nat.add(nin, Bool.pick(Nat, U64.is_eq(r, agg_in()), 1n, 0n)),
        Nat.add(nout, Bool.pick(Nat, U64.is_eq(r, agg_out()), 1n, 0n)),
        Nat.add(nbad, Bool.pick(Nat, agg_ok(r), 0n, 1n)))

def n_has(xs: List<&2, Nat>, +i: Nat) -> Bool:
  match xs:
    case []: False{}
    case x <> t: Bool.or(Nat.is_eq(x, i), n_has(t, i))

def n_pos(xs: List<&2, Nat>, +i: Nat, +at: Nat, +dflt: Nat) -> Nat:
  match xs:
    case []: dflt
    case x <> t: Bool.pick(Nat, Nat.is_eq(x, i), at, n_pos(t, i, Nat.add(at, 1n), dflt))

# Certified positive volume (strictly above zero).
def pos_vol(+v: I.I) -> Bool:
  F64.is_lt(0.0f64, I.i_lo(v))

# Intent material for booleans (mat tags match the model: 1 add,
# 2 remove, 3 same, 4 unknown). Union over a disjoint or contact append
# grows when both operands are positive; difference over a cavity shrinks
# when the tool is positive; carried and empty outcomes measure same.
# Anything else is unknown (fail-closed; C06 precedent).
def bool_mat(+op: U64, +outc: U64, +va: I.I, +vb: I.I, +tool: U64) -> U64:
  Bool.pick(U64, Bool.and(U64.is_eq(outc, 2u64), U64.is_eq(op, tag_union())),
    Bool.pick(U64, Bool.and(pos_vol(va), pos_vol(vb)), 1u64, 4u64),
    Bool.pick(U64, Bool.and(U64.is_eq(outc, 4u64), U64.is_eq(op, tag_diff())),
      Bool.pick(U64, pos_vol(Bool.pick(I.I, U64.is_eq(tool, 0u64), va, vb)), 2u64, 4u64),
      Bool.pick(U64, Bool.or(Bool.or(U64.is_eq(outc, 0u64), U64.is_eq(outc, 1u64)), U64.is_eq(outc, 3u64)),
        3u64, 4u64)))

def bake_lin(+la: F64, +lb: F64, +bb: BX) -> F64:
  F64.add(F64.max(la, lb), F64.mul(F64.add(bx_diag(bb), 1.0f64), 2.220446049250313e-16f64))

def ow_in(+j: Nat, hs: List<&2, Ty.HFace>) -> Bool:
  match hs:
    case []: False{}
    case Ty.HF{+fi, g} <> t:
      Bool.or(Nat.is_eq(fi, j), ow_in(j, t))

def cav_sample_go(ps: List<&2, V.Point>, +mfds: List<&2, SO.Fd>, +mbb: List<&2, I.I>) -> Maybe<&2, V.Point>:
  match ps:
    case []: None{}
    case +p <> t:
      Bool.pick(Maybe<&2, V.Point>, U64.is_eq(SO.classify_in(mfds, mbb, p), 1u64), Some{p},
        cav_sample_go(t, mfds, mbb))

def cav_cont_hit(+m: Ty.Brep, +mfds: List<&2, SO.Fd>, mp: Maybe<&2, V.Point>) -> Nat:
  match mp:
    case None{}: nsolids(m)
    case Some{p}: container_of(m, mfds, p)

def cav_conts(+t: Ty.Brep, ss: List<&2, Ty.Solid>, +mfds: List<&2, SO.Fd>, +mbb: List<&2, I.I>,
    +m: Ty.Brep) -> List<&2, Nat>:
  match ss:
    case []: []
    case Ty.So{g, ou, cs} <> s:
      +mp = cav_sample_go(solid_pts(t, ou), mfds, mbb)
      cav_cont_hit(m, mfds, mp) <> cav_conts(t, s, mfds, mbb, m)

def cav_cavs(+t: Ty.Brep, ss: List<&2, Ty.Solid>) -> List<&2, Nat>:
  match ss:
    case []: []
    case Ty.So{g, ou, cs} <> s:
      List.append(&2, Nat, sh_ids_go(cs), cav_cavs(t, s))

def cav_outs(+t: Ty.Brep, ss: List<&2, Ty.Solid>) -> List<&2, Nat>:
  match ss:
    case []: []
    case Ty.So{g, ou, cs} <> s:
      Ty.hsh_idx(ou) <> cav_outs(t, s)

# Cavity transplant: `bc` is append(minuend, tool) with every tool solid
# strictly inside the minuend. Every tool-outer shell becomes a cavity
# (SK_inner, faces flipped) of its container minuend-solid; every
# tool-cavity shell becomes a new island solid (SK_outer, faces flipped).
# Containers are found per tool solid via a strictly-inside sample.
type OW is Data:
  OW{ ti: Nat, sh: Nat, out: Bool, hit: Bool }

def ow_cav(+t: Ty.Brep, +j: Nat, cs: List<&2, Ty.HShell>, +ti: Nat) -> OW:
  match cs:
    case []: OW{ti, 0n, False{}, False{}}
    case +h <> +u:
      Bool.pick(OW, ow_in(j, Ty.sh_faces(nth_sh(Ty.brep_shs(t), Ty.hsh_idx(h)))),
        OW{ti, Ty.hsh_idx(h), False{}, True{}}, ow_cav(t, j, u, ti))

def cav_flip_fas(xs: List<&2, Ty.Face>, +nf: Nat, +at: Nat) -> List<&2, Ty.Face>:
  match xs:
    case []: []
    case Ty.Fa{g, su, ls, +same} <> t:
      Ty.Fa{g, su, ls, Bool.pick(Bool, Nat.is_lt(at, nf), same, Bool.not(same))} <>
        cav_flip_fas(t, nf, Nat.add(at, 1n))

# Flipping `same` alone breaks C04 orientation (loop winding must agree
# with the oriented normal): every flipped face's loops reverse and
# their coedges flip direction. Coedges are per-face uses, so only the
# flipped faces' loops are touched.
def hl_ids_go(hs: List<&2, Ty.HLoop>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match hs:
    case []: acc
    case h <> t: hl_ids_go(t, Ty.hlp_idx(h) <> acc)

def cav_floops(fs: List<&2, Ty.Face>, +nf: Nat, +at: Nat) -> List<&2, Nat>:
  match fs:
    case []: []
    case Ty.Fa{g, su, ls, same} <> t:
      List.append(&2, Nat, Bool.pick(List<&2, Nat>, Nat.is_lt(at, nf), [], hl_ids_go(ls, [])),
        cav_floops(t, nf, Nat.add(at, 1n)))

def hc_ids_go(hs: List<&2, Ty.HCoedge>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match hs:
    case []: acc
    case h <> t: hc_ids_go(t, Ty.hc_idx(h) <> acc)

def cav_fces(ls: List<&2, Ty.Loop>, +fl: List<&2, Nat>, +at: Nat) -> List<&2, Nat>:
  match ls:
    case []: []
    case Ty.Lp{g, ces, k} <> t:
      List.append(&2, Nat, Bool.pick(List<&2, Nat>, n_has(fl, at), hc_ids_go(ces, []), []),
        cav_fces(t, fl, Nat.add(at, 1n)))

def ce_flip(c: Ty.Coedge) -> Ty.Coedge:
  Ty.Ce{g, e, f, tr} = c
  Ty.Ce{g, e, Bool.not(f), tr}

def cav_flip_ces(xs: List<&2, Ty.Coedge>, +fc: List<&2, Nat>, +at: Nat) -> List<&2, Ty.Coedge>:
  match xs:
    case []: []
    case +h <> t:
      Bool.pick(Ty.Coedge, n_has(fc, at), ce_flip(h), h) <> cav_flip_ces(t, fc, Nat.add(at, 1n))

def cav_flip_lps(xs: List<&2, Ty.Loop>, +fl: List<&2, Nat>, +at: Nat) -> List<&2, Ty.Loop>:
  match xs:
    case []: []
    case Ty.Lp{g, +ces, k} <> t:
      Ty.Lp{g, Bool.pick(List<&2, Ty.HCoedge>, n_has(fl, at), List.reverse(&2, Ty.HCoedge, ces), ces), k} <>
        cav_flip_lps(t, fl, Nat.add(at, 1n))

def cav_kind_shs(xs: List<&2, Ty.Shell>, +outs: List<&2, Nat>, +nh: Nat, +at: Nat) -> List<&2, Ty.Shell>:
  match xs:
    case []: []
    case Ty.Sh{g, fs, k} <> t:
      +tool = Bool.not(Nat.is_lt(at, nh))
      +outer = n_has(outs, Nat.sub(at, nh))
      Ty.Sh{g, fs, Bool.pick(Ty.ShellKind, tool, Bool.pick(Ty.ShellKind, outer, Ty.SK_inner{},
        Ty.SK_outer{}), k)} <> cav_kind_shs(t, outs, nh, Nat.add(at, 1n))

def cav_add_cav(ss: List<&2, Ty.Solid>, +mi: Nat, +sh: Nat, +at: Nat) -> List<&2, Ty.Solid>:
  match ss:
    case []: []
    case Ty.So{g, ou, +cs} <> t:
      Ty.So{g, ou, Bool.pick(List<&2, Ty.HShell>, Nat.is_eq(at, mi), Ty.HS{sh, 0u64} <> cs, cs)} <>
        cav_add_cav(t, mi, sh, Nat.add(at, 1n))

def cav_add_cavs(+outs: List<&2, Nat>, +conts: List<&2, Nat>, +ss: List<&2, Ty.Solid>, +nh: Nat) -> List<&2, Ty.Solid>:
  match outs:
    case []: ss
    case o <> t:
      match conts:
        case []: ss
        case c <> u: cav_add_cavs(t, u, cav_add_cav(ss, c, Nat.add(o, nh), 0n), nh)

def cav_islands(cs: List<&2, Nat>, +nh: Nat) -> List<&2, Ty.Solid>:
  match cs:
    case []: []
    case c <> t: Ty.So{0u64, Ty.HS{Nat.add(c, nh), 0u64}, []} <> cav_islands(t, nh)

def cav_topsos(rem: Nat, +at: Nat) -> List<&2, Ty.HSolid>:
  match rem:
    case 0n: []
    case 1n+m: Ty.HSo{at, 0u64} <> cav_topsos(m, Nat.add(at, 1n))

def cav_fns_k(w: OW, +conts: List<&2, Nat>, +cavs: List<&2, Nat>, +nso: Nat) -> Nat:
  OW{+ti, +sh, +out, +hit} = w
  Bool.pick(Nat, Bool.and(hit, Bool.not(out)), Nat.add(nso, n_pos(cavs, sh, 0n, 0n)),
    nth_nat(conts, ti))

def cav_ok_conts(cs: List<&2, Nat>, +nso: Nat) -> Bool:
  match cs:
    case []: True{}
    case c <> t: Bool.and(Nat.is_lt(c, nso), cav_ok_conts(t, nso))

def PV_p(x: PV) -> V.Point:
  PV{p, s, v} = x
  p

def PV_s(x: PV) -> Nat:
  PV{p, s, v} = x
  s

def PV_v(x: PV) -> Nat:
  PV{p, s, v} = x
  v

def cr_go(xs: List<&2, PV>, +prev: PV, first: Bool, +acc: CR) -> CR:
  match xs:
    case []: acc
    case +x <> t:
      +p = PV_p(x)
      +s = PV_s(x)
      +v = PV_v(x)
      +pp = PV_p(prev)
      +sp = PV_s(prev)
      +vp = PV_v(prev)
      +eq = Bool.and(Bool.not(first), pt_eq3(p, pp))
      +intra = Bool.and(eq, Nat.is_eq(s, sp))
      +inter = Bool.and(eq, Bool.not(Nat.is_eq(s, sp)))
      cr_go(t, x, False{},
        CR{Bool.and(CR_ok(acc), Bool.not(intra)), Nat.add(CR_nc(acc), Bool.pick(Nat, inter, 1n, 0n)),
          Bool.pick(Nat, Bool.and(intra, CR_ok(acc)), vp, CR_a(acc)),
          Bool.pick(Nat, Bool.and(intra, CR_ok(acc)), v, CR_b(acc))})

def coin_contact(+b: Ty.Brep) -> CR:
  +mp = vsmap_of(b)
  +nso = nsolids(b)
  +ps = pv_so(B.msort(~PV, ~pv_lt, pv_of(b, Ty.brep_vs(b), mp, 0n, nso)))
  cr_go(ps, PV{V.Pt{0.0f64, 0.0f64, 0.0f64}, nso, 0n}, True{}, CR{True{}, 0n, 0n, 0n})

def vcore(+b: Ty.Brep) -> VR:
  +fds = SO.fds_of(b)
  vr_stage(stage10_of(b, fuel_of(b)), coin_contact(b), b, fds)

def SM_p(x: SM) -> V.Point:
  SM{p, s} = x
  p

def SM_s(x: SM) -> Nat:
  SM{p, s} = x
  s

type CV is Data:
  CV{ ok: Bool, brep: Ty.Brep, fns: List<&2, BD.Fn> }

# Strictness: `Bool.pick` evaluates both branches, so branching on the
# recursive call runs it twice per level (O(2^n) — past the sampling
# fix's sample counts this hangs); bind it once and `match` (O(n^2)).
def sm_dedup_go(+dup: Bool, +x: SM, rest: List<&2, SM>) -> List<&2, SM>:
  match dup:
    case True{}: rest
    case False{}: x <> rest

def sm_dedup(ps: List<&2, SM>) -> List<&2, SM>:
  match ps:
    case []: []
    case +x <> +t:
      sm_dedup_go(sm_has(t, SM_p(x), SM_s(x)), x, sm_dedup(t))

def ag_fold(xs: List<&2, SM>, cs: List<&2, U64>, +acc: AG) -> AG:
  match xs:
    case []: acc
    case x <> t:
      match cs:
        case []: acc
        case +c <> u:
          AG{+ok, +unc, +bad, +ms} = acc
          ag_fold(t, u, AG{ok, Bool.or(unc, U64.is_eq(c, 2u64)), bad, ag_set(ms, SM_s(x), c, 0n)})

def ag_run(+b: Ty.Brep, +fds: List<&2, SO.Fd>, +bb: List<&2, I.I>, +own: List<&2, SO.Fd>) -> AG:
  +xs = sm_dedup(List.append(&2, SM, sm_of(b, Ty.brep_sos(b), 0n), sm_int_of(own, Ty.brep_sos(b), 0n)))
  ag_fold(xs, cj_run(fds, bb, xs), AG{True{}, False{}, 0n, ag_masks(nsolids(b))})

def CV_ok(c: CV) -> Bool:
  CV{ok, brep, fns} = c
  ok

def CV_brep(c: CV) -> Ty.Brep:
  CV{ok, brep, fns} = c
  brep

def CV_fns(c: CV) -> List<&2, BD.Fn>:
  CV{ok, brep, fns} = c
  fns

def OW_ti(w: OW) -> Nat:
  OW{ti, sh, out, hit} = w
  ti

def OW_sh(w: OW) -> Nat:
  OW{ti, sh, out, hit} = w
  sh

def OW_out(w: OW) -> Bool:
  OW{ti, sh, out, hit} = w
  out

def OW_hit(w: OW) -> Bool:
  OW{ti, sh, out, hit} = w
  hit

def ow_go(+t: Ty.Brep, +j: Nat, ss: List<&2, Ty.Solid>, +ti: Nat) -> OW:
  match ss:
    case []: OW{ti, 0n, True{}, False{}}
    case Ty.So{g, +ou, cs} <> s:
      +w = ow_cav(t, j, cs, ti)
      Bool.pick(OW, ow_in(j, Ty.sh_faces(nth_sh(Ty.brep_shs(t), Ty.hsh_idx(ou)))),
        OW{ti, Ty.hsh_idx(ou), True{}, True{}},
        Bool.pick(OW, OW_hit(w), w, ow_go(t, j, s, Nat.add(ti, 1n))))

def cav_fns_go(+t: Ty.Brep, +nd: U64, +tool: U64, +conts: List<&2, Nat>, +cavs: List<&2, Nat>,
    +nso: Nat, rem: Nat, +at: Nat) -> List<&2, BD.Fn>:
  match rem:
    case 0n: []
    case 1n+m:
      fn_created(nd, cav_fns_k(ow_go(t, at, Ty.brep_sos(t), 0n), conts, cavs, nso), at, tool) <>
        cav_fns_go(t, nd, tool, conts, cavs, nso, m, Nat.add(at, 1n))

def cav_build(+m: Ty.Brep, +mfns: List<&2, BD.Fn>, +t: Ty.Brep, +nd: U64, +tool: U64,
    +conts: List<&2, Nat>) -> CV:
  +bc = brep_append(m, t)
  +nf = List.length(&2, Ty.Face, Ty.brep_fas(m))
  +nh = List.length(&2, Ty.Shell, Ty.brep_shs(m))
  +nso = nsolids(m)
  +outs = cav_outs(t, Ty.brep_sos(t))
  +cavs = cav_cavs(t, Ty.brep_sos(t))
  +msos = cav_add_cavs(outs, conts, Ty.brep_sos(m), nh)
  +iss = cav_islands(cavs, nh)
  +shl = Ty.cp_shells(Ty.brep_top(m))
  +fas = Ty.brep_fas(bc)
  +lps = Ty.brep_lps(bc)
  +fl = cav_floops(fas, nf, 0n)
  CV{True{},
    restamp(Ty.Br{Ty.brep_vs(bc), Ty.brep_es(bc), cav_flip_ces(Ty.brep_ces(bc), cav_fces(lps, fl, 0n), 0n),
      cav_flip_lps(lps, fl, 0n),
      cav_flip_fas(fas, nf, 0n), cav_kind_shs(Ty.brep_shs(bc), outs, nh, 0n),
      List.append(&2, Ty.Solid, msos, iss),
      Ty.Cp{cav_topsos(Nat.add(nso, List.length(&2, Ty.Solid, iss)), 0n), shl}, 0u64}),
    List.append(&2, BD.Fn, mfns,
      cav_fns_go(t, nd, tool, conts, cavs, nso, List.length(&2, Ty.Face, Ty.brep_fas(t)), 0n))}

def cavity(+m: Ty.Brep, +mfns: List<&2, BD.Fn>, +t: Ty.Brep, +mfds: List<&2, SO.Fd>,
    +mbb: List<&2, I.I>, +nd: U64, +tool: U64) -> CV:
  +conts = cav_conts(t, Ty.brep_sos(t), mfds, mbb, m)
  Bool.pick(CV, cav_ok_conts(conts, nsolids(m)), cav_build(m, mfns, t, nd, tool, conts),
    CV{False{}, Ty.brep_empty(), []})

def VR_stage(v: VR) -> U64:
  VR{ok, stage, nc, code, a, b} = v
  stage

def VR_nc(v: VR) -> Nat:
  VR{ok, stage, nc, code, a, b} = v
  nc

def VR_code(v: VR) -> String:
  VR{ok, stage, nc, code, a, b} = v
  code

def VR_a(v: VR) -> Nat:
  VR{ok, stage, nc, code, a, b} = v
  a

def VR_b(v: VR) -> Nat:
  VR{ok, stage, nc, code, a, b} = v
  b

def AG_unc(g: AG) -> Bool:
  AG{ok, unc, bad, masks} = g
  unc

def AG_masks(g: AG) -> List<&2, U64>:
  AG{ok, unc, bad, masks} = g
  masks

def BX_x0(b: BX) -> F64:
  BX{x0, x1, y0, y1, z0, z1} = b
  x0

def BX_x1(b: BX) -> F64:
  BX{x0, x1, y0, y1, z0, z1} = b
  x1

def BX_y0(b: BX) -> F64:
  BX{x0, x1, y0, y1, z0, z1} = b
  y0

def BX_y1(b: BX) -> F64:
  BX{x0, x1, y0, y1, z0, z1} = b
  y1

def BX_z0(b: BX) -> F64:
  BX{x0, x1, y0, y1, z0, z1} = b
  z0

def BX_z1(b: BX) -> F64:
  BX{x0, x1, y0, y1, z0, z1} = b
  z1

def Out_ok(o: Out) -> Bool:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  ok

def Out_kind(o: Out) -> U64:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  kind

def Out_what(o: Out) -> String:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  what

def Out_loc(o: Out) -> String:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  loc

def Out_why(o: Out) -> String:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  why

def Out_fix(o: Out) -> String:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  fix

def Out_carry(o: Out) -> U64:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  carry

def Out_brep(o: Out) -> Ty.Brep:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  brep

def Out_cells(o: Out) -> List<&2, BD.Cl>:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  cells

def Out_fns(o: Out) -> List<&2, BD.Fn>:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  fns

def Out_rv(o: Out) -> List<&2, F.Lp>:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  rv

def Out_nc(o: Out) -> Nat:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  nc

def Out_vol(o: Out) -> I.I:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  vol

def Out_area(o: Out) -> I.I:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  area

def Out_bb(o: Out) -> BX:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  bb

def Out_lin(o: Out) -> F64:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  lin

def Out_hasm(o: Out) -> Bool:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  hasm

def Out_mat(o: Out) -> U64:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  mat

def Out_fc(o: Out) -> Nat:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  fc

def Out_fm(o: Out) -> Nat:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  fm

def Out_sh(o: Out) -> Nat:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  sh

def Out_ho(o: Out) -> Nat:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  ho

def Out_nct(o: Out) -> Nat:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  nct

def Out_proof(o: Out) -> String:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  proof

def Out_del(o: Out) -> List<&2, Del>:
  Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, vol, area, bb, lin, hasm, mat,
    fc, fm, sh, ho, nct, proof, del} = o
  del

# Cells for appended results: shift the second operand's cell ids and
# parent links (par 0 means no parent) by the first operand's cell count.
def cells_shift(cs: List<&2, BD.Cl>, +n: Nat) -> List<&2, BD.Cl>:
  match cs:
    case []: []
    case BD.Cl{id, +par, nd, k, lp, mat, lo, hi} <> t:
      BD.Cl{Nat.add(id, n), Bool.pick(Nat, Nat.is_eq(par, 0n), 0n, Nat.add(par, n)), nd, k, lp, mat,
        lo, hi} <> cells_shift(t, n)

# Faces created at this node: created role with this node's id. Carried
# created-role faces from earlier booleans do not count.
def fn_created_here(fs: List<&2, BD.Fn>, +nd: U64) -> Nat:
  match fs:
    case []: 0n
    case +f <> t:
      Nat.add(Bool.pick(Nat, Bool.and(U64.is_eq(fn_role(f), role_created()), U64.is_eq(fn_nd(f), nd)),
        1n, 0n), fn_created_here(t, nd))

def in_brep(x: In) -> Ty.Brep:
  In{brep, cells, fns, m, tx, ty, tz, rv, vol, area, bb, lin, bo, px} = x
  brep

def in_bo(x: In) -> Bool:
  In{brep, cells, fns, m, tx, ty, tz, rv, vol, area, bb, lin, bo, px} = x
  bo

def in_lin(x: In) -> F64:
  In{brep, cells, fns, m, tx, ty, tz, rv, vol, area, bb, lin, bo, px} = x
  lin

def in_px(x: In) -> Bool:
  In{brep, cells, fns, m, tx, ty, tz, rv, vol, area, bb, lin, bo, px} = x
  px

def in_fns(x: In) -> List<&2, BD.Fn>:
  In{brep, cells, fns, m, tx, ty, tz, rv, vol, area, bb, lin, bo, px} = x
  fns

def empty_eab(+op: U64, sameab: Bool) -> U64:
  match sameab:
    case True{}: Bool.pick(U64, U64.is_eq(op, tag_diff()), 3u64, 0u64)
    case False{}: Bool.pick(U64, U64.is_eq(op, tag_union()), 1u64, 3u64)

def empty_ea(+op: U64, eb: Bool, sameab: Bool) -> U64:
  match eb:
    case True{}: 3u64
    case False{}: empty_eab(op, sameab)

def empty_fab(+op: U64, sameab: Bool) -> U64:
  match sameab:
    case True{}: Bool.pick(U64, U64.is_eq(op, tag_diff()), 3u64, 0u64)
    case False{}: Bool.pick(U64, U64.is_eq(op, tag_inter()), 3u64, 0u64)

def empty_fabb(+op: U64, sameab: Bool) -> U64:
  match sameab:
    case True{}: Bool.pick(U64, U64.is_eq(op, tag_diff()), 3u64, 0u64)
    case False{}: 10u64

def empty_fa(+op: U64, eb: Bool, +sameab: Bool) -> U64:
  match eb:
    case True{}: empty_fab(op, sameab)
    case False{}: empty_fabb(op, sameab)

# Empty-compound algebra (§4) plus identical operands (same node id):
# 10 means no empty case, continue the pipeline; else the outcome.
def empty_outcome(+op: U64, +ea: Bool, +eb: Bool, +sameab: Bool) -> U64:
  match ea:
    case True{}: empty_ea(op, eb, sameab)
    case False{}: empty_fa(op, eb, sameab)

def out_empty(+nd: U64, +proof: String, +del: List<&2, Del>) -> Out:
  Out{True{}, 0u64, "", "", "", "", 0u64, Ty.brep_empty(), [], [], [], 0n, I.ipt(0.0f64),
    I.ipt(0.0f64), bx_zero(), 0.0f64, True{}, 3u64, 0n, 0n, 0n, 0n, 0n, proof, del}

def out_carry_direct(x: In, +side: U64, +proof: String, +del: List<&2, Del>) -> Out:
  In{+brep, cells, fns, m, tx, ty, tz, rv, vol, area, bb, lin, bo, px} = x
  Out{True{}, 0u64, "", "", "", "", side, brep, cells, fns, rv, 0n, vol, area, bb, lin, False{}, 3u64,
    0n, 0n, nsolids(brep), genus_of(brep), 0n, proof, del}

def out_carry_nct(x: In, +side: U64, +nc: Nat, +proof: String, +del: List<&2, Del>) -> Out:
  In{+brep, cells, fns, m, tx, ty, tz, rv, vol, area, bb, lin, bo, px} = x
  Out{True{}, 0u64, "", "", "", "", side, brep, cells, fns, rv, 0n, vol, area, bb, lin, False{}, 3u64,
    0n, 0n, nsolids(brep), genus_of(brep), nc, proof, del}

def op_carry_nm(+side: U64) -> String:
  Bool.pick(String, U64.is_eq(side, 1u64), "carry-A", "carry-B")

def carry_check(x: In, +side: U64, +nd: U64, v: VR, +proof: String, +del: List<&2, Del>) -> Out:
  VR{+ok, +stage, +nc, +code, +a, +b} = v
  Bool.pick(Out, ok, out_carry_nct(x, side, nc, proof, del),
    out_fail(fk_uncertain(), op_carry_nm(side), "node " ++ U64.show(nd),
      "operand-failed-check: " ++ code ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b),
      "fix the operand so it passes check, then retry the boolean"))

# Carried results republish an input unchanged. Bodies that already passed
# through C08 carry their validation by induction (deterministic
# re-validation would repeat the identical computation); older bodies get
# their first C07 exposure here (L2).
def carry_out(+x: In, +side: U64, +nd: U64, +proof: String, +del: List<&2, Del>) -> Out:
  Bool.pick(Out, in_bo(x), out_carry_direct(x, side, proof, del),
    carry_check(x, side, nd, vcore(in_brep(x)), proof, del))

# Admit order (first-match-wins within the stage): open shells, face
# domain, edge domain, then placement exactness (F4: interval placements
# bake at an uncertified midpoint, so they refuse as `interval-placement`
# rather than publishing midpoint geometry as certified).
def admit_code(+sha: Bool, +shb: Bool, +faa: U64, +fab: U64, +eda: U64, +edb: U64, +pxa: Bool,
    +pxb: Bool) -> U64:
  Bool.pick(U64, sha, 1u64, Bool.pick(U64, shb, 2u64,
    Bool.pick(U64, Bool.not(U64.is_eq(faa, 0u64)), 3u64, Bool.pick(U64, Bool.not(U64.is_eq(fab, 0u64)), 4u64,
      Bool.pick(U64, Bool.not(U64.is_eq(eda, 0u64)), 5u64, Bool.pick(U64, Bool.not(U64.is_eq(edb, 0u64)),
        6u64, Bool.pick(U64, Bool.not(pxa), 7u64, Bool.pick(U64, Bool.not(pxb), 8u64, 0u64))))))))

def admit_fail(+op: U64, +code: U64, +a: In, +b: In, +nd: U64, +an: U64, +bn: U64) -> Out:
  +nm = op_name(op)
  Bool.pick(Out, U64.is_eq(code, 1u64),
    out_fail(fk_unsupported(), nm, "node " ++ U64.show(an),
      "open-shell-operand: booleans are closed-solid operators", "close the shell or pick a solid operand"),
    Bool.pick(Out, U64.is_eq(code, 2u64),
      out_fail(fk_unsupported(), nm, "node " ++ U64.show(bn),
        "open-shell-operand: booleans are closed-solid operators", "close the shell or pick a solid operand"),
      Bool.pick(Out, U64.is_eq(code, 3u64),
        out_fail(fk_unsupported(), nm,
          "node " ++ U64.show(an) ++ " face " ++ Nat.show(admit_fas_at(Ty.brep_fas(in_brep(a)), 0n)),
          surf_why(admit_fas(Ty.brep_fas(in_brep(a)), 0n)) ++ ": face outside the admitted domain",
          "boolean operands need plane, cylinder, cone, sphere, torus or flat-patch faces"),
        Bool.pick(Out, U64.is_eq(code, 4u64),
          out_fail(fk_unsupported(), nm,
            "node " ++ U64.show(bn) ++ " face " ++ Nat.show(admit_fas_at(Ty.brep_fas(in_brep(b)), 0n)),
            surf_why(admit_fas(Ty.brep_fas(in_brep(b)), 0n)) ++ ": face outside the admitted domain",
            "boolean operands need plane, cylinder, cone, sphere, torus or flat-patch faces"),
          Bool.pick(Out, U64.is_eq(code, 5u64),
            out_fail(fk_unsupported(), nm,
              "node " ++ U64.show(an) ++ " edge " ++ Nat.show(admit_eds_at(Ty.brep_es(in_brep(a)), 0n)),
              "edge-kind-not-supported: edge outside the admitted domain",
              "boolean operands need line, cubic, circle or rational-quadratic edges"),
            Bool.pick(Out, U64.is_eq(code, 6u64),
              out_fail(fk_unsupported(), nm,
                "node " ++ U64.show(bn) ++ " edge " ++ Nat.show(admit_eds_at(Ty.brep_es(in_brep(b)), 0n)),
                "edge-kind-not-supported: edge outside the admitted domain",
                "boolean operands need line, cubic, circle or rational-quadratic edges"),
              Bool.pick(Out, U64.is_eq(code, 7u64),
                out_fail(fk_unsupported(), nm, "node " ++ U64.show(an),
                  "interval-placement: operand placement is not certified exact",
                  "use move or quarter-turn rotations; general-angle placements need certified intervals (a C11 item)"),
                out_fail(fk_unsupported(), nm, "node " ++ U64.show(bn),
                  "interval-placement: operand placement is not certified exact",
                  "use move or quarter-turn rotations; general-angle placements need certified intervals (a C11 item)"))))))))

def bake_of(x: In) -> Ty.Brep:
  In{brep, cells, fns, m, tx, ty, tz, rv, vol, area, bb, lin, bo, px} = x
  xf_brep(m, tx, ty, tz, brep)

def intersect_fail(+nd: U64, +an: U64, +bn: U64, v: VR) -> Out:
  VR{ok, +stage, nc, +code, +a, +b} = v
  Bool.pick(Out, Bool.and(Bool.not(U64.is_eq(stage, 0u64)), Bool.not(U64.is_eq(stage, 10u64))),
    out_fail(fk_uncertain(), "intersect", "node " ++ U64.show(nd),
      "intersect-rejected: c04-" ++ stage_why(stage) ++ " on the combined boundary",
      "report these operands"),
    Bool.pick(Out, U64.is_eq(stage, 10u64),
      out_fail(fk_uncertain(), "intersect", "node " ++ U64.show(nd),
        "coincident-vertices " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++ " within one operand after baking",
        "report these operands"),
      Bool.pick(Out, is_uncertain_code(code),
        out_fail(fk_uncertain(), "intersect", "node " ++ U64.show(nd),
          code ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++ " between nodes " ++ U64.show(an) ++
            " and " ++ U64.show(bn),
          "separate the operands or nest one inside the other"),
        Bool.pick(Out, is_unsupported_code(code),
          out_fail(fk_unsupported(), "intersect", "node " ++ U64.show(nd),
            code ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b), "report these operands"),
          Bool.pick(Out, is_transverse_code(code),
            out_fail(fk_unsupported(), "intersect", "node " ++ U64.show(nd),
              "boundaries-cross-or-overlap: " ++ code ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++
                " between nodes " ++ U64.show(an) ++ " and " ++ U64.show(bn),
              "move the operands apart or nest one inside the other; general intersecting booleans need face splitting"),
            out_fail(fk_uncertain(), "intersect", "node " ++ U64.show(nd),
              "unknown-finding: " ++ code ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++
                " between nodes " ++ U64.show(an) ++ " and " ++ U64.show(bn),
              "report these operands"))))))

def rel_has(rs: List<&2, U64>, +c: U64) -> Bool:
  match rs:
    case []: False{}
    case r <> t: Bool.or(U64.is_eq(r, c), rel_has(t, c))

# A per-solid mixed mask (samples strictly inside AND strictly
# outside the other operand) proves the boundaries cross: the
# samples sit on one connected solid boundary, so an arc between an
# inside and an outside sample crosses the other boundary
# (continuity). Report it as a crossing, not an inconsistency.
def rel_why(+ra: List<&2, U64>, +rb: List<&2, U64>) -> String:
  Bool.pick(String, Bool.or(rel_has(ra, 3u64), rel_has(rb, 3u64)),
    "boundaries-cross-or-overlap: one solid samples strictly inside and outside the other",
    "contact-not-certified")

def vcode(v: VR) -> String:
  VR{ok, +stage, nc, +code, +a, +b} = v
  Bool.pick(String, Bool.not(U64.is_eq(stage, 0u64)), "c04-" ++ stage_why(stage),
    code ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b))

# Assembled results are pure B-rep bodies: rv is [] so the display
# tessellator renders the baked B-rep rather than stale lathe profiles.
# Stored boxes come from recomputed world boxes (F3/F10), never the
# advisory `In.bb`.
def append_out(+op: U64, a: In, b: In, +bc: Ty.Brep, +nd: U64, +nc: Nat, +wa: BX, +wb: BX,
    +proof: String) -> Out:
  In{brep, +cells, fns, m, tx, ty, tz, +rv, +vol, area, bb, lin, bo, pxa} = a
  In{brep2, cells2, fns2, m2, tx2, ty2, tz2, +rv2, +vol2, area2, bb2, lin2, bo2, pxb} = b
  +fn = List.append(&2, BD.Fn, fns, fns2)
  +bbx = bx_hull(wa, wb)
  Out{True{}, 0u64, "", "", "", "", 0u64, bc,
    List.append(&2, BD.Cl, cells, cells_shift(cells2, List.length(&2, BD.Cl, cells))), fn,
    [], 0n, I.iadd(vol, vol2), I.iadd(area, area2), bbx,
    bake_lin(lin, lin2, bbx), True{}, bool_mat(op, 2u64, vol, vol2, 0u64),
    fn_created_here(fn, nd), 0n, nsolids(bc), genus_of(bc), nc, proof, []}

def append_valid(a: In, b: In, +bc: Ty.Brep, +nd: U64, +wa: BX, +wb: BX, +proof: String) -> Out:
  +v = vcore(bc)
  Bool.pick(Out, VR_ok(v), append_out(tag_union(), a, b, bc, nd, VR_nc(v), wa, wb, proof),
    out_fail(fk_uncertain(), "validate", "node " ++ U64.show(nd),
      "validation-rejected: " ++ vcode(v), "report these operands"))

def append_rebox(+op: U64, +a: In, +b: In, +bc: Ty.Brep, +ba: Ty.Brep, +bb: Ty.Brep, +nd: U64,
    +nc: Nat) -> Out:
  append_out(op, a, b, bc, nd, nc, world_box(ba, in_lin(a)), world_box(bb, in_lin(b)), "")

def run_append(+a: In, +b: In, +ba: Ty.Brep, +bb: Ty.Brep, +wa: BX, +wb: BX, +nd: U64,
    +proof: String) -> Out:
  +bc = brep_append(ba, bb)
  append_valid(a, b, bc, nd, wa, wb, proof)

def run_disjoint(+op: U64, +a: In, +b: In, +ba: Ty.Brep, +bb: Ty.Brep, +wa: BX, +wb: BX, +nd: U64,
    +an: U64, +bn: U64) -> Out:
  +proof = "disjoint-boxes A" ++ bx_show(wa) ++ " B" ++ bx_show(wb)
  Bool.pick(Out, U64.is_eq(op, tag_union()), run_append(a, b, ba, bb, wa, wb, nd, proof),
    Bool.pick(Out, U64.is_eq(op, tag_diff()), carry_out(a, 1u64, nd, proof, del_classified(in_fns(b))),
      out_empty(nd, proof,
        List.append(&2, Del, del_classified(in_fns(a)), del_classified(in_fns(b))))))

def cavity_valid(+op: U64, a: In, b: In, +cv: CV, +nd: U64, +wm: BX) -> Out:
  In{brep, cells, fns, m, tx, ty, tz, +rv, +vol, area, +bb, lin, bo, pxa} = a
  In{brep2, cells2, fns2, m2, tx2, ty2, tz2, +rv2, +vol2, area2, bb2, lin2, bo2, pxb} = b
  +rb = CV_brep(cv)
  +rf = CV_fns(cv)
  +v = vcore(rb)
  Bool.pick(Out, VR_ok(v),
    Out{True{}, 0u64, "", "", "", "", 0u64, rb, cells, rf, [],
      0n, I.isub(vol, vol2), I.iadd(area, area2), wm, bake_lin(lin, lin2, wm),
      True{}, bool_mat(op, 4u64, vol, vol2, 1u64), fn_created_here(rf, nd), 0n, nsolids(rb),
      genus_of(rb), VR_nc(v), "", []},
    out_fail(fk_uncertain(), "validate", "node " ++ U64.show(nd),
      "validation-rejected: " ++ vcode(v), "report these operands"))

def run_cavity(+op: U64, +a: In, +b: In, +ba: Ty.Brep, +bx: Ty.Brep, +nd: U64) -> Out:
  In{brep, cells, fns, m, tx, ty, tz, rv, vol, area, bb, lin, bo, pxa} = a
  In{brep2, cells2, fns2, m2, tx2, ty2, tz2, rv2, vol2, area2, bb2, lin2, bo2, pxb} = b
  +fa = SO.fds_of(ba)
  +cv = cavity(ba, fns, bx, fa, SO.bbox(fa, []), nd, 1u64)
  Bool.pick(Out, CV_ok(cv), cavity_valid(op, a, b, cv, nd, world_box(ba, in_lin(a))),
    out_fail(fk_uncertain(), "assemble",
      "node " ++ U64.show(nd), "no-container-sample: a tool solid has no strictly-inside sample",
      "nest the tool strictly inside the minuend"))

# Match, not nested picks: the outcome arms each hold both In values
# (122 words), and nested-pick continuations over that env exceed the
# 247-word segment limit.
def run_assemble(+op: U64, +outc: U64, +a: In, +b: In, +ba: Ty.Brep, +bb: Ty.Brep, +bc: Ty.Brep,
    +nd: U64, +nc: Nat) -> Out:
  match outc:
    case 0u64: carry_out(a, 1u64, nd, "", del_classified(in_fns(b)))
    case 1u64: carry_out(b, 2u64, nd, "", del_classified(in_fns(a)))
    case 3u64: out_empty(nd, "", List.append(&2, Del, del_classified(in_fns(a)), del_classified(in_fns(b))))
    case 2u64: append_rebox(op, a, b, bc, ba, bb, nd, nc)
    case _: run_cavity(op, a, b, ba, bb, nd)

# Select + assemble + orient (inherited) + validate + publish-fields.
def run_outcome(+op: U64, a: In, b: In, +ba: Ty.Brep, +bb: Ty.Brep, +bc: Ty.Brep, +ca: U64,
    +cb: U64, +nd: U64, +an: U64, +bn: U64, +nc: Nat) -> Out:
  +agga = Bool.pick(U64, U64.is_eq(ca, 1u64), agg_in(), agg_out())
  +aggb = Bool.pick(U64, U64.is_eq(cb, 1u64), agg_in(), agg_out())
  +outc = outcome(op, decide(agga, aggb))
  Bool.pick(Out, U64.is_eq(outc, 5u64),
    out_fail(fk_uncertain(), "classify", "node " ++ U64.show(nd),
      "inconsistent-classification between nodes " ++ U64.show(an) ++ " and " ++ U64.show(bn),
      "separate the operands or nest one strictly inside the other"),
    run_assemble(op, outc, a, b, ba, bb, bc, nd, nc))

def run_rels(+op: U64, +a: In, b: In, +ba: Ty.Brep, +bb: Ty.Brep, +bc: Ty.Brep, +ra: List<&2, U64>,
    +rb: List<&2, U64>, +nd: U64, +an: U64, +bn: U64, +nc: Nat) -> Out:
  +ca = rel_class(ra, 0n, 0n, 0n)
  +cb = rel_class(rb, 0n, 0n, 0n)
  Bool.pick(Out, Bool.or(U64.is_eq(ca, 6u64), U64.is_eq(cb, 6u64)),
    Bool.pick(Out, Bool.or(rel_has(ra, 3u64), rel_has(rb, 3u64)),
      out_fail(fk_unsupported(), "classify", "node " ++ U64.show(nd),
        rel_why(ra, rb) ++ " between nodes " ++ U64.show(an) ++ " and " ++ U64.show(bn),
        "move the operands apart or nest one inside the other; general intersecting booleans need face splitting"),
      out_fail(fk_uncertain(), "classify", "node " ++ U64.show(nd),
        rel_why(ra, rb) ++ " between nodes " ++ U64.show(an) ++ " and " ++ U64.show(bn),
        "separate the operands or nest one strictly inside the other")),
    Bool.pick(Out, Bool.or(U64.is_eq(ca, 5u64), U64.is_eq(cb, 5u64)),
      out_fail(fk_unsupported(), "classify", "node " ++ U64.show(nd),
        "mixed-solid-relations: one operand has solids both inside and outside the other",
        "boolean operands with mixed containment need per-solid measures (a C11 item)"),
      run_outcome(op, a, b, ba, bb, bc, ca, cb, nd, an, bn, nc)))

# Classify stage: per-solid sampling against the other operand, in
# parallel. Uncertain samples fail (L4); touching-only solids fail as
# `contact-not-certified`; per-solid mixed inside/outside proves a
# crossing and fails as `boundaries-cross-or-overlap`; operands whose
# solids disagree in relation fail as `mixed-solid-relations`
# (per-solid measures need sub-brep integration, a C11 item).
def run_classify(+op: U64, +a: In, b: In, +ba: Ty.Brep, +bb: Ty.Brep, +bc: Ty.Brep, +nd: U64,
    +an: U64, +bn: U64, +nc: Nat) -> Out:
  +fa = SO.fds_of(ba)
  +fb = SO.fds_of(bb)
  +aga = ag_run(ba, fb, SO.bbox(fb, []), fa)
  +agb = ag_run(bb, fa, SO.bbox(fa, []), fb)
  +unca = AG_unc(aga)
  +uncb = AG_unc(agb)
  Bool.pick(Out, Bool.or(unca, uncb),
    out_fail(fk_uncertain(), "classify", "node " ++ U64.show(nd),
      "uncertain-classification against node " ++ U64.show(Bool.pick(U64, unca, bn, an)),
      "separate the operands or nest one inside the other"),
    run_rels(op, a, b, ba, bb, bc, rel_list(AG_masks(aga)), rel_list(AG_masks(agb)), nd, an, bn, nc))

# Intersect stage: append the baked operands and run the validation
# core. Any crossing, penetration or overlap fails as
# `boundaries-cross-or-overlap` (fusing them needs face splitting);
# uncertainty fails as numerical-uncertainty. Split is a certified no-op
# past this point.
def run_intersect(+op: U64, +a: In, +b: In, +ba: Ty.Brep, +bb: Ty.Brep, +nd: U64, +an: U64,
    +bn: U64) -> Out:
  +bc = brep_append(ba, bb)
  +v = vcore(bc)
  Bool.pick(Out, VR_ok(v), run_classify(op, a, b, ba, bb, bc, nd, an, bn, VR_nc(v)),
    intersect_fail(nd, an, bn, v))

# Broad-phase: bake first, then decide disjointness from recomputed world
# boxes (F3) — never the advisory `In.bb`. Certified disjoint boxes
# short-circuit (the receipt shows the boxes via `proof`); union still
# assembles and validates the append.
def run_broad(+op: U64, +a: In, +b: In, +nd: U64, +an: U64, +bn: U64) -> Out:
  +ba = bake_of(a)
  +bb = bake_of(b)
  +wa = world_box(ba, in_lin(a))
  +wb = world_box(bb, in_lin(b))
  Bool.pick(Out, bx_disjoint(wa, wb), run_disjoint(op, a, b, ba, bb, wa, wb, nd, an, bn),
    run_intersect(op, a, b, ba, bb, nd, an, bn))

# Admit stage: closed solids in the admitted domain with certified exact
# placements, else `unsupported-op` naming the operand, node and entity.
# First-match-wins in stage order.
def run_admit(+op: U64, +a: In, +b: In, +nd: U64, +an: U64, +bn: U64) -> Out:
  +br = in_brep(a)
  +bb = in_brep(b)
  +code = admit_code(admit_shs(Ty.brep_shs(br)), admit_shs(Ty.brep_shs(bb)), admit_fas(Ty.brep_fas(br), 0n),
    admit_fas(Ty.brep_fas(bb), 0n), admit_eds(Ty.brep_es(br)), admit_eds(Ty.brep_es(bb)), in_px(a),
    in_px(b))
  Bool.pick(Out, U64.is_eq(code, 0u64), run_broad(op, a, b, nd, an, bn), admit_fail(op, code, a, b, nd, an, bn))

def run_empty(+op: U64, +a: In, +b: In, +nd: U64, +an: U64, +bn: U64, +sameab: Bool) -> Out:
  +ea = Nat.is_eq(nsolids(in_brep(a)), 0n)
  +eb = Nat.is_eq(nsolids(in_brep(b)), 0n)
  +eo = empty_outcome(op, ea, eb, sameab)
  Bool.pick(Out, U64.is_eq(eo, 10u64), run_admit(op, a, b, nd, an, bn),
    Bool.pick(Out, U64.is_eq(eo, 3u64),
      out_empty(nd, "", List.append(&2, Del, del_classified(in_fns(a)), del_classified(in_fns(b)))),
      Bool.pick(Out, U64.is_eq(eo, 0u64), carry_out(a, 1u64, nd, "", del_classified(in_fns(b))),
        carry_out(b, 2u64, nd, "", del_classified(in_fns(a))))))

# The pipeline entry. `an`/`bn` are the operand node ids (for diagnoses),
# `sameab` says both operands are the same node.
def run(+op: U64, a: In, b: In, +nd: U64, +an: U64, +bn: U64, +sameab: Bool) -> Out:
  run_empty(op, a, b, nd, an, bn, sameab)
