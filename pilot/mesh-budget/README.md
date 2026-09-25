# Pilot: mesh-budget port

Pilot port of `legacy/aethalgard/packages/geometry-contracts/src/mesh-budget.ts`
(evaluation-budget admission) to Bend. It proves the port approach; it is not
kernel code and carries no production contract.

- `mesh_budget.bend`: the port (246 lines).
- `main.bend`: entry point replaying the oracle vectors and printing the line
  protocol, ending in a `selfcheck fails=N` line.
- `oracle.ts`: runs the ORIGINAL legacy module under bun and prints the same
  protocol. Bend lanes must match its stdout byte for byte.
- `expected.sha256`: sha256 of the oracle stdout.

Verify (from this directory, with the `BEND_PIN` toolchain installed):

```sh
bun oracle.ts > oracle.out && sha256sum -c expected.sha256
bend main.bend | cmp - oracle.out
bend main.bend -o /tmp/mb-native && /tmp/mb-native | cmp - oracle.out
bend main.bend -o /tmp/mb.js && bun /tmp/mb.js | cmp - oracle.out
```

Verified 2026-09-25: oracle, interpreted, native and JS lanes all exit 0 with
stdout sha256 `d35d8fe997c0f464fddb3748b360e75b20a6f129c5fa007e22b64abb032a0fdc`,
on `bend` rebuilt from fork tag `numeric/2026-09-25`.

Scope note: this pilot exercises integer/U64/control-flow logic only. Float
formatting, transcendental ops, string-heavy and array-heavy ports are not
demonstrated here.
