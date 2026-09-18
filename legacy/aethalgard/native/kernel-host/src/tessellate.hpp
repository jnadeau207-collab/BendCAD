#pragma once

#include <atomic>
#include <cstdint>
#include <vector>

#include <TopoDS_Shape.hxx>
#include <nlohmann/json.hpp>

namespace aeth {

struct TessellationPacket final {
  std::vector<std::uint8_t> bytes;
  nlohmann::json descriptor;
};

TessellationPacket TessellateShape(const TopoDS_Shape& shape, std::uint32_t streamSequence,
                                   const std::atomic_bool& cancelled, std::uint32_t lodTier = 0);

/**
 * Tessellates a body for MANUFACTURING EXPORT at an ABSOLUTE deflection
 * (0.02 mm linear / 10 deg angular, LOD tier 3), independent of the body's
 * size — unlike {@link TessellateShape}, whose deflection scales with the
 * world diagonal per LOD tier. Every other step (world-AABB origin rebasing,
 * extent guard, AEMB2 descriptor assembly) is identical to
 * {@link TessellateShape}; only the tolerances and the reported LOD tier
 * differ. Used by the kernel host's `export_mesh` method so a written 3MF
 * carries a print-quality mesh of the committed revision rather than the
 * retained viewport packet.
 */
TessellationPacket TessellateShapeForExport(const TopoDS_Shape& shape, std::uint32_t streamSequence,
                                            const std::atomic_bool& cancelled);

} // namespace aeth
