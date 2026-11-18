import 'package:kurir_go/data/models/road_route.dart';

import 'support/offline_map.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/main.dart';
import 'package:kurir_go/features/controllers/delivery_controller.dart';

Future<void> tapLabel(WidgetTester tester, String text) async {
  final baseFinder = find.text(text);
  if (baseFinder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      baseFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final finder = baseFinder.first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(RoadRoute.load);
  testWidgets('Login ke dashboard, verifikasi, kasir, setoran dan rute baru', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = DeliveryController();
    addTearDown(c.dispose);
    await tester.pumpWidget(offlineMaps(MyApp(controller: c)));
    expect(find.text('Masuk Akun Kurir'), findsOneWidget);
    await tapLabel(tester, 'Masuk ke Sistem Pengantaran');
    expect(find.text('Halo, Ardiansyah!'), findsOneWidget);
    await tapLabel(tester, 'Mulai Muat Barang (LIFO Stack)');
    final action = find.widgetWithText(FilledButton, 'Urutkan Rute Loop (TSP)');
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    for (final id in ['BRW-01', 'BRW-02']) {
      final box = find.byWidgetPredicate(
        (w) => w is Checkbox && w.semanticLabel == 'Verifikasi $id',
      );
      await tester.ensureVisible(box);
      await tester.pumpAndSettle();
      await tester.tap(box);
      await tester.pumpAndSettle();
    }
    await tapLabel(tester, 'Urutkan Rute Loop (TSP)');
    expect(find.text('28.50 KM · Loop Tertutup'), findsOneWidget);
    await tapLabel(tester, 'Mulai Navigasi Rute');
    expect(find.text('Ibu Nurul (Outlet Antang)'), findsOneWidget);
    final money = find.widgetWithText(TextField, 'Uang Diterima (Rp)');
    await tester.scrollUntilVisible(
      money,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(money, '200000');
    await tester.pumpAndSettle();
    expect(find.text('Kembalian: Rp 50.000'), findsOneWidget);
    await tapLabel(tester, 'Selesaikan Pengantaran Stop Ini');
    expect(c.currentOrder!.customerName, 'Bpk. Rahmat (Outlet Sudiang)');
    await tapLabel(tester, 'Selesaikan Pengantaran Stop Ini');
    expect(find.text('Riwayat Pengantaran'), findsOneWidget);
    expect(c.cashToDeposit, 150000);
    expect(c.nonCashTotal, 225000);
    await tapLabel(tester, 'Setor Tunai ke Kasir Depot');
    await tapLabel(tester, 'Belum');
    expect(c.isSettled, isFalse);
    await tapLabel(tester, 'Setor Tunai ke Kasir Depot');
    await tapLabel(tester, 'Sudah Kembali & Setor');
    expect(c.isSettled, isTrue);
    await tapLabel(tester, 'Mulai Rute Baru');
    expect(c.isAllOrdersVerified, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Registrasi validasi, SOP dan nama kurir baru', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tapLabel(tester, 'Daftar Akun KurirGO');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama Lengkap'),
      'Sari',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'sari',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Buat PIN'),
      '5678',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Konfirmasi PIN'),
      '5678',
    );
    final sop = find.byType(CheckboxListTile);
    await tester.ensureVisible(sop);
    await tester.tap(sop);
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Daftar Akun KurirGO');
    expect(find.text('Halo, Sari!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
