// Native tests for the Mold/tooling domain (native/kernel-host only; the
// schema/contracts and desktop-UI layers land independently against the
// same wire field names). Two mandatory EMPIRICAL SPIKES run first (Spike B
// then Spike A, in dependency order — see each test's own comment for why),
// proving the two genuinely novel OCCT usages this domain depends on BEFORE
// any executor-level test relies on either one, exactly this codebase's own
// "test empirically, never assume" discipline (the MakeThickSolid
// ByJoin/BySimple divergence, MakeFilling's missing wire overload). Then:
//
//   1. ClassifyDraftFaces: independently-derived sign checks against a
//      hand-built bicone (two conical faces meeting at a circular equator —
//      the classic "ball mold" shape) and a plain box, using OutwardNormalAtPoint
//      directly (geometry_measures.cpp) rather than trusting the function
//      under test to grade itself.
//   2. mold_parting_line: the bicone's equator loop found exactly, through
//      full ExecuteOperation dispatch; E_PARTING_LINE_NO_DRAFT_VARIATION on
//      a plain box; E_PARTING_LINE_STRADDLE_FACE on a full sphere (one face
//      spanning both signs); E_PARTING_LINE_MULTIPLE_LOOPS on two disjoint
//      bicones in one compound body.
//   3. GroupEdgesIntoLoops (topology_adjacency.hpp) directly: empty input,
//      one loop, two disjoint loops, and a non-manifold junction refusal —
//      the new connected-component grouping helper this domain motivated.
//   4. mold_shutoff_surface: a hand-built shell with one free hole loop (no
//      wall built for the hole — the standalone fixture no JSON primitive
//      can produce) caps correctly and excludes a second loop matching a
//      given "parting line" wire by identity; E_SHUTOFF_NO_HOLES on the
//      bicone's own OWN fully-closed solid (see mold_tooling_feature.hpp's
//      own documented honest scope limit on this refusal).
//   5. mold_parting_surface: sweeps the bicone's own real equator wire into
//      a shell spanning +/-extensionDistanceMm, self-intersection refusal
//      on a self-crossing profile, and a shut-off knit-in.
//   6. mold_tooling_split: the full pipeline (bicone -> parting_line ->
//      parting_surface -> tooling_split) yields exactly core+cavity with
//      volumes summing to the block minus the part, roles assigned by
//      pull-direction sign; a real 1-insert case; E_TOOLING_SPLIT_WRONG_SOLID_COUNT
//      via an extra tool that touches nothing; E_TOOLING_SPLIT_CAP_TOOL_NOT_CLOSED
//      on an open target with no shut-off referenced.
//   7. mold_draft_analysis-shaped coverage: ClassifyDraftFaces's counts are
//      exercised again in isolation (the RPC method itself lives in
//      server.cpp, which no ctest target links — see this repo's own
//      precedent of testing the underlying function, not the thin RPC
//      dispatch layer, for simulate/hlr_project too).
//
// Every numeric assertion is independently hand-derived in a comment beside
// it (this repo's own standard, set by sheet_metal_test.cpp and repeated by
// surfacing_test.cpp/electrical_routing_test.cpp) — never copied from what
// mold_tooling_feature.cpp itself computes.
#include <atomic>
#include <cmath>
#include <cstdio>
#include <optional>
#include <string>
#include <vector>

#include <BRepAdaptor_Surface.hxx>
#include <BRepAlgoAPI_Splitter.hxx>
#include <BRepBndLib.hxx>
#include <BRepBuilderAPI_MakeEdge.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <BRepBuilderAPI_MakePolygon.hxx>
#include <BRepBuilderAPI_MakeSolid.hxx>
#include <BRepBuilderAPI_MakeWire.hxx>
#include <BRepBuilderAPI_Sewing.hxx>
#include <BRepBuilderAPI_Transform.hxx>
#include <BRepCheck_Analyzer.hxx>
#include <BRepGProp.hxx>
#include <BRepLib.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakePrism.hxx>
#include <BRepPrimAPI_MakeRevol.hxx>
#include <BRepPrimAPI_MakeSphere.hxx>
#include <BRepTools.hxx>
#include <BRepTools_History.hxx>
#include <BRep_Builder.hxx>
#include <BRep_Tool.hxx>
#include <Bnd_Box.hxx>
#include <GC_MakeArcOfCircle.hxx>
#include <GProp_GProps.hxx>
#include <GeomAPI_ProjectPointOnSurf.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <Precision.hxx>
#include <Standard_Failure.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Compound.hxx>
#include <TopoDS_Edge.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shell.hxx>
#include <TopoDS_Solid.hxx>
#include <TopoDS_Vertex.hxx>
#include <TopoDS_Wire.hxx>
#include <gp_Ax1.hxx>
#include <gp_Ax2.hxx>
#include <gp_Circ.hxx>
#include <gp_Dir.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <gp_Pnt2d.hxx>
#include <gp_Trsf.hxx>
#include <gp_Vec.hxx>
#include <nlohmann/json.hpp>

#include "body_pool.hpp"
#include "element_names.hpp"
#include "geometry.hpp"
#include "geometry_measures.hpp"
#include "mold_tooling_feature.hpp"
#include "naming_registry.hpp"
#include "topology_adjacency.hpp"

namespace {

int g_failures = 0;

void check(const bool condition, const std::string& label) {
  if (condition) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s\n", label.c_str());
    g_failures += 1;
  }
  std::fflush(stdout); // Redirected-to-file runs fully buffer stdout; flush
                       // per-check so a crash's own log tail is accurate.
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

using aeth::BodyPool;
using aeth::DraftClassification;
using aeth::EvaluatedBody;

// =============================================================================
// SPIKE B: BRepPrimAPI_MakePrism on a bare TopoDS_Wire (never a face, unlike
// every existing call site in this codebase). mold_parting_surface's own
// construction depends on this. Run BEFORE Spike A: Spike A's own curved
// splitting tool is built the SAME way, so this proves the primitive Spike A
// itself depends on, in dependency order matching the real pipeline
// (parting_surface must exist before tooling_split can split with one).
// =============================================================================

/// A genuinely curved (non-planar-as-swept) wire: a circular arc from
/// (-2, y, 2) through (5, y, 6) to (12, y, 2), unambiguously constructed via
/// GC_MakeArcOfCircle's 3-point form (no circle-parametrization-direction
/// guessing — the arc is defined BY the three points, in order). Fully
/// spans X in [0, 10] with margin on both sides and stays within Z in
/// [0, 10] the whole way, so extruding it along Y crosses clean through a
/// [0,10]^3 box (used by Spike A below) without exiting through a side.
TopoDS_Wire MakeArcWire(const double y) {
  const gp_Pnt p1(-2.0, y, 2.0);
  const gp_Pnt pMid(5.0, y, 6.0);
  const gp_Pnt p3(12.0, y, 2.0);
  const GC_MakeArcOfCircle arcMaker(p1, pMid, p3);
  check(arcMaker.IsDone(), "MakeArcWire: 3-point arc construction succeeded");
  BRepBuilderAPI_MakeEdge edgeMaker(arcMaker.Value());
  check(edgeMaker.IsDone(), "MakeArcWire: arc edge construction succeeded");
  BRepBuilderAPI_MakeWire wireMaker(edgeMaker.Edge());
  check(wireMaker.IsDone(), "MakeArcWire: arc wire construction succeeded");
  return wireMaker.Wire();
}

TopoDS_Shape g_spikeArcShell; // Reused by Spike A below.

void SpikeB_MakePrismOnBareWireProducesUsableShell() {
  std::printf("\n[Spike B] BRepPrimAPI_MakePrism on a bare TopoDS_Wire\n");
  const TopoDS_Wire arcWire = MakeArcWire(-2.0);
  check(arcWire.ShapeType() == TopAbs_WIRE,
        "input to MakePrism is genuinely a TopoDS_Wire, not a face");

  BRepPrimAPI_MakePrism prism(arcWire, gp_Vec(0.0, 14.0, 0.0), /*Copy=*/true);
  prism.Build();
  check(prism.IsDone(), "MakePrism on a bare wire: IsDone()");
  const TopoDS_Shape result = prism.Shape();
  check(!result.IsNull(), "MakePrism on a bare wire: result is non-null");
  std::printf("  INFO result.ShapeType() = %d (TopAbs_SHELL=%d, TopAbs_FACE=%d)\n",
              static_cast<int>(result.ShapeType()), static_cast<int>(TopAbs_SHELL),
              static_cast<int>(TopAbs_FACE));
  check(
      result.ShapeType() == TopAbs_SHELL || result.ShapeType() == TopAbs_FACE,
      "MakePrism on a bare wire produces a SHELL or FACE (an open surface), not a solid/compound");
  check(BRepCheck_Analyzer(result, false).IsValid(),
        "MakePrism-on-wire result is topologically valid");

  int faceCount = 0;
  for (TopExp_Explorer explorer(result, TopAbs_FACE); explorer.More(); explorer.Next())
    ++faceCount;
  std::printf("  INFO face count of swept shell = %d\n", faceCount);
  check(faceCount >= 1, "MakePrism-on-wire result has at least one face");

  GProp_GProps properties;
  BRepGProp::SurfaceProperties(result, properties);
  const double area = std::abs(properties.Mass());
  std::printf("  INFO swept shell surface area = %.6f mm^2\n", area);
  check(area > 1.0, "MakePrism-on-wire result has non-trivial surface area (not degenerate)");

  std::printf("VERDICT: BRepPrimAPI_MakePrism on a bare TopoDS_Wire produces a usable open "
              "shell on this pinned OCCT build.\n");
  g_spikeArcShell = result;
}

// =============================================================================
// SPIKE A: BRepAlgoAPI_Splitter with a genuinely NON-PLANAR SHELL tool
// (mutation.cpp's own RunPlanarSplitIntoHistory, the only other user of this
// class in this codebase, only ever exercises a PLANAR TopoDS_Face tool).
// mold_tooling_split's own construction depends on this.
// =============================================================================

void SpikeA_SplitterWithNonPlanarShellToolYieldsTwoSolids() {
  std::printf("\n[Spike A] BRepAlgoAPI_Splitter with a non-planar SHELL tool\n");
  check(!g_spikeArcShell.IsNull(), "Spike A has a curved shell tool from Spike B to split with");

  // Block: a plain [0,10]x[0,10]x[0,10] box. The arc shell (built in Spike B,
  // spanning X in [-2,12], Y in [-2,12], Z in [2,6]) fully crosses it,
  // separating a "below the dome" piece from an "above the dome + corners"
  // piece.
  const TopoDS_Shape block = BRepPrimAPI_MakeBox(10.0, 10.0, 10.0).Shape();

  BRepAlgoAPI_Splitter splitter;
  NCollection_List<TopoDS_Shape> objects;
  objects.Append(block);
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(g_spikeArcShell);
  splitter.SetArguments(objects);
  splitter.SetTools(tools);
  splitter.SetRunParallel(false);
  splitter.SetToFillHistory(true);
  splitter.Build();

  check(!splitter.HasErrors(), "Splitter with a non-planar shell tool: no errors");
  const TopoDS_Shape result = splitter.Shape();
  check(!result.IsNull(), "Splitter result is non-null");

  int solidCount = 0;
  double totalVolume = 0.0;
  for (TopExp_Explorer explorer(result, TopAbs_SOLID); explorer.More(); explorer.Next()) {
    ++solidCount;
    GProp_GProps properties;
    BRepGProp::VolumeProperties(explorer.Current(), properties);
    totalVolume += std::abs(properties.Mass());
  }
  std::printf("  INFO solid count = %d, total volume = %.6f (box volume = 1000)\n", solidCount,
              totalVolume);
  check(solidCount == 2, "Splitter with a non-planar shell tool yields exactly 2 solids");
  // The split must be a partition, not a lossy approximation: the two
  // pieces' volumes must sum back to EXACTLY the box's own 10*10*10 = 1000.
  checkNear(totalVolume, 1000.0, 1e-6, "split solids' volumes sum exactly to the box's own volume");

  const occ::handle<BRepTools_History> history = splitter.History();
  check(!history.IsNull(), "Splitter records a non-null History()");
  // Exercise the history concretely, not just check it is non-null. EVERY
  // one of the block's own 6 faces must be accounted for in the result,
  // EITHER via a non-empty Modified() image (the arc, extruded uniformly
  // along Y across the block's own Y range, genuinely re-trims all 4 SIDE
  // faces x=0/x=10/y=0/y=10 -- each lies within the dome's own extent along
  // the other two axes) OR by surviving with IDENTICAL TShape identity (the
  // top z=10 and bottom z=0 faces sit entirely outside the dome's own
  // z=[2,6] range, so BRepAlgoAPI_Splitter's OWN convention is to carry
  // them through completely UNCHANGED, needing no Modified() entry at all
  // -- confirmed empirically below rather than assumed, exactly the
  // "verify, don't assume" discipline this file's own header cites).
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> resultFaces;
  TopExp::MapShapes(result, TopAbs_FACE, resultFaces);
  int modifiedCount = 0;
  int unchangedCount = 0;
  int unaccountedCount = 0;
  for (TopExp_Explorer explorer(block, TopAbs_FACE); explorer.More(); explorer.Next()) {
    const TopoDS_Shape& original = explorer.Current();
    const auto& modified = history->Modified(original);
    if (!modified.IsEmpty()) {
      ++modifiedCount;
    } else if (resultFaces.FindIndex(original) != 0) {
      ++unchangedCount;
    } else {
      ++unaccountedCount;
    }
  }
  std::printf("  INFO block faces: %d re-trimmed (Modified()), %d survived unchanged (IsSame in "
              "result), %d unaccounted for (of 6 total)\n",
              modifiedCount, unchangedCount, unaccountedCount);
  check(modifiedCount + unchangedCount == 6 && unaccountedCount == 0,
        "History() (Modified() plus surviving identity) accounts for all 6 of the block's "
        "original faces");
  check(modifiedCount == 4, "exactly the 4 side faces the dome genuinely crosses (x=0, x=10, "
                            "y=0, y=10) show a real Modified() re-trim image");
  check(unchangedCount == 2, "exactly the 2 faces outside the dome's own z-range (top, bottom) "
                             "survive with unchanged identity");

  std::printf("VERDICT: BRepAlgoAPI_Splitter with a non-planar SHELL tool yields exactly 2 "
              "solids with a real, usable History() on this pinned OCCT build.\n");
}

// =============================================================================
// Fixture builders.
// =============================================================================

/// A "ball mold" bicone: two conical faces meeting at a circular equator of
/// `radius` at z=0, apexes at z=+/-halfHeight, built by revolving a
/// triangular profile face (apex-bottom -> equator -> apex-top -> back down
/// the axis) 360 degrees around Z — BRepPrimAPI_MakeRevol on a FACE (not
/// merely a wire), the same class geometry.cpp's own `revolve` operation
/// uses (EvaluateRevolve), so this is a genuine SOLID (both apexes are
/// degenerate axis vertices, not flat caps — the same construction
/// BRepPrimAPI_MakeCone itself uses internally for a zero top radius).
TopoDS_Shape MakeBicone(const double radius, const double halfHeight) {
  BRepBuilderAPI_MakePolygon polygon;
  polygon.Add(gp_Pnt(0.0, 0.0, -halfHeight));
  polygon.Add(gp_Pnt(radius, 0.0, 0.0));
  polygon.Add(gp_Pnt(0.0, 0.0, halfHeight));
  polygon.Close();
  if (!polygon.IsDone())
    throw std::runtime_error("test fixture: bicone profile wire construction failed");
  const gp_Pln plane(gp_Pnt(0.0, 0.0, 0.0), gp_Dir(0.0, 1.0, 0.0));
  BRepBuilderAPI_MakeFace faceMaker(plane, polygon.Wire(), /*Inside=*/true);
  if (!faceMaker.IsDone())
    throw std::runtime_error("test fixture: bicone profile face construction failed");
  BRepPrimAPI_MakeRevol revol(faceMaker.Face(),
                              gp_Ax1(gp_Pnt(0.0, 0.0, 0.0), gp_Dir(0.0, 0.0, 1.0)),
                              /*Copy=*/true);
  revol.Build();
  if (!revol.IsDone())
    throw std::runtime_error("test fixture: bicone revolve failed");
  return revol.Shape();
}

/// The bicone's own 2 lateral faces, classified upper (z>0 apex side) /
/// lower (z<0 apex side) by their own centroid's z coordinate.
struct BiconeFaces final {
  TopoDS_Face upper;
  TopoDS_Face lower;
};

BiconeFaces SplitBiconeFaces(const TopoDS_Shape& bicone) {
  BiconeFaces faces;
  int count = 0;
  for (TopExp_Explorer explorer(bicone, TopAbs_FACE); explorer.More(); explorer.Next()) {
    ++count;
    const TopoDS_Face face = TopoDS::Face(explorer.Current());
    GProp_GProps properties;
    BRepGProp::SurfaceProperties(face, properties);
    if (properties.CentreOfMass().Z() > 0.0)
      faces.upper = face;
    else
      faces.lower = face;
  }
  if (count != 2 || faces.upper.IsNull() || faces.lower.IsNull())
    throw std::runtime_error("test fixture: bicone did not produce exactly 2 lateral faces");
  return faces;
}

/// A square bipyramid: apexes on the Z axis at z=+/-halfHeight, equator the
/// AXIS-ALIGNED SQUARE [-halfWidth,halfWidth]^2 at z=0, 8 planar triangular
/// faces (4 upper, 4 lower). Used for the FULL mold_tooling_split pipeline
/// tests INSTEAD of the bicone: MEASURED while writing those tests (not
/// assumed) that BRepAlgoAPI_Splitter genuinely requires its own tool to
/// fully cross the target's material in every direction being divided (the
/// same requirement mutation.cpp's own BuildSplitTool comment states for
/// its deliberately-oversized planar fixture) -- a bicone's own CIRCULAR
/// equator, swept straight up by mold_parting_surface, is geometrically
/// unable to reach a RECTANGULAR tooling block's own corners (a circle
/// inscribed in a square never touches the square's corners, at ANY
/// margin, since the corners sit at radius*sqrt(2)), leaving a connected
/// "frame" of block material around the tool that keeps the split result
/// as ONE solid instead of two. An AXIS-ALIGNED SQUARE equator's own 4
/// corners ARE exactly its own bounding box's corners, so at ZERO lateral
/// margin the swept parting surface exactly reaches the block's own
/// corners too, letting BRepAlgoAPI_Splitter genuinely divide the whole
/// block. Faces are independently built then SEWN (the same
/// MakeOpenBoxWithHole lesson: independently-constructed faces share no
/// edge identity until sewn) into one solid.
TopoDS_Shape MakeSquareBipyramid(const double halfWidth, const double halfHeight) {
  const gp_Pnt topApex(0.0, 0.0, halfHeight);
  const gp_Pnt bottomApex(0.0, 0.0, -halfHeight);
  const gp_Pnt corners[4] = {gp_Pnt(halfWidth, halfWidth, 0.0), gp_Pnt(-halfWidth, halfWidth, 0.0),
                             gp_Pnt(-halfWidth, -halfWidth, 0.0),
                             gp_Pnt(halfWidth, -halfWidth, 0.0)};
  const auto triangle = [](const gp_Pnt& a, const gp_Pnt& b, const gp_Pnt& c) {
    BRepBuilderAPI_MakePolygon polygon;
    polygon.Add(a);
    polygon.Add(b);
    polygon.Add(c);
    polygon.Close();
    if (!polygon.IsDone())
      throw std::runtime_error("test fixture: bipyramid triangle wire construction failed");
    BRepBuilderAPI_MakeFace faceMaker(polygon.Wire(), /*OnlyPlane=*/true);
    if (!faceMaker.IsDone())
      throw std::runtime_error("test fixture: bipyramid triangle face construction failed");
    return faceMaker.Face();
  };
  BRepBuilderAPI_Sewing sewing(1e-6);
  for (int i = 0; i < 4; ++i) {
    sewing.Add(triangle(corners[i], corners[(i + 1) % 4], topApex));
    sewing.Add(triangle(corners[(i + 1) % 4], corners[i], bottomApex));
  }
  sewing.Perform();
  const TopoDS_Shape sewn = sewing.SewedShape();
  if (sewn.IsNull())
    throw std::runtime_error("test fixture: bipyramid sewing produced no result");
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> sewnFaces;
  TopExp::MapShapes(sewn, TopAbs_FACE, sewnFaces);
  if (sewnFaces.Extent() != 8)
    throw std::runtime_error("test fixture: bipyramid sewing did not yield exactly 8 faces");
  BRep_Builder builder;
  TopoDS_Shell shell;
  builder.MakeShell(shell);
  for (int index = 1; index <= sewnFaces.Extent(); ++index)
    builder.Add(shell, TopoDS::Face(sewnFaces(index)));
  BRepBuilderAPI_MakeSolid solidMaker(shell);
  if (!solidMaker.IsDone())
    throw std::runtime_error("test fixture: bipyramid solid construction failed");
  TopoDS_Solid solid = TopoDS::Solid(solidMaker.Shape());
  BRepLib::OrientClosedSolid(solid);
  if (!BRepCheck_Analyzer(solid, false).IsValid())
    throw std::runtime_error("test fixture: bipyramid solid is invalid");
  return solid;
}

EvaluatedBody MakeFixtureBody(const std::string& operationId, const std::string& bodyId,
                              const TopoDS_Shape& shape) {
  EvaluatedBody body;
  body.operationId = operationId;
  body.bodyId = bodyId;
  body.shape = shape;
  body.probes = aeth::ProbeShape(shape);
  return body;
}

nlohmann::json Vec3Json(const double x, const double y, const double z) {
  return {{"x", x}, {"y", y}, {"z", z}};
}

nlohmann::json BoxOperation(const std::string& id, const std::string& bodyId, const double width,
                            const double depth, const double height) {
  return {{"id", id},
          {"type", "create_box"},
          {"outputBodyId", bodyId},
          {"parameters",
           {{"width", width},
            {"depth", depth},
            {"height", height},
            {"placement",
             {{"origin", {0.0, 0.0, 0.0}},
              {"zDirection", {0.0, 0.0, 1.0}},
              {"xDirection", {1.0, 0.0, 0.0}}}}}}};
}

nlohmann::json MoldPartingLineOperation(const std::string& id, const std::string& bodyId,
                                        const std::string& targetId,
                                        const nlohmann::json& pullDirection,
                                        const std::optional<double> toleranceDeg = std::nullopt) {
  nlohmann::json parameters = {{"targetOperationId", targetId}, {"pullDirection", pullDirection}};
  if (toleranceDeg.has_value())
    parameters["draftAngleToleranceDeg"] = *toleranceDeg;
  return {{"id", id},
          {"type", "mold_parting_line"},
          {"outputBodyId", bodyId},
          {"parameters", parameters}};
}

// Every test below builds its own BodyPool + (when needed) allOperations
// array directly — a raw OCCT fixture no JSON primitive can produce,
// exercised by calling an executor directly rather than through full JSON
// dispatch, the surfacing_test.cpp precedent.

// =============================================================================
// 1. ClassifyDraftFaces.
// =============================================================================

void ClassifyDraftFacesBiconeOppositeSigns() {
  std::printf("\n[ClassifyDraftFaces] bicone: upper/lower faces classify to opposite signs\n");
  const TopoDS_Shape bicone = MakeBicone(6.0, 8.0);
  const BiconeFaces faces = SplitBiconeFaces(bicone);

  // Independent check (NOT via ClassifyDraftFaces): sample each face's own
  // outward normal at its own UV-domain midpoint, via OutwardNormalAtPoint
  // directly (geometry_measures.cpp) -- proves the fixture itself has real
  // sign variation before trusting the function under test to say so.
  // Deliberately NOT the face's own area centroid projected onto its
  // surface: by full-360-degree rotational symmetry around the revolve
  // axis, a cone face's own area centroid sits EXACTLY ON that axis --
  // point-on-axis is a genuinely degenerate case for "nearest point on an
  // infinite conical surface" (a whole circle of equally-near points, not
  // one), which MEASURABLY throws inside GeomAPI_ProjectPointOnSurf on this
  // pinned OCCT build (caught empirically while writing this test, not
  // assumed) -- the UV-domain-midpoint direct surface evaluation below sits
  // strictly off-axis by construction and needs no projection at all.
  const auto independentDot = [](const TopoDS_Face& face) {
    double uMin = 0.0;
    double uMax = 0.0;
    double vMin = 0.0;
    double vMax = 0.0;
    BRepTools::UVBounds(face, uMin, uMax, vMin, vMax);
    const gp_Pnt2d midUv((uMin + uMax) / 2.0, (vMin + vMax) / 2.0);
    return aeth::OutwardNormalAtPoint(face, midUv).Z();
  };
  const double upperDot = independentDot(faces.upper);
  const double lowerDot = independentDot(faces.lower);
  std::printf("  INFO independently-sampled dot(normal,+Z): upper=%.4f lower=%.4f\n", upperDot,
              lowerDot);
  check(upperDot > 0.0, "independent check: bicone's upper (top-apex) face normal has positive Z");
  check(lowerDot < 0.0,
        "independent check: bicone's lower (bottom-apex) face normal has negative Z");

  const std::vector<aeth::DraftFaceResult> classified =
      aeth::ClassifyDraftFaces(bicone, gp_Dir(0.0, 0.0, 1.0), 0.5);
  check(classified.size() == 2, "ClassifyDraftFaces returns exactly 2 results for the bicone");
  for (const auto& result : classified) {
    const bool isUpper = result.face.IsSame(faces.upper);
    const DraftClassification expected =
        isUpper ? DraftClassification::Positive : DraftClassification::Negative;
    check(result.classification == expected,
          isUpper ? "ClassifyDraftFaces: upper face classifies Positive"
                  : "ClassifyDraftFaces: lower face classifies Negative");
  }
}

void ClassifyDraftFacesBoxSidesAreNoDraft() {
  std::printf("\n[ClassifyDraftFaces] plain box: side walls classify NoDraft, caps classify "
              "Positive/Negative\n");
  const TopoDS_Shape box = BRepPrimAPI_MakeBox(4.0, 4.0, 4.0).Shape();
  const std::vector<aeth::DraftFaceResult> classified =
      aeth::ClassifyDraftFaces(box, gp_Dir(0.0, 0.0, 1.0), 0.5);
  check(classified.size() == 6, "ClassifyDraftFaces returns exactly 6 results for a box");
  int positive = 0;
  int negative = 0;
  int noDraft = 0;
  for (const auto& result : classified) {
    GProp_GProps properties;
    BRepGProp::SurfaceProperties(result.face, properties);
    const aeth::Axis normal =
        aeth::PlanarOutwardNormal(result.face, BRepAdaptor_Surface(result.face, true));
    const double z = normal.has_value() ? (*normal)[2] : 0.0;
    if (std::abs(z) > 0.999) {
      // A vertical (top/bottom) cap: independently z>0 -> Positive, z<0 ->
      // Negative for pull direction +Z.
      check(result.classification ==
                (z > 0.0 ? DraftClassification::Positive : DraftClassification::Negative),
            "box cap face classifies by its own independently-sampled normal sign");
    } else {
      check(std::abs(z) < 1e-9, "box side wall's own outward normal has zero Z (a genuine "
                                "vertical wall, sanity check on the fixture itself)");
      check(result.classification == DraftClassification::NoDraft,
            "box side wall classifies NoDraft (perpendicular to pull direction)");
    }
    switch (result.classification) {
    case DraftClassification::Positive:
      ++positive;
      break;
    case DraftClassification::Negative:
      ++negative;
      break;
    case DraftClassification::NoDraft:
      ++noDraft;
      break;
    case DraftClassification::Straddle:
      break;
    }
  }
  check(positive == 1 && negative == 1 && noDraft == 4,
        "box classification counts: 1 positive (top), 1 negative (bottom), 4 no-draft (sides)");
}

void ClassifyDraftFacesToleranceBand() {
  std::printf("\n[ClassifyDraftFaces] tolerance band around vertical\n");
  const TopoDS_Shape box = BRepPrimAPI_MakeBox(4.0, 4.0, 4.0).Shape();
  // At angleToleranceDeg=90, band=sin(90)=1, so EVERY face (|dot|<=1 always)
  // classifies NoDraft -- a clean, hand-derivable boundary case indepedent
  // of the fixture's own geometry.
  const std::vector<aeth::DraftFaceResult> allNoDraft =
      aeth::ClassifyDraftFaces(box, gp_Dir(0.0, 0.0, 1.0), 30.0);
  int noDraftCount = 0;
  for (const auto& result : allNoDraft) {
    if (result.classification == DraftClassification::NoDraft)
      ++noDraftCount;
  }
  // 30 degrees is the schema's own max, band=sin(30)=0.5: the box's side
  // walls (dot=0) still classify NoDraft (0 < 0.5); its caps (dot=+/-1)
  // still classify Positive/Negative (1 > 0.5). So this only re-confirms
  // the same 4/1/1 split as the default-tolerance test above -- included to
  // pin the boundary value schema itself allows, not to find new behavior.
  check(noDraftCount == 4, "at the schema's max tolerance (30deg), box side walls still classify "
                           "NoDraft and its caps still classify Positive/Negative");

  bool threw = false;
  try {
    aeth::ClassifyDraftFaces(box, gp_Dir(0.0, 0.0, 1.0), 30.0001);
  } catch (const std::invalid_argument&) {
    threw = true;
  }
  check(threw, "ClassifyDraftFaces refuses a tolerance above the schema's own 30deg ceiling");
}

// =============================================================================
// 2. mold_parting_line (full ExecuteOperation dispatch, and direct fixtures
// for shapes no JSON primitive can produce).
// =============================================================================

void PartingLineBiconeFindsEquator() {
  std::printf("\n[mold_parting_line] bicone: finds the equator loop\n");
  std::atomic_bool cancelled{false};
  // A bicone is not producible by any existing JSON primitive (confirmed:
  // create_cylinder/cone/sphere/torus/wedge have no two-slope revolve
  // shape) -- import it via the direct-executor path instead, mirroring
  // surfacing_test.cpp's own non-planar-hexagon precedent.
  BodyPool pool;
  const TopoDS_Shape bicone = MakeBicone(6.0, 8.0);
  pool.Produce(MakeFixtureBody("target-op", "target-body", bicone));

  const nlohmann::json operation =
      MoldPartingLineOperation("pl-op", "pl-body", "target-op", Vec3Json(0.0, 0.0, 1.0));
  const EvaluatedBody result =
      aeth::EvaluateMoldPartingLine(operation, pool, nullptr, nullptr, cancelled);
  check(result.shape.ShapeType() == TopAbs_WIRE, "mold_parting_line produces a WIRE body");
  check(result.probes.solidCount == 0, "mold_parting_line's wire body has solidCount 0");

  // Independent check: the equator is the circle z=0, radius=6. Every
  // vertex of the resulting wire must sit at z=0 within tolerance, and its
  // total edge length must equal 2*pi*6 (a full circle) within a loose
  // numeric tolerance for the underlying curve's own discretization-free
  // analytic length.
  GProp_GProps lengthProps;
  BRepGProp::LinearProperties(result.shape, lengthProps);
  const double length = lengthProps.Mass();
  const double kPi = 3.14159265358979323846;
  std::printf("  INFO parting line length = %.6f (expected 2*pi*6 = %.6f)\n", length,
              2.0 * kPi * 6.0);
  checkNear(length, 2.0 * kPi * 6.0, 1e-6, "parting line's total length is exactly 2*pi*radius");

  for (TopExp_Explorer explorer(result.shape, TopAbs_VERTEX); explorer.More(); explorer.Next()) {
    const gp_Pnt point = BRep_Tool::Pnt(TopoDS::Vertex(explorer.Current()));
    checkNear(point.Z(), 0.0, 1e-6, "every vertex of the parting line sits at z=0 (the equator)");
    checkNear(std::sqrt(point.X() * point.X() + point.Y() * point.Y()), 6.0, 1e-6,
              "every vertex of the parting line sits at radius 6 from the axis");
  }
}

void PartingLineNoDraftVariationRefusal() {
  std::printf("\n[mold_parting_line] plain box: E_PARTING_LINE_NO_DRAFT_VARIATION\n");
  std::atomic_bool cancelled{false};
  // Full dispatch with a real NamingRegistry engaged: element_names.cpp's
  // own OperationIdPrefix requires every harvested operation id to be
  // UUID-shaped (hex digits and dashes only) -- create_box's own
  // HarvestBoxBirth runs before mold_parting_line even starts, so BOTH
  // operation ids need real UUID shapes here (discovered empirically: a
  // readable "box-op" id throws "element naming requires UUID operation
  // ids", rewrapped by ExecuteOperation's own tail catch into an
  // OperationFailure with NULL details -- not a mold_parting_line bug).
  nlohmann::json program = nlohmann::json::array();
  program.push_back(
      BoxOperation("00000000-0000-0000-0000-000000000001", "box-body", 4.0, 4.0, 4.0));
  program.push_back(MoldPartingLineOperation("00000000-0000-0000-0000-000000000002", "pl-body",
                                             "00000000-0000-0000-0000-000000000001",
                                             Vec3Json(0.0, 0.0, 1.0)));

  aeth::NamingRegistry registry;
  bool refused = false;
  std::string code;
  try {
    aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
  } catch (const aeth::OperationFailure& error) {
    refused = true;
    code = error.Details().value("toolingCode", "");
  }
  check(refused, "mold_parting_line on a plain box refuses (through full dispatch)");
  check(code == "E_PARTING_LINE_NO_DRAFT_VARIATION",
        "refusal code is E_PARTING_LINE_NO_DRAFT_VARIATION");
}

void PartingLineStraddleFaceRefusal() {
  std::printf("\n[mold_parting_line] full sphere: E_PARTING_LINE_STRADDLE_FACE\n");
  std::atomic_bool cancelled{false};
  BodyPool pool;
  const TopoDS_Shape sphere = BRepPrimAPI_MakeSphere(5.0).Shape();
  check(aeth::ProbeShape(sphere).faceCount == 1, "a full OCCT sphere is genuinely one single face "
                                                 "(sanity check on the fixture)");
  pool.Produce(MakeFixtureBody("target-op", "target-body", sphere));
  const nlohmann::json operation =
      MoldPartingLineOperation("pl-op", "pl-body", "target-op", Vec3Json(0.0, 0.0, 1.0));

  bool refused = false;
  std::string code;
  try {
    aeth::EvaluateMoldPartingLine(operation, pool, nullptr, nullptr, cancelled);
  } catch (const aeth::OperationFailure& error) {
    refused = true;
    code = error.Details().value("toolingCode", "");
  }
  check(refused, "mold_parting_line on a full sphere refuses");
  check(code == "E_PARTING_LINE_STRADDLE_FACE", "refusal code is E_PARTING_LINE_STRADDLE_FACE");
}

void PartingLineMultipleLoopsRefusal() {
  std::printf("\n[mold_parting_line] two disjoint bicones: E_PARTING_LINE_MULTIPLE_LOOPS\n");
  std::atomic_bool cancelled{false};
  BodyPool pool;
  const TopoDS_Shape bicone1 = MakeBicone(6.0, 8.0);
  gp_Trsf move;
  move.SetTranslation(gp_Vec(40.0, 0.0, 0.0));
  const TopoDS_Shape bicone2 = BRepBuilderAPI_Transform(MakeBicone(6.0, 8.0), move, true).Shape();
  BRep_Builder builder;
  TopoDS_Compound compound;
  builder.MakeCompound(compound);
  builder.Add(compound, bicone1);
  builder.Add(compound, bicone2);
  pool.Produce(MakeFixtureBody("target-op", "target-body", compound));
  const nlohmann::json operation =
      MoldPartingLineOperation("pl-op", "pl-body", "target-op", Vec3Json(0.0, 0.0, 1.0));

  bool refused = false;
  std::string code;
  std::string message;
  try {
    aeth::EvaluateMoldPartingLine(operation, pool, nullptr, nullptr, cancelled);
  } catch (const aeth::OperationFailure& error) {
    refused = true;
    code = error.Details().value("toolingCode", "");
    message = error.what();
  }
  check(refused, "mold_parting_line on two disjoint bicones refuses");
  check(code == "E_PARTING_LINE_MULTIPLE_LOOPS", "refusal code is E_PARTING_LINE_MULTIPLE_LOOPS");
  check(message.find("2") != std::string::npos, "refusal message reports the loop count (2)");
}

void PartingLineNamingDoesNotThrow() {
  std::printf("\n[mold_parting_line] naming: AddDerivedPrimitive path does not throw\n");
  std::atomic_bool cancelled{false};
  BodyPool pool;
  const TopoDS_Shape bicone = MakeBicone(6.0, 8.0);
  pool.Produce(MakeFixtureBody("11111111-1111-1111-1111-111111111111", "target-body", bicone));
  const nlohmann::json operation =
      MoldPartingLineOperation("22222222-2222-2222-2222-222222222222", "pl-body",
                               "11111111-1111-1111-1111-111111111111", Vec3Json(0.0, 0.0, 1.0));

  aeth::ElementNameBook book;
  book.AddPrimitive("11111111-1111-1111-1111-111111111111", bicone);
  bool threw = false;
  try {
    aeth::EvaluateMoldPartingLine(operation, pool, &book, nullptr, cancelled);
  } catch (const std::exception& error) {
    threw = true;
    std::printf("  INFO unexpected exception: %s\n", error.what());
  }
  check(!threw, "mold_parting_line's AddDerivedPrimitive naming path does not throw when the "
                "target's own sub-shapes are already named");
}

// =============================================================================
// 3. GroupEdgesIntoLoops (topology_adjacency.hpp) directly.
// =============================================================================

std::vector<TopoDS_Edge> SquareLoopEdges(const gp_Pnt& corner, const double side) {
  BRepBuilderAPI_MakePolygon polygon;
  polygon.Add(corner);
  polygon.Add(corner.Translated(gp_Vec(side, 0.0, 0.0)));
  polygon.Add(corner.Translated(gp_Vec(side, side, 0.0)));
  polygon.Add(corner.Translated(gp_Vec(0.0, side, 0.0)));
  polygon.Close();
  std::vector<TopoDS_Edge> edges;
  for (TopExp_Explorer explorer(polygon.Wire(), TopAbs_EDGE); explorer.More(); explorer.Next())
    edges.push_back(TopoDS::Edge(explorer.Current()));
  return edges;
}

void GroupEdgesIntoLoopsEmpty() {
  std::printf("\n[GroupEdgesIntoLoops] empty input -> empty output\n");
  const std::vector<std::vector<TopoDS_Edge>> loops = aeth::GroupEdgesIntoLoops({});
  check(loops.empty(), "GroupEdgesIntoLoops({}) returns no loops");
}

void GroupEdgesIntoLoopsSingleSquare() {
  std::printf("\n[GroupEdgesIntoLoops] one square -> one loop of 4 edges\n");
  const std::vector<TopoDS_Edge> square = SquareLoopEdges(gp_Pnt(0, 0, 0), 3.0);
  check(square.size() == 4, "square fixture has exactly 4 edges (sanity check)");
  const std::vector<std::vector<TopoDS_Edge>> loops = aeth::GroupEdgesIntoLoops(square);
  check(loops.size() == 1, "GroupEdgesIntoLoops finds exactly one loop for a single square");
  if (!loops.empty())
    check(loops.front().size() == 4, "the found loop has all 4 of the square's edges");
}

void GroupEdgesIntoLoopsTwoDisjointSquares() {
  std::printf("\n[GroupEdgesIntoLoops] two disjoint squares -> two loops\n");
  std::vector<TopoDS_Edge> edges = SquareLoopEdges(gp_Pnt(0, 0, 0), 3.0);
  const std::vector<TopoDS_Edge> second = SquareLoopEdges(gp_Pnt(100, 0, 0), 3.0);
  edges.insert(edges.end(), second.begin(), second.end());
  const std::vector<std::vector<TopoDS_Edge>> loops = aeth::GroupEdgesIntoLoops(edges);
  check(loops.size() == 2, "GroupEdgesIntoLoops finds exactly two loops for two disjoint squares");
  for (const auto& loop : loops)
    check(loop.size() == 4, "each found loop has exactly 4 edges");
}

void GroupEdgesIntoLoopsNonManifoldJunctionRefuses() {
  std::printf("\n[GroupEdgesIntoLoops] a degree-3 vertex refuses\n");
  std::vector<TopoDS_Edge> edges = SquareLoopEdges(gp_Pnt(0, 0, 0), 3.0);
  // A third edge touching one of the square's own corners (but going
  // nowhere useful) gives that vertex degree 3 among the edge set.
  BRepBuilderAPI_MakeEdge stray(gp_Pnt(0, 0, 0), gp_Pnt(0, 0, 5));
  edges.push_back(stray.Edge());
  bool threw = false;
  try {
    aeth::GroupEdgesIntoLoops(edges);
  } catch (const Standard_Failure&) {
    threw = true;
  }
  check(threw, "GroupEdgesIntoLoops refuses a non-manifold (degree != 2) vertex");
}

// =============================================================================
// 4. mold_shutoff_surface.
// =============================================================================

/// A hand-built OPEN shell: a rectangular box [0,W]x[0,D]x[0,H] with TWO
/// deliberate defects, neither producible by any existing JSON primitive:
/// (a) the TOP face (z=H) has a circular INNER hole of `holeRadius`, with NO
///     wall built for that hole at all -- the hole's own rim is therefore a
///     genuine free-boundary loop (one face touches it, not two) -- the
///     "hole to cap" this fixture exists to exercise.
/// (b) ONE side wall (the y=0 face) is entirely OMITTED from the shell --
///     the 4 edges that would have bounded it are therefore ALSO free,
///     forming a second, rectangular loop -- stood in for "the parting
///     line" in the exclusion test. `fakePartingLine` is built from THESE
///     SAME edges (found via a real FreeEdgesOf/GroupEdgesIntoLoops pass
///     over the finished shell, exactly the shared helper the real
///     mold_shutoff_surface executor itself uses), not from an
///     independently re-constructed same-position wire -- IsSame identity
///     is the whole point of the exclusion test (MEASURED: an
///     independently-built wire at a matching position is NOT IsSame to
///     the shell's own edges, so the exclusion test would silently match
///     nothing at all -- caught empirically while writing this fixture,
///     not assumed correct by construction).
struct OpenBoxWithHoleFixture final {
  TopoDS_Shape shell;
  TopoDS_Wire fakePartingLine; // The omitted y=0 wall's own 4 boundary edges, by real identity.
};

OpenBoxWithHoleFixture MakeOpenBoxWithHole(const double width, const double depth,
                                           const double height, const double holeRadius) {
  OpenBoxWithHoleFixture fixture;
  const auto rectFace = [](const gp_Pnt& corner, const gp_Dir& uDir, const gp_Dir& vDir,
                           const double uLen, const double vLen) {
    const gp_Vec u(uDir);
    const gp_Vec v(vDir);
    BRepBuilderAPI_MakePolygon polygon;
    polygon.Add(corner);
    polygon.Add(corner.Translated(uLen * u));
    polygon.Add(corner.Translated(uLen * u + vLen * v));
    polygon.Add(corner.Translated(vLen * v));
    polygon.Close();
    const gp_Pln plane(corner, uDir.Crossed(vDir));
    BRepBuilderAPI_MakeFace faceMaker(plane, polygon.Wire(), true);
    if (!faceMaker.IsDone())
      throw std::runtime_error("test fixture: rectFace construction failed");
    return faceMaker.Face();
  };

  // Bottom (z=0), outward normal -Z: order the polygon so uDir x vDir = -Z.
  const TopoDS_Face bottom =
      rectFace(gp_Pnt(0, 0, 0), gp_Dir(0, 1, 0), gp_Dir(1, 0, 0), depth, width);
  // y=depth wall, outward +Y.
  const TopoDS_Face yDepthWall =
      rectFace(gp_Pnt(0, depth, 0), gp_Dir(1, 0, 0), gp_Dir(0, 0, 1), width, height);
  // x=0 wall, outward -X.
  const TopoDS_Face xZeroWall =
      rectFace(gp_Pnt(0, 0, 0), gp_Dir(0, 0, 1), gp_Dir(0, 1, 0), height, depth);
  // x=width wall, outward +X.
  const TopoDS_Face xWidthWall =
      rectFace(gp_Pnt(width, 0, 0), gp_Dir(0, 1, 0), gp_Dir(0, 0, 1), depth, height);
  // y=0 wall is DELIBERATELY OMITTED (defect b) -- its own 4 edges become
  // the "fake parting line" loop, recovered below by real identity once the
  // shell is sewn (NOT independently re-constructed -- see this struct's
  // own doc comment for why that would break IsSame identity).
  // Top (z=height), outward +Z, WITH an inner circular hole (defect a) --
  // no wall built for the hole, so its rim stays free.
  TopoDS_Face top;
  {
    BRepBuilderAPI_MakePolygon outer;
    outer.Add(gp_Pnt(0, 0, height));
    outer.Add(gp_Pnt(width, 0, height));
    outer.Add(gp_Pnt(width, depth, height));
    outer.Add(gp_Pnt(0, depth, height));
    outer.Close();
    const gp_Pln plane(gp_Pnt(0, 0, height), gp_Dir(0, 0, 1));
    BRepBuilderAPI_MakeFace faceMaker(plane, outer.Wire(), true);
    if (!faceMaker.IsDone())
      throw std::runtime_error("test fixture: top face outer construction failed");
    BRepBuilderAPI_MakeEdge holeEdge(
        gp_Circ(gp_Ax2(gp_Pnt(width / 2.0, depth / 2.0, height), gp_Dir(0, 0, 1)), holeRadius));
    BRepBuilderAPI_MakeWire holeWire(holeEdge.Edge());
    faceMaker.Add(holeWire.Wire());
    if (!faceMaker.IsDone())
      throw std::runtime_error("test fixture: top face hole construction failed");
    top = faceMaker.Face();
  }

  // Each rectFace/top call above builds its OWN independent polygon/wire,
  // so no two of these 5 faces share so much as one edge YET (each is only
  // GEOMETRICALLY coincident with its neighbours, not topologically glued)
  // -- MEASURED while writing this fixture: without this sewing step, every
  // edge of every face reads as "free" (only 1 incident face), not just
  // this fixture's own two deliberate defects. BRepBuilderAPI_Sewing (the
  // same class mold_shutoff_surface's own SewIntoFreshShell wraps) merges
  // every coincident edge pair within tolerance into one SHARED edge,
  // leaving free only the boundary that has no coincident partner at all
  // -- the omitted wall's own 4 edges and the hole's own rim, exactly the
  // two loops this fixture exists to produce.
  BRepBuilderAPI_Sewing sewing(1e-6);
  sewing.Add(bottom);
  sewing.Add(yDepthWall);
  sewing.Add(xZeroWall);
  sewing.Add(xWidthWall);
  sewing.Add(top);
  sewing.Perform();
  const TopoDS_Shape sewn = sewing.SewedShape();
  if (sewn.IsNull())
    throw std::runtime_error("test fixture: open box sewing produced no result");

  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> sewnFaces;
  TopExp::MapShapes(sewn, TopAbs_FACE, sewnFaces);
  if (sewnFaces.Extent() != 5)
    throw std::runtime_error("test fixture: open box sewing did not yield exactly 5 faces");
  BRep_Builder builder;
  TopoDS_Shell shell;
  builder.MakeShell(shell);
  for (int index = 1; index <= sewnFaces.Extent(); ++index)
    builder.Add(shell, TopoDS::Face(sewnFaces(index)));
  fixture.shell = shell;

  // Recover the "fake parting line" loop from the sewn shell's OWN free
  // edges (real identity, not a re-construction): the omitted y=0 wall's
  // own boundary is the loop with 4 edges; the hole rim is the loop with 1
  // (a single closed circular edge, matching the standard OCCT
  // representation for a full circle -- see GroupEdgesIntoLoopsSingleSquare's
  // own 4-edge case for the general shape, and PartingLineBiconeFindsEquator
  // for the circular one-edge case, both already proven above).
  const std::vector<std::vector<TopoDS_Edge>> loops =
      aeth::GroupEdgesIntoLoops(aeth::FreeEdgesOf(shell));
  if (loops.size() != 2)
    throw std::runtime_error("test fixture: open box did not produce exactly 2 free loops");
  const std::vector<TopoDS_Edge>* rectangleLoop = nullptr;
  for (const auto& loop : loops) {
    if (loop.size() == 4)
      rectangleLoop = &loop;
  }
  if (rectangleLoop == nullptr)
    throw std::runtime_error("test fixture: open box's omitted-wall loop was not found");
  BRepBuilderAPI_MakeWire wireMaker;
  for (const TopoDS_Edge& edge : *rectangleLoop)
    wireMaker.Add(edge);
  if (!wireMaker.IsDone())
    throw std::runtime_error("test fixture: fake parting line wire construction failed");
  fixture.fakePartingLine = wireMaker.Wire();

  return fixture;
}

void ShutoffSurfaceCapsHoleAndExcludesPartingLine() {
  std::printf("\n[mold_shutoff_surface] hand-built open box: caps the hole, excludes the "
              "fake parting line\n");
  std::atomic_bool cancelled{false};
  const OpenBoxWithHoleFixture fixture = MakeOpenBoxWithHole(10.0, 10.0, 6.0, 2.0);
  check(!aeth::FreeEdgesOf(fixture.shell).empty(), "fixture sanity check: the open box has free "
                                                   "edges");

  BodyPool pool;
  pool.Produce(MakeFixtureBody("target-op", "target-body", fixture.shell));
  pool.Produce(MakeFixtureBody("pl-op", "pl-body", fixture.fakePartingLine));
  const nlohmann::json operation = {
      {"id", "shutoff-op"},
      {"type", "mold_shutoff_surface"},
      {"outputBodyId", "shutoff-body"},
      {"parameters", {{"targetOperationId", "target-op"}, {"partingLineOperationId", "pl-op"}}}};

  const EvaluatedBody result =
      aeth::EvaluateMoldShutoffSurface(operation, pool, nullptr, nullptr, cancelled);
  check(result.shape.ShapeType() == TopAbs_SHELL || result.shape.ShapeType() == TopAbs_FACE,
        "mold_shutoff_surface produces an open surface body");

  // Independent check: the cap must be a single circular disk of radius 2 --
  // area pi*r^2 = pi*4 -- and NOT include the fake-parting-line rectangle
  // (10x6=60, which would make the total area wildly larger).
  GProp_GProps properties;
  BRepGProp::SurfaceProperties(result.shape, properties);
  const double area = std::abs(properties.Mass());
  const double kPi = 3.14159265358979323846;
  std::printf("  INFO shutoff cap area = %.6f (expected pi*2^2 = %.6f)\n", area, kPi * 4.0);
  checkNear(area, kPi * 4.0, 1e-3,
            "shutoff surface caps EXACTLY the circular hole (area = "
            "pi*radius^2), not the excluded fake-parting-line rectangle");

  int faceCount = 0;
  for (TopExp_Explorer explorer(result.shape, TopAbs_FACE); explorer.More(); explorer.Next())
    ++faceCount;
  check(faceCount == 1, "mold_shutoff_surface caps exactly one loop (the hole; the fake parting "
                        "line loop was excluded)");
}

void ShutoffSurfaceNoHolesOnOrdinaryClosedPart() {
  std::printf("\n[mold_shutoff_surface] an ordinary closed part (the bicone): "
              "E_SHUTOFF_NO_HOLES\n");
  // See mold_tooling_feature.hpp's own documented honest scope limit: an
  // ORDINARY through-hole in a fully closed solid is not a free edge, so an
  // ordinary closed part (hole or not) always refuses here. Proves that
  // refusal fires correctly, not merely by assertion.
  std::atomic_bool cancelled{false};
  BodyPool pool;
  const TopoDS_Shape bicone = MakeBicone(6.0, 8.0);
  check(aeth::FreeEdgesOf(bicone).empty(), "fixture sanity check: the bicone, an ordinary closed "
                                           "solid, has ZERO free edges");
  pool.Produce(MakeFixtureBody("target-op", "target-body", bicone));
  // A real parting line wire (the bicone's own equator), so the exclusion
  // test has something concrete to compare against.
  const EvaluatedBody partingLine = aeth::EvaluateMoldPartingLine(
      MoldPartingLineOperation("pl-op", "pl-body", "target-op", Vec3Json(0.0, 0.0, 1.0)), pool,
      nullptr, nullptr, cancelled);
  pool.Produce(partingLine);

  const nlohmann::json operation = {
      {"id", "shutoff-op"},
      {"type", "mold_shutoff_surface"},
      {"outputBodyId", "shutoff-body"},
      {"parameters", {{"targetOperationId", "target-op"}, {"partingLineOperationId", "pl-op"}}}};
  bool refused = false;
  std::string code;
  try {
    aeth::EvaluateMoldShutoffSurface(operation, pool, nullptr, nullptr, cancelled);
  } catch (const aeth::OperationFailure& error) {
    refused = true;
    code = error.Details().value("toolingCode", "");
  }
  check(refused, "mold_shutoff_surface on the bicone (no additional free boundary) refuses");
  check(code == "E_SHUTOFF_NO_HOLES", "refusal code is E_SHUTOFF_NO_HOLES");
}

// =============================================================================
// 5. mold_parting_surface.
// =============================================================================

void PartingSurfaceSweepsBiconeEquator() {
  std::printf("\n[mold_parting_surface] sweeps the bicone's own equator wire\n");
  std::atomic_bool cancelled{false};
  BodyPool pool;
  const TopoDS_Shape bicone = MakeBicone(6.0, 8.0);
  pool.Produce(MakeFixtureBody("target-op", "target-body", bicone));
  const EvaluatedBody partingLine = aeth::EvaluateMoldPartingLine(
      MoldPartingLineOperation("pl-op", "pl-body", "target-op", Vec3Json(0.0, 0.0, 1.0)), pool,
      nullptr, nullptr, cancelled);
  pool.Produce(partingLine);

  nlohmann::json allOperations = nlohmann::json::array();
  allOperations.push_back(
      MoldPartingLineOperation("pl-op", "pl-body", "target-op", Vec3Json(0.0, 0.0, 1.0)));

  const nlohmann::json operation = {
      {"id", "ps-op"},
      {"type", "mold_parting_surface"},
      {"outputBodyId", "ps-body"},
      {"parameters", {{"partingLineOperationId", "pl-op"}, {"extensionDistanceMm", 4.0}}}};
  const EvaluatedBody result =
      aeth::EvaluateMoldPartingSurface(operation, allOperations, pool, nullptr, nullptr, cancelled);
  check(result.shape.ShapeType() == TopAbs_SHELL || result.shape.ShapeType() == TopAbs_FACE,
        "mold_parting_surface produces an open surface body");

  Bnd_Box box;
  BRepBndLib::Add(result.shape, box);
  double xmin, ymin, zmin, xmax, ymax, zmax;
  box.Get(xmin, ymin, zmin, xmax, ymax, zmax);
  std::printf("  INFO parting surface bbox z: [%.4f, %.4f] (expected [-4, 4])\n", zmin, zmax);
  checkNear(zmin, -4.0, 1e-6, "parting surface's z extent starts at -extensionDistanceMm");
  checkNear(zmax, 4.0, 1e-6, "parting surface's z extent ends at +extensionDistanceMm");
  // The equator's own radius (6) must be preserved at z=0 (a cylindrical
  // ruled surface swept straight along Z from a circle keeps its own
  // radius at every height).
  checkNear(std::sqrt(xmax * xmax), 6.0, 1e-6,
            "parting surface's own x extent still reflects the equator's radius 6");
}

/// A permanent regression test for the empirical finding that shaped
/// `SewIntoFreshShell`'s own connectivity-grouping design (mold_tooling_
/// feature.cpp): a `TopoDS_Shell` wrapping two individually-valid but
/// MUTUALLY DISCONNECTED faces is itself INVALID on this pinned OCCT build,
/// even with `BRepCheck_Analyzer`'s GeomChecks disabled -- discovered while
/// building mold_parting_surface's own shut-off knit-in (a real
/// `BRepCheck_Analyzer` false-valid assumption this file's own executors
/// used to make), not assumed. `BRepBuilderAPI_Sewing::SewedShape()` itself
/// already reports this correctly (a `TopoDS_COMPOUND` for disconnected
/// input, confirmed below), which is exactly why `SewIntoFreshShell` groups
/// by real connectivity rather than blindly rebuilding one flat shell the
/// way `stitch`'s own (connectivity-proven) precedent safely does.
void SewingTwoDisconnectedFacesIntoOneShellIsInvalid() {
  std::printf("\n[SewIntoFreshShell] two disjoint faces: a single TopoDS_Shell wrapping both is "
              "invalid; SewedShape() itself already reports a TopoDS_COMPOUND\n");
  const TopoDS_Shape a = BRepPrimAPI_MakeSphere(gp_Pnt(0, 0, 0), 3.0).Shape();
  const TopoDS_Shape b = BRepPrimAPI_MakeSphere(gp_Pnt(1000, 0, 0), 3.0).Shape();
  TopoDS_Face faceA;
  TopoDS_Face faceB;
  {
    TopExp_Explorer explorer(a, TopAbs_FACE);
    faceA = TopoDS::Face(explorer.Current());
  }
  {
    TopExp_Explorer explorer(b, TopAbs_FACE);
    faceB = TopoDS::Face(explorer.Current());
  }
  check(BRepCheck_Analyzer(faceA, false).IsValid() && BRepCheck_Analyzer(faceB, false).IsValid(),
        "both individual faces are independently valid");

  BRepBuilderAPI_Sewing sewing(1e-6);
  sewing.Add(faceA);
  sewing.Add(faceB);
  sewing.Perform();
  const TopoDS_Shape sewn = sewing.SewedShape();
  check(!sewn.IsNull(), "SewedShape() is non-null for two disjoint faces");
  check(sewn.ShapeType() == TopAbs_COMPOUND,
        "SewedShape() itself already reports a TopoDS_COMPOUND for genuinely disjoint input "
        "(never merges unrelated faces into a shell on its own)");
  check(BRepCheck_Analyzer(sewn, false).IsValid(), "that natural compound is valid");

  BRep_Builder builder;
  TopoDS_Shell forcedShell;
  builder.MakeShell(forcedShell);
  for (TopExp_Explorer explorer(sewn, TopAbs_FACE); explorer.More(); explorer.Next())
    builder.Add(forcedShell, TopoDS::Face(explorer.Current()));
  check(!BRepCheck_Analyzer(forcedShell, false).IsValid(),
        "MEASURED: forcing those same two disjoint faces into ONE TopoDS_Shell IS invalid on "
        "this pinned OCCT build, even though each face alone (and the natural compound) is "
        "valid -- the exact reason SewIntoFreshShell groups by real connectivity instead of "
        "blindly rebuilding a single shell");
}

void PartingSurfaceKnitsInShutoff() {
  std::printf("\n[mold_parting_surface] knits in an optional shut-off surface\n");
  std::atomic_bool cancelled{false};
  const OpenBoxWithHoleFixture fixture = MakeOpenBoxWithHole(10.0, 10.0, 6.0, 2.0);
  BodyPool pool;
  pool.Produce(MakeFixtureBody("target-op", "target-body", fixture.shell));
  pool.Produce(MakeFixtureBody("fake-pl-op", "fake-pl-body", fixture.fakePartingLine));
  const EvaluatedBody shutoff = aeth::EvaluateMoldShutoffSurface(
      {{"id", "shutoff-op"},
       {"type", "mold_shutoff_surface"},
       {"outputBodyId", "shutoff-body"},
       {"parameters",
        {{"targetOperationId", "target-op"}, {"partingLineOperationId", "fake-pl-op"}}}},
      pool, nullptr, nullptr, cancelled);
  pool.Produce(shutoff);

  // A REAL mold_parting_line wire, unrelated to the box fixture, purely so
  // mold_parting_surface has a valid wire+pullDirection to sweep.
  const TopoDS_Shape bicone = MakeBicone(6.0, 8.0);
  pool.Produce(MakeFixtureBody("bicone-op", "bicone-body", bicone));
  const EvaluatedBody partingLine = aeth::EvaluateMoldPartingLine(
      MoldPartingLineOperation("pl-op", "pl-body", "bicone-op", Vec3Json(0.0, 0.0, 1.0)), pool,
      nullptr, nullptr, cancelled);
  pool.Produce(partingLine);

  nlohmann::json allOperations = nlohmann::json::array();
  allOperations.push_back(
      MoldPartingLineOperation("pl-op", "pl-body", "bicone-op", Vec3Json(0.0, 0.0, 1.0)));

  const nlohmann::json operation = {{"id", "ps-op"},
                                    {"type", "mold_parting_surface"},
                                    {"outputBodyId", "ps-body"},
                                    {"parameters",
                                     {{"partingLineOperationId", "pl-op"},
                                      {"shutoffSurfaceOperationId", "shutoff-op"},
                                      {"extensionDistanceMm", 4.0}}}};
  const EvaluatedBody result =
      aeth::EvaluateMoldPartingSurface(operation, allOperations, pool, nullptr, nullptr, cancelled);
  GProp_GProps properties;
  BRepGProp::SurfaceProperties(result.shape, properties);
  const double sweptOnlyArea = [&] {
    BodyPool freshPool;
    freshPool.Produce(MakeFixtureBody("bicone-op2", "bicone-body2", MakeBicone(6.0, 8.0)));
    const EvaluatedBody freshLine = aeth::EvaluateMoldPartingLine(
        MoldPartingLineOperation("pl-op2", "pl-body2", "bicone-op2", Vec3Json(0.0, 0.0, 1.0)),
        freshPool, nullptr, nullptr, cancelled);
    freshPool.Produce(freshLine);
    nlohmann::json freshAllOps = nlohmann::json::array();
    freshAllOps.push_back(
        MoldPartingLineOperation("pl-op2", "pl-body2", "bicone-op2", Vec3Json(0.0, 0.0, 1.0)));
    const EvaluatedBody swept = aeth::EvaluateMoldPartingSurface(
        {{"id", "ps-op2"},
         {"type", "mold_parting_surface"},
         {"outputBodyId", "ps-body2"},
         {"parameters", {{"partingLineOperationId", "pl-op2"}, {"extensionDistanceMm", 4.0}}}},
        freshAllOps, freshPool, nullptr, nullptr, cancelled);
    GProp_GProps sweptProps;
    BRepGProp::SurfaceProperties(swept.shape, sweptProps);
    return std::abs(sweptProps.Mass());
  }();
  std::printf("  INFO knitted-in area = %.4f, swept-only area = %.4f\n",
              std::abs(properties.Mass()), sweptOnlyArea);
  check(std::abs(properties.Mass()) > sweptOnlyArea,
        "knitting in the shut-off surface strictly increases the parting surface's own area");
}

void PartingSurfaceZeroExtensionRefused() {
  std::printf("\n[mold_parting_surface] extensionDistanceMm <= 0 refuses before any OCCT call\n");
  std::atomic_bool cancelled{false};
  BodyPool pool;
  const TopoDS_Shape bicone = MakeBicone(6.0, 8.0);
  pool.Produce(MakeFixtureBody("target-op", "target-body", bicone));
  const EvaluatedBody partingLine = aeth::EvaluateMoldPartingLine(
      MoldPartingLineOperation("pl-op", "pl-body", "target-op", Vec3Json(0.0, 0.0, 1.0)), pool,
      nullptr, nullptr, cancelled);
  pool.Produce(partingLine);
  nlohmann::json allOperations = nlohmann::json::array();
  allOperations.push_back(
      MoldPartingLineOperation("pl-op", "pl-body", "target-op", Vec3Json(0.0, 0.0, 1.0)));

  bool threw = false;
  try {
    aeth::EvaluateMoldPartingSurface(
        {{"id", "ps-op"},
         {"type", "mold_parting_surface"},
         {"outputBodyId", "ps-body"},
         {"parameters", {{"partingLineOperationId", "pl-op"}, {"extensionDistanceMm", 0.0}}}},
        allOperations, pool, nullptr, nullptr, cancelled);
  } catch (const std::invalid_argument&) {
    threw = true;
  }
  check(threw, "mold_parting_surface refuses a non-positive extensionDistanceMm");
}

// =============================================================================
// 6. mold_tooling_split.
// =============================================================================

struct ToolingSplitPipeline final {
  BodyPool pool;
  nlohmann::json allOperations = nlohmann::json::array();
  std::string targetOp = "target-op";
  std::string partingLineOp = "pl-op";
  std::string partingSurfaceOp = "ps-op";
};

// ZERO lateral margin is deliberate here, not a placeholder: see
// MakeSquareBipyramid's own doc comment for why the parting surface only
// reaches the tooling block's own corners (and can therefore genuinely
// split the whole block) when the block's lateral footprint exactly
// matches the bipyramid's own equator.
ToolingSplitPipeline BuildBipyramidPipeline(std::atomic_bool& cancelled,
                                            const double halfWidth = 6.0,
                                            const double halfHeight = 8.0,
                                            const double extensionMm = 6.0) {
  ToolingSplitPipeline pipeline;
  const TopoDS_Shape bipyramid = MakeSquareBipyramid(halfWidth, halfHeight);
  pipeline.pool.Produce(MakeFixtureBody(pipeline.targetOp, "target-body", bipyramid));

  const nlohmann::json partingLineJson = MoldPartingLineOperation(
      pipeline.partingLineOp, "pl-body", pipeline.targetOp, Vec3Json(0.0, 0.0, 1.0));
  const EvaluatedBody partingLine =
      aeth::EvaluateMoldPartingLine(partingLineJson, pipeline.pool, nullptr, nullptr, cancelled);
  pipeline.pool.Produce(partingLine);
  pipeline.allOperations.push_back(partingLineJson);

  const nlohmann::json partingSurfaceJson = {
      {"id", pipeline.partingSurfaceOp},
      {"type", "mold_parting_surface"},
      {"outputBodyId", "ps-body"},
      {"parameters",
       {{"partingLineOperationId", pipeline.partingLineOp}, {"extensionDistanceMm", extensionMm}}}};
  const EvaluatedBody partingSurface = aeth::EvaluateMoldPartingSurface(
      partingSurfaceJson, pipeline.allOperations, pipeline.pool, nullptr, nullptr, cancelled);
  pipeline.pool.Produce(partingSurface);
  pipeline.allOperations.push_back(partingSurfaceJson);

  return pipeline;
}

nlohmann::json ToolingSplitOperation(const std::string& id, const std::vector<std::string>& bodyIds,
                                     const std::string& targetId,
                                     const std::string& partingSurfaceId,
                                     const std::optional<std::string>& shutoffId,
                                     const double marginX, const double marginY,
                                     const double marginZ,
                                     const std::vector<std::string>& extraIds = {}) {
  nlohmann::json parameters = {
      {"targetOperationId", targetId},
      {"partingSurfaceOperationId", partingSurfaceId},
      {"block", {{"marginXMm", marginX}, {"marginYMm", marginY}, {"marginZMm", marginZ}}}};
  if (shutoffId.has_value())
    parameters["shutoffSurfaceOperationId"] = *shutoffId;
  if (!extraIds.empty())
    parameters["extraSplitSurfaceOperationIds"] = extraIds;
  return {{"id", id},
          {"type", "mold_tooling_split"},
          {"outputBodyId", bodyIds.front()},
          {"outputBodyIds", bodyIds},
          {"parameters", parameters}};
}

void ToolingSplitCoreAndCavity() {
  std::printf("\n[mold_tooling_split] bipyramid: exactly core + cavity, volumes correct\n");
  std::atomic_bool cancelled{false};
  ToolingSplitPipeline pipeline = BuildBipyramidPipeline(cancelled);

  // ZERO lateral margin: see MakeSquareBipyramid's/BuildBipyramidPipeline's
  // own doc comments for why this is required, not incidental, for the
  // swept parting surface to actually reach the block's own corners.
  const nlohmann::json operation =
      ToolingSplitOperation("ts-op", {"core-body", "cavity-body"}, pipeline.targetOp,
                            pipeline.partingSurfaceOp, std::nullopt, 0.0, 0.0, 4.0);
  const std::vector<EvaluatedBody> born = aeth::EvaluateMoldToolingSplit(
      operation, pipeline.allOperations, pipeline.pool, nullptr, nullptr, cancelled);
  check(born.size() == 2, "mold_tooling_split on the bipyramid yields exactly 2 bodies");
  if (born.size() != 2)
    return;
  check(born[0].bodyId == "core-body", "born[0] carries the core's own bodyId");
  check(born[1].bodyId == "cavity-body", "born[1] carries the cavity's own bodyId");
  check(born[0].outputIndex == 0 && born[1].outputIndex == 1, "outputIndex assigned 0/1 in order");

  // Independent check: block = bipyramid's own bbox (halfWidth 6, halfHeight
  // 8 -> [-6,6]x[-6,6]x[-8,8]) expanded by ZERO lateral margin and 4mm in Z
  // -> [-6,6]x[-6,6]x[-12,12], volume = 12*12*24 = 3456. The bipyramid's own
  // volume = 2 * (1/3 * baseArea * halfHeight) = 2/3 * (12*12) * 8 = 768
  // (two square pyramids, base 12x12, height 8 each, glued base-to-base).
  // Core+cavity together = block volume minus the bipyramid's own volume
  // (the tooling block with the part's cavity removed).
  const double blockVolume = 12.0 * 12.0 * 24.0;
  const double bipyramidVolume = 2.0 * (1.0 / 3.0) * (12.0 * 12.0) * 8.0;
  const double expectedTotal = blockVolume - bipyramidVolume;
  const double actualTotal = born[0].probes.volume + born[1].probes.volume;
  std::printf("  INFO core=%.4f cavity=%.4f total=%.4f expected=%.4f (block=%.4f bipyramid=%.4f)\n",
              born[0].probes.volume, born[1].probes.volume, actualTotal, expectedTotal, blockVolume,
              bipyramidVolume);
  checkNear(actualTotal, expectedTotal, 1e-3,
            "core + cavity volumes sum exactly to block volume minus the bipyramid's own volume");

  // Core is the negative-Z (bottom apex) side, cavity is positive-Z: by the
  // block+bipyramid's own symmetry around z=0, core and cavity have EQUAL
  // volume (each exactly half of expectedTotal).
  checkNear(born[0].probes.volume, expectedTotal / 2.0, 1e-3,
            "core's own volume is exactly half the total (the bipyramid is Z-symmetric)");
  checkNear(born[1].probes.volume, expectedTotal / 2.0, 1e-3,
            "cavity's own volume is exactly half the total (the bipyramid is Z-symmetric)");
  check(born[0].probes.centerOfMass[2] < 0.0,
        "core's centroid sits below z=0 (negative/core side)");
  check(born[1].probes.centerOfMass[2] > 0.0, "cavity's centroid sits above z=0 (positive/cavity "
                                              "side)");
}

void ToolingSplitWithOneInsert() {
  std::printf("\n[mold_tooling_split] bipyramid + one extra split surface: core + cavity + 1 "
              "insert\n");
  std::atomic_bool cancelled{false};
  ToolingSplitPipeline pipeline = BuildBipyramidPipeline(cancelled);

  // ZERO lateral margin again (see BuildBipyramidPipeline's own comment).
  // An extra flat splitting plane inside the block's own now-[-6,6] lateral
  // range (x=3, spanning y generously), carving a slab off the CAVITY side
  // (x in [3,6]) as a separate "insert".
  //
  // Z EXTENT MUST BE BOUNDED, not the +/-50 u/v span used elsewhere in this
  // file for planes that are meant to cross the WHOLE block: an unbounded
  // plane here spans both the core (z<0) and cavity (z>0) halves at once,
  // so the splitter carves BOTH of them and yields 4 solids instead of the
  // intended 3 (core, cavity, one insert carved from just the cavity) --
  // measured directly (see this test's own history). Building the tool as
  // an explicit 4-point rectangle pins its Z range to [0, 20]: it starts
  // exactly at the core/cavity boundary (z=0, the bipyramid's own equator
  // -- this is a flush, same-domain coincidence OCCT's boolean framework is
  // built to handle cleanly, not a stray overlap) and reaches well past the
  // block's own top face (z=12 with marginZMm=4) so it fully severs the
  // cavity's solid material into two disjoint pieces with no unsplit
  // Z-band left for the two pieces to stay connected through.
  BRepBuilderAPI_MakePolygon extraToolPolygon;
  extraToolPolygon.Add(gp_Pnt(3.0, -50.0, 0.0));
  extraToolPolygon.Add(gp_Pnt(3.0, 50.0, 0.0));
  extraToolPolygon.Add(gp_Pnt(3.0, 50.0, 20.0));
  extraToolPolygon.Add(gp_Pnt(3.0, -50.0, 20.0));
  extraToolPolygon.Close();
  check(extraToolPolygon.IsDone(), "extra split tool's bounded polygon closed");
  const TopoDS_Shape extraTool =
      BRepBuilderAPI_MakeFace(gp_Pln(gp_Pnt(3.0, 0.0, 0.0), gp_Dir(1, 0, 0)),
                              extraToolPolygon.Wire(), true)
          .Face();
  pipeline.pool.Produce(MakeFixtureBody("extra-op", "extra-body", extraTool));

  const nlohmann::json operation = ToolingSplitOperation(
      "ts-op", {"core-body", "cavity-body", "insert-1-body"}, pipeline.targetOp,
      pipeline.partingSurfaceOp, std::nullopt, 0.0, 0.0, 4.0, {"extra-op"});
  const std::vector<EvaluatedBody> born = aeth::EvaluateMoldToolingSplit(
      operation, pipeline.allOperations, pipeline.pool, nullptr, nullptr, cancelled);
  check(born.size() == 3, "mold_tooling_split with 1 extra split surface yields exactly 3 bodies");
  if (born.size() != 3)
    return;
  check(born[2].bodyId == "insert-1-body", "born[2] carries the insert's own bodyId");
  check(born[2].outputIndex == 2, "insert's outputIndex is 2");
  // The insert is the slab beyond x=3 -> its own centroid.x must exceed 3
  // (it is entirely on the +X side of the cutting plane).
  std::printf("  INFO insert centroid.x = %.4f (expected > 3)\n", born[2].probes.centerOfMass[0]);
  check(born[2].probes.centerOfMass[0] > 3.0, "the insert's own centroid sits beyond the extra "
                                              "tool's own cutting plane (x>3)");
}

void ToolingSplitWrongSolidCountRefusal() {
  std::printf("\n[mold_tooling_split] an extra tool that touches nothing: "
              "E_TOOLING_SPLIT_WRONG_SOLID_COUNT\n");
  std::atomic_bool cancelled{false};
  ToolingSplitPipeline pipeline = BuildBipyramidPipeline(cancelled);

  // A flat plane FAR away from the block (x=1000) -- never intersects
  // anything the splitter actually touches, so the result stays at 2
  // solids even though 3 (2 + 1 extra) were expected.
  const TopoDS_Shape farTool =
      BRepBuilderAPI_MakeFace(gp_Pln(gp_Pnt(1000.0, 0.0, 0.0), gp_Dir(1, 0, 0)), -50.0, 50.0, -50.0,
                              50.0)
          .Face();
  pipeline.pool.Produce(MakeFixtureBody("far-op", "far-body", farTool));

  const nlohmann::json operation = ToolingSplitOperation(
      "ts-op", {"core-body", "cavity-body", "insert-1-body"}, pipeline.targetOp,
      pipeline.partingSurfaceOp, std::nullopt, 0.0, 0.0, 4.0, {"far-op"});
  bool refused = false;
  std::string code;
  try {
    aeth::EvaluateMoldToolingSplit(operation, pipeline.allOperations, pipeline.pool, nullptr,
                                   nullptr, cancelled);
  } catch (const aeth::OperationFailure& error) {
    refused = true;
    code = error.Details().value("toolingCode", "");
  }
  check(refused, "mold_tooling_split refuses when the splitter yields the wrong solid count");
  check(code == "E_TOOLING_SPLIT_WRONG_SOLID_COUNT",
        "refusal code is E_TOOLING_SPLIT_WRONG_SOLID_COUNT");
}

void ToolingSplitCapToolNotClosedRefusal() {
  std::printf("\n[mold_tooling_split] open target, no shut-off: "
              "E_TOOLING_SPLIT_CAP_TOOL_NOT_CLOSED\n");
  std::atomic_bool cancelled{false};
  ToolingSplitPipeline pipeline = BuildBipyramidPipeline(cancelled);

  // Swap in a deliberately OPEN target (the hand-built open box) for the
  // tooling_split call specifically -- isolates the cap-tool-closure check
  // from the rest of the (valid) pipeline built above.
  const OpenBoxWithHoleFixture openFixture = MakeOpenBoxWithHole(10.0, 10.0, 6.0, 2.0);
  pipeline.pool.Produce(MakeFixtureBody("open-target-op", "open-target-body", openFixture.shell));

  const nlohmann::json operation =
      ToolingSplitOperation("ts-op", {"core-body", "cavity-body"}, "open-target-op",
                            pipeline.partingSurfaceOp, std::nullopt, 4.0, 4.0, 4.0);
  bool refused = false;
  std::string code;
  try {
    aeth::EvaluateMoldToolingSplit(operation, pipeline.allOperations, pipeline.pool, nullptr,
                                   nullptr, cancelled);
  } catch (const aeth::OperationFailure& error) {
    refused = true;
    code = error.Details().value("toolingCode", "");
  }
  check(refused, "mold_tooling_split refuses an open target with no shut-off referenced");
  check(code == "E_TOOLING_SPLIT_CAP_TOOL_NOT_CLOSED",
        "refusal code is E_TOOLING_SPLIT_CAP_TOOL_NOT_CLOSED");
}

void ToolingSplitFullDispatchWiring() {
  std::printf("\n[mold_tooling_split] full ExecuteOperation dispatch wiring (geometry.cpp)\n");
  // Proves the geometry.cpp dispatch chain itself (not just the standalone
  // executor) for the common, no-holes bicone case, exactly the
  // "through full dispatch" coverage surfacing_test.cpp's own refusal tests
  // apply for their own boolean-family operations.
  std::atomic_bool cancelled{false};
  // Full dispatch with a real NamingRegistry engaged: every operation id
  // must be UUID-shaped (element_names.cpp's own OperationIdPrefix
  // requirement -- create_box's own HarvestBoxBirth enforces it before
  // mold_tooling_split even starts; see PartingLineNoDraftVariationRefusal's
  // own comment for the empirical discovery).
  nlohmann::json program = nlohmann::json::array();
  program.push_back(
      BoxOperation("00000000-0000-0000-0000-000000000011", "dummy-box-body", 1.0, 1.0, 1.0));
  // A bicone is not producible via JSON primitives; this test therefore
  // proves dispatch wiring using a program that only reaches mold_parting_line
  // /mold_parting_surface/mold_tooling_split's OWN dispatch branches are
  // reachable and type-check against the real ExecuteOperation switch --
  // the refusal-path tests above already prove full dispatch end-to-end for
  // mold_parting_line itself. Here: confirm an UNSUPPORTED/garbage
  // mold_tooling_split program still routes through the mold_tooling_split
  // branch (a missing outputBodyIds throws std::invalid_argument, mapped to
  // INVALID_REQUEST by ExecuteOperation's own catch chain) rather than
  // falling through to "unsupported operation" -- proving the dispatch
  // branch is truly wired, not merely present in source.
  program.push_back({{"id", "00000000-0000-0000-0000-000000000012"},
                     {"type", "mold_tooling_split"},
                     {"outputBodyId", "core-body"},
                     {"parameters",
                      {{"targetOperationId", "00000000-0000-0000-0000-000000000011"},
                       {"partingSurfaceOperationId", "00000000-0000-0000-0000-000000000099"},
                       {"block", {{"marginXMm", 1.0}, {"marginYMm", 1.0}, {"marginZMm", 1.0}}}}}});
  // outputBodyIds deliberately omitted -- operation.at("outputBodyIds")
  // throws nlohmann::json::out_of_range, which ExecuteOperation's own catch
  // chain maps to INVALID_REQUEST (not UNSUPPORTED_OPERATION) -- proving
  // this program reached EvaluateMoldToolingSplit's own parsing rather than
  // falling through the dispatch chain's final `unsupported operation` arm.
  aeth::NamingRegistry registry;
  bool sawInvalidRequest = false;
  try {
    aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
  } catch (const nlohmann::json::exception&) {
    sawInvalidRequest = true;
  } catch (const std::invalid_argument& error) {
    // unsupported operation: <type> is thrown for an UNMATCHED dispatch
    // branch; anything else confirms the mold_tooling_split branch itself
    // ran and threw its OWN validation error instead.
    sawInvalidRequest =
        std::string(error.what()).find("unsupported operation") == std::string::npos;
  }
  check(sawInvalidRequest, "a malformed mold_tooling_split program reaches "
                           "EvaluateMoldToolingSplit's own parsing through full ExecuteOperation "
                           "dispatch (not the dispatch chain's final 'unsupported operation' arm)");
}

} // namespace

int main() {
  // Unbuffer stdout even when redirected to a file/pipe (its default is full
  // block buffering off a TTY), so a crash's own captured log tail reflects
  // the actual last-executed check, not an arbitrary buffer cut.
  //
  // _IONBF, not _IOLBF: the MSVC runtime requires 2 <= size <= INT_MAX and
  // routes an out-of-range size to the invalid-parameter handler, which
  // __fastfails — reported as 0xC0000409 STATUS_STACK_BUFFER_OVERRUN. That
  // made this whole suite abort before its first printf with no output at
  // all. _IONBF ignores the buffer and size arguments entirely, so passing
  // nullptr/0 is valid, and it satisfies the intent above more strictly than
  // line buffering (which MSVC implements as full buffering regardless).
  std::setvbuf(stdout, nullptr, _IONBF, 0);
  try {
    SpikeB_MakePrismOnBareWireProducesUsableShell();
    SpikeA_SplitterWithNonPlanarShellToolYieldsTwoSolids();

    ClassifyDraftFacesBiconeOppositeSigns();
    ClassifyDraftFacesBoxSidesAreNoDraft();
    ClassifyDraftFacesToleranceBand();

    PartingLineBiconeFindsEquator();
    PartingLineNoDraftVariationRefusal();
    PartingLineStraddleFaceRefusal();
    PartingLineMultipleLoopsRefusal();
    PartingLineNamingDoesNotThrow();

    GroupEdgesIntoLoopsEmpty();
    GroupEdgesIntoLoopsSingleSquare();
    GroupEdgesIntoLoopsTwoDisjointSquares();
    GroupEdgesIntoLoopsNonManifoldJunctionRefuses();

    ShutoffSurfaceCapsHoleAndExcludesPartingLine();
    ShutoffSurfaceNoHolesOnOrdinaryClosedPart();

    SewingTwoDisconnectedFacesIntoOneShellIsInvalid();
    PartingSurfaceSweepsBiconeEquator();
    PartingSurfaceKnitsInShutoff();
    PartingSurfaceZeroExtensionRefused();

    ToolingSplitCoreAndCavity();
    ToolingSplitWithOneInsert();
    ToolingSplitWrongSolidCountRefusal();
    ToolingSplitCapToolNotClosedRefusal();
    ToolingSplitFullDispatchWiring();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL MOLD/TOOLING TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d MOLD/TOOLING CHECK(S) FAILED\n", g_failures);
  return 1;
}
