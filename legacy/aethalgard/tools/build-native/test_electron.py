import os
import shutil
import subprocess
import sys
from pathlib import Path

from native_tooling import (
    ROOT,
    bootstrap_tools,
    build_assembly_host,
    build_kernel_host,
    build_occt,
    checkout_occt,
    kernel_runtime_environment,
    pnpm_command,
)


def qualify_environment() -> None:
    if sys.platform.startswith("linux") and hasattr(os, "geteuid") and os.geteuid() == 0:
        raise SystemExit(
            "Electron qualification must run as an unprivileged user with Chromium's sandbox "
            "enabled. Enter the checkout as a non-root user; do not add --no-sandbox."
        )


def local_bypass(value: str | None) -> str:
    entries = [entry.strip() for entry in (value or "").split(",") if entry.strip()]
    for required in ("localhost", "127.0.0.1", "::1"):
        if required not in entries:
            entries.append(required)
    return ",".join(entries)


def under_virtual_display(command: list[str], env: dict[str, str]) -> list[str]:
    if not sys.platform.startswith("linux") or env.get("DISPLAY"):
        return command
    xvfb_run = shutil.which("xvfb-run")
    if not xvfb_run:
        raise SystemExit(
            "Electron qualification requires DISPLAY or xvfb-run on Linux. "
            "Install Xvfb or run inside a graphical session."
        )
    return [
        xvfb_run,
        "--auto-servernum",
        "--server-args=-screen 0 1440x960x24",
        *command,
    ]


def main() -> None:
    qualify_environment()
    bootstrap_tools()
    checkout_occt()
    build_occt()
    build_kernel_host()
    build_assembly_host()
    env = kernel_runtime_environment()
    bypass = local_bypass(env.get("NO_PROXY") or env.get("no_proxy"))
    env["NO_PROXY"] = bypass
    env["no_proxy"] = bypass
    subprocess.run(
        [
            pnpm_command(),
            "turbo",
            "run",
            "build",
            "--filter=@aeth/desktop",
        ],
        cwd=ROOT,
        env=env,
        check=True,
    )
    qualifier_command = under_virtual_display(
        [pnpm_command(), "--filter", "@aeth/desktop", "test:electron"], env
    )

    # One native/desktop build, then two fresh-profile renderer qualifications.
    # The harness requires this variable and asserts the actual post-init
    # backend, so neither local nor CI can silently substitute auto-fallback
    # WebGL2 for the WebGPU proof. Evidence is isolated per backend and stale
    # output is removed before either run.
    artifact_root = Path(
        env.get("AETH_ELECTRON_ARTIFACT_DIR", ROOT / ".native-cache/electron-launch")
    )
    shutil.rmtree(artifact_root, ignore_errors=True)
    failures: list[tuple[str, int]] = []
    for backend in ("webgpu", "webgl2"):
        run_env = env.copy()
        run_env["AETH_ELECTRON_TEST_BACKEND"] = backend
        run_env["AETH_ELECTRON_ARTIFACT_DIR"] = str(artifact_root / backend)
        completed = subprocess.run(
            qualifier_command,
            cwd=ROOT,
            env=run_env,
            check=False,
        )
        if completed.returncode != 0:
            failures.append((backend, completed.returncode))
    if failures:
        summary = ", ".join(
            f"{backend} (exit {returncode})" for backend, returncode in failures
        )
        raise SystemExit(f"Electron backend qualification failed: {summary}")

    # Task #38's surfacing/mold tour is a native product gate, not screenshot
    # documentation. Run it only after both renderer backends have qualified,
    # using the SAME kernel runtime and Chromium sandbox. SwiftShader is used
    # only for this feature-flow pass so the gate measures CAD behavior rather
    # than requiring a third GPU-backend proof; the two backend runs above own
    # that responsibility already.
    tour_env = env.copy()
    tour_env["AETH_TOUR_SHOTS"] = str(artifact_root / "surfacing-mold")
    if sys.platform.startswith("linux"):
        tour_env["AETH_TOUR_GL"] = "swiftshader"
    tour_command = under_virtual_display(
        [pnpm_command(), "--filter", "@aeth/desktop", "test:surfacing-mold-tour"],
        tour_env,
    )
    completed = subprocess.run(
        tour_command,
        cwd=ROOT,
        env=tour_env,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(
            f"Surfacing/mold Electron qualification failed (exit {completed.returncode})"
        )


if __name__ == "__main__":
    main()
