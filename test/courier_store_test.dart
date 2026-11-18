import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kurir_go/data/courier_store.dart';

void main() {
  sqfliteFfiInit();
  test('atomic outbox persists across restart and isolates accounts', () async {
    final dir = await Directory.systemTemp.createTemp('courier_store_test');
    final path = '${dir.path}/test.db';
    var db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: CourierStore.create),
    );
    var one = CourierStore(db, 'one');
    final state = {
      'orders': [
        {
          'id': 'a',
          'status': 'completed',
          'payment': {'received': 150000},
        },
      ],
      'trips': [],
    };
    await one.save(state);
    final operation = (await one.pending()).single;
    expect(operation['revision'], 0);
    expect(await CourierStore(db, 'two').read(), CourierStore.empty());
    await db.close();
    db = await databaseFactoryFfi.openDatabase(path);
    one = CourierStore(db, 'one');
    expect(await one.read(), state);
    expect((await one.pending()).single['id'], operation['id']);
    await one.receive(90, CourierStore.empty());
    expect(
      await one.read(),
      state,
      reason: 'Remote pull must never replace pending payments',
    );
    await one.conflict(operation['id'] as String, 'revision conflict');
    await expectLater(one.save(CourierStore.empty()), throwsStateError);
    expect(await one.read(), state);
    await CourierStore(db, 'two').acknowledge(operation['id'] as String);
    expect((await one.pending()).length, 1);
    await db.close();
    await dir.delete(recursive: true);
  });
  test(
    'stale snapshots are rejected and failed journal write rolls back cache',
    () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: 1, onCreate: CourierStore.create),
      );
      final store = CourierStore(db, 'one');
      await store.receive(4, {
        'orders': [
          {'id': 'remote'},
        ],
        'trips': [],
      });
      await expectLater(
        store.save(CourierStore.empty(), previous: CourierStore.empty()),
        throwsStateError,
      );
      expect(await store.pending(), isEmpty);
      await db.execute(
        "CREATE TRIGGER fail_outbox BEFORE INSERT ON outbox BEGIN SELECT RAISE(ABORT, 'disk failure'); END",
      );
      await expectLater(
        store.save(CourierStore.empty()),
        throwsA(isA<DatabaseException>()),
      );
      expect((await store.read())['orders'], [
        {'id': 'remote'},
      ]);
      await db.close();
    },
  );
}
