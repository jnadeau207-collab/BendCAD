// Hidden-line projection: the seam between evaluated 3D bodies and the 2D
// line work a drawing view renders. OCCT's HLRBRep does the geometry; this
// header names what a drawing actually consumes — polyline segments in view
// coordinates, each one VISIBLE or HIDDEN — so the wire layer never touches
// an OCCT type.
//
// Classification follows drafting practice, not the algorithm's full
// taxonomy: sharp edges and outlines (silhouettes — the curved profile of a
// cylinder seen from the side) are drawn; smooth tangent-continuation edges
// are not, because on paper they are not lines. Hidden counterparts of the
// drawn classes come back dashed-ready under their own flag.
#pragma once

#include <atomic>
#include <optional>
#include <vector>

#include <TopoDS_Shape.hxx>
#include <gp_Dir.hxx>
#include <gp_Pnt.hxx>

namespace aeth {

/// One polyline in view coordinates (paper axes, model millimetres — the
/// view's SCALE is applied by the document layer, never here).
struct HlrSegment {
  bool visible = true;
  /// Flattened x0,y0,x1,y1,… — at least two points.
  std::vector<double> points;
};

/// A drafting section: before anything is projected, every body is cut by
/// the plane through `origin` with `normal`, and ALL material on the side
/// the normal points toward is removed. The caller chooses a `direction`
/// that looks at the exposed cut (typically direction == normal).
struct HlrSectionPlane {
  gp_Pnt origin;
  gp_Dir normal;
};

struct HlrProjectionResult {
  std::vector<HlrSegment> segments;
  /// Closed boundary loops of every cut face lying ON the requested section
  /// plane, in the same view coordinates as `segments`. Each loop is
  /// flattened x0,y0,… with the first point NOT repeated at the end; a cut
  /// face's outer boundary and each of its holes become their own loop.
  /// Populated only when a section plane was requested.
  std::vector<std::vector<double>> sectionOutlines;
  /// Bounds over every segment, in the same view coordinates.
  double minX = 0.0;
  double minY = 0.0;
  double maxX = 0.0;
  double maxY = 0.0;
};

/// Project `shapes` along `direction` (the eye looks OPPOSITE the direction's
/// sense, screen-style: "front" passes -Y to look at the front face) with
/// `up` becoming the view's +Y. Directions must be non-parallel; the
/// implementation orthogonalizes `up` against `direction`.
HlrProjectionResult ProjectHiddenLine(const std::vector<TopoDS_Shape>& shapes,
                                      const gp_Dir& direction, const gp_Dir& up,
                                      const std::atomic_bool& cancelled);

/// As above, with an optional section cut applied to every shape before the
/// hidden-line pass; `std::nullopt` behaves exactly like the plain overload.
HlrProjectionResult ProjectHiddenLine(const std::vector<TopoDS_Shape>& shapes,
                                      const gp_Dir& direction, const gp_Dir& up,
                                      const std::optional<HlrSectionPlane>& sectionPlane,
                                      const std::atomic_bool& cancelled);

} // namespace aeth
