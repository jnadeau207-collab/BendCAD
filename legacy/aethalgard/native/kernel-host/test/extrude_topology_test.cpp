// Topology survival for professional extrude modes — expanded from stub per SUPERIORITY_LAW.
// Exercises start offset, symmetric/twoSided/toFace, faceProfile, taper, thin,
// and boolean Join/Cut/Intersect with fail-closed broken refs. Every new mode is scored
// against adversarial edits, not just happy-path volume.

#include <atomic>
#include <cmath>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepBndLib.hxx>
#include <BRepGProp.hxx>
#include <Bnd_Box.hxx>
#include <GProp_GProps.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS_Shape.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "naming_registry.hpp"

namespace {

int g_failures = 0;

void check(bool cond, const std::string& label) {
  if (cond)
    printf("  ok   %s\n", label.c_str());
  else {
    printf("  FAIL %s\n", label.c_str());
    g_failures++;
  }
}
void checkClose(double actual, double expected, double tol, const std::string& label) {
  bool ok = std::abs(actual - expected) <= tol;
  if (ok)
    printf("  ok   %s (%.6f)\n", label.c_str(), actual);
  else {
    printf("  FAIL %s expected %.6f got %.6f\n", label.c_str(), expected, actual);
    g_failures++;
  }
}

nlohmann::json Metadata() {
  return {{"createdAt", "2026-08-08T00:00:00.000Z"}, {"createdBy", {{"kind", "user"}}}};
}

std::string Eid(char c) { return std::string("aaaaaaaa-0000-4000-8000-00000000000") + c; }

nlohmann::json WorldPlaneRef(const std::string& name) {
  return {{"ast",
           {{"kind", "faces"},
            {"scope", nlohmann::json::array({{{"source", "world"}, {"world", name}}})},
            {"filters", nlohmann::json::array()}}},
          {"arity", "one"},
          {"anchors", nlohmann::json::array()},
          {"onEmpty", "error"}};
}

nlohmann::json AsArray(std::initializer_list<nlohmann::json> items) {
  nlohmann::json array = nlohmann::json::array();
  for (const nlohmann::json& item : items)
    array.push_back(item);
  return array;
}

nlohmann::json FaceRef(const std::string& operationId, const int normalSign) {
  return {
      {"ast",
       {{"kind", "faces"},
        {"scope", AsArray({{{"source", "op"}, {"opId", operationId}}})},
        {"filters",
         AsArray({{{"name", "normal"},
                   {"args",
                    AsArray({{{"arg", "direction"},
                              {"value",
                               {{"form", "axis"}, {"sign", normalSign}, {"axis", "z"}}}}})}}})}}},
      {"arity", "one"},
      {"anchors", nlohmann::json::array()},
      {"onEmpty", "error"}};
}

nlohmann::json TopFaceRef(const std::string& operationId) { return FaceRef(operationId, 1); }
nlohmann::json BottomFaceRef(const std::string& operationId) { return FaceRef(operationId, -1); }

nlohmann::json Line(char id, double x0, double y0, double x1, double y1) {
  return {{"eid", std::string("ent_") + id + std::string(25, '0')},
          {"kind", "line"},
          {"p1", {x0, y0}},
          {"p2", {x1, y1}},
          {"construction", false}};
}

nlohmann::json Sketch(const std::string& id, nlohmann::json plane,
                      std::vector<nlohmann::json> entities) {
  nlohmann::json arr = nlohmann::json::array();
  for (auto& e : entities)
    arr.push_back(e);
  return {{"id", id},
          {"type", "sketch"},
          {"schemaVersion", 1},
          {"name", "Sketch 1"},
          {"parameters",
           {{"plane", plane}, {"entities", arr}, {"constraints", nlohmann::json::array()}}},
          {"metadata", Metadata()}};
}

nlohmann::json Box(const std::string& id, double w, double d, double h) {
  return {{"id", id},
          {"type", "create_box"},
          {"schemaVersion", 1},
          {"name", "Box 1"},
          {"outputBodyId", "b0000000-0000-4000-8000-000000000099"},
          {"parameters",
           {{"width", w},
            {"depth", d},
            {"height", h},
            {"placement",
             {{"origin", {0, 0, 0}}, {"zDirection", {0, 0, 1}}, {"xDirection", {1, 0, 0}}}}}},
          {"metadata", Metadata()}};
}

nlohmann::json ExtrudeV2(const std::string& id, const std::string& profileId, nlohmann::json start,
                         nlohmann::json extent, nlohmann::json extra) {
  nlohmann::json params = {{"profileOperationId", profileId}, {"start", start}, {"extent", extent}};
  for (auto it = extra.begin(); it != extra.end(); ++it)
    params[it.key()] = it.value();
  // ensure direction present for determinism
  if (!params.contains("direction"))
    params["direction"] = "normal";
  return {{"id", id},
          {"type", "extrude"},
          {"schemaVersion", 2},
          {"name", "Extrude 1"},
          {"outputBodyId", "b0000000-0000-4000-8000-000000000002"},
          {"parameters", params},
          {"metadata", Metadata()}};
}

nlohmann::json StartOffset(double mm) { return {{"mode", "offset"}, {"offsetMm", mm}}; }
nlohmann::json StartPlane() { return {{"mode", "profilePlane"}}; }
nlohmann::json ExtentDistance(double mm) { return {{"mode", "distance"}, {"distanceMm", mm}}; }
nlohmann::json ExtentSymmetric(double mm) { return {{"mode", "symmetric"}, {"distanceMm", mm}}; }
nlohmann::json ExtentTwoSided(double fwd, double bwd) {
  return {{"mode", "twoSided"}, {"distanceForwardMm", fwd}, {"distanceBackwardMm", bwd}};
}

struct Run {
  std::vector<aeth::EvaluatedBody> bodies;
  std::string kind;
  std::string msg;
};

Run Evaluate(const nlohmann::json& prog) {
  std::atomic_bool cancelled{false};
  aeth::NamingRegistry reg;
  Run r;
  try {
    r.bodies = aeth::EvaluateOperations(prog, cancelled, nullptr, &reg);
    r.kind = "none";
  } catch (const aeth::OperationFailure& e) {
    r.kind = "operation";
    r.msg = e.what();
  } catch (const aeth::ReferenceMissing& e) {
    r.kind = "reference-missing";
    r.msg = e.what();
  } catch (const std::exception& e) {
    r.kind = "other";
    r.msg = e.what();
  }
  return r;
}
double Volume(const aeth::EvaluatedBody& b) {
  GProp_GProps p;
  BRepGProp::VolumeProperties(b.shape, p);
  return p.Mass();
}
Bnd_Box Bounds(const aeth::EvaluatedBody& b) {
  Bnd_Box box;
  BRepBndLib::Add(b.shape, box);
  return box;
}

std::vector<nlohmann::json> RectEntities() {
  return {Line('A', 0, 0, 40, 0), Line('B', 40, 0, 40, 30), Line('C', 40, 30, 0, 30),
          Line('D', 0, 30, 0, 0)};
}

void TestStartOffset() {
  printf("\n[start offset 5mm]\n");
  auto prog = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartOffset(5), ExtentDistance(10), {})});
  auto run = Evaluate(prog);
  check(run.kind == "none", "evaluates: " + run.msg);
  if (run.kind != "none" || run.bodies.empty())
    return;
  Bnd_Box b = Bounds(run.bodies[0]);
  double x0, y0, z0, x1, y1, z1;
  b.Get(x0, y0, z0, x1, y1, z1);
  checkClose(z0, 5.0, 1e-6, "zMin == start offset");
  checkClose(z1, 15.0, 1e-6, "zMax == offset+distance");
  checkClose(Volume(run.bodies[0]), 40 * 30 * 10, 1e-6, "volume unchanged by offset");
}

void TestSymmetric() {
  printf("\n[symmetric 10]\n");
  auto prog =
      nlohmann::json::array({Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
                             ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentSymmetric(10), {})});
  auto run = Evaluate(prog);
  check(run.kind == "none", "symmetric evaluates");
  if (run.kind != "none" || run.bodies.empty())
    return;
  Bnd_Box b = Bounds(run.bodies[0]);
  double x0, y0, z0, x1, y1, z1;
  b.Get(x0, y0, z0, x1, y1, z1);
  checkClose(z0, -10, 1e-6, "symmetric zMin");
  checkClose(z1, 10, 1e-6, "symmetric zMax");
  checkClose(Volume(run.bodies[0]), 40 * 30 * 20, 1e-6, "symmetric volume 20h");
}

void TestTwoSided() {
  printf("\n[twoSided 5+15]\n");
  auto prog = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentTwoSided(5, 15), {})});
  auto run = Evaluate(prog);
  check(run.kind == "none", "twoSided evaluates");
  if (run.kind != "none" || run.bodies.empty())
    return;
  checkClose(Volume(run.bodies[0]), 40 * 30 * 20, 1e-6, "twoSided volume 5+15=20");
  Bnd_Box b = Bounds(run.bodies[0]);
  double x0, y0, z0, x1, y1, z1;
  b.Get(x0, y0, z0, x1, y1, z1);
  checkClose(z0, -15, 1e-6, "twoSided bwd");
  checkClose(z1, 5, 1e-6, "twoSided fwd");
}

void TestTaper() {
  printf("\n[taper 10deg — real draft via BRepOffsetAPI_DraftAngle]\n");
  nlohmann::json extra = {{"taperAngleDeg", 10}};
  auto prog = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), extra)});
  auto run = Evaluate(prog);
  check(run.kind == "none", "taper evaluates (real draft)");
  check(run.bodies.size() == 1, "taper produces exactly one body");
  if (run.kind != "none" || run.bodies.size() != 1)
    return;
  // Sign convention verified against OCCT's own BRepOffsetAPI_DraftAngle.hxx:
  // "Direction indicates the side of NeutralPlane from which matter is
  // removed if Angle is positive or added if Angle is negative." Direction
  // here is the extrusion direction (points at the top, away from the
  // neutral/profile plane), and geometry.cpp negates the authored taper
  // before passing it to Add(), so positive authored taper -> negative OCCT
  // angle -> matter ADDED on the top side -> top strictly larger than the
  // straight prism. This must stay a directional check: a same-magnitude
  // check that accepts either sign would not catch the sign flipping back.
  double volPrism = 40 * 30 * 10;
  double volTaper = Volume(run.bodies[0]);
  check(volTaper > volPrism * 1.02,
        "positive taper adds material vs prism (top scaled outward, not shrunk)");
  // taper beyond 89 must fail closed
  extra["taperAngleDeg"] = 90;
  auto prog2 = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), extra)});
  auto run2 = Evaluate(prog2);
  check(run2.kind != "none", "taper 90 fails closed");

  extra["taperAngleDeg"] = 10;
  auto symmetric = Evaluate(nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentSymmetric(5), extra)}));
  check(symmetric.kind == "none", "symmetric taper evaluates: " + symmetric.msg);
  check(symmetric.bodies.size() == 1, "symmetric taper produces exactly one body");
  if (symmetric.kind == "none" && symmetric.bodies.size() == 1) {
    // Each leg is drafted independently with the same authored angle and its
    // own far-end neutral-plane direction (see makeTapered call sites), so
    // both legs add material at their own far end — total volume must be
    // strictly larger than the untapered two-sided baseline, same directional
    // reasoning as the single-sided case above.
    double volSym = Volume(symmetric.bodies.back());
    check(volSym > 40 * 30 * 10 * 1.02,
          "symmetric taper adds material on both legs vs untapered baseline");
  }

  const std::string boxId = Eid('9');
  auto toFaceTaper = Evaluate(nlohmann::json::array(
      {Box(boxId, 40, 30, 20), Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), {{"mode", "toFace"}},
                 {{"toFace", TopFaceRef(boxId)}, {"taperAngleDeg", 10}})}));
  check(toFaceTaper.kind == "operation", "unsupported toFace taper fails closed");
}

void TestThin() {
  printf("\n[thin midPlane 2 — fail-closed on hollow failure]\n");
  nlohmann::json extra = {{"thin", {{"thicknessMm", 2}, {"position", "midPlane"}}}};
  auto prog = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), extra)});
  auto run = Evaluate(prog);
  check(run.kind == "none", "thin midPlane evaluates: " + run.msg);
  check(run.bodies.size() == 1, "thin midPlane produces exactly one body");
  if (run.kind == "none" && run.bodies.size() == 1) {
    double volThin = Volume(run.bodies[0]);
    double volSolid = 40 * 30 * 10;
    check(volThin < volSolid * 0.95, "thin hollow reduces volume");
  }
  // oneSide now implemented — must succeed and also reduce volume, like midPlane/twoSide
  extra["thin"] = {{"thicknessMm", 2}, {"position", "oneSide"}};
  auto prog2 = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), extra)});
  auto run2 = Evaluate(prog2);
  check(run2.kind == "none", "thin oneSide evaluates: " + run2.msg);
  check(run2.bodies.size() == 1, "thin oneSide produces exactly one body");
  if (run2.kind == "none" && run2.bodies.size() == 1) {
    double volThin2 = Volume(run2.bodies[0]);
    double volSolid2 = 40 * 30 * 10;
    check(volThin2 < volSolid2 * 0.95, "thin oneSide hollow reduces volume");
    check(volThin2 > 1e-9, "thin oneSide produces non-zero volume");
  }
  // twoSide also
  extra["thin"] = {{"thicknessMm", 2}, {"position", "twoSide"}};
  auto prog3 = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), extra)});
  auto run3 = Evaluate(prog3);
  check(run3.kind == "none", "thin twoSide evaluates: " + run3.msg);
  if (run3.kind == "none" && run3.bodies.size() == 1) {
    check(Volume(run3.bodies[0]) < 40 * 30 * 10 * 0.95, "thin twoSide hollow reduces volume");
  }
}

void TestBoolean() {
  printf("\n[boolean Join/Cut/Intersect — Consume target, no orphan]\n");
  // Build a box target first, then extrude onto it with join
  std::string boxId = Eid('9');
  std::string sketchId = Eid('1');
  std::string extrudeId = Eid('2');
  // Box 40x30x10 at origin, sketch same rectangle extruded 10 overlapping
  auto progJoin = nlohmann::json::array(
      {Box(boxId, 40, 30, 10), Sketch(sketchId, WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(extrudeId, sketchId, StartPlane(), ExtentDistance(10),
                 {{"boolean", {{"mode", "join"}, {"targetOperationId", boxId}}}})});
  auto runJoin = Evaluate(progJoin);
  check(runJoin.kind == "none", "join evaluates: " + runJoin.msg);
  if (runJoin.kind == "none") {
    // after join, pool should have exactly 1 body (target consumed, result is 1)
    // EvaluateOperations returns bodies in order: box consumed, extrude-join is single remaining?
    // In current dispatch, EvaluateOperations returns visible bodies after evaluation.
    // We check that we did not leak orphan target: visible bodies should be 1, not 2.
    check(runJoin.bodies.size() == 1, "join consumed target — 1 visible body, no orphan");
    if (runJoin.bodies.size() == 1)
      checkClose(Volume(runJoin.bodies.front()), 21000.0, 1e-6,
                 "join volume = target + tool - overlap");
  }
  // Cut: extrude 10 from same box should remove material — we test that cut evaluates and reduces
  // volume
  std::string extrudeCutId = Eid('3');
  auto progCut = nlohmann::json::array(
      {Box(boxId, 40, 30, 20), Sketch(sketchId, WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(extrudeCutId, sketchId, StartPlane(), ExtentDistance(10),
                 {{"boolean", {{"mode", "cut"}, {"targetOperationId", boxId}}}})});
  auto runCut = Evaluate(progCut);
  check(runCut.kind == "none", "cut evaluates: " + runCut.msg);
  if (runCut.kind == "none") {
    check(runCut.bodies.size() == 1, "cut consumed target — 1 visible body, no orphan");
    if (runCut.bodies.size() == 1)
      checkClose(Volume(runCut.bodies.front()), 21000.0, 1e-6, "cut volume = target - overlap");
  }
  // Intersect similarly must consume
  std::string extrudeIntId = Eid('4');
  auto progInt = nlohmann::json::array(
      {Box(boxId, 40, 30, 10), Sketch(sketchId, WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(extrudeIntId, sketchId, StartPlane(), ExtentDistance(10),
                 {{"boolean", {{"mode", "intersect"}, {"targetOperationId", boxId}}}})});
  auto runInt = Evaluate(progInt);
  check(runInt.kind == "none", "intersect evaluates: " + runInt.msg);
  if (runInt.kind == "none") {
    check(runInt.bodies.size() == 1, "intersect consumed target — 1 visible body, no orphan");
    if (runInt.bodies.size() == 1)
      checkClose(Volume(runInt.bodies.front()), 3000.0, 1e-6,
                 "intersect volume = target/tool overlap");
  }
  // Missing target must fail closed, not first-overlapping
  auto progBad =
      nlohmann::json::array({Sketch(sketchId, WorldPlaneRef("xy"), RectEntities()),
                             ExtrudeV2(extrudeId, sketchId, StartPlane(), ExtentDistance(10),
                                       {{"boolean", {{"mode", "join"}}}})});
  auto runBad = Evaluate(progBad);
  check(runBad.kind != "none", "boolean without target fails closed");
}

void TestToFace() {
  printf("\n[toFace — resolved planar target and fail-closed missing ref]\n");
  const std::string boxId = Eid('9');
  const std::string extrudeId = Eid('2');
  nlohmann::json toFace = ExtrudeV2(extrudeId, Eid('1'), StartPlane(), {{"mode", "toFace"}},
                                    {{"toFace", TopFaceRef(boxId)}});
  auto valid = Evaluate(nlohmann::json::array(
      {Box(boxId, 40, 30, 20), Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()), toFace}));
  check(valid.kind == "none", "toFace evaluates: " + valid.msg);
  check(valid.bodies.size() == 2, "toFace preserves target and produces one Extrude body");
  if (valid.kind == "none" && valid.bodies.size() == 2) {
    const aeth::EvaluatedBody& extrusion = valid.bodies.back();
    check(extrusion.operationId == extrudeId, "toFace result belongs to the Extrude operation");
    Bnd_Box bounds = Bounds(extrusion);
    double x0, y0, z0, x1, y1, z1;
    bounds.Get(x0, y0, z0, x1, y1, z1);
    checkClose(z0, 0.0, 1e-6, "toFace starts on profile plane");
    checkClose(z1, 20.0, 1e-6, "toFace stops on selected target plane");
    checkClose(Volume(extrusion), 40 * 30 * 20, 1e-6, "toFace uses resolved distance");
  }

  // Missing reference must refuse, never substitute a model bound or first face.
  auto prog = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), {{"mode", "toFace"}}, {})});
  auto run = Evaluate(prog);
  check(run.kind != "none", "toFace without toFace ref fails closed");
}

void TestFaceProfile() {
  printf("\n[faceProfile — selected planar face and fail-closed missing source]\n");
  const std::string boxId = Eid('9');
  const std::string extrudeId = Eid('2');
  nlohmann::json faceExtrude = ExtrudeV2(extrudeId, Eid('1'), StartPlane(), ExtentDistance(7), {});
  faceExtrude["parameters"].erase("profileOperationId");
  faceExtrude["parameters"]["faceProfile"] = TopFaceRef(boxId);
  auto valid = Evaluate(nlohmann::json::array({Box(boxId, 40, 30, 10), faceExtrude}));
  check(valid.kind == "none", "faceProfile evaluates: " + valid.msg);
  check(valid.bodies.size() == 2, "faceProfile preserves source and produces one Extrude body");
  if (valid.kind == "none" && valid.bodies.size() == 2) {
    const aeth::EvaluatedBody& extrusion = valid.bodies.back();
    check(extrusion.operationId == extrudeId,
          "faceProfile result belongs to the Extrude operation");
    const double zExtent = extrusion.probes.bounds[5] - extrusion.probes.bounds[2];
    checkClose(zExtent, 7.0, 1e-6, "faceProfile extrudes the authored distance");
    checkClose(Volume(extrusion), 40 * 30 * 7, 1e-6, "faceProfile uses selected face area");
  }

  const std::string bottomExtrudeId = Eid('3');
  nlohmann::json bottomExtrude =
      ExtrudeV2(bottomExtrudeId, Eid('1'), StartPlane(), ExtentDistance(7), {});
  bottomExtrude["parameters"].erase("profileOperationId");
  bottomExtrude["parameters"]["faceProfile"] = BottomFaceRef(boxId);
  auto bottom = Evaluate(nlohmann::json::array({Box(boxId, 40, 30, 10), bottomExtrude}));
  check(bottom.kind == "none", "bottom faceProfile evaluates: " + bottom.msg);
  check(bottom.bodies.size() == 2, "bottom faceProfile produces one Extrude body");
  if (bottom.kind == "none" && bottom.bodies.size() == 2) {
    const aeth::EvaluatedBody& extrusion = bottom.bodies.back();
    check(extrusion.operationId == bottomExtrudeId,
          "bottom faceProfile result belongs to the Extrude operation");
    checkClose(extrusion.probes.bounds[2], -7.0, 1e-6,
               "normal follows selected bottom-face outward orientation");
    checkClose(extrusion.probes.bounds[5], 0.0, 1e-6,
               "bottom faceProfile ends on selected face plane");
  }

  // Neither source form may fall back to whichever face happens to be visible.
  auto prog = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       nlohmann::json{{"id", Eid('2')},
                      {"type", "extrude"},
                      {"schemaVersion", 2},
                      {"name", "Extrude 1"},
                      {"outputBodyId", "b0000000-0000-4000-8000-000000000002"},
                      {"parameters", {{"start", StartPlane()}, {"extent", ExtentDistance(10)}}},
                      {"metadata", Metadata()}}});
  auto run = Evaluate(prog);
  check(run.kind != "none", "extrude without profile/faceProfile fails closed");
}

void TestUpstreamSketchEdit() {
  printf("\n[upstream sketch edit — region preserved, volume tracks]\n");
  auto prog1 =
      nlohmann::json::array({Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
                             ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), {})});
  auto run1 = Evaluate(prog1);
  check(run1.kind == "none", "initial extrude evaluates");
  if (run1.kind != "none" || run1.bodies.empty())
    return;
  double vol1 = Volume(run1.bodies[0]);
  checkClose(vol1, 40 * 30 * 10, 1e-6, "initial volume 40x30x10");

  // Second evaluation with modified sketch: width 20 instead of 40 (simulate upstream edit)
  // Build new sketch with smaller rectangle but same extrude distance
  auto smallRect = std::vector<nlohmann::json>{Line('A', 0, 0, 20, 0), Line('B', 20, 0, 20, 30),
                                               Line('C', 20, 30, 0, 30), Line('D', 0, 30, 0, 0)};
  auto prog2 =
      nlohmann::json::array({Sketch(Eid('1'), WorldPlaneRef("xy"), smallRect),
                             ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), {})});
  auto run2 = Evaluate(prog2);
  check(run2.kind == "none", "re-evaluated extrude after upstream sketch shrink");
  if (run2.kind != "none" || run2.bodies.empty())
    return;
  double vol2 = Volume(run2.bodies[0]);
  checkClose(vol2, 20 * 30 * 10, 1e-6, "upstream edit preserves region — volume 20x30x10");
  check(vol2 < vol1 * 0.6, "volume tracks upstream edit (halved width)");
}

void TestOpenProfileThin() {
  printf("\n[thin along an open path — wall, not a hollowed solid]\n");
  // An open L: (0,0)->(40,0)->(40,30). Total path length 70, no enclosed area,
  // so this sketch produces no region at all and only Thin Extrude can use it.
  auto openL = std::vector<nlohmann::json>{Line('A', 0, 0, 40, 0), Line('B', 40, 0, 40, 30)};
  const double pathLength = 40.0 + 30.0;
  const double thickness = 2.0;
  const double height = 10.0;

  auto wall = [&](const std::string& position) {
    return nlohmann::json::array(
        {Sketch(Eid('1'), WorldPlaneRef("xy"), openL),
         ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(height),
                   {{"thin", {{"thicknessMm", thickness}, {"position", position}}}})});
  };

  // The wall is built as a planar band (the path offset in-plane to its two
  // wall edges, capped flat at the ends) and then prismed, so height comes
  // only from the extent and width only from the thickness.
  //
  // The height assertion below is the one that matters most: an earlier
  // attempt thickened the swept shell in 3D instead, which also grew the free
  // top and bottom edges and made this same 10mm wall measure 15.66mm. That
  // version passed a volume-only check. Keep both.
  for (const std::string& position :
       {std::string("oneSide"), std::string("twoSide"), std::string("midPlane")}) {
    auto run = Evaluate(wall(position));
    check(run.kind == "none", "open-path thin " + position + " evaluates: " + run.msg);
    if (run.kind != "none" || run.bodies.empty())
      continue;
    Bnd_Box b = Bounds(run.bodies.front());
    double x0, y0, z0, x1, y1, z1;
    b.Get(x0, y0, z0, x1, y1, z1);
    checkClose(z1 - z0, height, 1e-6,
               "open-path thin " + position + " wall is exactly the authored height");
    const double volume = Volume(run.bodies.front());
    // Path length x thickness x height, computed from the authored sketch.
    // The right-angle corner adds or removes at most one thickness-squared
    // prism depending on which side the wall falls, so allow exactly that.
    const double nominal = pathLength * thickness * height;
    const double cornerAllowance = thickness * thickness * height;
    check(std::abs(volume - nominal) <= cornerAllowance + 1e-6,
          "open-path thin " + position + " volume == path length x thickness x height");
    check(volume > 1e-9, "open-path thin " + position + " produces real volume");
  }

  // Wall location must be real geometry, not a label on the same solid: a
  // centered wall straddles the path, so its footprint differs from the
  // one-sided wall's.
  auto runOne = Evaluate(wall("oneSide"));
  auto runMid = Evaluate(wall("midPlane"));
  if (runOne.kind == "none" && runMid.kind == "none" && !runOne.bodies.empty() &&
      !runMid.bodies.empty()) {
    Bnd_Box bOne = Bounds(runOne.bodies.front());
    Bnd_Box bMid = Bounds(runMid.bodies.front());
    double a0, a1, a2, a3, a4, a5;
    double m0, m1, m2, m3, m4, m5;
    bOne.Get(a0, a1, a2, a3, a4, a5);
    bMid.Get(m0, m1, m2, m3, m4, m5);
    check(std::abs(a0 - m0) > 1e-9 || std::abs(a1 - m1) > 1e-9 || std::abs(a3 - m3) > 1e-9 ||
              std::abs(a4 - m4) > 1e-9,
          "center wall sits differently than the one-sided wall (real location, not a label)");
  }

  // An open path with no thickness has no wall to build and no area to sweep.
  auto runNoThin = Evaluate(nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), openL),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(height), {})}));
  check(runNoThin.kind != "none",
        "open path without thin fails closed instead of emitting a zero-volume shell");
}

void TestSketchOnModelFace() {
  printf("\n[sketch on a model face — extrudes from the face, tracks it]\n");
  const std::string boxId = Eid('9');
  // The sketch's own plane is a durable reference to the box's top face,
  // rather than a world plane. Extruding it must start on that face.
  auto onTopFace = [&](double boxHeight) {
    return nlohmann::json::array(
        {Box(boxId, 40, 30, boxHeight), Sketch(Eid('1'), TopFaceRef(boxId), RectEntities()),
         ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), {})});
  };

  auto run = Evaluate(onTopFace(20));
  check(run.kind == "none", "sketch on model face evaluates: " + run.msg);
  if (run.kind == "none" && run.bodies.size() >= 2) {
    const aeth::EvaluatedBody& extrusion = run.bodies.back();
    // Area is orientation-independent, so volume is the robust check that the
    // sketch geometry survived onto the face's plane intact.
    checkClose(Volume(extrusion), 40 * 30 * 10, 1e-6,
               "sketch-on-face extrude keeps the authored profile area");
    Bnd_Box b = Bounds(extrusion);
    double x0, y0, z0, x1, y1, z1;
    b.Get(x0, y0, z0, x1, y1, z1);
    checkClose(z0, 20.0, 1e-6, "extrusion begins on the model face, not the world plane");
    checkClose(z1, 30.0, 1e-6, "extrusion runs the authored distance off that face");
  }

  // Upstream move: a taller box carries the sketch plane, and the extrusion
  // with it. This is the associativity that makes sketch-on-face worth
  // having rather than a one-time coordinate copy.
  auto runMoved = Evaluate(onTopFace(35));
  check(runMoved.kind == "none", "sketch on model face re-evaluates after the face moves");
  if (runMoved.kind == "none" && runMoved.bodies.size() >= 2) {
    Bnd_Box b = Bounds(runMoved.bodies.back());
    double x0, y0, z0, x1, y1, z1;
    b.Get(x0, y0, z0, x1, y1, z1);
    checkClose(z0, 35.0, 1e-6, "sketch plane follows the moved face (35, not stale 20)");
    checkClose(z1, 45.0, 1e-6, "extrusion follows the moved face");
  }

  // A sketch whose plane reference cannot resolve must refuse rather than
  // silently falling back to a world plane at the origin.
  auto runBroken = Evaluate(
      nlohmann::json::array({Sketch(Eid('1'), TopFaceRef(boxId), RectEntities()),
                             ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), {})}));
  check(runBroken.kind != "none",
        "sketch on a missing model face fails closed, no silent world-plane fallback");
}

void TestThroughAll() {
  printf("\n[throughAll — body-aware extent, not a fixed sentinel]\n");
  const std::string boxId = Eid('9');
  // Cut through a box of height 20. A real through-all must scale with the
  // geometry actually present, so the same cut against a taller box must
  // travel further. Under the old 1e6 sentinel both cases produced an
  // identical prism and this comparison could not distinguish them.
  auto cutThrough = [&](double boxHeight) {
    return nlohmann::json::array(
        {Box(boxId, 40, 30, boxHeight), Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
         ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), nlohmann::json{{"mode", "throughAll"}},
                   {{"boolean", {{"mode", "cut"}, {"targetOperationId", boxId}}}})});
  };

  auto runShort = Evaluate(cutThrough(20));
  check(runShort.kind == "none", "throughAll cut evaluates: " + runShort.msg);
  if (runShort.kind == "none" && !runShort.bodies.empty()) {
    // create_box centers X/Y about the placement origin but grows +Z from it,
    // so Box(40,30,20) spans x -20..20, y -15..15, z 0..20 (volume 24000),
    // while the sketch rectangle spans x 0..40, y 0..30. They overlap over
    // x 0..20 by y 0..15. A cut that truly passes through the FULL height
    // removes 20*15*20 = 6000, leaving exactly 18000. A cut that stopped
    // short would leave more, so this number is what proves "through".
    checkClose(Volume(runShort.bodies.front()), 18000.0, 1e-6,
               "throughAll cut removes the overlap across the target's full height");
  }

  // New-body form: the extrusion must span the visible geometry it passes
  // through, and must grow when that geometry grows.
  auto newBodyThrough = [&](double boxHeight) {
    return nlohmann::json::array(
        {Box(boxId, 40, 30, boxHeight), Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
         ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), nlohmann::json{{"mode", "throughAll"}}, {})});
  };
  auto run20 = Evaluate(newBodyThrough(20));
  auto run50 = Evaluate(newBodyThrough(50));
  check(run20.kind == "none", "throughAll new body evaluates over a 20-tall box");
  check(run50.kind == "none", "throughAll new body evaluates over a 50-tall box");
  if (run20.kind == "none" && run50.kind == "none" && run20.bodies.size() >= 2 &&
      run50.bodies.size() >= 2) {
    Bnd_Box b20 = Bounds(run20.bodies.back());
    Bnd_Box b50 = Bounds(run50.bodies.back());
    double ax0, ay0, az0, ax1, ay1, az1;
    double cx0, cy0, cz0, cx1, cy1, cz1;
    b20.Get(ax0, ay0, az0, ax1, ay1, az1);
    b50.Get(cx0, cy0, cz0, cx1, cy1, cz1);
    check(az1 >= 20.0, "throughAll clears the 20-tall body it passes through");
    check(cz1 >= 50.0, "throughAll clears the 50-tall body it passes through");
    check(cz1 > az1 + 25.0,
          "throughAll extent tracks scene geometry (taller body => longer extrusion)");
    check(az1 < 1000.0, "throughAll is derived from geometry, not the old 1e6 sentinel");
  }

  // Nothing ahead to pass through: refuse rather than invent a length.
  auto runEmpty = Evaluate(nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), nlohmann::json{{"mode", "throughAll"}}, {})}));
  check(runEmpty.kind != "none",
        "throughAll with no visible geometry fails closed instead of guessing an extent");
}

void TestStartObject() {
  printf("\n[start object — durable planar reference, tracks upstream move]\n");
  const std::string boxId = Eid('9');
  // Box height 20 -> its top face sits at z=20. Starting from that face and
  // extruding 10 must span z 20..30. The expected numbers come from the box's
  // authored height, not from anything the extrude itself reports.
  auto prog = nlohmann::json::array(
      {Box(boxId, 40, 30, 20), Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), nlohmann::json{{"mode", "object"}}, ExtentDistance(10),
                 {{"startObject", TopFaceRef(boxId)}})});
  auto run = Evaluate(prog);
  check(run.kind == "none", "start object evaluates: " + run.msg);
  if (run.kind == "none" && run.bodies.size() >= 2) {
    Bnd_Box b = Bounds(run.bodies.back());
    double x0, y0, z0, x1, y1, z1;
    b.Get(x0, y0, z0, x1, y1, z1);
    checkClose(z0, 20.0, 1e-6, "start object begins on the referenced face");
    checkClose(z1, 30.0, 1e-6, "start object end == face + distance");
    checkClose(Volume(run.bodies.back()), 40 * 30 * 10, 1e-6,
               "start object volume is the authored distance, not to-the-face");
  }

  // Upstream move: a taller box puts the same top face at z=35. The start
  // must follow the face rather than staying at the old height.
  auto progMoved = nlohmann::json::array(
      {Box(boxId, 40, 30, 35), Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), nlohmann::json{{"mode", "object"}}, ExtentDistance(10),
                 {{"startObject", TopFaceRef(boxId)}})});
  auto runMoved = Evaluate(progMoved);
  check(runMoved.kind == "none", "start object re-evaluates after upstream face move");
  if (runMoved.kind == "none" && runMoved.bodies.size() >= 2) {
    Bnd_Box b = Bounds(runMoved.bodies.back());
    double x0, y0, z0, x1, y1, z1;
    b.Get(x0, y0, z0, x1, y1, z1);
    checkClose(z0, 35.0, 1e-6, "start tracks the moved face (35, not the stale 20)");
    checkClose(z1, 45.0, 1e-6, "start object end tracks the moved face");
  }

  // Authored extra offset stacks on top of the resolved face position.
  auto progOffset = nlohmann::json::array(
      {Box(boxId, 40, 30, 20), Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), nlohmann::json{{"mode", "object"}, {"offsetMm", 5}},
                 ExtentDistance(10), {{"startObject", TopFaceRef(boxId)}})});
  auto runOffset = Evaluate(progOffset);
  check(runOffset.kind == "none", "start object with extra offset evaluates");
  if (runOffset.kind == "none" && runOffset.bodies.size() >= 2) {
    Bnd_Box b = Bounds(runOffset.bodies.back());
    double x0, y0, z0, x1, y1, z1;
    b.Get(x0, y0, z0, x1, y1, z1);
    checkClose(z0, 25.0, 1e-6, "extra offset stacks on the resolved face (20+5)");
  }

  // Fail closed: object mode without a reference must refuse rather than
  // silently degrading to the profile plane.
  auto progMissing = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), nlohmann::json{{"mode", "object"}}, ExtentDistance(10), {})});
  auto runMissing = Evaluate(progMissing);
  check(runMissing.kind != "none",
        "start object without startObject ref fails closed, no silent profile-plane fallback");
}

void TestSketchRegionIds() {
  printf("\n[sketchRegionIds — durable region subset selection]\n");
  // A sketch with two disjoint rectangles: RectEntities() (A,B,C,D) plus a
  // second, separate rectangle (E,F,G,H) offset in X so the two regions do
  // not touch or nest.
  auto secondRect =
      std::vector<nlohmann::json>{Line('E', 100, 0, 140, 0), Line('F', 140, 0, 140, 30),
                                  Line('G', 140, 30, 100, 30), Line('H', 100, 30, 100, 0)};
  std::vector<nlohmann::json> entities = RectEntities();
  for (auto& e : secondRect)
    entities.push_back(e);
  auto sketch = Sketch(Eid('1'), WorldPlaneRef("xy"), entities);

  // No sketchRegionIds: the whole sketch (both disjoint regions) extrudes,
  // matching the pre-existing multi-region compound behavior.
  auto progBoth = nlohmann::json::array(
      {sketch, ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), {})});
  auto runBoth = Evaluate(progBoth);
  check(runBoth.kind == "none",
        "extrude without sketchRegionIds evaluates (both regions): " + runBoth.msg);
  if (runBoth.kind == "none" && !runBoth.bodies.empty()) {
    checkClose(Volume(runBoth.bodies[0]), 2 * 40 * 30 * 10, 1e-6,
               "no selection extrudes both disjoint regions");
  }

  // Durable key: sorted, deduplicated full entity ids bounding the region,
  // exactly matching geometry.cpp's regionKey construction — not a
  // positional index. Mirrors the Line() helper's own eid format so this
  // stays honest to what the kernel actually computes rather than a
  // hand-picked string the kernel happens to accept.
  auto eidFull = [](char id) { return std::string("ent_") + id + std::string(25, '0'); };
  std::string firstRegionKey =
      "region:" + eidFull('A') + "+" + eidFull('B') + "+" + eidFull('C') + "+" + eidFull('D');

  auto progOne = nlohmann::json::array(
      {sketch, ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10),
                         {{"sketchRegionIds", nlohmann::json::array({firstRegionKey})}})});
  auto runOne = Evaluate(progOne);
  check(runOne.kind == "none", "extrude with sketchRegionIds selects one region: " + runOne.msg);
  if (runOne.kind == "none" && !runOne.bodies.empty()) {
    checkClose(Volume(runOne.bodies[0]), 40 * 30 * 10, 1e-6,
               "selected region volume matches only that region, not both");
    Bnd_Box b = Bounds(runOne.bodies[0]);
    double x0, y0, z0, x1, y1, z1;
    b.Get(x0, y0, z0, x1, y1, z1);
    check(x1 <= 40.0 + 1e-6,
          "selected region bbox stays within the first rectangle, excludes the second");
  }

  // Fail-closed: a region id that does not match any current region (wrong,
  // stale, or invented) must refuse — never silently fall back to the whole
  // sketch or the first region found.
  auto progBad = nlohmann::json::array(
      {sketch, ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10),
                         {{"sketchRegionIds",
                           nlohmann::json::array({std::string("region:does-not-exist")})}})});
  auto runBad = Evaluate(progBad);
  check(runBad.kind != "none",
        "unknown sketchRegionIds value fails closed, does not silently substitute geometry");
}

void TestReEdit() {
  printf("\n[re-edit extent mode without recreate]\n");
  auto progA =
      nlohmann::json::array({Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
                             ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), {})});
  auto runA = Evaluate(progA);
  check(runA.kind == "none", "distance extrude evaluates");
  if (runA.kind == "none" && !runA.bodies.empty())
    checkClose(Volume(runA.bodies[0]), 12000, 1e-6, "distance 10 volume");

  auto progB =
      nlohmann::json::array({Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
                             ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentSymmetric(5), {})});
  auto runB = Evaluate(progB);
  check(runB.kind == "none", "re-edit to symmetric without recreate");
  if (runB.kind == "none" && !runB.bodies.empty())
    checkClose(Volume(runB.bodies[0]), 12000, 1e-6,
               "symmetric 5 volume same as distance 10 (total 10)");

  auto progC = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), {{"taperAngleDeg", 5}})});
  auto runC = Evaluate(progC);
  check(runC.kind == "none", "re-edit to add taper without recreate");

  auto progD = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10),
                 {{"thin", {{"thicknessMm", 1}, {"position", "midPlane"}}}})});
  auto runD = Evaluate(progD);
  check(runD.kind == "none", "re-edit to add thin without recreate");
}

void TestSuppression() {
  printf("\n[feature suppression + re-enable]\n");
  auto suppressedExtrude = ExtrudeV2(Eid('2'), Eid('1'), StartPlane(), ExtentDistance(10), {});
  suppressedExtrude["metadata"]["suppressed"] = true;
  auto suppressedProgram = nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()), suppressedExtrude});
  auto suppressedRun = Evaluate(suppressedProgram);
  check(suppressedRun.kind == "none", "suppressed extrude replays without kernel failure");
  if (suppressedRun.kind == "none")
    check(suppressedRun.bodies.empty(), "suppressed extrude produces no visible body");

  suppressedExtrude["metadata"]["suppressed"] = false;
  auto enabledRun = Evaluate(nlohmann::json::array(
      {Sketch(Eid('1'), WorldPlaneRef("xy"), RectEntities()), suppressedExtrude}));
  check(enabledRun.kind == "none", "re-enabled extrude evaluates");
  if (enabledRun.kind == "none" && !enabledRun.bodies.empty())
    checkClose(Volume(enabledRun.bodies.back()), 12000.0, 1e-6,
               "re-enabled extrude restores its authored volume");
}

void TestMultiBodyAndBoolean() {
  printf("\n[multi-body + Join/Cut/Intersect explicit targets]\n");
  std::string box1 = Eid('9');
  std::string box2 = Eid('8');
  std::string sketch = Eid('1');
  std::string extrude = Eid('2');
  // Two separate bodies, then extrude Join to first
  auto prog = nlohmann::json::array(
      {Box(box1, 40, 30, 10), Box(box2, 10, 10, 10),
       Sketch(sketch, WorldPlaneRef("xy"), RectEntities()),
       ExtrudeV2(extrude, sketch, StartPlane(), ExtentDistance(10),
                 {{"boolean", {{"mode", "join"}, {"targetOperationId", box1}}}})});
  auto run = Evaluate(prog);
  check(run.kind == "none", "multi-body Join evaluates");
  if (run.kind == "none") {
    // Visible bodies should be: box2 (untouched) + join result = 2 bodies
    check(run.bodies.size() == 2, "multi-body Join preserves unrelated body, consumes target");
  }
  // Upstream face move: change box1 height via new program, toFace should track or fail
  auto progFaceMove =
      nlohmann::json::array({Box(box1, 40, 30, 20), // taller target
                             Sketch(sketch, WorldPlaneRef("xy"), RectEntities()),
                             ExtrudeV2(extrude, sketch, StartPlane(), {{"mode", "toFace"}},
                                       {{"toFace", TopFaceRef(box1)}})});
  auto runFace = Evaluate(progFaceMove);
  check(runFace.kind == "none", "toFace tracks upstream face move (taller target)");
  if (runFace.kind == "none" && runFace.bodies.size() >= 2) {
    // extrude should now be height 20, not 10
    double vol = Volume(runFace.bodies.back());
    checkClose(vol, 40 * 30 * 20, 1e-6, "toFace uses moved face distance");
  }
}

// Mirror and pattern are catalog operations that consume a seed body;
// we verify an extruded body is a valid seed (topology survival across those hosts).
nlohmann::json MirrorOp(const std::string& id, const std::string& seedId, nlohmann::json plane) {
  return {{"id", id},
          {"type", "mirror"},
          {"outputBodyId", "b0000000-0000-4000-8000-0000000000a1"},
          {"parameters", {{"sourceOperationId", seedId}, {"plane", plane}, {"merge", false}}},
          {"metadata", Metadata()}};
}
nlohmann::json PatternLinearOp(const std::string& id, const std::string& seedId, int count,
                               double spacing) {
  return {{"id", id},
          {"type", "pattern_linear"},
          {"outputBodyId", "b0000000-0000-4000-8000-0000000000a2"},
          {"parameters",
           {{"seedOperationId", seedId},
            {"count", count},
            {"spacing", spacing},
            {"direction", {1, 0, 0}},
            {"op", "fuseInstances"}}},
          {"metadata", Metadata()}};
}

void TestMirrorAndPattern() {
  printf("\n[mirror + linear pattern of extruded body]\n");
  std::string sketch = Eid('1');
  std::string extrude = Eid('2');
  std::string mirror = Eid('3');
  std::string pattern = Eid('4');
  // Use a datum plane or world plane mirror — here we use a simple world xy plane mirror
  nlohmann::json plane = WorldPlaneRef("xy");
  // Mirror test: extrude a box, then mirror it
  auto progMirror =
      nlohmann::json::array({Sketch(sketch, WorldPlaneRef("xy"), RectEntities()),
                             ExtrudeV2(extrude, sketch, StartPlane(), ExtentDistance(10), {}),
                             MirrorOp(mirror, extrude, plane)});
  auto runMirror = Evaluate(progMirror);
  // Criterion 10 requires the extruded body to remain a valid mirror seed;
  // refusing the operation is not preservation.  This must prove the actual
  // result rather than accepting either success or an attributed refusal.
  check(runMirror.kind == "none", "mirror of extruded body evaluates");
  if (runMirror.kind != "none")
    printf("  mirror refusal: %s\n", runMirror.msg.c_str());
  if (runMirror.kind == "none") {
    check(runMirror.bodies.size() == 2, "mirror preserves source and mirrored bodies");
    if (runMirror.bodies.size() == 2) {
      checkClose(Volume(runMirror.bodies[0]), 12000.0, 1e-6, "mirror source volume");
      checkClose(Volume(runMirror.bodies[1]), 12000.0, 1e-6, "mirror result volume");
    }
  }

  auto progPattern =
      nlohmann::json::array({Sketch(sketch, WorldPlaneRef("xy"), RectEntities()),
                             ExtrudeV2(extrude, sketch, StartPlane(), ExtentDistance(10), {}),
                             PatternLinearOp(pattern, extrude, 3, 50)});
  auto runPattern = Evaluate(progPattern);
  // A rectangular pattern with 50mm spacing is intentionally disjoint.  A
  // professional pattern must preserve all three instances; treating the
  // disjoint result as a failure is not an acceptable success condition.
  check(runPattern.kind == "none", "pattern of extruded body evaluates");
  if (runPattern.kind != "none")
    printf("  pattern refusal: %s\n", runPattern.msg.c_str());
  if (runPattern.kind == "none") {
    check(runPattern.bodies.size() == 1, "pattern produces one semantic result body");
    if (runPattern.bodies.size() == 1)
      checkClose(Volume(runPattern.bodies[0]), 36000.0, 1e-6,
                 "pattern preserves all three instance volumes");
  }
}

} // namespace

int main() {
  printf(
      "[extrude-topology] Tournament — start offset, symmetric/twoSided, toFace, faceProfile, "
      "taper, thin, boolean, upstream edits, re-edit, multi-body, mirror/pattern (fail-closed)\n");
  TestStartOffset();
  TestSymmetric();
  TestTwoSided();
  TestTaper();
  TestThin();
  TestBoolean();
  TestToFace();
  TestFaceProfile();
  TestUpstreamSketchEdit();
  TestOpenProfileThin();
  TestSketchOnModelFace();
  TestThroughAll();
  TestStartObject();
  TestSketchRegionIds();
  TestReEdit();
  TestSuppression();
  TestMultiBodyAndBoolean();
  TestMirrorAndPattern();
  printf("\n[extrude-topology] failures: %d\n", g_failures);
  return g_failures == 0 ? 0 : 1;
}
