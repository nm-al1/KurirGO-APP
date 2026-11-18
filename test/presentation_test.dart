import 'dart:io';

import 'package:kurir_go/data/models/road_route.dart';

import 'support/offline_map.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/main.dart';
import 'package:kurir_go/features/controllers/delivery_controller.dart';
import 'package:kurir_go/data/models/payment_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await RoadRoute.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final size in [const Size(393, 852), const Size(320, 640)]) {
    testWidgets('Tujuh layar tanpa overflow pada $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (size.width == 320) {
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      final c = DeliveryController();
      addTearDown(c.dispose);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: offlineMaps(MyApp(controller: c)),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/brand/kurirgo_icon.png'),
          boundary.currentContext!,
        ),
      );
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        const directory = String.fromEnvironment('PREVIEW_DIR');
        if (directory.isNotEmpty) {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('$directory/${name}_${size.width.toInt()}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }

      Future<void> route(String name) async {
        tester
            .state<NavigatorState>(find.byType(Navigator))
            .pushNamedAndRemoveUntil(name, (_) => false);
        await tester.pumpAndSettle();
      }

      await capture('00a_login');
      await route('/register');
      await capture('00b_register');
      c.login('ardiansyah', '1234');
      await route('/dashboard');
      await capture('01_dashboard');
      await route('/performance');
      await capture('06_performance');
      await route('/profile');
      await capture('07_profile');
      await route('/edit-profile');
      await capture('08_edit_profile');
      await route('/verification');
      await capture('02_verification');
      c.toggleOrderVerification('BRW-01');
      c.toggleOrderVerification('BRW-02');
      c.calculateOptimalRoute();
      await route('/route-preview');
      await capture('03_route_preview');
      c.startNavigation();
      await route('/navigation');
      await capture('04_navigation');
      final money = find.widgetWithText(TextField, 'Uang Diterima (Rp)');
      await tester.scrollUntilVisible(
        money,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(money, '200000');
      await capture('04_cashier');
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.showKeyboard(money);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Selesaikan Pengantaran Stop Ini'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      tester.testTextInput.hide();
      c.completeCurrentStop(
        PaymentDetail(
          nominalTagihan: 150000,
          metode: PaymentMethod.cod,
          nominalDiterima: 200000,
          status: PaymentStatus.paid,
        ),
        orderId: 'BRW-02',
      );
      c.completeCurrentStop(c.currentOrder!.payment, orderId: 'BRW-01');
      await route('/history');
      await capture('05_history');
      await tester.scrollUntilVisible(
        find.text('5 Box / 100%'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('5 Box / 100%'), findsOneWidget);
      expect(find.text('28.5 KM'), findsOneWidget);
      expect(find.text('1 Jam 10 Mnt'), findsOneWidget);
    });
  }
}
