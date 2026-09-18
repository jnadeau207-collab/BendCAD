/**
 * Unit proof of the loud-fail native gate (audit §4.I backlog 0.2b;
 * docs/design/2026-07-19-verification-integrity.md §4) — runnable with NO OCCT
 * build: every row of the decision matrix is pinned against the pure core, and
 * a no-drift meta-test pins the byte-identical sibling copies so the
 * deliberate duplication (no shared test-util package) can never fork.
 */
import { readdirSync, readFileSync } from "node:fs";

import { afterEach, describe, expect, it, vi } from "vitest";

import {
  NativeGateError,
  gatedDescribe,
  nativeDescribe,
  resolveNativeGate,
  type NativeGateDecision,
} from "./native-gate.js";

type Env = Readonly<Record<string, string | undefined>>;

/** Every accepted "off" spelling for a flag (absent, empty, explicit zero). */
const offSpellings: readonly (string | undefined)[] = [undefined, "", "0"];

function makeEnv(
  hostPath: string | undefined,
  require_: string | undefined,
  allow: string | undefined,
): Env {
  return {
    AETH_KERNEL_HOST_PATH: hostPath,
    AETH_REQUIRE_NATIVE: require_,
    AETH_ALLOW_MISSING_KERNEL: allow,
  };
}

function decisionOf(env: Env): NativeGateDecision {
  return resolveNativeGate(env);
}

describe("resolveNativeGate", () => {
  it.each([
    ["no flags", makeEnv("/opt/kernel/aeth-kernel-host", undefined, undefined)],
    ["hard-required", makeEnv("/opt/kernel/aeth-kernel-host", "1", undefined)],
    [
      "opt-out also set",
      makeEnv("/opt/kernel/aeth-kernel-host", undefined, "1"),
    ],
    ["both flags set", makeEnv("/opt/kernel/aeth-kernel-host", "1", "1")],
  ])("runs when the kernel host path is set (%s)", (_label, env) => {
    expect(decisionOf(env)).toEqual({ mode: "run" });
  });

  it("fails loudly BY DEFAULT when the host path is missing (audit: coverage on-by-default)", () => {
    for (const require_ of offSpellings) {
      for (const allow of offSpellings) {
        for (const hostPath of [undefined, ""]) {
          expect(() => decisionOf(makeEnv(hostPath, require_, allow))).toThrow(
            NativeGateError,
          );
          expect(() => decisionOf(makeEnv(hostPath, require_, allow))).toThrow(
            /kernel host missing — native coverage silently shrank/,
          );
        }
      }
    }
  });

  it("default failure names both sanctioned exits (build the host, or opt out)", () => {
    expect(() => decisionOf(makeEnv(undefined, undefined, undefined))).toThrow(
      /pnpm native:test.*AETH_ALLOW_MISSING_KERNEL=1/s,
    );
  });

  it("fails loudly when AETH_REQUIRE_NATIVE=1 and the host path is missing", () => {
    let caught: unknown;
    try {
      decisionOf(makeEnv(undefined, "1", undefined));
    } catch (error) {
      caught = error;
    }
    expect(caught).toBeInstanceOf(NativeGateError);
    const gateError = caught as NativeGateError;
    expect(gateError.name).toBe("NativeGateError");
    expect(gateError.reason).toBe("kernel-host-missing");
    expect(gateError.flag).toBeUndefined();
    expect(gateError.message).toMatch(
      /kernel host missing — native coverage silently shrank/,
    );
    expect(gateError.message).toMatch(/AETH_REQUIRE_NATIVE=1 hard-requires/);
  });

  it("AETH_REQUIRE_NATIVE=1 beats the opt-out: an ambient opt-out cannot neuter a native lane", () => {
    expect(() => decisionOf(makeEnv(undefined, "1", "1"))).toThrow(
      NativeGateError,
    );
    expect(() => decisionOf(makeEnv("", "1", "1"))).toThrow(
      /native coverage silently shrank/,
    );
  });

  it("skips only under the explicit opt-out AETH_ALLOW_MISSING_KERNEL=1", () => {
    for (const require_ of offSpellings) {
      const decision = decisionOf(makeEnv(undefined, require_, "1"));
      expect(decision.mode).toBe("skip");
      if (decision.mode === "skip") {
        expect(decision.reason).toMatch(/AETH_ALLOW_MISSING_KERNEL=1/);
      }
    }
  });

  it.each([
    ["AETH_REQUIRE_NATIVE", "true"],
    ["AETH_REQUIRE_NATIVE", "yes"],
    ["AETH_REQUIRE_NATIVE", " 1"],
    ["AETH_REQUIRE_NATIVE", "2"],
    ["AETH_ALLOW_MISSING_KERNEL", "true"],
    ["AETH_ALLOW_MISSING_KERNEL", "on"],
    ["AETH_ALLOW_MISSING_KERNEL", "1 "],
  ])("refuses to guess a mode from %s=%j", (flag, value) => {
    const base: Record<string, string | undefined> = makeEnv(
      undefined,
      undefined,
      undefined,
    );
    let caught: unknown;
    try {
      decisionOf({ ...base, [flag]: value });
    } catch (error) {
      caught = error;
    }
    expect(caught).toBeInstanceOf(NativeGateError);
    const gateError = caught as NativeGateError;
    expect(gateError.reason).toBe("invalid-flag");
    expect(gateError.flag).toBe(flag);
    expect(gateError.message).toContain(flag);
    expect(gateError.message).toContain(JSON.stringify(value));
  });

  it("validates flags up front, even when the host path would decide the outcome", () => {
    // Fail-closed: a typo'd flag is a misconfiguration and must be loud on
    // EVERY path, not only on the branch that would have consulted it.
    expect(() =>
      decisionOf(makeEnv("/opt/kernel/aeth-kernel-host", "true", undefined)),
    ).toThrow(NativeGateError);
    expect(() =>
      decisionOf(makeEnv("/opt/kernel/aeth-kernel-host", undefined, "yes")),
    ).toThrow(NativeGateError);
  });
});

describe("gatedDescribe (pure selection seam)", () => {
  // Sentinels instead of vitest's own describe/describe.skip: `describe.skip`
  // is a chainable getter minting a fresh function per access, so identity
  // assertions must go through this seam (see the helper's doc comment).
  const sentinels = { run: Symbol("run"), skip: Symbol("skip") } as const;

  it("selects the running implementation when the host path is set", () => {
    expect(
      gatedDescribe(
        sentinels,
        makeEnv("/opt/kernel/aeth-kernel-host", "1", undefined),
      ),
    ).toBe(sentinels.run);
  });

  it("selects the skipping implementation under the explicit opt-out", () => {
    expect(gatedDescribe(sentinels, makeEnv(undefined, undefined, "1"))).toBe(
      sentinels.skip,
    );
  });

  it("throws through the seam when the host is demanded but missing", () => {
    expect(() =>
      gatedDescribe(sentinels, makeEnv(undefined, "1", "1")),
    ).toThrow(NativeGateError);
    expect(() =>
      gatedDescribe(sentinels, makeEnv(undefined, undefined, undefined)),
    ).toThrow(NativeGateError);
  });
});

describe("nativeDescribe (process.env wiring)", () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("returns the running describe when the host path is set", () => {
    vi.stubEnv("AETH_KERNEL_HOST_PATH", "/opt/kernel/aeth-kernel-host");
    vi.stubEnv("AETH_REQUIRE_NATIVE", "1");
    vi.stubEnv("AETH_ALLOW_MISSING_KERNEL", "0");
    expect(nativeDescribe()).toBe(describe);
  });

  it("returns a non-running describe, without throwing, under the explicit opt-out", () => {
    vi.stubEnv("AETH_KERNEL_HOST_PATH", "");
    vi.stubEnv("AETH_REQUIRE_NATIVE", "0");
    vi.stubEnv("AETH_ALLOW_MISSING_KERNEL", "1");
    const gated = nativeDescribe();
    // Identity with `describe.skip` is unassertable (fresh function per
    // access); the exact skip selection is pinned by the sentinel suite above.
    expect(gated).not.toBe(describe);
    expect(typeof gated).toBe("function");
  });

  it("throws at gate time (collection time in a suite) when the host is demanded but missing", () => {
    vi.stubEnv("AETH_KERNEL_HOST_PATH", "");
    vi.stubEnv("AETH_REQUIRE_NATIVE", "1");
    vi.stubEnv("AETH_ALLOW_MISSING_KERNEL", "1");
    expect(() => nativeDescribe()).toThrow(NativeGateError);
  });

  it("throws by default when nothing is configured", () => {
    vi.stubEnv("AETH_KERNEL_HOST_PATH", "");
    vi.stubEnv("AETH_REQUIRE_NATIVE", "");
    vi.stubEnv("AETH_ALLOW_MISSING_KERNEL", "");
    expect(() => nativeDescribe()).toThrow(/native coverage silently shrank/);
  });
});

describe("native-gate copies do not drift", () => {
  // The helper is deliberately duplicated byte-for-byte (no shared test-util
  // package; see the helper header). This meta-test pins every copy to the
  // unit-tested one, kernel-error-registry-no-drift style, so an edit that
  // misses a copy fails here instead of silently forking gate semantics.
  const canonical = readFileSync(
    new URL("./native-gate.ts", import.meta.url),
    "utf8",
  );

  it.each([
    ["packages/viewport", "../../viewport/test/native-gate.ts"],
    [
      "packages/agent-orchestrator",
      "../../agent-orchestrator/test/native-gate.ts",
    ],
    ["apps/desktop", "../../../apps/desktop/test/native-gate.ts"],
    [
      "tools/reference-tournament",
      "../../../tools/reference-tournament/test/native-gate.ts",
    ],
  ])("%s copy is byte-identical to the tested copy", (_label, relativePath) => {
    const copy = readFileSync(new URL(relativePath, import.meta.url), "utf8");
    expect(copy).toBe(canonical);
  });
});

describe("no native-gated suite reintroduces the retired silent-skip ternary", () => {
  // The gap that let the catalog-wave1 suite ship the pre-W0
  // `executable ? describe : describe.skip` unnoticed: nothing scanned the
  // suites themselves. This pins that a native-gated `*.integration.test.ts`
  // never gates through the silent-skip ternary — it must use nativeDescribe().
  const retiredTernary = /\?\s*describe\s*:\s*describe\.skip/;
  const testDirs = [
    "./",
    "../../viewport/test/",
    "../../agent-orchestrator/test/",
    "../../../apps/desktop/test/",
    "../../../tools/reference-tournament/test/",
  ];

  it("every *.integration.test.ts uses nativeDescribe(), not the silent-skip ternary", () => {
    const offenders: string[] = [];
    for (const dir of testDirs) {
      const dirUrl = new URL(dir, import.meta.url);
      for (const entry of readdirSync(dirUrl)) {
        if (!entry.endsWith(".integration.test.ts")) continue;
        const source = readFileSync(new URL(entry, dirUrl), "utf8");
        if (retiredTernary.test(source)) offenders.push(`${dir}${entry}`);
      }
    }
    expect(offenders).toEqual([]);
  });
});
