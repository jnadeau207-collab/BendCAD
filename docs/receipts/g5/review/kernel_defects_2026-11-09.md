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
