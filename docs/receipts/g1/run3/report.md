# G1 run 3 (2026-10-05) — brief B (strap bracket), over MCP

Same binary and transport as run 2 (`../run2/report.md`). Brief:
`../brief-b.md`, a different part from brief A: an obround strap with two
end holes and a blind rectangular pocket. It adds a deliberate failure
(pocket deeper than the plate). Grader: `tools/grade/g1b.py`, verdict PASS,
no failed checks (`grade.json`).

Agent: a fresh general-purpose subagent with no prior context, given the
brief verbatim. 8 tool uses, 54 s.

Results, re-derived by the grader:

- L = 90: volume [29566.63675994598, 29566.636760038786]; bbox 120 x 30 x 10;
  13 faces; genus 2.
- Sensitivity to L: d_volume = 300 (S x T).
- `(param Q 12)` was rejected:
  `node 3: error invalid-input | pocket @ node 3 | why: depth-reaches-opposite-face | fix: use a smaller depth or a through cut`,
  then `rejected: the design was not changed`. A later `show` still had
  Q = 4.
- L = 120: volume [38566.636759935805, 38566.63676004896], containing the
  exact 38566.63675999238.
- Mesh `strap.obj`: 396 triangles, watertight, Euler characteristic -2
  (genus 2), bbox exactly 0..150 x 0..30 x 0..10, volume -0.11 % (chordal).

Defect found by runs 2 and 3: both agents first passed `edits` as one
string. The server spread that string into single characters, and the CLI
rejected the result as bad syntax. Both agents recovered by sending an
array. The server now accepts a string of several edits or an array
(`tools/mcp/bendcad-mcp.mjs`), and E2E `mcp.session` checks
`edits_as_one_string`. Run 4 repeats brief A on the fixed server.
