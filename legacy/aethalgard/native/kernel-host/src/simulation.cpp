// Voxel hexahedral finite elements over evaluated bodies. The pipeline:
// voxelize the union of solids on a uniform grid (occupancy by column ray
// parity), resolve every boundary-condition selector through the SAME
// evaluator the `query` method uses, assemble trilinear 8-node hexahedra with
// 2x2x2 Gauss quadrature into a sparse block system, eliminate Dirichlet
// rows/columns, solve with Jacobi-preconditioned conjugate gradients, recover
// the requested scalar field, and emit the voxel skin as a renderable
// triangle mesh. Every number the caller sees is computed physics.
//
// UNIT SYSTEM — consistent N / mm / MPa throughout the static solve: lengths
// are millimetres, forces newtons, so moduli and stresses are N/mm^2 = MPa
// (Young's modulus arrives in GPa and is converted x1000) and displacements
// come out directly in millimetres. The steady-heat solve runs in W and
// degrees Celsius: conductivity arrives in W/(m*K) and is converted to
// W/(mm*K) (x1e-3), boundary flux arrives in W/m^2 and is converted to
// W/mm^2 (x1e-6), so nodal loads are watts and the temperature field needs
// no back-conversion.
#include "simulation.hpp"

#include "cancel.hpp"
#include "naming_registry.hpp"
#include "selector_evaluator.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdio>
#include <limits>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include <BRepBndLib.hxx>
#include <BRepBuilderAPI_MakeVertex.hxx>
#include <BRepExtrema_DistShapeShape.hxx>
#include <BRepIntCurveSurface_Inter.hxx>
#include <Bnd_Box.hxx>
#include <gp_Dir.hxx>
#include <gp_Lin.hxx>
#include <gp_Pnt.hxx>

namespace aeth {
namespace {

void CheckCancelled(const std::atomic_bool& cancelled) {
  if (cancelled.load(std::memory_order_relaxed)) {
    throw Cancelled();
  }
}

/// Upper bound on grid CELLS (occupied or not). The element cap alone cannot
/// bound the scan: a sliver solid inside a huge bounding box keeps the
/// occupied count small while the column scan and occupancy bitmap explode.
/// Refusing the grid itself keeps memory and scan time honest.
constexpr double kGridCellGuard = 256'000'000.0;

/// CG convergence target: relative residual |r| / |b|.
constexpr double kCgRelativeTolerance = 1e-8;

/// One typed simulation refusal: the fine SIM_* code rides the message AND
/// details.simulationCode, while the coarse `wireCode` stays inside the
/// existing kernelErrorSchema enum — the exact two-channel pattern
/// SelectorFailure established for E_SEL_* under REFERENCE_MISSING.
[[noreturn]] void ThrowSimulation(const char* simulationCode, const char* wireCode,
                                  const std::string& message, nlohmann::json details) {
  details["simulationCode"] = simulationCode;
  throw OperationFailure("", wireCode, std::string(simulationCode) + ": " + message,
                         std::move(details));
}

/// Local corner order of one voxel element whose lowest corner is grid node
/// (i,j,k): 0:(i,j,k) 1:(+x) 2:(+x+y) 3:(+y), then 4..7 the same square at
/// k+1. This matches the trilinear sign table below, so shape-function
/// gradients and connectivity never disagree.
constexpr std::int64_t kCornerOffset[8][3] = {
    {0, 0, 0}, {1, 0, 0}, {1, 1, 0}, {0, 1, 0}, {0, 0, 1}, {1, 0, 1}, {1, 1, 1}, {0, 1, 1},
};

/// Reference-cube corner signs for N_a = (1+xi*s0)(1+eta*s1)(1+zeta*s2)/8.
constexpr double kCornerSign[8][3] = {
    {-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
    {-1, -1, 1},  {1, -1, 1},  {1, 1, 1},  {-1, 1, 1},
};

/// The six voxel faces: outward step to the neighbor cell, and the four local
/// corners ordered so (c1-c0)x(c3-c0) points OUT of the element — the
/// consistent outward winding the skin mesh contract requires.
constexpr std::int64_t kFaceNeighbor[6][3] = {
    {1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1},
};
constexpr int kFaceCorners[6][4] = {
    {1, 2, 6, 5}, // +x
    {0, 4, 7, 3}, // -x
    {3, 7, 6, 2}, // +y
    {0, 1, 5, 4}, // -y
    {4, 5, 6, 7}, // +z
    {0, 3, 2, 1}, // -z
};

// --- Voxelization -----------------------------------------------------------

struct VoxelGrid final {
  double h{};
  double originX{}, originY{}, originZ{};
  std::int64_t nx{}, ny{}, nz{};
  /// Cell (i,j,k) at ((k*ny)+j)*nx + i.
  std::vector<bool> occupied;
  std::size_t occupiedCount{};

  bool Occupied(std::int64_t i, std::int64_t j, std::int64_t k) const {
    if (i < 0 || j < 0 || k < 0 || i >= nx || j >= ny || k >= nz) {
      return false;
    }
    return occupied[static_cast<std::size_t>(((k * ny) + j) * nx + i)];
  }
};

/// Voxelizes the union of `bodies` at edge length `h`: a uniform grid sized
/// to the union bounds plus at least a half-voxel margin per side, occupancy
/// decided per (x,y) column by casting a +Z line through each solid and
/// parity-filling between successive surface crossings.
///
/// Sample points are the element centers offset by +h*1e-4 on ALL three axes.
/// The offset is deterministic and puts every sample in generic position:
/// a model face that lands exactly on a grid plane (the common case — an
/// axis-aligned box whose span is a multiple of h) would otherwise put
/// centers exactly ON the surface, where both the ray cast and the in-run
/// comparison are knife-edge. The bias this introduces is one ten-thousandth
/// of a voxel, far below the h/2 discretization the grid already carries.
VoxelGrid Voxelize(const std::vector<EvaluatedBody>& bodies, double h,
                   const std::atomic_bool& cancelled) {
  Bnd_Box bounds;
  for (const EvaluatedBody& body : bodies) {
    BRepBndLib::Add(body.shape, bounds);
  }
  if (bounds.IsVoid()) {
    throw std::invalid_argument("simulation needs at least one solid body with real extent");
  }
  double xMin = 0, yMin = 0, zMin = 0, xMax = 0, yMax = 0, zMax = 0;
  bounds.Get(xMin, yMin, zMin, xMax, yMax, zMax);

  VoxelGrid grid;
  grid.h = h;
  // ceil(span/h) cells cover the span; one more guarantees the grid overhangs
  // the bounds by at least h/2 total, and centering it splits that margin
  // evenly — the half-voxel margin per side.
  const auto cellsFor = [h](double span) {
    return static_cast<std::int64_t>(std::ceil(span / h)) + 1;
  };
  grid.nx = cellsFor(xMax - xMin);
  grid.ny = cellsFor(yMax - yMin);
  grid.nz = cellsFor(zMax - zMin);
  const double cellCount =
      static_cast<double>(grid.nx) * static_cast<double>(grid.ny) * static_cast<double>(grid.nz);
  if (cellCount > kGridCellGuard) {
    char formatted[160];
    std::snprintf(formatted, sizeof(formatted),
                  "a %g mm voxel grid over this model spans %.0f cells, beyond what the "
                  "simulator will scan for its %zu-element cap; coarsen resolutionMm",
                  h, cellCount, kSimulationElementCap);
    ThrowSimulation("SIM_RESOLUTION", "INVALID_REQUEST", formatted,
                    {{"elementCap", kSimulationElementCap}, {"gridCellCount", cellCount}});
  }
  grid.originX = 0.5 * (xMin + xMax) - 0.5 * static_cast<double>(grid.nx) * h;
  grid.originY = 0.5 * (yMin + yMax) - 0.5 * static_cast<double>(grid.ny) * h;
  grid.originZ = 0.5 * (zMin + zMax) - 0.5 * static_cast<double>(grid.nz) * h;
  grid.occupied.assign(static_cast<std::size_t>(grid.nx * grid.ny * grid.nz), false);

  const double offset = h * 1e-4;
  const double weld = h * 1e-6;
  std::vector<double> crossings;
  for (std::int64_t j = 0; j < grid.ny; ++j) {
    for (std::int64_t i = 0; i < grid.nx; ++i) {
      CheckCancelled(cancelled);
      const double cx = grid.originX + (static_cast<double>(i) + 0.5) * h + offset;
      const double cy = grid.originY + (static_cast<double>(j) + 0.5) * h + offset;
      // Parity is per SOLID: overlapping bodies OR their fills, which a merged
      // crossing list would get wrong wherever two solids interpenetrate.
      for (const EvaluatedBody& body : bodies) {
        crossings.clear();
        BRepIntCurveSurface_Inter intersector;
        intersector.Init(body.shape, gp_Lin(gp_Pnt(cx, cy, 0.0), gp_Dir(0, 0, 1)), 1e-7);
        for (; intersector.More(); intersector.Next()) {
          // The line parameter IS z: the line starts at z=0 with direction +Z.
          crossings.push_back(intersector.W());
        }
        std::sort(crossings.begin(), crossings.end());
        // Weld near-coincident crossings (a ray grazing an edge reports the
        // shared boundary once per face). An odd residue means the ray is
        // still tangent somewhere despite the generic-position offset; the
        // column is conservatively left empty rather than parity-filled from
        // a broken crossing list.
        std::size_t kept = 0;
        for (std::size_t c = 0; c < crossings.size(); ++c) {
          if (kept == 0 || crossings[c] - crossings[kept - 1] > weld) {
            crossings[kept++] = crossings[c];
          }
        }
        if (kept % 2 != 0) {
          continue;
        }
        for (std::size_t run = 0; run + 1 < kept; run += 2) {
          const double enter = crossings[run];
          const double exit = crossings[run + 1];
          for (std::int64_t k = 0; k < grid.nz; ++k) {
            const double cz = grid.originZ + (static_cast<double>(k) + 0.5) * h + offset;
            if (cz < enter || cz >= exit) {
              continue;
            }
            const std::size_t cell = static_cast<std::size_t>(((k * grid.ny) + j) * grid.nx + i);
            if (!grid.occupied[cell]) {
              grid.occupied[cell] = true;
              grid.occupiedCount += 1;
              if (grid.occupiedCount > kSimulationElementCap) {
                ThrowSimulation(
                    "SIM_RESOLUTION", "INVALID_REQUEST",
                    "voxelizing at " + std::to_string(h) + " mm passed " +
                        std::to_string(grid.occupiedCount) + " occupied elements, above the " +
                        std::to_string(kSimulationElementCap) +
                        "-element cap; coarsen resolutionMm",
                    {{"elementCap", kSimulationElementCap}, {"elementCount", grid.occupiedCount}});
              }
            }
          }
        }
      }
    }
  }
  return grid;
}

// --- Mesh bookkeeping -------------------------------------------------------

struct FemModel final {
  /// Sorted grid-node keys ((k*(ny+1)+j)*(nx+1)+i); index IS the compact node
  /// id, so node numbering is lexicographic and replay-deterministic.
  std::vector<std::int64_t> nodeKeys;
  std::unordered_map<std::int64_t, std::int32_t> nodeIdOf;
  /// Per element: the 8 compact node ids in kCornerOffset order.
  std::vector<std::array<std::int32_t, 8>> elementNodes;
  /// Per element: its (i,j,k) cell, for skin-face neighbor tests.
  std::vector<std::array<std::int64_t, 3>> elementCells;
  /// Boundary quads: (element index, face 0..5) where the face neighbor cell
  /// is empty or outside the grid.
  std::vector<std::pair<std::int32_t, int>> skinQuads;
  std::vector<bool> nodeOnSkin;
};

gp_Pnt NodePosition(const VoxelGrid& grid, std::int64_t key) {
  const std::int64_t nodesX = grid.nx + 1;
  const std::int64_t nodesY = grid.ny + 1;
  const std::int64_t i = key % nodesX;
  const std::int64_t j = (key / nodesX) % nodesY;
  const std::int64_t k = key / (nodesX * nodesY);
  return gp_Pnt(grid.originX + static_cast<double>(i) * grid.h,
                grid.originY + static_cast<double>(j) * grid.h,
                grid.originZ + static_cast<double>(k) * grid.h);
}

FemModel BuildModel(const VoxelGrid& grid, const std::atomic_bool& cancelled) {
  FemModel model;
  const std::int64_t nodesX = grid.nx + 1;
  const std::int64_t nodesY = grid.ny + 1;
  const auto nodeKey = [nodesX, nodesY](std::int64_t i, std::int64_t j, std::int64_t k) {
    return (k * nodesY + j) * nodesX + i;
  };

  // Elements in ascending cell order (k, then j, then i) — the fixed
  // traversal every later loop inherits, which is what makes two runs of the
  // same study byte-identical.
  model.elementCells.reserve(grid.occupiedCount);
  for (std::int64_t k = 0; k < grid.nz; ++k) {
    for (std::int64_t j = 0; j < grid.ny; ++j) {
      for (std::int64_t i = 0; i < grid.nx; ++i) {
        if (grid.Occupied(i, j, k)) {
          model.elementCells.push_back({i, j, k});
        }
      }
    }
  }

  std::vector<std::int64_t> keys;
  keys.reserve(model.elementCells.size() * 8);
  for (const std::array<std::int64_t, 3>& cell : model.elementCells) {
    for (const std::int64_t (&corner)[3] : kCornerOffset) {
      keys.push_back(nodeKey(cell[0] + corner[0], cell[1] + corner[1], cell[2] + corner[2]));
    }
  }
  std::sort(keys.begin(), keys.end());
  keys.erase(std::unique(keys.begin(), keys.end()), keys.end());
  model.nodeKeys = std::move(keys);
  model.nodeIdOf.reserve(model.nodeKeys.size());
  for (std::size_t index = 0; index < model.nodeKeys.size(); ++index) {
    model.nodeIdOf.emplace(model.nodeKeys[index], static_cast<std::int32_t>(index));
  }

  model.elementNodes.reserve(model.elementCells.size());
  model.nodeOnSkin.assign(model.nodeKeys.size(), false);
  for (std::size_t element = 0; element < model.elementCells.size(); ++element) {
    CheckCancelled(cancelled);
    const std::array<std::int64_t, 3>& cell = model.elementCells[element];
    std::array<std::int32_t, 8> nodes{};
    for (int corner = 0; corner < 8; ++corner) {
      nodes[static_cast<std::size_t>(corner)] = model.nodeIdOf.at(
          nodeKey(cell[0] + kCornerOffset[corner][0], cell[1] + kCornerOffset[corner][1],
                  cell[2] + kCornerOffset[corner][2]));
    }
    model.elementNodes.push_back(nodes);
    for (int face = 0; face < 6; ++face) {
      if (grid.Occupied(cell[0] + kFaceNeighbor[face][0], cell[1] + kFaceNeighbor[face][1],
                        cell[2] + kFaceNeighbor[face][2])) {
        continue;
      }
      model.skinQuads.emplace_back(static_cast<std::int32_t>(element), face);
      for (int corner = 0; corner < 4; ++corner) {
        model.nodeOnSkin[static_cast<std::size_t>(
            nodes[static_cast<std::size_t>(kFaceCorners[face][corner])])] = true;
      }
    }
  }
  return model;
}

// --- Boundary-condition resolution ------------------------------------------

/// Resolves one constraint/load ast through the query evaluator and matches
/// the voxel-skin nodes that realize it: a skin node carries the condition
/// when its distance to any resolved entity is at most 0.9 x resolution.
/// Cost is bounded by testing only skin nodes inside the entity's bounding
/// box inflated by one voxel. Zero resolved entities is SIM_BC_UNRESOLVED
/// naming the id. An EMPTY match over resolved entities is returned, not
/// refused: for constraints the aggregate SIM_UNCONSTRAINED guard owns that
/// outcome, while the load path refuses it at its call site — a load that
/// binds nothing must not silently vanish from the answer.
std::vector<std::int32_t> MatchBoundaryNodes(const nlohmann::json& ast, const std::string& id,
                                             const std::vector<EvaluatedBody>& bodies,
                                             const NamingRegistry& registry, const FemModel& model,
                                             const VoxelGrid& grid,
                                             const std::atomic_bool& cancelled) {
  const QueryOutcome outcome = EvaluateQuery(ast, bodies, registry, cancelled);
  if (outcome.entities.empty()) {
    ThrowSimulation("SIM_BC_UNRESOLVED", "REFERENCE_MISSING",
                    "boundary condition \"" + id + "\" resolves to zero faces", {{"id", id}});
  }
  const double tolerance = 0.9 * grid.h;
  std::vector<Bnd_Box> entityBounds;
  entityBounds.reserve(outcome.entities.size());
  for (const QueryEntity& entity : outcome.entities) {
    Bnd_Box box;
    BRepBndLib::Add(entity.shape, box);
    box.Enlarge(grid.h);
    entityBounds.push_back(box);
  }

  std::vector<std::int32_t> matched;
  for (std::size_t node = 0; node < model.nodeKeys.size(); ++node) {
    if (!model.nodeOnSkin[node]) {
      continue;
    }
    if (node % 4096 == 0) {
      CheckCancelled(cancelled);
    }
    const gp_Pnt position = NodePosition(grid, model.nodeKeys[node]);
    for (std::size_t entity = 0; entity < outcome.entities.size(); ++entity) {
      if (entityBounds[entity].IsOut(position)) {
        continue;
      }
      BRepExtrema_DistShapeShape distance(BRepBuilderAPI_MakeVertex(position).Vertex(),
                                          outcome.entities[entity].shape);
      if (distance.IsDone() && distance.Value() <= tolerance) {
        matched.push_back(static_cast<std::int32_t>(node));
        break;
      }
    }
  }
  return matched;
}

// --- Element matrices (all elements are identical h-cubes: compute once) ----

/// Shape-function gradients (d/dx, d/dy, d/dz) of the 8 trilinear functions
/// at reference point (xi, eta, zeta). The Jacobian of an axis-aligned h-cube
/// is diag(h/2), so d/dx = (2/h) d/dxi.
std::array<std::array<double, 3>, 8> ShapeGradients(double xi, double eta, double zeta, double h) {
  std::array<std::array<double, 3>, 8> gradients{};
  const double scale = 2.0 / h / 8.0;
  for (int a = 0; a < 8; ++a) {
    const double sx = kCornerSign[a][0];
    const double sy = kCornerSign[a][1];
    const double sz = kCornerSign[a][2];
    gradients[static_cast<std::size_t>(a)] = {
        scale * sx * (1.0 + eta * sy) * (1.0 + zeta * sz),
        scale * sy * (1.0 + xi * sx) * (1.0 + zeta * sz),
        scale * sz * (1.0 + xi * sx) * (1.0 + eta * sy),
    };
  }
  return gradients;
}

/// 24x24 elastic stiffness of one h-cube, 2x2x2 Gauss. The isotropic triple
/// product B^T D B collapses to the classical nodal-block form
///   K_ab[r][c] = integral( lambda*ga[r]*gb[c] + mu*ga[c]*gb[r]
///                          + mu*(ga.gb)*delta_rc )
/// which is what is accumulated here — same matrix, no 6x24 B scaffolding.
std::vector<double> ElasticElementMatrix(double h, double lambda, double mu) {
  constexpr int kSize = 24;
  std::vector<double> ke(static_cast<std::size_t>(kSize) * kSize, 0.0);
  const double gauss = 1.0 / std::sqrt(3.0);
  const double weightDetJ = (h * h * h) / 8.0;
  for (const double (&point)[3] : kCornerSign) {
    const std::array<std::array<double, 3>, 8> g =
        ShapeGradients(point[0] * gauss, point[1] * gauss, point[2] * gauss, h);
    for (int a = 0; a < 8; ++a) {
      for (int b = 0; b < 8; ++b) {
        const std::array<double, 3>& ga = g[static_cast<std::size_t>(a)];
        const std::array<double, 3>& gb = g[static_cast<std::size_t>(b)];
        const double dot = ga[0] * gb[0] + ga[1] * gb[1] + ga[2] * gb[2];
        for (int r = 0; r < 3; ++r) {
          for (int c = 0; c < 3; ++c) {
            double value =
                lambda * ga[static_cast<std::size_t>(r)] * gb[static_cast<std::size_t>(c)] +
                mu * ga[static_cast<std::size_t>(c)] * gb[static_cast<std::size_t>(r)];
            if (r == c) {
              value += mu * dot;
            }
            ke[static_cast<std::size_t>((a * 3 + r) * kSize + (b * 3 + c))] += weightDetJ * value;
          }
        }
      }
    }
  }
  return ke;
}

/// 8x8 conductivity (Laplacian) matrix of one h-cube, 2x2x2 Gauss:
/// K_ab = integral( k * ga.gb ).
std::vector<double> HeatElementMatrix(double h, double conductivity) {
  std::vector<double> ke(64, 0.0);
  const double gauss = 1.0 / std::sqrt(3.0);
  const double weightDetJ = (h * h * h) / 8.0;
  for (const double (&point)[3] : kCornerSign) {
    const std::array<std::array<double, 3>, 8> g =
        ShapeGradients(point[0] * gauss, point[1] * gauss, point[2] * gauss, h);
    for (int a = 0; a < 8; ++a) {
      for (int b = 0; b < 8; ++b) {
        const std::array<double, 3>& ga = g[static_cast<std::size_t>(a)];
        const std::array<double, 3>& gb = g[static_cast<std::size_t>(b)];
        ke[static_cast<std::size_t>(a * 8 + b)] +=
            weightDetJ * conductivity * (ga[0] * gb[0] + ga[1] * gb[1] + ga[2] * gb[2]);
      }
    }
  }
  return ke;
}

// --- Sparse system ----------------------------------------------------------

/// Node-block CSR: per node row, the sorted neighbor-node columns, each entry
/// a dof x dof dense block. dof is 3 (elasticity) or 1 (conduction).
struct SparseBlocks final {
  int dof{};
  std::vector<std::size_t> rowPtr;
  std::vector<std::int32_t> columns;
  std::vector<double> values;

  std::size_t EntryOf(std::int32_t row, std::int32_t column) const {
    const auto begin =
        columns.begin() + static_cast<std::ptrdiff_t>(rowPtr[static_cast<std::size_t>(row)]);
    const auto end =
        columns.begin() + static_cast<std::ptrdiff_t>(rowPtr[static_cast<std::size_t>(row) + 1]);
    const auto found = std::lower_bound(begin, end, column);
    return static_cast<std::size_t>(found - columns.begin());
  }
};

SparseBlocks AssembleSystem(const FemModel& model, const std::vector<double>& elementMatrix,
                            int dof, const std::atomic_bool& cancelled) {
  const std::size_t nodeCount = model.nodeKeys.size();
  std::vector<std::vector<std::int32_t>> adjacency(nodeCount);
  for (const std::array<std::int32_t, 8>& nodes : model.elementNodes) {
    for (const std::int32_t row : nodes) {
      std::vector<std::int32_t>& list = adjacency[static_cast<std::size_t>(row)];
      list.insert(list.end(), nodes.begin(), nodes.end());
    }
  }

  SparseBlocks system;
  system.dof = dof;
  system.rowPtr.assign(nodeCount + 1, 0);
  for (std::size_t node = 0; node < nodeCount; ++node) {
    std::vector<std::int32_t>& list = adjacency[node];
    std::sort(list.begin(), list.end());
    list.erase(std::unique(list.begin(), list.end()), list.end());
    system.rowPtr[node + 1] = system.rowPtr[node] + list.size();
  }
  system.columns.reserve(system.rowPtr[nodeCount]);
  for (std::size_t node = 0; node < nodeCount; ++node) {
    system.columns.insert(system.columns.end(), adjacency[node].begin(), adjacency[node].end());
    adjacency[node].clear();
    adjacency[node].shrink_to_fit();
  }
  const std::size_t blockSize = static_cast<std::size_t>(dof) * static_cast<std::size_t>(dof);
  system.values.assign(system.rowPtr[nodeCount] * blockSize, 0.0);

  const int elementSize = 8 * dof;
  for (std::size_t element = 0; element < model.elementNodes.size(); ++element) {
    if (element % 1024 == 0) {
      CheckCancelled(cancelled);
    }
    const std::array<std::int32_t, 8>& nodes = model.elementNodes[element];
    for (int a = 0; a < 8; ++a) {
      const std::int32_t row = nodes[static_cast<std::size_t>(a)];
      for (int b = 0; b < 8; ++b) {
        const std::size_t entry = system.EntryOf(row, nodes[static_cast<std::size_t>(b)]);
        double* block = &system.values[entry * blockSize];
        for (int r = 0; r < dof; ++r) {
          for (int c = 0; c < dof; ++c) {
            block[r * dof + c] += elementMatrix[static_cast<std::size_t>(
                (a * dof + r) * elementSize + (b * dof + c))];
          }
        }
      }
    }
  }
  return system;
}

/// y = A x over every row (no masking — callers mask afterwards).
void Multiply(const SparseBlocks& system, const std::vector<double>& x, std::vector<double>& y) {
  const int dof = system.dof;
  const std::size_t blockSize = static_cast<std::size_t>(dof) * static_cast<std::size_t>(dof);
  const std::size_t nodeCount = system.rowPtr.size() - 1;
  std::fill(y.begin(), y.end(), 0.0);
  for (std::size_t row = 0; row < nodeCount; ++row) {
    for (std::size_t entry = system.rowPtr[row]; entry < system.rowPtr[row + 1]; ++entry) {
      const std::size_t column = static_cast<std::size_t>(system.columns[entry]);
      const double* block = &system.values[entry * blockSize];
      for (int r = 0; r < dof; ++r) {
        double sum = 0.0;
        for (int c = 0; c < dof; ++c) {
          sum += block[r * dof + c] *
                 x[column * static_cast<std::size_t>(dof) + static_cast<std::size_t>(c)];
        }
        y[row * static_cast<std::size_t>(dof) + static_cast<std::size_t>(r)] += sum;
      }
    }
  }
}

struct CgOutcome final {
  std::size_t iterations{};
  double relativeResidual{};
  bool converged{};
};

/// Jacobi-preconditioned conjugate gradients on the Dirichlet-eliminated
/// system: `fixedDof` rows/columns are excluded by keeping those entries of
/// every CG vector at zero and zeroing them after each matvec — algebraically
/// identical to deleting the rows and columns, with no penalty numbers
/// anywhere. `b` must already be masked; the caller adds prescribed values
/// back afterwards.
CgOutcome SolveConjugateGradient(const SparseBlocks& system, const std::vector<bool>& fixedDof,
                                 const std::vector<double>& b, std::vector<double>& x,
                                 const std::atomic_bool& cancelled) {
  const std::size_t size = b.size();
  const std::size_t blockSize =
      static_cast<std::size_t>(system.dof) * static_cast<std::size_t>(system.dof);
  x.assign(size, 0.0);

  std::vector<double> diagonal(size, 1.0);
  const std::size_t nodeCount = system.rowPtr.size() - 1;
  for (std::size_t row = 0; row < nodeCount; ++row) {
    const std::size_t entry =
        system.EntryOf(static_cast<std::int32_t>(row), static_cast<std::int32_t>(row));
    const double* block = &system.values[entry * blockSize];
    for (int d = 0; d < system.dof; ++d) {
      const double value = block[d * system.dof + d];
      if (value > 0.0) {
        diagonal[row * static_cast<std::size_t>(system.dof) + static_cast<std::size_t>(d)] = value;
      }
    }
  }

  const auto dot = [](const std::vector<double>& u, const std::vector<double>& v) {
    double sum = 0.0;
    for (std::size_t index = 0; index < u.size(); ++index) {
      sum += u[index] * v[index];
    }
    return sum;
  };
  const auto mask = [&fixedDof](std::vector<double>& v) {
    for (std::size_t index = 0; index < v.size(); ++index) {
      if (fixedDof[index]) {
        v[index] = 0.0;
      }
    }
  };

  const double bNorm = std::sqrt(dot(b, b));
  if (bNorm == 0.0) {
    return {0, 0.0, true};
  }

  std::vector<double> r = b;
  std::vector<double> z(size, 0.0);
  for (std::size_t index = 0; index < size; ++index) {
    z[index] = r[index] / diagonal[index];
  }
  mask(z);
  std::vector<double> p = z;
  std::vector<double> q(size, 0.0);
  double rz = dot(r, z);

  for (std::size_t iteration = 1; iteration <= kSimulationCgMaxIterations; ++iteration) {
    CheckCancelled(cancelled);
    Multiply(system, p, q);
    mask(q);
    const double pq = dot(p, q);
    if (pq <= 0.0) {
      // A non-positive curvature direction on an SPD operator means the
      // residual has hit rounding noise; report the honest residual.
      return {iteration, std::sqrt(dot(r, r)) / bNorm,
              std::sqrt(dot(r, r)) / bNorm <= kCgRelativeTolerance};
    }
    const double alpha = rz / pq;
    for (std::size_t index = 0; index < size; ++index) {
      x[index] += alpha * p[index];
      r[index] -= alpha * q[index];
    }
    const double residual = std::sqrt(dot(r, r)) / bNorm;
    if (residual <= kCgRelativeTolerance) {
      return {iteration, residual, true};
    }
    for (std::size_t index = 0; index < size; ++index) {
      z[index] = r[index] / diagonal[index];
    }
    mask(z);
    const double rzNext = dot(r, z);
    const double beta = rzNext / rz;
    rz = rzNext;
    for (std::size_t index = 0; index < size; ++index) {
      p[index] = z[index] + beta * p[index];
    }
  }
  return {kSimulationCgMaxIterations, 0.0, false};
}

// --- Recovery and skin emission ---------------------------------------------

/// Per-node von Mises stress: centroid strain B.u per element (the gradients
/// are constant at the centroid), stress through the isotropic law, then each
/// node averages the values of its adjacent elements.
std::vector<double> RecoverVonMises(const FemModel& model, const std::vector<double>& u, double h,
                                    double lambda, double mu) {
  std::vector<double> nodal(model.nodeKeys.size(), 0.0);
  std::vector<std::int32_t> adjacent(model.nodeKeys.size(), 0);
  // Centroid gradient of shape a along axis d is sign/(4h): (2/h) * s/8.
  for (const std::array<std::int32_t, 8>& nodes : model.elementNodes) {
    double strain[6] = {0, 0, 0, 0, 0, 0}; // xx yy zz xy yz zx (engineering)
    for (int a = 0; a < 8; ++a) {
      const std::size_t base = static_cast<std::size_t>(nodes[static_cast<std::size_t>(a)]) * 3;
      const double gx = kCornerSign[a][0] / (4.0 * h);
      const double gy = kCornerSign[a][1] / (4.0 * h);
      const double gz = kCornerSign[a][2] / (4.0 * h);
      strain[0] += gx * u[base + 0];
      strain[1] += gy * u[base + 1];
      strain[2] += gz * u[base + 2];
      strain[3] += gy * u[base + 0] + gx * u[base + 1];
      strain[4] += gz * u[base + 1] + gy * u[base + 2];
      strain[5] += gx * u[base + 2] + gz * u[base + 0];
    }
    const double trace = strain[0] + strain[1] + strain[2];
    const double sx = lambda * trace + 2.0 * mu * strain[0];
    const double sy = lambda * trace + 2.0 * mu * strain[1];
    const double sz = lambda * trace + 2.0 * mu * strain[2];
    const double txy = mu * strain[3];
    const double tyz = mu * strain[4];
    const double tzx = mu * strain[5];
    const double vonMises =
        std::sqrt(0.5 * ((sx - sy) * (sx - sy) + (sy - sz) * (sy - sz) + (sz - sx) * (sz - sx)) +
                  3.0 * (txy * txy + tyz * tyz + tzx * tzx));
    for (const std::int32_t node : nodes) {
      nodal[static_cast<std::size_t>(node)] += vonMises;
      adjacent[static_cast<std::size_t>(node)] += 1;
    }
  }
  for (std::size_t node = 0; node < nodal.size(); ++node) {
    if (adjacent[node] > 0) {
      nodal[node] /= static_cast<double>(adjacent[node]);
    }
  }
  return nodal;
}

/// Emits the voxel skin: vertices are the skin nodes in ascending node order
/// (deduplicated by construction), each boundary quad becomes two triangles
/// with the outward winding kFaceCorners fixed, and each vertex carries its
/// nodal scalar.
SimulationMesh EmitSkin(const FemModel& model, const VoxelGrid& grid,
                        const std::vector<double>& nodalScalar) {
  SimulationMesh mesh;
  std::vector<std::uint32_t> vertexOf(model.nodeKeys.size(),
                                      std::numeric_limits<std::uint32_t>::max());
  std::uint32_t vertexCount = 0;
  for (std::size_t node = 0; node < model.nodeKeys.size(); ++node) {
    if (model.nodeOnSkin[node]) {
      vertexOf[node] = vertexCount++;
    }
  }
  mesh.positions.reserve(static_cast<std::size_t>(vertexCount) * 3);
  mesh.scalars.reserve(vertexCount);
  for (std::size_t node = 0; node < model.nodeKeys.size(); ++node) {
    if (!model.nodeOnSkin[node]) {
      continue;
    }
    const gp_Pnt position = NodePosition(grid, model.nodeKeys[node]);
    mesh.positions.push_back(position.X());
    mesh.positions.push_back(position.Y());
    mesh.positions.push_back(position.Z());
    mesh.scalars.push_back(nodalScalar[node]);
  }
  mesh.triangles.reserve(model.skinQuads.size() * 6);
  for (const std::pair<std::int32_t, int>& quad : model.skinQuads) {
    const std::array<std::int32_t, 8>& nodes =
        model.elementNodes[static_cast<std::size_t>(quad.first)];
    std::uint32_t corners[4];
    for (int corner = 0; corner < 4; ++corner) {
      corners[corner] = vertexOf[static_cast<std::size_t>(
          nodes[static_cast<std::size_t>(kFaceCorners[quad.second][corner])])];
    }
    mesh.triangles.push_back(corners[0]);
    mesh.triangles.push_back(corners[1]);
    mesh.triangles.push_back(corners[2]);
    mesh.triangles.push_back(corners[0]);
    mesh.triangles.push_back(corners[2]);
    mesh.triangles.push_back(corners[3]);
  }
  return mesh;
}

} // namespace

SimulationResult SimulateStudy(const std::vector<EvaluatedBody>& bodies,
                               const NamingRegistry& registry, const SimulationStudy& study,
                               const std::atomic_bool& cancelled) {
  const bool isStatic = study.kind == "static-stress";
  if (!isStatic && study.kind != "steady-heat") {
    throw std::invalid_argument("simulation study kind must be static-stress or steady-heat");
  }
  if (!(study.resolutionMm > 0.0) || !std::isfinite(study.resolutionMm)) {
    throw std::invalid_argument("simulation resolutionMm must be a positive finite number");
  }
  const double nu = study.material.poissonsRatio;
  if (!(nu > -1.0) || !(nu < 0.5)) {
    throw std::invalid_argument("simulation poissonsRatio must lie inside (-1, 0.5)");
  }
  if (bodies.empty()) {
    throw std::invalid_argument("simulation needs at least one evaluated body");
  }

  const double h = study.resolutionMm;
  const VoxelGrid grid = Voxelize(bodies, h, cancelled);
  if (grid.occupiedCount == 0) {
    throw std::invalid_argument(
        "no voxel element center falls inside the bodies at this resolution; refine resolutionMm");
  }
  const FemModel model = BuildModel(grid, cancelled);
  const std::size_t nodeCount = model.nodeKeys.size();
  const int dof = isStatic ? 3 : 1;
  const std::size_t size = nodeCount * static_cast<std::size_t>(dof);

  // Dirichlet bookkeeping. For "temperature" a node hit by several
  // constraints keeps the FIRST prescription in constraint order — a
  // deterministic rule for the shared corner nodes of two adjoining faces.
  std::vector<bool> fixedDof(size, false);
  std::vector<double> prescribed(size, 0.0);
  for (const SimulationConstraint& constraint : study.constraints) {
    CheckCancelled(cancelled);
    const std::vector<std::int32_t> matched =
        MatchBoundaryNodes(constraint.ast, constraint.id, bodies, registry, model, grid, cancelled);
    for (const std::int32_t node : matched) {
      if (isStatic) {
        const std::size_t base = static_cast<std::size_t>(node) * 3;
        fixedDof[base + 0] = true;
        fixedDof[base + 1] = true;
        fixedDof[base + 2] = true;
      } else {
        const std::size_t index = static_cast<std::size_t>(node);
        if (!fixedDof[index]) {
          fixedDof[index] = true;
          prescribed[index] = constraint.valueC;
        }
      }
    }
  }
  bool anyClamped = false;
  for (std::size_t index = 0; index < size && !anyClamped; ++index) {
    anyClamped = fixedDof[index];
  }
  if (!anyClamped) {
    ThrowSimulation("SIM_UNCONSTRAINED", "INVALID_REQUEST",
                    "no constraint clamps any mesh node, so the system is singular; add a fixed "
                    "or temperature constraint that touches the model",
                    nlohmann::json::object());
  }

  // Loads. "force": the TOTAL vector split EQUALLY over the matched skin
  // nodes — a deliberate simplification (no tributary-area weighting); by
  // Saint-Venant the far field is unaffected, only the one-element boundary
  // layer differs. "heat-flux": flux x matched skin quad area (quads whose
  // four corners all matched), converted W/m^2 -> W, split equally the same
  // way.
  std::vector<double> loadVector(size, 0.0);
  for (const SimulationLoad& load : study.loads) {
    CheckCancelled(cancelled);
    const std::vector<std::int32_t> matched =
        MatchBoundaryNodes(load.ast, load.id, bodies, registry, model, grid, cancelled);
    if (matched.empty()) {
      ThrowSimulation("SIM_BC_UNRESOLVED", "REFERENCE_MISSING",
                      "load \"" + load.id +
                          "\" resolves to faces but matches no mesh node at this resolution",
                      {{"id", load.id}});
    }
    const double share = 1.0 / static_cast<double>(matched.size());
    if (isStatic) {
      for (const std::int32_t node : matched) {
        const std::size_t base = static_cast<std::size_t>(node) * 3;
        loadVector[base + 0] += load.vectorN[0] * share;
        loadVector[base + 1] += load.vectorN[1] * share;
        loadVector[base + 2] += load.vectorN[2] * share;
      }
    } else {
      std::vector<bool> isMatched(nodeCount, false);
      for (const std::int32_t node : matched) {
        isMatched[static_cast<std::size_t>(node)] = true;
      }
      std::size_t matchedQuads = 0;
      for (const std::pair<std::int32_t, int>& quad : model.skinQuads) {
        const std::array<std::int32_t, 8>& nodes =
            model.elementNodes[static_cast<std::size_t>(quad.first)];
        bool allMatched = true;
        for (int corner = 0; corner < 4; ++corner) {
          allMatched = allMatched &&
                       isMatched[static_cast<std::size_t>(
                           nodes[static_cast<std::size_t>(kFaceCorners[quad.second][corner])])];
        }
        if (allMatched) {
          matchedQuads += 1;
        }
      }
      const double areaMm2 = static_cast<double>(matchedQuads) * h * h;
      const double watts = load.wattsPerM2 * areaMm2 * 1e-6;
      for (const std::int32_t node : matched) {
        loadVector[static_cast<std::size_t>(node)] += watts * share;
      }
    }
  }

  // Assemble. Units: E GPa -> MPa keeps N/mm/MPa consistent; conductivity
  // W/(m*K) -> W/(mm*K) keeps W/Celsius consistent.
  std::vector<double> elementMatrix;
  double lambda = 0.0;
  double mu = 0.0;
  if (isStatic) {
    const double youngsMPa = study.material.youngsModulusGPa * 1000.0;
    lambda = youngsMPa * nu / ((1.0 + nu) * (1.0 - 2.0 * nu));
    mu = youngsMPa / (2.0 * (1.0 + nu));
    elementMatrix = ElasticElementMatrix(h, lambda, mu);
  } else {
    elementMatrix = HeatElementMatrix(h, study.material.thermalConductivityWPerMK * 1e-3);
  }
  const SparseBlocks system = AssembleSystem(model, elementMatrix, dof, cancelled);

  // Dirichlet elimination: b = f - A*prescribed on the free rows, fixed rows
  // zeroed; the solve runs on the free block only and the prescribed values
  // are added back into the full field afterwards.
  std::vector<double> rhs(size, 0.0);
  Multiply(system, prescribed, rhs);
  for (std::size_t index = 0; index < size; ++index) {
    rhs[index] = fixedDof[index] ? 0.0 : loadVector[index] - rhs[index];
  }
  std::vector<double> solution;
  const CgOutcome outcome = SolveConjugateGradient(system, fixedDof, rhs, solution, cancelled);
  if (!outcome.converged) {
    char formatted[128];
    std::snprintf(formatted, sizeof(formatted),
                  "conjugate gradients hit the %zu-iteration cap at relative residual %.3e",
                  kSimulationCgMaxIterations, outcome.relativeResidual);
    ThrowSimulation("SIM_DID_NOT_CONVERGE", "GEOMETRY_FAILED", formatted,
                    {{"iterations", kSimulationCgMaxIterations},
                     {"relativeResidual", outcome.relativeResidual}});
  }
  for (std::size_t index = 0; index < size; ++index) {
    solution[index] += prescribed[index];
  }

  // Recovery: static-stress reports nodal von Mises (element centroid values
  // averaged onto nodes) plus the maximum displacement magnitude; steady-heat
  // reports the nodal temperature field directly.
  SimulationResult result;
  result.kind = study.kind;
  result.elementCount = grid.occupiedCount;
  result.nodeCount = nodeCount;
  result.iterations = outcome.iterations;
  std::vector<double> nodalScalar;
  if (isStatic) {
    nodalScalar = RecoverVonMises(model, solution, h, lambda, mu);
    result.scalarName = "vonMisesMPa";
    double maxSquared = 0.0;
    for (std::size_t node = 0; node < nodeCount; ++node) {
      const std::size_t base = node * 3;
      const double squared = solution[base + 0] * solution[base + 0] +
                             solution[base + 1] * solution[base + 1] +
                             solution[base + 2] * solution[base + 2];
      maxSquared = std::max(maxSquared, squared);
    }
    result.displacementMaxMm = std::sqrt(maxSquared);
  } else {
    nodalScalar = solution;
    result.scalarName = "temperatureC";
  }

  result.mesh = EmitSkin(model, grid, nodalScalar);
  double scalarMin = std::numeric_limits<double>::infinity();
  double scalarMax = -std::numeric_limits<double>::infinity();
  for (const double value : result.mesh.scalars) {
    scalarMin = std::min(scalarMin, value);
    scalarMax = std::max(scalarMax, value);
  }
  if (result.mesh.scalars.empty()) {
    scalarMin = scalarMax = 0.0;
  }
  result.scalarMin = scalarMin;
  result.scalarMax = scalarMax;
  return result;
}

} // namespace aeth
