#pragma once

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <string>

#include <TopoDS_Shape.hxx>
#include <nlohmann/json.hpp>

#include "geometry.hpp"

namespace aeth {

/// Per-entity provenance resolver. Snapshot builders that describe the result
/// of a mutation must be able to attribute preserved sub-shapes to the
/// operation that originally produced them instead of the mutating operation.
using ProvenanceResolver = std::function<std::string(const TopoDS_Shape&)>;

/// Epoch-local topology token. Deterministic within one response, distinct
/// across evaluation epochs and body ordinals. Never a durable identity.
std::string TopologyEntityToken(std::uint32_t evaluationEpoch, std::uint32_t bodyOrdinal, char kind,
                                int index);

nlohmann::json DescribeTopology(const EvaluatedBody& body, std::uint32_t evaluationEpoch,
                                std::uint32_t bodyOrdinal, const std::atomic_bool& cancelled);

nlohmann::json DescribeTopology(const EvaluatedBody& body, std::uint32_t evaluationEpoch,
                                std::uint32_t bodyOrdinal, const std::atomic_bool& cancelled,
                                const ProvenanceResolver& provenance);

/// Return bounded identity evidence for one 0-based dense AEMB topology row.
/// The row is resolved through BuildTopologyIndexMaps, the same OCCT maps used
/// by tessellation, so the evidence cannot drift from the displayed pick table.
nlohmann::json DescribeTopologySelection(const EvaluatedBody& body, const std::string& kind,
                                         std::size_t entityIndex,
                                         const std::atomic_bool& cancelled);

/// Builds the {kind, geometryClass, measure, centroid, axis, radius} evidence
/// JSON for an ALREADY-RESOLVED shape of the given kind ("face"|"edge"|"vertex") —
/// the same shape topologySelectionEvidenceSchema (@aeth/geometry-contracts
/// topology.ts) requires. Extracted out of DescribeTopologySelection so a
/// caller holding a TopoDS_Shape from AQL resolution (mate_frame.cpp) never
/// needs a dense body/entityIndex pair to get identity evidence. Throws
/// std::invalid_argument if `kind` is not face/edge/vertex.
nlohmann::json DescribeTopologyEvidence(const std::string& kind, const TopoDS_Shape& shape);

} // namespace aeth
