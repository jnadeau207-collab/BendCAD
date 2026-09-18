// Native integration tests for executor ref resolution (integration tranche
// N5; plan 05 §8 failure taxonomy, §9.3 two-channel anchor lattice). These
// drive the REAL EvaluateFillet path with a schemaVersion-2 `edges` ref, and
// the ResolveRef resolver directly, over box / resized-box programs. They pin
// the tranche's safety discipline — the product-side descendant of the NG-2
// tournament's zero-misreference gate:
//
//   1. a descriptive edge query cuts EXACTLY the resolved edge set (not all
//      edges), and the same query stays stable across a parameter edit;
//   2. an empty match raises E_SEL_EMPTY carrying the §8.1 stage cardinalities;
//   3. a `one` slot that resolves to several candidates raises E_SEL_AMBIGUOUS —
//      the op REFUSES rather than cutting a guessed edge — in each of three
//      ways: no anchor at all; an unknown-token anchor over a symmetric (but
//      NON-twin) fingerprint that corroborates on neither channel; and a genuine
//      grammar-required twin collision (the naming suite's proven fixture) where
//      the history channel cannot separate two byte-identical normalized names
//      even though the surviving token makes the signature channel commit;
//   4. the safety invariant of the positive path: if ResolveRef accepts a `one`
//      slot at all, it accepts EXACTLY the anchored entity, never another.
//
// COMPILE-UNVERIFIED: authored while this machine's OCCT toolchain was absent
// (see docs/execution/2026-07-17-n5-native-handoff.md). Build + run this suite
// once the toolchain is restored and reconcile any geometry-count expectations
// against the real kernel before landing on trunk.
#include <array>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepAdaptor_Surface.hxx>
#include <BRepBndLib.hxx>
#include <BRepBuilderAPI_Copy.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepTools_History.hxx>
#include <BRep_Builder.hxx>
#include <Bnd_Box.hxx>
#include <GeomAbs_SurfaceType.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Compound.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shape.hxx>
#include <TopoDS_Solid.hxx>
#include <gp_Ax2.hxx>
#include <gp_Dir.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "naming_registry.hpp"
#include "ref_resolution.hpp"
#include "selector_evaluator.hpp"

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

void checkEqual(const std::size_t actual, const std::size_t expected, const std::string& label) {
  if (actual == expected) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s (expected %zu, got %zu)\n", label.c_str(), expected, actual);
    g_failures += 1;
  }
}

const std::string kBoxOp = "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa";
const std::string kFilletOp = "eeeeeeee-5555-4e55-8e55-eeeeeeeeeeee";

nlohmann::json BoxOperation(const std::string& id, const double width, const double depth,
                            const double height, const std::array<double, 3>& origin) {
  return {
      {"id", id},
      {"type", "create_box"},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000b"},
      {"parameters",
       {{"width", width},
        {"depth", depth},
        {"height", height},
        {"placement",
         {{"origin", {origin[0], origin[1], origin[2]}},
          {"zDirection", {0.0, 0.0, 1.0}},
          {"xDirection", {1.0, 0.0, 0.0}}}}}},
  };
}

// --- AST builders (the wire form the parser emits; §3 mirror) --------------

nlohmann::json AsArray(std::initializer_list<nlohmann::json> items) {
  nlohmann::json array = nlohmann::json::array();
  for (const nlohmann::json& item : items)
    array.push_back(item);
  return array;
}

nlohmann::json ArgDirAxis(const int sign, const std::string& axis) {
  return {{"arg", "direction"}, {"value", {{"form", "axis"}, {"sign", sign}, {"axis", axis}}}};
}

nlohmann::json Filter(const std::string& name, std::initializer_list<nlohmann::json> args = {}) {
  return {{"name", name}, {"args", AsArray(args)}};
}
nlohmann::json SrcOp(const std::string& id) { return {{"source", "op"}, {"opId", id}}; }

nlohmann::json Query(const std::string& kind, std::initializer_list<nlohmann::json> scope,
                     std::initializer_list<nlohmann::json> filters = {}) {
  return {{"kind", kind}, {"scope", AsArray(scope)}, {"filters", AsArray(filters)}};
}

// The kernel-wire ref slot (operationRefWireSchema): the parsed AST plus the
// resolution policy. `anchors` defaults empty.
nlohmann::json EdgesRef(const nlohmann::json& ast, const std::string& arity,
                        const nlohmann::json& anchors = nlohmann::json::array()) {
  return {{"ast", ast}, {"arity", arity}, {"anchors", anchors}, {"onEmpty", "error"}};
}

// A schemaVersion-2 fillet program over one box, rounding the `edges`-ref set.
nlohmann::json FilletEdgesProgram(const nlohmann::json& box, const nlohmann::json& edgesRef,
                                  const double radius) {
  nlohmann::json fillet = {
      {"id", kFilletOp},
      {"type", "fillet"},
      {"schemaVersion", 2},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000e"},
      {"parameters", {{"targetOperationId", kBoxOp}, {"radius", radius}, {"edges", edgesRef}}},
  };
  return nlohmann::json::array({box, fillet});
}

// --- Harness ---------------------------------------------------------------

// Evaluates a program and counts the cylindrical blend faces of the fillet
// result — one per straight edge a constant-radius fillet rounds. Throws
// through on any failure (the caller of an error case uses FilletSelectorCode).
std::size_t CylindricalBlendFaces(const nlohmann::json& program) {
  aeth::NamingRegistry registry;
  std::atomic_bool cancelled{false};
  const std::vector<aeth::EvaluatedBody> bodies =
      aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
  return aeth::EvaluateQuery(Query("faces", {SrcOp(kFilletOp)}, {Filter("cylindrical")}), bodies,
                             registry, cancelled)
      .entities.size();
}

// Runs a fillet program expected to REFUSE and returns the fine selector code
// (E_SEL_EMPTY / E_SEL_AMBIGUOUS), or "" if it did not raise a SelectorFailure.
std::string FilletSelectorCode(const nlohmann::json& program) {
  aeth::NamingRegistry registry;
  std::atomic_bool cancelled{false};
  try {
    aeth::EvaluateOperations(program, cancelled, nullptr, &registry);
    return "";
  } catch (const aeth::SelectorFailure& error) {
    return error.SelectorCode();
  } catch (...) {
    return "";
  }
}

// Evaluates just the box (with a registry) so a ref can be resolved against it
// directly — the ResolveRef unit path, independent of the fillet consumer.
struct BoxState final {
  aeth::NamingRegistry registry;
  std::vector<aeth::EvaluatedBody> bodies;
  std::atomic_bool cancelled{false};
};

void EvaluateBox(BoxState& state, const nlohmann::json& box) {
  state.bodies = aeth::EvaluateOperations(nlohmann::json::array({box}), state.cancelled, nullptr,
                                          &state.registry);
}

// --- Tests -----------------------------------------------------------------

void EdgeScopedCutIsExact() {
  std::printf("edge-scoped fillet rounds exactly the resolved set:\n");
  const nlohmann::json box = BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0});
  // The four vertical convex edges — the canonical "round the corners" ref.
  const nlohmann::json verticalEdges =
      Query("edges", {SrcOp(kBoxOp)}, {Filter("convex"), Filter("parallel", {ArgDirAxis(1, "z")})});
  checkEqual(
      CylindricalBlendFaces(FilletEdgesProgram(box, EdgesRef(verticalEdges, "one-or-more"), 3.0)),
      4, "edges(box).convex().parallel(+z) rounds 4 edges -> 4 cylindrical blends");

  // Parameter edit: a larger box, SAME descriptive query, SAME resolved set.
  const nlohmann::json biggerBox = BoxOperation(kBoxOp, 60, 40, 25, {0, 0, 0});
  checkEqual(
      CylindricalBlendFaces(
          FilletEdgesProgram(biggerBox, EdgesRef(verticalEdges, "one-or-more"), 3.0)),
      4, "the same query on a resized box still rounds exactly 4 edges (stable across param edit)");
}

void EmptyMatchRefuses() {
  std::printf("an empty match raises E_SEL_EMPTY:\n");
  const nlohmann::json box = BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0});
  // A box has no circular edges — the ref resolves to nothing.
  const nlohmann::json circles = Query("edges", {SrcOp(kBoxOp)}, {Filter("circle")});
  check(FilletSelectorCode(FilletEdgesProgram(box, EdgesRef(circles, "one-or-more"), 3.0)) ==
            "E_SEL_EMPTY",
        "edges(box).circle() on a box -> E_SEL_EMPTY, never a mis-cut");
}

void MultipleWithoutAnchorRefuses() {
  std::printf("a `one` slot resolving to many with no anchor raises E_SEL_AMBIGUOUS:\n");
  const nlohmann::json box = BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0});
  // Four vertical edges, but the slot expects ONE and carries no anchor.
  const nlohmann::json verticalEdges =
      Query("edges", {SrcOp(kBoxOp)}, {Filter("parallel", {ArgDirAxis(1, "z")})});
  check(FilletSelectorCode(FilletEdgesProgram(box, EdgesRef(verticalEdges, "one"), 3.0)) ==
            "E_SEL_AMBIGUOUS",
        "arity=one over 4 edges with no anchor -> E_SEL_AMBIGUOUS, never picks one");
}

void UnknownTokenSymmetricAnchorIsAmbiguous() {
  std::printf("an unknown-token, symmetric anchor corroborates on neither channel (§9.3):\n");
  BoxState state;
  EvaluateBox(state, BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0}));

  // Honest description of what this verifies (it is NOT a twin collision): the
  // box's four vertical edges carry DISTINCT normalized lineage names (element
  // naming mints n1:<prefix>.e.<index> and normalization strips only Modified
  // segments), so they are not grammar twins. The anchor's token is bogus, so
  // the HISTORY channel returns Missing (FindByToken resolves no record). Its
  // centroid sits on the box centre axis, equidistant from all four corner
  // edges, and its only class hint (curve "line") fits every candidate, so the
  // SIGNATURE channel sees a flat tie below threshold and returns Ambiguous.
  // Neither channel commits -> the meet refuses. The refusal is geometry-count
  // independent: it rests on token-lookup Missing and a symmetric fingerprint,
  // not on any measured score margin.
  nlohmann::json anchor = {
      {"token", "t:" + kBoxOp + "/side-edge/999"}, // not a real record -> history Missing
      {"kind", "edge"},
      {"curve", "line"},
      {"centroid", {0.0, 0.0, 10.0}}, // on the central axis, symmetric to all 4
  };
  const nlohmann::json verticalEdges =
      Query("edges", {SrcOp(kBoxOp)}, {Filter("parallel", {ArgDirAxis(1, "z")})});
  const aeth::RefResolution resolution =
      aeth::ResolveRef(EdgesRef(verticalEdges, "one", nlohmann::json::array({anchor})),
                       state.bodies, state.registry, state.cancelled);
  check(resolution.status == aeth::RefStatus::Ambiguous,
        "a centre anchor over 4 symmetric edges -> Ambiguous (no corroboration on either channel)");
  check(!resolution.candidates.empty() && resolution.candidates.size() <= 5,
        "the ambiguous payload carries the scored top-k candidates");
}

void PositivePathAcceptsOnlyTheAnchored() {
  std::printf("the positive two-channel path accepts EXACTLY the anchored edge:\n");
  BoxState state;
  EvaluateBox(state, BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0}));

  // Resolve the four vertical edges, then build an anchor from ONE of them —
  // its real token + true centroid — the strongest possible corroboration.
  const aeth::QueryOutcome verticals = aeth::EvaluateQuery(
      Query("edges", {SrcOp(kBoxOp)}, {Filter("parallel", {ArgDirAxis(1, "z")})}), state.bodies,
      state.registry, state.cancelled);
  check(verticals.entities.size() == 4, "the box has four vertical edges to anchor against");
  if (verticals.entities.size() != 4)
    return;
  const aeth::QueryEntity& picked = verticals.entities.front();
  const nlohmann::json fingerprint = aeth::ResolvedEntityToJson(picked);
  nlohmann::json anchor = {
      {"token", fingerprint.at("token")},   {"kind", "edge"},
      {"curve", fingerprint.at("curve")},   {"centroid", fingerprint.at("centroid")},
      {"length", fingerprint.at("length")},
  };
  const nlohmann::json verticalEdges =
      Query("edges", {SrcOp(kBoxOp)}, {Filter("parallel", {ArgDirAxis(1, "z")})});
  const aeth::RefResolution resolution =
      aeth::ResolveRef(EdgesRef(verticalEdges, "one", nlohmann::json::array({anchor})),
                       state.bodies, state.registry, state.cancelled);
  // SAFETY INVARIANT (naming-independent): the resolver may accept (both
  // channels corroborated the anchored edge) or refuse (a twin the history
  // channel could not separate). It must NEVER accept a DIFFERENT edge. This is
  // the whole point of the two-channel lattice.
  if (resolution.status == aeth::RefStatus::Resolved) {
    check(resolution.entities.size() == 1 && resolution.entities.front().token == picked.token,
          "accepted -> exactly the anchored edge, with D_ANCHOR_DRIFT");
    bool drift = false;
    for (const aeth::QueryDiagnostic& diagnostic : resolution.diagnostics)
      drift = drift || diagnostic.code == "D_ANCHOR_DRIFT";
    check(drift, "an ambiguous-resolved acceptance carries D_ANCHOR_DRIFT");
  } else {
    check(resolution.status == aeth::RefStatus::Ambiguous,
          "refused -> Ambiguous (never a silent wrong pick)");
  }
}

void AllEdgesFallbackUnchanged() {
  std::printf("a v2 fillet with no `edges` slot still rounds every edge (v1 behavior):\n");
  const nlohmann::json box = BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0});
  nlohmann::json fillet = {
      {"id", kFilletOp},
      {"type", "fillet"},
      {"schemaVersion", 2},
      {"outputBodyId", "00000000-0000-4000-8000-00000000000e"},
      {"parameters", {{"targetOperationId", kBoxOp}, {"radius", 3.0}}}, // no edges slot
  };
  const nlohmann::json program = nlohmann::json::array({box, fillet});
  // Every one of the 12 straight box edges is rounded -> 12 cylindrical blends.
  checkEqual(CylindricalBlendFaces(program), 12, "no edges slot -> all 12 edges rounded");
}

// --- N6 slice C part 3: the same edge-scoped fillet resolved through the REAL
// evaluate_document path (DocumentEvaluator::Evaluate), which now threads an
// epoch-local NamingRegistry so the selector resolves on-kernel. The count is
// direct topology, not a query: a constant-radius fillet emits exactly one
// cylindrical blend face per straight edge it rounds, so "exactly 4 cylindrical
// faces" proves the persisted-query→lower→wire→resolve→execute pipeline rounded
// the four selected vertical edges and no others (never 12, never the wrong
// ones). ---------------------------------------------------------------------

// The cache-line identity DocumentEvaluator::Evaluate needs; irrelevant to a
// cold (reuse-off) evaluation but a required argument.
const std::string kDocId = "dddddddd-0000-4d00-8d00-dddddddddddd";
const std::string kGeomVersion = "occt-test+aeth.1";

std::size_t CountCylindricalFaces(const TopoDS_Shape& shape) {
  std::size_t count = 0;
  for (TopExp_Explorer it(shape, TopAbs_FACE); it.More(); it.Next()) {
    const BRepAdaptor_Surface surface(TopoDS::Face(it.Current()));
    if (surface.GetType() == GeomAbs_Cylinder)
      count += 1;
  }
  return count;
}

void EvaluateDocumentResolvesEdgeScopedFillet() {
  std::printf(
      "evaluate_document threads a registry so an edge-scoped fillet resolves on-kernel:\n");
  std::atomic_bool cancelled{false};
  // The 60x40x4 plate the agent-orchestrator N6 proof uses; radius 1.5 fits the
  // 4mm vertical edges. Round the four vertical convex edges.
  const nlohmann::json box = BoxOperation(kBoxOp, 60, 40, 4, {0, 0, 0});
  const nlohmann::json verticalEdges =
      Query("edges", {SrcOp(kBoxOp)}, {Filter("convex"), Filter("parallel", {ArgDirAxis(1, "z")})});
  const nlohmann::json program =
      FilletEdgesProgram(box, EdgesRef(verticalEdges, "one-or-more"), 1.5);

  aeth::DocumentEvaluator evaluator;
  const aeth::DocumentEvaluator::Result result =
      evaluator.Evaluate(program, kDocId, kGeomVersion, /*includeElementNames=*/false,
                         /*reuseEnabled=*/false, cancelled);

  checkEqual(result.bodies.size(), 1, "evaluate_document returns exactly the one filleted body");
  if (result.bodies.size() != 1)
    return;
  const aeth::EvaluatedBody& body = result.bodies.front();
  check(body.operationId == kFilletOp, "the surviving body is the fillet result");
  checkEqual(CountCylindricalFaces(body.shape), 4,
             "the edge-scoped fillet rounded EXACTLY the 4 selected edges (4 cylindrical faces)");
  check(body.probes.valid, "the fillet produced a valid solid");
  check(
      body.probes.volume > 9500.0 && body.probes.volume < 9600.0,
      "volume sits just below the 9600 plate (four corners removed), never a no-op or full round");
}

void EvaluateDocumentEmptySelectorRefusesClosed() {
  std::printf(
      "evaluate_document refuses an empty edge selector with E_SEL_EMPTY (never a mis-cut):\n");
  std::atomic_bool cancelled{false};
  const nlohmann::json box = BoxOperation(kBoxOp, 60, 40, 4, {0, 0, 0});
  // A box has no circular edges -> the selector resolves to the empty set.
  const nlohmann::json circles = Query("edges", {SrcOp(kBoxOp)}, {Filter("circle")});
  const nlohmann::json program = FilletEdgesProgram(box, EdgesRef(circles, "one-or-more"), 1.5);

  aeth::DocumentEvaluator evaluator;
  std::string selectorCode;
  std::string attributedOp;
  try {
    evaluator.Evaluate(program, kDocId, kGeomVersion, false, false, cancelled);
  } catch (const aeth::SelectorFailure& error) {
    selectorCode = error.SelectorCode();
    attributedOp = error.OperationId();
  }
  check(selectorCode == "E_SEL_EMPTY",
        "an empty edge selector through evaluate_document -> E_SEL_EMPTY, never a mis-cut");
  check(attributedOp == kFilletOp, "the selector refusal is attributed to the fillet op");
}

// Returns the box face whose bounding box is flat at z == level. (Mirrors the
// naming-registry suite's helper; used only to root the proven twin fixture.)
TopoDS_Face FaceAtZ(const TopoDS_Shape& shape, const double level) {
  for (TopExp_Explorer it(shape, TopAbs_FACE); it.More(); it.Next()) {
    const TopoDS_Face face = TopoDS::Face(it.Current());
    Bnd_Box box;
    BRepBndLib::Add(face, box);
    double xmin;
    double ymin;
    double zmin;
    double xmax;
    double ymax;
    double zmax;
    box.Get(xmin, ymin, zmin, xmax, ymax, zmax);
    if (std::abs(zmin - level) < 1.0e-6 && std::abs(zmax - level) < 1.0e-6)
      return face;
  }
  throw std::runtime_error("no box face at the requested z level");
}

void HistoryChannelRefusesTwinCollision() {
  std::printf("the history channel refuses to separate a grammar-required twin (§6.4):\n");
  std::atomic_bool cancelled{false};
  aeth::NamingRegistry registry;

  // Reuse the naming-registry suite's PROVEN twin program verbatim (the fixture
  // aeth-naming-registry-test / TwinCollisionSurfacesAsSuch pins as producing a
  // grammar-required collision: both faces carry byte-identical normalized
  // lineage names and are flagged nameCollision). Two congruent, coincident
  // Generated images of one box face, whose lower elements are unnameable at
  // disambiguation time, so the grammar's quantized-geometry fallback fires and
  // identical keys are REQUIRED to collide. This is a real, verified twin — not
  // the unknown-token symmetric case above.
  const std::string kSplitOp = "abababab-7777-4a77-8a77-abababababab";
  BRepPrimAPI_MakeBox boxMaker(gp_Ax2(gp_Pnt(-20, -15, 0), gp_Dir(0, 0, 1), gp_Dir(1, 0, 0)), 40,
                               30, 10);
  boxMaker.Build();
  TopoDS_Solid box = boxMaker.Solid();
  registry.Book().AddPrimitive(kBoxOp, box);
  registry.HarvestBoxBirth(kBoxOp, box, gp_Dir(0, 0, 1), cancelled);
  const TopoDS_Face top = FaceAtZ(box, 10.0);

  BRepBuilderAPI_MakeFace protoMaker(gp_Pln(gp_Pnt(0, 0, 10), gp_Dir(0, 0, 1)), -5, 5, -5, 5);
  const TopoDS_Face proto = protoMaker.Face();
  const TopoDS_Shape twinA = BRepBuilderAPI_Copy(proto).Shape();
  const TopoDS_Shape twinB = BRepBuilderAPI_Copy(proto).Shape();
  BRepTools_History history;
  history.AddGenerated(top, twinA);
  history.AddGenerated(top, twinB);
  BRep_Builder builder;
  TopoDS_Compound result;
  builder.MakeCompound(result);
  builder.Add(result, twinA);
  builder.Add(result, twinB);
  registry.Book().ApplyOperation(kSplitOp, {box}, result, history, cancelled);
  registry.HarvestOperation(kSplitOp, aeth::NamingRegistry::OperationClass::Boolean, {{box, false}},
                            result, history, cancelled);

  // Expose the two twin faces as a visible body so a `faces` query can enumerate
  // them: ResolveRef resolves the AST against the body pool, and the evaluator
  // requires each result sub-shape to belong to a visible body. The compound of
  // the two Generated twins IS that body's shape.
  aeth::EvaluatedBody body;
  body.bodyId = "00000000-0000-4000-8000-00000000000d";
  body.operationId = kSplitOp;
  body.shape = result;
  std::vector<aeth::EvaluatedBody> bodies;
  bodies.push_back(body);

  // Anchor with ONE twin's real token. FindByToken resolves it (history channel
  // active), but BOTH live candidates share the anchor's normalized name, so the
  // history channel hits matches.size() > 1 -> Ambiguous and the meet refuses —
  // even though the surviving exact token makes the SIGNATURE channel commit to
  // that one twin (+100). The two-channel meet fails closed on a twin regardless
  // of the signature score.
  std::string oneTwinToken;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.live && record.minter == kSplitOp && record.kind == 'f') {
      oneTwinToken = record.token;
      break;
    }
  }
  check(!oneTwinToken.empty(), "the proven fixture minted a live twin face token to anchor with");
  nlohmann::json anchor = {{"token", oneTwinToken}, {"kind", "face"}};
  const nlohmann::json bothTwins = Query("faces", {SrcOp(kSplitOp)});
  const aeth::RefResolution resolution = aeth::ResolveRef(
      EdgesRef(bothTwins, "one", nlohmann::json::array({anchor})), bodies, registry, cancelled);
  // SAFETY INVARIANT (geometry-count independent): a grammar-required twin the
  // history channel cannot separate must NEVER resolve to a single entity, no
  // matter how strongly the signature channel scores the surviving token.
  check(resolution.status == aeth::RefStatus::Ambiguous,
        "a twin-collision `one` slot -> Ambiguous (history channel refuses to separate twins)");
}

} // namespace

int main() {
  try {
    EdgeScopedCutIsExact();
    EmptyMatchRefuses();
    MultipleWithoutAnchorRefuses();
    UnknownTokenSymmetricAnchorIsAmbiguous();
    PositivePathAcceptsOnlyTheAnchored();
    AllEdgesFallbackUnchanged();
    EvaluateDocumentResolvesEdgeScopedFillet();
    EvaluateDocumentEmptySelectorRefusesClosed();
    HistoryChannelRefusesTwinCollision();
  } catch (const std::exception& error) {
    std::printf("FATAL: uncaught exception: %s\n", error.what());
    return 1;
  }
  if (g_failures == 0) {
    std::printf("\nALL REF RESOLUTION TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d REF RESOLUTION CHECK(S) FAILED\n", g_failures);
  return 1;
}
