import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/core/dsa/adjacency_matrix.dart';
import 'package:kurir_go/core/dsa/graph.dart';
import 'package:kurir_go/core/algorithms/tsp_solver.dart';

AdjacencyMatrix matrixOf(List<List<num>> rows) {
  final matrix = AdjacencyMatrix(rows.length);
  for (var u = 0; u < rows.length; u++) {
    for (var v = 0; v < rows.length; v++) {
      matrix.setDistance(u, v, rows[u][v].toDouble());
    }
  }
  return matrix;
}

void expectTour(AdjacencyMatrix matrix, TSPResult result, int start) {
  expect(result.tour.length, matrix.size + 1);
  expect(result.tour.first, start);
  expect(result.tour.last, start);
  expect(
    result.tour.take(matrix.size),
    unorderedEquals(List.generate(matrix.size, (i) => i)),
  );
  expect(
    result.totalDistance,
    closeTo(tourDistance(matrix, result.tour), 1e-8),
  );
  expect(result.executionTime.isNegative, isFalse);
  expect(result.operationsCount, greaterThanOrEqualTo(0));
  expect(result.algorithmName, isNotEmpty);
}

// Enumerasi independen untuk oracle eksak pada graf kecil.
double bruteForce(AdjacencyMatrix matrix, int start) {
  var best = double.infinity;
  void visit(List<int> path, Set<int> remaining, double cost) {
    if (remaining.isEmpty) {
      final total = cost + matrix.getDistance(path.last, start);
      if (total < best) best = total;
      return;
    }
    for (final next in remaining) {
      visit(
        [...path, next],
        {...remaining}..remove(next),
        cost + matrix.getDistance(path.last, next),
      );
    }
  }

  visit(
    [start],
    {
      for (var i = 0; i < matrix.size; i++)
        if (i != start) i,
    },
    0,
  );
  return best;
}

DirectedEdge road(int from, int to, double km) =>
    DirectedEdge(from: from, to: to, distanceKm: km, durationMinutes: km * 2);

DeliveryGraph graphOf(List<DirectedEdge> edges) => DeliveryGraph(
  nodes: [
    for (final id in [10, 20, 30, 40]) GraphNode(id: id, name: 'V$id'),
  ],
  edges: edges,
);
