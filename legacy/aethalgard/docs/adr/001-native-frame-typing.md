# ADR-001: Split native control and mesh streams

- Status: Accepted
- Date: 2026-07-12
- Owners: geometry runtime

## Context

The TypeScript control codec is an unreleased `u32 length + UTF-8 JSON` frame. Native geometry
also needs to transfer mesh packets that may be hundreds of megabytes. Multiplexing both payload
classes onto stdout would require a kind byte, but a large mesh write would then head-of-line block
cancellation, health, and error responses. Any accidental native-library stdout write would also
poison both traffic classes.

## Decision

Keep stdout as the control-only stream and add a dedicated inherited binary pipe at fd 3. Control
frames retain their existing format. Binary frames use `ABM1 + streamSequence + packetByteLength`
followed by one AEMB1 packet. Both decoders are bounded; any framing, UTF-8, JSON, schema, magic,
length, or checksum failure is connection-fatal. The supervisor kills the process and invalidates
the process epoch before restart.

This supersedes the NG-1 work order's provisional single-stream kind-byte proposal. Separate pipes
preserve cancellation responsiveness and make OCCT diagnostic redirection independently testable.

## Consequences

- Control traffic never interleaves with mesh bytes.
- The process launcher must create fd 3 on every platform.
- A mesh descriptor correlates the binary packet by stream sequence and CRC-32.
- Resynchronization after corruption is forbidden.
