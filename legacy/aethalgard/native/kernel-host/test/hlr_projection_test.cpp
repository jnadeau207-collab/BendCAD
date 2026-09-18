// The hidden-line seam, proven on geometry whose projections are knowable by
// hand: a 100x60x30 box and the same box with a through hole. What is pinned
// is drafting truth — which lines a view SHOWS, which it dashes, and the
// paper-axis bounds — not OCCT internals.
#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <string>

#include <BRepAlgoAPI_Cut.hxx>
#include <BRepBuilderAPI_Transform.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakeCylinder.hxx>
#include <gp_Ax2.hxx>
#include <gp_Dir.hxx>
#include <gp_Pnt.hxx>
#include <gp_Quaternion.hxx>
#include <gp_Trsf.hxx>
#include <gp_Vec.hxx>

#include "hlr_projection.hpp"

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
  std::printf("  %s %s (got %.6g, want %.6g)\n", ok ? "ok  " : "FAIL", label.c_str(), actual,
              expected);
  if (!ok) {
    g_failures += 1;
  }
}

std::size_t CountVisible(const aeth::HlrProjectionResult& result, bool visible) {
  return static_cast<std::size_t>(
      std::count_if(result.segments.begin(), result.segments.end(),
                    [visible](const aeth::HlrSegment& s) { return s.visible == visible; }));
}

void BoxFrontView() {
  std::printf("1. a plain box seen from the front is its outline rectangle:\n");
  const std::atomic_bool cancelled{false};
  const TopoDS_Shape box = BRepPrimAPI_MakeBox(100.0, 60.0, 30.0).Shape();

  // Front: eye along -Y, so width lands on paper X and height on paper Y.
  const aeth::HlrProjectionResult front =
      aeth::ProjectHiddenLine({box}, gp_Dir(0, -1, 0), gp_Dir(0, 0, 1), cancelled);

  Check(CountVisible(front, true) == 4, "exactly four visible edges");
  // The BACK face's edges are hidden exactly behind the front's — the data
  // reports them, and the renderer applies visible-over-hidden ink precedence.
  Check(CountVisible(front, false) == 4, "the back face's four edges are hidden behind them");
  CheckClose(front.maxX - front.minX, 100.0, 1e-6, "paper width is the box width");
  CheckClose(front.maxY - front.minY, 30.0, 1e-6, "paper height is the box height");
}

void BoxTopView() {
  std::printf("2. the top view swaps which faces bound the paper:\n");
  const std::atomic_bool cancelled{false};
  const TopoDS_Shape box = BRepPrimAPI_MakeBox(100.0, 60.0, 30.0).Shape();

  const aeth::HlrProjectionResult top =
      aeth::ProjectHiddenLine({box}, gp_Dir(0, 0, -1), gp_Dir(0, 1, 0), cancelled);

  Check(CountVisible(top, true) == 4, "exactly four visible edges");
  CheckClose(top.maxX - top.minX, 100.0, 1e-6, "paper width is the box width");
  CheckClose(top.maxY - top.minY, 60.0, 1e-6, "paper height is the box depth");
}

void HiddenHole() {
  std::printf("3. a through hole shows as hidden lines and a silhouette:\n");
  const std::atomic_bool cancelled{false};
  const TopoDS_Shape box = BRepPrimAPI_MakeBox(100.0, 60.0, 30.0).Shape();
  // A vertical through hole in the middle: invisible from the front except as
  // dashed lines, visible as a circle from the top.
  const TopoDS_Shape drill =
      BRepPrimAPI_MakeCylinder(gp_Ax2(gp_Pnt(50, 30, -5), gp_Dir(0, 0, 1)), 10.0, 40.0).Shape();
  const TopoDS_Shape holed = BRepAlgoAPI_Cut(box, drill).Shape();

  const aeth::HlrProjectionResult front =
      aeth::ProjectHiddenLine({holed}, gp_Dir(0, -1, 0), gp_Dir(0, 0, 1), cancelled);
  Check(CountVisible(front, false) >= 2, "the bore shows dashed from the front");
  Check(CountVisible(front, true) >= 4, "the outline stays visible");

  const aeth::HlrProjectionResult top =
      aeth::ProjectHiddenLine({holed}, gp_Dir(0, 0, -1), gp_Dir(0, 1, 0), cancelled);
  // The far rim of the bore hides exactly beneath the near one; coincident
  // hidden ink is a render-precedence question, so the data keeps it. Every
  // hidden point must still fall inside the visible outline.
  bool hiddenEscapes = false;
  for (const aeth::HlrSegment& segment : top.segments) {
    if (segment.visible)
      continue;
    for (std::size_t i = 0; i + 1 < segment.points.size(); i += 2) {
      if (segment.points[i] < top.minX - 1e-6 || segment.points[i] > top.maxX + 1e-6 ||
          segment.points[i + 1] < top.minY - 1e-6 || segment.points[i + 1] > top.maxY + 1e-6) {
        hiddenEscapes = true;
      }
    }
  }
  Check(!hiddenEscapes, "no hidden ink escapes the visible outline from the top");
  // The circle discretizes into at least one closed polyline with real points.
  bool foundCurve = false;
  for (const aeth::HlrSegment& segment : top.segments) {
    if (segment.visible && segment.points.size() > 8) {
      foundCurve = true;
    }
  }
  Check(foundCurve, "the bore rim appears as a sampled curve from the top");
}

void RefusalsAndFrames() {
  std::printf("4. refusals are typed and the frame is orthogonalized:\n");
  const std::atomic_bool cancelled{false};
  bool threwEmpty = false;
  try {
    aeth::ProjectHiddenLine({}, gp_Dir(0, -1, 0), gp_Dir(0, 0, 1), cancelled);
  } catch (const std::invalid_argument&) {
    threwEmpty = true;
  }
  Check(threwEmpty, "no bodies refuses with invalid_argument");

  const TopoDS_Shape box = BRepPrimAPI_MakeBox(10.0, 10.0, 10.0).Shape();
  bool threwParallel = false;
  try {
    aeth::ProjectHiddenLine({box}, gp_Dir(0, -1, 0), gp_Dir(0, 1, 0), cancelled);
  } catch (const std::invalid_argument&) {
    threwParallel = true;
  }
  Check(threwParallel, "an up parallel to the view direction refuses");

  // A tilted up still yields a frame: it is orthogonalized, not rejected.
  const aeth::HlrProjectionResult skew =
      aeth::ProjectHiddenLine({box}, gp_Dir(0, -1, 0), gp_Dir(0, -0.5, 0.866), cancelled);
  Check(CountVisible(skew, true) == 4, "an oblique up orthogonalizes into a working frame");
}

void SectionOutlines() {
  std::printf("5. a section cut exposes closed cut-face outlines:\n");
  const std::atomic_bool cancelled{false};
  const TopoDS_Shape box = BRepPrimAPI_MakeBox(100.0, 60.0, 30.0).Shape();
  // A bore along Y through the middle of the depth (axis at x=50, z=15,
  // radius 10, spanning y in [-5, 65]): the section plane at y = 30 pierces
  // it broadside, so the cut face is a rectangle with a circular island.
  const TopoDS_Shape drill =
      BRepPrimAPI_MakeCylinder(gp_Ax2(gp_Pnt(50, -5, 15), gp_Dir(0, 1, 0)), 10.0, 70.0).Shape();
  const TopoDS_Shape holed = BRepAlgoAPI_Cut(box, drill).Shape();

  // Section at the depth midline, removing the +Y half; the eye looks along
  // the normal (direction == normal) straight at the exposed cut.
  const aeth::HlrSectionPlane section{gp_Pnt(50, 30, 15), gp_Dir(0, 1, 0)};
  const aeth::HlrProjectionResult sectioned =
      aeth::ProjectHiddenLine({holed}, gp_Dir(0, 1, 0), gp_Dir(0, 0, 1), section, cancelled);

  // The rectangle-with-island cut face contributes its outer boundary and
  // the bore as separate loops.
  Check(sectioned.sectionOutlines.size() >= 2, "outer boundary and bore are their own loops");
  bool allEvenAndBounded = true;
  bool anyRepeatsFirstPoint = false;
  for (const std::vector<double>& loop : sectioned.sectionOutlines) {
    if (loop.size() % 2 != 0 || loop.size() < 6) {
      allEvenAndBounded = false;
      continue;
    }
    if (std::fabs(loop[loop.size() - 2] - loop[0]) < 1e-9 &&
        std::fabs(loop[loop.size() - 1] - loop[1]) < 1e-9) {
      anyRepeatsFirstPoint = true;
    }
  }
  Check(allEvenAndBounded, "every loop is x,y pairs with at least three corners");
  Check(!anyRepeatsFirstPoint, "no loop repeats its first point at the end");

  // View frame: direction +Y with up +Z gives viewY = +Z and viewX =
  // viewY x direction = (-1, 0, 0), so paper x = -world X and paper y =
  // world Z. The bore axis pierces the plane at world (x=50, z=15), so its
  // loop is a paper circle of radius 10 about (-50, 15) — and sampled
  // points sit ON the circle, so the radius holds to 1e-6.
  bool foundBoreLoop = false;
  bool foundOuterLoop = false;
  for (const std::vector<double>& loop : sectioned.sectionOutlines) {
    if (loop.size() < 6) {
      continue;
    }
    bool onCircle = true;
    double minX = loop[0], maxX = loop[0], minY = loop[1], maxY = loop[1];
    for (std::size_t i = 0; i + 1 < loop.size(); i += 2) {
      if (std::fabs(std::hypot(loop[i] + 50.0, loop[i + 1] - 15.0) - 10.0) > 1e-6) {
        onCircle = false;
      }
      minX = std::min(minX, loop[i]);
      maxX = std::max(maxX, loop[i]);
      minY = std::min(minY, loop[i + 1]);
      maxY = std::max(maxY, loop[i + 1]);
    }
    if (onCircle) {
      foundBoreLoop = true;
    }
    // The outer boundary spans the whole kept half: world x in [0, 100] and
    // z in [0, 30] map to paper [-100, 0] x [0, 30].
    if (std::fabs(minX + 100.0) < 1e-6 && std::fabs(maxX) < 1e-6 && std::fabs(minY) < 1e-6 &&
        std::fabs(maxY - 30.0) < 1e-6) {
      foundOuterLoop = true;
    }
  }
  Check(foundBoreLoop, "the bore island is a closed circle about (-50, 15)");
  Check(foundOuterLoop, "the outer boundary spans the kept half");

  // A plain box still sections: at least the one rectangular cut face.
  const aeth::HlrProjectionResult plain =
      aeth::ProjectHiddenLine({box}, gp_Dir(0, 1, 0), gp_Dir(0, 0, 1), section, cancelled);
  Check(!plain.sectionOutlines.empty(), "a plain box section carries at least one loop");
}

void SectionHalvesDepth() {
  std::printf("6. the section cut halves the projected depth:\n");
  const std::atomic_bool cancelled{false};
  const TopoDS_Shape box = BRepPrimAPI_MakeBox(100.0, 60.0, 30.0).Shape();
  const aeth::HlrSectionPlane section{gp_Pnt(50, 30, 15), gp_Dir(0, 1, 0)};

  // Top view of the sectioned box: the plane at y = 30 with normal +Y
  // removes y > 30, keeping [0, 30] of the 60 mm depth — paper height drops
  // 60 -> 30 while the width stays the full 100.
  const aeth::HlrProjectionResult top =
      aeth::ProjectHiddenLine({box}, gp_Dir(0, 0, -1), gp_Dir(0, 1, 0), section, cancelled);
  CheckClose(top.maxX - top.minX, 100.0, 1e-6, "paper width is still the box width");
  CheckClose(top.maxY - top.minY, 30.0, 1e-6, "paper depth is the kept half (60 / 2 = 30)");

  // Looking straight at the cut, the exposed face is the full 100 x 30
  // elevation — the section changes material, not this view's outline.
  const aeth::HlrProjectionResult front =
      aeth::ProjectHiddenLine({box}, gp_Dir(0, 1, 0), gp_Dir(0, 0, 1), section, cancelled);
  CheckClose(front.maxX - front.minX, 100.0, 1e-6, "cut view width is the box width");
  CheckClose(front.maxY - front.minY, 30.0, 1e-6, "cut view height is the box height");
}

void SectionFrameRules() {
  std::printf("7. a section plane along `up` follows the existing frame rules:\n");
  const std::atomic_bool cancelled{false};
  const TopoDS_Shape box = BRepPrimAPI_MakeBox(100.0, 60.0, 30.0).Shape();
  // A horizontal section (normal +Z, parallel to the conventional up) is
  // fine while direction and up still span a frame: it removes z > 15,
  // keeping [0, 15] of the 30 mm height, so a front view's height halves.
  const aeth::HlrSectionPlane horizontal{gp_Pnt(50, 30, 15), gp_Dir(0, 0, 1)};
  const aeth::HlrProjectionResult front =
      aeth::ProjectHiddenLine({box}, gp_Dir(0, -1, 0), gp_Dir(0, 0, 1), horizontal, cancelled);
  CheckClose(front.maxY - front.minY, 15.0, 1e-6, "paper height is the kept half (30 / 2 = 15)");
  CheckClose(front.maxX - front.minX, 100.0, 1e-6, "paper width stays the box width");

  // Looking along the section normal with up parallel to it is the SAME
  // refusal as ever — the pair spans no frame, section or no section.
  bool threwParallel = false;
  try {
    aeth::ProjectHiddenLine({box}, gp_Dir(0, 0, 1), gp_Dir(0, 0, 1), horizontal, cancelled);
  } catch (const std::invalid_argument&) {
    threwParallel = true;
  }
  Check(threwParallel, "up parallel to direction still refuses with a section");
}

/// The pose math the server applies to an assembly instance: rotation
/// quaternion x,y,z,w, then translation in millimetres.
TopoDS_Shape Posed(const TopoDS_Shape& shape, double qx, double qy, double qz, double qw, double tx,
                   double ty, double tz) {
  gp_Trsf placement;
  placement.SetRotation(gp_Quaternion(qx, qy, qz, qw));
  placement.SetTranslationPart(gp_Vec(tx, ty, tz));
  return BRepBuilderAPI_Transform(shape, placement, true).Shape();
}

void PosedInstances() {
  std::printf("8. posed instances union into one drawing:\n");
  const std::atomic_bool cancelled{false};
  const TopoDS_Shape unit = BRepPrimAPI_MakeBox(1.0, 1.0, 1.0).Shape();

  // Two unit boxes, one at the origin and one translated 200 mm along X:
  // together they span x in [0, 201], so the top view's paper width is 201.
  const aeth::HlrProjectionResult translated = aeth::ProjectHiddenLine(
      {Posed(unit, 0, 0, 0, 1, 0, 0, 0), Posed(unit, 0, 0, 0, 1, 200, 0, 0)}, gp_Dir(0, 0, -1),
      gp_Dir(0, 1, 0), cancelled);
  CheckClose(translated.maxX - translated.minX, 201.0, 1e-6,
             "translation-only instances span 200 mm plus one edge");
  CheckClose(translated.maxY - translated.minY, 1.0, 1e-6, "the footprint depth is one edge");

  // Rotating the far instance 90 degrees about Z (quaternion
  // (0, 0, sin 45, cos 45)) maps its corner (1, 0, 0) to (0, 1, 0), so the
  // box occupies x in [-1, 0] before translation and [199, 200] after —
  // the union spans exactly 200 now, not 201.
  const double half = std::sqrt(0.5);
  const aeth::HlrProjectionResult rotated = aeth::ProjectHiddenLine(
      {Posed(unit, 0, 0, 0, 1, 0, 0, 0), Posed(unit, 0, 0, half, half, 200, 0, 0)},
      gp_Dir(0, 0, -1), gp_Dir(0, 1, 0), cancelled);
  CheckClose(rotated.maxX - rotated.minX, 200.0, 1e-6,
             "a 90-degree turn pulls the far corner back to exactly 200");
  CheckClose(rotated.maxY - rotated.minY, 1.0, 1e-6, "the rotated footprint still spans one edge");
}

} // namespace

int main() {
  std::printf("hidden-line projection seam (drawings domain)\n");
  BoxFrontView();
  BoxTopView();
  HiddenHole();
  RefusalsAndFrames();
  SectionOutlines();
  SectionHalvesDepth();
  SectionFrameRules();
  PosedInstances();
  if (g_failures != 0) {
    std::printf("%d HLR PROJECTION CHECK(S) FAILED\n", g_failures);
    return 1;
  }
  std::printf("ALL HLR PROJECTION TESTS PASSED\n");
  return 0;
}
