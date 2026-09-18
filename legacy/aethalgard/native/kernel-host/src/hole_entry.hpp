#pragma once

#include <TopoDS_Shape.hxx>
#include <gp_Ax2.hxx>

namespace aeth {

/**
 * Validates that a hole placement is a legal drilling ENTRY: the frame origin
 * lies on `target`'s boundary, with solid material immediately AHEAD along the
 * frame direction and empty space immediately BEHIND. Fail closed — throws
 * `std::invalid_argument` for an origin off the surface, inside the solid, or on
 * the surface but drilling outward.
 *
 * Scale-independent by construction: the drilling axis is intersected with the
 * body to find the real boundary crossings, the ON-acceptance band is the
 * tolerance of the SPECIFIC entry face (never the widest face anywhere on the
 * body), and the ahead/behind probes are sized to the local wall found between
 * crossings — never to the body's overall bounding box.
 */
void ClassifyHoleEntry(const TopoDS_Shape& target, const gp_Ax2& frame);

} // namespace aeth
