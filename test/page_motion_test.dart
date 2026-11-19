import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/features/production/app.dart';

void main() {
  testWidgets('page slides eight pixels, settles and returns to its caller', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                openPage<void>(context, const Scaffold(body: Text('Tujuan'))),
            child: const Text('Buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final initial = tester.getTopLeft(find.text('Tujuan')).dy;
    await tester.pump(const Duration(milliseconds: 80));
    final middle = tester.getTopLeft(find.text('Tujuan')).dy;
    await tester.pumpAndSettle();
    final end = tester.getTopLeft(find.text('Tujuan')).dy;
    expect(initial - end, closeTo(8, .3));
    expect(middle, inExclusiveRange(end, initial));
    Navigator.pop(tester.element(find.text('Tujuan')));
    await tester.pumpAndSettle();
    expect(find.text('Buka'), findsOneWidget);
  });
}

