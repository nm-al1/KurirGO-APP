import '../dsa/adjacency_matrix.dart';
import 'tsp_solver.dart';

/// Best-improvement 2-Opt asimetris: O(N^2) per putaran, ruang O(N).
class TwoOptOptimizer {
  TSPResult optimize(AdjacencyMatrix matrix, List<int> tour) {
    final watch = Stopwatch()..start();
    if (tour.isEmpty) throw ArgumentError('Tour must be closed');
    validateTspInput(matrix, tour.first);
    final route = List<int>.of(tour), n = matrix.size;
    final stops = route.take(route.length - 1).toSet();
    if (route.length != n + 1 ||
        route.first != route.last ||
        stops.length != n ||
        stops.any((v) => v < 0 || v >= n)) {
      throw ArgumentError('Tour must visit each node once and return to start');
    }
    var operations = 0;
    while (true) {
      // Prefix perubahan biaya sisi internal ketika arahnya dibalik.
      final prefix = List.filled(n + 1, 0.0);
      for (var k = 0; k < n; k++) {
        prefix[k + 1] =
            prefix[k] +
            matrix.getDistance(route[k + 1], route[k]) -
            matrix.getDistance(route[k], route[k + 1]);
      }
      var bestDelta = -1e-9;
      var first = -1, last = -1;
      for (var i = 1; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          operations++;
          final a = route[i - 1], b = route[i];
          final c = route[j], d = route[j + 1];
          final delta =
              matrix.getDistance(a, c) +
              matrix.getDistance(b, d) -
              matrix.getDistance(a, b) -
              matrix.getDistance(c, d) +
              prefix[j] -
              prefix[i];
          if (delta < bestDelta) {
            bestDelta = delta;
            first = i;
            last = j;
          }
        }
      }
      if (first < 0) break;
      route.setRange(first, last + 1, route.sublist(first, last + 1).reversed);
    }
    final distance = tourDistance(matrix, route);
    if (!distance.isFinite) {
      throw StateError('Tour cost exceeds finite double range');
    }
    watch.stop();
    return TSPResult(
      tour: List.unmodifiable(route),
      totalDistance: distance,
      executionTime: watch.elapsed,
      operationsCount: operations,
      algorithmName: '2-Opt',
    );
  }
}
