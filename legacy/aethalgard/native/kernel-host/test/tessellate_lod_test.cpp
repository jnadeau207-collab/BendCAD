// Native contract pins for Wave 2.2 tessellation quality plus the Phase-4
// topology-index bridge. Viewport tiers 0-2 remain size-relative; the
// manufacturing/export path is the distinct tier 3 with an absolute tolerance.
// The row-order tests prove the binary AEMB face/edge/vertex tables use the
// exact dense OCCT indexed maps that topology snapshots use, including
// identity-only degenerate edges whose AEMB polyline row is intentionally empty.
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <exception>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepBuilderAPI_MakeVertex.hxx>
#include <BRepExtrema_DistShapeShape.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakeSphere.hxx>
#include <BRep_Tool.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Shape.hxx>
#include <gp_Pnt.hxx>

#include "tessellate.hpp"
#include "topology_index_maps.hpp"

namespace {

int g_failures = 0;

void Check(const bool condition, const std::string& label) {
  if (condition) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s\n", label.c_str());
    ++g_failures;
  }
}

void CheckNear(const double actual, const double expected, const double tolerance,
               const std::string& label) {
  Check(std::abs(actual - expected) <= tolerance, label);
}

std::uint32_t ReadU32(const std::vector<std::uint8_t>& bytes, const std::size_t offset) {
  return static_cast<std::uint32_t>(bytes.at(offset)) |
         (static_cast<std::uint32_t>(bytes.at(offset + 1)) << 8U) |
         (static_cast<std::uint32_t>(bytes.at(offset + 2)) << 16U) |
         (static_cast<std::uint32_t>(bytes.at(offset + 3)) << 24U);
}

float ReadF32(const std::vector<std::uint8_t>& bytes, const std::size_t offset) {
  const std::uint32_t bits = ReadU32(bytes, offset);
  float value{};
  static_assert(sizeof(value) == sizeof(bits));
  std::memcpy(&value, &bits, sizeof(value));
  return value;
}

double ReadF64(const std::vector<std::uint8_t>& bytes, const std::size_t offset) {
  std::uint64_t bits{};
  for (std::size_t index = 0; index < 8; ++index) {
    bits |= static_cast<std::uint64_t>(bytes.at(offset + index)) << (8U * index);
  }
  double value{};
  static_assert(sizeof(value) == sizeof(bits));
  std::memcpy(&value, &bits, sizeof(value));
  return value;
}

struct SectionRange final {
  std::size_t offset;
  std::size_t length;
};

SectionRange FindSection(const std::vector<std::uint8_t>& bytes, const std::uint32_t id) {
  constexpr std::size_t kHeaderBytes = 96;
  constexpr std::size_t kDirectoryEntryBytes = 16;
  const std::uint32_t sectionCount = ReadU32(bytes, 36);
  for (std::uint32_t index = 0; index < sectionCount; ++index) {
    const std::size_t entry = kHeaderBytes + index * kDirectoryEntryBytes;
    if (ReadU32(bytes, entry) == id) {
      return {ReadU32(bytes, entry + 4), ReadU32(bytes, entry + 8)};
    }
  }
  throw std::runtime_error("AEMB test packet is missing section " + std::to_string(id));
}

gp_Pnt ReadWorldPoint(const std::vector<std::uint8_t>& bytes, const SectionRange& section,
                      const std::size_t pointIndex, const std::array<double, 3>& origin) {
  const std::size_t offset = section.offset + pointIndex * 3U * sizeof(float);
  if (offset + 3U * sizeof(float) > section.offset + section.length) {
    throw std::runtime_error("AEMB test point index is outside its section");
  }
  return gp_Pnt(static_cast<double>(ReadF32(bytes, offset)) + origin[0],
                static_cast<double>(ReadF32(bytes, offset + 4)) + origin[1],
                static_cast<double>(ReadF32(bytes, offset + 8)) + origin[2]);
}

double DistanceToShape(const gp_Pnt& point, const TopoDS_Shape& shape) {
  const TopoDS_Shape probe = BRepBuilderAPI_MakeVertex(point).Shape();
  BRepExtrema_DistShapeShape distance(probe, shape);
  if (!distance.IsDone() || distance.NbSolution() < 1) {
    throw std::runtime_error(
        "native topology-order test could not measure a point-to-shape distance");
  }
  return distance.Value();
}

int UniqueFaceMatch(const std::vector<std::uint8_t>& bytes, const SectionRange& positions,
                    const std::array<double, 3>& origin, const std::uint32_t firstVertex,
                    const std::uint32_t vertexCount, const aeth::TopologyShapeMap& faces) {
  constexpr double kToleranceMm = 1e-4;
  int matchedIndex = 0;
  int matchCount = 0;
  for (int candidate = 1; candidate <= faces.Extent(); ++candidate) {
    bool allPointsBelong = true;
    for (std::uint32_t local = 0; local < vertexCount; ++local) {
      const gp_Pnt point = ReadWorldPoint(bytes, positions, firstVertex + local, origin);
      if (DistanceToShape(point, faces(candidate)) > kToleranceMm) {
        allPointsBelong = false;
        break;
      }
    }
    if (allPointsBelong) {
      matchedIndex = candidate;
      ++matchCount;
    }
  }
  return matchCount == 1 ? matchedIndex : 0;
}

int UniqueEdgeMatch(const std::vector<std::uint8_t>& bytes, const SectionRange& edgeVertices,
                    const std::array<double, 3>& origin, const std::uint32_t firstVertex,
                    const std::uint32_t vertexCount, const aeth::TopologyShapeMap& edges) {
  constexpr double kToleranceMm = 1e-4;
  int matchedIndex = 0;
  int matchCount = 0;
  for (int candidate = 1; candidate <= edges.Extent(); ++candidate) {
    bool allPointsBelong = true;
    for (std::uint32_t local = 0; local < vertexCount; ++local) {
      const gp_Pnt point = ReadWorldPoint(bytes, edgeVertices, firstVertex + local, origin);
      if (DistanceToShape(point, edges(candidate)) > kToleranceMm) {
        allPointsBelong = false;
        break;
      }
    }
    if (allPointsBelong) {
      matchedIndex = candidate;
      ++matchCount;
    }
  }
  return matchCount == 1 ? matchedIndex : 0;
}

int UniqueVertexMatch(const gp_Pnt& point, const aeth::TopologyShapeMap& vertices) {
  constexpr double kToleranceMm = 1e-4;
  int matchedIndex = 0;
  int matchCount = 0;
  for (int candidate = 1; candidate <= vertices.Extent(); ++candidate) {
    if (DistanceToShape(point, vertices(candidate)) <= kToleranceMm) {
      matchedIndex = candidate;
      ++matchCount;
    }
  }
  return matchCount == 1 ? matchedIndex : 0;
}

void CheckPacketMetadata(const aeth::TessellationPacket& packet, const std::uint32_t lodTier,
                         const double deflection, const double angularDeflection,
                         const std::string& label) {
  Check(packet.descriptor.at("lodTier").get<std::uint32_t>() == lodTier,
        label + " descriptor tier");
  CheckNear(packet.descriptor.at("deflectionMm").get<double>(), deflection, 1e-12,
            label + " descriptor deflection");
  CheckNear(packet.descriptor.at("angularDeflectionRad").get<double>(), angularDeflection, 1e-12,
            label + " descriptor angle");
  Check(ReadU32(packet.bytes, 40) == lodTier, label + " packet tier");
  CheckNear(ReadF32(packet.bytes, 44), static_cast<float>(deflection), 1e-7,
            label + " packet deflection");
  CheckNear(ReadF32(packet.bytes, 60), static_cast<float>(angularDeflection), 1e-7,
            label + " packet angle");
}

void TestViewportTiers() {
  std::printf("viewport tiers\n");
  constexpr std::array<double, 3> kFactors{1e-3, 2.5e-4, 6.25e-5};
  constexpr std::array<double, 3> kAngles{0.5, 0.25, 0.1};
  const double diagonal = std::hypot(10.0, 20.0, 30.0);
  const std::atomic_bool cancelled{false};
  for (std::uint32_t tier = 0; tier < kFactors.size(); ++tier) {
    const TopoDS_Shape shape = BRepPrimAPI_MakeBox(10.0, 20.0, 30.0).Shape();
    const aeth::TessellationPacket packet = aeth::TessellateShape(shape, tier + 1, cancelled, tier);
    const double deflection = std::max(diagonal * kFactors[tier], 0.001);
    CheckPacketMetadata(packet, tier, deflection, kAngles[tier],
                        "viewport tier " + std::to_string(tier));
  }
}

void TestInvalidViewportTierFailsClosed() {
  std::printf("invalid viewport tier\n");
  const TopoDS_Shape shape = BRepPrimAPI_MakeBox(1.0, 1.0, 1.0).Shape();
  const std::atomic_bool cancelled{false};
  bool threw = false;
  try {
    static_cast<void>(aeth::TessellateShape(shape, 1, cancelled, 3));
  } catch (const std::invalid_argument&) {
    threw = true;
  }
  Check(threw, "tier 3 is rejected by the viewport entry point");
}

void TestExportQuality() {
  std::printf("export quality\n");
  const TopoDS_Shape shape = BRepPrimAPI_MakeBox(10.0, 20.0, 30.0).Shape();
  const std::atomic_bool cancelled{false};
  const aeth::TessellationPacket packet = aeth::TessellateShapeForExport(shape, 9, cancelled);
  CheckPacketMetadata(packet, 3, 0.02, std::acos(-1.0) / 18.0, "export tier");
}

void TestTopologyRowOrdering() {
  std::printf("AEMB topology row ordering\n");
  const TopoDS_Shape shape = BRepPrimAPI_MakeBox(10.0, 20.0, 30.0).Shape();
  const std::atomic_bool cancelled{false};
  const aeth::TessellationPacket packet = aeth::TessellateShape(shape, 77, cancelled, 0);

  aeth::TopologyShapeMap faces;
  aeth::TopologyShapeMap edges;
  aeth::TopologyShapeMap vertices;
  aeth::BuildTopologyIndexMaps(shape, faces, edges, vertices);

  Check(ReadU32(packet.bytes, 20) == static_cast<std::uint32_t>(faces.Extent()),
        "face count equals authoritative map");
  Check(ReadU32(packet.bytes, 24) == static_cast<std::uint32_t>(edges.Extent()),
        "edge count equals authoritative map");
  Check(ReadU32(packet.bytes, 32) == static_cast<std::uint32_t>(vertices.Extent()),
        "vertex count equals authoritative map");

  const std::array<double, 3> origin = {
      ReadF64(packet.bytes, 64),
      ReadF64(packet.bytes, 72),
      ReadF64(packet.bytes, 80),
  };
  const SectionRange positions = FindSection(packet.bytes, 1);
  const SectionRange faceTable = FindSection(packet.bytes, 5);
  const SectionRange edgeVertices = FindSection(packet.bytes, 6);
  const SectionRange edgeTable = FindSection(packet.bytes, 7);
  const SectionRange brepVertices = FindSection(packet.bytes, 8);

  for (int row = 0; row < faces.Extent(); ++row) {
    const std::size_t entry = faceTable.offset + static_cast<std::size_t>(row) * 16U;
    const std::uint32_t firstVertex = ReadU32(packet.bytes, entry + 8);
    const std::uint32_t vertexCount = ReadU32(packet.bytes, entry + 12);
    Check(vertexCount > 0, "face row " + std::to_string(row) + " is tessellated");
    Check(UniqueFaceMatch(packet.bytes, positions, origin, firstVertex, vertexCount, faces) ==
              row + 1,
          "face row " + std::to_string(row) + " matches topology map index");
  }

  for (int row = 0; row < edges.Extent(); ++row) {
    const std::size_t entry = edgeTable.offset + static_cast<std::size_t>(row) * 16U;
    const std::uint32_t firstVertex = ReadU32(packet.bytes, entry);
    const std::uint32_t vertexCount = ReadU32(packet.bytes, entry + 4);
    Check(vertexCount >= 2, "box edge row " + std::to_string(row) + " has a polyline");
    Check(UniqueEdgeMatch(packet.bytes, edgeVertices, origin, firstVertex, vertexCount, edges) ==
              row + 1,
          "edge row " + std::to_string(row) + " matches topology map index");
  }

  for (int row = 0; row < vertices.Extent(); ++row) {
    const gp_Pnt point =
        ReadWorldPoint(packet.bytes, brepVertices, static_cast<std::size_t>(row), origin);
    Check(UniqueVertexMatch(point, vertices) == row + 1,
          "vertex row " + std::to_string(row) + " matches topology map index");
  }
}

void TestDegenerateEdgeRows() {
  std::printf("AEMB degenerate edge rows\n");
  const TopoDS_Shape shape = BRepPrimAPI_MakeSphere(10.0).Shape();
  const std::atomic_bool cancelled{false};
  const aeth::TessellationPacket packet = aeth::TessellateShape(shape, 78, cancelled, 0);

  aeth::TopologyShapeMap faces;
  aeth::TopologyShapeMap edges;
  aeth::TopologyShapeMap vertices;
  aeth::BuildTopologyIndexMaps(shape, faces, edges, vertices);
  Check(ReadU32(packet.bytes, 24) == static_cast<std::uint32_t>(edges.Extent()),
        "sphere edge count equals authoritative map");

  const SectionRange edgeTable = FindSection(packet.bytes, 7);
  bool sawDegenerate = false;
  for (int row = 0; row < edges.Extent(); ++row) {
    const std::size_t entry = edgeTable.offset + static_cast<std::size_t>(row) * 16U;
    const std::uint32_t vertexCount = ReadU32(packet.bytes, entry + 4);
    const bool degenerated = BRep_Tool::Degenerated(TopoDS::Edge(edges(row + 1)));
    sawDegenerate = sawDegenerate || degenerated;
    if (degenerated) {
      Check(vertexCount == 0, "sphere degenerate edge row " + std::to_string(row) +
                                  " remains an empty identity row at the same map index");
    }
  }
  Check(sawDegenerate, "sphere fixture contains at least one degenerate edge");
}

} // namespace

int main() {
  try {
    TestViewportTiers();
    TestInvalidViewportTierFailsClosed();
    TestExportQuality();
    TestTopologyRowOrdering();
    TestDegenerateEdgeRows();
  } catch (const std::exception& error) {
    std::printf("  FAIL unexpected exception: %s\n", error.what());
    ++g_failures;
  } catch (...) {
    std::printf("  FAIL unexpected non-standard exception\n");
    ++g_failures;
  }
  std::printf("%s (%d failure%s)\n", g_failures == 0 ? "PASS" : "FAIL", g_failures,
              g_failures == 1 ? "" : "s");
  return g_failures == 0 ? 0 : 1;
}
