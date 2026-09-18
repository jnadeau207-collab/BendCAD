#include "hole_entry.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

#include <BRepBndLib.hxx>
#include <BRepClass3d_SolidClassifier.hxx>
#include <BRep_Tool.hxx>
#include <Bnd_Box.hxx>
#include <IntCurvesFace_ShapeIntersector.hxx>
#include <Precision.hxx>
#include <TopAbs_State.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Face.hxx>
#include <gp_Dir.hxx>
#include <gp_Lin.hxx>
#include <gp_Pnt.hxx>
#include <gp_Vec.hxx>

namespace aeth {

void ClassifyHoleEntry(const TopoDS_Shape& target, const gp_Ax2& frame) {
  const gp_Pnt entry = frame.Location();
  const gp_Dir drill(frame.Direction());
  const gp_Vec drillVec(drill);
  const gp_Lin axis(entry, drill);

  // Crossing-search tolerance for the ray/surface intersector: generous enough
  // to find every boundary crossing (including one on a loose imported/healed
  // face), floored at OCCT confusion. This ONLY governs which crossings the
  // intersector reports; it is NEVER the ON-acceptance band. That band is scoped
  // to the specific entry face below, so a loose face ELSEWHERE on the body can
  // never widen the tolerance at the drilling entry point.
  double searchTolerance = Precision::Confusion();
  for (TopExp_Explorer faceIt(target, TopAbs_FACE); faceIt.More(); faceIt.Next()) {
    searchTolerance =
        std::max(searchTolerance, BRep_Tool::Tolerance(TopoDS::Face(faceIt.Current())));
  }

  // Bound the axis search to the body's extent. Using the bounding-box diagonal
  // only as a finite search RANGE (never as a tolerance) is scale-safe: every
  // crossing of a point on the body lies within it.
  Bnd_Box axisBox;
  BRepBndLib::AddOptimal(target, axisBox, true, false);
  double axmin;
  double aymin;
  double azmin;
  double axmax;
  double aymax;
  double azmax;
  axisBox.Get(axmin, aymin, azmin, axmax, aymax, azmax);
  const double reach = gp_Vec(axmax - axmin, aymax - aymin, azmax - azmin).Magnitude() * 2.0 + 1.0;

  // Cast the drilling axis through the target and collect its boundary
  // crossings. WParameter(i) is the signed distance from the entry along the
  // (unit) drilling direction: positive is ahead (into the drill), negative is
  // behind it.
  IntCurvesFace_ShapeIntersector intersector;
  intersector.Load(target, searchTolerance);
  intersector.Perform(axis, -reach, reach);
  if (!intersector.IsDone() || intersector.NbPnt() == 0) {
    throw std::invalid_argument(
        "hole origin must lie on the target body's surface: the drilling axis does not cross "
        "the target body");
  }

  // The entry crossing is the boundary crossing nearest the origin along the
  // axis; the ON-acceptance band is the tolerance of THAT face alone, floored at
  // OCCT confusion — never the widest face anywhere on the body. A loose face
  // elsewhere (e.g. on a healed or imported solid) therefore cannot admit an
  // origin measurably off the actual entry surface.
  int entryIndex = 1;
  double nearestCrossing = std::abs(intersector.WParameter(1));
  for (int i = 2; i <= intersector.NbPnt(); ++i) {
    const double distance = std::abs(intersector.WParameter(i));
    if (distance < nearestCrossing) {
      nearestCrossing = distance;
      entryIndex = i;
    }
  }
  const double entryTolerance =
      std::max(Precision::Confusion(), BRep_Tool::Tolerance(intersector.Face(entryIndex)));

  // The origin IS the entry point: the nearest crossing must coincide with it,
  // within the LOCAL entry face's tolerance.
  if (nearestCrossing > entryTolerance) {
    throw std::invalid_argument(
        "hole origin must lie on the target body's surface: the placement origin is the "
        "drilling entry point, not a point above or inside the body");
  }

  // Nearest crossing strictly ahead of / behind the entry, measured against the
  // same local entry tolerance so the entry crossing itself is excluded.
  double aheadDistance = 0.0;
  double behindDistance = 0.0;
  for (int i = 1; i <= intersector.NbPnt(); ++i) {
    const double w = intersector.WParameter(i);
    if (w > entryTolerance && (aheadDistance == 0.0 || w < aheadDistance))
      aheadDistance = w;
    if (w < -entryTolerance && (behindDistance == 0.0 || -w < behindDistance))
      behindDistance = -w;
  }
  // Material must lie ahead along the drilling axis (a crossing bounds the solid
  // interval the drill enters). No ahead crossing ⇒ drilling out of the body.
  if (aheadDistance == 0.0) {
    throw std::invalid_argument(
        "hole drilling direction must point into the target from the entry point: material "
        "must lie ahead along the drilling axis and empty space behind it");
  }

  BRepClass3d_SolidClassifier classifier(target);
  // Probe the MIDPOINT of the first interval ahead of the entry: an unambiguous
  // point sized to the LOCAL wall, so it can never overshoot a thin plate. It
  // must be inside the material.
  classifier.Perform(entry.Translated((aheadDistance * 0.5) * drillVec), entryTolerance);
  const bool materialAhead = classifier.State() == TopAbs_IN;
  // Probe just behind the entry. If a crossing sits behind, the midpoint to it
  // is the interval immediately behind the entry face; otherwise step back by
  // half the local wall thickness (a length local to this feature, never the
  // global diagonal). It must be empty space.
  const double behindStep = behindDistance > 0.0 ? behindDistance * 0.5 : aheadDistance * 0.5;
  classifier.Perform(entry.Translated((-behindStep) * drillVec), entryTolerance);
  const bool voidBehind = classifier.State() == TopAbs_OUT;
  if (!materialAhead || !voidBehind) {
    throw std::invalid_argument(
        "hole drilling direction must point into the target from the entry point: material "
        "must lie ahead along the drilling axis and empty space behind it");
  }
}

} // namespace aeth
