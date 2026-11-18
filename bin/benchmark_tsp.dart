// ignore_for_file: avoid_print
import 'dart:math';

import 'package:kurir_go/core/algorithms/held_karp_tsp.dart';
import 'package:kurir_go/core/algorithms/nearest_neighbor_tsp.dart';
import 'package:kurir_go/core/algorithms/tsp_solver.dart';
import 'package:kurir_go/core/dsa/adjacency_matrix.dart';
import 'package:kurir_go/data/dummy_makassar_data.dart';

AdjacencyMatrix syntheticMatrix(int size) {
  final rng = Random(42 + size), matrix = AdjacencyMatrix(size);
  for (var u = 0; u < size; u++) {
    for (var v = 0; v < size; v++) {
      matrix.setDistance(u, v, u == v ? 0 : (1 + rng.nextInt(30)).toDouble());
    }
  }
  return matrix;
}

({int micros, double distance}) measure(
  TSPSolver solver,
  AdjacencyMatrix matrix,
) {
  solver.solve(matrix, 0); // Warm-up sebelum lima sampel terukur.
  final samples = List.generate(5, (_) => solver.solve(matrix, 0));
  final times = samples.map((r) => r.executionTime.inMicroseconds).toList()
    ..sort();
  return (micros: times[2], distance: samples.first.totalDistance);
}

void main() {
  print('BROWCYL DELIVERY - TSP BENCHMARK (median 5 run, 1 warm-up/solver)');
  print('N=3: fixture Makassar; N=6,10,12: graf berarah sintetis, seed=42+N.');
  final header = [
    'N',
    'HK (us)',
    'NN (us)',
    'HK (km)',
    'NN (km)',
    'Est. BBM (%)',
  ];
  void row(List<String> cells) =>
      print(cells.map((c) => c.padLeft(13)).join(' | '));
  row(header);
  print('-' * 93);
  for (final n in [3, 6, 10, 12]) {
    final matrix = n == 3
        ? DummyMakassarData.createDistanceMatrix()
        : syntheticMatrix(n);
    final exact = measure(HeldKarpTSP(), matrix);
    final greedy = measure(NearestNeighborTSP(), matrix);
    final savings = greedy.distance == 0
        ? 0.0
        : (greedy.distance - exact.distance) / greedy.distance * 100;
    row([
      '$n',
      '${exact.micros}',
      '${greedy.micros}',
      exact.distance.toStringAsFixed(2),
      greedy.distance.toStringAsFixed(2),
      savings.toStringAsFixed(2),
    ]);
  }
  print(
    'Est. BBM = (NN-HK)/NN x 100; proksi jarak, asumsi konsumsi/km konstan.',
  );
  print('Runtime Dart JIT lokal; bukan pengukuran konsumsi BBM di lapangan.');
}
