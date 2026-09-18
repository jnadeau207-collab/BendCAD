#pragma once

#include <atomic>
#include <cstdint>
#include <string>
#include <vector>

#include <NCollection_DataMap.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS_Shape.hxx>
#include <nlohmann/json.hpp>

class BRepTools_History;

namespace aeth {

/// Lineage-derived element names (NG-2 Phase A, research 02 §4/§5/§10).
///
/// A name is a deterministic string identity for one face/edge/vertex,
/// derived exclusively from the construction lineage recorded by real OCCT
/// algorithm histories — never from geometric similarity. Grammar (version
/// prefix "n1:"): one ROOT segment plus zero or more HISTORY segments joined
/// by '/':
///
/// - ROOT `n1:<opId8>.<kind>.<ordinal>` — opId8 is the first 8 hex characters
///   of the UUID of the operation that created the ancestor primitive
///   (dashes stripped); kind is f/e/v; ordinal is the entity's 1-based
///   TopExp::MapShapes index within that primitive shape at birth. Birth
///   enumeration of a parametrically determined primitive is deterministic
///   for a given program and build, so the root is lineage, not position
///   (the token channel stays epoch-local and positional per ADR-003).
/// - `M.<opId8>` — the entity is the sole same-kind Modified() image of its
///   source under that operation: identity survives (history rule R3).
/// - `G.<opId8>` — the entity was Generated() from the source: a NEW identity
///   whose segments continue the source's name so provenance stays visible.
/// - Sibling disambiguation `M.<opId8>.<d8>` / `G.<opId8>.<d8>`: when one
///   source leaves SEVERAL same-kind images under one operation (a split),
///   each image's step carries a disambiguator derived TOPOLOGICALLY — the
///   SHA-256 (first 8 hex) of the image's sorted, '\n'-joined lower-element
///   names (a face's result edges; an edge's result vertices), computed
///   multi-pass so lower elements resolve first. Images with IDENTICAL
///   lower-name sets (true twins) receive IDENTICAL names BY REQUIREMENT:
///   twins must collide so a resolver reports ambiguous instead of guessing.
///   Traversal order and unquantized floats never disambiguate. When lower
///   elements stay unnameable, the fallback is a quantized-geometry key
///   (centroid and measure quantized to max(Precision::Confusion(),
///   1e-7 x the SOURCE shape's bbox diagonal — the source is construction-
///   stable across independent evaluations, the result is not) hashed the
///   same way; identical keys again collide by design.
/// - Section root `n1:S.<opId8>.<h8>` — a Boolean section entity Generated()
///   from SEVERAL sources (a section edge appears in the Generated list of
///   both parent faces). h8 hashes the parents' normalized names, sorted
///   lexicographically and '\n'-joined, so the name is commutative and
///   survives Boolean argument-order flips. When several section entities
///   share one parent set, the sibling-disambiguator rule appends `.d8`.
///   Same-kind-up parents are preferred (an edge's face parents, a vertex's
///   edge parents) exactly as the research pins for section edges.
/// - Lower-bound root `n1:L.<opId8>.<h8>` — reconstruction for entities the
///   mapper cannot attribute (fillet histories are face-only for Modified):
///   an unnamed edge whose containing result faces are all named takes the
///   hash of those face names; an unnamed vertex likewise from its edges.
/// - Quantized root `n1:Q.<h8>` — last-resort total-coverage fallback from
///   the quantized-geometry key. Total coverage is required so a resolver's
///   "no match" honestly means missing, never "the mapper skipped it".
///
/// NORMALIZATION (the survivor-matching congruence): normalize(name) erases
/// every plain `M.<opId8>` segment and keeps everything else (root, G, S, L,
/// Q, and disambiguated `M.<opId8>.<d8>` segments). Two names denote the same
/// construction identity, WITHIN one entity kind, iff their normalized forms
/// are equal, or one normalized form extends the other by segments that are
/// all M-type. Every hash embedded in a name (S, L, disambiguators) is
/// computed over NORMALIZED constituent names so the congruence survives
/// hashing — this is what lets a feature-suppression re-evaluation, which
/// removes an M step from the MIDDLE of a lineage chain, still match its
/// survivors by string comparison.
///
/// DETERMINISM: byte-identical names across identical evaluations on one
/// build. Every iteration is over TopExp::MapShapes index order or sorted
/// keys, never unordered containers.
///
/// NEUTRALITY: the emitted alphabet is exactly [0-9a-f], the markers
/// n/M/G/S/L/Q/f/e/v, and ':', '.', '/'. That alphabet cannot spell any word
/// of the tournament's banned oracle vocabulary in any case combination.
using ElementNameMap = NCollection_DataMap<TopoDS_Shape, std::string, TopTools_ShapeMapHasher>;

/// Records one construction's operations in order and maintains an
/// IsSame-keyed map from every live sub-shape to its lineage name. Feed it
/// the EXACT TopoDS_Shape instances the algorithms consumed and produced
/// (BRepTools_History keys on shape identity; a copied intermediate silently
/// severs the lineage — the Copy=true trap in research 02 §5).
class ElementNameBook final {
public:
  /// Names every face/edge/vertex of a primitive created by `operationId`
  /// with a ROOT segment. `shape` may be a compound when one operation
  /// creates several primitives (a pattern's instance set): compound-wide
  /// MapShapes ordinals keep instance sub-shapes distinct and, because the
  /// enumeration is prefix-stable in instance order, cardinality edits leave
  /// surviving instances' ordinals — and therefore names — unchanged.
  void AddPrimitive(const std::string& operationId, const TopoDS_Shape& shape);

  /// Names a synthesized tool that SHARES geometry with a body already in the
  /// book, binding only the sub-shapes that are still unnamed and leaving every
  /// existing name untouched.
  ///
  /// `AddPrimitive` deliberately refuses a re-registration under a conflicting
  /// name, and that guard is right for a tool synthesized from nothing (the
  /// hole's cylinder shares no sub-shape with anything). CAP-034's offset prism
  /// is the different case: it is SWEPT FROM the target's own face, so its base
  /// face, edges and vertices are literally the target's and already carry the
  /// target's names. Those names are the correct ones and must survive — only
  /// the swept side walls and the moved top face are new and need roots.
  ///
  /// Ordinals still come from the full compound-wide `MapShapes` enumeration,
  /// so skipping a bound sub-shape does not renumber the ones after it.
  void AddDerivedPrimitive(const std::string& operationId, const TopoDS_Shape& shape);

  /// Applies one recorded algorithm: consumes the current names of the
  /// inputs' sub-shapes and produces a name for EVERY face/edge/vertex of
  /// `result` via the multi-pass scheme (identity survivors, history images,
  /// sibling disambiguation to fixpoint, lower-bound reconstruction,
  /// quantized fallback). Throws if an input sub-shape is unnamed or if the
  /// history asserts relations the fixtures structurally exclude.
  void ApplyOperation(const std::string& operationId, const std::vector<TopoDS_Shape>& inputs,
                      const TopoDS_Shape& result, const BRepTools_History& history,
                      const std::atomic_bool& cancelled);

  /// Name of one sub-shape (IsSame-keyed). Throws when unnamed — projection
  /// totality is a hard contract, so a miss is a defect, never a skip.
  const std::string& NameOf(const TopoDS_Shape& shape) const;

  /// Tranche 2.1 replay seam: an immutable value copy of the name map, so a
  /// cache entry can restore the lineage state as of an operation prefix. The
  /// map is keyed on TopoDS_Shape by IsSame identity, so the copy shares TShape
  /// identity with the shapes it was harvested from — a restored book answers
  /// NameOf() for the same live sub-shapes. RestoreFrom is a full replacement.
  struct Snapshot final {
    ElementNameMap names;
  };
  Snapshot TakeSnapshot() const;
  void RestoreFrom(const Snapshot& snapshot);

private:
  ElementNameMap names_;
};

/// Projects a book onto the wire: one {token, name} entry per face/edge/
/// vertex of `shape`, enumerated with the SAME per-kind TopExp::MapShapes
/// order DescribeTopology uses to mint tokens, so entries correlate 1:1 with
/// the topology snapshot of the same shape/epoch/ordinal.
nlohmann::json ProjectElementNames(const ElementNameBook& book, const TopoDS_Shape& shape,
                                   std::uint32_t evaluationEpoch, std::uint32_t bodyOrdinal);

/// The survivor-matching congruence (see the grammar notes above): erases
/// every plain `M.<opId8>` segment and keeps everything else. This is THE
/// normalization the whole naming substrate shares — the NamingRegistry's
/// `byNormalizedLineageName` index (plan 05 §6.2, ADR-006) consumes exactly
/// this implementation rather than re-deriving the congruence.
std::string NormalizeElementName(const std::string& name);

} // namespace aeth
