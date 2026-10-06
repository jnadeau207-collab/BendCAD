# G1 run 1 (2026-10-05)

Transport: BendCAD CLI through `/home/jesse/bc/bc`, a wrapper that logs every
call to `calls.jsonl` (arguments, exit status, full output). The agent was
a fresh subagent with no prior context, given `brief-cli.md` and told to use
only the CLI. Runs 2–5 use the same kind of agent over the MCP server.

Agent: fresh general-purpose subagent, 5 tool uses, 38 s. Its final report
follows verbatim in substance: every node and intent was accepted on the first
try; the only error was Git Bash rewriting `/home/jesse/bc/bc` into a Windows
path, fixed with `MSYS_NO_PATHCONV=1`.

Results reported by the agent and checked by `tools/grade/g1.py`
(`grade.json`, verdict PASS):

- W = 120: volume [83301.23811420775, 83301.23811436284]; bbox 0..120 x
  0..80 x 0..20; 17 faces, genus 5.
- dV/dW = 640 (H x T); W = 140: volume [96101.23811419433,
  96101.23811437626], which contains the exact 96101.23811428528.
- Mesh `bracket.obj`: 912 triangles, watertight, consistently oriented,
  Euler characteristic -8 (genus 5), bbox exactly 0..140 x 0..80 x 0..20,
  volume 96028.31 (-0.08 %, chordal).
