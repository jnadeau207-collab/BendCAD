// Per-operation tolerance budgets (GOV-003 §2, law under ADR-015 rule 2).
//
// The doctrine's rule is: every operation states its input tolerance envelope
// and its output tolerance guarantee, asserted in a gate rather than assumed.
// This is that gate. Every number below was MEASURED against the pinned OCCT
// before it was written down (docs/design/2026-07-27-kernel-robustness-
// doctrine.md §2 records the measurement run), and three of the measurements
// contradicted the doctrine's own draft phrasing:
//
//   1. Tolerance is ABSOLUTE, not scale-relative. A 0.05 mm box and a 5000 mm
//      box both carry exactly Precision::Confusion(). A ratio-to-size budget
//      would therefore be meaningless — the unit is millimetres, full stop.
//   2. Tolerance is PARAMETER-INDEPENDENT. chamfer at d=2 and d=0.01 both give
//      1e-4; fillet at r=0.01 and r=9.9 both give 1e-7; shell at t=2 and
//      t=0.05 both give 1e-6. That is what makes a budget declarable at all:
//      it is a per-operation CONSTANT, not a function of the arguments.
//   3. The inflated entity KIND MOVES. Single operations leave faces pinned at
//      1e-7 and inflate only vertices. But a fillet run on chamfered input
//      lands 1.063e-4 on FACES. A per-kind budget would have passed that chain
//      while the growth happened in a kind nobody was watching, so the budget
//      is stated over MAX-OF-ALL-KINDS.
//
// Why native and not on the wire: `shapeProbesSchema` is `.strict()`, so
// publishing tolerance would be a PROTOCOL §4 seam change, and no renderer
// surface consumes it. Tolerance is a kernel property and this is where it is
// both cheapest and exact.
#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <string>
#include <vector>

#include <BRep_Tool.hxx>
#include <Precision.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"

namespace {

int g_failures = 0;

void check(const bool condition, const std::string& label) {
  if (condition) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s\n", label.c_str());
    g_failures += 1;
  }
}

/// The doctrine's measurable quantity: the largest tolerance carried by ANY
/// entity of the result, across all three kinds. Finding 3 above is why this
/// does not report per-kind.
double MaxTolerance(const TopoDS_Shape& shape) {
  double worst = 0.0;
  for (TopExp_Explorer it(shape, TopAbs_FACE); it.More(); it.Next())
    worst = std::max(worst, BRep_Tool::Tolerance(TopoDS::Face(it.Current())));
  for (TopExp_Explorer it(shape, TopAbs_EDGE); it.More(); it.Next())
    worst = std::max(worst, BRep_Tool::Tolerance(TopoDS::Edge(it.Current())));
  for (TopExp_Explorer it(shape, TopAbs_VERTEX); it.More(); it.Next())
    worst = std::max(worst, BRep_Tool::Tolerance(TopoDS::Vertex(it.Current())));
  return worst;
}

// ---------------------------------------------------------------------------
// The budget table. `budgetMm` is the operation's declared OUTPUT GUARANTEE
// given inputs within the envelope; `measuredMm` is what the pinned OCCT
// actually produced. The gate asserts BOTH: within budget (the contract) and
// still at the measured constant (drift detection, which is what ADR-015 rule
// 5's upgrade protocol reads).
// ---------------------------------------------------------------------------

/// Plan 01-geometry-core/03's kernel linear tolerance. The input envelope for
/// every operation below: inputs are accepted at or under this band.
constexpr double kKernelLinearToleranceMm = 1e-4;

/// A budget is a decimal bound; the thing compared against it is the output of
/// floating-point kernel arithmetic. Two excesses were MEASURED at the bound,
/// four orders apart in kind:
///
///   - fillet returns 1.00000000000000022e-07 where a box returns
///     9.99999999999999955e-08 — two ULP at that exponent, pure representation
///     noise;
///   - shell at t=0.05 returns 1.00000000397206059e-06, a relative excess of
///     4e-9 over the bound. Not noise: a genuinely computed value, and ~4
///     femtometres in physical terms.
///
/// Neither is a tolerance regression, and neither may be papered over by moving
/// a budget up a tier. The slack is applied to the COMPARISON instead, stated
/// once, and `SlackCannotMaskATierCrossing` below proves it is orders below the
/// gap between adjacent budget tiers — so it can never hide a real change.
constexpr double kBudgetSlackRelative = 1e-6;

struct Budget final {
  const char* label;
  double budgetMm;
  double measuredMm;
};

const char* kBoxOp = "00000000-0000-4000-8000-000000000001";
const char* kMidOp = "00000000-0000-4000-8000-000000000004";
const char* kToolOp = "00000000-0000-4000-8000-000000000005";
const char* kOutOp = "00000000-0000-4000-8000-000000000002";

nlohmann::json Box(const char* id, const double w, const double d, const double h,
                   const double z = 0.0) {
  return {{"id", id},
          {"type", "create_box"},
          {"outputBodyId", "00000000-0000-4000-8000-0000000000a1"},
          {"parameters",
           {{"width", w},
            {"depth", d},
            {"height", h},
            {"placement",
             {{"origin", {0.0, 0.0, z}},
              {"zDirection", {0.0, 0.0, 1.0}},
              {"xDirection", {1.0, 0.0, 0.0}}}}}}};
}

nlohmann::json Modifier(const char* id, const char* type, const char* target,
                        const nlohmann::json& parameters) {
  nlohmann::json params = parameters;
  params["targetOperationId"] = target;
  return {{"id", id},
          {"type", type},
          {"outputBodyId", "00000000-0000-4000-8000-0000000000a2"},
          {"parameters", params}};
}

double EvaluateMaxTolerance(const nlohmann::json& program) {
  std::atomic_bool cancelled{false};
  const std::vector<aeth::EvaluatedBody> bodies = aeth::EvaluateOperations(program, cancelled);
  if (bodies.empty())
    throw std::runtime_error("program produced no bodies");
  return MaxTolerance(bodies.back().shape);
}

void Assert(const Budget& budget, const nlohmann::json& program) {
  const double actual = EvaluateMaxTolerance(program);
  std::printf("  %-26s budget=%.3e measured=%.3e actual=%.6e\n", budget.label, budget.budgetMm,
              budget.measuredMm, actual);
  check(actual <= budget.budgetMm * (1.0 + kBudgetSlackRelative),
        std::string(budget.label) + ": within its declared budget");
  // Drift detection: an OCCT bump or a code change that moves the constant is a
  // recorded decision (ADR-015 rule 5), never a silent slide.
  check(std::abs(actual - budget.measuredMm) <= budget.measuredMm * 1e-6,
        std::string(budget.label) + ": still at the pinned measured constant");
}

/// Rule 2's core claim, in one place: no SINGLE operation may hand back
/// geometry looser than the kernel linear tolerance it accepts. If this ever
/// fails the answer is to refuse the operation, never to widen the band.
void SingleOperationBudgets() {
  std::printf("single-operation output budgets (GOV-003 §2):\n");
  const nlohmann::json box = Box(kBoxOp, 40, 30, 20);

  Assert({"create_box", Precision::Confusion(), 1e-7}, nlohmann::json::array({box}));
  // Scale-invariance, finding 1: the same absolute number at both extremes.
  Assert({"create_box 0.05mm", Precision::Confusion(), 1e-7},
         nlohmann::json::array({Box(kBoxOp, 40, 30, 0.05)}));
  Assert({"create_box 5000mm", Precision::Confusion(), 1e-7},
         nlohmann::json::array({Box(kBoxOp, 5000, 3000, 2000)}));

  Assert(
      {"transform", Precision::Confusion(), 1e-7},
      nlohmann::json::array(
          {box, Modifier(kOutOp, "transform", kBoxOp,
                         {{"transform", {{"kind", "translate"}, {"offset", {5.0, 7.0, 9.0}}}}})}));

  // Finding 2, parameter-independence, asserted at both ends of each envelope.
  Assert({"fillet r=3", Precision::Confusion(), 1e-7},
         nlohmann::json::array({box, Modifier(kOutOp, "fillet", kBoxOp, {{"radius", 3.0}})}));
  Assert({"fillet r=0.01", Precision::Confusion(), 1e-7},
         nlohmann::json::array({box, Modifier(kOutOp, "fillet", kBoxOp, {{"radius", 0.01}})}));
  Assert({"fillet r=9.9", Precision::Confusion(), 1e-7},
         nlohmann::json::array({box, Modifier(kOutOp, "fillet", kBoxOp, {{"radius", 9.9}})}));

  // Chamfer is the catalog's loosest single operation: it lands exactly ON the
  // kernel linear tolerance, 1000x Confusion, and does so regardless of the
  // distance asked for. Budgeted at the band, not above it.
  Assert({"chamfer d=2", kKernelLinearToleranceMm, 1e-4},
         nlohmann::json::array({box, Modifier(kOutOp, "chamfer", kBoxOp, {{"distance", 2.0}})}));
  Assert({"chamfer d=0.01", kKernelLinearToleranceMm, 1e-4},
         nlohmann::json::array({box, Modifier(kOutOp, "chamfer", kBoxOp, {{"distance", 0.01}})}));

  Assert({"shell t=2", 1e-6, 1e-6},
         nlohmann::json::array({box, Modifier(kOutOp, "shell", kBoxOp, {{"thickness", 2.0}})}));
  Assert({"shell t=0.05", 1e-6, 1e-6},
         nlohmann::json::array({box, Modifier(kOutOp, "shell", kBoxOp, {{"thickness", 0.05}})}));

  // Booleans are the doctrine's named weak corner. Measured, a clean cut costs
  // half a Confusion unit on edges and vertices and nothing on faces.
  const nlohmann::json target = Box(kBoxOp, 80, 50, 15);
  const auto cut = [](const char* toolId) {
    return nlohmann::json{
        {"id", kOutOp},
        {"type", "boolean_combine"},
        {"outputBodyId", "00000000-0000-4000-8000-0000000000a3"},
        {"parameters",
         {{"kind", "cut"}, {"targetOperationId", kBoxOp}, {"toolOperationId", toolId}}}};
  };
  Assert({"boolean cut", 1.5e-7, 1.5e-7},
         nlohmann::json::array({target, Box(kToolOp, 10, 70, 10), cut(kToolOp)}));
  // A tool face landing 1e-5 mm short of the target face — three orders inside
  // the linear band. It does NOT inflate: the sliver case costs the same as the
  // clean one. Recorded because the intuition says otherwise.
  Assert({"boolean cut 1e-5 sliver", 1.5e-7, 1.5e-7},
         nlohmann::json::array({target, Box(kToolOp, 10, 70, 10, 15.0 - 1e-5), cut(kToolOp)}));
}

/// Finding 3, and the reason this gate exists at all: budgets do NOT compose by
/// max(). A fillet whose own budget is one Confusion unit, run on chamfered
/// input, hands back 1.063e-4 — MORE than either operation's budget and more
/// than the kernel linear tolerance itself. Two in-budget operations compose to
/// an out-of-budget result, and the growth lands on FACES, a kind that neither
/// operation touched on its own.
void CompositionAmplifies() {
  std::printf("composition amplification (GOV-003 §2, the stacking claim):\n");
  const nlohmann::json chamfer = Modifier(kMidOp, "chamfer", kBoxOp, {{"distance", 2.0}});
  const nlohmann::json program = nlohmann::json::array(
      {Box(kBoxOp, 40, 30, 20), chamfer, Modifier(kOutOp, "fillet", kMidOp, {{"radius", 1.0}})});

  const double chained = EvaluateMaxTolerance(program);
  std::printf("  chamfer>fillet chained max tolerance = %.4e mm (%.1fx Confusion)\n", chained,
              chained / Precision::Confusion());
  check(chained > kKernelLinearToleranceMm,
        "the chain EXCEEDS the kernel linear tolerance both inputs respect");
  check(std::abs(chained - 1.0633e-4) <= 1.0e-7,
        "chained amplification pinned at the measured 1.063e-4 mm");
  // The declared composition rule, asserted rather than asserted-to-be-absent:
  // a chain's guarantee is its worst input budget times this factor, not the
  // max of its members' budgets.
  const double amplification = chained / kKernelLinearToleranceMm;
  check(amplification > 1.0 && amplification < 1.10,
        "amplification over the loosest member stays under 10% (measured ~6.3%)");
}

/// The envelope half of rule 2. Every budget above is stated for inputs at or
/// under the kernel linear tolerance, so that constant must be what the plan
/// says it is; a silent change to it would invalidate the whole table.
void EnvelopeIsPinned() {
  std::printf("input envelope:\n");
  check(std::abs(Precision::Confusion() - 1e-7) <= 1e-12,
        "Precision::Confusion() is 1e-7 mm on the pinned OCCT");
  check(kKernelLinearToleranceMm == 1e-4, "the kernel linear tolerance band is 1e-4 mm (plan 01)");
  check(kKernelLinearToleranceMm > Precision::Confusion(),
        "the accepted input band is looser than the primitive floor");
}

/// What makes the comparison slack safe rather than a fudge. The budget tiers
/// in use are 1e-7, 1.5e-7, 1e-6 and 1e-4 mm; the tightest ratio between
/// adjacent tiers is 1.5x. A part-per-million slack is five orders below that,
/// so no amount of slack-absorbed noise can carry a measurement from one tier
/// into the next — which is the only way it could hide a real regression.
void SlackCannotMaskATierCrossing() {
  std::printf("comparison slack is bounded:\n");
  const double tightestTierRatio = 1.5; // 1.0e-7 -> 1.5e-7, the closest pair
  check(kBudgetSlackRelative < (tightestTierRatio - 1.0) / 1000.0,
        "the slack is >1000x smaller than the closest gap between budget tiers");
  // And in absolute terms at the tightest band it is a femtometre-scale number,
  // far below any tolerance that could affect a downstream boolean.
  check(Precision::Confusion() * kBudgetSlackRelative < 1e-12,
        "at the tightest band the slack is under 1e-12 mm absolute");
}

} // namespace

int main() {
  try {
    EnvelopeIsPinned();
    SlackCannotMaskATierCrossing();
    SingleOperationBudgets();
    CompositionAmplifies();
  } catch (const std::exception& error) {
    std::printf("  FAIL threw: %s\n", error.what());
    g_failures += 1;
  }
  if (g_failures == 0) {
    std::printf("tolerance-budget gate: all checks passed\n");
    return 0;
  }
  std::printf("tolerance-budget gate: %d FAILED\n", g_failures);
  return 1;
}
