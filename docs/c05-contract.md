# C05 contract — planar arrangements and sketch solving

Scope: MASTER_PLAN §C05. Two engines, one packet:

- `src/c05/exact.bend` — adaptive-exact orientation predicates
  over the pinned F64 path. The Shewchuk expansions it calls
  live in `src/base/ex.bend`.
- `src/c05/arrange.bend` — planar arrangement of line segments
  into regions with nested loops, holes, disconnected islands,
  dangling-edge reporting and deterministic boundary identity.
- `src/c05/solve.bend` — Bend-native 2D geometric constraint
  solver: analytic residuals and Jacobians, damped Gauss–Newton
  (Levenberg–Marquardt) on a backward-stable factorization,
  rank diagnosis, explicit degrees of freedom, named redundancy,
  certified conflicts and budget-honest nonconvergence. The
  constraint graph is split into independent clusters that are
  solved in parallel.
- `src/base/par.bend` — the shared parallel primitives: balanced
  read-mostly trees (`Tb`), a fork-join merge sort with an
  uncertainty-carrying comparator, parallel maps, and
  Shiloach–Vishkin connected components. R0.2 moved this file
  out of `src/c05/par.bend`.
- `src/c05/sqr.bend` — sparse orthogonal factorization: Givens
  row-merge into an upper-triangular sparse `R`, rank-revealing
  column deletion, and a nested-dissection multifrontal
  least-squares solve.

Amendment R0 (§12) rebuilt all three engines for speed and
parallelism. Behavior stayed byte-identical where the old engines
were correct; §12 lists every observable change.

Code carries no comments; this document is the explanation.
PlaneGCS (vendored in `legacy/`) was mined for vocabulary only
and is not called, linked or ported (BN-5).

## 1. Exact predicates (`exact.bend`)

An `Ex{ok, cs}` is a nonoverlapping expansion: `cs` sums exactly
to the represented real when `ok`. Construction:

- `two_sum` (Knuth) and `two_prod` (`F64.fma`) are exact error-free
  transforms; `grow_go` is Shewchuk's GROW-EXPANSION with zero
  elimination.
- `ex_scale` multiplies an expansion by a double component-wise;
  every partial product must pass `prod_exact`: `a·b` is exact in
  binary64 iff either operand is zero, or the product is finite and
  `lsb_b(a) + lsb_b(b) ≥ 1076`, where `lsb_b` is the biased
  exponent of the lowest set significand bit (a product whose
  lowest bit falls below 2^-1074 would round).
- Any nonfinite component, overflow, or inexact product clears
  `ok`. `ex_sign` returns `Su` (uncertain) whenever `ok` is false,
  and otherwise the sign of the last (largest) nonzero component.

`orient2(a, b, c)` is `(b−a)×(c−a)` built from exact differences
(`ex_dif`) and exact products. It never returns a wrong sign.
It returns `Su` only when the exact value is not representable
within the expansion scheme: overflow, subnormal underflow, or
nonfinite input.

`orient2s` is the filtered form the arrangement uses. `dd_sign`
evaluates `(a−b)(c−d) ± (e−f)(g−h)` in floating point and returns
its sign when `|value| > 2·errA·sum`, `sum ≥ 2^-900` and both are
finite, with Shewchuk's `errA` (`F64{4375247037990436868}`). Any
other case falls back to the exact expansion path, so `orient2s`
never returns a wrong sign either (ex_oracle: 0 wrong over 2,000
cases; 213 cases the exact path left uncertain are decided by the
filter, and none disagrees with `Fraction`).

## 2. Arrangement (`arrange.bend`)

### 2.1 Types

- `Seg{id: U64, ax, ay, bx, by: F64}` — a closed segment with a
  caller identity.
- `VKey` — vertex identity: `VK_end{seg, end}` (an input endpoint)
  or `VK_x{lo, hi}` (the proper crossing of segments `lo < hi`).
- `RPt{x, y, w: Ex}` — a rational point `(x/w, y/w)`. Endpoints
  have `w = 1`; crossings carry exact numerators and denominators
  from `rp_cross`.
- `OHE{from, to: VKey, srcs: List<U64>}` — an output boundary
  edge with its source-segment lineage (sorted, deduplicated).
- `Region{outer: List<OHE>, holes: List<List<OHE>>}` — exactly one
  counter-clockwise outer loop plus clockwise hole loops.
- `ARes = A_ok{nv, ne, nc, regions, dangling} | A_err{kind}`.
- `region_key(r)` — the durable region key ported from legacy
  CAP-038 (`geometry.cpp:1805-1866`): the sorted, deduplicated
  source ids bounding the region (outer loop plus holes). A consumer
  holding a key fails closed when the bounding entities change.

### 2.2 Pipeline (first match wins)

1. **Validation** (`segs_ok`): every coordinate finite, no
   zero-length segment, no duplicate id → `A_err{invalid}`.
2. **Budget**: `len(segs) > fuel` → `A_err{exhausted}`. Every later
   loop is structurally bounded by the input.
3. **Candidate pairs** (`cands`): segments sorted by `xmin`; each
   scans forward while the next `xmin ≤` its `xmax` and keeps pairs
   whose y-intervals overlap (sort-and-sweep broad phase).
4. **Stops** (`pr_stops`, a parallel map over candidate pairs):
   endpoints lying on the other segment (`orient2s = 0` and exact
   betweenness) and proper crossings as rational points, plus every
   segment's own endpoints.
5. **Vertices** (`vgroup`): all stops sorted exactly and
   lexicographically; equal points form one vertex keeping the
   minimum key (`VK_end < VK_x`, then lexicographic ids).
6. **Edges** (`ep_go`, `ie_go`): each segment's stops, sorted along
   it, give consecutive edges. Coincident edges (collinear overlaps)
   merge, unioning their `srcs`.
7. **Half-edges** (`hos`, `gr_of`): per vertex, outgoing half-edges
   sorted counter-clockwise by exact direction comparison (upper
   half plane first, then `orient2` on the directions). `next(h)` is
   the clockwise-previous half-edge at `head(h)`, counted from
   `twin(h)`.
8. **Faces** (`jump_min`): the `next` orbits, labeled by their
   minimum half-edge with pointer jumping (log rounds).
9. **Components** (`P.components`): Shiloach–Vishkin hooking and
   shortcutting. A component's outer cycle is the cycle through the
   last upper out-half-edge at its minimum vertex.
10. **Nesting** (slab index + pointer chaining):
    - edges are bucketed into x-slabs with conservative float bounds
      (rational crossings widened by a relative and absolute margin);
    - each component's minimum vertex casts a vertical ray at
      `x + ε` (ε symbolic, exact comparisons only) and finds the
      lowest edge above it in its slab;
    - if that edge's face is another component's outer cycle, the
      component points at that component; pointer jumping resolves
      the chains in log rounds;
    - a chain that does not terminate (a cycle through outer faces)
      falls back to the exclusion search: exclude the component
      named and retry, with fuel `#components + 1`;
    - no edge above means the unbounded face.
11. **Regions** (`nk_of`, `starts`, `lp_of`, `regions_of`): every
    bounded cycle, plus the outer cycles of the components located in
    it, as holes.
    - Half-edges whose twin lies in the same region are antennas
      and are removed; the survivors are relinked (next kept
      half-edge clockwise at the head, by pointer jumping).
    - Orientation is certified per loop by the exact turn at its
      minimum-origin vertex: exactly one CCW outer; the others are
      CW holes.
    - Loops start at their minimum vertex; holes and regions are
      sorted by origin-index lists.
12. **Dangling edges** (`dang_of`): edges whose two sides lie in the
    same face (antennas, bridges, isolated segments), in canonical
    (u, v) edge order.

Every sort carries an ok flag: an uncertain comparison (`Su`) in
any stage, or any internal lookup failing, publishes nothing and
yields `A_err{uncertain}`.

### 2.3 Identity (BN-7)

Output identity is lineage, never position:

- vertices are `VKey`s derived from caller segment ids;
- edges carry `srcs`;
- loop starting vertex and region order are canonical (sorted by
  exact geometry).

The result is invariant under input permutation (`pos-arr-perm`).
`region_key` gives a position-free handle on a region
(`pos-arr-region-keys`).
No array ordinal or address leaves the engine.

## 3. Constraint solver (`solve.bend`)

### 3.1 Model

- Parameters: a flat `List<F64>` with a parallel `free: List<Bool>`.
  Grounding is `free = False`: grounded columns are masked, so they
  never move and never count as degrees of freedom.
- A point is `Pt{x, y}`, a pair of parameter indices. A circle is a
  center `Pt` plus a radius index.
- Arcs are circles with `K_on_circ` endpoints. The solver needs no
  trigonometry: angles enter as a `(cos, sin)` unit pair, validated
  to within 2^-40.

Constraints, each carrying a caller id (`U64`) and giving one row
unless noted:

| Kind | Residual | Unit |
|------|----------|------|
| `K_coinc{p,q}` | `p−q` (2 rows) | lin |
| `K_horiz{a,b}` / `K_vert{a,b}` | `(b−a).y/‖b−a‖` / `(b−a).x/‖b−a‖` (sine of the angle to the axis) | ang |
| `K_dist{p,q,d}` (`d>0`) | `‖p−q‖ − d` | lin |
| `K_radius{r,v}` (`v>0`) / `K_fix{i,v}` | `p[i] − v` | lin |
| `K_angle{a,b,c,d,cs,sn}` | directed: with `s = sin` and `c = cos` of the error between `R(θ)(b−a)` and `d−c`, the residual is `s` when `c ≥ 0`, else `sign(s)·(2 − |s|)` | ang |
| `K_par` / `K_perp` | `s` only (undirected: lines have no orientation), `θ = 0` / `90°` | ang |
| `K_tan_lc{a,b,o,r}` | `s·sd(o; ab) − r`, where `s` is the side of `o` in the initial configuration | lin |
| `K_tan_cc{o1,r1,o2,r2}` | external `‖o1o2‖ − r1 − r2`; internal `‖o1o2‖ − s(r1 − r2)` (internal iff initially `‖o1o2‖ < max(r1,r2)`, with `s = sign(r1₀ − r2₀)`) | lin |
| `K_on_circ{p,o,r}` | `‖p−o‖ − r` | lin |
| `K_on_line{p,a,b}` | `sd(p; ab)` (signed distance) | lin |
| `K_midpoint{m,a,b}` | `2m − a − b` (2 rows) | lin |
| `K_equal{a,b,c,d}` | `‖b−a‖ − ‖d−c‖` | lin |
| `K_hdist` / `K_vdist{p,q,d}` | `q.x−p.x−d` / `q.y−p.y−d` | lin |
| `K_same{i,j}` | `p[j] − p[i]` (equal radii, etc.) | lin |

Parallel, perpendicular and angle share one rotated-cross formula,
so its gradient is written once. The directed branch only flips the
gradient's sign. Every gradient is analytic. The
independent oracle checks it against central finite differences
(§6).

### 3.2 Pipeline (first match wins)

1. **Validation** (`cns_valid` + `solve`) → `Sv_err{invalid}`,
   before any numeric work. Rejected:
   - out-of-range indices;
   - a point related to itself (coincidence, h/v, distance,
     on-circle, midpoint base, tangency centers);
   - a line related to itself in either orientation;
   - `d ≤ 0`, `v ≤ 0`, a nonfinite value, or a non-unit angle pair;
   - duplicate constraint ids (sort, then adjacent comparison);
   - a `free` length that differs from the parameter count;
   - a nonfinite parameter;
   - an inadmissible `lin`/`ang` tolerance.
2. **Clusters**: a graph with one node per parameter and one per
   constraint, and an edge from each constraint to every free
   parameter it reads. `P.components` labels it; constraints are
   grouped by label, in constraint order within each group. Fixed
   parameters join nothing, so two sketches sharing only grounded
   geometry are independent. A component labeling that fails to
   converge → `Sv_err{nonconverged}`.
3. **Per cluster, in parallel** (`P.pmap`), on the cluster's
   parameters renumbered by binary search:
   1. **Initial evaluation**: any nonfinite residual or gradient, or
      a nonpositive radius → `Sv_err{invalid}`.
   2. **Iteration** (`lm`), bounded by `fuel`:
      - Rows are weighted by `1/tol.lin` or `1/tol.ang`; grounded
        columns are masked; rows are sparse and deduplicated.
      - Each step solves `min ‖J̃δ + r̃‖² + λ‖δ‖²` through the
        augmented system `[J̃; √λ I]`. Columns are ordered once per
        cluster by nested dissection (BFS level separators from a
        pseudo-peripheral vertex, leaves below 17 columns). The rows
        are factored by Givens row-merge on the separator tree:
        independent subtrees factor in parallel, each front
        triangularizes its contribution rows, and the separator
        front merges them (`fact`). Back-substitution gives δ.
        Every column has full rank because of its own `√λ` row.
      - Acceptance and the damping update are Nielsen's, unchanged
        in the trial test: finite, every radius positive (`rad_ok`),
        a lower cost, and positive predicted reduction.
        `λ₀ = 2^-10 · max(‖col‖²_max, 1)`, clamp `[2^-30 λ₀, 2^60 λ₀]`.
        `‖col‖²_max` is `col_max`: the largest sum of squared
        entries in one column. The `1` floors that sum before the
        scale. A Jacobian whose columns are all shorter than 1,
        including a zero column, would otherwise make `λ₀` zero
        and drop the `√λ` row that keeps every column full rank.
        Iteration starts at `2^-30 λ₀`, not at `λ₀`. A rejected
        step still raises `λ` by the same factor. An accepted
        update uses Nielsen's gain, then the floor `2^-30 λ₀`.
        Either update stops the iteration when the new `λ` is
        above the ceiling. The accept arm (`gl`) and the reject
        arm (`up`) both set that stop.
      - The iteration stops on a zero cost, a step no longer than
        `2^-45(1+‖p‖)`, `λ` above its ceiling, or `fuel = 0`.
   3. **Classification** (`classify`, on rows recomputed at the
      final iterate, independent of why iteration stopped):
      - **Solved** (`solved_at`): admissible geometry (§3.4) and
        every weighted residual `≤ 1` → ok.
        - The rank comes from a sparse QR of `J̃ᵀ` with columns in
          constraint-row order (`Q.rank`). Column `j` is dependent
          when `|R_jj| ≤ 2^-26 ‖row j‖`; it is deleted and its tail
          re-merged, so every later `R_kk` is the distance of row `k`
          to the span of the kept earlier rows. This is exactly the
          C05.1 Gram–Schmidt criterion. Its constraint id is named
          in `red`.
        - `dof = #free − rank`.
      - **Conflicting**: not solved, and `‖J̃ᵀr̃‖ ≤ 2^-26 ‖J̃‖_F ‖r̃‖`
        → the ids whose weighted residual exceeds 1.
      - Otherwise → nonconverged.
4. **Merge** (`mg_fin`), by priority:
   - any cluster invalid → `Sv_err{invalid}`;
   - else any cluster conflicting → `Sv_conflict{ids}`, the union of
     the conflicting clusters' ids in global constraint order. A
     consistent cluster is never blamed;
   - else any cluster nonconverged → `Sv_err{nonconverged}`;
   - else `Sv_ok{ps, dof, red}`: `ps` scatters every cluster's free
     parameters into the input vector (canonicalized, `−0 → +0`),
     `dof` is the sum of cluster dofs plus the free parameters no
     constraint reads, and `red` is in global constraint order.

A single cluster yields exactly the C05.1 semantics: its
classification uses the same criteria on the same rows.

An expired budget is never a conflict: the fuel only bounds
iteration, and classification demands a certificate (laws
`lm_budget_returns_state`, `no_conflict_without_stationarity`,
`neg_solve_budget_not_conflict`).

### 3.4 No spurious solutions

A residual can be zero on geometry the constraint does not mean.
Each such case was audited and closed, then pinned by a law that
the old behavior would fail.

| Trap | Why it was possible | Rule now | Law witnesses |
|------|---------------------|----------|---------------|
| Angle at θ+180° | `sin` of the error is zero at both branches | directed residual, zero only at θ; strictly monotone in the error on (−π, π], finite everywhere, C¹ except exactly at an error of 180°, where the gradient still points back toward θ | `neg_angle_is_directed`, `neg_angle90_is_directed`, `ok_angle_from_flipped_side` |
| Line collapsed to a point under h/v | linear `Δy`/`Δx` residuals shrink with the line | h/v are angular: scale-invariant, so collapse does not satisfy them; h+v on one line is a certified conflict naming exactly those two (legacy `MutuallyExclusiveAxes`) | `neg_axes_never_collapse` |
| Collapse under any constraint that treats a pair as a line or a circle | residuals can be within tolerance on a line shorter than tolerance | **admissibility**: solved requires every such line (h, v, angle, par, perp, on-line base, tangency base, midpoint base, equal) longer than `tol.lin`, and every such radius above `tol.lin` (`geo_ok`) | `solved_needs_geometry`, `geometry_veto`, `ok_iff_solved`, `neg_coincidence_collapse_not_ok` |
| Negative radius | tangency / on-circle rows are satisfiable with `r < 0` | radii must be positive at the start (`invalid` otherwise) and on every accepted step | `steps_keep_radii_positive`, `neg_negative_radius_not_ok`, `neg_nonpositive_radius_start` |
| "Ok" without all constraints satisfied | — | `sol_ok(classify_go(s, …)) = s` for every `s`, and a conflict is never ok | `ok_iff_solved`, `conflict_never_ok`, `classify_is_solved_at` |

Parallel and perpendicular stay undirected on purpose
(`ok_parallel_is_undirected`): antiparallel lines are parallel.
Collapse traps end as a certified conflict once the least-squares
point is stationary (all 68 oracle collapse traps at budget 100),
otherwise as `nonconvergence`. Negative-radius traps end as
`nonconvergence`. Neither is ever ok, and an uncertified conflict is
never claimed (§9).

### 3.3 Vocabulary mined from the legacy solver

`legacy/.../sketch_solver.hpp` names `Converged`, `Redundant`,
`Conflicting`, `DidNotConverge` and `Invalid`, with named ids and
entity grounding.

| Legacy status | C05 result |
|---------------|------------|
| `Converged` | `Sv_ok` with empty `red` |
| `Redundant` | `Sv_ok` with nonempty `red` (not a failure) |
| `Conflicting` | `Sv_conflict{ids}` |
| `DidNotConverge` | `Sv_err{F_nonconverged}` (C00's reserved kind; its first trigger) |
| `Invalid` | `Sv_err{F_invalid}` |

Legacy constraint kinds and their C05 form:

| Legacy kind | C05 form |
|-------------|----------|
| Coincident, Horizontal, Vertical, Distance, Radius, Midpoint, Parallel, Perpendicular, Tangent, Angle | Native, same name |
| Collinear | `K_on_line` ×2 |
| Horizontal/VerticalDistance | `K_hdist` / `K_vdist` |
| Length | `K_dist` on the endpoints |
| Diameter | `K_radius` with `d/2` |
| Fixed | `free=False` or `K_fix` |
| Equal | `K_equal` (lengths) or `K_same` (radii) |
| Concentric | `K_coinc` on the centers |
| Symmetry | Composed: midpoint + on-line + perpendicular (§9) |

The numerics were rebuilt, not ported: legacy delegated diagnosis
to PlaneGCS' `diagnose()`.

Legacy sketch regions (`geometry.cpp:1790-1883`) were also rebuilt
rather than ported:

- they chained closed contours at a 1e-6 gap tolerance;
- they nested loops even/odd by point-in-polygon of a hole's
  sample centroid, which is wrong for nonconvex holes;
- they could not handle crossing contours.

Only the durable region key was ported.

## 4. Failure arms (C00 kinds reused, no new taxonomy)

| Arm | Arrangement | Solver | Publishes |
|-----|-------------|--------|-----------|
| invalid-input | validation (stage 1) | validation + initial evaluation | nothing (`A_err`/`Sv_err` carry only the kind) |
| resource-exhausted | `len > fuel` | — (budget expiry is nonconvergence, per plan) | nothing |
| numerical-uncertainty | any `Su` or internal miss | — | nothing |
| nonconvergence | — | not solved, no stationarity certificate | nothing |
| conflict (solver diagnosis, not a `FailKind`) | — | certified stationary, violated | constraint ids only, no geometry |

## 5. Bounds and constants (BN-10 labels)

| Constant | Value | Role |
|----------|-------|------|
| Product exactness | `lsb_b(a)+lsb_b(b) ≥ 1076` | proven condition (§1) |
| Orientation filter | `abs(v) > 2·errA·sum`, `sum ≥ 2^-900`, both finite | fast path, else exact (§1) |
| Slab margin | `abs(a)·2^-40 + 2^-1000` widening of each rational crossing's float estimate | conservative slab membership only; every decision is exact |
| Angle unit check | `|cs²+sn²−1| ≤ 2^-40` | input validation |
| Stationarity | `2^-26` (√ε) relative | conflict certificate, first-order |
| Admissibility | line length `> tol.lin`, radius `> tol.lin` | a segment or circle smaller than tolerance is not geometry |
| Rank / dependence | `abs(R_jj) ≤ 2^-26 ‖row j‖` | redundancy and dof |
| `λ₀`, clamp, start, stop | `λ₀ = 2^-10·max(‖col‖²_max, 1)`, clamp `[2^-30, 2^60]·λ₀`, start `2^-30 λ₀`. Reject raises `λ`. Accept uses Nielsen's gain, then the floor. Either new `λ` above the ceiling stops | damping |
| Tiny step | `2^-45 (1+‖p‖)` | stopping only, never classification |
| Nested-dissection leaf | fewer than 17 columns, or no edges | ordering granularity only |

Complexity and measured scaling are in §12.

## 6. Verification

```sh
export PATH=$HOME/.bend/bin:$HOME/.bun/bin:$PATH
bend src/c05/exact.bend --check-only     # ALL PROOFS CHECK
bend src/c05/arrange.bend --check-only   # ALL PROOFS CHECK
bend src/c05/solve.bend --check-only     # ALL PROOFS CHECK
bend src/base/par.bend --check-only      # ALL PROOFS CHECK
bend src/base/ex.bend --check-only       # ALL PROOFS CHECK
bend src/c05/sqr.bend --check-only       # ALL PROOFS CHECK
bend tests/c05/check.bend --check-only   # ALL PROOFS CHECK
bend laws/c05.bend --check-only          # ALL PROOFS CHECK (61 laws; timing in the receipt)
bend tests/c05/neg.bend                  # 38 PASS, selfcheck fails=0
bend tests/c05/pos.bend                  # 41 PASS, selfcheck fails=0
# native: bend <suite> -o <bin> && <bin>; js: bend <suite> -o <js> && bun <js>
python tools/oracle/c05/oracles.py       # independent oracles (numpy, scipy, shapely)
python tools/bench/bench.py              # scaling benchmarks with closed-form checks (§12)
```

The three lanes are byte-identical per suite (`cmp`). The receipt
(`docs/receipts/r0.1-2026-09-30.txt`, superseding
`c05.1-2026-09-29.txt` for 48ab78c) records hashes, law timings,
oracle output and the scaling benchmarks.

Independent oracles (`tools/oracle/c05/`, Layer D). None shares
code with the engines.

- **`ex_oracle.py`**: `orient2` sign against `fractions.Fraction`
  over 2,000 cases (random, near-collinear, and scaled by
  2^±1000). The criterion: 0 wrong signs, with uncertainty allowed
  only as fail-closed. Uncertainty is confined to extreme
  magnitudes: 1,316 moderate-magnitude cases (|x| in [1e-30, 1e30])
  give 0 uncertain.
- **`arr_oracle.py`**: random grid arrangements against
  shapely/GEOS (`unary_union` + `polygonize_full`). The oracle
  reconstructs every loop's exact coordinates from `VKey`s (crossings
  via `Fraction`) and checks:
  - the multiset of (face area, hole count);
  - outer loops CCW and holes CW;
  - no repeated vertex in a loop;
  - vertex count, edge count and dangling-edge count against the
    noded geometry.

  A mutation test (one region dropped, one dangling edge dropped)
  flips it to a mismatch.
- **`sol_oracle.py`**: random sketches built from a known
  configuration, so they are consistent by construction. They use
  all constraint kinds, with a locked-point discipline so no
  relation overwrites another. Solving starts from a perturbed
  point; one sketch in three is poisoned with a contradicting
  distance. Checks:
  - on `ok`: an independent residual recomputation within
    tolerance; grounded parameters bit-unchanged; and a reference
    rank from a fourth-order finite-difference Jacobian, orthogonalized
    twice in constraint order in numpy. A row at relative distance
    `≤ 1e-9` must be named redundant, a row at `≥ 1e-6` must not, and
    `dof` must equal `#free − kept rows`. A case with any row inside
    the band (the contract threshold `2^-26` sits there) is counted
    `grey` and skipped; the final run has none;
  - poisoned systems never `ok`, and every conflict names the
    contradicting pair;
  - consistent systems never `conflict`.
  - **multi** (50 per seed): two to four independent sketches, some
    poisoned, merged with disjoint parameters and interleaved,
    renumbered constraint ids. On `ok` the checks above apply to the
    whole system. A conflict must name only ids from poisoned parts
    and at least one complete contradicting pair. Nonconvergence is
    allowed only when a part is poisoned. This family found a real
    defect during R0 (a zero leading entry reaching a pivot poisoned
    the rank with NaN; law `ok_solve_zero_pivot`).

  Tangency follows the documented initial-side rule; angle and
  axis residuals are recomputed with `atan2`, independently.

  Trap families (50 per seed), built to catch spurious solutions:
  - **flip**: an angle constraint whose free end starts within ±20°
    of the θ+180° branch; it must solve on the directed branch;
  - **collapse**: h+v or coincidence+h on one line; it must never be
    ok;
  - **negrad**: a tangent circle whose center is forced across its
    line; it must never be ok.

  Run against the previous solver (commit `6a4a500`), the oracle
  reports 50 wrong per seed: every collapse and negrad trap reported
  ok, and every flip landed on θ+180°. The current solver reports 0.

Measured convergence profile. Seeds 1–4, per budget: 400
consistent, 200 poisoned, 68 flip, 68 collapse and 64 negrad
sketches.

| Budget | Consistent solved | Poisoned certified | Flip solved | Collapse / negrad ever ok | Spurious answers |
|--------|-------------------|--------------------|-------------|---------------------------|------------------|
| 10 | 367 | 181 | 0 (nonconvergence) | 0 / 0 | 0 |
| 20 | 398 | 195 | 68 | 0 / 0 | 0 |
| 40 | 399 | 198 | 68 | 0 / 0 | 0 |
| 100 | 400 | 198 | 68 | 0 / 0 | 0 |

The remaining poisoned cases end `nonconvergence`: their
least-squares infimum sits at a degenerate direction, where no
stationary point exists. Angular axis constraints are nonlinear, so
budget 10 now solves 367 consistent sketches (388 with the former
linear axes). From budget 20 on the counts match or exceed the
former solver.

## 7. Bend-native gates (BN-1..BN-12)

| Gate | Verdict | Evidence |
|------|---------|----------|
| BN-1 | PASS | The implementation is `src/c05/{exact,arrange,solve,sqr}.bend` (10 + 321 + 205 + 130 defs) plus `src/base/ex.bend` (34 defs) and `src/base/par.bend` (69 defs). The old count 48 + 321 + 205 + 65 + 130 put expansions and the parallel primitives under `src/c05`; R0.2 moved them, and `par` gained the sign defs (65 → 69). `src/c05/par.bend` is gone. Each `--check-only` → `ALL PROOFS CHECK`. The Python under `tools/oracle/c05/` and `tools/bench/` is test-only code, never on a runtime path. |
| BN-2 | PASS | `grep -rn "@unsafe" src/c05 laws/c05.bend tests/c05` is empty. |
| BN-3 | PASS | `grep -rn F32 src/c05 laws/c05.bend tests/c05` is empty; every scalar is the pinned as-bits F64. |
| BN-4 | PASS | No foreign or FFI code; imports are `Base`, `../c00/types.bend`, `../base/par.bend`, `../base/ex.bend` and the C05 files themselves. Boundary list: none. |
| BN-5 | PASS | `grep -rni "occt\|freecad\|planegcs" src/c05` is empty. The oracles (numpy, scipy, shapely/GEOS, `Fraction`) live under `tools/oracle/` as comparators only. PlaneGCS is not used, even as a comparator. |
| BN-6 | PASS | No GPU claim in this packet. |
| BN-7 | PASS | §2.3: vertices are lineage keys from caller ids, edges carry `srcs`, loops and regions are canonical, and the output is permutation-invariant (`pos-arr-perm`). Solver diagnostics name caller constraint ids. Parameter indices address the input vector of one call and are never persistent identity. |
| BN-8 | PASS | The checker proves every def terminates (a structurally shrinking first argument or an explicit Nat fuel: merges, row streaming, pointer jumping, component rounds, nested-dissection depth, `lm`). Budgets: arrangement `fuel ≥ #segments` else `resource-exhausted`; nesting retries `#comps + 1`; LM `fuel`, whose expiry is nonconvergence (`neg-sol-fuel-0/1`, `neg_solve_budget_not_conflict`, `lm_budget_returns_state`). |
| BN-9 | PASS | Parallelism ships as fork-join (§8): merge sorts, parallel maps over candidate pairs, edges, groups, components, loops and clusters, and the separator-tree factorization. Measured speedup is in §12. |
| BN-10 | PASS | Exact predicates carry a proven exactness condition and fail closed (`Su` → uncertainty, laws `ex_*_taints`, `ex_uncertain_dominates`). Every solver constant is labeled in §5. Conflict is a first-order certificate, labeled local in §9, and oracle-measured to give 0 false conflicts: 400 distinct consistent sketches, each solved at budgets 10, 20, 40, 100 and 200. |
| BN-11 | PASS | Error arms carry only a kind; conflicts carry only ids (§4). Laws: `arrange_invalid_publishes_nothing`, `arrange_budget_is_exhaustion`, `solve_invalid_publishes_nothing`, `no_conflict_without_stationarity`. Negative tests assert the exact arm. |
| BN-12 | PASS | The receipt names `BEND_PIN jnadeau207-collab/bend@bc01485d64a4454c08d74e343f9f1964859986c3` (`~/.bend/FORK` tag `numeric/2026-09-29`), the predecessor HEAD `e0915b0`, the committing SHA, per-file sha256, and the toolchain. |

Gate count: 12 (BN-1 through BN-12).

## 8. Parallel decomposition notes (BN-9)

Everything parallel is fork-join over immutable data: `a b = f(x)
g(y)` in `P.ms`, `P.pfm`, `P.pmc`, `Q.nd_go` and `Q.fact`. There is
no shared mutable state and no atomics.

Arrangement: candidate-pair stops (`P.pflat`), per-edge records,
per-vertex half-edge groups, per-component ray location, per-cycle
kept-successor links, per-loop walks and per-edge dangling tests are
parallel maps. Every sort is a parallel merge sort. Face and
component labels use pointer jumping and Shiloach–Vishkin, which take
log rounds of parallel maps.

Solver: clusters are solved in parallel. Within a cluster, nested
dissection is parallel over the separator tree, and so is the
multifrontal factorization. Redundancy naming stays sequential by
definition (it is order-dependent).

The spine is still lists: splitting and appending are sequential.
The R0.3 numbers are the side binary built from `0759b750`, not
`BEND_PIN`. That scheduler engages one thread per occupied row and
drains a small frontier flat, so a fork that follows a list split
is handed to the next turn. It is not the upstream pool, and it
was not replayed. The receipt's 16-thread rows are chain 1.06 s,
grid 0.81 s, truss 0.38 s (pinned 16-thread truss 7.03 s), and
sol-rects-1500 0.97 s (pinned 0.76 s, slower). The truss row is a
change above 2×. A3 disposition for sol-rects-1500: historical
regression on the side scheduler, not a number re-measured here.
Tree-shaped sequences are not in this packet.

## 9. Limitations (honest scope)

- **Segments only.** Arrangements take line segments; curved edges
  (arcs and circles in regions) need C07's curve/curve intersection
  and parameter correspondence. The solver handles arcs as
  circle-plus-endpoints.
- **Conflict certification is first-order and local.** It is
  global for linear constraint sets (h/v, coincidence, fix,
  midpoint, h/v distance, same). For nonlinear sets, a violated
  stationary point proves that no local improvement exists, not
  global inconsistency. A saddle start could in principle certify
  falsely; none occurred in any oracle run (§6).
- **Parallel and perpendicular are undirected by design.**
  Antiparallel lines are parallel. `K_angle` is directed (§3.4).
- **Collapse is refused; it is named only when certified.** A
  sketch whose only answers are degenerate (a line shorter than
  tolerance, or a radius at or below zero) is never ok.
  - It is a named conflict when the least-squares point is
    stationary (h+v on one line, and coincidence plus an axis
    constraint given enough iterations).
  - Otherwise, and for radii blocked at zero, it ends as
    `nonconvergence`. A boundary (KKT) certificate that would name
    those too is not yet computed.
- **Tangency sides are fixed by the initial configuration**, as in
  interactive CAD, and are documented in the residual table.
- **Degenerate starts are invalid.** Zero-length directions under
  direction constraints and concentric tangency starts are
  rejected rather than regularized.
- **One connected cluster is near a second, not a drag edit.**
  Iteration starts at the damping floor (§3.2). On pinned
  `bc01485d` the receipt's chain is 1.42 s (one thread) and
  1.38 s (16), and the grid is 1.63 s at either count (R0.1:
  3.71 s and 5.02 s). The 1.06 s chain and 0.81 s grid are the
  side binary `0759b750` at 16 threads, not the pin.
  There is no incremental re-solve or drag mode yet.
- **Rigid-cluster decomposition is not done.** Clusters are
  independent components only; a well-constrained subsystem inside a
  larger cluster is not solved separately. The latency above did
  not use that decomposition.
- **Parallel speedup is real and uneven** (§12). A banged GPU call
  on this WSL2 machine fails closed: CUDA has no concurrent managed
  access here, so no GPU speedup is claimed.
- **Symmetry is composed, not native.** Spline and ellipse
  constraints are absent.
- **The arrangement oracle is grid-based.** shapely nodes in
  floats, so its evidence covers integer inputs; non-grid exactness
  rests on `ex_oracle` plus the `pos-arr-tenth` and `pos-arr-star`
  pins.

## 10. General laws (`laws/c05.bend`)

61 laws.

**Layer A (general, quantified)**: 34.

- Sign algebra: `sgn_neg_invol`, `sgn_is_refl`, `sgn_neg_of_neg`.
- Expansion taint: `ex_uncertain_dominates`, `ex_neg_keeps_ok`,
  `ex_add_taints`, `ex_mul_taints`.
- Arm routing: `arrange_invalid_publishes_nothing`,
  `arrange_budget_is_exhaustion`, `ares_err_show`,
  `solve_invalid_publishes_nothing`, `sol_err_show`.
- Iteration and classification: `lm_budget_returns_state`,
  `lm_done_returns_state`, `no_conflict_without_stationarity`,
  `conflict_names_violations`.
- Shape: `gather_len` (the LM step has one entry per parameter).
- No spurious ok (§3.4): `conflict_never_ok`, `ok_iff_solved`,
  `classify_is_solved_at`, `solved_needs_geometry`,
  `geometry_veto`, `steps_keep_radii_positive`.
- Identity lemmas and self-reference: `nat_eq_refl`,
  `pt_eq_refl`, `or_true_r`, `self_pair_invalid`,
  `same_line_invalid`, `reversed_line_invalid`,
  `self_coincidence_invalid`, `par_self_invalid`,
  `perp_self_invalid`, `horiz_self_invalid`, `dist_self_invalid`.
  These hold for all ids, indices and parameter counts.

R0 restated the laws whose subjects changed, without weakening any
(receipt §4): `conflict_names_violations` over `dedup(viol(ds))`;
`classify_is_solved_at` over rows recomputed by `rows_at`;
`steps_keep_radii_positive` over the acceptance gate `rows_at`;
`dense_len` became `gather_len`. `zeros_len` was removed with its
subject.

**Layer B (closed implementation instances)**: 27, one per pipeline
arm plus the end-to-end exits. Floats are pinned by exact bits
(`ok_bits`), never by show strings.

- Arrangement accepts: square, crossing X with dangling arms,
  antenna, overlap lineage, hole, islands.
- Arrangement rejects: degenerate, budget, underflow uncertainty.
- Solver: linear solve, redundancy named, circle tangency, conflict
  named, grounded conflict, budget-not-conflict, bad index.
- Spurious-solution discriminators (each fails under the previous
  solver): angle directed (0° and 90°), parallel undirected,
  angle solved from the flipped side, axes never collapse,
  coincidence collapse not ok, negative radius not ok,
  nonpositive radius start invalid.
- R0: `ok_solve_zero_pivot` (fails with the zero-pivot defect),
  `ok_solve_clusters_merge` (redundancy across clusters in global
  order), `neg_solve_conflict_localized` (a consistent cluster is
  never blamed).

## 11. C05 exit receipt matrix (Amendment A2 format)

Legend:

- **Stage-isolated**: each negative fixture defeats exactly one
  pipeline stage (§2.2 / §3.2 first-match order), and each positive
  fixture traverses all stages.
- **3LANE**: interpreter, native and JS stdout byte-identical.
- **ORC-X / ORC-A / ORC-S**: the exact / arrangement / solver
  oracles (§6).
- **LA**: Layer A laws.
- **PASS**: law witness closed AND runtime witness green on all
  three lanes.

| Exit req | Formal spec | Predicate | Pos witness | Neg witness | Stage-isolated | Independent evidence | Status |
|----------|-------------|-----------|-------------|-------------|----------------|----------------------|--------|
| Regions with intersections | §2.2 stages 3–10 | exact stops + `next` orbits | `ok_arrange_square`, `ok_arrange_cross_dangles`; `pos-arr-cross/star/tenth` | — (accept) | yes (all stages) | 3LANE + ORC-A (1,200) + ORC-X | PASS |
| Nested loops and holes | §2.2 stages 9–10 | ray location + CW hole certification | `ok_arrange_hole`; `pos-arr-hole/nest` | — | yes | 3LANE + ORC-A (area and hole multiset) | PASS |
| Disconnected islands | §2.2 stage 8 | components + unbounded location | `ok_arrange_islands`; `pos-arr-islands` | — | yes | 3LANE + ORC-A | PASS |
| Dangling edges reported, never faces | §2.2 stages 10–11 | same-face sides | `ok_arrange_antenna_dangles`, `ok_arrange_cross_dangles`; `pos-arr-antenna/bridge` | — | yes | 3LANE + ORC-A (dangle count) | PASS |
| Deterministic boundary identity | §2.3 | `VKey` lineage + canonical order + `region_key` | `ok_arrange_overlap_lineage`; `pos-arr-perm`, `pos-arr-overlap`, `pos-arr-region-keys` | — | yes | 3LANE + ORC-A (coordinates rebuilt from keys) | PASS |
| Invalid arrangement input | §2.2 stage 1 | `segs_ok` | — | `neg_arrange_degenerate`; `neg-arr-degenerate/nan/inf/dup-id` | yes (stage 1 only) | 3LANE + LA (`arrange_invalid_publishes_nothing`) | PASS |
| Arrangement budget | §2.2 stage 2 | `len ≤ fuel` | — | `neg_arrange_budget`; `neg-arr-fuel` | yes (valid input) | 3LANE + LA (`arrange_budget_is_exhaustion`) | PASS |
| Uncertainty fails closed | §1; §2.2 | `Su` → uncertain | — | `neg_arrange_underflow`; `neg-arr-underflow/overflow` | yes (valid, within budget) | 3LANE + ORC-X (0 wrong in 2,000) + LA (`ex_*` taint) | PASS |
| Residual/Jacobian evaluation | §3.1 | analytic rows | `ok_solve_linear`, `ok_solve_tangent_circles`; 25 `pos-sol-*` | — | yes | 3LANE + ORC-S (finite-difference Jacobian rank) | PASS |
| Stable factorization, bounded iteration | §3.2 step 3.2 | Givens row-merge on the nested-dissection tree + Nielsen LM | `ok_solve_*`; `pos-sol-determinism` | `neg-sol-fuel-0/1` | yes | 3LANE + ORC-S (profile, §6) + LA (`lm_*`, `gather_len`) | PASS |
| DOF and rank diagnosis | §3.2 step 3.3 | sparse QR of `J̃ᵀ` with column deletion | `ok_solve_redundant_named` (dof 1), `ok_solve_zero_pivot`; `pos-sol-under/parallel/nothing/rect/zero-pivot` | — | yes | ORC-S (reference rank, 400 distinct sketches + 200 multi-part) | PASS |
| Independent clusters, merged | §3.2 steps 2 and 4 | components + priority merge in global order | `ok_solve_clusters_merge`; `pos-sol-clusters-merge` | `neg_solve_conflict_localized`; `pos-sol-conflict-localized` | yes | 3LANE + ORC-S multi (never blames a consistent part) | PASS |
| Speed and parallelism (MASTER_PLAN §15) | §12 | complexity + measured curves | `tools/bench/bench.py` (closed-form checks) | — | n/a | receipt §6 | PASS for the C05 rebuild; open items in §12 |
| Redundancy named | §3.2 step 4 | dependent rows in order | `ok_solve_redundant_named`; `pos-sol-redundant/perp-grounded/rect-extra/collinear-redundant` | — | yes | ORC-S (per-constraint SVD dependence) | PASS |
| Conflicts named | §3.2 step 4 | certified stationarity | — | `neg_solve_conflict_named`, `neg_solve_grounded_conflict`, `neg_axes_never_collapse`; `neg-sol-hv-axes/hv-collapse/dist-5-6/triangle/perp-grounded/grounded-contra/angle-flipped` | yes (valid, stationary) | ORC-S (200 distinct poisoned sketches: never ok, pair named) + LA (`conflict_names_violations`) | PASS |
| Nonconvergence is never a conflict | §3.2; plan text | budget → state, no certificate → nonconverged | — | `neg_solve_budget_not_conflict`; `neg-sol-fuel-0/1` | yes | LA (`lm_budget_returns_state`, `no_conflict_without_stationarity`) + ORC-S (0 false conflicts at every budget) | PASS |
| Invalid sketch input | §3.2 steps 1–2 | `cns_ok` + finite initial rows | — | `neg_solve_bad_index`, `neg_nonpositive_radius_start`; 19 `neg-sol-*` invalid pins | yes (one defect each) | LA (`*_self_invalid`, `same/reversed_line_invalid`, `solve_invalid_publishes_nothing`) | PASS |
| Constraint set (coincident … tangency) | §3.1 table | per-kind rows | `pos-sol-*` per kind (tan-lc both sides, tan-cc external/internal, arc, angle30, on-line, midpoint, equal, hdist/vdist, equal-radii) | — | yes | ORC-S (every kind appears in the random corpus) | PASS |
| No spurious solutions (flipped angle, collapse, negative radius) | §3.4 | directed angle, angular axes, `geo_ok`, `rad_ok` | `ok_angle_from_flipped_side`, `ok_parallel_is_undirected`; `pos-sol-angle-from-far`, `pos-sol-par-antiparallel` | `neg_angle_is_directed`, `neg_angle90_is_directed`, `neg_axes_never_collapse`, `neg_coincidence_collapse_not_ok`, `neg_negative_radius_not_ok`; `neg-sol-angle-flipped/angle90-flipped/hv-collapse/coinc-collapse/radius-cross/radius-start` | yes | LA (`ok_iff_solved`, `geometry_veto`, `solved_needs_geometry`, `steps_keep_radii_positive`, `conflict_never_ok`) + ORC-S trap families (0 wrong; 50 wrong per seed on the previous solver) | PASS |
| PlaneGCS comparator-only | BN-5 | grep | — | — | n/a | BN-5 grep | PASS |

## 12. Complexity and measured scaling (Amendment R0)

R0 replaced every list-positional loop, insertion sort and dense
factorization in C05.

| Stage | C05.1 | R0 |
|-------|-------|----|
| Arrangement candidate pairs | all `O(n²)` pairs | sort-and-sweep: `O(n log n + p)`, `p` = pairs with overlapping x-intervals |
| Vertices, edges, half-edge order | insertion sorts, `O(n²)` | merge sorts, `O(V log V)` |
| Faces, components | label relaxation, `O(V·diameter)` | pointer jumping and Shiloach–Vishkin, `O(V log V)` |
| Nesting | scan of all edges per component, retried | slab index + pointer-chained resolution, `O((V + c) log V)`; exclusion fallback only on cycles |
| Solver rows | dense `np`-wide rows, `O(m·np²)` to build | sparse rows, `O(nnz log nnz)` |
| Solver step | dense MGS, `O(np²(m+np))` | nested-dissection Givens row-merge on each cluster |
| Rank | dense Gram–Schmidt | sparse QR of `J̃ᵀ` with column deletion |
| Duplicate ids | `O(m²)` | sort, `O(m log m)` |
| Independence | one system | independent clusters in parallel |

Observable changes, each checked:

- `ok_arrange_cross_dangles` and `pos-arr-tenth`: dangling edges are
  now listed in canonical (u, v) edge order (the set is unchanged).
- Against C05.1, solver outputs differed in the last bits of values
  already within tolerance (Givens vs. Gram–Schmidt). `dof` and
  `red` stayed the same, and `ok_solve_linear` and
  `ok_solve_redundant_named` were re-pinned (a 6e-30 residual; 2 ulp).
  R0.3 pins those two again, plus `ok_angle_from_flipped_side`:
  the linear y residual is now 1.9e-27, and the other two move by
  1 ulp. Verdicts, `dof` and redundancy ids are unchanged
  (receipt §2).

Measured scaling (native, 16 cores, idle machine;
`tools/bench/bench.py`, every run checked against a closed-form
answer) is recorded in the receipt, §6.

Budgets and status against MASTER_PLAN §15:

- **10,000-segment arrangements: met for CAD-like input.** A
  10,000-segment plate with 2,500 holes arranges in about a second.
  Random dense input is output-bound (`V ≈ n²/8`).
- **10,000-parameter sketches.** Chain 10,002 parameters: pinned
  `bc01485d` 1.42 s (1 thread) and 1.38 s (16); side scheduler
  `0759b750` 1.46 s and 1.06 s. Grid 3,200 parameters: pinned
  1.63 s at either thread count; side scheduler 1.60 s and 0.81 s.
  R0.1 was 3.71 s and 5.02 s. The 0.81 s and 1.06 s figures are
  that side binary, not the pin, and were not re-measured here.
  Answers checked against the closed forms (receipt §3).
- **Parallel speedup: measured on the side scheduler `0759b750`,
  not re-measured on the current pin** (§8, receipt §3). Truss at
  16 threads is 7.03 s on the pinned compiler and 0.38 s on that
  side binary, which is above 2×. Grid on that binary is 1.60 s
  at one thread and 0.81 s at 16; chain is 1.46 s and 1.06 s.
  sol-rects-1500 at 16 threads is 0.97 s versus 0.76 s on the
  pinned scheduler. A3 disposition: historical regression on the
  side scheduler, not a number re-measured here. GPU: a banged
  call refuses to start on this WSL2 box.
