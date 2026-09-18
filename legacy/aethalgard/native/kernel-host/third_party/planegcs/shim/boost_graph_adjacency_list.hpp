#pragma once
#ifndef AETH_SPIKE_BOOST_GRAPH_SHIM
#define AETH_SPIKE_BOOST_GRAPH_SHIM
#include <numeric>
#include <vector>

namespace boost {

struct vecS {};
struct undirectedS {};

template <typename A = vecS, typename B = vecS, typename C = undirectedS> class adjacency_list {
public:
  std::vector<std::size_t> parent;

  std::size_t find(std::size_t x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]];
      x = parent[x];
    }
    return x;
  }
};

template <typename G> std::size_t add_vertex(G& g) {
  g.parent.push_back(g.parent.size());
  return g.parent.size() - 1;
}

template <typename G> void add_edge(std::size_t a, std::size_t b, G& g) {
  const std::size_t need = (a > b ? a : b) + 1;
  while (g.parent.size() < need)
    add_vertex(g);
  const std::size_t ra = g.find(a);
  const std::size_t rb = g.find(b);
  if (ra != rb)
    g.parent[ra] = rb;
}

template <typename G> std::size_t num_vertices(const G& g) { return g.parent.size(); }

/// Writes a dense 0..k-1 component label per vertex and returns the count,
/// matching boost::connected_components' contract.
template <typename G, typename OutIt> std::size_t connected_components(G& g, OutIt out) {
  const std::size_t n = g.parent.size();
  std::vector<std::size_t> label(n, static_cast<std::size_t>(-1));
  std::size_t next = 0;
  for (std::size_t i = 0; i < n; ++i) {
    const std::size_t root = g.find(i);
    if (label[root] == static_cast<std::size_t>(-1))
      label[root] = next++;
    out[i] = static_cast<typename std::remove_reference<decltype(out[0])>::type>(label[root]);
  }
  return next;
}

} // namespace boost
#endif
