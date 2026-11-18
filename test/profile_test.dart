import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/features/controllers/delivery_controller.dart';
import 'package:kurir_go/main.dart';

import 'support/offline_map.dart';

void main() {
  test('Profile edits preserve credentials and reject invalid updates', () {
    final c = DeliveryController();
    addTearDown(c.dispose);
    c.login('ardiansyah', '1234');
    c.updateProfile('Sari', '081234567890');
    c.login('ardiansyah', '1234');
    expect(c.account.fullName, 'Sari');
    expect(c.account.phone, '081234567890');
    expect(() => c.updateProfile('', ''), throwsArgumentError);
    expect(() => c.updateProfile('Other', 'bad'), throwsArgumentError);
    expect(c.account.fullName, 'Sari');
  });
  testWidgets('Profile navigation validates edits, saves and returns home', (
    tester,
  ) async {
    final c = DeliveryController()..login('ardiansyah', '1234');
    addTearDown(c.dispose);
    await tester.pumpWidget(offlineMaps(MyApp(controller: c)));
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/profile');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ubah Profil'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah Profil'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama Lengkap'),
      'Sari',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'WhatsApp (opsional)'),
      'bad',
    );
    await tester.ensureVisible(find.text('Simpan Perubahan Profil'));
    await tester.tap(find.text('Simpan Perubahan Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Nomor WhatsApp tidak valid.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'WhatsApp (opsional)'),
      '081234567890',
    );
    await tester.ensureVisible(find.text('Simpan Perubahan Profil'));
    await tester.tap(find.text('Simpan Perubahan Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Sari'), findsOneWidget);
    await tester.tap(find.text('Performa'));
    await tester.pumpAndSettle();
    expect(find.text('0 Box Selesai'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Halo, Sari!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
