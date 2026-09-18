import { maxPacketBytes } from "@aeth/geometry-contracts";

const binaryMagic = 0x314d_4241;
const headerBytes = 12;
// The per-packet wire byte cap is a product budget (mesh-budget.ts): one body's
// packet may not exceed 48 MiB. An overrun is framing corruption and poisons
// the connection below, before any buffer of the claimed size is allocated.
const defaultMaximumPacketBytes = maxPacketBytes;

export interface BinaryMeshFrame {
  readonly streamSequence: number;
  readonly packet: ArrayBuffer;
}

export class BinaryFrameError extends Error {
  public constructor(message: string) {
    super(message);
    this.name = "BinaryFrameError";
  }
}

export class BinaryMeshFrameDecoder {
  readonly #maximumPacketBytes: number;
  readonly #header = Buffer.alloc(headerBytes);
  #headerOffset = 0;
  #packet: Buffer | undefined;
  #packetOffset = 0;
  #streamSequence = 0;
  #poisoned = false;

  public constructor(maximumPacketBytes = defaultMaximumPacketBytes) {
    this.#maximumPacketBytes = maximumPacketBytes;
  }

  public push(chunk: Uint8Array): BinaryMeshFrame[] {
    if (this.#poisoned) {
      throw new BinaryFrameError("Binary mesh decoder is poisoned");
    }
    const source = Buffer.from(
      chunk.buffer,
      chunk.byteOffset,
      chunk.byteLength,
    );
    const frames: BinaryMeshFrame[] = [];
    let offset = 0;
    while (offset < source.byteLength) {
      if (!this.#packet) {
        const headerBytesToCopy = Math.min(
          headerBytes - this.#headerOffset,
          source.byteLength - offset,
        );
        source.copy(
          this.#header,
          this.#headerOffset,
          offset,
          offset + headerBytesToCopy,
        );
        this.#headerOffset += headerBytesToCopy;
        offset += headerBytesToCopy;
        if (this.#headerOffset < headerBytes) continue;
        if (this.#header.readUInt32LE(0) !== binaryMagic) {
          this.#poisoned = true;
          throw new BinaryFrameError("Invalid binary mesh frame magic");
        }
        this.#streamSequence = this.#header.readUInt32LE(4);
        const packetLength = this.#header.readUInt32LE(8);
        if (packetLength === 0 || packetLength > this.#maximumPacketBytes) {
          this.#poisoned = true;
          throw new BinaryFrameError("Invalid binary mesh packet length");
        }
        this.#packet = Buffer.allocUnsafe(packetLength);
        this.#packetOffset = 0;
      }

      const packet = this.#packet;
      const packetBytesToCopy = Math.min(
        packet.byteLength - this.#packetOffset,
        source.byteLength - offset,
      );
      source.copy(
        packet,
        this.#packetOffset,
        offset,
        offset + packetBytesToCopy,
      );
      this.#packetOffset += packetBytesToCopy;
      offset += packetBytesToCopy;
      if (this.#packetOffset < packet.byteLength) continue;

      const packetBuffer =
        packet.byteOffset === 0 &&
        packet.byteLength === packet.buffer.byteLength
          ? (packet.buffer as ArrayBuffer)
          : (packet.buffer.slice(
              packet.byteOffset,
              packet.byteOffset + packet.byteLength,
            ) as ArrayBuffer);
      frames.push({
        streamSequence: this.#streamSequence,
        packet: packetBuffer,
      });
      this.#headerOffset = 0;
      this.#packet = undefined;
      this.#packetOffset = 0;
    }
    return frames;
  }
}
