import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/core/dsa/adjacency_matrix.dart';
import 'package:kurir_go/core/algorithms/held_karp_tsp.dart';
import 'package:kurir_go/core/algorithms/nearest_neighbor_tsp.dart';
import 'package:kurir_go/core/algorithms/two_opt_optimizer.dart';
import 'package:kurir_go/core/algorithms/dijkstra_router.dart';
import 'package:kurir_go/core/algorithms/tsp_solver.dart';

import 'algorithm_fixtures.dart';

void algorithmEdgeCases() {
  for (final solver in <TSPSolver>[HeldKarpTSP(), NearestNeighborTSP()]) {
    group(solver.name, () {
      test('Satu simpul dan metadata penghitung operasi', () {
        final matrix = AdjacencyMatrix(1);
        final result = solver.solve(matrix, 0);
        expectTour(matrix, result, 0);
        expect(result.tour, [0, 0]);
        expect(result.totalDistance, 0);
        expect(result.operationsCount, 1);
        final pair = solver.solve(
          matrixOf([
            [0, 2],
            [3, 0],
          ]),
          0,
        );
        expect(pair.operationsCount, 2);
      });
      test('Bobot sama dan nol tetap deterministik', () {
        final matrix = matrixOf(List.generate(4, (_) => List.filled(4, 0)));
        final first = solver.solve(matrix, 2);
        expectTour(matrix, first, 2);
        expect(solver.solve(matrix, 2).tour, first.tour);
      });
      test('Menolak matriks kosong dan indeks awal invalid', () {
        expect(() => solver.solve(AdjacencyMatrix(0), 0), throwsArgumentError);
        expect(() => solver.solve(AdjacencyMatrix(1), -1), throwsArgumentError);
        expect(() => solver.solve(AdjacencyMatrix(1), 1), throwsArgumentError);
      });
      test('Menolak sisi hilang, NaN, negatif dan diagonal bukan nol', () {
        for (final invalid in [double.infinity, double.nan, -1.0]) {
          final matrix = matrixOf([
            [0, invalid],
            [1, 0],
          ]);
          expect(() => solver.solve(matrix, 0), throwsArgumentError);
        }
        final matrix = AdjacencyMatrix(1)..setDistance(0, 0, 1);
        expect(() => solver.solve(matrix, 0), throwsArgumentError);
      });
    });
  }
  test('2-Opt satu simpul, dua simpul, dan tour invalid', () {
    final optimizer = TwoOptOptimizer();
    expect(optimizer.optimize(AdjacencyMatrix(1), [0, 0]).totalDistance, 0);
    final pair = matrixOf([
      [0, 2],
      [3, 0],
    ]);
    expectTour(pair, optimizer.optimize(pair, [1, 0, 1]), 1);
    for (final tour in <List<int>>[
      [],
      [0, 1],
      [0, 0, 0],
      [0, 2, 0],
    ]) {
      expect(() => optimizer.optimize(pair, tour), throwsArgumentError);
    }
  });
  test('2-Opt benar-benar memperbaiki greedy pada matriks asimetris', () {
    final matrix = matrixOf([
      [0, 1, 2],
      [1, 0, 1],
      [100, 1, 0],
    ]);
    final result = TwoOptOptimizer().optimize(matrix, [0, 1, 2, 0]);
    expect(result.tour, [0, 2, 1, 0]);
    expect(result.totalDistance, 4);
  });
  test('Dijkstra asal sama, simpul terputus dan endpoint invalid', () {
    final graph = graphOf([road(10, 20, 0)]), router = DijkstraRouter();
    final same = router.shortestPath(graph, 10, 10);
    expect(same.path, [10]);
    expect(same.distance, 0);
    expect(router.shortestPath(graph, 10, 20).distance, 0);
    final missing = router.shortestPath(graph, 10, 40);
    expect(missing.path, isEmpty);
    expect(missing.distance, double.infinity);
    expect(() => router.shortestPath(graph, 99, 10), throwsArgumentError);
    expect(() => router.shortestPath(graph, 10, 99), throwsArgumentError);
  });
  test('Dijkstra menolak semua bobot negatif/nonfinite sebelum pencarian', () {
    for (final weight in [-1.0, double.nan, double.infinity]) {
      final graph = graphOf([road(20, 30, weight)]);
      expect(
        () => DijkstraRouter().shortestPath(graph, 10, 10),
        throwsArgumentError,
      );
    }
  });
}
