import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/data/dummy_makassar_data.dart';
import 'package:kurir_go/features/controllers/navigation_simulation_controller.dart';
import 'package:kurir_go/features/live_navigation/navigation_hud.dart';
import 'package:kurir_go/features/live_navigation/navigation_stage.dart';
import 'package:kurir_go/features/shared/makassar_map_view.dart';
import 'package:kurir_go/features/shared/rider_puck.dart';

import 'navigation_simulation_test.dart' show fixtureRoute;
import 'support/offline_map.dart';

class BrokenTiles extends TileProvider {
  static final brokenImage = MemoryImage(Uint8List(0));
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      brokenImage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  });
  testWidgets('Failed basemap keeps stored road overlays and controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Inter', brightness: Brightness.dark),
        home: Scaffold(
          body: MakassarMapView(
            route: fixtureRoute(),
            tileProvider: BrokenTiles(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Peta dasar tidak tersedia. Rute tersimpan tetap aktif.'),
      findsOneWidget,
    );
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(find.byType(MarkerLayer), findsOneWidget);
    await tester.tap(find.byTooltip('Perbesar peta'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Rider stays below enlarged HUD on 320px with 1.6 text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final route = fixtureRoute();
    final s = NavigationSimulationController(route.legs.first);
    addTearDown(s.dispose);
    await tester.pumpWidget(
      offlineMaps(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter', brightness: Brightness.dark),
          home: Scaffold(
            body: SingleChildScrollView(
              child: NavigationStage(
                roads: route,
                simulation: s,
                destination: DummyMakassarData.waypoints[2],
                title: 'Stop #1 - Outlet Antang',
                onToggle: () {},
                onReplay: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rider = tester.getCenter(find.byType(RiderPuck));
    final hud = tester.getRect(find.byType(NavigationHud));
    expect(rider.dy, greaterThan(hud.bottom + 32));
    expect(rider.dx, inInclusiveRange(32, 288));
    expect(rider.dy, lessThan(640 - 32));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
