// CAP-036 — the sketch-solver seam gate.
//
// The exit criterion names four properties and this file asserts each of them
// against the REAL vendored solver: a correct solve, a bit-identical re-solve,
// an under-constrained system reporting its free degrees of freedom, and an
// over-constrained system diagnosed with the conflicting constraints NAMED.
//
// It also tests `shim/boost_graph_adjacency_list.hpp` directly. That file is
// OURS, not upstream, and it is not a stub: GCS.cpp:1783-1801 calls
// connected_components inside diagnose(), so a wrong union-find would corrupt
// the DoF/redundancy analysis this capability exists to deliver — silently,
// because the numbers would still look plausible.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <string>
#include <utility>
#include <vector>

#include "sketch_solver.hpp"

#include <boost_graph_adjacency_list.hpp>

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
  std::printf("  %s %s (got %.17g, want %.17g)\n", ok ? "ok  " : "FAIL", label.c_str(), actual,
              expected);
  if (!ok) {
    g_failures += 1;
  }
}

using aeth::SketchSolverAnchorPosition;
using aeth::SketchSolverConstraint;
using aeth::SketchSolverConstraintKind;
using aeth::SketchSolverEntity;
using aeth::SketchSolverEntityKind;
using aeth::SketchSolverStatus;
using aeth::SketchSolverSystem;

/// A horizontal line from the origin, with its left end pinned. Grounding is
/// what stops a least-squares solve translating the whole sketch.
SketchSolverSystem GroundedLine(double length) {
  SketchSolverSystem system;
  SketchSolverEntity anchor;
  anchor.eid = "ent_anchor";
  anchor.kind = SketchSolverEntityKind::Point;
  anchor.values = {0.0, 0.0};
  system.entities.push_back(anchor);

  SketchSolverEntity line;
  line.eid = "ent_line";
  line.kind = SketchSolverEntityKind::Line;
  // Deliberately NOT the answer: 7,3 -> 7,3 would prove nothing.
  line.values = {0.0, 0.0, 7.0, 3.0};
  system.entities.push_back(line);

  system.grounded.push_back({"ent_anchor"});

  SketchSolverConstraint pin;
  pin.cid = "cst_pin";
  pin.kind = SketchSolverConstraintKind::Coincident;
  pin.anchors = {{"ent_anchor", SketchSolverAnchorPosition::Point},
                 {"ent_line", SketchSolverAnchorPosition::Start}};
  system.constraints.push_back(pin);

  SketchSolverConstraint horizontal;
  horizontal.cid = "cst_horizontal";
  horizontal.kind = SketchSolverConstraintKind::Horizontal;
  horizontal.anchors = {{"ent_line", SketchSolverAnchorPosition::Start},
                        {"ent_line", SketchSolverAnchorPosition::End}};
  system.constraints.push_back(horizontal);

  SketchSolverConstraint distance;
  distance.cid = "cst_length";
  distance.kind = SketchSolverConstraintKind::Distance;
  distance.anchors = {{"ent_line", SketchSolverAnchorPosition::Start},
                      {"ent_line", SketchSolverAnchorPosition::End}};
  distance.value = length;
  system.constraints.push_back(distance);

  return system;
}

void CorrectSolve() {
  std::printf("1. a constrained sketch solves to the DIMENSION, not near it:\n");
  const aeth::SketchSolverResult result = aeth::SolveSketch(GroundedLine(20.0));
  Check(result.status == SketchSolverStatus::Converged, "status is Converged");
  if (result.entities.size() != 2) {
    Check(false, "the solved entities come back");
    return;
  }
  const std::vector<double>& line = result.entities[1].values;
  // The analytic answer is exact: pinned at the origin, horizontal, length 20.
  CheckClose(line[0], 0.0, 1e-9, "the pinned end stayed at the origin (x)");
  CheckClose(line[1], 0.0, 1e-9, "the pinned end stayed at the origin (y)");
  CheckClose(line[3], 0.0, 1e-9, "the free end is level with it (horizontal)");
  CheckClose(std::fabs(line[2] - line[0]), 20.0, 1e-9, "the length dimension is honoured");
  Check(result.degreesOfFreedom == 0, "a fully-dimensioned sketch reports 0 DoF");
}

void Deterministic() {
  std::printf("2. determinism — the same system solved twice is BIT-identical:\n");
  std::vector<double> first;
  bool identical = true;
  bool sameStatus = true;
  SketchSolverStatus firstStatus = SketchSolverStatus::Invalid;
  for (int run = 0; run < 8; ++run) {
    const aeth::SketchSolverResult result = aeth::SolveSketch(GroundedLine(17.3));
    std::vector<double> values;
    for (const SketchSolverEntity& entity : result.entities) {
      values.insert(values.end(), entity.values.begin(), entity.values.end());
    }
    if (run == 0) {
      first = values;
      firstStatus = result.status;
      continue;
    }
    if (result.status != firstStatus) {
      sameStatus = false;
    }
    if (values.size() != first.size()) {
      identical = false;
      continue;
    }
    // std::memcmp, not a tolerance: ADR-016's determinism contract is
    // bit-identical, and a tolerance here would hide exactly the drift the
    // replay assertion must catch.
    if (std::memcmp(values.data(), first.data(), values.size() * sizeof(double)) != 0) {
      identical = false;
    }
  }
  Check(identical, "8 solves produce byte-identical parameter values");
  Check(sameStatus, "8 solves produce the same status");
}

void UnderConstrained() {
  std::printf("3. an UNDER-constrained sketch reports its free degrees of freedom:\n");
  SketchSolverSystem system = GroundedLine(20.0);
  // Drop the length: the free end can now slide along the horizontal.
  system.constraints.pop_back();
  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Converged,
        "under-constrained is a SOLVED state, not a failure");
  Check(result.degreesOfFreedom == 1, "exactly one degree of freedom remains (got " +
                                          std::to_string(result.degreesOfFreedom) + ")");
  Check(result.conflicting.empty(), "it is not misreported as conflicting");
}

void Conflicting() {
  std::printf("4. an OVER-constrained sketch NAMES the conflicting constraints:\n");
  SketchSolverSystem system = GroundedLine(20.0);
  SketchSolverConstraint second;
  second.cid = "cst_other_length";
  second.kind = SketchSolverConstraintKind::Distance;
  second.anchors = {{"ent_line", SketchSolverAnchorPosition::Start},
                    {"ent_line", SketchSolverAnchorPosition::End}};
  second.value = 35.0; // the same edge cannot be 20 and 35
  system.constraints.push_back(second);

  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Conflicting, "the conflict is detected");
  Check(!result.conflicting.empty(), "the conflicting SET is enumerated, not just flagged");
  bool namesOurIds = true;
  for (const std::string& cid : result.conflicting) {
    if (cid.rfind("cst_", 0) != 0) {
      namesOurIds = false;
    }
  }
  Check(namesOurIds, "the names are OUR constraint ids, not solver tag integers");
  Check(result.message.find("cst_") != std::string::npos,
        "the message names them too, in our words");
  std::printf("     message: %s\n", result.message.c_str());
}

void MutuallyExclusiveAxes() {
  std::printf("5. horizontal plus vertical preserves line non-degeneracy and names BOTH:\n");
  SketchSolverSystem system = GroundedLine(20.0);
  SketchSolverConstraint vertical;
  vertical.cid = "cst_vertical";
  vertical.kind = SketchSolverConstraintKind::Vertical;
  vertical.anchors = {{"ent_line", SketchSolverAnchorPosition::Start},
                      {"ent_line", SketchSolverAnchorPosition::End}};
  system.constraints.push_back(vertical);

  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Conflicting,
        "mutually exclusive line axes are conflicting, not a collapsed line");
  Check(result.conflicting.size() == 2, "the exact two axis constraints are named");
  Check(std::find(result.conflicting.begin(), result.conflicting.end(), "cst_horizontal") !=
            result.conflicting.end(),
        "the horizontal constraint is named");
  Check(std::find(result.conflicting.begin(), result.conflicting.end(), "cst_vertical") !=
            result.conflicting.end(),
        "the vertical constraint is named");
}

void GroundedContradiction() {
  std::printf("6. a fully grounded contradiction is checked, never echoed as converged:\n");
  SketchSolverSystem system;
  SketchSolverEntity line;
  line.eid = "ent_fixed_line";
  line.kind = SketchSolverEntityKind::Line;
  line.values = {0.0, 0.0, 10.0, 0.0};
  system.entities.push_back(line);
  system.grounded.push_back({"ent_fixed_line"});

  SketchSolverConstraint wrongLength;
  wrongLength.cid = "cst_fixed_wrong_length";
  wrongLength.kind = SketchSolverConstraintKind::Distance;
  wrongLength.anchors = {{"ent_fixed_line", SketchSolverAnchorPosition::Start},
                         {"ent_fixed_line", SketchSolverAnchorPosition::End}};
  wrongLength.value = 12.0;
  system.constraints.push_back(wrongLength);

  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Conflicting,
        "the fixed but unsatisfied distance is conflicting");
  Check(result.conflicting == std::vector<std::string>{"cst_fixed_wrong_length"},
        "the unsatisfied fixed constraint is named exactly");
}

void SelfEndpointCollapse() {
  std::printf("7. a self-endpoint coincidence cannot collapse a valid line:\n");
  SketchSolverSystem system;
  SketchSolverEntity line;
  line.eid = "ent_line";
  line.kind = SketchSolverEntityKind::Line;
  line.values = {0.0, 0.0, 10.0, 0.0};
  system.entities.push_back(line);

  SketchSolverConstraint collapse;
  collapse.cid = "cst_collapse";
  collapse.kind = SketchSolverConstraintKind::Coincident;
  collapse.anchors = {{"ent_line", SketchSolverAnchorPosition::Start},
                      {"ent_line", SketchSolverAnchorPosition::End}};
  system.constraints.push_back(collapse);

  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Conflicting,
        "collapsing one entity is a named conflict, never a solved sketch");
  Check(result.conflicting == std::vector<std::string>{"cst_collapse"},
        "the self-collapse constraint is named exactly");
  Check(result.entities.empty(), "no degenerate solved entity is returned");
}

void FixedRedundancy() {
  std::printf("8. a fixed system still diagnoses redundant constraints:\n");
  SketchSolverSystem system;
  SketchSolverEntity line;
  line.eid = "ent_fixed_line";
  line.kind = SketchSolverEntityKind::Line;
  line.values = {0.0, 0.0, 10.0, 0.0};
  system.entities.push_back(line);
  system.grounded.push_back({"ent_fixed_line"});

  SketchSolverConstraint first;
  first.cid = "cst_horizontal_first";
  first.kind = SketchSolverConstraintKind::Horizontal;
  first.anchors = {{"ent_fixed_line", SketchSolverAnchorPosition::Start},
                   {"ent_fixed_line", SketchSolverAnchorPosition::End}};
  system.constraints.push_back(first);
  SketchSolverConstraint duplicate = first;
  duplicate.cid = "cst_horizontal_duplicate";
  system.constraints.push_back(duplicate);

  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Redundant,
        "a satisfied duplicate is redundant even with zero unknowns");
  Check(result.redundant == std::vector<std::string>{"cst_horizontal_duplicate"},
        "the later duplicate is named exactly");
  Check(result.entities.size() == 1, "a redundant fixed solve returns its valid geometry");
}

void GroundedArcContour() {
  std::printf("9. a grounded arc closes two orthogonal lines at zero DoF:\n");
  SketchSolverSystem system;
  system.entities.push_back({"ent_arc", SketchSolverEntityKind::Arc, {0.0, 0.0, 20.0, 0.0, 90.0}});
  system.entities.push_back(
      {"ent_horizontal", SketchSolverEntityKind::Line, {5.0, 5.0, 25.0, 5.0}});
  system.entities.push_back(
      {"ent_vertical", SketchSolverEntityKind::Line, {10.0, 10.0, 30.0, 10.0}});
  system.grounded.push_back({"ent_arc"});

  auto addAxis = [&](const std::string& cid, SketchSolverConstraintKind kind,
                     const std::string& eid) {
    SketchSolverConstraint constraint;
    constraint.cid = cid;
    constraint.kind = kind;
    constraint.anchors = {{eid, SketchSolverAnchorPosition::Start},
                          {eid, SketchSolverAnchorPosition::End}};
    system.constraints.push_back(constraint);
  };
  auto addCoincident = [&](const std::string& cid, const std::string& first,
                           SketchSolverAnchorPosition firstPosition, const std::string& second,
                           SketchSolverAnchorPosition secondPosition) {
    SketchSolverConstraint constraint;
    constraint.cid = cid;
    constraint.kind = SketchSolverConstraintKind::Coincident;
    constraint.anchors = {{first, firstPosition}, {second, secondPosition}};
    system.constraints.push_back(constraint);
  };
  addAxis("cst_horizontal", SketchSolverConstraintKind::Horizontal, "ent_horizontal");
  addAxis("cst_vertical", SketchSolverConstraintKind::Vertical, "ent_vertical");
  addCoincident("cst_arc_to_horizontal", "ent_arc", SketchSolverAnchorPosition::End,
                "ent_horizontal", SketchSolverAnchorPosition::Start);
  addCoincident("cst_horizontal_to_vertical", "ent_horizontal", SketchSolverAnchorPosition::End,
                "ent_vertical", SketchSolverAnchorPosition::Start);
  addCoincident("cst_vertical_to_arc", "ent_vertical", SketchSolverAnchorPosition::End, "ent_arc",
                SketchSolverAnchorPosition::Start);

  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Converged, "the exact packaged contour converges");
  Check(result.degreesOfFreedom == 0, "grounded arc rules do not subtract a false negative DoF");
  Check(result.entities.size() == 3, "all three non-degenerate entities return");
}

void MalformedIsNotAFailure() {
  std::printf("10. a malformed system is INVALID input, never a solver failure:\n");
  SketchSolverSystem system = GroundedLine(20.0);
  system.constraints[0].anchors[0].eid = "ent_does_not_exist";
  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Invalid,
        "an anchor naming a missing entity is Invalid");
  Check(result.message.find("ent_does_not_exist") != std::string::npos,
        "the message names the missing entity");

  SketchSolverSystem wrongArity;
  SketchSolverEntity broken;
  broken.eid = "ent_broken";
  broken.kind = SketchSolverEntityKind::Line;
  broken.values = {0.0, 0.0}; // a line needs four
  wrongArity.entities.push_back(broken);
  const aeth::SketchSolverResult arity = aeth::SolveSketch(wrongArity);
  Check(arity.status == SketchSolverStatus::Invalid,
        "an entity with the wrong parameter count is Invalid");
  std::printf("     message: %s\n", arity.message.c_str());
}

void RadiusOnCircle() {
  std::printf("11. a radius dimension drives a circle:\n");
  SketchSolverSystem system;
  SketchSolverEntity centre;
  centre.eid = "ent_centre";
  centre.kind = SketchSolverEntityKind::Point;
  centre.values = {5.0, 5.0};
  system.entities.push_back(centre);

  SketchSolverEntity circle;
  circle.eid = "ent_circle";
  circle.kind = SketchSolverEntityKind::Circle;
  circle.values = {5.0, 5.0, 2.0}; // radius deliberately wrong
  system.entities.push_back(circle);
  system.grounded.push_back({"ent_centre"});

  SketchSolverConstraint pin;
  pin.cid = "cst_centre";
  pin.kind = SketchSolverConstraintKind::Coincident;
  pin.anchors = {{"ent_centre", SketchSolverAnchorPosition::Point},
                 {"ent_circle", SketchSolverAnchorPosition::Center}};
  system.constraints.push_back(pin);

  SketchSolverConstraint radius;
  radius.cid = "cst_radius";
  radius.kind = SketchSolverConstraintKind::Radius;
  radius.anchors = {{"ent_circle", SketchSolverAnchorPosition::Center}};
  radius.value = 12.5;
  system.constraints.push_back(radius);

  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Converged, "status is Converged");
  if (result.entities.size() == 2) {
    CheckClose(result.entities[1].values[2], 12.5, 1e-9, "the radius is driven to 12.5");
    CheckClose(result.entities[1].values[0], 5.0, 1e-9, "the centre stayed pinned");
  }
}

void ArcEndpointAnchors() {
  std::printf("12. arc endpoints are first-class anchors with degree angles:\n");
  SketchSolverSystem system;

  SketchSolverEntity left;
  left.eid = "ent_left";
  left.kind = SketchSolverEntityKind::Point;
  left.values = {-6.0, 0.0};
  system.entities.push_back(left);

  SketchSolverEntity right;
  right.eid = "ent_right";
  right.kind = SketchSolverEntityKind::Point;
  right.values = {6.0, 0.0};
  system.entities.push_back(right);

  SketchSolverEntity arc;
  arc.eid = "ent_arc";
  arc.kind = SketchSolverEntityKind::Arc;
  // Degrees, deliberately approximate. The radius constraint and endpoint
  // coincidences solve this to the 12 mm chord of a 10 mm circle.
  arc.values = {0.0, 7.0, 9.0, 225.0, 315.0};
  system.entities.push_back(arc);
  system.grounded.push_back({"ent_left"});
  system.grounded.push_back({"ent_right"});

  SketchSolverConstraint start;
  start.cid = "cst_arc_start";
  start.kind = SketchSolverConstraintKind::Coincident;
  start.anchors = {{"ent_left", SketchSolverAnchorPosition::Point},
                   {"ent_arc", SketchSolverAnchorPosition::Start}};
  system.constraints.push_back(start);

  SketchSolverConstraint end;
  end.cid = "cst_arc_end";
  end.kind = SketchSolverConstraintKind::Coincident;
  end.anchors = {{"ent_right", SketchSolverAnchorPosition::Point},
                 {"ent_arc", SketchSolverAnchorPosition::End}};
  system.constraints.push_back(end);

  SketchSolverConstraint radius;
  radius.cid = "cst_arc_radius";
  radius.kind = SketchSolverConstraintKind::Radius;
  radius.anchors = {{"ent_arc", SketchSolverAnchorPosition::Center}};
  radius.value = 10.0;
  system.constraints.push_back(radius);

  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Converged, "the line-and-arc closure converges");
  if (result.entities.size() != 3 || result.entities[2].values.size() != 5) {
    Check(false, "the public arc remains exactly five values");
    return;
  }

  constexpr double pi = 3.141592653589793238462643383279502884;
  const std::vector<double>& solved = result.entities[2].values;
  const double startRadians = solved[3] * pi / 180.0;
  const double endRadians = solved[4] * pi / 180.0;
  CheckClose(solved[2], 10.0, 1e-8, "the arc radius is driven");
  CheckClose(solved[0] + solved[2] * std::cos(startRadians), -6.0, 1e-8,
             "the arc start lands on the left point (x)");
  CheckClose(solved[1] + solved[2] * std::sin(startRadians), 0.0, 1e-8,
             "the arc start lands on the left point (y)");
  CheckClose(solved[0] + solved[2] * std::cos(endRadians), 6.0, 1e-8,
             "the arc end lands on the right point (x)");
  CheckClose(solved[1] + solved[2] * std::sin(endRadians), 0.0, 1e-8,
             "the arc end lands on the right point (y)");
  Check(result.degreesOfFreedom == 0, "the closed arc system reports 0 DoF");

  const aeth::SketchSolverResult repeated = aeth::SolveSketch(system);
  const bool identical = repeated.entities.size() == result.entities.size() &&
                         repeated.entities[2].values.size() == solved.size() &&
                         std::memcmp(repeated.entities[2].values.data(), solved.data(),
                                     solved.size() * sizeof(double)) == 0;
  Check(identical, "the solved arc is byte-identical on repeat");

  SketchSolverSystem invalid = system;
  invalid.constraints[0].anchors[1].position = SketchSolverAnchorPosition::Point;
  const aeth::SketchSolverResult refused = aeth::SolveSketch(invalid);
  Check(refused.status == SketchSolverStatus::Invalid, "an unsupported arc anchor fails closed");
  Check(refused.message.find("arc") != std::string::npos,
        "the invalid-anchor message names the arc");
}

void SignedZeroCanonicalization() {
  std::printf("13. accepted solutions expose only canonical positive zero:\n");
  const double negativeZero = std::copysign(0.0, -1.0);

  SketchSolverSystem fixed;
  fixed.entities.push_back(
      {"ent_fixed_point", SketchSolverEntityKind::Point, {negativeZero, negativeZero}});
  fixed.grounded.push_back({"ent_fixed_point"});
  const aeth::SketchSolverResult fixedResult = aeth::SolveSketch(fixed);
  Check(fixedResult.status == SketchSolverStatus::Converged,
        "a fully grounded signed-zero input converges");

  SketchSolverSystem solved = GroundedLine(20.0);
  solved.entities[0].values = {negativeZero, negativeZero};
  solved.entities[1].values[0] = negativeZero;
  solved.entities[1].values[1] = negativeZero;
  const aeth::SketchSolverResult solvedResult = aeth::SolveSketch(solved);
  Check(solvedResult.status == SketchSolverStatus::Converged,
        "a mixed grounded/solved signed-zero input converges");

  bool sawZero = false;
  bool allZerosCanonical = true;
  for (const aeth::SketchSolverResult* result : {&fixedResult, &solvedResult}) {
    for (const SketchSolverEntity& entity : result->entities) {
      for (const double value : entity.values) {
        if (value == 0.0) {
          sawZero = true;
          allZerosCanonical = allZerosCanonical && !std::signbit(value);
        }
      }
    }
  }
  Check(sawZero, "the regression exercised returned zero coordinates");
  Check(allZerosCanonical,
        "fully grounded and numerically solved paths canonicalize every -0 to +0");
}

/// The shim is OURS and it is LIVE — GCS.cpp calls it inside diagnose(). These
/// assert boost::connected_components' documented contract: a dense 0..k-1
/// label per vertex, and the component COUNT as the return value.
void UnionFindShim() {
  std::printf("14. the union-find shim honours connected_components' contract:\n");
  {
    boost::adjacency_list<> g;
    for (int i = 0; i < 6; ++i) {
      boost::add_vertex(g);
    }
    boost::add_edge(0, 1, g);
    boost::add_edge(1, 2, g);
    boost::add_edge(3, 4, g);
    // vertex 5 is isolated -> its own component
    std::vector<int> components(boost::num_vertices(g));
    const std::size_t count = boost::connected_components(g, &components[0]);
    Check(count == 3, "three components (got " + std::to_string(count) + ")");
    Check(components[0] == components[1] && components[1] == components[2],
          "0,1,2 share a component");
    Check(components[3] == components[4], "3,4 share a component");
    Check(components[5] != components[0] && components[5] != components[3],
          "the isolated vertex is its own component");
    bool dense = true;
    for (const int label : components) {
      if (label < 0 || label >= static_cast<int>(count)) {
        dense = false;
      }
    }
    Check(dense, "labels are dense in 0..k-1, as boost documents");
  }
  {
    // Transitivity through a chain, which a naive non-compressing find gets
    // wrong once the union order is unfavourable.
    boost::adjacency_list<> g;
    for (int i = 0; i < 8; ++i) {
      boost::add_vertex(g);
    }
    boost::add_edge(7, 6, g);
    boost::add_edge(6, 5, g);
    boost::add_edge(5, 4, g);
    boost::add_edge(4, 3, g);
    boost::add_edge(3, 2, g);
    boost::add_edge(2, 1, g);
    boost::add_edge(1, 0, g);
    std::vector<int> components(boost::num_vertices(g));
    const std::size_t count = boost::connected_components(g, &components[0]);
    Check(count == 1, "a chain of 8 is ONE component (got " + std::to_string(count) + ")");
  }
  {
    boost::adjacency_list<> g;
    std::vector<int> components;
    const std::size_t count = boost::connected_components(g, components.data());
    Check(count == 0, "an empty graph has zero components");
  }
}

/// Two lines: the first pinned along +u, the second free and starting askew.
/// The second's start is pinned so only its DIRECTION is left to solve for,
/// which is what makes the resulting angle a clean assertion.
SketchSolverSystem TwoLines(double secondEndX, double secondEndY) {
  SketchSolverSystem system;
  SketchSolverEntity fixed;
  fixed.eid = "ent_fixed";
  fixed.kind = SketchSolverEntityKind::Line;
  fixed.values = {0.0, 0.0, 10.0, 0.0};
  system.entities.push_back(fixed);

  SketchSolverEntity free;
  free.eid = "ent_free";
  free.kind = SketchSolverEntityKind::Line;
  // Deliberately neither parallel nor perpendicular to the fixed line.
  free.values = {0.0, 5.0, secondEndX, secondEndY};
  system.entities.push_back(free);

  system.grounded.push_back({"ent_fixed"});
  return system;
}

SketchSolverConstraint Relation(const std::string& cid, SketchSolverConstraintKind kind) {
  SketchSolverConstraint relation;
  relation.cid = cid;
  relation.kind = kind;
  relation.anchors = {{"ent_fixed", SketchSolverAnchorPosition::Start},
                      {"ent_free", SketchSolverAnchorPosition::Start}};
  return relation;
}

/// The direction of the solved `ent_free`, as (dx, dy).
std::pair<double, double> FreeDirection(const aeth::SketchSolverResult& result) {
  for (const SketchSolverEntity& entity : result.entities) {
    if (entity.eid == "ent_free") {
      return {entity.values[2] - entity.values[0], entity.values[3] - entity.values[1]};
    }
  }
  return {0.0, 0.0};
}

void ParallelAndPerpendicular() {
  std::printf("15. two lines can be held parallel or perpendicular:\n");

  SketchSolverSystem parallel = TwoLines(8.0, 11.0);
  parallel.constraints.push_back(Relation("cst_parallel", SketchSolverConstraintKind::Parallel));
  const aeth::SketchSolverResult parallelResult = aeth::SolveSketch(parallel);
  Check(parallelResult.status == SketchSolverStatus::Converged ||
            parallelResult.status == SketchSolverStatus::Redundant,
        "a parallel between two lines solves");
  const auto parallelDirection = FreeDirection(parallelResult);
  // Parallel drives the SINE of the angle between to zero: the cross product
  // of the two directions vanishes while the dot product stays large.
  CheckClose(parallelDirection.second, 0.0, 1e-9,
             "the free line ends up running along the fixed one");

  SketchSolverSystem perpendicular = TwoLines(8.0, 11.0);
  perpendicular.constraints.push_back(
      Relation("cst_perpendicular", SketchSolverConstraintKind::Perpendicular));
  const aeth::SketchSolverResult perpendicularResult = aeth::SolveSketch(perpendicular);
  Check(perpendicularResult.status == SketchSolverStatus::Converged ||
            perpendicularResult.status == SketchSolverStatus::Redundant,
        "a perpendicular between two lines solves");
  const auto perpendicularDirection = FreeDirection(perpendicularResult);
  CheckClose(perpendicularDirection.first, 0.0, 1e-9,
             "the free line ends up square to the fixed one");

  // Grounding BOTH lines removes every unknown, which is the path where
  // PlaneGCS skips diagnosis and the solver must check the relation itself.
  SketchSolverSystem grounded = TwoLines(8.0, 11.0);
  grounded.grounded.push_back({"ent_free"});
  grounded.constraints.push_back(
      Relation("cst_impossible", SketchSolverConstraintKind::Perpendicular));
  const aeth::SketchSolverResult groundedResult = aeth::SolveSketch(grounded);
  Check(groundedResult.status == SketchSolverStatus::Conflicting,
        "two pinned lines that are not square refuse a perpendicular");
  Check(groundedResult.conflicting == std::vector<std::string>{"cst_impossible"},
        "the unsatisfiable relation is named exactly");

  // The same pinned pair, this time genuinely perpendicular, must be accepted:
  // a check that refuses everything would pass the test above for free.
  SketchSolverSystem groundedTrue = TwoLines(0.0, 12.0);
  groundedTrue.grounded.push_back({"ent_free"});
  groundedTrue.constraints.push_back(
      Relation("cst_true", SketchSolverConstraintKind::Perpendicular));
  const aeth::SketchSolverResult trueResult = aeth::SolveSketch(groundedTrue);
  Check(trueResult.status == SketchSolverStatus::Converged ||
            trueResult.status == SketchSolverStatus::Redundant,
        "two pinned lines that ARE square accept the perpendicular");

  // A line has no angle to itself, and saying so is an authoring error rather
  // than a numeric one — it is refused before any solving happens.
  SketchSolverSystem itself = TwoLines(8.0, 11.0);
  SketchSolverConstraint self;
  self.cid = "cst_self";
  self.kind = SketchSolverConstraintKind::Parallel;
  self.anchors = {{"ent_free", SketchSolverAnchorPosition::Start},
                  {"ent_free", SketchSolverAnchorPosition::Start}};
  itself.constraints.push_back(self);
  Check(aeth::SolveSketch(itself).status == SketchSolverStatus::Invalid,
        "a line parallel to itself is refused as invalid");

  // Direction is a property of a line; a circle has none.
  SketchSolverSystem circle = TwoLines(8.0, 11.0);
  SketchSolverEntity round;
  round.eid = "ent_circle";
  round.kind = SketchSolverEntityKind::Circle;
  round.values = {0.0, 0.0, 4.0};
  circle.entities.push_back(round);
  SketchSolverConstraint onCircle;
  onCircle.cid = "cst_on_circle";
  onCircle.kind = SketchSolverConstraintKind::Parallel;
  onCircle.anchors = {{"ent_fixed", SketchSolverAnchorPosition::Start},
                      {"ent_circle", SketchSolverAnchorPosition::Center}};
  circle.constraints.push_back(onCircle);
  Check(aeth::SolveSketch(circle).status == SketchSolverStatus::Invalid,
        "a circle cannot be made parallel to anything");
}

SketchSolverConstraint AnchoredConstraint(const std::string& cid, SketchSolverConstraintKind kind,
                                          const std::string& first,
                                          SketchSolverAnchorPosition firstPosition,
                                          const std::string& second,
                                          SketchSolverAnchorPosition secondPosition,
                                          double value = 0.0) {
  SketchSolverConstraint constraint;
  constraint.cid = cid;
  constraint.kind = kind;
  constraint.anchors = {{first, firstPosition}, {second, secondPosition}};
  constraint.value = value;
  return constraint;
}

void ExtendedConstraintMappingCoverage() {
  std::printf("16. every extended dimensional and relational constraint lowers and replays:\n");

  auto accepted = [&](const std::string& label, const SketchSolverSystem& system) {
    const aeth::SketchSolverResult result = aeth::SolveSketch(system);
    Check(result.status == SketchSolverStatus::Converged ||
              result.status == SketchSolverStatus::Redundant,
          label + " is accepted");
  };

  {
    SketchSolverSystem system;
    system.entities.push_back(
        {"ent_horizontal", SketchSolverEntityKind::Line, {0.0, 0.0, 10.0, 0.0}});
    system.grounded.push_back({"ent_horizontal"});
    system.constraints.push_back(AnchoredConstraint(
        "cst_horizontal_distance", SketchSolverConstraintKind::HorizontalDistance, "ent_horizontal",
        SketchSolverAnchorPosition::Start, "ent_horizontal", SketchSolverAnchorPosition::End,
        10.0));
    accepted("horizontal distance", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back(
        {"ent_vertical", SketchSolverEntityKind::Line, {0.0, 0.0, 0.0, 10.0}});
    system.grounded.push_back({"ent_vertical"});
    system.constraints.push_back(AnchoredConstraint(
        "cst_vertical_distance", SketchSolverConstraintKind::VerticalDistance, "ent_vertical",
        SketchSolverAnchorPosition::Start, "ent_vertical", SketchSolverAnchorPosition::End, 10.0));
    accepted("vertical distance", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back({"ent_length", SketchSolverEntityKind::Line, {0.0, 0.0, 10.0, 0.0}});
    system.grounded.push_back({"ent_length"});
    system.constraints.push_back(AnchoredConstraint(
        "cst_length", SketchSolverConstraintKind::Length, "ent_length",
        SketchSolverAnchorPosition::Start, "ent_length", SketchSolverAnchorPosition::End, 10.0));
    accepted("length", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back({"ent_diameter", SketchSolverEntityKind::Circle, {0.0, 0.0, 5.0}});
    system.grounded.push_back({"ent_diameter"});
    SketchSolverConstraint constraint;
    constraint.cid = "cst_diameter";
    constraint.kind = SketchSolverConstraintKind::Diameter;
    constraint.anchors = {{"ent_diameter", SketchSolverAnchorPosition::Center}};
    constraint.value = 10.0;
    system.constraints.push_back(constraint);
    accepted("diameter", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back({"ent_fixed", SketchSolverEntityKind::Point, {2.0, 3.0}});
    SketchSolverConstraint constraint;
    constraint.cid = "cst_fixed";
    constraint.kind = SketchSolverConstraintKind::Fixed;
    constraint.anchors = {{"ent_fixed", SketchSolverAnchorPosition::Point}};
    system.constraints.push_back(constraint);
    accepted("fixed/ground", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back({"ent_midpoint", SketchSolverEntityKind::Line, {0.0, 0.0, 4.0, 0.0}});
    system.entities.push_back(
        {"ent_midpoint_axis", SketchSolverEntityKind::Line, {2.0, -3.0, 2.0, 3.0}});
    system.grounded.push_back({"ent_midpoint"});
    system.grounded.push_back({"ent_midpoint_axis"});
    system.constraints.push_back(AnchoredConstraint(
        "cst_midpoint", SketchSolverConstraintKind::Midpoint, "ent_midpoint",
        SketchSolverAnchorPosition::Start, "ent_midpoint_axis", SketchSolverAnchorPosition::Start));
    accepted("midpoint", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back(
        {"ent_collinear_a", SketchSolverEntityKind::Line, {0.0, 0.0, 4.0, 0.0}});
    system.entities.push_back(
        {"ent_collinear_b", SketchSolverEntityKind::Line, {1.0, 0.0, 3.0, 0.0}});
    system.grounded.push_back({"ent_collinear_a"});
    system.grounded.push_back({"ent_collinear_b"});
    system.constraints.push_back(AnchoredConstraint(
        "cst_collinear", SketchSolverConstraintKind::Collinear, "ent_collinear_a",
        SketchSolverAnchorPosition::Start, "ent_collinear_b", SketchSolverAnchorPosition::Start));
    accepted("collinear", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back(
        {"ent_tangent_line", SketchSolverEntityKind::Line, {-5.0, 5.0, 5.0, 5.0}});
    system.entities.push_back(
        {"ent_tangent_circle", SketchSolverEntityKind::Circle, {0.0, 0.0, 5.0}});
    system.grounded.push_back({"ent_tangent_line"});
    system.grounded.push_back({"ent_tangent_circle"});
    system.constraints.push_back(
        AnchoredConstraint("cst_tangent", SketchSolverConstraintKind::Tangent, "ent_tangent_line",
                           SketchSolverAnchorPosition::Start, "ent_tangent_circle",
                           SketchSolverAnchorPosition::Center));
    accepted("tangent", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back({"ent_equal_a", SketchSolverEntityKind::Line, {0.0, 0.0, 5.0, 0.0}});
    system.entities.push_back({"ent_equal_b", SketchSolverEntityKind::Line, {0.0, 2.0, 5.0, 2.0}});
    system.grounded.push_back({"ent_equal_a"});
    system.grounded.push_back({"ent_equal_b"});
    system.constraints.push_back(AnchoredConstraint(
        "cst_equal", SketchSolverConstraintKind::Equal, "ent_equal_a",
        SketchSolverAnchorPosition::Start, "ent_equal_b", SketchSolverAnchorPosition::Start));
    accepted("equal", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back(
        {"ent_concentric_a", SketchSolverEntityKind::Circle, {2.0, 3.0, 5.0}});
    system.entities.push_back(
        {"ent_concentric_b", SketchSolverEntityKind::Circle, {2.0, 3.0, 2.0}});
    system.grounded.push_back({"ent_concentric_a"});
    system.grounded.push_back({"ent_concentric_b"});
    system.constraints.push_back(
        AnchoredConstraint("cst_concentric", SketchSolverConstraintKind::Concentric,
                           "ent_concentric_a", SketchSolverAnchorPosition::Center,
                           "ent_concentric_b", SketchSolverAnchorPosition::Center));
    accepted("concentric", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back({"ent_symmetric_a", SketchSolverEntityKind::Point, {-2.0, 1.0}});
    system.entities.push_back({"ent_symmetric_b", SketchSolverEntityKind::Point, {2.0, 1.0}});
    system.entities.push_back(
        {"ent_symmetry_axis", SketchSolverEntityKind::Line, {0.0, -3.0, 0.0, 3.0}});
    system.grounded.push_back({"ent_symmetric_a"});
    system.grounded.push_back({"ent_symmetric_b"});
    system.grounded.push_back({"ent_symmetry_axis"});
    SketchSolverConstraint constraint;
    constraint.cid = "cst_symmetry";
    constraint.kind = SketchSolverConstraintKind::Symmetry;
    constraint.anchors = {{"ent_symmetric_a", SketchSolverAnchorPosition::Point},
                          {"ent_symmetric_b", SketchSolverAnchorPosition::Point},
                          {"ent_symmetry_axis", SketchSolverAnchorPosition::Start}};
    system.constraints.push_back(constraint);
    accepted("symmetry", system);
  }

  {
    SketchSolverSystem system;
    system.entities.push_back({"ent_angle_a", SketchSolverEntityKind::Line, {0.0, 0.0, 5.0, 0.0}});
    system.entities.push_back({"ent_angle_b", SketchSolverEntityKind::Line, {0.0, 0.0, 0.0, 5.0}});
    system.grounded.push_back({"ent_angle_a"});
    system.grounded.push_back({"ent_angle_b"});
    system.constraints.push_back(AnchoredConstraint(
        "cst_angle", SketchSolverConstraintKind::Angle, "ent_angle_a",
        SketchSolverAnchorPosition::Start, "ent_angle_b", SketchSolverAnchorPosition::Start, 90.0));
    accepted("angle/angular", system);
  }
}

void RichEntityKindCoverage() {
  std::printf("17. every persisted sketch entity kind validates and survives replay:\n");
  SketchSolverSystem system;
  system.entities.push_back({"ent_point", SketchSolverEntityKind::Point, {0.0, 0.0}});
  system.entities.push_back({"ent_line", SketchSolverEntityKind::Line, {0.0, 0.0, 10.0, 0.0}});
  system.entities.push_back(
      {"ent_polyline", SketchSolverEntityKind::Polyline, {0.0, 0.0, 2.0, 1.0, 4.0, 0.0}});
  system.entities.push_back(
      {"ent_rectangle", SketchSolverEntityKind::Rectangle, {0.0, 0.0, 10.0, 5.0, 0.0}});
  system.entities.push_back({"ent_circle", SketchSolverEntityKind::Circle, {0.0, 0.0, 3.0}});
  system.entities.push_back({"ent_arc", SketchSolverEntityKind::Arc, {0.0, 0.0, 3.0, 0.0, 90.0}});
  system.entities.push_back({"ent_arc_three_point",
                             SketchSolverEntityKind::ArcThreePoint,
                             {0.0, 0.0, 2.0, 3.0, 4.0, 0.0}});
  system.entities.push_back(
      {"ent_ellipse", SketchSolverEntityKind::Ellipse, {0.0, 0.0, 5.0, 3.0, 0.0}});
  system.entities.push_back(
      {"ent_polygon", SketchSolverEntityKind::Polygon, {0.0, 0.0, 6.0, 4.0, 0.0}});
  system.entities.push_back({"ent_slot", SketchSolverEntityKind::Slot, {0.0, 0.0, 10.0, 0.0, 4.0}});
  system.entities.push_back(
      {"ent_spline", SketchSolverEntityKind::Spline, {0.0, 0.0, 1.0, 2.0, 3.0, 2.0, 4.0, 0.0}});
  for (const SketchSolverEntity& entity : system.entities) {
    system.grounded.push_back({entity.eid});
  }
  const aeth::SketchSolverResult result = aeth::SolveSketch(system);
  Check(result.status == SketchSolverStatus::Converged ||
            result.status == SketchSolverStatus::Redundant,
        "all eleven entity kinds are accepted");
  Check(result.entities.size() == system.entities.size(),
        "all eleven entity kinds return from the solver");
  if (result.entities.size() == system.entities.size()) {
    bool sameOrder = true;
    for (std::size_t index = 0; index < result.entities.size(); ++index) {
      sameOrder = sameOrder && result.entities[index].eid == system.entities[index].eid;
    }
    Check(sameOrder, "rich entity replay preserves authored order and identity");
  }
}

} // namespace

int main() {
  std::printf("sketch solver seam (CAP-036)\n");
  CorrectSolve();
  Deterministic();
  UnderConstrained();
  Conflicting();
  MutuallyExclusiveAxes();
  GroundedContradiction();
  SelfEndpointCollapse();
  FixedRedundancy();
  GroundedArcContour();
  MalformedIsNotAFailure();
  RadiusOnCircle();
  ArcEndpointAnchors();
  SignedZeroCanonicalization();
  UnionFindShim();
  ParallelAndPerpendicular();
  ExtendedConstraintMappingCoverage();
  RichEntityKindCoverage();
  if (g_failures != 0) {
    std::printf("%d SKETCH SOLVER CHECK(S) FAILED\n", g_failures);
    return 1;
  }
  std::printf("ALL SKETCH SOLVER TESTS PASSED\n");
  return 0;
}
