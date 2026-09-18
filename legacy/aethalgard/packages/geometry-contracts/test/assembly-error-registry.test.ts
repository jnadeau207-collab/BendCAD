import { describe, expect, it } from "vitest";

import {
  assemblyErrorRegistry,
  assemblyErrorSchema,
  describeAssemblyError,
} from "../src/index.js";

describe("assembly error registry (no-drift meta-test)", () => {
  const wireCodes = [...assemblyErrorSchema.shape.code.options];

  it("registers exactly the wire error codes the assembly host can raise", () => {
    // Every code the wire enum can carry has a descriptor, and the registry has
    // no descriptor for a code the wire enum cannot carry — so C++ (which emits
    // the enum) and this TS metadata cannot drift.
    expect(Object.keys(assemblyErrorRegistry).sort()).toEqual(
      [...wireCodes].sort(),
    );
  });

  it("gives every code a well-formed descriptor", () => {
    for (const code of wireCodes) {
      const descriptor = describeAssemblyError(code);
      expect(["error", "warning"]).toContain(descriptor.severity);
      expect(typeof descriptor.retryable).toBe("boolean");
      expect(descriptor.agentHint.length).toBeGreaterThan(0);
    }
  });

  it("marks transient conditions retryable and design defects not", () => {
    expect(describeAssemblyError("CANCELLED").retryable).toBe(true);
    expect(describeAssemblyError("BUSY").retryable).toBe(true);
    expect(describeAssemblyError("INVALID_REQUEST").retryable).toBe(false);
  });
});
