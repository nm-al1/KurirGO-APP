import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kurir_go/data/courier_store.dart';
import 'package:kurir_go/data/route_service.dart';
import 'package:kurir_go/features/controllers/courier_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test('demo seeds once, isolates data and has no server journal; reset restores fixture', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1, onCreate: CourierStore.create),
    );
    final backend = SupabaseClient(
      'https://demo.invalid',
      'demo',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final c = CourierRuntime(
      CourierStore(db, 'demo', localOnly: true),
      backend,
      RouteService(),
    );
    await c.load();
    expect(c.waiting.length, 6);
    final route = await c.calculateRoute(c.waiting);
    expect((route['stops'] as List).length, 5);
    expect((route['geometry']['route']['legs'] as List).length, 6);
    expect(c.history.length, 14);
    expect(c.trips.length, 7);
    expect(c.waiting.map((o) => '${o['lat']},${o['lng']}').toSet().length, 5);
    final seed = c.state['demoSeededAt'];
    final id = c.waiting.first['id'] as String;
    await c.cancel(id);
    await c.load();
    expect(c.waiting.length, 5);
    expect(c.state['demoSeededAt'], seed);
    expect(await c.store.pending(), isEmpty);
    await c.sync();
    expect(c.syncError, isNull);
    await c.updateProfile(
      'Kurir Contoh Baru',
      '08123456789',
      photo: Uint8List.fromList([1, 2, 3]),
    );
    await c.load();
    expect(c.fullName, 'Kurir Contoh Baru');
    expect(c.avatar, [1, 2, 3]);
    expect(c.phone, '08123456789');
    expect(await c.store.pending(), isEmpty);
    expect((await CourierStore(db, 'other').read())['orders'], isEmpty);
    await c.resetDemo();
    expect(c.waiting.length, 6);
    expect(c.history.length, 14);
    expect(c.fullName, 'Kurir Demo');
    expect(c.avatar, isNull);
    c.dispose();
    backend.auth.dispose();
    await db.close();
  });
}
