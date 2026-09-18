#include "protocol.hpp"

#include <array>
#include <cstring>
#include <string>

namespace aeth {
namespace {

std::uint32_t ReadU32(const std::uint8_t* bytes) {
  return static_cast<std::uint32_t>(bytes[0]) | (static_cast<std::uint32_t>(bytes[1]) << 8U) |
         (static_cast<std::uint32_t>(bytes[2]) << 16U) |
         (static_cast<std::uint32_t>(bytes[3]) << 24U);
}

void WriteU32(std::uint8_t* bytes, const std::uint32_t value) {
  bytes[0] = static_cast<std::uint8_t>(value & 0xFFU);
  bytes[1] = static_cast<std::uint8_t>((value >> 8U) & 0xFFU);
  bytes[2] = static_cast<std::uint8_t>((value >> 16U) & 0xFFU);
  bytes[3] = static_cast<std::uint8_t>((value >> 24U) & 0xFFU);
}

} // namespace

bool ReadControlFrame(std::istream& input, nlohmann::json& value) {
  std::array<std::uint8_t, 4> header{};
  input.read(reinterpret_cast<char*>(header.data()), static_cast<std::streamsize>(header.size()));
  if (input.gcount() == 0 && input.eof())
    return false;
  if (input.gcount() != static_cast<std::streamsize>(header.size())) {
    throw ProtocolError("truncated control frame header");
  }
  const std::uint32_t length = ReadU32(header.data());
  if (length == 0 || length > kMaxControlFrameBytes) {
    throw ProtocolError("invalid control frame length");
  }
  std::string payload(length, '\0');
  input.read(payload.data(), static_cast<std::streamsize>(length));
  if (input.gcount() != static_cast<std::streamsize>(length)) {
    throw ProtocolError("truncated control frame payload");
  }
  value = nlohmann::json::parse(payload);
  return true;
}

ProtocolWriter::ProtocolWriter(std::ostream& control, std::FILE* binary)
    : control_(control), binary_(binary) {
  if (binary_ == nullptr)
    throw ProtocolError("binary mesh stream is unavailable");
}

void ProtocolWriter::WriteControl(const nlohmann::json& value) {
  const std::string payload = value.dump();
  if (payload.empty() || payload.size() > kMaxControlFrameBytes) {
    throw ProtocolError("control response exceeds the frame budget");
  }
  std::array<std::uint8_t, 4> header{};
  WriteU32(header.data(), static_cast<std::uint32_t>(payload.size()));
  std::scoped_lock lock(controlMutex_);
  control_.write(reinterpret_cast<const char*>(header.data()),
                 static_cast<std::streamsize>(header.size()));
  control_.write(payload.data(), static_cast<std::streamsize>(payload.size()));
  control_.flush();
  if (!control_)
    throw ProtocolError("failed to write control response");
}

void ProtocolWriter::WriteMesh(const std::uint32_t sequence,
                               const std::vector<std::uint8_t>& packet) {
  if (packet.empty() || packet.size() > UINT32_MAX) {
    throw ProtocolError("binary mesh packet has an invalid size");
  }
  std::array<std::uint8_t, 12> header{};
  WriteU32(header.data(), kBinaryMeshMagic);
  WriteU32(header.data() + 4, sequence);
  WriteU32(header.data() + 8, static_cast<std::uint32_t>(packet.size()));
  std::scoped_lock lock(binaryMutex_);
  if (std::fwrite(header.data(), 1, header.size(), binary_) != header.size() ||
      std::fwrite(packet.data(), 1, packet.size(), binary_) != packet.size() ||
      std::fflush(binary_) != 0) {
    throw ProtocolError("failed to write binary mesh packet");
  }
}

} // namespace aeth
