import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kurir_go/data/courier_store.dart';
import 'package:kurir_go/data/route_service.dart';
import 'package:kurir_go/features/controllers/courier_runtime.dart';
import 'package:kurir_go/features/production/app.dart';
import 'package:kurir_go/features/production/auth_page.dart';
import 'package:kurir_go/features/production/home.dart';
import 'package:kurir_go/features/production/order_form.dart';
import 'package:kurir_go/features/production/trip_page.dart';
import 'package:kurir_go/features/production/figcraft_widgets.dart';

import 'support/offline_map.dart';

import 'courier_runtime_test.dart' show orderInput;

void main() {
  late Json cachedGeometry;
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  setUpAll(() async {
    cachedGeometry = jsonDecode(
      await rootBundle.loadString('assets/routes/makassar_loop.json'),
    ) as Json;
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final size in [const Size(393, 852), const Size(320, 640)]) {
    testWidgets(
      'production forms and permanent tabs fit $size with keyboard and reduced motion',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (size.width == 320) {
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        final boundary = GlobalKey();
        final backend = SupabaseClient(
          'https://example.test',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        Future<void> mount(Widget page) async {
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: offlineMaps(
                MaterialApp(
                  theme: courierTheme(),
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: true),
                    child: child!,
                  ),
                  home: page,
                ),
              ),
            ),
          );
          await tester.runAsync(() async {
            await precacheImage(
              const AssetImage('assets/brand/kurirgo_icon.png'),
              boundary.currentContext!,
            );
          });
          await tester.pumpAndSettle();
        }

        Future<void> capture(String name) async {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          const directory = String.fromEnvironment('PREVIEW_DIR');
          if (directory.isNotEmpty) {
            final render =
                boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            render.markNeedsPaint();
            await tester.pump();
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

        await mount(AuthPage(backend: backend));
        await capture('live_login');
        await tester.ensureVisible(find.text('Belum punya akun? Daftar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Belum punya akun? Daftar'));
        await tester.pumpAndSettle();
        await capture('live_register');
        expect(
          find.widgetWithText(TextFormField, 'Nama kurir'),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == 'Email',
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Daftar').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Daftar').last);
        await tester.pumpAndSettle();
        expect(find.text('Nama kurir wajib diisi'), findsOneWidget);
        late Database db;
        late CourierRuntime c;
        await tester.runAsync(() async {
          db = await databaseFactoryFfi.openDatabase(
            inMemoryDatabasePath,
            options: OpenDatabaseOptions(
              version: 1,
              onCreate: CourierStore.create,
            ),
          );
          c = CourierRuntime(CourierStore(db, 'one'), backend, RouteService());
          await c.load();
          await c.saveOrder(orderInput('Ibu Penerima'));
        });
        await mount(CourierHome(runtime: c));
        expect(find.byType(DeliverySummary), findsOneWidget);
        expect(find.byType(FigcraftTabs), findsOneWidget);
        final nav = find.byType(FigcraftTabs);
        for (final name in ['Riwayat', 'Performa', 'Profil', 'Home']) {
          final label = find.descendant(of: nav, matching: find.text(name));
          final paragraph = tester.renderObject<RenderParagraph>(label);
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: name.length),
          );
          expect(boxes.map((box) => box.top).toSet(), hasLength(1));
          await tester.tap(label);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pumpAndSettle();
        expect(find.byType(DeliverySummary), findsOneWidget);
        await capture('live_home');
        for (final name in ['Riwayat', 'Performa', 'Profil', 'Home']) {
          await tester.tap(find.text(name).last);
          await tester.pumpAndSettle();
          await capture('live_${name.toLowerCase()}');
        }
        await mount(EditCourierProfile(runtime: c));
        expect(find.text('Ganti foto'), findsOneWidget);
        await capture('live_edit_profile');
        await mount(OrderForm(runtime: c));
        expect(find.widgetWithText(TextFormField, 'Latitude'), findsNothing);
        expect(find.widgetWithText(TextFormField, 'Longitude'), findsNothing);
        await capture('live_add_order');
        final bill = find.widgetWithText(TextFormField, 'Tagihan');
        await tester.scrollUntilVisible(
          bill,
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.enterText(bill, '150000');
        expect(tester.widget<TextFormField>(bill).controller!.text, '150.000');
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Simpan pesanan'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await capture('live_order_keyboard');
        tester.view.resetViewInsets();
        await tester.runAsync(
          () => c.saveOrder({...orderInput('Bapak Kedua'), 'lat': -5.20}),
        );
        final ids = c.orders.map((o) => o['id'] as String).toList();
        final route = <String, dynamic>{
          'geometry': cachedGeometry,
          'stops': [
            [ids.first],
            [ids.last],
          ],
          'distance': 40930,
          'duration': 4200,
          'algorithm': 'Held-Karp',
        };
        await mount(TripPreparation(runtime: c, route: route, ids: ids));
        await capture('live_verification');
        for (var i = 0; i < ids.length; i++) {
          final checkbox = find.byType(CheckboxListTile).at(i);
          await tester.ensureVisible(checkbox);
          await tester.pumpAndSettle();
          await tester.tap(checkbox);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Urutkan Rute Loop (TSP)'));
        await tester.pumpAndSettle();
        await capture('live_route_preview');
        await tester.runAsync(() => c.startTrip(route, ids));
        await mount(TripPage(runtime: c));
        await capture('live_navigation');
        await tester.pumpWidget(const SizedBox.shrink());
        late CourierRuntime demo;
        await tester.runAsync(() async {
          demo = CourierRuntime(
            CourierStore(db, 'layout-demo', localOnly: true),
            backend,
            RouteService(),
          );
          await demo.load();
        });
        await mount(CourierHome(runtime: demo));
        expect(find.byType(DeliverySummary), findsOneWidget);
        expect(find.byType(FigcraftTabs), findsOneWidget);
        await capture('demo_home');
        for (final name in ['Riwayat', 'Performa', 'Profil']) {
          await tester.tap(find.text(name).last);
          await tester.pumpAndSettle();
          await capture('demo_${name.toLowerCase()}');
        }
        await tester.pumpWidget(const SizedBox.shrink());
        demo.dispose();
        await tester.runAsync(() async {
          final operation = (await c.store.pending()).first;
          await c.store.conflict(
            operation['id'] as String,
            'Data ditolak server. Catatan lokal tetap disimpan; salin catatan untuk diperiksa sebelum melanjutkan.',
          );
          await c.load();
        });
        await mount(CourierHome(runtime: c));
        expect(find.textContaining('Data ditolak server.'), findsOneWidget);
        await tester.ensureVisible(find.text('Salin catatan konflik'));
        await capture('live_sync_blocked');
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData')
              copied = (call.arguments as Map)['text'] as String;
            return null;
          },
        );
        await tester.tap(find.text('Salin catatan konflik'));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(copied, contains('Ibu Penerima'));
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
        await tester.runAsync(db.close);
        backend.auth.dispose();
      },
    );
  }
}
