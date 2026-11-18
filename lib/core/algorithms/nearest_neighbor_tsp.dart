import '../dsa/adjacency_matrix.dart';
import 'tsp_solver.dart';

class NearestNeighborTSP implements TSPSolver {
  @override
  String get name => 'Nearest Neighbor';

  @override
  TSPResult solve(AdjacencyMatrix matrix, int startNode) {
    final watch = Stopwatch()..start();
    validateTspInput(matrix, startNode);
    final visited = List.filled(matrix.size, false);
    final tour = [startNode];
    visited[startNode] = true;
    var current = startNode, operations = 0;
    var total = 0.0;
    while (tour.length < matrix.size) {
      var nearest = -1, distance = double.infinity;
      for (var v = 0; v < matrix.size; v++) {
        if (visited[v]) continue;
        operations++; // Satu evaluasi kandidat yang belum dikunjungi.
        final candidate = matrix.getDistance(current, v);
        if (candidate < distance) {
          nearest = v;
          distance = candidate;
        }
      }
      visited[nearest] = true;
      tour.add(nearest);
      total += distance;
      current = nearest;
    }
    total += matrix.getDistance(current, startNode);
    operations++; // Segmen penutup.
    tour.add(startNode);
    if (!total.isFinite) {
      throw StateError('Tour cost exceeds finite double range');
    }
    watch.stop();
    return TSPResult(
      tour: List.unmodifiable(tour),
      totalDistance: total,
      executionTime: watch.elapsed,
      operationsCount: operations,
      algorithmName: name,
    );
  }
}
