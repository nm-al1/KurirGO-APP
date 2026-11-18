import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/core/algorithms/held_karp_tsp.dart';
import 'package:kurir_go/core/algorithms/nearest_neighbor_tsp.dart';
import 'package:kurir_go/core/algorithms/two_opt_optimizer.dart';
import 'package:kurir_go/core/algorithms/dijkstra_router.dart';
import 'package:kurir_go/core/algorithms/tsp_solver.dart';

import 'algorithm_fixtures.dart';
import 'algorithms_edge_cases.dart';

void main() {
  test('Segitiga Makassar tertutup dengan total 37 km', () {
    final matrix = matrixOf([
      [0, 16.5, 8.2],
      [16.5, 0, 12.3],
      [8.2, 12.3, 0],
    ]);
    for (final solver in <TSPSolver>[HeldKarpTSP(), NearestNeighborTSP()]) {
      final result = solver.solve(matrix, 0);
      expectTour(matrix, result, 0);
      expect(result.totalDistance, closeTo(37, 1e-9));
    }
  });
  test(
    'Held-Karp cocok dengan brute force pada graf berarah deterministik',
    () {
      final rng = Random(42),
          exact = HeldKarpTSP(),
          greedy = NearestNeighborTSP();
      for (var n = 2; n <= 7; n++) {
        final matrix = matrixOf(
          List.generate(
            n,
            (u) => List.generate(n, (v) => u == v ? 0 : rng.nextInt(30) + 1),
          ),
        );
        for (final start in [0, n - 1]) {
          final result = exact.solve(matrix, start),
              baseline = greedy.solve(matrix, start);
          expectTour(matrix, result, start);
          expectTour(matrix, baseline, start);
          expect(result.totalDistance, bruteForce(matrix, start));
          expect(
            result.totalDistance,
            lessThanOrEqualTo(baseline.totalDistance),
          );
          expect(exact.solve(matrix, start).tour, result.tour);
        }
      }
    },
  );
  test('Greedy dapat memilih sisi pulang mahal', () {
    final matrix = matrixOf([
      [0, 1, 2],
      [1, 0, 1],
      [100, 1, 0],
    ]);
    expect(HeldKarpTSP().solve(matrix, 0).totalDistance, 4);
    expect(NearestNeighborTSP().solve(matrix, 0).totalDistance, 102);
  });
  test('2-Opt membuka persilangan simetris tanpa memutasi input', () {
    final matrix = matrixOf([
      [0, 2, 1, 1],
      [2, 0, 1, 1],
      [1, 1, 0, 2],
      [1, 1, 2, 0],
    ]);
    final input = [0, 1, 2, 3, 0];
    final result = TwoOptOptimizer().optimize(matrix, input);
    expectTour(matrix, result, 0);
    expect(result.totalDistance, 4);
    expect(input, [0, 1, 2, 3, 0]);
    expect(TwoOptOptimizer().optimize(matrix, result.tour).tour, result.tour);
  });
  test('2-Opt menghitung penalti pembalikan sisi internal asimetris', () {
    final matrix = matrixOf([
      [0, 10, 1, 50],
      [50, 0, 1, 1],
      [50, 100, 0, 10],
      [1, 50, 50, 0],
    ]);
    final result = TwoOptOptimizer().optimize(matrix, [0, 1, 2, 3, 0]);
    expectTour(matrix, result, 0);
    expect(result.totalDistance, 22);
    expect(result.tour, [0, 1, 2, 3, 0]);
  });
  test('2-Opt mencapai minimum lokal pada graf asimetris', () {
    final rng = Random(7);
    for (var trial = 0; trial < 12; trial++) {
      final matrix = matrixOf(
        List.generate(
          6,
          (u) => List.generate(6, (v) => u == v ? 0 : rng.nextInt(30) + 1),
        ),
      );
      final initial = [3, 0, 1, 2, 4, 5, 3];
      final result = TwoOptOptimizer().optimize(matrix, initial);
      expectTour(matrix, result, 3);
      expect(
        result.totalDistance,
        lessThanOrEqualTo(tourDistance(matrix, initial)),
      );
      for (var i = 1; i < 6; i++) {
        for (var j = i + 1; j < 6; j++) {
          final candidate = [...result.tour];
          candidate.setRange(i, j + 1, candidate.sublist(i, j + 1).reversed);
          expect(
            tourDistance(matrix, candidate),
            greaterThanOrEqualTo(result.totalDistance),
          );
        }
      }
    }
  });
  test('Dijkstra melakukan relaksasi ulang, sisi paralel dan arah jalan', () {
    final graph = graphOf([
      road(10, 20, 10),
      road(10, 20, 12),
      road(10, 30, 1),
      road(30, 20, 2),
      road(20, 40, 20),
      road(30, 40, 50),
    ]);
    final result = DijkstraRouter().shortestPath(graph, 10, 40);
    expect(result.path, [10, 30, 20, 40]);
    expect(result.distance, 23);
    final reverse = DijkstraRouter().shortestPath(graph, 40, 10);
    expect(reverse.path, isEmpty);
    expect(reverse.distance, double.infinity);
  });
  algorithmEdgeCases();
}
