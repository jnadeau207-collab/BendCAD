from __future__ import annotations

import argparse
from pathlib import Path

from native_tooling import ROOT, bootstrap_tools, clang_format_command, run, tool_environment


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    arguments = parser.parse_args()
    bootstrap_tools()
    # third_party/ is VENDORED UPSTREAM. Reformatting it would rewrite
    # thousands of lines we do not own, void the sha256 provenance pins that
    # make a re-vendor drift detectable, and turn every upstream update into
    # a conflict. Our own shims beside each vendored tree are ours and stay
    # in scope. ondsel-solver's upstream (~440 files) dwarfs PlaneGCS's
    # (12) — excluding it matters even more.
    kernel_vendored = ROOT / "native" / "kernel-host" / "third_party"
    assembly_vendored = ROOT / "native" / "assembly-host" / "third_party"
    vendored_upstream = (
        kernel_vendored / "planegcs" / "upstream",
        assembly_vendored / "ondsel-solver" / "upstream",
    )
    sources = sorted(
        path
        for pattern in ("*.cpp", "*.hpp")
        for path in (ROOT / "native").rglob(pattern)
        if not any(path.is_relative_to(vendored) for vendored in vendored_upstream)
    )
    command: list[str | Path] = [clang_format_command()]
    command.extend(["-i"] if arguments.write else ["--dry-run", "--Werror"])
    command.extend(sources)
    run(command, env=tool_environment())


if __name__ == "__main__":
    main()
