/**
 * CAP-037 — `solve_sketch` end to end, over stdio, against the real kernel host.
 *
 * The schema tests in @aeth/geometry-contracts prove the wire SHAPE. They
 * cannot prove the kernel reads it correctly, and that gap is not theoretical:
 * the first draft of the host's translation assumed `horizontal` carried two
 * anchors when CAP-035 defines it as a single `eid` over the whole line. A
 * schema test passed either way. This suite is what fails.
 */
import { Buffer } from "node:buffer";
import { spawn } from "node:child_process";
import { createHash, randomUUID } from "node:crypto";
import { readFileSync } from "node:fs";

import {
  kernelProtocolVersion,
  kernelRequestSchema,
  type SketchSolution,
} from "@aeth/geometry-contracts";
import { afterEach, expect, it } from "vitest";

import { KernelSupervisor } from "../src/index.js";
import { nativeDescribe } from "./native-gate.js";

const executable = process.env["AETH_KERNEL_HOST_PATH"];
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

function expectSolutionsObjectIdentical(
  actual: SketchSolution,
  expected: SketchSolution,
): void {
  expect(actual.degreesOfFreedom).toBe(expected.degreesOfFreedom);
  expect(actual.entities).toHaveLength(expected.entities.length);
  for (
    let entityIndex = 0;
    entityIndex < expected.entities.length;
    entityIndex += 1
  ) {
    const actualEntity = actual.entities[entityIndex];
    const expectedEntity = expected.entities[entityIndex];
    expect(actualEntity?.eid).toBe(expectedEntity?.eid);
    expect(actualEntity?.values).toHaveLength(
      expectedEntity?.values.length ?? 0,
    );
    for (
      let valueIndex = 0;
      valueIndex < (expectedEntity?.values.length ?? 0);
      valueIndex += 1
    ) {
      expect(
        Object.is(
          actualEntity?.values[valueIndex],
          expectedEntity?.values[valueIndex],
        ),
      ).toBe(true);
    }
  }
}

async function rawNativeRequest(rawJson: string): Promise<unknown> {
  if (!executable) throw new Error("AETH_KERNEL_HOST_PATH is not configured");
  const child = spawn(executable, [], {
    env: { ...process.env, ...nativeEnvironment() },
    stdio: ["pipe", "pipe", "pipe", "pipe"],
    windowsHide: true,
  });
  const payload = Buffer.from(rawJson, "utf8");
  const header = Buffer.alloc(4);
  header.writeUInt32LE(payload.byteLength, 0);

  return await new Promise((resolve, reject) => {
    let output = Buffer.alloc(0);
    let diagnostics = "";
    let responseValue: object | null | undefined;
    let settled = false;
    const fail = (error: Error) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      child.kill();
      reject(error);
    };
    const timer = setTimeout(
      () => fail(new Error(`raw kernel request timed out: ${diagnostics}`)),
      30_000,
    );
    child.stderr?.on("data", (chunk: Buffer) => {
      diagnostics += chunk.toString("utf8");
    });
    // fd 3 is the binary-mesh stream. This request should emit none, but it
    // still must be drained so an unexpected frame cannot deadlock teardown.
    const binaryPipe = child.stdio[3];
    if (
      binaryPipe !== null &&
      typeof binaryPipe !== "number" &&
      "on" in binaryPipe
    ) {
      binaryPipe.on("data", () => undefined);
    }
    child.once("error", (error) => fail(error));
    // `close` follows stream drainage; `exit` can race the final stdout frame.
    child.once("close", (code) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      if (responseValue !== undefined) {
        resolve(responseValue);
      } else {
        reject(
          new Error(
            `raw kernel exited before responding (${String(code)}): ${diagnostics}`,
          ),
        );
      }
    });
    child.stdout?.on("data", (chunk: Buffer) => {
      if (responseValue !== undefined) return;
      output = Buffer.concat([output, chunk]);
      if (output.byteLength < 4) return;
      const size = output.readUInt32LE(0);
      if (output.byteLength < 4 + size) return;
      responseValue = JSON.parse(
        output.subarray(4, 4 + size).toString("utf8"),
      ) as object | null;
      // Only now signal EOF. The response has been received, so server.Stop()
      // cannot cancel the request; awaiting `close` below proves clean teardown.
      child.stdin?.end();
    });
    // Keep stdin open until the response arrives. EOF is the host's shutdown
    // signal and may cancel the worker before it writes fd 3.
    child.stdin?.write(Buffer.concat([header, payload]), (error) => {
      if (error) fail(error);
    });
  });
}

afterEach(async () => {
  for (const supervisor of supervisors.splice(0)) {
    await supervisor.stop();
  }
});

const eid = (suffix: string) => `ent_${suffix.padEnd(26, "0")}`;
const cid = (suffix: string) => `cst_${suffix.padEnd(26, "0")}`;

const ANCHOR = eid("A");
const LINE = eid("B");
const ARC = eid("C");
const SECOND_LINE = eid("D");

/**
 * A line pinned at the origin, horizontal, dimensioned. The line STARTS at
 * (7, 3) — deliberately not the answer, so a host that echoed its input back
 * would fail every assertion below.
 */
function groundedLine(lengthMm: number) {
  return {
    entities: [
      { eid: ANCHOR, kind: "point", at: [0, 0], construction: false },
      {
        eid: LINE,
        kind: "line",
        p1: [0, 0],
        p2: [7, 3],
        construction: false,
      },
    ],
    constraints: [
      {
        cid: cid("A"),
        kind: "coincident",
        a: { eid: ANCHOR, at: "point" },
        b: { eid: LINE, at: "start" },
      },
      { cid: cid("B"), kind: "horizontal", eid: LINE },
      {
        cid: cid("C"),
        kind: "distance",
        a: { eid: LINE, at: "start" },
        b: { eid: LINE, at: "end" },
        value: lengthMm,
      },
    ],
    grounded: [ANCHOR],
  };
}

function closedLineAndArc() {
  return {
    entities: [
      {
        eid: LINE,
        kind: "line",
        p1: [-6, 0],
        p2: [6, 0],
        construction: false,
      },
      {
        eid: ARC,
        kind: "arc-center",
        center: [0, 7],
        radius: 9,
        startAngle: 225,
        endAngle: 315,
        ccw: true,
        construction: false,
      },
    ],
    constraints: [
      {
        cid: cid("G"),
        kind: "coincident",
        a: { eid: LINE, at: "start" },
        b: { eid: ARC, at: "start" },
      },
      {
        cid: cid("H"),
        kind: "coincident",
        a: { eid: LINE, at: "end" },
        b: { eid: ARC, at: "end" },
      },
      { cid: cid("J"), kind: "radius", eid: ARC, value: 10 },
    ],
    grounded: [LINE],
  };
}

/** The exact Arc → Line(H) → Line(V) cycle driven by the packaged gate. */
function fullyConstrainedQuarterArcContour() {
  return {
    entities: [
      {
        eid: ARC,
        kind: "arc-center",
        center: [0, 0],
        radius: 20,
        startAngle: 0,
        endAngle: 90,
        ccw: true,
        construction: false,
      },
      {
        eid: LINE,
        kind: "line",
        p1: [5, 5],
        p2: [25, 5],
        construction: false,
      },
      {
        eid: SECOND_LINE,
        kind: "line",
        p1: [10, 10],
        p2: [30, 10],
        construction: false,
      },
    ],
    constraints: [
      { cid: cid("R"), kind: "horizontal", eid: LINE },
      { cid: cid("S"), kind: "vertical", eid: SECOND_LINE },
      {
        cid: cid("T"),
        kind: "coincident",
        a: { eid: ARC, at: "end" },
        b: { eid: LINE, at: "start" },
      },
      {
        cid: cid("V"),
        kind: "coincident",
        a: { eid: LINE, at: "end" },
        b: { eid: SECOND_LINE, at: "start" },
      },
      {
        cid: cid("W"),
        kind: "coincident",
        a: { eid: SECOND_LINE, at: "end" },
        b: { eid: ARC, at: "start" },
      },
    ],
    grounded: [ARC],
  };
}

async function solve(
  supervisor: KernelSupervisor,
  payload: Record<string, unknown>,
) {
  return supervisor.client.request(
    kernelRequestSchema.parse({
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      method: "solve_sketch",
      ...payload,
    }),
  );
}

describeNative("solve_sketch over the real kernel host", () => {
  it("solves a grounded, dimensioned line to its exact length", async () => {
    const supervisor = await startSupervisor();
    const response = await solve(supervisor, groundedLine(20));
    expect(response.ok).toBe(true);
    if (!response.ok || response.result.type !== "sketch_solution") {
      throw new Error(`unexpected response: ${JSON.stringify(response)}`);
    }
    expect(response.result.status).toBe("converged");
    const solved = response.result.solution?.entities ?? [];
    const line = solved.find((entity) => entity.eid === LINE);
    if (!line) throw new Error("the solved line did not come back");
    // Exact analytic answer: pinned at the origin, horizontal, 20 long.
    expect(Math.abs(line.values[0] ?? NaN)).toBeLessThan(1e-9);
    expect(Math.abs(line.values[1] ?? NaN)).toBeLessThan(1e-9);
    expect(Math.abs(line.values[3] ?? NaN)).toBeLessThan(1e-9);
    expect(Math.abs((line.values[2] ?? NaN) - 20)).toBeLessThan(1e-9);
    expect(response.result.solution?.degreesOfFreedom).toBe(0);

    const solution = response.result.solution;
    if (!solution) throw new Error("the solved sketch did not come back");
    const persisted = JSON.parse(JSON.stringify(solution)) as SketchSolution;
    expectSolutionsObjectIdentical(persisted, solution);
    expect(
      solution.entities
        .flatMap((entity) => entity.values)
        .filter((value) => value === 0)
        .every((value) => !Object.is(value, -0)),
    ).toBe(true);
  });

  it("returns BYTE-IDENTICAL values across two separate requests", async () => {
    // The determinism contract crossing a process boundary, which is where the
    // stored solution will actually be compared on reopen.
    const supervisor = await startSupervisor();
    const first = await solve(supervisor, groundedLine(17.3));
    const second = await solve(supervisor, groundedLine(17.3));
    if (
      !first.ok ||
      !second.ok ||
      first.result.type !== "sketch_solution" ||
      second.result.type !== "sketch_solution"
    ) {
      throw new Error("expected two sketch solutions");
    }
    expect(JSON.stringify(second.result.solution)).toBe(
      JSON.stringify(first.result.solution),
    );
  });

  it("solves a closed line-and-arc contour through typed arc endpoints", async () => {
    const supervisor = await startSupervisor();
    const first = await solve(supervisor, closedLineAndArc());
    const second = await solve(supervisor, closedLineAndArc());
    if (
      !first.ok ||
      !second.ok ||
      first.result.type !== "sketch_solution" ||
      second.result.type !== "sketch_solution"
    ) {
      throw new Error("expected two sketch solutions");
    }
    expect(first.result.status).toBe("converged");
    expect(JSON.stringify(second.result.solution)).toBe(
      JSON.stringify(first.result.solution),
    );

    const arc = (first.result.solution?.entities ?? []).find(
      (entity) => entity.eid === ARC,
    );
    if (!arc) throw new Error("the solved arc did not come back");
    expect(arc.values).toHaveLength(5);
    const [cx, cy, radius, startDegrees, endDegrees] = arc.values;
    const startRadians = ((startDegrees ?? NaN) * Math.PI) / 180;
    const endRadians = ((endDegrees ?? NaN) * Math.PI) / 180;
    expect(radius).toBeCloseTo(10, 8);
    expect((cx ?? NaN) + (radius ?? NaN) * Math.cos(startRadians)).toBeCloseTo(
      -6,
      8,
    );
    expect((cy ?? NaN) + (radius ?? NaN) * Math.sin(startRadians)).toBeCloseTo(
      0,
      8,
    );
    expect((cx ?? NaN) + (radius ?? NaN) * Math.cos(endRadians)).toBeCloseTo(
      6,
      8,
    );
    expect((cy ?? NaN) + (radius ?? NaN) * Math.sin(endRadians)).toBeCloseTo(
      0,
      8,
    );
    expect(first.result.solution?.degreesOfFreedom).toBe(0);

    // Robustness for iterative authoring: prove the degree↔radian adapter is a
    // fixed point when accepted coordinates become the next seed. This is not
    // the CAP-037 persisted-replay proof; evaluate_document below supplies that
    // independently by comparing the stored solution inside the native host.
    const lineSolved = (first.result.solution?.entities ?? []).find(
      (entity) => entity.eid === LINE,
    )?.values;
    if (!lineSolved) throw new Error("the solved line did not come back");
    const seeded = closedLineAndArc();
    seeded.entities = [
      {
        ...seeded.entities[0],
        p1: [lineSolved[0] ?? NaN, lineSolved[1] ?? NaN],
        p2: [lineSolved[2] ?? NaN, lineSolved[3] ?? NaN],
      },
      {
        ...seeded.entities[1],
        center: [cx ?? NaN, cy ?? NaN],
        radius: radius ?? NaN,
        startAngle: startDegrees ?? NaN,
        endAngle: endDegrees ?? NaN,
      },
    ];
    const fixedPoint = await solve(supervisor, seeded);
    if (
      !fixedPoint.ok ||
      fixedPoint.result.type !== "sketch_solution" ||
      fixedPoint.result.solution === undefined
    ) {
      throw new Error(
        `fixed-point solve failed: ${JSON.stringify(fixedPoint)}`,
      );
    }
    const originalSolution = first.result.solution;
    if (!originalSolution) throw new Error("the original solution is missing");
    expectSolutionsObjectIdentical(
      fixedPoint.result.solution,
      originalSolution,
    );
  });

  it("solves the packaged Arc/H-line/V-line contour fully", async () => {
    const supervisor = await startSupervisor();
    const response = await solve(
      supervisor,
      fullyConstrainedQuarterArcContour(),
    );
    expect(response.ok).toBe(true);
    if (!response.ok || response.result.type !== "sketch_solution") {
      throw new Error(`unexpected response: ${JSON.stringify(response)}`);
    }
    expect(response.result.status).toBe("converged");
    expect(response.result.solution?.degreesOfFreedom).toBe(0);
  });

  it("reports remaining freedom when the dimension is dropped", async () => {
    const supervisor = await startSupervisor();
    const system = groundedLine(20);
    system.constraints = system.constraints.filter(
      (constraint) => constraint.kind !== "distance",
    );
    const response = await solve(supervisor, system);
    if (!response.ok || response.result.type !== "sketch_solution") {
      throw new Error("expected a sketch solution");
    }
    expect(response.result.status).toBe("converged");
    expect(response.result.solution?.degreesOfFreedom).toBe(1);
    expect(response.result.conflicting).toEqual([]);
  });

  it("NAMES the conflicting constraints, in our ids", async () => {
    const supervisor = await startSupervisor();
    const system = groundedLine(20);
    system.constraints.push({
      cid: cid("D"),
      kind: "distance",
      a: { eid: LINE, at: "start" },
      b: { eid: LINE, at: "end" },
      value: 35,
    });
    const response = await solve(supervisor, system);
    if (!response.ok || response.result.type !== "sketch_solution") {
      throw new Error("expected a sketch solution");
    }
    expect(response.result.status).toBe("conflicting");
    expect(response.result.conflicting.length).toBeGreaterThan(0);
    for (const name of response.result.conflicting) {
      // A solver tag integer here would mean PlaneGCS's vocabulary leaked
      // across the wire instead of being translated to ours.
      expect(name.startsWith("cst_")).toBe(true);
    }
    expect(response.result.message).toContain("cst_");
  });

  it("refuses horizontal plus vertical on one line and names BOTH ids", async () => {
    const supervisor = await startSupervisor();
    const system = groundedLine(20);
    system.constraints.push({
      cid: cid("K"),
      kind: "vertical",
      eid: LINE,
    });
    const response = await solve(supervisor, system);
    if (!response.ok || response.result.type !== "sketch_solution") {
      throw new Error("expected a sketch solution");
    }
    expect(response.result.status).toBe("conflicting");
    expect([...response.result.conflicting].sort()).toEqual(
      [cid("B"), cid("K")].sort(),
    );
    expect(response.result.message).toContain(cid("B"));
    expect(response.result.message).toContain(cid("K"));
  });

  it("refuses a constraint that collapses one line onto itself", async () => {
    const supervisor = await startSupervisor();
    const collapse = cid("X");
    const response = await solve(supervisor, {
      entities: [
        {
          eid: LINE,
          kind: "line",
          p1: [0, 0],
          p2: [10, 0],
          construction: false,
        },
      ],
      constraints: [
        {
          cid: collapse,
          kind: "coincident",
          a: { eid: LINE, at: "start" },
          b: { eid: LINE, at: "end" },
        },
      ],
      grounded: [],
    });
    if (!response.ok || response.result.type !== "sketch_solution") {
      throw new Error(`unexpected response: ${JSON.stringify(response)}`);
    }
    expect(response.result.status).toBe("conflicting");
    expect(response.result.conflicting).toEqual([collapse]);
    expect(response.result.solution).toBeUndefined();
  });

  it("preserves an unconstrained ellipse through the native solver", async () => {
    const supervisor = await startSupervisor();
    const response = await solve(supervisor, {
      entities: [
        {
          eid: eid("C"),
          kind: "ellipse",
          center: [0, 0],
          radiusX: 4,
          radiusY: 8,
          construction: false,
        },
      ],
      constraints: [],
      grounded: [],
    });
    if (!response.ok || response.result.type !== "sketch_solution") {
      throw new Error("expected a sketch solution");
    }
    expect(response.result.status).toBe("converged");
    expect(response.result.solution?.degreesOfFreedom).toBeGreaterThan(0);
    const ellipse = response.result.solution?.entities.find(
      (entity) => entity.eid === eid("C"),
    );
    expect(ellipse?.values).toEqual([0, 0, 4, 8, 0]);
  });

  it("solves a radius dimension on a circle", async () => {
    const supervisor = await startSupervisor();
    const CIRCLE = eid("D");
    const response = await solve(supervisor, {
      entities: [
        { eid: ANCHOR, kind: "point", at: [5, 5], construction: false },
        {
          eid: CIRCLE,
          kind: "circle",
          center: [5, 5],
          radius: 2,
          construction: false,
        },
      ],
      constraints: [
        {
          cid: cid("E"),
          kind: "coincident",
          a: { eid: ANCHOR, at: "point" },
          b: { eid: CIRCLE, at: "center" },
        },
        { cid: cid("F"), kind: "radius", eid: CIRCLE, value: 12.5 },
      ],
      grounded: [ANCHOR],
    });
    if (!response.ok || response.result.type !== "sketch_solution") {
      throw new Error("expected a sketch solution");
    }
    expect(response.result.status).toBe("converged");
    const circle = (response.result.solution?.entities ?? []).find(
      (entity) => entity.eid === CIRCLE,
    );
    expect(Math.abs((circle?.values[2] ?? NaN) - 12.5)).toBeLessThan(1e-9);
  });

  it("REFUSES a document whose stored sketch solution does not reproduce", async () => {
    // The determinism contract with teeth. A tampered solution is the only way
    // to prove the assertion fires: an honest document always agrees with
    // itself, so a check that never fails would look identical to this one.
    const supervisor = await startSupervisor();
    const solved = await solve(supervisor, groundedLine(20));
    if (!solved.ok || solved.result.type !== "sketch_solution") {
      throw new Error("expected a sketch solution to seed the document");
    }
    const honest = solved.result.solution;
    if (!honest) throw new Error("expected a solution");

    const sketchOperation = (solution: unknown) => ({
      id: randomUUID(),
      type: "sketch",
      schemaVersion: 1,
      name: "Top sketch",
      parameters: {
        plane: {
          ast: {
            kind: "faces",
            scope: [{ source: "world", world: "xy" }],
            filters: [],
          },
          arity: "one",
          onEmpty: "error",
          anchors: [],
        },
        entities: groundedLine(20).entities,
        constraints: groundedLine(20).constraints,
        grounded: groundedLine(20).grounded,
        solution,
      },
      metadata: {
        createdAt: "2026-07-28T00:00:00.000Z",
        createdBy: { kind: "user" },
      },
    });

    const evaluate = async (solution: unknown) =>
      supervisor.client.request({
        protocolVersion: kernelProtocolVersion,
        requestId: randomUUID(),
        documentId: randomUUID(),
        revision: 1,
        method: "evaluate_document",
        operations: [sketchOperation(solution)],
      } as never);

    // The honest solution evaluates.
    const good = await evaluate(honest);
    expect(good.ok).toBe(true);

    // One coordinate moved by 1 mm — a change a person would not notice in a
    // file, and exactly what the assertion exists to catch.
    const tampered = structuredClone(honest) as typeof honest;
    const first = tampered.entities[0];
    if (!first || first.values[0] === undefined) {
      throw new Error("expected solved values to tamper with");
    }
    first.values[0] += 1;
    const bad = await evaluate(tampered);
    expect(bad.ok).toBe(false);
    if (bad.ok) throw new Error("a tampered solution must not evaluate");
    expect(bad.error.code).toBe("GEOMETRY_FAILED");
    expect(bad.error.message).toContain("re-solved to different coordinates");
  });

  it("compares persisted coordinates by f64 bits, not numeric JSON equality", async () => {
    // nlohmann numeric equality considers +0.0 and -0.0 equal. The replay
    // contract is stronger: a different bit pattern must fail. Write one raw
    // frame because JavaScript's JSON.stringify canonicalizes -0 to 0 before a
    // normal KernelSupervisor request could reach the native trust boundary.
    const marker = 987_654_321;
    const request = {
      protocolVersion: kernelProtocolVersion,
      requestId: randomUUID(),
      documentId: randomUUID(),
      revision: 1,
      method: "evaluate_document",
      operations: [
        {
          id: randomUUID(),
          type: "sketch",
          schemaVersion: 1,
          name: "Signed zero replay",
          parameters: {
            plane: {
              ast: {
                kind: "faces",
                scope: [{ source: "world", world: "xy" }],
                filters: [],
              },
              arity: "one",
              onEmpty: "error",
              anchors: [],
            },
            entities: groundedLine(20).entities,
            constraints: groundedLine(20).constraints,
            grounded: groundedLine(20).grounded,
            solution: {
              entities: [
                { eid: ANCHOR, values: [marker, 0] },
                { eid: LINE, values: [0, 0, 20, 0] },
              ],
              degreesOfFreedom: 0,
            },
          },
          metadata: {
            createdAt: "2026-07-28T00:00:00.000Z",
            createdBy: { kind: "user" },
          },
        },
      ],
    };
    const serialized = JSON.stringify(request);
    expect(serialized).toContain(String(marker));
    const rawWithNegativeZero = serialized.replace(String(marker), "-0.0");
    const response = (await rawNativeRequest(rawWithNegativeZero)) as {
      readonly ok?: boolean;
      readonly error?: { readonly code?: string; readonly message?: string };
    };
    expect(response.ok).toBe(false);
    expect(response.error?.code).toBe("GEOMETRY_FAILED");
    expect(response.error?.message).toContain(
      "re-solved to different coordinates",
    );
  });
});
