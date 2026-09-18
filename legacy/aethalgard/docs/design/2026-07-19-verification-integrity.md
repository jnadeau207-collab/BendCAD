# Verification Integrity — Design Note (Wave 0)

**Date:** 2026-07-19
**Track:** realignment backlog **0.1 / 0.2 / 0.3** (`docs/audits/2026-07-17-plan-realignment.md`
§4.I, §5.10 [r10]; ledger `docs/execution/2026-07-17-realignment-workflow.md` lines 25–27, both
DEFERRED).
**Packages:** repo root (`.nvmrc`, `package.json` volta key, `turbo.json`), `.github/workflows/`,
`tools/build-native/native_tooling.py`, and the gating lines of the 21 native-gated suites in
`packages/kernel-client`, `packages/viewport`, `packages/agent-orchestrator`,
`tools/reference-tournament`.
**Normative source:** audit §4.I ("Build / verification") — the three Wave-0 fixes that make every
later "green" claim trustworthy: a real Node pin, a Turbo hash that cannot launder a skip into a
cached pass, and native coverage that is **on by default with a loud failure when OCCT is missing**.

This is the mandated design pass (workspace rule #5). No geometry or product behavior changes; every
deliverable is a verification-integrity seam.

---

## 1. Scope of this slice

| Item | Deliverable                                                                                      | Verify (audit-verbatim signal)                                                          |
| ---- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| 0.1  | `.nvmrc` = `24.14.0`; `volta.node`/`volta.pnpm` keys in root `package.json`                      | `pnpm check` runs with no per-command config flags on the pinned Node                   |
| 0.2a | `turbo.json` `test` task declares `env` for the kernel-host path + runtime vars + gate flags     | `turbo run test --dry=json` hashes differ with vs. without `AETH_KERNEL_HOST_PATH`      |
| 0.2b | Loud-fail native gate (`test/native-gate.ts`, 4 byte-identical copies) replacing `describe.skip` | Unset host path + no opt-out ⇒ vitest FAILS at collection; unit + no-drift tests pin it |
| 0.3  | `.github/workflows/quality.yml` TS lane (no path filter) + native-lane path-filter closure fix   | A PR touching only `packages/ui` (or docs) runs CI                                      |

## 2. Node pin (0.1)

`.nvmrc` contains exactly `24.14.0` (the version CI's `setup-node` pins) and root `package.json`
gains `"volta": { "node": "24.14.0", "pnpm": "11.12.0" }`, matching `engines` (`>=24.14.0 <25`) and
`packageManager` (`pnpm@11.12.0`). `engineStrict: true` in `pnpm-workspace.yaml` stays the enforcing
gate; the pin files make the supported toolchain discoverable by nvm/Volta instead of tribal.

Sanctioned bootstrap on nvm machines: `source /opt/nvm/nvm.sh && nvm use` (reads `.nvmrc`). A box
carrying a newer 24.x (e.g. 24.18.0 under the `24` alias) may `nvm use 24`: `engines` accepts any
`>=24.14.0 <25`, and `engineStrict` refuses anything below the floor — which is exactly the failure
this machine previously exhibited in the opposite direction (node 22 below the range forcing
one-off `--engine-strict=false` flags). Volta users need no incantation; the `volta` key is the pin.

## 3. Turbo test-task env truth (0.2a)

`turbo.json`'s `test` task declared `inputs` but no `env`, so the task hash was blind to
`AETH_KERNEL_HOST_PATH`. The live poisoning sequence in `native-geometry.yml`: `pnpm native:test`
runs package `test` scripts via pnpm recursive (var set, real native runs, no turbo cache written),
then `pnpm check` runs `turbo run test` WITHOUT the var — natively-gated describes skip, pass, and
are cached; any later env-set `turbo run test` is served the cached skip-pass as green.

Fix — the `test` task declares:

```json
"env": [
  "AETH_ALLOW_MISSING_KERNEL",
  "AETH_KERNEL_HOST_PATH",
  "AETH_REPLAY_CACHE",
  "AETH_REQUIRE_NATIVE",
  "CASROOT",
  "CSF_OCCTResourcePath",
  "DYLD_LIBRARY_PATH",
  "LD_LIBRARY_PATH"
]
```

`CASROOT`/`CSF_OCCTResourcePath`/loader paths are forwarded to spawned kernel hosts by
`nativeEnvironment()` in the native suites (`packages/kernel-client/test/native.integration.test.ts`
and siblings), so they are genuine task inputs. The two gate flags (§4) are an addition beyond the
backlog item's list, for the same reason the item exists at all: gate _behavior_ (run / skip /
fail) is part of the task's input space, so a skip-pass produced under the opt-out must never be
cache-served to a run that demands native coverage. `PATH` is deliberately excluded (it is also in
`nativeEnvironment()`'s forward list, but hashing `PATH` would fracture caching per machine while
the kernel-relevant portion is already captured by `AETH_KERNEL_HOST_PATH` + the loader paths).

## 4. Loud-fail native gate (0.2b)

### 4.1 Environment contract

The silent pattern `const describeNative = executable ? describe : describe.skip;` (21 files) is
replaced by a shared guard with this contract, resolved at suite **collection** time:

| `AETH_KERNEL_HOST_PATH` | `AETH_REQUIRE_NATIVE` | `AETH_ALLOW_MISSING_KERNEL` | Outcome                                                     |
| ----------------------- | --------------------- | --------------------------- | ----------------------------------------------------------- |
| set (non-empty)         | any                   | any                         | run (`describe`)                                            |
| missing                 | `1`                   | any (even `1`)              | **throw** `NativeGateError` — hard requirement wins         |
| missing                 | off                   | `1`                         | skip (`describe.skip`) — explicit, visible opt-out          |
| missing                 | off                   | off                         | **throw** `NativeGateError` — coverage is on by default     |
| any                     | other value           | other value                 | **throw** `NativeGateError` (`invalid-flag`) — no typo mode |

- Flags accept exactly `""`/`"0"` (off) and `"1"` (on); anything else (`true`, `yes`, …) throws so a
  misspelled opt-out can never silently pick a mode. Fail closed, never guess.
- Precedence is `REQUIRE > ALLOW`: an ambient opt-out exported in a developer shell (or leaked into
  a CI job) can never neuter a lane that demands native proof.
- The default (nothing set) **fails loudly** — audit-verbatim "integration coverage on-by-default
  with a loud failure when OCCT is missing". The error message carries the audit's phrase
  (`kernel host missing — native coverage silently shrank`) plus the two sanctioned exits: build the
  host (`pnpm native:test`) or acknowledge the gap (`AETH_ALLOW_MISSING_KERNEL=1`).
- **Recorded divergence:** the subsystem-map phrasing of 0.2b suggested skip-by-default with an
  opt-in `AETH_REQUIRE_NATIVE`. That inverts the audit's "on-by-default" requirement, so this slice
  implements default-fail + explicit opt-out, and keeps `AETH_REQUIRE_NATIVE=1` as the hard-require
  overlay for native lanes. Both envs exist; only the default differs from the map's sketch.

### 4.2 Module placement — 4 byte-identical copies + a no-drift meta-test

There is no shared test-util package, and inventing one for two functions would put a
`workspace:*` edge + lockfile churn into 4 packages mid-swarm. Instead `test/native-gate.ts` is
duplicated **byte-for-byte** into the four test dirs that host native-gated suites
(`packages/kernel-client`, `packages/viewport`, `packages/agent-orchestrator`,
`tools/reference-tournament`), following each package's existing test-dir convention. The copies
are pinned by `packages/kernel-client/test/native-gate.test.ts`:

- a table-driven unit suite over `resolveNativeGate(env)` covering every row (and every invalid
  flag value) of the §4.1 matrix — this is the required no-OCCT proof of the loud-fail path;
- a **no-drift meta-test** that reads all four copies and asserts byte-identity with the tested
  copy (same pattern as the kernel-error-registry no-drift test), so the duplication cannot fork.

The helper exports `resolveNativeGate` (pure, env passed in), `NativeGateError` (typed,
machine-readable `reason: "kernel-host-missing" | "invalid-flag"` + structured fields), and
`nativeDescribe()` which the suites call at module scope: `const describeNative = nativeDescribe();`
— an import-time throw fails the file at collection, which vitest reports as a suite failure, i.e.
loudly. The module itself is side-effect-free so the unit test can import it under any environment.
Filename conventions (`*.integration.test.ts` / `*.native.integration.test.ts`) and each file's
`const executable = process.env.AETH_KERNEL_HOST_PATH;` (still consumed by spawn calls) are
unchanged; only the gating line and the now-unused `describe` import are touched.

### 4.3 Producers of the environment

- `tools/build-native/native_tooling.py` `kernel_runtime_environment()` — the **only** injector of
  `AETH_KERNEL_HOST_PATH`/OCCT runtime vars — now also sets `AETH_REQUIRE_NATIVE=1`, so every
  `native:*` driver run hard-requires the host it just built (a tooling regression that dropped the
  path would fail the suites, not skip them).
- `.github/workflows/native-geometry.yml`: both jobs set `AETH_REQUIRE_NATIVE: "1"` at job level.
  The `pnpm check` step overrides with `AETH_REQUIRE_NATIVE: "0"` + `AETH_ALLOW_MISSING_KERNEL: "1"`
  and a why-comment: its `turbo run test` runs kernel-less by design (native coverage already ran,
  REQUIRE'd, in the preceding `pnpm native:test` step), and after §3 its skip-pass hashes can no
  longer poison env-set runs.
- `.github/workflows/quality.yml` (§5) sets `AETH_ALLOW_MISSING_KERNEL: "1"` at job level — the
  TS-only lane's explicit, recorded acknowledgment that it owns no native coverage.

## 5. CI lanes (0.3)

**`quality.yml` — TS fast lane.** Runs on every PR and on trunk pushes with **no path filter**, so
all 14 packages — 11 of which had zero CI — and docs-only PRs get at least lint + typecheck + test +
build + format. Steps mirror the proven install sequence from `native-geometry.yml` (checkout,
setup-node `24.14.0`, `npm install --global pnpm@11.12.0`, `pnpm install --frozen-lockfile`) then
`pnpm lint`, `pnpm turbo run typecheck test build`, `pnpm format:check`. `native:format:check` is
deliberately absent (needs the python/clang-format bootstrap; the native lane owns it). The lane
never builds OCCT; the §4 opt-out makes that an explicit contract instead of a silent skip.

**`native-geometry.yml` path-filter fix.** The filter listed only 3 of the packages whose changes
alter native-lane behavior. Both lists (pull_request + push) now carry the full workspace dependency
closure of the four natively-tested packages (`kernel-client`, `viewport`, `reference-tournament`,
`agent-orchestrator` — the exact set `tools/build-native/test.py` builds and tests):
`agent-contracts`, `agent-orchestrator`, `child-process-env`, `document-model`, `ipc`,
`model-runtime`, `ui` join the existing `geometry-contracts`, `kernel-client`, `viewport`. Notably
`packages/ipc` (kernel-client's transport substrate) previously did not trigger the native lane at
all. The windows lane already exists and is untouched (no second one).

## 6. Conformance / verification on this kernel-less machine

- `turbo run test --dry=json --filter=@aeth/kernel-client` with vs. without `AETH_KERNEL_HOST_PATH`
  produces different task hashes (0.2a acceptance, no binary needed).
- `AETH_REQUIRE_NATIVE=1` + unset path ⇒ `vitest run` on a gated package fails at collection with
  `NativeGateError: kernel host missing — native coverage silently shrank`; bare (no flags) fails
  identically; `AETH_ALLOW_MISSING_KERNEL=1` skips visibly (0.2b acceptance, no OCCT build).
- `AETH_ALLOW_MISSING_KERNEL=1 pnpm turbo run typecheck test` green workspace-wide (the mandated
  kernel-less bar), plus eslint `--max-warnings 0` and prettier on every touched file.
- Workflow YAML is validated by construction/lint locally; the end-to-end "PR touching only
  `packages/ui` runs CI" signal is only observable on a pushed PR — flagged for the orchestrator.

## 7. Deferred / hazards recorded

- **Integration hazard:** after this slice, a kernel-less `turbo run test` / `pnpm check` fails
  loudly unless `AETH_ALLOW_MISSING_KERNEL=1` is exported (or a built host is on
  `AETH_KERNEL_HOST_PATH`). This is the audit's intended default. Sibling swarm branches adding
  native-gated suites with the old `describe.skip` ternary should migrate to `nativeDescribe()` at
  integration (the no-drift test only pins existing copies, it cannot see new ternaries).
- The end-to-end 0.3 acceptance (a `packages/ui`-only PR actually triggering both lanes) needs a
  pushed PR — orchestrator-side.
- `apps/desktop`'s `preload-artifact.test.ts` uses `describe.skipIf(!existsSync(outDir))` — a
  build-artifact gate, not a kernel gate; out of 0.2b's scope and left as is.
- Aligning this machine's _default_ node (v22 without nvm) is an environment concern; the sanctioned
  bootstrap (§2) is documented instead of mutating the box image.
