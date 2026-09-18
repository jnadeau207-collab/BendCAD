import subprocess

from native_tooling import (
    ROOT,
    bootstrap_tools,
    build_assembly_host,
    build_kernel_host,
    build_occt,
    checkout_occt,
    kernel_runtime_environment,
    pnpm_command,
    run_assembly_unit_tests,
    run_kernel_unit_tests,
)


def main() -> None:
    bootstrap_tools()
    checkout_occt()
    build_occt()
    build_kernel_host()
    build_assembly_host()
    # Native C++ unit tests first: they are fast and cover geometry the kernel
    # protocol cannot express, so a regression there fails before the heavier
    # integration suites spin up real OCCT host processes.
    run_kernel_unit_tests()
    # Same rationale for the assembly host: its native unit tests are fast and
    # exercise the solver adapter/collision world directly, so a regression
    # there fails before the heavier TS integration suites spin up real
    # assembly-host sidecar processes.
    run_assembly_unit_tests()
    env = kernel_runtime_environment()
    # Native-gated TypeScript suites must execute against the just-built native
    # hosts. A cached Turbo result is not evidence for this lane.
    env["TURBO_FORCE"] = "1"
    subprocess.run(
        [
            pnpm_command(),
            "turbo",
            "run",
            "build",
            "--filter=@aeth/kernel-client",
            "--filter=@aeth/assembly",
            "--filter=@aeth/assembly-client",
            "--filter=@aeth/viewport",
            "--filter=@aeth/reference-tournament",
            "--filter=@aeth/agent-orchestrator",
            "--filter=@aeth/desktop",
            "--force",
        ],
        cwd=ROOT,
        env=env,
        check=True,
    )
    subprocess.run(
        [
            pnpm_command(),
            # One package suite at a time: each suite spawns real OCCT host
            # processes doing write-then-reopen disk I/O, and running three of
            # them concurrently starved CI runners into transient STEP
            # inspect failures (different test each run, unreproducible on a
            # developer machine).
            "--workspace-concurrency=1",
            "--filter",
            "@aeth/kernel-client",
            # packages/assembly and packages/assembly-client own the ASM-002
            # native-gated integration suite (native.integration.test.ts);
            # omitting them from this filter list means that suite never runs
            # in ANY lane, passing by never being loaded — the exact CAP-022
            # gap.
            "--filter",
            "@aeth/assembly",
            "--filter",
            "@aeth/assembly-client",
            "--filter",
            "@aeth/viewport",
            "--filter",
            "@aeth/reference-tournament",
            "--filter",
            "@aeth/agent-orchestrator",
            # apps/desktop owns the native-gated desktop suites. Without this
            # filter none of them ran in any lane: `resolveNativeGate` only
            # fails closed when something actually loads the file, and nothing
            # did. They were passing by never executing.
            "--filter",
            "@aeth/desktop",
            "test",
        ],
        cwd=ROOT,
        env=env,
        check=True,
    )


if __name__ == "__main__":
    main()
