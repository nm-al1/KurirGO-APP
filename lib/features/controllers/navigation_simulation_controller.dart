import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/road_route.dart';

class NavigationSimulationController extends ChangeNotifier {
  final RoadLeg leg;
  static const timeScale = 20;
  double traveled = 0;
  double heading;
  bool running = false;

  NavigationSimulationController(this.leg) : heading = leg.bearingAt(0);
  LatLng get position => leg.positionAt(traveled);
  bool get arrived => traveled >= leg.length;
  double get speed => running ? 39 + 3 * math.sin(traveled / 150) : 0;
  RoadManeuver get maneuver => leg.nextTurn(traveled);
  double get distanceToTurn =>
      (leg.cumulative[maneuver.pointIndex] - traveled).clamp(0, leg.length);
  double get remaining => leg.length - traveled;
  String get instruction {
    if (arrived) return 'Tiba di Tujuan';
    final turn = maneuver;
    final action = switch (turn.type) {
      'arrive' => 'Menuju tujuan',
      'roundabout' || 'rotary' => 'Lewati bundaran',
      _ => switch (turn.modifier) {
        'right' || 'slight right' || 'sharp right' => 'Belok kanan',
        'left' || 'slight left' || 'sharp left' => 'Belok kiri',
        'uturn' => 'Putar balik',
        _ => 'Lanjut lurus',
      },
    };
    return turn.street.isEmpty ? action : '$action ke ${turn.street}';
  }

  void play() {
    if (arrived || running) return;
    running = true;
    notifyListeners();
  }

  void pause() {
    if (!running) return;
    running = false;
    notifyListeners();
  }

  void replay() {
    traveled = 0;
    heading = leg.bearingAt(0);
    running = false;
    notifyListeners();
  }

  void advance(Duration elapsed) {
    if (!running || elapsed <= Duration.zero) return;
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    traveled = (traveled + speed / 3.6 * seconds * timeScale).clamp(
      0,
      leg.length,
    );
    final target = leg.bearingAt(traveled);
    final delta = (target - heading + 540) % 360 - 180;
    heading = (heading + delta * (1 - math.exp(-seconds * 12)) + 360) % 360;
    if (arrived) running = false;
    notifyListeners();
  }
}
