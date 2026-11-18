import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kurir_go/data/courier_store.dart';
import 'package:kurir_go/data/route_service.dart';
import 'package:kurir_go/features/controllers/courier_runtime.dart';

Json orderInput(String name) => {
  'recipient': name,
  'phone': '08123456789',
  'address': 'Jalan Test 1',
  'items': 'Brownies',
  'boxes': 3,
  'bill': 150000,
  'lat': -5.15,
  'lng': 119.45,
};
void main() {
  sqfliteFfiInit();
  late Database db;
  late CourierRuntime runtime;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1, onCreate: CourierStore.create),
    );
    runtime = CourierRuntime(
      CourierStore(db, 'one'),
      SupabaseClient('https://example.test', 'test-key'),
      RouteService(),
    );
    await runtime.load();
  });
  tearDown(() async {
    runtime.dispose();
    await db.close();
  });
  test('new orders queue, shared stop stays separate, LIFO, restart and settlement preserve history', () async {
    await runtime.saveOrder(orderInput('One'));
    await runtime.saveOrder(orderInput('Two'));
    final ids = runtime.orders.map((o) => o['id'] as String).toList();
    await runtime.startTrip({
      'stops': [ids],
      'distance': 1000,
    }, ids);
    await expectLater(
      runtime.deliver(ids.last, 'cash', 150000, ''),
      throwsStateError,
    );
    await runtime.saveOrder(orderInput('Next trip'));
    expect(runtime.waiting.length, 1);
    await expectLater(runtime.cancel(ids.first), throwsStateError);
    await expectLater(
      runtime.deliver(ids.first, 'cash', 100000, ''),
      throwsStateError,
    );
    await runtime.deliver(ids.first, 'cash', 200000, '');
    final completed = Map<String, dynamic>.from(runtime.order(ids.first));
    expect(runtime.history.single['payment']['received'], 200000);
    await expectLater(
      runtime.deliver(ids.first, 'cash', 200000, ''),
      throwsStateError,
    );
    await expectLater(runtime.settle(), throwsStateError);
    await expectLater(
      runtime.deliver(ids.last, 'transfer', null, ''),
      throwsStateError,
    );
    await runtime.deliver(ids.last, 'transfer', null, 'BANK-123');
    await runtime.settle();
    expect(runtime.activeTrip, isNull);
    final next = runtime.waiting.single['id'] as String;
    await runtime.startTrip(
      {
        'stops': [
          [next],
        ],
        'distance': 1000,
      },
      [next],
    );
    expect(runtime.history.length, 2);
    expect(runtime.order(ids.first), completed);
    final restored = await runtime.store.read();
    expect(
      (restored['orders'] as List)
          .where((o) => o['status'] == 'completed')
          .length,
      2,
    );
    expect((await runtime.store.pending()).length, 8);
  });
  test(
    'server text limits are checked before queueing, with trimmed input',
    () async {
      for (final entry in CourierRuntime.orderTextLimits.entries) {
        await expectLater(
          runtime.saveOrder({
            ...orderInput('Valid'),
            entry.key: 'a' * (entry.value + 1),
          }),
          throwsStateError,
        );
        expect(await runtime.store.pending(), isEmpty);
      }
      await runtime.saveOrder({
        ...orderInput('  Valid  '),
        'address': 'a' * 2000,
      });
      expect(runtime.orders.single['recipient'], 'Valid');
      await expectLater(runtime.startTrip({'stops': []}, []), throwsStateError);
      await expectLater(
        runtime.saveOrder(
          orderInput('Edited'),
          id: runtime.orders.single['id'],
        ),
        completes,
      );
    },
  );
  test('negative amounts and double submission cannot corrupt data', () async {
    await expectLater(
      runtime.saveOrder({...orderInput('Bad'), 'bill': -1}),
      throwsStateError,
    );
    final first = runtime.saveOrder(orderInput('First'));
    await expectLater(
      runtime.saveOrder(orderInput('Duplicate')),
      throwsStateError,
    );
    await first;
    expect(runtime.orders.length, 1);
  });
}
