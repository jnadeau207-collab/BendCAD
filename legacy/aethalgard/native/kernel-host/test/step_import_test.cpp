// Native coverage for the STEP import path (defect D-019): the `import_step`
// document operation reads a body back from the ISO-10303-21 bytes it retains
// (§2.1) through the real EvaluateOperations dispatch. It proves the round-trip
// identity gate 6/9 demands — export a solid, ingest its bytes as an
// import_step, and the reconstructed body matches (volume, bounds, solid count)
// — plus the recorded content hash being verified (a corrupted source is
// refused, not silently rebuilt), and element naming over the import covering
// every entity with names two independent reads agree on (CAP-011).
#include <atomic>
#include <cmath>
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
#include <gp_Pnt.hxx>
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
    throw std::runtime_error("could not read STEP file for import");
  return std::string((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
}

std::string Sha256Of(const std::string& text) {
  aeth::Sha256 hasher;
  hasher.Update(reinterpret_cast<const unsigned char*>(text.data()), text.size());
  return hasher.HexDigest();
}

// The id must be a real UUID: element naming derives its lineage prefix from
// the first 8 hex digits and REFUSES a non-UUID id outright
// (`OperationIdPrefix`). With the placeholder "op-import" the naming checks
// below would throw for the wrong reason and a broken harvest would still look
// like a pass.
const std::string kImportOp = "a1b2c3d4-1111-4a11-8a11-a1b2c3d4e5f6";

nlohmann::json ImportOperation(const std::string& source, const std::string& sha) {
  return nlohmann::json{
      {"id", kImportOp},
      {"type", "import_step"},
      {"schemaVersion", 1},
      {"name", "Imported solid"},
      {"outputBodyId", "body-import"},
      {"parameters", {{"source", source}, {"sourceSha256", sha}}},
  };
}

bool Close(double a, double b, double tolerance) { return std::abs(a - b) <= tolerance; }

} // namespace

int main() {
  std::printf("step import round-trip (D-019)\n");
  std::atomic_bool cancelled{false};

  const std::filesystem::path scratch =
      std::filesystem::temp_directory_path() / "aeth-step-import-test";
  std::error_code ec;
  std::filesystem::remove_all(scratch, ec);
  std::filesystem::create_directories(scratch, ec);

  // A reference solid, assembled the way EvaluateOperations assembles one.
  BRepPrimAPI_MakeBox maker(10.0, 20.0, 30.0);
  const TopoDS_Solid box = maker.Solid();
  aeth::EvaluatedBody exportBody;
  exportBody.bodyId = "body-1";
  exportBody.operationId = "op-box";
  exportBody.shape = box;
  exportBody.probes = aeth::ProbeShape(box);
  const aeth::ShapeProbes& ref = exportBody.probes;

  // Serialize it to STEP, then read the exact bytes an import_step would retain.
  const std::filesystem::path exported = scratch / "solid.step";
  try {
    aeth::ExportStep({exportBody}, ToUtf8(exported), cancelled);
  } catch (const std::exception& error) {
    std::printf("  FAIL reference export threw: %s\n", error.what());
    g_failures += 1;
  }

  std::string source;
  try {
    source = ReadAll(exported);
  } catch (const std::exception& error) {
    std::printf("  FAIL reading exported STEP threw: %s\n", error.what());
    g_failures += 1;
  }
  const std::string sha = Sha256Of(source);

  // --- Direct in-memory reader: the retained bytes read back to a valid solid. ---
  try {
    const TopoDS_Shape shape = aeth::ImportStepShapeFromString(source, cancelled);
    const aeth::ShapeProbes probes = aeth::ProbeShape(shape);
    check(probes.valid, "ImportStepShapeFromString yields a valid shape");
    check(probes.solidCount == 1, "ImportStepShapeFromString yields exactly one solid");
    check(Close(probes.volume, ref.volume, 1e-3), "in-memory read preserves the volume");
  } catch (const std::exception& error) {
    std::printf("  FAIL ImportStepShapeFromString threw: %s\n", error.what());
    g_failures += 1;
  }

  // --- Full document path: import_step through EvaluateOperations. ---
  const nlohmann::json operations = nlohmann::json::array({ImportOperation(source, sha)});
  aeth::ShapeProbes imported{};
  bool importedOk = false;
  try {
    const std::vector<aeth::EvaluatedBody> bodies = aeth::EvaluateOperations(operations, cancelled);
    check(bodies.size() == 1, "import_step produces exactly one body");
    if (bodies.size() == 1) {
      importedOk = true;
      imported = bodies.front().probes;
      check(bodies.front().bodyId == "body-import",
            "the body carries the operation's outputBodyId");
      check(imported.valid, "the imported body is a valid solid");
      check(imported.solidCount == 1, "the imported body has exactly one solid");
      // Round-trip identity (gate 6 / gate 9): geometry survives the interchange.
      check(Close(imported.volume, ref.volume, 1e-3), "round-trip preserves the volume");
      check(Close(imported.surfaceArea, ref.surfaceArea, 1e-3),
            "round-trip preserves the surface area");
      for (int axis = 0; axis < 6; ++axis) {
        check(Close(imported.bounds[axis], ref.bounds[axis], 1e-4),
              "round-trip preserves bound " + std::to_string(axis));
      }
      check(imported.faceCount == ref.faceCount, "round-trip preserves the face count");
    }
  } catch (const std::exception& error) {
    std::printf("  FAIL import_step evaluation threw: %s\n", error.what());
    g_failures += 1;
  }

  // --- A second round trip is stable (export the import, re-import, compare). ---
  if (importedOk) {
    try {
      const std::vector<aeth::EvaluatedBody> once = aeth::EvaluateOperations(operations, cancelled);
      const std::filesystem::path again = scratch / "again.step";
      aeth::ExportStep(once, ToUtf8(again), cancelled);
      const std::string source2 = ReadAll(again);
      const nlohmann::json operations2 =
          nlohmann::json::array({ImportOperation(source2, Sha256Of(source2))});
      const std::vector<aeth::EvaluatedBody> twice =
          aeth::EvaluateOperations(operations2, cancelled);
      check(twice.size() == 1 && Close(twice.front().probes.volume, ref.volume, 1e-3),
            "export -> re-import is volume-stable across two hops");
    } catch (const std::exception& error) {
      std::printf("  FAIL second round trip threw: %s\n", error.what());
      g_failures += 1;
    }
  }

  // --- Multi-solid STEP (D-023): a STEP carrying more than one solid imports
  //     FAITHFULLY as a single body that is a compound of N solids — the solids
  //     are never dropped or reduced to one. (Surfacing them as N SEPARATE
  //     document bodies is a body-model extension beyond the one-op/one-body
  //     birth contract; the faithful compound is the in-model behavior.) ---
  {
    try {
      aeth::EvaluatedBody first;
      first.bodyId = "solid-a";
      first.operationId = "op-a";
      first.shape = BRepPrimAPI_MakeBox(10.0, 20.0, 30.0).Solid();
      first.probes = aeth::ProbeShape(first.shape);
      aeth::EvaluatedBody second;
      second.bodyId = "solid-b";
      second.operationId = "op-b";
      second.shape = BRepPrimAPI_MakeBox(gp_Pnt(100.0, 0.0, 0.0), 5.0, 5.0, 5.0).Solid();
      second.probes = aeth::ProbeShape(second.shape);
      const std::filesystem::path twoPath = scratch / "two-solids.step";
      aeth::ExportStep({first, second}, ToUtf8(twoPath), cancelled);
      const std::string twoSource = ReadAll(twoPath);
      const aeth::ShapeProbes probes =
          aeth::ProbeShape(aeth::ImportStepShapeFromString(twoSource, cancelled));
      check(probes.valid, "a two-solid STEP imports as a valid shape");
      check(probes.solidCount == 2,
            "a two-solid STEP imports as two solids (never reduced to one)");
      check(Close(probes.volume, 6000.0 + 125.0, 1e-2), "both solids' volume is preserved");
    } catch (const std::exception& error) {
      std::printf("  FAIL multi-solid STEP import threw: %s\n", error.what());
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

  // --- Element naming over an import (CAP-011). This used to fail closed: an
  //     import was said to have "no lineage to name". It has one — just not a
  //     CONSTRUCTION lineage. `AddPrimitive` roots every sub-shape in
  //     TopExp::MapShapes order, and identical retained bytes read back to
  //     identical topology (the step-reimport oracle), so the names two
  //     independent reads earn are the same names. That is what is asserted
  //     here, rather than assumed: total coverage, then byte-identity across
  //     two independent evaluations. ---
  if (importedOk) {
    try {
      aeth::ElementNameBook book;
      const std::vector<aeth::EvaluatedBody> named =
          aeth::EvaluateOperations(operations, cancelled, &book);
      check(named.size() == 1, "an import evaluates under an element-name pass");
      if (named.size() == 1) {
        const nlohmann::json projected = aeth::ProjectElementNames(book, named.front().shape, 1, 0);
        const aeth::ShapeProbes& probes = named.front().probes;
        const std::size_t expectedEntries = static_cast<std::size_t>(probes.faceCount) +
                                            static_cast<std::size_t>(probes.edgeCount) +
                                            static_cast<std::size_t>(probes.vertexCount);
        check(projected.size() == expectedEntries,
              "every imported face, edge and vertex carries an element name");

        aeth::ElementNameBook again;
        const std::vector<aeth::EvaluatedBody> reread =
            aeth::EvaluateOperations(operations, cancelled, &again);
        const nlohmann::json projectedAgain =
            aeth::ProjectElementNames(again, reread.front().shape, 1, 0);
        check(projectedAgain == projected,
              "two independent reads of the same bytes earn byte-identical names");
      }
    } catch (const std::exception& error) {
      std::printf("  FAIL import_step element naming threw: %s\n", error.what());
      g_failures += 1;
    }
  }

  std::filesystem::remove_all(scratch, ec);

  if (g_failures == 0) {
    std::printf("step import round-trip: all checks passed\n");
    return 0;
  }
  std::printf("step import round-trip: %d check(s) failed\n", g_failures);
  return 1;
}
