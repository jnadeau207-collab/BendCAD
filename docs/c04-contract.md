# C04 packet contract — boundary-representation topology

Scope: what this packet DELIVERS is representation + validation —
entity types, the edge/coedge split, value-level validation,
generational stores with a push/issued/resolve protocol — in
`src/c04/types.bend`, plus the profile validators (`brep_checked`:
incidence, edge-use pairing, closed boundaries, trimming
consistency, shell ownership, geometric embedding; vertex-link
pinch and face-orientation coherence deferred, §12) in
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
pinned in `laws/c04.bend` (`ck_*`) and asserted at runtime by
the suite appends (`pos_g10`: 5 accepts; `neg_g7` + `neg_g8` +
`neg_g9`: 21 rejects, incl. the C04.1 outer-kind/ownership and
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
   runs stages in order, earlier invalid winning over later
   exhaustion: A. store re-validation via `mk_brep` (catches
   raw `Br`); B. incidence (every member handle live);
   C. edge-use pairing (solid: twice opposite; open:
   once/twice, twice ⇒ opposite); D. loop closure (oriented
   vertex chain meets + closed) + no repeated starts (a
   narrow duplicate-handle proxy within each loop; geometric
   coincidence is stage J) + trim meets in face `(u,v)`;
   E. exactly one `LK_outer` per face; F. profile (solid: no
   `SK_open`, outer `SK_outer`, cavities `SK_inner`, every
   shell owned at most once; open: vacuous); G. embedding
   (C03 interiors + vertex-on-curve for all curves + trim
   coincidence for plane/bezp + quadric vertex membership
   for sphere/cylinder/cone/torus); H. vertex links (solid:
   every coedge in exactly one loop, each vertex fan a
   single `twin(prev())` orbit; open: vacuous); I. shell
   connectedness (faces of each shell edge-connected, both
   profiles); J. coincident distinct vertices (exact `pteq3`
   pairwise, both profiles); K. same-face straight-edge
   segment crossing (`orient3d` coplanarity + `seg_seg`
   proper in `xy`/`xz`/`yz`, both profiles); L. orientation
   (per-face winding vs `same`-adjusted C03 normal where
   determinable + shared-edge `same` propagation, both
   profiles). Returns `Tok brep` on success, else `Terr`.

## 4. Profiles (explicitly named, validation implemented)

`Profile = P_manifold_solid | P_open_shell`
(`profile_tag` 0/1, `profile_show`
"manifold-solid"/"open-shell"). The profile is threaded
data, never a global: every `brep_checked` call takes it
explicitly.

Implemented rules:

- `P_manifold_solid`: every edge used exactly twice with
  opposite `fwd`; every loop closed with distinct starts
  (duplicate-handle proxy within the loop); every face has
  exactly one `LK_outer`; no `SK_open`; outer `SK_outer`;
  cavities `SK_inner`; every shell owned at most once
  (no outer/cavity aliasing, no cavity dup, no reuse
  across solids, no solid/compound sharing); trims meet
  in `(u,v)`; vertices on curves; C03 interiors valid;
  plane/bezp trim coincidence; quadric vertex membership;
  single-orbit vertex links (`ck_pinch` rejects disjoint
  links); edge-connected shells; no coincident distinct
  vertices; no same-face straight-edge segment crossing;
  per-face winding vs `same`-adjusted normal agreement
  where determinable; shared-edge `same` propagation.
  Cavity inside/disjoint classification and global outward
  shell orientation (inside/outside classification) are
  DEFERRED to C07/C11 (§12).
- `P_open_shell`: `SK_open` valid; edges used once (boundary)
  or twice-opposite; loops still closed; face-kind, trim,
  embedding, connectedness, coincidence, segment-crossing,
  and orientation rules hold per face / per shell; vertex
  links and solid/cavity kind and ownership rules skipped
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
  `*_all_c`/`*_gen_c` spend 1 per slot; `*_nodup_c` spends
  1 per slot for the outer walk, each inner `*_free_of`
  scan getting the full remaining fuel (so fuel ≥ length
  still suffices); `*_at` spends 1 per tail step — head
  (`idx 0`) is FREE (`pos-at-vx-headfree`); `*_handle_of`
  checks the head even at fuel 0 (`pos-hof-vx-0head`) and
  spends 1 per further step. `*_snoc` is structural and
  takes NO fuel (C03 `dropk` precedent). `mk_brep` grants
  each of its 21 walks the FULL fuel cap (not divided).
  `brep_checked` grants each stage walk, each sub-resolve,
  and each ownership sub-walk (`hsh_nodup_c`,
  `hsh_free_of_sos`) the FULL cap; fuel ≥ max
  store/member-list length suffices.

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

## 7. Failure arms (C00 statuses reused, no new taxonomy)

`invalid-input`: nonfinite vertex point; wrong geometry
arm; non-strict/nonfinite domain; degenerate edge across
two vertices; empty member list; out-of-range index;
generation mismatch (stale); unknown stamp in `handle_of`;
gen 0 slot (D2), stamp below a slot gen (D1), duplicate gen
within a store (D3); any `brep_checked` stage failure:
dangling handle, edge-use count/fwd violation (inverted,
nonmanifold-edge, open-boundary under solid), loop unclosed
or repeated starts (the duplicate-vertex proxy — general
geometric self-intersection is NOT checked, §12), face
without exactly one outer, `SK_open` under solid, outer
not `SK_outer`, cavity not `SK_inner`, shell owned twice
(outer/cavity aliasing, cavity dup, cross-solid reuse,
solid/compound sharing), trim endpoints unmet, C03
interior invalid, vertex off curve, plane/bezp trim
coincidence missed. `resource-exhausted`:
fuel ran out in any walk (`len/at/resolve/handle_of/issued/
all_c/gen_c/nodup_c` or any `brep_checked` stage walk).
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
max store length and max member-list length (full cap per
stage walk and per sub-resolve; fixtures use 12–20).
`snoc`/`brep_set_top`/accessors/classifiers are
O(length)-structural or O(1) with no fuel parameter.
U64 stamp arithmetic wraps past 2^64 pushes (unstated
beyond that — no model approaches it; documented here so
it is not a hidden assumption).

## 9. Bend-native gates (BN-1..BN-12)

| Gate | Verdict | Evidence |
|------|---------|----------|
| BN-1 | PASS | Packet implementation is exactly `src/c04/types.bend` (294 defs) + `src/c04/ops.bend` (71 defs); both `bend … --check-only` → `All terms check.` No authoritative algorithm in another language. |
| BN-2 | PASS | `grep -rn "@unsafe" src/ laws/ tests/ \| grep -v ': *#'` empty (this session). |
| BN-3 | PASS | `grep -rn "F32" src/ laws/ tests/` empty; every scalar is the pinned as-bits F64 path. No display narrowing exists. |
| BN-4 | PASS | `grep -rni "foreign\|ffi_import\|@ffi" src/` empty; imports are `Base` + `../c00` + `../c01` + `../c03` only. Boundary list: none. |
| BN-5 | PASS | `grep -rni "occt\|freecad\|planegcs" src/` empty; `legacy/` clean + `verify_legacy.py` exit 0 (§11). No oracle harness in packet code. |
| BN-6 | PASS | No GPU claim in this packet — hence no GPU path to fall back from. All work is host structural/Nat/U64/F64-finite checks. |
| BN-7 | PASS | §6: generational `(idx, gen)` handles into explicit lists; stale → `invalid-input` (`neg-res-*-stale`, `vx/ed/…_res_stale` laws). No addresses; bare index never accepted as identity. |
| BN-8 | PASS | Machine audit (§11): 90 self-recursive defs = 83 fuel-capped walks (types: `*_all_c`/`*_gen_c`/`*_nodup_c`/`*_free_of`/`*_len_go`/`*_at`/`*_handle_of_go`; ops: incidence/usage/loop/face/profile/ownership/embed walks; exhaustion → `resource-exhausted`, `neg-*-0` + `ck_fuel` pins) + 7 structural `*_snoc` (C03 `dropk` precedent, no fuel by design). No unbounded recursion. |
| BN-9 | PASS | No batch op ships; a batch is SPECIFIED as the left fold of the single push, failing closed on the first `Terr` (§10). |
| BN-10 | PASS | No numerical shortcut: `brep_checked` evaluates C03 curves/surfaces at endpoints and compares exactly (no tolerance inflation); Euler identities documented-necessary, explicitly not validation (§4). The repeated-start proxy is claimed as a proxy only, never as general self-intersection; quadric trim coincidence skip, vertex-link pinch, cavity inside/disjoint, and face-orientation coherence are LABELED deferrals (§12), not shortcuts. |
| BN-11 | PASS | Every `Terr` arm returns no value: projectors yield documented defaults (§2); `neg-*` assert kinds, `pos-dflt-*` assert defaults, `fails=0` on all lanes. |
| BN-12 | PASS | C04.1 receipt records BendCAD HEAD `d080562`, per-file sha256, `BEND_PIN jnadeau207-collab/bend@50ec219a6b5c52316f4d1622816cceedd437fa95`, `~/.bend/FORK` tag `numeric/2026-09-25`, fork-build `bend`, bun 1.4.2, pinned env; CI-unavailable record carried. |

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
bend src/c04/types.bend --check-only   # All terms check.
bend src/c04/ops.bend --check-only     # All terms check.
bend laws/c04.bend --check-only        # All terms check (455 laws).
bend tests/c04/check.bend --check-only # All terms check.
bend tests/c04/neg.bend                # 115 PASS, selfcheck fails=0
bend tests/c04/pos.bend                # 213 PASS, selfcheck fails=0
# native lane: bend <suite> -o <bin> && <bin>; js lane: bend <suite> -o <js> && bun <js>
grep -rn '@unsafe' src/ laws/ tests/ | grep -v ': *#'  # empty
grep -rn 'F32' src/ laws/ tests/                        # empty
```

Close-out record (final bytes, C04.1): `src/c04/types.bend`
(one comment line reworded, no def changed),
`src/c04/ops.bend`, `laws/c04.bend` (430 laws),
`tests/c04/check.bend`, both
suites all check-only green; `pos` 188/188, `neg` 107/107,
`fails=0`, byte-identical `cmp` clean on interpreted +
native + js. Prior packets (c00–c03) untouched
(byte-identical to `d080562`) and re-run green on the
interpreted lane with counts reproducing the C03.2 receipt
sets. Repo totals:
924 laws (38+34+51+371+430), 844 checks/lane (549 prior +
295 C04). C04.2/A1 completion (this change): `laws/c04.bend`
455 laws, `pos` 213/213, `neg` 115/115, `fails=0` on the
interpreted lane; repo totals 949 laws
(38+34+51+371+455), 877 checks/lane (549 prior + 328 C04).
Oracle 57/57 (§4 of the C04.1 receipt: the C04
52 plus the 5 new ownership exit lines; the 13 probe
checks read the carried C04 probe log since types.bend is
behavior-identical). Codegen note: the per-store
len/at/resolve/handle_of/issued/push
law instances follow the mechanical pattern emitted by the
uncommitted `/tmp/gen_c04.py`; every law, however produced,
is machine-checked by `bend --check-only` like hand-written
ones.

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
- Orientation scope (C04.2/A1: self-consistency +
  propagation implemented; GLOBAL outwardness deferred):
  stage L checks per-face boundary winding against the
  `same`-adjusted C03 surface normal wherever determinable
  (plane/bezp/quadric normals; zero-area winding or an
  unavailable normal skips) plus shared-edge `same`
  propagation across distinct faces. Global outward shell
  orientation still needs the C07 inside/outside classifier
  and stays deferred, as do curved-edge crossings and
  cross-face / inter-loop penetration (C07).
- Repeated-start proxy, not self-intersection (C04.1
  correction, kept): stage D checks that loop start vertices
  are distinct handles. Coincident DISTINCT vertices are a
  stage J verdict (`ck_coin`); same-face straight-edge
  crossings are a stage K verdict (`ck_xing`); general
  geometric self-intersection stays C07. The words
  "self-intersection" / "self-intersecting" are reserved
  for C07 per Amendment A1; C04 text says repeated-vertex /
  duplicate-incidence and segment-crossing.
- Trim 3D coincidence for sphere/cylinder/cone/torus skipped:
  C03 has no surface eval for those arms, so their trims pass
  on `(u,v)` meets + finiteness while every face vertex is
  checked for implicit quadric membership (`ck_offquad`);
  plane/bezp coincidence IS checked (`ce_coinc_ok`).
  Labeled, not silent.
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
  (`ck_*`, 26) AND asserted at runtime (`pos_g10` 5 accepts
  + `neg_g7`/`neg_g8`/`neg_g9` 21 rejects over shared
  `check.bend` brep fixtures) on all three lanes (§11).
- U64 stamp wraps past 2^64 pushes (§8).

## 13. Explicit general laws (for `laws/c04.bend`)

General (quantified) laws, closed by the proof beneath each:

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
  instances (`ck_sphere/cyl/cav/open/pole` accept;
  `ck_dang/inv/trimx/embx/nonm/selfx/open_solid/alias/
  outerkind/cavdup/reuse/cpshare/pinch/offquad/split/coin/
  xing/invface/oriprop/split_open` reject; `ck_fuel`),
  stage J/K/L unit pins (`coin_*`, `link_*`, `segx_*`,
  `xing_*`, `orient_*`, `prop_*`, `qmem_*`).

455 laws, all closed (`bend laws/c04.bend --check-only`
exit 0). Laws cover `src/c04/types.bend` + `src/c04/ops.bend`.
