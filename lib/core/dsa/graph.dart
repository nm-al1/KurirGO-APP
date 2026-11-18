class GraphNode {
  final int id;
  final String name;
  const GraphNode({required this.id, required this.name});
}

class DirectedEdge {
  final int from;
  final int to;
  final double distanceKm;
  final double durationMinutes;

  const DirectedEdge({
    required this.from,
    required this.to,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

/// Simpul depot/outlet dan sisi jalan satu arah; sisi balik harus eksplisit.
class DeliveryGraph {
  final List<GraphNode> nodes;
  final List<DirectedEdge> edges;

  DeliveryGraph({
    required Iterable<GraphNode> nodes,
    required Iterable<DirectedEdge> edges,
  }) : nodes = List.unmodifiable(nodes),
       edges = List.unmodifiable(edges) {
    final ids = this.nodes.map((node) => node.id).toSet();
    if (ids.length != this.nodes.length) {
      throw ArgumentError('Duplicate node ID');
    }
    for (final edge in this.edges) {
      if (!ids.contains(edge.from) || !ids.contains(edge.to)) {
        throw ArgumentError('Edge endpoint is not registered');
      }
    }
  }

  Iterable<DirectedEdge> outgoingEdges(int nodeId) =>
      edges.where((edge) => edge.from == nodeId);
}
