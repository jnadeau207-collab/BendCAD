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
