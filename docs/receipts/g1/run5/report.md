# G1 run 5 (2026-10-05) — brief B again, final C06 binary

Binary: the C06 closeout build of `src/c06/cli.bend`, sha256
`5edb003628f113a12bf55c3ed0afabb0b046435ffb9b825fa1ea4fa3dfd583fc`. It
adds `rotate`, `zone`, parameter-zone validation, `unknown-op` and
cache reuse in `sens` to the run 2–4 binary. Transport: the MCP server
over stdio via `tools/mcp/mcpc.mjs`. Brief: `brief-b.md` (`../brief-b.md`
with this run's log path). A fresh general-purpose subagent with no prior
context ran it: 8 tool uses, 53 s. Grader `tools/grade/g1b.py`: verdict
PASS, no failed checks (`grade.json`).

The agent's only rejection was the one the brief asks for:
`node 3: error invalid-input | pocket @ node 3 | why: depth-reaches-opposite-face | fix: use a smaller depth or a through cut`,
then `rejected: the design was not changed`. A `show` afterwards confirmed
Q = 4. No syntax or intent errors.

Results: L = 90 volume [29566.63675994598, 29566.636760038786]; d_volume/dL
= 300; L = 120 volume [38566.636759935805, 38566.63676004896], containing
the exact 38566.63675999238; mesh 396 triangles, watertight, genus 2, bbox
exactly 0..150 x 0..30 x 0..10. The volume intervals are identical to
run 3. The agent placed the pocket with a different but equivalent
expression (`S/2 + L/2 - K/2` rather than `(L + S - K)/2`).

G1 summary: five runs by five independent agents. Brief A passed three
times (runs 1, 2, 4) and brief B twice (runs 3, 5); runs 2–5 went
through MCP. Every run was graded PASS by code independent of the
kernel's checks.
