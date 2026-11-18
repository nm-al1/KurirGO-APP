import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

typedef RoadManeuver = ({
  int pointIndex,
  String type,
  String modifier,
  String street,
});

class RoadRoute {
  final List<RoadLeg> legs;
  RoadRoute(this.legs);
  static RoadRoute? _cached;
  static Future<RoadRoute> load() async => _cached ??= RoadRoute.fromJson(
    jsonDecode(await rootBundle.loadString('assets/routes/makassar_loop.json'))
        as Map<String, dynamic>,
  );

  factory RoadRoute.fromJson(Map<String, dynamic> json) {
    final legs = (json['route']['legs'] as List).indexed.map((entry) {
      final leg = entry.$2;
      final origin = json['inputCoordinates'][entry.$1];
      final points = <LatLng>[
        LatLng((origin[1] as num).toDouble(), (origin[0] as num).toDouble()),
      ];
      final turns = <RoadManeuver>[];
      for (final step in leg['steps']) {
        final coordinates = step['geometry']['coordinates'] as List;
        final start = points.isEmpty ? 0 : points.length - 1;
        for (final pair in coordinates) {
          final point = LatLng(
            (pair[1] as num).toDouble(),
            (pair[0] as num).toDouble(),
          );
          if (points.isEmpty || points.last != point) points.add(point);
        }
        turns.add((
          pointIndex: start,
          type: step['maneuver']['type'] as String,
          modifier: step['maneuver']['modifier'] as String? ?? '',
          street: step['name'] as String,
        ));
      }
      return RoadLeg(points, turns);
    }).toList();
    if (legs.isEmpty ||
        legs.length != (json['inputCoordinates'] as List).length - 1) {
      throw const FormatException('Jumlah ruas dan tujuan rute tidak sesuai.');
    }
    return RoadRoute(legs);
  }
}

class RoadLeg {
  final List<LatLng> points;
  final List<RoadManeuver> maneuvers;
  late final List<double> cumulative;
  static const distance = Distance(roundResult: false);
  RoadLeg(List<LatLng> points, List<RoadManeuver> maneuvers)
    : points = List.unmodifiable(points),
      maneuvers = List.unmodifiable(maneuvers) {
    if (points.length < 2 ||
        points.any(
          (p) =>
              !p.latitude.isFinite ||
              !p.longitude.isFinite ||
              p.latitude.abs() > 90 ||
              p.longitude.abs() > 180,
        )) {
      throw const FormatException('Koordinat rute tidak valid.');
    }
    cumulative = [0];
    for (var i = 1; i < points.length; i++) {
      cumulative.add(cumulative.last + distance(points[i - 1], points[i]));
    }
    if (length <= 0 ||
        maneuvers.any(
          (m) => m.pointIndex < 0 || m.pointIndex >= points.length,
        )) {
      throw const FormatException('Ruas rute tidak valid.');
    }
  }

  double get length => cumulative.last;
  int segmentAt(double meters) {
    var low = 1, high = points.length - 1;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (cumulative[mid] <= meters) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  LatLng positionAt(double meters) {
    if (meters <= 0) return points.first;
    if (meters >= length) return points.last;
    final i = segmentAt(meters);
    final span = cumulative[i] - cumulative[i - 1];
    final t = span == 0 ? 1.0 : (meters - cumulative[i - 1]) / span;
    final a = points[i - 1], b = points[i];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  double bearingAt(double meters) {
    final i = segmentAt(meters.clamp(0, length - .001));
    return (distance.bearing(points[i - 1], points[i]) + 360) % 360;
  }

  RoadManeuver get arrival =>
      (pointIndex: points.length - 1, type: 'arrive', modifier: '', street: '');
  RoadManeuver nextTurn(double meters) => maneuvers.firstWhere(
    (m) => m.type != 'depart' && cumulative[m.pointIndex] > meters + .1,
    orElse: () => arrival,
  );
}
