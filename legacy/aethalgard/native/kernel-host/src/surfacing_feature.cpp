#include "surfacing_feature.hpp"

#include <cmath>
#include <cstddef>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepAlgoAPI_Check.hxx>
#include <BRepBuilderAPI_MakeSolid.hxx>
#include <BRepBuilderAPI_Sewing.hxx>
#include <BRepCheck_Analyzer.hxx>
#include <BRepGProp.hxx>
#include <BRepLib.hxx>
#include <BRepOffsetAPI_MakeFilling.hxx>
#include <BRepOffsetAPI_MakeOffsetShape.hxx>
#include <BRepOffsetAPI_MakeThickSolid.hxx>
#include <BRepOffset_Mode.hxx>
#include <BRep_Builder.hxx>
#include <BRep_Tool.hxx>
#include <GProp_GProps.hxx>
#include <GeomAbs_JoinType.hxx>
#include <GeomAbs_Shape.hxx>
#include <NCollection_IndexedDataMap.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <Standard_Failure.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shell.hxx>
#include <TopoDS_Solid.hxx>
#include <TopoDS_Vertex.hxx>

#include "body_pool.hpp"
#include "cancel.hpp"
#include "naming_registry.hpp"

namespace aeth {
namespace {

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

/// The unconsumed body produced by `operationId`, or null. Every op in this
/// file that references a body without consuming it (boundary_surface's
/// target) or must inspect a target's STORED probes before deciding whether
/// to consume it (surface_offset/thicken's solidCount refusal) uses this —
/// the same peeked-snapshot lookup EvaluateMirror's merge:false path and
/// EvaluateEdgeFlange's own target-body check already use inline.
const EvaluatedBody* FindVisibleBody(const std::vector<EvaluatedBody>& peeked,
                                     const std::string& operationId) {
  for (const EvaluatedBody& body : peeked) {
    if (body.operationId == operationId)
      return &body;
  }
  return nullptr;
}

/// Finishes a Surfacing-domain OPEN body: skips `BRepLib::OrientClosedSolid`
/// (there is no enclosed volume to orient), accepts only `TopAbs_SHELL` or
/// `TopAbs_FACE` — the two OCCT shapes an "open surface" can legitimately be
/// in this codebase — and refuses anything else (a bare wire/edge/compound
/// would mean this file's own construction went wrong, never a case to paper
/// over). Otherwise identical to geometry.cpp's `FinishSolidBody`: probe,
/// then require validity. Declared locally rather than shared cross-
/// translation-unit, the same precedent sheet_metal_feature.cpp's own local
/// `SingleValidSolid` sets against reaching into geometry.cpp's anonymous
/// namespace.
EvaluatedBody FinishSurfaceBody(const nlohmann::json& operation, TopoDS_Shape shape,
                                const char* label) {
  if (shape.IsNull())
    throw std::runtime_error(std::string("OCCT produced a null ") + label);
  const TopAbs_ShapeEnum kind = shape.ShapeType();
  if (kind != TopAbs_SHELL && kind != TopAbs_FACE) {
    throw std::runtime_error(std::string(label) +
                             " must be an open shell or a single face for a Surfacing-domain "
                             "body, not another shape kind");
  }
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operation.at("id").get<std::string>();
  body.shape = std::move(shape);
  body.probes = ProbeShape(body.shape);
  if (!body.probes.valid)
    throw std::runtime_error(std::string("OCCT produced an invalid ") + label);
  return body;
}

/// Finishes a Surfacing-domain SOLID body (stitch's fully-closed outcome,
/// thicken's only outcome): the `FinishSolidBody` steps (OrientClosedSolid,
/// probe, validity) reproduced locally for the same cross-translation-unit
/// reason as `FinishSurfaceBody` above.
EvaluatedBody FinishThickenedSolidBody(const nlohmann::json& operation, const TopoDS_Shape& shape,
                                       const char* label) {
  if (shape.IsNull() || shape.ShapeType() != TopAbs_SOLID)
    throw std::runtime_error(std::string(label) + " did not produce a solid body");
  TopoDS_Solid solid = TopoDS::Solid(shape);
  BRepLib::OrientClosedSolid(solid);
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operation.at("id").get<std::string>();
  body.shape = solid;
  body.probes = ProbeShape(body.shape);
  if (!body.probes.valid)
    throw std::runtime_error(std::string("OCCT produced an invalid ") + label);
  return body;
}

/// Every edge of `shape` incident to EXACTLY one face — the standard
/// manifold free-boundary definition (sheet_metal_feature.cpp's
/// IncidentFacesOf/EndNeedsRelief walk the identical MapShapesAndAncestors
/// adjacency for the same purpose).
std::vector<TopoDS_Edge> FreeEdgesOf(const TopoDS_Shape& shape) {
  NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>, TopTools_ShapeMapHasher>
      edgeToFaces;
  TopExp::MapShapesAndAncestors(shape, TopAbs_EDGE, TopAbs_FACE, edgeToFaces);
  std::vector<TopoDS_Edge> freeEdges;
  for (int index = 1; index <= edgeToFaces.Extent(); ++index) {
    if (edgeToFaces(index).Extent() == 1)
      freeEdges.push_back(TopoDS::Edge(edgeToFaces.FindKey(index)));
  }
  return freeEdges;
}

/// Walks `freeEdges` into ONE ordered closed loop by following shared
/// vertices. Throws Standard_Failure — routed by the caller to
/// `E_BOUNDARY_SURFACE_NOT_CLOSED` — unless every touched vertex has DEGREE
/// EXACTLY TWO among `freeEdges` and a single walk from edge 0 consumes every
/// edge and returns to its own start vertex (so two disjoint loops, a
/// non-manifold Y-junction, or a dangling chain are all refused, not
/// silently mis-filled).
std::vector<TopoDS_Edge> OrderIntoSingleLoop(const std::vector<TopoDS_Edge>& freeEdges) {
  NCollection_IndexedDataMap<TopoDS_Shape, std::vector<std::size_t>, TopTools_ShapeMapHasher>
      vertexToEdges;
  for (std::size_t index = 0; index < freeEdges.size(); ++index) {
    TopoDS_Vertex v1;
    TopoDS_Vertex v2;
    TopExp::Vertices(freeEdges[index], v1, v2);
    if (v1.IsNull() || v2.IsNull())
      throw Standard_Failure("boundary_surface free edge has no endpoints");
    for (const TopoDS_Vertex& vertex : {v1, v2}) {
      const int existing = vertexToEdges.FindIndex(vertex);
      if (existing == 0)
        vertexToEdges.Add(vertex, std::vector<std::size_t>{index});
      else
        vertexToEdges.ChangeFromIndex(existing).push_back(index);
    }
  }
  for (int index = 1; index <= vertexToEdges.Extent(); ++index) {
    if (vertexToEdges(index).size() != 2)
      throw Standard_Failure("boundary_surface's open boundary is not a single simple closed loop");
  }

  std::vector<TopoDS_Edge> ordered;
  ordered.reserve(freeEdges.size());
  std::vector<bool> used(freeEdges.size(), false);
  TopoDS_Vertex startVertex;
  TopoDS_Vertex currentVertex;
  TopExp::Vertices(freeEdges[0], startVertex, currentVertex);
  ordered.push_back(freeEdges[0]);
  used[0] = true;
  while (ordered.size() < freeEdges.size()) {
    const int atCurrent = vertexToEdges.FindIndex(currentVertex);
    bool advanced = false;
    for (const std::size_t candidateIndex : vertexToEdges(atCurrent)) {
      if (used[candidateIndex])
        continue;
      TopoDS_Vertex a;
      TopoDS_Vertex b;
      TopExp::Vertices(freeEdges[candidateIndex], a, b);
      currentVertex = a.IsSame(currentVertex) ? b : a;
      ordered.push_back(freeEdges[candidateIndex]);
      used[candidateIndex] = true;
      advanced = true;
      break;
    }
    if (!advanced) {
      throw Standard_Failure("boundary_surface's open boundary decomposes into more than one loop");
    }
  }
  if (!currentVertex.IsSame(startVertex))
    throw Standard_Failure("boundary_surface's open boundary does not close into a single loop");
  return ordered;
}

} // namespace

EvaluatedBody EvaluateBoundarySurface(const nlohmann::json& operation, BodyPool& pool,
                                      ElementNameBook* elementNames, NamingRegistry* registry,
                                      const std::atomic_bool& cancelled) {
  // No registry harvest for this operation — see this file's header comment
  // for why `OperationClass::BoundarySurface` is declared but never
  // constructed through `HarvestOperation`.
  (void)registry;
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();

  // Read-only reference: the target stays live and unconsumed (mirror
  // merge:false / datum_plane's own non-consuming shape) — see this file's
  // header comment for why that also governs the naming treatment below.
  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const EvaluatedBody* targetBody = FindVisibleBody(peeked, targetOperationId);
  if (targetBody == nullptr) {
    throw ReferenceMissing(operationId,
                           "boundary_surface target references operation " + targetOperationId +
                               ", which is not an unconsumed body-producing operation earlier in "
                               "the document");
  }
  const TopoDS_Shape& target = targetBody->shape;

  const auto refuse = [&](const char* message, const char* surfaceCode) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, {{"surfaceCode", surfaceCode}});
  };

  const std::vector<TopoDS_Edge> freeEdges = FreeEdgesOf(target);
  if (freeEdges.empty()) {
    refuse("boundary_surface target has no open boundary to cap; it is already a fully closed "
           "shape",
           "E_BOUNDARY_SURFACE_NOT_CLOSED");
  }

  std::vector<TopoDS_Edge> loop;
  try {
    loop = OrderIntoSingleLoop(freeEdges);
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("boundary_surface requires its target's ENTIRE open boundary to form one simple "
           "closed loop",
           "E_BOUNDARY_SURFACE_NOT_CLOSED");
  }

  // BRepOffsetAPI_MakeFilling: position/G0 continuity only (the wire
  // contract's stated v1 scope), added per edge in walked loop order. This
  // pinned OCCT has no Add(TopoDS_Wire) overload at all (see this file's
  // header comment), so the per-edge Add(edge, GeomAbs_C0) form is the only
  // one available — it handles an arbitrary non-planar 3D loop exactly as
  // well as a planar one, which is what makes this primitive the right
  // choice over a plain planar face-from-wire construction.
  BRepOffsetAPI_MakeFilling filling;
  for (const TopoDS_Edge& edge : loop)
    filling.Add(edge, GeomAbs_C0);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    try {
      filling.Build(progress->Start());
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      refuse("boundary_surface could not fit a surface to the boundary loop",
             "E_BOUNDARY_SURFACE_SELF_INTERSECTS");
    }
  }
  CheckCancellation(cancelled);
  if (!filling.IsDone())
    refuse("boundary_surface could not fit a surface to the boundary loop",
           "E_BOUNDARY_SURFACE_SELF_INTERSECTS");
  const TopoDS_Shape result = filling.Shape();
  if (result.IsNull() || result.ShapeType() != TopAbs_FACE) {
    refuse("boundary_surface did not produce a single face for this boundary loop",
           "E_BOUNDARY_SURFACE_SELF_INTERSECTS");
  }
  if (!BRepCheck_Analyzer(result, false).IsValid()) {
    refuse("boundary_surface produced an invalid face for this boundary loop",
           "E_BOUNDARY_SURFACE_SELF_INTERSECTS");
  }

  EvaluatedBody body = FinishSurfaceBody(operation, result, "boundary_surface result");

  if (elementNames != nullptr) {
    // MEASURED (surfacing_test.cpp, an explicit IsSame check — this file's
    // own "verify, don't assume" discipline): the ORIGINAL assumption here
    // was that BRepOffsetAPI_MakeFilling reuses the constraint edges passed
    // to Add() as the result face's own boundary, sharing TShape identity
    // with the target's edges. Tested directly, that is FALSE — the fill
    // face's boundary edges are fresh TShapes, geometrically coincident with
    // (per the zero-free-edges resewing proof in that same test) but never
    // IsSame to, the target's own edges. AddDerivedPrimitive is still the
    // right, safe naming choice regardless of which way this came out: with
    // nothing actually shared, it degrades to plain AddPrimitive's own
    // behavior (mint every sub-shape fresh) — the CAP-034 "swept/built from
    // the target's own boundary" mold edge_flange's own naming block
    // documents exists precisely to handle EITHER outcome (some sub-shapes
    // pre-named, or none) without needing to know in advance which applies.
    //
    // No registry harvest: see this file's header comment for why
    // `OperationClass::BoundarySurface` is declared but never constructed
    // through `HarvestOperation` — the target is not a consumed operand, so
    // there is no result for a Modified/Generated image to land in that
    // is not ALSO the (unconsumed, elsewhere-live) target itself. Book-level
    // naming above is still total: every sub-shape of the result has a name,
    // satisfying `includeElementNames`'s coverage contract.
    elementNames->AddDerivedPrimitive(operationId, body.shape);
  }
  return body;
}

EvaluatedBody EvaluateSurfaceOffset(const nlohmann::json& operation, BodyPool& pool,
                                    ElementNameBook* elementNames, NamingRegistry* registry,
                                    const std::atomic_bool& cancelled) {
  (void)registry;
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const double distance = parameters.at("distanceMm").get<double>();
  if (!(std::isfinite(distance) && distance != 0.0))
    throw std::invalid_argument("surface_offset distanceMm must be a nonzero finite number");

  // Fail closed under element naming (tranche N0 precedent): this is the
  // EXACT same BRepOffsetAPI_MakeOffsetShape::PerformByJoin whole-shape call
  // geometry.cpp's own `offset` v1 whole-body path already uses, and that
  // path is ALREADY documented there as naming-unverified. Re-litigating
  // that verification here, for the identical primitive, would either
  // silently diverge from the existing guard or duplicate work this
  // codebase already decided against doing for v1. See this file's header
  // comment.
  if (elementNames != nullptr) {
    throw std::invalid_argument(
        "unsupported operation: surface_offset cannot record element names yet; evaluate "
        "without includeElementNames");
  }

  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const EvaluatedBody* targetBody = FindVisibleBody(peeked, targetOperationId);
  if (targetBody == nullptr) {
    throw ReferenceMissing(operationId,
                           "surface_offset target references operation " + targetOperationId +
                               ", which is not an unconsumed body-producing operation earlier in "
                               "the document");
  }
  if (targetBody->probes.solidCount >= 1) {
    throw OperationFailure(operationId, "INVALID_REQUEST",
                           "surface_offset requires an open surface body; the target is a solid",
                           {{"surfaceCode", "E_SURFACE_OFFSET_NOT_SURFACE"}});
  }

  const TopoDS_Shape target =
      pool.Consume(operationId, "surface_offset", "target", targetOperationId);

  const auto refuse = [&](const char* message, const char* surfaceCode) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, {{"surfaceCode", surfaceCode}});
  };

  BRepOffsetAPI_MakeOffsetShape maker;
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    try {
      maker.PerformByJoin(target, distance, 1.0e-6, BRepOffset_Skin, false, false, GeomAbs_Arc,
                          false, progress->Start());
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      refuse("surface_offset construction failed; the distance may self-intersect the surface",
             "E_SURFACE_OFFSET_SELF_INTERSECTS");
    }
  }
  CheckCancellation(cancelled);
  if (!maker.IsDone()) {
    refuse("surface_offset construction failed; the distance may self-intersect the surface",
           "E_SURFACE_OFFSET_SELF_INTERSECTS");
  }
  const TopoDS_Shape result = maker.Shape();
  if (result.IsNull() ||
      (result.ShapeType() != TopAbs_SHELL && result.ShapeType() != TopAbs_FACE)) {
    refuse("surface_offset did not produce an open surface", "E_SURFACE_OFFSET_SELF_INTERSECTS");
  }
  if (!BRepCheck_Analyzer(result, false).IsValid()) {
    refuse("surface_offset produced an invalid surface for this distance",
           "E_SURFACE_OFFSET_SELF_INTERSECTS");
  }

  return FinishSurfaceBody(operation, result, "surface_offset result");
}

EvaluatedBody EvaluateStitch(const nlohmann::json& operation, BodyPool& pool,
                             ElementNameBook* elementNames, NamingRegistry* registry,
                             const std::atomic_bool& cancelled) {
  (void)registry;
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string firstOperationId = parameters.at("firstOperationId").get<std::string>();
  const std::string secondOperationId = parameters.at("secondOperationId").get<std::string>();
  // The TS schema always materializes a default before the wire (per the
  // pinned contract); the kernel is still a trust boundary (shell's own
  // `direction` precedent), so an absent slot takes a documented fallback
  // rather than throwing on `.at`. 0.01 mm is this file's own judgment call
  // for that fallback, not a value taken from the schema (flagged in the
  // implementation report).
  const double tolerance = parameters.value("toleranceMm", 0.01);
  if (!(std::isfinite(tolerance) && tolerance > 0.0))
    throw std::invalid_argument("stitch toleranceMm must be positive");
  if (firstOperationId == secondOperationId) {
    throw std::invalid_argument(
        "stitch firstOperationId and secondOperationId must reference two distinct bodies");
  }

  const TopoDS_Shape first = pool.Consume(operationId, "stitch", "first", firstOperationId);
  const TopoDS_Shape second = pool.Consume(operationId, "stitch", "second", secondOperationId);

  const auto refuse = [&](const char* message) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message,
                           {{"surfaceCode", "E_STITCH_NO_COMMON_BOUNDARY"}});
  };

  BRepBuilderAPI_Sewing sewing(tolerance);
  sewing.Add(first);
  sewing.Add(second);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    try {
      sewing.Perform(progress->Start());
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      refuse("stitch could not sew the two bodies together");
    }
  }
  CheckCancellation(cancelled);
  if (sewing.NbContigousEdges() == 0) {
    refuse("stitch found no shared boundary between the two bodies within toleranceMm; nothing "
           "to stitch");
  }

  const TopoDS_Shape sewn = sewing.SewedShape();
  if (sewn.IsNull())
    refuse("stitch produced no result shape");

  // Rebuild ONE clean shell from every face of the sewn result rather than
  // trust SewedShape()'s own TopoDS typing (a face, a shell, a compound, or —
  // per its own header comment — even a solid, depending on internal cases
  // this file does not rely on): this file measures the rebuilt shell's own
  // manifold closure directly instead (every edge incident to EXACTLY two
  // faces), which is well-defined regardless of what shape kind Sewing
  // itself chose to hand back.
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> sewnFaces;
  TopExp::MapShapes(sewn, TopAbs_FACE, sewnFaces);
  if (sewnFaces.Extent() == 0)
    refuse("stitch produced no surface material");
  BRep_Builder builder;
  TopoDS_Shell shell;
  builder.MakeShell(shell);
  for (int index = 1; index <= sewnFaces.Extent(); ++index)
    builder.Add(shell, TopoDS::Face(sewnFaces(index)));

  NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>, TopTools_ShapeMapHasher>
      edgeToFaces;
  TopExp::MapShapesAndAncestors(shell, TopAbs_EDGE, TopAbs_FACE, edgeToFaces);
  bool closed = edgeToFaces.Extent() > 0;
  for (int index = 1; closed && index <= edgeToFaces.Extent(); ++index) {
    if (edgeToFaces(index).Extent() != 2)
      closed = false;
  }

  EvaluatedBody body;
  if (closed) {
    BRepBuilderAPI_MakeSolid solidMaker(shell);
    if (!solidMaker.IsDone())
      refuse("stitch's fully-closed boundary could not be converted into a solid");
    const TopoDS_Shape solidShape = solidMaker.Shape();
    if (!BRepCheck_Analyzer(solidShape, false).IsValid())
      refuse("stitch produced an invalid closed solid");
    body = FinishThickenedSolidBody(operation, solidShape, "stitch result");
  } else {
    if (!BRepCheck_Analyzer(shell, false).IsValid())
      refuse("stitch produced an invalid open surface");
    body = FinishSurfaceBody(operation, shell, "stitch result");
  }

  if (elementNames != nullptr) {
    // Mints fresh: see this file's header comment for the measured reason
    // (BRepBuilderAPI_Sewing's Modified()/IsModifiedSubShape() surface does
    // not fit BRepTools_History/LocalOperationHistorySource's
    // BRepBuilderAPI_MakeShape-shaped contract — Sewing extends
    // Standard_Transient directly, confirmed by reading its header). No
    // registry harvest for the same reason; book-level naming above is
    // still total.
    elementNames->AddDerivedPrimitive(operationId, body.shape);
  }
  return body;
}

EvaluatedBody EvaluateThicken(const nlohmann::json& operation, BodyPool& pool,
                              ElementNameBook* elementNames, NamingRegistry* registry,
                              const std::atomic_bool& cancelled) {
  // No registry harvest for this operation — see this file's header comment
  // (and the naming block below) for the measured reason
  // `OperationClass::Thicken` is declared but never constructed through
  // `HarvestOperation`.
  (void)registry;
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const double thickness = parameters.at("thicknessMm").get<double>();
  const std::string direction = parameters.value("direction", "normal");
  if (!(std::isfinite(thickness) && thickness > 0.0))
    throw std::invalid_argument("thicken thicknessMm must be positive");
  if (direction != "normal" && direction != "reverse" && direction != "symmetric")
    throw std::invalid_argument("unsupported thicken direction: " + direction);

  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const EvaluatedBody* targetBody = FindVisibleBody(peeked, targetOperationId);
  if (targetBody == nullptr) {
    throw ReferenceMissing(operationId,
                           "thicken target references operation " + targetOperationId +
                               ", which is not an unconsumed body-producing operation earlier in "
                               "the document");
  }
  if (targetBody->probes.solidCount >= 1) {
    throw OperationFailure(operationId, "INVALID_REQUEST",
                           "thicken requires an open surface body; the target is already a solid",
                           {{"surfaceCode", "E_THICKEN_NOT_SURFACE"}});
  }

  const TopoDS_Shape target = pool.Consume(operationId, "thicken", "target", targetOperationId);

  const auto refuse = [&](const char* message) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message,
                           {{"surfaceCode", "E_THICKEN_SELF_INTERSECTS"}});
  };

  // "normal"/"reverse": ONE untouched call directly on the live target (a
  // plain sign flip on the offset value, the shell inward/outward
  // precedent). "symmetric": OCCT has no two-sided thicken primitive, so a
  // synthetic half-offset scaffold (a plain open-surface offset, -thickness/2
  // along the SAME direction convention) is thickened by the FULL thickness
  // from there. All three modes mint their naming fresh (see below), so —
  // unlike an earlier revision of this function — nothing downstream needs
  // to distinguish "built from a synthetic scaffold" from "built from the
  // live target" any more; `base` alone is enough.
  TopoDS_Shape base = target;
  if (direction == "symmetric") {
    BRepOffsetAPI_MakeOffsetShape halfShift;
    const occ::handle<CancellationProgress> shiftProgress = MakeCancellationProgress(cancelled);
    try {
      halfShift.PerformByJoin(target, -0.5 * thickness, 1.0e-6, BRepOffset_Skin, false, false,
                              GeomAbs_Arc, false, shiftProgress->Start());
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      refuse("thicken could not compute the symmetric half-offset");
    }
    CheckCancellation(cancelled);
    if (!halfShift.IsDone())
      refuse("thicken could not compute the symmetric half-offset");
    base = halfShift.Shape();
    if (base.IsNull() || (base.ShapeType() != TopAbs_SHELL && base.ShapeType() != TopAbs_FACE))
      refuse("thicken's symmetric half-offset did not produce an open surface");
    if (!BRepCheck_Analyzer(base, false).IsValid())
      refuse("thicken's symmetric half-offset produced an invalid surface");
  }
  const double signedOffset = (direction == "reverse") ? -thickness : thickness;

  // MEASURED DIVERGENCE FROM THE INITIAL PLAN (surfacing_test.cpp caught
  // this): MakeThickSolidByJoin with an EMPTY closing-faces list does NOT
  // build a genuine closing collar — verified experimentally that it just
  // returns the plain offset image (still open), regardless of whether the
  // input is a bare TopAbs_FACE or a TopAbs_SHELL wrapping that same face.
  // shell_feature.cpp's own use of this class never exercises the
  // EMPTY-closing-faces case (its `openFaces` is always non-empty when it
  // takes the open-container branch at all), so there was no existing
  // in-codebase proof either way before this file's own test caught it.
  // `MakeThickSolidBySimple` is the primitive actually documented for this
  // exact shape: "Non-closed shell or face is expected as input" (its own
  // header comment) — it produces the collar this operation needs directly.
  // Its tradeoff (own doc comment): "does not support faces removing"
  // because "intersections are not computed during offset creation" — a
  // real limitation for a self-intersecting or sharply creased surface, but
  // exactly what this operation is refusing anyway via the validity check
  // below (E_THICKEN_SELF_INTERSECTS), and irrelevant for the planar and
  // singly-curved (cylindrical) surfaces this file's own tests cover. A
  // bare TopAbs_FACE input works directly (its own doc comment says so
  // explicitly), so this call needs no AsShellForThicken-style rewrap.
  BRepOffsetAPI_MakeThickSolid thickenMaker;
  try {
    thickenMaker.MakeThickSolidBySimple(base, signedOffset);
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("thicken construction failed; the thickness may self-intersect the surface");
  }
  CheckCancellation(cancelled);
  if (!thickenMaker.IsDone())
    refuse("thicken construction failed; the thickness may self-intersect the surface");
  const TopoDS_Shape result = thickenMaker.Shape();
  if (result.IsNull() || result.ShapeType() != TopAbs_SOLID)
    refuse("thicken did not produce a solid body");
  if (!BRepCheck_Analyzer(result, false).IsValid())
    refuse("thicken produced an invalid solid for this thickness");
  // MEASURED (surfacing_test.cpp, a cylindrical face thickened inward past
  // its own radius): MakeThickSolidBySimple's own documented lack of
  // intersection computation means a self-overlapping thickness does NOT
  // fail construction and does NOT fail the plain topological
  // BRepCheck_Analyzer check above either — the resulting "solid" stays
  // topologically closed even though its walls physically overlap in space,
  // silently returning a wrong-but-plausible-looking body instead of
  // refusing. BRepAlgoAPI_Check with self-interference testing enabled is
  // the general, whole-shape self-intersection detector this codebase's
  // other offset-family primitives (PerformByJoin, verified via
  // surface_offset's own equivalent test) get for free from their own
  // intersection-aware construction; thicken needs to ask for the same
  // guarantee explicitly since MakeThickSolidBySimple does not provide it.
  {
    CheckCancellation(cancelled);
    BRepAlgoAPI_Check selfIntersectionCheck(result, /*bTestSE=*/true, /*bTestSI=*/true);
    if (!selfIntersectionCheck.IsValid())
      refuse("thicken thickness self-intersects the surface");
  }

  EvaluatedBody body = FinishThickenedSolidBody(operation, result, "thicken result");

  if (elementNames != nullptr) {
    // MEASURED DIVERGENCE FROM THE INITIAL PLAN (surfacing_test.cpp caught
    // this too — the same discipline as the MakeThickSolidBySimple switch
    // above): the plan was for "normal"/"reverse" (base == target directly,
    // zero intermediate transforms, structurally identical to shell_feature
    // .cpp's own already-proven MakeThickSolidByJoin harvest) to construct
    // through HarvestOperation via LocalOperationHistorySource, the same way
    // Shell's open-container branch does. Tested directly — a single,
    // UNCOMPOSED MakeThickSolidBySimple call on a bare planar rectangle, as
    // simple a case as exists — ElementNameBook::ApplyOperation throws
    // "cannot attribute a result entity ... bare quantized-geometry root",
    // the SAME failure class edge_flange's own header comment records for
    // its fuse->fillet composition. Unlike edge_flange's case, this is NOT a
    // composition-depth problem (there is no composition here at all) — it
    // is BRepOffsetAPI_MakeThickSolid's OWN Modified()/Generated() surface
    // being materially less complete when built via MakeThickSolidBySimple
    // than via MakeThickSolidByJoin (which the class's own doc comment
    // already flags as skipping intersection computation entirely — the
    // likely reason its retained bookkeeping is thinner too). All THREE
    // direction modes therefore mint fresh (AddDerivedPrimitive) uniformly,
    // and `OperationClass::Thicken` joins `BoundarySurface`/`SurfaceOffset`/
    // `Stitch` in the "declared but never constructed" set — see
    // naming_registry.hpp's own (corrected) doc comment.
    elementNames->AddDerivedPrimitive(operationId, body.shape);
  }
  return body;
}

} // namespace aeth
