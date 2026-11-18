import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/features/controllers/navigation_simulation_controller.dart';
import 'package:kurir_go/features/shared/makassar_map_view.dart';

import 'navigation_simulation_test.dart' show fixtureRoute;
import 'support/offline_map.dart';

void main() {
  testWidgets(
    'Pan, pinch, rotate, zoom and recenter preserve journey progress',
    (tester) async {
      final route = fixtureRoute();
      final s = NavigationSimulationController(route.legs.first);
      addTearDown(s.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 393,
              height: 600,
              child: MakassarMapView(
                route: route,
                simulation: s,
                mode: MapDisplayMode.navigation,
                tileProvider: OfflineTileProvider(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final controller = map.mapController!;
      expect(map.options.interactionOptions.flags, InteractiveFlag.all);
      final zoom = controller.camera.zoom;
      await tester.tap(find.byTooltip('Perbesar peta'));
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, zoom + 1);
      await tester.tap(find.byTooltip('Perkecil peta'));
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, zoom);
      await tester.dragFrom(const Offset(160, 280), const Offset(80, 35));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Kunci posisi kurir'), findsOneWidget);
      final panned = controller.camera.center;
      s.play();
      s.advance(const Duration(seconds: 1));
      s.pause();
      await tester.pumpAndSettle();
      expect(controller.camera.center, panned);
      final progress = s.traveled;
      await tester.tap(find.byTooltip('Kunci posisi kurir'));
      await tester.pumpAndSettle();
      expect(controller.camera.center, s.position);
      expect(s.traveled, progress);
      expect(controller.camera.zoom, zoom);
      final a = await tester.startGesture(const Offset(100, 280), pointer: 1);
      final b = await tester.startGesture(const Offset(220, 280), pointer: 2);
      await a.moveTo(const Offset(70, 230));
      await b.moveTo(const Offset(250, 330));
      await tester.pump(const Duration(milliseconds: 50));
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, isNot(zoom));
      expect(controller.camera.rotation.abs(), greaterThan(1));
      expect(s.traveled, progress);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
