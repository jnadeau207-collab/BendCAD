# ADR-0001 — Windows is a first-class platform, effective immediately

Status: ACCEPTED (founder directive, 2026-07-13). Supersedes MASTER_PLAN §6 Blocker 3
("use the current development machine as the first green platform").

## Decision

Aethalgard must be entirely Windows-compatible from now — not at release, not after
Linux stabilizes. The founder's primary test machine is Windows and is the canonical
hardware-testing target. Deferring Windows was an error by both AI builders: the
target user base is overwhelmingly Windows (Steam-class gaming PCs), and every
boundary built Linux-first accrues porting debt that compounds.

## Binding requirements (apply to every existing and future package)

1. tools/build-native (bootstrap/build/format/test) must support Windows: MSVC
   toolchain detection, OCCT V8_0_0_p1 CMake preset for win-x64, kernel-host build
   and install layout, path/quoting/process-spawn correctness (no POSIX-only calls).
2. The Electron launch qualification must run on Windows natively (no WSL
   requirement): display handling, user-data paths, and evidence artifacts identical.
3. CI adds a windows-latest lane running pnpm check, native:test, and
   native:test:electron with artifact upload — required, not optional.
4. All IPC, file, journal, and .aeth code must be verified for Windows semantics:
   CRLF, path separators, file locking, atomic-rename behavior, UNC paths.
5. No merge that breaks the Windows lane. Green means green on Windows and Linux.

## Immediate next actions

The founder is beginning Windows corrections now. Both builders treat Windows gaps
as release-blocking defects, not platform backlog.
