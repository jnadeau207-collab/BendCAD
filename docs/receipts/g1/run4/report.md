# G1 run 4 (2026-10-05) — brief A again, fixed MCP server

Same binary, transport and brief as run 2, after the `edits` fix recorded
in run 3. Fresh general-purpose subagent, no prior context; 6 tool uses,
44 s. Grader `tools/grade/g1.py`: verdict PASS, no failed checks
(`grade.json`).

The agent received no error or rejection. Every intent matched on the
first apply. Tool sequence from `calls.jsonl`: new, apply, eval, show,
eval, faces, sens, apply (W = 140), eval, tess, show.

Repeatability: `bracket.bcd` is identical to run 2's, and `bracket.obj` is
byte-identical to run 2's (912 triangles, watertight, genus 5). W = 120
volume [83301.23811420775, 83301.23811436284]; W = 140 volume
[96101.23811419433, 96101.23811437626], containing the exact
96101.23811428528.

G1 summary: brief A passed three times (runs 1, 2, 4) by three independent
agents over two transports (CLI, then MCP), and brief B passed once
(run 3). The design text was the same in all three brief-A runs.
