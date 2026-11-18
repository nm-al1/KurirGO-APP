import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

typedef Json = Map<String, dynamic>;

class CourierStore {
  final Database db;
  final String owner;
  final bool localOnly;
  CourierStore(this.db, this.owner, {this.localOnly = false});

  Future<void> putLocal(String key, Json payload) => db.insert('cache', {
    'owner': '$owner:$key',
    'revision': 0,
    'payload': jsonEncode(payload),
  }, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<Json?> getLocal(String key) async {
    final rows = await db.query(
      'cache',
      where: 'owner = ?',
      whereArgs: ['$owner:$key'],
    );
    return rows.isEmpty
        ? null
        : jsonDecode(rows.single['payload'] as String) as Json;
  }

  Future<void> resetLocal(Json payload) => db.transaction((txn) async {
    await txn.delete(
      'cache',
      where: 'owner = ? OR owner LIKE ?',
      whereArgs: [owner, '$owner:%'],
    );
    await txn.delete('outbox', where: 'owner = ?', whereArgs: [owner]);
    await txn.insert('cache', {
      'owner': owner,
      'revision': 0,
      'payload': jsonEncode(payload),
    });
  });

  static Future<void> create(Database db, int version) async {
    await db.execute(
      'CREATE TABLE cache (owner TEXT PRIMARY KEY, revision INTEGER NOT NULL, payload TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE outbox (sequence INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT UNIQUE NOT NULL, owner TEXT NOT NULL, revision INTEGER NOT NULL, payload TEXT NOT NULL, conflict TEXT)',
    );
  }

  static Json empty() => {'orders': <dynamic>[], 'trips': <dynamic>[]};
  Future<Json> read() async {
    final rows = await db.query(
      'cache',
      where: 'owner = ?',
      whereArgs: [owner],
    );
    return rows.isEmpty
        ? empty()
        : jsonDecode(rows.single['payload'] as String) as Json;
  }

  Future<List<Map<String, Object?>>> pending() => db.query(
    'outbox',
    where: 'owner = ?',
    whereArgs: [owner],
    orderBy: 'sequence',
  );

  Future<void> save(Json state, {Json? previous}) => db.transaction((
    txn,
  ) async {
    final conflicts = await txn.query(
      'outbox',
      where: 'owner = ? AND conflict IS NOT NULL',
      whereArgs: [owner],
    );
    if (conflicts.isNotEmpty) {
      throw StateError(
        'Selesaikan konflik sinkronisasi sebelum mengubah data.',
      );
    }
    final rows = await txn.query(
      'cache',
      where: 'owner = ?',
      whereArgs: [owner],
    );
    final revision = rows.isEmpty ? 0 : rows.single['revision'] as int;
    if (previous != null &&
        jsonEncode(previous) !=
            (rows.isEmpty ? jsonEncode(empty()) : rows.single['payload'])) {
      throw StateError(
        'Data berubah saat sinkronisasi. Buka kembali halaman lalu coba lagi.',
      );
    }
    final payload = jsonEncode(state);
    if (!localOnly) {
      await txn.insert('outbox', {
        'id': const Uuid().v4(),
        'owner': owner,
        'revision': revision,
        'payload': payload,
      });
    }
    await txn.insert('cache', {
      'owner': owner,
      'revision': revision + 1,
      'payload': payload,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  });

  Future<void> acknowledge(String id) => db.delete(
    'outbox',
    where: 'owner = ? AND id = ?',
    whereArgs: [owner, id],
  );
  Future<void> conflict(String id, String reason) => db.update(
    'outbox',
    {'conflict': reason},
    where: 'owner = ? AND id = ?',
    whereArgs: [owner, id],
  );
  Future<void> receive(int revision, Json state) => db.transaction((txn) async {
    if ((await txn.query(
      'outbox',
      where: 'owner = ?',
      whereArgs: [owner],
      limit: 1,
    )).isNotEmpty) {
      return;
    }
    final cached = await txn.query(
      'cache',
      where: 'owner = ?',
      whereArgs: [owner],
    );
    if (cached.isNotEmpty && (cached.single['revision'] as int) > revision) {
      return;
    }
    await txn.insert('cache', {
      'owner': owner,
      'revision': revision,
      'payload': jsonEncode(state),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  });
}
