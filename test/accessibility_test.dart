import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/main.dart';
import 'package:kurir_go/core/theme/app_colors.dart';

void main() {
  test('Kontras pasangan aksi utama melebihi AAA', () {
    final ratio =
        (AppColors.electricLime.computeLuminance() + .05) /
        (AppColors.matteCharcoal.computeLuminance() + .05);
    expect(ratio, greaterThanOrEqualTo(7));
  });
  testWidgets(
    'Login memenuhi target sentuh, kontras dan keyboard layar kecil',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      try {
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        semantics.dispose();
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.showKeyboard(find.widgetWithText(TextFormField, 'PIN'));
      await tester.pumpAndSettle();
      final action = find.text('Masuk ke Sistem Pengantaran');
      await tester.scrollUntilVisible(
        action,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Halo, Ardiansyah!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
