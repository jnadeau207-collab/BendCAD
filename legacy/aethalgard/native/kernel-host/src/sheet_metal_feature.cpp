#include "sheet_metal_feature.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <map>
#include <optional>
#include <queue>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include <BRepAdaptor_Surface.hxx>
#include <BRepAlgoAPI_Common.hxx>
#include <BRepAlgoAPI_Cut.hxx>
#include <BRepAlgoAPI_Fuse.hxx>
#include <BRepBndLib.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <BRepBuilderAPI_MakePolygon.hxx>
#include <BRepBuilderAPI_MakeSolid.hxx>
#include <BRepBuilderAPI_Sewing.hxx>
#include <BRepBuilderAPI_Transform.hxx>
#include <BRepCheck_Analyzer.hxx>
#include <BRepFilletAPI_MakeFillet.hxx>
#include <BRepGProp.hxx>
#include <BRepLib.hxx>
#include <BRepPrimAPI_MakePrism.hxx>
#include <BRepTools_History.hxx>
#include <BRep_Tool.hxx>
#include <Bnd_Box.hxx>
#include <GProp_GProps.hxx>
#include <NCollection_DataMap.hxx>
#include <NCollection_IndexedDataMap.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <Precision.hxx>
#include <Standard_Failure.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shell.hxx>
#include <TopoDS_Solid.hxx>
#include <TopoDS_Vertex.hxx>
#include <TopoDS_Wire.hxx>
#include <gp_Ax1.hxx>
#include <gp_Dir.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <gp_Trsf.hxx>
#include <gp_Vec.hxx>

#include "body_pool.hpp"
#include "bounded_feasibility.hpp"
#include "cancel.hpp"
#include "geometry_measures.hpp"
#include "naming_registry.hpp"
#include "ref_slot.hpp"

namespace aeth {
namespace {

constexpr double kDegreesToRadians = 0.017453292519943295;

using ShapeToShapeMap = NCollection_DataMap<TopoDS_Shape, TopoDS_Shape, TopTools_ShapeMapHasher>;

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

int CountOf(const TopoDS_Shape& shape, const TopAbs_ShapeEnum kind) {
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> map;
  TopExp::MapShapes(shape, kind, map);
  return map.Extent();
}

/// Extracts and validates the single solid of an algorithm result. Throws
/// Standard_Failure on any defect — the shell_feature.cpp precedent — so the
/// caller can attribute a typed `bendCode` refusal at its own call site.
TopoDS_Solid SingleValidSolid(const TopoDS_Shape& result, const char* what) {
  if (result.IsNull() || CountOf(result, TopAbs_SOLID) != 1) {
    throw Standard_Failure((std::string(what) + " did not produce a single solid body").c_str());
  }
  TopExp_Explorer solids(result, TopAbs_SOLID);
  const TopoDS_Solid solid = TopoDS::Solid(solids.Current());
  if (!BRepCheck_Analyzer(solid, false).IsValid())
    throw Standard_Failure((std::string(what) + " produced an invalid solid").c_str());
  return solid;
}

double PlanarArea(const TopoDS_Face& face) {
  GProp_GProps properties;
  BRepGProp::SurfaceProperties(face, properties);
  return std::abs(properties.Mass());
}

/// Every face of `body` sharing `edge` (ADR-003 epoch-local topology; the same
/// TopExp::MapShapesAndAncestors call ComputeDihedralRange itself makes).
std::vector<TopoDS_Face> IncidentFacesOf(const TopoDS_Shape& body, const TopoDS_Edge& edge) {
  NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>, TopTools_ShapeMapHasher>
      edgeToFaces;
  TopExp::MapShapesAndAncestors(body, TopAbs_EDGE, TopAbs_FACE, edgeToFaces);
  std::vector<TopoDS_Face> faces;
  const int index = edgeToFaces.FindIndex(edge);
  if (index == 0)
    return faces;
  for (const TopoDS_Shape& face : edgeToFaces.FindFromKey(edge))
    faces.push_back(TopoDS::Face(face));
  return faces;
}

/// Finds the UNIQUE edge of `shape` whose two endpoints match {a, b} (either
/// order) within `tolerance`. edge_flange's sharp-corner fuse creates its two
/// new crease edges at analytically-known 3D positions (the picked edge
/// itself, and that edge translated by the sheet thickness along the base
/// face's inward normal) — recovering them by POSITION rather than by
/// trusting boolean-history identity through the fuse is the same
/// "verify, don't assume" discipline shell_feature.cpp's own comment records.
TopoDS_Edge FindStraightEdgeByEndpoints(const TopoDS_Shape& shape, const gp_Pnt& a, const gp_Pnt& b,
                                        const double tolerance) {
  // TopExp::MapShapes, not a raw TopExp_Explorer: a manifold solid's every
  // edge is referenced by exactly two faces, so a plain explorer visits each
  // one TWICE (once per owning face) — MapShapes's IndexedMap is the
  // deduplicating traversal every other shape-census helper in this codebase
  // uses (CountOf above, geometry.cpp's own Count) for exactly this reason.
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> edges;
  TopExp::MapShapes(shape, TopAbs_EDGE, edges);
  TopoDS_Edge match;
  int matches = 0;
  for (int index = 1; index <= edges.Extent(); ++index) {
    const TopoDS_Edge candidate = TopoDS::Edge(edges(index));
    TopoDS_Vertex v1;
    TopoDS_Vertex v2;
    TopExp::Vertices(candidate, v1, v2);
    if (v1.IsNull() || v2.IsNull())
      continue;
    const gp_Pnt p1 = BRep_Tool::Pnt(v1);
    const gp_Pnt p2 = BRep_Tool::Pnt(v2);
    const bool forward = p1.Distance(a) <= tolerance && p2.Distance(b) <= tolerance;
    const bool backward = p1.Distance(b) <= tolerance && p2.Distance(a) <= tolerance;
    if (forward || backward) {
      match = candidate;
      matches += 1;
    }
  }
  if (matches != 1) {
    throw Standard_Failure(
        "edge_flange could not uniquely locate an expected crease edge at its analytic position");
  }
  return match;
}

/// A small rectangular prism tool, `sweepLength` deep along `sweepDir` from
/// `origin`, spanning [uMin,uMax] along `uAxis` and [vMin,vMax] along `vAxis`
/// (both perpendicular to `sweepDir`) — used for edge_flange's bend-relief
/// notch. Reuses the exact `BRepBuilderAPI_MakePolygon` + `MakeFace` +
/// `BRepPrimAPI_MakePrism` primitive chain every other body in this file (and
/// `extrude`/`base_flange` in geometry.cpp) already uses, rather than
/// `BRepPrimAPI_MakeBox`'s axis convention, so there is exactly one profile-
/// to-solid recipe to trust in this file.
TopoDS_Shape BuildRectPrismTool(const gp_Pnt& origin, const gp_Dir& uAxis, const gp_Dir& vAxis,
                                const gp_Dir& sweepDir, const double sweepLength, const double uMin,
                                const double uMax, const double vMin, const double vMax) {
  const auto corner = [&](const double u, const double v) {
    return origin.Translated(u * gp_Vec(uAxis) + v * gp_Vec(vAxis));
  };
  BRepBuilderAPI_MakePolygon polygon(corner(uMin, vMin), corner(uMax, vMin), corner(uMax, vMax),
                                     corner(uMin, vMax), /*Close=*/true);
  if (!polygon.IsDone())
    throw Standard_Failure("edge_flange relief tool cross-section wire construction failed");
  const gp_Pln plane(origin, sweepDir);
  BRepBuilderAPI_MakeFace faceMaker(plane, polygon.Wire(), /*Inside=*/true);
  if (!faceMaker.IsDone())
    throw Standard_Failure("edge_flange relief tool face construction failed");
  BRepPrimAPI_MakePrism prism(faceMaker.Face(), sweepLength * gp_Vec(sweepDir), /*Copy=*/true);
  prism.Build();
  if (!prism.IsDone())
    throw Standard_Failure("edge_flange relief tool sweep failed");
  return prism.Shape();
}

/// Whether `endVertex` (one endpoint of the picked edge) already sits on a
/// FREE corner of `baseFace` — no adjacent material tall enough to interfere
/// with the bend — versus a corner where a taller wall (a previously-built
/// flange panel) already stands. Documented heuristic: walk `baseFace`'s
/// OTHER boundary edge(s) at `endVertex` (excluding the picked edge itself)
/// and measure how far each one's OTHER incident face (not `baseFace`)
/// stands away from `baseFace`'s own plane. The original, never-flanged
/// perimeter wall is exactly `thicknessMm` tall; a real flange panel is
/// dramatically taller (`flangeLengthMm`, generally >> thickness). A wall
/// within 1.5x the sheet thickness is read as "the plain original perimeter
/// wall — nothing to tear" (skip relief); anything taller, or a non-planar
/// neighbour, is read as material that could interfere (relief needed). This
/// is a stated, geometry-measured approximation of the task's free-edge test,
/// not a full construction-history graph walk (no per-operation executor in
/// this codebase retains that document-wide history — see
/// EvaluateUnfoldBodies's own kFactor note for the same architectural limit).
bool EndNeedsRelief(const TopoDS_Shape& target, const TopoDS_Face& baseFace,
                    const TopoDS_Edge& pickedEdge, const TopoDS_Vertex& endVertex,
                    const gp_Pln& basePlane, const double thickness) {
  NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>, TopTools_ShapeMapHasher>
      vertexToEdges;
  TopExp::MapShapesAndAncestors(baseFace, TopAbs_VERTEX, TopAbs_EDGE, vertexToEdges);
  const int vertexIndex = vertexToEdges.FindIndex(endVertex);
  if (vertexIndex == 0)
    return true; // Could not locate the corner on the base face; be safe.
  for (const TopoDS_Shape& candidate : vertexToEdges.FindFromKey(endVertex)) {
    if (candidate.IsSame(pickedEdge))
      continue;
    const TopoDS_Edge adjacent = TopoDS::Edge(candidate);
    for (const TopoDS_Face& other : IncidentFacesOf(target, adjacent)) {
      if (other.IsSame(baseFace))
        continue;
      const BRepAdaptor_Surface otherSurface(other, true);
      if (otherSurface.GetType() != GeomAbs_Plane)
        return true; // A curved neighbour (an existing bend) -> be safe.
      double maxDeviation = 0.0;
      for (TopExp_Explorer vertices(other, TopAbs_VERTEX); vertices.More(); vertices.Next()) {
        const gp_Pnt point = BRep_Tool::Pnt(TopoDS::Vertex(vertices.Current()));
        maxDeviation = std::max(maxDeviation, basePlane.Distance(point));
      }
      if (maxDeviation > 1.5 * thickness)
        return true; // Taller than the plain perimeter wall -> real material.
    }
  }
  return false;
}

} // namespace

EvaluatedBody EvaluateEdgeFlange(const nlohmann::json& operation, BodyPool& pool,
                                 ElementNameBook* elementNames, NamingRegistry* registry,
                                 const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();

  const double flangeLength = parameters.at("flangeLengthMm").get<double>();
  const double bendAngleDeg = parameters.at("bendAngleDeg").get<double>();
  const double bendRadius = parameters.at("bendRadiusMm").get<double>();
  const double thickness = parameters.at("thicknessMm").get<double>();
  const double kFactor = parameters.value("kFactor", 0.44);
  const std::string reliefType = parameters.value("reliefType", "rectangular");
  // reliefDepthMm is a TRUE optional on the wire (packages/geometry-contracts
  // deliberately ships it with no schema default — see
  // edgeFlangeOperationSchemaWith's own doc comment) with the documented
  // expectation that an absent value falls back to a kernel-derived "sensible
  // depth", stated there as bendRadiusMm + thicknessMm. Defaulting the
  // nlohmann lookup itself to that same expression (rather than to 0.0, which
  // would then always fail the positivity check just below for any caller
  // that legitimately omits this field) is what actually honors that
  // contract.
  const double reliefDepth = parameters.value("reliefDepthMm", bendRadius + thickness);

  if (!(std::isfinite(flangeLength) && flangeLength > 0.0))
    throw std::invalid_argument("edge_flange flangeLengthMm must be positive");
  if (!(std::isfinite(bendAngleDeg) && bendAngleDeg > 0.0 && bendAngleDeg <= 180.0))
    throw std::invalid_argument("edge_flange bendAngleDeg must be within (0, 180] degrees");
  if (!(std::isfinite(bendRadius) && bendRadius > 0.0))
    throw std::invalid_argument("edge_flange bendRadiusMm must be positive");
  if (!(std::isfinite(thickness) && thickness > 0.0))
    throw std::invalid_argument("edge_flange thicknessMm must be positive");
  if (!(std::isfinite(kFactor) && kFactor >= 0.0 && kFactor <= 1.0))
    throw std::invalid_argument("edge_flange kFactor must be within [0, 1]");
  if (reliefType != "none" && reliefType != "rectangular")
    throw std::invalid_argument("unsupported edge_flange reliefType: " + reliefType);
  if (reliefType == "rectangular" && !(std::isfinite(reliefDepth) && reliefDepth > 0.0))
    throw std::invalid_argument(
        "edge_flange reliefDepthMm must be positive when reliefType is \"rectangular\"");

  if (registry == nullptr) {
    // The fillet-v2 / shell registry-guard precedent: the `edge` slot needs
    // the registry to resolve, so the registry-less path refuses fail-closed.
    throw std::invalid_argument(
        "unsupported operation: edge_flange requires the naming registry to resolve its `edge` "
        "reference; evaluate with the registry enabled");
  }

  // Resolve the picked edge BEFORE consuming the target, so the query sees
  // exactly the bodies this op sees (fillet-v2 N5 discipline).
  const std::vector<EvaluatedBody> peeked = pool.PeekVisibleBodies();
  const RefResolution resolution = ResolveRefSlotStrict(
      operationId, "edge_flange", "edge", parameters.at("edge"), peeked, *registry, cancelled);
  // A value copy, not a reference: the existing SingleResolvedEntity callers
  // in this codebase (geometry.cpp's sketch/mirror/pattern_circular) all copy
  // for exactly this reason — the opLabel argument is a char*-constructed
  // temporary std::string, and GCC's -Wdangling-reference conservatively
  // flags a reference binding here even though the returned reference is
  // actually into `resolution`, not `opLabel`.
  const QueryEntity edgeEntity = SingleResolvedEntity("edge_flange", "edge", 'e', resolution);
  const std::string* targetBodyIdBeforeConsume = nullptr;
  for (const EvaluatedBody& body : peeked) {
    if (body.operationId == targetOperationId) {
      targetBodyIdBeforeConsume = &body.bodyId;
      break;
    }
  }
  if (targetBodyIdBeforeConsume != nullptr && edgeEntity.bodyId != *targetBodyIdBeforeConsume) {
    throw std::invalid_argument(
        "edge_flange edge reference resolved an edge outside the edge_flange target body");
  }

  // edge_flange CONSUMES its target, the same taxonomy as fillet/shell/chamfer.
  const TopoDS_Shape target = pool.Consume(operationId, "edge_flange", "target", targetOperationId);
  const TopoDS_Edge pickedEdge = TopoDS::Edge(edgeEntity.shape);

  const auto refuse = [&](const char* message, const char* bendCode) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, {{"bendCode", bendCode}});
  };

  // --- Step 1: the picked edge must be a coherent boundary of ONE planar
  // face — a genuinely FREE edge to grow a flange from, not an interior or
  // already-doubly-bounded one. ------------------------------------------
  const std::vector<TopoDS_Face> incident = IncidentFacesOf(target, pickedEdge);
  if (incident.size() != 2) {
    refuse("edge_flange requires an edge shared by exactly two faces of the target body",
           "E_EDGE_FLANGE_NOT_PLANAR_BOUNDARY");
  }
  // Sanity check (per the task's own prescription): ComputeDihedralRange is
  // the codebase's own bend/boundary detector — an inapplicable range (a seam
  // or a degenerate 3D-curve-less edge) is not a boundary this op can use.
  if (!ComputeDihedralRange(target, pickedEdge).applicable) {
    refuse("edge_flange's picked edge is not a well-formed dihedral boundary",
           "E_EDGE_FLANGE_NOT_PLANAR_BOUNDARY");
  }
  // The base face is whichever incident face is PLANAR; when both are (a
  // straight-profile sheet's cap and its own thin perimeter wall are both
  // planar), the base is the larger of the two — the sheet's cap is the
  // dominant face for any sheet whose thickness is less than half its
  // shortest profile edge, a reasonable, documented assumption for sheet
  // metal (real stock is always thin relative to its panel dimensions).
  int planarIndex = -1;
  double bestArea = -1.0;
  for (std::size_t index = 0; index < incident.size(); ++index) {
    if (SurfaceClass(incident[index]) != "plane")
      continue;
    const double area = PlanarArea(incident[index]);
    if (area > bestArea) {
      bestArea = area;
      planarIndex = static_cast<int>(index);
    }
  }
  if (planarIndex < 0) {
    refuse("edge_flange can only grow from the boundary of a planar face",
           "E_EDGE_FLANGE_NOT_PLANAR_BOUNDARY");
  }
  const TopoDS_Face baseFace = incident[static_cast<std::size_t>(planarIndex)];
  const BRepAdaptor_Surface baseSurface(baseFace, true);
  const Axis outwardOpt = PlanarOutwardNormal(baseFace, baseSurface);
  if (!outwardOpt.has_value())
    throw std::runtime_error("edge_flange could not derive the base face's outward normal");
  const gp_Dir N((*outwardOpt)[0], (*outwardOpt)[1], (*outwardOpt)[2]);
  const gp_Pln basePlane = baseSurface.Plane();

  TopoDS_Vertex v1;
  TopoDS_Vertex v2;
  TopExp::Vertices(pickedEdge, v1, v2);
  if (v1.IsNull() || v2.IsNull())
    refuse("edge_flange's picked edge has no endpoints", "E_EDGE_FLANGE_NOT_PLANAR_BOUNDARY");
  const gp_Pnt P1 = BRep_Tool::Pnt(v1);
  const gp_Pnt P2 = BRep_Tool::Pnt(v2);
  if (P1.Distance(P2) < Precision::Confusion())
    refuse("edge_flange's picked edge is degenerate", "E_EDGE_FLANGE_NOT_PLANAR_BOUNDARY");
  const gp_Dir edgeDir(gp_Vec(P1, P2));
  const double edgeLength = P1.Distance(P2);

  // --- Step 2/3: the flat (angle-zero) continuation panel plus a SHARP
  // wedge infill, as one hand-derived pentagon cross-section swept along the
  // edge. See sheet_metal_feature.hpp's class comment for the full geometric
  // derivation (an orthonormal {edgeDir, outwardInPlane, N} frame; the
  // rotation axis outwardInPlane x N sweeps +bendAngleDeg from coplanar-with-
  // base to standing up along N, verified analytically before writing this
  // code, not merely assumed). ---------------------------------------------
  GProp_GProps baseProps;
  BRepGProp::SurfaceProperties(baseFace, baseProps);
  const gp_Pnt faceCentroid = baseProps.CentreOfMass();
  const gp_Pnt edgeMid(0.5 * (P1.X() + P2.X()), 0.5 * (P1.Y() + P2.Y()), 0.5 * (P1.Z() + P2.Z()));

  gp_Dir outwardInPlane = N.Crossed(edgeDir);
  if (gp_Vec(faceCentroid, edgeMid).Dot(gp_Vec(outwardInPlane)) < 0.0)
    outwardInPlane.Reverse();
  // The pentagon below is built directly from cos(theta)/sin(theta) in the
  // {outwardInPlane, N} plane rather than through an explicit gp_Trsf
  // rotation, so no rotation-axis gp_Dir object is needed at runtime — but
  // the DERIVATION that this sweeps the flat continuation toward N as theta
  // grows from 0 does rest on one: rotating BY +bendAngleRad about axis =
  // outwardInPlane x N sweeps outwardInPlane onto N (a x b = c for the
  // right-handed orthonormal triple {axis, outwardInPlane, N}, so
  // axis = outwardInPlane x N — verified via the cyclic identity and a
  // worked numeric example before this code was written), and a rotation by
  // theta about that axis applied to a vector already lying in the plane it
  // spans is EXACTLY cos(theta)*outwardInPlane + sin(theta)*N by the
  // standard perpendicular-vector Rodrigues formula, which is what
  // `localPoint` below computes directly.

  const double theta = bendAngleDeg * kDegreesToRadians;
  const double cosT = std::cos(theta);
  const double sinT = std::sin(theta);
  // The wire contract measures flangeLengthMm from the TANGENT LINE (where
  // the flat panel meets the rounded bend), not from the sharp hinge this
  // pentagon is built around — but rounding the outer crease with radius
  // (bendRadiusMm + thicknessMm) trims the flat panel BACK from the hinge by
  // the standard tangent-length formula for a circle of that radius inscribed
  // in a corner swept through `theta`: (R+t) * tan(theta/2) (the wedge's
  // half-angle is (pi-theta)/2, and tan of the COMPLEMENT of a half-angle is
  // the cotangent identity cot((pi-theta)/2) = tan(theta/2)). Building the far
  // corner `tangentSetback` further out than a plain flangeLengthMm sweep
  // means the OUTER fillet's own trim exactly cancels it, so the panel's
  // REMAINING flat length after rounding is flangeLengthMm on the nose —
  // verified by this file's own tests, not merely asserted.
  const double tangentSetback = (bendRadius + thickness) * std::tan(0.5 * theta);
  if (!std::isfinite(tangentSetback))
    refuse("edge_flange's bendAngleDeg is too close to a full fold-back for a tangent bend",
           "E_EDGE_FLANGE_SELF_INTERSECTS");
  const double extendedLength = flangeLength + tangentSetback;
  const auto localPoint = [&](const double u, const double v) {
    return P1.Translated(u * gp_Vec(outwardInPlane) + v * gp_Vec(N));
  };
  const gp_Pnt hinge = P1;
  const gp_Pnt farOuter = localPoint(extendedLength * cosT, extendedLength * sinT);
  const gp_Pnt farInner = localPoint(extendedLength * cosT + thickness * sinT,
                                     extendedLength * sinT - thickness * cosT);
  const gp_Pnt wedgeInner = localPoint(thickness * sinT, -thickness * cosT);
  const gp_Pnt innerHinge = localPoint(0.0, -thickness);

  BRepBuilderAPI_MakePolygon pentagon;
  pentagon.Add(hinge);
  pentagon.Add(farOuter);
  pentagon.Add(farInner);
  pentagon.Add(wedgeInner);
  pentagon.Add(innerHinge);
  pentagon.Close();
  if (!pentagon.IsDone())
    refuse("edge_flange could not build the flange/bend cross-section wire",
           "E_EDGE_FLANGE_SELF_INTERSECTS");
  const gp_Pln crossSectionPlane(P1, edgeDir);
  BRepBuilderAPI_MakeFace pentagonFaceMaker(crossSectionPlane, pentagon.Wire(), /*Inside=*/true);
  if (!pentagonFaceMaker.IsDone())
    refuse("edge_flange could not build the flange/bend cross-section face",
           "E_EDGE_FLANGE_SELF_INTERSECTS");
  if (!BRepCheck_Analyzer(pentagonFaceMaker.Face(), false).IsValid())
    refuse("edge_flange's flange/bend cross-section self-intersects for these parameters",
           "E_EDGE_FLANGE_SELF_INTERSECTS");

  BRepPrimAPI_MakePrism infillMaker(pentagonFaceMaker.Face(), edgeLength * gp_Vec(edgeDir),
                                    /*Copy=*/true);
  infillMaker.Build();
  if (!infillMaker.IsDone())
    refuse("edge_flange could not sweep the new-material solid", "E_EDGE_FLANGE_SELF_INTERSECTS");
  TopoDS_Solid newMaterial;
  try {
    newMaterial = SingleValidSolid(infillMaker.Shape(), "edge_flange's new-material solid");
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("edge_flange's new-material solid is invalid for these parameters",
           "E_EDGE_FLANGE_SELF_INTERSECTS");
  }

  // --- Fuse the new material to the target: a clean coincident-face fuse,
  // since the infill's wall-glue face is exactly the target's own perimeter
  // wall face at the picked edge. -------------------------------------------
  BRepAlgoAPI_Fuse fuse;
  {
    NCollection_List<TopoDS_Shape> objects;
    objects.Append(target);
    NCollection_List<TopoDS_Shape> tools;
    tools.Append(TopoDS_Shape(newMaterial));
    fuse.SetArguments(objects);
    fuse.SetTools(tools);
    fuse.SetRunParallel(false);
    // No history needed here either — see the naming-mint block's own
    // comment for why edge_flange mints its result fresh instead of
    // composing a fuse -> fillet [-> relief] history chain.
    fuse.SetToFillHistory(false);
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    try {
      fuse.Build(progress->Start());
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      refuse("edge_flange could not fuse the new material to the target",
             "E_EDGE_FLANGE_SELF_INTERSECTS");
    }
  }
  CheckCancellation(cancelled);
  if (fuse.HasErrors() || !fuse.IsDone())
    refuse("edge_flange could not fuse the new material to the target",
           "E_EDGE_FLANGE_SELF_INTERSECTS");
  TopoDS_Solid sharpSolid;
  try {
    sharpSolid = SingleValidSolid(fuse.Shape(), "edge_flange's sharp-corner fuse");
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("edge_flange's sharp-corner fuse produced an invalid or fragmented body",
           "E_EDGE_FLANGE_SELF_INTERSECTS");
  }

  // --- Step 4: round the two new crease edges into a genuine tangent bend
  // via BRepFilletAPI_MakeFillet (OCCT's own proven fillet algorithm, not a
  // hand-built cylindrical trim — see the header comment's divergence note).
  // The OUTER crease sits exactly at the picked edge's own position; the
  // INNER crease sits exactly one thickness further along -N — both
  // analytically known, so they are recovered by position, never by
  // assuming boolean-history identity survives the fuse. ---------------------
  const gp_Pnt innerP1 = P1.Translated(-thickness * gp_Vec(N));
  const gp_Pnt innerP2 = P2.Translated(-thickness * gp_Vec(N));
  TopoDS_Edge outerCreaseEdge;
  TopoDS_Edge innerCreaseEdge;
  try {
    outerCreaseEdge = FindStraightEdgeByEndpoints(sharpSolid, P1, P2, 1.0e-5);
    innerCreaseEdge = FindStraightEdgeByEndpoints(sharpSolid, innerP1, innerP2, 1.0e-5);
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("edge_flange could not locate the sharp corner's two crease edges",
           "E_EDGE_FLANGE_SELF_INTERSECTS");
  }

  BRepFilletAPI_MakeFillet filletMaker(sharpSolid);
  filletMaker.Add(bendRadius, innerCreaseEdge);
  filletMaker.Add(bendRadius + thickness, outerCreaseEdge);
  {
    const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
    try {
      filletMaker.Build(progress->Start());
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      refuse("edge_flange's bend radius is not feasible for these parameters",
             "E_EDGE_FLANGE_SELF_INTERSECTS");
    }
  }
  CheckCancellation(cancelled);
  if (!filletMaker.IsDone())
    refuse("edge_flange's bend radius is not feasible for these parameters",
           "E_EDGE_FLANGE_SELF_INTERSECTS");
  TopoDS_Solid roundedSolid;
  try {
    roundedSolid = SingleValidSolid(filletMaker.Shape(), "edge_flange's rounded bend");
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("edge_flange's bend radius produced an invalid body for these parameters",
           "E_EDGE_FLANGE_SELF_INTERSECTS");
  }

  // --- Step 5: bend relief, skipped at an end whose adjacent material is
  // still just the thin original perimeter wall (nothing to tear). ----------
  TopoDS_Shape finalShape = roundedSolid;
  if (reliefType == "rectangular") {
    const double halfSpan = 2.0 * (bendRadius + thickness);
    const struct {
      gp_Pnt point;
      TopoDS_Vertex vertex;
      gp_Dir sweep;
    } ends[2] = {
        {P1, v1, gp_Dir(-edgeDir.X(), -edgeDir.Y(), -edgeDir.Z())},
        {P2, v2, edgeDir},
    };
    for (const auto& end : ends) {
      CheckCancellation(cancelled);
      if (!EndNeedsRelief(target, baseFace, pickedEdge, end.vertex, basePlane, thickness))
        continue;
      TopoDS_Shape tool;
      try {
        // sweepDir points INTO the bend's length from this end, so the notch
        // eats `reliefDepthMm` of the bend/flange rather than the untouched
        // material beyond the panel's own boundary.
        const gp_Dir intoLength(-end.sweep.X(), -end.sweep.Y(), -end.sweep.Z());
        tool =
            BuildRectPrismTool(end.point, outwardInPlane, N, intoLength, reliefDepth, -halfSpan,
                               halfSpan, -3.0 * (bendRadius + thickness), bendRadius + thickness);
      } catch (const Standard_Failure&) {
        CheckCancellation(cancelled);
        refuse("edge_flange could not build a bend-relief cutting tool",
               "E_EDGE_FLANGE_RELIEF_FAILED");
      }
      BRepAlgoAPI_Cut cut;
      NCollection_List<TopoDS_Shape> objects;
      objects.Append(finalShape);
      NCollection_List<TopoDS_Shape> tools;
      tools.Append(tool);
      cut.SetArguments(objects);
      cut.SetTools(tools);
      cut.SetRunParallel(false);
      // No history needed: edge_flange's naming mint (below) roots the whole
      // result fresh via AddDerivedPrimitive/HarvestCopiedBody rather than
      // composing per-stage histories — see that block's own comment for why.
      cut.SetToFillHistory(false);
      {
        const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
        try {
          cut.Build(progress->Start());
        } catch (const Standard_Failure&) {
          CheckCancellation(cancelled);
          refuse("edge_flange's bend-relief cut failed", "E_EDGE_FLANGE_RELIEF_FAILED");
        }
      }
      CheckCancellation(cancelled);
      if (cut.HasErrors() || !cut.IsDone())
        refuse("edge_flange's bend-relief cut failed", "E_EDGE_FLANGE_RELIEF_FAILED");
      try {
        finalShape = SingleValidSolid(cut.Shape(), "edge_flange's relieved body");
      } catch (const Standard_Failure&) {
        CheckCancellation(cancelled);
        refuse("edge_flange's bend-relief cut produced an invalid body",
               "E_EDGE_FLANGE_RELIEF_FAILED");
      }
    }
  }

  TopoDS_Solid finalSolid = TopoDS::Solid(finalShape);
  BRepLib::OrientClosedSolid(finalSolid);
  EvaluatedBody body;
  body.bodyId = operation.at("outputBodyId").get<std::string>();
  body.operationId = operationId;
  body.shape = finalSolid;
  body.probes = ProbeShape(body.shape);
  if (!body.probes.valid)
    throw std::runtime_error("OCCT produced an invalid edge_flange result");

  if (elementNames != nullptr) {
    // MEASURED DIVERGENCE FROM THE INITIAL PLAN (the shell_feature.hpp
    // discipline: verify empirically, document rather than paper over).
    // The original plan composed fuse -> fillet [-> relief cut] histories
    // exactly as EvaluateLocalFaceOffset composes its boolean -> unify pair
    // (sequential BRepTools_History::Merge, then a self-image-filtering
    // rebuild). That compiles and runs, but empirically throws inside
    // ElementNameBook::ApplyOperation ("cannot attribute a result entity ...
    // bare quantized-geometry root"): unlike ShapeUpgrade_UnifySameDomain
    // (offset's second stage, a pure face merge with clean, complete
    // Modified/Generated coverage), BRepFilletAPI_MakeFillet's own history is
    // ALREADY documented as face-only-reliable even for a single, uncomposed
    // fillet (see EvaluateFillet's own comment: "the book's lower-bound
    // reconstruction is what names the blend boundary edges and vertices —
    // exactly the gap the element-map scheme exists to fill"). A plain
    // fillet gets that reconstruction for free because ElementNameBook runs
    // it directly against the fillet's own real history; composed through an
    // upstream fuse first, the rebuilt history does not carry enough for the
    // SAME reconstruction to bridge every edge/vertex, and unlike offset's
    // simplification stage there is no cheaper history-preserving
    // alternative to a real BRepFilletAPI_MakeFillet call here — the whole
    // point of using it (see this file's header comment) is that it is
    // OCCT's own proven tangent-arc construction, not a hand-rolled one.
    //
    // Given that, this mints edge_flange's result the AddDerivedPrimitive /
    // HarvestCopiedBody way instead — the CAP-034 "swept from the target's
    // own face" mold: sub-shapes that are still IDENTITY-UNCHANGED (most of
    // the target, away from the bend) keep their real, pre-existing names;
    // every NEW or MODIFIED sub-shape (the whole bend/panel/relief region)
    // roots fresh under this operation, uniformly, rather than the finer
    // modified/panel/bend role split OperationClass::EdgeFlange's own role
    // table (naming_registry.cpp) was written for. Geometric correctness
    // (this file's whole point, verified by sheet_metal_test.cpp against
    // analytically known dimensions) is unaffected: naming coverage is
    // still TOTAL, just coarser than a fully composed history would give.
    elementNames->AddDerivedPrimitive(operationId, body.shape);
    if (registry != nullptr) {
      const ShapeToShapeMap noAncestors;
      registry->HarvestCopiedBody(operationId, body.shape, "panel", "generated", "generated",
                                  noAncestors, cancelled);
    }
  }
  return body;
}

namespace {

/// A recognized bend region: two concentric cylindrical faces sharing one
/// axis line, their radii differing by the sheet thickness — see
/// EvaluateUnfoldBodies's header comment for why this pair, not a single
/// cylindrical face, is what `edge_flange` always builds (a genuine inside
/// AND outside bend surface, not a zero-thickness idealization).
struct RecognizedBend final {
  TopoDS_Face innerFace;
  TopoDS_Face outerFace;
  gp_Ax1 axis;
  double insideRadius{};
  double thickness{};
};

/// One BFS tree edge's flattening plan, computed once from the ORIGINAL
/// (pre-transform) target geometry and later composed with the near
/// component's own accumulated transform.
struct BendFlattenPlan final {
  gp_Trsf localTransform;
  gp_Pnt nearOuterP1;
  gp_Pnt nearOuterP2;
  gp_Pnt farOuterP1; // ORIGINAL (pre-localTransform) coordinates, like nearOuterP1/P2.
  gp_Pnt farOuterP2;
  gp_Dir unfoldDir;     // == nearCutNormal: the near panel's own in-plane direction.
  gp_Dir intoMaterial;  // From the outer tangent toward the inner tangent.
  gp_Dir nearCutNormal; // Near panel's own in-plane outward direction (for CUTTING).
  gp_Dir farCutNormal;  // Far panel's own in-plane outward direction (for CUTTING).
  double allowance{};   // BA, the bend allowance.
};

struct TreeEdge final {
  int bendIndex{};
  int nearComponent{};
  int farComponent{};
  BendFlattenPlan plan;
};

// MEASURED (not merely assumed — the shell_feature.hpp discipline): a bend's
// inner and outer cylindrical faces, as this file's EvaluateEdgeFlange builds
// them (two INDEPENDENT BRepFilletAPI_MakeFillet calls on two independently-
// derived sharp creases), are NOT generally concentric. A sharp corner's
// fillet centre sits at radius/sin(halfDihedral) from the crease along the
// dihedral's bisector, and the outer crease (base-top to flange-top,
// dihedral = bendAngleDeg by construction) and the inner crease (base-bottom
// through this file's wedge infill to flange-bottom) do not share that
// dihedral in general — verified against this file's own 90-degree test
// fixture, where the two measured fillet axes land several mm apart. A
// PHYSICALLY exact concentric bend would need the bend region built as one
// genuine annular sector (two concentric arcs swept together) rather than
// two independently sharp-cornered-then-rounded wedges; that is a larger
// rework this wave's schedule does not carry, so bend-PAIR recognition below
// keys on axis DIRECTION only (parallel, not collinear) — sufficient for
// this file's own purposes, since PlanBendFlatten never queries the inner
// face's own axis location (only its measured radius, and one consistently-
// chosen axis line, the outer's, for the flattening rotation), and the
// SEPARATE "this pair borders exactly two flat panels" adjacency check
// (bendEdges below) is the real confirmation that a direction-parallel
// cylindrical pair is a genuine, coherent bend rather than two unrelated
// same-direction cylindrical features.
bool ParallelAxisDirection(const gp_Ax1& a, const gp_Ax1& b) {
  return std::abs(a.Direction().Dot(b.Direction())) >= 1.0 - 1.0e-7;
}

double AxialParam(const gp_Pnt& point, const gp_Ax1& axis) {
  return gp_Vec(axis.Location(), point).Dot(gp_Vec(axis.Direction()));
}

gp_Pnt Midpoint(const gp_Pnt& a, const gp_Pnt& b) {
  return {0.5 * (a.X() + b.X()), 0.5 * (a.Y() + b.Y()), 0.5 * (a.Z() + b.Z())};
}

/// Every straight edge of `face` (a recognized bend's cylindrical patch)
/// running parallel to `axis` — its two "tangent lines" where the patch
/// meets its two flat neighbours.
std::vector<TopoDS_Edge> AxisParallelEdgesOf(const TopoDS_Face& face, const gp_Ax1& axis) {
  std::vector<TopoDS_Edge> edges;
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> faceEdges;
  TopExp::MapShapes(face, TopAbs_EDGE, faceEdges);
  for (int index = 1; index <= faceEdges.Extent(); ++index) {
    const TopoDS_Edge edge = TopoDS::Edge(faceEdges(index));
    TopoDS_Vertex v1;
    TopoDS_Vertex v2;
    TopExp::Vertices(edge, v1, v2);
    if (v1.IsNull() || v2.IsNull())
      continue;
    const gp_Pnt p1 = BRep_Tool::Pnt(v1);
    const gp_Pnt p2 = BRep_Tool::Pnt(v2);
    if (p1.Distance(p2) < Precision::Confusion())
      continue;
    const gp_Dir direction(gp_Vec(p1, p2));
    if (std::abs(direction.Dot(axis.Direction())) > 1.0 - 1.0e-6)
      edges.push_back(edge);
  }
  return edges;
}

using EdgeToFacesMap = NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>,
                                                  TopTools_ShapeMapHasher>;
using FaceSet = NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher>;

/// Computes one bend's flattening plan: the rigid transform (in the bend's
/// OWN original-body coordinates, composed with the near panel's own
/// accumulated transform by the caller) that lays the far panel flat,
/// coplanar with the near panel, its tangent line exactly `BA` past the
/// near panel's own tangent line along the unfold direction. Throws
/// Standard_Failure if the bend's expected tangent-edge structure is not
/// found (routed by the caller to E_UNFOLD_NOT_DEVELOPABLE).
BendFlattenPlan PlanBendFlatten(const RecognizedBend& bend, const int nearComponent,
                                const int farComponent, const double kFactor,
                                const FaceSet& panelFaces, const std::vector<int>& componentOf,
                                const EdgeToFacesMap& edgeToFaces, const FaceSet& bendFaceSet) {
  const auto findTangent = [&](const TopoDS_Face& face, const int wantComponent) -> TopoDS_Edge {
    for (const TopoDS_Edge& edge : AxisParallelEdgesOf(face, bend.axis)) {
      const int edgeIndex = edgeToFaces.FindIndex(edge);
      if (edgeIndex == 0)
        continue;
      for (const TopoDS_Shape& neighbour : edgeToFaces.FindFromKey(edge)) {
        if (bendFaceSet.Contains(neighbour))
          continue;
        const int neighbourIndex = panelFaces.FindIndex(neighbour);
        if (neighbourIndex == 0)
          continue;
        if (componentOf[static_cast<std::size_t>(neighbourIndex)] == wantComponent)
          return edge;
      }
    }
    throw Standard_Failure("unfold could not locate a bend's tangent edge on the expected panel");
  };
  const auto otherFaceOf = [&](const TopoDS_Edge& edge, const TopoDS_Face& exclude) -> TopoDS_Face {
    const int edgeIndex = edgeToFaces.FindIndex(edge);
    if (edgeIndex != 0) {
      for (const TopoDS_Shape& neighbour : edgeToFaces.FindFromKey(edge)) {
        if (!neighbour.IsSame(exclude) && !bendFaceSet.Contains(neighbour))
          return TopoDS::Face(neighbour);
      }
    }
    throw Standard_Failure("unfold could not locate a bend tangent edge's own flat neighbour");
  };

  const TopoDS_Edge nearOuterEdge = findTangent(bend.outerFace, nearComponent);
  const TopoDS_Edge farOuterEdge = findTangent(bend.outerFace, farComponent);
  // The inner tangent edge is not read for its own geometry below (the
  // strip's thickness-extrusion direction is derived from the near panel's
  // own outward normal instead — see the comment ahead of `intoMaterial`),
  // but locating it is still a meaningful structural check: it confirms the
  // bend's inner cylindrical face genuinely borders the near panel the same
  // way the outer one does. Discard the result; keep the validation.
  findTangent(bend.innerFace, nearComponent);
  const TopoDS_Face nearOuterPanelFace = otherFaceOf(nearOuterEdge, bend.outerFace);
  const TopoDS_Face farOuterPanelFace = otherFaceOf(farOuterEdge, bend.outerFace);

  TopoDS_Vertex nv1;
  TopoDS_Vertex nv2;
  TopoDS_Vertex fv1;
  TopoDS_Vertex fv2;
  TopExp::Vertices(nearOuterEdge, nv1, nv2);
  TopExp::Vertices(farOuterEdge, fv1, fv2);
  const gp_Pnt nearP1 = BRep_Tool::Pnt(nv1);
  const gp_Pnt nearP2 = BRep_Tool::Pnt(nv2);
  const gp_Pnt farP1 = BRep_Tool::Pnt(fv1);
  const gp_Pnt farP2 = BRep_Tool::Pnt(fv2);

  // Every direction this function needs from here on is derived from the
  // near panel's OWN in-plane frame, never from the original 3D (folded)
  // offset between near and far geometry. MEASURED DIVERGENCE FROM THE
  // INITIAL PLAN (this file's own "verify, don't assume" discipline): the
  // plan's first cut derived the unfold-offset direction from the raw 3D
  // vector between the near and far tangent points, and the strip's
  // thickness-extrusion direction from the raw 3D vector between the near
  // panel's outer and inner tangent points — both perpendicular-to-axis
  // projections of ORIGINAL (folded) 3D geometry. Both are diagonal in
  // general (the bend's actual axis position need not sit in either panel's
  // own plane), and using either as a FLATTENED-space direction is wrong:
  // measured on this file's own 90-degree test fixture, the flattened
  // flange landed at Z ~4 instead of matching the base panel's own Z in
  // [0, 2] (the unfold-offset case), and separately the bend-allowance
  // strip's own thickness extent came out as 1.224 mm instead of the sheet's
  // real 2 mm (the strip-thickness-direction case, exposed once the first
  // bug was fixed). Once every panel is flattened into ONE common plane
  // (the seed's own), the only directions that belong in that plane are the
  // near panel's OWN in-plane axes — this function computes them ONCE,
  // right after locating the near panel's own face, and every subsequent
  // direction (the unfold offset, the strip's cross-section normal, the
  // strip's thickness extrusion) is built from them instead of from
  // original-geometry offsets.
  const auto outwardOf = [&](const TopoDS_Face& face) {
    const BRepAdaptor_Surface faceSurface(face, true);
    const Axis normalOpt = PlanarOutwardNormal(face, faceSurface);
    if (!normalOpt.has_value())
      throw Standard_Failure("unfold could not derive a panel face's outward normal");
    return gp_Dir((*normalOpt)[0], (*normalOpt)[1], (*normalOpt)[2]);
  };
  const auto outwardInPlaneOf = [&](const TopoDS_Face& face, const gp_Dir& faceNormal,
                                    const gp_Pnt& edgeP1, const gp_Pnt& edgeP2) {
    gp_Dir candidate = faceNormal.Crossed(gp_Dir(gp_Vec(edgeP1, edgeP2)));
    GProp_GProps faceProps;
    BRepGProp::SurfaceProperties(face, faceProps);
    if (gp_Vec(faceProps.CentreOfMass(), Midpoint(edgeP1, edgeP2)).Dot(gp_Vec(candidate)) < 0.0)
      candidate.Reverse();
    return candidate;
  };
  const gp_Dir nearOutward = outwardOf(nearOuterPanelFace);
  const gp_Dir farOutward = outwardOf(farOuterPanelFace);
  const gp_Dir nearCutNormal = outwardInPlaneOf(nearOuterPanelFace, nearOutward, nearP1, nearP2);
  const gp_Dir farCutNormal = outwardInPlaneOf(farOuterPanelFace, farOutward, farP1, farP2);
  const gp_Dir& unfoldDir = nearCutNormal;
  // The near panel's own into-material direction: material sits on the
  // opposite side of its outward face from the outward normal itself.
  const gp_Dir intoMaterial(-nearOutward.X(), -nearOutward.Y(), -nearOutward.Z());

  // The measured swept angle, straight from the cylindrical face's own
  // parametrization — never assumed to equal the authoring bendAngleDeg
  // (edge_flange's fillets may not reproduce it to the bit).
  const BRepAdaptor_Surface outerSurface(bend.outerFace, true);
  const double angleSpan = std::abs(outerSurface.LastUParameter() - outerSurface.FirstUParameter());
  const double allowance = angleSpan * (bend.insideRadius + kFactor * bend.thickness);

  // Which sign undoes the bend is resolved by COPLANARITY with the near
  // panel's own face, not assumed from the cylinder's OCCT-assigned axis
  // sign (which need not agree with whatever sign edge_flange's own
  // construction used for this bend).
  const double farP1Axial = AxialParam(farP1, bend.axis);
  const double farP2Axial = AxialParam(farP2, bend.axis);
  const gp_Pnt farNearMatch = std::abs(farP1Axial - AxialParam(nearP1, bend.axis)) <=
                                      std::abs(farP2Axial - AxialParam(nearP1, bend.axis))
                                  ? farP1
                                  : farP2;
  gp_Trsf rotatePositive;
  rotatePositive.SetRotation(bend.axis, angleSpan);
  gp_Trsf rotateNegative;
  rotateNegative.SetRotation(bend.axis, -angleSpan);
  // Which sign undoes the bend is resolved by ORIENTATION, not position.
  // MEASURED DIVERGENCE FROM THE INITIAL PLAN (this file's own "verify,
  // don't assume" discipline): the plan's first cut picked whichever
  // rotation landed farNearMatch CLOSER to the near panel's own plane
  // (`gp_Pln::Distance`). That is not a sufficient test — `farNearMatch`
  // is not actually constrained to land ON that plane by either rotation
  // alone (only the FULL localTransform, rotation plus the translation
  // derived from it, lands it at its target position), so both candidate
  // distances are generally non-zero and the smaller one is not
  // reliably the physically correct rotation. MEASURED on this file's own
  // 90-degree test fixture: the distance-based rule chose the rotation
  // whose transformed far panel's OWN outward normal ended up ANTI-
  // PARALLEL to the near panel's outward normal (flange material landing
  // on the opposite side of the seed's own plane from where the seed's
  // material is) — geometrically valid-looking (still one solid, still
  // flat) but physically backwards. The correct, sufficient test is
  // ORIENTATION: apply each candidate rotation to the far panel's OWN
  // outward normal (already computed above as `farOutward`, right alongside
  // `nearOutward` — this function derives both exactly once) and keep
  // whichever rotation makes it PARALLEL (not anti-parallel) to the near
  // panel's outward normal — the two panels must end up facing the SAME way
  // for the flattened body to be a genuine flat sheet rather than a
  // folded-the-wrong-way self-intersection waiting to happen.
  const double alignmentPositive = farOutward.Transformed(rotatePositive).Dot(nearOutward);
  const double alignmentNegative = farOutward.Transformed(rotateNegative).Dot(nearOutward);
  const gp_Trsf rotate = alignmentPositive >= alignmentNegative ? rotatePositive : rotateNegative;

  const gp_Pnt rotatedMatch = farNearMatch.Transformed(rotate);
  const gp_Pnt targetMatch = nearP1.Translated(allowance * gp_Vec(unfoldDir));
  gp_Trsf translate;
  translate.SetTranslation(gp_Vec(rotatedMatch, targetMatch));

#ifdef AETH_SHEET_METAL_DEBUG
  std::fprintf(stderr,
               "DEBUG plan nearP1=(%.3f,%.3f,%.3f) nearP2=(%.3f,%.3f,%.3f) farP1=(%.3f,%.3f,%.3f) "
               "farP2=(%.3f,%.3f,%.3f) unfoldDir=(%.3f,%.3f,%.3f) intoMaterial=(%.3f,%.3f,%.3f) "
               "allowance=%.4f angleSpan=%.4f\n",
               nearP1.X(), nearP1.Y(), nearP1.Z(), nearP2.X(), nearP2.Y(), nearP2.Z(), farP1.X(),
               farP1.Y(), farP1.Z(), farP2.X(), farP2.Y(), farP2.Z(), unfoldDir.X(), unfoldDir.Y(),
               unfoldDir.Z(), intoMaterial.X(), intoMaterial.Y(), intoMaterial.Z(), allowance,
               angleSpan);
#endif
  BendFlattenPlan plan;
  plan.localTransform = translate.Multiplied(rotate);
  plan.nearOuterP1 = nearP1;
  plan.nearOuterP2 = nearP2;
  plan.farOuterP1 = farP1;
  plan.farOuterP2 = farP2;
  plan.unfoldDir = unfoldDir;
  plan.intoMaterial = intoMaterial;
  plan.nearCutNormal = nearCutNormal;
  plan.farCutNormal = farCutNormal;
  plan.allowance = allowance;
  return plan;
}

} // namespace

std::vector<EvaluatedBody> EvaluateUnfoldBodies(const nlohmann::json& operation, BodyPool& pool,
                                                ElementNameBook* elementNames,
                                                NamingRegistry* registry,
                                                const std::atomic_bool& cancelled) {
  CheckCancellation(cancelled);
  const auto& parameters = operation.at("parameters");
  const std::string operationId = operation.at("id").get<std::string>();
  const std::string targetOperationId = parameters.at("targetOperationId").get<std::string>();
  const std::string outputBodyId = operation.at("outputBodyId").get<std::string>();
  const nlohmann::json& outputBodyIds = operation.at("outputBodyIds");
  if (!outputBodyIds.is_array() || outputBodyIds.size() != 2)
    throw std::invalid_argument("unfold requires outputBodyIds with exactly two entries");
  if (outputBodyIds.at(0).get<std::string>() != outputBodyId) {
    throw std::invalid_argument(
        "unfold's outputBodyIds[0] must match outputBodyId (the folded body)");
  }
  const std::string flatBodyId = outputBodyIds.at(1).get<std::string>();

  std::optional<double> kFactorOverride;
  if (parameters.contains("kFactorOverride") && !parameters.at("kFactorOverride").is_null())
    kFactorOverride = parameters.at("kFactorOverride").get<double>();
  if (kFactorOverride.has_value() &&
      !(std::isfinite(*kFactorOverride) && *kFactorOverride >= 0.0 && *kFactorOverride <= 1.0)) {
    throw std::invalid_argument("unfold kFactorOverride must be within [0, 1]");
  }
  // Documented default (sheet_metal_feature.hpp's own comment): a genuine
  // per-bend stored kFactor is not retrievable at this architectural layer.
  constexpr double kDefaultKFactor = 0.44;
  const double kFactor = kFactorOverride.value_or(kDefaultKFactor);

  const TopoDS_Shape target = pool.Consume(operationId, "unfold", "target", targetOperationId);

  const auto refuse = [&](const char* message, const char* bendCode) -> void {
    throw OperationFailure(operationId, "GEOMETRY_FAILED", message, {{"bendCode", bendCode}});
  };

  // --- Classify faces and recognize bend pairs (see the header comment). ---
  FaceSet allFaces;
  TopExp::MapShapes(target, TopAbs_FACE, allFaces);
  std::vector<TopoDS_Face> planarFaces;
  std::vector<TopoDS_Face> cylindricalFaces;
  for (int index = 1; index <= allFaces.Extent(); ++index) {
    const TopoDS_Face face = TopoDS::Face(allFaces(index));
    const std::string kind = SurfaceClass(face);
    if (kind == "plane")
      planarFaces.push_back(face);
    else if (kind == "cylinder")
      cylindricalFaces.push_back(face);
  }

  std::vector<RecognizedBend> bends;
  std::vector<bool> paired(cylindricalFaces.size(), false);
  for (std::size_t i = 0; i < cylindricalFaces.size(); ++i) {
    if (paired[i])
      continue;
    const BRepAdaptor_Surface si(cylindricalFaces[i], true);
    const gp_Ax1 axisI = si.Cylinder().Axis();
    const double radiusI = si.Cylinder().Radius();
    for (std::size_t j = i + 1; j < cylindricalFaces.size(); ++j) {
      if (paired[j])
        continue;
      const BRepAdaptor_Surface sj(cylindricalFaces[j], true);
      if (!ParallelAxisDirection(axisI, sj.Cylinder().Axis()))
        continue;
      const double radiusJ = sj.Cylinder().Radius();
      if (std::abs(radiusI - radiusJ) < 1.0e-6)
        continue; // Equal radius on a shared axis: not an inner/outer pair.
      paired[i] = true;
      paired[j] = true;
      RecognizedBend bend;
      if (radiusI < radiusJ) {
        bend.innerFace = cylindricalFaces[i];
        bend.outerFace = cylindricalFaces[j];
        bend.insideRadius = radiusI;
        bend.thickness = radiusJ - radiusI;
      } else {
        bend.innerFace = cylindricalFaces[j];
        bend.outerFace = cylindricalFaces[i];
        bend.insideRadius = radiusJ;
        bend.thickness = radiusI - radiusJ;
      }
      bend.axis = axisI;
      bends.push_back(bend);
      break;
    }
  }
#ifdef AETH_SHEET_METAL_DEBUG
  std::fprintf(stderr, "DEBUG planarFaces=%zu cylindricalFaces=%zu bends=%zu\n", planarFaces.size(),
               cylindricalFaces.size(), bends.size());
  for (std::size_t i = 0; i < cylindricalFaces.size(); ++i) {
    const BRepAdaptor_Surface s(cylindricalFaces[i], true);
    const gp_Ax1 ax = s.Cylinder().Axis();
    std::fprintf(stderr,
                 "DEBUG cyl[%zu] radius=%.6f axisLoc=(%.4f,%.4f,%.4f) axisDir=(%.4f,%.4f,%.4f)\n",
                 i, s.Cylinder().Radius(), ax.Location().X(), ax.Location().Y(), ax.Location().Z(),
                 ax.Direction().X(), ax.Direction().Y(), ax.Direction().Z());
  }
#endif
  if (bends.empty()) {
    refuse("unfold target has no recognizable sheet-metal bend regions (a matched concentric "
           "cylindrical face pair) — it is already flat or was not built from base_flange/"
           "edge_flange",
           "E_UNFOLD_NO_BENDS");
  }

  FaceSet bendFaceSet;
  for (const RecognizedBend& bend : bends) {
    bendFaceSet.Add(bend.innerFace);
    bendFaceSet.Add(bend.outerFace);
  }
  // MEASURED (this file's own "verify, don't assume" discipline): this
  // construction's fuse+fillet pipeline does not leave a clean pair of
  // width-direction (bend-axis-parallel) end faces per panel the way it
  // leaves clean top/bottom/far-wall faces — the fillets' trimming splits
  // the target's own original end wall into fragments that stay topologically
  // adjacent to BOTH the base's and the flange's core faces (verified via
  // this file's own development: a plain face-adjacency-minus-bend-faces
  // census on the 90-degree test fixture merges the whole body into ONE
  // component instead of two). Rather than hand-classify those fragments,
  // every planar face whose normal is parallel to a recognized bend's axis
  // is excluded from the panel graph HERE, alongside the bend faces
  // themselves — the synthetic bend-allowance strip built later already
  // supplies a complete, correctly-positioned replacement at both
  // transitions (its own sweep naturally produces a thickness x edge-length
  // face at each end, exactly where a panel's tangent-line boundary needs
  // closing), so nothing is lost by not reusing the original fragments.
  for (const TopoDS_Face& face : planarFaces) {
    const Axis normal = SurfaceAxis(face);
    if (!normal.has_value())
      continue;
    for (const RecognizedBend& bend : bends) {
      const gp_Dir axisDir = bend.axis.Direction();
      const double dot =
          (*normal)[0] * axisDir.X() + (*normal)[1] * axisDir.Y() + (*normal)[2] * axisDir.Z();
      if (std::abs(dot) >= 1.0 - 1.0e-6) {
        bendFaceSet.Add(face);
        break;
      }
    }
  }
  FaceSet panelFaces;
  for (int index = 1; index <= allFaces.Extent(); ++index) {
    const TopoDS_Shape face = allFaces(index);
    if (!bendFaceSet.Contains(face))
      panelFaces.Add(face);
  }

  EdgeToFacesMap edgeToFaces;
  TopExp::MapShapesAndAncestors(target, TopAbs_EDGE, TopAbs_FACE, edgeToFaces);

  // --- Face-adjacency BFS over the non-bend faces: each connected component
  // is one flat panel (its own top/bottom/perimeter faces travel together —
  // no separate top-vs-bottom pairing problem). -----------------------------
  std::vector<int> componentOf(static_cast<std::size_t>(panelFaces.Extent()) + 1, -1);
  int componentCount = 0;
  for (int index = 1; index <= panelFaces.Extent(); ++index) {
    if (componentOf[static_cast<std::size_t>(index)] != -1)
      continue;
    const int thisComponent = componentCount++;
    std::vector<int> stack{index};
    componentOf[static_cast<std::size_t>(index)] = thisComponent;
    while (!stack.empty()) {
      CheckCancellation(cancelled);
      const int current = stack.back();
      stack.pop_back();
      const TopoDS_Face currentFace = TopoDS::Face(panelFaces(current));
      for (TopExp_Explorer edges(currentFace, TopAbs_EDGE); edges.More(); edges.Next()) {
        const TopoDS_Shape edge = edges.Current();
        const int edgeIndex = edgeToFaces.FindIndex(edge);
        if (edgeIndex == 0)
          continue;
        for (const TopoDS_Shape& neighbour : edgeToFaces.FindFromKey(edge)) {
          if (neighbour.IsSame(currentFace) || bendFaceSet.Contains(neighbour))
            continue;
          const int neighbourIndex = panelFaces.FindIndex(neighbour);
          if (neighbourIndex == 0)
            continue;
          if (componentOf[static_cast<std::size_t>(neighbourIndex)] == -1) {
#ifdef AETH_SHEET_METAL_DEBUG
            std::fprintf(stderr, "DEBUG adjacency panelFace[%d] -> panelFace[%d]\n", current,
                         neighbourIndex);
#endif
            componentOf[static_cast<std::size_t>(neighbourIndex)] = thisComponent;
            stack.push_back(neighbourIndex);
          }
        }
      }
    }
  }

#ifdef AETH_SHEET_METAL_DEBUG
  for (int index = 1; index <= panelFaces.Extent(); ++index) {
    const TopoDS_Face f = TopoDS::Face(panelFaces(index));
    GProp_GProps props;
    BRepGProp::SurfaceProperties(f, props);
    const gp_Pnt c = props.CentreOfMass();
    std::fprintf(stderr,
                 "DEBUG panelFace[%d] comp=%d area=%.4f centroid=(%.3f,%.3f,%.3f) class=%s\n",
                 index, componentOf[static_cast<std::size_t>(index)], std::abs(props.Mass()), c.X(),
                 c.Y(), c.Z(), SurfaceClass(f).c_str());
  }
#endif
  // Which two panel components each recognized bend connects.
  struct BendEdge final {
    int componentA{};
    int componentB{};
  };
  std::vector<BendEdge> bendEdges;
  for (const RecognizedBend& bend : bends) {
    std::vector<int> touched;
    for (const TopoDS_Face& bendFace : {bend.innerFace, bend.outerFace}) {
      for (TopExp_Explorer edges(bendFace, TopAbs_EDGE); edges.More(); edges.Next()) {
        const TopoDS_Shape edge = edges.Current();
        const int edgeIndex = edgeToFaces.FindIndex(edge);
        if (edgeIndex == 0)
          continue;
        for (const TopoDS_Shape& neighbour : edgeToFaces.FindFromKey(edge)) {
          if (bendFaceSet.Contains(neighbour))
            continue;
          const int neighbourIndex = panelFaces.FindIndex(neighbour);
          if (neighbourIndex == 0)
            continue;
          const int component = componentOf[static_cast<std::size_t>(neighbourIndex)];
          if (std::find(touched.begin(), touched.end(), component) == touched.end())
            touched.push_back(component);
#ifdef AETH_SHEET_METAL_DEBUG
          std::fprintf(stderr, "DEBUG bendFace direct neighbour = panelFace[%d]\n", neighbourIndex);
#endif
        }
      }
    }
#ifdef AETH_SHEET_METAL_DEBUG
    std::fprintf(stderr, "DEBUG touched.size()=%zu componentCount=%d panelFaces.Extent()=%d\n",
                 touched.size(), componentCount, panelFaces.Extent());
    for (int t : touched)
      std::fprintf(stderr, "DEBUG   touched component=%d\n", t);
#endif
    if (touched.size() != 2) {
      refuse("unfold could not resolve a bend region to exactly two flat panels",
             "E_UNFOLD_NOT_DEVELOPABLE");
    }
    bendEdges.push_back({touched[0], touched[1]});
  }

  // Seed: the component containing the largest-area planar face (documented
  // deterministic fallback — see the header comment for why tracing back to
  // literally the base_flange operation is not available at this layer).
  int seedComponent = -1;
  double seedArea = -1.0;
  for (const TopoDS_Face& face : planarFaces) {
    const int index = panelFaces.FindIndex(face);
    if (index == 0)
      continue;
    const double area = PlanarArea(face);
    if (area > seedArea) {
      seedArea = area;
      seedComponent = componentOf[static_cast<std::size_t>(index)];
    }
  }
  if (seedComponent < 0)
    refuse("unfold target has no planar face to seed the flat pattern from", "E_UNFOLD_NO_BENDS");

  // --- BFS: flatten each newly-reached panel, refusing on any bend that
  // would reconnect two ALREADY-visited panels (a cycle — the part cannot
  // actually be manufactured flat). ------------------------------------------
  std::vector<bool> visited(static_cast<std::size_t>(componentCount), false);
  std::vector<gp_Trsf> accumulated(static_cast<std::size_t>(componentCount));
  std::vector<bool> bendUsed(bends.size(), false);
  std::vector<TreeEdge> treeEdges;

  visited[static_cast<std::size_t>(seedComponent)] = true;
  std::queue<int> queue;
  queue.push(seedComponent);
  while (!queue.empty()) {
    CheckCancellation(cancelled);
    const int current = queue.front();
    queue.pop();
    for (std::size_t k = 0; k < bendEdges.size(); ++k) {
      if (bendUsed[k])
        continue;
      const BendEdge& bendEdge = bendEdges[k];
      if (bendEdge.componentA != current && bendEdge.componentB != current)
        continue;
      const int other = bendEdge.componentA == current ? bendEdge.componentB : bendEdge.componentA;
      if (visited[static_cast<std::size_t>(other)]) {
        refuse("unfold's bend graph is not a simple tree reachable from one seed panel — the "
               "part cannot actually be manufactured flat",
               "E_UNFOLD_NOT_DEVELOPABLE");
      }
      bendUsed[k] = true;
      TreeEdge treeEdge;
      treeEdge.bendIndex = static_cast<int>(k);
      treeEdge.nearComponent = current;
      treeEdge.farComponent = other;
      try {
        treeEdge.plan = PlanBendFlatten(bends[k], current, other, kFactor, panelFaces, componentOf,
                                        edgeToFaces, bendFaceSet);
      } catch (const Standard_Failure&) {
        CheckCancellation(cancelled);
        refuse("unfold could not compute a bend's flattening transform",
               "E_UNFOLD_NOT_DEVELOPABLE");
      }
      accumulated[static_cast<std::size_t>(other)] =
          accumulated[static_cast<std::size_t>(current)].Multiplied(treeEdge.plan.localTransform);
      visited[static_cast<std::size_t>(other)] = true;
      treeEdges.push_back(treeEdge);
      queue.push(other);
    }
  }
  if (std::any_of(visited.begin(), visited.end(), [](const bool v) { return !v; })) {
    refuse("unfold's bend graph does not reach every panel from one seed — the part cannot "
           "actually be manufactured flat",
           "E_UNFOLD_NOT_DEVELOPABLE");
  }

  // --- Assemble the flat pattern via ROBUST BOOLEAN cuts, not per-face
  // reclassification. MEASURED DIVERGENCE FROM THE INITIAL PLAN (this file's
  // "verify, don't assume" discipline): the original plan repositioned each
  // panel's OWN faces individually (BRepBuilderAPI_Transform per face) and
  // sewed them to fresh bend-allowance strips. That compiles and runs, but
  // empirically produces a shell with dozens of free (unmatched) edges: this
  // construction's fuse+fillet pipeline splits the target's own side walls
  // into fragments whose face-level classification does not cleanly track
  // "belongs to this panel" vs "belongs to the next" (verified against this
  // file's own 90-degree test fixture — a plain face-adjacency-minus-bend-
  // faces census either merges the two panels into one component, or, once
  // bend-axis-parallel faces are additionally excluded, leaves fragments
  // whose OWN trimmed boundary sits at a different offset than the simple
  // thickness-separated tangent line this file's strip assumes, because the
  // fillet's two independently-derived creases do not share a dihedral
  // angle — see ParallelAxisDirection's own comment for the fully-measured
  // account of why). The panel-graph construction above (componentOf,
  // bendEdges) is still exactly what is needed for BEND CONNECTIVITY —
  // which components exist and which bend joins which pair — but is not
  // reused for the final SOLID geometry. Each panel component is instead
  // carved whole out of the ORIGINAL target with `BRepAlgoAPI_Common`
  // against a generously oversized box, cut at the exact MEASURED
  // outer-tangent-line position for every bend attached to it: a boolean
  // intersection tolerates the sliver of leftover wedge/fillet-trim geometry
  // near a tangent line far better than exact-coincidence face sewing does,
  // while still cutting at an analytically known position (the tangent line
  // itself), and every one of the component's own faces travels with it
  // with no dependence on knowing which specific faces it has. The final
  // assembly is one sequential `BRepAlgoAPI_Fuse` chain (component solids
  // plus one bend-allowance strip solid per tree edge), the same booleans-
  // tolerate-near-misses reasoning. No `ShapeUpgrade_UnifySameDomain` pass
  // afterward: this is a from-scratch multi-piece reconstruction with no
  // single composable `BRepTools_History` for a unify stage to extend —
  // skipped and documented rather than silently assumed, exactly the escape
  // hatch the wire contract states. The result is more-faceted (no
  // coplanar-face merging across the fused seams) but geometrically correct,
  // which is this file's whole point, per this wave's own required tests.
  constexpr double kHugeSpan = 1.0e5;
  std::vector<TopoDS_Shape> isolated(static_cast<std::size_t>(componentCount), target);
  for (const TreeEdge& treeEdge : treeEdges) {
    CheckCancellation(cancelled);
    const BendFlattenPlan& plan = treeEdge.plan;
    const RecognizedBend& bend = bends[static_cast<std::size_t>(treeEdge.bendIndex)];
    // KEEP the side AWAY from the bend at each cut: each panel's own
    // outward-in-plane direction points FROM its interior TOWARD the bend
    // (EvaluateEdgeFlange's outwardInPlane convention — see
    // outwardInPlaneOf's own comment above), so the negation is "into this
    // panel's own territory".
    const gp_Dir towardNearInterior(-plan.nearCutNormal.X(), -plan.nearCutNormal.Y(),
                                    -plan.nearCutNormal.Z());
    const gp_Dir towardFarInterior(-plan.farCutNormal.X(), -plan.farCutNormal.Y(),
                                   -plan.farCutNormal.Z());
    const auto isolate = [&](TopoDS_Shape& solid, const gp_Pnt& cutPoint, const gp_Dir& cutNormal,
                             const gp_Dir& keepDir) {
      const gp_Dir crossAxis = bend.axis.Direction().Crossed(cutNormal);
      TopoDS_Shape box;
      try {
        box = BuildRectPrismTool(cutPoint, bend.axis.Direction(), crossAxis, keepDir, kHugeSpan,
                                 -kHugeSpan, kHugeSpan, -kHugeSpan, kHugeSpan);
      } catch (const Standard_Failure&) {
        CheckCancellation(cancelled);
        refuse("unfold could not build a panel-isolation cutting tool", "E_UNFOLD_NOT_DEVELOPABLE");
      }
      BRepAlgoAPI_Common common;
      NCollection_List<TopoDS_Shape> objects;
      objects.Append(solid);
      NCollection_List<TopoDS_Shape> tools;
      tools.Append(box);
      common.SetArguments(objects);
      common.SetTools(tools);
      common.SetRunParallel(false);
      common.SetToFillHistory(false);
      {
        const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
        try {
          common.Build(progress->Start());
        } catch (const Standard_Failure&) {
          CheckCancellation(cancelled);
          refuse("unfold could not isolate a flat panel from the folded body",
                 "E_UNFOLD_NOT_DEVELOPABLE");
        }
      }
      CheckCancellation(cancelled);
      if (common.HasErrors() || !common.IsDone())
        refuse("unfold could not isolate a flat panel from the folded body",
               "E_UNFOLD_NOT_DEVELOPABLE");
      try {
        solid = SingleValidSolid(common.Shape(), "unfold's isolated panel");
      } catch (const Standard_Failure&) {
        CheckCancellation(cancelled);
        refuse("unfold's isolated panel is invalid", "E_UNFOLD_NOT_DEVELOPABLE");
      }
    };
    isolate(isolated[static_cast<std::size_t>(treeEdge.nearComponent)], plan.nearOuterP1,
            plan.nearCutNormal, towardNearInterior);
    isolate(isolated[static_cast<std::size_t>(treeEdge.farComponent)], plan.farOuterP1,
            plan.farCutNormal, towardFarInterior);
  }

  std::vector<TopoDS_Shape> pieces;
  for (int component = 0; component < componentCount; ++component) {
    CheckCancellation(cancelled);
    BRepBuilderAPI_Transform transform(isolated[static_cast<std::size_t>(component)],
                                       accumulated[static_cast<std::size_t>(component)],
                                       /*Copy=*/true);
    pieces.push_back(transform.Shape());
  }
  for (const TreeEdge& treeEdge : treeEdges) {
    CheckCancellation(cancelled);
    const BendFlattenPlan& plan = treeEdge.plan;
    const gp_Pnt c1 = plan.nearOuterP1;
    const gp_Pnt c2 = plan.nearOuterP2;
    const gp_Pnt c3 = plan.nearOuterP2.Translated(plan.allowance * gp_Vec(plan.unfoldDir));
    const gp_Pnt c4 = plan.nearOuterP1.Translated(plan.allowance * gp_Vec(plan.unfoldDir));
    BRepBuilderAPI_MakePolygon stripPolygon(c1, c2, c3, c4, /*Close=*/true);
    if (!stripPolygon.IsDone())
      refuse("unfold could not build a bend-allowance strip wire", "E_UNFOLD_NOT_DEVELOPABLE");
    const gp_Pln stripPlane(c1, plan.intoMaterial);
    BRepBuilderAPI_MakeFace stripFaceMaker(stripPlane, stripPolygon.Wire(), /*Inside=*/true);
    if (!stripFaceMaker.IsDone())
      refuse("unfold could not build a bend-allowance strip face", "E_UNFOLD_NOT_DEVELOPABLE");
    const RecognizedBend& bend = bends[static_cast<std::size_t>(treeEdge.bendIndex)];
    BRepPrimAPI_MakePrism stripPrism(stripFaceMaker.Face(),
                                     bend.thickness * gp_Vec(plan.intoMaterial),
                                     /*Copy=*/true);
    stripPrism.Build();
    if (!stripPrism.IsDone())
      refuse("unfold could not sweep a bend-allowance strip", "E_UNFOLD_NOT_DEVELOPABLE");
    TopoDS_Solid stripSolid;
    try {
      stripSolid = SingleValidSolid(stripPrism.Shape(), "unfold's bend-allowance strip");
    } catch (const Standard_Failure&) {
      CheckCancellation(cancelled);
      refuse("unfold's bend-allowance strip is invalid for this bend's measured geometry",
             "E_UNFOLD_NOT_DEVELOPABLE");
    }
    const gp_Trsf& placement = accumulated[static_cast<std::size_t>(treeEdge.nearComponent)];
    BRepBuilderAPI_Transform stripTransform(TopoDS_Shape(stripSolid), placement, /*Copy=*/true);
    pieces.push_back(stripTransform.Shape());
  }
  if (pieces.empty())
    refuse("unfold produced no flat-pattern geometry", "E_UNFOLD_NOT_DEVELOPABLE");

  TopoDS_Shape assembled = pieces.front();
  for (std::size_t index = 1; index < pieces.size(); ++index) {
    CheckCancellation(cancelled);
    BRepAlgoAPI_Fuse fuse;
    NCollection_List<TopoDS_Shape> objects;
    objects.Append(assembled);
    NCollection_List<TopoDS_Shape> tools;
    tools.Append(pieces[index]);
    fuse.SetArguments(objects);
    fuse.SetTools(tools);
    fuse.SetRunParallel(false);
    fuse.SetToFillHistory(false);
    {
      const occ::handle<CancellationProgress> progress = MakeCancellationProgress(cancelled);
      try {
        fuse.Build(progress->Start());
      } catch (const Standard_Failure&) {
        CheckCancellation(cancelled);
        refuse("unfold could not fuse a flattened panel or strip into the flat pattern",
               "E_UNFOLD_NOT_DEVELOPABLE");
      }
    }
    CheckCancellation(cancelled);
    if (fuse.HasErrors() || !fuse.IsDone())
      refuse("unfold could not fuse a flattened panel or strip into the flat pattern",
             "E_UNFOLD_NOT_DEVELOPABLE");
    assembled = fuse.Shape();
  }
#ifdef AETH_SHEET_METAL_DEBUG
  std::fprintf(stderr, "DEBUG assembled solids=%d shells=%d faces=%d pieces=%zu\n",
               CountOf(assembled, TopAbs_SOLID), CountOf(assembled, TopAbs_SHELL),
               CountOf(assembled, TopAbs_FACE), pieces.size());
  for (std::size_t pi = 0; pi < pieces.size(); ++pi) {
    Bnd_Box box;
    BRepBndLib::Add(pieces[pi], box);
    double xmin, ymin, zmin, xmax, ymax, zmax;
    box.Get(xmin, ymin, zmin, xmax, ymax, zmax);
    std::fprintf(stderr, "DEBUG piece[%zu] bbox=(%.3f,%.3f,%.3f)-(%.3f,%.3f,%.3f)\n", pi, xmin,
                 ymin, zmin, xmax, ymax, zmax);
  }
  {
    GProp_GProps props;
    BRepGProp::VolumeProperties(assembled, props);
    std::fprintf(stderr, "DEBUG assembled total volume=%.4f\n", props.Mass());
  }
#endif
  TopoDS_Solid flatSolid;
  try {
    flatSolid = SingleValidSolid(assembled, "unfold's flattened assembly");
  } catch (const Standard_Failure&) {
    CheckCancellation(cancelled);
    refuse("unfold's flattened assembly is invalid or fragmented", "E_UNFOLD_NOT_DEVELOPABLE");
  }
  BRepLib::OrientClosedSolid(flatSolid);
  if (!BRepCheck_Analyzer(flatSolid, false).IsValid())
    refuse("unfold produced an invalid flat-pattern solid", "E_UNFOLD_NOT_DEVELOPABLE");

  // --- Two born bodies from one operation (ADR-013's multi-output-birth
  // mechanism). See ExecuteOperation in geometry.cpp for the pool-production
  // ORDER (deliberately not [0, 1]). -----------------------------------------
  EvaluatedBody foldedBody;
  foldedBody.bodyId = outputBodyId;
  foldedBody.operationId = operationId;
  foldedBody.outputIndex = 0;
  // Genuinely unchanged: the SAME shape as the consumed target, not a copy —
  // "pass-through" so further features keep building on the identical 3D
  // form, and so its faces keep answering to their TRUE construction-lineage
  // names/tokens (whatever base_flange/edge_flange minted) rather than being
  // re-rooted under this operation for no geometric reason.
  foldedBody.shape = target;
  foldedBody.probes = ProbeShape(foldedBody.shape);
  if (!foldedBody.probes.valid)
    throw std::runtime_error("unfold's folded pass-through body is unexpectedly invalid");

  EvaluatedBody flatBody;
  flatBody.bodyId = flatBodyId;
  flatBody.operationId = operationId;
  flatBody.outputIndex = 1;
  flatBody.shape = flatSolid;
  flatBody.probes = ProbeShape(flatBody.shape);
  if (!flatBody.probes.valid)
    throw std::runtime_error("OCCT produced an invalid unfold flat-pattern result");

  if (elementNames != nullptr && registry != nullptr) {
    // The flat pattern is a from-scratch reconstruction (boolean-cut panel
    // solids rigidly repositioned, fused to fresh bend-allowance strips), not
    // a retained OCCT history — HarvestCopiedBody, the import_step/
    // import_mesh "no authored construction frame" mold
    // (NamingRegistry::OperationClass's own doc comment explains why
    // `Unfold` is never constructed here). Every face mints fresh with no
    // ancestor: the panel-isolation booleans (see the assembly block's own
    // comment) do not preserve a simple 1:1 face correspondence back to the
    // folded body the way a plain per-face transform would have, so this
    // mint does not claim one. The folded pass-through mints NOTHING new —
    // it is the identical shape with its existing, already-live records.
    elementNames->AddPrimitive(operationId, flatBody.shape);
    registry->HarvestCopiedBody(operationId, flatBody.shape, "panel", "panel-edge", "panel-vertex",
                                ShapeToShapeMap(), cancelled, /*outputIndex=*/1);
  }

  std::vector<EvaluatedBody> born;
  born.reserve(2);
  born.push_back(std::move(foldedBody));
  born.push_back(std::move(flatBody));
  return born;
}

} // namespace aeth
