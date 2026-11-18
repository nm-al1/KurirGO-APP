import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/features/shared/external_actions.dart';
import 'package:kurir_go/data/dummy_makassar_data.dart';

void main() {
  test('URI telepon, WhatsApp dan Maps memakai fixture pelanggan aktif', () {
    expect(callUri('0812-9988-7766').toString(), 'tel:+6281299887766');
    expect(
      chatUri('+62 812 9988 7766').toString(),
      'https://wa.me/6281299887766',
    );
    final uri = mapsUri(
      DummyMakassarData.waypoints[2],
      origin: const LatLng(-5.1560, 119.4350),
    );
    expect(uri.queryParameters['destination'], '-5.1685,119.482');
    expect(uri.queryParameters['travelmode'], 'driving');
    expect(uri.queryParameters['origin'], '-5.156,119.435');
    expect(uri.queryParameters['dir_action'], 'navigate');
  });
  testWidgets('Pembuka URI dimock dan kegagalan menyediakan salin', (
    tester,
  ) async {
    Uri? captured;
    var success = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => launchCourierLink(
                context,
                callUri('08123456789'),
                '08123456789',
                opener: (uri) async {
                  captured = uri;
                  return success;
                },
              ),
              child: const Text('Telepon'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Telepon'));
    await tester.pumpAndSettle();
    expect(captured!.scheme, 'tel');
    expect(find.text('Salin'), findsNothing);
    success = false;
    await tester.tap(find.text('Telepon'));
    await tester.pumpAndSettle();
    expect(find.text('Salin'), findsOneWidget);
  });
}
