// Unit test for the crash-safe atomic STEP write (finding 11). Exercises
// ExportStep directly against a body built in OCCT so it can prove the two
// guarantees that matter: (1) the happy path writes a reopenable file and leaves
// no temp behind, and (2) a write that cannot even open its temp file throws and
// leaves a pre-existing destination byte-for-byte untouched — a failed export
// can never destroy a previously-valid file. The temp path is deterministic
// (<dest>.step-tmp-<pid>-<n>), so the preservation case pre-occupies the exact
// predicted temp path with a directory to force the temp open to fail.
#include <atomic>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <system_error>
#include <vector>

#include <BRepPrimAPI_MakeBox.hxx>
#include <TopoDS_Shape.hxx>
#include <TopoDS_Solid.hxx>

#include "geometry.hpp"

namespace {

int g_failures = 0;

void check(bool condition, const std::string& label) {
  if (condition) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s\n", label.c_str());
    g_failures += 1;
  }
}

// The UTF-8 string ExportStep/InspectStep consume, recovered from a path the
// same way ExportStep does (the inverse of the kernel's Utf8Path helper).
std::string ToUtf8(const std::filesystem::path& path) {
  const std::u8string u8 = path.u8string();
  return std::string(reinterpret_cast<const char*>(u8.data()), u8.size());
}

std::string ReadAll(const std::filesystem::path& path) {
  std::ifstream input(path, std::ios::binary);
  if (!input)
    throw std::runtime_error("could not reopen file for readback");
  return std::string((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
}

} // namespace

int main() {
  std::printf("step export crash-safety\n");
  std::atomic_bool cancelled{false};

  const std::filesystem::path scratch =
      std::filesystem::temp_directory_path() / "aeth-step-export-test";
  std::error_code ec;
  std::filesystem::remove_all(scratch, ec);
  std::filesystem::create_directories(scratch, ec);

  // A single-solid box body, assembled the way EvaluateOperations assembles one.
  BRepPrimAPI_MakeBox maker(10.0, 20.0, 30.0);
  const TopoDS_Solid box = maker.Solid();
  aeth::EvaluatedBody body;
  body.bodyId = "body-1";
  body.operationId = "op-box";
  body.shape = box;
  body.probes = aeth::ProbeShape(box);
  const std::vector<aeth::EvaluatedBody> bodies{body};

  // --- Case 1: happy path (consumes temp counter 0). ---
  const std::filesystem::path dest1 = scratch / "happy.step";
  std::uintmax_t reported = 0;
  bool exported = true;
  try {
    reported = aeth::ExportStep(bodies, ToUtf8(dest1), cancelled);
  } catch (const std::exception& error) {
    std::printf("  FAIL happy-path export threw: %s\n", error.what());
    g_failures += 1;
    exported = false;
  }
  if (exported) {
    check(std::filesystem::exists(dest1), "destination file exists after export");
    check(std::filesystem::exists(dest1) && reported == std::filesystem::file_size(dest1),
          "reported byte length equals the file size on disk");
    bool anyTemp = false;
    for (const auto& entry : std::filesystem::directory_iterator(scratch)) {
      if (entry.path().filename().string().find("step-tmp") != std::string::npos)
        anyTemp = true;
    }
    check(!anyTemp, "no .step-tmp files remain in the scratch directory");
    try {
      const aeth::ShapeProbes probes = aeth::InspectStep(ToUtf8(dest1), cancelled);
      check(probes.valid, "reopened export is a valid solid");
      check(probes.solidCount == 1, "reopened export contains exactly one solid");
    } catch (const std::exception& error) {
      std::printf("  FAIL reopen-inspect threw: %s\n", error.what());
      g_failures += 1;
    }
  }

  // --- Case 2: cancellation preserves the destination. --------------------
  const std::filesystem::path dest2 = scratch / "preserve.step";
  const std::string sentinel = "SENTINEL STEP CONTENT - MUST NOT BE CLOBBERED\n";
  {
    std::ofstream seed(dest2, std::ios::binary | std::ios::trunc);
    seed.write(sentinel.data(), static_cast<std::streamsize>(sentinel.size()));
  }
  bool threw = false;
  cancelled.store(true);
  try {
    aeth::ExportStep(bodies, ToUtf8(dest2), cancelled);
  } catch (const std::exception&) {
    threw = true;
  }
  check(threw, "cancelled export throws before publishing");
  check(std::filesystem::exists(dest2),
        "sentinel destination still exists after the failed export");
  check(ReadAll(dest2) == sentinel, "sentinel destination is byte-for-byte untouched");

  std::filesystem::remove_all(scratch, ec);

  if (g_failures == 0) {
    std::printf("step export crash-safety: all checks passed\n");
    return 0;
  }
  std::printf("step export crash-safety: %d check(s) failed\n", g_failures);
  return 1;
}
