// Voxel finite-element simulation: the seam between evaluated 3D bodies and
// the strength / heat questions an agent asks of them ("does this bracket
// hold", "where does the heat go"). The answers are genuinely computed
// physics — trilinear hexahedral elements on a uniform voxelization, a real
// sparse conjugate-gradient solve, stress recovery from the strain field —
// never a shaded guess. Two study kinds share the machinery: static linear
// elasticity (3 DOF per node) and steady-state heat conduction (1 DOF per
// node).
//
// Boundary conditions arrive as selector ASTs (the same wire form the `query`
// method evaluates) so a study names faces the way every other reference in
// the document does; the evaluator resolves them against the same replay
// state, and a selector that resolves to nothing is a typed refusal, never a
// silently unloaded model.
#pragma once

#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

#include "geometry.hpp"

namespace aeth {

class NamingRegistry;

/// Hard cap on occupied voxel elements. Above it the assembled system (up to
/// ~27 neighbor blocks per node) outgrows what an interactive host should
/// attempt, so the study is refused with SIM_RESOLUTION before any matrix
/// exists — the repair is a coarser `resolutionMm`, and the refusal names
/// this cap and the computed count.
inline constexpr std::size_t kSimulationElementCap = 150000;

/// Conjugate-gradient iteration cap. A well-posed voxel study converges far
/// below it; hitting the cap is reported as SIM_DID_NOT_CONVERGE naming the
/// relative residual, never returned as a half-converged field.
inline constexpr std::size_t kSimulationCgMaxIterations = 10000;

struct SimulationMaterial final {
  /// Young's modulus in GPa (converted to MPa internally: N/mm/MPa units).
  double youngsModulusGPa{};
  /// Poisson's ratio, inside (-1, 0.5) — 0.5 exactly is incompressible and
  /// has no isotropic stiffness matrix.
  double poissonsRatio{};
  /// Carried for the caller's factor-of-safety display; the linear solve
  /// itself never reads it.
  double yieldStrengthMPa{};
  /// Thermal conductivity in W/(m*K) (converted to W/(mm*K) internally).
  double thermalConductivityWPerMK{};
};

struct SimulationConstraint final {
  /// Caller-chosen handle, echoed by SIM_BC_UNRESOLVED so the failing
  /// constraint is nameable without positional guessing.
  std::string id;
  /// Selector AST (plan 05 §3 wire form) resolving the constrained faces.
  nlohmann::json ast;
  /// "fixed" (static-stress: all 3 DOF clamped to zero) or "temperature"
  /// (steady-heat: Dirichlet at `valueC`).
  std::string kind;
  /// Prescribed temperature in Celsius; read only when kind == "temperature".
  double valueC{};
};

struct SimulationLoad final {
  /// Caller-chosen handle, echoed by SIM_BC_UNRESOLVED (see constraint id).
  std::string id;
  /// Selector AST resolving the loaded faces.
  nlohmann::json ast;
  /// "force" (static-stress) or "heat-flux" (steady-heat).
  std::string kind;
  /// TOTAL force in newtons, split equally over the matched skin nodes; read
  /// only when kind == "force".
  std::array<double, 3> vectorN{};
  /// Inward heat flux in W/m² over the matched skin patch; read only when
  /// kind == "heat-flux". Positive flows INTO the body.
  double wattsPerM2{};
};

struct SimulationStudy final {
  /// "static-stress" or "steady-heat".
  std::string kind;
  /// Voxel edge length in millimetres.
  double resolutionMm{};
  SimulationMaterial material;
  std::vector<SimulationConstraint> constraints;
  std::vector<SimulationLoad> loads;
};

/// The voxel SKIN (boundary quads of occupied voxels, two triangles each,
/// deduplicated vertices, outward winding) with one recovered scalar per
/// emitted vertex — exactly what a heat-map render consumes.
struct SimulationMesh final {
  /// Flattened x,y,z in millimetres — length is a multiple of 3.
  std::vector<double> positions;
  /// Flattened vertex-index triples into positions/3 — length a multiple of 3.
  std::vector<std::uint32_t> triangles;
  /// One scalar per vertex (positions.size() / 3 entries).
  std::vector<double> scalars;
};

struct SimulationResult final {
  /// Echo of the study kind.
  std::string kind;
  SimulationMesh mesh;
  /// "vonMisesMPa" (static-stress) or "temperatureC" (steady-heat).
  std::string scalarName;
  /// Extremes over the EMITTED skin vertices.
  double scalarMin{};
  double scalarMax{};
  /// Maximum nodal displacement magnitude in mm; meaningful only for
  /// "static-stress" (the serializer omits it for steady-heat).
  double displacementMaxMm{};
  std::size_t elementCount{};
  std::size_t nodeCount{};
  /// Conjugate-gradient iterations actually run.
  std::size_t iterations{};
};

/// Runs one study over the evaluated `bodies`, resolving every boundary
/// condition through the SAME selector evaluator the `query` method uses
/// (against `registry`, which EvaluateOperations populated for these bodies).
///
/// Typed refusals ride the existing OperationFailure envelope with the fine
/// code in details.simulationCode and in the message:
///  - SIM_BC_UNRESOLVED  (REFERENCE_MISSING): a constraint/load ast resolved
///    to zero entities (the failing id is named). A LOAD that resolves but
///    matches zero mesh nodes at this resolution also refuses under this
///    code — a load that binds nothing must not silently vanish; a
///    CONSTRAINT in the same position instead feeds the aggregate
///    SIM_UNCONSTRAINED guard below.
///  - SIM_UNCONSTRAINED  (INVALID_REQUEST): no constraint clamped any node,
///    so the operator is singular; raised before assembly.
///  - SIM_RESOLUTION     (INVALID_REQUEST): occupied elements would exceed
///    kSimulationElementCap; raised before assembly, naming cap and count.
///  - SIM_DID_NOT_CONVERGE (GEOMETRY_FAILED): CG hit
///    kSimulationCgMaxIterations; the relative residual is named.
SimulationResult SimulateStudy(const std::vector<EvaluatedBody>& bodies,
                               const NamingRegistry& registry, const SimulationStudy& study,
                               const std::atomic_bool& cancelled);

} // namespace aeth
