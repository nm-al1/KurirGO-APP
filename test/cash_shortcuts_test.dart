import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/data/dummy_makassar_data.dart';
import 'package:kurir_go/data/models/payment_model.dart';
import 'package:kurir_go/features/live_navigation/payment_console.dart';

void main() {
  testWidgets(
    'Quick amounts replace, validate underpayment and calculate change',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                PaymentConsole(
                  order: DummyMakassarData.createOrders().last,
                  onComplete: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      final input = find.widgetWithText(TextField, 'Uang Diterima (Rp)');
      final action = find.widgetWithText(
        FilledButton,
        'Selesaikan Pengantaran Stop Ini',
      );
      expect(tester.widget<TextField>(input).decoration!.prefixText, 'Rp  ');
      for (final entry in [
        ('Rp 200.000', '200.000', true),
        ('Rp 50.000', '50.000', false),
        ('Rp 100.000', '100.000', false),
        ('Rp 150.000', '150.000', true),
        ('Uang Pas', '150.000', true),
      ]) {
        final chip = find.widgetWithText(ActionChip, entry.$1);
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(input).controller!.text, entry.$2);
        expect(tester.widget<FilledButton>(action).onPressed != null, entry.$3);
        expect(
          find.text('Kembalian: Rp ${entry.$2 == '200.000' ? '50.000' : '0'}'),
          findsOneWidget,
        );
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.showKeyboard(input);
      await tester.pumpAndSettle();
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Prepaid Sudiang keeps the same payment and transaction reference',
    (tester) async {
      final order = DummyMakassarData.createOrders().first;
      order.payment = PaymentDetail(
        nominalTagihan: 225000,
        metode: PaymentMethod.transfer,
        status: PaymentStatus.verified,
        referensiTransaksi: 'BANK-001',
      );
      PaymentDetail? completed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                PaymentConsole(
                  order: order,
                  onComplete: (payment) => completed = payment,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Selesaikan Pengantaran Stop Ini'));
      expect(completed, same(order.payment));
      expect(completed!.referensiTransaksi, 'BANK-001');
      expect(completed!.status, PaymentStatus.verified);
    },
  );
}
