import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/features/live_navigation/payment_console.dart';
import 'package:kurir_go/data/dummy_makassar_data.dart';
import 'package:kurir_go/data/models/payment_model.dart';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final method in PaymentMethod.values) {
    testWidgets('Kasir ${method.name} membutuhkan konfirmasi yang sesuai', (
      tester,
    ) async {
      PaymentDetail? completed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                PaymentConsole(
                  order: DummyMakassarData.createOrders().last,
                  onComplete: (p) => completed = p,
                ),
              ],
            ),
          ),
        ),
      );
      final choice = find.widgetWithText(
        ChoiceChip,
        ['COD', 'Tunai', 'QRIS', 'Transfer'][method.index],
      );
      await reveal(tester, choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      final action = find.widgetWithText(
        FilledButton,
        'Selesaikan Pengantaran Stop Ini',
      );
      await reveal(tester, action);
      expect(tester.widget<FilledButton>(action).onPressed, isNull);
      if (method == PaymentMethod.cod || method == PaymentMethod.cash) {
        final input = find.widgetWithText(TextField, 'Uang Diterima (Rp)');
        await reveal(tester, input);
        await tester.enterText(input, '100000');
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(action).onPressed, isNull);
        await tester.enterText(input, '200000');
        await tester.pumpAndSettle();
      } else {
        final checkbox = find.byType(CheckboxListTile);
        await reveal(tester, checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      }
      await reveal(tester, action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(completed!.metode, method);
      expect(completed!.status, PaymentStatus.paid);
      expect(
        completed!.uangKembalian,
        method == PaymentMethod.cod || method == PaymentMethod.cash ? 50000 : 0,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Sudiang lunas; ganti metode membutuhkan konfirmasi baru', (
    tester,
  ) async {
    final order = DummyMakassarData.createOrders().first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [PaymentConsole(order: order, onComplete: (_) {})],
          ),
        ),
      ),
    );
    final action = find.widgetWithText(
      FilledButton,
      'Selesaikan Pengantaran Stop Ini',
    );
    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tunai'));
    await tester.pumpAndSettle();
    await reveal(tester, action);
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    expect(order.payment.metode, PaymentMethod.qris);
  });
}
