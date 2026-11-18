import 'dart:convert';

import 'package:latlong2/latlong.dart';

import 'package:http/http.dart' as http;

import '../core/algorithms/road_tour.dart';
import 'courier_store.dart';
import 'models/road_route.dart';

class RouteService {
  Future<Json> between(LatLng origin, LatLng destination) async {
    final coordinates = [
      [origin.longitude, origin.latitude],
      [destination.longitude, destination.latitude],
    ];
    final response = await request(
      'route/v1/driving/${coordinates.map((p) => p.join(',')).join(';')}',
      {'steps': 'true', 'geometries': 'geojson', 'overview': 'full'},
    );
    final geometry = <String, dynamic>{
      'route': (response['routes'] as List).first,
      'inputCoordinates': coordinates,
    };
    RoadRoute.fromJson(geometry);
    return geometry;
  }

  final http.Client client;
  final String endpoint;
  RouteService({
    http.Client? client,
    this.endpoint = const String.fromEnvironment(
      'OSRM_URL',
      defaultValue: 'https://router.project-osrm.org',
    ),
  }) : client = client ?? http.Client();
  static const depot = [119.4350, -5.1560];

  Future<Json> request(String path, Map<String, String> query) async {
    final response = await client
        .get(Uri.parse('$endpoint/$path').replace(queryParameters: query))
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw StateError('Layanan rute tidak tersedia. Coba lagi saat online.');
    }
    final body = jsonDecode(response.body) as Json;
    if (body['code'] != 'Ok') {
      throw StateError(
        'Alamat tidak dapat dijangkau melalui jalan. Periksa pin.',
      );
    }
    return body;
  }

  Future<Json> calculate(List<Json> orders) async {
    if (orders.isEmpty || orders.length > 20) {
      throw StateError('Pilih 1–20 pesanan per perjalanan.');
    }
    final coordinates = <List<num>>[depot];
    final grouped = <List<String>>[[]];
    for (final order in orders) {
      final pair = [order['lng'] as num, order['lat'] as num];
      var index = coordinates.indexWhere(
        (p) => p[0] == pair[0] && p[1] == pair[1],
      );
      if (index == 0) {
        throw StateError('Tujuan pengantaran harus berbeda dari depot.');
      }
      if (index < 0) {
        index = coordinates.length;
        coordinates.add(pair);
        grouped.add([]);
      }
      grouped[index].add(order['id'] as String);
    }
    String encoded(List<List<num>> points) =>
        points.map((p) => '${p[0]},${p[1]}').join(';');
    final table = await request('table/v1/driving/${encoded(coordinates)}', {
      'annotations': 'distance',
    });
    final result = solveRoadDistances(table['distances'] as List);
    final tour = result.tour.map((i) => coordinates[i]).toList();
    final response = await request('route/v1/driving/${encoded(tour)}', {
      'steps': 'true',
      'geometries': 'geojson',
      'overview': 'full',
    });
    final route = (response['routes'] as List).first as Json;
    final geometry = <String, dynamic>{
      'route': route,
      'inputCoordinates': tour,
    };
    RoadRoute.fromJson(geometry);
    return {
      'sourceOrders': orders,
      'geometry': geometry,
      'stops': [
        for (final i in result.tour.skip(1).take(result.tour.length - 2))
          grouped[i],
      ],
      'distance': route['distance'],
      'duration': route['duration'],
      'algorithm': result.algorithmName,
    };
  }
}
