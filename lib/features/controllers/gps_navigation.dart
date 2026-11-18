import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/road_route.dart';
import '../../data/route_service.dart';

class LocationFix {
  final LatLng point;
  final DateTime time;
  final double accuracy, heading, speed;
  const LocationFix(
    this.point,
    this.time,
    this.accuracy,
    this.heading,
    this.speed,
  );
  bool usable(DateTime now) =>
      accuracy.isFinite &&
      accuracy >= 0 &&
      accuracy <= 50 &&
      now.difference(time).inSeconds <= 15 &&
      !time.isAfter(now.add(const Duration(seconds: 3)));
}

abstract class LocationSource {
  Future<Stream<LocationFix>> start();
}

class AndroidLocationSource implements LocationSource {
  @override
  Future<Stream<LocationFix>> start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw StateError('GPS perjalanan tersedia pada Android.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
        'GPS mati. Aktifkan lokasi di pengaturan lalu coba lagi.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Izin lokasi diblokir. Buka pengaturan aplikasi untuk mengizinkan lokasi.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Izin lokasi diperlukan untuk mengikuti posisi kurir.');
    }
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Pengantaran aktif',
          notificationText: 'KurirGO memakai lokasi selama perjalanan. Hentikan GPS melalui aplikasi.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      ),
    ).map(
      (p) => LocationFix(
        LatLng(p.latitude, p.longitude),
        p.timestamp,
        p.accuracy,
        p.heading,
        p.speed,
      ),
    );
  }
}

class GpsNavigation extends ChangeNotifier {
  final LocationSource source;
  final RouteService routes;
  final Future<void> Function(int leg, Map<String, dynamic> geometry)?
  saveReroute;
  StreamSubscription<LocationFix>? subscription;
  Timer? watchdog;
  RoadLeg? leg;
  LocationFix? fix;
  int legIndex = -1,
      _generation = 0,
      _startGeneration = 0,
      _outside = 0,
      _near = 0;
  double progress = 0;
  bool enabled = false, starting = false, rerouting = false;
  String? error;
  DateTime? _lastReroute;
  bool _disposed = false;
  GpsNavigation(this.source, this.routes, {this.saveReroute});
  bool get reliable => enabled && fix != null && fix!.usable(DateTime.now());
  bool get nearDestination => reliable && _near >= 2;
  bool get onRoute => reliable && !_needsInitialConnection && _outside == 0;
  bool _needsInitialConnection = true;
  String get status =>
      error ??
      (!enabled
          ? 'GPS dihentikan'
          : fix == null
          ? 'Menunggu posisi GPS…'
          : !reliable
          ? 'Sinyal GPS lemah atau posisi usang'
          : nearDestination
          ? 'Mendekati tujuan'
          : 'GPS aktif · akurasi ${fix!.accuracy.round()} m');
  String get instruction {
    if (!reliable || leg == null) return status;
    if (_outside >= 3) {
      return rerouting
          ? 'Menghitung ulang jalan…'
          : 'Di luar jalur · menunggu rute baru';
    }
    final turn = leg!.nextTurn(progress);
    final action = turn.modifier.contains('right')
        ? 'Belok kanan'
        : turn.modifier.contains('left')
        ? 'Belok kiri'
        : 'Lanjut lurus';
    return nearDestination
        ? 'Mendekati tujuan'
        : '$action${turn.street.isEmpty ? '' : ' ke ${turn.street}'}';
  }

  void setLeg(int index, RoadLeg value) {
    if (index == legIndex) return;
    _generation++;
    legIndex = index;
    leg = value;
    progress = 0;
    _outside = 0;
    _near = 0;
    _lastReroute = null;
    _needsInitialConnection = true;
    error = null;
    notifyListeners();
  }

  Future<void> start() async {
    if (starting || enabled || _disposed) return;
    starting = true;
    error = null;
    final generation = ++_startGeneration;
    notifyListeners();
    try {
      final stream = await source.start();
      if (_disposed || generation != _startGeneration) return;
      enabled = true;
      subscription = stream.listen(
        accept,
        onDone: () {
          error = 'GPS terputus. Aktifkan kembali GPS.';
          unawaited(stop());
        },
        onError: (Object e) {
          error = 'GPS terputus. Hentikan lalu aktifkan kembali GPS.';
          unawaited(stop());
        },
      );
      watchdog = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!reliable) {
          _outside = 0;
          _near = 0;
        }
        _notify();
      });
    } catch (e) {
      if (!_disposed && generation == _startGeneration) {
        error = e is StateError
            ? e.message
            : 'GPS belum dapat dimulai. Periksa izin lokasi.';
      }
    } finally {
      if (generation == _startGeneration) starting = false;
      _notify();
    }
  }

  void accept(LocationFix value) {
    if (!value.accuracy.isFinite || value.accuracy < 0) return;
    if (!enabled ||
        leg == null ||
        (fix != null && !value.time.isAfter(fix!.time))) {
      return;
    }
    if (!value.point.latitude.isFinite ||
        !value.point.longitude.isFinite ||
        value.point.latitude.abs() > 90 ||
        value.point.longitude.abs() > 180) {
      return;
    }
    fix = value;
    error = null;
    if (!value.usable(DateTime.now())) {
      _outside = 0;
      _near = 0;
      _notify();
      return;
    }
    final projection = project(leg!, value.point, progress);
    _outside = projection.$2 > 50 ? _outside + 1 : 0;
    if (_needsInitialConnection) {
      _needsInitialConnection = false;
      if (projection.$2 > 50) _outside = 3;
    }
    if (_outside == 0) progress = projection.$1;
    _near = RoadLeg.distance(value.point, leg!.points.last) <= 50
        ? _near + 1
        : 0;
    _notify();
    if (_outside >= 3) unawaited(_reroute());
  }

  static (double, double) project(RoadLeg leg, LatLng point, double previous) {
    var best = double.infinity, along = previous;
    final scale = math.cos(point.latitude * math.pi / 180);
    for (var i = 1; i < leg.points.length; i++) {
      if (leg.cumulative[i] < previous - 60) continue;
      if (leg.cumulative[i - 1] > previous + 500) continue;
      final a = leg.points[i - 1], b = leg.points[i];
      final dx = (b.longitude - a.longitude) * scale,
          dy = b.latitude - a.latitude;
      final px = (point.longitude - a.longitude) * scale,
          py = point.latitude - a.latitude;
      final denominator = dx * dx + dy * dy;
      final t = denominator == 0
          ? 0.0
          : ((px * dx + py * dy) / denominator).clamp(0.0, 1.0);
      final projected = LatLng(
        a.latitude + dy * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      final distance = RoadLeg.distance(point, projected);
      final candidate =
          leg.cumulative[i - 1] +
          (leg.cumulative[i] - leg.cumulative[i - 1]) * t;
      final score = distance + (candidate - previous).abs() * 0.01;
      if (score < best) {
        best = score;
        along = candidate;
      }
    }
    final separation = RoadLeg.distance(point, leg.positionAt(along));
    return (along, separation);
  }

  Future<void> _reroute() async {
    final now = DateTime.now();
    if (!reliable ||
        rerouting ||
        (_lastReroute != null &&
            now.difference(_lastReroute!).inSeconds < 30)) {
      return;
    }
    final generation = _generation,
        index = legIndex,
        origin = fix!.point,
        destination = leg!.points.last;
    rerouting = true;
    _lastReroute = now;
    _notify();
    try {
      final geometry = await routes.between(origin, destination);
      if (_disposed || generation != _generation || !enabled) return;
      await saveReroute?.call(index, geometry);
      if (_disposed || generation != _generation || !enabled) return;
      leg = RoadRoute.fromJson(geometry).legs.single;
      progress = 0;
      _outside = 0;
    } catch (_) {
      if (generation == _generation) {
        error = 'Di luar jalur. Rute baru belum tersedia; periksa koneksi.';
      }
    } finally {
      rerouting = false;
      _notify();
    }
  }

  Future<void> stop() async {
    enabled = false;
    starting = false;
    _startGeneration++;
    _generation++;
    watchdog?.cancel();
    final previous = subscription;
    subscription = null;
    fix = null;
    _needsInitialConnection = true;
    _outside = 0;
    _near = 0;
    _notify();
    await previous?.cancel();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(stop());
    super.dispose();
  }
}
