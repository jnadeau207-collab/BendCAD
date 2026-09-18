#include "element_names.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <map>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include <BRepBndLib.hxx>
#include <BRepGProp.hxx>
#include <BRepTools_History.hxx>
#include <BRep_Tool.hxx>
#include <Bnd_Box.hxx>
#include <GProp_GProps.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <Precision.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Shape.hxx>
#include <TopoDS_Vertex.hxx>
#include <gp_Pnt.hxx>

#include "cancel.hpp"
#include "sha256.hpp"
#include "topology.hpp"

namespace aeth {
namespace {

using ShapeMap = NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher>;

// SHA-256 (FIPS 180-4) now lives in sha256.hpp (included above) so the name
// grammar and the operation-hash contract share ONE vetted implementation.
// Sha256Hex8 — the first 8 hex characters of a digest — is used below for the
// element-name grammar's collision-resistant short hashes.

// ---------------------------------------------------------------------------
// Grammar helpers.
// ---------------------------------------------------------------------------

bool IsHexDigit(const char character) {
  return (character >= '0' && character <= '9') || (character >= 'a' && character <= 'f');
}

/// First 8 hex characters of a UUID with dashes stripped and lowercased.
/// Operation ids are wire-validated UUIDs; anything else is a programming
/// error and fails loudly rather than minting a non-neutral name.
std::string OperationIdPrefix(const std::string& operationId) {
  std::string prefix;
  prefix.reserve(8);
  for (const char raw : operationId) {
    if (raw == '-')
      continue;
    const char lowered = raw >= 'A' && raw <= 'F' ? static_cast<char>(raw - 'A' + 'a') : raw;
    if (!IsHexDigit(lowered)) {
      throw std::runtime_error("element naming requires UUID operation ids");
    }
    prefix.push_back(lowered);
    if (prefix.size() == 8)
      return prefix;
  }
  throw std::runtime_error("element naming requires UUID operation ids");
}

/// A plain (undisambiguated) Modified step: exactly "M." + 8 hex characters.
/// Disambiguated steps "M.<8hex>.<8hex>" are NOT plain — they carry split
/// identity and survive normalization.
bool IsPlainModifiedSegment(const std::string& segment) {
  if (segment.size() != 10 || segment[0] != 'M' || segment[1] != '.')
    return false;
  for (std::size_t index = 2; index < segment.size(); ++index) {
    if (!IsHexDigit(segment[index]))
      return false;
  }
  return true;
}

/// The survivor-matching congruence (see element_names.hpp): erase plain
/// M steps, keep everything else. Every hash embedded in a name consumes
/// NORMALIZED constituent names so the congruence survives hashing.
std::string NormalizeName(const std::string& name) {
  std::string normalized;
  normalized.reserve(name.size());
  std::size_t position = 0;
  while (position <= name.size()) {
    const std::size_t slash = name.find('/', position);
    const std::size_t end = slash == std::string::npos ? name.size() : slash;
    const std::string segment = name.substr(position, end - position);
    if (!IsPlainModifiedSegment(segment)) {
      if (!normalized.empty())
        normalized += '/';
      normalized += segment;
    }
    if (slash == std::string::npos)
      break;
    position = slash + 1;
  }
  return normalized;
}

/// Order-free 8-hex digest of a set of already-normalized names: sorted
/// lexicographically, '\n'-joined. Sorting (never traversal order) is what
/// makes section names commutative under Boolean argument-order flips.
std::string HashNameSet(std::vector<std::string> names) {
  std::sort(names.begin(), names.end());
  std::string joined;
  for (std::size_t index = 0; index < names.size(); ++index) {
    if (index > 0)
      joined += '\n';
    joined += names[index];
  }
  return Sha256Hex8(joined);
}

char KindCodeOf(const TopAbs_ShapeEnum type) {
  switch (type) {
  case TopAbs_FACE:
    return 'f';
  case TopAbs_EDGE:
    return 'e';
  case TopAbs_VERTEX:
    return 'v';
  default:
    throw std::runtime_error("element naming covers faces, edges, and vertices only");
  }
}

constexpr std::array<TopAbs_ShapeEnum, 3> kNamedKinds{TopAbs_FACE, TopAbs_EDGE, TopAbs_VERTEX};

void CheckCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

/// Quantum for the geometry-key fallback: max(Precision::Confusion(),
/// 1e-7 x the anchors' combined bbox diagonal). The anchors are the
/// CONSTRUCTION shapes the entity descends from (its history source or
/// section parents), never the evaluation result: a re-evaluated document
/// state has a different result bbox (a suppressed boss changes the extent),
/// and a result-derived quantum would break byte-equality of names across
/// the two independent evaluations that Case B correspondence requires.
double QuantumFor(const std::vector<TopoDS_Shape>& anchors) {
  Bnd_Box box;
  for (const TopoDS_Shape& anchor : anchors) {
    BRepBndLib::Add(anchor, box);
  }
  double diagonal = 0.0;
  if (!box.IsVoid()) {
    double xMin = 0.0;
    double yMin = 0.0;
    double zMin = 0.0;
    double xMax = 0.0;
    double yMax = 0.0;
    double zMax = 0.0;
    box.Get(xMin, yMin, zMin, xMax, yMax, zMax);
    diagonal = std::sqrt((xMax - xMin) * (xMax - xMin) + (yMax - yMin) * (yMax - yMin) +
                         (zMax - zMin) * (zMax - zMin));
  }
  return std::max(Precision::Confusion(), 1e-7 * diagonal);
}

/// Fixed-precision quantized geometry key: centroid and measure divided by
/// the quantum and rounded to integers. Identical keys are REQUIRED to
/// produce identical names (twin collision -> resolver ambiguity); raw
/// floats never enter a name.
std::string QuantizedGeometryKey(const TopoDS_Shape& shape, const double quantum) {
  double measure = 0.0;
  gp_Pnt centroid(0.0, 0.0, 0.0);
  switch (shape.ShapeType()) {
  case TopAbs_FACE: {
    GProp_GProps properties;
    BRepGProp::SurfaceProperties(shape, properties);
    measure = std::abs(properties.Mass());
    centroid = properties.CentreOfMass();
    break;
  }
  case TopAbs_EDGE: {
    GProp_GProps properties;
    BRepGProp::LinearProperties(shape, properties);
    measure = std::abs(properties.Mass());
    centroid = properties.CentreOfMass();
    break;
  }
  case TopAbs_VERTEX:
    centroid = BRep_Tool::Pnt(TopoDS::Vertex(shape));
    break;
  default:
    throw std::runtime_error("element naming covers faces, edges, and vertices only");
  }
  const auto quantize = [quantum](const double value) { return std::llround(value / quantum); };
  return std::string(1, KindCodeOf(shape.ShapeType())) + ":" +
         std::to_string(quantize(centroid.X())) + ":" + std::to_string(quantize(centroid.Y())) +
         ":" + std::to_string(quantize(centroid.Z())) + ":" + std::to_string(quantize(measure));
}

// ---------------------------------------------------------------------------
// One operation application: the multi-pass naming of every result
// face/edge/vertex from the inputs' current names plus the algorithm's
// recorded history. All iteration is over TopExp::MapShapes index order or
// std::map-sorted keys — determinism is a wire contract, not a nicety.
// ---------------------------------------------------------------------------

class OperationNaming final {
public:
  OperationNaming(ElementNameMap& bookNames, const std::string& operationId,
                  const std::vector<TopoDS_Shape>& inputs, const TopoDS_Shape& result,
                  const BRepTools_History& history, const std::atomic_bool& cancelled)
      : bookNames_(bookNames), operationPrefix_(OperationIdPrefix(operationId)), inputs_(inputs),
        result_(result), history_(history), cancelled_(cancelled) {}

  void Run() {
    for (std::size_t kindIndex = 0; kindIndex < kNamedKinds.size(); ++kindIndex) {
      TopExp::MapShapes(result_, kNamedKinds[kindIndex], resultOfKind_[kindIndex]);
    }
    CollectSources();
    PassIdentitySurvivors();
    BuildReverseHistory();
    PlanAndAssignHistoryImages();
    // Sibling disambiguation and lower-bound reconstruction interleave to a
    // fixpoint: a split face's disambiguator needs its half-edges named,
    // which need the section vertices named, and a reconstructed vertex
    // needs its (possibly reconstructed) edges named first.
    bool progress = true;
    int guard = 0;
    while (progress) {
      CheckCancellation(cancelled_);
      if (++guard > 32)
        break;
      progress = false;
      if (ResolvePendingDisambiguators(false))
        progress = true;
      if (ResolveLowerBoundNames())
        progress = true;
    }
    // Stalled siblings fall back to the quantized-geometry disambiguator,
    // then reconstruction gets one more chance to consume those names.
    ResolvePendingDisambiguators(true);
    progress = true;
    guard = 0;
    while (progress) {
      CheckCancellation(cancelled_);
      if (++guard > 32)
        break;
      progress = ResolveLowerBoundNames();
    }
    AssignQuantizedRoots();
    MergeIntoBook();
  }

private:
  struct PendingImage final {
    TopoDS_Shape shape;
    /// Everything up to the disambiguator, ending with '.'.
    std::string prefix;
    /// Construction shapes anchoring the geometry-fallback quantum.
    std::vector<TopoDS_Shape> anchors;
    char kind{};
    bool resolved{};
  };

  const ShapeMap& ResultOfKind(const TopAbs_ShapeEnum type) const {
    switch (type) {
    case TopAbs_FACE:
      return resultOfKind_[0];
    case TopAbs_EDGE:
      return resultOfKind_[1];
    case TopAbs_VERTEX:
      return resultOfKind_[2];
    default:
      throw std::runtime_error("element naming covers faces, edges, and vertices only");
    }
  }

  bool InResult(const TopoDS_Shape& shape) const {
    const TopAbs_ShapeEnum type = shape.ShapeType();
    if (type != TopAbs_FACE && type != TopAbs_EDGE && type != TopAbs_VERTEX)
      return false;
    return ResultOfKind(type).Contains(shape);
  }

  void Assign(const TopoDS_Shape& shape, const std::string& name) {
    const std::string* existing = resultNames_.Seek(shape);
    if (existing != nullptr) {
      if (*existing != name) {
        throw std::runtime_error("element naming produced two distinct names for one entity (" +
                                 *existing + " vs " + name + ")");
      }
      return;
    }
    resultNames_.Bind(shape, name);
  }

  const std::string& SourceName(const int sourceOrdinal) const {
    const std::string* name = bookNames_.Seek(sources_(sourceOrdinal));
    if (name == nullptr) {
      throw std::runtime_error("element naming lost a source name it collected");
    }
    return *name;
  }

  void CollectSources() {
    for (const TopoDS_Shape& input : inputs_) {
      for (const TopAbs_ShapeEnum kind : kNamedKinds) {
        CheckCancellation(cancelled_);
        ShapeMap inputShapes;
        TopExp::MapShapes(input, kind, inputShapes);
        for (int index = 1; index <= inputShapes.Extent(); ++index) {
          const TopoDS_Shape& shape = inputShapes(index);
          if (sources_.Contains(shape))
            continue;
          if (bookNames_.Seek(shape) == nullptr) {
            throw std::runtime_error(
                "element naming requires every input sub-shape to be named before the "
                "operation applies");
          }
          sources_.Add(shape);
        }
      }
    }
  }

  /// A sub-shape that survives into the result as the exact same TopoDS
  /// shape was untouched by the operation: its name is UNCHANGED, with no
  /// new segment. Untouched-ness is exact set membership, mirroring the
  /// ProvenanceResolver discipline — never geometric similarity.
  void PassIdentitySurvivors() {
    for (int ordinal = 1; ordinal <= sources_.Extent(); ++ordinal) {
      const TopoDS_Shape& shape = sources_(ordinal);
      if (InResult(shape)) {
        Assign(shape, SourceName(ordinal));
      }
    }
  }

  void AddReverse(NCollection_DataMap<TopoDS_Shape, std::vector<int>, TopTools_ShapeMapHasher>& map,
                  const TopoDS_Shape& image, const int sourceOrdinal) {
    if (!InResult(image))
      return;
    std::vector<int>* parents = map.ChangeSeek(image);
    if (parents == nullptr) {
      map.Bind(image, std::vector<int>());
      parents = map.ChangeSeek(image);
    }
    if (std::find(parents->begin(), parents->end(), sourceOrdinal) == parents->end()) {
      parents->push_back(sourceOrdinal);
    }
  }

  void BuildReverseHistory() {
    for (int ordinal = 1; ordinal <= sources_.Extent(); ++ordinal) {
      CheckCancellation(cancelled_);
      const TopoDS_Shape& shape = sources_(ordinal);
      for (const TopoDS_Shape& image : history_.Modified(shape)) {
        AddReverse(reverseModified_, image, ordinal);
      }
      for (const TopoDS_Shape& image : history_.Generated(shape)) {
        AddReverse(reverseGenerated_, image, ordinal);
      }
    }
  }

  void PlanAndAssignHistoryImages() {
    // Plans keyed by (source ordinal, image kind): a source's same-kind
    // image count is what decides whether a step needs a disambiguator.
    std::map<std::pair<int, char>, std::vector<TopoDS_Shape>> modifiedPlans;
    std::map<std::pair<int, char>, std::vector<TopoDS_Shape>> generatedPlans;
    struct SectionPlan final {
      TopoDS_Shape shape;
      char kind{};
      std::vector<int> parents;
    };
    std::vector<SectionPlan> sectionPlans;

    for (const TopAbs_ShapeEnum kind : kNamedKinds) {
      const char code = KindCodeOf(kind);
      const ShapeMap& shapes = ResultOfKind(kind);
      for (int index = 1; index <= shapes.Extent(); ++index) {
        CheckCancellation(cancelled_);
        const TopoDS_Shape& shape = shapes(index);
        if (resultNames_.IsBound(shape))
          continue; // identity survivor
        if (const std::vector<int>* modifiedParents = reverseModified_.Seek(shape)) {
          // A Modified image continues its source's identity, so an entity
          // Modified from SEVERAL sources is a MERGED image: two operand
          // entities fusing into one result. Catalog wave 2 produces these by
          // construction — mirroring or patterning a body onto itself makes the
          // operands' coplanar faces merge — so this is a real domain, not a
          // contract violation (the earlier fixtures simply excluded it because
          // clearance rules forbade coincident faces).
          //
          // Exactly one ancestor may carry the identity forward. The winner is
          // the LOWEST source ordinal (ADR-006 lineage-first), which is
          // replay-deterministic. Operands are registered arguments-before-
          // tools, so the lowest ordinal is the TARGET — deliberately the same
          // ancestor the registry's §6.3 "target over tools" precedence picks,
          // which keeps the lineage name and the registry role on one entity.
          // Absorbed ancestors keep any other images they produced and are
          // still recorded as ancestors by the registry.
          const int winner = *std::min_element(modifiedParents->begin(), modifiedParents->end());
          modifiedPlans[{winner, code}].push_back(shape);
          continue;
        }
        if (const std::vector<int>* generatedParents = reverseGenerated_.Seek(shape)) {
          if (generatedParents->size() == 1) {
            generatedPlans[{generatedParents->front(), code}].push_back(shape);
          } else {
            sectionPlans.push_back({shape, code, *generatedParents});
          }
        }
      }
    }

    const auto assignStepPlans =
        [this](const std::map<std::pair<int, char>, std::vector<TopoDS_Shape>>& plans,
               const char marker) {
          for (const auto& [key, images] : plans) {
            const std::string step =
                SourceName(key.first) + "/" + std::string(1, marker) + "." + operationPrefix_;
            if (images.size() == 1) {
              Assign(images.front(), step);
              continue;
            }
            for (const TopoDS_Shape& image : images) {
              pending_.push_back({image, step + ".", {sources_(key.first)}, key.second, false});
            }
          }
        };
    assignStepPlans(modifiedPlans, 'M');
    assignStepPlans(generatedPlans, 'G');

    // Section entities: Generated from several sources. The parent set is
    // hashed commutatively; same-kind-up parents are preferred (a section
    // edge's two parent FACES) exactly as pinned for Boolean section edges.
    std::map<std::pair<std::string, char>, std::vector<std::pair<TopoDS_Shape, std::vector<int>>>>
        sectionGroups;
    for (const SectionPlan& plan : sectionPlans) {
      const TopAbs_ShapeEnum preferredKind = plan.kind == 'v' ? TopAbs_EDGE : TopAbs_FACE;
      std::vector<int> preferred;
      for (const int ordinal : plan.parents) {
        if (sources_(ordinal).ShapeType() == preferredKind)
          preferred.push_back(ordinal);
      }
      const std::vector<int>& chosen =
          plan.kind != 'f' && preferred.size() >= 2 ? preferred : plan.parents;
      std::vector<std::string> parentNames;
      parentNames.reserve(chosen.size());
      for (const int ordinal : chosen) {
        parentNames.push_back(NormalizeName(SourceName(ordinal)));
      }
      const std::string base = "n1:S." + operationPrefix_ + "." + HashNameSet(parentNames);
      sectionGroups[{base, plan.kind}].push_back({plan.shape, chosen});
    }
    for (const auto& [key, members] : sectionGroups) {
      if (members.size() == 1) {
        Assign(members.front().first, key.first);
        continue;
      }
      for (const auto& [shape, parents] : members) {
        std::vector<TopoDS_Shape> anchors;
        anchors.reserve(parents.size());
        for (const int ordinal : parents) {
          anchors.push_back(sources_(ordinal));
        }
        pending_.push_back({shape, key.first + ".", std::move(anchors), key.second, false});
      }
    }
  }

  std::string QuantizedDisambiguator(const PendingImage& pendingImage) const {
    const double quantum = QuantumFor(pendingImage.anchors);
    return Sha256Hex8(QuantizedGeometryKey(pendingImage.shape, quantum));
  }

  /// Lower kinds first (v, e, f) so an edge's disambiguator can consume the
  /// vertex names minted in the same sweep, and a face's the edge names.
  bool ResolvePendingDisambiguators(const bool force) {
    bool progress = false;
    for (const char kindCode : std::array<char, 3>{'v', 'e', 'f'}) {
      for (PendingImage& pendingImage : pending_) {
        if (pendingImage.resolved || pendingImage.kind != kindCode)
          continue;
        if (pendingImage.kind == 'v') {
          // A vertex has no lower elements; its only sibling separator is
          // the quantized-geometry key.
          Assign(pendingImage.shape, pendingImage.prefix + QuantizedDisambiguator(pendingImage));
          pendingImage.resolved = true;
          progress = true;
          continue;
        }
        const TopAbs_ShapeEnum lowerKind = pendingImage.kind == 'f' ? TopAbs_EDGE : TopAbs_VERTEX;
        ShapeMap lowerShapes;
        TopExp::MapShapes(pendingImage.shape, lowerKind, lowerShapes);
        std::vector<std::string> lowerNames;
        lowerNames.reserve(static_cast<std::size_t>(lowerShapes.Extent()));
        bool allNamed = lowerShapes.Extent() > 0;
        for (int index = 1; index <= lowerShapes.Extent() && allNamed; ++index) {
          const std::string* lowerName = resultNames_.Seek(lowerShapes(index));
          if (lowerName == nullptr) {
            allNamed = false;
            break;
          }
          lowerNames.push_back(NormalizeName(*lowerName));
        }
        if (allNamed) {
          Assign(pendingImage.shape, pendingImage.prefix + HashNameSet(std::move(lowerNames)));
          pendingImage.resolved = true;
          progress = true;
        } else if (force) {
          Assign(pendingImage.shape, pendingImage.prefix + QuantizedDisambiguator(pendingImage));
          pendingImage.resolved = true;
          progress = true;
        }
      }
    }
    return progress;
  }

  void BuildResultIncidence() {
    if (incidenceBuilt_)
      return;
    incidenceBuilt_ = true;
    const ShapeMap& faces = ResultOfKind(TopAbs_FACE);
    const ShapeMap& edges = ResultOfKind(TopAbs_EDGE);
    const ShapeMap& vertices = ResultOfKind(TopAbs_VERTEX);
    edgeFaces_.assign(static_cast<std::size_t>(edges.Extent()), {});
    vertexEdges_.assign(static_cast<std::size_t>(vertices.Extent()), {});
    for (int faceIndex = 1; faceIndex <= faces.Extent(); ++faceIndex) {
      ShapeMap faceEdges;
      TopExp::MapShapes(faces(faceIndex), TopAbs_EDGE, faceEdges);
      for (int local = 1; local <= faceEdges.Extent(); ++local) {
        const int edgeIndex = edges.FindIndex(faceEdges(local));
        if (edgeIndex > 0)
          edgeFaces_[static_cast<std::size_t>(edgeIndex - 1)].push_back(faceIndex);
      }
    }
    for (int edgeIndex = 1; edgeIndex <= edges.Extent(); ++edgeIndex) {
      ShapeMap edgeVertices;
      TopExp::MapShapes(edges(edgeIndex), TopAbs_VERTEX, edgeVertices);
      for (int local = 1; local <= edgeVertices.Extent(); ++local) {
        const int vertexIndex = vertices.FindIndex(edgeVertices(local));
        if (vertexIndex > 0)
          vertexEdges_[static_cast<std::size_t>(vertexIndex - 1)].push_back(edgeIndex);
      }
    }
  }

  /// Lower-bound reconstruction (passes 3/4 of the element-map scheme): an
  /// unattributed edge is named by the hash of its containing result faces'
  /// names; an unattributed vertex by its containing edges'. This is what
  /// names fillet blend boundaries, whose history is face-only.
  bool ResolveLowerBoundNames() {
    BuildResultIncidence();
    bool progress = false;
    const ShapeMap& faces = ResultOfKind(TopAbs_FACE);
    const ShapeMap& edges = ResultOfKind(TopAbs_EDGE);
    const ShapeMap& vertices = ResultOfKind(TopAbs_VERTEX);
    const auto tryReconstruct = [this, &progress](const ShapeMap& entityMap,
                                                  const std::vector<std::vector<int>>& containers,
                                                  const ShapeMap& containerMap) {
      for (int index = 1; index <= entityMap.Extent(); ++index) {
        const TopoDS_Shape& shape = entityMap(index);
        if (resultNames_.IsBound(shape))
          continue;
        const std::vector<int>& containing = containers[static_cast<std::size_t>(index - 1)];
        if (containing.empty())
          continue;
        std::vector<std::string> containerNames;
        containerNames.reserve(containing.size());
        bool allNamed = true;
        for (const int containerIndex : containing) {
          const std::string* containerName = resultNames_.Seek(containerMap(containerIndex));
          if (containerName == nullptr) {
            allNamed = false;
            break;
          }
          containerNames.push_back(NormalizeName(*containerName));
        }
        if (!allNamed)
          continue;
        Assign(shape, "n1:L." + operationPrefix_ + "." + HashNameSet(std::move(containerNames)));
        progress = true;
      }
    };
    tryReconstruct(edges, edgeFaces_, faces);
    tryReconstruct(vertices, vertexEdges_, edges);
    return progress;
  }

  /// Total coverage is a hard requirement: the quantized-geometry root is
  /// the last resort so a resolver's "no match" honestly means the identity
  /// is gone, never that the mapper skipped an entity.
  void AssignQuantizedRoots() {
    const std::vector<TopoDS_Shape> resultAnchor{result_};
    const double quantum = QuantumFor(resultAnchor);
    for (const TopAbs_ShapeEnum kind : kNamedKinds) {
      const ShapeMap& shapes = ResultOfKind(kind);
      for (int index = 1; index <= shapes.Extent(); ++index) {
        const TopoDS_Shape& shape = shapes(index);
        if (resultNames_.IsBound(shape))
          continue;
        Assign(shape, "n1:Q." + Sha256Hex8(QuantizedGeometryKey(shape, quantum)));
      }
    }
  }

  void MergeIntoBook() {
    for (const TopAbs_ShapeEnum kind : kNamedKinds) {
      const ShapeMap& shapes = ResultOfKind(kind);
      for (int index = 1; index <= shapes.Extent(); ++index) {
        const TopoDS_Shape& shape = shapes(index);
        const std::string* name = resultNames_.Seek(shape);
        if (name == nullptr) {
          throw std::runtime_error("element naming failed total coverage of the result");
        }
        const std::string* prior = bookNames_.Seek(shape);
        if (prior != nullptr && *prior != *name) {
          throw std::runtime_error("element naming rebound a live sub-shape to a new name");
        }
        bookNames_.Bind(shape, *name);
      }
    }
  }

  ElementNameMap& bookNames_;
  const std::string operationPrefix_;
  const std::vector<TopoDS_Shape>& inputs_;
  const TopoDS_Shape& result_;
  const BRepTools_History& history_;
  const std::atomic_bool& cancelled_;

  std::array<ShapeMap, 3> resultOfKind_;
  ShapeMap sources_;
  ElementNameMap resultNames_;
  NCollection_DataMap<TopoDS_Shape, std::vector<int>, TopTools_ShapeMapHasher> reverseModified_;
  NCollection_DataMap<TopoDS_Shape, std::vector<int>, TopTools_ShapeMapHasher> reverseGenerated_;
  std::vector<PendingImage> pending_;
  bool incidenceBuilt_ = false;
  std::vector<std::vector<int>> edgeFaces_;
  std::vector<std::vector<int>> vertexEdges_;
};

} // namespace

void ElementNameBook::AddPrimitive(const std::string& operationId, const TopoDS_Shape& shape) {
  const std::string prefix = OperationIdPrefix(operationId);
  for (const TopAbs_ShapeEnum kind : kNamedKinds) {
    const char code = KindCodeOf(kind);
    ShapeMap shapes;
    TopExp::MapShapes(shape, kind, shapes);
    for (int index = 1; index <= shapes.Extent(); ++index) {
      const std::string name =
          "n1:" + prefix + "." + std::string(1, code) + "." + std::to_string(index);
      const std::string* existing = names_.Seek(shapes(index));
      if (existing != nullptr && *existing != name) {
        throw std::runtime_error("element naming registered one primitive sub-shape twice");
      }
      names_.Bind(shapes(index), name);
    }
  }
}

void ElementNameBook::AddDerivedPrimitive(const std::string& operationId,
                                          const TopoDS_Shape& shape) {
  const std::string prefix = OperationIdPrefix(operationId);
  for (const TopAbs_ShapeEnum kind : kNamedKinds) {
    const char code = KindCodeOf(kind);
    ShapeMap shapes;
    TopExp::MapShapes(shape, kind, shapes);
    for (int index = 1; index <= shapes.Extent(); ++index) {
      // An already-named sub-shape is SHARED with the body this tool was
      // derived from; its existing name is the correct one and is preserved.
      // The ordinal is still consumed so the unnamed siblings keep stable
      // numbers across edits.
      if (names_.Seek(shapes(index)) != nullptr)
        continue;
      names_.Bind(shapes(index),
                  "n1:" + prefix + "." + std::string(1, code) + "." + std::to_string(index));
    }
  }
}

void ElementNameBook::ApplyOperation(const std::string& operationId,
                                     const std::vector<TopoDS_Shape>& inputs,
                                     const TopoDS_Shape& result, const BRepTools_History& history,
                                     const std::atomic_bool& cancelled) {
  OperationNaming naming(names_, operationId, inputs, result, history, cancelled);
  naming.Run();
}

std::string NormalizeElementName(const std::string& name) { return NormalizeName(name); }

const std::string& ElementNameBook::NameOf(const TopoDS_Shape& shape) const {
  const std::string* name = names_.Seek(shape);
  if (name == nullptr) {
    throw std::runtime_error("element name book has no name for a requested sub-shape");
  }
  return *name;
}

// The replay seam is a deep copy of the IsSame-keyed name map: NCollection_DataMap's
// copy duplicates every (shape-handle, name) entry, so the snapshot is an independent
// value that shares TShape identity — not aliasing — with the live book.
ElementNameBook::Snapshot ElementNameBook::TakeSnapshot() const { return Snapshot{names_}; }

void ElementNameBook::RestoreFrom(const Snapshot& snapshot) { names_ = snapshot.names; }

nlohmann::json ProjectElementNames(const ElementNameBook& book, const TopoDS_Shape& shape,
                                   const std::uint32_t evaluationEpoch,
                                   const std::uint32_t bodyOrdinal) {
  nlohmann::json entries = nlohmann::json::array();
  for (const TopAbs_ShapeEnum kind : kNamedKinds) {
    const char code = KindCodeOf(kind);
    ShapeMap shapes;
    TopExp::MapShapes(shape, kind, shapes);
    for (int index = 1; index <= shapes.Extent(); ++index) {
      const std::string& name = book.NameOf(shapes(index));
      if (name.empty() || name.size() > 512) {
        throw std::runtime_error("element name violates the wire length envelope");
      }
      entries.push_back({
          {"token", TopologyEntityToken(evaluationEpoch, bodyOrdinal, code, index - 1)},
          {"name", name},
      });
    }
  }
  return entries;
}

} // namespace aeth
