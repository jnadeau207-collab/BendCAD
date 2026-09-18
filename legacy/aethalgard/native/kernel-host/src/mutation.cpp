#include "mutation.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <map>
#include <random>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include <BRepAlgoAPI_BooleanOperation.hxx>
#include <BRepAlgoAPI_Cut.hxx>
#include <BRepAlgoAPI_Fuse.hxx>
#include <BRepAlgoAPI_Splitter.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <BRepFilletAPI_MakeFillet.hxx>
#include <BRepLib.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakeCylinder.hxx>
#include <BRepTools_History.hxx>
#include <BRep_Builder.hxx>
#include <BRep_Tool.hxx>
#include <IFSelect_ReturnStatus.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <STEPControl_StepModelType.hxx>
#include <STEPControl_Writer.hxx>
#include <Standard_Failure.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Compound.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shape.hxx>
#include <TopoDS_Solid.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Ax2.hxx>
#include <gp_Dir.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>

#include "cancel.hpp"
#include "element_names.hpp"
#include "geometry.hpp"
#include "local_operation_history.hpp"
#include "topology.hpp"

namespace aeth {
namespace {

using ShapeMap = NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher>;

// The five fixture records live in mutation.hpp: the OCAF TNaming entrant
// (ocaf_naming.cpp) rebuilds the identical construction programs from the
// same wire payload, so the parsed fixture surface and the deterministic
// builders below are shared through the header instead of duplicated.

/// Mirror of `filletRadiusMaximumFraction` in kernel-protocol.ts. The fillet
/// radius is capped strictly below the geometric maximum for the two faces
/// adjacent to the filleted edge (min(width, depth), where a trimmed
/// neighbour degenerates to zero extent and the fillet surface becomes
/// tangent to the opposite boundary). Degenerate tangency is therefore a
/// fixture-domain exclusion, not a proven oracle robustness — exactly like
/// the split fixture's open (0, 1) offset-fraction domain.
constexpr double kFilletRadiusMaximumFraction = 0.8;

/// Mirror of `bossClearanceMinimumFraction` in kernel-protocol.ts. Every
/// cylindrical feature footprint of the construction-correspondence fixtures
/// must clear the top-face boundary and every other footprint by at least
/// this fraction of its own radius, which makes tangent, overlapping, or
/// boundary-crossing features — and therefore any argument sub-shape
/// splitting into several same-kind pieces — structurally impossible. A
/// fixture-domain exclusion, not an oracle robustness guarantee.
constexpr double kBossClearanceMinimumFraction = 0.25;

/// Mirror of `mergeClearanceMinimumFraction` in kernel-protocol.ts. The tool
/// box's cross-section (perpendicular to the piercing X axis) must clear the
/// target box's Y/Z boundary by this fraction of the tool's own depth/height,
/// and the tool's embedding/protrusion depth along X must each clear the
/// target's X boundary by this fraction of the tool's own width. See the
/// TypeScript constant's documentation for the pathologies this rules out.
constexpr double kMergeClearanceMinimumFraction = 0.2;

/// Mirror of `openingClearanceMinimumFraction` in kernel-protocol.ts. The
/// STEP-interchange fixtures' rectangular through-opening must clear the slab
/// boundary — and, in the import-cut fixture, the corner notch — by this
/// fraction of the opening's own width/depth on the respective axis. This
/// keeps every cut plane strictly separated from every pre-existing face
/// plane, so coplanar-face gluing, tangency, and edge-touching loops are
/// structurally impossible. A fixture-domain exclusion, not an oracle
/// robustness guarantee.
constexpr double kOpeningClearanceMinimumFraction = 0.25;

/// The import-cut fixture's corner notch spans at most this fraction of the
/// slab's width/depth (and at least half the opening clearance fraction of
/// it), bounding the notch away from both far corners and keeping the domain
/// checks in ParseStepImportCutFixture simple and total.
constexpr double kNotchMaximumFraction = 0.4;

double FinitePositive(const nlohmann::json& value, const char* label) {
  const double parsed = value.get<double>();
  if (!std::isfinite(parsed) || parsed <= 0.0) {
    throw std::invalid_argument(std::string(label) + " must be finite and positive");
  }
  return parsed;
}

bool ParseEdgeSide(const nlohmann::json& value, const char* label) {
  const std::string side = value.get<std::string>();
  if (side == "min")
    return false;
  if (side == "max")
    return true;
  throw std::invalid_argument(std::string(label) + " must be min or max");
}

int BoundedCount(const nlohmann::json& value, const char* label, const int minimum,
                 const int maximum) {
  if (!value.is_number_integer()) {
    throw std::invalid_argument(std::string(label) + " must be an integer");
  }
  const int parsed = value.get<int>();
  if (parsed < minimum || parsed > maximum) {
    throw std::invalid_argument(std::string(label) + " must lie in [" + std::to_string(minimum) +
                                ", " + std::to_string(maximum) + "]");
  }
  return parsed;
}

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

} // namespace

// ---------------------------------------------------------------------------
// Shared fixture surface (declared in mutation.hpp): parsers and
// deterministic construction helpers used by both the mutation-case oracle
// below and the OCAF TNaming entrant (ocaf_naming.cpp).
// ---------------------------------------------------------------------------

PlanarSplitFixture ParsePlanarSplitFixture(const nlohmann::json& request) {
  const auto& fixture = request.at("fixture");
  PlanarSplitFixture parsed;
  const auto& box = fixture.at("box");
  parsed.width = FinitePositive(box.at("width"), "box width");
  parsed.depth = FinitePositive(box.at("depth"), "box depth");
  parsed.height = FinitePositive(box.at("height"), "box height");
  const auto& plane = fixture.at("plane");
  const std::string axis = plane.at("axis").get<std::string>();
  if (axis != "x" && axis != "y") {
    throw std::invalid_argument("split plane axis must be x or y");
  }
  parsed.axis = axis.front();
  parsed.offsetFraction = plane.at("offsetFraction").get<double>();
  if (!std::isfinite(parsed.offsetFraction) || parsed.offsetFraction <= 0.0 ||
      parsed.offsetFraction >= 1.0) {
    throw std::invalid_argument("split plane offset fraction must lie strictly inside (0, 1)");
  }
  parsed.baseOperationId = fixture.at("baseOperationId").get<std::string>();
  parsed.splitOperationId = fixture.at("splitOperationId").get<std::string>();
  if (parsed.baseOperationId.empty() || parsed.splitOperationId.empty()) {
    throw std::invalid_argument("mutation fixture operation IDs must be non-empty");
  }
  return parsed;
}

FilletFixture ParseFilletFixture(const nlohmann::json& request) {
  const auto& fixture = request.at("fixture");
  FilletFixture parsed;
  const auto& box = fixture.at("box");
  parsed.width = FinitePositive(box.at("width"), "box width");
  parsed.depth = FinitePositive(box.at("depth"), "box depth");
  parsed.height = FinitePositive(box.at("height"), "box height");
  const auto& fillet = fixture.at("fillet");
  parsed.radius = FinitePositive(fillet.at("radius"), "fillet radius");
  const double maximumRadius = kFilletRadiusMaximumFraction * std::min(parsed.width, parsed.depth);
  if (parsed.radius > maximumRadius) {
    throw std::invalid_argument(
        "fillet radius must stay at or below the fixture cap of 0.8 x min(width, depth)");
  }
  const auto& edge = fillet.at("edge");
  parsed.edgeAtXMax = ParseEdgeSide(edge.at("xSide"), "fillet edge xSide");
  parsed.edgeAtYMax = ParseEdgeSide(edge.at("ySide"), "fillet edge ySide");
  parsed.baseOperationId = fixture.at("baseOperationId").get<std::string>();
  parsed.filletOperationId = fixture.at("filletOperationId").get<std::string>();
  if (parsed.baseOperationId.empty() || parsed.filletOperationId.empty()) {
    throw std::invalid_argument("mutation fixture operation IDs must be non-empty");
  }
  return parsed;
}

LinearPatternFixture ParseLinearPatternFixture(const nlohmann::json& request) {
  const auto& fixture = request.at("fixture");
  LinearPatternFixture parsed;
  const auto& box = fixture.at("box");
  parsed.width = FinitePositive(box.at("width"), "box width");
  parsed.depth = FinitePositive(box.at("depth"), "box depth");
  parsed.height = FinitePositive(box.at("height"), "box height");
  const auto& boss = fixture.at("boss");
  parsed.bossRadius = FinitePositive(boss.at("radius"), "boss radius");
  parsed.bossHeight = FinitePositive(boss.at("height"), "boss height");
  const auto& layout = fixture.at("layout");
  parsed.firstCenterX = FinitePositive(layout.at("firstCenterX"), "layout firstCenterX");
  parsed.centerY = FinitePositive(layout.at("centerY"), "layout centerY");
  parsed.pitch = FinitePositive(layout.at("pitch"), "layout pitch");
  const auto& count = fixture.at("instanceCount");
  parsed.countBefore = BoundedCount(count.at("before"), "instance count before", 2, 6);
  parsed.countAfter = BoundedCount(count.at("after"), "instance count after", 1, 7);
  if (std::abs(parsed.countBefore - parsed.countAfter) != 1) {
    throw std::invalid_argument("instance count must change by exactly one");
  }
  const double clearance = kBossClearanceMinimumFraction * parsed.bossRadius;
  if (parsed.pitch < 2.0 * parsed.bossRadius + clearance) {
    throw std::invalid_argument("adjacent instances must clear each other by the minimum");
  }
  const int maxCount = std::max(parsed.countBefore, parsed.countAfter);
  const double lastCenterX = parsed.firstCenterX + (maxCount - 1) * parsed.pitch;
  if (parsed.firstCenterX - parsed.bossRadius < clearance ||
      parsed.width - (lastCenterX + parsed.bossRadius) < clearance ||
      parsed.centerY - parsed.bossRadius < clearance ||
      parsed.depth - (parsed.centerY + parsed.bossRadius) < clearance) {
    throw std::invalid_argument(
        "every instance footprint must clear the top-face boundary by the minimum");
  }
  parsed.baseOperationId = fixture.at("baseOperationId").get<std::string>();
  parsed.arrayOperationId = fixture.at("arrayOperationId").get<std::string>();
  if (parsed.baseOperationId.empty() || parsed.arrayOperationId.empty()) {
    throw std::invalid_argument("mutation fixture operation IDs must be non-empty");
  }
  return parsed;
}

BossSuppressionFixture ParseBossSuppressionFixture(const nlohmann::json& request) {
  const auto& fixture = request.at("fixture");
  BossSuppressionFixture parsed;
  const auto& box = fixture.at("box");
  parsed.width = FinitePositive(box.at("width"), "box width");
  parsed.depth = FinitePositive(box.at("depth"), "box depth");
  parsed.height = FinitePositive(box.at("height"), "box height");
  const auto& boss = fixture.at("boss");
  parsed.bossRadius = FinitePositive(boss.at("radius"), "boss radius");
  parsed.bossHeight = FinitePositive(boss.at("height"), "boss height");
  parsed.bossCenterX = FinitePositive(boss.at("center").at("x"), "boss center x");
  parsed.bossCenterY = FinitePositive(boss.at("center").at("y"), "boss center y");
  const auto& hole = fixture.at("hole");
  parsed.holeRadius = FinitePositive(hole.at("radius"), "hole radius");
  parsed.holeCenterX = FinitePositive(hole.at("center").at("x"), "hole center x");
  parsed.holeCenterY = FinitePositive(hole.at("center").at("y"), "hole center y");
  const auto inTopFace = [&](const double centerX, const double centerY, const double radius) {
    const double clearance = kBossClearanceMinimumFraction * radius;
    return centerX - radius >= clearance && parsed.width - (centerX + radius) >= clearance &&
           centerY - radius >= clearance && parsed.depth - (centerY + radius) >= clearance;
  };
  if (!inTopFace(parsed.bossCenterX, parsed.bossCenterY, parsed.bossRadius)) {
    throw std::invalid_argument("boss footprint must clear the top-face boundary");
  }
  if (!inTopFace(parsed.holeCenterX, parsed.holeCenterY, parsed.holeRadius)) {
    throw std::invalid_argument("hole footprint must clear the top-face boundary");
  }
  const double distance =
      std::hypot(parsed.bossCenterX - parsed.holeCenterX, parsed.bossCenterY - parsed.holeCenterY);
  const double clearance =
      kBossClearanceMinimumFraction * std::max(parsed.bossRadius, parsed.holeRadius);
  if (distance < parsed.bossRadius + parsed.holeRadius + clearance) {
    throw std::invalid_argument("boss and hole footprints must clear each other by the minimum");
  }
  parsed.baseOperationId = fixture.at("baseOperationId").get<std::string>();
  parsed.bossOperationId = fixture.at("bossOperationId").get<std::string>();
  parsed.holeOperationId = fixture.at("holeOperationId").get<std::string>();
  if (parsed.baseOperationId.empty() || parsed.bossOperationId.empty() ||
      parsed.holeOperationId.empty()) {
    throw std::invalid_argument("mutation fixture operation IDs must be non-empty");
  }
  return parsed;
}

MergeFixture ParseMergeFixture(const nlohmann::json& request) {
  const auto& fixture = request.at("fixture");
  MergeFixture parsed;
  const auto& target = fixture.at("target");
  parsed.targetWidth = FinitePositive(target.at("width"), "target width");
  parsed.targetDepth = FinitePositive(target.at("depth"), "target depth");
  parsed.targetHeight = FinitePositive(target.at("height"), "target height");
  const auto& tool = fixture.at("tool");
  parsed.toolWidth = FinitePositive(tool.at("width"), "tool width");
  parsed.toolDepth = FinitePositive(tool.at("depth"), "tool depth");
  parsed.toolHeight = FinitePositive(tool.at("height"), "tool height");
  const auto& placement = tool.at("placement");
  parsed.originX = FinitePositive(placement.at("originX"), "tool origin x");
  parsed.originY = FinitePositive(placement.at("originY"), "tool origin y");
  parsed.originZ = FinitePositive(placement.at("originZ"), "tool origin z");

  // Cross-axis (Y, Z) footprint clearance: the tool's Y/Z cross-section must
  // clear the target's Y/Z boundary on every side by this fraction of the
  // tool's own depth/height, mirroring kBossClearanceMinimumFraction's
  // footprint-clears-boundary discipline. This keeps the piercing hole
  // strictly interior to the target's pierced face -- never touching that
  // face's own bounding edges -- which is what makes the hole a single,
  // well-defined loop rather than an edge-touching notch whose
  // classification would be ambiguous.
  const double crossClearanceY = kMergeClearanceMinimumFraction * parsed.toolDepth;
  if (parsed.originY < crossClearanceY ||
      parsed.targetDepth - (parsed.originY + parsed.toolDepth) < crossClearanceY) {
    throw std::invalid_argument("merge tool footprint must clear the target depth boundary");
  }
  const double crossClearanceZ = kMergeClearanceMinimumFraction * parsed.toolHeight;
  if (parsed.originZ < crossClearanceZ ||
      parsed.targetHeight - (parsed.originZ + parsed.toolHeight) < crossClearanceZ) {
    throw std::invalid_argument("merge tool footprint must clear the target height boundary");
  }

  // Piercing-axis (X) embedding/protrusion depth: the tool must start
  // clearly inside the target (never near x=0, avoiding coincidence with the
  // target's own min-X face) and end clearly beyond the target's max-X face
  // (never near x=width, avoiding coincidence and a tangential sliver
  // protrusion), each by a margin expressed as a fraction of the tool's own
  // width -- mirroring the split fixture's open (0, 1) offsetFraction
  // discipline.
  const double pierceClearance = kMergeClearanceMinimumFraction * parsed.toolWidth;
  if (parsed.originX < pierceClearance || parsed.targetWidth - parsed.originX < pierceClearance) {
    throw std::invalid_argument("merge tool must be embedded clear of the target width boundary");
  }
  if (parsed.originX + parsed.toolWidth - parsed.targetWidth < pierceClearance) {
    throw std::invalid_argument("merge tool must protrude clear beyond the target width boundary");
  }

  parsed.targetOperationId = fixture.at("targetOperationId").get<std::string>();
  parsed.toolOperationId = fixture.at("toolOperationId").get<std::string>();
  parsed.mergeOperationId = fixture.at("mergeOperationId").get<std::string>();
  if (parsed.targetOperationId.empty() || parsed.toolOperationId.empty() ||
      parsed.mergeOperationId.empty()) {
    throw std::invalid_argument("mutation fixture operation IDs must be non-empty");
  }
  if (fixture.contains("argumentOrder")) {
    const std::string order = fixture.at("argumentOrder").get<std::string>();
    if (order != "target-first" && order != "tool-first") {
      throw std::invalid_argument("merge argumentOrder must be target-first or tool-first");
    }
    parsed.toolFirst = order == "tool-first";
  }
  return parsed;
}

namespace {

/// Shared slab/opening domain checks of the two STEP-interchange fixtures:
/// the rectangular through-opening must sit strictly interior to the slab's
/// top face, clearing the boundary on each axis by
/// kOpeningClearanceMinimumFraction of the opening's own extent on that axis.
void ValidateSlabOpening(const double width, const double depth, const double openingOriginX,
                         const double openingOriginY, const double openingWidth,
                         const double openingDepth) {
  const double clearanceX = kOpeningClearanceMinimumFraction * openingWidth;
  if (openingOriginX < clearanceX || width - (openingOriginX + openingWidth) < clearanceX) {
    throw std::invalid_argument("opening must clear the slab width boundary by the minimum");
  }
  const double clearanceY = kOpeningClearanceMinimumFraction * openingDepth;
  if (openingOriginY < clearanceY || depth - (openingOriginY + openingDepth) < clearanceY) {
    throw std::invalid_argument("opening must clear the slab depth boundary by the minimum");
  }
}

} // namespace

StepReimportFixture ParseStepReimportFixture(const nlohmann::json& request) {
  const auto& fixture = request.at("fixture");
  StepReimportFixture parsed;
  const auto& slab = fixture.at("slab");
  parsed.width = FinitePositive(slab.at("width"), "slab width");
  parsed.depth = FinitePositive(slab.at("depth"), "slab depth");
  parsed.height = FinitePositive(slab.at("height"), "slab height");
  const auto& opening = fixture.at("opening");
  parsed.openingOriginX = FinitePositive(opening.at("originX"), "opening origin x");
  parsed.openingOriginY = FinitePositive(opening.at("originY"), "opening origin y");
  parsed.openingWidth = FinitePositive(opening.at("width"), "opening width");
  parsed.openingDepth = FinitePositive(opening.at("depth"), "opening depth");
  ValidateSlabOpening(parsed.width, parsed.depth, parsed.openingOriginX, parsed.openingOriginY,
                      parsed.openingWidth, parsed.openingDepth);
  parsed.sourceOperationId = fixture.at("sourceOperationId").get<std::string>();
  if (parsed.sourceOperationId.empty()) {
    throw std::invalid_argument("mutation fixture operation IDs must be non-empty");
  }
  return parsed;
}

StepImportCutFixture ParseStepImportCutFixture(const nlohmann::json& request) {
  const auto& fixture = request.at("fixture");
  StepImportCutFixture parsed;
  const auto& slab = fixture.at("slab");
  parsed.width = FinitePositive(slab.at("width"), "slab width");
  parsed.depth = FinitePositive(slab.at("depth"), "slab depth");
  parsed.height = FinitePositive(slab.at("height"), "slab height");
  const auto& opening = fixture.at("opening");
  parsed.openingOriginX = FinitePositive(opening.at("originX"), "opening origin x");
  parsed.openingOriginY = FinitePositive(opening.at("originY"), "opening origin y");
  parsed.openingWidth = FinitePositive(opening.at("width"), "opening width");
  parsed.openingDepth = FinitePositive(opening.at("depth"), "opening depth");
  ValidateSlabOpening(parsed.width, parsed.depth, parsed.openingOriginX, parsed.openingOriginY,
                      parsed.openingWidth, parsed.openingDepth);
  const auto& notch = fixture.at("notch");
  parsed.notchWidth = FinitePositive(notch.at("width"), "notch width");
  parsed.notchDepth = FinitePositive(notch.at("depth"), "notch depth");
  // The notch occupies [width - notchWidth, width] x [0, notchDepth]. Bound
  // it away from the far corners so the x = 0 and y = depth faces are never
  // touched, and keep its two interior cut planes clear of the opening by
  // the opening's own clearance fractions — every cut plane then stays
  // strictly separated from every pre-existing plane (no gluing, no
  // tangency, no edge-touching loops).
  if (parsed.notchWidth > kNotchMaximumFraction * parsed.width ||
      parsed.notchDepth > kNotchMaximumFraction * parsed.depth) {
    throw std::invalid_argument("notch must span at most the fixture fraction of the slab");
  }
  const double clearanceX = kOpeningClearanceMinimumFraction * parsed.openingWidth;
  if (parsed.width - parsed.notchWidth < parsed.openingOriginX + parsed.openingWidth + clearanceX) {
    throw std::invalid_argument("notch must clear the opening along the width axis");
  }
  const double clearanceY = kOpeningClearanceMinimumFraction * parsed.openingDepth;
  if (parsed.openingOriginY < parsed.notchDepth + clearanceY) {
    throw std::invalid_argument("notch must clear the opening along the depth axis");
  }
  parsed.sourceOperationId = fixture.at("sourceOperationId").get<std::string>();
  parsed.cutOperationId = fixture.at("cutOperationId").get<std::string>();
  if (parsed.sourceOperationId.empty() || parsed.cutOperationId.empty()) {
    throw std::invalid_argument("mutation fixture operation IDs must be non-empty");
  }
  return parsed;
}

/// The mutation-fixture box occupies [0, width] x [0, depth] x [0, height];
/// every fixture coordinate contract is stated against this placement.
TopoDS_Shape BuildBaseBox(const double width, const double depth, const double height,
                          const std::atomic_bool& cancelled) {
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepPrimAPI_MakeBox maker;
  maker.Init(width, depth, height);
  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  TopoDS_Solid solid = maker.Solid();
  BRepLib::OrientClosedSolid(solid);
  return solid;
}

/// Places a box with one corner at (originX, originY, originZ) instead of the
/// origin -- the merge fixture's "tool" box, which must be positioned
/// relative to the canonically-placed "target" box built by BuildBaseBox.
TopoDS_Shape BuildBoxAt(const double originX, const double originY, const double originZ,
                        const double width, const double depth, const double height,
                        const std::atomic_bool& cancelled) {
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepPrimAPI_MakeBox maker(gp_Pnt(originX, originY, originZ), width, depth, height);
  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  TopoDS_Solid solid = maker.Solid();
  BRepLib::OrientClosedSolid(solid);
  return solid;
}

TopoDS_Face BuildSplitTool(const PlanarSplitFixture& fixture) {
  // Vertical split plane: the plane contains the Z direction; its normal is a
  // horizontal axis (X or Y) at a parameterized offset through the box.
  const bool alongX = fixture.axis == 'x';
  const double extent = alongX ? fixture.width : fixture.depth;
  const double offset = fixture.offsetFraction * extent;
  const gp_Pnt location = alongX ? gp_Pnt(offset, fixture.depth * 0.5, fixture.height * 0.5)
                                 : gp_Pnt(fixture.width * 0.5, offset, fixture.height * 0.5);
  const gp_Dir normal = alongX ? gp_Dir(1.0, 0.0, 0.0) : gp_Dir(0.0, 1.0, 0.0);
  // The bounded tool face must fully cross the solid; the sum of the extents
  // from the plane location covers every box point with margin to spare.
  const double margin = fixture.width + fixture.depth + fixture.height;
  const BRepBuilderAPI_MakeFace faceMaker(gp_Pln(location, normal), -margin, margin, -margin,
                                          margin);
  if (faceMaker.Error() != BRepBuilderAPI_FaceDone) {
    throw Standard_Failure("split tool face construction failed");
  }
  return faceMaker.Face();
}

/// Deterministic fillet-edge selection contract: the single vertical box edge
/// (parallel to Z, spanning z in [0, height]) whose two vertices sit at
/// (x, y, 0) and (x, y, height), where x is 0 or width per the fixture's
/// xSide and y is 0 or depth per its ySide. Selection matches exact vertex
/// coordinates within a small absolute tolerance and fails the request unless
/// exactly one box edge matches — never a geometric-similarity guess.
TopoDS_Edge SelectFilletEdge(const TopoDS_Shape& solid, const FilletFixture& fixture) {
  const double edgeX = fixture.edgeAtXMax ? fixture.width : 0.0;
  const double edgeY = fixture.edgeAtYMax ? fixture.depth : 0.0;
  const double tolerance = 1e-9 * (fixture.width + fixture.depth + fixture.height);
  ShapeMap edges;
  TopExp::MapShapes(solid, TopAbs_EDGE, edges);
  TopoDS_Edge selected;
  int matchCount = 0;
  for (int edgeIndex = 1; edgeIndex <= edges.Extent(); ++edgeIndex) {
    const TopoDS_Edge edge = TopoDS::Edge(edges(edgeIndex));
    TopoDS_Vertex first;
    TopoDS_Vertex last;
    TopExp::Vertices(edge, first, last);
    if (first.IsNull() || last.IsNull())
      continue;
    const gp_Pnt a = BRep_Tool::Pnt(first);
    const gp_Pnt b = BRep_Tool::Pnt(last);
    const auto atCorner = [&](const gp_Pnt& point, const double z) {
      return std::abs(point.X() - edgeX) <= tolerance && std::abs(point.Y() - edgeY) <= tolerance &&
             std::abs(point.Z() - z) <= tolerance;
    };
    if ((atCorner(a, 0.0) && atCorner(b, fixture.height)) ||
        (atCorner(a, fixture.height) && atCorner(b, 0.0))) {
      selected = edge;
      ++matchCount;
    }
  }
  if (matchCount != 1 || selected.IsNull()) {
    throw Standard_Failure("fillet fixture did not select exactly one vertical box edge");
  }
  return selected;
}

TopoDS_Shape RunPlanarSplitIntoHistory(const TopoDS_Shape& baseSolid, const TopoDS_Face& splitTool,
                                       const std::atomic_bool& cancelled,
                                       occ::handle<BRepTools_History>& historyOut) {
  // BRepAlgoAPI_Splitter is chosen over a BRepAlgoAPI_Common/Cut composition:
  // the split is a single General-Fuse evaluation, so one History() covers
  // every argument sub-shape. A Common+Cut composition would run two
  // independent algorithms whose histories would need to be stitched together
  // by re-identifying coincident section geometry across two results — exactly
  // the geometric-similarity inference this oracle is forbidden to use.
  BRepAlgoAPI_Splitter splitter;
  NCollection_List<TopoDS_Shape> objects;
  objects.Append(baseSolid);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(splitTool);
  splitter.SetArguments(objects);
  splitter.SetTools(tools);
  splitter.SetRunParallel(false);
  splitter.SetToFillHistory(true);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    splitter.Build(progress->Start());
  }
  CheckCancellation(cancelled);
  if (splitter.HasErrors())
    throw Standard_Failure("planar split failed");
  const TopoDS_Shape result = splitter.Shape();
  if (result.IsNull())
    throw Standard_Failure("planar split produced no result");
  // History() returns a reference-counted opencascade::handle<BRepTools_History>
  // that safely outlives the non-copyable algorithm object; retaining the handle
  // (not the splitter) is the supported lifetime contract.
  historyOut = splitter.History();
  if (historyOut.IsNull())
    throw std::runtime_error("splitter did not record algorithm history");
  return result;
}

namespace {

char KindCode(const TopAbs_ShapeEnum type) {
  switch (type) {
  case TopAbs_FACE:
    return 'f';
  case TopAbs_EDGE:
    return 'e';
  case TopAbs_VERTEX:
    return 'v';
  default:
    throw std::runtime_error("mutation oracle covers faces, edges, and vertices only");
  }
}

const char* KindName(const TopAbs_ShapeEnum type) {
  switch (type) {
  case TopAbs_FACE:
    return "face";
  case TopAbs_EDGE:
    return "edge";
  case TopAbs_VERTEX:
    return "vertex";
  default:
    throw std::runtime_error("mutation oracle covers faces, edges, and vertices only");
  }
}

/// Indexed face/edge/vertex maps of the AFTER shape. Generated() relations
/// are cross-kind (a before-edge generates an after-vertex, a before-face an
/// after-edge), so every oracle entry needs all three maps, not just the map
/// of its own kind.
struct AfterShapeIndex final {
  ShapeMap faces;
  ShapeMap edges;
  ShapeMap vertices;

  explicit AfterShapeIndex(const TopoDS_Shape& after) {
    TopExp::MapShapes(after, TopAbs_FACE, faces);
    TopExp::MapShapes(after, TopAbs_EDGE, edges);
    TopExp::MapShapes(after, TopAbs_VERTEX, vertices);
  }

  const ShapeMap& ForType(const TopAbs_ShapeEnum type) const {
    switch (type) {
    case TopAbs_FACE:
      return faces;
    case TopAbs_EDGE:
      return edges;
    case TopAbs_VERTEX:
      return vertices;
    default:
      throw std::runtime_error("mutation oracle covers faces, edges, and vertices only");
    }
  }
};

} // namespace

TopoDS_Shape RunFilletIntoHistory(const TopoDS_Shape& baseSolid, const FilletFixture& fixture,
                                  const std::atomic_bool& cancelled,
                                  occ::handle<BRepTools_History>& historyOut) {
  const TopoDS_Edge spineEdge = SelectFilletEdge(baseSolid, fixture);
  BRepFilletAPI_MakeFillet maker(baseSolid);
  maker.Add(fixture.radius, spineEdge);
  // BRepFilletAPI_MakeFillet::Build ignores its progress range in the pinned
  // source, so the fillet computation itself is not interruptible; the
  // cancellation flag is re-checked immediately afterwards.
  maker.Build();
  CheckCancellation(cancelled);
  if (!maker.IsDone() || maker.NbFaultyContours() != 0 || maker.NbFaultyVertices() != 0)
    throw Standard_Failure("fillet construction failed");
  const TopoDS_Shape result = maker.Shape();
  if (result.IsNull())
    throw Standard_Failure("fillet produced no result");
  // BRepFilletAPI_MakeFillet exposes no History() handle the way General-Fuse
  // algorithms do; the supported path is BRepTools_History's template
  // constructor over the standard IsDeleted/Modified/Generated surface, with
  // the IsDeleted correction documented on LocalOperationHistorySource.
  NCollection_List<TopoDS_Shape> arguments;
  arguments.Append(baseSolid);
  LocalOperationHistorySource historySource(maker, result);
  historyOut = new BRepTools_History(arguments, historySource);
  return result;
}

namespace {

/// Oracle entries for every BEFORE entity of one shape kind, computed only
/// from the recorded algorithm history: IsRemoved(), Modified(), and
/// Generated() are all consulted. Fate semantics (IsRemoved/Modified plus
/// result membership):
/// - "gone": History()->IsRemoved reports the entity left no trace;
/// - "stable-single": exactly one same-kind descendant, either the identity
///   survivor (empty Modified list, entity still present in the result) or a
///   single Modified image;
/// - "stable-set": two or more same-kind Modified images (a split face maps
///   to both pieces).
/// Generated() images never affect the fate; they are reported in the
/// additive "generated" field. They are cross-kind by OCCT contract, never
/// intersect the Modified set (G(S) and M(S) are disjoint), and are legal on
/// every fate including "gone": a fillet-class algorithm removes an edge yet
/// generates a face from it.
/// A surviving entity that history cannot place in the result is a
/// contract violation and fails the request instead of being guessed at.
nlohmann::json OracleEntriesForKind(const BRepTools_History& history, const TopoDS_Shape& before,
                                    const AfterShapeIndex& afterIndex, const TopAbs_ShapeEnum type,
                                    const std::uint32_t evaluationEpoch,
                                    const std::atomic_bool& cancelled) {
  const char code = KindCode(type);
  ShapeMap beforeShapes;
  TopExp::MapShapes(before, type, beforeShapes);
  const ShapeMap& afterShapes = afterIndex.ForType(type);
  nlohmann::json entries = nlohmann::json::array();
  for (int beforeIndex = 1; beforeIndex <= beforeShapes.Extent(); ++beforeIndex) {
    CheckCancellation(cancelled);
    const TopoDS_Shape& shape = beforeShapes(beforeIndex);
    nlohmann::json entry = {
        {"beforeToken", TopologyEntityToken(evaluationEpoch, 0, code, beforeIndex - 1)},
        {"afterTokens", nlohmann::json::array()},
    };
    // Generated images are collected before the fate branches: a removed
    // entity may still generate shapes, so this must not sit behind the
    // IsRemoved early exit.
    ShapeMap generatedShapes;
    for (const TopoDS_Shape& image : history.Generated(shape)) {
      generatedShapes.Add(image);
    }
    if (!generatedShapes.IsEmpty()) {
      nlohmann::json generated = nlohmann::json::array();
      for (int generatedIndex = 1; generatedIndex <= generatedShapes.Extent(); ++generatedIndex) {
        const TopoDS_Shape& image = generatedShapes(generatedIndex);
        const TopAbs_ShapeEnum imageType = image.ShapeType();
        const int afterImageIndex = afterIndex.ForType(imageType).FindIndex(image);
        if (afterImageIndex <= 0) {
          throw std::runtime_error(
              "history reports a generated image that is absent from the mutation result");
        }
        generated.push_back({
            {"token",
             TopologyEntityToken(evaluationEpoch, 1, KindCode(imageType), afterImageIndex - 1)},
            {"kind", KindName(imageType)},
        });
      }
      entry["generated"] = std::move(generated);
    }
    if (history.IsRemoved(shape)) {
      entry["fate"] = "gone";
      entries.push_back(std::move(entry));
      continue;
    }
    ShapeMap descendants;
    for (const TopoDS_Shape& modified : history.Modified(shape)) {
      if (modified.ShapeType() == type)
        descendants.Add(modified);
    }
    if (descendants.IsEmpty()) {
      const int survivorIndex = afterShapes.FindIndex(shape);
      if (survivorIndex <= 0) {
        throw std::runtime_error(
            "history reports a surviving entity that is absent from the mutation result");
      }
      entry["fate"] = "stable-single";
      entry["afterTokens"].push_back(
          TopologyEntityToken(evaluationEpoch, 1, code, survivorIndex - 1));
      entries.push_back(std::move(entry));
      continue;
    }
    for (int descendantIndex = 1; descendantIndex <= descendants.Extent(); ++descendantIndex) {
      const int descendantAfterIndex = afterShapes.FindIndex(descendants(descendantIndex));
      if (descendantAfterIndex <= 0) {
        throw std::runtime_error(
            "history reports a modified descendant that is absent from the mutation result");
      }
      entry["afterTokens"].push_back(
          TopologyEntityToken(evaluationEpoch, 1, code, descendantAfterIndex - 1));
    }
    entry["fate"] = descendants.Extent() == 1 ? "stable-single" : "stable-set";
    entries.push_back(std::move(entry));
  }
  return entries;
}

nlohmann::json OracleEntries(const BRepTools_History& history, const TopoDS_Shape& before,
                             const TopoDS_Shape& result, const std::uint32_t evaluationEpoch,
                             const std::atomic_bool& cancelled) {
  nlohmann::json entries = nlohmann::json::array();
  const AfterShapeIndex afterIndex(result);
  const std::array<TopAbs_ShapeEnum, 3> kinds{TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX};
  for (const TopAbs_ShapeEnum kind : kinds) {
    for (auto& entry :
         OracleEntriesForKind(history, before, afterIndex, kind, evaluationEpoch, cancelled)) {
      entries.push_back(std::move(entry));
    }
  }
  return entries;
}

EvaluatedBody DescribeBeforeBody(const TopoDS_Shape& baseSolid, const std::string& operationId) {
  EvaluatedBody beforeBody;
  beforeBody.bodyId = "mutation-before";
  beforeBody.operationId = operationId;
  beforeBody.shape = baseSolid;
  beforeBody.probes = ProbeShape(baseSolid);
  if (!beforeBody.probes.valid)
    throw Standard_Failure("mutation base solid is invalid");
  return beforeBody;
}

nlohmann::json BuildPlanarSplitCase(const PlanarSplitFixture& fixture,
                                    const std::uint32_t evaluationEpoch,
                                    const bool includeElementNames,
                                    const std::atomic_bool& cancelled) {
  const TopoDS_Shape baseSolid =
      BuildBaseBox(fixture.width, fixture.depth, fixture.height, cancelled);
  const EvaluatedBody beforeBody = DescribeBeforeBody(baseSolid, fixture.baseOperationId);
  nlohmann::json before = DescribeTopology(beforeBody, evaluationEpoch, 0, cancelled);

  // The tool face is hoisted to a named local so the element-name book can
  // register and thread the EXACT instance the splitter consumed —
  // BRepTools_History keys on shape identity, so a re-built tool would
  // silently sever the section face's lineage (the Copy=true trap, research
  // 02 §5). The single-General-Fuse rationale lives on
  // RunPlanarSplitIntoHistory, which the OCAF entrant shares.
  const TopoDS_Face splitTool = BuildSplitTool(fixture);
  occ::handle<BRepTools_History> history;
  const TopoDS_Shape result = RunPlanarSplitIntoHistory(baseSolid, splitTool, cancelled, history);

  EvaluatedBody afterBody;
  afterBody.bodyId = "mutation-after";
  afterBody.operationId = fixture.splitOperationId;
  afterBody.shape = result;
  afterBody.probes = ProbeShape(result);
  if (!afterBody.probes.valid)
    throw Standard_Failure("planar split produced an invalid shape");
  if (afterBody.probes.solidCount < 2)
    throw Standard_Failure("planar split did not divide the solid");

  // Preserved sub-shapes keep the provenance of the operation that created
  // them; every image minted by the split carries the split operation. This is
  // a set-membership question against the argument shape, not a geometric
  // similarity judgement.
  ShapeMap beforeSubshapes;
  TopExp::MapShapes(baseSolid, beforeSubshapes);
  const ProvenanceResolver provenance = [&](const TopoDS_Shape& shape) {
    return beforeSubshapes.Contains(shape) ? fixture.baseOperationId : fixture.splitOperationId;
  };
  nlohmann::json after = DescribeTopology(afterBody, evaluationEpoch, 1, cancelled, provenance);

  nlohmann::json oracle = {
      {"entries", OracleEntries(*history, baseSolid, result, evaluationEpoch, cancelled)}};
  nlohmann::json response = {
      {"type", "mutation_case"},
      {"epoch", evaluationEpoch},
      {"fixtureKind", "planar-split"},
      {"before", std::move(before)},
      {"after", std::move(after)},
      {"beforeProbes", ProbesToJson(beforeBody.probes)},
      {"afterProbes", ProbesToJson(afterBody.probes)},
      {"oracle", std::move(oracle)},
  };
  if (includeElementNames) {
    ElementNameBook book;
    book.AddPrimitive(fixture.baseOperationId, baseSolid);
    response["beforeElementNames"] = ProjectElementNames(book, baseSolid, evaluationEpoch, 0);
    // The cutting tool has no document identity of its own (it is never in
    // the before snapshot), so its sub-shapes root at the mutating
    // operation: the section face's name then reads as an image minted by
    // that operation, mirroring the provenance resolver above.
    book.AddPrimitive(fixture.splitOperationId, splitTool);
    book.ApplyOperation(fixture.splitOperationId, {baseSolid, splitTool}, result, *history,
                        cancelled);
    response["afterElementNames"] = ProjectElementNames(book, result, evaluationEpoch, 1);
  }
  return response;
}

nlohmann::json BuildFilletCase(const FilletFixture& fixture, const std::uint32_t evaluationEpoch,
                               const bool includeElementNames, const std::atomic_bool& cancelled) {
  const TopoDS_Shape baseSolid =
      BuildBaseBox(fixture.width, fixture.depth, fixture.height, cancelled);
  const EvaluatedBody beforeBody = DescribeBeforeBody(baseSolid, fixture.baseOperationId);
  nlohmann::json before = DescribeTopology(beforeBody, evaluationEpoch, 0, cancelled);

  occ::handle<BRepTools_History> history;
  const TopoDS_Shape result = RunFilletIntoHistory(baseSolid, fixture, cancelled, history);

  EvaluatedBody afterBody;
  afterBody.bodyId = "mutation-after";
  afterBody.operationId = fixture.filletOperationId;
  afterBody.shape = result;
  afterBody.probes = ProbeShape(result);
  if (!afterBody.probes.valid)
    throw Standard_Failure("fillet produced an invalid shape");
  if (afterBody.probes.solidCount != 1)
    throw Standard_Failure("fillet did not preserve a single solid");
  if (afterBody.probes.faceCount <= beforeBody.probes.faceCount)
    throw Standard_Failure("fillet did not add a fillet face");

  // Preserved sub-shapes keep the provenance of the operation that created
  // them; every image minted by the fillet (the fillet face, re-trimmed
  // neighbours, new boundary edges and vertices) carries the fillet
  // operation. Set membership against the argument shape, not geometric
  // similarity.
  ShapeMap beforeSubshapes;
  TopExp::MapShapes(baseSolid, beforeSubshapes);
  const ProvenanceResolver provenance = [&](const TopoDS_Shape& shape) {
    return beforeSubshapes.Contains(shape) ? fixture.baseOperationId : fixture.filletOperationId;
  };
  nlohmann::json after = DescribeTopology(afterBody, evaluationEpoch, 1, cancelled, provenance);

  nlohmann::json oracle = {
      {"entries", OracleEntries(*history, baseSolid, result, evaluationEpoch, cancelled)}};
  nlohmann::json response = {
      {"type", "mutation_case"},
      {"epoch", evaluationEpoch},
      {"fixtureKind", "fillet"},
      {"before", std::move(before)},
      {"after", std::move(after)},
      {"beforeProbes", ProbesToJson(beforeBody.probes)},
      {"afterProbes", ProbesToJson(afterBody.probes)},
      {"oracle", std::move(oracle)},
  };
  if (includeElementNames) {
    // The fillet history is face-only for Modified() (documented on
    // FilletHistorySource), so the book's lower-bound reconstruction passes
    // are what name the blend boundary edges and vertices — exactly the gap
    // the element-map scheme exists to fill.
    ElementNameBook book;
    book.AddPrimitive(fixture.baseOperationId, baseSolid);
    response["beforeElementNames"] = ProjectElementNames(book, baseSolid, evaluationEpoch, 0);
    book.ApplyOperation(fixture.filletOperationId, {baseSolid}, result, *history, cancelled);
    response["afterElementNames"] = ProjectElementNames(book, result, evaluationEpoch, 1);
  }
  return response;
}

nlohmann::json BuildMergeCase(const MergeFixture& fixture, const std::uint32_t evaluationEpoch,
                              const bool includeElementNames, const std::atomic_bool& cancelled) {
  const TopoDS_Shape targetSolid =
      BuildBaseBox(fixture.targetWidth, fixture.targetDepth, fixture.targetHeight, cancelled);
  const TopoDS_Shape toolSolid =
      BuildBoxAt(fixture.originX, fixture.originY, fixture.originZ, fixture.toolWidth,
                 fixture.toolDepth, fixture.toolHeight, cancelled);

  // Before snapshot covers BOTH argument solids: unlike the planar-split
  // fixture's cutting-plane tool (which has no independent document
  // identity and is never described in the before snapshot), a merge fuses
  // two REAL bodies, so both need their own before-state topology and
  // provenance. A compound is the same device CombineBodies uses to gather
  // several unconsumed document bodies into one shape for STEP export.
  BRep_Builder compoundBuilder;
  TopoDS_Compound beforeCompound;
  compoundBuilder.MakeCompound(beforeCompound);
  compoundBuilder.Add(beforeCompound, targetSolid);
  compoundBuilder.Add(beforeCompound, toolSolid);

  EvaluatedBody beforeBody;
  beforeBody.bodyId = "mutation-before";
  beforeBody.operationId = fixture.targetOperationId;
  beforeBody.shape = beforeCompound;
  beforeBody.probes = ProbeShape(beforeCompound);
  if (!beforeBody.probes.valid)
    throw Standard_Failure("merge base solids are invalid");
  if (beforeBody.probes.solidCount != 2)
    throw Standard_Failure("merge fixture must start from exactly two argument solids");

  ShapeMap targetSubshapes;
  TopExp::MapShapes(targetSolid, targetSubshapes);
  ShapeMap toolSubshapes;
  TopExp::MapShapes(toolSolid, toolSubshapes);
  const ProvenanceResolver beforeProvenance = [&](const TopoDS_Shape& shape) {
    return targetSubshapes.Contains(shape) ? fixture.targetOperationId : fixture.toolOperationId;
  };
  nlohmann::json before =
      DescribeTopology(beforeBody, evaluationEpoch, 0, cancelled, beforeProvenance);

  // ONE General-Fuse evaluation of the two solids: BRepAlgoAPI_Fuse with
  // SetToFillHistory(true) produces a single BRepTools_History covering both
  // argument solids -- the SAME history class BRepAlgoAPI_Splitter produces
  // for planar-split -- which is fed unchanged to the shared OracleEntries()
  // below. No new oracle logic; only a new before/after construction.
  BRepAlgoAPI_Fuse fuse;
  NCollection_List<TopoDS_Shape> objects;
  NCollection_List<TopoDS_Shape> tools;
  // The optional argumentOrder knob flips ONLY which argument list each
  // solid enters the fuse through; the before compound, its enumeration,
  // provenance, and the oracle contract are unchanged. It exists so the
  // element-name channel's section names can be PROVEN commutative under an
  // argument-order flip against the real kernel.
  if (fixture.toolFirst) {
    objects.Append(toolSolid);
    tools.Append(targetSolid);
  } else {
    objects.Append(targetSolid);
    tools.Append(toolSolid);
  }
  fuse.SetArguments(objects);
  fuse.SetTools(tools);
  fuse.SetRunParallel(false);
  fuse.SetToFillHistory(true);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    fuse.Build(progress->Start());
  }
  CheckCancellation(cancelled);
  if (fuse.HasErrors())
    throw Standard_Failure("merge fuse failed");
  const TopoDS_Shape result = fuse.Shape();
  if (result.IsNull())
    throw Standard_Failure("merge fuse produced no result");
  // History() returns a reference-counted opencascade::handle<BRepTools_History>
  // that safely outlives the non-copyable algorithm object; retaining the handle
  // (not the fuse) is the supported lifetime contract, exactly as for the
  // planar-split splitter above.
  const occ::handle<BRepTools_History> history = fuse.History();
  if (history.IsNull())
    throw std::runtime_error("merge fuse did not record algorithm history");

  EvaluatedBody afterBody;
  afterBody.bodyId = "mutation-after";
  afterBody.operationId = fixture.mergeOperationId;
  afterBody.shape = result;
  afterBody.probes = ProbeShape(result);
  if (!afterBody.probes.valid)
    throw Standard_Failure("merge produced an invalid shape");
  if (afterBody.probes.solidCount != 1)
    throw Standard_Failure("merge did not fuse the two argument solids into one");

  // Preserved sub-shapes keep the provenance of the operation that created
  // them; every image the fuse minted (the piercing intersection curve's new
  // edges and vertices) carries the merge operation. Set-membership against
  // each argument shape, never geometric similarity -- identical technique to
  // every other fixture's provenance resolver.
  const ProvenanceResolver afterProvenance = [&](const TopoDS_Shape& shape) {
    if (targetSubshapes.Contains(shape))
      return fixture.targetOperationId;
    if (toolSubshapes.Contains(shape))
      return fixture.toolOperationId;
    return fixture.mergeOperationId;
  };
  nlohmann::json after =
      DescribeTopology(afterBody, evaluationEpoch, 1, cancelled, afterProvenance);

  nlohmann::json oracle = {
      {"entries", OracleEntries(*history, beforeCompound, result, evaluationEpoch, cancelled)}};
  nlohmann::json response = {
      {"type", "mutation_case"},
      {"epoch", evaluationEpoch},
      {"fixtureKind", "merge"},
      {"before", std::move(before)},
      {"after", std::move(after)},
      {"beforeProbes", ProbesToJson(beforeBody.probes)},
      {"afterProbes", ProbesToJson(afterBody.probes)},
      {"oracle", std::move(oracle)},
  };
  if (includeElementNames) {
    ElementNameBook book;
    book.AddPrimitive(fixture.targetOperationId, targetSolid);
    book.AddPrimitive(fixture.toolOperationId, toolSolid);
    response["beforeElementNames"] = ProjectElementNames(book, beforeCompound, evaluationEpoch, 0);
    // Inputs are threaded in fixture-declaration order REGARDLESS of the
    // argumentOrder knob: names must be a function of construction lineage,
    // never of the Boolean's argument-list sides.
    book.ApplyOperation(fixture.mergeOperationId, {targetSolid, toolSolid}, result, *history,
                        cancelled);
    response["afterElementNames"] = ProjectElementNames(book, result, evaluationEpoch, 1);
  }
  return response;
}

// ---------------------------------------------------------------------------
// STEP-interchange fixtures ("step-reimport", "step-import-cut").
//
// Both build the same all-planar pierced slab, serialize it to a private
// temporary STEP file, and read it back through the exact production reader
// (ImportStepShape) — the construction that produced the bytes never reaches
// the case, so the imported body enters with no history, which is the
// property the imported-step stratum exists to test. "step-reimport" reads
// the same bytes twice and derives a serialization-identity correspondence
// (declared-truth class, ADR-005 human review required); "step-import-cut"
// reads once and runs a real corner-notch BRepAlgoAPI_Cut, so its oracle is
// the ordinary single-run algorithm-history class.
// ---------------------------------------------------------------------------

/// The pierced slab: [0, width] x [0, depth] x [0, height] minus one
/// rectangular through-opening along Z. The cutting tool over-extends past
/// both Z faces so the boolean is a clean through-cut with no coplanar
/// tool/slab faces (the opening's clearances keep its four wall planes away
/// from every slab plane).
TopoDS_Shape BuildPiercedSlab(const StepReimportFixture& fixture,
                              const std::atomic_bool& cancelled) {
  const TopoDS_Shape slab = BuildBaseBox(fixture.width, fixture.depth, fixture.height, cancelled);
  const TopoDS_Shape tool =
      BuildBoxAt(fixture.openingOriginX, fixture.openingOriginY, -0.5 * fixture.height,
                 fixture.openingWidth, fixture.openingDepth, 2.0 * fixture.height, cancelled);
  BRepAlgoAPI_Cut cut;
  NCollection_List<TopoDS_Shape> objects;
  objects.Append(slab);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(tool);
  cut.SetArguments(objects);
  cut.SetTools(tools);
  cut.SetRunParallel(false);
  // The slab's own construction history is deliberately NOT recorded: the
  // solid exists only to be serialized, and the whole point of the fixtures
  // is that nothing about its construction survives the STEP boundary.
  cut.SetToFillHistory(false);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    cut.Build(progress->Start());
  }
  CheckCancellation(cancelled);
  if (cut.HasErrors() || cut.Shape().IsNull()) {
    throw Standard_Failure("pierced slab construction failed");
  }
  return cut.Shape();
}

/// Serializes one shape to a fresh private file under the system temp
/// directory and returns its path. The name embeds a per-process random tag
/// plus a process-global counter: several kernel hosts share one temp
/// directory (the tournament runner's worker pool), so uniqueness must not
/// depend on pid alone. ASCII-only, so the path round-trips every native
/// encoding.
std::filesystem::path WriteShapeToTempStep(const TopoDS_Shape& shape,
                                           const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  STEPControl_Writer writer;
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    if (writer.Transfer(shape, STEPControl_AsIs, true, progress->Start()) != IFSelect_RetDone) {
      throw std::runtime_error("STEP transfer failed for the interchange fixture");
    }
  }
  CheckCancellation(cancelled);
  static const std::uint64_t processTag = std::random_device{}();
  static std::atomic<std::uint64_t> counter{0};
  std::ostringstream name;
  name << "aeth-mutation-" << std::hex << processTag << "-" << std::dec
       << counter.fetch_add(1, std::memory_order_relaxed) << ".step";
  const std::filesystem::path path = std::filesystem::temp_directory_path() / name.str();
  std::ofstream output(path, std::ios::binary | std::ios::trunc);
  if (!output) {
    throw std::runtime_error("STEP temp output could not be opened");
  }
  if (writer.WriteStream(output) != IFSelect_RetDone) {
    output.close();
    std::error_code ignored;
    std::filesystem::remove(path, ignored);
    throw std::runtime_error("STEP temp write failed");
  }
  output.flush();
  output.close();
  return path;
}

/// Best-effort temp-file removal on every exit path. A leftover temp under
/// the OS temp directory is inert, so cleanup never throws.
struct TempFileGuard final {
  std::filesystem::path path;
  ~TempFileGuard() {
    std::error_code ignored;
    std::filesystem::remove(path, ignored);
  }
};

/// Verifies the serialization-identity premise of the "step-reimport" oracle:
/// two reads of the same bytes must yield per-kind snapshot entity sequences
/// that agree in count and, index by index, in geometry class and — within
/// serialization tolerance — in measure and centroid. Any disagreement fails
/// the request loudly: the oracle refuses to guess, exactly like the
/// construction-correspondence class's ambiguity failures. Tolerances are
/// generous against real decimal-text round-trip error (~1e-12 relative) and
/// tight against entity spacing (millimetre scale).
void AssertSerializationCongruence(const nlohmann::json& before, const nlohmann::json& after) {
  const auto& beforeEntities = before.at("entities");
  const auto& afterEntities = after.at("entities");
  if (beforeEntities.size() != afterEntities.size()) {
    throw std::runtime_error("re-imported shape changed its entity count across identical reads");
  }
  for (std::size_t index = 0; index < beforeEntities.size(); ++index) {
    const auto& lhs = beforeEntities.at(index);
    const auto& rhs = afterEntities.at(index);
    if (lhs.at("kind") != rhs.at("kind") || lhs.at("geometryClass") != rhs.at("geometryClass")) {
      throw std::runtime_error(
          "re-imported shape changed an entity's classification across identical reads");
    }
    const double lhsMeasure = lhs.at("measure").get<double>();
    const double rhsMeasure = rhs.at("measure").get<double>();
    if (std::abs(lhsMeasure - rhsMeasure) >
        std::max(1e-9, 1e-7 * std::max(std::abs(lhsMeasure), std::abs(rhsMeasure)))) {
      throw std::runtime_error(
          "re-imported shape changed an entity's measure across identical reads");
    }
    const auto& lhsCentroid = lhs.at("centroid");
    const auto& rhsCentroid = rhs.at("centroid");
    for (std::size_t axis = 0; axis < 3; ++axis) {
      if (std::abs(lhsCentroid.at(axis).get<double>() - rhsCentroid.at(axis).get<double>()) >
          1e-6) {
        throw std::runtime_error(
            "re-imported shape changed an entity's centroid across identical reads");
      }
    }
  }
}

nlohmann::json BuildStepReimportCase(const StepReimportFixture& fixture,
                                     const std::uint32_t evaluationEpoch,
                                     const bool includeElementNames,
                                     const std::atomic_bool& cancelled) {
  const TopoDS_Shape constructed = BuildPiercedSlab(fixture, cancelled);
  const TempFileGuard temp{WriteShapeToTempStep(constructed, cancelled)};
  const std::u8string pathUtf8 = temp.path.u8string();
  const std::string pathString(reinterpret_cast<const char*>(pathUtf8.data()), pathUtf8.size());

  // Two INDEPENDENT reads of the same bytes through the production reader.
  // Nothing of `constructed` (or its construction) reaches the case beyond
  // the serialized geometry itself.
  const TopoDS_Shape firstRead = ImportStepShape(pathString, cancelled);
  const TopoDS_Shape secondRead = ImportStepShape(pathString, cancelled);

  EvaluatedBody beforeBody;
  beforeBody.bodyId = "mutation-before";
  beforeBody.operationId = fixture.sourceOperationId;
  beforeBody.shape = firstRead;
  beforeBody.probes = ProbeShape(firstRead);
  if (!beforeBody.probes.valid || beforeBody.probes.solidCount != 1) {
    throw Standard_Failure("re-imported slab (first read) is not a single valid solid");
  }
  EvaluatedBody afterBody;
  afterBody.bodyId = "mutation-after";
  afterBody.operationId = fixture.sourceOperationId;
  afterBody.shape = secondRead;
  afterBody.probes = ProbeShape(secondRead);
  if (!afterBody.probes.valid || afterBody.probes.solidCount != 1) {
    throw Standard_Failure("re-imported slab (second read) is not a single valid solid");
  }

  // Every entity of an import carries the binding operation's provenance on
  // BOTH sides — an import has no per-feature history to attribute.
  nlohmann::json before = DescribeTopology(beforeBody, evaluationEpoch, 0, cancelled);
  nlohmann::json after = DescribeTopology(afterBody, evaluationEpoch, 1, cancelled);
  AssertSerializationCongruence(before, after);

  // With the premise verified, correspondence is equal per-kind enumeration
  // index — the same construction-role convention the pure re-evaluation
  // fixtures use, applied across a serialization boundary. Every entity is a
  // stable-single survivor; this class has no "gone", no sets, no generation.
  nlohmann::json entries = nlohmann::json::array();
  const std::array<TopAbs_ShapeEnum, 3> kinds{TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX};
  for (const TopAbs_ShapeEnum kind : kinds) {
    CheckCancellation(cancelled);
    const char code = KindCode(kind);
    ShapeMap beforeShapes;
    TopExp::MapShapes(firstRead, kind, beforeShapes);
    for (int index = 1; index <= beforeShapes.Extent(); ++index) {
      entries.push_back({
          {"beforeToken", TopologyEntityToken(evaluationEpoch, 0, code, index - 1)},
          {"fate", "stable-single"},
          {"afterTokens",
           nlohmann::json::array({TopologyEntityToken(evaluationEpoch, 1, code, index - 1)})},
      });
    }
  }

  nlohmann::json response = {
      {"type", "mutation_case"},
      {"epoch", evaluationEpoch},
      {"fixtureKind", "step-reimport"},
      {"before", std::move(before)},
      {"after", std::move(after)},
      {"beforeProbes", ProbesToJson(beforeBody.probes)},
      {"afterProbes", ProbesToJson(afterBody.probes)},
      {"oracle", nlohmann::json{{"entries", std::move(entries)}}},
  };
  if (includeElementNames) {
    // Each read is its own primitive rooted at the binding operation: birth
    // ordinals of a deterministic reader over identical bytes agree across
    // reads, so the two sides earn identical names — the lineage channel's
    // form of the same serialization-identity premise, verified by the
    // integration test rather than assumed here.
    ElementNameBook beforeBook;
    beforeBook.AddPrimitive(fixture.sourceOperationId, firstRead);
    response["beforeElementNames"] = ProjectElementNames(beforeBook, firstRead, evaluationEpoch, 0);
    ElementNameBook afterBook;
    afterBook.AddPrimitive(fixture.sourceOperationId, secondRead);
    response["afterElementNames"] = ProjectElementNames(afterBook, secondRead, evaluationEpoch, 1);
  }
  return response;
}

nlohmann::json BuildStepImportCutCase(const StepImportCutFixture& fixture,
                                      const std::uint32_t evaluationEpoch,
                                      const bool includeElementNames,
                                      const std::atomic_bool& cancelled) {
  StepReimportFixture slabFixture;
  slabFixture.width = fixture.width;
  slabFixture.depth = fixture.depth;
  slabFixture.height = fixture.height;
  slabFixture.openingOriginX = fixture.openingOriginX;
  slabFixture.openingOriginY = fixture.openingOriginY;
  slabFixture.openingWidth = fixture.openingWidth;
  slabFixture.openingDepth = fixture.openingDepth;
  slabFixture.sourceOperationId = fixture.sourceOperationId;
  const TopoDS_Shape constructed = BuildPiercedSlab(slabFixture, cancelled);
  const TempFileGuard temp{WriteShapeToTempStep(constructed, cancelled)};
  const std::u8string pathUtf8 = temp.path.u8string();
  const std::string pathString(reinterpret_cast<const char*>(pathUtf8.data()), pathUtf8.size());

  // ONE read: the notch is cut from the IMPORTED shape, so the recorded
  // history relates genuinely history-less imported entities to the cut
  // result — the ordinary single-run oracle class over an imported base.
  const TopoDS_Shape imported = ImportStepShape(pathString, cancelled);
  EvaluatedBody beforeBody;
  beforeBody.bodyId = "mutation-before";
  beforeBody.operationId = fixture.sourceOperationId;
  beforeBody.shape = imported;
  beforeBody.probes = ProbeShape(imported);
  if (!beforeBody.probes.valid || beforeBody.probes.solidCount != 1) {
    throw Standard_Failure("imported slab is not a single valid solid");
  }
  nlohmann::json before = DescribeTopology(beforeBody, evaluationEpoch, 0, cancelled);

  // Full-height corner notch at (x = width, y = 0): the tool over-extends
  // past x = width, y = 0, and both Z faces, so its only interior cut planes
  // are x = width - notchWidth and y = notchDepth — both structurally clear
  // of every pre-existing plane per the fixture domain.
  const TopoDS_Shape notchTool = BuildBoxAt(
      fixture.width - fixture.notchWidth, -0.5 * fixture.notchDepth, -0.5 * fixture.height,
      1.5 * fixture.notchWidth, 1.5 * fixture.notchDepth, 2.0 * fixture.height, cancelled);
  BRepAlgoAPI_Cut cut;
  BRepTools_History composedHistory;
  occ::handle<BRepTools_History> history;
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(notchTool);
  const TopoDS_Shape result = RunBooleanIntoHistory(cut, imported, tools, composedHistory,
                                                    "corner notch cut", cancelled, history);

  EvaluatedBody afterBody;
  afterBody.bodyId = "mutation-after";
  afterBody.operationId = fixture.cutOperationId;
  afterBody.shape = result;
  afterBody.probes = ProbeShape(result);
  if (!afterBody.probes.valid || afterBody.probes.solidCount != 1) {
    throw Standard_Failure("notched import is not a single valid solid");
  }
  // Structural deltas of a clean interior corner notch: +2 faces (the two
  // new notch walls), +6 edges (three new verticals, one new segment on each
  // of the top and bottom faces at each of the two cut planes minus the one
  // consumed corner vertical), +4 vertices (six new cut-plane corners minus
  // the two consumed). Any other delta means the cut interacted with
  // geometry the fixture domain promised it never would.
  if (afterBody.probes.faceCount != beforeBody.probes.faceCount + 2 ||
      afterBody.probes.edgeCount != beforeBody.probes.edgeCount + 6 ||
      afterBody.probes.vertexCount != beforeBody.probes.vertexCount + 4) {
    throw Standard_Failure("corner notch produced an unexpected topology delta");
  }

  // Preserved sub-shapes keep the import's provenance; every image the cut
  // minted carries the cut operation. Set membership against the imported
  // argument, never geometric similarity.
  ShapeMap importedSubshapes;
  TopExp::MapShapes(imported, importedSubshapes);
  const ProvenanceResolver provenance = [&](const TopoDS_Shape& shape) {
    return importedSubshapes.Contains(shape) ? fixture.sourceOperationId : fixture.cutOperationId;
  };
  nlohmann::json after = DescribeTopology(afterBody, evaluationEpoch, 1, cancelled, provenance);

  nlohmann::json oracle = {
      {"entries", OracleEntries(*history, imported, result, evaluationEpoch, cancelled)}};
  nlohmann::json response = {
      {"type", "mutation_case"},
      {"epoch", evaluationEpoch},
      {"fixtureKind", "step-import-cut"},
      {"before", std::move(before)},
      {"after", std::move(after)},
      {"beforeProbes", ProbesToJson(beforeBody.probes)},
      {"afterProbes", ProbesToJson(afterBody.probes)},
      {"oracle", std::move(oracle)},
  };
  if (includeElementNames) {
    ElementNameBook book;
    book.AddPrimitive(fixture.sourceOperationId, imported);
    response["beforeElementNames"] = ProjectElementNames(book, imported, evaluationEpoch, 0);
    // The notch tool has no document identity of its own (it is never in the
    // before snapshot), so its sub-shapes root at the mutating operation,
    // mirroring the provenance resolver above and the planar-split tool.
    book.AddPrimitive(fixture.cutOperationId, notchTool);
    book.ApplyOperation(fixture.cutOperationId, {imported, notchTool}, result, *history, cancelled);
    response["afterElementNames"] = ProjectElementNames(book, result, evaluationEpoch, 1);
  }
  return response;
}

// ---------------------------------------------------------------------------
// Construction-correspondence oracle (linear-pattern, boss-suppression).
//
// These fixtures compare two INDEPENDENT evaluations, so no single algorithm
// history relates BEFORE to AFTER. Each evaluation instead derives, from its
// own recorded history composed across operations, which result entities
// descend from which deterministic construction argument; correspondence
// across evaluations is by construction identity (equal owner, equal TopExp
// sub-shape index of the identical construction program), refined where
// needed by topological incidence. Never geometric similarity. This oracle
// class is semantically weaker than single-run history and requires human
// adversarial review per ADR-005 before any qualification use.
// ---------------------------------------------------------------------------

/// One algorithm application recorded for the element-name book: the exact
/// argument instances the algorithm consumed, its result, and its OWN
/// un-composed history handle. The state's composed `history` spans every
/// operation and therefore cannot attribute a name segment to a single
/// operation; per-step histories can.
struct RecordedNameOperation final {
  std::string operationId;
  std::vector<TopoDS_Shape> inputs;
  TopoDS_Shape result;
  occ::handle<BRepTools_History> history;
};

/// One independently evaluated document state: the final result, the
/// deterministic construction arguments that produced it (keyed by owner ids
/// that are stable across evaluations), and one BRepTools_History composed
/// over every operation in the state, relating argument sub-shapes to the
/// result. `namedPrimitives` and `recordedOperations` additionally record
/// the construction for the element-name book: primitives with the document
/// operation ids that created them (a pattern's instances gathered into ONE
/// compound so compound-wide birth ordinals stay prefix-stable under
/// cardinality edits), and each boolean step with its own history.
struct ConstructionState final {
  TopoDS_Shape result;
  std::vector<std::pair<std::string, TopoDS_Shape>> owners;
  BRepTools_History history;
  std::vector<std::pair<std::string, TopoDS_Shape>> namedPrimitives;
  std::vector<RecordedNameOperation> recordedOperations;
};

/// Replays a state's recorded construction into an element-name book. The
/// recorded shapes are the EXACT instances the algorithms consumed (never
/// copies), which is what keeps the history keyed to the book's names.
void FillStateNameBook(ElementNameBook& book, const ConstructionState& state,
                       const std::atomic_bool& cancelled) {
  for (const auto& [operationId, primitive] : state.namedPrimitives) {
    book.AddPrimitive(operationId, primitive);
  }
  for (const RecordedNameOperation& operation : state.recordedOperations) {
    book.ApplyOperation(operation.operationId, operation.inputs, operation.result,
                        *operation.history, cancelled);
  }
}

} // namespace

TopoDS_Shape BuildVerticalCylinder(const double centerX, const double centerY, const double baseZ,
                                   const double radius, const double height,
                                   const std::atomic_bool& cancelled) {
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepPrimAPI_MakeCylinder maker(gp_Ax2(gp_Pnt(centerX, centerY, baseZ), gp_Dir(0.0, 0.0, 1.0)),
                                 radius, height);
  maker.Build(progress->Start());
  CheckCancellation(cancelled);
  TopoDS_Solid solid = maker.Solid();
  BRepLib::OrientClosedSolid(solid);
  return solid;
}

/// Runs one General-Fuse-based boolean with history recording and merges the
/// recorded history into the state's composed history. BRepTools_History's
/// Merge (verified in the pinned source) composes modified-of-modified and
/// generated-through-modified relations, propagates removal, and directly
/// binds relations of shapes unknown to the earlier history (a later
/// operation's tool sub-shapes), which is exactly what a multi-operation
/// document state needs.
TopoDS_Shape RunBooleanIntoHistory(BRepAlgoAPI_BooleanOperation& operation,
                                   const TopoDS_Shape& object,
                                   const NCollection_List<TopoDS_Shape>& tools,
                                   BRepTools_History& history, const char* label,
                                   const std::atomic_bool& cancelled,
                                   occ::handle<BRepTools_History>& stepHistoryOut) {
  NCollection_List<TopoDS_Shape> objects;
  objects.Append(object);
  operation.SetArguments(objects);
  operation.SetTools(tools);
  operation.SetRunParallel(false);
  operation.SetToFillHistory(true);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    operation.Build(progress->Start());
  }
  CheckCancellation(cancelled);
  if (operation.HasErrors())
    throw Standard_Failure((std::string(label) + " failed").c_str());
  const TopoDS_Shape result = operation.Shape();
  if (result.IsNull())
    throw Standard_Failure((std::string(label) + " produced no result").c_str());
  const occ::handle<BRepTools_History> operationHistory = operation.History();
  if (operationHistory.IsNull())
    throw std::runtime_error(std::string(label) + " did not record algorithm history");
  history.Merge(operationHistory);
  // The step's own history outlives the algorithm through the same
  // reference-counted handle contract every single-run fixture relies on;
  // the element-name book needs it because the composed `history` cannot
  // attribute an image to one operation.
  stepHistoryOut = operationHistory;
  return result;
}

namespace {

ConstructionState EvaluateLinearPatternState(const LinearPatternFixture& fixture, const int count,
                                             const std::atomic_bool& cancelled) {
  ConstructionState state;
  const TopoDS_Shape base = BuildBaseBox(fixture.width, fixture.depth, fixture.height, cancelled);
  state.owners.emplace_back("base", base);
  NCollection_List<TopoDS_Shape> tools;
  // The array feature creates ALL instances as one operation, so the name
  // book registers them as ONE compound primitive: compound-wide MapShapes
  // ordinals keep instance sub-shapes distinct, and — because instances are
  // appended in instance order — the enumeration is prefix-stable, so a
  // cardinality edit leaves every surviving instance's birth ordinals (and
  // therefore names) unchanged across the two independent evaluations.
  BRep_Builder instanceCompoundBuilder;
  TopoDS_Compound instanceCompound;
  instanceCompoundBuilder.MakeCompound(instanceCompound);
  std::vector<TopoDS_Shape> fuseInputs;
  fuseInputs.push_back(base);
  for (int instance = 0; instance < count; ++instance) {
    const TopoDS_Shape boss =
        BuildVerticalCylinder(fixture.firstCenterX + instance * fixture.pitch, fixture.centerY,
                              fixture.height, fixture.bossRadius, fixture.bossHeight, cancelled);
    state.owners.emplace_back("instance-" + std::to_string(instance), boss);
    tools.Append(boss);
    instanceCompoundBuilder.Add(instanceCompound, boss);
    fuseInputs.push_back(boss);
  }
  // ONE General-Fuse evaluation per document state: a single
  // BRepAlgoAPI_Fuse run with every instance as a tool records one History()
  // covering the box and all instance arguments. Fusing instances one at a
  // time would require stitching independent histories back together —
  // exactly the re-identification this oracle is forbidden to do.
  BRepAlgoAPI_Fuse fuse;
  occ::handle<BRepTools_History> fuseHistory;
  state.result = RunBooleanIntoHistory(fuse, base, tools, state.history, "linear pattern fuse",
                                       cancelled, fuseHistory);
  state.namedPrimitives.emplace_back(fixture.baseOperationId, base);
  state.namedPrimitives.emplace_back(fixture.arrayOperationId, instanceCompound);
  state.recordedOperations.push_back(
      {fixture.arrayOperationId, std::move(fuseInputs), state.result, fuseHistory});
  return state;
}

struct BossSuppressionEvaluation final {
  ConstructionState state;
  /// The solid after the boss fuse and before the hole cut; null when the
  /// boss is omitted. Retained so provenance can attribute fuse-minted
  /// entities to the boss operation by set membership.
  TopoDS_Shape fusedIntermediate;
};

BossSuppressionEvaluation EvaluateBossSuppressionState(const BossSuppressionFixture& fixture,
                                                       const bool includeBoss,
                                                       const std::atomic_bool& cancelled) {
  BossSuppressionEvaluation evaluation;
  ConstructionState& state = evaluation.state;
  const TopoDS_Shape base = BuildBaseBox(fixture.width, fixture.depth, fixture.height, cancelled);
  state.owners.emplace_back("base", base);
  state.namedPrimitives.emplace_back(fixture.baseOperationId, base);
  TopoDS_Shape current = base;
  if (includeBoss) {
    const TopoDS_Shape boss =
        BuildVerticalCylinder(fixture.bossCenterX, fixture.bossCenterY, fixture.height,
                              fixture.bossRadius, fixture.bossHeight, cancelled);
    state.owners.emplace_back("boss", boss);
    state.namedPrimitives.emplace_back(fixture.bossOperationId, boss);
    NCollection_List<TopoDS_Shape> tools;
    tools.Append(boss);
    BRepAlgoAPI_Fuse fuse;
    occ::handle<BRepTools_History> fuseHistory;
    current = RunBooleanIntoHistory(fuse, current, tools, state.history, "boss fuse", cancelled,
                                    fuseHistory);
    state.recordedOperations.push_back(
        {fixture.bossOperationId, {base, boss}, current, fuseHistory});
    evaluation.fusedIntermediate = current;
  }
  // The hole tool construction is identical in both evaluations (it does not
  // depend on the boss), which is what makes hole-owned construction keys
  // comparable across them. It spans strictly beyond [0, height] so it
  // pierces the top and bottom faces; the footprint clearance rule keeps it
  // out of the boss.
  const double overshoot = fixture.height * 0.25;
  const TopoDS_Shape holeTool =
      BuildVerticalCylinder(fixture.holeCenterX, fixture.holeCenterY, -overshoot,
                            fixture.holeRadius, fixture.height + 2.0 * overshoot, cancelled);
  state.owners.emplace_back("hole", holeTool);
  state.namedPrimitives.emplace_back(fixture.holeOperationId, holeTool);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(holeTool);
  BRepAlgoAPI_Cut cut;
  // `current` is the exact intermediate the cut consumes (the fused solid
  // when the boss is present, the bare base otherwise); recording that same
  // instance keeps the name book's chain unbroken.
  const TopoDS_Shape cutInput = current;
  occ::handle<BRepTools_History> cutHistory;
  state.result =
      RunBooleanIntoHistory(cut, current, tools, state.history, "hole cut", cancelled, cutHistory);
  state.recordedOperations.push_back(
      {fixture.holeOperationId, {cutInput, holeTool}, state.result, cutHistory});
  return evaluation;
}

/// Per-evaluation lineage index: for every construction argument sub-shape
/// (keyed "owner|kind|index" with the deterministic TopExp order), the
/// same-kind images it left in the result (empty when removed) and the
/// images the history records as Generated from it. Built purely from the
/// composed history plus exact TShape set membership.
struct StateLineage final {
  AfterShapeIndex resultIndex;
  std::map<std::string, std::vector<TopoDS_Shape>> imagesByKey;
  std::map<std::string, std::vector<TopoDS_Shape>> generatedByKey;
  std::set<std::string> ownerIds;
  std::map<std::string, int> argumentExtents;

  StateLineage(const ConstructionState& state, const std::atomic_bool& cancelled)
      : resultIndex(state.result) {
    const std::array<TopAbs_ShapeEnum, 3> kinds{TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX};
    for (const auto& [ownerId, argument] : state.owners) {
      ownerIds.insert(ownerId);
      for (const TopAbs_ShapeEnum kind : kinds) {
        CheckCancellation(cancelled);
        const char code = KindCode(kind);
        ShapeMap argumentShapes;
        TopExp::MapShapes(argument, kind, argumentShapes);
        argumentExtents[ownerId + "|" + code] = argumentShapes.Extent();
        for (int index = 1; index <= argumentShapes.Extent(); ++index) {
          const TopoDS_Shape& shape = argumentShapes(index);
          const std::string key = ownerId + "|" + code + "|" + std::to_string(index - 1);
          std::vector<TopoDS_Shape> images;
          if (!state.history.IsRemoved(shape)) {
            const NCollection_List<TopoDS_Shape>& modified = state.history.Modified(shape);
            if (modified.IsEmpty()) {
              if (resultIndex.ForType(kind).FindIndex(shape) <= 0) {
                throw std::runtime_error(
                    "construction history reports a surviving entity absent from the result (" +
                    key + ")");
              }
              images.push_back(shape);
            } else {
              for (const TopoDS_Shape& image : modified) {
                if (image.ShapeType() != kind) {
                  throw std::runtime_error(
                      "construction history recorded a cross-kind Modified image (" + key + ")");
                }
                if (resultIndex.ForType(kind).FindIndex(image) <= 0) {
                  throw std::runtime_error(
                      "construction history reports a modified image absent from the result (" +
                      key + ")");
                }
                images.push_back(image);
              }
            }
          }
          imagesByKey[key] = std::move(images);
          std::vector<TopoDS_Shape> generated;
          for (const TopoDS_Shape& image : state.history.Generated(shape)) {
            if (resultIndex.ForType(image.ShapeType()).FindIndex(image) <= 0) {
              throw std::runtime_error(
                  "construction history reports a generated image absent from the result (" + key +
                  ")");
            }
            generated.push_back(image);
          }
          if (!generated.empty())
            generatedByKey[key] = std::move(generated);
        }
      }
    }
  }
};

std::string OwnerOfKey(const std::string& key) { return key.substr(0, key.find('|')); }

/// Construction parents of one BEFORE-result entity: the argument sub-shape
/// keys whose same-kind images contain it, and (separately) the keys whose
/// Generated images contain it. Same-kind descent is the primary
/// attribution; Generated attribution covers entities the algorithms minted
/// at feature intersections (a hole rim edge generated from the pierced face
/// and the tool face).
struct BeforeAttribution final {
  std::vector<std::string> sameKindParents;
  std::vector<std::string> generatedParents;
};

nlohmann::json ConstructionCorrespondenceEntries(const ConstructionState& beforeState,
                                                 const ConstructionState& afterState,
                                                 const std::uint32_t evaluationEpoch,
                                                 const std::atomic_bool& cancelled) {
  const StateLineage before(beforeState, cancelled);
  const StateLineage after(afterState, cancelled);

  // Construction congruence: owners shared by both evaluations must expose
  // identical per-kind argument sub-shape counts — the identical
  // deterministic construction program is what makes equal keys denote the
  // same constructed entity.
  for (const auto& [ownerAndKind, extent] : before.argumentExtents) {
    const std::string ownerId = OwnerOfKey(ownerAndKind);
    if (after.ownerIds.count(ownerId) == 0)
      continue;
    const auto found = after.argumentExtents.find(ownerAndKind);
    if (found == after.argumentExtents.end() || found->second != extent) {
      throw std::runtime_error(
          "construction congruence violated: shared owner argument sub-shape counts differ (" +
          ownerAndKind + ")");
    }
  }

  // Reverse attribution for every BEFORE-result entity.
  const std::array<TopAbs_ShapeEnum, 3> kinds{TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX};
  std::map<char, std::map<int, BeforeAttribution>> attributionByKind;
  const auto attribute = [&](const std::map<std::string, std::vector<TopoDS_Shape>>& byKey,
                             const bool sameKind) {
    for (const auto& [key, images] : byKey) {
      for (const TopoDS_Shape& image : images) {
        const char code = KindCode(image.ShapeType());
        const int index = before.resultIndex.ForType(image.ShapeType()).FindIndex(image);
        // Presence was asserted when the lineage was built.
        BeforeAttribution& attribution = attributionByKind[code][index];
        (sameKind ? attribution.sameKindParents : attribution.generatedParents).push_back(key);
      }
    }
  };
  attribute(before.imagesByKey, true);
  attribute(before.generatedByKey, false);

  // Correspondence, processed faces -> edges -> vertices so incidence
  // refinement of a lower-kind entity may consult the already-corresponded
  // images of the higher-kind entities containing it.
  nlohmann::json entries = nlohmann::json::array();
  std::map<char, std::map<int, TopoDS_Shape>> resolvedImages;
  ShapeMap usedAfterImages;
  for (std::size_t kindIndex = 0; kindIndex < kinds.size(); ++kindIndex) {
    const TopAbs_ShapeEnum kind = kinds.at(kindIndex);
    const char code = KindCode(kind);
    const ShapeMap& beforeShapes = before.resultIndex.ForType(kind);
    const ShapeMap& afterShapes = after.resultIndex.ForType(kind);
    for (int beforeIdx = 1; beforeIdx <= beforeShapes.Extent(); ++beforeIdx) {
      CheckCancellation(cancelled);
      const std::string beforeToken = TopologyEntityToken(evaluationEpoch, 0, code, beforeIdx - 1);
      const auto kindAttribution = attributionByKind.find(code);
      const BeforeAttribution* attribution = nullptr;
      if (kindAttribution != attributionByKind.end()) {
        const auto found = kindAttribution->second.find(beforeIdx);
        if (found != kindAttribution->second.end())
          attribution = &found->second;
      }
      if (attribution == nullptr ||
          (attribution->sameKindParents.empty() && attribution->generatedParents.empty())) {
        throw std::runtime_error(
            "construction correspondence cannot attribute a before entity to any construction "
            "argument (" +
            beforeToken + ")");
      }
      const bool generatedAttribution = attribution->sameKindParents.empty();
      const std::vector<std::string>& parents =
          generatedAttribution ? attribution->generatedParents : attribution->sameKindParents;

      nlohmann::json entry = {
          {"beforeToken", beforeToken},
          {"afterTokens", nlohmann::json::array()},
      };

      bool anyOwnerAbsent = false;
      for (const std::string& key : parents) {
        if (after.ownerIds.count(OwnerOfKey(key)) == 0) {
          anyOwnerAbsent = true;
          break;
        }
      }
      if (anyOwnerAbsent) {
        // The entity descends from a construction feature the other
        // evaluation does not contain; with disjoint footprints its trace is
        // gone with the feature.
        entry["fate"] = "gone";
        entries.push_back(std::move(entry));
        continue;
      }

      // Candidates: the intersection, over every construction parent, of the
      // corresponding after-evaluation image sets of the translated keys.
      const std::map<std::string, std::vector<TopoDS_Shape>>& afterLookup =
          generatedAttribution ? after.generatedByKey : after.imagesByKey;
      ShapeMap candidates;
      bool firstParent = true;
      for (const std::string& key : parents) {
        ShapeMap parentImages;
        const auto found = afterLookup.find(key);
        if (found != afterLookup.end()) {
          for (const TopoDS_Shape& image : found->second) {
            if (image.ShapeType() == kind)
              parentImages.Add(image);
          }
        }
        if (firstParent) {
          candidates = parentImages;
          firstParent = false;
        } else {
          ShapeMap intersection;
          for (int candidateIdx = 1; candidateIdx <= candidates.Extent(); ++candidateIdx) {
            if (parentImages.Contains(candidates(candidateIdx)))
              intersection.Add(candidates(candidateIdx));
          }
          candidates = intersection;
        }
      }
      if (candidates.IsEmpty()) {
        throw std::runtime_error(
            "construction correspondence found no after image although every construction "
            "parent survives (" +
            beforeToken + ")");
      }

      TopoDS_Shape resolved;
      if (candidates.Extent() == 1) {
        resolved = candidates(1);
      } else {
        // Incidence refinement: several after entities share the exact same
        // construction parents (e.g. the two seam-end vertices generated
        // from one tool seam edge). Keep the candidates contained in the
        // already-corresponded images of every higher-kind before entity
        // containing this one — exact TShape set membership, never geometric
        // similarity.
        std::vector<TopoDS_Shape> requiredContainers;
        for (std::size_t higherIndex = 0; higherIndex < kindIndex; ++higherIndex) {
          const TopAbs_ShapeEnum higherKind = kinds.at(higherIndex);
          const char higherCode = KindCode(higherKind);
          const ShapeMap& higherBefore = before.resultIndex.ForType(higherKind);
          const auto resolvedOfKind = resolvedImages.find(higherCode);
          if (resolvedOfKind == resolvedImages.end())
            continue;
          for (int higherIdx = 1; higherIdx <= higherBefore.Extent(); ++higherIdx) {
            ShapeMap containerSubshapes;
            TopExp::MapShapes(higherBefore(higherIdx), kind, containerSubshapes);
            if (!containerSubshapes.Contains(beforeShapes(beforeIdx)))
              continue;
            const auto resolvedHigher = resolvedOfKind->second.find(higherIdx);
            if (resolvedHigher == resolvedOfKind->second.end())
              continue; // gone containers constrain nothing
            requiredContainers.push_back(resolvedHigher->second);
          }
        }
        ShapeMap refined;
        for (int candidateIdx = 1; candidateIdx <= candidates.Extent(); ++candidateIdx) {
          const TopoDS_Shape& candidate = candidates(candidateIdx);
          bool containedInAll = true;
          for (const TopoDS_Shape& container : requiredContainers) {
            ShapeMap containerSubshapes;
            TopExp::MapShapes(container, kind, containerSubshapes);
            if (!containerSubshapes.Contains(candidate)) {
              containedInAll = false;
              break;
            }
          }
          if (containedInAll)
            refined.Add(candidate);
        }
        if (refined.Extent() != 1) {
          throw std::runtime_error(
              "construction correspondence stayed ambiguous after incidence refinement (" +
              beforeToken + ", " + std::to_string(refined.Extent()) + " of " +
              std::to_string(candidates.Extent()) + " candidates remain)");
        }
        resolved = refined(1);
      }

      const int afterIdx = afterShapes.FindIndex(resolved);
      if (afterIdx <= 0) {
        throw std::runtime_error(
            "construction correspondence resolved to a shape absent from the after result (" +
            beforeToken + ")");
      }
      if (usedAfterImages.Contains(resolved)) {
        throw std::runtime_error(
            "construction correspondence mapped two before entities onto one after entity (" +
            beforeToken + ")");
      }
      usedAfterImages.Add(resolved);
      resolvedImages[code][beforeIdx] = resolved;
      entry["fate"] = "stable-single";
      entry["afterTokens"].push_back(TopologyEntityToken(evaluationEpoch, 1, code, afterIdx - 1));
      entries.push_back(std::move(entry));
    }
  }
  return entries;
}

EvaluatedBody DescribeMutationBody(const TopoDS_Shape& shape, const char* bodyId,
                                   const std::string& operationId, const char* label) {
  EvaluatedBody body;
  body.bodyId = bodyId;
  body.operationId = operationId;
  body.shape = shape;
  body.probes = ProbeShape(shape);
  if (!body.probes.valid)
    throw Standard_Failure((std::string(label) + " is invalid").c_str());
  if (body.probes.solidCount != 1)
    throw Standard_Failure((std::string(label) + " is not a single solid").c_str());
  return body;
}

nlohmann::json BuildLinearPatternCase(const LinearPatternFixture& fixture,
                                      const std::uint32_t evaluationEpoch,
                                      const bool includeElementNames,
                                      const std::atomic_bool& cancelled) {
  const ConstructionState beforeState =
      EvaluateLinearPatternState(fixture, fixture.countBefore, cancelled);
  const ConstructionState afterState =
      EvaluateLinearPatternState(fixture, fixture.countAfter, cancelled);

  const EvaluatedBody beforeBody =
      DescribeMutationBody(beforeState.result, "mutation-before", fixture.arrayOperationId,
                           "linear pattern before state");
  const EvaluatedBody afterBody = DescribeMutationBody(
      afterState.result, "mutation-after", fixture.arrayOperationId, "linear pattern after state");

  // Preserved base sub-shapes keep the base operation's provenance; every
  // instance sub-shape and every image the fuse minted carries the array
  // feature's operation, which is the SAME operation in both evaluations — a
  // count edit re-evaluates the feature, it does not create a new one. Set
  // membership against the base argument, never geometric similarity.
  ShapeMap beforeBoxSubshapes;
  TopExp::MapShapes(beforeState.owners.front().second, beforeBoxSubshapes);
  const ProvenanceResolver beforeProvenance = [&](const TopoDS_Shape& shape) {
    return beforeBoxSubshapes.Contains(shape) ? fixture.baseOperationId : fixture.arrayOperationId;
  };
  nlohmann::json before =
      DescribeTopology(beforeBody, evaluationEpoch, 0, cancelled, beforeProvenance);
  ShapeMap afterBoxSubshapes;
  TopExp::MapShapes(afterState.owners.front().second, afterBoxSubshapes);
  const ProvenanceResolver afterProvenance = [&](const TopoDS_Shape& shape) {
    return afterBoxSubshapes.Contains(shape) ? fixture.baseOperationId : fixture.arrayOperationId;
  };
  nlohmann::json after =
      DescribeTopology(afterBody, evaluationEpoch, 1, cancelled, afterProvenance);

  nlohmann::json oracle = {{"entries", ConstructionCorrespondenceEntries(
                                           beforeState, afterState, evaluationEpoch, cancelled)}};
  nlohmann::json response = {
      {"type", "mutation_case"},
      {"epoch", evaluationEpoch},
      {"fixtureKind", "linear-pattern"},
      {"before", std::move(before)},
      {"after", std::move(after)},
      {"beforeProbes", ProbesToJson(beforeBody.probes)},
      {"afterProbes", ProbesToJson(afterBody.probes)},
      {"oracle", std::move(oracle)},
  };
  if (includeElementNames) {
    // Two INDEPENDENT books, one per evaluation: no history spans the two
    // states, so correspondence is exactly what the name strings carry
    // (Case B, research 02 §5) — equal construction lineage must earn the
    // identical string in both books.
    ElementNameBook beforeBook;
    FillStateNameBook(beforeBook, beforeState, cancelled);
    response["beforeElementNames"] =
        ProjectElementNames(beforeBook, beforeState.result, evaluationEpoch, 0);
    ElementNameBook afterBook;
    FillStateNameBook(afterBook, afterState, cancelled);
    response["afterElementNames"] =
        ProjectElementNames(afterBook, afterState.result, evaluationEpoch, 1);
  }
  return response;
}

nlohmann::json BuildBossSuppressionCase(const BossSuppressionFixture& fixture,
                                        const std::uint32_t evaluationEpoch,
                                        const bool includeElementNames,
                                        const std::atomic_bool& cancelled) {
  const BossSuppressionEvaluation beforeEvaluation =
      EvaluateBossSuppressionState(fixture, true, cancelled);
  const BossSuppressionEvaluation afterEvaluation =
      EvaluateBossSuppressionState(fixture, false, cancelled);
  const ConstructionState& beforeState = beforeEvaluation.state;
  const ConstructionState& afterState = afterEvaluation.state;

  const EvaluatedBody beforeBody =
      DescribeMutationBody(beforeState.result, "mutation-before", fixture.holeOperationId,
                           "boss suppression before state");
  const EvaluatedBody afterBody = DescribeMutationBody(
      afterState.result, "mutation-after", fixture.holeOperationId, "boss suppression after state");

  // Provenance follows creation order by set membership: base-argument
  // sub-shapes belong to the base operation; anything else already present
  // after the boss fuse (boss survivors and fuse-minted images) belongs to
  // the boss operation; everything minted by the hole cut belongs to the
  // hole operation. Operation ids are shared across the two evaluations —
  // suppressing a feature does not re-identify the others.
  ShapeMap beforeBoxSubshapes;
  TopExp::MapShapes(beforeState.owners.front().second, beforeBoxSubshapes);
  ShapeMap fusedSubshapes;
  TopExp::MapShapes(beforeEvaluation.fusedIntermediate, fusedSubshapes);
  const ProvenanceResolver beforeProvenance = [&](const TopoDS_Shape& shape) {
    if (beforeBoxSubshapes.Contains(shape))
      return fixture.baseOperationId;
    if (fusedSubshapes.Contains(shape))
      return fixture.bossOperationId;
    return fixture.holeOperationId;
  };
  nlohmann::json before =
      DescribeTopology(beforeBody, evaluationEpoch, 0, cancelled, beforeProvenance);
  ShapeMap afterBoxSubshapes;
  TopExp::MapShapes(afterState.owners.front().second, afterBoxSubshapes);
  const ProvenanceResolver afterProvenance = [&](const TopoDS_Shape& shape) {
    return afterBoxSubshapes.Contains(shape) ? fixture.baseOperationId : fixture.holeOperationId;
  };
  nlohmann::json after =
      DescribeTopology(afterBody, evaluationEpoch, 1, cancelled, afterProvenance);

  nlohmann::json oracle = {{"entries", ConstructionCorrespondenceEntries(
                                           beforeState, afterState, evaluationEpoch, cancelled)}};
  nlohmann::json response = {
      {"type", "mutation_case"},
      {"epoch", evaluationEpoch},
      {"fixtureKind", "boss-suppression"},
      {"before", std::move(before)},
      {"after", std::move(after)},
      {"beforeProbes", ProbesToJson(beforeBody.probes)},
      {"afterProbes", ProbesToJson(afterBody.probes)},
      {"oracle", std::move(oracle)},
  };
  if (includeElementNames) {
    // Two independent books (Case B). A suppression removes an operation
    // from the middle of a lineage chain, which is exactly the case the
    // name normalization congruence (element_names.hpp) exists for.
    ElementNameBook beforeBook;
    FillStateNameBook(beforeBook, beforeState, cancelled);
    response["beforeElementNames"] =
        ProjectElementNames(beforeBook, beforeState.result, evaluationEpoch, 0);
    ElementNameBook afterBook;
    FillStateNameBook(afterBook, afterState, cancelled);
    response["afterElementNames"] =
        ProjectElementNames(afterBook, afterState.result, evaluationEpoch, 1);
  }
  return response;
}

} // namespace

nlohmann::json BuildMutationCase(const nlohmann::json& request, const std::uint32_t evaluationEpoch,
                                 const std::atomic_bool& cancelled) {
  const std::string kind = request.at("fixture").at("kind").get<std::string>();
  // Additive element-name channel (NG-2 Phase A): absent flag means the
  // response is byte-identical to the pre-flag protocol.
  const bool includeElementNames = request.value("includeElementNames", false);
  if (kind == "planar-split") {
    return BuildPlanarSplitCase(ParsePlanarSplitFixture(request), evaluationEpoch,
                                includeElementNames, cancelled);
  }
  if (kind == "fillet") {
    return BuildFilletCase(ParseFilletFixture(request), evaluationEpoch, includeElementNames,
                           cancelled);
  }
  if (kind == "linear-pattern") {
    return BuildLinearPatternCase(ParseLinearPatternFixture(request), evaluationEpoch,
                                  includeElementNames, cancelled);
  }
  if (kind == "boss-suppression") {
    return BuildBossSuppressionCase(ParseBossSuppressionFixture(request), evaluationEpoch,
                                    includeElementNames, cancelled);
  }
  if (kind == "merge") {
    return BuildMergeCase(ParseMergeFixture(request), evaluationEpoch, includeElementNames,
                          cancelled);
  }
  if (kind == "step-reimport") {
    return BuildStepReimportCase(ParseStepReimportFixture(request), evaluationEpoch,
                                 includeElementNames, cancelled);
  }
  if (kind == "step-import-cut") {
    return BuildStepImportCutCase(ParseStepImportCutFixture(request), evaluationEpoch,
                                  includeElementNames, cancelled);
  }
  throw std::invalid_argument("unsupported mutation fixture kind: " + kind);
}

} // namespace aeth
