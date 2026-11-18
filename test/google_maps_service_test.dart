import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kurir_go/data/geocoding_service.dart';
import 'package:kurir_go/features/shared/google_route_view.dart';
import 'package:kurir_go/features/controllers/gps_navigation.dart';
import 'package:kurir_go/data/route_service.dart';

import 'gps_navigation_test.dart' show FakeLocation;
import 'navigation_simulation_test.dart' show fixtureRoute;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'autocomplete fetches details only for selected result and rotates session',
    () async {
      final calls = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        expect(request.url.path, endsWith('/google-geocode'));
        final input = jsonDecode(request.body) as Map<String, dynamic>;
        calls.add(input);
        return http.Response(
          jsonEncode({
            'results': input.containsKey('query')
                ? [
                    {
                      'placeId': 'perdosfit-example',
                      'formatted': 'Perdosfit Makassar',
                    },
                  ]
                : [
                    {
                      'placeId': 'perdosfit-example',
                      'lat': -5.15,
                      'lon': 119.44,
                      'formatted': 'Jalan contoh, Makassar',
                    },
                  ],
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });
      final backend = SupabaseClient(
        'https://example.invalid',
        'anon',
        httpClient: client,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final service = GeocodingService(backend, google: true);
      final suggestions = await service.search('Perdosfit');
      expect(calls.length, 1);
      expect(suggestions.single.point, isNull);
      final picked = await service.resolve(suggestions.single);
      expect(picked.point!.latitude, -5.15);
      expect(picked.address, 'Jalan contoh, Makassar');
      expect(calls.length, 2);
      expect(calls[0]['sessionToken'], calls[1]['sessionToken']);
      await service.search('Losari');
      expect(calls[2]['sessionToken'], isNot(calls[0]['sessionToken']));
      service.dispose();
      backend.auth.dispose();
      client.close();
    },
  );
  test(
    'without Google activation the existing geocode backend remains usable',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, endsWith('/geocode'));
        return http.Response(
          jsonEncode({
            'results': [
              {'lat': -5.15, 'lon': 119.44, 'formatted': 'Makassar'},
            ],
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });
      final backend = SupabaseClient(
        'https://example.invalid',
        'anon',
        httpClient: client,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final service = GeocodingService(backend);
      final found = await service.search('Makassar');
      expect(found.single.point!.latitude, -5.15);
      expect((await service.resolve(found.single)).address, 'Makassar');
      service.dispose();
      backend.auth.dispose();
      client.close();
    },
  );
  test(
    'Google route composition retains every leg and bounds contain all stops',
    () {
      final route = fixtureRoute();
      final service = RouteService();
      final gps = GpsNavigation(FakeLocation(), service);
      gps.setLeg(0, route.legs.last);
      final displayed = routeWithGps(route, gps);
      expect(displayed.legs.length, route.legs.length);
      expect(displayed.legs.first, route.legs.last);
      final bounds = googleRouteBounds(displayed);
      for (final p in displayed.legs.expand((l) => l.points)) {
        expect(
          p.latitude,
          inInclusiveRange(
            bounds.southwest.latitude,
            bounds.northeast.latitude,
          ),
        );
        expect(
          p.longitude,
          inInclusiveRange(
            bounds.southwest.longitude,
            bounds.northeast.longitude,
          ),
        );
      }
      gps.dispose();
      service.client.close();
    },
  );
}
