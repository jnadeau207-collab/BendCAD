#pragma once

#include <cstdint>
#include <cstdio>
#include <istream>
#include <mutex>
#include <ostream>
#include <stdexcept>
#include <vector>

#include <nlohmann/json.hpp>

namespace aeth {

constexpr std::uint32_t kMaxControlFrameBytes = 4U * 1024U * 1024U;
constexpr std::uint32_t kBinaryMeshMagic = 0x314D4241U;

class ProtocolError final : public std::runtime_error {
public:
  using std::runtime_error::runtime_error;
};

bool ReadControlFrame(std::istream& input, nlohmann::json& value);

class ProtocolWriter final {
public:
  ProtocolWriter(std::ostream& control, std::FILE* binary);
  void WriteControl(const nlohmann::json& value);
  void WriteMesh(std::uint32_t sequence, const std::vector<std::uint8_t>& packet);

private:
  std::ostream& control_;
  std::FILE* binary_;
  std::mutex controlMutex_;
  std::mutex binaryMutex_;
};

} // namespace aeth
