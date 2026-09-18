#include "geometry_measures.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>

#include <BRepAdaptor_Curve.hxx>
#include <BRepAdaptor_Surface.hxx>
#include <BRep_Tool.hxx>
#include <Geom2d_Curve.hxx>
#include <GeomLProp_CLProps.hxx>
#include <GeomLProp_SLProps.hxx>
#include <Geom_Curve.hxx>
#include <Geom_Surface.hxx>
#include <NCollection_IndexedDataMap.hxx>
#include <NCollection_List.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <gp_Circ.hxx>
#include <gp_Cone.hxx>
#include <gp_Cylinder.hxx>
#include <gp_Pnt.hxx>
#include <gp_Vec.hxx>

namespace aeth {

std::string Orientation(const TopAbs_Orientation orientation) {
  switch (orientation) {
  case TopAbs_FORWARD:
    return "forward";
  case TopAbs_REVERSED:
    return "reversed";
  case TopAbs_INTERNAL:
    return "internal";
  case TopAbs_EXTERNAL:
    return "external";
  }
  throw std::runtime_error("OCCT returned an unknown topology orientation");
}

std::string SurfaceClass(const TopoDS_Face& face) {
  switch (BRepAdaptor_Surface(face, true).GetType()) {
  case GeomAbs_Plane:
    return "plane";
  case GeomAbs_Cylinder:
    return "cylinder";
  case GeomAbs_Cone:
    return "cone";
  case GeomAbs_Sphere:
    return "sphere";
  case GeomAbs_Torus:
    return "torus";
  case GeomAbs_BezierSurface:
    return "bezier-surface";
  case GeomAbs_BSplineSurface:
    return "bspline-surface";
  default:
    return "other";
  }
}

std::string CurveClass(const TopoDS_Edge& edge) {
  if (BRep_Tool::Degenerated(edge))
    return "other";
  switch (BRepAdaptor_Curve(edge).GetType()) {
  case GeomAbs_Line:
    return "line";
  case GeomAbs_Circle:
    return "circle";
  case GeomAbs_Ellipse:
    return "ellipse";
  case GeomAbs_BezierCurve:
    return "bezier-curve";
  case GeomAbs_BSplineCurve:
    return "bspline-curve";
  default:
    return "other";
  }
}

std::array<double, 3> AsArray(const gp_Dir& direction) {
  return {direction.X(), direction.Y(), direction.Z()};
}

/// AQL's structural candidate filter (tools/reference-tournament/src/
/// resolvers/aql.ts) treats {kind, geometryClass, orientation, provenance}
/// as the full candidate key, so an X-axis and a Y-axis entity were
/// indistinguishable and a merge could positionally misreference across
/// axes. The emitted axis closes that gap. See PlanarOutwardNormal for the
/// directed-face case; this helper produces the UNDIRECTED variant.
///
/// Undirected canonical axis, used for cylinder/cone axes of revolution and
/// for all edge directions/axes, where a directed "outward" has no meaning:
/// sign-flip so the first component whose absolute value exceeds 1e-9 is
/// positive. This keeps forward/reversed TopoDS orientation from flipping
/// the reported sign of the same physical curve/axis.
///
/// KNOWN RESIDUAL (documented honestly, do not paper over): because this is
/// an undirected LINE, two entities on the same axis line emit the same
/// value — a box's opposite parallel EDGES, or two distinct edges parallel
/// to a shared direction, stay interchangeable by axis alone. The axis gate
/// therefore does NOT separate them; that residual needs position /
/// normalization work in the scorer, not an axis change (a directed edge
/// tangent would reintroduce exactly the forward/reversed flip this
/// canonicalization exists to remove). Planar FACES do not suffer this —
/// they carry a genuinely directed outward normal instead (PlanarOutward-
/// Normal below), so opposite faces are correctly distinguished.
Axis Canonicalize(const gp_Dir& direction) {
  double x = direction.X();
  double y = direction.Y();
  double z = direction.Z();
  const double components[3] = {x, y, z};
  for (const double component : components) {
    if (std::abs(component) > 1e-9) {
      if (component < 0.0) {
        x = -x;
        y = -y;
        z = -z;
      }
      break;
    }
  }
  return Axis{std::array<double, 3>{x, y, z}};
}

/// Outward-directed unit normal for a planar face: the plane's geometric
/// normal, negated when the face is REVERSED relative to that surface, so it
/// points OUT of the solid's material. Deliberately NOT sign-canonicalized
/// (unlike Canonicalize above): a box's +Z and -Z faces must emit OPPOSITE
/// axes so AQL's axisAgrees (dot >= 1 - 1e-6) rejects an opposite-facing
/// survivor as a candidate. That directedness is the entire point of the
/// face gate. A re-trimmed but preserved face keeps its material side, so
/// its outward normal is unchanged and it stays a candidate for its own
/// anchor; only genuinely opposite/rotated faces are excluded.
Axis PlanarOutwardNormal(const TopoDS_Face& face, const BRepAdaptor_Surface& surface) {
  gp_Dir normal = surface.Plane().Axis().Direction();
  if (face.Orientation() == TopAbs_REVERSED) {
    normal.Reverse();
  }
  return Axis{AsArray(normal)};
}

Axis SurfaceAxis(const TopoDS_Face& face) {
  const BRepAdaptor_Surface surface(face, true);
  switch (surface.GetType()) {
  case GeomAbs_Plane:
    return PlanarOutwardNormal(face, surface);
  case GeomAbs_Cylinder:
    return Canonicalize(surface.Cylinder().Axis().Direction());
  case GeomAbs_Cone:
    return Canonicalize(surface.Cone().Axis().Direction());
  default:
    return std::nullopt;
  }
}

Axis CurveAxis(const TopoDS_Edge& edge) {
  if (BRep_Tool::Degenerated(edge))
    return std::nullopt;
  const BRepAdaptor_Curve curve(edge);
  switch (curve.GetType()) {
  case GeomAbs_Line:
    return Canonicalize(curve.Line().Direction());
  case GeomAbs_Circle:
    return Canonicalize(curve.Circle().Axis().Direction());
  case GeomAbs_Ellipse:
    return Canonicalize(curve.Ellipse().Axis().Direction());
  default:
    return std::nullopt;
  }
}

double CylindricalFaceRadius(const TopoDS_Face& face) {
  const BRepAdaptor_Surface surface(face, true);
  if (surface.GetType() != GeomAbs_Cylinder) {
    throw std::invalid_argument("CylindricalFaceRadius requires a cylindrical face");
  }
  return surface.Cylinder().Radius();
}

double ConicalFaceReferenceRadius(const TopoDS_Face& face) {
  const BRepAdaptor_Surface surface(face, true);
  if (surface.GetType() != GeomAbs_Cone) {
    throw std::invalid_argument("ConicalFaceReferenceRadius requires a conical face");
  }
  return surface.Cone().RefRadius();
}

double CircleEdgeRadius(const TopoDS_Edge& edge) {
  const BRepAdaptor_Curve curve(edge);
  if (curve.GetType() != GeomAbs_Circle) {
    throw std::invalid_argument("CircleEdgeRadius requires a circular edge");
  }
  return curve.Circle().Radius();
}

std::optional<double> SurfaceRadius(const TopoDS_Face& face) {
  const BRepAdaptor_Surface surface(face, true);
  switch (surface.GetType()) {
  case GeomAbs_Cylinder:
    return CylindricalFaceRadius(face);
  case GeomAbs_Cone:
    return ConicalFaceReferenceRadius(face);
  default:
    return std::nullopt;
  }
}

std::optional<double> CurveRadius(const TopoDS_Edge& edge) {
  if (BRep_Tool::Degenerated(edge))
    return std::nullopt;
  const BRepAdaptor_Curve curve(edge);
  if (curve.GetType() != GeomAbs_Circle)
    return std::nullopt;
  return CircleEdgeRadius(edge);
}

gp_Dir OutwardNormalAtPoint(const TopoDS_Face& face, const gp_Pnt2d& uv) {
  Handle(Geom_Surface) surface = BRep_Tool::Surface(face);
  GeomLProp_SLProps props(surface, uv.X(), uv.Y(), 1, 1e-6);
  if (!props.IsNormalDefined()) {
    throw std::runtime_error("surface normal is not defined at the given parameter point");
  }
  gp_Dir normal = props.Normal();
  if (face.Orientation() == TopAbs_REVERSED) {
    normal.Reverse();
  }
  return normal;
}

namespace {

constexpr double kDihedralFixedThresholdDegrees = 1.0;
constexpr std::array<double, 3> kDihedralSampleFractions = {0.25, 0.5, 0.75};
// Avoid relying on the platform-conditional M_PI macro (not guaranteed by
// <cmath> under MSVC without _USE_MATH_DEFINES).
constexpr double kPi = 3.14159265358979323846;

} // namespace

DihedralRange ComputeDihedralRange(const TopoDS_Shape& owningBody, const TopoDS_Edge& edge) {
  NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>, TopTools_ShapeMapHasher>
      edgeToFaces;
  TopExp::MapShapesAndAncestors(owningBody, TopAbs_EDGE, TopAbs_FACE, edgeToFaces);

  const int edgeIndex = edgeToFaces.FindIndex(edge);
  if (edgeIndex == 0) {
    return DihedralRange{};
  }
  const NCollection_List<TopoDS_Shape>& incidentFaces = edgeToFaces.FindFromKey(edge);
  if (incidentFaces.Extent() != 2) {
    return DihedralRange{};
  }

  // F1 is fixed by the map's deterministic ancestor order (first element of
  // the list), never by iteration order elsewhere, so the classification is
  // reproducible across runs on the same document.
  const TopoDS_Face f1 = TopoDS::Face(incidentFaces.First());
  const TopoDS_Face f2 = TopoDS::Face(incidentFaces.Last());

  double curveFirst = 0.0;
  double curveLast = 0.0;
  Handle(Geom_Curve) curve3d = BRep_Tool::Curve(edge, curveFirst, curveLast);
  if (curve3d.IsNull()) {
    return DihedralRange{};
  }

  DihedralRange range;
  range.applicable = true;
  range.minTheta = std::numeric_limits<double>::infinity();
  range.maxTheta = -std::numeric_limits<double>::infinity();

  for (const double fraction : kDihedralSampleFractions) {
    const double param = curveFirst + fraction * (curveLast - curveFirst);

    GeomLProp_CLProps clprops(curve3d, param, 1, 1e-6);
    gp_Dir tangentRaw;
    clprops.Tangent(tangentRaw);

    TopAbs_Orientation orientationInF1 = TopAbs_FORWARD;
    bool foundInF1 = false;
    TopExp_Explorer explorer(f1, TopAbs_EDGE);
    for (; explorer.More(); explorer.Next()) {
      if (explorer.Current().IsSame(edge)) {
        orientationInF1 = explorer.Current().Orientation();
        foundInF1 = true;
        break;
      }
    }
    if (!foundInF1) {
      throw std::runtime_error(
          "edge not found on its own ancestor face F1 (topology inconsistency)");
    }

    gp_Vec t = tangentRaw;
    if (orientationInF1 == TopAbs_REVERSED) {
      t.Reverse();
    }

    double pf1 = 0.0;
    double pl1 = 0.0;
    Handle(Geom2d_Curve) pcurve1 = BRep_Tool::CurveOnSurface(edge, f1, pf1, pl1);
    const gp_Pnt2d uv1 = pcurve1->Value(param);
    const gp_Dir n1 = OutwardNormalAtPoint(f1, uv1);

    double pf2 = 0.0;
    double pl2 = 0.0;
    Handle(Geom2d_Curve) pcurve2 = BRep_Tool::CurveOnSurface(edge, f2, pf2, pl2);
    const gp_Pnt2d uv2 = pcurve2->Value(param);
    const gp_Dir n2 = OutwardNormalAtPoint(f2, uv2);

    const double thetaRadians = std::atan2(gp_Vec(n1.XYZ()).Crossed(gp_Vec(n2.XYZ())).Dot(t),
                                           gp_Vec(n1.XYZ()).Dot(gp_Vec(n2.XYZ())));
    // Sign calibration (empirical, pinned by the selector-evaluator regression):
    // the plan's raw formula and OCCT's outward-solid face/tangent orientation
    // yield the OPPOSITE label from the plan's stated semantics — a box's
    // external corners come out at +theta while §5.3 defines an external
    // (protruding) corner as CONVEX (theta < 0). Negating here makes the stored
    // range carry the plan's convention: a solid box's edges classify convex,
    // and a blind hole's pocket edges classify concave (both asserted in
    // selector_evaluator_test.cpp). The magnitude — hence the smooth band — is
    // unchanged.
    const double thetaDegrees = -thetaRadians * 180.0 / kPi;

    range.minTheta = std::min(range.minTheta, thetaDegrees);
    range.maxTheta = std::max(range.maxTheta, thetaDegrees);
  }

  return range;
}

DihedralClass ClassifyFromRange(const DihedralRange& range, const double smoothToleranceDegrees) {
  if (!range.applicable) {
    return DihedralClass::NotApplicable;
  }
  // Per spec, smoothToleranceDegrees only widens the smooth band beyond the
  // fixed +/-1 degree convex/concave boundary — it never narrows it. A
  // caller passing a tighter tolerance would create an unclassifiable gap
  // between the fixed boundary and its own band, so reject that misuse
  // explicitly instead of silently mislabeling samples in that gap.
  if (smoothToleranceDegrees < kDihedralFixedThresholdDegrees) {
    throw std::invalid_argument("smoothToleranceDegrees must be >= 1.0 (it widens the fixed "
                                "convex/concave boundary, never narrows it)");
  }
  const bool hasConvexSample = range.minTheta < -kDihedralFixedThresholdDegrees;
  const bool hasConcaveSample = range.maxTheta > kDihedralFixedThresholdDegrees;
  if (hasConvexSample && hasConcaveSample) {
    // Mixed-sign always wins over smooth, even if some samples individually
    // fall within tolerance.
    return DihedralClass::Mixed;
  }
  if (hasConvexSample) {
    return DihedralClass::Convex;
  }
  if (hasConcaveSample) {
    return DihedralClass::Concave;
  }
  // Neither convex nor concave fired, so every sample already lies within
  // the fixed +/-1 degree boundary; smoothToleranceDegrees >= 1 (checked
  // above) means the caller's widened band always contains that range too.
  return DihedralClass::Smooth;
}

DihedralClass ClassifyDihedral(const TopoDS_Shape& owningBody, const TopoDS_Edge& edge,
                               const double smoothToleranceDegrees) {
  const DihedralRange range = ComputeDihedralRange(owningBody, edge);
  return ClassifyFromRange(range, smoothToleranceDegrees);
}

} // namespace aeth
