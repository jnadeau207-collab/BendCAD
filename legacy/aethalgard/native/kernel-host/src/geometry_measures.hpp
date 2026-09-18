#pragma once

#include <array>
#include <optional>
#include <string>

#include <BRepAdaptor_Surface.hxx>
#include <TopAbs_Orientation.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shape.hxx>
#include <gp_Dir.hxx>
#include <gp_Pnt2d.hxx>

namespace aeth {

using Axis = std::optional<std::array<double, 3>>;

std::string Orientation(TopAbs_Orientation orientation);

std::string SurfaceClass(const TopoDS_Face& face);

std::string CurveClass(const TopoDS_Edge& edge);

std::array<double, 3> AsArray(const gp_Dir& direction);

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
Axis Canonicalize(const gp_Dir& direction);

/// Outward-directed unit normal for a planar face: the plane's geometric
/// normal, negated when the face is REVERSED relative to that surface, so it
/// points OUT of the solid's material. Deliberately NOT sign-canonicalized
/// (unlike Canonicalize above): a box's +Z and -Z faces must emit OPPOSITE
/// axes so AQL's axisAgrees (dot >= 1 - 1e-6) rejects an opposite-facing
/// survivor as a candidate. That directedness is the entire point of the
/// face gate. A re-trimmed but preserved face keeps its material side, so
/// its outward normal is unchanged and it stays a candidate for its own
/// anchor; only genuinely opposite/rotated faces are excluded.
Axis PlanarOutwardNormal(const TopoDS_Face& face, const BRepAdaptor_Surface& surface);

Axis SurfaceAxis(const TopoDS_Face& face);

Axis CurveAxis(const TopoDS_Edge& edge);

/// Radius of a cylindrical face. Throws std::invalid_argument if the face's
/// surface type is not GeomAbs_Cylinder.
double CylindricalFaceRadius(const TopoDS_Face& face);

/// Reference radius of a conical face (the radius at the cone's origin
/// parameter, per OCCT's gp_Cone::RefRadius). Throws std::invalid_argument
/// if the face's surface type is not GeomAbs_Cone.
double ConicalFaceReferenceRadius(const TopoDS_Face& face);

/// Radius of a circular edge. Throws std::invalid_argument if the edge's
/// curve type is not GeomAbs_Circle.
double CircleEdgeRadius(const TopoDS_Edge& edge);

/// `CylindricalFaceRadius`/`ConicalFaceReferenceRadius`, dispatched by
/// surface type; `std::nullopt` for every other surface (mirrors
/// `SurfaceAxis`'s dispatch shape so the topology harvest and the query
/// path's ResolvedEntity projection can share one radius definition instead
/// of two independently-typed ones drifting apart, the way the harvest and
/// query axis conventions once did).
std::optional<double> SurfaceRadius(const TopoDS_Face& face);

/// `CircleEdgeRadius`, dispatched by curve type; `std::nullopt` for every
/// other curve. See `SurfaceRadius`.
std::optional<double> CurveRadius(const TopoDS_Edge& edge);

/// General outward unit normal at a (u,v) parameter point on any face
/// surface type (not just planar — cylindrical fillet faces need this too).
/// Throws std::runtime_error if the surface normal is not defined at that
/// point.
gp_Dir OutwardNormalAtPoint(const TopoDS_Face& face, const gp_Pnt2d& uv);

/// Dihedral classification of an edge shared by two faces of a body.
enum class DihedralClass { Convex, Concave, Smooth, Mixed, NotApplicable };

/// Raw per-sample dihedral angle range (degrees) for an edge, computed once
/// so both a fixed convex/concave test and a variable-tolerance smooth test
/// can be derived cheaply without recomputing the OCCT surface evaluations.
/// `applicable` is false for seam edges, open-shell boundary edges, or
/// degenerate edges (no 3D curve) — the caller must treat those as
/// DihedralClass::NotApplicable regardless of theta values.
struct DihedralRange {
  bool applicable = false;
  double minTheta = 0.0;
  double maxTheta = 0.0;
};

/// Computes the dihedral angle range across the 3 sample parameters (0.25,
/// 0.5, 0.75) along `edge`, which must be a genuine edge of `owningBody`. See
/// plan 05 §5.3 for the full algorithm and sign convention.
DihedralRange ComputeDihedralRange(const TopoDS_Shape& owningBody, const TopoDS_Edge& edge);

/// Classifies a dihedral angle range into convex/concave/smooth/mixed per
/// plan 05 §5.3: convex iff theta < -1 degrees on some sample and no sample
/// is concave; concave iff theta > 1 degrees on some sample and no sample is
/// convex; mixed if both convex and concave samples are present (mixed
/// always wins over smooth); otherwise smooth iff every sample falls within
/// +/- smoothToleranceDegrees. `range.applicable == false` always yields
/// NotApplicable.
DihedralClass ClassifyFromRange(const DihedralRange& range, double smoothToleranceDegrees = 1.0);

/// Convenience wrapper: computes the dihedral range for `edge` within
/// `owningBody` and classifies it at `smoothToleranceDegrees` in one call.
DihedralClass ClassifyDihedral(const TopoDS_Shape& owningBody, const TopoDS_Edge& edge,
                               double smoothToleranceDegrees = 1.0);

} // namespace aeth
