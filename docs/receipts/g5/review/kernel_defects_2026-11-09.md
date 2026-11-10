# Kernel defects found 2026-11-09

All four were found while proving G5 and while building the agent-loop demo. Each one is reproducible.

1. **The tessellator stitches T-junctions with zero-area triangles.**
   - Scale: impeller 116,024, turbine 179,072, NGV 5,298 (readiness.json).
   - Refining a bicubic patch splits its boundary edges on one side only, and collinear filler triangles keep the mesh topologically closed.
   - Volume is unaffected. FEM and CFD cannot use these meshes.
   - The old closure check paired directed edges, so it passed.
2. **Intent is mis-measured for a hole tangent to a face.**
   - Steps: a 60x40x10 box (node 1), then a cylinder r4 h10 moved to (56, 20, 0), then `difference` with `remove` intent.
   - The kernel measures `material=same`, but the hole removes about 500 mm³.
   - The edit is refused, so no bad geometry is published. The measured effect is still wrong (a tangent degeneracy).
3. **`wall` is slow.**
   - On the same plate with two through holes (node 32), `wall 32 2` ran past 10 minutes and was stopped.
   - With one hole (node 4) it finished in about 1 s.
4. **The `scene` command tessellates parts one after another.**
   - Regenerating G5 took about 3 h.
   - Per-node `tess` calls run in parallel give identical meshes in 72 min, bounded by the turbine alone (about 4,300 s).
5. **K1 point classification reported "on boundary" from hits on a patch's widened extension.** (Fixed 2026-11-09, `src/k1/gb.bend` `ry_hits` / `ry_hx`.)
   - Ray-vs-patch hits come from a widened parameter domain. The "sample point lies on the other solid" test ran before the in-face test, so an extension passing near the sample point refused the boolean (K1 reason 92, class 3).
   - Every helix-vs-plane boolean failed this way (helix union box, box minus helix, patch rod union box). All now commit.
6. **K1 intersection trace loses a segment when a patch boundary lies on a periodic surface's parameter wrap.** (Open.)
   - Steps: a helical tooth skin whose sections fall every 30 degrees from 0, unioned with a cylinder. The patch spanning 150 to 180 degrees ends exactly at theta = pi of the cylinder.
   - Its trace keeps only the part from 179.2 degrees onward, which leaves degree-1 vertices, so face cycles fail (K1 reason 93; probe `tests/k4/zcyc.bend`).
   - Workaround in `tools/g5/threads.py`: section angles are kept more than 2 degrees from 0 and 180 in the cutter's own frame.
7. **A plane through a cone's apex was refused as a tangency.** (Fixed 2026-11-09, `src/k1/ss.bend` `pk_apex`.)
   - A helical thread's end caps are planes containing the axis, so they pass through the apex of every coaxial chamfer cone. The infinite plane cuts the cone in two generator lines, one tangent line, or only the apex.
   - Before the fix, every threaded shaft end and nut refused the boolean (K1 reason 71); the front nut gave up after 62 minutes. The kernel now returns the generator lines.
8. **A coplanar edge crossing was refused when the first edge could not be extruded.** (Fixed 2026-11-09, `src/k1/co.bend` `pair_sw`.)
   - Crossings in a shared face plane are found by extruding edge A along the plane normal and intersecting edge B with it. Only lines, arcs and straight Béziers extrude, so a curved Bézier edge refused the boolean (K1 reason 97).
   - Steps: one diffuser vane prism (Bézier edges) unioned with a Ø6.2 boss whose end faces are flush with the vane's. Probe: `tests/k4/zcx.bend`.
   - When A cannot be extruded, edge B is extruded instead and A is intersected with it. The repro now commits in 0.9 s.
9. **Cylinder face membership was decided by a vertical ray through a boundary vertex.** (Fixed 2026-11-09, `src/c07/mem.bend` `uv_mem_w`.)
   - Symptom: a core cylinder unioned with an M8x1 tooth skin. 2, 3, 5 and 6 turns commit; 4 and 6.68 turns are rejected by the C07 embedding check (`edge-face-penetration`). Probe: `tests/k4/zval.bend`.
   - Cause: the flagged edge is a tooth section line. It meets the core only at its end vertex, 0.35 mm outside the flagged band face. The section lines sit at fixed angles, and the band boundary has trace vertices at the same angles. The membership test counts boundary crossings on a vertical ray at the point's angle, so the ray passes within one ulp of a boundary vertex. The hit box and the exact vertex then gave opposite parity (inside 1, outside 0), so pass/fail depended on the exact turn count.
   - Fix: membership already returns "uncertain" for points within `tol` of the boundary. Any other point keeps its answer when moved sideways by less than `tol`, so the ray is cast at angle + tol/(2r), off every shared vertex angle.
   - Verified on k6w: the unbanded 4-turn case commits in 135 s, the full-length M8 thread on a plain cylinder in 267 s, and on the stepped shaft in 295 s. An interim workaround (cores built from 0.5 mm bands) only moved the odds and was removed.
10. **Unions of disjoint solids scale as about O(n^2.3) and create no faces.** (Open.)
   - Steps: one diffuser vane prism, rotated n times about z, tree-unioned. Results on k6w: n = 2 in 0.2 s, 4 in 1.5 s, 8 in 8.5 s, 18 in 57 s. Every union reports `faces_created=0`, and the result is n disjoint solids.
   - The vanes' bounding boxes overlap, so each level runs K1 and then re-validates every cross-operand face pair of the growing result. A full diffuser (60 bodies plus the disc) takes hours on one core.
11. **A thread callout cannot bind to a modelled helical thread.** (Open.)
   - `(thread NODE NAME FACE ...)` requires one cylindrical face of NODE that spans Z0..Z1 (`docs/k2-contract.md` §2: "no helix is modelled"). Once a true ISO 68 tooth is unioned onto the core, the core splits into helical strips about one pitch long (`n1001.c0.wall.1.0.p0` … `p4`), so no face spans the engaged length. `asm engage` therefore has nothing to bind to.
   - Needed: let a callout name the thread feature (the core plus its helix) and check the modelled root and crest against the class window, or carry the callout through the boolean on the core's lineage.
