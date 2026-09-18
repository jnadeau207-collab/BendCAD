#include "mold_tooling_feature.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <limits>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include <BRepAlgoAPI_Check.hxx>
#include <BRepAlgoAPI_Cut.hxx>
#include <BRepAlgoAPI_Splitter.hxx>
#include <BRepBuilderAPI_MakeSolid.hxx>
#include <BRepBuilderAPI_MakeWire.hxx>
#include <BRepBuilderAPI_Sewing.hxx>
#include <BRepBuilderAPI_Transform.hxx>
#include <BRepCheck_Analyzer.hxx>
#include <BRepClass_FaceClassifier.hxx>
#include <BRepGProp.hxx>
#include <BRepOffsetAPI_MakeFilling.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakePrism.hxx>
#include <BRepTools.hxx>
#include <BRep_Builder.hxx>
#include <BRep_Tool.hxx>
#include <GProp_GProps.hxx>
#include <GeomAPI_ProjectPointOnSurf.hxx>
#include <GeomAbs_Shape.hxx>
#include <NCollection_DataMap.hxx>
#include <NCollection_IndexedDataMap.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <Precision.hxx>
#include <Standard_Failure.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopAbs_State.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Compound.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Shell.hxx>
#include <TopoDS_Solid.hxx>
#include <TopoDS_Wire.hxx>
#include <gp_Pnt.hxx>
#include <gp_Pnt2d.hxx>
#include <gp_Trsf.hxx>
#include <gp_Vec.hxx>

#include "body_pool.hpp"
#include "cancel.hpp"
#include "geometry_measures.hpp"
#include "naming_registry.hpp"
#include "topology_adjacency.hpp"

namespace aeth {
namespace {

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

constexpr double kMoldDegreesToRadians = 0.017453292519943295;

// --- Shared small helpers (this file's own local copies, matching the
// sheet_metal_feature.cpp/surfacing_feature.cpp precedent of declaring
// per-file helpers locally rather than reaching into another translation
// unit's anonymous namespace). ------------------------------------------

/// The unconsumed body produced by `operationId`, or null. Every operation
/// in this file reads bodies without consuming them (see this file's own
/// header comment for why) — the same peeked-snapshot lookup
/// surfacing_feature.cpp's own `FindVisibleBody` already uses.
const EvaluatedBody* FindVisibleBody(const std::vector<EvaluatedBody>& peeked,
                                     const std::string& operationId) {
  for (const EvaluatedBody& body : peeked) {
    if (body.operationId == operationId)
      return &body;
  }
  return nullptr;
}

/// Parses a `{x, y, z}` pull-direction object (NOT a tuple — the pinned
/// schema's own shape) into a normalized `gp_Dir`. Throws
/// `std::invalid_argument` on a non-finite or near-zero vector; `gp_Dir`'s
/// own constructor already normalizes, so no separate scale step is needed.
gp_Dir ParsePullDirection(const nlohmann::json& value) {
  const double x = value.at("x").get<double>();
  const double y = value.at("y").get<double>();
  const double z = value.at("z").get<double>();
  const gp_Vec raw(x, y, z);
  if (!(std::isfinite(x) && std::isfinite(y) && std::isfinite(z)) || raw.Magnitude() < 1e-9) {
    throw std::invalid_argument("mold pullDirection must be a finite, non-zero {x, y, z} vector");
  }
  return gp_Dir(raw);
}

/// Linear scan for the operation whose `"id"` equals `operationId` within
/// the full document `allOperations` array — the same by-id linear scan
/// `KernelServer::Query`'s own `atOperationId` lookup already uses
/// (server.cpp), just applied inside the kernel rather than at the RPC
/// layer. Null when not found (a caller-side invariant violation: a
/// reference already resolved to a live BODY produced by `operationId`
/// could not exist unless `operationId` itself was in this same array).
const nlohmann::json* FindOperationJson(const nlohmann::json& allOperations,
                                        const std::string& operationId) {
  for (const auto& candidate : allOperations) {
    if (candidate.at("id").get<std::string>() == operationId)
      return &candidate;
  }
  return nullptr;
}

/// Reads `partingLineOperationId`'s OWN authored `pullDirection` back out of
/// the full operations array — see mold_tooling_feature.hpp's own header
/// comment on `EvaluateMoldPartingSurface` for why this reach-back is
/// necessary and how it is wired in. `callerType` names the calling
/// operation type for the error message only.
gp_Dir ReadPullDirectionOfPartingLine(const nlohmann::json& allOperations,
                                      const std::string& partingLineOperationId,
                                      const char* callerType) {
  const nlohmann::json* partingLineOp = FindOperationJson(allOperations, partingLineOperationId);
  if (partingLineOp == nullptr) {
    throw std::runtime_error(std::string(callerType) +
                             " could not find its own referenced mold_parting_line operation " +
                             partingLineOperationId +
                             " in the evaluated document (internal inconsistency)");
  }
  if (partingLineOp->at("type").get<std::string>() != "mold_parting_line") {
    throw std::invalid_argument(std::string(callerType) +
                                " partingLineOperationId does not reference a mold_parting_line "
                                "operation");
  }
  return ParsePullDirection(partingLineOp->at("parameters").at("pullDirection"));
}

/// `mold_tooling_split`'s own transitive lookup: `partingSurfaceOperationId`
/// -> its own `partingLineOperationId` -> that operation's `pullDirection`.
/// One hop further than `ReadPullDirectionOfPartingLine`, reusing it once
/// the parting-surface operation's own JSON is found.
gp_Dir ReadPullDirectionTransitively(const nlohmann::json& allOperations,
                                     const std::string& partingSurfaceOperationId,
                                     const char* callerType) {
  const nlohmann::json* partingSurfaceOp =
      FindOperationJson(allOperations, partingSurfaceOperationId);
  if (partingSurfaceOp == nullptr) {
    throw std::runtime_error(std::string(callerType) +
                             " could not find its own referenced mold_parting_surface operation " +
                             partingSurfaceOperationId +
                             " in the evaluated document (internal inconsistency)");
  }
  if (partingSurfaceOp->at("type").get<std::string>() != "mold_parting_surface") {
    throw std::invalid_argument(std::string(callerType) +
                                " partingSurfaceOperationId does not reference a "
                                "mold_parting_surface operation");
  }
  const std::string partingLineOperationId =
      partingSurfaceOp->at("parameters").at("partingLineOperationId").get<std::string>();
  return ReadPullDirectionOfPartingLine(allOperations, partingLineOperationId, callerType);
}

/// Finishes a Mold-domain WIRE body (`mold_parting_line`'s only output kind)
/// — probe, then require validity. Declared locally for the same
/// cross-translation-unit reason surfacing_feature.cpp's own
/// `FinishSurfaceBody` states.
EvaluatedBody FinishMoldWireBody(const nlohmann::json& operation, TopoDS_Shape shape,
                                 const char* label) {
  if (shape.IsNull())
    throw std::runtime_error(std::string("OCCT produced a null ") + label);
  if (shape.ShapeType() != TopAbs_WIRE)
    throw std::runtime_error(std::string(label) + " must be a wire");
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operation.at("id").get<std::string>();
  body.shape = std::move(shape);
  body.probes = ProbeShape(body.shape);
  if (!body.probes.valid)
    throw std::runtime_error(std::string("OCCT produced an invalid ") + label);
  return body;
}

/// Finishes a Mold-domain OPEN SURFACE body (`mold_shutoff_surface`,
/// `mold_parting_surface`) — the exact `FinishSurfaceBody` contract
/// surfacing_feature.cpp already established (SHELL or FACE only), declared
/// locally for the same cross-translation-unit reason.
/// Finishes a Mold-domain OPEN SURFACE body (`mold_shutoff_surface`,
/// `mold_parting_surface`) — the `FinishSurfaceBody` contract
/// surfacing_feature.cpp already established (SHELL or FACE), WIDENED to
/// also accept a `TopoDS_COMPOUND` of shells: `SewIntoFreshShell`'s own
/// connectivity-grouping means a body capping/knitting several mutually
/// DISCONNECTED patches (independent hole caps; a shut-off that does not
/// touch the swept parting band) is genuinely, correctly, a compound of
/// disconnected surface patches — never forced into one artificially-glued
/// shell that would fail validity (see `SewIntoFreshShell`'s own doc
/// comment for the measured reason). `solidCount == 0` is checked either
/// way as a general sanity invariant for a SURFACE body regardless of
/// shape kind.
EvaluatedBody FinishMoldSurfaceBody(const nlohmann::json& operation, TopoDS_Shape shape,
                                    const char* label) {
  if (shape.IsNull())
    throw std::runtime_error(std::string("OCCT produced a null ") + label);
  const TopAbs_ShapeEnum kind = shape.ShapeType();
  if (kind != TopAbs_SHELL && kind != TopAbs_FACE && kind != TopAbs_COMPOUND) {
    throw std::runtime_error(std::string(label) +
                             " must be an open shell, a single face, or a compound of open "
                             "shells for a Mold-domain surface body, not another shape kind");
  }
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operation.at("id").get<std::string>();
  body.shape = std::move(shape);
  body.probes = ProbeShape(body.shape);
  if (!body.probes.valid)
    throw std::runtime_error(std::string("OCCT produced an invalid ") + label);
  if (body.probes.solidCount != 0) {
    throw std::runtime_error(std::string(label) +
                             " unexpectedly contains solid material for a Mold-domain surface "
                             "body");
  }
  return body;
}

/// Sews `shapes` together within `tolerance` (`BRepBuilderAPI_Sewing`) and
/// rebuilds a fresh result from every face of the sewn output, GROUPED BY
/// REAL CONNECTIVITY (faces sharing at least one edge, transitively): a
/// single `TopoDS_Shell` when every face lands in one connected component,
/// or a `TopoDS_COMPOUND` of one `TopoDS_Shell` per component otherwise.
///
/// MEASURED, not assumed (this file's own ctest caught it): a `TopoDS_Shell`
/// wrapping MUTUALLY DISCONNECTED faces fails `BRepCheck_Analyzer` outright
/// on this pinned OCCT build (a shell's own implicit "one connected patch of
/// surface" contract, enforced even with GeomChecks disabled) — even though
/// every individual face is itself perfectly valid. `stitch`'s own
/// rebuild-into-one-shell step (surfacing_feature.cpp's `EvaluateStitch`,
/// the precedent this helper was originally modeled on verbatim) is safe
/// ONLY because it first PROVES connectivity via `NbContigousEdges() > 0`
/// before ever reaching its own rebuild. This helper's own callers have no
/// such guarantee — `mold_shutoff_surface`'s own multiple independent hole
/// loops are NEVER mutually connected by construction (separate holes), and
/// `mold_parting_surface`'s optional shut-off is not generally adjacent to
/// the swept parting band either (the shut-off sits inside the part's own
/// silhouette; the parting band runs around its outer perimeter) — so this
/// helper verifies connectivity itself via a plain face-adjacency BFS
/// (`TopExp::MapShapesAndAncestors` on edges, the identical adjacency
/// `IncidentFacesOf`/`GroupEdgesIntoLoops` already walk) instead of assuming
/// its own inputs happen to touch.
///
/// `mold_tooling_split`'s own capped-cut-tool-solid step is the one
/// consumer that DOES require its result to already be one genuinely
/// connected, closed `TopoDS_Shell` (for `BRepBuilderAPI_MakeSolid`) — but
/// that requirement is enforced by ITS OWN `IsClosedShell` check
/// immediately afterward (topology-generic: it reads the same edge-incidence
/// census regardless of whether this helper handed back a Shell or a
/// Compound), so an improperly-closed shut-off still refuses correctly
/// there either way; only the genuinely single-component (Shell) case ever
/// reaches that call's own `TopoDS::Shell` cast.
TopoDS_Shape SewIntoFreshShell(const std::vector<TopoDS_Shape>& shapes, const double tolerance,
                               const std::atomic_bool& cancelled) {
  BRepBuilderAPI_Sewing sewing(tolerance);
  for (const TopoDS_Shape& shape : shapes)
    sewing.Add(shape);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    sewing.Perform(progress->Start());
  }
  CheckCancellation(cancelled);
  const TopoDS_Shape sewn = sewing.SewedShape();
  if (sewn.IsNull())
    throw Standard_Failure("mold tooling sew produced no result shape");
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> sewnFaces;
  TopExp::MapShapes(sewn, TopAbs_FACE, sewnFaces);
  if (sewnFaces.Extent() == 0)
    throw Standard_Failure("mold tooling sew produced no surface material");

  NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>, TopTools_ShapeMapHasher>
      edgeToFaces;
  TopExp::MapShapesAndAncestors(sewn, TopAbs_EDGE, TopAbs_FACE, edgeToFaces);

  // Plain BFS over face adjacency (two faces adjacent iff they share an
  // edge) to find connected components — the same adjacency
  // IncidentFacesOf/GroupEdgesIntoLoops already walk, applied to faces
  // instead of edges.
  const int faceCount = sewnFaces.Extent();
  std::vector<int> component(static_cast<std::size_t>(faceCount), -1);
  int componentCount = 0;
  std::vector<int> stack;
  for (int seed = 1; seed <= faceCount; ++seed) {
    if (component[static_cast<std::size_t>(seed - 1)] != -1)
      continue;
    stack.push_back(seed);
    component[static_cast<std::size_t>(seed - 1)] = componentCount;
    while (!stack.empty()) {
      const int current = stack.back();
      stack.pop_back();
      const TopoDS_Face currentFace = TopoDS::Face(sewnFaces(current));
      for (TopExp_Explorer explorer(currentFace, TopAbs_EDGE); explorer.More(); explorer.Next()) {
        const int edgeIndex = edgeToFaces.FindIndex(explorer.Current());
        if (edgeIndex == 0)
          continue;
        for (const TopoDS_Shape& neighbourFace : edgeToFaces.FindFromKey(explorer.Current())) {
          const int neighbourIndex = sewnFaces.FindIndex(neighbourFace);
          if (neighbourIndex == 0)
            continue;
          if (component[static_cast<std::size_t>(neighbourIndex - 1)] != -1)
            continue;
          component[static_cast<std::size_t>(neighbourIndex - 1)] = componentCount;
          stack.push_back(neighbourIndex);
        }
      }
    }
    ++componentCount;
  }

  BRep_Builder builder;
  std::vector<TopoDS_Shell> shells(static_cast<std::size_t>(componentCount));
  for (TopoDS_Shell& shell : shells)
    builder.MakeShell(shell);
  for (int index = 1; index <= faceCount; ++index) {
    builder.Add(shells[static_cast<std::size_t>(component[static_cast<std::size_t>(index - 1)])],
                TopoDS::Face(sewnFaces(index)));
  }
  if (componentCount == 1)
    return shells.front();
  TopoDS_Compound compound;
  builder.MakeCompound(compound);
  for (const TopoDS_Shell& shell : shells)
    builder.Add(compound, shell);
  return compound;
}

/// Whether every edge of `shape` is incident to EXACTLY two faces — the
/// manifold-closure test `stitch`'s own executor uses to decide solid vs.
/// open-surface finishing (surfacing_feature.cpp's `EvaluateStitch`),
/// reused verbatim.
bool IsClosedShell(const TopoDS_Shape& shape) {
  NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>, TopTools_ShapeMapHasher>
      edgeToFaces;
  TopExp::MapShapesAndAncestors(shape, TopAbs_EDGE, TopAbs_FACE, edgeToFaces);
  if (edgeToFaces.Extent() == 0)
    return false;
  for (int index = 1; index <= edgeToFaces.Extent(); ++index) {
    if (edgeToFaces(index).Extent() != 2)
      return false;
  }
  return true;
}

// --- ClassifyDraftFaces internals. ---------------------------------------

// A 5x5 grid of parametric-bounds fractions per face — finer than
// ComputeDihedralRange's 3-point EDGE sampling (geometry_measures.cpp)
// since a 2-D face needs real coverage to catch a genuinely curved/twisted
// surface's sign variation, not just a monotonic sweep along one parameter.
constexpr std::array<double, 5> kDraftSampleFractions = {0.1, 0.3, 0.5, 0.7, 0.9};

/// The [min, max] range of `dot(pullDirection, outwardNormal)` sampled
/// across `face`'s own TRIMMED extent. Grid samples landing outside the
/// trim (a non-rectangular loop within its UV bounding box — a real risk a
/// naive UV-fraction sample would silently mis-sample, unlike
/// ComputeDihedralRange's 1-D edge-fraction sampling, which has no analogous
/// off-curve failure mode) are filtered out via `BRepClass_FaceClassifier`.
/// Always returns at least one sample (the centroid fallback below
/// guarantees it), so the returned pair always satisfies first <= second.
std::pair<double, double> SampleFaceDraftRange(const TopoDS_Face& face,
                                               const gp_Dir& pullDirection) {
  double uMin = 0.0;
  double uMax = 0.0;
  double vMin = 0.0;
  double vMax = 0.0;
  BRepTools::UVBounds(face, uMin, uMax, vMin, vMax);

  double minDot = std::numeric_limits<double>::infinity();
  double maxDot = -std::numeric_limits<double>::infinity();
  int sampled = 0;
  for (const double uFraction : kDraftSampleFractions) {
    for (const double vFraction : kDraftSampleFractions) {
      const gp_Pnt2d uv(uMin + uFraction * (uMax - uMin), vMin + vFraction * (vMax - vMin));
      const BRepClass_FaceClassifier classifier(face, uv, Precision::Confusion());
      if (classifier.State() != TopAbs_IN && classifier.State() != TopAbs_ON)
        continue;
      gp_Dir normal;
      try {
        normal = OutwardNormalAtPoint(face, uv);
      } catch (const std::runtime_error&) {
        continue; // Undefined normal at this exact sample (e.g. a pole); skip, not fatal.
      }
      const double dot = pullDirection.Dot(normal);
      minDot = std::min(minDot, dot);
      maxDot = std::max(maxDot, dot);
      ++sampled;
    }
  }
  if (sampled > 0)
    return {minDot, maxDot};

  // Every grid sample fell outside the trim (a thin sliver face) or had an
  // undefined normal everywhere sampled: fall back to the face's own area
  // centroid, projected onto its surface — always well-defined for a
  // non-degenerate face with positive area.
  GProp_GProps properties;
  BRepGProp::SurfaceProperties(face, properties);
  const GeomAPI_ProjectPointOnSurf projector(properties.CentreOfMass(), BRep_Tool::Surface(face));
  if (!projector.IsDone() || projector.NbPoints() < 1)
    throw std::runtime_error("ClassifyDraftFaces could not sample any point on a face");
  double u = 0.0;
  double v = 0.0;
  projector.LowerDistanceParameters(u, v);
  const double dot = pullDirection.Dot(OutwardNormalAtPoint(face, gp_Pnt2d(u, v)));
  return {dot, dot};
}

} // namespace

std::vector<DraftFaceResult> ClassifyDraftFaces(const TopoDS_Shape& body,
                                                const gp_Dir& pullDirection,
                                                const double angleToleranceDeg) {
  if (!(std::isfinite(angleToleranceDeg) && angleToleranceDeg >= 0.0 &&
        angleToleranceDeg <= 30.0)) {
    throw std::invalid_argument("ClassifyDraftFaces angleToleranceDeg must be within [0, 30]");
  }
  // A face at EXACTLY angleToleranceDeg off vertical (measured from the
  // plane perpendicular to pullDirection) has |dot(normal, pull)| ==
  // sin(angleToleranceDeg): draftAngle == 90deg - angle(normal, pull), so
  // cos(angle(normal,pull)) == cos(90deg - draftAngle) == sin(draftAngle).
  const double band = std::sin(angleToleranceDeg * kMoldDegreesToRadians);

  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> faces;
  TopExp::MapShapes(body, TopAbs_FACE, faces);
  std::vector<DraftFaceResult> results;
  results.reserve(static_cast<std::size_t>(faces.Extent()));
  for (int index = 1; index <= faces.Extent(); ++index) {
    const TopoDS_Face face = TopoDS::Face(faces(index));
    const auto [minDot, maxDot] = SampleFaceDraftRange(face, pullDirection);
    const bool hasPositive = maxDot > band;
    const bool hasNegative = minDot < -band;
    DraftClassification classification;
    if (hasPositive && hasNegative) {
      // Mixed-sign always wins (ClassifyFromRange's own precedent,
      // geometry_measures.cpp): a face that spans both signs is
      // SolidWorks' "straddle" case regardless of how far each extreme
      // reaches beyond the tolerance band.
      classification = DraftClassification::Straddle;
    } else if (hasPositive) {
      classification = DraftClassification::Positive;
    } else if (hasNegative) {
      classification = DraftClassification::Negative;
    } else {
      classification = DraftClassification::NoDraft;
    }
    results.push_back({face, classification});
  }
  return results;
}

EvaluatedBody EvaluateMoldPartingLine(const nlohmann::json& operation, BodyPool& pool,
                                      ElementNameBook* elementNames, NamingRegistry* registry,
                                      const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const gp_Dir pullDirection = ParsePullDirection(parameters.at("pullDirection"));
  // The TS schema always materializes a default before the wire (per the
  // pinned contract); the kernel is still a trust boundary (shell's own
  // `direction` precedent, stitch's own `toleranceMm` precedent), so an
  // absent slot takes the documented 0.5deg fallback rather than throwing.
  const double toleranceDeg = parameters.value("draftAngleToleranceDeg", 0.5);
  if (!(std::isfinite(toleranceDeg) && toleranceDeg >= 0.0 && toleranceDeg <= 30.0)) {
    throw std::invalid_argument("mold_parting_line draftAngleToleranceDeg must be within [0, 30]");
  }

  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const EvaluatedBody* target = FindVisibleBody(peeked, targetOperationId);
  if (target == nullptr) {
    throw ReferenceMissing(operationId,
                           "mold_parting_line target references operation " + targetOperationId +
                               ", which is not an unconsumed body-producing operation earlier in "
                               "the document");
  }

  const auto refuse = [&](const std::string& message, const char* toolingCode,
                          nlohmann::json extraDetails = nlohmann::json::object()) -> void {
    nlohmann::json details = {{"toolingCode", toolingCode}};
    details.update(extraDetails);
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, details);
  };

  const std::vector<DraftFaceResult> classifications =
      ClassifyDraftFaces(target->shape, pullDirection, toleranceDeg);

  // Straddle check FIRST: a straddle face poisons the sign-based edge walk
  // wherever it sits on the body (this file's own header comment).
  for (const DraftFaceResult& result : classifications) {
    if (result.classification != DraftClassification::Straddle)
      continue;
    nlohmann::json extra = nlohmann::json::object();
    if (registry != nullptr) {
      const std::vector<std::string> tokens = registry->TokensOf(result.face);
      if (!tokens.empty())
        extra["faceToken"] = tokens.front();
    }
    refuse("mold_parting_line found a face whose draft varies across its own extent (SolidWorks' "
           "\"straddle face\" case); the parting line cannot be found through edges alone here -- "
           "split this face manually first",
           "E_PARTING_LINE_STRADDLE_FACE", extra);
  }

  // Face -> sign lookup (Positive/Negative only; NoDraft/Straddle never
  // qualify a candidate edge on their own).
  NCollection_DataMap<TopoDS_Shape, DraftClassification, TopTools_ShapeMapHasher> signOf;
  for (const DraftFaceResult& result : classifications)
    signOf.Bind(result.face, result.classification);

  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> allEdges;
  TopExp::MapShapes(target->shape, TopAbs_EDGE, allEdges);
  std::vector<TopoDS_Edge> candidates;
  for (int index = 1; index <= allEdges.Extent(); ++index) {
    const TopoDS_Edge edge = TopoDS::Edge(allEdges(index));
    const std::vector<TopoDS_Face> incident = IncidentFacesOf(target->shape, edge);
    if (incident.size() != 2)
      continue;
    const DraftClassification* first = signOf.Seek(incident[0]);
    const DraftClassification* second = signOf.Seek(incident[1]);
    if (first == nullptr || second == nullptr)
      continue;
    const bool opposite =
        (*first == DraftClassification::Positive && *second == DraftClassification::Negative) ||
        (*first == DraftClassification::Negative && *second == DraftClassification::Positive);
    if (opposite)
      candidates.push_back(edge);
  }

  if (candidates.empty()) {
    refuse("mold_parting_line found no adjacent faces of opposite draft sign for this pull "
           "direction; every face may be the same sign here (nothing to split), or this pull "
           "direction is degenerate for this body",
           "E_PARTING_LINE_NO_DRAFT_VARIATION");
  }

  std::vector<std::vector<TopoDS_Edge>> loops;
  try {
    loops = GroupEdgesIntoLoops(candidates);
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("mold_parting_line's candidate edges do not resolve into a single simple closed loop",
           "E_PARTING_LINE_MULTIPLE_LOOPS");
  }
  if (loops.size() != 1) {
    refuse("mold_parting_line found " + std::to_string(loops.size()) +
               " independent closed loop(s) of sign-changing edges; v1 handles only a single "
               "outer loop",
           "E_PARTING_LINE_MULTIPLE_LOOPS");
  }

  BRepBuilderAPI_MakeWire wireMaker;
  for (const TopoDS_Edge& edge : loops.front())
    wireMaker.Add(edge);
  CheckCancellation(cancelled);
  if (!wireMaker.IsDone())
    throw std::runtime_error("mold_parting_line could not assemble its loop into a wire");

  EvaluatedBody body = FinishMoldWireBody(operation, wireMaker.Wire(), "mold_parting_line result");

  if (elementNames != nullptr) {
    // Mints fresh — see this file's header comment. The wire's edges are
    // literally the target's own (never copied — see this function's own
    // edge collection above, which reads TopoDS_Edge values straight out of
    // the target's own TopExp::MapShapes census), so AddDerivedPrimitive
    // PRESERVES their existing names/tokens (its own doc comment); only the
    // wire-as-a-body is new, and a wire has no faces to mint besides its
    // (already-named) edges/vertices.
    elementNames->AddDerivedPrimitive(operationId, body.shape);
  }
  (void)registry; // No registry harvest — see this file's header comment.
  return body;
}

EvaluatedBody EvaluateMoldShutoffSurface(const nlohmann::json& operation, BodyPool& pool,
                                         ElementNameBook* elementNames, NamingRegistry* registry,
                                         const std::atomic_bool& cancelled) {
  (void)registry; // No registry harvest — see this file's header comment.
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const std::string partingLineOperationId =
      parameters.at("partingLineOperationId").get<std::string>();

  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const EvaluatedBody* target = FindVisibleBody(peeked, targetOperationId);
  if (target == nullptr) {
    throw ReferenceMissing(operationId,
                           "mold_shutoff_surface target references operation " + targetOperationId +
                               ", which is not an unconsumed body-producing operation earlier in "
                               "the document");
  }
  const EvaluatedBody* partingLine = FindVisibleBody(peeked, partingLineOperationId);
  if (partingLine == nullptr) {
    throw ReferenceMissing(operationId, "mold_shutoff_surface partingLineOperationId references "
                                        "operation " +
                                            partingLineOperationId +
                                            ", which is not an unconsumed body-producing "
                                            "operation earlier in the document");
  }

  // The operation's ONE typed refusal code, covering every way capping the
  // target's holes can fail — mirrors `stitch`'s own single-code precedent
  // (E_STITCH_NO_COMMON_BOUNDARY, surfacing_feature.cpp).
  const auto refuse = [&](const std::string& message) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message,
                           {{"toolingCode", "E_SHUTOFF_NO_HOLES"}});
  };

  const std::vector<TopoDS_Edge> freeEdges = FreeEdgesOf(target->shape);
  if (freeEdges.empty()) {
    refuse("mold_shutoff_surface target has no free-boundary loops to cap; it has no "
           "through-holes or open boundary for this parting line");
  }

  std::vector<std::vector<TopoDS_Edge>> loops;
  try {
    loops = GroupEdgesIntoLoops(freeEdges);
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("mold_shutoff_surface target's free-boundary edges do not resolve into simple closed "
           "loops");
  }

  // Exclusion test: a loop IS the parting line iff its edge SET is exactly
  // the parting-line body's own edges, by IsSame identity — sound and exact
  // because mold_parting_line never copies the target's edges into its wire
  // (see EvaluateMoldPartingLine's own comment).
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> partingLineEdges;
  TopExp::MapShapes(partingLine->shape, TopAbs_EDGE, partingLineEdges);
  const auto isPartingLineLoop = [&](const std::vector<TopoDS_Edge>& loop) {
    if (static_cast<int>(loop.size()) != partingLineEdges.Extent())
      return false;
    for (const TopoDS_Edge& edge : loop) {
      if (partingLineEdges.FindIndex(edge) == 0)
        return false;
    }
    return true;
  };

  std::vector<TopoDS_Shape> caps;
  for (const std::vector<TopoDS_Edge>& loop : loops) {
    if (isPartingLineLoop(loop))
      continue;
    // BRepOffsetAPI_MakeFilling: boundary_surface's own proven per-edge
    // Add(edge, GeomAbs_C0) pattern (surfacing_feature.cpp) — this pinned
    // OCCT has no Add(TopoDS_Wire) overload at all.
    BRepOffsetAPI_MakeFilling filling;
    for (const TopoDS_Edge& edge : loop)
      filling.Add(edge, GeomAbs_C0);
    {
      const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
      try {
        filling.Build(progress->Start());
      } catch (const Standard_Failure&) {
        CheckCancellation(cancelled);
        refuse("mold_shutoff_surface could not fit a cap surface to one of the target's hole "
               "loops");
      }
    }
    CheckCancellation(cancelled);
    if (!filling.IsDone()) {
      refuse("mold_shutoff_surface could not fit a cap surface to one of the target's hole "
             "loops");
    }
    const TopoDS_Shape result = filling.Shape();
    if (result.IsNull() || result.ShapeType() != TopAbs_FACE) {
      refuse("mold_shutoff_surface did not produce a single face for one of the target's hole "
             "loops");
    }
    if (!BRepCheck_Analyzer(result, false).IsValid()) {
      refuse("mold_shutoff_surface produced an invalid cap face for one of the target's hole "
             "loops");
    }
    caps.push_back(result);
  }

  if (caps.empty()) {
    refuse("every free-boundary loop on mold_shutoff_surface's target is the parting line "
           "itself; there are no through-holes to cap");
  }

  // Combine via Sew — these caps are disjoint (one per hole, never
  // touching), the SAME idiom `stitch`'s own executor already uses to knit
  // unrelated faces into one body (surfacing_feature.cpp), reused.
  TopoDS_Shape shell;
  try {
    shell = SewIntoFreshShell(caps, 1e-6, cancelled);
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("mold_shutoff_surface could not combine its cap faces into one surface body");
  }

  EvaluatedBody body = FinishMoldSurfaceBody(operation, shell, "mold_shutoff_surface result");
  if (elementNames != nullptr) {
    // Mints fresh — see this file's header comment. Each cap's own boundary
    // edges are the target's own (already named); AddDerivedPrimitive
    // preserves them and mints only the new interior fill material.
    elementNames->AddDerivedPrimitive(operationId, body.shape);
  }
  return body;
}

EvaluatedBody EvaluateMoldPartingSurface(const nlohmann::json& operation,
                                         const nlohmann::json& allOperations, BodyPool& pool,
                                         ElementNameBook* elementNames, NamingRegistry* registry,
                                         const std::atomic_bool& cancelled) {
  (void)registry; // No registry harvest — see this file's header comment.
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string partingLineOperationId =
      parameters.at("partingLineOperationId").get<std::string>();
  const double extensionDistanceMm = parameters.at("extensionDistanceMm").get<double>();
  if (!(std::isfinite(extensionDistanceMm) && extensionDistanceMm > 0.0)) {
    throw std::invalid_argument(
        "mold_parting_surface extensionDistanceMm must be a positive finite number");
  }
  const bool hasShutoff = parameters.contains("shutoffSurfaceOperationId") &&
                          !parameters.at("shutoffSurfaceOperationId").is_null();
  std::string shutoffSurfaceOperationId;
  if (hasShutoff)
    shutoffSurfaceOperationId = parameters.at("shutoffSurfaceOperationId").get<std::string>();

  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const EvaluatedBody* partingLine = FindVisibleBody(peeked, partingLineOperationId);
  if (partingLine == nullptr) {
    throw ReferenceMissing(operationId, "mold_parting_surface partingLineOperationId references "
                                        "operation " +
                                            partingLineOperationId +
                                            ", which is not an unconsumed body-producing "
                                            "operation earlier in the document");
  }
  if (partingLine->shape.ShapeType() != TopAbs_WIRE) {
    throw std::invalid_argument(
        "mold_parting_surface partingLineOperationId does not reference a wire body");
  }
  const EvaluatedBody* shutoff = nullptr;
  if (hasShutoff) {
    shutoff = FindVisibleBody(peeked, shutoffSurfaceOperationId);
    if (shutoff == nullptr) {
      throw ReferenceMissing(operationId, "mold_parting_surface shutoffSurfaceOperationId "
                                          "references operation " +
                                              shutoffSurfaceOperationId +
                                              ", which is not an unconsumed body-producing "
                                              "operation earlier in the document");
    }
  }

  const gp_Dir pullDirection =
      ReadPullDirectionOfPartingLine(allOperations, partingLineOperationId, "mold_parting_surface");

  const auto refuse = [&](const std::string& message) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message,
                           {{"toolingCode", "E_PARTING_SURFACE_SELF_INTERSECTS"}});
  };

  const TopoDS_Wire wire = TopoDS::Wire(partingLine->shape);
  const gp_Vec sweep(pullDirection.XYZ() * extensionDistanceMm);

  // Translate the wire BACKWARD by `sweep`, then extrude by `2 * sweep` in
  // ONE call — the swept shell's near/far faces land at
  // -extensionDistanceMm/+extensionDistanceMm from the ORIGINAL wire with NO
  // internal seam to re-sew (see this file's own header comment for why this
  // beats two independent opposite-direction sweeps glued back together).
  gp_Trsf toStart;
  toStart.SetTranslation(-sweep);
  const TopoDS_Shape startWire = BRepBuilderAPI_Transform(wire, toStart, /*Copy=*/true).Shape();

  TopoDS_Shape sweptShell;
  {
    // BRepPrimAPI_MakePrism on a bare TopoDS_Wire — see this file's ctest
    // spike (mold_tooling_test.cpp) proving this produces a usable open
    // shell on this pinned OCCT build.
    BRepPrimAPI_MakePrism prism(startWire, gp_Vec(sweep.XYZ() * 2.0), /*Copy=*/true);
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    try {
      prism.Build(progress->Start());
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      refuse("mold_parting_surface's extrusion failed; the parting line may be too irregular "
             "for this extension distance");
    }
    CheckCancellation(cancelled);
    if (!prism.IsDone()) {
      refuse("mold_parting_surface's extrusion failed; the parting line may be too irregular "
             "for this extension distance");
    }
    sweptShell = prism.Shape();
  }
  if (sweptShell.IsNull() ||
      (sweptShell.ShapeType() != TopAbs_SHELL && sweptShell.ShapeType() != TopAbs_FACE)) {
    refuse("mold_parting_surface's extrusion did not produce an open surface");
  }

  TopoDS_Shape result = sweptShell;
  if (hasShutoff) {
    // Knit in the shut-off surface — the same Sew idiom
    // mold_shutoff_surface's own combine step uses, reused.
    try {
      result = SewIntoFreshShell({sweptShell, shutoff->shape}, 1e-6, cancelled);
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      refuse("mold_parting_surface could not knit the shut-off surface into the swept parting "
             "surface");
    }
  }

  if (!BRepCheck_Analyzer(result, false).IsValid()) {
    refuse("mold_parting_surface produced an invalid surface for this extension distance");
  }
  {
    // Geometric (not merely topological) self-intersection test — the
    // `thicken` precedent (surfacing_feature.cpp) for a primitive whose own
    // construction does not already guarantee non-self-overlap.
    CheckCancellation(cancelled);
    BRepAlgoAPI_Check selfIntersectionCheck(result, /*bTestSE=*/true, /*bTestSI=*/true);
    if (!selfIntersectionCheck.IsValid())
      refuse("mold_parting_surface's extrusion self-intersects for this extension distance");
  }

  EvaluatedBody body = FinishMoldSurfaceBody(operation, result, "mold_parting_surface result");
  if (elementNames != nullptr) {
    // Mints fresh — see this file's header comment. The swept side walls
    // are entirely new sub-shapes with no existing identity to inherit.
    elementNames->AddDerivedPrimitive(operationId, body.shape);
  }
  return body;
}

std::vector<EvaluatedBody> EvaluateMoldToolingSplit(const nlohmann::json& operation,
                                                    const nlohmann::json& allOperations,
                                                    BodyPool& pool, ElementNameBook* elementNames,
                                                    NamingRegistry* registry,
                                                    const std::atomic_bool& cancelled) {
  (void)registry; // No registry harvest — see this file's header comment.
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const std::string partingSurfaceOperationId =
      parameters.at("partingSurfaceOperationId").get<std::string>();
  const bool hasShutoff = parameters.contains("shutoffSurfaceOperationId") &&
                          !parameters.at("shutoffSurfaceOperationId").is_null();
  std::string shutoffSurfaceOperationId;
  if (hasShutoff)
    shutoffSurfaceOperationId = parameters.at("shutoffSurfaceOperationId").get<std::string>();

  const auto& block = parameters.at("block");
  const double marginX = block.at("marginXMm").get<double>();
  const double marginY = block.at("marginYMm").get<double>();
  const double marginZ = block.at("marginZMm").get<double>();
  if (!(std::isfinite(marginX) && marginX >= 0.0 && std::isfinite(marginY) && marginY >= 0.0 &&
        std::isfinite(marginZ) && marginZ >= 0.0)) {
    throw std::invalid_argument("mold_tooling_split block margins must be finite and non-negative");
  }

  std::vector<std::string> extraSplitSurfaceOperationIds;
  if (parameters.contains("extraSplitSurfaceOperationIds")) {
    for (const auto& entry : parameters.at("extraSplitSurfaceOperationIds"))
      extraSplitSurfaceOperationIds.push_back(entry.get<std::string>());
  }
  if (extraSplitSurfaceOperationIds.size() > 16) {
    throw std::invalid_argument(
        "mold_tooling_split extraSplitSurfaceOperationIds must contain at most 16 entries");
  }

  const std::string outputBodyId = operation.at("outputBodyId").get<std::string>();
  const nlohmann::json& outputBodyIdsJson = operation.at("outputBodyIds");
  if (!outputBodyIdsJson.is_array() || outputBodyIdsJson.size() < 2 ||
      outputBodyIdsJson.size() > 64) {
    throw std::invalid_argument(
        "mold_tooling_split requires outputBodyIds with between two and 64 entries");
  }
  std::vector<std::string> outputBodyIds;
  for (const auto& id : outputBodyIdsJson)
    outputBodyIds.push_back(id.get<std::string>());
  if (outputBodyIds.front() != outputBodyId) {
    throw std::invalid_argument(
        "mold_tooling_split's outputBodyIds[0] must match outputBodyId (the core body)");
  }
  const std::size_t expectedSolidCount = 2 + extraSplitSurfaceOperationIds.size();
  if (outputBodyIds.size() != expectedSolidCount) {
    throw std::invalid_argument("mold_tooling_split's outputBodyIds must have exactly 2 + "
                                "extraSplitSurfaceOperationIds.length entries");
  }

  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const auto require = [&](const std::string& refId, const char* role) -> const EvaluatedBody& {
    const EvaluatedBody* found = FindVisibleBody(peeked, refId);
    if (found == nullptr) {
      throw ReferenceMissing(operationId, std::string("mold_tooling_split ") + role +
                                              " references operation " + refId +
                                              ", which is not an unconsumed body-producing "
                                              "operation earlier in the document");
    }
    return *found;
  };
  const EvaluatedBody& target = require(targetOperationId, "target");
  const EvaluatedBody& partingSurface =
      require(partingSurfaceOperationId, "partingSurfaceOperationId");
  const EvaluatedBody* shutoff =
      hasShutoff ? &require(shutoffSurfaceOperationId, "shutoffSurfaceOperationId") : nullptr;
  std::vector<const EvaluatedBody*> extraSplitSurfaces;
  extraSplitSurfaces.reserve(extraSplitSurfaceOperationIds.size());
  for (const std::string& refId : extraSplitSurfaceOperationIds)
    extraSplitSurfaces.push_back(&require(refId, "extraSplitSurfaceOperationIds"));

  const gp_Dir pullDirection =
      ReadPullDirectionTransitively(allOperations, partingSurfaceOperationId, "mold_tooling_split");

  const auto refuse = [&](const std::string& message, const char* toolingCode) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, {{"toolingCode", toolingCode}});
  };

  // --- Step 1: capped cut-tool solid. --------------------------------------
  TopoDS_Shape cutTool;
  if (hasShutoff) {
    TopoDS_Shape shell;
    try {
      shell = SewIntoFreshShell({target.shape, shutoff->shape}, 1e-6, cancelled);
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      refuse("mold_tooling_split could not sew the part and the shut-off surface into one "
             "closed cap-tool solid",
             "E_TOOLING_SPLIT_CAP_TOOL_NOT_CLOSED");
    }
    if (!IsClosedShell(shell)) {
      refuse("mold_tooling_split's capped cut-tool did not close into a solid; the shut-off "
             "surface may not fully meet the part's own boundary",
             "E_TOOLING_SPLIT_CAP_TOOL_NOT_CLOSED");
    }
    BRepBuilderAPI_MakeSolid solidMaker(TopoDS::Shell(shell));
    if (!solidMaker.IsDone() || !BRepCheck_Analyzer(solidMaker.Shape(), false).IsValid()) {
      refuse("mold_tooling_split's capped cut-tool could not be converted into a valid solid",
             "E_TOOLING_SPLIT_CAP_TOOL_NOT_CLOSED");
    }
    cutTool = solidMaker.Shape();
  } else {
    if (!FreeEdgesOf(target.shape).empty()) {
      // Real shut-offs exist so the two mold halves PINCH at a through-hole
      // instead of the hole tunneling all the way through the block — see
      // this file's own header comment.
      refuse("mold_tooling_split's part has an open boundary (a through-hole relative to the "
             "parting line) but no shutoffSurfaceOperationId was given; cutting with an unsewn "
             "part would tunnel the hole through both mold halves -- reference a "
             "mold_shutoff_surface first",
             "E_TOOLING_SPLIT_CAP_TOOL_NOT_CLOSED");
    }
    cutTool = target.shape;
  }

  // --- Step 2: tooling block. -----------------------------------------------
  const ShapeProbes& targetProbes = target.probes;
  const gp_Pnt blockMin(targetProbes.bounds[0] - marginX, targetProbes.bounds[1] - marginY,
                        targetProbes.bounds[2] - marginZ);
  const gp_Pnt blockMax(targetProbes.bounds[3] + marginX, targetProbes.bounds[4] + marginY,
                        targetProbes.bounds[5] + marginZ);
  TopoDS_Shape block3d;
  {
    // BRepPrimAPI_MakeBox — the same primitive class geometry.cpp's own
    // create_box path (EvaluateBox) uses; EvaluateBox itself lives in
    // geometry.cpp's anonymous namespace (no header declares it, confirmed
    // before writing this file), so this executor calls the class directly
    // rather than reconstructing a synthetic create_box JSON operation.
    BRepPrimAPI_MakeBox blockMaker;
    blockMaker.Init(blockMin, blockMax);
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    blockMaker.Build(progress->Start());
    CheckCancellation(cancelled);
    if (!blockMaker.IsDone())
      throw std::runtime_error("mold_tooling_split could not build the tooling block");
    block3d = blockMaker.Shape();
  }

  // --- Step 3: cut. -----------------------------------------------------------
  TopoDS_Shape cutResult;
  {
    BRepAlgoAPI_Cut cut;
    NCollection_List<TopoDS_Shape> objects;
    objects.Append(block3d);
    NCollection_List<TopoDS_Shape> tools;
    tools.Append(cutTool);
    cut.SetArguments(objects);
    cut.SetTools(tools);
    cut.SetRunParallel(false);
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    cut.Build(progress->Start());
    CheckCancellation(cancelled);
    if (!cut.IsDone()) {
      throw std::runtime_error(
          "mold_tooling_split could not cut the part's cavity from the tooling block");
    }
    cutResult = cut.Shape();
  }

  // --- Step 4: split. ----------------------------------------------------------
  NCollection_List<TopoDS_Shape> splitTools;
  splitTools.Append(partingSurface.shape);
  for (const EvaluatedBody* extra : extraSplitSurfaces)
    splitTools.Append(extra->shape);

  TopoDS_Shape splitResult;
  {
    // BRepAlgoAPI_Splitter — this file's own ctest spike proves a correct
    // multi-solid split from a genuinely NON-PLANAR shell tool on this
    // pinned OCCT build (mutation.cpp's own RunPlanarSplitIntoHistory, the
    // only other user of this class in this codebase, only ever exercises a
    // PLANAR face tool).
    BRepAlgoAPI_Splitter splitter;
    NCollection_List<TopoDS_Shape> splitObjects;
    splitObjects.Append(cutResult);
    splitter.SetArguments(splitObjects);
    splitter.SetTools(splitTools);
    splitter.SetRunParallel(false);
    splitter.SetToFillHistory(true);
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    splitter.Build(progress->Start());
    CheckCancellation(cancelled);
    if (splitter.HasErrors())
      throw std::runtime_error("mold_tooling_split's splitter failed");
    splitResult = splitter.Shape();
    if (splitResult.IsNull())
      throw std::runtime_error("mold_tooling_split's splitter produced no result");
  }

  std::vector<TopoDS_Shape> solids;
  for (TopExp_Explorer explorer(splitResult, TopAbs_SOLID); explorer.More(); explorer.Next())
    solids.push_back(explorer.Current());

  if (solids.size() != expectedSolidCount) {
    refuse("mold_tooling_split's splitter yielded " + std::to_string(solids.size()) +
               " solid(s), expected exactly " + std::to_string(expectedSolidCount) +
               " (2 + the number of extra split surfaces)",
           "E_TOOLING_SPLIT_WRONG_SOLID_COUNT");
  }

  // --- Step 5: explode + assign role. -------------------------------------------
  // Reference point along the pull axis: the parting surface's OWN centroid
  // — by the symmetric (+/-extensionDistanceMm) construction of
  // mold_parting_surface, this sits at exactly the parting LINE's own
  // pull-axis position, without a second peeked-body lookup.
  const gp_Vec partingSurfaceCentroid(partingSurface.probes.centerOfMass[0],
                                      partingSurface.probes.centerOfMass[1],
                                      partingSurface.probes.centerOfMass[2]);
  const double referenceProjection = gp_Vec(pullDirection.XYZ()).Dot(partingSurfaceCentroid);

  struct RoleAssignment final {
    TopoDS_Shape shape;
    ShapeProbes probes;
    double projection{};
  };
  std::vector<RoleAssignment> assignments;
  assignments.reserve(solids.size());
  for (const TopoDS_Shape& solid : solids) {
    ShapeProbes probes = ProbeShape(solid);
    if (!probes.valid)
      throw std::runtime_error("mold_tooling_split produced an invalid solid");
    const gp_Vec centroid(probes.centerOfMass[0], probes.centerOfMass[1], probes.centerOfMass[2]);
    const double projection = gp_Vec(pullDirection.XYZ()).Dot(centroid);
    assignments.push_back({solid, probes, projection});
  }

  // Core/cavity: the LARGEST-volume solid on each side of the parting
  // surface (moldmaking's own common case — the bulk core/cavity block is
  // the largest piece on its side; any smaller piece sharing that side is
  // an insert carved out of it). Pull-direction-POSITIVE centroid is
  // "cavity" (the mold half the pull direction points OUT of — a
  // DEFINITION this catalog states plainly, mirroring `unfold`'s own
  // honesty about its kFactor default rather than asserting a universal
  // moldmaking convention); negative is "core".
  std::size_t coreIndex = assignments.size();
  std::size_t cavityIndex = assignments.size();
  for (std::size_t index = 0; index < assignments.size(); ++index) {
    const bool isCavitySide = assignments[index].projection > referenceProjection;
    std::size_t& chosen = isCavitySide ? cavityIndex : coreIndex;
    if (chosen == assignments.size() ||
        assignments[index].probes.volume > assignments[chosen].probes.volume) {
      chosen = index;
    }
  }
  if (coreIndex == assignments.size() || cavityIndex == assignments.size()) {
    throw std::runtime_error("mold_tooling_split could not find both a core-side and a "
                             "cavity-side solid relative to the parting surface (internal "
                             "inconsistency)");
  }

  // Every remaining solid is an "insert". ORDERING CAVEAT (a documented,
  // honest v1 gap — see this file's header comment): the pinned schema's
  // own intent is author-controlled ordering by extraSplitSurfaceOperationIds
  // array position, but BRepAlgoAPI_Splitter's own multi-tool History() does
  // not expose "which tool argument produced this solid" in a form this v1
  // resolves; with more than one insert this falls back to a real,
  // deterministic, but SIZE-based heuristic (descending volume) rather than
  // true per-tool provenance. With exactly one insert (the common case)
  // there is no ambiguity at all: only one non-core/cavity solid exists.
  std::vector<std::size_t> insertIndices;
  for (std::size_t index = 0; index < assignments.size(); ++index) {
    if (index != coreIndex && index != cavityIndex)
      insertIndices.push_back(index);
  }
  std::stable_sort(insertIndices.begin(), insertIndices.end(),
                   [&assignments](const std::size_t left, const std::size_t right) {
                     return assignments[left].probes.volume > assignments[right].probes.volume;
                   });

  std::vector<EvaluatedBody> born;
  born.reserve(assignments.size());
  const auto makeBody = [&born, &assignments, operationId](const std::size_t assignmentIndex,
                                                           const std::string& bodyId) {
    EvaluatedBody body;
    body.bodyId = bodyId;
    body.operationId = operationId;
    body.outputIndex = static_cast<int>(born.size());
    body.shape = assignments[assignmentIndex].shape;
    body.probes = assignments[assignmentIndex].probes;
    return body;
  };
  born.push_back(makeBody(coreIndex, outputBodyIds[0]));
  born.push_back(makeBody(cavityIndex, outputBodyIds[1]));
  for (std::size_t k = 0; k < insertIndices.size(); ++k)
    born.push_back(makeBody(insertIndices[k], outputBodyIds[2 + k]));

  if (elementNames != nullptr) {
    // Mints each output body fresh, ONE call per body under the SAME
    // operationId — the import_step/EvaluateImportStepBodies multi-solid
    // birth precedent (geometry.cpp's own produceRoot, called once per
    // solid, same operationId every time), NOT unfold's registry-gated
    // HarvestCopiedBody shape — see this file's own header comment for the
    // full account of why this operation's shape matches import_step's,
    // not unfold's.
    for (const EvaluatedBody& body : born)
      elementNames->AddDerivedPrimitive(operationId, body.shape);
  }
  return born;
}

} // namespace aeth
