import { maxPacketBytes } from "@aeth/geometry-contracts";
import { describe, expect, it } from "vitest";

import { BinaryFrameError, BinaryMeshFrameDecoder } from "../src/index.js";

function frame(sequence: number, payload: Uint8Array): Uint8Array {
  const result = new Uint8Array(12 + payload.byteLength);
  const view = new DataView(result.buffer);
  view.setUint32(0, 0x314d_4241, true);
  view.setUint32(4, sequence, true);
  view.setUint32(8, payload.byteLength, true);
  result.set(payload, 12);
  return result;
}

/** A 12-byte frame header declaring `packetLength` without the payload. */
function header(sequence: number, packetLength: number): Uint8Array {
  const result = new Uint8Array(12);
  const view = new DataView(result.buffer);
  view.setUint32(0, 0x314d_4241, true);
  view.setUint32(4, sequence, true);
  view.setUint32(8, packetLength, true);
  return result;
}

describe("binary mesh frame decoder", () => {
  it("reassembles a fragmented packet", () => {
    const encoded = frame(17, Uint8Array.of(1, 2, 3, 4));
    const decoder = new BinaryMeshFrameDecoder();
    expect(decoder.push(encoded.subarray(0, 9))).toEqual([]);
    const decoded = decoder.push(encoded.subarray(9));
    expect(decoded[0]?.streamSequence).toBe(17);
    expect([...new Uint8Array(decoded[0]?.packet)]).toEqual([1, 2, 3, 4]);
  });

  it("treats framing corruption as connection-fatal", () => {
    const decoder = new BinaryMeshFrameDecoder();
    expect(() => decoder.push(new Uint8Array(12))).toThrow(BinaryFrameError);
    expect(() => decoder.push(frame(1, Uint8Array.of(1)))).toThrow(/poisoned/);
  });

  it("rejects a packet length over the 48 MiB cap before allocating (finding-8)", () => {
    // The default ceiling is the product per-packet byte cap (48 MiB); a header
    // declaring one byte more is framing corruption and poisons the decoder
    // BEFORE any buffer of the claimed size is allocated.
    expect(maxPacketBytes).toBe(48 * 1024 * 1024);
    const decoder = new BinaryMeshFrameDecoder();
    expect(() => decoder.push(header(1, maxPacketBytes + 1))).toThrow(
      BinaryFrameError,
    );
    expect(() => decoder.push(frame(2, Uint8Array.of(1)))).toThrow(/poisoned/);
  });
});
