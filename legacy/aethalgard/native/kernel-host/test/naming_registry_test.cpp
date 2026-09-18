// Native integration tests for the kernel-host NamingRegistry (integration
// tranche N3; plan 05 §6.2–§6.4 as amended by ADR-006). These drive the REAL
// evaluation path — EvaluateOperations with a registry threaded exactly as a
// future selector request will thread it — plus one registry-level twin
// construction, and pin the tranche's three verify criteria:
//
//  1. token stability across replays: two independent evaluations of one
//     program produce record-for-record identical registries;
//  2. role/ordinal determinism: the explicit birth and mutating-operation role
//     tables assign the same roles and ordinals every time, byte-stable;
//  3. twin collision surfaces as such: grammar-required name twins are
//     flagged and indexed as collisions — never silently ordered apart.
//
// The twin case is constructed at the registry boundary with a hand-built
// history: the current document operation set is not known to produce
// grammar-level name twins (positional quantized disambiguators separate
// every mirror-symmetric construction the ops can express), but the grammar
// REQUIRES twins with identical lower-name sets or identical quantized keys
// to collide, and the registry's contract must hold for whichever future
// operation (patterns, symmetric branches of one op) first produces one.
#include <array>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <exception>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include <BRepAdaptor_Surface.hxx>
#include <BRepAlgoAPI_Cut.hxx>
#include <BRepAlgoAPI_Fuse.hxx>
#include <BRepBndLib.hxx>
#include <BRepBuilderAPI_Copy.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <BRepCheck_Analyzer.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakePrism.hxx>
#include <BRepTools_History.hxx>
#include <BRep_Builder.hxx>
#include <Bnd_Box.hxx>
#include <NCollection_DataMap.hxx>
#include <NCollection_IndexedMap.hxx>
#include <ShapeUpgrade_UnifySameDomain.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ListOfShape.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Compound.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shape.hxx>
#include <TopoDS_Solid.hxx>
#include <gp_Ax2.hxx>
#include <gp_Dir.hxx>
#include <gp_Pln.hxx>
#include <gp_Pnt.hxx>
#include <gp_Vec.hxx>
#include <nlohmann/json.hpp>

#include "element_names.hpp"
#include "geometry.hpp"
#include "naming_registry.hpp"
#include "sha256.hpp"

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

// Fixed UUID operation ids so lineage roots and tokens are stable in-test.
const std::string kBoxOp = "aaaaaaaa-1111-4a11-8a11-aaaaaaaaaaaa";
const std::string kHoleOp = "bbbbbbbb-2222-4b22-8b22-bbbbbbbbbbbb";
const std::string kToolBoxOp = "cccccccc-3333-4c33-8c33-cccccccccccc";
const std::string kCutOp = "dddddddd-4444-4d44-8d44-dddddddddddd";
const std::string kFilletOp = "eeeeeeee-5555-4e55-8e55-eeeeeeeeeeee";
const std::string kTransformOp = "ffffffff-6666-4f66-8f66-ffffffffffff";
const std::string kSplitOp = "abababab-7777-4a77-8a77-abababababab";
const std::string kChamferOp = "bcbcbcbc-aaaa-4baa-8baa-bcbcbcbcbcbc";
const std::string kSelfImageOp = "cdcdcdcd-8888-4c88-8c88-cdcdcdcdcdcd";

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

nlohmann::json BoxHoleProgram(const double radius) {
  return nlohmann::json::array({
      BoxOperation(kBoxOp, 80, 50, 15, {0, 0, 0}),
      {
          {"id", kHoleOp},
          {"type", "hole"},
          {"outputBodyId", "00000000-0000-4000-8000-00000000000c"},
          {"parameters",
           {{"targetOperationId", kBoxOp},
            {"placement",
             {{"origin", {15.0, 0.0, 15.0}},
              {"zDirection", {0.0, 0.0, -1.0}},
              {"xDirection", {1.0, 0.0, 0.0}}}},
            {"size", {{"kind", "radius"}, {"radius", radius}}},
            {"depth", 10.0},
            {"throughAll", false}}},
      },
  });
}

nlohmann::json GrooveProgram() {
  return nlohmann::json::array({
      BoxOperation(kBoxOp, 80, 50, 15, {0, 0, 0}),
      BoxOperation(kToolBoxOp, 10, 70, 10, {0, 0, 10}),
      {
          {"id", kCutOp},
          {"type", "boolean_combine"},
          {"outputBodyId", "00000000-0000-4000-8000-00000000000d"},
          {"parameters",
           {{"kind", "cut"}, {"targetOperationId", kBoxOp}, {"toolOperationId", kToolBoxOp}}},
      },
  });
}

nlohmann::json FilletProgram() {
  return nlohmann::json::array({
      BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0}),
      {
          {"id", kFilletOp},
          {"type", "fillet"},
          {"outputBodyId", "00000000-0000-4000-8000-00000000000e"},
          {"parameters", {{"targetOperationId", kBoxOp}, {"radius", 3.0}}},
      },
  });
}

nlohmann::json TransformProgram() {
  return nlohmann::json::array({
      BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0}),
      {
          {"id", kTransformOp},
          {"type", "transform"},
          {"outputBodyId", "00000000-0000-4000-8000-00000000000f"},
          {"parameters",
           {{"targetOperationId", kBoxOp},
            {"transform", {{"kind", "translate"}, {"offset", {5.0, 7.0, 9.0}}}}}},
      },
  });
}

const std::string kImportOp = "cdcdcdcd-8888-4c88-8c88-cdcdcdcdcdcd";
const std::string kImportFilletOp = "efefefef-9999-4e99-8e99-efefefefefef";

/// The STEP bytes of a 40x30x20 box, exported once through the production
/// exporter so the import under test reads a REAL Part-21 file rather than a
/// hand-written stub. Cached: the export is the slow part, and every caller
/// wants the identical bytes (which is the point — see the determinism check).
const std::string& BoxStepSource() {
  static const std::string source = [] {
    std::atomic_bool cancelled{false};
    const std::filesystem::path scratch =
        std::filesystem::temp_directory_path() / "aeth-naming-registry-import";
    std::error_code ec;
    std::filesystem::create_directories(scratch, ec);
    const std::filesystem::path exported = scratch / "box.step";
    aeth::EvaluatedBody body;
    body.bodyId = "00000000-0000-4000-8000-0000000000aa";
    body.operationId = "00000000-0000-4000-8000-0000000000ab";
    body.shape = BRepPrimAPI_MakeBox(40.0, 30.0, 20.0).Solid();
    body.probes = aeth::ProbeShape(body.shape);
    const std::u8string u8 = exported.u8string();
    aeth::ExportStep({body}, std::string(reinterpret_cast<const char*>(u8.data()), u8.size()),
                     cancelled);
    std::ifstream input(exported, std::ios::binary);
    return std::string((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
  }();
  return source;
}

nlohmann::json ImportOperation() {
  const std::string& source = BoxStepSource();
  aeth::Sha256 hasher;
  hasher.Update(reinterpret_cast<const unsigned char*>(source.data()), source.size());
  return {
      {"id", kImportOp},
      {"type", "import_step"},
      {"outputBodyId", "00000000-0000-4000-8000-0000000000ac"},
      {"parameters", {{"source", source}, {"sourceSha256", hasher.HexDigest()}}},
  };
}

nlohmann::json ImportProgram() { return nlohmann::json::array({ImportOperation()}); }

/// An import CONSUMED by a mutating operation. This is the composition the
/// registry could not express before CAP-011: HarvestOperation requires every
/// input sub-shape to already hold a record, so a fillet over an unharvested
/// import failed closed. Rounding every edge exercises the full attribution
/// path (survivors, blends, corner patches) against import-born ancestors.
nlohmann::json ImportFilletProgram() {
  return nlohmann::json::array({
      ImportOperation(),
      {
          {"id", kImportFilletOp},
          {"type", "fillet"},
          {"outputBodyId", "00000000-0000-4000-8000-0000000000ad"},
          {"parameters", {{"targetOperationId", kImportOp}, {"radius", 3.0}}},
      },
  });
}

std::vector<aeth::EvaluatedBody> Evaluate(const nlohmann::json& operations,
                                          aeth::NamingRegistry& registry) {
  std::atomic_bool cancelled{false};
  return aeth::EvaluateOperations(operations, cancelled, nullptr, &registry);
}

/// Full deterministic dump: append order, every field that the tranche's
/// determinism criterion covers. Byte-equality of two dumps IS the
/// role/ordinal determinism + token stability check.
std::string DumpRegistry(const aeth::NamingRegistry& registry) {
  std::string dump;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    dump += record.token;
    dump += '|';
    dump += record.kind;
    dump += '|';
    dump += record.role + "|" + record.minter + "|";
    dump += record.live ? "live" : "dead";
    dump += '|';
    dump += record.nameCollision ? "twin" : "-";
    dump += '|';
    dump += record.orderTie ? "tie" : "-";
    dump += '|';
    dump += record.lineageName + "|" + record.normalizedLineageName + "|";
    for (const std::string& ancestor : record.ancestors) {
      dump += ancestor;
      dump += ',';
    }
    dump += '\n';
  }
  return dump;
}

int CountLive(const aeth::NamingRegistry& registry, const std::string& minter,
              const std::string& role, const char kind) {
  int count = 0;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.live && record.minter == minter && record.role == role && record.kind == kind)
      count += 1;
  }
  return count;
}

void ReplayDeterminism(const std::string& label, const nlohmann::json& program) {
  aeth::NamingRegistry first;
  Evaluate(program, first);
  aeth::NamingRegistry second;
  Evaluate(program, second);
  checkEqual(second.RecordCount(), first.RecordCount(), label + ": record counts correlate 1:1");
  check(DumpRegistry(first) == DumpRegistry(second),
        label + ": independent replays are record-for-record byte-identical");
  // Name-keyed lookups agree across the replays: every live record found in
  // one registry resolves to the same token set in the other.
  bool lookupsAgree = true;
  for (std::size_t index = 0; index < first.RecordCount(); ++index) {
    const aeth::NamingRecord& record = first.RecordAt(index);
    if (!record.live)
      continue;
    const auto firstMatches = first.LiveByNormalizedName(record.kind, record.normalizedLineageName);
    const auto secondMatches =
        second.LiveByNormalizedName(record.kind, record.normalizedLineageName);
    if (firstMatches.size() != secondMatches.size()) {
      lookupsAgree = false;
      break;
    }
    for (std::size_t match = 0; match < firstMatches.size(); ++match) {
      if (firstMatches[match]->token != secondMatches[match]->token)
        lookupsAgree = false;
    }
  }
  check(lookupsAgree, label + ": name-keyed lookups agree across replays");
}

void BoxHoleRolesAndAliasing() {
  std::printf("box+hole roles and aliasing:\n");
  aeth::NamingRegistry registry;
  Evaluate(BoxHoleProgram(8), registry);

  checkEqual(static_cast<std::size_t>(CountLive(registry, kBoxOp, "top", 'f')), 1,
             "one live top face record");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kBoxOp, "bottom", 'f')), 1,
             "one live bottom face record");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kBoxOp, "side", 'f')), 4,
             "four live side face records");
  // Blind hole: the bore wall (tool lateral, a Modified image) and the floor
  // (the tool's untrimmed end cap, a synthetic-tool survivor re-minted under
  // the op role) both take the hole's `wall` role.
  checkEqual(static_cast<std::size_t>(CountLive(registry, kHoleOp, "wall", 'f')), 2,
             "bore wall and floor take the hole's wall role");
  // Exactly ONE section seam edge: the rim circle where the box top face
  // (target) meets the bore wall (tool) — a genuine target/tool section. The
  // floor circle and the bore's own seam line join two TOOL faces, so they
  // are tool-internal (`generated`), never section seams.
  checkEqual(static_cast<std::size_t>(CountLive(registry, kHoleOp, "seam", 'e')), 1,
             "exactly one section seam edge: the hole's rim circle");
  bool rimSpansBothOperands = false;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (!record.live || record.minter != kHoleOp || record.role != "seam")
      continue;
    bool fromBox = false;
    bool fromTool = false;
    for (const std::string& ancestor : record.ancestors) {
      if (ancestor.rfind("t:" + kBoxOp + "/", 0) == 0)
        fromBox = true;
      if (ancestor.rfind("t:" + kHoleOp + "/tool/", 0) == 0)
        fromTool = true;
    }
    rimSpansBothOperands = fromBox && fromTool;
  }
  check(rimSpansBothOperands, "the rim seam's ancestry spans the box target and the hole tool");
  // The synthetic tool's scaffolding records never outlive the harvest: a
  // synthetic tool has no durable identity, so no `tool`-role record may
  // remain live on a result entity (the fix that re-mints the floor as wall).
  bool toolRecordsDead = true;
  bool sawToolRecord = false;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.role == "tool") {
      sawToolRecord = true;
      if (record.live)
        toolRecordsDead = false;
    }
  }
  check(sawToolRecord && toolRecordsDead, "synthetic tool records exist and are all dead");

  // §6.3 step 12 aliasing: the re-trimmed top face still answers to its box
  // birth token AND to the hole's modified token, oldest first.
  const aeth::NamingRecord* topRecord = registry.FindByToken("t:" + kBoxOp + "/top/0");
  check(topRecord != nullptr && topRecord->live, "top face birth record is live after re-trim");
  if (topRecord != nullptr) {
    const std::vector<std::string> tokens = registry.TokensOf(topRecord->shape);
    checkEqual(tokens.size(), 2, "re-trimmed top face answers to exactly two tokens");
    check(!tokens.empty() && tokens.front() == topRecord->token,
          "alias chain starts at the birth token");
    check(tokens.size() == 2 && tokens.back().rfind("t:" + kHoleOp + "/modified/", 0) == 0,
          "alias chain ends at the hole's modified token");
    // The alias pair shares one shape and one normalized name — visible in
    // the index as two records over the SAME entity, which consumers must
    // deduplicate by shape before reading cardinality as a twin collision.
    const auto matches =
        registry.LiveByNormalizedName(topRecord->kind, topRecord->normalizedLineageName);
    checkEqual(matches.size(), 2, "alias pair is visible in the normalized-name index");
    bool sameShape = matches.size() == 2 && matches[0]->shape.IsSame(matches[1]->shape);
    check(sameShape, "alias pair records share one shape (not a twin collision)");
    check(matches.size() == 2 && !matches[0]->nameCollision && !matches[1]->nameCollision,
          "alias pair is not flagged as a name collision");
  }

  // Provenance: every wall record descends from the synthetic tool.
  bool wallAncestryHonest = true;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (!record.live || record.role != "wall")
      continue;
    if (record.ancestors.size() != 1 ||
        record.ancestors.front().rfind("t:" + kHoleOp + "/tool/", 0) != 0) {
      wallAncestryHonest = false;
    }
  }
  check(wallAncestryHonest, "wall records descend from the synthetic tool's tokens");
}

void GrooveSplitAndBooleanRoles() {
  std::printf("groove cut: split identity and boolean roles:\n");
  aeth::NamingRegistry registry;
  Evaluate(GrooveProgram(), registry);

  // The groove splits the plate's top face into two strips: a SPLIT never
  // aliases — the birth token dies and each strip minths a fresh modified
  // record with a grammar-DISTINCT name (their lower-name sets differ), so
  // no collision is flagged.
  const aeth::NamingRecord* topRecord = registry.FindByToken("t:" + kBoxOp + "/top/0");
  check(topRecord != nullptr && !topRecord->live, "split top face's birth token dies");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kCutOp, "modified", 'f')), 4,
             "two top strips and two re-trimmed sides take modified");
  bool stripsDistinct = true;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.live && record.minter == kCutOp && record.role == "modified" && record.kind == 'f' &&
        record.nameCollision) {
      stripsDistinct = false;
    }
  }
  check(stripsDistinct, "distinguishable split strips are not flagged as twins");

  checkEqual(static_cast<std::size_t>(CountLive(registry, kCutOp, "tool-face", 'f')), 3,
             "groove floor and both walls take tool-face");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kCutOp, "tool-edge", 'e')), 2,
             "surviving tool bottom edges take tool-edge");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kCutOp, "seam", 'e')), 8,
             "the groove's section edges take seam");
  // The untouched bottom face survives on its birth record.
  checkEqual(static_cast<std::size_t>(CountLive(registry, kBoxOp, "bottom", 'f')), 1,
             "untouched bottom face survives on its birth record");
  // All FOUR side birth records stay live: the two x-extreme faces are
  // untouched (one token each), and the two y-extreme faces are notched by
  // the groove — a 1:1 Modified image, so they ALIAS (§6.3 step 12) and keep
  // their birth `side` token alongside the new `modified` token. This is the
  // same aliasing the re-trimmed box+hole top face exercises.
  checkEqual(static_cast<std::size_t>(CountLive(registry, kBoxOp, "side", 'f')), 4,
             "all four side birth records stay live (two untouched, two aliased)");
  int untouchedSides = 0;
  int notchedSides = 0;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (!record.live || record.minter != kBoxOp || record.role != "side" || record.kind != 'f')
      continue;
    const std::size_t answeringTokens = registry.TokensOf(record.shape).size();
    if (answeringTokens == 1)
      untouchedSides += 1;
    else if (answeringTokens == 2)
      notchedSides += 1;
  }
  checkEqual(static_cast<std::size_t>(untouchedSides), 2,
             "two side faces are untouched survivors (one token each)");
  checkEqual(static_cast<std::size_t>(notchedSides), 2,
             "two notched side faces alias (birth token plus modified token)");
}

void FilletBlendRoles() {
  std::printf("fillet blend roles:\n");
  aeth::NamingRegistry registry;
  const auto bodies = Evaluate(FilletProgram(), registry);
  checkEqual(bodies.size(), 1, "fillet program returns one body");

  // v1 all-edges fillet of a box: 6 re-trimmed faces, 12 edge blends, 8
  // corner patches. Blends and corner patches harvest under `fillet`
  // (Generated images of box edges/vertices through the materialized
  // local-operation history); re-trimmed faces alias under `modified`.
  checkEqual(static_cast<std::size_t>(CountLive(registry, kFilletOp, "modified", 'f')), 6,
             "six re-trimmed box faces take modified");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kFilletOp, "fillet", 'f')), 20,
             "twelve edge blends and eight corner patches take fillet");
  // Every re-trimmed box face still answers to its birth token.
  int aliasedFaces = 0;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.live && record.minter == kBoxOp && record.kind == 'f' &&
        registry.TokensOf(record.shape).size() == 2) {
      aliasedFaces += 1;
    }
  }
  checkEqual(static_cast<std::size_t>(aliasedFaces), 6,
             "all six box faces alias through the fillet");
}

void TransformAliasesEverything() {
  std::printf("transform aliases everything:\n");
  aeth::NamingRegistry registry;
  Evaluate(TransformProgram(), registry);
  // Every entity is the 1:1 Modified continuation of its box source: 6 faces
  // + 12 edges + 8 vertices, all under the reserved modified role, every one
  // answering to both its birth token and the transform's token.
  checkEqual(static_cast<std::size_t>(CountLive(registry, kTransformOp, "modified", 'f')), 6,
             "six modified face records");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kTransformOp, "modified", 'e')), 12,
             "twelve modified edge records");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kTransformOp, "modified", 'v')), 8,
             "eight modified vertex records");
  bool everyEntityAliased = true;
  bool anyFlagged = false;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (!record.live)
      continue;
    if (registry.TokensOf(record.shape).size() != 2)
      everyEntityAliased = false;
    if (record.nameCollision || record.orderTie)
      anyFlagged = true;
  }
  check(everyEntityAliased, "every live entity answers to birth + transform tokens");
  check(!anyFlagged, "a rigid move flags no collisions and no order ties");
}

// Returns the box face whose bounding box is flat at z == level.
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

void TwinCollisionSurfacesAsSuch() {
  std::printf("twin collision surfaces as such:\n");
  std::atomic_bool cancelled{false};
  aeth::NamingRegistry registry;

  BRepPrimAPI_MakeBox boxMaker(gp_Ax2(gp_Pnt(-20, -15, 0), gp_Dir(0, 0, 1), gp_Dir(1, 0, 0)), 40,
                               30, 10);
  boxMaker.Build();
  TopoDS_Solid box = boxMaker.Solid();
  registry.Book().AddPrimitive(kBoxOp, box);
  registry.HarvestBoxBirth(kBoxOp, box, gp_Dir(0, 0, 1), cancelled);
  const TopoDS_Face top = FaceAtZ(box, 10.0);

  // TRUE grammar twins: two congruent, coincident Generated images of one
  // source face. Their lower elements are unnameable at disambiguation time
  // (mutual face/edge dependency), so the grammar's quantized-geometry
  // fallback fires — and identical keys are REQUIRED to collide, so both
  // faces (and, through L-reconstruction, their edges and vertices) carry
  // byte-identical lineage names.
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

  // The twin faces: identical names, both flagged, distinct tokens with a
  // stable presentation order, D_ORDER_TIE surfaced (their geometric keys
  // tie too — they are coincident), and the index reports BOTH.
  std::vector<const aeth::NamingRecord*> twinFaces;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.live && record.minter == kSplitOp && record.kind == 'f')
      twinFaces.push_back(&record);
  }
  checkEqual(twinFaces.size(), 2, "both twin faces mint records");
  if (twinFaces.size() == 2) {
    check(twinFaces[0]->lineageName == twinFaces[1]->lineageName,
          "twins carry byte-identical lineage names by grammar requirement");
    check(twinFaces[0]->token != twinFaces[1]->token, "twins still mint distinct tokens");
    check(twinFaces[0]->nameCollision && twinFaces[1]->nameCollision,
          "both twins are flagged as name collisions");
    check(twinFaces[0]->orderTie && twinFaces[1]->orderTie,
          "the geometric tie is surfaced as D_ORDER_TIE, never silent");
    check(!twinFaces[0]->shape.IsSame(twinFaces[1]->shape),
          "twin records hold distinct entities (a collision, not an alias)");
    const auto matches = registry.LiveByNormalizedName('f', twinFaces[0]->normalizedLineageName);
    checkEqual(matches.size(), 2, "the normalized-name index surfaces both twins");
  }
  // The twins' L-reconstructed edges collide too — an 8-way collision (4
  // edges per coincident twin), every one flagged.
  int collidedEdges = 0;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.live && record.minter == kSplitOp && record.kind == 'e' && record.nameCollision)
      collidedEdges += 1;
  }
  checkEqual(static_cast<std::size_t>(collidedEdges), 8,
             "all reconstructed twin edges surface as collisions");
  // The source box left the replay state entirely.
  bool boxDead = true;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.minter == kBoxOp && record.live)
      boxDead = false;
  }
  check(boxDead, "the consumed source's records all die");
}

void UntabledModifiersFailClosed() {
  std::printf("untabled modifiers fail closed:\n");
  // CAP-012 FLIPPED THE CHAMFER PIN. Chamfer now has a doc-04 role table and
  // harvests under the registry, so it is no longer the subject here — see
  // ChamferRolesAreTabled below. `offset` takes its place as the ONE remaining
  // untabled modifier: its history is measured-stable, but the normative plan
  // has no `### offset` section to table it against, so it must keep failing
  // closed rather than mint a role table invented at the keyboard.
  const nlohmann::json offsetProgram = nlohmann::json::array({
      BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0}),
      {
          {"id", kCutOp},
          {"type", "offset"},
          {"outputBodyId", "00000000-0000-4000-8000-000000000011"},
          {"parameters", {{"targetOperationId", kBoxOp}, {"distance", 2.0}}},
      },
  });
  for (const auto& [label, program] :
       std::vector<std::pair<std::string, const nlohmann::json*>>{{"offset", &offsetProgram}}) {
    aeth::NamingRegistry registry;
    try {
      Evaluate(*program, registry);
      check(false, label + " under the registry must fail closed");
    } catch (const aeth::OperationFailure& failure) {
      check(failure.Code() == "UNSUPPORTED_OPERATION",
            label + " fails with UNSUPPORTED_OPERATION under the registry");
    }
    // The same program without a registry keeps evaluating exactly as before.
    std::atomic_bool cancelled{false};
    try {
      aeth::EvaluateOperations(*program, cancelled);
      check(true, label + " still evaluates without the registry");
    } catch (const std::exception& error) {
      std::printf("  FAIL %s without the registry threw: %s\n", label.c_str(), error.what());
      g_failures += 1;
    }
  }
}

} // namespace

// Tranche 2.1 replay seam (naming half). TakeSnapshot/RestoreFrom must
// reproduce the full registry state — record-for-record AND the OCCT-keyed
// handle identity a tail replay's harvest resolves against — into a fresh
// registry; a restore fully replaces prior state; and a snapshot is a reusable,
// immutable value. This is the design's flagged main correctness risk, proven
// here at the seam before any prefix reuse trusts it.
/// CAP-012: the chamfer role table (doc-04 ~213-218). Bevel faces generated
/// from one provenance input edge are `chamfer`; the surviving original faces
/// stay `modified`. Asserted on a box whose 12 edges are all bevelled, so the
/// counts are exact rather than incidental.
void ChamferRolesAreTabled() {
  std::printf("chamfer roles are tabled (CAP-012):\n");
  const nlohmann::json program = nlohmann::json::array({
      BoxOperation(kBoxOp, 40, 30, 20, {0, 0, 0}),
      {
          {"id", kChamferOp},
          {"type", "chamfer"},
          {"outputBodyId", "00000000-0000-4000-8000-000000000012"},
          {"parameters", {{"targetOperationId", kBoxOp}, {"distance", 2.0}}},
      },
  });
  aeth::NamingRegistry registry;
  const std::vector<aeth::EvaluatedBody> bodies = Evaluate(program, registry);
  checkEqual(bodies.size(), 1, "a chamfer under the registry evaluates");
  check(bodies.front().probes.valid && bodies.front().probes.solidCount == 1,
        "the chamfered body is one valid solid");
  // MEASURED, and it corrects doc-04's expectation: bevelling all 12 box edges
  // yields 20 new faces (12 bevels + 8 corner patches), and the pinned OCCT
  // attributes EVERY one of them to a SINGLE provenance edge. No multi-source
  // Generated image occurs, so `chamfer-corner` — doc-04's row for "faces where
  // chamfers meet" — is not expressible from this history. Separating the 8
  // corner patches would take a geometric inference, and a role is what
  // `role(...)` selectors resolve against, so a guessed role is a wrong answer
  // to a user query. The role stays `chamfer` for all 20, exactly as fillet
  // labels every blend face `fillet`; the row remains reachable if a future
  // history ever reports a genuine multi-source bevel face.
  checkEqual(static_cast<std::size_t>(CountLive(registry, kChamferOp, "chamfer", 'f')), 20,
             "twenty live chamfer bevel-face records (12 bevels + 8 corner patches)");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kChamferOp, "chamfer-corner", 'f')), 0,
             "no chamfer-corner record: this history has no multi-source bevel face");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kChamferOp, "modified", 'f')), 6,
             "the six original box faces survive as modified");
  // No role outside the doc-04 table plus the reserved fallbacks.
  bool tabled = true;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (record.minter != kChamferOp)
      continue;
    if (record.role != "chamfer" && record.role != "chamfer-corner" &&
        record.role != "chamfer-edge" && record.role != "modified" && record.role != "generated")
      tabled = false;
  }
  check(tabled, "every chamfer record carries a doc-04 chamfer role or a reserved fallback");
}

/// CAP-034 — the local face offset pipeline's HISTORY, fixture-pinned.
///
/// Acceptance criterion 4 forbids minting names over history that has not been
/// fixture-pinned first, so this lands BEFORE any offset role table. It pins
/// the composed pipeline the CAP-034 spikes selected — sweep the target face
/// along its own normal, fuse (outward) or cut (inward), then
/// `UnifySameDomain` to reconstruct the boundary graph.
///
/// Why this is the RULED operation and not an approximation of it: the prism's
/// side walls lie EXACTLY in the neighbour planes, so the boolean re-trims those
/// neighbours against the moved surface rather than translating anything, and
/// the neighbours keep their original surfaces. The three clauses of the
/// founder's ruling map onto the three stages.
void LocalFaceOffsetHistoryFixtures() {
  std::printf("local face offset history (CAP-034):\n");

  struct Outcome final {
    int faces{};
    double volume{};
    bool valid{};
    int solids{};
    int shells{};
    int unifyModified{};
    int unattributed{};
  };

  using OffsetMap = NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher>;
  const auto run = [](const double distance) {
    Outcome outcome;
    const TopoDS_Shape box = BRepPrimAPI_MakeBox(90.0, 64.0, 36.0).Solid();
    OffsetMap faces;
    TopExp::MapShapes(box, TopAbs_FACE, faces);
    // Face 6 is the +Z top face in the pinned traversal.
    const TopoDS_Face target = TopoDS::Face(faces(6));
    BRepAdaptor_Surface surface(target, true);
    gp_Dir normal = surface.Plane().Axis().Direction();
    if (target.Orientation() == TopAbs_REVERSED)
      normal.Reverse();

    const bool outward = distance > 0.0;
    const gp_Vec sweep(normal.XYZ() * (outward ? distance : distance));
    const TopoDS_Shape prism = BRepPrimAPI_MakePrism(target, sweep).Shape();

    NCollection_List<TopoDS_Shape> objects;
    objects.Append(box);
    NCollection_List<TopoDS_Shape> tools;
    tools.Append(prism);
    TopoDS_Shape fused;
    if (outward) {
      BRepAlgoAPI_Fuse fuse;
      fuse.SetArguments(objects);
      fuse.SetTools(tools);
      fuse.SetRunParallel(false);
      fuse.SetToFillHistory(true);
      fuse.Build();
      fused = fuse.Shape();
    } else {
      BRepAlgoAPI_Cut cut;
      cut.SetArguments(objects);
      cut.SetTools(tools);
      cut.SetRunParallel(false);
      cut.SetToFillHistory(true);
      cut.Build();
      fused = cut.Shape();
    }

    OffsetMap fusedFaces;
    TopExp::MapShapes(fused, TopAbs_FACE, fusedFaces);
    ShapeUpgrade_UnifySameDomain unify(fused, true, true, false);
    unify.Build();
    const TopoDS_Shape unified = unify.Shape();

    OffsetMap unifiedFaces;
    TopExp::MapShapes(unified, TopAbs_FACE, unifiedFaces);
    const aeth::ShapeProbes probes = aeth::ProbeShape(unified);
    outcome.faces = unifiedFaces.Extent();
    outcome.volume = probes.volume;
    outcome.valid = BRepCheck_Analyzer(unified, false).IsValid();
    outcome.solids = probes.solidCount;
    outcome.shells = probes.shellCount;

    // Attribution: every unified face must trace back through the unify
    // history. An unattributable one is exactly what the totality rule refuses,
    // and is the reason `boolean_combine` runs no unify stage — this path is
    // only allowed one because UnifySameDomain CARRIES its history.
    const occ::handle<BRepTools_History>& history = unify.History();
    NCollection_DataMap<TopoDS_Shape, int, TopTools_ShapeMapHasher> reached;
    if (!history.IsNull()) {
      for (int i = 1; i <= fusedFaces.Extent(); ++i) {
        for (const TopoDS_Shape& image : history->Modified(fusedFaces(i))) {
          outcome.unifyModified += 1;
          if (!reached.IsBound(image))
            reached.Bind(image, 1);
        }
      }
    }
    // A unified face is attributable if the unify history MODIFIED it, or if it
    // passed through untouched — an identity survivor, which history has
    // nothing to report about. (Same class as CAP-013s ByJoin finding: the
    // inward cut needs no merging at all, so ALL six of its faces are identity
    // survivors and a Modified-only check would call them orphans.)
    for (int i = 1; i <= unifiedFaces.Extent(); ++i) {
      if (reached.IsBound(unifiedFaces(i)))
        continue;
      if (fusedFaces.Contains(unifiedFaces(i)))
        continue;
      outcome.unattributed += 1;
    }
    return outcome;
  };

  const Outcome out = run(5.0);
  // Criterion 2, outward: 90x64x41. Neighbours RE-TRIMMED, so SIX faces — the
  // fuse alone leaves 10 (each side split into original + extension) and unify
  // is what reconstructs the boundary graph.
  check(std::abs(out.volume - 236160.0) <= 1e-6,
        "outward +5 leaves exactly 90x64x41 = 236,160 mm^3");
  checkEqual(static_cast<std::size_t>(out.faces), 6,
             "outward +5 leaves SIX faces (neighbours re-trimmed, not split)");
  check(out.valid && out.solids == 1 && out.shells == 1, "outward +5 is one valid closed solid");
  checkEqual(static_cast<std::size_t>(out.unattributed), 0,
             "every unified face is attributable through the unify history");
  check(out.unifyModified > 0, "the unify history reports Modified images");

  const Outcome in = run(-5.0);
  // Criterion 2, inward: 90x64x31. The cut needs no unify — it splits nothing.
  check(std::abs(in.volume - 178560.0) <= 1e-6, "inward -5 leaves exactly 90x64x31 = 178,560 mm^3");
  checkEqual(static_cast<std::size_t>(in.faces), 6, "inward -5 leaves SIX faces");
  check(in.valid && in.solids == 1 && in.shells == 1, "inward -5 is one valid closed solid");
  checkEqual(static_cast<std::size_t>(in.unattributed), 0,
             "inward: every unified face is attributable (all six by IDENTITY — the cut "
             "needs no merging, so unify reports nothing about them)");

  // Determinism is a wire contract for anything that will mint names.
  const Outcome again = run(5.0);
  check(again.faces == out.faces && again.volume == out.volume &&
            again.unattributed == out.unattributed,
        "two independent runs of the pipeline agree exactly");
}

/// CAP-011: the import birth role table. An import is the one body birth with
/// no authored construction frame, so it mints FLAT per-kind roles. The test
/// asserts three things the capability rests on: total coverage under those
/// roles, that no role claims knowledge the kernel does not have, and that a
/// consuming operation can now attribute its result to import-born ancestors.
void ImportedBirthRoles() {
  std::printf("imported birth roles (CAP-011):\n");
  aeth::NamingRegistry registry;
  const std::vector<aeth::EvaluatedBody> bodies = Evaluate(ImportProgram(), registry);
  checkEqual(bodies.size(), 1, "the import produces exactly one body");

  // A 40x30x20 box read back from STEP: 6 faces, 12 edges, 8 vertices, every
  // one of them under the flat import role for its kind.
  checkEqual(static_cast<std::size_t>(CountLive(registry, kImportOp, "imported-face", 'f')), 6,
             "six live imported-face records");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kImportOp, "imported-edge", 'e')), 12,
             "twelve live imported-edge records");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kImportOp, "imported-vertex", 'v')), 8,
             "eight live imported-vertex records");
  checkEqual(registry.RecordCount(), 26, "the import mints records for nothing else");

  // No semantic role and no invented provenance: an import descends from file
  // bytes, so a `top`/`wall` role or an ancestor token would be a claim the
  // kernel cannot support.
  bool flat = true;
  for (std::size_t index = 0; index < registry.RecordCount(); ++index) {
    const aeth::NamingRecord& record = registry.RecordAt(index);
    if (!record.ancestors.empty() || record.nameCollision || record.orderTie)
      flat = false;
    if (record.role != "imported-face" && record.role != "imported-edge" &&
        record.role != "imported-vertex")
      flat = false;
  }
  check(flat, "every import record is ancestor-free, collision-free and flatly roled");

  // The composition the capability exists for: a mutating operation consuming
  // an imported body. Before CAP-011 this threw at the import.
  aeth::NamingRegistry composed;
  const std::vector<aeth::EvaluatedBody> filleted = Evaluate(ImportFilletProgram(), composed);
  checkEqual(filleted.size(), 1, "a fillet over an imported body evaluates");
  check(filleted.front().probes.valid && filleted.front().probes.solidCount == 1,
        "the filleted import is one valid solid");
  check(CountLive(composed, kImportFilletOp, "fillet", 'f') > 0,
        "the fillet mints blend faces attributed through import-born ancestors");
}

/// The other half of "never a guess": the import mint reads its lineage names
/// from the composed book, so an unnamed shape must fail the request loudly
/// rather than mint an identity it cannot justify.
void ImportedBirthFailsLoudlyWithoutNames() {
  std::printf("imported birth fails loudly without book names:\n");
  std::atomic_bool cancelled{false};
  aeth::NamingRegistry registry;
  const TopoDS_Shape unnamed = BRepPrimAPI_MakeBox(5.0, 5.0, 5.0).Solid();
  bool threw = false;
  try {
    registry.HarvestImportedBody(kImportOp, 0, unnamed, cancelled);
  } catch (const std::exception&) {
    threw = true;
  }
  check(threw, "harvesting an import the book never named is refused");
  checkEqual(registry.RecordCount(), 0, "nothing was minted by the refused harvest");
}

void NamingRegistrySnapshotRoundTrips() {
  std::printf("naming registry snapshot round-trips:\n");
  aeth::NamingRegistry regA;
  Evaluate(BoxHoleProgram(8), regA);
  aeth::NamingRegistry regB;
  Evaluate(FilletProgram(), regB);
  check(DumpRegistry(regA) != DumpRegistry(regB),
        "sanity: the two programs build distinct registries");

  const aeth::NamingRegistry::Snapshot snapA = regA.TakeSnapshot();
  const aeth::NamingRegistry::Snapshot snapB = regB.TakeSnapshot();

  // Round-trip into a fresh registry reproduces regA record-for-record.
  aeth::NamingRegistry t1;
  t1.RestoreFrom(snapA);
  checkEqual(t1.RecordCount(), regA.RecordCount(), "restore reproduces regA's record count");
  check(DumpRegistry(t1) == DumpRegistry(regA),
        "restored registry is record-for-record identical to regA");

  // Handle identity: the OCCT-keyed shapeIndex survived the copy, so every live
  // record's shape resolves to the same token set in the restored registry.
  bool handlesAgree = true;
  for (std::size_t index = 0; index < regA.RecordCount(); ++index) {
    const aeth::NamingRecord& record = regA.RecordAt(index);
    if (!record.live)
      continue;
    if (regA.TokensOf(record.shape) != t1.TokensOf(record.shape))
      handlesAgree = false;
  }
  check(
      handlesAgree,
      "a live record's shape resolves to the same tokens after restore (TShape identity survives)");

  // Restore fully replaces prior state: seeding t1 from snapB overwrites regA's.
  t1.RestoreFrom(snapB);
  check(DumpRegistry(t1) == DumpRegistry(regB),
        "a second restore fully replaces the prior state (now identical to regB)");

  // The snapshot was not disturbed by seeding then overwriting t1: a reusable,
  // immutable value.
  aeth::NamingRegistry t2;
  t2.RestoreFrom(snapA);
  check(DumpRegistry(t2) == DumpRegistry(regA),
        "snapA restores identically a second time (reusable, immutable value)");
}

// The bare ElementNameBook seam — the evaluate_document caching path threads a
// bare book, not a registry. Snapshot/restore must reproduce NameOf for every
// sub-shape of the evaluated bodies (total coverage; NameOf throws on a miss,
// so a silent gap cannot pass), and a snapshot is reusable.
void ElementNameBookSnapshotRoundTrips() {
  std::printf("element name book snapshot round-trips:\n");
  std::atomic_bool cancelled{false};
  aeth::ElementNameBook book;
  const std::vector<aeth::EvaluatedBody> bodies =
      aeth::EvaluateOperations(FilletProgram(), cancelled, &book, nullptr);

  const aeth::ElementNameBook::Snapshot snap = book.TakeSnapshot();
  aeth::ElementNameBook other;
  other.RestoreFrom(snap);
  aeth::ElementNameBook again;
  again.RestoreFrom(snap);

  const std::array<TopAbs_ShapeEnum, 3> kinds = {TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX};
  bool restoredAgrees = true;
  bool reuseAgrees = true;
  std::size_t compared = 0;
  for (const aeth::EvaluatedBody& body : bodies) {
    for (const TopAbs_ShapeEnum kind : kinds) {
      for (TopExp_Explorer explorer(body.shape, kind); explorer.More(); explorer.Next()) {
        const std::string& expected = book.NameOf(explorer.Current());
        if (other.NameOf(explorer.Current()) != expected)
          restoredAgrees = false;
        if (again.NameOf(explorer.Current()) != expected)
          reuseAgrees = false;
        compared += 1;
      }
    }
  }
  check(compared > 0, "the evaluated bodies expose named sub-shapes to compare");
  check(restoredAgrees, "the restored book answers NameOf identically for every sub-shape");
  check(reuseAgrees, "the same snapshot restores an identical book a second time (reusable)");
}

/// A composed history that reports a source as its OWN Modified image must not
/// abort the registry build.
///
/// `BRepTools_History::Merge` emits self-images — `Modified(x)` containing `x` —
/// for entities a stage left untouched, so every operation that composes two
/// histories produces them. Reading one as a real image made the source both an
/// identity survivor and a modified source, and the survivor pass rejected the
/// pair as an incoherent history. That threw out of `HarvestOperation`, which
/// fails `record_selection`, which leaves Hole / Push / Datum / Sketch / Mirror
/// / Hollow permanently disabled against a body that is perfectly valid — the
/// exact state a shipped build reached on a mirrored assembly.
///
/// The survivor must keep its identity and the operation must complete.
void SelfImagesAreIdentitySurvival() {
  std::printf("self-images in a composed history are identity survival:\n");
  aeth::NamingRegistry registry;
  const std::atomic_bool cancelled{false};

  BRepPrimAPI_MakeBox boxMaker(gp_Ax2(gp_Pnt(-20, -15, 0), gp_Dir(0, 0, 1), gp_Dir(1, 0, 0)), 40,
                               30, 10);
  boxMaker.Build();
  const TopoDS_Solid box = boxMaker.Solid();
  registry.Book().AddPrimitive(kBoxOp, box);
  registry.HarvestBoxBirth(kBoxOp, box, gp_Dir(0, 0, 1), cancelled);

  const std::size_t recordsBefore = registry.RecordCount();
  const TopoDS_Face top = FaceAtZ(box, 10.0);

  // The shape is untouched by the operation; the history nonetheless badges
  // every face as its own Modified image, which is exactly what a Merge of two
  // stage histories produces for the entities neither stage changed.
  BRepTools_History history;
  for (TopExp_Explorer face(box, TopAbs_FACE); face.More(); face.Next()) {
    history.AddModified(face.Current(), face.Current());
  }

  registry.Book().ApplyOperation(kSelfImageOp, {box}, box, history, cancelled);
  registry.HarvestOperation(kSelfImageOp, aeth::NamingRegistry::OperationClass::Boolean,
                            {{box, false}}, box, history, cancelled);

  // Identity survival keeps the birth records exactly as they were: no record
  // is retired, none is re-minted under the operation, and the top face is
  // still addressable by the role it was born with. A regression here throws
  // before reaching any of these.
  check(registry.RecordCount() == recordsBefore,
        "a pure identity-survival operation mints no new records");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kBoxOp, "top", 'f')), 1,
             "the top face survives with its birth record intact");
  checkEqual(static_cast<std::size_t>(CountLive(registry, kBoxOp, "side", 'f')), 4,
             "all four side faces survive with their birth records intact");
  check(!top.IsNull(), "the survivor is still a real face");
}

int main() {
  try {
    std::printf("replay determinism (token stability, role/ordinal determinism):\n");
    ReplayDeterminism("box+hole", BoxHoleProgram(8));
    ReplayDeterminism("groove cut", GrooveProgram());
    ReplayDeterminism("fillet", FilletProgram());
    ReplayDeterminism("transform", TransformProgram());
    // CAP-011: the same criterion over read-back topology. If OCCT's STEP
    // reader ever returned entities in an unstable order, this is where it
    // would surface — the packet's named blocked risk, measured rather than
    // assumed.
    ReplayDeterminism("imported step", ImportProgram());
    ReplayDeterminism("fillet over an import", ImportFilletProgram());
    BoxHoleRolesAndAliasing();
    GrooveSplitAndBooleanRoles();
    FilletBlendRoles();
    TransformAliasesEverything();
    TwinCollisionSurfacesAsSuch();
    UntabledModifiersFailClosed();
    ChamferRolesAreTabled();
    LocalFaceOffsetHistoryFixtures();
    ImportedBirthRoles();
    ImportedBirthFailsLoudlyWithoutNames();
    NamingRegistrySnapshotRoundTrips();
    ElementNameBookSnapshotRoundTrips();
    SelfImagesAreIdentitySurvival();
  } catch (const std::exception& error) {
    std::printf("FATAL: unhandled exception: %s\n", error.what());
    return 1;
  }
  if (g_failures > 0) {
    std::printf("%d failure(s)\n", g_failures);
    return 1;
  }
  std::printf("all naming registry tests passed\n");
  return 0;
}
