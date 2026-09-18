#include "naming_registry.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <compare>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include <BRepAdaptor_Curve.hxx>
#include <BRepAdaptor_Surface.hxx>
#include <BRepGProp.hxx>
#include <BRepTools_History.hxx>
#include <BRep_Tool.hxx>
#include <GProp_GProps.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <TopAbs_Orientation.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Pnt.hxx>
#include <gp_Vec.hxx>

#include "cancel.hpp"

namespace aeth {
namespace {

std::uint64_t StableSemanticOrdinal(const std::string& value) {
  std::uint64_t hash = 14695981039346656037ull;
  for (const unsigned char byte : value) {
    hash ^= byte;
    hash *= 1099511628211ull;
  }
  return hash;
}

using ShapeMap = NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher>;
using ParentMap = NCollection_DataMap<TopoDS_Shape, std::vector<int>, TopTools_ShapeMapHasher>;

constexpr std::array<TopAbs_ShapeEnum, 3> kNamedKinds{TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX};

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

char KindCodeOf(const TopAbs_ShapeEnum type) {
  switch (type) {
  case TopAbs_FACE:
    return 'f';
  case TopAbs_EDGE:
    return 'e';
  case TopAbs_VERTEX:
    return 'v';
  default:
    throw std::runtime_error("naming registry covers faces, edges, and vertices only");
  }
}

/// The §6.4 canonical geometric key, demoted by ADR-006 to a tie-break used
/// only where the lineage grammar REQUIRES twins to collide. Ordered exactly
/// as the plan lists its components: quantized centroid, quantized measure,
/// surface/curve class rank, then the minimal-ancestor provenance key.
struct GeometricKey final {
  long long x{};
  long long y{};
  long long z{};
  long long measure{};
  int classRank{};
  std::string provenance;

  friend auto operator<=>(const GeometricKey&, const GeometricKey&) = default;
};

/// §6.4 quantization: banker's rounding on value/quantum + 1e-9. std::llrint
/// honours the ambient rounding mode, which this codebase pins to the default
/// round-to-nearest-even (SSE2 math, /fp:precise — 06 §4.6).
long long Quantize(const double value, const double quantum) {
  return std::llrint(value / quantum + 1e-9);
}

int SurfaceClassRank(const TopoDS_Face& face) {
  switch (BRepAdaptor_Surface(face, true).GetType()) {
  case GeomAbs_Plane:
    return 0;
  case GeomAbs_Cylinder:
    return 1;
  case GeomAbs_Cone:
    return 2;
  case GeomAbs_Sphere:
    return 3;
  case GeomAbs_Torus:
    return 4;
  default:
    return 5;
  }
}

int CurveClassRank(const TopoDS_Edge& edge) {
  // OCCT represents the two pole closures of a sphere as real, zero-length
  // edges with no 3D curve. They remain part of the host's topology census and
  // therefore need names; constructing BRepAdaptor_Curve for one throws.
  if (BRep_Tool::Degenerated(edge))
    return 4;
  switch (BRepAdaptor_Curve(edge).GetType()) {
  case GeomAbs_Line:
    return 0;
  case GeomAbs_Circle:
    return 1;
  case GeomAbs_Ellipse:
    return 2;
  default:
    return 3;
  }
}

constexpr double kBoundaryLinearTolerance = 1.0e-6;
constexpr double kBoundaryAngularCosine = 0.9998476951563913; // cos(1 degree)

bool PointOnBoundary(const gp_Pnt& point, const NamingRegistry::BirthBoundary& boundary) {
  return std::abs(gp_Vec(boundary.anchor, point).Dot(gp_Vec(boundary.normal))) <=
         kBoundaryLinearTolerance;
}

bool FaceOnBoundary(const TopoDS_Face& face, const NamingRegistry::BirthBoundary& boundary) {
  const BRepAdaptor_Surface surface(face, true);
  if (surface.GetType() != GeomAbs_Plane)
    return false;
  if (std::abs(surface.Plane().Axis().Direction().Dot(boundary.normal)) < kBoundaryAngularCosine)
    return false;
  GProp_GProps properties;
  BRepGProp::SurfaceProperties(face, properties);
  return PointOnBoundary(properties.CentreOfMass(), boundary);
}

bool EdgeOnBoundary(const TopoDS_Edge& edge, const NamingRegistry::BirthBoundary& boundary) {
  ShapeMap vertices;
  TopExp::MapShapes(edge, TopAbs_VERTEX, vertices);
  if (vertices.IsEmpty()) {
    GProp_GProps properties;
    BRepGProp::LinearProperties(edge, properties);
    return PointOnBoundary(properties.CentreOfMass(), boundary);
  }
  for (int index = 1; index <= vertices.Extent(); ++index) {
    if (!PointOnBoundary(BRep_Tool::Pnt(TopoDS::Vertex(vertices(index))), boundary))
      return false;
  }
  return true;
}

bool IsFeatureBirth(const NamingRegistry::BirthClass operationClass) {
  switch (operationClass) {
  case NamingRegistry::BirthClass::Extrude:
  case NamingRegistry::BirthClass::Revolve:
  case NamingRegistry::BirthClass::Loft:
  case NamingRegistry::BirthClass::Sweep:
    return true;
  case NamingRegistry::BirthClass::Cylinder:
  case NamingRegistry::BirthClass::Sphere:
  case NamingRegistry::BirthClass::Cone:
  case NamingRegistry::BirthClass::Torus:
  case NamingRegistry::BirthClass::Wedge:
    return false;
  }
  throw std::runtime_error("naming registry received an unknown birth operation class");
}

GeometricKey GeometryKeyOf(const TopoDS_Shape& shape, std::string provenance) {
  constexpr double kCentroidQuantum = 1e-3; // §6.4: q = 1e-3 mm
  constexpr double kMeasureQuantum = 1e-6;  // §6.4: m = 1e-6
  GeometricKey key;
  key.provenance = std::move(provenance);
  gp_Pnt centroid(0.0, 0.0, 0.0);
  double measure = 0.0;
  switch (shape.ShapeType()) {
  case TopAbs_FACE: {
    GProp_GProps properties;
    BRepGProp::SurfaceProperties(shape, properties);
    measure = std::abs(properties.Mass());
    centroid = properties.CentreOfMass();
    key.classRank = SurfaceClassRank(TopoDS::Face(shape));
    break;
  }
  case TopAbs_EDGE: {
    GProp_GProps properties;
    BRepGProp::LinearProperties(shape, properties);
    measure = std::abs(properties.Mass());
    centroid = properties.CentreOfMass();
    // A degenerate (zero-length) edge has no well-defined mass centroid;
    // anchor the key on its first vertex so no NaN ever reaches quantization.
    if (!(measure > 0.0)) {
      TopoDS_Vertex first;
      TopoDS_Vertex last;
      TopExp::Vertices(TopoDS::Edge(shape), first, last);
      centroid = first.IsNull() ? gp_Pnt(0.0, 0.0, 0.0) : BRep_Tool::Pnt(first);
      measure = 0.0;
    }
    key.classRank = CurveClassRank(TopoDS::Edge(shape));
    break;
  }
  case TopAbs_VERTEX:
    centroid = BRep_Tool::Pnt(TopoDS::Vertex(shape));
    break;
  default:
    throw std::runtime_error("naming registry covers faces, edges, and vertices only");
  }
  key.x = Quantize(centroid.X(), kCentroidQuantum);
  key.y = Quantize(centroid.Y(), kCentroidQuantum);
  key.z = Quantize(centroid.Z(), kCentroidQuantum);
  key.measure = Quantize(measure, kMeasureQuantum);
  return key;
}

int KindRankOf(const char kind) {
  switch (kind) {
  case 'f':
    return 0;
  case 'e':
    return 1;
  case 'v':
    return 2;
  default:
    throw std::runtime_error("naming registry covers faces, edges, and vertices only");
  }
}

/// A fresh quantized-geometry ROOT (no history segment at all) minted for an
/// entity this harvest could not attribute means the naming pass itself had
/// nothing but position to offer — the fail-closed line for the registry.
bool IsBareQuantizedRoot(const std::string& name) {
  return name.starts_with("n1:Q.") && name.find('/') == std::string::npos;
}

// -----------------------------------------------------------------------------
// Minimal role tables (integration tranche N3). Reserved cross-op roles
// `modified` / `generated` per plan 05 §6.1; op tables per catalogs 02–04.
// -----------------------------------------------------------------------------

using OperationClass = NamingRegistry::OperationClass;

std::string RoleForModified(const OperationClass operationClass, const bool tool, const char kind) {
  switch (operationClass) {
  case OperationClass::Boolean:
    if (!tool)
      return "modified";
    return kind == 'f' ? "tool-face" : kind == 'e' ? "tool-edge" : "generated";
  case OperationClass::Hole:
  case OperationClass::Shell:
    // Shell mirrors Hole (catalog wave 1): the synthetic offset solid takes
    // the tool route, so its surviving faces carry the doc-04 `wall` role —
    // the cavity surface when inward, the new outer skin when outward.
    if (!tool)
      return "modified";
    return kind == 'f' ? "wall" : "generated";
  case OperationClass::Mirror:
    // merge:true fuse (catalog wave 2): the source is the real operand — its
    // untouched faces identity-survive as `modified` — and the mirrored copy is
    // the synthetic operand, so its surviving/split images carry the doc-04
    // `mirrored*` roles.
    if (!tool)
      return "modified";
    return kind == 'f' ? "mirrored" : kind == 'e' ? "mirrored-edge" : "mirrored-vertex";
  case OperationClass::Pattern:
    // The optional real `target` (union/subtract) survives as `modified`; every
    // instance is synthetic, so its images carry the doc-04 `instance-*` roles.
    if (!tool)
      return "modified";
    return kind == 'f' ? "instance-face" : kind == 'e' ? "instance-edge" : "instance-vertex";
  case OperationClass::Offset:
    // doc-04 offset table. The MOVED face descends from the swept prism — the
    // synthetic tool — while every re-trimmed neighbour descends from the
    // target. So the tool flag is exactly the "is this the moved face?"
    // discriminator, and without this branch the moved face silently reads as
    // just another `modified` neighbour and the table's `offset` row is dead.
    return tool && kind == 'f' ? "offset" : "modified";
  case OperationClass::Fillet:
  case OperationClass::Chamfer:
  case OperationClass::Transform:
    return "modified";
  case OperationClass::EdgeFlange:
    // The synthetic new-material solid (flange panel + bend infill) is the
    // tool operand, hole/offset-style; its surviving flat faces are the
    // sheet's new panel. The target's own untouched faces identity-survive
    // as `modified` regardless of kind.
    if (!tool)
      return "modified";
    return kind == 'f' ? "panel" : "generated";
  case OperationClass::BaseFlange:
    // Never constructed: base_flange is a root birth (HarvestBirth), see the
    // enum's doc comment. A real case is still required so this switch stays
    // exhaustive under -Wswitch.
    throw std::runtime_error(
        "naming registry: base_flange harvests through HarvestBirth, never HarvestOperation");
  case OperationClass::Unfold:
    // Never constructed on this path either: unfold's flat-pattern harvest is
    // a plain per-panel/per-strip mint (HarvestCopiedBody-shaped), not a
    // Modified/Generated boolean history — see sheet_metal_feature.cpp.
    throw std::runtime_error(
        "naming registry: unfold harvests its flat pattern directly, never HarvestOperation");
  case OperationClass::SurfaceOffset:
    // Never constructed: the exact same whole-shape PerformByJoin call
    // Offset's own v1 path already declines to name — see the enum's doc
    // comment and surfacing_feature.cpp.
    throw std::runtime_error("naming registry: surface_offset does not record element names yet");
  case OperationClass::Stitch:
    // Never constructed: BRepBuilderAPI_Sewing has no BRepBuilderAPI_MakeShape
    // -shaped Modified/Generated/IsDeleted surface to adapt — see the enum's
    // doc comment and surfacing_feature.cpp.
    throw std::runtime_error(
        "naming registry: stitch harvests its result directly, never HarvestOperation");
  case OperationClass::BoundarySurface:
    // Never constructed: the target is a READ-ONLY reference, never a
    // consumed operand — see the enum's doc comment and surfacing_feature.cpp.
    throw std::runtime_error(
        "naming registry: boundary_surface harvests its result directly, never HarvestOperation");
  case OperationClass::Thicken:
    // Never constructed: MEASURED (surfacing_feature.cpp's own comment on
    // EvaluateThicken has the full account) — a single, UNCOMPOSED
    // MakeThickSolidBySimple call on a bare planar rectangle, as simple a
    // case as exists, still throws inside ElementNameBook::ApplyOperation
    // ("cannot attribute a result entity ... bare quantized-geometry root").
    // Unlike EdgeFlange's composition-depth issue, this is
    // MakeThickSolidBySimple's OWN Modified()/Generated() surface being too
    // thin even uncomposed (its own doc comment already flags skipping
    // intersection computation entirely, the likely cause). `thicken` mints
    // its result fresh (AddDerivedPrimitive) for all three direction modes
    // instead.
    throw std::runtime_error(
        "naming registry: thicken harvests its result directly, never HarvestOperation");
  case OperationClass::WireRoute:
    // Never constructed: MEASURED (electrical_routing_feature.cpp's own
    // comment on EvaluateWireRoute has the full account) — wire_route
    // consumes NO existing body's topology at all (its spine and profile
    // are built fresh from resolved point coordinates), so there is no
    // NamingRegistry::Input for HarvestOperation to attribute images
    // against in the first place. `wire_route` mints its result fresh
    // (AddDerivedPrimitive) instead.
    throw std::runtime_error(
        "naming registry: wire_route harvests its result directly, never HarvestOperation");
  case OperationClass::MoldPartingLine:
    throw std::runtime_error(
        "naming registry: mold_parting_line harvests its result directly, never HarvestOperation");
  case OperationClass::MoldShutoffSurface:
    throw std::runtime_error(
        "naming registry: mold_shutoff_surface harvests its result directly, never "
        "HarvestOperation");
  case OperationClass::MoldPartingSurface:
    throw std::runtime_error(
        "naming registry: mold_parting_surface harvests its result directly, never "
        "HarvestOperation");
  case OperationClass::MoldToolingSplit:
    throw std::runtime_error(
        "naming registry: mold_tooling_split harvests its result directly, never HarvestOperation");
  }
  throw std::runtime_error("naming registry received an unknown operation class");
}

std::string RoleForGenerated(const OperationClass operationClass, const bool tool,
                             const char kind) {
  switch (operationClass) {
  case OperationClass::Boolean:
    if (tool)
      return kind == 'f' ? "tool-face" : kind == 'e' ? "tool-edge" : "generated";
    return "generated";
  case OperationClass::Hole:
  case OperationClass::Shell:
    if (tool)
      return kind == 'f' ? "wall" : "generated";
    return "generated";
  case OperationClass::Mirror:
  case OperationClass::Pattern:
    // A single-source Generated image under the fuse is not the operand's own
    // face (that is Modified) — it is a new entity: route it to the reserved
    // `generated` role, the doc-04 mirror/pattern classifyByOpSemantics fallback.
    (void)tool;
    return "generated";
  case OperationClass::Fillet:
    return kind == 'f' ? "fillet" : "generated";
  case OperationClass::Chamfer:
    // doc-04 chamfer table: a bevel face generated from ONE provenance input
    // edge is `chamfer`; a generated edge is `chamfer-edge`.
    return kind == 'f' ? "chamfer" : kind == 'e' ? "chamfer-edge" : "generated";
  case OperationClass::Offset:
    // doc-04 offset table: the MOVED target face is `offset`. Its two-row table
    // has no generated-edge row — the re-trim reuses the neighbours' own
    // surfaces, so new edges are ordinary boundary curves.
    return kind == 'f' ? "offset" : "generated";
  case OperationClass::EdgeFlange:
    // A face generated from ONE provenance edge (target's or the synthetic
    // tool's) is the paired-fillet bend surface — the inner or outer
    // cylindrical patch. Generated edges/vertices fall to the reserved
    // role, sharing Fillet/Chamfer's honest face-only-history limit.
    (void)tool;
    return kind == 'f' ? "bend" : "generated";
  case OperationClass::Transform:
    throw std::runtime_error(
        "naming registry found a Generated image under transform; its history must be "
        "Modified-only");
  case OperationClass::BaseFlange:
    throw std::runtime_error(
        "naming registry: base_flange harvests through HarvestBirth, never HarvestOperation");
  case OperationClass::Unfold:
    throw std::runtime_error(
        "naming registry: unfold harvests its flat pattern directly, never HarvestOperation");
  case OperationClass::SurfaceOffset:
    throw std::runtime_error("naming registry: surface_offset does not record element names yet");
  case OperationClass::Stitch:
    throw std::runtime_error(
        "naming registry: stitch harvests its result directly, never HarvestOperation");
  case OperationClass::BoundarySurface:
    throw std::runtime_error(
        "naming registry: boundary_surface harvests its result directly, never HarvestOperation");
  case OperationClass::Thicken:
    throw std::runtime_error(
        "naming registry: thicken harvests its result directly, never HarvestOperation");
  case OperationClass::WireRoute:
    throw std::runtime_error(
        "naming registry: wire_route harvests its result directly, never HarvestOperation");
  case OperationClass::MoldPartingLine:
    throw std::runtime_error(
        "naming registry: mold_parting_line harvests its result directly, never HarvestOperation");
  case OperationClass::MoldShutoffSurface:
    throw std::runtime_error(
        "naming registry: mold_shutoff_surface harvests its result directly, never "
        "HarvestOperation");
  case OperationClass::MoldPartingSurface:
    throw std::runtime_error(
        "naming registry: mold_parting_surface harvests its result directly, never "
        "HarvestOperation");
  case OperationClass::MoldToolingSplit:
    throw std::runtime_error(
        "naming registry: mold_tooling_split harvests its result directly, never HarvestOperation");
  }
  throw std::runtime_error("naming registry received an unknown operation class");
}

/// Entities Generated from SEVERAL sources — the boolean section family.
std::string RoleForSection(const OperationClass operationClass, const char kind) {
  switch (operationClass) {
  case OperationClass::Boolean:
  case OperationClass::Hole:
  case OperationClass::Shell:
  case OperationClass::Mirror:
  case OperationClass::Pattern:
    // Mirror/pattern join curves are `seam` (doc-04), new join faces `generated`.
    return kind == 'e' ? "seam" : "generated";
  case OperationClass::Fillet:
    return kind == 'f' ? "fillet" : "generated";
  case OperationClass::Chamfer:
    // A face generated from SEVERAL input edges is the corner patch where
    // chamfers meet — doc-04's `chamfer-corner` row, which is exactly the
    // multi-source case this classifier handles.
    return kind == 'f' ? "chamfer-corner" : kind == 'e' ? "chamfer-edge" : "generated";
  case OperationClass::Offset:
    // Multi-source is reachable here when the moved face's image merges with a
    // neighbour extension during unify. doc-04's table has exactly two roles,
    // so the merged face is still the `offset` face — inventing a third role
    // for it would be a name the history cannot justify (ADR-015).
    return kind == 'f' ? "offset" : "generated";
  case OperationClass::EdgeFlange:
    // The common case in practice: the crease edge the paired fillets round
    // traces back through the fuse to BOTH the target's original boundary
    // edge and the synthetic tool's own swept edge, so the bend face they
    // generate is multi-source. Same `bend` / `generated` split as the
    // single-source case above — the section/generated distinction is a
    // provenance-count detail the sheet-metal role table does not surface.
    return kind == 'f' ? "bend" : "generated";
  case OperationClass::Transform:
    throw std::runtime_error(
        "naming registry found a Generated image under transform; its history must be "
        "Modified-only");
  case OperationClass::BaseFlange:
    throw std::runtime_error(
        "naming registry: base_flange harvests through HarvestBirth, never HarvestOperation");
  case OperationClass::Unfold:
    throw std::runtime_error(
        "naming registry: unfold harvests its flat pattern directly, never HarvestOperation");
  case OperationClass::SurfaceOffset:
    throw std::runtime_error("naming registry: surface_offset does not record element names yet");
  case OperationClass::Stitch:
    throw std::runtime_error(
        "naming registry: stitch harvests its result directly, never HarvestOperation");
  case OperationClass::BoundarySurface:
    throw std::runtime_error(
        "naming registry: boundary_surface harvests its result directly, never HarvestOperation");
  case OperationClass::Thicken:
    throw std::runtime_error(
        "naming registry: thicken harvests its result directly, never HarvestOperation");
  case OperationClass::WireRoute:
    throw std::runtime_error(
        "naming registry: wire_route harvests its result directly, never HarvestOperation");
  case OperationClass::MoldPartingLine:
    throw std::runtime_error(
        "naming registry: mold_parting_line harvests its result directly, never HarvestOperation");
  case OperationClass::MoldShutoffSurface:
    throw std::runtime_error(
        "naming registry: mold_shutoff_surface harvests its result directly, never "
        "HarvestOperation");
  case OperationClass::MoldPartingSurface:
    throw std::runtime_error(
        "naming registry: mold_parting_surface harvests its result directly, never "
        "HarvestOperation");
  case OperationClass::MoldToolingSplit:
    throw std::runtime_error(
        "naming registry: mold_tooling_split harvests its result directly, never HarvestOperation");
  }
  throw std::runtime_error("naming registry received an unknown operation class");
}

/// The catalog step-8 classifier fallback for entities the retained history
/// does not attribute (fillet blend boundaries — its history is face-only).
std::string RoleForUnattributed(const OperationClass operationClass, const char kind) {
  (void)kind;
  switch (operationClass) {
  case OperationClass::Boolean:
  case OperationClass::Hole:
  case OperationClass::Fillet:
  case OperationClass::Chamfer:
  case OperationClass::Offset:
  case OperationClass::Shell:
  case OperationClass::Mirror:
  case OperationClass::Pattern:
  case OperationClass::EdgeFlange:
    return "generated";
  case OperationClass::BaseFlange:
    throw std::runtime_error(
        "naming registry: base_flange harvests through HarvestBirth, never HarvestOperation");
  case OperationClass::Unfold:
    throw std::runtime_error(
        "naming registry: unfold harvests its flat pattern directly, never HarvestOperation");
  case OperationClass::SurfaceOffset:
    throw std::runtime_error("naming registry: surface_offset does not record element names yet");
  case OperationClass::Stitch:
    throw std::runtime_error(
        "naming registry: stitch harvests its result directly, never HarvestOperation");
  case OperationClass::Thicken:
    throw std::runtime_error(
        "naming registry: thicken harvests its result directly, never HarvestOperation");
  case OperationClass::WireRoute:
    throw std::runtime_error(
        "naming registry: wire_route harvests its result directly, never HarvestOperation");
  case OperationClass::MoldPartingLine:
    throw std::runtime_error(
        "naming registry: mold_parting_line harvests its result directly, never HarvestOperation");
  case OperationClass::MoldShutoffSurface:
    throw std::runtime_error(
        "naming registry: mold_shutoff_surface harvests its result directly, never "
        "HarvestOperation");
  case OperationClass::MoldPartingSurface:
    throw std::runtime_error(
        "naming registry: mold_parting_surface harvests its result directly, never "
        "HarvestOperation");
  case OperationClass::MoldToolingSplit:
    throw std::runtime_error(
        "naming registry: mold_tooling_split harvests its result directly, never HarvestOperation");
  case OperationClass::BoundarySurface:
    throw std::runtime_error(
        "naming registry: boundary_surface harvests its result directly, never HarvestOperation");
  case OperationClass::Transform:
    throw std::runtime_error(
        "naming registry found an unattributed entity under transform; its 1:1 Modified "
        "history is incoherent");
  }
  throw std::runtime_error("naming registry received an unknown operation class");
}

} // namespace

/// One planned mint: everything the bucket sort and record append need,
/// captured BEFORE any index mutation so ancestry reads pre-operation state.
struct NamingRegistry::MintPlan final {
  TopoDS_Shape shape;
  /// Non-null when this mint is the 1:1 Modified continuation of a source
  /// entity: the source's answering tokens re-point here (§6.3 step 12).
  TopoDS_Shape aliasSource;
  char kind{};
  int kindRank{};
  std::string lineageName;
  std::string normalizedName;
  std::vector<std::string> ancestors;
  GeometricKey geometry;
  // Construction entities need an eid-derived public token. A contiguous
  // position would silently retarget when an earlier line is added/moved.
  std::optional<std::uint64_t> stableOrdinal;
};

const NamingRecord& NamingRegistry::RecordAt(const std::size_t index) const {
  if (index >= records_.size())
    throw std::runtime_error("naming registry record index out of range");
  return records_[index];
}

const NamingRecord* NamingRegistry::FindByToken(const std::string& token) const {
  const auto found = byToken_.find(token);
  return found == byToken_.end() ? nullptr : &records_[found->second];
}

std::vector<const NamingRecord*>
NamingRegistry::LiveByNormalizedName(const char kind, const std::string& normalizedName) const {
  std::vector<const NamingRecord*> live;
  const auto found = byNormalizedName_.find({kind, normalizedName});
  if (found == byNormalizedName_.end())
    return live;
  for (const std::size_t index : found->second) {
    if (records_[index].live)
      live.push_back(&records_[index]);
  }
  return live;
}

std::vector<std::string> NamingRegistry::TokensOf(const TopoDS_Shape& shape) const {
  std::vector<std::string> tokens;
  const std::vector<std::size_t>* answering = shapeIndex_.Seek(shape);
  if (answering == nullptr)
    return tokens;
  for (const std::size_t index : *answering) {
    if (records_[index].live)
      tokens.push_back(records_[index].token);
  }
  return tokens;
}

// The replay seam copies every member by value: the vector/maps deep-copy, the
// composed book snapshots itself, and NCollection_DataMap duplicates its
// (shape-handle, indices) entries. The snapshot is therefore an independent,
// reusable value that still shares TShape identity with the shapes harvested
// into the live registry — the property a tail replay's byte-identical record
// harvest depends on.
NamingRegistry::Snapshot NamingRegistry::TakeSnapshot() const {
  return Snapshot{book_.TakeSnapshot(), records_, byToken_, byNormalizedName_, shapeIndex_};
}

void NamingRegistry::RestoreFrom(const Snapshot& snapshot) {
  book_.RestoreFrom(snapshot.book);
  records_ = snapshot.records;
  byToken_ = snapshot.byToken;
  byNormalizedName_ = snapshot.byNormalizedName;
  shapeIndex_ = snapshot.shapeIndex;
}

void NamingRegistry::MintBuckets(const std::string& operationId,
                                 std::map<std::string, std::vector<MintPlan>>& buckets,
                                 const std::atomic_bool& cancelled, const int outputIndex) {
  // ADR-013 decision 2: enumeration is per-(operation, output body). Index 0
  // mints the LEGACY token bytes so every single-output operation — which is
  // every operation but a multi-solid import — names its entities exactly as it
  // always did, and every reference persisted before fan-out keeps resolving.
  const std::string tokenScope =
      outputIndex == 0 ? operationId : operationId + ":" + std::to_string(outputIndex);
  for (auto& [role, plans] : buckets) {
    CheckCancellation(cancelled);
    // §6.4 as amended: primary key is the normalized lineage name (within
    // kind), tie-break is the geometric canonical key. Plans arrive in
    // per-kind TopExp::MapShapes order, so a stable sort makes traversal
    // order the documented last-resort fallback (D_ORDER_TIE below).
    std::stable_sort(plans.begin(), plans.end(), [](const MintPlan& a, const MintPlan& b) {
      if (a.kindRank != b.kindRank)
        return a.kindRank < b.kindRank;
      if (a.normalizedName != b.normalizedName)
        return a.normalizedName < b.normalizedName;
      return a.geometry < b.geometry;
    });
    const auto namesCollide = [&plans](const std::size_t left, const std::size_t right) {
      return plans[left].kindRank == plans[right].kindRank &&
             plans[left].normalizedName == plans[right].normalizedName;
    };
    const auto keysTie = [&plans, &namesCollide](const std::size_t left, const std::size_t right) {
      return namesCollide(left, right) && plans[left].geometry == plans[right].geometry;
    };
    for (std::size_t ordinal = 0; ordinal < plans.size(); ++ordinal) {
      MintPlan& plan = plans[ordinal];
      NamingRecord record;
      const std::uint64_t tokenOrdinal =
          plan.stableOrdinal.has_value() ? *plan.stableOrdinal : ordinal;
      record.token = "t:" + tokenScope + "/" + role + "/" + std::to_string(tokenOrdinal);
      record.shape = plan.shape;
      record.minter = operationId;
      record.role = role;
      record.kind = plan.kind;
      record.lineageName = std::move(plan.lineageName);
      record.normalizedLineageName = plan.normalizedName;
      record.ancestors = std::move(plan.ancestors);
      record.live = true;
      // Grammar-required twins: identical (kind, normalized name) neighbours
      // in the sorted bucket. Their ordinals are presentation order only —
      // the flag is what keeps a resolver from ever trusting that order.
      record.nameCollision = (ordinal > 0 && namesCollide(ordinal - 1, ordinal)) ||
                             (ordinal + 1 < plans.size() && namesCollide(ordinal, ordinal + 1));
      // D_ORDER_TIE: the geometric key also tied, so only traversal order
      // separated the twins. Surfaced, never silent (§6.4).
      record.orderTie = (ordinal > 0 && keysTie(ordinal - 1, ordinal)) ||
                        (ordinal + 1 < plans.size() && keysTie(ordinal, ordinal + 1));

      const std::size_t recordIndex = records_.size();
      if (!byToken_.emplace(record.token, recordIndex).second) {
        throw std::runtime_error("naming registry minted one token twice: " + record.token);
      }
      byNormalizedName_[{record.kind, record.normalizedLineageName}].push_back(recordIndex);

      if (!plan.aliasSource.IsNull()) {
        // §6.3 step 12: the 1:1 Modified survivor keeps its old token(s) as
        // aliases — every record answering for the source re-points to the
        // image, then the new token joins the chain (cap 8, oldest dropped).
        const std::vector<std::size_t>* sourceAnswering = shapeIndex_.Seek(plan.aliasSource);
        if (sourceAnswering == nullptr) {
          throw std::runtime_error(
              "naming registry lost the answering records of an aliased source");
        }
        std::vector<std::size_t> answering = *sourceAnswering;
        shapeIndex_.UnBind(plan.aliasSource);
        for (const std::size_t aliasIndex : answering)
          records_[aliasIndex].shape = plan.shape;
        answering.push_back(recordIndex);
        while (answering.size() > 8) {
          records_[answering.front()].live = false;
          answering.erase(answering.begin());
        }
        if (shapeIndex_.Seek(plan.shape) != nullptr) {
          throw std::runtime_error(
              "naming registry found a Modified image that already answers to other records");
        }
        shapeIndex_.Bind(plan.shape, std::move(answering));
      } else if (std::vector<std::size_t>* existing = shapeIndex_.ChangeSeek(plan.shape)) {
        existing->push_back(recordIndex);
      } else {
        shapeIndex_.Bind(plan.shape, std::vector<std::size_t>{recordIndex});
      }
      records_.push_back(std::move(record));
    }
  }
}

void NamingRegistry::HarvestBoxBirth(const std::string& operationId, const TopoDS_Shape& shape,
                                     const gp_Dir& placementZ, const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  std::array<ShapeMap, 3> ofKind;
  for (std::size_t kindIndex = 0; kindIndex < kNamedKinds.size(); ++kindIndex)
    TopExp::MapShapes(shape, kNamedKinds[kindIndex], ofKind[kindIndex]);
  if (ofKind[0].Extent() != 6 || ofKind[1].Extent() != 12 || ofKind[2].Extent() != 8) {
    throw std::runtime_error(
        "naming registry expected a 6-face/12-edge/8-vertex solid from create_box");
  }

  // Catalog 02 face classification bands: outward normal against the
  // placement z direction within ±1 degree. Anything outside all three bands
  // is a contract violation, never a guess.
  constexpr double kCosOneDegree = 0.9998476951563913;
  constexpr double kSinOneDegree = 0.01745240643728351;
  std::map<std::string, std::vector<MintPlan>> buckets;
  const auto plan = [this](const TopoDS_Shape& entity) {
    MintPlan minted;
    minted.shape = entity;
    minted.kind = KindCodeOf(entity.ShapeType());
    minted.kindRank = KindRankOf(minted.kind);
    minted.lineageName = book_.NameOf(entity);
    minted.normalizedName = NormalizeElementName(minted.lineageName);
    minted.geometry = GeometryKeyOf(entity, "");
    return minted;
  };
  int bottomCount = 0;
  int topCount = 0;
  for (int index = 1; index <= ofKind[0].Extent(); ++index) {
    const TopoDS_Face face = TopoDS::Face(ofKind[0](index));
    const BRepAdaptor_Surface surface(face, true);
    if (surface.GetType() != GeomAbs_Plane)
      throw std::runtime_error("naming registry expected only planar faces on a box");
    gp_Dir normal = surface.Plane().Axis().Direction();
    if (face.Orientation() == TopAbs_REVERSED)
      normal.Reverse();
    const double alignment = normal.Dot(placementZ);
    std::string role = "side";
    if (alignment <= -kCosOneDegree) {
      role = "bottom";
      bottomCount += 1;
    } else if (alignment >= kCosOneDegree) {
      role = "top";
      topCount += 1;
    }
    buckets[role].push_back(plan(face));
  }
  if (bottomCount != 1 || topCount != 1) {
    throw std::runtime_error(
        "naming registry could not classify the box's bottom/top faces against its placement");
  }
  // Catalog 02 box edge roles are semantic and placement-relative. Determine
  // the two horizontal levels from projected centroids so rotated/transformed
  // placements classify identically without relying on world Z.
  struct HorizontalEdge final {
    TopoDS_Edge edge;
    double elevation{};
  };
  std::vector<HorizontalEdge> horizontalEdges;
  int verticalEdgeCount = 0;
  for (int index = 1; index <= ofKind[1].Extent(); ++index) {
    const TopoDS_Edge edge = TopoDS::Edge(ofKind[1](index));
    const BRepAdaptor_Curve curve(edge);
    if (curve.GetType() != GeomAbs_Line)
      throw std::runtime_error("naming registry expected only straight edges on a box");
    const double alignment = std::abs(curve.Line().Direction().Dot(placementZ));
    if (alignment >= kCosOneDegree) {
      buckets["vertical-edge"].push_back(plan(edge));
      verticalEdgeCount += 1;
      continue;
    }
    if (alignment > kSinOneDegree)
      throw std::runtime_error(
          "naming registry found a box edge outside horizontal/vertical classification bands");
    GProp_GProps properties;
    BRepGProp::LinearProperties(edge, properties);
    const gp_Pnt centroid = properties.CentreOfMass();
    horizontalEdges.push_back(
        {edge, gp_Vec(gp_Pnt(0.0, 0.0, 0.0), centroid).Dot(gp_Vec(placementZ))});
  }
  if (horizontalEdges.size() != 8 || verticalEdgeCount != 4)
    throw std::runtime_error("naming registry expected 8 horizontal and 4 vertical edges on a box");
  const auto [minimum, maximum] =
      std::minmax_element(horizontalEdges.begin(), horizontalEdges.end(),
                          [](const HorizontalEdge& lhs, const HorizontalEdge& rhs) {
                            return lhs.elevation < rhs.elevation;
                          });
  const double middle = (minimum->elevation + maximum->elevation) * 0.5;
  int bottomEdgeCount = 0;
  int topEdgeCount = 0;
  for (const HorizontalEdge& horizontal : horizontalEdges) {
    if (horizontal.elevation < middle) {
      buckets["bottom-edge"].push_back(plan(horizontal.edge));
      bottomEdgeCount += 1;
    } else {
      buckets["top-edge"].push_back(plan(horizontal.edge));
      topEdgeCount += 1;
    }
  }
  if (bottomEdgeCount != 4 || topEdgeCount != 4)
    throw std::runtime_error("naming registry expected 4 bottom and 4 top edges on a box");
  for (int index = 1; index <= ofKind[2].Extent(); ++index)
    buckets["vertex"].push_back(plan(ofKind[2](index)));
  MintBuckets(operationId, buckets, cancelled);
}

void NamingRegistry::HarvestBirth(const std::string& operationId, const TopoDS_Shape& shape,
                                  const BirthSpec& spec, const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  std::array<ShapeMap, 3> ofKind;
  for (std::size_t kindIndex = 0; kindIndex < kNamedKinds.size(); ++kindIndex)
    TopExp::MapShapes(shape, kNamedKinds[kindIndex], ofKind[kindIndex]);
  if (ofKind[0].IsEmpty() || ofKind[1].IsEmpty() || ofKind[2].IsEmpty()) {
    throw std::runtime_error(
        "naming registry requires a body birth with faces, edges, and vertices");
  }

  std::map<std::string, std::vector<MintPlan>> buckets;
  const auto plan = [this](const TopoDS_Shape& entity) {
    MintPlan minted;
    minted.shape = entity;
    minted.kind = KindCodeOf(entity.ShapeType());
    minted.kindRank = KindRankOf(minted.kind);
    minted.lineageName = book_.NameOf(entity);
    minted.normalizedName = NormalizeElementName(minted.lineageName);
    minted.geometry = GeometryKeyOf(entity, "");
    return minted;
  };

  enum class BoundarySide { None, Start, End };
  const auto closestBoundary = [&spec](const gp_Pnt& centroid, const bool onStart,
                                       const bool onEnd) {
    if (onStart && !onEnd)
      return BoundarySide::Start;
    if (onEnd && !onStart)
      return BoundarySide::End;
    if (!onStart && !onEnd)
      return BoundarySide::None;
    if (!spec.start.has_value() || !spec.end.has_value())
      throw std::runtime_error("naming registry lost a matched birth boundary");
    const double startDistance = centroid.Distance(spec.start->anchor);
    const double endDistance = centroid.Distance(spec.end->anchor);
    if (std::abs(startDistance - endDistance) <= kBoundaryLinearTolerance) {
      throw std::runtime_error(
          "naming registry cannot distinguish coincident birth boundaries; refusing a role guess");
    }
    return startDistance < endDistance ? BoundarySide::Start : BoundarySide::End;
  };
  const auto faceBoundary = [&spec, &closestBoundary](const TopoDS_Face& face) {
    const bool onStart =
        spec.start.has_value() && spec.start->faceExpected && FaceOnBoundary(face, *spec.start);
    const bool onEnd =
        spec.end.has_value() && spec.end->faceExpected && FaceOnBoundary(face, *spec.end);
    GProp_GProps properties;
    BRepGProp::SurfaceProperties(face, properties);
    return closestBoundary(properties.CentreOfMass(), onStart, onEnd);
  };
  const auto edgeBoundary = [&spec, &closestBoundary](const TopoDS_Edge& edge) {
    const bool onStart = spec.start.has_value() && EdgeOnBoundary(edge, *spec.start);
    const bool onEnd = spec.end.has_value() && EdgeOnBoundary(edge, *spec.end);
    GProp_GProps properties;
    BRepGProp::LinearProperties(edge, properties);
    gp_Pnt centroid = properties.CentreOfMass();
    if (BRep_Tool::Degenerated(edge)) {
      TopoDS_Vertex first;
      TopoDS_Vertex last;
      TopExp::Vertices(edge, first, last);
      if (!first.IsNull())
        centroid = BRep_Tool::Pnt(first);
    }
    return closestBoundary(centroid, onStart, onEnd);
  };

  for (int index = 1; index <= ofKind[0].Extent(); ++index) {
    CheckCancellation(cancelled);
    const TopoDS_Face face = TopoDS::Face(ofKind[0](index));
    const BoundarySide boundary = faceBoundary(face);
    std::string role;
    if (boundary != BoundarySide::None) {
      if (IsFeatureBirth(spec.operationClass))
        role = boundary == BoundarySide::Start ? "cap-start" : "cap-end";
      else
        role = boundary == BoundarySide::Start ? "bottom" : "top";
    } else {
      const GeomAbs_SurfaceType surface = BRepAdaptor_Surface(face, true).GetType();
      switch (spec.operationClass) {
      case BirthClass::Cylinder:
        if (surface != GeomAbs_Cylinder)
          throw std::runtime_error("naming registry found a non-cylindrical cylinder wall face");
        role = "wall";
        break;
      case BirthClass::Sphere:
        if (surface != GeomAbs_Sphere)
          throw std::runtime_error("naming registry found a non-spherical sphere wall face");
        role = "wall";
        break;
      case BirthClass::Cone:
        if (surface != GeomAbs_Cone)
          throw std::runtime_error("naming registry found a non-conical cone wall face");
        role = "wall";
        break;
      case BirthClass::Torus:
        if (surface != GeomAbs_Torus)
          throw std::runtime_error("naming registry found a non-toroidal torus wall face");
        role = "wall";
        break;
      case BirthClass::Wedge:
        if (surface != GeomAbs_Plane)
          throw std::runtime_error("naming registry found a non-planar wedge face");
        role = "side";
        break;
      case BirthClass::Extrude:
      case BirthClass::Revolve:
      case BirthClass::Loft:
      case BirthClass::Sweep:
        role = "side";
        break;
      }
    }
    buckets[role].push_back(plan(face));
  }

  for (int index = 1; index <= ofKind[1].Extent(); ++index) {
    CheckCancellation(cancelled);
    const TopoDS_Edge edge = TopoDS::Edge(ofKind[1](index));
    std::string role;
    switch (spec.operationClass) {
    case BirthClass::Cylinder:
    case BirthClass::Cone: {
      const BoundarySide boundary = edgeBoundary(edge);
      if (boundary == BoundarySide::Start) {
        role = "bottom-edge";
      } else if (boundary == BoundarySide::End) {
        role = spec.end.has_value() && spec.end->faceExpected ? "top-edge" : "apex-edge";
      } else {
        role = "seam";
      }
      break;
    }
    case BirthClass::Sphere:
      role = BRep_Tool::Degenerated(edge) ? "pole-edge" : "seam";
      break;
    case BirthClass::Torus:
      role = "seam";
      break;
    case BirthClass::Wedge: {
      const BoundarySide boundary = edgeBoundary(edge);
      role = boundary == BoundarySide::Start ? "bottom-edge"
             : boundary == BoundarySide::End ? "top-edge"
                                             : "side-edge";
      break;
    }
    case BirthClass::Extrude:
    case BirthClass::Revolve:
    case BirthClass::Loft:
    case BirthClass::Sweep:
      role = "side-edge";
      break;
    }
    buckets[role].push_back(plan(edge));
  }

  for (int index = 1; index <= ofKind[2].Extent(); ++index) {
    CheckCancellation(cancelled);
    const TopoDS_Vertex vertex = TopoDS::Vertex(ofKind[2](index));
    std::string role = "vertex";
    if (spec.operationClass == BirthClass::Cone && spec.end.has_value() &&
        !spec.end->faceExpected && PointOnBoundary(BRep_Tool::Pnt(vertex), *spec.end)) {
      role = "apex-vertex";
    }
    buckets[role].push_back(plan(vertex));
  }

  const auto count = [&buckets](const std::string& role, const char kind) {
    const auto found = buckets.find(role);
    if (found == buckets.end())
      return std::size_t{0};
    return static_cast<std::size_t>(
        std::count_if(found->second.begin(), found->second.end(),
                      [kind](const MintPlan& minted) { return minted.kind == kind; }));
  };
  const auto requireCount = [&count](const std::string& role, const char kind,
                                     const std::size_t expected) {
    const std::size_t actual = count(role, kind);
    if (actual != expected) {
      throw std::runtime_error("naming registry birth role '" + role + "' expected " +
                               std::to_string(expected) + " entities of kind " + kind + ", got " +
                               std::to_string(actual));
    }
  };
  const auto requirePositive = [&count](const std::string& role, const char kind) {
    if (count(role, kind) == 0) {
      throw std::runtime_error("naming registry birth role '" + role +
                               "' unexpectedly has no entities");
    }
  };

  // Profile features may legitimately birth several disjoint solids at once
  // (one per disjoint sketch region). Cap-role counts scale with that; a
  // shape with no explicit solids still counts as one body.
  ShapeMap solids;
  TopExp::MapShapes(shape, TopAbs_SOLID, solids);
  const std::size_t solidCount =
      solids.Extent() > 0 ? static_cast<std::size_t>(solids.Extent()) : std::size_t{1};

  switch (spec.operationClass) {
  case BirthClass::Cylinder:
    requireCount("bottom", 'f', 1);
    requireCount("top", 'f', 1);
    requireCount("wall", 'f', 1);
    requireCount("bottom-edge", 'e', 1);
    requireCount("top-edge", 'e', 1);
    requireCount("seam", 'e', 1);
    break;
  case BirthClass::Sphere:
    requireCount("wall", 'f', 1);
    requireCount("seam", 'e', 1);
    requireCount("pole-edge", 'e', 2);
    requireCount("vertex", 'v', 2);
    break;
  case BirthClass::Cone:
    requireCount("bottom", 'f', 1);
    requireCount("top", 'f', spec.end.has_value() && spec.end->faceExpected ? 1 : 0);
    requireCount("wall", 'f', 1);
    requirePositive("seam", 'e');
    break;
  case BirthClass::Torus:
    requireCount("wall", 'f', 1);
    requireCount("seam", 'e', 2);
    requireCount("vertex", 'v', 1);
    break;
  case BirthClass::Wedge:
    requireCount("bottom", 'f', 1);
    requireCount("top", 'f', spec.end.has_value() && spec.end->faceExpected ? 1 : 0);
    requirePositive("side", 'f');
    break;
  case BirthClass::Extrude:
  case BirthClass::Loft:
  case BirthClass::Sweep:
    // One start cap and one end cap PER DISJOINT SOLID. A sketch with
    // several disjoint material regions is valid input (EvaluateSketchRegion
    // compounds them deliberately), and extruding it produces one solid per
    // region — each with its own pair of caps. Hardcoding 1 here rejected
    // every multi-region profile feature outright. The count still has to be
    // exact: a missing or extra cap on any solid is a real naming defect.
    requireCount("cap-start", 'f', solidCount);
    requireCount("cap-end", 'f', solidCount);
    requirePositive("side", 'f');
    break;
  case BirthClass::Revolve:
    requireCount("cap-start", 'f', spec.start.has_value() ? solidCount : 0);
    requireCount("cap-end", 'f', spec.end.has_value() ? solidCount : 0);
    requirePositive("side", 'f');
    break;
  }

  MintBuckets(operationId, buckets, cancelled);
}

void NamingRegistry::HarvestSyntheticTool(const std::string& operationId, const TopoDS_Shape& tool,
                                          const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  std::map<std::string, std::vector<MintPlan>> buckets;
  for (const TopAbs_ShapeEnum kind : kNamedKinds) {
    ShapeMap shapes;
    TopExp::MapShapes(tool, kind, shapes);
    for (int index = 1; index <= shapes.Extent(); ++index) {
      const TopoDS_Shape& entity = shapes(index);
      MintPlan minted;
      minted.shape = entity;
      minted.kind = KindCodeOf(entity.ShapeType());
      minted.kindRank = KindRankOf(minted.kind);
      minted.lineageName = book_.NameOf(entity);
      minted.normalizedName = NormalizeElementName(minted.lineageName);
      minted.geometry = GeometryKeyOf(entity, "");
      buckets["tool"].push_back(std::move(minted));
    }
  }
  MintBuckets(operationId, buckets, cancelled);
}

void NamingRegistry::HarvestCopiedBody(
    const std::string& operationId, const TopoDS_Shape& body, const std::string& faceRole,
    const std::string& edgeRole, const std::string& vertexRole,
    const NCollection_DataMap<TopoDS_Shape, TopoDS_Shape, TopTools_ShapeMapHasher>& copyToSource,
    const std::atomic_bool& cancelled, const int outputIndex) {
  CheckCancellation(cancelled);
  // The newest token currently answering for a source shape — the canonical
  // ancestor handle (the same rule HarvestOperation records on descendants).
  const auto newestTokenOf = [this](const TopoDS_Shape& source) -> std::string {
    const std::vector<std::size_t>* answering = shapeIndex_.Seek(source);
    if (answering == nullptr || answering->empty()) {
      throw std::runtime_error(
          "naming registry cannot attribute a copied body sub-shape: its source holds no record");
    }
    return records_[answering->back()].token;
  };
  std::map<std::string, std::vector<MintPlan>> buckets;
  for (const TopAbs_ShapeEnum kind : kNamedKinds) {
    CheckCancellation(cancelled);
    ShapeMap shapes;
    TopExp::MapShapes(body, kind, shapes);
    for (int index = 1; index <= shapes.Extent(); ++index) {
      const TopoDS_Shape& entity = shapes(index);
      const char code = KindCodeOf(entity.ShapeType());
      MintPlan minted;
      minted.shape = entity;
      minted.kind = code;
      minted.kindRank = KindRankOf(code);
      minted.lineageName = book_.NameOf(entity);
      minted.normalizedName = NormalizeElementName(minted.lineageName);
      const std::string& role = code == 'f' ? faceRole : code == 'e' ? edgeRole : vertexRole;
      // Correspondence-preserving provenance: the source's newest token
      // (doc-04 mirror/pattern keep the copy pointing at its origin), recorded
      // as an ancestor rather than a positional ordinal (ADR-006).
      if (const TopoDS_Shape* source = copyToSource.Seek(entity)) {
        minted.ancestors.push_back(newestTokenOf(*source));
      }
      minted.geometry = GeometryKeyOf(entity, minted.ancestors.empty() ? std::string()
                                                                       : minted.ancestors.front());
      buckets[role].push_back(std::move(minted));
    }
  }
  MintBuckets(operationId, buckets, cancelled, outputIndex);
}

void NamingRegistry::HarvestImportedBody(const std::string& operationId, const int outputIndex,
                                         const TopoDS_Shape& body,
                                         const std::atomic_bool& cancelled) {
  // The import birth is structurally the copied-body mint: the result topology
  // IS exactly the shape harvested and no OCCT history maps its entities. It
  // differs only in provenance — an import descends from FILE BYTES, not from a
  // document entity — so the correspondence map is empty and the records carry
  // no ancestors. Reusing the same mint keeps one lineage-first ordering path
  // (ADR-006) instead of a second one that could drift.
  HarvestCopiedBody(operationId, body, "imported-face", "imported-edge", "imported-vertex",
                    NCollection_DataMap<TopoDS_Shape, TopoDS_Shape, TopTools_ShapeMapHasher>(),
                    cancelled, outputIndex);
}

void NamingRegistry::RegisterDatumEntity(const std::string& operationId, const std::string& role,
                                         const TopoDS_Shape& backing, const gp_Pnt& anchor,
                                         const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  // Only the two plan-02 §2.3 datum roles exist; anything else is a caller
  // defect, refused loudly rather than minting an untabled identity.
  const char kind = KindCodeOf(backing.ShapeType());
  if (!((role == "plane" && kind == 'f') || (role == "axis" && kind == 'e'))) {
    throw std::runtime_error(
        "naming registry only mints datum entities as plane-faces or axis-edges");
  }
  // Direct minting (plan 02: "History object: none"): root the backing shape
  // in the composed book, then append exactly one record. The geometric key
  // is HAND-BUILT — quantized anchor centroid, measure 0 — so the bounded
  // backing proxy's finite extent (a display stand-in for the plan's
  // infinite analytic) never leaks into §6.4 ordering or measures.
  book_.AddPrimitive(operationId, backing);
  MintPlan plan;
  plan.shape = backing;
  plan.kind = kind;
  plan.kindRank = KindRankOf(kind);
  plan.lineageName = book_.NameOf(backing);
  plan.normalizedName = NormalizeElementName(plan.lineageName);
  plan.geometry.x = Quantize(anchor.X(), 1e-3);
  plan.geometry.y = Quantize(anchor.Y(), 1e-3);
  plan.geometry.z = Quantize(anchor.Z(), 1e-3);
  plan.geometry.measure = 0;
  plan.geometry.classRank = 0; // plane / line — rank 0 in both class tables
  std::map<std::string, std::vector<MintPlan>> buckets;
  buckets[role].push_back(std::move(plan));
  MintBuckets(operationId, buckets, cancelled);
}

void NamingRegistry::RegisterSketchEdges(
    const std::string& operationId, const std::string& role, const std::string& lineageNamespace,
    const std::vector<std::pair<std::string, TopoDS_Shape>>& edges,
    const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  if (role.empty() || lineageNamespace.empty())
    throw std::invalid_argument("sketch edge role and lineage namespace must be non-empty");
  std::map<std::string, std::vector<MintPlan>> buckets;
  for (const auto& [semanticId, backing] : edges) {
    CheckCancellation(cancelled);
    if (semanticId.empty() || backing.IsNull() || backing.ShapeType() != TopAbs_EDGE)
      throw std::invalid_argument("sketch edge registration received an invalid edge");
    book_.AddPrimitive(operationId + ":" + lineageNamespace + ":" + semanticId, backing);
    MintPlan plan;
    plan.shape = backing;
    plan.kind = 'e';
    plan.kindRank = KindRankOf(plan.kind);
    plan.lineageName = book_.NameOf(backing);
    plan.normalizedName = NormalizeElementName(plan.lineageName);
    plan.geometry = GeometryKeyOf(backing, "");
    plan.stableOrdinal = StableSemanticOrdinal(semanticId);
    buckets[role].push_back(std::move(plan));
  }
  MintBuckets(operationId, buckets, cancelled);
}

void NamingRegistry::HarvestOperation(const std::string& operationId,
                                      const OperationClass operationClass,
                                      const std::vector<Input>& inputs, const TopoDS_Shape& result,
                                      const BRepTools_History& history,
                                      const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  std::array<ShapeMap, 3> resultOfKind;
  for (std::size_t kindIndex = 0; kindIndex < kNamedKinds.size(); ++kindIndex)
    TopExp::MapShapes(result, kNamedKinds[kindIndex], resultOfKind[kindIndex]);
  const auto inResult = [&resultOfKind](const TopoDS_Shape& shape) {
    switch (shape.ShapeType()) {
    case TopAbs_FACE:
      return resultOfKind[0].Contains(shape);
    case TopAbs_EDGE:
      return resultOfKind[1].Contains(shape);
    case TopAbs_VERTEX:
      return resultOfKind[2].Contains(shape);
    default:
      return false;
    }
  };

  // §6.3 inputs: every source sub-shape arrives with its token(s). A source
  // without a registry record is a threading defect — fail loudly.
  ShapeMap sources;
  std::vector<bool> sourceIsTool;
  std::vector<bool> sourceIsSynthetic;
  for (const Input& input : inputs) {
    for (const TopAbs_ShapeEnum kind : kNamedKinds) {
      CheckCancellation(cancelled);
      ShapeMap inputShapes;
      TopExp::MapShapes(input.shape, kind, inputShapes);
      for (int index = 1; index <= inputShapes.Extent(); ++index) {
        const TopoDS_Shape& source = inputShapes(index);
        if (sources.Contains(source))
          continue;
        const std::vector<std::size_t>* answering = shapeIndex_.Seek(source);
        if (answering == nullptr || answering->empty()) {
          throw std::runtime_error(
              "naming registry requires every input sub-shape to hold a record before the "
              "operation harvests");
        }
        sources.Add(source);
        sourceIsTool.push_back(input.tool);
        sourceIsSynthetic.push_back(input.synthetic);
      }
    }
  }
  const auto isSyntheticOrdinal = [&sourceIsSynthetic](const int ordinal) {
    return sourceIsSynthetic[static_cast<std::size_t>(ordinal - 1)];
  };
  // The newest token currently answering for one source shape — the
  // canonical ancestor handle recorded on minted descendants.
  const auto newestTokenOf = [this](const TopoDS_Shape& source) -> const std::string& {
    const std::vector<std::size_t>* answering = shapeIndex_.Seek(source);
    if (answering == nullptr || answering->empty())
      throw std::runtime_error("naming registry lost a source record it verified");
    return records_[answering->back()].token;
  };

  // Reverse history restricted to images that actually appear in the result
  // (mirroring the element-name pass exactly).
  ParentMap reverseModified;
  ParentMap reverseGenerated;
  std::vector<int> modifiedImageCount(static_cast<std::size_t>(sources.Extent()) + 1, 0);
  const auto addParent = [](ParentMap& map, const TopoDS_Shape& image, const int sourceOrdinal) {
    std::vector<int>* parents = map.ChangeSeek(image);
    if (parents == nullptr) {
      map.Bind(image, std::vector<int>());
      parents = map.ChangeSeek(image);
    }
    if (std::find(parents->begin(), parents->end(), sourceOrdinal) == parents->end())
      parents->push_back(sourceOrdinal);
  };
  for (int ordinal = 1; ordinal <= sources.Extent(); ++ordinal) {
    CheckCancellation(cancelled);
    const TopoDS_Shape& source = sources(ordinal);
    for (const TopoDS_Shape& image : history.Modified(source)) {
      if (!inResult(image))
        continue;
      // A SELF-image — `Modified(x)` containing `x` — is identity survival
      // wearing a Modified badge, not a modification. `BRepTools_History::Merge`
      // emits them for entities a stage left untouched, so any operation that
      // composes two histories produces them. Reading one as a real image made
      // the source both an identity survivor and a modified source, and the
      // survivor pass below rejected that pair as an incoherent history —
      // aborting the whole registry build, which fails `record_selection` and
      // leaves every selector-driven verb (Hole, Push, Datum, Sketch, Mirror,
      // Hollow) permanently disabled against an otherwise valid body.
      //
      // `boolean_combine`'s unify path already rebuilt its composed history to
      // strip these (see `geometry.cpp`'s "identity-survives yet claims
      // Modified images" note), but that was one call site defending itself.
      // Dropping self-images HERE makes every present and future history
      // composition safe, and is the same judgement stated once.
      if (image.IsSame(source))
        continue;
      if (image.ShapeType() != source.ShapeType()) {
        throw std::runtime_error(
            "naming registry found a Modified image of a different kind than its source");
      }
      addParent(reverseModified, image, ordinal);
      modifiedImageCount[static_cast<std::size_t>(ordinal)] += 1;
    }
    for (const TopoDS_Shape& image : history.Generated(source)) {
      // Same rule as Modified above: a shape cannot have generated itself, so a
      // self-image here is merge noise. Recording it would make the entity its
      // own parent and give the classification pass a cycle to resolve.
      if (inResult(image) && !image.IsSame(source))
        addParent(reverseGenerated, image, ordinal);
    }
  }

  // Identity survivors keep their records untouched; a survivor that ALSO
  // claims Modified images is an incoherent history. A SYNTHETIC-tool survivor
  // (an unchanged face/edge of the hole's cylinder — e.g. the blind-hole
  // floor, whose cap is untrimmed) is NOT a real identity: it re-mints under
  // the operation role and its scaffolding dies, so it never keeps a live
  // `tool` record. It is collected here and routed in the classification loop.
  ShapeMap survivors;
  ShapeMap syntheticSurvivors;
  for (int ordinal = 1; ordinal <= sources.Extent(); ++ordinal) {
    const TopoDS_Shape& source = sources(ordinal);
    if (!inResult(source))
      continue;
    if (modifiedImageCount[static_cast<std::size_t>(ordinal)] > 0) {
      throw std::runtime_error(
          "naming registry found a source that identity-survives yet claims Modified images");
    }
    if (isSyntheticOrdinal(ordinal)) {
      syntheticSurvivors.Add(source);
    } else {
      survivors.Add(source);
    }
  }

  // Classify every remaining result entity into role buckets (§6.3 steps
  // 3–9), with the assign-conflict tie-break: target operand over tools,
  // then Modified over Generated; every losing provenance lands in
  // ancestors.
  std::map<std::string, std::vector<MintPlan>> buckets;
  ShapeMap aliasedSources;
  for (std::size_t kindIndex = 0; kindIndex < kNamedKinds.size(); ++kindIndex) {
    const ShapeMap& shapes = resultOfKind[kindIndex];
    for (int index = 1; index <= shapes.Extent(); ++index) {
      CheckCancellation(cancelled);
      const TopoDS_Shape& entity = shapes(index);
      if (survivors.Contains(entity))
        continue;
      const char kind = KindCodeOf(entity.ShapeType());
      const std::vector<int>* modifiedParents = reverseModified.Seek(entity);
      const std::vector<int>* generatedParents = reverseGenerated.Seek(entity);

      MintPlan plan;
      plan.shape = entity;
      plan.kind = kind;
      plan.kindRank = KindRankOf(kind);
      plan.lineageName = book_.NameOf(entity);
      plan.normalizedName = NormalizeElementName(plan.lineageName);

      std::string role;
      std::vector<std::string> ancestors;
      const auto collectAncestors = [&](const std::vector<int>* parents) {
        if (parents == nullptr)
          return;
        for (const int parentOrdinal : *parents)
          ancestors.push_back(newestTokenOf(sources(parentOrdinal)));
      };
      collectAncestors(modifiedParents);
      collectAncestors(generatedParents);
      std::sort(ancestors.begin(), ancestors.end());
      ancestors.erase(std::unique(ancestors.begin(), ancestors.end()), ancestors.end());

      if (modifiedParents != nullptr) {
        // A MERGED image (Modified from SEVERAL sources) is two operand entities
        // fusing into one result. Catalog wave 2 produces them by construction:
        // mirroring or patterning a body onto itself merges the operands'
        // coplanar faces. Exactly one ancestor may carry identity forward, and
        // it is chosen by the SAME §6.3 precedence already used for assign
        // conflicts below — a TARGET outranks a tool, a real source outranks a
        // SYNTHETIC scaffold (whose token has no durable identity), and the
        // lowest ordinal breaks remaining ties (ADR-006 lineage-first). That is
        // replay-deterministic and resolves to the same ancestor the element
        // book picks for the lineage name, so name and role never diverge. The
        // absorbed ancestors remain in `ancestors` above, so the record still
        // describes the whole merge for anchor-based recovery.
        const int parentOrdinal = *std::min_element(
            modifiedParents->begin(), modifiedParents->end(),
            [&sourceIsTool, &isSyntheticOrdinal](const int lhs, const int rhs) {
              const bool lhsTool = sourceIsTool[static_cast<std::size_t>(lhs - 1)];
              const bool rhsTool = sourceIsTool[static_cast<std::size_t>(rhs - 1)];
              if (lhsTool != rhsTool)
                return !lhsTool; // target before tool (§6.3)
              const bool lhsSynthetic = isSyntheticOrdinal(lhs);
              const bool rhsSynthetic = isSyntheticOrdinal(rhs);
              if (lhsSynthetic != rhsSynthetic)
                return !lhsSynthetic; // real source before synthetic scaffold
              return lhs < rhs;       // lineage-first deterministic tie-break
            });
        const bool parentIsTool = sourceIsTool[static_cast<std::size_t>(parentOrdinal - 1)];
        // Assign-conflict tie-break: a TARGET-generated claim outranks a
        // tool-modified one (§6.3: target over tools before modified over
        // generated); the Modified relation still drives aliasing below.
        bool targetGeneratedWins = false;
        if (parentIsTool && generatedParents != nullptr) {
          for (const int generatedOrdinal : *generatedParents) {
            if (!sourceIsTool[static_cast<std::size_t>(generatedOrdinal - 1)])
              targetGeneratedWins = true;
          }
        }
        role = targetGeneratedWins ? RoleForGenerated(operationClass, false, kind)
                                   : RoleForModified(operationClass, parentIsTool, kind);
        if (modifiedImageCount[static_cast<std::size_t>(parentOrdinal)] == 1 &&
            !isSyntheticOrdinal(parentOrdinal)) {
          // 1:1 Modified: identity continues — alias (§6.3 step 12). A
          // SYNTHETIC parent (the hole cylinder) never aliases: its
          // scaffolding token has no durable identity to carry forward, so
          // the image mints fresh under the op role and the scaffold dies in
          // the sweep — the token survives only as recorded provenance.
          plan.aliasSource = sources(parentOrdinal);
          aliasedSources.Add(plan.aliasSource);
        }
        // A SPLIT (several same-kind images of one source) never aliases:
        // the source token dies with the sweep below, each half minths a
        // fresh record, and grammar-identical halves surface as collisions.
      } else if (generatedParents != nullptr) {
        if (generatedParents->size() == 1) {
          const int parentOrdinal = generatedParents->front();
          role = RoleForGenerated(operationClass,
                                  sourceIsTool[static_cast<std::size_t>(parentOrdinal - 1)], kind);
        } else {
          role = RoleForSection(operationClass, kind);
        }
      } else if (syntheticSurvivors.Contains(entity)) {
        // A synthetic-tool sub-shape that passed through unchanged (the
        // blind-hole floor is the tool's untrimmed end cap). It has no
        // durable identity: re-mint it under the operation's tool role
        // (hole tool-face -> `wall`) with its scaffolding token recorded as
        // provenance; the cleanup before MintBuckets retires the scaffold so
        // the fresh record is the shape's sole live answer.
        role = RoleForModified(operationClass, /*tool=*/true, kind);
        ancestors.push_back(newestTokenOf(entity));
      } else {
        // History-missed entity (§6.3 steps 7–9). The naming pass already
        // attributed it structurally (an L-reconstruction or a history step)
        // or gave up with a bare quantized root — the latter is exactly the
        // "cannot attribute" case the registry refuses to paper over.
        if (IsBareQuantizedRoot(plan.lineageName)) {
          throw std::runtime_error(
              "naming registry cannot attribute a result entity (bare quantized-geometry root " +
              plan.lineageName + "); refusing to mint an untrusted identity");
        }
        role = RoleForUnattributed(operationClass, kind);
      }

      plan.ancestors = std::move(ancestors);
      plan.geometry =
          GeometryKeyOf(entity, plan.ancestors.empty() ? std::string() : plan.ancestors.front());
      buckets[role].push_back(std::move(plan));
    }
  }

  // Retire the scaffolding of every synthetic-tool survivor BEFORE minting:
  // the survivor shape IS the scaffold's shape, so the fresh op-role record
  // MintBuckets is about to bind must be that shape's sole answer. The
  // scaffold token was already captured as the mint's ancestor above.
  for (int ordinal = 1; ordinal <= sources.Extent(); ++ordinal) {
    const TopoDS_Shape& source = sources(ordinal);
    if (!syntheticSurvivors.Contains(source))
      continue;
    if (const std::vector<std::size_t>* answering = shapeIndex_.Seek(source)) {
      for (const std::size_t recordIndex : *answering)
        records_[recordIndex].live = false;
      shapeIndex_.UnBind(source);
    }
  }

  MintBuckets(operationId, buckets, cancelled);

  // §6.3 step 13 (scoped to this operation's inputs): sources that neither
  // identity-survived nor continued through a 1:1 Modified alias are no
  // longer in the current replay state — their records die, and their
  // now-stale answering sets leave the current-state shape index. Synthetic
  // survivors are skipped: their scaffold was already retired above and the
  // shape now holds the freshly minted op-role record.
  for (int ordinal = 1; ordinal <= sources.Extent(); ++ordinal) {
    const TopoDS_Shape& source = sources(ordinal);
    if (survivors.Contains(source) || aliasedSources.Contains(source) ||
        syntheticSurvivors.Contains(source))
      continue;
    if (const std::vector<std::size_t>* answering = shapeIndex_.Seek(source)) {
      for (const std::size_t recordIndex : *answering)
        records_[recordIndex].live = false;
      shapeIndex_.UnBind(source);
    }
  }

  // Registry totality: every result entity answers to at least one live
  // record. A miss here is a harvest defect, never a skip.
  for (std::size_t kindIndex = 0; kindIndex < kNamedKinds.size(); ++kindIndex) {
    const ShapeMap& shapes = resultOfKind[kindIndex];
    for (int index = 1; index <= shapes.Extent(); ++index) {
      const std::vector<std::size_t>* answering = shapeIndex_.Seek(shapes(index));
      const bool anyLive =
          answering != nullptr &&
          std::any_of(answering->begin(), answering->end(),
                      [this](const std::size_t recordIndex) { return records_[recordIndex].live; });
      if (!anyLive)
        throw std::runtime_error("naming registry failed total coverage of the result");
    }
  }
}

} // namespace aeth
