# Aethalgard

**Professional CAD-to-manufacturing software with an accessibility layer for normal 3D-printer users.**

Aethalgard is a desktop CAD-to-manufacturing system for real, printable,
dimension-accurate work. Its direct-manipulation surface makes professional
capabilities accessible to normal 3D-printer users, while the full product
targets Fusion parity or better across the stack. Two ideas define it:

1. **A Squarespace-grade direct-manipulation accessibility layer.** Click, drag,
   drop, resize. On-object handles with clickable dimension callouts. Snapping
   that explains itself. Professional sketch planes and authored constraints,
   a light operation timeline, and a searchable command surface coexist with
   the direct surface; none is reduced to a shortcut-only path.

2. **A local agentic AI, packaged in the box.** You download Aethalgard, you get the model. It runs on your machine, offline, unmetered. The agent doesn't write code — it drives the same structured operation graph the drag-drop UI edits, one validated operation at a time, with kernel feedback after every step. Its edits are ordinary editable objects in the same undo stack as yours.

The output is what slicers actually want: 3MF first, STEP for the pros.

## Status

The production runtime is well underway. Core document durability, native
geometry, interchange/preflight, agent orchestration, viewport foundations,
and a broad UI system exist as tested packages. CAP-137's sketch system is
finished on its exact implementation tip, but the shared shell currently has
a blocking regression in menus and bottom viewport pills. See
[the current defect ledger](./DEFECT_LEDGER_2026-08-08.md) and the shell repair
packet; do not infer product completion from package-level green tests.

- **[MASTER_PLAN.md](./MASTER_PLAN.md)** — the authoritative engineering blueprint for the complete modeling system, direct-manipulation editor, local agent, manufacturing pipeline, durable application architecture, integration gates, and implementation tranches.
- **[RESEARCH.md](./RESEARCH.md)** — the founding concept research (July 2026): market gap, architecture direction, geometry stack, local model candidates, UX doctrine, packaging, print pipeline, risks, and initial phasing.
- **[docs/plan/](./docs/plan/)** — detailed implementation references across geometry, design, AI, application shell, viewport, and print pipeline. Use them as engineering input while the working product remains authoritative.

## The one-paragraph pitch

Millions of people own 3D printers; only a few hundred thousand can design for
them. Aethalgard combines **Fusion parity or better across the full
CAD-to-manufacturing stack** with a Squarespace-grade direct-manipulation
accessibility layer and local agentic AI. The direct surface lowers the entry
bar without narrowing the professional product. That's Aethalgard.
