# G2 brief: external gear pump

`ROOT` below is the BendCAD checkout named in your instructions; use
it with forward slashes from Git Bash (`/c/dev/...`) or Windows tools
(`C:/dev/...`).

You are the design agent for gate G2. The gate itself is
`ROOT/docs/gates/g2-gear-pump.md`; its doctrine is
`ROOT/docs/gates/README.md`. Read both in full before anything
else. They define the pump, the fits, the sizing work, the build
requirements and what a pass is. This file only says how to work.

## Reaching BendCAD

BendCAD is reachable only through its MCP tools. Call them from Bash with

    BENDCAD_BIN=/home/jesse/bc/bendcad-g2 BENDCAD_TIMEOUT_MS=3600000 \
      BENDCAD_LOG='ROOT/docs/receipts/g2/RUN/calls.jsonl' \
      node ROOT/tools/mcp/mcpc.mjs TOOL 'JSON-ARGUMENTS'

where `RUN` is the run directory you were given. `node
ROOT/tools/mcp/mcpc.mjs --list` lists the tools. Call the
`reference` tool first and read it in full, including the sections on
booleans, assemblies, semantic PMI, and materials, threads and fits.

Keep every design and output file under `/home/jesse/g2/` (a WSL path).
Create it with
`MSYS_NO_PATHCONV=1 wsl.exe -e mkdir -p /home/jesse/g2/parts /home/jesse/g2/export`.
Under Git Bash, prefix every `wsl.exe` call with `MSYS_NO_PATHCONV=1`.
The Windows command line holds about 32,000 characters, so apply a long
gear profile in its own `apply` call. Some queries take minutes; let them
finish.

You may use Python only to compute numbers. All geometry is built by
BendCAD. `python ROOT/docs/receipts/g2/gear.py Z MODULE [SHIFT_X]
[PHASE_RAD] [BACKLASH_MM] [ADDENDUM_COEFF] [FLANK_POINTS]` prints the
involute profile of a Z-tooth spur gear (20 degree pressure angle) as a
BendCAD `(path ...)` centred at the origin, with one tooth centred at angle
PHASE. Points run from the root circle `r − m(1.25 − x)` to the tip circle
`r + m(ADDENDUM_COEFF + x)`; BACKLASH thins each tooth at the reference
circle. Choose and justify module, tooth count, shift, backlash and
centre distance yourself.

## Kernel limits

If BendCAD cannot build, certify or export something the gate requires,
do not change the design to get around it. Stop that line of work and
record a KERNEL-BLOCKER in your report. Each blocker states what the
design needs, the exact tool call, the exact output, and why no
compliant design avoids the need. Then continue with every part of the
pump that does not depend on it. A blocker is a valid finding; a design
quietly bent to fit the kernel is a failed run.

## Deliverables in `ROOT/docs/receipts/g2/RUN/`

- `report.md`: the design document the gate asks for, every number
  labelled MEASURED (with citation), COMPUTED (assumptions stated) or
  PROJECTED; the mate scheme; every certified fit, clearance and mass with
  the tool output that certifies it; the risk register; the
  KERNEL-BLOCKER list.
- `parts.txt`: every part with its design file, node, material grade and
  certified mass.
- Exports in `/home/jesse/g2/export/`: STEP AP242 of every part and of
  the assembly, and STL at manufacturing quality, named after the part.
- The design files themselves stay in `/home/jesse/g2/parts/`.
