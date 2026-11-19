import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kurir_go/data/route_service.dart';
import 'package:kurir_go/features/controllers/gps_navigation.dart';
import 'package:kurir_go/features/controllers/navigation_simulation_controller.dart';
import 'package:kurir_go/features/shared/makassar_map_view.dart';

import 'gps_navigation_test.dart' show FakeLocation;
import 'navigation_simulation_test.dart' show fixtureRoute;
import 'support/offline_map.dart';

void main() {
  testWidgets(
    'switching to GPS before a fix keeps every leg and overview control',
    (tester) async {
      final route = fixtureRoute(),
          source = FakeLocation(),
          service = RouteService();
      final gps = GpsNavigation(source, service);
      final sim = NavigationSimulationController(route.legs.first);
      gps.setLeg(0, route.legs.last);
      Future<void> mount(bool real) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 393,
                height: 600,
                child: MakassarMapView(
                  route: route,
                  simulation: real ? null : sim,
                  gps: real ? gps : null,
                  mode: MapDisplayMode.navigation,
                  tileProvider: OfflineTileProvider(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await mount(false);
      await mount(true);
      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines.length, route.legs.length);
      expect(layer.polylines.first.points, route.legs.last.points);
      for (var i = 1; i < route.legs.length; i++) {
        expect(layer.polylines[i].points, route.legs[i].points);
      }
      expect(layer.polylines.first.color, const Color(0xFFC6FF00));
      for (final line in layer.polylines.skip(1)) {
        expect(line.color, const Color(0xFF64748B));
      }
      await gps.start();
      gps.fix = LocationFix(
        const LatLng(-5.18, 119.44),
        DateTime.now(),
        10,
        0,
        0,
      );
      gps.setLeg(1, route.legs.last);
      await tester.pumpAndSettle();
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(gps.onRoute, isFalse);
      expect(map.mapController!.camera.center, gps.fix!.point);
      expect(map.mapController!.camera.zoom, 16);
      await tester.tap(find.byTooltip('Lihat seluruh rute'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Kunci posisi kurir'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      gps.dispose();
      sim.dispose();
      service.client.close();
    },
  );
}
