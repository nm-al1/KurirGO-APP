import '../dsa/graph.dart';
import '../dsa/priority_queue.dart';

class DijkstraRouter {
  /// Adjacency map dibangun sekali; bobot paralel dipilih yang minimum.
  ({List<int> path, double distance}) shortestPath(
    DeliveryGraph graph,
    int startNode,
    int endNode,
  ) {
    final adjacency = {
      for (final node in graph.nodes) node.id: <int, double>{},
    };
    if (!adjacency.containsKey(startNode) || !adjacency.containsKey(endNode)) {
      throw ArgumentError('Unknown endpoint');
    }
    for (final edge in graph.edges) {
      if (!edge.distanceKm.isFinite || edge.distanceKm < 0) {
        throw ArgumentError('Dijkstra requires finite nonnegative weights');
      }
      final neighbors = adjacency[edge.from]!;
      if (edge.distanceKm < (neighbors[edge.to] ?? double.infinity)) {
        neighbors[edge.to] = edge.distanceKm;
      }
    }
    final distances = {for (final id in adjacency.keys) id: double.infinity};
    final parent = <int, int>{}, settled = <int>{};
    final queue = MinHeap<int>()..insert(startNode, 0);
    distances[startNode] = 0;
    while (!queue.isEmpty) {
      final u = queue.extractMin();
      if (!settled.add(u)) continue;
      if (u == endNode) {
        final reverse = [u];
        while (reverse.last != startNode) {
          reverse.add(parent[reverse.last]!);
        }
        return (
          path: List<int>.unmodifiable(reverse.reversed),
          distance: distances[u]!,
        );
      }
      for (final edge in adjacency[u]!.entries) {
        final candidate = distances[u]! + edge.value;
        if (!settled.contains(edge.key) && candidate < distances[edge.key]!) {
          distances[edge.key] = candidate;
          parent[edge.key] = u;
          queue.insert(edge.key, candidate);
        }
      }
    }
    return (path: const <int>[], distance: double.infinity);
  }
}
