import { createHash, randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";

import {
  kernelProtocolVersion,
  kernelRequestSchema,
  operationSchema,
  wireOperationSchema,
  type CreateBoxOperation,
  type Operation,
} from "@aeth/geometry-contracts";
import { afterEach, expect, it } from "vitest";

import { KernelSupervisor } from "../src/index.js";
import { nativeDescribe } from "./native-gate.js";
import { opFacesNormalZ, opQuery } from "./wire-refs.js";

/**
 * Catalog wave-1 STAGING PINS, updated for the native executor wave
 * (docs/design/2026-07-19-native-catalog-wave1.md §4; TS staging contract in
 * docs/design/2026-07-19-catalog-ts-contracts.md §5). `stagedOperationTypes`
 * is UNCHANGED — enablement is a deliberate later act — but the kernel-side
 * boundary moved per type and this suite pins exactly where it now sits:
 *
 * - `shell` (closed hollow): REAL geometry over `evaluate_document` — the
 *   executor landed, carries no ref slot, and hollows a box to its analytic
 *   volume. `shell` WITH `openFaces` still fails closed, but the boundary MOVED
 *   with N6 slice C part 3: `evaluate_document` now threads the naming registry
 *   for any selector-bearing document, so the openFaces ref RESOLVES on-kernel
 *   and the refusal is now the still-deferred ByJoin execution (the pinned
 *   BRepOffsetAPI_MakeThickSolid history surface is unverified for topology
 *   naming), attributed UNSUPPORTED_OPERATION.
 * - `datum_plane` / `datum_axis`: executors landed (all modes, natively
 *   proven in aeth-catalog-wave1-test) but every mode carries a required ref
 *   and the minted synthetic entity lives in the registry. N6 slice C part 3
 *   now threads that registry through `evaluate_document`, so these ops REACH
 *   their executors and RESOLVE their refs on-kernel. The staging refs here are
 *   deliberately under-specified (every planar face / every vertex), so the
 *   resolver refuses them E_SEL_AMBIGUOUS (REFERENCE_AMBIGUOUS) rather than pick
 *   one — the no-silent-misreference invariant, now proven end-to-end. That
 *   ambiguity case STAYS. CAP-014 added its counterpart beside it: a UNIQUE
 *   datum ref that mints real geometry and is consumed by a mirror, plus the
 *   `query`-method refusal that keeps body-less datum entities off a wire whose
 *   schema requires `bodyId`.
 * - `mirror` / `pattern_linear` / `pattern_circular`: executors LANDED (the
 *   "no executor yet" claim here expired with catalog wave 2). The sibling
 *   case below pins that they run, and CAP-014 adds a mirror that consumes a
 *   DATUM plane resolved from a unique ref.
 *
 * Native-gated exactly like the sibling suites via the shared loud-fail
 * `nativeDescribe()`: a missing AETH_KERNEL_HOST_PATH FAILS at collection
 * (not a silent skip) unless AETH_ALLOW_MISSING_KERNEL=1 opts out
 * (`pnpm native:test` sets the host path + OCCT runtime env).
 */
const executable = process.env.AETH_KERNEL_HOST_PATH;
const describeNative = nativeDescribe();
const supervisors: KernelSupervisor[] = [];

const occtManifestSha256 = createHash("sha256")
  .update(
    readFileSync(
      new URL(
        "../../../native/third_party/occt.manifest.json",
        import.meta.url,
      ),
    ),
  )
  .digest("hex");

function nativeEnvironment(): Record<string, string> {
  const environment: Record<string, string> = {};
  for (const name of [
    "CASROOT",
    "CSF_OCCTResourcePath",
    "LD_LIBRARY_PATH",
    "DYLD_LIBRARY_PATH",
    "PATH",
  ]) {
    const value = process.env[name];
    if (value) environment[name] = value;
  }
  return environment;
}

async function startSupervisor(): Promise<KernelSupervisor> {
  if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
  const supervisor = new KernelSupervisor({
    executable,
    requestTimeoutMs: 120_000,
    environment: nativeEnvironment(),
  });
  supervisors.push(supervisor);
  const build = await supervisor.start();
  expect(build.occtManifestSha256).toBe(occtManifestSha256);
  return supervisor;
}

afterEach(async () => {
  for (const supervisor of supervisors.splice(0)) {
    await supervisor.stop();
  }
});

const metadata = {
  createdAt: "2026-07-19T09:00:00.000Z",
  createdBy: { kind: "user" },
} as const;

function createBox(): CreateBoxOperation {
  return {
    id: randomUUID() as CreateBoxOperation["id"],
    type: "create_box",
    schemaVersion: 1,
    name: "Catalog wave 1 target",
    outputBodyId: randomUUID() as CreateBoxOperation["outputBodyId"],
    parameters: {
      width: 60,
      depth: 40,
      height: 20,
      placement: {
        origin: [0, 0, 0],
        zDirection: [0, 0, 1],
        xDirection: [1, 0, 0],
      },
    },
    metadata,
  };
}

const shared = { schemaVersion: 1, metadata } as const;

function createShell(
  box: CreateBoxOperation,
  parameters: Record<string, unknown>,
): Operation {
  // Validated against the WIRE schema (N6 slice C): a closed shell carries no
  // ref slot and validates identically to the persisted schema, while the
  // `openFaces` staging pin ships the wire `{ast}` the kernel actually receives.
  return wireOperationSchema.parse({
    ...shared,
    id: randomUUID(),
    type: "shell",
    name: "Hollow the box",
    outputBodyId: randomUUID(),
    parameters: { targetOperationId: box.id, ...parameters },
  });
}

async function evaluate(
  supervisor: KernelSupervisor,
  operations: readonly Operation[],
) {
  return supervisor.client.request(
    kernelRequestSchema.parse({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      documentId: randomUUID(),
      revision: 1,
      method: "evaluate_document",
      operations,
    }),
  );
}

describeNative("catalog wave 1 kernel boundary", () => {
  it("hollows a box with the shell executor (closed hollow, inward)", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const shell = createShell(box, { thickness: 1.6 });
    const response = await evaluate(supervisor, [box, shell]);
    expect(response.ok, "shell must evaluate for real now").toBe(true);
    if (!response.ok || response.result.type !== "evaluation") return;
    expect(response.result.bodies.map((body) => body.operationId)).toEqual([
      shell.id,
    ]);
    const [body] = response.result.bodies;
    // Outer 60x40x20 minus the 56.8x36.8x16.8 cavity (1.6 mm walls all round).
    const expectedVolume = 48_000 - 56.8 * 36.8 * 16.8;
    expect(body?.probes.volumeMm3).toBeGreaterThan(expectedVolume - 0.01);
    expect(body?.probes.volumeMm3).toBeLessThan(expectedVolume + 0.01);
    expect(body?.probes.solidCount).toBe(1);
    // One solid bounded by two shells: outer skin + interior cavity.
    expect(body?.probes.shellCount).toBe(2);
    // Inward keeps the outer size (bbox unchanged, z from 0 to 20).
    expect(body?.probes.boundingBoxMm[2]).toBeCloseTo(0, 6);
    expect(body?.probes.boundingBoxMm[5]).toBeCloseTo(20, 6);
  });

  // Fastener-after-snap slice 6 (native): a `bolt` lowers to this exact hole
  // subgraph (document-model `lowerFastenerOperations`); these pins prove the
  // GEOMETRY that lowering targets executes against the real kernel. The radii
  // are `resolveBoltCuts("M3","medium",…)` output: clearance r 1.8 (ISO 273 3.4
  // + 0.2 §6.3 comp), counterbore r 3.25 / depth 4.0 (ISO 4762 6.5 / 3.5+0.5).
  const boltHole = (
    targetOperationId: string,
    radius: number,
    depthPart: Record<string, unknown>,
    origin: [number, number, number] = [0, 0, 20],
  ): Operation =>
    operationSchema.parse({
      ...shared,
      id: randomUUID(),
      type: "hole",
      name: "Bolt cut",
      outputBodyId: randomUUID(),
      parameters: {
        targetOperationId,
        placement: { origin, zDirection: [0, 0, -1] },
        size: { kind: "radius", radius },
        ...depthPart,
      },
    });

  it("executes an M3 bolt clearance bore (lowered to a through hole)", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const clearance = boltHole(box.id, 1.8, { throughAll: true });
    const response = await evaluate(supervisor, [box, clearance]);
    expect(response.ok, "the lowered clearance hole must evaluate").toBe(true);
    if (!response.ok || response.result.type !== "evaluation") return;
    expect(response.result.bodies.map((body) => body.operationId)).toEqual([
      clearance.id,
    ]);
    const [body] = response.result.bodies;
    // 60·40·20 box minus a through Ø3.6 (r 1.8) bore over the 20 mm height.
    const expected = 48_000 - Math.PI * 1.8 ** 2 * 20;
    expect(body?.probes.volumeMm3).toBeCloseTo(expected, 3);
    expect(body?.probes.solidCount).toBe(1);
  });

  it("executes an M3 counterbore bolt (lowered to two chained holes)", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    // Pocket first from the solid top face, then the clearance bore from the
    // pocket FLOOR (z = 20 − 4) — the lowering's counterbore ordering.
    const cbore = boltHole(box.id, 3.25, { depth: 4 });
    const clearance = boltHole(cbore.id, 1.8, { throughAll: true }, [0, 0, 16]);
    const response = await evaluate(supervisor, [box, cbore, clearance]);
    expect(response.ok, "the lowered stepped hole must evaluate").toBe(true);
    if (!response.ok || response.result.type !== "evaluation") return;
    // Only the final body survives (each hole consumes its target).
    expect(response.result.bodies.map((body) => body.operationId)).toEqual([
      clearance.id,
    ]);
    const [body] = response.result.bodies;
    // Box minus the through clearance bore, minus the annular counterbore ring
    // (r 3.25 pocket over the top 4 mm, less the already-removed r 1.8 core).
    const expected =
      48_000 - Math.PI * 1.8 ** 2 * 20 - Math.PI * (3.25 ** 2 - 1.8 ** 2) * 4;
    expect(body?.probes.volumeMm3).toBeCloseTo(expected, 3);
    expect(body?.probes.solidCount).toBe(1);
  });

  it("executes an M3 countersink bolt (lowered to a clearance bore + cone cut)", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    // The document-model lowering: a through clearance bore (into an
    // intermediate body), then a 90° cone cut opening the conical head seat.
    // `resolveBoltCuts("M3","medium","countersink")`: clearance r 1.8, cone top
    // r 3.05 over depth 1.25 (ISO 4762 head Ø5.5 + 0.6 → Ø6.1). The lowering
    // over-extends the cone 1 mm past the entry face for a clean surface cut, so
    // radiusTop 4.05 / height 2.25, and drops its origin 1.25 mm down the drill
    // axis (cone rises +Z from z = 18.75 against the −Z drilling direction).
    const clearance = boltHole(box.id, 1.8, { throughAll: true });
    const cone = operationSchema.parse({
      ...shared,
      id: randomUUID(),
      type: "create_cone",
      name: "Countersink tool",
      outputBodyId: randomUUID(),
      parameters: {
        radiusBottom: 1.8,
        radiusTop: 4.05,
        height: 2.25,
        placement: {
          origin: [0, 0, 18.75],
          zDirection: [0, 0, 1],
          xDirection: [1, 0, 0],
        },
      },
    });
    const cut = operationSchema.parse({
      ...shared,
      id: randomUUID(),
      type: "boolean_combine",
      name: "Countersink cut",
      outputBodyId: randomUUID(),
      parameters: {
        kind: "cut",
        targetOperationId: clearance.id,
        toolOperationId: cone.id,
      },
    });
    const response = await evaluate(supervisor, [box, clearance, cone, cut]);
    expect(response.ok, "the lowered countersink must evaluate").toBe(true);
    if (!response.ok || response.result.type !== "evaluation") return;
    // The cut consumes both the clearance body and the cone tool; one body left.
    expect(response.result.bodies.map((body) => body.operationId)).toEqual([
      cut.id,
    ]);
    const [body] = response.result.bodies;
    // Box minus the through clearance bore, minus the conical seat that the cut
    // adds ABOVE that bore: a frustum from r 1.8 (z 18.75) to r 3.05 (z 20, the
    // face) over the 1.25 mm countersink depth, less the r 1.8 core the bore
    // already removed. The 1 mm cone overshoot above z 20 is air (removes none).
    const frustum =
      ((Math.PI * 1.25) / 3) * (3.05 ** 2 + 3.05 * 1.8 + 1.8 ** 2);
    const boreCoreInSeat = Math.PI * 1.8 ** 2 * 1.25;
    const expected =
      48_000 - Math.PI * 1.8 ** 2 * 20 - (frustum - boreCoreInSeat);
    expect(body?.probes.volumeMm3).toBeCloseTo(expected, 3);
    expect(body?.probes.solidCount).toBe(1);
  });

  // Fastener-after-snap clasp v1 (native): a `clasp` lowers to this beam-box +
  // hook-wedge union subgraph (document-model `lowerFastenerOperations`). These
  // pins prove the ADDITIVE geometry the lowering targets fuses into one solid
  // against the real kernel. Beam t 2 / w 6 / L 12 buried 0.5 mm into the host;
  // hook overhang 1.44 (PETG §8 allowable deflection y = 0.03·12²/(1.5·2)).
  const CLASP_OVERLAP = 0.5;
  const claspBeam = (targetOrigin: [number, number, number]): Operation =>
    operationSchema.parse({
      ...shared,
      id: randomUUID(),
      type: "create_box",
      name: "Clasp beam",
      outputBodyId: randomUUID(),
      parameters: {
        width: 2,
        depth: 6,
        height: 12 + CLASP_OVERLAP,
        placement: {
          origin: [
            targetOrigin[0],
            targetOrigin[1],
            targetOrigin[2] - CLASP_OVERLAP,
          ],
          zDirection: [0, 0, 1],
          xDirection: [1, 0, 0],
        },
      },
    });
  const unionOf = (
    targetOperationId: string,
    toolOperationId: string,
  ): Operation =>
    operationSchema.parse({
      ...shared,
      id: randomUUID(),
      type: "boolean_combine",
      name: "Clasp union",
      outputBodyId: randomUUID(),
      parameters: { kind: "union", targetOperationId, toolOperationId },
    });

  it("unions a clasp beam onto the host as one solid", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const beam = claspBeam([0, 0, 20]);
    const beamUnion = unionOf(box.id, beam.id);
    const response = await evaluate(supervisor, [box, beam, beamUnion]);
    expect(response.ok, "the clasp beam union must evaluate").toBe(true);
    if (!response.ok || response.result.type !== "evaluation") return;
    expect(response.result.bodies.map((body) => body.operationId)).toEqual([
      beamUnion.id,
    ]);
    const [body] = response.result.bodies;
    // 60·40·20 host + the beam OUTSIDE it (t·w·L; the 0.5 mm buried root adds none).
    expect(body?.probes.volumeMm3).toBeCloseTo(48_000 + 2 * 6 * 12, 3);
    expect(body?.probes.solidCount).toBe(1);
    // The beam raises the top from z 20 to z 32 (root on the face + 12 mm length).
    expect(body?.probes.boundingBoxMm[5]).toBeCloseTo(32, 5);
  });

  it("adds the clasp hook barb at the beam tip, still one solid", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const beam = claspBeam([0, 0, 20]);
    const beamUnion = unionOf(box.id, beam.id);
    // Hook barb: a topWidth-0 wedge protruding +x past the beam face, its origin
    // at the beam tip (z 32), one overlap inside the +x face (x 0.5), centered in
    // width (y +3). It runs 1.44/tan(25°) back toward the root.
    const overhang = (0.03 * 12 * 12) / (1.5 * 2);
    const hookZLength = overhang / Math.tan((25 * Math.PI) / 180);
    const hook = operationSchema.parse({
      ...shared,
      id: randomUUID(),
      type: "create_wedge",
      name: "Clasp hook",
      outputBodyId: randomUUID(),
      parameters: {
        width: overhang + CLASP_OVERLAP,
        depth: 6,
        height: hookZLength,
        topWidth: 0,
        placement: {
          origin: [0.5, 3, 32],
          zDirection: [0, 0, -1],
          xDirection: [1, 0, 0],
        },
      },
    });
    const hookUnion = unionOf(beamUnion.id, hook.id);
    const response = await evaluate(supervisor, [
      box,
      beam,
      beamUnion,
      hook,
      hookUnion,
    ]);
    expect(response.ok, "the clasp hook union must evaluate").toBe(true);
    if (!response.ok || response.result.type !== "evaluation") return;
    expect(response.result.bodies.map((body) => body.operationId)).toEqual([
      hookUnion.id,
    ]);
    const [body] = response.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    // The barb adds material past the beam, up to its full wedge volume.
    const beamVolume = 48_000 + 2 * 6 * 12;
    const barbVolume = (6 * hookZLength * (overhang + CLASP_OVERLAP)) / 2;
    expect(body?.probes.volumeMm3).toBeGreaterThan(beamVolume);
    expect(body?.probes.volumeMm3).toBeLessThan(beamVolume + barbVolume);
    // The barb tip sits at the beam tip plane (z 32), so the top does not grow.
    expect(body?.probes.boundingBoxMm[5]).toBeCloseTo(32, 5);
  });

  it("grows the body with direction outward while keeping one hollow solid", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const shell = createShell(box, { thickness: 1.6, direction: "outward" });
    const response = await evaluate(supervisor, [box, shell]);
    expect(response.ok).toBe(true);
    if (!response.ok || response.result.type !== "evaluation") return;
    const [body] = response.result.bodies;
    expect(body?.probes.solidCount).toBe(1);
    expect(body?.probes.shellCount).toBe(2);
    // Outward: the original surface becomes the cavity and the body grows.
    expect(body?.probes.boundingBoxMm[2]).toBeCloseTo(-1.6, 6);
    expect(body?.probes.boundingBoxMm[5]).toBeCloseTo(21.6, 6);
  });

  it("fails GEOMETRY_FAILED with a thickness feasibility bound when the walls collide", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    // 15 mm walls in a 20 mm-tall body: the inward offset collapses.
    const shell = createShell(box, { thickness: 15 });
    const response = await evaluate(supervisor, [box, shell]);
    expect(response.ok).toBe(false);
    if (response.ok) return;
    expect(response.error.code).toBe("GEOMETRY_FAILED");
    expect(response.error.operationId).toBe(shell.id);
    // Wave 2.4 payload: a TESTED lower bound on the workable thickness.
    const details = response.error.details as {
      feasibilityProbe?: { parameter?: string; maxFeasible?: number };
    };
    expect(details.feasibilityProbe?.parameter).toBe("thickness");
    expect(details.feasibilityProbe?.maxFeasible).toBeGreaterThan(0);
    expect(details.feasibilityProbe?.maxFeasible).toBeLessThan(10);
  });

  /**
   * CAP-013 FLIPPED THIS PIN. It used to assert that a resolved openFaces set
   * fails closed after resolution, because the pinned
   * `BRepOffsetAPI_MakeThickSolid` history was unverified for topology naming.
   * That history is now MEASURED deterministic and the registry's harvest
   * attributes the ByJoin result, so the set executes into a real open
   * container over the wire.
   *
   * The witness is the SHELL COUNT, not the volume. A closed hollow is one
   * solid bounded by TWO shells (outer skin + cavity); an open container's
   * cavity is continuous with the outside, so it has exactly ONE. A regression
   * that silently produced a closed hollow would still report a plausible
   * volume, and would still fail here.
   */
  it("hollows a body into an open container when openFaces resolves (CAP-013)", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const shell = createShell(box, {
      thickness: 1.6,
      openFaces: {
        ast: opFacesNormalZ(box.id),
        arity: "any",
        onEmpty: "empty-ok",
      },
    });
    const response = await evaluate(supervisor, [box, shell]);
    expect(response.ok, "an open-face shell must now execute").toBe(true);
    if (!response.ok || response.result.type !== "evaluation") return;
    expect(response.result.bodies).toHaveLength(1);
    const body = response.result.bodies[0];
    expect(body?.operationId).toBe(shell.id);
    expect(body?.probes.valid).toBe(true);
    expect(body?.probes.solidCount).toBe(1);
    expect(body?.probes.shellCount).toBe(1);
    // The outer size is untouched — inward walls grow into the body.
    expect(body?.probes.boundingBoxMm[5]).toBeCloseTo(20, 6);
  });

  it("reaches the datum executors now that evaluate_document threads a registry, refusing the ambiguous refs (N6 slice C)", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const datums = wireOperationSchema.array().parse([
      {
        ...shared,
        id: randomUUID(),
        type: "datum_plane",
        name: "Lid plane",
        parameters: {
          mode: "offset",
          offset: 5,
          base: {
            ast: opQuery("faces", box.id, [{ name: "planar", args: [] }]),
          },
        },
      },
      {
        ...shared,
        id: randomUUID(),
        type: "datum_axis",
        name: "Two-point axis",
        parameters: {
          mode: "twoPoints",
          a: { ast: opQuery("vertices", box.id) },
          b: {
            ast: opQuery("vertices", box.id, [
              { name: "nth", args: [{ arg: "number", value: 1 }] },
            ]),
          },
        },
      },
    ]);
    for (const datum of datums) {
      const response = await evaluate(supervisor, [box, datum]);
      expect(response.ok, `${datum.type} must fail closed`).toBe(false);
      if (response.ok) continue;
      // N6 slice C part 3 threads the registry through evaluate_document, so the
      // datum executor is REACHED and its ref RESOLVES on-kernel (no longer a
      // registry-missing refusal). These staging refs are under-specified (every
      // planar face / every vertex), so the resolver refuses them E_SEL_AMBIGUOUS
      // rather than pick one — the no-silent-misreference invariant, now proven
      // end-to-end through evaluate_document.
      expect(response.error.code, datum.type).toBe("REFERENCE_AMBIGUOUS");
      // Attribution is the load-bearing half: the refusal names the staged
      // operation, never the healthy box and never an unattributed failure.
      expect(response.error.operationId, datum.type).toBe(datum.id);
    }
  });

  /**
   * CAP-014 — the staging step the header above called "next": UNIQUE refs that
   * mint real datum geometry, and a downstream operation that CONSUMES it.
   *
   * The ambiguity case above stays exactly as it was. It is not superseded by
   * this one — it is the standing no-silent-misreference pin, and the two
   * together are the whole contract: an under-specified datum ref REFUSES, a
   * unique one RESOLVES and can be referenced.
   *
   * The bound is the assertion. The datum sits 5 mm outboard of the box's +x
   * face, so mirroring through it lands the copy further out than mirroring
   * through the face itself would. A datum that silently degraded to its own
   * base face would still produce a valid mirrored solid — only the number
   * separates them.
   */
  it("mints real datum geometry from a unique ref and mirrors a body across it", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const plusX = [
      {
        name: "normal",
        args: [
          {
            arg: "direction" as const,
            value: { form: "axis" as const, sign: 1, axis: "x" as const },
          },
        ],
      },
    ];
    const datum = wireOperationSchema.parse({
      ...shared,
      id: randomUUID(),
      type: "datum_plane",
      name: "Mirror plane",
      parameters: {
        mode: "offset",
        offset: 5,
        base: { ast: opQuery("faces", box.id, plusX) },
      },
    });
    const mirror = wireOperationSchema.parse({
      ...shared,
      id: randomUUID(),
      type: "mirror",
      name: "Mirror across the datum",
      outputBodyId: randomUUID(),
      parameters: {
        sourceOperationId: box.id,
        merge: false,
        plane: { ast: opQuery("faces", datum.id) },
      },
    });

    const response = await evaluate(supervisor, [box, datum, mirror]);
    expect(
      response.ok,
      "a unique datum ref must resolve and be consumable",
    ).toBe(true);
    if (!response.ok || response.result.type !== "evaluation") return;
    // The datum itself produces NO body; the source and its reflected copy do.
    expect(response.result.bodies).toHaveLength(2);
    const copy = response.result.bodies.find(
      (body) => body.operationId === mirror.id,
    );
    expect(copy, "the mirrored copy is a visible body").toBeDefined();
    expect(copy?.probes.valid).toBe(true);
    expect(copy?.probes.solidCount).toBe(1);
    // createBox is 60 wide, so x spans [-30,30] and its +x face is at x=30.
    // The datum sits 5 mm outboard at x=35, and reflecting [-30,30] through it
    // gives [40,100]. Mirroring through the FACE instead would have given
    // [30,90] — an equally valid solid of identical volume, which is exactly
    // why the bound is what this test asserts.
    expect(copy?.probes.boundingBoxMm[0]).toBeCloseTo(40, 6);
    expect(copy?.probes.boundingBoxMm[3]).toBeCloseTo(100, 6);
  });

  /**
   * The durable sketch-plane seam: a datum entity is synthetic and has no
   * visible body, but the query wire still returns its analytic plane evidence
   * so the renderer can open and re-open a sketch on that datum.
   */
  it("returns a synthetic datum plane over the query method", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const datum = wireOperationSchema.parse({
      ...shared,
      id: randomUUID(),
      type: "datum_plane",
      name: "Queried plane",
      parameters: {
        mode: "offset",
        offset: 5,
        base: {
          ast: opQuery("faces", box.id, [
            {
              name: "normal",
              args: [
                {
                  arg: "direction" as const,
                  value: { form: "axis" as const, sign: 1, axis: "x" as const },
                },
              ],
            },
          ]),
        },
      },
    });
    const response = await supervisor.client.request(
      kernelRequestSchema.parse({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "query",
        operations: [box, datum],
        atOperationId: datum.id,
        ast: opQuery("faces", datum.id),
      }),
    );
    expect(response.ok, "querying a datum must resolve its durable plane").toBe(
      true,
    );
    if (!response.ok || response.result.type !== "query") return;
    expect(response.result.entities).toHaveLength(1);
    const plane = response.result.entities[0];
    expect(plane?.bodyId).toBe("");
    expect(plane?.surface).toBe("plane");
    expect(plane?.normal?.[0]).toBeCloseTo(1, 6);
    expect(plane?.normal?.[1]).toBeCloseTo(0, 6);
    expect(plane?.normal?.[2]).toBeCloseTo(0, 6);
    expect(plane?.centroid[0]).toBeCloseTo(35, 6);
  });

  // Catalog wave 2 (`mirror` / `pattern_linear` / `pattern_circular`) now HAS
  // native executors, so those types no longer reach the dispatch-`else`; the
  // sibling "executes the catalog wave 2 types" case below pins that they run.
  // What still fails closed here is a RAW fastener: both feeds lower `bolt` and
  // `clasp` into primitive ops before the kernel, so an unlowered one arriving
  // raw must still hit the fail-closed guard.
  it("refuses a raw, unlowered fastener at the kernel dispatch", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const staged = wireOperationSchema.array().parse([
      {
        ...shared,
        id: randomUUID(),
        type: "bolt",
        name: "Bolt through the box",
        outputBodyId: randomUUID(),
        parameters: {
          targetOperationId: box.id,
          size: "M3",
          fit: "medium",
          head: "counterbore",
          throughAll: true,
        },
      },
      {
        ...shared,
        id: randomUUID(),
        type: "clasp",
        name: "Clasp on the box",
        outputBodyId: randomUUID(),
        parameters: {
          targetOperationId: box.id,
          material: "PLA",
          beamThicknessMm: 2,
          beamLengthMm: 16,
          beamWidthMm: 6,
          retention: "releasable",
        },
      },
    ]);
    for (const operation of staged) {
      const response = await evaluate(supervisor, [box, operation]);
      expect(response.ok, `${operation.type} must fail closed`).toBe(false);
      if (response.ok) continue;
      expect(response.error.code, operation.type).toBe("UNSUPPORTED_OPERATION");
      expect(response.error.operationId, operation.type).toBe(operation.id);
      expect(response.error.message).toContain(operation.type);
    }
  });

  // Catalog wave 2 executes for real. The native `aeth-catalog-wave2-test`
  // proves the GEOMETRY (reflected extents, fused bar, instance rings) against
  // the kernel directly; this pins the WIRE path those ops travel — schema →
  // request validation → dispatch → executor — which N6 proved can break
  // independently of the kernel itself.
  it("executes the catalog wave 2 types at the kernel dispatch", async () => {
    const supervisor = await startSupervisor();
    const box = createBox();
    const waveTwo = wireOperationSchema.array().parse([
      {
        ...shared,
        id: randomUUID(),
        type: "mirror",
        name: "Mirror the box",
        outputBodyId: randomUUID(),
        parameters: {
          sourceOperationId: box.id,
          // A ref that must actually RESOLVE, unlike the staging pins above:
          // the box's single +z face is unambiguous. A `world(...)` source
          // cannot be used here — that selector source is deferred in this
          // tranche and fails closed with UNSUPPORTED_OPERATION.
          plane: { ast: opFacesNormalZ(box.id) },
          merge: false,
        },
      },
      {
        ...shared,
        id: randomUUID(),
        type: "pattern_linear",
        name: "Row of boxes",
        outputBodyId: randomUUID(),
        parameters: {
          seedOperationId: box.id,
          count: 3,
          // Spacing == the seed's 60mm width, so the instances TOUCH and fuse
          // into the single connected solid a v1 pattern must yield (a gap
          // would be refused GEOMETRY_FAILED: "disjoint solids"). Coincident
          // instance faces also make this exercise the merged-image naming
          // path through the wire.
          spacing: 60,
          direction: [1, 0, 0],
        },
      },
    ]);
    for (const operation of waveTwo) {
      const response = await evaluate(supervisor, [box, operation]);
      expect(
        response.ok,
        `${operation.type} must evaluate for real now${
          response.ok
            ? ""
            : ` — got ${response.error.code}: ${response.error.message}`
        }`,
      ).toBe(true);
      if (!response.ok || response.result.type !== "evaluation") continue;
      expect(
        response.result.bodies.length,
        `${operation.type} must yield at least one body`,
      ).toBeGreaterThan(0);
      for (const body of response.result.bodies) {
        expect(body.probes.solidCount, operation.type).toBe(1);
      }
    }
  });
});
