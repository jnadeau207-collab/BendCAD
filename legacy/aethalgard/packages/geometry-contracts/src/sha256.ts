/**
 * FIPS 180-4 SHA-256, pure and isomorphic (no `node:crypto`, no Web Crypto —
 * this package is `target: "isomorphic"`, and the cumulative operation hash is a
 * synchronous chain). It is the TypeScript twin of the kernel-host's
 * `native/kernel-host/src/sha256.hpp`; both implement the same standard and are
 * pinned byte-for-byte against each other by the operation-hash golden vectors,
 * so a divergence in either is caught, not shipped.
 */

// prettier-ignore
const ROUND_CONSTANTS = new Uint32Array([
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]);

// Bounds-checked read: `noUncheckedIndexedAccess` types typed-array access as
// `number | undefined`, and non-null assertions are disallowed. Indices here are
// always in range, so the throw is unreachable — it just satisfies the checker
// honestly instead of asserting.
function readU32(array: Uint32Array, index: number): number {
  const value = array[index];
  if (value === undefined) {
    throw new Error(`sha256: word index ${index} out of range`);
  }
  return value;
}

function rotr(value: number, bits: number): number {
  return (value >>> bits) | (value << (32 - bits));
}

/** The 32-byte SHA-256 digest of `data`. */
export function sha256(data: Uint8Array): Uint8Array {
  const state = new Uint32Array([
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c,
    0x1f83d9ab, 0x5be0cd19,
  ]);
  const bitLength = data.length * 8;
  const afterOne = data.length + 1;
  const total = afterOne + ((56 - (afterOne % 64) + 64) % 64) + 8;
  const message = new Uint8Array(total);
  message.set(data);
  message[data.length] = 0x80;
  const view = new DataView(message.buffer);
  view.setUint32(total - 8, Math.floor(bitLength / 0x100000000));
  view.setUint32(total - 4, bitLength >>> 0);

  const schedule = new Uint32Array(64);
  for (let offset = 0; offset < total; offset += 64) {
    for (let index = 0; index < 16; index += 1) {
      schedule[index] = view.getUint32(offset + index * 4);
    }
    for (let index = 16; index < 64; index += 1) {
      const w15 = readU32(schedule, index - 15);
      const w2 = readU32(schedule, index - 2);
      const sigma0 = rotr(w15, 7) ^ rotr(w15, 18) ^ (w15 >>> 3);
      const sigma1 = rotr(w2, 17) ^ rotr(w2, 19) ^ (w2 >>> 10);
      schedule[index] =
        (readU32(schedule, index - 16) +
          sigma0 +
          readU32(schedule, index - 7) +
          sigma1) >>>
        0;
    }
    let a = readU32(state, 0);
    let b = readU32(state, 1);
    let c = readU32(state, 2);
    let d = readU32(state, 3);
    let e = readU32(state, 4);
    let f = readU32(state, 5);
    let g = readU32(state, 6);
    let h = readU32(state, 7);
    for (let index = 0; index < 64; index += 1) {
      const bigSigma1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
      const choose = (e & f) ^ (~e & g);
      const temp1 =
        (h +
          bigSigma1 +
          choose +
          readU32(ROUND_CONSTANTS, index) +
          readU32(schedule, index)) >>>
        0;
      const bigSigma0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
      const majority = (a & b) ^ (a & c) ^ (b & c);
      const temp2 = (bigSigma0 + majority) >>> 0;
      h = g;
      g = f;
      f = e;
      e = (d + temp1) >>> 0;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) >>> 0;
    }
    state[0] = (readU32(state, 0) + a) >>> 0;
    state[1] = (readU32(state, 1) + b) >>> 0;
    state[2] = (readU32(state, 2) + c) >>> 0;
    state[3] = (readU32(state, 3) + d) >>> 0;
    state[4] = (readU32(state, 4) + e) >>> 0;
    state[5] = (readU32(state, 5) + f) >>> 0;
    state[6] = (readU32(state, 6) + g) >>> 0;
    state[7] = (readU32(state, 7) + h) >>> 0;
  }

  const digest = new Uint8Array(32);
  const digestView = new DataView(digest.buffer);
  for (let index = 0; index < 8; index += 1) {
    digestView.setUint32(index * 4, readU32(state, index));
  }
  return digest;
}

/** Lowercase hex of a byte array. */
export function bytesToHex(bytes: Uint8Array): string {
  let hex = "";
  for (const byte of bytes) {
    hex += byte.toString(16).padStart(2, "0");
  }
  return hex;
}

/** Concatenate byte arrays into one. */
export function concatBytes(...parts: readonly Uint8Array[]): Uint8Array {
  let length = 0;
  for (const part of parts) {
    length += part.length;
  }
  const out = new Uint8Array(length);
  let offset = 0;
  for (const part of parts) {
    out.set(part, offset);
    offset += part.length;
  }
  return out;
}
