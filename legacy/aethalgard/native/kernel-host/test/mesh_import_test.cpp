// Native coverage for the mesh import path (defect D-023): the `import_mesh`
// document operation rebuilds a solid body from the checked aeth-mesh-v1 surface
// it retains (the guaranteed-manifold, welded, outward-oriented mesh the TS
// interchange pipeline produced), through the real EvaluateOperations dispatch.
// It proves the round-trip identity gates 6/9 demand — ingest a closed box
// triangle surface as an import_mesh, and the reconstructed body matches (volume,
// bounds, solid count), then export it to STEP and re-import to confirm the
// interchange identity — plus the two guarantees import_step carries: the
// recorded content hash is verified (a corrupted source is refused, not
// silently rebuilt), and element naming over the import covers every entity
// with names two independent rebuilds agree on (CAP-011).
#include <array>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <system_error>
#include <vector>

#include <TopoDS_Shape.hxx>
#include <nlohmann/json.hpp>

#include "element_names.hpp"
#include "geometry.hpp"
#include "sha256.hpp"

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

std::string ToUtf8(const std::filesystem::path& path) {
  const std::u8string u8 = path.u8string();
  return std::string(reinterpret_cast<const char*>(u8.data()), u8.size());
}

std::string ReadAll(const std::filesystem::path& path) {
  std::ifstream input(path, std::ios::binary);
  if (!input)
    throw std::runtime_error("could not read exported STEP for re-import");
  return std::string((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
}

std::string Sha256Of(const std::string& text) {
  aeth::Sha256 hasher;
  hasher.Update(reinterpret_cast<const unsigned char*>(text.data()), text.size());
  return hasher.HexDigest();
}

void PushU32LE(std::vector<unsigned char>& out, std::uint32_t value) {
  out.push_back(static_cast<unsigned char>(value & 0xff));
  out.push_back(static_cast<unsigned char>((value >> 8) & 0xff));
  out.push_back(static_cast<unsigned char>((value >> 16) & 0xff));
  out.push_back(static_cast<unsigned char>((value >> 24) & 0xff));
}

void PushF32LE(std::vector<unsigned char>& out, float value) {
  std::uint32_t bits = 0;
  std::memcpy(&bits, &value, sizeof(bits));
  PushU32LE(out, bits);
}

// Encodes the aeth-mesh-v1 layout (08 §6.3.2, the exact bytes encodeAethMeshV1
// produces): "AETHMESH", u32 version=1, u32 flags=0, u32 vertexCount, u32
// triCount, f32*3n positions (mm), u32*3t indices, all little-endian.
std::vector<unsigned char> EncodeAethMeshV1(const std::vector<float>& positions,
                                            const std::vector<std::uint32_t>& indices) {
  std::vector<unsigned char> out;
  const char magic[8] = {'A', 'E', 'T', 'H', 'M', 'E', 'S', 'H'};
  for (const char c : magic)
    out.push_back(static_cast<unsigned char>(c));
  PushU32LE(out, 1);
  PushU32LE(out, 0);
  PushU32LE(out, static_cast<std::uint32_t>(positions.size() / 3));
  PushU32LE(out, static_cast<std::uint32_t>(indices.size() / 3));
  for (const float component : positions)
    PushF32LE(out, component);
  for (const std::uint32_t index : indices)
    PushU32LE(out, index);
  return out;
}

std::string EncodeBase64(const std::vector<unsigned char>& bytes) {
  static const char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  std::string out;
  std::size_t index = 0;
  while (index + 3 <= bytes.size()) {
    const std::uint32_t chunk = (static_cast<std::uint32_t>(bytes[index]) << 16) |
                                (static_cast<std::uint32_t>(bytes[index + 1]) << 8) |
                                static_cast<std::uint32_t>(bytes[index + 2]);
    out.push_back(alphabet[(chunk >> 18) & 0x3f]);
    out.push_back(alphabet[(chunk >> 12) & 0x3f]);
    out.push_back(alphabet[(chunk >> 6) & 0x3f]);
    out.push_back(alphabet[chunk & 0x3f]);
    index += 3;
  }
  const std::size_t remaining = bytes.size() - index;
  if (remaining == 1) {
    const std::uint32_t chunk = static_cast<std::uint32_t>(bytes[index]) << 16;
    out.push_back(alphabet[(chunk >> 18) & 0x3f]);
    out.push_back(alphabet[(chunk >> 12) & 0x3f]);
    out.push_back('=');
    out.push_back('=');
  } else if (remaining == 2) {
    const std::uint32_t chunk = (static_cast<std::uint32_t>(bytes[index]) << 16) |
                                (static_cast<std::uint32_t>(bytes[index + 1]) << 8);
    out.push_back(alphabet[(chunk >> 18) & 0x3f]);
    out.push_back(alphabet[(chunk >> 12) & 0x3f]);
    out.push_back(alphabet[(chunk >> 6) & 0x3f]);
    out.push_back('=');
  }
  return out;
}

// A closed, welded, outward-oriented box surface [0,W]x[0,D]x[0,H] — 8 shared
// vertices, 12 triangles, every edge shared by exactly two faces — exactly the
// manifold surface the TS ingestion pipeline guarantees before encoding.
std::vector<unsigned char> BoxMeshBytes(float w, float d, float h) {
  const std::vector<float> positions = {
      0, 0, 0, // v0
      w, 0, 0, // v1
      w, d, 0, // v2
      0, d, 0, // v3
      0, 0, h, // v4
      w, 0, h, // v5
      w, d, h, // v6
      0, d, h, // v7
  };
  const std::vector<std::uint32_t> indices = {
      4, 5, 6, 4, 6, 7, // top    (+Z)
      0, 3, 2, 0, 2, 1, // bottom (-Z)
      0, 1, 5, 0, 5, 4, // front  (-Y)
      3, 7, 6, 3, 6, 2, // back   (+Y)
      0, 4, 7, 0, 7, 3, // left   (-X)
      1, 2, 6, 1, 6, 5, // right  (+X)
  };
  return EncodeAethMeshV1(positions, indices);
}

// A real UUID, not a placeholder: element naming derives its lineage prefix
// from the first 8 hex digits and refuses a non-UUID id (`OperationIdPrefix`),
// so "op-import" would make the naming checks below throw for the wrong reason.
const std::string kImportOp = "b2c3d4e5-2222-4b22-8b22-b2c3d4e5f6a7";

nlohmann::json ImportOperation(const std::string& source, const std::string& sha) {
  return nlohmann::json{
      {"id", kImportOp},
      {"type", "import_mesh"},
      {"schemaVersion", 1},
      {"name", "Imported mesh"},
      {"outputBodyId", "body-import"},
      {"parameters", {{"source", source}, {"sourceSha256", sha}}},
  };
}

bool Close(double a, double b, double tolerance) { return std::abs(a - b) <= tolerance; }

} // namespace

int main() {
  std::printf("mesh import round-trip (D-023)\n");
  std::atomic_bool cancelled{false};

  const std::filesystem::path scratch =
      std::filesystem::temp_directory_path() / "aeth-mesh-import-test";
  std::error_code ec;
  std::filesystem::remove_all(scratch, ec);
  std::filesystem::create_directories(scratch, ec);

  const float boxW = 10.0F;
  const float boxD = 20.0F;
  const float boxH = 30.0F;
  const double expectedVolume = static_cast<double>(boxW) * boxD * boxH; // 6000
  const double expectedArea =
      2.0 * (static_cast<double>(boxW) * boxD + static_cast<double>(boxW) * boxH +
             static_cast<double>(boxD) * boxH); // 2200

  const std::vector<unsigned char> payload = BoxMeshBytes(boxW, boxD, boxH);
  const std::string source = EncodeBase64(payload);
  const std::string sha = Sha256Of(source);

  // --- Direct in-memory rebuild: the retained payload builds a valid solid. ---
  try {
    const TopoDS_Shape shape = aeth::ImportMeshShapeFromString(source, cancelled);
    const aeth::ShapeProbes probes = aeth::ProbeShape(shape);
    check(probes.valid, "ImportMeshShapeFromString yields a valid shape");
    check(probes.solidCount == 1, "ImportMeshShapeFromString yields exactly one solid");
    check(Close(probes.volume, expectedVolume, 1e-3), "in-memory rebuild preserves the box volume");
    check(Close(probes.surfaceArea, expectedArea, 1e-3),
          "in-memory rebuild preserves the surface area");
  } catch (const std::exception& error) {
    std::printf("  FAIL ImportMeshShapeFromString threw: %s\n", error.what());
    g_failures += 1;
  }

  // --- Full document path: import_mesh through EvaluateOperations. ---
  const nlohmann::json operations = nlohmann::json::array({ImportOperation(source, sha)});
  std::vector<aeth::EvaluatedBody> bodies;
  bool importedOk = false;
  try {
    bodies = aeth::EvaluateOperations(operations, cancelled);
    check(bodies.size() == 1, "import_mesh produces exactly one body");
    if (bodies.size() == 1) {
      importedOk = true;
      const aeth::ShapeProbes& imported = bodies.front().probes;
      check(bodies.front().bodyId == "body-import",
            "the body carries the operation's outputBodyId");
      check(imported.valid, "the imported body is a valid solid");
      check(imported.solidCount == 1, "the imported body has exactly one solid");
      check(Close(imported.volume, expectedVolume, 1e-3), "round-trip preserves the volume");
      check(Close(imported.surfaceArea, expectedArea, 1e-3),
            "round-trip preserves the surface area");
      const std::array<double, 6> expectedBounds = {0.0, 0.0, 0.0, boxW, boxD, boxH};
      for (int axis = 0; axis < 6; ++axis) {
        check(Close(imported.bounds[axis], expectedBounds[static_cast<std::size_t>(axis)], 1e-4),
              "round-trip preserves bound " + std::to_string(axis));
      }
    }
  } catch (const std::exception& error) {
    std::printf("  FAIL import_mesh evaluation threw: %s\n", error.what());
    g_failures += 1;
  }

  // --- Interchange identity (gate 6/9): export the imported body to STEP and
  //     re-import; the volume survives the mesh -> B-rep -> STEP -> B-rep hops. ---
  if (importedOk) {
    try {
      const std::filesystem::path exported = scratch / "mesh-body.step";
      aeth::ExportStep(bodies, ToUtf8(exported), cancelled);
      const std::string stepSource = ReadAll(exported);
      const aeth::ShapeProbes reimported =
          aeth::ProbeShape(aeth::ImportStepShapeFromString(stepSource, cancelled));
      check(reimported.valid && reimported.solidCount == 1,
            "mesh body exports to STEP and re-imports as one valid solid");
      check(Close(reimported.volume, expectedVolume, 1e-3),
            "import -> body -> export -> re-import preserves the volume");
    } catch (const std::exception& error) {
      std::printf("  FAIL mesh export/re-import threw: %s\n", error.what());
      g_failures += 1;
    }
  }

  // --- Integrity (gate 9): a source that does not match its hash is refused. ---
  {
    std::string wrongSha = sha;
    wrongSha[0] = (wrongSha[0] == '0') ? '1' : '0';
    const nlohmann::json tampered = nlohmann::json::array({ImportOperation(source, wrongSha)});
    bool threw = false;
    try {
      aeth::EvaluateOperations(tampered, cancelled);
    } catch (const std::exception&) {
      threw = true;
    }
    check(threw, "a source that does not match sourceSha256 is refused");
  }

  // --- Fail closed on a corrupt payload: a base64 body with garbage bytes is
  //     refused, never coerced into geometry the user did not ask for. ---
  {
    const std::string garbage = EncodeBase64({'n', 'o', 't', 'a', 'm', 'e', 's', 'h'});
    const nlohmann::json corrupt =
        nlohmann::json::array({ImportOperation(garbage, Sha256Of(garbage))});
    bool threw = false;
    try {
      aeth::EvaluateOperations(corrupt, cancelled);
    } catch (const std::exception&) {
      threw = true;
    }
    check(threw, "a non-aeth-mesh payload is refused");
  }

  // --- Element naming over a mesh import (CAP-011). The sewn topology is a
  //     deterministic function of the sha256-verified retained payload, so the
  //     same bytes rebuild the same entities in the same traversal order and
  //     earn the same names. Asserted, not assumed. ---
  if (importedOk) {
    try {
      aeth::ElementNameBook book;
      const std::vector<aeth::EvaluatedBody> named =
          aeth::EvaluateOperations(operations, cancelled, &book);
      check(named.size() == 1, "a mesh import evaluates under an element-name pass");
      if (named.size() == 1) {
        const nlohmann::json projected = aeth::ProjectElementNames(book, named.front().shape, 1, 0);
        const aeth::ShapeProbes& probes = named.front().probes;
        const std::size_t expectedEntries = static_cast<std::size_t>(probes.faceCount) +
                                            static_cast<std::size_t>(probes.edgeCount) +
                                            static_cast<std::size_t>(probes.vertexCount);
        check(projected.size() == expectedEntries,
              "every rebuilt face, edge and vertex carries an element name");

        aeth::ElementNameBook again;
        const std::vector<aeth::EvaluatedBody> rebuilt =
            aeth::EvaluateOperations(operations, cancelled, &again);
        const nlohmann::json projectedAgain =
            aeth::ProjectElementNames(again, rebuilt.front().shape, 1, 0);
        check(projectedAgain == projected,
              "two independent rebuilds of the same payload earn byte-identical names");
      }
    } catch (const std::exception& error) {
      std::printf("  FAIL import_mesh element naming threw: %s\n", error.what());
      g_failures += 1;
    }
  }

  std::filesystem::remove_all(scratch, ec);

  if (g_failures == 0) {
    std::printf("mesh import round-trip: all checks passed\n");
    return 0;
  }
  std::printf("mesh import round-trip: %d check(s) failed\n", g_failures);
  return 1;
}
