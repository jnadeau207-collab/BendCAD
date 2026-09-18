/**
 * Native-kernel test gate — loud-fail-on-missing-OCCT (audit
 * docs/audits/2026-07-17-plan-realignment.md §4.I backlog 0.2;
 * docs/design/2026-07-19-verification-integrity.md §4).
 *
 * Replaces the silent `describe.skip` ternary: with no explicit opt-out, a
 * missing kernel host FAILS the suite at collection time instead of shrinking
 * native coverage to a green no-op. Environment contract:
 *
 * - `AETH_KERNEL_HOST_PATH` — path to the built kernel host, injected only by
 *   tools/build-native/native_tooling.py `kernel_runtime_environment()`. When
 *   present the native describes run.
 * - `AETH_REQUIRE_NATIVE=1` — hard requirement (native CI lanes, native:*
 *   drivers): a missing host path throws even when the opt-out below is also
 *   set, so an ambient opt-out can never neuter a native lane.
 * - `AETH_ALLOW_MISSING_KERNEL=1` — explicit opt-out for kernel-less TS-only
 *   lanes and sandboxes: the native describes skip, visibly, as vitest skips.
 *
 * Flags accept exactly "" / "0" (off) and "1" (on); any other value throws so
 * a typo ("true", "yes", …) can never silently select a mode. Fail closed.
 *
 * This file is intentionally duplicated byte-for-byte into every test dir
 * hosting native-gated suites (there is no shared test-util package); the
 * no-drift meta-test in packages/kernel-client/test/native-gate.test.ts pins
 * all copies to the unit-tested copy. Edit all copies together.
 */
import { describe } from "vitest";

/** Machine-readable cause of a gate failure. */
export type NativeGateFailureReason = "kernel-host-missing" | "invalid-flag";

/** Typed, structured gate failure — free-text-only errors are forbidden. */
export class NativeGateError extends Error {
  public readonly reason: NativeGateFailureReason;
  /** The offending flag name for `invalid-flag`, absent otherwise. */
  public readonly flag?: string;

  public constructor(
    message: string,
    reason: NativeGateFailureReason,
    flag?: string,
  ) {
    super(message);
    this.name = "NativeGateError";
    this.reason = reason;
    if (flag !== undefined) this.flag = flag;
  }
}

/** Resolved gate outcome; a demanded-but-missing kernel host throws instead. */
export type NativeGateDecision =
  { readonly mode: "run" } | { readonly mode: "skip"; readonly reason: string };

const onValues = ["1"] as const;
const offValues = [undefined, "", "0"] as const;

function flagIsSet(
  env: Readonly<Record<string, string | undefined>>,
  name: string,
): boolean {
  const value = env[name];
  if ((onValues as readonly (string | undefined)[]).includes(value))
    return true;
  if ((offValues as readonly (string | undefined)[]).includes(value))
    return false;
  throw new NativeGateError(
    `${name} must be "1" (on) or ""/"0" (off); got ${JSON.stringify(value)}. ` +
      "Refusing to guess a native-coverage mode from an unrecognized value.",
    "invalid-flag",
    name,
  );
}

/**
 * Pure decision core (unit-tested without touching process.env): given an
 * environment, decide whether native suites run, skip, or must fail loudly.
 */
export function resolveNativeGate(
  env: Readonly<Record<string, string | undefined>>,
): NativeGateDecision {
  // Validate BOTH flags up front so an invalid value is loud even on the
  // paths where that flag would not have decided the outcome.
  const required = flagIsSet(env, "AETH_REQUIRE_NATIVE");
  const allowMissing = flagIsSet(env, "AETH_ALLOW_MISSING_KERNEL");
  if (env["AETH_KERNEL_HOST_PATH"]) return { mode: "run" };
  if (required || !allowMissing) {
    throw new NativeGateError(
      "kernel host missing — native coverage silently shrank: " +
        "AETH_KERNEL_HOST_PATH is not set" +
        (required
          ? " and AETH_REQUIRE_NATIVE=1 hard-requires it. Build and run the " +
            "host via `pnpm native:test` (AETH_ALLOW_MISSING_KERNEL=1 cannot " +
            "opt out of a hard requirement)."
          : " and native coverage is on by default. Build and run the host " +
            "via `pnpm native:test`, or acknowledge the gap explicitly with " +
            "AETH_ALLOW_MISSING_KERNEL=1 (TS-only lanes)."),
      "kernel-host-missing",
    );
  }
  return {
    mode: "skip",
    reason:
      "AETH_ALLOW_MISSING_KERNEL=1 acknowledged a missing kernel host; " +
      "native suites skip.",
  };
}

/**
 * Pure selection seam: picks the run-vs-skip implementation for a resolved
 * environment. Exists because vitest's `describe.skip` is a chainable getter
 * that mints a fresh function per property access, so the unit test pins the
 * selection with sentinels through this seam instead of identity-comparing
 * `describe.skip`.
 */
export function gatedDescribe<Api>(
  implementations: Readonly<{ run: Api; skip: Api }>,
  env: Readonly<Record<string, string | undefined>>,
): Api {
  return resolveNativeGate(env).mode === "run"
    ? implementations.run
    : implementations.skip;
}

/**
 * The suite-facing gate: `const describeNative = nativeDescribe();` at module
 * scope. Throwing here fails the file at vitest collection time — the loud
 * failure the audit demands — while the opt-out keeps `describe.skip`'s
 * visible skip markers for kernel-less lanes.
 */
export function nativeDescribe(): typeof describe | typeof describe.skip {
  return gatedDescribe<typeof describe | typeof describe.skip>(
    { run: describe, skip: describe.skip },
    process.env,
  );
}
