# G2 grader brief

You grade gate G2 (`C:/dev/BendCAD/docs/gates/g2-gear-pump.md`, §5).
You did not build the pump, and you do not trust the design agent's
report. You check the exported files and the report against each other
and against physics.

## Inputs

- The run directory you were given, `C:/dev/BendCAD/docs/receipts/g2/RUN/`:
  `report.md`, `parts.txt`, and `calls.jsonl` (every BendCAD call the agent
  made, with its output).
- The exports in `/home/jesse/g2/export/` (WSL path; read them from Git
  Bash with `MSYS_NO_PATHCONV=1 wsl.exe -e ...` or copy them to a scratch
  directory): STEP AP242 per part and of the assembly, STL per part.

## Tools

Write your grader as `C:/dev/BendCAD/tools/grade/g2.py`. Run it in WSL with
`PYTHONPATH=$HOME/oracle-pkgs python3` (build123d/OCCT, shapely, numpy,
scipy are there). OCCT is a test-only reader here: you may use it to read
STEP, measure volumes and boxes, slice, and compute distances. You may not
call BendCAD. Every number you report must come from the exported files
or from the published standards and catalogs you cite.

## Checks

1. Every part STEP reads as the expected number of valid solids. Volumes
   times the stated densities agree with the report's certified masses
   within 1e-6 relative; the total mass agrees.
2. The assembly STEP reads as one solid per instance in the printed
   instance order, and each solid agrees with its part file moved to its
   placement.
3. Envelope and ports: the assembly box, the flange pilot diameter and
   the two mounting holes on 106.4 mm centres, both port axes
   perpendicular to the gear axes on opposite side faces, suction larger
   than pressure.
4. Gear tip to chamber bore clearance and gear face to cover side
   clearance, recomputed from the exported geometry (slices, outlines,
   distances), against the report and against the 0.02–0.06 and
   0.02–0.05 mm windows.
5. The gear mesh: tooth outlines of both gears over one full pitch of
   rotation at the gear ratio; minimum clearance and no crossing.
6. Displacement per revolution recomputed from the exported gear and
   chamber geometry by a method independent of the agent's (state it),
   against 8 cm³/rev ±3 % and against the report.
7. Every fit and clearance the report claims as certified appears in
   `calls.jsonl` with `status=certified` output, for the parts named.
8. Every KERNEL-BLOCKER in the report is checked: is the need real (the
   gate demands it), is the call and output in `calls.jsonl`, and could a
   compliant design avoid it.

## Renders

Render the assembly, an exploded view, and a section through the gear
plane from the STL exports (numpy + Pillow, as
`C:/dev/BendCAD/tools/grade/g3_render.py` does) into the run directory as
PNG files.

## Output

`grade.json` (one entry per check: pass, measured values, tolerance,
evidence path) and `grade.md` (verdict PASS, FAIL or REFUSED-BY-KERNEL
with the named blockers; then the checks, each with its numbers) in the
run directory.
