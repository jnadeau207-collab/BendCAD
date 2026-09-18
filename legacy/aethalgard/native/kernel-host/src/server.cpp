#include "server.hpp"

#include "hlr_projection.hpp"

#include <bit>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <exception>
#include <filesystem>
#include <optional>
#include <stdexcept>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>

#include <BRepBuilderAPI_Transform.hxx>
#include <Standard_Failure.hxx>
#include <gp_Quaternion.hxx>
#include <gp_Trsf.hxx>
#include <gp_Vec.hxx>

#include "build_manifest.hpp"
#include "element_names.hpp"
#include "geometry.hpp"
#include "mate_frame.hpp"
#include "mold_tooling_feature.hpp"
#include "mutation.hpp"
#include "naming_registry.hpp"
#include "ocaf_naming.hpp"
#include "selector_evaluator.hpp"
#include "simulation.hpp"
#include "sketch_solver.hpp"
#include "tessellate.hpp"
#include "topology.hpp"

namespace aeth {
namespace {

constexpr int kKernelProtocolVersion = 3;

bool ReplayCacheEnabled() {
  const char* const flag = std::getenv("AETH_REPLAY_CACHE");
  return flag != nullptr && std::string(flag) == "1";
}

std::string KernelGeomVersion() {
  return std::string(AETH_OCCT_TAG) + "+" + AETH_KERNEL_HOST_VERSION;
}

std::chrono::milliseconds OpTimeoutForMethod(const std::string& method) {
  if (const char* const env = std::getenv("AETH_OP_TIMEOUT_MS")) {
    char* end = nullptr;
    const long long parsed = std::strtoll(env, &end, 10);
    if (end != env && *end == '\0' && parsed >= 0)
      return std::chrono::milliseconds(parsed);
  }
  if (method == "export_step" || method == "export_step_xde" || method == "interference_exact" ||
      method == "export_mesh")
    return std::chrono::milliseconds(120000);
  return std::chrono::milliseconds(30000);
}

std::uint32_t EvaluationLodTier(const nlohmann::json& request) {
  const auto tier = request.find("lodTier");
  if (tier == request.end())
    return 0;
  if (!tier->is_number_integer() && !tier->is_number_unsigned())
    throw std::invalid_argument("lodTier must be an integer from 0 through 2");

  if (tier->is_number_unsigned()) {
    const std::uint64_t value = tier->get<std::uint64_t>();
    if (value <= 2)
      return static_cast<std::uint32_t>(value);
  } else {
    const std::int64_t value = tier->get<std::int64_t>();
    if (value >= 0 && value <= 2)
      return static_cast<std::uint32_t>(value);
  }
  throw std::invalid_argument("lodTier must be an integer from 0 through 2");
}

struct TopologySelectionRequest {
  std::string bodyId;
  std::string kind;
  std::size_t entityIndex;
};

std::optional<TopologySelectionRequest>
ParseTopologySelectionRequest(const nlohmann::json& request) {
  const auto selection = request.find("topologySelection");
  if (selection == request.end())
    return std::nullopt;
  if (request.value("includeTopology", false))
    throw std::invalid_argument(
        "includeTopology and topologySelection are mutually exclusive evaluation modes");
  if (!selection->is_object() || selection->size() != 3)
    throw std::invalid_argument(
        "topologySelection must contain exactly bodyId, kind, and entityIndex");
  if (!selection->contains("bodyId") || !(*selection)["bodyId"].is_string())
    throw std::invalid_argument("topologySelection bodyId must be a string");
  if (!selection->contains("kind") || !(*selection)["kind"].is_string())
    throw std::invalid_argument("topologySelection kind must be face, edge, or vertex");
  if (!selection->contains("entityIndex") || (!(*selection)["entityIndex"].is_number_integer() &&
                                              !(*selection)["entityIndex"].is_number_unsigned()))
    throw std::invalid_argument(
        "topologySelection entityIndex must be an integer from 0 through 999999");

  const std::string bodyId = (*selection)["bodyId"].get<std::string>();
  const std::string kind = (*selection)["kind"].get<std::string>();
  if (bodyId.empty() || bodyId.size() > 64)
    throw std::invalid_argument("topologySelection bodyId is invalid");
  if (kind != "face" && kind != "edge" && kind != "vertex")
    throw std::invalid_argument("topologySelection kind must be face, edge, or vertex");

  std::uint64_t entityIndex = 0;
  if ((*selection)["entityIndex"].is_number_unsigned()) {
    entityIndex = (*selection)["entityIndex"].get<std::uint64_t>();
  } else {
    const std::int64_t signedIndex = (*selection)["entityIndex"].get<std::int64_t>();
    if (signedIndex < 0)
      throw std::invalid_argument(
          "topologySelection entityIndex must be an integer from 0 through 999999");
    entityIndex = static_cast<std::uint64_t>(signedIndex);
  }
  if (entityIndex > 999999)
    throw std::invalid_argument(
        "topologySelection entityIndex must be an integer from 0 through 999999");
  return TopologySelectionRequest{bodyId, kind, static_cast<std::size_t>(entityIndex)};
}

bool IsAssemblyEndpointGeometry(const std::string& geometry) {
  static const std::unordered_set<std::string> kGeometry = {
      "point", "line", "axis", "circle", "plane", "cylinder", "cone", "sphere", "coordinate_frame",
  };
  return kGeometry.contains(geometry);
}

} // namespace

KernelServer::KernelServer(ProtocolWriter& writer) : writer_(writer) {}

KernelServer::~KernelServer() { Stop(); }

void KernelServer::HandleRequest(const nlohmann::json& request) {
  const std::string fallbackRequestId = "00000000-0000-0000-0000-000000000000";
  const std::string requestId =
      request.is_object() && request.contains("requestId") && request["requestId"].is_string()
          ? request["requestId"].get<std::string>()
          : fallbackRequestId;
  if (!request.is_object()) {
    WriteError(requestId, "INVALID_REQUEST", "kernel request must be an object");
    return;
  }
  if (requestId.empty()) {
    WriteError(fallbackRequestId, "INVALID_REQUEST", "requestId is required");
    return;
  }
  if (!request.contains("protocolVersion") || !request["protocolVersion"].is_number_integer() ||
      request["protocolVersion"].get<int>() != kKernelProtocolVersion) {
    WriteError(requestId, "INVALID_REQUEST", "unsupported kernel protocol version");
    return;
  }
  if (!request.contains("method") || !request["method"].is_string()) {
    WriteError(requestId, "INVALID_REQUEST", "method is required");
    return;
  }

  const std::string method = request["method"].get<std::string>();
  if (method == "health") {
    HandleHealth(requestId);
  } else if (method == "stats") {
    HandleStats(requestId);
  } else if (method == "cancel") {
    HandleCancel(request);
  } else if (method == "evaluate_document" || method == "evaluate_definition" ||
             method == "resolve_mate_frames" || method == "mutation_case" ||
             method == "ocaf_case" || method == "export_step" || method == "export_step_xde" ||
             method == "interference_exact" || method == "export_mesh" ||
             method == "inspect_step" || method == "inspect_step_xde" || method == "query" ||
             method == "simulate" || method == "solve_sketch" || method == "hlr_project" ||
             method == "mold_draft_analysis") {
    StartWork(request);
  } else {
    WriteError(requestId, "INVALID_REQUEST", "unknown kernel method");
  }
}

void KernelServer::HandleHealth(const std::string& requestId) {
  WriteSuccess(requestId, {{"type", "health"},
                           {"build",
                            {{"kernelProtocolVersion", kKernelProtocolVersion},
                             {"kernelHostVersion", AETH_KERNEL_HOST_VERSION},
                             {"occtTag", AETH_OCCT_TAG},
                             {"occtCommit", AETH_OCCT_COMMIT},
                             {"occtManifestSha256", AETH_OCCT_MANIFEST_SHA256},
                             {"compiler", AETH_COMPILER},
                             {"buildType", AETH_BUILD_TYPE}}}});
}

void KernelServer::HandleStats(const std::string& requestId) {
  const DocumentEvaluator::CacheStats cache = evaluator_.Stats();
  const auto uptimeMs = std::chrono::duration_cast<std::chrono::milliseconds>(
                            std::chrono::steady_clock::now() - startTime_)
                            .count();
  WriteSuccess(requestId, {{"type", "stats"},
                           {"cache",
                            {{"entries", cache.entries},
                             {"bytes", cache.bytes},
                             {"budgetBytes", cache.budgetBytes},
                             {"hits", cache.hits},
                             {"misses", cache.misses},
                             {"evictions", cache.evictions},
                             {"snapshotsStored", cache.snapshotsStored}}},
                           {"uptimeMs", static_cast<std::uint64_t>(uptimeMs)},
                           {"occtTag", AETH_OCCT_TAG},
                           {"occtCommit", AETH_OCCT_COMMIT},
                           {"kernelGeomVersion", KernelGeomVersion()}});
}

void KernelServer::HandleCancel(const nlohmann::json& request) {
  const std::string requestId = request.at("requestId").get<std::string>();
  if (!request.contains("targetRequestId") || !request["targetRequestId"].is_string()) {
    WriteError(requestId, "INVALID_REQUEST", "targetRequestId is required");
    return;
  }
  const std::string target = request["targetRequestId"].get<std::string>();
  bool cancelledCurrent = false;
  {
    std::scoped_lock lock(stateMutex_);
    if (busy_.load() && target == currentRequest_) {
      watchdog_.Cancel();
      cancelled_.store(true);
      cancelledCurrent = true;
    }
  }
  if (cancelledCurrent && worker_.joinable())
    worker_.join();
  WriteSuccess(requestId, {{"type", "cancellation"}, {"targetRequestId", target}});
}

void KernelServer::StartWork(nlohmann::json request) {
  const std::string requestId = request.at("requestId").get<std::string>();
  bool expected = false;
  if (!busy_.compare_exchange_strong(expected, true)) {
    WriteError(requestId, "BUSY", "kernel is already evaluating a request");
    return;
  }
  if (worker_.joinable())
    worker_.join();
  {
    std::scoped_lock lock(stateMutex_);
    currentRequest_ = requestId;
    cancelled_.store(false);
  }
  watchdog_.BeginRequest(OpTimeoutForMethod(request.at("method").get<std::string>()));
  worker_ =
      std::thread([this, request = std::move(request)]() mutable { RunWork(std::move(request)); });
}

void KernelServer::RunWork(nlohmann::json request) {
  const std::string requestId = request.at("requestId").get<std::string>();
  nlohmann::json response;
  try {
    const std::string method = request.at("method").get<std::string>();
    nlohmann::json result;
    if (method == "evaluate_document") {
      result = Evaluate(request);
    } else if (method == "evaluate_definition") {
      result = EvaluateDefinition(request);
    } else if (method == "resolve_mate_frames") {
      result = ResolveMateFramesRequest(request);
    } else if (method == "export_mesh") {
      result = ExportMesh(request);
    } else if (method == "hlr_project") {
      result = HlrProject(request);
    } else if (method == "mutation_case") {
      result = MutationCase(request);
    } else if (method == "ocaf_case") {
      result = OcafCase(request);
    } else if (method == "export_step") {
      result = Export(request);
    } else if (method == "export_step_xde") {
      result = ExportXde(request);
    } else if (method == "interference_exact") {
      result = Interference(request);
    } else if (method == "inspect_step") {
      result = Inspect(request);
    } else if (method == "inspect_step_xde") {
      result = InspectXde(request);
    } else if (method == "query") {
      result = Query(request);
    } else if (method == "simulate") {
      result = Simulate(request);
    } else if (method == "solve_sketch") {
      result = SolveSketchRequest(request);
    } else if (method == "mold_draft_analysis") {
      result = MoldDraftAnalysis(request);
    } else {
      throw std::invalid_argument("unknown kernel work method");
    }
    response = MakeSuccess(requestId, result);
  } catch (const Cancelled&) {
    const OperationTimeout timeout = watchdog_.Result();
    if (timeout.tripped) {
      response = MakeError(requestId, "TIMEOUT", "operation exceeded its per-operation time budget",
                           timeout.operationId,
                           {{"timeoutMs", static_cast<std::int64_t>(timeout.budget.count())}});
    } else {
      response = MakeError(requestId, "CANCELLED", "kernel request was cancelled");
    }
  } catch (const ReferenceMissing& error) {
    response = MakeError(requestId, "REFERENCE_MISSING", error.what(), error.OperationId());
  } catch (const SelectorFailure& error) {
    response =
        MakeError(requestId, error.Code(), error.what(), error.OperationId(), error.Details());
  } catch (const OperationFailure& error) {
    response =
        MakeError(requestId, error.Code(), error.what(), error.OperationId(), error.Details());
  } catch (const nlohmann::json::exception& error) {
    response = MakeError(requestId, "INVALID_REQUEST", error.what());
  } catch (const std::invalid_argument& error) {
    const std::string message = error.what();
    response = MakeError(requestId,
                         message.starts_with("unsupported operation") ? "UNSUPPORTED_OPERATION"
                                                                      : "INVALID_REQUEST",
                         message);
  } catch (const Standard_Failure& error) {
    response = MakeError(requestId, "GEOMETRY_FAILED", error.what());
  } catch (const std::filesystem::filesystem_error& error) {
    response = MakeError(requestId, "IO_ERROR", error.what());
  } catch (const std::exception& error) {
    response = MakeError(requestId, "INTERNAL_ERROR", error.what());
  } catch (...) {
    response = MakeError(requestId, "INTERNAL_ERROR", "unknown native exception");
  }

  {
    std::scoped_lock lock(stateMutex_);
    busy_.store(false);
    currentRequest_.clear();
  }
  try {
    writer_.WriteControl(response);
  } catch (const ProtocolError& error) {
    if (std::string(error.what()) != "control response exceeds the frame budget")
      throw;
    writer_.WriteControl(
        MakeError(requestId, "INTERNAL_ERROR",
                  std::string("kernel response could not be published: ") + error.what()));
  }
}

namespace {

bool SketchKindFromWire(const std::string& kind, SketchSolverEntityKind& out) {
  if (kind == "point") {
    out = SketchSolverEntityKind::Point;
  } else if (kind == "line") {
    out = SketchSolverEntityKind::Line;
  } else if (kind == "polyline") {
    out = SketchSolverEntityKind::Polyline;
  } else if (kind == "rectangle") {
    out = SketchSolverEntityKind::Rectangle;
  } else if (kind == "circle") {
    out = SketchSolverEntityKind::Circle;
  } else if (kind == "arc-center") {
    out = SketchSolverEntityKind::Arc;
  } else if (kind == "arc-three-point") {
    out = SketchSolverEntityKind::ArcThreePoint;
  } else if (kind == "ellipse") {
    out = SketchSolverEntityKind::Ellipse;
  } else if (kind == "polygon") {
    out = SketchSolverEntityKind::Polygon;
  } else if (kind == "slot") {
    out = SketchSolverEntityKind::Slot;
  } else if (kind == "spline") {
    out = SketchSolverEntityKind::Spline;
  } else {
    return false;
  }
  return true;
}

bool SketchAnchorPositionFromWire(const std::string& position, SketchSolverAnchorPosition& out) {
  if (position == "point") {
    out = SketchSolverAnchorPosition::Point;
  } else if (position == "start") {
    out = SketchSolverAnchorPosition::Start;
  } else if (position == "end") {
    out = SketchSolverAnchorPosition::End;
  } else if (position == "center") {
    out = SketchSolverAnchorPosition::Center;
  } else if (position == "mid") {
    out = SketchSolverAnchorPosition::Mid;
  } else {
    return false;
  }
  return true;
}

void SketchValuesFromWire(const nlohmann::json& entity, SketchSolverEntityKind kind,
                          SketchParameterValues& out) {
  const auto number = [&](const char* key, std::size_t index) {
    return entity.at(key).at(index).get<double>();
  };
  switch (kind) {
  case SketchSolverEntityKind::Point:
    out = {number("at", 0), number("at", 1)};
    return;
  case SketchSolverEntityKind::Line:
    out = {number("p1", 0), number("p1", 1), number("p2", 0), number("p2", 1)};
    return;
  case SketchSolverEntityKind::Polyline:
  case SketchSolverEntityKind::Spline:
    for (const auto& point : entity.at("points")) {
      out.push_back(point.at(0).get<double>());
      out.push_back(point.at(1).get<double>());
    }
    return;
  case SketchSolverEntityKind::Rectangle:
    out = {number("position", 0), number("position", 1), entity.at("width").get<double>(),
           entity.at("height").get<double>(), entity.at("rotation").get<double>()};
    return;
  case SketchSolverEntityKind::Circle:
    out = {number("center", 0), number("center", 1), entity.at("radius").get<double>()};
    return;
  case SketchSolverEntityKind::Arc:
    out = {number("center", 0), number("center", 1), entity.at("radius").get<double>(),
           entity.at("startAngle").get<double>(), entity.at("endAngle").get<double>()};
    return;
  case SketchSolverEntityKind::ArcThreePoint:
    out = {number("p1", 0), number("p1", 1), number("p2", 0),
           number("p2", 1), number("p3", 0), number("p3", 1)};
    return;
  case SketchSolverEntityKind::Ellipse:
    out = {number("center", 0), number("center", 1), entity.at("radiusX").get<double>(),
           entity.at("radiusY").get<double>(), entity.at("rotation").get<double>()};
    return;
  case SketchSolverEntityKind::Polygon:
    out = {number("center", 0), number("center", 1), entity.at("sides").get<double>(),
           entity.at("circumradius").get<double>(), entity.at("rotation").get<double>()};
    return;
  case SketchSolverEntityKind::Slot:
    out = {number("p1", 0), number("p1", 1), number("p2", 0), number("p2", 1),
           entity.at("width").get<double>()};
    return;
  }
}

const char* SketchStatusToWire(SketchSolverStatus status) {
  switch (status) {
  case SketchSolverStatus::Converged:
    return "converged";
  case SketchSolverStatus::Conflicting:
    return "conflicting";
  case SketchSolverStatus::Redundant:
    return "redundant";
  case SketchSolverStatus::DidNotConverge:
    return "did-not-converge";
  case SketchSolverStatus::Invalid:
    return "invalid";
  }
  return "invalid";
}

nlohmann::json SketchRefusal(const std::string& message) {
  return {{"type", "sketch_solution"},
          {"status", "invalid"},
          {"conflicting", nlohmann::json::array()},
          {"redundant", nlohmann::json::array()},
          {"message", message}};
}

nlohmann::json SolveSketchPayload(const nlohmann::json& payload) {
  SketchSolverSystem system;

  for (const auto& entity : payload.at("entities")) {
    SketchSolverEntity solverEntity;
    solverEntity.eid = entity.at("eid").get<std::string>();
    const std::string kindName = entity.at("kind").get<std::string>();
    if (!SketchKindFromWire(kindName, solverEntity.kind)) {
      return SketchRefusal("This sketch contains a " + kindName +
                           ", which the constraint solver does not handle yet. Use lines, "
                           "arcs, circles and points.");
    }
    SketchValuesFromWire(entity, solverEntity.kind, solverEntity.values);
    system.entities.push_back(std::move(solverEntity));
  }

  const auto anchorFromWire = [](const nlohmann::json& anchor, SketchSolverAnchor& out) {
    out.eid = anchor.at("eid").get<std::string>();
    return SketchAnchorPositionFromWire(anchor.at("at").get<std::string>(), out.position);
  };

  for (const auto& constraint : payload.at("constraints")) {
    SketchSolverConstraint solverConstraint;
    solverConstraint.cid = constraint.at("cid").get<std::string>();
    const std::string kind = constraint.at("kind").get<std::string>();
    solverConstraint.driving = constraint.value("driving", true);

    auto addAnchorPair = [&]() -> bool {
      SketchSolverAnchor a;
      SketchSolverAnchor b;
      if (!anchorFromWire(constraint.at("a"), a) || !anchorFromWire(constraint.at("b"), b)) {
        return false;
      }
      solverConstraint.anchors.push_back(std::move(a));
      solverConstraint.anchors.push_back(std::move(b));
      return true;
    };

    if (kind == "coincident" || kind == "distance" || kind == "horizontal-distance" ||
        kind == "vertical-distance" || kind == "length") {
      if (kind == "coincident") {
        solverConstraint.kind = SketchSolverConstraintKind::Coincident;
      } else if (kind == "distance") {
        solverConstraint.kind = SketchSolverConstraintKind::Distance;
      } else if (kind == "horizontal-distance") {
        solverConstraint.kind = SketchSolverConstraintKind::HorizontalDistance;
      } else if (kind == "vertical-distance") {
        solverConstraint.kind = SketchSolverConstraintKind::VerticalDistance;
      } else {
        solverConstraint.kind = SketchSolverConstraintKind::Length;
      }
      if (!addAnchorPair()) {
        return SketchRefusal("Constraint " + solverConstraint.cid +
                             " uses an unknown anchor position.");
      }
      if (kind != "coincident")
        solverConstraint.value = constraint.at("value").get<double>();
    } else if (kind == "horizontal" || kind == "vertical") {
      solverConstraint.kind = kind == "horizontal" ? SketchSolverConstraintKind::Horizontal
                                                   : SketchSolverConstraintKind::Vertical;
      const std::string eid = constraint.at("eid").get<std::string>();
      solverConstraint.anchors.push_back({eid, SketchSolverAnchorPosition::Start});
      solverConstraint.anchors.push_back({eid, SketchSolverAnchorPosition::End});
    } else if (kind == "parallel" || kind == "perpendicular" || kind == "angle" ||
               kind == "angular" || kind == "tangent" || kind == "equal" || kind == "concentric" ||
               kind == "midpoint" || kind == "collinear") {
      if (kind == "parallel") {
        solverConstraint.kind = SketchSolverConstraintKind::Parallel;
      } else if (kind == "perpendicular") {
        solverConstraint.kind = SketchSolverConstraintKind::Perpendicular;
      } else if (kind == "angle" || kind == "angular") {
        solverConstraint.kind = SketchSolverConstraintKind::Angle;
        solverConstraint.value = constraint.at("value").get<double>();
      } else if (kind == "tangent") {
        solverConstraint.kind = SketchSolverConstraintKind::Tangent;
      } else if (kind == "equal") {
        solverConstraint.kind = SketchSolverConstraintKind::Equal;
      } else if (kind == "concentric") {
        solverConstraint.kind = SketchSolverConstraintKind::Concentric;
      } else if (kind == "midpoint") {
        solverConstraint.kind = SketchSolverConstraintKind::Midpoint;
      } else {
        solverConstraint.kind = SketchSolverConstraintKind::Collinear;
      }
      solverConstraint.anchors.push_back(
          {constraint.at("a").get<std::string>(), SketchSolverAnchorPosition::Start});
      solverConstraint.anchors.push_back(
          {constraint.at("b").get<std::string>(), SketchSolverAnchorPosition::Start});
    } else if (kind == "symmetry") {
      solverConstraint.kind = SketchSolverConstraintKind::Symmetry;
      SketchSolverAnchor a;
      SketchSolverAnchor b;
      if (!anchorFromWire(constraint.at("a"), a) || !anchorFromWire(constraint.at("b"), b)) {
        return SketchRefusal("Constraint " + solverConstraint.cid +
                             " uses an unknown symmetry anchor position.");
      }
      solverConstraint.anchors.push_back(std::move(a));
      solverConstraint.anchors.push_back(std::move(b));
      solverConstraint.anchors.push_back(
          {constraint.at("axis").get<std::string>(), SketchSolverAnchorPosition::Start});
    } else if (kind == "radius" || kind == "diameter") {
      solverConstraint.kind = kind == "radius" ? SketchSolverConstraintKind::Radius
                                               : SketchSolverConstraintKind::Diameter;
      solverConstraint.anchors.push_back(
          {constraint.at("eid").get<std::string>(), SketchSolverAnchorPosition::Center});
      solverConstraint.value = constraint.at("value").get<double>();
    } else if (kind == "fix" || kind == "ground") {
      solverConstraint.kind = SketchSolverConstraintKind::Fixed;
      solverConstraint.anchors.push_back(
          {constraint.at("eid").get<std::string>(), SketchSolverAnchorPosition::Point});
    } else {
      return SketchRefusal("Constraint " + solverConstraint.cid + " is of an unknown kind.");
    }
    system.constraints.push_back(std::move(solverConstraint));
  }

  for (const auto& grounded : payload.at("grounded"))
    system.grounded.push_back({grounded.get<std::string>()});

  const SketchSolverResult solved = SolveSketch(system);
  nlohmann::json result = {{"type", "sketch_solution"},
                           {"status", SketchStatusToWire(solved.status)},
                           {"message", solved.message},
                           {"conflicting", solved.conflicting},
                           {"redundant", solved.redundant}};
  if (solved.status == SketchSolverStatus::Converged ||
      solved.status == SketchSolverStatus::Redundant) {
    nlohmann::json entities = nlohmann::json::array();
    for (const SketchSolverEntity& entity : solved.entities)
      entities.push_back({{"eid", entity.eid}, {"values", entity.values}});
    result["solution"] = {{"entities", entities}, {"degreesOfFreedom", solved.degreesOfFreedom}};
  }
  return result;
}

bool SketchSolutionsBitIdentical(const nlohmann::json& actual, const nlohmann::json& stored) {
  try {
    if (!actual.is_object() || !stored.is_object() ||
        actual.at("degreesOfFreedom").get<int>() != stored.at("degreesOfFreedom").get<int>())
      return false;
    const nlohmann::json& actualEntities = actual.at("entities");
    const nlohmann::json& storedEntities = stored.at("entities");
    if (!actualEntities.is_array() || !storedEntities.is_array() ||
        actualEntities.size() != storedEntities.size())
      return false;
    for (std::size_t entityIndex = 0; entityIndex < actualEntities.size(); ++entityIndex) {
      const nlohmann::json& actualEntity = actualEntities.at(entityIndex);
      const nlohmann::json& storedEntity = storedEntities.at(entityIndex);
      if (actualEntity.at("eid").get<std::string>() != storedEntity.at("eid").get<std::string>())
        return false;
      const nlohmann::json& actualValues = actualEntity.at("values");
      const nlohmann::json& storedValues = storedEntity.at("values");
      if (!actualValues.is_array() || !storedValues.is_array() ||
          actualValues.size() != storedValues.size())
        return false;
      for (std::size_t valueIndex = 0; valueIndex < actualValues.size(); ++valueIndex) {
        const double actualValue = actualValues.at(valueIndex).get<double>();
        const double storedValue = storedValues.at(valueIndex).get<double>();
        if (std::bit_cast<std::uint64_t>(actualValue) != std::bit_cast<std::uint64_t>(storedValue))
          return false;
      }
    }
  } catch (const nlohmann::json::exception&) {
    return false;
  }
  return true;
}

void AssertSketchSolutionsReproduce(const nlohmann::json& request) {
  if (!request.contains("operations") || !request.at("operations").is_array())
    return;
  for (const auto& operation : request.at("operations")) {
    if (!operation.is_object() || operation.value("type", std::string()) != "sketch")
      continue;
    const std::string operationId = operation.value("id", std::string());
    const nlohmann::json& parameters = operation.at("parameters");
    if (!parameters.contains("solution"))
      continue;

    nlohmann::json payload;
    payload["entities"] = parameters.at("entities");
    payload["constraints"] = parameters.value("constraints", nlohmann::json::array());
    payload["grounded"] = parameters.value("grounded", nlohmann::json::array());

    const nlohmann::json outcome = SolveSketchPayload(payload);
    if (!outcome.contains("solution")) {
      throw OperationFailure(operationId, "GEOMETRY_FAILED",
                             "this sketch no longer solves: " +
                                 outcome.at("message").get<std::string>());
    }
    if (!SketchSolutionsBitIdentical(outcome.at("solution"), parameters.at("solution"))) {
      throw OperationFailure(
          operationId, "GEOMETRY_FAILED",
          "this sketch re-solved to different coordinates than the ones saved with it, so "
          "the document cannot be trusted to reopen the same shape");
    }
  }
}

} // namespace

nlohmann::json KernelServer::ShapeEvaluatedBodies(const std::vector<EvaluatedBody>& bodies,
                                                  std::uint32_t epoch, std::uint32_t lodTier,
                                                  bool includeTopology, bool includeElementNames,
                                                  ElementNameBook* elementNames,
                                                  const char* idKey) {
  nlohmann::json bodyResults = nlohmann::json::array();
  for (std::size_t bodyIndex = 0; bodyIndex < bodies.size(); ++bodyIndex) {
    const auto& body = bodies[bodyIndex];
    if (cancelled_.load())
      throw Cancelled();
    const std::uint32_t sequence = streamSequence_.fetch_add(1) + 1;
    TessellationPacket packet = TessellateShape(body.shape, sequence, cancelled_, lodTier);
    packet.descriptor["epoch"] = epoch;
    nlohmann::json topology;
    if (includeTopology)
      topology = DescribeTopology(body, epoch, static_cast<std::uint32_t>(bodyIndex), cancelled_);
    writer_.WriteMesh(sequence, packet.bytes);
    nlohmann::json bodyResult = {
        {idKey, body.bodyId},
        {"operationId", body.operationId},
        {"probes", ProbesToJson(body.probes)},
        {"mesh", std::move(packet.descriptor)},
    };
    if (body.outputIndex != 0)
      bodyResult["outputIndex"] = body.outputIndex;
    if (includeTopology)
      bodyResult["topology"] = std::move(topology);
    if (includeElementNames) {
      bodyResult["elementNames"] = ProjectElementNames(*elementNames, body.shape, epoch,
                                                       static_cast<std::uint32_t>(bodyIndex));
    }
    bodyResults.push_back(std::move(bodyResult));
  }
  return bodyResults;
}

nlohmann::json KernelServer::Evaluate(const nlohmann::json& request) {
  AssertSketchSolutionsReproduce(request);
  const std::uint32_t lodTier = EvaluationLodTier(request);
  const std::optional<TopologySelectionRequest> topologySelection =
      ParseTopologySelectionRequest(request);
  const bool includeElementNames = request.value("includeElementNames", false);
  const std::string documentId = request.value("documentId", std::string());
  DocumentEvaluator::Result evaluated =
      evaluator_.Evaluate(request.at("operations"), documentId, KernelGeomVersion(),
                          includeElementNames, ReplayCacheEnabled(), cancelled_, &watchdog_);
  const std::vector<EvaluatedBody>& bodies = evaluated.bodies;
  if (topologySelection) {
    bool bodyFound = false;
    for (const EvaluatedBody& body : bodies) {
      if (body.bodyId == topologySelection->bodyId) {
        bodyFound = true;
        break;
      }
    }
    if (!bodyFound)
      throw std::invalid_argument("topologySelection bodyId is not present in the evaluation");
  }

  const std::uint32_t epoch = epoch_.fetch_add(1) + 1;
  const bool includeTopology = request.value("includeTopology", false);
  nlohmann::json bodyResults =
      ShapeEvaluatedBodies(bodies, epoch, lodTier, includeTopology, includeElementNames,
                           includeElementNames ? &*evaluated.elementNames : nullptr, "bodyId");
  if (topologySelection) {
    for (std::size_t bodyIndex = 0; bodyIndex < bodies.size(); ++bodyIndex) {
      if (bodies[bodyIndex].bodyId == topologySelection->bodyId) {
        bodyResults[bodyIndex]["topologySelection"] = DescribeTopologySelection(
            bodies[bodyIndex], topologySelection->kind, topologySelection->entityIndex, cancelled_);
        break;
      }
    }
  }
  return {{"type", "evaluation"},
          {"revision", request.at("revision")},
          {"epoch", epoch},
          {"bodies", std::move(bodyResults)}};
}

nlohmann::json KernelServer::EvaluateDefinition(const nlohmann::json& request) {
  AssertSketchSolutionsReproduce(request);
  const std::string definitionId = request.at("definitionId").get<std::string>();
  const std::string revisionHash = request.at("revisionHash").get<std::string>();
  const std::uint32_t lodTier = EvaluationLodTier(request);
  const bool includeTopology = request.value("includeTopology", false);
  const bool includeElementNames = request.value("includeElementNames", false);
  std::optional<ElementNameBook> book;
  if (includeElementNames)
    book.emplace();
  const std::vector<EvaluatedBody> bodies =
      EvaluateOperations(request.at("operations"), cancelled_,
                         includeElementNames ? &*book : nullptr, nullptr, &watchdog_);
  const std::uint32_t epoch = epoch_.fetch_add(1) + 1;
  nlohmann::json bodyResults =
      ShapeEvaluatedBodies(bodies, epoch, lodTier, includeTopology, includeElementNames,
                           includeElementNames ? &*book : nullptr, "definitionBodyId");
  for (std::size_t index = 0; index < bodies.size(); ++index) {
    bodyResults[index]["collisionShapeCacheKey"] =
        CollisionShapeCacheKey(revisionHash, bodies[index].bodyId);
  }
  return {{"type", "definition_evaluation"},
          {"definitionId", definitionId},
          {"revisionHash", revisionHash},
          {"epoch", epoch},
          {"bodies", std::move(bodyResults)}};
}

nlohmann::json KernelServer::ResolveMateFramesRequest(const nlohmann::json& request) {
  AssertSketchSolutionsReproduce(request);
  const std::string definitionId = request.at("definitionId").get<std::string>();
  const std::string revisionHash = request.at("revisionHash").get<std::string>();
  if (definitionId.empty())
    throw std::invalid_argument("definitionId is required");
  if (revisionHash.empty() || revisionHash.size() > 128)
    throw std::invalid_argument("revisionHash must contain 1 through 128 characters");

  const nlohmann::json& endpointPayloads = request.at("endpoints");
  if (!endpointPayloads.is_array() || endpointPayloads.empty() || endpointPayloads.size() > 4096)
    throw std::invalid_argument("endpoints must contain between 1 and 4096 items");

  std::vector<MateFrameEndpointRequest> endpoints;
  endpoints.reserve(endpointPayloads.size());
  std::unordered_set<std::string> endpointIds;
  for (const nlohmann::json& endpoint : endpointPayloads) {
    if (!endpoint.is_object() || endpoint.size() != 3 || !endpoint.contains("requestId") ||
        !endpoint.at("requestId").is_string() || !endpoint.contains("ast") ||
        !endpoint.at("ast").is_object() || !endpoint.contains("expectedGeometry") ||
        !endpoint.at("expectedGeometry").is_string()) {
      throw std::invalid_argument(
          "each endpoint must contain exactly requestId, ast, and expectedGeometry");
    }
    const std::string endpointId = endpoint.at("requestId").get<std::string>();
    if (endpointId.empty() || endpointId.size() > 128)
      throw std::invalid_argument("endpoint requestId must contain 1 through 128 characters");
    if (!endpointIds.insert(endpointId).second)
      throw std::invalid_argument("endpoint requestId values must be unique");
    const std::string expectedGeometry = endpoint.at("expectedGeometry").get<std::string>();
    if (!IsAssemblyEndpointGeometry(expectedGeometry))
      throw std::invalid_argument("endpoint expectedGeometry is not supported");

    nlohmann::json refSlot = {{"ast", endpoint.at("ast")},
                              {"arity", "one"},
                              {"anchors", nlohmann::json::array()},
                              {"onEmpty", "error"}};
    endpoints.push_back({endpointId, std::move(refSlot), expectedGeometry});
  }

  NamingRegistry registry;
  const std::vector<EvaluatedBody> bodies =
      EvaluateOperations(request.at("operations"), cancelled_, nullptr, &registry, &watchdog_);
  const std::vector<MateFrameResolution> resolutions =
      ResolveMateFrames(endpoints, bodies, registry, cancelled_);
  if (resolutions.size() != endpoints.size())
    throw std::runtime_error("mate-frame resolver returned the wrong number of outcomes");

  nlohmann::json outcomes = nlohmann::json::array();
  for (std::size_t index = 0; index < resolutions.size(); ++index) {
    nlohmann::json outcome = MateFrameResolutionToJson(resolutions[index]);
    outcome["requestId"] = endpoints[index].requestId;
    outcomes.push_back(std::move(outcome));
  }
  return {{"type", "mate_frame_resolution"},
          {"definitionId", definitionId},
          {"revisionHash", revisionHash},
          {"outcomes", std::move(outcomes)}};
}

nlohmann::json KernelServer::ExportMesh(const nlohmann::json& request) {
  const auto bodies =
      EvaluateOperations(request.at("operations"), cancelled_, nullptr, nullptr, &watchdog_);
  const std::uint32_t epoch = epoch_.fetch_add(1) + 1;
  nlohmann::json bodyResults = nlohmann::json::array();
  for (const auto& body : bodies) {
    if (cancelled_.load())
      throw Cancelled();
    const std::uint32_t sequence = streamSequence_.fetch_add(1) + 1;
    TessellationPacket packet = TessellateShapeForExport(body.shape, sequence, cancelled_);
    packet.descriptor["epoch"] = epoch;
    writer_.WriteMesh(sequence, packet.bytes);
    nlohmann::json exportedBody = {
        {"bodyId", body.bodyId},
        {"operationId", body.operationId},
        {"mesh", std::move(packet.descriptor)},
    };
    if (body.outputIndex != 0)
      exportedBody["outputIndex"] = body.outputIndex;
    bodyResults.push_back(std::move(exportedBody));
  }
  return {{"type", "export_mesh"},
          {"revision", request.at("revision")},
          {"epoch", epoch},
          {"bodies", std::move(bodyResults)}};
}

nlohmann::json KernelServer::MutationCase(const nlohmann::json& request) {
  const std::uint32_t epoch = epoch_.fetch_add(1) + 1;
  return BuildMutationCase(request, epoch, cancelled_);
}

nlohmann::json KernelServer::OcafCase(const nlohmann::json& request) {
  return BuildOcafCase(request, cancelled_);
}

nlohmann::json KernelServer::HlrProject(const nlohmann::json& request) {
  // The top-level operations and each instance's operations are the same
  // program shape and parse the same way: evaluate, keep the bodies' shapes.
  const auto evaluateShapes = [this](const nlohmann::json& operations) {
    const auto bodies = EvaluateOperations(operations, cancelled_, nullptr, nullptr, &watchdog_);
    std::vector<TopoDS_Shape> shapes;
    shapes.reserve(bodies.size());
    for (const auto& body : bodies) {
      shapes.push_back(body.shape);
    }
    return shapes;
  };
  std::vector<TopoDS_Shape> shapes = evaluateShapes(request.at("operations"));

  // Posed assembly instances: the drawing is the union of every instance's
  // bodies, each placed by its pose — rotation quaternion x,y,z,w, then
  // translation in millimetres.
  if (request.contains("instances")) {
    for (const auto& instance : request.at("instances")) {
      if (cancelled_.load())
        throw Cancelled();
      const auto& pose = instance.at("pose");
      const auto& rotation = pose.at("rotationXyzw");
      const auto& translation = pose.at("translationMm");
      gp_Trsf placement;
      placement.SetRotation(
          gp_Quaternion(rotation.at(0).get<double>(), rotation.at(1).get<double>(),
                        rotation.at(2).get<double>(), rotation.at(3).get<double>()));
      placement.SetTranslationPart(gp_Vec(translation.at(0).get<double>(),
                                          translation.at(1).get<double>(),
                                          translation.at(2).get<double>()));
      for (const TopoDS_Shape& shape : evaluateShapes(instance.at("operations"))) {
        shapes.push_back(BRepBuilderAPI_Transform(shape, placement, true).Shape());
      }
    }
  }

  const auto vec = [&](const char* key) {
    const auto& value = request.at(key);
    return gp_Dir(value.at(0).get<double>(), value.at(1).get<double>(), value.at(2).get<double>());
  };
  // A requested section cuts every body before projection; the response then
  // carries the cut-face outlines even when no face landed on the plane.
  std::optional<HlrSectionPlane> sectionPlane;
  if (request.contains("sectionPlane")) {
    const auto& plane = request.at("sectionPlane");
    const auto& origin = plane.at("origin");
    const auto& normal = plane.at("normal");
    sectionPlane = HlrSectionPlane{
        gp_Pnt(origin.at(0).get<double>(), origin.at(1).get<double>(), origin.at(2).get<double>()),
        gp_Dir(normal.at(0).get<double>(), normal.at(1).get<double>(), normal.at(2).get<double>())};
  }
  const HlrProjectionResult projection =
      ProjectHiddenLine(shapes, vec("direction"), vec("up"), sectionPlane, cancelled_);
  nlohmann::json segments = nlohmann::json::array();
  for (const HlrSegment& segment : projection.segments) {
    segments.push_back({{"visible", segment.visible}, {"points", segment.points}});
  }
  nlohmann::json result = {{"type", "hlr_projection"},
                           {"segments", std::move(segments)},
                           {"bounds",
                            {{"minX", projection.minX},
                             {"minY", projection.minY},
                             {"maxX", projection.maxX},
                             {"maxY", projection.maxY}}},
                           {"bodyCount", shapes.size()}};
  if (sectionPlane) {
    nlohmann::json outlines = nlohmann::json::array();
    for (const std::vector<double>& outline : projection.sectionOutlines) {
      outlines.push_back({{"points", outline}});
    }
    result["sectionOutlines"] = std::move(outlines);
  }
  return result;
}

nlohmann::json KernelServer::Export(const nlohmann::json& request) {
  const auto bodies =
      EvaluateOperations(request.at("operations"), cancelled_, nullptr, nullptr, &watchdog_);
  const std::string path = request.at("outputPath").get<std::string>();
  const std::uintmax_t bytes = ExportStep(bodies, path, cancelled_);
  return {{"type", "step_export"},
          {"outputPath", path},
          {"bodyCount", bodies.size()},
          {"byteLength", bytes}};
}

nlohmann::json KernelServer::ExportXde(const nlohmann::json& request) {
  const auto bodies =
      EvaluateOperations(request.at("operations"), cancelled_, nullptr, nullptr, &watchdog_);
  const std::string path = request.at("outputPath").get<std::string>();
  const std::uintmax_t bytes = ExportStepXde(bodies, path, cancelled_);
  return {{"type", "step_xde_export"},
          {"outputPath", path},
          {"bodyCount", bodies.size()},
          {"byteLength", bytes},
          {"representation", "xde"}};
}

nlohmann::json KernelServer::Interference(const nlohmann::json& request) {
  const auto bodies =
      EvaluateOperations(request.at("operations"), cancelled_, nullptr, nullptr, &watchdog_);
  return ExactInterference(bodies, request, KernelGeomVersion(), KernelGeomVersion(), cancelled_);
}

nlohmann::json KernelServer::Inspect(const nlohmann::json& request) {
  const ShapeProbes probes = InspectStep(request.at("inputPath").get<std::string>(), cancelled_);
  return {{"type", "step_inspection"}, {"probes", ProbesToJson(probes)}};
}

nlohmann::json KernelServer::InspectXde(const nlohmann::json& request) {
  return InspectStepXde(request.at("inputPath").get<std::string>(), cancelled_);
}

nlohmann::json KernelServer::SolveSketchRequest(const nlohmann::json& request) {
  return SolveSketchPayload(request);
}

nlohmann::json KernelServer::Query(const nlohmann::json& request) {
  const std::string atOperationId = request.at("atOperationId").get<std::string>();
  const nlohmann::json& operations = request.at("operations");
  nlohmann::json prefix = nlohmann::json::array();
  bool found = false;
  for (const auto& operation : operations) {
    prefix.push_back(operation);
    if (operation.at("id").get<std::string>() == atOperationId) {
      found = true;
      break;
    }
  }
  if (!found) {
    throw ReferenceMissing(
        atOperationId, "query atOperationId names no operation in the document: " + atOperationId);
  }

  NamingRegistry registry;
  const std::vector<EvaluatedBody> bodies =
      EvaluateOperations(prefix, cancelled_, nullptr, &registry, &watchdog_);
  const QueryOutcome outcome = EvaluateQuery(request.at("ast"), bodies, registry, cancelled_);

  nlohmann::json entities = nlohmann::json::array();
  for (const QueryEntity& entity : outcome.entities) {
    // Synthetic datum entities deliberately have no visible body.  They are
    // nevertheless first-class durable references: a sketch on a datum plane
    // must resolve the same query during re-edit as every model-face sketch.
    // `resolvedEntitySchema` makes the empty bodyId explicit rather than
    // pretending the datum belongs to an arbitrary body.
    entities.push_back(ResolvedEntityToJson(entity));
  }
  nlohmann::json diagnostics = nlohmann::json::array();
  for (const QueryDiagnostic& diagnostic : outcome.diagnostics) {
    nlohmann::json entry = {{"code", diagnostic.code}, {"message", diagnostic.message}};
    if (!diagnostic.token.empty())
      entry["token"] = diagnostic.token;
    diagnostics.push_back(std::move(entry));
  }
  nlohmann::json stageCardinalities = nlohmann::json::array();
  for (const std::size_t cardinality : outcome.stageCardinalities)
    stageCardinalities.push_back(cardinality);
  return {{"type", "query"},
          {"entities", std::move(entities)},
          {"diagnostics", std::move(diagnostics)},
          {"stageCardinalities", std::move(stageCardinalities)}};
}

nlohmann::json KernelServer::Simulate(const nlohmann::json& request) {
  // The study rides the wire pre-validated by the TS `simulate` member
  // (kernel-protocol-core.ts); this parse mirrors its field names exactly and
  // lets nlohmann's .at() surface any structural surprise as INVALID_REQUEST.
  const nlohmann::json& studyJson = request.at("study");
  SimulationStudy study;
  study.kind = studyJson.at("kind").get<std::string>();
  study.resolutionMm = studyJson.at("resolutionMm").get<double>();
  const nlohmann::json& material = studyJson.at("material");
  study.material.youngsModulusGPa = material.at("youngsModulusGPa").get<double>();
  study.material.poissonsRatio = material.at("poissonsRatio").get<double>();
  study.material.yieldStrengthMPa = material.at("yieldStrengthMPa").get<double>();
  study.material.thermalConductivityWPerMK = material.at("thermalConductivityWPerMK").get<double>();
  for (const nlohmann::json& constraint : studyJson.at("constraints")) {
    SimulationConstraint parsed;
    parsed.id = constraint.at("id").get<std::string>();
    parsed.ast = constraint.at("ast");
    parsed.kind = constraint.at("kind").get<std::string>();
    if (constraint.contains("valueC")) {
      parsed.valueC = constraint.at("valueC").get<double>();
    }
    study.constraints.push_back(std::move(parsed));
  }
  for (const nlohmann::json& load : studyJson.at("loads")) {
    SimulationLoad parsed;
    parsed.id = load.at("id").get<std::string>();
    parsed.ast = load.at("ast");
    parsed.kind = load.at("kind").get<std::string>();
    if (load.contains("vectorN")) {
      const nlohmann::json& vector = load.at("vectorN");
      parsed.vectorN = {vector.at(0).get<double>(), vector.at(1).get<double>(),
                        vector.at(2).get<double>()};
    }
    if (load.contains("wattsPerM2")) {
      parsed.wattsPerM2 = load.at("wattsPerM2").get<double>();
    }
    study.loads.push_back(std::move(parsed));
  }

  // Evaluate with a registry exactly as `query` does: boundary-condition asts
  // resolve through the SAME selector evaluator against the SAME replay state.
  NamingRegistry registry;
  const std::vector<EvaluatedBody> bodies =
      EvaluateOperations(request.at("operations"), cancelled_, nullptr, &registry, &watchdog_);
  const SimulationResult simulated = SimulateStudy(bodies, registry, study, cancelled_);

  nlohmann::json result = {
      {"type", "simulation_result"},
      {"kind", simulated.kind},
      {"mesh",
       {{"positions", simulated.mesh.positions},
        {"triangles", simulated.mesh.triangles},
        {"scalars", simulated.mesh.scalars}}},
      {"scalar",
       {{"name", simulated.scalarName},
        {"min", simulated.scalarMin},
        {"max", simulated.scalarMax}}},
      {"summary",
       {{"elementCount", simulated.elementCount},
        {"nodeCount", simulated.nodeCount},
        {"iterations", simulated.iterations}}},
  };
  if (simulated.kind == "static-stress") {
    result["displacementMaxMm"] = simulated.displacementMaxMm;
  }
  return result;
}

namespace {

const char* DraftClassificationLabel(const DraftClassification classification) {
  switch (classification) {
  case DraftClassification::Positive:
    return "positive";
  case DraftClassification::Negative:
    return "negative";
  case DraftClassification::NoDraft:
    return "no-draft";
  case DraftClassification::Straddle:
    return "straddle";
  }
  throw std::runtime_error("mold_draft_analysis encountered an unknown draft classification");
}

} // namespace

/**
 * `mold_draft_analysis`: a top-level, read-only RPC method (sibling to
 * `simulate`/`hlr_project`, NOT an entry in the `operations` array — it
 * bypasses `ExecuteOperation`/naming_registry/operations.ts's discriminated
 * union entirely). Confirmed via kernel investigation: geometry-producing
 * ops go through THREE registries (`ExecuteOperation` dispatch,
 * `operations.ts`'s discriminated union, `naming_registry.hpp`'s
 * `OperationClass` exhaustive switches); read-only computations over
 * already-evaluated bodies (`simulate`, `hlr_project`, `query`) are
 * top-level RPC methods dispatched right here, bypassing all three. Real
 * SolidWorks itself doesn't tree-feature Draft Analysis either (a display
 * mode, not a FeatureManager entry) — the same call, doubly grounded.
 *
 * Evaluates `operations`, resolves `bodyId` (a body id, NOT an operation
 * id — read-only draft analysis is about one concrete evaluated shape, not
 * "whatever operation produced it") against the resulting bodies, then
 * calls the SAME shared `ClassifyDraftFaces` `mold_parting_line`'s own
 * executor calls (mold_tooling_feature.hpp) — one source of truth, two
 * doors, so the live preview this backs and `mold_parting_line`'s own edge
 * walk can never drift on what counts as positive/negative/no-draft/
 * straddle for the same body and pull direction. Does not touch the
 * document — no book, no registry, nothing persisted.
 *
 * Response `type` is exactly `"mold_draft_analysis"` (NOT
 * `"mold_draft_analysis_result"`). `faces` is an array of `{token,
 * classification}` records (the array-of-records convention every other
 * per-entity wire projection in this codebase uses, never a keyed map);
 * each face's token uses the SAME `TopologyEntityToken` (topology.hpp)
 * scheme every other topology projection mints tokens with (a fresh epoch,
 * bodyOrdinal 0 — this response describes exactly one body), enumerated in
 * the SAME `TopExp::MapShapes(shape, TopAbs_FACE, ...)` order
 * `ClassifyDraftFaces` itself iterates in, so index N's token here names
 * the SAME physical face as index N of a `topologySnapshot`/`elementNames`
 * projection of the same body at the same epoch.
 */
nlohmann::json KernelServer::MoldDraftAnalysis(const nlohmann::json& request) {
  const std::string bodyId = request.at("bodyId").get<std::string>();
  const nlohmann::json& pullDirectionJson = request.at("pullDirection");
  const gp_Vec pullDirectionRaw(pullDirectionJson.at("x").get<double>(),
                                pullDirectionJson.at("y").get<double>(),
                                pullDirectionJson.at("z").get<double>());
  if (!(std::isfinite(pullDirectionRaw.X()) && std::isfinite(pullDirectionRaw.Y()) &&
        std::isfinite(pullDirectionRaw.Z())) ||
      pullDirectionRaw.Magnitude() < 1e-9) {
    throw std::invalid_argument(
        "mold_draft_analysis pullDirection must be a finite, non-zero {x, y, z} vector");
  }
  const gp_Dir pullDirection(pullDirectionRaw);
  const double toleranceDeg = request.at("draftAngleToleranceDeg").get<double>();
  if (!(std::isfinite(toleranceDeg) && toleranceDeg >= 0.0 && toleranceDeg <= 30.0)) {
    throw std::invalid_argument(
        "mold_draft_analysis draftAngleToleranceDeg must be within [0, 30]");
  }

  const std::vector<EvaluatedBody> bodies =
      EvaluateOperations(request.at("operations"), cancelled_, nullptr, nullptr, &watchdog_);
  const EvaluatedBody* target = nullptr;
  for (const EvaluatedBody& body : bodies) {
    if (body.bodyId == bodyId) {
      target = &body;
      break;
    }
  }
  if (target == nullptr) {
    // The query `atOperationId` precedent (this file's own `Query`, above):
    // a request that names no live entity in the evaluated document is
    // REFERENCE_MISSING, attributed to the name it could not resolve.
    throw ReferenceMissing(bodyId, "mold_draft_analysis bodyId names no unconsumed body in the "
                                   "evaluated document: " +
                                       bodyId);
  }

  const std::vector<DraftFaceResult> classifications =
      ClassifyDraftFaces(target->shape, pullDirection, toleranceDeg);

  const std::uint32_t epoch = epoch_.fetch_add(1) + 1;
  nlohmann::json faces = nlohmann::json::array();
  std::uint64_t positive = 0;
  std::uint64_t negative = 0;
  std::uint64_t noDraft = 0;
  std::uint64_t straddle = 0;
  for (std::size_t index = 0; index < classifications.size(); ++index) {
    const DraftClassification classification = classifications[index].classification;
    switch (classification) {
    case DraftClassification::Positive:
      ++positive;
      break;
    case DraftClassification::Negative:
      ++negative;
      break;
    case DraftClassification::NoDraft:
      ++noDraft;
      break;
    case DraftClassification::Straddle:
      ++straddle;
      break;
    }
    faces.push_back({{"token", TopologyEntityToken(epoch, 0, 'f', static_cast<int>(index))},
                     {"classification", DraftClassificationLabel(classification)}});
  }

  return {{"type", "mold_draft_analysis"},
          {"bodyId", bodyId},
          {"faces", std::move(faces)},
          {"counts",
           {{"positive", positive},
            {"negative", negative},
            {"noDraft", noDraft},
            {"straddle", straddle}}}};
}

nlohmann::json KernelServer::MakeSuccess(const std::string& requestId,
                                         const nlohmann::json& result) {
  return {{"protocolVersion", kKernelProtocolVersion},
          {"requestId", requestId},
          {"ok", true},
          {"result", result}};
}

nlohmann::json KernelServer::MakeError(const std::string& requestId, const std::string& code,
                                       const std::string& message, const std::string& operationId,
                                       const nlohmann::json& details) {
  nlohmann::json error = {{"code", code}, {"message", message}};
  if (!operationId.empty())
    error["operationId"] = operationId;
  if (!details.is_null() && !details.empty())
    error["details"] = details;
  return {{"protocolVersion", kKernelProtocolVersion},
          {"requestId", requestId},
          {"ok", false},
          {"error", std::move(error)}};
}

void KernelServer::WriteSuccess(const std::string& requestId, const nlohmann::json& result) {
  writer_.WriteControl(MakeSuccess(requestId, result));
}

void KernelServer::WriteError(const std::string& requestId, const std::string& code,
                              const std::string& message, const std::string& operationId) {
  writer_.WriteControl(MakeError(requestId, code, message, operationId));
}

void KernelServer::Stop() {
  cancelled_.store(true);
  if (worker_.joinable())
    worker_.join();
}

} // namespace aeth
