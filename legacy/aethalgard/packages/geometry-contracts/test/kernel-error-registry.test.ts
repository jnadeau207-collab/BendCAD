import { describe, expect, it } from "vitest";

import {
  describeKernelError,
  kernelErrorRegistry,
  kernelErrorSchema,
} from "../src/index.js";

describe("kernel error registry (no-drift meta-test)", () => {
  const wireCodes = [...kernelErrorSchema.shape.code.options];

  it("registers exactly the wire error codes the kernel can raise", () => {
    // Every code the wire enum can carry has a descriptor, and the registry has
    // no descriptor for a code the wire enum cannot carry — so C++ (which emits
    // the enum) and this TS metadata cannot drift.
    expect(Object.keys(kernelErrorRegistry).sort()).toEqual(
      [...wireCodes].sort(),
    );
  });

  it("gives every code a well-formed descriptor", () => {
    for (const code of wireCodes) {
      const descriptor = describeKernelError(code);
      expect(["error", "warning"]).toContain(descriptor.severity);
      expect(typeof descriptor.retryable).toBe("boolean");
      expect(descriptor.agentHint.length).toBeGreaterThan(0);
    }
  });

  it("marks transient conditions retryable and design defects not", () => {
    expect(describeKernelError("BUSY").retryable).toBe(true);
    expect(describeKernelError("CANCELLED").retryable).toBe(true);
    // A per-op timeout is retryable after the agent simplifies/splits the step.
    expect(describeKernelError("TIMEOUT").retryable).toBe(true);
    expect(describeKernelError("TIMEOUT").severity).toBe("error");
    expect(describeKernelError("GEOMETRY_FAILED").retryable).toBe(false);
    expect(describeKernelError("REFERENCE_AMBIGUOUS").retryable).toBe(false);
    expect(describeKernelError("INTERNAL_ERROR").retryable).toBe(false);
  });
});
