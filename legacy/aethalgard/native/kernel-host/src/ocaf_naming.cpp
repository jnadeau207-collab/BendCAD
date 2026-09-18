#include "ocaf_naming.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include <BRepAlgoAPI_Cut.hxx>
#include <BRepAlgoAPI_Fuse.hxx>
#include <BRepTools_History.hxx>
#include <BRep_Builder.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <NCollection_Map.hxx>
#include <Standard_Failure.hxx>
#include <TDF_ChildIterator.hxx>
#include <TDF_Data.hxx>
#include <TDF_Label.hxx>
#include <TNaming_Builder.hxx>
#include <TNaming_NamedShape.hxx>
#include <TNaming_Selector.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS_Compound.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Iterator.hxx>
#include <TopoDS_Shape.hxx>

#include "cancel.hpp"
#include "mutation.hpp"

namespace aeth {
namespace {

using ShapeMap = NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher>;
using LabelMap = NCollection_Map<TDF_Label>;

// ---------------------------------------------------------------------------
// Deterministic label layout. Label identity IS operation identity (the Case
// B replay re-records fresh states onto the same labels), so every tag below
// is a pure function of the operation's program position and the sub-shape's
// deterministic TopExp enumeration — never of traversal order or geometry.
//
//   root
//   +- FindChild(operationOrdinal)          one label per operation, 1-based
//   |  +- FindChild(kTagResult)             top-level Modify(inputBody, result)
//   |  +- FindChild(kTagDeleted)            Delete(s) for removed sub-shapes
//   |  +- FindChild(kTagPrimitive)          op-owned tool primitive (+ faces)
//   |  +- FindChild(kTagInputBase + i)      per consumed input i
//   |     +- FindChild(kTagModified)
//   |     |  +- FindChild(SubShapeTag(...)) Modify(s, image...) per sub-shape
//   |     +- FindChild(kTagGenerated)
//   |        +- FindChild(SubShapeTag(...)) Generated(s, image...)
//   +- FindChild(kTagSelectors)
//      +- FindChild(targetOrdinal + 1)      TNaming_Selector labels
//
// Per-sub-shape granularity for Modify/Generated (rather than the OCAF user
// guide's one-label-per-evolution grouping) keeps every recipe argument
// NamedShape as precise as possible: an argument attribute holding several
// unrelated shapes coarsens the recipe and invites compound results. The
// pitfall-#4 guards below stay in force regardless.
// ---------------------------------------------------------------------------
constexpr int kTagResult = 1;
constexpr int kTagDeleted = 2;
constexpr int kTagPrimitive = 3;
constexpr int kTagInputBase = 10;
constexpr int kTagModified = 1;
constexpr int kTagGenerated = 2;
constexpr int kTagPrimitiveFaceBase = 500000;
constexpr int kTagSelectors = 1000000;

struct OcafTarget final {
  char kindCode{};
  int index{};
};

struct TargetSelection final {
  OcafTarget target;
  TDF_Label selectorLabel;
  bool selected{};
};

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

TopAbs_ShapeEnum KindEnumOf(const char code) {
  switch (code) {
  case 'f':
    return TopAbs_FACE;
  case 'e':
    return TopAbs_EDGE;
  case 'v':
    return TopAbs_VERTEX;
  default:
    throw std::invalid_argument("ocaf target kind must be face, edge, or vertex");
  }
}

const char* KindNameOf(const char code) {
  switch (code) {
  case 'f':
    return "face";
  case 'e':
    return "edge";
  case 'v':
    return "vertex";
  default:
    throw std::invalid_argument("ocaf target kind must be face, edge, or vertex");
  }
}

std::vector<OcafTarget> ParseTargets(const nlohmann::json& request) {
  const auto& targetsJson = request.at("targets");
  if (!targetsJson.is_array() || targetsJson.empty() || targetsJson.size() > 10'000) {
    throw std::invalid_argument("ocaf_case targets must be a non-empty array of at most 10000");
  }
  std::vector<OcafTarget> targets;
  targets.reserve(targetsJson.size());
  for (const auto& entry : targetsJson) {
    const std::string kind = entry.at("kind").get<std::string>();
    char code = 0;
    if (kind == "face")
      code = 'f';
    else if (kind == "edge")
      code = 'e';
    else if (kind == "vertex")
      code = 'v';
    else
      throw std::invalid_argument("ocaf target kind must be face, edge, or vertex");
    const auto& indexJson = entry.at("index");
    if (!indexJson.is_number_integer()) {
      throw std::invalid_argument("ocaf target index must be an integer");
    }
    const long long index = indexJson.get<long long>();
    if (index < 0 || index > 1'000'000) {
      throw std::invalid_argument("ocaf target index must lie in [0, 1000000]");
    }
    targets.push_back({code, static_cast<int>(index)});
  }
  return targets;
}

int SubShapeTag(const TopAbs_ShapeEnum kind, const int oneBasedIndex) {
  switch (kind) {
  case TopAbs_FACE:
    return oneBasedIndex;
  case TopAbs_EDGE:
    return 100'000 + oneBasedIndex;
  case TopAbs_VERTEX:
    return 200'000 + oneBasedIndex;
  default:
    throw std::runtime_error("ocaf recorder covers faces, edges, and vertices only");
  }
}

/// Records a primitive shape: Generated(shape) at `label` (PRIMITIVE
/// evolution) plus one Generated(face) per face on a dedicated child label —
/// the OCAF box-driver convention. Per-face labels make each face
/// individually identified, which is what keeps edge/vertex selections
/// resolvable through INTERSECTION recipes over precisely named faces
/// (research 02 §3, pitfall #3: name the parent faces stably first). A
/// primitive that IS a single face (the split tool) records no face child: a
/// second PRIMITIVE state for the same TShape would make its first
/// appearance ambiguous to the identifier.
void RecordPrimitiveAt(const TDF_Label& label, const TopoDS_Shape& shape,
                       const std::atomic_bool& cancelled) {
  {
    TNaming_Builder builder(label);
    builder.Generated(shape);
  }
  ShapeMap faces;
  TopExp::MapShapes(shape, TopAbs_FACE, faces);
  if (faces.Extent() == 1 && faces(1).IsSame(shape))
    return;
  for (int index = 1; index <= faces.Extent(); ++index) {
    CheckCancellation(cancelled);
    TNaming_Builder faceBuilder(label.FindChild(kTagPrimitiveFaceBase + index));
    faceBuilder.Generated(faces(index));
  }
}

/// Records one operation's COMPLETE history (research 02 §3, pitfall #1)
/// from its BRepTools_History: every face, edge, and vertex of every input
/// is classified through exactly IsRemoved/Modified/Generated — Delete for
/// removed sub-shapes, Modify(s, image) for every survivor image, and
/// Generated(s, image) for generated ones. Identity survivors (the same
/// TShape persisting into the result, which is how General-Fuse algorithms
/// express "untouched") record no pair by necessity, not omission:
/// TNaming_Builder::Modify is a documented no-op for IsSame pairs in the
/// pinned source, and the survivor's birth state already IS its current
/// state. The complete-history rule's Modify(f, f) requirement targets
/// re-built survivors (new TShapes), which these algorithms never produce.
/// Any history claim that contradicts result membership fails the request
/// loudly instead of recording a corrupt document.
void RecordOperationHistory(const TDF_Label& operationLabel,
                            const std::vector<TopoDS_Shape>& inputs, const TopoDS_Shape& result,
                            const BRepTools_History& history, const std::atomic_bool& cancelled) {
  // Top-level result state: each consumed input BODY maps forward onto the
  // result (the OCAF cut/fuse convention). This is also what keeps a
  // selection CONTEXT current across the operation — TNaming solves inside
  // the current value of the context's evolution chain. Non-body inputs (the
  // split fixture's tool FACE) are never selection contexts and record no
  // top-level pair; their sub-shape history below is what names their
  // images.
  {
    TNaming_Builder resultBuilder(operationLabel.FindChild(kTagResult));
    for (const TopoDS_Shape& input : inputs) {
      if (input.ShapeType() <= TopAbs_SOLID) {
        resultBuilder.Modify(input, result);
      }
    }
  }
  ShapeMap resultSubshapes;
  TopExp::MapShapes(result, resultSubshapes);
  std::optional<TNaming_Builder> deleteBuilder;
  const std::array<TopAbs_ShapeEnum, 3> kinds{TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX};
  for (std::size_t inputOrdinal = 0; inputOrdinal < inputs.size(); ++inputOrdinal) {
    const TDF_Label inputLabel =
        operationLabel.FindChild(kTagInputBase + static_cast<int>(inputOrdinal));
    for (const TopAbs_ShapeEnum kind : kinds) {
      ShapeMap shapes;
      TopExp::MapShapes(inputs[inputOrdinal], kind, shapes);
      for (int index = 1; index <= shapes.Extent(); ++index) {
        CheckCancellation(cancelled);
        const TopoDS_Shape& shape = shapes(index);
        const int shapeTag = SubShapeTag(kind, index);
        const NCollection_List<TopoDS_Shape>& generated = history.Generated(shape);
        if (!generated.IsEmpty()) {
          TNaming_Builder generatedBuilder(inputLabel.FindChild(kTagGenerated).FindChild(shapeTag));
          for (const TopoDS_Shape& image : generated) {
            if (resultSubshapes.FindIndex(image) <= 0) {
              throw std::runtime_error(
                  "ocaf recorder: history reports a generated image absent from the result");
            }
            generatedBuilder.Generated(shape, image);
          }
        }
        if (history.IsRemoved(shape)) {
          if (!deleteBuilder)
            deleteBuilder.emplace(operationLabel.FindChild(kTagDeleted));
          deleteBuilder->Delete(shape);
          continue;
        }
        const NCollection_List<TopoDS_Shape>& modified = history.Modified(shape);
        if (modified.IsEmpty()) {
          if (resultSubshapes.FindIndex(shape) <= 0) {
            throw std::runtime_error(
                "ocaf recorder: history reports a surviving sub-shape absent from the result");
          }
          continue;
        }
        TNaming_Builder modifiedBuilder(inputLabel.FindChild(kTagModified).FindChild(shapeTag));
        for (const TopoDS_Shape& image : modified) {
          if (image.ShapeType() != kind) {
            throw std::runtime_error("ocaf recorder: history recorded a cross-kind Modified image");
          }
          if (resultSubshapes.FindIndex(image) <= 0) {
            throw std::runtime_error(
                "ocaf recorder: history reports a modified image absent from the result");
          }
          modifiedBuilder.Modify(shape, image);
        }
      }
    }
  }
}

/// Removes every TNaming_NamedShape state on an operation label and its
/// whole subtree (TNaming_NamedShape::BeforeRemoval clears the recorded
/// pairs out of the root TNaming_UsedShapes map, so stale evolutions can
/// never leak into a replayed document). Used by the Case B replay before an
/// operation re-records, and by suppression to leave an omitted operation
/// with no state at all.
void ClearOperationStates(const TDF_Label& operationLabel) {
  operationLabel.ForgetAttribute(TNaming_NamedShape::GetID());
  for (TDF_ChildIterator iterator(operationLabel, true); iterator.More(); iterator.Next()) {
    iterator.Value().ForgetAttribute(TNaming_NamedShape::GetID());
  }
}

/// The smallest uniquely-embedding selection context (research 02 §3,
/// pitfall #2): the owning SOLID of the target sub-shape within the BEFORE
/// shape — never the whole document. Returns a null shape when no solid of
/// `beforeShape` contains the sub-shape.
TopoDS_Shape OwningSolid(const TopoDS_Shape& beforeShape, const TopoDS_Shape& subShape) {
  for (TopExp_Explorer explorer(beforeShape, TopAbs_SOLID); explorer.More(); explorer.Next()) {
    ShapeMap solidSubshapes;
    TopExp::MapShapes(explorer.Current(), solidSubshapes);
    if (solidSubshapes.FindIndex(subShape) > 0)
      return explorer.Current();
  }
  return {};
}

/// Attaches one TNaming_Selector per target on a fresh label. Selection
/// failure (out-of-range index, no owning solid, Select() == false, or a
/// thrown OCCT failure) marks that target failed and continues with the
/// others — fail closed per target, never per request.
std::vector<TargetSelection> SelectTargets(const TDF_Label& selectorsRoot,
                                           const std::vector<OcafTarget>& targets,
                                           const TopoDS_Shape& beforeShape,
                                           const std::atomic_bool& cancelled) {
  std::vector<TargetSelection> selections;
  selections.reserve(targets.size());
  for (std::size_t targetOrdinal = 0; targetOrdinal < targets.size(); ++targetOrdinal) {
    CheckCancellation(cancelled);
    const OcafTarget& target = targets[targetOrdinal];
    TargetSelection selection;
    selection.target = target;
    selection.selectorLabel = selectorsRoot.FindChild(static_cast<int>(targetOrdinal) + 1);
    ShapeMap beforeShapes;
    TopExp::MapShapes(beforeShape, KindEnumOf(target.kindCode), beforeShapes);
    // OCCT maps are 1-based; the wire index is 0-based.
    if (target.index < 0 || target.index >= beforeShapes.Extent()) {
      selections.push_back(std::move(selection));
      continue;
    }
    const TopoDS_Shape& subShape = beforeShapes(target.index + 1);
    const TopoDS_Shape context = OwningSolid(beforeShape, subShape);
    if (context.IsNull()) {
      selections.push_back(std::move(selection));
      continue;
    }
    try {
      const TNaming_Selector selector(selection.selectorLabel);
      selection.selected = selector.Select(subShape, context);
    } catch (const Standard_Failure&) {
      selection.selected = false;
    } catch (const std::exception&) {
      selection.selected = false;
    }
    selections.push_back(std::move(selection));
  }
  return selections;
}

void CollectValidLabels(const TDF_Label& root, LabelMap& scope) {
  occ::handle<TNaming_NamedShape> namedShape;
  if (root.FindAttribute(TNaming_NamedShape::GetID(), namedShape))
    scope.Add(root);
  for (TDF_ChildIterator iterator(root, true); iterator.More(); iterator.Next()) {
    if (iterator.Value().FindAttribute(TNaming_NamedShape::GetID(), namedShape))
      scope.Add(iterator.Value());
  }
}

nlohmann::json SolvedEntity(const char kindCode, const int index) {
  return {{"kind", KindNameOf(kindCode)}, {"index", index}};
}

/// Solves every selector against the updated document and maps each answer
/// onto the AFTER result, applying the pitfall-#4/#6 guards (tracker
/// #23119): Solve() == false, null/empty NamedShape, or null Get() are
/// "missing"; a COMPOUND of target-kind members is "ambiguous" with the
/// member set; a wrong-kind shape, a member of the wrong kind, or a shape
/// absent from the AFTER result is "failed". Never a blind cast, never a
/// nearby index.
nlohmann::json SolveTargets(const TDF_Label& root, const std::vector<TargetSelection>& selections,
                            const TopoDS_Shape& afterShape, const std::atomic_bool& cancelled) {
  LabelMap scope;
  CollectValidLabels(root, scope);
  nlohmann::json outcomes = nlohmann::json::array();
  for (const TargetSelection& selection : selections) {
    CheckCancellation(cancelled);
    const char kindCode = selection.target.kindCode;
    nlohmann::json outcome = {
        {"target", {{"kind", KindNameOf(kindCode)}, {"index", selection.target.index}}},
    };
    if (!selection.selected) {
      outcome["status"] = "failed";
      outcomes.push_back(std::move(outcome));
      continue;
    }
    bool solveSucceeded = false;
    bool solveFailedHard = false;
    try {
      const TNaming_Selector selector(selection.selectorLabel);
      solveSucceeded = selector.Solve(scope);
    } catch (const Standard_Failure&) {
      solveFailedHard = true;
    } catch (const std::exception&) {
      solveFailedHard = true;
    }
    if (solveFailedHard) {
      outcome["status"] = "failed";
      outcomes.push_back(std::move(outcome));
      continue;
    }
    occ::handle<TNaming_NamedShape> namedShape;
    selection.selectorLabel.FindAttribute(TNaming_NamedShape::GetID(), namedShape);
    if (!solveSucceeded || namedShape.IsNull() || namedShape->IsEmpty()) {
      outcome["status"] = "missing";
      outcomes.push_back(std::move(outcome));
      continue;
    }
    TopoDS_Shape solvedShape;
    try {
      solvedShape = namedShape->Get();
    } catch (const Standard_Failure&) {
      solvedShape.Nullify();
    }
    if (solvedShape.IsNull()) {
      outcome["status"] = "missing";
      outcomes.push_back(std::move(outcome));
      continue;
    }
    ShapeMap afterShapes;
    TopExp::MapShapes(afterShape, KindEnumOf(kindCode), afterShapes);
    if (solvedShape.ShapeType() == TopAbs_COMPOUND) {
      bool coherent = true;
      std::vector<int> memberIndices;
      for (TopoDS_Iterator member(solvedShape); member.More(); member.Next()) {
        if (member.Value().ShapeType() != KindEnumOf(kindCode)) {
          coherent = false;
          break;
        }
        const int afterIndex = afterShapes.FindIndex(member.Value());
        if (afterIndex <= 0) {
          coherent = false;
          break;
        }
        memberIndices.push_back(afterIndex - 1);
      }
      if (!coherent) {
        outcome["status"] = "failed";
        outcomes.push_back(std::move(outcome));
        continue;
      }
      std::sort(memberIndices.begin(), memberIndices.end());
      memberIndices.erase(std::unique(memberIndices.begin(), memberIndices.end()),
                          memberIndices.end());
      nlohmann::json solved = nlohmann::json::array();
      for (const int memberIndex : memberIndices) {
        solved.push_back(SolvedEntity(kindCode, memberIndex));
      }
      outcome["status"] = "ambiguous";
      outcome["solved"] = std::move(solved);
      outcomes.push_back(std::move(outcome));
      continue;
    }
    if (solvedShape.ShapeType() != KindEnumOf(kindCode)) {
      outcome["status"] = "failed";
      outcomes.push_back(std::move(outcome));
      continue;
    }
    const int afterIndex = afterShapes.FindIndex(solvedShape);
    if (afterIndex <= 0) {
      outcome["status"] = "failed";
      outcomes.push_back(std::move(outcome));
      continue;
    }
    outcome["status"] = "solved";
    outcome["solved"] = nlohmann::json::array({SolvedEntity(kindCode, afterIndex - 1)});
    outcomes.push_back(std::move(outcome));
  }
  return {{"type", "ocaf_case"}, {"outcomes", std::move(outcomes)}};
}

// ---------------------------------------------------------------------------
// Fixture drivers. Construction is shared bit-for-bit with the mutation-case
// oracle through mutation.hpp, so the BEFORE/AFTER TopExp enumerations here
// are the SAME enumerations that minted the snapshot tokens the targets were
// parsed from.
// ---------------------------------------------------------------------------

nlohmann::json BuildSplitOcafCase(const PlanarSplitFixture& fixture,
                                  const std::vector<OcafTarget>& targets,
                                  const std::atomic_bool& cancelled) {
  const occ::handle<TDF_Data> data = new TDF_Data();
  const TDF_Label root = data->Root();
  const TopoDS_Shape baseSolid =
      BuildBaseBox(fixture.width, fixture.depth, fixture.height, cancelled);
  RecordPrimitiveAt(root.FindChild(1), baseSolid, cancelled);
  const std::vector<TargetSelection> selections =
      SelectTargets(root.FindChild(kTagSelectors), targets, baseSolid, cancelled);

  const TDF_Label splitLabel = root.FindChild(2);
  // The tool face is an op-owned primitive (it is never in the before
  // snapshot); recording it gives its section images an identified origin,
  // mirroring the element-name book's AddPrimitive(splitOperationId, tool).
  const TopoDS_Face splitTool = BuildSplitTool(fixture);
  RecordPrimitiveAt(splitLabel.FindChild(kTagPrimitive), splitTool, cancelled);
  occ::handle<BRepTools_History> history;
  const TopoDS_Shape result = RunPlanarSplitIntoHistory(baseSolid, splitTool, cancelled, history);
  RecordOperationHistory(splitLabel, {baseSolid, splitTool}, result, *history, cancelled);
  return SolveTargets(root, selections, result, cancelled);
}

nlohmann::json BuildFilletOcafCase(const FilletFixture& fixture,
                                   const std::vector<OcafTarget>& targets,
                                   const std::atomic_bool& cancelled) {
  const occ::handle<TDF_Data> data = new TDF_Data();
  const TDF_Label root = data->Root();
  const TopoDS_Shape baseSolid =
      BuildBaseBox(fixture.width, fixture.depth, fixture.height, cancelled);
  RecordPrimitiveAt(root.FindChild(1), baseSolid, cancelled);
  const std::vector<TargetSelection> selections =
      SelectTargets(root.FindChild(kTagSelectors), targets, baseSolid, cancelled);

  occ::handle<BRepTools_History> history;
  const TopoDS_Shape result = RunFilletIntoHistory(baseSolid, fixture, cancelled, history);
  RecordOperationHistory(root.FindChild(2), {baseSolid}, result, *history, cancelled);
  return SolveTargets(root, selections, result, cancelled);
}

nlohmann::json BuildMergeOcafCase(const MergeFixture& fixture,
                                  const std::vector<OcafTarget>& targets,
                                  const std::atomic_bool& cancelled) {
  const occ::handle<TDF_Data> data = new TDF_Data();
  const TDF_Label root = data->Root();
  const TopoDS_Shape targetSolid =
      BuildBaseBox(fixture.targetWidth, fixture.targetDepth, fixture.targetHeight, cancelled);
  const TopoDS_Shape toolSolid =
      BuildBoxAt(fixture.originX, fixture.originY, fixture.originZ, fixture.toolWidth,
                 fixture.toolDepth, fixture.toolHeight, cancelled);
  RecordPrimitiveAt(root.FindChild(1), targetSolid, cancelled);
  RecordPrimitiveAt(root.FindChild(2), toolSolid, cancelled);

  // The before snapshot's enumeration is over the compound of both argument
  // solids in fixture-declaration order, exactly as BuildMergeCase builds it.
  BRep_Builder compoundBuilder;
  TopoDS_Compound beforeCompound;
  compoundBuilder.MakeCompound(beforeCompound);
  compoundBuilder.Add(beforeCompound, targetSolid);
  compoundBuilder.Add(beforeCompound, toolSolid);
  const std::vector<TargetSelection> selections =
      SelectTargets(root.FindChild(kTagSelectors), targets, beforeCompound, cancelled);

  // The argumentOrder knob flips ONLY which argument list each solid enters
  // the fuse through; the recorded inputs stay in fixture-declaration order
  // (history keys on shape identity, not argument sides).
  BRepAlgoAPI_Fuse fuse;
  NCollection_List<TopoDS_Shape> tools;
  tools.Append(fixture.toolFirst ? targetSolid : toolSolid);
  BRepTools_History composedHistory;
  occ::handle<BRepTools_History> stepHistory;
  const TopoDS_Shape result =
      RunBooleanIntoHistory(fuse, fixture.toolFirst ? toolSolid : targetSolid, tools,
                            composedHistory, "merge fuse", cancelled, stepHistory);
  RecordOperationHistory(root.FindChild(3), {targetSolid, toolSolid}, result, *stepHistory,
                         cancelled);
  return SolveTargets(root, selections, result, cancelled);
}

nlohmann::json BuildLinearPatternOcafCase(const LinearPatternFixture& fixture,
                                          const std::vector<OcafTarget>& targets,
                                          const std::atomic_bool& cancelled) {
  const occ::handle<TDF_Data> data = new TDF_Data();
  const TDF_Label root = data->Root();
  // The base box is built ONCE and shared by both evaluations: a real
  // parametric replay re-executes only impacted operations, and the shared
  // TShape is what lets an unchanged base sub-shape's evolution chain span
  // the replayed fuse. Its geometry is identical to each independent
  // evaluation's own box, so the result enumerations match the snapshots.
  const TopoDS_Shape base = BuildBaseBox(fixture.width, fixture.depth, fixture.height, cancelled);
  RecordPrimitiveAt(root.FindChild(1), base, cancelled);
  const TDF_Label arrayLabel = root.FindChild(2);

  const auto evaluateState = [&](const int count) -> TopoDS_Shape {
    // All instances of the array feature are one operation: one compound
    // primitive (prefix-stable, instance-ordered) and ONE General-Fuse run
    // whose single history covers the box and every instance tool — exactly
    // EvaluateLinearPatternState's construction.
    BRep_Builder instanceCompoundBuilder;
    TopoDS_Compound instanceCompound;
    instanceCompoundBuilder.MakeCompound(instanceCompound);
    NCollection_List<TopoDS_Shape> tools;
    std::vector<TopoDS_Shape> inputs;
    inputs.push_back(base);
    for (int instance = 0; instance < count; ++instance) {
      const TopoDS_Shape boss =
          BuildVerticalCylinder(fixture.firstCenterX + instance * fixture.pitch, fixture.centerY,
                                fixture.height, fixture.bossRadius, fixture.bossHeight, cancelled);
      tools.Append(boss);
      instanceCompoundBuilder.Add(instanceCompound, boss);
      inputs.push_back(boss);
    }
    RecordPrimitiveAt(arrayLabel.FindChild(kTagPrimitive), instanceCompound, cancelled);
    BRepAlgoAPI_Fuse fuse;
    BRepTools_History composedHistory;
    occ::handle<BRepTools_History> stepHistory;
    const TopoDS_Shape result = RunBooleanIntoHistory(
        fuse, base, tools, composedHistory, "linear pattern fuse", cancelled, stepHistory);
    RecordOperationHistory(arrayLabel, inputs, result, *stepHistory, cancelled);
    return result;
  };

  const TopoDS_Shape beforeResult = evaluateState(fixture.countBefore);
  const std::vector<TargetSelection> selections =
      SelectTargets(root.FindChild(kTagSelectors), targets, beforeResult, cancelled);

  // Independent re-evaluation replay (Case B): the array operation's labels
  // are cleared and re-recorded with the new count's states — label identity
  // is operation identity, so downstream recipes re-solve against the
  // replayed history.
  ClearOperationStates(arrayLabel);
  const TopoDS_Shape afterResult = evaluateState(fixture.countAfter);
  return SolveTargets(root, selections, afterResult, cancelled);
}

nlohmann::json BuildBossSuppressionOcafCase(const BossSuppressionFixture& fixture,
                                            const std::vector<OcafTarget>& targets,
                                            const std::atomic_bool& cancelled) {
  const occ::handle<TDF_Data> data = new TDF_Data();
  const TDF_Label root = data->Root();
  const TopoDS_Shape base = BuildBaseBox(fixture.width, fixture.depth, fixture.height, cancelled);
  RecordPrimitiveAt(root.FindChild(1), base, cancelled);
  const TDF_Label bossLabel = root.FindChild(2);
  const TDF_Label holeLabel = root.FindChild(3);

  const TopoDS_Shape boss =
      BuildVerticalCylinder(fixture.bossCenterX, fixture.bossCenterY, fixture.height,
                            fixture.bossRadius, fixture.bossHeight, cancelled);
  RecordPrimitiveAt(bossLabel.FindChild(kTagPrimitive), boss, cancelled);
  TopoDS_Shape fused;
  {
    BRepAlgoAPI_Fuse fuse;
    NCollection_List<TopoDS_Shape> tools;
    tools.Append(boss);
    BRepTools_History composedHistory;
    occ::handle<BRepTools_History> stepHistory;
    fused = RunBooleanIntoHistory(fuse, base, tools, composedHistory, "boss fuse", cancelled,
                                  stepHistory);
    RecordOperationHistory(bossLabel, {base, boss}, fused, *stepHistory, cancelled);
  }

  // Identical hole-tool construction to EvaluateBossSuppressionState; the
  // SAME tool instance serves both evaluations (the unchanged feature is not
  // re-executed by a replay), which is what lets hole-owned chains span the
  // replayed cut.
  const double overshoot = fixture.height * 0.25;
  const TopoDS_Shape holeTool =
      BuildVerticalCylinder(fixture.holeCenterX, fixture.holeCenterY, -overshoot,
                            fixture.holeRadius, fixture.height + 2.0 * overshoot, cancelled);
  RecordPrimitiveAt(holeLabel.FindChild(kTagPrimitive), holeTool, cancelled);
  TopoDS_Shape beforeResult;
  {
    BRepAlgoAPI_Cut cut;
    NCollection_List<TopoDS_Shape> tools;
    tools.Append(holeTool);
    BRepTools_History composedHistory;
    occ::handle<BRepTools_History> stepHistory;
    beforeResult = RunBooleanIntoHistory(cut, fused, tools, composedHistory, "hole cut", cancelled,
                                         stepHistory);
    RecordOperationHistory(holeLabel, {fused, holeTool}, beforeResult, *stepHistory, cancelled);
  }
  const std::vector<TargetSelection> selections =
      SelectTargets(root.FindChild(kTagSelectors), targets, beforeResult, cancelled);

  // Suppression replay (Case B): the omitted boss operation's labels are
  // cleared and record NO new state; the downstream hole cut re-executes
  // against the bare base and re-records onto its own labels.
  ClearOperationStates(bossLabel);
  ClearOperationStates(holeLabel);
  RecordPrimitiveAt(holeLabel.FindChild(kTagPrimitive), holeTool, cancelled);
  TopoDS_Shape afterResult;
  {
    BRepAlgoAPI_Cut cut;
    NCollection_List<TopoDS_Shape> tools;
    tools.Append(holeTool);
    BRepTools_History composedHistory;
    occ::handle<BRepTools_History> stepHistory;
    afterResult = RunBooleanIntoHistory(cut, base, tools, composedHistory, "hole cut", cancelled,
                                        stepHistory);
    RecordOperationHistory(holeLabel, {base, holeTool}, afterResult, *stepHistory, cancelled);
  }
  return SolveTargets(root, selections, afterResult, cancelled);
}

} // namespace

nlohmann::json BuildOcafCase(const nlohmann::json& request, const std::atomic_bool& cancelled) {
  const std::string kind = request.at("fixture").at("kind").get<std::string>();
  const std::vector<OcafTarget> targets = ParseTargets(request);
  if (kind == "planar-split") {
    return BuildSplitOcafCase(ParsePlanarSplitFixture(request), targets, cancelled);
  }
  if (kind == "fillet") {
    return BuildFilletOcafCase(ParseFilletFixture(request), targets, cancelled);
  }
  if (kind == "merge") {
    return BuildMergeOcafCase(ParseMergeFixture(request), targets, cancelled);
  }
  if (kind == "linear-pattern") {
    return BuildLinearPatternOcafCase(ParseLinearPatternFixture(request), targets, cancelled);
  }
  if (kind == "boss-suppression") {
    return BuildBossSuppressionOcafCase(ParseBossSuppressionFixture(request), targets, cancelled);
  }
  throw std::invalid_argument("unsupported ocaf fixture kind: " + kind);
}

} // namespace aeth
