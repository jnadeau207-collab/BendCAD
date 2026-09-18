#include "hlr_projection.hpp"

#include "cancel.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>

#include <BRepAdaptor_Curve.hxx>
#include <BRepAdaptor_Surface.hxx>
#include <BRepAlgoAPI_Cut.hxx>
#include <BRepBndLib.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepTools_WireExplorer.hxx>
#include <Bnd_Box.hxx>
#include <GCPnts_QuasiUniformDeflection.hxx>
#include <HLRAlgo_Projector.hxx>
#include <HLRBRep_Algo.hxx>
#include <HLRBRep_HLRToShape.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Wire.hxx>
#include <gp_Ax2.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <gp_Pnt2d.hxx>

namespace aeth {
namespace {

void CheckCancelled(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed)) {
    throw Cancelled();
  }
}

/// Union bounds of `shapes` — the sizing basis for the deflection rule, the
/// section removal solid, and the on-plane face tolerance.
Bnd_Box UnionBounds(const std::vector<TopoDS_Shape>& shapes) {
  Bnd_Box box;
  for (const TopoDS_Shape& shape : shapes) {
    BRepBndLib::Add(shape, box);
  }
  return box;
}

double DiagonalOf(const Bnd_Box& box) {
  if (box.IsVoid()) {
    return 0.0;
  }
  double xMin = 0, yMin = 0, zMin = 0, xMax = 0, yMax = 0, zMax = 0;
  box.Get(xMin, yMin, zMin, xMax, yMax, zMax);
  return std::hypot(xMax - xMin, std::hypot(yMax - yMin, zMax - zMin));
}

/// Discretization deflection, scaled from the model so a watch part and a
/// site plan both come out smooth: 0.1% of the bounding diagonal, clamped to
/// [1 µm, 0.5 mm] in model units.
double DeflectionFor(const std::vector<TopoDS_Shape>& shapes) {
  const Bnd_Box box = UnionBounds(shapes);
  if (box.IsVoid()) {
    return 0.1;
  }
  return std::clamp(DiagonalOf(box) * 1e-3, 1e-3, 0.5);
}

/// Cut each shape by the section plane, removing all material on the side
/// the normal points toward. The removal solid is a plane-aligned box sized
/// from the union bounds with generous margin — a finite box survives the
/// Boolean where a BRepPrimAPI_MakeHalfSpace half-space is fragile.
std::vector<TopoDS_Shape> CutShapesAtSection(const std::vector<TopoDS_Shape>& shapes,
                                             const HlrSectionPlane& section, const Bnd_Box& bounds,
                                             const std::atomic_bool& cancelled) {
  // 10x the union diagonal in every direction, so no corner of the model can
  // escape the removal volume (a degenerate model still needs a real solid).
  const double extent = 10.0 * std::max(DiagonalOf(bounds), 1.0);
  // Anchor the box laterally over the model, ON the plane: the caller's plane
  // origin may sit anywhere along the plane without uncovering the model.
  gp_Pnt center(0, 0, 0);
  if (!bounds.IsVoid()) {
    double xMin = 0, yMin = 0, zMin = 0, xMax = 0, yMax = 0, zMax = 0;
    bounds.Get(xMin, yMin, zMin, xMax, yMax, zMax);
    center = gp_Pnt((xMin + xMax) / 2.0, (yMin + yMax) / 2.0, (zMin + zMax) / 2.0);
  }
  const gp_XYZ normal = section.normal.XYZ();
  const gp_XYZ anchor =
      center.XYZ() - normal.Multiplied((center.XYZ() - section.origin.XYZ()).Dot(normal));
  // The box corner sits half an extent below the anchor in the plane and AT
  // the plane along the normal, so the box covers exactly the removal side.
  const gp_Ax2 planeFrame(gp_Pnt(anchor), section.normal);
  const gp_XYZ corner = anchor - planeFrame.XDirection().XYZ().Multiplied(extent / 2.0) -
                        planeFrame.YDirection().XYZ().Multiplied(extent / 2.0);
  const TopoDS_Shape removal =
      BRepPrimAPI_MakeBox(gp_Ax2(gp_Pnt(corner), section.normal, planeFrame.XDirection()), extent,
                          extent, extent)
          .Shape();

  std::vector<TopoDS_Shape> kept;
  kept.reserve(shapes.size());
  for (const TopoDS_Shape& shape : shapes) {
    CheckCancelled(cancelled);
    BRepAlgoAPI_Cut cut(shape, removal);
    if (!cut.IsDone()) {
      throw std::runtime_error("section cut failed: a body could not be cut by the section plane");
    }
    kept.push_back(cut.Shape());
  }
  return kept;
}

/// Append every edge of `compound` as one polyline segment. The edges
/// HLRToShape returns already live in the projector's coordinate system with
/// depth along Z, so the drawing is their X/Y verbatim.
void AppendEdges(const TopoDS_Shape& compound, bool visible, double deflection,
                 const std::atomic_bool& cancelled, HlrProjectionResult& result) {
  if (compound.IsNull()) {
    return;
  }
  for (TopExp_Explorer explorer(compound, TopAbs_EDGE); explorer.More(); explorer.Next()) {
    CheckCancelled(cancelled);
    const TopoDS_Edge edge = TopoDS::Edge(explorer.Current());
    BRepAdaptor_Curve curve(edge);
    GCPnts_QuasiUniformDeflection sampler(curve, deflection);
    if (!sampler.IsDone() || sampler.NbPoints() < 2) {
      continue;
    }
    HlrSegment segment;
    segment.visible = visible;
    segment.points.reserve(static_cast<std::size_t>(sampler.NbPoints()) * 2);
    for (int i = 1; i <= sampler.NbPoints(); ++i) {
      const gp_Pnt point = sampler.Value(i);
      segment.points.push_back(point.X());
      segment.points.push_back(point.Y());
      result.minX = std::min(result.minX, point.X());
      result.minY = std::min(result.minY, point.Y());
      result.maxX = std::max(result.maxX, point.X());
      result.maxY = std::max(result.maxY, point.Y());
    }
    result.segments.push_back(std::move(segment));
  }
}

/// Discretize one wire of a section face into a closed loop: edges walked in
/// wire order, each sampled at `deflection` and projected through the SAME
/// projector the segments went through. Junction points shared by
/// consecutive edges are kept once, and the closing point that returns to
/// the start is dropped — the loop's first point is never repeated.
std::vector<double> SectionLoop(const TopoDS_Wire& wire, const TopoDS_Face& face,
                                const HLRAlgo_Projector& projector, double deflection,
                                const std::atomic_bool& cancelled) {
  const double weld = deflection * 1e-2;
  std::vector<double> loop;
  for (BRepTools_WireExplorer edges(wire, face); edges.More(); edges.Next()) {
    CheckCancelled(cancelled);
    const TopoDS_Edge edge = edges.Current();
    BRepAdaptor_Curve curve(edge);
    GCPnts_QuasiUniformDeflection sampler(curve, deflection);
    if (!sampler.IsDone() || sampler.NbPoints() < 2) {
      continue;
    }
    const bool reversed = edge.Orientation() == TopAbs_REVERSED;
    for (int i = 1; i <= sampler.NbPoints(); ++i) {
      gp_Pnt2d point;
      projector.Project(sampler.Value(reversed ? sampler.NbPoints() + 1 - i : i), point);
      if (!loop.empty() && std::fabs(point.X() - loop[loop.size() - 2]) < weld &&
          std::fabs(point.Y() - loop[loop.size() - 1]) < weld) {
        continue;
      }
      loop.push_back(point.X());
      loop.push_back(point.Y());
    }
  }
  if (loop.size() >= 4 && std::fabs(loop[loop.size() - 2] - loop[0]) < weld &&
      std::fabs(loop[loop.size() - 1] - loop[1]) < weld) {
    loop.pop_back();
    loop.pop_back();
  }
  return loop;
}

/// Collect one closed loop per wire of every cut face lying ON the section
/// plane: planar, normal parallel to the section normal, and within
/// `onPlaneTolerance` of the plane. A face's outer boundary and each of its
/// holes become their own loop.
void AppendSectionOutlines(const std::vector<TopoDS_Shape>& shapes, const HlrSectionPlane& section,
                           double onPlaneTolerance, const HLRAlgo_Projector& projector,
                           double deflection, const std::atomic_bool& cancelled,
                           HlrProjectionResult& result) {
  for (const TopoDS_Shape& shape : shapes) {
    for (TopExp_Explorer faces(shape, TopAbs_FACE); faces.More(); faces.Next()) {
      CheckCancelled(cancelled);
      const TopoDS_Face face = TopoDS::Face(faces.Current());
      const BRepAdaptor_Surface surface(face);
      if (surface.GetType() != GeomAbs_Plane) {
        continue;
      }
      const gp_Pln plane = surface.Plane();
      if (!plane.Axis().Direction().IsParallel(section.normal, 1e-9)) {
        continue;
      }
      const double distance =
          (plane.Location().XYZ() - section.origin.XYZ()).Dot(section.normal.XYZ());
      if (std::fabs(distance) > onPlaneTolerance) {
        continue;
      }
      for (TopExp_Explorer wires(face, TopAbs_WIRE); wires.More(); wires.Next()) {
        CheckCancelled(cancelled);
        std::vector<double> loop =
            SectionLoop(TopoDS::Wire(wires.Current()), face, projector, deflection, cancelled);
        // A boundary needs at least three corners to enclose anything.
        if (loop.size() >= 6) {
          result.sectionOutlines.push_back(std::move(loop));
        }
      }
    }
  }
}

} // namespace

HlrProjectionResult ProjectHiddenLine(const std::vector<TopoDS_Shape>& shapes,
                                      const gp_Dir& direction, const gp_Dir& up,
                                      const std::atomic_bool& cancelled) {
  return ProjectHiddenLine(shapes, direction, up, std::nullopt, cancelled);
}

HlrProjectionResult ProjectHiddenLine(const std::vector<TopoDS_Shape>& shapes,
                                      const gp_Dir& direction, const gp_Dir& up,
                                      const std::optional<HlrSectionPlane>& sectionPlane,
                                      const std::atomic_bool& cancelled) {
  if (shapes.empty()) {
    throw std::invalid_argument("hidden-line projection needs at least one body");
  }
  // Orthogonalize `up` against the view direction; refuse a parallel pair,
  // which has no horizon and therefore no view frame.
  const gp_XYZ d = direction.XYZ();
  gp_XYZ upRaw = up.XYZ();
  upRaw -= d.Multiplied(upRaw.Dot(d));
  if (upRaw.Modulus() < 1e-9) {
    throw std::invalid_argument("view up direction is parallel to the view direction");
  }
  const gp_Dir viewY(upRaw);
  const gp_Dir viewX = viewY.Crossed(direction);

  // HLRAlgo_Projector projects along the frame's Z onto its XY plane. Passing
  // `direction` as Z makes X/Y the paper axes established above.
  const gp_Ax2 frame(gp_Pnt(0, 0, 0), direction, viewX);
  HLRAlgo_Projector projector(frame);

  // A requested section removes, before anything is projected, all material
  // on the side of the plane its normal points toward — the view then draws
  // what a drafting section shows: the kept half and its exposed cut.
  std::vector<TopoDS_Shape> bodies = shapes;
  double onPlaneTolerance = 0.0;
  if (sectionPlane) {
    const Bnd_Box bounds = UnionBounds(shapes);
    bodies = CutShapesAtSection(shapes, *sectionPlane, bounds, cancelled);
    onPlaneTolerance = 1e-6 * DiagonalOf(bounds);
  }

  Handle(HLRBRep_Algo) algo = new HLRBRep_Algo();
  for (const TopoDS_Shape& body : bodies) {
    CheckCancelled(cancelled);
    algo->Add(body);
  }
  algo->Projector(projector);
  algo->Update();
  algo->Hide();

  HLRBRep_HLRToShape extractor(algo);
  HlrProjectionResult result;
  result.minX = result.minY = std::numeric_limits<double>::infinity();
  result.maxX = result.maxY = -std::numeric_limits<double>::infinity();

  const double deflection = DeflectionFor(bodies);
  // Drafting draws sharp edges and outlines; smooth tangent continuations
  // (Rg1Line/RgNLine) are surface artifacts a drawing omits.
  AppendEdges(extractor.VCompound(), true, deflection, cancelled, result);
  AppendEdges(extractor.OutLineVCompound(), true, deflection, cancelled, result);
  AppendEdges(extractor.HCompound(), false, deflection, cancelled, result);
  AppendEdges(extractor.OutLineHCompound(), false, deflection, cancelled, result);

  if (sectionPlane) {
    AppendSectionOutlines(bodies, *sectionPlane, onPlaneTolerance, projector, deflection, cancelled,
                          result);
  }

  if (result.segments.empty()) {
    result.minX = result.minY = result.maxX = result.maxY = 0.0;
  }
  return result;
}

} // namespace aeth
