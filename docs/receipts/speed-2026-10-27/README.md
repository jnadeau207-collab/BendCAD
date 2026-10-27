# Speed: measured causes and fixes (2026-10-27)

Every change here leaves results bit-identical. Evidence:

- `tools/speed/ident.py` runs one command battery (G1 bracket and strap, G2
  gear pump, G3 gearbox: eval, mass, interf, step, asm solve, asm interf,
  threads) on a reference binary and on a new one. It compares stdout and
  exported files by sha256.
- The reference is `bendcad-k3z` (main before this work), outputs in
  `ident-k3z.json`.
- Laws (check and `--verdict`), mutants for the touched packets, and pins
  run on the final source (`gates.txt`).

## What was slow, measured

1. Whole-design evaluation on every command.
   - A command about one node evaluated every node in the design.
   - G2 `mass 38` needs the front-cover chain (16 nodes), but paid for all
     53, including the 300 s drive-shaft union.
2. The same design evaluated twice.
   - `interf A B` and `clearance A B` called `ev_part` once per operand.
   - `asm` chose between `AS.asm_go` and `KA.k2_asm` with a strict
     `Bool.pick`. Bend evaluates both arms, so both ran, each evaluating
     the design.
   - `step` (`step_k2` / `step_out`) and `pmi` (`fits_s`) had the same
     pattern.
3. Independent nodes evaluated one after another.
   - `ev_nodes` walked the node list sequentially, although a design's part
     chains do not depend on each other.
4. Linear list indexing inside loops in the boolean kernel (K1).
   - Every coedge, edge, vertex and face lookup was an `L.nth_*` scan of the
     B-rep's lists.
   - A union of an n-gon prism with a cylinder scaled as about n^2.3:
     212 s at n = 256.
   - perf: 88 % of that time was those scans: `hcs_ce` 57 %, `edge_at` in
     `ces_dist` / `ce_turn` / `ce_poly` 29 %.
   - The face-cycle walk (`gw.bend`) was O(n³) per face:
     - `next_he` scanned every half-edge at each step, with an `nth_pc`
       scan for each one;
     - used flags were a list;
     - the polygon was built by appending to a growing list.
5. C07 curve-box restriction.
   - `restr` ran a full blossom for each of the n control points (n³/2
     interval combinations).
   - A point restriction ran n identical blossoms.
   - `h_val` used a strict `Bool.pick` that computed the interval
     restriction even in its point branch.

## Fixes

| # | Change | Where |
|---|---|---|
| 1 | `M.ev_for(p, ids, old)` evaluates only the dependency closure of the nodes a command needs. Op lookups still see the full node list. | `src/c06/model.bend`, `src/c06/cli.bend`, `src/c06/zone.bend`, `src/c14/asm.bend`, `src/k2/kasm.bend` |
| 2 | `match` dispatch in place of strict picks over expensive arms (`asm_k`, `step_k`, `pmi_k`); `pair_q` evaluates once for both operands. | `src/c06/cli.bend` |
| 3 | `ev_nodes` evaluates by dependency level, each level with `B.pmap_g`. Results return in node order (`ce_ord`). | `src/c06/model.bend` |
| 4 | K1 takes `FB.KB`: the B-rep plus its C04 `Ty.Ix` tables, built once per operand, so each lookup is O(log n). The recursive `box` field makes the compiler pass a `KB` as one word; flattened, two KBs overflowed the 247-slot segment limit in `px.bend`. `gw.bend` gets a piece table, a per-vertex index of outgoing half-edges (stable order, same tie-breaking), a used-flag table and a linear polygon join. | `src/k1/*.bend`, `src/k2/kgap.bend`, `src/k2/thr.bend`, `src/k3/div.bend`, `src/k3/mach.bend` |
| 5 | `restr` shares the de Casteljau triangle in parameter a, applying the same operations in the same order, and computes one blossom for a point. `h_val` dispatches with `match`. | `src/c07/rb.bend`, `src/c07/eng.bend` |

## Results

Final binary `bendcad-s5` (`binaries.txt`) against `bendcad-k3z`. The
battery ran 6 commands at a time on 16 cores, so absolute times include
contention (`compare-k3z-s5.txt`):

| Command | k3z | s5 | Speed-up | Output |
|---|---|---|---|---|
| G1 bracket mass | 34.6 s | 19.9 s | 1.74 | identical |
| G2 eval (53 nodes) | 805.5 s | 373.4 s | 2.16 | identical |
| G2 mass 38 | 843.1 s | 173.6 s | 4.86 | identical |
| G2 interf 11 38 | 1452.3 s | 228.9 s | 6.34 | identical |
| G2 step 38 | 808.3 s | 117.0 s | 6.91 | identical (STEP file sha too) |
| G2 asm solve (20 instances) | 1257.2 s | 390.3 s | 3.22 | identical |
| G2 asm interf (body, front cover) | 1854.3 s | 222.8 s | 8.32 | identical |
| G2 threads 38 | 772.8 s | 120.5 s | 6.41 | identical |
| G3 eval (164 nodes) | 1.9 s | 1.3 s | 1.54 | identical |

All 11 battery commands are identical at every step: s1 (demand evaluation
and single evaluation), s2 (+ level-parallel evaluation), s3 (+ C07
restriction), s4 (+ indexed K1) and s5 (+ face-cycle walk). See
`compare-k3z-s*.txt`.

Union scaling (`scaling.txt`, `tools/speed/union_scale.py`):

| n | s1 | s5 |
|---|---|---|
| 16 | 2.25 s | 1.44 s |
| 64 | 11.41 s | 6.26 s |
| 128 | 40.44 s | 16.68 s |
| 256 | 212.18 s | 55.40 s |

The exponent drops from about 2.3 to about 1.7. Same certified volume and
area at every n.

Gates on the final source (`src_sha256.txt`):

- Laws: 23/23 packets `ALL PROOFS CHECK` under check and `--verdict`
  (`laws.txt`).
- Mutants: C06 2/2, C14 19/19 and K1 3/3 killed (`mutants.txt`).
- E2E regression sweep: 28/28 suites pass on s5 (`gates.txt`). The K1 corpus ran in 1099 s (1722 s on k3z), K2 E2E in 528 s (874 s) and K3 E2E in 732 s (979 s).
- Pins: 25/25 files, 2,651 pins, all hold (`gates.txt`).

## What is still slow, and the next steps

- The 256-face union profile on s4 is flat. The largest self-time entries:
  - runtime list freeing: `term_drop` 16 %, `span_fade` 13 %, `rfc_wrap` 8 %;
  - `List.append` 7 %;
  - C07 rational-Bézier interval arithmetic: `rb_zipc` 6 %, `rb_hull`
    3 %, `rb_lvl` 2 %.

  The callers of the freeing are mostly `rb_zipc`, `rb_lvl`, `rb_blossom`
  and `rb_hull`: lists of intervals allocate a cell per coefficient per
  level.
  - The next step is a packed coefficient representation for C07 curve
    boxes, or fewer box evaluations per K1 hit test.
- The G2 critical path is still the 300 s drive-shaft union (gear prism with
  shaft) and the 170 s front-cover hole chain. Level parallelism cannot
  shorten one chain.
- No result cache between CLI calls. `ev_nodes` already reuses `old` by
  structural key; persisting it needs exact serialization of a node result
  (B-rep, cells, names, placement, cached measures). C12's archive covers
  the B-rep part.
