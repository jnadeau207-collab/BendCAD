#include "selector_evaluator.hpp"

#include <cstdint>
#include <iomanip>
#include <set>
#include <sstream>

#include <NCollection_IndexedDataMap.hxx>
#include <NCollection_List.hxx>
#include <TopExp.hxx>
#include <TopExp_Explorer.hxx>
#include <TopTools_ShapeMapHasher.hxx>

#define EvaluateQuery EvaluateQueryCore
#define ResolvedEntityToJson ResolvedEntityToJsonCore
#include "selector_evaluator-core.cpp"
#undef ResolvedEntityToJson
#undef EvaluateQuery

namespace aeth {
namespace {

using ShapeAncestorMap = NCollection_IndexedDataMap<TopoDS_Shape, NCollection_List<TopoDS_Shape>,
                                                    TopTools_ShapeMapHasher>;

void CheckAdjacencyCancellation(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed))
    throw Cancelled();
}

const EvaluatedBody& OwningBody(const QueryEntity& entity,
                                const std::vector<EvaluatedBody>& bodies) {
  const auto found =
      std::find_if(bodies.begin(), bodies.end(),
                   [&entity](const EvaluatedBody& body) { return body.bodyId == entity.bodyId; });
  if (found == bodies.end())
    throw std::runtime_error("selector adjacency could not find the entity's owning body");
  return *found;
}

void AddNewestToken(const TopoDS_Shape& shape, const NamingRegistry& registry,
                    std::set<std::string>& tokens) {
  const std::vector<std::string> answering = registry.TokensOf(shape);
  if (!answering.empty())
    tokens.insert(answering.back());
}

void AddSubshapeTokens(const TopoDS_Shape& owner, TopAbs_ShapeEnum kind,
                       const NamingRegistry& registry, const std::atomic_bool& cancelled,
                       std::set<std::string>& tokens) {
  for (TopExp_Explorer explorer(owner, kind); explorer.More(); explorer.Next()) {
    CheckAdjacencyCancellation(cancelled);
    AddNewestToken(explorer.Current(), registry, tokens);
  }
}

void AddAncestors(const TopoDS_Shape& body, const TopoDS_Shape& entity, TopAbs_ShapeEnum entityKind,
                  TopAbs_ShapeEnum ancestorKind, const NamingRegistry& registry,
                  const std::atomic_bool& cancelled, std::set<std::string>& tokens) {
  ShapeAncestorMap ancestors;
  TopExp::MapShapesAndAncestors(body, entityKind, ancestorKind, ancestors);
  const int index = ancestors.FindIndex(entity);
  if (index <= 0)
    return;
  const NCollection_List<TopoDS_Shape>& shapes = ancestors.FindFromIndex(index);
  for (const TopoDS_Shape& shape : shapes) {
    CheckAdjacencyCancellation(cancelled);
    AddNewestToken(shape, registry, tokens);
  }
}

std::string Fnv1aHex(const std::set<std::string>& tokens) {
  if (tokens.empty())
    return {};
  std::uint64_t hash = UINT64_C(14695981039346656037);
  constexpr std::uint64_t prime = UINT64_C(1099511628211);
  for (const std::string& token : tokens) {
    for (const unsigned char byte : token) {
      hash ^= static_cast<std::uint64_t>(byte);
      hash *= prime;
    }
    // A delimiter makes ["ab", "c"] distinct from ["a", "bc"].
    hash ^= UINT64_C(0xff);
    hash *= prime;
  }
  std::ostringstream stream;
  stream << std::hex << std::nouppercase << std::setfill('0') << std::setw(16) << hash;
  return stream.str();
}

std::string AdjacencyHash(const QueryEntity& entity, const std::vector<EvaluatedBody>& bodies,
                          const NamingRegistry& registry, const std::atomic_bool& cancelled) {
  // Synthetic datum entities are intentionally bodyless. They are legal in
  // operation ref-slot resolution, but have no visible B-rep neighborhood to
  // enrich, so their projection omits adjHash. Requiring a visible owner here
  // would turn a valid datum reference into an internal ownership failure.
  if (entity.bodyId.empty())
    return {};
  const TopoDS_Shape& body = OwningBody(entity, bodies).shape;
  std::set<std::string> tokens;
  switch (entity.kind) {
  case 'f':
    AddSubshapeTokens(entity.shape, TopAbs_EDGE, registry, cancelled, tokens);
    AddSubshapeTokens(entity.shape, TopAbs_VERTEX, registry, cancelled, tokens);
    break;
  case 'e':
    AddSubshapeTokens(entity.shape, TopAbs_VERTEX, registry, cancelled, tokens);
    AddAncestors(body, entity.shape, TopAbs_EDGE, TopAbs_FACE, registry, cancelled, tokens);
    break;
  case 'v':
    AddAncestors(body, entity.shape, TopAbs_VERTEX, TopAbs_EDGE, registry, cancelled, tokens);
    AddAncestors(body, entity.shape, TopAbs_VERTEX, TopAbs_FACE, registry, cancelled, tokens);
    break;
  default:
    throw std::runtime_error("selector adjacency covers faces, edges, and vertices only");
  }
  return Fnv1aHex(tokens);
}

} // namespace

QueryOutcome EvaluateQuery(const nlohmann::json& ast, const std::vector<EvaluatedBody>& bodies,
                           const NamingRegistry& registry, const std::atomic_bool& cancelled) {
  QueryOutcome outcome = EvaluateQueryCore(ast, bodies, registry, cancelled);
  for (QueryEntity& entity : outcome.entities) {
    CheckAdjacencyCancellation(cancelled);
    entity.adjHash = AdjacencyHash(entity, bodies, registry, cancelled);
  }
  return outcome;
}

nlohmann::json ResolvedEntityToJson(const QueryEntity& entity) {
  nlohmann::json json = ResolvedEntityToJsonCore(entity);
  if (!entity.adjHash.empty())
    json["adjHash"] = entity.adjHash;
  return json;
}

} // namespace aeth
