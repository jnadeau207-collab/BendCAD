# G1 brief B: strap mounting bracket

You are designing a part with BendCAD, a CAD kernel you can reach only through
its MCP server. Call MCP tools from the Bash tool with the stdio client:

    MSYS_NO_PATHCONV=1 BENDCAD_LOG=C:/dev/BendCAD/docs/receipts/g1/run5/calls.jsonl node C:/dev/BendCAD/tools/mcp/mcpc.mjs TOOL 'JSON-ARGUMENTS'

`node C:/dev/BendCAD/tools/mcp/mcpc.mjs --list` lists the tools and their
arguments (the JSON is an object with those keys). Start with the `reference`
tool. Use no other command and do not read, search or open any file:
everything you need comes from the tools. Use the design file
`/home/jesse/g1b/strap.bcd`.

Design a strap bracket, fully parameterized:

- Parameters (millimetres): centre distance L = 90, strap width S = 30,
  thickness T = 10, end-hole diameter D = 12, pocket length K = 40, pocket
  width M = 14, pocket depth Q = 4.
- Plate: an obround (stadium) outline of thickness T on z = 0: two
  semicircular ends of diameter S whose centres are (S/2, S/2) and
  (S/2 + L, S/2), joined by straight sides, so x is in [0, L + S] and y in
  [0, S].
- A through hole of diameter D at each end centre. The holes must follow L.
- A blind rectangular pocket K x M, depth Q, in the top face, centred on the
  strap.
- Declare a truthful intent for every operation.

Then:

1. Evaluate and report the final node's volume interval and bounding box.
2. Ask for the sensitivity of the final volume to L.
3. Try to make the pocket deeper than the plate (Q = 12) and report what the
   kernel says. Confirm the design did not change.
4. Edit L to 120 and evaluate again. Report the new volume interval.
5. Tessellate the final node to `/home/jesse/g1b/strap.obj`.

Finish with a short report: the final design text, both volume intervals, the
bounding box, the sensitivity, the rejection you received and the mesh path.
Also list every error or rejection you received, verbatim, and what you changed
in response.
