#include "selector_evaluator.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepAdaptor_Curve.hxx>
#include <BRepAdaptor_Surface.hxx>
#include <BRepBndLib.hxx>
#include <BRepBuilderAPI_MakeVertex.hxx>
#include <BRepExtrema_DistShapeShape.hxx>
#include <BRepGProp.hxx>
#include <BRep_Tool.hxx>
#include <Bnd_Box.hxx>
#include <GProp_GProps.hxx>
#include <NCollection_DataMap.hxx>
#include <NCollection_IndexedMap.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Dir.hxx>
#include <gp_Pnt.hxx>
#include <gp_Pnt2d.hxx>

#include "cancel.hpp"
#include "geometry_measures.hpp"
#include "naming_registry.hpp"

namespace aeth {
namespace {

using ShapeMap = NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher>;
template <typename V>
using ShapeData = NCollection_DataMap<TopoDS_Shape, V, TopTools_ShapeMapHasher>;

constexpr double kPi = 3.14159265358979323846;

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

[[noreturn]] void Unsupported(const std::string& message) {
  // std::invalid_argument beginning with "unsupported operation" is what the
  // server maps to UNSUPPORTED_OPERATION (server.cpp catch chain) — the
  // fail-closed path for every deferred selector surface.
  throw std::invalid_argument("unsupported operation: " + message);
}

char HeadKindChar(const std::string& kind) {
  if (kind == "faces")
    return 'f';
  if (kind == "edges")
    return 'e';
  if (kind == "vertices")
    return 'v';
  if (kind == "bodies" || kind == "regions")
    Unsupported("selector head kind '" + kind +
                "' is deferred (no body/region evaluation in this tranche)");
  throw std::invalid_argument("selector query has an unknown head kind: " + kind);
}

TopAbs_ShapeEnum TopAbsOf(const char kind) {
  switch (kind) {
  case 'f':
    return TopAbs_FACE;
  case 'e':
    return TopAbs_EDGE;
  case 'v':
    return TopAbs_VERTEX;
  default:
    throw std::runtime_error("selector evaluator covers faces, edges, and vertices only");
  }
}

int KindRank(const char kind) {
  switch (kind) {
  case 'f':
    return 0;
  case 'e':
    return 1;
  case 'v':
    return 2;
  default:
    return 3;
  }
}

// ---------------------------------------------------------------------------
// Measured primitives (plan 05 §5), computed lazily per filter.
// ---------------------------------------------------------------------------

gp_Pnt Centroid(const TopoDS_Shape& shape) {
  switch (shape.ShapeType()) {
  case TopAbs_FACE: {
    GProp_GProps properties;
    BRepGProp::SurfaceProperties(shape, properties);
    return properties.CentreOfMass();
  }
  case TopAbs_EDGE: {
    const TopoDS_Edge edge = TopoDS::Edge(shape);
    if (BRep_Tool::Degenerated(edge)) {
      TopoDS_Vertex first;
      TopoDS_Vertex last;
      TopExp::Vertices(edge, first, last);
      if (!first.IsNull())
        return BRep_Tool::Pnt(first);
      throw std::runtime_error("selector evaluator found a degenerate edge with no vertex");
    }
    GProp_GProps properties;
    BRepGProp::LinearProperties(shape, properties);
    return properties.CentreOfMass();
  }
  case TopAbs_VERTEX:
    return BRep_Tool::Pnt(TopoDS::Vertex(shape));
  default:
    throw std::runtime_error("selector evaluator cannot take a centroid of this shape kind");
  }
}

double FaceArea(const TopoDS_Face& face) {
  GProp_GProps properties;
  BRepGProp::SurfaceProperties(face, properties);
  return std::abs(properties.Mass());
}

double EdgeLength(const TopoDS_Edge& edge) {
  GProp_GProps properties;
  BRepGProp::LinearProperties(edge, properties);
  return std::abs(properties.Mass());
}

/// Canonical measure for size filters (§3.2): faces → area, edges → length,
/// vertices → 0 (they never carry a measure filter through doc-model kind
/// checks, but a defensive 0 keeps the sort total).
double Measure(const TopoDS_Shape& shape) {
  switch (shape.ShapeType()) {
  case TopAbs_FACE:
    return FaceArea(TopoDS::Face(shape));
  case TopAbs_EDGE:
    return EdgeLength(TopoDS::Edge(shape));
  default:
    return 0.0;
  }
}

double ClosestDistance(const gp_Pnt& point, const TopoDS_Shape& shape) {
  const TopoDS_Vertex probe = BRepBuilderAPI_MakeVertex(point);
  BRepExtrema_DistShapeShape distance(probe, shape);
  if (!distance.IsDone() || distance.NbSolution() < 1)
    throw std::runtime_error("selector evaluator could not measure a point-to-entity distance");
  return distance.Value();
}

double AngleDegrees(const gp_Dir& a, const gp_Dir& b) {
  double dot = a.Dot(b);
  dot = std::clamp(dot, -1.0, 1.0);
  return std::acos(dot) * 180.0 / kPi;
}

std::optional<gp_Dir> AsDir(const Axis& axis) {
  if (!axis)
    return std::nullopt;
  const std::array<double, 3>& v = *axis;
  if (v[0] * v[0] + v[1] * v[1] + v[2] * v[2] < 1e-18)
    return std::nullopt;
  return gp_Dir(v[0], v[1], v[2]);
}

/// The DIRECTED outward normal of a planar face (nullopt for non-planar).
/// Used by `normal()` and `onGround()`, which are sign-sensitive.
std::optional<gp_Dir> FaceOutwardNormal(const TopoDS_Face& face) {
  const BRepAdaptor_Surface surface(face, true);
  if (surface.GetType() != GeomAbs_Plane)
    return std::nullopt;
  return AsDir(PlanarOutwardNormal(face, surface));
}

/// The UNDIRECTED representative axis of an entity for `parallel`/
/// `perpendicular`: a face's plane normal or cylinder/cone axis, an edge's
/// line direction or circle/ellipse axis. nullopt when the entity has no such
/// direction (a freeform face or curve).
std::optional<gp_Dir> EntityAxis(const TopoDS_Shape& shape) {
  switch (shape.ShapeType()) {
  case TopAbs_FACE:
    return AsDir(SurfaceAxis(TopoDS::Face(shape)));
  case TopAbs_EDGE:
    return AsDir(CurveAxis(TopoDS::Edge(shape)));
  default:
    return std::nullopt;
  }
}

// ---------------------------------------------------------------------------
// AST argument accessors. Filter args arrive as the wire form
// `{arg:"<tag>", value:<...>}` (packages/geometry-contracts/src/selector-ast.ts,
// mirroring the document-model AST). Each accessor asserts the tag so a
// mis-shaped AST fails loudly rather than resolving to a guess.
// ---------------------------------------------------------------------------

const nlohmann::json& ArgAt(const nlohmann::json& args, const std::size_t index) {
  if (!args.is_array() || index >= args.size())
    throw std::invalid_argument("selector filter is missing a required argument");
  return args.at(index);
}

double NumberArg(const nlohmann::json& args, const std::size_t index) {
  const nlohmann::json& arg = ArgAt(args, index);
  if (arg.at("arg").get<std::string>() != "number")
    throw std::invalid_argument("selector filter expected a number argument");
  return arg.at("value").get<double>();
}

double NumberArgOr(const nlohmann::json& args, const std::size_t index, const double fallback) {
  if (!args.is_array() || index >= args.size())
    return fallback;
  return NumberArg(args, index);
}

char AxisArg(const nlohmann::json& args, const std::size_t index) {
  const nlohmann::json& arg = ArgAt(args, index);
  if (arg.at("arg").get<std::string>() != "axis")
    throw std::invalid_argument("selector filter expected an axis argument");
  const std::string axis = arg.at("value").get<std::string>();
  if (axis == "x")
    return 'x';
  if (axis == "y")
    return 'y';
  if (axis == "z")
    return 'z';
  throw std::invalid_argument("selector axis argument must be x, y, or z");
}

std::string IdentArg(const nlohmann::json& args, const std::size_t index) {
  const nlohmann::json& arg = ArgAt(args, index);
  if (arg.at("arg").get<std::string>() != "ident")
    throw std::invalid_argument("selector filter expected an identifier argument");
  return arg.at("value").get<std::string>();
}

gp_Dir DirectionArg(const nlohmann::json& args, const std::size_t index) {
  const nlohmann::json& arg = ArgAt(args, index);
  if (arg.at("arg").get<std::string>() != "direction")
    throw std::invalid_argument("selector filter expected a direction argument");
  const nlohmann::json& value = arg.at("value");
  const std::string form = value.at("form").get<std::string>();
  if (form == "axis") {
    const double sign = value.at("sign").get<double>();
    const std::string axis = value.at("axis").get<std::string>();
    if (axis == "x")
      return gp_Dir(sign, 0.0, 0.0);
    if (axis == "y")
      return gp_Dir(0.0, sign, 0.0);
    if (axis == "z")
      return gp_Dir(0.0, 0.0, sign);
    throw std::invalid_argument("selector direction axis must be x, y, or z");
  }
  if (form == "vector") {
    const nlohmann::json& vector = value.at("vector");
    return gp_Dir(vector.at(0).get<double>(), vector.at(1).get<double>(),
                  vector.at(2).get<double>());
  }
  throw std::invalid_argument("selector direction has an unknown form");
}

gp_Pnt PointArg(const nlohmann::json& args, const std::size_t index) {
  const nlohmann::json& arg = ArgAt(args, index);
  if (arg.at("arg").get<std::string>() != "point")
    throw std::invalid_argument("selector filter expected a point argument");
  const nlohmann::json& value = arg.at("value");
  if (!value.is_array())
    throw std::invalid_argument("selector point argument must be an array");
  if (value.size() == 3)
    return gp_Pnt(value.at(0).get<double>(), value.at(1).get<double>(), value.at(2).get<double>());
  // A 2-component point is a sketch-plane coordinate (regions.containing),
  // which this tranche defers — a 3D positional filter needs all three.
  Unsupported("2-component point arguments are sketch-only and deferred");
}

const nlohmann::json& QueryArg(const nlohmann::json& args, const std::size_t index) {
  const nlohmann::json& arg = ArgAt(args, index);
  if (arg.at("arg").get<std::string>() != "query")
    throw std::invalid_argument("selector filter expected a nested query argument");
  return arg.at("value");
}

// ---------------------------------------------------------------------------
// Evaluation context and the entity set model.
// ---------------------------------------------------------------------------

struct EvalContext final {
  const std::vector<EvaluatedBody>& bodies;
  const NamingRegistry& registry;
  const std::atomic_bool& cancelled;
  /// Every result sub-shape → its owning visible body id and body root shape.
  ShapeData<std::string> shapeToBodyId;
  ShapeData<TopoDS_Shape> shapeToBody;
  std::vector<QueryDiagnostic>& diagnostics;
  /// Tokens already carrying a D_MIXED_CONVEXITY / D_TOKEN_DEAD note, so one
  /// entity never floods the diagnostics list.
  ShapeData<bool> mixedNoted;
};

/// Newest live token answering for `shape` (the §6.3 alias chain's tail).
std::string NewestToken(const NamingRegistry& registry, const TopoDS_Shape& shape) {
  const std::vector<std::string> tokens = registry.TokensOf(shape);
  return tokens.empty() ? std::string() : tokens.back();
}

/// `allowBodyless` admits a SYNTHETIC DATUM entity (CAP-014): a datum plane's
/// face or a datum axis's edge belongs to no visible body, by construction —
/// the datum executors produce registry entities and no geometry the user can
/// see. For every other entity a missing body is a real coverage defect and
/// must keep throwing, which is why this is an explicit opt-in at the two datum
/// call sites rather than a relaxed check for everyone.
///
/// A body-less entity is legal INSIDE ref-slot resolution and illegal on the
/// `query` wire, where `resolvedEntitySchema` requires `bodyId` (a named seam,
/// PROTOCOL §4). `server.cpp`'s query handler enforces that boundary.
QueryEntity MakeEntity(EvalContext& ctx, const TopoDS_Shape& shape, const char kind,
                       const bool allowBodyless = false) {
  QueryEntity entity;
  entity.shape = shape;
  entity.kind = kind;
  const std::string* bodyId = ctx.shapeToBodyId.Seek(shape);
  if (bodyId == nullptr && !allowBodyless)
    throw std::runtime_error("selector evaluator found an entity not owned by any visible body");
  entity.bodyId = bodyId != nullptr ? *bodyId : std::string();
  entity.token = NewestToken(ctx.registry, shape);
  if (entity.token.empty()) {
    // Registry totality (naming_registry.cpp) guarantees every live result
    // sub-shape holds a live record; a miss is a harvest defect, never a
    // silently-untokened entity.
    throw std::runtime_error(
        "selector evaluator found a live entity with no naming record (registry coverage defect)");
  }
  const NamingRecord* record = ctx.registry.FindByToken(entity.token);
  entity.normalizedName = record != nullptr ? record->normalizedLineageName : std::string();
  return entity;
}

/// A set of entities with O(1) membership by shape identity. Preserves
/// insertion order for reproducible diagnostics; final canonical ordering is
/// applied once at the end (§6.4).
class EntitySet final {
public:
  bool Add(QueryEntity entity) {
    if (membership_.Contains(entity.shape))
      return false;
    membership_.Add(entity.shape);
    entities_.push_back(std::move(entity));
    return true;
  }
  bool Contains(const TopoDS_Shape& shape) const { return membership_.Contains(shape); }
  std::vector<QueryEntity>& Entities() { return entities_; }
  const std::vector<QueryEntity>& Entities() const { return entities_; }
  std::size_t Size() const { return entities_.size(); }

private:
  std::vector<QueryEntity> entities_;
  ShapeMap membership_;
};

std::vector<QueryEntity> EvaluateToSet(const nlohmann::json& ast, EvalContext& ctx,
                                       std::vector<std::size_t>* stages);

// ---------------------------------------------------------------------------
// Scope expansion → S0 (plan 05 §4.1).
// ---------------------------------------------------------------------------

void ExpandSource(const nlohmann::json& source, const char headKind, EvalContext& ctx,
                  EntitySet& into) {
  const std::string kind = source.at("source").get<std::string>();
  const TopAbs_ShapeEnum topAbs = TopAbsOf(headKind);
  if (kind == "op") {
    const std::string opId = source.at("opId").get<std::string>();
    for (std::size_t index = 0; index < ctx.registry.RecordCount(); ++index) {
      CheckCancellation(ctx.cancelled);
      const NamingRecord& record = ctx.registry.RecordAt(index);
      if (record.live && record.minter == opId && record.kind == headKind) {
        // Catalog wave 1: datum operations mint SYNTHETIC entities whose
        // backing shape belongs to no visible body (plan 02 §2.3). Resolving
        // them through the evaluator (datum-on-datum chaining) is a later
        // tranche — refuse deliberately instead of tripping the
        // coverage-defect internal error in MakeEntity.
        // CAP-014: a live record whose shape belongs to no visible body IS a
        // synthetic datum entity — a datum plane resolves under `faces`, a
        // datum axis under `edges`. It resolves body-less on purpose; the wire
        // boundary in server.cpp is what keeps it off the `query` method.
        into.Add(MakeEntity(ctx, record.shape, headKind,
                            ctx.shapeToBodyId.Seek(record.shape) == nullptr));
      }
    }
    return;
  }
  if (kind == "body") {
    const std::string opId = source.at("opId").get<std::string>();
    for (const EvaluatedBody& body : ctx.bodies) {
      if (body.operationId != opId)
        continue;
      ShapeMap shapes;
      TopExp::MapShapes(body.shape, topAbs, shapes);
      for (int index = 1; index <= shapes.Extent(); ++index)
        into.Add(MakeEntity(ctx, shapes(index), headKind));
    }
    // A body() source that names an op which is not a visible body (a consumed
    // or intermediate lineage) resolves to the empty set here rather than a
    // guess: lineage-body tracking beyond the final unconsumed bodies is a
    // later tranche. The empty set is attributed through stage cardinalities.
    return;
  }
  if (kind == "token") {
    const std::string token = source.at("token").get<std::string>();
    const NamingRecord* record = ctx.registry.FindByToken(token);
    if (record == nullptr)
      return;
    if (!record->live) {
      ctx.diagnostics.push_back(
          {"D_TOKEN_DEAD", "token no longer resolves to a live entity", token});
      return;
    }
    if (record->kind == headKind) {
      // Same rule as the `op` source (CAP-014): a live record whose shape
      // belongs to no visible body is a synthetic datum entity and resolves
      // body-less. A token source is how a RECORDED datum reference re-resolves
      // on replay, so this arm is what makes a saved datum-mirror reopen.
      into.Add(MakeEntity(ctx, record->shape, headKind,
                          ctx.shapeToBodyId.Seek(record->shape) == nullptr));
    }
    return;
  }
  if (kind == "all") {
    for (const EvaluatedBody& body : ctx.bodies) {
      ShapeMap shapes;
      TopExp::MapShapes(body.shape, topAbs, shapes);
      for (int index = 1; index <= shapes.Extent(); ++index)
        into.Add(MakeEntity(ctx, shapes(index), headKind));
    }
    return;
  }
  if (kind == "sketch" || kind == "tag" || kind == "world") {
    Unsupported("selector source '" + kind + "' is deferred in this tranche");
  }
  throw std::invalid_argument("selector query has an unknown scope source: " + kind);
}

// ---------------------------------------------------------------------------
// Canonical ordering (plan 05 §6.4): normalized lineage name, then a geometric
// tie-break, then the token string as the final determinism guarantee.
// ---------------------------------------------------------------------------

long long Quantize(const double value, const double quantum) {
  return std::llrint(value / quantum + 1e-9);
}

struct OrderKey final {
  int kindRank{};
  std::string normalizedName;
  long long x{};
  long long y{};
  long long z{};
  long long measure{};
  std::string token;

  bool operator<(const OrderKey& other) const {
    if (kindRank != other.kindRank)
      return kindRank < other.kindRank;
    if (normalizedName != other.normalizedName)
      return normalizedName < other.normalizedName;
    if (x != other.x)
      return x < other.x;
    if (y != other.y)
      return y < other.y;
    if (z != other.z)
      return z < other.z;
    if (measure != other.measure)
      return measure < other.measure;
    return token < other.token;
  }
};

OrderKey KeyOf(const QueryEntity& entity) {
  OrderKey key;
  key.kindRank = KindRank(entity.kind);
  key.normalizedName = entity.normalizedName;
  const gp_Pnt centroid = Centroid(entity.shape);
  key.x = Quantize(centroid.X(), 1e-3);
  key.y = Quantize(centroid.Y(), 1e-3);
  key.z = Quantize(centroid.Z(), 1e-3);
  key.measure = Quantize(Measure(entity.shape), 1e-6);
  key.token = entity.token;
  return key;
}

void CanonicalSort(std::vector<QueryEntity>& entities) {
  std::stable_sort(entities.begin(), entities.end(),
                   [](const QueryEntity& a, const QueryEntity& b) { return KeyOf(a) < KeyOf(b); });
}

// ---------------------------------------------------------------------------
// Filter application (plan 05 §3.2, §4.1). Each filter maps the input set to a
// subset (or, for union, a superset) with no reordering; ordering is deferred
// to the single canonical sort at the end.
// ---------------------------------------------------------------------------

/// Collects every sub-shape (all kinds, including the shapes themselves) of a
/// nested query's result set — the adjacency/on/boundary primitives all work
/// off this map.
ShapeMap SubShapesOf(const std::vector<QueryEntity>& entities) {
  ShapeMap collected;
  for (const QueryEntity& entity : entities) {
    for (const TopAbs_ShapeEnum kind : {TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX}) {
      ShapeMap ofKind;
      TopExp::MapShapes(entity.shape, kind, ofKind);
      for (int index = 1; index <= ofKind.Extent(); ++index)
        collected.Add(ofKind(index));
    }
    collected.Add(entity.shape);
  }
  return collected;
}

ShapeMap ShapesOf(const std::vector<QueryEntity>& entities) {
  ShapeMap collected;
  for (const QueryEntity& entity : entities)
    collected.Add(entity.shape);
  return collected;
}

std::vector<QueryEntity> ApplyFilter(const nlohmann::json& filter, const char headKind,
                                     EvalContext& ctx, const std::vector<QueryEntity>& input) {
  // The head kind is enforced per-entity (each entity already carries its
  // kind); the parameter documents the pipeline stage's kind without a
  // separate use here.
  (void)headKind;
  const std::string name = filter.at("name").get<std::string>();
  const nlohmann::json& args =
      filter.contains("args") ? filter.at("args") : nlohmann::json::array();

  // A predicate over one entity; the common shape of most filters.
  const auto keepBy = [&](const auto& predicate) {
    std::vector<QueryEntity> output;
    for (const QueryEntity& entity : input) {
      CheckCancellation(ctx.cancelled);
      if (predicate(entity))
        output.push_back(entity);
    }
    return output;
  };

  // --- Creation / role -----------------------------------------------------
  if (name == "role") {
    const std::string role = IdentArg(args, 0);
    return keepBy([&](const QueryEntity& e) {
      for (const std::string& token : ctx.registry.TokensOf(e.shape)) {
        const NamingRecord* record = ctx.registry.FindByToken(token);
        if (record != nullptr && record->role == role)
          return true;
      }
      return false;
    });
  }
  if (name == "created" || name == "modified") {
    const bool wantModified = name == "modified";
    // The reserved cross-op role `modified` (plan 05 §6.1) marks a
    // pass-through entity; every other role is a generation. created() keeps
    // entities generated by some op, modified() keeps pass-throughs.
    return keepBy([&](const QueryEntity& e) {
      bool hasModified = false;
      bool hasGenerated = false;
      for (const std::string& token : ctx.registry.TokensOf(e.shape)) {
        const NamingRecord* record = ctx.registry.FindByToken(token);
        if (record == nullptr)
          continue;
        if (record->role == "modified")
          hasModified = true;
        else
          hasGenerated = true;
      }
      return wantModified ? hasModified : hasGenerated;
    });
  }

  // --- Geometric class -----------------------------------------------------
  if (name == "planar" || name == "cylindrical" || name == "conical" || name == "spherical" ||
      name == "toroidal" || name == "freeform") {
    return keepBy([&](const QueryEntity& e) {
      if (e.kind != 'f')
        return false;
      const std::string surface = SurfaceClass(TopoDS::Face(e.shape));
      if (name == "planar")
        return surface == "plane";
      if (name == "cylindrical")
        return surface == "cylinder";
      if (name == "conical")
        return surface == "cone";
      if (name == "spherical")
        return surface == "sphere";
      if (name == "toroidal")
        return surface == "torus";
      // freeform: anything not an analytic primitive surface.
      return surface != "plane" && surface != "cylinder" && surface != "cone" &&
             surface != "sphere" && surface != "torus";
    });
  }
  if (name == "line" || name == "circle" || name == "ellipse" || name == "bspline") {
    return keepBy([&](const QueryEntity& e) {
      if (e.kind != 'e')
        return false;
      const std::string curve = CurveClass(TopoDS::Edge(e.shape));
      if (name == "line")
        return curve == "line";
      if (name == "circle")
        return curve == "circle";
      if (name == "ellipse")
        return curve == "ellipse";
      // bspline groups the freeform curve families.
      return curve == "bspline-curve" || curve == "bezier-curve";
    });
  }

  // --- Directional ---------------------------------------------------------
  if (name == "normal") {
    const gp_Dir dir = DirectionArg(args, 0);
    const double tol = NumberArgOr(args, 1, 1.0);
    return keepBy([&](const QueryEntity& e) {
      if (e.kind != 'f')
        return false;
      const std::optional<gp_Dir> outward = FaceOutwardNormal(TopoDS::Face(e.shape));
      return outward.has_value() && AngleDegrees(*outward, dir) <= tol;
    });
  }
  if (name == "parallel" || name == "perpendicular") {
    const gp_Dir dir = DirectionArg(args, 0);
    const double tol = NumberArgOr(args, 1, 1.0);
    const bool wantParallel = name == "parallel";
    return keepBy([&](const QueryEntity& e) {
      const std::optional<gp_Dir> axis = EntityAxis(e.shape);
      if (!axis.has_value())
        return false;
      const double angle = AngleDegrees(*axis, dir);
      // Sign-insensitive: fold to [0, 90].
      const double folded = angle > 90.0 ? 180.0 - angle : angle;
      return wantParallel ? folded <= tol : folded >= 90.0 - tol;
    });
  }

  // --- Positional ----------------------------------------------------------
  if (name == "min" || name == "max") {
    const char axis = AxisArg(args, 0);
    const bool wantMax = name == "max";
    if (input.empty())
      return {};
    const auto coord = [axis](const gp_Pnt& p) {
      return axis == 'x' ? p.X() : axis == 'y' ? p.Y() : p.Z();
    };
    double extreme = wantMax ? -1e300 : 1e300;
    for (const QueryEntity& e : input) {
      const double value = coord(Centroid(e.shape));
      extreme = wantMax ? std::max(extreme, value) : std::min(extreme, value);
    }
    return keepBy(
        [&](const QueryEntity& e) { return std::abs(coord(Centroid(e.shape)) - extreme) <= 1e-3; });
  }
  if (name == "at") {
    const gp_Pnt point = PointArg(args, 0);
    const double tol = NumberArgOr(args, 1, 0.5);
    return keepBy([&](const QueryEntity& e) { return ClosestDistance(point, e.shape) <= tol; });
  }
  if (name == "within") {
    const gp_Pnt lo = PointArg(args, 0);
    const gp_Pnt hi = PointArg(args, 1);
    return keepBy([&](const QueryEntity& e) {
      Bnd_Box box;
      BRepBndLib::Add(e.shape, box);
      if (box.IsVoid())
        return false;
      double xmin, ymin, zmin, xmax, ymax, zmax;
      box.Get(xmin, ymin, zmin, xmax, ymax, zmax);
      constexpr double eps = 1e-6;
      return xmin >= std::min(lo.X(), hi.X()) - eps && ymin >= std::min(lo.Y(), hi.Y()) - eps &&
             zmin >= std::min(lo.Z(), hi.Z()) - eps && xmax <= std::max(lo.X(), hi.X()) + eps &&
             ymax <= std::max(lo.Y(), hi.Y()) + eps && zmax <= std::max(lo.Z(), hi.Z()) + eps;
    });
  }
  if (name == "onGround") {
    const double tol = NumberArgOr(args, 0, 1e-3);
    const gp_Dir downward(0.0, 0.0, -1.0);
    return keepBy([&](const QueryEntity& e) {
      if (e.kind != 'f')
        return false;
      const std::optional<gp_Dir> outward = FaceOutwardNormal(TopoDS::Face(e.shape));
      if (!outward.has_value() || AngleDegrees(*outward, downward) > 1.0)
        return false;
      return std::abs(Centroid(e.shape).Z()) <= tol;
    });
  }

  // --- Size / measure ------------------------------------------------------
  if (name == "largest" || name == "smallest") {
    const int count = static_cast<int>(NumberArgOr(args, 0, 1.0));
    std::vector<QueryEntity> sorted = input;
    const bool wantLargest = name == "largest";
    std::stable_sort(sorted.begin(), sorted.end(),
                     [wantLargest](const QueryEntity& a, const QueryEntity& b) {
                       const double ma = Measure(a.shape);
                       const double mb = Measure(b.shape);
                       return wantLargest ? ma > mb : ma < mb;
                     });
    if (static_cast<int>(sorted.size()) > count)
      sorted.resize(static_cast<std::size_t>(std::max(0, count)));
    return sorted;
  }
  if (name == "area") {
    const double lo = NumberArg(args, 0);
    const double hi = NumberArg(args, 1);
    return keepBy([&](const QueryEntity& e) {
      if (e.kind != 'f')
        return false;
      const double a = FaceArea(TopoDS::Face(e.shape));
      return (lo < 0 || a >= lo) && (hi < 0 || a <= hi);
    });
  }
  if (name == "length") {
    const double lo = NumberArg(args, 0);
    const double hi = NumberArg(args, 1);
    return keepBy([&](const QueryEntity& e) {
      if (e.kind != 'e')
        return false;
      const double l = EdgeLength(TopoDS::Edge(e.shape));
      return (lo < 0 || l >= lo) && (hi < 0 || l <= hi);
    });
  }
  if (name == "radius" || name == "radiusBetween") {
    double lo = 0.0;
    double hi = 0.0;
    if (name == "radius") {
      const double r = NumberArg(args, 0);
      const double tol = NumberArgOr(args, 1, 1e-3);
      lo = r - tol;
      hi = r + tol;
    } else {
      lo = NumberArg(args, 0);
      hi = NumberArg(args, 1);
    }
    return keepBy([&](const QueryEntity& e) {
      std::optional<double> radius;
      if (e.kind == 'f') {
        const std::string surface = SurfaceClass(TopoDS::Face(e.shape));
        if (surface == "cylinder")
          radius = CylindricalFaceRadius(TopoDS::Face(e.shape));
        else if (surface == "cone")
          radius = ConicalFaceReferenceRadius(TopoDS::Face(e.shape));
      } else if (e.kind == 'e') {
        if (CurveClass(TopoDS::Edge(e.shape)) == "circle")
          radius = CircleEdgeRadius(TopoDS::Edge(e.shape));
      }
      return radius.has_value() && *radius >= lo && *radius <= hi;
    });
  }

  // --- Topological ---------------------------------------------------------
  if (name == "convex" || name == "concave" || name == "smooth") {
    const double smoothTol = name == "smooth" ? NumberArgOr(args, 0, 1.0) : 1.0;
    return keepBy([&](const QueryEntity& e) {
      if (e.kind != 'e')
        return false;
      const TopoDS_Shape* body = ctx.shapeToBody.Seek(e.shape);
      if (body == nullptr)
        return false;
      const DihedralRange range = ComputeDihedralRange(*body, TopoDS::Edge(e.shape));
      const DihedralClass classified = ClassifyFromRange(range, smoothTol);
      if (classified == DihedralClass::Mixed && !ctx.mixedNoted.IsBound(e.shape)) {
        ctx.mixedNoted.Bind(e.shape, true);
        ctx.diagnostics.push_back(
            {"D_MIXED_CONVEXITY", "edge has mixed convexity along its length", e.token});
      }
      if (name == "convex")
        return classified == DihedralClass::Convex;
      if (name == "concave")
        return classified == DihedralClass::Concave;
      return classified == DihedralClass::Smooth;
    });
  }
  if (name == "adjacentTo") {
    const std::vector<QueryEntity> other = EvaluateToSet(QueryArg(args, 0), ctx, nullptr);
    const ShapeMap neighborhood = SubShapesOf(other);
    const ShapeMap others = ShapesOf(other);
    return keepBy([&](const QueryEntity& e) {
      if (others.Contains(e.shape))
        return false; // an entity is not adjacent to itself
      for (const TopAbs_ShapeEnum kind : {TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX}) {
        ShapeMap boundary;
        TopExp::MapShapes(e.shape, kind, boundary);
        for (int index = 1; index <= boundary.Extent(); ++index) {
          if (boundary(index).IsSame(e.shape))
            continue;
          if (neighborhood.Contains(boundary(index)))
            return true;
        }
      }
      return false;
    });
  }
  if (name == "on" || name == "boundaryOf") {
    // edges/vertices that lie on the boundary of the faces (or edges) `query`
    // returns. Both reduce to "is a sub-shape of some result entity".
    const std::vector<QueryEntity> faces = EvaluateToSet(QueryArg(args, 0), ctx, nullptr);
    const ShapeMap boundary = SubShapesOf(faces);
    return keepBy([&](const QueryEntity& e) { return boundary.Contains(e.shape); });
  }
  if (name == "interiorTo") {
    // edges shared by two faces both in `query`.
    const std::vector<QueryEntity> faces = EvaluateToSet(QueryArg(args, 0), ctx, nullptr);
    return keepBy([&](const QueryEntity& e) {
      if (e.kind != 'e')
        return false;
      int owningFaces = 0;
      for (const QueryEntity& face : faces) {
        if (face.kind != 'f')
          continue;
        ShapeMap edges;
        TopExp::MapShapes(face.shape, TopAbs_EDGE, edges);
        if (edges.Contains(e.shape))
          owningFaces += 1;
      }
      return owningFaces >= 2;
    });
  }

  // --- Set / order ---------------------------------------------------------
  if (name == "union") {
    std::vector<QueryEntity> output = input;
    EntitySet merged;
    for (const QueryEntity& entity : output)
      merged.Add(entity);
    for (const QueryEntity& entity : EvaluateToSet(QueryArg(args, 0), ctx, nullptr))
      merged.Add(entity);
    return merged.Entities();
  }
  if (name == "not") {
    const ShapeMap removed = ShapesOf(EvaluateToSet(QueryArg(args, 0), ctx, nullptr));
    return keepBy([&](const QueryEntity& e) { return !removed.Contains(e.shape); });
  }
  if (name == "nth") {
    const int index = static_cast<int>(NumberArg(args, 0));
    std::vector<QueryEntity> sorted = input;
    CanonicalSort(sorted);
    if (index < 0 || static_cast<std::size_t>(index) >= sorted.size())
      return {};
    return {sorted.at(static_cast<std::size_t>(index))};
  }
  if (name == "first") {
    const int count = static_cast<int>(NumberArg(args, 0));
    std::vector<QueryEntity> sorted = input;
    CanonicalSort(sorted);
    if (static_cast<int>(sorted.size()) > count)
      sorted.resize(static_cast<std::size_t>(std::max(0, count)));
    return sorted;
  }

  Unsupported("selector filter '" + name + "' is not implemented");
}

std::vector<QueryEntity> EvaluateToSet(const nlohmann::json& ast, EvalContext& ctx,
                                       std::vector<std::size_t>* stages) {
  const char headKind = HeadKindChar(ast.at("kind").get<std::string>());

  EntitySet zero;
  for (const nlohmann::json& source : ast.at("scope"))
    ExpandSource(source, headKind, ctx, zero);
  std::vector<QueryEntity> current = std::move(zero.Entities());
  if (stages != nullptr)
    stages->push_back(current.size());

  if (ast.contains("filters")) {
    for (const nlohmann::json& filter : ast.at("filters")) {
      CheckCancellation(ctx.cancelled);
      current = ApplyFilter(filter, headKind, ctx, current);
      if (stages != nullptr)
        stages->push_back(current.size());
    }
  }
  return current;
}

nlohmann::json PointJson(const gp_Pnt& point) { return {point.X(), point.Y(), point.Z()}; }

nlohmann::json DirJson(const gp_Dir& dir) { return {dir.X(), dir.Y(), dir.Z()}; }

nlohmann::json AxisArrayJson(const std::array<double, 3>& axis) {
  return {axis[0], axis[1], axis[2]};
}

std::string SurfaceEnum(const std::string& surfaceClass) {
  if (surfaceClass == "plane" || surfaceClass == "cylinder" || surfaceClass == "cone" ||
      surfaceClass == "sphere" || surfaceClass == "torus")
    return surfaceClass;
  return "freeform";
}

std::string CurveEnum(const std::string& curveClass) {
  if (curveClass == "line" || curveClass == "circle" || curveClass == "ellipse")
    return curveClass;
  if (curveClass == "bspline-curve" || curveClass == "bezier-curve")
    return "bspline";
  return "other";
}

} // namespace

QueryOutcome EvaluateQuery(const nlohmann::json& ast, const std::vector<EvaluatedBody>& bodies,
                           const NamingRegistry& registry, const std::atomic_bool& cancelled) {
  QueryOutcome outcome;
  EvalContext ctx{bodies, registry, cancelled, {}, {}, outcome.diagnostics, {}};
  // Map every result sub-shape to its owning visible body once up front.
  for (const EvaluatedBody& body : bodies) {
    for (const TopAbs_ShapeEnum kind : {TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX}) {
      ShapeMap shapes;
      TopExp::MapShapes(body.shape, kind, shapes);
      for (int index = 1; index <= shapes.Extent(); ++index) {
        if (!ctx.shapeToBodyId.IsBound(shapes(index))) {
          ctx.shapeToBodyId.Bind(shapes(index), body.bodyId);
          ctx.shapeToBody.Bind(shapes(index), body.shape);
        }
      }
    }
  }

  outcome.entities = EvaluateToSet(ast, ctx, &outcome.stageCardinalities);
  CanonicalSort(outcome.entities);
  return outcome;
}

nlohmann::json ResolvedEntityToJson(const QueryEntity& entity) {
  const char* kindName = entity.kind == 'f' ? "face" : entity.kind == 'e' ? "edge" : "vertex";
  nlohmann::json json = {
      {"token", entity.token},
      {"kind", kindName},
      {"bodyId", entity.bodyId},
      {"centroid", PointJson(Centroid(entity.shape))},
  };
  if (entity.kind == 'f') {
    const TopoDS_Face face = TopoDS::Face(entity.shape);
    const std::string surfaceClass = SurfaceClass(face);
    json["area"] = FaceArea(face);
    json["surface"] = SurfaceEnum(surfaceClass);
    const std::optional<gp_Dir> outward = FaceOutwardNormal(face);
    if (outward.has_value())
      json["normal"] = DirJson(*outward);
    const BRepAdaptor_Surface surface(face, true);
    // SurfaceAxis (not the raw OCCT direction) so this query-path axis is
    // canonicalized identically to the evaluate_document topology harvest's
    // TopologyEntity.axis (geometry_measures.cpp) — the two are compared
    // directly by the desktop selection recorder's matchesEvidence, and a
    // raw-vs-canonical sign mismatch made it spuriously refuse the correct
    // entity for roughly half of all cylinder/cone faces.
    const Axis surfaceAxis = SurfaceAxis(face);
    if (surface.GetType() == GeomAbs_Cylinder) {
      json["radius"] = CylindricalFaceRadius(face);
      if (surfaceAxis.has_value())
        json["axis"] = {{"origin", PointJson(surface.Cylinder().Location())},
                        {"dir", AxisArrayJson(*surfaceAxis)}};
    } else if (surface.GetType() == GeomAbs_Cone) {
      json["radius"] = ConicalFaceReferenceRadius(face);
      if (surfaceAxis.has_value())
        json["axis"] = {{"origin", PointJson(surface.Cone().Location())},
                        {"dir", AxisArrayJson(*surfaceAxis)}};
    }
  } else if (entity.kind == 'e') {
    const TopoDS_Edge edge = TopoDS::Edge(entity.shape);
    const std::string curveClass = CurveClass(edge);
    json["length"] = EdgeLength(edge);
    json["curve"] = CurveEnum(curveClass);
    if (!BRep_Tool::Degenerated(edge)) {
      const BRepAdaptor_Curve curve(edge);
      // A projection is a live semantic reference, not a copied pair of
      // coordinates.  The renderer therefore receives a bounded, current
      // presentation sample from the same edge that the query resolved.  It
      // is deliberately optional wire evidence: it never participates in the
      // durable operation hash or native region lowering.
      const double first = curve.FirstParameter();
      const double last = curve.LastParameter();
      if (std::isfinite(first) && std::isfinite(last) && last > first) {
        const int segments = curve.GetType() == GeomAbs_Line ? 1 : 64;
        nlohmann::json samples = nlohmann::json::array();
        for (int index = 0; index <= segments; ++index) {
          const double parameter =
              first + (last - first) * static_cast<double>(index) / static_cast<double>(segments);
          samples.push_back(PointJson(curve.Value(parameter)));
        }
        json["samplePoints"] = std::move(samples);
      }
      // CurveAxis (see the cylinder/cone comment above) so line/circle/ellipse
      // edges get the SAME canonicalized axis the topology harvest emits —
      // previously only circle edges carried an axis at all here, so every
      // line/ellipse edge failed the desktop recorder's evidence match
      // unconditionally (axis undefined on this path, non-null on the other).
      const Axis curveAxis = CurveAxis(edge);
      if (curve.GetType() == GeomAbs_Circle) {
        json["radius"] = CircleEdgeRadius(edge);
        if (curveAxis.has_value())
          json["axis"] = {{"origin", PointJson(curve.Circle().Location())},
                          {"dir", AxisArrayJson(*curveAxis)}};
      } else if (curve.GetType() == GeomAbs_Line) {
        if (curveAxis.has_value())
          json["axis"] = {{"origin", PointJson(curve.Line().Location())},
                          {"dir", AxisArrayJson(*curveAxis)}};
      } else if (curve.GetType() == GeomAbs_Ellipse) {
        if (curveAxis.has_value())
          json["axis"] = {{"origin", PointJson(curve.Ellipse().Location())},
                          {"dir", AxisArrayJson(*curveAxis)}};
      }
    }
  }
  return json;
}

} // namespace aeth
