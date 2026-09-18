import { z } from "zod";

import {
  operationRefSchema as coreOperationRefSchema,
  operationRefWireSchema as coreOperationRefWireSchema,
  referenceAnchorSchema as coreReferenceAnchorSchema,
} from "./refs-core.js";

export * from "./refs-core.js";

const referenceVector3Schema = z.tuple([
  z.number().finite(),
  z.number().finite(),
  z.number().finite(),
]);

/**
 * Analytic identity retained alongside the established topology token and
 * geometric signature. These fields are optional and non-authoritative, so
 * every existing document remains valid; new recordings give the native
 * two-channel resolver stronger evidence for coaxial and equal-measure twins.
 */
export const referenceAnchorSchema = coreReferenceAnchorSchema
  .extend({
    axis: z
      .object({
        origin: referenceVector3Schema,
        dir: referenceVector3Schema,
      })
      .strict()
      .optional(),
    radius: z.number().finite().nonnegative().optional(),
  })
  .strict();

export type ReferenceAnchor = z.infer<typeof referenceAnchorSchema>;

export const operationRefSchema = coreOperationRefSchema
  .extend({
    anchors: z.array(referenceAnchorSchema).max(64).default([]),
  })
  .strict();

export type OperationRef = z.infer<typeof operationRefSchema>;

export const operationRefWireSchema = coreOperationRefWireSchema
  .extend({
    anchors: z.array(referenceAnchorSchema).max(64).default([]),
  })
  .strict();

export type OperationRefWire = z.infer<typeof operationRefWireSchema>;
