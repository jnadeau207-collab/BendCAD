# C04 packet contract — boundary-representation topology

Scope: what this packet DELIVERS is representation + validation —
entity types, the edge/coedge split, value-level validation,
generational stores with a push/issued/resolve protocol — in
`src/c04/types.bend`, plus the profile validators (`brep_checked`:
incidence, edge-use pairing, closed boundaries, trimming
consistency, shell ownership, geometric embedding, vertex-link
validation (stage H, IMPLEMENTED), and kind-aware per-face
orientation (L-plane certified, L-varying explicit skip; global
outwardness deferred, §12)) in
`src/c04/ops.bend`. §4 states the implemented rules; §12 records
the remaining deferrals honestly. `brep_checked` is the validity
verdict beyond value-level shape.

MASTER_PLAN C04 (verbatim): "Implement vertices, edges, oriented
edge uses/coedges, loops, faces, shells, solids, cavities, and
compounds. Separate an underlying edge from its oriented uses. A
closed edge can begin and end at the same vertex; a seam can occur
twice on one face; a singular pole requires an explicit degenerate
representation. For the admitted manifold-solid profile, validate
local incidence and vertex links, orientation, closed boundaries,
trimming consistency, and geometric embedding. Counting faces or
checking Euler's formula alone is not solid validation. Open
surfaces remain valid under a different explicitly named profile.
Exit: valid sphere/cylinder seams and cavities are accepted;
dangling, inverted, self-intersecting, and nonmanifold
counterexamples are diagnosed appropriately."

Delivered against that scope: representation (first paragraph)
and profile validation (second paragraph) are implemented, pinned by
laws, and tested. The exit fixtures (seams/cavities accepted,
counterexamples diagnosed) are runnable via `brep_checked` and
pinned in `laws/c04.bend` (32 `ck_*`: 10 accepts + 21 rejects
+ fuel) and asserted at runtime by the suite appends
(`pos_g10`–`pos_g14`: 13 accepts; `neg_g7`–`neg_g10`:
32 rejects, incl. the C04.1 outer-kind/ownership and
the C04.2 vertex-link / connectedness / quadric-membership /
coincidence / segment-crossing / orientation diagnoses).

## 1. Representation policy: the edge is not its uses

The UNDERLYING edge (`Ed`) carries geometry + endpoints and is
unoriented: two vertex handles `v0/v1` plus an `EdgeKind` (a C03
curve arm over a strict domain, or the explicit degenerate
marker). Orientation lives ONLY in coedges (`Ce`): one oriented
use = edge handle + `fwd` flag + trimming curve in the owning
face's `(u,v)` parameter space (a C03 trim arm, never retrofitted).

Consequences, all enforced at value level:

- A closed edge has `v0 == v1` (structural handle equality) with
  `EK_curve` — accepted, not degenerate (`pos-ec-closed-ok`).
- A seam edge occurs twice as two coedges with opposite
  `fwd`; `brep_checked` stage C enforces the twice-opposite
  rule (`ck_sphere`/`ck_cyl`). The loop value shape admits
  any coedge multiset (`pos-lp-seam2-ok`).
- A singular pole is `EK_degenerate` AND pinched to one vertex
  (`edge_valid` requires `hv_eq(v0, v1)`); a degenerate edge
  across two vertices is `invalid-input` (`neg-ed-degen-idx/gen`).
  Pole-ness is content (`ekind_tag` 0/1), never inferred.
- A cavity IS a shell of kind `SK_inner` referenced from
  `Solid.cavities` (`ck_cav`); the outer boundary is `SK_outer`
  (`ck_outerkind` rejects an `SK_inner` outer); `SK_open` is
  admitted only under `P_open_shell` (`ck_open` vs
  `ck_open_solid`). Every shell is owned at most once: no
  outer/cavity aliasing (`ck_alias`), no cavity dup
  (`ck_cavdup`), no reuse across solids (`ck_reuse`), no
  sharing between solids and the compound root (`ck_cpshare`).
  Kind and ownership are store-level `brep_checked` stage-F
  verdicts, not value shape: `mk_solid`/`so_push` stay total
  by design.
- A face carries >= 1 loop and a `same` flag aligning (or
  flipping) the surface normal; shells carry >= 1 face; loops
  carry >= 1 coedge. Emptiness is rejected at the constructor
  AND at push AND at assembly (one centralized `*_valid`
  layer, consumed by all three paths).

Ownership contract (hierarchy exclusivity + allowed
multi-ref), enforced by `brep_checked` stage F over member
lists only. EXCLUSIVE (owned at most once — no dup within
one member list, no sharing across owners): each loop is
owned by at most one face (`fas_loop_own_c`); each face by
at most one shell (`shs_face_own_c`); each shell by at most
one solid-or-compound slot (`sos_own_c` + `cp_sh_own_c`);
each solid listed at most once in the compound root
(`cp_so_own_c`). ALLOWED multi-ref: vertices shared by many
edges; one edge used by one (boundary, open only) or two
(opposite-`fwd`) coedges per stage C; every coedge in
exactly one loop (stage H traversal well-definedness);
curve/surface/trim `GVal`s are plain values, freely reused.
APPEND-ONLY UNREACHABLE-HISTORY RULE: stores grow by push
only (no delete/update, §6); a slot never referenced from
the root is retained history — never garbage, never an
ownership rejection. Ownership verdicts read member lists,
not store reachability.

## 2. Types (all in `src/c04/types.bend`)

Handles (one per entity, §6): `HVertex/HE/HC/HL/HF/HS/HSo`,
each a structural `(idx: Nat, gen: U64)` pair. Entities:
`Vertex{Vx}` (gen + finite point), `Edge{Ed}` (gen + v0/v1 +
kind), `Coedge{Ce}` (gen + edge + fwd + trim), `Loop{Lp}`
(gen + coedge list + kind), `Face{Fa}` (gen + surface + loop
list + same), `Shell{Sh}` (gen + face list + kind),
`Solid{So}` (gen + outer + cavities), `Compound{Cp}` (solid
list + open-shell list, the root grouping). `Brep{Br}` holds
the seven explicit stores + `top` + the issue `stamp`.

One value union, one result type: `TVal` (18 arms: F/N/Bool,
7 entities, compound, brep, 7 handles) and `TRes`
(`Tok{v}`/`Terr{kind}`) reusing C00 `FailKind` — no new
taxonomy. Every fallible op returns `TRes`.

Total projectors with documented defaults (§6 of types.bend):
`tres_f/n/b` yield `0.0/0n/False`; entity projectors yield
gen-0 values with null handles, empty member lists, zero
geometry arms, `same=True`, shell kind `SK_open` BY
CONVENTION; `tres_kind` on `Tok` yields `F_invalid` BY
DOCUMENTED CONVENTION (there is no ok-valued `FailKind` —
gate on `tres_ok`/`tres_show` first, mirroring C01
`cres_kind`). Zero arms (`curve_zero/surf_zero/trim_zero`)
are never validated, only classified.

## 3. Pipeline order (first match wins)

Construction protocol, in order:

1. `mk_*` validates VALUE shape only (finite points, geometry
   arm class, strict domain, nonempty member lists, degenerate
   pinch). All `mk_*` values carry gen 0 = UNISSUED.
2. `*_push` re-validates through the SAME `*_valid` predicates,
   stamps `stamp+1`, appends structurally, bumps the stamp.
   Push checks shape, never handle liveness: a push naming
   not-yet-pushed handles succeeds (`pos-psh-dangling` pins
   this — dangling is a `brep_checked` verdict, not a push
   verdict).
3. `*_issued` previews the handle the next push will stamp
   (`(len, stamp+1)`); the preview names the pushed slot iff
   no push intervenes (`pos-iss-names-slot`).
4. `*_resolve` looks up `(idx, gen)`: out-of-range or
   generation mismatch → `invalid-input` (stale handle);
   fuel-out → `resource-exhausted`.
5. `mk_brep` assembles a `Brep` from seven raw stores after
   value-, gen-, and nodup-checking EVERY slot under one
   shared per-walk fuel cap (full cap each, 21 walks);
   first undecided walk → `resource-exhausted`, else
   first invalid slot → `invalid-input`. Gen rules (D1–D3):
   nonzero, `≤ stamp`, unique within each store.
6. `brep_set_top` replaces the root totally (liveness of the
   new top is `brep_checked`, not here).
7. `brep_checked(b, profile, fuel)` (ops.bend, IMPLEMENTED)
   returns `resource-exhausted` before stage A and before
   stages B..L whenever `fuel < ix_bound(b)` (the longest
   store or member list, or one more than the longest NURBS
   knot list on an edge). That result is not a geometric
   pass. Otherwise it runs A. store re-validation via
   `mk_brep` (catches raw `Br`; an invalid store wins only
   when fuel covers `ix_bound`), then the conjunction
   of B..L in this order, each decided on the store index
   `Ty.Ix`: B. incidence (every member handle live);
   C. edge-use pairing (solid: twice opposite; open:
   once/twice, twice ⇒ opposite); D. loop closure (oriented
   vertex chain meets + closed) + no same-coedge dup
   (`hc_nodup_c`; repeated start vertices are NOT
   auto-invalid) + seam double-use (`loop_seam_ok`,
   opposite `fwd`) + singleton pole (`loop_pole_ok`) +
   trim meets in face `(u,v)` (geometric coincidence is
   stage J);
   E. exactly one `LK_outer` per face; F. hierarchy/profile
   (loop/face ownership both profiles; solid adds kind
   rules + shell/solid ownership; open skips solid/cavity/
   solid-list ownership); G. embedding (C03 interiors +
   vertex-on-curve for all curves + trim coincidence for
   plane/bezp + quadric vertex membership for
   sphere/cylinder/cone/torus — exact ordered-zero test of
   this F64 evaluation, overflow rejected, NOT
   real-arithmetic); H. vertex links (solid: every coedge
   in exactly one loop, each vertex fan a single
   `twin(prev())` orbit, a vertex whose orbit enters a cycle
   it is not on is invalid; open: vacuous); I. shell
   connectedness (each shell's face-edge graph connected:
   faces adjacent iff sharing one underlying edge,
   vertex-touching does not connect; both profiles);
   J. coincident distinct vertices (exact point equality,
   decided by sorting, both profiles); K. same-face straight-edge segment
   crossing (`orient3d` coplanarity + `seg_seg` proper in
   `xy`/`xz`/`yz`, candidates from a bounding-box sweep,
   fail-closed: predicate uncertainty rejects, NOT a proven
   crossing; both profiles);
   L. orientation, split: L-plane certifies per-face
   boundary winding vs the `same`-adjusted plane normal in
   the loop kind's sense (outer aligned, hole opposed) ONLY
   for straight-line planar boundaries; L-varying
   (sphere/cyl/cone/torus/bezier faces and curved plane
   boundaries) explicitly skips as not-determinable (never
   fails; certified-vs-skipped counts via
   `brep_orient_cert_c`/`brep_orient_skip_c`); every shared
   edge is re-traversed as an explicit redundant recheck
   (`same` never compared across faces). The recheck is not
   profile-parameterized: it runs the solid use-rule
   (`use_rule_ok` under `P_manifold_solid`) and is vacuous
   (`ok=True`) for edges that are not twice-opposite, hence
   harmless under the open profile; the per-loop verdict it
   rechecks (`loop_orient_c`) is itself profile-independent.
   Returns `Tok brep` on success, else `Terr`.

## 4. Profiles (explicitly named, validation implemented)

`Profile = P_manifold_solid | P_open_shell`
(`profile_tag` 0/1, `profile_show`
"manifold-solid"/"open-shell"). The profile is threaded
data, never a global: every `brep_checked` call takes it
explicitly.

Implemented rules:

- `P_manifold_solid`: every edge used exactly twice with
  opposite `fwd`; every loop closed with no same-coedge
  dup (seam double-use and singleton pole allowed);
  every face has
  exactly one `LK_outer`; loops/faces/shells/solids owned
  at most once (no loop shared across faces, no face
  shared across shells, no outer/cavity aliasing, no
  cavity dup, no shell reuse across solids, no
  solid/compound shell sharing, no solid dup in the
  compound root); no `SK_open`; outer `SK_outer`;
  cavities `SK_inner`; trims meet in `(u,v)`; vertices on
  curves; C03 interiors valid; plane/bezp trim
  coincidence; quadric vertex membership (exact
  ordered-zero test of this F64 evaluation, overflow
  rejected, NOT real-arithmetic); single-orbit vertex
  links (`ck_pinch` rejects disjoint links);
  face-edge-graph-connected shells (shared underlying
  edge = adjacent; vertex-touching does not connect); no
  coincident distinct vertices; no same-face
  straight-edge segment crossing (fail-closed: predicate
  uncertainty rejects, NOT a proven crossing);
  L-plane certified winding vs the `same`-adjusted plane
  normal (outer aligned, hole opposed) for straight-line
  planar boundaries; L-varying explicit skip (never fails)
  for quadric/bezier faces and curved boundaries, with
  certified-vs-skipped counts; an explicit redundant
  per-edge recheck (`same` never compared across faces).
  Cavity inside/disjoint classification and global outward
  shell orientation (inside/outside classification) are
  DEFERRED to C07/C11 (§12).
- `P_open_shell`: `SK_open` valid; edges used once (boundary)
  or twice-opposite; loops still closed; face-kind,
  loop/face ownership, trim, embedding, connectedness,
  coincidence, segment-crossing, and orientation rules
  hold per face / per shell; vertex links and solid/cavity
  kind and shell/solid-list ownership rules skipped
  (solids are only meaningful under `P_manifold_solid`).

Euler/counting identities are NECESSARY but explicitly NOT
SUFFICIENT (MASTER_PLAN: "Counting faces or checking Euler's
formula alone is not solid validation"): tet and cube both
satisfy V-E+F=2 yet differ, so no counting check appears in
the §3 order — the oracle (§11) documents the identities
while the validators check structure.

## 5. Handle, stamp, and walk arithmetic (formulas, orders)

- Stamp: `brep_empty` has stamp 0; each push stamps
  `stamp+1` and stores it. Gens are BREEP-global across
  stores (one counter), so `(store, idx, gen)` triples
  are unique per push. The tet probe (§11) pins
  stamp 32 after 32 pushes.
- `*_issued(b, fuel)` = `(len(store), stamp+1)`; fuel
  threads through `*_len`.
- `*_handle_of(xs, gen, fuel)` scans for the slot with
  stamp `gen`, returning `(idx, gen)`; unknown stamp or
  empty store → `invalid-input`.
- Walk codes pack `ok + 2*done` as one `Nat` (C03
  `code_pack` precedent; `ok` meaningful only when
  `done`): 3 = all-valid, 2 = walked-but-invalid,
  1 = vacuously-ok-but-unfinished, 0 = fuel-out.
  `okd_all` ands both bits. `mk_brep` checks `done`
  FIRST (→ `resource-exhausted`), then `ok`
  (→ `invalid-input`).
- Fuel consumption (exact): `*_len` spends 1 per cons;
  `*_all_c`/`*_gen_c` spend 1 per slot; `*_nodup_c` is
  done iff the list is no longer than the fuel, and finds
  duplicates by sorting (R0.2); `*_at` spends 1 per tail
  step — head (`idx 0`) is FREE (`pos-at-vx-headfree`);
  `*_handle_of` checks the head even at fuel 0
  (`pos-hof-vx-0head`) and spends 1 per further step.
  `*_snoc` is structural and takes NO fuel (C03 `dropk`
  precedent). `mk_brep` grants each of its 21 walks the
  FULL fuel cap (not divided). `brep_checked` decides a
  stage only at `fuel ≥ ix_bound(b)` (§16.2).

## 6. Identity (BN-7)

Identity is the generational `(index, generation)` pair
into an explicit `Brep` list — structural content, never
an address. The index alone is NOT identity: `resolve`
compares the stored slot stamp and reports a mismatch as
`invalid-input` (stale handle). Slot gens start at 1
(stamp 0 is the empty model); `mk_*` values carry gen 0
= unissued and the incoming gen is IGNORED at push.
`hv_null()` etc. (`(0n, 0u64)`) are documented projector
defaults carrying no liveness claim; `resolve` treats
them like any other pair. Handle equality (`hv_eq` and
siblings) compares index AND generation.

Honest scope: stores are append-only (no delete/update
op exists), so today a stale handle arises from a forged
or cross-brep handle, not from removal; the generation
check already rejects those (`neg-res-*-stale`). Removal
with generational invalidation is a later milestone.
Unreachable slots are retained history under the
append-only unreachable-history rule (§1): ownership
verdicts read member lists only, so unreferenced slots
never reject.

## 7. Failure arms (C00 statuses reused, no new taxonomy)

`invalid-input`: nonfinite vertex point; wrong geometry
arm; non-strict/nonfinite domain; degenerate edge across
two vertices; empty member list; out-of-range index;
generation mismatch (stale); unknown stamp in `handle_of`;
gen 0 slot (D2), stamp below a slot gen (D1), duplicate gen
within a store (D3); any `brep_checked` stage failure:
dangling handle, edge-use count/fwd violation (inverted,
nonmanifold-edge, open-boundary under solid), loop unclosed
or same-coedge dup or seam/pole violation
(duplicate-incidence only — general geometric
self-intersection is NOT checked, §12), face
without exactly one outer, `SK_open` under solid, outer
not `SK_outer`, cavity not `SK_inner`, loop/face/shell/solid
owned twice (loop shared across faces, face shared across
shells, outer/cavity aliasing, cavity dup, cross-solid
reuse, solid/compound sharing, solid dup in the compound
root), trim endpoints unmet, C03 interior invalid, vertex
off curve, plane/bezp trim coincidence missed, quadric
vertex off (exact ordered-zero test of this F64 evaluation;
overflow rejected), same-face segment pair
uncertain-or-crossing (fail-closed: uncertainty rejects,
NOT a proven crossing). `resource-exhausted`:
fuel ran out in any walk (`len/at/resolve/handle_of/issued/
all_c/gen_c/nodup_c` or any `brep_checked` stage walk), and
`brep_checked` returns it before those walks when
`fuel < ix_bound`.
No C04 op publishes `numerical-uncertainty`, `unsupported-op`
(except internal `surf_at` on non-plane/bezp, which is caught
and skipped, never published), `nonconvergence`, `cancelled`,
or `Incomplete`. Every failure publishes no value: projectors
yield documented defaults (§2), never NaN (BN-11).

## 8. Bounds

Fuel bounds are exact counts, not estimates: `len` needs
fuel ≥ store length; `at` needs fuel ≥ index (head free);
`handle_of` needs fuel ≥ slot position (head free at 0);
`resolve` costs its inner `at`; `issued` costs its inner
`len`; `mk_brep` needs fuel ≥ the LONGEST store (full cap
per each of 21 walks); `brep_checked` needs fuel ≥ the
max store length, the max member-list length, and one more than
the longest NURBS knot list on an edge (`ix_bound`).
Fuel below that bound is `resource-exhausted` and does not
run `mk_brep` or stages B..L. At or above the bound, each
stage walk and each sub-resolve gets that full cap
(fixtures use 12–20, and the digon control decides at 2).
`snoc`/`brep_set_top`/accessors/classifiers are
O(length)-structural or O(1) with no fuel parameter.
U64 stamp arithmetic wraps past 2^64 pushes (unstated
beyond that — no model approaches it; documented here so
it is not a hidden assumption).

## 9. Bend-native gates (BN-1..BN-12)

| Gate | Verdict | Evidence |
|------|---------|----------|
| BN-1 | PASS | Packet implementation is exactly `src/c04/types.bend` (296 defs) + `src/c04/ops.bend` (192 defs); both `bend … --check-only` → `All terms check.` No authoritative algorithm in another language. |
| BN-2 | PASS | `grep -rn "@unsafe" src/ laws/ tests/ \| grep -v ': *#'` empty (this session). |
| BN-3 | PASS | `grep -rn "F32" src/ laws/ tests/` empty; every scalar is the pinned as-bits F64 path. No display narrowing exists. |
| BN-4 | PASS | `grep -rni "foreign\|ffi_import\|@ffi" src/` empty; imports are `Base` + `../c00` + `../c01` + `../c03` only. Boundary list: none. |
| BN-5 | PASS | `grep -rni "occt\|freecad\|planegcs" src/` empty; `legacy/` clean + `verify_legacy.py` exit 0 (§11). No oracle harness in packet code. |
| BN-6 | PASS | No GPU claim in this packet — hence no GPU path to fall back from. All work is host structural/Nat/U64/F64-finite checks. |
| BN-7 | PASS | §6: generational `(idx, gen)` handles into explicit lists; stale → `invalid-input` (`neg-res-*-stale`, `vx/ed/…_res_stale` laws). No addresses; bare index never accepted as identity. |
| BN-8 | PASS | Every self-recursive def is structural in a list or `Nat`, or takes fuel. Store walks (`*_all_c`/`*_gen_c`/`*_len_go`/`*_at`/`*_handle_of_go`) spend one fuel per element; every `brep_checked` stage decides only when `fuel ≥ ix_bound` (§16.2) and otherwise reports code `0`, and `brep_checked` returns `resource-exhausted` before `mk_brep` and the stages. The `*_snoc` appends are structural (C03 `dropk` precedent). No unbounded recursion. (The pre-R0.2 per-walk accounting this row used to describe is superseded by §16.) |
| BN-9 | PASS | No batch op ships; a batch is SPECIFIED as the left fold of the single push, failing closed on the first `Terr` (§10). |
| BN-10 | PASS | No numerical shortcut: `brep_checked` evaluates C03 curves/surfaces at endpoints and compares exactly (no tolerance inflation); Euler identities documented-necessary, explicitly not validation (§4). Stage D duplicate-incidence (`hc_nodup_c` + seam + pole) is claimed as loop-handle hygiene only, never as general self-intersection; stage K uncertainty fails closed (uncertain-or-crossing, never a proven crossing). Vertex-link validation is IMPLEMENTED (stage H, `ck_pinch`); orientation is L-plane CERTIFIED with L-varying explicit skip and GLOBAL outwardness deferred (§12). Quadric trim 3D coincidence skip (with exact ordered-zero vertex membership), cavity inside/disjoint, curved-edge crossings, and cross-face/inter-loop penetration are LABELED deferrals (§12), not shortcuts. |
| BN-11 | PASS | Every `Terr` arm returns no value: projectors yield documented defaults (§2); `neg-*` assert kinds, `pos-dflt-*` assert defaults, `fails=0` on all lanes. |
| BN-12 | PASS | Single-SHA closeout at predecessor HEAD `6f70197d2dd1005670733f0206903408378f6427` + working-tree C04 bytes (§11, per-file sha256); `BEND_PIN jnadeau207-collab/bend@50ec219a6b5c52316f4d1622816cceedd437fa95`, `~/.bend/FORK` tag `numeric/2026-09-25`, fork-build `bend`, bun 1.4.2, pinned env; CI-unavailable record carried. No completion claim from any other SHA (§14 records the superseded interim SHAs). |

Gate count: 12 (BN-1 through BN-12).

## 10. Parallel decomposition notes (BN-9)

No batch code ships. The specified decomposition, when a
later milestone implements the left-fold batch: per-store
`all_c`/`len` walks are independent across the seven
stores (partition by store, one owned list per task);
`mk_brep`'s seven walks combine by `okd_all`, which is
associative/commutative over the `(ok,done)` bits, so a
segmented reduction assembles the verdict deterministically;
push sequences stay ordered (stamp counter is the single
serialization point — batch folds do not parallelize
across pushes). No shared mutable state, no atomics.

## 11. Verification

```sh
export PATH=$HOME/.bend/bin:$HOME/.bun/bin:$PATH; export BEND_NO_TELEMETRY=1
bend src/c04/types.bend --check-only   # ALL PROOFS CHECK
bend src/c04/ops.bend --check-only     # ALL PROOFS CHECK
bend laws/c04.bend --check-only        # ALL PROOFS CHECK (602 laws at R0.4).
bend tests/c04/check.bend --check-only # ALL PROOFS CHECK
bend tests/c04/neg.bend                # 128 PASS, selfcheck fails=0
bend tests/c04/pos.bend                # 283 PASS, selfcheck fails=0
# native lane: bend <suite> -o <bin> && <bin>; js lane: bend <suite> -o <js> && bun <js>
grep -rn '@unsafe' src/ laws/ tests/ | grep -v ': *#'  # empty
grep -rn 'F32' src/ laws/ tests/                        # empty
```

Closeout record — ONE coherent record for the closeout bytes
(this section supersedes every interim number in §14 history;
no 430/455 figure here is live).

Predecessor HEAD: `6f70197d2dd1005670733f0206903408378f6427`
(`c04.2: kind-aware orientation, hierarchy ownership, qualified
closeout`). The closeout bytes are the working tree on top of
that SHA: exactly the seven closeout paths
(`docs/c04-contract.md`, `MASTER_PLAN.md` (Rev 4, Amendment
A2), `src/c04/ops.bend`, `laws/c04.bend`,
`tests/c04/check.bend`, `tests/c04/neg.bend`,
`tests/c04/pos.bend`); c00–c03 and `src/c04/types.bend` are
byte-identical to HEAD (`git status` shows no other path).
No completion claim is made from any other SHA. Per-file
sha256 of the closeout bytes (this contract excluded as the
file being written):

```text
e6c621438fbbf3f93a1a99e3bfda1ed84137a006764c85104393a3287d7e90b5  MASTER_PLAN.md
80d8a686118112be5381aa4059e9c058a63b962f36eeb551a2d5164751b17f9b  src/c04/types.bend (unmodified vs HEAD)
51660ef6c57a15df2853059bf417caf32bfdea036261df9b34abc14d2af7aeec  src/c04/ops.bend
8bec62a46e4af079947387ac618e20707d74df7ba9043aec0ce4e097c05e45c5  laws/c04.bend
9101f8ca6fa6eb8cb2211dc53817ff9936ff0e171d8a003e9fa2e8b29517fa49  tests/c04/check.bend
f0cc19fa5f4036fa809243b6db624c89ad3a089766c68188a305577faed791ca  tests/c04/neg.bend
de0369caf3714f055857363c6adebd55bd68f7e8f6d32ad65cc5e1a4bf2392c4  tests/c04/pos.bend
```

Bend pin: `BEND_PIN
jnadeau207-collab/bend@50ec219a6b5c52316f4d1622816cceedd437fa95`
(`~/.bend/FORK` tag `numeric/2026-09-25`); fork-build `bend`,
bun 1.4.2, `PATH=$HOME/.bend/bin:$HOME/.bun/bin:$PATH`,
`BEND_NO_TELEMETRY=1`. CI-unavailable record carried (BN-12):
local qualification is the authoritative evidence.

Laws: 592 (`grep -c '^law ' laws/c04.bend` = 592 = 480 L0 +
112 L1; `grep -c '^law ck_'` = 32 = 10 accepts + 21 rejects +
fuel; L1 = 35 semantic + 33 correspondence/base + 44
microcase per the §13 taxonomy). C03 predecessor: 403 laws;
repo total 1118
(38+34+51+403+592). RECONCILIATION: C03 stood at 371 laws
through C04/C04.1; the C03.3 record (b5c18a6, G10 quadric
exact-membership) added 32 laws purely additively (371 →
403, neg stdout reproduced bit-for-bit). Every repo total
still quoting 371, and every C04 total quoting 430 or 455,
is superseded interim state — see §14.

Tests (observed this turn, all exit 0): `neg` 126/126 and
`pos` 282/282 on interpreted + native + js (408 checks × 3
lanes = 1224 executions, 0 fails), `selfcheck fails=0`, zero
FAIL lines in all six logs, `cmp` clean across lanes per
suite. stdout sha256: neg
`9bace48468977659517e3101c96e359bed4e741194306a54881cfcae65a3258b`
(x3 — REPRODUCES the c04.2 receipt hash byte-for-byte); pos
`84e3152a5577f98b86d229e58ca00987b32a9a649256d7da9d7e7e759a72d99c`
(x3 — new, +44 pins vs the c04.2 238). C04 total 408/lane;
prior packets carried 581/lane by byte-identity to the
qualified HEAD (c00 16+13, c01 69+44, c02 24+34, c03 191+190;
the older 549 figure predates the C03.3 +32 pos pins —
reconciled above); repo total 989 checks/lane. Fast static
gates re-run this turn: types/ops/check/neg/pos check-only
all `All terms check.` Contamination re-greps all zero
(BN-2/3/4/5); `legacy/` clean; `tools/verify_legacy.py` exit
0 (`"failures": []`).

Receipts: the predecessor receipts
(`docs/receipts/c04-2026-09-26.txt`, `c04.1-2026-09-26.txt`,
`c04.2-2026-09-26.txt`, `c03.3-2026-09-26.txt`) record their
own bytes and stand; THIS section is the closeout record for
the bytes above, and §15 is the exit receipt matrix
(Amendment A2 format). Pre-commit gate (explicit, not
silent): full `bend laws/c04.bend --check-only` closure over
the 592 laws (re-run this turn: `All terms check.`, exit 0,
1:14:51 wall; prior full run 1:07:29 at 466 laws).
Oracle provenance (stated exactly once, no gate attached):
C04/C04.1 carried 52/57 oracle checks on older bytes
(stages A–G only); C04.2 produced no fresh oracle script,
and neither does this closeout. That absence is not a
silent gap: per Amendment A2 Layer D, where no oracle
script exists the independent check is Layer-A
cross-checks — here the L1 fixture-independent law layer
(§13 taxonomy) over the new-stage semantics. No fresh
oracle script is claimed anywhere in this receipt. The 13
C04 probe checks read the carried C04 probe log (sound:
the probe exercises only types.bend, byte-identical since
C04.1).

Limitation set: §12 (single set — vertex-link IMPLEMENTED,
L-plane certified / L-varying skip / global outwardness
deferred, cavity inside/disjoint deferred, quadric trim
coincidence skipped-with-membership, curved-edge and
cross-face penetration deferred to C07, exact containment to
C11). No other limitation list is live.

Codegen note: the per-store len/at/resolve/handle_of/issued/
push law instances follow the mechanical pattern emitted by
the uncommitted `/tmp/gen_c04.py`; every law, however
produced, is machine-checked by `bend --check-only` like
hand-written ones.

## 12. Limitations (honest scope, not placeholders)

- Vertex links IMPLEMENTED (stage H, solid profile): each
  vertex fan must be a single `twin(prev())` orbit; two
  solids sharing one vertex (disjoint links) are diagnosed
  (`ck_pinch`). Edge-nonmanifold (0/1/3+ uses, same fwd)
  IS diagnosed (`ck_nonm`/`ck_inv`).
- Cavity inside/disjoint deferred: cavities are checked for
  `SK_inner` kind and single ownership only, not
  strict-inside or pairwise-disjoint bboxes. Kind-correct,
  singly-owned cavities accept (`ck_cav`).
- Orientation scope (L-plane certified, L-varying
  explicit skip; GLOBAL outwardness deferred): stage L
  certifies kind-aware per-face boundary winding (outer
  aligned, hole opposed) against the `same`-adjusted plane
  normal ONLY for straight-line planar boundaries
  (`loop_orient_class` 1/2; the check fires only on a
  strictly wrong-signed FINITE dot). Everything else skips
  as not-determinable (class 0, never fails): quadric and
  bezier faces (no one-sample-normal dot verdict),
  curved boundaries on planes (no chord-only claims),
  zero-area winding, unavailable normals, nonfinite dots,
  and orthogonal samples (dot == 0). Certified-vs-skipped
  counts (`brep_orient_cert_c`/`brep_orient_skip_c`) share
  the class core with the verdict, so counts and verdicts
  agree by construction. Bezier normals evaluate at the
  caller-carried query UV (`bezp_normal_at`); no fixed
  sample exists. Each shared edge is re-traversed as an
  explicit redundant recheck of the same per-loop verdict
  (`same` flags never compared across faces — each is
  relative to its own surface parametrization, so differing
  parametrizations and differing `same` flags are both
  valid). Known cleanup, non-blocking: the recheck runs
  the solid use-rule rather than the caller's profile (§4);
  parameterize it by profile when the recheck next changes.
  Global outward shell orientation still needs the
  C07 inside/outside classifier and stays deferred, as do
  curved-edge crossings and cross-face / inter-loop
  penetration (C07).
- Duplicate-incidence, not self-intersection (L0/L1
  closeout rework): stage D checks no same-coedge dup
  (`hc_nodup_c`) with seam double-use (`loop_seam_ok`,
  opposite `fwd`) and singleton pole (`loop_pole_ok`)
  allowed; repeated start vertices alone do NOT reject.
  Coincident DISTINCT vertices are a stage J verdict
  (`ck_coin`); same-face straight-edge crossings are a
  stage K verdict (`ck_xing`); general geometric
  self-intersection stays C07. The words
  "self-intersection" / "self-intersecting" are reserved
  for C07 per Amendment A1; C04 text says
  duplicate-incidence and segment-crossing.
- Trim 3D coincidence for sphere/cylinder/cone/torus skipped:
  C03 has no surface eval for those arms, so their trims pass
  on `(u,v)` meets + finiteness while every face vertex is
  checked for implicit quadric membership (`ck_offquad`):
  the exact ordered-zero test (`F64.is_eq(v, 0.0f64)`,
  signed zero counts as on) of this F64 evaluation with its
  documented left-fold association — malformed spec, non-unit
  axis, nonfinite input, or nonfinite value (true overflow)
  yields off and rejects; NOT a real-arithmetic test.
  plane/bezp coincidence IS checked (`ce_coinc_ok`).
  Labeled, not silent.
- Stage I connectedness means the face-edge graph: nodes are
  the shell's faces, adjacency is sharing one underlying
  edge — vertex-touching alone does NOT connect. A pinch
  (shared vertex, disjoint links) fails at H; disjoint cells
  in one shell fail at I (`ck_split`).
- Open-shell skips vertex links and solid/cavity kind and
  ownership (§4): `P_open_shell` is vacuous on stages H/F
  by design; solids are only meaningful under
  `P_manifold_solid`.
- Push admits dangling handles BY DESIGN (`pos-psh-dangling`);
  `brep_checked` stage B diagnoses them (`ck_dang`).
- Stores are append-only: no delete/update, no compaction;
  stale-by-removal cannot arise yet (§6).
- No batch ops (specified fold only, §10); no Euler/counting
  validators (deliberately absent — counting alone is not
  validation, §4).
- Exit coverage is dual: exit instances are pinned in laws
  (`ck_*`, 32 = 10 accepts + 21 rejects + fuel) AND asserted
  at runtime (13 `pos-ck-*` accepts + 32 `neg-ck-*` rejects
  over shared `check.bend` brep fixtures) on all three lanes
  (§11).
- U64 stamp wraps past 2^64 pushes (§8).

## 13. Explicit general laws (for `laws/c04.bend`)

Two layers, every law closed by the proof beneath it.

L0 implementation algebra (480 laws: sections A–M/L/F1 plus
the ops-fixture `brep_checked` instances — kept):

- Result core: `tres_ok`/`tres_show`/`tres_kind` over
  `Tok`/`Terr` (`tok_ok`, `tok_kind_doc`, `terr_not_ok`…).
- Projector defaults on `Terr`, GENERAL over every
  `FailKind` (`for k: T.FailKind`: `terr_f_zero`,
  `terr_n_zero`, `terr_b_false`, `terr_vx_zero`,
  `terr_ed/ce/lp/fa/sh/so_dflt`, `terr_cp_empty`,
  `terr_brep_empty`, `terr_hv/he/hc/hlp/hfa/hsh/hso_null`).
- Projector round-trips per arm (`tok_*_round`) and
  wrong-arm defaults (`mis_*`).
- Handle constructors, GENERAL over every index and
  generation (`for i: Nat, for g: U64`: `mk_hv/he/hc/
  hlp/hfa/hsh/hso_idx/gen`); null pins (`null_*`);
  structural equality (`eq_*`).
- One closed instance per pipeline arm: classifiers,
  validity, tags/shows, walk codes (`okd_*`, `allc_*`,
  `gen_*`, `nodup_*`), constructors (`mk_*`, `mk_brep_*`
  incl. per-store invalid + stamp/gen0/dup + fuel arms),
  per-entity store ops, shell-ownership walks (`hsh_nd_*`,
  `hsh_fo_*`, `so_shl_*`, `outer_kind_*`, `own_*`,
  `cpown_*`, `hlf_*`, `hfos_*`), and `brep_checked`
  instances (`ck_sphere/cyl/cav/open/pole/oriprop_ok/
  diffparam_ok/hole_ok/cyl_side/sphere_curved` accept;
  `ck_dang/inv/trimx/embx/nonm/selfx/open_solid/alias/
  outerkind/cavdup/reuse/cpshare/pinch/offquad/split/coin/
  xing/invface/split_open/hole_bad/hole_bad2` reject;
  `ck_fuel`), stage J/K/L unit pins (`coin_*`, `link_*`,
  `segx_*`, `xing_*`, `orient_*`, `recheck_*`, `cert_*`,
  `skip_*`, `bezp_*`, `qmem_*`).

L1 laws (112, `l1_*`, fixture-independent: quantified
binders and inline micro-stores only — no L0 fixture
referenced). Honest taxonomy: these are NOT 112
independent semantic specifications. They split into
three classes (35 + 33 + 44 = 112; every `l1_*` law
appears in exactly one class):

- L1-S semantic invariants (35, the Layer-A core):
  binder-quantified laws whose conclusion pins
  implementation output against independent terms
  (literals, constructors, boolean/Nat combinators,
  equality atoms `hv_eq`/`v2_eq`/`is_eq`; gate
  predicates allowed in hypotheses). The stage C rule
  and corollaries (`l1_use_solid/open_spec`,
  `l1_use_solid_non2/pair`, `l1_use_open_1/non12/pair`),
  the one-outer rule (`l1_outer_rule`), oriented-end
  atoms (`l1_ov_start/end`, `l1_closed_start/end`),
  trim-end atoms (`l1_trim_ts/tb_start/end`), closure as
  vertex-meet AND uv-meet (`l1_closure`),
  single-element nodup (`l1_nodup_single`), the pole rule
  (`l1_pole_nil`), open-shell link vacuity (`l1_link_open`,
  every brep and fuel), line/plane gate arms
  (`l1_line_ln/cc/bz/rq/nb/pl`,
  `l1_plane_pos/cy/co/sp/to/bp`), quantified
  no-false-reject (`l1_varying_nofail`: non-plane ⟹ never
  class 2, over every `GVal` arm and every store;
  `l1_plnorm_unsupported`), and the counter-codec atom
  (`l1_cnt_false`).
- L1-C correspondence/base laws (33, conceptually Layer B):
  agreements between two implementation-computed values
  (wrapper ≡ structure, cross-helper agreement) plus
  nil-walk and fuel-0 structural base cases. Named in
  full: `l1_use_go_nil`, `l1_es_use_nil`, `l1_ov_swap`,
  `l1_trim_o_start`, `l1_trim_o_end`, `l1_trim_swap`,
  `l1_nodup_nil`, `l1_seam_run_nil`, `l1_seam_go_nil`,
  `l1_mem_nil`, `l1_last_nil`, `l1_prev_nil`,
  `l1_hcprev_nil`, `l1_twin_nil`, `l1_orbit_tail`,
  `l1_vxlink_fuel0`, `l1_cov_nil`, `l1_start_nil`,
  `l1_have_nil`, `l1_share_nil`, `l1_hls_nil`,
  `l1_hlps_nil`, `l1_conn_nil`, `l1_conn_rule`,
  `l1_ekind_curve`, `l1_edge_line`, `l1_lines_nil`,
  `l1_lines_cons`, `l1_orient_c_spec`, `l1_oct_hls_nil`,
  `l1_oct_skip`, `l1_oct_fas_nil`, `l1_oct_bad`. In
  particular `l1_orient_c_spec` proves the wrapper agrees
  with `loop_orient_class` — it does not prove the class
  function itself implements geometric orientation; that
  direction is carried by `l1_varying_nofail` (S) plus
  the orientation microcases (M). Likewise `l1_edge_line`
  and `l1_ekind_curve` prove helper agreement, not
  independent line-ness.
- L1-M microcase witnesses (44, A2-permitted): closed (or
  flag-only-quantified: `l1_seam_use`, `l1_seam_accept`)
  evaluations on fixed micro-stores. Outer/no-open cases,
  closure misses, chain ok/gap, nodup dup/distinct (the
  latter: distinct handles pass regardless of shared
  vertices — repeated starts are not auto-invalid), seam
  accept/same/skip, pole single/two/clean, link
  prev/twin/step/nondegen cases, share/faces/conn cases
  (incl. vertex-only non-adjacency `l1_share_neg`,
  `l1_faces_split`, `l1_conn_split`), lines pos/neg,
  `l1_ekind_degen`, curved skip, counter round-trips.
  Valuable regression pins, not universal invariants.

592 laws, all closed (`bend laws/c04.bend --check-only`
exit 0). Laws cover `src/c04/types.bend` + `src/c04/ops.bend`.

## 14. Historical record (superseded interim states)

Nothing here is live; §11 is the single closeout. Each entry
records its own bytes (see its receipt) and the numbers this
file quoted before the rewrite:

- C04 (`d080562`, `docs/receipts/c04-2026-09-26.txt`):
  403 laws (13 `ck_*`), `pos` 185 + `neg` 102 = 287/lane,
  repo 897 laws / 836 checks. Vertex-link pinch, cavity
  inside/disjoint, and quadric trim coincidence carried as
  deferrals; exit sentence in pre-A1 wording
  ("self-intersecting ... diagnosed").
- C04.1 (`4cae05d`, `docs/receipts/c04.1-2026-09-26.txt`):
  430 laws (18 `ck_*`), `pos` 188 + `neg` 107 = 295/lane,
  repo 924 laws (38+34+51+371+430) / 844 checks (549 prior +
  295). Added solid outer-kind + shell ownership; corrected
  orientation/self-intersection claims to edge-use pairing
  and the repeated-start proxy; deferred face-orientation
  coherence. The pre-rewrite §11 paragraph quoting
  "`laws/c04.bend` (430 laws), `pos` 188/188, `neg` 107/107"
  at `d080562` is preserved here.
- C04.2 WIP (`b5c18a6`) → closeout (`6f70197`,
  `docs/receipts/c04.2-2026-09-26.txt`): 455 → 466 laws
  (26 → 30 `ck_*`), `pos` 213 → 238, `neg` 115 → 126.
  Kind-aware orientation (hole-open fix), propagation
  without cross-face `same` comparison, full hierarchy
  ownership, vertex-link / connectedness / quadric-
  membership / coincidence / segment-crossing / orientation
  stages. The pre-rewrite §11 line quoting "455 laws, `pos`
  213/213, `neg` 115/115" with repo totals
  38+34+51+371+455 / 549+328 is preserved here.
- C03.3 (`b5c18a6`, `docs/receipts/c03.3-2026-09-26.txt`):
  C03 371 → 403 laws (+32 G10 quadric exact-membership, purely
  additive) and `pos` 158 → 190 (+32). This is the
  reconciliation source for the 403-law C03 predecessor and
  the 581 prior checks in §11.
- L0/L1 completion (working tree on `6f70197`, this
  closeout): 592 laws (480 L0 + 112 L1 = 35 S + 33 C +
  44 M), 32 `ck_*`, `pos` 282 + `neg` 126 = 408/lane,
  repo 1118 laws / 989 checks. L-plane-certified /
  L-varying-skip orientation split with certified-vs-skipped
  counts, redundant per-edge recheck, and the §13 L1
  taxonomy (no fresh oracle script — Layer-A cross-checks
  per A2).

## 15. C04 exit receipt matrix (Amendment A2 format)

One row per exit requirement (MASTER_PLAN C04 exit as amended
by A1, plus the profile and robustness rows the contract
implements). Columns per Amendment A2: exit req, formal spec,
predicate, pos witness, neg witness, stage-isolated,
independent evidence, status.

Legend. Stage-isolated = the witness fixture passes every
stage except the named one (reject rows) or all stages
(accept rows), by fixture design over the §3 first-match-wins
order, corroborated by the cited unit pins. Independent
evidence tags: 3LANE = triple-lane byte-equality observed
this turn (§11); REG = neg stdout reproduces the c04.2 hash;
L1 = fixture-independent L1 laws (§13 taxonomy); ORC-C =
carried C04/C04.1 oracle (older bytes, stages A–G only).
Status PASS = law witness closed (§11 full closure) AND runtime
witness green on all three lanes this turn.

| Exit req | Formal spec | Predicate | Pos witness | Neg witness | Stage-isolated | Independent evidence | Status |
|----------|-------------|-----------|-------------|-------------|----------------|----------------------|--------|
| Sphere seam accepted | §4 solid; A1 exit | stage C twice-opposite + stage G qmem | `ck_sphere` + `pos-ck-sphere` | — (accept) | yes (`l1_seam_*`, `l1_use_*`) | 3LANE + L1 + REG | PASS |
| Cylinder seam accepted | §4 solid; A1 exit | stage C twice-opposite + stage G qmem | `ck_cyl` + `pos-ck-cyl`; `ck_cyl_side` + `pos-ck-cyl-side` | — (accept) | yes (`l1_seam_*`, `qmem_*`) | 3LANE + L1 | PASS |
| Cavity accepted | §4 solid; A1 exit | stage F `SK_inner` + single ownership | `ck_cav` + `pos-ck-cav` | — (accept) | yes (`own_*`, `cpown_*`) | 3LANE + ORC-C | PASS |
| Open-shell accepted | §4 open profile | stages C–E + open-skipped F/H | `ck_open` + `pos-ck-open`; `ck_hole_ok` + `pos-ck-hole-open` | — (accept) | yes (`l1_noopen_*`, `l1_link_open`) | 3LANE + L1 | PASS |
| Degenerate pole accepted | §1 pole rule | `edge_valid` pinch + stage C/D | `ck_pole` + `pos-ck-pole` | — (accept) | yes (`l1_pole_*`) | 3LANE + L1 | PASS |
| Dangling diagnosed | §4; A1 exit | stage B liveness | — | `ck_dang` + `neg-ck-dang` | yes (L0 resolve/`*_at` laws) | 3LANE + REG + ORC-C | PASS |
| Inverted / nonmanifold edge diagnosed | §4; A1 exit | stage C count+`fwd` | — | `ck_inv` + `neg-ck-inv`; `ck_nonm` + `neg-ck-nonm` | yes (`l1_use_solid_*`, `l1_seam_same`) | 3LANE + L1 + REG | PASS |
| Duplicate-incidence diagnosed | §4; A1 exit (C04 wording) | stage D `hc_nodup_c` + seam + pole | — | `ck_selfx` + `neg-ck-selfx` | yes (`l1_nodup_*`, `l1_closure*`) | 3LANE + L1 + REG | PASS |
| Trim / embedding diagnosed | §4; §6–§7 | stage D uv-meet + stage G C03/qmem | — | `ck_trimx`/`ck_embx`/`ck_offquad` + `neg-ck-trimx/embx/offquad` | yes (`l1_chain_*`, `l1_trim_*`, `qmem_*`) | 3LANE + L1 + REG | PASS |
| Kind / ownership diagnosed | §1 hierarchy; §4 solid | stage F kind + ownership walks | — | `ck_open_solid`/`ck_alias`/`ck_outerkind`/`ck_cavdup`/`ck_reuse`/`ck_cpshare` + 6 `neg-ck-*`; `neg-ck-alias-loop/face/solid` | yes (`own_*`, `cpown_*`, `hlf_*`, `hfos_*`) | 3LANE + REG | PASS |
| Vertex-link pinch diagnosed | §4; §12 (IMPLEMENTED) | stage H single `twin(prev())` orbit | `pos-ck-h-seam/h-pole/h-highval` (link accepts) | `ck_pinch` + `neg-ck-pinch`; `neg-ck-h-disc/wrongtwin/dupce/ce0/ce2/multi/rev` | yes (`l1_step`, `l1_mem/prev/twin_*`, `link_*`) | 3LANE + L1 | PASS |
| Disconnected shell diagnosed | §4; A1 exit | stage I face-edge graph | — | `ck_split` + `neg-ck-split`; `ck_split_open` + `neg-ck-split-open` | yes (`l1_conn*`, `l1_share_*`, `l1_faces_*`) | 3LANE + L1 | PASS |
| Coincident vertices diagnosed | §4; A1 exit | stage J exact equality by sort (R0.2) | — | `ck_coin` + `neg-ck-coin` | yes (`coin_*`) | 3LANE | PASS |
| Segment crossing diagnosed | §4; A1 exit (fail-closed) | stage K coplanar+proper-cross | — | `ck_xing` + `neg-ck-xing` | yes (`segx_*`, `xing_*`) | 3LANE | PASS |
| Face-orientation mismatch diagnosed | §4; §12 (L-plane certified) | stage L kind-aware winding + recheck | `ck_oriprop_ok` + `pos-ck-oriprop`; `ck_diffparam_ok` + `pos-ck-diffparam` | `ck_invface` + `neg-ck-invface`; `ck_hole_bad/bad2` + `neg-ck-hole-bad/bad2` | yes (`l1_orient_c_spec`, `l1_varying_nofail`, `recheck_*`, `cert/skip_*`) | 3LANE + L1 | PASS |
| Fuel exhaustion diagnosed | §5; §8 (BN-8) | `fuel < ix_bound` → `resource-exhausted` (R0.2, §16) | — | `ck_fuel` + `neg-ck-fuel`; `neg-*-0` pins | yes (`l1_vxlink_fuel0`, `l1_nodup_nil`, `coin_fuel`) | 3LANE + REG | PASS |

Matrix closure: all 32 `ck_*` laws appear above (10 accepts +
21 rejects + fuel); all 13 runtime `pos-ck-*` accepts and all
32 runtime `neg-ck-*` rejects appear above. Deferred-by-A1
items (global outwardness, cavity inside/disjoint, curved-edge
and cross-face penetration, exact containment) have no matrix
row by design — they are §12 limitations, not exit claims.

## 16. Amendment R0.2 — validation rebuilt on a store index

R0.2 (2026-10-01) replaced every list walk and pairwise scan in
`brep_checked` with an index and sorted passes. Construction (§3
steps 1–6) and `mk_brep` are unchanged, apart from duplicate-generation
detection, which now sorts. §16 supersedes earlier wording in §3, §5,
§8 (stages), §9 BN-8 and §10 where they differ.

### 16.1 Index

`Ty.Ix` (types.bend) holds the seven stores as balanced trees
(`B.tb_of`) with their lengths. `ix_vx`/`ix_ed`/`ix_ce`/`ix_lp`/
`ix_fa`/`ix_sh`/`ix_so` resolve a handle in `O(log n)` with exactly
the verdict of the list `*_resolve` (out of range or generation
mismatch → `invalid-input`). `ix_bound(b)` is the largest of the
longest store, the longest member list (loop coedges, face
loops, shell faces, solid shells), and `nk + 1` for every edge
whose curve is a NURBS with `nk` knots. Stage G evaluates NURBS
edges with the caller's fuel (`nurbs_checked`, `nurbs_eval`),
which decide only at `fuel ≥ nk + 1`. Before the 2026-10-04 audit
the knot term was missing, so a NURBS edge with more knots than
the longest store made stage G decide `invalid` at
`ix_bound ≤ fuel ≤ nk` (`ck_embed_nurbs_short` pins the fix:
`brep_embed_c` on a two-vertex, one-NURBS-edge store returns `0`,
not decided, at fuel 2; `ck_embed_nurbs_full` returns `3` at
fuel 9 = `ix_bound`).

### 16.2 Fuel

A stage decides iff `fuel ≥ ix_bound(b)`; otherwise its code is
`0` (not done). `brep_checked` reports `resource-exhausted`
before `mk_brep` and before B..L whenever `fuel < ix_bound(b)`.
That answer is not a geometric pass. Otherwise it runs A, then
the verdict of B..L as a short-circuit conjunction; A's invalid
verdict wins only at a covering fuel. This is the §8 statement
made exact: before R0.2 each walk spent its own fuel, so some
intermediate fuel values gave per-walk codes that §8 did not
promise. A later reading ran A before the `ix_bound` rejection,
so a store-invalid brep whose member list was the bound returned
`invalid-input` below `ix_bound`. `ck_fuel_ix` pins the rejection
in front: fuel 1 on that brep (`ix_bound` 2) is
`resource-exhausted`, while `mk_brep` at the same fuel is still
`invalid-input`, and fuel 2 still validates. Every earlier fuel
law and pin (`ck_fuel`, `neg-*-0`, `*_fuel`) holds unchanged, and
the old implementation's cost grew with the
fuel cap even on valid input: at fuel 10⁸ it overflowed the stack
after 305 s on an 8-entity prism.

### 16.3 Stages

| Stage | Before | R0.2 |
|---|---|---|
| Handle resolution | list walk per lookup, `O(n)` | tree, `O(log n)` |
| B incidence | resolve per member | index, `O(n log n)` |
| C edge uses | per-edge scan of all coedges, `O(E·C)` | sort coedge-use keys, one grouped pass, `O(C log C)` |
| D loop rules | membership and seam scans per coedge | chain via index; duplicates and seams by sort, `O(L log L)` per loop |
| E/F kind, ownership | pairwise `free_of` walks | key sort, `hks_distinct`, `O(n log n)` |
| G embedding | per-vertex resolve | index, `O(n log n)` |
| H vertex links | walk each orbit with fuel | `prev`/`twin` maps by sort; orbits by pointer jumping on the `twin(prev())` functional graph, `O(C log C)` |
| I connectivity | BFS with list membership | edge-incidence sort (`sh_adj`) + `B.components`, `O(n log n)` |
| J coincidence | all pairs | sort points, compare neighbours, `O(V log V)` |
| K crossing | all same-face edge pairs | bounding-box sweep for safe segments, exhaustive pairs only for risky ones (§16.4) |
| L orientation | per-loop walks, per-edge recheck scans | loop classes cached per store loop, recheck by sorted maps, `O(n log n)` |

One deliberate verdict change: a vertex whose `twin(prev())` orbit
enters a cycle it is not on was `resource-exhausted` at every fuel
(the walk never returned to its start); it is now `invalid-input`.
Law `l1_vxlink_rho` pins it; the pre-R0.2 code returns fuel-out on
the same fixture even at fuel 2000 (`tools/oracle/c04/disc_rho.bend`).
Laws `l1_orbit_tail`, `l1_orbit_cycle` and `l1_orbit_tail_step` pin
the orbit facts it rests on.

### 16.4 Stage K candidates

A segment is safe when every coordinate is 0 or has magnitude in
`[2^-300, 2^300]`; its bounding box then cannot hide a crossing
through rounding, and the sweep reports every pair whose boxes
overlap. Pairs involving a risky segment are checked exhaustively.
Each candidate pair still goes through the certified C02 predicates
(`orient3d` coplanarity, `seg_seg` proper), and since R0.2 those
decide every finite input of moderate magnitude, non-integral
collinear edges included (C02 §4).

### 16.5 Evidence

- Differential oracle (`tools/oracle/c04/diff_oracle.py`): the new
  `ops.bend` against the pre-R0.2 one (`tools/oracle/c04/ref/`) on
  prisms and holed plates under 17 mutation kinds, single and
  compound, comparing all 14 stage codes and `brep_checked`.
  Seeds 11/23/101: 1026 cases, 0 mismatches apart from the orbit
  change above (30 cases, each confirmed fuel-out on the old side at
  4× fuel).
- Planted-bug check (`tools/oracle/c04/plant.py`): each of the ten
  stage predicates forced to `True` in turn is detected (mismatches
  ≥ 1 for every one).
- Laws: 597 (5 new: `l1_seam_use_same`, `l1_orbit_cycle`,
  `l1_orbit_tail_step`, `l1_vxlink_rho`, `l1_conn_dup_face`); 94
  restated against the new internals on the same micro-fixtures, none
  weakened. Renamed with their subject: `l1_vorbit_fuel0` →
  `l1_orbit_tail`, `l1_lines_fuel0` → `l1_lines_cons`,
  `l1_bfs_nil`/`l1_bfs_done` → `l1_conn_nil`/`l1_conn_rule`,
  `l1_cert_nil`/`l1_skip_nil`/`l1_fcert_nil`/`l1_fskip_nil` →
  `l1_oct_hls_nil`/`l1_oct_skip`/`l1_oct_fas_nil`/`l1_oct_bad`,
  `l1_seam_free_nil` → `l1_seam_run_nil`.
- Suites: neg 126/126 and pos 282/282, byte-identical to the
  pre-R0.2 output on all three lanes.

### 16.6 Measured (native lane, idle machine, `tools/bench/bench.py`)

| Workload | Entities | Pre-R0.2 | R0.2 |
|---|---|---|---|
| Holed plate, open shell | 104 | 0.30 s | 0.05 s |
| Holed plate | 404 | 16.2 s | 0.19 s |
| Holed plate | 1,604 | — | 0.83 s |
| Holed plate | 6,404 | — | 5.0 s |
| Comb prism, solid | 80 | 24.1 s (fuel 1000) | 0.24 s |
| Comb prism | 400 | — | 1.25 s |
| Comb prism | 1,000 | — | 3.7 s |

Times include building the brep with `push` (§3 step 2), which is
`O(n)` per push because stores are lists: construction measured
1.0 s of the 1,000-entity prism's 3.7 s and 2.2 s of the 6,404-entity
plate's 5.0 s. A tree-backed builder belongs with the
first operation that creates breps in bulk (C06).

