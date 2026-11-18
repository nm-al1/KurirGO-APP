import '../dsa/adjacency_matrix.dart';
import 'tsp_solver.dart';

/// DP O(N^2 * 2^N), ruang O(N * 2^N); tabel tumbuh eksponensial.
class HeldKarpTSP implements TSPSolver {
  @override
  String get name => 'Held-Karp DP';

  @override
  TSPResult solve(AdjacencyMatrix matrix, int startNode) {
    final watch = Stopwatch()..start();
    validateTspInput(matrix, startNode);
    final n = matrix.size, states = 1 << n, startMask = 1 << startNode;
    final memo = List.generate(states, (_) => List.filled(n, double.infinity));
    final parent = List.generate(states, (_) => List.filled(n, -1));
    memo[startMask][startNode] = 0;
    var operations = 0;
    for (var mask = startMask; mask < states; mask++) {
      if (mask & startMask == 0) continue;
      for (var u = 0; u < n; u++) {
        if (!memo[mask][u].isFinite) continue;
        for (var v = 0; v < n; v++) {
          if (mask & (1 << v) != 0) continue;
          operations++; // Satu evaluasi kandidat transisi.
          final next = mask | (1 << v);
          final cost = memo[mask][u] + matrix.getDistance(u, v);
          if (cost < memo[next][v]) {
            memo[next][v] = cost;
            parent[next][v] = u;
          }
        }
      }
    }
    var best = double.infinity, last = -1;
    for (var u = 0; u < n; u++) {
      if (n > 1 && u == startNode) continue;
      operations++; // Kandidat penutupan kembali ke depot.
      final cost = memo[states - 1][u] + matrix.getDistance(u, startNode);
      if (cost < best) {
        best = cost;
        last = u;
      }
    }
    if (last < 0) throw StateError('Tour cost exceeds finite double range');
    final reverse = <int>[];
    var mask = states - 1, current = last;
    while (current != startNode) {
      reverse.add(current);
      final previous = parent[mask][current];
      mask ^= 1 << current;
      current = previous;
    }
    watch.stop();
    return TSPResult(
      tour: List.unmodifiable([startNode, ...reverse.reversed, startNode]),
      totalDistance: best,
      executionTime: watch.elapsed,
      operationsCount: operations,
      algorithmName: name,
    );
  }
}
