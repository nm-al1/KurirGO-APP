import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kurir_go/data/models/road_route.dart';
import 'package:kurir_go/data/dummy_makassar_data.dart';
import 'package:kurir_go/features/controllers/navigation_simulation_controller.dart';

RoadRoute fixtureRoute() => RoadRoute.fromJson(
  jsonDecode(File('assets/routes/makassar_loop.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  test(
    'Three saved road legs follow the fixture stops; matrix remains 28.5',
    () {
      final roads = fixtureRoute();
      const nodes = [0, 2, 1, 0];
      expect(roads.legs, hasLength(3));
      for (var i = 0; i < 3; i++) {
        final leg = roads.legs[i];
        final start = DummyMakassarData.waypoints[nodes[i]];
        final end = DummyMakassarData.waypoints[nodes[i + 1]];
        expect(leg.points.first, LatLng(start.latitude, start.longitude));
        expect(
          RoadLeg.distance(
            leg.points.last,
            LatLng(end.latitude, end.longitude),
          ),
          lessThan(50),
        );
        expect(leg.length, greaterThan(1000));
        expect(leg.cumulative, orderedEquals([...leg.cumulative]..sort()));
        expect(leg.maneuvers, isNotEmpty);
      }
      final matrix = DummyMakassarData.createDistanceMatrix();
      expect(
        matrix.getDistance(0, 2) +
            matrix.getDistance(2, 1) +
            matrix.getDistance(1, 0),
        28.5,
      );
    },
  );
  test('Interpolation handles duplicate points and both endpoints', () {
    final leg = RoadLeg([
      const LatLng(0, 0),
      const LatLng(0, 0),
      const LatLng(0, .001),
      const LatLng(0, .001),
    ], []);
    expect(leg.positionAt(0), const LatLng(0, 0));
    expect(leg.positionAt(leg.length / 2).longitude, closeTo(.0005, 1e-8));
    expect(leg.positionAt(leg.length), const LatLng(0, .001));
    expect(
      () => RoadLeg([const LatLng(0, 0), const LatLng(0, 0)], []),
      throwsFormatException,
    );
    expect(
      () => RoadLeg([const LatLng(91, 0), const LatLng(0, 1)], []),
      throwsFormatException,
    );
  });
  test(
    'Pause, resume, replay and arrival preserve deterministic route state',
    () {
      final s = NavigationSimulationController(fixtureRoute().legs.first);
      addTearDown(s.dispose);
      expect(s.speed, 0);
      s.advance(const Duration(seconds: 1));
      expect(s.traveled, 0);
      s.play();
      final before = s.distanceToTurn;
      s.advance(const Duration(milliseconds: 100));
      expect(s.traveled, greaterThan(0));
      expect(s.distanceToTurn, lessThan(before));
      expect(s.speed, inInclusiveRange(36, 42));
      s.pause();
      final paused = s.position;
      s.advance(const Duration(seconds: 1));
      expect(s.position, paused);
      s.play();
      s.advance(const Duration(hours: 10));
      expect(s.arrived, isTrue);
      expect(s.running, isFalse);
      expect(s.position, s.leg.points.last);
      expect(s.instruction, 'Tiba di Tujuan');
      expect(s.speed, 0);
      s.replay();
      expect(s.position, s.leg.points.first);
      expect(s.running, isFalse);
      expect(s.traveled, 0);
    },
  );
  test('Heading follows shortest rotation across north', () {
    final s = NavigationSimulationController(
      RoadLeg([const LatLng(0, 0), const LatLng(1, .01745)], []),
    );
    addTearDown(s.dispose);
    s.heading = 359;
    s.play();
    s.advance(const Duration(milliseconds: 1));
    expect(s.heading, greaterThan(359));
    expect(s.heading, lessThan(360));
    final traveled = s.traveled;
    s.advance(const Duration(milliseconds: -10));
    expect(s.traveled, traveled);
  });
}
