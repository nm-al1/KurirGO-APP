import 'dart:async';

import 'support/offline_map.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kurir_go/data/geocoding_service.dart';
import 'package:kurir_go/features/production/order_form.dart';

class FakeGeocoder extends GeocodingService {
  final initial = Completer<PlaceLocation?>();
  final requests = <String, Completer<List<PlaceLocation>>>{};
  FakeGeocoder(super.backend);
  @override
  Future<PlaceLocation?> reverse(LatLng point) => initial.future;
  @override
  Future<List<PlaceLocation>> search(String query) =>
      (requests[query] = Completer<List<PlaceLocation>>()).future;
}

void main() {
  testWidgets(
    'latest search and selected pin survive delayed replies on small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final backend = SupabaseClient(
        'https://demo.invalid',
        'demo',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final service = FakeGeocoder(backend);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: offlineMaps(
            PinPage(initial: const LatLng(-5.156, 119.435), service: service),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Losari');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.enterText(find.byType(TextField), 'Pettarani');
      await tester.pump(const Duration(milliseconds: 550));
      service.requests['Pettarani']!.complete([
        const PlaceLocation(LatLng(-5.15, 119.44), 'Jalan Pettarani'),
      ]);
      await tester.pump();
      service.requests['Losari']!.complete([
        const PlaceLocation(LatLng(-5.1, 119.4), 'Hasil lama'),
      ]);
      await tester.pump();
      expect(find.text('Hasil lama'), findsNothing);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Gunakan lokasi ini'), findsNothing);
      await tester.tap(find.text('Jalan Pettarani'));
      await tester.pump();
      tester.view.resetViewInsets();
      await tester.pump();
      service.initial.complete(
        const PlaceLocation(LatLng(-5.156, 119.435), 'Alamat lama'),
      );
      await tester.pump();
      expect(find.text('Alamat lama'), findsNothing);
      expect(find.text('Jalan Pettarani'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Gunakan lokasi ini'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      backend.auth.dispose();
    },
  );
}
