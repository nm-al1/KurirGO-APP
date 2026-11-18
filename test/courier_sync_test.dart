import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kurir_go/data/courier_store.dart';
import 'package:kurir_go/data/route_service.dart';
import 'package:kurir_go/features/controllers/courier_runtime.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  sqfliteFfiInit();
  for (final failure in [
    'offline',
    'PGRST301',
    'P0001',
    'conflict',
    'lost-ack',
  ]) {
    test('sync preserves queued data across $failure and retry', () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: 1, onCreate: CourierStore.create),
      );
      addTearDown(() async {
        if (db.isOpen) await db.close();
      });
      var attempts = 0;
      var retry = false;
      var remoteRevision = 0;
      Json remote = CourierStore.empty();
      final accepted = <String>{};
      final operationIds = <String>[];
      final token =
          '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'one', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})))}.signature';
      Future<http.Response> handle(http.Request request) async {
        if (request.url.path.contains('/auth/')) {
          return http.Response(
            jsonEncode({
              'access_token': token,
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'one',
                'aud': 'authenticated',
                'app_metadata': {},
                'user_metadata': {},
                'created_at': '2026-11-18T00:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/rpc/')) {
          attempts++;
          final body = jsonDecode(request.body) as Json;
          operationIds.add(body['operation_id']);
          if (!retry) {
            if (failure == 'offline') throw http.ClientException('offline');
            if (failure == 'conflict') {
              return http.Response('{"conflict":true,"revision":9}', 200);
            }
            if (failure != 'lost-ack') {
              return http.Response(
                jsonEncode({'code': failure, 'message': 'rejected'}),
                failure == 'PGRST301' ? 401 : 400,
              );
            }
          }
          if (accepted.add(body['operation_id'])) {
            expect(body['expected_revision'], remoteRevision);
            remoteRevision++;
            remote = body['new_payload'];
          }
          if (!retry && failure == 'lost-ack') {
            throw http.ClientException('response lost after commit');
          }
          return http.Response(
            jsonEncode({'conflict': false, 'revision': remoteRevision}),
            200,
          );
        }
        return http.Response(
          jsonEncode({'revision': remoteRevision, 'payload': remote}),
          200,
        );
      }

      final transport = MockClient((request) async {
        final response = await handle(request);
        return http.Response(
          response.body,
          response.statusCode,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      });
      final backend = SupabaseClient(
        'https://example.test',
        'test-key',
        httpClient: transport,
      );
      await backend.auth.signInWithPassword(
        email: 'test@example.com',
        password: 'unused',
      );
      final store = CourierStore(db, 'one');
      final snapshot = {
        'orders': [
          {
            'id': 'pending',
            'payment': {'received': 150000},
          },
        ],
        'trips': [],
      };
      await store.save(snapshot);
      final runtime = CourierRuntime(store, backend, RouteService());
      addTearDown(runtime.dispose);
      addTearDown(backend.dispose);
      await runtime.load();
      await runtime.sync();
      expect(runtime.syncing, isFalse);
      expect(await store.read(), snapshot);
      expect(await store.pending(), hasLength(1));
      if (failure == 'P0001' || failure == 'conflict') {
        expect(runtime.hasConflict, isTrue);
        expect(
          runtime.blockedSyncReason,
          contains(failure == 'P0001' ? 'ditolak' : 'perangkat lain'),
        );
        final restored = CourierRuntime(
          CourierStore(db, 'one'),
          backend,
          RouteService(),
        );
        await restored.load();
        await restored.sync();
        expect(attempts, 1);
        await expectLater(
          restored.store.save(CourierStore.empty()),
          throwsStateError,
        );
        restored.dispose();
      } else {
        expect(
          runtime.syncError,
          contains(failure == 'PGRST301' ? 'Sesi' : 'koneksi'),
        );
        final restored = CourierRuntime(
          CourierStore(db, 'one'),
          backend,
          RouteService(),
        );
        addTearDown(restored.dispose);
        await restored.load();
        retry = true;
        await restored.sync();
        expect(await store.pending(), isEmpty);
        expect(restored.state, snapshot);
        expect(remoteRevision, 1);
        expect(operationIds.toSet(), hasLength(1));
        expect(restored.syncError, isNull);
      }
    });
  }
}
