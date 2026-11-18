import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kurir_go/core/algorithms/road_tour.dart';

Future<void> main() async {
  const points = [
    [119.435, -5.156],
    [119.482, -5.1685],
    [119.5215, -5.0782],
    [119.4327, -5.1477],
    [119.419, -5.161],
    [119.415, -5.14],
  ];
  final client = http.Client();
  Future<Map<String, dynamic>> request(
    String path,
    Map<String, String> query,
  ) async {
    final result = await client
        .get(Uri.https('router.project-osrm.org', path, query))
        .timeout(const Duration(seconds: 30));
    final body = jsonDecode(result.body) as Map<String, dynamic>;
    if (result.statusCode != 200 || body['code'] != 'Ok') {
      throw StateError('OSRM gagal; fixture lama dipertahankan.');
    }
    return body;
  }

  String encoded(List<List<num>> p) => p.map((v) => v.join(',')).join(';');
  try {
    final table = await request('/table/v1/driving/${encoded(points)}', {
      'annotations': 'distance',
    });
    final solution = solveRoadDistances(table['distances'] as List);
    final coordinates = solution.tour.map((i) => points[i]).toList();
    final response = await request(
      '/route/v1/driving/${encoded(coordinates)}',
      {'steps': 'true', 'geometries': 'geojson', 'overview': 'full'},
    );
    final route = (response['routes'] as List).first;
    if ((route['legs'] as List).length != solution.tour.length - 1) {
      throw StateError('Geometry tidak lengkap.');
    }
    await File('assets/routes/demo_loop.json').writeAsString(
      jsonEncode({
        'route': route,
        'inputCoordinates': coordinates,
        'nodeCoordinates': points,
        'distances': table['distances'],
        'nodeTour': solution.tour,
        'matrixDistance': solution.totalDistance,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    stdout.writeln(
      'Demo ${solution.tour}: ${solution.totalDistance.toStringAsFixed(1)} m pada matriks jalan.',
    );
  } finally {
    client.close();
  }
}
