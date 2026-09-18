#include "tessellate.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>
#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <utility>
#include <vector>

#include <BRepAdaptor_Curve.hxx>
#include <BRepBndLib.hxx>
#include <BRepMesh_IncrementalMesh.hxx>
#include <BRep_Tool.hxx>
#include <Bnd_Box.hxx>
#include <GCPnts_QuasiUniformDeflection.hxx>
#include <GeomAbs_Shape.hxx>
#include <NCollection_IndexedDataMap.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <Poly_Triangle.hxx>
#include <Poly_Triangulation.hxx>
#include <TopAbs_Orientation.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopLoc_Location.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Dir.hxx>
#include <gp_Pnt.hxx>
#include <gp_Trsf.hxx>
#include <gp_Vec.hxx>

#include "cancel.hpp"

namespace aeth {
namespace {

using ShapeList = NCollection_List<TopoDS_Shape>;
using ShapeMap = NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher>;
using ShapeAncestorsMap =
    NCollection_IndexedDataMap<TopoDS_Shape, ShapeList, TopTools_ShapeMapHasher>;

constexpr std::uint32_t kAembMagic = 0x424D4541U;
constexpr std::size_t kHeaderBytes = 96;
constexpr std::size_t kDirectoryEntryBytes = 16;
constexpr std::uint32_t kSectionCount = 8;
// Outer bound on a body's world extent and rebasing anchor, in millimetres.
// MUST stay bit-identical to `maxModelExtentMm` in
// packages/geometry-contracts/src/operations.ts: past it the export is refused
// here and `parseAembPacket` rejects the header's f64 world origin.
constexpr double kMaxModelExtentMm = 1.0e8;
constexpr std::uint32_t kEdgeSharp = 1U;
constexpr std::uint32_t kEdgeSmooth = 2U;
constexpr std::uint32_t kEdgeBoundary = 4U;
// Manufacturing-export tessellation tolerances (finding-10). ABSOLUTE, not
// diagonal-scaled: a 0.02 mm chord tolerance and a 10 deg angular tolerance
// on every body regardless of size, reported as LOD tier 3 so the packet and
// its 3MF quality metadata are distinguishable from any viewport LOD (0-2).
// These do NOT pass through Deflection()/AngularDeflection(); they feed
// BuildMesh and EncodeAemb directly.
constexpr double kExportLinearDeflectionMm = 0.02;
constexpr double kExportAngularDeflectionRad = 0.17453292519943295;
constexpr std::uint32_t kExportLodTier = 3U;

struct FaceEntry final {
  std::uint32_t firstTriangle;
  std::uint32_t triangleCount;
  std::uint32_t firstVertex;
  std::uint32_t vertexCount;
};

struct EdgeEntry final {
  std::uint32_t firstVertex;
  std::uint32_t vertexCount;
  std::uint32_t flags;
  std::uint32_t reserved;
};

struct Section final {
  std::uint32_t id;
  std::uint32_t offset;
  std::uint32_t length;
};

struct MeshData final {
  std::vector<float> positions;
  std::vector<float> normals;
  std::vector<std::uint32_t> faceIds;
  std::vector<std::uint32_t> triangles;
  std::vector<FaceEntry> faces;
  std::vector<float> edgeVertices;
  std::vector<EdgeEntry> edges;
  std::vector<float> brepVertices;
};

std::size_t Align16(const std::size_t value) { return (value + 15U) & ~std::size_t{15U}; }

void PutU32(std::vector<std::uint8_t>& bytes, const std::size_t offset, const std::uint32_t value) {
  bytes.at(offset) = static_cast<std::uint8_t>(value & 0xFFU);
  bytes.at(offset + 1) = static_cast<std::uint8_t>((value >> 8U) & 0xFFU);
  bytes.at(offset + 2) = static_cast<std::uint8_t>((value >> 16U) & 0xFFU);
  bytes.at(offset + 3) = static_cast<std::uint8_t>((value >> 24U) & 0xFFU);
}

void PutU16(std::vector<std::uint8_t>& bytes, const std::size_t offset, const std::uint16_t value) {
  bytes.at(offset) = static_cast<std::uint8_t>(value & 0xFFU);
  bytes.at(offset + 1) = static_cast<std::uint8_t>((value >> 8U) & 0xFFU);
}

void PutF32(std::vector<std::uint8_t>& bytes, const std::size_t offset, const float value) {
  std::uint32_t bits{};
  std::memcpy(&bits, &value, sizeof(bits));
  PutU32(bytes, offset, bits);
}

void PutF64(std::vector<std::uint8_t>& bytes, const std::size_t offset, const double value) {
  std::uint64_t bits{};
  std::memcpy(&bits, &value, sizeof(bits));
  for (std::size_t index = 0; index < 8; ++index) {
    bytes.at(offset + index) = static_cast<std::uint8_t>((bits >> (8U * index)) & 0xFFU);
  }
}

template <typename Value>
void AppendPodVector(std::vector<std::uint8_t>& bytes, const std::vector<Value>& values) {
  const auto* begin = reinterpret_cast<const std::uint8_t*>(values.data());
  bytes.insert(bytes.end(), begin, begin + values.size() * sizeof(Value));
}

void AppendFaceTable(std::vector<std::uint8_t>& bytes, const std::vector<FaceEntry>& entries) {
  for (const auto& entry : entries) {
    const std::size_t start = bytes.size();
    bytes.resize(start + 16);
    PutU32(bytes, start, entry.firstTriangle);
    PutU32(bytes, start + 4, entry.triangleCount);
    PutU32(bytes, start + 8, entry.firstVertex);
    PutU32(bytes, start + 12, entry.vertexCount);
  }
}

void AppendEdgeTable(std::vector<std::uint8_t>& bytes, const std::vector<EdgeEntry>& entries) {
  for (const auto& entry : entries) {
    const std::size_t start = bytes.size();
    bytes.resize(start + 16);
    PutU32(bytes, start, entry.firstVertex);
    PutU32(bytes, start + 4, entry.vertexCount);
    PutU32(bytes, start + 8, entry.flags);
    PutU32(bytes, start + 12, 0);
  }
}

// Rebases a world-space OCCT point onto the body-local frame (subtracting the
// world-AABB centre in DOUBLE) and only then narrows to float32, so fine
// features never collapse into the ~1 mm float32 spacing that ±1e7 mm world
// coordinates would otherwise suffer. The world placement is preserved
// separately as the f64 origin in the AEMB2 header.
void AddPoint(std::vector<float>& values, const gp_Pnt& point,
              const std::array<double, 3>& origin) {
  const float fx = static_cast<float>(point.X() - origin[0]);
  const float fy = static_cast<float>(point.Y() - origin[1]);
  const float fz = static_cast<float>(point.Z() - origin[2]);
  if (!std::isfinite(fx) || !std::isfinite(fy) || !std::isfinite(fz))
    throw std::runtime_error("AEMB non-finite body-local coordinate");
  values.push_back(fx);
  values.push_back(fy);
  values.push_back(fz);
}

void AddNormal(std::vector<float>& values, gp_Vec normal) {
  if (normal.Magnitude() < 1e-12)
    normal = gp_Vec(0.0, 0.0, 1.0);
  normal.Normalize();
  values.push_back(static_cast<float>(normal.X()));
  values.push_back(static_cast<float>(normal.Y()));
  values.push_back(static_cast<float>(normal.Z()));
}

std::array<double, 6> Bounds(const TopoDS_Shape& shape) {
  Bnd_Box box;
  BRepBndLib::AddOptimal(shape, box, true, false);
  std::array<double, 6> bounds{};
  box.Get(bounds[0], bounds[1], bounds[2], bounds[3], bounds[4], bounds[5]);
  return bounds;
}

double Deflection(const std::array<double, 6>& bounds, const std::uint32_t lodTier) {
  const double diagonal =
      std::hypot(bounds[3] - bounds[0], bounds[4] - bounds[1], bounds[5] - bounds[2]);
  switch (lodTier) {
  case 0:
    return std::max(diagonal * 1e-3, 0.001);
  case 1:
    return std::max(diagonal * 2.5e-4, 0.001);
  case 2:
    return std::max(diagonal * 6.25e-5, 0.001);
  default:
    throw std::invalid_argument("LOD tier must be 0, 1, or 2");
  }
}

double AngularDeflection(const std::uint32_t lodTier) {
  switch (lodTier) {
  case 0:
    return 0.5;
  case 1:
    return 0.25;
  case 2:
    return 0.1;
  default:
    throw std::invalid_argument("LOD tier must be 0, 1, or 2");
  }
}

std::uint32_t EdgeFlags(const TopoDS_Edge& edge, const ShapeAncestorsMap& edgeFaces) {
  if (!edgeFaces.Contains(edge))
    return kEdgeBoundary;
  const ShapeList& adjacent = edgeFaces.FindFromKey(edge);
  if (adjacent.Extent() == 1)
    return kEdgeBoundary | kEdgeSharp;
  if (adjacent.Extent() != 2)
    return kEdgeSharp;
  ShapeList::Iterator iterator(adjacent);
  const TopoDS_Face first = TopoDS::Face(iterator.Value());
  iterator.Next();
  const TopoDS_Face second = TopoDS::Face(iterator.Value());
  try {
    return BRep_Tool::Continuity(edge, first, second) >= GeomAbs_G1 ? kEdgeSmooth : kEdgeSharp;
  } catch (...) {
    return kEdgeSharp;
  }
}

MeshData BuildMesh(const TopoDS_Shape& shape, const double deflection,
                   const double angularDeflection, const std::array<double, 3>& origin,
                   const std::atomic_bool& cancelled) {
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepMesh_IncrementalMesh mesher;
  mesher.SetShape(shape);
  mesher.ChangeParameters().Deflection = deflection;
  mesher.ChangeParameters().Angle = angularDeflection;
  mesher.ChangeParameters().InParallel = true;
  mesher.Perform(progress->Start());
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
  if (!mesher.IsDone())
    throw std::runtime_error("OCCT tessellation failed");

  MeshData data;
  ShapeMap faceMap;
  TopExp::MapShapes(shape, TopAbs_FACE, faceMap);
  data.faces.reserve(static_cast<std::size_t>(faceMap.Extent()));
  for (int faceIndex = 1; faceIndex <= faceMap.Extent(); ++faceIndex) {
    const TopoDS_Face face = TopoDS::Face(faceMap(faceIndex));
    TopLoc_Location location;
    const occ::handle<Poly_Triangulation>& triangulation = BRep_Tool::Triangulation(face, location);
    if (triangulation.IsNull()) {
      data.faces.push_back({static_cast<std::uint32_t>(data.triangles.size() / 3), 0,
                            static_cast<std::uint32_t>(data.positions.size() / 3), 0});
      continue;
    }
    triangulation->ComputeNormals();
    const std::uint32_t firstVertex = static_cast<std::uint32_t>(data.positions.size() / 3);
    const std::uint32_t firstTriangle = static_cast<std::uint32_t>(data.triangles.size() / 3);
    const gp_Trsf transform = location.Transformation();
    const bool reversed = face.Orientation() == TopAbs_REVERSED;
    for (int nodeIndex = 1; nodeIndex <= triangulation->NbNodes(); ++nodeIndex) {
      AddPoint(data.positions, triangulation->Node(nodeIndex).Transformed(transform), origin);
      gp_Vec normal(triangulation->Normal(nodeIndex));
      normal.Transform(transform);
      if (reversed)
        normal.Reverse();
      AddNormal(data.normals, normal);
    }
    for (int triangleIndex = 1; triangleIndex <= triangulation->NbTriangles(); ++triangleIndex) {
      int first{};
      int second{};
      int third{};
      triangulation->Triangle(triangleIndex).Get(first, second, third);
      if (reversed)
        std::swap(second, third);
      data.triangles.push_back(firstVertex + static_cast<std::uint32_t>(first - 1));
      data.triangles.push_back(firstVertex + static_cast<std::uint32_t>(second - 1));
      data.triangles.push_back(firstVertex + static_cast<std::uint32_t>(third - 1));
      data.faceIds.push_back(static_cast<std::uint32_t>(faceIndex - 1));
    }
    data.faces.push_back({
        firstTriangle,
        static_cast<std::uint32_t>(triangulation->NbTriangles()),
        firstVertex,
        static_cast<std::uint32_t>(triangulation->NbNodes()),
    });
  }

  ShapeAncestorsMap edgeFaces;
  TopExp::MapShapesAndAncestors(shape, TopAbs_EDGE, TopAbs_FACE, edgeFaces);
  ShapeMap edgeMap;
  TopExp::MapShapes(shape, TopAbs_EDGE, edgeMap);
  data.edges.reserve(static_cast<std::size_t>(edgeMap.Extent()));
  for (int edgeIndex = 1; edgeIndex <= edgeMap.Extent(); ++edgeIndex) {
    const TopoDS_Edge edge = TopoDS::Edge(edgeMap(edgeIndex));
    const std::uint32_t firstVertex = static_cast<std::uint32_t>(data.edgeVertices.size() / 3);
    if (BRep_Tool::Degenerated(edge)) {
      // Degenerate edges (for example sphere poles) carry no 3D curve, so
      // BRepAdaptor_Curve cannot be constructed for them. They stay in the
      // edge table so AEMB edge identity matches the B-rep edge count, but
      // they contribute no renderable polyline.
      data.edges.push_back({firstVertex, 0, EdgeFlags(edge, edgeFaces), 0});
      continue;
    }
    BRepAdaptor_Curve curve(edge);
    GCPnts_QuasiUniformDeflection sampling(curve, std::max(deflection * 0.5, 1e-4),
                                           curve.FirstParameter(), curve.LastParameter());
    if (sampling.IsDone() && sampling.NbPoints() >= 2) {
      for (int pointIndex = 1; pointIndex <= sampling.NbPoints(); ++pointIndex) {
        AddPoint(data.edgeVertices, sampling.Value(pointIndex), origin);
      }
    } else {
      AddPoint(data.edgeVertices, curve.Value(curve.FirstParameter()), origin);
      AddPoint(data.edgeVertices, curve.Value(curve.LastParameter()), origin);
    }
    data.edges.push_back({firstVertex,
                          static_cast<std::uint32_t>(data.edgeVertices.size() / 3) - firstVertex,
                          EdgeFlags(edge, edgeFaces), 0});
  }

  ShapeMap vertexMap;
  TopExp::MapShapes(shape, TopAbs_VERTEX, vertexMap);
  for (int vertexIndex = 1; vertexIndex <= vertexMap.Extent(); ++vertexIndex) {
    AddPoint(data.brepVertices, BRep_Tool::Pnt(TopoDS::Vertex(vertexMap(vertexIndex))), origin);
  }
  return data;
}

std::vector<std::uint8_t> EncodeAemb(const MeshData& data, const std::uint32_t lodTier,
                                     const double deflection, const double angularDeflection,
                                     const std::array<double, 6>& bounds,
                                     const std::array<double, 3>& origin) {
  std::vector<std::uint8_t> bytes(Align16(kHeaderBytes + kSectionCount * kDirectoryEntryBytes), 0);
  std::vector<Section> sections;
  sections.reserve(kSectionCount);
  const auto appendSection = [&](const std::uint32_t id, const auto& values, auto appender) {
    bytes.resize(Align16(bytes.size()), 0);
    const std::uint32_t offset = static_cast<std::uint32_t>(bytes.size());
    appender(bytes, values);
    sections.push_back({id, offset, static_cast<std::uint32_t>(bytes.size() - offset)});
  };
  appendSection(1, data.positions, AppendPodVector<float>);
  appendSection(2, data.normals, AppendPodVector<float>);
  appendSection(3, data.faceIds, AppendPodVector<std::uint32_t>);
  appendSection(4, data.triangles, AppendPodVector<std::uint32_t>);
  appendSection(5, data.faces, AppendFaceTable);
  appendSection(6, data.edgeVertices, AppendPodVector<float>);
  appendSection(7, data.edges, AppendEdgeTable);
  appendSection(8, data.brepVertices, AppendPodVector<float>);

  PutU32(bytes, 0, kAembMagic);
  PutU16(bytes, 4, 2);
  PutU16(bytes, 6, static_cast<std::uint16_t>(kHeaderBytes));
  PutU32(bytes, 8, 0);
  PutU32(bytes, 12, static_cast<std::uint32_t>(data.positions.size() / 3));
  PutU32(bytes, 16, static_cast<std::uint32_t>(data.triangles.size() / 3));
  PutU32(bytes, 20, static_cast<std::uint32_t>(data.faces.size()));
  PutU32(bytes, 24, static_cast<std::uint32_t>(data.edges.size()));
  PutU32(bytes, 28, static_cast<std::uint32_t>(data.edgeVertices.size() / 3));
  PutU32(bytes, 32, static_cast<std::uint32_t>(data.brepVertices.size() / 3));
  PutU32(bytes, 36, kSectionCount);
  PutU32(bytes, 40, lodTier);
  PutF32(bytes, 44, static_cast<float>(deflection));
  // Body-LOCAL minimum corner (world min − origin), matching AddPoint's rebase.
  PutF32(bytes, 48, static_cast<float>(bounds[0] - origin[0]));
  PutF32(bytes, 52, static_cast<float>(bounds[1] - origin[1]));
  PutF32(bytes, 56, static_cast<float>(bounds[2] - origin[2]));
  PutF32(bytes, 60, static_cast<float>(angularDeflection));
  // The f64 rebasing anchor at 64/72/80; bytes 88..95 stay the zero-fill above.
  PutF64(bytes, 64, origin[0]);
  PutF64(bytes, 72, origin[1]);
  PutF64(bytes, 80, origin[2]);
  for (std::size_t index = 0; index < sections.size(); ++index) {
    const std::size_t entry = kHeaderBytes + index * kDirectoryEntryBytes;
    PutU32(bytes, entry, sections[index].id);
    PutU32(bytes, entry + 4, sections[index].offset);
    PutU32(bytes, entry + 8, sections[index].length);
  }
  return bytes;
}

std::uint32_t Crc32(const std::vector<std::uint8_t>& bytes) {
  std::uint32_t crc = 0xFFFFFFFFU;
  for (const std::uint8_t byte : bytes) {
    crc ^= byte;
    for (int bit = 0; bit < 8; ++bit) {
      const std::uint32_t mask = 0U - (crc & 1U);
      crc = (crc >> 1U) ^ (0xEDB88320U & mask);
    }
  }
  return ~crc;
}

std::string HexU32(const std::uint32_t value) {
  std::ostringstream output;
  output << std::hex << std::nouppercase << std::setfill('0') << std::setw(8) << value;
  return output.str();
}

} // namespace

TessellationPacket TessellateShape(const TopoDS_Shape& shape, const std::uint32_t streamSequence,
                                   const std::atomic_bool& cancelled, const std::uint32_t lodTier) {
  const auto bounds = Bounds(shape);
  // AEMB2 rebasing anchor: the body's world-AABB centre, in full double. Every
  // emitted coordinate is stored relative to this point (see AddPoint) so the
  // float32 vertex cast never loses fine features to world placement.
  const std::array<double, 3> origin = {
      (bounds[0] + bounds[3]) / 2.0,
      (bounds[1] + bounds[4]) / 2.0,
      (bounds[2] + bounds[5]) / 2.0,
  };
  // Refuse a body whose world diagonal exceeds the export envelope before any
  // tessellation work: past this the local frame cannot be trusted, and it is
  // the same bound the TS layer enforces. server.cpp maps std::exception here
  // to an error code.
  const double diagonal =
      std::hypot(bounds[3] - bounds[0], bounds[4] - bounds[1], bounds[5] - bounds[2]);
  if (!(diagonal <= kMaxModelExtentMm))
    throw std::runtime_error("model extent exceeds export limit");
  const std::array<double, 6> boundsLocal = {
      bounds[0] - origin[0], bounds[1] - origin[1], bounds[2] - origin[2],
      bounds[3] - origin[0], bounds[4] - origin[1], bounds[5] - origin[2],
  };
  const double deflection = Deflection(bounds, lodTier);
  const double angularDeflection = AngularDeflection(lodTier);
  const MeshData data = BuildMesh(shape, deflection, angularDeflection, origin, cancelled);
  TessellationPacket result;
  result.bytes = EncodeAemb(data, lodTier, deflection, angularDeflection, bounds, origin);
  result.descriptor = {
      {"format", "AEMB2"},
      {"streamSequence", streamSequence},
      {"packetByteLength", result.bytes.size()},
      {"vertexCount", data.positions.size() / 3},
      {"triangleCount", data.triangles.size() / 3},
      {"faceCount", data.faces.size()},
      {"edgeCount", data.edges.size()},
      {"edgeVertexCount", data.edgeVertices.size() / 3},
      {"brepVertexCount", data.brepVertices.size() / 3},
      {"lodTier", lodTier},
      {"deflectionMm", deflection},
      {"angularDeflectionRad", angularDeflection},
      {"checksumCrc32", HexU32(Crc32(result.bytes))},
      {"boundingBoxMm", bounds},
      {"worldOriginMm", origin},
      {"boundingBoxLocalMm", boundsLocal},
  };
  return result;
}

TessellationPacket TessellateShapeForExport(const TopoDS_Shape& shape,
                                            const std::uint32_t streamSequence,
                                            const std::atomic_bool& cancelled) {
  const auto bounds = Bounds(shape);
  // AEMB2 rebasing anchor: the body's world-AABB centre, in full double —
  // computed identically to TessellateShape so fine 0.02 mm features never
  // lose precision to the float32 vertex cast at large world placements.
  const std::array<double, 3> origin = {
      (bounds[0] + bounds[3]) / 2.0,
      (bounds[1] + bounds[4]) / 2.0,
      (bounds[2] + bounds[5]) / 2.0,
  };
  // Same world-extent guard as TessellateShape: refuse a body past the export
  // envelope before any tessellation work (server.cpp maps std::exception here
  // to an error code).
  const double diagonal =
      std::hypot(bounds[3] - bounds[0], bounds[4] - bounds[1], bounds[5] - bounds[2]);
  if (!(diagonal <= kMaxModelExtentMm))
    throw std::runtime_error("model extent exceeds export limit");
  const std::array<double, 6> boundsLocal = {
      bounds[0] - origin[0], bounds[1] - origin[1], bounds[2] - origin[2],
      bounds[3] - origin[0], bounds[4] - origin[1], bounds[5] - origin[2],
  };
  // ABSOLUTE tolerances — NOT the diagonal-scaled Deflection()/AngularDeflection()
  // tier switch. Everything downstream (mesh build, encode, descriptor) is the
  // same path TessellateShape uses; only the tolerances and lodTier differ.
  const MeshData data =
      BuildMesh(shape, kExportLinearDeflectionMm, kExportAngularDeflectionRad, origin, cancelled);
  TessellationPacket result;
  result.bytes = EncodeAemb(data, kExportLodTier, kExportLinearDeflectionMm,
                            kExportAngularDeflectionRad, bounds, origin);
  result.descriptor = {
      {"format", "AEMB2"},
      {"streamSequence", streamSequence},
      {"packetByteLength", result.bytes.size()},
      {"vertexCount", data.positions.size() / 3},
      {"triangleCount", data.triangles.size() / 3},
      {"faceCount", data.faces.size()},
      {"edgeCount", data.edges.size()},
      {"edgeVertexCount", data.edgeVertices.size() / 3},
      {"brepVertexCount", data.brepVertices.size() / 3},
      {"lodTier", kExportLodTier},
      {"deflectionMm", kExportLinearDeflectionMm},
      {"angularDeflectionRad", kExportAngularDeflectionRad},
      {"checksumCrc32", HexU32(Crc32(result.bytes))},
      {"boundingBoxMm", bounds},
      {"worldOriginMm", origin},
      {"boundingBoxLocalMm", boundsLocal},
  };
  return result;
}

} // namespace aeth
