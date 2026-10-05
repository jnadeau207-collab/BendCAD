# G1 brief: parameterized mounting bracket

You are designing a part with BendCAD, a CAD kernel you can reach only through
its MCP server. Call MCP tools from the Bash tool with the stdio client:

    MSYS_NO_PATHCONV=1 BENDCAD_LOG=C:/dev/BendCAD/docs/receipts/g1/run2/calls.jsonl node C:/dev/BendCAD/tools/mcp/mcpc.mjs TOOL 'JSON-ARGUMENTS'

`node C:/dev/BendCAD/tools/mcp/mcpc.mjs --list` lists the tools and their
arguments (the JSON is an object with those keys). Start with the `reference` tool (`... mcpc.mjs reference`). Use no
other command and do not read, search or open any file: everything you need
comes from the tools. Keep every design file under `/home/jesse/g1/`.

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
