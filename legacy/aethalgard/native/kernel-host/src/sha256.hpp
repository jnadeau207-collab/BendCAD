#pragma once

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <string>

// FIPS 180-4 SHA-256. Extracted verbatim from element_names.cpp (which still
// uses Sha256Hex8 for the element-name grammar) so the operation-hash contract
// can share ONE vetted implementation instead of duplicating it. This is the
// C++ twin of packages/geometry-contracts/src/sha256.ts; both implement the
// same standard and are pinned byte-for-byte by the operation-hash golden
// vectors. Header-only: the whole thing is small and constant-folded, and two
// translation units (element_names, operation_hash) need it.
namespace aeth {

inline constexpr std::array<std::uint32_t, 64> kSha256RoundConstants = {
    0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u, 0x3956c25bu, 0x59f111f1u, 0x923f82a4u,
    0xab1c5ed5u, 0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u, 0x72be5d74u, 0x80deb1feu,
    0x9bdc06a7u, 0xc19bf174u, 0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu, 0x2de92c6fu,
    0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau, 0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u,
    0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u, 0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu,
    0x53380d13u, 0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u, 0xa2bfe8a1u, 0xa81a664bu,
    0xc24b8b70u, 0xc76c51a3u, 0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u, 0x19a4c116u,
    0x1e376c08u, 0x2748774cu, 0x34b0bcb5u, 0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,
    0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u, 0x90befffau, 0xa4506cebu, 0xbef9a3f7u,
    0xc67178f2u};

class Sha256 final {
public:
  void Update(const unsigned char* data, std::size_t length) {
    totalBytes_ += length;
    while (length > 0) {
      const std::size_t take = std::min<std::size_t>(64 - bufferFill_, length);
      std::copy(data, data + take, buffer_.begin() + static_cast<std::ptrdiff_t>(bufferFill_));
      bufferFill_ += take;
      data += take;
      length -= take;
      if (bufferFill_ == 64) {
        Compress();
        bufferFill_ = 0;
      }
    }
  }

  // Finalizes the hash and returns the 32 raw digest bytes. Single-use: the
  // padding it appends mutates state, so call Digest() (or HexDigest()) once.
  std::array<std::uint8_t, 32> Digest() {
    const std::uint64_t bitLength = totalBytes_ * 8;
    const unsigned char padStart = 0x80;
    Update(&padStart, 1);
    const unsigned char zero = 0;
    while (bufferFill_ != 56)
      Update(&zero, 1);
    std::array<unsigned char, 8> lengthBytes{};
    for (std::size_t byteIndex = 0; byteIndex < 8; ++byteIndex) {
      lengthBytes[byteIndex] =
          static_cast<unsigned char>((bitLength >> (56 - 8 * byteIndex)) & 0xFFu);
    }
    Update(lengthBytes.data(), 8);
    std::array<std::uint8_t, 32> digest{};
    for (std::size_t wordIndex = 0; wordIndex < 8; ++wordIndex) {
      const std::uint32_t word = state_[wordIndex];
      digest[wordIndex * 4] = static_cast<std::uint8_t>((word >> 24) & 0xFFu);
      digest[wordIndex * 4 + 1] = static_cast<std::uint8_t>((word >> 16) & 0xFFu);
      digest[wordIndex * 4 + 2] = static_cast<std::uint8_t>((word >> 8) & 0xFFu);
      digest[wordIndex * 4 + 3] = static_cast<std::uint8_t>(word & 0xFFu);
    }
    return digest;
  }

  std::string HexDigest() {
    static constexpr char kHexDigits[] = "0123456789abcdef";
    std::string hex;
    hex.reserve(64);
    for (const std::uint8_t byte : Digest()) {
      hex.push_back(kHexDigits[(byte >> 4) & 0xFu]);
      hex.push_back(kHexDigits[byte & 0xFu]);
    }
    return hex;
  }

private:
  void Compress() {
    std::array<std::uint32_t, 64> schedule{};
    for (std::size_t wordIndex = 0; wordIndex < 16; ++wordIndex) {
      schedule[wordIndex] = (static_cast<std::uint32_t>(buffer_[wordIndex * 4]) << 24) |
                            (static_cast<std::uint32_t>(buffer_[wordIndex * 4 + 1]) << 16) |
                            (static_cast<std::uint32_t>(buffer_[wordIndex * 4 + 2]) << 8) |
                            static_cast<std::uint32_t>(buffer_[wordIndex * 4 + 3]);
    }
    for (std::size_t wordIndex = 16; wordIndex < 64; ++wordIndex) {
      const std::uint32_t w15 = schedule[wordIndex - 15];
      const std::uint32_t w2 = schedule[wordIndex - 2];
      const std::uint32_t sigma0 = std::rotr(w15, 7) ^ std::rotr(w15, 18) ^ (w15 >> 3);
      const std::uint32_t sigma1 = std::rotr(w2, 17) ^ std::rotr(w2, 19) ^ (w2 >> 10);
      schedule[wordIndex] = schedule[wordIndex - 16] + sigma0 + schedule[wordIndex - 7] + sigma1;
    }
    std::uint32_t a = state_[0];
    std::uint32_t b = state_[1];
    std::uint32_t c = state_[2];
    std::uint32_t d = state_[3];
    std::uint32_t e = state_[4];
    std::uint32_t f = state_[5];
    std::uint32_t g = state_[6];
    std::uint32_t h = state_[7];
    for (std::size_t round = 0; round < 64; ++round) {
      const std::uint32_t bigSigma1 = std::rotr(e, 6) ^ std::rotr(e, 11) ^ std::rotr(e, 25);
      const std::uint32_t choose = (e & f) ^ (~e & g);
      const std::uint32_t temp1 =
          h + bigSigma1 + choose + kSha256RoundConstants[round] + schedule[round];
      const std::uint32_t bigSigma0 = std::rotr(a, 2) ^ std::rotr(a, 13) ^ std::rotr(a, 22);
      const std::uint32_t majority = (a & b) ^ (a & c) ^ (b & c);
      const std::uint32_t temp2 = bigSigma0 + majority;
      h = g;
      g = f;
      f = e;
      e = d + temp1;
      d = c;
      c = b;
      b = a;
      a = temp1 + temp2;
    }
    state_[0] += a;
    state_[1] += b;
    state_[2] += c;
    state_[3] += d;
    state_[4] += e;
    state_[5] += f;
    state_[6] += g;
    state_[7] += h;
  }

  std::array<std::uint32_t, 8> state_{0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u, 0xa54ff53au,
                                      0x510e527fu, 0x9b05688cu, 0x1f83d9abu, 0x5be0cd19u};
  std::array<unsigned char, 64> buffer_{};
  std::size_t bufferFill_ = 0;
  std::uint64_t totalBytes_ = 0;
};

// The 32-byte SHA-256 digest of a byte range.
inline std::array<std::uint8_t, 32> Sha256Bytes(const unsigned char* data, std::size_t length) {
  Sha256 hasher;
  hasher.Update(data, length);
  return hasher.Digest();
}

// First 8 hex characters of the SHA-256 of `input` — the element-name grammar's
// collision-resistant short hash (element_names.cpp).
inline std::string Sha256Hex8(const std::string& input) {
  Sha256 hasher;
  hasher.Update(reinterpret_cast<const unsigned char*>(input.data()), input.size());
  return hasher.HexDigest().substr(0, 8);
}

} // namespace aeth
