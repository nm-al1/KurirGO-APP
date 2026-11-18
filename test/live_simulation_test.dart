import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/data/models/road_route.dart';
import 'package:kurir_go/data/models/payment_model.dart';
import 'package:kurir_go/features/controllers/delivery_controller.dart';
import 'package:kurir_go/features/live_navigation/live_navigation_screen.dart';
import 'package:kurir_go/features/live_navigation/navigation_hud.dart';
import 'package:kurir_go/features/shared/delivery_scope.dart';

import 'support/offline_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(RoadRoute.load);
  testWidgets(
    'Play, pause, replay, background and next stop preserve delivery data',
    (tester) async {
      final c = DeliveryController();
      addTearDown(c.dispose);
      c.login('ardiansyah', '1234');
      for (final order in c.orders) {
        c.toggleOrderVerification(order.id);
      }
      c.calculateOptimalRoute();
      c.startNavigation();
      await tester.pumpWidget(
        offlineMaps(
          DeliveryScope(
            controller: c,
            child: const MaterialApp(home: LiveNavigationScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final s = tester
          .widget<NavigationHud>(find.byType(NavigationHud))
          .simulation;
      await tester.tap(find.text('Putar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(s.traveled, greaterThan(0));
      await tester.tap(find.text('Jeda'));
      await tester.pumpAndSettle();
      final paused = s.traveled;
      await tester.pump(const Duration(seconds: 2));
      expect(s.traveled, paused);
      await tester.tap(find.byTooltip('Ulangi simulasi'));
      await tester.pumpAndSettle();
      expect(s.traveled, 0);
      expect(c.currentStopIndex, 0);
      expect(c.cargoStack.length, 2);
      await tester.tap(find.text('Putar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(s.running, isFalse);
      final background = s.traveled;
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(s.traveled, background);
      c.completeCurrentStop(
        PaymentDetail(
          nominalTagihan: 150000,
          nominalDiterima: 200000,
          metode: PaymentMethod.cod,
          status: PaymentStatus.paid,
        ),
        orderId: 'BRW-02',
      );
      await tester.pumpAndSettle();
      final next = tester
          .widget<NavigationHud>(find.byType(NavigationHud))
          .simulation;
      expect(next, isNot(same(s)));
      expect(next.traveled, 0);
      expect(next.running, isFalse);
      expect(c.currentOrder!.id, 'BRW-01');
      expect(c.cashToDeposit, 150000);
      await tester.tap(find.text('Putar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
