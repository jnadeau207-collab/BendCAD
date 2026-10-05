# G1 brief: parameterized mounting bracket

You are designing a part with BendCAD, a CAD kernel you can reach only through
its command-line interface. Run it from the Bash tool as

    wsl -e /home/jesse/bc/bc DESIGN COMMAND ARGS...

Commands: `reference` (no design argument: `wsl -e /home/jesse/bc/bc reference`
prints the design language; read it first), `new`, `apply EDIT...` (each edit
one quoted S-expression argument), `show`, `eval`, `measure NODE`,
`faces NODE`, `sens PARAM NODE`, `tess NODE OUT.obj`. Use no other tool and do
not read, search or open any file: everything you need comes from the CLI.
Keep every design file under `/home/jesse/g1/`.

Design a mounting bracket plate, fully parameterized:

- Parameters (millimetres): plate width W = 120, depth H = 80, thickness
  T = 8, corner radius R = 10, mounting-hole diameter D = 8, hole edge offset
  E = 12, boss diameter B = 40, boss height P = 12, bore diameter C = 20.
- Plate: W x H x T, lying on z = 0, with all four corners rounded to radius R
  (a curved outer boundary), x in [0, W], y in [0, H].
- Four through holes of diameter D at (E, E), (W - E, E), (E, H - E),
  (W - E, H - E). Hole positions must follow W and H.
- A cylindrical boss of diameter B and height P on the top face, centred on
  the plate.
- A bore of diameter C through the boss and the plate, on the same axis.
- Declare a truthful intent for every operation.

Then:

1. Evaluate the design and report its volume interval and bounding box.
2. Show the stored design, then evaluate it again (this re-opens it from the
   file).
3. List the faces of the final node.
4. Ask for the sensitivity of the final volume to W.
5. Edit W to 140 and evaluate again. Report the new volume interval.
6. Tessellate the final node to `/home/jesse/g1/bracket.obj`.

Use the design file `/home/jesse/g1/bracket.bcd`.

Finish with a short report: the final design text, both volume intervals, the
bounding box and the mesh path.
