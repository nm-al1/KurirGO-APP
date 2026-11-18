import '../dsa/adjacency_matrix.dart';
import 'held_karp_tsp.dart';
import 'nearest_neighbor_tsp.dart';
import 'two_opt_optimizer.dart';
import 'tsp_solver.dart';

TSPResult solveRoadDistances(List<dynamic> distances) {
  if (distances.length < 2 || distances.length > 21) {
    throw ArgumentError('Jumlah tujuan tidak valid.');
  }
  final matrix = AdjacencyMatrix(distances.length);
  for (var i = 0; i < matrix.size; i++) {
    if (distances[i] is! List || (distances[i] as List).length != matrix.size) {
      throw ArgumentError('Matriks jarak tidak lengkap.');
    }
    for (var j = 0; j < matrix.size; j++) {
      final value = distances[i][j];
      if (value is! num ||
          !value.isFinite ||
          value < 0 ||
          (i == j && value != 0)) {
        throw StateError('Ada tujuan yang tidak dapat dijangkau.');
      }
      matrix.setDistance(i, j, value.toDouble());
    }
  }
  return matrix.size <= 11
      ? HeldKarpTSP().solve(matrix, 0)
      : TwoOptOptimizer().optimize(
          matrix,
          NearestNeighborTSP().solve(matrix, 0).tour,
        );
}
