// The ADR-016 sketch-solver seam: constraint system in, solution + diagnosis
// out. THIS HEADER MENTIONS NO PlaneGCS TYPE. `sketch_solver.cpp` is the only
// translation unit in the repository permitted to include the vendored subtree
// (native/kernel-host/third_party/planegcs), which is what makes replacing the
// engine a one-file change rather than a refactor.
//
// The diagnosis vocabulary below is OURS. PlaneGCS reports integers and tag
// sets; every word a person could read is authored on this side, because
// ADR-016's whole argument for adopting the library was that its numerics are
// excellent and its messaging is not.
#pragma once

#include <cstddef>
#include <string>
#include <vector>

namespace aeth {

/// A solver parameter: one scalar degree of freedom (a coordinate, a radius).
/// The caller owns the ordering; the solver returns values in the same order.
using SketchParameterValues = std::vector<double>;

/// Entity kinds the solver understands. Compound/analytic kinds keep their
/// canonical authored values in the same deterministic vector even when a
/// particular PlaneGCS relation has no native lowering; this lets them
/// participate in coincident/distance constraints through their exposed
/// anchors and prevents the wire from silently rejecting valid sketch data.
enum class SketchSolverEntityKind {
  Point,
  Line,
  Polyline,
  Rectangle,
  Circle,
  Arc,
  ArcThreePoint,
  Ellipse,
  Polygon,
  Slot,
  Spline,
};

/// One entity's parameter block. `values` holds the entity's scalars in the
/// kind's canonical order:
///   Point  -> x, y
///   Line   -> x1, y1, x2, y2
///   Circle -> cx, cy, r
///   Polyline/Spline -> x,y pairs for each control point
///   Rectangle -> x,y,width,height,rotationDegrees
///   Arc      -> cx, cy, r, startAngleDegrees, endAngleDegrees
///   ArcThreePoint -> p1x,p1y,p2x,p2y,p3x,p3y
///   Ellipse  -> cx,cy,radiusX,radiusY,rotationDegrees
///   Polygon  -> cx,cy,sides,circumradius,rotationDegrees
///   Slot     -> p1x,p1y,p2x,p2y,width
struct SketchSolverEntity {
  std::string eid;
  SketchSolverEntityKind kind = SketchSolverEntityKind::Point;
  SketchParameterValues values;
};

/// The point-like positions exposed by the persisted sketch anchor contract.
/// Keeping these names typed at the native seam prevents one kind's numeric
/// convention from being silently reinterpreted as another kind's position.
enum class SketchSolverAnchorPosition {
  Point,
  Start,
  End,
  Center,
  Mid,
};

/// Which point-like position of which entity a constraint refers to.
struct SketchSolverAnchor {
  std::string eid;
  SketchSolverAnchorPosition position = SketchSolverAnchorPosition::Point;
};

/// The constraints CAP-035's schema ships. Adding one is a schema change
/// first, never a solver change first.
///
/// Coincident/Horizontal/Vertical/Distance/Radius are ABSOLUTE: each pins
/// geometry against the sketch frame or a fixed number. Parallel and
/// Perpendicular are RELATIVE — they fix two lines with respect to each other
/// and neither one in the plane, so a parallel pair still turns together. That
/// difference is why they take two entities rather than an entity and a value.
enum class SketchSolverConstraintKind {
  Coincident,
  Horizontal,
  Vertical,
  Distance,
  Radius,
  Midpoint,
  Collinear,
  HorizontalDistance,
  VerticalDistance,
  Length,
  Diameter,
  Fixed,
  Parallel,
  Perpendicular,
  Tangent,
  Equal,
  Concentric,
  Symmetry,
  Angle,
};

struct SketchSolverConstraint {
  std::string cid;
  SketchSolverConstraintKind kind = SketchSolverConstraintKind::Coincident;
  std::vector<SketchSolverAnchor> anchors;
  /// The driving value for dimensional constraints; ignored by relations.
  double value = 0.0;
  /// Reference dimensions report a value without changing geometry.
  bool driving = true;
};

/// An entity whose parameters are pinned. Without at least one, a
/// least-squares solve is free to TRANSLATE the whole sketch — GOV-004
/// measured exactly that (a width dimension moved both endpoints). Grounding
/// is therefore part of the contract, not a later refinement.
struct SketchSolverGround {
  std::string eid;
};

struct SketchSolverSystem {
  std::vector<SketchSolverEntity> entities;
  std::vector<SketchSolverConstraint> constraints;
  std::vector<SketchSolverGround> grounded;
};

/// The outcome vocabulary. `Converged` is the only success; everything else
/// names a condition a person can act on.
enum class SketchSolverStatus {
  Converged,
  /// The system has no solution: constraints genuinely disagree. The
  /// conflicting constraint ids are enumerated.
  Conflicting,
  /// The system is solvable but over-specified: some constraints are implied
  /// by others. Redundant ids are enumerated. This is NOT a failure.
  Redundant,
  /// The numerics did not converge within the iteration budget. Distinct from
  /// Conflicting: a person's fix is different.
  DidNotConverge,
  /// The system as described is not solvable input at all (an anchor naming
  /// an entity that is not present, an entity with the wrong parameter count).
  /// Reported before any numeric work.
  Invalid,
};

struct SketchSolverResult {
  SketchSolverStatus status = SketchSolverStatus::Invalid;
  /// Solved parameter values, entity-by-entity in the input order. Populated
  /// on Converged and Redundant; empty otherwise.
  std::vector<SketchSolverEntity> entities;
  /// Remaining free degrees of freedom. 0 means fully constrained.
  int degreesOfFreedom = 0;
  /// Constraint ids the solver identified, per `status`. Named, never counted:
  /// "3 constraints conflict" is not actionable, "these three" is.
  std::vector<std::string> conflicting;
  std::vector<std::string> redundant;
  /// A sentence in OUR words, safe to show a person. Never PlaneGCS text.
  std::string message;
};

/// Solve `system`. Deterministic: the same system solved twice returns
/// bit-identical parameter values (the ADR-016 determinism contract, measured
/// by the native gate). Never throws for bad input — malformed systems come
/// back as `Invalid` with a message.
SketchSolverResult SolveSketch(const SketchSolverSystem& system);

/// The number of scalar parameters an entity kind carries. Exposed because
/// both the solver and its validation need it and a second copy would drift.
std::size_t SketchEntityParameterCount(SketchSolverEntityKind kind);

} // namespace aeth
