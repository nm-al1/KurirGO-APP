import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/core/algorithms/road_tour.dart';
import 'package:kurir_go/data/models/road_route.dart';

void main() {
  test(
    'saved demo tour matches shared solver and brute force over all 120 orders',
    () {
      final fixture = jsonDecode(
        File('assets/routes/demo_loop.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final distances = fixture['distances'] as List;
      final result = solveRoadDistances(distances);
      double cost(List<int> path) {
        var sum = 0.0;
        for (var i = 1; i < path.length; i++) {
          sum += (distances[path[i - 1]][path[i]] as num).toDouble();
        }
        return sum;
      }

      var best = double.infinity, count = 0;
      void search(List<int> path, List<int> left) {
        if (left.isEmpty) {
          final value = cost([0, ...path, 0]);
          if (value < best) best = value;
          count++;
          return;
        }
        for (final node in left) {
          search([...path, node], left.where((n) => n != node).toList());
        }
      }

      search([], [1, 2, 3, 4, 5]);
      expect(count, 120);
      expect(result.totalDistance, closeTo(best, 0.001));
      expect(fixture['nodeTour'], result.tour);
      expect(fixture['matrixDistance'], closeTo(best, 0.001));
      final coordinates = fixture['inputCoordinates'] as List,
          nodes = fixture['nodeCoordinates'] as List;
      expect(coordinates, [for (final index in result.tour) nodes[index]]);
      expect(RoadRoute.fromJson(fixture).legs.length, 6);
    },
  );
}
