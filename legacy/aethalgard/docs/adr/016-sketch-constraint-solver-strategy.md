# ADR-016: The 2D constraint solver — adopt the numerics, own the diagnosis

Date: 2026-07-27
Status: **ACCEPTED 2026-07-27 — in force.** GOV-004's packet reserved the
strategy choice because it is architectural law; it was taken by manager ruling
under the founder's standing directives (`41e8353`), is reversible through the
seam this ADR requires, and remains overridable by the founder.
**The benchmark gate was SATISFIED first** — the hands-on evaluation was run and
PlaneGCS passed every bar (see "The benchmark" below), so the decision rests on
measurement rather than argument.

Header corrected at CAP-015's admission: `41e8353` accepted this ADR by editing
the Decision heading and left this block reading "not in force", so the file
declared itself both accepted and pending. The Decision below is authoritative.

## Context

Half of parametric CAD is a sketcher standing on a 2D variational constraint
solver, and Aethalgard has neither — verified, not assumed: there is no
sketch, constraint, or solver source in the tree. Five of the 27 catalog
operations (`create_profile`, `extrude`, `revolve`, `loft`, `sweep`) are
UNREACHABLE behind this one pillar, the largest single blocked group at the
current 17-of-27 reachability.

Full analysis: `docs/research/03-sketcher-constraint-solver.md`.

## The measured facts that drive the decision

1. **`package.json` declares `"license": "UNLICENSED"`.** Aethalgard is
   proprietary. A copyleft license is therefore a prohibition, not a trade-off
   to weigh against technical merit.
2. **This project already ships LGPL code, dynamically linked.** OCCT is
   LGPL-2.1-with-exception and the build produces **26 `TK*.dll`** loaded at
   runtime. The compliance pattern an LGPL dependency requires is already built
   and proven here, so a second LGPL component adds no new obligation _class_.
3. **Fast math is already off everywhere** — every native target compiles
   `/fp:precise` (MSVC) or `-fno-fast-math` (GCC/Clang). The usual sources of
   cross-machine floating-point divergence are disabled by existing policy, which
   is what makes determinism over an iterative solver tractable at all.

## Decision (ACCEPTED 2026-07-27)

**Adopt PlaneGCS's numerical core behind one typed seam; own the diagnosis layer
above it.**

- **Adopt** the numerics and DoF/redundancy analysis. PlaneGCS (FreeCAD, LGPL
  2.1+) carries 15+ years of production use and solves the genuinely hard part:
  degree-of-freedom decomposition, and stability while dragging.
- **Own** the diagnosis language. ADR-015 rule 6 already makes refusal quality a
  product surface; FreeCAD's most persistent Sketcher complaint is precisely its
  redundant/conflicting-constraint messaging. Import the conflict _sets_ as data,
  write the _language_ ourselves.
- **Stage** behind one seam — constraint system in, solution + diagnosis out —
  so the engine stays replaceable. Reversibility is what makes adopting a
  third-party solver safe.

**Determinism is part of the decision, not a follow-on.** The document stores
the constraint system _and_ the solved geometry. Replay re-solves and asserts
the result reproduces the stored solution within a tolerance declared in the
GOV-003 §2 budget table; outside it, the document **fails closed**. A silent
branch flip becomes a caught failure rather than a corrupted model.

## Alternatives rejected

- **SolveSpace's `slvs` — DISQUALIFIED on license.** It has the cleanest C
  library boundary of any candidate and is genuinely the nicest seam; GPL 3
  copyleft would extend to the whole linked work. Recorded explicitly so it is
  not re-proposed as a discovery later: **the seam quality is real, the license
  makes it irrelevant.**
- **D-Cubed DCM (Siemens).** The industry reference point — SolidWorks, NX,
  Creo and Onshape all build on it. Enterprise licensing aimed at established CAD
  vendors; not obtainable in practice at this project's size.
- **A from-scratch variational solver.** No license risk and full control, and
  the highest execution risk by a wide margin. The hard part is not the Newton
  iteration — it is DoF analysis via graph decomposition, robust under/well/over-
  constrained handling, drag stability without branch flips, and actionable
  diagnosis. That combination is _why_ the industry licenses DCM. For this
  component, the world-class move is to stand on a mature solver rather than
  re-derive one.

## Consequences

- Adds **Eigen** (MPL2, permissive) to the native build, which currently fetches
  only nlohmann_json. **Eigen is the ONLY new dependency** — see the correction
  below.
- **Correction to this ADR's own first draft: Boost is NOT required.** The draft
  listed it as a dependency. Measured: two of PlaneGCS's three Boost includes
  are **dead** (zero uses), and the third is a single `connected_components`
  call replaceable by ~30 lines of union-find. All five translation units
  compile clean against Eigen alone. Recorded because the wrong version of this
  line would have inflated the adoption cost with a heavyweight dependency that
  the code does not actually need.
- PlaneGCS is **not** distributed as a standalone library — it lives inside
  FreeCAD's source tree, so adoption means vendoring a subtree (**11 files,
  ~13,300 LOC**, plus three trivial shims for FreeCAD's export macros and
  logger) and owning its updates.
- Adds a second LGPL component to a proprietary product. No new obligation
  class (see fact 2), but a business call the founder owns.
- The constraint-system op-hash must be **order-independent**: constraints
  canonically sorted before hashing, or the replay cache misses constantly while
  appearing correct.
- Sketch entities mint **real roles from birth**. CAP-011 ruled that imports mint
  FLAT per-kind roles because they have no authored construction frame; a sketch
  is the opposite — fully authored — and downstream fillet/chamfer selectors will
  resolve against its edges.

## The benchmark

The GOV-004 packet asks for hands-on evaluation "not from READMEs". It was run —
PlaneGCS vendored standalone, compiled, and driven against a harness on this
machine. Full detail in `docs/research/03-sketcher-constraint-solver.md` §1a.

| property                 | result                                                                        |
| ------------------------ | ----------------------------------------------------------------------------- |
| correctness              | constrained square solves; dimension honoured exactly                         |
| under-constrained        | reports **DoF = 7** exactly — a number a UI can act on                        |
| conflicting              | names the **specific tags {2, 3}**; the set is enumerable                     |
| redundant vs conflicting | correctly **separated** (`hasRedundant=1, hasConflicting=0`)                  |
| **determinism**          | **8 independent solves agree to the LAST BIT** (exact compare, not tolerance) |
| drag stability           | **200 drag steps: 0 failures, no branch flip**                                |

**The determinism result is what makes this decision safe**, because it is the
property most at risk from an iterative solver and the one §2's replay contract
depends on. It was checked with an exact `!=` comparison deliberately — a
tolerance-based check would have hidden the drift the contract exists to catch.

**The redundant-vs-conflicting result strengthens the adopt/own split.** The raw
solver already distinguishes the two and enumerates the offending tags, so
FreeCAD's known messaging weakness is a **presentation** problem, not a data
one. The material for a better diagnosis surface is already there.

Because PlaneGCS cleared every bar, the rejected alternatives above stay
rejected **on evidence rather than on argument**. Had it failed the drag or
determinism bar, they would have re-opened.
