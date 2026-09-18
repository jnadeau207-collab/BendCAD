// The ADR-016 seam implementation. THIS IS THE ONLY TRANSLATION UNIT IN THE
// REPOSITORY THAT INCLUDES PlaneGCS. Everything below the include boundary is
// translation: our typed system in, PlaneGCS's raw doubles and integer tags
// out, and then OUR vocabulary back to the caller.
//
// Two properties this file is responsible for, both measured by the gate:
//
//  * DETERMINISM. PlaneGCS holds `double*` into caller storage, so the solve
//    depends on parameter ORDER. Order here is derived from the input order —
//    never from a hash map iteration, which would be stable within a build and
//    silently different across one.
//  * DIAGNOSIS IN OUR WORDS. PlaneGCS reports integer tags. We assign those
//    tags from the constraint list, so mapping back to the caller's `cid` is
//    exact, and every message is authored here.
#include "sketch_solver.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "GCS.h" // the vendored subtree — nowhere else

namespace aeth {
namespace {

/// Tags are 1-based: PlaneGCS treats tag 0 as "untagged", so a constraint
/// given tag 0 would be invisible to getConflicting/getRedundant and its
/// conflict would be detected but unattributable.
constexpr int kFirstTag = 1;
constexpr double kPi = 3.141592653589793238462643383279502884;
constexpr double kFixedConstraintTolerance = 1e-8;
constexpr double kSketchMinimumSize = 1e-6;
constexpr double kSketchCoordinateLimit = 1e7;

/// DogLeg's iteration budget is PlaneGCS's own default; we do not raise it.
/// A system that does not converge is a diagnosis, not something to grind at.
bool IsFinite(double value) { return std::isfinite(value); }

double DegreesToRadians(double degrees) { return degrees * kPi / 180.0; }

double RadiansToDegrees(double radians) { return radians * 180.0 / kPi; }

/// PlaneGCS stores an arc's four derived endpoint coordinates in addition to
/// the five values in our public contract. That is an adapter detail: callers
/// continue to send and receive cx, cy, r, startAngleDeg, endAngleDeg.
std::size_t PlaneGcsParameterCount(const SketchSolverEntity& entity) {
  if (entity.kind == SketchSolverEntityKind::Arc)
    return 9;
  if (entity.kind == SketchSolverEntityKind::Polyline ||
      entity.kind == SketchSolverEntityKind::Spline) {
    return entity.values.size();
  }
  return SketchEntityParameterCount(entity.kind);
}

struct EntityLayout {
  std::size_t entityIndex = 0;
  std::size_t firstParam = 0;
  SketchSolverEntityKind kind = SketchSolverEntityKind::Point;
  bool grounded = false;
};

struct AxisConstraintIds {
  std::vector<std::string> horizontal;
  std::vector<std::string> vertical;
};

SketchSolverResult Invalid(std::string message) {
  SketchSolverResult result;
  result.status = SketchSolverStatus::Invalid;
  result.message = std::move(message);
  return result;
}

SketchSolverResult Conflict(std::vector<std::string> names, int degreesOfFreedom) {
  std::sort(names.begin(), names.end());
  names.erase(std::unique(names.begin(), names.end()), names.end());

  SketchSolverResult result;
  result.status = SketchSolverStatus::Conflicting;
  result.conflicting = std::move(names);
  result.degreesOfFreedom = degreesOfFreedom;
  if (result.conflicting.empty()) {
    result.message = "These constraints cannot all be satisfied at once.";
    return result;
  }

  std::string joined;
  for (const std::string& name : result.conflicting) {
    if (!joined.empty()) {
      joined += ", ";
    }
    joined += name;
  }
  result.message = "These constraints cannot all be satisfied at once: " + joined + ".";
  return result;
}

bool SameAnchor(const SketchSolverAnchor& a, const SketchSolverAnchor& b) {
  return a.eid == b.eid && a.position == b.position;
}

bool SameConstraintDefinition(const SketchSolverConstraint& a, const SketchSolverConstraint& b) {
  if (a.kind != b.kind || a.anchors.size() != b.anchors.size()) {
    return false;
  }
  if (a.driving != b.driving) {
    return false;
  }
  if ((a.kind == SketchSolverConstraintKind::Distance ||
       a.kind == SketchSolverConstraintKind::Radius ||
       a.kind == SketchSolverConstraintKind::HorizontalDistance ||
       a.kind == SketchSolverConstraintKind::VerticalDistance ||
       a.kind == SketchSolverConstraintKind::Length ||
       a.kind == SketchSolverConstraintKind::Diameter ||
       a.kind == SketchSolverConstraintKind::Angle) &&
      a.value != b.value) {
    return false;
  }
  if (a.anchors.size() == 1) {
    return SameAnchor(a.anchors[0], b.anchors[0]);
  }
  if (a.anchors.size() != 2) {
    return false;
  }
  return (SameAnchor(a.anchors[0], b.anchors[0]) && SameAnchor(a.anchors[1], b.anchors[1])) ||
         (SameAnchor(a.anchors[0], b.anchors[1]) && SameAnchor(a.anchors[1], b.anchors[0]));
}

std::string EntityGeometryError(const SketchSolverEntity& entity) {
  const auto coordinateInRange = [](double value) {
    return std::abs(value) <= kSketchCoordinateLimit;
  };
  switch (entity.kind) {
  case SketchSolverEntityKind::Point:
    if (!coordinateInRange(entity.values[0]) || !coordinateInRange(entity.values[1])) {
      return "has a coordinate outside the supported sketch range";
    }
    return {};
  case SketchSolverEntityKind::Polyline:
  case SketchSolverEntityKind::Spline:
    for (const double value : entity.values) {
      if (!coordinateInRange(value)) {
        return "has a coordinate outside the supported sketch range";
      }
    }
    return {};
  case SketchSolverEntityKind::Rectangle:
    if (entity.values.size() != 5 || !coordinateInRange(entity.values[0]) ||
        !coordinateInRange(entity.values[1]) || entity.values[2] < kSketchMinimumSize ||
        entity.values[2] > kSketchCoordinateLimit || entity.values[3] < kSketchMinimumSize ||
        entity.values[3] > kSketchCoordinateLimit || !IsFinite(entity.values[4])) {
      return "has invalid rectangle dimensions or coordinates";
    }
    return {};
  case SketchSolverEntityKind::Line:
    for (const double value : entity.values) {
      if (!coordinateInRange(value)) {
        return "has a coordinate outside the supported sketch range";
      }
    }
    if (std::hypot(entity.values[2] - entity.values[0], entity.values[3] - entity.values[1]) <
        kSketchMinimumSize) {
      return "collapsed below the minimum line length";
    }
    return {};
  case SketchSolverEntityKind::Circle:
    if (!coordinateInRange(entity.values[0]) || !coordinateInRange(entity.values[1]) ||
        entity.values[2] < kSketchMinimumSize || entity.values[2] > kSketchCoordinateLimit) {
      return "has an invalid circle radius or coordinate";
    }
    return {};
  case SketchSolverEntityKind::Arc: {
    if (!coordinateInRange(entity.values[0]) || !coordinateInRange(entity.values[1]) ||
        entity.values[2] < kSketchMinimumSize || entity.values[2] > kSketchCoordinateLimit) {
      return "has an invalid arc radius or coordinate";
    }
    const double start = DegreesToRadians(entity.values[3]);
    const double end = DegreesToRadians(entity.values[4]);
    const double chord = std::hypot(entity.values[2] * (std::cos(end) - std::cos(start)),
                                    entity.values[2] * (std::sin(end) - std::sin(start)));
    if (chord < kSketchMinimumSize) {
      return "collapsed below the minimum arc chord";
    }
    return {};
  }
  case SketchSolverEntityKind::ArcThreePoint:
    for (const double value : entity.values) {
      if (!coordinateInRange(value)) {
        return "has a coordinate outside the supported sketch range";
      }
    }
    if (std::hypot(entity.values[2] - entity.values[0], entity.values[3] - entity.values[1]) <
            kSketchMinimumSize ||
        std::hypot(entity.values[4] - entity.values[2], entity.values[5] - entity.values[3]) <
            kSketchMinimumSize) {
      return "has repeated three-point arc points";
    }
    return {};
  case SketchSolverEntityKind::Ellipse:
    if (!coordinateInRange(entity.values[0]) || !coordinateInRange(entity.values[1]) ||
        entity.values[2] < kSketchMinimumSize || entity.values[2] > kSketchCoordinateLimit ||
        entity.values[3] < kSketchMinimumSize || entity.values[3] > kSketchCoordinateLimit ||
        !IsFinite(entity.values[4])) {
      return "has invalid ellipse dimensions or coordinates";
    }
    return {};
  case SketchSolverEntityKind::Polygon:
    if (!coordinateInRange(entity.values[0]) || !coordinateInRange(entity.values[1]) ||
        entity.values[2] < 3.0 || entity.values[2] > 64.0 ||
        std::floor(entity.values[2]) != entity.values[2] || entity.values[3] < kSketchMinimumSize ||
        entity.values[3] > kSketchCoordinateLimit || !IsFinite(entity.values[4])) {
      return "has invalid polygon dimensions or coordinates";
    }
    return {};
  case SketchSolverEntityKind::Slot:
    for (const double value : entity.values) {
      if (!IsFinite(value))
        return "has a value that is not finite";
    }
    if (!coordinateInRange(entity.values[0]) || !coordinateInRange(entity.values[1]) ||
        !coordinateInRange(entity.values[2]) || !coordinateInRange(entity.values[3]) ||
        entity.values[4] < kSketchMinimumSize || entity.values[4] > kSketchCoordinateLimit ||
        std::hypot(entity.values[2] - entity.values[0], entity.values[3] - entity.values[1]) <
            kSketchMinimumSize) {
      return "has invalid slot dimensions or coordinates";
    }
    return {};
  }
  return "has an unknown geometry kind";
}

std::vector<std::string> ConstraintIdsForEntity(const SketchSolverSystem& system,
                                                const std::string& eid) {
  std::vector<std::string> names;
  for (const SketchSolverConstraint& constraint : system.constraints) {
    if (std::any_of(constraint.anchors.begin(), constraint.anchors.end(),
                    [&](const SketchSolverAnchor& anchor) { return anchor.eid == eid; })) {
      names.push_back(constraint.cid);
    }
  }
  return names;
}

void CanonicalizeZeros(std::vector<SketchSolverEntity>& entities) {
  for (SketchSolverEntity& entity : entities) {
    for (double& value : entity.values) {
      // JSON has only one zero spelling in the persisted project container.
      // Never let a solver-produced -0 cross the native seam and become a
      // different f64 bit pattern when that project is reopened.
      if (value == 0.0) {
        value = 0.0;
      }
    }
  }
}

} // namespace

std::size_t SketchEntityParameterCount(SketchSolverEntityKind kind) {
  switch (kind) {
  case SketchSolverEntityKind::Point:
    return 2; // x, y
  case SketchSolverEntityKind::Line:
    return 4; // x1, y1, x2, y2
  case SketchSolverEntityKind::Polyline:
  case SketchSolverEntityKind::Spline:
    // The authored vector carries the actual count; SolveSketch validates it
    // against the entity-specific payload before constructing the system.
    return 0;
  case SketchSolverEntityKind::Rectangle:
    return 5;
  case SketchSolverEntityKind::Circle:
    return 3; // cx, cy, r
  case SketchSolverEntityKind::Arc:
    return 5; // cx, cy, r, startAngle, endAngle
  case SketchSolverEntityKind::ArcThreePoint:
    return 6;
  case SketchSolverEntityKind::Ellipse:
    return 5;
  case SketchSolverEntityKind::Polygon:
    return 5;
  case SketchSolverEntityKind::Slot:
    return 5;
  }
  return 0;
}

SketchSolverResult SolveSketch(const SketchSolverSystem& system) {
  // ---- Validation, before any numeric work. A malformed system is a fact
  // about the input, and reporting it as a solver failure would send a person
  // looking for a geometry problem that is really a typo.
  std::unordered_map<std::string, EntityLayout> layoutByEid;
  std::vector<EntityLayout> layouts;
  layouts.reserve(system.entities.size());

  std::size_t paramCount = 0;
  for (std::size_t i = 0; i < system.entities.size(); ++i) {
    const SketchSolverEntity& entity = system.entities[i];
    const std::size_t expected = entity.kind == SketchSolverEntityKind::Polyline ||
                                         entity.kind == SketchSolverEntityKind::Spline
                                     ? entity.values.size()
                                     : SketchEntityParameterCount(entity.kind);
    if ((entity.kind == SketchSolverEntityKind::Polyline && expected < 4) ||
        (entity.kind == SketchSolverEntityKind::Spline && expected < 6) ||
        (entity.kind == SketchSolverEntityKind::Polyline ||
         entity.kind == SketchSolverEntityKind::Spline) &&
            expected % 2 != 0) {
      return Invalid("Entity " + entity.eid + " has an invalid control-point vector.");
    }
    if (entity.values.size() != expected) {
      return Invalid("Entity " + entity.eid + " carries " + std::to_string(entity.values.size()) +
                     " values but its kind needs " + std::to_string(expected) + ".");
    }
    for (const double value : entity.values) {
      if (!IsFinite(value)) {
        return Invalid("Entity " + entity.eid + " has a value that is not a finite number.");
      }
    }
    const std::string geometryError = EntityGeometryError(entity);
    if (!geometryError.empty()) {
      return Invalid("Entity " + entity.eid + " " + geometryError + ".");
    }
    if (layoutByEid.count(entity.eid) != 0) {
      return Invalid("Entity id " + entity.eid + " appears more than once.");
    }
    EntityLayout layout;
    layout.entityIndex = i;
    layout.firstParam = paramCount;
    layout.kind = entity.kind;
    layouts.push_back(layout);
    layoutByEid.emplace(entity.eid, layout);
    paramCount += PlaneGcsParameterCount(entity);
  }

  for (const SketchSolverGround& ground : system.grounded) {
    const auto found = layoutByEid.find(ground.eid);
    if (found == layoutByEid.end()) {
      return Invalid("Cannot ground " + ground.eid + ": no such entity in this sketch.");
    }
    found->second.grounded = true;
    layouts[found->second.entityIndex].grounded = true;
  }

  // `fix`/`ground` are persisted constraints in the public sketch system. They
  // have the same geometric meaning as the legacy grounded list, but keeping
  // them as constraints means an edit/replay round-trip does not lose the
  // user's intent. Apply them before declaring PlaneGCS unknowns.
  for (const SketchSolverConstraint& constraint : system.constraints) {
    if (constraint.kind != SketchSolverConstraintKind::Fixed)
      continue;
    if (constraint.anchors.size() != 1) {
      return Invalid("Constraint " + constraint.cid + " needs one entity to fix.");
    }
    const auto found = layoutByEid.find(constraint.anchors[0].eid);
    if (found == layoutByEid.end()) {
      return Invalid("Constraint " + constraint.cid + " refers to " + constraint.anchors[0].eid +
                     ", which is not in this sketch.");
    }
    found->second.grounded = true;
    layouts[found->second.entityIndex].grounded = true;
  }

  // ---- Parameter storage. Stable for the whole solve: PlaneGCS stores raw
  // pointers into this vector, so it must not reallocate after this point.
  std::vector<double> params;
  params.reserve(paramCount);
  for (const SketchSolverEntity& entity : system.entities) {
    if (entity.kind != SketchSolverEntityKind::Arc) {
      params.insert(params.end(), entity.values.begin(), entity.values.end());
      continue;
    }

    const double centerX = entity.values[0];
    const double centerY = entity.values[1];
    const double radius = entity.values[2];
    const double startAngle = DegreesToRadians(entity.values[3]);
    const double endAngle = DegreesToRadians(entity.values[4]);
    params.push_back(centerX);
    params.push_back(centerY);
    params.push_back(radius);
    params.push_back(centerX + radius * std::cos(startAngle));
    params.push_back(centerY + radius * std::sin(startAngle));
    params.push_back(centerX + radius * std::cos(endAngle));
    params.push_back(centerY + radius * std::sin(endAngle));
    params.push_back(startAngle);
    params.push_back(endAngle);
  }

  // ---- Geometry. Built in input order so the parameter vector handed to
  // PlaneGCS is a deterministic function of the input.
  std::vector<GCS::Point> points(system.entities.size());
  std::vector<GCS::Line> lines(system.entities.size());
  std::vector<GCS::Circle> circles(system.entities.size());
  std::vector<GCS::Arc> arcs(system.entities.size());
  std::vector<std::vector<GCS::Point>> entityPoints(system.entities.size());

  GCS::System gcs;
  int nextTag = kFirstTag;
  std::unordered_map<int, std::string> cidByTag;

  for (std::size_t i = 0; i < system.entities.size(); ++i) {
    double* base = params.data() + layouts[i].firstParam;
    switch (system.entities[i].kind) {
    case SketchSolverEntityKind::Point:
      points[i] = GCS::Point(base, base + 1);
      break;
    case SketchSolverEntityKind::Line:
      lines[i].p1 = GCS::Point(base, base + 1);
      lines[i].p2 = GCS::Point(base + 2, base + 3);
      break;
    case SketchSolverEntityKind::Polyline:
    case SketchSolverEntityKind::Spline:
      for (std::size_t pointIndex = 0; pointIndex * 2 < system.entities[i].values.size();
           ++pointIndex) {
        entityPoints[i].emplace_back(base + pointIndex * 2, base + pointIndex * 2 + 1);
      }
      break;
    case SketchSolverEntityKind::Rectangle:
      entityPoints[i].emplace_back(base, base + 1);
      break;
    case SketchSolverEntityKind::Circle:
      circles[i].center = GCS::Point(base, base + 1);
      circles[i].rad = base + 2;
      break;
    case SketchSolverEntityKind::Arc:
      arcs[i].center = GCS::Point(base, base + 1);
      arcs[i].rad = base + 2;
      arcs[i].start = GCS::Point(base + 3, base + 4);
      arcs[i].end = GCS::Point(base + 5, base + 6);
      arcs[i].startAngle = base + 7;
      arcs[i].endAngle = base + 8;
      break;
    case SketchSolverEntityKind::ArcThreePoint:
      entityPoints[i].emplace_back(base, base + 1);
      entityPoints[i].emplace_back(base + 2, base + 3);
      entityPoints[i].emplace_back(base + 4, base + 5);
      break;
    case SketchSolverEntityKind::Ellipse:
    case SketchSolverEntityKind::Polygon:
      entityPoints[i].emplace_back(base, base + 1);
      break;
    case SketchSolverEntityKind::Slot:
      entityPoints[i].emplace_back(base, base + 1);
      entityPoints[i].emplace_back(base + 2, base + 3);
      break;
    }
  }

  // ---- Constraints. Anchors are resolved BEFORE any are added, so a bad
  // anchor cannot leave a half-built system behind.
  auto resolvePoint = [&](const SketchSolverAnchor& anchor, GCS::Point** out) -> std::string {
    const auto found = layoutByEid.find(anchor.eid);
    if (found == layoutByEid.end()) {
      return "constraint refers to " + anchor.eid + ", which is not in this sketch";
    }
    const std::size_t index = found->second.entityIndex;
    switch (found->second.kind) {
    case SketchSolverEntityKind::Point:
      if (anchor.position != SketchSolverAnchorPosition::Point) {
        return "a point exposes only its point anchor";
      }
      *out = &points[index];
      return {};
    case SketchSolverEntityKind::Line:
      if (anchor.position == SketchSolverAnchorPosition::Start) {
        *out = &lines[index].p1;
        return {};
      }
      if (anchor.position == SketchSolverAnchorPosition::End) {
        *out = &lines[index].p2;
        return {};
      }
      return "a line exposes only start and end anchors";
    case SketchSolverEntityKind::Circle:
      if (anchor.position != SketchSolverAnchorPosition::Center) {
        return "a circle exposes only its center anchor";
      }
      *out = &circles[index].center;
      return {};
    case SketchSolverEntityKind::Arc:
      if (anchor.position == SketchSolverAnchorPosition::Center) {
        *out = &arcs[index].center;
        return {};
      }
      if (anchor.position == SketchSolverAnchorPosition::Start) {
        *out = &arcs[index].start;
        return {};
      }
      if (anchor.position == SketchSolverAnchorPosition::End) {
        *out = &arcs[index].end;
        return {};
      }
      return "an arc exposes only start, end, and center anchors";
    case SketchSolverEntityKind::Polyline:
    case SketchSolverEntityKind::Spline: {
      if (entityPoints[index].empty())
        return "the curve has no points";
      std::size_t pointIndex = 0;
      if (anchor.position == SketchSolverAnchorPosition::End) {
        pointIndex = entityPoints[index].size() - 1;
      } else if (anchor.position == SketchSolverAnchorPosition::Mid) {
        pointIndex = entityPoints[index].size() / 2;
      } else if (anchor.position != SketchSolverAnchorPosition::Start) {
        return "the curve exposes start, end, and mid anchors";
      }
      *out = &entityPoints[index][pointIndex];
      return {};
    }
    case SketchSolverEntityKind::Rectangle:
    case SketchSolverEntityKind::Ellipse:
    case SketchSolverEntityKind::Polygon:
      if (anchor.position != SketchSolverAnchorPosition::Center) {
        return "the shape exposes only its center anchor";
      }
      *out = &entityPoints[index][0];
      return {};
    case SketchSolverEntityKind::ArcThreePoint:
      if (anchor.position == SketchSolverAnchorPosition::Start) {
        *out = &entityPoints[index][0];
        return {};
      }
      if (anchor.position == SketchSolverAnchorPosition::Mid) {
        *out = &entityPoints[index][1];
        return {};
      }
      if (anchor.position == SketchSolverAnchorPosition::End) {
        *out = &entityPoints[index][2];
        return {};
      }
      return "a three-point arc exposes start, mid, and end anchors";
    case SketchSolverEntityKind::Slot:
      if (anchor.position == SketchSolverAnchorPosition::Start) {
        *out = &entityPoints[index][0];
        return {};
      }
      if (anchor.position == SketchSolverAnchorPosition::End) {
        *out = &entityPoints[index][1];
        return {};
      }
      return "a slot exposes start and end anchors";
    }
    return "unknown entity kind";
  };

  // Driving values live here because PlaneGCS takes `double*` for them and
  // they must outlive the solve.
  std::vector<double> drivingValues;
  drivingValues.reserve(system.constraints.size());
  for (const SketchSolverConstraint& constraint : system.constraints) {
    drivingValues.push_back(constraint.value);
  }

  std::unordered_map<std::string, AxisConstraintIds> axisConstraintsByEid;
  for (std::size_t i = 0; i < system.constraints.size(); ++i) {
    const SketchSolverConstraint& constraint = system.constraints[i];
    const int tag = nextTag++;
    cidByTag.emplace(tag, constraint.cid);

    const std::size_t needed = (constraint.kind == SketchSolverConstraintKind::Radius ||
                                constraint.kind == SketchSolverConstraintKind::Diameter ||
                                constraint.kind == SketchSolverConstraintKind::Fixed)
                                   ? 1
                               : constraint.kind == SketchSolverConstraintKind::Symmetry ? 3
                                                                                         : 2;
    if (constraint.anchors.size() != needed) {
      return Invalid("Constraint " + constraint.cid + " needs " + std::to_string(needed) +
                     " reference(s) but has " + std::to_string(constraint.anchors.size()) + ".");
    }

    if (constraint.kind == SketchSolverConstraintKind::Fixed) {
      continue;
    }

    if (constraint.kind == SketchSolverConstraintKind::Radius ||
        constraint.kind == SketchSolverConstraintKind::Diameter) {
      const auto found = layoutByEid.find(constraint.anchors[0].eid);
      if (found == layoutByEid.end()) {
        return Invalid("Constraint " + constraint.cid + " refers to " + constraint.anchors[0].eid +
                       ", which is not in this sketch.");
      }
      if (!IsFinite(constraint.value) || constraint.value < kSketchMinimumSize ||
          constraint.value > kSketchCoordinateLimit) {
        return Invalid("Constraint " + constraint.cid +
                       " needs a radius inside the supported sketch range.");
      }
      const std::size_t index = found->second.entityIndex;
      if (found->second.kind == SketchSolverEntityKind::Circle) {
        if (constraint.anchors[0].position != SketchSolverAnchorPosition::Center) {
          return Invalid("Constraint " + constraint.cid +
                         " must refer to the circle's center anchor.");
        }
        if (constraint.kind == SketchSolverConstraintKind::Radius) {
          gcs.addConstraintCircleRadius(circles[index], &drivingValues[i], tag, constraint.driving);
        } else {
          gcs.addConstraintCircleDiameter(circles[index], &drivingValues[i], tag,
                                          constraint.driving);
        }
      } else if (found->second.kind == SketchSolverEntityKind::Arc) {
        if (constraint.anchors[0].position != SketchSolverAnchorPosition::Center) {
          return Invalid("Constraint " + constraint.cid +
                         " must refer to the arc's center anchor.");
        }
        if (constraint.kind == SketchSolverConstraintKind::Radius) {
          gcs.addConstraintArcRadius(arcs[index], &drivingValues[i], tag, constraint.driving);
        } else {
          gcs.addConstraintArcDiameter(arcs[index], &drivingValues[i], tag, constraint.driving);
        }
      } else {
        return Invalid("Constraint " + constraint.cid +
                       " sets a radius or diameter on something that has none.");
      }
      continue;
    }

    // A direction constraint binds two LINES, not two points, so it resolves
    // entities rather than anchors and never reaches `resolvePoint` below.
    // PlaneGCS's ConstraintParallel/Perpendicular copy the parameter pointers
    // out of the Line at construction, so passing our long-lived `lines[]`
    // entries is what keeps the constraint valid for the whole solve.
    if (constraint.kind == SketchSolverConstraintKind::Parallel ||
        constraint.kind == SketchSolverConstraintKind::Perpendicular) {
      const bool parallel = constraint.kind == SketchSolverConstraintKind::Parallel;
      const std::string word = parallel ? "parallel" : "perpendicular";
      if (constraint.anchors[0].eid == constraint.anchors[1].eid) {
        return Invalid(
            "Constraint " + constraint.cid + " names the same line twice; a line " +
            (parallel ? "is always parallel to itself." : "cannot be perpendicular to itself."));
      }
      std::size_t index[2] = {0, 0};
      for (int side = 0; side < 2; ++side) {
        const auto found = layoutByEid.find(constraint.anchors[side].eid);
        if (found == layoutByEid.end()) {
          return Invalid("Constraint " + constraint.cid + " refers to " +
                         constraint.anchors[side].eid + ", which is not in this sketch.");
        }
        if (found->second.kind != SketchSolverEntityKind::Line) {
          return Invalid("Constraint " + constraint.cid + " makes something " + word +
                         " that has no direction. Only a line does.");
        }
        index[side] = found->second.entityIndex;
      }
      if (parallel) {
        gcs.addConstraintParallel(lines[index[0]], lines[index[1]], tag);
      } else {
        gcs.addConstraintPerpendicular(lines[index[0]], lines[index[1]], tag);
      }
      continue;
    }

    if (constraint.kind == SketchSolverConstraintKind::Midpoint ||
        constraint.kind == SketchSolverConstraintKind::Collinear) {
      std::size_t index[2] = {0, 0};
      for (int side = 0; side < 2; ++side) {
        const auto found = layoutByEid.find(constraint.anchors[side].eid);
        if (found == layoutByEid.end()) {
          return Invalid("Constraint " + constraint.cid + " refers to " +
                         constraint.anchors[side].eid + ", which is not in this sketch.");
        }
        if (found->second.kind != SketchSolverEntityKind::Line) {
          return Invalid("Constraint " + constraint.cid + " applies only to line entities.");
        }
        index[side] = found->second.entityIndex;
      }
      if (index[0] == index[1]) {
        return Invalid("Constraint " + constraint.cid + " names the same line twice.");
      }
      if (constraint.kind == SketchSolverConstraintKind::Midpoint) {
        gcs.addConstraintMidpointOnLine(lines[index[0]], lines[index[1]], tag, constraint.driving);
      } else {
        gcs.addConstraintPointOnLine(lines[index[0]].p1, lines[index[1]], tag, constraint.driving);
        gcs.addConstraintPointOnLine(lines[index[0]].p2, lines[index[1]], tag, constraint.driving);
      }
      continue;
    }

    if (constraint.kind == SketchSolverConstraintKind::Tangent ||
        constraint.kind == SketchSolverConstraintKind::Equal ||
        constraint.kind == SketchSolverConstraintKind::Concentric ||
        constraint.kind == SketchSolverConstraintKind::Angle ||
        constraint.kind == SketchSolverConstraintKind::Symmetry) {
      auto entityIndexFor = [&](const SketchSolverAnchor& anchor,
                                std::size_t& index) -> std::string {
        const auto found = layoutByEid.find(anchor.eid);
        if (found == layoutByEid.end()) {
          return "refers to " + anchor.eid + ", which is not in this sketch";
        }
        index = found->second.entityIndex;
        return {};
      };

      if (constraint.kind == SketchSolverConstraintKind::Symmetry) {
        GCS::Point* first = nullptr;
        GCS::Point* second = nullptr;
        const std::string firstError = resolvePoint(constraint.anchors[0], &first);
        const std::string secondError = resolvePoint(constraint.anchors[1], &second);
        if (!firstError.empty() || !secondError.empty()) {
          return Invalid("Constraint " + constraint.cid + ": " +
                         (!firstError.empty() ? firstError : secondError) + ".");
        }
        std::size_t axisIndex = 0;
        const std::string axisError = entityIndexFor(constraint.anchors[2], axisIndex);
        if (!axisError.empty())
          return Invalid("Constraint " + constraint.cid + ": " + axisError + ".");
        if (system.entities[axisIndex].kind != SketchSolverEntityKind::Line) {
          return Invalid("Constraint " + constraint.cid + " uses a non-line symmetry axis.");
        }
        gcs.addConstraintP2PSymmetric(*first, *second, lines[axisIndex], tag, constraint.driving);
        continue;
      }

      std::size_t firstIndex = 0;
      std::size_t secondIndex = 0;
      const std::string firstError = entityIndexFor(constraint.anchors[0], firstIndex);
      const std::string secondError = entityIndexFor(constraint.anchors[1], secondIndex);
      if (!firstError.empty() || !secondError.empty()) {
        return Invalid("Constraint " + constraint.cid + ": " +
                       (!firstError.empty() ? firstError : secondError) + ".");
      }
      if (firstIndex == secondIndex) {
        return Invalid("Constraint " + constraint.cid + " names the same shape twice.");
      }
      const auto firstKind = system.entities[firstIndex].kind;
      const auto secondKind = system.entities[secondIndex].kind;

      if (constraint.kind == SketchSolverConstraintKind::Concentric) {
        const auto centerPoint = [&](std::size_t index, GCS::Point*& point) -> std::string {
          const SketchSolverEntityKind kind = system.entities[index].kind;
          if (kind != SketchSolverEntityKind::Circle && kind != SketchSolverEntityKind::Arc &&
              kind != SketchSolverEntityKind::Ellipse) {
            return "concentric applies only to circles, arcs, and ellipses";
          }
          SketchSolverAnchor anchor{system.entities[index].eid, SketchSolverAnchorPosition::Center};
          return resolvePoint(anchor, &point);
        };
        GCS::Point* first = nullptr;
        GCS::Point* second = nullptr;
        const std::string firstCenterError = centerPoint(firstIndex, first);
        const std::string secondCenterError = centerPoint(secondIndex, second);
        if (!firstCenterError.empty() || !secondCenterError.empty()) {
          return Invalid("Constraint " + constraint.cid + ": " +
                         (!firstCenterError.empty() ? firstCenterError : secondCenterError) + ".");
        }
        gcs.addConstraintP2PCoincident(*first, *second, tag, constraint.driving);
        continue;
      }

      if (constraint.kind == SketchSolverConstraintKind::Angle) {
        if (firstKind != SketchSolverEntityKind::Line ||
            secondKind != SketchSolverEntityKind::Line) {
          return Invalid("Constraint " + constraint.cid + " needs two lines for an angle.");
        }
        if (!IsFinite(constraint.value) || constraint.value < -360.0 || constraint.value > 360.0) {
          return Invalid("Constraint " + constraint.cid +
                         " needs an angle between -360 and 360 degrees.");
        }
        drivingValues[i] = DegreesToRadians(constraint.value);
        gcs.addConstraintL2LAngle(lines[firstIndex], lines[secondIndex], &drivingValues[i], tag,
                                  constraint.driving);
        continue;
      }

      if (constraint.kind == SketchSolverConstraintKind::Equal) {
        if (firstKind == SketchSolverEntityKind::Line &&
            secondKind == SketchSolverEntityKind::Line) {
          gcs.addConstraintEqualLength(lines[firstIndex], lines[secondIndex], tag,
                                       constraint.driving);
          continue;
        }
        if (firstKind == SketchSolverEntityKind::Circle &&
            secondKind == SketchSolverEntityKind::Circle) {
          gcs.addConstraintEqualRadius(circles[firstIndex], circles[secondIndex], tag,
                                       constraint.driving);
          continue;
        }
        if (firstKind == SketchSolverEntityKind::Circle &&
            secondKind == SketchSolverEntityKind::Arc) {
          gcs.addConstraintEqualRadius(circles[firstIndex], arcs[secondIndex], tag,
                                       constraint.driving);
          continue;
        }
        if (firstKind == SketchSolverEntityKind::Arc &&
            secondKind == SketchSolverEntityKind::Circle) {
          gcs.addConstraintEqualRadius(circles[secondIndex], arcs[firstIndex], tag,
                                       constraint.driving);
          continue;
        }
        if (firstKind == SketchSolverEntityKind::Arc && secondKind == SketchSolverEntityKind::Arc) {
          gcs.addConstraintEqualRadius(arcs[firstIndex], arcs[secondIndex], tag,
                                       constraint.driving);
          continue;
        }
        return Invalid("Constraint " + constraint.cid + " cannot make those shapes equal.");
      }

      if (constraint.kind == SketchSolverConstraintKind::Tangent) {
        if (firstKind == SketchSolverEntityKind::Line &&
            secondKind == SketchSolverEntityKind::Circle) {
          gcs.addConstraintTangent(lines[firstIndex], circles[secondIndex], true, tag,
                                   constraint.driving);
          continue;
        }
        if (firstKind == SketchSolverEntityKind::Line &&
            secondKind == SketchSolverEntityKind::Arc) {
          gcs.addConstraintTangent(lines[firstIndex], arcs[secondIndex], true, tag,
                                   constraint.driving);
          continue;
        }
        if (firstKind == SketchSolverEntityKind::Line &&
            secondKind == SketchSolverEntityKind::Ellipse) {
          return Invalid("Constraint " + constraint.cid +
                         " cannot lower a line/ellipse tangent in this engine.");
        }
        if (firstKind == SketchSolverEntityKind::Circle &&
            secondKind == SketchSolverEntityKind::Circle) {
          gcs.addConstraintTangent(circles[firstIndex], circles[secondIndex], tag,
                                   constraint.driving);
          continue;
        }
        if (firstKind == SketchSolverEntityKind::Arc && secondKind == SketchSolverEntityKind::Arc) {
          gcs.addConstraintTangent(arcs[firstIndex], arcs[secondIndex], tag, constraint.driving);
          continue;
        }
        if (firstKind == SketchSolverEntityKind::Circle &&
            secondKind == SketchSolverEntityKind::Arc) {
          gcs.addConstraintTangent(circles[firstIndex], arcs[secondIndex], tag, constraint.driving);
          continue;
        }
        if (firstKind == SketchSolverEntityKind::Arc &&
            secondKind == SketchSolverEntityKind::Circle) {
          gcs.addConstraintTangent(circles[secondIndex], arcs[firstIndex], tag, constraint.driving);
          continue;
        }
        return Invalid("Constraint " + constraint.cid +
                       " cannot lower a tangent for those shapes.");
      }
    }

    GCS::Point* a = nullptr;
    GCS::Point* b = nullptr;
    const std::string firstError = resolvePoint(constraint.anchors[0], &a);
    if (!firstError.empty()) {
      return Invalid("Constraint " + constraint.cid + ": " + firstError + ".");
    }
    const std::string secondError = resolvePoint(constraint.anchors[1], &b);
    if (!secondError.empty()) {
      return Invalid("Constraint " + constraint.cid + ": " + secondError + ".");
    }

    if (constraint.kind == SketchSolverConstraintKind::Coincident &&
        constraint.anchors[0].eid == constraint.anchors[1].eid) {
      const SketchSolverAnchorPosition first = constraint.anchors[0].position;
      const SketchSolverAnchorPosition second = constraint.anchors[1].position;
      const bool joinsOwnEndpoints =
          (first == SketchSolverAnchorPosition::Start &&
           second == SketchSolverAnchorPosition::End) ||
          (first == SketchSolverAnchorPosition::End && second == SketchSolverAnchorPosition::Start);
      const EntityLayout& entity = layoutByEid.at(constraint.anchors[0].eid);
      if (joinsOwnEndpoints && (entity.kind == SketchSolverEntityKind::Line ||
                                entity.kind == SketchSolverEntityKind::Arc)) {
        return Conflict({constraint.cid}, 0);
      }
    }

    if ((constraint.kind == SketchSolverConstraintKind::Horizontal ||
         constraint.kind == SketchSolverConstraintKind::Vertical) &&
        constraint.anchors[0].eid == constraint.anchors[1].eid) {
      const SketchSolverAnchorPosition first = constraint.anchors[0].position;
      const SketchSolverAnchorPosition second = constraint.anchors[1].position;
      const bool namesBothLineEndpoints =
          (first == SketchSolverAnchorPosition::Start &&
           second == SketchSolverAnchorPosition::End) ||
          (first == SketchSolverAnchorPosition::End && second == SketchSolverAnchorPosition::Start);
      const auto entity = layoutByEid.find(constraint.anchors[0].eid);
      if (namesBothLineEndpoints && entity != layoutByEid.end() &&
          entity->second.kind == SketchSolverEntityKind::Line) {
        AxisConstraintIds& ids = axisConstraintsByEid[constraint.anchors[0].eid];
        if (constraint.kind == SketchSolverConstraintKind::Horizontal) {
          ids.horizontal.push_back(constraint.cid);
        } else {
          ids.vertical.push_back(constraint.cid);
        }
      }
    }

    switch (constraint.kind) {
    case SketchSolverConstraintKind::Coincident:
      gcs.addConstraintP2PCoincident(*a, *b, tag, constraint.driving);
      break;
    case SketchSolverConstraintKind::Horizontal:
      gcs.addConstraintHorizontal(*a, *b, tag, constraint.driving);
      break;
    case SketchSolverConstraintKind::Vertical:
      gcs.addConstraintVertical(*a, *b, tag, constraint.driving);
      break;
    case SketchSolverConstraintKind::Distance:
      if (!IsFinite(constraint.value) || constraint.value < kSketchMinimumSize ||
          constraint.value > kSketchCoordinateLimit) {
        return Invalid("Constraint " + constraint.cid +
                       " needs a distance inside the supported sketch range.");
      }
      gcs.addConstraintP2PDistance(*a, *b, &drivingValues[i], tag, constraint.driving);
      break;
    case SketchSolverConstraintKind::HorizontalDistance:
      if (!IsFinite(constraint.value) || std::abs(constraint.value) > kSketchCoordinateLimit) {
        return Invalid("Constraint " + constraint.cid +
                       " needs a horizontal distance inside the supported sketch range.");
      }
      gcs.addConstraintDifference(a->x, b->x, &drivingValues[i], tag, constraint.driving);
      break;
    case SketchSolverConstraintKind::VerticalDistance:
      if (!IsFinite(constraint.value) || std::abs(constraint.value) > kSketchCoordinateLimit) {
        return Invalid("Constraint " + constraint.cid +
                       " needs a vertical distance inside the supported sketch range.");
      }
      gcs.addConstraintDifference(a->y, b->y, &drivingValues[i], tag, constraint.driving);
      break;
    case SketchSolverConstraintKind::Length:
      if (!IsFinite(constraint.value) || constraint.value < kSketchMinimumSize ||
          constraint.value > kSketchCoordinateLimit) {
        return Invalid("Constraint " + constraint.cid +
                       " needs a length inside the supported sketch range.");
      }
      gcs.addConstraintP2PDistance(*a, *b, &drivingValues[i], tag, constraint.driving);
      break;
    case SketchSolverConstraintKind::Radius:
    case SketchSolverConstraintKind::Diameter:
    case SketchSolverConstraintKind::Midpoint:
    case SketchSolverConstraintKind::Collinear:
    case SketchSolverConstraintKind::Fixed:
    case SketchSolverConstraintKind::Parallel:
    case SketchSolverConstraintKind::Perpendicular:
    case SketchSolverConstraintKind::Tangent:
    case SketchSolverConstraintKind::Equal:
    case SketchSolverConstraintKind::Concentric:
    case SketchSolverConstraintKind::Symmetry:
    case SketchSolverConstraintKind::Angle:
      break; // handled above
    }
  }

  // A schema-valid line is non-degenerate. Making the same line horizontal and
  // vertical has only a zero-length "solution", so it is a structural conflict
  // even though an unconstrained numeric solver could collapse both endpoints
  // together. Diagnose this before PlaneGCS and name BOTH user constraints.
  std::vector<std::string> mutuallyExclusiveAxes;
  for (const auto& [eid, ids] : axisConstraintsByEid) {
    (void)eid;
    if (!ids.horizontal.empty() && !ids.vertical.empty()) {
      mutuallyExclusiveAxes.insert(mutuallyExclusiveAxes.end(), ids.horizontal.begin(),
                                   ids.horizontal.end());
      mutuallyExclusiveAxes.insert(mutuallyExclusiveAxes.end(), ids.vertical.begin(),
                                   ids.vertical.end());
    }
  }
  if (!mutuallyExclusiveAxes.empty()) {
    return Conflict(std::move(mutuallyExclusiveAxes), 0);
  }

  // An ungrounded arc's start/end points are derived from
  // centre+radius+angles by PlaneGCS's own rule constraint; without it the arc
  // is under-determined in a way that has nothing to do with the user's
  // constraints. A grounded arc already has all nine internal values pinned
  // and initialized consistently, so adding its fixed rule equations would
  // subtract rank from somebody else's unknowns and can report a negative DoF.
  for (std::size_t i = 0; i < system.entities.size(); ++i) {
    if (system.entities[i].kind == SketchSolverEntityKind::Arc && !layouts[i].grounded) {
      gcs.addConstraintArcRules(arcs[i]);
    }
  }

  // ---- Unknowns. A GROUNDED entity's parameters are simply not declared, so
  // the solver cannot move them. This is why grounding is in the contract:
  // GOV-004 measured a width dimension translating the whole sketch when
  // nothing was pinned.
  std::vector<double*> unknowns;
  unknowns.reserve(paramCount);
  for (std::size_t i = 0; i < system.entities.size(); ++i) {
    if (layouts[i].grounded) {
      continue;
    }
    const std::size_t count = PlaneGcsParameterCount(system.entities[i]);
    for (std::size_t k = 0; k < count; ++k) {
      unknowns.push_back(params.data() + layouts[i].firstParam + k);
    }
  }

  SketchSolverResult result;
  if (unknowns.empty()) {
    // PlaneGCS intentionally skips diagnosis when it has no unknowns. Check
    // every shipped constraint against the fixed geometry ourselves; otherwise
    // a contradictory grounded sketch would be echoed as falsely converged.
    const auto lineData = [&](const std::string& eid, double& x1, double& y1, double& x2,
                              double& y2) -> bool {
      const auto found = layoutByEid.find(eid);
      if (found == layoutByEid.end() || found->second.kind != SketchSolverEntityKind::Line) {
        return false;
      }
      const std::size_t first = found->second.firstParam;
      x1 = params[first];
      y1 = params[first + 1];
      x2 = params[first + 2];
      y2 = params[first + 3];
      return true;
    };
    const auto circleData = [&](const std::string& eid, double& cx, double& cy,
                                double& radius) -> bool {
      const auto found = layoutByEid.find(eid);
      if (found == layoutByEid.end() || (found->second.kind != SketchSolverEntityKind::Circle &&
                                         found->second.kind != SketchSolverEntityKind::Arc)) {
        return false;
      }
      const std::size_t first = found->second.firstParam;
      cx = params[first];
      cy = params[first + 1];
      radius = params[first + 2];
      return true;
    };
    const auto fixedPoint = [&](const SketchSolverAnchor& anchor, double& x, double& y) -> bool {
      GCS::Point* point = nullptr;
      if (!resolvePoint(anchor, &point).empty())
        return false;
      x = *point->x;
      y = *point->y;
      return true;
    };
    const auto pointOnLine = [&](double px, double py, double x1, double y1, double x2,
                                 double y2) -> bool {
      const double dx = x2 - x1;
      const double dy = y2 - y1;
      const double length = std::hypot(dx, dy);
      if (length <= kFixedConstraintTolerance)
        return false;
      return std::abs((px - x1) * dy - (py - y1) * dx) / length <= kFixedConstraintTolerance;
    };
    const auto normalizedAngle = [](double angle) { return std::remainder(angle, 2.0 * kPi); };
    const auto relationSatisfied = [&](const SketchSolverConstraint& constraint) -> bool {
      if (constraint.kind == SketchSolverConstraintKind::Fixed)
        return true;

      if (constraint.kind == SketchSolverConstraintKind::Radius ||
          constraint.kind == SketchSolverConstraintKind::Diameter) {
        double cx = 0.0;
        double cy = 0.0;
        double radius = 0.0;
        if (!circleData(constraint.anchors[0].eid, cx, cy, radius))
          return false;
        const double expected = constraint.kind == SketchSolverConstraintKind::Diameter
                                    ? constraint.value / 2.0
                                    : constraint.value;
        return std::abs(radius - expected) <= kFixedConstraintTolerance;
      }

      if (constraint.kind == SketchSolverConstraintKind::Parallel ||
          constraint.kind == SketchSolverConstraintKind::Perpendicular ||
          constraint.kind == SketchSolverConstraintKind::Angle ||
          constraint.kind == SketchSolverConstraintKind::Equal ||
          constraint.kind == SketchSolverConstraintKind::Tangent ||
          constraint.kind == SketchSolverConstraintKind::Concentric) {
        const std::string& firstEid = constraint.anchors[0].eid;
        const std::string& secondEid = constraint.anchors[1].eid;
        double ax1 = 0.0;
        double ay1 = 0.0;
        double ax2 = 0.0;
        double ay2 = 0.0;
        double bx1 = 0.0;
        double by1 = 0.0;
        double bx2 = 0.0;
        double by2 = 0.0;
        double acx = 0.0;
        double acy = 0.0;
        double ar = 0.0;
        double bcx = 0.0;
        double bcy = 0.0;
        double br = 0.0;
        const bool firstLine = lineData(firstEid, ax1, ay1, ax2, ay2);
        const bool secondLine = lineData(secondEid, bx1, by1, bx2, by2);
        const bool firstCircle = circleData(firstEid, acx, acy, ar);
        const bool secondCircle = circleData(secondEid, bcx, bcy, br);
        if (constraint.kind == SketchSolverConstraintKind::Parallel ||
            constraint.kind == SketchSolverConstraintKind::Perpendicular ||
            constraint.kind == SketchSolverConstraintKind::Angle) {
          if (!firstLine || !secondLine)
            return false;
          const double ax = ax2 - ax1;
          const double ay = ay2 - ay1;
          const double bx = bx2 - bx1;
          const double by = by2 - by1;
          const double lengthA = std::hypot(ax, ay);
          const double lengthB = std::hypot(bx, by);
          if (lengthA <= kFixedConstraintTolerance || lengthB <= kFixedConstraintTolerance) {
            return false;
          }
          if (constraint.kind == SketchSolverConstraintKind::Parallel) {
            return std::abs(ax * by - ay * bx) / (lengthA * lengthB) <= kFixedConstraintTolerance;
          }
          if (constraint.kind == SketchSolverConstraintKind::Perpendicular) {
            return std::abs(ax * bx + ay * by) / (lengthA * lengthB) <= kFixedConstraintTolerance;
          }
          const double actual = normalizedAngle(std::atan2(by, bx) - std::atan2(ay, ax));
          const double expected = normalizedAngle(DegreesToRadians(constraint.value));
          return std::abs(normalizedAngle(actual - expected)) <= kFixedConstraintTolerance;
        }
        if (constraint.kind == SketchSolverConstraintKind::Equal) {
          if (firstLine && secondLine) {
            return std::abs(std::hypot(ax2 - ax1, ay2 - ay1) - std::hypot(bx2 - bx1, by2 - by1)) <=
                   kFixedConstraintTolerance;
          }
          return firstCircle && secondCircle && std::abs(ar - br) <= kFixedConstraintTolerance;
        }
        if (constraint.kind == SketchSolverConstraintKind::Concentric) {
          if (!firstCircle || !secondCircle)
            return false;
          return std::hypot(acx - bcx, acy - bcy) <= kFixedConstraintTolerance;
        }
        if (firstLine && secondCircle) {
          return std::abs(std::abs((bcx - ax1) * (ay2 - ay1) - (bcy - ay1) * (ax2 - ax1)) /
                              std::hypot(ax2 - ax1, ay2 - ay1) -
                          br) <= kFixedConstraintTolerance;
        }
        if (secondLine && firstCircle) {
          return std::abs(std::abs((acx - bx1) * (by2 - by1) - (acy - by1) * (bx2 - bx1)) /
                              std::hypot(bx2 - bx1, by2 - by1) -
                          ar) <= kFixedConstraintTolerance;
        }
        if (firstCircle && secondCircle) {
          const double centers = std::hypot(acx - bcx, acy - bcy);
          return std::abs(centers - (ar + br)) <= kFixedConstraintTolerance ||
                 std::abs(centers - std::abs(ar - br)) <= kFixedConstraintTolerance;
        }
        return false;
      }

      if (constraint.kind == SketchSolverConstraintKind::Symmetry) {
        double ax = 0.0;
        double ay = 0.0;
        double bx = 0.0;
        double by = 0.0;
        double x1 = 0.0;
        double y1 = 0.0;
        double x2 = 0.0;
        double y2 = 0.0;
        if (!fixedPoint(constraint.anchors[0], ax, ay) ||
            !fixedPoint(constraint.anchors[1], bx, by) ||
            !lineData(constraint.anchors[2].eid, x1, y1, x2, y2)) {
          return false;
        }
        const double dx = x2 - x1;
        const double dy = y2 - y1;
        const double lengthSquared = dx * dx + dy * dy;
        if (lengthSquared <= kFixedConstraintTolerance)
          return false;
        const double t = ((ax - x1) * dx + (ay - y1) * dy) / lengthSquared;
        const double rx = 2.0 * (x1 + t * dx) - ax;
        const double ry = 2.0 * (y1 + t * dy) - ay;
        return std::hypot(rx - bx, ry - by) <= kFixedConstraintTolerance;
      }

      double ax = 0.0;
      double ay = 0.0;
      double bx = 0.0;
      double by = 0.0;
      if (!fixedPoint(constraint.anchors[0], ax, ay) ||
          !fixedPoint(constraint.anchors[1], bx, by)) {
        return false;
      }
      const double dx = bx - ax;
      const double dy = by - ay;
      switch (constraint.kind) {
      case SketchSolverConstraintKind::Coincident:
        return std::hypot(dx, dy) <= kFixedConstraintTolerance;
      case SketchSolverConstraintKind::Horizontal:
        return std::abs(dy) <= kFixedConstraintTolerance;
      case SketchSolverConstraintKind::Vertical:
        return std::abs(dx) <= kFixedConstraintTolerance;
      case SketchSolverConstraintKind::Distance:
      case SketchSolverConstraintKind::Length:
        return std::abs(std::hypot(dx, dy) - constraint.value) <= kFixedConstraintTolerance;
      case SketchSolverConstraintKind::HorizontalDistance:
        return std::abs(dx - constraint.value) <= kFixedConstraintTolerance;
      case SketchSolverConstraintKind::VerticalDistance:
        return std::abs(dy - constraint.value) <= kFixedConstraintTolerance;
      case SketchSolverConstraintKind::Midpoint: {
        double ax1 = 0.0;
        double ay1 = 0.0;
        double ax2 = 0.0;
        double ay2 = 0.0;
        double bx1 = 0.0;
        double by1 = 0.0;
        double bx2 = 0.0;
        double by2 = 0.0;
        return lineData(constraint.anchors[0].eid, ax1, ay1, ax2, ay2) &&
               lineData(constraint.anchors[1].eid, bx1, by1, bx2, by2) &&
               pointOnLine((ax1 + ax2) / 2.0, (ay1 + ay2) / 2.0, bx1, by1, bx2, by2);
      }
      case SketchSolverConstraintKind::Collinear: {
        double ax1 = 0.0;
        double ay1 = 0.0;
        double ax2 = 0.0;
        double ay2 = 0.0;
        double bx1 = 0.0;
        double by1 = 0.0;
        double bx2 = 0.0;
        double by2 = 0.0;
        return lineData(constraint.anchors[0].eid, ax1, ay1, ax2, ay2) &&
               lineData(constraint.anchors[1].eid, bx1, by1, bx2, by2) &&
               pointOnLine(ax1, ay1, bx1, by1, bx2, by2) &&
               pointOnLine(ax2, ay2, bx1, by1, bx2, by2);
      }
      case SketchSolverConstraintKind::Fixed:
      case SketchSolverConstraintKind::Radius:
      case SketchSolverConstraintKind::Diameter:
      case SketchSolverConstraintKind::Parallel:
      case SketchSolverConstraintKind::Perpendicular:
      case SketchSolverConstraintKind::Tangent:
      case SketchSolverConstraintKind::Equal:
      case SketchSolverConstraintKind::Concentric:
      case SketchSolverConstraintKind::Symmetry:
      case SketchSolverConstraintKind::Angle:
        return false;
      }
      return false;
    };

    std::vector<std::string> unsatisfied;
    for (const SketchSolverConstraint& constraint : system.constraints) {
      if (!relationSatisfied(constraint))
        unsatisfied.push_back(constraint.cid);
    }
    if (!unsatisfied.empty()) {
      return Conflict(std::move(unsatisfied), 0);
    }

    std::vector<std::string> redundant;
    for (std::size_t index = 0; index < system.constraints.size(); ++index) {
      for (std::size_t prior = 0; prior < index; ++prior) {
        if (SameConstraintDefinition(system.constraints[index], system.constraints[prior])) {
          redundant.push_back(system.constraints[index].cid);
          break;
        }
      }
    }
    if (!redundant.empty()) {
      std::sort(redundant.begin(), redundant.end());
      result.status = SketchSolverStatus::Redundant;
      result.entities = system.entities;
      CanonicalizeZeros(result.entities);
      result.redundant = std::move(redundant);
      result.degreesOfFreedom = 0;
      result.message =
          "This sketch is solved, but some constraints repeat what others already say.";
      return result;
    }

    // Everything is pinned and consistent. That is a legal fully-constrained
    // sketch; the answer preserves its coordinates with seam-canonical zeros.
    result.status = SketchSolverStatus::Converged;
    result.entities = system.entities;
    CanonicalizeZeros(result.entities);
    result.degreesOfFreedom = 0;
    result.message = "Every shape in this sketch is fixed.";
    return result;
  }

  gcs.declareUnknowns(unknowns);
  gcs.initSolution();
  gcs.diagnose();

  const bool conflicting = gcs.hasConflicting();
  const bool redundant = gcs.hasRedundant();
  std::vector<int> conflictingTags;
  std::vector<int> redundantTags;
  gcs.getConflicting(conflictingTags);
  gcs.getRedundant(redundantTags);

  auto namesFor = [&](const std::vector<int>& tags) {
    std::vector<std::string> names;
    for (const int tag : tags) {
      const auto found = cidByTag.find(tag);
      if (found != cidByTag.end()) {
        names.push_back(found->second);
      }
    }
    std::sort(names.begin(), names.end());
    names.erase(std::unique(names.begin(), names.end()), names.end());
    return names;
  };

  if (conflicting) {
    return Conflict(namesFor(conflictingTags), std::max(0, gcs.dofsNumber()));
  }

  const int status = gcs.solve();
  gcs.applySolution();

  result.degreesOfFreedom = std::max(0, gcs.dofsNumber());
  if (status != GCS::Success && status != GCS::Converged) {
    result.status = SketchSolverStatus::DidNotConverge;
    result.message = "This sketch could not be solved to a stable shape.";
    return result;
  }

  // Read the solved values back in the SAME order they were written.
  result.entities = system.entities;
  for (std::size_t i = 0; i < system.entities.size(); ++i) {
    const std::size_t first = layouts[i].firstParam;
    if (system.entities[i].kind == SketchSolverEntityKind::Arc) {
      result.entities[i].values[0] = params[first];
      result.entities[i].values[1] = params[first + 1];
      result.entities[i].values[2] = params[first + 2];
      result.entities[i].values[3] = RadiansToDegrees(params[first + 7]);
      result.entities[i].values[4] = RadiansToDegrees(params[first + 8]);
      continue;
    }
    const std::size_t count = PlaneGcsParameterCount(system.entities[i]);
    for (std::size_t k = 0; k < count; ++k) {
      result.entities[i].values[k] = params[first + k];
    }
  }
  CanonicalizeZeros(result.entities);

  for (const SketchSolverEntity& entity : result.entities) {
    const std::string geometryError = EntityGeometryError(entity);
    if (geometryError.empty()) {
      continue;
    }
    std::vector<std::string> causes = ConstraintIdsForEntity(system, entity.eid);
    if (!causes.empty()) {
      return Conflict(std::move(causes), result.degreesOfFreedom);
    }
    result.status = SketchSolverStatus::DidNotConverge;
    result.entities.clear();
    result.message =
        "The solver produced invalid geometry for " + entity.eid + ": it " + geometryError + ".";
    return result;
  }

  if (redundant) {
    result.status = SketchSolverStatus::Redundant;
    result.redundant = namesFor(redundantTags);
    result.message = "This sketch is solved, but some constraints repeat what others "
                     "already say.";
    return result;
  }

  result.status = SketchSolverStatus::Converged;
  result.message = result.degreesOfFreedom == 0
                       ? "This sketch is fully constrained."
                       : "This sketch is solved, with " + std::to_string(result.degreesOfFreedom) +
                             " degree(s) of freedom still open.";
  return result;
}

} // namespace aeth
