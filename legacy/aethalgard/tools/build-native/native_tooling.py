from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any, Sequence

ROOT = Path(__file__).resolve().parents[2]
TOOLS_DIR = ROOT / ".native-tools" / "python"
CACHE_DIR = ROOT / ".native-cache"
OCCT_SOURCE = CACHE_DIR / "occt-src"
OCCT_BUILD = CACHE_DIR / "occt-build"
OCCT_INSTALL = CACHE_DIR / "occt-install"
OCCT_RUNTIME = CACHE_DIR / "occt-runtime"
KERNEL_BUILD = CACHE_DIR / "kernel-host-build"
KERNEL_INSTALL = CACHE_DIR / "kernel-host-install"
ASSEMBLY_BUILD = CACHE_DIR / "assembly-host-build"
ASSEMBLY_INSTALL = CACHE_DIR / "assembly-host-install"
MANIFEST_PATH = Path(__file__).with_name("manifest.json")
OCCT_MANIFEST_PATH = ROOT / "native" / "third_party" / "occt.manifest.json"
# Canonical OCCT toolkit link set, shared with native/kernel-host/CMakeLists.txt.
OCCT_TOOLKITS_PATH = ROOT / "native" / "kernel-host" / "occt-toolkits.json"
OCCT_BUILD_STAMP = OCCT_INSTALL / ".aeth-build.json"


def manifest() -> dict[str, Any]:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def occt_manifest() -> dict[str, Any]:
    return json.loads(OCCT_MANIFEST_PATH.read_text(encoding="utf-8"))


def occt_linked_toolkits() -> list[str]:
    """The full toolkit set the kernel host links, from the canonical shared
    list that CMake also consumes. Validating every one of these against the
    cache is what keeps the check honest with the actual link line."""
    return list(json.loads(OCCT_TOOLKITS_PATH.read_text(encoding="utf-8"))["toolkits"])


def run(args: Sequence[str | Path], *, cwd: Path = ROOT, env: dict[str, str] | None = None) -> None:
    rendered = [str(value) for value in args]
    print("+", " ".join(rendered), flush=True)
    subprocess.run(rendered, cwd=cwd, env=env, check=True)


def command(name: str) -> str:
    """Resolve executables including Windows command shims such as pnpm.cmd."""
    resolved = shutil.which(name)
    if resolved:
        return resolved
    raise RuntimeError(f"Required command is not available on PATH: {name}")


def pnpm_command() -> str:
    return command("pnpm")


def require_native_compiler() -> None:
    if os.name != "nt":
        return
    missing = [tool for tool in ("cl.exe", "link.exe") if shutil.which(tool) is None]
    if missing:
        raise RuntimeError(
            "MSVC x64 build tools are required on Windows. Run this command from a "
            "Visual Studio 2022 Developer PowerShell/Command Prompt or install the "
            f"Desktop development with C++ workload. Missing: {', '.join(missing)}"
        )


def tool_environment() -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(TOOLS_DIR) + os.pathsep + env.get("PYTHONPATH", "")
    env["PATH"] = str(TOOLS_DIR / "bin") + os.pathsep + env.get("PATH", "")
    return env


def kernel_runtime_environment() -> dict[str, str]:
    """Environment shared by native integration tests and the desktop host."""
    executable = KERNEL_INSTALL / "bin" / (
        "aeth-kernel-host.exe" if os.name == "nt" else "aeth-kernel-host"
    )
    env = os.environ.copy()
    env.setdefault("CI", "true")
    env.setdefault("XDG_CACHE_HOME", str(ROOT / ".native-tools" / "xdg" / "cache"))
    env.setdefault("XDG_CONFIG_HOME", str(ROOT / ".native-tools" / "xdg" / "config"))
    env.setdefault("XDG_DATA_HOME", str(ROOT / ".native-tools" / "xdg" / "data"))
    env.setdefault("XDG_STATE_HOME", str(ROOT / ".native-tools" / "xdg" / "state"))
    env.setdefault("PNPM_STORE_DIR", str(ROOT / ".native-tools" / "pnpm-store"))
    env["AETH_KERNEL_HOST_PATH"] = str(executable)
    env["AETH_ASSEMBLY_HOST_PATH"] = str(
        ASSEMBLY_INSTALL / "bin" / ("aeth-assembly-host.exe" if os.name == "nt" else "aeth-assembly-host")
    )
    # Loud-fail native gate (docs/design/2026-07-19-verification-integrity.md
    # §4.3): every native:* driver run hard-requires the host it just built, so
    # a tooling regression that drops the path fails the suites instead of
    # letting them skip to green. Overrides any ambient opt-out by design.
    env["AETH_REQUIRE_NATIVE"] = "1"
    env["CASROOT"] = str(KERNEL_INSTALL)
    env["CSF_OCCTResourcePath"] = str(
        KERNEL_INSTALL / "share" / "opencascade" / "resources"
    )
    if os.name == "nt":
        env["PATH"] = str(KERNEL_INSTALL / "bin") + os.pathsep + env.get("PATH", "")
    else:
        loader_variable = (
            "DYLD_LIBRARY_PATH" if sys.platform == "darwin" else "LD_LIBRARY_PATH"
        )
        env[loader_variable] = str(KERNEL_INSTALL / "lib") + os.pathsep + env.get(
            loader_variable, ""
        )
    return env


def cmake_command() -> Path:
    suffix = ".exe" if os.name == "nt" else ""
    return TOOLS_DIR / "bin" / f"cmake{suffix}"


def ninja_command() -> Path:
    suffix = ".exe" if os.name == "nt" else ""
    return TOOLS_DIR / "bin" / f"ninja{suffix}"


def clang_format_command() -> Path:
    suffix = ".exe" if os.name == "nt" else ""
    return TOOLS_DIR / "clang_format" / "data" / "bin" / f"clang-format{suffix}"


def bootstrap_tools() -> None:
    config = manifest()
    cmake_version = config["cmake"]["version"]
    ninja_version = config["ninja"]["version"]
    clang_format_version = config["clangFormat"]["version"]
    if cmake_command().exists() and ninja_command().exists() and clang_format_command().exists():
        env = tool_environment()
        try:
            cmake_output = subprocess.check_output(
                [cmake_command(), "--version"], env=env, text=True
            ).splitlines()[0]
            ninja_output = subprocess.check_output(
                [ninja_command(), "--version"], env=env, text=True
            ).strip()
            clang_format_output = subprocess.check_output(
                [clang_format_command(), "--version"], env=env, text=True
            ).strip()
            if (
                cmake_output == f"cmake version {cmake_version}"
                and ninja_output.startswith(ninja_version)
                and f"version {clang_format_version}" in clang_format_output
            ):
                return
        except (OSError, subprocess.SubprocessError, IndexError):
            pass
        shutil.rmtree(TOOLS_DIR, ignore_errors=True)
    TOOLS_DIR.mkdir(parents=True, exist_ok=True)
    run(
        [
            sys.executable,
            "-m",
            "pip",
            "install",
            "--disable-pip-version-check",
            "--no-input",
            "--target",
            TOOLS_DIR,
            f"cmake=={cmake_version}",
            f"ninja=={ninja_version}",
            f"clang-format=={clang_format_version}",
        ]
    )


def checkout_occt() -> None:
    config = occt_manifest()
    expected_commit = config["commit"]
    if not OCCT_SOURCE.exists():
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        run(
            [
                "git",
                "clone",
                "--filter=blob:none",
                "--depth",
                "1",
                "--branch",
                config["tag"],
                config["repository"],
                OCCT_SOURCE,
            ]
        )
    actual_commit = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=OCCT_SOURCE, text=True
    ).strip()
    if actual_commit != expected_commit:
        raise RuntimeError(
            f"OCCT source mismatch: expected {expected_commit}, found {actual_commit}. "
            f"Delete {OCCT_SOURCE} and bootstrap again."
        )


def configure_occt() -> None:
    require_native_compiler()
    config = occt_manifest()
    env = tool_environment()
    arguments: list[str | Path] = [
        cmake_command(),
        "-S",
        OCCT_SOURCE,
        "-B",
        OCCT_BUILD,
        "-G",
        "Ninja",
        f"-DCMAKE_MAKE_PROGRAM={ninja_command()}",
        "-DCMAKE_BUILD_TYPE=Release",
        f"-DCMAKE_INSTALL_PREFIX={OCCT_INSTALL}",
        f"-DINSTALL_DIR={OCCT_INSTALL}",
        "-DINSTALL_DIR_WITH_VERSION=OFF",
        f"-DBUILD_LIBRARY_TYPE={config['libraryType']}",
        f"-DINSTALL_DIR_LAYOUT={config['installLayout']}",
        f"-DBUILD_CPP_STANDARD=C++{config['cxxStandard']}",
        f"-DBUILD_ADDITIONAL_TOOLKITS={';'.join(config['toolkits'])}",
        "-DBUILD_DOC_Overview=OFF",
        "-DBUILD_DOC_RefMan=OFF",
    ]
    arguments.extend(f"-DBUILD_MODULE_{module}=OFF" for module in config["modulesDisabled"])
    arguments.extend(f"-DUSE_{dependency}=OFF" for dependency in config["optionalDependenciesDisabled"])
    run(arguments, env=env)


def occt_build_fingerprint() -> str:
    build_manifest = manifest()
    config = {
        "schemaVersion": build_manifest["schemaVersion"],
        "occt": occt_manifest(),
    }
    encoded = json.dumps(config, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def occt_runtime_libraries(toolkit: str) -> tuple[Path, ...]:
    """Platform-specific runtime artifact path(s) for one OCCT toolkit."""
    if os.name == "nt":
        return (
            OCCT_RUNTIME / "bin" / f"{toolkit}.dll",
            OCCT_RUNTIME / "lib" / f"{toolkit}.lib",
        )
    if sys.platform == "darwin":
        return (OCCT_RUNTIME / "lib" / f"lib{toolkit}.dylib",)
    return (OCCT_RUNTIME / "lib" / f"lib{toolkit}.so",)


def occt_install_is_current() -> bool:
    required_toolkits = occt_linked_toolkits()
    required_paths = [OCCT_INSTALL / "include" / "opencascade" / "TopoDS_Shape.hxx"]
    for toolkit in required_toolkits:
        required_paths.extend(occt_runtime_libraries(toolkit))
    try:
        stamp = json.loads(OCCT_BUILD_STAMP.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return False
    return stamp.get("fingerprint") == occt_build_fingerprint() and all(
        path.exists() for path in required_paths
    )


def materialize_occt_runtime() -> None:
    if os.name == "nt":
        runtime_bin = OCCT_RUNTIME / "bin"
        runtime_lib = OCCT_RUNTIME / "lib"
        shutil.rmtree(OCCT_RUNTIME, ignore_errors=True)
        runtime_bin.mkdir(parents=True, exist_ok=True)
        runtime_lib.mkdir(parents=True, exist_ok=True)
        for library in (OCCT_INSTALL / "bin").glob("*.dll"):
            shutil.copy2(library, runtime_bin / library.name)
        for library in (OCCT_INSTALL / "lib").glob("*.lib"):
            shutil.copy2(library, runtime_lib / library.name)
        return
    if sys.platform == "darwin":
        library_directory = OCCT_INSTALL / "lib"
        runtime_directory = OCCT_RUNTIME / "lib"
        shutil.rmtree(runtime_directory, ignore_errors=True)
        runtime_directory.mkdir(parents=True, exist_ok=True)
        version_pattern = re.compile(r"^(lib.+)\.(\d+)\.(\d+)\.(\d+)\.dylib$")
        for library in library_directory.glob("lib*.*.*.*.dylib"):
            match = version_pattern.match(library.name)
            if not match or library.is_symlink():
                continue
            stem, major, minor, _patch = match.groups()
            for destination in (
                runtime_directory / library.name,
                runtime_directory / f"{stem}.{major}.{minor}.dylib",
                runtime_directory / f"{stem}.dylib",
            ):
                shutil.copy2(library, destination)
        return
    if not sys.platform.startswith("linux"):
        return
    library_directory = OCCT_INSTALL / "lib"
    runtime_directory = OCCT_RUNTIME / "lib"
    shutil.rmtree(runtime_directory, ignore_errors=True)
    runtime_directory.mkdir(parents=True, exist_ok=True)
    version_pattern = re.compile(r"^(lib.+\.so)\.(\d+)\.(\d+)\.(\d+)$")
    for library in library_directory.glob("lib*.so.*.*.*"):
        match = version_pattern.match(library.name)
        if not match or library.is_symlink():
            continue
        unversioned, major, minor, _patch = match.groups()
        for destination in (
            runtime_directory / f"{unversioned}.{major}.{minor}",
            runtime_directory / unversioned,
        ):
            shutil.copy2(library, destination)


def write_occt_build_stamp() -> None:
    OCCT_BUILD_STAMP.write_text(
        json.dumps(
            {
                "fingerprint": occt_build_fingerprint(),
                "manifest": occt_manifest(),
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )


def build_occt() -> None:
    require_native_compiler()
    if occt_install_is_current():
        print(f"OCCT install is current: {OCCT_INSTALL}", flush=True)
        return
    env = tool_environment()
    configure_occt()
    run([cmake_command(), "--build", OCCT_BUILD, "--parallel"], env=env)
    run([cmake_command(), "--install", OCCT_BUILD], env=env)
    materialize_occt_runtime()
    write_occt_build_stamp()


def build_kernel_host() -> None:
    require_native_compiler()
    env = tool_environment()
    if sys.platform.startswith("linux"):
        current = env.get("LD_LIBRARY_PATH", "")
        env["LD_LIBRARY_PATH"] = str(OCCT_RUNTIME / "lib") + os.pathsep + current
    elif sys.platform == "darwin":
        current = env.get("DYLD_LIBRARY_PATH", "")
        env["DYLD_LIBRARY_PATH"] = str(OCCT_RUNTIME / "lib") + os.pathsep + current
    run(
        [
            cmake_command(),
            "-S",
            ROOT / "native" / "kernel-host",
            "-B",
            KERNEL_BUILD,
            "-G",
            "Ninja",
            f"-DCMAKE_MAKE_PROGRAM={ninja_command()}",
            "-DCMAKE_BUILD_TYPE=Release",
            f"-DCMAKE_INSTALL_PREFIX={KERNEL_INSTALL}",
            f"-DOCCT_ROOT={OCCT_INSTALL}",
            f"-DOCCT_LIBRARY_ROOT={OCCT_RUNTIME / 'lib'}",
            f"-DAETH_OCCT_MANIFEST_SHA256={hashlib.sha256(OCCT_MANIFEST_PATH.read_bytes()).hexdigest()}",
        ],
        env=env,
    )
    run([cmake_command(), "--build", KERNEL_BUILD, "--parallel", "1"], env=env)
    run([cmake_command(), "--install", KERNEL_BUILD], env=env)


def build_assembly_host() -> None:
    require_native_compiler()
    env = tool_environment()
    run(
        [
            cmake_command(),
            "-S",
            ROOT / "native" / "assembly-host",
            "-B",
            ASSEMBLY_BUILD,
            "-G",
            "Ninja",
            f"-DCMAKE_MAKE_PROGRAM={ninja_command()}",
            "-DCMAKE_BUILD_TYPE=Release",
            f"-DCMAKE_INSTALL_PREFIX={ASSEMBLY_INSTALL}",
        ],
        env=env,
    )
    run([cmake_command(), "--build", ASSEMBLY_BUILD, "--parallel"], env=env)
    run([cmake_command(), "--install", ASSEMBLY_BUILD], env=env)


def run_kernel_unit_tests() -> None:
    suffix = ".exe" if os.name == "nt" else ""
    binaries = [
        KERNEL_BUILD / f"aeth-hole-entry-test{suffix}",
        KERNEL_BUILD / f"aeth-step-export-test{suffix}",
        KERNEL_BUILD / f"aeth-step-import-test{suffix}",
        KERNEL_BUILD / f"aeth-mesh-import-test{suffix}",
        KERNEL_BUILD / f"aeth-naming-registry-test{suffix}",
        KERNEL_BUILD / f"aeth-selector-evaluator-test{suffix}",
        KERNEL_BUILD / f"aeth-ref-resolution-test{suffix}",
        KERNEL_BUILD / f"aeth-catalog-wave1-test{suffix}",
        KERNEL_BUILD / f"aeth-catalog-wave2-test{suffix}",
        KERNEL_BUILD / f"aeth-body-pool-snapshot-test{suffix}",
        KERNEL_BUILD / f"aeth-canonical-hash-test{suffix}",
        KERNEL_BUILD / f"aeth-selector-print-test{suffix}",
        KERNEL_BUILD / f"aeth-replay-cache-test{suffix}",
        KERNEL_BUILD / f"aeth-operation-watchdog-test{suffix}",
        KERNEL_BUILD / f"aeth-tessellate-lod-test{suffix}",
        KERNEL_BUILD / f"aeth-bounded-feasibility-test{suffix}",
        KERNEL_BUILD / f"aeth-tolerance-budget-test{suffix}",
        KERNEL_BUILD / f"aeth-local-face-offset-test{suffix}",
        KERNEL_BUILD / f"aeth-sketch-solver-test{suffix}",
        KERNEL_BUILD / f"aeth-sketch-region-test{suffix}",
        KERNEL_BUILD / f"aeth-extrude-topology-test{suffix}",
        KERNEL_BUILD / f"aeth-revolve-topology-test{suffix}",
    ]
    env = kernel_runtime_environment()
    # The Revolve tournament writes a machine-readable case record so the
    # tournament record can prove zero failures and a non-shrinking case count
    # instead of scraping stdout.
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    env["AETH_REVOLVE_TOURNAMENT_JSON"] = str(CACHE_DIR / "revolve-tournament.json")
    for binary in binaries:
        if not binary.exists():
            raise RuntimeError(
                f"native unit test binary is missing (build the kernel host first): {binary}"
            )
        run([binary], env=env)


def run_assembly_unit_tests() -> None:
    """Run every admitted native C++ assembly-host test executable.

    Keep this list aligned with native/assembly-host/CMakeLists.txt. Omitting a
    target here makes `pnpm native:test` pass without exercising that contract.
    """
    suffix = ".exe" if os.name == "nt" else ""
    binaries = [
        ASSEMBLY_BUILD / f"aeth-solver-adapter-test{suffix}",
        ASSEMBLY_BUILD / f"aeth-server-protocol-test{suffix}",
    ]
    env = kernel_runtime_environment()
    for binary in binaries:
        if not binary.exists():
            raise RuntimeError(
                f"native unit test binary is missing (build the assembly host first): {binary}"
            )
        run([binary], env=env)


def clean_native_cache() -> None:
    for path in (
        OCCT_BUILD,
        OCCT_INSTALL,
        OCCT_RUNTIME,
        KERNEL_BUILD,
        KERNEL_INSTALL,
        ASSEMBLY_BUILD,
        ASSEMBLY_INSTALL,
    ):
        shutil.rmtree(path, ignore_errors=True)
