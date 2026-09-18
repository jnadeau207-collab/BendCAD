#include "shell_feature.hpp"

#include <cmath>
#include <cstddef>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include <BRepAlgoAPI_Cut.hxx>
#include <BRepCheck_Analyzer.hxx>
#include <BRepLib.hxx>
#include <BRepOffsetAPI_MakeOffsetShape.hxx>
#include <BRepOffsetAPI_MakeThickSolid.hxx>
#include <BRepOffset_Mode.hxx>
#include <BRepTools_History.hxx>
#include <GeomAbs_JoinType.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <Standard_Failure.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Solid.hxx>

#include "body_pool.hpp"
#include "bounded_feasibility.hpp"
#include "cancel.hpp"
#include "local_operation_history.hpp"
#include "naming_registry.hpp"
#include "ref_slot.hpp"

namespace aeth {
namespace {

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

int CountOf(const TopoDS_Shape& shape, const TopAbs_ShapeEnum kind) {
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> map;
  TopExp::MapShapes(shape, kind, map);
  return map.Extent();
}

/// The offset stage of the closed-hollow decomposition: the EXACT PerformByJoin
/// call shape the landed `offset` executor uses (geometry.cpp EvaluateOffset),
/// validated to one closed solid. Throws Standard_Failure on any defect so the
/// caller can route through the feasibility probe.
TopoDS_Shape BuildOffsetSolid(const TopoDS_Shape& target, const double signedDistance,
                              const std::atomic_bool& cancelled) {
  const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
  BRepOffsetAPI_MakeOffsetShape maker;
  maker.PerformByJoin(target, signedDistance, 1.0e-6, BRepOffset_Skin, false, false, GeomAbs_Arc,
                      false, progress->Start());
  CheckCancellation(cancelled);
  if (!maker.IsDone())
    throw Standard_Failure("shell offset stage failed; the thickness may collapse the body");
  const TopoDS_Shape result = maker.Shape();
  if (result.IsNull() || result.ShapeType() != TopAbs_SOLID)
    throw Standard_Failure("shell offset stage did not produce a single solid");
  if (!BRepCheck_Analyzer(result, false).IsValid())
    throw Standard_Failure("shell offset stage produced an invalid solid");
  return result;
}

struct CutOutcome final {
  TopoDS_Shape result;
  /// Non-null exactly when the caller asked for retained history (naming on).
  occ::handle<BRepTools_History> history;
};

/// The nested cut of the decomposition. Deterministic (SetRunParallel(false),
/// the document-evaluation mandate) and history-retaining exactly when naming
/// is recording — the boolean_combine/hole conventions verbatim.
CutOutcome RunNestedCut(const TopoDS_Shape& object, const TopoDS_Shape& tool,
                        const bool fillHistory, const std::atomic_bool& cancelled) {
  BRepAlgoAPI_Cut cut;
  NCollection_List<TopoDS_Shape> objects;
  objects.Append(object);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(tool);
  cut.SetArguments(objects);
  cut.SetTools(tools);
  cut.SetRunParallel(false);
  cut.SetToFillHistory(fillHistory);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    cut.Build(progress->Start());
  }
  CheckCancellation(cancelled);
  if (cut.HasErrors())
    throw Standard_Failure("shell hollowing cut failed");
  CutOutcome outcome;
  outcome.result = cut.Shape();
  if (outcome.result.IsNull())
    throw Standard_Failure("shell hollowing cut produced no result shape");
  if (fillHistory) {
    outcome.history = cut.History();
    if (outcome.history.IsNull())
      throw Standard_Failure("shell hollowing cut did not record algorithm history");
  }
  return outcome;
}

/// Extracts and validates the single hollow solid of a cut result. Throws
/// Standard_Failure on any defect (routed through the probe by the caller).
TopoDS_Solid SingleValidSolid(const TopoDS_Shape& result) {
  const int solidCount = CountOf(result, TopAbs_SOLID);
  if (solidCount != 1) {
    throw Standard_Failure(("shell produced " + std::to_string(solidCount) +
                            " solids; a shell output must be a single hollow solid")
                               .c_str());
  }
  TopExp_Explorer solids(result, TopAbs_SOLID);
  const TopoDS_Solid solid = TopoDS::Solid(solids.Current());
  if (!BRepCheck_Analyzer(solid, false).IsValid())
    throw Standard_Failure("shell produced an invalid solid");
  return solid;
}

} // namespace

EvaluatedBody EvaluateShell(const nlohmann::json& operation, BodyPool& pool,
                            ElementNameBook* elementNames, NamingRegistry* registry,
                            const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const double thickness = parameters.at("thickness").get<double>();
  if (!(std::isfinite(thickness) && thickness > 0.0))
    throw std::invalid_argument("shell thickness must be positive");
  // The TS schema materializes the default before the wire, but the kernel is
  // a trust boundary: an absent slot takes the documented default and an
  // unknown literal fails closed.
  const std::string direction = parameters.value("direction", "inward");
  if (direction != "inward" && direction != "outward")
    throw std::invalid_argument("unsupported shell direction: " + direction);
  const bool inward = direction == "inward";

  // --- openFaces staging (design note §3.3): resolution + resolve-time
  // validation land NOW; ByJoin execution stays deferred fail-closed. -------
  std::vector<QueryEntity> openFaces;
  if (parameters.contains("openFaces")) {
    if (registry == nullptr) {
      // Same guard shape as fillet-v2's edge-scoped registry requirement:
      // resolution needs the registry, so the registry-less path refuses.
      throw std::invalid_argument(
          "unsupported operation: a shell with openFaces requires the naming registry; evaluate "
          "without openFaces or with a registry-threaded replay state");
    }
    // Resolve against the replay state BEFORE consuming the target so the
    // query sees exactly the bodies this op sees (fillet-v2 N5 discipline).
    const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
    const RefResolution resolution =
        ResolveRefSlotStrict(operationId, "shell", "openFaces", parameters.at("openFaces"), peeked,
                             *registry, cancelled);
    // Locate the target in the peeked snapshot for the on-body check; when it
    // is not visible (a bad targetOperationId) the checks are skipped and the
    // later pool.Consume raises the canonical ReferenceMissing instead.
    const std::string* targetBodyId = nullptr;
    for (const EvaluatedBody& body : peeked) {
      if (body.operationId == targetOperationId) {
        targetBodyId = &body.bodyId;
        break;
      }
    }
    for (const QueryEntity& entity : resolution.entities) {
      if (entity.kind != 'f')
        throw std::invalid_argument(
            "shell openFaces reference resolved a non-face entity; the slot is face-kinded");
      if (targetBodyId != nullptr && entity.bodyId != *targetBodyId) {
        // Doc 04 validation rule 2: every open face must lie on the target
        // body. Fine code rides in details (kernel-error-registry rule).
        throw OperationFailure(
            operationId, "INVALID_REQUEST",
            "shell openFaces resolved a face outside the shell target body",
            {{"shellCode", "E_SHELL_FAILED"}, {"reason", "open-face-not-on-body"}});
      }
    }
    openFaces = resolution.entities;
  }

  // Shell CONSUMES its target (the hollowed body replaces it in place), the
  // same taxonomy as fillet/offset. Consumed AFTER resolution so a missing
  // target surfaces as the canonical ReferenceMissing.
  const TopoDS_Shape target = pool.Consume(operationId, "shell", "target", targetOperationId);

  if (!openFaces.empty()) {
    // Doc 04 validation rule 3: removing every face leaves nothing to hollow.
    const int faceCount = CountOf(target, TopAbs_FACE);
    if (static_cast<int>(openFaces.size()) == faceCount) {
      throw OperationFailure(
          operationId, "INVALID_REQUEST",
          "shell openFaces resolved every face of the target body; removing every face leaves "
          "nothing to hollow",
          {{"shellCode", "E_SHELL_ALL_FACES_REMOVED"}, {"faceCount", faceCount}});
    }
    // --- Open container via MakeThickSolidByJoin (CAP-013). --------------
    // The deferral is lifted on MEASUREMENT: the pinned ByJoin history is
    // deterministic (byte-identical across independent runs for top-open and
    // side-open inward, and for outward), and the §3.3 reversed-image concern
    // does not reproduce inward — the closing face reports Modified=1 with
    // orientation UNCHANGED and every retained face reports Generated=1 (its
    // cavity image). The naming pass below runs over the SAME retained history,
    // and the registry's totality rule is the backstop: an entity the harvest
    // cannot attribute fails the request loudly rather than minting a guess.
    NCollection_List<TopoDS_Shape> closingFaces;
    for (const QueryEntity& entity : openFaces)
      closingFaces.Append(entity.shape);

    const double joinSign = inward ? -1.0 : 1.0;

    // Work-order item 6: feasibility PARITY with the closed hollow. Someone who
    // asks for too thick a wall is owed the kernel's TESTED bound whether or
    // not they left a face open; emitting `probeSkipped` on this path only
    // would be a silent downgrade of the same refusal.
    // A hollow that removed NOTHING is a no-op committed as a feature — the
    // same defect the closed path refuses via its shell count. That witness
    // does not work here: an open container legitimately has ONE shell, and so
    // does an untouched solid, so a collapsed open hollow is indistinguishable
    // by topology. VOLUME is the witness instead — hollowing must remove
    // material. Found by measurement: without this, a 25 mm wall on a
    // 60x40x20 box (walls that must collide) returned a plausible body.
    const double targetVolume = ProbeShape(target).volume;
    const auto hollowedOut = [&targetVolume](const TopoDS_Shape& candidate) {
      return ProbeShape(candidate).volume < targetVolume * (1.0 - 1e-9);
    };

    const auto isFeasibleByJoin = [&](const double candidate) {
      CheckCancellation(cancelled);
      try {
        BRepOffsetAPI_MakeThickSolid trial;
        trial.MakeThickSolidByJoin(target, closingFaces, joinSign * candidate, 1.0e-4,
                                   BRepOffset_Skin, false, false, GeomAbs_Arc, true);
        CheckCancellation(cancelled);
        if (!trial.IsDone())
          return false;
        const TopoDS_Solid trialSolid = SingleValidSolid(trial.Shape());
        return inward ? hollowedOut(trialSolid) : true;
      } catch (const Standard_Failure&) {
        CheckCancellation(cancelled);
        return false;
      }
    };
    const auto failOpenWithBound = [&](const std::string& message) {
      const auto bound = ProbeMaxFeasible(thickness, isFeasibleByJoin);
      nlohmann::json details;
      if (bound.has_value()) {
        // The SAME .strict() thickness payload the closed hollow emits
        // (geometryFeasibilityDetailsSchema); the shape may not diverge.
        details = {{"requestedThickness", thickness},
                   {"maxFeasibleThickness", bound->maxFeasible},
                   {"feasibilityProbe",
                    {{"parameter", "thickness"},
                     {"requested", thickness},
                     {"maxFeasible", bound->maxFeasible},
                     {"bound", "tested-lower-bound"},
                     {"attempts", bound->attempts}}}};
      } else {
        details = {{"shellCode", "E_SHELL_FAILED"}, {"probeSkipped", true}};
      }
      throw OperationFailure(operationId, "GEOMETRY_FAILED", message, std::move(details));
    };

    BRepOffsetAPI_MakeThickSolid joinMaker;
    try {
      joinMaker.MakeThickSolidByJoin(target, closingFaces, joinSign * thickness, 1.0e-4,
                                     BRepOffset_Skin, false, false, GeomAbs_Arc, true);
    } catch (const Standard_Failure& error) {
      CheckCancellation(cancelled);
      failOpenWithBound(error.what());
    }
    CheckCancellation(cancelled);
    if (!joinMaker.IsDone())
      failOpenWithBound("shell could not hollow the body with those faces left open");
    TopoDS_Solid openSolid;
    try {
      openSolid = SingleValidSolid(joinMaker.Shape());
    } catch (const Standard_Failure& error) {
      failOpenWithBound(error.what());
    }
    // The no-op guard (see `hollowedOut`): an inward hollow that removed no
    // material means the walls consumed the whole interior.
    if (inward && !hollowedOut(openSolid))
      failOpenWithBound("shell produced no interior cavity; the walls consumed the whole body");
    BRepLib::OrientClosedSolid(openSolid);

    EvaluatedBody openBody;
    openBody.bodyId = operation.at("outputBodyId").get<std::string>();
    openBody.operationId = operationId;
    openBody.shape = openSolid;
    openBody.probes = ProbeShape(openBody.shape);
    if (!openBody.probes.valid)
      throw std::runtime_error("OCCT produced an invalid open-shell result");

    if (elementNames != nullptr) {
      NCollection_List<TopoDS_Shape> arguments;
      arguments.Append(target);
      LocalOperationHistorySource historySource(joinMaker, openBody.shape);
      const occ::handle<BRepTools_History> history =
          new BRepTools_History(arguments, historySource);
      elementNames->ApplyOperation(operationId, {target}, openBody.shape, *history, cancelled);
      if (registry != nullptr) {
        registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Shell,
                                   {{target, false}}, openBody.shape, *history, cancelled);
      }
    }
    return openBody;
  }

  // --- Closed hollow via the verified decomposition (design note §3.1). ----
  const double sign = inward ? -1.0 : 1.0;
  const bool naming = elementNames != nullptr;

  const auto isFeasibleThickness = [&](const double candidate) {
    CheckCancellation(cancelled);
    try {
      const TopoDS_Shape trialOffset = BuildOffsetSolid(target, sign * candidate, cancelled);
      const CutOutcome trial = RunNestedCut(inward ? target : trialOffset,
                                            inward ? trialOffset : target, false, cancelled);
      SingleValidSolid(trial.result);
      return true;
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      return false;
    }
  };

  const auto failWithBound = [&](const std::string& message) {
    const auto bound = ProbeMaxFeasible(thickness, isFeasibleThickness);
    nlohmann::json details;
    if (bound.has_value()) {
      // Doc 04 E_SHELL_THICKNESS_TOO_LARGE, carried as the shipped Wave 2.4
      // payload shape: the wire schema's thickness variant is .strict()
      // (geometryFeasibilityDetailsSchema), so the payload is EXACTLY the
      // fillet/offset triple — the fine shell code is implied by
      // parameter: "thickness" and stays off this variant by contract.
      details = {{"requestedThickness", thickness},
                 {"maxFeasibleThickness", bound->maxFeasible},
                 {"feasibilityProbe",
                  {{"parameter", "thickness"},
                   {"requested", thickness},
                   {"maxFeasible", bound->maxFeasible},
                   {"bound", "tested-lower-bound"},
                   {"attempts", bound->attempts}}}};
    } else {
      details = {{"shellCode", "E_SHELL_FAILED"}, {"probeSkipped", true}};
    }
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, std::move(details));
  };

  // Offset stage: synthesize the cavity (inward) or the grown skin (outward).
  TopoDS_Shape synthetic;
  try {
    synthetic = BuildOffsetSolid(target, sign * thickness, cancelled);
  } catch (const Standard_Failure& error) {
    CheckCancellation(cancelled);
    failWithBound(error.what());
  }

  // Nested cut: inward hollows the target with the cavity; outward keeps the
  // grown skin and carves the original body out of it (the original surface
  // becomes the cavity — doc 04's `outward` semantics).
  const TopoDS_Shape& object = inward ? target : synthetic;
  const TopoDS_Shape& tool = inward ? synthetic : target;
  CutOutcome cut;
  try {
    cut = RunNestedCut(object, tool, naming, cancelled);
  } catch (const Standard_Failure& error) {
    CheckCancellation(cancelled);
    failWithBound(error.what());
  }

  TopoDS_Solid solid;
  try {
    solid = SingleValidSolid(cut.result);
  } catch (const Standard_Failure& error) {
    failWithBound(error.what());
  }
  // A hollow is one solid bounded by TWO shells (outer skin + cavity). A
  // single-shell result means the cavity vanished — a no-op hollow committed
  // as a feature, refused like the boolean family's no-op cut.
  if (CountOf(solid, TopAbs_SHELL) != 2)
    failWithBound("shell produced no interior cavity; the walls consumed the whole body");

  BRepLib::OrientClosedSolid(solid);
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operationId;
  body.shape = solid;
  body.probes = ProbeShape(body.shape);
  if (!body.probes.valid)
    throw std::runtime_error("OCCT produced an invalid shell result");

  if (naming) {
    // The synthesized offset solid has no document identity — the hole's
    // cylinder pattern verbatim: root its sub-shapes at this operation, run
    // the naming pass over the cut's REAL retained history, then (under a
    // registry) provide scaffolding records and harvest through the SAME
    // history. Synthetic face survivors re-mint as `wall`; the target's
    // untouched faces identity-survive with their records intact.
    elementNames->AddPrimitive(operationId, synthetic);
    elementNames->ApplyOperation(operationId, {object, tool}, body.shape, *cut.history, cancelled);
    if (registry != nullptr) {
      registry->HarvestSyntheticTool(operationId, synthetic, cancelled);
      registry->HarvestOperation(operationId, NamingRegistry::OperationClass::Shell,
                                 {{object, false, !inward}, {tool, true, inward}}, body.shape,
                                 *cut.history, cancelled);
    }
  }
  return body;
}

} // namespace aeth
