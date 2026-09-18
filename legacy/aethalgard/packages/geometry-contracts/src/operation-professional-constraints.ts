import type { z } from "zod";

import * as raw from "./operations.js";

function issue(
  context: z.RefinementCtx,
  message: string,
  path: readonly (string | number)[],
): void {
  context.addIssue({ code: "custom", message, path: [...path] });
}

function operationRefKind(value: unknown): string | undefined {
  if (typeof value !== "object" || value === null) return undefined;
  const candidate = value as {
    query?: unknown;
    ast?: { kind?: unknown };
  };
  if (typeof candidate.ast?.kind === "string") return candidate.ast.kind;
  if (typeof candidate.query !== "string") return undefined;
  const match = /^\s*(faces|edges|vertices|bodies|regions)\s*\(/.exec(
    candidate.query,
  );
  return match?.[1];
}

function requireRefKind(
  context: z.RefinementCtx,
  value: unknown,
  expected: "edges" | "faces",
  path: readonly (string | number)[],
  label: string,
): void {
  const actual = operationRefKind(value);
  if (actual === undefined || actual === expected) return;
  issue(
    context,
    expected === "edges"
      ? `${label} must reference an edge or curve`
      : `${label} must reference a face`,
    path,
  );
}

/**
 * Cross-field invariants shared by persisted and wire operation schemas.
 *
 * These checks deliberately contain only states that are contradictory by
 * construction. Capability support/refusal belongs to the evaluator; this layer
 * prevents two authoring surfaces from assigning different meanings to the same
 * otherwise schema-valid payload.
 */
export function refineProfessionalOperation(
  value: unknown,
  context: z.RefinementCtx,
): void {
  if (typeof value !== "object" || value === null) return;
  const operation = value as {
    type?: string;
    schemaVersion?: number;
    parameters?: Record<string, unknown>;
  };
  const parameters = operation.parameters;
  if (parameters === undefined) return;

  if (operation.type === "sweep" && operation.schemaVersion === 2) {
    if (
      parameters.guideRail !== undefined &&
      parameters.guideSurface !== undefined
    ) {
      issue(
        context,
        "guideRail and guideSurface are mutually exclusive Sweep controls",
        ["parameters", "guideSurface"],
      );
    }
    if (
      parameters.orientation === "fixed" &&
      (parameters.guideRail !== undefined ||
        parameters.guideSurface !== undefined)
    ) {
      issue(
        context,
        "fixed Sweep orientation cannot be combined with a guide rail or guide surface",
        ["parameters", "orientation"],
      );
    }

    if (Array.isArray(parameters.path)) {
      parameters.path.forEach((ref, index) =>
        requireRefKind(
          context,
          ref,
          "edges",
          ["parameters", "path", index],
          `Sweep path segment ${String(index + 1)}`,
        ),
      );
    }
    if (parameters.guideRail !== undefined) {
      requireRefKind(
        context,
        parameters.guideRail,
        "edges",
        ["parameters", "guideRail"],
        "Sweep guide rail",
      );
    }
    if (parameters.guideSurface !== undefined) {
      requireRefKind(
        context,
        parameters.guideSurface,
        "faces",
        ["parameters", "guideSurface"],
        "Sweep guide surface",
      );
    }
    if (parameters.faceProfile !== undefined) {
      requireRefKind(
        context,
        parameters.faceProfile,
        "faces",
        ["parameters", "faceProfile"],
        "Sweep face profile",
      );
    }
    const extent = parameters.extent as
      { mode?: unknown; end?: unknown } | undefined;
    if (extent?.mode === "toReference" && extent.end !== undefined) {
      requireRefKind(
        context,
        extent.end,
        "faces",
        ["parameters", "extent", "end"],
        "Sweep reference extent",
      );
    }
    return;
  }
}

export const sweepOperationV2Schema = raw.sweepOperationV2Schema.superRefine(
  refineProfessionalOperation,
);
export const sweepOperationSchema = raw.sweepOperationSchema.superRefine(
  refineProfessionalOperation,
);
export const operationSchema = raw.operationSchema.superRefine(
  refineProfessionalOperation,
);
export const persistedOperationSchema =
  raw.persistedOperationSchema.superRefine(refineProfessionalOperation);
export const wireOperationSchema = raw.wireOperationSchema.superRefine(
  refineProfessionalOperation,
);
