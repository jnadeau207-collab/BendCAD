# G3 brief: two-stage spur gearbox

You are designing a gearbox with BendCAD, a CAD kernel you can reach only
through its MCP tools. Call them from Bash with

    BENDCAD_TIMEOUT_MS=3600000 BENDCAD_LOG='C:/dev/BendCAD/docs/receipts/g3/run2/calls.jsonl' \
      node /c/dev/BendCAD/tools/mcp/mcpc.mjs TOOL 'JSON-ARGUMENTS'

(`node /c/dev/BendCAD/tools/mcp/mcpc.mjs --list` lists the tools). Start by
calling the `reference` tool and read it in full. Apply a long gear profile in its own `apply` call: the Windows command line
holds about 32,000 characters. Keep every design and
output file under `/home/jesse/g3/` (a WSL path; create it and its `parts`
and `placed` subdirectories once with
`MSYS_NO_PATHCONV=1 wsl.exe -e mkdir -p /home/jesse/g3/parts /home/jesse/g3/placed`; under Git Bash, prefix every `wsl.exe` call with `MSYS_NO_PATHCONV=1`). You may use Python only to
compute numbers: `python /c/dev/BendCAD/docs/receipts/g3/gear.py Z PHASE ADDENDUM`
prints the involute spur-gear profile of a Z-tooth gear (module 2, 20 degree
pressure angle, 0.1 mm backlash, centred at the origin, one tooth centred at
angle PHASE radians, tip radius `Z + 2 * ADDENDUM` mm) as a BendCAD `(path ...)`. All geometry must be built
by BendCAD. Some queries take many minutes; let them finish.

## The gearbox (millimetres)

Two-stage reduction, ratio 9:1, three parallel vertical shafts (axes along
z) at x = 0 (input), x = 60 (intermediate) and x = 120 (output), y = 0.

- Gears: module 2, face width 20, bore diameter 20 (a hole in the gear
  region). The 15-tooth pinions use the full addendum (ADDENDUM 1); the
  45-tooth gears use tip relief, ADDENDUM 0.9 (tip diameter 92.6), because a
  full-depth 45-tooth tip reaches the 15-tooth pinion's involute
  interference limit at this centre distance. Stage 1: input pinion, 15 teeth, on the input shaft; gear, 45
  teeth, on the intermediate shaft; both with z from 10 to 30. Stage 2:
  pinion, 15 teeth, on the intermediate shaft; gear, 45 teeth, on the
  output shaft; both with z from 40 to 60. Each meshing pair must mesh: a
  tooth of one gear sits in a gap of the other on the line between their
  centres, with backlash, never overlapping. Use the phase argument to get
  this right, and check it with BendCAD.
- Shafts: diameter 20. Input: z from -10 to 100 (it leaves the top of the
  housing). Intermediate: z from -10 to 80. Output: z from -30 to 80 (it
  leaves the bottom).
- Housing, three parts: a base plate 230 x 130 x 10 (x from -40 to 190, y
  from -65 to 65, z from -10 to 0); a wall frame of the same outline with a
  200 x 110 rectangular opening (x from -25 to 175, y from -55 to 55), z
  from 0 to 70, so every gear clears the walls; and a cover plate like the
  base at z from 70 to 80. The
  base and cover each have a bearing bore of diameter 36 at every shaft
  axis.
- Bearings: six rings, inner diameter 20, outer diameter 36, height 10, one
  in each bearing bore.
- Seals: two rings, inner diameter 20, outer diameter 32, thickness 4, one
  on the input shaft on top of the cover (z from 80 to 84) and one on the
  output shaft below the base (z from -14 to -10).

Model every part as its own design node, at a convenient local position, and
declare a truthful intent for every operation. Parameterize the housing
interior height (70) and the gear face width (20) with tolerance zones of
your choice.

## What to do

1. Build all 18 parts (3 housing parts, 3 shafts, 4 gears, 6 bearings, 2 seals). Evaluate them and record each part's volume interval.
2. Write the assembly: one instance per part, mates that pin the base and
   place every other part (shafts on their axes, gears and bearings on their
   shafts at the right heights, plates stacked). Solve it and report the
   kinematic degrees of freedom; aim for a fully constrained assembly, or
   explain any remaining freedom (a shaft's rotation is not represented).
3. Check both gear meshes with `interference` and `clearance` on placed
   copies of the meshing gears (use `move` nodes at the solved
   translations), and check a gear against the housing frame the same way.
   Report exactly what BendCAD certifies and what it only estimates.
4. Write PMI for the housing: a datum on the base, the interior height and
   the gear face width as dimensions, a flatness tolerance on the base's top
   face, and a stack-up of the axial gap between the stage-1 gear and the
   cover, over cold (grow 1) and hot (grow 1.001) states. Run `check` and
   `stack`, and export it with `step42`.
5. Export every part as STEP (`step_export`) and STL (`stl_export`), both
   from the part node and from a `move`d copy at its solved assembly
   placement, into `/home/jesse/g3/parts/` and `/home/jesse/g3/placed/`.
   Run `explode` along z with a gap of your choice and record the exploded
   placements.

Finish with a short report: the parts and their volumes, the assembly
text, the solve result, the mesh checks (certified versus estimated), the
stack-up results and every exported file path. If BendCAD refuses
something, say what it said and how you worked around it; never pretend a
refusal did not happen.
