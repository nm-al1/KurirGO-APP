import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:kurir_go/data/models/road_route.dart';
import 'package:kurir_go/data/route_service.dart';
import 'package:kurir_go/features/controllers/gps_navigation.dart';

class FakeLocation implements LocationSource {
  final stream = StreamController<LocationFix>.broadcast();
  int starts = 0;
  @override
  Future<Stream<LocationFix>> start() async {
    starts++;
    return stream.stream;
  }
}

class DelayedLocation implements LocationSource {
  final pending = <Completer<Stream<LocationFix>>>[];
  @override
  Future<Stream<LocationFix>> start() {
    final result = Completer<Stream<LocationFix>>();
    pending.add(result);
    return result.future;
  }
}

void main() {
  test('first distant stationary fix requests connector immediately and failure keeps geometry', () async {
    final source = FakeLocation();
    var calls = 0;
    final service = RouteService(
      client: MockClient((_) async {
        calls++;
        return http.Response('offline', 503);
      }),
    );
    final gps = GpsNavigation(source, service);
    final original = RoadLeg([
      const LatLng(-5.15, 119.43),
      const LatLng(-5.15, 119.44),
    ], []);
    gps.setLeg(0, original);
    await gps.start();
    expect(gps.onRoute, isFalse);
    gps.accept(
      LocationFix(const LatLng(-6.2, 106.8), DateTime.now(), 10, 0, 0),
    );
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    expect(gps.leg, same(original));
    expect(gps.onRoute, isFalse);
    expect(gps.error, contains('Rute baru belum tersedia'));
    gps.dispose();
    service.client.close();
    await source.stream.close();
  });
  RoadLeg leg() => RoadLeg(
    [const LatLng(-5.15, 119.43), const LatLng(-5.15, 119.44)],
    [
      (
        pointIndex: 0,
        type: 'depart',
        modifier: 'right',
        street: 'Jalan Contoh',
      ),
    ],
  );
  test(
    'GPS quality, ordered samples, arrival, stopping and single subscription',
    () async {
      final source = FakeLocation();
      final routes = RouteService();
      final gps = GpsNavigation(source, routes);
      gps.setLeg(0, leg());
      await gps.start();
      await gps.start();
      expect(source.starts, 1);
      final now = DateTime.now();
      gps.accept(LocationFix(const LatLng(-5.15, 119.434), now, 10, 90, 5));
      expect(gps.reliable, isTrue);
      expect(gps.progress, greaterThan(400));
      gps.accept(
        LocationFix(
          const LatLng(-5.15, 119.439),
          now.subtract(const Duration(seconds: 1)),
          10,
          90,
          5,
        ),
      );
      expect(gps.fix!.point.longitude, 119.434);
      gps.accept(
        LocationFix(
          const LatLng(-5.15, 119.44),
          now.add(const Duration(milliseconds: 1)),
          100,
          90,
          0,
        ),
      );
      expect(gps.reliable, isFalse);
      expect(gps.nearDestination, isFalse);
      for (var i = 2; i < 4; i++) {
        gps.accept(
          LocationFix(
            const LatLng(-5.15, 119.44),
            now.add(Duration(milliseconds: i)),
            10,
            90,
            0,
          ),
        );
      }
      expect(gps.nearDestination, isTrue);
      await gps.stop();
      expect(gps.fix, isNull);
      expect(gps.enabled, isFalse);
      gps.dispose();
      routes.client.close();
      await source.stream.close();
    },
  );
  test(
    'off-route reroute is throttled and late response cannot replace next leg',
    () async {
      final response = Completer<http.Response>();
      var calls = 0;
      final routes = RouteService(
        client: MockClient((_) {
          calls++;
          return response.future;
        }),
      );
      final source = FakeLocation();
      final gps = GpsNavigation(source, routes);
      gps.setLeg(0, leg());
      await gps.start();
      final now = DateTime.now();
      for (var i = 0; i < 5; i++) {
        gps.accept(
          LocationFix(
            const LatLng(-5.16, 119.435),
            now.add(Duration(milliseconds: i)),
            10,
            90,
            4,
          ),
        );
      }
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      expect(gps.rerouting, isTrue);
      final next = leg();
      gps.setLeg(1, next);
      response.complete(
        http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'legs': [
                  {
                    'steps': [
                      {
                        'geometry': {
                          'coordinates': [
                            [119.435, -5.16],
                            [119.44, -5.15],
                          ],
                        },
                        'maneuver': {'type': 'depart'},
                        'name': 'New road',
                      },
                    ],
                  },
                ],
              },
            ],
          }),
          200,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(gps.leg, same(next));
      expect(gps.legIndex, 1);
      gps.dispose();
      routes.client.close();
      await source.stream.close();
    },
  );
  test(
    'changing destination during permission request still starts GPS',
    () async {
      final source = DelayedLocation();
      final routes = RouteService();
      final gps = GpsNavigation(source, routes)..setLeg(0, leg());
      final stream = StreamController<LocationFix>.broadcast();
      final starting = gps.start();
      gps.setLeg(1, leg());
      source.pending.single.complete(stream.stream);
      await starting;
      expect(gps.enabled, isTrue);
      expect(gps.legIndex, 1);
      await stream.close();
      await Future<void>.delayed(Duration.zero);
      expect(gps.enabled, isFalse);
      expect(gps.status, contains('terputus'));
      gps.dispose();
      routes.client.close();
    },
  );
  test('stop invalidates pending permission request without cancelling a later start', () async {
    final source = DelayedLocation();
    final routes = RouteService();
    final gps = GpsNavigation(source, routes)..setLeg(0, leg());
    final oldStart = gps.start();
    await gps.stop();
    final newStart = gps.start();
    final oldStream = StreamController<LocationFix>.broadcast();
    final newStream = StreamController<LocationFix>.broadcast();
    source.pending.first.complete(oldStream.stream);
    await oldStart;
    expect(gps.starting, isTrue);
    expect(gps.enabled, isFalse);
    source.pending.last.complete(newStream.stream);
    await newStart;
    expect(gps.enabled, isTrue);
    gps.dispose();
    routes.client.close();
    await oldStream.close();
    await newStream.close();
  });
  test('stale fixes and a denied source never fabricate a location', () async {
    final stale = LocationFix(
      const LatLng(-5.15, 119.43),
      DateTime.now().subtract(const Duration(seconds: 16)),
      10,
      0,
      0,
    );
    expect(stale.usable(DateTime.now()), isFalse);
    expect(
      GpsNavigation.project(leg(), const LatLng(-5.15, 119.435), 0).$2,
      lessThan(1),
    );
  });
}
