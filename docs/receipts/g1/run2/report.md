# G1 run 2 (2026-10-05) — over MCP, final C06 binary

Binary: `~/bc/bendcad` built from `src/c06/cli.bend` at the C06 closeout
tree, sha256 `36dfc048cd87e0bc4eab2f918ca06a94bf3806bf0c2ac1b620028999fa690ea8`.

Transport: the MCP server `tools/mcp/bendcad-mcp.mjs` over stdio JSON-RPC
(initialize, tools/list, tools/call), driven by `tools/mcp/mcpc.mjs`, a
one-call stdio client, from the agent's shell. Every kernel call the server
made is in `calls.jsonl` (arguments, exit status, full output; the
`reference` tool reads the language file and is not a kernel call).

Agent: a fresh general-purpose subagent with no prior context, given
`brief-mcp.md` verbatim plus "use only the MCP client command; read no
file". 7 tool uses, 50 s.

Agent's account of errors, verbatim: its first `apply` passed all edits as
one string and got
`error invalid-input | apply | why: edits must be (param NAME NOM [LO HI]), (node ID OP INTENT) or (delete ID) | fix: correct the edit syntax`;
it resent them as a JSON array, one edit per string, and the same content
committed. No geometry or intent was rejected.

Agent-reported results (all re-derived by the grader, `grade.json`,
verdict PASS, no failed checks):

- W = 120: volume [83301.23811420775, 83301.23811436284]; bbox 120 x 80 x 20
  with linear uncertainty 2.13e-13; 17 faces; genus 5.
- `show` then a second evaluate: identical.
- Sensitivity to W: d_volume = 640 (H x T), d_area = 176, d_xmax = 1.
- W = 140: volume [96101.23811419433, 96101.23811437626], containing the
  exact 96101.23811428528.
- Mesh `bracket.obj`: 912 triangles, watertight, no non-manifold or
  unmatched edges, Euler characteristic -8 (genus 5), bbox exactly
  0..140 x 0..80 x 0..20, volume 96028.31 (-0.08 %, chordal).

Tool sequence (from `calls.jsonl`): new, apply (rejected), apply, eval,
show, eval, faces, sens, apply (W = 140), eval, tess, show.

Files: `brief-mcp.md`, `calls.jsonl`, `bracket.bcd`, `bracket.obj`,
`grade.json`. Run 1 (CLI transport, earlier binary) is in `../run1/`.
The two agents wrote identical design files and got identical volume
intervals. The meshes differ in bytes: planar faces have been
ear-clipped by `ear.bend` since `a475bd7`, after run 1. Both meshes have
912 triangles, are watertight and have genus 5.
