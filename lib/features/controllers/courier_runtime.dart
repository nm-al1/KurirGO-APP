import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/number_format.dart';
import '../../data/courier_store.dart';
import '../../data/route_service.dart';
import '../../data/models/road_route.dart';
import '../../data/demo_data.dart';
import '../../core/algorithms/road_tour.dart';
import 'gps_navigation.dart';

class CourierRuntime extends ChangeNotifier {
  final CourierStore store;
  final SupabaseClient backend;
  final RouteService routes;
  Json state = CourierStore.empty();
  List<Map<String, Object?>> outbox = [];
  String? syncError;
  bool syncing = false;
  bool _changing = false, _disposed = false;
  int _generation = 0;
  Timer? timer;
  late final gps = GpsNavigation(
    AndroidLocationSource(),
    routes,
    saveReroute: (index, geometry) async {
      final id = activeTrip?['id'];
      if (id != null) await store.putLocal('route:$id:$index', geometry);
    },
  );
  bool get isDemo => store.localOnly;
  String get fullName => isDemo
      ? (state['profile']?['full_name'] as String? ?? 'Kurir Demo')
      : backend.auth.currentUser?.userMetadata?['full_name'] ?? 'Kurir';
  String get username => isDemo
      ? 'demo'
      : backend.auth.currentUser?.userMetadata?['username'] ?? '';
  String get phone => isDemo
      ? (state['profile']?['phone'] as String? ?? '08000000000')
      : backend.auth.currentUser?.userMetadata?['phone'] ?? '';
  Uint8List? avatar;
  Future<void> loadAvatar() async {
    final cached = await store.getLocal('avatar');
    final path = backend.auth.currentUser?.userMetadata?['avatar_path'];
    avatar = cached?['bytes'] == null ? null : base64Decode(cached!['bytes']);
    if (!isDemo && path is String && path.startsWith('${store.owner}/')) {
      try {
        avatar = await backend.storage.from('courier-avatars').download(path);
        await store.putLocal('avatar', {
          'bytes': base64Encode(avatar!),
          'path': path,
        });
      } catch (_) {
        // Keep the account's cached photo while offline.
      }
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> updateProfile(
    String name,
    String number, {
    Uint8List? photo,
  }) async {
    if (name.trim().isEmpty ||
        name.trim().length > 100 ||
        !RegExp(r'^0[0-9]{8,14}$').hasMatch(number.trim())) {
      throw StateError('Periksa nama dan nomor WhatsApp.');
    }
    if (photo != null && (photo.isEmpty || photo.length > 2 * 1024 * 1024)) {
      throw StateError('Ukuran foto maksimal 2 MB.');
    }
    final profile = <String, dynamic>{
      'full_name': name.trim(),
      'phone': number.trim(),
    };
    if (isDemo) {
      await change((s) => s['profile'] = profile);
    } else {
      final old = backend.auth.currentUser?.userMetadata?['avatar_path'];
      String? uploaded;
      try {
        if (photo != null) {
          uploaded = '${store.owner}/${const Uuid().v4()}.jpg';
          await backend.storage
              .from('courier-avatars')
              .uploadBinary(
                uploaded,
                photo,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );
          profile['avatar_path'] = uploaded;
        }
        await backend.auth.updateUser(UserAttributes(data: profile));
      } catch (_) {
        if (uploaded != null) {
          try {
            await backend.storage.from('courier-avatars').remove([uploaded]);
          } catch (_) {}
        }
        rethrow;
      }
      if (uploaded != null &&
          old is String &&
          old.startsWith('${store.owner}/')) {
        try {
          await backend.storage.from('courier-avatars').remove([old]);
        } catch (_) {}
      }
    }
    if (photo != null) {
      avatar = photo;
      await store.putLocal('avatar', {'bytes': base64Encode(photo)});
    }
    notifyListeners();
  }

  Future<void> resetDemo() async {
    if (!isDemo) throw StateError('Hanya tersedia pada demo.');
    await gps.stop();
    await store.resetLocal(DemoData.seed(DateTime.now()));
    await load();
  }

  int _gpsPreparation = 0;
  Future<void> prepareGps() async {
    final preparation = ++_gpsPreparation;
    final trip = activeTrip;
    if (trip == null) {
      if (_gpsTrip != null) {
        _gpsTrip = null;
        await gps.stop();
      }
      return;
    }
    if (trip['geometry'] == null) return;
    final stops = trip['stops'] as List;
    var index = stops.indexWhere(
      (stop) => (stop as List).any((id) => order(id)['status'] != 'completed'),
    );
    if (index < 0) index = stops.length;
    if (gps.legIndex == index && _gpsTrip == trip['id']) return;
    if (_gpsTrip != trip['id']) {
      gps.legIndex = -1;
      _gpsTrip = trip['id'];
    }
    final saved = await store.getLocal('route:${trip['id']}:$index');
    if (_disposed || preparation != _gpsPreparation) return;
    gps.setLeg(
      index,
      saved == null
          ? RoadRoute.fromJson(trip['geometry']).legs[index]
          : RoadRoute.fromJson(saved).legs.single,
    );
  }

  String? _gpsTrip;
  Future<Json> calculateRoute(List<Json> selected) async {
    final original = DemoData.seed(DateTime.now())['orders'] as List;
    final initial = original.take(6).cast<Json>().toList();
    bool matches(Json a, Json b) =>
        a['id'] == b['id'] && a['lat'] == b['lat'] && a['lng'] == b['lng'];
    if (isDemo &&
        selected.length == 6 &&
        initial.every((o) => selected.any((s) => matches(s, o)))) {
      final geometry = jsonDecode(
        (await rootBundle.loadString('assets/routes/demo_loop.json'))
            .replaceFirst('\ufeff', ''),
      ) as Json;
      RoadRoute.fromJson(geometry);
      final solution = solveRoadDistances(geometry['distances'] as List);
      if (jsonEncode(solution.tour) != jsonEncode(geometry['nodeTour'])) {
        throw StateError('Fixture demo tidak sesuai hasil optimasi.');
      }
      final groups = [
        <String>[],
        [initial[0]['id'] as String, initial[5]['id'] as String],
        for (var i = 1; i < 5; i++) [initial[i]['id'] as String],
      ];
      return {
        'geometry': geometry,
        'stops': [
          for (final node
              in solution.tour.skip(1).take(solution.tour.length - 2))
            groups[node],
        ],
        'distance': geometry['route']['distance'],
        'duration': geometry['route']['duration'],
        'algorithm': '${solution.algorithmName} · matriks jalan demo tersimpan',
        'sourceOrders': selected,
      };
    }
    return routes.calculate(selected);
  }

  CourierRuntime(this.store, this.backend, this.routes);
  List<Json> get orders => (state['orders'] as List).cast<Json>();
  List<Json> get trips => (state['trips'] as List).cast<Json>();
  Json? get activeTrip =>
      trips.where((t) => t['settledAt'] == null).firstOrNull;
  bool get hasConflict => outbox.any((o) => o['conflict'] != null);
  String? get blockedSyncReason => outbox
      .where((o) => o['conflict'] != null)
      .map((o) => o['conflict'] as String)
      .firstOrNull;
  static const orderTextLimits = {
    'recipient': 200,
    'address': 2000,
    'items': 2000,
  };
  List<Json> get waiting =>
      orders.where((o) => o['status'] == 'waiting').toList();
  List<Json> get history =>
      orders.where((o) => o['status'] == 'completed').toList()..sort(
        (a, b) =>
            (b['completedAt'] as String).compareTo(a['completedAt'] as String),
      );
  Json order(String id) => orders.firstWhere((o) => o['id'] == id);
  Future<void> load() async {
    state = await store.read();
    if (isDemo && state['demoSeededAt'] == null) {
      await store.resetLocal(DemoData.seed(DateTime.now()));
      state = await store.read();
    }
    outbox = await store.pending();
    await loadAvatar();
    notifyListeners();
    if (!isDemo) {
      timer ??= Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(sync()),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    timer?.cancel();
    routes.client.close();
    gps.dispose();
    super.dispose();
  }

  Future<void> change(void Function(Json) edit) async {
    if (_changing) throw StateError('Tunggu penyimpanan sebelumnya selesai.');
    _changing = true;
    _generation++;
    try {
      final next = jsonDecode(jsonEncode(state)) as Json;
      edit(next);
      await store.save(next, previous: state);
      state = next;
      outbox = await store.pending();
    } finally {
      _changing = false;
      _generation++;
      if (!_disposed) notifyListeners();
    }
    if (!_disposed) unawaited(sync());
    if (!_disposed) await prepareGps();
  }

  Future<void> saveOrder(Json input, {String? id}) async {
    input = Map<String, dynamic>.from(input);
    for (final key in ['recipient', 'address', 'items', 'phone']) {
      if (input[key] is! String || (input[key] as String).trim().isEmpty) {
        throw StateError('Lengkapi seluruh data pesanan.');
      }
    }
    for (final key in ['recipient', 'address', 'items', 'phone']) {
      input[key] = (input[key] as String).trim();
    }
    for (final entry in orderTextLimits.entries) {
      if ((input[entry.key] as String).runes.length > entry.value) {
        throw StateError(
          'Teks pesanan terlalu panjang. Maksimal penerima 200 karakter, alamat dan rincian barang 2.000 karakter.',
        );
      }
    }
    if (!RegExp(r'^0[0-9]{8,14}$').hasMatch(input['phone'])) {
      throw StateError('WhatsApp harus 9–15 digit dan diawali 0.');
    }
    if (input['boxes'] is! int ||
        input['boxes'] < 1 ||
        input['boxes'] > 9999 ||
        input['bill'] is! int ||
        input['bill'] < 0 ||
        input['bill'] > maxRupiah) {
      throw StateError('Jumlah box atau tagihan tidak valid.');
    }
    if (parseCoordinate('${input['lat']}', latitude: true) == null ||
        parseCoordinate('${input['lng']}', latitude: false) == null) {
      throw StateError('Koordinat tidak valid.');
    }
    if (id != null && order(id)['status'] != 'waiting') {
      throw StateError('Pesanan sudah masuk perjalanan.');
    }
    await change((s) {
      final list = s['orders'] as List;
      if (id != null) list.removeWhere((o) => o['id'] == id);
      list.add({
        ...input,
        'id': id ?? const Uuid().v4(),
        'status': 'waiting',
        'createdAt': id == null
            ? DateTime.now().toUtc().toIso8601String()
            : order(id)['createdAt'],
      });
    });
  }

  Future<void> cancel(String id) async {
    if (order(id)['status'] != 'waiting') {
      throw StateError('Hanya pesanan antrean yang dapat dibatalkan.');
    }
    await change(
      (s) => (s['orders'] as List).firstWhere((o) => o['id'] == id)['status'] =
          'cancelled',
    );
  }

  Future<void> startTrip(Json route, List<String> ids) async {
    if (ids.isEmpty || ids.length > 20) {
      throw StateError('Pilih 1?20 pesanan untuk perjalanan.');
    }
    if (route['sourceOrders'] != null &&
        jsonEncode(route['sourceOrders']) !=
            jsonEncode(ids.map(order).toList())) {
      throw StateError(
        'Pesanan berubah setelah rute dihitung. Hitung ulang dan verifikasi muatan kembali.',
      );
    }
    if (activeTrip != null) {
      throw StateError('Setorkan perjalanan aktif dahulu.');
    }
    if (ids.toSet().length != ids.length ||
        ids.any((id) => order(id)['status'] != 'waiting')) {
      throw StateError('Pilihan pesanan sudah berubah. Hitung ulang rute.');
    }
    final routeIds = (route['stops'] as List)
        .expand((s) => s as List)
        .cast<String>()
        .toList();
    if (routeIds.length != ids.length || !routeIds.toSet().containsAll(ids)) {
      throw StateError('Muatan tidak sesuai rute.');
    }
    final tripId = const Uuid().v4();
    await change((s) {
      (s['trips'] as List).add({
        ...route,
        'id': tripId,
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'settledAt': null,
      });
      for (final o in s['orders']) {
        if (ids.contains(o['id'])) {
          o['status'] = 'active';
          o['tripId'] = tripId;
        }
      }
    });
  }

  List<String> get remaining => activeTrip == null
      ? []
      : (activeTrip!['stops'] as List)
            .expand((s) => s as List)
            .cast<String>()
            .where((id) => order(id)['status'] != 'completed')
            .toList();
  Future<void> deliver(
    String id,
    String method,
    int? received,
    String reference,
  ) async {
    if (remaining.isEmpty || remaining.first != id) {
      throw StateError('Selesaikan pesanan sesuai urutan LIFO.');
    }
    if (!['cash', 'qris', 'transfer'].contains(method)) {
      throw StateError('Pilih metode pembayaran.');
    }
    final bill = order(id)['bill'] as int;
    if (method == 'cash' &&
        (received == null || received < bill || received > maxRupiah)) {
      throw StateError('Uang diterima belum mencukupi.');
    }
    if (method != 'cash' && reference.trim().isEmpty) {
      throw StateError('Isi referensi pembayaran yang sudah diperiksa.');
    }
    await change((s) {
      final o = (s['orders'] as List).firstWhere((o) => o['id'] == id);
      o['status'] = 'completed';
      o['completedAt'] = DateTime.now().toUtc().toIso8601String();
      o['payment'] = {
        'method': method,
        'received': method == 'cash' ? received : bill,
        'reference': reference.trim(),
      };
    });
  }

  Future<void> settle() async {
    if (activeTrip == null || remaining.isNotEmpty) {
      throw StateError('Selesaikan seluruh pengantaran dahulu.');
    }
    final id = activeTrip!['id'];
    await change(
      (s) =>
          (s['trips'] as List).firstWhere((t) => t['id'] == id)['settledAt'] =
              DateTime.now().toUtc().toIso8601String(),
    );
    await gps.stop();
  }

  Future<void> sync() async {
    if (isDemo ||
        _disposed ||
        syncing ||
        hasConflict ||
        backend.auth.currentUser?.id != store.owner) {
      return;
    }
    syncing = true;
    notifyListeners();
    try {
      for (final operation in await store.pending()) {
        if (_disposed || backend.auth.currentUser?.id != store.owner) return;
        Json response;
        try {
          response = await backend.rpc(
            'apply_courier_state',
            params: {
              'operation_id': operation['id'],
              'expected_revision': operation['revision'],
              'new_payload': jsonDecode(operation['payload'] as String),
            },
          ) as Json;
        } on PostgrestException catch (e) {
          if (e.code == 'P0001' ||
              (e.code?.startsWith('22') ?? false) ||
              (e.code?.startsWith('23') ?? false)) {
            await store.conflict(
              operation['id'] as String,
              'Data ditolak server. Catatan lokal tetap disimpan; salin catatan untuk diperiksa sebelum melanjutkan.',
            );
          }
          rethrow;
        }
        if (response['conflict'] == true) {
          await store.conflict(
            operation['id'] as String,
            'Data akun berubah di perangkat lain. Catatan lokal tetap disimpan.',
          );
          break;
        }
        await store.acknowledge(operation['id'] as String);
      }
      final remote = await backend
          .from('courier_state')
          .select()
          .eq('owner', store.owner)
          .maybeSingle();
      if (remote != null) {
        await store.receive(
          remote['revision'] as int,
          remote['payload'] as Json,
        );
      }
      syncError = null;
    } on AuthException {
      syncError = 'Sesi login perlu diperbarui. Hubungkan internet dan masuk kembali dengan akun yang sama; data lokal tetap tersimpan.';
    } on PostgrestException catch (e) {
      syncError =
          e.code == 'PGRST301' || e.code == 'PGRST303' || e.code == '42501'
          ? 'Sesi atau akses akun perlu diperiksa. Masuk kembali dengan akun yang sama; data lokal tetap tersimpan.'
          : 'Server belum menerima perubahan. Data lokal tetap tersimpan; periksa status sinkronisasi.';
    } catch (_) {
      syncError = 'Belum tersinkron. Data tersimpan di perangkat. Periksa koneksi lalu coba kembali.';
    } finally {
      try {
        final generation = _generation;
        final snapshot = await store.read();
        if (!_changing && generation == _generation) state = snapshot;
        outbox = await store.pending();
        if (!_disposed) await prepareGps();
      } catch (_) {
        syncError = 'Penyimpanan lokal belum dapat dibaca. Buka ulang aplikasi sebelum melanjutkan.';
      } finally {
        syncing = false;
        if (!_disposed) notifyListeners();
      }
    }
  }
}
