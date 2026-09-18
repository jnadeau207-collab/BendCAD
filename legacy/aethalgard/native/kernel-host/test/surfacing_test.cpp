// Native integration tests for the Surfacing domain — boundary_surface,
// surface_offset, stitch, thicken (native/kernel-host only; the
// geometry-contracts schema layer is landed independently against the same
// wire field names). Exercises both the standalone Evaluate* entry points
// directly (surfacing_feature.hpp) against hand-built OCCT fixtures no
// existing JSON primitive can produce (an open shell/face), AND the full
// ExecuteOperation dispatch via EvaluateOperations for the refusal paths that
// only need a create_box target — proving the geometry.cpp dispatch wiring
// itself, not just the standalone functions. Every numeric assertion is
// independently hand-derived in a comment beside it (this repo's own
// standard, set by sheet_metal_test.cpp, which caught a real bug in the test
// file itself this way) — never copied from what surfacing_feature.cpp
// computes.
//
//   1. boundary_surface: (a) a box missing its top face -> the fill's area is
//      EXACTLY width*depth, and sewing the fill back onto the other 5 faces
//      (independent BRepBuilderAPI_Sewing, not this repo's own `stitch`)
//      recovers the box's exact original volume; (b) a box with 3
//      mutually-adjacent faces removed -> a genuinely NON-planar hexagonal
//      boundary loop (proved non-coplanar by hand below), whose fill closes
//      cleanly when sewn back (zero free edges) and whose boundary vertices
//      exactly match the 6 known box corners; (c) an already-closed box and
//      an open box with a disconnected boundary both refuse
//      E_BOUNDARY_SURFACE_NOT_CLOSED.
//   2. surface_offset: a planar rectangle offset by a known signed distance
//      lands EXACTLY on the parallel plane at that distance, area preserved;
//      zero distance refuses before any OCCT call; a solid target refuses
//      E_SURFACE_OFFSET_NOT_SURFACE (through full dispatch); a cylindrical
//      face offset past its own radius toward the axis refuses
//      E_SURFACE_OFFSET_SELF_INTERSECTS while offsetting outward by the same
//      magnitude succeeds at the exact hand-derived radius.
//   3. stitch: (a) two rectangles sharing one edge stitch into one open
//      2-face shell whose total area is EXACTLY the sum of both; (b) two
//      complementary 3-face box halves (sharing the SAME hexagonal boundary
//      as 1(b)) stitch into the box's own exact closed volume; (c) two
//      disjoint bodies refuse E_STITCH_NO_COMMON_BOUNDARY, through full
//      dispatch.
//   4. thicken: a planar rectangle thickened normal/reverse/symmetric each
//      produce EXACTLY width*depth*thickness, with the bounding box landing
//      where each direction mode implies (symmetric centered exactly on the
//      source surface, normal/reverse each keeping the source surface as one
//      wall, on opposite sides of each other); a solid target refuses
//      E_THICKEN_NOT_SURFACE (through full dispatch); a cylindrical face
//      thickened past its own radius toward the axis refuses
//      E_THICKEN_SELF_INTERSECTS while thickening outward by the same
//      magnitude succeeds at the exact hand-derived annulus volume.
//   5. Naming/registry: every operation's naming path (real HarvestOperation
//      for thicken normal/reverse; fresh-mint AddDerivedPrimitive for the
//      other three and for thicken symmetric; the surface_offset fail-closed
//      guard) is exercised against a real NamingRegistry, not merely
//      asserted in a comment.
//   6. Tessellation and STEP export/reimport of an open shape produced by
//      this file's own executors, proving both pipelines are genuinely
//      shape-agnostic rather than assuming it.
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <string>
#include <vector>

#include <BRepAdaptor_Surface.hxx>
#include <BRepBuilderAPI_MakeEdge.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <BRepBuilderAPI_MakePolygon.hxx>
#include <BRepBuilderAPI_MakeWire.hxx>
#include <BRepBuilderAPI_Sewing.hxx>
#include <BRepCheck_Analyzer.hxx>
#include <BRepGProp.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakeCylinder.hxx>
#include <BRep_Builder.hxx>
#include <BRep_Tool.hxx>
#include <GProp_GProps.hxx>
#include <NCollection_IndexedMap.hxx>
#include <Precision.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shell.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Dir.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <gp_Vec.hxx>
#include <nlohmann/json.hpp>

#include "body_pool.hpp"
#include "element_names.hpp"
#include "geometry.hpp"
#include "geometry_measures.hpp"
#include "naming_registry.hpp"
#include "surfacing_feature.hpp"
#include "tessellate.hpp"

namespace {

int g_failures = 0;

void check(const bool condition, const std::string& label) {
  if (condition) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s\n", label.c_str());
    g_failures += 1;
  }
}

void checkNear(const double actual, const double expected, const double tolerance,
               const std::string& label) {
  if (std::abs(actual - expected) <= tolerance) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s (expected %.6f, got %.6f)\n", label.c_str(), expected, actual);
    g_failures += 1;
  }
}

constexpr double kPi = 3.14159265358979323846;

using aeth::BodyPool;
using aeth::EvaluatedBody;

// --- Fixture builders (independent of surfacing_feature.cpp's own code —
// these are stock OCCT primitives assembled by hand). -----------------------

/// A standalone planar rectangular face: `corner` + u in [0,uLen] + v in
/// [0,vLen], outward normal = uDir x vDir (BRepBuilderAPI_MakeFace keeps the
/// FORWARD orientation of a freshly-built face matching the plane's own
/// geometric normal, so this is exact, not merely expected).
TopoDS_Face RectFace(const gp_Pnt& corner, const gp_Dir& uDir, const gp_Dir& vDir,
                     const double uLen, const double vLen) {
  const gp_Vec u(uDir);
  const gp_Vec v(vDir);
  BRepBuilderAPI_MakePolygon polygon;
  polygon.Add(corner);
  polygon.Add(corner.Translated(uLen * u));
  polygon.Add(corner.Translated(uLen * u + vLen * v));
  polygon.Add(corner.Translated(vLen * v));
  polygon.Close();
  const gp_Dir normal = uDir.Crossed(vDir);
  const gp_Pln plane(corner, normal);
  BRepBuilderAPI_MakeFace faceMaker(plane, polygon.Wire(), true);
  if (!faceMaker.IsDone())
    throw std::runtime_error("test fixture: RectFace construction failed");
  return faceMaker.Face();
}

/// Every face of `box` whose outward normal is the given axis-aligned
/// direction (dot >= 0.999 against `axis`).
TopoDS_Face BoxFaceByNormal(const TopoDS_Shape& box, const gp_Dir& axis) {
  for (TopExp_Explorer explorer(box, TopAbs_FACE); explorer.More(); explorer.Next()) {
    const TopoDS_Face face = TopoDS::Face(explorer.Current());
    const BRepAdaptor_Surface surface(face, true);
    const aeth::Axis normal = aeth::PlanarOutwardNormal(face, surface);
    if (normal.has_value() &&
        (*normal)[0] * axis.X() + (*normal)[1] * axis.Y() + (*normal)[2] * axis.Z() > 0.999) {
      return face;
    }
  }
  throw std::runtime_error("test fixture: box has no face with the requested outward normal");
}

/// A TopoDS_Shell built from exactly `faces` (BRep_Builder::Add, no sewing —
/// the faces already share exact topology since they come from the SAME
/// source box).
TopoDS_Shape ShellOf(const std::vector<TopoDS_Face>& faces) {
  BRep_Builder builder;
  TopoDS_Shell shell;
  builder.MakeShell(shell);
  for (const TopoDS_Face& face : faces)
    builder.Add(shell, face);
  return shell;
}

/// Box [0,w]x[0,d]x[0,h], corner-anchored at the origin (BRepPrimAPI_MakeBox's
/// own convention), as the 6 discrete outward-normal-classified faces so
/// callers can pick subsets by axis.
struct BoxFaces final {
  TopoDS_Face negX, posX, negY, posY, negZ, posZ;
};

BoxFaces MakeBoxFaces(const double w, const double d, const double h) {
  BRepPrimAPI_MakeBox maker(w, d, h);
  const TopoDS_Shape box = maker.Shape();
  BoxFaces faces;
  faces.negX = BoxFaceByNormal(box, gp_Dir(-1, 0, 0));
  faces.posX = BoxFaceByNormal(box, gp_Dir(1, 0, 0));
  faces.negY = BoxFaceByNormal(box, gp_Dir(0, -1, 0));
  faces.posY = BoxFaceByNormal(box, gp_Dir(0, 1, 0));
  faces.negZ = BoxFaceByNormal(box, gp_Dir(0, 0, -1));
  faces.posZ = BoxFaceByNormal(box, gp_Dir(0, 0, 1));
  return faces;
}

/// `shape` as a single TopoDS_Face — either it already is one, or it is a
/// TopAbs_SHELL wrapping exactly one (BRepOffsetAPI_MakeOffsetShape's own
/// result typing for a single-face input is not assumed here; this file
/// takes whichever it actually returns).
TopoDS_Face SingleFaceOf(const TopoDS_Shape& shape) {
  if (shape.ShapeType() == TopAbs_FACE)
    return TopoDS::Face(shape);
  TopExp_Explorer explorer(shape, TopAbs_FACE);
  if (!explorer.More())
    throw std::runtime_error("test fixture: shape has no face");
  return TopoDS::Face(explorer.Current());
}

double FaceArea(const TopoDS_Face& face) {
  GProp_GProps properties;
  BRepGProp::SurfaceProperties(face, properties);
  return std::abs(properties.Mass());
}

aeth::EvaluatedBody MakeFixtureBody(const std::string& operationId, const std::string& bodyId,
                                    const TopoDS_Shape& shape) {
  aeth::EvaluatedBody body;
  body.operationId = operationId;
  body.bodyId = bodyId;
  body.shape = shape;
  body.probes = aeth::ProbeShape(shape);
  return body;
}

nlohmann::json OperationEnvelope(const std::string& id, const std::string& type,
                                 const std::string& outputBodyId, nlohmann::json parameters) {
  return {{"id", id}, {"type", type}, {"outputBodyId", outputBodyId}, {"parameters", parameters}};
}

// --- Refusal harness (the sheet_metal_test.cpp shape). ----------------------

struct Refusal final {
  std::string kind;
  std::string code;
  std::string operationId;
  std::string message;
  nlohmann::json details;
};

/// Runs a full JSON program through the REAL EvaluateOperations/
/// ExecuteOperation dispatch path (registry-threaded), catching every typed
/// refusal this codebase throws.
Refusal RunProgramExpectingRefusal(const nlohmann::json& program) {
  std::atomic_bool cancelled{false};
  try {
    aeth::NamingRegistry registry;
    aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
    return {"none", "", "", "", {}};
  } catch (const aeth::SelectorFailure& error) {
    return {"selector", error.Code(), error.OperationId(), error.what(), error.Details()};
  } catch (const aeth::OperationFailure& error) {
    return {"operation", error.Code(), error.OperationId(), error.what(), error.Details()};
  } catch (const aeth::ReferenceMissing& error) {
    return {"reference-missing", "", error.OperationId(), error.what(), {}};
  } catch (const std::exception& error) {
    return {"other", "", "", error.what(), {}};
  }
}

/// The same full-dispatch path with NO naming/registry threaded at all
/// (both `elementNames` and `namingRegistry` null) — needed for
/// `surface_offset` refusal paths that sit BEHIND its own fail-closed naming
/// guard (see EvaluateSurfaceOffset's own comment): with a registry always
/// threaded, that guard would fire first and mask the refusal under test,
/// exactly the ordering `offset`'s own v1 whole-body path already commits to.
Refusal RunProgramExpectingRefusalNoNaming(const nlohmann::json& program) {
  std::atomic_bool cancelled{false};
  try {
    aeth::EvaluateOperations(program, cancelled, nullptr, nullptr);
    return {"none", "", "", "", {}};
  } catch (const aeth::SelectorFailure& error) {
    return {"selector", error.Code(), error.OperationId(), error.what(), error.Details()};
  } catch (const aeth::OperationFailure& error) {
    return {"operation", error.Code(), error.OperationId(), error.what(), error.Details()};
  } catch (const aeth::ReferenceMissing& error) {
    return {"reference-missing", "", error.OperationId(), error.what(), {}};
  } catch (const std::exception& error) {
    return {"other", "", "", error.what(), {}};
  }
}

/// Calls one Evaluate* function directly against a hand-seeded BodyPool,
/// catching every typed refusal — for fixtures no existing JSON primitive
/// can build (an open shell/face).
template <typename Fn>
Refusal RunDirectExpectingRefusal(BodyPool& pool, const nlohmann::json& operation, Fn&& evaluate) {
  std::atomic_bool cancelled{false};
  try {
    evaluate(operation, pool, cancelled);
    return {"none", "", "", "", {}};
  } catch (const aeth::OperationFailure& error) {
    return {"operation", error.Code(), error.OperationId(), error.what(), error.Details()};
  } catch (const aeth::ReferenceMissing& error) {
    return {"reference-missing", "", error.OperationId(), error.what(), {}};
  } catch (const std::exception& error) {
    return {"other", "", "", error.what(), {}};
  }
}

// --- 1. boundary_surface -----------------------------------------------------

void BoundarySurfacePlanarRectangle() {
  std::printf("boundary_surface caps a box's missing top face with the exact planar area, and "
              "the recapped box recovers its exact original volume:\n");
  constexpr double kW = 30.0, kD = 20.0, kH = 10.0;
  const BoxFaces faces = MakeBoxFaces(kW, kD, kH);
  const TopoDS_Shape openBox =
      ShellOf({faces.negX, faces.posX, faces.negY, faces.posY, faces.negZ});
  check(aeth::ProbeShape(openBox).solidCount == 0,
        "the missing-top-face fixture is open (no solid)");

  BodyPool pool;
  const std::string targetOp = "b0000000-0000-4000-8000-000000000001";
  pool.Produce(MakeFixtureBody(targetOp, "target-body", openBox));

  const nlohmann::json operation =
      OperationEnvelope("b0000000-0000-4000-8000-0000000000f1", "boundary_surface", "fill-body",
                        {{"targetOperationId", targetOp}});
  std::atomic_bool cancelled{false};
  const EvaluatedBody result =
      aeth::EvaluateBoundarySurface(operation, pool, nullptr, nullptr, cancelled);
  check(result.probes.valid && result.probes.faceCount == 1 && result.probes.solidCount == 0,
        "the fill result is one valid open face");
  // Hand-derived: the missing face is the box's own top rim, a planar
  // rectangle of exactly width x depth.
  checkNear(result.probes.surfaceArea, kW * kD, 1e-6, "fill area == width * depth (600)");

  // MEASURED (this check itself): BRepOffsetAPI_MakeFilling does NOT reuse
  // its input constraint edges by IDENTITY in the result face — every
  // boundary edge of the fill face is a FRESH TShape, geometrically
  // coincident with (per the zero-free-edges sewing proof above and the
  // exact-area match) but never IsSame to, any of openBox's own edges. This
  // corrects this file's own original assumption (surfacing_feature.cpp's
  // naming-block comment is written to the verified truth, not the original
  // guess) — AddDerivedPrimitive is still the right, safe naming choice
  // regardless (it degrades to AddPrimitive's own behavior when nothing is
  // shared, exactly as intended), so no production-code change follows from
  // this correction, only a documentation one.
  {
    NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> targetEdges;
    TopExp::MapShapes(openBox, TopAbs_EDGE, targetEdges);
    bool anyFillEdgeIsShared = false;
    int fillEdgeCount = 0;
    for (TopExp_Explorer explorer(result.shape, TopAbs_EDGE); explorer.More(); explorer.Next()) {
      fillEdgeCount += 1;
      if (targetEdges.FindIndex(explorer.Current()) != 0)
        anyFillEdgeIsShared = true;
    }
    check(fillEdgeCount == 4 && !anyFillEdgeIsShared,
          "the fill face's 4 boundary edges are FRESH TShapes (BRepOffsetAPI_MakeFilling rebuilds "
          "its boundary rather than reusing the input edges by identity) — geometrically "
          "coincident, never IsSame");
  }

  // Independent closure proof: sew the fill face back onto the other 5 faces
  // with a PLAIN BRepBuilderAPI_Sewing here in the test (not this file's own
  // `stitch` executor) and confirm the box's exact original volume comes
  // back — this can only happen if the fill's own boundary wire exactly
  // retraces the missing rim, edge for edge.
  BRepBuilderAPI_Sewing sewing(1e-6);
  sewing.Add(openBox);
  sewing.Add(result.shape);
  sewing.Perform();
  const TopoDS_Shape resewn = sewing.SewedShape();
  check(sewing.NbFreeEdges() == 0, "resewing the fill face leaves zero free edges (a genuine "
                                   "watertight recap)");
  // Plain BRepGProp::VolumeProperties directly here, NOT aeth::ProbeShape:
  // raw BRepBuilderAPI_Sewing does not automatically promote a fully-closed
  // shell to TopAbs_SOLID (this file's `stitch` executor does that
  // conversion itself, deliberately, via BRepBuilderAPI_MakeSolid — see
  // ProbeShapeOpenShapeVolumeAndCentroid below for that same distinction
  // tested directly), so ProbeShape's solidCount-gated volume would report
  // exactly 0 here by its own correct, documented contract. The divergence-
  // theorem integral IS still meaningful for THIS shape specifically because
  // this test independently just verified its manifold closure one line
  // above (NbFreeEdges() == 0) — this is the one place in this file that
  // is entitled to bypass ProbeShape's conservative default.
  GProp_GProps resewnVolume;
  BRepGProp::VolumeProperties(resewn, resewnVolume);
  checkNear(std::abs(resewnVolume.Mass()), kW * kD * kH, 1e-3,
            "resewn box volume == width * depth * height (6000), the exact original box");
}

void BoundarySurfaceNonPlanarHexagon() {
  std::printf("boundary_surface fills a genuinely NON-PLANAR hexagonal loop (3 mutually-"
              "adjacent box faces removed):\n");
  constexpr double kW = 30.0, kD = 20.0, kH = 10.0;
  const BoxFaces faces = MakeBoxFaces(kW, kD, kH);
  // Keep only the 3 faces touching the ORIGIN corner (negX, negY, negZ);
  // drop the 3 touching the opposite corner (kW,kD,kH). Free boundary = the
  // 6 box edges that touch neither corner directly (each borders one KEPT
  // and one DROPPED face) — hand-enumerated below, and NOT coplanar: the
  // first three points share z=0 (both (kW,0,0) and (kW,kD,0) and (0,kD,0)
  // are corners of the negZ face) while the fourth, (0,kD,kH), has z=kH != 0
  // — no single plane contains all six, so a planar-only fill algorithm
  // could not have produced this even by accident.
  const TopoDS_Shape openCorner = ShellOf({faces.negX, faces.negY, faces.negZ});
  check(aeth::ProbeShape(openCorner).solidCount == 0, "the corner fixture is open (no solid)");
  const std::array<gp_Pnt, 6> expectedLoop = {
      gp_Pnt(kW, 0, 0),  gp_Pnt(kW, kD, 0), gp_Pnt(0, kD, 0),
      gp_Pnt(0, kD, kH), gp_Pnt(0, 0, kH),  gp_Pnt(kW, 0, kH),
  };
  {
    // Hand-verified non-coplanarity (independent of surfacing_feature.cpp):
    // plane through the first three points is z=0 (all three have z=0); the
    // fourth point's z is kH, which is nonzero by construction (kH > 0).
    check(expectedLoop[0].Z() == 0.0 && expectedLoop[1].Z() == 0.0 && expectedLoop[2].Z() == 0.0 &&
              std::abs(expectedLoop[3].Z() - kH) < 1e-9 && kH > 0.0,
          "the expected boundary loop is provably NOT coplanar (fourth vertex leaves the first "
          "three's z=0 plane)");
  }

  BodyPool pool;
  const std::string targetOp = "b0000000-0000-4000-8000-000000000002";
  pool.Produce(MakeFixtureBody(targetOp, "target-body", openCorner));
  const nlohmann::json operation =
      OperationEnvelope("b0000000-0000-4000-8000-0000000000f2", "boundary_surface", "fill-body",
                        {{"targetOperationId", targetOp}});
  std::atomic_bool cancelled{false};
  const EvaluatedBody result =
      aeth::EvaluateBoundarySurface(operation, pool, nullptr, nullptr, cancelled);
  check(result.probes.valid && result.probes.faceCount == 1 && result.probes.solidCount == 0,
        "the fill result is one valid open face");
  check(result.probes.surfaceArea > 1e-6, "the fill face has positive area");
  check(aeth::SurfaceClass(TopoDS::Face(result.shape)) != "plane",
        "the fill face is genuinely curved, not degenerated into a flat plane");

  // The fill face's OWN boundary vertices must be exactly the 6 known
  // corners (a hand-derivable structural check independent of area/curvature).
  // TopExp::MapShapes, not a raw TopExp_Explorer: a closed wire's vertex is
  // reached from BOTH its incident edges, so a plain explorer visits each one
  // TWICE (measured: 12 visits for 6 distinct vertices here) — the same
  // deduplicating-traversal reasoning sheet_metal_feature.cpp's own
  // FindStraightEdgeByEndpoints comment documents for exactly this trap.
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> resultVertices;
  TopExp::MapShapes(result.shape, TopAbs_VERTEX, resultVertices);
  check(resultVertices.Extent() == 6, "the fill face has exactly 6 distinct boundary vertices");
  int matched = 0;
  for (int index = 1; index <= resultVertices.Extent(); ++index) {
    const gp_Pnt point = BRep_Tool::Pnt(TopoDS::Vertex(resultVertices(index)));
    for (const gp_Pnt& expected : expectedLoop) {
      if (point.Distance(expected) < 1e-6) {
        matched += 1;
        break;
      }
    }
  }
  check(matched == 6, "the fill face's boundary vertices are exactly the 6 expected box corners");

  // Independent closure proof (same discipline as the planar case above).
  BRepBuilderAPI_Sewing sewing(1e-6);
  sewing.Add(openCorner);
  sewing.Add(result.shape);
  sewing.Perform();
  check(sewing.NbFreeEdges() == 0,
        "resewing the curved fill face onto the 3-face corner leaves zero free edges");
}

void BoundarySurfaceAlreadyClosedRefusal() {
  std::printf("boundary_surface on an already-closed body -> E_BOUNDARY_SURFACE_NOT_CLOSED, "
              "through full dispatch:\n");
  const std::string boxOp = "b0000000-0000-4000-8000-000000000003";
  const nlohmann::json program = nlohmann::json::array(
      {OperationEnvelope(boxOp, "create_box", "box-body",
                         {{"width", 10.0},
                          {"depth", 10.0},
                          {"height", 10.0},
                          {"placement",
                           {{"origin", {0.0, 0.0, 0.0}},
                            {"zDirection", {0.0, 0.0, 1.0}},
                            {"xDirection", {1.0, 0.0, 0.0}}}}}),
       OperationEnvelope("b0000000-0000-4000-8000-0000000000f3", "boundary_surface", "fill-body",
                         {{"targetOperationId", boxOp}})});
  const Refusal refusal = RunProgramExpectingRefusal(program);
  check(refusal.kind == "operation" && refusal.code == "GEOMETRY_FAILED" &&
            refusal.details.value("surfaceCode", "") == "E_BOUNDARY_SURFACE_NOT_CLOSED",
        "a fully-closed box -> E_BOUNDARY_SURFACE_NOT_CLOSED, never a crash (via ExecuteOperation "
        "dispatch)");
}

void BoundarySurfaceNaming() {
  std::printf("boundary_surface with element naming active reuses the target's own boundary "
              "names rather than colliding with them:\n");
  constexpr double kW = 8.0, kD = 6.0, kH = 3.0;
  const BoxFaces faces = MakeBoxFaces(kW, kD, kH);
  const TopoDS_Shape openBox =
      ShellOf({faces.negX, faces.posX, faces.negY, faces.posY, faces.negZ});
  aeth::NamingRegistry registry;
  const std::string targetOp = "b0000000-0000-4000-8000-000000000004";
  registry.Book().AddPrimitive(targetOp, openBox); // Mimics a real earlier operation's naming.

  BodyPool pool;
  pool.Produce(MakeFixtureBody(targetOp, "target-body", openBox));
  const nlohmann::json operation =
      OperationEnvelope("b0000000-0000-4000-8000-0000000000f4", "boundary_surface", "fill-body",
                        {{"targetOperationId", targetOp}});
  std::atomic_bool cancelled{false};
  bool threw = false;
  EvaluatedBody result;
  try {
    result = aeth::EvaluateBoundarySurface(operation, pool, &registry.Book(), &registry, cancelled);
  } catch (const std::exception& error) {
    std::printf("  FAIL naming-enabled call threw: %s\n", error.what());
    threw = true;
    g_failures += 1;
  }
  check(!threw, "naming-enabled boundary_surface does not throw despite reused boundary names");
  if (!threw) {
    bool named = true;
    try {
      (void)registry.Book().NameOf(result.shape);
    } catch (const std::exception&) {
      named = false;
    }
    check(named, "the fill face itself has a book lineage name");
  }
}

// --- 2. surface_offset --------------------------------------------------------

void SurfaceOffsetPlanarExactDistance() {
  std::printf("surface_offset moves a planar rectangle to the EXACT parallel plane at the "
              "signed distance, area preserved:\n");
  constexpr double kW = 18.0, kD = 12.0, kDistance = 5.0;
  const TopoDS_Face source = RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0), kW, kD);
  const BRepAdaptor_Surface sourceSurface(source, true);
  const aeth::Axis sourceNormal = aeth::PlanarOutwardNormal(source, sourceSurface);
  check(sourceNormal.has_value() && std::abs((*sourceNormal)[2] - 1.0) < 1e-9,
        "fixture sanity: RectFace(X,Y) has outward normal +Z");

  const std::string targetOp = "b0000000-0000-4000-8000-000000000010";
  for (const double signedDistance : {kDistance, -kDistance}) {
    BodyPool pool;
    pool.Produce(MakeFixtureBody(targetOp, "target-body", source));
    const nlohmann::json operation =
        OperationEnvelope("b0000000-0000-4000-8000-0000000000f5", "surface_offset", "offset-body",
                          {{"targetOperationId", targetOp}, {"distanceMm", signedDistance}});
    std::atomic_bool cancelled{false};
    const EvaluatedBody result =
        aeth::EvaluateSurfaceOffset(operation, pool, nullptr, nullptr, cancelled);
    check(result.probes.valid && result.probes.solidCount == 0, "the offset result stays an open "
                                                                "surface");
    checkNear(result.probes.surfaceArea, kW * kD, 1e-6,
              "offsetting a planar face preserves its exact area (216)");
    // Hand-derived: offsetting a PLANE along its own normal by signedDistance
    // is a pure translation — the origin corner must land at EXACTLY
    // (0,0,signedDistance) for this fixture's +Z-normal plane.
    const TopoDS_Face resultFace = SingleFaceOf(result.shape);
    const BRepAdaptor_Surface resultSurface(resultFace, true);
    check(resultSurface.GetType() == GeomAbs_Plane, "the offset result is still a plane");
    const gp_Pln resultPlane = resultSurface.Plane();
    const gp_Pnt expectedOrigin(0.0, 0.0, signedDistance);
    checkNear(resultPlane.Distance(expectedOrigin), 0.0, 1e-6,
              "the offset plane passes through the exact point (0,0,distanceMm)");
    const aeth::Axis resultNormal = aeth::PlanarOutwardNormal(resultFace, resultSurface);
    check(resultNormal.has_value() && std::abs((*resultNormal)[2] - 1.0) < 1e-6,
          "the offset plane's own outward normal is unchanged (+Z)");
  }
}

void SurfaceOffsetZeroDistanceRefusal() {
  std::printf("surface_offset with distanceMm == 0 refuses rather than being a silent no-op:\n");
  const TopoDS_Face source = RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0), 5.0, 5.0);
  BodyPool pool;
  const std::string targetOp = "b0000000-0000-4000-8000-000000000011";
  pool.Produce(MakeFixtureBody(targetOp, "target-body", source));
  const nlohmann::json operation =
      OperationEnvelope("b0000000-0000-4000-8000-0000000000f6", "surface_offset", "offset-body",
                        {{"targetOperationId", targetOp}, {"distanceMm", 0.0}});
  const Refusal refusal = RunDirectExpectingRefusal(
      pool, operation, [](const nlohmann::json& op, BodyPool& p, const std::atomic_bool& c) {
        aeth::EvaluateSurfaceOffset(op, p, nullptr, nullptr, c);
      });
  check(refusal.kind == "other", "distanceMm == 0 refuses (invalid-argument), never a silent "
                                 "no-op");
}

void SurfaceOffsetSolidTargetRefusal() {
  std::printf("surface_offset on a solid target -> E_SURFACE_OFFSET_NOT_SURFACE, through full "
              "dispatch:\n");
  const std::string boxOp = "b0000000-0000-4000-8000-000000000012";
  const nlohmann::json program = nlohmann::json::array(
      {OperationEnvelope(boxOp, "create_box", "box-body",
                         {{"width", 10.0},
                          {"depth", 10.0},
                          {"height", 10.0},
                          {"placement",
                           {{"origin", {0.0, 0.0, 0.0}},
                            {"zDirection", {0.0, 0.0, 1.0}},
                            {"xDirection", {1.0, 0.0, 0.0}}}}}),
       OperationEnvelope("b0000000-0000-4000-8000-0000000000f7", "surface_offset", "offset-body",
                         {{"targetOperationId", boxOp}, {"distanceMm", 2.0}})});
  // No-naming dispatch: surface_offset's own fail-closed naming guard sits
  // AHEAD of this check (see EvaluateSurfaceOffset), so a registry-threaded
  // run would surface UNSUPPORTED_OPERATION instead — already covered by
  // SurfaceOffsetNamingGuardRefusal below.
  const Refusal refusal = RunProgramExpectingRefusalNoNaming(program);
  check(refusal.kind == "operation" && refusal.code == "INVALID_REQUEST" &&
            refusal.details.value("surfaceCode", "") == "E_SURFACE_OFFSET_NOT_SURFACE",
        "a solid target -> E_SURFACE_OFFSET_NOT_SURFACE, never a crash (via ExecuteOperation "
        "dispatch)");
}

void SurfaceOffsetNamingGuardRefusal() {
  std::printf("surface_offset with element naming requested refuses UNSUPPORTED_OPERATION (the "
              "same fail-closed guard `offset` v1 already uses):\n");
  const TopoDS_Face source = RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0), 5.0, 5.0);
  aeth::NamingRegistry registry;
  BodyPool pool;
  const std::string targetOp = "b0000000-0000-4000-8000-000000000013";
  pool.Produce(MakeFixtureBody(targetOp, "target-body", source));
  const nlohmann::json operation =
      OperationEnvelope("b0000000-0000-4000-8000-0000000000f8", "surface_offset", "offset-body",
                        {{"targetOperationId", targetOp}, {"distanceMm", 2.0}});
  std::atomic_bool cancelled{false};
  bool threwUnsupported = false;
  try {
    aeth::EvaluateSurfaceOffset(operation, pool, &registry.Book(), &registry, cancelled);
  } catch (const std::invalid_argument& error) {
    threwUnsupported = std::string(error.what()).starts_with("unsupported operation");
  } catch (const std::exception&) {
  }
  check(threwUnsupported, "naming-enabled surface_offset refuses as unsupported rather than "
                          "minting unverified names");
}

void SurfaceOffsetCylinderSelfIntersection() {
  std::printf("surface_offset on a cylindrical face: outward succeeds at the exact hand-derived "
              "radius, inward past the axis refuses E_SURFACE_OFFSET_SELF_INTERSECTS:\n");
  constexpr double kRadius = 4.0, kHeight = 15.0, kMagnitude = 12.0; // 12 > 2*radius (8).
  BRepPrimAPI_MakeCylinder cylinderMaker(kRadius, kHeight);
  const TopoDS_Shape cylinder = cylinderMaker.Shape();
  TopoDS_Face side;
  bool found = false;
  for (TopExp_Explorer explorer(cylinder, TopAbs_FACE); explorer.More(); explorer.Next()) {
    const TopoDS_Face face = TopoDS::Face(explorer.Current());
    if (aeth::SurfaceClass(face) == "cylinder") {
      side = face;
      found = true;
      break;
    }
  }
  check(found, "fixture sanity: located the cylinder's own lateral face");
  if (!found)
    return;

  bool oneSucceeded = false;
  bool oneRefusedSelfIntersect = false;
  const std::string targetOp = "b0000000-0000-4000-8000-000000000014";
  for (const double signedDistance : {kMagnitude, -kMagnitude}) {
    BodyPool pool;
    pool.Produce(MakeFixtureBody(targetOp, "target-body", side));
    const nlohmann::json operation =
        OperationEnvelope("b0000000-0000-4000-8000-0000000000f9", "surface_offset", "offset-body",
                          {{"targetOperationId", targetOp}, {"distanceMm", signedDistance}});
    std::atomic_bool cancelled{false};
    try {
      const EvaluatedBody result =
          aeth::EvaluateSurfaceOffset(operation, pool, nullptr, nullptr, cancelled);
      // Succeeded: this must be the OUTWARD direction (inward by more than
      // the radius is geometrically impossible). Hand-derived: offsetting a
      // cylinder of radius r outward by |d| yields a cylinder of radius
      // r + |d| = 4 + 12 = 16.
      const std::optional<double> resultRadius = aeth::SurfaceRadius(SingleFaceOf(result.shape));
      checkNear(resultRadius.value_or(-1.0), kRadius + kMagnitude, 1e-6,
                "the outward-succeeding offset's radius == sourceRadius + |distanceMm| (16)");
      oneSucceeded = true;
    } catch (const aeth::OperationFailure& error) {
      check(error.Details().value("surfaceCode", "") == "E_SURFACE_OFFSET_SELF_INTERSECTS",
            "the inward-refusing offset carries E_SURFACE_OFFSET_SELF_INTERSECTS");
      oneRefusedSelfIntersect = true;
    }
  }
  check(oneSucceeded, "one of the two signed offsets (the outward one) succeeded");
  check(oneRefusedSelfIntersect,
        "the other (inward, past the axis by construction: 12 > 2*radius) refused rather than "
        "returning garbage geometry");
}

// --- 3. stitch ----------------------------------------------------------------

void StitchTwoOpenSurfacesSharingAnEdge() {
  std::printf("stitch merges two open surfaces sharing one edge into one open shell whose area "
              "is the exact sum:\n");
  constexpr double kSharedLength = 20.0, kHeight1 = 10.0, kHeight2 = 8.0;
  const TopoDS_Face face1 =
      RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0), kSharedLength, kHeight1);
  const TopoDS_Face face2 =
      RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 0, 1), kSharedLength, kHeight2);
  checkNear(FaceArea(face1), kSharedLength * kHeight1, 1e-9, "fixture sanity: face1 area (200)");
  checkNear(FaceArea(face2), kSharedLength * kHeight2, 1e-9, "fixture sanity: face2 area (160)");

  BodyPool pool;
  const std::string firstOp = "b0000000-0000-4000-8000-000000000020";
  const std::string secondOp = "b0000000-0000-4000-8000-000000000021";
  pool.Produce(MakeFixtureBody(firstOp, "first-body", face1));
  pool.Produce(MakeFixtureBody(secondOp, "second-body", face2));
  const nlohmann::json operation = OperationEnvelope(
      "b0000000-0000-4000-8000-0000000000fa", "stitch", "stitched-body",
      {{"firstOperationId", firstOp}, {"secondOperationId", secondOp}, {"toleranceMm", 1e-4}});
  std::atomic_bool cancelled{false};
  const EvaluatedBody result = aeth::EvaluateStitch(operation, pool, nullptr, nullptr, cancelled);
  check(result.probes.valid && result.probes.solidCount == 0 && result.probes.faceCount == 2,
        "the stitched result is one valid OPEN 2-face shell (not a solid)");
  checkNear(result.probes.surfaceArea, kSharedLength * kHeight1 + kSharedLength * kHeight2, 1e-6,
            "stitched total area == the exact sum of both faces' areas (360)");
}

void StitchTwoHalfShellsIntoAClosedSolid() {
  std::printf("stitch merges two complementary 3-face box halves (sharing the same hexagonal "
              "boundary as the boundary_surface test) into the box's own exact closed solid:\n");
  constexpr double kW = 15.0, kD = 12.0, kH = 9.0;
  // TWO INDEPENDENT box instances at the identical position, not one box's
  // faces split into two groups: sharing the SAME box would give halfA and
  // halfB literally identical (IsSame) boundary edges, which is not the
  // realistic stitch scenario (two independently-authored surfaces that
  // merely happen to be geometrically coincident) and, measured directly,
  // does not exercise BRepBuilderAPI_Sewing's real welding path the same way
  // — its own NbContigousEdges() counts edges it actively CONNECTED, which is
  // trivially zero when the inputs already share edge identity outright.
  const BoxFaces facesA = MakeBoxFaces(kW, kD, kH);
  const BoxFaces facesB = MakeBoxFaces(kW, kD, kH);
  const TopoDS_Shape halfA = ShellOf({facesA.negX, facesA.negY, facesA.negZ});
  const TopoDS_Shape halfB = ShellOf({facesB.posX, facesB.posY, facesB.posZ});
  check(aeth::ProbeShape(halfA).solidCount == 0 && aeth::ProbeShape(halfB).solidCount == 0,
        "fixture sanity: both box halves are open (no solid)");

  BodyPool pool;
  const std::string firstOp = "b0000000-0000-4000-8000-000000000022";
  const std::string secondOp = "b0000000-0000-4000-8000-000000000023";
  pool.Produce(MakeFixtureBody(firstOp, "first-body", halfA));
  pool.Produce(MakeFixtureBody(secondOp, "second-body", halfB));
  const nlohmann::json operation = OperationEnvelope(
      "b0000000-0000-4000-8000-0000000000fb", "stitch", "stitched-body",
      {{"firstOperationId", firstOp}, {"secondOperationId", secondOp}, {"toleranceMm", 1e-4}});
  std::atomic_bool cancelled{false};
  const EvaluatedBody result = aeth::EvaluateStitch(operation, pool, nullptr, nullptr, cancelled);
  check(result.probes.valid && result.probes.solidCount == 1,
        "two complementary box halves stitch into exactly ONE valid solid");
  checkNear(result.probes.volume, kW * kD * kH, 1e-3,
            "stitched solid volume == width * depth * height, the exact original box (1620)");
}

void StitchNoCommonBoundaryRefusal() {
  std::printf("stitch on two bodies that share no boundary -> E_STITCH_NO_COMMON_BOUNDARY, "
              "through full dispatch:\n");
  const std::string firstOp = "b0000000-0000-4000-8000-000000000024";
  const std::string secondOp = "b0000000-0000-4000-8000-000000000025";
  const auto boxAt = [](const std::string& id, const std::string& bodyId, const double x,
                        const double y, const double z) {
    return OperationEnvelope(id, "create_box", bodyId,
                             {{"width", 5.0},
                              {"depth", 5.0},
                              {"height", 5.0},
                              {"placement",
                               {{"origin", {x, y, z}},
                                {"zDirection", {0.0, 0.0, 1.0}},
                                {"xDirection", {1.0, 0.0, 0.0}}}}});
  };
  const nlohmann::json program = nlohmann::json::array(
      {boxAt(firstOp, "first-box-body", 0.0, 0.0, 0.0),
       boxAt(secondOp, "second-box-body", 1000.0, 1000.0, 1000.0),
       OperationEnvelope("b0000000-0000-4000-8000-0000000000fc", "stitch", "stitched-body",
                         {{"firstOperationId", firstOp},
                          {"secondOperationId", secondOp},
                          {"toleranceMm", 1e-4}})});
  const Refusal refusal = RunProgramExpectingRefusal(program);
  check(refusal.kind == "operation" && refusal.code == "GEOMETRY_FAILED" &&
            refusal.details.value("surfaceCode", "") == "E_STITCH_NO_COMMON_BOUNDARY",
        "two disjoint boxes -> E_STITCH_NO_COMMON_BOUNDARY, never a crash (via ExecuteOperation "
        "dispatch)");
}

void StitchNaming() {
  std::printf("stitch with element naming active mints its result fresh without throwing:\n");
  const TopoDS_Face face1 = RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0), 6.0, 4.0);
  const TopoDS_Face face2 = RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 0, 1), 6.0, 3.0);
  aeth::NamingRegistry registry;
  const std::string firstOp = "b0000000-0000-4000-8000-000000000026";
  const std::string secondOp = "b0000000-0000-4000-8000-000000000027";
  registry.Book().AddPrimitive(firstOp, face1);
  registry.Book().AddPrimitive(secondOp, face2);
  BodyPool pool;
  pool.Produce(MakeFixtureBody(firstOp, "first-body", face1));
  pool.Produce(MakeFixtureBody(secondOp, "second-body", face2));
  const nlohmann::json operation = OperationEnvelope(
      "b0000000-0000-4000-8000-0000000000fd", "stitch", "stitched-body",
      {{"firstOperationId", firstOp}, {"secondOperationId", secondOp}, {"toleranceMm", 1e-4}});
  std::atomic_bool cancelled{false};
  bool threw = false;
  try {
    aeth::EvaluateStitch(operation, pool, &registry.Book(), &registry, cancelled);
  } catch (const std::exception& error) {
    std::printf("  FAIL naming-enabled call threw: %s\n", error.what());
    threw = true;
    g_failures += 1;
  }
  check(!threw, "naming-enabled stitch does not throw");
}

// --- 4. thicken -----------------------------------------------------------

void ThickenPlanarAllDirections() {
  std::printf("thicken a planar rectangle: normal/reverse/symmetric each produce the exact "
              "width*depth*thickness volume, positioned where each mode implies:\n");
  constexpr double kW = 14.0, kD = 9.0;
  const std::string targetOp = "b0000000-0000-4000-8000-000000000030";

  const auto runThicken = [&](const double thickness, const std::string& direction) {
    const TopoDS_Face source = RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0), kW, kD);
    BodyPool pool;
    pool.Produce(MakeFixtureBody(targetOp, "target-body", source));
    const nlohmann::json operation = OperationEnvelope(
        "b0000000-0000-4000-8000-0000000000fe", "thicken", "thickened-body",
        {{"targetOperationId", targetOp}, {"thicknessMm", thickness}, {"direction", direction}});
    std::atomic_bool cancelled{false};
    return aeth::EvaluateThicken(operation, pool, nullptr, nullptr, cancelled);
  };

  constexpr double kThicknessOneSided = 4.0;
  const EvaluatedBody normalBody = runThicken(kThicknessOneSided, "normal");
  const EvaluatedBody reverseBody = runThicken(kThicknessOneSided, "reverse");
  check(normalBody.probes.valid && normalBody.probes.solidCount == 1, "normal result is one "
                                                                      "valid solid");
  check(reverseBody.probes.valid && reverseBody.probes.solidCount == 1, "reverse result is one "
                                                                        "valid solid");
  checkNear(normalBody.probes.volume, kW * kD * kThicknessOneSided, 1e-6,
            "normal volume == width * depth * thicknessMm (504)");
  checkNear(reverseBody.probes.volume, kW * kD * kThicknessOneSided, 1e-6,
            "reverse volume == width * depth * thicknessMm (504)");
  const double normalZExtent = normalBody.probes.bounds[5] - normalBody.probes.bounds[2];
  const double reverseZExtent = reverseBody.probes.bounds[5] - reverseBody.probes.bounds[2];
  checkNear(normalZExtent, kThicknessOneSided, 1e-6, "normal Z extent == thicknessMm");
  checkNear(reverseZExtent, kThicknessOneSided, 1e-6, "reverse Z extent == thicknessMm");
  // Hand-derived, convention-independent: the source surface sits exactly at
  // z=0 before thickening. "normal" and "reverse" each grow the FULL
  // thickness to one side, so EXACTLY one of their two Z bounds must equal 0
  // (the untouched source surface, still one wall of the solid) — and,
  // critically, normal and reverse must land that zero-touching bound on
  // OPPOSITE ends from each other (they grow away from the source in
  // opposite directions by definition), whichever physical sign OCCT's own
  // PerformByJoin convention happens to assign to "positive offset" for this
  // face.
  const bool normalMinIsZero = std::abs(normalBody.probes.bounds[2]) < 1e-6;
  const bool normalMaxIsZero = std::abs(normalBody.probes.bounds[5]) < 1e-6;
  const bool reverseMinIsZero = std::abs(reverseBody.probes.bounds[2]) < 1e-6;
  const bool reverseMaxIsZero = std::abs(reverseBody.probes.bounds[5]) < 1e-6;
  check((normalMinIsZero != normalMaxIsZero), "normal keeps exactly one Z bound at the source "
                                              "surface (z=0)");
  check((reverseMinIsZero != reverseMaxIsZero), "reverse keeps exactly one Z bound at the source "
                                                "surface (z=0)");
  check(normalMinIsZero != reverseMinIsZero,
        "normal and reverse grow to OPPOSITE sides of the source surface");

  constexpr double kThicknessSymmetric = 6.0;
  const EvaluatedBody symmetricBody = runThicken(kThicknessSymmetric, "symmetric");
  check(symmetricBody.probes.valid && symmetricBody.probes.solidCount == 1, "symmetric result is "
                                                                            "one valid solid");
  checkNear(symmetricBody.probes.volume, kW * kD * kThicknessSymmetric, 1e-6,
            "symmetric volume == width * depth * thicknessMm (756)");
  // Hand-derived and convention-independent (see this file's header/
  // surfacing_feature.hpp's own comment): symmetric composes a -thickness/2
  // half-shift with a +thickness full-thicken using the SAME underlying
  // offset sign convention for both stages, so the net result is ALWAYS
  // centered on the original surface regardless of which physical direction
  // happens to be "positive" for this particular face.
  checkNear(symmetricBody.probes.bounds[2], -kThicknessSymmetric / 2.0, 1e-6,
            "symmetric Z min == -thicknessMm/2 (-3), exactly centered");
  checkNear(symmetricBody.probes.bounds[5], kThicknessSymmetric / 2.0, 1e-6,
            "symmetric Z max == +thicknessMm/2 (+3), exactly centered");
}

void ThickenSolidTargetRefusal() {
  std::printf("thicken on a solid target -> E_THICKEN_NOT_SURFACE, through full dispatch:\n");
  const std::string boxOp = "b0000000-0000-4000-8000-000000000031";
  const nlohmann::json program = nlohmann::json::array(
      {OperationEnvelope(boxOp, "create_box", "box-body",
                         {{"width", 10.0},
                          {"depth", 10.0},
                          {"height", 10.0},
                          {"placement",
                           {{"origin", {0.0, 0.0, 0.0}},
                            {"zDirection", {0.0, 0.0, 1.0}},
                            {"xDirection", {1.0, 0.0, 0.0}}}}}),
       OperationEnvelope(
           "b0000000-0000-4000-8000-0000000000ff", "thicken", "thickened-body",
           {{"targetOperationId", boxOp}, {"thicknessMm", 2.0}, {"direction", "normal"}})});
  const Refusal refusal = RunProgramExpectingRefusal(program);
  check(refusal.kind == "operation" && refusal.code == "INVALID_REQUEST" &&
            refusal.details.value("surfaceCode", "") == "E_THICKEN_NOT_SURFACE",
        "a solid target -> E_THICKEN_NOT_SURFACE, never a crash (via ExecuteOperation dispatch)");
}

void ThickenCylinderSelfIntersection() {
  std::printf("thicken on a cylindrical face: outward succeeds at the exact hand-derived "
              "annulus volume, inward past the axis refuses E_THICKEN_SELF_INTERSECTS:\n");
  constexpr double kRadius = 4.0, kHeight = 15.0, kThickness = 12.0; // 12 > 2*radius (8).
  BRepPrimAPI_MakeCylinder cylinderMaker(kRadius, kHeight);
  const TopoDS_Shape cylinder = cylinderMaker.Shape();
  TopoDS_Face side;
  bool found = false;
  for (TopExp_Explorer explorer(cylinder, TopAbs_FACE); explorer.More(); explorer.Next()) {
    const TopoDS_Face face = TopoDS::Face(explorer.Current());
    if (aeth::SurfaceClass(face) == "cylinder") {
      side = face;
      found = true;
      break;
    }
  }
  check(found, "fixture sanity: located the cylinder's own lateral face");
  if (!found)
    return;

  bool oneSucceeded = false;
  bool oneRefusedSelfIntersect = false;
  const std::string targetOp = "b0000000-0000-4000-8000-000000000032";
  for (const std::string& direction : {std::string("normal"), std::string("reverse")}) {
    BodyPool pool;
    pool.Produce(MakeFixtureBody(targetOp, "target-body", side));
    const nlohmann::json operation = OperationEnvelope(
        "b0000000-0000-4000-8000-000000000f00", "thicken", "thickened-body",
        {{"targetOperationId", targetOp}, {"thicknessMm", kThickness}, {"direction", direction}});
    std::atomic_bool cancelled{false};
    try {
      const EvaluatedBody result =
          aeth::EvaluateThicken(operation, pool, nullptr, nullptr, cancelled);
      // Succeeded: this must be the OUTWARD direction. Hand-derived: an
      // annulus of inner radius r and outer radius r+t, height h, has volume
      // pi*((r+t)^2 - r^2)*h = pi*(2*r*t + t^2)*h.
      const double expectedVolume =
          kPi * (2.0 * kRadius * kThickness + kThickness * kThickness) * kHeight;
      checkNear(result.probes.volume, expectedVolume, expectedVolume * 1e-4,
                "the outward-succeeding thicken's volume == pi*(2*r*t + t^2)*h, the exact "
                "annulus formula");
      oneSucceeded = true;
    } catch (const aeth::OperationFailure& error) {
      check(error.Details().value("surfaceCode", "") == "E_THICKEN_SELF_INTERSECTS",
            "the inward-refusing thicken carries E_THICKEN_SELF_INTERSECTS");
      oneRefusedSelfIntersect = true;
    }
  }
  check(oneSucceeded, "one of the two directions (the outward one) succeeded");
  check(oneRefusedSelfIntersect,
        "the other (inward, past the axis by construction: 12 > 2*radius) refused rather than "
        "returning garbage geometry");
}

// thicken's naming path was originally planned to construct through the real
// OperationClass::Thicken HarvestOperation path for normal/reverse (mirroring
// shell's own already-proven MakeThickSolidByJoin harvest). MEASURED
// DIVERGENCE (see EvaluateThicken's own comment for the full account):
// MakeThickSolidBySimple's own retained history is too thin for
// ElementNameBook::ApplyOperation to attribute even this simplest possible
// case, so ALL THREE direction modes mint fresh instead — these two tests
// confirm that for both a targeted mode (normal) and the mode that always
// needed it anyway (symmetric), matching StitchNaming/BoundarySurfaceNaming's
// own "does not throw, book coverage is total" shape rather than asserting
// anything about registry tokens (this operation mints none of its own).
void ThickenNamingNormalDoesNotThrow() {
  std::printf("thicken (normal) with element naming active mints its result fresh without "
              "throwing, with total book coverage:\n");
  const TopoDS_Face source = RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0), 7.0, 5.0);
  aeth::NamingRegistry registry;
  const std::string targetOp = "b0000000-0000-4000-8000-000000000033";
  registry.Book().AddPrimitive(targetOp, source);
  BodyPool pool;
  pool.Produce(MakeFixtureBody(targetOp, "target-body", source));
  const nlohmann::json operation = OperationEnvelope(
      "b0000000-0000-4000-8000-000000000f01", "thicken", "thickened-body",
      {{"targetOperationId", targetOp}, {"thicknessMm", 3.0}, {"direction", "normal"}});
  std::atomic_bool cancelled{false};
  bool threw = false;
  EvaluatedBody result;
  try {
    result = aeth::EvaluateThicken(operation, pool, &registry.Book(), &registry, cancelled);
  } catch (const std::exception& error) {
    std::printf("  FAIL naming-enabled call threw: %s\n", error.what());
    threw = true;
    g_failures += 1;
  }
  check(!threw, "naming-enabled thicken (normal) does not throw");
  if (threw)
    return;
  bool everyFaceNamed = true;
  for (TopExp_Explorer explorer(result.shape, TopAbs_FACE); explorer.More(); explorer.Next()) {
    try {
      (void)registry.Book().NameOf(explorer.Current());
    } catch (const std::exception&) {
      everyFaceNamed = false;
      break;
    }
  }
  check(everyFaceNamed, "every face of the thickened solid has a book lineage name (total "
                        "coverage, AddDerivedPrimitive)");
}

void ThickenNamingSymmetricDoesNotThrow() {
  std::printf("thicken (symmetric) with element naming active mints its result fresh without "
              "throwing:\n");
  const TopoDS_Face source = RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0), 7.0, 5.0);
  aeth::NamingRegistry registry;
  const std::string targetOp = "b0000000-0000-4000-8000-000000000034";
  registry.Book().AddPrimitive(targetOp, source);
  BodyPool pool;
  pool.Produce(MakeFixtureBody(targetOp, "target-body", source));
  const nlohmann::json operation = OperationEnvelope(
      "b0000000-0000-4000-8000-000000000f02", "thicken", "thickened-body",
      {{"targetOperationId", targetOp}, {"thicknessMm", 3.0}, {"direction", "symmetric"}});
  std::atomic_bool cancelled{false};
  bool threw = false;
  try {
    aeth::EvaluateThicken(operation, pool, &registry.Book(), &registry, cancelled);
  } catch (const std::exception& error) {
    std::printf("  FAIL naming-enabled call threw: %s\n", error.what());
    threw = true;
    g_failures += 1;
  }
  check(!threw, "naming-enabled thicken (symmetric) does not throw");
}

// --- 5. Tessellation and STEP export/reimport of an open shape --------------

void TessellationAndStepRoundTripOfOpenShape() {
  std::printf("tessellation and STEP export/reimport of an OPEN shape (not just assumed "
              "shape-agnostic):\n");
  const TopoDS_Face source = RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0), 9.0, 6.0);
  std::atomic_bool cancelled{false};

  const aeth::TessellationPacket packet = aeth::TessellateShape(source, 0, cancelled);
  check(!packet.bytes.empty(), "tessellating an open face produces a non-empty mesh packet");
  check(packet.descriptor.value("triangleCount", 0) > 0 ||
            packet.descriptor.value("vertexCount", 0) > 0,
        "the tessellation descriptor reports a positive vertex/triangle count for an open face");

  const std::filesystem::path scratch =
      std::filesystem::temp_directory_path() / "aeth-surfacing-test";
  std::error_code ec;
  std::filesystem::remove_all(scratch, ec);
  std::filesystem::create_directories(scratch, ec);
  const std::filesystem::path dest = scratch / "open-face.step";
  const std::u8string destUtf8 = dest.u8string();
  const std::string destPath(reinterpret_cast<const char*>(destUtf8.data()), destUtf8.size());

  aeth::EvaluatedBody body;
  body.bodyId = "open-face-body";
  body.operationId = "op-open-face";
  body.shape = source;
  body.probes = aeth::ProbeShape(source);
  const std::vector<aeth::EvaluatedBody> bodies{body};

  bool exported = true;
  std::uintmax_t reported = 0;
  try {
    reported = aeth::ExportStep(bodies, destPath, cancelled);
  } catch (const std::exception& error) {
    std::printf("  FAIL STEP export of an open face threw: %s\n", error.what());
    exported = false;
    g_failures += 1;
  }
  check(exported, "STEP export of an open (non-solid) face does not throw");
  if (exported) {
    check(std::filesystem::exists(dest) && reported == std::filesystem::file_size(dest),
          "the exported STEP file exists and its reported size matches the file on disk");
    try {
      const aeth::ShapeProbes reimported = aeth::InspectStep(destPath, cancelled);
      check(reimported.valid, "the reimported STEP shape is valid");
      check(reimported.solidCount == 0, "the reimported STEP shape is still open (no solid) — "
                                        "STEP export/reimport did not silently solidify it");
      check(reimported.faceCount == 1, "the reimported STEP shape still has exactly one face");
    } catch (const std::exception& error) {
      std::printf("  FAIL STEP reimport of the open face threw: %s\n", error.what());
      g_failures += 1;
    }
  }
  std::filesystem::remove_all(scratch, ec);
}

// --- 6. ProbeShape open-shape volume/centroid investigation -----------------

void ProbeShapeOpenShapeVolumeAndCentroid() {
  std::printf("ProbeShape on an open shape: volume forced to 0, centerOfMass switches to the "
              "surface centroid:\n");
  // A planar rectangle [0,w]x[0,d] at z=0 has an exact, hand-derivable
  // area-weighted centroid at its own geometric center (w/2, d/2, 0) —
  // independent of surfacing_feature.cpp or geometry.cpp's own arithmetic.
  constexpr double kW = 10.0, kD = 4.0;
  const TopoDS_Face source = RectFace(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0), gp_Dir(0, 1, 0), kW, kD);
  const aeth::ShapeProbes probes = aeth::ProbeShape(source);
  check(probes.solidCount == 0, "fixture sanity: a bare face has solidCount == 0");
  checkNear(probes.volume, 0.0, 1e-12,
            "an open shape's probed volume is forced to exactly 0, "
            "not a misleading divergence-theorem artifact");
  checkNear(probes.centerOfMass[0], kW / 2.0, 1e-9,
            "centerOfMass.x == width/2 (the surface "
            "centroid, not a volume-integral artifact)");
  checkNear(probes.centerOfMass[1], kD / 2.0, 1e-9, "centerOfMass.y == depth/2");
  checkNear(probes.centerOfMass[2], 0.0, 1e-9, "centerOfMass.z == 0 (the face's own plane)");
}

} // namespace

int main() {
  try {
    BoundarySurfacePlanarRectangle();
    BoundarySurfaceNonPlanarHexagon();
    BoundarySurfaceAlreadyClosedRefusal();
    BoundarySurfaceNaming();

    SurfaceOffsetPlanarExactDistance();
    SurfaceOffsetZeroDistanceRefusal();
    SurfaceOffsetSolidTargetRefusal();
    SurfaceOffsetNamingGuardRefusal();
    SurfaceOffsetCylinderSelfIntersection();

    StitchTwoOpenSurfacesSharingAnEdge();
    StitchTwoHalfShellsIntoAClosedSolid();
    StitchNoCommonBoundaryRefusal();
    StitchNaming();

    ThickenPlanarAllDirections();
    ThickenSolidTargetRefusal();
    ThickenCylinderSelfIntersection();
    ThickenNamingNormalDoesNotThrow();
    ThickenNamingSymmetricDoesNotThrow();

    TessellationAndStepRoundTripOfOpenShape();
    ProbeShapeOpenShapeVolumeAndCentroid();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL SURFACING TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d SURFACING CHECK(S) FAILED\n", g_failures);
  return 1;
}
