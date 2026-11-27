# After the kernel: the BendCAD workbench

This is how BendCAD is finished once the kernel meets `docs/finish.md`. That file decides when the kernel is done. This one is the product phase that follows: making the kernel usable by a person in a Fusion/Onshape-style Three.js workbench with an AI side panel, without giving up any of the agent-first guarantees. It comes from an external review of `main` at `609384c` (README, `MASTER_PLAN.md`, `AGENTS.md`, `docs/finish.md`, `docs/gates/g6a-robustness.md`, `docs/evaluation-2026-11-11.md`, `src/c02` to `src/c16`, `src/k1`, `tools/mcp/bendcad-mcp.mjs` and `viewer/`).

## 1. Kernel review: what makes BendCAD unusual, and where it hurts

BendCAD is a clean-room B-Rep CAD kernel written in a pinned 64-bit fork of Bend (`BEND_PIN`: `jnadeau207-collab/bend@a4d17ace...`), compiled through a split C build to native parallel binaries. It is paired with Lean 4.34.0 law proofs (24/24 packages, 163/163 mutation-tested laws in `docs/evaluation-2026-11-11.md`) and tested against OCCT/`build123d` strictly as an external oracle.

### What is genuinely strong

- **True B-Rep and exact predicates** (`src/c02/ops.bend`, `src/c03/types.bend`, `src/c04/types.bend`): generational-index topology (`HVertex` to `HSolid`); analytic surfaces, bicubic Bezier patches (`BezP`), NURBS (`Nurb`) and `Helicoid` threads; Shewchuk-style adaptive `orient2d`/`orient3d`/`incircle`/`insphere` with an exact expansion fallback (`E.Ex`); per-face measured geometric slack (`slv`, `sla`) instead of one magic epsilon.
- **Agent-first guarantees** (`src/c06/model.bend`, `src/c06/build.bend`, `tools/mcp/language.md`):
  - **Checked intent:** every node carries `(intent ...)` (`M_create`/`M_add`/`M_remove`/`M_same` plus face, feature, shell and hole counts), so silent topology flips are refused.
  - **Durable semantic naming:** `Fn{ nd, k, role, i, j }` gives stable names such as `n1.c0.top`, `n1.c0.wall.0.1`, `n1.cav.0.0.0`, with `.p<piece>` for splits.
  - **Engineering-native types:** tolerance zones (`Dim` with ISO 286 classes), certified interval math (`I.I`), DFM (`make`), standards checks (`std`), clearances (`near`), FEM modes and spin (`k3`), and 40 CLI verbs (`cmd_code`) exposed through `bendcad-mcp.mjs`.
  - **Incremental evaluation and a warm daemon:** `ev_part` caches node results (`CE`) by dependency hash, and `bendcad serve` keeps the `List<SE>` caches in memory (about 1.9 s to 4.6 s on warm brief edits per `docs/finish.md`).

### The viewer already exists (`viewer/`)

BendCAD is not starting from zero on visualisation. `viewer/` (`index.html`, `app.js`, `mesh-worker.js`, `studio.js`, `explode.js`, `live.mjs`) already has:

- A Three.js r185 viewport with `EffectComposer` (`GTAOPass`, `OutlinePass`), stencil-capped section planes, exploded view, rotor animation, measurement, and a `FloatType` GPU face-picking render target (`pickRT`) encoding `pid * 65536.0 + vf + 1.0` and world XYZ from the OBJ `g f<fi> <kind>` face groups.
- A live bridge (`viewer/live.mjs`) driving the warm `bendcad serve` daemon (`GET /api/doc`, `POST /api/edit`, `GET /api/mesh/:id.obj`, `GET /api/checks/:id`, `GET /api/near/:id`), with editable `(param ...)` inputs, a feature node list, and live DFM, standards and clearance checks.

**Why it still feels agent-only:** today `viewer/` is a live inspector and parameter tweaker, not a CAD authoring tool. A person can inspect faces and change existing parameter values, but cannot sketch, select faces or edges to start features, drag 3D handles, edit the feature tree, undo and redo, or talk to an AI in context inside the viewport.

## 2. Kernel gaps that block interactive human CAD

Before or alongside the UI work, five kernel gaps in the current code stand in the way:

1. **Close the boolean refusal gap (89.0% to 99%+) and build K5** (`docs/gates/g6a-robustness.md`). On r58 over the 150-seed fuzz corpus, 382 of 429 (89.0%) commit (p95 11.7 s); the 47 refusals are led by `edge-face-uncertain` (17), c04 coplanar embedding (6) and K1 solver codes (42, 72, 93, 82, 40). People will not tolerate one boolean in nine refusing during exploratory modelling. Completing K5 (the face-local general intersection solver) and resolving the `edge-face-uncertain` and coplanar embedding cases is the first unlock.
2. **Interactive tessellation speed and slivers** (`src/c06/tess.bend`, `docs/evaluation-2026-11-11.md`). `perf.holes100` took 880 s against a 5 s budget, and 431 zero-area slivers remained on the K4 blade. No interactive viewport survives multi-minute tessellation stalls. `cli.bend`'s `tess` already takes `[0|1|2|3] [CHORD] [ANGLE] [MAXTRIS] [display|manufacturing]` and `eval` already skips unchanged nodes: `live.mjs` should use fast coarse display tessellation (`tess NODE OUT 0 ... display`) for interactive edits and run fine or manufacturing meshing asynchronously or on export, and stream binary triangle and edge buffers (or glTF) instead of ASCII OBJ parsed in `mesh-worker.js`.
3. **Lift the axis-aligned plane restriction in `frame_of`** (`src/c06/model.bend`). `frame_of(Face)` requires `dir_ax(u) && dir_ax(y) && dir_ax(n)`, and `unit_ax` admits only 0 or ±1 components, so nothing can be sketched, padded, pocketed or drilled on an angled, drafted or rotated planar face. Arbitrary orthonormal `(o, u, y, n)` frames, or explicit datum planes, are required for Fusion/Onshape workflows.
4. **Wire the 2D constraint solver (`src/c05/solve.bend`) into `.bcd` features.** `src/c05/solve.bend` has 18 constraint kinds (`K_coinc` to `K_same`), a DOF count and `Sv_conflict{ids, cert}`, but `src/c06/model.bend` never imports it: `O_prism`, `O_pad` and `O_pocket` take only explicit `F.Region` formulas. A first-class constrained `(sketch ...)` node, with c05 solving constraints into an `F.Region` inside the kernel, turns c05 into a real parametric sketcher.
5. **Generalise `O_fillet`, `O_fillet_e`, `O_chamfer` and `O_draft` beyond hard-coded base ops** (`src/c06/model.bend`). `O_echamf` and `O_lchamf` use durable face names, but `O_fillet`, `O_fillet_e`, `O_chamfer` and `O_draft` match on `nd_op(ns, base)` (`fi_box`, `fi_cyl` and so on) and refuse general B-rep edges (`fillet-base-not-admitted`; brief B7 still needs edge-loop fillets). Durable edge identifiers (for example the sorted pair of adjacent face names, `edge(faceA, faceB)`) unlock click-an-edge fillets and chamfers in the viewport.

## 3. Architecture: `viewer/` as a Three.js workbench with an AI side panel

Do not replace `viewer/`; evolve it in three layers that keep the agent-first guarantees (`apply`, intent, `diag`, `faces`) for people and agents alike:

```
+--------------------------------------------------------------------+
| Browser workbench (Three.js r185, evolved viewer/)                 |
|  Left: parametric feature tree, sketch and operation toolbar       |
|  Centre: 3D viewport (pickRT faces/edges, 2D sketch plane, gizmos) |
|  Right: inspector, DFM checks, AI assistant side panel             |
+-------------------------------^------------------------------------+
                                | HTTP + SSE/WS (shared revision and selection context)
+-------------------------------v------------------------------------+
| Unified workspace bridge (evolved viewer/live.mjs + MCP bridge)    |
|  - one .bcd document lock and an undo/redo snapshot stack          |
|  - pushes live reloads on file or MCP changes (fs.watch + SSE)     |
|  - connects to ONE shared `bendcad serve` warm daemon              |
|  - hosts the AI agent loop (bendcad-mcp tools + viewport context)  |
+-------------------------------^------------------------------------+
                                | TCP (one warm cache, List<SE>)
+-------------------------------v------------------------------------+
| BendCAD kernel (`bendcad serve`)                                   |
+--------------------------------------------------------------------+
```

### Step A: the kernel-bridge protocol (`tess`, `faces`, `live.mjs`)

1. **One `bendcad serve` for `bendcad-mcp.mjs` and `live.mjs`, with push sync.** Today `bendcad-mcp.mjs` defaults to port 7790 and `live.mjs` to `KPORT = PORT + 1000` (9790), and `live.mjs` has no push channel to the browser. Route both through one `bendcad serve` (sharing its node cache), watch the `.bcd` and emit SSE or WebSocket events from `live.mjs` whenever the person or the AI commits an edit, and guard `.bcd` writes with one mutex or queue plus an in-memory and on-disk undo/redo ring of `.bcd` snapshots.
2. **Full topology mapping: face index to durable `Fn` name and frame, plus edge and vertex ids.** `tess.bend` emits `g f<fi> <kind>` (index and surface kind) and untagged `e` polylines, and `liveProps()` in `viewer/app.js` drops `st.face` in live mode (`if (live.on && ps[0].node != null) return liveProps(...)`).
   - Bridge first, no kernel rebuild: have `live.mjs` call `faces <node> -f` with `tess` and return a `faceMeta` array indexed by `fi` (`name: "n1.c0.top"`, `kind`, `loops`, `frame: { o, x, y, n }`). A click on any triangle in `pickRT` then resolves to the exact kernel face name and planar sketch frame.
   - Then the kernel: emit `g e<ei> <faceA> <faceB>` edge groups in `tess.bend` and a binary buffer endpoint (`/api/mesh/:id.bin`), so the viewport can render and pick B-rep edges (`LineSegments2` or a GPU edge-id pass) for fillets, chamfers and sketch projections, and cache unchanged node meshes by `CE` hash instead of reloading the whole scene on every edit.

### Step B: human CAD modelling in the viewport (`viewer/`)

1. **Selection modes: part, face, edge, vertex.** Extend `st.selMode` beyond `'part' | 'face'` to `'edge' | 'vertex'`. Show `st.face` in `liveProps` with its durable name (`n1.c0.top`), surface type and area, and contextual actions: Sketch on face, Pad, Pocket, Hole, Chamfer edges.
2. **Feature tree editing and a rollback bar** (`#live` / `#tree`). Replace the flat parts-only `liveScene()` list with the full `.bcd` node DAG (nodes, params, parent and child links). Node actions: edit the node's form or fields, delete (`(delete ID)`), reorder or insert before and after, and rollback preview (temporarily showing `tess <earlier_node_id>` to inspect intermediate solids, as Fusion's timeline does).
3. **2D sketcher on a selected face or datum plane.** On Sketch on face (using the `o, x, y, n` frame from `faces -f`) or a datum plane (XY, YZ, XZ):
   - tween an orthographic camera to look along `-n` and lock orbit;
   - draw a 2D construction plane mapped to world coordinates `(o + u*x + v*y)`, with snapping to the origin and to projected B-rep edges, and tools for line, rectangle, circle, tangent arc, trim, and dimensions and constraints;
   - solve constraints live (a small `solve_sketch` verb on `src/c05/solve.bend`, or c05 constraints stored in the node), showing the DOF count, a fully-constrained state, or `Sv_conflict` highlights;
   - on Finish sketch, commit or prefill a `prism`, `pad` or `pocket` node.
4. **3D gizmos and client-side ghost previews** (needed at 0.5 s to 5 s kernel latency). `apply` is atomic and takes hundreds of milliseconds to seconds, so dragging must never call `apply` on every `mousemove`. Mount `TransformControls` or custom extrude arrows on the selected face frame or transform origin:
   - while dragging, preview a translucent client-side extrusion, cylinder or transform ghost at 60 FPS with a live dimension badge;
   - on `pointerup` or Enter, generate the node form and its `(intent ...)` (material mode from the operation: `add` for pad, `remove` for pocket and hole), `POST /api/edit`, and replace the ghost with the certified B-rep mesh, or show the kernel's `why / fix` diagnostic inline when it refuses.

### Step C: the AI assistant side panel as a co-pilot

The kernel already speaks structured engineering facts (face names, tolerances, intent, `diag`, `make`, `std`, `sens`, `near`). Wire the side panel (`#acol` in `viewer/index.html`) into the live workbench state:

1. **Selection context on every prompt.** For "add 4 M4 counterbored mounting holes around this flange and fillet the outer edge 2 mm", attach a compact JSON context: the current `.bcd` (`show` and `eval` status); the active selection (`selectedPart: node 4`, `selectedFaces: ["n4.c0.top"]` with surface kind and frame, `selectedEdges`, `lastMeasureDist`); and the active `#checks` (`std`, `make`, `near` failures).
2. **Tools over the same warm session.** The side panel's model calls the `bendcad-mcp.mjs` tools routed through `live.mjs`'s queue, not a separate CLI process: `reference`, `apply`, `faces`, `evaluate`, `diagnose`, `sensitivity`, `zone`, `std`, `make`, `clearance` and the rest.
3. **Person in the loop: preview, verification, shared undo.**
   - Every committed AI `apply` streams an SSE update to the viewport, highlighting new or changed faces and nodes and refreshing `#checks`.
   - Because the kernel answers `error KIND | what @ where | why | fix`, the AI corrects refused `apply` calls before showing the final edit, or explains why geometry or DFM refused the request.
   - Each AI turn is one entry in `live.mjs`'s undo stack, shown as a card ("Added node 7 (sholes, M4 clearance) · make mill: pass · [Revert] [Inspect faces]").
   - AI replies can carry references such as `[n4.c0.top]` or `[corner 12]` (from `make` and `std`) that move the camera, highlight the face or part through `pickRT` and `OutlinePass`, and open its inspector card.

## Build order (smallest high-impact increments)

1. Put `live.mjs` and `bendcad-mcp.mjs` on one `bendcad serve`, add SSE push and `.bcd` snapshot undo/redo, and wire `faces -f` into `/api/doc` so `st.face` shows durable face names in live mode.
2. Add the AI side panel (`#acol`) in `viewer/`, passing live face selections and `#checks` into MCP tool calls, with SSE refresh and one-click revert.
3. Add feature creation dialogs and `TransformControls` ghost previews (`box`, `cyl`, `pad`, `pocket`, `holes`, `sholes`, `echamf`/`lchamf`, `move`/`rot`, booleans), plus node delete and rollback in `#live`.
4. Upgrade the kernel and the sketcher together: lift `frame_of`'s `dir_ax` limit, wire `c05/solve.bend` into `.bcd` sketches, add durable edge ids (`g e<ei>`) and binary preset-0 streaming tessellation, and build the 2D orthographic sketch overlay.
