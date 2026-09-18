#pragma once

#include <array>
#include <atomic>
#include <optional>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "selector_evaluator.hpp"

namespace aeth {

class NamingRegistry;

/// One of spec section 5's six mate-frame geometry classes. A frame's
/// `geometry` names which analytic extraction rule produced `origin`/
/// `primary`/`secondary` — never the source topology kind (a circular edge
/// and a cylindrical face can both resolve to `Cylinder`).
enum class MateFrameGeometry { Point, Axis, Plane, Cylinder, Cone, Sphere };

/// The exact analytic frame plan 07 section 5 requires for one endpoint.
/// `primary` is the plane normal / cylinder-cone-axis direction / datum
/// primary axis; `secondary` is the deterministic in-plane tangent for planar
/// frames and unused (zero) for the rotationally-symmetric classes, matching
/// `orientationClass == "isotropic"`. `sourceEvidence` is the
/// topologySelectionEvidenceSchema-shaped payload DescribeTopologyEvidence
/// (topology.hpp) produced for the resolved shape.
struct MateFrame final {
  std::array<double, 3> origin{};
  std::array<double, 3> primary{};
  std::array<double, 3> secondary{};
  MateFrameGeometry geometry{};
  std::optional<double> radius;
  std::optional<double> halfAngleRad;
  std::string orientationClass; // "directed" | "undirected-axis" | "isotropic"
  nlohmann::json sourceEvidence;
};

/// The four named outcomes ASM-005's exit criterion requires. A relationship
/// endpoint is never silently rebound to similar geometry (plan 07 section
/// 2.6): every outcome short of `Resolved` is a typed, attributable refusal.
enum class MateFrameStatus { Resolved, Missing, Ambiguous, Invalidated };

/// The result of resolving one assembly endpoint. Exactly one of `frame` /
/// `candidates` is populated, gated by `status`, mirroring `RefResolution`'s
/// status-gated shape in ref_resolution.hpp.
struct MateFrameResolution final {
  MateFrameStatus status = MateFrameStatus::Missing;
  std::optional<MateFrame> frame;      // set iff Resolved
  std::vector<QueryEntity> candidates; // set iff Ambiguous (mirrors RefResolution.candidates)
  std::string message;
};

/// Resolves ONE assembly endpoint: runs the existing ResolveRef (arity is
/// ALWAYS forced to "one" regardless of what refSlot.arity says — an endpoint
/// is a single-entity reference by definition, per spec section 3; this
/// function must overwrite/ignore any other arity value defensively, in
/// depth, exactly as document-model's own schema-level .refine() already
/// requires at the TS boundary) against `bodies`/`registry`, then checks the
/// resolved entity's actual OCCT geometry class against `expectedGeometry`
/// (one of geometry-contracts' assemblyEndpointGeometrySchema string values:
/// "point"|"line"|"axis"|"circle"|"plane"|"cylinder"|"cone"|"sphere"|
/// "coordinate_frame"), and on a match extracts the analytic MateFrame per
/// spec section 5's rules. `endpointAst` is the wire-parsed AQL AST (the
/// SAME shape ResolveRef's refSlot.at("ast") already expects) wrapped exactly
/// like a refSlot: `{"ast": <ast>, "arity": "one", "anchors": [...], "onEmpty": "error"}`.
MateFrameResolution ResolveMateFrame(const nlohmann::json& endpointRefSlot,
                                     const std::string& expectedGeometry,
                                     const std::vector<EvaluatedBody>& bodies,
                                     const NamingRegistry& registry,
                                     const std::atomic_bool& cancelled);

/// Serializes one MateFrameResolution to JSON matching
/// endpointResolutionOutcomeSchema (minus requestId, which the batch caller
/// attaches — see below).
nlohmann::json MateFrameResolutionToJson(const MateFrameResolution& resolution);

/// One endpoint of a `resolveMateFramesRequestSchema` batch: the caller's
/// correlation id, the `{ast, arity, anchors, onEmpty}` refSlot
/// ResolveMateFrame expects (arity ignored/forced to one, see above), and the
/// expected OCCT geometry class.
struct MateFrameEndpointRequest final {
  std::string requestId;
  nlohmann::json refSlot;
  std::string expectedGeometry;
};

/// Resolves several endpoints against ONE shared evaluated definition
/// (bodies/registry from a single EvaluateOperations call) — the batch shape
/// resolveMateFramesRequestSchema's `endpoints` array needs. Order-preserving:
/// outcomes[i] answers endpoints[i].
std::vector<MateFrameResolution>
ResolveMateFrames(const std::vector<MateFrameEndpointRequest>& endpoints,
                  const std::vector<EvaluatedBody>& bodies, const NamingRegistry& registry,
                  const std::atomic_bool& cancelled);

} // namespace aeth
