import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kurir_go/data/route_service.dart';
import 'package:kurir_go/data/models/road_route.dart';

import 'courier_runtime_test.dart' show orderInput;

void main() {
  test(
    'shared coordinates produce one stop and variable closed road legs',
    () async {
      final client = MockClient((request) async {
        final points = request.url.pathSegments.last
            .split(';')
            .map((p) => p.split(',').map(double.parse).toList())
            .toList();
        if (request.url.path.contains('/table/')) {
          expect(points.length, 3);
          return http.Response(
            jsonEncode({
              'code': 'Ok',
              'distances': [
                [0, 100, 200],
                [100, 0, 120],
                [200, 120, 0],
              ],
            }),
            200,
          );
        }
        expect(points.first, points.last);
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 420,
                'duration': 80,
                'legs': [
                  for (var i = 1; i < points.length; i++)
                    {
                      'steps': [
                        {
                          'geometry': {
                            'coordinates': [points[i - 1], points[i]],
                          },
                          'maneuver': {'type': 'depart'},
                          'name': 'Test road',
                        },
                      ],
                    },
                ],
              },
            ],
          }),
          200,
        );
      });
      final route = await RouteService(client: client).calculate([
        {...orderInput('A'), 'id': 'a'},
        {...orderInput('B'), 'id': 'b'},
        {...orderInput('C'), 'id': 'c', 'lat': -5.16},
      ]);
      expect((route['stops'] as List).length, 2);
      expect(
        (route['stops'] as List).any(
          (s) => s.length == 2 && s.contains('a') && s.contains('b'),
        ),
        isTrue,
      );
      expect(RoadRoute.fromJson(route['geometry']).legs.length, 3);
    },
  );
  test(
    'unreachable and offline routes fail without straight-line fallback',
    () async {
      final service = RouteService(
        client: MockClient(
          (_) async => http.Response(
            '{"code":"Ok","distances":[[0,null],[null,0]]}',
            200,
          ),
        ),
      );
      await expectLater(
        service.calculate([
          {...orderInput('A'), 'id': 'a'},
        ]),
        throwsStateError,
      );
      final unavailable = RouteService(
        client: MockClient((_) async => http.Response('unavailable', 503)),
      );
      await expectLater(
        unavailable.calculate([
          {...orderInput('A'), 'id': 'a'},
        ]),
        throwsStateError,
      );
      await expectLater(
        service.calculate(
          List.generate(21, (i) => {...orderInput('A'), 'id': '$i'}),
        ),
        throwsStateError,
      );
    },
  );
}
