import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as g;

import '../../data/models/road_route.dart';
import '../../data/models/waypoint_model.dart';
import '../../data/dummy_makassar_data.dart';
import '../controllers/gps_navigation.dart';
import '../controllers/navigation_simulation_controller.dart';
import 'google_map_gate.dart';

RoadRoute routeWithGps(RoadRoute route, GpsNavigation? gps) =>
    gps?.leg == null || gps!.legIndex < 0 || gps.legIndex >= route.legs.length
    ? route
    : RoadRoute([
        for (var i = 0; i < route.legs.length; i++)
          i == gps.legIndex ? gps.leg! : route.legs[i],
      ]);

g.LatLngBounds googleRouteBounds(RoadRoute route) {
  final points = route.legs.expand((leg) => leg.points).toList();
  return g.LatLngBounds(
    southwest: g.LatLng(
      points.map((p) => p.latitude).reduce(math.min) - 0.00001,
      points.map((p) => p.longitude).reduce(math.min) - 0.00001,
    ),
    northeast: g.LatLng(
      points.map((p) => p.latitude).reduce(math.max) + 0.00001,
      points.map((p) => p.longitude).reduce(math.max) + 0.00001,
    ),
  );
}

Future<g.BitmapDescriptor> googleCourierMarker(String label) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawCircle(
    const Offset(48, 48),
    42,
    Paint()..color = const Color(0xFF18181B),
  );
  canvas.drawCircle(
    const Offset(48, 48),
    42,
    Paint()
      ..color = const Color(0xFFC6FF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6,
  );
  if (label == 'courier') {
    canvas.drawPath(
      Path()
        ..moveTo(48, 20)
        ..lineTo(72, 70)
        ..lineTo(48, 58)
        ..lineTo(24, 70)
        ..close(),
      Paint()..color = const Color(0xFFC6FF00),
    );
  } else {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFC6FF00),
          fontSize: 28,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(48 - text.width / 2, 48 - text.height / 2));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(96, 96);
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return g.BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    width: 44,
    height: 44,
  );
}

class GoogleRouteView extends StatefulWidget {
  final RoadRoute route;
  final GpsNavigation? gps;
  final NavigationSimulationController? simulation;
  final List<WaypointModel>? waypoints;
  final bool navigation;
  final Offset riderOffset;
  const GoogleRouteView({
    required this.route,
    this.gps,
    this.simulation,
    this.waypoints,
    this.navigation = false,
    this.riderOffset = Offset.zero,
    super.key,
  });
  @override
  State<GoogleRouteView> createState() => _GoogleRouteViewState();
}

class _GoogleRouteViewState extends State<GoogleRouteView> {
  g.GoogleMapController? map;
  bool following = true;
  final icons = <String, g.BitmapDescriptor>{};
  final pendingIcons = <String>{};
  g.BitmapDescriptor icon(String label) {
    if (!icons.containsKey(label) && pendingIcons.add(label)) {
      googleCourierMarker(label).then((value) {
        if (mounted) setState(() => icons[label] = value);
      });
    }
    return icons[label] ??
        g.BitmapDescriptor.defaultMarkerWithHue(g.BitmapDescriptor.hueGreen);
  }

  RoadRoute get route => routeWithGps(widget.route, widget.gps);
  g.LatLng get rider {
    final p =
        widget.gps?.fix?.point ??
        widget.simulation?.position ??
        widget.route.legs.first.points.first;
    return g.LatLng(p.latitude, p.longitude);
  }

  @override
  void initState() {
    super.initState();
    widget.gps?.addListener(changed);
    widget.simulation?.addListener(changed);
  }

  @override
  void didUpdateWidget(covariant GoogleRouteView old) {
    super.didUpdateWidget(old);
    if (old.gps != widget.gps) {
      old.gps?.removeListener(changed);
      widget.gps?.addListener(changed);
    }
    if (old.simulation != widget.simulation) {
      old.simulation?.removeListener(changed);
      widget.simulation?.addListener(changed);
    }
  }

  Future<void> move(g.CameraUpdate update) async {
    try {
      await map?.animateCamera(update);
    } catch (_) {}
  }

  void changed() {
    if (!mounted) return;
    if (following && (widget.gps == null || widget.gps!.onRoute)) {
      unawaited(
        move(
          g.CameraUpdate.newCameraPosition(
            g.CameraPosition(target: rider, zoom: 16),
          ),
        ),
      );
    }
    setState(() {});
  }

  void overview() {
    setState(() {
      following = false;
    });
    unawaited(
      move(g.CameraUpdate.newLatLngBounds(googleRouteBounds(route), 45)),
    );
  }

  void recenter() {
    setState(() => following = true);
    if (widget.gps != null && !widget.gps!.onRoute) {
      unawaited(
        move(g.CameraUpdate.newLatLngBounds(googleRouteBounds(route), 45)),
      );
    } else {
      unawaited(move(g.CameraUpdate.newLatLngZoom(rider, 16)));
    }
  }

  @override
  void dispose() {
    widget.gps?.removeListener(changed);
    widget.simulation?.removeListener(changed);
    map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      GoogleMapGate(
        child: Listener(
          onPointerDown: (_) => setState(() => following = false),
          child: g.GoogleMap(
            initialCameraPosition: g.CameraPosition(
              target: rider,
              zoom: widget.navigation ? 16 : 11.6,
            ),
            padding: EdgeInsets.only(
              top: math.max(100, widget.riderOffset.dy * 2),
              bottom: 70,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) {
              map = controller;
              if (!widget.navigation || widget.gps != null) {
                overview();
              } else {
                recenter();
              }
              if (widget.gps != null) {
                following = true;
                changed();
              }
            },
            polylines: {
              for (final entry in route.legs.indexed)
                g.Polyline(
                  polylineId: g.PolylineId('leg-${entry.$1}'),
                  points: entry.$2.points
                      .map((p) => g.LatLng(p.latitude, p.longitude))
                      .toList(),
                  width: 6,
                  color:
                      (widget.gps != null
                          ? entry.$1 == widget.gps!.legIndex
                          : widget.simulation == null ||
                                widget.simulation!.leg == entry.$2)
                      ? const Color(0xFFC6FF00)
                      : const Color(0xFF64748B),
                ),
            },
            circles: {
              if (widget.gps?.fix != null)
                g.Circle(
                  circleId: const g.CircleId('accuracy'),
                  center: rider,
                  radius: widget.gps!.fix!.accuracy.clamp(1, 500),
                  fillColor: const Color(0x223B82F6),
                  strokeWidth: 1,
                ),
            },
            markers: {
              for (final p in widget.waypoints ?? DummyMakassarData.waypoints)
                g.Marker(
                  markerId: g.MarkerId(p.id),
                  position: g.LatLng(p.latitude, p.longitude),
                  icon: icon(p.nodeIndex == 0 ? 'V0' : '#${p.nodeIndex}'),
                  anchor: const Offset(0.5, 0.5),
                  infoWindow: g.InfoWindow(
                    title:
                        '${p.nodeIndex == 0 ? 'V0' : '#${p.nodeIndex}'} - ${p.name}',
                  ),
                ),
              if (widget.simulation != null || widget.gps?.fix != null)
                g.Marker(
                  markerId: const g.MarkerId('courier'),
                  position: rider,
                  icon: icon('courier'),
                  anchor: const Offset(0.5, 0.5),
                  flat: true,
                  rotation:
                      widget.gps?.fix?.heading.isFinite == true &&
                          widget.gps!.fix!.heading >= 0
                      ? widget.gps!.fix!.heading
                      : widget.simulation?.heading ?? 0,
                  infoWindow: const g.InfoWindow(title: 'Posisi kurir'),
                ),
            },
          ),
        ),
      ),
      Positioned(
        right: 12,
        bottom: 64,
        child: Material(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Lihat seluruh rute',
                onPressed: overview,
                icon: const Icon(Icons.route, color: Colors.white),
              ),
              IconButton(
                tooltip: following
                    ? 'Posisi kurir terkunci'
                    : 'Kunci posisi kurir',
                onPressed: recenter,
                icon: Icon(
                  following ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: const Color(0xFFC6FF00),
                ),
              ),
              for (final zoom in [1.0, -1.0])
                IconButton(
                  tooltip: zoom > 0 ? 'Perbesar peta' : 'Perkecil peta',
                  onPressed: () => unawaited(move(g.CameraUpdate.zoomBy(zoom))),
                  icon: Icon(
                    zoom > 0 ? Icons.add : Icons.remove,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
      const Positioned(
        left: 8,
        bottom: 32,
        child: Material(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              'Rute: OSRM - optimasi KurirGO',
              style: TextStyle(fontSize: 10, color: Colors.black),
            ),
          ),
        ),
      ),
    ],
  );
}
