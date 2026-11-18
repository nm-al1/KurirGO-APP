import '../dsa/adjacency_matrix.dart';

class TSPResult {
  final List<int> tour;
  final double totalDistance;
  final Duration executionTime;
  final int operationsCount;
  final String algorithmName;

  const TSPResult({
    required this.tour,
    required this.totalDistance,
    required this.executionTime,
    required this.operationsCount,
    required this.algorithmName,
  });
}

abstract class TSPSolver {
  String get name;
  TSPResult solve(AdjacencyMatrix matrix, int startNode);
}

/// TSP bekerja pada graf lengkap, finite, nonnegatif dengan diagonal nol.
void validateTspInput(AdjacencyMatrix matrix, int startNode) {
  if (startNode < 0 || startNode >= matrix.size) {
    throw ArgumentError.value(startNode, 'startNode');
  }
  for (var u = 0; u < matrix.size; u++) {
    for (var v = 0; v < matrix.size; v++) {
      final distance = matrix.getDistance(u, v);
      if (!distance.isFinite || distance < 0 || (u == v && distance != 0)) {
        throw ArgumentError(
          'Expected finite nonnegative distances and zero diagonal',
        );
      }
    }
  }
}

double tourDistance(AdjacencyMatrix matrix, List<int> tour) {
  var total = 0.0;
  for (var i = 1; i < tour.length; i++) {
    total += matrix.getDistance(tour[i - 1], tour[i]);
  }
  return total;
}
