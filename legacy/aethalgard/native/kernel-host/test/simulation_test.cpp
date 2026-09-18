// The voxel FEM seam, proven against closed-form mechanics and conduction on
// a bar whose answers are knowable by hand. These drive the REAL path the
// server's `simulate` handler threads — EvaluateOperations with a registry,
// boundary conditions through the selector evaluator, then SimulateStudy —
// and every expectation carries its hand computation. What is pinned is
// physics truth (sigma = F/A, delta = FL/EA, FL^3/3EI, linear conduction),
// the typed refusals, and byte-identical determinism — never OCCT internals.
//
// Shared grid arithmetic the expectations lean on (resolution 5 mm):
// create_box centers x/y on its placement origin and rests on z, so the
// 100x10x10 bar spans x[-50,50], y[-5,5], z[0,10]. The voxelizer covers each
// span with ceil(span/h)+1 cells centered on the bounds (>= half-voxel margin
// per side): 21x3x3 cells from origin (-52.5,-7.5,-2.5). Occupancy samples
// sit at cell centers + h*1e-4, so exactly 20x2x2 = 80 elements fill — a
// voxel bar of exactly 100x10x10 mm shifted (-2.5,-2.5,-2.5) from the
// geometry, with node planes x in {-52.5,-47.5,...,47.5}, y in
// {-7.5,-2.5,2.5}, z in {-2.5,2.5,7.5} and (20+1)*3*3 = 189 nodes.
//
// Boundary matching (tolerance 0.9h = 4.5 mm): the x=-50 face reaches the
// -52.5 cap plane (9 nodes, corner distance sqrt(3*2.5^2) = 4.33 <= 4.5) AND
// the 8 skin ring nodes of the -47.5 plane (its 9th, central node is
// interior, not skin) — 17 clamped. The x=+50 face reaches only the 47.5 cap
// plane (9 nodes; the 42.5 plane is 7.5 > 4.5 away).
#include <algorithm>
#include <array>
#include <atomic>
#include <bit>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <initializer_list>
#include <limits>
#include <string>
#include <utility>
#include <vector>

#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "naming_registry.hpp"
#include "simulation.hpp"

namespace {

int g_failures = 0;

void Check(bool ok, const std::string& label) {
  std::printf("  %s %s\n", ok ? "ok  " : "FAIL", label.c_str());
  if (!ok) {
    g_failures += 1;
  }
}

void CheckClose(double actual, double expected, double tolerance, const std::string& label) {
  const bool ok = std::fabs(actual - expected) <= tolerance;
  std::printf("  %s %s (got %.6g, want %.6g +/- %.3g)\n", ok ? "ok  " : "FAIL", label.c_str(),
              actual, expected, tolerance);
  if (!ok) {
    g_failures += 1;
  }
}

const std::string kBarOp = "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa";
const std::string kPlateOp = "bbbbbbbb-2222-4b22-8b22-bbbbbbbbbbbb";

nlohmann::json BoxOperation(const std::string& id, const double width, const double depth,
                            const double height, const std::array<double, 3>& origin) {
  return {
      {"id", id},
      {"type", "create_box"},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000b"},
      {"parameters",
       {{"width", width},
        {"depth", depth},
        {"height", height},
        {"placement",
         {{"origin", {origin[0], origin[1], origin[2]}},
          {"zDirection", {0.0, 0.0, 1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
  };
}

/// The 100x10x10 mm bar every analytic case runs on.
nlohmann::json BarProgram() {
  return nlohmann::json::array({BoxOperation(kBarOp, 100, 10, 10, {0, 0, 0})});
}

// --- Selector AST builders (the same wire form the selector tests use) ------

nlohmann::json AsArray(std::initializer_list<nlohmann::json> items) {
  nlohmann::json array = nlohmann::json::array();
  for (const nlohmann::json& item : items)
    array.push_back(item);
  return array;
}

nlohmann::json ArgAxis(const std::string& value) { return {{"arg", "axis"}, {"value", value}}; }
nlohmann::json Filter(const std::string& name, std::initializer_list<nlohmann::json> args = {}) {
  return {{"name", name}, {"args", AsArray(args)}};
}
nlohmann::json SrcOp(const std::string& id) { return {{"source", "op"}, {"opId", id}}; }
nlohmann::json Query(const std::string& kind, std::initializer_list<nlohmann::json> scope,
                     std::initializer_list<nlohmann::json> filters = {}) {
  return {{"kind", kind}, {"scope", AsArray(scope)}, {"filters", AsArray(filters)}};
}

/// faces(op(id)).min(x) / .max(x) — the planar end faces of the bar, selected
/// the same way a document ref slot would select them.
nlohmann::json MinXFace(const std::string& opId) {
  return Query("faces", {SrcOp(opId)}, {Filter("min", {ArgAxis("x")})});
}
nlohmann::json MaxXFace(const std::string& opId) {
  return Query("faces", {SrcOp(opId)}, {Filter("max", {ArgAxis("x")})});
}

aeth::SimulationMaterial Aluminum() {
  // E is set to 200 GPa (steel-like) so the classic delta = FL/EA numbers
  // stay round; conductivity 167 W/mK is the heat case's aluminum value.
  aeth::SimulationMaterial material;
  material.youngsModulusGPa = 200.0;
  material.poissonsRatio = 0.3;
  material.yieldStrengthMPa = 250.0;
  material.thermalConductivityWPerMK = 167.0;
  return material;
}

aeth::SimulationStudy StaticBarStudy(double resolutionMm, const std::array<double, 3>& forceN) {
  aeth::SimulationStudy study;
  study.kind = "static-stress";
  study.resolutionMm = resolutionMm;
  study.material = Aluminum();
  aeth::SimulationConstraint fix;
  fix.id = "fix-root";
  fix.ast = MinXFace(kBarOp);
  fix.kind = "fixed";
  study.constraints.push_back(std::move(fix));
  aeth::SimulationLoad load;
  load.id = "end-load";
  load.ast = MaxXFace(kBarOp);
  load.kind = "force";
  load.vectorN = forceN;
  study.loads.push_back(std::move(load));
  return study;
}

struct TimedResult final {
  aeth::SimulationResult result;
  double solveMs{};
};

TimedResult Run(const nlohmann::json& program, const aeth::SimulationStudy& study) {
  aeth::NamingRegistry registry;
  std::atomic_bool cancelled{false};
  const std::vector<aeth::EvaluatedBody> bodies =
      aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
  const auto start = std::chrono::steady_clock::now();
  aeth::SimulationResult result = aeth::SimulateStudy(bodies, registry, study, cancelled);
  const auto stop = std::chrono::steady_clock::now();
  return {std::move(result), std::chrono::duration<double, std::milli>(stop - start).count()};
}

/// Runs a study expected to refuse; returns (details.simulationCode, message)
/// or ("", "") when it unexpectedly succeeded.
std::pair<std::string, std::string> RunExpectingRefusal(const nlohmann::json& program,
                                                        const aeth::SimulationStudy& study) {
  try {
    Run(program, study);
  } catch (const aeth::OperationFailure& error) {
    return {error.Details().value("simulationCode", std::string()), error.what()};
  }
  return {"", ""};
}

/// The requested statistic over skin-vertex scalars whose x lies in
/// [low, high]. Median for stress (voxel corners sing; the median ignores
/// them), mean for temperature (the two node planes straddling mid-span are
/// symmetric about it, so their MEAN is the exact discrete midpoint).
double ScalarOverBand(const aeth::SimulationResult& result, double low, double high, bool median) {
  std::vector<double> values;
  for (std::size_t vertex = 0; vertex * 3 < result.mesh.positions.size(); ++vertex) {
    const double x = result.mesh.positions[vertex * 3];
    if (x >= low && x <= high) {
      values.push_back(result.mesh.scalars[vertex]);
    }
  }
  if (values.empty()) {
    return std::numeric_limits<double>::quiet_NaN();
  }
  if (median) {
    std::sort(values.begin(), values.end());
    return values[values.size() / 2];
  }
  double sum = 0.0;
  for (const double value : values)
    sum += value;
  return sum / static_cast<double>(values.size());
}

bool MeshStructurallySound(const aeth::SimulationResult& result) {
  if (result.mesh.positions.size() % 3 != 0 || result.mesh.triangles.size() % 3 != 0) {
    return false;
  }
  const std::size_t vertexCount = result.mesh.positions.size() / 3;
  if (result.mesh.scalars.size() != vertexCount) {
    return false;
  }
  for (const std::uint32_t index : result.mesh.triangles) {
    if (index >= vertexCount) {
      return false;
    }
  }
  return true;
}

// --- Tests -----------------------------------------------------------------

void UniaxialBar() {
  std::printf("1. uniaxial bar at 5 mm reproduces sigma = F/A and delta = FL/EA:\n");
  const TimedResult timed = Run(BarProgram(), StaticBarStudy(5.0, {1000.0, 0.0, 0.0}));
  const aeth::SimulationResult& bar = timed.result;

  // Grid arithmetic in the file header: exactly 20x2x2 elements, 189 nodes.
  Check(bar.elementCount == 80, "element count is 20*2*2 = 80 (header arithmetic)");
  Check(bar.nodeCount == 189, "node count is 21*3*3 = 189");
  Check(bar.scalarName == "vonMisesMPa", "static-stress scalar is vonMisesMPa");
  Check(bar.iterations > 0, "the CG solver genuinely iterated");
  Check(MeshStructurallySound(bar),
        "skin mesh is flat xyz triples, index triples, one scalar per vertex");

  // sigma = F/A = 1000 N / (10*10 mm^2) = 10 MPa exactly. A uniform uniaxial
  // stress state is inside the trilinear element space, so mid-span elements
  // reproduce it and only the one-element boundary layers at the clamped and
  // loaded ends deviate (Saint-Venant). Sampling the MEDIAN over skin
  // vertices with |x| <= 10.1 (node planes +/-2.5, +/-7.5 — 4+ cross-sections
  // from either end) ignores the singing corners; 15% tolerance = 1.5 MPa.
  const double vonMisesMid = ScalarOverBand(bar, -10.1, 10.1, true);
  CheckClose(vonMisesMid, 10.0, 1.5, "mid-span median von Mises vs sigma = F/A = 10 MPa");

  // delta = FL/(EA) = 1000 N * 100 mm / (200000 MPa * 100 mm^2)
  //       = 1e5 / 2e7 = 0.005 mm exactly. Two documented simplifications
  // pull the reported max in opposite directions: the clamp also reaches the
  // skin ring one plane in (shortens the stretched length — stiffer), while
  // the EQUAL-split end load gives face corners 1.78x their consistent
  // tributary share (1/9 vs 1/16), and displacementMaxMm is a max over
  // nodes, so it reads the corner's local bulge (softer). The net lands a
  // few percent HIGH, inside the 10% band.
  CheckClose(bar.displacementMaxMm, 0.005, 0.0005,
             "displacementMaxMm vs delta = FL/EA = 0.005 mm (10%)");

  std::printf("  -- solve time: %.2f ms (80 elements)\n", timed.solveMs);
  Check(timed.solveMs < 2000.0, "the 80-element bar solves in milliseconds, not seconds");
}

void BarScalesWithResolution() {
  std::printf("2. the same bar at 2.5 mm (640 elements) proves the CG scales:\n");
  const TimedResult timed = Run(BarProgram(), StaticBarStudy(2.5, {1000.0, 0.0, 0.0}));
  const aeth::SimulationResult& bar = timed.result;

  // Same arithmetic at h = 2.5: ceil(100/2.5)+1 = 41 cells (origin -51.25),
  // samples -50 + 2.5i + 2.5e-4 fill i = 0..39; cross sections fill 4 of 5
  // cells: 40*4*4 = 640 elements, 41*5*5 = 1025 nodes.
  Check(bar.elementCount == 640, "element count is 40*4*4 = 640");
  Check(bar.nodeCount == 1025, "node count is 41*5*5 = 1025");
  Check(bar.iterations > 0, "the CG solver genuinely iterated");

  // Physics does not move with the mesh: same 10 MPa and 0.005 mm targets.
  // The clamp ring now sits 2.5 mm in (half the geometric shortening), and
  // the equal-split corner overload concentrates a little harder on the
  // finer face grid — the max still lands inside the same 10% band.
  const double vonMisesMid = ScalarOverBand(bar, -5.1, 5.1, true);
  CheckClose(vonMisesMid, 10.0, 1.5, "mid-span median von Mises still 10 MPa");
  CheckClose(bar.displacementMaxMm, 0.005, 0.0005, "displacementMaxMm still 0.005 mm (10%)");

  std::printf("  -- solve time: %.2f ms (640 elements, %zu CG iterations)\n", timed.solveMs,
              bar.iterations);
  Check(timed.solveMs < 10000.0, "the 640-element bar stays interactive");
}

void Cantilever() {
  std::printf("3. cantilever tip deflection tracks FL^3/3EI:\n");
  const TimedResult timed = Run(BarProgram(), StaticBarStudy(5.0, {0.0, 0.0, -100.0}));
  const aeth::SimulationResult& beam = timed.result;

  // I = b*h^3/12 = 10 * 10^3 / 12 = 833.33 mm^4 (10 mm wide, 10 mm deep).
  // delta = FL^3/(3EI) = 100 * 100^3 / (3 * 200000 * 833.33)
  //       = 1e8 / 5e8 = 0.2 mm. Voxel FEM at 5 mm is STIFF here: fully
  // integrated trilinear hexes carry parasitic shear in bending and only two
  // elements span the depth, and the clamp ring shortens the effective span
  // to ~95 mm ((95/100)^3 = 0.857) — so the computed tip runs meaningfully
  // under 0.2. The 25% band is exactly the honest statement of that
  // stiffness; a value outside it would mean the assembly is wrong, not just
  // coarse.
  CheckClose(beam.displacementMaxMm, 0.2, 0.05,
             "tip |u| vs delta = FL^3/3EI = 0.2 mm (25%: voxel FEM is stiff)");
  Check(beam.scalarName == "vonMisesMPa", "cantilever scalar is vonMisesMPa");
  Check(beam.iterations > 0, "the CG solver genuinely iterated");
  std::printf("  -- solve time: %.2f ms\n", timed.solveMs);
}

void SteadyHeatBar() {
  std::printf("4. steady conduction between 100C and 0C ends is linear:\n");
  aeth::SimulationStudy study;
  study.kind = "steady-heat";
  study.resolutionMm = 5.0;
  study.material = Aluminum(); // k = 167 W/mK
  aeth::SimulationConstraint hot;
  hot.id = "hot-end";
  hot.ast = MinXFace(kBarOp);
  hot.kind = "temperature";
  hot.valueC = 100.0;
  aeth::SimulationConstraint cold;
  cold.id = "cold-end";
  cold.ast = MaxXFace(kBarOp);
  cold.kind = "temperature";
  cold.valueC = 0.0;
  study.constraints.push_back(std::move(hot));
  study.constraints.push_back(std::move(cold));

  const TimedResult timed = Run(BarProgram(), study);
  const aeth::SimulationResult& heat = timed.result;
  Check(heat.scalarName == "temperatureC", "steady-heat scalar is temperatureC");
  Check(heat.iterations > 0, "the CG solver genuinely iterated");
  Check(MeshStructurallySound(heat), "heat skin mesh is structurally sound");

  // With Dirichlet ends and no flux, the continuum solution is linear in x —
  // and on a uniform grid the discrete conduction operator reproduces a
  // linear field EXACTLY (its stencil is consistent to machine precision on
  // affine fields), so the only deviations are the CG residual (1e-8) and
  // the clamp's one-plane reach: the hot face pins cap plane -52.5 plus the
  // -47.5 skin ring, the cold face pins only cap plane 47.5, making the far
  // field linear between ~-47.5 (100C) and 47.5 (0C). The two node planes at
  // x = -2.5 and +2.5 straddle mid-span symmetrically, so their MEAN is the
  // discrete mid temperature: 100 * 47.5/95 = 50.0C, within 2% (1C).
  const double midMean = ScalarOverBand(heat, -2.6, 2.6, false);
  CheckClose(midMean, 50.0, 1.0, "mid-span mean temperature vs the exact 50C");

  // The discrete field stays inside the prescribed range (no source terms).
  Check(heat.scalarMax <= 100.0 + 0.5 && heat.scalarMin >= -0.5,
        "temperatures stay within the prescribed 0..100C envelope");
  std::printf("  -- solve time: %.2f ms\n", timed.solveMs);
}

void TypedRefusals() {
  std::printf("5. refusals are typed, named, and raised before assembly:\n");

  // SIM_BC_UNRESOLVED: cylindrical() over a box resolves ZERO faces; the
  // refusal names the failing constraint id.
  aeth::SimulationStudy bore = StaticBarStudy(5.0, {1000.0, 0.0, 0.0});
  bore.constraints[0].id = "clamp-bore";
  bore.constraints[0].ast = Query("faces", {SrcOp(kBarOp)}, {Filter("cylindrical")});
  const std::pair<std::string, std::string> unresolved = RunExpectingRefusal(BarProgram(), bore);
  Check(unresolved.first == "SIM_BC_UNRESOLVED", "zero-face constraint is SIM_BC_UNRESOLVED");
  Check(unresolved.second.find("clamp-bore") != std::string::npos,
        "the refusal names the failing constraint id");

  // SIM_UNCONSTRAINED: the constraint RESOLVES (one real face) but clamps no
  // node. Construction: a second, disjoint 0.5 mm plate at placement origin
  // x=82 spans x in [81.75, 82.25]. The union grid at h=5 covers
  // x[-50, 82.25] with ceil(132.25/5)+1 = 28 cells from origin -53.875, so
  // occupancy samples sit at x = -51.375 + 5i + 5e-4: i=26 gives 78.625,
  // i=27 gives 83.625 — neither inside the plate, so the plate voxelizes to
  // NOTHING (an honest too-thin-for-this-resolution outcome), while the bar
  // still fills i = 1..20. The plate's max-x face at 82.25 (bbox inflated by
  // one voxel: x in [77.25, 87.25]) is beyond every bar skin node (max
  // 51.125), so the fixed constraint clamps zero nodes and the study refuses
  // as unconstrained before assembly.
  nlohmann::json disjoint = BarProgram();
  nlohmann::json plate = BoxOperation(kPlateOp, 0.5, 10, 10, {82.0, 0.0, 0.0});
  plate["outputBodyId"] = "00000000-0000-4000-8000-00000000000c";
  disjoint.push_back(plate);
  aeth::SimulationStudy unclamped = StaticBarStudy(5.0, {1000.0, 0.0, 0.0});
  unclamped.constraints[0].id = "fix-plate";
  unclamped.constraints[0].ast = MaxXFace(kPlateOp);
  const std::pair<std::string, std::string> unconstrained =
      RunExpectingRefusal(disjoint, unclamped);
  Check(unconstrained.first == "SIM_UNCONSTRAINED",
        "a constraint that clamps zero nodes leaves the study SIM_UNCONSTRAINED");

  // SIM_RESOLUTION: at 0.1 mm the bar needs 1000*100*100 = 10,000,000
  // elements; counting stops the moment it passes the cap, so the refusal
  // arrives fast and names 150000.
  const std::pair<std::string, std::string> tooFine =
      RunExpectingRefusal(BarProgram(), StaticBarStudy(0.1, {1000.0, 0.0, 0.0}));
  Check(tooFine.first == "SIM_RESOLUTION", "0.1 mm on the bar is SIM_RESOLUTION");
  Check(tooFine.second.find("150000") != std::string::npos, "the refusal names the 150000 cap");
}

void Determinism() {
  std::printf("6. two runs of the same study are byte-identical:\n");
  const aeth::SimulationResult first =
      Run(BarProgram(), StaticBarStudy(5.0, {1000.0, 0.0, 0.0})).result;
  const aeth::SimulationResult second =
      Run(BarProgram(), StaticBarStudy(5.0, {1000.0, 0.0, 0.0})).result;

  const auto bitIdentical = [](const std::vector<double>& a, const std::vector<double>& b) {
    if (a.size() != b.size()) {
      return false;
    }
    for (std::size_t index = 0; index < a.size(); ++index) {
      if (std::bit_cast<std::uint64_t>(a[index]) != std::bit_cast<std::uint64_t>(b[index])) {
        return false;
      }
    }
    return true;
  };
  Check(bitIdentical(first.mesh.scalars, second.mesh.scalars), "scalars are byte-identical");
  Check(bitIdentical(first.mesh.positions, second.mesh.positions), "positions are byte-identical");
  Check(first.mesh.triangles == second.mesh.triangles, "triangulation is identical");
  Check(std::bit_cast<std::uint64_t>(first.displacementMaxMm) ==
            std::bit_cast<std::uint64_t>(second.displacementMaxMm),
        "displacementMaxMm is byte-identical");
  Check(first.iterations == second.iterations, "iteration counts agree");
}

} // namespace

int main() {
  std::printf("voxel FEM simulation seam (strengths / heat maps domain)\n");
  try {
    UniaxialBar();
    BarScalesWithResolution();
    Cantilever();
    SteadyHeatBar();
    TypedRefusals();
    Determinism();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures != 0) {
    std::printf("%d SIMULATION CHECK(S) FAILED\n", g_failures);
    return 1;
  }
  std::printf("ALL SIMULATION TESTS PASSED\n");
  return 0;
}
